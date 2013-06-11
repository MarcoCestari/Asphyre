unit Asphyre.TypeDef;
//---------------------------------------------------------------------------
// Basic type definitions for Asphyre framework.
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
{< General integer and floating-point types optimized for each platform that
   are used throughout the entire framework. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
type
{ This type is used to pass @link(SizeFloat) by reference. }
 PSizeFloat = ^SizeFloat;

//---------------------------------------------------------------------------
{ General floating-point type. On 64-bit platform it is an equivalent of
  @italic(Double) for better real-time performance, while on 32-bit systems 
  it is an equivalent of @italic(Single). }
 SizeFloat = {$ifdef cpux64}Double{$else}Single{$endif};

//---------------------------------------------------------------------------
{ This type is used to pass @link(PreciseFloat) by reference. }
 PPreciseFloat = ^PreciseFloat;

//---------------------------------------------------------------------------
{ High-precision floating-point type. It is typically equivalent of Double,
  unless target platform does not support 64-bit floats, in which case it is
  considered as Single. }
 PreciseFloat = {$ifdef AllowPreciseFloat}Double{$else}Single{$endif};

//---------------------------------------------------------------------------
{ This type is used to pass @link(UniString) by reference. }
 PUniString = ^UniString;

{ General-purpose Unicode string type. }
 UniString = {$ifdef DelphiLegacy}WideString{$else}UnicodeString{$endif};

//---------------------------------------------------------------------------
{ This type is used to pass @link(UniChar) by reference. }
 PUniChar = ^UniChar;

{ General-purpose Unicode character type. }
 UniChar =
  {$ifdef fpc}
   WideChar
  {$else}
   {$ifdef DelphiLegacy}
    WideChar
   {$else}
    Char
   {$endif}
  {$endif};

//---------------------------------------------------------------------------
{ This type is used to pass @link(StdString) by reference. }
 PStdString = ^StdString;

{ Standard string type that is compatible with most Delphi and/or FreePascal
  functions that is version dependant. In latest Delphi versions it is
  considered Unicode, while older versions and FreePascal consider it
  AnsiString. }
 StdString = {$ifdef fpc}AnsiString{$else}string{$endif};

//---------------------------------------------------------------------------
// The following types in certain circumstances can lead to better
// performance because they fit completely into CPU registers on each 
// specific platform.
//---------------------------------------------------------------------------
{ This type is used to pass @link(SizeInt) by reference. }
 PSizeInt = ^SizeInt;

{ This type is used to pass @link(SizeInt) by reference. }
 PSizeUInt = ^SizeUInt;

{$ifdef fpc}
 SizeInt  = PtrInt;
 SizeUInt = PtrUInt;
{$else}

{$ifdef DelphiXE2Up}
{ General-purpose signed integer type. }
 SizeInt = NativeInt;

{ General-purpose unsigned integer type. }
 SizeUInt = NativeUInt;
{$else} // Other Delphi versions.
 SizeInt  = Integer;
 SizeUInt = Cardinal;
{$endif}

{$endif}

//---------------------------------------------------------------------------
{$ifndef fpc}
{ Special signed integer type that can be used for pointer arithmetic. }
 PtrInt  = SizeInt;

{ Special unsigned integer type that can be used for pointer arithmetic. }
 PtrUInt = SizeUInt;
{$endif}

//---------------------------------------------------------------------------
var
{ Indicates how many total Asphyre instances are currently created. This can
  be used to debug any memory leaks, especially on systems, where automatic
  reference counting is enabled. }
 AsphyreClassInstances: Integer = 0;

//---------------------------------------------------------------------------
{ Calls FreeMem for the given value and then sets the value to @nil. }
procedure FreeNullMem(var Value);

//---------------------------------------------------------------------------
{ Adds the current FPU state to the stack. If the stack is full, this
  function does nothing. }
procedure PushFPUState();

//---------------------------------------------------------------------------
{ Adds the current FPU state to the stack and clears FPU state so that all
  FPU exceptions are disabled. If the stack is full, this function still
  disables FPU exceptions without saving original FPU state. }
procedure PushClearFPUState();

//---------------------------------------------------------------------------
{ Restores the FPU state stored that was previously added to the stack. If
  the stack is empty, this function does nothing. }
procedure PopFPUState();

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 System.Math;

//---------------------------------------------------------------------------
const
 FPUStateStackLength = 16;

 //---------------------------------------------------------------------------
{$ifndef DelphiXE2Up}
type
 TArithmeticExceptionMask = TFPUExceptionMask;

 //---------------------------------------------------------------------------
const
 exAllArithmeticExceptions = [exInvalidOp, exDenormalized, exZeroDivide,
  exOverflow, exUnderflow, exPrecision];
{$endif}

//---------------------------------------------------------------------------
var
 FPUStateStack: array[0..FPUStateStackLength - 1] of TArithmeticExceptionMask;

//---------------------------------------------------------------------------
 FPUStackAt: Integer = 0;

//---------------------------------------------------------------------------
procedure FreeNullMem(var Value);
var
 Aux: Pointer;
begin
 Aux:= Pointer(Value);

 Pointer(Value):= nil;
 FreeMem(Aux);
end;

//---------------------------------------------------------------------------
procedure PushFPUState();
begin
 if (FPUStackAt >= FPUStateStackLength) then Exit;

 FPUStateStack[FPUStackAt]:= GetExceptionMask();
 Inc(FPUStackAt);
end;

//---------------------------------------------------------------------------
procedure PushClearFPUState();
begin
 PushFPUState();
 SetExceptionMask(exAllArithmeticExceptions);
end;

//---------------------------------------------------------------------------
procedure PopFPUState();
begin
 if (FPUStackAt <= 0) then Exit;

 Dec(FPUStackAt);

 SetExceptionMask(FPUStateStack[FPUStackAt]);
 FPUStateStack[FPUStackAt]:= [];
end;

//---------------------------------------------------------------------------
end.
