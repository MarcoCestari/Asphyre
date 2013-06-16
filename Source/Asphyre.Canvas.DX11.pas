unit Asphyre.Canvas.DX11;
//---------------------------------------------------------------------------
// DirectX 11 canvas implementation.
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
 Winapi.Windows, System.Types,
{$else}
 Windows, Types,
{$endif}
 JSB.D3D11, Asphyre.TypeDef, Asphyre.Math,
 Asphyre.Types, Asphyre.Textures, Asphyre.Canvas, Asphyre.Shaders.DX11;

//---------------------------------------------------------------------------
type
 TDX11CanvasTopology = (ctUnknown, ctPoints, ctLines, ctTriangles);
 TDX11CanvasProgram = (cpUnknown, cpSolid, cpTextured, cpTexturedAchromatic);

//---------------------------------------------------------------------------
 TDX11Canvas = class(TAsphyreCanvas)
 private
  SolidEffect: TDX11ShaderEffect;
  TexturedEffect: TDX11ShaderEffect;
  TexturedAchroEffect: TDX11ShaderEffect;

  RasterState: ID3D11RasterizerState;
  DepthStencilState: ID3D11DepthStencilState;

  PointSampler : ID3D11SamplerState;
  LinearSampler: ID3D11SamplerState;
  MipmapSampler: ID3D11SamplerState;

  VertexBuffer: ID3D11Buffer;
  IndexBuffer : ID3D11Buffer;

  BlendingStates: array[TBlendingEffect] of ID3D11BlendState;

  VertexArray: Pointer;
  IndexArray : Pointer;

  ActiveTopology: TDX11CanvasTopology;
  ActiveProgram : TDX11CanvasProgram;
  ActiveEffect  : TDX11ShaderEffect;

  FVertexCount: Integer;
  FIndexCount : Integer;
  FPrimitives : Integer;

  ActiveTexture  : TAsphyreCustomTexture;
  ActiveTexCoords: TPoint4;

  CachedTexture: TAsphyreCustomTexture;
  CachedBlend  : TBlendingEffect;

  NormalSize : TPoint2;
  FAntialias : Boolean;
  FMipmapping: Boolean;
  ScissorRect: TRect;

  procedure CreateEffects();
  procedure DestroyEffects();

  function InitializeEffects(): Boolean;
  procedure FinalizeEffects();

  procedure CreateStaticObjects();
  procedure DestroyStaticObjects();

  function CreateDynamicBuffers(): Boolean;
  procedure DestroyDynamicBuffers();

  function CreateSamplerStates(): Boolean;
  procedure DestroySamplerStates();

  function CreateDeviceStates(): Boolean;
  procedure DestroyDeviceStates();

  procedure CreateBlendStates();
  procedure DestroyBlendStates();

  function CreateDynamicObjects(): Boolean;
  procedure DestroyDynamicObjects();

  procedure ResetRasterState();
  procedure ResetDepthStencilState();

  procedure ResetActiveTexture();

  procedure UpdateSamplerState();
  procedure ResetSamplerState();

  function UploadVertexBuffer(): Boolean;
  function UploadIndexBuffer(): Boolean;
  procedure SetBuffersAndTopology();
  procedure DrawPrimitives();

  function IsTextureAchromatic(Texture: TAsphyreCustomTexture): Boolean;

  function NextVertexEntry(): Pointer;
  procedure AddVertexEntry(const Position, TexCoord: TPoint2; Color: Cardinal);
  procedure AddIndexEntry(Index: Integer);

  function RequestCache(NewTopology: TDX11CanvasTopology;
   NewProgram: TDX11CanvasProgram; Vertices, Indices: Integer;
   BlendType: TBlendingEffect; Texture: TAsphyreCustomTexture): Boolean;
 protected
  function HandleDeviceCreate(): Boolean; override;
  procedure HandleDeviceDestroy(); override;
  function HandleDeviceReset(): Boolean; override;
  procedure HandleDeviceLost(); override;

  procedure HandleBeginScene(); override;
  procedure HandleEndScene(); override;

  procedure GetViewport(out x, y, Width, Height: Integer); override;
  procedure SetViewport(x, y, Width, Height: Integer); override;

  function GetAntialias(): Boolean; override;
  procedure SetAntialias(const Value: Boolean); override;
  function GetMipMapping(): Boolean; override;
  procedure SetMipMapping(const Value: Boolean); override;
 public
  procedure PutPixel(const Point: TPoint2; Color: Cardinal); override;
  procedure Line(const Src, Dest: TPoint2; Color1, Color2: Cardinal); override;

  procedure DrawIndexedTriangles(Vertices: PPoint2; Colors: PLongWord;
   Indices: PLongInt; NoVertices, NoTriangles: Integer;
   Effect: TBlendingEffect = beNormal); override;

  procedure UseTexture(const Texture: TAsphyreCustomTexture;
   const Mapping: TPoint4); override;

  procedure TexMap(const Points: TPoint4; const Colors: TColor4;
   Effect: TBlendingEffect = beNormal); override;

  procedure Flush(); override;
  procedure ResetStates(); override;

  constructor Create(); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//--------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.SysUtils,
{$else}
 SysUtils,
{$endif}
 JSB.DXGI, JSB.D3DCommon, Asphyre.Types.DX11,
 Asphyre.Canvas.DX11.Shaders;

//--------------------------------------------------------------------------
const
 // The following parameters roughly affect the rendering performance. The
 // higher values means that more primitives will fit in cache, but it will
 // also occupy more bandwidth, even when few primitives are rendered.
 //
 // These parameters can be fine-tuned in a finished product to improve the
 // overall performance.
 MaxCachedPrimitives = 8192;
 MaxCachedIndices    = 8192;
 MaxCachedVertices   = 8192;

//---------------------------------------------------------------------------
 CanvasVertexLayout: array[0..2] of D3D11_INPUT_ELEMENT_DESC =
 ((SemanticName: 'POSITION';
   SemanticIndex: 0;
   Format: DXGI_FORMAT_R32G32_FLOAT;
   InputSlot: 0;
   AlignedByteOffset: 0;
   InputSlotClass: D3D11_INPUT_PER_VERTEX_DATA;
   InstanceDataStepRate: 0),

  (SemanticName: 'COLOR';
   SemanticIndex: 0;
   Format: DXGI_FORMAT_R8G8B8A8_UNORM;
   InputSlot: 0;
   AlignedByteOffset: 8;
   InputSlotClass: D3D11_INPUT_PER_VERTEX_DATA;
   InstanceDataStepRate: 0),

  (SemanticName: 'TEXCOORD';
   SemanticIndex: 0;
   Format: DXGI_FORMAT_R32G32_FLOAT;
   InputSlot: 0;
   AlignedByteOffset: 12;
   InputSlotClass: D3D11_INPUT_PER_VERTEX_DATA;
   InstanceDataStepRate: 0));

//--------------------------------------------------------------------------
type
 PVertexRecord = ^TVertexRecord;
 TVertexRecord = packed record
  x, y : Single;
  Color: LongWord;
  u, v : Single;
 end;

//--------------------------------------------------------------------------
constructor TDX11Canvas.Create();
begin
 inherited;

 CreateEffects();

 VertexArray := nil;
 IndexArray  := nil;
 VertexBuffer:= nil;
 IndexBuffer := nil;
end;

//---------------------------------------------------------------------------
destructor TDX11Canvas.Destroy();
begin
 DestroyDynamicObjects();
 DestroyStaticObjects();
 DestroyEffects();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.CreateEffects();
begin
 // (1) Solid canvas effect.
 SolidEffect:= TDX11ShaderEffect.Create();

 SolidEffect.SetVertexLayout(@CanvasVertexLayout[0],
  High(CanvasVertexLayout) + 1);

 SolidEffect.SetShaderCodes(@CanvasVertex[0], High(CanvasVertex) + 1,
  @CanvasSolid[0], High(CanvasSolid) + 1);

 // (2) Textured canvas effect.
 TexturedEffect:= TDX11ShaderEffect.Create();

 TexturedEffect.SetVertexLayout(@CanvasVertexLayout[0],
  High(CanvasVertexLayout) + 1);

 TexturedEffect.SetShaderCodes(@CanvasVertex[0], High(CanvasVertex) + 1,
  @CanvasTextured[0], High(CanvasTextured) + 1);

 // (2) Achromatic textured canvas effect.
 TexturedAchroEffect:= TDX11ShaderEffect.Create();

 TexturedAchroEffect.SetVertexLayout(@CanvasVertexLayout[0],
  High(CanvasVertexLayout) + 1);

 TexturedAchroEffect.SetShaderCodes(@CanvasVertex[0],
  High(CanvasVertex) + 1, @CanvasTexturedAchromatic[0],
  High(CanvasTexturedAchromatic) + 1);
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.DestroyEffects();
begin
 if (Assigned(TexturedAchroEffect)) then FreeAndNil(TexturedAchroEffect);
 if (Assigned(TexturedEffect)) then FreeAndNil(TexturedEffect);
 if (Assigned(SolidEffect)) then FreeAndNil(SolidEffect);
end;

//---------------------------------------------------------------------------
function TDX11Canvas.InitializeEffects(): Boolean;
begin
 Result:= SolidEffect.Initialize();
 if (not Result) then Exit;

 Result:= TexturedEffect.Initialize();
 if (not Result) then
  begin
   SolidEffect.Finalize();
   Exit;
  end;

 Result:= TexturedAchroEffect.Initialize();
 if (not Result) then
  begin
   TexturedEffect.Finalize();
   SolidEffect.Finalize();
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.FinalizeEffects();
begin
 if (Assigned(TexturedAchroEffect)) then
  TexturedAchroEffect.Finalize();

 if (Assigned(TexturedEffect)) then
  TexturedEffect.Finalize();

 if (Assigned(SolidEffect)) then
  SolidEffect.Finalize();
 end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.CreateStaticObjects();
begin
 VertexArray:= AllocMem(MaxCachedVertices * SizeOf(TVertexRecord));
 IndexArray := AllocMem(MaxCachedIndices * SizeOf(Word));
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.DestroyStaticObjects();
begin
 if (Assigned(IndexArray)) then
  FreeNullMem(IndexArray);

 if (Assigned(VertexArray)) then
  FreeNullMem(VertexArray);
end;

//---------------------------------------------------------------------------
function TDX11Canvas.CreateDynamicBuffers(): Boolean;
var
 Desc: D3D11_BUFFER_DESC;
begin
 Result:= Assigned(D3D11Device);
 if (not Result) then Exit;

 // Create Vertex Buffer.
 FillChar(Desc, SizeOf(D3D11_BUFFER_DESC), 0);

 Desc.ByteWidth:= SizeOf(TVertexRecord) * MaxCachedVertices;
 Desc.Usage    := D3D11_USAGE_DYNAMIC;
 Desc.BindFlags:= Ord(D3D11_BIND_VERTEX_BUFFER);
 Desc.MiscFlags:= 0;
 Desc.CPUAccessFlags:= Ord(D3D11_CPU_ACCESS_WRITE);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateBuffer(Desc, nil, VertexBuffer));
 finally
  PopFPUState();
 end;

 if (not Result) then Exit;

 // Create Index Buffer.
 FillChar(Desc, SizeOf(D3D11_BUFFER_DESC), 0);

 Desc.ByteWidth:= SizeOf(Word) * MaxCachedIndices;
 Desc.Usage    := D3D11_USAGE_DYNAMIC;
 Desc.BindFlags:= Ord(D3D11_BIND_INDEX_BUFFER);
 Desc.MiscFlags:= 0;
 Desc.CPUAccessFlags:= Ord(D3D11_CPU_ACCESS_WRITE);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateBuffer(Desc, nil, IndexBuffer));
 finally
  PopFPUState();
 end;

 if (not Result) then
  VertexBuffer:= nil;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.DestroyDynamicBuffers();
begin
 if (Assigned(IndexBuffer)) then IndexBuffer:= nil;
 if (Assigned(VertexBuffer)) then VertexBuffer:= nil;
end;

//---------------------------------------------------------------------------
function TDX11Canvas.CreateSamplerStates(): Boolean;
var
 Desc: D3D11_SAMPLER_DESC;
begin
 Result:= Assigned(D3D11Device);
 if (not Result) then Exit;

 FillChar(Desc, SizeOf(D3D11_SAMPLER_DESC), 0);

 // Create Point Sampler.
 Desc.Filter:= D3D11_FILTER_MIN_MAG_MIP_POINT;
 Desc.AddressU:= D3D11_TEXTURE_ADDRESS_WRAP;
 Desc.AddressV:= D3D11_TEXTURE_ADDRESS_WRAP;
 Desc.AddressW:= D3D11_TEXTURE_ADDRESS_WRAP;
 Desc.MaxAnisotropy:= 1;
 Desc.ComparisonFunc:= D3D11_COMPARISON_NEVER;
 Desc.BorderColor[0]:= 1.0;
 Desc.BorderColor[1]:= 1.0;
 Desc.BorderColor[2]:= 1.0;
 Desc.BorderColor[3]:= 1.0;
 Desc.BorderColor[0]:= 1.0;

 if (D3D11FeatureLevel < D3D_FEATURE_LEVEL_10_0) then
  begin
   Desc.MinLOD:= -D3D11_FLOAT32_MAX;
   Desc.MaxLOD:= D3D11_FLOAT32_MAX;
  end;

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateSamplerState(Desc, PointSampler));
 finally
  PopFPUState();
 end;

 if (not Result) then Exit;

 // Create Linear Sampler.
 Desc.Filter:= D3D11_FILTER_MIN_MAG_LINEAR_MIP_POINT;

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateSamplerState(Desc, LinearSampler));
 finally
  PopFPUState();
 end;

 if (not Result) then
  begin
   PointSampler:= nil;
   Exit;
  end;

 // Create Mipmap Sampler.
 Desc.Filter:= D3D11_FILTER_MIN_MAG_MIP_LINEAR;
 Desc.MinLOD:= -D3D11_FLOAT32_MAX;
 Desc.MaxLOD:= D3D11_FLOAT32_MAX;

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateSamplerState(Desc, MipmapSampler));
 finally
  PopFPUState();
 end;

 if (not Result) then
  begin
   LinearSampler:= nil;
   PointSampler:= nil;
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.DestroySamplerStates();
begin
 if (Assigned(MipmapSampler)) then MipmapSampler:= nil;
 if (Assigned(LinearSampler)) then LinearSampler:= nil;
 if (Assigned(PointSampler)) then PointSampler:= nil;
end;

//--------------------------------------------------------------------------
function TDX11Canvas.CreateDeviceStates(): Boolean;
var
 RasterDesc: D3D11_RASTERIZER_DESC;
 DepthStencilDesc: D3D11_DEPTH_STENCIL_DESC;
begin
 Result:= False;
 if (not Assigned(D3D11Device)) then Exit;

 // Create Raster state.
 FillChar(RasterDesc, SizeOf(D3D11_RASTERIZER_DESC), 0);

 RasterDesc.CullMode:= D3D11_CULL_NONE;
 RasterDesc.FillMode:= D3D11_FILL_SOLID;

 RasterDesc.DepthClipEnable:= True;
 RasterDesc.ScissorEnable  := True;

 RasterDesc.MultisampleEnable    := True;
 RasterDesc.AntialiasedLineEnable:= False;

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateRasterizerState(RasterDesc,
   RasterState));
 finally
  PopFPUState();
 end;

 if (not Result) then Exit;

 // Create Depth/Stencil state.
 FillChar(DepthStencilDesc, SizeOf(D3D11_DEPTH_STENCIL_DESC), 0);

 DepthStencilDesc.DepthEnable:= False;
 DepthStencilDesc.StencilEnable:= False;

 PushClearFPUState();
 try
  D3D11Device.CreateDepthStencilState(DepthStencilDesc, DepthStencilState);
 finally
  PopFPUState();
 end;

 if (not Result) then RasterState:= nil;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.DestroyDeviceStates();
begin
 if (Assigned(DepthStencilState)) then DepthStencilState:= nil;
 if (Assigned(RasterState)) then RasterState:= nil;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.CreateBlendStates();
begin
 // "Normal"
 DX11CreateBasicBlendState(D3D11_BLEND_SRC_ALPHA, D3D11_BLEND_INV_SRC_ALPHA,
  BlendingStates[beNormal]);

 // "Shadow"
 DX11CreateBasicBlendState(D3D11_BLEND_ZERO, D3D11_BLEND_INV_SRC_ALPHA,
  BlendingStates[beShadow]);

 // "Add"
 DX11CreateBasicBlendState(D3D11_BLEND_SRC_ALPHA, D3D11_BLEND_ONE,
  BlendingStates[beAdd]);

 // "Multiply"
 DX11CreateBasicBlendState(D3D11_BLEND_ZERO, D3D11_BLEND_SRC_COLOR,
  BlendingStates[beMultiply]);

 // "InvMultiply"
 DX11CreateBasicBlendState(D3D11_BLEND_ZERO, D3D11_BLEND_INV_SRC_COLOR,
  BlendingStates[beInvMultiply]);

 // "SrcColor"
 DX11CreateBasicBlendState(D3D11_BLEND_SRC_COLOR, D3D11_BLEND_INV_SRC_COLOR,
  BlendingStates[beSrcColor]);

 // "SrcColorAdd"
 DX11CreateBasicBlendState(D3D11_BLEND_SRC_COLOR, D3D11_BLEND_ONE,
  BlendingStates[beSrcColorAdd]);
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.DestroyBlendStates();
var
 State: TBlendingEffect;
begin
 for State:= High(TBlendingEffect) downto Low(TBlendingEffect) do
  if (Assigned(BlendingStates[State])) then BlendingStates[State]:= nil;
end;

//--------------------------------------------------------------------------
function TDX11Canvas.CreateDynamicObjects(): Boolean;
begin
 Result:= InitializeEffects();
 if (not Result) then Exit;

 Result:= CreateDynamicBuffers();
 if (not Result) then
  begin
   FinalizeEffects();
   Exit;
  end;

 Result:= CreateSamplerStates();
 if (not Result) then
  begin
   DestroyDynamicBuffers();
   FinalizeEffects();
   Exit;
  end;

 Result:= CreateDeviceStates();
 if (not Result) then
  begin
   DestroySamplerStates();
   DestroyDynamicBuffers();
   FinalizeEffects();
   Exit;
  end;

 CreateBlendStates();
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.DestroyDynamicObjects();
begin
 DestroyBlendStates();
 DestroyDeviceStates();
 DestroyDynamicBuffers();
 DestroySamplerStates();
 FinalizeEffects();
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.ResetRasterState();
begin
 if (not Assigned(RasterState))or(not Assigned(D3D11Context)) then Exit;

 ScissorRect:= Bounds(
  Round(D3D11Viewport.TopLeftX),
  Round(D3D11Viewport.TopLeftY),
  Round(D3D11Viewport.Width),
  Round(D3D11Viewport.Height));

 PushClearFPUState();
 try
  D3D11Context.RSSetState(RasterState);
  D3D11Context.RSSetScissorRects(1, @ScissorRect);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.ResetDepthStencilState();
begin
 if (not Assigned(DepthStencilState))or(not Assigned(D3D11Context)) then Exit;

 PushClearFPUState();
 try
  D3D11Context.OMSetDepthStencilState(DepthStencilState, 0);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.ResetActiveTexture();
var
 NullView: ID3D11ShaderResourceView;
begin
 if (Assigned(D3D11Context)) then
  begin
   NullView:= nil;

   PushClearFPUState();
   try
    D3D11Context.PSSetShaderResources(0, 1, @NullView);
   finally
    PopFPUState();
   end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.UpdateSamplerState();
begin
 if (not Assigned(D3D11Context)) then Exit;

 PushClearFPUState();
 try
  if (FAntialias)and(FMipmapping) then
   begin
    D3D11Context.PSSetSamplers(0, 1, @MipmapSampler);
   end else
  if (FAntialias)and(not FMipmapping) then
   begin
    D3D11Context.PSSetSamplers(0, 1, @LinearSampler);
   end else
    D3D11Context.PSSetSamplers(0, 1, @PointSampler);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.ResetSamplerState();
var
 NullSampler: ID3D11SamplerState;
begin
 if (Assigned(D3D11Context)) then
  begin
   NullSampler:= nil;

   PushClearFPUState();
   try
    D3D11Context.PSSetSamplers(0, 1, @NullSampler);
   finally
    PopFPUState();
   end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.ResetStates();
begin
 FVertexCount:= 0;
 FIndexCount := 0;
 FPrimitives := 0;

 ActiveTopology:= ctUnknown;
 ActiveProgram := cpUnknown;
 ActiveEffect  := nil;
 CachedBlend   := beUnknown;
 CachedTexture := nil;
 ActiveTexture := nil;

 FillChar(ActiveTexCoords, SizeOf(ActiveTexCoords), 0);

 NormalSize.x:= D3D11Viewport.Width * 0.5;
 NormalSize.y:= D3D11Viewport.Height * 0.5;

 ResetRasterState();
 ResetDepthStencilState();
 ResetActiveTexture();
 ResetSamplerState();

 FAntialias := True;
 FMipmapping:= False;
end;

//--------------------------------------------------------------------------
function TDX11Canvas.HandleDeviceCreate(): Boolean;
begin
 CreateStaticObjects();

 Result:= True;
end;

//--------------------------------------------------------------------------
procedure TDX11Canvas.HandleDeviceDestroy();
begin
 DestroyStaticObjects();
end;

//--------------------------------------------------------------------------
function TDX11Canvas.HandleDeviceReset(): Boolean;
begin
 Result:= CreateDynamicObjects();
end;

//--------------------------------------------------------------------------
procedure TDX11Canvas.HandleDeviceLost();
begin
 DestroyDynamicObjects();
end;

//--------------------------------------------------------------------------
procedure TDX11Canvas.HandleBeginScene();
begin
 ResetStates();
end;

//--------------------------------------------------------------------------
procedure TDX11Canvas.HandleEndScene();
begin
 Flush();
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.GetViewport(out x, y, Width, Height: Integer);
begin
 x:= ScissorRect.Left;
 y:= ScissorRect.Top;

 Width := ScissorRect.Right - ScissorRect.Left;
 Height:= ScissorRect.Bottom - ScissorRect.Top;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.SetViewport(x, y, Width, Height: Integer);
begin
 if (not Assigned(D3D11Device)) then Exit;

 Flush();

 ScissorRect:= Bounds(x, y, Width, Height);

 PushClearFPUState();
 try
  D3D11Context.RSSetScissorRects(1, @ScissorRect);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX11Canvas.GetAntialias(): Boolean;
begin
 Result:= FAntialias;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.SetAntialias(const Value: Boolean);
begin
 Flush();
 FAntialias:= Value;
end;

//---------------------------------------------------------------------------
function TDX11Canvas.GetMipMapping(): Boolean;
begin
 Result:= FMipmapping;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.SetMipMapping(const Value: Boolean);
begin
 Flush();
 FMipmapping:= Value;
end;

//---------------------------------------------------------------------------
function TDX11Canvas.UploadVertexBuffer(): Boolean;
var
 Mapped : D3D11_MAPPED_SUBRESOURCE;
 BufSize: Integer;
begin
 Result:= (Assigned(VertexBuffer))and(Assigned(D3D11Context));
 if (not Result) then Exit;

 Result:= Succeeded(D3D11Context.Map(VertexBuffer, 0, D3D11_MAP_WRITE_DISCARD,
  0, Mapped));
 if (not Result) then Exit;

 BufSize:= FVertexCount * SizeOf(TVertexRecord);

 Move(VertexArray^, Mapped.pData^, BufSize);
 D3D11Context.Unmap(VertexBuffer, 0);
end;

//---------------------------------------------------------------------------
function TDX11Canvas.UploadIndexBuffer(): Boolean;
var
 Mapped : D3D11_MAPPED_SUBRESOURCE;
 BufSize: Integer;
begin
 Result:= (Assigned(IndexBuffer))and(Assigned(D3D11Context));
 if (not Result) then Exit;

 Result:= Succeeded(D3D11Context.Map(IndexBuffer, 0, D3D11_MAP_WRITE_DISCARD,
  0, Mapped));
 if (not Result) then Exit;

 BufSize:= FIndexCount * SizeOf(Word);

 Move(IndexArray^, Mapped.pData^, BufSize);
 D3D11Context.Unmap(IndexBuffer, 0);
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.SetBuffersAndTopology();
var
 VtxStride, VtxOffset: LongWord;
begin
 if (not Assigned(D3D11Context)) then Exit;

 VtxStride:= SizeOf(TVertexRecord);
 VtxOffset:= 0;

 with D3D11Context do
  begin
   IASetVertexBuffers(0, 1, @VertexBuffer, @VtxStride, @VtxOffset);

   case ActiveTopology of
    ctPoints:
     IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_POINTLIST);

    ctLines:
     IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_LINELIST);

    ctTriangles:
     begin
      IASetIndexBuffer(IndexBuffer, DXGI_FORMAT_R16_UINT, 0);
      IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
     end;
   end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.DrawPrimitives();
begin
 if (not Assigned(D3D11Context)) then Exit;

 case ActiveTopology of
  ctPoints,
  ctLines:
   D3D11Context.Draw(FVertexCount, 0);

  ctTriangles:
   D3D11Context.DrawIndexed(FIndexCount, 0, 0);
 end;
end;

//---------------------------------------------------------------------------
function TDX11Canvas.IsTextureAchromatic(
 Texture: TAsphyreCustomTexture): Boolean;
begin
 Result:= (Assigned(Texture))and(Texture.Format <> apf_Unknown);
 if (not Result) then Exit;

 Result:= Texture.Format in [apf_A8L8, apf_A4L4, apf_L8, apf_L16, apf_A5L3];
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.Flush();
var
 Success: Boolean;
begin
 if (FVertexCount > 0)and(FPrimitives > 0) then
  begin
   PushClearFPUState();
   try
    Success:= UploadVertexBuffer();

    if (Success) then
     Success:= UploadIndexBuffer();

    if (Success) then
     begin
      SetBuffersAndTopology();
      DrawPrimitives();
     end;
   finally
    PopFPUState();
   end;

   NextDrawCall();
  end;

 ResetActiveTexture();
 ResetSamplerState();

 if (Assigned(ActiveEffect)) then
  begin
   ActiveEffect.Deactivate();
   ActiveEffect:= nil;
  end;

 FVertexCount:= 0;
 FIndexCount := 0;
 FPrimitives := 0;
 ActiveTopology:= ctUnknown;
 ActiveProgram := cpUnknown;
 CachedBlend:= beUnknown;

 CachedTexture:= nil;
 ActiveTexture:= nil;
end;

//---------------------------------------------------------------------------
function TDX11Canvas.RequestCache(NewTopology: TDX11CanvasTopology;
 NewProgram: TDX11CanvasProgram; Vertices, Indices: Integer;
 BlendType: TBlendingEffect; Texture: TAsphyreCustomTexture): Boolean;
begin
 Result:= (Vertices <= MaxCachedVertices)and(Indices <= MaxCachedIndices);
 if (not Result) then Exit;

 if (Assigned(Texture))and(NewProgram = cpTextured)and
  (IsTextureAchromatic(Texture)) then
  NewProgram:= cpTexturedAchromatic;

 if (FVertexCount + Vertices > MaxCachedVertices)or
  (FIndexCount + Indices > MaxCachedIndices)or
  (ActiveTopology = ctUnknown)or(ActiveTopology <> NewTopology)or
  (ActiveProgram = cpUnknown)or(ActiveProgram <> NewProgram)or
  (CachedBlend = beUnknown)or(CachedBlend <> BlendType)or
  (CachedTexture <> Texture) then
  begin
   Flush();

   if (CachedBlend = beUnknown)or(CachedBlend <> BlendType) then
    DX11SetSimpleBlendState(BlendingStates[BlendType]);

   if (CachedTexture <> Texture) then
    begin
     if (Assigned(Texture)) then
      begin
       Texture.Bind(0);
       UpdateSamplerState();
      end else
      begin
       ResetActiveTexture();
       ResetSamplerState();
      end;
    end;

   if (ActiveProgram = cpUnknown)or(ActiveProgram <> NewProgram) then
    begin
     case NewProgram of
      cpSolid:
       ActiveEffect:= SolidEffect;

      cpTextured:
       ActiveEffect:= TexturedEffect;

      cpTexturedAchromatic:
       ActiveEffect:= TexturedAchroEffect;

      else ActiveEffect:= nil;
     end;

     if (Assigned(ActiveEffect)) then
      Result:= ActiveEffect.Activate();
    end;

   ActiveTopology:= NewTopology;
   ActiveProgram := NewProgram;
   CachedBlend   := BlendType;
   CachedTexture := Texture;
  end;
end;

//---------------------------------------------------------------------------
function TDX11Canvas.NextVertexEntry(): Pointer;
begin
 Result:= Pointer(PtrInt(VertexArray) + FVertexCount * SizeOf(TVertexRecord));
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.AddIndexEntry(Index: Integer);
var
 Entry: PWord;
begin
 Entry:= Pointer(PtrInt(IndexArray) + FIndexCount * SizeOf(Word));
 Entry^:= Index;

 Inc(FIndexCount);
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.AddVertexEntry(const Position, TexCoord: TPoint2;
 Color: Cardinal);
var
 NormAt: TPoint2;
 Entry : PVertexRecord;
begin
 NormAt.x:= (Position.x - NormalSize.x) / NormalSize.x;
 NormAt.y:= (Position.y - NormalSize.y) / NormalSize.y;

 Entry:= NextVertexEntry();
 Entry.x:= NormAt.x;
 Entry.y:= -NormAt.y;
 Entry.Color:= DisplaceRB(Color);
 Entry.u:= TexCoord.x;
 Entry.v:= TexCoord.y;

 Inc(FVertexCount);
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.PutPixel(const Point: TPoint2; Color: Cardinal);
begin
 if (not RequestCache(ctPoints, cpSolid, 1, 0, beNormal, nil)) then Exit;

 AddVertexEntry(Point + Point2(0.5, 0.5), ZeroVec2, Color);
 Inc(FPrimitives);
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.Line(const Src, Dest: TPoint2; Color1, Color2: Cardinal);
begin
 if (not RequestCache(ctLines, cpSolid, 2, 0, beNormal, nil)) then Exit;

 AddVertexEntry(Src + Point2(0.5, 0.5), ZeroVec2, Color1);
 AddVertexEntry(Dest + Point2(0.5, 0.5), ZeroVec2, Color2);

 Inc(FPrimitives);
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.DrawIndexedTriangles(Vertices: PPoint2; Colors: PLongWord;
 Indices: PLongInt; NoVertices, NoTriangles: Integer;
 Effect: TBlendingEffect = beNormal);
var
 Index : PLongInt;
 Vertex: PPoint2;
 Color : PLongWord;
 i     : Integer;
begin
 if (not RequestCache(ctTriangles, cpSolid, NoVertices, NoTriangles * 3,
  Effect, nil)) then Exit;

 Index:= Indices;

 for i:= 0 to (NoTriangles * 3) - 1 do
  begin
   AddIndexEntry(FVertexCount + Index^);
   Inc(Index);
  end;

 Vertex:= Vertices;
 Color := Colors;

 for i:= 0 to NoVertices - 1 do
  begin
   AddVertexEntry(Vertex^, ZeroVec2, Color^);

   Inc(Vertex);
   Inc(Color);
  end;

 Inc(FPrimitives, NoTriangles);
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.UseTexture(const Texture: TAsphyreCustomTexture;
 const Mapping: TPoint4);
begin
 ActiveTexture  := Texture;
 ActiveTexCoords:= Mapping;
end;

//---------------------------------------------------------------------------
procedure TDX11Canvas.TexMap(const Points: TPoint4; const Colors: TColor4;
 Effect: TBlendingEffect);
begin
 RequestCache(ctTriangles, cpTextured, 4, 6, Effect, ActiveTexture);

 AddIndexEntry(FVertexCount + 2);
 AddIndexEntry(FVertexCount);
 AddIndexEntry(FVertexCount + 1);

 AddIndexEntry(FVertexCount + 3);
 AddIndexEntry(FVertexCount + 2);
 AddIndexEntry(FVertexCount + 1);

 AddVertexEntry(Point2(Points[0].x, Points[0].y), ActiveTexCoords[0],
  Colors[0]);

 AddVertexEntry(Point2(Points[1].x, Points[1].y), ActiveTexCoords[1],
  Colors[1]);

 AddVertexEntry(Point2(Points[3].x, Points[3].y), ActiveTexCoords[3],
  Colors[3]);

 AddVertexEntry(Point2(Points[2].x, Points[2].y), ActiveTexCoords[2],
  Colors[2]);

 Inc(FPrimitives, 2);
end;

//---------------------------------------------------------------------------
end.

