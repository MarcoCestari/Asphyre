unit Asphyre.UI.Edits;
//---------------------------------------------------------------------------
// Edit controls for Asphyre GUI framework.
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
{$ifndef FireMonkey}
 Clipbrd,
{$endif}

 Types, Classes, Asphyre.TypeDef, Asphyre.Math, Asphyre.Math.Sets, Asphyre.Types,
 Asphyre.Fonts, Asphyre.UI.Types, Asphyre.UI.Controls;

//---------------------------------------------------------------------------
type
 TGuiEdit = class(TGuiControl)
 private
  TextRect : TRect;
  DispFont : TAsphyreFont;

  FText     : StdString;
  FScrollPos: Integer;
  FMaxLength: Integer;

  TextDrawPos: TPoint2px;
  TextSize   : TPoint2px;
  VirtualSize: TPoint2px;
  LocalRects : TRectList;
  ScreenRects: TRectList;

  FCaretPos : Integer;
  FAlignment: TTextAlignType;
  FVertShift: Integer;
  FSelStart : Integer;
  FSelEnd   : Integer;

  ClickCharAt: Integer;
  CurMousePos: TPoint2px;
  FPasswordChar: Integer;
  FTextFontName: StdString;

  EnabledAlpha: Integer;
  FocusAlpha  : Integer;

  ChangeTextTag: Integer;
  FOnChange: TNotifyEvent;

  procedure ValidateNewText();
  procedure SetText(const Value: StdString);
  procedure SetMaxLength(const Value: Integer);
  procedure SetScrollPos(const Value: Integer);
  function GetCaretSize(): TPoint2px;
  function GetViewText(): UniString;
  function UpdateTextRects(): Boolean;
  function GetMidPos(CharAt: Integer): Integer;
  function HaveSelection(): Boolean;

  procedure DrawCaret();
  procedure DrawSelected();
  function NeedToScroll(): Boolean;
  procedure ConstraintScroll();
  procedure ScrollToLeft(Index: Integer);
  function GetMaxScroll(): Integer;
  procedure CheckMouseScroll();

  procedure AppKeyDown(Key: Integer; Ctrl, Shift: Boolean);
  procedure AppKeyPress(Key: Char);

  procedure AppMouseDown(Button: TMouseButtonType);
  procedure AppMouseMove();
  procedure AppMouseUp(Button: TMouseButtonType);

  function CharAtPos(const Pos: TPoint2px; Imaginary: Boolean = False): Integer;
  procedure DrawEdit();
 protected
  procedure StripInvalidChars(var Text: StdString);

  procedure DoPaint(); override;
  procedure DoUpdate(); override;

  procedure DoKeyEvent(Key: Integer; Event: TKeyEventType;
   Shift: TGuiShiftState); override;
  procedure DoMouseEvent(const MousePos: TPoint2px; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TGuiShiftState); override;

  procedure AfterChange(const AFieldName: StdString;
   PropType: TGuiPropertyType; PropTag: Integer); override;

  procedure SelfDescribe(); override;
  procedure FirstTimePaint(); override;
 public
  property TextFontName: StdString read FTextFontName write FTextFontName;

  property ScrollPos: Integer read FScrollPos write SetScrollPos;
  property CaretPos : Integer read FCaretPos write FCaretPos;

  property SelStart: Integer read FSelStart write FSelStart;
  property SelEnd  : Integer read FSelEnd write FSelEnd;

  property MaxLength: Integer read FMaxLength write SetMaxLength;

  property Alignment: TTextAlignType read FAlignment write FAlignment;
  property VertShift: Integer read FVertShift write FVertShift;

  property Text: StdString read FText write SetText;
  property PasswordChar: Integer read FPasswordChar write FPasswordChar;

  property OnChange: TNotifyEvent read FOnChange write FOnChange;
  property TabOrder;

  procedure ScrollToRight(Index: Integer);
  procedure ResetSelection();
  procedure SendCaretToEnd();
  procedure SelectAll();

  procedure SetFocus(); override;

  constructor Create(const AOwner: TGuiControl); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 SysUtils, Asphyre.Timing, Asphyre.UI.Globals;

//---------------------------------------------------------------------------
const
 CaretDrawSpeed  = 1.0;
 SelectDrawSpeed = 1.2;
 SpaceToCaret    = 1;

//---------------------------------------------------------------------------
constructor TGuiEdit.Create(const AOwner: TGuiControl);
begin
 inherited;

 LocalRects := TRectList.Create();
 ScreenRects:= TRectList.Create();

 FTextFontName:= '';

 TextRect:= Rect(0, 0, 0, 0);
 DispFont:= nil;

 Width := 100;
 Height:= 24;

 FScrollPos:= 0;
 FMaxLength:= 0;

 FText:= '';
 FCaretPos:= Length(FText);

 FAlignment:= tatLeft;
 FVertShift:= 0;

 FSelStart:= -1;
 FSelEnd  := -1;

 ClickCharAt:= -1;
 CurMousePos:= InfPoint2px;

 FPasswordChar:= 0;
end;

//---------------------------------------------------------------------------
destructor TGuiEdit.Destroy();
begin
 FreeAndNil(ScreenRects);
 FreeAndNil(LocalRects);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.ValidateNewText();
begin
 if (FMaxLength > 0)and(Length(FText) > FMaxLength) then
  FText:= Copy(FText, 1, FMaxLength);

 FCaretPos:= Length(FText);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SetText(const Value: StdString);
var
 PrevText: StdString;
begin
 PrevText:= FText;

 FText:= Value;
 ValidateNewText();

 if (Assigned(FOnChange))and(CompareStr(PrevText, FText) <> 0) then
  FOnChange(Self);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SetMaxLength(const Value: Integer);
var
 PrevText: StdString;
begin
 FMaxLength:= Value;

 if (FMaxLength > 0)and(Length(FText) > FMaxLength) then
  begin
   PrevText:= FText;

   FText:= Copy(FText, 1, FMaxLength);
   if (FScrollPos > Length(FText)) then FScrollPos:= Length(FText);

   if (Assigned(FOnChange))and(CompareStr(PrevText, FText) <> 0) then
    FOnChange(Self);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SetScrollPos(const Value: Integer);
begin
 FScrollPos:= Value;
 if (FScrollPos < 0) then FScrollPos:= 0;
 if (FScrollPos > Length(FText)) then FScrollPos:= Length(FText);
end;

//---------------------------------------------------------------------------
function TGuiEdit.GetCaretSize(): TPoint2px;
var
 Height: Integer;
begin
 Height:= TextRect.Bottom - TextRect.Top;

 Result.x:= 2;
 Result.y:= Height;
end;

//---------------------------------------------------------------------------
function TGuiEdit.GetViewText(): UniString;
var
 i: Integer;
begin
 Result:= FText;

 if (FPasswordChar <> 0) then
  for i:= 1 to Length(Result) do
   Result[i]:= WideChar(FPasswordChar);
end;

//---------------------------------------------------------------------------
function TGuiEdit.UpdateTextRects(): Boolean;
var
 i: Integer;
 CaretSize: TPoint2px;
 Font: TAsphyreFont;
 ViText: UniString;
begin
 // (1) Check that the font specified is valid.
 Font:= RetrieveGuiFont(FTextFontName);

 Result:= Assigned(Font);
 if (not Result) then Exit;

 ConstraintScroll();

 ViText:= GetViewText();

 // (2) Determine the complete text and caret size.
 TextSize := Vec2ToPx(Font.TextExtent(ViText));
 CaretSize:= GetCaretSize();

 // (3) Determine the "virtualized" text size, including caret.
 VirtualSize.x:= TextSize.x;
 VirtualSize.y:= TextRect.Bottom - TextRect.Top;

 if (VirtualSize.x > 0) then
  Inc(VirtualSize.x, SpaceToCaret);

 Inc(VirtualSize.x, CaretSize.x);

 // (4) The position in screen space to draw text and caret at.
 case FAlignment of
  tatCenter:
   TextDrawPos.x:= TextRect.Left + (((TextRect.Right - TextRect.Left) -
    VirtualSize.x) div 2) - FScrollPos;

  tatRight:
   TextDrawPos.x:= TextRect.Right - (VirtualSize.x + FScrollPos);
 end;

 if (FAlignment = tatLeft)or(GetMaxScroll() > 0) then
  TextDrawPos.x:= TextRect.Left - FScrollPos;

 TextDrawPos.y:= TextRect.Top + FVertShift +
  ((TextRect.Bottom - TextRect.Top) - TextSize.y) div 2;

 // (5) Find individual letter rectangles.
 LocalRects.Clear();
 Font.TextRects(ViText, LocalRects);

 // (6) Include caret in rectangle list.
 if (LocalRects.Count > 0) then
  LocalRects.Add(TextSize.x + SpaceToCaret, 0, CaretSize.x, VirtualSize.y)
   else LocalRects.Add(0, 0, CaretSize.x, VirtualSize.y);

 // (7) Update rectangles identifying each letter on the screen.
 ScreenRects.Clear();

 for i:= 0 to LocalRects.Count - 1 do
  ScreenRects.Add(
   TextDrawPos.x + LocalRects[i].Left, TextRect.Top,
   LocalRects[i].Right - LocalRects[i].Left,
   TextRect.Bottom - TextRect.Top);

 Font.RestoreState();
end;

//---------------------------------------------------------------------------
function TGuiEdit.GetMidPos(CharAt: Integer): Integer;
var
 PrevRect, NextRect: TRect;
begin
 if (LocalRects.Count < 1) then
  begin
   Result:= TextDrawPos.x;
   Exit;
  end;

 if (FCaretPos <= 0) then
  begin
   PrevRect:= LocalRects[0]^;

   Result:= TextDrawPos.x + Max2(PrevRect.Left, 0);
   Exit;
  end;

 if (FCaretPos >= LocalRects.Count) then
  begin
   NextRect:= LocalRects[LocalRects.Count - 1]^;

   Result:= TextDrawPos.x + NextRect.Right - 1;
   Exit;
  end;

 PrevRect:= LocalRects[CharAt - 1]^;
 NextRect:= LocalRects[CharAt]^;

 Result:= TextDrawPos.x + Max2(((PrevRect.Right - 1) + NextRect.Left) div 2, 0);
end;

//---------------------------------------------------------------------------
function TGuiEdit.HaveSelection(): Boolean;
begin
 Result:=
  (FSelStart <> -1)and
  (FSelEnd <> -1)and
  (FSelEnd >= FSelStart)and
  (FSelStart >= 0)and
  (FSelEnd < ScreenRects.Count - 1);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.ResetSelection();
begin
 FSelStart:= -1;
 FSelEnd  := -1;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.DrawEdit();
var
 PrevClipRect: TRect;
 ViText: UniString;
begin
 if (not UpdateTextRects()) then Exit;

 PrevClipRect:= GuiCanvas.ClipRect;
 GuiCanvas.ClipRect:= ShortRect(TextRect, PrevClipRect);

 ViText:= GetViewText();

 GuiDrawControlText(TextDrawPos, ViText, DispFont, 1.0, EnabledAlpha);

 if (HaveSelection()) then DrawSelected();
 DrawCaret();

 GuiCanvas.ClipRect:= PrevClipRect;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.DrawCaret();
var
 MidPos: Integer;
 Theta: Single;
 Alpha: Integer;
begin
 if (not Enabled)or(GuiDesign)or(not Focused) then Exit;

 MidPos:= GetMidPos(FCaretPos);

 Theta:= (Sin(Timing.GetTickCount() * CaretDrawSpeed / 100.0) + 1.0) * 0.5;
 Theta:= 0.25 + (Theta * 0.75);
 Alpha:= Round(Theta * 255.0 * GuiGlobalAlpha);

 GuiCanvas.VertLine(MidPos - 1, TextRect.Top, TextRect.Bottom - TextRect.Top,
  cColorAlpha1(GuiCaretColor, Alpha div 4));

 GuiCanvas.VertLine(MidPos, TextRect.Top, TextRect.Bottom - TextRect.Top,
  cColorAlpha1(GuiCaretColor, Alpha));

 GuiCanvas.VertLine(MidPos + 1, TextRect.Top, TextRect.Bottom - TextRect.Top,
  cColorAlpha1(GuiCaretColor, Alpha div 4));
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.DrawSelected();
var
 PrevRect, NextRect, SelRect: TRect;
 Theta: Single;
begin
 if (not Enabled)or(GuiDesign)or(not Focused) then Exit;

 PrevRect:= ScreenRects[FSelStart]^;
 NextRect:= ScreenRects[FSelEnd]^;

 SelRect.Top   := Min2(PrevRect.Top, NextRect.Top);
 SelRect.Bottom:= Max2(PrevRect.Bottom, NextRect.Bottom);
 SelRect.Left  := PrevRect.Left;
 SelRect.Right := NextRect.Right;

 Theta:= (Sin(Timing.GetTickCount() * SelectDrawSpeed / 100.0) + 1.0) * 0.5;
 Theta:= 0.75 + (Theta * 0.25);

 GuiCanvas.FillQuad(pRect4(SelRect), cColor4(cColorAlpha1f(GuiEditSelectColor,
  Theta * GuiGlobalAlpha)));

 GuiCanvas.FrameRect(SelRect, cColor4(cColorAlpha1f(GuiEditSelectColor,
  Theta * GuiGlobalAlpha)));
end;

//---------------------------------------------------------------------------
function TGuiEdit.NeedToScroll(): Boolean;
var
 ChRect, CutRect: TRect;
begin
 if (not UpdateTextRects())or(FCaretPos < 0)or
  (FCaretPos >= LocalRects.Count) then
  begin
   Result:= False;
   Exit;
  end;

 ChRect := MoveRect(LocalRects[FCaretPos]^, Point2px(-FScrollPos, 0));
 CutRect:= ShortRect(ChRect, Bounds(0, 0, (TextRect.Right - TextRect.Left),
  TextRect.Bottom - TextRect.Top));

 Result:= (CutRect.Right - CutRect.Left) < (ChRect.Right - ChRect.Left);
end;

//---------------------------------------------------------------------------
function TGuiEdit.GetMaxScroll(): Integer;
begin
 Result:= TextSize.x;
 if (Result > 0) then Inc(Result, SpaceToCaret);
 Inc(Result, GetCaretSize().x);

 Result:= Max2(Result - (TextRect.Right - TextRect.Left), 0);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.ConstraintScroll();
begin
 FScrollPos:= MinMax2(FScrollPos, 0, GetMaxScroll());
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.ScrollToLeft(Index: Integer);
var
 ChRect: TRect;
begin
 if (not UpdateTextRects())or(Index < 0)or
  (Index >= LocalRects.Count) then Exit;

 ChRect:= LocalRects[Index]^;
 if (ChRect.Right <= ChRect.Left)and(ChRect.Right = 0) then Exit;

 FScrollPos:= ChRect.Left;
 ConstraintScroll();
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.ScrollToRight(Index: Integer);
var
 ChRect: TRect;
begin
 if (not UpdateTextRects())or(Index < 0)or
  (Index >= LocalRects.Count) then Exit;

 ChRect:= LocalRects[Index]^;
 if (ChRect.Right <= ChRect.Left)and(ChRect.Right = 0) then Exit;

 FScrollPos:= ChRect.Right - (TextRect.Right - TextRect.Left);
 ConstraintScroll();
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SendCaretToEnd();
begin
 ResetSelection();

 FCaretPos:= Length(FText);
 if (NeedToScroll()) then ScrollToRight(FCaretPos);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SelectAll();
begin
 FSelStart:= 0;
 FSelEnd  := Length(Text) - 1;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.StripInvalidChars(var Text: StdString);
var
 i: Integer;
begin
 Text:= Trim(Text);

 for i:= Length(Text) downto 1 do
  if (Text[i] < #32) then Delete(Text, i, 1);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.AppKeyDown(Key: Integer; Ctrl, Shift: Boolean);
var
 HaveSel : Boolean;
 PrevText: StdString;
 {$ifndef FireMonkey}
 CopyText : StdString;
 Clipboard: TClipboard;
 {$endif}
begin
 PrevText:= FText;

 case Key of
  AVK_Tab:
   begin
    SendFocusToNext();
    Exit;
   end;

  AVK_Right:
   begin
    if (FCaretPos < LocalRects.Count - 1) then
     begin
      Inc(FCaretPos);

      if (Shift) then
       begin
        HaveSel:= HaveSelection();

        if (HaveSel)and(FSelStart = FCaretPos - 1) then
         begin
          Inc(FSelStart);
         end else
        if (not HaveSel)or(FSelStart >= FCaretPos)or
         (FSelEnd >= FCaretPos)or(FSelEnd < FCaretPos - 2) then
         begin
          FSelStart:= FCaretPos - 1;
          FSelEnd  := FCaretPos - 1;
         end else FSelEnd:= FCaretPos - 1;
       end else ResetSelection();
     end else if (not Shift) then ResetSelection();

    if (NeedToScroll()) then ScrollToRight(FCaretPos);
   end;

  AVK_Left:
   begin
    if (FCaretPos > 0) then
     begin
      Dec(FCaretPos);

      if (Shift) then
       begin
        HaveSel:= HaveSelection();

        if (HaveSel)and(FSelEnd = FCaretPos) then
         begin
          Dec(FSelEnd);
         end else
        if (not HaveSel)or(FSelStart <= FCaretPos)or
         (FSelEnd <= FCaretPos)or(FSelStart > FCaretPos + 1) then
         begin
          FSelStart:= FCaretPos;
          FSelEnd  := FCaretPos;
         end else FSelStart:= FCaretPos;
       end else ResetSelection();
     end else if (not Shift) then ResetSelection();

    if (NeedToScroll()) then ScrollToLeft(FCaretPos);
   end;

  AVK_Back:
   begin
    if (HaveSelection()) then
     begin
      Delete(FText, FSelStart + 1, (FSelEnd - FSelStart) + 1);
      FCaretPos:= FSelStart;

      ResetSelection();
     end else
     begin
      Delete(FText, FCaretPos, 1);
      if (FCaretPos > 0) then Dec(FCaretPos);
     end;

    if (NeedToScroll()) then ScrollToRight(FCaretPos);
   end;

  AVK_Delete:
   begin
    if (HaveSelection()) then
     begin
      Delete(FText, FSelStart + 1, (FSelEnd - FSelStart) + 1);
      FCaretPos:= FSelStart;

      ResetSelection();
     end else Delete(FText, FCaretPos + 1, 1);
   end;

  AVK_Home:
   begin
    if (Shift) then
     begin
      if (not HaveSelection())or(FSelEnd < FCaretPos - 1) then
       FSelEnd:= FCaretPos - 1;

      FSelStart:= 0;
     end else ResetSelection();

    FCaretPos:= 0;

    if (NeedToScroll()) then ScrollToLeft(FCaretPos);
   end;

  AVK_End:
   begin
    if (Shift) then
     begin
      if (not HaveSelection())or(FSelStart > FCaretPos) then
       FSelStart:= FCaretPos;

      FSelEnd:= Length(Text) - 1;
     end else ResetSelection();

    FCaretPos:= Length(FText);

    if (NeedToScroll()) then ScrollToRight(FCaretPos);
   end;
 end;

 {$ifndef FireMonkey}
 if (Key = Ord('V'))and(Ctrl) then
  begin
   Clipboard:= TClipboard.Create();

   CopyText:= Clipboard.AsText;
   StripInvalidChars(CopyText);

   if (HaveSelection()) then
    begin
     FCaretPos:= FSelStart;

     Delete(FText, FSelStart + 1, (FSelEnd - FSelStart) + 1);
     ResetSelection();
    end;

   Insert(CopyText, FText, FCaretPos + 1);
   Inc(FCaretPos, Length(CopyText));

   if (FMaxLength > 0)and(Length(FText) > FMaxLength) then
    begin
     FText:= Copy(FText, 1, FMaxLength);
     if (FCaretPos > Length(FText)) then FCaretPos:= Length(FText);
    end;

   if (NeedToScroll()) then ScrollToRight(FCaretPos);

   FreeAndNil(Clipboard);
  end;
 {$endif}

 if (Key = Byte('A'))and(Ctrl)and(FPasswordChar = 0) then
  begin
   FSelStart:= 0;
   FSelEnd  := Length(Text) - 1;
  end;

 {$ifndef FireMonkey}
 if (Key = Ord('C'))and(Ctrl)and(FPasswordChar = 0)and(HaveSelection()) then
  begin
   Clipboard:= TClipboard.Create();
   Clipboard.AsText:= Copy(FText, FSelStart + 1, (FSelEnd - FSelStart) + 1);
   FreeAndNil(Clipboard);
  end;

 if (Key = Ord('X'))and(Ctrl)and(FPasswordChar = 0)and(HaveSelection()) then
  begin
   Clipboard:= TClipboard.Create();
   Clipboard.AsText:= Copy(FText, FSelStart + 1, (FSelEnd - FSelStart) + 1);
   FreeAndNil(Clipboard);

   Delete(FText, FSelStart + 1, (FSelEnd - FSelStart) + 1);
   FCaretPos:= FSelStart;

   ResetSelection();
  end;
 {$endif}

 if (Assigned(FOnChange))and(CompareStr(PrevText, FText) <> 0) then
  FOnChange(Self);

 ClickCharAt:= -1;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.AppKeyPress(Key: Char);
var
 PrevText: StdString;
begin
 if (Key < #32) then Exit;

 PrevText:= FText;

 if (HaveSelection()) then
  begin
   FCaretPos:= FSelStart;

   Delete(FText, FSelStart + 1, (FSelEnd - FSelStart) + 1);
   ResetSelection();

   if (NeedToScroll()) then ScrollToRight(FCaretPos);
  end;

 if ((FMaxLength < 1)or(Length(FText) < FMaxLength - 1)) then
  begin
   if (FText = '')or(FCaretPos >= Length(FText)) then FText:= FText + Key
    else Insert(Key, FText, FCaretPos + 1);

   Inc(FCaretPos);
   if (NeedToScroll()) then ScrollToRight(FCaretPos);
  end;

 if (Assigned(FOnChange))and(CompareStr(PrevText, FText) <> 0) then
  FOnChange(Self);

 ClickCharAt:= -1;
end;

//---------------------------------------------------------------------------
function TGuiEdit.CharAtPos(const Pos: TPoint2px;
 Imaginary: Boolean = False): Integer;
var
 i, MidPos, TotalWidth: Integer;
 MoPos : TPoint2px;
 ChRect: TRect;
begin
 Result:= -1;
 if (ScreenRects.Count < 1) then Exit;

 MoPos:= Pos;

 if (Imaginary)and(MoPos.y < TextRect.Top) then MoPos.y:= TextRect.Top;
 if (Imaginary)and(MoPos.y >= TextRect.Bottom) then
  MoPos.y:= TextRect.Bottom - 1;

 for i:= 0 to ScreenRects.Count - 1 do
  begin
   ChRect:= ScreenRects[i]^;

   if (PointInRect(MoPos, ShortRect(ChRect, TextRect))) then
    begin
     Result:= i;

     if (MoPos.x > (ChRect.Left + ChRect.Right) div 2)and
      (Result < ScreenRects.Count - 1) then
      Inc(Result);

     Break;
    end;
  end;

 if (Result <> -1)or(not Imaginary) then Exit;

 if (MoPos.x >= TextRect.Left)and(MoPos.x < TextRect.Right) then
  begin
   if (MoPos.y < TextRect.Top) then Exit;
   if (MoPos.y >= TextRect.Bottom) then Exit;
  end;

 TotalWidth:= ScreenRects[ScreenRects.Count - 1].Right - ScreenRects[0].Left;
 if (TotalWidth < TextRect.Right - TextRect.Left) then
  MidPos:= (ScreenRects[0].Left +
   ScreenRects[ScreenRects.Count - 1].Right) div 2
   else MidPos:= (TextRect.Left + TextRect.Right) div 2;

 if (MoPos.x < MidPos) then
  begin // First visible character
   for i:= 0 to ScreenRects.Count - 1 do
    begin
     ChRect:= ScreenRects[i]^;

     if (RectInRect(ChRect, TextRect))or(OverlapRect(ChRect, TextRect)) then
      begin
       Result:= i;
       Break;
      end;
    end;
  end else
  begin // Last visible character
   for i:= ScreenRects.Count - 1 downto 0 do
    begin
     ChRect:= ScreenRects[i]^;

     if (RectInRect(ChRect, TextRect))or(OverlapRect(ChRect, TextRect)) then
      begin
       Result:= i;
       Break;
      end;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.CheckMouseScroll();
var
 MidPos: Integer;
begin
 MidPos:= (TextRect.Left + TextRect.Right) div 2;

 if (NeedToScroll()) then
  begin
   if (CurMousePos.x > MidPos) then ScrollToRight(FCaretPos)
    else ScrollToLeft(FCaretPos);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.AppMouseDown(Button: TMouseButtonType);
begin
 if (not PointInRect(CurMousePos, TextRect)) then Exit;

 if (Button = mbtLeft) then
  begin
   ClickCharAt:= CharAtPos(CurMousePos, True);
   if (ClickCharAt <> -1) then
    begin
     FCaretPos:= ClickCharAt;
     CheckMouseScroll();
    end else
    begin
     case FAlignment of
      tatLeft:
       FCaretPos:= Length(FText);

      tatRight:
       FCaretPos:= 0;

      tatCenter:
       if (CurMousePos.x > (TextRect.Left + TextRect.Right) div 2) then
        FCaretPos:= Length(FText)
         else FCaretPos:= 0;
     end;

     CheckMouseScroll();
    end;

   ResetSelection();
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.AppMouseMove();
var
 NextClickAt: Integer;
begin
 if (ClickCharAt = -1)or(GuiDesign)or(not Focused) then Exit;

 NextClickAt:= CharAtPos(CurMousePos, True);

 if (NextClickAt <> -1) then
  begin
   FCaretPos:= NextClickAt;
   CheckMouseScroll();
  end;

 if (NextClickAt <> -1) then
  begin
   if (NextClickAt > ClickCharAt) then
    begin
     FSelStart:= ClickCharAt;
     FSelEnd  := NextClickAt - 1;
    end else
    begin
     FSelStart:= NextClickAt;
     FSelEnd  := ClickCharAt - 1;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.AppMouseUp(Button: TMouseButtonType);
begin
 ClickCharAt:= -1;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.DoPaint();
var
 PaintRect: TRect;
begin
 PaintRect:= VirtualRect;

 GuiDrawControlFill(PaintRect);

 if (FocusAlpha > 0)and(not GuiDesign) then
  GuiDrawCtrlFocus(PaintRect, FocusAlpha);

 TextRect:= ShortRect(ShrinkRect(PaintRect, 2, 2), VisibleRect);

 if (TextRect.Right > TextRect.Left)and(TextRect.Bottom > TextRect.Top) then
  begin
   DispFont:= RetrieveGuiFont(FTextFontName);
   if (Assigned(DispFont)) then DrawEdit();

   DispFont.RestoreState();
  end;

 GuiDrawControlBorder(PaintRect);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.DoUpdate();
begin
 inherited;

 if (Enabled) then EnabledAlpha:= Min2(EnabledAlpha + 16, 255)
  else EnabledAlpha:= Max2(EnabledAlpha - 12, 0);

 if (Focused)and(Enabled) then FocusAlpha:= Min2(FocusAlpha + 22, 255)
  else FocusAlpha:= Max2(FocusAlpha - 16, 0);

 if (ClickCharAt = -1)or(GuiDesign)or(not Focused) then Exit;

 if (PointInRect(CurMousePos, TextRect)) then Exit;

 if (CurMousePos.x < TextRect.Left) then FScrollPos:= Max2(FScrollPos - 2, 0);
 if (CurMousePos.x >= TextRect.Right) then
  FScrollPos:= Min2(FScrollPos + 2, GetMaxScroll());

 AppMouseMove();
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.DoKeyEvent(Key: Integer; Event: TKeyEventType;
 Shift: TGuiShiftState);
begin
 if (GuiDesign)or(not Focused) then Exit;

 case Event of
  ketDown:
   AppKeyDown(Key, gssCtrl in Shift, gssShift in Shift);

  ketPress:
   AppKeyPress(Char(Key));
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.DoMouseEvent(const MousePos: TPoint2px;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TGuiShiftState);
begin
 if (GuiDesign)or(not Focused) then Exit;

 CurMousePos:= MousePos;

 case Event of
  metDown:
   AppMouseDown(Button);

  metUp:
   AppMouseUp(Button);

  metMove:
   AppMouseMove();
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SelfDescribe();
begin
 inherited;

 ChangeTextTag:= NextFieldTag();

 FNameOfClass:= 'TGuiEdit';

 AddProperty('TextFontName', gptString, gpfStdString, @FTextFontName);

 AddProperty('MaxLength', gptInteger, gpfInteger, @FMaxLength, 
  SizeOf(Integer));

 AddProperty('Alignment', gptAlignType, gpfAlignType, @FAlignment,
  SizeOf(TTextAlignType));

 AddProperty('VertShift', gptInteger, gpfInteger, @FVertShift, 
  SizeOf(Integer));

 AddProperty('TabOrder', gptInteger, gpfInteger, @FTabOrder, 
  SizeOf(Integer));

 AddProperty('Text', gptString, gpfStdString, @FText, 0, ChangeTextTag);

 AddProperty('PasswordChar', gptInteger, gpfInteger, @FPasswordChar, 
  SizeOf(Integer));
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.AfterChange(const AFieldName: StdString;
 PropType: TGuiPropertyType; PropTag: Integer);
begin
 inherited;

 if (PropTag = ChangeTextTag) then ValidateNewText();
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.FirstTimePaint();
begin
 inherited;

 if (Enabled) then EnabledAlpha:= 255
  else EnabledAlpha:= 0;

 if (Focused)and(Enabled) then FocusAlpha:= 255
  else FocusAlpha:= 0;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SetFocus();
begin
 inherited;

 FCaretPos:= Length(FText);
 FSelStart:= 0;
 FSelEnd  := Length(FText) - 1;

 CheckMouseScroll();
end;

//---------------------------------------------------------------------------
end.
