//---------------------------------------------------------------------------
// Matrices4.inc
// Definitions and functions working with 3D 4x4 matrices
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
{ This type is used to pass @link(TMatrix4) by reference. }
 PMatrix4 = ^TMatrix4;

//---------------------------------------------------------------------------
{ 4x4 transformation matrix. }
 TMatrix4 = record
  { Individual matrix values. }
  Data: array[0..3, 0..3] of Single;

  {@exclude}class operator Add(const a, b: TMatrix4): TMatrix4;
  {@exclude}class operator Subtract(const a, b: TMatrix4): TMatrix4;
  {@exclude}class operator Multiply(const a, b: TMatrix4): TMatrix4;
  {@exclude}class operator Multiply(const Mtx: TMatrix4;
   Theta: Single): TMatrix4;
  {@exclude}class operator Divide(const Mtx: TMatrix4;
   Theta: Single): TMatrix4;
  {@exclude}class operator Multiply(const v: TVector3;
   const m: TMatrix4): TVector3;
 end;

//---------------------------------------------------------------------------
const
{ 4x4 matrix values representing identity. This can be used either for matrix
  initialization or where no transformation should be applied. }
 IdentityMtx4: TMatrix4 = (Data: ((1.0, 0.0, 0.0, 0.0), (0.0, 1.0, 0.0, 0.0),
  (0.0, 0.0, 1.0, 0.0), (0.0, 0.0, 0.0, 1.0)));

//---------------------------------------------------------------------------
{ 4x4 matrix values containing zeros. This can be used in special occasions for
  matrix initialization or where no valid matrix exists. }
 ZeroMtx4: TMatrix4 = (Data: ((0.0, 0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 0.0),
  (0.0, 0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 0.0)));

//---------------------------------------------------------------------------
{ Transposes the given matrix. That is, the rows become columns and
  vice-versa. }
function TransposeMtx4(const Mtx: TMatrix4): TMatrix4;

//---------------------------------------------------------------------------
{ Calculates the inverse of the matrix. The resulting matrix, in other words,
  is the transformation that can be applied to a 3D vector to undo the
  transformation applied previously. }
function InvertMtx4(const m: TMatrix4): TMatrix4;

//---------------------------------------------------------------------------
{ Creates 4x4 matrix containing 3D translation made using the specified vector
  offset. }
function TranslateMtx4(const Offset: TVector3): TMatrix4;

//---------------------------------------------------------------------------
{ Creates 4x4 matrix containing 3D scaling made using the specified vector
  coefficient for the axes. }
function ScaleMtx4(const Coef: TVector3): TMatrix4;

//---------------------------------------------------------------------------
{ Returns textual representation of the matrix. This is mainly suited for
  debugging purposes to see that the matrix is defined properly. }
function StringMtx4(const m: TMatrix4): string;

//---------------------------------------------------------------------------
{ Creates 4x4 matrix containing 3D rotation along X matrix using the specified
  angle (in radians). }
function RotateXMtx4(Angle: Single): TMatrix4;

//---------------------------------------------------------------------------
{ Creates 4x4 matrix containing 3D rotation along Y matrix using the specified
  angle (in radians). }
function RotateYMtx4(Angle: Single): TMatrix4;

//---------------------------------------------------------------------------
{ Creates 4x4 matrix containing 3D rotation along Z matrix using the specified
  angle (in radians). }
function RotateZMtx4(Angle: Single): TMatrix4;

//---------------------------------------------------------------------------
{ Creates 4x4 matrix containing 3D rotation along an arbitrary axis defined by
  the given vector and the specified angle (in radians). }
function RotateMtx4(const Axis: TVector3; Angle: Single): TMatrix4;

//---------------------------------------------------------------------------
{ Creates a reflection matrix specified by the given vector defining the
  orientation of the reflection. }
function ReflectMtx4(const Axis: TVector3): TMatrix4;

//---------------------------------------------------------------------------
{ Creates a view matrix that is defined by the camera's position, its target
  and the defined vertical axis or so-called "roof". }
function LookAtMtx4(const Origin, Target, Roof: TVector3): TMatrix4;

//---------------------------------------------------------------------------
{ Creates perspective projection matrix defined by a field of view on Y axis.
  This is a common way for typical 3D applications. In 3D shooters special care
  is to be taken because on wide-screen monitors the visible area will be
  bigger. The parameters that define the viewed range are important for
  defining the precision of the depth transformation or a depth-buffer.
   @param(FieldOfView The camera's field of view in radians. For example Pi/4.)
   @param(AspectRatio The screen's aspect ratio. Can be calculated as y/x.)
   @param(MinRange The closest range at which the scene will be viewed.)
   @param(MaxRange The farthest range at which the scene will be viewed.) }
function PerspectiveFOVYMtx4(FieldOfView, AspectRatio, MinRange,
 MaxRange: Single): TMatrix4;

//---------------------------------------------------------------------------
{ Creates perspective projection matrix defined by a field of view on X axis.
  In 3D shooters the field of view needs to be adjusted to allow more visible
  area on wide-screen monitors. The parameters that define the viewed range are
  important for defining the precision of the depth transformation or a
  depth-buffer.
   @param(FieldOfView The camera's field of view in radians. For example Pi/4.)
   @param(AspectRatio The screen's aspect ratio. Can be calculated as x/y.)
   @param(MinRange The closest range at which the scene will be viewed.)
   @param(MaxRange The farthest range at which the scene will be viewed.) }
function PerspectiveFOVXMtx4(FieldOfView, AspectRatio, MinRange,
 MaxRange: Single): TMatrix4;

//---------------------------------------------------------------------------
{ Creates perspective projection matrix defined by the viewing volume in 3D
  space. }
function PerspectiveVOLMtx4(Width, Height, MinRange,
 MaxRange: Single): TMatrix4;

//---------------------------------------------------------------------------
{ Creates perspective projection matrix defined by the individual axis's
  boundaries. }
function PerspectiveBDSMtx4(Left, Right, Top, Bottom, MinRange,
 MaxRange: Single): TMatrix4;

//---------------------------------------------------------------------------
{ Creates orthogonal projection matrix defined by the viewing volume in 3D
  space. }
function OrthogonalVOLMtx4(Width, Height, MinRange,
 MaxRange: Single): TMatrix4;

//---------------------------------------------------------------------------
{ Creates orthogonal projection matrix defined by the individual axis's
  boundaries. }
function OrthogonalBDSMtx4(Left, Right, Top, Bottom, MinRange,
 MaxRange: Single): TMatrix4;

//---------------------------------------------------------------------------
{ Creates 4x4 matrix containing 3D rotation based on parameters similar to
  flight dynamics, specifically heading, pitch and Bank. Each of the components
  is specified individually. }
function HeadingPitchBankMtx4(Heading, Pitch,
 Bank: Single): TMatrix4; overload;

//---------------------------------------------------------------------------
{ Creates 4x4 matrix containing 3D rotation based on parameters similar to
  flight dynamics, specifically heading, pitch and bank. The components are
  taken from the specified vector with Y corresponding to heading, X to pitch
  and Z to bank. }
function HeadingPitchBankMtx4(const v: TVector3): TMatrix4; overload;

//---------------------------------------------------------------------------
{ Creates 4x4 matrix containing 3D rotation based on parameters similar to
  flight dynamics, specifically yaw, pitch and roll. Each of the components
  is specified individually. }
function YawPitchRollMtx4(Yaw, Pitch, Roll: Single): TMatrix4; overload;

//---------------------------------------------------------------------------
{ Creates 4x4 matrix containing 3D rotation based on parameters similar to
  flight dynamics, specifically yaw, pitch and roll. The components are
  taken from the specified vector with Y corresponding to yaw, X to pitch
  and Z to roll. }
function YawPitchRollMtx4(const v: TVector3): TMatrix4; overload;

//---------------------------------------------------------------------------
{ Assuming that the specified matrix is a view matrix, this method calculates
  the 3D position where the camera (or "eye") is supposedly located. }
function GetEyePos4(const m: TMatrix4): TVector3;

//---------------------------------------------------------------------------
{ Assuming that the specified matrix is a world matrix, this method calculates
  the 3D position where the object or world is supposedly located. }
function GetWorldPos4(const m: TMatrix4): TVector3;

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
class operator TMatrix4.Add(const a, b: TMatrix4): TMatrix4;
var
 i, j: Integer;
begin
 for j:= 0 to 3 do
  for i:= 0 to 3 do
   Result.Data[j, i]:= a.Data[j, i] + b.Data[j, i];
end;

//---------------------------------------------------------------------------
class operator TMatrix4.Subtract(const a, b: TMatrix4): TMatrix4;
var
 i, j: Integer;
begin
 for j:= 0 to 3 do
  for i:= 0 to 3 do
   Result.Data[j, i]:= a.Data[j, i] - b.Data[j, i];
end;

//---------------------------------------------------------------------------
class operator TMatrix4.Multiply(const a, b: TMatrix4): TMatrix4;
var
 i, j: Integer;
begin
 for j:= 0 to 3 do
  for i:= 0 to 3 do
   Result.Data[j, i]:= (a.Data[j, 0] * b.Data[0, i]) +
    (a.Data[j, 1] * b.Data[1, i]) +
    (a.Data[j, 2] * b.Data[2, i]) +
    (a.Data[j, 3] * b.Data[3, i]);
end;

//---------------------------------------------------------------------------
class operator TMatrix4.Multiply(const Mtx: TMatrix4;
 Theta: Single): TMatrix4;
var
 i, j: Integer;
begin
 for j:= 0 to 3 do
  for i:= 0 to 3 do
   Result.Data[j, i]:= Mtx.Data[j, i] * Theta;
end;

//---------------------------------------------------------------------------
class operator TMatrix4.Divide(const Mtx: TMatrix4;
 Theta: Single): TMatrix4;
var
 i, j: Integer;
begin
 for j:= 0 to 3 do
  for i:= 0 to 3 do
   Result.Data[j, i]:= Mtx.Data[j, i] / Theta;
end;

//---------------------------------------------------------------------------
class operator TMatrix4.Multiply(const v: TVector3;
 const m: TMatrix4): TVector3;
begin
 Result.x:= (v.x * m.Data[0, 0]) + (v.y * m.Data[1, 0]) +
  (v.z * m.Data[2, 0]) + m.Data[3, 0];
 Result.y:= (v.x * m.Data[0, 1]) + (v.y * m.Data[1, 1]) +
  (v.z * m.Data[2, 1]) + m.Data[3, 1];
 Result.z:= (v.x * m.Data[0, 2]) + (v.y * m.Data[1, 2]) +
 (v.z * m.Data[2, 2]) + m.Data[3, 2];
end;

//---------------------------------------------------------------------------
function StringMtx4(const m: TMatrix4): string;
var
 s: string;
 i, j: Integer;
begin
 s:= '{';
 for i:= 0 to 3 do
  begin
   s:= s + '(';
   for j:= 0 to 3 do
    begin
     s:= s + Format('%1.2f', [m.Data[i, j]]);
     if (j < 3) then s:= s + ', ';
    end;
   s:= s + ')';
   if (i < 3) then s:= s + #13#10;
  end;
 Result:= s + '}';
end;

//--------------------------------------------------------------------------
function TransposeMtx4(const Mtx: TMatrix4): TMatrix4;
var
 i, j: Integer;
begin
 for i:= 0 to 3 do
  for j:= 0 to 3 do
   Result.Data[i, j]:= Mtx.Data[j, i];
end;

//---------------------------------------------------------------------------
function TranslateMtx4(const Offset: TVector3): TMatrix4;
begin
 Result:= IdentityMtx4;
 Result.Data[3, 0]:= Offset.x;
 Result.Data[3, 1]:= Offset.y;
 Result.Data[3, 2]:= Offset.z;
end;

//--------------------------------------------------------------------------
function ScaleMtx4(const Coef: TVector3): TMatrix4;
begin
 Result:= IdentityMtx4;
 Result.Data[0, 0]:= Coef.x;
 Result.Data[1, 1]:= Coef.y;
 Result.Data[2, 2]:= Coef.z;
end;

//---------------------------------------------------------------------------
function DetMtx3(a1, a2, a3, b1, b2, b3, c1, c2,
 c3: Single): Single;
begin
 Result:= a1 * (b2 * c3 - b3 * c2) - b1 * (a2 * c3 - a3 * c2) +
  c1 * (a2 * b3 - a3 * b2);
end;

//---------------------------------------------------------------------------
function AdjointMtx4(const m: TMatrix4): TMatrix4;
begin
 Result.Data[0, 0]:=  DetMtx3(m.Data[1, 1], m.Data[2, 1], m.Data[3, 1],
  m.Data[1, 2], m.Data[2, 2], m.Data[3, 2], m.Data[1, 3], m.Data[2, 3],
  m.Data[3, 3]);
 Result.Data[1, 0]:= -DetMtx3(m.Data[1, 0], m.Data[2, 0], m.Data[3, 0],
  m.Data[1, 2], m.Data[2, 2], m.Data[3, 2], m.Data[1, 3], m.Data[2, 3],
  m.Data[3, 3]);
 Result.Data[2, 0]:=  DetMtx3(m.Data[1, 0], m.Data[2, 0], m.Data[3, 0],
  m.Data[1, 1], m.Data[2, 1], m.Data[3, 1], m.Data[1, 3], m.Data[2, 3],
  m.Data[3, 3]);
 Result.Data[3, 0]:= -DetMtx3(m.Data[1, 0], m.Data[2, 0], m.Data[3, 0],
  m.Data[1, 1], m.Data[2, 1], m.Data[3, 1], m.Data[1, 2], m.Data[2, 2],
  m.Data[3, 2]);

 Result.Data[0, 1]:= -DetMtx3(m.Data[0, 1], m.Data[2, 1], m.Data[3, 1],
  m.Data[0, 2], m.Data[2, 2], m.Data[3, 2], m.Data[0, 3], m.Data[2, 3],
  m.Data[3, 3]);
 Result.Data[1, 1]:=  DetMtx3(m.Data[0, 0], m.Data[2, 0], m.Data[3, 0],
  m.Data[0, 2], m.Data[2, 2], m.Data[3, 2], m.Data[0, 3], m.Data[2, 3],
  m.Data[3, 3]);
 Result.Data[2, 1]:= -DetMtx3(m.Data[0, 0], m.Data[2, 0], m.Data[3, 0],
  m.Data[0, 1], m.Data[2, 1], m.Data[3, 1], m.Data[0, 3], m.Data[2, 3],
  m.Data[3, 3]);
 Result.Data[3, 1]:=  DetMtx3(m.Data[0, 0], m.Data[2, 0], m.Data[3, 0],
  m.Data[0, 1], m.Data[2, 1], m.Data[3, 1], m.Data[0, 2], m.Data[2, 2],
  m.Data[3, 2]);

 Result.Data[0, 2]:=  DetMtx3(m.Data[0, 1], m.Data[1, 1], m.Data[3, 1],
  m.Data[0, 2], m.Data[1, 2], m.Data[3, 2], m.Data[0, 3], m.Data[1, 3],
  m.Data[3, 3]);
 Result.Data[1, 2]:= -DetMtx3(m.Data[0, 0], m.Data[1, 0], m.Data[3, 0],
  m.Data[0, 2], m.Data[1, 2], m.Data[3, 2], m.Data[0, 3], m.Data[1, 3],
  m.Data[3, 3]);
 Result.Data[2, 2]:=  DetMtx3(m.Data[0, 0], m.Data[1, 0], m.Data[3, 0],
  m.Data[0, 1], m.Data[1, 1], m.Data[3, 1], m.Data[0, 3], m.Data[1, 3],
  m.Data[3, 3]);
 Result.Data[3, 2]:= -DetMtx3(m.Data[0, 0], m.Data[1, 0], m.Data[3, 0],
  m.Data[0, 1], m.Data[1, 1], m.Data[3, 1], m.Data[0, 2], m.Data[1, 2],
  m.Data[3, 2]);

 Result.Data[0, 3]:= -DetMtx3(m.Data[0, 1], m.Data[1, 1], m.Data[2, 1],
  m.Data[0, 2], m.Data[1, 2], m.Data[2, 2], m.Data[0, 3], m.Data[1, 3],
  m.Data[2, 3]);
 Result.Data[1, 3]:=  DetMtx3(m.Data[0, 0], m.Data[1, 0], m.Data[2, 0],
  m.Data[0, 2], m.Data[1, 2], m.Data[2, 2], m.Data[0, 3], m.Data[1, 3],
  m.Data[2, 3]);
 Result.Data[2, 3]:= -DetMtx3(m.Data[0, 0], m.Data[1, 0], m.Data[2, 0],
  m.Data[0, 1], m.Data[1, 1], m.Data[2, 1], m.Data[0, 3], m.Data[1, 3],
  m.Data[2, 3]);
 Result.Data[3, 3]:=  DetMtx3(m.Data[0, 0], m.Data[1, 0], m.Data[2, 0],
  m.Data[0, 1], m.Data[1, 1], m.Data[2, 1], m.Data[0, 2], m.Data[1, 2],
  m.Data[2, 2]);
end;

//---------------------------------------------------------------------------
function DetMtx4(const m: TMatrix4): Single;
begin
 Result:= m.Data[0, 0] * DetMtx3(m.Data[1, 1], m.Data[2, 1], m.Data[3, 1],
  m.Data[1, 2], m.Data[2, 2], m.Data[3, 2], m.Data[1, 3], m.Data[2, 3],
  m.Data[3, 3]) - m.Data[0, 1] * DetMtx3(m.Data[1, 0], m.Data[2, 0],
  m.Data[3, 0], m.Data[1, 2], m.Data[2, 2], m.Data[3, 2], m.Data[1, 3],
  m.Data[2, 3], m.Data[3, 3]) + m.Data[0, 2] * DetMtx3(m.Data[1, 0],
  m.Data[2, 0], m.Data[3, 0], m.Data[1, 1], m.Data[2, 1], m.Data[3, 1],
  m.Data[1, 3], m.Data[2, 3], m.Data[3, 3]) - m.Data[0, 3] *
  DetMtx3(m.Data[1, 0], m.Data[2, 0], m.Data[3, 0], m.Data[1, 1],
  m.Data[2, 1], m.Data[3, 1], m.Data[1, 2], m.Data[2, 2], m.Data[3, 2]);
end;

//---------------------------------------------------------------------------
function InvertMtx4(const m: TMatrix4): TMatrix4;
var
 Det: Single;
begin
 Det:= DetMtx4(m);

 if (Abs(Det) > NonZeroEpsilon) then
  begin
   Result:= AdjointMtx4(m) / Det;
  end else Result:= IdentityMtx4;
end;

//--------------------------------------------------------------------------
function RotateXMtx4(Angle: Single): TMatrix4;
begin
 Result:= IdentityMtx4;

 Result.Data[1, 1]:=  Cos(Angle);
 Result.Data[1, 2]:=  Sin(Angle);
 Result.Data[2, 1]:= -Result.Data[1, 2];
 Result.Data[2, 2]:=  Result.Data[1, 1];
end;

//--------------------------------------------------------------------------
function RotateYMtx4(Angle: Single): TMatrix4;
begin
 Result:= IdentityMtx4;

 Result.Data[0, 0]:=  Cos(Angle);
 Result.Data[0, 2]:= -Sin(Angle);
 Result.Data[2, 0]:= -Result.Data[0, 2];
 Result.Data[2, 2]:=  Result.Data[0, 0];
end;

//--------------------------------------------------------------------------
function RotateZMtx4(Angle: Single): TMatrix4;
begin
 Result:= IdentityMtx4;

 Result.Data[0, 0]:=  Cos(Angle);
 Result.Data[0, 1]:=  Sin(Angle);
 Result.Data[1, 0]:= -Result.Data[0, 1];
 Result.Data[1, 1]:=  Result.Data[0, 0];
end;

//--------------------------------------------------------------------------
function RotateMtx4(const Axis: TVector3; Angle: Single): TMatrix4;
var
 CosTh, iCosTh, SinTh: Single;
 xy, xz, yz, xSin, ySin, zSin: Single;
begin
 Result:= IdentityMtx4;

 SinTh := Sin(Angle);
 CosTh := Cos(Angle);
 iCosTh:= 1.0 - CosTh;

 xy:= Axis.x * Axis.y * iCosTh;
 xz:= Axis.x * Axis.z * iCosTh;
 yz:= Axis.y * Axis.z * iCosTh;

 xSin:= Axis.x * SinTh;
 ySin:= Axis.y * SinTh;
 zSin:= Axis.z * SinTh;

 Result.Data[0, 0]:= (Sqr(Axis.x) * iCosTh) + CosTh;
 Result.Data[0, 1]:= xy + zSin;
 Result.Data[0, 2]:= xz - ySin;
 Result.Data[1, 0]:= xy - zSin;
 Result.Data[1, 1]:= (Sqr(Axis.y) * iCosTh) + CosTh;
 Result.Data[1, 2]:= yz + xSin;
 Result.Data[2, 0]:= xz + ySin;
 Result.Data[2, 1]:= yz - xSin;
 Result.Data[2, 2]:= (Sqr(Axis.z) * iCosTh) + CosTh;
end;

//---------------------------------------------------------------------------
function ReflectMtx4(const Axis: TVector3): TMatrix4;
var
 xy, yz, xz: Single;
begin
 xy:= -2.0 * Axis.x * Axis.y;
 xz:= -2.0 * Axis.x * Axis.z;
 yz:= -2.0 * Axis.y * Axis.z;

 Result:= IdentityMtx4;
 Result.Data[0, 0]:= 1.0 - (2.0 * Sqr(Axis.x));
 Result.Data[0, 1]:= xy;
 Result.Data[0, 2]:= xz;
 Result.Data[1, 0]:= xy;
 Result.Data[1, 1]:= 1.0 - (2.0 * Sqr(Axis.y));
 Result.Data[1, 2]:= yz;
 Result.Data[2, 0]:= xz;
 Result.Data[2, 1]:= yz;
 Result.Data[2, 2]:= 1.0 - (2.0 * Sqr(Axis.z));
end;

//---------------------------------------------------------------------------
function LookAtMtx4(const Origin, Target, Roof: TVector3): TMatrix4;
var
 xAxis, yAxis, zAxis: TVector3;
begin
 zAxis:= Norm3(Target - Origin);
 xAxis:= Norm3(Cross3(Roof, zAxis));
 yAxis:= Cross3(zAxis, xAxis);

 Result.Data[0, 0]:= xAxis.x;
 Result.Data[0, 1]:= yAxis.x;
 Result.Data[0, 2]:= zAxis.x;
 Result.Data[0, 3]:= 0.0;

 Result.Data[1, 0]:= xAxis.y;
 Result.Data[1, 1]:= yAxis.y;
 Result.Data[1, 2]:= zAxis.y;
 Result.Data[1, 3]:= 0.0;

 Result.Data[2, 0]:= xAxis.z;
 Result.Data[2, 1]:= yAxis.z;
 Result.Data[2, 2]:= zAxis.z;
 Result.Data[2, 3]:= 0.0;

 Result.Data[3, 0]:= -Dot3(xAxis, Origin);
 Result.Data[3, 1]:= -Dot3(yAxis, Origin);
 Result.Data[3, 2]:= -Dot3(zAxis, Origin);
 Result.Data[3, 3]:= 1.0;
end;

//---------------------------------------------------------------------------
function PerspectiveFOVYMtx4(FieldOfView, AspectRatio, MinRange,
 MaxRange: Single): TMatrix4;
var
 xScale, yScale, zCoef: Single;
begin
 Result:= ZeroMtx4;

 yScale:= Cot(FieldOfView * 0.5);
 xScale:= yScale / AspectRatio;
 zCoef := MaxRange / (MaxRange - MinRange);

 Result.Data[0, 0]:= xScale;
 Result.Data[1, 1]:= yScale;
 Result.Data[2, 2]:= zCoef;
 Result.Data[2, 3]:= 1.0;
 Result.Data[3, 2]:= -MinRange * zCoef;
end;

//---------------------------------------------------------------------------
function PerspectiveFOVXMtx4(FieldOfView, AspectRatio, MinRange,
 MaxRange: Single): TMatrix4;
var
 xScale, yScale, zCoef: Single;
begin
 Result:= ZeroMtx4;

 xScale:= Cot(FieldOfView * 0.5);
 yScale:= xScale / AspectRatio;
 zCoef := MaxRange / (MaxRange - MinRange);

 Result.Data[0, 0]:= xScale;
 Result.Data[1, 1]:= yScale;
 Result.Data[2, 2]:= zCoef;
 Result.Data[2, 3]:= 1.0;
 Result.Data[3, 2]:= -MinRange * zCoef;
end;

//---------------------------------------------------------------------------
function PerspectiveVOLMtx4(Width, Height, MinRange,
 MaxRange: Single): TMatrix4;
begin
 Result:= ZeroMtx4;

 Result.Data[0, 0]:= (2.0 * MinRange) / Width;
 Result.Data[1, 1]:= (2.0 * MinRange) / Height;
 Result.Data[2, 2]:= MaxRange / (MaxRange - MinRange);
 Result.Data[2, 3]:= 1.0;
 Result.Data[3, 2]:= MinRange * (MinRange - MaxRange);
end;

//---------------------------------------------------------------------------
function PerspectiveBDSMtx4(Left, Right, Top, Bottom, MinRange,
 MaxRange: Single): TMatrix4;
begin
 Result:= ZeroMtx4;

 Result.Data[0, 0]:= (2.0 * MinRange) / (Right - Left);
 Result.Data[1, 1]:= (2.0 * MinRange) / (Top - Bottom);

 Result.Data[2, 0]:= (Left + Right) / (Left - Right);
 Result.Data[2, 1]:= (Top + Bottom) / (Bottom - Top);
 Result.Data[2, 2]:= MaxRange / (MaxRange - MinRange);
 Result.Data[2, 3]:= 1.0;
 Result.Data[3, 2]:= MinRange * MaxRange / (MinRange - MaxRange);
end;

//---------------------------------------------------------------------------
function OrthogonalVOLMtx4(Width, Height, MinRange,
 MaxRange: Single): TMatrix4;
begin
 Result:= ZeroMtx4;

 Result.Data[0, 0]:= 2.0 / Width;
 Result.Data[1, 1]:= 2.0 / Height;
 Result.Data[2, 2]:= 1.0 / (MaxRange - MinRange);
 Result.Data[2, 3]:= MinRange / (MinRange - MaxRange);
 Result.Data[3, 3]:= 1.0;
end;

//---------------------------------------------------------------------------
function OrthogonalBDSMtx4(Left, Right, Top, Bottom, MinRange,
 MaxRange: Single): TMatrix4;
begin
 Result:= ZeroMtx4;

 Result.Data[0, 0]:= 2.0 / (Right - Left);
 Result.Data[1, 1]:= 2.0 / (Top - Bottom);
 Result.Data[2, 2]:= 1.0 / (MaxRange - MinRange);
 Result.Data[2, 3]:= MinRange / (MinRange - MaxRange);
 Result.Data[3, 0]:= (Left + Right) / (Left - Right);
 Result.Data[3, 1]:= (Top + Bottom) / (Bottom - Top);
 Result.Data[3, 2]:= MinRange / (MinRange - MaxRange);
 Result.Data[3, 3]:= 1.0;
end;

//--------------------------------------------------------------------------
function HeadingPitchBankMtx4(Heading, Pitch, Bank: Single): TMatrix4;
var
 CosH, SinH: Single;
 CosP, SinP: Single;
 CosB, SinB: Single;
begin
 Result:= IdentityMtx4;

 CosH:= Cos(Heading);
 SinH:= Sin(Heading);
 CosP:= Cos(Pitch);
 SinP:= Sin(Pitch);
 CosB:= Cos(Bank);
 SinB:= Sin(Bank);

 Result.Data[0, 0]:= (CosH * CosB) + (SinH * SinP * SinB);
 Result.Data[0, 1]:= (-CosH * SinB) + (SinH * SinP * CosB);
 Result.Data[0, 2]:= SinH * CosP;
 Result.Data[1, 0]:= SinB * CosP;
 Result.Data[1, 1]:= CosB * CosP;
 Result.Data[1, 2]:= -SinP;
 Result.Data[2, 0]:= (-SinH * CosB) + (CosH * SinP * SinB);
 Result.Data[2, 1]:= (SinB * SinH) + (CosH * SinP * CosB);
 Result.Data[2, 2]:= CosH * CosP;
end;

//---------------------------------------------------------------------------
function HeadingPitchBankMtx4(const v: TVector3): TMatrix4; overload;
begin
 Result:= HeadingPitchBankMtx4(v.y, v.x, v.z);
end;

//---------------------------------------------------------------------------
function YawPitchRollMtx4(Yaw, Pitch, Roll: Single): TMatrix4; overload;
var
 SinYaw, CosYaw, SinPitch, CosPitch, SinRoll, CosRoll: Single;
begin
 Result:= IdentityMtx4;

 SinYaw  := Sin(Yaw);
 CosYaw  := Cos(Yaw);
 SinPitch:= Sin(Pitch);
 CosPitch:= Cos(Pitch);
 SinRoll := Sin(Roll);
 CosRoll := Cos(Roll);

 Result.Data[0, 0]:= CosRoll * CosYaw + SinPitch * SinRoll * SinYaw;
 Result.Data[0, 1]:= CosYaw * SinPitch * SinRoll - CosRoll * SinYaw;
 Result.Data[0, 2]:= -CosPitch * SinRoll;

 Result.Data[1, 0]:= CosPitch * SinYaw;
 Result.Data[1, 1]:= CosPitch * CosYaw;
 Result.Data[1, 2]:= SinPitch;

 Result.Data[2, 0]:= CosYaw * SinRoll - CosRoll * SinPitch * SinYaw;
 Result.Data[2, 1]:= -CosRoll * CosYaw * SinPitch - SinRoll * SinYaw;
 Result.Data[2, 2]:= CosPitch * CosRoll;
end;

//---------------------------------------------------------------------------
function YawPitchRollMtx4(const v: TVector3): TMatrix4; overload;
begin
 Result:= YawPitchRollMtx4(v.y, v.x, v.z);
end;

//---------------------------------------------------------------------------
function GetEyePos4(const m: TMatrix4): TVector3;
begin
 Result.x:= -m.Data[0, 0] * m.Data[3, 0] - m.Data[0, 1] * m.Data[3, 1] -
  m.Data[0, 2]  * m.Data[3, 2];

 Result.y:= -m.Data[1, 0] * m.Data[3, 0] - m.Data[1, 1] * m.Data[3, 1] -
  m.Data[1, 2]  * m.Data[3, 2];

 Result.z:= -m.Data[2, 0] * m.Data[3, 0] - m.Data[2, 1] * m.Data[3, 1] -
  m.Data[2, 2]  * m.Data[3, 2];
end;

//---------------------------------------------------------------------------
function GetWorldPos4(const m: TMatrix4): TVector3;
begin
 Result.x:= m.Data[3, 0];
 Result.y:= m.Data[3, 1];
 Result.z:= m.Data[3, 2];
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
