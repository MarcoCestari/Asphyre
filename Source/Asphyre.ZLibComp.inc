//---------------------------------------------------------------------------
// ZLibComp.inc
// ZLib Data Compression high level routines.
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
type
{ The level of compression used when compressing data blocks. }
 TCompressionLevel = (
  { Lowest level of compression but fastest performance. }
  clLowest,

  { A balanced approach using average compression and performance. }
  clNormal,

  { The best possible compression at the expense of decreased performance. }
  clHighest);

//---------------------------------------------------------------------------
// CompressData()
//
// Compresses a given number of bytes of source data and saves the compressed
// data in the destination address. The output size can be limited by
// specifying non-zero value in "MaxDestSize".
//---------------------------------------------------------------------------
{ Compresses data block from the source buffer to destination buffer. The
  memory for both buffers must be allocated. @italic(MaxDestSize) can be used
  to specify the maximum data length that can be saved at the destination
  buffer to prevent overflow. }
function CompressData(Source, Dest: Pointer; SourceSize,
 MaxDestSize: Cardinal; Compression: TCompressionLevel = clNormal): Integer;

//---------------------------------------------------------------------------
// DecompressData()
//
// Decompresses the previously compressed data (by InflateData routine) and
// saves it in the destination address. The output size can be limited by
// specifying non-zero value in "MaxDestSize".
//---------------------------------------------------------------------------
{ Decompresses data block from the source buffer to destination buffer. The
  memory for both buffers must be allocated. @italic(MaxDestSize) can be used
  to specify the maximum data length that can be saved at the destination
  buffer to prevent overflow. }
function DecompressData(Source, Dest: Pointer; SourceSize,
 MaxDestSize: Cardinal): Integer;

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
function CompressData(Source, Dest: Pointer; SourceSize,
 MaxDestSize: Cardinal; Compression: TCompressionLevel): Integer;
var
 OutSize: Cardinal;
 Level: Integer;
begin
 OutSize:= MaxDestSize;

 case Compression of
  clLowest:
   Level:= Z_BEST_SPEED;

   clHighest:
   Level:= Z_BEST_COMPRESSION;

  else Level:= Z_DEFAULT_COMPRESSION;
 end;

 compress2(Dest, OutSize, Source, SourceSize, Level);

 Result:= OutSize;
end;

//---------------------------------------------------------------------------
function DecompressData(Source, Dest: Pointer; SourceSize,
 MaxDestSize: Cardinal): Integer;
var
 OutSize: Cardinal;
begin
 OutSize:= MaxDestSize;

 uncompress(Dest, OutSize, Source, SourceSize);

 Result:= OutSize;
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}
