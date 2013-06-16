unit Asphyre.XML;
//---------------------------------------------------------------------------
// Note: This component doesn't read or write data parts of XML and is
// primarily used to read nodes and their attributes only, mainly used in
// configuration files.
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
 System.SysUtils, System.Classes,
{$else}
 SysUtils, Classes,
{$endif}
 Asphyre.TypeDef, Asphyre.Archives;

//---------------------------------------------------------------------------
type
 PXMLNodeField = ^TXMLNodeField;
 TXMLNodeField = record
  Name : StdString;
  Value: StdString;
 end;

//---------------------------------------------------------------------------
 TXMLNode = class;

//---------------------------------------------------------------------------
 TXMLNodeEnumerator = class
 private
  {$ifdef DelphiNextGen}[weak]{$endif}FNode: TXMLNode;
  Index: Integer;

  function GetCurrent(): TXMLNode;
 public
  property Current: TXMLNode read GetCurrent;

  function MoveNext(): Boolean;

  constructor Create(const Node: TXMLNode);
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TXMLNode = class
 private
  FName : StdString;
  Nodes : array of TXMLNode;
  Fields: array of TXMLNodeField;

  function GetChildCount(): Integer;
  function GetChild(Index: Integer): TXMLNode;
  function GetChildNode(const AName: StdString): TXMLNode;
  function GetFieldCount(): Integer;
  function GetField(Index: Integer): PXMLNodeField;
  function GetFieldValue(const AName: StdString): StdString;
  procedure SetFieldValue(const AName: StdString; const Value: StdString);
  function SubCode(Spacing: Integer): StdString;
 public
  property Name: StdString read FName;

  property ChildCount: Integer read GetChildCount;
  property Child[Index: Integer]: TXMLNode read GetChild;
  property ChildNode[const AName: StdString]: TXMLNode read GetChildNode;

  property FieldCount: Integer read GetFieldCount;
  property Field[Index: Integer]: PXMLNodeField read GetField;
  property FieldValue[const AName: StdString]: StdString read GetFieldValue
   write SetFieldValue;

  function AddChild(const AName: StdString): TXMLNode;
  function FindChildByName(const AName: StdString): Integer;

  function AddField(const AName: StdString;
   const Value: StdString): PXMLNodeField;
  function FindFieldByName(const AName: StdString): Integer;

  function GetCode(): StdString;

  procedure SaveToFile(const FileName: StdString);
  function SaveToStream(OutStream: TStream): Boolean;

  function SaveToArchive(const Key: UniString;
   Archive: TAsphyreArchive): Boolean; overload;
  function SaveToArchive(const Key: UniString;
   const ArchiveName: StdString): Boolean; overload;

  function GetEnumerator(): TXMLNodeEnumerator;

  constructor Create(const AName: StdString);
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
function LoadXMLFromFile(const FileName: StdString): TXMLNode;
function LoadXMLFromStream(InStream: TStream): TXMLNode;
function LoadXMLFromArchive(const Key: UniString;
 Archive: TAsphyreArchive): TXMLNode; overload;
function LoadXMLFromArchive(const Key: UniString;
 const ArchiveName: StdString): TXMLNode; overload;

//---------------------------------------------------------------------------
{$define Asphyre_Interface}
 {$ifdef DelphiNextGen}
  {$include Asphyre.XMLParserNG.inc}
 {$else}
  {$include Asphyre.XMLParser.inc}
 {$endif}
{$undef Asphyre_Interface}

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Archives.Auth;

//---------------------------------------------------------------------------
function Spaces(Count: Integer): StdString;
var
 i: Integer;
begin
 Result:= '';

 for i:= 0 to Count - 1 do
  Result:= Result + ' ';
end;

//---------------------------------------------------------------------------
constructor TXMLNode.Create(const AName: StdString);
begin
 inherited Create();

 Inc(AsphyreClassInstances);

 FName:= AName;
end;

//---------------------------------------------------------------------------
destructor TXMLNode.Destroy();
var
 i: Integer;
begin
 Dec(AsphyreClassInstances);

 for i:= Length(Nodes) - 1 downto 0 do
  if (Assigned(Nodes[i])) then FreeAndNil(Nodes[i]);

 SetLength(Nodes, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TXMLNode.GetChildCount(): Integer;
begin
 Result:= Length(Nodes);
end;

//---------------------------------------------------------------------------
function TXMLNode.GetChild(Index: Integer): TXMLNode;
begin
 if (Index >= 0)and(Index < Length(Nodes)) then
  Result:= Nodes[Index]
   else Result:= nil;
end;

//---------------------------------------------------------------------------
function TXMLNode.FindChildByName(const AName: StdString): Integer;
var
 i: Integer;
begin
 Result:= -1;
 for i:= 0 to Length(Nodes) - 1 do
  if (SameText(Nodes[i].Name, AName)) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TXMLNode.GetChildNode(const AName: StdString): TXMLNode;
var
 Index: Integer;
begin
 Index:= FindChildByName(AName);
 if (Index <> -1) then Result:= Nodes[Index]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
function TXMLNode.GetFieldCount(): Integer;
begin
 Result:= Length(Fields);
end;

//---------------------------------------------------------------------------
function TXMLNode.GetField(Index: Integer): PXMLNodeField;
begin
 if (Index >= 0)and(Index < Length(Fields)) then
  Result:= @Fields[Index]
   else Result:= nil;
end;

//---------------------------------------------------------------------------
function TXMLNode.FindFieldByName(const AName: StdString): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Fields) - 1 do
  if (SameText(Fields[i].Name, AName)) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TXMLNode.GetFieldValue(const AName: StdString): StdString;
var
 Index: Integer;
begin
 Index:= FindFieldByName(AName);

 if (Index <> -1) then
  Result:= Fields[Index].Value
   else Result:= '';
end;

//---------------------------------------------------------------------------
procedure TXMLNode.SetFieldValue(const AName: StdString;
 const Value: StdString);
var
 Index: Integer;
begin
 Index:= FindFieldByName(AName);

 if (Index <> -1) then
  Fields[Index].Value:= Value
   else AddField(AName, Value);
end;

//---------------------------------------------------------------------------
function TXMLNode.AddChild(const AName: StdString): TXMLNode;
var
 Index: Integer;
begin
 Index:= Length(Nodes);
 SetLength(Nodes, Index + 1);

 Nodes[Index]:= TXMLNode.Create(AName);
 Result:= Nodes[Index];
end;

//---------------------------------------------------------------------------
function TXMLNode.AddField(const AName: StdString;
 const Value: StdString): PXMLNodeField;
var
 Index: Integer;
begin
 Index:= Length(Fields);
 SetLength(Fields, Index + 1);

 Fields[Index].Name := AName;
 Fields[Index].Value:= Value;
 Result:= @Fields[Index];
end;

//---------------------------------------------------------------------------
function TXMLNode.SubCode(Spacing: Integer): StdString;
var
 st: StdString;
 i: Integer;
begin
 st:= Spaces(Spacing) + '<' + FName;
 if (Length(Fields) > 0) then
  begin
   st:= st + ' ';
   for i:= 0 to Length(Fields) - 1 do
    begin
     st:= st + Fields[i].Name + '="' + Fields[i].Value + '"';
     if (i < Length(Fields) - 1) then st:= st + ' ';
    end;
  end;

 if (Length(Nodes) > 0) then
  begin
   st:= st + '>'#13#10;
   for i:= 0 to Length(Nodes) - 1 do
    st:= st + Nodes[i].SubCode(Spacing + 1);
   st:= st + Spaces(Spacing) + '</' + FName + '>'#13#10; 
  end else st:= st + ' />'#13#10;

 Result:= st; 
end;

//---------------------------------------------------------------------------
function TXMLNode.GetCode(): StdString;
begin
 Result:= SubCode(0);
end;

//---------------------------------------------------------------------------
procedure TXMLNode.SaveToFile(const FileName: StdString);
var
 Strings: TStrings;
begin
 Strings:= TStringList.Create();
 Strings.Text:= GetCode();

 try
  Strings.SaveToFile(FileName);
 finally
  FreeAndNil(Strings);
 end;
end;

//---------------------------------------------------------------------------
function TXMLNode.SaveToStream(OutStream: TStream): Boolean;
var
 Strings: TStrings;
begin
 Strings:= TStringList.Create();
 Strings.Text:= GetCode();

 Result:= True;
 try
  try
   Strings.SaveToStream(OutStream);
  except
   Result:= False;
  end;
 finally
  FreeAndNil(Strings);
 end;
end;

//---------------------------------------------------------------------------
function TXMLNode.SaveToArchive(const Key: UniString;
 Archive: TAsphyreArchive): Boolean;
var
 Stream: TMemoryStream;
begin
 if (not Assigned(Archive)) then
  begin
   Result:= False;
   Exit;
  end;

 Stream:= TMemoryStream.Create();

 Result:= SaveToStream(Stream);
 if (not Result) then
  begin
   FreeAndNil(Stream);
   Exit;
  end;

 Auth.Authorize(Self, Archive);

 Result:= Archive.WriteRecord(Key, Stream.Memory, Stream.Size);

 Auth.Unauthorize();

 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
function TXMLNode.SaveToArchive(const Key: UniString;
 const ArchiveName: StdString): Boolean;
var
 Archive: TAsphyreArchive;
begin
 Archive:= TAsphyreArchive.Create();

 Result:= Archive.OpenFile(ArchiveName);
 if (not Result) then
  begin
   FreeAndNil(Archive);
   Exit;
  end;

 Result:= SaveToArchive(Key, Archive);

 FreeAndNil(Archive);
end;

//---------------------------------------------------------------------------
function TXMLNode.GetEnumerator(): TXMLNodeEnumerator;
begin
 Result:= TXMLNodeEnumerator.Create(Self);
end;

//---------------------------------------------------------------------------
constructor TXMLNodeEnumerator.Create(const Node: TXMLNode);
begin
 inherited Create();

 Inc(AsphyreClassInstances);

 FNode:= Node;
 Index:= -1;
end;

//---------------------------------------------------------------------------
destructor TXMLNodeEnumerator.Destroy();
begin
 Dec(AsphyreClassInstances);

 inherited;
end;

//---------------------------------------------------------------------------
function TXMLNodeEnumerator.GetCurrent(): TXMLNode;
begin
 Result:= FNode.Child[Index];
end;

//---------------------------------------------------------------------------
function TXMLNodeEnumerator.MoveNext(): Boolean;
begin
 Result:= Index < FNode.ChildCount - 1;
 if (Result) then Inc(Index);
end;

//--------------------------------------------------------------------------
function LoadXMLFromStream(InStream: TStream): TXMLNode;
var
 StList: TStringList;
 Text: string;
begin
 Result:= nil;

 StList:= TStringList.Create();
 try
  try
   StList.LoadFromStream(InStream);
  except
   Exit;
  end;
  Text:= StList.Text;
 finally
  FreeAndNil(StList);
 end;

 Result:= ParseXMLText(Text);
end;

//---------------------------------------------------------------------------
function LoadXMLFromFile(const FileName: StdString): TXMLNode;
var
 StList: TStringList;
 Text: string;
begin
 Result:= nil;

 StList:= TStringList.Create();
 try
  try
   StList.LoadFromFile(FileName);
  except
   Exit;
  end;

  Text:= StList.Text;
 finally
  FreeAndNil(StList);
 end;

 Result:= ParseXMLText(Text);
end;

//---------------------------------------------------------------------------
function LoadXMLFromArchive(const Key: UniString;
 Archive: TAsphyreArchive): TXMLNode; overload;
var
 Stream: TMemoryStream;
begin
 Result:= nil;
 if (not Assigned(Archive)) then Exit;

 Stream:= TMemoryStream.Create();
 try
  try
   Auth.Authorize(nil, Archive);

   if (not Archive.ReadStream(Key, Stream)) then Exit;
  finally
   Auth.Unauthorize();
  end;

  Stream.Seek(0, soFromBeginning);

  Result:= LoadXMLFromStream(Stream);
 finally
  FreeAndNil(Stream);
 end;
end;

//---------------------------------------------------------------------------
function LoadXMLFromArchive(const Key: UniString;
 const ArchiveName: StdString): TXMLNode; overload;
var
 Archive: TAsphyreArchive;
begin
 Archive:= TAsphyreArchive.Create();
 Archive.OpenMode:= aomReadOnly;

 try
  if (not Archive.OpenFile(ArchiveName)) then
   begin
    Result:= nil;
    Exit;
   end;

  Result:= LoadXMLFromArchive(Key, Archive);
 finally
  FreeAndNil(Archive);
 end;
end;

//---------------------------------------------------------------------------
{$define Asphyre_Implementation}
 {$ifdef DelphiNextGen}
  {$include Asphyre.XMLParserNG.inc}
 {$else}
  {$include Asphyre.XMLParser.inc}
 {$endif}
{$undef Asphyre_Implementation}

//---------------------------------------------------------------------------
end.
