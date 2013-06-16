unit Asphyre.Canvas.DX7;
//---------------------------------------------------------------------------
// Direct3D 7 canvas implementation.
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
 Asphyre.D3D7, Asphyre.TypeDef, Asphyre.Math, Asphyre.Types, 
 Asphyre.Textures, Asphyre.Canvas;

//---------------------------------------------------------------------------
const
// This parameter along with others described in implementation section
// roughly determine the canvas performance and cache stall.
 DX7CachedIndices = 4096;

//---------------------------------------------------------------------------
type
 TDX7CanvasTopology = (ctUnknown, ctPoints, ctLines, ctTriangles);

//---------------------------------------------------------------------------
 TDX7Canvas = class(TAsphyreCanvas)
 private
  VertexBuffer: IDirect3DVertexBuffer7;

  VertexArray: Pointer;
  IndexArray : packed array[0..DX7CachedIndices - 1] of Word;

  DrawingMode: TDX7CanvasTopology;

  VertexCount: Integer;
  IndexCount : Integer;
  Primitives : Integer;
  ActiveTex  : TAsphyreCustomTexture;

  CachedEffect: TBlendingEffect;
  CachedTex   : TAsphyreCustomTexture;
  QuadMapping : TPoint4;

  procedure CreateStaticBuffers();
  procedure DestroyStaticBuffers();
  procedure PrepareVertexArray();

  function CreateVertexBuffer(): Boolean;
  procedure DestroyVertexBuffer();
  procedure ResetDeviceStates();

  function UploadVertexBuffer(): Boolean;
  procedure DrawBuffers();

  function NextVertexEntry(): Pointer;
  procedure AddIndexEntry(Index: Integer);
  function RequestCache(Mode: TDX7CanvasTopology; Vertices, Indices: Integer;
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

  constructor Create(); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//--------------------------------------------------------------------------
uses
{$ifndef fpc}
 Winapi.Windows,
{$else}
 Windows,
{$endif}
 Asphyre.DDraw7, Asphyre.Types.DX7;

//--------------------------------------------------------------------------
const
 VertexFVFType = D3DFVF_XYZRHW or D3DFVF_DIFFUSE or D3DFVF_TEX1;

//--------------------------------------------------------------------------
 DX7CachedPrimitives = 3072;
 DX7CachedVertices   = 4096;

//--------------------------------------------------------------------------
type
 PVertexRecord = ^TVertexRecord;
 TVertexRecord = packed record
  Vertex: TD3DVector;
  rhw   : Single;
  Color : LongWord;
  u, v  : Single;
 end;

//--------------------------------------------------------------------------
constructor TDX7Canvas.Create();
begin
 inherited;

 VertexArray := nil;
 VertexBuffer:= nil;
end;

//---------------------------------------------------------------------------
destructor TDX7Canvas.Destroy();
begin
 DestroyVertexBuffer();
 DestroyStaticBuffers();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.PrepareVertexArray();
var
 Entry: PVertexRecord;
 Index: Integer;
begin
 Entry:= VertexArray;
 for Index:= 0 to DX7CachedVertices - 1 do
  begin
   FillChar(Entry^, SizeOf(TVertexRecord), 0);

   Entry.Vertex.z:= 0.0;
   Entry.rhw     := 1.0;

   Inc(Entry);
  end;
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.CreateStaticBuffers();
begin
 ReallocMem(VertexArray, DX7CachedVertices * SizeOf(TVertexRecord));
 FillChar(VertexArray^, DX7CachedVertices * SizeOf(TVertexRecord), 0);

 PrepareVertexArray();
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.DestroyStaticBuffers();
begin
 if (Assigned(VertexArray)) then
  FreeNullMem(VertexArray);
end;

//--------------------------------------------------------------------------
function TDX7Canvas.CreateVertexBuffer(): Boolean;
var
 Desc: TD3DVertexBufferDesc;
begin
 Result:= Assigned(D3D7Object);
 if (not Result) then Exit;

 FillChar(Desc, SizeOf(TD3DVertexBufferDesc), 0);

 Desc.dwSize:= SizeOf(TD3DVertexBufferDesc);
 Desc.dwCaps:= D3DVBCAPS_WRITEONLY or D3DVBCAPS_SYSTEMMEMORY;
 Desc.dwFVF := VertexFVFType;
 Desc.dwNumVertices:= DX7CachedVertices;

 Result:= Succeeded(D3D7Object.CreateVertexBuffer(Desc, VertexBuffer, 0));
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.DestroyVertexBuffer();
begin
 if (Assigned(VertexBuffer)) then VertexBuffer:= nil;
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.ResetDeviceStates();
begin
 VertexCount := 0;
 IndexCount  := 0;
 Primitives  := 0;
 DrawingMode := ctUnknown;
 CachedEffect:= beUnknown;
 CachedTex   := nil;
 ActiveTex   := nil;

 if (not Assigned(D3D7Device)) then Exit;

 with D3D7Device do
  begin
   // Disable unnecessary device states.
   SetRenderState(D3DRENDERSTATE_LIGHTING,  Ord(False));
   SetRenderState(D3DRENDERSTATE_CULLMODE,  Ord(D3DCULL_NONE));
   SetRenderState(D3DRENDERSTATE_ZENABLE,   Ord(D3DZB_FALSE));
   SetRenderState(D3DRENDERSTATE_FOGENABLE, Ord(False));

   // Enable Alpha-testing.
   SetRenderState(D3DRENDERSTATE_ALPHATESTENABLE, Ord(True));
   SetRenderState(D3DRENDERSTATE_ALPHAFUNC, Ord(D3DCMP_GREATEREQUAL));
   SetRenderState(D3DRENDERSTATE_ALPHAREF,  $00000001);

   // Default alpha-blending behavior
   SetRenderState(D3DRENDERSTATE_ALPHABLENDENABLE, Ord(True));

   SetTextureStageState(0, D3DTSS_COLOROP, Ord(D3DTOP_MODULATE));
   SetTextureStageState(0, D3DTSS_ALPHAOP, Ord(D3DTOP_MODULATE));

   SetTextureStageState(0, D3DTSS_MAGFILTER, Ord(D3DTFG_LINEAR));
   SetTextureStageState(0, D3DTSS_MINFILTER, Ord(D3DTFG_LINEAR));
   SetTextureStageState(0, D3DTSS_MIPFILTER, Ord(D3DTFP_NONE));
  end;
end;

//--------------------------------------------------------------------------
function TDX7Canvas.HandleDeviceCreate(): Boolean;
begin
 CreateStaticBuffers();
 Result:= True;
end;

//--------------------------------------------------------------------------
procedure TDX7Canvas.HandleDeviceDestroy();
begin
 DestroyStaticBuffers();
end;

//--------------------------------------------------------------------------
function TDX7Canvas.HandleDeviceReset(): Boolean;
begin
 Result:= CreateVertexBuffer();
end;

//--------------------------------------------------------------------------
procedure TDX7Canvas.HandleDeviceLost();
begin
 DestroyVertexBuffer();
end;

//--------------------------------------------------------------------------
procedure TDX7Canvas.HandleBeginScene();
begin
 ResetDeviceStates();
end;

//--------------------------------------------------------------------------
procedure TDX7Canvas.HandleEndScene();
begin
 Flush();
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.GetViewport(out x, y, Width, Height: Integer);
var
 vp: TD3DViewport7;
begin
 if (not Assigned(D3D7Device)) then
  begin
   x:= 0; y:= 0; Width:= 0; Height:= 0;
   Exit;
  end;

 FillChar(vp, SizeOf(vp), 0);
 D3D7Device.GetViewport(vp);

 x:= vp.dwX;
 y:= vp.dwY;

 Width := vp.dwWidth;
 Height:= vp.dwHeight;
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.SetViewport(x, y, Width, Height: Integer);
var
 vp: TD3DViewport7;
begin
 if (not Assigned(D3D7Device)) then Exit;

 Flush();

 vp.dwX:= x;
 vp.dwY:= y;
 vp.dwWidth := Width;
 vp.dwHeight:= Height;
 vp.dvMinZ:= 0.0;
 vp.dvMaxZ:= 1.0;

 D3D7Device.SetViewport(vp);
end;

//---------------------------------------------------------------------------
function TDX7Canvas.GetAntialias(): Boolean;
var
 MagFlt, MinFlt: Cardinal;
begin
 if (not Assigned(D3D7Device)) then
  begin
   Result:= False;
   Exit;
  end;

 D3D7Device.GetTextureStageState(0, D3DTSS_MAGFILTER, MagFlt);
 D3D7Device.GetTextureStageState(0, D3DTSS_MINFILTER, MinFlt);

 Result:= True;

 if (MagFlt = Cardinal(D3DTFG_POINT))or(MinFlt = Cardinal(D3DTFN_POINT)) then
  Result:= False;
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.SetAntialias(const Value: Boolean);
begin
 if (not Assigned(D3D7Device)) then Exit;

 Flush();

 if (Value) then
  begin
   D3D7Device.SetTextureStageState(0, D3DTSS_MAGFILTER, Ord(D3DTFG_LINEAR));
   D3D7Device.SetTextureStageState(0, D3DTSS_MINFILTER, Ord(D3DTFN_LINEAR));
  end else
  begin
   D3D7Device.SetTextureStageState(0, D3DTSS_MAGFILTER, Ord(D3DTFG_POINT));
   D3D7Device.SetTextureStageState(0, D3DTSS_MINFILTER, Ord(D3DTFN_POINT));
  end;
end;

//---------------------------------------------------------------------------
function TDX7Canvas.GetMipMapping(): Boolean;
var
 MipFlt: Cardinal;
begin
 if (not Assigned(D3D7Device)) then
  begin
   Result:= False;
   Exit;
  end;

 D3D7Device.GetTextureStageState(0, D3DTSS_MIPFILTER, MipFlt);

 Result:= True;

 if (MipFlt = Cardinal(D3DTFP_NONE))or(MipFlt = Cardinal(D3DTFP_POINT)) then
  Result:= False;
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.SetMipMapping(const Value: Boolean);
begin
 if (not Assigned(D3D7Device)) then Exit;

 Flush();

 if (Value) then
  D3D7Device.SetTextureStageState(0, D3DTSS_MIPFILTER, Ord(D3DTFP_LINEAR))
   else D3D7Device.SetTextureStageState(0, D3DTSS_MIPFILTER, Ord(D3DTFP_NONE));
end;

//---------------------------------------------------------------------------
function TDX7Canvas.UploadVertexBuffer(): Boolean;
var
 MemAddr: Pointer;
 BufSize: Cardinal;
begin
 Result:= Assigned(VertexBuffer);
 if (not Result) then Exit;

 BufSize:= VertexCount * SizeOf(TVertexRecord);

 Result:= Succeeded(VertexBuffer.Lock(DDLOCK_DISCARDCONTENTS or
  DDLOCK_SURFACEMEMORYPTR or DDLOCK_WRITEONLY, MemAddr, BufSize));
 if (not Result) then Exit;

 Move(VertexArray^, MemAddr^, BufSize);
 VertexBuffer.Unlock();
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.DrawBuffers();
begin
 if (not Assigned(D3D7Device)) then Exit;

 with D3D7Device do
  begin
   case DrawingMode of
    ctPoints:
     DrawPrimitiveVB(D3DPT_POINTLIST, VertexBuffer, 0, VertexCount, 0);

    ctLines:
     DrawPrimitiveVB(D3DPT_LINELIST, VertexBuffer, 0, VertexCount, 0);

    ctTriangles:
     DrawIndexedPrimitiveVB(D3DPT_TRIANGLELIST, VertexBuffer, 0, VertexCount,
      IndexArray[0], IndexCount, 0);
   end;
  end;

 NextDrawCall();
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.Flush();
begin
 if (VertexCount > 0)and(Primitives > 0)and(UploadVertexBuffer()) then
  DrawBuffers();

 VertexCount:= 0;
 IndexCount := 0;
 Primitives := 0;
 DrawingMode := ctUnknown;
 CachedEffect:= beUnknown;

 if (Assigned(D3D7Device)) then D3D7Device.SetTexture(0, nil);

 CachedTex:= nil;
 ActiveTex:= nil;
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.SetEffectStates(Effect: TBlendingEffect);
begin
 if (not Assigned(D3D7Device)) then Exit;

 case Effect of
  beNormal:
   with D3D7Device do
    begin
     SetRenderState(D3DRENDERSTATE_SRCBLEND,  Ord(D3DBLEND_SRCALPHA));
     SetRenderState(D3DRENDERSTATE_DESTBLEND, Ord(D3DBLEND_INVSRCALPHA));
     SetTextureStageState(0, D3DTSS_COLOROP, Ord(D3DTOP_MODULATE));
     SetTextureStageState(0, D3DTSS_ALPHAOP, Ord(D3DTOP_MODULATE));
    end;

  beShadow:
   with D3D7Device do
    begin
     SetRenderState(D3DRENDERSTATE_SRCBLEND,  Ord(D3DBLEND_ZERO));
     SetRenderState(D3DRENDERSTATE_DESTBLEND, Ord(D3DBLEND_INVSRCALPHA));
     SetTextureStageState(0, D3DTSS_COLOROP, Ord(D3DTOP_MODULATE));
     SetTextureStageState(0, D3DTSS_ALPHAOP, Ord(D3DTOP_MODULATE));
    end;

  beAdd:
   with D3D7Device do
    begin
     SetRenderState(D3DRENDERSTATE_SRCBLEND,  Ord(D3DBLEND_SRCALPHA));
     SetRenderState(D3DRENDERSTATE_DESTBLEND, Ord(D3DBLEND_ONE));
     SetTextureStageState(0, D3DTSS_COLOROP, Ord(D3DTOP_MODULATE));
     SetTextureStageState(0, D3DTSS_ALPHAOP, Ord(D3DTOP_MODULATE));
    end;

  beMultiply:
   with D3D7Device do
    begin
     SetRenderState(D3DRENDERSTATE_SRCBLEND,  Ord(D3DBLEND_ZERO));
     SetRenderState(D3DRENDERSTATE_DESTBLEND, Ord(D3DBLEND_SRCCOLOR));
     SetTextureStageState(0, D3DTSS_COLOROP, Ord(D3DTOP_MODULATE));
     SetTextureStageState(0, D3DTSS_ALPHAOP, Ord(D3DTOP_MODULATE));
    end;

  beSrcColor:
   with D3D7Device do
    begin
     SetRenderState(D3DRENDERSTATE_SRCBLEND,  Ord(D3DBLEND_SRCCOLOR));
     SetRenderState(D3DRENDERSTATE_DESTBLEND, Ord(D3DBLEND_INVSRCCOLOR));
     SetTextureStageState(0, D3DTSS_COLOROP, Ord(D3DTOP_MODULATE));
     SetTextureStageState(0, D3DTSS_ALPHAOP, Ord(D3DTOP_MODULATE));
    end;

  beSrcColorAdd:
   with D3D7Device do
    begin
     SetRenderState(D3DRENDERSTATE_SRCBLEND,  Ord(D3DBLEND_SRCCOLOR));
     SetRenderState(D3DRENDERSTATE_DESTBLEND, Ord(D3DBLEND_ONE));
     SetTextureStageState(0, D3DTSS_COLOROP, Ord(D3DTOP_MODULATE));
     SetTextureStageState(0, D3DTSS_ALPHAOP, Ord(D3DTOP_MODULATE));
    end;

  beInvMultiply:
   with D3D7Device do
    begin
     SetRenderState(D3DRENDERSTATE_SRCBLEND,  Ord(D3DBLEND_ZERO));
     SetRenderState(D3DRENDERSTATE_DESTBLEND, Ord(D3DBLEND_INVSRCCOLOR));
     SetTextureStageState(0, D3DTSS_COLOROP, Ord(D3DTOP_MODULATE));
     SetTextureStageState(0, D3DTSS_ALPHAOP, Ord(D3DTOP_MODULATE));
    end;
 end;
end;

//---------------------------------------------------------------------------
function TDX7Canvas.RequestCache(Mode: TDX7CanvasTopology; Vertices,
 Indices: Integer; Effect: TBlendingEffect;
 Texture: TAsphyreCustomTexture): Boolean;
var
 NeedReset: Boolean;
begin
 Result:= (Vertices <= DX7CachedVertices)and(Indices <= DX7CachedIndices);
 if (not Result) then Exit;

 NeedReset:= (VertexCount + Vertices > DX7CachedVertices);
 NeedReset:= (NeedReset)or(IndexCount + Indices > DX7CachedIndices);
 NeedReset:= (NeedReset)or(DrawingMode = ctUnknown)or(DrawingMode <> Mode);
 NeedReset:= (NeedReset)or(CachedEffect = beUnknown)or(CachedEffect <> Effect);
 NeedReset:= (NeedReset)or(CachedTex <> Texture);

 if (NeedReset) then
  begin
   Flush();

   if (CachedEffect = beUnknown)or(CachedEffect <> Effect) then
    SetEffectStates(Effect);

   if (Assigned(D3D7Device))and((CachedEffect = beUnknown)or
    (CachedTex <> Texture)) then
    begin
     if (Assigned(Texture)) then Texture.Bind(0)
      else D3D7Device.SetTexture(0, nil);
    end;

   DrawingMode := Mode;
   CachedEffect:= Effect;
   CachedTex   := Texture;
  end;
end;

//---------------------------------------------------------------------------
function TDX7Canvas.NextVertexEntry(): Pointer;
begin
 Result:= Pointer(PtrInt(VertexArray) + (VertexCount * SizeOf(TVertexRecord)));
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.AddIndexEntry(Index: Integer);
begin
 IndexArray[IndexCount]:= Index;
 Inc(IndexCount);
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.PutPixel(const Point: TPoint2; Color: Cardinal);
var
 Entry: PVertexRecord;
begin
 if (not RequestCache(ctPoints, 1, 0, beNormal, nil)) then Exit;

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Point.x;
 Entry.Vertex.y:= Point.y;
 Entry.Color   := Color;

 Inc(VertexCount);
 Inc(Primitives);
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.Line(const Src, Dest: TPoint2; Color1, Color2: Cardinal);
var
 Entry: PVertexRecord;
begin
 if (not RequestCache(ctLines, 2, 0, beNormal, nil)) then Exit;

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Src.x;
 Entry.Vertex.y:= Src.y;
 Entry.Color   := Color1;
 Inc(VertexCount);

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Dest.x;
 Entry.Vertex.y:= Dest.y;
 Entry.Color   := Color2;
 Inc(VertexCount);

 Inc(Primitives);
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.DrawIndexedTriangles(Vertices: PPoint2;
 Colors: PLongWord; Indices: PLongInt; NoVertices, NoTriangles: Integer;
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
   AddIndexEntry(VertexCount + Index^);

   Inc(Index);
  end;

 Vertex:= Vertices;
 Color := Colors;

 for i:= 0 to NoVertices - 1 do
  begin
   Entry:= NextVertexEntry();
   Entry.Vertex.x:= Vertex.x - 0.5;
   Entry.Vertex.y:= Vertex.y - 0.5;
   Entry.Color   := Color^;
   Inc(VertexCount);

   Inc(Vertex);
   Inc(Color);
  end;

 Inc(Primitives, NoTriangles);
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.UseTexture(const Texture: TAsphyreCustomTexture;
 const Mapping: TPoint4);
begin
 ActiveTex  := Texture;
 QuadMapping:= Mapping;
end;

//---------------------------------------------------------------------------
procedure TDX7Canvas.TexMap(const Points: TPoint4; const Colors: TColor4;
 Effect: TBlendingEffect);
var
 Entry: PVertexRecord;
begin
 RequestCache(ctTriangles, 4, 6, Effect, ActiveTex);

 AddIndexEntry(VertexCount + 2);
 AddIndexEntry(VertexCount);
 AddIndexEntry(VertexCount + 1);

 AddIndexEntry(VertexCount + 3);
 AddIndexEntry(VertexCount + 2);
 AddIndexEntry(VertexCount + 1);

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Points[0].x - 0.5;
 Entry.Vertex.y:= Points[0].y - 0.5;
 Entry.Color   := Colors[0];
 Entry.u:= QuadMapping[0].x;
 Entry.v:= QuadMapping[0].y;
 Inc(VertexCount);

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Points[1].x - 0.5;
 Entry.Vertex.y:= Points[1].y - 0.5;
 Entry.Color   := Colors[1];
 Entry.u:= QuadMapping[1].x;
 Entry.v:= QuadMapping[1].y;
 Inc(VertexCount);

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Points[3].x - 0.5;
 Entry.Vertex.y:= Points[3].y - 0.5;
 Entry.Color   := Colors[3];
 Entry.u:= QuadMapping[3].x;
 Entry.v:= QuadMapping[3].y;
 Inc(VertexCount);

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Points[2].x - 0.5;
 Entry.Vertex.y:= Points[2].y - 0.5;
 Entry.Color   := Colors[2];
 Entry.u:= QuadMapping[2].x;
 Entry.v:= QuadMapping[2].y;
 Inc(VertexCount);

 Inc(Primitives, 2);
end;

//---------------------------------------------------------------------------
end.
