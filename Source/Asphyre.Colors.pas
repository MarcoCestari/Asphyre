unit Asphyre.Colors;
//---------------------------------------------------------------------------
// Floating-point true color implementation.
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
{< Types, classes and utility routines working with colors defined using
   floating-point numbers. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.SysUtils, System.Math;
{$else}
 SysUtils, Math;
{$endif}


//---------------------------------------------------------------------------
type
{ Pointer to @link(TAsphyreColor) to pass the structure by reference. }
 PAsphyreColor = ^TAsphyreColor;

//---------------------------------------------------------------------------
{ High-fidelity color type using floating-point numbers.
   @member r Red component typically in [0, 1] range.
   @member g Green component typically in [0, 1] range.
   @member b Blue component typically in [0, 1] range.
   @member a Alpha-channel component typically in [0, 1] range. }
 TAsphyreColor = record
  r, g, b, a: Single;

  {@exclude}class operator Add(const a, b: TAsphyreColor): TAsphyreColor;
  {@exclude}class operator Subtract(const a, b: TAsphyreColor): TAsphyreColor;
  {@exclude}class operator Multiply(const a, b: TAsphyreColor): TAsphyreColor;
  {@exclude}class operator Divide(const a, b: TAsphyreColor): TAsphyreColor;

  {@exclude}class operator Multiply(const c: TAsphyreColor; k: Single): TAsphyreColor;
  {@exclude}class operator Divide(const c: TAsphyreColor; k: Single): TAsphyreColor;

  {@exclude}class operator Implicit(const c: TAsphyreColor): Cardinal;
  {@exclude}class operator Implicit(c: Cardinal): TAsphyreColor;
  {@exclude}class operator Explicit(const c: TAsphyreColor): Cardinal;
  {@exclude}class operator Explicit(c: Cardinal): TAsphyreColor;
 end;

//---------------------------------------------------------------------------
{ List of high-fidelity color types that use floating-point numbers. }
 TAsphyreColors = class
 private
  Data: array of TAsphyreColor;
  DataCount: Integer;

  function GetItem(Index: Integer): PAsphyreColor;
  procedure Request(Quantity: Integer);
  function GetMemAddr(): Pointer;
 public
  { Pointer to the first element in the list. If the list is empty, the
    returned value is @nil. }
  property MemAddr: Pointer read GetMemAddr;

  { The number of elements in the list. }
  property Count: Integer read DataCount;

  { Provides access to individual colors in the list by using each item's
    index, which should be in range of [0..(Count - 1)]. If the index is
    outside of valid range, the returned value is @nil. }
  property Items[Index: Integer]: PAsphyreColor read GetItem; default;

  { Adds the given color to the list. }
  function Add(const NewCol: TAsphyreColor): Integer; overload;

  { Removes one element from the list given by its index, which should be in
    range of [0..(Count - 1)]. If the index is outside of valir range, this
    method does nothing. }
  procedure Remove(Index: Integer);

  { Removes all elements from the list. }
  procedure RemoveAll();

  { Copies the entire contents from the source list to this one, creating an
    exact copy. }
  procedure CopyFrom(Source: TAsphyreColors);

  { Adds all elements from the source list to this one. }
  procedure AddFrom(Source: TAsphyreColors);

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{ Constructs @link(TAsphyreColor) using individual components. }
function cColor(r, g, b, a: Single): TAsphyreColor; overload;

//---------------------------------------------------------------------------
{ Constructs @link(TAsphyreColor) where red, green and blue components are
  set to the given grayscale value and alpha-channel specified separately. }
function cColor(Gray, Alpha: Single): TAsphyreColor; overload;

//---------------------------------------------------------------------------
{ Constructs @link(TAsphyreColor) where red, green and blue components are
  set to the given grayscale value and alpha-channel set to one. }
function cColor(Gray: Single): TAsphyreColor; overload;

//---------------------------------------------------------------------------
{ This function takes the source color and returns the same color but with
  alpha-channel set to one. }
function cNoAlpha(const Src: TAsphyreColor): TAsphyreColor;

//---------------------------------------------------------------------------
{ Clamps the individual components of the given color so that the resulting
  color has all its components within [0..1] range. }
function cClamp(const c: TAsphyreColor): TAsphyreColor;

//---------------------------------------------------------------------------
{ Similar to @link(cClamp) this function makes sure that all components stay
  within the range of [0..1]. However, if one of the components overpasses
  the limit, it will be "wrapped" from the limit; for example, value of 1.2
  becomes 0.8, 1.1 becomes 0.9, -0.3 becomes 0.3, -1.25 becomes 0.25 and so
  on. }
function cWrap(const c: TAsphyreColor): TAsphyreColor;

//---------------------------------------------------------------------------
{ Interpolates between two given colors producing the resulting mixture.
  @code(Alpha) should be specified in [0..1] range. }
{$ifdef fpc}
// FreePascal has a bug in its ARM compiler causing access violation on iOS,
// when "const" is used.
function cLerp(Src, Dest: TAsphyreColor; Alpha: Single): TAsphyreColor;
{$else}
function cLerp(const Src, Dest: TAsphyreColor; Alpha: Single): TAsphyreColor;
{$endif}

//---------------------------------------------------------------------------
{ Interpolates between two given colors producing the resulting mixture.
  @code(Alpha) should be specified in [0..255] range. }
function cBlend(const Src, Dest: TAsphyreColor; Alpha: Integer): TAsphyreColor;

//---------------------------------------------------------------------------
{ Computes cubic interpolation between four colors for each individual
  components using Catmull-Rom interpolation. @code(Theta) should be
  specified in [0..1] range.  }
function cCubic(const c1, c2, c3, c4: TAsphyreColor;
 Theta: Single): TAsphyreColor;

//---------------------------------------------------------------------------
{ Multiplies red, green and blue channels of the given color by the specified
  coefficient and returns the result. }
function cDarken(const c: TAsphyreColor; Light: Single): TAsphyreColor;

//---------------------------------------------------------------------------
{ Multiplies alpha-channel from the given color by the specified coefficient
  and returns the resulting color with red, green and blue components
  unchanged. }
function cModulateAlpha(const c: TAsphyreColor;
 Alpha: Single): TAsphyreColor;

//---------------------------------------------------------------------------
{ Computes negative color from the source by subtracting each individual
  component from one. }
function cNegative(const c: TAsphyreColor): TAsphyreColor;

//---------------------------------------------------------------------------
{ Calculates the gray value that appear in perceptual terms from the source
  color. }
function cGrayValue(const Color: TAsphyreColor): Single;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types;

//---------------------------------------------------------------------------
const
 CacheSize = 128;

//---------------------------------------------------------------------------
class operator TAsphyreColor.Add(const a, b: TAsphyreColor): TAsphyreColor;
begin
 Result.r:= a.r + b.r;
 Result.g:= a.g + b.g;
 Result.b:= a.b + b.b;
 Result.a:= a.a + b.a;
end;

//---------------------------------------------------------------------------
class operator TAsphyreColor.Subtract(const a, b: TAsphyreColor): TAsphyreColor;
begin
 Result.r:= a.r - b.r;
 Result.g:= a.g - b.g;
 Result.b:= a.b - b.b;
 Result.b:= a.a - b.a;
end;

//---------------------------------------------------------------------------
class operator TAsphyreColor.Multiply(const a, b: TAsphyreColor): TAsphyreColor;
begin
 Result.r:= a.r * b.r;
 Result.g:= a.g * b.g;
 Result.b:= a.b * b.b;
 Result.a:= a.a * b.a;
end;

//---------------------------------------------------------------------------
class operator TAsphyreColor.Divide(const a, b: TAsphyreColor): TAsphyreColor;
begin
 Result.r:= a.r / b.r;
 Result.g:= a.g / b.g;
 Result.b:= a.b / b.b;
 Result.a:= a.a / b.a;
end;

//---------------------------------------------------------------------------
class operator TAsphyreColor.Multiply(const c: TAsphyreColor;
 k: Single): TAsphyreColor;
begin
 Result.r:= c.r * k;
 Result.g:= c.g * k;
 Result.b:= c.b * k;
 Result.a:= c.a * k;
end;

//---------------------------------------------------------------------------
class operator TAsphyreColor.Divide(const c: TAsphyreColor;
 k: Single): TAsphyreColor;
begin
 Result.r:= c.r / k;
 Result.g:= c.g / k;
 Result.b:= c.b / k;
 Result.a:= c.a / k;
end;

//---------------------------------------------------------------------------
class operator TAsphyreColor.Implicit(c: Cardinal): TAsphyreColor;
begin
 Result.b:= (c and $FF) / 255.0;
 Result.g:= ((c shr 8) and $FF) / 255.0;
 Result.r:= ((c shr 16) and $FF) / 255.0;
 Result.a:= ((c shr 24) and $FF) / 255.0;
end;

//---------------------------------------------------------------------------
class operator TAsphyreColor.Implicit(const c: TAsphyreColor): Cardinal;
begin
 Result:=
  Cardinal(Round(c.b * 255.0)) or
  (Cardinal(Round(c.g * 255.0)) shl 8) or
  (Cardinal(Round(c.r * 255.0)) shl 16) or
  (Cardinal(Round(c.a * 255.0)) shl 24);
end;

//---------------------------------------------------------------------------
class operator TAsphyreColor.Explicit(c: Cardinal): TAsphyreColor;
begin
 Result.b:= (c and $FF) / 255.0;
 Result.g:= ((c shr 8) and $FF) / 255.0;
 Result.r:= ((c shr 16) and $FF) / 255.0;
 Result.a:= ((c shr 24) and $FF) / 255.0;
end;

//---------------------------------------------------------------------------
class operator TAsphyreColor.Explicit(const c: TAsphyreColor): Cardinal;
begin
 Result:=
  Cardinal(Round(c.b * 255.0)) or
  (Cardinal(Round(c.g * 255.0)) shl 8) or
  (Cardinal(Round(c.r * 255.0)) shl 16) or
  (Cardinal(Round(c.a * 255.0)) shl 24);
end;

//---------------------------------------------------------------------------
function cColor(r, g, b, a: Single): TAsphyreColor;
begin
 Result.r:= r;
 Result.g:= g;
 Result.b:= b;
 Result.a:= a;
end;

//---------------------------------------------------------------------------
function cColor(Gray, Alpha: Single): TAsphyreColor;
begin
 Result:= cColor(Gray, Gray, Gray, Alpha);
end;

//---------------------------------------------------------------------------
function cColor(Gray: Single): TAsphyreColor;
begin
 Result:= cColor(Gray, 1.0);
end;

//---------------------------------------------------------------------------
function cClamp(const c: TAsphyreColor): TAsphyreColor;
begin
 Result.r:= Min(Max(c.r, 0.0), 1.0);
 Result.g:= Min(Max(c.g, 0.0), 1.0);
 Result.b:= Min(Max(c.b, 0.0), 1.0);
 Result.a:= Min(Max(c.a, 0.0), 1.0);
end;

//---------------------------------------------------------------------------
function cWrap(const c: TAsphyreColor): TAsphyreColor;
begin
 Result:= c;

 if (Result.r > 1.0) then Result.r:= 1.0 - (Result.r - 1.0);
 if (Result.r < 0) then Result.r:= -Result.r;

 if (Result.g > 1.0) then Result.g:= 1.0 - (Result.g - 1.0);
 if (Result.g < 0) then Result.g:= -Result.g;

 if (Result.b > 1.0) then Result.b:= 1.0 - (Result.b - 1.0);
 if (Result.b < 0) then Result.b:= -Result.b;

 if (Result.a > 1.0) then Result.a:= 1.0 - (Result.a - 1.0);
 if (Result.a < 0) then Result.a:= -Result.a;
end;

//---------------------------------------------------------------------------
{$ifdef fpc}
function cLerp(Src, Dest: TAsphyreColor; Alpha: Single): TAsphyreColor;
{$else}
function cLerp(const Src, Dest: TAsphyreColor; Alpha: Single): TAsphyreColor;
{$endif}
begin
 Result.r:= Src.r + (Dest.r - Src.r) * Alpha;
 Result.g:= Src.g + (Dest.g - Src.g) * Alpha;
 Result.b:= Src.b + (Dest.b - Src.b) * Alpha;
 Result.a:= Src.a + (Dest.a - Src.a) * Alpha;
end;

//---------------------------------------------------------------------------
function cBlend(const Src, Dest: TAsphyreColor; Alpha: Integer): TAsphyreColor;
begin
 Result:= cLerp(Src, Dest, Alpha / 255.0);
end;

//---------------------------------------------------------------------------
function cCubic(const c1, c2, c3, c4: TAsphyreColor;
 Theta: Single): TAsphyreColor;
begin
 Result.r:= CatmullRom(c1.r, c2.r, c3.r, c4.r, Theta);
 Result.g:= CatmullRom(c1.g, c2.g, c3.g, c4.g, Theta);
 Result.b:= CatmullRom(c1.b, c2.b, c3.b, c4.b, Theta);
 Result.a:= CatmullRom(c1.a, c2.a, c3.a, c4.a, Theta);
end;

//---------------------------------------------------------------------------
function cNoAlpha(const Src: TAsphyreColor): TAsphyreColor;
begin
 Result.r:= Src.r;
 Result.g:= Src.g;
 Result.b:= Src.b;
 Result.a:= 1.0;
end;

//---------------------------------------------------------------------------
function cDarken(const c: TAsphyreColor; Light: Single): TAsphyreColor;
begin
 Result.r:= c.r * Light;
 Result.g:= c.g * Light;
 Result.b:= c.b * Light;
 Result.a:= c.a;
end;

//---------------------------------------------------------------------------
function cModulateAlpha(const c: TAsphyreColor;
 Alpha: Single): TAsphyreColor;
begin
 Result.r:= c.r;
 Result.g:= c.g;
 Result.b:= c.b;
 Result.a:= c.a * Alpha;
end;

//---------------------------------------------------------------------------
function cNegative(const c: TAsphyreColor): TAsphyreColor;
begin
 Result.r:= 1.0 - c.r;
 Result.g:= 1.0 - c.g;
 Result.b:= 1.0 - c.b;
 Result.a:= c.a;
end;

//---------------------------------------------------------------------------
function cGrayValue(const Color: TAsphyreColor): Single;
begin
 Result:= (Color.r * 0.29889531 + Color.g * 0.58662246 +
  Color.b * 0.11448223) * Color.a;
end;

//---------------------------------------------------------------------------
constructor TAsphyreColors.Create();
begin
 inherited;

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TAsphyreColors.Destroy();
begin
 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreColors.GetMemAddr(): Pointer;
begin
 Result:= @Data[0];
end;

//---------------------------------------------------------------------------
function TAsphyreColors.GetItem(Index: Integer): PAsphyreColor;
begin
 if (Index >= 0)and(Index < DataCount) then Result:= @Data[Index]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TAsphyreColors.Request(Quantity: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Quantity / CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TAsphyreColors.Add(const NewCol: TAsphyreColor): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Data[Index]:= NewCol;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
procedure TAsphyreColors.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TAsphyreColors.RemoveAll();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TAsphyreColors.CopyFrom(Source: TAsphyreColors);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TAsphyreColors.AddFrom(Source: TAsphyreColors);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
end.
