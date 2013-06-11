unit Asphyre.Media.Images;
//---------------------------------------------------------------------------
// Resource management utility for Asphyre images.
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
 System.Types, System.SysUtils, Asphyre.Math, Asphyre.TypeDef, Asphyre.Types, 
 Asphyre.XML, Asphyre.Media.Utils;

//---------------------------------------------------------------------------
type
 PImageDesc = ^TImageDesc;
 TImageDesc = record
  Name        : StdString;           // unique image identifier
  Format      : TAsphyrePixelFormat; // preferred pixel format
  MipMapping  : Boolean;             // whether to enable mipmapping
  PatternSize : TPoint2px;           // pattern size
  PatternCount: Integer;             // number of patterns
  VisibleSize : TPoint2px;           // visible size
  MediaLink   : StdString;           // link to image media
 end;

//---------------------------------------------------------------------------
 TImageGroup = class
 private
  Elements: array of TImageDesc;

  FName  : StdString;
  FOption: StdString;

  function GetCount(): Integer;
  function GetItem(Index: Integer): PImageDesc;
  function NewItem(): PImageDesc;
  procedure ParseItem(Node: TXMLNode);
 public
  property Name  : StdString read FName;
  property Option: StdString read FOption;

  property Count: Integer read GetCount;
  property Item[Index: Integer]: PImageDesc read GetItem; default;

  function Find(const AName: StdString): PImageDesc;
  procedure ParseXML(Node: TXMLNode);

  constructor Create(const AName: StdString);
 end;

//---------------------------------------------------------------------------
 TImageGroups = class
 private
  Groups : array of TImageGroup;
  FOption: StdString;

  function GetCount(): Integer;
  function GetItem(Index: Integer): TImageGroup;
  function GetGroup(const AName: StdString): TImageGroup;
  function NewGroup(const AName: StdString): TImageGroup;
  function GetTotalElements(): Integer;
 public
  property Count: Integer read GetCount;
  property Item[Index: Integer]: TImageGroup read GetItem;
  property Group[const AName: StdString]: TImageGroup read GetGroup;

  property Option: StdString read FOption write FOption;

  property TotalElements: Integer read GetTotalElements;

  function IndexOf(const AName: StdString): Integer;
  procedure Clear();

  function Find(const AName: StdString): PImageDesc;
  procedure ParseLink(const Link: StdString);
  procedure ParseFolder(Link: StdString);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
 ImageGroups: TImageGroups = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Formats;

//---------------------------------------------------------------------------
constructor TImageGroup.Create(const AName: StdString);
begin
 inherited Create();

 FName:= AName;
end;

//---------------------------------------------------------------------------
function TImageGroup.GetCount(): Integer;
begin
 Result:= Length(Elements);
end;

//---------------------------------------------------------------------------
function TImageGroup.GetItem(Index: Integer): PImageDesc;
begin
 if (Index >= 0)and(Index < Length(Elements)) then
  Result:= @Elements[Index] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TImageGroup.Find(const AName: StdString): PImageDesc;
var
 i: Integer;
begin
 Result:= nil;

 for i:= 0 to Length(Elements) - 1 do
  if (SameText(Elements[i].Name, AName)) then
   begin
    Result:= @Elements[i];
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TImageGroup.NewItem(): PImageDesc;
var
 Index: Integer;
begin
 Index:= Length(Elements);
 SetLength(Elements, Index + 1);

 FillChar(Elements[Index], SizeOf(TImageDesc), 0);

 Elements[Index].Format      := apf_Unknown;
 Elements[Index].MipMapping  := False;
 Elements[Index].PatternCount:= 0;

 Result:= @Elements[Index];
end;

//---------------------------------------------------------------------------
procedure TImageGroup.ParseItem(Node: TXMLNode);
var
 Desc: PImageDesc;
 Aux : TXMLNode;
begin
 // -> node "image"
 if (not SameText(Node.Name, 'image')) then Exit;

 // -> attributes "name" and "link"
 Desc:= NewItem();
 Desc.Name     := Node.FieldValue['name'];
 Desc.MediaLink:= Node.FieldValue['link'];

 // -> "format" node
 Aux:= Node.ChildNode['format'];
 if (Assigned(Aux)) then
  begin
   Desc.Format    := StrToFormat(Aux.FieldValue['type']);
   Desc.MipMapping:= ParseBoolean(Aux.FieldValue['mipmapping'], False);
  end;

 // -> "pattern" node
 Aux:= Node.ChildNode['pattern'];
 if (Assigned(Aux)) then
  begin
   Desc.PatternSize.x:= ParseInt(Aux.FieldValue['width'], 0);
   Desc.PatternSize.y:= ParseInt(Aux.FieldValue['height'], 0);
   Desc.PatternCount := ParseInt(Aux.FieldValue['count'], 1);
   Desc.VisibleSize.x:= ParseInt(Aux.FieldValue['viewx'], 0);
   Desc.VisibleSize.y:= ParseInt(Aux.FieldValue['viewy'], 0);
  end;
end;

//---------------------------------------------------------------------------
procedure TImageGroup.ParseXML(Node: TXMLNode);
var
 i: Integer;
begin
 if (not SameText(Node.Name, 'image-group')) then Exit;

 FName  := Node.FieldValue['name'];
 FOption:= Node.FieldValue['option'];

 for i:= 0 to Node.ChildCount - 1 do
  ParseItem(Node.Child[i]);
end;

//---------------------------------------------------------------------------
constructor TImageGroups.Create();
begin
 inherited;

 FOption:= '';
end;

//---------------------------------------------------------------------------
destructor TImageGroups.Destroy();
begin
 Clear();

 inherited;
end;

//---------------------------------------------------------------------------
function TImageGroups.GetCount(): Integer;
begin
 Result:= Length(Groups);
end;

//---------------------------------------------------------------------------
function TImageGroups.GetItem(Index: Integer): TImageGroup;
begin
 if (Index >= 0)and(Index < Length(Groups)) then
  Result:= Groups[Index] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TImageGroups.IndexOf(const AName: StdString): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Groups) - 1 do
  if (SameText(Groups[i].Name, AName)) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TImageGroups.GetGroup(const AName: StdString): TImageGroup;
var
 Index: Integer;
begin
 Result:= nil;
 Index := IndexOf(AName);

 if (Index <> -1) then Result:= Groups[Index];
end;

//---------------------------------------------------------------------------
procedure TImageGroups.Clear();
var
 i: Integer;
begin
 for i:= 0 to Length(Groups) - 1 do
  if (Assigned(Groups[i])) then FreeAndNil(Groups[i]);

 SetLength(Groups, 0);
end;

//---------------------------------------------------------------------------
function TImageGroups.GetTotalElements(): Integer;
var
 i: Integer;
begin
 Result:= 0;

 for i:= 0 to Length(Groups) - 1 do
  Inc(Result, Groups[i].Count);
end;

//---------------------------------------------------------------------------
function TImageGroups.Find(const AName: StdString): PImageDesc;
var
 i: Integer;
begin
 Result:= nil;

 for i:= 0 to Length(Groups) - 1 do
  if (FOption = '')or(Groups[i].Option = '')or
   (SameText(Groups[i].Option, FOption)) then
   begin
    Result:= Groups[i].Find(AName);
    if (Assigned(Result)) then Break;
   end;
end;

//---------------------------------------------------------------------------
function TImageGroups.NewGroup(const AName: StdString): TImageGroup;
var
 Index: Integer;
begin
 Index:= Length(Groups);
 SetLength(Groups, Index + 1);

 Groups[Index]:= TImageGroup.Create(AName);
 Result:= Groups[Index];
end;

//---------------------------------------------------------------------------
procedure TImageGroups.ParseLink(const Link: StdString);
var
 Root : TXMLNode;
 Child: TXMLNode;
 Name : StdString;
 GroupItem: TImageGroup;
begin
 Root:= LoadLinkXML(Link);
 if (not Assigned(Root)) then Exit;

 for Child in Root do
  begin
   // -> "image-group" node
   if (SameText(Child.Name, 'image-group')) then
    begin
     Name:= Child.FieldValue['name'];
     if (Length(Name) > 0) then
      begin
       GroupItem:= GetGroup(Name);
       if (not Assigned(GroupItem)) then GroupItem:= NewGroup(Name);

       GroupItem.ParseXML(Child);
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
procedure TImageGroups.ParseFolder(Link: StdString);
var
 Rec  : TSearchRec;
 Path : StdString;
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
 ImageGroups:= TImageGroups.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(ImageGroups);

//---------------------------------------------------------------------------
end.
