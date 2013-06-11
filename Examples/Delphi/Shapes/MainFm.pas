unit MainFm;
//---------------------------------------------------------------------------
// Asphyre Sphinx: Shapes Example
// This example illustrates different canvas shapes.
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
  Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    FailureHandled: Boolean;
    GameTicks : Integer;
    CacheStall: Integer;

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
 Asphyre.Providers.DX11, GameTypes;

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
procedure TMainForm.OnAsphyreCreate(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
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
procedure TMainForm.OnAsphyreDestroy(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
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
 GameDevice.SwapChains.Add( Self.Handle, DisplaySize, 8);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceCreate(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 GameImages.AddFromArchive('Kristen.image', MediaFile, '', False);
 fontKristen:= GameFonts.Insert('media.asvf | Kristen.xml', 'Kristen.image');

 PBoolean(Param)^:=
  (PBoolean(Param)^)and
  (fontKristen <> -1);
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
 GameDevice.Render(RenderEvent, $FF4E4433);

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
 HexMtx: TMatrix3;
 Omega, Kappa: Single;
 HoleAt, HoleSize: TPoint2;
 i: Integer;
begin
 // Draw gradient lines.
 for i:= 0 to DisplaySize.y div 20 do
  GameCanvas.Line(Point2(0.0, 0.0), Point2(DisplaySize.x, i * 20.0),
   $FF837256, $FF4E4433);

 for i:= 0 to DisplaySize.x div 20 do
  GameCanvas.Line(Point2(0.0, 0.0), Point2(i * 20.0, DisplaySize.y),
   $FF837256, $FF4E4433);

 // Draw Hexagon.
 HexMtx:=
  // Make hexagon with dimensions of 50x50.
  ScaleMtx3(Point2(50.0, 50.0)) *
  // Rotate hexagon with time.
  RotateMtx3(GameTicks * 0.00371) *
  // Position hexagon at one quarter of screen.
  TranslateMtx3(Point2(DisplaySize.x * 0.25, DisplaySize.y * 0.25));

 GameCanvas.FillHexagon(HexMtx, $00FF0000, $FFFFD728, $00FF0000, $FFFFD728,
  $00FF0000, $FFFFD728);

 // Draw Arc.
 Omega:= GameTicks * 0.01892;
 Kappa:= 1.25 * Pi + Sin(GameTicks * 0.01241) * 0.5 * Pi;

 GameCanvas.FillArc(
  Point2(DisplaySize.x * 0.75, DisplaySize.y * 0.25),
  Point2(70.0, 50.0), Omega, Omega + Kappa, 64,
  cColor4($FFA4E581, $FFFF9C00, $FF7728FF, $FFFFFFFF));

 // Draw small Ribbon.
 Omega:= GameTicks * 0.01134;
 Kappa:= 1.25 * Pi + Sin(GameTicks * 0.014751) * 0.5 * Pi;

 GameCanvas.FillRibbon(Point2(DisplaySize.x * 0.25, DisplaySize.y * 0.75),
  Point2(25.0, 20.0), Point2(45.0, 40.0), Omega, Omega + Kappa, 64,
  cColor4($FFFF244F, $FFACFF0D, $FF2B98FF, $FF7B42FF));

 // Draw large Ribbon.
 Omega:= GameTicks * 0.01721;
 Kappa:= 1.25 * Pi + Sin(GameTicks * 0.01042) * 0.5 * Pi;

 GameCanvas.FillRibbon(Point2(DisplaySize.x * 0.25, DisplaySize.y * 0.75),
  Point2(50.0, 45.0), Point2(70.0, 65.0), Omega, Omega + Kappa, 64,
  $FFFF244F, $FFACFF0D, $FF2B98FF, $FFA4E581, $FFFF9C00, $FF7728FF);

 // Draw hole with smooth internal border (using tape).
 HoleAt:=
  Point2(
   DisplaySize.x * 0.75 + Cos(GameTicks * 0.00718) * DisplaySize.x * 0.15,
   DisplaySize.y * 0.75 + Sin(GameTicks * 0.00912) * DisplaySize.y * 0.15);

 HoleSize:= Point2(40.0, 40.0);

 GameCanvas.QuadHole(
  Point2(DisplaySize.x * 0.5, DisplaySize.y * 0.5),
  Point2(DisplaySize.x * 0.5, DisplaySize.y * 0.5),
  HoleAt,
  HoleSize,
  $004E4433, $FFE4DED5, 64);

 GameCanvas.FillRibbon(HoleAt, HoleSize * 0.75, HoleSize, 0.0, 2.0 * Pi, 64,
  $004E4433, $004E4433, $004E4433, $FFE4DED5, $FFE4DED5, $FFE4DED5);

 // Draw information text.
 GameFonts[fontKristen].TextMidH(
  Vec2ToPx(Point2(DisplaySize.x * 0.25, DisplaySize.y * 0.25 + 70.0)),
  'Hexagon',
  cColor2($FFFFD25D, $FFFF0036));

 GameFonts[fontKristen].TextMidH(
  Vec2ToPx(Point2(DisplaySize.x * 0.75, DisplaySize.y * 0.25 + 70.0)),
  'Arc',
  cColor2($FFE5FF3B, $FF00FF00));

 GameFonts[fontKristen].TextMidH(
  Vec2ToPx(Point2(DisplaySize.x * 0.25, DisplaySize.y * 0.75 + 80.0)),
  'Tapes',
  cColor2($FFEAFAFF, $FF7B42FF));

 GameFonts[fontKristen].TextMidH(
  Vec2ToPx(Point2(DisplaySize.x * 0.75, DisplaySize.y * 0.75 + 80.0)),
  'Hole + tape',
  cColor2($FFFFF4B3, $FFA9824C));

 GameFonts[fontKristen].TextOut(
  Point2(4.0, 4.0),
  'FPS: ' + IntToStr(Timer.FrameRate) + ', Cache Stall: ' + IntToStr(CacheStall),
  cColor2($FFFFFF62, $FFFF8424), 1.0);

 GameFonts[fontKristen].TextOut(
  Point2(4.0, 34.0),
  'Technology: ' + GetFullDeviceTechString(GameDevice),
  cColor2($FFE8FFAA, $FF12C312));

 GameCanvas.Flush();
 CacheStall:= GameCanvas.CacheStall;
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
