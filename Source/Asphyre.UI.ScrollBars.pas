unit Asphyre.UI.ScrollBars;
//---------------------------------------------------------------------------
// Scroll bar controls for Asphyre GUI framework.
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
 System.Types, Asphyre.TypeDef, Asphyre.Math, Asphyre.Types, 
 Asphyre.UI.Types, Asphyre.UI.Controls, Asphyre.UI.Buttons;

//---------------------------------------------------------------------------
type
 TGuiScrollBar = class(TGuiControl)
 private
  Buttons: array[0..2] of TGuiButton;

  FMinScroll: Integer;
  FMaxScroll: Integer;
  FPageSize : Single;
  FScrollPos: Integer;

  ScrollArea: Integer;
  ScrollTop : Integer;

  ScrollClickAt: TPoint2px;
  ScrollButTop : Integer;
  FSmallChange : Integer;
  FLargeChange : Integer;

  ScrollPrevClick: Integer;
  ScrollPrevTop  : Integer;

  AutoScrollTimer: Integer;
  AutoScrollTicks: Integer;
  AutoScrollInc  : Integer;

  ScrollPosTag: Integer;

  FAutoScrollWait : Single;
  FAutoScrollSpeed: Single;

  procedure SetScrollPos(const Value: Integer);
  procedure SetScrollParam(const Index, Value: Integer);

  function GetButSize(): Integer;

  procedure CreateButtons();
  procedure UpdateParams();

  procedure ScrollMouseEvent(Sender: TObject; const MousePos: TPoint2px;
   Event: TMouseEventType; Button: TMouseButtonType; Shift: TGuiShiftState);
 protected
  procedure DoResize(); override;

  procedure DoPaint(); override;
  procedure DoUpdate(); override;
  procedure DoMouseEvent(const MousePos: TPoint2px; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TGuiShiftState); override;

  procedure SelfDescribe(); override;

  procedure AfterChange(const AFieldName: StdString;
   PropType: TGuiPropertyType; PropTag: Integer); override;
 public
  property MinScroll: Integer index 0 read FMinScroll write SetScrollParam;
  property MaxScroll: Integer index 1 read FMaxScroll write SetScrollParam;
  property PageSize : Single read FPageSize write FPageSize;
  property ScrollPos: Integer read FScrollPos write SetScrollPos;

  property SmallChange: Integer read FSmallChange write FSmallChange;
  property LargeChange: Integer read FLargeChange write FLargeChange;

  property AutoScrollWait : Single read FAutoScrollWait write FAutoScrollWait;
  property AutoScrollSpeed: Single read FAutoScrollSpeed write FAutoScrollSpeed;

  constructor Create(const AOwner: TGuiControl); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.UI.Globals;

//---------------------------------------------------------------------------
constructor TGuiScrollBar.Create(const AOwner: TGuiControl);
begin
 inherited;

 CreateButtons();

 FMinScroll:= 0;
 FMaxScroll:= 10;
 FPageSize := 0.0;
 FScrollPos:= 0;

 FSmallChange:= 1;
 FLargeChange:= 3;

 ScrollArea:= -1;
 ScrollTop := 0;

 AutoScrollInc:= 0;

 FAutoScrollWait := 0.5;
 FAutoScrollSpeed:= 10.0;

 ScrollClickAt:= InfPoint2px;

 SetSize(Point2px(140, 18));
end;

//---------------------------------------------------------------------------
destructor TGuiScrollBar.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiScrollBar.SetScrollPos(const Value: Integer);
begin
 FScrollPos:= MinMax2(Value, FMinScroll, FMaxScroll);

 UpdateParams();
end;

//---------------------------------------------------------------------------
procedure TGuiScrollBar.SetScrollParam(const Index, Value: Integer);
begin
 case Index of
  0: FMinScroll:= Value;
  1: FMaxScroll:= Value;
 end;

 UpdateParams();
end;

//---------------------------------------------------------------------------
procedure TGuiScrollBar.CreateButtons();
var
 i: Integer;
begin
 for i:= 0 to High(Buttons) do
  begin
   Buttons[i]:= TGuiButton.Create(Self);
   Buttons[i].ShowBorder:= False;
   Buttons[i].Tag:= i;
   Buttons[i].OnMouse:= ScrollMouseEvent;
  end;

 Buttons[2].ButtonType:= gbtScrollSvc;
end;

//---------------------------------------------------------------------------
function TGuiScrollBar.GetButSize(): Integer;
var
 MaxSize: Integer;
begin
 Result:= Min2(Width - 2, Height - 2);

 MaxSize:= Max2(Width, Height) div 4;
 Result:= Min2(Result, MaxSize);
end;

//---------------------------------------------------------------------------
procedure TGuiScrollBar.DoResize();
var
 ButSize: Integer;
begin
 inherited;

 ButSize:= GetButSize();

 if (Width < Height) then
  begin
   Buttons[0].Left:= 1;
   Buttons[0].Top := 1;
   Buttons[0].SetSize(Point2px(Width - 2, ButSize));

   Buttons[1].Left:= 1;
   Buttons[1].Top := Height - (ButSize + 1);
   Buttons[1].SetSize(Point2px(Width - 2, ButSize));

   Buttons[2].Left:= 1;
   Buttons[2].Top := Height div 2;
   Buttons[2].SetSize(Point2px(Width - 2, ButSize * 2));
  end else
  begin
   Buttons[0].Left:= 1;
   Buttons[0].Top := 1;
   Buttons[0].SetSize(Point2px(ButSize, Height - 2));

   Buttons[1].Left:= Width - (ButSize + 1);
   Buttons[1].Top := 1;
   Buttons[1].SetSize(Point2px(ButSize, Height - 2));

   Buttons[2].Left:= Width div 2;
   Buttons[2].Top := 1;
   Buttons[2].SetSize(Point2px(ButSize * 2, Height - 2));
  end;

 UpdateParams();
end;

//---------------------------------------------------------------------------
procedure TGuiScrollBar.DoPaint();
var
 PaintRect: TRect;
 ScrollPaintRect: TRect;
 ButSize: Integer;
 BorderColor: Cardinal;
 i: Integer;
begin
 if (ScrollArea = -1) then UpdateParams();

 PaintRect:= VirtualRect;
 ScrollPaintRect:= Buttons[2].VirtualRect;

 ButSize:= GetButSize();

 GuiCanvas.FillQuad(RectExtrude(PaintRect),
  cColor4Alpha1f(GuiScrollBarFillColor, GuiGlobalAlpha));

 BorderColor:= cColorAlpha1f(GuiBorderColor, GuiGlobalAlpha);

 if (Width < Height) then
  begin
   GuiCanvas.HorizLine(PaintRect.Left + 1, PaintRect.Top + ButSize + 1,
    (PaintRect.Right - PaintRect.Left) - 2, BorderColor);

   GuiCanvas.HorizLine(PaintRect.Left + 1, PaintRect.Bottom - (ButSize + 2),
    (PaintRect.Right - PaintRect.Left) - 2, BorderColor);

   GuiCanvas.HorizLine(PaintRect.Left + 1, ScrollPaintRect.Top - 1,
    (PaintRect.Right - PaintRect.Left) - 2, cColorAlpha1f(BorderColor, 0.25));

   GuiCanvas.HorizLine(PaintRect.Left + 1, ScrollPaintRect.Bottom,
    (PaintRect.Right - PaintRect.Left) - 2, cColorAlpha1f(BorderColor, 0.25));
  end else
  begin
   GuiCanvas.VertLine(PaintRect.Left + ButSize + 1, PaintRect.Top + 1,
    (PaintRect.Bottom - PaintRect.Top) - 2, BorderColor);

   GuiCanvas.VertLine(PaintRect.Right - (ButSize + 2), PaintRect.Top + 1,
    (PaintRect.Bottom - PaintRect.Top) - 2, BorderColor);

   GuiCanvas.VertLine(ScrollPaintRect.Left - 1, PaintRect.Top + 1,
    (PaintRect.Bottom - PaintRect.Top) - 2, cColorAlpha1f(BorderColor, 0.25));

   GuiCanvas.VertLine(ScrollPaintRect.Right, PaintRect.Top + 1,
    (PaintRect.Bottom - PaintRect.Top) - 2, cColorAlpha1f(BorderColor, 0.25));
  end;

 GuiDrawControlBorder(PaintRect);

 for i:= 0 to High(Buttons) do
  begin
   Buttons[i].SystemIcon:= i;
   Buttons[i].Enabled   := Enabled;
   if (Width > Height) then Buttons[i].SystemIcon:= 3 + i;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiScrollBar.DoMouseEvent(const MousePos: TPoint2px;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TGuiShiftState);
var
 ClickArea: TRect;
 SclRect: TRect;
begin
 case Event of
  metDown:
   if (Button = mbtLeft) then
    begin
     ClickArea:= ShrinkRect(VirtualRect, 1, 1);
     if (PointInRect(MousePos, ClickArea)) then
      begin
       SclRect:= Buttons[2].VirtualRect;

       if (Width < Height) then
        begin
         if (MousePos.y < SclRect.Top) then
          SetScrollPos(FScrollPos - FLargeChange);

         if (MousePos.y > SclRect.Bottom) then
          SetScrollPos(FScrollPos + FLargeChange);
        end else
        begin
         if (MousePos.x < SclRect.Left) then
          SetScrollPos(FScrollPos - FLargeChange);

         if (MousePos.x > SclRect.Right) then
          SetScrollPos(FScrollPos + FLargeChange);
        end;
      end;
    end;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiScrollBar.ScrollMouseEvent(Sender: TObject;
 const MousePos: TPoint2px; Event: TMouseEventType; Button: TMouseButtonType;
 Shift: TGuiShiftState);
var
 Delta, NewTop: Integer;
 Ctrl: TGuiControl;
begin
 if (not Assigned(Sender))or(not (Sender is TGuiControl)) then Exit;

 Ctrl:= TGuiControl(Sender);

 case Event of
  metDown:
   begin
    if (Ctrl.Tag < 2) then
     begin
      AutoScrollTimer := 0;
      AutoScrollTicks:= 0;

      AutoScrollInc:= FSmallChange;
      if (Ctrl.Tag = 0) then AutoScrollInc:= -FSmallChange;

      SetScrollPos(FScrollPos + AutoScrollInc);
     end;

    if (Ctrl.Tag = 2)and(Button = mbtLeft) then
     begin
      ScrollClickAt:= MousePos;

      ScrollPrevClick:= FScrollPos;

      if (Width < Height) then
       begin
        ScrollButTop := Buttons[2].Top - ScrollTop;
        ScrollPrevTop:= Buttons[2].Top;
       end else
       begin
        ScrollButTop := Buttons[2].Left - ScrollTop;
        ScrollPrevTop:= Buttons[2].Left;
       end;
     end;
   end;

  metMove:
   if (Ctrl.Tag = 2)and(ScrollClickAt <> InfPoint2px)and(ScrollArea > 0) then
    begin
     if (Width < Height) then Delta:= MousePos.y - ScrollClickAt.y
      else Delta:= MousePos.x - ScrollClickAt.x;

     NewTop:= MinMax2(ScrollButTop + Delta, 0, ScrollArea);

     if (Width < Height) then Buttons[2].Top:= ScrollTop + NewTop
       else Buttons[2].Left:= ScrollTop + NewTop;

     FScrollPos:= FMinScroll + Round(NewTop *
      (FMaxScroll - FMinScroll) / ScrollArea);

     if (Width < Height)and(Abs(MousePos.x - ScrollClickAt.x) >=
      GuiScrollDragCancelTreshold) then
      begin
       FScrollPos:= ScrollPrevClick;
       Buttons[2].Top:= ScrollPrevTop;
      end;

     if (Width > Height)and(Abs(MousePos.y - ScrollClickAt.y) >=
      GuiScrollDragCancelTreshold) then
      begin
       FScrollPos:= ScrollPrevClick;
       Buttons[2].Left:= ScrollPrevTop;
      end;
    end;

  metUp:
   begin
    if (Ctrl.Tag < 2) then AutoScrollInc:= 0;
    if (Ctrl.Tag = 2) then ScrollClickAt:= InfPoint2px;
   end;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiScrollBar.UpdateParams();
var
 ButSize, ScrollTotal, ViewSize, ScrollButSize: Integer;
 Theta: Single;
begin
 FScrollPos:= MinMax2(FScrollPos, FMinScroll, FMaxScroll);

 ScrollArea:= 0;

 ScrollTotal:= (FMaxScroll - FMinScroll) + 1;
 if (ScrollTotal <= 0) then Exit;

 ButSize:= GetButSize();

 if (Width < Height) then
  begin
   ViewSize:= Height - ((ButSize + 2) * 2);

   ScrollButSize:= MinMax2(Round(FPageSize * ViewSize), ButSize, ViewSize);

   ScrollArea:= Max2(ViewSize - ScrollButSize, 0);
   ScrollTop := ButSize + 2;

   Buttons[2].Height:= ScrollButSize;

   if (FMaxScroll > FMinScroll) then
    Theta:= (FScrollPos - FMinScroll) / (FMaxScroll - FMinScroll)
     else Theta:= 0.0;

   Buttons[2].Top:= ScrollTop + Round(Theta * ScrollArea);
  end else
  begin
   ViewSize:= Width - ((ButSize + 2) * 2);

   ScrollButSize:= MinMax2(Round(FPageSize * ViewSize), ButSize, ViewSize);

   ScrollArea:= Max2(ViewSize - ScrollButSize, 0);
   ScrollTop := ButSize + 2;

   Buttons[2].Width:= ScrollButSize;

   if (FMaxScroll > FMinScroll) then
    Theta:= (FScrollPos - FMinScroll) / (FMaxScroll - FMinScroll)
     else Theta:= 0.0;

   Buttons[2].Left:= ScrollTop + Round(Theta * ScrollArea);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiScrollBar.DoUpdate();
var
 AutoScrollSpeedMax: Integer;
begin
 inherited;

 if (AutoScrollInc <> 0) then
  begin
   AutoScrollSpeedMax:= Round(60.0 / FAutoScrollSpeed);

   Inc(AutoScrollTimer);
   if (AutoScrollTimer >= Round(FAutoScrollWait * 60.0)) then
    begin
     Inc(AutoScrollTicks);
     if (AutoScrollTicks >= AutoScrollSpeedMax)or(AutoScrollSpeedMax <= 1) then
      begin
       SetScrollPos(FScrollPos + AutoScrollInc);
       AutoScrollTicks:= 0;
      end;
    end else AutoScrollTicks:= AutoScrollSpeedMax;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiScrollBar.SelfDescribe();
begin
 inherited;

 ScrollPosTag:= NextFieldTag();

 FNameOfClass:= 'TGuiScrollBar';

 AddProperty('MinScroll', gptInteger, gpfInteger, @FMinScroll, 
  SizeOf(Integer), ScrollPosTag);

 AddProperty('MaxScroll', gptInteger, gpfInteger, @FMaxScroll, 
  SizeOf(Integer), ScrollPosTag);

 AddProperty('PageSize', gptFloat, gpfSingle, @FPageSize, SizeOf(Single), 
  ScrollPosTag);

 AddProperty('ScrollPos', gptInteger, gpfInteger, @FScrollPos, 
  SizeOf(Integer), ScrollPosTag);

 AddProperty('SmallChange', gptInteger, gpfInteger, @FSmallChange, 
  SizeOf(Integer));

 AddProperty('LargeChange', gptInteger, gpfInteger, @FLargeChange, 
  SizeOf(Integer));

 AddProperty('AutoScrollWait', gptFloat, gpfSingle, @FAutoScrollWait,
  SizeOf(Single));

 AddProperty('AutoScrollSpeed', gptFloat, gpfSingle, @FAutoScrollSpeed, 
  SizeOf(Single));
end;

//---------------------------------------------------------------------------
procedure TGuiScrollBar.AfterChange(const AFieldName: StdString;
 PropType: TGuiPropertyType; PropTag: Integer);
begin
 inherited;

 if (PropTag = ScrollPosTag) then UpdateParams();
end;

//---------------------------------------------------------------------------
end.
