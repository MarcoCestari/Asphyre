unit MainFm;
//---------------------------------------------------------------------------
// Basic Asphyre Example.
// This example can be used as a new sheet for your applications.
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
    GameTicks: Integer;

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
 Asphyre.FormTimers, Asphyre.Providers, Asphyre.Archives, Asphyre.Devices,
 Asphyre.Images, Asphyre.Fonts, Asphyre.Canvas, Asphyre.Native.Connectors,
 Asphyre.Providers.DX9, GameTypes, Asphyre.Adapters.Win;

//---------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
 // Enable Delphi's memory manager to show memory leaks.
 ReportMemoryLeaksOnShutdown:= DebugHook <> 0;

 // Specify that DirectX 9 provider is to be used.
 Factory.UseProvider(idDirectX9);

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
 Timer.Enabled:= False;

 FreeAndNil(GameFonts);
 FreeAndNil(GameImages);
 FreeAndNil(MediaFile);
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
 GameImages.AddFromArchive('tahoma9b.image', MediaFile, '', False);

 fontTahoma:= GameFonts.Insert('media.asvf | tahoma9b.xml', 'tahoma9b.image');
 imageLena := GameImages.AddFromArchive( 'lena.image', MediaFile);

 PBoolean(Param)^:=
  (PBoolean(Param)^)and
  (fontTahoma <> -1)and
  (imageLena <> -1);
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

 // Render the scene.
 GameDevice.Render(RenderEvent, $000050);

 // Execute constant time processing.
 Timer.Process();
end;

//---------------------------------------------------------------------------
procedure TMainForm.ProcessEvent(Sender: TObject);
begin
 Inc(GameTicks);
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderEvent(Sender: TObject);
var
 j, i: Integer;
 Omega, Kappa: Single;
begin
 // Draw gray background.
 for j:= 0 to DisplaySize.y div 40 do
  for i:= 0 to DisplaySize.x div 40 do
   GameCanvas.FillQuad(
    pBounds4(i * 40, j * 40, 40, 40),
    cColor4($FF585858, $FF505050, $FF484848, $FF404040));

 for i:= 0 to DisplaySize.x div 40 do
  GameCanvas.Line(
   Point2(i * 40.0, 0.0),
   Point2(i * 40.0, DisplaySize.y),
   $FF505050);

 for j:= 0 to DisplaySize.y div 40 do
  GameCanvas.Line(
   Point2(0.0, j * 40.0),
   Point2(DisplaySize.x, j * 40.0),
   $FF505050);

 // Draw an animated hole.
 GameCanvas.QuadHole(
  Point2(0.0, 0.0),
  Point2(DisplaySize.x, DisplaySize.y),
  Point2(
   DisplaySize.x * 0.5 + Cos(GameTicks * 0.0073) * DisplaySize.x * 0.25,
   DisplaySize.y * 0.5 + Sin(GameTicks * 0.00312) * DisplaySize.y * 0.25),
  Point2(80.0, 100.0),
  $20FFFFFF, $80955BFF, 16);

 // Draw the image of famous Lenna.
 GameCanvas.UseImagePx(GameImages[imageLena], pBounds4(0, 0, 512, 512));
 GameCanvas.TexMap(pRotate4c(
  Point2(400.0, 300.0),
  Point2(300.0, 300.0),
  GameTicks * 0.01),
  cAlpha4(128));

 // Draw an animated Arc.
 Omega:= GameTicks * 0.0274;
 Kappa:= 1.25 * Pi + Sin(GameTicks * 0.01854) * 0.5 * Pi;

 GameCanvas.FillArc(Point2(DisplaySize.x * 0.1, DisplaySize.y * 0.9),
  Point2(75.0, 50.0), Omega, Omega + Kappa, 32,
  cColor4($FFFF0000, $FF00FF00, $FF0000FF, $FFFFFFFF));

 // Draw an animated Ribbon.
 Omega:= GameTicks * 0.02231;
 Kappa:= 1.25 * Pi + Sin(GameTicks * 0.024751) * 0.5 * Pi;

 GameCanvas.FillRibbon(Point2(DisplaySize.x * 0.9, DisplaySize.y * 0.85),
  Point2(25.0, 20.0), Point2(70.0, 80.0), Omega, Omega + Kappa, 32,
  cColor4($FFFF0000, $FF00FF00, $FF0000FF, $FFFFFFFF));

 GameFonts[fontTahoma].TextOut(
  Point2(4.0, 4.0),
  'FPS: ' + IntToStr(Timer.FrameRate),
  cColor2($FFFFE887, $FFFF0000));

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
end.
