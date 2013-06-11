unit Asphyre.Providers.DX10;
//---------------------------------------------------------------------------
// DirectX 10 provider for Asphyre.
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
 Asphyre.Providers, Asphyre.Devices, Asphyre.Canvas, Asphyre.Textures;

//---------------------------------------------------------------------------
const
 idDirectX10 = $10000A00;

//---------------------------------------------------------------------------
type
 TDX10Provider = class(TAsphyreProvider)
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
 DX10Provider: TDX10Provider = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 System.SysUtils, Asphyre.Textures.DX10, Asphyre.Canvas.DX10, 
 Asphyre.Devices.DX10;

//---------------------------------------------------------------------------
constructor TDX10Provider.Create();
begin
 inherited;

 FProviderID:= idDirectX10;

 Factory.Subscribe(Self);
end;

//---------------------------------------------------------------------------
destructor TDX10Provider.Destroy();
begin
 Factory.Unsubscribe(Self, True);

 inherited;
end;

//---------------------------------------------------------------------------
function TDX10Provider.CreateDevice(): TAsphyreDevice;
begin
 Result:= TDX10Device.Create();
end;

//---------------------------------------------------------------------------
function TDX10Provider.CreateCanvas(): TAsphyreCanvas;
begin
 Result:= TDX10Canvas.Create();
end;

//---------------------------------------------------------------------------
function TDX10Provider.CreateLockableTexture(): TAsphyreLockableTexture;
begin
 Result:= TDX10LockableTexture.Create();
end;

//---------------------------------------------------------------------------
function TDX10Provider.CreateRenderTargetTexture(): TAsphyreRenderTargetTexture;
begin
 Result:= TDX10RenderTargetTexture.Create();
end;

//---------------------------------------------------------------------------
initialization
 DX10Provider:= TDX10Provider.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(DX10Provider);

//---------------------------------------------------------------------------
end.
