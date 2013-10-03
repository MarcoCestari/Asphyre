//---------------------------------------------------------------------------
// Asphyre.Config.inc
// Compiler configuration for Asphyre framework.
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

{$define AllowPreciseFloat}

//---------------------------------------------------------------------------
// The following parameters make the framework compliant with FreePascal.
//---------------------------------------------------------------------------
{$ifdef fpc}
 {$ifdef cpu32}{$ifdef i386}{$define cpux86}{$endif}{$endif}
 {$ifdef cpu64}{$define cpux64}{$endif}
{$endif}

//---------------------------------------------------------------------------
// Provide shorter keyword for Windows platform.
//---------------------------------------------------------------------------
{$ifdef MsWindows}
{$define Windows}
{$endif}

//---------------------------------------------------------------------------
// Determine Delphi version.
//---------------------------------------------------------------------------
{$ifndef fpc}

{$define Delphi}

{$ifdef ver180} // Delphi 2006
 {$define DelphiLegacy}
 {$define Delphi2006}
{$endif}

{$ifdef ver185} // Delphi 2007
 {$define DelphiLegacy}
 {$define Delphi2007}
{$endif}

{$ifdef ver200} // Delphi 2009
 {$define Delphi2009Up}
 {$define Delphi2009}
{$endif}

{$ifdef ver210} // Delphi 2010
 {$define Delphi2009Up}
 {$define Delphi2010Up}
 {$define Delphi2010}
{$endif}

{$ifdef ver220} // Delphi XE
 {$define Delphi2009Up}
 {$define Delphi2010Up}
 {$define DelphiXEUp}
 {$define DelphiXE}
{$endif}

{$ifdef ver230} // Delphi XE 2
 {$define Delphi2009Up}
 {$define Delphi2010Up}
 {$define DelphiXEUp}
 {$define DelphiXE2Up}
 {$define DelphiXE2}
{$endif}

{$ifdef ver240} // Delphi XE 3
 {$define Delphi2009Up}
 {$define Delphi2010Up}
 {$define DelphiXEUp}
 {$define DelphiXE2Up}
 {$define DelphiXE3Up}
 {$define DelphiXE3}
{$endif}

{$ifdef ver250} // Delphi XE 4
 {$define Delphi2009Up}
 {$define Delphi2010Up}
 {$define DelphiXEUp}
 {$define DelphiXE2Up}
 {$define DelphiXE3Up}
 {$define DelphiXE3}
 {$define DelphiXE4}
{$endif}

{$ifdef ver260} // Delphi XE 5
 {$define Delphi2009Up}
 {$define Delphi2010Up}
 {$define DelphiXEUp}
 {$define DelphiXE2Up}
 {$define DelphiXE3Up}
 {$define DelphiXE3}
 {$define DelphiXE4}
 {$define DelphiXE5}
{$endif}

{$endif}

//---------------------------------------------------------------------------
{$ifdef Delphi}
 {$ifdef NextGen}
  {$define DelphiNextGen}
  {$define StandardStringsOnly}
 {$endif}
{$endif}

//---------------------------------------------------------------------------
{$ifdef DelphiLegacy}
 // Earlier Delphi versions do not have CPUX86 symbol defined.
 {$define cpux86}
{$endif}

//---------------------------------------------------------------------------
// On Mac OS X, FireMonkey is always used. This flag needs to be configured
// manually on Windows.
//---------------------------------------------------------------------------
{$if defined(Delphi) and defined(posix)}
 {$define FireMonkey}
{$ifend}

//---------------------------------------------------------------------------
// FreePascal does not support assembly instructions on 64-bit platform.
//---------------------------------------------------------------------------
{$ifdef fpc}
 {$ifdef cpux64}
  {$define PurePascal}
 {$endif}
{$endif}

//---------------------------------------------------------------------------
// On 32-bit Intel platform, assembly instructions are explicitly allowed.
//---------------------------------------------------------------------------
{$ifndef PurePascal}
 {$ifdef cpux86}
  {$define AsmIntelX86}
 {$endif}
{$endif}

//---------------------------------------------------------------------------
// Disable excess precision for 32-bit floating-point operations in latest
// versions of Delphi XE 2 and up, to speed up intermediary calculations.
//---------------------------------------------------------------------------
{$ifdef DelphiXE2Up}
 {$ExcessPrecision off}
{$endif}

//---------------------------------------------------------------------------
// Enable Delphi compatibility mode in FreePascal
//---------------------------------------------------------------------------
{$ifdef fpc}
 {$mode delphi}
{$endif}
