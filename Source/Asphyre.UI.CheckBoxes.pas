unit Asphyre.UI.CheckBoxes;
//---------------------------------------------------------------------------
// Check Box controls for Asphyre GUI framework.
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
{$ifndef fpc}
 System.Types,
{$else}
 Types,
{$endif}
 Asphyre.Math, Asphyre.TypeDef, Asphyre.UI.Types,
 Asphyre.UI.Controls;

//---------------------------------------------------------------------------
type
 TGuiCheckBox = class(TGuiControl)
 private
  FCaption: UniString;
  FChecked: Boolean;
  FAutoSize: Boolean;
  FTextSpacing: Integer;
  FTextVertShift: Integer;
  FTextFontName: StdString;

  DownAlpha   : Integer;
  EnabledAlpha: Integer;
  FocusAlpha  : Integer;
  CheckedAlpha: Integer;
  ClickedOver : Boolean;
  PressedOver : Boolean;
 protected
  procedure DoPaint(); override;
  procedure DoUpdate(); override;

  procedure SelfDescribe(); override;
  procedure FirstTimePaint(); override;

  procedure DoMouseEvent(const MousePos: TPoint2px; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TGuiShiftState); override;

  procedure DoKeyEvent(Key: Integer; Event: TKeyEventType;
   Shift: TGuiShiftState); override;
 public
  property Caption : UniString read FCaption write FCaption;
  property Checked : Boolean read FChecked write FChecked;
  property AutoSize: Boolean read FAutoSize write FAutoSize;

  property TextSpacing: Integer read FTextSpacing write FTextSpacing;
  property TextVertShift: Integer read FTextVertShift write FTextVertShift;

  property TextFontName: StdString read FTextFontName write FTextFontName;
  property TabOrder;

  constructor Create(const AOwner: TGuiControl); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types, Asphyre.UI.Globals, Asphyre.Fonts;

//---------------------------------------------------------------------------
constructor TGuiCheckBox.Create(const AOwner: TGuiControl);
begin
 inherited;

 FAutoSize:= True;

 FCaption:= '';
 FChecked:= True;

 FTextSpacing  := 5;
 FTextVertShift:= 0;

 Width := 120;
 Height:= 15;

 ClickedOver:= False;
 PressedOver:= False;
end;

//---------------------------------------------------------------------------
procedure TGuiCheckBox.DoPaint();
var
 PaintRect : TRect;
 DrawAt    : TPoint2px;
 DrawSize  : TPoint2px;
 ButtonRect: TRect;
 TextSize  : TPoint2px;
 TextFont  : TAsphyreFont;
 DrawAlpha : Single;
begin
 PaintRect:= VirtualRect;

 DrawAlpha:= Lerp(1.0, GuiButtonDisabledAlpha,
  1.0 - GuiComputeTheta(EnabledAlpha));

 DrawSize.y:= PaintRect.Bottom - PaintRect.Top;
 DrawSize.x:= Min2(DrawSize.y, (PaintRect.Right - PaintRect.Left) div 4);

 DrawAt:= Point2px(PaintRect.Left, PaintRect.Top);

 ButtonRect:= Bounds(DrawAt.x, DrawAt.y, DrawSize.x, DrawSize.y);

 GuiDrawButtonFillInside(ButtonRect, DrawAlpha, EnabledAlpha, DownAlpha);

 GuiDrawCtrlFocus(ButtonRect, FocusAlpha);

 GuiDrawCheckIcon(ShrinkRect(ButtonRect, 2, 2), DrawAlpha, EnabledAlpha,
  DownAlpha, CheckedAlpha);

 GuiDrawControlBorder(ButtonRect, DrawAlpha);

 TextFont:= RetrieveGuiFont(FTextFontName);
 if (not Assigned(TextFont)) then Exit;

 TextSize:= TextFont.TexExtent(FCaption);
 if (TextSize.x < 1)or(TextSize.y < 1) then Exit;

 if (FAutoSize) then
  Width:= DrawSize.x + FTextSpacing + TextSize.x;

 DrawAt.x:= PaintRect.Left + DrawSize.x + FTextSpacing;
 DrawAt.y:= FTextVertShift + (PaintRect.Top + PaintRect.Bottom -
  TextSize.y) div 2;

 GuiDrawControlText(DrawAt, FCaption, TextFont, DrawAlpha, EnabledAlpha, 0,
  FocusAlpha);
end;

//---------------------------------------------------------------------------
procedure TGuiCheckBox.DoUpdate();
begin
 inherited;

 if (Enabled) then
  EnabledAlpha:= Min2(EnabledAlpha + 16, 255)
   else EnabledAlpha:= Max2(EnabledAlpha - 12, 0);

 if (((ClickedOver)and(MouseOver))or(PressedOver))and(Enabled) then
  DownAlpha:= Min2(DownAlpha + 48, 255)
   else DownAlpha:= Max2(DownAlpha - 32, 0);

 if (Assigned(Owner))and(Owner.CtrlHolder) then
  begin
   if (Focused)and(Enabled) then
    FocusAlpha:= Min2(FocusAlpha + 22, 255)
     else FocusAlpha:= Max2(FocusAlpha - 16, 0);
  end;

 if (FChecked) then
  CheckedAlpha:= Min2(CheckedAlpha + 48, 255)
   else CheckedAlpha:= Max2(CheckedAlpha - 32, 0);
end;

//---------------------------------------------------------------------------
procedure TGuiCheckBox.FirstTimePaint();
begin
 inherited;

 if (Enabled) then
  EnabledAlpha:= 255
   else EnabledAlpha:= 0;

 if (((ClickedOver)and(MouseOver))or(PressedOver))and(Enabled) then
  DownAlpha:= 255
   else DownAlpha:= 0;

 if (Assigned(Owner))and(Owner.CtrlHolder) then
  begin
   if (Focused)and(Enabled) then
    FocusAlpha:= 255
     else FocusAlpha:= 0;
  end;

 if (FChecked) then
  CheckedAlpha:= 255
   else CheckedAlpha:= 0;
end;

//---------------------------------------------------------------------------
procedure TGuiCheckBox.DoMouseEvent(const MousePos: TPoint2px;
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
      FChecked:= not FChecked;

     ClickedOver:= False;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiCheckBox.DoKeyEvent(Key: Integer; Event: TKeyEventType;
 Shift: TGuiShiftState);
begin
 case Event of
  ketDown:
   case Key of
    AVK_Tab:
     SendFocusToNext();

    AVK_Space:
     if (not ClickedOver) then
      PressedOver:= True;

    AVK_Escape:
     if (PressedOver) then
      PressedOver:= False;
   end;

  ketUp:
   if (Key = AVK_Space)and(PressedOver) then
    begin
     FChecked:= not FChecked;
     PressedOver:= False;
    end;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiCheckBox.SelfDescribe();
begin
 inherited;

 FNameOfClass:= 'TGuiCheckBox';

 AddProperty('TextFontName', gptString, gpfStdString, @FTextFontName);

 AddProperty('Caption', gptString,  gpfUniString, @FCaption);

 AddProperty('Checked', gptBoolean, gpfBoolean, @FChecked, 
  SizeOf(Boolean));

 AddProperty('AutoSize', gptBoolean, gpfBoolean, @FAutoSize, 
  SizeOf(Boolean));

 AddProperty('TabOrder', gptInteger, gpfInteger, @FTabOrder, 
  SizeOf(Integer));

 AddProperty('TextSpacing', gptInteger, gpfInteger, @FTextSpacing, 
  SizeOf(Integer));

 AddProperty('TextVertShift', gptInteger, gpfInteger, @FTextVertShift, 
  SizeOf(Integer));
end;

//---------------------------------------------------------------------------
end.
