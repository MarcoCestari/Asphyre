unit Asphyre.Pixels.Utils;
//---------------------------------------------------------------------------
// Utility routines for processing images and pixels.
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
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.Math, Asphyre.TypeDef, Asphyre.Math, Asphyre.Surfaces;

//---------------------------------------------------------------------------
// FindAlphaChannel()
//
// Given the two images with different background values this method extracts
// the resulting image that has alpha channel in it.
//---------------------------------------------------------------------------
procedure FindAlphaChannel(Dest, Image1, Image2: TSystemSurface;
 Bk1, Bk2: Cardinal);

//---------------------------------------------------------------------------
// LineConvMasked()
//
// Processes one scanline comparing colors to the mask. The closer matches
// become more transparent (lower alpha).
//---------------------------------------------------------------------------
procedure LineConvMasked(Source, Dest: Pointer; Count, Tolerance: Integer;
 ColorMask: Cardinal);

//---------------------------------------------------------------------------
// BestTexSize()
//
// Attempts to find the best texture size to match the specified pattern
// amount and dimensions. The heuristics try to optimize for performance
// first, then minimize waste and finally, gives preference to textures
// with less anisotropy (likes square textures).
//---------------------------------------------------------------------------
procedure BestTexSize(const PatternSize: TPoint2px; PatternCount: Integer;
 out TextureSize: TPoint2px);

//---------------------------------------------------------------------------
// TileBitmap()
//
// Accomodates the source image with multiple patterns on destination texture
// using the optimal configuration.
//---------------------------------------------------------------------------
procedure TileBitmap(Dest, Source: TSystemSurface; const TexSize, InPSize,
 OutPSize: TPoint2px; NeedMask: Boolean; MaskColor: Cardinal;
 Tolerance: Integer);

 //---------------------------------------------------------------------------
// RenderLineAlpha()
//
// Renders source scanline with alpha-channel onto destination address.
// The source alpha-channel is multiplied by the specified Alpha coefficient.
//   Alpha can be [0..255]
//---------------------------------------------------------------------------
procedure RenderLineAlpha(Source, Dest: Pointer; Count, Alpha: Integer);

//---------------------------------------------------------------------------
// RenderLineAlphaAdd()
//
// Renders source scanline  onto destination address.
// The source is multiplied bu its alpha-channel and Alpha coefficient.
//   Alpha can be [0..255]
//---------------------------------------------------------------------------
procedure RenderLineAlphaAdd(Source, Dest: Pointer; Count, Alpha: Integer);

//---------------------------------------------------------------------------
// RenderLineDiffuse()
//
// Similar in effect to RenderLineAlpha() except that source pixels are also
// multiplied by the specified color.
//---------------------------------------------------------------------------
procedure RenderLineDiffuse(Source, Dest: Pointer; Count: Integer;
 Diffuse: Cardinal);

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types, Asphyre.Colors;

//---------------------------------------------------------------------------
function Linear2Sine(Alpha: Single): Single;
const
 PiHalf = Pi / 2.0;
begin
 Result:= (Sin((Alpha * Pi) - PiHalf) + 1.0) / 2.0;
end;

//---------------------------------------------------------------------------
procedure FindAlphaChannel(Dest, Image1, Image2: TSystemSurface; Bk1,
 Bk2: Cardinal);
var
 Index   : Integer;
 ScanIndx: Integer;

 BackValue1: Single;
 BackValue2: Single;

 Pixel1: Single;
 Pixel2: Single;

 Pixel: Single;
 Alpha: Single;

 Read0: PLongWord;
 Read1: PLongWord;
 Write: PLongWord;

 Color: Cardinal;
begin
 BackValue1:= PixelToGrayEx(Bk1);
 BackValue2:= PixelToGrayEx(Bk2);

 Dest.SetSize(Image1.Width, Image1.Height);

 for ScanIndx:= 0 to Dest.Height - 1 do
  begin
   Read0:= Image1.Scanline[ScanIndx];
   Read1:= Image2.Scanline[ScanIndx];
   Write:= Dest.Scanline[ScanIndx];

   for Index:= 0 to Dest.Width - 1 do
    begin
     // retrieve source grayscale pixels
     Pixel1:= PixelToGrayEx(Read0^);
     Pixel2:= PixelToGrayEx(Read1^);

     // calculate alpha-value and original pixel
     ExtractAlpha(Pixel1, Pixel2, BackValue1, BackValue2, Alpha, Pixel);

     // convert normalized pixel to color index
     Color:= Round(Pixel * 255.0);
     // prepare a 24-bit RGB color
     Color:= Color or (Color shl 8) or (Color shl 16);
     // add alpha-channel to 24-bit RGB color and write it to destination
     Write^:= Color or (Round(Alpha * 255.0) shl 24);

     // move through pixels
     Inc(Read0);
     Inc(Read1);
     Inc(Write);
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure LineConvMasked(Source, Dest: Pointer; Count, Tolerance: Integer;
 ColorMask: Cardinal);
const
 Delta2Dist = 57.73502692;
 DeltaMin = 0.025;
var
 InPx, OutPx: PLongWord;
 Color, cMask: TAsphyreColor;
 i: Integer;
 Delta, DeltaMax: Single;
begin
 InPx:= Source;
 OutPx:= Dest;
 cMask:= DisplaceRB(ColorMask);

 DeltaMax:= (Abs(Tolerance) / Delta2Dist) + DeltaMin;

 for i:= 0 to Count - 1 do
  begin
   // retrieve real color
   Color:= DisplaceRB(InPx^);

   // calculate the difference (in %)
   Delta:= Sqrt(Sqr(Color.r - cMask.r) + Sqr(Color.g - cMask.g) +
    Sqr(Color.b - cMask.b));

   // based on distance, find the specified alpha-channel
   Color.a:= 1.0;
   if (Delta <= DeltaMax) then
    Color.a:= Linear2Sine(Delta / DeltaMax);

   // write final pixel
   OutPx^:= DisplaceRB(Color);

   // advance in pixel list
   Inc(InPx);
   Inc(OutPx);
  end;
end;

//---------------------------------------------------------------------------
function WastedSpace(const PatternSize, TextureSize: TPoint2px;
 PatternCount: Integer; out TextureCount: Integer): Integer;
var
 UsedWidth        : Integer;
 UsedHeight       : Integer;
 AvailablePatterns: Integer;
 PatternsInTexture: Integer;
 Wasted           : Integer;
 WastedWidth      : Integer;
 WastedHeight     : Integer;
 WastedCorner     : Integer;
 WastedPatterns   : Integer;
begin
 UsedWidth := (TextureSize.x div PatternSize.x) * PatternSize.x;
 UsedHeight:= (TextureSize.y div PatternSize.y) * PatternSize.y;

 // how many patterns fit in one texture?
 PatternsInTexture:= ((TextureSize.x div PatternSize.x) *
  (TextureSize.y div PatternSize.y));

 // how many textures are needed to hold all patterns
 if (PatternsInTexture > 0) then
  TextureCount:= Ceil(PatternCount / PatternsInTexture)
   else TextureCount:= 0;

 // patterns in these textures
 AvailablePatterns:= TextureCount * PatternsInTexture;

 WastedWidth := (TextureSize.x - UsedWidth) * TextureSize.y;
 WastedHeight:= (TextureSize.y - UsedHeight) * TextureSize.x;
 WastedCorner:= (TextureSize.x - UsedWidth) * (TextureSize.y - UsedHeight);

 WastedPatterns:= (AvailablePatterns - PatternCount) * PatternSize.x *
  PatternSize.y;

 // space wasted in ONE texture
 Wasted:= WastedWidth + WastedHeight - WastedCorner;

 // space wasted in ALL textures and missing patterns
 Result:= (Wasted * TextureCount) + WastedPatterns;
end;

//---------------------------------------------------------------------------
procedure BestTexSize(const PatternSize: TPoint2px; PatternCount: Integer;
 out TextureSize: TPoint2px);
const
 MaxSize: TPoint2px = (x: 512; y: 512);
var
 MinSize: TPoint2px;
 Wasted : Integer;
 Attempt: TPoint2px;

 TexCount: Integer;
 NewCount: Integer;
 NewWaste: Integer;
 Delta   : Integer;
 NewDelta: Integer;
begin
 // (1) Minimal texture size.
 MinSize:= PatternSize;
 if (not IsPowerOfTwo(MinSize.x)) then
  MinSize.x:= CeilPowerOfTwo(PatternSize.x);

 if (not IsPowerOfTwo(MinSize.y)) then
  MinSize.y:= CeilPowerOfTwo(PatternSize.y);

 // (2) If it's not within limits -> just use the minimal size.
 if (MinSize.x > MaxSize.x)or(MinSize.y > MaxSize.y) then
  begin
   TextureSize:= MinSize;
   Exit;
  end;

 // (3) Assume we are using maximum texture size.
 Wasted:= WastedSpace(PatternSize, MaxSize, PatternCount, TexCount);
 TextureSize:= MaxSize;
 Delta:= Abs(MaxSize.x - MaxSize.y);

 Attempt.x:= MaxSize.x;
 while (Attempt.x >= MinSize.x) do
  begin
   Attempt.y:= MaxSize.y;
   while (Attempt.y >= MinSize.y) do
    begin
     NewWaste:= WastedSpace(PatternSize, Attempt, PatternCount, NewCount);
     NewDelta:= Abs(Attempt.y - Attempt.x);
     if (NewCount < TexCount)or((NewCount = TexCount)and(NewWaste < Wasted))or
      ((NewCount = TexCount)and(NewWaste = Wasted)and(NewDelta < Delta)) then
      begin
       TextureSize:= Attempt;
       Wasted  := NewWaste;
       TexCount:= NewCount;
       Delta   := NewDelta;
      end;

     Attempt.y:= Attempt.y div 2;
    end;

   Attempt.x:= Attempt.x div 2;
  end;
end;

//---------------------------------------------------------------------------
procedure TileBitmap(Dest, Source: TSystemSurface; const TexSize, InPSize,
 OutPSize: TPoint2px; NeedMask: Boolean; MaskColor: Cardinal;
 Tolerance: Integer);
var
 SrcInRow: Integer;
 SrcInCol: Integer;
 SrcCount: Integer;
 DstInRow: Integer;
 DstInCol: Integer;
 ImgInTex: Integer;
 TexCount: Integer;
 AuxMem  : Pointer;
 AuxPitch: Integer;
 SrcIndex: Integer;
 TexIndex: Integer;
 PatIndex: Integer;
 DestPt  : TPoint2px;
 SrcPt   : TPoint2px;
 Index   : Integer;
 MemAddr : Pointer;
 DestIndx: Integer;
begin
 // (1) Determine source attributes.
 SrcInRow:= Source.Width div InPSize.x;
 SrcInCol:= Source.Height div InPSize.y;
 SrcCount:= SrcInRow * SrcInCol;

 // (2) Determine destination attributes.
 DstInRow:= TexSize.x div OutPSize.x;
 DstInCol:= TexSize.y div OutPSize.y;
 ImgInTex:= DstInRow * DstInCol;
 TexCount:= Ceil(SrcCount / ImgInTex);

 // (3) Allocate auxiliary memory.
 AuxPitch:= InPSize.x * 4;
 AuxMem  := AllocMem(AuxPitch);

 Dest.SetSize(TexSize.x, TexSize.y * TexCount);
 Dest.Clear(0);

 // (4) Place individual patterns.
 SrcIndex:= 0;
 for TexIndex:= 0 to TexCount - 1 do
  for PatIndex:= 0 to ImgInTex - 1 do
   begin
    DestPt.x:= (PatIndex mod DstInRow) * OutPSize.x;
    DestPt.y:= ((PatIndex div DstInRow) mod DstInCol) * OutPSize.y;
    SrcPt.x := (SrcIndex mod SrcInRow) * InPSize.x;
    SrcPt.y := ((SrcIndex div SrcInRow) mod SrcInCol) * InPSize.y;

    // render scanlines
    for Index:= 0 to InPSize.y - 1 do
     begin
      // prepare source pointer
      MemAddr:= Pointer(NativeInt(Source.Scanline[(Index + SrcPt.y)]) +
       (SrcPt.x * 4));

      if (NeedMask) then
       begin
        LineConvMasked(MemAddr, AuxMem, InPSize.x, Tolerance,
         DisplaceRB(MaskColor));
       end else Move(MemAddr^, AuxMem^, InPSize.x * 4);

      DestIndx:= DestPt.y + (TexSize.y * TexIndex) + Index;
      MemAddr:= Pointer(NativeInt(Dest.Scanline[DestIndx]) + (DestPt.x * 4));
      Move(AuxMem^, MemAddr^, AuxPitch);
     end;

    Inc(SrcIndex);
    if (SrcIndex >= SrcCount) then Break;
   end;

 // (5) Release auxiliary memory.
 FreeNullMem(AuxMem);
end;

//---------------------------------------------------------------------------
procedure RenderLineAlpha(Source, Dest: Pointer; Count, Alpha: Integer);
var
 i: Integer;
 SrcPx, DestPx: PLongWord;
begin
 SrcPx := Source;
 DestPx:= Dest;

 for i:= 0 to Count - 1 do
  begin
   DestPx^:= BlendPixels(SrcPx^, DestPx^, 255 - ((Integer(SrcPx^ shr 24) *
    Alpha) div 255));

   Inc(SrcPx);
   Inc(DestPx);
  end;
end;

//---------------------------------------------------------------------------
procedure RenderLineAlphaAdd(Source, Dest: Pointer; Count, Alpha: Integer);
var
 i: Integer;
 FadePx: Cardinal;
 SrcPx, DestPx: PLongWord;
begin
 SrcPx := Source;
 DestPx:= Dest;

 for i:= 0 to Count - 1 do
  begin
   FadePx:= SrcPx^ shr 24;
   FadePx:= FadePx or (FadePx shl 8) or (FadePx shl 16) or (FadePx shl 24);

   DestPx^:= AddPixels(MulPixels(SrcPx^, FadePx), DestPx^);

   Inc(SrcPx);
   Inc(DestPx);
  end;
end;

//---------------------------------------------------------------------------
procedure RenderLineDiffuse(Source, Dest: Pointer; Count: Integer;
 Diffuse: Cardinal);
var
 i: Integer;
 Pixel: Cardinal;
 SrcPx, DestPx: PLongWord;
begin
 SrcPx := Source;
 DestPx:= Dest;

 for i:= 0 to Count - 1 do
  begin
   Pixel:= MulPixels(SrcPx^, Diffuse);
   DestPx^:= BlendPixels(Pixel, DestPx^, 255 - (Pixel shr 24));

   Inc(SrcPx);
   Inc(DestPx);
  end;
end;

//---------------------------------------------------------------------------
end.
