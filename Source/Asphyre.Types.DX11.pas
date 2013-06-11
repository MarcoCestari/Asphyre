unit Asphyre.Types.DX11;
//---------------------------------------------------------------------------
// Global Direct3D 11 types, variables and utilities.
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
 JSB.D3DCommon, JSB.DXGI, JSB.D3D11, Asphyre.TypeDef;

//---------------------------------------------------------------------------
var
// Global access to Direct3D 11 primary interfaces.
 DXGIFactory : IDXGIFactory1 = nil;
 D3D11Device : ID3D11Device = nil;
 D3D11Context: ID3D11DeviceContext = nil;

//---------------------------------------------------------------------------
// The following parameters provide low-level indication of Direct3D 11
// driver and feature level being currently used.
//---------------------------------------------------------------------------
 D3D11FeatureLevel: D3D_FEATURE_LEVEL = D3D_FEATURE_LEVEL_11_0;
 D3D11DriverType: D3D_DRIVER_TYPE = D3D_DRIVER_TYPE_NULL;

//---------------------------------------------------------------------------
// This structure holds information about the current viewport. It is used
// by the device, render targets and canvas.
//---------------------------------------------------------------------------
 D3D11Viewport: D3D11_VIEWPORT;

//---------------------------------------------------------------------------
function DX11CreateBasicBlendState(SrcBlend, DestBlend: D3D11_BLEND;
 out BlendState: ID3D11BlendState): Boolean;

//---------------------------------------------------------------------------
function DX11SetSimpleBlendState(const BlendState: ID3D11BlendState): Boolean;

//---------------------------------------------------------------------------
procedure DX11FindBestMultisampleType(Format: DXGI_FORMAT;
 Multisamples: Integer; out SampleCount, QualityLevel: Integer);

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Winapi.Windows, JSB.DXTypes, Asphyre.Types;

//---------------------------------------------------------------------------
function DX11CreateBasicBlendState(SrcBlend, DestBlend: D3D11_BLEND;
 out BlendState: ID3D11BlendState): Boolean;
var
 Desc: D3D11_BLEND_DESC;
begin
 if (not Assigned(D3D11Device)) then
  begin
   BlendState:= nil;
   Result:= False;
   Exit;
  end;

 FillChar(Desc, SizeOf(D3D11_BLEND_DESC), 0);

 Desc.RenderTarget[0].BlendEnable:= True;

 Desc.RenderTarget[0].SrcBlend := SrcBlend;
 Desc.RenderTarget[0].DestBlend:= DestBlend;
 Desc.RenderTarget[0].BlendOp  := D3D11_BLEND_OP_ADD;

 Desc.RenderTarget[0].SrcBlendAlpha := D3D11_BLEND_SRC_ALPHA;
 Desc.RenderTarget[0].DestBlendAlpha:= D3D11_BLEND_ONE;
 Desc.RenderTarget[0].BlendOpAlpha  := D3D11_BLEND_OP_ADD;

 Desc.RenderTarget[0].RenderTargetWriteMask:= Ord(D3D11_COLOR_WRITE_ENABLE_ALL);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D11Device.CreateBlendState(Desc, BlendState));
 finally
  PopFPUState();
 end;

 if (not Result) then BlendState:= nil;
end;

//---------------------------------------------------------------------------
function DX11SetSimpleBlendState(const BlendState: ID3D11BlendState): Boolean;
begin
 Result:= (Assigned(D3D11Context))and(Assigned(BlendState));
 if (not Result) then Exit;

 PushClearFPUState();
 try
  D3D11Context.OMSetBlendState(BlendState, ColorArray(1.0, 1.0, 1.0, 1.0),
   $FFFFFFFF);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure DX11FindBestMultisampleType(Format: DXGI_FORMAT;
 Multisamples: Integer; out SampleCount, QualityLevel: Integer);
var
 i, MaxSampleNo: Integer;
 QuaLevels: Cardinal;
begin
 SampleCount := 1;
 QualityLevel:= 0;

 if (not Assigned(D3D11Device))or(Multisamples < 2)or
  (Format = DXGI_FORMAT_UNKNOWN) then Exit;

 MaxSampleNo:= Min2(Multisamples, D3D11_MAX_MULTISAMPLE_SAMPLE_COUNT);

 PushClearFPUState();
 try
  for i:= MaxSampleNo downto 2 do
   begin
    if (Failed(D3D11Device.CheckMultisampleQualityLevels(Format, i,
     QuaLevels))) then Continue;

    if (QuaLevels > 0) then
     begin
      SampleCount := i;
      QualityLevel:= QuaLevels - 1;
      Break;
     end;
   end;
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
end.
