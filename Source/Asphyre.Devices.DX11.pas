unit Asphyre.Devices.DX11;
//---------------------------------------------------------------------------
// DirectX 11 device management for Asphyre.
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

//--------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.Classes,
{$else}
 Classes,
{$endif}
 Asphyre.TypeDef, Asphyre.Devices, Asphyre.Textures,
 Asphyre.SwapChains, Asphyre.SwapChains.DX11;

//---------------------------------------------------------------------------
type
 TDX11Device = class(TAsphyreDevice)
 private
  ManagedDXGI: Boolean;
  ManagedDevice: Boolean;

  FDXSwapChains: TDX11SwapChains;

  procedure UpdateTechFeatureVersion();

  function ExtractFactory(): Boolean;
  procedure DestroyFactory();

  function CreateHALDevice(): Boolean;
  function CreateWARPDevice(): Boolean;

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
  property DXSwapChains: TDX11SwapChains read FDXSwapChains;

  constructor Create(); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 Winapi.Windows, System.SysUtils,
{$else}
 Windows, SysUtils,
{$endif}
 JSB.DXTypes, JSB.D3DCommon, JSB.DXGI, JSB.D3D11,
 Asphyre.Types.DX11, Asphyre.Events;

//---------------------------------------------------------------------------
var
 D3D11Linked: Boolean = False;

//---------------------------------------------------------------------------
const
 TypicalFeatureLevels: array[0..3] of D3D_FEATURE_LEVEL = (
  D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_1, D3D_FEATURE_LEVEL_10_0,
  D3D_FEATURE_LEVEL_9_1);

//---------------------------------------------------------------------------
{$ifdef DX11Debug}
 DefaultDeviceCreationFlags = Ord(D3D11_CREATE_DEVICE_DEBUG);
{$else}
 DefaultDeviceCreationFlags = 0;
{$endif}

//---------------------------------------------------------------------------
function LinkD3D11(): Boolean;
begin
 Result:= D3D11Linked;
 if (Result) then Exit;

 try
  JSB.DXGI.Link();
  JSB.D3D11.Link();
 except
  Result:= False;
  Exit;
 end;

 D3D11Linked:= True;
 Result:= True;
end;

//---------------------------------------------------------------------------
constructor TDX11Device.Create();
begin
 inherited;

 FTechnology:= adtDirectX;
 FTechVersion:= $B00;

 ManagedDXGI:= False;
 ManagedDevice:= False;

 FDXSwapChains:= TDX11SwapChains.Create();
end;

//---------------------------------------------------------------------------
destructor TDX11Device.Destroy();
begin
 inherited;

 FreeAndNil(FDXSwapChains);
end;

//---------------------------------------------------------------------------
function TDX11Device.ExtractFactory(): Boolean;
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

 if (Supports(D3D11Device, IDXGIDevice1, DXGIDevice)) then
  if (Succeeded(DXGIDevice.GetParent(IDXGIAdapter1, DXGIAdapter)))and
   (Assigned(DXGIAdapter)) then
   if (Succeeded(DXGIAdapter.GetParent(IDXGIFactory1, DXGIFactory)))and
    (Assigned(DXGIAdapter)) then
    begin
     ManagedDXGI:= True;
     Result:= True;
    end;
end;

//---------------------------------------------------------------------------
procedure TDX11Device.DestroyFactory();
begin
 if (ManagedDXGI) then
  begin
   if (Assigned(DXGIFactory)) then DXGIFactory:= nil;
   ManagedDXGI:= False;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11Device.UpdateTechFeatureVersion();
begin
 case D3D11FeatureLevel of
  D3D_FEATURE_LEVEL_9_1:
   FTechFeatureVersion:= $910;

  D3D_FEATURE_LEVEL_9_2:
   FTechFeatureVersion:= $920;

  D3D_FEATURE_LEVEL_9_3:
   FTechFeatureVersion:= $930;

  D3D_FEATURE_LEVEL_10_0:
   FTechFeatureVersion:= $A00;

  D3D_FEATURE_LEVEL_10_1:
   FTechFeatureVersion:= $A10;

  D3D_FEATURE_LEVEL_11_0:
   FTechFeatureVersion:= $B00;
 end;
end;

//---------------------------------------------------------------------------
function TDX11Device.CreateHALDevice(): Boolean;
var
 CustomFeatureLevel, NewFeatureLevel: D3D_FEATURE_LEVEL;
 InFeatureLevel: PD3D_FEATURE_LEVEL;
 InFeatureLevelCount: Integer;
begin
 if (D3D11FeatureLevel >= D3D_FEATURE_LEVEL_10_0) then
  begin // Use typical feature level selection approach.
   InFeatureLevel:= @TypicalFeatureLevels[0];
   InFeatureLevelCount:= High(TypicalFeatureLevels) + 1;
  end else
  begin // Force lowest feature level possible.
   CustomFeatureLevel:= D3D_FEATURE_LEVEL_9_1;

   InFeatureLevel:= @CustomFeatureLevel;
   InFeatureLevelCount:= 1;
  end;

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11CreateDevice(nil, D3D_DRIVER_TYPE_HARDWARE, 0,
   DefaultDeviceCreationFlags, PTD3D_FeatureLevel(InFeatureLevel),
   InFeatureLevelCount, D3D11_SDK_VERSION, D3D11Device, @NewFeatureLevel,
   D3D11Context));
 finally
  PopFPUState();
 end;
 if (not Result) then Exit;

 D3D11DriverType:= D3D_DRIVER_TYPE_HARDWARE;
 D3D11FeatureLevel:= NewFeatureLevel;

 UpdateTechFeatureVersion();
end;

//---------------------------------------------------------------------------
function TDX11Device.CreateWARPDevice(): Boolean;
var
 NewFeatureLevel: D3D_FEATURE_LEVEL;
begin
 PushClearFPUState();
 try
  Result:= Succeeded(D3D11CreateDevice(nil, D3D_DRIVER_TYPE_WARP, 0,
   DefaultDeviceCreationFlags, @TypicalFeatureLevels[0],
   High(TypicalFeatureLevels) + 1, D3D11_SDK_VERSION,  D3D11Device,
   @NewFeatureLevel, D3D11Context));
 finally
  PopFPUState();
 end;

 if (not Result) then Exit;

 D3D11DriverType:= D3D_DRIVER_TYPE_WARP;
 D3D11FeatureLevel:= NewFeatureLevel;

 UpdateTechFeatureVersion();
end;

//---------------------------------------------------------------------------
function TDX11Device.CreateDirect3D(): Boolean;
begin
 ManagedDevice:= False;

 if (Assigned(D3D11Device))and(Assigned(D3D11Context)) then
  begin
   Result:= True;
   Exit;
  end;

 if (D3D11DriverType <> D3D_DRIVER_TYPE_WARP) then
  Result:= CreateHALDevice()
   else Result:= False;

 if (not Result) then
  Result:= CreateWARPDevice();

 if (not Result) then Exit;

 Result:= ExtractFactory();
 if (not Result) then
  begin
   D3D11Context:= nil;
   D3D11Device := nil;
  end;

 if (Result) then ManagedDevice:= True;
end;

//---------------------------------------------------------------------------
procedure TDX11Device.DestroyDirect3D();
begin
 if (ManagedDevice) then
  begin
   if (Assigned(D3D11Context)) then D3D11Context:= nil;
   if (Assigned(D3D11Device)) then D3D11Device:= nil;
   ManagedDevice:= False;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11Device.UpdateWindowAssociation();
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
function TDX11Device.InitDevice(): Boolean;
begin
 Result:= LinkD3D11();
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
procedure TDX11Device.DoneDevice();
begin
 FDXSwapChains.RemoveAll();

 DestroyDirect3D();
 DestroyFactory();
end;

//---------------------------------------------------------------------------
procedure TDX11Device.ResetDevice();
begin
end;

//---------------------------------------------------------------------------
function TDX11Device.ResizeSwapChain(SwapChainIndex: Integer;
 NewUserDesc: PSwapChainDesc): Boolean;
var
 SwapChain: TDX11SwapChain;
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
procedure TDX11Device.Clear(Color: Cardinal);
var
 ActiveRenderTarget: ID3D11RenderTargetView;
 ActiveDepthStencil: ID3D11DepthStencilView;
 ClearColor: TColorArray;
begin
 if (not Assigned(D3D11Context)) then Exit;

 ClearColor[0]:= ((Color shr 16) and $FF) / 255.0;
 ClearColor[1]:= ((Color shr 8) and $FF) / 255.0;
 ClearColor[2]:= (Color and $FF) / 255.0;
 ClearColor[3]:= ((Color shr 24) and $FF) / 255.0;

 PushClearFPUState();
 try
  D3D11Context.OMGetRenderTargets(1, @ActiveRenderTarget, ActiveDepthStencil);

  if (Assigned(ActiveRenderTarget)) then
   D3D11Context.ClearRenderTargetView(ActiveRenderTarget, ClearColor);

  if (Assigned(ActiveDepthStencil)) then
   D3D11Context.ClearDepthStencilView(ActiveDepthStencil,
    Ord(D3D11_CLEAR_DEPTH) or Ord(D3D11_CLEAR_STENCIL), FillDepthValue,
    FillStencilValue)
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX11Device.ClearDevStates();
begin
 if (not Assigned(D3D11Context)) then Exit;

 PushClearFPUState();
 try
  D3D11Context.ClearState();
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11Device.MayRender(SwapChainIndex: Integer): Boolean;
var
 SwapChain: TDX11SwapChain;
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
procedure TDX11Device.InvestigatePresentIssue(SwapChainIndex: Integer;
 OpRes: HResult);
var
 SwapChain: TDX11SwapChain;
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
procedure TDX11Device.RenderWith(SwapChainIndex: Integer;
 Handler: TNotifyEvent; Background: Cardinal);
var
 SwapChain: TDX11SwapChain;
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
procedure TDX11Device.RenderToTarget(Handler: TNotifyEvent;
 Background: Cardinal; FillBk: Boolean);
begin
 if (FillBk) then Clear(Background);

 EventBeginScene.Notify(Self);

 Handler(Self);

 EventEndScene.Notify(Self);
end;

//---------------------------------------------------------------------------
end.
