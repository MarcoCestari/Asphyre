unit Asphyre.Canvas.GLES;
//---------------------------------------------------------------------------
// OpenGL ES canvas implementation.
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
uses
 System.Types, Asphyre.TypeDef, Asphyre.Math, Asphyre.Types, Asphyre.Canvas,
 Asphyre.Textures;

//---------------------------------------------------------------------------
type
 TGLESCanvasTopology = (gctNone, gctPoints, gctLines, gctTriangles);

//---------------------------------------------------------------------------
 TGLESCanvas = class(TAsphyreCanvas)
 private
  FTopology   : TGLESCanvasTopology;
  NormSize    : TPoint2;
  CachedEffect: TBlendingEffect;
  CachedTex   : TAsphyreCustomTexture;
  ActiveTex   : TAsphyreCustomTexture;
  QuadMapping : TPoint4;
  FAntialias  : Boolean;
  FMipmapping : Boolean;

  ClipRect: TRect;

  IndexBuffer : Pointer;
  VertexBuffer: Pointer;
  ColorBuffer : Pointer;
  TexCoordBuf : Pointer;

  VertexCount: Integer;
  IndexCount : Integer;

  GenericVS  : Integer;
  SolidFillPS: Integer;
  TexMapPS   : Integer;

  SolidFillProgram: Integer;
  TexMapProgram   : Integer;
  SourceTexLoc    : Integer;

  procedure CreateStaticBuffers();
  procedure DestroyStaticBuffers();

  function CompileShader(ShaderType: Integer;
   const ShaderText: string): Integer;
  function CreateShaders(): Boolean;
  procedure DestroyShaders();

  function CreateSolidFillProgram(): Boolean;
  procedure DestroySolidFillProgram();

  function CreateTexMapProgram(): Boolean;
  procedure DestroyTexMapProgram();

  function UseSolidFillProgram(): Boolean;
  function UseTexMapProgram(): Boolean;

  procedure DrawBuffers();
  procedure ResetScene();
  procedure RequestCache(const Mode: TGLESCanvasTopology; const Vertices,
   Indices: Integer);

  procedure RequestEffect(const Effect: TBlendingEffect);
  procedure RequestTexture(const Texture: TAsphyreCustomTexture);
  procedure InsertRawVertex(const Pos: TPoint2);
  procedure InsertVertex(const Pos, TexCoord: TPoint2; const Color: Cardinal);
  procedure InsertIndex(const Value: Integer);
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
  procedure Line(const Src, Dest: TPoint2; Color0, Color1: Cardinal); override;

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

//---------------------------------------------------------------------------
uses
 {$IFDEF IOS}
 iOSapi.GLES,
 {$ELSE}
 Androidapi.Gles2,
 {$ENDIF}
 System.SysUtils;

//---------------------------------------------------------------------------
const
// The following parameters roughly affect the rendering performance. The
// higher values means that more primitives will fit in cache, but it will
// also occupy more bandwidth, even when few primitives are rendered.
//
// These parameters can be fine-tuned in a finished product to improve the
// overall performance.
 MaxIndexCount  = 3072;
 MaxVertexCount = 2048;

//---------------------------------------------------------------------------
{$include Asphyre.Canvas.GLES.VertexShdr.inc}

//---------------------------------------------------------------------------
{$include Asphyre.Canvas.GLES.SolidFill.inc}

//---------------------------------------------------------------------------
{$include Asphyre.Canvas.GLES.TexMap.inc}

//---------------------------------------------------------------------------
type
 PVertexPoint2 = ^TVertexPoint2;
 TVertexPoint2 = record
  x, y: Single;
 end;

//---------------------------------------------------------------------------
const
 ATTRIB_VERTEX    = 0;
 ATTRIB_NORMAL    = 1;
 ATTRIB_COLOR     = 2;
 ATTRIB_TEXCOORD0 = 3;

//---------------------------------------------------------------------------
constructor TGLESCanvas.Create();
begin
 inherited;

 FAntialias := True;
 FMipmapping:= False;
end;

//---------------------------------------------------------------------------
destructor TGLESCanvas.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.CreateStaticBuffers();
begin
 VertexBuffer:= AllocMem(MaxVertexCount * SizeOf(TVertexPoint2));
 TexCoordBuf := AllocMem(MaxVertexCount * SizeOf(TVertexPoint2));

 ColorBuffer:= AllocMem(MaxVertexCount * SizeOf(LongWord));
 IndexBuffer:= AllocMem(MaxIndexCount * SizeOf(Word));
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.DestroyStaticBuffers();
begin
 if (Assigned(IndexBuffer)) then
  FreeNullMem(IndexBuffer);

 if (Assigned(ColorBuffer)) then
  FreeNullMem(ColorBuffer);

 if (Assigned(TexCoordBuf)) then
  FreeNullMem(TexCoordBuf);

 if (Assigned(VertexBuffer)) then
  FreeNullMem(VertexBuffer);
end;

//---------------------------------------------------------------------------
function TGLESCanvas.CompileShader(ShaderType: Integer;
 const ShaderText: string): Integer;
var
 TempBytes: TBytes;
 TextLen: GLint;
 CompileStatus: GLint;
begin
 TextLen:= Length(ShaderText);
 if (TextLen < 1) then
  begin
   Result:= 0;
   Exit;
  end;

 SetLength(TempBytes, TextLen);
 TMarshal.WriteStringAsAnsi(TPtrWrapper.Create(@TempBytes[0]), ShaderText,
  TextLen);

 Result:= glCreateShader(ShaderType);
 if (Result = 0) then Exit;

 glShaderSource(Result, 1, @TempBytes, @TextLen);
 glCompileShader(Result);

 glGetShaderiv(Result, GL_COMPILE_STATUS, @CompileStatus);
 if (CompileStatus = 0)or(glGetError() <> GL_NO_ERROR) then
  begin
   glDeleteShader(Result);
   Result:= 0;
  end;
end;

//---------------------------------------------------------------------------
function TGLESCanvas.CreateShaders(): Boolean;
begin
 GenericVS:= CompileShader(GL_VERTEX_SHADER, VertexShaderCode);

 Result:= (GenericVS <> 0)and(glGetError() = GL_NO_ERROR);
 if (not Result) then Exit;

 SolidFillPS:= CompileShader(GL_FRAGMENT_SHADER, SolidFillPSCode);

 Result:= (SolidFillPS <> 0)and(glGetError() = GL_NO_ERROR);
 if (not Result) then
  begin
   glDeleteShader(GenericVS);
   Exit;
  end;

 TexMapPS:= CompileShader(GL_FRAGMENT_SHADER, TexMapPSCode);

 Result:= (TexMapPS <> 0)and(glGetError() = GL_NO_ERROR);
 if (not Result) then
  begin
   glDeleteShader(SolidFillPS);
   glDeleteShader(GenericVS);
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.DestroyShaders();
begin
 if (TexMapPS <> 0) then
  begin
   glDeleteShader(TexMapPS);
   TexMapPS:= 0;
  end;

 if (SolidFillPS <> 0) then
  begin
   glDeleteShader(SolidFillPS);
   SolidFillPS:= 0;
  end;

 if (GenericVS <> 0) then
  begin
   glDeleteShader(GenericVS);
   GenericVS:= 0;
  end;
end;

//--------------------------------------------------------------------------
function TGLESCanvas.CreateSolidFillProgram(): Boolean;
var
 LinkStatus: Integer;
begin
 SolidFillProgram:= glCreateProgram();

 glAttachShader(SolidFillProgram, GenericVS);
 glAttachShader(SolidFillProgram, SolidFillPS);

 glBindAttribLocation(SolidFillProgram, ATTRIB_VERTEX, 'InPos');
 glBindAttribLocation(SolidFillProgram, ATTRIB_TEXCOORD0, 'InpTexCoord');
 glBindAttribLocation(SolidFillProgram, ATTRIB_COLOR, 'InpColor');

 glLinkProgram(SolidFillProgram);
 glGetProgramiv(SolidFillProgram, GL_LINK_STATUS, @LinkStatus);

 Result:= (LinkStatus <> 0)and(glGetError() = GL_NO_ERROR);
 if (not Result) then
  begin
   glDeleteProgram(SolidFillProgram);
   SolidFillProgram:= 0;
   Exit;
  end;
end;

//--------------------------------------------------------------------------
procedure TGLESCanvas.DestroySolidFillProgram();
begin
 if (SolidFillProgram <> 0) then
  begin
   glDeleteProgram(SolidFillProgram);
   SolidFillProgram:= 0;
  end;
end;

//---------------------------------------------------------------------------
function TGLESCanvas.CreateTexMapProgram(): Boolean;
var
 LinkStatus: Integer;
begin
 TexMapProgram:= glCreateProgram();

 glAttachShader(TexMapProgram, GenericVS);
 glAttachShader(TexMapProgram, TexMapPS);

 glBindAttribLocation(TexMapProgram, ATTRIB_VERTEX, 'InPos');
 glBindAttribLocation(TexMapProgram, ATTRIB_TEXCOORD0, 'InpTexCoord');
 glBindAttribLocation(TexMapProgram, ATTRIB_COLOR, 'InpColor');

 glLinkProgram(TexMapProgram);
 glGetProgramiv(TexMapProgram, GL_LINK_STATUS, @LinkStatus);

 Result:= (LinkStatus <> 0)and(glGetError() = GL_NO_ERROR);
 if (not Result) then
  begin
   glDeleteProgram(TexMapProgram);
   TexMapProgram:= 0;
   Exit;
  end;

 SourceTexLoc:= glGetUniformLocation(TexMapProgram, 'SourceTex');
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.DestroyTexMapProgram();
begin
 if (TexMapProgram <> 0) then
  begin
   glDeleteProgram(TexMapProgram);
   TexMapProgram:= 0;
  end;
end;

//--------------------------------------------------------------------------
function TGLESCanvas.HandleDeviceCreate(): Boolean;
begin
 CreateStaticBuffers();
 Result:= True;
end;

//--------------------------------------------------------------------------
procedure TGLESCanvas.HandleDeviceDestroy();
begin
 DestroyStaticBuffers();
end;

//---------------------------------------------------------------------------
function TGLESCanvas.HandleDeviceReset(): Boolean;
begin
 Result:= CreateShaders();
 if (not Result) then Exit;

 Result:= CreateSolidFillProgram();
 if (not Result) then
  begin
   DestroyShaders();
   Exit;
  end;

 Result:= CreateTexMapProgram();
 if (not Result) then
  begin
   DestroySolidFillprogram();
   DestroyShaders();
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.HandleDeviceLost();
begin
 DestroyTexMapProgram();
 DestroySolidFillProgram();
 DestroyShaders();
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.ResetStates();
var
 Viewport: array[0..3] of GLint;
begin
 FTopology  := gctNone;
 CachedEffect:= beUnknown;
 CachedTex   := nil;
 ActiveTex   := nil;

 VertexCount:= 0;
 IndexCount := 0;

 glGetIntegerv(GL_VIEWPORT, @Viewport[0]);

 NormSize.x:= Viewport[2] * 0.5 / InternalScale;
 NormSize.y:= Viewport[3] * 0.5 / InternalScale;

 glDisable(GL_CULL_FACE);
 glDisable(GL_DEPTH_TEST);

 glBindBuffer(GL_ARRAY_BUFFER, 0);
 glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

 glDisable(GL_STENCIL_TEST);
 glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
 glActiveTexture(GL_TEXTURE0);

 glScissor(Viewport[0], Viewport[1], Viewport[2], Viewport[3]);
 glEnable(GL_SCISSOR_TEST);

 ClipRect:= Bounds(Viewport[0], Viewport[1], Viewport[2], Viewport[3]);
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.HandleBeginScene();
begin
 ResetStates();
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.HandleEndScene();
begin
 Flush();
end;

//---------------------------------------------------------------------------
function TGLESCanvas.GetAntialias(): Boolean;
begin
 Result:= FAntialias;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.SetAntialias(const Value: Boolean);
begin
 FAntialias:= Value;
end;

//---------------------------------------------------------------------------
function TGLESCanvas.GetMipMapping(): Boolean;
begin
 Result:= FMipmapping;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.SetMipMapping(const Value: Boolean);
begin
 FMipmapping:= Value;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.GetViewport(out x, y, Width, Height: Integer);
begin
 x     := ClipRect.Left;
 y     := ClipRect.Top;
 Width := ClipRect.Right - ClipRect.Left;
 Height:= ClipRect.Bottom - ClipRect.Top;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.SetViewport(x, y, Width, Height: Integer);
begin
 ResetScene();
 ClipRect:= Bounds(x, y, Width, Height);

 glScissor(x, (Round(NormSize.y * 2.0) - y) - Height, Width, Height);
end;

//---------------------------------------------------------------------------
function TGLESCanvas.UseSolidFillProgram(): Boolean;
begin
 Result:= SolidFillProgram <> 0;
 if (not Result) then Exit;

 glUseProgram(SolidFillProgram);
end;

//---------------------------------------------------------------------------
function TGLESCanvas.UseTexMapProgram(): Boolean;
begin
 Result:= TexMapProgram <> 0;
 if (not Result) then Exit;

 glUseProgram(TexMapProgram);

 glUniform1i(SourceTexLoc, 0);
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.DrawBuffers();
begin
 if (Assigned(CachedTex)) then
  begin
   if (not UseTexMapProgram()) then Exit;
  end else
  begin
   if (not UseSolidFillProgram()) then Exit;
  end;

 glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE,
  SizeOf(LongWord), ColorBuffer);
 glEnableVertexAttribArray(ATTRIB_COLOR);

 glVertexAttribPointer(ATTRIB_TEXCOORD0, 2, GL_FLOAT, GL_FALSE,
  SizeOf(TVertexPoint2), TexCoordBuf);
 glEnableVertexAttribArray(ATTRIB_TEXCOORD0);

 glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE,
  SizeOf(TVertexPoint2), VertexBuffer);
 glEnableVertexAttribArray(ATTRIB_VERTEX);

 case FTopology of
  gctPoints:
   glDrawElements(GL_POINTS, IndexCount, GL_UNSIGNED_SHORT, IndexBuffer);

  gctLines:
   glDrawElements(GL_LINES, IndexCount, GL_UNSIGNED_SHORT,
    IndexBuffer);

  gctTriangles:
   glDrawElements(GL_TRIANGLES, IndexCount, GL_UNSIGNED_SHORT,
    IndexBuffer);
 end;

 glDisableVertexAttribArray(ATTRIB_VERTEX);
 glDisableVertexAttribArray(ATTRIB_COLOR);
 glDisableVertexAttribArray(ATTRIB_TEXCOORD0);
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.ResetScene();
begin
 if (VertexCount > 0) then DrawBuffers();

 VertexCount:= 0;
 IndexCount := 0;

 FTopology:= gctNone;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.Flush();
begin
 ResetScene();
 RequestEffect(beUnknown);
 RequestTexture(nil);
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.RequestCache(const Mode: TGLESCanvasTopology;
 const Vertices, Indices: Integer);
begin
 if (VertexCount + Vertices > MaxVertexCount)or
  (IndexCount + Indices > MaxIndexCount)or
  (FTopology = gctNone)or(FTopology <> Mode) then ResetScene();

 FTopology:= Mode;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.RequestEffect(const Effect: TBlendingEffect);
begin
 if (CachedEffect = Effect) then Exit;

 ResetScene();

 if (Effect <> beUnknown) then glEnable(GL_BLEND)
  else glDisable(GL_BLEND);

 case Effect of
  beNormal:
   glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  beShadow:
   glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA);

  beAdd:
   glBlendFunc(GL_SRC_ALPHA, GL_ONE);

  beMultiply:
   glBlendFunc(GL_ZERO, GL_SRC_COLOR);

  beInvMultiply:
   glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_COLOR);

  beSrcColor:
   glBlendFunc(GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR);

  beSrcColorAdd:
   glBlendFunc(GL_SRC_COLOR, GL_ONE);
 end;

 CachedEffect:= Effect;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.RequestTexture(const Texture: TAsphyreCustomTexture);
begin
 if (CachedTex = Texture) then Exit;

 ResetScene();

 if (Assigned(Texture)) then
  begin
   Texture.Bind(0);

   if (FAntialias) then
    begin
     if (FMipmapping)and(Texture.Mipmapping) then
      begin
       glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
        GL_LINEAR_MIPMAP_LINEAR);
      end else
       glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    end else
    begin
     if (FMipmapping)and(Texture.Mipmapping) then
      begin
       glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
        GL_LINEAR_MIPMAP_NEAREST);
      end else
       glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    end;
  end else
  begin
   glBindTexture(GL_TEXTURE_2D, 0);
  end;

 CachedTex:= Texture;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.InsertRawVertex(const Pos: TPoint2);
var
 DestPt: PVertexPoint2;
begin
 DestPt:= Pointer(PtrInt(VertexBuffer) + VertexCount * SizeOf(TVertexPoint2));
 DestPt.x:= (Pos.x - NormSize.x) / NormSize.x;
 DestPt.y:= -(Pos.y - NormSize.y) / NormSize.y;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.InsertVertex(const Pos, TexCoord: TPoint2;
 const Color: Cardinal);
var
 DestCol: PLongWord;
 DestPt : PVertexPoint2;
begin
 InsertRawVertex(Pos);

 DestCol:= Pointer(PtrInt(ColorBuffer) + VertexCount * SizeOf(LongWord));
 DestCol^:= DisplaceRB(Color);

 DestPt:= Pointer(PtrInt(TexCoordBuf) + VertexCount * SizeOf(TVertexPoint2));
 DestPt.x:= TexCoord.x;
 DestPt.y:= TexCoord.y;

 Inc(VertexCount);
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.InsertIndex(const Value: Integer);
var
 DestIndx: PWord;
begin
 DestIndx:= Pointer(PtrInt(IndexBuffer) + IndexCount * SizeOf(Word));
 DestIndx^:= Value;

 Inc(IndexCount);
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.PutPixel(const Point: TPoint2; Color: Cardinal);
var
 Index: Integer;
begin
 RequestEffect(beNormal);
 RequestTexture(nil);
 RequestCache(gctPoints, 1, 1);

 Index:= VertexCount;

 InsertVertex(Point + Point2(0.5, 0.5), ZeroVec2, Color);
 InsertIndex(Index);
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.Line(const Src, Dest: TPoint2; Color0,
 Color1: Cardinal);
var
 Index: Integer;
begin
 RequestEffect(beNormal);
 RequestTexture(nil);
 RequestCache(gctLines, 2, 2);

 Index:= VertexCount;

 InsertVertex(Src + Point2(0.5, 0.5), ZeroVec2, Color0);
 InsertVertex(Dest + Point2(0.5, 0.5), ZeroVec2, Color1);

 InsertIndex(Index);
 InsertIndex(Index + 1);
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.DrawIndexedTriangles(Vertices: PPoint2;
 Colors: PLongWord; Indices: PLongInt; NoVertices, NoTriangles: Integer;
 Effect: TBlendingEffect);
var
 Index : PLongInt;
 Vertex: PPoint2;
 Color : PLongWord;
 i     : Integer;
begin
 RequestEffect(Effect);
 RequestTexture(nil);
 RequestCache(gctTriangles, NoVertices, NoTriangles * 3);

 Index:= Indices;

 for i:= 0 to (NoTriangles * 3) - 1 do
  begin
   InsertIndex(VertexCount + Index^);
   Inc(Index);
  end;

 Vertex:= Vertices;
 Color := Colors;

 for i:= 0 to NoVertices - 1 do
  begin
   InsertVertex(Vertex^, ZeroVec2, Color^);

   Inc(Vertex);
   Inc(Color);
  end;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.UseTexture(const Texture: TAsphyreCustomTexture;
 const Mapping: TPoint4);
begin
 ActiveTex  := Texture;
 QuadMapping:= Mapping;
end;

//---------------------------------------------------------------------------
procedure TGLESCanvas.TexMap(const Points: TPoint4; const Colors: TColor4;
 Effect: TBlendingEffect);
var
 Index: Integer;
begin
 RequestEffect(Effect);
 RequestTexture(ActiveTex);
 RequestCache(gctTriangles, 4, 6);

 Index:= VertexCount;

 InsertVertex(Points[0], QuadMapping[0], Colors[0]);
 InsertVertex(Points[1], QuadMapping[1], Colors[1]);
 InsertVertex(Points[3], QuadMapping[3], Colors[3]);
 InsertVertex(Points[2], QuadMapping[2], Colors[2]);

 InsertIndex(Index + 2);
 InsertIndex(Index + 0);
 InsertIndex(Index + 1);

 InsertIndex(Index + 3);
 InsertIndex(Index + 2);
 InsertIndex(Index + 1);
end;

//---------------------------------------------------------------------------
end.
