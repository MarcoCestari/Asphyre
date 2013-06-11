unit Asphyre.SwapChains.DX9;
//---------------------------------------------------------------------------
// Direct3D 9 multiple swap chains implementation.
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
 Asphyre.D3D9, Winapi.Windows, Asphyre.Types, Asphyre.SwapChains;

//---------------------------------------------------------------------------
type
 TDX9SwapChain = class
 private
  FInitialized: Boolean;

  FD3DSwapChain : IDirect3DSwapChain9;
  FPresentParams: D3DPRESENT_PARAMETERS;
  FDepthStencil : IDirect3DSurface9;

  DepthStencilFormat: D3DFORMAT;

  SavedBackBuffer  : IDirect3DSurface9;
  SavedDepthStencil: IDirect3DSurface9;

  function MakePresentParams(UserDesc: PSwapChainDesc): Boolean;

  function CreateSwapChain(UserDesc: PSwapChainDesc): Boolean;
  procedure DestroySwapChain();

  function CreateDepthStencil(UserDesc: PSwapChainDesc): Boolean;
  procedure DestroyDepthStencil();

  function SaveRenderBuffers(): Boolean;
  procedure RestoreRenderBuffers();

  function SetRenderBuffers(): Boolean;
 public
  property Initialized: Boolean read FInitialized;

  property D3DSwapChain : IDirect3DSwapChain9 read FD3DSwapChain;
  property PresentParams: D3DPRESENT_PARAMETERS read FPresentParams;

  property DepthStencil: IDirect3DSurface9 read FDepthStencil;

  function Initialize(UserDesc: PSwapChainDesc): Boolean;
  procedure Finalize();

  function BeginDraw(): Boolean;
  procedure EndDraw();

  function Present(): Boolean;

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TDX9SwapChains = class
 private
  Data: array of TDX9SwapChain;

  function GetCount(): Integer;
  function GetItem(Index: Integer): TDX9SwapChain;
 public
  property Count: Integer read GetCount;
  property Items[Index: Integer]: TDX9SwapChain read GetItem; default;

  function Add(UserDesc: PSwapChainDesc): Integer;
  procedure RemoveAll();

  function CreateAll(UserChains: TAsphyreSwapChains): Boolean;

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifdef FireMonkey}
 FMX.Platform.Win, FMX.Types,
{$endif}

 System.SysUtils, Asphyre.Types.DX9;

//---------------------------------------------------------------------------
constructor TDX9SwapChain.Create();
begin
 inherited;

 FD3DSwapChain:= nil;
 FillChar(FPresentParams, SizeOf(D3DPRESENT_PARAMETERS), 0);

 DepthStencilFormat:= D3DFMT_UNKNOWN;

 FInitialized:= False;
end;

//---------------------------------------------------------------------------
destructor TDX9SwapChain.Destroy();
begin
 if (FInitialized) then Finalize();

 inherited;
end;

//---------------------------------------------------------------------------
function TDX9SwapChain.MakePresentParams(UserDesc: PSwapChainDesc): Boolean;
begin
 Result:= Assigned(UserDesc);
 if (not Result) then Exit;

 with FPresentParams do
  begin
   BackBufferWidth := UserDesc.Width;
   BackBufferHeight:= UserDesc.Height;

   Windowed  := True;
   SwapEffect:= D3DSWAPEFFECT_DISCARD;

  {$ifdef FireMonkey}
   hDeviceWindow:= WindowHandleToPlatform(TWindowHandle(UserDesc.WindowHandle)).Wnd;
  {$else}
   hDeviceWindow:= UserDesc.WindowHandle;
  {$endif}

   PresentationInterval:= D3DPRESENT_INTERVAL_IMMEDIATE;
   if (UserDesc.VSync) then
    PresentationInterval:= D3DPRESENT_INTERVAL_ONE;

   BackBufferFormat:= DX9FindBackBufferFormat(UserDesc.Format);
  end;

 DepthStencilFormat:= DX9FindDepthStencilFormat(Integer(UserDesc.DepthStencil));

 DX9FindBestMultisampleType(FPresentParams.BackBufferFormat, DepthStencilFormat,
  UserDesc.Multisamples, FPresentParams.MultiSampleType,
  FPresentParams.MultiSampleQuality);
end;

//---------------------------------------------------------------------------
function TDX9SwapChain.CreateSwapChain(UserDesc: PSwapChainDesc): Boolean;
begin
 // (1) Verify initial conditions.
 Result:= (Assigned(UserDesc))and(Assigned(D3D9Device))and
  (FPresentParams.BackBufferWidth > 0)and(FPresentParams.BackBufferHeight > 0);
 if (not Result) then Exit;

 // (2) Create additional swap chain.
 Result:= Succeeded(D3D9Device.CreateAdditionalSwapChain(FPresentParams,
  FD3DSwapChain));

 // (3) Update the description of the first swap chain.
 if (Result) then
  begin
   UserDesc.Format:= DX9FormatToAsphyre(FPresentParams.BackBufferFormat);
   UserDesc.Multisamples:= Integer(FPresentParams.MultiSampleType);
  end;
end;

//---------------------------------------------------------------------------
procedure TDX9SwapChain.DestroySwapChain();
begin
 DepthStencilFormat:= D3DFMT_UNKNOWN;
 FillChar(FPresentParams, SizeOf(D3DPRESENT_PARAMETERS), 0);

 if (Assigned(FD3DSwapChain)) then FD3DSwapChain:= nil;
end;

//---------------------------------------------------------------------------
function TDX9SwapChain.CreateDepthStencil(UserDesc: PSwapChainDesc): Boolean;
begin
 // (1) If no depth-stencil is required, return success.
 if (UserDesc.DepthStencil = dstNone) then
  begin
   Result:= True;
   Exit;
  end;

 // (2) Verify initial conditions.
 Result:= (Assigned(UserDesc))and(Assigned(D3D9Device))and
  (DepthStencilFormat <> D3DFMT_UNKNOWN);
 if (not Result) then Exit;

 // (3) Create depth-stencil surface.
 Result:= Succeeded(D3D9Device.CreateDepthStencilSurface(UserDesc.Width,
  UserDesc.Height, DepthStencilFormat, FPresentParams.MultiSampleType,
  FPresentParams.MultiSampleQuality, True, FDepthStencil, nil));
end;

//---------------------------------------------------------------------------
procedure TDX9SwapChain.DestroyDepthStencil();
begin
 if (Assigned(FDepthStencil)) then FDepthStencil:= nil;
end;

//---------------------------------------------------------------------------
function TDX9SwapChain.Initialize(UserDesc: PSwapChainDesc): Boolean;
begin
 Result:= (not FInitialized)and(Assigned(UserDesc));
 if (not Result) then Exit;

 Result:= MakePresentParams(UserDesc);
 if (not Result) then Exit;

 Result:= CreateSwapChain(UserDesc);
 if (not Result) then Exit;

 Result:= CreateDepthStencil(UserDesc);
 if (not Result) then
  begin
   DestroySwapChain();
   Exit;
  end;

 FInitialized:= True;
end;

//---------------------------------------------------------------------------
procedure TDX9SwapChain.Finalize();
begin
 if (not FInitialized) then Exit;

 if (Assigned(SavedBackBuffer)) then SavedBackBuffer:= nil;
 if (Assigned(SavedDepthStencil)) then SavedDepthStencil:= nil;

 DestroyDepthStencil();
 DestroySwapChain();

 FInitialized:= False;
end;

//---------------------------------------------------------------------------
function TDX9SwapChain.SaveRenderBuffers(): Boolean;
begin
 Result:= Assigned(D3D9Device);
 if (not Result) then Exit;

 Result:= Succeeded(D3D9Device.GetRenderTarget(0, SavedBackBuffer));
 if (not Result) then Exit;

 if (D3D9PresentParams.EnableAutoDepthStencil) then
  begin
   Result:= Succeeded(D3D9Device.GetDepthStencilSurface(SavedDepthStencil));
   if (not Result) then
    begin
     SavedBackBuffer:= nil;
     Exit;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX9SwapChain.RestoreRenderBuffers();
begin
 if (Assigned(D3D9Device)) then
  begin
   if (D3D9PresentParams.EnableAutoDepthStencil) then
    D3D9Device.SetDepthStencilSurface(SavedDepthStencil);

   D3D9Device.SetRenderTarget(0, SavedBackBuffer);
  end;

 if (Assigned(SavedDepthStencil)) then SavedDepthStencil:= nil;
 if (Assigned(SavedBackBuffer)) then SavedBackBuffer:= nil;
end;

//---------------------------------------------------------------------------
function TDX9SwapChain.SetRenderBuffers(): Boolean;
var
 BackBuffer: IDirect3DSurface9;
begin
 Result:= (Assigned(D3D9Device))and(Assigned(FD3DSwapChain));
 if (not Result) then Exit;

 Result:= Succeeded(FD3DSwapChain.GetBackBuffer(0, D3DBACKBUFFER_TYPE_MONO,
  BackBuffer));
 if (not Result) then Exit;

 Result:= Succeeded(D3D9Device.SetRenderTarget(0, BackBuffer));

 if (Result) then
   Result:= Succeeded(D3D9Device.SetDepthStencilSurface(FDepthStencil));
end;

//---------------------------------------------------------------------------
function TDX9SwapChain.BeginDraw(): Boolean;
begin
 Result:= (Assigned(D3D9Device))and(Assigned(FD3DSwapChain));
 if (not Result) then Exit;

 Result:= SaveRenderBuffers();
 if (not Result) then Exit;

 Result:= SetRenderBuffers();
 if (not Result) then
  begin
   RestoreRenderBuffers();
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX9SwapChain.EndDraw();
begin
 RestoreRenderBuffers();
end;

//---------------------------------------------------------------------------
function TDX9SwapChain.Present(): Boolean;
begin
 Result:= Assigned(FD3DSwapChain);
 if (not Result) then Exit;

 Result:= Succeeded(FD3DSwapChain.Present(nil, nil, 0, nil, 0));
end;

//---------------------------------------------------------------------------
constructor TDX9SwapChains.Create();
begin
 inherited;

end;

//---------------------------------------------------------------------------
destructor TDX9SwapChains.Destroy();
begin
 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
function TDX9SwapChains.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TDX9SwapChains.GetItem(Index: Integer): TDX9SwapChain;
begin
 if (Index >= 0)and(Index < Length(Data)) then
  Result:= Data[Index]
   else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TDX9SwapChains.RemoveAll();
var
 i: Integer;
begin
 for i:= Length(Data) - 1 downto 0 do
  if (Assigned(Data[i])) then FreeAndNil(Data[i]);

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
function TDX9SwapChains.Add(UserDesc: PSwapChainDesc): Integer;
var
 NewItem: TDX9SwapChain;
begin
 NewItem:= TDX9SwapChain.Create();

 if (not NewItem.Initialize(UserDesc)) then
  begin
   FreeAndNil(NewItem);
   Result:= -1;
   Exit;
  end;

 Result:= Length(Data);
 SetLength(Data, Result + 1);

 Data[Result]:= NewItem;
end;

//---------------------------------------------------------------------------
function TDX9SwapChains.CreateAll(UserChains: TAsphyreSwapChains): Boolean;
{ Typically, the first swap chain is ignored as it is the primary swap chain
  created by the device. However, FireMonkey DX9 context uses a dummy swap
  chain when creating device, so it cannot be used; therefore, in FireMonkey
  applications it is necessary to create all swap chains. }
const
 ChainInitIndex = {$ifdef FireMonkey}0{$else}1{$endif};
var
 i, Index: Integer;
 UserDesc: PSwapChainDesc;
begin
 Result:= Assigned(UserChains);
 if (not Result) then Exit;

 if (Length(Data) > 0) then RemoveAll();
 Result:= True;

 for i:= ChainInitIndex to UserChains.Count - 1 do
  begin
   UserDesc:= UserChains[i];
   if (not Assigned(UserDesc)) then
    begin
     Result:= False;
     Break;
    end;

   Index:= Add(UserDesc);

   Result:= Index <> -1;
   if (not Result) then Break;
  end;

 if (not Result)and(Length(Data) > 0) then RemoveAll();
end;

//---------------------------------------------------------------------------
end.
