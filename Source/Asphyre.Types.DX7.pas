unit Asphyre.Types.DX7;
//---------------------------------------------------------------------------
// DirectX 7 general type definitions and utilities.
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
 Asphyre.DDraw7, Asphyre.D3D7, Asphyre.Types;

//---------------------------------------------------------------------------
var
 DDraw7Obj : IDirectDraw7 = nil;
 D3D7Object: IDirect3D7 = nil;
 D3D7Device: IDirect3DDevice7 = nil;

//---------------------------------------------------------------------------
function DX7FormatToAsphyre(const Format: TDDPixelFormat): TAsphyrePixelFormat;
procedure AsphyreToDX7Format(Format: TAsphyrePixelFormat;
 var Desc: TDDPixelFormat);

//---------------------------------------------------------------------------
function DX7FindBackBufferFormat(Width, Height: Integer;
 Format: TAsphyrePixelFormat): TAsphyrePixelFormat;

//---------------------------------------------------------------------------
function DX7FindTextureFormat(
 Format: TAsphyrePixelFormat): TAsphyrePixelFormat;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 System.SysUtils, Asphyre.Formats;

//---------------------------------------------------------------------------
const
 BackBufferFormats: array[0..4] of TAsphyrePixelFormat = (
  { 0 } apf_A8R8G8B8,
  { 1 } apf_X8R8G8B8,
  { 2 } apf_A1R5G5B5,
  { 3 } apf_X1R5G5B5,
  { 4 } apf_R5G6B5);

//---------------------------------------------------------------------------
procedure LearnBitMask(BitMask: Cardinal; out BitPos, BitSize: Integer);
var
 Pos: Integer;
begin
 Pos:= 0;

 while (Pos < 32)and(BitMask and (1 shl Pos) = 0) do Inc(Pos);

 if (Pos >= 32) then
  begin
   BitPos := -1;
   BitSize:= 0;
   Exit;
  end;

 BitPos := Pos;
 BitSize:= 0;

 while (Pos < 32)and(BitMask and (1 shl Pos) > 0) do
  begin
   Inc(Pos);
   Inc(BitSize);
  end;
end;

//---------------------------------------------------------------------------
function CreateBitMask(BitPos, BitSize: Integer): Cardinal;
var
 i: Integer;
begin
 Result:= 0;

 for i:= 0 to BitSize - 1 do
  Result:= Result or (1 shl (BitPos + i));
end;

//---------------------------------------------------------------------------
function DX7FormatToAsphyre(const Format: TDDPixelFormat): TAsphyrePixelFormat;
var
 Info: TPixelFormatInfo;
 BitPos, BitSize, BitCount, TotalBitCount: Integer;
begin
 ResetFormatInfo(Info);

 // -> Check AxRxGxBx formats
 if (Format.dwFlags and DDPF_RGB > 0) then
  begin // RGB format
   BitCount:= 0;

   // (1) Red Channel
   LearnBitMask(Format.dwRBitMask, BitPos, BitSize);
   if (BitPos <> -1)and(BitSize > 0) then
    begin
     AddChannel(Info, ctiR, csUnsigned, BitSize, BitPos);
     Inc(BitCount, BitSize);
    end;

   // (2) Green Channel
   LearnBitMask(Format.dwGBitMask, BitPos, BitSize);
   if (BitPos <> -1)and(BitSize > 0) then
    begin
     AddChannel(Info, ctiG, csUnsigned, BitSize, BitPos);
     Inc(BitCount, BitSize);
    end;

   // (3) Blue Channel
   LearnBitMask(Format.dwBBitMask, BitPos, BitSize);
   if (BitPos <> -1)and(BitSize > 0) then
    begin
     AddChannel(Info, ctiB, csUnsigned, BitSize, BitPos);
     Inc(BitCount, BitSize);
    end;

   // (4) Alpha Channel
   LearnBitMask(Format.dwRGBAlphaBitMask, BitPos, BitSize);

   if (BitPos <> -1)and(BitSize > 0) then
    begin
     AddChannel(Info, ctiA, csUnsigned, BitSize, BitPos);
     Inc(BitCount, BitSize);
    end;

   // (5) X Channel (unused bits)
   TotalBitCount:= Format.dwRGBBitCount;

   if (TotalBitCount > BitCount) then
    AddChannel(Info, ctiX, csUnsigned, TotalBitCount - BitCount, BitCount);
  end;

 // -> Check LxAx formats
 if (Format.dwFlags and DDPF_LUMINANCE > 0) then
  begin // Luminance format
   BitCount:= 0;

   // (1) Luminance Channel
   LearnBitMask(Format.dwLuminanceBitMask, BitPos, BitSize);
   if (BitPos <> -1)and(BitSize > 0) then
    begin
     AddChannel(Info, ctiL, csUnsigned, BitSize, BitPos);
     Inc(BitCount, BitSize);
    end;

   // (2) Alpha Channel
   LearnBitMask(Format.dwLuminanceAlphaBitMask, BitPos, BitSize);
   if (BitPos <> -1)and(BitSize > 0) then
    begin
     AddChannel(Info, ctiA, csUnsigned, BitSize, BitPos);
     Inc(BitCount, BitSize);
    end;

   // (3) X Channel (unused bits)
   TotalBitCount:= Format.dwLuminanceBitCount;

   if (TotalBitCount > BitCount) then
    AddChannel(Info, ctiX, csUnsigned, TotalBitCount - BitCount, BitCount);
  end;

 // -> Alpha-only format
 if (Format.dwFlags and DDPF_ALPHA > 0) then
  AddChannel(Info, ctiA, csUnsigned, Format.dwAlphaBitDepth, 0);

 // Find an existing pixel format matching the current description.
 Result:= InfoToPixelFormat(Info);
end;

//---------------------------------------------------------------------------
procedure AsphyreToDX7Format(Format: TAsphyrePixelFormat;
 var Desc: TDDPixelFormat);
var
 Info: TPixelFormatInfo;
 Category: TPixelFormatCategory;
 RedAt, GreenAt, BlueAt, AlphaAt, VoidAt, LumAt: Integer;
begin
 FillChar(Desc, SizeOf(TDDPixelFormat), 0);
 Desc.dwSize:= SizeOf(TDDPixelFormat);

 if (Format = apf_A8) then
  begin
   Desc.dwFlags:= DDPF_ALPHA;
   Desc.dwAlphaBitDepth:= 8;
   Exit;
  end;

 Info:= GetPixelFormatInfo(Format);
 Category:= PixelFormatCategory[Format];

 case Category of
  pfc_RGB:
   begin
    RedAt  := FindChannelAt(ctiR, Info);
    GreenAt:= FindChannelAt(ctiG, Info);
    BlueAt := FindChannelAt(ctiB, Info);
    AlphaAt:= FindChannelAt(ctiA, Info);
    VoidAt := FindChannelAt(ctiX, Info);

    Desc.dwFlags:= DDPF_RGB;

    if (AlphaAt <> -1)and(Info.Channels[AlphaAt].Bits > 0) then
     Desc.dwFlags:= Desc.dwFlags or DDPF_ALPHAPIXELS;

    if (RedAt <> -1) then
     with Info.Channels[RedAt] do
      begin
       Inc(Desc.dwRGBBitCount, Bits);
       Desc.dwRBitMask:= CreateBitMask(Pos, Bits);
      end;

    if (GreenAt <> -1) then
     with Info.Channels[GreenAt] do
      begin
       Inc(Desc.dwRGBBitCount, Bits);
       Desc.dwGBitMask:= CreateBitMask(Pos, Bits);
      end;

    if (BlueAt <> -1) then
     with Info.Channels[BlueAt] do
      begin
       Inc(Desc.dwRGBBitCount, Bits);
       Desc.dwBBitMask:= CreateBitMask(Pos, Bits);
      end;

    if (AlphaAt <> -1) then
     with Info.Channels[AlphaAt] do
      begin
       Inc(Desc.dwRGBBitCount, Bits);
       Desc.dwRGBAlphaBitMask:= CreateBitMask(Pos, Bits);
      end;

    if (VoidAt <> -1) then
     with Info.Channels[VoidAt] do
      Inc(Desc.dwRGBBitCount, Bits);
   end;

  pfc_Luminance:
   begin
    LumAt  := FindChannelAt(ctiL, Info);
    AlphaAt:= FindChannelAt(ctiA, Info);

    Desc.dwFlags:= DDPF_LUMINANCE;

    if (AlphaAt <> -1)and(Info.Channels[AlphaAt].Bits > 0) then
     Desc.dwFlags:= Desc.dwFlags or DDPF_ALPHAPIXELS;

    if (LumAt <> -1) then
     with Info.Channels[LumAt] do
      begin
       Inc(Desc.dwLuminanceBitCount, Bits);
       Desc.dwLuminanceBitMask:= CreateBitMask(Pos, Bits);
      end;

    if (AlphaAt <> -1) then
     with Info.Channels[AlphaAt] do
      begin
       Inc(Desc.dwLuminanceBitCount, Bits);
       Desc.dwLuminanceAlphaBitMask:= CreateBitMask(Pos, Bits);
      end;
   end;
 end;
end;

//---------------------------------------------------------------------------
function EnumBackBufferCallback(Surface: IDirectDrawSurface7;
 const SurfaceDesc: TDDSurfaceDesc2; Context: Pointer): HResult; stdcall;
var
 Format: TAsphyrePixelFormat;
begin
 Result:= DDENUMRET_OK;

 Format:= DX7FormatToAsphyre(SurfaceDesc.ddpfPixelFormat);

 if (Format <> apf_Unknown) then
  TAsphyreFormatList(Context).Include(Format);
end;

//---------------------------------------------------------------------------
function DX7FindBackBufferFormat(Width, Height: Integer;
 Format: TAsphyrePixelFormat): TAsphyrePixelFormat;
var
 Supported: TAsphyreFormatList;
 BackDesc : TDDSurfaceDesc2;
begin
 Result:= apf_Unknown;
 if (not Assigned(DDraw7Obj)) then Exit;

 Supported:= TAsphyreFormatList.Create();

 FillChar(BackDesc, SizeOf(TDDSurfaceDesc2), 0);

 BackDesc.dwSize:= SizeOf(TDDSurfaceDesc2);
 BackDesc.dwFlags:= DDSD_CAPS or DDSD_HEIGHT or DDSD_WIDTH or DDSD_PIXELFORMAT;
 BackDesc.ddsCaps.dwCaps:= DDSCAPS_OFFSCREENPLAIN or DDSCAPS_3DDEVICE;
 BackDesc.dwWidth := Width;
 BackDesc.dwHeight:= Height;
 BackDesc.ddpfPixelFormat.dwFlags:= DDPF_RGB;

 DDraw7Obj.EnumSurfaces(DDENUMSURFACES_CANBECREATED or DDENUMSURFACES_MATCH,
  BackDesc, Supported, EnumBackBufferCallback);

 Result:= FindClosestFormat(Format, Supported);
 FreeAndNil(Supported);
end;

//---------------------------------------------------------------------------
function EnumTextureCallback(var PixelFmt: TDDPixelFormat;
 Context: Pointer): HResult; stdcall;
var
 Format: TAsphyrePixelFormat;
begin
 Format:= DX7FormatToAsphyre(PixelFmt);
 if (Format <> apf_Unknown) then TAsphyreFormatList(Context).Insert(Format);

 Result:= DDENUMRET_OK;
end;

//---------------------------------------------------------------------------
function DX7FindTextureFormat(
 Format: TAsphyrePixelFormat): TAsphyrePixelFormat;
var
 Supported: TAsphyreFormatList;
begin
 Result:= apf_Unknown;
 if (not Assigned(D3D7Device)) then Exit;

 Supported:= TAsphyreFormatList.Create();
 D3D7Device.EnumTextureFormats(EnumTextureCallback, Supported);

 Result:= FindClosestFormat(Format, Supported);
 FreeAndNil(Supported);
end;

//---------------------------------------------------------------------------
end.
