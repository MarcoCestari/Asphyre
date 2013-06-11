unit pxfm;
//---------------------------------------------------------------------------
// pxfm.pas
// Utility routines that facilitate work with ASVF images.
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
 System.Classes, Asphyre.Math, Asphyre.Surfaces, Asphyre.Types;

//---------------------------------------------------------------------------
type
 TPxFm = record
  Format       : TAsphyrePixelFormat;
  PatternWidth : Integer;
  PatternHeight: Integer;
  VisibleWidth : Integer;
  VisibleHeight: Integer;
  PatternCount : Integer;
  TextureWidth : Integer;
  TextureHeight: Integer;
  TextureCount : Integer;
 end;

//---------------------------------------------------------------------------
function WriteBitmapPxFm(Stream: TStream; Source: TSystemSurface;
 PxFm: TPxFm): Boolean;
function ReadBitmapPxFm(Stream: TStream; Dest: TSystemSurface;
 out PxFm: TPxFm): Boolean;

//---------------------------------------------------------------------------
procedure TileBitmap(Dest, Source: TSystemSurface; const TexSize, InPSize,
 OutPSize: TPoint2px; NeedMask: Boolean; MaskColor: Cardinal;
 Tolerance: Integer);

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 System.Math, Asphyre.Formats, Asphyre.Streams;

//---------------------------------------------------------------------------
type
 PRealColor = ^TRealColor;
 TRealColor = record
  r, g, b, a: Single;
 end;

//---------------------------------------------------------------------------
function WriteBitmapPxFm(Stream: TStream; Source: TSystemSurface;
 PxFm: TPxFm): Boolean;
var
 AuxMem : Pointer;
 AuxSize: Integer;
 Index  : Integer;
begin
 Result:= True;

 // (1) Write image header to the stream.
 try
  // --> Format
  StreamPutByte(Stream, Integer(PxFm.Format));
  // --> Pattern Size
  StreamPutWord(Stream, PxFm.PatternWidth);
  StreamPutWord(Stream, PxFm.PatternHeight);
  // --> Pattern Count
  StreamPutLongint(Stream, PxFm.PatternCount);
  // --> Visible Size
  StreamPutWord(Stream, PxFm.VisibleWidth);
  StreamPutWord(Stream, PxFm.VisibleHeight);
  // --> Texture Size
  StreamPutWord(Stream, PxFm.TextureWidth);
  StreamPutWord(Stream, PxFm.TextureHeight);
  // --> Texture Count
  StreamPutWord(Stream, PxFm.TextureCount);
 except
  Result:= False;
  Exit;
 end;

 // (2) Allocate auxiliary memory for pixel conversion.
 AuxSize:= (PxFm.TextureWidth * AsphyrePixelFormatBits[PxFm.Format]) div 8;
 AuxMem := AllocMem(AuxSize);

 // (3) Convert pixel data and write it to the stream.
 try
  for Index:= 0 to Source.Height - 1 do
   begin
    Pixel32toXArray(Source.ScanLine[Index], AuxMem, PxFm.Format,
     PxFm.TextureWidth);

    Stream.WriteBuffer(AuxMem^, AuxSize);
   end;
 except
  Result:= False;
 end;

 // (4) Release auxiliary memory.
 FreeMem(AuxMem);
end;

//---------------------------------------------------------------------------
function ReadBitmapPxFm(Stream: TStream; Dest: TSystemSurface;
 out PxFm: TPxFm): Boolean;
var
 Index  : Integer;
 AuxMem : Pointer;
 AuxSize: Integer;
 VDepth : Integer;
 TexIndx: Integer;
 VIndex : Integer;
begin
 Result:= True;

 // (1) Load image header from the stream.
 try
  // --> Format
  PxFm.Format:= TAsphyrePixelFormat(StreamGetByte(Stream));
  // --> Pattern Size
  PxFm.PatternWidth:= StreamGetWord(Stream);
  PxFm.PatternHeight:= StreamGetWord(Stream);
  // --> Pattern Count
  PxFm.PatternCount:= StreamGetLongint(Stream);
  // --> Visible Size
  PxFm.VisibleWidth:= StreamGetWord(Stream);
  PxFm.VisibleHeight:= StreamGetWord(Stream);
  // --> Texture Size
  PxFm.TextureWidth:= StreamGetWord(Stream);
  PxFm.TextureHeight:= StreamGetWord(Stream);
  // --> Texture Count
  PxFm.TextureCount:= StreamGetWord(Stream);
 except
  Result:= False;
  Exit;
 end;

 // (2) Real vertical depth (excludes the gap).
 VDepth:= (PxFm.TextureHeight div PxFm.PatternHeight) * PxFm.PatternHeight;

 // (3) Apply bitmap size.
 Dest.SetSize(PxFm.TextureWidth, VDepth * PxFm.TextureCount);

 // (4) Allocate auxiliary memory.
 AuxSize:= (Dest.Width * AsphyrePixelFormatBits[PxFm.Format]) div 8;
 AuxMem := AllocMem(AuxSize);

 // (5) Load pixel data.
 VIndex:= 0;
 for TexIndx:= 0 to PxFm.TextureCount - 1 do
  for Index:= 0 to PxFm.TextureHeight - 1 do
   begin
    if (Stream.Read(AuxMem^, AuxSize) <> AuxSize) then
     begin
      Result:= False;
      Break;
     end;

    if (Index < VDepth) then
     begin
      PixelXto32Array(AuxMem, Dest.ScanLine[VIndex], PxFm.Format, Dest.Width);
      Inc(VIndex);
     end;
   end;

 // (6) Release auxiliary memory.
 FreeMem(AuxMem);
end;

//---------------------------------------------------------------------------
function Color2Real(Color: Longword): TRealColor;
begin
 Result.b:= (Color and $FF) / 255.0;
 Result.g:= ((Color shr 8) and $FF) / 255.0;
 Result.r:= ((Color shr 16) and $FF) / 255.0;
 Result.a:= ((Color shr 24) and $FF) / 255.0;
end;

//---------------------------------------------------------------------------
function Real2Color(const Pix: TRealColor): Longword;
begin
 Result:= Round(Pix.b * 255.0) + (Round(Pix.g * 255.0) shl 8) +
  (Round(Pix.r * 255.0) shl 16) + (Round(Pix.a * 255.0) shl 24);
end;

//---------------------------------------------------------------------------
function Linear2Sine(Alpha: Single): Single;
const
 PiHalf = Pi / 2.0;
begin
 Result:= (Sin((Alpha * Pi) - PiHalf) + 1.0) / 2.0;
end;

//---------------------------------------------------------------------------
procedure LineConvMasked(Source, Dest: Pointer; Count, Tolerance: Integer;
 ColorMask: Cardinal);
const
 Delta2Dist = 57.73502692;
 DeltaMin = 0.025;
var
 InPx, OutPx: PLongword;
 Color, cMask: TRealColor;
 i: Integer;
 Delta, DeltaMax: Single;
begin
 InPx:= Source;
 OutPx:= Dest;
 cMask:= Color2Real(ColorMask);

 DeltaMax:= (Abs(Tolerance) / Delta2Dist) + DeltaMin;

 for i:= 0 to Count - 1 do
  begin
   // retreive real color
   Color:= Color2Real(InPx^);

   // calculate the difference (in %)
   Delta:= Sqrt(Sqr(Color.r - cMask.r) + Sqr(Color.g - cMask.g) +
    Sqr(Color.b - cMask.b));

   // based on distance, find the specified alpha-channel
   Color.a:= 1.0;
   if (Delta <= DeltaMax) then
    Color.a:= Linear2Sine(Delta / DeltaMax);

   // write final pixel
   OutPx^:= Real2Color(Color);

   // advance in pixel list
   Inc(InPx);
   Inc(OutPx);
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
 // Step 1. Determine source attributes
 SrcInRow:= Source.Width div InPSize.x;
 SrcInCol:= Source.Height div InPSize.y;
 SrcCount:= SrcInRow * SrcInCol;

 // Step 2. Determine destination attributes
 DstInRow:= TexSize.x div OutPSize.x;
 DstInCol:= TexSize.y div OutPSize.y;
 ImgInTex:= DstInRow * DstInCol;
 TexCount:= Ceil(SrcCount / ImgInTex);

 // Step 3. Allocate auxiliary memory
 AuxPitch:= InPSize.x * 4;
 AuxMem  := AllocMem(AuxPitch);

 // Step 4. Prepare source and destination images
 Dest.SetSize(TexSize.x, TexSize.y * TexCount);
 Dest.Clear($00000000);

 // Step 5. Place individual patterns
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
      MemAddr:= Pointer(Integer(Source.Scanline[(Index + SrcPt.y)]) + (SrcPt.x * 4));

      if (NeedMask) then
       begin
        LineConvMasked(MemAddr, AuxMem, InPSize.X, Tolerance, MaskColor);
       end else Move(MemAddr^, AuxMem^, InPSize.x * 4);

      DestIndx:= DestPt.y + (TexSize.y * TexIndex) + Index;
      MemAddr:= Pointer(Integer(Dest.Scanline[DestIndx]) + (DestPt.x * 4));
      Move(AuxMem^, MemAddr^, AuxPitch);
     end;

    Inc(SrcIndex);
    if (SrcIndex >= SrcCount) then Break;
   end;

 // Step 6. Release auxiliary memory
 FreeMem(AuxMem);
end;

//---------------------------------------------------------------------------
end.
