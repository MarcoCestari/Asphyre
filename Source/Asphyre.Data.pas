unit Asphyre.Data;
//---------------------------------------------------------------------------
// Helper routines working with binary data.
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
{< Utility routines for working with binary data including compression,
   encryption and checksum calculation. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.Types, System.SysUtils, System.Classes,

{$ifdef fpc}
 paszlib
{$else}
 {$ifdef DelphiLegacy}
 AsphyreZLib
 {$else}
 ZLib
 {$endif}
{$endif};

//---------------------------------------------------------------------------
{$define Asphyre_Interface}
 {$include Asphyre.Base64Codec.inc}
 {$include Asphyre.CipherXTEA.inc}
 {$include Asphyre.EvalCRC32.inc}
 {$include Asphyre.EvalMD5.inc}
 {$include Asphyre.ZLibComp.inc}
{$undef Asphyre_Interface}

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
{$define Asphyre_Implementation}
 {$include Asphyre.Base64Codec.inc}
 {$include Asphyre.CipherXTEA.inc}
 {$include Asphyre.EvalCRC32.inc}
 {$include Asphyre.EvalMD5.inc}
 {$include Asphyre.ZLibComp.inc}
{$undef Asphyre_Implementation}

//---------------------------------------------------------------------------
end.
