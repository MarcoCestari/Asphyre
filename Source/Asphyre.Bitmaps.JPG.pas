unit Asphyre.Bitmaps.JPG;
//---------------------------------------------------------------------------
// JPEG image format connection for Asphyre.
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
 TAsphyreJPGFlag  = (ajfProgressive, ajfGrayscale);
 TAsphyreJPGFlags = set of TAsphyreJPGFlag;

//---------------------------------------------------------------------------
 TAsphyreJPGBitmap = class(TAsphyreCustomBitmap)
 private
  FFlags: TAsphyreJPGFlags;
  FQuality: Integer;
 public
  // JPEG flags that determine how the file should be saved.
  property Flags: TAsphyreJPGFlags read FFlags write FFlags;

  // The quality of the saved JPEG file being 0 worst quality and 100 the best.
  property Quality: Integer read FQuality write FQuality;

  function LoadFromStream(const Extension: StdString; Stream: TStream;
   Dest: TSystemSurface): Boolean; override;

  function SaveToStream(const Extension: StdString; Stream: TStream;
   Source: TSystemSurface): Boolean; override;

  constructor Create();
 end;

//---------------------------------------------------------------------------
var
 JPGBitmap: TAsphyreJPGBitmap = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Vcl.Imaging.JPEG;

//---------------------------------------------------------------------------
constructor TAsphyreJPGBitmap.Create();
begin
 inherited;

 FDesc:= 'JPEG';

 FFlags:= [ajfProgressive];
 FQuality:= 75;
end;

//---------------------------------------------------------------------------
function TAsphyreJPGBitmap.LoadFromStream(const Extension: StdString;
 Stream: TStream; Dest: TSystemSurface): Boolean;
var
 Image : TJpegImage;
 Bitmap: TBitmap;
 UnmaskAlpha: Boolean;
 i: Integer;
begin
 Result:= True;
 Image:= TJpegImage.Create();

 try
  Image.LoadFromStream(Stream);
 except
  Result:= False;
 end;

 if (Result) then
  begin
   Bitmap:= TBitmap.Create();
   Bitmap.Assign(Image);

   UnmaskAlpha:= Bitmap.PixelFormat <> pf32bit;
   Bitmap.PixelFormat:= pf32bit;

   Dest.SetSize(Bitmap.Width, Bitmap.Height);

   for i:= 0 to Bitmap.Height - 1 do
    Move(Bitmap.ScanLine[i]^, Dest.Scanline[i]^, Bitmap.Width * 4);

   if (UnmaskAlpha) then Dest.ResetAlpha();

   FreeAndNil(Bitmap);
  end;

 FreeAndNil(Image);
end;

//---------------------------------------------------------------------------
function TAsphyreJPGBitmap.SaveToStream(const Extension: StdString;
 Stream: TStream; Source: TSystemSurface): Boolean;
var
 Image: TJpegImage;
 Bitmap: TBitmap;
 i: Integer;
begin
 Result:= True;

 Bitmap:= TBitmap.Create();
 Bitmap.PixelFormat:= pf32bit;
 Bitmap.SetSize(Source.Width, Source.Height);

 for i:= 0 to Source.Height - 1 do
  Move(Source.ScanLine[i]^, Bitmap.Scanline[i]^, Source.Width * 4);

 Image:= TJpegImage.Create();
 Image.Assign(Bitmap);

 Image.ProgressiveEncoding:= ajfProgressive in Flags;
 Image.Grayscale:= ajfGrayscale in Flags;

 Image.CompressionQuality:= Quality;

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
 JPGBitmap:= TAsphyreJPGBitmap.Create();
 BitmapManager.RegisterExt('.jpg', JPGBitmap);
 BitmapManager.RegisterExt('.jpeg', JPGBitmap);

//---------------------------------------------------------------------------
finalization
 BitmapManager.UnregisterExt('.jpeg');
 BitmapManager.UnregisterExt('.jpg');
 FreeAndNil(JPGBitmap);

//---------------------------------------------------------------------------
end.
