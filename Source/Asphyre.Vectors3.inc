//---------------------------------------------------------------------------
// Vectors3.inc
// Definitions and functions working with 3D vectors.
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
{ This type is used to pass @link(TVector3) by reference. }
 PVector3 = ^TVector3;

//---------------------------------------------------------------------------
{ 3D floating-point vector. }
 TVector3 = record
  { The coordinate in 3D space. }
  x, y, z: Single;

  {@exclude}class operator Add(const a, b: TVector3): TVector3;
  {@exclude}class operator Subtract(const a, b: TVector3): TVector3;
  {@exclude}class operator Multiply(const a, b: TVector3): TVector3;
  {@exclude}class operator Divide(const a, b: TVector3): TVector3;
  {@exclude}class operator Negative(const v: TVector3): TVector3;
  {@exclude}class operator Multiply(const v: TVector3;
   const k: Single): TVector3;
  {@exclude}class operator Divide(const v: TVector3;
   const k: Single): TVector3;
  {@exclude}class operator Multiply(const k: Single;
   const v: TVector3): TVector3;
  {@exclude}class operator Divide(const k: Single;
   const v: TVector3): TVector3;

  { Returns (x, y) portion of 3D vector as @link(TPoint2). }
  function GetXY(): TPoint2;

  { Returns (x, y) portion of 3D vector as @link(TTPoint2px) rounding values
    down to integers. }
  function GetXYpx(): TPoint2px;
 end;

//---------------------------------------------------------------------------
 TVectors3 = class;

//---------------------------------------------------------------------------
{@exclude}
 TVectors3Enumerator = class
 private
  {$ifdef DelphiNextGen}[weak]{$endif} List: TVectors3;
  Index: Integer;

  function GetCurrent(): TVector3;
 public
  property Current: TVector3 read GetCurrent;

  function MoveNext(): Boolean;
  constructor Create(const AList: TVectors3);
 end;

//---------------------------------------------------------------------------
{ A general-purpose list of 3D floating-point vectors. }
 TVectors3 = class
 private
  Data: array of TVector3;
  DataCount: Integer;

  procedure SetCount(const Value: Integer);
  function GetItem(Index: Integer): PVector3;
  procedure Request(Quantity: Integer);
 public
  { The total number of elements in the list. }
  property Count: Integer read DataCount write SetCount;

  { A direct access to each of the elements in the list. The first element has
    index of 0 and the last element is @link(Count) - 1. }
  property Items[Index: Integer]: PVector3 read GetItem; default;

  //.........................................................................
  { Finds the element given by the vector in the list and returns its index. }
  function IndexOf(const Vec: TVector3;
   CompareEpsilon: Single = 0.0001): Integer; overload;

  { Finds the element given by the coordinates in the list and returns its
    index. }
  function IndexOf(x, y, z: Single;
   CompareEpsilon: Single = 0.0001): Integer; overload;

  { Inserts the new vector to the list. }
  function Add(const v: TVector3): Integer; overload;

  { Inserts the vector with the specified coordinates to the list. }
  function Add(x, y, z: Single): Integer; overload;

  { Removes the specified element from the list. }
  procedure Remove(Index: Integer);

  { Removes all elements from the list. }
  procedure RemoveAll();

  { Copies the entire contents from the source list to this one. }
  procedure CopyFrom(const Source: TVectors3);

  { Adds all elements from the source list to this one. }
  procedure AddFrom(const Source: TVectors3);

  { Add elements from custom pointer location. }
  procedure AddFromPtr(Source: PVector3; ElementCount: Integer);

  { Normalizes all the vectors in the list to make them having unity length. }
  procedure Normalize();

  { Rescales all the vectors in the list by the specified coefficient. }
  procedure Rescale(const Scale: TVector3); overload;

  { Rescales all the vectors in the list by the specified coefficient. }
  procedure Rescale(Scale: Single); overload;

  { Inverts all the vectors in the list by pointing them into an opposite
    direction. }
  procedure Invert();

  { Assuming that the vectors in the list represent a 3D mesh, this method
    calculates the minimal and maximum boundaries and then translates the
    vertices so that the resulting mesh is centered around zero point. }
  procedure Centralize();

  {@exclude}function GetEnumerator(): TVectors3Enumerator;

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
const
{ Zero constant for @link(TVector3) that can be used as a parameter to some
  function and for vector initialization. }
 ZeroVec3: TVector3 = (x: 0.0; y: 0.0; z: 0.0);

//---------------------------------------------------------------------------
{ Special constant for @link(TVector3) that can be used as a parameter to some
  function and for vector initialization. This vector, however, contradictory
  to its name is actually not a unity vector in mathematical terms. }
 UnityVec3: TVector3 = (x: 1.0; y: 1.0; z: 1.0);

//---------------------------------------------------------------------------
{ Special constant for @link(TVector3) that defines X axis. }
 AxisXVec3: TVector3 = (x: 1.0; y: 0.0; z: 0.0);

//---------------------------------------------------------------------------
{ Special constant for @link(TVector3) that defines Y axis. }
 AxisYVec3: TVector3 = (x: 0.0; y: 1.0; z: 0.0);

//---------------------------------------------------------------------------
{ Special constant for @link(TVector3) that defines Z axis. }
 AxisZVec3: TVector3 = (x: 0.0; y: 0.0; z: 1.0);

//---------------------------------------------------------------------------
{ Creates a @link(TVector3) record using the specified coordinates. }
function Vector3(x, y, z: Single): TVector3; overload;

//---------------------------------------------------------------------------
{ Creates a @link(TVector3) record using 2D vector and specified Z coordinate. }
function Vector3(const p: TPoint2; z: Single): TVector3; overload;

//---------------------------------------------------------------------------
{ Returns the length of the specified 3D vector. }
function Length3(const v: TVector3): Single;

//---------------------------------------------------------------------------
{ Normalizes the specified 3D vector to unity length. The second parameter
  is used to prevent division by zero in vectors that are of zero length. }
function Norm3(const v: TVector3; ZeroAmpEpsilon: Single = 0.00001): TVector3;

//---------------------------------------------------------------------------
{ Interpolates between the specified two 3D vectors.
   @param(v0 The first vector to be used in the interpolation)
   @param(v1 The second vector to be used in the interpolation)
   @param(Alpha The mixture of the two vectors with the a range of [0..1].) }
function Lerp3(const v0, v1: TVector3; Alpha: Single): TVector3;

//---------------------------------------------------------------------------
{ Calculates the dot-product of the specified 3D vectors. The dot-product is
 an indirect measure of the angle between two vectors. }
function Dot3(const a, b: TVector3): Single;

//---------------------------------------------------------------------------
{ Calculates the cross-product of the specified 3D vectors. The resulting
  vector is perpendicular to both source vectors and normal to the plane
  containing them. }
function Cross3(const a, b: TVector3): TVector3;

//---------------------------------------------------------------------------
{ Calculates the angle between two 3D vectors. The returning value has range
  of [0..Pi]. }
function Angle3(const a, b: TVector3): Single;

//---------------------------------------------------------------------------
{ Calculates the portion of 3D vector "v" that is parallel to the vector "n". }
function Parallel3(const v, n: TVector3): TVector3;

//---------------------------------------------------------------------------
{ Calculates the portion of 3D vector "v" that is perpendicular to the
  vector "n". }
function Perp3(const v, n: TVector3): TVector3;

//---------------------------------------------------------------------------
{ Calculates 3D vector that is a reflection of vector "i" from surface given
  by the normal "n". }
function Reflect3(const i, n: TVector3): TVector3;

//---------------------------------------------------------------------------
{ Compares the two specified 3D vectors using the given threshold. }
function SameVec3(const a, b: TVector3; Epsilon: Single = 0.0001): Boolean;

//---------------------------------------------------------------------------
{ Converts Red, Green and Blue components of 32-bit color to X, Y and Z
  components of 3D vector accordingly. This can be useful for making
  calculations with the color as if it was a 3D vector. }
function ColorToVec3(Color: Cardinal): TVector3;

//---------------------------------------------------------------------------
{ Converts X, Y and Z components of 3D vector to Red, Green and Blue components
  of 32-bit color accordingly. The resulting color has Alpha value of 255. }
function Vec3ToColor(const v: TVector3): Cardinal;

//---------------------------------------------------------------------------
{ Returns a string that describes the source 3D vector with two decimal places
  precision; for example "(0.25, 0.31, 1.45)". }
function Vec3toString(const v: TVector3): string;

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
class operator TVector3.Add(const a, b: TVector3): TVector3;
begin
 Result.x:= a.x + b.x;
 Result.y:= a.y + b.y;
 Result.z:= a.z + b.z;
end;

//---------------------------------------------------------------------------
class operator TVector3.Subtract(const a, b: TVector3): TVector3;
begin
 Result.x:= a.x - b.x;
 Result.y:= a.y - b.y;
 Result.z:= a.z - b.z;
end;

//---------------------------------------------------------------------------
class operator TVector3.Multiply(const a, b: TVector3): TVector3;
begin
 Result.x:= a.x * b.x;
 Result.y:= a.y * b.y;
 Result.z:= a.z * b.z;
end;

//---------------------------------------------------------------------------
class operator TVector3.Divide(const a, b: TVector3): TVector3;
begin
 Result.x:= a.x / b.x;
 Result.y:= a.y / b.y;
 Result.z:= a.z / b.z;
end;

//---------------------------------------------------------------------------
class operator TVector3.Negative(const v: TVector3): TVector3;
begin
 Result.x:= -v.x;
 Result.y:= -v.y;
 Result.z:= -v.z;
end;

//---------------------------------------------------------------------------
class operator TVector3.Multiply(const v: TVector3;
 const k: Single): TVector3;
begin
 Result.x:= v.x * k;
 Result.y:= v.y * k;
 Result.z:= v.z * k;
end;

//---------------------------------------------------------------------------
class operator TVector3.Divide(const v: TVector3;
 const k: Single): TVector3;
begin
 Result.x:= v.x / k;
 Result.y:= v.y / k;
 Result.z:= v.z / k;
end;

//---------------------------------------------------------------------------
class operator TVector3.Multiply(const k: Single;
 const v: TVector3): TVector3;
begin
 Result.x:= k * v.x;
 Result.y:= k * v.y;
 Result.z:= k * v.z;
end;

//---------------------------------------------------------------------------
class operator TVector3.Divide(const k: Single;
 const v: TVector3): TVector3;
begin
 Result.x:= k / v.x;
 Result.y:= k / v.y;
 Result.z:= k / v.z;
end;

//---------------------------------------------------------------------------
function TVector3.GetXY(): TPoint2;
begin
 Result.x:= Self.x;
 Result.y:= Self.y;
end;

//---------------------------------------------------------------------------
function TVector3.GetXYpx(): TPoint2px;
begin
 Result.x:= Round(Self.x);
 Result.y:= Round(Self.y);
end;

//---------------------------------------------------------------------------
function Vector3(x, y, z: Single): TVector3;
begin
 Result.x:= x;
 Result.y:= y;
 Result.z:= z;
end;

//---------------------------------------------------------------------------
function Vector3(const p: TPoint2; z: Single): TVector3; overload;
begin
 Result.x:= p.x;
 Result.y:= p.y;
 Result.z:= z;
end;

//---------------------------------------------------------------------------
function Length3(const v: TVector3): Single;
begin
 Result:= Sqrt((v.x * v.x) + (v.y * v.y) + (v.z * v.z));
end;

//---------------------------------------------------------------------------
function Norm3(const v: TVector3; ZeroAmpEpsilon: Single = 0.00001): TVector3;
var
 Amp: Single;
begin
 Amp:= Length3(v);

 if (Abs(Amp) > ZeroAmpEpsilon) then
  begin
   Result.x:= v.x / Amp;
   Result.y:= v.y / Amp;
   Result.z:= v.z / Amp;
  end else Result:= ZeroVec3;
end;

//---------------------------------------------------------------------------
function Lerp3(const v0, v1: TVector3; Alpha: Single): TVector3;
begin
 Result.x:= v0.x + (v1.x - v0.x) * Alpha;
 Result.y:= v0.y + (v1.y - v0.y) * Alpha;
 Result.z:= v0.z + (v1.z - v0.z) * Alpha;
end;

//---------------------------------------------------------------------------
function Dot3(const a, b: TVector3): Single;
begin
 Result:= (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
end;

//---------------------------------------------------------------------------
function Cross3(const a, b: TVector3): TVector3;
begin
 Result.x:= (a.y * b.z) - (a.z * b.y);
 Result.y:= (a.z * b.x) - (a.x * b.z);
 Result.z:= (a.x * b.y) - (a.y * b.x);
end;

//---------------------------------------------------------------------------
function Angle3(const a, b: TVector3): Single;
var
 v: Single;
begin
 v:= Dot3(a, b) / (Length3(a) * Length3(b));

 if (v < -1.0) then v:= -1.0
  else if (v > 1.0) then v:= 1.0;

 Result:= ArcCos(v);
end;

//---------------------------------------------------------------------------
function Parallel3(const v, n: TVector3): TVector3;
begin
 Result:= n * (Dot3(v, n) / Sqr(Length3(n)));
end;

//--------------------------------------------------------------------------
function Perp3(const v, n: TVector3): TVector3;
begin
 Result:= v - Parallel3(v, n);
end;

//---------------------------------------------------------------------------
function Reflect3(const i, n: TVector3): TVector3;
begin
 Result:= i - 2.0 * n * Dot3(i, n);
end;

//---------------------------------------------------------------------------
function SameVec3(const a, b: TVector3; Epsilon: Single = 0.0001): Boolean;
begin
 Result:=
  (Abs(a.x - b.x) < Epsilon)and
  (Abs(a.y - b.y) < Epsilon)and
  (Abs(a.z - b.z) < Epsilon);
end;

//---------------------------------------------------------------------------
function ColorToVec3(Color: Cardinal): TVector3;
begin
 Result.x:= ((Color shl 8) shr 24) / 255.0;
 Result.y:= ((Color shl 16) shr 24) / 255.0;
 Result.z:= ((Color shl 24) shr 24) / 255.0;
end;

//---------------------------------------------------------------------------
function Vec3ToColor(const v: TVector3): Cardinal;
begin
 Result:= (Round(v.x * 255.0) shl 16) or (Round(v.y * 255.0) shl 8) or
  Round(v.z * 255.0) or $FF000000;
end;

//---------------------------------------------------------------------------
function Vec3toString(const v: TVector3): string;
begin
 Result:= Format('(%1.2f, %1.2f, %1.2f)', [v.x, v.y, v.z]);
end;

//---------------------------------------------------------------------------
constructor TVectors3.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TVectors3.Destroy();
begin
 Dec(AsphyreClassInstances);

 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TVectors3.SetCount(const Value: Integer);
begin
 Request(Value);
 DataCount:= Value;
end;

//---------------------------------------------------------------------------
function TVectors3.GetItem(Index: Integer): PVector3;
begin
 if (Index >= 0)and(Index < DataCount) then Result:= @Data[Index]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TVectors3.Request(Quantity: Integer);
var
 Required: Integer;
begin
 Required:= ((Quantity + CacheSize - 1) div CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TVectors3.Add(const v: TVector3): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Data[Index]:= v;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TVectors3.Add(x, y, z: Single): Integer;
begin
 Result:= Add(Vector3(x, y, z));
end;

//---------------------------------------------------------------------------
procedure TVectors3.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TVectors3.RemoveAll();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TVectors3.CopyFrom(const Source: TVectors3);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TVectors3.AddFrom(const Source: TVectors3);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//--------------------------------------------------------------------------
procedure TVectors3.AddFromPtr(Source: PVector3; ElementCount: Integer);
var
 i: Integer;
 InpVec: PVector3;
begin
 Request(DataCount + ElementCount);

 InpVec:= Source;

 for i:= 0 to ElementCount - 1 do
  begin
   Data[i + DataCount]:= InpVec^;
   Inc(InpVec);
  end;

 Inc(DataCount, ElementCount);
end;

//--------------------------------------------------------------------------
procedure TVectors3.Normalize();
var
 i: Integer;
begin
 for i:= 0 to DataCount - 1 do
  Data[i]:= Norm3(Data[i]);
end;

//---------------------------------------------------------------------------
procedure TVectors3.Rescale(const Scale: TVector3);
var
 i: Integer;
begin
 for i:= 0 to DataCount - 1 do
  Data[i]:= Data[i] * Scale;
end;

//--------------------------------------------------------------------------
procedure TVectors3.Rescale(Scale: Single);
var
 i: Integer;
begin
 for i:= 0 to DataCount - 1 do
  Data[i]:= Data[i] * Scale;
end;

//---------------------------------------------------------------------------
procedure TVectors3.Invert();
var
 i: Integer;
begin
 for i:= 0 to DataCount - 1 do
  Data[i]:= -Data[i];
end;

//--------------------------------------------------------------------------
procedure TVectors3.Centralize();
var
 i: Integer;
 MinPoint: TVector3;
 MaxPoint: TVector3;
 Middle  : TVector3;
begin
 if (DataCount < 1) then Exit;

 MinPoint:= Vector3(High(LongInt), High(LongInt), High(LongInt));
 MaxPoint:= Vector3(Low(LongInt), Low(LongInt), Low(LongInt));

 for i:= 0 to DataCount - 1 do
  begin
   MinPoint.x:= Min(MinPoint.x, Data[i].x);
   MinPoint.y:= Min(MinPoint.y, Data[i].y);
   MinPoint.z:= Min(MinPoint.z, Data[i].z);

   MaxPoint.x:= Max(MaxPoint.x, Data[i].x);
   MaxPoint.y:= Max(MaxPoint.y, Data[i].y);
   MaxPoint.z:= Max(MaxPoint.z, Data[i].z);
  end;

 Middle.x:= (MinPoint.x + MaxPoint.x) / 2.0;
 Middle.y:= (MinPoint.y + MaxPoint.y) / 2.0;
 Middle.z:= (MinPoint.z + MaxPoint.z) / 2.0;

 for i:= 0 to DataCount - 1 do
  Data[i]:= Data[i] - Middle;
end;

//---------------------------------------------------------------------------
function TVectors3.IndexOf(const Vec: TVector3;
 CompareEpsilon: Single = 0.0001): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to DataCount - 1 do
  if (Abs(Data[i].x - Vec.x) < CompareEpsilon)and
   (Abs(Data[i].y - Vec.y) < CompareEpsilon)and
   (Abs(Data[i].z - Vec.z) < CompareEpsilon) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TVectors3.IndexOf(x, y, z: Single;
 CompareEpsilon: Single = 0.0001): Integer;
begin
 Result:= IndexOf(Vector3(x, y, z), CompareEpsilon);
end;

//---------------------------------------------------------------------------
function TVectors3.GetEnumerator(): TVectors3Enumerator;
begin
 Result:= TVectors3Enumerator.Create(Self);
end;

//---------------------------------------------------------------------------
constructor TVectors3Enumerator.Create(const AList: TVectors3);
begin
 inherited Create();

 List := AList;
 Index:= -1;
end;

//---------------------------------------------------------------------------
function TVectors3Enumerator.GetCurrent(): TVector3;
begin
 Result:= List.Items[Index]^;
end;

//---------------------------------------------------------------------------
function TVectors3Enumerator.MoveNext(): Boolean;
begin
 Result:= Index < List.Count - 1;
 if (Result) then Inc(Index);
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
