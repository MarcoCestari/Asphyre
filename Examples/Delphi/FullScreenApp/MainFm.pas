unit MainFm;
//---------------------------------------------------------------------------
// Full-screen multi-monitor example.
// Shows how to use fullscreen mode and multiple monitors.
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
// This example illustrates the handling of full-screen mode and special
// events such as Alt + Tab and similar. In addition, this application shows
// how to render on two monitors simultaneously in full-screen.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    FailureHandled: Boolean;
    AppInactive: Boolean;

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
    procedure OnProcess(Sender: TObject);

    procedure RenderPrimary(Sender: TObject);
    procedure RenderSecondary(Sender: TObject);

    procedure HandleConnectFailure();

    procedure AppActivate(Sender: TObject);
    procedure AppDeactivate(Sender: TObject);
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
 Asphyre.Math, Asphyre.Types, Asphyre.FormTimers, Asphyre.Events.Types,
 Asphyre.Events, Asphyre.Providers, Asphyre.Native.Connectors, Asphyre.Images,
 Asphyre.Fonts, Asphyre.RenderTargets, Asphyre.Textures, Asphyre.Archives,
 Asphyre.Canvas, Asphyre.Devices, Asphyre.Providers.DX11, GameTypes, SecondFm;

//---------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
 // Configure the current window to be placed in full-screen mode on the
 // first monitor.
 if (Screen.MonitorCount > 0) then
  begin
   BorderStyle:= bsNone;
   Left:= Screen.Monitors[0].Left;
   Top := Screen.Monitors[0].Top;

   Width := Screen.Monitors[0].Width;
   Height:= Screen.Monitors[0].Height;
  end;

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

 // Initialize and prepare the timer.
 Timer.OnTimer  := OnTimer;
 Timer.OnProcess:= OnProcess;
 Timer.Enabled  := True;

 // Tell AsphyreManager that the archive will always be in the same folder
 // as this application.
 ArchiveTypeAccess:= ataPackaged;

 // This variable tells that a connection failure to Asphyre device has been
 // already handled.
 FailureHandled:= False;

 // These events will handle Alt + Tab scenario.
 Application.OnActivate:= AppActivate;
 Application.OnDeactivate:= AppDeactivate;

 AppInactive:= False;
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
procedure TMainForm.FormResize(Sender: TObject);
begin
 if (Assigned(GameDevice))and(not AppInactive) then
  begin
   PrimarySize:= Point2px(ClientWidth, ClientHeight);
   GameDevice.Resize(0, PrimarySize);
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreCreate(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 // If more than one monitor is present, create the second form and place
 // it on the second monitor.
 if (not Assigned(SecondForm))and(Screen.MonitorCount > 1) then
  begin
   SecondForm:= TSecondForm.Create(Self);
   SecondForm.Show();

   SecondForm.BorderStyle:= bsNone;
   SecondForm.Left:= Screen.Monitors[1].Left;
   SecondForm.Top := Screen.Monitors[1].Top;

   SecondForm.Width := Screen.Monitors[1].Width;
   SecondForm.Height:= Screen.Monitors[1].Height;
  end;

 // Create all Asphyre components.
 GameDevice:= Factory.CreateDevice();

 GameCanvas:= Factory.CreateCanvas();
 GameImages:= TAsphyreImages.Create();

 GameFonts:= TAsphyreFonts.Create();
 GameFonts.Images:= GameImages;
 GameFonts.Canvas:= GameCanvas;

 MediaFile:= TAsphyreArchive.Create();
 MediaFile.OpenMode:= aomReadOnly;
 MediaFile.FileName:= 'media.asvf';
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreDestroy(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 // Disable the timer to prevent it from occuring.
 Timer.Enabled:= False;

 // Release all Asphyre components.
 FreeAndNil(MediaFile);
 FreeAndNil(GameFonts);
 FreeAndNil(GameImages);
 FreeAndNil(GameCanvas);
 FreeAndNil(GameDevice);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceInit(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 PrimarySize:= Point2px(ClientWidth, ClientHeight);

 GameDevice.SwapChains.RemoveAll();
 GameDevice.SwapChains.Add(Self.Handle, PrimarySize);

 // Add the second form to swap chain registry.
 if (Assigned(SecondForm)) then
  GameDevice.SwapChains.Add(SecondForm.Handle, SecondarySize);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceCreate(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 GameImages.AddFromArchive('BookAntiqua24.image', MediaFile, '', False);
 fontBookAntiqua:= GameFonts.Insert('media.asvf | BookAntiqua24.xml',
  'BookAntiqua24.image');

 PBoolean(Param)^:=
  (PBoolean(Param)^)and
  (fontBookAntiqua <> -1);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnTimer(Sender: TObject);
begin
 if (AppInactive) then
  begin
   Sleep(15);
   Exit;
  end;

 // Try to connect Asphyre to the application.
 if (not NativeAsphyreConnect.Init()) then Exit;

 // In case the device could not be initialized properly (in the frame before
 // this one), show the message and close the form.
 if (Assigned(GameDevice))and(GameDevice.State = adsInitFailed) then
  begin
   if (not FailureHandled) then HandleConnectFailure();
   FailureHandled:= True;
   Exit;
  end;

 // Initialize Asphyre device, if needed. If this initialization fails, the
 // failure will be handled in the next OnTimer event.
 if (not Assigned(GameDevice))or(not GameDevice.Connect()) then Exit;

 // If the above steps are finished, proceed to render the scene.
 GameDevice.Render(RenderPrimary, $FF000040);

 if (Assigned(SecondForm)) then
  GameDevice.Render(1, RenderSecondary, $FF404040);

 Timer.Process();
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderPrimary(Sender: TObject);
begin
 GameFonts[fontBookAntiqua].Whitespace:= 12;

 GameFonts[fontBookAntiqua].TextOut(Point2(4.0, 4.0),
  'This text should appear on first monitor.',
  cColor2($FFE8F9FF, $FFAEE2FF));

 GameFonts[fontBookAntiqua].TextOut(
  Point2(4.0, 4.0 + 40.0),
  'Frame Rate: ' + IntToStr(Timer.FrameRate),
  cColor2($FFEED1FF, $FFA1A0FF));

 GameFonts[fontBookAntiqua].TextOut(
  Point2(4.0, 4.0 + 80.0),
  'Technology: ' + GetFullDeviceTechString(GameDevice),
  cColor2($FFE8FFAA, $FF12C312));
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderSecondary(Sender: TObject);
begin
 GameFonts[fontBookAntiqua].Whitespace:= 12;

 GameFonts[fontBookAntiqua].TextOut(Point2(4.0, 4.0),
  'This text should appear on second monitor.',
  cColor2($FFFFD27B, $FFFF0000));

 GameFonts[fontBookAntiqua].TextOut(
  Point2(4.0, 4.0 + 40.0),
  'Frame Rate: ' + IntToStr(Timer.FrameRate),
  cColor2($FFE4FFA5, $FF00E000));
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnProcess(Sender: TObject);
begin
 Inc(GameTicks);
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
procedure TMainForm.AppActivate(Sender: TObject);
begin
 AppInactive:= False;
end;

//---------------------------------------------------------------------------
procedure TMainForm.AppDeactivate(Sender: TObject);
begin
 AppInactive:= True;
 Application.Minimize();
end;

//---------------------------------------------------------------------------
end.
