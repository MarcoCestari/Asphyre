unit MainFm;
//---------------------------------------------------------------------------
// Compact Fonts example for Asphyre Sphinx.
// Illustrates the use and implementation of "apf_A5L3" pixel format.
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
// This example shows how to use custom shader code for interpreting images
// stored in custom pixel formats. Specifically, this example uses apf_A8L3
// pixel format that is defined by Asphyre but not supported natively by
// underlying APIs. However, this format can easily be interpreted directly
// in pixel shader when sampling the texture.
//
// The mentioned pixel format can be particularly useful for fonts that are
// either too large or contain many characters (e.g. in Chinese charsets)
// because it only uses 8 bits per pixel.
//
// The limitations of this implementation, however, is that DX10 is required
// for the shader to run; antialiasing and multisampling are not supported.
//
// Note that DX9- supported A4L4 on some video cards, but it looks worse with
// the rendered fonts. This is because fonts tend to have more data in alpha
// channel and less data in the luminance component. In addition, this format
// is supported only on a handful of DX9- video cards.
//
// The performance hit from using A5L3 format is relatively low considering
// that canvas caching is still used (check CanvasStall value) and since the
// processing is made in pixel shader, it will run decently on the majority
// of video cards that are DX10-compliant.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
  System.SysUtils, Vcl.Forms, Vcl.Dialogs, Asphyre.Shaders.DX10;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FailureHandled: Boolean;

    CustomEffect: TDX10CanvasEffect;

    CanvasStall: Integer;

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
 Asphyre.Math, Asphyre.Types, Asphyre.FormTimers, Asphyre.Events.Types,
 Asphyre.Events, Asphyre.Providers, Asphyre.Native.Connectors, Asphyre.Images,
 Asphyre.Fonts, Asphyre.RenderTargets, Asphyre.Textures, Asphyre.Archives,
 Asphyre.Canvas, Asphyre.Devices, Asphyre.Canvas.DX10, Asphyre.Providers.DX10,
 GameTypes;

//---------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
 Factory.UseProvider(idDirectX10);

 EventAsphyreCreate.Subscribe(ClassName, OnAsphyreCreate);
 EventAsphyreDestroy.Subscribe(ClassName, OnAsphyreDestroy);
 EventDeviceInit.Subscribe(ClassName, OnDeviceInit);
 EventDeviceCreate.Subscribe(ClassName, OnDeviceCreate);
 EventTimerReset.Subscribe(ClassName, OnTimerReset);

 Timer.OnTimer  := OnTimer;
 Timer.OnProcess:= OnProcess;
 Timer.Enabled  := True;

 ArchiveTypeAccess:= ataPackaged;
 FailureHandled:= False;
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormDestroy(Sender: TObject);
begin
 if (Assigned(GameDevice)) then GameDevice.Disconnect();
 NativeAsphyreConnect.Done();
 EventProviders.Unsubscribe(ClassName);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreCreate(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
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
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreDestroy(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 Timer.Enabled:= False;

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
 // Normal version of text font. In the archive it is stored as A8L8. When
 // loaded with DX10 provider, it is converted to R8G8 format, which is then
 // in internal shader is interpreted as A8L8. On DX9- providers, it is loaded
 // natively as A8L8 and treated as such in fixed-function pipeline.
 GameImages.AddFromArchive('TempusSans.image', MediaFile);

 fontTempusSans:= GameFonts.Insert('media.asvf | TempusSans.xml',
  'TempusSans.image');

 // Compact version of text font. It is converted from archive format of A8L8
 // to A5L3 stored in DX10 texture as R8 format. In custom shader effect, it
 // is properly converted to ARGB format.
 GameImages.AddFromArchiveEx('TempusSans.image', MediaFile,
  'TempusSansComp.image', apf_A5L3, False);

 fontTempusSansComp:= GameFonts.Insert('media.asvf | TempusSans.xml',
  'TempusSansComp.image');

 FileName:= ExtractFilePath(ParamStr(0)) + 'effect\custom.fxo';
 EffectLoaded:= CustomEffect.LoadCompiledFromFile(FileName);

 PBoolean(Param)^:=
  (PBoolean(Param)^)and
  (fontTempusSans <> -1)and
  (fontTempusSansComp <> -1)and
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
 GameDevice.Render(OnRender, $FF2E2A88);

 Timer.Process();
end;

//---------------------------------------------------------------------------
procedure TMainForm.SetCanvasTech(const TechName: string);
begin
 // Setting the technique is only supported on DX10 canvas.
 if (GameCanvas is TDX10Canvas) then
  begin
   TDX10Canvas(GameCanvas).CustomEffect:= CustomEffect;
   TDX10Canvas(GameCanvas).CustomTechnique:= TechName;
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnRender(Sender: TObject);
begin
 // Specify that we are using a custom shader effect and technique.
 SetCanvasTech('CompactFontTech');

 // Render the text using compact pixel format.
 GameFonts[fontTempusSansComp].TextMidF(
  Point2(DisplaySize.x * 0.5, DisplaySize.y * 0.25 - 15.0),
  'This text font is stored in "apf_A5L3" pixel format with only 8 bits (= 1 byte) per pixel.',
  cColor2($FFFFFFFF, $FF74FF1F));

 GameFonts[fontTempusSansComp].TextMidF(
  Point2(DisplaySize.x * 0.5, DisplaySize.y * 0.25 + 15.0),
  'Another line of text in compact pixel format. As you can see, it really looks okay!',
  cColor2($FFFFE35B, $FFFF0000));

 // Reset the custom technique to make canvas work using native approach.
 SetCanvasTech('');

 // This text should appear garbled because natively A5L3 format is not
 // supported properly.
 GameFonts[fontTempusSansComp].TextMidF(
  Point2(DisplaySize.x * 0.5, DisplaySize.y * 0.5),
  'If you do not use custom shader, the text in compact format will look garbled like this.',
  cColor2($FFFFFFFF));

 // Display some text using high-quality pixel format for comparison.
 GameFonts[fontTempusSans].TextMidF(
  Point2(DisplaySize.x * 0.5, DisplaySize.y * 0.75 - 15.0),
  'This font uses original pixel format "apf_A8L8", which has 16 bits (= 2 bytes) per pixel.',
  cColor2($FFFFFFFF, $FF74FF1F));

 GameFonts[fontTempusSans].TextMidF(
  Point2(DisplaySize.x * 0.5, DisplaySize.y * 0.75 + 15.0),
  'As you can see, it looks similar to the compact version but using double of texture memory.',
  cColor2($FFFFE35B, $FFFF0000));

 // Display the information about frame rate and canvas stall.
 GameFonts[fontTempusSans].TextOut(Point2(4.0, 4.0),
  'Frame Rate: ' + IntToStr(Timer.FrameRate) + ' fps, Cache Stall: ' +
   IntToStr(CanvasStall), cColor2($FFEDF8FF, $FFA097FF));

 GameFonts[fontTempusSans].TextOut(
  Point2(4.0, 24.0),
  'Technology: ' + GetFullDeviceTechString(GameDevice),
  cColor2($FFE8FFAA, $FF12C312));

 // Flush the canvas to properly calculate the stall value.
 GameCanvas.Flush();
 CanvasStall:= GameCanvas.CacheStall;
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnProcess(Sender: TObject);
begin
 // No code here. This place is for doing constant time-based processing.
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
