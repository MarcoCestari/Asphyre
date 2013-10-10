unit Asphyre.Canvas.GL2.Shaders;
//---------------------------------------------------------------------------
// GLSL source code for modern Asphyre OpenGL canvas.
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
const
 VertexShaderSource: AnsiString =
  '#version 110'#13#10 +
  'attribute vec2 InpVertex; attribute vec2 InpTexCoord; attribute vec4 InpColor;'#13#10 +
  'varying vec4 VarCol; varying vec2 VarTex;'#13#10 +
  'void main() { gl_Position = vec4(InpVertex, 0.0, 1.0); VarCol = InpColor; VarTex = InpTexCoord; }' + #0;

//---------------------------------------------------------------------------
 PixelShaderSolidSource: AnsiString =
  '#version 110'#13#10 +
  'varying vec4 VarCol;'#13#10 +
  'void main() { if (VarCol.w < 0.00390625) discard; gl_FragColor = VarCol; }' + #0;

//---------------------------------------------------------------------------
 PixelShaderTexturedSource: AnsiString =
  '#version 110'#13#10 +
  'uniform sampler2D SourceTex;'#13#10 +
  'varying vec4 VarCol; varying vec2 VarTex;'#13#10 +
  'void main() { vec4 TempCol = texture2D(SourceTex, VarTex) * VarCol; if (TempCol.w < 0.00390625) discard; gl_FragColor = TempCol; }' + #0;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
end.
