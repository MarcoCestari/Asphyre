unit Asphyre.UI.Buttons;
//---------------------------------------------------------------------------
// Button control for Asphyre GUI framework.
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
 System.Types, System.Classes, Asphyre.TypeDef, Asphyre.Math, 
 Asphyre.UI.Types, Asphyre.UI.Controls;

//---------------------------------------------------------------------------
type
 TGuiButtonType = (gbtNormal, gbtScrollSvc, gbtTrackSvc);

//---------------------------------------------------------------------------
 TGuiButton = class(TGuiControl)
 private
  FSystemIcon: Integer;

  FCaption: UniString;
  ClickedOver: Boolean;
  PressedOver: Boolean;

  DownAlpha   : Integer;
  EnabledAlpha: Integer;
  FocusAlpha  : Integer;
  FShowBorder : Boolean;

  FTextFontName  : StdString;
  FTextVertShift : Integer;
  FGlyphPattern  : Integer;
  FGlyphImageName: StdString;
  FGlyphSpacing  : Integer;
  FGlyphVertShift: Integer;

  FOnClick   : TNotifyEvent;
  FButtonType: TGuiButtonType;
 protected
  procedure DoPaint(); override;
  procedure DoUpdate(); override;

  procedure SelfDescribe(); override;
  procedure FirstTimePaint(); override;

  procedure DoMouseEvent(const MousePos: TPoint2px; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TGuiShiftState); override;

  procedure DoKeyEvent(Key: Integer; Event: TKeyEventType;
   Shift: TGuiShiftState); override;

  procedure DoButtonClick(); virtual;
 public
  property SystemIcon: Integer read FSystemIcon write FSystemIcon;

  property ButtonType: TGuiButtonType read FButtonType write FButtonType;

  property Caption: UniString read FCaption write FCaption;

  property ShowBorder: Boolean read FShowBorder write FShowBorder;

  property TextFontName : StdString read FTextFontName write FTextFontName;
  property TextVertShift: Integer read FTextVertShift write FTextVertShift;

  property GlyphImageName: StdString read FGlyphImageName write FGlyphImageName;
  property GlyphPattern  : Integer read FGlyphPattern write FGlyphPattern;
  property GlyphSpacing  : Integer read FGlyphSpacing write FGlyphSpacing;
  property GlyphVertShift: Integer read FGlyphVertShift write FGlyphVertShift;

  property OnClick: TNotifyEvent read FOnClick write FOnClick;
  property OnMouse;
  property TabOrder;

  constructor Create(const AOwner: TGuiControl); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types, Asphyre.Fonts, Asphyre.Images, Asphyre.UI.Globals, Asphyre.Events;

//---------------------------------------------------------------------------
constructor TGuiButton.Create(const AOwner: TGuiControl);
begin
 inherited;

 FSystemIcon:= -1;

 Width := 90;
 Height:= 25;

 FTextVertShift:= 0;

 FGlyphImageName:= '';
 FGlyphPattern  := 0;
 FGlyphSpacing  := 4;
 FGlyphVertShift:= 0;

 FShowBorder:= True;

 ClickedOver:= False;
 PressedOver:= False;
end;

//---------------------------------------------------------------------------
procedure TGuiButton.DoPaint();
var
 PaintRect: TRect;
 TextFont : TAsphyreFont;
 TextSize : TPoint2px;
 DrawAt   : TPoint2px;
 EnAlpha  : Single;
 Glyph    : TAsphyreImage;
 GlyphSize: TPoint2px;
 GlyphNo  : Integer;
 CompAlpha: Single;
 FillAlpha: Single;
begin
 PaintRect:= VirtualRect;

 EnAlpha  := GuiComputeTheta(EnabledAlpha);
 CompAlpha:= Lerp(1.0, GuiButtonDisabledAlpha, 1.0 - EnAlpha);

 if (FButtonType <> gbtTrackSvc) then
  GuiDrawOuterBorder(PaintRect, CompAlpha);

 FillAlpha:= CompAlpha;

 if (FButtonType = gbtTrackSvc) then
  FillAlpha:= 1.0;

 if (FShowBorder) then
  begin
   GuiDrawButtonFill(ShrinkRect(PaintRect, 1, 1), FillAlpha, EnabledAlpha,
    DownAlpha);
  end else
   GuiDrawButtonFill(PaintRect, CompAlpha, EnabledAlpha, DownAlpha);

 if (FocusAlpha > 0)and(not GuiDesign) then
  GuiDrawButtonFocus(PaintRect, FocusAlpha);

 if (FShowBorder) then
  begin
   if (FButtonType <> gbtTrackSvc) then
    GuiDrawControlBorder(PaintRect, CompAlpha)
     else GuiDrawControlBorder(PaintRect, CompAlpha * 0.75);
  end;

 Glyph:= nil;
 if (FGlyphImageName <> '')and(FGlyphPattern <> -1) then
  begin
   GlyphNo:= GuiImages.Resolve(FGlyphImageName);

   if (GlyphNo <> -1) then
    Glyph:= GuiImages[GlyphNo];
  end;

 TextFont:= RetrieveGuiFont(FTextFontName);
 TextSize:= ZeroPoint2px;

 if (Assigned(TextFont))and(FSystemIcon = -1) then
  TextSize:= TextFont.TexExtent(FCaption);

 if (Assigned(Glyph)) then
  begin
   GlyphSize:= Glyph.VisibleSize;

   DrawAt.x:= (PaintRect.Left + PaintRect.Right - (TextSize.x + GlyphSize.x +
    FGlyphSpacing)) div 2;
   DrawAt.y:= FGlyphVertShift + (PaintRect.Top + PaintRect.Bottom -
    GlyphSize.y) div 2;

   GuiDrawGlyph(DrawAt, Glyph, FGlyphPattern, CompAlpha, EnabledAlpha,
    DownAlpha);
  end else
   GlyphSize:= ZeroPoint2px;

 if (not Assigned(Glyph))and(FSystemIcon <> -1) then
  GuiPaintSystemIcon(PaintRect, FSystemIcon, CompAlpha, EnabledAlpha,
   DownAlpha);

 if (Assigned(TextFont))and(FSystemIcon = -1) then
  begin
   DrawAt.x:= (PaintRect.Left + PaintRect.Right - TextSize.x) div 2;
   DrawAt.y:= FTextVertShift + (PaintRect.Top + PaintRect.Bottom -
    TextSize.y) div 2;

   if (Assigned(Glyph))and(GlyphSize.x > 0) then
    DrawAt.x:= ((PaintRect.Left + PaintRect.Right - (TextSize.x + GlyphSize.x +
     FGlyphSpacing)) div 2) + GlyphSize.x + FGlyphSpacing;

   GuiDrawControlText(DrawAt, FCaption, TextFont, CompAlpha, EnabledAlpha,
    DownAlpha);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiButton.FirstTimePaint();
begin
 inherited;

 if (Enabled) then
  EnabledAlpha:= 255
   else EnabledAlpha:= 0;

 if (((ClickedOver)and(MouseOver))or(PressedOver))and(Enabled) then
  DownAlpha:= 255
   else DownAlpha:= 0;

 if ((Assigned(Owner))and(Owner.CtrlHolder))or(FButtonType = gbtTrackSvc) then
  begin
   if (Focused)and(Enabled) then FocusAlpha:= 255
    else FocusAlpha:= 0;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiButton.DoUpdate();
begin
 inherited;

 if (Enabled) then
  EnabledAlpha:= Min2(EnabledAlpha + 16, 255)
   else EnabledAlpha:= Max2(EnabledAlpha - 12, 0);

 if (((ClickedOver)and((MouseOver)or(FButtonType in [gbtScrollSvc,
  gbtTrackSvc])))or(PressedOver)) then
  DownAlpha:= Min2(DownAlpha + 48, 255)
   else DownAlpha:= Max2(DownAlpha - 32, 0);

 if ((Assigned(Owner))and(Owner.CtrlHolder))or(FButtonType = gbtTrackSvc) then
  begin
   if (Focused)and(Enabled) then FocusAlpha:= Min2(FocusAlpha + 22, 255)
    else FocusAlpha:= Max2(FocusAlpha - 16, 0);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiButton.DoMouseEvent(const MousePos: TPoint2px;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TGuiShiftState);
begin
 inherited;

 if (not PressedOver) then
  begin
   if (Event = metDown)and(Button = mbtLeft) then
    ClickedOver:= True;

   if (Event = metUp)and(Button = mbtLeft) then
    begin
     if (ClickedOver)and(MouseOver) then
      DoButtonClick();

     ClickedOver:= False;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiButton.DoKeyEvent(Key: Integer; Event: TKeyEventType;
 Shift: TGuiShiftState);
begin
 case Event of
  ketDown:
   case Key of
    AVK_Space:
     if (not ClickedOver) then
      PressedOver:= True;

    AVK_Escape:
     if (PressedOver) then
      PressedOver:= False;

    AVK_Tab:
     SendFocusToNext();
   end;

  ketUp:
   if (Key = AVK_Space)and(PressedOver) then
    begin
     DoButtonClick();
     PressedOver:= False;
    end;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiButton.SelfDescribe();
begin
 inherited;

 FNameOfClass:= 'TGuiButton';

 AddProperty('Caption', gptString, gpfUniString,  @FCaption);

 AddProperty('TextFontName', gptString,  gpfStdString, @FTextFontName);

 AddProperty('TextVertShift', gptInteger, gpfInteger, @FTextVertShift,
  SizeOf(Integer));

 AddProperty('GlyphImageName', gptString, gpfStdString, @FGlyphImageName);

 AddProperty('GlyphPattern', gptInteger, gpfInteger, @FGlyphPattern, 
  SizeOf(Integer));

 AddProperty('GlyphSpacing', gptInteger, gpfInteger, @FGlyphSpacing, 
  SizeOf(Integer));

 AddProperty('GlyphVertShift', gptInteger, gpfInteger, @FGlyphVertShift, 
  SizeOf(Integer));

 AddProperty('TabOrder', gptInteger, gpfInteger, @FTabOrder, 
  SizeOf(Integer));
end;

//---------------------------------------------------------------------------
procedure TGuiButton.DoButtonClick();
begin
 if (Assigned(FOnClick)) then FOnClick(Self);

 EventControlName:= Name;
 EventControlForm:= GetOwnerFormName();

 EventButtonClick.Notify(Self);
end;

//---------------------------------------------------------------------------
end.

