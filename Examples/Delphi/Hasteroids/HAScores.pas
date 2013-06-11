unit HAScores;
//---------------------------------------------------------------------------
// Hasteroids - High Scores implementation v1.0
//---------------------------------------------------------------------------
// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in
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
uses
 Types, Classes, SysUtils, Asphyre.Archives, StreamUtils;

//---------------------------------------------------------------------------
type
 THighScore = class(TCollectionItem)
 private
  FScore: Integer;
  FPlayer: string;
 public
  property Player: string read FPlayer write FPlayer;
  property Score: Integer read FScore write FScore;
 end;

//---------------------------------------------------------------------------
 THighScores = class(TCollection)
 private
  function GetItem(Index: Integer): THighScore;
  procedure SetItem(Index: Integer; const Value: THighScore);
 public
  property Items[Index: Integer]: THighScore read GetItem write SetItem; default;

  function Add(): THighScore;
  function AddItem(Item: THighScore; Index: Integer): THighScore;
  function Insert(Index: Integer): THighScore;
  procedure Exchange(Item1, Item2: Integer);

  procedure Sort();

  procedure LoadFromVTDb(const Key: WideString; Archive: TAsphyreArchive);
  procedure SaveToVTDB(const Key: WideString; Archive: TAsphyreArchive);

  constructor Create();
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor THighScores.Create();
begin
 inherited Create(THighScore);
end;

//---------------------------------------------------------------------------
function THighScores.GetItem(Index: Integer): THighScore;
begin
 Result:= THighScore(inherited GetItem(Index));
end;

//---------------------------------------------------------------------------
procedure THighScores.SetItem(Index: Integer; const Value: THighScore);
begin
 inherited SetItem(Index, Value);
end;

//---------------------------------------------------------------------------
function THighScores.Add(): THighScore;
begin
 Result:= THighScore(inherited Add());
end;

//---------------------------------------------------------------------------
function THighScores.AddItem(Item: THighScore; Index: Integer): THighScore;
begin
 if (Item = nil) then Result:= THighScore.Create(Self)
  else Result:= Item;

 if (Assigned(Result)) then
  begin
   Result.Collection:= Self;
   if (Index < 0) then Index:= Count - 1;
   Result.Index:= Index;
  end;
end;

//---------------------------------------------------------------------------
function THighScores.Insert(Index: Integer): THighScore;
begin
 Result:= AddItem(nil, Index);
end;

//---------------------------------------------------------------------------
procedure THighScores.Exchange(Item1, Item2: Integer);
var
 Aux: THighScore;
begin
 Aux:= Items[Item1];
 Items[Item1]:= Items[Item2];
 Items[Item2]:= Aux;
end;

//---------------------------------------------------------------------------
procedure THighScores.Sort();
var
 i, j: Integer;
begin
// Simple Bubble-sort
 for j:= 0 to Count - 1 do
  for i:= 0 to Count - 2 do
   if (Items[i].Score < Items[i + 1].Score) then
    Items[i].Index:= Items[i].Index + 1;
end;

//---------------------------------------------------------------------------
procedure THighScores.LoadFromVTDb(const Key: WideString;
 Archive: TAsphyreArchive);
var
 Stream: TStream;
 ItemCount, i: Integer;
 NewItem: THighScore;
begin
 Clear();

 Stream:= TMemoryStream.Create();

 // attempt to read from vtdb archive
 if (not Archive.ReadStream(Key, Stream)) then
  begin
   Stream.Free();
   Exit;
  end;

 Stream.Seek(0, soFromBeginning);
 try
  // retreive item count
  ItemCount:= StreamGetLongint(Stream);

  // retreive individual items
  for i:= 0 to ItemCount - 1 do
   begin
    NewItem:= Add();
    NewItem.Player:= StreamGetAnsi4String(Stream);
    NewItem.Score:= StreamGetLongInt(Stream);
   end;
 except
 end;

 Stream.Free();
 Sort();
end;

//---------------------------------------------------------------------------
procedure THighScores.SaveToVTDB(const Key: WideString;
 Archive: TAsphyreArchive);
var
 Stream: TStream;
 i: Integer;
begin
 Stream:= TMemoryStream.Create();

 // item count
 StreamPutLongint(Stream, Count);

 // individual items
 for i:= 0 to Count - 1 do
  begin
   StreamPutAnsi4String(Stream, Items[i].Player);
   StreamPutLongint(Stream, Items[i].Score);
  end;

 // save to vtdb archive
 Stream.Seek(0, soFromBeginning);
 Archive.WriteStream(Key, Stream);

 // release the stream
 Stream.Free();
end;

//---------------------------------------------------------------------------
end.
