unit Asphyre.SwapChains.DX11;
//---------------------------------------------------------------------------
// DirectX 11 multiple swap chains implementation.
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
 JSB.DXGI, JSB.D3D11, Asphyre.TypeDef, Asphyre.Types, Asphyre.SwapChains;

//---------------------------------------------------------------------------
type
 TDX11SwapChain = class
 private
  FInitialized: Boolean;

  FDXGISwapChain: IDXGISwapChain;
  FSwapChainDesc: DXGI_SWAP_CHAIN_DESC;

  FRenderTargetView: ID3D11RenderTargetView;
  FDepthStencilTex : ID3D11Texture2D;
  FDepthStencilView: ID3D11DepthStencilView;

  SavedTargetView : ID3D11RenderTargetView;
  SavedStencilView: ID3D11DepthStencilView;

  VSyncEnabled: Boolean;
  FIdleState: Boolean;

  function FindSwapChainFormat(Format: TAsphyrePixelFormat): DXGI_FORMAT;
  function CreateSwapChain(UserDesc: PSwapChainDesc): Boolean;
  procedure DestroySwapChain();

  function CreateRenderTargetView(): Boolean;
  procedure DestroyRenderTargetView();

  function CreateDepthStencil(UserDesc: PSwapChainDesc): Boolean;
  procedure DestroyDepthStencil();

  procedure PreserveRenderTargets();
  procedure RestoreRenderTargets();
 public
  property Initialized: Boolean read FInitialized;

  property DXGISwapChain: IDXGISwapChain read FDXGISwapChain;
  property SwapChainDesc: DXGI_SWAP_CHAIN_DESC read FSwapChainDesc;

  property RenderTargetView: ID3D11RenderTargetView read FRenderTargetView;
  property DepthStencilTex : ID3D11Texture2D read FDepthStencilTex;
  property DepthStencilView: ID3D11DepthStencilView read FDepthStencilView;

  property IdleState: Boolean read FIdleState write FIdleState;

  function Initialize(UserDesc: PSwapChainDesc): Boolean;
  procedure Finalize();

  function Resize(UserDesc: PSwapChainDesc): Boolean;

  function SetRenderTargets(): Boolean;
  function SetDefaultViewport(): Boolean;

  procedure ResetRenderTargets();

  function Present(): HResult;
  function PresentTest(): HResult;

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TDX11SwapChains = class
 private
  Data: array of TDX11SwapChain;

  function GetCount(): Integer;
  function GetItem(Index: Integer): TDX11SwapChain;
 public
  property Count: Integer read GetCount;
  property Items[Index: Integer]: TDX11SwapChain read GetItem; default;

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
{$ifndef fpc}
 Winapi.Windows, System.SysUtils,
{$else}
 Windows, SysUtils,
{$endif}
 Asphyre.Types.DX11, Asphyre.Formats.DX11;

//---------------------------------------------------------------------------
constructor TDX11SwapChain.Create();
begin
 inherited;

 FDXGISwapChain:= nil;

 FRenderTargetView:= nil;
 FDepthStencilTex := nil;
 FDepthStencilView:= nil;

 FillChar(FSwapChainDesc, SizeOf(DXGI_SWAP_CHAIN_DESC), 0);

 FInitialized:= False;
 VSyncEnabled:= False;

 FIdleState:= False;
end;

//---------------------------------------------------------------------------
destructor TDX11SwapChain.Destroy();
begin
 if (FInitialized) then Finalize();

 inherited;
end;

//---------------------------------------------------------------------------
function TDX11SwapChain.FindSwapChainFormat(
 Format: TAsphyrePixelFormat): DXGI_FORMAT;
var
 NewFormat: TAsphyrePixelFormat;
begin
 if (Format = apf_Unknown) then Format:= apf_A8R8G8B8;
 NewFormat:= DX11FindDisplayFormat(Format);

 Result:= DXGI_FORMAT_UNKNOWN;
 if (NewFormat <> apf_Unknown) then Result:= AsphyreToDX11Format(NewFormat);

 // If no format was found for the swap chain, try some common format.
 if (Result = DXGI_FORMAT_UNKNOWN) then Result:= DXGI_FORMAT_R8G8B8A8_UNORM;
end;

//---------------------------------------------------------------------------
function TDX11SwapChain.CreateSwapChain(UserDesc: PSwapChainDesc): Boolean;
var
 SwapDesc: DXGI_SWAP_CHAIN_DESC;
 SampleCount, QualityLevel: Integer;
 NewFormat: TAsphyrePixelFormat;
begin
 // (1) Verify initial conditions.
 Result:= (Assigned(D3D11Device))and(Assigned(DXGIFactory))and
  (Assigned(UserDesc))and(UserDesc.Width > 0)and(UserDesc.Height > 0)and
  (UserDesc.WindowHandle <> 0);
 if (not Result) then Exit;

 // (2) Prepare DXGI swap chain declaration.
 FillChar(SwapDesc, SizeOf(DXGI_SWAP_CHAIN_DESC), 0);

 SwapDesc.BufferCount:= 1;

 SwapDesc.BufferDesc.Width := UserDesc.Width;
 SwapDesc.BufferDesc.Height:= UserDesc.Height;
 SwapDesc.BufferDesc.Format:= FindSwapChainFormat(UserDesc.Format);

 SwapDesc.BufferUsage := DXGI_USAGE_RENDER_TARGET_OUTPUT;
 SwapDesc.OutputWindow:= UserDesc.WindowHandle;

 DX11FindBestMultisampleType(SwapDesc.BufferDesc.Format, UserDesc.Multisamples,
  SampleCount, QualityLevel);

 SwapDesc.SampleDesc.Count  := SampleCount;
 SwapDesc.SampleDesc.Quality:= QualityLevel;

 SwapDesc.Windowed:= True;

 // (3) Create DXGI swap chain.
 PushClearFPUState();
 try
  Result:= Succeeded(DXGIFactory.CreateSwapChain(D3D11Device, SwapDesc,
   FDXGISwapChain));
 finally
  PopFPUState();
 end;
 if (not Result) then Exit;

 // (4) Retrieve the updated description of swap chain.
 FillChar(FSwapChainDesc, SizeOf(DXGI_SWAP_CHAIN_DESC), 0);

 PushClearFPUState();
 try
  Result:= Succeeded(FDXGISwapChain.GetDesc(FSwapChainDesc));
 finally
  PopFPUState();
 end;

 // (5) Update user swap chain parameters.
 if (Result) then
  begin
   VSyncEnabled:= UserDesc.VSync;

   UserDesc.Multisamples:= FSwapChainDesc.SampleDesc.Count;

   NewFormat:= DX11FormatToAsphyre(FSwapChainDesc.BufferDesc.Format);
   if (NewFormat <> apf_Unknown) then UserDesc.Format:= NewFormat;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11SwapChain.DestroySwapChain();
begin
 if (Assigned(FDXGISwapChain)) then FDXGISwapChain:= nil;

 FillChar(FSwapChainDesc, SizeOf(DXGI_SWAP_CHAIN_DESC), 0);
 VSyncEnabled:= False;
end;

//---------------------------------------------------------------------------
function TDX11SwapChain.CreateRenderTargetView(): Boolean;
var
 BackBuffer: ID3D11Texture2D;
begin
 // (1) Verify initial conditions.
 Result:= (Assigned(D3D11Device))and(Assigned(FDXGISwapChain));
 if (not Result) then Exit;

 // (2) Retrieve swap chain's back buffer.
 PushClearFPUState();
 try
  Result:= Succeeded(FDXGISwapChain.GetBuffer(0, ID3D11Texture2D, BackBuffer));
 finally
  PopFPUState();
 end;

 if (not Result) then Exit;

 // (3) Create render target view.
 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateRenderTargetView(BackBuffer, nil,
   FRenderTargetView));
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX11SwapChain.DestroyRenderTargetView();
begin
 if (Assigned(FRenderTargetView)) then FRenderTargetView:= nil;
end;

//---------------------------------------------------------------------------
function TDX11SwapChain.CreateDepthStencil(UserDesc: PSwapChainDesc): Boolean;
var
 Format: DXGI_FORMAT;
 Desc  : D3D11_TEXTURE2D_DESC;
begin
 // (1) Verify initial conditions.
 Result:= False;
 if (not Assigned(D3D11Device))or(not Assigned(FDXGISwapChain)) then Exit;

 // (2) If no depth-stencil buffer is required, return success.
 if (UserDesc.DepthStencil = dstNone) then
  begin
   Result:= True;
   Exit;
  end;

 // (3) Find a compatible depth-stencil format.
 Format:= DX11FindDepthStencilFormat(Integer(UserDesc.DepthStencil));
 if (Format = DXGI_FORMAT_UNKNOWN) then Exit;

 // (4) Create a new depth-stencil buffer.
 FillChar(Desc, SizeOf(D3D11_TEXTURE2D_DESC), 0);

 Desc.Format:= Format;
 Desc.Width := FSwapChainDesc.BufferDesc.Width;
 Desc.Height:= FSwapChainDesc.BufferDesc.Height;

 Desc.MipLevels:= 1;
 Desc.ArraySize:= 1;

 Desc.SampleDesc.Count  := FSwapChainDesc.SampleDesc.Count;
 Desc.SampleDesc.Quality:= FSwapChainDesc.SampleDesc.Quality;

 Desc.Usage:= D3D11_USAGE_DEFAULT;
 Desc.BindFlags:= Ord(D3D11_BIND_DEPTH_STENCIL);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateTexture2D(Desc, nil, FDepthStencilTex));
 finally
  PopFPUState();
 end;
 if (not Result) then Exit;

 // (5) Create a depth-stencil view.
 Result:= Succeeded(D3D11Device.CreateDepthStencilView(FDepthStencilTex, nil,
  FDepthStencilView));
 if (not Result) then
  begin
   FDepthStencilTex:= nil;
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11SwapChain.DestroyDepthStencil();
begin
 if (Assigned(FDepthStencilView)) then FDepthStencilView:= nil;
 if (Assigned(FDepthStencilTex)) then FDepthStencilTex:= nil;
end;

//---------------------------------------------------------------------------
function TDX11SwapChain.Initialize(UserDesc: PSwapChainDesc): Boolean;
begin
 Result:= (not FInitialized)and(Assigned(UserDesc));
 if (not Result) then Exit;

 Result:= CreateSwapChain(UserDesc);
 if (not Result) then Exit;

 Result:= CreateRenderTargetView();
 if (not Result) then
  begin
   DestroySwapChain();
   Exit;
  end;

 Result:= CreateDepthStencil(UserDesc);
 if (not Result) then
  begin
   DestroyRenderTargetView();
   DestroySwapChain();
   Exit;
  end;

 FInitialized:= True;
 FIdleState:= False;
end;

//---------------------------------------------------------------------------
procedure TDX11SwapChain.Finalize();
begin
 if (not FInitialized) then Exit;

 RestoreRenderTargets();

 DestroyDepthStencil();
 DestroyRenderTargetView();
 DestroySwapChain();

 FInitialized:= False;
end;

//---------------------------------------------------------------------------
function TDX11SwapChain.Resize(UserDesc: PSwapChainDesc): Boolean;
begin
 // (1) Verify initial conditions.
 Result:= (FInitialized)and(Assigned(UserDesc))and(Assigned(FDXGISwapChain));
 if (not Result) then Exit;

 // (2) Destroy the depth-stencil and render target views because they will be
 // of different size.
 DestroyDepthStencil();
 DestroyRenderTargetView();

 // (3) Resize the swap chain itself.
 PushClearFPUState();
 try
  Result:= Succeeded(FDXGISwapChain.ResizeBuffers(1, UserDesc.Width,
   UserDesc.Height, FSwapChainDesc.BufferDesc.Format, 0));
 finally
  PopFPUState();
 end;

 if (not Result) then
  begin
   DestroySwapChain();
   Exit;
  end;

 // (4) Retrieve the updated description of swap chain.
 FillChar(FSwapChainDesc, SizeOf(DXGI_SWAP_CHAIN_DESC), 0);

 PushClearFPUState();
 try
  Result:= Succeeded(FDXGISwapChain.GetDesc(FSwapChainDesc));
 finally
  PopFPUState();
 end;

 if (not Result) then
  begin
   DestroySwapChain();
   Exit;
  end;

 // (5) Create render target view with the new size.
 Result:= CreateRenderTargetView();
 if (not Result) then
  begin
   DestroySwapChain();
   Exit;
  end;

 // (6) Create depth stencil with the new size.
 Result:= CreateDepthStencil(UserDesc);
 if (not Result) then
  begin
   DestroyRenderTargetView();
   DestroySwapChain();
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11SwapChain.PreserveRenderTargets();
begin
 if (Assigned(D3D11Context)) then
  begin
   PushClearFPUState();
   try
    D3D11Context.OMGetRenderTargets(1, @SavedTargetView, SavedStencilView);
   finally
    PopFPUState();
   end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11SwapChain.RestoreRenderTargets();
begin
 if (Assigned(D3D11Context))and(Assigned(SavedTargetView)) then
  begin
   PushClearFPUState();
   try
    D3D11Context.OMSetRenderTargets(1, @SavedTargetView, SavedStencilView);
   finally
    PopFPUState();
   end;
  end;

 if (Assigned(SavedStencilView)) then SavedStencilView:= nil;
 if (Assigned(SavedTargetView)) then SavedTargetView:= nil;
end;

//---------------------------------------------------------------------------
function TDX11SwapChain.SetRenderTargets(): Boolean;
begin
 Result:= (Assigned(D3D11Context))and(Assigned(FRenderTargetView));
 if (not Result) then Exit;

 PreserveRenderTargets();

 PushClearFPUState();
 try
  D3D11Context.OMSetRenderTargets(1, @FRenderTargetView, FDepthStencilView);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX11SwapChain.ResetRenderTargets();
begin
 RestoreRenderTargets();
end;

//---------------------------------------------------------------------------
function TDX11SwapChain.SetDefaultViewport(): Boolean;
begin
 Result:= (Assigned(D3D11Device))and(FSwapChainDesc.BufferDesc.Width > 0)and
  (FSwapChainDesc.BufferDesc.Height > 0);
 if (not Result) then Exit;

 FillChar(D3D11Viewport, SizeOf(D3D11_VIEWPORT), 0);

 D3D11Viewport.Width := FSwapChainDesc.BufferDesc.Width;
 D3D11Viewport.Height:= FSwapChainDesc.BufferDesc.Height;
 D3D11Viewport.MinDepth:= 0.0;
 D3D11Viewport.MaxDepth:= 1.0;

 PushClearFPUState();
 try
  D3D11Context.RSSetViewports(1, @D3D11Viewport);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11SwapChain.Present(): HResult;
var
 Interval: Cardinal;
begin
 Result:= DXGI_ERROR_INVALID_CALL;
 if (not Assigned(FDXGISwapChain)) then Exit;

 Interval:= 0;
 if (VSyncEnabled) then Interval:= 1;

 PushClearFPUState();
 try
  Result:= DXGISwapChain.Present(Interval, 0);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11SwapChain.PresentTest(): HResult;
begin
 Result:= DXGI_ERROR_INVALID_CALL;
 if (not Assigned(FDXGISwapChain)) then Exit;

 PushClearFPUState();
 try
  Result:= DXGISwapChain.Present(0, DXGI_PRESENT_TEST);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
constructor TDX11SwapChains.Create();
begin
 inherited;

end;

//---------------------------------------------------------------------------
destructor TDX11SwapChains.Destroy();
begin
 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
function TDX11SwapChains.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TDX11SwapChains.GetItem(Index: Integer): TDX11SwapChain;
begin
 if (Index >= 0)and(Index < Length(Data)) then
  Result:= Data[Index]
   else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TDX11SwapChains.RemoveAll();
var
 i: Integer;
begin
 for i:= Length(Data) - 1 downto 0 do
  if (Assigned(Data[i])) then FreeAndNil(Data[i]);

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
function TDX11SwapChains.Add(UserDesc: PSwapChainDesc): Integer;
var
 NewItem: TDX11SwapChain;
begin
 NewItem:= TDX11SwapChain.Create();

 if (not NewItem.Initialize(UserDesc)) then
  begin
   NewItem.Free();
   Result:= -1;
   Exit;
  end;

 Result:= Length(Data);
 SetLength(Data, Result + 1);

 Data[Result]:= NewItem;
end;

//---------------------------------------------------------------------------
function TDX11SwapChains.CreateAll(UserChains: TAsphyreSwapChains): Boolean;
var
 i, Index: Integer;
 UserDesc: PSwapChainDesc;
begin
 Result:= Assigned(UserChains);
 if (not Result) then Exit;

 if (Length(Data) > 0) then RemoveAll();
 Result:= False;

 for i:= 0 to UserChains.Count - 1 do
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
