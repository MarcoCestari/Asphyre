unit Asphyre.UI.Taskbar;
//---------------------------------------------------------------------------
// Taskbar components for Asphyre GUI framework.
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
// Additional Comments:
//
// The mouse handling is issued by this Taskbar component. The Mouse Enter
// event is issued when mouse enters certain control. Only this control
// receives MouseEnter event. If the user clicks on that control, MouseLeave
// event is issued only after user "unclicked" the button. This will not work
// for buttons as they will continue to be pressed until user "unclicks", no
// matter where the mouse cursor is.
//
// In addition to the above, components have "MouseOver" property. When a
// certain control is selected by mouse, its MouseOver property is True, as
// well as all its ancestors. If the user clicks on the component, the
// property MouseOver is locked to that component. However, if the user
// selects another control while holding click, the destination MouseOver
// component will be chosen within common ancestors between the control that
// was clicked on and the one pointed by the mouse. For instance, if a button
// is clicked on and then user drags mouse away to another button, the owner
// window will have its MouseOver property set but neigher of the buttons.
// The above can be useful for buttons so if user clicks on a button but then
// decides to cancel the click, the mouse can be dragged away from the button
// and "unclicking" will not trigger the button.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
{$ifdef FireMonkey}
 System.UITypes,
{$else}
 {$ifndef fpc}
  Vcl.Controls,
 {$else}
  Controls,
 {$endif}
{$endif}

{$ifndef fpc}
 System.Classes,
{$else}
 Classes,
{$endif}
 Asphyre.TypeDef, Asphyre.Math, Asphyre.Archives,
 Asphyre.UI.Types, Asphyre.UI.Controls;

//---------------------------------------------------------------------------
type
 TGuiTaskbar = class(TGuiControl)
 private
  FMousePos : TPoint2px;
  LastButton: TMouseButtonType;
  LastShift : TGuiShiftState;
  LastOver  : TGuiControl;
  LastClick : TGuiControl;
  ClickLevel: Integer;

  procedure ListObjectNames(Control: TGuiControl; Strings: TStrings);
  procedure ResetMouseOver(Ctrl: TGuiControl);
  procedure SetMouseOver(Ctrl: TGuiControl);
  function HasAncestor(Ctrl, Ancest: TGuiControl): Boolean;
  function FindCommonAncestor(Ctrl, Other: TGuiControl): TGuiControl;
 protected
  procedure DoMouseEvent(const MousePos: TPoint2px; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TGuiShiftState); override;
  procedure DoKeyEvent(Key: Integer; Event: TKeyEventType;
   Shift: TGuiShiftState); override;
 public
  property MousePos: TPoint2px read FMousePos;

  function FindCtrlAt(const Point: TPoint2px): TGuiControl; override;

  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure MouseMove(Shift: TShiftState; X, Y: Integer);
  procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer;
   const MouseAt: TPoint2px);
  procedure KeyDown(Key: Word; Shift: TShiftState);
  procedure KeyUp(Key: Word; Shift: TShiftState);
  procedure KeyPress(Key: Char);
  procedure Click();
  procedure DblClick();

  procedure MakeObjectList(Strings: TStrings);

  // Clears LastOver and LastClick references since the control is
  // being deleted.
  procedure RemoveRef();

  function SaveToFile(const Filename: StdString): Boolean;
  function LoadFromFile(const Filename: StdString): Boolean;
  function LoadFromArchive(const Key: WideString;
   Archive: TAsphyreArchive): Boolean;

  constructor Create(const AOwner: TGuiControl); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.SysUtils,
{$else}
 SysUtils,
{$endif}
 Asphyre.Archives.Auth, Asphyre.UI.Forms;

//---------------------------------------------------------------------------
constructor TGuiTaskbar.Create(const AOwner: TGuiControl);
begin
 inherited;

 Visible   := True;
 Enabled   := True;
 FMousePos := Point2px(0, 0);
 LastOver  := nil;
 ClickLevel:= 0;

 FCtrlHolder:= True;
end;

//---------------------------------------------------------------------------
function TGuiTaskbar.FindCtrlAt(const Point: TPoint2px): TGuiControl;
begin
 Result:= inherited FindCtrlAt(Point);
 if (Result = Self) then Result:= nil;

 if (GuiDesign) then
  begin
   while (Assigned(Result))and(Assigned(Result.Owner))and
    (not Result.Owner.CtrlHolder) do
    Result:= Result.Owner;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.MouseDown(Button: TMouseButton; Shift: TShiftState;
 X, Y: Integer);
begin
 FMousePos := Point2px(X, Y);
 LastButton:= ButtonToGui(Button);
 LastShift := ShiftToGui(Shift);

 AcceptMouse(FMousePos, metDown, LastButton, LastShift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
 FMousePos := Point2px(X, Y);
 LastButton:= mbtNone;
 LastShift := ShiftToGui(Shift);

 AcceptMouse(FMousePos, metMove, LastButton, LastShift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.MouseUp(Button: TMouseButton; Shift: TShiftState;
 X, Y: Integer);
begin
 FMousePos := Point2px(X, Y);
 LastButton:= ButtonToGui(Button);
 LastShift := ShiftToGui(Shift);

 AcceptMouse(FMousePos, metUp, LastButton, LastShift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.MouseWheel(Shift: TShiftState; WheelDelta: Integer;
 const MouseAt: TPoint2px);
begin
 if (WheelDelta = 0) then Exit;

 FMousePos := MouseAt;
 LastButton:= mbtNone;
 LastShift := ShiftToGui(Shift);

 if (WheelDelta < 0) then
  begin
   AcceptMouse(Point2px(GuiEncodeMousePos(FMousePos), -WheelDelta),
    metWheelDown, LastButton, LastShift);
  end else
  begin
   AcceptMouse(Point2px(GuiEncodeMousePos(FMousePos), WheelDelta), metWheelUp,
    LastButton, LastShift);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.Click();
begin
 AcceptMouse(FMousePos, metClick, LastButton, LastShift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.DblClick();
begin
 AcceptMouse(FMousePos, metDblClick, LastButton, LastShift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.KeyPress(Key: Char);
begin
 AcceptKey(Byte(Key), ketPress, []);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.KeyDown(Key: Word; Shift: TShiftState);
begin
 AcceptKey(Byte(Key), ketDown, ShiftToGui(Shift));
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.KeyUp(Key: Word; Shift: TShiftState);
begin
 AcceptKey(Byte(Key), ketUp, ShiftToGui(Shift));
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.ResetMouseOver(Ctrl: TGuiControl);
var
 i: Integer;
 Child: TGuiControl;
begin
 if (not Assigned(Ctrl)) then Exit;
 Ctrl.MouseOver:= False;

 for i:= 0 to Ctrl.ControlCount - 1 do
  begin
   Child:= Ctrl.Control[i];
   if (Assigned(Child)) then ResetMouseOver(Child);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.SetMouseOver(Ctrl: TGuiControl);
var
 Prev: TGuiControl;
begin
 if (not Assigned(Ctrl)) then Exit;

 Ctrl.MouseOver:= True;

 Prev:= Ctrl.Owner;
 while (Assigned(Prev)) do
  begin
   Prev.MouseOver:= True;
   Prev:= Prev.Owner;
  end;
end;

//---------------------------------------------------------------------------
function TGuiTaskbar.HasAncestor(Ctrl, Ancest: TGuiControl): Boolean;
begin
 Result:= False;
 if (not Assigned(Ancest)) then Exit;

 while (Assigned(Ctrl)) do
  begin
   if (Ctrl = Ancest) then
    begin
     Result:= True;
     Break;
    end;

   Ctrl:= Ctrl.Owner;
  end;
end;

//---------------------------------------------------------------------------
function TGuiTaskbar.FindCommonAncestor(Ctrl, Other: TGuiControl): TGuiControl;
begin
 Result:= nil;
 if (not Assigned(Other)) then Exit;

 while (Assigned(Other)) do
  begin
   if (HasAncestor(Ctrl, Other)) then
    begin
     Result:= Other;
     Break;
    end;

   Other:= Other.Owner;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.DoMouseEvent(const MousePos: TPoint2px;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TGuiShiftState);
var
 CtrlOver : TGuiControl;
 EventCtrl: TGuiControl;
begin
 if (Button = mbtRight)and(GuiDesign) then Exit;

 if (Event in [metWheelUp, metWheelDown]) then
  begin
   if (FocusIndex >= 0)and(FocusIndex < ControlCount) then
    Control[FocusIndex].AcceptMouse(MousePos, Event, Button, Shift);

   Exit; 
  end;

 // (1) Find the control pointed by the mouse.
 CtrlOver:= FindCtrlAt(MousePos);

 // (2) Whom to send mouse event?
 EventCtrl:= CtrlOver;
 if (Assigned(LastClick)) then EventCtrl:= LastClick;

 // (3) Check whether a user pressed mouse button.
 if (Event = metDown)and(Assigned(CtrlOver)) then
  begin
   if (ClickLevel <= 0) then
    begin
     CtrlOver.SetFocus();
     LastClick:= CtrlOver;
    end;

   if (LastClick is TGuiForm) then LastClick.SetFocus();
   Inc(ClickLevel);
  end;

 // (4) Verify if the user released mouse button.
 if (Event = metUp) then
  begin
   Dec(ClickLevel);
   if (ClickLevel <= 0) then LastClick:= nil;
  end;

 // (5) Notify control pointed by the mouse that it is being ENTERED
 if (ClickLevel <= 0)and(LastOver <> CtrlOver) then
  begin
   if (Assigned(CtrlOver)) then CtrlOver.AcceptMouse(MousePos, metEnter,
    Button, Shift);
  end;

 // (6) Send the mouse event
 if (Assigned(EventCtrl))and(EventCtrl.Enabled) then
  EventCtrl.AcceptMouse(MousePos, Event, Button, Shift);

 // (7) Notify control no longer pointed by the mouse, that it is LEFT
 if (ClickLevel <= 0)and(LastOver <> CtrlOver) then
  begin
   if (Assigned(LastOver)) then LastOver.AcceptMouse(MousePos, metLeave,
    Button, Shift);
   LastOver:= CtrlOver;
  end;

 // (8) Update "MouseOver" property for the controls.
 ResetMouseOver(Self);

 if (ClickLevel <= 0)or(CtrlOver = LastClick) then SetMouseOver(CtrlOver)
  else SetMouseOver(FindCommonAncestor(LastClick, CtrlOver));
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.DoKeyEvent(Key: Integer; Event: TKeyEventType;
 Shift: TGuiShiftState);
begin
 if (FocusIndex >= 0)and(FocusIndex < ControlCount) then
  Control[FocusIndex].AcceptKey(Key, Event, Shift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.ListObjectNames(Control: TGuiControl; Strings: TStrings);
var
 Index: Integer;
begin
 if (not Control.CtrlHolder) then Exit;
 
 for Index:= 0 to Control.ControlCount - 1 do
  begin
   Strings.Add(Control[Index].Name + ':' + Control[Index].NameOfClass);
   ListObjectNames(Control[Index], Strings);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.MakeObjectList(Strings: TStrings);
begin
 ListObjectNames(Self, Strings);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.RemoveRef();
begin
 LastOver := nil;
 LastClick:= nil;
end;

//---------------------------------------------------------------------------
function TGuiTaskbar.SaveToFile(const Filename: StdString): Boolean;
var
 Stream: TFileStream;
begin
 try
  Stream:= TFileStream.Create(Filename, fmCreate or fmShareExclusive);
 except
  Result:= False;
  Exit;
 end;

 try
  Result:= SaveToStream(Stream);
 finally
  FreeAndNil(Stream);
 end;
end;

//---------------------------------------------------------------------------
function TGuiTaskbar.LoadFromFile(const Filename: StdString): Boolean;
var
 Stream: TFileStream;
begin
 try
  Stream:= TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
 except
  Result:= False;
  Exit;
 end;

 try
  Result:= LoadFromStream(Stream);
 finally
  FreeAndNil(Stream);
 end;
end;

//---------------------------------------------------------------------------
function TGuiTaskbar.LoadFromArchive(const Key: WideString;
 Archive: TAsphyreArchive): Boolean;
var
 Stream: TMemoryStream;
begin
 Auth.Authorize(Self, Archive);

 Stream:= TMemoryStream.Create();
 Result:= Archive.ReadStream(Key, Stream);

 Auth.Unauthorize();

 if (not Result) then
  begin
   FreeAndNil(Stream);
   Exit;
  end;

 Stream.Seek(0, soFromBeginning);
 Result:= LoadFromStream(Stream);

 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
end.
