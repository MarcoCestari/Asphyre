unit Asphyre.Textures.DX11;
//---------------------------------------------------------------------------
// Direct3D 11 Texture implementation.
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
{$ifndef fpc}
 System.Types,
{$else}
 Types,
{$endif}
 JSB.DXGI, JSB.D3D11, Asphyre.TypeDef, Asphyre.Types,
 Asphyre.Surfaces, Asphyre.Textures;

//---------------------------------------------------------------------------
type
 TDX11LockableTexture = class(TAsphyreLockableTexture)
 private
  Surface : TPixelSurface;
  FTexture: ID3D11Texture2D;

  FResourceView: ID3D11ShaderResourceView;
  FCustomFormat: DXGI_FORMAT;

  function IsNativeFormat(): Boolean;
  procedure UpdateSurfaceSize();

  function CreateTextureInstance(): Boolean;
  procedure DestroyTextureInstance();

  function CreateDynamicTexture(): Boolean;
  function UploadDynamicTexture(): Boolean;
  function CreateDefaultTexture(): Boolean;
  function UploadTexture(): Boolean;
  function CreateShaderResourceView(): Boolean;
 protected
  function GetBytesPerPixel(): Integer; override;
  procedure UpdateSize(); override;

  function CreateTexture(): Boolean; override;
  procedure DestroyTexture(); override;
 public
  property Texture: ID3D11Texture2D read FTexture;
  property ResourceView: ID3D11ShaderResourceView read FResourceView;

  property CustomFormat: DXGI_FORMAT read FCustomFormat write FCustomFormat;

  procedure Bind(Stage: Integer); override;

  procedure HandleDeviceReset(); override;
  procedure HandleDeviceLost(); override;

  procedure Lock(const Rect: TRect; out Bits: Pointer;
   out Pitch: Integer); override;
  procedure Unlock(); override;

  constructor Create(); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TDX11RenderTargetTexture = class(TAsphyreRenderTargetTexture)
 private
  FTexture: ID3D11Texture2D;

  FResourceView: ID3D11ShaderResourceView;
  FRenderTargetView: ID3D11RenderTargetView;

  FDepthStencilTex : ID3D11Texture2D;
  FDepthStencilView: ID3D11DepthStencilView;

  SavedTargetView : ID3D11RenderTargetView;
  SavedStencilView: ID3D11DepthStencilView;

  FCustomFormat: DXGI_FORMAT;

  function IsNativeFormat(): Boolean;
  function CreateTargetTexture(): Boolean;
  function CreateShaderResourceView(): Boolean;
  function CreateRenderTargetView(): Boolean;
  function CreateDepthStencil(): Boolean;

  function CreateTextureInstance(): Boolean;
  procedure DestroyTextureInstance();

  procedure PreserveRenderTargets();
  procedure RestoreRenderTargets();

  procedure UpdateViewport();
 protected
  procedure UpdateSize(); override;

  function CreateTexture(): Boolean; override;
  procedure DestroyTexture(); override;
 public
  property Texture: ID3D11Texture2D read FTexture;
  property ResourceView: ID3D11ShaderResourceView read FResourceView;
  property RenderTargetView: ID3D11RenderTargetView read FRenderTargetView;

  property DepthStencilTex : ID3D11Texture2D read FDepthStencilTex;
  property DepthStencilView: ID3D11DepthStencilView read FDepthStencilView;

  property CustomFormat: DXGI_FORMAT read FCustomFormat write FCustomFormat;

  procedure Bind(Stage: Integer); override;

  procedure HandleDeviceReset(); override;
  procedure HandleDeviceLost(); override;

  procedure UpdateMipmaps(); override;

  function BeginDrawTo(): Boolean; override;
  procedure EndDrawTo(); override;

  constructor Create(); override;
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
constructor TDX11LockableTexture.Create();
begin
 inherited;

 Surface:= TPixelSurface.Create();
 FCustomFormat:= DXGI_FORMAT_UNKNOWN;
end;

//---------------------------------------------------------------------------
destructor TDX11LockableTexture.Destroy();
begin
 FreeAndNil(Surface);

 inherited;
end;

//---------------------------------------------------------------------------
function TDX11LockableTexture.IsNativeFormat(): Boolean;
begin
 Result:= (FFormat <> apf_Unknown)and(FCustomFormat = DXGI_FORMAT_UNKNOWN);
end;

//---------------------------------------------------------------------------
function TDX11LockableTexture.GetBytesPerPixel(): Integer;
begin
 if (IsNativeFormat()) then
  Result:= inherited GetBytesPerPixel()
   else Result:= GetDX11FormatBitDepth(FCustomFormat) div 8;
end;

//---------------------------------------------------------------------------
procedure TDX11LockableTexture.UpdateSurfaceSize();
begin
 if (not IsNativeFormat()) then
  begin
   Surface.SetSize(Width, Height, apf_Unknown,
    GetDX11FormatBitDepth(FCustomFormat) div 8);
  end else Surface.SetSize(Width, Height, FFormat);
end;

//---------------------------------------------------------------------------
function TDX11LockableTexture.CreateDynamicTexture(): Boolean;
var
 Desc: D3D11_TEXTURE2D_DESC;
begin
 FillChar(Desc, SizeOf(D3D11_TEXTURE2D_DESC), 0);

 Desc.Width := Width;
 Desc.Height:= Height;

 Desc.MipLevels:= 1;
 Desc.ArraySize:= 1;

 if (IsNativeFormat()) then Desc.Format:= AsphyreToDX11Format(FFormat)
  else Desc.Format:= FCustomFormat;

 Desc.SampleDesc.Count  := 1;
 Desc.SampleDesc.Quality:= 0;

 Desc.Usage    := D3D11_USAGE_DYNAMIC;
 Desc.BindFlags:= Ord(D3D11_BIND_SHADER_RESOURCE);
 Desc.CPUAccessFlags:= Ord(D3D11_CPU_ACCESS_WRITE);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateTexture2D(Desc, nil, FTexture));
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11LockableTexture.CreateShaderResourceView(): Boolean;
begin
 Result:= Assigned(FTexture);
 if (not Result) then Exit;

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateShaderResourceView(FTexture, nil,
   FResourceView));
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11LockableTexture.CreateTextureInstance(): Boolean;
begin
 // Non-dynamic textures are (re)created each time new data is uploaded. This
 // assumes that the contents of texture is modified only once.
 Result:= not DynamicTexture;
 if (Result) then Exit;

 Result:= CreateDynamicTexture();
 if (Result) then Result:= CreateShaderResourceView();
end;

//---------------------------------------------------------------------------
procedure TDX11LockableTexture.DestroyTextureInstance();
begin
 if (Assigned(FResourceView)) then FResourceView:= nil;
 if (Assigned(FTexture)) then FTexture:= nil;
end;

//---------------------------------------------------------------------------
function TDX11LockableTexture.CreateTexture(): Boolean;
begin
 // (1) Check initial conditions for texture creation.
 Result:= (Assigned(D3D11Device))and((FFormat <> apf_Unknown)or
  (FCustomFormat <> DXGI_FORMAT_UNKNOWN));
 if (not Result) then Exit;

 // (2) In native mode look for a compatible texture format.
 if (IsNativeFormat()) then
  begin
   FFormat:= DX11FindTextureFormat(FFormat, Mipmapping);

   Result:= FFormat <> apf_Unknown;
   if (not Result) then Exit;
  end;

 // (3) Resize the texture's surface and create its Direct3D instance.
 UpdateSurfaceSize();
 Result:= CreateTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX11LockableTexture.DestroyTexture();
begin
 DestroyTextureInstance();
end;

//---------------------------------------------------------------------------
function TDX11LockableTexture.UploadDynamicTexture(): Boolean;
var
 Mapped: D3D11_MAPPED_SUBRESOURCE;
 Pixels: Pointer;
 i: Integer;
begin
 Result:= (Assigned(FTexture))and(Assigned(D3D11Context))and(Surface.Width > 0)and
  (Surface.Height > 0);
 if (not Result) then Exit;

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Context.Map(FTexture, 0, D3D11_MAP_WRITE_DISCARD, 0,
   Mapped));
 finally
  PopFPUState();
 end;
 if (not Result) then Exit;

 for i:= 0 to Surface.Height - 1 do
  begin
   Pixels:= Pointer(PtrInt(Mapped.pData) + (PtrInt(Mapped.RowPitch) * i));
   Move(Surface.Scanline[i]^, Pixels^, Surface.Pitch);
  end;

 PushClearFPUState();
 try
  D3D11Context.Unmap(FTexture, 0);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11LockableTexture.CreateDefaultTexture(): Boolean;
var
 Desc: D3D11_TEXTURE2D_DESC;
 SubResData: array of D3D11_SUBRESOURCE_DATA;
 i: Integer;
begin
 // (1) Mip-mapping requires a manual generation of individual mip levels.
 if (Mipmapping)and(IsNativeFormat()) then Surface.GenerateMipMaps()
  else Surface.RemoveMipMaps();

 // (2) Initialize Texture description.
 FillChar(Desc, SizeOf(D3D11_TEXTURE2D_DESC), 0);

 Desc.Width := Width;
 Desc.Height:= Height;

 Desc.MipLevels:= 1 + Surface.MipMaps.Count;
 Desc.ArraySize:= 1;

 if (IsNativeFormat()) then Desc.Format:= AsphyreToDX11Format(FFormat)
  else Desc.Format:= FCustomFormat;

 Desc.SampleDesc.Count  := 1;
 Desc.SampleDesc.Quality:= 0;

 Desc.Usage    := D3D11_USAGE_DEFAULT;
 Desc.BindFlags:= Ord(D3D11_BIND_SHADER_RESOURCE);

 // (3) Initialize Pixel Data description.
 SetLength(SubResData, 1 + Surface.MipMaps.Count);

 for i:= 0 to Length(SubResData) - 1 do
  begin
   SubResData[i].SysMemSlicePitch:= 0;

   if (i = 0) then
    begin
     SubResData[i].pSysMem:= Surface.Bits;
     SubResData[i].SysMemPitch:= Surface.Pitch;
    end else
    begin
     SubResData[i].pSysMem:= Surface.MipMaps[i - 1].Bits;
     SubResData[i].SysMemPitch:= Surface.MipMaps[i - 1].Pitch;
    end;
  end;

 // (4) Create Direct3D 10 Texture.
 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateTexture2D(Desc, @SubResData[0],
   FTexture));
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11LockableTexture.UploadTexture(): Boolean;
begin
 if (DynamicTexture) then
  begin
   Result:= UploadDynamicTexture();
   Exit;
  end;

 if (Assigned(FResourceView)) then FResourceView:= nil;
 if (Assigned(FTexture)) then FTexture:= nil;

 Result:= CreateDefaultTexture();
 if (Result) then Result:= CreateShaderResourceView();
end;

//---------------------------------------------------------------------------
procedure TDX11LockableTexture.Bind(Stage: Integer);
begin
 if (Assigned(D3D11Context))and(Assigned(FResourceView)) then
  begin
   PushClearFPUState();
   try
    D3D11Context.PSSetShaderResources(Stage, 1, @FResourceView);
   finally
    PopFPUState();
   end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11LockableTexture.HandleDeviceReset();
begin
 if (Assigned(FTexture)) then Exit;

 if (CreateTextureInstance()) then UploadTexture();
end;

//---------------------------------------------------------------------------
procedure TDX11LockableTexture.HandleDeviceLost();
begin
 DestroyTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX11LockableTexture.Lock(const Rect: TRect; out Bits: Pointer;
 out Pitch: Integer);
begin
 if (Surface.Width < 1)or(Surface.Height < 1) then
  begin
   Bits := nil;
   Pitch:= 0;
   Exit;
  end;

 Pitch:= Surface.Pitch;
 Bits := Surface.GetPixelPtr(Rect.Top, Rect.Left);
end;

//---------------------------------------------------------------------------
procedure TDX11LockableTexture.Unlock();
begin
 UploadTexture();
end;

//---------------------------------------------------------------------------
procedure TDX11LockableTexture.UpdateSize();
begin
 DestroyTextureInstance();

 if (not IsNativeFormat()) then
  begin
   Surface.SetSize(Width, Height, apf_Unknown,
    GetDX11FormatBitDepth(FCustomFormat) div 8);
  end else Surface.SetSize(Width, Height, FFormat);

 CreateTextureInstance();
end;

//---------------------------------------------------------------------------
constructor TDX11RenderTargetTexture.Create();
begin
 inherited;

 FCustomFormat:= DXGI_FORMAT_UNKNOWN;
end;

//---------------------------------------------------------------------------
function TDX11RenderTargetTexture.IsNativeFormat(): Boolean;
begin
 Result:= (FFormat <> apf_Unknown)and(FCustomFormat = DXGI_FORMAT_UNKNOWN);
end;

//---------------------------------------------------------------------------
function TDX11RenderTargetTexture.CreateTargetTexture(): Boolean;
var
 Desc: D3D11_TEXTURE2D_DESC;
 SampleCount, QualityLevel: Integer;
begin
 FillChar(Desc, SizeOf(D3D11_TEXTURE2D_DESC), 0);

 Desc.Width := Width;
 Desc.Height:= Height;

 Desc.MipLevels:= 1;
 if (Mipmapping) then Desc.MipLevels:= 0;

 Desc.ArraySize:= 1;

 if (IsNativeFormat()) then Desc.Format:= AsphyreToDX11Format(FFormat)
  else Desc.Format:= FCustomFormat;

 Desc.SampleDesc.Count  := 1;
 Desc.SampleDesc.Quality:= 0;

 if (not Mipmapping)and(FMultisamples > 1) then
  begin
   DX11FindBestMultisampleType(Desc.Format, FMultisamples, SampleCount,
    QualityLevel);

   Desc.SampleDesc.Count  := SampleCount;
   Desc.SampleDesc.Quality:= QualityLevel;

   FMultisamples:= SampleCount;
  end;

 Desc.Usage:= D3D11_USAGE_DEFAULT;

 Desc.BindFlags:= Ord(D3D11_BIND_SHADER_RESOURCE) or
  Ord(D3D11_BIND_RENDER_TARGET);

 if (Mipmapping) then Desc.MiscFlags:= Ord(D3D11_RESOURCE_MISC_GENERATE_MIPS);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateTexture2D(Desc, nil, FTexture));
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11RenderTargetTexture.CreateShaderResourceView(): Boolean;
begin
 Result:= Assigned(FTexture);
 if (not Result) then Exit;

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateShaderResourceView(FTexture, nil,
   FResourceView));
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11RenderTargetTexture.CreateRenderTargetView(): Boolean;
begin
 Result:= Assigned(FTexture);
 if (not Result) then Exit;

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateRenderTargetView(FTexture, nil,
   FRenderTargetView));
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11RenderTargetTexture.CreateDepthStencil(): Boolean;
var
 Format: DXGI_FORMAT;
 TexDesc, NewDesc: D3D11_TEXTURE2D_DESC;
begin
 Result:= False;
 if (not Assigned(D3D11Device))or(not Assigned(FTexture)) then Exit;

 // (1) Find a compatible depth-stencil format.
 Format:= DX11FindDepthStencilFormat(2);
 if (Format = DXGI_FORMAT_UNKNOWN) then Exit;

 // (2) Retrieve the description of the render target texture.
 FillChar(TexDesc, SizeOf(D3D11_TEXTURE2D_DESC), 0);

 PushClearFPUState();
 try
  FTexture.GetDesc(TexDesc);
 finally
  PopFPUState();
 end;

 // (3) Create a new depth-stencil buffer.
 FillChar(NewDesc, SizeOf(D3D11_TEXTURE2D_DESC), 0);

 NewDesc.Format:= Format;
 NewDesc.Width := Width;
 NewDesc.Height:= Height;

 NewDesc.MipLevels:= TexDesc.MipLevels;
 NewDesc.ArraySize:= 1;

 NewDesc.SampleDesc.Count  := TexDesc.SampleDesc.Count;
 NewDesc.SampleDesc.Quality:= TexDesc.SampleDesc.Quality;

 NewDesc.Usage    := D3D11_USAGE_DEFAULT;
 NewDesc.BindFlags:= Ord(D3D11_BIND_DEPTH_STENCIL);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateTexture2D(NewDesc, nil,
   FDepthStencilTex));
 finally
  PopFPUState();
 end;
 if (not Result) then Exit;

 // (4) Create a depth-stencil view.
 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateDepthStencilView(FDepthStencilTex, nil,
   FDepthStencilView));
 finally
  PopFPUState();
 end;

 if (not Result) then
  begin
   FDepthStencilTex:= nil;
   Exit;
  end;
end;

//---------------------------------------------------------------------------
function TDX11RenderTargetTexture.CreateTextureInstance(): Boolean;
begin
 Result:= (Assigned(D3D11Device))and((FFormat <> apf_Unknown)or
  (FCustomFormat <> DXGI_FORMAT_UNKNOWN));
 if (not Result) then Exit;

 if (IsNativeFormat()) then
  begin
   FFormat:= DX11FindRenderTargetFormat(FFormat, Mipmapping);

   Result:= FFormat <> apf_Unknown;
   if (not Result) then Exit;
  end;

 Result:= CreateTargetTexture();
 if (Result) then Result:= CreateShaderResourceView();
 if (Result) then Result:= CreateRenderTargetView();
 if (Result) then Result:= CreateDepthStencil();
end;

//---------------------------------------------------------------------------
procedure TDX11RenderTargetTexture.DestroyTextureInstance();
begin
 if (Assigned(FDepthStencilView)) then FDepthStencilView:= nil;
 if (Assigned(FDepthStencilTex)) then FDepthStencilTex:= nil;
 if (Assigned(FRenderTargetView)) then FRenderTargetView:= nil;
 if (Assigned(FResourceView)) then FResourceView:= nil;
 if (Assigned(FTexture)) then FTexture:= nil;
end;

//---------------------------------------------------------------------------
function TDX11RenderTargetTexture.CreateTexture(): Boolean;
begin
 Result:= CreateTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX11RenderTargetTexture.DestroyTexture();
begin
 DestroyTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX11RenderTargetTexture.Bind(Stage: Integer);
begin
 if (Assigned(D3D11Context))and(Assigned(FResourceView)) then
  begin
   PushClearFPUState();
   try
    D3D11Context.PSSetShaderResources(Stage, 1, @FResourceView);
   finally
    PopFPUState();
   end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11RenderTargetTexture.HandleDeviceReset();
begin
 CreateTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX11RenderTargetTexture.HandleDeviceLost();
begin
 DestroyTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX11RenderTargetTexture.UpdateMipmaps();
begin
 if (Assigned(D3D11Context))and(Assigned(FResourceView)) then
  begin
   PushClearFPUState();
   try
    D3D11Context.GenerateMips(FResourceView);
   finally
    PopFPUState();
   end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11RenderTargetTexture.UpdateSize();
begin
 DestroyTextureInstance();
 CreateTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX11RenderTargetTexture.PreserveRenderTargets();
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
procedure TDX11RenderTargetTexture.RestoreRenderTargets();
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
procedure TDX11RenderTargetTexture.UpdateViewport();
begin
 FillChar(D3D11Viewport, SizeOf(D3D11_VIEWPORT), 0);

 D3D11Viewport.Width := Width;
 D3D11Viewport.Height:= Height;
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
function TDX11RenderTargetTexture.BeginDrawTo(): Boolean;
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

 UpdateViewport();
end;

//---------------------------------------------------------------------------
procedure TDX11RenderTargetTexture.EndDrawTo();
begin
 RestoreRenderTargets();
end;

//---------------------------------------------------------------------------
end.
