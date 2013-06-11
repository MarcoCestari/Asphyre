//---------------------------------------------------------------------------
// Matrix4Helper.inc
// High-level implementation of 4x4 matrix w/32-byte alignment.
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
 { High-level 4x4 matrix class that facilitates working with matrices for
   moving objects, cameras and projections. The matrix information is aligned
   on 16-byte boundaries, which allows it to be used with aligned SSE assembly
   instructions for improved performance. }
 TAsphyreMatrix = class
 private
  MemAddr: Pointer;
  FRawMtx: PMatrix4;

  function GetWorldPos(): TVector3;
  function GetEyePos(): TVector3;
 public
  { Pointer th the actual @link(TMatrix4) internal structure. This pointer is
    always aligned to 16-byte boundaries so that the resulting matrix can be
    used with aligned SSE assembly instructions. }
  property RawMtx: PMatrix4 read FRawMtx;

  { If the matrix defines world or object position, this property returns
    the supposed position as a 3D vector. }
  property WorldPos: TVector3 read GetWorldPos;

  { If the matrix defines camera view, this property returns the supposed
    camera (or "eye") position as a 3D vector. }
  property EyePos: TVector3 read GetEyePos;

  { Loads the contents of the matrix specified by the pointer into this
    class. }
  procedure LoadMtx(Source: PMatrix4); overload;

  { Loads the contents of the specified matrix into this class. }
  procedure LoadMtx(const Source: TMatrix4); overload;

  { Loads an identity matrix equal to @link(IdentityMtx4) into this class. }
  procedure LoadIdentity();

  { Loads a zero matrix equal to @link(ZeroMtx4) into this class. }
  procedure LoadZero();

  { Applies translation to the current matrix specified by the components of
    each individual axis. }
  procedure Translate(dx, dy, dz: Single); overload;

  { Applies translation to the current matrix specified by the given 3D
    vector. }
  procedure Translate(const v: TVector3); overload;

  { Applies scaling to the current matrix specified by the given 3D vector. }
  procedure Scale(const v: TVector3); overload;

  { Applies scaling to the current matrix specified by the components of each
    individual axis. }
  procedure Scale(dx, dy, dz: Single); overload;

  { Applies uniform scaling to the current matrix specified by a single
    coefficient. }
  procedure Scale(Delta: Single); overload;

  { Applies rotation to the current matrix around global X axis specified by
    the given angle (in radians). }
  procedure RotateX(Phi: Single);

  { Applies rotation to the current matrix around global Y axis specified by
    the given angle (in radians). }
  procedure RotateY(Phi: Single);

  { Applies rotation to the current matrix around global Z axis specified by
    the given angle (in radians). }
  procedure RotateZ(Phi: Single);

  { Applies rotation to the current matrix around local X axis specified by
    the given angle (in radians). }
  procedure RotateXLocal(Phi: Single);

  { Applies rotation to the current matrix around local Y axis specified by
    the given angle (in radians). }
  procedure RotateYLocal(Phi: Single);

  { Applies rotation to the current matrix around local Z axis specified by
    the given angle (in radians). }
  procedure RotateZLocal(Phi: Single);

  { Multiplies the current matrix by another matrix specified by the given
    pointer. }
  procedure Multiply(SrcMtx: PMatrix4); overload;

  { Multiples the current matrix by another matrix given as a parameter. }
  procedure Multiply(const SrcMtx: TMatrix4); overload;

  { Multiplies the current matrix by another matrix from another
    @link(TAsphyreMatrix) class. }
  procedure Multiply(const Source: TAsphyreMatrix); overload;

  { Loads the rotation information from matrix specified by the given pointer.
    In other words, only 3x3 part of the matrix is loaded with the rest of
    contents replaced by identity matrix. }
  procedure LoadRotation(SrcMtx: PMatrix4);

  { Multiplies the contents of the current matrix by a so-called "View" matrix,
    which is created by defining camera's position, its target and the vertical
    axis or "roof". In typical applications, it is recommended to call
    @link(LoadIdentity) before this method. }
  procedure LookAt(const Origin, Target, Roof: TVector3);

  { Loads perspective projection matrix defined by a field of view on Y axis.
    This is a common way for typical 3D applications. In 3D shooters special
    care is to be taken because on wide-screen monitors the visible area will
    be bigger. The parameters that define the viewed range are important for
    defining the precision of the depth transformation or a depth-buffer.
     @param(FieldOfView The camera's field of view in radians. For example Pi/4.)
     @param(AspectRatio The screen's aspect ratio. Can be calculated as y/x.)
     @param(MinRange The closest range at which the scene will be viewed.)
     @param(MaxRange The farthest range at which the scene will be viewed.) }
  procedure PerspectiveFOVY(FieldOfView, AspectRatio, MinRange,
   MaxRange: Single);

  { Loads perspective projection matrix defined by a field of view on X axis.
    In 3D shooters the field of view needs to be adjusted to allow more visible
    area on wide-screen monitors. The parameters that define the viewed range
    are important for defining the precision of the depth transformation or a
    depth-buffer.
     @param(FieldOfView The camera's field of view in radians. For example Pi/4.)
     @param(AspectRatio The screen's aspect ratio. Can be calculated as x/y.)
     @param(MinRange The closest range at which the scene will be viewed.)
     @param(MaxRange The farthest range at which the scene will be viewed.) }
  procedure PerspectiveFOVX(FieldOfView, AspectRatio, MinRange,
   MaxRange: Single);

  { Loads perspective projection matrix defined by the viewing volume in 3D
    space. }
  procedure PerspectiveVOL(Width, Height, MinRange, MaxRange: Single);

  { Loads perspective projection matrix defined by the individual axis's
    boundaries. }
  procedure PerspectiveBDS(Left, Right, Top, Bottom, MinRange,
   MaxRange: Single);

  { Loads orthogonal projection matrix defined by the viewing volume in 3D
    space. }
  procedure OrthogonalVOL(Width, Height, MinRange, MaxRange: Single);

  { Loads orthogonal projection matrix defined by the individual axis's
    boundaries. }
  procedure OrthogonalBDS(Left, Right, Top, Bottom, MinRange,
   MaxRange: Single);

  { Loads a new matrix containing 3D rotation based on parameters similar to
    flight dynamics, specifically heading, pitch and bank. The components are
    taken from the specified vector with Y corresponding to heading, X to pitch
    and Z to bank. }
  procedure HeadingPitchBank(const v: TVector3); overload;

  { Loads a new matrix containing 3D rotation based on parameters similar to
    flight dynamics, specifically heading, pitch and Bank. Each of the
    components is specified individually. }
  procedure HeadingPitchBank(Heading, Pitch, Bank: Single); overload;

  { Loads a new matrix containing 3D rotation based on parameters similar to
    flight dynamics, specifically yaw, pitch and roll. Each of the components
    is specified individually. }
  procedure YawPitchRoll(Yaw, Pitch, Roll: Single); overload;

  { Loads a new matrix containing 3D rotation based on parameters similar to
    flight dynamics, specifically yaw, pitch and roll. The components are
    taken from the specified vector with Y corresponding to yaw, X to pitch
    and Z to roll. }
  procedure YawPitchRoll(const v: TVector3); overload;

  { Calculates and loads the inverse of the current matrix. The resulting
    matrix, in other words, is the transformation that can be applied to a 3D
    vector to undo the transformation applied to it previously. }
  procedure Inverse();

  { Transposes the current matrix. That is, the rows become columns and
    vice-versa. }
  procedure Transpose();

  { Calculates the inverse of the current matrix and then transposes it. This
    is mostly useful for transforming the normals of the 3D mesh. }
  procedure InverseTranspose();

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
constructor TAsphyreMatrix.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 MemAddr:= AllocMem(SizeOf(TMatrix4) + 16);
 FRawMtx:= Pointer(PtrInt(MemAddr) + ($10 - (PtrInt(MemAddr) and $0F)));

 LoadIdentity();
end;

//---------------------------------------------------------------------------
destructor TAsphyreMatrix.Destroy();
begin
 Dec(AsphyreClassInstances);

 FreeMem(MemAddr);

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreMatrix.GetWorldPos(): TVector3;
begin
 Result:= GetWorldPos4(FRawMtx^);
end;

//---------------------------------------------------------------------------
function TAsphyreMatrix.GetEyePos(): TVector3;
begin
 Result:= GetEyePos4(FRawMtx^);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.LoadIdentity();
begin
 Move(IdentityMtx4, FRawMtx^, SizeOf(TMatrix4));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.LoadZero();
begin
 FillChar(FRawMtx^, SizeOf(TMatrix4), 0);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.LoadMtx(Source: PMatrix4);
begin
 Move(Source^, FRawMtx^, SizeOf(TMatrix4));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.LoadMtx(const Source: TMatrix4);
begin
 Move(Source, FRawMtx^, SizeOf(TMatrix4));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Translate(dx, dy, dz: Single);
begin
 FRawMtx^:= FRawMtx^ * TranslateMtx4(Vector3(dx, dy, dz));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Translate(const v: TVector3);
begin
 FRawMtx^:= FRawMtx^ * TranslateMtx4(v);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.RotateX(Phi: Single);
begin
 FRawMtx^:= FRawMtx^ * RotateXMtx4(Phi);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.RotateY(Phi: Single);
begin
 FRawMtx^:= FRawMtx^ * RotateYMtx4(Phi);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.RotateZ(Phi: Single);
begin
 FRawMtx^:= FRawMtx^ * RotateZMtx4(Phi);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Scale(const v: TVector3);
begin
 FRawMtx^:= FRawMtx^ * ScaleMtx4(v);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Scale(dx, dy, dz: Single);
begin
 FRawMtx^:= FRawMtx^ * ScaleMtx4(Vector3(dx, dy, dz));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Scale(Delta: Single);
begin
 FRawMtx^:= FRawMtx^ * ScaleMtx4(Vector3(Delta, Delta, Delta));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.RotateXLocal(Phi: Single);
var
 Axis: TVector3;
begin
 Axis.x:= FRawMtx.Data[0, 0];
 Axis.y:= FRawMtx.Data[0, 1];
 Axis.z:= FRawMtx.Data[0, 2];

 FRawMtx^:= FRawMtx^ * RotateMtx4(Axis, Phi);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.RotateYLocal(Phi: Single);
var
 Axis: TVector3;
begin
 Axis.x:= FRawMtx.Data[1, 0];
 Axis.y:= FRawMtx.Data[1, 1];
 Axis.z:= FRawMtx.Data[1, 2];

 FRawMtx^:= FRawMtx^ * RotateMtx4(Axis, Phi);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.RotateZLocal(Phi: Single);
var
 Axis: TVector3;
begin
 Axis.x:= FRawMtx.Data[2, 0];
 Axis.y:= FRawMtx.Data[2, 1];
 Axis.z:= FRawMtx.Data[2, 2];

 FRawMtx^:= FRawMtx^ * RotateMtx4(Axis, Phi);
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.Multiply(SrcMtx: PMatrix4);
begin
 FRawMtx^:= FRawMtx^ * SrcMtx^;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Multiply(const SrcMtx: TMatrix4);
begin
 Multiply(@SrcMtx);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Multiply(const Source: TAsphyreMatrix);
begin
 Multiply(Source.RawMtx);
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.LookAt(const Origin, Target, Roof: TVector3);
var
 Aux: TMatrix4;
begin
 Aux:= LookAtMtx4(Origin, Target, Roof);
 Multiply(@Aux);
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.PerspectiveFovY(FieldOfView, AspectRatio, MinRange,
 MaxRange: Single);
begin
 FRawMtx^:= PerspectiveFOVYMtx4(FieldOfView, AspectRatio, MinRange, MaxRange);
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.PerspectiveFovX(FieldOfView, AspectRatio, MinRange,
 MaxRange: Single);
begin
 FRawMtx^:= PerspectiveFOVXMtx4(FieldOfView, AspectRatio, MinRange, MaxRange);
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.PerspectiveVOL(Width, Height, MinRange,
 MaxRange: Single);
begin
 FRawMtx^:= PerspectiveVOLMtx4(Width, Height, MinRange, MaxRange);
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.PerspectiveBDS(Left, Right, Top, Bottom, MinRange,
 MaxRange: Single);
begin
 FRawMtx^:= PerspectiveBDSMtx4(Left, Right, Top, Bottom, MinRange, MaxRange);
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.OrthogonalVOL(Width, Height, MinRange,
 MaxRange: Single);
begin
 FRawMtx^:= OrthogonalVOLMtx4(Width, Height, MinRange, MaxRange);
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.OrthogonalBDS(Left, Right, Top, Bottom, MinRange,
 MaxRange: Single);
begin
 FRawMtx^:= OrthogonalBDSMtx4(Left, Right, Top, Bottom, MinRange, MaxRange);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.LoadRotation(SrcMtx: PMatrix4);
var
 i: Integer;
begin
 Move(SrcMtx^, FRawMtx^, SizeOf(TMatrix4));

 for i:= 0 to 3 do
  begin
   FRawMtx.Data[3, i]:= 0.0;
   FRawMtx.Data[i, 3]:= 0.0;
  end;

 FRawMtx.Data[3, 3]:= 1.0;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.HeadingPitchBank(Heading, Pitch, Bank: Single);
var
 Aux: TMatrix4;
begin
 Aux:= HeadingPitchBankMtx4(Heading, Pitch, Bank);
 Multiply(@Aux);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.HeadingPitchBank(const v: TVector3);
var
 Aux: TMatrix4;
begin
 Aux:= HeadingPitchBankMtx4(v);
 Multiply(@Aux);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.YawPitchRoll(Yaw, Pitch, Roll: Single);
begin
 Multiply(YawPitchRollMtx4(Yaw, Pitch, Roll));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.YawPitchRoll(const v: TVector3);
begin
 YawPitchRoll(v.y, v.x, v.z);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.InverseTranspose();
begin
 FRawMtx^:= TransposeMtx4(InvertMtx4(FRawMtx^));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Inverse();
begin
 FRawMtx^:= InvertMtx4(FRawMtx^);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Transpose();
begin
 FRawMtx^:= TransposeMtx4(FrawMtx^);
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
