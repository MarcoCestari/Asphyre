unit Asphyre.Devices.DX10;
//---------------------------------------------------------------------------
// Direct3D 10.x device management for Asphyre.
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
 JSB.DXGI, System.Classes, Asphyre.TypeDef, Asphyre.Devices, 
 Asphyre.Textures, Asphyre.SwapChains, Asphyre.SwapChains.DX10;

//---------------------------------------------------------------------------
// Remove dot "." to enable loading shaders from external files. This will
// include "D3DX10.pas" to USES and require distributing "d3dx10_41.dll".
//---------------------------------------------------------------------------
{.$define EnableD3DX10}

//---------------------------------------------------------------------------
type
 TDX10Device = class(TAsphyreDevice)
 private
  ManagedDXGI: Boolean;
  ManagedDevice: Boolean;

  FDXSwapChains: TDX10SwapChains;

  procedure UpdateTechFeatureVersion();

  function CreateFactory(): Boolean;
  procedure DestroyFactory();
  function ExtractFactory1(): Boolean;
  function ExtractFactory(): Boolean;

  function EnumPrimaryAdapter(): IDXGIAdapter;

  function CreateHALDevice1(): Boolean;
  function CreateWARPDevice1(): Boolean;

  function CreateHALDevice(): Boolean;

  function CreateDirect3D(): Boolean;
  procedure DestroyDirect3D();

  procedure UpdateWindowAssociation();

  procedure Clear(Color: Cardinal);
  procedure InvestigatePresentIssue(SwapChainIndex: Integer; OpRes: HResult);
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

  procedure ClearDevStates(); override;
 public
  property DXSwapChains: TDX10SwapChains read FDXSwapChains;

  constructor Create(); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Winapi.Windows, System.SysUtils, JSB.DXTypes, JSB.D3D10, JSB.D3D10_1,
 Asphyre.Types.DX10, Asphyre.Events;

//---------------------------------------------------------------------------
var
 D3D10Linked: Boolean = False;

//---------------------------------------------------------------------------
function LinkD3D10(): Boolean;
begin
 Result:= D3D10Linked;
 if (Result) then Exit;

 try
  JSB.DXGI.Link();
  JSB.D3D10.Link();
  JSB.D3D10_1.Link();
 except
  Result:= False;
  Exit;
 end;

 D3D10Linked:= True;
 Result:= True;
end;

//---------------------------------------------------------------------------
constructor TDX10Device.Create();
begin
 inherited;

 FTechnology:= adtDirectX;

 ManagedDXGI:= False;
 ManagedDevice:= False;

 FDXSwapChains:= TDX10SwapChains.Create();
end;

//---------------------------------------------------------------------------
destructor TDX10Device.Destroy();
begin
 inherited;

 FreeAndNil(FDXSwapChains);
end;

//---------------------------------------------------------------------------
function TDX10Device.CreateFactory(): Boolean;
begin
 // (1) Check in case DXGI interface is already allocated.
 if (Assigned(DXGIFactory)) then
  begin
   ManagedDXGI:= False;

   DXGIMode:= ddmDXGI10;

   if (Supports(DXGIFactory, IDXGIFactory1)) then
    DXGIMode:= ddmDXGI11;

   Result:= True;
   Exit;
  end;

 // (2) Attempt creating DXGI 1.1 interface, unless DXGI 1.0 is forced on.
 if (DXGIMode <> ddmDXGI10) then
  begin
   PushClearFPUState();
   try
    Result:= Succeeded(CreateDXGIFactory1(IDXGIFactory1, DXGIFactory));
   finally
    PopFPUState();
   end;

   if (Result) then
    DXGIMode:= ddmDXGI11
     else DXGIFactory:= nil;
  end;

 // (3) If DXGI 1.1 interface failed or DXGI 1.0 is forced, try creating it.
 if (not Assigned(DXGIFactory)) then
  begin
   PushClearFPUState();
   try
    Result:= Succeeded(CreateDXGIFactory(IDXGIFactory, DXGIFactory));
   finally
    PopFPUState();
   end;

   if (Result) then
    DXGIMode:= ddmDXGI10
     else DXGIFactory:= nil;
  end;

 Result:= Assigned(DXGIFactory);
 ManagedDXGI:= Result;

 if (not Result) then DXGIMode:= ddmUnknown;
end;

//---------------------------------------------------------------------------
procedure TDX10Device.DestroyFactory();
begin
 if (ManagedDXGI) then
  begin
   if (Assigned(DXGIFactory)) then DXGIFactory:= nil;
   ManagedDXGI:= False;
  end;
end;

//---------------------------------------------------------------------------
function TDX10Device.ExtractFactory1(): Boolean;
var
 DXGIDevice : IDXGIDevice1;
 DXGIAdapter: IDXGIAdapter1;
begin
 DestroyFactory();

 ManagedDXGI:= False;

 if (Assigned(DXGIFactory)) then
  begin
   Result:= True;
   Exit;
  end;

 Result:= False;
 DXGIMode:= ddmUnknown;

 if (Supports(D3D10Device, IDXGIDevice1, DXGIDevice)) then
  if (Succeeded(DXGIDevice.GetParent(IDXGIAdapter1, DXGIAdapter)))and
   (Assigned(DXGIAdapter)) then
   if (Succeeded(DXGIAdapter.GetParent(IDXGIFactory1, DXGIFactory)))and
    (Assigned(DXGIAdapter)) then
    begin
     ManagedDXGI:= True;
     DXGIMode:= ddmDXGI11;
     Result:= True;
    end;
end;

//---------------------------------------------------------------------------
function TDX10Device.ExtractFactory(): Boolean;
var
 DXGIDevice : IDXGIDevice;
 DXGIAdapter: IDXGIAdapter;
begin
 DestroyFactory();

 ManagedDXGI:= False;

 if (Assigned(DXGIFactory)) then
  begin
   Result:= True;
   Exit;
  end;

 Result:= False;
 DXGIMode:= ddmUnknown;

 if (Supports(D3D10Device, IDXGIDevice, DXGIDevice)) then
  if (Succeeded(DXGIDevice.GetParent(IDXGIAdapter, DXGIAdapter)))and
   (Assigned(DXGIAdapter)) then
   if (Succeeded(DXGIAdapter.GetParent(IDXGIFactory, DXGIFactory)))and
    (Assigned(DXGIAdapter)) then
    begin
     ManagedDXGI:= True;
     DXGIMode:= ddmDXGI10;
     Result:= True;
    end;
end;

//---------------------------------------------------------------------------
procedure TDX10Device.UpdateTechFeatureVersion();
begin
 case D3D10FeatureLevel of
  flDirectX10:
   FTechFeatureVersion:= $A00;

  flDirectX10_1:
   FTechFeatureVersion:= $A10;
 end;
end;

//---------------------------------------------------------------------------
function TDX10Device.EnumPrimaryAdapter(): IDXGIAdapter;
var
 Result1: IDXGIAdapter1;
 OpRes  : HResult;
begin
 Result1:= nil;

 if (not Assigned(DXGIFactory)) then
  begin
   Result:= nil;
   Exit;
  end;

 PushClearFPUState();
 try
  if (DXGIMode = ddmDXGI11) then
   OpRes:= IDXGIFactory1(DXGIFactory).EnumAdapters1(0, Result1)
    else OpRes:= DXGIFactory.EnumAdapters(0, Result);
 finally
  PopFPUState();
 end;
 if (Failed(OpRes)) then Exit;

 if (Assigned(Result1)) then Result:= Result1;
end;

//---------------------------------------------------------------------------
function TDX10Device.CreateHALDevice1(): Boolean;
var
 Device1: ID3D10Device1;
 PriAdapter: IDXGIAdapter;
 Flags: Cardinal;
begin
 // (1) Retrieve default adapter for the device.
 PriAdapter:= EnumPrimaryAdapter();

 Result:= Assigned(PriAdapter);
 if (not Result) then Exit;

 // (2) Create Direct3D 10.1 device.
 Flags:= {$ifdef DX10Debug}Ord(D3D10_CREATE_DEVICE_DEBUG){$else}0{$endif};

 PushClearFPUState();
 try
  Result:= Succeeded(D3D10CreateDevice1(PriAdapter, D3D10_DRIVER_TYPE_HARDWARE,
   0, Flags, D3D10_FEATURE_LEVEL_10_1, D3D10_1_SDK_VERSION, Device1));
 finally
  PopFPUState();
 end;

 if (Result) then
  begin
   D3D10Device:= Device1;

   D3D10Mode:= dmDirectX10_1;
   D3D10DriverType:= dtHardware;
   D3D10FeatureLevel:= flDirectX10_1;
   Exit;
  end;

 // (3) Try creating Direct3D 10.1 device with 10.0 feature level.
 PushClearFPUState();
 try
  Result:= Succeeded(D3D10CreateDevice1(PriAdapter, D3D10_DRIVER_TYPE_HARDWARE,
   0, Flags, D3D10_FEATURE_LEVEL_10_0, D3D10_1_SDK_VERSION, Device1));
 finally
  PopFPUState();
 end;

 if (Result) then
  begin
   D3D10Device:= Device1;

   D3D10Mode:= dmDirectX10_1;
   D3D10DriverType:= dtHardware;
   D3D10FeatureLevel:= flDirectX10;
  end;
end;

//---------------------------------------------------------------------------
function TDX10Device.CreateWARPDevice1(): Boolean;
var
 Device1: ID3D10Device1;
 Flags: Cardinal;
begin
 // (1) Create Direct3D 10.1 WARP device.
 Flags:= {$ifdef DX10Debug}Ord(D3D10_CREATE_DEVICE_DEBUG){$else}0{$endif};

 PushClearFPUState();
 try
  Result:= Succeeded(D3D10CreateDevice1(nil, D3D10_DRIVER_TYPE_WARP,
   0, Flags, D3D10_FEATURE_LEVEL_10_1, D3D10_1_SDK_VERSION, Device1));
 finally
  PopFPUState();
 end;

 if (Result) then
  begin
   D3D10Device:= Device1;

   D3D10Mode:= dmDirectX10_1;
   D3D10DriverType:= dtSoftware;
   D3D10FeatureLevel:= flDirectX10_1;
   Exit;
  end;

 // (3) Try creating Direct3D 10.1 WARP device with 10.0 feature level.
 PushClearFPUState();
 try
  Result:= Succeeded(D3D10CreateDevice1(nil, D3D10_DRIVER_TYPE_WARP,
   0, Flags, D3D10_FEATURE_LEVEL_10_0, D3D10_1_SDK_VERSION, Device1));
 finally
  PopFPUState();
 end;

 if (Result) then
  begin
   D3D10Device:= Device1;

   D3D10Mode:= dmDirectX10_1;
   D3D10DriverType:= dtSoftware;
   D3D10FeatureLevel:= flDirectX10;
  end;
end;

//---------------------------------------------------------------------------
function TDX10Device.CreateHALDevice(): Boolean;
var
 PriAdapter: IDXGIAdapter;
 Flags: Cardinal;
begin
 // (1) Retrieve default adapter for the device.
 PriAdapter:= EnumPrimaryAdapter();

 Result:= Assigned(PriAdapter);
 if (not Result) then Exit;

 // (2) Setup and create Direct3D 10 device.
 Flags:= {$ifdef DX10Debug}Ord(D3D10_CREATE_DEVICE_DEBUG){$else}0{$endif};

 PushClearFPUState();
 try
  Result:= Succeeded(D3D10CreateDevice(PriAdapter, D3D10_DRIVER_TYPE_HARDWARE,
   0, Flags, D3D10_SDK_VERSION, D3D10Device));
 finally
  PopFPUState();
 end;

 if (Result) then
  begin
   D3D10Mode:= dmDirectX10;
   D3D10DriverType:= dtHardware;
   D3D10FeatureLevel:= flDirectX10;
  end;
end;

//---------------------------------------------------------------------------
function TDX10Device.CreateDirect3D(): Boolean;
begin
 ManagedDevice:= False;

 if (Assigned(D3D10Device)) then
  begin
   D3D10Mode:= dmDirectX10;
   FTechVersion:= $A00;

   if (Supports(D3D10Device, ID3D10Device1)) then
    begin
     D3D10Mode:= dmDirectX10_1;
     FTechVersion:= $A10;
    end;

   Result:= True;
   Exit;
  end;

 // Force DirectX 10.0 DLL mode, if 10.1 functions are not loaded.
 if (not Assigned(D3D10CreateDevice1)) then
  D3D10Mode:= dmDirectX10;

 // If no DirectX 10 runtime is installed, there is nothing to be done here.
 if (not Assigned(D3D10CreateDevice)) then
  begin
   Result:= False;
   Exit;
  end;

 case D3D10Mode of
  dmDirectX10:
   // Use DirectX 10.0 DLL.
   begin
    Result:= CreateHALDevice();

    if (Result) then
     FTechVersion:= $A00;
   end

  else
   begin // Use DirectX 10.1 DLL.
    case D3D10DriverType of
     dtSoftware:
      Result:= CreateWARPDevice1();

     else
      begin // Hardware mode.
       Result:= CreateHALDevice1();

       if (not Result)and(D3D10DriverType = dtUnknown) then
        Result:= CreateWARPDevice1();
      end;
    end; // case D3D10DriverType

    if (not Result) then
     Result:= CreateHALDevice();

    if (Result) then
     FTechVersion:= $A10;
   end;
 end; // case D3D10Mode

 if (not Result) then Exit;

 UpdateTechFeatureVersion();

 if (D3D10DriverType = dtSoftware) then
  begin
   Result:= ExtractFactory1();
   if (not Result) then Result:= ExtractFactory();

   if (not Result) then DestroyDirect3D();
  end;

 if (Result) then ManagedDevice:= True;
end;

//---------------------------------------------------------------------------
procedure TDX10Device.DestroyDirect3D();
begin
 if (ManagedDevice) then
  begin
   if (Assigned(D3D10Device)) then D3D10Device:= nil;
   ManagedDevice:= False;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX10Device.UpdateWindowAssociation();
var
 UserDesc: PSwapChainDesc;
 Success : Boolean;
 i: Integer;
begin
 if (not Assigned(DXGIFactory)) then Exit;

 for i:= 0 to SwapChains.Count - 1 do
  begin
   UserDesc:= SwapChains[i];
   if (not Assigned(UserDesc))or(UserDesc.WindowHandle = 0) then Continue;

   PushClearFPUState();
   try
    Success:= Succeeded(DXGIFactory.MakeWindowAssociation(UserDesc.WindowHandle,
     DXGI_MWA_NO_WINDOW_CHANGES or DXGI_MWA_NO_ALT_ENTER));
   finally
    PopFPUState();
   end;

   if (Success) then Break;
  end;
end;

//---------------------------------------------------------------------------
function TDX10Device.InitDevice(): Boolean;
begin
 Result:= LinkD3D10();
 if (not Result) then Exit;

 Result:= CreateFactory();
 if (not Result) then Exit;

 Result:= CreateDirect3D();
 if (not Result) then
  begin
   DestroyFactory();
   Exit;
  end;

 Result:= FDXSwapChains.CreateAll(SwapChains);
 if (not Result) then
  begin
   DestroyDirect3D();
   DestroyFactory();
   Exit;
  end;

 if (Result) then UpdateWindowAssociation();
end;

//---------------------------------------------------------------------------
procedure TDX10Device.DoneDevice();
begin
 FDXSwapChains.RemoveAll();

 DestroyDirect3D();
 DestroyFactory();
end;

//---------------------------------------------------------------------------
procedure TDX10Device.ResetDevice();
begin
end;

//---------------------------------------------------------------------------
function TDX10Device.ResizeSwapChain(SwapChainIndex: Integer;
 NewUserDesc: PSwapChainDesc): Boolean;
var
 SwapChain: TDX10SwapChain;
begin
 SwapChain:= FDXSwapChains[SwapChainIndex];
 if (not Assigned(SwapChain)) then
  begin
   Result:= False;
   Exit;
  end;

 ClearStates();

 Result:= SwapChain.Resize(NewUserDesc);
end;

//---------------------------------------------------------------------------
procedure TDX10Device.Clear(Color: Cardinal);
var
 ClearColor: TColorArray;
begin
 if (not Assigned(D3D10Device)) then Exit;

 ClearColor[0]:= ((Color shr 16) and $FF) / 255.0;
 ClearColor[1]:= ((Color shr 8) and $FF) / 255.0;
 ClearColor[2]:= (Color and $FF) / 255.0;
 ClearColor[3]:= ((Color shr 24) and $FF) / 255.0;

 PushClearFPUState();
 try
  if (ActiveRenderTargetView <> nil) then
   D3D10Device.ClearRenderTargetView(ActiveRenderTargetView, ClearColor);

  if (ActiveDepthStencilView <> nil) then
   D3D10Device.ClearDepthStencilView(ActiveDepthStencilView,
    Ord(D3D10_CLEAR_DEPTH) or Ord(D3D10_CLEAR_STENCIL), FillDepthValue,
    FillStencilValue)
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX10Device.ClearDevStates();
begin
 if (not Assigned(D3D10Device)) then Exit;

 PushClearFPUState();
 try
  D3D10Device.ClearState();
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX10Device.MayRender(SwapChainIndex: Integer): Boolean;
var
 SwapChain: TDX10SwapChain;
 OpRes: HResult;
begin
 Result:= True;
 if (SwapChainIndex = -1) then Exit;

 SwapChain:= FDXSwapChains[SwapChainIndex];
 if (not Assigned(SwapChain)) then Exit;

 if (SwapChain.IdleState) then
  begin
   Result:= False;
   if (not SwapChain.Initialized) then Exit;

   OpRes:= SwapChain.PresentTest();
   if (OpRes = S_OK) then
    begin
     SwapChain.IdleState:= False;
     Result:= True;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX10Device.InvestigatePresentIssue(SwapChainIndex: Integer;
 OpRes: HResult);
var
 SwapChain: TDX10SwapChain;
begin
 SwapChain:= FDXSwapChains[SwapChainIndex];
 if (not Assigned(SwapChain)) then Exit;

 case OpRes of
  DXGI_STATUS_OCCLUDED,
  DXGI_STATUS_MODE_CHANGE_IN_PROGRESS:
   SwapChain.IdleState:= True;

// The following status message is not handled.
//  DXGI_STATUS_MODE_CHANGED: ;

  DXGI_ERROR_DEVICE_HUNG,
  DXGI_ERROR_DRIVER_INTERNAL_ERROR,
  DXGI_ERROR_DEVICE_REMOVED,
  DXGI_ERROR_DEVICE_RESET:
   FState:= adsRunTimeFault;
 end;
end;

//---------------------------------------------------------------------------
procedure TDX10Device.RenderWith(SwapChainIndex: Integer;
 Handler: TNotifyEvent; Background: Cardinal);
var
 SwapChain: TDX10SwapChain;
 OpRes: HResult;
begin
 SwapChain:= FDXSwapChains[SwapChainIndex];
 if (not Assigned(SwapChain)) then Exit;

 if (not SwapChain.SetRenderTargets()) then Exit;
 if (not SwapChain.SetDefaultViewport()) then Exit;

 Clear(Background);
 EventBeginScene.Notify(Self);

 Handler(Self);

 EventEndScene.Notify(Self);

 OpRes:= SwapChain.Present();
 SwapChain.ResetRenderTargets();

 if (OpRes <> S_OK) then InvestigatePresentIssue(SwapChainIndex, OpRes);
end;

//---------------------------------------------------------------------------
procedure TDX10Device.RenderToTarget(Handler: TNotifyEvent;
 Background: Cardinal; FillBk: Boolean);
begin
 if (FillBk) then Clear(Background);

 EventBeginScene.Notify(Self);

 Handler(Self);

 EventEndScene.Notify(Self);
end;

//---------------------------------------------------------------------------
end.
