unit Asphyre.UI.RadioButtons;
//---------------------------------------------------------------------------
// Radio Button controls for Asphyre GUI framework.
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
 Asphyre.TypeDef, Asphyre.Math, Asphyre.UI.Types,
 Asphyre.UI.Controls;

//---------------------------------------------------------------------------
type
 TGuiRadioButton = class(TGuiControl)
 private
  FCaption: UniString;
  FChecked: Boolean;
  FGroupIndex: Integer;
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

  ChangeGroupTag: Integer;
  ChangeCheckTag: Integer;

  procedure SetChecked(const Value: Boolean);
  procedure SetGroupIndex(const Value: Integer);
  procedure CheckInitStatus();
  procedure UncheckOtherButtons();
 protected
  procedure DoPaint(); override;
  procedure DoUpdate(); override;

  procedure SelfDescribe(); override;
  procedure FirstTimePaint(); override;

  procedure DoMouseEvent(const MousePos: TPoint2px; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TGuiShiftState); override;

  procedure DoKeyEvent(Key: Integer; Event: TKeyEventType;
   Shift: TGuiShiftState); override;

  procedure AfterChange(const AFieldName: StdString;
   PropType: TGuiPropertyType; PropTag: Integer); override;
 public
  property Caption: UniString read FCaption write FCaption;
  property Checked: Boolean read FChecked write SetChecked;

  property GroupIndex: Integer read FGroupIndex write SetGroupIndex;
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
constructor TGuiRadioButton.Create(const AOwner: TGuiControl);
begin
 inherited;

 FGroupIndex:= -1;
 FAutoSize  := True;

 FCaption:= '';
 FChecked:= True;

 FTextSpacing  := 5;
 FTextVertShift:= 0;

 Width := 120;
 Height:= 17;

 ClickedOver:= False;
 PressedOver:= False;

 CheckInitStatus();
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.CheckInitStatus();
var
 i: Integer;
 Ctrl: TGuiControl;
 Button: TGuiRadioButton;
 AnyButtonSet: Boolean;
begin
 if (not Assigned(Owner))or(FGroupIndex = -1) then Exit;

 AnyButtonSet:= False;

 for i:= 0 to Owner.ControlCount - 1 do
  begin
   Ctrl:= Owner.Control[i];
   if (not Assigned(Ctrl))or(not (Ctrl is TGuiRadioButton))or
    (Ctrl = Self) then Continue;

   Button:= TGuiRadioButton(Ctrl);
   if (Button.GroupIndex = FGroupIndex)and(Button.Checked) then
    begin
     AnyButtonSet:= True;
     Break;
    end;
  end;

 FChecked:= not AnyButtonSet;
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.SetChecked(const Value: Boolean);
begin
 FChecked:= Value;

 if (FChecked) then
  UncheckOtherButtons();
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.SetGroupIndex(const Value: Integer);
begin
 FGroupIndex:= Value;
 CheckInitStatus();
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.UncheckOtherButtons();
var
 i: Integer;
 Ctrl: TGuiControl;
 Button: TGuiRadioButton;
begin
 if (not Assigned(Owner))or(FGroupIndex = -1) then Exit;

 for i:= 0 to Owner.ControlCount - 1 do
  begin
   Ctrl:= Owner.Control[i];
   if (not Assigned(Ctrl))or(not (Ctrl is TGuiRadioButton))or
    (Ctrl = Self) then Continue;

   Button:= TGuiRadioButton(Ctrl);

   if (Button.GroupIndex = FGroupIndex) then
    Button.Checked:= False;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.DoPaint();
var
 PaintRect: TRect;
 DrawAt   : TPoint2px;
 DrawSize : TPoint2px;
 TextSize : TPoint2px;
 TextFont : TAsphyreFont;
 DrawAlpha: Single;
begin
 PaintRect:= VirtualRect;

 DrawAlpha:= Lerp(1.0, GuiButtonDisabledAlpha,
  1.0 - GuiComputeTheta(EnabledAlpha));

 DrawSize.y:= PaintRect.Bottom - PaintRect.Top;
 DrawSize.x:= DrawSize.y;

 DrawAt:= Point2px(PaintRect.Left, PaintRect.Top);

 GuiDrawRadioButton(Bounds(DrawAt.x, DrawAt.y, DrawSize.x, DrawSize.y),
  DrawAlpha, EnabledAlpha, DownAlpha, FocusAlpha, CheckedAlpha);

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
procedure TGuiRadioButton.DoUpdate();
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
procedure TGuiRadioButton.FirstTimePaint();
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
procedure TGuiRadioButton.DoMouseEvent(const MousePos: TPoint2px;
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
      SetChecked(True);

     ClickedOver:= False;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.DoKeyEvent(Key: Integer; Event: TKeyEventType;
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
     SetChecked(True);
     PressedOver:= False;
    end;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.SelfDescribe();
begin
 inherited;

 ChangeGroupTag:= NextFieldTag();
 ChangeCheckTag:= NextFieldTag();

 FNameOfClass:= 'TGuiRadioButton';

 AddProperty('TextFontName', gptString, gpfStdString, @FTextFontName);

 AddProperty('Caption', gptString, gpfUniString, @FCaption);

 AddProperty('Checked', gptBoolean, gpfBoolean, @FChecked,
  SizeOf(Boolean), ChangeCheckTag);

 AddProperty('GroupIndex', gptInteger, gpfInteger, @FGroupIndex,
  SizeOf(Integer), ChangeGroupTag);

 AddProperty('AutoSize', gptBoolean, gpfBoolean, @FAutoSize,
  SizeOf(Boolean));

 AddProperty('TextSpacing', gptInteger, gpfInteger, @FTextSpacing,
  SizeOf(Integer));

 AddProperty('TextVertShift', gptInteger, gpfInteger, @FTextVertShift,
  SizeOf(Integer));

 AddProperty('TabOrder', gptInteger, gpfInteger, @FTabOrder,
  SizeOf(Integer));
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.AfterChange(const AFieldName: StdString;
 PropType: TGuiPropertyType; PropTag: Integer);
begin
 inherited;

 if (PropTag = ChangeGroupTag) then
  CheckInitStatus();

 if (PropTag = ChangeCheckTag)and(FChecked) then
  UncheckOtherButtons();
end;

//---------------------------------------------------------------------------
end.
