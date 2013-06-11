unit Asphyre.Textures.DX7;
//---------------------------------------------------------------------------
// Direct3D 7 texture implementation.
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
 Winapi.Windows, Asphyre.DDraw7, Asphyre.D3D7, System.Types, Asphyre.TypeDef, 
 Asphyre.Math, Asphyre.Surfaces, Asphyre.Textures;

//---------------------------------------------------------------------------
type
 TDX7LockableTexture = class(TAsphyreLockableTexture)
 private
  FSurface: IDirectDrawSurface7;
  FSurfaceDesc: TDDSurfaceDesc2;

  LockedRect: TRect;

  procedure UnlockRect(Rect: PRect; Level: Integer);
  procedure InitSurfaceDesc();
  function CreateTextureSurface(): Boolean;
  procedure DestroyTextureSurface();
  function GetSurfaceLevel(Level: Integer): IDirectDrawSurface7;
  function GetSizeOfLevel(Level: Integer): TPoint2px;
  procedure LockRect(Rect: PRect; Level: Integer; out Bits: Pointer;
   out Pitch: Integer);
  function GetLockRectPtr(Rect: PRect): PRect;

  function GetPixelData(Level: Integer; Buffer: TPixelSurface): Boolean;
  function SetPixelData(Level: Integer; Buffer: TPixelSurface): Boolean;
 protected
  procedure UpdateSize(); override;

  function CreateTexture(): Boolean; override;
  procedure DestroyTexture(); override;
 public
  property Surface: IDirectDrawSurface7 read FSurface;
  property SurfaceDesc: TDDSurfaceDesc2 read FSurfaceDesc;

  procedure Bind(Stage: Integer); override;

  procedure UpdateMipmaps(); override;

  procedure Lock(const Rect: TRect; out Bits: Pointer;
   out Pitch: Integer); override;
  procedure Unlock(); override;

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
 TDX7RenderTargetTexture = class(TAsphyreRenderTargetTexture)
 private
  FSurface    : IDirectDrawSurface7;
  FSurfaceDesc: TDDSurfaceDesc2;
  PrevSurface : IDirectDrawSurface7;

  procedure InitSurfaceDesc();
  function CreateTextureSurface(): Boolean;
  procedure DestroyTextureSurface();
 protected
  procedure UpdateSize(); override;

  function CreateTexture(): Boolean; override;
  procedure DestroyTexture(); override;
 public
  property Surface: IDirectDrawSurface7 read FSurface;
  property SurfaceDesc: TDDSurfaceDesc2 read FSurfaceDesc;

  procedure Bind(Stage: Integer); override;

  procedure HandleDeviceReset(); override;
  procedure HandleDeviceLost(); override;

  function BeginDrawTo(): Boolean; override;
  procedure EndDrawTo(); override;

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 System.SysUtils, Asphyre.Types.DX7, Asphyre.Types;

//---------------------------------------------------------------------------
function ComputeMipLevels(Width, Height: Integer): Integer;
begin
 Result:= 1;

 while (Width > 1)and(Height > 1)and(Width and 1 = 0)and(Height and 1 = 0) do
  begin
   Width := Width div 2;
   Height:= Height div 2;
   Inc(Result);
  end;
end;

//---------------------------------------------------------------------------
constructor TDX7LockableTexture.Create();
begin
 inherited;

 FSurface:= nil;
 FillChar(FSurfaceDesc, SizeOf(TDDSurfaceDesc2), 0);
end;

//---------------------------------------------------------------------------
procedure TDX7LockableTexture.InitSurfaceDesc();
begin
 FillChar(FSurfaceDesc, SizeOf(TDDSurfaceDesc2), 0);

 FSurfaceDesc.dwSize:= SizeOf(TDDSurfaceDesc2);

 FSurfaceDesc.dwFlags:= DDSD_CAPS or DDSD_HEIGHT or DDSD_WIDTH or
  DDSD_PIXELFORMAT or DDSD_TEXTURESTAGE;

 FSurfaceDesc.ddsCaps.dwCaps := DDSCAPS_TEXTURE;
 FSurfaceDesc.ddsCaps.dwCaps2:= DDSCAPS2_TEXTUREMANAGE;

 FSurfaceDesc.dwWidth := Width;
 FSurfaceDesc.dwHeight:= Height;

 if (MipMapping) then
  begin
   FSurfaceDesc.dwFlags:= FSurfaceDesc.dwFlags or DDSD_MIPMAPCOUNT;

   FSurfaceDesc.ddsCaps.dwCaps:= FSurfaceDesc.ddsCaps.dwCaps or
    DDSCAPS_MIPMAP or DDSCAPS_COMPLEX;

   FSurfaceDesc.dwMipMapCount:= ComputeMipLevels(Width, Height);
  end;

 AsphyreToDX7Format(FFormat, FSurfaceDesc.ddpfPixelFormat);
end;

//---------------------------------------------------------------------------
function TDX7LockableTexture.CreateTextureSurface(): Boolean;
begin
 Result:= Assigned(DDraw7Obj);
 if (not Result) then Exit;

 InitSurfaceDesc();

 Result:= Succeeded(DDraw7Obj.CreateSurface(FSurfaceDesc, FSurface, nil));
 if (not Result) then Exit;

 Result:= Succeeded(FSurface.GetSurfaceDesc(FSurfaceDesc));
 if (not Result) then
  begin
   FSurface:= nil;
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX7LockableTexture.DestroyTextureSurface();
begin
 if (Assigned(FSurface)) then
  begin
   FSurface:= nil;
   FillChar(FSurfaceDesc, SizeOf(TDDSurfaceDesc2), 0);
  end;
end;

//---------------------------------------------------------------------------
function TDX7LockableTexture.CreateTexture(): Boolean;
begin
 FFormat:= DX7FindTextureFormat(FFormat);
 if (FFormat = apf_Unknown) then
  begin
   Result:= False;
   Exit;
  end;

 Result:= CreateTextureSurface();
end;

//---------------------------------------------------------------------------
procedure TDX7LockableTexture.DestroyTexture();
begin
 DestroyTextureSurface();
end;

//---------------------------------------------------------------------------
procedure TDX7LockableTexture.Bind(Stage: Integer);
begin
 if (Assigned(D3D7Device))and(Assigned(FSurface)) then
  D3D7Device.SetTexture(Stage, FSurface);
end;

//---------------------------------------------------------------------------
function TDX7LockableTexture.GetSizeOfLevel(Level: Integer): TPoint2px;
var
 MipMap : IDirectDrawSurface7;
 MipDesc: TDDSurfaceDesc2;
begin
 Result:= ZeroPoint2px;

 MipMap:= GetSurfaceLevel(Level);
 if (not Assigned(MipMap)) then Exit;

 FillChar(MipDesc, SizeOf(TDDSurfaceDesc2), 0);
 MipDesc.dwSize:= SizeOf(TDDSurfaceDesc2);

 if (Succeeded(MipMap.GetSurfaceDesc(MipDesc))) then
  begin
   Result.x:= MipDesc.dwWidth;
   Result.y:= MipDesc.dwHeight;
  end;
end;

//---------------------------------------------------------------------------
function TDX7LockableTexture.GetSurfaceLevel(
 Level: Integer): IDirectDrawSurface7;
var
 Surface1, Surface2: IDirectDrawSurface7;
 Caps: TDDSCaps2;
begin
 if (not Assigned(FSurface)) then
  begin
   Result:= nil;
   Exit;
  end;

 if (Level = 0) then
  begin
   Result:= FSurface;
   Exit;
  end;

 Surface1:= FSurface;
 Surface2:= nil;

 repeat
  FillChar(Caps, SizeOf(TDDSCaps2), 0);
  Caps.dwCaps:= DDSCAPS_MIPMAP;

  if (Failed(Surface1.GetAttachedSurface(Caps, Surface2))) then
   begin
    Surface1:= nil;
    Surface2:= nil;
    Exit;
   end;

  Surface1:= Surface2;
  Surface2:= nil;

  Dec(Level);
 until (Level <= 0);

 Result:= Surface1;

 Surface1:= nil;
 Surface2:= nil;
end;

//---------------------------------------------------------------------------
procedure TDX7LockableTexture.LockRect(Rect: PRect; Level: Integer;
 out Bits: Pointer; out Pitch: Integer);
var
 MipMap : IDirectDrawSurface7;
 MipDesc: TDDSurfaceDesc2;
begin
 Bits := nil;
 Pitch:= 0;

 MipMap:= GetSurfaceLevel(Level);
 if (not Assigned(MipMap)) then Exit;

 FillChar(MipDesc, SizeOf(TDDSurfaceDesc2), 0);
 MipDesc.dwSize:= SizeOf(TDDSurfaceDesc2);

 if (Succeeded(MipMap.Lock(Rect, MipDesc, DDLOCK_SURFACEMEMORYPTR or
  DDLOCK_WAIT, 0))) then
  begin
   Bits := MipDesc.lpSurface;
   Pitch:= MipDesc.lPitch;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX7LockableTexture.UnlockRect(Rect: PRect; Level: Integer);
var
 MipMap: IDirectDrawSurface7;
begin
 MipMap:= GetSurfaceLevel(Level);
 if (Assigned(MipMap)) then MipMap.Unlock(Rect);
end;

//---------------------------------------------------------------------------
function TDX7LockableTexture.GetLockRectPtr(Rect: PRect): PRect;
begin
 Result:= Rect;

 if (Rect.Left = 0)and(Rect.Top = 0)and(Rect.Right = Width)and
  (Rect.Bottom = Height) then Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TDX7LockableTexture.Lock(const Rect: TRect; out Bits: Pointer;
 out Pitch: Integer);
begin
 LockedRect:= Rect;

 LockRect(GetLockRectPtr(@LockedRect), 0, Bits, Pitch);
end;

//---------------------------------------------------------------------------
procedure TDX7LockableTexture.Unlock();
begin
 UnlockRect(GetLockRectPtr(@LockedRect), 0);
end;

//---------------------------------------------------------------------------
procedure TDX7LockableTexture.UpdateSize();
begin
 DestroyTextureSurface();
 CreateTextureSurface();
end;

//---------------------------------------------------------------------------
function TDX7LockableTexture.GetPixelData(Level: Integer;
 Buffer: TPixelSurface): Boolean;
var
 Size : TPoint2px;
 Bits : Pointer;
 Pitch: Integer;
 Index: Integer;
 LinePtr: Pointer;
 ScanWidthBytes: Integer;
begin
 Result:= False;
 if (not Assigned(Buffer)) then Exit;

 Size:= GetSizeOfLevel(Level);
 if (Size = ZeroPoint2px) then Exit;

 LockRect(nil, Level, Bits, Pitch);
 if (not Assigned(Bits))or(Pitch < 1) then Exit;

 Buffer.SetSize(Size.x, Size.y, FFormat);

 ScanWidthBytes:= Buffer.Width * Buffer.BytesPerPixel;

 for Index:= 0 to Size.y - 1 do
  begin
   LinePtr:= Pointer(PtrInt(Bits) + (Pitch * Index));

   Move(LinePtr^, Buffer.Scanline[Index]^, ScanWidthBytes);
  end;

 UnlockRect(nil, Level);
 Result:= True;
end;

//---------------------------------------------------------------------------
function TDX7LockableTexture.SetPixelData(Level: Integer;
 Buffer: TPixelSurface): Boolean;
var
 Size : TPoint2px;
 Bits : Pointer;
 Pitch: Integer;
 Index: Integer;
 SegWidth: Integer;
 LinePtr : Pointer;
 ScanWidthBytes: Integer;
begin
 Result:= False;
 if (not Assigned(Buffer))or(Buffer.PixelFormat <> FFormat) then Exit;

 Size:= GetSizeOfLevel(Level);
 if (Size = ZeroPoint2px) then Exit;

 LockRect(nil, Level, Bits, Pitch);
 if (not Assigned(Bits))or(Pitch < 1) then Exit;

 SegWidth:= Min2(Size.x, Buffer.Width);

 ScanWidthBytes:= SegWidth * Buffer.BytesPerPixel;

 for Index:= 0 to Min2(Size.y, Buffer.Height) - 1 do
  begin
   LinePtr:= Pointer(PtrInt(Bits) + (Pitch * Index));

   Move(Buffer.Scanline[Index]^, LinePtr^, ScanWidthBytes);
  end;

 UnlockRect(nil, Level);
 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TDX7LockableTexture.UpdateMipmaps();
var
 Mipmaps, MipSurface: TPixelSurface;
 Level: Integer;
begin
 if (FSurfaceDesc.dwMipMapCount < 2) then Exit;

 Mipmaps:= TPixelSurface.Create();
 if (not GetPixelData(0, Mipmaps)) then
  begin
   FreeAndNil(Mipmaps);
   Exit;
  end;

 Mipmaps.GenerateMipMaps();

 for Level:= 1 to FSurfaceDesc.dwMipMapCount - 1 do
  begin
   MipSurface:= Mipmaps.MipMaps[Level - 1];
   if (not Assigned(MipSurface)) then Break;

   if (not SetPixelData(Level, MipSurface)) then Break;
  end;

 FreeAndNil(Mipmaps);
end;

//---------------------------------------------------------------------------
constructor TDX7RenderTargetTexture.Create();
begin
 inherited;

 FSurface   := nil;
 PrevSurface:= nil;

 FillChar(FSurfaceDesc, SizeOf(TDDSurfaceDesc), 0);
end;

//---------------------------------------------------------------------------
procedure TDX7RenderTargetTexture.InitSurfaceDesc();
begin
 FillChar(FSurfaceDesc, SizeOf(TDDSurfaceDesc2), 0);

 FSurfaceDesc.dwSize:= SizeOf(TDDSurfaceDesc2);

 FSurfaceDesc.dwFlags:= DDSD_CAPS or DDSD_HEIGHT or DDSD_WIDTH or
   DDSD_PIXELFORMAT or DDSD_TEXTURESTAGE;

 FSurfaceDesc.ddsCaps.dwCaps:= DDSCAPS_TEXTURE or DDSCAPS_3DDEVICE or
  DDSCAPS_VIDEOMEMORY;

 FSurfaceDesc.dwWidth := Width;
 FSurfaceDesc.dwHeight:= Height;

 AsphyreToDX7Format(FFormat, FSurfaceDesc.ddpfPixelFormat);
end;

//---------------------------------------------------------------------------
function TDX7RenderTargetTexture.CreateTextureSurface(): Boolean;
begin
 Result:= Assigned(DDraw7Obj);
 if (not Result) then Exit;

 InitSurfaceDesc();

 Result:= Succeeded(DDraw7Obj.CreateSurface(FSurfaceDesc, FSurface, nil));
 if (not Result) then Exit;

 Result:= Succeeded(FSurface.GetSurfaceDesc(FSurfaceDesc));
 if (not Result) then
  begin
   FSurface:= nil;
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TDX7RenderTargetTexture.DestroyTextureSurface();
begin
 if (Assigned(PrevSurface)) then PrevSurface:= nil;

 if (Assigned(FSurface)) then
  begin
   FSurface:= nil;
   FillChar(FSurfaceDesc, SizeOf(TDDSurfaceDesc), 0);
  end;
end;

//---------------------------------------------------------------------------
function TDX7RenderTargetTexture.CreateTexture(): Boolean;
begin
 FFormat:= DX7FindTextureFormat(FFormat);
 if (FFormat = apf_Unknown) then
  begin
   Result:= False;
   Exit;
  end;

 Result:= CreateTextureSurface();
end;

//---------------------------------------------------------------------------
procedure TDX7RenderTargetTexture.DestroyTexture();
begin
 DestroyTextureSurface();
end;

//---------------------------------------------------------------------------
procedure TDX7RenderTargetTexture.Bind(Stage: Integer);
begin
 if (Assigned(D3D7Device))and(Assigned(FSurface)) then
  D3D7Device.SetTexture(Stage, FSurface);
end;

//---------------------------------------------------------------------------
procedure TDX7RenderTargetTexture.HandleDeviceReset();
begin
 CreateTextureSurface();
end;

//---------------------------------------------------------------------------
procedure TDX7RenderTargetTexture.HandleDeviceLost();
begin
 DestroyTextureSurface();
end;

//---------------------------------------------------------------------------
procedure TDX7RenderTargetTexture.UpdateSize();
begin
 DestroyTextureSurface();
 CreateTextureSurface();
end;

//---------------------------------------------------------------------------
function TDX7RenderTargetTexture.BeginDrawTo(): Boolean;
var
 Viewport: TD3DViewport7;
begin
 Result:= (Assigned(FSurface))and(Assigned(D3D7Device));
 if (not Result) then Exit;

 Result:= Succeeded(D3D7Device.GetRenderTarget(PrevSurface));
 if (not Result) then Exit;

 Result:= Succeeded(D3D7Device.SetRenderTarget(FSurface, 0));
 if (not Result) then
  begin
   PrevSurface:= nil;
   Exit;
  end;

 Viewport.dwX:= 0;
 Viewport.dwY:= 0;
 Viewport.dwWidth := Width;
 Viewport.dwHeight:= Height;
 Viewport.dvMinZ:= 0.0;
 Viewport.dvMaxZ:= 1.0;

 D3D7Device.SetViewport(Viewport);
end;

//---------------------------------------------------------------------------
procedure TDX7RenderTargetTexture.EndDrawTo();
begin
 if (Assigned(D3D7Device)) then
  D3D7Device.SetRenderTarget(PrevSurface, 0);

 if (Assigned(PrevSurface)) then PrevSurface:= nil;
end;

//---------------------------------------------------------------------------
end.
