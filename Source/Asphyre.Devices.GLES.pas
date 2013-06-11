unit Asphyre.Devices.GLES;
//---------------------------------------------------------------------------
// OpenGL ES device management for Asphyre.
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
 System.Classes, Asphyre.Devices;

//---------------------------------------------------------------------------
type
 TGLESDevice = class(TAsphyreDevice)
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
 iOSapi.OpenGLES, FMX.Types, Asphyre.Math, Asphyre.Events, Asphyre.SwapChains, 
 Asphyre.Types.GLES;

//---------------------------------------------------------------------------
constructor TGLESDevice.Create();
begin
 inherited;

 FTechnology := adtOpenGL_ES;
 FTechVersion:= $200;
end;

//---------------------------------------------------------------------------
function TGLESDevice.InitDevice(): Boolean;
begin
 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TGLESDevice.DoneDevice();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGLESDevice.Clear(Color: Cardinal);
begin
 glClearColor(
  ((Color shr 16) and $FF) / 255.0,
  ((Color shr 8) and $FF) / 255.0,
  (Color and $FF) / 255.0, ((Color shr 24) and $FF) / 255.0);

 glClearDepthf(FillDepthValue);
 glClearStencil(GLint(FillStencilValue));

 glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

 // Reset error flags in case no depth/stencil is available.
 GLES_ResetErrors();
end;

//---------------------------------------------------------------------------
procedure TGLESDevice.RenderWith(SwapChainIndex: Integer;
 Handler: TNotifyEvent; Background: Cardinal);
var
 UserDesc: PSwapChainDesc;
begin
 UserDesc:= SwapChains[SwapChainIndex];
 if (not Assigned(UserDesc)) then Exit;

 GLES_ResetErrors();

 glDisable(GL_CULL_FACE);
 glDisable(GL_DEPTH_TEST);
 glDisable(GL_SCISSOR_TEST);

 glViewport(0, 0, Round(UserDesc.Width * FDeviceScale),
  Round(UserDesc.Height * FDeviceScale));

 EventBeginScene.Notify(Self);

 Handler(Self);

 EventEndScene.Notify(Self);
end;

//---------------------------------------------------------------------------
procedure TGLESDevice.RenderToTarget(Handler: TNotifyEvent;
 Background: Cardinal; FillBk: Boolean);
begin
 GLES_UsingFrameBuffer:= True;

 glDisable(GL_SCISSOR_TEST);

 if (FillBk) then Clear(Background);

 EventBeginScene.Notify(Self);
 Handler(Self);
 EventEndScene.Notify(Self);

 GLES_UsingFrameBuffer:= False;
end;

//---------------------------------------------------------------------------
end.
