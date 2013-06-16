//---------------------------------------------------------------------------
// Vectors4.inc
// Definitions and functions working with 4D vectors.
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
{ This type is used to pass @link(TVector4) by reference. }
 PVector4 = ^TVector4;

//---------------------------------------------------------------------------
{ 4D (3D + w) floating-point vector. }
 TVector4 = record
  { The coordinate in 3D space. }
  x, y, z: Single;

  { Homogeneous transform coordinate, mostly used for perspective projection.
    Typically, this component is set to 1.0.  }
  w: Single;

  {@exclude}class operator Add(const a, b: TVector4): TVector4;
  {@exclude}class operator Subtract(const a, b: TVector4): TVector4;
  {@exclude}class operator Multiply(const a, b: TVector4): TVector4;
  {@exclude}class operator Divide(const a, b: TVector4): TVector4;
  {@exclude}class operator Negative(const v: TVector4): TVector4;
  {@exclude}class operator Multiply(const v: TVector4;
   const k: Single): TVector4;
  {@exclude}class operator Divide(const v: TVector4;
   const k: Single): TVector4;
  {@exclude}class operator Multiply(const v: TVector4;
   const m: TMatrix4): TVector4;

  { Returns (x, y, z) portion of 4D vector. }
  function GetXYZ(): TVector3;
 end;

//---------------------------------------------------------------------------
 TVectors4 = class;

//---------------------------------------------------------------------------
{@exclude}
 TVectors4Enumerator = class
 private
  {$ifdef DelphiNextGen}[weak]{$endif} List: TVectors4;
  Index: Integer;

  function GetCurrent(): TVector4;
 public
  property Current: TVector4 read GetCurrent;

  function MoveNext(): Boolean;
  constructor Create(const AList: TVectors4);
 end;

//---------------------------------------------------------------------------
{ A general-purpose list of 4D (3D + w) floating-point vectors. }
 TVectors4 = class
 private
  Data: array of TVector4;
  DataCount: Integer;

  function GetMemAddr(): Pointer;
  procedure SetCount(const Value: Integer);
  procedure Request(Amount: Integer);
  function GetItem(Index: Integer): PVector4;
 public
  {@exclude}property MemAddr: Pointer read GetMemAddr;

  { The total number of elements in the list. }
  property Count: Integer read DataCount write SetCount;

  { A direct access to each of the elements in the list. The first element has
    index of 0 and the last element is @link(Count) - 1. }
  property Items[Index: Integer]: PVector4 read GetItem; default;

  //.........................................................................
  { Inserts the new vector to the list. }
  function Add(const v: TVector4): Integer; overload;

  { Inserts the vector with the specified coordinates to the list. }
  function Add(x, y, z: Single; w: Single = 1.0): Integer; overload;

  { Removes the specified element from the list. }
  procedure Remove(Index: Integer);

  { Removes all elements from the list. }
  procedure RemoveAll();

  { Copies the entire contents from the source list to this one. }
  procedure CopyFrom(const Source: TVectors4);

  { Adds all elements from the source list to this one. }
  procedure AddFrom(const Source: TVectors4);

  { Copies 3D vectors from source list, transforming them by the given matrix. }
  procedure CopyTransform(const Source: TVectors3; const Matrix: TMatrix4;
   AssumeW: Single = 1.0); overload;

  { Copies 4D vectors from source list, transforming them by the given matrix. }
  procedure CopyTransform(const Source: TVectors4; const Matrix: TMatrix4); overload;

  { Adds 3D vectors from source list, transforming them by the given matrix. }
  procedure AddTransform(const Source: TVectors3; const Matrix: TMatrix4;
   AssumeW: Single = 1.0); overload;

  { Adds 4D vectors from source list, transforming them by the given matrix. }
  procedure AddTransform(const Source: TVectors4; const Matrix: TMatrix4); overload;

  {@exclude}function GetEnumerator(): TVectors4Enumerator;

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
const
{ Zero constant for @link(TVector4) that can be used as a parameter to some
  function and for vector initialization. In this case, homogeneous is set
  to zero. }
 ZeroVec4: TVector4 = (x: 0.0; y: 0.0; z: 0.0; w: 0.0);

//---------------------------------------------------------------------------
{ Zero constant for @link(TVector4) that can be used as a parameter to some
  function and for vector initialization. In this case, homogeneous is set
  to one. }
 ZeroVec4H: TVector4 = (x: 0.0; y: 0.0; z: 0.0; w: 1.0);

//---------------------------------------------------------------------------
{ Special constant for @link(TVector4) that can be used as a parameter to some
  function and for vector initialization. This vector, however, contradictory
  to its name is actually not a unity vector in mathematical terms. }
 UnityVec4: TVector4 = (x: 1.0; y: 1.0; z: 1.0; w: 1.0);

//---------------------------------------------------------------------------
{ Special constant for @link(TVector4) that defines X axis. }
 AxisXVec4: TVector4 = (x: 1.0; y: 0.0; z: 0.0; w: 1.0);

//---------------------------------------------------------------------------
{ Special constant for @link(TVector4) that defines Y axis. }
 AxisYVec4: TVector4 = (x: 0.0; y: 1.0; z: 0.0; w: 1.0);

//---------------------------------------------------------------------------
{ Special constant for @link(TVector4) that defines Z axis. }
 AxisZVec4: TVector4 = (x: 0.0; y: 0.0; z: 1.0; w: 1.0);

//---------------------------------------------------------------------------
{ Creates a @link(TVector4) record using the specified X, Y, Z and W
  coordinates. }
function Vector4(x, y, z: Single; w: Single = 1.0): TVector4; overload;

//---------------------------------------------------------------------------
{ Creates a @link(TVector4) record using the specified 3D vector and W
  coordinate. }
function Vector4(const v: TVector3; w: Single = 1.0): TVector4; overload;

//---------------------------------------------------------------------------
{ Returns the length of the specified 4D vector. }
function Length4(const v: TVector4): Single;

//---------------------------------------------------------------------------
{ Normalizes the specified 4D vector to unity length. The second parameter
  is used to prevent division by zero in vectors that are of zero length. }
function Norm4(const v: TVector4; ZeroAmpEpsilon: Single = 0.00001): TVector4;

//---------------------------------------------------------------------------
{ Interpolates between the specified two 4D vectors.
   @param(v0 The first vector to be used in the interpolation)
   @param(v1 The second vector to be used in the interpolation)
   @param(Alpha The mixture of the two vectors with the a range of [0..1].) }
function Lerp4(const v0, v1: TVector4; Alpha: Single): TVector4;

//---------------------------------------------------------------------------
{ Converts Red, Green, Blue and Alpha components of 32-bit color to X, Y, Z
  and W components of 4D vector accordingly. This can be useful for making
  calculations with the color as if it was a 4D vector. }
function ColorToVec4(Color: Cardinal): TVector4;

//---------------------------------------------------------------------------
{ Converts X, Y, Z and W components of 4D vector to Red, Green, Blue and Alpha
  components of 32-bit color accordingly. }
function Vec4ToColor(const v: TVector4): Cardinal;

//---------------------------------------------------------------------------
{ Compares all of the components from the given two vectors to see whether
  they are within the specified threshold. }
function SameVec4(const a, b: TVector4; Epsilon: Single = 0.0001): Boolean;

//---------------------------------------------------------------------------
{ Converts 4D vector to 3D vector, projecting it (dividing by W). }
function Vec4To3Proj(const v: TVector4): TVector3;

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
class operator TVector4.Add(const a, b: TVector4): TVector4;
begin
 Result.x:= a.x + b.x;
 Result.y:= a.y + b.y;
 Result.z:= a.z + b.z;
 Result.w:= a.w + b.w;
end;

//---------------------------------------------------------------------------
class operator TVector4.Subtract(const a, b: TVector4): TVector4;
begin
 Result.x:= a.x - b.x;
 Result.y:= a.y - b.y;
 Result.z:= a.z - b.z;
 Result.w:= a.w - b.w;
end;

//---------------------------------------------------------------------------
class operator TVector4.Multiply(const a, b: TVector4): TVector4;
begin
 Result.x:= a.x * b.x;
 Result.y:= a.y * b.y;
 Result.z:= a.z * b.z;
 Result.w:= a.w * b.w;
end;

//---------------------------------------------------------------------------
class operator TVector4.Divide(const a, b: TVector4): TVector4;
begin
 Result.x:= a.x / b.x;
 Result.y:= a.y / b.y;
 Result.z:= a.z / b.z;
 Result.w:= a.w / b.w;
end;

//---------------------------------------------------------------------------
class operator TVector4.Negative(const v: TVector4): TVector4;
begin
 Result.x:= -v.x;
 Result.y:= -v.y;
 Result.z:= -v.z;
 Result.w:= -v.w;
end;

//---------------------------------------------------------------------------
class operator TVector4.Multiply(const v: TVector4;
 const k: Single): TVector4;
begin
 Result.x:= v.x * k;
 Result.y:= v.y * k;
 Result.z:= v.z * k;
 Result.w:= v.w * k;
end;

//---------------------------------------------------------------------------
class operator TVector4.Divide(const v: TVector4;
 const k: Single): TVector4;
begin
 Result.x:= v.x / k;
 Result.y:= v.y / k;
 Result.z:= v.z / k;
 Result.w:= v.w / k;
end;

//---------------------------------------------------------------------------
class operator TVector4.Multiply(const v: TVector4;
 const m: TMatrix4): TVector4;
begin
 Result.x:= (v.x * m.Data[0, 0]) + (v.y * m.Data[1, 0]) +
  (v.z * m.Data[2, 0]) + (v.w * m.Data[3, 0]);
 Result.y:= (v.x * m.Data[0, 1]) + (v.y * m.Data[1, 1]) +
  (v.z * m.Data[2, 1]) + (v.w * m.Data[3, 1]);
 Result.z:= (v.x * m.Data[0, 2]) + (v.y * m.Data[1, 2]) +
  (v.z * m.Data[2, 2]) + (v.w * m.Data[3, 2]);
 Result.w:= (v.x * m.Data[0, 3]) + (v.y * m.Data[1, 3]) +
  (v.z * m.Data[2, 3]) + (v.w * m.Data[3, 3]);
end;

//---------------------------------------------------------------------------
function TVector4.GetXYZ(): TVector3;
begin
 Result.x:= Self.x;
 Result.y:= Self.y;
 Result.z:= Self.z;
end;

//---------------------------------------------------------------------------
function Vector4(x, y, z: Single; w: Single = 1.0): TVector4;
begin
 Result.x:= x;
 Result.y:= y;
 Result.z:= z;
 Result.w:= w;
end;

//---------------------------------------------------------------------------
function Vector4(const v: TVector3; w: Single = 1.0): TVector4; overload;
begin
 Result.x:= v.x;
 Result.y:= v.y;
 Result.z:= v.z;
 Result.w:= w;
end;

//---------------------------------------------------------------------------
function Length4(const v: TVector4): Single;
begin
 Result:= Sqrt((v.x * v.x) + (v.y * v.y) + (v.z * v.z) + (v.w * v.w));
end;

//---------------------------------------------------------------------------
function Norm4(const v: TVector4; ZeroAmpEpsilon: Single = 0.00001): TVector4;
var
 Amp: Single;
begin
 Amp:= Length4(v);

 if (Abs(Amp) > ZeroAmpEpsilon) then
  begin
   Result.x:= v.x / Amp;
   Result.y:= v.y / Amp;
   Result.z:= v.z / Amp;
   Result.w:= v.w / Amp;
  end else Result:= ZeroVec4;
end;

//---------------------------------------------------------------------------
function Lerp4(const v0, v1: TVector4; Alpha: Single): TVector4;
begin
 Result.x:= v0.x + (v1.x - v0.x) * Alpha;
 Result.y:= v0.y + (v1.y - v0.y) * Alpha;
 Result.z:= v0.z + (v1.z - v0.z) * Alpha;
 Result.w:= v0.w + (v1.w - v0.w) * Alpha;
end;

//---------------------------------------------------------------------------
function ColorToVec4(Color: Cardinal): TVector4;
begin
 Result.x:= ((Color shl 8) shr 24) / 255.0;
 Result.y:= ((Color shl 16) shr 24) / 255.0;
 Result.z:= ((Color shl 24) shr 24) / 255.0;
 Result.w:= (Color shr 24) / 255.0;
end;

//---------------------------------------------------------------------------
function Vec4ToColor(const v: TVector4): Cardinal;
begin
 Result:= (Round(v.x * 255.0) shl 16) or (Round(v.y * 255.0) shl 8) or
  Round(v.z * 255.0) or (Round(v.w * 255.0) shl 24);
end;

//---------------------------------------------------------------------------
function Vec4To3Proj(const v: TVector4): TVector3;
begin
 Result.x:= v.x / v.w;
 Result.y:= v.y / v.w;
 Result.z:= v.z / v.w;
end;

//---------------------------------------------------------------------------
function SameVec4(const a, b: TVector4; Epsilon: Single = 0.0001): Boolean;
begin
 Result:=
  (Abs(a.x - b.x) < Epsilon)and
  (Abs(a.y - b.y) < Epsilon)and
  (Abs(a.z - b.z) < Epsilon)and
  (Abs(a.w - b.w) < Epsilon);
end;

//---------------------------------------------------------------------------
constructor TVectors4.Create();
begin
 inherited;

{$ifndef fpc}
 Inc(AsphyreClassInstances);
{$endif}

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TVectors4.Destroy();
begin
{$ifndef fpc}
 Dec(AsphyreClassInstances);
{$endif}

 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TVectors4.GetMemAddr(): Pointer;
begin
 Result:= nil;
 if (DataCount > 0) then Result:= @Data[0];
end;

//---------------------------------------------------------------------------
procedure TVectors4.SetCount(const Value: Integer);
begin
 Request(Value);
 DataCount:= Value;
end;

//---------------------------------------------------------------------------
procedure TVectors4.Request(Amount: Integer);
var
 Required: Integer;
begin
 Required:= ((Amount + CacheSize - 1) div CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TVectors4.GetItem(Index: Integer): PVector4;
begin
 if (Index >= 0)and(Index < DataCount) then Result:= @Data[Index]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
function TVectors4.Add(const v: TVector4): Integer;
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
function TVectors4.Add(x, y, z: Single; w: Single = 1.0): Integer;
begin
 Result:= Add(Vector4(x, y, z, w));
end;

//---------------------------------------------------------------------------
procedure TVectors4.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TVectors4.RemoveAll();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TVectors4.CopyFrom(const Source: TVectors4);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TVectors4.AddFrom(const Source: TVectors4);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
procedure TVectors4.CopyTransform(const Source: TVectors3; 
 const Matrix: TMatrix4; AssumeW: Single);
var
 i: Integer;
begin
 Request(Source.Count);

 for i:= 0 to Source.Count - 1 do
  Data[i]:= Vector4(Source[i]^, AssumeW) * Matrix;

 DataCount:= Source.Count;
end;

//---------------------------------------------------------------------------
procedure TVectors4.CopyTransform(const Source: TVectors4; 
 const Matrix: TMatrix4);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i] * Matrix;

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TVectors4.AddTransform(const Source: TVectors3; 
 const Matrix: TMatrix4; AssumeW: Single);
var
 i: Integer;
begin
 Request(DataCount + Source.Count);

 for i:= 0 to Source.Count - 1 do
  Data[i + DataCount]:= Vector4(Source[i]^, AssumeW) * Matrix;

 Inc(DataCount, Source.Count);
end;

//---------------------------------------------------------------------------
procedure TVectors4.AddTransform(const Source: TVectors4; 
 const Matrix: TMatrix4);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i] * Matrix;

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
function TVectors4.GetEnumerator(): TVectors4Enumerator;
begin
 Result:= TVectors4Enumerator.Create(Self);
end;

//---------------------------------------------------------------------------
constructor TVectors4Enumerator.Create(const AList: TVectors4);
begin
 inherited Create();

 List := AList;
 Index:= -1;
end;

//---------------------------------------------------------------------------
function TVectors4Enumerator.GetCurrent(): TVector4;
begin
 Result:= List.Items[Index]^;
end;

//---------------------------------------------------------------------------
function TVectors4Enumerator.MoveNext(): Boolean;
begin
 Result:= Index < List.Count - 1;
 if (Result) then Inc(Index);
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
