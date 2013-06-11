//---------------------------------------------------------------------------
// XMLParserNG.inc
// Minimalistic Asphyre XML parser.
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

{$ifdef Asphyre_Interface}

//---------------------------------------------------------------------------
function ParseXMLText(const Text: StdString): TXMLNode;

//---------------------------------------------------------------------------
function GetXMLParseError(): Integer;

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
const
 XWhiteSpace = [#0, #9, #10, #13, #32];
 XQuotes = ['"', ''''];
 XSeparators = ['+', '-', '=', '<', '>', '(', ')', '[', ']', '"', '''', ',',
  '.', '/', '\', ':', ';', '*', '#', '&', '@', '$', '%', '^', '?', '!'];

//---------------------------------------------------------------------------
 XParsingOkay = 0;
 XIncompleteAttribute = -1;
 XInvalidNodeDeclaration = -2;
 XInvalidDocumentSymbol = -3;
 XInvalidClosingTagName = -4;
 XInvalidClosingTagSyntax = -5;
 XNodeHasNotBeenClosed = -6;

//---------------------------------------------------------------------------
var
 CurrentParseStatus: Integer = 0;

//---------------------------------------------------------------------------
function IsNameCharacter(ScanCh: Char): Boolean;
begin
 Result:= (not (ScanCh in XWhiteSpace))and(not (ScanCh in XSeparators));
end;

//---------------------------------------------------------------------------
procedure SkipBlankSpace(const Text: StdString; var TextPos: Integer);
begin
 while (TextPos < Text.Length)and(Text.Chars[TextPos] in XWhiteSpace) do
  Inc(TextPos);
end;

//---------------------------------------------------------------------------
function HasTextPortion(const Text: StdString; TextPos: Integer;
 SubText: StdString): Boolean;
var
 TestText: StdString;
begin
 if (Text.Length - TextPos < SubText.Length) then
  begin
   Result:= False;
   Exit;
  end;

 TestText:= Text.Substring(TextPos, SubText.Length);

 Result:= SameText(TestText, SubText);
end;

//---------------------------------------------------------------------------
procedure ScanAfterPortion(const Text: StdString; var TextPos: Integer;
 const SubText: StdString);
begin
 while (TextPos < Text.Length) do
  begin
   if (HasTextPortion(Text, TextPos, SubText)) then
    begin
     Inc(TextPos, SubText.Length);
     Break;
    end;

   Inc(TextPos);
  end;
end;

//---------------------------------------------------------------------------
procedure ScanAfterChar(const Text: StdString; var TextPos: Integer;
 ScanCh: Char);
begin
 while (TextPos < Text.Length) do
  begin
   if (Text.Chars[TextPos] = ScanCh) then
    begin
     Inc(TextPos);
     Break;
    end;

   Inc(TextPos);
  end;
end;

//---------------------------------------------------------------------------
function ScanForName(const Text: StdString; var TextPos: Integer): StdString;
var
 StartPos, CopyLen: Integer;
begin
 Result:= '';

 SkipBlankSpace(Text, TextPos);

 if (TextPos >= Text.Length)or(Text.Chars[TextPos] in XSeparators) then Exit;

 StartPos:= TextPos;
 CopyLen := 0;

 while (TextPos < Text.Length) do
  begin
   if (not IsNameCharacter(Text.Chars[TextPos])) then Break;

   Inc(CopyLen);
   Inc(TextPos);
  end;

 Result:= Text.Substring(StartPos, CopyLen);
end;

//---------------------------------------------------------------------------
function ScanForTextValue(const Text: StdString;
 var TextPos: Integer): StdString;
var
 StartPos, CopyLen: Integer;
 QuoteCh: Char;
begin
 Result:= '';

 SkipBlankSpace(Text, TextPos);

 if (TextPos >= Text.Length)or((Text.Chars[TextPos] in XSeparators)and
  (not (Text.Chars[TextPos] in XQuotes))) then Exit;

 // Opening quote?
 if (Text.Chars[TextPos] in XQuotes) then
  begin
   QuoteCh:= Text.Chars[TextPos];
   Inc(TextPos);
  end else QuoteCh:= #0;

 StartPos:= TextPos;
 CopyLen := 0;

 while (TextPos < Text.Length) do
  begin
   // Closing quote.
   if (QuoteCh <> #0)and(Text.Chars[TextPos] = QuoteCh) then
    begin
     Inc(TextPos);
     Break;
    end;

   if (QuoteCh = #0)and(not IsNameCharacter(Text.Chars[TextPos])) then
    Break;

   Inc(CopyLen);
   Inc(TextPos);
  end;

 Result:= Text.Substring(StartPos, CopyLen);
end;

//---------------------------------------------------------------------------
procedure ParseXMLField(const Node: TXMLNode; const Text: StdString;
 var TextPos: Integer);
var
 FieldName, FieldValue: StdString;
begin
 FieldName:= ScanForName(Text, TextPos);

 // Skip any blank space.
 SkipBlankSpace(Text, TextPos);

 // Abrupt end of text?
 if (TextPos >= Text.Length) then
  begin
   if (FieldName.Length > 0) then
    Node.AddField(FieldName, '');

   CurrentParseStatus:= XIncompleteAttribute;
   Exit;
  end;

 // Field has no value.
 if (Text.Chars[TextPos] <> '=') then
  begin
   if (FieldName.Length > 0) then
    Node.AddField(FieldName, '');

   Exit;
  end;

 // Parse field value (skip "=" symbol).
 Inc(TextPos);
 FieldValue:= ScanForTextValue(Text, TextPos);

 if (FieldName.Length > 0) then
  Node.AddField(FieldName, FieldValue);
end;

//---------------------------------------------------------------------------
function ParseXMLNode(const Root: TXMLNode; const Text: StdString;
 var TextPos: Integer; const ShowRefCount: Boolean = False): TXMLNode;
var
 NodeName: StdString;
begin
 // Process node name.
 NodeName:= ScanForName(Text, TextPos);

 if (Assigned(Root)) then
  Result:= Root.AddChild(NodeName)
   else Result:= TXMLNode.Create(NodeName);

 // Processing after [<NODE]...
 while (TextPos < Text.Length) do
  begin
   // Skip any blank space.
   SkipBlankSpace(Text, TextPos);
   if (TextPos >= Text.Length) then Break;

   // Skip "<!-- ... -->" comments inside node (is this allowed?)
   if (HasTextPortion(Text, TextPos, '<!--')) then
    begin
     Inc(TextPos, 4);
     ScanAfterPortion(Text, TextPos, '-->');
     Continue;
    end;

   // Full end of node.
   if (HasTextPortion(Text, TextPos, '/>')) then
    begin
     Inc(TextPos, 2);
     Exit;
    end;

   // End of node, need to parse the second part.
   if (Text.Chars[TextPos] = '>') then
    begin
     Inc(TextPos);
     Break;
    end;

   // Attribute.
   if (IsNameCharacter(Text.Chars[TextPos])) then
    begin
     ParseXMLField(Result, Text, TextPos);
     Continue;
    end;

   CurrentParseStatus:= XInvalidNodeDeclaration;
   Exit;
  end;

 // Processing after [<NODE>]...
 while (TextPos < Text.Length) do
  begin
   // Skip any blank space.
   SkipBlankSpace(Text, TextPos);
   if (TextPos >= Text.Length) then Break;

   // Skip "<!-- ... -->" comments.
   if (HasTextPortion(Text, TextPos, '<!--')) then
    begin
     Inc(TextPos, 4);
     ScanAfterPortion(Text, TextPos, '-->');
     Continue;
    end;

   // Skip "<? ... ?>" tags.
   if (HasTextPortion(Text, TextPos, '<?')) then
    begin
     Inc(TextPos, 2);
     ScanAfterPortion(Text, TextPos, '?>');
     Continue;
    end;

   // Skip "<!doctype >" tags.
   if (HasTextPortion(Text, TextPos, '<!doctype')) then
    begin
     Inc(TextPos, 9);
     ScanAfterChar(Text, TextPos, '>');
     Continue;
    end;

   // End of node "</NODE>"
   if (HasTextPortion(Text, TextPos, '</')) then
    begin
     Inc(TextPos, 2);

     NodeName:= ScanForName(Text, TextPos);
     if (not SameText(NodeName, Result.Name)) then
      begin
       CurrentParseStatus:= XInvalidClosingTagName;
       Exit;
      end;

     SkipBlankSpace(Text, TextPos);
     if (TextPos >= Text.Length)or(Text.Chars[TextPos] <> '>') then
      begin
       CurrentParseStatus:= XInvalidClosingTagSyntax;
       Exit;
      end;

     Inc(TextPos);
     Exit;
    end;

   // Start of child node.
   if (Text.Chars[TextPos] = '<') then
    begin
     Inc(TextPos);

     ParseXMLNode(Result, Text, TextPos);
     Continue;
    end;

   // Skip text inside the node.
   Inc(TextPos);
  end;

 if (TextPos >= Text.Length) then
  CurrentParseStatus:= XNodeHasNotBeenClosed;
end;

//---------------------------------------------------------------------------
function ParseXMLText(const Text: StdString): TXMLNode;
var
 TextPos: Integer;
begin
 Result:= nil;
 if (Text.Length < 1) then Exit;

 TextPos:= 0;
 CurrentParseStatus:= XParsingOkay;

 while (TextPos < Text.Length) do
  begin
   // Skip any blank space.
   SkipBlankSpace(Text, TextPos);
   if (TextPos >= Text.Length) then Break;

   // Skip "<!-- ... -->" comments.
   if (HasTextPortion(Text, TextPos, '<!--')) then
    begin
     Inc(TextPos, 4);
     ScanAfterPortion(Text, TextPos, '-->');
     Continue;
    end;

   // Skip "<? ... ?>" tags.
   if (HasTextPortion(Text, TextPos, '<?')) then
    begin
     Inc(TextPos, 2);
     ScanAfterPortion(Text, TextPos, '?>');
     Continue;
    end;

   // Skip "<!doctype >" tags.
   if (HasTextPortion(Text, TextPos, '<!doctype')) then
    begin
     Inc(TextPos, 9);
     ScanAfterChar(Text, TextPos, '>');
     Continue;
    end;

   // Start of node.
   if (Text.Chars[TextPos] = '<') then
    begin
     Inc(TextPos);

     Result:= ParseXMLNode(nil, Text, TextPos, True);
     Break;
    end;

   // Invalid text character.
   CurrentParseStatus:= XInvalidDocumentSymbol;
   Break;
  end;

 if (CurrentParseStatus <> XParsingOkay) then
  if (Assigned(Result)) then FreeAndNil(Result);
end;

//---------------------------------------------------------------------------
function GetXMLParseError(): Integer;
begin
 Result:= CurrentParseStatus;
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
