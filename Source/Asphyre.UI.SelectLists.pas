unit Asphyre.UI.SelectLists;
//---------------------------------------------------------------------------
// Animated selection lists for Asphyre GUI framework.
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
 System.SysUtils, Asphyre.Math.Sets;

//---------------------------------------------------------------------------
type
 PGuiSelectItem = ^TGuiSelectItem;
 TGuiSelectItem = record
  Index: Integer;
  Alpha: Integer;
 end;

//---------------------------------------------------------------------------
 TGuiSelectItems = class
 private
  FSelectIndex: Integer;
  Data: array of TGuiSelectItem;

  FAlphaInc: Integer;
  FAlphaDec: Integer;

  FMultiIndexes: TIntegerList;
  WorkList: TIntegerList;

  function GetItem(Index: Integer): PGuiSelectItem;
  function GetItemCount: Integer;
  function GetIndexAlpha(SelIndex: Integer): Integer;
  procedure InsertIt(ItIndex, ItAlpha: Integer);
 public
  property ItemCount: Integer read GetItemCount;
  property Items[Index: Integer]: PGuiSelectItem read GetItem; default;

  property IndexAlpha[SelIndex: Integer]: Integer read GetIndexAlpha;

  property SelectIndex: Integer read FSelectIndex write FSelectIndex;

  property AlphaInc: Integer read FAlphaInc write FAlphaInc;
  property AlphaDec: Integer read FAlphaDec write FAlphaDec;

  property MultiIndexes: TIntegerList read FMultiIndexes;

  procedure Update();
  procedure Reset();

  procedure InstantAlpha();
  function IndexOf(ItIndex: Integer): Integer;

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types;

//---------------------------------------------------------------------------
constructor TGuiSelectItems.Create();
begin
 inherited;

 FMultiIndexes:= TIntegerList.Create();
 WorkList:= TIntegerList.Create();

 FSelectIndex:= -1;

 FAlphaInc:= 16;
 FAlphaDec:= 12;
end;

//---------------------------------------------------------------------------
destructor TGuiSelectItems.Destroy();
begin
 FreeAndNil(WorkList);
 FreeAndNil(FMultiIndexes);

 inherited;
end;

//---------------------------------------------------------------------------
function TGuiSelectItems.GetItemCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TGuiSelectItems.GetItem(Index: Integer): PGuiSelectItem;
begin
 if (Index >= 0)and(Index < Length(Data)) then
  Result:= @Data[Index]
   else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TGuiSelectItems.InsertIt(ItIndex, ItAlpha: Integer);
var
 Ind: Integer;
begin
 Ind:= Length(Data);
 SetLength(Data, Ind + 1);

 Data[Ind].Index:= ItIndex;
 Data[Ind].Alpha:= ItAlpha;
end;

//---------------------------------------------------------------------------
procedure TGuiSelectItems.Update();
var
 i, Index, ItIndex: Integer;
begin
 WorkList.Clear();

 for i:= Length(Data) - 1 downto 0 do
  if (Data[i].Index = FSelectIndex)or(FMultiIndexes.Exists(Data[i].Index)) then
   begin
    Data[i].Alpha:= Min2(Data[i].Alpha + FAlphaInc, 255);
    WorkList.Insert(Data[i].Index);
   end else
   begin
    Data[i].Alpha:= Max2(Data[i].Alpha - FAlphaDec, 0);

    if (Data[i].Alpha <= 0) then
     begin
      Index:= Length(Data) - 1;
      if (i <> Index) then Data[i]:= Data[Index];

      SetLength(Data, Length(Data) - 1);
     end;
   end;

 if (FSelectIndex <> -1)and(not WorkList.Exists(FSelectIndex)) then
  InsertIt(FSelectIndex, FAlphaInc);

 for i:= 0 to FMultiIndexes.Count - 1 do
  begin
   ItIndex:= FMultiIndexes[i];
   if (WorkList.Exists(ItIndex)) then Continue;

   InsertIt(ItIndex, FAlphaInc);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiSelectItems.Reset();
begin
 if (FSelectIndex <> -1) then
  begin
   SetLength(Data, 1);

   Data[0].Index:= FSelectIndex;
   Data[0].Alpha:= 255;
  end else
   SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
function TGuiSelectItems.GetIndexAlpha(SelIndex: Integer): Integer;
var
 i: Integer;
begin
 Result:= 0;

 for i:= 0 to Length(Data) - 1 do
  if (Data[i].Index = SelIndex) then
   begin
    Result:= Data[i].Alpha;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TGuiSelectItems.IndexOf(ItIndex: Integer): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Data) - 1 do
  if (Data[i].Index = ItIndex) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
procedure TGuiSelectItems.InstantAlpha();
var
 Index: Integer;
begin
 if (FSelectIndex = -1) then Exit;

 Index:= IndexOf(FSelectIndex);
 if (Index = -1) then
  begin
   InsertIt(FSelectIndex, 255);
   Exit;
  end;

 Data[Index].Alpha:= 255; 
end;

//---------------------------------------------------------------------------
end.
