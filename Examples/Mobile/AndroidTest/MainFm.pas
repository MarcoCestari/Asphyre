unit MainFm;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Types3D, FMX.Controls, FMX.Forms3D;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm3D)
    SysTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure OnSysTimer(Sender: TObject);
    procedure FormRender(Sender: TObject; Context: TContext3D);
  private
    { Private declarations }
    function GetDeviceScale(): Single;

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
 FMX.Platform, FMX.Forms, FMX.Dialogs, Asphyre.Math, Asphyre.Types, Asphyre.Events.Types,
 Asphyre.Events, Asphyre.FeedTimers, Asphyre.Archives, Asphyre.Providers,
 Asphyre.Images, Asphyre.Fonts, Asphyre.Monkey.Connectors, Asphyre.Devices,
 GameTypes, IOUtils, Asphyre.Providers.GLES;

//---------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
 EventAsphyreCreate.Subscribe(ClassName, OnAsphyreCreate);
 EventAsphyreDestroy.Subscribe(ClassName, OnAsphyreDestroy);
 EventDeviceInit.Subscribe(ClassName, OnDeviceInit);
 EventDeviceCreate.Subscribe(ClassName, OnDeviceCreate);
 EventTimerReset.Subscribe(ClassName, OnTimerReset);

 Timer.MaxFPS   := 4000;
 Timer.OnTimer  := OnTimer;
 Timer.OnProcess:= OnProcess;
 Timer.Enabled  := True;

 ArchiveTypeAccess:= ataPackaged;
 ArchiveHInstance := hInstance;
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormDestroy(Sender: TObject);
begin
 // Remove the subscription to the events.
 EventProviders.Unsubscribe(ClassName);

 // Disconnect Asphyre device from FireMonkey.
 if (Assigned(GameDevice)) then GameDevice.Disconnect();

 // Finish the Asphyre connection manager.
 MonkeyAsphyreConnect.Done();
end;

//---------------------------------------------------------------------------
function TMainForm.GetDeviceScale(): Single;
var
 WinSvc: IFMXWindowService;
begin
 if (TPlatformServices.Current.SupportsPlatformService(IFMXWindowService,
  IInterface(WinSvc))) then
  Result:= WinSvc.GetWindowScale(Self)
   else Result:= 1.0;
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormResize(Sender: TObject);
begin
 DisplaySize:= Point2px(ClientWidth, ClientHeight);

 if (Assigned(GameDevice)) then
  GameDevice.Resize(0, DisplaySize);
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormRender(Sender: TObject; Context: TContext3D);
begin
 Timer.NotifyIdle();
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreCreate(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 //Factory.UseProvider(idOpenGL_ES);
 // Create all Asphyre components.
 GameDevice:= Factory.CreateDevice();
 GameDevice.DeviceScale:= GetDeviceScale();

 GameCanvas:= Factory.CreateCanvas();
 GameImages:= TAsphyreImages.Create();

 GameFonts:= TAsphyreFonts.Create();
 GameFonts.Images:= GameImages;
 GameFonts.Canvas:= GameCanvas;

 //ArchiveTypeAccess := ataResource;

 //ShowMessage(GetHomePath + PathDelim + 'media.asvf');
 //ShowMessage(TPath.Combine(TPath.GetDocumentsPath,'media.asvf'));

 MediaFile:= TAsphyreArchive.Create();
 MediaFile.OpenMode:= aomReadOnly;
 //if FileExists(GetHomePath + PathDelim + 'media.asvf') then
 //begin
 // ShowMessage('1');
 // MediaFile.FileName := GetHomePath + PathDelim + 'media.asvf';
 //end
 {else} if FileExists(TPath.Combine(TPath.GetDocumentsPath,'media.asvf')) then
 begin
  ShowMessage('2');
  MediaFile.FileName:= TPath.Combine(TPath.GetDocumentsPath,'media.asvf');
 end
 else if FileExists('media.asvf') then
 begin
  ShowMessage('3');
  MediaFile.FileName := 'media.asvf';
 end;
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
 DisplaySize:= Point2px(ClientWidth, ClientHeight);
 GameDevice.SwapChains.Add(NativeUInt(Self.Handle), DisplaySize);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceCreate(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
//var
// x: NativeInt;
begin
 {if TFile.Exists(TPath.Combine(TPath.GetDocumentsPath,'Tahoma18b.png')) then
  ShowMessage('tahoma');

 //GameImages.AddFromArchive('tahoma18b.image', MediaFile, '', False);
 x := GameImages.AddFromFileEx(TPath.Combine(TPath.GetDocumentsPath,'Tahoma18b.png'),'tahoma18b.image');
 ShowMessage(IntToStr(x));

 fontTahoma:= GameFonts.Insert('media.asvf | tahoma18b.xml', 'tahoma18b.image');

 //imageLena:= GameImages.AddFromArchive('lena.image', MediaFile);
 imageLena:= GameImages.AddFromFileEx(TPath.Combine(TPath.GetDocumentsPath,'lena.png'),'lena.image');

 ShowMessage(IntToStr(fontTahoma));
 ShowMessage(IntToStr(imageLena)); }

 PBoolean(Param)^:= True;
 { (PBoolean(Param)^)and
  (imageLena <> -1)and
  (fontTahoma <> -1);}
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnTimer(Sender: TObject);
begin
 //ShowMessage('OnTimer');
 if (not MonkeyAsphyreConnect.Init(Context)) then Exit;
 //ShowMessage('OnTimer 2');
 if (not Assigned(GameDevice))or(not GameDevice.Connect()) then Exit;
 //ShowMessage('OnTimer 3');
 GameDevice.Render(OnRender, $FF000000);

 Timer.Process();
 //ShowMessage('OnTimer Done');
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnRender(Sender: TObject);
const
 DivisionSize = 40;
var
 j, i: NativeInt;
 Omega, Kappa: Single;
begin
 //ShowMessage('OnRender');

 // Let the canvas our own scale units and the actual scale of device.
 GameCanvas.ExternalScale:= 1.0;
 GameCanvas.DeviceScale:= GameDevice.DeviceScale;

 // Draw gray background.
 for j:= 0 to DisplaySize.y div DivisionSize do
  for i:= 0 to DisplaySize.x div DivisionSize do
   GameCanvas.FillQuad(
    pBounds4(i * DivisionSize, j * DivisionSize, DivisionSize, DivisionSize),
    cColor4($FF585858, $FF505050, $FF484848, $FF404040));

 for i:= 0 to DisplaySize.x div DivisionSize do
  GameCanvas.Line(
   Point2(i * DivisionSize, 0.0),
   Point2(i * DivisionSize, DisplaySize.y),
   $FF505050);

 for j:= 0 to DisplaySize.y div DivisionSize do
  GameCanvas.Line(
   Point2(0.0, j * DivisionSize),
   Point2(DisplaySize.x, j * DivisionSize),
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
 {GameCanvas.UseImagePx(GameImages[imageLena], pBounds4(0, 0, 512, 512));
 GameCanvas.TexMap(pRotate4c(
  Point2(DisplaySize.x * 0.5, DisplaySize.y * 0.5),
  Point2(300.0, 300.0),
  GameTicks * 0.01),
  cAlpha4(128));}

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

 { The font Tahoma 18 has been rendered to work on Retina display, resulting
   in visible image as if it was Tahoma 9.

   Since our local units have scale of 1.0, the font is actually twice as big,
   so we need to set its scale to 0.5 to compensate.

   The result is that on Retina display, it will be rendered twice of its size,
   so 0.5 x 2.0 = 1.0, while on non-Retina display it will appear half of its size. }
 {GameFonts[fontTahoma].Scale:= 0.5;

 GameFonts[fontTahoma].TextOut(
  Point2(4.0, 4.0),
  'FPS: ' + IntToStr(Timer.FrameRate),
  cColor2($FFFFE887, $FFFF0000));

 GameFonts[fontTahoma].TextOut(
  Point2(4.0, 24.0),
  'Technology: ' + GetFullDeviceTechString(GameDevice),
  cColor2($FFE8FFAA, $FF12C312));}
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
procedure TMainForm.OnSysTimer(Sender: TObject);
begin
{$ifdef MsWindows}
 Timer.NotifyIdle();
{$else}
 Invalidate();
{$endif}
end;

//---------------------------------------------------------------------------
end.
