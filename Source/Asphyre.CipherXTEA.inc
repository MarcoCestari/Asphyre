//---------------------------------------------------------------------------
// CipherXTEA.inc
// XTEA 128-bit cipher using 64-bit block mode.
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
// For more information about XTEA cipher, visit:
//   http://en.wikipedia.org/wiki/XTEA
//
// Block cipher operation modes are explained at:
//   http://en.wikipedia.org/wiki/Cipher_block_chaining
//
// Thanks to Robert Kosek for providing information about this cipher in the
// following discussion on Afterwarp forums:
//   http://dev.ixchels.net/forum/thread460.html
//---------------------------------------------------------------------------
// Additional Information
//
// This is an implementation of XTEA block cipher encryption in CBC mode,
// using residual block termination for data that is not 64-bit divisible.
// The cipher code uses extensive parenthesis usage to avoid ambiguity.
//---------------------------------------------------------------------------
// Note: this file has been preformatted to be used with PasDoc.
//---------------------------------------------------------------------------

{$ifdef Asphyre_Interface}

//---------------------------------------------------------------------------
type
{ Pointer to @link(TBlock64) to pass that structure by reference. }
 PBlock64 = ^TBlock64;

{ 64-bit data block commonly used as init-vector for XTEA cipher. }
 TBlock64 = packed array[0..1] of LongWord;

//---------------------------------------------------------------------------
{ Pointer to @link(TKey128) to pass that structure by reference. }
 PKey128 = ^TKey128;

{ 128-bit data block commonly used as password XTEA cipher. }
 TKey128 = packed array[0..3] of LongWord;

//---------------------------------------------------------------------------
{ Encrypts data using 128-bit XTEA cipher in CBC chaining mode and residual
  block termination (in case the data buffer is not multiple of 8 bytes). }
procedure CipherDataXTEA(Source, Dest: Pointer; Count: Integer;
 const Key: TKey128; const InitVec: TBlock64);

//---------------------------------------------------------------------------
{ Decrypts data using 128-bit XTEA cipher in CBC chaining mode and residual
  block termination (in case the data buffer is not multiple of 8 bytes). }
procedure DecipherDataXTEA(Source, Dest: Pointer; Count: Integer;
 const Key: TKey128; const InitVec: TBlock64);

//---------------------------------------------------------------------------
{$endif Asphyre_Interface}
{$ifdef Asphyre_Implementation}

//---------------------------------------------------------------------------
const
 Delta = $9E3779B9;

//---------------------------------------------------------------------------
// CipherEntryXEA()
//
// Encrypts a single 64-bit block using XTEA cipher.
//---------------------------------------------------------------------------
procedure CipherEntryXTEA(const Src: TBlock64; out Dest: TBlock64;
 const Key: TKey128);
var
 i: Integer;
 Sum, v0, v1: LongWord;
begin
 Sum:= 0;
 v0:= Src[0];
 v1:= Src[1];

 for i:= 0 to 31 do
  begin
   Inc(v0, (((v1 shl 4) xor (v1 shr 5)) + v1) xor (Sum + Key[Sum and 3]));
   Inc(Sum, Delta);
   Inc(v1, (((v0 shl 4) xor (v0 shr 5)) + v0) xor
    (Sum + Key[(Sum shr 11) and 3]));
  end;

 Dest[0]:= v0;
 Dest[1]:= v1;
end;

//---------------------------------------------------------------------------
// DecipherEntryXEA()
//
// Decrypts a single 64-bit block using XTEA cipher.
//---------------------------------------------------------------------------
procedure DecipherEntryXTEA(const Src: TBlock64; out Dest: TBlock64;
 const Key: TKey128);
var
 i: Integer;
 Sum, v0, v1: LongWord;
begin
 Sum:= $C6EF3720;
 v0:= Src[0];
 v1:= Src[1];

 for i:= 0 to 31 do
  begin
   Dec(v1, (((v0 shl 4) xor (v0 shr 5)) + v0) xor
    (Sum + Key[(Sum shr 11) and 3]));
   Dec(Sum, Delta);
   Dec(v0, (((v1 shl 4) xor (v1 shr 5)) + v1) xor
    (Sum + Key[Sum and 3]));
  end;

 Dest[0]:= v0;
 Dest[1]:= v1;
end;

//---------------------------------------------------------------------------
procedure CipherDataXTEA(Source, Dest: Pointer; Count: Integer;
 const Key: TKey128; const InitVec: TBlock64);
var
 i: Integer;
 SrcBlock : PBlock64;
 DestBlock: PBlock64;
 AuxBlock : TBlock64;
 LastBlock: TBlock64;
begin
 // Apply CBC mode in the block cipher.
 Move(InitVec, LastBlock, SizeOf(TBlock64));

 SrcBlock := Source;
 DestBlock:= Dest;

 for i:= 0 to (Count div 8) - 1 do
  begin
   AuxBlock[0]:= SrcBlock[0] xor LastBlock[0];
   AuxBlock[1]:= SrcBlock[1] xor LastBlock[1];

   CipherEntryXTEA(AuxBlock, LastBlock, Key);

   DestBlock[0]:= LastBlock[0];
   DestBlock[1]:= LastBlock[1];

   Inc(SrcBlock);
   Inc(DestBlock);
  end;

 // Residual block termination.
 if (Count mod 8 > 0) then
  begin
   // Use encrypted IV, if message is too small.
   if (Count < 8) then
    CipherEntryXTEA(InitVec, LastBlock, Key);

   // Encrypt last block again.
   CipherEntryXTEA(LastBlock, LastBlock, Key);

   // Fill the auxiliary block with remaining bytes.
   AuxBlock[0]:= 0;
   AuxBlock[1]:= 0;
   Move(SrcBlock^, AuxBlock, Count mod 8);

   // Encrypt the remaining bytes.
   AuxBlock[0]:= AuxBlock[0] xor LastBlock[0];
   AuxBlock[1]:= AuxBlock[1] xor LastBlock[1];

   // Write the remaining bytes to destination.
   Move(AuxBlock, DestBlock^, Count mod 8);
  end;
end;

//---------------------------------------------------------------------------
procedure DecipherDataXTEA(Source, Dest: Pointer; Count: Integer;
 const Key: TKey128; const InitVec: TBlock64);
var
 i: Integer;
 SrcBlock : PBlock64;
 DestBlock: PBlock64;
 AuxBlock : TBlock64;
 LastBlock: TBlock64;
begin
 // Apply CBC mode in block cipher.
 Move(InitVec, LastBlock, SizeOf(TBlock64));

 SrcBlock := Source;
 DestBlock:= Dest;

 for i:= 0 to (Count div 8) - 1 do
  begin
   DecipherEntryXTEA(SrcBlock^, AuxBlock, Key);

   AuxBlock[0]:= AuxBlock[0] xor LastBlock[0];
   AuxBlock[1]:= AuxBlock[1] xor LastBlock[1];

   LastBlock[0]:= SrcBlock^[0];
   LastBlock[1]:= SrcBlock^[1];

   DestBlock[0]:= AuxBlock[0];
   DestBlock[1]:= AuxBlock[1];

   Inc(SrcBlock);
   Inc(DestBlock);
  end;

 // Residual block termination.
 if (Count mod 8 > 0) then
  begin
   // Use encrypted IV, if message is too small.
   if (Count < 8) then
    CipherEntryXTEA(InitVec, LastBlock, Key);

   // Encrypt last block again.
   CipherEntryXTEA(LastBlock, LastBlock, Key);

   // Fill the auxiliary block with remaining bytes.
   AuxBlock[0]:= 0;
   AuxBlock[1]:= 0;
   Move(SrcBlock^, AuxBlock, Count mod 8);

   // Decrypt the remaining bytes.
   AuxBlock[0]:= AuxBlock[0] xor LastBlock[0];
   AuxBlock[1]:= AuxBlock[1] xor LastBlock[1];

   // Write the remaining bytes to destination.
   Move(AuxBlock, DestBlock^, Count mod 8);
  end;
end;

//---------------------------------------------------------------------------
{$endif Asphyre_Implementation}

