//---------------------------------------------------------------------------
// Vectors2px.inc
// Definitions and functions working with 2D integer vectors.
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
{ This type is used to pass @link(TPoint2px) by reference. }
 PPoint2px = ^TPoint2px;

//---------------------------------------------------------------------------
{ 2D integer vector. }
 TPoint2px = record
  { The coordinate in 2D space. }
  x, y: Integer;

  {@exclude}class operator Add(const a, b: TPoint2px): TPoint2px;
  {@exclude}class operator Subtract(const a, b: TPoint2px): TPoint2px;
  {@exclude}class operator Multiply(const a, b: TPoint2px): TPoint2px;
  {@exclude}class operator Divide(const a, b: TPoint2px): TPoint2px;

  {@exclude}class operator Negative(const v: TPoint2px): TPoint2px;
  {@exclude}class operator Multiply(const v: TPoint2px; k: Single): TPoint2px;
  {@exclude}class operator Multiply(const v: TPoint2px; k: Integer): TPoint2px;
  {@exclude}class operator Divide(const v: TPoint2px; k: Single): TPoint2px;
  {@exclude}class operator Divide(const v: TPoint2px; k: Integer): TPoint2px;
  {@exclude}class operator Implicit(const Point: TPoint): TPoint2px;
  {@exclude}class operator Implicit(const Point: TPoint2px): TPoint;
  {@exclude}class operator Equal(const a, b: TPoint2px): Boolean;
  {@exclude}class operator NotEqual(const a, b: TPoint2px): Boolean;
 end;

//---------------------------------------------------------------------------
 TPoints2px = class;

//---------------------------------------------------------------------------
{@exclude}
 TPoints2pxEnumerator = class
 private
  {$ifdef DelphiNextGen}[weak]{$endif} List: TPoints2px;
  Index: Integer;

  function GetCurrent(): TPoint2px;
 public
  property Current: TPoint2px read GetCurrent;

  function MoveNext(): Boolean;
  constructor Create(const AList: TPoints2px);
 end;

//---------------------------------------------------------------------------
{ A general-purpose list of 2D integer vectors. }
 TPoints2px = class
 private
  Data: array of TPoint2px;
  DataCount: Integer;

  function GetItem(Index: Integer): PPoint2px;
  procedure Request(Quantity: Integer);
  procedure SetCount(const Value: Integer);
 public
  { The total number of elements in the list. }
  property Count: Integer read DataCount write SetCount;

  { A direct access to each of the elements in the list. The first element has
    index of 0 and the last element is @link(Count) - 1. }
  property Items[Index: Integer]: PPoint2px read GetItem; default;

  //.........................................................................
  { Finds the element given by the vector in the list and returns its index. }
  function IndexOf(const Point: TPoint2px): Integer; overload;

  { Finds the element given by the coordinates in the list and returns its
    index. }
  function IndexOf(x, y: Integer): Integer; overload;

  { Inserts the new vector to the list. }
  function Add(const Point: TPoint2px): Integer; overload;

  { Inserts the vector with the specified coordinates to the list. }
  function Add(x, y: Integer): Integer; overload;

  { Removes the specified element from the list. }
  procedure Remove(Index: Integer);

  { Removes all elements from the list. }
  procedure RemoveAll();

  { Copies the entire contents from the source list to this one. }
  procedure CopyFrom(const Source: TPoints2px);

  { Adds all elements from the source list to this one. }
  procedure AddFrom(const Source: TPoints2px);

  {@exclude}function GetEnumerator(): TPoints2pxEnumerator;

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
const
{ Zero constant for @link(TPoint2px) that can be used for vector
  initialization. }
 ZeroPoint2px: TPoint2px = (x: 0; y: 0);

//---------------------------------------------------------------------------
{ Unity constant for @link(TPoint2px) that can be used for vector
  initialization. }
 UnityPoint2px: TPoint2px = (x: 1; y: 1);

//---------------------------------------------------------------------------
{ Infinity constant for @link(TPoint2px). In certain situations this vector
  is used to identify unknown vector value. }
 InfPoint2px: TPoint2px = (x: Low(Integer); y: Low(Integer));

//---------------------------------------------------------------------------
{ Creates a @link(TPoint2px) record using the specified coordinates. }
function Point2px(x, y: Integer): TPoint2px;

//---------------------------------------------------------------------------
{ Returns the length of the specified 2D vector. }
function Length2px(const v: TPoint2px): Single;

//---------------------------------------------------------------------------
{ Returns the angle (in radians) at which the 2D vector is pointing at. }
function Angle2px(const v: TPoint2px): Single;

//---------------------------------------------------------------------------
{ Interpolates between the specified two vectors.
   @param(v0 The first vector to be used in the interpolation)
   @param(v1 The second vector to be used in the interpolation)
   @param(Alpha The mixture of the two vectors with the a range of [0..1].) }
function Lerp2px(const v0, v1: TPoint2px; Alpha: Single): TPoint2px;

//---------------------------------------------------------------------------
{ Calculates the dot-product of the specified 2D vectors. The dot-product is
 an indirect measure of the angle between two vectors. }
function Dot2px(const a, b: TPoint2px): Integer;

//---------------------------------------------------------------------------
{ Calculates a so-called "cross product" of 2D vectors, or analog of
  thereof. }
function Cross2px(const a, b: TPoint2px): Integer;

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
class operator TPoint2px.Add(const a, b: TPoint2px): TPoint2px;
begin
 Result.x:= a.x + b.x;
 Result.y:= a.y + b.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2px.Subtract(const a, b: TPoint2px): TPoint2px;
begin
 Result.x:= a.x - b.x;
 Result.y:= a.y - b.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2px.Multiply(const a, b: TPoint2px): TPoint2px;
begin
 Result.x:= a.x * b.x;
 Result.y:= a.y * b.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2px.Divide(const a, b: TPoint2px): TPoint2px;
begin
 Result.x:= a.x div b.x;
 Result.y:= a.y div b.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2px.Negative(const v: TPoint2px): TPoint2px;
begin
 Result.x:= -v.x;
 Result.y:= -v.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2px.Multiply(const v: TPoint2px;
 k: Integer): TPoint2px;
begin
 Result.x:= v.x * k;
 Result.y:= v.y * k;
end;

//---------------------------------------------------------------------------
class operator TPoint2px.Multiply(const v: TPoint2px;
 k: Single): TPoint2px;
begin
 Result.x:= Round(v.x * k);
 Result.y:= Round(v.y * k);
end;

//---------------------------------------------------------------------------
class operator TPoint2px.Divide(const v: TPoint2px;
 k: Integer): TPoint2px;
begin
 Result.x:= v.x div k;
 Result.y:= v.y div k;
end;

//---------------------------------------------------------------------------
class operator TPoint2px.Divide(const v: TPoint2px;
 k: Single): TPoint2px;
begin
 Result.x:= Round(v.x / k);
 Result.y:= Round(v.y / k);
end;

//---------------------------------------------------------------------------
class operator TPoint2px.Implicit(const Point: TPoint): TPoint2px;
begin
 Result.x:= Point.X;
 Result.y:= Point.Y;
end;

//---------------------------------------------------------------------------
class operator TPoint2px.Implicit(const Point: TPoint2px): TPoint;
begin
 Result.X:= Point.x;
 Result.Y:= Point.y;
end;

//---------------------------------------------------------------------------
class operator TPoint2px.Equal(const a, b: TPoint2px): Boolean;
begin
 Result:= (a.x = b.x)and(a.y = b.y);
end;

//---------------------------------------------------------------------------
class operator TPoint2px.NotEqual(const a, b: TPoint2px): Boolean;
begin
 Result:= (a.x <> b.x)or(a.y <> b.y);
end;

//---------------------------------------------------------------------------
function Point2px(x, y: Integer): TPoint2px;
begin
 Result.x:= x;
 Result.y:= y;
end;

//---------------------------------------------------------------------------
function Length2px(const v: TPoint2px): Single;
begin
 Result:= Hypot(v.x, v.y);
end;

//---------------------------------------------------------------------------
function Angle2px(const v: TPoint2px): Single;
begin
 Result:= ArcTan2(v.y, v.x);
end;

//---------------------------------------------------------------------------
function Lerp2px(const v0, v1: TPoint2px; Alpha: Single): TPoint2px;
begin
 Result.x:= Round(v0.x + (v1.x - v0.x) * Alpha);
 Result.y:= Round(v0.y + (v1.y - v0.y) * Alpha);
end;

//---------------------------------------------------------------------------
function Dot2px(const a, b: TPoint2px): Integer;
begin
 Result:= (a.x * b.x) + (a.y * b.y);
end;

//---------------------------------------------------------------------------
function Cross2px(const a, b: TPoint2px): Integer;
begin
 Result:= (a.x * b.y) - (a.y * b.x);
end;

//---------------------------------------------------------------------------
constructor TPoints2px.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TPoints2px.Destroy();
begin
 Dec(AsphyreClassInstances);

 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TPoints2px.SetCount(const Value: Integer);
begin
 Request(Value);
 DataCount:= Value;
end;

//---------------------------------------------------------------------------
function TPoints2px.GetItem(Index: Integer): PPoint2px;
begin
 if (Index >= 0)and(Index < DataCount) then Result:= @Data[Index]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TPoints2px.Request(Quantity: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Quantity / CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TPoints2px.Add(const Point: TPoint2px): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Data[Index]:= Point;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TPoints2px.Add(x, y: Integer): Integer;
begin
 Result:= Add(Point2px(x, y));
end;

//---------------------------------------------------------------------------
procedure TPoints2px.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TPoints2px.RemoveAll();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TPoints2px.CopyFrom(const Source: TPoints2px);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TPoints2px.AddFrom(const Source: TPoints2px);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
function TPoints2px.IndexOf(const Point: TPoint2px): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to DataCount - 1 do
  if (Data[i] = Point) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TPoints2px.IndexOf(x, y: Integer): Integer;
begin
 Result:= IndexOf(Point2px(x, y));
end;

//---------------------------------------------------------------------------
function TPoints2px.GetEnumerator(): TPoints2pxEnumerator;
begin
 Result:= TPoints2pxEnumerator.Create(Self);
end;

//---------------------------------------------------------------------------
constructor TPoints2pxEnumerator.Create(const AList: TPoints2px);
begin
 inherited Create();

 List := AList;
 Index:= -1;
end;

//---------------------------------------------------------------------------
function TPoints2pxEnumerator.GetCurrent(): TPoint2px;
begin
 Result:= List.Items[Index]^;
end;

//---------------------------------------------------------------------------
function TPoints2pxEnumerator.MoveNext(): Boolean;
begin
 Result:= Index < List.Count - 1;
 if (Result) then Inc(Index);
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
