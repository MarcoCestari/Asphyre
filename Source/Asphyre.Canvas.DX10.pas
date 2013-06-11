unit Asphyre.Canvas.DX10;
//---------------------------------------------------------------------------
// Direct3D 10.x canvas implementation.
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
 Winapi.Windows, JSB.D3D10, JSB.D3D10_1, System.Types, Asphyre.TypeDef,
 Asphyre.Math, Asphyre.Types, Asphyre.Textures, Asphyre.Canvas,
 Asphyre.Shaders.DX10;

//---------------------------------------------------------------------------
// Remove the dot "." to load the canvas default effect from file instead of
// the embedded one.
//---------------------------------------------------------------------------
{.$define DX10CanvasEffectDebug}

//---------------------------------------------------------------------------
type
 TDX10CanvasTopology = (ctUnknown, ctPoints, ctLines, ctTriangles);

//---------------------------------------------------------------------------
 TDX10Canvas = class(TAsphyreCanvas)
 private
  FEffect: TDX10CanvasEffect;

  FCustomEffect: TDX10CanvasEffect;
  FCustomTechnique: StdString;

  RasterState: ID3D10RasterizerState;
  DepthStencilState: ID3D10DepthStencilState;

  VertexBuffer: ID3D10Buffer;
  IndexBuffer : ID3D10Buffer;

  BlendingStates: array[TBlendingEffect] of ID3D10BlendState;
  BlendingStates1: array[TBlendingEffect] of ID3D10BlendState1;

  VertexArray: Pointer;
  IndexArray : Pointer;

  ActiveTopology: TDX10CanvasTopology;

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

  procedure SetCustomEffect(const Value: TDX10CanvasEffect);
  procedure SetCustomTechnique(const Value: StdString);

  procedure CreateStaticBuffers();
  procedure DestroyStaticBuffers();

  function LoadCanvasEffect(): Boolean;
  function CreateVertexBuffer(): Boolean;
  function CreateIndexBuffer(): Boolean;

  procedure CreateRasterState();
  procedure CreateDepthStencilState();

  procedure CreateBlendStates();
  procedure DestroyBlendStates();

  function CreateDynamicObjects(): Boolean;
  procedure DestroyDynamicObjects();

  procedure ResetRasterState();
  procedure ResetDepthStencilState();

  function UploadVertexBuffer(): Boolean;
  function UploadIndexBuffer(): Boolean;
  procedure SetBuffersAndTopology();
  procedure DrawPrimitives();
  procedure DrawTechBuffers(const TechName: StdString);
  procedure DrawCustomBuffers();

  function IsTextureLumAlpha(): Boolean;
  function IsTextureLumOnly(): Boolean;
  procedure DrawBuffers();

  function NextVertexEntry(): Pointer;
  procedure AddVertexEntry1(const Vtx: TPoint2; Color: Cardinal);
  procedure AddVertexEntry2(const Vtx, TexAt: TPoint2; Color: Cardinal);
  procedure AddIndexEntry(Index: Integer);
  function RequestCache(Mode: TDX10CanvasTopology; Vertices, Indices: Integer;
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
  property Effect: TDX10CanvasEffect read FEffect;

  property CustomEffect: TDX10CanvasEffect read FCustomEffect
   write SetCustomEffect;

  property CustomTechnique: StdString read FCustomTechnique
   write SetCustomTechnique;

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
 System.SysUtils, System.Math, JSB.D3DCommon, JSB.DXGI, Asphyre.Types.DX10,
 Asphyre.Canvas.DX10.Shaders;

//--------------------------------------------------------------------------
const
 // The following parameters roughly affect the rendering performance. The
 // higher values means that more primitives will fit in cache, but it will
 // also occupy more bandwidth, even when few primitives are rendered.
 //
 // These parameters can be fine-tuned in a finished product to improve the
 // overall performance.
 MaxCachedPrimitives = 3072;
 MaxCachedIndices    = 4096;
 MaxCachedVertices   = 4096;

//---------------------------------------------------------------------------
 CanvasVertexLayout: array[0..2] of D3D10_INPUT_ELEMENT_DESC =
 ((SemanticName: 'POSITION';
   SemanticIndex: 0;
   Format: DXGI_FORMAT_R32G32_FLOAT;
   InputSlot: 0;
   AlignedByteOffset: 0;
   InputSlotClass: D3D10_INPUT_PER_VERTEX_DATA;
   InstanceDataStepRate: 0),

  (SemanticName: 'COLOR';
   SemanticIndex: 0;
   Format: DXGI_FORMAT_R8G8B8A8_UNORM;
   InputSlot: 0;
   AlignedByteOffset: 8;
   InputSlotClass: D3D10_INPUT_PER_VERTEX_DATA;
   InstanceDataStepRate: 0),

  (SemanticName: 'TEXCOORD';
   SemanticIndex: 0;
   Format: DXGI_FORMAT_R32G32_FLOAT;
   InputSlot: 0;
   AlignedByteOffset: 12;
   InputSlotClass: D3D10_INPUT_PER_VERTEX_DATA;
   InstanceDataStepRate: 0));

//--------------------------------------------------------------------------
 DebugCanvasEffectFile = 'Asphyre.Canvas.DX10.fx';

//--------------------------------------------------------------------------
 TextureVariable = 'SourceTex';

//--------------------------------------------------------------------------
 TechSimpleColorFill = 'SimpleColorFill';

//--------------------------------------------------------------------------
 TechMipTextureRGBA = 'MipTextureRGBA';

//--------------------------------------------------------------------------
 TechLinearTextureRGBA = 'LinearTextureRGBA';

//--------------------------------------------------------------------------
 TechPointTextureRGBA = 'PointTextureRGBA';

//--------------------------------------------------------------------------
 TechMipTextureLA = 'MipTextureLA';

//--------------------------------------------------------------------------
 TechPointTextureLA = 'PointTextureLA';

//--------------------------------------------------------------------------
 TechMipTextureL = 'MipTextureL';

//--------------------------------------------------------------------------
type
 PVertexRecord = ^TVertexRecord;
 TVertexRecord = packed record
  x, y : Single;
  Color: LongWord;
  u, v : Single;
 end;

//--------------------------------------------------------------------------
constructor TDX10Canvas.Create();
begin
 inherited;

 FEffect:= TDX10CanvasEffect.Create();

 FCustomEffect:= nil;
 FCustomTechnique:= '';

 VertexArray := nil;
 IndexArray  := nil;
 VertexBuffer:= nil;
 IndexBuffer := nil;
end;

//---------------------------------------------------------------------------
destructor TDX10Canvas.Destroy();
begin
 DestroyDynamicObjects();
 DestroyStaticBuffers();
 FreeAndNil(FEffect);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.SetCustomEffect(const Value: TDX10CanvasEffect);
begin
 if (FCustomEffect = Value) then Exit;

 if (FCustomTechnique <> '') then Flush();

 FCustomEffect:= Value;

 if (Assigned(FCustomEffect)) then
  begin
   FCustomEffect.Techniques.LayoutDecl:= @CanvasVertexLayout[0];
   FCustomEffect.Techniques.LayoutDeclCount:= High(CanvasVertexLayout) + 1;
  end else FCustomTechnique:= '';
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.SetCustomTechnique(const Value: StdString);
begin
 if (Assigned(FCustomEffect))and(FCustomTechnique <> Value) then Flush();

 FCustomTechnique:= Value;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.CreateStaticBuffers();
begin
 ReallocMem(VertexArray, MaxCachedVertices * SizeOf(TVertexRecord));
 FillChar(VertexArray^, MaxCachedVertices * SizeOf(TVertexRecord), 0);

 ReallocMem(IndexArray, MaxCachedIndices * SizeOf(Word));
 FillChar(IndexArray^, MaxCachedIndices * SizeOf(Word), 0);
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.DestroyStaticBuffers();
begin
 if (Assigned(IndexArray)) then FreeNullMem(IndexArray);
 if (Assigned(VertexArray)) then FreeNullMem(VertexArray);
end;

//---------------------------------------------------------------------------
function TDX10Canvas.CreateVertexBuffer(): Boolean;
var
 Desc: D3D10_BUFFER_DESC;
begin
 Result:= Assigned(D3D10Device);
 if (not Result) then Exit;

 FillChar(Desc, SizeOf(D3D10_BUFFER_DESC), 0);

 Desc.ByteWidth:= SizeOf(TVertexRecord) * MaxCachedVertices;
 Desc.Usage    := D3D10_USAGE_DYNAMIC;
 Desc.BindFlags:= Ord(D3D10_BIND_VERTEX_BUFFER);
 Desc.MiscFlags:= 0;
 Desc.CPUAccessFlags:= Ord(D3D10_CPU_ACCESS_WRITE);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D10Device.CreateBuffer(Desc, nil, VertexBuffer));
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX10Canvas.CreateIndexBuffer(): Boolean;
var
 Desc: D3D10_BUFFER_DESC;
begin
 Result:= Assigned(D3D10Device);
 if (not Result) then Exit;

 FillChar(Desc, SizeOf(D3D10_BUFFER_DESC), 0);

 Desc.ByteWidth:= SizeOf(Word) * MaxCachedIndices;
 Desc.Usage    := D3D10_USAGE_DYNAMIC;
 Desc.BindFlags:= Ord(D3D10_BIND_INDEX_BUFFER);
 Desc.MiscFlags:= 0;
 Desc.CPUAccessFlags:= Ord(D3D10_CPU_ACCESS_WRITE);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D10Device.CreateBuffer(Desc, nil, IndexBuffer));
 finally
  PopFPUState();
 end;
end;

//--------------------------------------------------------------------------
procedure TDX10Canvas.CreateRasterState();
var
 Desc: D3D10_RASTERIZER_DESC;
begin
 if (not Assigned(D3D10Device)) then Exit;

 FillChar(Desc, SizeOf(D3D10_RASTERIZER_DESC), 0);

 Desc.CullMode:= D3D10_CULL_NONE;
 Desc.FillMode:= D3D10_FILL_SOLID;

 Desc.DepthClipEnable:= False;
 Desc.ScissorEnable  := True;

 Desc.MultisampleEnable    := True;
 Desc.AntialiasedLineEnable:= False;

 PushClearFPUState();
 try
  D3D10Device.CreateRasterizerState(Desc, RasterState);
 finally
  PopFPUState();
 end;
end;

//--------------------------------------------------------------------------
procedure TDX10Canvas.CreateDepthStencilState();
var
 Desc: D3D10_DEPTH_STENCIL_DESC;
begin
 if (not Assigned(D3D10Device)) then Exit;

 FillChar(Desc, SizeOf(D3D10_DEPTH_STENCIL_DESC), 0);

 Desc.DepthEnable:= False;
 Desc.StencilEnable:= False;

 PushClearFPUState();
 try
  D3D10Device.CreateDepthStencilState(Desc, DepthStencilState);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.CreateBlendStates();
begin
 if (D3D10Mode >= dmDirectX10_1) then
  begin // Direct3D 10.1
   // "Normal"
   DX10CreateBasicBlendState1(D3D10_BLEND_SRC_ALPHA, D3D10_BLEND_INV_SRC_ALPHA,
    BlendingStates1[beNormal]);

   // "Shadow"
   DX10CreateBasicBlendState1(D3D10_BLEND_ZERO, D3D10_BLEND_INV_SRC_ALPHA,
    BlendingStates1[beShadow]);

   // "Add"
   DX10CreateBasicBlendState1(D3D10_BLEND_SRC_ALPHA, D3D10_BLEND_ONE,
    BlendingStates1[beAdd]);

   // "Multiply"
   DX10CreateBasicBlendState1(D3D10_BLEND_ZERO, D3D10_BLEND_SRC_COLOR,
    BlendingStates1[beMultiply]);

   // "InvMultiply"
   DX10CreateBasicBlendState1(D3D10_BLEND_ZERO, D3D10_BLEND_INV_SRC_COLOR,
    BlendingStates1[beInvMultiply]);

   // "SrcColor"
   DX10CreateBasicBlendState1(D3D10_BLEND_SRC_COLOR, D3D10_BLEND_INV_SRC_COLOR,
    BlendingStates1[beSrcColor]);

   // "SrcColorAdd"
   DX10CreateBasicBlendState1(D3D10_BLEND_SRC_COLOR, D3D10_BLEND_ONE,
    BlendingStates1[beSrcColorAdd]);
  end else
  begin // Direct3D 10.0
   // "Normal"
   DX10CreateBasicBlendState(D3D10_BLEND_SRC_ALPHA, D3D10_BLEND_INV_SRC_ALPHA,
    BlendingStates[beNormal]);

   // "Shadow"
   DX10CreateBasicBlendState(D3D10_BLEND_ZERO, D3D10_BLEND_INV_SRC_ALPHA,
    BlendingStates[beShadow]);

   // "Add"
   DX10CreateBasicBlendState(D3D10_BLEND_SRC_ALPHA, D3D10_BLEND_ONE,
    BlendingStates[beAdd]);

   // "Multiply"
   DX10CreateBasicBlendState(D3D10_BLEND_ZERO, D3D10_BLEND_SRC_COLOR,
    BlendingStates[beMultiply]);

   // "InvMultiply"
   DX10CreateBasicBlendState(D3D10_BLEND_ZERO, D3D10_BLEND_INV_SRC_COLOR,
    BlendingStates[beInvMultiply]);

   // "SrcColor"
   DX10CreateBasicBlendState(D3D10_BLEND_SRC_COLOR, D3D10_BLEND_INV_SRC_COLOR,
    BlendingStates[beSrcColor]);

   // "SrcColorAdd"
   DX10CreateBasicBlendState(D3D10_BLEND_SRC_COLOR, D3D10_BLEND_ONE,
    BlendingStates[beSrcColorAdd]);
  end;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.DestroyBlendStates();
var
 State: TBlendingEffect;
begin
 for State:= High(TBlendingEffect) downto Low(TBlendingEffect) do
  begin
   if (Assigned(BlendingStates1[State])) then BlendingStates1[State]:= nil;
   if (Assigned(BlendingStates[State])) then BlendingStates[State]:= nil;
  end;
end;

//---------------------------------------------------------------------------
function TDX10Canvas.LoadCanvasEffect(): Boolean;
{$ifndef DX10CanvasEffectDebug}
var
 Data: Pointer;
 DataSize: Integer;
{$endif}
begin
 {$ifdef DX10CanvasEffectDebug}
 Result:= FEffect.CompileFromFile(DebugCanvasEffectFile);
 if (not Result) then Exit;
 {$else}
 CreateDX10CanvasEffect(Data, DataSize);

 Result:= (Assigned(Data))and(DataSize > 0);
 if (not Result) then
  begin
   if (Assigned(Data)) then FreeNullMem(Data);
   Exit;
  end;

 Result:= FEffect.LoadCompiledFromMem(Data, DataSize);
 FreeNullMem(Data);
 {$endif}

 if (Result) then
  begin
   FEffect.Techniques.LayoutDecl:= @CanvasVertexLayout[0];
   FEffect.Techniques.LayoutDeclCount:= High(CanvasVertexLayout) + 1;
  end;
end;

//--------------------------------------------------------------------------
function TDX10Canvas.CreateDynamicObjects(): Boolean;
begin
 Result:= LoadCanvasEffect();
 if (not Result) then Exit;

 if (Result) then Result:= CreateVertexBuffer();
 if (Result) then Result:= CreateIndexBuffer();

 if (Result) then
  begin
   CreateRasterState();
   CreateDepthStencilState();
   CreateBlendStates();
  end;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.DestroyDynamicObjects();
begin
 DestroyBlendStates();
 if (Assigned(DepthStencilState)) then DepthStencilState:= nil;
 if (Assigned(RasterState)) then RasterState:= nil;
 if (Assigned(IndexBuffer)) then IndexBuffer:= nil;
 if (Assigned(VertexBuffer)) then VertexBuffer:= nil;

 FEffect.ReleaseAll();
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.ResetRasterState();
begin
 if (not Assigned(RasterState))or(not Assigned(D3D10Device)) then Exit;

 ScissorRect:= Bounds(D3D10Viewport.TopLeftX, D3D10Viewport.TopLeftY,
  D3D10Viewport.Width, D3D10Viewport.Height);

 PushClearFPUState();
 try
  D3D10Device.RSSetState(RasterState);
  D3D10Device.RSSetScissorRects(1, @ScissorRect);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.ResetDepthStencilState();
begin
 if (not Assigned(DepthStencilState))or(not Assigned(D3D10Device)) then Exit;

 PushClearFPUState();
 try
  D3D10Device.OMSetDepthStencilState(DepthStencilState, 0);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.ResetStates();
begin
 FVertexCount:= 0;
 FIndexCount := 0;
 FPrimitives := 0;

 ActiveTopology:= ctUnknown;
 CachedBlend   := beUnknown;
 CachedTexture := nil;
 ActiveTexture := nil;

 FillChar(ActiveTexCoords, SizeOf(ActiveTexCoords), 0);

 NormalSize.x:= D3D10Viewport.Width * 0.5;
 NormalSize.y:= D3D10Viewport.Height * 0.5;

 ResetRasterState();
 ResetDepthStencilState();

 FAntialias := True;
 FMipmapping:= False;

 FCustomTechnique:= '';
end;

//--------------------------------------------------------------------------
function TDX10Canvas.HandleDeviceCreate(): Boolean;
begin
 CreateStaticBuffers();

 Result:= True;
end;

//--------------------------------------------------------------------------
procedure TDX10Canvas.HandleDeviceDestroy();
begin
 DestroyStaticBuffers();
end;

//--------------------------------------------------------------------------
function TDX10Canvas.HandleDeviceReset(): Boolean;
begin
 Result:= CreateDynamicObjects();
end;

//--------------------------------------------------------------------------
procedure TDX10Canvas.HandleDeviceLost();
begin
 DestroyDynamicObjects();
end;

//--------------------------------------------------------------------------
procedure TDX10Canvas.HandleBeginScene();
begin
 ResetStates();
end;

//--------------------------------------------------------------------------
procedure TDX10Canvas.HandleEndScene();
begin
 Flush();
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.GetViewport(out x, y, Width, Height: Integer);
begin
 x:= ScissorRect.Left;
 y:= ScissorRect.Top;

 Width := ScissorRect.Right - ScissorRect.Left;
 Height:= ScissorRect.Bottom - ScissorRect.Top;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.SetViewport(x, y, Width, Height: Integer);
begin
 if (not Assigned(D3D10Device)) then Exit;

 Flush();

 ScissorRect:= Bounds(x, y, Width, Height);

 PushClearFPUState();
 try
  D3D10Device.RSSetScissorRects(1, @ScissorRect);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX10Canvas.GetAntialias(): Boolean;
begin
 Result:= FAntialias;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.SetAntialias(const Value: Boolean);
begin
 Flush();
 FAntialias:= Value;
end;

//---------------------------------------------------------------------------
function TDX10Canvas.GetMipMapping(): Boolean;
begin
 Result:= FMipmapping;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.SetMipMapping(const Value: Boolean);
begin
 Flush();
 FMipmapping:= Value;
end;

//---------------------------------------------------------------------------
function TDX10Canvas.UploadVertexBuffer(): Boolean;
var
 MemAddr: Pointer;
 BufSize: Integer;
begin
 Result:= Assigned(VertexBuffer);
 if (not Result) then Exit;

 PushClearFPUState();
 try
  Result:= Succeeded(VertexBuffer.Map(D3D10_MAP_WRITE_DISCARD, 0, MemAddr));
  if (not Result) then Exit;

  BufSize:= FVertexCount * SizeOf(TVertexRecord);

  Move(VertexArray^, MemAddr^, BufSize);
  VertexBuffer.Unmap();
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function TDX10Canvas.UploadIndexBuffer(): Boolean;
var
 MemAddr: Pointer;
 BufSize: Integer;
begin
 Result:= Assigned(IndexBuffer);
 if (not Result) then Exit;

 PushClearFPUState();
 try
  Result:= Succeeded(IndexBuffer.Map(D3D10_MAP_WRITE_DISCARD, 0, MemAddr));
  if (not Result) then Exit;

  BufSize:= FIndexCount * SizeOf(Word);

  Move(IndexArray^, MemAddr^, BufSize);
  IndexBuffer.Unmap();
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.SetBuffersAndTopology();
var
 VtxStride, VtxOffset: LongWord;
begin
 if (not Assigned(D3D10Device))or(not Assigned(VertexBuffer)) then Exit;

 VtxStride:= SizeOf(TVertexRecord);
 VtxOffset:= 0;

 PushClearFPUState();
 try
  with D3D10Device do
   begin
    IASetVertexBuffers(0, 1, @VertexBuffer, @VtxStride, @VtxOffset);
    IASetIndexBuffer(IndexBuffer, DXGI_FORMAT_R16_UINT, 0);

    case ActiveTopology of
     ctPoints:
      IASetPrimitiveTopology(D3D10_PRIMITIVE_TOPOLOGY_POINTLIST);

     ctLines:
      IASetPrimitiveTopology(D3D10_PRIMITIVE_TOPOLOGY_LINELIST);

     ctTriangles:
      IASetPrimitiveTopology(D3D10_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    end;
   end;
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.DrawPrimitives();
begin
 if (not Assigned(D3D10Device)) then Exit;

 PushClearFPUState();
 try
  case ActiveTopology of
   ctPoints,
   ctLines:
    D3D10Device.Draw(FVertexCount, 0);

   ctTriangles:
    D3D10Device.DrawIndexed(FIndexCount, 0, 0);
  end;
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.DrawTechBuffers(const TechName: StdString);
begin
 if (not FEffect.Active) then Exit;

 if (not FEffect.Techniques.CheckLayoutStatus(TechName)) then Exit;
 FEffect.Techniques.SetLayout();

 SetBuffersAndTopology();
 if (not FEffect.Techniques.Apply(TechName)) then Exit;

 DrawPrimitives();
 NextDrawCall();
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.DrawCustomBuffers();
begin
 if (not FCustomEffect.Active) then Exit;

 if (not FCustomEffect.Techniques.CheckLayoutStatus(FCustomTechnique)) then Exit;
 FCustomEffect.Techniques.SetLayout();

 SetBuffersAndTopology();
 if (not FCustomEffect.Techniques.Apply(FCustomTechnique)) then Exit;

 DrawPrimitives();
 NextDrawCall();
end;

//---------------------------------------------------------------------------
function TDX10Canvas.IsTextureLumAlpha(): Boolean;
begin
 Result:= (Assigned(CachedTexture))and(CachedTexture.Format <> apf_Unknown);
 if (not Result) then Exit;

 Result:= CachedTexture.Format in [apf_A8L8, apf_A4L4];
end;

//---------------------------------------------------------------------------
function TDX10Canvas.IsTextureLumOnly(): Boolean;
begin
 Result:= (Assigned(CachedTexture))and(CachedTexture.Format <> apf_Unknown);
 if (not Result) then Exit;

 Result:= CachedTexture.Format in [apf_L8, apf_L16];
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.DrawBuffers();
begin
 if (Assigned(FCustomEffect))and(FCustomTechnique <> '') then
  begin
   DrawCustomBuffers();
   Exit;
  end;

 if (not Assigned(CachedTexture)) then
  begin
   DrawTechBuffers(TechSimpleColorFill);
   Exit;
  end;

 if (IsTextureLumAlpha()) then
  begin
   if (FAntialias) then DrawTechBuffers(TechMipTextureLA)
    else DrawTechBuffers(TechPointTextureLA);

   Exit;
  end;

 if (IsTextureLumOnly()) then
  begin
   DrawTechBuffers(TechMipTextureL);
   Exit;
  end;

 if (FAntialias) then
  begin
   if (FMipmapping) then DrawTechBuffers(TechMipTextureRGBA)
    else DrawTechBuffers(TechLinearTextureRGBA);
  end else DrawTechBuffers(TechPointTextureRGBA);
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.Flush();
var
 Success: Boolean;
begin
 if (FVertexCount > 0)and(FPrimitives > 0) then
  begin
   PushClearFPUState();
   try
    Success:= UploadVertexBuffer();
    if (Success) then Success:= UploadIndexBuffer();
   finally
    PopFPUState();
   end;

   if (Success) then DrawBuffers();
  end;

 if (Assigned(FEffect))and(FEffect.Active) then
  FEffect.Variables.SetShaderResource(TextureVariable, nil);

 if (Assigned(FCustomEffect))and(FCustomEffect.Active) then
  FCustomEffect.Variables.SetShaderResource(TextureVariable, nil);

 FVertexCount:= 0;
 FIndexCount := 0;
 FPrimitives := 0;
 ActiveTopology := ctUnknown;
 CachedBlend:= beUnknown;

 CachedTexture:= nil;
 ActiveTexture:= nil;
end;

//---------------------------------------------------------------------------
function TDX10Canvas.RequestCache(Mode: TDX10CanvasTopology; Vertices,
 Indices: Integer; BlendType: TBlendingEffect;
 Texture: TAsphyreCustomTexture): Boolean;
var
 NeedReset: Boolean;
 ResourceView: Pointer;
begin
 Result:= (Vertices <= MaxCachedVertices)and(Indices <= MaxCachedIndices);
 if (not Result) then Exit;

 NeedReset:= (FVertexCount + Vertices > MaxCachedVertices);
 NeedReset:= (NeedReset)or(FIndexCount + Indices > MaxCachedIndices);
 NeedReset:= (NeedReset)or(ActiveTopology = ctUnknown)or(ActiveTopology <> Mode);
 NeedReset:= (NeedReset)or(CachedBlend = beUnknown)or(CachedBlend <> BlendType);
 NeedReset:= (NeedReset)or(CachedTexture <> Texture);

 if (NeedReset) then
  begin
   Flush();

   if (CachedBlend = beUnknown)or(CachedBlend <> BlendType) then
    begin
     if (D3D10Mode >= dmDirectX10_1) then
      DX10SetSimpleBlendState1(BlendingStates1[BlendType])
       else DX10SetSimpleBlendState(BlendingStates[BlendType]);
    end;

   if ((CachedBlend = beUnknown)or(CachedTexture <> Texture)) then
    begin
     ResourceView:= nil;
     if (Assigned(Texture)) then ResourceView:= Texture.GetResourceView();

     if (Assigned(FEffect))and(FEffect.Active) then
      FEffect.Variables.SetShaderResource(TextureVariable,
       ID3D10ShaderResourceView(ResourceView));

     if (Assigned(FCustomEffect))and(FCustomEffect.Active) then
      FCustomEffect.Variables.SetShaderResource(TextureVariable,
       ID3D10ShaderResourceView(ResourceView));
    end;

   ActiveTopology:= Mode;
   CachedBlend   := BlendType;
   CachedTexture := Texture;
  end;
end;

//---------------------------------------------------------------------------
function TDX10Canvas.NextVertexEntry(): Pointer;
begin
 Result:= Pointer(PtrInt(VertexArray) + FVertexCount * SizeOf(TVertexRecord));
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.AddIndexEntry(Index: Integer);
var
 Entry: PWord;
begin
 Entry:= Pointer(PtrInt(IndexArray) + FIndexCount * SizeOf(Word));
 Entry^:= Index;

 Inc(FIndexCount);
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.AddVertexEntry1(const Vtx: TPoint2; Color: Cardinal);
var
 NormAt: TPoint2;
 Entry : PVertexRecord;
begin
 NormAt.x:= (Vtx.x - NormalSize.x) / NormalSize.x;
 NormAt.y:= (Vtx.y - NormalSize.y) / NormalSize.y;

 Entry:= NextVertexEntry();
 Entry.x:= NormAt.x;
 Entry.y:= -NormAt.y;
 Entry.Color:= DisplaceRB(Color);
 Entry.u:= 0.0;
 Entry.v:= 0.0;

 Inc(FVertexCount);
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.AddVertexEntry2(const Vtx, TexAt: TPoint2;
 Color: Cardinal);
var
 NormAt: TPoint2;
 Entry : PVertexRecord;
begin
 NormAt.x:= (Vtx.x - NormalSize.x) / NormalSize.x;
 NormAt.y:= (Vtx.y - NormalSize.y) / NormalSize.y;

 Entry:= NextVertexEntry();
 Entry.x:= NormAt.x;
 Entry.y:= -NormAt.y;
 Entry.Color:= DisplaceRB(Color);
 Entry.u:= TexAt.x;
 Entry.v:= TexAt.y;

 Inc(FVertexCount);
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.PutPixel(const Point: TPoint2; Color: Cardinal);
begin
 if (not RequestCache(ctPoints, 1, 0, beNormal, nil)) then Exit;

 AddVertexEntry1(Point + Point2(0.5, 0.5), Color);
 Inc(FPrimitives);
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.Line(const Src, Dest: TPoint2; Color1, Color2: Cardinal);
begin
 if (not RequestCache(ctLines, 2, 0, beNormal, nil)) then Exit;

 AddVertexEntry1(Src + Point2(0.5, 0.5), Color1);
 AddVertexEntry1(Dest + Point2(0.5, 0.5), Color2);

 Inc(FPrimitives);
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.DrawIndexedTriangles(Vertices: PPoint2; Colors: PLongWord;
Indices: PLongInt; NoVertices, NoTriangles: Integer;
Effect: TBlendingEffect = beNormal);
var
 Index : PLongInt;
 Vertex: PPoint2;
 Color : PLongWord;
 i     : Integer;
begin
 if (not RequestCache(ctTriangles, NoVertices, NoTriangles * 3, Effect,
  nil)) then Exit;

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
   AddVertexEntry1(Point2(Vertex.x, Vertex.y), Color^);

   Inc(Vertex);
   Inc(Color);
  end;

 Inc(FPrimitives, NoTriangles);
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.UseTexture(const Texture: TAsphyreCustomTexture;
 const Mapping: TPoint4);
begin
 ActiveTexture  := Texture;
 ActiveTexCoords:= Mapping;
end;

//---------------------------------------------------------------------------
procedure TDX10Canvas.TexMap(const Points: TPoint4; const Colors: TColor4;
 Effect: TBlendingEffect);
begin
 RequestCache(ctTriangles, 4, 6, Effect, ActiveTexture);

 AddIndexEntry(FVertexCount + 2);
 AddIndexEntry(FVertexCount);
 AddIndexEntry(FVertexCount + 1);

 AddIndexEntry(FVertexCount + 3);
 AddIndexEntry(FVertexCount + 2);
 AddIndexEntry(FVertexCount + 1);

 AddVertexEntry2(Points[0], ActiveTexCoords[0], Colors[0]);
 AddVertexEntry2(Points[1], ActiveTexCoords[1], Colors[1]);
 AddVertexEntry2(Points[3], ActiveTexCoords[3], Colors[3]);
 AddVertexEntry2(Points[2], ActiveTexCoords[2], Colors[2]);

 Inc(FPrimitives, 2);
end;

//---------------------------------------------------------------------------
end.

