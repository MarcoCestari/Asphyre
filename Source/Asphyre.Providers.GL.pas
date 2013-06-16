unit Asphyre.Providers.GL;
//---------------------------------------------------------------------------
// OpenGL provider for Asphyre.
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
 idOpenGL = $2F000000;

//---------------------------------------------------------------------------
type
 TGLProvider = class(TAsphyreProvider)
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
 GLProvider: TGLProvider = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.SysUtils,
{$else}
 SysUtils,
{$endif}
 
{$ifdef FireMonkey}
 Asphyre.Devices.GL.FMX,
{$else}
{$ifdef Windows}
 Asphyre.Devices.GL.Win,
{$endif}
{$endif}

{$ifdef LegacyGL}
 Asphyre.Canvas.GL,
{$else}
 Asphyre.Canvas.GL2,
{$endif}

 Asphyre.Textures.GL;

//---------------------------------------------------------------------------
constructor TGLProvider.Create();
begin
 inherited;

 FProviderID:= idOpenGL;

 Factory.Subscribe(Self);
end;

//---------------------------------------------------------------------------
destructor TGLProvider.Destroy();
begin
 Factory.Unsubscribe(Self, True);

 inherited;
end;

//---------------------------------------------------------------------------
function TGLProvider.CreateDevice(): TAsphyreDevice;
begin
 Result:= TGLDevice.Create();
end;

//---------------------------------------------------------------------------
function TGLProvider.CreateCanvas(): TAsphyreCanvas;
begin
 Result:= TGLCanvas.Create();
end;

//---------------------------------------------------------------------------
function TGLProvider.CreateLockableTexture(): TAsphyreLockableTexture;
begin
 Result:= TGLLockableTexture.Create();
end;

//---------------------------------------------------------------------------
function TGLProvider.CreateRenderTargetTexture(
 ): TAsphyreRenderTargetTexture;
begin
 Result:= TGLRenderTargetTexture.Create();
end;

//---------------------------------------------------------------------------
initialization
 GLProvider:= TGLProvider.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(GLProvider);

//---------------------------------------------------------------------------
end.
