//---------------------------------------------------------------------------
// StreamUtils.inc
// String portion for StreamUtils.pas.
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
// Note: this file has been preformatted to be used with PasDoc.
//---------------------------------------------------------------------------

{$ifdef Asphyre_Interface}

//---------------------------------------------------------------------------
{ Saves @bold(ShortString) to the stream. If @italic(MaxCount) is not zero,
  the string will be limited to a certain number of characters. }
procedure StreamPutShortString(const Stream: TStream;
 const Text: ShortString; MaxCount: Integer = 0);

//---------------------------------------------------------------------------
{ Loads @bold(ShortString) from the stream. }
function StreamGetShortString(const Stream: TStream): ShortString;

//---------------------------------------------------------------------------
{ Saves @bold(AnsiString) (non-unicode, ansi) to the stream. No restrictions
  are applied to the string, so up to 2 Gb of data can be saved this way.
  This is most useful when the string contains binary data or very long
  text. For a more restricted and limited approach, use
  @link(StreamPutAnsiString). }
procedure StreamPutAnsi4String(const Stream: TStream; const Value: AnsiString);

//---------------------------------------------------------------------------
{ Loads @bold(AnsiString) (non-unicode, ansi) from the stream previously saved
  by @link(StreamPutAnsi4String). }
function StreamGetAnsi4String(const Stream: TStream): AnsiString;

//---------------------------------------------------------------------------
{ Saves @bold(AnsiString) (non-unicode, ansi) to the stream. The string is
  limited to a maximum of 65535 characters. If @italic(MaxCount) is not zero,
  the string will be limited to the given number of characters. }
procedure StreamPutAnsiString(const Stream: TStream; const Text: AnsiString;
 MaxCount: Integer = 0);

//---------------------------------------------------------------------------
{ Loads @bold(AnsiString) (non-unicode, ansi) from the stream previously saved
  by @link(StreamPutAnsiString). The returned string can contain up to 65535
  characters. }
function StreamGetAnsiString(const Stream: TStream): AnsiString;

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
procedure StreamPutShortString(const Stream: TStream; const Text: ShortString;
 MaxCount: Integer = 0);
var
 i, Count: Integer;
begin
 Count:= Length(Text);
 if (MaxCount > 0)and(MaxCount < 255) then Count:= Min2(Count, MaxCount);

 StreamPutByte(Stream, Count);

 for i:= 0 to Count - 1 do
  StreamPutByte(Stream, Byte(Text[i + 1]));
end;

//---------------------------------------------------------------------------
function StreamGetShortString(const Stream: TStream): ShortString;
var
 Count, i: Integer;
begin
 Count:= StreamGetByte(Stream);
 SetLength(Result, Count);

 for i:= 0 to Count - 1 do
  Result[i + 1]:= AnsiChar(StreamGetByte(Stream));
end;

//---------------------------------------------------------------------------
procedure StreamPutAnsi4String(const Stream: TStream;
 const Value: AnsiString);
var
 i: Integer;
begin
 StreamPutLongInt(Stream, Length(Value));

 for i:= 0 to Length(Value) - 1 do
  StreamPutByte(Stream, Byte(Value[i + 1]));
end;

//---------------------------------------------------------------------------
function StreamGetAnsi4String(const Stream: TStream): AnsiString;
var
 Count, i: Integer;
begin
 Count:= StreamGetLongInt(Stream);
 SetLength(Result, Count);

 for i:= 0 to Count - 1 do
  Result[i + 1]:= AnsiChar(StreamGetByte(Stream));
end;

//----------------------------------------------------------------------------
procedure StreamPutAnsiString(const Stream: TStream; const Text: AnsiString;
 MaxCount: Integer = 0);
var
 i, Count: Integer;
begin
 Count:= Min2(Length(Text), 65535);
 if (MaxCount > 0)and(MaxCount < 65535) then Count:= Min2(Count, MaxCount);

 StreamPutWord(Stream, Count);

 for i:= 0 to Count - 1 do
  StreamPutByte(Stream, Byte(Text[i + 1]));
end;

//----------------------------------------------------------------------------
function StreamGetAnsiString(const Stream: TStream): AnsiString;
var
 Count, i: Integer;
begin
 Count:= StreamGetWord(Stream);
 SetLength(Result, Count);

 for i:= 0 to Count - 1 do
  Result[i + 1]:= AnsiChar(StreamGetByte(Stream));
end;

//----------------------------------------------------------------------------
procedure StreamPutUtf8String(const Stream: TStream; const Text: UniString;
 MaxCount: Integer = 0);
var
 i, Count: Integer;
 ShText: AnsiString;
begin
 ShText:= UTF8Encode(Text);

 Count:= Min2(Length(ShText), 65535);
 if (MaxCount > 0)and(MaxCount < 65535) then Count:= Min2(Count, MaxCount);

 StreamPutWord(Stream, Count);

 for i:= 0 to Count - 1 do
  StreamPutByte(Stream, Byte(ShText[i + 1]));
end;

//----------------------------------------------------------------------------
function StreamGetUtf8String(const Stream: TStream): UniString;
var
 Count, i: Integer;
 ShText: AnsiString;
begin
 Count:= StreamGetWord(Stream);

 SetLength(ShText, Count);

 for i:= 0 to Count - 1 do
  ShText[i + 1]:= AnsiChar(StreamGetByte(Stream));

 {$if (defined(fpc))or(defined(DelphiLegacy))}
 Result:= UTF8Decode(ShText);
 {$else}
 Result:= UTF8ToWideString(ShText);
 {$ifend}
end;

//----------------------------------------------------------------------------
procedure StreamPutShortUtf8String(const Stream: TStream;
 const Text: UniString; MaxCount: Integer = 0);
var
 i, Count: Integer;
 ShText: AnsiString;
begin
 ShText:= UTF8Encode(Text);

 Count:= Min2(Length(ShText), 255);
 if (MaxCount > 0)and(MaxCount < 255) then Count:= Min2(Count, MaxCount);

 StreamPutByte(Stream, Count);

 for i:= 0 to Count - 1 do
  StreamPutByte(Stream, Byte(ShText[i + 1]));
end;

//----------------------------------------------------------------------------
function StreamGetShortUtf8String(const Stream: TStream): UniString;
var
 Count, i: Integer;
 ShText: AnsiString;
begin
 Count:= StreamGetByte(Stream);

 SetLength(ShText, Count);

 for i:= 0 to Count - 1 do
  ShText[i + 1]:= AnsiChar(StreamGetByte(Stream));

 {$if (defined(fpc))or(defined(DelphiLegacy))}
 Result:= UTF8Decode(ShText);
 {$else}
 Result:= UTF8ToWideString(ShText);
 {$ifend}
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
