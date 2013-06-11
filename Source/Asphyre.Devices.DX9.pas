unit Asphyre.Devices.DX9;
//---------------------------------------------------------------------------
// Direct3D 9 device management for Asphyre.
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
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 Asphyre.D3D9, Winapi.Windows, System.Classes, Asphyre.Devices,
 Asphyre.Textures, Asphyre.SwapChains, Asphyre.SwapChains.DX9;

//---------------------------------------------------------------------------

// Remove the dot to preserve FPU state.
{$define PreserveFPU}

// Remove the dot to enable multi-threading mode.
{.$define EnableMultithread}

//---------------------------------------------------------------------------
type
 TDX9Device = class(TAsphyreDevice)
 private
  FDXSwapChains: TDX9SwapChains;

  ManagedDirect3D: Boolean;
  ManagedDevice: Boolean;

  UsingDepthBuf: Boolean;
  UsingStencil : Boolean;
  IsLostState  : Boolean;

  function CreateDirect3D(): Boolean;
  procedure DestroyDirect3D();

  function GetDisplayMode(): Boolean;
  function MakePresentParams(): Boolean;
  function CreateDevice(): Boolean;
  procedure DestroyDevice();

  procedure MoveIntoLostState();
  function AttemptRecoverState(): Boolean;
  function CheckDeviceCondition(SwapChainIndex: Integer): Boolean;

  procedure SetDefaultViewport(UserDesc: PSwapChainDesc);
  procedure Clear(Color: Cardinal);
 protected
  function InitDevice(): Boolean; override;
  procedure DoneDevice(); override;
  procedure ResetDevice(); override;

  function MayRender(SwapChainIndex: Integer): Boolean; override;

  procedure RenderWith(SwapChainIndex: Integer; Handler: TNotifyEvent;
   Background: Cardinal); override;

  procedure RenderToTarget(Handler: TNotifyEvent;
   Background: Cardinal; FillBk: Boolean); override;

  function ResizeSwapChain(SwapChainIndex: Integer;
   NewUserDesc: PSwapChainDesc): Boolean; override;
 public
  property DXSwapChains: TDX9SwapChains read FDXSwapChains;

  constructor Create(); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifdef FireMonkey}
 FMX.Platform.Win, FMX.Types,
{$endif}

 System.SysUtils, Asphyre.Types.DX9, Asphyre.Events;

//---------------------------------------------------------------------------
constructor TDX9Device.Create();
begin
 inherited;

 FTechnology := adtDirectX;
 FTechVersion:= $900;

 FDXSwapChains:= TDX9SwapChains.Create();

 ManagedDirect3D:= False;
 ManagedDevice:= False;
end;

//---------------------------------------------------------------------------
destructor TDX9Device.Destroy();
begin
 inherited;

 FreeAndNil(FDXSwapChains);
end;

//---------------------------------------------------------------------------
function TDX9Device.CreateDirect3D(): Boolean;
{$ifndef FireMonkey}
var
 D3D9ObjectEx: IDirect3D9Ex;
{$endif}
begin
 ManagedDirect3D:= False;

 if (Assigned(D3D9Object)) then
  begin
   D3D9Mode:= dmDirect3D9;
   FTechFeatureVersion:= $900;

   if (Supports(D3D9Object, IDirect3D9Ex)) then
    begin
     D3D9Mode:= dmDirect3D9Ex;
     FTechFeatureVersion:= $901;
    end;

   Result:= True;
   Exit;
  end;

 LoadDirect3D9();

{$ifndef FireMonkey}
 if (D3D9Mode <> dmDirect3D9)and(Assigned(Direct3DCreate9Ex)) then
  begin
   Result:= Succeeded(Direct3DCreate9Ex(D3D_SDK_VERSION, D3D9ObjectEx));

   if (Result) then
    begin
     D3D9Object:= D3D9ObjectEx;
     D3D9Mode:= dmDirect3D9Ex;
     FTechFeatureVersion:= $901;
    end;
  end;
{$endif}

 if (not Assigned(D3D9Object)) then
  begin
   D3D9Object:= Direct3DCreate9(D3D_SDK_VERSION);

   if (Assigned(D3D9Object)) then
    begin
     D3D9Mode:= dmDirect3D9;
     FTechFeatureVersion:= $900;
    end;
  end;

 Result:= Assigned(D3D9Object);

 if (Result) then
  ManagedDirect3D:= True;
end;

//---------------------------------------------------------------------------
procedure TDX9Device.DestroyDirect3D();
begin
 if (ManagedDirect3D) then
  begin
   if (Assigned(D3D9Object)) then D3D9Object:= nil;
   ManagedDirect3D:= False;
  end;

 D3D9Mode:= dmUnknown;
 FTechFeatureVersion:= 0;
end;

//---------------------------------------------------------------------------
function TDX9Device.GetDisplayMode(): Boolean;
var
 CompMode: D3DDISPLAYMODE;
begin
 Result:= Assigned(D3D9Object);
 if (not Result) then Exit;

 ClearD3D9DisplayMode();

 if (D3D9Mode = dmDirect3D9Ex) then
  begin // Vista enhanced mode.
   Result:= Succeeded(IDirect3D9Ex(D3D9Object).GetAdapterDisplayModeEx(
    D3DADAPTER_DEFAULT, @D3D9DisplayMode, nil));
  end else
  begin // XP compatibility mode.
   Result:= Succeeded(D3D9Object.GetAdapterDisplayMode(D3DADAPTER_DEFAULT,
    CompMode));

   if (Result) then
    begin
     D3D9DisplayMode.Width:= CompMode.Width;
     D3D9DisplayMode.Height:= CompMode.Height;
     D3D9DisplayMode.RefreshRate:= CompMode.RefreshRate;
     D3D9DisplayMode.Format:= CompMode.Format;
    end;
  end;
end;

//---------------------------------------------------------------------------
function TDX9Device.MakePresentParams(): Boolean;
var
 SwapChain: PSwapChainDesc;
begin
 SwapChain:= SwapChains[0];

 Result:= Assigned(SwapChain);
 if (not Result) then Exit;

 with D3D9PresentParams do
  begin
   BackBufferWidth := SwapChain.Width;
   BackBufferHeight:= SwapChain.Height;

   Windowed  := True;
   SwapEffect:= D3DSWAPEFFECT_DISCARD;

  {$ifdef FireMonkey}
   hDeviceWindow:= WindowHandleToPlatform(TWindowHandle(SwapChain.WindowHandle)).Wnd;
  {$else}
   hDeviceWindow:= SwapChain.WindowHandle;
  {$endif}

   PresentationInterval:= D3DPRESENT_INTERVAL_IMMEDIATE;

   if (SwapChain.VSync) then
    PresentationInterval:= D3DPRESENT_INTERVAL_ONE;

   BackBufferFormat:= DX9FindBackBufferFormat(SwapChain.Format);

   if (SwapChain.DepthStencil <> dstNone) then
    begin
     EnableAutoDepthStencil:= True;
     Flags:= D3DPRESENTFLAG_DISCARD_DEPTHSTENCIL;

     AutoDepthStencilFormat:=
      DX9FindDepthStencilFormat(Integer(SwapChain.DepthStencil));
    end;

   DX9FindBestMultisampleType(BackBufferFormat, AutoDepthStencilFormat,
    SwapChain.Multisamples, MultiSampleType, MultiSampleQuality);
  end;

 UsingDepthBuf:= SwapChain.DepthStencil > dstNone;
 UsingStencil := SwapChain.DepthStencil > dstDepthOnly;
end;

//---------------------------------------------------------------------------
function TDX9Device.CreateDevice(): Boolean;
var
 Flags: Cardinal;
 SwapChain: PSwapChainDesc;
 DeviceEx:  IDirect3DDevice9Ex;
begin
 ManagedDevice:= False;

 // (1) Verify whether the device has already been created.
 if (Assigned(D3D9Device)) then
  begin
   if (D3D9Mode = dmUnknown) then
    begin
     D3D9Mode:= dmDirect3D9;

     if (Supports(D3D9Device, IDirect3DDevice9Ex)) then
      D3D9Mode:= dmDirect3D9Ex;
    end;

   Result:= Succeeded(D3D9Device.GetDeviceCaps(D3D9Caps));
   Exit;
  end;

 // (2) Check starting conditions.
 Result:= False;
 if (not Assigned(D3D9Object)) then Exit;

 SwapChain:= SwapChains[0];
 if (not Assigned(SwapChain)) then Exit;

 // (3) Prepare the device flags.
 Flags:= D3DCREATE_NOWINDOWCHANGES;

{$ifdef PreserveFPU}
 Flags:= Flags or D3DCREATE_FPU_PRESERVE;
{$endif}

{$ifdef EnableMultithread}
 Flags:= Flags or D3DCREATE_MULTITHREADED;
{$endif}

 // (4) Create Direct3D9 device.
 if (D3D9Mode = dmDirect3D9Ex) then
  begin // Vista enhanced mode.
   Result:= Succeeded(IDirect3D9Ex(D3D9Object).CreateDeviceEx(
    D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, SwapChain.WindowHandle, Flags or
    D3DCREATE_HARDWARE_VERTEXPROCESSING, @D3D9PresentParams, nil, DeviceEx));

   if (not Result) then
    Result:= Succeeded(IDirect3D9Ex(D3D9Object).CreateDeviceEx(
     D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, SwapChain.WindowHandle, Flags or
     D3DCREATE_SOFTWARE_VERTEXPROCESSING, @D3D9PresentParams, nil, DeviceEx));

   if (Result) then
    begin
     D3D9Device:= DeviceEx;
     DeviceEx:= nil;
    end;
  end else
  begin // XP compatibility mode.
   Result:= Succeeded(D3D9Object.CreateDevice(D3DADAPTER_DEFAULT,
    D3DDEVTYPE_HAL, SwapChain.WindowHandle, Flags or
    D3DCREATE_HARDWARE_VERTEXPROCESSING, @D3D9PresentParams, D3D9Device));

   if (not Result) then
    Result:= Succeeded(D3D9Object.CreateDevice(D3DADAPTER_DEFAULT,
     D3DDEVTYPE_HAL, SwapChain.WindowHandle, Flags or
     D3DCREATE_SOFTWARE_VERTEXPROCESSING, @D3D9PresentParams, D3D9Device));
  end;

 // (5) Retrieve the capabilities of the device.
 if (Result) then
  begin
   Result:= Succeeded(D3D9Device.GetDeviceCaps(D3D9Caps));
   if (not Result) then D3D9Device:= nil;
  end;

 // (6) Update the description of the first swap chain.
 if (Result) then
  begin
   SwapChain.Format:= DX9FormatToAsphyre(D3D9PresentParams.BackBufferFormat);
   SwapChain.Multisamples:= Integer(D3D9PresentParams.MultiSampleType);
  end;

 ManagedDevice:= Result;
end;

//---------------------------------------------------------------------------
procedure TDX9Device.DestroyDevice();
begin
 if (ManagedDevice) then
  begin
   ClearD3D9Caps();
   if (Assigned(D3D9Device)) then D3D9Device:= nil;

   ManagedDevice:= False;
  end;
end;

//---------------------------------------------------------------------------
function TDX9Device.InitDevice(): Boolean;
begin
 Result:= CreateDirect3D();
 if (not Result) then Exit;

 Result:= GetDisplayMode();
 if (not Result) then
  begin
   DestroyDirect3D();
   Exit;
  end;

 Result:= MakePresentParams();
 if (not Result) then
  begin
   ClearD3D9PresentParams();
   ClearD3D9DisplayMode();
   DestroyDirect3D();
   Exit;
  end;

 Result:= CreateDevice();
 if (not Result) then
  begin
   ClearD3D9PresentParams();
   ClearD3D9DisplayMode();
   DestroyDirect3D();
   Exit;
  end;

 Result:= FDXSwapChains.CreateAll(SwapChains);
 if (not Result) then
  begin
   DestroyDevice();
   ClearD3D9PresentParams();
   ClearD3D9DisplayMode();
   DestroyDirect3D();
   Exit;
  end;

 IsLostState:= False;
end;

//---------------------------------------------------------------------------
procedure TDX9Device.DoneDevice();
begin
 FDXSwapChains.RemoveAll();

 DestroyDevice();
 ClearD3D9PresentParams();
 ClearD3D9DisplayMode();
 DestroyDirect3D();
end;

//---------------------------------------------------------------------------
procedure TDX9Device.MoveIntoLostState();
begin
 if (not IsLostState) then
  begin
   EventDeviceLost.Notify(Self);
   FDXSwapChains.RemoveAll();
   IsLostState:= True;
  end;
end;

//---------------------------------------------------------------------------
function TDX9Device.AttemptRecoverState(): Boolean;
begin
 Result:= Assigned(D3D9Device);
 if (not Result) then Exit;

 if (IsLostState) then
  begin
   if (D3D9Mode = dmDirect3D9Ex) then
    begin // Vista enhanced mode.
     Result:= Succeeded(IDirect3DDevice9Ex(D3D9Device).ResetEx(
      D3D9PresentParams, nil));
    end else
    begin // XP compatibility mode.
     Result:= Succeeded(D3D9Device.Reset(D3D9PresentParams));
    end;

   if (Result) then
    begin
     Result:= FDXSwapChains.CreateAll(SwapChains);
     if (not Result) then
      begin
       FState:= adsRunTimeFault;
       Exit;
      end;

     IsLostState:= False;
     EventDeviceReset.Notify(Self);
    end;
  end;
end;

//---------------------------------------------------------------------------
function TDX9Device.CheckDeviceCondition(SwapChainIndex: Integer): Boolean;
var
 UserDesc: PSwapChainDesc;
 Res: HResult;
begin
 Result:= Assigned(D3D9Device);
 if (not Result) then Exit;

 if (D3D9Mode = dmDirect3D9Ex) then
  begin // Vista enhanced mode.
   Result:= True;
   if (SwapChainIndex = -1) then Exit;

   UserDesc:= SwapChains[SwapChainIndex];
   if (not Assigned(UserDesc)) then Exit;

   Result:= Succeeded(IDirect3DDevice9Ex(D3D9Device).CheckDeviceState(
    UserDesc.WindowHandle));

   if (not Result) then
    begin
     MoveIntoLostState();
     Result:= AttemptRecoverState();
    end;
  end else
  begin // XP compatibility mode.
   Res:= D3D9Device.TestCooperativeLevel();

   case Res of
    D3DERR_DEVICELOST:
     begin
      MoveIntoLostState();
      Result:= False;
     end;

    D3DERR_DEVICENOTRESET:
     begin
      if (not IsLostState) then MoveIntoLostState();
      Result:= AttemptRecoverState();
     end;

    D3DERR_DRIVERINTERNALERROR:
     begin
      MoveIntoLostState();
      Result:= AttemptRecoverState();
     end;

    D3D_OK:
     Result:= True;

    else Result:= False;
   end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX9Device.ResetDevice();
begin
 MoveIntoLostState();
 AttemptRecoverState();
end;

//---------------------------------------------------------------------------
function TDX9Device.MayRender(SwapChainIndex: Integer): Boolean;
begin
 Result:= CheckDeviceCondition(SwapChainIndex);
end;

//---------------------------------------------------------------------------
procedure TDX9Device.SetDefaultViewport(UserDesc: PSwapChainDesc);
var
 vp: TD3DViewport9;
begin
 if (not Assigned(D3D9Device))or(not Assigned(UserDesc)) then Exit;

 vp.X:= 0;
 vp.Y:= 0;
 vp.Width := UserDesc.Width;
 vp.Height:= UserDesc.Height;
 vp.MinZ:= 0.0;
 vp.MaxZ:= 1.0;

 D3D9Device.SetViewport(vp);
end;

//---------------------------------------------------------------------------
procedure TDX9Device.Clear(Color: Cardinal);
var
 ClearFlags: Cardinal;
begin
 if (not Assigned(D3D9Device)) then Exit;

 ClearFlags:= D3DCLEAR_TARGET;

 if (DX9ActiveDepthStencilLevel > 0) then
  ClearFlags:= ClearFlags or D3DCLEAR_ZBUFFER;

 if (DX9ActiveDepthStencilLevel > 1) then
  ClearFlags:= ClearFlags or D3DCLEAR_STENCIL;

 D3D9Device.Clear(0, nil, ClearFlags, Color, FillDepthValue, FillStencilValue);
end;

//---------------------------------------------------------------------------
procedure TDX9Device.RenderWith(SwapChainIndex: Integer; Handler: TNotifyEvent;
 Background: Cardinal);
var
 UserDesc : PSwapChainDesc;
 SwapChain: TDX9SwapChain;
begin
 UserDesc:= SwapChains[SwapChainIndex];
 if (not Assigned(UserDesc))or(not Assigned(D3D9Device)) then Exit;

{$ifdef FireMonkeyHRH}
 SetDefaultViewport(UserDesc);

 EventBeginScene.Notify(Self);

 Handler(Self);

 EventEndScene.Notify(Self);
{$else}
 SwapChain:= nil;

 {$ifdef FireMonkey}
 { FireMonkey DX9 context uses dummy primary swap chain, so it's useless and
   an additional swap chain is used in its place. }
 if (SwapChainIndex >= 0) then
  begin
   SwapChain:= FDXSwapChains[SwapChainIndex];
   if (not Assigned(SwapChain)) then Exit;
  end;
 {$else}
 if (SwapChainIndex > 0) then
  begin
   SwapChain:= FDXSwapChains[SwapChainIndex - 1];
   if (not Assigned(SwapChain)) then Exit;
  end;
 {$endif}

 if (Assigned(SwapChain))and(not SwapChain.BeginDraw()) then Exit;

 SetDefaultViewport(UserDesc);

 DX9ActiveDepthStencilLevel:= Integer(UserDesc.DepthStencil);
 Clear(Background);

 if (Succeeded(D3D9Device.BeginScene())) then
  begin
   EventBeginScene.Notify(Self);

   Handler(Self);

   EventEndScene.Notify(Self);
   D3D9Device.EndScene();
  end;

 if (Assigned(SwapChain)) then
  begin
   SwapChain.EndDraw();
   SwapChain.Present();
  end else
  begin
   if (D3D9Mode = dmDirect3D9Ex) then
    IDirect3DDevice9Ex(D3D9Device).PresentEx(nil, nil, 0, nil, 0)
     else D3D9Device.Present(nil, nil, 0, nil);
  end;
{$endif}
end;

//---------------------------------------------------------------------------
procedure TDX9Device.RenderToTarget(Handler: TNotifyEvent;
 Background: Cardinal; FillBk: Boolean);
begin
 if (not Assigned(D3D9Device)) then Exit;

 if (FillBk) then Clear(Background);

 if (Succeeded(D3D9Device.BeginScene())) then
  begin
   EventBeginScene.Notify(Self);

   Handler(Self);

   EventEndScene.Notify(Self);
   D3D9Device.EndScene();
  end;
end;

//---------------------------------------------------------------------------
function TDX9Device.ResizeSwapChain(SwapChainIndex: Integer;
 NewUserDesc: PSwapChainDesc): Boolean;
var
 UserDesc : PSwapChainDesc;
 SwapChain: TDX9SwapChain;
begin
 Result:= False;

 UserDesc:= SwapChains[SwapChainIndex];
 if (not Assigned(UserDesc))or(not Assigned(D3D9Device)) then Exit;

{$ifndef FireMonkeyHRH}
 {$ifdef FireMonkey}
 SwapChain:= FDXSwapChains[SwapChainIndex];
 if (not Assigned(SwapChain)) then Exit;
{$else}
 SwapChain:= nil;
 if (SwapChainIndex > 0) then
  begin
   SwapChain:= FDXSwapChains[SwapChainIndex - 1];
   if (not Assigned(SwapChain)) then Exit;
  end;
 {$endif}
{$endif}

 UserDesc.Width := NewUserDesc.Width;
 UserDesc.Height:= NewUserDesc.Height;

{$ifndef FireMonkeyHRH}
 if (not Assigned(SwapChain)) then
  begin
   if (D3D9Mode = dmDirect3D9Ex) then
    begin // Vista enhanced mode.
     D3D9PresentParams.BackBufferWidth := UserDesc.Width;
     D3D9PresentParams.BackBufferHeight:= UserDesc.Height;

     Result:= Succeeded(IDirect3DDevice9Ex(D3D9Device).ResetEx(
      D3D9PresentParams, nil));
    end else
    begin // XP compatibility mode.
     MoveIntoLostState();

     D3D9PresentParams.BackBufferWidth := UserDesc.Width;
     D3D9PresentParams.BackBufferHeight:= UserDesc.Height;

     Result:= AttemptRecoverState();
    end;
  end else
  begin
   SwapChain.Finalize();
   Result:= SwapChain.Initialize(UserDesc);
  end;
{$endif}
end;

//---------------------------------------------------------------------------
end.
