unit MainFm;
//---------------------------------------------------------------------------
// Multiple render targets and swap chains example.
// Illustrates rendering to different render targets and panels.
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
  Vcl.Dialogs, Vcl.ExtCtrls;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FailureHandled: Boolean;
    GameTicks: Integer;

    DrawIndex: Integer;
    MixIndex : Integer;

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

    procedure RenderPrimary(Sender: TObject);
    procedure RenderSecondary(Sender: TObject);

    procedure RenderMotion(Sender: TObject);
    procedure RenderBlur(Sender: TObject);

    procedure HandleConnectFailure();
  public
    { Public declarations }
  end;

//---------------------------------------------------------------------------
var
  MainForm: TMainForm;

//---------------------------------------------------------------------------
implementation
uses
 Asphyre.Math, Asphyre.Types, Asphyre.Events.Types, Asphyre.Events,
 Asphyre.FormTimers, Asphyre.Providers, Asphyre.Archives, Asphyre.Devices,
 Asphyre.Images, Asphyre.Fonts, Asphyre.Canvas, Asphyre.RenderTargets,
 Asphyre.Native.Connectors, Asphyre.Providers.DX11, GameTypes;
{$R *.dfm}

//---------------------------------------------------------------------------
const
 OrigPx: TPoint4 = (
  (x:   0 + 4; y: 0 + 4),
  (x: 256 - 1; y: 0 + 3),
  (x: 256 - 3; y: 256 - 1),
  (x:   0 + 1; y: 256 - 4));

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
 GameDevice := Factory.CreateDevice();
 GameCanvas := Factory.CreateCanvas();
 GameImages := TAsphyreImages.Create();
 GameTargets:= TAsphyreRenderTargets.Create();

 GameFonts:= TAsphyreFonts.Create();
 GameFonts.Images:= GameImages;
 GameFonts.Canvas:= GameCanvas;

 MediaFile:= TAsphyreArchive.Create();
 MediaFile.OpenMode:= aomReadOnly;
 MediaFile.FileName:= 'media.asvf';

 // Init render target swapping parameters.
 DrawIndex:= 0;
 MixIndex := 0;
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreDestroy(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 Timer.Enabled:= False;

 FreeAndNil(GameFonts);
 FreeAndNil(GameTargets);
 FreeAndNil(GameImages);
 FreeAndNil(MediaFile);
 FreeAndNil(GameCanvas);
 FreeAndNil(GameDevice);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceInit(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 DisplaySize:= Point2px(256, 256);

 // Include both panels into swap chain descriptions.
 GameDevice.SwapChains.Add(Panel1.Handle, Point2px(Panel1.Width, Panel1.Height));
 GameDevice.SwapChains.Add(Panel2.Handle, Point2px(Panel2.Width, Panel2.Height));
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceCreate(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 // Load images used by bitmap fonts.
 GameImages.AddFromArchive('tahoma9b.image', MediaFile);
 GameImages.AddFromArchive('calibri.image', MediaFile);

 // Load bitmap font descriptions.
 fontTahoma:= GameFonts.Insert('/media.asvf | tahoma9b.xml', 'tahoma9b.image');
 fontCalibri:= GameFonts.Insert('/media.asvf | calibri.xml', 'calibri.image');

 // Create 4 render targets
 swapDraw:= GameTargets.Add(2, 256, 256, apf_A8R8G8B8, True, True);
 swapMix := GameTargets.Add(2, 256, 256, apf_A8R8G8B8, True, True);

 // Notify the device if the creation failed.
 PBoolean(Param)^:=
  (PBoolean(Param)^)and
  (swapDraw <> -1)and
  (swapMix <> -1)and
  (fontCalibri <> -1)and
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

 // Render scene to the first pair of render targets.
 GameDevice.RenderTo(RenderMotion, 0, True,
  GameTargets[swapDraw + DrawIndex xor 1]);

 // Render scene to the second pair of render targets.
 GameDevice.RenderTo(RenderBlur, 0, False,
  GameTargets[swapMix + MixIndex xor 1]);

 // Render some scene on first panel.
 GameDevice.Render(0, RenderPrimary, $000000);

 // Render another scene on second panel.
 GameDevice.Render(1, RenderSecondary,  $000000);

 // Do some constant time processing.
 Timer.Process();

 // Exchange the render targets.
 DrawIndex:= DrawIndex xor 1;
 MixIndex := MixIndex xor 1;
end;

//---------------------------------------------------------------------------
procedure TMainForm.ProcessEvent(Sender: TObject);
begin
 Inc(GameTicks);
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderMotion(Sender: TObject);
var
 Theta, RibbonLength: Single;
begin
 Theta:= (GameTicks mod 200) * Pi / 100;
 RibbonLength:= (1.0 + Sin(GameTicks / 50.0)) * Pi * 2 / 3 + (Pi / 3);

 GameCanvas.FillRibbon(Point2(128, 128 - 32), Point2(16.0, 24.0),
  Point2(48.0, 32.0), Theta, Theta + RibbonLength, 24,
  cColor4($FF7E00FF, $FF75D3FF, $FFD1FF75, $FFFFC042));

 GameFonts[fontCalibri].TextOut(
  Point2(-128 + GameTicks mod 384, 160.0),
  'Motion Blur!',
  cColor2($FFFFE000, $FFFF0000), 1.0);
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderBlur(Sender: TObject);
begin
 // Copy previous scene, englarged and slightly rotated.
 GameCanvas.UseTexturePx(GameTargets[swapMix + MixIndex], OrigPx);
 GameCanvas.TexMap(pBounds4(0.0, 0.0, 256.0, 256.0), clWhite4);

 // Darken the area slightly, to avoid color mess :)
 // Replace color parameter to $FFF0F0F0 to reduce the effect.
 GameCanvas.FillRect(0, 0, 256, 256, $FFF0F0F0, beMultiply);

 // Add the "motion scene" on our working surface.
 GameCanvas.UseTexture(GameTargets[swapDraw + DrawIndex], TexFull4);
 GameCanvas.TexMap(pBounds4(0.0, 0.0, 256.0, 256.0), cAlpha4(224));
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderPrimary(Sender: TObject);
var
 Theta, Length: Single;
begin
 GameCanvas.FillQuad(pBounds4(2, 2, 50, 50),
  cColor4($FF00FF00, $FFFF0000, $FF0000FF, $FFFFFFFF));

 GameCanvas.FillQuad(pBounds4(54, 2, 50, 50),
  cColor4($FF000000, $FFFF00FF, $FFFFFF00, $FF00FFFF));

 GameCanvas.FillQuad(pBounds4(2, 54, 50, 50),
  cColor4($FF95E792, $FFBD7700, $FF000000, $FFB3ECFF));

 GameCanvas.FillQuad(pBounds4(54, 54, 50, 50),
  cColor4($FF7E00FF, $FF75D3FF, $FFD1FF75, $FFFFC042));

 Theta := (GameTicks mod 300) * Pi / 150;
 Length:= (1.0 + Sin(GameTicks / 50.0)) * Pi * 2 / 3 + (Pi / 3);

 GameCanvas.FillArc(Point2(150, 150), Point2(80, 70), Theta, Theta + Length, 24,
  cColor4($FF6703FF, $FFAFFF03, $FFFFA703, $FFFFFFFF));

 GameFonts[fontTahoma].TextOut(
  Point2(4.0, 240.0),
  'FPS: ' + IntToStr(Timer.FrameRate),
  cColor2($FFFFE887, $FFFF0000), 1.0);

 GameFonts[fontTahoma].TextOut(
  Point2(4.0, 220.0),
  'Tech: ' + GetFullDeviceTechString(GameDevice),
  cColor2($FFE8FFAA, $FF12C312));
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderSecondary(Sender: TObject);
begin
 // Just render the "mixed" scene on the second panel.
 GameCanvas.UseTexture(GameTargets[swapMix + MixIndex], TexFull4);
 GameCanvas.TexMap(pBounds4(0.0, 0.0, 256.0, 256.0), clWhite4);
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
