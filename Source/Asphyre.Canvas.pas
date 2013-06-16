unit Asphyre.Canvas;
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
// Note: this file has been preformatted to be used with PasDoc.
//---------------------------------------------------------------------------
{< 2D rendering canvas specification and functions for drawing lines, filled
   shapes and images using gradient colors and alpha transparency. }
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
 Asphyre.TypeDef, Asphyre.Math, Asphyre.Types, Asphyre.Textures, Asphyre.Images;

//---------------------------------------------------------------------------
type
{ The blending effect that should be applied when drawing 2D primitives. }
 TBlendingEffect = (
  { Undefined blending effect. This effect type is used internally and should
    not be used elsewhere. @br @br }
  beUnknown,

  { Normal blending effect. If drawing primitive has alpha-channel supplied,
    it will be alpha-blended to the destination depending on alpha
    transparency. @br @br }
  beNormal,

  { Shadow drawing effect. The screen (or render target) will be multiplied by
    alpha-channel of the source primitive; thus, the rendered image will look
    like a shadow. @br @br }
  beShadow,

  { Addition blending effect. The source primitive will be multiplied by its
    alpha-channel and then added to the destination using saturation. @br @br }
  beAdd,

  { Multiplication blending effect. The screen (or render target) will be
    multiplied by the source primitive. @br @br }
  beMultiply,

  { Inverse multiplication effect. The screen (or render target) will be
    multiplied by an inverse of the source primitive. @br @br }
  beInvMultiply,

  { Source color blending effect. Instead of using alpha-channel, the
    grayscale value of source primitive's pixels will be used as an alpha
    value for blending on destination. @br @br }
  beSrcColor,

  { Source color addition effect. Instead of using alpha-channel, the
    grayscale value of source primitive's pixels will be used as an alpha
    value for multiplying source pixels, which will then be added to
    destination using saturation. @br @br }
  beSrcColorAdd);

//---------------------------------------------------------------------------
{ 2D canvas specification for rendering points, lines, filled shapes and
  images using gradient color fills, different blending effects, and alpha
  transparency. }
 TAsphyreCanvas = class
 private
  FCacheStall: Integer;
  FDeviceScale: Single;
  FExternalScale: Single;

  HexLookup: array[0..5] of TPoint2;

  procedure InitHexLookup();

  procedure UpdateInternalScale();
  procedure SetDeviceScale(const Value: Single);
  procedure SetExternalScale(const Value: Single);

  procedure OnDeviceCreate(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);
  procedure OnDeviceDestroy(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);
  procedure OnDeviceReset(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);
  procedure OnDeviceLost(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);

  procedure OnBeginScene(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);
  procedure OnEndScene(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);

  function GetClipRect(): TRect;
  procedure SetClipRect(const Value: TRect);
  procedure WuHoriz(x1, y1, x2, y2: Single; Color1, Color2: Cardinal);
  procedure WuVert(x1, y1, x2, y2: Single; Color1, Color2: Cardinal);
 protected
  function HandleDeviceCreate(): Boolean; virtual;
  procedure HandleDeviceDestroy(); virtual;
  function HandleDeviceReset(): Boolean; virtual;
  procedure HandleDeviceLost(); virtual;

  procedure HandleBeginScene(); virtual; abstract;
  procedure HandleEndScene(); virtual; abstract;

  procedure GetViewport(out x, y, Width, Height: Integer); virtual; abstract;
  procedure SetViewport(x, y, Width, Height: Integer); virtual; abstract;
  function GetAntialias(): Boolean; virtual; abstract;
  procedure SetAntialias(const Value: Boolean); virtual; abstract;
  function GetMipMapping(): Boolean; virtual; abstract;
  procedure SetMipMapping(const Value: Boolean); virtual; abstract;

  procedure NextDrawCall();
 protected
  InternalScale: Single;
 public
  { Number of times the rendering cache was reseted during last rendering
    frame. Each cache reset is typically a time-consuming operation so high
    number of such events could be detrimental to the application's rendering
    performance. If this parameter happens to be considerably high (above 20)
    in the rendered scene, the rendering code should be revised for better
    grouping of images, shapes and blending types. }
  property CacheStall: Integer read FCacheStall;

  { The clipping rectangle in which the rendering will be made. This can be
    useful for restricting the rendering to a certain part of screen. }
  property ClipRect: TRect read GetClipRect write SetClipRect;

  { Determines whether antialiasing should be used when stretching images and
    textures. If this parameter is set to @False, no antialiasing will be made
    and stretched images will appear pixelated. There is little to none
    performance gain from not using antialiasing, so this parameter should
    typically be set to @True. }
  property Antialias: Boolean read GetAntialias write SetAntialias;

  { Determines whether mipmapping should be used when rendering images and
    textures. Mipmapping can improve visual quality when extreme shrinking of
    original images is made at the expense of performance. }
  property MipMapping: Boolean read GetMipMapping write SetMipMapping;

  { Determines the current scale of device to be rendered on. This value should
    be typically taken from @link(TAsphyreDevice) when rendering on the screen,
    or set to 1.0 when rendering on render target. Additionally, this value can
    be set to other values to compensate for screen's DPI. }
  property DeviceScale: Single read FDeviceScale write SetDeviceScale;

  { Determines the scale that user (or application) uses for rendering on this
    canvas. If this scale matches @link(DeviceScale), then pixel to pixel
    mapping is achieved. }
  property ExternalScale: Single read FExternalScale write SetExternalScale;

  //-------------------------------------------------------------------------
  { Draws a single pixel on the screen or render target using the specified
    2D floating-point vector. }
  procedure PutPixel(const Point: TPoint2;
   Color: Cardinal); overload; virtual; abstract;

  { Draws a single pixel on the screen or render target using the specified
    coordinates. }
  procedure PutPixel(x, y: Single; Color: Cardinal); overload;

  //.........................................................................
  { Draws line between the two specified 2D floating-point vectors using
    gradient of two colors. }
  procedure Line(const Src, Dest: TPoint2; Color1,
   Color2: Cardinal); overload; virtual; abstract;

  { Draws line between the two specified 2D floating-point vectors using
    solid color. }
  procedure Line(const Src, Dest: TPoint2; Color: Cardinal); overload;

  { Draws line between the specified coordinates using solid color. }
  procedure Line(x1, y1, x2, y2: Single; Color: Cardinal); overload;

  { Draws series of lines between specified vertices using solid color. }
  procedure LineArray(Points: PPoint2; Color: Cardinal;
   NoPoints: Integer); virtual;

  { Draws antialiased "wu-line" using @link(PutPixel) primitive between the
    specified 2D floating-point vectors using two color gradient. }
  procedure WuLine(Src, Dest: TPoint2; Color1, Color2: Cardinal);

  //.........................................................................
  { Draws ellipse at the given position, radius and color. This routine uses
    @link(Line) routine. @code(Steps) parameter indicates the number of
    divisions in the ellipse. }
  procedure Ellipse(const Pos, Radius: TPoint2; Steps: Integer;
   Color: Cardinal);

  { Draws circle at the given position, radius and color. This routine uses
    @link(Line) routine. @code(Steps) parameter indicates the number of
    divisions in the circle. }
  procedure Circle(const Pos: TPoint2; Radius: Single; Steps: Integer;
   Color: Cardinal);

  //.........................................................................
  { Draws multiple filled triangles using the specified vertices, vertex
    colors and index buffers. This is a low-level routine and can be used
    for drawing complex shapes quickly and efficiently. }
  procedure DrawIndexedTriangles(Vertices: PPoint2; Colors: PLongWord;
   Indices: PLongInt; NoVertices, NoTriangles: Integer;
   Effect: TBlendingEffect = beNormal); virtual; abstract;

  //.........................................................................
  { Draws filled triangle between the specified vertices and vertex colors. }
  procedure FillTri(const p1, p2, p3: TPoint2; c1, c2, c3: Cardinal;
   Effect: TBlendingEffect = beNormal);

  { Draws filled quad between the specified vertices and vertex colors. }
  procedure FillQuad(const Points: TPoint4; const Colors: TColor4;
   Effect: TBlendingEffect = beNormal);

  { Draws lines between the specified vertices (making it a wireframe quad)
    and vertex colors. }
  procedure WireQuad(const Points: TPoint4; const Colors: TColor4);

  { Draws rectangle filled with the specified 4-color gradient. }
  procedure FillRect(const Rect: TRect; const Colors: TColor4;
   Effect: TBlendingEffect = beNormal); overload;

  { Draws rectangle filled with solid color. }
  procedure FillRect(const Rect: TRect; Color: Cardinal;
   Effect: TBlendingEffect = beNormal); overload;

  { Draws rectangle at the given coordinates filled with solid color. }
  procedure FillRect(Left, Top, Width, Height: Integer; Color: Cardinal;
   Effect: TBlendingEffect = beNormal); overload;

  //.........................................................................
  { Draws lines between four corners of the given rectangle where the lines
    are filled using 4-color gradient. This method uses filled shapes instead
    of line primitives for pixel-perfect mapping but assumes that the four
    vertex points are aligned to form rectangle. }
  procedure FrameRect(const Points: TPoint4; const Colors: TColor4;
   Effect: TBlendingEffect = beNormal); overload;

  { Draws lines that form the specified rectangle using colors from the given
    4-color gradient. This primitive uses filled shapes and not actual lines
    for pixel-perfect mapping. }
  procedure FrameRect(const Rect: TRect; const Colors: TColor4;
   Effect: TBlendingEffect = beNormal); overload;

  { Draws horizontal line using the specified coordinates and filled with
    two color gradient. This primitive uses a filled shape and not line
    primitive for pixel-perfect mapping. }
  procedure HorizLine(Left, Top, Width: Single; Color1, Color2: Cardinal;
   Effect: TBlendingEffect = beNormal); overload;

  { Draws horizontal line using the specified coordinates and filled with
    solid color. This primitive uses a filled shape and not line primitive for
    pixel-perfect mapping. }
  procedure HorizLine(Left, Top, Width: Single; Color: Cardinal;
   Effect: TBlendingEffect = beNormal); overload;

  { Draws vertical line using the specified coordinates and filled with
    two color gradient. This primitive uses a filled shape and not line
    primitive for pixel-perfect mapping. }
  procedure VertLine(Left, Top, Height: Single; Color1, Color2: Cardinal;
   Effect: TBlendingEffect = beNormal); overload;

  { Draws vertical line using the specified coordinates and filled with
    solid color. This primitive uses a filled shape and not line primitive for
    pixel-perfect mapping. }
  procedure VertLine(Left, Top, Height: Single; Color: Cardinal;
   Effect: TBlendingEffect = beNormal); overload;

  //.........................................................................
  { Draws hexagon where vertices are spaced 0.5 pixels apart from its center
    (so diameter is 1) in all directions, multiplied by the given matrix and
    filled with gradient of six colors at the corresponding vertices. The
    size, position and rotation of hexagon can be given using one or a
    combination of several 3x3 matrices multiplied together. }
  procedure FillHexagon(const Mtx: TMatrix3; c1, c2, c3, c4, c5, c6: Cardinal;
   Effect: TBlendingEffect = beNormal);

  { Draws lines between each vertex in hexagon. The vertices are spaced 0.5
    pixels apart from its center (so diameter is 1) in all directions,
    multiplied by the given matrix and filled with gradient of six colors at
    the corresponding vertices. The size, position and rotation of hexagon can
    be given using one or a combination of several 3x3 matrices multiplied
    together. }
  procedure FrameHexagon(const Mtx: TMatrix3; Color: Cardinal);

  //.........................................................................
  { Draws filled arc at the given position and radius. The arc begins at
    @code(InitPhi) and ends at @code(EndPhi) (in radians), subdivided into
    a number of triangles specified in @code(Steps). The arc's shape is
    filled with 4-color gradient. }
  procedure FillArc(const Pos, Radius: TPoint2; InitPhi, EndPhi: Single;
   Steps: Integer; const Colors: TColor4;
    Effect: TBlendingEffect = beNormal); overload;

  { Draws filled arc at the given coordinates and radius. The arc begins at
    @code(InitPhi) and ends at @code(EndPhi) (in radians), subdivided into
    a number of triangles specified in @code(Steps). The arc's shape is
    filled with 4-color gradient. }
  procedure FillArc(x, y, Radius, InitPhi, EndPhi: Single; Steps: Integer;
   const Colors: TColor4; Effect: TBlendingEffect = beNormal); overload;

  //.........................................................................
  { Draws filled ellipse at the given position and radius. The ellipse is
    subdivided into a number of triangles specified in @code(Steps).
    The shape of ellipse is filled with 4-color gradient. }
  procedure FillEllipse(const Pos, Radius: TPoint2; Steps: Integer;
   const Colors: TColor4; Effect: TBlendingEffect = beNormal);

  { Draws filled circle at the given position and radius. The circle is
    subdivided into a number of triangles specified in @code(Steps).
    The shape of circle is filled with 4-color gradient. }
  procedure FillCircle(x, y, Radius: Single; Steps: Integer;
   const Colors: TColor4; Effect: TBlendingEffect = beNormal);

  //.........................................................................
  { Draws filled ribbon at the given position between inner and outer radiuses.
    The ribbon begins at @code(InitPhi) and ends at @code(EndPhi) (in radians),
    subdivided into a number of triangles specified in @code(Steps). The
    ribbons's shape is filled with 4-color gradient. }
  procedure FillRibbon(const Pos, InRadius, OutRadius: TPoint2; InitPhi,
   EndPhi: Single; Steps: Integer; const Colors: TColor4;
   Effect: TBlendingEffect = beNormal); overload;

  { Draws filled ribbon at the given position between inner and outer radiuses.
    The ribbon begins at @code(InitPhi) and ends at @code(EndPhi) (in radians),
    subdivided into a number of triangles specified in @code(Steps). The
    ribbons's shape is filled with continuous gradient set by three pairs of
    inner and outer colors. }
  procedure FillRibbon(const Pos, InRadius, OutRadius: TPoint2; InitPhi,
   EndPhi: Single; Steps: Integer; InColor1, InColor2, InColor3, OutColor1,
   OutColor2, OutColor3: Cardinal;
   Effect: TBlendingEffect = beNormal); overload;

  //.........................................................................
  { Draws a filled rectangle at the given position and size with a hole (in
    form of ellipse) inside at the given center and radius. The quality of the
    hole is defined by the value of @code(Steps) in number of subdivisions.
    This entire shape is filled with gradient starting from outer color at the
    edges of rectangle and inner color ending at the edge of hole. This shape
    can be particularly useful for highlighting items on the screen by
    darkening the entire area except the one inside the hole. }
  procedure QuadHole(const Pos, Size, Center, Radius: TPoint2; OutColor,
   InColor: Cardinal; Steps: Integer;
   Effect: TBlendingEffect = beNormal); overload;

  //.........................................................................
  { Defines the specified texture to be used in next call to @link(TexMap).
    The coordinates inside the texture are defined in logical units in range
    of [0..1]. }
  procedure UseTexture(const Texture: TAsphyreCustomTexture;
   const Mapping: TPoint4); virtual; abstract;

  { Defines the specified texture to be used in next call to @link(TexMap).
    The coordinates inside the texture are defined in pixels using
    floating-point coordinates. }
  procedure UseTexturePx(const Texture: TAsphyreCustomTexture;
   const Mapping: TPoint4);

  //.........................................................................
  { Defines the specified image with one of its textures to be used in next
    call to @link(TexMap). The coordinates inside the texture are defined in
    logical units in range of [0..1]. }
  procedure UseImage(const Image: TAsphyreImage; const Mapping: TPoint4;
   TextureNo: Integer = 0);

  //.........................................................................
  { Defines the specified image with one of its patterns to be used in next
    call to @link(TexMap). If the image has none or just one pattern, the
    value of @code(Pattern) should be set to zero; in this case, the entire
    texture is used instead of pattern. }
  procedure UseImagePt(const Image: TAsphyreImage; Pattern: Integer = 0); overload;

  { Defines the specified image with one of its patterns to be used in next
    call to @link(TexMap). Only part of pattern is used for rendering defined
    by the given coordinates; these coordinates can also be mirrored
    horizontally and/or flipped vertically, if needed. If the image has no or
    just one pattern, the value of @code(Pattern) should be set to zero; in
    this case, the entire texture is used instead of pattern. }
  procedure UseImagePt(const Image: TAsphyreImage; Pattern: Integer;
   const SrcRect: TRect; Mirror: Boolean = False;
   Flip: Boolean = False); overload;

  //.........................................................................
  { Defines the specified image with one of its textures to be used in next
    call to @link(TexMap). The coordinates inside the texture are defined in
    pixels using floating-point coordinates. }
  procedure UseImagePx(const Image: TAsphyreImage; const Mapping: TPoint4;
   TextureNo: Integer = 0);

  //.........................................................................
  { Draws textured rectangle at the given vertices and multiplied by the
    specified 4-color gradient. The texture must be set prior to this call by
    one of @code(UseTexture[...]) or @code(UseImage[...]) calls. For every call
    of @code(TexMap) there must be a corresponding @code(UseTexture[...]) or
    @code(UseImage[...]) call to specify the image or texture. All pixels of
    the rendered texture are multiplied by the gradient color before applying
    alpha-blending. If the texture has no alpha-channel present, alpha value
    of the gradient will be used instead. }
  procedure TexMap(const Points: TPoint4; const Colors: TColor4;
   Effect: TBlendingEffect = beNormal); virtual; abstract;

  //.........................................................................
  { Flushes the canvas cache and presents the pending primitives on the
    screen or render target. This can be useful to make sure that nothing
    remains in canvas cache before starting to draw, for instance, a 3D scene. }
  procedure Flush(); virtual; abstract;

  { Resets all the states necessary for canvas operation. This can be useful
    when custom state changes have been made (for instance, in a 3D scene) so
    to restore the canvas to its working condition this method should be
    called. }
  procedure ResetStates(); virtual;

  {@exclude}constructor Create(); virtual;
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Events.Types, Asphyre.Events;

//---------------------------------------------------------------------------
const
 MinAllowedCanvasScale = 0.001;

//---------------------------------------------------------------------------
procedure SwapFloat(var Value1, Value2: Single);
var
 Temp: Single;
begin
 Temp  := Value1;
 Value1:= Value2;
 Value2:= Temp;
end;

//---------------------------------------------------------------------------
constructor TAsphyreCanvas.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 FCacheStall:= 0;

 FDeviceScale:= 1.0;
 FExternalScale:= 1.0;
 UpdateInternalScale();

 EventDeviceCreate.Subscribe(ClassName, OnDeviceCreate);
 EventDeviceDestroy.Subscribe(ClassName, OnDeviceDestroy);

 EventDeviceReset.Subscribe(ClassName, OnDeviceReset);
 EventDeviceLost.Subscribe(ClassName, OnDeviceLost);

 EventBeginScene.Subscribe(ClassName, OnBeginScene);
 EventEndScene.Subscribe(ClassName, OnEndScene);

 InitHexLookup();
end;

//---------------------------------------------------------------------------
destructor TAsphyreCanvas.Destroy();
begin
 Dec(AsphyreClassInstances);

 EventProviders.Unsubscribe(ClassName);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.InitHexLookup();
const
 HexDelta = 1.154700538;
 AngleInc = Pi / 6.0;
 AngleMul = 2.0 * Pi / 6.0;
var
 i: Integer;
 Angle: Single;
begin
 for i:= 0 to 5 do
  begin
   Angle:= i * AngleMul + AngleInc;

   HexLookup[i].x:=  Cos(Angle) * HexDelta;
   HexLookup[i].y:= -Sin(Angle) * HexDelta;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.UpdateInternalScale();
begin
 InternalScale:= FDeviceScale / FExternalScale;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.SetDeviceScale(const Value: Single);
var
 NewValue: Single;
begin
 NewValue:= Value;
 if (NewValue < MinAllowedCanvasScale) then NewValue:= MinAllowedCanvasScale;

 if (NewValue <> FDeviceScale) then
  begin
   Flush();

   FDeviceScale:= NewValue;
   UpdateInternalScale();
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.SetExternalScale(const Value: Single);
var
 NewValue: Single;
begin
 NewValue:= Value;
 if (NewValue < MinAllowedCanvasScale) then NewValue:= MinAllowedCanvasScale;

 if (NewValue <> FExternalScale) then
  begin
   Flush();

   FExternalScale:= NewValue;
   UpdateInternalScale();
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.OnDeviceCreate(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
var
 Success: Boolean;
begin
 Success:= HandleDeviceCreate();

 if (Assigned(Param)) then
  PBoolean(Param)^:= (PBoolean(Param)^)and(Success);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.OnDeviceDestroy(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 HandleDeviceDestroy();
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.OnDeviceReset(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
var
 Success: Boolean;
begin
 Success:= HandleDeviceReset();

 if (Assigned(Param)) then
  PBoolean(Param)^:= (PBoolean(Param)^)and(Success);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.OnDeviceLost(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 HandleDeviceLost();
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.OnBeginScene(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 FCacheStall:= 0;

 HandleBeginScene();
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.OnEndScene(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 HandleEndScene();
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.ResetStates();
begin
 // no code
end;

//---------------------------------------------------------------------------
function TAsphyreCanvas.GetClipRect(): TRect;
var
 x, y, Width, Height: Integer;
begin
 GetViewport(x, y, Width, Height);

 Result:= Bounds(Round(x / InternalScale), Round(y / InternalScale),
  Round(Width / InternalScale), Round(Height / InternalScale));
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.SetClipRect(const Value: TRect);
begin
 SetViewport(Round(Value.Left * InternalScale),
  Round(Value.Top * InternalScale),
  Round((Value.Right - Value.Left) * InternalScale),
  Round((Value.Bottom - Value.Top) * InternalScale));
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.UseTexturePx(const Texture: TAsphyreCustomTexture;
 const Mapping: TPoint4);
var
 Points: TPoint4;
begin
 if (Assigned(Texture)) then
  begin
   Points[0]:= Texture.PixelToLogical(Mapping[0]);
   Points[1]:= Texture.PixelToLogical(Mapping[1]);
   Points[2]:= Texture.PixelToLogical(Mapping[2]);
   Points[3]:= Texture.PixelToLogical(Mapping[3]);

   UseTexture(Texture, Points);
  end else UseTexture(Texture, TexFull4);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.UseImage(const Image: TAsphyreImage; const Mapping: TPoint4;
 TextureNo: Integer);
var
 Texture: TAsphyreCustomTexture;
begin
 if (Assigned(Image)) then
  Texture:= Image.Texture[TextureNo]
   else Texture:= nil;

 UseTexture(Texture, Mapping);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.UseImagePx(const Image: TAsphyreImage;
 const Mapping: TPoint4; TextureNo: Integer);
var
 Texture: TAsphyreCustomTexture;
begin
 if (Assigned(Image)) then
  Texture:= Image.Texture[TextureNo]
   else Texture:= nil;

 UseTexturePx(Texture, Mapping);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.UseImagePt(const Image: TAsphyreImage; Pattern: Integer);
var
 Mapping  : TPoint4;
 TextureNo: Integer;
begin
 TextureNo:= -1;

 if (Assigned(Image)) then
  TextureNo:= Image.RetrieveTex(Pattern, Mapping);

 UseImage(Image, Mapping, TextureNo);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.UseImagePt(const Image: TAsphyreImage; Pattern: Integer;
 const SrcRect: TRect; Mirror, Flip: Boolean);
var
 Mapping  : TPoint4;
 TextureNo: Integer;
begin
 TextureNo:= -1;

 if (Assigned(Image)) then
  TextureNo:= Image.RetrieveTex(Pattern, SrcRect, Mirror, Flip, Mapping);

 UseImage(Image, Mapping, TextureNo);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.NextDrawCall();
begin
 Inc(FCacheStall);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.PutPixel(x, y: Single; Color: Cardinal);
begin
 PutPixel(Point2(x, y), Color);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FillArc(x, y, Radius, InitPhi, EndPhi: Single;
 Steps: Integer; const Colors: TColor4; Effect: TBlendingEffect);
begin
 FillArc(Point2(x, y), Point2(Radius, Radius), InitPhi, EndPhi, Steps, Colors,
  Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FillEllipse(const Pos, Radius: TPoint2;
 Steps: Integer; const Colors: TColor4; Effect: TBlendingEffect);
begin
 FillArc(Pos, Radius, 0, Pi * 2.0, Steps, Colors, Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FillCircle(x, y, Radius: Single;
 Steps: Integer; const Colors: TColor4; Effect: TBlendingEffect);
begin
 FillArc(Point2(x, y), Point2(Radius, Radius), 0, Pi * 2.0, Steps, Colors,
  Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FillRect(const Rect: TRect; const Colors: TColor4;
 Effect: TBlendingEffect = beNormal);
begin
 FillQuad(pRect4(Rect), Colors, Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FillRect(const Rect: TRect; Color: Cardinal;
 Effect: TBlendingEffect = beNormal);
begin
 FillRect(Rect, cColor4(Color), Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FillRect(Left, Top, Width, Height: Integer;
 Color: Cardinal; Effect: TBlendingEffect = beNormal);
begin
 FillRect(Bounds(Left, Top, Width, Height), Color, Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.WuHoriz(x1, y1, x2, y2: Single; Color1,
 Color2: Cardinal);
var
 Color: Cardinal;
 xd, yd, Grad, yf: Single;
 xEnd, x, ix1, ix2, iy1, iy2: Integer;
 yEnd, xGap, Alpha1, Alpha2, Alpha, AlphaInc: Single;
begin
 xd:= x2 - x1;
 yd:= y2 - y1;

 if (x1 > x2) then
  begin
   SwapFloat(x1, x2);
   SwapFloat(y1, y2);
   xd:= x2 - x1;
   yd:= y2 - y1;
  end;

 Grad:= yd / xd;

 // End Point 1
 xEnd:= Trunc(x1 + 0.5);
 yEnd:= y1 + Grad * (xEnd - x1);

 xGap:= 1.0 - Frac(x1 + 0.5);

 ix1:= xEnd;
 iy1:= Trunc(yEnd);

 Alpha1:= (1.0 - Frac(yEnd)) * xGap;
 Alpha2:= Frac(yEnd) * xGap;

 PutPixel(Point2(ix1, iy1), MulPixelAlpha(Color1, Alpha1));
 PutPixel(Point2(ix1, iy1 + 1.0), MulPixelAlpha(Color1, Alpha2));

 yf:= yEnd + Grad;

 // End Point 2
 xEnd:= Trunc(x2 + 0.5);
 yEnd:= y2 + Grad * (xEnd - x2);

 xGap:= 1.0 - Frac(x2 + 0.5);

 ix2:= xEnd;
 iy2:= Trunc(yEnd);

 Alpha1:= (1.0 - Frac(yEnd)) * xGap;
 Alpha2:= Frac(yEnd) * xGap;

 PutPixel(Point2(ix2, iy2), MulPixelAlpha(Color2, Alpha1));
 PutPixel(Point2(ix2, iy2 + 1.0), MulPixelAlpha(Color2, Alpha2));

 Alpha:= 0.0;
 AlphaInc:= 1.0 / xd;

 // Main Loop
 for x:= ix1 + 1 to ix2 - 1 do
  begin
   Alpha1:= 1.0 - Frac(yf);
   Alpha2:= Frac(yf);

   Color:= LerpPixels(Color1, Color2, Alpha);

   PutPixel(Point2(x, Int(yf)), MulPixelAlpha(Color, Alpha1));
   PutPixel(Point2(x, Int(yf) + 1.0), MulPixelAlpha(Color, Alpha2));

   yf:= yf + Grad;
   Alpha:= Alpha + AlphaInc;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.WuVert(x1, y1, x2, y2: Single; Color1,
 Color2: Cardinal);
var
 Color: Cardinal;
 xd, yd, Grad, xf: Single;
 yEnd, y, ix1, ix2, iy1, iy2: Integer;
 xEnd, yGap, Alpha1, Alpha2, Alpha, AlphaInc: Single;
begin
 xd:= x2 - x1;
 yd:= y2 - y1;

 if (y1 > y2) then
  begin
   SwapFloat(x1, x2);
   SwapFloat(y1, y2);
   xd:= x2 - x1;
   yd:= y2 - y1;
  end;

 Grad:= xd / yd;

 // End Point 1
 yEnd:= Trunc(y1 + 0.5);
 xEnd:= x1 + Grad * (yEnd - y1);

 yGap:= 1.0 - Frac(y1 + 0.5);

 ix1:= Trunc(xEnd);
 iy1:= yEnd;

 Alpha1:= (1.0 - Frac(xEnd)) * yGap;
 Alpha2:= Frac(xEnd) * yGap;

 PutPixel(Point2(ix1, iy1), MulPixelAlpha(Color1, Alpha1));
 PutPixel(Point2(ix1 + 1.0, iy1), MulPixelAlpha(Color1, Alpha2));

 xf:= xEnd + Grad;

 // End Point 2
 yEnd:= Trunc(y2 + 0.5);
 xEnd:= x2 + Grad * (yEnd - y2);

 yGap:= 1.0 - Frac(y2 + 0.5);

 ix2:= Trunc(xEnd);
 iy2:= yEnd;

 Alpha1:= (1.0 - Frac(xEnd)) * yGap;
 Alpha2:= Frac(xEnd) * yGap;

 PutPixel(Point2(ix2, iy2), MulPixelAlpha(Color2, Alpha1));
 PutPixel(Point2(ix2 + 1.0, iy2), MulPixelAlpha(Color2, Alpha2));

 Alpha:= 0.0;
 AlphaInc:= 1.0 / yd;

 // Main Loop
 for y:= iy1 + 1 to iy2 - 1 do
  begin
   Alpha1:= 1.0 - Frac(xf);
   Alpha2:= Frac(xf);

   Color:= LerpPixels(Color1, Color2, Alpha);

   PutPixel(Point2(Int(xf), y), MulPixelAlpha(Color, Alpha1));
   PutPixel(Point2(Int(xf) + 1.0, y), MulPixelAlpha(Color, Alpha2));

   xf:= xf + Grad;
   Alpha:= Alpha + AlphaInc;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.WuLine(Src, Dest: TPoint2; Color1, Color2: Cardinal);
begin
 if (Abs(Dest.x - Src.x) > Abs(Dest.y - Src.y)) then
  WuHoriz(Src.x, Src.y, Dest.x, Dest.y, Color1, Color2)
   else WuVert(Src.x, Src.y, Dest.x, Dest.y, Color1, Color2)
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.Ellipse(const Pos, Radius: TPoint2; Steps: Integer;
 Color: Cardinal);
const
 Pi2 = Pi * 2.0;
var
 i: Integer;
 Vertex, PreVertex: TPoint2;
 Alpha: Single;
begin
 Vertex:= ZeroVec2;

 for i:= 0 to Steps do
  begin
   Alpha:= i * Pi2 / Steps;

   PreVertex:= Vertex;
   Vertex.x:= Round(Pos.x + Cos(Alpha) * Radius.x);
   Vertex.y:= Round(Pos.y - Sin(Alpha) * Radius.y);

   if (i > 0) then
    WuLine(PreVertex, Vertex, Color, Color);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.Circle(const Pos: TPoint2; Radius: Single;
 Steps: Integer; Color: Cardinal);
begin
 Ellipse(Pos, Point2(Radius, Radius), Steps, Color);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FrameRect(const Points: TPoint4;
 const Colors: TColor4; Effect: TBlendingEffect);
const
 Indices: array[0..23] of LongInt = (0, 1, 4, 4, 1, 5, 1, 2, 5, 5, 2, 6, 2, 3,
  6, 6, 3, 7, 3, 0, 7, 7, 0, 4);
var
 Vertices: array[0..7] of TPoint2;
 VColors : array[0..7] of LongWord;
 i: Integer;
begin
 for i:= 0 to 3 do
  begin
   Vertices[i]:= Points[i];

   VColors[i]:= Colors[i];
   VColors[4 + i]:= Colors[i];
  end;

 Vertices[4]:= Point2(Points[0].x + 1.0, Points[0].y + 1.0);
 Vertices[5]:= Point2(Points[1].x - 1.0, Points[1].y + 1.0);
 Vertices[6]:= Point2(Points[2].x - 1.0, Points[2].y - 1.0);
 Vertices[7]:= Point2(Points[3].x + 1.0, Points[3].y - 1.0);

 DrawIndexedTriangles(@Vertices[0], @VColors[0], @Indices[0], 8, 8);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FrameRect(const Rect: TRect; const Colors: TColor4;
 Effect: TBlendingEffect);
begin
 FrameRect(pRect4(Rect), Colors, Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.HorizLine(Left, Top, Width: Single; Color1,
 Color2: Cardinal; Effect: TBlendingEffect);
begin
 FillQuad(pBounds4(Left, Top, Width, 1.0), cColor4(Color1, Color2, Color2,
  Color1), Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.HorizLine(Left, Top, Width: Single;
 Color: Cardinal; Effect: TBlendingEffect);
begin
 HorizLine(Left, Top, Width, Color, Color, Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.VertLine(Left, Top, Height: Single; Color1,
 Color2: Cardinal; Effect: TBlendingEffect);
begin
 FillQuad(pBounds4(Left, Top, 1.0, Height), cColor4(Color1, Color1, Color2,
  Color2), Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.VertLine(Left, Top, Height: Single; Color: Cardinal;
 Effect: TBlendingEffect);
begin
 VertLine(Left, Top, Height, Color, Color, Effect);
end;

//---------------------------------------------------------------------------
function TAsphyreCanvas.HandleDeviceCreate(): Boolean;
begin
 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.HandleDeviceDestroy();
begin
 // no code
end;

//---------------------------------------------------------------------------
function TAsphyreCanvas.HandleDeviceReset(): Boolean;
begin
 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.HandleDeviceLost();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FillTri(const p1, p2, p3: TPoint2; c1, c2,
 c3: Cardinal; Effect: TBlendingEffect);
const
 Indices: packed array[0..2] of LongInt = (0, 1, 2);
var
 Vertices: packed array[0..2] of TPoint2;
 Colors  : packed array[0..2] of LongWord;
begin
 Vertices[0]:= p1;
 Vertices[1]:= p2;
 Vertices[2]:= p3;

 Colors[0]:= c1;
 Colors[1]:= c2;
 Colors[2]:= c3;

 DrawIndexedTriangles(@Vertices[0], @Colors[0], @Indices[0], 3, 1, Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FillQuad(const Points: TPoint4; const Colors: TColor4;
 Effect: TBlendingEffect);
const
 Indices: packed array[0..5] of LongInt = (2, 0, 1, 3, 2, 1);
var
 Vertices: packed array[0..3] of TPoint2;
 VColors : packed array[0..3] of LongWord;
begin
 Vertices[0]:= Points[0];
 Vertices[1]:= Points[1];
 Vertices[2]:= Points[3];
 Vertices[3]:= Points[2];

 VColors[0]:= Colors[0];
 VColors[1]:= Colors[1];
 VColors[2]:= Colors[3];
 VColors[3]:= Colors[2];

 DrawIndexedTriangles(@Vertices[0], @VColors[0], @Indices[0], 4, 2, Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FillRibbon(const Pos, InRadius, OutRadius: TPoint2;
 InitPhi, EndPhi: Single; Steps: Integer; const Colors: TColor4;
 Effect: TBlendingEffect);
var
 Vertices: packed array of TPoint2;
 VColors : packed array of LongWord;
 Indices : packed array of LongInt;
 Pt1, Pt2: TPoint2;
 i: Integer;
 Alpha: Single;
 xAlpha, yAlpha: Integer;
 NoVertex, NoIndex: Integer;
begin
 if (Steps < 1) then Exit;

 // (1) Find (x, y) margins for color interpolation.
 Pt1:= Pos - OutRadius;
 Pt2:= Pos + OutRadius;

 // (2) Specify the size of vertex/index arrays.
 SetLength(Vertices, (Steps * 2) + 2);
 SetLength(VColors, Length(Vertices));
 SetLength(Indices, Steps * 6);

 NoVertex:= 0;

 // (3) Create first inner vertex
 Vertices[NoVertex].x:= Pos.x + Cos(InitPhi) * InRadius.x;
 Vertices[NoVertex].y:= Pos.y - Sin(InitPhi) * InRadius.y;
 // -> color interpolation values
 xAlpha:= Round((Vertices[NoVertex].x - Pt1.x) * 255.0 / (Pt2.x - Pt1.x));
 yAlpha:= Round((Vertices[NoVertex].y - Pt1.y) * 255.0 / (Pt2.y - Pt1.y));
 // -> interpolate the color
 VColors[NoVertex]:= BlendPixels(BlendPixels(Colors[0], Colors[1], xAlpha),
  BlendPixels(Colors[3], Colors[2], xAlpha), yAlpha);

 Inc(NoVertex);

 // (4) Create first outer vertex
 Vertices[NoVertex].x:= Pos.x + Cos(InitPhi) * OutRadius.x;
 Vertices[NoVertex].y:= Pos.y - Sin(InitPhi) * OutRadius.y;
 // -> color interpolation values
 xAlpha:= Round((Vertices[NoVertex].x - Pt1.x) * 255.0 / (Pt2.x - Pt1.x));
 yAlpha:= Round((Vertices[NoVertex].y - Pt1.y) * 255.0 / (Pt2.y - Pt1.y));
 // -> interpolate the color
 VColors[NoVertex]:= BlendPixels(BlendPixels(Colors[0], Colors[1], xAlpha),
  BlendPixels(Colors[3], Colors[2], xAlpha), yAlpha);

 Inc(NoVertex);

 // (5) Insert the rest of vertices
 for i:= 1 to Steps do
  begin
   // 5a. Insert inner vertex
   // -> angular position
   Alpha:= (i * (EndPhi - InitPhi) / Steps) + InitPhi;
   // -> vertex position
   Vertices[NoVertex].x:= Pos.x + Cos(Alpha) * InRadius.x;
   Vertices[NoVertex].y:= Pos.y - Sin(Alpha) * InRadius.y;
   // -> color interpolation values
   xAlpha:= Round((Vertices[NoVertex].x - Pt1.x) * 255.0 / (Pt2.x - Pt1.x));
   yAlpha:= Round((Vertices[NoVertex].y - Pt1.y) * 255.0 / (Pt2.y - Pt1.y));
   // -> interpolate the color
   VColors[NoVertex]:= BlendPixels(BlendPixels(Colors[0], Colors[1], xAlpha),
    BlendPixels(Colors[3], Colors[2], xAlpha), yAlpha);

   Inc(NoVertex);

   // 5b. Insert outer vertex
   // -> angular position
   Alpha:= (i * (EndPhi - InitPhi) / Steps) + InitPhi;
   // -> vertex position
   Vertices[NoVertex].x:= Pos.x + Cos(Alpha) * OutRadius.x;
   Vertices[NoVertex].y:= Pos.y - Sin(Alpha) * OutRadius.y;
   // -> color interpolation values
   xAlpha:= Round((Vertices[NoVertex].x - Pt1.x) * 255.0 / (Pt2.x - Pt1.x));
   yAlpha:= Round((Vertices[NoVertex].y - Pt1.y) * 255.0 / (Pt2.y - Pt1.y));
   // -> interpolate the color
   VColors[NoVertex]:= BlendPixels(BlendPixels(Colors[0], Colors[1], xAlpha),
    BlendPixels(Colors[3], Colors[2], xAlpha), yAlpha);

   Inc(NoVertex);
  end;

 // (6) Insert indexes
 NoIndex:= 0;
 for i:= 0 to Steps - 1 do
  begin
   Indices[(i * 6) + 0]:= NoIndex;
   Indices[(i * 6) + 1]:= NoIndex + 1;
   Indices[(i * 6) + 2]:= NoIndex + 2;

   Indices[(i * 6) + 3]:= NoIndex + 1;
   Indices[(i * 6) + 4]:= NoIndex + 3;
   Indices[(i * 6) + 5]:= NoIndex + 2;

   Inc(NoIndex, 2);
  end;

 DrawIndexedTriangles(@Vertices[0], @VColors[0], @Indices[0], Length(Vertices),
  Steps * 2, Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FillRibbon(const Pos, InRadius, OutRadius: TPoint2;
 InitPhi, EndPhi: Single; Steps: Integer; InColor1, InColor2, InColor3,
 OutColor1, OutColor2, OutColor3: Cardinal; Effect: TBlendingEffect);
var
 Vertices: packed array of TPoint2;
 VColors : packed array of LongWord;
 Indices : packed array of LongInt;
 InColor, OutColor: Cardinal;
 i: Integer;
 Alpha, Theta: Single;
 NoVertex, NoIndex: Integer;
begin
 if (Steps < 1) then Exit;

 // (1) Specify the size of vertex/index arrays.
 SetLength(Vertices, (Steps * 2) + 2);
 SetLength(VColors, Length(Vertices));
 SetLength(Indices, Steps * 6);

 NoVertex:= 0;

 // (2) Create first inner vertex
 Vertices[NoVertex].x:= Pos.x + Cos(InitPhi) * InRadius.x;
 Vertices[NoVertex].y:= Pos.y - Sin(InitPhi) * InRadius.y;
 VColors[NoVertex]   := InColor1;
 Inc(NoVertex);

 // (3) Create first outer vertex
 Vertices[NoVertex].x:= Pos.x + Cos(InitPhi) * OutRadius.x;
 Vertices[NoVertex].y:= Pos.y - Sin(InitPhi) * OutRadius.y;
 VColors[NoVertex]   := OutColor1;
 Inc(NoVertex);

 // (4) Insert the rest of vertices
 for i:= 1 to Steps do
  begin
   Theta:= i / Steps;
   if (Theta < 0.5) then
    begin
     Theta:= 2.0 * Theta;

     InColor := LerpPixels(InColor1, InColor2, Theta);
     OutColor:= LerpPixels(OutColor1, OutColor2, Theta);
    end else
    begin
     Theta:= (Theta - 0.5) * 2.0;

     InColor := LerpPixels(InColor2, InColor3, Theta);
     OutColor:= LerpPixels(OutColor2, OutColor3, Theta);
    end;

   // 4a. Insert inner vertex
   // -> angular position
   Alpha:= (i * (EndPhi - InitPhi) / Steps) + InitPhi;
   // -> vertex position
   Vertices[NoVertex].x:= Pos.x + Cos(Alpha) * InRadius.x;
   Vertices[NoVertex].y:= Pos.y - Sin(Alpha) * InRadius.y;
   VColors[NoVertex]   := InColor;
   Inc(NoVertex);

   // 4b. Insert outer vertex
   // -> angular position
   Alpha:= (i * (EndPhi - InitPhi) / Steps) + InitPhi;
   // -> vertex position
   Vertices[NoVertex].x:= Pos.x + Cos(Alpha) * OutRadius.x;
   Vertices[NoVertex].y:= Pos.y - Sin(Alpha) * OutRadius.y;
   VColors[NoVertex]   := OutColor;
   Inc(NoVertex);
  end;

 // (5) Insert indexes
 NoIndex:= 0;
 for i:= 0 to Steps - 1 do
  begin
   Indices[(i * 6) + 0]:= NoIndex;
   Indices[(i * 6) + 1]:= NoIndex + 1;
   Indices[(i * 6) + 2]:= NoIndex + 2;

   Indices[(i * 6) + 3]:= NoIndex + 1;
   Indices[(i * 6) + 4]:= NoIndex + 3;
   Indices[(i * 6) + 5]:= NoIndex + 2;

   Inc(NoIndex, 2);
  end;

 DrawIndexedTriangles(@Vertices[0], @VColors[0], @Indices[0], Length(Vertices),
  Steps * 2, Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FillArc(const Pos, Radius: TPoint2; InitPhi,
 EndPhi: Single; Steps: Integer; const Colors: TColor4;
 Effect: TBlendingEffect);
var
 Vertices: packed array of TPoint2;
 VColors : packed array of LongWord;
 Indices : packed array of LongInt;
 Pt1, Pt2: TPoint2;
 i: Integer;
 Alpha: Single;
 xAlpha, yAlpha: Integer;
 NoVertex: Integer;
begin
 if (Steps < 1) then Exit;

 // (1) Find (x, y) margins for color interpolation.
 Pt1:= Pos - Radius;
 Pt2:= Pos + Radius;

 // (2) Before doing anything else, check cache availability.
 SetLength(Vertices, Steps + 2);
 SetLength(VColors, Length(Vertices));
 SetLength(Indices, Steps * 3);

 NoVertex:= 0;

 // (3) Insert initial vertex placed at the arc's center
 Vertices[NoVertex]:= Pos;

 VColors[NoVertex]:= AvgFourPixels(Colors[0], Colors[1], Colors[2], Colors[3]);
 Inc(NoVertex);

 // (5) Insert the rest of vertices
 for i:= 0 to Steps - 1 do
  begin
   // initial and final angles for this vertex
   Alpha:= (i * (EndPhi - InitPhi) / Steps) + InitPhi;

   // determine second and third points of the processed vertex
   Vertices[NoVertex].x:= Pos.x + Cos(Alpha) * Radius.x;
   Vertices[NoVertex].y:= Pos.y - Sin(Alpha) * Radius.y;

   // find color interpolation values
   xAlpha:= Round((Vertices[NoVertex].x - Pt1.x) * 255.0 / (Pt2.x - Pt1.x));
   yAlpha:= Round((Vertices[NoVertex].y - Pt1.y) * 255.0 / (Pt2.y - Pt1.y));

   VColors[NoVertex]:= BlendPixels(BlendPixels(Colors[0], Colors[1], xAlpha),
    BlendPixels(Colors[3], Colors[2], xAlpha), yAlpha);

   // insert new index buffer entry
   Indices[(i * 3) + 0]:= 0;
   Indices[(i * 3) + 1]:= NoVertex;
   Indices[(i * 3) + 2]:= NoVertex + 1;

   Inc(NoVertex);
  end;

 // find the latest vertex to finish the arc
 Vertices[NoVertex].x:= Pos.x + Cos(EndPhi) * Radius.x;
 Vertices[NoVertex].y:= Pos.y - Sin(EndPhi) * Radius.y;

 // find color interpolation values
 xAlpha:= Round((Vertices[NoVertex].x - Pt1.x) * 255.0 / (Pt2.x - Pt1.x));
 yAlpha:= Round((Vertices[NoVertex].y - Pt1.y) * 255.0 / (Pt2.y - Pt1.y));

 VColors[NoVertex]:= BlendPixels(BlendPixels(Colors[0], Colors[1], xAlpha),
  BlendPixels(Colors[3], Colors[2], xAlpha), yAlpha);

 DrawIndexedTriangles(@Vertices[0], @VColors[0], @Indices[0], Length(Vertices),
  Steps, Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FillHexagon(const Mtx: TMatrix3; c1, c2, c3, c4, c5,
 c6: Cardinal; Effect: TBlendingEffect);
const
 Indices: packed array[0..17] of LongInt =
  (0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 5, 0, 5, 6, 0, 6, 1);
var
 Vertices: packed array[0..6] of TPoint2;
 VColors : packed array[0..6] of LongWord;
begin
 Vertices[0]:= ZeroVec2 * Mtx;
 VColors[0] := AvgSixPixels(c1, c2, c3, c4, c5, c6);

 Vertices[1]:= HexLookup[0] * Mtx;
 VColors[1] := c1;

 Vertices[2]:= HexLookup[1] * Mtx;
 VColors[2] := c2;

 Vertices[3]:= HexLookup[2] * Mtx;
 VColors[3] := c3;

 Vertices[4]:= HexLookup[3] * Mtx;
 VColors[4] := c4;

 Vertices[5]:= HexLookup[4] * Mtx;
 VColors[5] := c5;

 Vertices[6]:= HexLookup[5] * Mtx;
 VColors[6] := c6;

 DrawIndexedTriangles(@Vertices[0], @VColors[0], @Indices[0], 7, 6, Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.QuadHole(const Pos, Size, Center, Radius: TPoint2;
 OutColor, InColor: Cardinal; Steps: Integer; Effect: TBlendingEffect);
var
 Vertices: packed array of TPoint2;
 VtColors: packed array of LongWord;
 Indices : packed array of LongInt;
 Theta, Angle: Single;
 i, Base: Integer;
begin
 SetLength(Vertices, Steps * 2);
 SetLength(VtColors, Steps * 2);
 SetLength(Indices, (Steps - 1) * 6);

 for i:= 0 to Steps - 2 do
  begin
   Base:= i * 6;

   Indices[Base + 0]:= i;
   Indices[Base + 1]:= i + 1;
   Indices[Base + 2]:= Steps + i;

   Indices[Base + 3]:= i + 1;
   Indices[Base + 4]:= Steps + i + 1;
   Indices[Base + 5]:= Steps + i;
  end;

 for i:= 0 to Steps - 1 do
  begin
   Theta:= i / (Steps - 1);

   Vertices[i].x:= Pos.x + Theta * Size.x;
   Vertices[i].y:= Pos.y;
   VtColors[i]  := OutColor;

   Angle:= Pi * 0.25 + Pi * 0.5 - Theta * Pi * 0.5;

   Vertices[Steps + i].x:= Center.x + Cos(Angle) * Radius.x;
   Vertices[Steps + i].y:= Center.y - Sin(Angle) * Radius.y;
   VtColors[Steps + i]  := InColor;
  end;

 DrawIndexedTriangles(@Vertices[0], @VtColors[0], @Indices[0],
  Length(Vertices), Length(Indices) div 3, Effect);

 for i:= 0 to Steps - 1 do
  begin
   Theta:= i / (Steps - 1);

   Vertices[i].x:= Pos.x + Size.x;
   Vertices[i].y:= Pos.y + Theta * Size.y;
   VtColors[i]  := OutColor;

   Angle:= Pi * 0.25 - Theta * Pi * 0.5;

   Vertices[Steps + i].x:= Center.x + Cos(Angle) * Radius.x;
   Vertices[Steps + i].y:= Center.y - Sin(Angle) * Radius.y;
   VtColors[Steps + i]  := InColor;
  end;

 DrawIndexedTriangles(@Vertices[0], @VtColors[0], @Indices[0],
  Length(Vertices), Length(Indices) div 3, Effect);

 for i:= 0 to Steps - 1 do
  begin
   Theta:= i / (Steps - 1);

   Vertices[i].x:= Pos.x;
   Vertices[i].y:= Pos.y + Theta * Size.y;
   VtColors[i]  := OutColor;

   Angle:= Pi * 0.75 + Theta * Pi * 0.5;

   Vertices[Steps + i].x:= Center.x + Cos(Angle) * Radius.x;
   Vertices[Steps + i].y:= Center.y - Sin(Angle) * Radius.y;
   VtColors[Steps + i]  := InColor;
  end;

 DrawIndexedTriangles(@Vertices[0], @VtColors[0], @Indices[0],
  Length(Vertices), Length(Indices) div 3, Effect);

 for i:= 0 to Steps - 1 do
  begin
   Theta:= i / (Steps - 1);

   Vertices[i].x:= Pos.x + Theta * Size.x;
   Vertices[i].y:= Pos.y + Size.y;
   VtColors[i]  := OutColor;

   Angle:= Pi * 1.25 + Theta * Pi * 0.5;

   Vertices[Steps + i].x:= Center.x + Cos(Angle) * Radius.x;
   Vertices[Steps + i].y:= Center.y - Sin(Angle) * Radius.y;
   VtColors[Steps + i]  := InColor;
  end;

 DrawIndexedTriangles(@Vertices[0], @VtColors[0], @Indices[0],
  Length(Vertices), Length(Indices) div 3, Effect);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.FrameHexagon(const Mtx: TMatrix3;
 Color: Cardinal);
var
 i: Integer;
 Vertex, PreVertex: TPoint2;
begin
 Vertex:= ZeroVec2;

 for i:= 0 to 6 do
  begin
   PreVertex:= Vertex;
   Vertex:= HexLookup[i mod 6] * Mtx;

   if (i > 0) then
    WuLine(PreVertex, Vertex, Color, Color);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.WireQuad(const Points: TPoint4;
 const Colors: TColor4);
begin
 Line(Points[0], Points[1], Colors[0], Colors[1]);
 Line(Points[1], Points[2], Colors[1], Colors[2]);
 Line(Points[2], Points[3], Colors[2], Colors[3]);
 Line(Points[3], Points[0], Colors[3], Colors[0]);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.Line(const Src, Dest: TPoint2; Color: Cardinal);
begin
 Line(Src, Dest, Color, Color);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.Line(x1, y1, x2, y2: Single; Color: Cardinal);
begin
 Line(Point2(x1, y1), Point2(x2, y2), Color, Color);
end;

//---------------------------------------------------------------------------
procedure TAsphyreCanvas.LineArray(Points: PPoint2; Color: Cardinal;
 NoPoints: Integer);
var
 i: Integer;
 NextPt: PPoint2;
begin
 for i:= 0 to NoPoints - 2 do
  begin
   NextPt:= Points;
   Inc(NextPt);

   Line(Points^, NextPt^, Color, Color);

   Points:= NextPt;
  end;
end;

//---------------------------------------------------------------------------
end.


