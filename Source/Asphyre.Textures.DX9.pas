unit Asphyre.Textures.DX9;
//---------------------------------------------------------------------------
// Direct3D 9 texture implementation.
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
{$ifndef fpc}
 Winapi.Windows, System.Types,
{$else}
 Windows, Types,
{$endif}
 Asphyre.D3D9, Asphyre.Types, Asphyre.Textures;

//---------------------------------------------------------------------------
type
 TDX9LockableTexture = class(TAsphyreLockableTexture)
 private
  FSysTexture: IDirect3DTexture9;
  FVidTexture: IDirect3DTexture9;
  
  SysUsage: Cardinal;
  VidUsage: Cardinal;
  VidPool : D3DPOOL;

  function ComputeParams(): Boolean;
  procedure ResetParams();

  function CreateSystemTexture(): Boolean;
  procedure DestroySystemTexture();

  function CreateVideoTexture(): Boolean;
  procedure DestroyVideoTexture();

  function CopySystemToVideo(): Boolean;
 protected
  procedure UpdateSize(); override;

  function CreateTexture(): Boolean; override;
  procedure DestroyTexture(); override;
 public
  property SysTexture: IDirect3DTexture9 read FSysTexture;
  property VidTexture: IDirect3DTexture9 read FVidTexture;

  procedure Bind(Stage: Integer); override;

  procedure HandleDeviceReset(); override;
  procedure HandleDeviceLost(); override;

  procedure UpdateMipmaps(); override;

  procedure Lock(const Rect: TRect; out Bits: Pointer;
   out Pitch: Integer); override;
  procedure Unlock(); override;

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
 TDX9RenderTargetTexture = class(TAsphyreRenderTargetTexture)
 private
  FTexture    : IDirect3DTexture9;
  FDepthBuffer: IDirect3DSurface9;

  SavedBackBuffer : IDirect3DSurface9;
  SavedDepthBuffer: IDirect3DSurface9;

  DepthStencilFormat: D3DFORMAT;

  function CreateTextureInstance(): Boolean;
  procedure DestroyTextureInstance();

  function SaveRenderBuffers(): Boolean;
  procedure RestoreRenderBuffers();
  function SetRenderBuffers(): Boolean;
  procedure SetDefaultViewport();
 protected
  procedure UpdateSize(); override;

  function CreateTexture(): Boolean; override;
  procedure DestroyTexture(); override;
 public
  property Texture: IDirect3DTexture9 read FTexture;
  property DepthBuffer: IDirect3DSurface9 read FDepthBuffer;

  procedure Bind(Stage: Integer); override;

  procedure HandleDeviceReset(); override;
  procedure HandleDeviceLost(); override;

  procedure UpdateMipmaps(); override;

  function BeginDrawTo(): Boolean; override;
  procedure EndDrawTo(); override;

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types.DX9;

//---------------------------------------------------------------------------
const
 DX9TextureDepthStencilLevel = 2;

//---------------------------------------------------------------------------
constructor TDX9LockableTexture.Create();
begin
 inherited;

 FSysTexture:= nil;
 FVidTexture:= nil;

 ResetParams();
end;

//---------------------------------------------------------------------------
function TDX9LockableTexture.ComputeParams(): Boolean;
begin
 SysUsage:= 0;
 VidUsage:= 0;

 if (MipMapping) then
  VidUsage:= VidUsage or D3DUSAGE_AUTOGENMIPMAP;

 if (D3D9Mode = dmDirect3D9Ex) then
  begin // Vista enhanced mode.
   VidPool:= D3DPOOL_DEFAULT;

   if (DynamicTexture) then
    begin
     SysUsage:= SysUsage or D3DUSAGE_DYNAMIC;
     VidUsage:= VidUsage or D3DUSAGE_DYNAMIC;
    end;

   FFormat:= DX9FindTextureFormatEx(FFormat, SysUsage, VidUsage);
  end else
  begin // XP compatibility mode.
   VidPool:= D3DPOOL_MANAGED;

   if (DynamicTexture) then
    begin
     VidUsage:= VidUsage or D3DUSAGE_DYNAMIC;
     VidPool := D3DPOOL_DEFAULT;
    end;

   FFormat:= DX9FindTextureFormat(FFormat, VidUsage);
  end;

 Result:= FFormat <> apf_Unknown;
 if (not Result) then Exit;
end;

//---------------------------------------------------------------------------
procedure TDX9LockableTexture.ResetParams();
begin
 SysUsage:= 0;
 VidUsage:= 0;
 VidPool := D3DPOOL_SCRATCH;
end;

//---------------------------------------------------------------------------
function TDX9LockableTexture.CreateSystemTexture(): Boolean;
var
 NativeFormat: D3DFORMAT;
begin
 NativeFormat:= AsphyreToDX9Format(FFormat);

 Result:= (Assigned(D3D9Device))and(NativeFormat <> D3DFMT_UNKNOWN);
 if (not Result) then Exit;

 Result:= Succeeded(D3D9Device.CreateTexture(Width, Height, 1, SysUsage,
  NativeFormat, D3DPOOL_SYSTEMMEM, FSysTexture, nil));
end;

//---------------------------------------------------------------------------
procedure TDX9LockableTexture.DestroySystemTexture();
begin
 if (Assigned(FSysTexture)) then FSysTexture:= nil;
end;

//---------------------------------------------------------------------------
function TDX9LockableTexture.CreateVideoTexture(): Boolean;
var
 Levels: Integer;
 NativeFormat: D3DFORMAT;
begin
 Levels:= 1;
 if (MipMapping) then Levels:= 0;

 NativeFormat:= AsphyreToDX9Format(FFormat);

 Result:= (Assigned(D3D9Device))and(NativeFormat <> D3DFMT_UNKNOWN);
 if (not Result) then Exit;

 Result:= Succeeded(D3D9Device.CreateTexture(Width, Height, Levels,
  VidUsage, NativeFormat, VidPool, FVidTexture, nil));
end;

//---------------------------------------------------------------------------
procedure TDX9LockableTexture.DestroyVideoTexture();
begin
 if (Assigned(FVidTexture)) then FVidTexture:= nil;
end;

//---------------------------------------------------------------------------
function TDX9LockableTexture.CreateTexture(): Boolean;
begin
 Result:= ComputeParams();
 if (not Result) then Exit;

 if (D3D9Mode = dmDirect3D9Ex) then
  begin
   Result:= CreateSystemTexture();
   if (not Result) then Exit;
  end;

 Result:= CreateVideoTexture();
end;

//---------------------------------------------------------------------------
procedure TDX9LockableTexture.DestroyTexture();
begin
 DestroyVideoTexture();
 DestroySystemTexture();
 ResetParams();
end;

//---------------------------------------------------------------------------
procedure TDX9LockableTexture.HandleDeviceReset();
begin
 if (D3D9Mode <> dmDirect3D9Ex)and(not Assigned(FVidTexture))and
  (FFormat <> apf_Unknown)and(VidPool = D3DPOOL_DEFAULT) then
   CreateVideoTexture();
end;

//---------------------------------------------------------------------------
procedure TDX9LockableTexture.HandleDeviceLost();
begin
 if (D3D9Mode <> dmDirect3D9Ex)and(VidPool = D3DPOOL_DEFAULT) then
  DestroyVideoTexture();
end;

//---------------------------------------------------------------------------
procedure TDX9LockableTexture.Bind(Stage: Integer);
begin
 if (Assigned(D3D9Device))and(Assigned(FVidTexture)) then
  D3D9Device.SetTexture(Stage, FVidTexture);
end;

//---------------------------------------------------------------------------
procedure TDX9LockableTexture.Lock(const Rect: TRect; out Bits: Pointer;
 out Pitch: Integer);
var
 LockedRect: TD3DLockedRect;
 Usage     : Cardinal;
 RectPtr   : Pointer;
begin
 Bits := nil;
 Pitch:= 0;

 // If the rectangle specified in Rect is the entire texture, then provide
 // null pointer instead.
 RectPtr:= @Rect;
 if (Rect.Left = 0)and(Rect.Top = 0)and(Rect.Right = Width)and
  (Rect.Bottom = Height) then RectPtr:= nil;

 Usage:= 0;
 if (DynamicTexture) then
  begin
   Usage:= D3DLOCK_DISCARD;

   // Only the entire texture can be locked at a time when dealing with
   // dynamic textures.
   if (Assigned(RectPtr)) then Exit;
  end;

 if (D3D9Mode = dmDirect3D9Ex) then
  begin // Vista enhanced mode.
   if (Assigned(FSysTexture))and(Succeeded(FSysTexture.LockRect(0, LockedRect,
    RectPtr, Usage))) then
    begin
     Bits := LockedRect.pBits;
     Pitch:= LockedRect.Pitch;
    end;
  end else
  begin // XP compatibility mode.
   if (Assigned(FVidTexture))and(Succeeded(FVidTexture.LockRect(0, LockedRect,
    RectPtr, Usage))) then
    begin
     Bits := LockedRect.pBits;
     Pitch:= LockedRect.Pitch;
    end;
  end;
end;

//---------------------------------------------------------------------------
function TDX9LockableTexture.CopySystemToVideo(): Boolean;
begin
 Result:= (Assigned(D3D9Device))and(Assigned(FSysTexture))and
  (Assigned(FVidTexture));
 if (not Result) then Exit;

 Result:= Succeeded(D3D9Device.UpdateTexture(FSysTexture, FVidTexture));
end;

//---------------------------------------------------------------------------
procedure TDX9LockableTexture.Unlock();
begin
 if (D3D9Mode = dmDirect3D9Ex) then
  begin // Vista enhanced mode.
   if (Assigned(FSysTexture)) then
    FSysTexture.UnlockRect(0);

   CopySystemToVideo();
  end else
  begin // XP compatibility mode.
   if (Assigned(FVidTexture)) then
    FVidTexture.UnlockRect(0);
  end;
end;

//---------------------------------------------------------------------------
procedure TDX9LockableTexture.UpdateMipmaps();
begin
 if (Assigned(FVidTexture)) then
  FVidTexture.GenerateMipSubLevels();
end;

//---------------------------------------------------------------------------
procedure TDX9LockableTexture.UpdateSize();
begin
 DestroyVideoTexture();
 CreateVideoTexture();
end;

//---------------------------------------------------------------------------
constructor TDX9RenderTargetTexture.Create();
begin
 inherited;

 FTexture    := nil;
 FDepthBuffer:= nil;

 SavedBackBuffer := nil;
 SavedDepthBuffer:= nil;

 DepthStencilFormat:= D3DFMT_UNKNOWN;
end;

//---------------------------------------------------------------------------
function TDX9RenderTargetTexture.CreateTextureInstance(): Boolean;
var
 Levels: Integer;
 Usage : Cardinal;
 NativeFormat: D3DFORMAT;
begin
 Result:= Assigned(D3D9Device);
 if (not Result) then Exit;

 Levels:= 1;
 if (MipMapping) then Levels:= 0;

 Usage:= D3DUSAGE_RENDERTARGET;
 if (MipMapping) then Usage:= Usage or D3DUSAGE_AUTOGENMIPMAP;

 FFormat:= DX9FindTextureFormat(FFormat, Usage);
 if (FFormat = apf_Unknown) then
  begin
   Result:= False;
   Exit;
  end;

 if (DepthStencil) then
  begin
   DepthStencilFormat:= DX9FindDepthStencilFormat(DX9TextureDepthStencilLevel);
   if (DepthStencilFormat = D3DFMT_UNKNOWN) then
    begin
     Result:= False;
     Exit;
    end;
  end;

 NativeFormat:= AsphyreToDX9Format(FFormat);

 Result:= Succeeded(D3D9Device.CreateTexture(Width, Height, Levels, Usage,
  NativeFormat, D3DPOOL_DEFAULT, FTexture, nil));
 if (not Result) then Exit;

 if (DepthStencil) then
  begin
   Result:= Succeeded(D3D9Device.CreateDepthStencilSurface(Width, Height,
    DepthStencilFormat, D3DMULTISAMPLE_NONE, 0, True, FDepthBuffer, nil));
   if (not Result) then
    begin
     FTexture:= nil;
     Exit;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX9RenderTargetTexture.DestroyTextureInstance();
begin
 if (Assigned(FDepthBuffer)) then FDepthBuffer:= nil;
 if (Assigned(FTexture)) then FTexture:= nil;

 DepthStencilFormat:= D3DFMT_UNKNOWN;
end;

//---------------------------------------------------------------------------
function TDX9RenderTargetTexture.CreateTexture(): Boolean;
begin
 Result:= CreateTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX9RenderTargetTexture.DestroyTexture();
begin
 DestroyTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX9RenderTargetTexture.Bind(Stage: Integer);
begin
 if (Assigned(D3D9Device))and(Assigned(FTexture)) then
  D3D9Device.SetTexture(Stage, FTexture);
end;

//---------------------------------------------------------------------------
procedure TDX9RenderTargetTexture.HandleDeviceReset();
begin
 if (D3D9Mode <> dmDirect3D9Ex) then
  CreateTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX9RenderTargetTexture.HandleDeviceLost();
begin
 if (D3D9Mode <> dmDirect3D9Ex) then
  DestroyTextureInstance();
end;

//---------------------------------------------------------------------------
procedure TDX9RenderTargetTexture.UpdateMipmaps();
begin
 if (Assigned(FTexture)) then
  FTexture.GenerateMipSubLevels();
end;

//---------------------------------------------------------------------------
procedure TDX9RenderTargetTexture.UpdateSize();
begin
 DestroyTextureInstance();
 CreateTextureInstance();
end;

//---------------------------------------------------------------------------
function TDX9RenderTargetTexture.SaveRenderBuffers(): Boolean;
begin
 Result:= Assigned(D3D9Device);
 if (not Result) then Exit;

 Result:= Succeeded(D3D9Device.GetRenderTarget(0, SavedBackBuffer));
 if (not Result) then Exit;

 if (D3D9PresentParams.EnableAutoDepthStencil) then
  begin
   Result:= Succeeded(D3D9Device.GetDepthStencilSurface(SavedDepthBuffer));
   if (not Result) then
    begin
     SavedBackBuffer:= nil;
     Exit;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX9RenderTargetTexture.RestoreRenderBuffers();
begin
 if (Assigned(D3D9Device)) then
  begin
   if (D3D9PresentParams.EnableAutoDepthStencil) then
    D3D9Device.SetDepthStencilSurface(SavedDepthBuffer);

   D3D9Device.SetRenderTarget(0, SavedBackBuffer);
  end;

 if (Assigned(SavedDepthBuffer)) then SavedDepthBuffer:= nil;
 if (Assigned(SavedBackBuffer)) then SavedBackBuffer:= nil;
end;

//---------------------------------------------------------------------------
function TDX9RenderTargetTexture.SetRenderBuffers(): Boolean;
var
 Surface: IDirect3DSurface9;
begin
 Result:= (Assigned(D3D9Device))and(Assigned(FTexture));
 if (not Result) then Exit;

 Result:= Succeeded(FTexture.GetSurfaceLevel(0, Surface));
 if (not Result) then Exit;

 Result:= Succeeded(D3D9Device.SetRenderTarget(0, Surface));

 if (Result) then
   Result:= Succeeded(D3D9Device.SetDepthStencilSurface(FDepthBuffer));
end;

//---------------------------------------------------------------------------
procedure TDX9RenderTargetTexture.SetDefaultViewport();
var
 vp: TD3DViewport9;
begin
 if (Assigned(D3D9Device)) then Exit;

 vp.X:= 0;
 vp.Y:= 0;
 vp.Width := Width;
 vp.Height:= Height;
 vp.MinZ:= 0.0;
 vp.MaxZ:= 1.0;

 D3D9Device.SetViewport(vp);
end;

//---------------------------------------------------------------------------
function TDX9RenderTargetTexture.BeginDrawTo(): Boolean;
begin
 // (1) Verify initial conditions.
 Result:= (Assigned(D3D9Device))and(Assigned(FTexture));
 if (not Result) then Exit;

 // (2) Save the currently set buffers.
 Result:= SaveRenderBuffers();
 if (not Result) then Exit;

 // (3) Set new render target and depth-stencil.
 Result:= SetRenderBuffers();
 if (not Result) then
  begin
   RestoreRenderBuffers();
   Exit;
  end;

 // (4) Update viewport to reflect the new render target size.
 SetDefaultViewport();

 // (5) Define the current depth-stencil level for Clear() method.
 if (DepthStencil) then
  DX9ActiveDepthStencilLevel:= DX9TextureDepthStencilLevel
   else DX9ActiveDepthStencilLevel:= 0;
end;

//---------------------------------------------------------------------------
procedure TDX9RenderTargetTexture.EndDrawTo();
begin
 RestoreRenderBuffers();
end;

//---------------------------------------------------------------------------
end.
