unit Asphyre.UI.Labels;
//---------------------------------------------------------------------------
// Label controls for Asphyre GUI framework.
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
 System.Types, Asphyre.TypeDef, Asphyre.Types, Asphyre.UI.Types, 
 Asphyre.UI.Controls;

//---------------------------------------------------------------------------
type
 TGuiLabel = class(TGuiControl)
 private
  FCaption  : UniString;
  FAutoSize : Boolean;
  FAlignment: TTextAlignType;
  FDrawAlpha: Single;

  FTextFontName : StdString;
  EnabledAlpha  : Integer;
  FEnabledColor : TColor2;
  FDisabledColor: TColor2;
  FUseSysColors : Boolean;
 protected
  procedure DoPaint(); override;
  procedure DoUpdate(); override;

  procedure SelfDescribe(); override;
  procedure FirstTimePaint(); override;
 public
  property Caption: UniString read FCaption write FCaption;

  property Alignment: TTextAlignType read FAlignment write FAlignment;
  property AutoSize : Boolean read FAutoSize write FAutoSize;
  property DrawAlpha: Single read FDrawAlpha write FDrawAlpha;

  property TextFontName: StdString read FTextFontName write FTextFontName;

  property EnabledColor : TColor2 read FEnabledColor write FEnabledColor;
  property DisabledColor: TColor2 read FDisabledColor write FDisabledColor;
  property UseSysColors : Boolean read FUseSysColors write FUseSysColors;

  constructor Create(const AOwner: TGuiControl); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Math, Asphyre.Fonts, Asphyre.UI.Globals;

//---------------------------------------------------------------------------
constructor TGuiLabel.Create(const AOwner: TGuiControl);
begin
 inherited;

 Width := 100;
 Height:= 20;

 FEnabledColor := cColor2($FF316AC5);
 FDisabledColor:= cColor2($FF96897C);

 FUseSysColors:= True;

 FAutoSize := True;
 FDrawAlpha:= 1.0;
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.DoPaint();
var
 ViRect: TRect;
 TextFont: TAsphyreFont;
 TextSize, DrawAt: TPoint2px;
 PrevRect: TRect;
begin
 if (FDrawAlpha <= 0.0) then Exit;

 TextFont:= RetrieveGuiFont(FTextFontName);
 if (not Assigned(TextFont)) then Exit;

 TextSize:= TextFont.TexExtent(FCaption);

 if (FAutoSize) then
  case FAlignment of
   tatLeft:
    SetSize(TextSize);

   tatRight:
    begin
     Left:= Left + Width - TextSize.x;
     Top := Top + Height - TextSize.y;
     SetSize(TextSize);
    end;

   tatCenter:
    begin
     Left:= Left + (Width - TextSize.x) div 2;
     Top := Top + (Height - TextSize.y) div 2;
     SetSize(TextSize);
    end;
  end;

 ViRect:= VirtualRect;

 case FAlignment of
  tatLeft:
   DrawAt:= Point2px(ViRect.Left, ViRect.Top);

  tatRight:
   begin
    DrawAt.x:= ViRect.Right - TextSize.x;
    DrawAt.y:= ViRect.Bottom - TextSize.y;
   end;

  tatCenter:
   begin
    DrawAt.x:= ((ViRect.Left + ViRect.Right) - TextSize.x) div 2;
    DrawAt.y:= ((ViRect.Top + ViRect.Bottom) - TextSize.y) div 2;
   end;
 end;

 if (Assigned(Owner))and(FAutoSize) then
  begin
   PrevRect:= GuiCanvas.ClipRect;
   GuiCanvas.ClipRect:= Owner.VisibleRect;
  end else PrevRect:= Bounds(0, 0, 0, 0);

 if (FUseSysColors) then
  GuiDrawControlText(DrawAt, FCaption, TextFont, FDrawAlpha, EnabledAlpha)
   else GuiDrawCustomText(DrawAt, FCaption, TextFont, FEnabledColor,
    FDisabledColor, FDrawAlpha, EnabledAlpha);

 if (Assigned(Owner))and(FAutoSize) then GuiCanvas.ClipRect:= PrevRect;
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.FirstTimePaint();
begin
 inherited;

 if (Enabled) then EnabledAlpha:= 255
  else EnabledAlpha:= 0;
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.DoUpdate();
begin
 inherited;

 if (Enabled) then EnabledAlpha:= Min2(EnabledAlpha + 16, 255)
  else EnabledAlpha:= Max2(EnabledAlpha - 12, 0);
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.SelfDescribe();
begin
 inherited;

 FNameOfClass:= 'TGuiLabel';

 AddProperty('Caption', gptString, gpfUniString, @FCaption);
 AddProperty('AutoSize', gptBoolean, gpfBoolean, @FAutoSize, 
  SizeOf(Boolean));

 AddProperty('Alignment', gptAlignType, gpfAlignType, @FAlignment, 
  SizeOf(TTextAlignType));

 AddProperty('DrawAlpha', gptFloat, gpfSingle, @FDrawAlpha, 
  SizeOf(Single));

 AddProperty('TextFontName', gptString, gpfStdString, @FTextFontName);

 AddProperty('EnabledColor', gptColor2, gpfColor2, @FEnabledColor, 
  SizeOf(TColor2));

 AddProperty('DisabledColor', gptColor2, gpfColor2, @FDisabledColor, 
  SizeOf(TColor2));

 AddProperty('UseSysColors', gptBoolean, gpfBoolean, @FUseSysColors,
  SizeOf(Boolean));
end;

//---------------------------------------------------------------------------
end.
