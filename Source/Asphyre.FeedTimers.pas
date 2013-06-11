unit Asphyre.FeedTimers;
//---------------------------------------------------------------------------
// Asphyre platform independent timer with external interface.
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
   on a variety of platforms including Windows, Mac OS and iOS. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.Classes;

//---------------------------------------------------------------------------
type
{ The implementation of Asphyre's event-based multimedia timer running on
  a variety of platforms including Windows, Mac OS and iOS. This class is not
  independent, it requires the application to call @code(NotifyIdle) method,
  which will provide similar functionality of @link(TAsphyreTimer) class.}
 TAsphyreBridgedTimer = class
 private
  FMaxFPS : Integer;
  FSpeed  : Double;
  FEnabled: Boolean;
  FOnTimer: TNotifyEvent;

  FFrameRate: Integer;

  FOnProcess: TNotifyEvent;
  Processed : Boolean;

  PrevValue : Double;
  FLatency  : Double;
  FDelta    : Double;
  MinLatency: Double;
  SpeedLatency: Double;
  DeltaCounter: Double;

  SampleLatency: Double;
  SampleIndex: Integer;
  FSingleCallOnly: Boolean;

  function RetrieveLatency(): Double;
  procedure SetSpeed(const Value: Double);
  procedure SetMaxFPS(const Value: Integer);
 public
  { Movement differential between the current frame rate and the requested
    @link(Speed). Object movement and animation control can be made inside
    @link(OnTimer) event if all displacements are multiplied by this
    coefficient. For instance, if frame rate is 30 FPS and speed is set to 60,
    this coefficient will equal to 2.0, so objects moving at 30 FPS will have
    double displacement to match 60 FPS speed; on the other hand, if frame
    rate is 120 FPS with speed set to 60, this coefficient will equal to 0.5,
    to move objects two times slower. An easier and more straight-forward
    approach can be used with @link(OnProcess) event, where using this
    coefficient is not necessary. }
  property Delta: Double read FDelta;

  { The time (in milliseconds) calculated between previous frame and the
    current one. This can be a direct indicator of rendering performance as it
    indicates how much time it took to render (and possibly process) the
    frame. }
  property Latency: Double read FLatency;

  { The current frame rate in frames per second. This value is calculated
    approximately two times per second and can only be used for informative
    purposes (e.g. displaying frame rate in the application). For precise
    real-time indications it is recommended to use @link(Latency) property
    instead. }
  property FrameRate: Integer read FFrameRate;

  { The speed of constant processing and animation control in frames per
    second. This affects both @link(Delta) property and occurence of
    @link(OnProcess) event. }
  property Speed: Double read FSpeed write SetSpeed;

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
    and controlling animation at constant speed. Note that for this event to
    occur, it is necessary to call @link(NotifyIdle) at some point in the
    application for this timer to do the required calculations. }
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

  { This event should be called as fast as possible from within the main
    application for the timer to work. It can be either called when idle
    event occurs or from within system timer event. }
  procedure NotifyIdle();

  {@exclude}constructor Create();
 end;

//---------------------------------------------------------------------------
var
{ Instance of @link(TAsphyreBridgedTimer) that is ready to use in applications
  without having to create that class explicitly. }
 Timer: TAsphyreBridgedTimer{$ifndef PasDoc} = nil{$endif};

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Timing;

//---------------------------------------------------------------------------
const
 DeltaLimit = 8.0;

//---------------------------------------------------------------------------
constructor TAsphyreBridgedTimer.Create();
begin
 inherited;

 Speed := 60.0;
 MaxFPS:= 100;

 PrevValue:= Timing.GetTimeValue();

 FFrameRate   := 0;
 DeltaCounter := 0.0;
 SampleLatency:= 0.0;
 SampleIndex  := 0;
 Processed    := False;
 FSingleCallOnly:= False;
end;

//---------------------------------------------------------------------------
procedure TAsphyreBridgedTimer.SetSpeed(const Value: Double);
begin
 FSpeed:= Value;
 if (FSpeed < 1.0) then FSpeed:= 1.0;

 SpeedLatency:= 1000.0 / FSpeed;
end;

//---------------------------------------------------------------------------
procedure TAsphyreBridgedTimer.SetMaxFPS(const Value: Integer);
begin
 FMaxFPS:= Value;
 if (FMaxFPS < 1) then FMaxFPS:= 1;

 MinLatency:= 1000.0 / FMaxFPS;
end;

//---------------------------------------------------------------------------
function TAsphyreBridgedTimer.RetrieveLatency(): Double;
var
 CurValue: Double;
begin
 CurValue:= Timing.GetTimeValue();

 Result:= Abs(CurValue - PrevValue);

 PrevValue:= CurValue;
end;

//---------------------------------------------------------------------------
procedure TAsphyreBridgedTimer.NotifyIdle();
var
 WaitTime : Integer;
 SampleMax: Integer;
begin
 // (1) Retrieve current latency.
 FLatency:= RetrieveLatency();

 // (2) If Timer is disabled, wait a little to avoid using 100% of CPU.
 if (not FEnabled) then
  begin
   Timing.Sleep(5);
   Exit;
  end;

 // (3) Adjust to maximum FPS, if necessary.
 if (FLatency < MinLatency) then
  begin
   WaitTime:= Round(MinLatency - FLatency);
   if (WaitTime > 0) then Timing.Sleep(WaitTime);
  end else WaitTime:= 0;

 // (4) The running speed ratio.
 FDelta:= FLatency / SpeedLatency;
 // -> provide Delta limit to prevent auto-loop lockup.
 if (FDelta > DeltaLimit) then FDelta:= DeltaLimit;

 // (5) Calculate Frame Rate every second.
 SampleLatency:= SampleLatency + FLatency + WaitTime;
 if (FLatency <= 0) then SampleMax:= 4
  else SampleMax:= Round(1000.0 / FLatency);

 Inc(SampleIndex);
 if (SampleIndex >= SampleMax) then
  begin
   if (SampleLatency > 0) then
    FFrameRate:= Round((SampleIndex * 1000.0) / SampleLatency)
     else FFrameRate:= 0;

   SampleLatency:= 0.0;
   SampleIndex  := 0;
  end;

 // (6) Increase processing queque, if processing was made last time.
 if (Processed) then
  begin
   DeltaCounter:= DeltaCounter + FDelta;
   Processed:= False;
  end;

 // (7) Call Timer event.
 if (Assigned(FOnTimer)) then FOnTimer(Self);
end;

//---------------------------------------------------------------------------
procedure TAsphyreBridgedTimer.Process();
var
 i, Qty: Integer;
begin
 Processed:= True;

 Qty:= Trunc(DeltaCounter);
 if (Qty < 1) then Exit;

 if (FSingleCallOnly) then
  begin
   Qty:= 1;
   DeltaCounter:= 0.0;
  end;

 if (Assigned(FOnProcess)) then
  for i:= 1 to Qty do
   FOnProcess(Self);

 DeltaCounter:= Frac(DeltaCounter);
end;

//---------------------------------------------------------------------------
procedure TAsphyreBridgedTimer.Reset();
begin
 DeltaCounter:= 0.0;
 FDelta:= 0.0;

 RetrieveLatency();
end;

//---------------------------------------------------------------------------
initialization
 Timer:= TAsphyreBridgedTimer.Create();

//---------------------------------------------------------------------------
finalization
 Timer.Free;

//---------------------------------------------------------------------------
end.

