unit MainFm;
//---------------------------------------------------------------------------
// Basic GUI example for Asphyre.
// Illustrates how to use and work with Asphyre and FireMonkey.
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
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Forms3D, FMX.Dialogs, FMX.Types3D;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm3D)
    SysTimer: TTimer;
    procedure Form3DCreate(Sender: TObject);
    procedure Form3DDestroy(Sender: TObject);
    procedure Form3DResize(Sender: TObject);
    procedure SysTimerTimer(Sender: TObject);
    procedure Form3DRender(Sender: TObject; Context: TContext3D);
    procedure Form3DMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Form3DMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure Form3DMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Form3DMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure Form3DKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure Form3DKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  private
    { Private declarations }
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

    procedure OnTimer(Sender: TObject);
    procedure OnRender(Sender: TObject);
    procedure OnProcess(Sender: TObject);

    procedure SetupFontLetterSpacing();

    procedure InitGuiStyle();
    procedure UpdateGuiControls();

    procedure OnButtonClick(const Sender: TObject; const Param: Pointer;
     var Handled: Boolean);
  public
    { Public declarations }
    procedure PaintRects(const UpdateRects: array of TRectF); override;

    procedure IsDialogKey(const Key: Word; const KeyChar: WideChar;
     const Shift: TShiftState; var IsDialog: Boolean); override;
  end;

//---------------------------------------------------------------------------
var
  MainForm: TMainForm;

//---------------------------------------------------------------------------
implementation
{$R *.fmx}

//---------------------------------------------------------------------------
uses
 Asphyre.Math, Asphyre.Types, Asphyre.Events.Types, Asphyre.Events,
 Asphyre.FeedTimers, Asphyre.Archives, Asphyre.Monkey.Connectors,
 Asphyre.Providers, Asphyre.Images, Asphyre.Fonts, Asphyre.Formats,
 Asphyre.Canvas, Asphyre.Textures, Asphyre.UI.Types, Asphyre.UI.Taskbar,
 Asphyre.UI.Controls, Asphyre.UI.Globals, Asphyre.UI.ListBoxes,
 Asphyre.UI.Forms, Asphyre.UI.Utils, Asphyre.Devices, GameTypes;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DCreate(Sender: TObject);
begin
 // The following option tells Asphyre that archive files containing images
 // and fonts will be located in the same folder as the EXE.
 // This is particularly important for Mac OS/X development where the media
 // file will be located in the same bundle path.
 ArchiveTypeAccess:= ataPackaged;

 // The following events are called by FireMonkey Asphyre Connect component.
 // This is different from classical Asphyre pipeline because there is no
 // explicit initialization and finalization; partly, the device is handled
 // by Firemonkey, while Asphyre handles its own internal parts.

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
 Timer.OnTimer  := OnTimer;
 Timer.OnProcess:= OnProcess;
 Timer.Enabled  := True;

 FirstTimeShow:= True;
 InitGuiStyle();

 AddItemNo:= 0;
end;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DDestroy(Sender: TObject);
begin
 // Remove the subscription to all events made by this class.
 EventProviders.Unsubscribe(ClassName);

 // Disconnect Asphyre device from FireMonkey.
 if (Assigned(GameDevice)) then GameDevice.Disconnect();

 // Finish the Asphyre connection manager.
 MonkeyAsphyreConnect.Done();
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceInit(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 DisplaySize:= Point2px(ClientWidth, ClientHeight);
 GameDevice.SwapChains.Add(NativeUInt(Self.Handle), DisplaySize);
end;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DResize(Sender: TObject);
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
procedure TMainForm.SysTimerTimer(Sender: TObject);
begin
 Timer.NotifyIdle();
end;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DRender(Sender: TObject; Context: TContext3D);
begin
 // If the render event is called from within FireMonkey, call our own event.
 if (Assigned(GameDevice))and(GameDevice.State = adsActive) then
  OnRender(Sender);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnTimerReset(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 // Avoid timer stall after lengthy operations.
 Timer.Reset();
end;

//---------------------------------------------------------------------------
procedure TMainForm.PaintRects(const UpdateRects: array of TRectF);
begin
 // This is a bug fix for flicker when pressing text keys.
 if (not Assigned(GameDevice))or(GameDevice.State <> adsActive) then
  inherited PaintRects(UpdateRects);
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
procedure TMainForm.OnDeviceCreate(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 GameImages.AddFromArchive('Icons.image', MediaFile, '', False);
 GameImages.AddFromArchive('Tahoma.image', MediaFile, '', False);

 fontTahoma:= GameFonts.Insert('media.asvf | Tahoma.xml', 'Tahoma.image');

 GameTaskbar.LoadFromArchive('MainFm.gui', MediaFile);

 if (fontTahoma <> -1) then SetupFontLetterSpacing();
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnTimer(Sender: TObject);
begin
 // Try to connect the FireMonkey interface to Asphyre.
 if (not MonkeyAsphyreConnect.Init(Context)) then Exit;

 // Try to hook the Asphyre device into FireMonkey.
 if (not Assigned(GameDevice))or(not GameDevice.Connect()) then Exit;

 // Check the state of all GUI controls.
 UpdateGuiControls();

 // If the above steps are finished, proceed to render the scene.
 GameDevice.Render(OnRender, $FF3A4691);

 // Do the independent processing.
 Timer.Process();
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnRender(Sender: TObject);
begin
 GameCanvas.ClipRect:= Bounds(0, 0, DisplaySize.x, DisplaySize.y);

 GameCanvas.ResetStates();
 GameCanvas.MipMapping:= False;

 GameTaskbar.ShowWindow('MainForm', FirstTimeShow);
 if (FirstTimeShow) then FirstTimeShow:= False;

 GameTaskbar.Draw();

 GameFonts[fontTahoma].TextOut(
  Point2(4.0, 4.0),
  'Frame Rate: ' + IntToStr(Timer.FrameRate),
  cColor2($FFF2F3F9, $FFB6BCE2), 1.0);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnProcess(Sender: TObject);
begin
 GameTaskbar.Update();
end;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DMouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Single);
begin
 if (Assigned(GameTaskbar)) then
  GameTaskbar.MouseDown(Button, Shift, Round(x), Round(y));
end;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DMouseMove(Sender: TObject; Shift: TShiftState; X,
 Y: Single);
begin
 if (Assigned(GameTaskbar)) then
  GameTaskbar.MouseMove(Shift, Round(x), Round(y));
end;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DMouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Single);
begin
 if (Assigned(GameTaskbar)) then
  GameTaskbar.MouseUp(Button, Shift, Round(x), Round(y));
end;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DMouseWheel(Sender: TObject; Shift: TShiftState;
 WheelDelta: Integer; var Handled: Boolean);
begin
 if (Assigned(GameTaskbar)) then
  GameTaskbar.MouseWheel(Shift, WheelDelta, GameTaskbar.MousePos);
end;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DKeyDown(Sender: TObject; var Key: Word;
 var KeyChar: Char; Shift: TShiftState);
begin
 if (Assigned(GameTaskbar)) then
  begin
   // FireMonkey bugfix: KeyChar = ' ', Key = #0 (?)
   if (KeyChar = ' ') then Key:= AVK_SPACE;

   GameTaskbar.KeyDown(Key, Shift);
   GameTaskbar.KeyPress(KeyChar);
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DKeyUp(Sender: TObject; var Key: Word;
 var KeyChar: Char; Shift: TShiftState);
begin
 if (Assigned(GameTaskbar)) then
  begin
   // FireMonkey bugfix: KeyChar = ' ', Key = #0 (?)
   if (KeyChar = ' ') then Key:= AVK_SPACE;

   GameTaskbar.KeyUp(Key, Shift);
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.IsDialogKey(const Key: Word; const KeyChar: WideChar;
 const Shift: TShiftState; var IsDialog: Boolean);
begin
 if (Key = AVK_Tab) then
  begin
   // This hack intercepts "Tab" key, which is not sent to Form's key events.
   if (Assigned(GameTaskbar)) then
    begin
     GameTaskbar.KeyDown(AVK_TAB, Shift);
     GameTaskbar.KeyUP(AVK_TAB, Shift);
    end;

   IsDialog:= False;
  end else inherited;
end;

//---------------------------------------------------------------------------
procedure TMainForm.SetupFontLetterSpacing();
var
 Font: TAsphyreFont;
begin
 // This method illustrates how to manually specify the spacing between some
 // specific pair of letters to provide a better looking text.
 Font:= GameFonts[fontTahoma];
 if (not Assigned(Font)) then Exit;

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
procedure TMainForm.OnButtonClick(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
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
end.
