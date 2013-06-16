unit Asphyre.Textures.GL;
//---------------------------------------------------------------------------
// OpenGL texture implementation.
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
{$ifdef FireMonkey}
 Macapi.CocoaTypes, Macapi.OpenGL
{$else}
 Asphyre.GL
{$endif},

{$ifndef fpc}
 System.Types,
{$else}
 Types,
{$endif}
 Asphyre.TypeDef, Asphyre.Types, Asphyre.Textures,
 Asphyre.Surfaces;

//---------------------------------------------------------------------------
type
 TGLLockableTexture = class(TAsphyreLockableTexture)
 private
  FSurface: TSystemSurface;
  FTexture: GLuint;

  function CreateTextureSurface(): Boolean;
  procedure DestroyTextureSurface();
 protected
  procedure UpdateSize(); override;

  function CreateTexture(): Boolean; override;
  procedure DestroyTexture(); override;
 public
  property Surface: TSystemSurface read FSurface;

  property Texture: GLuint read FTexture;

  procedure Lock(const Rect: TRect; out Bits: Pointer;
   out Pitch: Integer); override;
  procedure Unlock(); override;

  procedure Bind(Stage: Integer); override;

  constructor Create(); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TGLRenderTargetTexture = class(TAsphyreRenderTargetTexture)
 private
  FTexture: GLuint;
  FFrameBuffer: GLuint;
  FDepthBuffer: GLuint;

  function CreateTextureSurface(): Boolean;
  function CreateFrameObjects(): Boolean;
  function CreateTextureInstance(): Boolean;
  procedure DestroyTextureInstance();
 protected
  procedure UpdateSize(); override;

  function CreateTexture(): Boolean; override;
  procedure DestroyTexture(); override;
 public
  property Texture: GLuint read FTexture;

  property FrameBuffer: GLuint read FFrameBuffer;
  property DepthBuffer: GLuint read FDepthBuffer;

  procedure Bind(Stage: Integer); override;

  function BeginDrawTo(): Boolean; override;
  procedure EndDrawTo(); override;

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.SysUtils,
{$else}
 SysUtils,
{$endif}
 Asphyre.Formats, Asphyre.Types.GL;

//---------------------------------------------------------------------------
constructor TGLLockableTexture.Create();
begin
 inherited;

 FSurface:= TSystemSurface.Create();
 FTexture:= 0;
end;

//---------------------------------------------------------------------------
destructor TGLLockableTexture.Destroy();
begin
 FreeAndNil(FSurface);

 inherited;
end;

//---------------------------------------------------------------------------
function TGLLockableTexture.CreateTextureSurface(): Boolean;
begin
 Result:= GL_CreateNewTexture(FTexture, Mipmapping);
 if (not Result) then Exit;

 Result:= GL_DefineTexture2D(Width, Height, FSurface.Bits);
 if (not Result) then Exit;

 if (Mipmapping) then GL_GenerateTextureMipmaps();

 GL_DisableTexture2D();
end;

//---------------------------------------------------------------------------
procedure TGLLockableTexture.DestroyTextureSurface();
begin
 GL_DestroyTexture(FTexture);
end;

//---------------------------------------------------------------------------
function TGLLockableTexture.CreateTexture(): Boolean;
begin
 FFormat:= apf_A8R8G8B8;

 FSurface.SetSize(Width, Height);
 FSurface.Clear($FF000000);

 Result:= CreateTextureSurface();
end;

//---------------------------------------------------------------------------
procedure TGLLockableTexture.DestroyTexture();
begin
 DestroyTextureSurface();
end;

//---------------------------------------------------------------------------
procedure TGLLockableTexture.UpdateSize();
begin
 DestroyTextureSurface();
 CreateTextureSurface();
end;

//---------------------------------------------------------------------------
procedure TGLLockableTexture.Bind(Stage: Integer);
begin
 glBindTexture(GL_TEXTURE_2D, FTexture);
end;

//---------------------------------------------------------------------------
procedure TGLLockableTexture.Lock(const Rect: TRect; out Bits: Pointer;
 out Pitch: Integer);
begin
 Bits := nil;
 Pitch:= 0;
 if (FTexture = 0) then Exit;

 if (FSurface.Width < 1)or(FSurface.Height < 1)or(Rect.Left < 0)or
  (Rect.Top < 0)or(Rect.Right > FSurface.Width)or
  (Rect.Bottom > FSurface.Height) then
  begin
   Bits := nil;
   Pitch:= 0;
   Exit;
  end;

 Pitch:= FSurface.Width * 4;

 Bits:= Pointer(PtrInt(FSurface.Bits) + (PtrInt(Pitch) * Rect.Top) +
  (PtrInt(Rect.Left) * 4));
end;

//---------------------------------------------------------------------------
procedure TGLLockableTexture.Unlock();
begin
 if (FTexture = 0)or(FSurface.Width < 1)or(FSurface.Height < 1) then Exit;

 GL_UpdateTextureContents(FTexture, FSurface.Width, FSurface.Height,
  FSurface.Bits);

 if (Mipmapping) then GL_GenerateTextureMipmaps();

 GL_DisableTexture2D();
end;

//---------------------------------------------------------------------------
constructor TGLRenderTargetTexture.Create();
begin
 inherited;

 FTexture:= 0;
 FFrameBuffer:= 0;
 FDepthBuffer:= 0;
end;

//---------------------------------------------------------------------------
function TGLRenderTargetTexture.CreateTextureSurface(): Boolean;
begin
 Result:= GL_CreateNewTexture(FTexture, Mipmapping);
 if (not Result) then Exit;

 Result:= GL_DefineTexture2D(Width, Height);
 if (not Result) then Exit;

 if (Mipmapping) then GL_GenerateTextureMipmaps();

 GL_DisableTexture2D();
end;

//---------------------------------------------------------------------------
function TGLRenderTargetTexture.CreateFrameObjects(): Boolean;
begin
 Result:= GL_CreateFrameBuffer(FFrameBuffer, FTexture);
 if (not Result) then Exit;

 if (DepthStencil) then
  begin
   Result:= GL_CreateDepthBuffer(Width, Height, FDepthBuffer);

   if (not Result) then
    begin
     glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
     Exit;
    end;
  end;

 if (Result) then
  begin
   Result:= glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT) =
    GL_FRAMEBUFFER_COMPLETE_EXT;
  end;

 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
end;

//---------------------------------------------------------------------------
function TGLRenderTargetTexture.CreateTextureInstance(): Boolean;
begin
 Result:= CreateTextureSurface();
 if (not Result) then Exit;

 Result:= CreateFrameObjects();
end;

//---------------------------------------------------------------------------
procedure TGLRenderTargetTexture.DestroyTextureInstance();
begin
 glBindTexture(GL_TEXTURE_2D, 0);
 glDisable(GL_TEXTURE_2D);

 if (FDepthBuffer <> 0) then glDeleteRenderbuffersEXT(1, @FDepthBuffer);
 if (FFrameBuffer <> 0) then glDeleteFramebuffersEXT(1, @FFrameBuffer);

 if (FTexture <> 0) then glDeleteTextures(1, @FTexture);
end;

//---------------------------------------------------------------------------
function TGLRenderTargetTexture.CreateTexture(): Boolean;
begin
 Result:= GL_EXT_framebuffer_object;
 if (not Result) then Exit;

 FFormat:= apf_A8R8G8B8;

 Result:= CreateTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TGLRenderTargetTexture.DestroyTexture();
begin
 DestroyTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TGLRenderTargetTexture.Bind(Stage: Integer);
begin
 glBindTexture(GL_TEXTURE_2D, FTexture);
end;

//---------------------------------------------------------------------------
function TGLRenderTargetTexture.BeginDrawTo(): Boolean;
begin
 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, FFrameBuffer);
 glViewport(0, 0, Width, Height);

 Result:= glGetError() = GL_NO_ERROR;
end;

//---------------------------------------------------------------------------
procedure TGLRenderTargetTexture.EndDrawTo();
begin
 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

 if (Mipmapping) then
  begin
   glActiveTexture(GL_TEXTURE0);
   glEnable(GL_TEXTURE_2D);
   glBindTexture(GL_TEXTURE_2D, FTexture);

   GL_GenerateTextureMipmaps();
   GL_DisableTexture2D();
  end;
end;

//---------------------------------------------------------------------------
procedure TGLRenderTargetTexture.UpdateSize();
begin
 DestroyTextureInstance();
 CreateTextureInstance();
end;

//---------------------------------------------------------------------------
end.
