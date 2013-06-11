unit Asphyre.Providers.DX11;
//---------------------------------------------------------------------------
// DirectX 11 provider for Asphyre.
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
 Asphyre.Providers, Asphyre.Devices, Asphyre.Canvas, Asphyre.Textures;

//---------------------------------------------------------------------------
const
 idDirectX11 = $10000B00;

//---------------------------------------------------------------------------
type
 TDX11Provider = class(TAsphyreProvider)
 private
 public
  function CreateDevice(): TAsphyreDevice; override;
  function CreateCanvas(): TAsphyreCanvas; override;
  function CreateLockableTexture(): TAsphyreLockableTexture; override;
  function CreateRenderTargetTexture(): TAsphyreRenderTargetTexture; override;

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
 DX11Provider: TDX11Provider = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 System.SysUtils, Asphyre.Devices.DX11, Asphyre.Canvas.DX11, 
 Asphyre.Textures.DX11;

//---------------------------------------------------------------------------
constructor TDX11Provider.Create();
begin
 inherited;

 FProviderID:= idDirectX11;

 Factory.Subscribe(Self);
end;

//---------------------------------------------------------------------------
destructor TDX11Provider.Destroy();
begin
 Factory.Unsubscribe(Self, True);

 inherited;
end;

//---------------------------------------------------------------------------
function TDX11Provider.CreateDevice(): TAsphyreDevice;
begin
 Result:= TDX11Device.Create();
end;

//---------------------------------------------------------------------------
function TDX11Provider.CreateCanvas(): TAsphyreCanvas;
begin
 Result:= TDX11Canvas.Create();
end;

//---------------------------------------------------------------------------
function TDX11Provider.CreateLockableTexture(): TAsphyreLockableTexture;
begin
 Result:= TDX11LockableTexture.Create();
end;

//---------------------------------------------------------------------------
function TDX11Provider.CreateRenderTargetTexture(): TAsphyreRenderTargetTexture;
begin
 Result:= TDX11RenderTargetTexture.Create();
end;

//---------------------------------------------------------------------------
initialization
 DX11Provider:= TDX11Provider.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(DX11Provider);

//---------------------------------------------------------------------------
end.
