unit Asphyre.UI.TrackBars;
//---------------------------------------------------------------------------
// Track Bar controls for Asphyre GUI framework.
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
 System.Types, Asphyre.TypeDef, Asphyre.Math, Asphyre.UI.Types, 
 Asphyre.UI.Controls, Asphyre.UI.Buttons;

//---------------------------------------------------------------------------
type
 TGuiTrackBar = class(TGuiControl)
 private
  ScrollButton: TGuiButton;

  FMinScroll: Integer;
  FMaxScroll: Integer;
  FScrollPos: Integer;

  ScrollArea: Integer;
  ScrollTop : Integer;

  ScrollClickAt: TPoint2px;
  ScrollButTop : Integer;
  FSmallChange : Integer;
  FLargeChange : Integer;

  ScrollPrevClick: Integer;
  ScrollPrevTop  : Integer;

  ScrollPosTag: Integer;

  FocusAlpha  : Integer;
  EnabledAlpha: Integer;

  procedure SetScrollPos(const Value: Integer);
  procedure SetScrollParam(const Index, Value: Integer);

  function GetButSize(): Integer;

  procedure UpdateParams();

  procedure ScrollMouseEvent(Sender: TObject; const MousePos: TPoint2px;
   Event: TMouseEventType; Button: TMouseButtonType; Shift: TGuiShiftState);
 protected
  procedure DoResize(); override;
  procedure FirstTimePaint(); override;

  procedure DoPaint(); override;
  procedure DoUpdate(); override;
  procedure DoMouseEvent(const MousePos: TPoint2px; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TGuiShiftState); override;

  procedure DoKeyEvent(Key: Integer; Event: TKeyEventType;
   Shift: TGuiShiftState); override;

  procedure SelfDescribe(); override;

  procedure AfterChange(const AFieldName: StdString;
   PropType: TGuiPropertyType; PropTag: Integer); override;
 public
  property MinScroll: Integer index 0 read FMinScroll write SetScrollParam;
  property MaxScroll: Integer index 1 read FMaxScroll write SetScrollParam;
  property ScrollPos: Integer read FScrollPos write SetScrollPos;

  property SmallChange: Integer read FSmallChange write FSmallChange;
  property LargeChange: Integer read FLargeChange write FLargeChange;

  procedure AcceptKey(Key: Integer; Event: TKeyEventType;
   Shift: TGuiShiftState); override;

  constructor Create(const AOwner: TGuiControl); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types, Asphyre.UI.Globals;

//---------------------------------------------------------------------------
constructor TGuiTrackBar.Create(const AOwner: TGuiControl);
begin
 inherited;

 ScrollButton:= TGuiButton.Create(Self);
 ScrollButton.OnMouse   := ScrollMouseEvent;
 ScrollButton.ButtonType:= gbtTrackSvc;

 FMinScroll:= 0;
 FMaxScroll:= 10;
 FScrollPos:= 0;

 FSmallChange:= 1;
 FLargeChange:= 3;

 ScrollArea:= -1;
 ScrollTop := 0;

 ScrollClickAt:= InfPoint2px;

 SetSize(Point2px(140, 20));
end;

//---------------------------------------------------------------------------
destructor TGuiTrackBar.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiTrackBar.SetScrollPos(const Value: Integer);
begin
 FScrollPos:= MinMax2(Value, FMinScroll, FMaxScroll);

 UpdateParams();
end;

//---------------------------------------------------------------------------
procedure TGuiTrackBar.SetScrollParam(const Index, Value: Integer);
begin
 case Index of
  0: FMinScroll:= Value;
  1: FMaxScroll:= Value;
 end;

 UpdateParams();
end;

//---------------------------------------------------------------------------
function TGuiTrackBar.GetButSize(): Integer;
var
 MaxSize: Integer;
begin
 Result:= Min2(Width - 2, Height - 2);

 MaxSize:= Max2(Width, Height) div 4;
 Result:= Min2(Result, MaxSize);
end;

//---------------------------------------------------------------------------
procedure TGuiTrackBar.DoResize();
var
 ButSize, Depth: Integer;
begin
 inherited;

 ButSize:= GetButSize();

 Depth:= (ButSize * 2) div 3;

 if (Depth mod 2 = 0) then
  Dec(Depth);

 if (Width < Height) then
  begin
   ScrollButton.Left:= 1;
   ScrollButton.Top := Height div 2;
   ScrollButton.SetSize(Point2px(Width - 2, Depth));
  end else
  begin
   ScrollButton.Left:= Width div 2;
   ScrollButton.Top := 1;
   ScrollButton.SetSize(Point2px(Depth, Height - 2));
  end;

 UpdateParams();
end;

//---------------------------------------------------------------------------
procedure TGuiTrackBar.DoPaint();
var
 PaintRect, MiniRect: TRect;
 MiniAt, MiniSize: TPoint2px;
 EnAlpha, CompAlpha: Single;
begin
 if (ScrollArea = -1) then UpdateParams();

 EnAlpha  := GuiComputeTheta(EnabledAlpha);
 CompAlpha:= Lerp(1.0, GuiButtonDisabledAlpha, 1.0 - EnAlpha);

 PaintRect:= VirtualRect;

 MiniAt  := Point2px(PaintRect.Left, PaintRect.Top);
 MiniSize:= Point2px(PaintRect.Right - PaintRect.Left, PaintRect.Bottom -
  PaintRect.Top);

 if (Width > Height) then
  begin
   MiniSize.y:= MiniSize.y div 2;
   MiniAt.y  := (PaintRect.Top + PaintRect.Bottom - MiniSize.y) div 2;
  end else
  begin
   MiniSize.x:= MiniSize.x div 2;
   MiniAt.x  := (PaintRect.Left + PaintRect.Right - MiniSize.x) div 2;
  end;

 MiniRect:= Bounds(MiniAt.x, MiniAt.y, MiniSize.x, MiniSize.y);

 GuiDrawControlFill(MiniRect, CompAlpha);
 GuiDrawCtrlFocus(MiniRect, FocusAlpha);

 GuiDrawControlBorder(MiniRect, CompAlpha * 0.5);

 ScrollButton.Enabled:= Enabled;
 ScrollButton.SystemIcon:= 7;

 if (Width > Height) then
  ScrollButton.SystemIcon:= 8;
end;

//---------------------------------------------------------------------------
procedure TGuiTrackBar.DoMouseEvent(const MousePos: TPoint2px;
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
       SclRect:= ScrollButton.VirtualRect;

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
procedure TGuiTrackBar.DoKeyEvent(Key: Integer; Event: TKeyEventType;
 Shift: TGuiShiftState);
begin
 case Key of
  AVK_Left:
   if (Width > Height)and(Event = ketDown) then
    SetScrollPos(FScrollPos - FSmallChange);

  AVK_Right:
   if (Width > Height)and(Event = ketDown) then
    SetScrollPos(FScrollPos + FSmallChange);

  AVK_Up:
   if (Width < Height)and(Event = ketDown) then
    SetScrollPos(FScrollPos - FSmallChange);

  AVK_Down:
   if (Width < Height)and(Event = ketDown) then
    SetScrollPos(FScrollPos + FSmallChange);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiTrackBar.ScrollMouseEvent(Sender: TObject;
 const MousePos: TPoint2px; Event: TMouseEventType; Button: TMouseButtonType;
 Shift: TGuiShiftState);
var
 Delta, NewTop: Integer;
begin
 case Event of
  metDown:
   if (Button = mbtLeft) then
    begin
     ScrollClickAt:= MousePos;

     ScrollPrevClick:= FScrollPos;

     if (Width < Height) then
      begin
       ScrollButTop := ScrollButton.Top - ScrollTop;
       ScrollPrevTop:= ScrollButton.Top;
      end else
      begin
       ScrollButTop := ScrollButton.Left - ScrollTop;
       ScrollPrevTop:= ScrollButton.Left;
      end;
    end;

  metMove:
   if (ScrollClickAt <> InfPoint2px)and(ScrollArea > 0) then
    begin
     if (Width < Height) then
      Delta:= MousePos.y - ScrollClickAt.y
       else Delta:= MousePos.x - ScrollClickAt.x;

     NewTop:= MinMax2(ScrollButTop + Delta, 0, ScrollArea);

     if (Width < Height) then
      ScrollButton.Top:= ScrollTop + NewTop
       else ScrollButton.Left:= ScrollTop + NewTop;

     FScrollPos:= FMinScroll + Round(NewTop *
      (FMaxScroll - FMinScroll) / ScrollArea);

     if (Width < Height)and(Abs(MousePos.x - ScrollClickAt.x) >=
      GuiScrollDragCancelTreshold) then
      begin
       FScrollPos:= ScrollPrevClick;
       ScrollButton.Top:= ScrollPrevTop;
      end;

     if (Width > Height)and(Abs(MousePos.y - ScrollClickAt.y) >=
      GuiScrollDragCancelTreshold) then
      begin
       FScrollPos:= ScrollPrevClick;
       ScrollButton.Left:= ScrollPrevTop;
      end;
    end;

  metUp:
   ScrollClickAt:= InfPoint2px;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiTrackBar.UpdateParams();
const
 BlankSpace = 3;
var
 ScrollTotal, ViewSize: Integer;
 Theta: Single;
begin
 FScrollPos:= MinMax2(FScrollPos, FMinScroll, FMaxScroll);

 ScrollArea:= 0;

 ScrollTotal:= (FMaxScroll - FMinScroll) + 1;
 if (ScrollTotal <= 0) then Exit;

 if (Width < Height) then
  begin
   ViewSize:= Height - (BlankSpace * 2);

   ScrollArea:= Max2(ViewSize - ScrollButton.Height, 0);
   ScrollTop := BlankSpace;

   if (FMaxScroll > FMinScroll) then
    Theta:= (FScrollPos - FMinScroll) / (FMaxScroll - FMinScroll)
     else Theta:= 0.0;

   ScrollButton.Top:= ScrollTop + Round(Theta * ScrollArea);
  end else
  begin
   ViewSize:= Width - (BlankSpace * 2);

   ScrollArea:= Max2(ViewSize - ScrollButton.Width, 0);
   ScrollTop := BlankSpace;

   if (FMaxScroll > FMinScroll) then
    Theta:= (FScrollPos - FMinScroll) / (FMaxScroll - FMinScroll)
     else Theta:= 0.0;

   ScrollButton.Left:= ScrollTop + Round(Theta * ScrollArea);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiTrackBar.DoUpdate();
begin
 inherited;

 if (Enabled) then
  EnabledAlpha:= Min2(EnabledAlpha + 16, 255)
   else EnabledAlpha:= Max2(EnabledAlpha - 12, 0);

 if (Focused)and(Enabled) then
  FocusAlpha:= Min2(FocusAlpha + 22, 255)
   else FocusAlpha:= Max2(FocusAlpha - 16, 0);
end;

//---------------------------------------------------------------------------
procedure TGuiTrackBar.FirstTimePaint();
begin
 inherited;

 if (Enabled) then
  EnabledAlpha:= 255
   else EnabledAlpha:= 0;

 if (Focused)and(Enabled) then
  FocusAlpha:= 255
   else FocusAlpha:= 0;
end;

//---------------------------------------------------------------------------
procedure TGuiTrackBar.SelfDescribe();
begin
 inherited;

 ScrollPosTag:= NextFieldTag();

 FNameOfClass:= 'TGuiTrackBar';

 AddProperty('MinScroll', gptInteger, gpfInteger, @FMinScroll,
  SizeOf(Integer), ScrollPosTag);

 AddProperty('MaxScroll', gptInteger, gpfInteger, @FMaxScroll,
  SizeOf(Integer), ScrollPosTag);

 AddProperty('ScrollPos', gptInteger, gpfInteger, @FScrollPos,
  SizeOf(Integer), ScrollPosTag);

 AddProperty('SmallChange', gptInteger, gpfInteger, @FSmallChange,
  SizeOf(Integer));

 AddProperty('LargeChange', gptInteger, gpfInteger, @FLargeChange,
  SizeOf(Integer));
end;

//---------------------------------------------------------------------------
procedure TGuiTrackBar.AcceptKey(Key: Integer; Event: TKeyEventType;
 Shift: TGuiShiftState);
begin
 if (Key in [AVK_Left, AVK_Right, AVK_Up, AVK_Down]) then
  DoKeyEvent(Key, Event, Shift)
   else inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiTrackBar.AfterChange(const AFieldName: StdString;
 PropType: TGuiPropertyType; PropTag: Integer);
begin
 inherited;

 if (PropTag = ScrollPosTag) then
  UpdateParams();
end;

//---------------------------------------------------------------------------
end.
