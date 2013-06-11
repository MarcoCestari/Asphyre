//---------------------------------------------------------------------------
// YIQColors.inc
// YIQ color space utilities for Asphyre.
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

{$ifdef Asphyre_Interface}

//---------------------------------------------------------------------------
type
{ Color defined in NTSC transmission YIQ color space as chroma, luminance
  and alpha-channel, which can be useful for manipulating color shades. }
 TYIQColor = record
  // Luminance (related to perceived brightness).
  y: Single;
  // Chroma (concurrently describes color hue).
  i, q: Single;
  // Alpha (transparency).
  a: Single;
 end;

//---------------------------------------------------------------------------
{ Color defined in a cylindrical variant of YIQ color space as described in
  "An alternative color space for color selection and image manipulation" }
 TYCHiqColor = record
  // Luminance (related to perceived brightness).
  y: Single;
  // Chroma (related somewhat to "purity" of the color).
  C: Single;
  // Hue (in radians).
  h: Single;
  // Alpha (transparency).
  a: Single;
 end;

//---------------------------------------------------------------------------
{ Constructs a new value in YIQ color space. }
function YIQColor(y, i, q: Single): TYIQColor;
{ Constructs a new value in cylindrical variant of YIQ color space. }
function YCHiqColor(y, C, h: Single): TYCHiqColor;

//---------------------------------------------------------------------------
{ Converts normal RGB color value into YIQ color space. }
function RGBtoYIQ(Color: Cardinal): TYIQColor;
{ Converts YIQ color space value back to RGB (clamping, if necessary). }
function YIQtoRGB(const Color: TYIQColor): Cardinal;

//---------------------------------------------------------------------------
{ Converts YIQ color space value to its cylindrical variant YCH. }
function YIQtoYCHiq(const Color: TYIQColor): TYCHiqColor;
{ Converts cylindrical YIQ color space value to back to cartesian variant. }
function YCHiqToYIQ(const Color: TYCHiqColor): TYIQColor;

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
function YIQColor(y, i, q: Single): TYIQColor;
begin
 Result.y:= y;
 Result.i:= i;
 Result.q:= q;
 Result.a:= 1.0;
end;

//---------------------------------------------------------------------------
function YCHiqColor(y, C, h: Single): TYCHiqColor;
begin
 Result.y:= y;
 Result.C:= C;
 Result.h:= h;
 Result.a:= 1.0;
end;

//---------------------------------------------------------------------------
function RGBtoYIQ(Color: Cardinal): TYIQColor;
var
 r, g, b: Single;
begin
 b:= (Color and $FF) / 255.0;
 g:= ((Color shr 8) and $FF) / 255.0;
 r:= ((Color shr 16) and $FF) / 255.0;

 Result.y:= 0.29889531 * r +  0.58662247 * g +  0.11448223 * b;
 Result.i:= 0.59597799 * r + -0.27417610 * g + -0.32180189 * b;
 Result.q:= 0.21147017 * r + -0.52261711 * g +  0.31114694 * b;
 Result.a:= ((Color shr 24) and $FF) / 255.0;
end;

//---------------------------------------------------------------------------
function YIQtoRGB(const Color: TYIQColor): Cardinal;
var
 Red, Green, Blue: Integer;
begin
 Red:= MinMax2(Round((Color.y + 0.95608445 * Color.i + 0.62088850 * Color.q) *
  255.0), 0, 255);

 Green:= MinMax2(Round((Color.y - 0.27137664 * Color.i - 0.64860590 * Color.q) *
  255.0), 0, 255);

 Blue:= MinMax2(Round((Color.y - 1.10561724 * Color.i + 1.70250126 * Color.q) *
  255.0), 0, 255);

 Result:= Cardinal(Blue) or (Cardinal(Green) shl 8) or
  (Cardinal(Red) shl 16) or (Cardinal(Round(Color.a * 255.0)) shl 24);
end;

//---------------------------------------------------------------------------
function YIQtoYCHiq(const Color: TYIQColor): TYCHiqColor;
begin
 Result.y:= Color.y;
 Result.C:= Sqrt(Sqr(Color.i) + Sqr(Color.q));
 Result.h:= ArcTan2(Color.q, Color.i);
 Result.a:= Color.a;
end;

//---------------------------------------------------------------------------
function YCHiqToYIQ(const Color: TYCHiqColor): TYIQColor;
begin
 Result.y:= Color.y;
 Result.i:= Color.C * Cos(Color.h);
 Result.q:= Color.C * Sin(Color.h);
 Result.a:= Color.a;
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
