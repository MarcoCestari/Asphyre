//---------------------------------------------------------------------------
// Matrices3.inc
// Definitions and functions working with 3x3 matrices.
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
{ This type is used to pass @link(TMatrix3) by reference. }
 PMatrix3 = ^TMatrix3;

//---------------------------------------------------------------------------
{ 3x3 transformation matrix. }
 TMatrix3 = record
  { Individual matrix values. }
  Data: array[0..2, 0..2] of Single;

  {@exclude}class operator Add(const a, b: TMatrix3): TMatrix3;
  {@exclude}class operator Subtract(const a, b: TMatrix3): TMatrix3;
  {@exclude}class operator Multiply(const a, b: TMatrix3): TMatrix3;
  {@exclude}class operator Multiply(const Mtx: TMatrix3;
   Theta: Single): TMatrix3;
  {@exclude}class operator Multiply(const v: TPoint2;
   const m: TMatrix3): TPoint2;
  {@exclude}class operator Divide(const Mtx: TMatrix3;
   Theta: Single): TMatrix3;
 end;

//---------------------------------------------------------------------------
const
{ 3x3 matrix values representing identity. This can be used either for matrix
  initialization or where no transformation should be applied. }
 IdentityMtx3: TMatrix3 = (Data: ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0),
  (0.0, 0.0, 1.0)));

//---------------------------------------------------------------------------
{ 3x3 matrix values containing zeros. This can be used in special occasions
  for matrix initialization or where no valid matrix exists. }
 ZeroMtx3: TMatrix3 = (Data: ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0),
  (0.0, 0.0, 0.0)));

//---------------------------------------------------------------------------
{ Transposes the given matrix. That is, the rows become columns and
  vice-versa. }
function TransposeMtx3(const Mtx: TMatrix3): TMatrix3;

//---------------------------------------------------------------------------
{ Creates 3x3 matrix containing 2D translation made using the specified
  offset. }
function TranslateMtx3(const Offset: TPoint2): TMatrix3;

//---------------------------------------------------------------------------
{ Creates 3x3 matrix containing 2D scaling made using the specified
  coefficient for both axes. }
function ScaleMtx3(const Coef: TPoint2): TMatrix3;

//---------------------------------------------------------------------------
{ Creates 3x3 matrix containing 2D rotation made using the specified
  angle (in radians). }
function RotateMtx3(Angle: Single): TMatrix3;

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
class operator TMatrix3.Add(const a, b: TMatrix3): TMatrix3;
var
 i, j: Integer;
begin
 for j:= 0 to 2 do
  for i:= 0 to 2 do
   Result.Data[j, i]:= a.Data[j, i] + b.Data[j, i];
end;

//---------------------------------------------------------------------------
class operator TMatrix3.Subtract(const a, b: TMatrix3): TMatrix3;
var
 i, j: Integer;
begin
 for j:= 0 to 2 do
  for i:= 0 to 2 do
   Result.Data[j, i]:= a.Data[j, i] - b.Data[j, i];
end;

//---------------------------------------------------------------------------
class operator TMatrix3.Multiply(const a, b: TMatrix3): TMatrix3;
var
 i, j: Integer;
begin
 for j:= 0 to 2 do
  for i:= 0 to 2 do
   Result.Data[j, i]:= (a.Data[j, 0] * b.Data[0, i]) +
    (a.Data[j, 1] * b.Data[1, i]) +
    (a.Data[j, 2] * b.Data[2, i]);
end;

//---------------------------------------------------------------------------
class operator TMatrix3.Multiply(const Mtx: TMatrix3;
 Theta: Single): TMatrix3;
var
 i, j: Integer;
begin
 for j:= 0 to 2 do
  for i:= 0 to 2 do
   Result.Data[j, i]:= Mtx.Data[j, i] * Theta;
end;

//---------------------------------------------------------------------------
class operator TMatrix3.Divide(const Mtx: TMatrix3;
 Theta: Single): TMatrix3;
var
 i, j: Integer;
begin
 for j:= 0 to 2 do
  for i:= 0 to 2 do
   Result.Data[j, i]:= Mtx.Data[j, i] / Theta;
end;

//---------------------------------------------------------------------------
class operator TMatrix3.Multiply(const v: TPoint2;
 const m: TMatrix3): TPoint2;
begin
 Result.x:= (v.x * m.Data[0, 0]) + (v.y * m.Data[1, 0]) + m.Data[2, 0];
 Result.y:= (v.x * m.Data[0, 1]) + (v.y * m.Data[1, 1]) + m.Data[2, 1];
end;

//--------------------------------------------------------------------------
function TransposeMtx3(const Mtx: TMatrix3): TMatrix3;
var
 i, j: Integer;
begin
 for i:= 0 to 2 do
  for j:= 0 to 2 do
   Result.Data[i, j]:= Mtx.Data[j, i];
end;

//---------------------------------------------------------------------------
function TranslateMtx3(const Offset: TPoint2): TMatrix3;
begin
 Result:= IdentityMtx3;
 Result.Data[2, 0]:= Offset.x;
 Result.Data[2, 1]:= Offset.y;
end;

//--------------------------------------------------------------------------
function ScaleMtx3(const Coef: TPoint2): TMatrix3;
begin
 Result:= IdentityMtx3;
 Result.Data[0, 0]:= Coef.x;
 Result.Data[1, 1]:= Coef.y;
end;

//--------------------------------------------------------------------------
function RotateMtx3(Angle: Single): TMatrix3;
begin
 Result:= IdentityMtx3;

 Result.Data[0, 0]:=  Cos(Angle);
 Result.Data[0, 1]:=  Sin(Angle);
 Result.Data[1, 0]:= -Result.Data[0, 1];
 Result.Data[1, 1]:=  Result.Data[0, 0];
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
