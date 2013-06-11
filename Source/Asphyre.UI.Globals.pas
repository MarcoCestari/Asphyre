unit Asphyre.UI.Globals;
//---------------------------------------------------------------------------
// Global definitions and utilities for Asphyre GUI framework.
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
 System.Types, Asphyre.TypeDef, Asphyre.Math, Asphyre.Types, Asphyre.Images, 
 Asphyre.Fonts;

//---------------------------------------------------------------------------
var
 // Border of the windows, controls, etc.
 GuiBorderColor: LongWord;

 // The color of the focus inside the control such as edit box.
 GuiCtrlFocusColor: LongWord;

 // The color of the focus in the controls such as buttons, etc.
 GuiButtonFocusColor: LongWord;

 // The color of the "selected" area in list box, etc.
 GuiPointedColor: TColor4;

 // Item selection color for list box.
 GuiItemSelectColor: TColor4;

 // The color inside of the controls such as edit box, etc.
 GuiCtrlFillColor: TColor4;

 // The color of the editing caret.
 GuiCaretColor: LongWord;

 // The color of the selected text in edit box.
 GuiEditSelectColor: LongWord;

 // The color of the enabled text.
 GuiTextEnabledColor: TColor2;

 // The color of the disabled text (will appear as 3D effect).
 GuiTextDisabledColor: TColor2;

 // The outer button border which improve 3D illusion of the button.
 GuiButtonOuterColor: TColor4;

 // The button's fill color when the control is enabled.
 GuiButtonEnabledColor: TColor4;

 // The button's fill color when the control is disabled.
 GuiButtonDisabledColor: TColor4;

 // The global transparency of all GUI controls.
 GuiGlobalAlpha: Single = 1.0;

// The size of the transparent border that indicates control has focus.
 GuiFocusDrawBorder: Integer = 3;

// How to shift the luma of the button being clicked on. Negative values
// make it appear darker while positive values make it appear brighter.
 GuiButtonDownLumaShift: Single = -0.1;

// The color of the system icons that appear on scrollbar buttons.
 GuiSystemIconColor: LongWord;

// The overall transparency of a disabled button.
 GuiButtonDisabledAlpha: Single = 0.5;

// The filler color of the scrollbar's scrolling area.
 GuiScrollBarFillColor: TColor4;

// How opaque the shadow is for the glyphs rendered in buttons and list boxes.
 GuiGlyphShadowAlpha: Single = 0.0;

// The number of subdivisions made for rendering radio button's image.
 GuiRadioButtonQuality: Integer = 24;

// The color of the "checked" circle inside the radio button when enabled.
 GuiEnabledCheckedColor: LongWord;

// The color of the "checked" circle inside the radio button when disabled.
 GuiDisabledCheckedColor: LongWord;

// How thin or thick is the checkbox "check" icon.
 GuiCheckBoxAnisotropy: Single = 0.25;

// The height of the focus underline for check boxes and radio buttons.
 GuiTextFocusHeight: Integer = 3;

// The displacement of focus underline behind the text.
 GuiTextFocusDelta: Integer = -2;

// The color of the default form's icon. 
 GuiFormIconColor: LongWord;

// The color of the window's border. 
 GuiFormBorderColor: LongWord;

// The fill color inside the window's client area. 
 GuiFormFillColor: TColor4;

// The following variables indicate the color of the title's fill area
// depending on whether the window is active or not.
 GuiFormActiveTitleFill  : TColor4;
 GuiFormInactiveTitleFill: TColor4;

// The following variables indicate the color of the title's text depending
// on whether the window is active or not. 
 GuiFormActiveTitleColor  : TColor2;
 GuiFormInactiveTitleColor: TColor2;

// The default font name for the GUI controls, if not specified.
 GuiDefaultFontName: StdString = 'Tahoma';

// The default font index for the GUI controls, if not specified.
 GuiDefaultFontIndex: Integer = -1;

// The background color when only taskbar is shown in GUI Designer.
 GuiTaskbarBackground: LongWord;

//---------------------------------------------------------------------------
 GuiScrollDragCancelTreshold: Integer = 64;

//---------------------------------------------------------------------------
function RetrieveGuiFont(const FontName: StdString): TAsphyreFont;
procedure GuiDrawControlFill(const PaintRect: TRect; DrawAlpha: Single = 1.0);
procedure GuiDrawCtrlFocus(const PaintRect: TRect; FocusAlpha: Integer);
procedure GuiDrawButtonFocus(const PaintRect: TRect; FocusAlpha: Integer);
procedure GuiDrawControlBorder(const PaintRect: TRect;
 BorderAlpha: Single = 1.0);
procedure GuiDrawItemSelection(const SelectRect: TRect; SelAlpha: Single);
procedure GuiDrawItemPointed(const PointedRect: TRect; PointAlpha: Single);
procedure GuiDrawOuterBorder(var PaintRect: TRect; OutAlpha: Single);

procedure GuiDraw3DFill(const DrawRect: TRect; const Color4: TColor4);
procedure GuiDrawButtonFill(const PaintRect: TRect; ButtonAlpha: Single = 1.0;
 EnabledAlpha: Integer = 255; DownAlpha: Integer = 0);

procedure GuiDrawButtonFillInside(const PaintRect: TRect;
 ButtonAlpha: Single = 1.0; EnabledAlpha: Integer = 255;
 DownAlpha: Integer = 0);

procedure GuiDrawGlyph(const DrawAt: TPoint2px; Glyph: TAsphyreImage;
 Pattern: Integer; GlyphAlpha: Single = 1.0; EnabledAlpha: Integer = 255;
 DownAlpha: Integer = 0);

procedure GuiDrawControlText(const DrawAt: TPoint2px; const Text: UniString;
 TextFont: TAsphyreFont; TextAlpha: Single = 1.0; EnabledAlpha: Integer = 255;
 DownAlpha: Integer = 0; FocusAlpha: Integer = 0);

procedure GuiDrawCustomText(const DrawAt: TPoint2px; const Text: UniString;
 TextFont: TAsphyreFont; const EnabledColor, DisabledColor: TColor2;
 TextAlpha: Single = 1.0; EnabledAlpha: Integer = 255);

procedure GuiPaintSystemIcon(const PaintRect: TRect; IconNo: Integer;
 IconAlpha: Single = 1.0; EnabledAlpha: Integer = 255;
 DownAlpha: Integer = 0);

procedure GuiDrawRadioButton(const PaintRect: TRect; ButtonAlpha: Single = 1.0;
 EnabledAlpha: Integer = 255; DownAlpha: Integer = 0; FocusAlpha: Integer = 0;
 CheckedAlpha: Integer = 0);

procedure GuiDrawCheckIcon(const PaintRect: TRect; ButtonAlpha: Single = 1.0;
 EnabledAlpha: Integer = 255; DownAlpha: Integer = 0;
 CheckedAlpha: Integer = 0);

//---------------------------------------------------------------------------
function GuiComputeTheta(SrcAlpha: Integer): Single;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Canvas, Asphyre.UI.Types;

//------------------------------------------------------------7---------------
function RetrieveGuiFont(const FontName: StdString): TAsphyreFont;
var
 Index: Integer;
begin
 if (Length(FontName) < 1)and(GuiDefaultFontIndex <> -1) then
  begin
   Result:= GuiFonts[GuiDefaultFontIndex];
   Exit;
  end;

 Index:= GuiFonts.Resolve(FontName);
 if (Index = -1) then Index:= GuiFonts.Resolve(GuiDefaultFontName);

 if (Index = -1)and(GuiFonts.Count > 0) then Index:= 0;

 Result:= nil;
 if (Index <> -1) then Result:= GuiFonts[Index];
end;

//---------------------------------------------------------------------------
procedure GuiDrawControlFill(const PaintRect: TRect; DrawAlpha: Single = 1.0);
begin
 GuiCanvas.FillQuad(pRect4(PaintRect), cColor4Alpha1f(GuiCtrlFillColor,
  GuiGlobalAlpha * DrawAlpha));

 GuiCanvas.FrameRect(RectExtrude(PaintRect),
  cColor4Alpha1f(ExchangeColors(GuiCtrlFillColor), GuiGlobalAlpha));
end;

//---------------------------------------------------------------------------
procedure GuiDrawFocusRect(const PaintRect: TRect; const FocusColor: Cardinal;
 FocusAlpha: Integer);
var
 DrawSize: TPoint2px;
 FocAlpha : Single;
 FocColor, FocBlank: Cardinal;
begin
 DrawSize.x:= PaintRect.Right - PaintRect.Left;
 DrawSize.y:= PaintRect.Bottom - PaintRect.Top;

 FocAlpha:= SineTheta(FocusAlpha / 255.0);
 FocColor:= cColorAlpha1f(FocusColor, FocAlpha);
 FocBlank:= cColorAlpha1f(FocusColor, 0.0);

 GuiCanvas.FillQuad(Point4(
  PaintRect.Left + 1, PaintRect.Top + 1,
  PaintRect.Left + DrawSize.x - 1, PaintRect.Top + 1,
  PaintRect.Left + DrawSize.x - (GuiFocusDrawBorder + 1),
   PaintRect.Top + (GuiFocusDrawBorder + 1),
  PaintRect.Left + GuiFocusDrawBorder + 1,
   PaintRect.Top + GuiFocusDrawBorder + 1),
  cColor4(FocColor, FocColor, FocBlank, FocBlank));

 GuiCanvas.FillQuad(Point4(
  PaintRect.Left + 1, PaintRect.Top + 1,
  PaintRect.Left + GuiFocusDrawBorder + 1,
   PaintRect.Top + GuiFocusDrawBorder + 1,
  PaintRect.Left + GuiFocusDrawBorder + 1,
   PaintRect.Top + DrawSize.y - (GuiFocusDrawBorder + 1),
  PaintRect.Left + 1, PaintRect.Top + DrawSize.y - 1),
  cColor4(FocColor, FocBlank, FocBlank, FocColor));

 GuiCanvas.FillQuad(Point4(
  PaintRect.Left + DrawSize.x - 1, PaintRect.Top + 1,
  PaintRect.Left + DrawSize.x - (GuiFocusDrawBorder + 1),
   PaintRect.Top + GuiFocusDrawBorder + 1,
  PaintRect.Left + DrawSize.x - (GuiFocusDrawBorder + 1),
   PaintRect.Top + DrawSize.y - (GuiFocusDrawBorder + 1),
  PaintRect.Left + DrawSize.x - 1, PaintRect.Top + DrawSize.y - 1),
  cColor4(FocColor, FocBlank, FocBlank, FocColor));

 GuiCanvas.FillQuad(Point4(
  PaintRect.Left + 1, PaintRect.Top + DrawSize.y - 1,
  PaintRect.Left + GuiFocusDrawBorder + 1,
   PaintRect.Top + DrawSize.y - (GuiFocusDrawBorder + 1),
  PaintRect.Left + DrawSize.x - (GuiFocusDrawBorder + 1),
   PaintRect.Top + DrawSize.y - (GuiFocusDrawBorder + 1),
  PaintRect.Left + DrawSize.x - 1, PaintRect.Top + DrawSize.y - 1),
  cColor4(FocColor, FocBlank, FocBlank, FocColor));
end;

//---------------------------------------------------------------------------
procedure GuiDrawCtrlFocus(const PaintRect: TRect; FocusAlpha: Integer);
begin
 GuiDrawFocusRect(PaintRect, GuiCtrlFocusColor, FocusAlpha);
end;

//---------------------------------------------------------------------------
procedure GuiDrawButtonFocus(const PaintRect: TRect; FocusAlpha: Integer);
begin
 GuiDrawFocusRect(PaintRect, GuiButtonFocusColor, FocusAlpha);
end;

//---------------------------------------------------------------------------
procedure GuiDrawControlBorder(const PaintRect: TRect;
 BorderAlpha: Single = 1.0);
begin
 GuiCanvas.FrameRect(pRect4(PaintRect), cColor4(cColorAlpha1f(GuiBorderColor,
  GuiGlobalAlpha * BorderAlpha)));
end;

//---------------------------------------------------------------------------
procedure GuiDrawItemSelection(const SelectRect: TRect; SelAlpha: Single);
begin
 GuiCanvas.FillQuad(pRect4(SelectRect), cColor4Alpha1f(GuiItemSelectColor,
  GuiGlobalAlpha * SelAlpha));

 GuiCanvas.FrameRect(pRect4(SelectRect),
  cColor4Alpha1f(ExchangeColors(GuiItemSelectColor), GuiGlobalAlpha *
   SelAlpha));
end;

//---------------------------------------------------------------------------
procedure GuiDrawItemPointed(const PointedRect: TRect; PointAlpha: Single);
begin
 GuiCanvas.FillQuad(pRect4(PointedRect), cColor4Alpha1f(GuiPointedColor,
  GuiGlobalAlpha * PointAlpha));

 GuiCanvas.FrameRect(pRect4(PointedRect),
  cColor4Alpha1f(ExchangeColors(GuiPointedColor), GuiGlobalAlpha * PointAlpha));
end;

//---------------------------------------------------------------------------
procedure GuiDrawOuterBorder(var PaintRect: TRect; OutAlpha: Single);
begin
 if (cGetMaxAlpha4(GuiButtonOuterColor) <= 0) then Exit;

 GuiCanvas.FillQuad(pRect4(PaintRect), cColor4Alpha1f(GuiButtonOuterColor,
  GuiGlobalAlpha * OutAlpha));

 PaintRect:= ShrinkRect(PaintRect, 1, 1);
end;

//---------------------------------------------------------------------------
procedure GuiDraw3DFill(const DrawRect: TRect; const Color4: TColor4);
begin
 GuiCanvas.FillQuad(pRect4(DrawRect), Color4);

 GuiCanvas.VertLine(DrawRect.Right - 1, DrawRect.Top,
  DrawRect.Bottom - DrawRect.Top, Color4[2]);

 GuiCanvas.HorizLine(DrawRect.Left, DrawRect.Bottom - 1,
  DrawRect.Right - DrawRect.Left, Color4[2]);

 GuiCanvas.VertLine(DrawRect.Left, DrawRect.Top,
  DrawRect.Bottom - DrawRect.Top, Color4[0]);

 GuiCanvas.HorizLine(DrawRect.Left, DrawRect.Top,
  DrawRect.Right - DrawRect.Left, Color4[0]);
end;

//---------------------------------------------------------------------------
procedure GuiDrawButtonFill(const PaintRect: TRect; ButtonAlpha: Single = 1.0;
 EnabledAlpha: Integer = 255; DownAlpha: Integer = 0);
var
 DownTheta: Single;
 EnAlpha  : Single;
 GlobAlpha: Single;
 ButColor : TColor4;
begin
 DownTheta:= SineTheta(DownAlpha / 255.0);
 EnAlpha  := SineTheta(EnabledAlpha / 255.0);
 GlobAlpha:= GuiGlobalAlpha * ButtonAlpha;

 if (EnAlpha > 0.0) then
  begin
   if (DownTheta > 0.0) then
    begin
     ButColor:=
      cColor4Alpha1f(cAdjustLuma4(ExchangeColors(GuiButtonEnabledColor),
      GuiButtonDownLumaShift), DownTheta * EnAlpha * GlobAlpha);

     GuiDraw3DFill(PaintRect, ButColor);
    end;

   if (DownTheta < 1.0) then
    begin
     ButColor:= cColor4Alpha1f(GuiButtonEnabledColor, (1.0 - DownTheta) *
      EnAlpha * GlobAlpha);

     GuiDraw3DFill(PaintRect, ButColor);
    end;
  end;

 if (EnAlpha < 1.0) then
  begin
   ButColor:= cColor4Alpha1f(GuiButtonDisabledColor, (1.0 - EnAlpha) *
    GlobAlpha);

   GuiDraw3DFill(PaintRect, ButColor);
  end;
end;

//---------------------------------------------------------------------------
procedure GuiDrawButtonFillInside(const PaintRect: TRect;
 ButtonAlpha: Single = 1.0; EnabledAlpha: Integer = 255;
 DownAlpha: Integer = 0);
var
 DownTheta: Single;
 EnAlpha  : Single;
 GlobAlpha: Single;
 ButColor : TColor4;
begin
 DownTheta:= SineTheta(DownAlpha / 255.0);
 EnAlpha  := SineTheta(EnabledAlpha / 255.0);
 GlobAlpha:= GuiGlobalAlpha * ButtonAlpha;

 if (EnAlpha > 0.0) then
  begin
   if (DownTheta > 0.0) then
    begin
     ButColor:=
      cColor4Alpha1f(cAdjustLuma4(GuiCtrlFillColor, GuiButtonDownLumaShift),
      DownTheta * EnAlpha * GlobAlpha);

     GuiDraw3DFill(PaintRect, ButColor);
    end;

   if (DownTheta < 1.0) then
    begin
     ButColor:= cColor4Alpha1f(GuiCtrlFillColor, (1.0 - DownTheta) *
      EnAlpha * GlobAlpha);

     GuiDraw3DFill(PaintRect, ButColor);
    end;
  end;

 if (EnAlpha < 1.0) then
  begin
   ButColor:= cColor4Alpha1f(GuiButtonDisabledColor, (1.0 - EnAlpha) *
    GlobAlpha);

   GuiDraw3DFill(PaintRect, ButColor);
  end;
end;

//---------------------------------------------------------------------------
procedure GuiDrawGlyph(const DrawAt: TPoint2px; Glyph: TAsphyreImage;
 Pattern: Integer; GlyphAlpha: Single = 1.0; EnabledAlpha: Integer = 255;
 DownAlpha: Integer = 0);
var
 DrawPos  : TPoint2;
 DownTheta: Single;
 EnAlpha  : Single;
 GlobAlpha: Single;
 GlyphSize: TPoint2px;
 DarkColor: TColor4;
begin
 if (not Assigned(Glyph))or(Pattern < 0)or
  (Pattern >= Glyph.PatternCount) then Exit;

 DownTheta:= SineTheta(DownAlpha / 255.0);
 EnAlpha  := SineTheta(EnabledAlpha / 255.0);
 GlobAlpha:= GuiGlobalAlpha * GlyphAlpha;
 GlyphSize:= Glyph.VisibleSize;

 DrawPos.x:= DrawAt.x + DownTheta;
 DrawPos.y:= DrawAt.y + DownTheta;

 if (EnAlpha > 0.0)and(GuiGlyphShadowAlpha > 0.0) then
  begin
   GuiCanvas.UseImagePt(Glyph, Pattern);
   GuiCanvas.TexMap(pBounds4(DrawPos.x - 1, DrawPos.y - 1, GlyphSize.x + 3,
    GlyphSize.y + 3), cAlpha4f(GlobAlpha * EnAlpha * GuiGlyphShadowAlpha),
    beShadow);
  end;

 if (GuiGlyphShadowAlpha > 0.0) then
  begin
   GuiCanvas.UseImagePt(Glyph, Pattern);
   GuiCanvas.TexMap(pBounds4(DrawPos.x - 1, DrawPos.y - 1, GlyphSize.x + 3,
    GlyphSize.y + 3), cAlpha4f(GlobAlpha * GuiGlyphShadowAlpha),
    beShadow);
  end;

 if (EnAlpha > 0.0) then
  begin
   DarkColor:= cColor4(cColorAlpha1f(BlendPixels($FFFFFFFF, $FF000000,
    MinMax2(Round((-GuiButtonDownLumaShift * 4.0 * DownTheta) * 255.0), 0,
    255)), EnAlpha * GlobAlpha));

   GuiCanvas.UseImagePt(Glyph, Pattern);
   GuiCanvas.TexMap(pBounds4(DrawPos.x, DrawPos.y, GlyphSize.x, GlyphSize.y),
    DarkColor);
  end;

 if (EnAlpha < 1.0) then
  begin
   GuiCanvas.UseImagePt(Glyph, Pattern);
   GuiCanvas.TexMap(pBounds4(DrawPos.x, DrawPos.y, GlyphSize.x, GlyphSize.y),
    cColor4(cAlpha1f((1.0 - EnAlpha) * GlobAlpha * 0.75)));

   GuiCanvas.UseImagePt(Glyph, Pattern);
   GuiCanvas.TexMap(pBounds4(DrawPos.x - 1, DrawPos.y - 1, GlyphSize.x,
    GlyphSize.y), cColor4(cAlpha1f((1.0 - EnAlpha) * GlobAlpha * 0.5)),
    beShadow);
  end;
end;

//---------------------------------------------------------------------------
procedure GuiDrawControlText(const DrawAt: TPoint2px; const Text: UniString;
 TextFont: TAsphyreFont; TextAlpha: Single = 1.0; EnabledAlpha: Integer = 255;
 DownAlpha: Integer = 0; FocusAlpha: Integer = 0);
const
 FocusDelta = -2;
var
 DrawPos  : TPoint2;
 DownTheta: Single;
 EnAlpha  : Single;
 GlobAlpha: Single;
 TexColor : TColor2;
 AvgBkCol : Cardinal;
 AvgTxCol : Cardinal;
 GrayBk   : Single;
 GrayTx   : Single;
 TextSize : TPoint2px;
 Points   : array[0..7] of TPoint2;
 MidFocPt : Single;
 FocusIn  : Cardinal;
 FocusOut : Cardinal;
 FocTheta : Single;
 ClipRect: TRect;
begin
 DownTheta:= GuiComputeTheta(DownAlpha);
 EnAlpha  := GuiComputeTheta(EnabledAlpha);
 GlobAlpha:= GuiGlobalAlpha * TextAlpha;
 FocTheta := GuiComputeTheta(FocusAlpha);

 DrawPos.x:= DrawAt.x + DownTheta;
 DrawPos.y:= DrawAt.y + DownTheta;

 TextSize:= TextFont.TexExtent(Text);

 ClipRect:= GuiCanvas.ClipRect;

 GuiCanvas.ClipRect:= Bounds(ClipRect.Left, ClipRect.Top, ClipRect.Right -
  ClipRect.Left, (ClipRect.Bottom - ClipRect.Top) + TextSize.y +
  GuiTextFocusHeight + GuiTextFocusDelta);

 if (FocusAlpha > 0) then
  begin
   MidFocPt:= DrawAt.y + TextSize.y + GuiTextFocusHeight * 0.5 +
    GuiTextFocusDelta;

   Points[0]:= Point2(DrawAt.x, MidFocPt);
   Points[1]:= Point2(DrawAt.x + TextSize.x * 0.15, MidFocPt);
   Points[2]:= Point2(DrawAt.x + TextSize.x * 0.85, MidFocPt);
   Points[3]:= Point2(DrawAt.x + TextSize.x, MidFocPt);

   MidFocPt:= DrawAt.y + TextSize.y + GuiTextFocusDelta;

   Points[4]:= Point2(DrawAt.x + TextSize.x * 0.15, MidFocPt);
   Points[5]:= Point2(DrawAt.x + TextSize.x * 0.85, MidFocPt);

   MidFocPt:= DrawAt.y + TextSize.y + GuiTextFocusHeight + GuiTextFocusDelta;

   Points[6]:= Point2(DrawAt.x + TextSize.x * 0.15, MidFocPt);
   Points[7]:= Point2(DrawAt.x + TextSize.x * 0.85, MidFocPt);

   FocusIn := cColorAlpha1f(GuiCtrlFocusColor, GlobAlpha * FocTheta);
   FocusOut:= cColorAlpha1f(GuiCtrlFocusColor, 0.0);

   GuiCanvas.FillTri(
    Points[0], Points[4], Points[1], FocusOut, FocusOut, FocusIn);
   GuiCanvas.FillTri(
    Points[0], Points[1], Points[6], FocusOut, FocusIn, FocusOut);

   GuiCanvas.FillTri(
    Points[5], Points[3], Points[2], FocusOut, FocusOut, FocusIn);
   GuiCanvas.FillTri(
    Points[7], Points[2], Points[3], FocusOut, FocusIn, FocusOut);

   GuiCanvas.FillQuad(
    Point4(Points[4], Points[5], Points[2], Points[1]),
    cColor4(FocusOut, FocusOut, FocusIn, FocusIn));

   GuiCanvas.FillQuad(
    Point4(Points[1], Points[2], Points[7], Points[6]),
    cColor4(FocusIn, FocusIn, FocusOut, FocusOut));
  end;

 GuiCanvas.ClipRect:= ClipRect;

 if (EnAlpha > 0.0) then
  begin
   TexColor:= cAdjustLuma2(GuiTextEnabledColor, GuiButtonDownLumaShift *
    DownTheta);
   TextFont.TextOut(DrawPos, Text, TexColor, EnAlpha * GlobAlpha);
  end;

 if (EnAlpha < 1.0) then
  begin
   TextFont.TextOut(DrawPos, Text, GuiTextDisabledColor, (1.0 - EnAlpha) *
    GlobAlpha);

   AvgBkCol:= AvgFourPixels(GuiCtrlFillColor[0], GuiCtrlFillColor[1],
    GuiCtrlFillColor[2], GuiCtrlFillColor[3]);

   AvgTxCol:= AvgPixels(GuiTextDisabledColor[0], GuiTextDisabledColor[1]);

   GrayBk:= PixelToGrayEx(AvgBkCol);
   GrayTx:= PixelToGrayEx(AvgTxCol);

   if (Abs(GrayBk - GrayTx) > 0.25) then
    begin
     TextFont.TextOut(DrawPos - Point2(1.0, 1.0), Text, cColor2(AvgBkCol),
      (1.0 - EnAlpha) * GlobAlpha * 0.5);
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure GuiDrawCustomText(const DrawAt: TPoint2px; const Text: UniString;
 TextFont: TAsphyreFont; const EnabledColor, DisabledColor: TColor2;
 TextAlpha: Single = 1.0; EnabledAlpha: Integer = 255);
var
 EnAlpha  : Single;
 GlobAlpha: Single;
begin
 EnAlpha  := GuiComputeTheta(EnabledAlpha);
 GlobAlpha:= GuiGlobalAlpha * TextAlpha;

 if (EnAlpha > 0.0) then
  TextFont.TextOut(DrawAt, Text, EnabledColor, EnAlpha * GlobAlpha);

 if (EnAlpha < 1.0) then
  TextFont.TextOut(DrawAt, Text, DisabledColor, (1.0 - EnAlpha) * GlobAlpha);
end;

//---------------------------------------------------------------------------
procedure GuiPaintSystemIcon(const PaintRect: TRect; IconNo: Integer;
 IconAlpha: Single = 1.0; EnabledAlpha: Integer = 255;
 DownAlpha: Integer = 0);
var
 DownTheta: Single;
 GlobAlpha: Single;
 DrawAt, DrawSize, MidPt: TPoint2px;
 DrawColor: Cardinal;
 i: Integer;
begin
 DownTheta:= SineTheta(DownAlpha / 255.0);
 GlobAlpha:= GuiGlobalAlpha * IconAlpha;

 DrawAt.x:= PaintRect.Left;
 DrawAt.y:= PaintRect.Top;

 DrawSize.x:= PaintRect.Right - PaintRect.Left;
 DrawSize.y:= PaintRect.Bottom - PaintRect.Top;

 MidPt.x:= DrawAt.x + (DrawSize.x div 2);
 MidPt.y:= DrawAt.y + (DrawSize.y div 2);

 DrawColor:= cColorAlpha1f(cAdjustLuma1(GuiSystemIconColor,
  GuiButtonDownLumaShift * DownTheta), GlobAlpha);

 case IconNo of
  0: // Up Arrow
   begin
    GuiCanvas.FillTri(
     Point2(MidPt.x, MidPt.y + 3),
     Point2(MidPt.x, MidPt.y - 3),
     Point2(MidPt.x + 5, MidPt.y + 3),
     DrawColor, DrawColor, DrawColor);

    GuiCanvas.FillTri(
     Point2(MidPt.x, MidPt.y + 3),
     Point2(MidPt.x, MidPt.y - 3),
     Point2(MidPt.x - 5, MidPt.y + 3),
     DrawColor, DrawColor, DrawColor);
   end;

  1: // Down Arrow
   begin
    GuiCanvas.FillTri(
     Point2(MidPt.x, MidPt.y - 2),
     Point2(MidPt.x, MidPt.y + 4),
     Point2(MidPt.x + 5, MidPt.y - 2),
     DrawColor, DrawColor, DrawColor);

    GuiCanvas.FillTri(
     Point2(MidPt.x, MidPt.y - 2),
     Point2(MidPt.x, MidPt.y + 4),
     Point2(MidPt.x - 5, MidPt.y - 2),
     DrawColor, DrawColor, DrawColor);
   end;

  2: // Drag Button
   for i:= 0 to 3 do
    GuiCanvas.HorizLine(DrawAt.x + 4, MidPt.y + (i - 1) * 2 - 1,
     DrawSize.x - 8, DrawColor);

  3: // Left Arrow
   begin
    GuiCanvas.FillTri(
     Point2(MidPt.x + 2, MidPt.y),
     Point2(MidPt.x - 4, MidPt.y),
     Point2(MidPt.x + 2, MidPt.y + 5),
     DrawColor, DrawColor, DrawColor);

    GuiCanvas.FillTri(
     Point2(MidPt.x + 2, MidPt.y),
     Point2(MidPt.x - 4, MidPt.y),
     Point2(MidPt.x + 2, MidPt.y - 5),
     DrawColor, DrawColor, DrawColor);
   end;

  4: // Right Arrow
   begin
    GuiCanvas.FillTri(
     Point2(MidPt.x - 2, MidPt.y),
     Point2(MidPt.x + 4, MidPt.y),
     Point2(MidPt.x - 2, MidPt.y + 5),
     DrawColor, DrawColor, DrawColor);

    GuiCanvas.FillTri(
     Point2(MidPt.x - 2, MidPt.y),
     Point2(MidPt.x + 4, MidPt.y),
     Point2(MidPt.x - 2, MidPt.y - 5),
     DrawColor, DrawColor, DrawColor);
   end;

  5: // Drag Button
   begin
    for i:= 0 to 3 do
     GuiCanvas.VertLine(MidPt.x + (i - 1) * 2 - 1, DrawAt.y + 4,
      DrawSize.y - 8, DrawColor);
   end;

  7: // Track Vertical Button
   begin
    for i:= 0 to 1 do
     GuiCanvas.HorizLine(DrawAt.x + 4, MidPt.y + (i - 0.5) * 2,
      DrawSize.x - 8, DrawColor);
   end;

  8: // Track Horizontal Button
   begin
    for i:= 0 to 1 do
     GuiCanvas.VertLine(MidPt.x + i * 2 - 1, DrawAt.y + 4,
      DrawSize.y - 8, DrawColor);
   end;
 end;
end;

//---------------------------------------------------------------------------
procedure GuiDrawRadioButton(const PaintRect: TRect; ButtonAlpha: Single = 1.0;
 EnabledAlpha: Integer = 255; DownAlpha: Integer = 0; FocusAlpha: Integer = 0;
 CheckedAlpha: Integer = 0);
var
 Center, Radius, InRad: TPoint2;
 FillColor, NextColor: TColor4;
 MidColor, ColorIn, ColorOut: Cardinal;
 CheckColor: Cardinal;
 DownTheta: Single;
 EnAlpha  : Single;
 GlobAlpha: Single;
 CheckTheta: Single;
 i: Integer;
begin
 DownTheta := SineTheta(DownAlpha / 255.0);
 EnAlpha   := SineTheta(EnabledAlpha / 255.0);
 GlobAlpha := GuiGlobalAlpha * ButtonAlpha;
 CheckTheta:= GlobAlpha * GuiComputeTheta(CheckedAlpha);

 Center.x:= (PaintRect.Left + PaintRect.Right) * 0.5;
 Center.y:= (PaintRect.Top + PaintRect.Bottom) * 0.5;

 Radius.x:= (PaintRect.Right - PaintRect.Left) * 0.5;
 Radius.y:= (PaintRect.Bottom - PaintRect.Top) * 0.5;

 InRad:= Point2(Radius.x - 1, Radius.y - 1);

 //..........................................................................
 // Button Fill
 //..........................................................................
 FillColor:= cColor4Alpha1f(GuiButtonEnabledColor, GlobAlpha);

 if (DownTheta > 0.0) then
  begin
   NextColor:= cColor4Alpha1f(
    cAdjustLuma4(ExchangeColors(GuiButtonEnabledColor),
    GuiButtonDownLumaShift), GlobAlpha);

   for i:= 0 to 3 do
    FillColor[i]:= LerpPixels(FillColor[i], NextColor[i], DownTheta);
  end;

 if (EnAlpha < 1.0) then
  begin
   NextColor:= cColor4Alpha1f(GuiButtonDisabledColor, GlobAlpha);

   for i:= 0 to 3 do
    FillColor[i]:= LerpPixels(FillColor[i], NextColor[i], 1.0 - EnAlpha);
  end;

 MidColor:= AvgFourPixels(FillColor[0], FillColor[1], FillColor[2],
  FillColor[3]);

 ColorIn := MidColor;// cColorAlpha1f(MidColor, GuiGlobalAlpha * ButtonAlpha);
 ColorOut:= cColorAlpha1f(MidColor, 0.0);

 GuiCanvas.FillEllipse(Center, InRad, GuiRadioButtonQuality, FillColor);
//  cColor4Alpha1f(FillColor, GuiGlobalAlpha * ButtonAlpha));

 GuiCanvas.FillRibbon(Center, InRad, Radius, 0.0, 2.0 * Pi,
  GuiRadioButtonQuality, ColorIn, ColorIn, ColorIn, ColorOut, ColorOut,
  ColorOut);

 //..........................................................................
 // Border
 //..........................................................................
 ColorIn := cColorAlpha1f(GuiBorderColor, GlobAlpha);
 ColorOut:= cColorAlpha1f(GuiBorderColor, 0.0);

 GuiCanvas.FillRibbon(Center, Point2(Radius.x - 1.0, Radius.y - 1.0), Radius,
  0.0, 2.0 * Pi, GuiRadioButtonQuality, ColorIn, ColorIn, ColorIn, ColorOut,
  ColorOut, ColorOut);

 GuiCanvas.FillRibbon(Center, Point2(Radius.x - 2.0, Radius.y - 2.0),
  Point2(Radius.x - 1.0, Radius.y - 1.0), 0.0, 2.0 * Pi, GuiRadioButtonQuality,
  ColorOut, ColorOut, ColorOut, ColorIn, ColorIn, ColorIn);

 //..........................................................................
 // Focus
 //..........................................................................
 ColorIn := cColorAlpha1f(GuiCtrlFocusColor, GlobAlpha *
  GuiComputeTheta(FocusAlpha));
 ColorOut:= cColorAlpha1f(GuiCtrlFocusColor, 0.0);

 GuiCanvas.FillRibbon(Center, Point2(Radius.x - 3.0, Radius.y - 3.0),
  Point2(Radius.x - 1.0, Radius.y - 1.0), 0.0, 2.0 * Pi, GuiRadioButtonQuality,
  ColorIn, ColorIn, ColorIn, ColorOut, ColorOut, ColorOut);

 GuiCanvas.FillRibbon(Center, Point2(Radius.x - 6.0, Radius.y - 6.0),
  Point2(Radius.x - 3.0, Radius.y - 3.0), 0.0, 2.0 * Pi, GuiRadioButtonQuality,
  ColorOut, ColorOut, ColorOut, ColorIn, ColorIn, ColorIn);

 //..........................................................................
 // "Checked"
 //..........................................................................
 CheckColor:= LerpPixels(GuiEnabledCheckedColor, GuiDisabledCheckedColor,
  1.0 - EnAlpha);

 ColorIn := cColorAlpha1f(CheckColor, CheckTheta);
 ColorOut:= cColorAlpha1f(CheckColor, 0.0);

 GuiCanvas.FillEllipse(Center, Radius * 0.3, GuiRadioButtonQuality,
  cColor4(cColorAlpha1f(CheckColor, CheckTheta)));

 GuiCanvas.FillRibbon(Center, Radius * 0.3, Point2(Radius.x * 0.3 + 1,
  Radius.y * 0.3 + 1), 0.0, 2.0 * Pi,
  GuiRadioButtonQuality, ColorIn, ColorIn, ColorIn, ColorOut, ColorOut,
  ColorOut);
end;

//---------------------------------------------------------------------------
procedure GuiDrawCheckIcon(const PaintRect: TRect; ButtonAlpha: Single = 1.0;
 EnabledAlpha: Integer = 255; DownAlpha: Integer = 0;
 CheckedAlpha: Integer = 0);
var
 Points: array[0..8] of TPoint2;
 CheckColor: Cardinal;
 DownTheta : Single;
 EnAlpha   : Single;
 GlobAlpha : Single;
 CheckTheta: Single;
 Anisotropy, InvAnisotropy: Single;
 ColorIn, ColorOut: Cardinal;
begin
 Anisotropy:= GuiCheckBoxAnisotropy;
 InvAnisotropy:= 1.0 - GuiCheckBoxAnisotropy;

 DownTheta := SineTheta(DownAlpha / 255.0);
 EnAlpha   := SineTheta(EnabledAlpha / 255.0);
 GlobAlpha := GuiGlobalAlpha * ButtonAlpha;
 CheckTheta:= GlobAlpha * GuiComputeTheta(CheckedAlpha);

 Points[0]:= Point2(PaintRect.Left, PaintRect.Top);
 Points[1]:= Point2(PaintRect.Right, PaintRect.Top);
 Points[2]:= Point2(PaintRect.Right, PaintRect.Bottom);
 Points[3]:= Point2(PaintRect.Left, PaintRect.Bottom);

 Points[4]:= Point2(
  PaintRect.Left * 0.5 + PaintRect.Right * 0.5,
  PaintRect.Top * InvAnisotropy + PaintRect.Bottom * Anisotropy);

 Points[5]:= Point2(
  PaintRect.Left * Anisotropy + PaintRect.Right * InvAnisotropy,
  PaintRect.Top * 0.5 + PaintRect.Bottom * 0.5);

 Points[6]:= Point2(
  PaintRect.Left * 0.5 + PaintRect.Right * 0.5,
  PaintRect.Top * Anisotropy + PaintRect.Bottom * InvAnisotropy);

 Points[7]:= Point2(
  PaintRect.Left * InvAnisotropy + PaintRect.Right * Anisotropy,
  PaintRect.Top * 0.5 + PaintRect.Bottom * 0.5);

 Points[8]:= (Points[4] + Points[6]) * 0.5;

 CheckColor:= LerpPixels(GuiEnabledCheckedColor, GuiDisabledCheckedColor,
  1.0 - EnAlpha);

 if (DownTheta > 0.0) then
  CheckColor:= cAdjustLuma1(CheckColor, GuiButtonDownLumaShift * DownTheta);

 ColorIn := cColorAlpha1f(CheckColor, CheckTheta);
 ColorOut:= cColorAlpha1f(CheckColor, 0.0);

 GuiCanvas.FillTri(
  Points[0], Points[4], Points[8], ColorOut, ColorOut, ColorIn);
 GuiCanvas.FillTri(
  Points[0], Points[8], Points[7], ColorOut, ColorIn, ColorOut);

 GuiCanvas.FillTri(
  Points[1], Points[8], Points[4], ColorOut, ColorIn, ColorOut);
 GuiCanvas.FillTri(
  Points[1], Points[5], Points[8], ColorOut, ColorOut, ColorIn);

 GuiCanvas.FillTri(
  Points[3], Points[7], Points[8], ColorOut, ColorOut, ColorIn);
 GuiCanvas.FillTri(
  Points[3], Points[8], Points[6], ColorOut, ColorIn, ColorOut);

 GuiCanvas.FillTri(
  Points[2], Points[8], Points[5], ColorOut, ColorIn, ColorOut);
 GuiCanvas.FillTri(
  Points[2], Points[6], Points[8], ColorOut, ColorOut, ColorIn);
end;

//---------------------------------------------------------------------------
procedure InitVariables();
begin
 GuiBorderColor:= $FF7F9DB9;

 GuiCtrlFocusColor := $407592C3;
 GuiButtonFocusColor:= $407592C3;

 GuiCaretColor:= $803B4680;
 GuiEditSelectColor:= $406F7FD9;

 GuiPointedColor := cColor4($20A689EF, $209877ED, $20774CE7, $208862EA);
 GuiCtrlFillColor:= cColor4($FFE4E7F3, $FFDFE4F5, $FFEFF3FF, $FFFFFFFF);

 GuiItemSelectColor:= cColor4($FFD5DEF7, $FFCBD6F5, $FFB4C4F0, $FFC1CFF3);

 GuiTextEnabledColor := cColor2($FF316AC5);
 GuiTextDisabledColor:= cColor2($FF96897C);

 GuiButtonOuterColor:= cColor4($FFD0DBF6, $FFD6DFF7, $FFEDF1FC, $FFD6DFF7);

 GuiButtonEnabledColor := cColor4($FFFCFCFC, $FFFCFCFB, $FFE9E8E1, $FFEBEBE5);
 GuiButtonDisabledColor:= cColor4($FFF0EEEC, $FFEDEAE8, $FFE4E1DE, $FFE8E6E3);

 GuiSystemIconColor:= $FFA2B8CD;

 GuiScrollBarFillColor:= cColor4($FFBDC5EE);

 GuiEnabledCheckedColor := $FF5A75BB;
 GuiDisabledCheckedColor:= $FF8A81AB;

 GuiFormIconColor  := $FF799FE5;
 GuiFormBorderColor:= $FFFFFFFF;
 GuiFormFillColor  := cColor4($FFD6DFF7);

 GuiFormActiveTitleFill:= cColor4($FFFFFFFF, $FFFFFFFF, $FFC6D3F7, $FFC6D3F7);
 GuiFormInactiveTitleFill:= cColor4($FFDCDFE8, $FFDCDFE8, $FFB7C2E0, $FFB7C2E0);

 GuiFormActiveTitleColor  := cColor2($FF295DCE);
 GuiFormInactiveTitleColor:= cColor2($FF2446B3);

 GuiTaskbarBackground:= $FF6375D6;
end;

//---------------------------------------------------------------------------
function GuiComputeTheta(SrcAlpha: Integer): Single;
begin
 if (SrcAlpha >= 255) then Result:= 1.0
  else if (SrcAlpha <= 0) then Result:= 0.0
   else Result:= SineTheta(SrcAlpha / 255.0);
end;

//---------------------------------------------------------------------------
initialization
 InitVariables();

//---------------------------------------------------------------------------
end.

