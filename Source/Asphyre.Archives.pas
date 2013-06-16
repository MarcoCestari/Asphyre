unit Asphyre.Archives;
//---------------------------------------------------------------------------
// Archive format for storing compressed data and images.
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
{< Asphyre Archive format with its functions and utilities that can be used
   for storing images, textures, and application's data. The information is
   compressed to save disk space and optionally encrypted to ensure
   confidentiality and protect the contents from unauthorized usage. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
{$ifdef Windows}
 {$ifdef Delphi}
 Winapi.Windows,
 {$endif}
{$endif}

{$ifndef fpc}
 System.Types, System.SysUtils, System.Classes, System.Math,
{$else}
 Types, SysUtils, Classes, Math,
{$endif}
 Asphyre.TypeDef;

//---------------------------------------------------------------------------
{
 Archive Header structure:
  Signature     - longword ('ASVF' = $46565341)
  Record Count  - longint
  Table Offset  - int64

 Archive Table structure:
  Key Name      - 2 bytes (length) + X bytes (UTF-8 text)
  Offset        - int64

 Archive Record structure:
  Record Type   -  byte (4 bits - record type, 4 bits - security)

  Original Size -  longword
  Physical Size -  longword
  File Date     -  double

  Checksum      -  longword (CRC32)
  Init Vector   -  int64 (optional, only if encrypted)

  DataBlock     -  N bytes (equals to Physical Size)
}

//---------------------------------------------------------------------------
type
{ Handling mode for Asphyre archives that indicates possible usage scenarios
  and limitations. }
 TArchiveOpenMode = (
  { The archive will be used both for reading and writing. @br @br }
  aomUpdate, 
  
  { The archive will be used for reading data. No modifications are
    allowed. @br @br }
  aomReadOnly,

  { The archive will be overwritten with blank new file; once this is
    accomplished, the mode will be changed to @link(aomUpdate). @br @br }
  aomOverwrite);

//---------------------------------------------------------------------------
{ Explicit type of the archive's record, which determines how the data should
  be interpreted. }
 TArchiveRecordType = (
  { The record is a file or binary data. @br @br }
  artFile,

  { The record is a native Asphyre image that has been prepared and
    pre-formatted for loading directly to hardware's memory. @br @br }
  artImage,

  { The record is a binary Asphyre font that has been optimized for
    performance and has its accompanying image data prepared to be loaded
    to hardware's memory. @br @br }
  artFont);

//---------------------------------------------------------------------------
{ File access type when handled by Asphyre, indicating how the archive's file
  name should be interpreted.  }
 TArchiveTypeAccess = (
  { The file name is a typical name as used by the underlying OS, which
    should include its full path. @br @br }
  ataAnyFile,

  { The file name is the name of resource that is integrated directly to
    the application's executable. Only the actual name will be used for
    resource name, any existing paths from the name will be stripped. @br @br }
  ataResource,

  { The file name which is distributed in the same folder as the application's
    executable or within the same bundle on Mac OS. The file name will be
    treated as regular file name with any existing paths stripped and the
    path to the executable added. @br @br }
  ataPackaged);

//---------------------------------------------------------------------------
{@exclude}
 TArchiveRecord = record
  Key       : string;    // record unique identifier
  Offset    : Int64;     // record offset in archive
  RecordType: TArchiveRecordType;  // type of the record (file, graphics, etc)
  OrigSize  : Cardinal;  // original data size
  PhysSize  : Cardinal;  // physical data size
  DateTime  : TDateTime; // record date & time
  Checksum  : Cardinal;  // CRC32 checksum
  Secure    : Boolean;   // whether record is encrypted
  InitVec   : Int64;     // the initial vector for cipher algorithm
 end;

//---------------------------------------------------------------------------
{ Asphyre archive implementation class that provides methods for reading,
  writing, deleting and renaming records in compressed (and possibly
  encrypted) archive; Zlib is used for data compression, CRC32 is used for
  data integrity checks and Asphyre's native 128-bit XTEA cipher is used for
  data encryption. @br @br Note that this implementation is not meant for
  concurrent access so modifying archives from different threads and/or
  applications simultaneously is not supported. The data can be read by
  different threads/applications only if it is not being written/updated at
  the same time and it is the application's responsibility to ensure this. }
 TAsphyreArchive = class
 private
  FOpenMode: TArchiveOpenMode;
  FFileName: string;
  FFileSize: Integer;
  FPassword: Pointer;

  Records: array of TArchiveRecord;
  TableOffset: Int64;
  FReady: Boolean;

  SearchList : array of Integer;
  SearchDirty: Boolean;

  function GetRecordCount(): Integer;
  function GetRecordKey(Index: Integer): string;
  function GetRecordPhysSize(Index: Integer): Cardinal;
  function GetRecordOrigSize(Index: Integer): Cardinal;
  function GetRecordType(Index: Integer): TArchiveRecordType;
  function GetRecordDate(Index: Integer): TDateTime;
  function GetRecordSecure(Index: Integer): Boolean;
  function GetRecordChecksum(Index: Integer): Cardinal;
  procedure SetFileName(const Value: string);

  function FixPlatformFileName(const NewFileName: string): string;
  function CreateArchiveReadStream(): TStream;

  function CreateEmptyFile(): Boolean;
  function ReadArchiveHeader(): Boolean;
  function WriteArchiveHeader(): Boolean;
  function ReadRecordTable(): Boolean;
  function WriteRecordTable(): Boolean;
  function ReadRecordHeaders(): Boolean;

  procedure InitRecordCount(NoRecords: Integer);
  function ReadFileRecords(): Boolean;
  function RefreshArchive(): Boolean;

  function CompressData(Source: Pointer; SourceSize: Integer;
   out Data: Pointer; out DataSize: Integer): Boolean;
  function DecompressData(Source: Pointer; SourceSize: Integer;
   out Data: Pointer; DataSize: Integer): Boolean;
  function DecompressToMemStream(Source: Pointer; SourceSize: Integer;
   DestStream: TMemoryStream): Boolean;

  procedure InitSearchList();
  procedure SearchListSwap(Index1, Index2: Integer);
  function SearchListCompare(Value1, Value2: Integer): Integer;
  function SearchListSplit(Start, Stop: Integer): Integer;
  procedure SearchListSort(Start, Stop: Integer);
  procedure UpdateSearchList();
 public
  { How the file should be handled and accessed. }
  property OpenMode: TArchiveOpenMode read FOpenMode write FOpenMode;

  { The file name of the archive. This can be interpreted differently
    depending how the global variable @link(ArchiveTypeAccess) is set.
    Setting this property may cause the list of records to be refreshed when
    a different file name is being set; @link(Ready) property will also be
    updated as well. For a more flexible and controlled approach, consider
    using @link(OpenFile) method instead. }
  property FileName: string read FFileName write SetFileName;

  { Indicates whether the archive with name set in @link(FileName) has been
    opened property and can be used for reading and/or writing records. }
  property Ready: Boolean read FReady;

  { Physical size of the archive on disk. }
  property FileSize: Integer read FFileSize;

  { 128-bit password that will be used for reading and writing encrypted
    records within archive. If set to @nil (by default), the data is stored
    unsecurely. Secure records require this password to be set, trying to read
    them without password will fail. The data pointed by this property should
    have 16 bytes or 128 bits, the encryption uses Asphyre's native 128-bit
    XTEA cipher. }
  property Password: Pointer read FPassword write FPassword;

  { Number of existing records in the archive. }
  property RecordCount: Integer read GetRecordCount;

  { Returns key of the record specified by the given index, which should be
    in range of [0..(RecordCount - 1)]. If the index is outside of valid range,
    empty string will be returned. }
  property RecordKey[Index: Integer]: string read GetRecordKey;

  { Returns the physical record's size on disk for the given index, which does
    not include its internal header or space used in record table. If the index
    is outside of [0..(RecordCount - 1)] range, the returned size is zero. }
  property RecordPhysSize[Index: Integer]: Cardinal read GetRecordPhysSize;

  { Returns the original (uncompressed) record's size for the given index.
    If the index is outside of [0..(RecordCount - 1)] range, the returned size
    is zero. }
  property RecordOrigSize[Index: Integer]: Cardinal read GetRecordOrigSize;

  { Returns the record type for the given index. If the index is outside of
    [0..(RecordCount - 1)] range, the returned type is @link(artFile). }
  property RecordType[Index: Integer]: TArchiveRecordType read GetRecordType;

  { Returns the record date and time for the given index. If the index is
    outside of [0..(RecordCount - 1)] range, the returned value is zero. }
  property RecordDate[Index: Integer]: TDateTime read GetRecordDate;

  { Returns whether the record at the specified index is encrypted or not.
    If the index is outside of [0..(RecordCount - 1)] range, the returned
    value is @False. }
  property RecordSecure[Index: Integer]: Boolean read GetRecordSecure;

  { Returns the record's CRC32 Checksum for the given index. If the index is
    outside of [0..(RecordCount - 1)] range, the returned value is zero. }
  property RecordChecksum[Index: Integer]: Cardinal read GetRecordChecksum;

  //.........................................................................

  { Reloads the record table for the given archive, updating the list of
    records. This can be used to ensure that the list of records is current. }
  procedure Refresh();

  { Opens the specified file and refreshes the record list. If the specified
    file is already open, this method does nothing (in this case,
    @link(Refresh) can be called to explicitly refresh the record list). }
  function OpenFile(const AFileName: string): Boolean;

  { Returns index of the record that has the specified key. If no record with
    such key exists, the returned value is -1. }
  function IndexOf(const Key: string): Integer;

  { Writes a new record with the specified key and data. If a record with the
    same name exists, it will be removed first. If the specified date/time is
    zero or no date/time is specified, the current date and time will be used
    instead. The method returns @True if the record has been written
    successfully or @False if there was a problem. }
  function WriteRecord(const Key: string; Source: Pointer;
   SourceSize: Integer; RecType: TArchiveRecordType = artFile;
   RecDate: TDateTime = 0.0): Boolean;

  { Writes a new record with the specified key from the given stream. The
    stream's current position is used and the remaining data is read;
    therefore, to use the entire stream, make sure to call
    @code(Stream.Seek(0, soFromBeginning)) first. If a record with the same
    name exists, it will be removed first. If the specified date/time is zero
    or no date/time is specified, the current date and time will be used
    instead. The method returns @True if the record has been written
    successfully or @False if there was a problem.}
  function WriteStream(const Key: string; Stream: TStream;
   RecType: TArchiveRecordType = artFile; RecDate: TDateTime = 0.0): Boolean;

  { Reads existing record with the specified key from the archive and returns
    its raw data. The memory is allocated within this method and it's the
    caller responsibility to release the memory after it is no longer being
    used by using @code(FreeNullMem(Data)). If the method succeeds, @True is
    returned; if the method fails, @False is returned, @italic(Data) is set
    to @nil and @italic(DataSize) is set to zero. }
  function ReadRecord(const Key: string; out Data: Pointer;
   out DataSize: Integer): Boolean;

  { Reads existing record from archive with the given key to the specified
    stream. If the method succeeds, @True is returned and the data block
    will be written to stream at current position. If the method fails,
    @False is returned and the stream remains unchanged. }
  function ReadStream(const Key: string; Stream: TStream): Boolean;

  { Reads existing record from archive with the given key to the specified
    "memory" stream. The difference between this method and @link(ReadStream)
    is the explicit use of @italic(TMemoryStream) making this method faster to
    execute. The entire contents of the given stream are overwritten. If the
    method succeeds, @True is returned and the specified stream will contain
    the record's data block with position set to zero. If the method fails,
    @False is returned and the stream will be empty. }
  function ReadMemStream(const Key: string;
   MemStream: TMemoryStream): Boolean;

  { Changes the name of the given record updating the record table and writing
    it to disk. The returned value is @True if the method succeeds and @False
    otherwise. }
  function RenameRecord(const Key, NewKey: string): Boolean;

  { Removes the given record from archive. The returned value is @True if the
    method succeeds and @False otherwise. }
  function RemoveRecord(const Key: string): Boolean;

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
{ Global access type for any instance of @link(TAsphyreArchive), controlling
  how the archive's file name is interpreted. }
 ArchiveTypeAccess: TArchiveTypeAccess{$ifndef PasDoc} = ataAnyFile{$endif};

{ The instance handle of the application's thread. This parameter must be
  specified when @link(ArchiveTypeAccess) is set to @link(ataResource) for
  reading data from resources. Typically, it should be set to application's
  @italic(hInstance). }
 ArchiveHInstance: SizeUInt{$ifndef PasDoc} = 0{$endif};

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Streams, Asphyre.Data;

//---------------------------------------------------------------------------
const
 // 'ASVF' asphyre secure vector file
 ArchiveSignature = $46565341;

 // The size in bytes of the archive's header.
 ArchiveHeaderSize = 16;

 // When using compression, a temporary buffer is used to store the final
 // output. Under certain circumstances, the output data size is bigger than
 // the original. For these cases, output buffer is created slightly bigger
 // than the original. The additional percentage added is specified below.
 BufferGrow    = 5; // default: 5 (in %)

 // For the same purpose as BufferGrow, this value is simply added to the
 // buffer size previously increased by BufferGrow (for very short buffers).
 BufferGrowAdd = 256; // default: 256

 // In original record position, this offset determines where record data
 // is allocated. This is used for ReadRecord method to get directly to
 // record data. Also used for removing records. The encryption initial
 // vector (see below) is added optionally for secure records.
 ArchiveDataOffset = 21;

 // The size of additional security data added to the record's header.
 RecordSecuritySize = 8;

 // Temporary archive name to be used when deleting or overwriting records.
 TempFileText = 'archive.temp.asvf';

//---------------------------------------------------------------------------
constructor TAsphyreArchive.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 FOpenMode:= aomUpdate;
 FFileName:= '';
 FFileSize:= 0;
 FPassword:= nil;

 TableOffset:= ArchiveHeaderSize;
 FReady:= False;

 SearchDirty:= False;
end;

//---------------------------------------------------------------------------
destructor TAsphyreArchive.Destroy();
begin
 Dec(AsphyreClassInstances);

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.GetRecordCount(): Integer;
begin
 Result:= Length(Records);
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.GetRecordKey(Index: Integer): string;
begin
 if (Index >= 0)and(Index < Length(Records)) then
  Result:= Records[Index].Key else Result:= '';
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.GetRecordPhysSize(Index: Integer): Cardinal;
begin
 if (Index >= 0)and(Index < Length(Records)) then
  Result:= Records[Index].PhysSize else Result:= 0;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.GetRecordOrigSize(Index: Integer): Cardinal;
begin
 if (Index >= 0)and(Index < Length(Records)) then
  Result:= Records[Index].OrigSize else Result:= 0;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.GetRecordType(Index: Integer): TArchiveRecordType;
begin
 if (Index >= 0)and(Index < Length(Records)) then
  Result:= Records[Index].RecordType else Result:= artFile;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.GetRecordDate(Index: Integer): TDateTime;
begin
 if (Index >= 0)and(Index < Length(Records)) then
  Result:= Records[Index].DateTime else Result:= 0.0;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.GetRecordSecure(Index: Integer): Boolean;
begin
 if (Index >= 0)and(Index < Length(Records)) then
  Result:= Records[Index].Secure else Result:= False;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.GetRecordChecksum(Index: Integer): Cardinal;
begin
 if (Index >= 0)and(Index < Length(Records)) then
  Result:= Records[Index].Checksum else Result:= 0;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.FixPlatformFileName(
 const NewFileName: string): string;
var
 i: Integer;
begin
 Result:= NewFileName;

 {$ifdef MsWindows}
 for i:= 1 to Length(Result) do
  if (Result[i] = '/') then Result[i]:= '\';
 {$else}
 for i:= 1 to Length(Result) do
  if (Result[i] = '\') then Result[i]:= '/';
 {$endif}
end;

//---------------------------------------------------------------------------
procedure TAsphyreArchive.SetFileName(const Value: string);
var
 PrevFileName: string;
begin
 PrevFileName:= FFileName;

 FFileName:= FixPlatformFileName(Value);

 if (not SameText(FFileName, PrevFileName)) then
  if (Length(FFileName) > 0) then
   begin
    FReady:= RefreshArchive();
    if (not FReady) then FFileName:= '';
   end else
   begin
    FFileName:= '';
    SetLength(Records, 0);

    FFileSize:= 0;
    TableOffset:= 0;
    FReady:= False;

    SearchDirty:= True;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.OpenFile(const AFileName: string): Boolean;
var
 NewFileName: string;
begin
 Result:= True;

 NewFileName:= FixPlatformFileName(AFileName);

 if (Length(NewFileName) < 1) then
  begin
   if (Length(FFileName) > 0) then
    begin
     FFileName:= '';
     SetLength(Records, 0);

     FFileSize:= 0;
     TableOffset:= 0;
     FReady:= False;

     SearchDirty:= True;
    end;

   Exit;
  end;

 if (not SameText(FFileName, NewFileName)) then
  begin
   FFileName:= NewFileName;

   FReady:= RefreshArchive();
   Result:= FReady;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.CreateEmptyFile(): Boolean;
var
 Stream: TFileStream;
begin
 if (FOpenmode = aomReadOnly)or(ArchiveTypeAccess <> ataAnyFile) then
  begin
   Result:= False;
   Exit;
  end;

 try
  Stream:= TFileStream.Create(FFileName, fmCreate or fmShareExclusive);
 except
  Result:= False;
  Exit;
 end;

 Result:= True;

 try
  // --> Signature
  StreamPutLongWord(Stream, ArchiveSignature);
  // --> Record Count
  StreamPutLongInt(Stream, 0);
  // --> Table Offset
  StreamPutInt64(Stream, ArchiveHeaderSize);
 except
  Result:= False;
 end;

 FreeAndNil(Stream);
 SetLength(Records, 0);

 if (Result) then
  begin
   FFileSize  := ArchiveHeaderSize;
   TableOffset:= ArchiveHeaderSize;

   if (FOpenMode = aomOverwrite) then FOpenMode:= aomUpdate;
  end else
  begin
   FFileSize:= 0;
   TableOffset:= 0;
  end;

 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreArchive.InitRecordCount(NoRecords: Integer);
var
 i: Integer;
begin
 SetLength(Records, NoRecords);

 for i:= 0 to Length(Records) - 1 do
  begin
   Records[i].Key     := '';
   Records[i].Offset  := 0;
   Records[i].RecordType:= artFile;
   Records[i].OrigSize:= 0;
   Records[i].PhysSize:= 0;
   Records[i].DateTime:= 0.0;
   Records[i].Checksum:= 0;
   Records[i].Secure  := False;
   Records[i].InitVec := 0;
  end;

 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.CreateArchiveReadStream(): TStream;
begin
 Result:= nil;
 if (FOpenMode = aomOverwrite) then Exit;
 if (FOpenMode = aomUpdate)and(ArchiveTypeAccess <> ataAnyFile) then Exit;

 try
  case FOpenMode of
   aomUpdate:
    Result:= TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);

   aomReadOnly:
    case ArchiveTypeAccess of
     ataAnyFile:
      Result:= TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);

     ataResource:
      Result:= TResourceStream.Create(ArchiveHInstance,
       ExtractFileName(FFileName), RT_RCDATA);

     ataPackaged:
      Result:= TFileStream.Create(ExtractFilePath(ParamStr(0)) +
       ExtractFileName(FFileName), fmOpenRead or fmShareDenyWrite);
    end;
  end;
 except
  Exit;
 end;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.ReadArchiveHeader(): Boolean;
var
 Stream   : TStream;
 FileSig  : Cardinal;
 NoRecords: Integer;
begin
 NoRecords:= 0;
 SetLength(Records, 0);

 SearchDirty:= True;

 Stream:= CreateArchiveReadStream();
 if (not Assigned(Stream)) then
  begin
   Result:= False;
   Exit;
  end;

 Result:= True;
 try
  // --> Signature
  FileSig:= StreamGetLongWord(Stream);
  if (FileSig <> ArchiveSignature) then
   begin
    FreeAndNil(Stream);
    Result:= False;
    Exit;
   end;

  // --> Record Count
  NoRecords:= StreamGetLongInt(Stream);
  // --> Table Offset
  TableOffset:= StreamGetInt64(Stream);
 except
  Result:= False;
 end;

 // The offset to record table should always be valid, no matter if there are
 // no records stored in the archive.
 if (TableOffset < ArchiveHeaderSize) then
  begin
   FreeAndNil(Stream);
   Result:= False;
   Exit;
  end;

 FFileSize:= Stream.Size;
 FreeAndNil(Stream);

 // Set the total number of records and set them to empty values.
 if (NoRecords > 0) then InitRecordCount(NoRecords);
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.WriteArchiveHeader(): Boolean;
var
 Stream: TFileStream;
begin
 if (FOpenmode = aomReadOnly)or(ArchiveTypeAccess <> ataAnyFile) then
  begin
   Result:= False;
   Exit;
  end;

 try
  Stream:= TFileStream.Create(FFileName, fmOpenReadWrite or fmShareExclusive);
 except
  Result:= False;
  Exit;
 end;

 Result:= True;
 try
  // Skip the signature, it is supposed to be valid.
  Stream.Seek(4, soFromBeginning);

  // --> Record Count
  StreamPutLongInt(Stream, Length(Records));
  // --> Table Offset
  StreamPutInt64(Stream, TableOffset);
 except
  Result:= False;
 end;

 FFileSize:= Stream.Size;
 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.ReadRecordTable(): Boolean;
var
 Stream: TStream;
 i: Integer;
begin
 Stream:= CreateArchiveReadStream();
 if (not Assigned(Stream)) then
  begin
   Result:= False;
   Exit;
  end;

 Result:= True;
 try
  Stream.Seek(TableOffset, soFromBeginning);

  for i:= 0 to Length(Records) - 1 do
   begin
    // --> Key
    Records[i].Key:= StreamGetUtf8String(Stream);
    // --> Offset
    Records[i].Offset:= StreamGetInt64(Stream);
   end;
 except
  Result:= False;
 end;

 FFileSize:= Stream.Size;
 FreeAndNil(Stream);

 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.WriteRecordTable(): Boolean;
var
 Stream: TFileStream;
 i: Integer;
begin
 if (FOpenmode = aomReadOnly)or(ArchiveTypeAccess <> ataAnyFile) then
  begin
   Result:= False;
   Exit;
  end;

 try
  Stream:= TFileStream.Create(FFileName, fmOpenReadWrite or fmShareExclusive);
 except
  Result:= False;
  Exit;
 end;

 Result:= True;
 try
  Stream.Seek(TableOffset, soFromBeginning);

  for i:= 0 to Length(Records) - 1 do
   begin
    // --> Key
    StreamPutUtf8String(Stream, Records[i].Key);
    // --> Offset
    StreamPutInt64(Stream, Records[i].Offset);
   end;
 except
  Result:= False;
 end;

 FFileSize:= Stream.Size;
 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.ReadRecordHeaders(): Boolean;
var
 Stream: TStream;
 i, Value: Integer;
begin
 Stream:= CreateArchiveReadStream();
 if (not Assigned(Stream)) then
  begin
   Result:= False;
   Exit;
  end;

 Result:= True;
 try
  for i:= 0 to Length(Records) - 1 do
   begin
    Stream.Seek(Records[i].Offset, soFromBeginning);

    // --> Record Type + Security
    Value:= StreamGetByte(Stream);

    Records[i].RecordType:= TArchiveRecordType(Value and $0F);
    Records[i].Secure    := (Value shr 4) > 0;

    // --> Original Size
    Records[i].OrigSize:= StreamGetLongWord(Stream);
    // --> Physical Size
    Records[i].PhysSize:= StreamGetLongWord(Stream);
    // --> File Date
    Records[i].DateTime:= StreamGetDouble(Stream);
    // --> Checksum
    Records[i].Checksum:= StreamGetLongWord(Stream);
    // --> Init Vector (only if secure)
    if (Records[i].Secure) then
     Records[i].InitVec:= StreamGetInt64(Stream);
   end;
 except
  Result:= False;
 end;

 FFileSize:= Stream.Size;
 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.ReadFileRecords(): Boolean;
begin
 Result:= ReadArchiveHeader();
 if (not Result) then Exit;

 Result:= ReadRecordTable();
 if (not Result) then Exit;

 Result:= ReadRecordHeaders();
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.RefreshArchive(): Boolean;
begin
 case FOpenMode of
  aomUpdate:
   if (not FileExists(FFileName)) then Result:= CreateEmptyFile()
    else Result:= ReadFileRecords();

  aomReadOnly:
   Result:= ReadFileRecords();

  aomOverwrite:
   Result:= CreateEmptyFile();

  else Result:= False; 
 end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreArchive.Refresh();
begin
 if (Length(FFileName) > 0) then RefreshArchive();
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.CompressData(Source: Pointer; SourceSize: Integer;
 out Data: Pointer; out DataSize: Integer): Boolean;
var
 CodeBuf   : Pointer;
 BufferSize: Cardinal;
begin
 Result:= True;

 // guaranteed buffer size
 BufferSize:= Ceil((Cardinal(SourceSize) * (100 + BufferGrow)) / 100) +
  BufferGrowAdd;

 // allocate encoding buffer
 GetMem(CodeBuf, BufferSize);

 // inflate the buffer
 DataSize:= Asphyre.Data.CompressData(Source, CodeBuf, SourceSize,
  BufferSize, clHighest);
 if (DataSize = 0) then
  begin
   FreeNullMem(CodeBuf);
   Result:= False;
   Exit;
  end;

 // allocate real data container
 GetMem(Data, DataSize);

 // copy the compressed data
 Move(CodeBuf^, Data^, DataSize);

 // release encoding buffer
 FreeNullMem(CodeBuf);
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.DecompressData(Source: Pointer; SourceSize: Integer;
 out Data: Pointer; DataSize: Integer): Boolean;
var
 OutSize: Integer;
begin
 Result:= True;

 // allocate output buffer
 GetMem(Data, DataSize);

 // decompress the data stream
 OutSize:= Asphyre.Data.DecompressData(Source, Data, SourceSize, DataSize);
 if (OutSize = 0)or(Int64(OutSize) <> DataSize) then
  begin
   FreeNullMem(Data);
   Result:= False;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.DecompressToMemStream(Source: Pointer;
 SourceSize: Integer; DestStream: TMemoryStream): Boolean;
var
 OutSize: Integer;
begin
 Result:= True;

 OutSize:= Asphyre.Data.DecompressData(Source, DestStream.Memory,
  SourceSize, DestStream.Size);

 if (OutSize = 0)or(Int64(OutSize) <> DestStream.Size) then
  Result:= False;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.WriteRecord(const Key: string; Source: Pointer;
 SourceSize: Integer; RecType: TArchiveRecordType = artFile;
 RecDate: TDateTime = 0.0): Boolean;
var
 i, Value, NewIndex: Integer;
 Data: Pointer;
 DataSize: Integer;
 Stream: TStream;
 RecordOffset: Int64;
 InitVec : packed array[0..3] of Word;
 Checksum: Cardinal;
begin
 Result:= False;
 if (FOpenmode = aomReadOnly)or(ArchiveTypeAccess <> ataAnyFile) then Exit;

 // (1) If the archive does not exist, it needs to be created first.
 if (not FileExists(FFileName)) then
  begin
   Result:= CreateEmptyFile();
   if (not Result) then Exit;
  end;

 // (2) If the record already exists, remove it first.
 if (IndexOf(Key) <> -1) then RemoveRecord(Key);

 // If the record still exists in the list, it cannot be added.
 if (IndexOf(Key) <> -1) then
  begin
   Result:= False;
   Exit;
  end;

 // (3) Calculate the original data checksum.
 Checksum:= ComputeCRC32(Source, SourceSize);

 // (4) Compress the data block.
 Result:= CompressData(Source, SourceSize, Data, DataSize);
 if (not Result) then Exit;

 // (5) Encrypt the data block, if needed.
 if (Assigned(FPassword)) then
  begin
   // Generate random IV keys.
   for i:= 0 to High(InitVec) do
    InitVec[i]:= Random(65536);

   // Encrypt the compressed data. The encryption is done after compression
   // because the encrypted data does not compress much.
   CipherDataXTEA(Data, Data, DataSize, PKey128(FPassword)^, TBlock64(InitVec));
  end else FillChar(InitVec, SizeOf(InitVec), 0);

 // (6) Open the archive to update its contents.
 try
  Stream:= TFileStream.Create(FFileName, fmOpenReadWrite or fmShareExclusive);
 except
  FreeNullMem(Data);
  Result:= False;
  Exit;
 end;

 // (7) Write the new record at the place where record table was located, thus
 // replacing it partially or completely.
 RecordOffset:= TableOffset;
 if (RecDate = 0.0) then RecDate:= Now();

 try
  Stream.Seek(RecordOffset, soFromBeginning);

  // --> Record Type + Security
  Value:= Integer(RecType) and $0F;
  if (Assigned(FPassword)) then Value:= Value or $F0;

  StreamPutByte(Stream, Value);

  // --> Original Size
  StreamPutLongWord(Stream, SourceSize);
  // --> Physical Size
  StreamPutLongWord(Stream, DataSize);
  // --> File Date
  StreamPutDouble(Stream, RecDate);
  // --> Checksum
  StreamPutLongWord(Stream, Checksum);

  // --> Init Vector (only if secure)
  if (Assigned(FPassword)) then
   StreamPutInt64(Stream, Int64(InitVec));

  // --> Record Data
  Stream.WriteBuffer(Data^, DataSize);
 except
  Result:= False;
 end;

 // Update the position of the record table, which should be located exactly
 // at the end of the written record.
 TableOffset:= Stream.Position;

 FreeAndNil(Stream);
 FreeNullMem(Data);

 // If the writing has failed, the archive is most likely unusable as the
 // record table has been corrupted. Trying to write old record table might
 // not work since the writing is what failed in the first place, so there is
 // not much left to do.
 if (not Result) then Exit;

 // (8) Add new entry to the record table.
 NewIndex:= Length(Records);
 SetLength(Records, NewIndex + 1);

 Records[NewIndex].Key     := Key;
 Records[NewIndex].Offset  := RecordOffset;
 Records[NewIndex].RecordType:= RecType;
 Records[NewIndex].OrigSize:= SourceSize;
 Records[NewIndex].PhysSize:= DataSize;
 Records[NewIndex].DateTime:= RecDate;
 Records[NewIndex].Checksum:= Checksum;
 Records[NewIndex].Secure  := Assigned(FPassword);
 Records[NewIndex].InitVec := Int64(InitVec);

 SearchDirty:= True;

 // (9) Write the new record table.
 Result:= WriteRecordTable();
 if (not Result) then Exit;

 // (10) Write the new archive header.
 Result:= WriteArchiveHeader();
 if (not Result) then Exit;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.WriteStream(const Key: string; Stream: TStream;
 RecType: TArchiveRecordType = artFile; RecDate: TDateTime = 0.0): Boolean;
var
 Data: Pointer;
 DataSize, ReadBytes: Integer;
begin
 Result:= False;
 if (FOpenmode = aomReadOnly)or(ArchiveTypeAccess <> ataAnyFile) then Exit;

 DataSize:= Stream.Size - Stream.Position;
 Data:= AllocMem(DataSize);

 ReadBytes:= Stream.Read(Data^, DataSize);
 if (ReadBytes <> DataSize) then
  begin
   FreeNullMem(Data);
   Exit;
  end;

 Result:= WriteRecord(Key, Data, DataSize, RecType, RecDate);
 FreeNullMem(Data);
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.ReadRecord(const Key: string; out Data: Pointer;
 out DataSize: Integer): Boolean;
var
 PhysBuf   : Pointer;
 PhysSize  : Cardinal;
 Index     : Integer;
 Stream    : TStream;
 DataOffset: Int64;
begin
 Result:= False;
 if (FOpenMode = aomOverwrite) then Exit;

 // Find the record in the table to retrieve its offset in the archive.
 Index:= IndexOf(Key);
 if (Index = -1) then Exit;

 // If the record is encrypted, the password is required to proceed.
 if (Records[Index].Secure)and(not Assigned(FPassword)) then Exit;

 // (1) Open the archive for reading data.
 Stream:= CreateArchiveReadStream();
 if (not Assigned(Stream)) then Exit;

 // Assign the original data size, for convenience.
 DataSize:= Records[Index].OrigSize;

 // Create temporary buffers, which will contain compressed data.
 PhysSize:= Records[Index].PhysSize;
 GetMem(PhysBuf, PhysSize);

 // Calculate the position in the archive of the record's data block.
 DataOffset:= Records[Index].Offset + ArchiveDataOffset;
 if (Records[Index].Secure) then Inc(DataOffset, RecordSecuritySize);

 // (2) Read the record from the archive.
 try
  // Move to the position of the data block in the archive.
  Stream.Seek(DataOffset, soFromBeginning);

  // Read the record's data from the archive.
  Stream.ReadBuffer(PhysBuf^, PhysSize);
 except
  FreeNullMem(PhysBuf);
  FreeAndNil(Stream);
  Result:= False;
  Exit;
 end;

 FreeAndNil(Stream);

 // If the record is secure, decrypt the data before decompression.
 if (Records[Index].Secure)and(Assigned(FPassword)) then
  begin
   DecipherDataXTEA(PhysBuf, PhysBuf, PhysSize, PKey128(FPassword)^,
    TBlock64(Records[Index].InitVec));
  end;

 // (3) Decompress the record's data to retrieve original block.
 Result:= DecompressData(PhysBuf, PhysSize, Data, DataSize);
 if (not Result) then
  begin
   FreeNullMem(PhysBuf);
   Exit;
  end;

 FreeNullMem(PhysBuf);

 // (4) Calculate and verify the checksum to verify that the data is genuine.
 Result:= ComputeCRC32(Data, DataSize) = Records[Index].Checksum;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.ReadStream(const Key: string;
 Stream: TStream): Boolean;
var
 Data: Pointer;
 DataSize, BytesWritten: Integer;
begin
 Result:= ReadRecord(Key, Data, DataSize);

 if (Result) then
  begin
   BytesWritten:= Stream.Write(Data^, DataSize);
   Result:= (BytesWritten = DataSize);

   FreeNullMem(Data);
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.ReadMemStream(const Key: string;
 MemStream: TMemoryStream): Boolean;
var
 PhysBuf   : Pointer;
 PhysSize  : Integer;
 Index     : Integer;
 Stream    : TStream;
 DataOffset: Int64;
begin
 Result:= False;
 if (FOpenMode = aomOverwrite) then Exit;

 // Find the record in the table to retrieve its offset in the archive.
 Index:= IndexOf(Key);
 if (Index = -1) then Exit;

 // If the record is encrypted, the password is required to proceed.
 if (Records[Index].Secure)and(not Assigned(FPassword)) then Exit;

 // (1) Open the archive for reading only.
 Stream:= CreateArchiveReadStream();
 if (not Assigned(Stream)) then Exit;

 // Assign the original data size, for convenience.
 MemStream.SetSize(Records[Index].OrigSize);

 // Create temporary buffers, which will contain compressed data.
 PhysSize:= Records[Index].PhysSize;
 GetMem(PhysBuf, PhysSize);

 // Calculate the position in the archive of the record's data block.
 DataOffset:= Records[Index].Offset + ArchiveDataOffset;
 if (Records[Index].Secure) then Inc(DataOffset, RecordSecuritySize);

 // (2) Read the record from the archive.
 try
  // Move to the position of the data block in the archive.
  Stream.Seek(DataOffset, soFromBeginning);

  // Read the record's data from the archive.
  Stream.ReadBuffer(PhysBuf^, PhysSize);
 except
  FreeNullMem(PhysBuf);
  FreeAndNil(Stream);
  Result:= False;
  Exit;
 end;

 FreeAndNil(Stream);

 // If the record is secure, decrypt the data before decompression.
 if (Records[Index].Secure)and(Assigned(FPassword)) then
  begin
   DecipherDataXTEA(PhysBuf, PhysBuf, PhysSize, PKey128(FPassword)^,
    TBlock64(Records[Index].InitVec));
  end;

 // (3) Decompress the record's data to retrieve original block.
 Result:= DecompressToMemStream(PhysBuf, PhysSize, MemStream);
 if (not Result) then
  begin
   FreeNullMem(PhysBuf);
   Exit;
  end;

 FreeNullMem(PhysBuf);

 // (4) Calculate and verify the checksum to verify that the data is genuine.
 Result:= ComputeCRC32(MemStream.Memory, MemStream.Size) =
  Records[Index].Checksum;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.RenameRecord(const Key, NewKey: string): Boolean;
var
 Index: Integer;
begin
 if (FOpenmode <> aomUpdate)or(ArchiveTypeAccess <> ataAnyFile) then
  begin
   Result:= False;
   Exit;
  end;

 Index:= IndexOf(Key);
 if (Index = -1)or(IndexOf(NewKey) <> -1) then
  begin
   Result:= False;
   Exit;
  end;

 Records[Index].Key:= NewKey;
 Result:= WriteRecordTable();

 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.RemoveRecord(const Key: string): Boolean;
var
 NewRecords: array of TArchiveRecord;
 InStream, OutStream: TFileStream;
 TempFileName: string;
 i, Index, NewIndex: Integer;
 TempData: Pointer;
 TempDataSize: Integer;
 NewTableOffset: Int64;
begin
 Result:= False;
 if (FOpenmode <> aomUpdate)or(ArchiveTypeAccess <> ataAnyFile) then Exit;

 // (1) Retrieve record index.
 Index:= IndexOf(Key);
 if (Index = -1) then Exit;

 // (2) Open the source archive for reading only.
 try
  InStream:= TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);
 except
  Exit;
 end;

 // (3) Create temporary archive for writing.
 TempFileName:= ExtractFilePath(FFileName) + TempFileText;

 try
  OutStream:= TFileStream.Create(TempFileName, fmCreate or fmShareExclusive);
 except
  FreeAndNil(InStream);
  Exit;
 end;

 SetLength(NewRecords, 0);
 TempData:= nil;

 Result:= True;
 try
  //.........................................................................
  // Write new tentative archive header.
  //.........................................................................
  // --> Signature
  StreamPutLongWord(OutStream, ArchiveSignature);
  // --> Record Count
  StreamPutLongInt(OutStream, Length(Records) - 1);
  // --> Table Offset
  StreamPutInt64(OutStream, ArchiveHeaderSize);

  //.........................................................................
  // Copy records from the source archive to destination, without modifying
  // their contents.
  //.........................................................................
  for i:= 0 to Length(Records) - 1 do
   if (i <> Index) then
    begin
     // Create a new record in the destination archive.
     NewIndex:= Length(NewRecords);
     SetLength(NewRecords, NewIndex + 1);

     // Copy the record's contents and update its offset.
     NewRecords[NewIndex]:= Records[i];
     NewRecords[NewIndex].Offset:= OutStream.Position;

     // Allocate the memory to hold the entire's record block, including its
     // header and compressed data.
     TempDataSize:= NewRecords[NewIndex].PhysSize + ArchiveDataOffset;
     if (NewRecords[NewIndex].Secure) then Inc(TempDataSize, RecordSecuritySize);

     ReallocMem(TempData, TempDataSize);

     // Read the data from source archive.
     InStream.Seek(Records[i].Offset, soFromBeginning);
     InStream.ReadBuffer(TempData^, TempDataSize);

     // Write the data to the destination archive.
     OutStream.WriteBuffer(TempData^, TempDataSize);
    end;
 except
  Result:= False;
 end;

 if (Assigned(TempData)) then FreeNullMem(TempData);
 FreeAndNil(InStream);

 if (not Result) then
  begin
   FreeAndNil(OutStream);
   Exit;
  end;

 NewTableOffset:= OutStream.Position;

 // (4) Write the new record table and update destination archive header.
 try
  for i:= 0 to Length(NewRecords) - 1 do
   begin
    // --> Key
    StreamPutUtf8String(OutStream, NewRecords[i].Key);
    // --> Offset
    StreamPutInt64(OutStream, NewRecords[i].Offset);
   end;

  // Write an updated value for the record table offset.
  OutStream.Seek(8, soFromBeginning);
  // --> Table Offset
  StreamPutInt64(OutStream, NewTableOffset);
 except
  Result:= False;
 end;

 FreeAndNil(OutStream);
 if (not Result) then Exit;

 try
  DeleteFile(FFileName);
  RenameFile(TempFileName, FFileName);
 except
  Result:= False;
 end;

 if (Result) then Result:= ReadFileRecords();
 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreArchive.InitSearchList();
var
 NeedCount, i: Integer;
begin
 NeedCount:= Length(Records);
 if (Length(SearchList) <> NeedCount) then SetLength(SearchList, NeedCount);

 for i:= 0 to NeedCount - 1 do
  SearchList[i]:= i;
end;

//---------------------------------------------------------------------------
procedure TAsphyreArchive.SearchListSwap(Index1, Index2: Integer);
var
 Temp: Integer;
begin
 Temp:= SearchList[Index1];

 SearchList[Index1]:= SearchList[Index2];
 SearchList[Index2]:= Temp;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.SearchListCompare(Value1, Value2: Integer): Integer;
begin
 Result:= CompareText(Records[Value1].Key, Records[Value2].Key);
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.SearchListSplit(Start, Stop: Integer): Integer;
var
 Left, Right, Pivot: Integer;
begin
 Left := Start + 1;
 Right:= Stop;
 Pivot:= SearchList[Start];

 while (Left <= Right) do
  begin
   while (Left <= Stop)and(SearchListCompare(SearchList[Left], Pivot) < 0) do
    Inc(Left);

   while (Right > Start)and(SearchListCompare(SearchList[Right], Pivot) >= 0) do
    Dec(Right);

   if (Left < Right) then SearchListSwap(Left, Right);
  end;

 SearchListSwap(Start, Right);

 Result:= Right;
end;

//---------------------------------------------------------------------------
procedure TAsphyreArchive.SearchListSort(Start, Stop: Integer);
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
procedure TAsphyreArchive.UpdateSearchList();
var
 ListCount: Integer;
begin
 InitSearchList();

 ListCount:= Length(SearchList);
 if (ListCount > 1) then SearchListSort(0, ListCount - 1);

 SearchDirty:= False;
end;

//---------------------------------------------------------------------------
function TAsphyreArchive.IndexOf(const Key: string): Integer;
var
 Lo, Hi, Mid, Res: Integer;
begin
 if (SearchDirty) then UpdateSearchList();

 Result:= -1;

 Lo:= 0;
 Hi:= Length(SearchList) - 1;

 while (Lo <= Hi) do
  begin
   Mid:= (Lo + Hi) div 2;
   Res:= CompareText(Records[SearchList[Mid]].Key, Key);

   if (Res = 0) then
    begin
     Result:= SearchList[Mid];
     Break;
    end;

   if (Res > 0) then Hi:= Mid - 1 else Lo:= Mid + 1;
 end;
end;

//---------------------------------------------------------------------------
end.
