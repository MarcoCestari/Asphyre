unit Asphyre.Textures.GLES;
//---------------------------------------------------------------------------
// OpenGL ES texture implementation.
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
 {$IFDEF IOS}
 iOSapi.GLES,
 {$ELSE}
 Androidapi.Gles2,
 {$ENDIF}
 System.Types, System.SysUtils, Asphyre.TypeDef,
 Asphyre.Types, Asphyre.Textures, Asphyre.Surfaces;

//---------------------------------------------------------------------------
type
 TGLESLockableTexture = class(TAsphyreLockableTexture)
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
 TGLESRenderTargetTexture = class(TAsphyreRenderTargetTexture)
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
 Asphyre.Formats, Asphyre.Types.GLES;

//---------------------------------------------------------------------------
constructor TGLESLockableTexture.Create();
begin
 inherited;

 FSurface:= TSystemSurface.Create();
 FTexture:= 0;
end;

//---------------------------------------------------------------------------
destructor TGLESLockableTexture.Destroy();
begin
 FreeAndNil(FSurface);

 inherited;
end;

//---------------------------------------------------------------------------
function TGLESLockableTexture.CreateTextureSurface(): Boolean;
begin
 Result:= GLES_CreateNewTexture(FTexture, Mipmapping);
 if (not Result) then Exit;

 Result:= GLES_DefineTexture2D(Width, Height, FSurface.Bits);
 if (not Result) then Exit;

 if (Mipmapping) then GLES_GenerateTextureMipmaps();

 GLES_DisableTexture2D();
end;

//---------------------------------------------------------------------------
procedure TGLESLockableTexture.DestroyTextureSurface();
begin
 GLES_DestroyTexture(FTexture);
end;

//---------------------------------------------------------------------------
function TGLESLockableTexture.CreateTexture(): Boolean;
begin
 FFormat:= apf_A8R8G8B8;

 FSurface.SetSize(Width, Height);
 FSurface.Clear($FF000000);

 Result:= CreateTextureSurface();
end;

//---------------------------------------------------------------------------
procedure TGLESLockableTexture.DestroyTexture();
begin
 DestroyTextureSurface();
end;

//---------------------------------------------------------------------------
procedure TGLESLockableTexture.UpdateSize();
begin
 DestroyTextureSurface();
 CreateTextureSurface();
end;

//---------------------------------------------------------------------------
procedure TGLESLockableTexture.Bind(Stage: Integer);
begin
 glBindTexture(GL_TEXTURE_2D, FTexture);
end;

//---------------------------------------------------------------------------
procedure TGLESLockableTexture.Lock(const Rect: TRect; out Bits: Pointer;
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
procedure TGLESLockableTexture.Unlock();
begin
 if (FTexture = 0)or(FSurface.Width < 1)or(FSurface.Height < 1) then Exit;

 GLES_UpdateTextureContents(FTexture, FSurface.Width, FSurface.Height,
  FSurface.Bits);

 if (Mipmapping) then GLES_GenerateTextureMipmaps();

 GLES_DisableTexture2D();
end;

//---------------------------------------------------------------------------
constructor TGLESRenderTargetTexture.Create();
begin
 inherited;

 FTexture:= 0;
 FFrameBuffer:= 0;
 FDepthBuffer:= 0;
end;

//---------------------------------------------------------------------------
function TGLESRenderTargetTexture.CreateTextureSurface(): Boolean;
begin
 Result:= GLES_CreateNewTexture(FTexture, Mipmapping);
 if (not Result) then Exit;

 Result:= GLES_DefineTexture2D(Width, Height);
 if (not Result) then Exit;

 if (Mipmapping) then GLES_GenerateTextureMipmaps();

 GLES_DisableTexture2D();
end;

//---------------------------------------------------------------------------
function TGLESRenderTargetTexture.CreateFrameObjects(): Boolean;
begin
 Result:= GLES_CreateFrameBuffer(FFrameBuffer, FTexture);
 if (not Result) then Exit;

 if (DepthStencil) then
  begin
   Result:= GLES_CreateDepthBuffer(Width, Height, FDepthBuffer);

   if (not Result) then
    begin
     glBindFramebuffer(GL_FRAMEBUFFER, 0);
     Exit;
    end;
  end;

 if (Result) then
  begin
   Result:= glCheckFramebufferStatus(GL_FRAMEBUFFER) =
    GL_FRAMEBUFFER_COMPLETE;
  end;

 glBindFramebuffer(GL_FRAMEBUFFER, 0);
end;

//---------------------------------------------------------------------------
function TGLESRenderTargetTexture.CreateTextureInstance(): Boolean;
begin
 Result:= CreateTextureSurface();
 if (not Result) then Exit;

 Result:= CreateFrameObjects();
end;

//---------------------------------------------------------------------------
procedure TGLESRenderTargetTexture.DestroyTextureInstance();
begin
 glBindTexture(GL_TEXTURE_2D, 0);

 if (FDepthBuffer <> 0) then glDeleteRenderbuffers(1, @FDepthBuffer);
 if (FFrameBuffer <> 0) then glDeleteFramebuffers(1, @FFrameBuffer);

 if (FTexture <> 0) then glDeleteTextures(1, @FTexture);
end;

//---------------------------------------------------------------------------
function TGLESRenderTargetTexture.CreateTexture(): Boolean;
begin
 FFormat:= apf_A8R8G8B8;

 Result:= CreateTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TGLESRenderTargetTexture.DestroyTexture();
begin
 DestroyTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TGLESRenderTargetTexture.Bind(Stage: Integer);
begin
 glBindTexture(GL_TEXTURE_2D, FTexture);
end;

//---------------------------------------------------------------------------
function TGLESRenderTargetTexture.BeginDrawTo(): Boolean;
begin
 glBindFramebuffer(GL_FRAMEBUFFER, FFrameBuffer);
 glViewport(0, 0, Width, Height);

 Result:= glGetError() = GL_NO_ERROR;
end;

//---------------------------------------------------------------------------
procedure TGLESRenderTargetTexture.EndDrawTo();
begin
 glBindFramebuffer(GL_FRAMEBUFFER, 0);

 if (Mipmapping) then
  begin
   glActiveTexture(GL_TEXTURE0);
   glEnable(GL_TEXTURE_2D);
   glBindTexture(GL_TEXTURE_2D, FTexture);

   GLES_GenerateTextureMipmaps();
   GLES_DisableTexture2D();
  end;
end;

//---------------------------------------------------------------------------
procedure TGLESRenderTargetTexture.UpdateSize();
begin
 DestroyTextureInstance();
 CreateTextureInstance();
end;

//---------------------------------------------------------------------------
end.
