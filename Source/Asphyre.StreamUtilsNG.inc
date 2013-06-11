//---------------------------------------------------------------------------
// StreamUtilsNG.inc
// String portion for StreamUtils.pas (for NextGen compiler).
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
procedure StreamPutShortString(const Stream: TStream; const Text: string;
 MaxCount: Integer = 0);

//---------------------------------------------------------------------------
function StreamGetShortString(const Stream: TStream): string;

//---------------------------------------------------------------------------
procedure StreamPutAnsi4String(const Stream: TStream; const Value: string);

//---------------------------------------------------------------------------
function StreamGetAnsi4String(const Stream: TStream): string;

//---------------------------------------------------------------------------
procedure StreamPutAnsiString(const Stream: TStream; const Text: string;
 MaxCount: Integer = 0);

//---------------------------------------------------------------------------
function StreamGetAnsiString(const Stream: TStream): string;

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
procedure StreamPlaceStringCodepage1(Codepage: Cardinal; 
 const Stream: TStream; const Text: string; MaxCount: Integer = 0);
var
 i, Count, NewLen: Integer;
 Buffer: TBytes;
begin
 NewLen:= LocaleCharsFromUnicode(Codepage, 0, PWideChar(Text),
  Length(Text) + 1, nil, 0, nil, nil);

 if (NewLen > 0) then
  begin
   SetLength(Buffer, NewLen);

   LocaleCharsFromUnicode(Codepage, 0, PWideChar(Text),
    Length(Text) + 1, @Buffer[0], NewLen, nil, nil);
  end;

 Count:= MinMax2(Length(Buffer) - 1, 0, 255);
 if (MaxCount > 0)and(MaxCount < 255) then Count:= Min2(Count, MaxCount);

 StreamPutByte(Stream, Count);

 for i:= 0 to Count - 1 do
  StreamPutByte(Stream, Buffer[i]);
end;

//----------------------------------------------------------------------------
function StreamRetrieveStringCodepage1(Codepage: Cardinal;
 const Stream: TStream): string;
var
 i, Count, NewLen: Integer;
 Buffer: TBytes;
begin
 Count:= StreamGetByte(Stream);

 SetLength(Buffer, Count + 1);

 for i:= 0 to Count - 1 do
  Buffer[i]:= StreamGetByte(Stream);

 Buffer[Count]:= 0;

 if (Count > 0) then
  begin
   NewLen:= UnicodeFromLocaleChars(Codepage, 0, @Buffer[0], Count + 1, nil, 0);

   if (NewLen > 1) then
    begin
     SetLength(Result, NewLen - 1);
     UnicodeFromLocaleChars(Codepage, 0, @Buffer[0], Count + 1,
      Pointer(Result), NewLen);
    end else SetLength(Result, 0);
  end else SetLength(Result, 0);
end;

//---------------------------------------------------------------------------
procedure StreamPlaceStringCodepage2(Codepage: Cardinal; 
 const Stream: TStream; const Text: string; MaxCount: Integer = 0);
var
 i, Count, NewLen: Integer;
 Buffer: TBytes;
begin
 NewLen:= LocaleCharsFromUnicode(Codepage, 0, PWideChar(Text),
  Length(Text) + 1, nil, 0, nil, nil);

 if (NewLen > 0) then
  begin
   SetLength(Buffer, NewLen);

   LocaleCharsFromUnicode(Codepage, 0, PWideChar(Text),
    Length(Text) + 1, @Buffer[0], NewLen, nil, nil);
  end;

 Count:= MinMax2(Length(Buffer) - 1, 0, 65535);
 if (MaxCount > 0)and(MaxCount < 65536) then Count:= Min2(Count, MaxCount);

 StreamPutWord(Stream, Count);

 for i:= 0 to Count - 1 do
  StreamPutByte(Stream, Buffer[i]);
end;

//----------------------------------------------------------------------------
function StreamRetrieveStringCodepage2(Codepage: Cardinal;
 const Stream: TStream): string;
var
 i, Count, NewLen: Integer;
 Buffer: TBytes;
begin
 Count:= StreamGetWord(Stream);

 SetLength(Buffer, Count + 1);

 for i:= 0 to Count - 1 do
  Buffer[i]:= StreamGetByte(Stream);

 Buffer[Count]:= 0;

 if (Count > 0) then
  begin
   NewLen:= UnicodeFromLocaleChars(Codepage, 0, @Buffer[0], Count + 1, nil, 0);

   if (NewLen > 1) then
    begin
     SetLength(Result, NewLen - 1);
     UnicodeFromLocaleChars(Codepage, 0, @Buffer[0], Count + 1,
      Pointer(Result), NewLen);
    end else SetLength(Result, 0);
  end else SetLength(Result, 0);
end;

//---------------------------------------------------------------------------
procedure StreamPlaceStringCodepage4(Codepage: Cardinal; 
 const Stream: TStream; const Text: string);
var
 i, Count, NewLen: Integer;
 Buffer: TBytes;
begin
 NewLen:= LocaleCharsFromUnicode(Codepage, 0, PWideChar(Text),
  Length(Text) + 1, nil, 0, nil, nil);

 if (NewLen > 0) then
  begin
   SetLength(Buffer, NewLen);

   LocaleCharsFromUnicode(Codepage, 0, PWideChar(Text),
    Length(Text) + 1, @Buffer[0], NewLen, nil, nil);
  end;

 Count:= Max2(Length(Buffer) - 1, 0);

 StreamPutLongInt(Stream, Count);

 for i:= 0 to Count - 1 do
  StreamPutByte(Stream, Buffer[i]);
end;

//----------------------------------------------------------------------------
function StreamRetrieveStringCodepage4(Codepage: Cardinal; 
 const Stream: TStream): string;
var
 i, Count, NewLen: Integer;
 Buffer: TBytes;
begin
 Count:= StreamGetLongInt(Stream);

 SetLength(Buffer, Count + 1);

 for i:= 0 to Count - 1 do
  Buffer[i]:= StreamGetByte(Stream);

 Buffer[Count]:= 0;

 if (Count > 0) then
  begin
   NewLen:= UnicodeFromLocaleChars(Codepage, 0, @Buffer[0], Count + 1, nil, 0);

   if (NewLen > 1) then
    begin
     SetLength(Result, NewLen - 1);
     UnicodeFromLocaleChars(Codepage, 0, @Buffer[0], Count + 1,
      Pointer(Result), NewLen);
    end else SetLength(Result, 0);
  end else SetLength(Result, 0);
end;

//---------------------------------------------------------------------------
procedure StreamPutShortString(const Stream: TStream; const Text: string;
 MaxCount: Integer = 0);
begin
 StreamPlaceStringCodepage1(DefaultSystemCodePage, Stream, Text, MaxCount);
end;

//---------------------------------------------------------------------------
function StreamGetShortString(const Stream: TStream): string;
begin
 Result:= StreamRetrieveStringCodepage1(DefaultSystemCodePage, Stream);
end;

//---------------------------------------------------------------------------
procedure StreamPutAnsi4String(const Stream: TStream; const Value: string);
begin
 StreamPlaceStringCodepage4(DefaultSystemCodePage, Stream, Value);
end;

//---------------------------------------------------------------------------
function StreamGetAnsi4String(const Stream: TStream): string;
begin
 Result:= StreamRetrieveStringCodepage4(DefaultSystemCodePage, Stream);
end;

//----------------------------------------------------------------------------
procedure StreamPutAnsiString(const Stream: TStream; const Text: string;
 MaxCount: Integer = 0);
begin
 StreamPlaceStringCodepage2(DefaultSystemCodePage, Stream, Text, MaxCount);
end;

//----------------------------------------------------------------------------
function StreamGetAnsiString(const Stream: TStream): string;
begin
 Result:= StreamRetrieveStringCodepage2(DefaultSystemCodePage, Stream);
end;

//----------------------------------------------------------------------------
procedure StreamPutUtf8String(const Stream: TStream; const Text: string;
 MaxCount: Integer = 0);
begin
 StreamPlaceStringCodepage2(CP_UTF8, Stream, Text, MaxCount);
end;

//----------------------------------------------------------------------------
function StreamGetUtf8String(const Stream: TStream): string;
begin
 Result:= StreamRetrieveStringCodepage2(CP_UTF8, Stream);
end;

//----------------------------------------------------------------------------
procedure StreamPutShortUtf8String(const Stream: TStream; const Text: string;
 MaxCount: Integer = 0);
begin
 StreamPlaceStringCodepage1(CP_UTF8, Stream, Text, MaxCount);
end;

//----------------------------------------------------------------------------
function StreamGetShortUtf8String(const Stream: TStream): string;
begin
 Result:= StreamRetrieveStringCodepage1(CP_UTF8, Stream);
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
