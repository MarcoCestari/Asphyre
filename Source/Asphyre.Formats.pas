unit Asphyre.Formats;
//---------------------------------------------------------------------------
// Conversion and mapping between different pixel formats.
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
{< Utility routines for converting between different pixel formats. Most of
   the pixel formats that are described by Asphyre are supported except those
   that are floating-point. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.SysUtils, System.Classes, Asphyre.TypeDef, Asphyre.Types;

//---------------------------------------------------------------------------
{$define Asphyre_Interface}
 {$include Asphyre.Formats.inc}
 {$include Asphyre.FormatInfo.inc}
 {$include Asphyre.FormatConv.inc}
{$undef Asphyre_Interface}

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
{$define Asphyre_Implementation}
 {$include Asphyre.Formats.inc}
 {$include Asphyre.FormatInfo.inc}
 {$include Asphyre.FormatConv.inc}
{$undef Asphyre_Implementation}

//---------------------------------------------------------------------------
initialization
{$define Asphyre_Initialization}
 {$include Asphyre.Formats.inc}
{$undef Asphyre_Initialization}

//---------------------------------------------------------------------------
finalization
{$define Asphyre_Finalization}
 {$include Asphyre.Formats.inc}
{$undef Asphyre_Finalization}

//---------------------------------------------------------------------------
end.
