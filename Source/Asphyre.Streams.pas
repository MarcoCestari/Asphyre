unit Asphyre.Streams;
//---------------------------------------------------------------------------
// Utility routines for handling simple data types in streams.
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
{< Utility routines for saving and loading different data type in streams. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.Classes,
{$else}
 Classes,
{$endif}
 Asphyre.TypeDef, Asphyre.Math;

//---------------------------------------------------------------------------
{ Saves 8-bit unsigned integer to the stream. If the value is outside of
  [0..255] range, it will be clamped. }
procedure StreamPutByte(const Stream: TStream; Value: Cardinal); inline;

{ Loads 8-bit unsigned integer from the stream. }
function StreamGetByte(const Stream: TStream): Cardinal; inline;

//---------------------------------------------------------------------------
{ Saves 16-bit unsigned integer to the stream. If the value is outside of
  [0..65535] range, it will be clamped. }
procedure StreamPutWord(const Stream: TStream; Value: Cardinal); inline;

{ Loads 16-bit unsigned integer value from the stream. }
function StreamGetWord(const Stream: TStream): Cardinal; inline;

//---------------------------------------------------------------------------
{ Saves 32-bit unsigned integer to the stream. }
procedure StreamPutLongWord(const Stream: TStream; Value: Cardinal); inline;

{ Loads 32-bit unsigned integer from the stream. }
function StreamGetLongWord(const Stream: TStream): Cardinal; inline;

//---------------------------------------------------------------------------
{ Saves 8-bit signed integer to the stream. If the value is outside of
  [-128..127] range, it will be clamped. }
procedure StreamPutShortInt(const Stream: TStream; Value: Integer); inline;

{ Loads 8-bit signed integer from the stream. }
function StreamGetShortInt(const Stream: TStream): Integer; inline;

//---------------------------------------------------------------------------
{ Saves 16-bit signed integer to the stream. If the value is outside of
  [-32768..32767] range, it will be clamped. }
procedure StreamPutSmallInt(const Stream: TStream; Value: Integer); inline;

{ Loads 16-bit signed integer from the stream. }
function StreamGetSmallInt(const Stream: TStream): Integer; inline;

//---------------------------------------------------------------------------
{ Saves 32-bit signed integer to the stream. }
procedure StreamPutLongInt(const Stream: TStream; Value: Integer); inline;

{ Loads 32-bit signed integer from the stream. }
function StreamGetLongInt(const Stream: TStream): Integer; inline;

//---------------------------------------------------------------------------
{ Saves 64-bit signed integer to the stream. }
procedure StreamPutInt64(const Stream: TStream; const Value: Int64); inline;

{ Loads 64-bit signed integer from the stream. }
function StreamGetInt64(const Stream: TStream): Int64; inline;

//---------------------------------------------------------------------------
{ Saves 64-bit unsigned integer to the stream. }
procedure StreamPutUInt64(const Stream: TStream; 
 const Value: UInt64); inline;

{ Loads 64-bit unsigned integer from the stream. }
function StreamGetUInt64(const Stream: TStream): UInt64; inline;

//---------------------------------------------------------------------------
{ Saves @bold(Boolean) value to the stream as 8-bit unsigned integer. A value
  of @False is saved as 255, while @True is saved as 0. }
procedure StreamPutBool(const Stream: TStream; Value: Boolean); inline;

{ Loads @bold(Boolean) value from the stream previously saved by
  @link(StreamPutBool). The resulting value is treated as 8-bit unsigned
  integer with values of [0..127] considered as @True and values of
  [128..255] considered as @False. }
function StreamGetBool(const Stream: TStream): Boolean; inline;

//---------------------------------------------------------------------------
{ Saves 8-bit unsigned index to the stream. A value of -1 (and other
  negative values) is stored as 255. Positive numbers that are outside of
  [0..254] range will be clamped. }
procedure StreamPutByteIndex(const Stream: TStream; Value: Integer); inline;

{ Loads 8-bit unsigned index from the stream. The range of returned values is
  [0..254], the value of 255 is returned as -1. }
function StreamGetByteIndex(const Stream: TStream): Integer; inline;

//---------------------------------------------------------------------------
{ Saves 16-bit unsigned index to the stream. A value of -1 (and other
  negative values) is stored as 65535. Positive numbers that are outside of
  [0..65534] range will be clamped. }
procedure StreamPutWordIndex(const Stream: TStream; Value: Integer); inline;

{ Loads 16-bit unsigned index from the stream. The range of returned values is
  [0..65534], the value of 65535 is returned as -1. }
function StreamGetWordIndex(const Stream: TStream): Integer; inline;

//---------------------------------------------------------------------------
{ Saves 2D integer point to the stream. Each coordinate is saved as 32-bit
  signed integer. }
procedure StreamPutLongPoint2px(const Stream: TStream; 
 const Vec: TPoint2px); inline;

{ Loads 2D integer point from the stream. Each coordinate is loaded as 32-bit
  signed integer.}
function StreamGetLongPoint2px(const Stream: TStream): TPoint2px; inline;

//---------------------------------------------------------------------------
{ Saves 2D integer point to the stream. Each coordinate is saved as 16-bit
  unsigned integer with values outside of [0..65534] range clamped. Each
  coordinate values equalling to those of @link(InfPoint2px) will be saved
  as 65535. }
procedure StreamPutWordPoint2px(const Stream: TStream; 
 const Vec: TPoint2px); inline;

{ Loads 2D integer point from the stream. Each coordinate is loaded as 16-bit
  unsigned integer with values in range of [0..65534]. The loaded values of
  65535 are returned equalling to those from @link(InfPoint2px). }
function StreamGetWordPoint2px(const Stream: TStream): TPoint2px; inline;

//---------------------------------------------------------------------------
{ Saves 2D integer point to the stream. Each coordinate is saved as 8-bit
  unsigned integer with values outside of [0..254] range clamped. Each
  coordinate values equalling to those of @link(InfPoint2px) will be saved
  as 255. }
procedure StreamPutBytePoint2px(const Stream: TStream; 
 const Vec: TPoint2px); inline;

{ Loads 2D integer point from the stream. Each coordinate is loaded as 8-bit
  unsigned integer with values in range of [0..254]. The loaded values of
  255 are returned equalling to those from @link(InfPoint2px). }
function StreamGetBytePoint2px(const Stream: TStream): TPoint2px; inline;

//---------------------------------------------------------------------------
{ Saves 32-bit floating-point value (single-precision) to the stream. }
procedure StreamPutSingle(const Stream: TStream; Value: Single); inline;

{ Loads 32-bit floating-point value (single-precision) from the stream. }
function StreamGetSingle(const Stream: TStream): Single; inline;

//---------------------------------------------------------------------------
{ Saves 64-bit floating-point value (double-precision) to the stream. }
procedure StreamPutDouble(const Stream: TStream; Value: Double); inline;

{ Loads 64-bit floating-point value (double-precision) from the stream. }
function StreamGetDouble(const Stream: TStream): Double; inline;

//---------------------------------------------------------------------------
{ Saves floating-point value as 8-bit signed byte to the stream using 1:3:4
  fixed-point format with values outside of [-8..7.9375] range will be
  clamped.  }
procedure StreamPutFloat34(const Stream: TStream; Value: Single);

{ Loads floating-point value as 8-bit signed byte from the stream using 1:3:4
  fixed-point format. The possible values are in [-8..7.9375] range.  }
function StreamGetFloat34(const Stream: TStream): Single;

//---------------------------------------------------------------------------
{ Saves floating-point value as 8-bit signed byte to the stream using 1:4:3
  fixed-point format with values outside of [-16..15.875] range will be
  clamped.  }
procedure StreamPutFloat43(const Stream: TStream; Value: Single);

{ Loads floating-point value as 8-bit signed byte from the stream using 1:4:3
  fixed-point format. The possible values are in [-16..15.875] range.  }
function StreamGetFloat43(const Stream: TStream): Single;

//---------------------------------------------------------------------------
{ Saves two floating-point values as a single 8-bit unsigned byte to the
  stream with each value having 4-bits. Values outside of [-8..7] range will be
  clamped. }
procedure StreamPutFloats44(const Stream: TStream; Value1, Value2: Single);

{ Loads two floating-point values as a single 8-bit unsigned byte from the
  stream with each value having 4-bits. The possible values are in [-8..7]
  range. }
procedure StreamGetFloats44(const Stream: TStream; out Value1,
 Value2: Single);

//---------------------------------------------------------------------------
{ Saves two floating-point values as a single 8-bit unsigned byte to the
  stream with each value stored in fixed-point 1:2:1 format. Values outside
  of [-4..3.5] range will be clamped. }
procedure StreamPutFloats3311(const Stream: TStream; Value1, Value2: Single);

{ Loads two floating-point values as a single 8-bit unsigned byte from the
  stream with each value stored in fixed-point 1:2:1 format. The possible
  values are in [-4..3.5] range. }
procedure StreamGetFloats3311(const Stream: TStream; out Value1, 
 Value2: Single);

//---------------------------------------------------------------------------
{ Saves @bold(UniString) (Unicode) to the stream in UTF-8 encoding. The
  resulting UTF-8 string is limited to a maximum of 65535 characters;
  therefore, for certain charsets the actual string is limited to either
  32767 or even 21845 characters in worst case. If @italic(MaxCount) is not
  zero, the input string will be limited to the given number of characters. }
procedure StreamPutUtf8String(const Stream: TStream; const Text: UniString;
 MaxCount: Integer = 0);

{ Loads @bold(UniString) (Unicode) from the stream in UTF-8 encoding
  previously saved by @link(StreamPutUtf8String). }
function StreamGetUtf8String(const Stream: TStream): UniString;

//---------------------------------------------------------------------------
{ Saves @bold(UniString) (Unicode) to the stream in UTF-8 encoding. The
  resulting UTF-8 string is limited to a maximum of 255 characters;
  therefore, for certain charsets the actual string is limited to either
  127 or even 85 characters in worst case. If @italic(MaxCount) is not
  zero, the input string will be limited to the given number of characters. }
procedure StreamPutShortUtf8String(const Stream: TStream; 
 const Text: UniString; MaxCount: Integer = 0);

{ Loads @bold(UniString) (Unicode) from the stream in UTF-8 encoding
  previously saved by @link(StreamPutShortUtf8String). }
function StreamGetShortUtf8String(const Stream: TStream): UniString;

//---------------------------------------------------------------------------
{$define Asphyre_Interface}
 {$ifdef DelphiNextGen}
  {$include Asphyre.StreamUtilsNG.inc}
 {$else}
  {$include Asphyre.StreamUtils.inc}
 {$endif}
{$undef Asphyre_Interface}

//----------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifdef DelphiNextGen}
 System.SysUtils,
{$endif}

 Asphyre.Types;

//---------------------------------------------------------------------------
{$REGION 'Data Routines'}

//---------------------------------------------------------------------------
procedure StreamPutByte(const Stream: TStream; Value: Cardinal);
var
 ByteValue: Byte;
begin
 ByteValue:= Min2(Value, 255);
 Stream.WriteBuffer(ByteValue, SizeOf(Byte));
end;

//---------------------------------------------------------------------------
function StreamGetByte(const Stream: TStream): Cardinal;
var
 ByteValue: Byte;
begin
 Stream.ReadBuffer(ByteValue, SizeOf(Byte));
 Result:= ByteValue;
end;

//---------------------------------------------------------------------------
procedure StreamPutWord(const Stream: TStream; Value: Cardinal);
var
 WordValue: Word;
begin
 WordValue:= Min2(Value, 65535);
 Stream.WriteBuffer(WordValue, SizeOf(Word));
end;

//---------------------------------------------------------------------------
function StreamGetWord(const Stream: TStream): Cardinal;
var
 WordValue: Word;
begin
 Stream.ReadBuffer(WordValue, SizeOf(Word));
 Result:= WordValue;
end;

//---------------------------------------------------------------------------
procedure StreamPutLongWord(const Stream: TStream; Value: Cardinal);
var
 LongValue: LongWord;
begin
 LongValue:= Value;
 Stream.WriteBuffer(LongValue, SizeOf(LongWord));
end;

//---------------------------------------------------------------------------
function StreamGetLongWord(const Stream: TStream): Cardinal;
var
 LongValue: LongWord;
begin
 Stream.ReadBuffer(LongValue, SizeOf(LongWord));
 Result:= LongValue;
end;

//---------------------------------------------------------------------------
procedure StreamPutShortInt(const Stream: TStream; Value: Integer);
var
 IntValue: ShortInt;
begin
 IntValue:= MinMax2(Value, -128, 127);
 Stream.WriteBuffer(IntValue, SizeOf(ShortInt));
end;

//---------------------------------------------------------------------------
function StreamGetShortInt(const Stream: TStream): Integer;
var
 IntValue: ShortInt;
begin
 Stream.ReadBuffer(IntValue, SizeOf(ShortInt));
 Result:= IntValue;
end;

//---------------------------------------------------------------------------
procedure StreamPutSmallInt(const Stream: TStream; Value: Integer);
var
 IntValue: SmallInt;
begin
 IntValue:= MinMax2(Value, -32768, 32767);
 Stream.WriteBuffer(IntValue, SizeOf(SmallInt));
end;

//---------------------------------------------------------------------------
function StreamGetSmallInt(const Stream: TStream): Integer;
var
 IntValue: SmallInt;
begin
 Stream.ReadBuffer(IntValue, SizeOf(SmallInt));
 Result:= IntValue;
end;

//---------------------------------------------------------------------------
procedure StreamPutLongInt(const Stream: TStream; Value: Integer);
var
 LongValue: LongInt;
begin
 LongValue:= Value;
 Stream.WriteBuffer(LongValue, SizeOf(LongInt));
end;

//---------------------------------------------------------------------------
function StreamGetLongInt(const Stream: TStream): Integer;
var
 LongValue: LongInt;
begin
 Stream.ReadBuffer(LongValue, SizeOf(LongInt));
 Result:= LongValue;
end;

//---------------------------------------------------------------------------
procedure StreamPutInt64(const Stream: TStream; const Value: Int64);
begin
 Stream.WriteBuffer(Value, SizeOf(Int64));
end;

//---------------------------------------------------------------------------
function StreamGetInt64(const Stream: TStream): Int64;
begin
 Stream.ReadBuffer(Result, SizeOf(Int64));
end;

//---------------------------------------------------------------------------
procedure StreamPutUInt64(const Stream: TStream; const Value: UInt64);
begin
 Stream.WriteBuffer(Value, SizeOf(UInt64));
end;

//---------------------------------------------------------------------------
function StreamGetUInt64(const Stream: TStream): UInt64;
begin
 Stream.ReadBuffer(Result, SizeOf(UInt64));
end;

//---------------------------------------------------------------------------
procedure StreamPutBool(const Stream: TStream; Value: Boolean);
var
 ByteValue: Byte;
begin
 ByteValue:= 255;
 if (Value) then ByteValue:= 0;

 Stream.WriteBuffer(ByteValue, SizeOf(Byte));
end;

//---------------------------------------------------------------------------
function StreamGetBool(const Stream: TStream): Boolean;
var
 ByteValue: Byte;
begin
 Stream.ReadBuffer(ByteValue, SizeOf(Byte));
 Result:= ByteValue < 128;
end;

//---------------------------------------------------------------------------
procedure StreamPutByteIndex(const Stream: TStream; Value: Integer);
var
 ByteValue: Byte;
begin
 if (Value >= 0) then ByteValue:= Min2(Value, 254)
  else ByteValue:= 255;

 Stream.WriteBuffer(ByteValue, SizeOf(Byte));
end;

//---------------------------------------------------------------------------
function StreamGetByteIndex(const Stream: TStream): Integer;
var
 ByteValue: Byte;
begin
 Stream.ReadBuffer(ByteValue, SizeOf(Byte));

 if (ByteValue <> 255) then Result:= ByteValue
  else Result:= -1;
end;

//---------------------------------------------------------------------------
procedure StreamPutWordIndex(const Stream: TStream; Value: Integer);
var
 WordValue: Word;
begin
 if (Value >= 0) then WordValue:= Min2(Value, 65534)
  else WordValue:= 65535;

 Stream.WriteBuffer(WordValue, SizeOf(Word));
end;

//---------------------------------------------------------------------------
function StreamGetWordIndex(const Stream: TStream): Integer;
var
 WordValue: Word;
begin
 Stream.ReadBuffer(WordValue, SizeOf(Word));

 if (WordValue <> 65535) then Result:= WordValue
  else Result:= -1;
end;

//---------------------------------------------------------------------------
procedure StreamPutLongPoint2px(const Stream: TStream; const Vec: TPoint2px);
begin
 Stream.WriteBuffer(Vec.x, SizeOf(Longint));
 Stream.WriteBuffer(Vec.y, SizeOf(Longint));
end;

//---------------------------------------------------------------------------
function StreamGetLongPoint2px(const Stream: TStream): TPoint2px;
begin
 Stream.ReadBuffer(Result.x, SizeOf(Longint));
 Stream.ReadBuffer(Result.y, SizeOf(Longint));
end;

//---------------------------------------------------------------------------
procedure StreamPutWordPoint2px(const Stream: TStream; const Vec: TPoint2px);
var
 WordValue: Word;
begin
 if (Vec.x <> Low(LongInt)) then WordValue:= MinMax2(Vec.x, 0, 65534)
  else WordValue:= 65535;

 Stream.WriteBuffer(WordValue, SizeOf(Word));

 if (Vec.y <> Low(LongInt)) then WordValue:= MinMax2(Vec.y, 0, 65534)
  else WordValue:= 65535;

 Stream.WriteBuffer(WordValue, SizeOf(Word));
end;

//---------------------------------------------------------------------------
function StreamGetWordPoint2px(const Stream: TStream): TPoint2px;
var
 WordValue: Word;
begin
 Stream.ReadBuffer(WordValue, SizeOf(Word));

 if (WordValue <> 65535) then Result.x:= WordValue
  else Result.x:= Low(Integer);

 Stream.ReadBuffer(WordValue, SizeOf(Word));

 if (WordValue <> 65535) then Result.y:= WordValue
  else Result.y:= Low(Integer);
end;

//---------------------------------------------------------------------------
procedure StreamPutBytePoint2px(const Stream: TStream; const Vec: TPoint2px);
var
 ByteValue: Byte;
begin
 if (Vec.x <> Low(LongInt)) then ByteValue:= MinMax2(Vec.x, 0, 254)
  else ByteValue:= 255;

 Stream.WriteBuffer(ByteValue, SizeOf(Byte));

 if (Vec.y <> Low(LongInt)) then ByteValue:= MinMax2(Vec.y, 0, 254)
  else ByteValue:= 255;

 Stream.WriteBuffer(ByteValue, SizeOf(Byte));
end;

//---------------------------------------------------------------------------
function StreamGetBytePoint2px(const Stream: TStream): TPoint2px;
var
 ByteValue: Byte;
begin
 Stream.ReadBuffer(ByteValue, SizeOf(Byte));

 if (ByteValue <> 255) then Result.x:= ByteValue
  else Result.x:= Low(Integer);

 Stream.ReadBuffer(ByteValue, SizeOf(Byte));

 if (ByteValue <> 255) then Result.y:= ByteValue
  else Result.y:= Low(Integer);
end;

//---------------------------------------------------------------------------
procedure StreamPutSingle(const Stream: TStream; Value: Single);
begin
 Stream.WriteBuffer(Value, SizeOf(Single));
end;

//---------------------------------------------------------------------------
function StreamGetSingle(const Stream: TStream): Single;
begin
 Stream.ReadBuffer(Result, SizeOf(Single));
end;

//---------------------------------------------------------------------------
procedure StreamPutDouble(const Stream: TStream; Value: Double);
begin
 Stream.WriteBuffer(Value, SizeOf(Double));
end;

//---------------------------------------------------------------------------
function StreamGetDouble(const Stream: TStream): Double;
begin
 Stream.ReadBuffer(Result, SizeOf(Double));
end;

//----------------------------------------------------------------------------
procedure StreamPutFloat34(const Stream: TStream; Value: Single);
var
 Aux: Integer;
begin
 Aux:= MinMax2(Round(Value * 16.0), -128, 127);
 StreamPutShortInt(Stream, Aux);
end;

//----------------------------------------------------------------------------
function StreamGetFloat34(const Stream: TStream): Single;
begin
 Result:= StreamGetShortInt(Stream) / 16.0;
end;

//----------------------------------------------------------------------------
procedure StreamPutFloat43(const Stream: TStream; Value: Single);
var
 Aux: Integer;
begin
 Aux:= MinMax2(Round(Value * 8.0), -128, 127);
 StreamPutShortInt(Stream, Aux);
end;

//----------------------------------------------------------------------------
function StreamGetFloat43(const Stream: TStream): Single;
begin
 Result:= StreamGetShortInt(Stream) / 8.0;
end;

//---------------------------------------------------------------------------
procedure StreamPutFloats44(const Stream: TStream; Value1, Value2: Single);
var
 Aux1, Aux2: Integer;
begin
 Aux1:= MinMax2(Round(Value1), -8, 7) + 8;
 Aux2:= MinMax2(Round(Value2), -8, 7) + 8;

 StreamPutByte(Stream, Aux1 or (Aux2 shl 4));
end;

//---------------------------------------------------------------------------
procedure StreamGetFloats44(const Stream: TStream; out Value1, 
 Value2: Single);
var
 Aux: Integer;
begin
 Aux:= StreamGetByte(Stream);

 Value1:= ((Aux and $0F) - 8);
 Value2:= ((Aux shr 4) - 8);
end;

//---------------------------------------------------------------------------
procedure StreamPutFloats3311(const Stream: TStream; Value1, Value2: Single);
var
 Aux1, Aux2: Integer;
begin
 Aux1:= MinMax2(Round(Value1 * 2.0), -8, 7) + 8;
 Aux2:= MinMax2(Round(Value2 * 2.0), -8, 7) + 8;

 StreamPutByte(Stream, Aux1 or (Aux2 shl 4));
end;

//---------------------------------------------------------------------------
procedure StreamGetFloats3311(const Stream: TStream; out Value1,
 Value2: Single);
var
 Aux: Integer;
begin
 Aux:= StreamGetByte(Stream);

 Value1:= ((Aux and $0F) - 8) / 2.0;
 Value2:= ((Aux shr 4) - 8) / 2.0;
end;

{$ENDREGION}

//---------------------------------------------------------------------------
{$define Asphyre_Implementation}
 {$ifdef DelphiNextGen}
  {$include Asphyre.StreamUtilsNG.inc}
 {$else}
  {$include Asphyre.StreamUtils.inc}
 {$endif}
{$undef Asphyre_Implementation}

//----------------------------------------------------------------------------
end.
