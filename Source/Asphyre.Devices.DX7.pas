unit Asphyre.Devices.DX7;
//---------------------------------------------------------------------------
// DirectDraw + Direct3D devices using DirectX 7.0.
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
 System.Classes, Asphyre.DDraw7, Asphyre.D3D7, Asphyre.Devices, 
 Asphyre.SwapChains;

//---------------------------------------------------------------------------
// Remove the dot to preserve FPU state.
{$define PreserveFPU}

// Remove the dot to enable multi-threading mode.
{.$define EnableMultithread}

//---------------------------------------------------------------------------
type
 TDX7Device = class(TAsphyreDevice)
 private
  FFrontBuffer: IDirectDrawSurface7;
  FBackBuffer : IDirectDrawSurface7;

  LostState: Boolean;

  function CreateDirectDraw(): Boolean;
  procedure DestroyDirectDraw();

  function CreateDirect3D(): Boolean;
  procedure DestroyDirect3D();

  function SetCooperativeLevel(): Boolean;
  function CreateFrontBuffer(): Boolean;
  procedure DestroyFrontBuffer();

  function CreateBackBuffer(UserDesc: PSwapChainDesc): Boolean;
  procedure DestroyBackBuffer();

  function CreateWindowClipper(Handle: THandle): Boolean;

  function CreateDevice(): Boolean;
  procedure DestroyDevice();

  procedure SetDefaultViewport(UserDesc: PSwapChainDesc);

  function Flip(): Boolean;
 protected
  function InitDevice(): Boolean; override;
  procedure DoneDevice(); override;
  procedure ResetDevice(); override;

  function MayRender(SwapChainIndex: Integer): Boolean; override;

  procedure RenderWith(SwapChainIndex: Integer; Handler: TNotifyEvent;
   Background: Cardinal); override;

  procedure RenderToTarget(Handler: TNotifyEvent; Background: Cardinal;
   FillBk: Boolean); override;

  function ResizeSwapChain(SwapChainIndex: Integer;
   NewUserDesc: PSwapChainDesc): Boolean; override;
 public
  property FrontBuffer: IDirectDrawSurface7 read FFrontBuffer;
  property BackBuffer : IDirectDrawSurface7 read FBackBuffer;

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Winapi.Windows, System.SysUtils, Asphyre.Types.DX7, Asphyre.Types, 
 Asphyre.Events;

//---------------------------------------------------------------------------
{$ifdef fpc}
type
 TWindowInfo = packed record
  cbSize: LongWord;
  rcWindow: TRect;
  rcClient: TRect;
  dwStyle: LongWord;
  dwExStyle: LongWord;
  dwWindowStatus: LongWord;
  cxWindowBorders: LongWord;
  cyWindowBorders: LongWord;
  atomWindowType: Word;
  wCreatorVersion: Word;
 end;

//---------------------------------------------------------------------------
function GetWindowInfo(Handle: HWND;
 var WinInfo: TWindowInfo): LongBool; stdcall; external 'User32.dll';
{$endif}

//---------------------------------------------------------------------------
constructor TDX7Device.Create();
begin
 inherited;

 FTechnology:= adtDirectX;
 FTechVersion:= $700;

 FFrontBuffer:= nil;
 FBackBuffer := nil;
end;

//---------------------------------------------------------------------------
function TDX7Device.CreateDirectDraw(): Boolean;
begin
 Result:= Succeeded(DirectDrawCreateEx(nil, DDraw7Obj, IID_IDirectDraw7,
  nil));
end;

//---------------------------------------------------------------------------
procedure TDX7Device.DestroyDirectDraw();
begin
 if (Assigned(DDraw7Obj)) then DDraw7Obj:= nil;
end;

//---------------------------------------------------------------------------
function TDX7Device.CreateDirect3D(): Boolean;
begin
 Result:= Supports(DDraw7Obj, IID_IDirect3D7, D3D7Object);
end;

//---------------------------------------------------------------------------
procedure TDX7Device.DestroyDirect3D();
begin
 if (Assigned(D3D7Object)) then D3D7Object:= nil;
end;

//---------------------------------------------------------------------------
function TDX7Device.SetCooperativeLevel(): Boolean;
var
 Flags: Cardinal;
begin
 Flags:= DDSCL_NORMAL or DDSCL_NOWINDOWCHANGES;

{$ifdef PreserveFPU}
 Flags:= Flags or DDSCL_FPUPRESERVE;
{$endif}

{$ifdef EnableMultithread}
 Flags:= Flags or DDSCL_MULTITHREADED;
{$endif}

 Result:= Succeeded(DDraw7Obj.SetCooperativeLevel(0, Flags));
end;

//---------------------------------------------------------------------------
function TDX7Device.CreateFrontBuffer(): Boolean;
var
 SurfaceDesc: TDDSurfaceDesc2;
begin
 FillChar(SurfaceDesc, SizeOf(TDDSurfaceDesc2), 0);

 SurfaceDesc.dwSize := SizeOf(TDDSurfaceDesc2);
 SurfaceDesc.dwFlags:= DDSD_CAPS;
 SurfaceDesc.ddsCaps.dwCaps:= DDSCAPS_PRIMARYSURFACE;

 Result:= Succeeded(DDraw7Obj.CreateSurface(SurfaceDesc, FFrontBuffer, nil));
end;

//---------------------------------------------------------------------------
procedure TDX7Device.DestroyFrontBuffer();
begin
 if (Assigned(FFrontBuffer)) then FFrontBuffer:= nil;
end;

//---------------------------------------------------------------------------
function TDX7Device.CreateBackBuffer(UserDesc: PSwapChainDesc): Boolean;
var
 Format: TAsphyrePixelFormat;
 SurfaceDesc: TDDSurfaceDesc2;
begin
 // (1) If the pixel format is specified, check for supported format and
 // update it.
 Format:= apf_Unknown;

 if (UserDesc.Format <> apf_Unknown) then
  Format:= DX7FindBackBufferFormat(UserDesc.Width, UserDesc.Height,
   UserDesc.Format);

 // (2) Prepare the surface declaration.
 FillChar(SurfaceDesc, SizeOf(TDDSurfaceDesc2), 0);

 SurfaceDesc.dwSize := SizeOf(TDDSurfaceDesc2);
 SurfaceDesc.dwFlags:= DDSD_CAPS or DDSD_HEIGHT or DDSD_WIDTH;
 SurfaceDesc.ddsCaps.dwCaps:= DDSCAPS_OFFSCREENPLAIN or DDSCAPS_3DDEVICE;
 SurfaceDesc.dwWidth := UserDesc.Width;
 SurfaceDesc.dwHeight:= UserDesc.Height;

 // Include pixel format description, if necessary.
 if (Format <> apf_Unknown) then
  begin
   SurfaceDesc.dwFlags:= SurfaceDesc.dwFlags or DDSD_PIXELFORMAT;
   AsphyreToDX7Format(Format, SurfaceDesc.ddpfPixelFormat);
  end;

 // (3) Create DirectDraw surface.
 Result:= Succeeded(DDraw7Obj.CreateSurface(SurfaceDesc, FBackBuffer, nil));
 if (not Result) then Exit;

 // (4) Retrieve the new surface's description.
 FillChar(SurfaceDesc, SizeOf(TDDSurfaceDesc2), 0);
 SurfaceDesc.dwSize:= SizeOf(TDDSurfaceDesc2);

 Result:= Succeeded(FBackBuffer.GetSurfaceDesc(SurfaceDesc));
 if (not Result) then
  begin
   FBackBuffer:= nil;
   Exit;
  end;

 // (5) Update the user data with new pixel format.
 UserDesc.Format:= DX7FormatToAsphyre(SurfaceDesc.ddpfPixelFormat);
end;

//---------------------------------------------------------------------------
procedure TDX7Device.DestroyBackBuffer();
begin
 if (Assigned(FBackBuffer)) then FBackBuffer:= nil;
end;

//---------------------------------------------------------------------------
function TDX7Device.CreateWindowClipper(Handle: THandle): Boolean;
var
 Clipper: IDirectDrawClipper;
begin
 Result:= Succeeded(DDraw7Obj.CreateClipper(0, Clipper, nil));
 if (not Result) then Exit;

 Clipper.SetHWnd(0, Handle);
 FFrontBuffer.SetClipper(Clipper);
end;

//---------------------------------------------------------------------------
function TDX7Device.CreateDevice(): Boolean;
begin
 Result:= Succeeded(D3D7Object.CreateDevice(IID_IDirect3DHALDevice,
  FBackBuffer, D3D7Device));
end;

//---------------------------------------------------------------------------
procedure TDX7Device.DestroyDevice();
begin
 if (Assigned(D3D7Device)) then D3D7Device:= nil;
end;

//---------------------------------------------------------------------------
function TDX7Device.InitDevice(): Boolean;
var
 UserDesc: PSwapChainDesc;
begin
 // (1) Verify initial conditions.
 UserDesc:= SwapChains[0];

 Result:= (Assigned(UserDesc))and(SwapChains.Count < 2);
 if (not Result) then Exit;

 // (2) Create DirectDraw interface.
 Result:= CreateDirectDraw();
 if (not Result) then Exit;

 // (3) Create Direct3D interface.
 Result:= CreateDirect3D();
 if (not Result) then
  begin
   DestroyDirectDraw();
   Exit;
  end;

 // (4) Set the particular cooperative mode.
 Result:= SetCooperativeLevel();
 if (not Result) then
  begin
   DestroyDirect3D();
   DestroyDirectDraw();
   Exit;
  end;

 // (5) Create primary surface as a Front Buffer.
 Result:= CreateFrontBuffer();
 if (not Result) then
  begin
   DestroyDirect3D();
   DestroyDirectDraw();
   Exit;
  end;

 // (6) Create offscreen surface as a Back Buffer.
 Result:= CreateBackBuffer(UserDesc);
 if (not Result) then
  begin
   DestroyFrontBuffer();
   DestroyDirect3D();
   DestroyDirectDraw();
   Exit;
  end;

 // (7) Create clipper for swap chain's window.
 Result:= CreateWindowClipper(UserDesc.WindowHandle);
 if (not Result) then
  begin
   DestroyBackBuffer();
   DestroyFrontBuffer();
   DestroyDirect3D();
   DestroyDirectDraw();
   Exit;
  end;

 // (8) Create Direct3D device for 3D rendering.
 Result:= CreateDevice();
 if (not Result) then
  begin
   DestroyBackBuffer();
   DestroyFrontBuffer();
   DestroyDirect3D();
   DestroyDirectDraw();
   Exit;
  end;

 LostState:= False;
end;

//---------------------------------------------------------------------------
procedure TDX7Device.DoneDevice();
begin
 DestroyDevice();
 DestroyBackBuffer();
 DestroyFrontBuffer();
 DestroyDirect3D();
 DestroyDirectDraw();
end;

//---------------------------------------------------------------------------
procedure TDX7Device.ResetDevice();
begin
 FBackBuffer._Restore();
 FFrontBuffer._Restore();
end;

//---------------------------------------------------------------------------
function TDX7Device.MayRender(SwapChainIndex: Integer): Boolean;
var
 Res: HResult;
 IsLost, NeedReset: Boolean;
begin
 // (1) Verify initial conditions and check the device state.
 Result:= Assigned(DDraw7Obj);
 if (not Result) then Exit;

 Res   := DDraw7Obj.TestCooperativeLevel();
 IsLost:= Failed(Res);

 NeedReset:= ((LostState)and(not IsLost))or(Res = DDERR_WRONGMODE);

 // (2) The device has been lost.
 if (IsLost)and(not LostState) then
  begin
   LostState:= True;
   Result:= False;
   Exit;
  end;

 // (3) The device has been recovered.
 if (LostState)and(not IsLost) then
  begin
   ResetDevice();
   LostState:= False;
   Result:= True;
   Exit;
  end;

 // (4) The device is lost, but may be recovered (later on).
 if (IsLost)and(NeedReset) then
  begin
   ResetDevice();
   LostState:= False;
   Result:= False;
   Exit;
  end;

 // (5) The device is still lost.
 if (IsLost) then
  begin
   Result:= False;
   Exit;
  end;

 // (6) The device is operational.
 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TDX7Device.SetDefaultViewport(UserDesc: PSwapChainDesc);
var
 vp: TD3DViewport7;
begin
 if (not Assigned(D3D7Device))or(not Assigned(UserDesc)) then Exit;

 vp.dwX:= 0;
 vp.dwY:= 0;
 vp.dwWidth := UserDesc.Width;
 vp.dwHeight:= UserDesc.Height;
 vp.dvMinZ:= 0.0;
 vp.dvMaxZ:= 1.0;

 D3D7Device.SetViewport(vp);
end;

//---------------------------------------------------------------------------
function TDX7Device.Flip(): Boolean;
var
 UserDesc  : PSwapChainDesc;
 WindowInfo: TWindowInfo;
 WindowRect: TRect;
begin
 Result:= False;
 if (not Assigned(DDraw7Obj))or(not Assigned(FBackBuffer))or
  (not Assigned(FFrontBuffer)) then Exit;

 UserDesc:= SwapChains[0];
 if (not Assigned(UserDesc)) then Exit;

 FillChar(WindowInfo, SizeOf(TWindowInfo), 0);
 WindowInfo.cbSize:= SizeOf(TWindowInfo);

 if (not GetWindowInfo(UserDesc.WindowHandle, WindowInfo)) then Exit;

 WindowRect:= WindowInfo.rcClient;

 if (UserDesc.VSync) then
  DDraw7Obj.WaitForVerticalBlank(DDWAITVB_BLOCKBEGIN, 0);

 Result:= Succeeded(FFrontBuffer.Blt(@WindowRect, FBackBuffer, nil,
  DDBLT_WAIT, nil));
end;

//---------------------------------------------------------------------------
procedure TDX7Device.RenderWith(SwapChainIndex: Integer;
 Handler: TNotifyEvent; Background: Cardinal);
var
 UserDesc: PSwapChainDesc;
begin
 if (SwapChainIndex <> 0) then Exit;

 UserDesc:= SwapChains[0];
 if (not Assigned(UserDesc)) then Exit;

 SetDefaultViewport(UserDesc);

 D3D7Device.Clear(0, nil, D3DCLEAR_TARGET, Background, 0.0, 0);

 if (Succeeded(D3D7Device.BeginScene())) then
  begin
   EventBeginScene.Notify(Self);

   Handler(Self);

   EventEndScene.Notify(Self);
   D3D7Device.EndScene();
  end;

 Flip();
end;

//---------------------------------------------------------------------------
procedure TDX7Device.RenderToTarget(Handler: TNotifyEvent;
 Background: Cardinal; FillBk: Boolean);
begin
 if (FillBk) then
  D3D7Device.Clear(0, nil, D3DCLEAR_TARGET, Background, 0.0, 0);

 if (Succeeded(D3D7Device.BeginScene())) then
  begin
   EventBeginScene.Notify(Self);

   Handler(Self);

   EventEndScene.Notify(Self);
   D3D7Device.EndScene();
  end;
end;

//---------------------------------------------------------------------------
function TDX7Device.ResizeSwapChain(SwapChainIndex: Integer;
 NewUserDesc: PSwapChainDesc): Boolean;
begin
 Result:= (SwapChainIndex = 0)and(Assigned(NewUserDesc));
 if (not Result) then Exit;

 if (not Assigned(D3D7Device)) then Exit;

 DestroyBackBuffer();

 Result:= CreateBackBuffer(NewUserDesc);
 if (Result) then D3D7Device.SetRenderTarget(FBackBuffer, 0);
end;

//---------------------------------------------------------------------------
end.
