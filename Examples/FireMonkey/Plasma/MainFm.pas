unit MainFm;
//---------------------------------------------------------------------------
// Plasma rendering example.
// Shows how to use Asphyre dynamic textures in FireMonkey.
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
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Forms3D, Asphyre.Types, Asphyre.Surfaces;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm3D)
    MonkeyTimer: TTimer;
    procedure Form3DCreate(Sender: TObject);
    procedure Form3DDestroy(Sender: TObject);
    procedure MonkeyTimerTimer(Sender: TObject);
    procedure Form3DResize(Sender: TObject);
  private
    { Private declarations }
    Surface: TSystemSurface;

    SinTab, CosTab: array[0..1023] of Word;
    PaletteTab: array[0..1023] of LongWord;
    iShift, jShift: Integer;
    PalIndex: Integer;

    procedure InitPlasma();
    procedure InitPalette();

    function CreateDraftImage(): Integer;

    procedure UploadConversion(Bits: Pointer; Pitch: Integer;
     Format: TAsphyrePixelFormat);
    procedure UploadNative(Bits: Pointer; Pitch: Integer);
    procedure DoPlasma(iShift, jShift: Integer);

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
 Asphyre.Math, Asphyre.TypeDef, Asphyre.Events.Types, Asphyre.Events,
 Asphyre.FeedTimers, Asphyre.Archives, Asphyre.Monkey.Connectors,
 Asphyre.Providers, Asphyre.Images, Asphyre.Fonts, Asphyre.Palettes,
 Asphyre.Formats, Asphyre.Canvas, Asphyre.Textures, GameTypes;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DCreate(Sender: TObject);
begin
 ArchiveTypeAccess:= ataPackaged;

 EventAsphyreCreate.Subscribe(ClassName, OnAsphyreCreate);
 EventAsphyreDestroy.Subscribe(ClassName, OnAsphyreDestroy);
 EventDeviceInit.Subscribe(ClassName, OnDeviceInit);
 EventDeviceCreate.Subscribe(ClassName, OnDeviceCreate);
 EventTimerReset.Subscribe(ClassName, OnTimerReset);

 InitPlasma();
 InitPalette();

 Surface:= TSystemSurface.Create();
 Surface.SetSize(256, 256);

 Timer.OnTimer  := OnTimer;
 Timer.OnProcess:= OnProcess;
 Timer.Enabled  := True;
end;

//---------------------------------------------------------------------------
procedure TMainForm.Form3DDestroy(Sender: TObject);
begin
 EventProviders.Unsubscribe(ClassName);
 if (Assigned(GameDevice)) then GameDevice.Disconnect();

 MonkeyAsphyreConnect.Done();

 FreeAndNil(Surface);
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
procedure TMainForm.InitPlasma();
var
 i: Integer;
begin
 // Precalculate sine and cosine functions for performance reasons.
 for i:= 0 to 1023 do
  begin
   SinTab[i]:= (Trunc(Sin(2.0 * Pi * i / 1024.0) * 512) + 512) and $3FF;
   CosTab[i]:= (Trunc(Cos(2.0 * Pi * i / 1024.0) * 512) + 512) and $3FF;
  end;

 // Initialize displacements for plasma animation.
 iShift:= 0;
 jShift:= 0;
end;

//---------------------------------------------------------------------------
procedure TMainForm.InitPalette();
var
 Palette: TAsphyrePalette;
 i: Integer;
begin
 // Create a palette of different colors, then precalculate its values in
 // a fixed-size lookup table for performance reasons.
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
procedure TMainForm.OnAsphyreCreate(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 DisplaySize:= Point2px(ClientWidth, ClientHeight);

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
procedure TMainForm.OnDeviceCreate(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 GameImages.AddFromArchive('tranceform.image', MediaFile);

 fontTranceform:= GameFonts.Insert('media.asvf | tranceform.xml',
  'tranceform.image');

 imagePlasma  := CreateDraftImage();
 imageScanline:= GameImages.AddFromArchive('scanline.image', MediaFile);
end;

//---------------------------------------------------------------------------
procedure TMainForm.MonkeyTimerTimer(Sender: TObject);
begin
 // Application.OnIdle event does not work in FireMonkey applications.
 // The solution is this timer (MonkeyTimer of class TTimer) that has interval
 // set to 1. This timer will notify Asphyre's timer as if it was idle event.
 // This is merely a hack until Embarcadero's fix the issue with OnIdle event.
 Timer.NotifyIdle();
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnTimerReset(const Sender: TObject; const Param: Pointer;
 var Handled: Boolean);
begin
 // This event occurs when resources are loaded or other heavy operations are
 // made to notify timer that the delay was not part of the rendering stall.
 // If you don't do this, the timer may lag momentarily after loading.
 Timer.Reset();
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnTimer(Sender: TObject);
begin
 if (not MonkeyAsphyreConnect.Init(Context)) then Exit;
 if (not Assigned(GameDevice))or(not GameDevice.Connect()) then Exit;

 // Update the plasma's texture.
 DoPlasma(iShift, jShift);

 GameDevice.Render(OnRender, $FF000000);
 Timer.Process();
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnRender(Sender: TObject);
var
 j, i: NativeInt;
begin
 for j:= 0 to (ClientHeight div 256) do
  for i:= 0 to (ClientWidth div 256) do
   begin
    GameCanvas.UseImage(GameImages[imagePlasma], TexFull4);
    GameCanvas.TexMap(pBounds4(i * 256, j * 256, 256, 256),
     clWhite4);
   end;

 for j:= 0 to (ClientHeight div 64) do
  for i:= 0 to (ClientWidth div 64) do
   begin
    GameCanvas.UseImage(GameImages[imageScanline], TexFull4);
    GameCanvas.TexMap(pBounds4(i * 64, j * 64, 64, 64),
     clWhite4, beMultiply);
   end;

 GameFonts[fontTranceform].TextOut(
  Point2(4.0, 4.0),
  'fps: ' + IntToStr(Timer.FrameRate),
  cColor2($FFD1FF46, $FF3EB243));
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnProcess(Sender: TObject);
begin
 Inc(iShift);
 Dec(jShift);
 Inc(PalIndex);
end;

//---------------------------------------------------------------------------
procedure TMainForm.UploadConversion(Bits: Pointer; Pitch: Integer;
 Format: TAsphyrePixelFormat);
var
 i: Integer;
begin
 // This method copies a single scanline of pixel data applying conversion
 // between different pixel formats. This is necessary if the plasma's image
 // has pixel format different than A8R8G8B8.
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
 // This method simply copies the scanline data from system surface to the
 // image, assuming that the image's pixel format is A8R8G8B8.
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
 Image: TAsphyreImage;
 Texture: TAsphyreLockableTexture;
begin
 for j:= 0 to 255 do
  begin
   Pixel:= Surface.Scanline[j];

   // plasma shifts
   Xadd:= SinTab[((j shl 2) + iShift) and $3FF];
   Cadd:= CosTab[((j shl 2) + jShift) and $3FF];

   // render scanline
   for i:= 0 to 255 do
    begin
     Index:= (SinTab[((i shl 2) + Xadd) and $3FF] + Cadd +
      (PalIndex * 4)) and $3FF;
     if (Index > 511) then Index:= 1023 - Index;

     Pixel^:= PaletteTab[((Index div 4) + PalIndex) and $3FF];
     Inc(Pixel);
    end;
  end;

 Image:= GameImages[imagePlasma];
 if (not Assigned(Image))or(Image.TextureCount < 1) then Exit;

 Texture:= Image.Texture[0];
 if (not Assigned(Texture))or(Texture.Format = apf_Unknown) then Exit;

 Texture.Lock(Bounds(0, 0, 256, 256), Bits, Pitch);

 if (Assigned(Bits))and(Pitch > 0) then
  begin
   if (Texture.Format = apf_A8R8G8B8) then UploadNative(Bits, Pitch)
    else UploadConversion(Bits, Pitch, Texture.Format);

   Texture.Unlock();
  end;
end;

//---------------------------------------------------------------------------
end.
