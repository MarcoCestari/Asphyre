unit Asphyre.Types.DX10;
//---------------------------------------------------------------------------
// DirectX 10.x general type definitions and utilities.
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
{$ifndef fpc}
 Winapi.Windows,
{$else}
 Windows,
{$endif}
 JSB.DXGI, JSB.D3D10, JSB.D3D10_1, Asphyre.TypeDef;

//---------------------------------------------------------------------------
type
 TDirect3D10Mode = (dmUnknown, dmDirectX10, dmDirectX10_1);

//---------------------------------------------------------------------------
 TDXGIDirect3DMode = (ddmUnknown, ddmDXGI10, ddmDXGI11);

//---------------------------------------------------------------------------
 TDirect3D10DriverType = (dtUnknown, dtHardware, dtSoftware);
 TDirect3D10FeatureLevel = (flUnknown, flDirectX10, flDirectX10_1);

//---------------------------------------------------------------------------
// The following variables are declared as globals. The global declaration,
// although generally avoided, in this case decreases the coupling of DX 10
// provider classes.
//---------------------------------------------------------------------------
var
 D3D10Mode: TDirect3D10Mode = dmUnknown;
 DXGIMode : TDXGIDirect3DMode = ddmUnknown;

//---------------------------------------------------------------------------
 D3D10DriverType: TDirect3D10DriverType = dtUnknown;
 D3D10FeatureLevel: TDirect3D10FeatureLevel = flUnknown;

//---------------------------------------------------------------------------
 DXGIFactory: IDXGIFactory = nil;
 D3D10Device: ID3D10Device = nil;

//---------------------------------------------------------------------------
// This structure holds information about the current viewport. It is used
// by the device, render targets and canvas.
//---------------------------------------------------------------------------
 D3D10Viewport: D3D10_VIEWPORT;

//---------------------------------------------------------------------------
// The following variables hold information about the current render target
// and depth-stencil buffer. They are set by the device and render targets.
//---------------------------------------------------------------------------
 ActiveRenderTargetView: ID3D10RenderTargetView = nil;
 ActiveDepthStencilView: ID3D10DepthStencilView = nil;

//---------------------------------------------------------------------------
function DX10CreateBasicBlendState(SrcBlend, DestBlend: TD3D10_Blend;
 out BlendState: ID3D10BlendState): Boolean;

//---------------------------------------------------------------------------
function DX10CreateBasicBlendState1(SrcBlend, DestBlend: D3D10_BLEND;
 out BlendState: ID3D10BlendState1): Boolean;

//---------------------------------------------------------------------------
function DX10SetSimpleBlendState(const BlendState: ID3D10BlendState): Boolean;

//---------------------------------------------------------------------------
function DX10SetSimpleBlendState1(const BlendState: ID3D10BlendState1): Boolean;

//---------------------------------------------------------------------------
procedure DX10FindBestMultisampleType(Format: DXGI_FORMAT;
 Multisamples: Integer; out SampleCount, QualityLevel: Integer);

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 JSB.DXTypes, Asphyre.Types;

//---------------------------------------------------------------------------
function DX10CreateBasicBlendState(SrcBlend, DestBlend: TD3D10_Blend;
 out BlendState: ID3D10BlendState): Boolean;
var
 Desc: D3D10_BLEND_DESC;
begin
 if (not Assigned(D3D10Device)) then
  begin
   BlendState:= nil;
   Result:= False;
   Exit;
  end;

 FillChar(Desc, SizeOf(D3D10_BLEND_DESC), 0);

 Desc.BlendEnable[0]:= True;

 Desc.SrcBlend := SrcBlend;
 Desc.DestBlend:= DestBlend;
 Desc.BlendOp  := D3D10_BLEND_OP_ADD;

 Desc.SrcBlendAlpha := D3D10_BLEND_SRC_ALPHA;
 Desc.DestBlendAlpha:= D3D10_BLEND_ONE;
 Desc.BlendOpAlpha  := D3D10_BLEND_OP_ADD;

 Desc.RenderTargetWriteMask[0]:= Ord(D3D10_COLOR_WRITE_ENABLE_ALL);

 PushClearFPUState();
 try
  Result:= Succeeded(D3D10Device.CreateBlendState(Desc, BlendState));
 finally
  PopFPUState();
 end;

 if (not Result) then BlendState:= nil;
end;

//---------------------------------------------------------------------------
function DX10CreateBasicBlendState1(SrcBlend, DestBlend: D3D10_BLEND;
 out BlendState: ID3D10BlendState1): Boolean;
var
 Desc: D3D10_BLEND_DESC1;
begin
 if (not Assigned(D3D10Device))or(D3D10Mode < dmDirectX10_1) then
  begin
   BlendState:= nil;
   Result:= False;
   Exit;
  end;

 FillChar(Desc, SizeOf(D3D10_BLEND_DESC1), 0);

 Desc.RenderTarget[0].BlendEnable:= True;

 Desc.RenderTarget[0].SrcBlend := SrcBlend;
 Desc.RenderTarget[0].DestBlend:= DestBlend;
 Desc.RenderTarget[0].BlendOp  := D3D10_BLEND_OP_ADD;

 Desc.RenderTarget[0].SrcBlendAlpha := D3D10_BLEND_SRC_ALPHA;
 Desc.RenderTarget[0].DestBlendAlpha:= D3D10_BLEND_ONE;
 Desc.RenderTarget[0].BlendOpAlpha  := D3D10_BLEND_OP_ADD;

 Desc.RenderTarget[0].RenderTargetWriteMask:= Ord(D3D10_COLOR_WRITE_ENABLE_ALL);

 PushClearFPUState();
 try
  Result:= Succeeded(ID3D10Device1(D3D10Device).CreateBlendState1(Desc,
   BlendState));
 finally
  PopFPUState();
 end;

 if (not Result) then BlendState:= nil;
end;

//---------------------------------------------------------------------------
function DX10SetSimpleBlendState(const BlendState: ID3D10BlendState): Boolean;
begin
 Result:= (Assigned(D3D10Device))and(Assigned(BlendState));
 if (not Result) then Exit;

 PushClearFPUState();
 try
  D3D10Device.OMSetBlendState(BlendState, ColorArray(1.0, 1.0, 1.0, 1.0),
   $FFFFFFFF);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
function DX10SetSimpleBlendState1(const BlendState: ID3D10BlendState1): Boolean;
begin
 Result:= (Assigned(D3D10Device))and(Assigned(BlendState))and
  (D3D10Mode >= dmDirectX10_1);
 if (not Result) then Exit;

 PushClearFPUState();
 try
  D3D10Device.OMSetBlendState(BlendState, ColorArray(1.0, 1.0, 1.0, 1.0),
   $FFFFFFFF);
 finally
  PopFPUState();
 end;
end;

//---------------------------------------------------------------------------
procedure DX10FindBestMultisampleType(Format: DXGI_FORMAT;
 Multisamples: Integer; out SampleCount, QualityLevel: Integer);
var
 i, MaxSampleNo: Integer;
 QuaLevels: Cardinal;
begin
 SampleCount := 1;
 QualityLevel:= 0;

 if (not Assigned(D3D10Device))or(Multisamples < 2)or
  (Format = DXGI_FORMAT_UNKNOWN) then Exit;

 MaxSampleNo:= Min2(Multisamples, D3D10_MAX_MULTISAMPLE_SAMPLE_COUNT);

 PushClearFPUState();

 try
  for i:= MaxSampleNo downto 2 do
   begin
    if (Failed(D3D10Device.CheckMultisampleQualityLevels(Format, i,
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
initialization
 FillChar(D3D10Viewport, SizeOf(D3D10_VIEWPORT), 0);

//---------------------------------------------------------------------------
end.
