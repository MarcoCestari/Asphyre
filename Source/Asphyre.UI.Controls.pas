unit Asphyre.UI.Controls;
//---------------------------------------------------------------------------
// Base interactive control for Asphyre GUI framework.
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
 Asphyre.Math, Asphyre.UI.Types, Asphyre.UI.Components;

//---------------------------------------------------------------------------
type
 TGuiControl = class;

//---------------------------------------------------------------------------
 TGuiControlEnumerator = class
 private
  FParent: TGuiControl;
  Index: Integer;

  function GetCurrent(): TGuiControl;
 public
  property Current: TGuiControl read GetCurrent;

  function MoveNext(): Boolean;
  constructor Create(AParent: TGuiControl);
 end;

//---------------------------------------------------------------------------
 TGuiControl = class(TGuiComponent)
 private
  Controls: array of TGuiControl;

  IsFirstTimePaint: Boolean;

  FName : StdString;

  {$ifdef DelphiNextGen}[weak]{$endif}FOwner: TGuiControl;

  FOnMouse: TGuiMouseEvent;
  FOnKey  : TGuiKeyEvent;
  FOnClick: TNotifyEvent;
  FOnDblClick: TNotifyEvent;
  FMouseOver : Boolean;
  FOnMouseEnter: TNotifyEvent;
  FOnMouseLeave: TNotifyEvent;

  function GetControlCount(): Integer;
  function GetControl(Index: Integer): TGuiControl;
  function FindControl(const Name: StdString): TGuiControl;
  function GetRootCtrl(): TGuiControl;
  function GetFocused(): Boolean;
  procedure ToFront(Index: Integer);
  procedure ToBack(Index: Integer);
  function GetVisibleRect(): TRect;
  function GetVirtualRect(): TRect;

  procedure PasteFieldsFromStream(const Stream: TStream;
   const Master: TGuiComponent);

  procedure CustomLoadFromStream(Control: TGuiControl; const Stream: TStream);
  procedure SaveChildrenToStream(Control: TGuiControl; const Stream: TStream);

  procedure CustomPasteFromStream(Control: TGuiControl; const Stream: TStream;
   const Master: TGuiControl);

  function PasteFromClipboard(const Stream: TStream): Boolean;
  function SaveThisToStream(const Stream: TStream): Boolean;
 protected
  FocusIndex : Integer;
  FCtrlHolder: Boolean;
  FTabOrder  : Integer;

  property OnMouse: TGuiMouseEvent read FOnMouse write FOnMouse;
  property OnKey  : TGuiKeyEvent read FOnKey write FOnKey;
  property OnClick: TNotifyEvent read FOnClick write FOnClick;
  property OnDblClick: TNotifyEvent read FOnDblClick write FOnDblClick;
  property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
  property OnMouseLeave: TNotifyEvent read FOnMouseLeave write FOnMouseLeave;

  property TabOrder: Integer read FTabOrder write FTabOrder;

  function Screen2Local(const Point: TPoint2px): TPoint2px;
  procedure FocusSomething();

  procedure FirstTimePaint(); virtual;
  procedure DoUpdate(); virtual;
  procedure DoPaint(); virtual;
  procedure DoShow(); override;
  procedure DoHide(); override;

  procedure DoMouseEvent(const MousePos: TPoint2px; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TGuiShiftState); virtual;
  procedure DoKeyEvent(Key: Integer; Event: TKeyEventType;
   Shift: TGuiShiftState); virtual;

  procedure SelfDescribe(); override;
 public
  property Name : StdString read FName write FName;
  property Owner: TGuiControl read FOwner;

  property MouseOver: Boolean read FMouseOver write FMouseOver;
  property Focused  : Boolean read GetFocused;

  property CtrlHolder: Boolean read FCtrlHolder;
  // The first control in the tree.
  property RootCtrl: TGuiControl read GetRootCtrl;

  property ControlCount: Integer read GetControlCount;
  property Control[Index: Integer]: TGuiControl read GetControl; default;
  property Ctrl[const Name: StdString]: TGuiControl read FindControl;

  // The rectangle that covers this entire control in screen space.
  property VisibleRect: TRect read GetVisibleRect;

  // The rectangle to draw on the screen (will be clipped with
  // VisibleRect rect).
  property VirtualRect: TRect read GetVirtualRect;

  function Link(const Control: TGuiControl): Integer;
  procedure Unlink(const Control: TGuiControl);
  function IndexOf(const Control: TGuiControl): Integer;
  procedure RemoveAll();

  procedure AcceptMouse(const MousePos: TPoint2px; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TGuiShiftState); virtual;
  procedure AcceptKey(Key: Integer; Event: TKeyEventType;
   Shift: TGuiShiftState); virtual;

  procedure ResetFirstTimePaint();

  function FindCtrlAt(const Point: TPoint2px): TGuiControl; virtual;
  procedure BringToFront();
  procedure SentToBack();
  procedure SetFocus(); virtual;

  function SendFocusToNext(): Boolean;
  procedure SetFirstFocus();

  procedure Update();
  procedure Draw();

  function LoadFromStream(const Stream: TStream): Boolean;
  function SaveToStream(const Stream: TStream): Boolean;

 {$ifndef StandardStringsOnly}
  function SaveThisToString(out Text: AnsiString): Boolean;
  function PasteFromString(const Text: AnsiString): Boolean;
 {$else}
  function SaveThisToString(out Text: StdString): Boolean;
  function PasteFromString(const Text: StdString): Boolean;
 {$endif}

  procedure ShowWindow(const FormName: StdString; FirstTime: Boolean = False);

  function FindPreRootCtrl(): TGuiControl;
  function GetOwnerFormName(): StdString;

  function GetEnumerator(): TGuiControlEnumerator;

  constructor Create(const AOwner: TGuiControl); virtual;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types, Asphyre.Streams, Asphyre.Data, Asphyre.UI.Registry, Asphyre.UI.Forms;

//------------------------------------------------------------------------------
function MakeGuiName(const Master: TGuiControl;
 const ClassName: StdString): StdString;
var
 Num: Integer;
begin
 if (Pos('tgui', LowerCase(ClassName)) = 1) then
  begin
   Result:= Copy(ClassName, 5, Length(ClassName) - 4);
  end else Result:= ClassName;

 Num:= 1;
 while (Assigned(Master.Ctrl[Result + IntToStr(Num)])) do Inc(Num);
 Result:= Result + IntToStr(Num);
end;

//---------------------------------------------------------------------------
constructor TGuiControl.Create(const AOwner: TGuiControl);
begin
 inherited Create();

 FOwner:= AOwner;
 FName := '';

 FMouseOver := False;
 FCtrlHolder:= False;

 FTabOrder:= -1;

 IsFirstTimePaint:= True;

 if (Assigned(FOwner)) then
  FOwner.Link(Self);

 FocusIndex:= -1;
end;

//---------------------------------------------------------------------------
destructor TGuiControl.Destroy();
begin
 if (Assigned(FOwner)) then
  FOwner.Unlink(Self);

 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
function TGuiControl.GetControlCount(): Integer;
begin
 Result:= Length(Controls);
end;

//---------------------------------------------------------------------------
function TGuiControl.GetControl(Index: Integer): TGuiControl;
begin
 if (Index >= 0)and(Index < Length(Controls)) then
  Result:= Controls[Index]
   else Result:= nil;
end;

//---------------------------------------------------------------------------
function TGuiControl.IndexOf(const Control: TGuiControl): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Controls) - 1 do
  if (Controls[i] = Control) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= -1;
end;

//---------------------------------------------------------------------------
function TGuiControl.Link(const Control: TGuiControl): Integer;
var
 Index: Integer;
begin
 Index:= IndexOf(Control);
 if (Index <> -1) then
  begin
   Result:= Index;
   Exit;
  end;

 Index:= Length(Controls);
 SetLength(Controls, Index + 1);

 Controls[Index]:= Control;
 Result:= Index;

 if (FocusIndex = -1) then
  FocusIndex:= Index;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.Unlink(const Control: TGuiControl);
var
 Index, i: Integer;
begin
 Index:= IndexOf(Control);
 if (Index = -1) then Exit;

 if (FocusIndex = Index) then
  FocusIndex:= -1;

 for i:= Index to Length(Controls) - 2 do
  Controls[i]:= Controls[i + 1];

 SetLength(Controls, Length(Controls) - 1);

 if (FocusIndex = -1) then
  FocusSomething();
end;

//---------------------------------------------------------------------------
procedure TGuiControl.RemoveAll();
var
 i: Integer;
begin
 for i:= Length(Controls) - 1 downto 0 do
  FreeAndNil(Controls[i]);

 SetLength(Controls, 0);
end;

//---------------------------------------------------------------------------
function TGuiControl.FindControl(const Name: StdString): TGuiControl;
var
 Index: Integer;
begin
 Result:= nil;

 if (SameText(Name, Self.Name)) then
  begin
   Result:= Self;
   Exit;
  end;

 for Index:= 0 to Length(Controls) - 1 do
  begin
   if (SameText(Name, Controls[Index].Name)) then
    begin
     Result:= Controls[Index];
     Break;
    end;

   Result:= Controls[Index].FindControl(Name);
   if (Assigned(Result)) then Break;
  end;
end;

//---------------------------------------------------------------------------
function TGuiControl.GetRootCtrl(): TGuiControl;
begin
 Result:= Self;

 while (Assigned(Result.Owner)) do
  Result:= Result.Owner;
end;

//---------------------------------------------------------------------------
function TGuiControl.FindPreRootCtrl(): TGuiControl;
begin
 Result:= FOwner;

 while (Assigned(Result.Owner))and(Assigned(Result.Owner.Owner)) do
  Result:= Result.Owner;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.FocusSomething();
var
 i: Integer;
begin
 FocusIndex:= -1;

 for i:= 0 to Length(Controls) - 1 do
  if (Controls[i].Visible)and(Controls[i].Enabled) then
   begin
    FocusIndex:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DoHide();
begin
 if (Assigned(Owner))and(Owner.FocusIndex = Owner.IndexOf(Self)) then
  Owner.FocusSomething();
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DoShow();
begin
 if (Assigned(Owner))and(Owner.FocusIndex = -1) then
  Owner.FocusSomething();
end;

//---------------------------------------------------------------------------
function TGuiControl.GetFocused(): Boolean;
begin
 if (not Assigned(Owner)) then
  begin
   Result:= True;
   Exit;
  end;

 Result:= (Owner.FocusIndex = Owner.IndexOf(Self))and(Owner.Focused);
end;

//---------------------------------------------------------------------------
procedure TGuiControl.SetFocus();
begin
 if (Assigned(Owner)) then
  begin
   Owner.FocusIndex:= Owner.IndexOf(Self);
   Owner.SetFocus();
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.ToFront(Index: Integer);
var
 Aux: TGuiControl;
 i: Integer;
begin
 if (FocusIndex = Index) then FocusIndex:= 0;
 Aux:= Controls[Index];

 for i:= Index downto 1 do
  Controls[i]:= Controls[i - 1];

 Controls[0]:= Aux;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.ToBack(Index: Integer);
var
 Aux: TGuiControl;
 i: Integer;
begin
 if (FocusIndex = Index) then FocusIndex:= Length(Controls) - 1;
 Aux:= Controls[Index];

 for i:= Index to Length(Controls) - 2 do
  Controls[i]:= Controls[i + 1];

 Controls[Length(Controls) - 1]:= Aux;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.BringToFront();
begin
 if (Assigned(FOwner)) then
  FOwner.ToFront(FOwner.IndexOf(Self));
end;

//---------------------------------------------------------------------------
procedure TGuiControl.SentToBack();
begin
 if (Assigned(FOwner)) then
  FOwner.ToBack(FOwner.IndexOf(Self));
end;

//---------------------------------------------------------------------------
function TGuiControl.GetVisibleRect(): TRect;
var
 OwnerSurface: TRect;
 MySurface: TRect;
begin
 if (not Assigned(FOwner)) then
  begin
   Result:= ClientRect;
   Exit;
  end;

 // Retrieve owner VisibleRect
 OwnerSurface:= Owner.VisibleRect;

 // Calculate our theoretical VisibleRect, in absolute space
 MySurface:= MoveRect(ClientRect, Owner.VirtualRect.TopLeft);

 // The intersection of both rectangles is our result
 Result:= ShortRect(MySurface, OwnerSurface);
end;

//---------------------------------------------------------------------------
function TGuiControl.GetVirtualRect(): TRect;
begin
 if (not Assigned(FOwner)) then
  begin
   Result:= ClientRect;
   Exit;
  end;

 Result:= MoveRect(ClientRect, Owner.VirtualRect.TopLeft);
end;

//---------------------------------------------------------------------------
function TGuiControl.FindCtrlAt(const Point: TPoint2px): TGuiControl;
var
 Allowed: Boolean;
 Index: Integer;
 Aux: TGuiControl;
begin
 // Check whether this control is already pointed and if not, cannot proceed.
 Allowed:= (Visible)or(GuiDesign);
 if (not Allowed)or(not PointInRect(Point, VisibleRect)) then
  begin
   Result:= nil;
   Exit;
  end;

 Result:= Self;

 // Since this control is really pointed, see if there is any child pointed as
 // well.
 for Index:= 0 to Length(Controls) - 1 do
  begin
   Aux:= Controls[Index].FindCtrlAt(Point);
   if (Assigned(Aux)) then
    begin
     Result:= Aux;
     Break;
    end;
  end;
end;

//---------------------------------------------------------------------------
function TGuiControl.SendFocusToNext(): Boolean;
var
 i, OrderDiff, CurDiff: Integer;
 Ctrl, NextCtrl: TGuiControl;
begin
 Result:= False;
 if (not Assigned(Owner)) then Exit;

 OrderDiff:= High(Integer);
 NextCtrl := nil;

 for i:= 0 to Owner.ControlCount - 1 do
  begin
   Ctrl:= Owner.Control[i];
   if (not Assigned(Ctrl))or(Ctrl = Self)or(Ctrl.TabOrder = -1)or
    (not Ctrl.Visible)or(not Ctrl.Enabled)or
    (Ctrl.TabOrder <= FTabOrder) then Continue;

   CurDiff:= Abs(Ctrl.TabOrder - FTabOrder);
   if (CurDiff < OrderDiff) then
    begin
     NextCtrl := Ctrl;
     OrderDiff:= CurDiff;
    end;
  end;

 // Try to give the focus to the next control with the same owner.
 if (Assigned(NextCtrl)) then
  begin
   NextCtrl.SetFocus();
   Result:= True;
   Exit;
  end;

 // Try to give the focus to the next control in the parent owner, if this one
 // is the last control to be selected.
 if (Owner.SendFocusToNext()) then
  begin
   Result:= True;
   Exit;
  end;

 // Select the very first control starting from the top parent.
 NextCtrl:= RootCtrl;

 if (Assigned(NextCtrl)) then
  begin
   NextCtrl.SetFirstFocus();
   Result:= True;
   Exit;
  end;

 Result:= False;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.SetFirstFocus();
var
 i, BestOrder, BestIndex: Integer;
 Ctrl, BestCtrl: TGuiControl;
begin
 if (ControlCount < 1)and(Assigned(Owner)) then
  begin
   SetFocus();
   Exit;
  end;

 BestOrder:= High(Integer);
 BestCtrl := nil;
 BestIndex:= -1;

 for i:= 0 to ControlCount - 1 do
  begin
   Ctrl:= Control[i];
   if (not Assigned(Ctrl))or(Ctrl.TabOrder = -1)or(not Ctrl.Visible)or
    (not Ctrl.Enabled) then Continue;

   if (Ctrl.TabOrder < BestOrder) then
    begin
     BestOrder:= Ctrl.TabOrder;
     BestCtrl := Ctrl;
     BestIndex:= i;
    end;
  end;

 if (BestIndex <> -1) then FocusIndex:= BestIndex;
 if (Assigned(BestCtrl)) then BestCtrl.SetFirstFocus();
end;

//---------------------------------------------------------------------------
procedure TGuiControl.ResetFirstTimePaint();
var
 i: Integer;
begin
 IsFirstTimePaint:= False;

 for i:= Length(Controls) - 1 downto 0 do
  if (Controls[i].Visible)or(GuiDesign) then
   Controls[i].Draw();
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DoUpdate();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiControl.FirstTimePaint();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DoPaint();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DoKeyEvent(Key: Integer; Event: TKeyEventType;
 Shift: TGuiShiftState);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DoMouseEvent(const MousePos: TPoint2px;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TGuiShiftState);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiControl.Update();
var
 i: Integer;
begin
 DoUpdate();

 for i:= 0 to Length(Controls) - 1 do
  Controls[i].Update();
end;

//---------------------------------------------------------------------------
procedure TGuiControl.Draw();
var
 ViSurface: TRect;
 PrevRect: TRect;
 i: Integer;
begin
 ViSurface:= GetVisibleRect();
 if (ViSurface.Bottom <= ViSurface.Top)or
  (ViSurface.Right <= ViSurface.Left) then Exit;

 if (IsFirstTimePaint) then
  begin
   FirstTimePaint();
   IsFirstTimePaint:= False;
  end;

 PrevRect:= GuiCanvas.ClipRect;
 GuiCanvas.ClipRect:= ViSurface;

 DoPaint();

 GuiCanvas.ClipRect:= PrevRect;

 for i:= Length(Controls) - 1 downto 0 do
  if (Controls[i].Visible)or((GuiDesign)and(FCtrlHolder)) then
   Controls[i].Draw();
end;

//---------------------------------------------------------------------------
procedure TGuiControl.AcceptMouse(const MousePos: TPoint2px;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TGuiShiftState);
begin
 if (FCtrlHolder)and(Event in [metWheelUp, metWheelDown])and
  (FocusIndex >= 0)and(FocusIndex < ControlCount) then
  begin
   Control[FocusIndex].AcceptMouse(MousePos, Event, Button, Shift);
   Exit;
  end;

 DoMouseEvent(MousePos, Event, Button, Shift);

 if (Assigned(FOnMouse)) then FOnMouse(Self, MousePos, Event, Button, Shift);

 if (Event = metClick)and(Enabled)and(Assigned(FOnClick))and
  (PointInRect(MousePos, VirtualRect)) then FOnClick(Self);

 if (Event = metDblClick)and(Enabled)and(Assigned(FOnDblClick))and
  (PointInRect(MousePos, VirtualRect)) then FOnDblClick(Self);

 if (Event = metEnter) then
  begin
   FMouseOver:= True;
   if (Assigned(FOnMouseEnter)) then FOnMouseEnter(Self);
  end;

 if (Event = metLeave) then
  begin
   FMouseOver:= False;
   if (Assigned(FOnMouseLeave)) then FOnMouseLeave(Self);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.AcceptKey(Key: Integer; Event: TKeyEventType;
 Shift: TGuiShiftState);
begin
 if (FocusIndex >= 0)and(FocusIndex < ControlCount) then
  begin
   Control[FocusIndex].AcceptKey(Key, Event, Shift);
  end else
  begin
   DoKeyEvent(Key, Event, Shift);
   if (Assigned(FOnKey)) then FOnKey(Self, Key, Event, Shift);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.SelfDescribe();
begin
 inherited;

 FNameOfClass:= 'TGuiControl';

 AddProperty('Name', gptString, gpfStdString, @FName);
end;

//---------------------------------------------------------------------------
function TGuiControl.Screen2Local(const Point: TPoint2px): TPoint2px;
var
 Surf: TRect;
begin
 Surf:= GetVirtualRect();

 Result.x:= Point.x - Surf.Left;
 Result.y:= Point.y - Surf.Top;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.PasteFieldsFromStream(const Stream: TStream;
 const Master: TGuiComponent);
var
 i, Count: Integer;
 FiName: UniString;
 FiText: UniString;
begin
 // # of fields
 Count:= StreamGetWord(Stream);

 for i:= 0 to Count - 1 do
  begin
   // --> Field Name
   FiName:= StreamGetShortUtf8String(Stream);
   // --> Field Text
   FiText:= StreamGetUtf8String(Stream);

   // Make sure the name is unique. If there is existing control with this name,
   // compose a different name.
   if (SameText(FiName, 'name'))and
    (Assigned(TGuiControl(Master).Ctrl[FiText])) then
    FiText:= MakeGuiName(TGuiControl(Master), ClassName);

   ValueString[FiName]:= FiText;
  end;

 MoveBy(GuiPosGrid);
end;

//---------------------------------------------------------------------------
procedure TGuiControl.SaveChildrenToStream(Control: TGuiControl;
 const Stream: TStream);
var
 i, Count: Integer;
begin
 if (not Assigned(Control)) then Control:= Self;

 Count:= Control.ControlCount;
 if (not Control.CtrlHolder) then Count:= 0;

 // --> # of controls
 StreamPutWord(Stream, Count);

 for i:= 0 to Count - 1 do
  begin
   // --> Control Class Name
   StreamPutShortUtf8String(Stream, Control[i].NameOfClass);
   // --> Control's Properties
   Control[i].SaveFieldsToStream(Stream);

   // Dump recursively the children of the component.
   SaveChildrenToStream(Control[i], Stream);
  end;
end;

//---------------------------------------------------------------------------
function TGuiControl.SaveThisToStream(const Stream: TStream): Boolean;
begin
 Result:= True;
 
 try
  // --> # of controls (1, in this case).
  StreamPutWord(Stream, 1);

  // --> Name of the Control
  StreamPutShortUtf8String(Stream, NameOfClass);
  // --> Dump all properties
  SaveFieldsToStream(Stream);

  // Save child controls as well.
  SaveChildrenToStream(Self, Stream);
 except
  Result:= False;
 end;  
end;

//---------------------------------------------------------------------------
procedure TGuiControl.CustomLoadFromStream(Control: TGuiControl;
 const Stream: TStream);
var
 i, Count: Integer;
 CtrlName: UniString;
 NewCtrl : TGuiControl;
begin
 if (not Assigned(Control)) then Control:= Self;

 // --> # of controls
 Count:= StreamGetWord(Stream);

 for i:= 0 to Count - 1 do
  begin
   // --> Name of the Control
   CtrlName:= StreamGetShortUtf8String(Stream);

   NewCtrl:= MasterRegistry.NewControl(CtrlName, Control);
   if (not Assigned(NewCtrl)) then Break;

   // --> Control's Properties
   NewCtrl.LoadFieldsFromStream(Stream);

   // Load children as well.
   CustomLoadFromStream(NewCtrl, Stream);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.CustomPasteFromStream(Control: TGuiControl;
 const Stream: TStream; const Master: TGuiControl);
var
 i, Count: Integer;
 CtrlName: UniString;
 NewCtrl : TGuiControl;
begin
 if (not Assigned(Control)) then Control:= Self;

 // # of controls
 Count:= StreamGetWord(Stream);

 for i:= 0 to Count - 1 do
  begin
   // --> Name of the Control
   CtrlName:= StreamGetShortUtf8String(Stream);

   NewCtrl:= MasterRegistry.NewControl(CtrlName, Control);
   if (not Assigned(NewCtrl)) then Break;

   // --> Control's Properties (applying unique names and displacing on
   // the grid).
   NewCtrl.PasteFieldsFromStream(Stream, Master);

   CustomPasteFromStream(NewCtrl, Stream, Master);
  end;
end;

//---------------------------------------------------------------------------
function TGuiControl.LoadFromStream(const Stream: TStream): Boolean;
begin
 Result:= True;

 try
  CustomLoadFromStream(nil, Stream);
 except
  Result:= False;
 end;
end;

//---------------------------------------------------------------------------
function TGuiControl.SaveToStream(const Stream: TStream): Boolean;
begin
 Result:= True;

 try
  SaveChildrenToStream(nil, Stream);
 except
  Result:= False;
 end;
end;

//---------------------------------------------------------------------------
function TGuiControl.PasteFromClipboard(const Stream: TStream): Boolean;
begin
 Result:= True;

 try
  CustomPasteFromStream(Self, Stream, RootCtrl);
 except
  Result:= False;
 end;
end;

//---------------------------------------------------------------------------
{$ifndef StandardStringsOnly}
function TGuiControl.SaveThisToString(out Text: AnsiString): Boolean;
{$else}
function TGuiControl.SaveThisToString(out Text: StdString): Boolean;
{$endif}
var
 Stream: TMemoryStream;
begin
 Stream:= TMemoryStream.Create();

 Result:= SaveThisToStream(Stream);
 if (not Result) then
  begin
   FreeAndNil(Stream);
   Exit;
  end;

 Text:= Base64String(Stream.Memory, Stream.Size);
 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
{$ifndef StandardStringsOnly}
function TGuiControl.PasteFromString(const Text: AnsiString): Boolean;
{$else}
function TGuiControl.PasteFromString(const Text: StdString): Boolean;
{$endif}
var
 Stream: TMemoryStream;
begin
 Stream:= TMemoryStream.Create();
 Stream.SetSize(Round(Length(Text) * 3 / 4) + 1);
 Stream.SetSize(Base64Binary(Text, Stream.Memory));

 Result:= PasteFromClipboard(Stream);
 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
procedure TGuiControl.ShowWindow(const FormName: StdString;
 FirstTime: Boolean = False);
var
 i: Integer;
 Ctrl, PickCtrl: TGuiControl;
begin
 PickCtrl:= nil;

 for i:= 0 to ControlCount - 1 do
  begin
   Ctrl:= Controls[i];
   if (not Assigned(Ctrl))or(not (Ctrl is TGuiForm)) then Continue;

   if (SameText(Ctrl.Name, FormName)) then
    begin
     if (not Ctrl.Visible)or(FirstTime) then PickCtrl:= Ctrl;

     Ctrl.Visible:= True;

     Ctrl.Left:= (Width - Ctrl.Width) div 2;
     Ctrl.Top := (Height - Ctrl.Height) div 2;
    end else Ctrl.Visible:= False;
  end;

 if (Assigned(PickCtrl)) then PickCtrl.SetFirstFocus();
end;

//---------------------------------------------------------------------------
function TGuiControl.GetOwnerFormName(): StdString;
var
 Ctrl: TGuiControl;
begin
 Result:= '';

 Ctrl:= FindPreRootCtrl();
 if (Assigned(Ctrl)) then Result:= Ctrl.Name;
end;

//---------------------------------------------------------------------------
function TGuiControl.GetEnumerator(): TGuiControlEnumerator;
begin
 Result:= TGuiControlEnumerator.Create(Self);
end;

//---------------------------------------------------------------------------
constructor TGuiControlEnumerator.Create(AParent: TGuiControl);
begin
 inherited Create();

 FParent:= AParent;
 Index:= -1;
end;

//---------------------------------------------------------------------------
function TGuiControlEnumerator.GetCurrent(): TGuiControl;
begin
 Result:= FParent.Control[Index];
end;

//---------------------------------------------------------------------------
function TGuiControlEnumerator.MoveNext(): Boolean;
begin
 Result:= Index < FParent.ControlCount - 1;
 if (Result) then Inc(Index);
end;

//---------------------------------------------------------------------------
end.

