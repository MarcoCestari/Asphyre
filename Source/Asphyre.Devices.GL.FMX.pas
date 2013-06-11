unit Asphyre.Devices.GL.FMX;
//---------------------------------------------------------------------------
// FireMonkey (Mac OS X) OpenGL device hook.
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
uses
 System.Classes, Asphyre.Devices;

//---------------------------------------------------------------------------
type
 TGLDevice = class(TAsphyreDevice)
 private
  procedure Clear(Color: Cardinal);
 protected
  function InitDevice(): Boolean; override;
  procedure DoneDevice(); override;

  procedure RenderWith(SwapChainIndex: Integer; Handler: TNotifyEvent;
   Background: Cardinal); override;

  procedure RenderToTarget(Handler: TNotifyEvent;
   Background: Cardinal; FillBk: Boolean); override;
 public
  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Macapi.OpenGL, Asphyre.Events, Asphyre.Monkey.Types, Asphyre.Types.GL;

//---------------------------------------------------------------------------
constructor TGLDevice.Create();
begin
 inherited;

 FTechnology:= adtOpenGL;
end;

//---------------------------------------------------------------------------
function TGLDevice.InitDevice(): Boolean;
begin
 FTechVersion:= GetOpenGLTechVersion();

 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TGLDevice.DoneDevice();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGLDevice.Clear(Color: Cardinal);
begin
 glClearColor(
  ((Color shr 16) and $FF) / 255.0, ((Color shr 8) and $FF) / 255.0,
  (Color and $FF) / 255.0, ((Color shr 24) and $FF) / 255.0);

 glClearDepth(FillDepthValue);
 glClearStencil(FillStencilValue);

 glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
end;

//---------------------------------------------------------------------------
procedure TGLDevice.RenderWith(SwapChainIndex: Integer;
 Handler: TNotifyEvent; Background: Cardinal);
begin
 if (not FireContext.BeginScene()) then Exit;

 glViewport(0, 0, FireContext.Width, FireContext.Height);
 glDisable(GL_SCISSOR_TEST);

 Clear(Background);

 glShadeModel(GL_SMOOTH);
 glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
 glDisable(GL_CULL_FACE);
 glDisable(GL_DEPTH_TEST);

 glEnable(GL_TEXTURE_2D);

 glDisable(GL_VERTEX_PROGRAM_ARB);
 glDisable(GL_FRAGMENT_PROGRAM_ARB);

 glUseProgram(0);

 EventBeginScene.Notify(Self);

 Handler(Self);

 EventEndScene.Notify(Self);
 FireContext.EndScene();
end;

//---------------------------------------------------------------------------
procedure TGLDevice.RenderToTarget(Handler: TNotifyEvent;
 Background: Cardinal; FillBk: Boolean);
begin
 GL_UsingFrameBuffer:= True;

 if (FillBk) then Clear(Background);

 EventBeginScene.Notify(Self);
 Handler(Self);
 EventEndScene.Notify(Self);

 GL_UsingFrameBuffer:= False;
end;

//---------------------------------------------------------------------------
end.
