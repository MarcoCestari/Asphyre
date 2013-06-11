unit Asphyre.Strings.Aliases;
//---------------------------------------------------------------------------
// Short aliases for long file names for media descriptions.
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
 System.SysUtils, Asphyre.TypeDef;

//---------------------------------------------------------------------------
type
 TFileNameAlias = record
  Alias: StdString;
  FileName: StdString;
 end;

//---------------------------------------------------------------------------
 TFileNameAliases = class
 private
  Items: array of TFileNameAlias;
  SearchDirty: Boolean;

  procedure SearchListSwap(Index1, Index2: Integer);
  function SearchListCompare(Index1, Index2: Integer): Integer;
  function SearchListSplit(Start, Stop: Integer): Integer;
  procedure SearchListSort(Start, Stop: Integer);
  procedure UpdateSearchList();
  function IndexOf(const Alias: StdString): Integer;
  procedure Remove(Index: Integer);
  function GetFileName(const Alias: StdString): StdString;
 public
  property FileName[const Alias: StdString]: StdString read GetFileName; default;

  procedure Define(const Alias, AFileName: StdString);
  procedure Undefine(const Alias: StdString);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
 FileAliases: TFileNameAliases = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TFileNameAliases.Create();
begin
 inherited;

 SearchDirty:= False;
end;

//---------------------------------------------------------------------------
destructor TFileNameAliases.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
procedure TFileNameAliases.SearchListSwap(Index1, Index2: Integer);
var
 Aux: TFileNameAlias;
begin
 Aux:= Items[Index1];

 Items[Index1]:= Items[Index2];
 Items[Index2]:= Aux;
end;

//---------------------------------------------------------------------------
function TFileNameAliases.SearchListCompare(Index1, Index2: Integer): Integer;
begin
 Result:= CompareText(Items[Index1].Alias, Items[Index2].Alias);
end;

//---------------------------------------------------------------------------
function TFileNameAliases.SearchListSplit(Start, Stop: Integer): Integer;
var
 Left, Right, Pivot: Integer;
begin
 Left := Start + 1;
 Right:= Stop;
 Pivot:= Start;

 while (Left <= Right) do
  begin
   while (Left <= Stop)and(SearchListCompare(Left, Pivot) < 0) do 
    Inc(Left);

   while (Right > Start)and(SearchListCompare(Right, Pivot) >= 0) do 
    Dec(Right);

   if (Left < Right) then SearchListSwap(Left, Right);
  end;

 SearchListSwap(Start, Right);

 Result:= Right;
end;

//---------------------------------------------------------------------------
procedure TFileNameAliases.SearchListSort(Start, Stop: Integer);
var
 SplitPt: Integer;
begin
 if (Start < Stop) then
  begin
   SplitPt:= SearchListSplit(Start, Stop);

   SearchListSort(Start, SplitPt - 1);
   SearchListSort(SplitPt + 1, Stop);
  end;
end;

//---------------------------------------------------------------------------
procedure TFileNameAliases.UpdateSearchList();
begin
 if (Length(Items) > 1) then 
  SearchListSort(0, Length(Items) - 1);

 SearchDirty:= False;
end;

//---------------------------------------------------------------------------
function TFileNameAliases.IndexOf(const Alias: StdString): Integer;
var
 Lo, Hi, Mid, Res: Integer;
begin
 if (SearchDirty) then UpdateSearchList();

 Result:= -1;

 Lo:= 0;
 Hi:= Length(Items) - 1;

 while (Lo <= Hi) do
  begin
   Mid:= (Lo + Hi) div 2;
   Res:= CompareText(Items[Mid].Alias, Alias);

   if (Res = 0) then
    begin
     Result:= Mid;
     Break;
    end;

   if (Res > 0) then Hi:= Mid - 1 
    else Lo:= Mid + 1;
 end;
end;

//---------------------------------------------------------------------------
procedure TFileNameAliases.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Items)) then Exit;

 for i:= 0 to Length(Items) - 2 do
  Items[i]:= Items[i + 1];

 SetLength(Items, Length(Items) - 1);
end;

//---------------------------------------------------------------------------
procedure TFileNameAliases.Define(const Alias, AFileName: StdString);
var
 Index: Integer;
begin
 Index:= IndexOf(Alias);
 if (Index <> -1) then
  begin
   Items[Index].FileName:= AFileName;
   Exit;
  end;

 Index:= Length(Items);
 SetLength(Items, Index + 1);

 Items[Index].Alias:= Alias;
 Items[Index].FileName:= AFileName;

 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TFileNameAliases.Undefine(const Alias: StdString);
var
 Index: Integer;
begin
 Index:= IndexOf(Alias);
 if (Index <> -1) then Remove(Index);
end;

//---------------------------------------------------------------------------
function TFileNameAliases.GetFileName(const Alias: StdString): StdString;
var
 Index: Integer;
begin
 Index:= IndexOf(Alias);

 if (Index <> -1) then Result:= Items[Index].FileName
  else Result:= '';
end;

//---------------------------------------------------------------------------
initialization
 FileAliases:= TFileNameAliases.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(FileAliases);

//---------------------------------------------------------------------------
end.
