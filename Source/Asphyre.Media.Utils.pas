unit Asphyre.Media.Utils;
//---------------------------------------------------------------------------
// Utility routines for handling media files.
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
 Asphyre.TypeDef, Asphyre.XML;

//---------------------------------------------------------------------------
// IsArchiveLink()
//
// Validates if the specified link points to Archive.
// Example:
//   \data\media\map.zip | test.image
//
// Alternatively, supports file name aliases (see Asphyre.Strings.Aliases.pas)
//---------------------------------------------------------------------------
function IsArchiveLink(const Text: StdString): Boolean;

//---------------------------------------------------------------------------
// ExtractArchiveName()
//
// Generates a valid archive file name with full path from the archive link.
//---------------------------------------------------------------------------
function ExtractArchiveName(const Text: StdString): StdString;

//---------------------------------------------------------------------------
// ExtractArchiveKey()
//
// Generates a valid key from the archive link.
//---------------------------------------------------------------------------
function ExtractArchiveKey(const Text: StdString): StdString;

//---------------------------------------------------------------------------
// ExtractPipedName()
//
// Extracts all paths from the specified piped link leaving only the name.
//---------------------------------------------------------------------------
function ExtractPipedName(const Text: StdString): StdString;

//---------------------------------------------------------------------------
// MakeValidPath()
//
// Assures that the specified path ends with "\", so a file name can be
// added to it.
//---------------------------------------------------------------------------
function MakeValidPath(const Path: StdString): StdString;

//---------------------------------------------------------------------------
// MakeValidFileName()
//
// Assures that the specified file name does not begin with "\", so a path
// can be added to it.
//---------------------------------------------------------------------------
function MakeValidFileName(const FileName: StdString): StdString;

//---------------------------------------------------------------------------
// ParseInt()
//
// Parses a signed integer value read from XML. If no AutoValue is provided,
// in case of empty or non-parseable text, -1 will be returned.
//---------------------------------------------------------------------------
function ParseInt(const Text: StdString): Integer; overload;
function ParseInt(const Text: StdString; AutoValue: Integer): Integer; overload;

//---------------------------------------------------------------------------
// ParseCardinal()
//
// Parses an unsigned integer value read from XML. If no AutoValue is provided,
// in case of empty or non-parseable text, High(Cardinal) will be returned.
//---------------------------------------------------------------------------
function ParseCardinal(const Text: StdString): Cardinal; overload;
function ParseCardinal(const Text: StdString;
 AutoValue: Cardinal): Cardinal; overload;

//---------------------------------------------------------------------------
// ParseFloat()
//
// Parses a floating-point  unsigned integer value read from XML. If no
// AutoValue is provided, in case of empty or non-parseable text,
// High(Cardinal) will be returned.
//---------------------------------------------------------------------------
function ParseFloat(const Text: StdString): Single; overload;
function ParseFloat(const Text: StdString; AutoValue: Single): Single; overload;

//---------------------------------------------------------------------------
// ParseBoolean()
//
// Parses Boolean text representation (true, false, yes, no).
//---------------------------------------------------------------------------
function ParseBoolean(const Text: StdString;
 AutoValue: Boolean): Boolean; overload;
function ParseBoolean(const Text: StdString): Boolean; overload;

//---------------------------------------------------------------------------
// ParseColor()
//
// Parses an HTML or hexadecimal color.
//  -> For HTML colors (#RRGGBB), alpha is always 255.
//  -> If no AutoValue is specified, unparseable text gives opaque white.
//---------------------------------------------------------------------------
function ParseColor(const Text: StdString): Cardinal; overload;
function ParseColor(const Text: StdString;
 AutoColor: Cardinal): Cardinal; overload;

//---------------------------------------------------------------------------
// BooleanToString()
//
// Returns StdString representation of boolean.
//---------------------------------------------------------------------------
function BooleanToString(Value: Boolean): StdString;

//---------------------------------------------------------------------------
// LoadLinkXML()
//
// Attempts to load a link pointing to XML file
//---------------------------------------------------------------------------
function LoadLinkXML(const Link: StdString): TXMLNode;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Strings.Aliases;

//---------------------------------------------------------------------------
function IsArchiveLink(const Text: StdString): Boolean;
var
 SepPos: Integer;
begin
 SepPos:= Pos('|', Text);
 Result:= (Length(Text) >= 3)and(SepPos > 1)and(SepPos < Length(Text));
end;

//---------------------------------------------------------------------------
function ExtractArchiveName(const Text: StdString): StdString;
var
 SepPos, i: Integer;
 AliasFile: StdString;
begin
 Result:= Text;

 // (1) Remove "key" part from the link.
 SepPos:= Pos('|', Text);
 if (SepPos <> 0) then
  Delete(Result, SepPos, Length(Result) + 1 - SepPos);

 // (2) Check if there is a known alias for this name.
 AliasFile:= FileAliases[Trim(Result)];
 if (AliasFile <> '') then
  begin
   Result:= AliasFile;
   Exit;
  end;

 {$ifdef Windows}
 // (3-a) Replace "/" with "\" (in case Unix-type path is specified).
 for i:= 1 to Length(Result) do
  if (Result[i] = '/') then Result[i]:= '\';
 {$else}
 // (3-b) Replace "\" with "/" (in case Windows-type path is specified).
 for i:= 1 to Length(Result) do
  if (Result[i] = '\') then Result[i]:= '/';
 {$endif}

 // (4) Trim all leading and trailing spaces.
 Result:= Trim(Result);

 // (5) Remove leading "\" or "/", if such exists.
 {$ifdef Windows}
 if (Length(Result) > 0)and(Result[1] = '\') then Delete(Result, 1, 1);
 {$else}
 if (Length(Result) > 0)and(Result[1] = '/') then Delete(Result, 1, 1);
 {$endif}

 // (6) Include program path.
 Result:= ExtractFilePath(ParamStr(0)) + Result;
end;

//---------------------------------------------------------------------------
function ExtractArchiveKey(const Text: StdString): StdString;
var
 SepPos: Integer;
begin
 Result:= Text;

 // (1) Remove "archive" part from the link.
 SepPos:= Pos('|', Text);
 if (SepPos <> 0) then Delete(Result, 1, SepPos);

 // (2) Trim all leading and trailing spaces.
 Result:= Trim(Result);
end;

//---------------------------------------------------------------------------
function ExtractPipedName(const Text: StdString): StdString;
var
 SepPos, i: Integer;
begin
 Result:= Text;

 // (1) Remove "key" part from the link.
 SepPos:= Pos('|', Text);
 if (SepPos <> 0) then
  Delete(Result, SepPos, Length(Result) + 1 - SepPos);

 // (2) Replace "/" with "\" in case of unix-type file names.
 for i:= 1 to Length(Result) do
  if (Result[i] = '/') then Result[i]:= '\';

 // (3) Trim all leading and trailing spaces.
 Result:= Trim(Result);

 // (4) Remove leading "\", if such exists.
 if (Length(Result) > 0)and(Result[1] = '\') then Delete(Result, 1, 1);
end;

//---------------------------------------------------------------------------
function MakeValidPath(const Path: StdString): StdString;
begin
 Result:= Trim(Path);

 if (Length(Result) > 0)and(Result[Length(Result)] <> '\') then
  Result:= Result + '\';
end;

//---------------------------------------------------------------------------
function MakeValidFileName(const FileName: StdString): StdString;
begin
 Result:= Trim(FileName);
 while (Length(Result) > 0)and(Result[1] = '\') do Delete(Result, 1, 1);
end;

//---------------------------------------------------------------------------
function ParseInt(const Text: StdString): Integer;
begin
 Result:= StrToIntDef(Text, -1);
end;

//---------------------------------------------------------------------------
function ParseInt(const Text: StdString; AutoValue: Integer): Integer;
begin
 Result:= StrToIntDef(Text, AutoValue);
end;

//---------------------------------------------------------------------------
function ParseCardinal(const Text: StdString): Cardinal;
begin
 Result:= Cardinal(StrToIntDef(Text, Integer(High(Cardinal))));
end;

//---------------------------------------------------------------------------
function ParseCardinal(const Text: StdString; AutoValue: Cardinal): Cardinal;
begin
 Result:= Cardinal(StrToIntDef(Text, Integer(AutoValue)));
end;

//---------------------------------------------------------------------------
function ParseBoolean(const Text: StdString; AutoValue: Boolean): Boolean;
begin
 Result:= AutoValue;

 if (SameText(Text, 'no'))or(SameText(Text, 'false')) then Result:= False;
 if (SameText(Text, 'yes'))or(SameText(Text, 'true')) then Result:= True;
end;

//---------------------------------------------------------------------------
function ParseBoolean(const Text: StdString): Boolean;
begin
 Result:= ParseBoolean(Text, False);
end;

//---------------------------------------------------------------------------
function ParseFloat(const Text: StdString): Single;
begin
 Result:= ParseFloat(Text, 0.0);
end;

//---------------------------------------------------------------------------
function ParseFloat(const Text: StdString; AutoValue: Single): Single;
var
 PrevDecimalSpeparator: Char;
begin
 {$if (defined(DelphiLegacy))}
 PrevDecimalSpeparator:= DecimalSeparator;
 DecimalSeparator:= '.';
 {$else}
 PrevDecimalSpeparator:= FormatSettings.DecimalSeparator;
 FormatSettings.DecimalSeparator:= '.';
 {$endif}

 Result:= StrToFloatDef(Text, AutoValue);

 {$if (defined(DelphiLegacy))}
 DecimalSeparator:= PrevDecimalSpeparator;
 {$else}
 FormatSettings.DecimalSeparator:= PrevDecimalSpeparator;
 {$endif}
end;

//---------------------------------------------------------------------------
function ParseColor(const Text: StdString; AutoColor: Cardinal): Cardinal;
begin
 if (SameText(Text, 'source'))or(SameText(Text, 'auto'))or
  (SameText(Text, 'none')) then
  begin
   Result:= AutoColor;
   Exit;
  end;

 Result:= $FFFFFFFF;
 if (Length(Text) < 2)or((Text[1] <> '#')and(Text[1] <> '$')) then Exit;

 if (Text[1] = '#') then
  begin
   Result:= Cardinal(StrToIntDef('$' + Copy(Text, 2, Length(Text) - 1),
    Integer(AutoColor))) or $FF000000;
  end else Result:= Cardinal(StrToIntDef(Text, Integer(AutoColor)));
end;

//---------------------------------------------------------------------------
function ParseColor(const Text: StdString): Cardinal;
begin
 Result:= ParseColor(Text, $FFFFFFFF);
end;

//---------------------------------------------------------------------------
function BooleanToString(Value: Boolean): StdString;
begin
 if (Value) then Result:= 'yes' else Result:= 'no';
end;

//---------------------------------------------------------------------------
function LoadLinkXML(const Link: StdString): TXMLNode;
begin
 if (IsArchiveLink(Link)) then
  begin
   Result:= LoadXMLFromArchive(ExtractArchiveKey(Link),
    ExtractArchiveName(Link));
  end else Result:= LoadXMLFromFile(ExtractArchiveName(Link));
end;

//---------------------------------------------------------------------------
end.
