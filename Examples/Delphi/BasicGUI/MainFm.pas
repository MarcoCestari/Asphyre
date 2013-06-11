unit MainFm;
//---------------------------------------------------------------------------
// Basic GUI example for Asphyre.
// Illustrates how to use and work with Asphyre GUI framework.
//---------------------------------------------------------------------------
// The contents of this file are subject to the Mozilla Public License
// Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
  System.Types, System.SysUtils, Winapi.Messages, System.Classes, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  private
    { Private declarations }
    FailureHandled: Boolean;
    FirstTimeShow: Boolean;
    AddItemNo: Integer;

    procedure OnAsphyreCreate(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);

    procedure OnAsphyreDestroy(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);

    procedure OnDeviceInit(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);

    procedure OnDeviceCreate(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);

    procedure OnTimerReset(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);

    procedure TimerEvent(Sender: TObject);
    procedure ProcessEvent(Sender: TObject);
    procedure RenderEvent(Sender: TObject);

    procedure HandleConnectFailure();
    procedure SetupFontLetterSpacing();

    procedure InitGuiStyle();
    procedure UpdateGuiControls();

    procedure OnButtonClick(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);

    procedure CMDialogKey(var Msg: TWMKEY); message CM_DIALOGKEY;
  public
    { Public declarations }
  end;

//---------------------------------------------------------------------------
var
  MainForm: TMainForm;

//---------------------------------------------------------------------------
implementation
{$R *.dfm}

//---------------------------------------------------------------------------
uses
 Asphyre.Math, Asphyre.Types, Asphyre.Events.Types, Asphyre.Events,
 Asphyre.FormTimers, Asphyre.Archives, Asphyre.Native.Connectors,
 Asphyre.Providers, Asphyre.Images, Asphyre.Fonts, Asphyre.Formats,
 Asphyre.Canvas, Asphyre.Textures, Asphyre.UI.Types, Asphyre.UI.Taskbar,
 Asphyre.UI.Controls, Asphyre.UI.Globals, Asphyre.UI.ListBoxes,
 Asphyre.UI.Forms, Asphyre.UI.Utils, Asphyre.Devices, Asphyre.Providers.DX11,
 GameTypes;

//---------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
 // Enable Delphi's memory manager to show memory leaks.
 ReportMemoryLeaksOnShutdown:= DebugHook <> 0;

 // Specify that DirectX 11 provider is to be used.
 Factory.UseProvider(idDirectX11);

 // This event is called when Asphyre components should be created.
 EventAsphyreCreate.Subscribe(ClassName, OnAsphyreCreate);

 // This event is called when Asphyre components are to be freed.
 EventAsphyreDestroy.Subscribe(ClassName, OnAsphyreDestroy);

 // This event is callled before creating Asphyre device to initialize its
 // parameters.
 EventDeviceInit.Subscribe(ClassName, OnDeviceInit);

 // This event is callled upon Asphyre device creation.
 EventDeviceCreate.Subscribe(ClassName, OnDeviceCreate);

 // This event is called when creating device and loading data to let the
 // application reset the timer so it does not stall.
 EventTimerReset.Subscribe(ClassName, OnTimerReset);

 // Register the event that will handle button clicks.
 EventButtonClick.Subscribe(ClassName, OnButtonClick);

 // Initialize and prepare the timer.
 Timer.MaxFPS   := 4000;
 Timer.OnTimer  := TimerEvent;
 Timer.OnProcess:= ProcessEvent;
 Timer.Enabled  := True;

 // Tell AsphyreManager that the archive will always be in the same folder
 // as this application.
 ArchiveTypeAccess:= ataPackaged;

 // This variable tells that a connection failure to Asphyre device has been
 // already handled.
 FailureHandled:= False;
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormDestroy(Sender: TObject);
begin
 // Disconnect Asphyre device.
 if (Assigned(GameDevice)) then GameDevice.Disconnect();

 // Finish the Asphyre connection manager.
 NativeAsphyreConnect.Done();

 // Remove the subscription to the events.
 EventProviders.Unsubscribe(ClassName);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreCreate(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 DisplaySize:= Point2px(ClientWidth, ClientHeight);

 GameDevice:= Factory.CreateDevice();

 GameCanvas:= Factory.CreateCanvas();
 GameImages:= TAsphyreImages.Create();

 GameFonts:= TAsphyreFonts.Create();
 GameFonts.Images:= GameImages;
 GameFonts.Canvas:= GameCanvas;

 GameTaskbar:= TGuiTaskbar.Create(nil);
 GameTaskbar.ClientRect:= Bounds(0, 0, DisplaySize.x, DisplaySize.y);

 GuiCanvas:= GameCanvas;
 GuiImages:= GameImages;
 GuiFonts := GameFonts;

 MediaFile:= TAsphyreArchive.Create();
 MediaFile.OpenMode:= aomReadOnly;
 MediaFile.FileName:= 'media.asvf';

 FirstTimeShow:= True;
 InitGuiStyle();

 AddItemNo:= 0;
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreDestroy(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 Timer.Enabled:= False;

 FreeAndNil(MediaFile);
 FreeAndNil(GameTaskbar);
 FreeAndNil(GameFonts);
 FreeAndNil(GameImages);
 FreeAndNil(GameCanvas);
 FreeAndNil(GameDevice);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceInit(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 DisplaySize:= Point2px(ClientWidth, ClientHeight);
 GameDevice.SwapChains.Add(Self.Handle, DisplaySize);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceCreate(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 GameImages.AddFromArchive('Icons.image', MediaFile, '', False);
 GameImages.AddFromArchive('Tahoma.image', MediaFile, '', False);

 fontTahoma:= GameFonts.Insert('media.asvf | Tahoma.xml', 'Tahoma.image');

 GameTaskbar.LoadFromArchive('MainFm.gui', MediaFile);

 if (fontTahoma <> -1) then SetupFontLetterSpacing();

 PBoolean(Param)^:=
  (PBoolean(Param)^)and
  (fontTahoma <> -1);
end;

//---------------------------------------------------------------------------
procedure TMainForm.TimerEvent(Sender: TObject);
begin
 // Try to connect Asphyre to the application.
 if (not NativeAsphyreConnect.Init()) then Exit;

 // In case the device could not be initialized properly (in the frame before
 // this one), show error message and close the form.
 if (Assigned(GameDevice))and(GameDevice.IsAtFault()) then
  begin
   if (not FailureHandled) then HandleConnectFailure();
   FailureHandled:= True;
   Exit;
  end;

 // Initialize Asphyre device, if needed. If this initialization fails, the
 // failure will be handled in the next OnTimer event.
 if (not Assigned(GameDevice))or(not GameDevice.Connect()) then Exit;

 // Check the state of all GUI controls.
 UpdateGuiControls();

 // Render the scene.
 GameDevice.Render(RenderEvent, $FF3A4691);

 // Execute constant time processing.
 Timer.Process();
end;

//---------------------------------------------------------------------------
procedure TMainForm.ProcessEvent(Sender: TObject);
begin
 GameTaskbar.Update();
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderEvent(Sender: TObject);
begin
 GameTaskbar.ShowWindow('MainForm', FirstTimeShow);
 if (FirstTimeShow) then FirstTimeShow:= False;

 GameTaskbar.Draw();

 GameFonts[fontTahoma].TextOut(
  Point2(4.0, 4.0),
  'Frame Rate: ' + IntToStr(Timer.FrameRate),
  cColor2($FFF2F3F9, $FFB6BCE2));

 GameFonts[fontTahoma].TextOut(
  Point2(4.0, 24.0),
  'Technology: ' + GetFullDeviceTechString(GameDevice),
  cColor2($FFE8FFAA, $FF12C312));
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormResize(Sender: TObject);
begin
 if (Assigned(GameDevice)) then
  begin
   DisplaySize:= Point2px(ClientWidth, ClientHeight);
   GameDevice.Resize(0, DisplaySize);
  end;

 if (Assigned(GameTaskbar)) then
  GameTaskbar.ClientRect:= Bounds(0, 0, DisplaySize.x, DisplaySize.y);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnTimerReset(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 Timer.Reset();
end;

//---------------------------------------------------------------------------
procedure TMainForm.HandleConnectFailure();
begin
 Timer.Enabled:= False;

 ShowMessage('Failed initializing Asphyre device.');
 Close();
end;

//---------------------------------------------------------------------------
procedure TMainForm.SetupFontLetterSpacing();
var
 Font: TAsphyreFont;
begin
 // This method illustrates how to manually specify the spacing between some
 // specific pair of letters to provide a better looking text.
 Font:= GameFonts[fontTahoma];
 if (Font = nil) then Exit;

 Font.Kerning:= 1;

 // The following corrections were made by looking at "Frame Rate" text. They
 // make the text look perfect on pixel level.

 // Note that the spacing for each individual letter is specified in XML file.
 // It is precomputed using FontTool (where you can also modify this for each
 // individual letter). The spacing between pair of letters can also be edited
 // in the XML file, or it can be specified manually here.

 // It is not obligatory to specify spacing between every pair of letters.
 // However, in some very evident cases it is useful because no automatic tool
 // can reliably predict how good every possible pair of letters will look like.
 Font.Kernings.Spec('F', 'r', -1);
 Font.Kernings.Spec('R', 'a', -2);
 Font.Kernings.Spec('a', 'm', -1);
 Font.Kernings.Spec('a', 't', -2);
 Font.Kernings.Spec('r', 'a', -1);
 Font.Kernings.Spec('t', 'e', -1);
end;

//---------------------------------------------------------------------------
procedure TMainForm.InitGuiStyle();
begin
 // Customize some of the default GUI style parameters.
 GuiCtrlFocusColor  := $60FF8003;
 GuiButtonFocusColor:= $60FF8003;

 GuiButtonDisabledAlpha:= 0.333;
 GuiGlyphShadowAlpha:= 0.1;
end;

//---------------------------------------------------------------------------
procedure TMainForm.UpdateGuiControls();
var
 Ctrl: TGuiControl;
 Form: TGuiForm;
 ListBox: TGuiListBox;
 CanChangeItems: Boolean;
begin
 Ctrl:= GameTaskbar.Ctrl['MainForm'];
 if (not Assigned(Ctrl))or(not (Ctrl is TGuiForm)) then Exit;

 Form:= TGuiForm(Ctrl);

 Ctrl:= Form.Ctrl['ListingBox'];
 if (Assigned(Ctrl))and(Ctrl is TGuiListBox) then
  begin
   ListBox:= TGuiListBox(Ctrl);

   // Customize some specific visual animations in list box.
   ListBox.PointedItems.AlphaInc:= 64;
   ListBox.PointedItems.AlphaDec:= 48;

   ListBox.SelectedItems.AlphaInc:= 48;
   ListBox.SelectedItems.AlphaDec:= 32;

   // Determine if any changes can be made to the list.
   CanChangeItems:= (ListBox.Items.Count > 0)and(ListBox.ItemIndex <> -1);

   // Enable or disable specific buttons in their respective circumstances.
   SetControlEnabled(Form, 'RemoveButton', CanChangeItems);

   SetControlEnabled(Form, 'UpButton', CanChangeItems and
    (ListBox.ItemIndex > 0));

   SetControlEnabled(Form, 'DownButton', CanChangeItems and
    (ListBox.ItemIndex < ListBox.Items.Count - 1));
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnButtonClick(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
var
 Ctrl: TGuiControl;
 ListBox: TGuiListBox;
 Text: string;
 Index: Integer;
begin
 Ctrl:= GameTaskbar.Ctrl['ListingBox'];
 if (not Assigned(Ctrl))or(not (Ctrl is TGuiListBox)) then Exit;

 ListBox:= TGuiListBox(Ctrl);

 // Add button inserts some text to the list box using an integer number and
 // a letter chosen depending on the state of a check box.
 if (SameText(EventControlName, 'AddButton')) then
  begin
   if (GetControlChecked(GameTaskbar, 'AnonymBox')) then
    Text:= 'A' + IntToStr(AddItemNo + 1)
     else Text:= 'N' + IntToStr(AddItemNo + 1);

   Text:= Text + ': ' + GetControlText(GameTaskbar, 'UserNameEdit');

   Index:= ListBox.Items.Add(Text);
   ListBox.ItemIndex:= Index;

   Inc(AddItemNo);

   Handled:= True;
   Exit;
  end;

 // Remove button eliminates the item that is currently being selected.
 if (SameText(EventControlName, 'RemoveButton')) then
  begin
   if (ListBox.ItemIndex <> -1) then
    begin
     ListBox.Items.Delete(ListBox.ItemIndex);
     ListBox.ItemIndex:= -1;
    end;

   Handled:= True;
   Exit;
  end;

 // Up button displaces the currently selected element up by one.
 if (SameText(EventControlName, 'UpButton')) then
  begin
   Index:= ListBox.ItemIndex;
   if (Index > 0) then
    begin
     ListBox.Items.Exchange(Index - 1, Index);
     ListBox.ItemIndex:= Index - 1;
    end;

   Handled:= True;
   Exit;
  end;

 // Down button displaces the currently selected element down by one.
 if (SameText(EventControlName, 'DownButton')) then
  begin
   Index:= ListBox.ItemIndex;
   if (Index < ListBox.Items.Count - 1) then
    begin
     ListBox.Items.Exchange(Index, Index + 1);
     ListBox.ItemIndex:= Index + 1;
    end;

   Handled:= True;
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormMouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
begin
 if (Assigned(GameTaskbar)) then
  GameTaskbar.MouseDown(Button, Shift, x, y);
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
 Y: Integer);
begin
 if (Assigned(GameTaskbar)) then
  GameTaskbar.MouseMove(Shift, x, y);
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormMouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
begin
 if (Assigned(GameTaskbar)) then
  GameTaskbar.MouseUp(Button, Shift, x, y);
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormMouseWheel(Sender: TObject; Shift: TShiftState;
 WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
 if (Assigned(GameTaskbar)) then
  GameTaskbar.MouseWheel(Shift, WheelDelta, MousePos);
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
 Shift: TShiftState);
begin
 if (Assigned(GameTaskbar)) then
  GameTaskbar.KeyDown(Key, Shift);
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
 if (Assigned(GameTaskbar)) then
  GameTaskbar.KeyPress(Key);
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word;
 Shift: TShiftState);
begin
 if (Assigned(GameTaskbar)) then
  GameTaskbar.KeyUp(Key, Shift);
end;

//---------------------------------------------------------------------------
procedure TMainForm.CMDialogKey(var Msg: TWMKEY);
var
 Shift: TShiftState;
begin
 { This hack is to intercept "Tab" key, which Delphi does not send to
   standard Form's key events. }
 if (Msg.Charcode = AVK_TAB) then
  begin
   Shift:= KeyDataToShiftState(Msg.KeyData);

   if (Assigned(GameTaskbar)) then
    begin
     GameTaskbar.KeyDown(AVK_TAB, Shift);
     GameTaskbar.KeyUP(AVK_TAB, Shift);
    end;
  end else inherited;
end;

//---------------------------------------------------------------------------
end.
