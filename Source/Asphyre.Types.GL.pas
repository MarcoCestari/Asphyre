unit Asphyre.Types.GL;
//---------------------------------------------------------------------------
// OpenGL types and helper utilities.
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
{$endif};

//---------------------------------------------------------------------------
var
// Indicates that the OpenGL rendering is made through normal process and not
// by using render targets.
 GL_UsingFrameBuffer: Boolean = False;

//---------------------------------------------------------------------------
function GetOpenGLTechVersion(): Integer;

//---------------------------------------------------------------------------
function GL_CreateNewTexture(out Texture: GLuint;
 Mipmapping: Boolean): Boolean;

//---------------------------------------------------------------------------
procedure GL_DestroyTexture(var Texture: GLuint);

//---------------------------------------------------------------------------
function GL_DefineTexture2D(Width, Height: Integer;
 SurfaceBits: Pointer = nil): Boolean;

//---------------------------------------------------------------------------
procedure GL_GenerateTextureMipmaps();

//---------------------------------------------------------------------------
function GL_UpdateTextureContents(Texture, Width, Height: Integer;
 SurfaceBits: Pointer; Level: Integer = 0): Boolean;

//---------------------------------------------------------------------------
procedure GL_DisableTexture2D();

//---------------------------------------------------------------------------
function GL_CreateFrameBuffer(out FrameBuffer: GLuint;
 Texture: GLuint): Boolean;

//---------------------------------------------------------------------------
function GL_CreateDepthBuffer(Width, Height: Integer;
 out DepthBuffer: GLuint): Boolean;

//---------------------------------------------------------------------------
{$ifdef FireMonkey}
// FireMonkey has several incompatible methods and data types in its header
// translation (Macapi.CocoaTypes.pas and Macapi.OpenGL.pas), so this section
// provides compatible replacements for Asphyre components to work properly.
procedure glBufferData(Target: Cardinal; Size: Integer; Data: Pointer;
 Usage: Cardinal);

//...........................................................................
procedure glBufferSubData(Target: Cardinal; Offset: Pointer; Size: Integer;
 Data: Pointer);

//...........................................................................
procedure glVertexAttribPointer(Index: Cardinal; Size: Integer;
 AType: Cardinal; Normalized: Boolean; Stride: Integer; Data: Pointer);

//...........................................................................
type
 PPGLchar = PGLchar;

//...........................................................................
var
 GL_VERSION_1_1: Boolean = True;
 GL_VERSION_1_2: Boolean = True;
 GL_VERSION_1_3: Boolean = True;
 GL_VERSION_1_4: Boolean = True;
 GL_VERSION_1_5: Boolean = True;
 GL_VERSION_2_0: Boolean = True;
 GL_VERSION_2_1: Boolean = True;
 GL_VERSION_3_0: Boolean = False;
 GL_VERSION_3_1: Boolean = False;
 GL_VERSION_3_2: Boolean = False;
 GL_VERSION_3_3: Boolean = False;
 GL_VERSION_4_0: Boolean = False;
 GL_VERSION_4_1: Boolean = False;
 GL_VERSION_4_2: Boolean = False;
 GL_VERSION_4_3: Boolean = False;
 GL_EXT_framebuffer_object: Boolean = True;
 GL_EXT_separate_specular_color: Boolean = True;
{$endif}

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
{$ifdef FireMonkey}
procedure glBufferData(Target: Cardinal; Size: Integer; Data: Pointer;
 Usage: Cardinal);
begin
 Macapi.OpenGL.glBufferData(Target, GLsizeiptr(Size), Data, Usage);
end;

//---------------------------------------------------------------------------
procedure glBufferSubData(Target: Cardinal; Offset: Pointer; Size: Integer;
 Data: Pointer);
begin
 Macapi.OpenGL.glBufferSubData(Target, Offset, GLsizeiptr(Size), Data);
end;

//---------------------------------------------------------------------------
procedure glVertexAttribPointer(Index: Cardinal; Size: Integer; AType: Cardinal;
 Normalized: Boolean; Stride: Integer; Data: Pointer);
var
 NormValue: GLboolean;
begin
 if (Normalized) then NormValue:= GL_TRUE
  else NormValue:= GL_FALSE;

 Macapi.OpenGL.glVertexAttribPointer(Index, Size, AType, NormValue, Stride,
  Data);
end;
{$endif}

//---------------------------------------------------------------------------
function GetOpenGLTechVersion(): Integer;
begin
 Result:= $100;

 if (GL_VERSION_1_1) then Result:= $110;
 if (GL_VERSION_1_2) then Result:= $120;
 if (GL_VERSION_1_3) then Result:= $130;
 if (GL_VERSION_1_4) then Result:= $140;
 if (GL_VERSION_1_5) then Result:= $150;
 if (GL_VERSION_2_0) then Result:= $200;
 if (GL_VERSION_2_1) then Result:= $210;
 if (GL_VERSION_3_0) then Result:= $300;
 if (GL_VERSION_3_1) then Result:= $310;
 if (GL_VERSION_3_2) then Result:= $320;
 if (GL_VERSION_3_3) then Result:= $330;
 if (GL_VERSION_4_0) then Result:= $400;
 if (GL_VERSION_4_1) then Result:= $410;
 if (GL_VERSION_4_2) then Result:= $420;
 if (GL_VERSION_4_3) then Result:= $430;
end;

//---------------------------------------------------------------------------
function GL_CreateNewTexture(out Texture: GLuint;
 Mipmapping: Boolean): Boolean;
begin
 glActiveTexture(GL_TEXTURE0);
 glEnable(GL_TEXTURE_2D);
 glGenTextures(1, @Texture);
 glBindTexture(GL_TEXTURE_2D, Texture);

 glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
 glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

 if (GL_VERSION_1_4) then
  begin // OpenGL 1.4 or higher.
   if (Mipmapping) then
    begin
     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
      GL_LINEAR_MIPMAP_LINEAR);

     if (not GL_EXT_framebuffer_object) then
      glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
    end else
    begin
     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
     glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

     if (not GL_EXT_framebuffer_object) then
      glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);
    end;
  end else
  begin // OpenGL 1.3 or lower.
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  end;

 Result:= (glGetError() = GL_NO_ERROR)and(Texture <> 0);
end;

//---------------------------------------------------------------------------
procedure GL_DestroyTexture(var Texture: GLuint);
begin
 if (Texture <> 0) then
  begin
   GL_DisableTexture2D();

   glDeleteTextures(1, @Texture);
  end;
end;

//---------------------------------------------------------------------------
function GL_DefineTexture2D(Width, Height: Integer;
 SurfaceBits: Pointer): Boolean;
begin
 Result:= (Width > 0)and(Height > 0);
 if (not Result) then Exit;

 glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, Width, Height, 0, GL_BGRA,
  GL_UNSIGNED_BYTE, SurfaceBits);

 Result:= glGetError() = GL_NO_ERROR;
end;

//---------------------------------------------------------------------------
procedure GL_GenerateTextureMipmaps();
begin
 if (GL_EXT_framebuffer_object) then
  begin
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
   glGenerateMipmapEXT(GL_TEXTURE_2D);
  end;
end;

//---------------------------------------------------------------------------
function GL_UpdateTextureContents(Texture, Width, Height: Integer;
 SurfaceBits: Pointer; Level: Integer = 0): Boolean;
begin
 Result:= (Texture <> 0)and(Width > 0)and(Height > 0)and(Assigned(SurfaceBits));
 if (not Result) then Exit;

 glActiveTexture(GL_TEXTURE0);
 glEnable(GL_TEXTURE_2D);
 glBindTexture(GL_TEXTURE_2D, Texture);

 glTexSubImage2D(GL_TEXTURE_2D, Level, 0, 0, Width, Height, GL_BGRA,
  GL_UNSIGNED_BYTE, SurfaceBits);

 Result:= glGetError() = GL_NO_ERROR;
end;

//---------------------------------------------------------------------------
procedure GL_DisableTexture2D();
begin
 glBindTexture(GL_TEXTURE_2D, 0);
 glDisable(GL_TEXTURE_2D);
end;

//---------------------------------------------------------------------------
function GL_CreateFrameBuffer(out FrameBuffer: GLuint;
 Texture: GLuint): Boolean;
begin
 glGenFramebuffersEXT(1, @FrameBuffer);
 glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, FrameBuffer);

 Result:= (glGetError() = GL_NO_ERROR)and(FrameBuffer <> 0);
 if (not Result) then
  begin
   glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
   Exit;
  end;

 if (Texture <> 0) then
  glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
   GL_TEXTURE_2D, Texture, 0);
end;

//---------------------------------------------------------------------------
function GL_CreateDepthBuffer(Width, Height: Integer;
 out DepthBuffer: GLuint): Boolean;
begin
 glGenRenderbuffersEXT(1, @DepthBuffer);
 glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, DepthBuffer);

 glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH24_STENCIL8_EXT, Width,
  Height);

 glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, 0);

 Result:= (glGetError() = GL_NO_ERROR)and(DepthBuffer <> 0);
 if (not Result) then Exit;

 glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
  GL_RENDERBUFFER_EXT, DepthBuffer);

 Result:= glGetError() = GL_NO_ERROR;
end;

//---------------------------------------------------------------------------
end.
