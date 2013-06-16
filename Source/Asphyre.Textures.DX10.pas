unit Asphyre.Textures.DX10;
//---------------------------------------------------------------------------
// Direct3D 10.x texture implementation.
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
 System.Types, System.SysUtils,
{$else}
 Types, SysUtils,
{$endif}
 JSB.DXGI, JSB.D3D10, Asphyre.TypeDef,
 Asphyre.Types, Asphyre.Surfaces, Asphyre.Textures;

//---------------------------------------------------------------------------
type
 TDX10LockableTexture = class(TAsphyreLockableTexture)
 private
  Surface : TPixelSurface;
  FTexture: ID3D10Texture2D;

  FResourceView: ID3D10ShaderResourceView;
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
  property Texture: ID3D10Texture2D read FTexture;
  property ResourceView: ID3D10ShaderResourceView read FResourceView;

  property CustomFormat: DXGI_FORMAT read FCustomFormat write FCustomFormat;

  function GetResourceView(): Pointer; override;

  procedure HandleDeviceReset(); override;
  procedure HandleDeviceLost(); override;

  procedure Lock(const Rect: TRect; out Bits: Pointer;
   out Pitch: Integer); override;
  procedure Unlock(); override;

  constructor Create(); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TDX10RenderTargetTexture = class(TAsphyreRenderTargetTexture)
 private
  FTexture: ID3D10Texture2D;

  FResourceView: ID3D10ShaderResourceView;
  FRenderTargetView: ID3D10RenderTargetView;

  FDepthStencilTex : ID3D10Texture2D;
  FDepthStencilView: ID3D10DepthStencilView;

  FCustomFormat: DXGI_FORMAT;

  function IsNativeFormat(): Boolean;
  function CreateTargetTexture(): Boolean;
  function CreateShaderResourceView(): Boolean;
  function CreateRenderTargetView(): Boolean;
  function CreateDepthStencil(): Boolean;

  function CreateTextureInstance(): Boolean;
  procedure DestroyTextureInstance();
  procedure ResetDefaultViewport();
 protected
  procedure UpdateSize(); override;

  function CreateTexture(): Boolean; override;
  procedure DestroyTexture(); override;
 public
  property Texture: ID3D10Texture2D read FTexture;
  property ResourceView: ID3D10ShaderResourceView read FResourceView;
  property RenderTargetView: ID3D10RenderTargetView read FRenderTargetView;

  property DepthStencilTex : ID3D10Texture2D read FDepthStencilTex;
  property DepthStencilView: ID3D10DepthStencilView read FDepthStencilView;

  property CustomFormat: DXGI_FORMAT read FCustomFormat write FCustomFormat;

  function GetResourceView(): Pointer; override;

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
 Winapi.Windows,
{$else}
 Windows,
{$endif}
 JSB.D3D10_1, Asphyre.Formats, Asphyre.Types.DX10,
 Asphyre.Formats.DX10;

//---------------------------------------------------------------------------
constructor TDX10LockableTexture.Create();
begin
 inherited;

 Surface:= TPixelSurface.Create();
 FCustomFormat:= DXGI_FORMAT_UNKNOWN;
end;

//---------------------------------------------------------------------------
destructor TDX10LockableTexture.Destroy();
begin
 FreeAndNil(Surface);

 inherited;
end;

//---------------------------------------------------------------------------
function TDX10LockableTexture.IsNativeFormat(): Boolean;
begin
 Result:= (FFormat <> apf_Unknown)and(FCustomFormat = DXGI_FORMAT_UNKNOWN);
end;

//---------------------------------------------------------------------------
function TDX10LockableTexture.GetBytesPerPixel(): Integer;
begin
 if (IsNativeFormat()) then Result:= inherited GetBytesPerPixel()
  else Result:= GetDX10FormatBitDepth(FCustomFormat) div 8;
end;

//---------------------------------------------------------------------------
procedure TDX10LockableTexture.UpdateSurfaceSize();
begin
 if (not IsNativeFormat()) then
  begin
   Surface.SetSize(Width, Height, apf_Unknown,
    GetDX10FormatBitDepth(FCustomFormat) div 8);
  end else Surface.SetSize(Width, Height, FFormat);
end;

//---------------------------------------------------------------------------
function TDX10LockableTexture.CreateDynamicTexture(): Boolean;
var
 Desc: D3D10_TEXTURE2D_DESC;
begin
 FillChar(Desc, SizeOf(D3D10_TEXTURE2D_DESC), 0);

 Desc.Width := Width;
 Desc.Height:= Height;

 Desc.MipLevels:= 1;
 Desc.ArraySize:= 1;

 if (IsNativeFormat()) then Desc.Format:= AsphyreToDX10Format(FFormat)
  else Desc.Format:= FCustomFormat;

 Desc.SampleDesc.Count  := 1;
 Desc.SampleDesc.Quality:= 0;

 Desc.Usage    := D3D10_USAGE_DYNAMIC;
 Desc.BindFlags:= Ord(D3D10_BIND_SHADER_RESOURCE);
 Desc.CPUAccessFlags:= Ord(D3D10_CPU_ACCESS_WRITE);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D10Device.CreateTexture2D(Desc, nil, FTexture));
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX10LockableTexture.CreateShaderResourceView(): Boolean;
var
 ExResView: ID3D10ShaderResourceView1;
begin
 Result:= Assigned(FTexture);
 if (not Result) then Exit;

 PushClearFPUState();
 try
  if (D3D10Mode >= dmDirectX10_1) then
   begin // Direct3D 10.1
    Result:= Succeeded(ID3D10Device1(D3D10Device).CreateShaderResourceView1(
     FTexture, nil, ExResView));

    if (Result)and(Assigned(ExResView)) then FResourceView:= ExResView;
   end else
   begin // Direct3D 10.0
    Result:= Succeeded(D3D10Device.CreateShaderResourceView(FTexture, nil,
     FResourceView));
   end;
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX10LockableTexture.CreateTextureInstance(): Boolean;
begin
 // Non-dynamic textures are (re)created each time new data is uploaded. This
 // assumes that the contents of texture is modified only once.
 Result:= not DynamicTexture;
 if (Result) then Exit;

 Result:= CreateDynamicTexture();
 if (Result) then Result:= CreateShaderResourceView();
end;

//---------------------------------------------------------------------------
procedure TDX10LockableTexture.DestroyTextureInstance();
begin
 if (Assigned(FResourceView)) then FResourceView:= nil;
 if (Assigned(FTexture)) then FTexture:= nil;
end;

//---------------------------------------------------------------------------
function TDX10LockableTexture.CreateTexture(): Boolean;
begin
 // (1) Check initial conditions for texture creation.
 Result:= (Assigned(D3D10Device))and((FFormat <> apf_Unknown)or
  (FCustomFormat <> DXGI_FORMAT_UNKNOWN));
 if (not Result) then Exit;

 // (2) In native mode look for a compatible texture format.
 if (IsNativeFormat()) then
  begin
   FFormat:= DX10FindTextureFormat(FFormat, Mipmapping);

   Result:= FFormat <> apf_Unknown;
   if (not Result) then Exit;
  end;

 // (3) Resize the texture's surface and create its Direct3D instance.
 UpdateSurfaceSize();
 Result:= CreateTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX10LockableTexture.DestroyTexture();
begin
 DestroyTextureInstance();
end;

//---------------------------------------------------------------------------
function TDX10LockableTexture.UploadDynamicTexture(): Boolean;
var
 Mapped: D3D10_MAPPED_TEXTURE2D;
 Pixels: Pointer;
 i: Integer;
begin
 Result:= (Assigned(FTexture))and(Surface.Width > 0)and(Surface.Height > 0);
 if (not Result) then Exit;

 PushClearFPUState();
 try
  Result:= Succeeded(FTexture.Map(0, D3D10_MAP_WRITE_DISCARD, 0, Mapped));
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
  FTexture.Unmap(0);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX10LockableTexture.CreateDefaultTexture(): Boolean;
var
 Desc: D3D10_TEXTURE2D_DESC;
 SubResData: array of D3D10_SUBRESOURCE_DATA;
 i: Integer;
begin
 // (1) Mip-mapping requires a manual generation of individual mip levels.
 if (Mipmapping)and(IsNativeFormat()) then Surface.GenerateMipMaps()
  else Surface.RemoveMipMaps();

 // (2) Initialize Texture description.
 FillChar(Desc, SizeOf(D3D10_TEXTURE2D_DESC), 0);

 Desc.Width := Width;
 Desc.Height:= Height;

 Desc.MipLevels:= 1 + Surface.MipMaps.Count;
 Desc.ArraySize:= 1;

 if (IsNativeFormat()) then Desc.Format:= AsphyreToDX10Format(FFormat)
  else Desc.Format:= FCustomFormat;

 Desc.SampleDesc.Count  := 1;
 Desc.SampleDesc.Quality:= 0;

 Desc.Usage    := D3D10_USAGE_DEFAULT;
 Desc.BindFlags:= Ord(D3D10_BIND_SHADER_RESOURCE);

 // (3) Initialize Pixel Data description.
 SetLength(SubResData, 1 + Surface.MipMaps.Count);

 for i:= 0 to Length(SubResData) - 1 do
  begin
   SubResData[i].SysMemSlicePitch:= 0;

   if (i = 0) then
    begin
     SubResData[i].pSysMem    := Surface.Bits;
     SubResData[i].SysMemPitch:= Surface.Pitch;
    end else
    begin
     SubResData[i].pSysMem    := Surface.MipMaps[i - 1].Bits;
     SubResData[i].SysMemPitch:= Surface.MipMaps[i - 1].Pitch;
    end;
  end;

 // (4) Create Direct3D 10 Texture.
 PushClearFPUState();
 try
  Result:= Succeeded(D3D10Device.CreateTexture2D(Desc, @SubResData[0],
   FTexture));
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX10LockableTexture.UploadTexture(): Boolean;
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
function TDX10LockableTexture.GetResourceView(): Pointer;
begin
 Result:= Pointer(FResourceView);
end;

//---------------------------------------------------------------------------
procedure TDX10LockableTexture.HandleDeviceReset();
begin
 if (not Assigned(FTexture)) then Exit;

 if (CreateTextureInstance()) then UploadTexture();
end;

//---------------------------------------------------------------------------
procedure TDX10LockableTexture.HandleDeviceLost();
begin
 DestroyTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX10LockableTexture.Lock(const Rect: TRect; out Bits: Pointer;
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
procedure TDX10LockableTexture.Unlock();
begin
 UploadTexture();
end;

//---------------------------------------------------------------------------
procedure TDX10LockableTexture.UpdateSize();
begin
 DestroyTextureInstance();

 if (not IsNativeFormat()) then
  begin
   Surface.SetSize(Width, Height, apf_Unknown,
    GetDX10FormatBitDepth(FCustomFormat) div 8);
  end else Surface.SetSize(Width, Height, FFormat);

 CreateTextureInstance();
end;

//---------------------------------------------------------------------------
constructor TDX10RenderTargetTexture.Create();
begin
 inherited;

 FCustomFormat:= DXGI_FORMAT_UNKNOWN;
end;

//---------------------------------------------------------------------------
function TDX10RenderTargetTexture.IsNativeFormat(): Boolean;
begin
 Result:= (FFormat <> apf_Unknown)and(FCustomFormat = DXGI_FORMAT_UNKNOWN);
end;

//---------------------------------------------------------------------------
function TDX10RenderTargetTexture.GetResourceView(): Pointer;
begin
 Result:= Pointer(FResourceView);
end;

//---------------------------------------------------------------------------
function TDX10RenderTargetTexture.CreateTargetTexture(): Boolean;
var
 Desc: D3D10_TEXTURE2D_DESC;
 SampleCount, QualityLevel: Integer;
begin
 FillChar(Desc, SizeOf(D3D10_TEXTURE2D_DESC), 0);

 Desc.Width := Width;
 Desc.Height:= Height;

 Desc.MipLevels:= 1;
 if (Mipmapping) then Desc.MipLevels:= 0;

 Desc.ArraySize:= 1;

 if (IsNativeFormat()) then Desc.Format:= AsphyreToDX10Format(FFormat)
  else Desc.Format:= FCustomFormat;

 Desc.SampleDesc.Count  := 1;
 Desc.SampleDesc.Quality:= 0;

 if (not Mipmapping)and(FMultisamples > 1) then
  begin
   DX10FindBestMultisampleType(Desc.Format, FMultisamples, SampleCount,
    QualityLevel);

   Desc.SampleDesc.Count  := SampleCount;
   Desc.SampleDesc.Quality:= QualityLevel;

   FMultisamples:= SampleCount;
  end;

 Desc.Usage:= D3D10_USAGE_DEFAULT;

 Desc.BindFlags:= Ord(D3D10_BIND_SHADER_RESOURCE) or
  Ord(D3D10_BIND_RENDER_TARGET);

 if (Mipmapping) then Desc.MiscFlags:= Ord(D3D10_RESOURCE_MISC_GENERATE_MIPS);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D10Device.CreateTexture2D(Desc, nil, FTexture));
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX10RenderTargetTexture.CreateShaderResourceView(): Boolean;
var
 ExResView: ID3D10ShaderResourceView1;
begin
 Result:= Assigned(FTexture);
 if (not Result) then Exit;

 PushClearFPUState();
 try
  if (D3D10Mode >= dmDirectX10_1) then
   begin // Direct3D 10.1
    Result:= Succeeded(ID3D10Device1(D3D10Device).CreateShaderResourceView1(
     FTexture, nil, ExResView));

    if (Result)and(Assigned(ExResView)) then FResourceView:= ExResView;
   end else
   begin // Direct3D 10.0
    Result:= Succeeded(D3D10Device.CreateShaderResourceView(FTexture, nil,
     FResourceView));
   end;
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX10RenderTargetTexture.CreateRenderTargetView(): Boolean;
begin
 Result:= Assigned(FTexture);
 if (not Result) then Exit;

 PushClearFPUState();
 try
  Result:= Succeeded(D3D10Device.CreateRenderTargetView(FTexture, nil,
   FRenderTargetView));
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX10RenderTargetTexture.CreateDepthStencil(): Boolean;
var
 Format: DXGI_FORMAT;
 TexDesc, NewDesc: D3D10_TEXTURE2D_DESC;
begin
 Result:= False;
 if (not Assigned(D3D10Device))or(not Assigned(FTexture)) then Exit;

 // (1) Find a compatible depth-stencil format.
 Format:= DX10FindDepthStencilFormat(2);
 if (Format = DXGI_FORMAT_UNKNOWN) then Exit;

 // (2) Retrieve the description of the render target texture.
 FillChar(TexDesc, SizeOf(D3D10_TEXTURE2D_DESC), 0);

 PushClearFPUState();
 try
  FTexture.GetDesc(TexDesc);
 finally
  PopFPUState();
 end;

 // (3) Create a new depth-stencil buffer.
 FillChar(NewDesc, SizeOf(D3D10_TEXTURE2D_DESC), 0);

 NewDesc.Format:= Format;
 NewDesc.Width := Width;
 NewDesc.Height:= Height;

 NewDesc.MipLevels:= TexDesc.MipLevels;
 NewDesc.ArraySize:= 1;

 NewDesc.SampleDesc.Count  := TexDesc.SampleDesc.Count;
 NewDesc.SampleDesc.Quality:= TexDesc.SampleDesc.Quality;

 NewDesc.Usage    := D3D10_USAGE_DEFAULT;
 NewDesc.BindFlags:= Ord(D3D10_BIND_DEPTH_STENCIL);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D10Device.CreateTexture2D(NewDesc, nil,
   FDepthStencilTex));
 finally
  PopFPUState();
 end;
 if (not Result) then Exit;

 // (4) Create a depth-stencil view.
 PushClearFPUState();
 try
  Result:= Succeeded(D3D10Device.CreateDepthStencilView(FDepthStencilTex, nil,
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
function TDX10RenderTargetTexture.CreateTextureInstance(): Boolean;
begin
 Result:= (Assigned(D3D10Device))and((FFormat <> apf_Unknown)or
  (FCustomFormat <> DXGI_FORMAT_UNKNOWN));
 if (not Result) then Exit;

 if (IsNativeFormat()) then
  begin
   FFormat:= DX10FindRenderTargetFormat(FFormat, Mipmapping);

   Result:= FFormat <> apf_Unknown;
   if (not Result) then Exit;
  end;

 Result:= CreateTargetTexture();
 if (Result) then Result:= CreateShaderResourceView();
 if (Result) then Result:= CreateRenderTargetView();
 if (Result) then Result:= CreateDepthStencil();
end;

//---------------------------------------------------------------------------
procedure TDX10RenderTargetTexture.DestroyTextureInstance();
begin
 if (Assigned(FDepthStencilView)) then FDepthStencilView:= nil;
 if (Assigned(FDepthStencilTex)) then FDepthStencilTex:= nil;
 if (Assigned(FRenderTargetView)) then FRenderTargetView:= nil;
 if (Assigned(FResourceView)) then FResourceView:= nil;
 if (Assigned(FTexture)) then FTexture:= nil;
end;

//---------------------------------------------------------------------------
function TDX10RenderTargetTexture.CreateTexture(): Boolean;
begin
 Result:= CreateTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX10RenderTargetTexture.DestroyTexture();
begin
 DestroyTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX10RenderTargetTexture.HandleDeviceReset();
begin
 CreateTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX10RenderTargetTexture.HandleDeviceLost();
begin
 DestroyTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX10RenderTargetTexture.UpdateMipmaps();
begin
 if (Assigned(D3D10Device))and(Assigned(FResourceView)) then
  begin
   PushClearFPUState();
   try
    D3D10Device.GenerateMips(FResourceView);
   finally
    PopFPUState();
   end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX10RenderTargetTexture.UpdateSize();
begin
 DestroyTextureInstance();
 CreateTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX10RenderTargetTexture.ResetDefaultViewport();
begin
 FillChar(D3D10Viewport, SizeOf(D3D10_VIEWPORT), 0);

 D3D10Viewport.Width := Width;
 D3D10Viewport.Height:= Height;
 D3D10Viewport.MinDepth:= 0.0;
 D3D10Viewport.MaxDepth:= 1.0;

 PushClearFPUState();
 try
  D3D10Device.RSSetViewports(1, @D3D10Viewport);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX10RenderTargetTexture.BeginDrawTo(): Boolean;
begin
 Result:= (Assigned(D3D10Device))and(Assigned(FRenderTargetView));
 if (not Result) then Exit;

 ActiveRenderTargetView:= FRenderTargetView;
 ActiveDepthStencilView:= FDepthStencilView;

 PushClearFPUState();
 try
  D3D10Device.OMSetRenderTargets(1, @FRenderTargetView, FDepthStencilView);
 finally
  PopFPUState();
 end;

 ResetDefaultViewport();
end;

//---------------------------------------------------------------------------
procedure TDX10RenderTargetTexture.EndDrawTo();
begin
 ActiveRenderTargetView:= nil;
 ActiveDepthStencilView:= nil;
end;

//---------------------------------------------------------------------------
end.
