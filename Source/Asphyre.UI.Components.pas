unit Asphyre.UI.Components;
//---------------------------------------------------------------------------
// Base component class for Asphyre GUI framework.
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
 System.Types, System.Classes, Asphyre.TypeDef, Asphyre.Math,
 Asphyre.UI.Types;

//---------------------------------------------------------------------------
type
 TGuiComponent = class(TGuiObject)
 private
  FLeft  : Integer;
  FTop   : Integer;
  FWidth : Integer;
  FHeight: Integer;

  FTag     : Integer;
  FVisible : Boolean;
  FEnabled : Boolean;
  FOnResize: TNotifyEvent;
  FOnShow  : TNotifyEvent;
  FOnHide  : TNotifyEvent;

  ResizeFieldTag: Integer;

  function GetClientRect(): TRect;
  procedure SetClientRect(const Value: TRect);
  procedure SetVisible(const Value: Boolean);
  procedure SetEnabled(const Value: Boolean);
  procedure SetWidth(const Value: Integer);
  procedure SetHeight(const Value: Integer);
 protected
  procedure SelfDescribe(); override;

  procedure AfterChange(const AFieldName: StdString;
   PropType: TGuiPropertyType; PropTag: Integer); override;

  property OnResize: TNotifyEvent read FOnResize write FOnResize;
  property OnShow: TNotifyEvent read FOnShow write FOnShow;
  property OnHide: TNotifyEvent read FOnHide write FOnHide;

  procedure DoResize(); virtual;
  procedure DoShow(); virtual;
  procedure DoHide(); virtual;
  procedure DoEnable(); virtual;
  procedure DoDisable(); virtual;

  procedure LoadFieldsFromStream(const Stream: TStream);
  procedure SaveFieldsToStream(const Stream: TStream);
 public
  property ClientRect: TRect read GetClientRect write SetClientRect;

  property Left  : Integer read FLeft write FLeft;
  property Top   : Integer read FTop write FTop;
  property Width : Integer read FWidth write SetWidth;
  property Height: Integer read FHeight write SetHeight;

  property Tag    : Integer read FTag write FTag;
  property Visible: Boolean read FVisible write SetVisible;
  property Enabled: Boolean read FEnabled write SetEnabled;

  procedure Show();
  procedure Hide();

  procedure MoveBy(const Delta: TPoint2px);
  procedure ResizeBy(const Delta: TPoint2px);
  procedure ApplyConstraint(const Constraint: TRect);
  procedure SetSize(const NewSize: TPoint2px);

  constructor Create();
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types, Asphyre.Streams;

//---------------------------------------------------------------------------
constructor TGuiComponent.Create();
begin
 inherited;

 FLeft:= 0;
 FTop := 0;

 FWidth := 0;
 FHeight:= 0;

 FVisible:= True;
 FEnabled:= True;
 FTag    := 0;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.DoResize();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.DoShow();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.DoHide();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.DoEnable();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.DoDisable();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SetWidth(const Value: Integer);
begin
 if (FWidth <> Value) then
  begin
   FWidth:= Value;

   DoResize();
   if (Assigned(FOnResize)) then FOnResize(Self);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SetHeight(const Value: Integer);
begin
 if (FHeight <> Value) then
  begin
   FHeight:= Value;

   DoResize();
   if (Assigned(FOnResize)) then FOnResize(Self);
  end;
end;

//---------------------------------------------------------------------------
function TGuiComponent.GetClientRect(): TRect;
begin
 Result:= Bounds(FLeft, FTop, FWidth, FHeight);
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SetClientRect(const Value: TRect);
var
 PrevPos, PrevSize: TPoint2px;
begin
 PrevPos := Point2px(FLeft, FTop);
 PrevSize:= Point2px(FWidth, FHeight);

 FLeft:= Value.Left;
 FTop := Value.Top;

 FWidth := Value.Right - Value.Left;
 FHeight:= Value.Bottom - Value.Top;

 if (PrevPos.x <> FLeft)or(PrevPos.y <> FTop)or(PrevSize.x <> FWidth)or
  (PrevSize.y <> FHeight) then
  begin
   DoResize();
   if (Assigned(FOnResize)) then FOnResize(Self);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SetVisible(const Value: Boolean);
begin
 if (FVisible <> Value) then
  begin
   FVisible:= Value;

   if (FVisible) then
    begin
     DoShow();
     if (Assigned(FOnShow)) then FOnShow(Self);
    end else
    begin
     if (Assigned(FOnHide)) then FOnHide(Self);
     DoHide();
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.Show();
begin
 Visible:= True;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.Hide();
begin
 Visible:= False;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SetEnabled(const Value: Boolean);
begin
 if (FEnabled <> Value) then
  begin
   FEnabled:= Value;
   if (FEnabled) then DoEnable() else DoDisable();
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SelfDescribe();
begin
 FNameOfClass:= 'TGuiComponent';

 ResizeFieldTag:= NextFieldTag();

 AddProperty('Left', gptInteger, gpfInteger, @FLeft, SizeOf(Integer), 
  ResizeFieldTag);

 AddProperty('Top', gptInteger, gpfInteger, @FTop, SizeOf(Integer), 
  ResizeFieldTag);

 AddProperty('Width', gptInteger, gpfInteger, @FWidth, SizeOf(Integer), 
  ResizeFieldTag);

 AddProperty('Height', gptInteger, gpfInteger, @FHeight, SizeOf(Integer), 
  ResizeFieldTag);

 AddProperty('Tag', gptInteger, gpfInteger, @FTag, SizeOf(Integer));
 AddProperty('Visible', gptBoolean, gpfBoolean, @FVisible, SizeOf(Boolean));
 AddProperty('Enabled', gptBoolean, gpfBoolean, @FEnabled, SizeOf(Boolean));
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.MoveBy(const Delta: TPoint2px);
begin
 Inc(FLeft, Delta.x);
 Inc(FTop, Delta.y);
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.ResizeBy(const Delta: TPoint2px);
var
 PrevWidth, PrevHeight: Integer;
begin
 PrevWidth := FWidth;
 PrevHeight:= FHeight;

 FWidth := Max2(FWidth + Delta.x, 0);
 FHeight:= Max2(FHeight + Delta.y, 0);

 if ((PrevWidth <> FWidth)or(PrevHeight <> FHeight)) then
  begin
   DoResize();
   if (Assigned(FOnResize)) then FOnResize(Self);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SetSize(const NewSize: TPoint2px);
begin
 if (FWidth <> NewSize.x)or(FHeight <> NewSize.y) then
  begin
   FWidth := NewSize.x;
   FHeight:= NewSize.y;

   DoResize();
   if (Assigned(FOnResize)) then FOnResize(Self);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.ApplyConstraint(const Constraint: TRect);
begin
 ClientRect:= ShortRect(ClientRect, Constraint);
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.AfterChange(const AFieldName: StdString;
 PropType: TGuiPropertyType; PropTag: Integer);
begin
 inherited;

 if (PropTag = ResizeFieldTag) then
  begin
   DoResize();
   if (Assigned(FOnResize)) then FOnResize(Self);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SaveFieldsToStream(const Stream: TStream);
var
 i, Count: Integer;
 FiName: UniString;
 FiText: UniString;
begin
 Count:= FieldCount;

 // --> # of fields
 StreamPutWord(Stream, Count);

 for i:= 0 to Count - 1 do
  begin
   FiName:= FieldName[i];
   FiText:= ValueString[FiName];

   // --> Field Name
   StreamPutShortUtf8String(Stream, FiName);
   // --> Field Text
   StreamPutUtf8String(Stream, FiText);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.LoadFieldsFromStream(const Stream: TStream);
var
 i, Count: Integer;
 FiName: UniString;
 FiText: UniString;
begin
 // --> # of fields
 Count:= StreamGetWord(Stream);

 for i:= 0 to Count - 1 do
  begin
   // --> Field Name
   FiName:= StreamGetShortUtf8String(Stream);
   // --> Field Text
   FiText:= StreamGetUtf8String(Stream);

   ValueString[FiName]:= FiText;
  end;
end;

//---------------------------------------------------------------------------
end.
