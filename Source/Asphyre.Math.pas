unit Asphyre.Math;
//---------------------------------------------------------------------------
// Mathematical definitions and functions.
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
{< Mathematical types and functions that facilitate working with common
   tasks. This unit includes a complete functional set of 2D, 3D and 4D
   vectors, 3D and 4D matrices and quaternions. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
{$ifdef fpc}
 Types, SysUtils, Math;
{$else}
 System.Types, System.SysUtils, System.Math, Asphyre.TypeDef;
{$endif}

//---------------------------------------------------------------------------
{$define Asphyre_Interface}
 {$include Asphyre.Vectors2px.inc}
 {$include Asphyre.Vectors2.inc}
 {$include Asphyre.Matrices3.inc}
 {$include Asphyre.Vectors3.inc}
 {$include Asphyre.Matrices4.inc}
 {$include Asphyre.Vectors4.inc}
 {$include Asphyre.Quaternions.inc}
 {$include Asphyre.Matrix4Helper.inc}
{$undef Asphyre_Interface}

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 CacheSize = 128;
 NonZeroEpsilon = 0.00001;

//---------------------------------------------------------------------------
{$define Asphyre_Implementation}
 {$include Asphyre.Vectors2px.inc}
 {$include Asphyre.Vectors2.inc}
 {$include Asphyre.Matrices3.inc}
 {$include Asphyre.Vectors3.inc}
 {$include Asphyre.Matrices4.inc}
 {$include Asphyre.Vectors4.inc}
 {$include Asphyre.Quaternions.inc}
 {$include Asphyre.Matrix4Helper.inc}
{$undef Asphyre_Implementation}

//---------------------------------------------------------------------------
end.
