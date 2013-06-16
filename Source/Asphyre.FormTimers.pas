unit Asphyre.FormTimers;
//---------------------------------------------------------------------------
// Asphyre event-based multimedia timer.
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
{< Event-based multimedia timer for Asphyre using high-precision calculations
   on Windows platforms. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.SysUtils, System.Classes, Vcl.Forms,
{$else}
 SysUtils, Classes, Forms,
{$endif}
 Asphyre.TypeDef;

//---------------------------------------------------------------------------
type
{ The implementation of Asphyre's event-based multimedia timer running on
  Windows platforms. This class hooks into application's idle event, so only
  once instance of this class should be used. For that purpose, @link(Timer)
  variable exists that is automatically created on application's start. }
 TAsphyreTimer = class
 private
  FMaxFPS : Integer;
  FSpeed  : Single;
  FEnabled: Boolean;
  FOnTimer: TNotifyEvent;

  FFrameRate: Integer;

  FOnProcess: TNotifyEvent;
  Processed : Boolean;

  FLatency: PreciseFloat;
  DeltaAccum: Single;

  ProcessTimeScale : PreciseFloat;
  MinInvokeInterval: PreciseFloat;

  QuickSampleTime: PreciseFloat;
  SlowSampleTime : PreciseFloat;
  QuickFrameCount: Integer;
  SlowFrameCount : Integer;

  FSingleCallOnly: Boolean;

  procedure AppIdle(Sender: TObject; var Done: Boolean);
  procedure SetSpeed(Value: Single);
  procedure SetMaxFPS(Value: Integer);
 public
  { Average time (in milliseconds) calculated between previous frame and the
    current one. This can be a direct indicator of rendering performance as it
    indicates how much time it takes on average to render (and possibly
    process) the frame. This parameter is typically updated much more
    frequently than @link(FrameRate). }
  property Latency: PreciseFloat read FLatency;

  { The current frame rate in frames per second. This value is calculated
    approximately two times per second and can only be used for informative
    purposes (e.g. displaying frame rate in the application). For precise
    real-time indications it is recommended to use @link(Latency) property
    instead. }
  property FrameRate: Integer read FFrameRate;

  { The speed of constant processing and animation control in frames per
    second. This affects both @link(Delta) property and occurence of
    @link(OnProcess) event. }
  property Speed: Single read FSpeed write SetSpeed;

  { The maximum allowed frame rate at which @link(OnTimer) should be
    executed. This value is an approximate and the resulting frame rate may
    be quite different (the resolution can be as low as 10 ms). It should be
    used with reasonable values to prevent the application from using 100% of
    CPU and GPU with unnecessarily high frame rates such as 1000 FPS. A
    reasonable and default value for this property is 200. }
  property MaxFPS: Integer read FMaxFPS write SetMaxFPS;

  { Determines whether the timer is enabled or not. The internal processing
    may still be occurring independently of this value, but it controls
    whether @link(OnTimer) event occurs or not. }
  property Enabled: Boolean read FEnabled write FEnabled;

  { If this property is set to @True, it will prevent the timer from trying to
    fix situations where the rendering speed is slower than the processing
    speed (that is, @link(FrameRate) is lower than @link(Speed)). Therefore,
    faster rendering produces constant speed, while slower rendering slows the
    processing down. This is particularly useful for dedicated servers that do
    no rendering but only processing; in this case, the processing cannot be
    technically any faster than it already is.}
  property SingleCallOnly: Boolean read FSingleCallOnly write FSingleCallOnly;

  { This event occurs when @link(Enabled) is set to @True and as fast as
    possible (only limited approximately by @link(MaxFPS)). In this event, all
    rendering should be made. Inside this event, at some location it is
    recommended to call @link(Process) method, which will invoke
    @link(OnProcess) event for constant object movement and animation control.
    The idea is to render graphics as fast as possible while moving objects
    and controlling animation at constant speed. }
  property OnTimer: TNotifyEvent read FOnTimer write FOnTimer;

  { This event occurs when calling @link(Process) method inside @link(OnTimer)
    event. In this event all constant object movement and animation control
    should be made. This event can occur more than once for each call to
    @link(Process) or may not occur, depending on the current @link(FrameRate)
    and @link(Speed). For instance, when frame rate is 120 FPS and speed set
    to 60, this event will occur for each second call to @code(Process); on
    the other hand, if frame rate is 30 FPS with speed set to 60, this event
    will occur twice for each call to @code(Process) to maintain constant
    processing. An alternative to this is doing processing inside
    @link(OnTimer) event using @link(Delta) as coefficient for object
    movement. If the processing takes too much time inside this event so that
    the target speed cannot be achieved, the timer may stall (that is, reduce
    number of occurences of this event until the balance is restored). }
  property OnProcess: TNotifyEvent read FOnProcess write FOnProcess;

  { This method should only be called from within @link(OnTimer) event to do
    constant object movement and animation control. Each time this method is
    called, @link(OnProcess) event may (or may not) occur depending on the
    current rendering frame rate (see @link(FrameRate)) and the desired
    processing speed (see @link(Speed)). The only thing that is assured is
    that @link(OnProcess) event will occur exactly @link(Speed) times per
    second no matter how fast @link(OnTimer) occurs (that is, the value of
    @link(FrameRate)). }
  procedure Process();

  { Resets internal structures of the timer and starts over the timing
    calculations. This can be useful when a very time-consuming task was
    executed inside @link(OnTimer) event that only occurs once. Normally, it
    would stall the timer making it think that the processing takes too long
    or the rendering is too slow; calling this method will tell the timer that
    it should ignore the situation and prevent the stall. }
  procedure Reset();

  {@exclude}constructor Create();
 end;

//---------------------------------------------------------------------------
var
{ Instance of @link(TAsphyreTimer) that is ready to use in applications
  without having to create that class explicitly. }
 Timer: TAsphyreTimer{$ifndef PasDoc} = nil{$endif};

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Timing;

//---------------------------------------------------------------------------
const
// Maximum number of processing ticks that can be added to delta accumulator.
// In cases where the time elapsed between sequential frames is many times
// higher than the desired frame rate, instead of calling huge number of
// processing calls the number is limited to this value. This particularly
// helps when actual processing takes too long so that even sacrificing
// rendering frames does not help, it will not overhelm the application and
// make it unresponsive.
 DeltaIncreaseLimit = 8.0;

//...........................................................................

// Minimal number of milliseconds required to pass before calculating
// user-given frame rate.
 SlowSampleTimeMax = 1000.0;

//...........................................................................

// Minimal number of milliseconds required to pass before calculating
// internal latency required for render-independent processing.
 QuickSampleTimeMax = 1.0;

//---------------------------------------------------------------------------
constructor TAsphyreTimer.Create();
begin
 inherited;

 Speed := 60.0;
 MaxFPS:= 4000;

 Application.OnIdle:= AppIdle;

 QuickSampleTime:= Timing.GetTimeValue();
 SlowSampleTime := QuickSampleTime;
 QuickFrameCount:= 0;
 SlowFrameCount := 0;

 FFrameRate:= 0;
 FLatency  := 0.0;
 DeltaAccum:= 0.0;
 Processed := False;

 FSingleCallOnly:= False;
end;

//---------------------------------------------------------------------------
procedure TAsphyreTimer.SetSpeed(Value: Single);
begin
 FSpeed:= Value;
 if (FSpeed < 1.0) then FSpeed:= 1.0;

 ProcessTimeScale:= FSpeed / 1000.0;
end;

//---------------------------------------------------------------------------
procedure TAsphyreTimer.SetMaxFPS(Value: Integer);
begin
 FMaxFPS:= Value;
 if (FMaxFPS < 1) then FMaxFPS:= 1;

 MinInvokeInterval:= 1000.0 / FMaxFPS;
end;

//---------------------------------------------------------------------------
procedure TAsphyreTimer.AppIdle(Sender: TObject; var Done: Boolean);
var
 WaitAmount: Integer;
 Delta, CurSampleTime, QuickSampleDiff, SlowSampleDiff: PreciseFloat;
begin
 Done:= False;

 CurSampleTime:= Timing.GetTimeValue();

 // If Timer is disabled, wait a little to avoid using 100% of CPU.
 if (not FEnabled) then
  begin
   QuickSampleTime:= CurSampleTime;
   SlowSampleTime := CurSampleTime;
   QuickFrameCount:= 0;
   SlowFrameCount := 0;

   Timing.Sleep(5);
   Exit;
  end;

 // If wrap-around occurs, consider this frame unreliable and skip it.
 if (CurSampleTime < QuickSampleTime)or(CurSampleTime < SlowSampleTime) then
  begin
   Reset();
   Exit;
  end;

 Inc(QuickFrameCount);
 Inc(SlowFrameCount);

 QuickSampleDiff:= CurSampleTime - QuickSampleTime;
 SlowSampleDiff := CurSampleTime - SlowSampleTime;

 if (SlowSampleDiff >= SlowSampleTimeMax) then
  begin
   FFrameRate:= Round((1000.0 * SlowFrameCount) / SlowSampleDiff);

   SlowSampleTime:= CurSampleTime;
   SlowFrameCount:= 0;
  end;

 if (QuickSampleDiff >= QuickSampleTimeMax) then
  begin
   if (QuickFrameCount > 0) then
    FLatency:= QuickSampleDiff / QuickFrameCount
     else FLatency:= 0.0;

   Delta:= QuickSampleDiff * ProcessTimeScale;

   // Provide Delta limit to prevent auto-loop lockup.
   if (Delta > DeltaIncreaseLimit) then Delta:= DeltaIncreaseLimit;

   if (Processed) then
    begin
     DeltaAccum:= DeltaAccum + Delta;
     Processed:= False;
    end;

   QuickSampleTime:= CurSampleTime;
   QuickFrameCount:= 0;
  end;

 if (Assigned(FOnTimer)) then FOnTimer(Self);

 if (MinInvokeInterval > QuickSampleTimeMax + 1.0) then
  begin
   CurSampleTime:= Timing.GetTimeValue();
   if (CurSampleTime < QuickSampleTime)or(CurSampleTime < SlowSampleTime) then
    begin
     Reset();
     Exit;
    end;

   QuickSampleDiff:= CurSampleTime - QuickSampleTime;

   if (QuickSampleDiff < MinInvokeInterval) then
    begin
     WaitAmount:= Round(MinInvokeInterval - QuickSampleDiff);
     if (WaitAmount > 0) then Timing.Sleep(WaitAmount);
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreTimer.Process();
var
 i, InvokeCount: Integer;
begin
 Processed:= True;

 InvokeCount:= Trunc(DeltaAccum);
 if (InvokeCount < 1) then Exit;

 if (FSingleCallOnly) then
  begin
   InvokeCount:= 1;
   DeltaAccum:= 0.0;
  end;

 if (Assigned(FOnProcess)) then
  for i:= 1 to InvokeCount do
   FOnProcess(Self);

 DeltaAccum:= Frac(DeltaAccum);
end;

//---------------------------------------------------------------------------
procedure TAsphyreTimer.Reset();
begin
 DeltaAccum:= 0.0;

 QuickSampleTime:= Timing.GetTimeValue();
 SlowSampleTime := QuickSampleTime;
 QuickFrameCount:= 0;
 SlowFrameCount := 0;
end;

//---------------------------------------------------------------------------
initialization
 Timer:= TAsphyreTimer.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(Timer);

//---------------------------------------------------------------------------
end.

