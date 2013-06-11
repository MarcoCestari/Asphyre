unit Asphyre.UI.ComboBoxes;
//---------------------------------------------------------------------------
// Combo Box controls for Asphyre GUI framework.
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
 System.Types, System.Classes, System.SysUtils, Asphyre.TypeDef, 
 Asphyre.Math, Asphyre.UI.Types, Asphyre.UI.Controls, Asphyre.UI.ListBoxes;

//---------------------------------------------------------------------------
type
 TGuiComboBox = class(TGuiControl)
 private
  EnabledAlpha: Integer;
  DownAlpha   : Integer;
  FocusAlpha  : Integer;

  FListBox: TGuiListBox;

  FItemHeight : Integer;
  FItemsInList: Integer;

  OrigHeight: Integer;
  OrigIndex : Integer;
  FItems: TStringList;
  FItemIndex: Integer;

  FTextFontName: StdString;

  FTextHorizShift: Integer;
  FTextVertShift : Integer;

  FTextIconSpace: Integer;
  FIconImageName: StdString;
  FIconVertShift: Integer;
  FIconPatternStart: Integer;
  FTextVertAdjust: Integer;
  FIconVertAdjust: Integer;

  IndexChangeTag: Integer;

  procedure PaintText(const PaintRect: TRect);

  procedure CreateListBox();
  procedure DestroyListBox();
  procedure ListBoxChange(Sender: TObject);
  procedure ListBoxAffirm(Sender: TObject);
  procedure SetItemIndex(const Value: Integer);
 protected
  procedure DoPaint(); override;
  procedure DoUpdate(); override;

  procedure DoMouseEvent(const MousePos: TPoint2px; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TGuiShiftState); override;

  procedure DoKeyEvent(Key: Integer; Event: TKeyEventType;
   Shift: TGuiShiftState); override;

  procedure FirstTimePaint(); override;
  procedure SelfDescribe(); override;
 public
  property ListBox: TGuiListBox read FListBox;

  property Items: TStringList read FItems;

  property ItemIndex: Integer read FItemIndex write SetItemIndex;

  property ItemHeight : Integer read FItemHeight write FItemHeight;
  property ItemsInList: Integer read FItemsInList write FItemsInList;

  property TextFontName: StdString read FTextFontName write FTextFontName;

  property TextHorizShift: Integer read FTextHorizShift write FTextHorizShift;
  property TextVertShift : Integer read FTextVertShift write FTextVertShift;

  property TextIconSpace: Integer read FTextIconSpace write FTextIconSpace;
  property IconVertShift: Integer read FIconVertShift write FIconVertShift;

  property IconImageName: StdString read FIconImageName write FIconImageName;
  property IconPatternStart: Integer read FIconPatternStart
   write FIconPatternStart;

  property TextVertAdjust: Integer read FTextVertAdjust write FTextVertAdjust;
  property IconVertAdjust: Integer read FIconVertAdjust write FIconVertAdjust;

  property TabOrder;

  procedure AcceptKey(Key: Integer; Event: TKeyEventType;
   Shift: TGuiShiftState); override;

  constructor Create(const AOwner: TGuiControl); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types, Asphyre.Images, Asphyre.Fonts, Asphyre.UI.Globals;

//---------------------------------------------------------------------------
constructor TGuiComboBox.Create(const AOwner: TGuiControl);
begin
 FItems:= TStringList.Create();

 inherited;

 Width := 120;
 Height:= 24;

 FItemHeight := 18;
 FItemsInList:= 5;

 FTextHorizShift:= 4;
 FTextVertShift := 1;

 FIconPatternStart:= 0;
 FIconVertShift:= -1;

 FIconImageName:= '';

 FTextFontName:= '';
 FTextIconSpace:= 4;

 FTextVertAdjust:= -1;
 FIconVertAdjust:= -1;

 FItemIndex:= 0;

 FListBox:= nil;
end;

//---------------------------------------------------------------------------
destructor TGuiComboBox.Destroy();
begin
 FreeAndNil(FItems);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.PaintText(const PaintRect: TRect);
var
 PrevRect: TRect;
 TextFont: TAsphyreFont;
 TextSize: TPoint2px;
 ImageIndex: Integer;
 HorizAdd  : Integer;
 ImageSize : TPoint2px;
 Image : TAsphyreImage;
 DrawAt: TPoint2px;
 Text  : UniString;
begin
 if (FItemIndex < 0)or(FItemIndex >= FItems.Count) then Exit;

 TextFont:= RetrieveGuiFont(FTextFontName);
 if (not Assigned(TextFont)) then Exit;

 PrevRect:= GuiCanvas.ClipRect;
 GuiCanvas.ClipRect:= PaintRect;

 Image:= nil;
 if (FIconImageName <> '') then
  begin
   ImageIndex:= GuiImages.Resolve(FIconImageName);

   if (ImageIndex <> -1) then
    Image:= GuiImages[ImageIndex];
  end;

 HorizAdd:= 0;
 if (Assigned(Image))and(Image.VisibleSize.y > 0) then
  begin
   ImageSize.y:= Min2(Image.VisibleSize.y, FItemHeight);
   ImageSize.x:= (ImageSize.y * Image.VisibleSize.x) div Image.VisibleSize.y;

   HorizAdd:= ImageSize.x + FTextIconSpace;
  end;

 Text:= FItems[FItemIndex];

 TextSize:= TextFont.TexExtent(Text);

 DrawAt.x:= PaintRect.Left + FTextHorizShift + HorizAdd;
 DrawAt.y:= FTextVertAdjust + (PaintRect.Top + PaintRect.Bottom -
  TextSize.y) div 2;

 GuiDrawControlText(DrawAt, Text, TextFont, 1.0, EnabledAlpha);

 DrawAt.x:= PaintRect.Left + FTextHorizShift;
 DrawAt.y:= FIconVertAdjust + (PaintRect.Top + PaintRect.Bottom -
  ImageSize.y) div 2;

 GuiDrawGlyph(DrawAt, Image, FIconPatternStart + FItemIndex, 1.0, EnabledAlpha);

 GuiCanvas.ClipRect:= PrevRect;
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.DoPaint();
var
 PaintRect: TRect;
 ArrowAt  : TPoint2px;
 ArrowSize: TPoint2px;
 ArrowRect: TRect;
 EnAlpha  : Single;
 CompAlpha: Single;
begin
 if (not Focused)and(Assigned(FListBox)) then DestroyListBox();

 PaintRect:= VirtualRect;

 if (Assigned(FListBox)) then
  PaintRect.Bottom:= PaintRect.Top + OrigHeight;

 EnAlpha  := GuiComputeTheta(EnabledAlpha);
 CompAlpha:= Lerp(1.0, GuiButtonDisabledAlpha, 1.0 - EnAlpha);

 ArrowSize.y:= Height - 6;

 if (Assigned(FListBox)) then
  ArrowSize.y:= OrigHeight - 6;

 ArrowSize.x:= ArrowSize.y;

 if (ArrowSize.x > Width div 4) then
  ArrowSize.x:= Width div 4;

 ArrowAt.x:= Width - (ArrowSize.x + 3);
 ArrowAt.y:= 3;

 ArrowRect:= Bounds(PaintRect.Left + ArrowAt.x, PaintRect.Top + ArrowAt.y,
  ArrowSize.x, ArrowSize.y);

 GuiDrawControlFill(PaintRect);

 if (FocusAlpha > 0)and(not GuiDesign) then
  GuiDrawCtrlFocus(PaintRect, FocusAlpha);

 GuiDrawButtonFill(ArrowRect, CompAlpha, EnabledAlpha, DownAlpha);

 GuiPaintSystemIcon(ArrowRect, 1, CompAlpha, EnabledAlpha, DownAlpha);

 GuiDrawControlBorder(ArrowRect, CompAlpha * 0.5);

 GuiDrawControlBorder(PaintRect);

 PaintRect.Right:= PaintRect.Right - (ArrowSize.x + 2);
 PaintText(ShrinkRect(PaintRect, 2, 2));
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.CreateListBox();
var
 DispItems: Integer;
begin
 if (Assigned(FListBox)) then
  begin
   Height:= OrigHeight;
   FItemIndex:= OrigIndex;

   FreeAndNil(FListBox);
  end;

 if (FItems.Count < 1) then Exit;

 BringToFront();

 OrigHeight:= Height;
 OrigIndex := FItemIndex;

 FListBox:= TGuiListBox.Create(Self);
 FListBox.ItemHeight      := FItemHeight;
 FListBox.TextFontName    := FTextFontName;
 FListBox.TextHorizShift  := FTextHorizShift;
 FListBox.TextVertShift   := FTextVertShift;
 FListBox.TextIconSpace   := FTextIconSpace;
 FListBox.IconVertShift   := FIconVertShift;
 FListBox.IconImageName   := FIconImageName;
 FListBox.IconPatternStart:= FIconPatternStart;

 DispItems:= Min2(FItemsInList, FItems.Count);

 FListBox.SetSize(Point2px(Width, DispItems * FListBox.ItemHeight + 4));
 FListBox.Left:= 0;
 FListBox.Top := Height + 2;

 FListBox.Items.Assign(FItems);
 FListBox.ItemIndex:= FItemIndex;
 FListBox.OnChange:= ListBoxChange;
 FListBox.OnItemAffirm:= ListBoxAffirm;

 Height:= FListBox.Top + FListBox.Height;
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.DestroyListBox();
begin
 if (Assigned(FListBox)) then
  begin
   Height:= OrigHeight;
   FreeAndNil(FListBox);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.DoMouseEvent(const MousePos: TPoint2px;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TGuiShiftState);
begin
 case Event of
  metDown:
   if (Button = mbtLeft) then
    begin
     if (not Assigned(FListBox)) then
      CreateListBox()
       else DestroyListBox();
    end;

  metWheelUp,
  metWheelDown:
   if (Assigned(FListBox)) then
    FListBox.AcceptMouse(MousePos, Event, Button, Shift);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.DoKeyEvent(Key: Integer; Event: TKeyEventType;
 Shift: TGuiShiftState);
begin
 if (Event = ketDown) then
  case Key of
   AVK_Up,
   AVK_Left:
    FItemIndex:= Max2(FItemIndex - 1, 0);

   AVK_Down,
   AVK_Right:
    FItemIndex:= Min2(FItemIndex + 1, FItems.Count - 1);

   AVK_Space,
   AVK_Return:
    CreateListBox();
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.AcceptKey(Key: Integer; Event: TKeyEventType;
 Shift: TGuiShiftState);
var
 Handled: Boolean;
begin
 Handled:= False;

 case Key of
  AVK_Tab:
   if (Event = ketDown) then
    begin
     SendFocusToNext();
     Handled:= True;
    end;

  AVK_Escape:
   begin
    if (Event = ketDown)and(Assigned(FListBox)) then
     begin
      FItemIndex:= OrigIndex;
      DestroyListBox();
     end;

    Handled:= True;
   end;
 end;

 if (not Handled) then
  begin
   if (not Assigned(FListBox)) then
    DoKeyEvent(Key, Event, Shift)
     else FListBox.AcceptKey(Key, Event, Shift);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.FirstTimePaint();
begin
 inherited;

 if (Enabled) then
  EnabledAlpha:= 255
   else EnabledAlpha:= 0;

 if (Assigned(FListBox)) then
  DownAlpha:= 255
   else DownAlpha:= 0;

 if (Focused)and(Enabled) then
  FocusAlpha:= 255
   else FocusAlpha:= 0;
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.DoUpdate();
begin
 inherited;

 if (Enabled) then
  EnabledAlpha:= Min2(EnabledAlpha + 16, 255)
   else EnabledAlpha:= Max2(EnabledAlpha - 12, 0);

 if (Assigned(FListBox)) then
  DownAlpha:= Min2(DownAlpha + 48, 255)
   else DownAlpha:= Max2(DownAlpha - 32, 0);

 if (Focused)and(Enabled) then
  FocusAlpha:= Min2(FocusAlpha + 22, 255)
   else FocusAlpha:= Max2(FocusAlpha - 16, 0);
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.ListBoxChange(Sender: TObject);
begin
 if (Assigned(Sender))and(Sender is TGuiListBox) then
  FItemIndex:= TGuiListBox(Sender).ItemIndex;
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.ListBoxAffirm(Sender: TObject);
begin
 if (Assigned(Sender))and(Sender is TGuiListBox)and(Sender = FListBox) then
  DestroyListBox();
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.SelfDescribe();
begin
 inherited;

 FNameOfClass:= 'TGuiComboBox';

 AddProperty('TextFontName', gptString, gpfStdString, @FTextFontName);

 AddProperty('ItemHeight', gptInteger,  gpfInteger, @FItemHeight,
  SizeOf(Integer));

 AddProperty('Items', gptStrings,  gpfStrings, Pointer(FItems));
 AddProperty('ItemIndex', gptInteger, gpfInteger, @FItemIndex,
  SizeOf(Integer), IndexChangeTag);

 AddProperty('TextHorizShift', gptInteger, gpfInteger, @FTextHorizShift,
  SizeOf(Integer));

 AddProperty('TextVertShift', gptInteger, gpfInteger, @FTextVertShift,
  SizeOf(Integer));

 AddProperty('TextIconSpace', gptInteger, gpfInteger, @FTextIconSpace,
  SizeOf(Integer));

 AddProperty('IconVertShift', gptInteger, gpfInteger, @FIconVertShift,
  SizeOf(Integer));

 AddProperty('TextVertAdjust', gptInteger, gpfInteger, @FTextVertAdjust,
  SizeOf(Integer));

 AddProperty('IconVertAdjust', gptInteger, gpfInteger, @FIconVertAdjust,
  SizeOf(Integer));

 AddProperty('IconImageName', gptString, gpfStdString, @FIconImageName);

 AddProperty('IconPatternStart', gptInteger, gpfInteger,
  @FIconPatternStart, SizeOf(Integer));

 AddProperty('TabOrder', gptInteger, gpfInteger, @FTabOrder,
  SizeOf(Integer));
end;

//---------------------------------------------------------------------------
procedure TGuiComboBox.SetItemIndex(const Value: Integer);
begin
 FItemIndex:= Value;

 if (Assigned(FListBox)) then
  FListBox.ItemIndex:= FItemIndex;
end;

//---------------------------------------------------------------------------
end.
