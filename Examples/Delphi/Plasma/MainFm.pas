unit MainFm;
//---------------------------------------------------------------------------
// Plasma rendering example.
// Shows how to use dynamic textures.
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
// In this example the comments have been stripped to make the code more
// compact looking. Most of the initialization and other tasks is similar to
// other examples that have their source code commented.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Asphyre.Types, Asphyre.Surfaces;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    FailureHandled: Boolean;
    Surface: TSystemSurface;

    SinTab, CosTab: array[0..1023] of Word;
    PaletteTab: array[0..1023] of LongWord;
    iShift, jShift: Integer;
    PalIndex: Integer;

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

    procedure InitPlasma();
    procedure InitPalette();

    function CreateDraftImage(): Integer;
    procedure UploadNative(Bits: Pointer; Pitch: Integer);
    procedure UploadConversion(Bits: Pointer; Pitch: Integer;
     Format: TAsphyrePixelFormat);

    procedure TimerEvent(Sender: TObject);
    procedure ProcessEvent(Sender: TObject);
    procedure RenderEvent(Sender: TObject);

    procedure DoPlasma(iShift, jShift: Integer);
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
 Asphyre.TypeDef, Asphyre.Math, Asphyre.Events.Types, Asphyre.Events,
 Asphyre.FormTimers, Asphyre.Providers, Asphyre.Archives, Asphyre.Devices,
 Asphyre.Canvas, Asphyre.Images, Asphyre.Fonts, Asphyre.Palettes,
 Asphyre.Formats, Asphyre.Native.Connectors, Asphyre.Providers.DX9, GameTypes;
{$R *.dfm}

//---------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
 ReportMemoryLeaksOnShutdown:= DebugHook <> 0;

 Factory.UseProvider(idDirectX9);

 EventAsphyreCreate.Subscribe(ClassName, OnAsphyreCreate);
 EventAsphyreDestroy.Subscribe(ClassName, OnAsphyreDestroy);
 EventDeviceInit.Subscribe(ClassName, OnDeviceInit);
 EventDeviceCreate.Subscribe(ClassName, OnDeviceCreate);
 EventTimerReset.Subscribe(ClassName, OnTimerReset);

 Timer.OnTimer  := TimerEvent;
 Timer.OnProcess:= ProcessEvent;
 Timer.Enabled  := True;

 ArchiveTypeAccess:= ataPackaged;

 FailureHandled:= False;

 InitPlasma();
 InitPalette();
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormDestroy(Sender: TObject);
begin
 if (Assigned(GameDevice)) then GameDevice.Disconnect();
 NativeAsphyreConnect.Done();
 EventProviders.Unsubscribe(ClassName);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreCreate(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 GameDevice:= Factory.CreateDevice();
 GameCanvas:= Factory.CreateCanvas();
 GameImages:= TAsphyreImages.Create();

 GameFonts:= TAsphyreFonts.Create();
 GameFonts.Images:= GameImages;
 GameFonts.Canvas:= GameCanvas;

 MediaFile:= TAsphyreArchive.Create();
 MediaFile.OpenMode:= aomReadOnly;
 MediaFile.FileName:= 'media.asvf';

 Surface:= TSystemSurface.Create();
 Surface.SetSize(256, 256);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnAsphyreDestroy(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 Timer.Enabled:= False;

 FreeAndNil(Surface);

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
procedure TMainForm.InitPlasma();
var
 i: Integer;
begin
 for i:= 0 to 1023 do
  begin
   SinTab[i]:= (Trunc(Sin(2.0 * Pi * i / 1024.0) * 512) + 512) and $3FF;
   CosTab[i]:= (Trunc(Cos(2.0 * Pi * i / 1024.0) * 512) + 512) and $3FF;
  end;

 iShift:= 0;
 jShift:= 0;
end;

//---------------------------------------------------------------------------
procedure TMainForm.InitPalette();
var
 Palette: TAsphyrePalette;
 i: Integer;
begin
 Palette:= TAsphyrePalette.Create();
 Palette.Add($FF000000, ntSine, 0.0);
 Palette.Add($FF7E00FF, ntSine, 0.1);
 Palette.Add($FFE87AFF, ntSine, 0.2);
 Palette.Add($FF7E00FF, ntSine, 0.3);
 Palette.Add($FFFFFFFF, ntSine, 0.4);

 Palette.Add($FF000000, ntPlain, 0.5);
 Palette.Add($FF0500A8, ntBrake, 0.6);
 Palette.Add($FFBEFF39, ntAccel, 0.7);
 Palette.Add($FFFFC939, ntBrake, 0.8);
 Palette.Add($FFFFF58D, ntSine,  0.9);
 Palette.Add($FF000000, ntPlain, 1.0);

 for i:= 0 to 1023 do
  PaletteTab[i]:= Palette.Color[i / 1023.0];

 FreeAndNil(Palette);
end;

//---------------------------------------------------------------------------
function TMainForm.CreateDraftImage(): Integer;
var
 Image: TAsphyreImage;
begin
 Image:= TAsphyreImage.Create();
 Image.MipMapping  := False;
 Image.PixelFormat := apf_A8R8G8B8;
 Image.DynamicImage:= True;

 if (not Assigned(Image.InsertTexture(256, 256))) then
  begin
   Result:= -1;
   Exit;
  end;

 Result:= GameImages.Include(Image); 
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnDeviceCreate(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 GameImages.AddFromArchive('tranceform.image', MediaFile);
 fontTranceform:= GameFonts.Insert('media.asvf | tranceform.xml',
  'tranceform.image');

 imagePlasma  := CreateDraftImage();
 imageScanline:= GameImages.AddFromArchive('scanline.image', MediaFile);

 PBoolean(Param)^:=
  (PBoolean(Param)^)and
  (imageScanline <> -1)and
  (fontTranceform <> -1);
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
procedure TMainForm.TimerEvent(Sender: TObject);
begin
 if (not NativeAsphyreConnect.Init()) then Exit;

 if (Assigned(GameDevice))and(GameDevice.IsAtFault()) then
  begin
   if (not FailureHandled) then HandleConnectFailure();
   FailureHandled:= True;
   Exit;
  end;

 if (not Assigned(GameDevice))or(not GameDevice.Connect()) then Exit;

 DoPlasma(iShift, jShift);

 GameDevice.Render(RenderEvent, $000000);
 Timer.Process();
end;

//---------------------------------------------------------------------------
procedure TMainForm.ProcessEvent(Sender: TObject);
begin
 Inc(iShift);
 Dec(jShift);
 Inc(PalIndex);
end;

//---------------------------------------------------------------------------
procedure TMainForm.RenderEvent(Sender: TObject);
var
 j, i: Integer;
begin
 for j:= 0 to ClientHeight div 256 do
  for i:= 0 to ClientWidth div 256 do
   begin
    GameCanvas.UseImage(GameImages[imagePlasma], TexFull4);
    GameCanvas.TexMap(pBounds4(i * 256, j * 256, 256, 256),
     clWhite4);
   end;

 for j:= 0 to ClientHeight div 64 do
  for i:= 0 to ClientWidth div 64 do
   begin
    GameCanvas.UseImage(GameImages[imageScanline], TexFull4);
    GameCanvas.TexMap(pBounds4(i * 64, j * 64, 64, 64),
     clWhite4, beMultiply);
   end;

 GameFonts[fontTranceform].TextOut(
  Point2(4.0, 4.0),
  'fps: ' + IntToStr(Timer.FrameRate),
  cColor2($FFD1FF46, $FF3EB243), 1.0);
end;

//---------------------------------------------------------------------------
procedure TMainForm.UploadConversion(Bits: Pointer; Pitch: Integer;
 Format: TAsphyrePixelFormat);
var
 i: Integer;
begin
 for i:= 0 to Surface.Height - 1 do
  begin
   Pixel32toXArray(Surface.Scanline[i], Bits, Format, Surface.Width);
   Inc(PtrInt(Bits), Pitch);
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.UploadNative(Bits: Pointer; Pitch: Integer);
var
 i: Integer;
begin
 for i:= 0 to Surface.Height - 1 do
  begin
   Move(Surface.Scanline[i]^, Bits^, Surface.Width * 4);
   Inc(PtrInt(Bits), Pitch);
  end;
end;

//---------------------------------------------------------------------------
procedure TMainForm.DoPlasma(iShift, jShift: Integer);
var
 i, j, Xadd, Cadd: Integer;
 Pixel: PLongWord;
 Index: Integer;
 Bits : Pointer;
 Pitch: Integer;
begin
 for j:= 0 to 255 do
  begin
   Pixel:= Surface.Scanline[j];

   Xadd:= SinTab[((j shl 2) + iShift) and $3FF];
   Cadd:= CosTab[((j shl 2) + jShift) and $3FF];

   for i:= 0 to 255 do
    begin
     Index:= (SinTab[((i shl 2) + Xadd) and $3FF] + Cadd +
      (PalIndex * 4)) and $3FF;
     if (Index > 511) then Index:= 1023 - Index;

     Pixel^:= PaletteTab[((Index div 4) + PalIndex) and $3FF];
     Inc(Pixel);
    end;
  end;

 with GameImages[imagePlasma].Texture[0] do
  begin
   Lock(Bounds(0, 0, 256, 256), Bits, Pitch);

   if (Bits <> nil)and(Pitch > 0) then
    begin
     if (Format = apf_A8R8G8B8) then UploadNative(Bits, Pitch)
      else UploadConversion(Bits, Pitch, Format);

     Unlock();
    end;
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
