unit Asphyre.UI.Bevels;
//---------------------------------------------------------------------------
// Bevel controls for Asphyre GUI framework.
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
 System.Types, Asphyre.Types, Asphyre.UI.Types, Asphyre.UI.Controls;

//---------------------------------------------------------------------------
type
 TGuiBevel = class(TGuiControl)
 private
  FInsideFill  : TColor4;
  FBorderColor : Cardinal;
  FInside3DFeel: Boolean;
  FDrawAlpha   : Single;
 protected
  procedure DoPaint(); override;
  procedure SelfDescribe(); override;
 public
  property InsideFill : TColor4 read FInsideFill write FInsideFill;
  property BorderColor: Cardinal read FBorderColor write FBorderColor;

  property Inside3DFeel: Boolean read FInside3DFeel write FInside3DFeel;

  property DrawAlpha: Single read FDrawAlpha write FDrawAlpha;

  constructor Create(const AOwner: TGuiControl); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.UI.Globals;

//---------------------------------------------------------------------------
constructor TGuiBevel.Create(const AOwner: TGuiControl);
begin
 inherited;

 FInsideFill  := cColor4($FF7D8FD2, $FF667BCA, $FF3F58B6, $FF536BC4);
 FBorderColor := $FF5057AD;
 FInside3DFeel:= False;
 FDrawAlpha   := 1.0;

 Width := 100;
 Height:= 100;
end;

//---------------------------------------------------------------------------
procedure TGuiBevel.DoPaint();
var
 PaintRect: TRect;
begin
 PaintRect:= VirtualRect;

 GuiCanvas.FillQuad(pRect4(PaintRect), cColor4Alpha1f(FInsideFill,
  GuiGlobalAlpha * FDrawAlpha));

 if (FInside3DFeel) then
  GuiCanvas.FrameRect(RectExtrude(PaintRect),
   cColor4Alpha1f(ExchangeColors(FInsideFill), GuiGlobalAlpha * FDrawAlpha));

 GuiCanvas.FrameRect(pRect4(PaintRect), cColor4(cColorAlpha1f(FBorderColor,
  GuiGlobalAlpha * FDrawAlpha)));
end;

//---------------------------------------------------------------------------
procedure TGuiBevel.SelfDescribe();
begin
 inherited;

 FNameOfClass:= 'TGuiBevel';

 AddProperty('InsideFill', gptColor4, gpfColor4, @FInsideFill, 
  SizeOf(TColor4));

 AddProperty('BorderColor', gptColor, gpfCardinal, @FBorderColor, 
  SizeOf(Cardinal));

 AddProperty('Inside3DFeel', gptBoolean, gpfBoolean, @FInside3DFeel, 
  SizeOf(Boolean));

 AddProperty('DrawAlpha', gptFloat, gpfSingle, @FDrawAlpha, 
  SizeOf(Single));
end;

//---------------------------------------------------------------------------
end.
