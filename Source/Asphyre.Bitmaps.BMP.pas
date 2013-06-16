unit Asphyre.Bitmaps.BMP;
//---------------------------------------------------------------------------
// Windows Bitmap image format connection for Asphyre.
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
{$ifndef fpc}
 System.SysUtils, System.Classes, Vcl.Graphics,
{$else}
 SysUtils, Classes, Graphics,
{$endif}
 Asphyre.TypeDef,
 Asphyre.Surfaces, Asphyre.Bitmaps;

//---------------------------------------------------------------------------
type
 TAsphyreBMPBitmap = class(TAsphyreCustomBitmap)
 public
  function LoadFromStream(const Extension: StdString; Stream: TStream;
   Dest: TSystemSurface): Boolean; override;

  function SaveToStream(const Extension: StdString; Stream: TStream;
   Source: TSystemSurface): Boolean; override;

  constructor Create();
 end;

//---------------------------------------------------------------------------
var
 BMPBitmap: TAsphyreBMPBitmap = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyreBMPBitmap.Create();
begin
 inherited;

 FDesc:= 'Windows Bitmap';
end;

//---------------------------------------------------------------------------
function TAsphyreBMPBitmap.LoadFromStream(const Extension: StdString;
 Stream: TStream; Dest: TSystemSurface): Boolean;
var
 Bitmap: TBitmap;
 UnmaskAlpha: Boolean;
 i: Integer;
begin
 Result:= True;
 Bitmap:= TBitmap.Create();

 try
  Bitmap.LoadFromStream(Stream);
 except
  Result:= False;
 end;

 if (Result) then
  begin
   UnmaskAlpha:= Bitmap.PixelFormat <> pf32bit;
   Bitmap.PixelFormat:= pf32bit;

   Dest.SetSize(Bitmap.Width, Bitmap.Height);

   for i:= 0 to Bitmap.Height - 1 do
    Move(Bitmap.ScanLine[i]^, Dest.Scanline[i]^, Bitmap.Width * 4);

   if (UnmaskAlpha) then Dest.ResetAlpha();
  end;

 FreeAndNil(Bitmap);
end;

//---------------------------------------------------------------------------
function TAsphyreBMPBitmap.SaveToStream(const Extension: StdString;
 Stream: TStream; Source: TSystemSurface): Boolean;
var
 Bitmap: TBitmap;
 i: Integer;
begin
 Result:= True;

 Bitmap:= TBitmap.Create();
 Bitmap.PixelFormat:= pf32bit;
 Bitmap.SetSize(Source.Width, Source.Height);

 for i:= 0 to Source.Height - 1 do
  Move(Source.ScanLine[i]^, Bitmap.Scanline[i]^, Source.Width * 4);

 try
  Bitmap.SaveToStream(Stream);
 except
  Result:= False;
 end;

 FreeAndNil(Bitmap);
end;

//---------------------------------------------------------------------------
initialization
 BMPBitmap:= TAsphyreBMPBitmap.Create();
 BitmapManager.RegisterExt('.bmp', BMPBitmap);

//---------------------------------------------------------------------------
finalization
 BitmapManager.UnregisterExt('.bmp');
 FreeAndNil(BMPBitmap);

//---------------------------------------------------------------------------
end.
