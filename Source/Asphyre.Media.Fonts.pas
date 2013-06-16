unit Asphyre.Media.Fonts;
//---------------------------------------------------------------------------
// Resource management utility for Asphyre fonts.
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
 System.SysUtils,
{$else}
 SysUtils,
{$endif}
 Asphyre.TypeDef, Asphyre.Math.Sets, Asphyre.XML,
 Asphyre.Media.Utils;

//---------------------------------------------------------------------------
type
 TFontDesc = class
 private
  FFontName : StdString;
  FImageName: StdString;
  FDataLink : StdString;

  FKerning   : Single;
  FWhitespace: Single;
  FLinespace : Single;

  FLetterShifts: TPointList;
 public
  property FontName : StdString read FFontName;
  property ImageName: StdString read FImageName;
  property DataLink : StdString read FDataLink;

  property Kerning   : Single read FKerning;
  property Whitespace: Single read FWhitespace;
  property Linespace : Single read FLinespace;

  property LetterShifts: TPointList read FLetterShifts;

  procedure ParseXMLNode(Node: TXMLNode);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TFontGroup = class
 private
  Elements: array of TFontDesc;

  FName  : StdString;
  FOption: StdString;

  function GetCount(): Integer;
  function GetItem(Num: Integer): TFontDesc;
  function NewItem(): TFontDesc;
 public
  property Name  : StdString read FName;
  property Option: StdString read FOption;

  property Count: Integer read GetCount;
  property Item[Num: Integer]: TFontDesc read GetItem; default;

  function Find(const AFontName: StdString): TFontDesc;
  procedure ParseXMLNode(Node: TXMLNode);

  procedure Clear();

  constructor Create(const AName: StdString);
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TFontGroups = class
 private
  Groups: array of TFontGroup;
  FOption: StdString;

  function GetCount(): Integer;
  function GetItem(Num: Integer): TFontGroup;
  function GetGroup(const AGroupName: StdString): TFontGroup;
  function NewGroup(const AGroupName: StdString): TFontGroup;
  function GetTotalElements(): Integer;
 public
  property Count: Integer read GetCount;
  property Item[Num: Integer]: TFontGroup read GetItem;
  property Group[const AGroupName: StdString]: TFontGroup read GetGroup;

  property Option: StdString read FOption write FOption;

  property TotalElements: Integer read GetTotalElements;

  function IndexOf(const AGroupName: StdString): Integer;
  procedure Clear();

  function FindFont(const AFontName: StdString): TFontDesc;
  procedure ParseLink(const ALink: StdString);
  procedure ParseFolder(Link: StdString);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
 FontGroups: TFontGroups = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TFontDesc.Create();
begin
 inherited;

 FLetterShifts:= TPointList.Create();

 FFontName := '';
 FImageName:= '';
 FDataLink := '';

 FKerning   := 0.0;
 FWhitespace:= 0.0;
 FLinespace := 0.0;
end;

//---------------------------------------------------------------------------
destructor TFontDesc.Destroy();
begin
 FreeAndNil(FLetterShifts);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TFontDesc.ParseXMLNode(Node: TXMLNode);
var
 Child, Aux: TXMLNode;
 AsciiText : StdString;
 Code1, Code2, Delta: Integer;
begin
 FFontName := Node.FieldValue['name'];
 FDataLink := Node.FieldValue['link'];
 FImageName:= Node.FieldValue['image'];

 // -> "attrib" node
 Child:= Node.ChildNode['attrib'];
 if (Assigned(Child)) then
  begin
   FKerning   := ParseFloat(Child.FieldValue['kerning']);
   FWhitespace:= ParseFloat(Child.FieldValue['whitespace']);
   FLinespace := ParseFloat(Child.FieldValue['linespace']);
  end;

 // -> "letters" node
 Child:= Node.ChildNode['letters'];
 if (Assigned(Child)) then
  for Aux in Child do
   if (SameText(Aux.Name, 'delta')) then
    begin
     AsciiText:= Aux.FieldValue['ascii'];

     if (Length(AsciiText) < 2) then
      begin
       Code1:= ParseInt(Aux.FieldValue['code1'], -1);
       Code2:= ParseInt(Aux.FieldValue['code2'], -1);
      end else
      begin
       Code1:= Byte(AsciiText[1]);
       Code2:= Byte(AsciiText[2]);
      end;

     Delta:= ParseInt(Aux.FieldValue['value'], 0);

     if (Code1 >= 0)and(Code2 >= 0)and(Delta <> 0) then
      FLetterShifts.Insert(Code1, Code2, Pointer(Delta));
    end;
end;

//---------------------------------------------------------------------------
constructor TFontGroup.Create(const AName: StdString);
begin
 inherited Create();

 FName:= AName;
end;

//---------------------------------------------------------------------------
destructor TFontGroup.Destroy();
begin
 Clear();

 inherited;
end;

//---------------------------------------------------------------------------
function TFontGroup.GetCount(): Integer;
begin
 Result:= Length(Elements);
end;

//---------------------------------------------------------------------------
function TFontGroup.GetItem(Num: Integer): TFontDesc;
begin
 if (Num >= 0)and(Num < Length(Elements)) then
  Result:= Elements[Num] else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TFontGroup.Clear();
var
 i: Integer;
begin
 for i:= Length(Elements) - 1 downto 0 do
  if (Assigned(Elements[i])) then FreeAndNil(Elements[i]);

 SetLength(Elements, 0); 
end;

//---------------------------------------------------------------------------
function TFontGroup.Find(const AFontName: StdString): TFontDesc;
var
 i: Integer;
begin
 Result:= nil;

 for i:= 0 to Length(Elements) - 1 do
  if (SameText(Elements[i].FontName, AFontName)) then
   begin
    Result:= Elements[i];
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TFontGroup.NewItem(): TFontDesc;
var
 Index: Integer;
begin
 Index:= Length(Elements);
 SetLength(Elements, Index + 1);

 Elements[Index]:= TFontDesc.Create();
 Result:= Elements[Index];
end;

//---------------------------------------------------------------------------
procedure TFontGroup.ParseXMLNode(Node: TXMLNode);
var
 Child: TXMLNode;
 Desc : TFontDesc;
begin
 FName  := Node.FieldValue['name'];
 FOption:= Node.FieldValue['option'];

 for Child in Node do
  if (SameText(Child.Name, 'font')) then
   begin
    Desc:= NewItem();
    if (Assigned(Desc)) then Desc.ParseXMLNode(Child);
   end;
end;

//---------------------------------------------------------------------------
constructor TFontGroups.Create();
begin
 inherited;

 FOption:= '';
end;

//---------------------------------------------------------------------------
destructor TFontGroups.Destroy();
begin
 Clear();

 inherited;
end;

//---------------------------------------------------------------------------
function TFontGroups.GetCount(): Integer;
begin
 Result:= Length(Groups);
end;

//---------------------------------------------------------------------------
function TFontGroups.GetItem(Num: Integer): TFontGroup;
begin
 if (Num >= 0)and(Num < Length(Groups)) then
  Result:= Groups[Num] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TFontGroups.IndexOf(const AGroupName: StdString): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Groups) - 1 do
  if (SameText(Groups[i].Name, AGroupName)) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TFontGroups.GetGroup(const AGroupName: StdString): TFontGroup;
var
 Index: Integer;
begin
 Result:= nil;
 Index := IndexOf(AGroupName);

 if (Index <> -1) then Result:= Groups[Index];
end;

//---------------------------------------------------------------------------
procedure TFontGroups.Clear();
var
 i: Integer;
begin
 for i:= 0 to Length(Groups) - 1 do
  if (Assigned(Groups[i])) then
   FreeAndNil(Groups[i]);

 SetLength(Groups, 0);
end;

//---------------------------------------------------------------------------
function TFontGroups.GetTotalElements(): Integer;
var
 i: Integer;
begin
 Result:= 0;

 for i:= 0 to Length(Groups) - 1 do
  Inc(Result, Groups[i].Count);
end;

//---------------------------------------------------------------------------
function TFontGroups.FindFont(const AFontName: StdString): TFontDesc;
var
 i: Integer;
begin
 Result:= nil;

 for i:= 0 to Length(Groups) - 1 do
  if (FOption = '')or(Groups[i].Option = '')or
   (SameText(Groups[i].Option, FOption)) then
   begin
    Result:= Groups[i].Find(AFontName);
    if (Assigned(Result)) then Break;
   end;
end;

//---------------------------------------------------------------------------
function TFontGroups.NewGroup(const AGroupName: StdString): TFontGroup;
var
 Index: Integer;
begin
 Index:= Length(Groups);
 SetLength(Groups, Index + 1);

 Groups[Index]:= TFontGroup.Create(AGroupName);
 Result:= Groups[Index];
end;

//---------------------------------------------------------------------------
procedure TFontGroups.ParseLink(const ALink: StdString);
var
 Root : TXMLNode;
 Child: TXMLNode;
 GroupItem: TFontGroup;
 Name : StdString;
begin
 Root:= LoadLinkXML(ALink);
 if (not Assigned(Root)) then Exit;

 for Child in Root do
  begin
   // -> "font-group" node
   if (SameText(Child.Name, 'font-group')) then
    begin
     Name:= Child.FieldValue['name'];

     if (Length(Name) > 0) then
      begin
       GroupItem:= GetGroup(Name);
       if (not Assigned(GroupItem)) then GroupItem:= NewGroup(Name);

       GroupItem.ParseXMLNode(Child);
      end;
    end;

   // -> "resource" node
   if (SameText(Child.Name, 'resource')) then
    begin
     Name:= Child.FieldValue['source'];
     if (Length(Name) > 0) then ParseLink(Name);
    end;
  end;

 FreeAndNil(Root);
end;

//---------------------------------------------------------------------------
procedure TFontGroups.ParseFolder(Link: StdString);
var
 Path : StdString;
 Rec  : TSearchRec;
 Found: Boolean;
begin
 if (Length(Link) < 1)or(Link[Length(Link)] <> '\') then
  Link:= Link + '\';

 Path:= ExtractArchiveName(Link);

 if (Length(Path) > 0)and(Path[Length(Path)] <> '\') then
  Path:= Path + '\';

 if (FindFirst(Path + '*.xml', faReadOnly or faArchive, Rec) <> 0) then
  begin
   FindClose(Rec);
   Exit;
  end;

 repeat
  ParseLink(Link + Rec.Name);
  Found:= FindNext(Rec) = 0;
 until (not Found);

 FindClose(Rec);
end;

//---------------------------------------------------------------------------
initialization
 FontGroups:= TFontGroups.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(FontGroups);

//---------------------------------------------------------------------------
end.
