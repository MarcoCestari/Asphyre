unit Asphyre.Providers.GLES;
//---------------------------------------------------------------------------
// OpenGL ES provider for Asphyre.
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
 idOpenGL_ES = $2F000000;

//---------------------------------------------------------------------------
type
 TGLESProvider = class(TAsphyreProvider)
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
 GLESProvider: TGLESProvider = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 System.SysUtils, Asphyre.Textures.GLES, Asphyre.Canvas.GLES, 
 Asphyre.Devices.GLES;

//---------------------------------------------------------------------------
constructor TGLESProvider.Create();
begin
 inherited;

 FProviderID:= idOpenGL_ES;

 Factory.Subscribe(Self);
end;

//---------------------------------------------------------------------------
destructor TGLESProvider.Destroy();
begin
 Factory.Unsubscribe(Self, True);

 inherited;
end;

//---------------------------------------------------------------------------
function TGLESProvider.CreateDevice(): TAsphyreDevice;
begin
 Result:= TGLESDevice.Create();
end;

//---------------------------------------------------------------------------
function TGLESProvider.CreateCanvas(): TAsphyreCanvas;
begin
 Result:= TGLESCanvas.Create();
end;

//---------------------------------------------------------------------------
function TGLESProvider.CreateLockableTexture(): TAsphyreLockableTexture;
begin
 Result:= TGLESLockableTexture.Create();
end;

//---------------------------------------------------------------------------
function TGLESProvider.CreateRenderTargetTexture(
 ): TAsphyreRenderTargetTexture;
begin
 Result:= TGLESRenderTargetTexture.Create();
end;

//---------------------------------------------------------------------------
initialization
 GLESProvider:= TGLESProvider.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(GLESProvider);

//---------------------------------------------------------------------------
end.
