unit Asphyre.Providers.DX9;
//---------------------------------------------------------------------------
// Direct3D 9 provider for Asphyre.
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
 System.SysUtils, Asphyre.Providers, Asphyre.Devices, Asphyre.Canvas,
 Asphyre.Textures;

//---------------------------------------------------------------------------
const
 idDirectX9 = $10000900;

//---------------------------------------------------------------------------
type
 TDX9Provider = class(TAsphyreProvider)
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
 DX9Provider: TDX9Provider = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Textures.DX9, Asphyre.Canvas.DX9, Asphyre.Devices.DX9;

//---------------------------------------------------------------------------
constructor TDX9Provider.Create();
begin
 inherited;

 FProviderID:= idDirectX9;

 Factory.Subscribe(Self);
end;

//---------------------------------------------------------------------------
destructor TDX9Provider.Destroy();
begin
 Factory.Unsubscribe(Self, True);

 inherited;
end;

//---------------------------------------------------------------------------
function TDX9Provider.CreateDevice(): TAsphyreDevice;
begin
 Result:= TDX9Device.Create();
end;

//---------------------------------------------------------------------------
function TDX9Provider.CreateCanvas(): TAsphyreCanvas;
begin
 Result:= TDX9Canvas.Create();
end;

//---------------------------------------------------------------------------
function TDX9Provider.CreateLockableTexture(): TAsphyreLockableTexture;
begin
 Result:= TDX9LockableTexture.Create();
end;

//---------------------------------------------------------------------------
function TDX9Provider.CreateRenderTargetTexture(): TAsphyreRenderTargetTexture;
begin
 Result:= TDX9RenderTargetTexture.Create();
end;

//---------------------------------------------------------------------------
initialization
 DX9Provider:= TDX9Provider.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(DX9Provider);

//---------------------------------------------------------------------------
end.
