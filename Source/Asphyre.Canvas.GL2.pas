unit Asphyre.Canvas.GL2;
//---------------------------------------------------------------------------
// Modern OpenGL canvas implementation.
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
{$ifdef FireMonkey}
 Macapi.CocoaTypes, Macapi.OpenGL
{$else}
 Asphyre.GL
{$endif},

{$ifndef fpc}
 System.Types,
{$else}
 Types,
{$endif}
 Asphyre.TypeDef, Asphyre.Math, Asphyre.Types,
 Asphyre.Textures, Asphyre.Canvas;

//---------------------------------------------------------------------------
type
 TCanvasTopology = (ctNone, ctPoints, ctLines, ctTriangles);
 TCanvasProgram = (cpNone, cpSolid, cpTextured);

//---------------------------------------------------------------------------
 TGLCanvas = class(TAsphyreCanvas)
 private
  SystemVertexBuffer: Pointer;
  SystemIndexBuffer : Pointer;

  GPUVertexBuffer: GLuint;
  GPUIndexBuffer : GLuint;

  CachedVertexCount: Integer;
  CachedIndexCount : Integer;

  Topology    : TCanvasTopology;
  CurProgram  : TCanvasProgram;
  NormSize    : TPoint2;
  CachedEffect: TBlendingEffect;
  CachedTex   : TAsphyreCustomTexture;
  ActiveTex   : TAsphyreCustomTexture;
  QuadMapping : TPoint4;
  FAntialias  : Boolean;
  FMipmapping : Boolean;

  ClippingRect: TRect;
  ViewportRect: TRect;

  CompiledVS: GLuint;
  CompiledSolidPS: GLuint;
  CompiledTexturedPS: GLuint;

  SolidProgram: GLuint;
  TexturedProgram: GLuint;
  SourceTexLocation: GLint;

  SolidInpVertex: GLint;
  SolidInpTexCoord: GLint;
  SolidInpColor: GLint;

  TexturedInpVertex: GLint;
  TexturedInpTexCoord: GLint;
  TexturedInpColor: GLint;

  CurrentInpVertex: GLint;
  CurrentInpTexCoord: GLint;
  CurrentInpColor: GLint;

  procedure CreateSystemBuffers();
  procedure DestroySystemBuffers();

  function CreateGPUBuffers(): Boolean;
  procedure DestroyGPUBuffers();

  function CompileShader(ShaderType: GLenum;
   const ShaderText: AnsiString): GLuint;

  function CreateShaders(): Boolean;
  procedure DestroyShaders();

  function CreateSolidProgram(): Boolean;
  function CreateTexturedProgram(): Boolean;
  procedure DestroySolidProgram();
  procedure DestroyTexturedProgram();

  function UseSolidProgram(): Boolean;
  function UseTexturedProgram(): Boolean;
  function UploadBuffers(): Boolean;
  function DrawBuffers(): Boolean;

  procedure ResetScene();
  procedure RequestCache(NewTopology: TCanvasTopology;
   NewProgram: TCanvasProgram; Vertices, Indices: Integer);
  procedure RequestEffect(Effect: TBlendingEffect);
  procedure RequestTexture(Texture: TAsphyreCustomTexture);
  procedure InsertElementVertex(const PosAt: TPoint2; Color: Cardinal;
   const TexCoord: TPoint2);
  procedure InsertElementIndex(Value: Integer);
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
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.SysUtils,
{$else}
 SysUtils,
{$endif}
 Asphyre.Types.GL, Asphyre.Canvas.GL2.Shaders;

//---------------------------------------------------------------------------
type
 PVertexRecord = ^TVertexRecord;
 TVertexRecord = packed record
  x, y : GLfloat;
  u, v : GLfloat;
  Color: GLuint;
 end;

//--------------------------------------------------------------------------
const
 // The following parameters roughly affect the rendering performance. The
 // higher values means that more primitives will fit in cache, but it will
 // also occupy more bandwidth, even when few primitives are rendered.
 //
 // These parameters can be fine-tuned in a finished product to improve the
 // overall performance.
 MaxCachedIndices  = 4096;
 MaxCachedVertices = 4096;

//---------------------------------------------------------------------------
constructor TGLCanvas.Create();
begin
 inherited;

 FAntialias := True;
 FMipmapping:= False;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.CreateSystemBuffers();
begin
 SystemVertexBuffer:= AllocMem(SizeOf(TVertexRecord) * MaxCachedVertices);
 SystemIndexBuffer := AllocMem(SizeOf(Word) * MaxCachedIndices);
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.DestroySystemBuffers();
begin
 if (Assigned(SystemIndexBuffer)) then FreeNullMem(SystemIndexBuffer);
 if (Assigned(SystemVertexBuffer)) then FreeNullMem(SystemVertexBuffer);
end;

//---------------------------------------------------------------------------
function TGLCanvas.CreateGPUBuffers(): Boolean;
begin
 glGenBuffers(1, @GPUVertexBuffer);
 glBindBuffer(GL_ARRAY_BUFFER, GPUVertexBuffer);
 glBufferData(GL_ARRAY_BUFFER, SizeOf(TVertexRecord) * MaxCachedVertices, nil,
  GL_DYNAMIC_DRAW);

 glGenBuffers(1, @GPUIndexBuffer);
 glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, GPUIndexBuffer);
 glBufferData(GL_ELEMENT_ARRAY_BUFFER, SizeOf(Word) * MaxCachedIndices, nil,
  GL_DYNAMIC_DRAW);

 Result:= (glGetError() = GL_NO_ERROR)and(GPUVertexBuffer <> 0)and
  (GPUIndexBuffer <> 0);
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.DestroyGPUBuffers();
begin
 if (GPUIndexBuffer <> 0) then
  begin
   glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
   glDeleteBuffers(1, @GPUIndexBuffer);

   GPUIndexBuffer:= 0;
  end;

 if (GPUVertexBuffer <> 0) then
  begin
   glBindBuffer(GL_ARRAY_BUFFER, 0);
   glDeleteBuffers(1, @GPUVertexBuffer);

   GPUVertexBuffer:= 0;
  end;
end;

//---------------------------------------------------------------------------
function TGLCanvas.CompileShader(ShaderType: GLenum;
 const ShaderText: AnsiString): GLuint;
var
 TextLen: GLint;
 CompileStatus: GLint;
 ShaderSource: PPGLchar;
begin
 TextLen:= Length(ShaderText) - 1;
 if (TextLen < 1) then
  begin
   Result:= 0;
   Exit;
  end;

 Result:= glCreateShader(ShaderType);
 if (Result = 0) then Exit;

 ShaderSource:= @ShaderText[1];

 glShaderSource(Result, 1, @ShaderSource, @TextLen);
 glCompileShader(Result);

 glGetShaderiv(Result, GL_COMPILE_STATUS, @CompileStatus);

 if (CompileStatus <> GL_TRUE) then
  begin
   glDeleteShader(Result);
   Result:= 0;
  end;
end;

//---------------------------------------------------------------------------
function TGLCanvas.CreateShaders(): Boolean;
begin
 // (1) Normal Vertex Shader.
 CompiledVS:= CompileShader(GL_VERTEX_SHADER, VertexShaderSource);

 Result:= CompiledVS <> 0;
 if (not Result) then Exit;

 // (2) Solid Pixel Shader.
 CompiledSolidPS:= CompileShader(GL_FRAGMENT_SHADER, PixelShaderSolidSource);

 Result:= CompiledSolidPS <> 0;
 if (not Result) then
  begin
   glDeleteShader(CompiledSolidPS);
   Exit;
  end;

 // (3) Textured Pixel Shader.
 CompiledTexturedPS:= CompileShader(GL_FRAGMENT_SHADER,
  PixelShaderTexturedSource);

 Result:= CompiledTexturedPS <> 0;
 if (not Result) then
  begin
   glDeleteShader(CompiledSolidPS);
   glDeleteShader(CompiledVS);
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.DestroyShaders();
begin
 if (CompiledTexturedPS <> 0) then
  begin
   glDeleteShader(CompiledTexturedPS);
   CompiledTexturedPS:= 0;
  end;

 if (CompiledSolidPS <> 0) then
  begin
   glDeleteShader(CompiledSolidPS);
   CompiledSolidPS:= 0;
  end;

 if (CompiledVS <> 0) then
  begin
   glDeleteShader(CompiledVS);
   CompiledVS:= 0;
  end;
end;

//---------------------------------------------------------------------------
function TGLCanvas.CreateSolidProgram(): Boolean;
var
 LinkStatus: Integer;
begin
 SolidProgram:= glCreateProgram();

 glAttachShader(SolidProgram, CompiledVS);
 glAttachShader(SolidProgram, CompiledSolidPS);

 glLinkProgram(SolidProgram);
 glGetProgramiv(SolidProgram, GL_LINK_STATUS, @LinkStatus);

 Result:= LinkStatus <> 0;
 if (not Result) then
  begin
   glDeleteProgram(SolidProgram);
   SolidProgram:= 0;
   Exit;
  end;

 SolidInpVertex  := glGetAttribLocation(SolidProgram, 'InpVertex');
 SolidInpTexCoord:= glGetAttribLocation(SolidProgram, 'InpTexCoord');
 SolidInpColor   := glGetAttribLocation(SolidProgram, 'InpColor');
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.DestroySolidProgram();
begin
 if (SolidProgram <> 0) then
  begin
   glDeleteProgram(SolidProgram);
   SolidProgram:= 0;
  end;
end;

//---------------------------------------------------------------------------
function TGLCanvas.CreateTexturedProgram(): Boolean;
var
 LinkStatus: Integer;
begin
 TexturedProgram:= glCreateProgram();

 glAttachShader(TexturedProgram, CompiledVS);
 glAttachShader(TexturedProgram, CompiledTexturedPS);

 glLinkProgram(TexturedProgram);
 glGetProgramiv(TexturedProgram, GL_LINK_STATUS, @LinkStatus);

 Result:= LinkStatus <> 0;
 if (not Result) then
  begin
   glDeleteProgram(TexturedProgram);
   TexturedProgram:= 0;
   Exit;
  end;

 SourceTexLocation:= glGetUniformLocation(TexturedProgram, 'SourceTex');

 TexturedInpVertex  := glGetAttribLocation(TexturedProgram, 'InpVertex');
 TexturedInpTexCoord:= glGetAttribLocation(TexturedProgram, 'InpTexCoord');
 TexturedInpColor   := glGetAttribLocation(TexturedProgram, 'InpColor');
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.DestroyTexturedProgram();
begin
 if (TexturedProgram <> 0) then
  begin
   glDeleteProgram(TexturedProgram);
   TexturedProgram:= 0;
  end;
end;

//---------------------------------------------------------------------------
function TGLCanvas.HandleDeviceCreate(): Boolean;
begin
 Result:= GL_VERSION_2_0;
 if (not Result) then Exit;

 Result:= CreateGPUBuffers();
 if (not Result) then Exit;

 CreateSystemBuffers();
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.HandleDeviceDestroy();
begin
 DestroyGPUBuffers();
 DestroySystemBuffers();
end;

//---------------------------------------------------------------------------
function TGLCanvas.HandleDeviceReset(): Boolean;
begin
 Result:= CreateShaders();
 if (not Result) then Exit;

 Result:= CreateSolidProgram();
 if (not Result) then
  begin
   DestroyShaders();
   Exit;
  end;

 Result:= CreateTexturedProgram();
 if (not Result) then
  begin
   DestroySolidProgram();
   DestroyShaders();
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.HandleDeviceLost();
begin
 DestroyTexturedProgram();
 DestroySolidProgram();
 DestroyShaders();
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.ResetStates();
var
 Viewport: array[0..3] of GLint;
begin
 Topology:= ctNone;
 CurProgram:= cpNone;
 CachedEffect:= beUnknown;

 CachedTex:= nil;
 ActiveTex:= nil;

 CachedVertexCount:= 0;
 CachedIndexCount := 0;

 glGetIntegerv(GL_VIEWPORT, @Viewport[0]);

 NormSize.x:= Viewport[2] * 0.5;
 NormSize.y:= Viewport[3] * 0.5;

 glDisable(GL_DEPTH_TEST);

 glDisable(GL_TEXTURE_1D);
 glDisable(GL_TEXTURE_2D);
 glDisable(GL_LINE_SMOOTH);

 glScissor(Viewport[0], Viewport[1], Viewport[2], Viewport[3]);
 glEnable(GL_SCISSOR_TEST);

 ClippingRect:= Bounds(Viewport[0], Viewport[1], Viewport[2], Viewport[3]);
 ViewportRect:= Bounds(Viewport[0], Viewport[1], Viewport[2], Viewport[3]);
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.HandleBeginScene();
begin
 ResetStates();
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.HandleEndScene();
begin
 Flush();
end;

//---------------------------------------------------------------------------
function TGLCanvas.GetAntialias(): Boolean;
begin
 Result:= FAntialias;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.SetAntialias(const Value: Boolean);
begin
 FAntialias:= Value;
end;

//---------------------------------------------------------------------------
function TGLCanvas.GetMipMapping(): Boolean;
begin
 Result:= FMipmapping;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.SetMipMapping(const Value: Boolean);
begin
 FMipmapping:= Value;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.GetViewport(out x, y, Width, Height: Integer);
begin
 x:= ClippingRect.Left;
 y:= ClippingRect.Top;
 Width := ClippingRect.Right - ClippingRect.Left;
 Height:= ClippingRect.Bottom - ClippingRect.Top;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.SetViewport(x, y, Width, Height: Integer);
var
 ViewPos: Integer;
begin
 ResetScene();

 ViewPos:= (ViewportRect.Bottom - ViewportRect.Top) - (y + Height);

 glScissor(x, Viewpos, Width, Height);
 ClippingRect:= Bounds(x, y, Width, Height);
end;

//---------------------------------------------------------------------------
function TGLCanvas.UseSolidProgram(): Boolean;
begin
 Result:= SolidProgram <> 0;
 if (not Result) then Exit;

 glUseProgram(SolidProgram);

 CurrentInpVertex:= SolidInpVertex;
 CurrentInpTexCoord:= SolidInpTexCoord;
 CurrentInpColor:= SolidInpColor;
end;

//---------------------------------------------------------------------------
function TGLCanvas.UseTexturedProgram(): Boolean;
begin
 Result:= TexturedProgram <> 0;
 if (not Result) then Exit;

 glUseProgram(TexturedProgram);

 CurrentInpVertex:= TexturedInpVertex;
 CurrentInpTexCoord:= TexturedInpTexCoord;
 CurrentInpColor:= TexturedInpColor;

 glUniform1i(SourceTexLocation, 0);
end;

//---------------------------------------------------------------------------
function TGLCanvas.UploadBuffers(): Boolean;
begin
 if (CachedVertexCount > 0) then
  begin
   glBindBuffer(GL_ARRAY_BUFFER, GPUVertexBuffer);
   glBufferSubData(GL_ARRAY_BUFFER, 0, SizeOf(TVertexRecord) *
    CachedVertexCount, SystemVertexBuffer);
  end;

 if (CachedIndexCount > 0) then
  begin
   glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, GPUIndexBuffer);
   glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, SizeOf(Word) *
    CachedIndexCount, SystemIndexBuffer);
  end;

 Result:= glGetError() = GL_NO_ERROR;
end;

//---------------------------------------------------------------------------
function TGLCanvas.DrawBuffers(): Boolean;
var
 RecordSize: GLsizei;
begin
 glBindBuffer(GL_ARRAY_BUFFER, GPUVertexBuffer);
 RecordSize:= SizeOf(TVertexRecord);

 if (CurrentInpVertex >= 0) then
  begin
   glVertexAttribPointer(CurrentInpVertex, 2, GL_FLOAT, False, RecordSize,
    nil);
   glEnableVertexAttribArray(CurrentInpVertex);
  end;

 if (CurrentInpTexCoord >= 0) then
  begin
   glVertexAttribPointer(CurrentInpTexCoord, 2, GL_FLOAT, False, RecordSize,
    Pointer(8));
   glEnableVertexAttribArray(CurrentInpTexCoord);
  end;

 if (CurrentInpColor >= 0) then
  begin
   glVertexAttribPointer(CurrentInpColor, 4, GL_UNSIGNED_BYTE, True,
    RecordSize, Pointer(16));
   glEnableVertexAttribArray(CurrentInpColor);
  end;

 case Topology of
  ctPoints:
   glDrawArrays(GL_POINTS, 0, CachedVertexCount);

  ctLines:
   glDrawArrays(GL_LINES, 0, CachedVertexCount);

  ctTriangles:
   begin
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, GPUIndexBuffer);
    glDrawElements(GL_TRIANGLES, CachedIndexCount, GL_UNSIGNED_SHORT, nil);
   end;
 end;

 Result:= glGetError() = GL_NO_ERROR;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.ResetScene();
begin
 if (CachedVertexCount > 0) then
  if (UploadBuffers()) then
   begin
    DrawBuffers();
    NextDrawCall();
   end;

 CachedVertexCount:= 0;
 CachedIndexCount := 0;

 Topology:= ctNone;

 if (CurProgram <> cpNone) then
  begin
   CurProgram:= cpNone;
   glUseProgram(0);
  end;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.RequestCache(NewTopology: TCanvasTopology;
 NewProgram: TCanvasProgram; Vertices, Indices: Integer);
begin
 if (CachedVertexCount + Vertices > MaxCachedVertices)or
  (CachedIndexCount + Indices > MaxCachedIndices)or
  (Topology = ctNone)or(Topology <> NewTopology)or
  (CurProgram = cpNone)or(CurProgram <> NewProgram) then ResetScene();

 Topology:= NewTopology;
 CurProgram:= NewProgram;

 case CurProgram of
  cpSolid:
   UseSolidProgram();

  cpTextured:
   UseTexturedProgram();
 end;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.RequestEffect(Effect: TBlendingEffect);
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

  beSrcColor:
   glBlendFunc(GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR);

  beSrcColorAdd:
   glBlendFunc(GL_SRC_COLOR, GL_ONE);

  beInvMultiply:
   glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_COLOR);
 end;

 CachedEffect:= Effect;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.RequestTexture(Texture: TAsphyreCustomTexture);
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

   glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
   glEnable(GL_TEXTURE_2D);
  end else
  begin
   glBindTexture(GL_TEXTURE_2D, 0);
   glDisable(GL_TEXTURE_2D);
  end;

 CachedTex:= Texture;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.InsertElementVertex(const PosAt: TPoint2;
 Color: Cardinal; const TexCoord: TPoint2);
var
 DestValue: PVertexRecord;
begin
 DestValue:= Pointer(PtrInt(SystemVertexBuffer) + CachedVertexCount *
  SizeOf(TVertexRecord));

 DestValue.x:= (PosAt.x - NormSize.x) / NormSize.x;
 DestValue.y:= (PosAt.y - NormSize.y) / NormSize.y;

 if (not GL_UsingFrameBuffer) then
  DestValue.y:= -DestValue.y;

 DestValue.Color:= DisplaceRB(Color);

 DestValue.u:= TexCoord.x;
 DestValue.v:= TexCoord.y;

 Inc(CachedVertexCount);
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.InsertElementIndex(Value: Integer);
var
 DestValue: PWord;
begin
 DestValue:= Pointer(PtrInt(SystemIndexBuffer) + CachedIndexCount *
  SizeOf(Word));
 DestValue^:= Value;

 Inc(CachedIndexCount);
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.PutPixel(const Point: TPoint2; Color: Cardinal);
begin
 RequestEffect(beNormal);
 RequestTexture(nil);
 RequestCache(ctPoints, cpSolid, 1, 0);

 InsertElementVertex(Point, Color, ZeroVec2);
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.Line(const Src, Dest: TPoint2; Color0, Color1: Cardinal);
begin
 RequestEffect(beNormal);
 RequestTexture(nil);
 RequestCache(ctLines, cpSolid, 2, 0);

 InsertElementVertex(Src + Point2(0.5, 0.5), Color0, ZeroVec2);
 InsertElementVertex(Dest + Point2(0.5, 0.5), Color1, ZeroVec2);
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.DrawIndexedTriangles(Vertices: PPoint2; Colors: PLongWord;
 Indices: PLongInt; NoVertices, NoTriangles: Integer; Effect: TBlendingEffect);
var
 InpVertex: PPoint2;
 InpColor: PLongWord;
 InpIndex: PLongInt;
 i, StartVertex: Integer;
begin
 RequestEffect(Effect);
 RequestTexture(nil);
 RequestCache(ctTriangles, cpSolid, NoVertices, NoTriangles * 3);

 StartVertex:= CachedVertexCount;

 InpVertex:= Vertices;
 InpColor:= Colors;

 for i:= 0 to NoVertices - 1 do
  begin
   InsertElementVertex(InpVertex^, InpColor^, ZeroVec2);
   Inc(InpVertex);
   Inc(InpColor);
  end;

 InpIndex:= Indices;

 for i:= 0 to (NoTriangles * 3) - 1 do
  begin
   InsertElementIndex(StartVertex + InpIndex^);
   Inc(InpIndex);
  end;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.UseTexture(const Texture: TAsphyreCustomTexture;
 const Mapping: TPoint4);
begin
 ActiveTex  := Texture;
 QuadMapping:= Mapping;
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.TexMap(const Points: TPoint4; const Colors: TColor4;
 Effect: TBlendingEffect);
var
 StartVertex: Integer;
begin
 RequestEffect(Effect);
 RequestTexture(ActiveTex);
 RequestCache(ctTriangles, cpTextured, 4, 6);

 StartVertex:= CachedVertexCount;

 InsertElementVertex(Points[0], Colors[0], QuadMapping[0]);
 InsertElementVertex(Points[1], Colors[1], QuadMapping[1]);
 InsertElementVertex(Points[3], Colors[3], QuadMapping[3]);
 InsertElementVertex(Points[2], Colors[2], QuadMapping[2]);

 InsertElementIndex(StartVertex + 2);
 InsertElementIndex(StartVertex + 0);
 InsertElementIndex(StartVertex + 1);

 InsertElementIndex(StartVertex + 3);
 InsertElementIndex(StartVertex + 2);
 InsertElementIndex(StartVertex + 1);
end;

//---------------------------------------------------------------------------
procedure TGLCanvas.Flush();
begin
 ResetScene();
 RequestEffect(beUnknown);
 RequestTexture(nil);
end;

//---------------------------------------------------------------------------
end.
