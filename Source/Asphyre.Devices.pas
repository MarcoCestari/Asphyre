unit Asphyre.Devices;
//---------------------------------------------------------------------------
// Asphyre Device Abstract declaration.
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
{< Hardware device specification that handles creation of back buffers, swap
   chains and other administrative tasks. This device plays primordial part
   in communication between the application and hardware-specific
   implementation of each particular provider. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.SysUtils, System.Classes, Asphyre.TypeDef, Asphyre.Math, 
 Asphyre.Textures, Asphyre.SwapChains;

//---------------------------------------------------------------------------
type
{ The current state of the device. }
 TAsphyreDeviceState = (
  { The device has not yet been initialized. @br @br }
  adsNotActive,

  { The device has been initialized and is working properly. @br @br }
  adsActive,

  { Initialization was attempted for this device but failed. Before attempting
    another initialization, @code(ResetInitFailed) must be called
    first. @br @br }
  adsInitFailed,

  { Run-time failure occurred while working with the device. The device is no
    longer in stable state and should be finalized as soon as possible to
    prevent major issues from occurring. @br @br }
  adsRunTimeFault,

  { The device is currently being initialized. This state can be detected
    inside device's creation events and it means that the device has not
    finished initialization phase yet. The application must be very cautious
    with any device-related calls while the device is in this state. }
  adsCreating);

//---------------------------------------------------------------------------
{ Type of technology that is being used in Asphyre device. }
 TAsphyreDeviceTechnology = (
  { The technology has not yet been established. }
  adtUnknown,

  { Microsoft DirectX technology is being used. }
  adtDirectX,

  { OpenGL by Khronos Group is being used. }
  adtOpenGL,

  { OpenGL ES by Khronos Group is being used. }
  adtOpenGL_ES,

  { Private propietary technology is being used. }
  adtPropietary);

//---------------------------------------------------------------------------
{ Hardware device wrapper that handles communication between application and
  the video card. The device must be created from Asphyre factory and is one
  of the first objects that needs to be initialized before working with any
  other components. }
 TAsphyreDevice = class
 private
  FSwapChains: TAsphyreSwapChains;

  FFillDepthValue  : Single;
  FFillStencilValue: Cardinal;
 protected
  FTechnology: TAsphyreDeviceTechnology;
  FTechVersion: Integer;
  FTechFeatureVersion: Integer;
  FState: TAsphyreDeviceState;
  FDeviceScale: Single;

  function InitDevice(): Boolean; virtual; abstract;
  procedure DoneDevice(); virtual; abstract;
  procedure ResetDevice(); virtual;

  function MayRender(SwapChainIndex: Integer): Boolean; virtual;

  procedure RenderWith(SwapChainIndex: Integer; Handler: TNotifyEvent;
   Background: Cardinal); virtual; abstract;

  procedure RenderToTarget(Handler: TNotifyEvent;
   Background: Cardinal; FillBk: Boolean); virtual; abstract;

  function ResizeSwapChain(SwapChainIndex: Integer;
   NewUserDesc: PSwapChainDesc): Boolean; virtual;

  procedure ClearDevStates(); virtual;
 public
  { The list of swap chains that will be used for rendering into. In a typical
    scenario at least one swap chain must be added to this list for device
    initialization to succeed. In FireMonkey applications the swap chains
    are not used and will be ignored by the device. }
  property SwapChains: TAsphyreSwapChains read FSwapChains;

  //.........................................................................
  { The current state of the device. If the device is not in working state,
    any rendering calls may fail either silently or returning @False. }
  property State: TAsphyreDeviceState read FState;

  //.........................................................................
  { Indicates the type of technology that is currently being used. }
  property Technology: TAsphyreDeviceTechnology read FTechnology;

  //.........................................................................
  { Indicates the version of current technology that is currently being used.
    The values are specified in hexadecimal format. That is, a value of $100
    indicates version 1.0, while a value of $247 would indicate version
    2.4.7. This value is used in combination with @link(Technology), so if
    @code(Technology) is set to @italic(adtDirectX) and this value is set to
    $A10, it means that @italic(DirectX 10.1) is being used.  }
  property TechVersion: Integer read FTechVersion;

  //.........................................................................
  { Indicates the feature level version of current technology that is
    currently being used. The difference between this parameter and
    @link(TechVersion) is that the second parameter indicates type of
    technology being used (for example, DirectX 10), while this one
    indicates the level of features available (for example, DirectX 9.0c).
    The values here are specified in hexadecimal format. That is, a value of
    $213 would indicate version 2.1.3. }
  property TechFeatureVersion: Integer read FTechFeatureVersion;

  //.........................................................................
  { Indicates the current scale of device display. This is typically used on
    Retina displays to provide mapping between logical and pixel units. For
    example, if DisplayScale is 2, then the screen has twice pixel density for
    each logical unit. }
  property DeviceScale: Single read FDeviceScale write FDeviceScale;

  //.........................................................................
  { The value that should be used for setting depth buffer either on the
    screen or the currently used rendering target. }
  property FillDepthValue: Single read FFillDepthValue
   write FFillDepthValue;

  //.........................................................................
  { The value that should be used for setting stencil buffer either on the
    screen or the currently used rendering target. }
  property FillStencilValue: Cardinal read FFillStencilValue
   write FFillStencilValue;

  //.........................................................................
  { Initializes the device using the swap chain information provided in
    @link(SwapChains) and prepares it for rendering. If the call succeeds,
    @True is returned and @False otherwise. This method should be used in
    native Windows applications only. For FireMonkey applications,
    @link(Connect) should be used instead. }
  function Initialize(): Boolean;

  //.........................................................................
  { Finalizes the device releasing all its resources and handles. User-created
    content that is not handled automatically by Asphyre should be released
    before calling this method. }
  procedure Finalize();

  //.........................................................................
  { In native Windows applications, this function initializes the device in
    the same fashion as @link(Initialize). In FireMonkey applications, this
    function hooks the device into FireMonkey's context so Asphyre can use
    it for its own rendering. }
  function Connect(): Boolean;

  //.........................................................................
  { In native Windows applications, this function finalizes the device in
    the same fashion as @link(Finalize). In FireMonkey applications, this
    function unhooks the device from FireMonkey's context. Any created
    resources that are not handled by Asphyre should be released before
    calling this. }
  procedure Disconnect();

  //.........................................................................
  { Begins rendering scene to the first swap chain described in
    @link(SwapChains), clears the back-buffer with the given background color
    and values stored in @link(FillDepthValue)/@link(FillStencilValue), and
    calls the provided event handler, where the actual rendering should be
    made. }
  procedure Render(Handler: TNotifyEvent; Background: Cardinal); overload;

  //.........................................................................
  { Begins rendering scene to the swap chain identified by its index described
    in @link(SwapChains), clears the back-buffer with the given background
    color and values stored in @link(FillDepthValue)/@link(FillStencilValue),
    and calls the provided event handler, where the actual rendering should be
    made. The first swap chain has index of zero. If the provided index is
    outside of valid range, this method does nothing. }
  procedure Render(SwapChainIndex: Integer; Handler: TNotifyEvent;
   Background: Cardinal); overload;

  //.........................................................................
  { Begins rendering scene on the specified render target texture. If @code(FillBk)
    is set to @True, the render target is cleared using the given background
    color and values stored in @link(FillDepthValue)/@link(FillStencilValue).
    This method calls the provided event handler, where the actual rendering
    should be made. The render target texture must be property created and
    initialized before calling this method. If there is a problem starting the
    rendering to the given render target, this method will silently fail and
    the given event handler will not be called. }
  procedure RenderTo(Handler: TNotifyEvent; Background: Cardinal;
   FillBk: Boolean; Texture: TAsphyreRenderTargetTexture);

  //.........................................................................
  { Changes size of the back-buffer tied to swap chain identified by the
    given index. The first swap chain has index of zero. If the index is
    outside of valid range or the swap chain cannot be resized, the returned
    value is @False and the size of swap chain remains unchanged. If this
    method succeeds, the swap chain will have its size updated and @True will
    be returned. In some providers this may cause device to be reset and some
    resources to be recreated, so any resources that are not handled by Asphyre
    should be released before calling this; the best way to handle this
    scenario is to subscribe to @code(EventDeviceReset) and
    @code(EventDeviceLost) events provided in @code(Asphyre.Events.pas). }
  function Resize(SwapChainIndex: Integer; const NewSize: TPoint2px): Boolean;

  //.........................................................................
  { Returns @True if the device either failed to initialize or is in run-time
    fault state. If the device is working properly or has not yet been
    initialized, @False is returned. }
  function IsAtFault(): Boolean;

  //.........................................................................
  { Clears all textures, shaders and states currently bound to the device.
    This method works only on some modern providers. }
  procedure ClearStates();

  //.........................................................................
  { Resets the failed state of the device, which is usually set when
    the initialization has failed. This must be done explicitly to
    acknowledge that the application is aware of the situation. }
  procedure ResetInitFailed();

  {@exclude}constructor Create(); virtual;
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{ Returns a readable text string with the name of the specified device
  technology. }
function DeviceTechnologyToString(
 Technology: TAsphyreDeviceTechnology): StdString;

//---------------------------------------------------------------------------
{ Converts device version value originally specified in hexadecimal format
  (e.g. $324) into a readable text string describing that version
  (e.g. "3.2.4"). If @italic(CompactForm) form parameter is set to @true,
  the version text is reduced for trailing zeros, so a text like "3.0" becomes
  just "3". }
function DeviceVersionToString(Value: Integer;
 CompactForm: Boolean = False): StdString;

//---------------------------------------------------------------------------
{ Returns a readable text string that describes the current device's
  technology, technology version and feature level version. This information
  can be used for informative purposes. }
function GetFullDeviceTechString(Device: TAsphyreDevice): StdString;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Events, Asphyre.Timing;

//---------------------------------------------------------------------------
function DeviceTechnologyToString(
 Technology: TAsphyreDeviceTechnology): StdString;
begin
 case Technology of
  adtDirectX:
   Result:= 'DirectX';

  adtOpenGL:
   Result:= 'OpenGL';

  adtOpenGL_ES:
   Result:= 'OpenGL ES';

  adtPropietary:
   Result:= 'Propietary';

  else Result:= 'Unknown';
 end;
end;

//---------------------------------------------------------------------------
function DeviceVersionToString(Value: Integer;
 CompactForm: Boolean = False): StdString;
begin
 if (Value <= 0) then
  begin
   Result:= '0.0';
   Exit;
  end;

 Result:= '';

 if (Value and $00F > 0) then
  Result:= '.' + IntToStr(Value and $00F);

 if (not CompactForm)or(Value and $0F0 > 0) then
  Result:= '.' + IntToStr((Value and $0F0) shr 4) + Result;

 Result:= IntToStr(Value shr 8) + Result;
end;

//---------------------------------------------------------------------------
function GetFullDeviceTechString(Device: TAsphyreDevice): StdString;
begin
 if (not Assigned(Device))or(Device.Technology = adtUnknown) then
  begin
   Result:= 'Unidentified device technology.';
   Exit;
  end;

 Result:= DeviceTechnologyToString(Device.Technology);

 if (Device.TechVersion > 0) then
  Result:= Result + #32 + DeviceVersionToString(Device.TechVersion, True);

 if (Device.Technology = adtDirectX)and(Device.TechVersion = $900) then
  begin // DirectX 9 specific.
   if (Device.TechFeatureVersion = $901) then
    Result:= Result + ' Ex (Vista)'
     else Result:= Result + ' (XP compatibility)';
  end else
  begin // General feature levels.
   if (Device.TechFeatureVersion > 0) then
    Result:= Result + ' (feature level ' +
     DeviceVersionToString(Device.TechFeatureVersion) + ')';
  end;
end;

//---------------------------------------------------------------------------
constructor TAsphyreDevice.Create();
begin
 FTechnology := adtUnknown;
 FTechVersion:= 0;
 FTechFeatureVersion:= 0;
 FDeviceScale:= 1.0;

 inherited;

 Inc(AsphyreClassInstances);

 FSwapChains:= TAsphyreSwapChains.Create(Self);
 FState:= adsNotActive;

 FFillDepthValue  := 1.0;
 FFillStencilValue:= 0;
end;

//---------------------------------------------------------------------------
destructor TAsphyreDevice.Destroy();
begin
 Dec(AsphyreClassInstances);

 Finalize();

 inherited;

 FreeAndNil(FSwapChains);
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.Initialize(): Boolean;
begin
 Result:= (FState = adsNotActive)and(FSwapChains.Count > 0);
 if (not Result) then Exit;

 FState:= adsCreating;

 Result:= InitDevice();
 if (not Result) then Exit;

 FState:= adsActive;

 EventDeviceCreate.Notify(Self, @Result);
 if (not Result) then
  begin
   DoneDevice();

   FState:= adsNotActive;
   Exit;
  end;

 EventDeviceReset.Notify(Self, @Result);
 if (not Result) then
  begin
   EventDeviceDestroy.Notify(Self);
   DoneDevice();

   FState:= adsNotActive;
   Exit;
  end;

 EventTimerReset.Notify(Self);
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.Finalize();
begin
 if (not (FState in [adsActive, adsRunTimeFault])) then Exit;

 ClearStates();

 EventDeviceLost.Notify(Self);
 EventDeviceDestroy.Notify(Self);

 DoneDevice();

 FState:= adsNotActive;
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.IsAtFault(): Boolean;
begin
 Result:= FState in [adsInitFailed, adsRunTimeFault];
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.ResetDevice();
begin
 // no code
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.MayRender(SwapChainIndex: Integer): Boolean;
begin
 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.Render(Handler: TNotifyEvent;
 Background: Cardinal);
begin
 if (FState = adsActive)and(MayRender(0)) then
  RenderWith(0, Handler, Background)
   else Timing.Sleep(5);
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.Render(SwapChainIndex: Integer; Handler: TNotifyEvent;
 Background: Cardinal);
begin
 if (FState = adsActive)and(MayRender(SwapChainIndex)) then
  RenderWith(SwapChainIndex, Handler, Background)
   else Timing.Sleep(5);
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.RenderTo(Handler: TNotifyEvent;
 Background: Cardinal; FillBk: Boolean;
 Texture: TAsphyreRenderTargetTexture);
begin
 if (FState <> adsActive)or(not MayRender(-1))or(not Assigned(Texture)) then Exit;

 if (not Texture.BeginDrawTo()) then Exit;

 RenderToTarget(Handler, Background, FillBk);

 Texture.EndDrawTo();
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.Connect(): Boolean;
begin
 // (1) Check initial conditions.
 if (FState = adsActive) then
  begin
   Result:= True;
   Exit;
  end;

 if (FState = adsInitFailed) then
  begin
   Result:= False;
   Exit;
  end;

 Result:= True;

 // (2) Initialize device parameters.
 EventDeviceInit.Notify(Self, @Result);
 if (not Result) then Exit;

 FState:= adsCreating;

 // (3) Create and initialize the particular device.
 Result:= InitDevice();
 if (not Result) then
  begin
   FState:= adsInitFailed;
   EventTimerReset.Notify(Self);
   Exit;
  end;

 FState:= adsActive;

 // (4) Notify others that the device has been created.
 EventDeviceCreate.Notify(Self, @Result);
 if (not Result) then
  begin
   DoneDevice();
   FState:= adsInitFailed;

   EventTimerReset.Notify(Self);

   Exit;
  end;

 // (5) Notify others that the device is now in ready state.
 EventDeviceReset.Notify(Self, @Result);
 if (not Result) then
  begin
   EventDeviceDestroy.Notify(Self);
   DoneDevice();

   FState:= adsInitFailed;

   EventTimerReset.Notify(Self);
   Exit;
  end;

 // (6) Notify the timer that a lenghty operation took place.
 EventTimerReset.Notify(Self);
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.Disconnect();
begin
 Finalize();
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.ResetInitFailed();
begin
 if (FState = adsInitFailed) then FState:= adsNotActive;
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.ClearDevStates();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.ClearStates();
begin
 if (FState = adsActive) then ClearDevStates();
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.ResizeSwapChain(SwapChainIndex: Integer;
 NewUserDesc: PSwapChainDesc): Boolean;
begin
 Result:= True;
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.Resize(SwapChainIndex: Integer;
 const NewSize: TPoint2px): Boolean;
var
 UserDesc: PSwapChainDesc;
 PrevSize: TPoint2px;
begin
 UserDesc:= FSwapChains[SwapChainIndex];
 if (not Assigned(UserDesc))or(IsAtFault()) then
  begin
   Result:= False;
   Exit;
  end;

 if (UserDesc.Width = NewSize.x)and(UserDesc.Height = NewSize.y) then
  begin
   Result:= True;
   Exit;
  end;

 ClearStates();

 PrevSize.x:= UserDesc.Width;
 PrevSize.y:= UserDesc.Height;

 UserDesc.Width := NewSize.x;
 UserDesc.Height:= NewSize.y;

 if (FState <> adsNotActive) then
  begin
   Result:= ResizeSwapChain(SwapChainIndex, UserDesc);
   if (not Result) then
    begin
     UserDesc.Width := PrevSize.x;
     UserDesc.Height:= PrevSize.y;
    end;
  end else Result:= True;
end;

//---------------------------------------------------------------------------
end.
