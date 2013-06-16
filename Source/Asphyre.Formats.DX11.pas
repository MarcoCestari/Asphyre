unit Asphyre.Formats.DX11;
//---------------------------------------------------------------------------
// DirectX 11 pixel format utilities.
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

//--------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 JSB.DXGI, Asphyre.TypeDef, Asphyre.Types;

//---------------------------------------------------------------------------
function AsphyreToDX11Format(Format: TAsphyrePixelFormat): DXGI_FORMAT;
function DX11FormatToAsphyre(Format: DXGI_FORMAT): TAsphyrePixelFormat;

//---------------------------------------------------------------------------
function GetDX11FormatBitDepth(Format: DXGI_FORMAT): Integer;

//---------------------------------------------------------------------------
function DX11FindTextureFormat(Format: TAsphyrePixelFormat;
 Mipmapped: Boolean): TAsphyrePixelFormat;

//---------------------------------------------------------------------------
function DX11FindRenderTargetFormat(Format: TAsphyrePixelFormat;
 Mipmapped: Boolean): TAsphyrePixelFormat;

//---------------------------------------------------------------------------
function DX11FindDisplayFormat(
 Format: TAsphyrePixelFormat): TAsphyrePixelFormat;

//---------------------------------------------------------------------------
function DX11FindDepthStencilFormat(StencilLevel: Integer): DXGI_FORMAT;

 //---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 Winapi.Windows, System.SysUtils,
{$else}
 Windows, SysUtils,
{$endif}
 JSB.D3D11, Asphyre.Formats,
 Asphyre.Types.DX11;

//---------------------------------------------------------------------------
const
 DepthStencilFormats: array[0..3] of DXGI_FORMAT = (
  { 0 } DXGI_FORMAT_D32_FLOAT_S8X24_UINT,
  { 1 } DXGI_FORMAT_D24_UNORM_S8_UINT,
  { 2 } DXGI_FORMAT_D32_FLOAT,
  { 3 } DXGI_FORMAT_D16_UNORM);

//---------------------------------------------------------------------------
function AsphyreToDX11Format(Format: TAsphyrePixelFormat): DXGI_FORMAT;
begin
 case Format of
  apf_A8R8G8B8:
   Result:= DXGI_FORMAT_B8G8R8A8_UNORM;

  apf_X8R8G8B8:
   Result:= DXGI_FORMAT_B8G8R8X8_UNORM;

  apf_R5G6B5:
   Result:= DXGI_FORMAT_B5G6R5_UNORM;

  apf_A1R5G5B5:
   Result:= DXGI_FORMAT_B5G5R5A1_UNORM;

  apf_A8:
   Result:= DXGI_FORMAT_A8_UNORM;

  apf_A2B10G10R10:
   Result:= DXGI_FORMAT_R10G10B10A2_UNORM;

  apf_G16R16:
   Result:= DXGI_FORMAT_R16G16_UNORM;

  apf_A16B16G16R16:
   Result:= DXGI_FORMAT_R16G16B16A16_UNORM;

  apf_L8:
   Result:= DXGI_FORMAT_R8_UNORM;

  apf_A8L8:
   Result:= DXGI_FORMAT_R8G8_UNORM;

  apf_L16:
   Result:= DXGI_FORMAT_R16_UNORM;

  apf_R16F:
   Result:= DXGI_FORMAT_R16_FLOAT;

  apf_G16R16F:
   Result:= DXGI_FORMAT_R16G16_FLOAT;

  apf_A16B16G16R16F:
   Result:= DXGI_FORMAT_R16G16B16A16_FLOAT;

  apf_R32F:
   Result:= DXGI_FORMAT_R32_FLOAT;

  apf_G32R32F:
   Result:= DXGI_FORMAT_R32G32_FLOAT;

  apf_A32B32G32R32F:
   Result:= DXGI_FORMAT_R32G32B32A32_FLOAT;

  apf_A8B8G8R8:
   Result:= DXGI_FORMAT_R8G8B8A8_UNORM;

  else Result:= DXGI_FORMAT_UNKNOWN;
 end;
end;

//---------------------------------------------------------------------------
function DX11FormatToAsphyre(Format: DXGI_FORMAT): TAsphyrePixelFormat;
begin
 case Format of
  DXGI_FORMAT_B8G8R8A8_UNORM:
   Result:= apf_A8R8G8B8;

  DXGI_FORMAT_B8G8R8X8_UNORM:
   Result:= apf_X8R8G8B8;

  DXGI_FORMAT_B5G6R5_UNORM:
   Result:= apf_R5G6B5;

  DXGI_FORMAT_B5G5R5A1_UNORM:
   Result:= apf_A1R5G5B5;

  DXGI_FORMAT_A8_UNORM:
   Result:= apf_A8;

  DXGI_FORMAT_R10G10B10A2_UNORM:
   Result:= apf_A2B10G10R10;

  DXGI_FORMAT_R16G16_UNORM:
   Result:= apf_G16R16;

  DXGI_FORMAT_R16G16B16A16_UNORM:
   Result:= apf_A16B16G16R16;

  DXGI_FORMAT_R16_FLOAT:
   Result:= apf_R16F;

  DXGI_FORMAT_R16G16_FLOAT:
   Result:= apf_G16R16F;

  DXGI_FORMAT_R16G16B16A16_FLOAT:
   Result:= apf_A16B16G16R16F;

  DXGI_FORMAT_R32_FLOAT:
   Result:= apf_R32F;

  DXGI_FORMAT_R32G32_FLOAT:
   Result:= apf_G32R32F;

  DXGI_FORMAT_R32G32B32A32_FLOAT:
   Result:= apf_A32B32G32R32F;

  DXGI_FORMAT_R8G8B8A8_UNORM:
   Result:= apf_A8B8G8R8;

  else Result:= apf_Unknown;
 end;
end;

//---------------------------------------------------------------------------
function GetDX11FormatBitDepth(Format: DXGI_FORMAT): Integer;
begin
 case Format of
  DXGI_FORMAT_R32G32B32A32_TYPELESS,
  DXGI_FORMAT_R32G32B32A32_FLOAT,
  DXGI_FORMAT_R32G32B32A32_UINT,
  DXGI_FORMAT_R32G32B32A32_SINT:
   Result:= 128;

  DXGI_FORMAT_R32G32B32_TYPELESS,
  DXGI_FORMAT_R32G32B32_FLOAT,
  DXGI_FORMAT_R32G32B32_UINT,
  DXGI_FORMAT_R32G32B32_SINT:
   Result:= 96;

  DXGI_FORMAT_R16G16B16A16_TYPELESS,
  DXGI_FORMAT_R16G16B16A16_FLOAT,
  DXGI_FORMAT_R16G16B16A16_UNORM,
  DXGI_FORMAT_R16G16B16A16_UINT,
  DXGI_FORMAT_R16G16B16A16_SNORM,
  DXGI_FORMAT_R16G16B16A16_SINT,
  DXGI_FORMAT_R32G32_TYPELESS,
  DXGI_FORMAT_R32G32_FLOAT,
  DXGI_FORMAT_R32G32_UINT,
  DXGI_FORMAT_R32G32_SINT,
  DXGI_FORMAT_R32G8X24_TYPELESS,
  DXGI_FORMAT_D32_FLOAT_S8X24_UINT,
  DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS,
  DXGI_FORMAT_X32_TYPELESS_G8X24_UINT:
   Result:= 64;

  DXGI_FORMAT_R10G10B10A2_TYPELESS,
  DXGI_FORMAT_R10G10B10A2_UNORM,
  DXGI_FORMAT_R10G10B10A2_UINT,
  DXGI_FORMAT_R11G11B10_FLOAT,
  DXGI_FORMAT_R8G8B8A8_TYPELESS,
  DXGI_FORMAT_R8G8B8A8_UNORM,
  DXGI_FORMAT_R8G8B8A8_UNORM_SRGB,
  DXGI_FORMAT_R8G8B8A8_UINT,
  DXGI_FORMAT_R8G8B8A8_SNORM,
  DXGI_FORMAT_R8G8B8A8_SINT,
  DXGI_FORMAT_R16G16_TYPELESS,
  DXGI_FORMAT_R16G16_FLOAT,
  DXGI_FORMAT_R16G16_UNORM,
  DXGI_FORMAT_R16G16_UINT,
  DXGI_FORMAT_R16G16_SNORM,
  DXGI_FORMAT_R16G16_SINT,
  DXGI_FORMAT_R32_TYPELESS,
  DXGI_FORMAT_D32_FLOAT,
  DXGI_FORMAT_R32_FLOAT,
  DXGI_FORMAT_R32_UINT,
  DXGI_FORMAT_R32_SINT,
  DXGI_FORMAT_R24G8_TYPELESS,
  DXGI_FORMAT_D24_UNORM_S8_UINT,
  DXGI_FORMAT_R24_UNORM_X8_TYPELESS,
  DXGI_FORMAT_X24_TYPELESS_G8_UINT,
  DXGI_FORMAT_B8G8R8A8_UNORM,
  DXGI_FORMAT_B8G8R8X8_UNORM,
  DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM,
  DXGI_FORMAT_B8G8R8A8_TYPELESS,
  DXGI_FORMAT_B8G8R8A8_UNORM_SRGB,
  DXGI_FORMAT_B8G8R8X8_TYPELESS,
  DXGI_FORMAT_B8G8R8X8_UNORM_SRGB,
  DXGI_FORMAT_R9G9B9E5_SHAREDEXP:
   Result:= 32;

  DXGI_FORMAT_R8G8_TYPELESS,
  DXGI_FORMAT_R8G8_UNORM,
  DXGI_FORMAT_R8G8_UINT,
  DXGI_FORMAT_R8G8_SNORM,
  DXGI_FORMAT_R8G8_SINT,
  DXGI_FORMAT_R16_TYPELESS,
  DXGI_FORMAT_R16_FLOAT,
  DXGI_FORMAT_D16_UNORM,
  DXGI_FORMAT_R16_UNORM,
  DXGI_FORMAT_R16_UINT,
  DXGI_FORMAT_R16_SNORM,
  DXGI_FORMAT_R16_SINT,
  DXGI_FORMAT_B5G6R5_UNORM,
  DXGI_FORMAT_B5G5R5A1_UNORM,
  DXGI_FORMAT_R8G8_B8G8_UNORM,
  DXGI_FORMAT_G8R8_G8B8_UNORM:
   Result:= 16;

  DXGI_FORMAT_R8_TYPELESS,
  DXGI_FORMAT_R8_UNORM,
  DXGI_FORMAT_R8_UINT,
  DXGI_FORMAT_R8_SNORM,
  DXGI_FORMAT_R8_SINT,
  DXGI_FORMAT_A8_UNORM:
   Result:= 8;

  DXGI_FORMAT_R1_UNORM:
   Result:= 1;

  DXGI_FORMAT_BC1_TYPELESS,
  DXGI_FORMAT_BC1_UNORM,
  DXGI_FORMAT_BC1_UNORM_SRGB,
  DXGI_FORMAT_BC4_TYPELESS,
  DXGI_FORMAT_BC4_UNORM,
  DXGI_FORMAT_BC4_SNORM:
   Result:= 4;

  DXGI_FORMAT_BC2_TYPELESS,
  DXGI_FORMAT_BC2_UNORM,
  DXGI_FORMAT_BC2_UNORM_SRGB,
  DXGI_FORMAT_BC3_TYPELESS,
  DXGI_FORMAT_BC3_UNORM,
  DXGI_FORMAT_BC3_UNORM_SRGB,
  DXGI_FORMAT_BC5_TYPELESS,
  DXGI_FORMAT_BC5_UNORM,
  DXGI_FORMAT_BC5_SNORM,
  DXGI_FORMAT_BC6H_TYPELESS,
  DXGI_FORMAT_BC6H_UF16,
  DXGI_FORMAT_BC6H_SF16,
  DXGI_FORMAT_BC7_TYPELESS,
  DXGI_FORMAT_BC7_UNORM,
  DXGI_FORMAT_BC7_UNORM_SRGB:
   Result:= 8;

  else Result:= 0;
 end;
end;

//---------------------------------------------------------------------------
function DX11FindTextureFormat(Format: TAsphyrePixelFormat;
 Mipmapped: Boolean): TAsphyrePixelFormat;
var
 Supported : TAsphyreFormatList;
 Sample    : TAsphyrePixelFormat;
 TestFormat: DXGI_FORMAT;
 FormatSup : Cardinal;
begin
 Result:= apf_Unknown;
 if (not Assigned(D3D11Device)) then Exit;

 Supported:= TAsphyreFormatList.Create();

 PushClearFPUState();
 try
  for Sample:= Low(TAsphyrePixelFormat) to High(TAsphyrePixelFormat) do
   begin
    TestFormat:= AsphyreToDX11Format(Sample);
    if (TestFormat = DXGI_FORMAT_UNKNOWN) then Continue;

    if (Failed(D3D11Device.CheckFormatSupport(TestFormat, FormatSup))) then
     Continue;

    if (FormatSup and Ord(D3D11_FORMAT_SUPPORT_TEXTURE2D) = 0) then Continue;

    if (Mipmapped)and
     (FormatSup and Ord(D3D11_FORMAT_SUPPORT_MIP) = 0) then Continue;

    Supported.Insert(Sample);
   end;
 finally
  PopFPUState();
 end;

 Result:= FindClosestFormat(Format, Supported);
 FreeAndNil(Supported);
end;

//---------------------------------------------------------------------------
function DX11FindRenderTargetFormat(Format: TAsphyrePixelFormat;
 Mipmapped: Boolean): TAsphyrePixelFormat;
var
 Supported : TAsphyreFormatList;
 Sample    : TAsphyrePixelFormat;
 TestFormat: DXGI_FORMAT;
 FormatSup : Cardinal;
begin
 Result:= apf_Unknown;
 if (not Assigned(D3D11Device)) then Exit;

 Supported:= TAsphyreFormatList.Create();

 PushClearFPUState();
 try
  for Sample:= Low(TAsphyrePixelFormat) to High(TAsphyrePixelFormat) do
   begin
    TestFormat:= AsphyreToDX11Format(Sample);
    if (TestFormat = DXGI_FORMAT_UNKNOWN) then Continue;

    if (Failed(D3D11Device.CheckFormatSupport(TestFormat, FormatSup))) then
     Continue;

    if (FormatSup and Ord(D3D11_FORMAT_SUPPORT_TEXTURE2D) = 0) then Continue;
    if (FormatSup and Ord(D3D11_FORMAT_SUPPORT_RENDER_TARGET) = 0) then Continue;

    if (Mipmapped) then
     begin
      if (FormatSup and Ord(D3D11_FORMAT_SUPPORT_MIP) = 0) then Continue;
      if (FormatSup and Ord(D3D11_FORMAT_SUPPORT_MIP_AUTOGEN) = 0) then Continue;
     end;

    Supported.Insert(Sample);
   end;
 finally
  PopFPUState();
 end;

 Result:= FindClosestFormat(Format, Supported);
 FreeAndNil(Supported);
end;

//---------------------------------------------------------------------------
function DX11FindDisplayFormat(
 Format: TAsphyrePixelFormat): TAsphyrePixelFormat;
var
 Supported : TAsphyreFormatList;
 Sample    : TAsphyrePixelFormat;
 TestFormat: DXGI_FORMAT;
 FormatSup : Cardinal;
begin
 Result:= apf_Unknown;
 if (not Assigned(D3D11Device)) then Exit;

 Supported:= TAsphyreFormatList.Create();

 PushClearFPUState();
 try
  for Sample:= Low(TAsphyrePixelFormat) to High(TAsphyrePixelFormat) do
   begin
    TestFormat:= AsphyreToDX11Format(Sample);
    if (TestFormat = DXGI_FORMAT_UNKNOWN) then Continue;

    if (Failed(D3D11Device.CheckFormatSupport(TestFormat, FormatSup))) then
     Continue;

    if (FormatSup and Ord(D3D11_FORMAT_SUPPORT_DISPLAY) = 0) then Continue;
    if (FormatSup and Ord(D3D11_FORMAT_SUPPORT_BUFFER) = 0) then Continue;
    if (FormatSup and Ord(D3D11_FORMAT_SUPPORT_RENDER_TARGET) = 0) then Continue;

    Supported.Insert(Sample);
   end;
 finally
  PopFPUState();
 end;

 Result:= FindClosestFormat(Format, Supported);
 FreeAndNil(Supported);
end;

//---------------------------------------------------------------------------
function DX11FindDepthStencilFormat(StencilLevel: Integer): DXGI_FORMAT;
const
 FormatIndexes: array[0..2, 0..3] of Integer = ((-1, -1, -1, -1), (2, 0, 1, 3),
  (0, 1, 2, 3));
var
 i: Integer;
 Format: DXGI_FORMAT;
 FormatSup: Cardinal;
begin
 Result:= DXGI_FORMAT_UNKNOWN;
 if (StencilLevel < 0)or(StencilLevel > 2)or(not Assigned(D3D11Device)) then Exit;

 for i:= 0 to 3 do
  begin
   Format:= DepthStencilFormats[FormatIndexes[StencilLevel, i]];
   if (Failed(D3D11Device.CheckFormatSupport(Format, FormatSup))) then Continue;

   if (FormatSup and Ord(D3D11_FORMAT_SUPPORT_TEXTURE2D) > 0)and
    (FormatSup and Ord(D3D11_FORMAT_SUPPORT_DEPTH_STENCIL) > 0) then
    begin
     Result:= Format;
     Break;
    end;
  end;
end;

//---------------------------------------------------------------------------
end.
