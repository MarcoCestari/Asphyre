//---------------------------------------------------------------------------
// Asphyre.FormatConv.inc
// Asphyre Pixel Format conversion.
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
// Note: this file has been preformatted to be used with PasDoc.
//---------------------------------------------------------------------------

{$ifdef Asphyre_Interface}

//---------------------------------------------------------------------------
{ Converts a single pixel from an arbitrary format back to 32-bit RGBA
  format (@link(apf_A8R8G8B8)). If the specified format is not supported,
  this function returns zero.
   @param(Source Pointer to a valid block of memory where the source pixel
    resides.)
   @param(SourceFormat Pixel format that is used to describe the source
    pixel.)
   @returns(Resulting pixel in 32-bit RGBA format (@link(apf_A8R8G8B8)).) }
function PixelXto32(Source: Pointer;
 SourceFormat: TAsphyrePixelFormat): Cardinal;

//---------------------------------------------------------------------------
{ Converts a single pixel from 32-bit RGBA format (@link(apf_A8R8G8B8)) to an
  arbitrary format. If the specified format is not supported, this function
  does nothing.
   @param(Source Source pixel specified in 32-bit RGBA format
    (@link(apf_A8R8G8B8)).)
   @param(Dest Pointer to the memory block where the resulting pixel should be
    written to. This memory should be previously allocated.)
   @param(DestFormat Pixel format that is used to describe the destination
    pixel.) }
procedure Pixel32toX(Source: Cardinal; Dest: Pointer;
 DestFormat: TAsphyrePixelFormat);

//---------------------------------------------------------------------------
{ Converts an array of pixels from an arbitrary format back to 32-bit RGBA
  format (@link(apf_A8R8G8B8)). If the specified format is not supported,
  this function does nothing.
   @param(Source Pointer to a valid memory block that holds the source pixels.)
   @param(Dest Pointer to a valid memory block where destination pixels will
    be written to.)
   @param(SourceFormat Pixel format that is used to describe the source
    pixels.)
   @param(Elements The number of pixels to convert.) }
procedure PixelXto32Array(Source, Dest: Pointer;
 SourceFormat: TAsphyrePixelFormat; Elements: Integer);

//---------------------------------------------------------------------------
// Pixel32toX()
//
// Converts an array of pixels from A8R8G8B8 (32-bit) format to an
// arbitrary format.
//---------------------------------------------------------------------------

{ Converts an array of pixels from 32-bit RGBA format (@link(apf_A8R8G8B8)) to
  an arbitrary format. If the specified format is not supported, this function
  does nothing.
   @param(Source Pointer to a valid memory block that holds the source pixels.)
   @param(Dest Pointer to a valid memory block where destination pixels will
    be written to.)
   @param(DestFormat Pixel format that is used to describe the destination
    pixels.)
   @param(Elements The number of pixels to convert.) }
procedure Pixel32toXArray(Source, Dest: Pointer;
 DestFormat: TAsphyrePixelFormat; Elements: Integer);

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
function PixelXto32(Source: Pointer;
 SourceFormat: TAsphyrePixelFormat): Cardinal;
var
 Bits : Integer;
 Value: Cardinal;
 Info : PFormatBitInfo;
 Mask : Cardinal;
begin
 Result:= 0;

 if (SourceFormat = apf_A16B16G16R16) then
  begin
   Value:= PLongword(Source)^;

   Result:=
    (((Value shl 16) shr 24) shl 16) or
    ((Value shr 24) shl 8);

   Value:= PLongword(PtrInt(Source) + 4)^;

   Result:= Result or
    ((Value shl 16) shr 24) or
    ((Value shr 24) shl 24);

   Exit;
  end;

 Bits:= AsphyrePixelFormatBits[SourceFormat];
 if (Bits < 8)or(Bits > 32) then Exit;

 Value:= 0;
 Move(Source^, Value, Bits div 8);

 case SourceFormat of
  apf_R8G8B8, apf_X8R8G8B8:
   Result:= Value or $FF000000;

  apf_A8R8G8B8:
   Result:= Value;

  apf_A8:
   Result:= Value shl 24;

  apf_L8:
   Result:= Value or (Value shl 8) or (Value shl 16) or $FF000000;

  apf_A8L8:
   begin
    Result:= Value and $FF;
    Result:= Result or (Result shl 8) or (Result shl 16) or
     ((Value shr 8) shl 24)
   end;

  apf_A4L4:
   begin
    Result:= ((Value and $0F) * 255) div 15;
    Result:= Result or (Result shl 8) or (Result shl 16) or
     ((((Value shr 4) * 255) div 15) shl 24);
   end;

  apf_L16:
   begin
    Result:= Value shr 8;
    Result:= Result or (Result shl 8) or (Result shl 16) or $FF000000;
   end;

  apf_A8B8G8R8:
   Result:= (Value and $FF00FF00) or ((Value shr 16) and $FF) or
    ((Value and $FF) shl 16);

  apf_X8B8G8R8:
   Result:= (Value and $0000FF00) or ((Value shr 16) and $FF) or
    ((Value and $FF) shl 16) or ($FF000000);

  apf_A5L3:
   begin
    Result:= ((Value and 7) * 255) div 7;
    Result:= Result or (Result shl 8) or (Result shl 16) or
     ((((Value shr 3) * 255) div 31) shl 24);
   end;

  else
   begin
    Info:= @FormatInfo[SourceFormat];

    // -> Blue Component
    if (Info.bNo > 0) then
     begin
      Mask:= (1 shl Info.bNo) - 1;
      Result:= (((Value shr Info.bAt) and Mask) * 255) div Mask;
     end else Result:= 255;

    // -> Green Component
    if (Info.gNo > 0) then
     begin
      Mask:= (1 shl Info.gNo) - 1;
      Result:= Result or
       (((((Value shr Info.gAt) and Mask) * 255) div Mask) shl 8);
     end else Result:= Result or $FF00;

    // -> Red Component
    if (Info.rNo > 0) then
     begin
      Mask:= (1 shl Info.rNo) - 1;
      Result:= Result or
       (((((Value shr Info.rAt) and Mask) * 255) div Mask) shl 16);
     end else Result:= Result or $FF0000;

    // -> Alpha Component
    if (Info.aNo > 0) then
     begin
      Mask:= (1 shl Info.aNo) - 1;
      Result:= Result or
       (((((Value shr Info.aAt) and Mask) * 255) div Mask) shl 24);
     end else Result:= Result or $FF000000;
   end;
 end;
end;

//---------------------------------------------------------------------------
function ComputeLuminance(Value: Cardinal): Single;
begin
 Result:= ((Value and $FF) * 0.11 + ((Value shr 8) and $FF) * 0.59 +
  ((Value shr 16) and $FF) * 0.3) / 255.0;
end;

//---------------------------------------------------------------------------
procedure Pixel32toX(Source: Cardinal; Dest: Pointer;
 DestFormat: TAsphyrePixelFormat);
var
 Bits : Integer;
 Value: Cardinal;
 Info : PFormatBitInfo;
 Mask : Cardinal;
begin
 if (DestFormat = apf_A16B16G16R16) then
  begin
   PLongword(Dest)^:=
    (((((Source shl 16) shr 24) * $FFFF) div $FF) shl 16) or
    ((((Source shl 8) shr 24) * $FFFF) div $FF);

   PLongword(PtrInt(Dest) + 4)^:=
    ((((Source shl 24) shr 24) * $FFFF) div $FF) or
    ((((Source shr 24) * $FFFF) div $FF) shl 16);

   Exit;
  end;

 Bits:= AsphyrePixelFormatBits[DestFormat];
 if (Bits < 8)or(Bits > 32) then Exit;

 Value:= 0;

 case DestFormat of
  apf_R8G8B8, apf_X8R8G8B8, apf_A8R8G8B8:
   Value:= Source;

  apf_A8:
   Value:= Source shr 24;

  apf_A8B8G8R8:
   Value:= (Source and $FF00FF00) or ((Source shr 16) and $FF) or
    ((Source and $FF) shl 16);

  apf_X8B8G8R8:
   Value:= (Source and $0000FF00) or ((Source shr 16) and $FF) or
    ((Source and $FF) shl 16);

  apf_L8:
   Value:= Round(ComputeLuminance(Source) * 255.0);

  apf_A8L8:
   Value:= ((Source shr 24) shl 8) or Round(ComputeLuminance(Source) * 255.0);

  apf_A4L4:
   Value:= ((Source shr 28) shl 4) or Round(ComputeLuminance(Source) * 15.0);

  apf_L16:
   Value:= Round(ComputeLuminance(Source) * 65535.0);

  apf_A5L3:
   Value:= ((Source shr 27) shl 3) or Round(ComputeLuminance(Source) * 7.0);

  else
   begin
    Info:= @FormatInfo[DestFormat];

    // -> Blue Component
    if (Info.bNo > 0) then
     begin
      Mask:= (1 shl Info.bNo) - 1;
      Value:= (((Source and $FF) * Mask) div 255) shl Info.bAt;
     end;

    // -> Green Component
    if (Info.gNo > 0) then
     begin
      Mask:= (1 shl Info.gNo) - 1;
      Value:= Value or
       ((((Source shr 8) and $FF) * Mask) div 255) shl Info.gAt;
     end;

    // -> Red Component
    if (Info.rNo > 0) then
     begin
      Mask:= (1 shl Info.rNo) - 1;
      Value:= Value or
       ((((Source shr 16) and $FF) * Mask) div 255) shl Info.rAt;
     end;

    // -> Alpha Component
    if (Info.aNo > 0) then
     begin
      Mask:= (1 shl Info.aNo) - 1;
      Value:= Value or
       ((((Source shr 24) and $FF) * Mask) div 255) shl Info.aAt;
     end;
   end;
 end;

 Move(Value, Dest^, Bits div 8);
end;

//---------------------------------------------------------------------------
procedure PixelXto32Array(Source, Dest: Pointer;
 SourceFormat: TAsphyrePixelFormat; Elements: Integer);
var
 Bits: Integer;
 SourcePx: Pointer;
 DestPx  : PLongWord;
 i, BytesPerPixel: Integer;
begin
 Bits:= AsphyrePixelFormatBits[SourceFormat];
 if (Bits < 8) then Exit;

 BytesPerPixel:= Bits div 8;

 SourcePx:= Source;
 DestPx  := Dest;
 for i:= 0 to Elements - 1 do
  begin
   DestPx^:= PixelXto32(SourcePx, SourceFormat);

   Inc(PtrInt(SourcePx), BytesPerPixel);
   Inc(DestPx);
  end;
end;

//---------------------------------------------------------------------------
procedure Pixel32toXArray(Source, Dest: Pointer;
 DestFormat: TAsphyrePixelFormat; Elements: Integer);
var
 Bits: Integer;
 SourcePx: PLongWord;
 DestPx  : Pointer;
 i, BytesPerPixel: Integer;
begin
 Bits:= AsphyrePixelFormatBits[DestFormat];
 if (Bits < 8) then Exit;

 BytesPerPixel:= Bits div 8;

 SourcePx:= Source;
 DestPx  := Dest;
 for i:= 0 to Elements - 1 do
  begin
   Pixel32toX(SourcePx^, DestPx, DestFormat);

   Inc(SourcePx);
   Inc(PtrInt(DestPx), BytesPerPixel);
  end;
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
