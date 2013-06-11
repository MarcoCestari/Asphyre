unit Asphyre.Types.DX9;
//---------------------------------------------------------------------------
// Direct3D 9 general type definitions and utilities.
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
 Asphyre.D3D9, Winapi.Windows, System.SysUtils, Asphyre.Types;

//---------------------------------------------------------------------------
type
 TDirect3D9Mode = (dmUnknown, dmDirect3D9, dmDirect3D9Ex);

//---------------------------------------------------------------------------
// The following variables are declared as globals. The global declaration,
// although generally avoided, in this case decreases the coupling of DX 9
// provider classes.
//---------------------------------------------------------------------------
var
 D3D9Mode: TDirect3D9Mode = dmUnknown;

//---------------------------------------------------------------------------
 D3D9DisplayMode  : D3DDISPLAYMODEEX;
 D3D9PresentParams: D3DPRESENT_PARAMETERS;

//---------------------------------------------------------------------------
 D3D9Object: IDirect3D9 = nil;
 D3D9Device: IDirect3DDevice9 = nil;

//---------------------------------------------------------------------------
 D3D9Caps: D3DCaps9;

//---------------------------------------------------------------------------
 DX9ActiveDepthStencilLevel: Integer = 0;

//---------------------------------------------------------------------------
function DX9FormatToAsphyre(Format: D3DFORMAT): TAsphyrePixelFormat;
function AsphyreToDX9Format(Format: TAsphyrePixelFormat): D3DFORMAT;

//---------------------------------------------------------------------------
function DX9FindBackBufferFormat(Format: TAsphyrePixelFormat): D3DFORMAT;
function DX9FindDepthStencilFormat(StencilLevel: Integer): D3DFORMAT;

procedure DX9FindBestMultisampleType(BackBufferFormat, DepthFormat: D3DFORMAT;
 Multisamples: Integer; out SampleType: D3DMULTISAMPLE_TYPE;
 out QualityLevel: Cardinal);

//---------------------------------------------------------------------------
function DX9FindTextureFormat(Format: TAsphyrePixelFormat;
 Usage: Cardinal): TAsphyrePixelFormat;

//---------------------------------------------------------------------------
function DX9FindTextureFormatEx(Format: TAsphyrePixelFormat;
 Usage1, Usage2: Cardinal): TAsphyrePixelFormat;

//---------------------------------------------------------------------------
procedure ClearD3D9DisplayMode();
procedure ClearD3D9PresentParams();
procedure ClearD3D9Caps();

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Formats;

//---------------------------------------------------------------------------
const
 BackBufferFormats: array[0..5] of TAsphyrePixelFormat = (
  { 0 } apf_A2R10G10B10,
  { 1 } apf_A8R8G8B8,
  { 2 } apf_X8R8G8B8,
  { 3 } apf_A1R5G5B5,
  { 4 } apf_X1R5G5B5,
  { 5 } apf_R5G6B5);

//---------------------------------------------------------------------------
 DepthStencilFormats: array[0..5] of D3DFORMAT = (
  { 0 } D3DFMT_D24S8,
  { 1 } D3DFMT_D24X4S4,
  { 2 } D3DFMT_D15S1,
  { 3 } D3DFMT_D32,
  { 4 } D3DFMT_D24X8,
  { 5 } D3DFMT_D16);

//---------------------------------------------------------------------------
function DX9FormatToAsphyre(Format: D3DFORMAT): TAsphyrePixelFormat;
begin
 case Format of
  D3DFMT_R8G8B8: Result:= apf_R8G8B8;
  D3DFMT_A8R8G8B8: Result:= apf_A8R8G8B8;
  D3DFMT_X8R8G8B8: Result:= apf_X8R8G8B8;
  D3DFMT_R5G6B5: Result:= apf_R5G6B5;
  D3DFMT_X1R5G5B5: Result:= apf_X1R5G5B5;
  D3DFMT_A1R5G5B5: Result:= apf_A1R5G5B5;
  D3DFMT_A4R4G4B4: Result:= apf_A4R4G4B4;
  D3DFMT_R3G3B2: Result:= apf_R3G3B2;
  D3DFMT_A8: Result:= apf_A8;
  D3DFMT_A8R3G3B2: Result:= apf_A8R3G3B2;
  D3DFMT_X4R4G4B4: Result:= apf_X4R4G4B4;
  D3DFMT_A2B10G10R10: Result:= apf_A2B10G10R10;
  D3DFMT_A8B8G8R8: Result:= apf_A8B8G8R8;
  D3DFMT_X8B8G8R8: Result:= apf_X8B8G8R8;
  D3DFMT_G16R16: Result:= apf_G16R16;
  D3DFMT_A2R10G10B10: Result:= apf_A2R10G10B10;
  D3DFMT_A16B16G16R16: Result:= apf_A16B16G16R16;
  D3DFMT_L8: Result:= apf_L8;
  D3DFMT_A8L8: Result:= apf_A8L8;
  D3DFMT_A4L4: Result:= apf_A4L4;
  D3DFMT_L16: Result:= apf_L16;
  D3DFMT_R16F: Result:= apf_R16F;
  D3DFMT_G16R16F: Result:= apf_G16R16F;
  D3DFMT_A16B16G16R16F: Result:= apf_A16B16G16R16F;
  D3DFMT_R32F: Result:= apf_R32F;
  D3DFMT_G32R32F: Result:= apf_G32R32F;
  D3DFMT_A32B32G32R32F: Result:= apf_A32B32G32R32F;

  else Result:= apf_Unknown;
 end;
end;

//---------------------------------------------------------------------------
function AsphyreToDX9Format(Format: TAsphyrePixelFormat): D3DFORMAT;
begin
 case Format of
  apf_R8G8B8: Result:= D3DFMT_R8G8B8;
  apf_A8R8G8B8: Result:= D3DFMT_A8R8G8B8;
  apf_X8R8G8B8: Result:= D3DFMT_X8R8G8B8;
  apf_R5G6B5: Result:= D3DFMT_R5G6B5;
  apf_X1R5G5B5: Result:= D3DFMT_X1R5G5B5;
  apf_A1R5G5B5: Result:= D3DFMT_A1R5G5B5;
  apf_A4R4G4B4: Result:= D3DFMT_A4R4G4B4;
  apf_R3G3B2: Result:= D3DFMT_R3G3B2;
  apf_A8: Result:= D3DFMT_A8;
  apf_A8R3G3B2: Result:= D3DFMT_A8R3G3B2;
  apf_X4R4G4B4: Result:= D3DFMT_X4R4G4B4;
  apf_A2B10G10R10: Result:= D3DFMT_A2B10G10R10;
  apf_A8B8G8R8: Result:= D3DFMT_A8B8G8R8;
  apf_X8B8G8R8: Result:= D3DFMT_X8B8G8R8;
  apf_G16R16: Result:= D3DFMT_G16R16;
  apf_A2R10G10B10: Result:= D3DFMT_A2R10G10B10;
  apf_A16B16G16R16: Result:= D3DFMT_A16B16G16R16;
  apf_L8: Result:= D3DFMT_L8;
  apf_A8L8: Result:= D3DFMT_A8L8;
  apf_A4L4: Result:= D3DFMT_A4L4;
  apf_L16: Result:= D3DFMT_L16;
  apf_R16F: Result:= D3DFMT_R16F;
  apf_G16R16F: Result:= D3DFMT_G16R16F;
  apf_A16B16G16R16F: Result:= D3DFMT_A16B16G16R16F;
  apf_R32F: Result:= D3DFMT_R32F;
  apf_G32R32F: Result:= D3DFMT_G32R32F;
  apf_A32B32G32R32F: Result:= D3DFMT_A32B32G32R32F;

  else Result:= D3DFMT_UNKNOWN;
 end;
end;

//---------------------------------------------------------------------------
function DX9FindBackBufferFormat(Format: TAsphyrePixelFormat): D3DFORMAT;
var
 Supported : TAsphyreFormatList;
 ModeFormat: D3DFORMAT;
 Index     : Integer;
 Sample    : TAsphyrePixelFormat;
 TestFormat: D3DFORMAT;
begin
 Result:= D3DFMT_UNKNOWN;
 if (not Assigned(D3D9Object)) then Exit;

 if (Format = apf_Unknown) then Format:= apf_A8R8G8B8;

 ModeFormat:= D3D9DisplayMode.Format;
 if (ModeFormat = D3DFMT_UNKNOWN) then ModeFormat:= D3DFMT_X8R8G8B8;

 Supported:= TAsphyreFormatList.Create();

 for Index:= Low(BackBufferFormats) to High(BackBufferFormats) do
  begin
   Sample:= BackBufferFormats[Index];

   TestFormat:= AsphyreToDX9Format(Sample);
   if (TestFormat = D3DFMT_UNKNOWN) then Continue;

   if (not Succeeded(D3D9Object.CheckDeviceType(D3DADAPTER_DEFAULT,
    D3DDEVTYPE_HAL, ModeFormat, TestFormat, True))) then Continue;

   Supported.Insert(Sample);
  end;

 Result:= AsphyreToDX9Format(FindClosestFormat(Format, Supported));
 FreeAndNil(Supported);
end;

//---------------------------------------------------------------------------
function DX9FindDepthStencilFormat(StencilLevel: Integer): D3DFORMAT;
const
 FormatIndexes: array[0..1, 0..5] of Integer = ((3, 0, 1, 4, 5, 2),
  (0, 1, 2, 3, 4, 5));
var
 DisplayFormat: D3DFORMAT;
 Index : Integer;
 Format: D3DFORMAT;
begin
 Result:= D3DFMT_UNKNOWN;
 if (not Assigned(D3D9Object))or(StencilLevel < 1)or(StencilLevel > 2) then Exit;

 DisplayFormat:= D3D9DisplayMode.Format;
 if (DisplayFormat = D3DFMT_UNKNOWN) then DisplayFormat:= D3DFMT_X8R8G8B8;

 for Index:= 0 to 5 do
  begin
   Format:= DepthStencilFormats[FormatIndexes[StencilLevel - 1, Index]];

   if (Succeeded(D3D9Object.CheckDeviceFormat(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL,
    DisplayFormat, D3DUSAGE_DEPTHSTENCIL, D3DRTYPE_SURFACE, Format))) then
    begin
     Result:= Format;
     Exit;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure DX9FindBestMultisampleType(BackBufferFormat, DepthFormat: D3DFORMAT;
 Multisamples: Integer; out SampleType: D3DMULTISAMPLE_TYPE;
 out QualityLevel: Cardinal);
var
 TestSample: D3DMULTISAMPLE_TYPE;
 QuaLevels : Cardinal;
 Success: Boolean;
 i: Integer;
begin
 SampleType  := D3DMULTISAMPLE_NONE;
 QualityLevel:= 0;

 if (not Assigned(D3D9Object))or(Multisamples < 2) then Exit;

 for i:= Multisamples downto 2 do
  begin
   TestSample:= D3DMULTISAMPLE_TYPE(i);

   Success:= Succeeded(D3D9Object.CheckDeviceMultiSampleType(
    D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, BackBufferFormat, True, TestSample,
    @QuaLevels));

   if (Success)and(DepthFormat <> D3DFMT_UNKNOWN) then
    Success:= Succeeded(D3D9Object.CheckDeviceMultiSampleType(
     D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, DepthFormat, True, TestSample, nil));

   if (Success) then
    begin
     SampleType  := TestSample;
     QualityLevel:= QuaLevels - 1;
     Break;
    end;
  end;
end;

//---------------------------------------------------------------------------
function DX9FindTextureFormat(Format: TAsphyrePixelFormat;
 Usage: Cardinal): TAsphyrePixelFormat;
var
 DisplayFormat: D3DFORMAT;
 Supported    : TAsphyreFormatList;
 Sample       : TAsphyrePixelFormat;
 TestFormat   : D3DFORMAT;
begin
 Result:= apf_Unknown;
 if (not Assigned(D3D9Object)) then Exit;

 DisplayFormat:= D3D9DisplayMode.Format;
 if (DisplayFormat = D3DFMT_UNKNOWN) then DisplayFormat:= D3DFMT_X8R8G8B8;

 Supported:= TAsphyreFormatList.Create();

 for Sample:= Low(TAsphyrePixelFormat) to High(TAsphyrePixelFormat) do
  begin
   TestFormat:= AsphyreToDX9Format(Sample);
   if (TestFormat = D3DFMT_UNKNOWN) then Continue;

   if (Succeeded(D3D9Object.CheckDeviceFormat(D3DADAPTER_DEFAULT,
    D3DDEVTYPE_HAL, DisplayFormat, Usage, D3DRTYPE_TEXTURE, TestFormat))) then
    Supported.Insert(Sample);
  end;

 Result:= FindClosestFormat(Format, Supported);
 FreeAndNil(Supported);
end;

//---------------------------------------------------------------------------
function DX9FindTextureFormatEx(Format: TAsphyrePixelFormat;
 Usage1, Usage2: Cardinal): TAsphyrePixelFormat;
var
 DisplayFormat: D3DFORMAT;
 Supported    : TAsphyreFormatList;
 Sample       : TAsphyrePixelFormat;
 TestFormat   : D3DFORMAT;
begin
 Result:= apf_Unknown;
 if (not Assigned(D3D9Object)) then Exit;

 DisplayFormat:= D3D9DisplayMode.Format;
 if (DisplayFormat = D3DFMT_UNKNOWN) then DisplayFormat:= D3DFMT_X8R8G8B8;

 Supported:= TAsphyreFormatList.Create();

 for Sample:= Low(TAsphyrePixelFormat) to High(TAsphyrePixelFormat) do
  begin
   TestFormat:= AsphyreToDX9Format(Sample);
   if (TestFormat = D3DFMT_UNKNOWN) then Continue;

   if (Failed(D3D9Object.CheckDeviceFormat(D3DADAPTER_DEFAULT,
    D3DDEVTYPE_HAL, DisplayFormat, Usage1, D3DRTYPE_TEXTURE,
    TestFormat))) then Continue;

   if (Failed(D3D9Object.CheckDeviceFormat(D3DADAPTER_DEFAULT,
    D3DDEVTYPE_HAL, DisplayFormat, Usage2, D3DRTYPE_TEXTURE,
    TestFormat))) then Continue;

   Supported.Insert(Sample);
  end;

 Result:= FindClosestFormat(Format, Supported);
 FreeAndNil(Supported);
end;

//---------------------------------------------------------------------------
procedure ClearD3D9DisplayMode();
begin
 FillChar(D3D9DisplayMode, SizeOf(D3DDISPLAYMODEEX), 0);
 D3D9DisplayMode.Size:= SizeOf(D3DDISPLAYMODEEX);
end;

//---------------------------------------------------------------------------
procedure ClearD3D9PresentParams();
begin
 FillChar(D3D9PresentParams, SizeOf(D3DPRESENT_PARAMETERS), 0);
end;

//---------------------------------------------------------------------------
procedure ClearD3D9Caps();
begin
 FillChar(D3D9Caps, SizeOf(D3DCaps9), 0);
end;

//---------------------------------------------------------------------------
initialization
 ClearD3D9DisplayMode();
 ClearD3D9PresentParams();
 ClearD3D9Caps();

//---------------------------------------------------------------------------
finalization

//---------------------------------------------------------------------------
end.
