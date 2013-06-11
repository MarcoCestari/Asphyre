unit Asphyre.Timing;
//---------------------------------------------------------------------------
// Cross-platform timing and utilities.
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
{< High accuracy timing and sleep routines that can be used on different
   platforms including Win32, Win64 and Mac OS. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 Asphyre.TypeDef;

//---------------------------------------------------------------------------
type
{ The timing mode that is currently being used by @link(TAsphyreTiming).
  It is typically chosen the first time one of the routines is called and
  remains unchanged during the lifetime of application. }
 TAsphyreTimingMode = (

  { The timing operations have not yet started. One of the timing functions
    need to be called for this state to change. @br @br }
  atmNotStarted,

  { The timing operations are running in low-precision mode that may degrade
    the quality of operations. This means that the system has no high precision
    timer available. @br @br }
  atmLowPrecision,

  { The timing operations are running in high-precision mode providing the
    best possible timer resolution. The actual resolution is hardware and
    platform dependent and can vary on different configurations. }
  atmHighPrecision);

//---------------------------------------------------------------------------
{ High accuracy timing and sleep implementation that can be used on different
  platforms including Win32, Win64 and Mac OS. }
 TAsphyreTiming = class
 private
  FMode: TAsphyreTimingMode;

  {$ifdef MsWindows}
  HighFrequency: Int64;
  {$endif}
 public
  { The timing mode at which the component currently operates. }
  property Mode: TAsphyreTimingMode read FMode;

  { Returns the current timer counter represented as 64-bit floating-point
    number. The resulting value is specified in milliseconds and fractions
    of thereof. The value should only be used for calculating differences
    because it can wrap (from very high positive value back to zero or even
    some negative value) after prolonged time intervals. }
  function GetTimeValue(): PreciseFloat;

  { Returns the current timer counter represented as 32-bit unsigned integer.
    The resulting value is specified in milliseconds. The value should only be
    used for calculating differences because it can wrap (from very high
    positive value back to zero) after prolonged time intervals. The wrapping
    usually occurs upon reaching High(Cardinal) but depending on each
    individual platform, it can also occur earlier. }
  function GetTickCount(): Cardinal;

  { Causes the calling thread to sleep for a given number of milliseconds.
    The sleep can actually be interrupted under certain conditions (such as
    when a message is sent to the caller's thread). }
  procedure Sleep(Milliseconds: Integer);

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
{ A running instance of @link(TAsphyreTiming) that is created when the
  application is executed and freed upon termination; therefore, this class
  can be used with its timing functions without having to explicitly create
  it elsewhere. }
 Timing: TAsphyreTiming{$ifndef PasDoc} = nil{$endif};

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifdef MsWindows}
 Winapi.Windows, Winapi.MMSystem,
 {$define OSTimingSupport}
{$endif}

{$ifdef Posix}
 Posix.SysTime, Posix.Time,
 {$define OSTimingSupport}
{$endif}

 System.SysUtils;

//---------------------------------------------------------------------------
constructor TAsphyreTiming.Create();
begin
 inherited;

 FMode:= atmNotStarted;

{$ifdef MsWindows}
 HighFrequency:= 0;
{$endif}
end;

//---------------------------------------------------------------------------
destructor TAsphyreTiming.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreTiming.GetTimeValue(): PreciseFloat;
var
{$ifdef MsWindows}
 TimeCounter: Int64;
{$endif}
{$ifdef Posix}
 Value: TimeVal;
{$endif}
{$ifndef OSTimingSupport}
 CurTime: TDateTime;
{$endif}
begin
{$ifdef MsWindows}
 if (FMode = atmNotStarted) then
  begin
   FMode:= atmLowPrecision;

   if (QueryPerformanceFrequency(HighFrequency))and(HighFrequency > 0) then
    FMode:= atmHighPrecision;
  end;

 if (FMode = atmHighPrecision) then
  begin
   QueryPerformanceCounter(TimeCounter);
   Result:= (TimeCounter * 1000.0) / HighFrequency;
  end else Result:= timeGetTime();
{$endif}

{$ifdef Posix}
 if (FMode = atmNotStarted) then
  FMode:= atmHighPrecision;

 GetTimeOfDay(Value, nil);
 Result:= (Value.tv_sec * 1000.0) + (Value.tv_usec / 1000.0);
{$endif}

{$ifndef OSTimingSupport}
 CurTime:= Now();
 Result := CurTime * 86400000.0;
{$endif}
end;

//---------------------------------------------------------------------------
function TAsphyreTiming.GetTickCount(): Cardinal;
begin
 Result:= Cardinal(Round(GetTimeValue()));
end;

//---------------------------------------------------------------------------
procedure TAsphyreTiming.Sleep(Milliseconds: Integer);
{$ifdef Posix}
var
 Delay, DelayRem: TimeSpec;
{$endif}
begin
{$ifdef MsWindows}
 SleepEx(Milliseconds, True);
{$endif}

{$ifdef Posix}
 Delay.tv_sec := Milliseconds div 1000;
 Delay.tv_nsec:= (Milliseconds mod 1000) * 1000000;

 NanoSleep(Delay, @DelayRem);
{$endif}

{$ifndef OSTimingSupport}
 SysUtils.Sleep(Milliseconds);
{$endif}
end;

//---------------------------------------------------------------------------
initialization
 Timing:= TAsphyreTiming.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(Timing);

//---------------------------------------------------------------------------
end.
