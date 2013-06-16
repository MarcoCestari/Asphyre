unit Asphyre.UI.Forms;
//---------------------------------------------------------------------------
// Form control for Asphyre GUI framework.
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
 System.Types, System.Classes,
{$else}
 Types, Classes,
{$endif}
 Asphyre.Math, Asphyre.TypeDef, Asphyre.Types,
 Asphyre.UI.Types, Asphyre.UI.Controls;

//---------------------------------------------------------------------------
type
 TGuiForm = class;

//---------------------------------------------------------------------------
 TCustomPaintFormProc = procedure(Sender: TGuiForm) of object;

//---------------------------------------------------------------------------
 TGuiForm = class(TGuiControl)
 private
  FTitleFontName: StdString;

  FCaptSize    : Integer;
  FCaption     : UniString;
  FIconImage   : StdString;
  FIconPattern : Integer;
  FIconWidth   : Integer;
  FIconHeight  : Integer;
  FCaptAdjust  : Integer;
  DragClick    : TPoint2px;
  DragInit     : TPoint2px;
  Dragging     : Boolean;
  FShadowSize  : Integer;
  FShadowColor : Cardinal;
  FBackImage   : StdString;
  FBackPattern : Integer;
  FCustomPaint : TCustomPaintFormProc;
 protected
  procedure DoMouseEvent(const MousePos: TPoint2px; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TGuiShiftState); override;
  procedure DoPaint(); override;

  procedure SelfDescribe(); override;
 public
  property CaptSize: Integer read FCaptSize write FCaptSize;
  property Caption : UniString read FCaption write FCaption;

  property TitleFontName: StdString read FTitleFontName write FTitleFontName;

  property CaptAdjust: Integer read FCaptAdjust write FCaptAdjust;

  property IconImage  : StdString read FIconImage write FIconImage;
  property IconPattern: Integer read FIconPattern write FIconPattern;
  property IconWidth  : Integer read FIconWidth write FIconWidth;
  property IconHeight : Integer read FIconHeight write FIconHeight;

  property BackImage  : StdString read FBackImage write FBackImage;
  property BackPattern: Integer read FBackPattern write FBackPattern;

  property ShadowSize : Integer read FShadowSize write FShadowSize;
  property ShadowColor: Cardinal read FShadowColor write FShadowColor;

  property CustomPaint: TCustomPaintFormProc read FCustomPaint
   write FCustomPaint;

  property TabOrder;

  property OnResize;
  property OnShow;
  property OnHide;

  procedure SetFocus(); override;

  constructor Create(const AOwner: TGuiControl); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Fonts, Asphyre.UI.Globals;

//---------------------------------------------------------------------------
constructor TGuiForm.Create(const AOwner: TGuiControl);
begin
 inherited;

 FTitleFontName:= '';

 FTabOrder:= 0;

 FCaption   := 'TGuiForm';
 FCaptSize  := 20;
 FCaptAdjust:= -1;
 FIconWidth := 12;
 FIconHeight:= 12;

 FShadowSize := 4;
 FShadowColor:= $40000000;

 FIconImage  := '';
 FIconpattern:= 0;

 FBackImage  := '';
 FBackPattern:= 0;

 Width := 300;
 Height:= 200;

 FCtrlHolder:= True;
 Dragging:= False;
end;

//---------------------------------------------------------------------------
destructor TGuiForm.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiForm.DoPaint();
var
 PaintRect: TRect;
 IconLeft, IconTop, CaptLeft, BlockSize, ImageIndex: Integer;
 TopRect, vRect: TRect;
 UsedFont: TAsphyreFont;
 TitleColor: TColor2;
 Text: UniString;
begin
 if (Assigned(FCustomPaint)) then
  begin
   FCustomPaint(Self);
   Exit;
  end;

 // (1) Compute the rectangle to paint into.
 PaintRect:= VirtualRect;

 // -> Shorten PaintRect by excluding shadow area
 Dec(PaintRect.Right, FShadowSize);
 Dec(PaintRect.Bottom, FShadowSize);

 // (2) Compute the caption rectangle
 TopRect:= Bounds(PaintRect.Left, PaintRect.Top, Width - FShadowSize,
  CaptSize);

 // (3) Render the window's caption
 if (FCaptSize > 0) then
  begin
   // (3.1) Draw the caption's rectangle
   if (Focused)and(cGetMaxAlpha4(GuiFormActiveTitleFill) > 0) then
    GuiCanvas.FillQuad(pRect4(TopRect), GuiFormActiveTitleFill);

   if (not Focused)and(cGetMaxAlpha4(GuiFormInactiveTitleFill) > 0) then
    GuiCanvas.FillQuad(pRect4(TopRect), GuiFormInactiveTitleFill);

   if (cGetAlpha1(GuiFormBorderColor) > 0) then
    GuiCanvas.FrameRect(pRect4(TopRect), cColor4(GuiFormBorderColor));

   IconTop := (FCaptSize - FIconHeight) div 2;
   IconLeft:= IconTop;

   // (3.2) Draw the caption's icon
   if (cGetAlpha1(GuiFormIconColor) > 0)or(FIconImage <> '') then
    with GuiCanvas do
     begin
      ImageIndex:= -1;
      if (FIconImage <> '') then ImageIndex:= GuiImages.Resolve(FIconImage);

      if (ImageIndex = -1) then
       begin
        FillRect(IconLeft + PaintRect.Left, IconTop + PaintRect.Top,
         FIconWidth, FIconHeight div 3, GuiFormIconColor);

        FrameRect(Bounds(IconLeft + PaintRect.Left, IconTop + PaintRect.Top,
         FIconWidth, FIconHeight), cColor4(GuiFormIconColor));
       end else
       begin
        UseImagePt(GuiImages[ImageIndex], FIconPattern);

        TexMap(pBounds4(IconLeft + PaintRect.Left, IconTop + PaintRect.Top,
         FIconWidth, FIconHeight), clWhite4);
       end;
     end;

   // (3.3) Draw the caption's text
   UsedFont:= RetrieveGuiFont(FTitleFontName);
   if (Assigned(UsedFont)) then
    begin
     CaptLeft:= (IconLeft * 2) + FIconWidth;
     if (cGetAlpha1(GuiFormIconColor) <= 0)and(FIconImage = '') then
      CaptLeft:= 4;

     Text:= FCaption;

     if (UsedFont.TextWidth(Text) > Width - (FShadowSize + CaptLeft)) then
      begin
       while (UsedFont.TextWidth(Text + '...') > Width - (CaptLeft +
        FShadowSize))and(Length(Text) > 0) do Delete(Text, Length(Text), 1);

       Text:= Text + '...';
      end;

     TitleColor:= GuiFormActiveTitleColor;
     if (not Focused) then TitleColor:= GuiFormInactiveTitleColor;

     UsedFont.TextOut(Point2px(CaptLeft + PaintRect.Left, PaintRect.Top +
      FCaptAdjust + (FCaptSize - Round(UsedFont.TextHeight(Text))) div 2),
      Text, TitleColor);
    end;
  end;

 // (4) Render the window's content background
 if (CaptSize > 0) then
  vRect:= Bounds(PaintRect.Left, TopRect.Bottom - 1, Width - FShadowSize,
   (Height - (FCaptSize + FShadowSize)) + 1)
  else vRect:= Bounds(PaintRect.Left, PaintRect.Top, Width - FShadowSize,
   Height - FShadowSize);

 if (cGetMaxAlpha4(GuiFormFillColor) > 0) then
  GuiCanvas.FillQuad(pRect4(vRect), GuiFormFillColor);

 // (5) Render the window's background image
 ImageIndex:= -1;
 if (FBackImage <> '') then ImageIndex:= GuiImages.Resolve(FBackImage);

 if (ImageIndex <> -1) then
  begin
   GuiCanvas.UseImagePt(GuiImages[ImageIndex], FBackPattern);
   GuiCanvas.TexMap(pRect4(vRect), GuiFormFillColor);
  end;

 // (6) Draw window's border
 if (cGetAlpha1(GuiFormBorderColor) > 0) then
  GuiCanvas.FrameRect(pRect4(vRect), cColor4(GuiFormBorderColor));

 // (7) Render the shadow
 if (FShadowSize > 0) then
  begin
   BlockSize:= (PaintRect.Bottom - PaintRect.Top) - FShadowSize;
   GuiCanvas.FillQuad(pBounds4(PaintRect.Right, PaintRect.Top + FShadowSize,
    FShadowSize, BlockSize), cColor4(FShadowColor));

   BlockSize:= (PaintRect.Right - PaintRect.Left);
   guiCanvas.FillQuad(pBounds4(PaintRect.Left + FShadowSize, PaintRect.Bottom,
    BlockSize, FShadowSize), cColor4(FShadowColor));
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiForm.DoMouseEvent(const MousePos: TPoint2px;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TGuiShiftState);
var
 Pt: TPoint2px;
 Drag: Boolean;
begin
 Pt:= Screen2Local(MousePos);
 Drag:= (Pt.x >= 0)and(Pt.x < Width)and(Pt.y >= 0)and(Pt.y < FCaptSize)and
  (Button = mbtLeft)and(Event = metDown);

 if (Drag)and(not Dragging) then
  begin
   DragInit := Point2px(Left, Top);
   DragClick:= MousePos;
   Dragging := True;
  end;

 if (Dragging)and(Button = mbtLeft)and(Event = metUp) then Dragging:= False;
 if (Dragging)and(Event = metMove) then
  begin
   Left:= DragInit.x + (MousePos.x - DragClick.x);
   Top := DragInit.y + (MousePos.y - DragClick.y);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiForm.SetFocus();
begin
 BringToFront();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiForm.SelfDescribe();
begin
 inherited;

 FNameOfClass:= 'TGuiForm';

 AddProperty('CaptSize', gptInteger, gpfInteger, @FCaptSize, 
  SizeOf(Integer));

 AddProperty('Caption', gptString,  gpfUniString, @FCaption);

 AddProperty('TitleFontName', gptString, gpfStdString, @FTitleFontName);

 AddProperty('CaptAdjust', gptInteger, gpfInteger, @FCaptAdjust,
  SizeOf(Integer));

 AddProperty('IconImage', gptString, gpfStdString, @FIconImage);

 AddProperty('IconPattern', gptInteger, gpfInteger, @FIconPattern,
  SizeOf(Integer));

 AddProperty('IconWidth', gptInteger, gpfInteger, @FIconWidth, 
  SizeOf(Integer));

 AddProperty('IconHeight', gptInteger, gpfInteger, @FIconHeight, 
  SizeOf(Integer));

 AddProperty('BackImage', gptString,  gpfStdString, @FBackImage);

 AddProperty('BackPattern', gptInteger, gpfInteger, @FBackPattern, 
  SizeOf(Integer));

 AddProperty('ShadowSize', gptInteger, gpfInteger,  @FShadowSize, 
  SizeOf(Integer));

 AddProperty('ShadowColor', gptColor, gpfCardinal, @FShadowColor,  
  SizeOf(Cardinal));

 AddProperty('TabOrder', gptInteger, gpfInteger, @FTabOrder, 
  SizeOf(Integer));
end;

//---------------------------------------------------------------------------
end.
