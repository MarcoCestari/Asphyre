unit Asphyre.Bitmaps.PNG;
//---------------------------------------------------------------------------
// PNG image format connection for Asphyre.
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
 System.SysUtils, System.Classes, Vcl.Graphics, Asphyre.TypeDef, 
 Asphyre.Surfaces, Asphyre.Bitmaps;

//---------------------------------------------------------------------------
type
 TAsphyrePNGBitmap = class(TAsphyreCustomBitmap)
 private
  FCompressionLevel: Integer;
 public
  property CompressionLevel: Integer read FCompressionLevel
   write FCompressionLevel;

  function LoadFromStream(const Extension: StdString; Stream: TStream;
   Dest: TSystemSurface): Boolean; override;

  function SaveToStream(const Extension: StdString; Stream: TStream;
   Source: TSystemSurface): Boolean; override;

  constructor Create();
 end;

//---------------------------------------------------------------------------
var
 PNGBitmap: TAsphyrePNGBitmap = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Vcl.Imaging.PNGImage;

//---------------------------------------------------------------------------
constructor TAsphyrePNGBitmap.Create();
begin
 inherited;

 FDesc:= 'PNG';
 FCompressionLevel:= 7;
end;

//---------------------------------------------------------------------------
function TAsphyrePNGBitmap.LoadFromStream(const Extension: StdString;
 Stream: TStream; Dest: TSystemSurface): Boolean;
var
 Image: TPngImage;
 Bitmap: TBitmap;
 UnmaskAlpha: Boolean;
 i, ScanIndex: Integer;
 SrcPixel : Cardinal;
 SrcPtr   : Pointer;
 DestPixel: PLongWord;
 SrcAlpha : PByte;
begin
 Result:= True;

 Image:= TPngImage.Create();
 try
  Image.LoadFromStream(Stream);
 except
  Result:= False;
 end;

 if (Result) then
  begin
   Bitmap:= TBitmap.Create();

   Image.AssignTo(Bitmap);

   Bitmap.PixelFormat:= pf32bit;
   UnmaskAlpha:= True;

   if (Image.Header.ColorType = COLOR_RGBALPHA)or
    (Image.Header.ColorType = COLOR_GRAYSCALEALPHA) then
    begin
     UnmaskAlpha:= False;

     for ScanIndex:= 0 to Bitmap.Height - 1 do
      begin
       DestPixel:= Bitmap.ScanLine[ScanIndex];
       SrcAlpha := @Image.AlphaScanline[ScanIndex][0];

       SrcPtr  := Image.Scanline[ScanIndex];
       SrcPixel:= 0;

       for i:= 0 to Bitmap.Width - 1 do
        begin
         Move(SrcPtr^, SrcPixel, 3);

         DestPixel^:= SrcPixel or (LongWord(Byte(SrcAlpha^)) shl 24);

         Inc(PtrInt(SrcPtr), 3);
         Inc(DestPixel);
         Inc(SrcAlpha);
        end;
      end;
    end;

   Dest.SetSize(Bitmap.Width, Bitmap.Height);

   for i:= 0 to Bitmap.Height - 1 do
    Move(Bitmap.ScanLine[i]^, Dest.Scanline[i]^, Bitmap.Width * 4);

   if (UnmaskAlpha) then Dest.ResetAlpha();

   FreeAndNil(Bitmap);
  end;

 FreeAndNil(Image);
end;

//---------------------------------------------------------------------------
function TAsphyrePNGBitmap.SaveToStream(const Extension: StdString;
 Stream: TStream; Source: TSystemSurface): Boolean;
var
 Bitmap: TBitmap;
 Image : TPngImage;
 i, ScanIndex: Integer;
 SrcPixel : PLongWord;
 DestAlpha: PByte;
begin
 Result:= True;

 Bitmap:= TBitmap.Create();
 Bitmap.PixelFormat:= pf32bit;
 Bitmap.SetSize(Source.Width, Source.Height);

 for i:= 0 to Source.Height - 1 do
  Move(Source.ScanLine[i]^, Bitmap.Scanline[i]^, Source.Width * 4);

 if (not Source.HasAlphaChannel()) then Bitmap.PixelFormat:= pf24bit;

 Image:= TPngImage.Create();
 Image.Assign(Bitmap);

 if (Bitmap.PixelFormat = pf32bit) then
  begin
   Image.CreateAlpha();

   for ScanIndex:= 0 to Bitmap.Height - 1 do
    begin
     SrcPixel := Bitmap.ScanLine[ScanIndex];
     DestAlpha:= @Image.AlphaScanline[ScanIndex][0];

     for i:= 0 to Bitmap.Width - 1 do
      begin
       DestAlpha^:= SrcPixel^ shr 24;

       Inc(SrcPixel);
       Inc(DestAlpha);
      end;
    end;
  end;

 Image.CompressionLevel:= FCompressionLevel;

 try
  Image.SaveToStream(Stream);
 except
  Result:= False;
 end;

 FreeAndNil(Image);
 FreeAndNil(Bitmap);
end;

//---------------------------------------------------------------------------
initialization
 PNGBitmap:= TAsphyrePNGBitmap.Create();
 BitmapManager.RegisterExt('.png', PNGBitmap);

//---------------------------------------------------------------------------
finalization
 BitmapManager.UnregisterExt('.png');
 FreeAndNil(PNGBitmap);

//---------------------------------------------------------------------------
end.
