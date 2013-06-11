//---------------------------------------------------------------------------
// Vectors2.inc
// Definitions and functions working with 2D vectors.
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
type
{ This type is used to pass @link(TPoint2) by reference. }
 PPoint2 = ^TPoint2;

//---------------------------------------------------------------------------
{ 2D floating-point vector. }
 TPoint2 = record
  { The coordinate in 2D space. }
  x, y: Single;

  {@exclude}class operator Add(const a, b: TPoint2): TPoint2;
  {@exclude}class operator Subtract(const a, b: TPoint2): TPoint2;
  {@exclude}class operator Multiply(const a, b: TPoint2): TPoint2;
  {@exclude}class operator Divide(const a, b: TPoint2): TPoint2;
  {@exclude}class operator Negative(const v: TPoint2): TPoint2;
  {@exclude}class operator Multiply(const v: TPoint2; k: Single): TPoint2;
  {@exclude}class operator Multiply(const v: TPoint2; k: Integer): TPoint2;
  {@exclude}class operator Divide(const v: TPoint2; k: Single): TPoint2;
  {@exclude}class operator Divide(const v: TPoint2; k: Integer): TPoint2;
  {@exclude}class operator Implicit(const Point: TPoint): TPoint2;
  {@exclude}class operator Implicit(const Point: TPoint2px): TPoint2;

  {$ifdef Vec2ToPxImplicit}
  { This implicit conversion is only allowed as a compiler directive because
    it causes ambiguity and precision problems when excessively used. In
    addition, it can make code confusing. }
  {@exclude}class operator Implicit(const Point: TPoint2): TPoint2px;
  {$endif}
 end;

//---------------------------------------------------------------------------
 TPoints2 = class;

//---------------------------------------------------------------------------
{@exclude}
 TPoints2Enumerator = class
 private
  {$ifdef DelphiNextGen}[weak]{$endif} List: TPoints2;
  Index: Integer;

  function GetCurrent(): TPoint2;
 public
  property Current: TPoint2 read GetCurrent;

  function MoveNext(): Boolean;
  constructor Create(const AList: TPoints2);
 end;

//---------------------------------------------------------------------------
{ A general-purpose list of 2D floating-point vectors. }
 TPoints2 = class
 private
  Data: array of TPoint2;
  DataCount: Integer;

  procedure SetCount(const Value: Integer);
  function GetItem(Index: Integer): PPoint2;
  procedure Request(Quantity: Integer);
 public
  { The total number of elements in the list. }
  property Count: Integer read DataCount write SetCount;

  { A direct access to each of the elements in the list. The first element has
    index of 0 and the last element is @link(Count) - 1. }
  property Items[Index: Integer]: PPoint2 read GetItem; default;

  //.........................................................................
  { Finds the element given by the vector in the list and returns its index. }
  function IndexOf(const Vec: TPoint2;
   CompareEpsilon: Single = 0.0001): Integer; overload;

  { Finds the element given by the coordinates in the list and returns its
    index. }
  function IndexOf(x, y: Single;
   CompareEpsilon: Single = 0.0001): Integer; overload;

  { Inserts the new vector to the list. }
  function Add(const Vec: TPoint2): Integer; overload;

  { Inserts the vector with the specified coordinates to the list. }
  function Add(x, y: Single): Integer; overload;

  { Removes the specified element from the list. }
  procedure Remove(Index: Integer);

  { Removes all elements from the list. }
  procedure RemoveAll();

  { Copies the entire contents from the source list to this one. }
  procedure CopyFrom(const Source: TPoints2);

  { Adds all elements from the source list to this one. }
  procedure AddFrom(const Source: TPoints2);

  {@exclude}function GetEnumerator(): TPoints2Enumerator;

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
const
{ Zero constant for @link(TPoint2) that can be used for vector
  initialization. }
 ZeroVec2: TPoint2 = (x: 0.0; y: 0.0);

//---------------------------------------------------------------------------
{ Unity constant for @link(TPoint2) that can be used for vector
  initialization. }
 UnityVec2: TPoint2 = (x: 1.0; y: 1.0);

//---------------------------------------------------------------------------
{ Creates a @link(TPoint2) record using the specified coordinates. }
function Point2(x, y: Single): TPoint2;

//---------------------------------------------------------------------------
{ Converts @link(TPoint2) to @link(TPoint2px) by using floating-point
  rounding. }
function Point2ToPx(const p: TPoint2): TPoint2px;

//---------------------------------------------------------------------------
{ Returns the length of the specified 2D vector. }
function Length2(const v: TPoint2): Single;

//---------------------------------------------------------------------------
{ Normalizes the specified 2D vector to unity length. The second parameter
  is used to prevent division by zero in vectors that are of zero length. }
function Norm2(const v: TPoint2; ZeroAmpEpsilon: Single = 0.00001): TPoint2;

//---------------------------------------------------------------------------
{ Returns the angle (in radians) at which the 2D vector is pointing at. }
function Angle2(const v: TPoint2): Single;

//---------------------------------------------------------------------------
{ Interpolates between the specified two 2D vectors.
   @param(v0 The first vector to be used in the interpolation)
   @param(v1 The second vector to be used in the interpolation)
   @param(Alpha The mixture of the two vectors with the a range of [0..1].) }
function Lerp2(const v0, v1: TPoint2; Alpha: Single): TPoint2;

//---------------------------------------------------------------------------
{ Calculates the dot-product of the specified 2D vectors. The dot-product is
 an indirect measure of the angle between two vectors. }
function Dot2(const a, b: TPoint2): Single;

//---------------------------------------------------------------------------
{ Calculates a so-called "cross product" of 2D vectors, or analog of
  thereof. }
function Cross2(const a, b: TPoint2): Single;

//---------------------------------------------------------------------------
{ Compares the two specified 2D vectors using the given threshold. }
function SameVec2(const a, b: TPoint2; Epsilon: Single = 0.0001): Boolean;

//---------------------------------------------------------------------------
{ Converts floating-point 2D vector to 2D integer vector by rounding down. }
{$ifndef Vec2ToPxImplicit}
function Vec2ToPx(const v: TPoint2): TPoint2px;
{$endif}

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
class operator TPoint2.Add(const a, b: TPoint2): TPoint2;
begin
 Result.x:= a.x + b.x;
 Result.y:= a.y + b.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Subtract(const a, b: TPoint2): TPoint2;
begin
 Result.x:= a.x - b.x;
 Result.y:= a.y - b.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Multiply(const a, b: TPoint2): TPoint2;
begin
 Result.x:= a.x * b.x;
 Result.y:= a.y * b.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Divide(const a, b: TPoint2): TPoint2;
begin
 Result.x:= a.x / b.x;
 Result.y:= a.y / b.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Negative(const v: TPoint2): TPoint2;
begin
 Result.x:= -v.x;
 Result.y:= -v.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Multiply(const v: TPoint2; k: Single): TPoint2;
begin
 Result.x:= v.x * k;
 Result.y:= v.y * k;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Multiply(const v: TPoint2; k: Integer): TPoint2;
begin
 Result.x:= v.x * k;
 Result.y:= v.y * k;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Divide(const v: TPoint2; k: Single): TPoint2;
begin
 Result.x:= v.x / k;
 Result.y:= v.y / k;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Divide(const v: TPoint2; k: Integer): TPoint2;
begin
 Result.x:= v.x / k;
 Result.y:= v.y / k;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Implicit(const Point: TPoint): TPoint2;
begin
 Result.x:= Point.X;
 Result.y:= Point.Y;
end;

//---------------------------------------------------------------------------
class operator TPoint2.Implicit(const Point: TPoint2px): TPoint2;
begin
 Result.x:= Point.x;
 Result.y:= Point.y;
end;

//---------------------------------------------------------------------------
{$ifdef Vec2ToPxImplicit}
class operator TPoint2.Implicit(const Point: TPoint2): TPoint2px;
begin
 Result.x:= Round(Point.x);
 Result.y:= Round(Point.y);
end;
{$endif}

//---------------------------------------------------------------------------
function Point2(x, y: Single): TPoint2;
begin
 Result.x:= x;
 Result.y:= y;
end;

//---------------------------------------------------------------------------
function Point2ToPx(const p: TPoint2): TPoint2px;
begin
 Result.x:= Round(p.x);
 Result.y:= Round(p.y);
end;

//---------------------------------------------------------------------------
function Length2(const v: TPoint2): Single;
begin
 Result:= Hypot(v.x, v.y);
end;

//---------------------------------------------------------------------------
function Norm2(const v: TPoint2; ZeroAmpEpsilon: Single = 0.00001): TPoint2;
var
 Amp: Single;
begin
 Amp:= Length2(v);

 if (Abs(Amp) > ZeroAmpEpsilon) then
  begin
   Result.x:= v.x / Amp;
   Result.y:= v.y / Amp;
  end else Result:= ZeroVec2;
end;

//---------------------------------------------------------------------------
function Angle2(const v: TPoint2): Single;
begin
 if (v.x <> 0.0) then Result:= ArcTan2(v.y, v.x)
  else Result:= 0.0;
end;

//---------------------------------------------------------------------------
function Lerp2(const v0, v1: TPoint2; Alpha: Single): TPoint2;
begin
 Result.x:= v0.x + (v1.x - v0.x) * Alpha;
 Result.y:= v0.y + (v1.y - v0.y) * Alpha;
end;

//---------------------------------------------------------------------------
function Dot2(const a, b: TPoint2): Single;
begin
 Result:= (a.x * b.x) + (a.y * b.y);
end;

//---------------------------------------------------------------------------
function Cross2(const a, b: TPoint2): Single;
begin
 Result:= (a.x * b.y) - (a.y * b.x);
end;

//---------------------------------------------------------------------------
function SameVec2(const a, b: TPoint2; Epsilon: Single = 0.0001): Boolean;
begin
 Result:=
  (Abs(a.x - b.x) < Epsilon)and
  (Abs(a.y - b.y) < Epsilon);
end;

//---------------------------------------------------------------------------
{$ifndef Vec2ToPxImplicit}
function Vec2ToPx(const v: TPoint2): TPoint2px;
begin
 Result.x:= Round(v.x);
 Result.y:= Round(v.y);
end;
{$endif}

//---------------------------------------------------------------------------
constructor TPoints2.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TPoints2.Destroy();
begin
 Dec(AsphyreClassInstances);

 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TPoints2.SetCount(const Value: Integer);
begin
 Request(Value);
 DataCount:= Value;
end;

//---------------------------------------------------------------------------
function TPoints2.GetItem(Index: Integer): PPoint2;
begin
 if (Index >= 0)and(Index < DataCount) then Result:= @Data[Index]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TPoints2.Request(Quantity: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Quantity / CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TPoints2.Add(const Vec: TPoint2): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Data[Index]:= Vec;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TPoints2.Add(x, y: Single): Integer;
begin
 Result:= Add(Point2(x, y));
end;

//---------------------------------------------------------------------------
procedure TPoints2.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TPoints2.RemoveAll();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TPoints2.CopyFrom(const Source: TPoints2);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TPoints2.AddFrom(const Source: TPoints2);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
function TPoints2.IndexOf(const Vec: TPoint2;
 CompareEpsilon: Single = 0.0001): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to DataCount - 1 do
  if (SameVec2(Data[i], Vec, CompareEpsilon)) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TPoints2.IndexOf(x, y: Single;
 CompareEpsilon: Single = 0.0001): Integer;
begin
 Result:= IndexOf(Point2(x, y), CompareEpsilon);
end;

//---------------------------------------------------------------------------
function TPoints2.GetEnumerator(): TPoints2Enumerator;
begin
 Result:= TPoints2Enumerator.Create(Self);
end;

//---------------------------------------------------------------------------
constructor TPoints2Enumerator.Create(const AList: TPoints2);
begin
 inherited Create();

 List := AList;
 Index:= -1;
end;

//---------------------------------------------------------------------------
function TPoints2Enumerator.GetCurrent(): TPoint2;
begin
 Result:= List.Items[Index]^;
end;

//---------------------------------------------------------------------------
function TPoints2Enumerator.MoveNext(): Boolean;
begin
 Result:= Index < List.Count - 1;
 if (Result) then Inc(Index);
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
