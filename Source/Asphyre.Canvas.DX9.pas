unit Asphyre.Canvas.DX9;
//---------------------------------------------------------------------------
// Direct3D 9 canvas implementation.
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
 Winapi.Windows,
{$else}
 Windows,
{$endif}
 Asphyre.D3D9, Asphyre.TypeDef, Asphyre.Math, Asphyre.Types,
 Asphyre.Textures, Asphyre.Canvas;

//---------------------------------------------------------------------------
// The following option controls the behavior of antialiased lines.
// Enable the option for compatibility with DirectX 7 wrapper.
// Also note that antialiased lines don't work on Intel GMA X3100 and have
// disastrous consequences on Intel HD 3000 video cards.
//---------------------------------------------------------------------------
{$define NoAntialiasedLines}

//---------------------------------------------------------------------------
type
 TDX9CanvasTopology = (ctUnknown, ctPoints, ctLines, ctTriangles);

//---------------------------------------------------------------------------
 TDX9Canvas = class(TAsphyreCanvas)
 private
  VertexBuffer: IDirect3DVertexBuffer9;
  IndexBuffer : IDirect3DIndexBuffer9;

  VertexArray: Pointer;
  IndexArray : Pointer;

  CanvasTopology: TDX9CanvasTopology;

  FVertexCache: Integer;
  FIndexCache : Integer;
  FVertexCount: Integer;
  FIndexCount : Integer;

  FPrimitives   : Integer;
  FMaxPrimitives: Integer;

  ActiveTex   : TAsphyreCustomTexture;
  CachedTex   : TAsphyreCustomTexture;
  CachedEffect: TBlendingEffect;
  QuadMapping : TPoint4;

  procedure InitCacheSpec();
  procedure PrepareVertexArray();

  procedure CreateSystemBuffers();
  procedure DestroySystemBuffers();

  function CreateVideoBuffers(): Boolean;
  procedure DestroyVideoBuffers();

  function UploadVertexBuffer(): Boolean;
  function UploadIndexBuffer(): Boolean;
  procedure DrawBuffers();

  function NextVertexEntry(): Pointer;
  procedure AddIndexEntry(Index: Integer);
  function RequestCache(Mode: TDX9CanvasTopology; Vertices, Indices: Integer;
   Effect: TBlendingEffect; Texture: TAsphyreCustomTexture): Boolean;

  procedure SetEffectStates(Effect: TBlendingEffect);
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
 Asphyre.Types.DX9;

//--------------------------------------------------------------------------
const
 VertexFVFType = D3DFVF_XYZRHW or D3DFVF_DIFFUSE or D3DFVF_TEX1;

//---------------------------------------------------------------------------
// The following parameters roughly affect the rendering performance. The
// higher values means that more primitives will fit in cache, but it will
// also occupy more bandwidth, even when few primitives are rendered.
//
// These parameters can be fine-tuned in a finished product to improve the
// overall performance.
//---------------------------------------------------------------------------
 MaxCachedPrimitives = 3072;
 MaxCachedIndices    = 4096;
 MaxCachedVertices   = 4096;

//--------------------------------------------------------------------------
type
 PVertexRecord = ^TVertexRecord;
 TVertexRecord = packed record
  Vertex: D3DVECTOR;
  rhw   : Single;
  Color : LongWord;
  u, v  : Single;
 end;

//--------------------------------------------------------------------------
constructor TDX9Canvas.Create();
begin
 inherited;

 VertexArray := nil;
 IndexArray  := nil;
 VertexBuffer:= nil;
 IndexBuffer := nil;
end;

//---------------------------------------------------------------------------
destructor TDX9Canvas.Destroy();
begin
 DestroyVideoBuffers();
 DestroySystemBuffers();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.InitCacheSpec();
begin
 with D3D9Caps do
  begin
   FMaxPrimitives:= Min2(MaxPrimitiveCount, MaxCachedPrimitives);
   FVertexCache  := Min2(MaxVertexIndex, MaxCachedVertices);
   FIndexCache   := Min2(MaxVertexIndex, MaxCachedIndices);
  end;
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.PrepareVertexArray();
var
 Entry: PVertexRecord;
 Index: Integer;
begin
 Entry:= VertexArray;

 for Index:= 0 to MaxCachedVertices - 1 do
  begin
   FillChar(Entry^, SizeOf(TVertexRecord), 0);

   Entry.Vertex.z:= 0.0;
   Entry.rhw     := 1.0;

   Inc(Entry);
  end;
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.CreateSystemBuffers();
begin
 ReallocMem(VertexArray, FVertexCache * SizeOf(TVertexRecord));
 FillChar(VertexArray^, FVertexCache * SizeOf(TVertexRecord), 0);

 ReallocMem(IndexArray, FIndexCache * SizeOf(Word));
 FillChar(IndexArray^, FIndexCache * SizeOf(Word), 0);

 PrepareVertexArray();
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.DestroySystemBuffers();
begin
 if (Assigned(IndexArray)) then
  FreeNullMem(IndexArray);

 if (Assigned(VertexArray)) then
  FreeNullMem(VertexArray);
end;

//--------------------------------------------------------------------------
function TDX9Canvas.CreateVideoBuffers(): Boolean;
begin
 Result:= Assigned(D3D9Device);
 if (not Result) then Exit;

 // Dynamic Vertex Buffer.
 Result:= Succeeded(D3D9Device.CreateVertexBuffer(FVertexCache *
  SizeOf(TVertexRecord), D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC,
  VertexFVFType, D3DPOOL_DEFAULT, VertexBuffer, nil));
 if (not Result) then Exit;

 // Dynamic Index Buffer.
 Result:= Succeeded(D3D9Device.CreateIndexBuffer(FIndexCache *
  SizeOf(Word), D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, D3DFMT_INDEX16,
  D3DPOOL_DEFAULT, IndexBuffer, nil));
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.DestroyVideoBuffers();
begin
 if (Assigned(IndexBuffer)) then IndexBuffer:= nil;
 if (Assigned(VertexBuffer)) then VertexBuffer:= nil;
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.ResetStates();
begin
 FVertexCount:= 0;
 FIndexCount := 0;
 FPrimitives := 0;
 CanvasTopology:= ctUnknown;
 CachedEffect:= beUnknown;
 CachedTex   := nil;
 ActiveTex   := nil;

 if (not Assigned(D3D9Device)) then Exit;

 with D3D9Device do
  begin
   // Disable pixel shader.
   SetPixelShader(nil);

   // Disable unnecessary device states.
   SetRenderState(D3DRS_LIGHTING,  iFalse);
   SetRenderState(D3DRS_CULLMODE,  D3DCULL_NONE);
   SetRenderState(D3DRS_ZENABLE,   D3DZB_FALSE);
   SetRenderState(D3DRS_FOGENABLE, iFalse);

  {$ifdef NoAntialiasedLines}
   SetRenderState(D3DRS_ANTIALIASEDLINEENABLE, iFalse);
  {$else}
   SetRenderState(D3DRS_ANTIALIASEDLINEENABLE, iTrue);
  {$endif}

   // Enable Alpha-testing.
   SetRenderState(D3DRS_ALPHATESTENABLE, iTrue);
   SetRenderState(D3DRS_ALPHAFUNC, D3DCMP_GREATEREQUAL);
   SetRenderState(D3DRS_ALPHAREF,  $00000001);

   // Default alpha-blending behavior
   SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);

   // Alpha-blending stages for COLOR component.
   SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
   SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
   SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);

   SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_DISABLE);

   // Alpha-blending stages for ALPHA component.
   SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
   SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
   SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);

   SetTextureStageState(1, D3DTSS_ALPHAOP, D3DTOP_DISABLE);

   // Texture filtering flags.
   SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
   SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR);
   SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_NONE);

   // Triangle fill mode.
   SetRenderState(D3DRS_FILLMODE, D3DFILL_SOLID);
  end;
end;

//--------------------------------------------------------------------------
function TDX9Canvas.HandleDeviceCreate(): Boolean;
begin
 InitCacheSpec();
 CreateSystemBuffers();

 if (D3D9Mode = dmDirect3D9Ex) then
  Result:= CreateVideoBuffers()
   else Result:= True;
end;

//--------------------------------------------------------------------------
procedure TDX9Canvas.HandleDeviceDestroy();
begin
 if (D3D9Mode = dmDirect3D9Ex) then
  DestroyVideoBuffers();

 DestroySystemBuffers();
end;

//--------------------------------------------------------------------------
function TDX9Canvas.HandleDeviceReset(): Boolean;
begin
 if (D3D9Mode <> dmDirect3D9Ex) then
  Result:= CreateVideoBuffers()
   else Result:= True;
end;

//--------------------------------------------------------------------------
procedure TDX9Canvas.HandleDeviceLost();
begin
 if (D3D9Mode <> dmDirect3D9Ex) then
  DestroyVideoBuffers();
end;

//--------------------------------------------------------------------------
procedure TDX9Canvas.HandleBeginScene();
begin
 ResetStates();
end;

//--------------------------------------------------------------------------
procedure TDX9Canvas.HandleEndScene();
begin
 Flush();
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.GetViewport(out x, y, Width, Height: Integer);
var
 vp: TD3DViewport9;
begin
 if (not Assigned(D3D9Device)) then
  begin
   x:= 0; y:= 0; Width:= 0; Height:= 0;
   Exit;
  end;

 FillChar(vp, SizeOf(vp), 0);
 D3D9Device.GetViewport(vp);

 x:= vp.X;
 y:= vp.Y;

 Width := vp.Width;
 Height:= vp.Height;
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.SetViewport(x, y, Width, Height: Integer);
var
 vp: TD3DViewport9;
begin
 if (not Assigned(D3D9Device)) then Exit;

 Flush();

 vp.X:= x;
 vp.Y:= y;
 vp.Width := Width;
 vp.Height:= Height;
 vp.MinZ:= 0.0;
 vp.MaxZ:= 1.0;

 D3D9Device.SetViewport(vp);
end;

//---------------------------------------------------------------------------
function TDX9Canvas.GetAntialias(): Boolean;
var
 MagFlt, MinFlt: LongWord;
begin
 if (not Assigned(D3D9Device)) then
  begin
   Result:= False;
   Exit;
  end;

 D3D9Device.GetSamplerState(0, D3DSAMP_MAGFILTER, MagFlt);
 D3D9Device.GetSamplerState(0, D3DSAMP_MINFILTER, MinFlt);

 Result:= True;

 if (MagFlt = D3DTEXF_POINT)or(MinFlt = D3DTEXF_POINT) then Result:= False;
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.SetAntialias(const Value: Boolean);
begin
 if (not Assigned(D3D9Device)) then Exit;

 Flush();

 if (Value) then
  begin
   D3D9Device.SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
   D3D9Device.SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR);
  end else
  begin
   D3D9Device.SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_POINT);
   D3D9Device.SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_POINT);
  end;
end;

//---------------------------------------------------------------------------
function TDX9Canvas.GetMipMapping(): Boolean;
var
 MipFlt: LongWord;
begin
 if (not Assigned(D3D9Device)) then
  begin
   Result:= False;
   Exit;
  end;

 D3D9Device.GetSamplerState(0, D3DSAMP_MIPFILTER, MipFlt);

 Result:= True;

 if (MipFlt = D3DTEXF_NONE)or(MipFlt = D3DTEXF_POINT) then Result:= False;
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.SetMipMapping(const Value: Boolean);
begin
 if (not Assigned(D3D9Device)) then Exit;

 Flush();

 if (Value) then
  D3D9Device.SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR)
   else D3D9Device.SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_NONE);
end;

//---------------------------------------------------------------------------
function TDX9Canvas.UploadVertexBuffer(): Boolean;
var
 MemAddr: Pointer;
 BufSize: Integer;
begin
 Result:= Assigned(VertexBuffer);
 if (not Result) then Exit;

 BufSize:= FVertexCount * SizeOf(TVertexRecord);

 Result:= Succeeded(VertexBuffer.Lock(0, BufSize, MemAddr, D3DLOCK_DISCARD));
 if (not Result) then Exit;

 Move(VertexArray^, MemAddr^, BufSize);
 VertexBuffer.Unlock();
end;

//---------------------------------------------------------------------------
function TDX9Canvas.UploadIndexBuffer(): Boolean;
var
 MemAddr: Pointer;
 BufSize: Integer;
begin
 Result:= Assigned(IndexBuffer);
 if (not Result) then Exit;

 BufSize:= FIndexCount * SizeOf(Word);

 Result:= Succeeded(IndexBuffer.Lock(0, BufSize, MemAddr, D3DLOCK_DISCARD));
 if (not Result) then Exit;

 Move(IndexArray^, MemAddr^, BufSize);
 IndexBuffer.Unlock();
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.DrawBuffers();
begin
 if (not Assigned(D3D9Device)) then Exit;

 with D3D9Device do
  begin
   SetStreamSource(0, VertexBuffer, 0, SizeOf(TVertexRecord));
   SetIndices(IndexBuffer);
   SetVertexShader(nil);
   SetFVF(VertexFVFType);

   case CanvasTopology of
    ctPoints:
     DrawPrimitive(D3DPT_POINTLIST, 0, FPrimitives);

    ctLines:
     DrawPrimitive(D3DPT_LINELIST, 0, FPrimitives);

    ctTriangles:
     DrawIndexedPrimitive(D3DPT_TRIANGLELIST, 0, 0, FVertexCount, 0,
      FPrimitives);
   end;
  end;

 NextDrawCall();
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.Flush();
begin
 if (FVertexCount > 0)and(FPrimitives > 0)and(UploadVertexBuffer())and
  (UploadIndexBuffer()) then DrawBuffers();

 FVertexCount:= 0;
 FIndexCount := 0;
 FPrimitives := 0;
 CanvasTopology:= ctUnknown;
 CachedEffect:= beUnknown;

 if (Assigned(D3D9Device)) then D3D9Device.SetTexture(0, nil);

 CachedTex:= nil;
 ActiveTex:= nil;
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.SetEffectStates(Effect: TBlendingEffect);
begin
 if (not Assigned(D3D9Device)) then Exit;

 case Effect of
  beNormal:
   with D3D9Device do
    begin
     SetRenderState(D3DRS_SRCBLEND,  D3DBLEND_SRCALPHA);
     SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
     SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
     SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    end;

  beShadow:
   with D3D9Device do
    begin
     SetRenderState(D3DRS_SRCBLEND,  D3DBLEND_ZERO);
     SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
     SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
     SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    end;

  beAdd:
   with D3D9Device do
    begin
     SetRenderState(D3DRS_SRCBLEND,  D3DBLEND_SRCALPHA);
     SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
     SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
     SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    end;

  beMultiply:
   with D3D9Device do
    begin
     SetRenderState(D3DRS_SRCBLEND,  D3DBLEND_ZERO);
     SetRenderState(D3DRS_DESTBLEND, D3DBLEND_SRCCOLOR);
     SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
     SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    end;

  beSrcColor:
   with D3D9Device do
    begin
     SetRenderState(D3DRS_SRCBLEND,  D3DBLEND_SRCCOLOR);
     SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCCOLOR);
     SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
     SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    end;

  beSrcColorAdd:
   with D3D9Device do
    begin
     SetRenderState(D3DRS_SRCBLEND,  D3DBLEND_SRCCOLOR);
     SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
     SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
     SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    end;

  beInvMultiply:
   with D3D9Device do
    begin
     SetRenderState(D3DRS_SRCBLEND,  D3DBLEND_ZERO);
     SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCCOLOR);
     SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
     SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    end;
 end;
end;

//---------------------------------------------------------------------------
function TDX9Canvas.RequestCache(Mode: TDX9CanvasTopology; Vertices,
 Indices: Integer; Effect: TBlendingEffect;
 Texture: TAsphyreCustomTexture): Boolean;
var
 NeedReset: Boolean;
begin
 Result:= (Vertices <= MaxCachedVertices)and(Indices <= MaxCachedIndices);
 if (not Result) then Exit;

 NeedReset:= (FVertexCount + Vertices > FVertexCache);
 NeedReset:= (NeedReset)or(FIndexCount + Indices > FIndexCache);
 NeedReset:= (NeedReset)or(CanvasTopology = ctUnknown)or(CanvasTopology <> Mode);
 NeedReset:= (NeedReset)or(CachedEffect = beUnknown)or(CachedEffect <> Effect);
 NeedReset:= (NeedReset)or(CachedTex <> Texture);

 if (NeedReset) then
  begin
   Flush();

   if (CachedEffect = beUnknown)or(CachedEffect <> Effect) then
    SetEffectStates(Effect);

   if (Assigned(D3D9Device))and((CachedEffect = beUnknown)or
    (CachedTex <> Texture)) then
    begin
     if (Assigned(Texture)) then Texture.Bind(0)
      else D3D9Device.SetTexture(0, nil);
    end;

   CanvasTopology := Mode;
   CachedEffect:= Effect;
   CachedTex   := Texture;
  end;
end;

//---------------------------------------------------------------------------
function TDX9Canvas.NextVertexEntry(): Pointer;
begin
 Result:= Pointer(PtrInt(VertexArray) + (FVertexCount * SizeOf(TVertexRecord)));
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.AddIndexEntry(Index: Integer);
var
 Entry: PWord;
begin
 Entry:= Pointer(PtrInt(IndexArray) + (FIndexCount * SizeOf(Word)));
 Entry^:= Index;

 Inc(FIndexCount);
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.PutPixel(const Point: TPoint2; Color: Cardinal);
var
 Entry: PVertexRecord;
begin
 if (not RequestCache(ctPoints, 1, 0, beNormal, nil)) then Exit;

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Point.x * InternalScale;
 Entry.Vertex.y:= Point.y * InternalScale;
 Entry.Color   := Color;

 Inc(FVertexCount);
 Inc(FPrimitives);
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.Line(const Src, Dest: TPoint2; Color1, Color2: Cardinal);
var
 Entry: PVertexRecord;
begin
 if (not RequestCache(ctLines, 2, 0, beNormal, nil)) then Exit;

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Src.x * InternalScale;
 Entry.Vertex.y:= Src.y * InternalScale;
 Entry.Color   := Color1;
 Inc(FVertexCount);

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Dest.x * InternalScale;
 Entry.Vertex.y:= Dest.y * InternalScale;
 Entry.Color   := Color2;
 Inc(FVertexCount);

 Inc(FPrimitives);
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.DrawIndexedTriangles(Vertices: PPoint2; Colors: PLongWord;
Indices: PLongInt; NoVertices, NoTriangles: Integer;
Effect: TBlendingEffect = beNormal);
var
 Entry : PVertexRecord;
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
   Entry:= NextVertexEntry();
   Entry.Vertex.x:= Vertex.x * InternalScale - 0.5;
   Entry.Vertex.y:= Vertex.y * InternalScale - 0.5;
   Entry.Color   := Color^;
   Inc(FVertexCount);

   Inc(Vertex);
   Inc(Color);
  end;

 Inc(FPrimitives, NoTriangles);
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.UseTexture(const Texture: TAsphyreCustomTexture;
 const Mapping: TPoint4);
begin
 ActiveTex  := Texture;
 QuadMapping:= Mapping;
end;

//---------------------------------------------------------------------------
procedure TDX9Canvas.TexMap(const Points: TPoint4; const Colors: TColor4;
 Effect: TBlendingEffect);
var
 Entry: PVertexRecord;
begin
 RequestCache(ctTriangles, 4, 6, Effect, ActiveTex);

 AddIndexEntry(FVertexCount + 2);
 AddIndexEntry(FVertexCount);
 AddIndexEntry(FVertexCount + 1);

 AddIndexEntry(FVertexCount + 3);
 AddIndexEntry(FVertexCount + 2);
 AddIndexEntry(FVertexCount + 1);

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Points[0].x * InternalScale - 0.5;
 Entry.Vertex.y:= Points[0].y * InternalScale - 0.5;
 Entry.Color   := Colors[0];
 Entry.u:= QuadMapping[0].x;
 Entry.v:= QuadMapping[0].y;
 Inc(FVertexCount);

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Points[1].x * InternalScale - 0.5;
 Entry.Vertex.y:= Points[1].y * InternalScale - 0.5;
 Entry.Color   := Colors[1];
 Entry.u:= QuadMapping[1].x;
 Entry.v:= QuadMapping[1].y;
 Inc(FVertexCount);

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Points[3].x * InternalScale - 0.5;
 Entry.Vertex.y:= Points[3].y * InternalScale - 0.5;
 Entry.Color   := Colors[3];
 Entry.u:= QuadMapping[3].x;
 Entry.v:= QuadMapping[3].y;
 Inc(FVertexCount);

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Points[2].x * InternalScale - 0.5;
 Entry.Vertex.y:= Points[2].y * InternalScale - 0.5;
 Entry.Color   := Colors[2];
 Entry.u:= QuadMapping[2].x;
 Entry.v:= QuadMapping[2].y;
 Inc(FVertexCount);

 Inc(FPrimitives, 2);
end;

//---------------------------------------------------------------------------
end.
