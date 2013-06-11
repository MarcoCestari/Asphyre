unit MainFm;
//---------------------------------------------------------------------------
// Custom shader effects example for Asphyre.
// Illustrates how to write custom shader effects.
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
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Asphyre.Shaders.DX10;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
    FailureHandled: Boolean;
    CustomEffect: TDX10CanvasEffect;

    SmoothDistance: Single;

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

    procedure HandleConnectFailure();

    procedure SetCanvasTech(const TechName: string);
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
 System.Math, Asphyre.Math, Asphyre.Types, Asphyre.FormTimers,
 Asphyre.Events.Types, Asphyre.Events, Asphyre.Providers,
 Asphyre.Native.Connectors, Asphyre.Images, Asphyre.Fonts,
 Asphyre.RenderTargets, Asphyre.Textures, Asphyre.Archives,
 Asphyre.Canvas, Asphyre.Devices, Asphyre.Canvas.DX10, Asphyre.Providers.DX10,
 GameTypes;

//---------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
 ReportMemoryLeaksOnShutdown:= DebugHook <> 0;

 // Specify that DirectX 10 provider is to be used.
 Factory.UseProvider(idDirectX10);

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

 CustomEffect:= TDX10CanvasEffect.Create();

 MediaFile:= TAsphyreArchive.Create();
 MediaFile.OpenMode:= aomReadOnly;
 MediaFile.FileName:= 'media.asvf';

 SmoothDistance:= 2.0;
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreDestroy(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 // Disable the timer to prevent it from occuring.
 Timer.Enabled:= False;

 // Release all Asphyre components.
 FreeAndNil(MediaFile);
 FreeAndNil(CustomEffect);
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
procedure TMainForm.OnDeviceCreate(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
var
 FileName: string;
 EffectLoaded: Boolean;
begin
 GameImages.AddFromArchiveEx('Candara.image', MediaFile, '', apf_A8R8G8B8, False, False);
 GameImages.AddFromArchive('TempusSans.image', MediaFile);

 fontCandara:= GameFonts.Insert('media.asvf | Candara.xml', 'Candara.image');

 fontTempusSans:= GameFonts.Insert('media.asvf | TempusSans.xml',
  'TempusSans.image');

 imageFlowers:= GameImages.AddFromArchive('flowers.image', MediaFile);

 FileName:= ExtractFilePath(ParamStr(0)) + 'effect\custom.fxo';
 EffectLoaded:= CustomEffect.LoadCompiledFromFile(FileName);

 PBoolean(Param)^:=
  (PBoolean(Param)^)and
  (fontCandara <> -1)and
  (fontTempusSans <> -1)and
  (imageFlowers <> -1)and
  (EffectLoaded);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnTimer(Sender: TObject);
begin
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
 GameDevice.Render(OnRender, $FF222B3A);

 Timer.Process();
end;

//---------------------------------------------------------------------------
procedure TMainForm.SetCanvasTech(const TechName: string);
begin
 if (GameCanvas is TDX10Canvas) then
  begin
   TDX10Canvas(GameCanvas).CustomEffect:= CustomEffect;
   TDX10Canvas(GameCanvas).CustomTechnique:= TechName;
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnRender(Sender: TObject);
const
 ImageSize: TPoint2px = (x: 500; y: 362);
var
 DrawAt: TPoint2px;
 SmoothAlpha: Single;
begin
 // Display blurred image.
 DrawAt.x:= (DisplaySize.x - ImageSize.x) div 2;
 DrawAt.y:= ((DisplaySize.y - ImageSize.y) div 2) - 10;

 SmoothAlpha:= (Sin(GameTicks * 0.0732) + 1.0) * 0.5;

 CustomEffect.Variables.SetPoint2('TexSize', ImageSize);
 CustomEffect.Variables.SetFloat('SmoothAlpha', SmoothAlpha);
 CustomEffect.Variables.SetFloat('SmoothDistance', SmoothDistance);
 SetCanvasTech('BlurTechnique');

 GameCanvas.UseImagePt(GameImages[imageFlowers], 0);
 GameCanvas.TexMap(pBounds4(DrawAt.x, DrawAt.y, ImageSize.x, ImageSize.y),
  clWhite4);

 GameCanvas.Flush();

 // Display text with Glow effect.
 GameFonts[fontCandara].Whitespace:= 10.0;

 CustomEffect.Variables.SetPoint2('TexSize', Point2(128.0, 128.0));
 SetCanvasTech('GlowTechnique');

 GameFonts[fontCandara].TextMidF(
  Point2(DisplaySize.x * 0.5, DisplaySize.y - 60),
  'This font is rendered using Glow Effect!',
  cColor2($FFE5FFAA, $FF00E000));

 SetCanvasTech('');

 GameFonts[fontCandara].TextMidF(
  Point2(DisplaySize.x * 0.5, DisplaySize.y - 20),
  'This font is rendered without effects!',
  cColor2($FFECD661, $FFED561D));

 // Render 1-pixel frame around the image.
 GameCanvas.FrameRect(
  pBounds4(DrawAt.x, DrawAt.y, ImageSize.x, ImageSize.y),
  cColor4($FF64748E));

 // Display text hint.
 GameFonts[fontTempusSans].TextMidH(
  Point2px(DrawAt.x + (ImageSize.x div 2), DrawAt.y + ImageSize.y + 4),
  'This image has real-time blur applied with variable strength.',
  cColor2($FFEEE8E0, $FF8C744D));

 // Display information text.
 GameFonts[fontTempusSans].TextOut(Point2(4.0, 4.0),
  'FPS: ' + IntToStr(Timer.FrameRate),
  cColor2($FFD7FF97, $FF37DE47));

 GameFonts[fontTempusSans].TextOut(
  Point2(4.0, 24.0),
  'Technology: ' + GetFullDeviceTechString(GameDevice),
  cColor2($FFFFE040, $FFFF0000));

 GameFonts[fontTempusSans].TextOut(Point2(4.0, 44.0),
  'Smooth distance: ' + Format('%1.1f', [SmoothDistance]),
  cColor2($FFFFEA28, $FFFF9D03));

 GameFonts[fontTempusSans].TextOut(Point2(4.0, 64.0),
  'Press [Up] and [Down] keys to change the distance.',
  cColor2($FFA9F9E8, $FF3EAB5E));
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
procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
 Shift: TShiftState);
begin
 if (Key = VK_UP) then SmoothDistance:= Min(SmoothDistance + 0.5, 10.0);
 if (Key = VK_DOWN) then SmoothDistance:= Max(SmoothDistance - 0.5, 0.5);
end;

//---------------------------------------------------------------------------
end.
