unit Asphyre.Types.GLES;
//---------------------------------------------------------------------------
// OpenGL ES types and helper utilities.
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
 Androidapi.Gles, Androidapi.Gles2, Androidapi.Gles2ext,
 {$ENDIF}
 Asphyre.Math;

//---------------------------------------------------------------------------
var
{ Indicates that the OpenGL ES rendering is made through normal process and
  not by using render targets. }
 GLES_UsingFrameBuffer: Boolean = False;

//---------------------------------------------------------------------------
function GLES_CreateNewTexture(out Texture: GLuint;
 Mipmapping: Boolean): Boolean;

//---------------------------------------------------------------------------
procedure GLES_DestroyTexture(var Texture: GLuint);

//---------------------------------------------------------------------------
function GLES_DefineTexture2D(Width, Height: Integer;
 SurfaceBits: Pointer = nil): Boolean;

//---------------------------------------------------------------------------
procedure GLES_GenerateTextureMipmaps();

//---------------------------------------------------------------------------
function GLES_UpdateTextureContents(Texture, Width, Height: Integer;
 SurfaceBits: Pointer; Level: Integer = 0): Boolean;

//---------------------------------------------------------------------------
procedure GLES_DisableTexture2D();

//---------------------------------------------------------------------------
function GLES_CreateFrameBuffer(out FrameBuffer: GLuint;
 Texture: GLuint): Boolean;

//---------------------------------------------------------------------------
function GLES_CreateDepthBuffer(Width, Height: Integer;
 out DepthBuffer: GLuint): Boolean;

//---------------------------------------------------------------------------
procedure GLES_ResetErrors();

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
function GLES_CreateNewTexture(out Texture: GLuint;
 Mipmapping: Boolean): Boolean;
begin
 glActiveTexture(GL_TEXTURE0);
 glGenTextures(1, @Texture);
 glBindTexture(GL_TEXTURE_2D, Texture);

 glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
 glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

 if (Mipmapping) then
  begin
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
    GL_LINEAR_MIPMAP_LINEAR);
  end else
  begin
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  end;

 Result:= (glGetError() = GL_NO_ERROR)and(Texture <> 0);
end;

//---------------------------------------------------------------------------
procedure GLES_DestroyTexture(var Texture: GLuint);
begin
 if (Texture <> 0) then
  begin
   GLES_DisableTexture2D();

   glDeleteTextures(1, @Texture);
  end;
end;

//---------------------------------------------------------------------------
function GLES_DefineTexture2D(Width, Height: Integer;
 SurfaceBits: Pointer): Boolean;
begin
 Result:= (Width > 0)and(Height > 0);
 if (not Result) then Exit;

 glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Width, Height, 0, GL_BGRA_EXT,
  GL_UNSIGNED_BYTE, SurfaceBits);

 Result:= glGetError() = GL_NO_ERROR;
end;

//---------------------------------------------------------------------------
procedure GLES_GenerateTextureMipmaps();
begin
 glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
 glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
 glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
 glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
 glGenerateMipmap(GL_TEXTURE_2D);
end;

//---------------------------------------------------------------------------
function GLES_UpdateTextureContents(Texture, Width, Height: Integer;
 SurfaceBits: Pointer; Level: Integer = 0): Boolean;
begin
 Result:= (Texture <> 0)and(Width > 0)and(Height > 0)and(Assigned(SurfaceBits));
 if (not Result) then Exit;

 glActiveTexture(GL_TEXTURE0);
 glBindTexture(GL_TEXTURE_2D, Texture);

 glTexSubImage2D(GL_TEXTURE_2D, Level, 0, 0, Width, Height, GL_BGRA_EXT,
  GL_UNSIGNED_BYTE, SurfaceBits);

 Result:= glGetError() = GL_NO_ERROR;
end;

//---------------------------------------------------------------------------
procedure GLES_DisableTexture2D();
begin
 glBindTexture(GL_TEXTURE_2D, 0);
end;

//---------------------------------------------------------------------------
function GLES_CreateFrameBuffer(out FrameBuffer: GLuint;
 Texture: GLuint): Boolean;
begin
 glGenFramebuffers(1, @FrameBuffer);
 glBindFramebuffer(GL_FRAMEBUFFER, FrameBuffer);

 Result:= (glGetError() = GL_NO_ERROR)and(FrameBuffer <> 0);
 if (not Result) then
  begin
   glBindFramebuffer(GL_FRAMEBUFFER, 0);
   Exit;
  end;

 if (Texture <> 0) then
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
   Texture, 0);
end;

//---------------------------------------------------------------------------
function GLES_CreateDepthBuffer(Width, Height: Integer;
 out DepthBuffer: GLuint): Boolean;
begin
 glGenRenderbuffers(1, @DepthBuffer);
 glBindRenderbuffer(GL_RENDERBUFFER, DepthBuffer);

 glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, Width, Height);

 glBindRenderbuffer(GL_RENDERBUFFER, 0);

 Result:= (glGetError() = GL_NO_ERROR)and(DepthBuffer <> 0);
 if (not Result) then Exit;

 glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
  GL_RENDERBUFFER, DepthBuffer);

 Result:= glGetError() = GL_NO_ERROR;
end;

//---------------------------------------------------------------------------
procedure GLES_ResetErrors();
const
 MaxErrors = 16;
var
 i: Integer;
begin
 i:= MaxErrors;

 while (i > 0)and(glGetError() <> GL_NO_ERROR) do
  Dec(i);
end;

//---------------------------------------------------------------------------
end.
