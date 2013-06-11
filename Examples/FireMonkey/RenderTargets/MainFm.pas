unit MainFm;
//---------------------------------------------------------------------------
// Asphyre Render Targets example.
// Illustrates how to use render targets with FireMonkey.
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
  FMX.Controls, FMX.Forms, FMX.Forms3D, FMX.Dialogs;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm3D)
    SecTimer: TTimer;
    procedure Form3DCreate(Sender: TObject);
    procedure Form3DDestroy(Sender: TObject);
    procedure Form3DResize(Sender: TObject);
    procedure SecTimerTimer(Sender: TObject);
  private
    { Private declarations }
    FailureHandled: Boolean;

    MotionNo: Integer;
    BlurNo  : Integer;

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
    procedure RenderMotion(Sender: TObject);
    procedure RenderBlur(Sender: TObject);
    procedure OnProcess(Sender: TObject);

    procedure HandleConnectFailure();
  public
    { Public declarations }
  end;

//---------------------------------------------------------------------------
var
  MainForm: TMainForm;

//---------------------------------------------------------------------------
implementation
{$R *.fmx}

//---------------------------------------------------------------------------
uses
 Asphyre.Math, Asphyre.Types, Asphyre.FeedTimers, Asphyre.Providers,
 Asphyre.Events.Types, Asphyre.Events, Asphyre.Monkey.Connectors,
 Asphyre.Archives, Asphyre.Images, Asphyre.Fonts, Asphyre.Timing,
 Asphyre.Textures, Asphyre.Canvas, Asphyre.RenderTargets, GameTypes;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DCreate(Sender: TObject);
begin
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
 Timer.MaxFPS   := 4000;
 Timer.OnTimer  := OnTimer;
 Timer.OnProcess:= OnProcess;
 Timer.Enabled  := True;

 // Tell AsphyreManager that the archive will always be in the same folder
 // as this application.
 ArchiveTypeAccess:= ataPackaged;

 // This variable tells that a connection failure to Asphyre device has been
 // already handled.
 FailureHandled:= False;

 MotionNo:= 0;
 BlurNo  := 0;

 ArchiveTypeAccess:= ataPackaged;
 ArchiveHInstance := hInstance;
end;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DDestroy(Sender: TObject);
begin
 // Remove the subscription to the events.
 EventProviders.Unsubscribe(ClassName);

 // Disconnect Asphyre device from FireMonkey.
 if (Assigned(GameDevice)) then GameDevice.Disconnect();

 // Finish the Asphyre connection manager.
 MonkeyAsphyreConnect.Done();
end;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DResize(Sender: TObject);
begin
 if (Assigned(GameDevice)) then
  begin
   DisplaySize:= Point2px(ClientWidth, ClientHeight);
   GameDevice.Resize(0, DisplaySize);
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceInit(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 DisplaySize:= Point2px(ClientWidth, ClientHeight);
 GameDevice.SwapChains.Add(NativeUInt(Self.Handle), DisplaySize);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreCreate(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 // Create all Asphyre components.
 GameDevice:= Factory.CreateDevice();

 GameCanvas:= Factory.CreateCanvas();
 GameImages:= TAsphyreImages.Create();

 RenderTargets:= TAsphyreRenderTargets.Create();

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
 // Disable the timer to prevent it from occuring.
 Timer.Enabled:= False;

 // Release all Asphyre components.
 FreeAndNil(MediaFile);
 FreeAndNil(GameFonts);
 FreeAndNil(RenderTargets);
 FreeAndNil(GameImages);
 FreeAndNil(GameCanvas);
 FreeAndNil(GameDevice);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceCreate(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 GameImages.AddFromArchive('Corbel.image', MediaFile, '', False);
 fontCorbel:= GameFonts.Insert('media.asvf | Corbel.xml', 'Corbel.image');

 targetMotion:= RenderTargets.Add(2, 512, 512, apf_A2B10G10R10);
 targetBlur  := RenderTargets.Add(2, 512, 512, apf_A2B10G10R10);

 PBoolean(Param)^:=
  (PBoolean(Param)^)and
  (fontCorbel <> -1)and
  (targetMotion <> -1)and
  (targetBlur <> -1);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnTimer(Sender: TObject);
begin
 // Try to connect the FireMonkey interface to Asphyre.
 if (not MonkeyAsphyreConnect.Init(Context)) then Exit;

 // In case the device could not be initialized properly (in the frame before
 // this one), show the message and close the form.
 if (Assigned(GameDevice))and(GameDevice.IsAtFault()) then
  begin
   if (not FailureHandled) then HandleConnectFailure();
   FailureHandled:= True;
   Exit;
  end;

 // Initialize Asphyre device, if needed. If this initialization fails, the
 // failure will be handled in the next OnTimer event.
 if (not Assigned(GameDevice))or(not GameDevice.Connect()) then Exit;

 GameDevice.RenderTo(RenderMotion, 0, True,
  RenderTargets[targetMotion + (MotionNo xor 1)]);

 GameDevice.RenderTo(RenderBlur, 0, False,
  RenderTargets[targetBlur + (BlurNo xor 1)]);

 // If the above steps are finished, proceed to render the scene.
 GameDevice.Render(OnRender, $FF000040);

 Timer.Process();

 MotionNo:= MotionNo xor 1;
 BlurNo  := BlurNo xor 1;
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnRender(Sender: TObject);
var
 Texture: TAsphyreRenderTargetTexture;
 DrawAt: TPoint2;
begin
 Texture:= RenderTargets[targetBlur + BlurNo];
 if (Assigned(Texture)) then
  begin
   DrawAt.x:= (DisplaySize.x - Texture.Width) * 0.5;
   DrawAt.y:= (DisplaySize.y - Texture.Height) * 0.5;

   GameCanvas.UseTexture(Texture, TexFull4);
   GameCanvas.TexMap(pBounds4(DrawAt.x, DrawAt.y, Texture.Width,
    Texture.Height), clWhite4);
  end;

 // Display the information text.
 GameFonts[fontCorbel].TextOut(
  Point2(4.0, 4.0),
  'FPS: ' + IntToStr(Timer.FrameRate),
  cColor2($FFFFEC99, $FFF78900));
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderMotion(Sender: TObject);
var
 Theta, RibbonLength: Single;
begin
 Theta:= (GameTicks mod 200) * Pi / 100;
 RibbonLength:= (1.0 + Sin(GameTicks / 50.0)) * Pi * 2 / 3 + (Pi / 3);

 GameCanvas.FillRibbon(Point2(256, 256 - 32), Point2(32.0, 48.0),
  Point2(96.0, 64.0), Theta, Theta + RibbonLength, 64,
  $FF7E00FF, $FF75D3FF, $FFD1FF75, $FFFFC042, $FF00FF00, $FFFF0000);
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderBlur(Sender: TObject);
const
 OrigPx: TPoint4 = (
  (x:   0 + 4; y: 0 + 4),
  (x: 512 - 1; y: 0 + 3),
  (x: 512 - 3; y: 512 - 1),
  (x:   0 + 1; y: 512 - 4));
begin
 // Copy previous scene, englarged and slightly rotated.
 GameCanvas.UseTexturePx(RenderTargets[targetBlur + BlurNo], OrigPx);
 GameCanvas.TexMap(pBounds4(0.0, 0.0, 512.0, 512.0), clWhite4);

 // Darken the area slightly, to avoid color mess :)
 // Replace color parameter to $FFF0F0F0 to reduce the effect.
 GameCanvas.FillRect(0, 0, 512, 512, $FFFCFCFC, beMultiply);

 // Add the "motion scene" on our working surface.
 GameCanvas.UseTexture(RenderTargets[targetMotion + MotionNo], TexFull4);
 GameCanvas.TexMap(pBounds4(0.0, 0.0, 512.0, 512.0), cAlpha4f(0.875));
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
procedure TMainForm.SecTimerTimer(Sender: TObject);
begin
 Timer.NotifyIdle();
end;

//---------------------------------------------------------------------------
end.
