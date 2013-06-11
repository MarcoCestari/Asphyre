unit Asphyre.UI.ListBoxes;
//---------------------------------------------------------------------------
// List Box controls for Asphyre GUI framework.
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
 Asphyre.Math, Asphyre.Types, Asphyre.UI.Types, Asphyre.UI.Controls, 
 Asphyre.UI.ScrollBars, Asphyre.UI.SelectLists;

//---------------------------------------------------------------------------
type
 TGuiListBox = class(TGuiControl)
 private
  FScrollBar: TGuiScrollBar;

  FTextFontName: StdString;

  EnabledAlpha: Integer;
  FocusAlpha  : Integer;
  FItemHeight : Integer;
  FItems: TStringList;

  FTextHorizShift: Integer;
  FTextVertShift : Integer;

  ListViewSize : Integer;
  ListTotalSize: Integer;
  FItemIndex: Integer;

  FixMouseScroll: Boolean;
  FixMouseImmediate: Boolean;

  FSelectedItems: TGuiSelectItems;
  FPointedItems : TGuiSelectItems;
  PointedIndex : Integer;
  PrevMouseClickIndex: Integer;

  LastMousePos: TPoint2px;
  MousePressed: Boolean;

  FTextIconSpace: Integer;
  FIconImageName: StdString;
  FIconVertShift: Integer;
  FIconPatternStart: Integer;
  FOnChange: TNotifyEvent;

  IndexChangeTag : Integer;
  ChangePrevIndex: Integer;
  FOnItemAffirm: TNotifyEvent;

  procedure UpdateScrollBar();
  procedure UpdatePointedIndex();
  procedure CheckMouseScroll();
  procedure DrawItems(const PaintRect: TRect);
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

  procedure BeforeChange(const AFieldName: StdString;
   PropType: TGuiPropertyType; PropTag: Integer;
   var Proceed: Boolean); override;

  procedure AfterChange(const AFieldName: StdString;
   PropType: TGuiPropertyType; PropTag: Integer); override;
 public
  property ScrollBar: TGuiScrollBar read FScrollBar;

  property TextFontName: StdString read FTextFontName write FTextFontName;

  property ItemHeight: Integer read FItemHeight write FItemHeight;
  property Items: TStringList read FItems;

  property ItemIndex: Integer read FItemIndex write SetItemIndex;

  property TextHorizShift: Integer read FTextHorizShift write FTextHorizShift;
  property TextVertShift : Integer read FTextVertShift write FTextVertShift;

  property TextIconSpace: Integer read FTextIconSpace write FTextIconSpace;
  property IconVertShift: Integer read FIconVertShift write FIconVertShift;

  property IconImageName: StdString read FIconImageName write FIconImageName;
  property IconPatternStart: Integer read FIconPatternStart
   write FIconPatternStart;

  property PointedItems: TGuiSelectItems read FPointedItems;
  property SelectedItems: TGuiSelectItems read FSelectedItems;

  procedure AcceptKey(Key: Integer; Event: TKeyEventType;
   Shift: TGuiShiftState); override;

  property OnChange: TNotifyEvent read FOnChange write FOnChange;
  property OnItemAffirm: TNotifyEvent read FOnItemAffirm write FOnItemAffirm;
  property TabOrder;

  constructor Create(const AOwner: TGuiControl); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Fonts, Asphyre.Images, Asphyre.Canvas, Asphyre.UI.Globals;

//---------------------------------------------------------------------------
constructor TGuiListBox.Create(const AOwner: TGuiControl);
begin
 FItems:= TStringList.Create();

 inherited;

 FSelectedItems:= TGuiSelectItems.Create();
 FSelectedItems.AlphaInc:= 24;
 FSelectedItems.AlphaDec:= 16;

 FPointedItems:= TGuiSelectItems.Create();
 FPointedItems.AlphaInc:= 32;
 FPointedItems.AlphaDec:= 24;

 FScrollBar:= TGuiScrollBar.Create(Self);
 FScrollBar.Visible:= False;
 FScrollBar.AutoScrollSpeed:= 30.0;
 FScrollBar.SmallChange:= 4;
 FScrollBar.LargeChange:= 18;

 FTextFontName:= '';
 FTextIconSpace:= 4;

 FItemHeight:= 18;

 FTextHorizShift:= 4;
 FTextVertShift := 1;

 FIconPatternStart:= 0;
 FIconVertShift:= -1;

 FIconImageName:= '';

 FItemIndex  := -1;
 PointedIndex:= -1;
 LastMousePos:= InfPoint2px;
 MousePressed:= False;

 Width := 120;
 Height:= 80;

 FixMouseScroll:= False;
 FixMouseImmediate:= False;
end;

//---------------------------------------------------------------------------
destructor TGuiListBox.Destroy();
begin
 FreeAndNil(FPointedItems);
 FreeAndNil(FSelectedItems);

 inherited;

 FreeAndNil(FItems);
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.UpdateScrollBar();
begin
 ListViewSize := Height - 4;
 ListTotalSize:= FItems.Count * FItemHeight;

 FScrollBar.SetSize(Point2px(18, Height));

 FScrollBar.Left:= Width - FScrollBar.Width;
 FScrollBar.Top := 0;

 FScrollBar.Enabled:= Enabled;

 FScrollBar.MaxScroll:= Max2(ListTotalSize - ListViewSize, 0);

 FScrollBar.LargeChange:= ListViewSize;
 FScrolLBar.SmallChange:= Max2(FItemHeight div 4, 1);

 if (ListTotalSize > 0.0) then
  FScrollBar.PageSize:= ListViewSize / ListTotalSize
   else FScrollBar.PageSize:= 0.0;

 FScrollBar.Visible:= ListViewSize < ListTotalSize;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.UpdatePointedIndex();
var
 DrawAt: TPoint2px;
 PaintRect, SelectRect: TRect;
 i, Index, InitElem, ElemOfs, ElemCount: Integer;
begin
 PointedIndex:= -1;
 FPointedItems.SelectIndex:= -1;

 if (FItemHeight < 1)or(LastMousePos = InfPoint2px)or
  (FScrollBar.MouseOver)or(FItems.Count < 1) then Exit;

 PaintRect:= ShrinkRect(VirtualRect, 2, 2);

 InitElem := FScrollBar.ScrollPos div FItemHeight;
 ElemOfs  := FScrollBar.ScrollPos mod FItemHeight;
 ElemCount:= ListViewSize div FItemHeight;

 if (LastMousePos.y < PaintRect.Top + 2) then
  begin
   if (MousePressed) then
    begin
     PointedIndex:= InitElem;
     if (PointedIndex < 0) then PointedIndex:= 0;

     FPointedItems.SelectIndex:= PointedIndex;
    end;

   Exit;
  end;

 if (LastMousePos.y > PaintRect.Bottom + 1) then
  begin
   if (MousePressed) then
    begin
     PointedIndex:= InitElem + ElemCount;
     if (PointedIndex >= FItems.Count) then PointedIndex:= FItems.Count - 1;

     FPointedItems.SelectIndex:= PointedIndex;
    end;

   Exit;
  end;

 if (not MouseOver)or(not PointInRect(LastMousePos, PaintRect)) then Exit;

 for i:= -1 to ElemCount do
  begin
   Index:= InitElem + i;
   if (Index < 0)or(Index >= FItems.Count) then Continue;

   DrawAt.x:= PaintRect.Left;
   DrawAt.y:= PaintRect.Top + (Index - InitElem) * FItemHeight - ElemOfs;

   SelectRect:= Bounds(DrawAt.x, DrawAt.y, PaintRect.Right - PaintRect.Left,
    FItemHeight);

   if (PointInRect(LastMousePos, SelectRect)) then
    begin
     PointedIndex:= Index;
     Break;
    end;
  end;

 FPointedItems.SelectIndex:= PointedIndex;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.DrawItems(const PaintRect: TRect);
var
 SelItem : PGuiSelectItem;
 TextFont: TAsphyreFont;
 PrevRect: TRect;
 DrawAt, ImageSize: TPoint2px;
 SelectRect: TRect;
 Text: UniString;
 i, Index, InitElem, ElemOfs, ElemCount, ImageIndex, HorizAdd: Integer;
 EnAlpha: Single;
 Image: TAsphyreImage;
begin
 if (FItemHeight < 1) then Exit;

 TextFont:= RetrieveGuiFont(FTextFontName);
 if (not Assigned(TextFont)) then Exit;

 PrevRect:= GuiCanvas.ClipRect;
 GuiCanvas.ClipRect:= ShortRect(PrevRect, PaintRect);

 InitElem := FScrollBar.ScrollPos div FItemHeight;
 ElemOfs  := FScrollBar.ScrollPos mod FItemHeight;
 ElemCount:= ListViewSize div FItemHeight;

 EnAlpha:= GuiComputeTheta(EnabledAlpha);

 if (EnAlpha > 0.0)and(not GuiDesign) then
  for i:= 0 to FSelectedItems.ItemCount - 1 do
   begin
    SelItem:= FSelectedItems[i];
    if (not Assigned(SelItem)) then Continue;

    DrawAt.x:= PaintRect.Left;
    DrawAt.y:= PaintRect.Top + (SelItem.Index - InitElem) * FItemHeight -
     ElemOfs;

    SelectRect:= Bounds(DrawAt.x, DrawAt.y, PaintRect.Right -
     PaintRect.Left, FItemHeight);

    if (OverlapRect(SelectRect, GuiCanvas.ClipRect)) then
     GuiDrawItemSelection(SelectRect, EnAlpha *
      SineTheta(SelItem.Alpha / 255.0));
   end;

 if (EnAlpha > 0.0)and(not GuiDesign) then
  for i:= 0 to FPointedItems.ItemCount - 1 do
   begin
    SelItem:= FPointedItems[i];
    if (not Assigned(SelItem)) then Continue;

    DrawAt.x:= PaintRect.Left;
    DrawAt.y:= PaintRect.Top + (SelItem.Index - InitElem) * FItemHeight -
     ElemOfs;

    SelectRect:= Bounds(DrawAt.x, DrawAt.y, PaintRect.Right -
     PaintRect.Left, FItemHeight);

    if (OverlapRect(SelectRect, GuiCanvas.ClipRect)) then
     GuiDrawItemPointed(SelectRect, EnAlpha * SineTheta(SelItem.Alpha / 255.0));
   end;

 Image:= nil;
 if (FIconImageName <> '') then
  begin
   ImageIndex:= GuiImages.Resolve(FIconImageName);
   if (ImageIndex <> -1) then Image:= GuiImages[ImageIndex];
  end;

 HorizAdd:= 0;
 if (Assigned(Image))and(Image.VisibleSize.y > 0) then
  begin
   ImageSize.y:= Min2(Image.VisibleSize.y, FItemHeight);
   ImageSize.x:= (ImageSize.y * Image.VisibleSize.x) div Image.VisibleSize.y;

   HorizAdd:= ImageSize.x + FTextIconSpace;
  end;

 for i:= -1 to ElemCount do
  begin
   Index:= InitElem + i;
   if (Index < 0)or(Index >= FItems.Count) then Continue;

   Text:= FItems[Index];

   DrawAt.x:= PaintRect.Left + FTextHorizShift + HorizAdd;
   DrawAt.y:= PaintRect.Top + i * FItemHeight + FTextVertShift - ElemOfs;

   GuiDrawControlText(DrawAt, Text, TextFont, 1.0, EnabledAlpha);
  end;

 if (Assigned(Image)) then
  for i:= -1 to ElemCount do
   begin
    Index:= InitElem + i;
    if (Index < 0)or(Index >= FItems.Count) then Continue;

    DrawAt.x:= PaintRect.Left + FTextHorizShift;
    DrawAt.y:= PaintRect.Top + i * FItemHeight + FTextVertShift - ElemOfs;

    Inc(DrawAt.y, ((FItemHeight - ImageSize.y) div 2) + FIconVertShift);

    GuiDrawGlyph(DrawAt, Image, Index + FIconPatternStart, 1.0, EnabledAlpha);
   end;

 GuiCanvas.ClipRect:= PrevRect;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.DoPaint();
var
 PaintRect: TRect;
 PrevIndex: Integer;
 CustColor: Cardinal;
begin
 UpdateScrollBar();

 UpdatePointedIndex();

 if (MousePressed)and(PointedIndex <> -1) then
  begin
   PrevIndex:= FItemIndex;

   FItemIndex:= PointedIndex;
   if (FItemIndex <> -1)and(FItemIndex <> PrevIndex) then
    begin
     if (Assigned(FOnChange)) then FOnChange(Self);
     FixMouseScroll:= True;
    end;
  end;

 PaintRect:= VirtualRect;

 if (FScrollBar.Visible) then Dec(PaintRect.Right, (FScrollBar.Width - 1));

 GuiDrawControlFill(PaintRect);

 if (FocusAlpha > 0)and(not GuiDesign) then
  GuiDrawCtrlFocus(PaintRect, FocusAlpha);

 DrawItems(ShrinkRect(PaintRect, 2, 2));

 if (FScrollBar.Visible) then
  begin
   CustColor:= cColorAlpha1f(GuiBorderColor, GuiGlobalAlpha);

   GuiCanvas.HorizLine(PaintRect.Left, PaintRect.Top, PaintRect.Right -
    PaintRect.Left, CustColor);

   GuiCanvas.HorizLine(PaintRect.Left, PaintRect.Bottom - 1, PaintRect.Right -
    PaintRect.Left, CustColor);

   GuiCanvas.VertLine(PaintRect.Left, PaintRect.Top + 1, (PaintRect.Bottom -
    PaintRect.Top) - 2, CustColor);
  end else GuiDrawControlBorder(PaintRect);
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.FirstTimePaint();
begin
 inherited;

 if (Enabled) then EnabledAlpha:= 255
  else EnabledAlpha:= 0;

 if (Focused)and(Enabled) then FocusAlpha:= 255
  else FocusAlpha:= 0;

 FSelectedItems.SelectIndex:= FItemIndex;
 FSelectedItems.Reset();

 FPointedItems.SelectIndex:= -1;
 FPointedItems.Reset();

 PointedIndex:= -1;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.DoUpdate();
var
 PaintRect: TRect;
begin
 inherited;

 if (Enabled) then EnabledAlpha:= Min2(EnabledAlpha + 16, 255)
  else EnabledAlpha:= Max2(EnabledAlpha - 12, 0);

 if (Focused)and(Enabled) then FocusAlpha:= Min2(FocusAlpha + 22, 255)
  else FocusAlpha:= Max2(FocusAlpha - 16, 0);

 FSelectedItems.SelectIndex:= FItemIndex;
 FSelectedItems.Update();

 FPointedItems.Update();

 PaintRect:= VirtualRect;

 if (FixMouseScroll) then CheckMouseScroll();

 if (MousePressed)and(not FixMouseScroll) then
  begin
   if (LastMousePos.y < PaintRect.Top) then
    FScrollBar.ScrollPos:= FScrollBar.ScrollPos -
     Max2(FScrollBar.SmallChange div 2, 1);

   if (LastMousePos.y >= PaintRect.Bottom) then
    FScrollBar.ScrollPos:= FScrollBar.ScrollPos +
     Max2(FScrollBar.SmallChange div 2, 1);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.CheckMouseScroll();
var
 InitElem, ElemOfs, FixAt: Integer;
 DrawAt: TPoint2px;
 PaintRect: TRect;
begin
 if (FItemIndex < 0)or(FItemIndex >= FItems.Count) then Exit;

 PaintRect:= VirtualRect;

 InitElem:= FScrollBar.ScrollPos div FItemHeight;
 ElemOfs := FScrollBar.ScrollPos mod FItemHeight;

 DrawAt.x:= PaintRect.Left;
 DrawAt.y:= PaintRect.Top + (FItemIndex - InitElem) * FItemHeight -
  ElemOfs;

 FixMouseScroll:= False;

 if (DrawAt.y < PaintRect.Top) then
  begin
   FixAt:= FItemIndex * FItemHeight;

   if (FScrollBar.ScrollPos > FixAt) then
    FScrollBar.ScrollPos:= FScrollBar.ScrollPos -
     Max2(FScrollBar.SmallChange div 2, 1);

   FixMouseScroll:= True;

   if (FixMouseImmediate) then
    begin
     FScrollBar.ScrollPos:= FixAt;
     FixMouseScroll   := False;
     FixMouseImmediate:= False;
    end;
  end;

 if (DrawAt.y + FItemHeight >= PaintRect.Bottom) then
  begin
   FixAt:= FItemIndex * FItemHeight -
    (ListViewSize - FItemHeight);

   if (FScrollBar.ScrollPos < FixAt) then
    FScrollBar.ScrollPos:= FScrollBar.ScrollPos +
     Max2(FScrollBar.SmallChange div 2, 1);

   FixMouseScroll:= True;

   if (FixMouseImmediate) then
    begin
     FScrollBar.ScrollPos:= FixAt;
     FixMouseScroll   := False;
     FixMouseImmediate:= False;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.DoMouseEvent(const MousePos: TPoint2px;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TGuiShiftState);
begin
 inherited;

 if (GuiDesign) then Exit;

 case Event of
  metWheelUp:
   FScrollBar.ScrollPos:= FScrollBar.ScrollPos -
    (MousePos.y div FScrollBar.SmallChange);

  metWheelDown:
   FScrollBar.ScrollPos:= FScrollBar.ScrollPos +
    (MousePos.y div FScrollBar.SmallChange);

  metDown:
   if (Button = mbtLeft)and(PointedIndex <> -1) then
    begin
     MousePressed:= True;

     PrevMouseClickIndex:= FItemIndex;
     FItemIndex:= PointedIndex;

     if (PrevMouseClickIndex <> FItemIndex) then
      begin
       if (Assigned(FOnChange)) then FOnChange(Self);
       FixMouseScroll:= True;
      end;
    end;

  metUp:
   if (Button = mbtLeft) then
    begin
     MousePressed:= False;

     if (not MouseOver)and(FItemIndex <> PrevMouseClickIndex) then
      begin
       FItemIndex:= PrevMouseClickIndex;

       FSelectedItems.SelectIndex:= FItemIndex;
       FSelectedItems.Reset();

       FixMouseImmediate:= True;
       UpdateScrollBar();
       CheckMouseScroll();

       if (Assigned(FOnChange)) then FOnChange(Self);
      end;

     if (MouseOver){and(FItemIndex <> PrevMouseClickIndex)}and
      (Assigned(FOnItemAffirm)) then
      begin
       FOnItemAffirm(Self);
       Exit;
      end;
    end;
 end;

 if (Event in [metWheelUp, metWheelDown]) then
  LastMousePos:= GuiDecodeMousePos(MousePos.x)
   else LastMousePos:= MousePos;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.DoKeyEvent(Key: Integer; Event: TKeyEventType;
 Shift: TGuiShiftState);
var
 PrevIndex: Integer;
begin
 inherited;

 PrevIndex:= FItemIndex;

 if (Event = ketDown) then
  case Key of
   AVK_Up:
    FItemIndex:= Max2(FItemIndex - 1, 0);

   AVK_Down:
    FItemIndex:= Min2(FItemIndex + 1, FItems.Count - 1);

   AVK_Prior:
    FItemIndex:= Max2(FItemIndex - Max2((Height div FItemHeight) - 1, 1), 0);

   AVK_Next:
    FItemIndex:= Min2(FItemIndex + Max2((Height div FItemHeight) - 1, 1),
     FItems.Count - 1);

   AVK_Space,
   AVK_Return:
    if (FItemIndex <> -1)and(Assigned(FOnItemAffirm)) then
     begin
      FOnItemAffirm(Self);
      Exit;
     end;
  end;

 if (PrevIndex <> FItemIndex) then
  begin
   FSelectedItems.SelectIndex:= FItemIndex;
   FSelectedItems.Reset();

   FixMouseImmediate:= True;
   UpdateScrollBar();
   CheckMouseScroll();

   if (Assigned(FOnChange)) then FOnChange(Self);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.AcceptKey(Key: Integer; Event: TKeyEventType;
 Shift: TGuiShiftState);
begin
 DoKeyEvent(Key, Event, Shift);
// inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.SelfDescribe();
begin
 inherited;

 IndexChangeTag:= NextFieldTag();

 FNameOfClass:= 'TGuiListBox';

 AddProperty('TextFontName', gptString, gpfStdString, @FTextFontName);

 AddProperty('ItemHeight', gptInteger,  gpfInteger, @FItemHeight, 
  SizeOf(Integer));

 AddProperty('Items', gptStrings, gpfStrings, Pointer(FItems));
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

 AddProperty('IconImageName', gptString, gpfStdString, @FIconImageName);

 AddProperty('IconPatternStart', gptInteger, gpfInteger, 
  @FIconPatternStart, SizeOf(Integer));
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.SetItemIndex(const Value: Integer);
var
 PrevIndex: Integer;
begin
 PrevIndex:= FItemIndex;

 FItemIndex:= Value;

 if (PrevIndex <> FItemIndex) then
  begin
   FixMouseImmediate:= True;

   UpdateScrollBar();
   CheckMouseScroll();

   if (Assigned(FOnChange)) then FOnChange(Self);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.BeforeChange(const AFieldName: StdString;
 PropType: TGuiPropertyType; PropTag: Integer; var Proceed: Boolean);
begin
 inherited;

 if (PropTag = IndexChangeTag) then ChangePrevIndex:= FItemIndex;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.AfterChange(const AFieldName: StdString;
 PropType: TGuiPropertyType; PropTag: Integer);
begin
 inherited;

 if (PropTag = IndexChangeTag)and(FItemIndex <> ChangePrevIndex) then
  begin
   FSelectedItems.SelectIndex:= FItemIndex;
   FSelectedItems.Reset();

   FixMouseImmediate:= True;

   UpdateScrollBar();
   CheckMouseScroll();

   if (Assigned(FOnChange)) then FOnChange(Self);
  end;
end;

//---------------------------------------------------------------------------
end.
