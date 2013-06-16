unit Asphyre.Providers.DX7;
//---------------------------------------------------------------------------
// DirectX 7.0 support provider.
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
 idDirectX7 = $10000700;

//---------------------------------------------------------------------------
type
 TDX7Provider = class(TAsphyreProvider)
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
 DX7Provider: TDX7Provider = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.SysUtils,
{$else}
 SysUtils,
{$endif}
 Asphyre.Devices.DX7, Asphyre.Canvas.DX7,
 Asphyre.Textures.DX7;

//---------------------------------------------------------------------------
constructor TDX7Provider.Create();
begin
 inherited;

 FProviderID:= idDirectX7;

 Factory.Subscribe(Self);
end;

//---------------------------------------------------------------------------
destructor TDX7Provider.Destroy();
begin
 Factory.Unsubscribe(Self, True);

 inherited;
end;

//---------------------------------------------------------------------------
function TDX7Provider.CreateDevice(): TAsphyreDevice;
begin
 Result:= TDX7Device.Create();
end;

//---------------------------------------------------------------------------
function TDX7Provider.CreateCanvas(): TAsphyreCanvas;
begin
 Result:= TDX7Canvas.Create();
end;

//---------------------------------------------------------------------------
function TDX7Provider.CreateLockableTexture(): TAsphyreLockableTexture;
begin
 Result:= TDX7LockableTexture.Create();
end;

//---------------------------------------------------------------------------
function TDX7Provider.CreateRenderTargetTexture(): TAsphyreRenderTargetTexture;
begin
 Result:= TDX7RenderTargetTexture.Create();
end;

//---------------------------------------------------------------------------
initialization
 DX7Provider:= TDX7Provider.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(DX7Provider);

//---------------------------------------------------------------------------
end.
