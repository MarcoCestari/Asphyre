unit Asphyre.Types;
//---------------------------------------------------------------------------
// Asphyre types and definitions.
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
{< Essential types, constants and functions that work with colors, pixels and
   rectangles that are used throughout the entire framework. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.Types, System.Math, Asphyre.TypeDef, Asphyre.Math;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Asphyre Pixel Format'}

//---------------------------------------------------------------------------
type
{ This type is used to pass @link(TAsphyrePixelFormat) by reference. }
 PAsphyrePixelFormat = ^TAsphyrePixelFormat;

//---------------------------------------------------------------------------
{ Defines how individual pixels and their colors are encoded in the images and
  textures. The order of letters in the constants defines the order of the
  encoded components; R stands for Red, G for Green, B for Blue, A for Alpha,
  L for Luminance and X for Not Used (or discarded). Letters such as V and U
  define displacement for bump-mapped textures and the rest are
  miscellaneous. }
 TAsphyrePixelFormat = (

  { Unknown pixel format. It is usually returned when no valid pixel format is
    available. In some cases, it can be specified to indicate that the format
    should be selected by default or automatically. @br @br }
  apf_Unknown,

  { 24-bit RGB pixel format. This format can be used for storage and it is
    unsuitable for rendering both on @italic(DirectX) and
    @italic(OpenGL). @br @br }
  apf_R8G8B8,

  { 32-bit RGBA pixel format. The most commonly used pixel format for storing
    and loading textures and images. @br @br }
  apf_A8R8G8B8,

  { 32-bit RGB pixel format that has no alpha-channel. Should be used for
    images and textures that have no transparency information in them. @br @br }
  apf_X8R8G8B8,

  { 16-bit RGB pixel format. This format can be used as an alternative to
    A8R8G8B8 in cases where memory footprint is important at the expense
    of visual quality. @br @br }
  apf_R5G6B5,

  { 16-bit RGB pixel format with only 15 bits used for actual storage. This
    format was common on older hardware many years ago but today it is rarely
    used or even supported. @br @br }
  apf_X1R5G5B5,

  { 16-bit RGBA pixel format with one bit dedicated for alpha-channel. This
    format can be used for images where a transparency mask is used; that is,
    the pixel is either transparent or not, typical for those images where
    a single color is picked to be transparent. In Asphyre, there is no need
    for this format because @italic(AlphaTool) can be used to generate alpha
    channel for images with masked color, which then can be used with any other
    higher-quality format. @br @br }
  apf_A1R5G5B5,

  { 16-bit RGBA pixel format with 4 bits for each channel. This format can be
    used as a replacement for @italic(A8R8G8B8) format in cases where memory
    footprint is important at the expense of visual quality. @br @br }
  apf_A4R4G4B4,

  { 8-bit RGB pixel format. An extreme low-quality format useful only in
    special circumstances and mainly for storage. It is more commonly supported
    on ATI video cards than on Nvidia, being really scarce on newer
    hardware. @br @br }
  apf_R3G3B2,

  { 8-bit alpha pixel format. This format can be used as an alpha-channel
    format for applications that require low memory footprint and require
    transparency information only. Its usefulness, however, is severely
    limited because it is only supported only on newer video cards and when
    converted in hardware to @italic(A8R8G8B8), it has zero values for red,
    green and blue components; in other words, it is basically a black color
    with an alpha-channel. @br @br }
  apf_A8,

  { 16-bit RGBA pixel format with uneven bit distribution among the components.
    It is more supported on ATI video cards and can be rarely found on newer
    hardware. In many cases it is more useful to use @italic(A4R4G4B4)
    format. @br @br }
  apf_A8R3G3B2,

  { 16-bit RGB pixel format with 4 bits unused. It is basically
    @italic(A4R4G4B4) with alpha-channel discarded. This format is widely
    supported, but in typical applications it is more convenient to use
    @italic(R5G6B5) instead. @br @br }
  apf_X4R4G4B4,

  { 32-bit RGBA pixel format with 10 bits used for each component of red,
    green and blue, being a higher-quality variant of @italic(A8R8G8B8). It is
    more commonly supported on some video cards than its more practical cousin
    @italic(A2R10G10B10). @br @br }
  apf_A2B10G10R10,

  { 32-bit pixel format that has only green and red components 16 bits each.
    This format is more useful for shaders where only one or two components
    are needed but with extra resolution.. @br @br }
  apf_G16R16,

  { 32-bit RGBA pixel format with 10 bits used for each component of red,
    green and blue, with only 2 bits dedicated to alpha channel. @br @br }
  apf_A2R10G10B10,

  { 64-bit RGBA pixel format with each channel having 16 bits. @br @br }
  apf_A16B16G16R16,

  { 8-bit luminance pixel format. This format can be used for grayscale images
    and textures. @br @br }
  apf_L8,

  { 16-bit luminance pixel format. One of the best formats to be used with
    bitmap fonts, which is also widely supported. @br @br }
  apf_A8L8,

  { 8-bit luminance pixel format. This format can be used as a low quality
    replacement for @italic(A8L8) to represent bitmap fonts. @br @br }
  apf_A4L4,

  { 16-bit luminance pixel format that can be used to represent high-quality
    grayscale images and textures. @br @br }
  apf_L16,

  { 16-bit floating-point pixel format, which has only one component. This is
    useful in shaders either as a render target or as a data source. @br @br }
  apf_R16F,

  { 32-bit floating-point pixel format containing two components with 16 bits
    each. This can be used in shaders as a data source. @br @br }
  apf_G16R16F,

  { 64-bit floating-point RGBA pixel format with each component having 16
    bits. It can be used as a special purpose texture or a render target with
    shaders. @br @br }
  apf_A16B16G16R16F,

  { 32-bit floating-point pixel format, which has only one component. This
    format is typically used as render target for shadow mapping. @br @br }
  apf_R32F,

  { 64-bit floating-point pixel format containing two components with 32 bits
    each, mainly useful in shaders as a data source. @br @br }
  apf_G32R32F,

  { 128-bit floating-point RGBA pixel format with each component having 32
    bits. It can be used as a special purpose texture or a render target with
    shaders. @br @br }
  apf_A32B32G32R32F,

  { 32-bit BGRA pixel format. This is similar to @italic(A8R8G8B8) format but
    with red and blue components exchanged. @br @br }
  apf_A8B8G8R8,

  { 32-bit BGR pixel format that has no alpha-channel, similar to
    @italic(X8R8G8B8) but with red and blue components exchanged. @br @br }
  apf_X8B8G8R8,

  { 8-bit special purpose pixel format primarily targeted for storing bitmap
    fonts, having 5 bits for alpha-channel for improved transparency and only
    3 bits for luminance (in case the font has shadows in it). This can be
    particularly useful to save disk space but still conserve visual quality.
    Upon loading, this format is likely to be converted on the fly to
    @italic(A8L8), @italic(A4L4), @italic(A8R8G8B8) or
    @italic(A4R4G4B4). Alternatively, this format can be used natively on DX10+
    providers using special conversion in pixel shaders
    (see @italic(CompactFonts) example). @br @br }
  apf_A5L3,

  { 8-bit RGBA pixel format that was originally supported by OpenGL in earlier
    implementations. This format can significantly save disk space and memory
    consumption (if supported in hardware) but at the expense of very low
    visual quality. @br @br }
  apf_A2R2G2B2,

  { 32-bit special purpose RGBA pixel format that is only supported by Asphyre
    for storage. It provides double resolution for red, green and blue
    components up to 512 levels each with 32 different levels of transparency.
    This format can be used for system-level applications where additional
    image resolution is required for higher pixel processing accuracy. @br @br }
  apf_A5R9G9B9);

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Color, Point and Event Definitions'}

//---------------------------------------------------------------------------
{ This type is used to pass @link(TColor2) by reference. }
 PColor2 = ^TColor2;

//---------------------------------------------------------------------------
{ A combination of two colors, primarily used for displaying text with the
  first color being on top and the second being on bottom. The format for
  specifying colors is defined as A8R8G8B8. These values can be edited in
  an interactive manner with the included @italic(ColorSel) tool. }
 TColor2 = array[0..1] of Cardinal;

//---------------------------------------------------------------------------
{ This type is used to pass @link(TColor4) by reference. }
 PColor4 = ^TColor4;

//---------------------------------------------------------------------------
{ A combination of four colors, primarily used for displaying images and
  rectangles with the colors corresponding to each of the vertices. The
  colors are specified on clockwise order: top-left, top-right, bottom-right
  and bottom-left. The format for specifying colors is defined as A8R8G8B8.
  These values can be edited in an interactive manner with the included
  @italic(ColorSel) tool. }
 TColor4 = array[0..3] of Cardinal;

//---------------------------------------------------------------------------
{ This type is used to pass @link(TPoint4) by reference. }
 PPoint4 = ^TPoint4;

//---------------------------------------------------------------------------
{ A combination of four 2D floating-point vectors that define a rectangle,
  mainly used for drawing rectangular primitives and images. The vertices are
  specified on clockwise order: top-left, top-right, bottom-right and
  bottom-left. }
 TPoint4 = array[0..3] of TPoint2;

//---------------------------------------------------------------------------
{ Declaration of general resource-processing event that is invoked when an
  action is being taken for a specific resource.
   @param(Sender Reference to the class involved in the event.)
   @param(SymbolName The name of the symbol that is being processed.)
   @param(ResName The name of the resource file associated with the symbol.) }
 TResourceProcessEvent = procedure(Sender: TObject; const SymbolName,
  ResName: UniString) of object;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Color and Misc Constants'}

//---------------------------------------------------------------------------
const
{ White Color individual constant. In some cases it can be used when no color
  is to be specified. }
 clWhite1: Cardinal = $FFFFFFFF;

//---------------------------------------------------------------------------
{ Black Color individual constant. It can be used in certain circumstances,
  for instance, to draw a shadow of the image. }
 clBlack1: Cardinal = $FF000000;

//---------------------------------------------------------------------------
{ Opaque Color individual constant. This one can be used in certain cases
  where the color of the image is to preserved but the result should be
  completely transparent. }
 clOpaque1: Cardinal = $00FFFFFF;

//---------------------------------------------------------------------------
{ Unknown Color individual constant. It can be used in some cases to specify
  that no color is present or required, or to clear the rendering buffer. }
 clUnknown1: Cardinal = $00000000;

//---------------------------------------------------------------------------
{ White Color vertical gradient constant. In some cases it can be used when
  no color is to be specified. }
 clWhite2: TColor2 = ($FFFFFFFF, $FFFFFFFF);

//---------------------------------------------------------------------------
{ Black Color vertical gradient constant. It can be used in certain
  circumstances, for instance, to draw a shadow of the image. }
 clBlack2: TColor2 = ($FF000000, $FF000000);

//---------------------------------------------------------------------------
{ Opaque Color vertical gradient constant. This one can be used in certain
  cases where the color of the image is to preserved but the result should be
  completely transparent. }
 clOpaque2: TColor2 = ($00FFFFFF, $00FFFFFF);

//---------------------------------------------------------------------------
{ Unknown Color vertical gradient constant. It can be used in some cases to
  specify that no color is present or required. }
 clUnknown2: TColor2 = ($00000000, $00000000);

//---------------------------------------------------------------------------
{ White Color rectangle gradient constant. In some cases it can be used when
  no color is to be specified. }
 clWhite4: TColor4 = ($FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF);

//---------------------------------------------------------------------------
{ Black Color rectangle gradient constant. It can be used in certain
  circumstances, for instance, to draw a shadow of the image. }
 clBlack4: TColor4 = ($FF000000, $FF000000, $FF000000, $FF000000);

//---------------------------------------------------------------------------
{ Opaque Color rectangle gradient constant. This one can be used in certain
  cases where the color of the image is to preserved but the result should be
  completely transparent. }
 clOpaque4: TColor4 = ($00FFFFFF, $00FFFFFF, $00FFFFFF, $00FFFFFF);

//---------------------------------------------------------------------------
{ Unknown Color rectangle gradient constant. It can be used in some cases to
  specify that no color is present or required. }
 clUnknown4: TColor4 = ($00000000, $00000000, $00000000, $00000000);

//---------------------------------------------------------------------------
{ This constant can be used in texture rendering methods which require input
  texture coordinates. In this case, the coordinates are specified to cover
  the entire texture. }
 TexFull4: TPoint4 = ((x: 0.0; y: 0.0), (x: 1.0; y: 0.0), (x: 1.0; y: 1.0),
  (x: 0.0; y: 1.0));

//---------------------------------------------------------------------------
{ This constant has values defined for every possible combination of
  @link(TAsphyrePixelFormat) and indicates the total number of bits used for
  each particular pixel format. }
 AsphyrePixelFormatBits: array[TAsphyrePixelFormat] of Integer
 {$ifndef PasDoc} = (0, 24, 32, 32, 16, 16, 16, 16, 8, 8, 16, 16, 32, 32, 32,
  64, 8, 16, 8, 16, 16, 32, 64, 32, 64, 128, 32, 32, 8, 8, 32){$endif};

//---------------------------------------------------------------------------
//...........................................................................
//===========================================================================
//...........................................................................
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Single Color Helper Functions'}

//---------------------------------------------------------------------------
{ Creates 32-bit RGBA color using the specified individual components for
  red, green, blue and alpha channel. }
function cRGB1(r, g, b: Integer; a: Integer = 255): Cardinal;

//---------------------------------------------------------------------------
{ Creates 32-bit RGBA color using the specified grayscale value with
  alpha-channel set to 255. }
function cGray1(Gray: Integer): Cardinal;

//---------------------------------------------------------------------------
{ Creates 32-bit RGBA color with the specified alpha-channel and each of red,
  green and blue components set to 255. }
function cAlpha1(Alpha: Integer): Cardinal;

//---------------------------------------------------------------------------
{ Creates 32-bit RGBA color with the specified color value having its
  alpha-channel multiplied by the specified coefficient and divided by
  255. }
function cColorAlpha1(Color: Cardinal; Alpha: Integer): Cardinal;

//---------------------------------------------------------------------------
{ Creates 32-bit RGBA color using the specified grayscale value and required
  alpha-channel value. }
function cGrayAlpha1(Gray, Alpha: Integer): Cardinal;

//---------------------------------------------------------------------------
{ Creates 32-bit RGBA color where the original color value has its
  components multiplied by the given grayscale value and alpha-channel
  multiplied by the specified coefficient, and all components divided by
  255. }
function cColorGrayAlpha1(Color: Cardinal; Gray, Alpha: Integer): Cardinal;

//---------------------------------------------------------------------------
{ Creates 32-bit RGBA color where the specified color value has its
  alpha-channel multiplied by the given coefficient. }
function cColorAlpha1f(Color: Cardinal; Alpha: Single): Cardinal;

//---------------------------------------------------------------------------
{ Creates 32-bit RGBA color with alpha-channel specified by the given
  coefficient (multiplied by 255) and the rest of components set to 255. }
function cAlpha1f(Alpha: Single): Cardinal;

//---------------------------------------------------------------------------
{ Creates 32-bit RGBA color from the given 32-bit RGBA color having its luma
  adjusted by the given displacement. The adjustment is made in YIQ color
  space and the resulting color is properly clamped to have all its
  components within valid range so no wrapping/overlapping occurs. }
function cAdjustLuma1(Color: Cardinal; Delta: Single): Cardinal;

//---------------------------------------------------------------------------
{ Returns alpha-channel value from the specified 32-bit RGBA color. }
function cGetAlpha1(Color: Cardinal): Integer;

//---------------------------------------------------------------------------
//...........................................................................
//===========================================================================
//...........................................................................
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Two-color Helper Functions'}

//---------------------------------------------------------------------------
{ Creates 2-color 32-bit RGBA vertical gradient from the specified pair of
  colors values. }
function cColor2(Color0, Color1: Cardinal): TColor2; overload;

//---------------------------------------------------------------------------
{ Creates 2-color 32-bit RGBA vertical gradient where both colors are copied
  from the specified color value. }
function cColor2(Color: Cardinal): TColor2; overload;

//---------------------------------------------------------------------------
{ Creates 2-color 32-bit RGBA vertical gradient where both colors are
  specified from the same components of red, green, blue and alpha-channel. }
function cRGB2(r, g, b: Integer; a: Integer = 255): TColor2; overload;

//---------------------------------------------------------------------------
{ Creates 2-color 32-bit RGBA vertical gradient where each of the colors is
  specified by individual components of red, green, blue and alpha-channel. }
function cRGB2(r1, g1, b1, a1, r2, g2, b2, a2: Integer): TColor2; overload;

//---------------------------------------------------------------------------
{ Creates 2-color 32-bit RGBA vertical gradient where both colors have their
  components of red, green and blue match the grayscale value, and
  alpha-channel set to 255. }
function cGray2(Gray: Integer): TColor2; overload;

//---------------------------------------------------------------------------
{ Creates 2-color 32-bit RGBA vertical gradient where each of the colors have
  their components of red, green and blue match the specified grayscale values,
  and alpha-channel set to 255. }
function cGray2(Gray1, Gray2: Integer): TColor2; overload;

//---------------------------------------------------------------------------
{ Creates 2-color 32-bit RGBA vertical gradient where both colors have their
  alpha-channel set to the specified value and the components of red, green and
  blue set to 255. }
function cAlpha2(Alpha: Integer): TColor2; overload;

//---------------------------------------------------------------------------
{ Creates 2-color 32-bit RGBA vertical gradient where each of the colors have
  their alpha-channel set to the specified values and the components of red,
  green and blue set to 255. }
function cAlpha2(Alpha1, Alpha2: Integer): TColor2; overload;

//---------------------------------------------------------------------------
{ Creates 2-color 32-bit RGBA vertical gradient where both colors are
  specified by the combination of 32-bit RGBA color and alpha-channel value.
  The alpha-channel of the specified color is multiplied by the alpha-channel
  value and divided by 255. }
function cColorAlpha2(Color: Cardinal; Alpha: Integer): TColor2; overload;

//---------------------------------------------------------------------------
{ Creates 2-color 32-bit RGBA vertical gradient where each of the colors is
  specified by combination of color value and alpha-channel coefficient.
  The alpha-channel of each specified color value is multiplied by the
  alpha-channel coefficient and divided by 255. }
function cColorAlpha2(Color1, Color2: Cardinal; Alpha1,
 Alpha2: Integer): TColor2; overload;

//---------------------------------------------------------------------------
{ Creates 2-color 32-bit RGBA vertical gradient from another gradient,
  multiplying alpha-channel of both color values by the specified
  coefficient. }
function cColorAlpha2of(const Colors: TColor2; Alpha: Single): TColor2;

//---------------------------------------------------------------------------
{ Creates 2-color 32-bit RGBA vertical gradient from another gradient,
  adjusting luma of each color value by the given displacement. The
  adjustment is made in YIQ color space and the resulting colors are properly
  clamped to have all their components within valid range so no
  wrapping/overlapping occurs. }
function cAdjustLuma2(const Color: TColor2; Delta: Single): TColor2;

//---------------------------------------------------------------------------
{ Returns the maximum of two alpha-channel values from the given 2-color
  32-bit RGBA vertical gradient. }
function cGetMaxAlpha2(const Color2: TColor2): Integer;

//---------------------------------------------------------------------------
//...........................................................................
//===========================================================================
//...........................................................................
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Four-color Helper Functions'}

//---------------------------------------------------------------------------
{ Creates 4-color gradient where all colors are specified by the same source
  color. }
function cColor4(Color: Cardinal): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where each color is specified individually. }
function cColor4(Color1, Color2, Color3, Color4: Cardinal): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where all colors are specified by the same
  individual components of red, green, blue and alpha-channel. }
function cRGB4(r, g, b: Integer; a: Integer = 255): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where the first two colors are specified by the
  first combination of individual components and the second two colors
  specified by the second combination of individual components, effectively
  describing a 2-color vertical gradient. }
function cRGB4(r1, g1, b1, a1, r2, g2, b2, a2: Integer): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where all colors have their individual components
  of red, green and blue set to the given grayscale value, and alpha-channel
  to 255. }
function cGray4(Gray: Integer): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where each color has its individual components of
  red, green and blue set to each of the given grayscale values, and
  alpha-channel to 255. }
function cGray4(Gray1, Gray2, Gray3, Gray4: Integer): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where each color has its alpha-channel set to the
  same specified value with the rest of components set to 255. }
function cAlpha4(Alpha: Integer): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where each color has its alpha-channel set to each
  of the specified values with the rest of components set to 255. }
function cAlpha4(Alpha1, Alpha2, Alpha3, Alpha4: Integer): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where each color has its individual components of
  red, green and blue set to the same grayscale value, and alpha-channel set
  to the same alpha value. }
function cGrayAlpha4(Gray, Alpha: Integer): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where each color has its individual components of
  red, green and blue set to the corresponding grayscale value, and
  alpha-channel set to the corresponding alpha value. }
function cGrayAlpha4(Gray1, Gray2, Gray3, Gray4, Alpha1, Alpha2, Alpha3,
 Alpha4: Integer): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where all colors are specified by one
  combination of 32-bit RGBA color and alpha-value. The specified color has
  its alpha-channel multiplied by the alpha value and divided by 255. }
function cColorAlpha4(Color: Cardinal; Alpha: Integer): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where each of the colors is specified by the
  corresponding combination of 32-bit RGBA color and alpha-value. Each of the
  specified colors has its alpha-channel multiplied by the corresponding alpha
  value and divided by 255. }
function cColorAlpha4(Color1, Color2, Color3, Color4: Cardinal; Alpha1,
 Alpha2, Alpha3, Alpha4: Integer): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where all colors are specified by one
  combination of 32-bit RGBA color, grayscale and alpha values. The specified
  color has its red, green and blue values multiplied by grayscale value,
  alpha-channel multiplied by alpha value, and then all components divided
  by 255. }
function cColorGrayAlpha4(Color: Cardinal; Gray,
 Alpha: Integer): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where each of the colors is specified by the
  corresponding combination of 32-bit RGBA color, grayscale and alpha values.
  In each combination, the specified color has its red, green and blue values
  multiplied by the grayscale value, alpha-channel multiplied by the alpha
  value, and then all components divided by 255. }
function cColorGrayAlpha4(Color1, Color2, Color3, Color4: Cardinal;
 Gray1, Gray2, Gray3, Gray4, Alpha1, Alpha2, Alpha3,
 Alpha4: Integer): TColor4; overload;

//---------------------------------------------------------------------------
{ Creates 4-color gradient from another 4-color gradient where each color has
  its alpha-channel multiplied by the given coefficient. }
function cColor4Alpha1f(const Color4: TColor4; Alpha: Single): TColor4;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where all colors has their alpha-channel set to
  the given coefficient (multiplied by 255) with the rest of components set to
  255. }
function cAlpha4f(Alpha: Single): TColor4;

//---------------------------------------------------------------------------
{ Creates 4-color gradient where the first pair of colors specified by the
  first color value and the second pair of colors specified by the second
  color value. All four colors have their alpha-channel multiplied by the
  given coefficient. }
function cColor4f2(TopColor, BottomColor: Cardinal; Alpha: Single): TColor4;

//---------------------------------------------------------------------------
{ Creates 4-color gradient from another 4-color gradient adjusting luma by
  the given displacement. The adjustment is made in YIQ color space and the
  resulting colors are properly clamped to have all their components within
  valid range so no wrapping/overlapping occurs. }
function cAdjustLuma4(const Color: TColor4; Delta: Single): TColor4;

//---------------------------------------------------------------------------
{ Returns the maximum of four alpha-channel values taken from colors in the
  given 4-color gradient. }
function cGetMaxAlpha4(const Color4: TColor4): Integer;

//---------------------------------------------------------------------------
//...........................................................................
//===========================================================================
//...........................................................................
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Four-point Helper Functions'}

//---------------------------------------------------------------------------
{ Creates 4-point rectangle from each of the specified individual
 coordinates. }
function Point4(x1, y1, x2, y2, x3, y3, x4, y4: Single): TPoint4; overload;

//---------------------------------------------------------------------------
{ Creates 4-point rectangle from each of the specified 2D points. }
function Point4(const p1, p2, p3, p4: TPoint2): TPoint4; overload;

//---------------------------------------------------------------------------
{ Creates 4-point rectangle from the given standard rectangle. }
function pRect4(const Rect: TRect): TPoint4;

//---------------------------------------------------------------------------
{ Creates 4-point rectangle with the specified top left corner and the given
  dimensions. }
function pBounds4(ALeft, ATop, AWidth, AHeight: Single): TPoint4;

//---------------------------------------------------------------------------
{ Creates 4-point rectangle with the specified top left corner and the given
  dimensions, which are scaled by the given coefficient. }
function pBounds4s(ALeft, ATop, AWidth, AHeight, Theta: Single): TPoint4;

//---------------------------------------------------------------------------
{ Creates 4-point rectangle with the specified top left corner and the given
  dimensions. The rectangle is then scaled by the given coefficient with its
  center preserved. }
function pBounds4sc(ALeft, ATop, AWidth, AHeight, Theta: Single): TPoint4;

//---------------------------------------------------------------------------
{ Creates 4-point rectangle from another 4-point rectangle but having left
  vertices exchanged with the right ones, effectively mirroring it
  horizontally. }
function pMirror4(const Point4: TPoint4): TPoint4;

//---------------------------------------------------------------------------
{ Creates 4-point rectangle from another 4-point rectangle but having top
  vertices exchanged with the bottom ones, effectively flipping it
  vertically. }
function pFlip4(const Point4: TPoint4): TPoint4;

//---------------------------------------------------------------------------
{ Creates 4-point rectangle from another 4-point rectangle but having all
  vertices shifted by the specified displacement. }
function pShift4(const Points: TPoint4; const ShiftBy: TPoint2): TPoint4;

//---------------------------------------------------------------------------
{ Creates 4-point rectangle specified by its dimensions. The rectangle is
  rotated and scaled around the specified middle point (assumed to be inside
  its dimensions) and placed in the center of the specified origin. }
function pRotate4(const Origin, Size, Middle: TPoint2; Angle: Single;
 Theta: Single = 1.0): TPoint4;

 //---------------------------------------------------------------------------
{ Creates 4-point rectangle specified by its dimensions. The rectangle is
  rotated and scaled around the specified middle point (assumed to be inside
  its dimensions) and placed in the center of the specified origin. The
  difference between this method and @link(pRotate4) is that the rotation does
  not preserve centering of the rectangle in case where middle point is not
  actually located in the middle. }
function pRotate4se(const Origin, Size, Middle: TPoint2; Angle: Single;
 Theta: Single = 1.0): TPoint4;

//---------------------------------------------------------------------------
{ Creates 4-point rectangle specified by its dimensions. The rectangle is
  rotated and scaled around its center and placed at the specified origin. }
function pRotate4c(const Origin, Size: TPoint2; Angle: Single;
 Theta: Single = 1.0): TPoint4;

//---------------------------------------------------------------------------
{ Returns @True if the given point is within the specified rectangle or
  @False otherwise. }
function PointInRect(const Point: TPoint2px;
 const Rect: TRect): Boolean; overload;

//---------------------------------------------------------------------------
{ Returns @True if the given point is within the specified rectangle or
  @False otherwise. This function works with floating-point vector by rounding
  it down. }
{$ifndef Vec2ToPxImplicit}
function PointInRect(const Point: TPoint2;
 const Rect: TRect): Boolean; overload;
{$endif}

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Utility and Math Functions'}

//---------------------------------------------------------------------------
{ Returns @True if the given rectangle is within the specified rectangle or
  @False otherwise. }
function RectInRect(const Rect1, Rect2: TRect): Boolean;

//---------------------------------------------------------------------------
{ Returns @True if the two specified rectangles overlap or @False otherwise. }
function OverlapRect(const Rect1, Rect2: TRect): Boolean;

//---------------------------------------------------------------------------
{ Returns @True if the specified point is inside the triangle specified by
  the given three vertices or @False otherwise. }
function PointInTriangle(const Pos, v1, v2, v3: TPoint2px): Boolean;

//---------------------------------------------------------------------------
{ Displaces the specified rectangle by the given offset and returns the
  new resulting rectangle. }
function MoveRect(const Rect: TRect; const Point: TPoint2px): TRect;

//---------------------------------------------------------------------------
{ Calculates the smaller rectangle resulting from the intersection of the
  given two rectangles. }
function ShortRect(const Rect1, Rect2: TRect): TRect;

//---------------------------------------------------------------------------
{ Reduces the size of the specified rectangle by the given offsets on all
  edges. }
function ShrinkRect(const Rect: TRect; hIn, vIn: Integer): TRect;

//---------------------------------------------------------------------------
{ Calculates the resulting interpolated value from the given two depending on
  the @italic(Theta) parameter, which must be specified in [0..1] range. }
function Lerp(x0, x1, Theta: Single): Single;

//---------------------------------------------------------------------------
{ Calculates the resulting interpolated value from the given four vertices and
  the @italic(Theta) parameter, which must be specified in [0..1] range. The
  interpolation uses Catmull-Rom spline. }
function CatmullRom(x0, x1, x2, x3, Theta: Single): Single;

//---------------------------------------------------------------------------
{ Clamps the given value so that it always lies within the specified range. }
function MinMax2(Value, Min, Max: Integer): Integer;

//---------------------------------------------------------------------------
{ Returns the value that is smallest among the two. }
function Min2(a, b: Integer): Integer;

//---------------------------------------------------------------------------
{ Returns the value that is biggest among the two. }
function Max2(a, b: Integer): Integer;

//---------------------------------------------------------------------------
{ Returns the value that is smallest among the three. }
function Min3(a, b, c: Integer): Integer;

//---------------------------------------------------------------------------
{ Returns the value that is biggest among the three. }
function Max3(a, b, c: Integer): Integer;

//---------------------------------------------------------------------------
{ Returns @True if the specified value is a power of two or @False otherwise. }
function IsPowerOfTwo(Value: Integer): Boolean;

//---------------------------------------------------------------------------
{ Returns the least power of two greater or equal to the specified value. }
function CeilPowerOfTwo(Value: Integer): Integer;

//---------------------------------------------------------------------------
{ Returns the greatest power of two lesser or equal to the specified value. }
function FloorPowerOfTwo(Value: Integer): Integer;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Pixel Helper Functions'}

//---------------------------------------------------------------------------
{ Switches red and blue channels in 32-bit RGBA color value. }
function DisplaceRB(Color: Cardinal): Cardinal;

//---------------------------------------------------------------------------
{ Computes alpha-blending for a pair of 32-bit RGBA colors values.
  @italic(Alpha) can be in [0..255] range. }
function BlendPixels(Color1, Color2: Cardinal; Alpha: Integer): Cardinal;

//---------------------------------------------------------------------------
{ Computes alpha-blending for a pair of 32-bit RGBA colors values using
  floating-point approach. @italic(Alpha) can be in [0..1] range. For a
  faster alternative, use @link(BlendPixels). }
function LerpPixels(Color1, Color2: Cardinal; Alpha: Single): Cardinal;

//---------------------------------------------------------------------------
{ Computes the average of two given 32-bit RGBA color values. }
function AvgPixels(Color1, Color2: Cardinal): Cardinal;

//---------------------------------------------------------------------------
{ Computes the average of four given 32-bit RGBA color values. }
function AvgFourPixels(Color1, Color2, Color3, Color4: Cardinal): Cardinal;

//---------------------------------------------------------------------------
{ Computes the average of six given 32-bit RGBA color values. }
function AvgSixPixels(Color1, Color2, Color3, Color4, Color5,
 Color6: Cardinal): Cardinal;

//---------------------------------------------------------------------------
{ Adds two 32-bit RGBA color values together clamping the resulting values
  if necessary. }
function AddPixels(Color1, Color2: Cardinal): Cardinal;

//---------------------------------------------------------------------------
{ Multiplies two 32-bit RGBA color values together. }
function MulPixels(Color1, Color2: Cardinal): Cardinal;

//---------------------------------------------------------------------------
{ Multiplies alpha-channel of the given 32-bit RGBA color value by the
  given coefficient and divides the result by 255. }
function MulPixelAlpha(Color: Cardinal; Alpha: Integer): Cardinal; overload;

{ Multiplies alpha-channel of the given 32-bit RGBA color value by the
  given coefficient using floating-point approach. }
function MulPixelAlpha(Color: Cardinal; Alpha: Single): Cardinal; overload;

//---------------------------------------------------------------------------
{ Returns grayscale value in range of [0..255] from the given 32-bit RGBA
  color value. The alpha-channel is ignored. }
function PixelToGray(Pixel: Cardinal): Integer;

//---------------------------------------------------------------------------
{ Returns grayscale value in range of [0..1] from the given 32-bit RGBA
  color value. The resulting value can be considered the color's @italic(luma).
  The alpha-channel is ignored. }
function PixelToGrayEx(Pixel: Cardinal): Single;

//---------------------------------------------------------------------------
{ Extracts alpha-channel from two grayscale samples. The sample must be
  rendered with the same color on two different backgrounds, preferably on
  black and white; the resulting colors are provided in @italic(Src1) and
  @italic(Src2), with original backgrounds in @italic(Bk1) and @italic(Bk2).
  The resulting alpha-channel and original color are computed and returned.
  This method is particularly useful for calculating alpha-channel when
  rendering GDI fonts or in tools that generate resulting images without
  providing alpha-channel (therefore rendering the same image on two
  backgrounds is sufficient to calculate its alpha-channel). }
procedure ExtractAlpha(Src1, Src2, Bk1, Bk2: Single; out Alpha,
 Px: Single);

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'YIQ Color Helper Functions'}

//---------------------------------------------------------------------------
{$define Asphyre_Interface}
 {$include Asphyre.YIQColors.inc}
{$undef Asphyre_Interface}

//---------------------------------------------------------------------------
{$ENDREGION}

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
{$REGION 'Single Color Helper Functions'}

//---------------------------------------------------------------------------
function cRGB1(r, g, b: Integer; a: Integer = 255): Cardinal;
begin
 Result:= Cardinal(b) or (Cardinal(g) shl 8) or (Cardinal(r) shl 16) or
  (Cardinal(a) shl 24);
end;

//---------------------------------------------------------------------------
function cGray1(Gray: Integer): Cardinal;
begin
 Result:= ((Cardinal(Gray) and $FF) or ((Cardinal(Gray) and $FF) shl 8) or
  ((Cardinal(Gray) and $FF) shl 16)) or $FF000000;
end;

//---------------------------------------------------------------------------
function cAlpha1(Alpha: Integer): Cardinal;
begin
 Result:= $00FFFFFF or ((Cardinal(Alpha) and $FF) shl 24);
end;

//---------------------------------------------------------------------------
function cColorAlpha1(Color: Cardinal; Alpha: Integer): Cardinal;
begin
 Result:= (Color and $00FFFFFF) or
  Cardinal((Integer(Color shr 24) * Alpha) div 255) shl 24;
end;

//---------------------------------------------------------------------------
function cGrayAlpha1(Gray, Alpha: Integer): Cardinal;
begin
 Result:= ((Cardinal(Gray) and $FF) or ((Cardinal(Gray) and $FF) shl 8) or
  ((Cardinal(Gray) and $FF) shl 16)) or ((Cardinal(Alpha) and $FF) shl 24);
end;

//---------------------------------------------------------------------------
function cColorGrayAlpha1(Color: Cardinal; Gray, Alpha: Integer): Cardinal;
begin
 Result:= Cardinal((Integer(Color and $FF) * Gray) div 255) or
  (Cardinal((Integer((Color shr 8) and $FF) * Gray) div 255) shl 8) or
  (Cardinal((Integer((Color shr 16) and $FF) * Gray) div 255) shl 16) or
  (Cardinal((Integer((Color shr 24) and $FF) * Alpha) div 255) shl 24);
end;

//---------------------------------------------------------------------------
function cColorAlpha1f(Color: Cardinal; Alpha: Single): Cardinal;
begin
 Result:= cColorAlpha1(Color, Round(Alpha * 255.0));
end;

//---------------------------------------------------------------------------
function cAlpha1f(Alpha: Single): Cardinal;
begin
 Result:= cAlpha1(Round(Alpha * 255.0));
end;

//---------------------------------------------------------------------------
function cAdjustLuma1(Color: Cardinal; Delta: Single): Cardinal;
var
 ColYiq: TYIQColor;
begin
 ColYiq:= RGBtoYIQ(Color);
 ColYiq.y:= Max(Min(ColYiq.y + Delta, 1.0), 0.0);

 Result:= YIQtoRGB(ColYiq);
end;

//---------------------------------------------------------------------------
function cGetAlpha1(Color: Cardinal): Integer;
begin
 Result:= (Color shr 24) and $FF;
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Two-color Helper Functions'}

//---------------------------------------------------------------------------
function cColor2(Color0, Color1: Cardinal): TColor2;
begin
 Result[0]:= Color0;
 Result[1]:= Color1;
end;

//---------------------------------------------------------------------------
function cColor2(Color: Cardinal): TColor2;
begin
 Result[0]:= Color;
 Result[1]:= Color;
end;

//---------------------------------------------------------------------------
function cRGB2(r1, g1, b1, a1, r2, g2, b2, a2: Integer): TColor2; overload;
begin
 Result[0]:= cRGB1(r1, g1, b1, a1);
 Result[1]:= cRGB1(r2, g2, b2, a2);
end;

//---------------------------------------------------------------------------
function cRGB2(r, g, b: Integer; a: Integer = 255): TColor2; overload;
begin
 Result[0]:= cRGB1(r, g, b, a);
 Result[1]:= Result[0];
end;

//---------------------------------------------------------------------------
function cGray2(Gray: Integer): TColor2;
begin
 Result:= cColor2(
  ((Cardinal(Gray) and $FF) or
  ((Cardinal(Gray) and $FF) shl 8) or
  ((Cardinal(Gray) and $FF) shl 16)) or $FF000000);
end;

//---------------------------------------------------------------------------
function cGray2(Gray1, Gray2: Integer): TColor2;
begin
 Result[0]:=
  ((Cardinal(Gray1) and $FF) or
  ((Cardinal(Gray1) and $FF) shl 8) or
  ((Cardinal(Gray1) and $FF) shl 16)) or $FF000000;

 Result[1]:=
  ((Cardinal(Gray2) and $FF) or
  ((Cardinal(Gray2) and $FF) shl 8) or
  ((Cardinal(Gray2) and $FF) shl 16)) or $FF000000;
end;

//---------------------------------------------------------------------------
function cAlpha2(Alpha: Integer): TColor2;
begin
 Result:= cColor2($FFFFFF or ((Cardinal(Alpha) and $FF) shl 24));
end;

//---------------------------------------------------------------------------
function cAlpha2(Alpha1, Alpha2: Integer): TColor2;
begin
 Result[0]:= $FFFFFF or ((Cardinal(Alpha1) and $FF) shl 24);
 Result[1]:= $FFFFFF or ((Cardinal(Alpha2) and $FF) shl 24);
end;

//---------------------------------------------------------------------------
function cColorAlpha2(Color: Cardinal; Alpha: Integer): TColor2; overload;
begin
 Result:= cColor2((Color and $FFFFFF) or ((Cardinal(Alpha) and $FF) shl 24));
end;

//---------------------------------------------------------------------------
function cColorAlpha2(Color1, Color2: Cardinal; Alpha1,
 Alpha2: Integer): TColor2;
begin
 Result[0]:= cColorAlpha1(Color1, Alpha1);
 Result[1]:= cColorAlpha1(Color2, Alpha2);
end;

//---------------------------------------------------------------------------
function cColorAlpha2of(const Colors: TColor2; Alpha: Single): TColor2;
var
 iAlpha: Integer;
begin
 iAlpha:= Round(Alpha * 255.0);

 Result[0]:= cColorAlpha1(Colors[0], iAlpha);
 Result[1]:= cColorAlpha1(Colors[1], iAlpha);
end;

//---------------------------------------------------------------------------
function cAdjustLuma2(const Color: TColor2; Delta: Single): TColor2;
begin
 Result[0]:= cAdjustLuma1(Color[0], Delta);
 Result[1]:= cAdjustLuma1(Color[1], Delta);
end;

//---------------------------------------------------------------------------
function cGetMaxAlpha2(const Color2: TColor2): Integer;
begin
 Result:= Max2(cGetAlpha1(Color2[0]), cGetAlpha1(Color2[1]));
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Four-color Helper Functions'}

//---------------------------------------------------------------------------
function cColor4(Color: Cardinal): TColor4;
begin
 Result[0]:= Color;
 Result[1]:= Color;
 Result[2]:= Color;
 Result[3]:= Color;
end;

//---------------------------------------------------------------------------
function cColor4(Color1, Color2, Color3, Color4: Cardinal): TColor4;
begin
 Result[0]:= Color1;
 Result[1]:= Color2;
 Result[2]:= Color3;
 Result[3]:= Color4;
end;

//---------------------------------------------------------------------------
function cRGB4(r, g, b: Integer; a: Integer = 255): TColor4;
begin
 Result:= cColor4(cRGB1(r, g, b, a));
end;

//---------------------------------------------------------------------------
function cRGB4(r1, g1, b1, a1, r2, g2, b2, a2: Integer): TColor4;
begin
 Result[0]:= cRGB1(r1, g1, b1, a1);
 Result[1]:= Result[0];
 Result[2]:= cRGB1(r2, g2, b2, a2);
 Result[3]:= Result[2];
end;

//---------------------------------------------------------------------------
function cGray4(Gray: Integer): TColor4;
begin
 Result:= cColor4(
  ((Cardinal(Gray) and $FF) or
  ((Cardinal(Gray) and $FF) shl 8) or
  ((Cardinal(Gray) and $FF) shl 16)) or $FF000000);
end;

//---------------------------------------------------------------------------
function cGray4(Gray1, Gray2, Gray3, Gray4: Integer): TColor4;
begin
 Result[0]:= ((Cardinal(Gray1) and $FF) or
  ((Cardinal(Gray1) and $FF) shl 8) or
  ((Cardinal(Gray1) and $FF) shl 16)) or $FF000000;

 Result[1]:= ((Cardinal(Gray2) and $FF) or
  ((Cardinal(Gray2) and $FF) shl 8) or
  ((Cardinal(Gray2) and $FF) shl 16)) or $FF000000;

 Result[2]:= ((Cardinal(Gray3) and $FF) or
  ((Cardinal(Gray3) and $FF) shl 8) or
  ((Cardinal(Gray3) and $FF) shl 16)) or $FF000000;

 Result[3]:= ((Cardinal(Gray4) and $FF) or
  ((Cardinal(Gray4) and $FF) shl 8) or
  ((Cardinal(Gray4) and $FF) shl 16)) or $FF000000;
end;

//---------------------------------------------------------------------------
function cAlpha4(Alpha: Integer): TColor4;
begin
 Result:= cColor4($FFFFFF or ((Cardinal(Alpha) and $FF) shl 24));
end;

//---------------------------------------------------------------------------
function cAlpha4(Alpha1, Alpha2, Alpha3, Alpha4: Integer): TColor4;
begin
 Result[0]:= $FFFFFF or ((Cardinal(Alpha1) and $FF) shl 24);
 Result[1]:= $FFFFFF or ((Cardinal(Alpha2) and $FF) shl 24);
 Result[2]:= $FFFFFF or ((Cardinal(Alpha3) and $FF) shl 24);
 Result[3]:= $FFFFFF or ((Cardinal(Alpha4) and $FF) shl 24);
end;

//---------------------------------------------------------------------------
function cGrayAlpha4(Gray, Alpha: Integer): TColor4;
begin
 Result:= cColor4(((Cardinal(Gray) and $FF) or
  ((Cardinal(Gray) and $FF) shl 8) or
  ((Cardinal(Gray) and $FF) shl 16)) or (Cardinal(Alpha) shl 24));
end;

//---------------------------------------------------------------------------
function cGrayAlpha4(Gray1, Gray2, Gray3, Gray4, Alpha1, Alpha2, Alpha3,
 Alpha4: Integer): TColor4;
begin
 Result[0]:=
  ((Cardinal(Gray1) and $FF) or
  ((Cardinal(Gray1) and $FF) shl 8) or
  ((Cardinal(Gray1) and $FF) shl 16)) or
  (Cardinal(Alpha1) shl 24);

 Result[1]:=
  ((Cardinal(Gray2) and $FF) or
  ((Cardinal(Gray2) and $FF) shl 8) or
  ((Cardinal(Gray2) and $FF) shl 16)) or
  (Cardinal(Alpha2) shl 24);

 Result[2]:=
  ((Cardinal(Gray3) and $FF) or
  ((Cardinal(Gray3) and $FF) shl 8) or
  ((Cardinal(Gray3) and $FF) shl 16)) or
  (Cardinal(Alpha3) shl 24);

 Result[3]:=
  ((Cardinal(Gray4) and $FF) or
  ((Cardinal(Gray4) and $FF) shl 8) or
  ((Cardinal(Gray4) and $FF) shl 16)) or
  (Cardinal(Alpha4) shl 24);
end;

//---------------------------------------------------------------------------
function cColorAlpha4(Color: Cardinal; Alpha: Integer): TColor4; overload;
begin
 Result:= cColor4(cColorAlpha1(Color, Alpha));
end;

//---------------------------------------------------------------------------
function cColorAlpha4(Color1, Color2, Color3, Color4: Cardinal;
 Alpha1, Alpha2, Alpha3, Alpha4: Integer): TColor4;
begin
 Result[0]:= cColorAlpha1(Color1, Alpha1);
 Result[1]:= cColorAlpha1(Color2, Alpha2);
 Result[2]:= cColorAlpha1(Color3, Alpha3);
 Result[3]:= cColorAlpha1(Color4, Alpha4);
end;

//---------------------------------------------------------------------------
function cColorGrayAlpha4(Color: Cardinal; Gray,
 Alpha: Integer): TColor4; overload;
begin
 Result:= cColor4(cColorGrayAlpha1(Color, Gray, Alpha));
end;

//---------------------------------------------------------------------------
function cColorGrayAlpha4(Color1, Color2, Color3, Color4: Cardinal;
 Gray1, Gray2, Gray3, Gray4, Alpha1, Alpha2, Alpha3,
 Alpha4: Integer): TColor4; overload;
begin
 Result[0]:= cColorGrayAlpha1(Color1, Gray1, Alpha1);
 Result[1]:= cColorGrayAlpha1(Color2, Gray2, Alpha2);
 Result[2]:= cColorGrayAlpha1(Color3, Gray3, Alpha3);
 Result[3]:= cColorGrayAlpha1(Color4, Gray4, Alpha4);
end;

//---------------------------------------------------------------------------
function cColor4Alpha1f(const Color4: TColor4; Alpha: Single): TColor4;
begin
 Result[0]:= cColorAlpha1f(Color4[0], Alpha);
 Result[1]:= cColorAlpha1f(Color4[1], Alpha);
 Result[2]:= cColorAlpha1f(Color4[2], Alpha);
 Result[3]:= cColorAlpha1f(Color4[3], Alpha);
end;

//---------------------------------------------------------------------------
function cAlpha4f(Alpha: Single): TColor4;
begin
 Result:= cColor4(cAlpha1f(Alpha));
end;

//---------------------------------------------------------------------------
function cColor4f2(TopColor, BottomColor: Cardinal; Alpha: Single): TColor4;
var
 Color1, Color2: Cardinal;
 Alpha1: Integer;
begin
 Alpha1:= Round(Alpha * 255.0);
 Color1:= cColorAlpha1(TopColor, Alpha1);
 Color2:= cColorAlpha1(BottomColor, Alpha1);

 Result:= cColor4(Color1, Color1, Color2, Color2);
end;

//---------------------------------------------------------------------------
function cAdjustLuma4(const Color: TColor4; Delta: Single): TColor4;
begin
 Result[0]:= cAdjustLuma1(Color[0], Delta);
 Result[1]:= cAdjustLuma1(Color[1], Delta);
 Result[2]:= cAdjustLuma1(Color[2], Delta);
 Result[3]:= cAdjustLuma1(Color[3], Delta);
end;

//---------------------------------------------------------------------------
function cGetMaxAlpha4(const Color4: TColor4): Integer;
begin
 Result:= Max2(
  Max2(cGetAlpha1(Color4[0]), cGetAlpha1(Color4[1])),
  Max2(cGetAlpha1(Color4[2]), cGetAlpha1(Color4[3])));
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Four-point Helper Functions'}

//---------------------------------------------------------------------------
function Point4(x1, y1, x2, y2, x3, y3, x4, y4: Single): TPoint4;
begin
 Result[0].x:= x1;
 Result[0].y:= y1;
 Result[1].x:= x2;
 Result[1].y:= y2;
 Result[2].x:= x3;
 Result[2].y:= y3;
 Result[3].x:= x4;
 Result[3].y:= y4;
end;

//---------------------------------------------------------------------------
function Point4(const p1, p2, p3, p4: TPoint2): TPoint4;
begin
 Result:= Point4(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y);
end;

//---------------------------------------------------------------------------
function pRect4(const Rect: TRect): TPoint4;
begin
 Result[0].x:= Rect.Left;
 Result[0].y:= Rect.Top;
 Result[1].x:= Rect.Right;
 Result[1].y:= Rect.Top;
 Result[2].x:= Rect.Right;
 Result[2].y:= Rect.Bottom;
 Result[3].x:= Rect.Left;
 Result[3].y:= Rect.Bottom;
end;

//---------------------------------------------------------------------------
function pBounds4(ALeft, ATop, AWidth, AHeight: Single): TPoint4;
begin
 Result[0].X:= ALeft;
 Result[0].Y:= ATop;
 Result[1].X:= ALeft + AWidth;
 Result[1].Y:= ATop;
 Result[2].X:= ALeft + AWidth;
 Result[2].Y:= ATop + AHeight;
 Result[3].X:= ALeft;
 Result[3].Y:= ATop + AHeight;
end;

//---------------------------------------------------------------------------
function pBounds4s(ALeft, ATop, AWidth, AHeight, Theta: Single): TPoint4;
begin
 Result:= pBounds4(ALeft, ATop, Round(AWidth * Theta), Round(AHeight * Theta));
end;

//---------------------------------------------------------------------------
function pBounds4sc(ALeft, ATop, AWidth, AHeight, Theta: Single): TPoint4;
var
 Left, Top: Single;
 Width, Height: Single;
begin
 if (Theta = 1.0) then
  Result:= pBounds4(ALeft, ATop, AWidth, AHeight)
 else
  begin
   Width := AWidth * Theta;
   Height:= AHeight * Theta;
   Left  := ALeft + ((AWidth - Width) * 0.5);
   Top   := ATop + ((AHeight - Height) * 0.5);
   Result:= pBounds4(Left, Top, Round(Width), Round(Height));
  end;
end;

//---------------------------------------------------------------------------
function pMirror4(const Point4: TPoint4): TPoint4;
begin
 Result[0].x:= Point4[1].x;
 Result[0].y:= Point4[0].y;
 Result[1].x:= Point4[0].x;
 Result[1].y:= Point4[1].y;
 Result[2].x:= Point4[3].x;
 Result[2].y:= Point4[2].y;
 Result[3].x:= Point4[2].x;
 Result[3].y:= Point4[3].y;
end;

//---------------------------------------------------------------------------
function pFlip4(const Point4: TPoint4): TPoint4;
begin
 Result[0].x:= Point4[0].x;
 Result[0].y:= Point4[2].y;
 Result[1].x:= Point4[1].x;
 Result[1].y:= Point4[3].y;
 Result[2].x:= Point4[2].x;
 Result[2].y:= Point4[0].y;
 Result[3].x:= Point4[3].x;
 Result[3].y:= Point4[1].y;
end;

//---------------------------------------------------------------------------
function pShift4(const Points: TPoint4; const ShiftBy: TPoint2): TPoint4;
begin
 Result[0].x:= Points[0].x + ShiftBy.x;
 Result[0].y:= Points[0].y + ShiftBy.y;
 Result[1].x:= Points[1].x + ShiftBy.x;
 Result[1].y:= Points[1].y + ShiftBy.y;
 Result[2].x:= Points[2].x + ShiftBy.x;
 Result[2].y:= Points[2].y + ShiftBy.y;
 Result[3].x:= Points[3].x + ShiftBy.x;
 Result[3].y:= Points[3].y + ShiftBy.y;
end;

//---------------------------------------------------------------------------
function pRotate4(const Origin, Size, Middle: TPoint2; Angle: Single;
 Theta: Single): TPoint4;
var
 CosPhi: Single;
 SinPhi: Single;
 Index : Integer;
 Points: TPoint4;
 Point : TPoint2;
begin
 CosPhi:= Cos(Angle);
 SinPhi:= Sin(Angle);

 // create 4 points centered at (0, 0)
 Points:= pBounds4(-Middle.x, -Middle.y, Size.x, Size.y);

 // process the created points
 for Index:= 0 to 3 do
  begin
   // scale the point
   Points[Index].x:= Points[Index].x * Theta;
   Points[Index].y:= Points[Index].y * Theta;

   // rotate the point around Phi
   Point.x:= (Points[Index].x * CosPhi) - (Points[Index].y * SinPhi);
   Point.y:= (Points[Index].y * CosPhi) + (Points[Index].x * SinPhi);

   // translate the point to (Origin)
   Points[Index].x:= Point.x + Origin.x;
   Points[Index].y:= Point.y + Origin.y;
  end;

 Result:= Points;
end;

//---------------------------------------------------------------------------
function pRotate4se(const Origin, Size, Middle: TPoint2; Angle: Single;
 Theta: Single): TPoint4;
var
 CosPhi: Single;
 SinPhi: Single;
 Index : Integer;
 Points: TPoint4;
 Point : TPoint2;
begin
 CosPhi:= Cos(Angle);
 SinPhi:= Sin(Angle);

 // create 4 points centered at (0, 0)
 Points:= pBounds4(-Middle.x, -Middle.y, Size.x, Size.y);

 // process the created points
 for Index:= 0 to 3 do
  begin
   // scale the point
   Points[Index].x:= Points[Index].x * Theta;
   Points[Index].y:= Points[Index].y * Theta;

   // rotate the point around Phi
   Point.x:= (Points[Index].x * CosPhi) - (Points[Index].y * SinPhi);
   Point.y:= (Points[Index].y * CosPhi) + (Points[Index].x * SinPhi);

   // translate the point to (Origin)
   Points[Index].x:= Point.x + Origin.x + Middle.x;
   Points[Index].y:= Point.y + Origin.y + Middle.y;
  end;

 Result:= Points;
end;

//---------------------------------------------------------------------------
function pRotate4c(const Origin, Size: TPoint2; Angle: Single;
 Theta: Single): TPoint4;
begin
 Result:= pRotate4(Origin, Size, Point2(Size.x * 0.5, Size.y * 0.5), Angle,
  Theta);
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Utility and Math Helper Functions'}

//-----------------------------------------------------------------------------
function PointInRect(const Point: TPoint2px;
 const Rect: TRect): Boolean; overload;
begin
 Result:= (Point.x >= Rect.Left)and(Point.x <= Rect.Right)and
  (Point.y >= Rect.Top)and(Point.y <= Rect.Bottom);
end;

//---------------------------------------------------------------------------
{$ifndef Vec2ToPxImplicit}
function PointInRect(const Point: TPoint2;
 const Rect: TRect): Boolean; overload;
begin
 Result:= PointInRect(Vec2ToPx(Point), Rect);
end;
{$endif}

//---------------------------------------------------------------------------
function RectInRect(const Rect1, Rect2: TRect): Boolean;
begin
 Result:= (Rect1.Left >= Rect2.Left)and(Rect1.Right <= Rect2.Right)and
  (Rect1.Top >= Rect2.Top)and(Rect1.Bottom <= Rect2.Bottom);
end;

//---------------------------------------------------------------------------
function OverlapRect(const Rect1, Rect2: TRect): Boolean;
begin
 Result:= (Rect1.Left < Rect2.Right)and(Rect1.Right > Rect2.Left)and
  (Rect1.Top < Rect2.Bottom)and(Rect1.Bottom > Rect2.Top);
end;

//---------------------------------------------------------------------------
function PointInTriangle(const Pos, v1, v2, v3: TPoint2px): Boolean;
var
 Aux: Integer;
begin
 Aux:= (Pos.y - v2.y) * (v3.x - v2.x) - (Pos.x - v2.x) * (v3.y - v2.y);

 Result:= (Aux * ((Pos.y - v1.y) * (v2.x - v1.x) - (Pos.x - v1.x) *
  (v2.y - v1.y)) > 0)and(Aux * ((Pos.y - v3.y) * (v1.x - v3.x) - (Pos.x -
  v3.x) * (v1.y - v3.y)) > 0);
end;

//---------------------------------------------------------------------------
function Lerp(x0, x1, Theta: Single): Single;
begin
 Result:= x0 + (x1 - x0) * Theta;
end;

//---------------------------------------------------------------------------
function CatmullRom(x0, x1, x2, x3, Theta: Single): Single;
begin
 Result:= 0.5 * ((2.0 * x1) + Theta * (-x0 + x2 + Theta * (2.0 * x0 - 5.0 *
  x1 + 4.0 * x2 - x3 + Theta * (-x0 + 3.0 * x1 - 3.0 * x2 + x3))));
end;

//---------------------------------------------------------------------------
function MoveRect(const Rect: TRect; const Point: TPoint2px): TRect;
begin
 Result.Left  := Rect.Left   + Point.x;
 Result.Top   := Rect.Top    + Point.y;
 Result.Right := Rect.Right  + Point.x;
 Result.Bottom:= Rect.Bottom + Point.y;
end;

//---------------------------------------------------------------------------
function ShortRect(const Rect1, Rect2: TRect): TRect;
begin
 Result.Left  := Max2(Rect1.Left, Rect2.Left);
 Result.Top   := Max2(Rect1.Top, Rect2.Top);
 Result.Right := Min2(Rect1.Right, Rect2.Right);
 Result.Bottom:= Min2(Rect1.Bottom, Rect2.Bottom);
end;

//---------------------------------------------------------------------------
function ShrinkRect(const Rect: TRect; hIn, vIn: Integer): TRect;
begin
 Result.Left:= Rect.Left + hIn;
 Result.Top:= Rect.Top + vIn;
 Result.Right:= Rect.Right - hIn;
 Result.Bottom:= Rect.Bottom - vIn;
end;

//---------------------------------------------------------------------------
function MinMax2(Value, Min, Max: Integer): Integer;
{$ifdef AsmIntelX86}
{$ifdef fpc} assembler;{$endif}
asm // 32-bit assembly
 cmp eax, edx
 cmovl eax, edx
 cmp eax, ecx
 cmovg eax, ecx
end;
{$else !AsmIntelX86}
begin // native pascal code
 Result:= Value;
 if (Result < Min) then Result:= Min;
 if (Result > Max) then Result:= Max;
end;
{$endif AsmIntelX86}

//---------------------------------------------------------------------------
function Min2(a, b: Integer): Integer;
{$ifdef AsmIntelX86}
{$ifdef fpc} assembler;{$endif}
asm // 32-bit assembly
 cmp edx, eax
 cmovl eax, edx
end;
{$else !AsmIntelX86}
begin // native pascal code
 Result:= a;
 if (b < Result) then Result:= b;
end;
{$endif AsmIntelX86}

//---------------------------------------------------------------------------
function Max2(a, b: Integer): Integer;
{$ifdef AsmIntelX86}
{$ifdef fpc} assembler;{$endif}
asm // 32-bit assembly
 cmp edx, eax
 cmovg eax, edx
end;
{$else !AsmIntelX86}
begin // native pascal code
 Result:= a;
 if (b > Result) then Result:= b;
end;
{$endif AsmIntelX86}

//---------------------------------------------------------------------------
function Min3(a, b, c: Integer): Integer;
{$ifdef AsmIntelX86}
{$ifdef fpc} assembler;{$endif}
asm // 32-bit assembly
 cmp edx, eax
 cmovl eax, edx
 cmp ecx, eax
 cmovl eax, ecx
end;
{$else !AsmIntelX86}
begin // native pascal code
 Result:= a;
 if (b < Result) then Result:= b;
 if (c < Result) then Result:= c;
end;
{$endif AsmIntelX86}

//---------------------------------------------------------------------------
function Max3(a, b, c: Integer): Integer;
{$ifdef AsmIntelX86}
{$ifdef fpc} assembler;{$endif}
asm // 32-bit assembly
 cmp   edx, eax
 cmovg eax, edx
 cmp   ecx, eax
 cmovg eax, ecx
end;
{$else !AsmIntelX86}
begin // native pascal code
 Result:= a;
 if (b > Result) then Result:= b;
 if (c > Result) then Result:= c;
end;
{$endif AsmIntelX86}

//---------------------------------------------------------------------------
function IsPowerOfTwo(Value: Integer): Boolean;
begin
 Result:= (Value >= 1)and((Value and (Value - 1)) = 0);
end;

//---------------------------------------------------------------------------
function CeilPowerOfTwo(Value: Integer): Integer;
begin
 Result:= Round(Power(2.0, Ceil(Log2(Value))))
end;

//---------------------------------------------------------------------------
function FloorPowerOfTwo(Value: Integer): Integer;
begin
 Result:= Round(Power(2.0, Floor(Log2(Value))))
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Pixel Helper Functions'}

//----------------------------------------------------------------------------
function DisplaceRB(Color: Cardinal): Cardinal;
begin
 Result:= ((Color and $FF) shl 16) or (Color and $FF00FF00) or
  ((Color shr 16) and $FF);
end;

//---------------------------------------------------------------------------
function BlendPixels(Color1, Color2: Cardinal; Alpha: Integer): Cardinal;
begin
 Result:=
  // Blue Component
  Cardinal(Integer(Color1 and $FF) + (((Integer(Color2 and $FF) -
  Integer(Color1 and $FF)) * Alpha) div 255)) or

  // Green Component
  (Cardinal(Integer((Color1 shr 8) and $FF) +
  (((Integer((Color2 shr 8) and $FF) - Integer((Color1 shr 8) and $FF)) *
  Alpha) div 255)) shl 8) or

  // Red Component
  (Cardinal(Integer((Color1 shr 16) and $FF) +
  (((Integer((Color2 shr 16) and $FF) - Integer((Color1 shr 16) and $FF)) *
  Alpha) div 255)) shl 16) or

  // Alpha Component
  (Cardinal(Integer((Color1 shr 24) and $FF) +
  (((Integer((Color2 shr 24) and $FF) - Integer((Color1 shr 24) and $FF)) *
  Alpha) div 255)) shl 24);
end;

//---------------------------------------------------------------------------
function LerpPixels(Color1, Color2: Cardinal; Alpha: Single): Cardinal;
begin
 Result:=
  // Blue component
  Cardinal(Integer(Color1 and $FF) + Round((Integer(Color2 and $FF) -
  Integer(Color1 and $FF)) * Alpha)) or

  // Green component
  (Cardinal(Integer((Color1 shr 8) and $FF) +
  Round((Integer((Color2 shr 8) and $FF) - Integer((Color1 shr 8) and $FF)) *
  Alpha)) shl 8) or

  // Red component
  (Cardinal(Integer((Color1 shr 16) and $FF) +
  Round((Integer((Color2 shr 16) and $FF) - Integer((Color1 shr 16) and $FF)) *
  Alpha)) shl 16) or

  // Alpha component
  (Cardinal(Integer((Color1 shr 24) and $FF) +
  Round((Integer((Color2 shr 24) and $FF) - Integer((Color1 shr 24) and $FF)) *
  Alpha)) shl 24);
end;

//---------------------------------------------------------------------------
function AvgPixels(Color1, Color2: Cardinal): Cardinal;
begin
 Result:=
  // Blue component
  (((Color1 and $FF) + (Color2 and $FF)) div 2) or

  // Green component
  (((((Color1 shr 8) and $FF) + ((Color2 shr 8) and $FF)) div 2) shl 8) or

  // Red component
  (((((Color1 shr 16) and $FF) + ((Color2 shr 16) and $FF)) div 2) shl 16) or

  // Alpha component
  (((((Color1 shr 24) and $FF) + ((Color2 shr 24) and $FF)) div 2) shl 24);
end;

//---------------------------------------------------------------------------
function AvgFourPixels(Color1, Color2, Color3, Color4: Cardinal): Cardinal;
begin
 Result:=
  // Blue component
  (((Color1 and $FF) + (Color2 and $FF) + (Color3 and $FF) +
  (Color4 and $FF)) div 4) or

  // Green component
  (((((Color1 shr 8) and $FF) + ((Color2 shr 8) and $FF) +
  ((Color3 shr 8) and $FF) + ((Color4 shr 8) and $FF)) div 4) shl 8) or

  // Red component
  (((((Color1 shr 16) and $FF) + ((Color2 shr 16) and $FF) +
  ((Color3 shr 16) and $FF) + ((Color4 shr 16) and $FF)) div 4) shl 16) or

  // Alpha component
  (((((Color1 shr 24) and $FF) + ((Color2 shr 24) and $FF) +
  ((Color3 shr 24) and $FF) + ((Color4 shr 24) and $FF)) div 4) shl 24);
end;

//---------------------------------------------------------------------------
function AvgSixPixels(Color1, Color2, Color3, Color4, Color5,
 Color6: Cardinal): Cardinal;
begin
 Result:=
  // Blue component
  (((Color1 and $FF) + (Color2 and $FF) + (Color3 and $FF) +
  (Color4 and $FF) + (Color5 and $FF) + (Color6 and $FF)) div 6) or

  // Green component
  (((((Color1 shr 8) and $FF) + ((Color2 shr 8) and $FF) +
  ((Color3 shr 8) and $FF) + ((Color4 shr 8) and $FF) +
  ((Color5 shr 8) and $FF) + ((Color6 shr 8) and $FF)) div 6) shl 8) or

  // Red component
  (((((Color1 shr 16) and $FF) + ((Color2 shr 16) and $FF) +
  ((Color3 shr 16) and $FF) + ((Color4 shr 16) and $FF) +
  ((Color5 shr 16) and $FF) + ((Color6 shr 16) and $FF)) div 6) shl 16) or

  // Alpha component
  (((((Color1 shr 24) and $FF) + ((Color2 shr 24) and $FF) +
  ((Color3 shr 24) and $FF) + ((Color4 shr 24) and $FF) +
  ((Color5 shr 24) and $FF) + ((Color6 shr 24) and $FF)) div 6) shl 24);
end;

//---------------------------------------------------------------------------
function AddPixels(Color1, Color2: Cardinal): Cardinal;
begin
 Result:=
  // Blue Component
  Cardinal(Min2(Integer(Color1 and $FF) + Integer(Color2 and $FF), 255)) or

  // Green Component
  (Cardinal(Min2(Integer((Color1 shr 8) and $FF) +
   Integer((Color2 shr 8) and $FF), 255)) shl 8) or

  // Blue Component
  (Cardinal(Min2(Integer((Color1 shr 16) and $FF) +
   Integer((Color2 shr 16) and $FF), 255)) shl 16) or

  // Alpha Component
  (Cardinal(Min2(Integer((Color1 shr 24) and $FF) +
   Integer((Color2 shr 24) and $FF), 255)) shl 24);
end;

//---------------------------------------------------------------------------
function MulPixels(Color1, Color2: Cardinal): Cardinal;
begin
 Result:=
  // Blue Component
  Cardinal((Integer(Color1 and $FF) * Integer(Color2 and $FF)) div 255) or

  // Green Component
  (Cardinal((Integer((Color1 shr 8) and $FF) *
   Integer((Color2 shr 8) and $FF)) div 255) shl 8) or

  // Blue Component
  (Cardinal((Integer((Color1 shr 16) and $FF) *
   Integer((Color2 shr 16) and $FF)) div 255) shl 16) or

  // Alpha Component
  (Cardinal((Integer((Color1 shr 24) and $FF) *
   Integer((Color2 shr 24) and $FF)) div 255) shl 24);
end;

//---------------------------------------------------------------------------
function MulPixelAlpha(Color: Cardinal; Alpha: Integer): Cardinal; overload;
begin
 Result:= (Color and $00FFFFFF) or
  Cardinal((Integer(Color shr 24) * Alpha) div 255) shl 24;
end;

//---------------------------------------------------------------------------
function MulPixelAlpha(Color: Cardinal; Alpha: Single): Cardinal; overload;
begin
 Result:= (Color and $00FFFFFF) or
  Cardinal(Round(Integer(Color shr 24) * Alpha)) shl 24;
end;

//---------------------------------------------------------------------------
function PixelToGray(Pixel: Cardinal): Integer;
begin
 Result:=
  ((Integer(Pixel and $FF) * 5) +
  (Integer((Pixel shr 8) and $FF) * 8) +
  (Integer((Pixel shr 16) and $FF) * 3)) div 16;
end;

//---------------------------------------------------------------------------
function PixelToGrayEx(Pixel: Cardinal): Single;
begin
 Result:= ((Pixel and $FF) * 0.3 + ((Pixel shr 8) and $FF) * 0.59 +
  ((Pixel shr 16) and $FF) * 0.11) / 255.0;
end;

//---------------------------------------------------------------------------
procedure ExtractAlpha(Src1, Src2, Bk1, Bk2: Single; out Alpha,
 Px: Single);
begin
 Alpha:= (1.0 - (Src2 - Src1)) / (Bk2 - Bk1);

 Px:= Src1;

 if (Alpha > 0.0) then
  Px:= (Src1 - (1.0 - Alpha) * Bk1) / Alpha;
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'YIQ Color Helper Functions'}

//---------------------------------------------------------------------------
{$define Asphyre_Implementation}
 {$include Asphyre.YIQColors.inc}
{$undef Asphyre_Implementation}

//---------------------------------------------------------------------------
{$ENDREGION}

//---------------------------------------------------------------------------
end.
