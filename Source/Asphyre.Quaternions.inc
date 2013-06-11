//---------------------------------------------------------------------------
// Quaternions.inc
// Definitions and functions working with 3D quaternions.
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
{ 3D quaternion }
 TQuaternion = record
  w, x, y, z: Single;

  {@exclude}class operator Multiply(const a, b: TQuaternion): TQuaternion;
  {@exclude}class operator Implicit(const q: TQuaternion): TMatrix4;
  {@exclude}class operator Explicit(const m: TMatrix4): TQuaternion;
 end;

//---------------------------------------------------------------------------
const
{ Identity quaternion that can be used to specify an object with no rotation. }
 IdentityQuat: TQuaternion = (w: 1.0; x: 0.0; y: 0.0; z: 0.0);

//---------------------------------------------------------------------------
{ Creates 3D quaternion containing rotation around X axis with the specified
  angle (in radians). }
function RotateAboutXQuat(Theta: Single): TQuaternion;

//---------------------------------------------------------------------------
{ Creates 3D quaternion containing rotation around Y axis with the specified
  angle (in radians). }
function RotateAboutYQuat(Theta: Single): TQuaternion;

//---------------------------------------------------------------------------
{ Creates 3D quaternion containing rotation around Z axis with the specified
  angle (in radians). }
function RotateAboutZQuat(Theta: Single): TQuaternion;

//---------------------------------------------------------------------------
{ Creates 3D quaternion containing rotation around an arbitrary axis that is
  specified by the given vector; the rotation is specified in radians. }
function RotateAboutAxisQuat(const Axis: TVector3;
 Theta: Single): TQuaternion;

//---------------------------------------------------------------------------
{ Creates 3D quaternion setup to perform Object-To-Inertial rotation using
  the angles specified in Euler format. }
function RotateObjectToIntertialQuat(Pitch, Bank,
 Heading: Single): TQuaternion;

//---------------------------------------------------------------------------
{ Creates 3D quaternion setup to perform Inertial-To-Object rotation using
  the angles specified in Euler format. }
function RotateInertialToObjectQuat(Pitch, Bank,
 Heading: Single): TQuaternion;

//---------------------------------------------------------------------------
{ Normalizes the given quaternion. Note that normally quaternions are always
  normalized (of course, within limits of numerical precision). This function
  is provided mainly to combat floating point "error creep", which occurs
  after many successive quaternion operations. }
function NormalizeQuat(const q: TQuaternion): TQuaternion;

//---------------------------------------------------------------------------
{ Returns the rotational angle "theta" that is currently present in the given
 quaternion. }
function RotationAngleQuat(const q: TQuaternion): Single;

//---------------------------------------------------------------------------
{ Returns the rotational axis that is currently present in the given
  quaternion. }
function RotationAxisQuat(const q: TQuaternion): TVector3;

//---------------------------------------------------------------------------
{ Computes the dot product of the two given quaternions. }
function DotQuat(const a, b: TQuaternion): Single;

//---------------------------------------------------------------------------
{ Applies spherical linear interpolation between the specified two
  quaternions. The last parameter specifies the amount of interpolation with
  zero giving the first quaternion and one giving the second quaternion. }
function SlerpQuat(const q0, q1: TQuaternion; t: Single): TQuaternion;

//---------------------------------------------------------------------------
{ Computes the quaternion's conjugate. The resulting quaternion has opposite
  rotation to the original quaternion. }
function ConjugateQuat(const q: TQuaternion): TQuaternion;

//---------------------------------------------------------------------------
{ Computes the exponentiation of the given quaternion. }
function ExpQuat(const q: TQuaternion; Exponent: Single): TQuaternion;

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
class operator TQuaternion.Multiply(const a, b: TQuaternion): TQuaternion;
begin
 Result.w:= b.w * a.w - b.x * a.x - b.y * a.y - b.z * a.z;
 Result.x:= b.w * a.x + b.x * a.w + b.z * a.y - b.y * a.z;
 Result.y:= b.w * a.y + b.y * a.w + b.x * a.z - b.z * a.x;
 Result.z:= b.w * a.z + b.z * a.w + b.y * a.x - b.x * a.y;
end;

//---------------------------------------------------------------------------
class operator TQuaternion.Implicit(const q: TQuaternion): TMatrix4;
begin
 Result.Data[0, 0]:= 1.0 - (2.0 * q.y * q.y) - (2.0 * q.z * q.z);
 Result.Data[0, 1]:= (2.0 * q.x * q.y) + (2.0 * q.w * q.z);
 Result.Data[0, 2]:= (2.0 * q.x * q.z) - (2.0 * q.w * q.y);
 Result.Data[0, 3]:= 0.0;
 Result.Data[1, 0]:= (2.0 * q.x * q.y) - (2.0 * q.w * q.z);
 Result.Data[1, 1]:= 1.0 - (2.0 * q.x * q.x) - (2.0 * q.z * q.z);
 Result.Data[1, 2]:= (2.0 * q.y * q.z) + (2.0 * q.w * q.x);
 Result.Data[1, 3]:= 0.0;
 Result.Data[2, 0]:= (2.0 * q.x * q.z) + (2.0 * q.w * q.y);
 Result.Data[2, 1]:= (2.0 * q.y * q.z) - (2.0 * q.w * q.x);
 Result.Data[2, 2]:= 1.0 - (2.0 * q.x * q.x) - (2.0 * q.y * q.y);
 Result.Data[2, 3]:= 0.0;
 Result.Data[3, 0]:= 0.0;
 Result.Data[3, 1]:= 0.0;
 Result.Data[3, 2]:= 0.0;
 Result.Data[3, 3]:= 1.0;
end;

//---------------------------------------------------------------------------
class operator TQuaternion.Explicit(const m: TMatrix4): TQuaternion;
var
 Aux  : TQuaternion;
 Max  : Single;
 Index: Integer;
 High : Double;
 Mult : Double;
begin
 // Determine wich of w, x, y, z has the largest absolute value.
 Aux.w:= m.Data[0, 0] + m.Data[1, 1] + m.Data[2, 2];
 Aux.x:= m.Data[0, 0] - m.Data[1, 1] - m.Data[2, 2];
 Aux.y:= m.Data[1, 1] - m.Data[0, 0] - m.Data[2, 2];
 Aux.z:= m.Data[2, 2] - m.Data[0, 0] - m.Data[1, 1];

 Index:= 0;
 Max  := Aux.w;
 if (Aux.x > Max) then
  begin
   Max  := Aux.x;
   Index:= 1;
  end;
 if (Aux.y > Max) then
  begin
   Max  := Aux.y;
   Index:= 2;
  end;
 if (Aux.z > Max) then
  begin
   Max  := Aux.z;
   Index:= 3;
  end;

 // Performe square root and division.
 High:= Sqrt(Max + 1.0) * 0.5;
 Mult:= 0.25 / High;

 // Apply table to compute quaternion values.
 case Index of
  0: begin
      Result.w:= High;
      Result.x:= (m.Data[1, 2] - m.Data[2, 1]) * Mult;
      Result.y:= (m.Data[2, 0] - m.Data[0, 2]) * Mult;
      Result.z:= (m.Data[0, 1] - m.Data[1, 0]) * Mult;
     end;
  1: begin
      Result.x:= High;
      Result.w:= (m.Data[1, 2] - m.Data[2, 1]) * Mult;
      Result.z:= (m.Data[2, 0] + m.Data[0, 2]) * Mult;
      Result.y:= (m.Data[0, 1] + m.Data[1, 0]) * Mult;
     end;
  2: begin
      Result.y:= High;
      Result.z:= (m.Data[1, 2] + m.Data[2, 1]) * Mult;
      Result.w:= (m.Data[2, 0] - m.Data[0, 2]) * Mult;
      Result.x:= (m.Data[0, 1] + m.Data[1, 0]) * Mult;
     end;
  else
   begin
    Result.z:= High;
    Result.y:= (m.Data[1, 2] + m.Data[2, 1]) * Mult;
    Result.x:= (m.Data[2, 0] + m.Data[0, 2]) * Mult;
    Result.w:= (m.Data[0, 1] - m.Data[1, 0]) * Mult;
   end;
 end;
end;

//---------------------------------------------------------------------------
function RotateAboutXQuat(Theta: Single): TQuaternion;
var
 ThetaOver2: Single;
begin
 // Compute the half angle
 ThetaOver2:= Theta * 0.5;

 // Set the values
 Result.w:= Cos(ThetaOver2);
 Result.x:= Sin(ThetaOver2);
 Result.y:= 0.0;
 Result.z:= 0.0;
end;

//---------------------------------------------------------------------------
function RotateAboutYQuat(Theta: Single): TQuaternion;
var
 ThetaOver2: Single;
begin
 // Compute the half angle
 ThetaOver2:= Theta * 0.5;

 // Set the values
 Result.w:= Cos(ThetaOver2);
 Result.x:= 0.0;
 Result.y:= Sin(ThetaOver2);
 Result.z:= 0.0;
end;

//---------------------------------------------------------------------------
function RotateAboutZQuat(Theta: Single): TQuaternion;
var
 ThetaOver2: Single;
begin
 // Compute the half angle
 ThetaOver2:= Theta * 0.5;

 // Set the values
 Result.w:= Cos(ThetaOver2);
 Result.x:= 0.0;
 Result.y:= 0.0;
 Result.z:= Sin(ThetaOver2);
end;

//---------------------------------------------------------------------------
function RotateAboutAxisQuat(const Axis: TVector3;
 Theta: Single): TQuaternion;
var
 ThetaOver2, sinThetaOver2: Single;
begin
 // Compute the half angle and its sin
 ThetaOver2:= Theta * 0.5;
 SinThetaOver2:= Sin(ThetaOver2);

 // Set the values
 Result.w:= Cos(ThetaOver2);
 Result.x:= SinThetaOver2;
 Result.y:= SinThetaOver2;
 Result.z:= SinThetaOver2;
end;

//---------------------------------------------------------------------------
function RotateObjectToIntertialQuat(Pitch, Bank,
 Heading: Single): TQuaternion;
var
 sp, sb, sh, cp, cb, ch: Double;
begin
 // Compute sine and cosine of the half angles
 SinCos(Pitch * 0.5, sp, cp);
 SinCos(Bank * 0.5, sb, cb);
 SinCos(Heading * 0.5, sh, ch);

 // Compute values
 Result.w:= ( ch * cp * cb) + (sh * sp * sb);
 Result.x:= ( ch * sp * cb) + (sh * cp * sb);
 Result.y:= (-ch * sp * sb) + (sh * cp * cb);
 Result.z:= (-sh * sp * cb) + (ch * cp * sb);
end;

//---------------------------------------------------------------------------
function RotateInertialToObjectQuat(Pitch, Bank,
 Heading: Single): TQuaternion;
var
 sp, sb, sh, cp, cb, ch: Double;
begin
 // Compute sine and cosine of the half angles
 SinCos(Pitch * 0.5, sp, cp);
 SinCos(Bank * 0.5, sb, cb);
 SinCos(Heading * 0.5, sh, ch);

 // Compute values
 Result.w:= ( ch * cp * cb) + (sh * sp * sb);
 Result.x:= (-ch * sp * cb) - (sh * cp * sb);
 Result.y:= ( ch * sp * sb) - (sh * cp * cb);
 Result.z:= ( sh * sp * cb) - (ch * cp * sb);
end;

//---------------------------------------------------------------------------
function NormalizeQuat(const q: TQuaternion): TQuaternion;
var
 Mag, OneOverMag: Single;
begin
 // Compute magnitude of the quaternion
 Mag:= Sqrt(q.w * q.w + q.x * q.x + q.y * q.y + q.z * q.z);

 // Check for bogus length, to protect against divide by zero
 if (Mag > NonZeroEpsilon) then
  begin
   OneOverMag:= 1.0 / Mag;
   Result.w:= q.w * OneOverMag;
   Result.x:= q.x * OneOverMag;
   Result.y:= q.y * OneOverMag;
   Result.z:= q.z * OneOverMag;
  end else Result:= IdentityQuat;
end;

//---------------------------------------------------------------------------
function RotationAngleQuat(const q: TQuaternion): Single;
begin
 // Compute the half angle and return the rotation angle.
 // Remember that w = cos(theta / 2).
 Result:= ArcCos(q.w) * 2.0;
end;

//---------------------------------------------------------------------------
function RotationAxisQuat(const q: TQuaternion): TVector3;
var
 SinThetaOver2Sq: Single;
 OneOverSinThetaOver2: Single;
begin
 // Compute sin^2(theta/2).  Remember that w = cos(theta/2),
 // and sin^2(x) + cos^2(x) = 1
 SinThetaOver2Sq:= 1.0 - q.w * q.w;

 // Protect against numerical imprecision
 if (SinThetaOver2Sq <= 0.0) then
  begin
   // Identity quaternion, or numerical imprecision.
   // Just return any valid vector, since it doesn't matter
   Result:= AxisYVec3;
   Exit;
  end;

 // Compute 1 / sin(theta/2)
 OneOverSinThetaOver2:= 1.0 / Sqrt(SinThetaOver2Sq);

 // Return axis of rotation
 Result.x:= q.x * OneOverSinThetaOver2;
 Result.y:= q.y * OneOverSinThetaOver2;
 Result.z:= q.z * OneOverSinThetaOver2;
end;

//---------------------------------------------------------------------------
function DotQuat(const a, b: TQuaternion): Single;
begin
 Result:= (a.w * b.w) + (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
end;

//---------------------------------------------------------------------------
function SlerpQuat(const q0, q1: TQuaternion; t: Single): TQuaternion;
var
 SinOmega, CosOmega, Omega, q1w, q1x, q1y, q1z, k0, k1: Single;
 OneOverSinOmega: Single;
begin
 // Check for out-of range parameter and return edge points if so
 if (t <= 0.0) then
  begin
   Result:= q0;
   Exit;
  end;
 if (t >= 1.0) then
  begin
   Result:= q1;
   Exit;
  end;

 // Compute "cosine of angle between quaternions" using dot product
 CosOmega:= DotQuat(q0, q1);

 // If negative dot, use -q1.  Two quaternions q and -q
 // represent the same rotation, but may produce
 // different slerp.  We chose q or -q to rotate using
 // the acute angle.
 q1w:= q1.w;
 q1x:= q1.x;
 q1y:= q1.y;
 q1z:= q1.z;
 if (CosOmega < 0.0) then
  begin
   q1w:= -q1w;
   q1x:= -q1x;
   q1y:= -q1y;
   q1z:= -q1z;
   CosOmega:= -CosOmega;
  end;

 // Compute interpolation fraction, checking for quaternions
 // almost exactly the same
 if (CosOmega > 0.9999) then
  begin
   // Very close - just use linear interpolation,
   // which will protect againt a divide by zero
   k0:= 1.0 - t;
   k1:= t;
  end else
  begin
   // Compute the sin of the angle using the
   // trig identity sin^2(omega) + cos^2(omega) = 1
   SinOmega:= Sqrt(1.0 - CosOmega * CosOmega);

   // Compute the angle from its sin and cosine
   Omega:= ArcTan2(SinOmega, CosOmega);

   // Compute inverse of denominator, so we only have
   // to divide once
   OneOverSinOmega:= 1.0 / SinOmega;

   // Compute interpolation parameters
   k0:= Sin((1.0 - t) * Omega) * OneOverSinOmega;
   k1:= Sin(t * Omega) * OneOverSinOmega;
  end;

 // Interpolate
 Result.w:= k0 * q0.w + k1 * q1w;
 Result.x:= k0 * q0.x + k1 * q1x;
 Result.y:= k0 * q0.y + k1 * q1y;
 Result.z:= k0 * q0.z + k1 * q1z;
end;

//---------------------------------------------------------------------------
function ConjugateQuat(const q: TQuaternion): TQuaternion;
begin
 // Same rotation amount
 Result.w:= q.w;

 // Opposite axis of rotation
 Result.x:= -q.x;
 Result.y:= -q.y;
 Result.z:= -q.z;
end;

//---------------------------------------------------------------------------
function ExpQuat(const q: TQuaternion; Exponent: Single): TQuaternion;
var
 Alpha, NewAlpha, Mult: Single;
begin
 // Check for the case of an identity quaternion.
 // This will protect against divide by zero
 if (Abs(q.w) > (1.0 - NonZeroEpsilon)) then
  begin
   Result:= q;
   Exit;
  end;

 // Extract the half angle alpha (alpha = theta/2)
 Alpha:= ArcCos(q.w);

 // Compute new alpha value
 NewAlpha:= Alpha * Exponent;

 // Compute new w value
 Result.w:= Cos(NewAlpha);

 // Compute new xyz values
 Mult:= Sin(NewAlpha) / Sin(Alpha);
 Result.x:= q.x * Mult;
 Result.y:= q.y * Mult;
 Result.z:= q.z * Mult;
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
