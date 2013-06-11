unit Asphyre.Textures;
//---------------------------------------------------------------------------
// Asphyre Custom Texture implementation.
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
{< Texture specification and general implementation common to all providers
   in Asphyre framework. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.Types, Asphyre.TypeDef, Asphyre.Math, Asphyre.Types;

//---------------------------------------------------------------------------
type
{ General texture specification, which specifies common parameters and
  provides basic utilities. }
 TAsphyreCustomTexture = class
 private
  FWidth : Integer;
  FHeight: Integer;
  FActive: Boolean;

  FMipMapping: Boolean;

  procedure SetSize(const Index: Integer; Value: Integer);
  procedure SetMipmapping(const Value: Boolean);
  procedure SetFormat(const Value: TAsphyrePixelFormat);
 protected
  FFormat: TAsphyrePixelFormat;

  function GetBytesPerPixel(): Integer; virtual;
  procedure UpdateSize(); virtual;

  function CreateTexture(): Boolean; virtual;
  procedure DestroyTexture(); virtual;
 public
  { The pixel format of the texture's surface and its mipmap levels. }
  property Format: TAsphyrePixelFormat read FFormat write SetFormat;

  { The width of texture's surface or first mipmap level. }
  property Width : Integer index 0 read FWidth write SetSize;

  { The height of texture's surface or first mipmap level. }
  property Height: Integer index 1 read FHeight write SetSize;

  { Indicates whether the texture has been created and initialized properly. }
  property Active: Boolean read FActive;

  { Indicates how many bytes each pixel in texture occupies. }
  property BytesPerPixel: Integer read GetBytesPerPixel;

  { Determines whether mipmapping should be used for this texture. If this
    parameter is set to @True, a full set of mipmap levels will be used in
    the texture and handled by its specific provider implementation. Mipmapping
    is used when the texture is drawn in significantly smaller sizes to
    improve visual quality of the displayed image. }
  property Mipmapping: Boolean read FMipMapping write SetMipmapping;

  { Initializes the texture creating all provider specific resources. If this
    method succeeds, the texture can be used for rendering and the returned
    value is @True. If the returned value is @False, it means that the texture
    initialization failed and configuration parameters need to be revised. }
  function Initialize(): Boolean;

  { Finalizes the texture releasing all provider specific resources. }
  procedure Finalize();

  { Returns the pointer to shader resource view when used in latest DX10+
    providers. }
  function GetResourceView(): Pointer; virtual;

  { Binds the texture to the given stage index in DX9- and OGL providers. }
  procedure Bind(Stage: Integer); virtual;

  {@exclude}procedure HandleDeviceReset(); virtual;
  {@exclude}procedure HandleDeviceLost(); virtual;

  { Converts 2D integer pixel coordinates to their logical representation
    provided in range of [0..1]. }
  function PixelToLogical(const Pos: TPoint2px): TPoint2; overload;

  { Converts 2D floating-point pixel coordinates to their logical
    representation provided in range of [0..1]. }
  function PixelToLogical(const Pos: TPoint2): TPoint2; overload;

  { Converts 2D logic texture coordinates in range of [0..1] to pixel
    coordinates. }
  function LogicalToPixel(const Pos: TPoint2): TPoint2px;

  { Updates all mipmap images contained in the texture. This should only be
    used when @link(Mipmapping) is set to @True. }
  procedure UpdateMipmaps(); virtual;

  {@exclude}constructor Create(); virtual;
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{ Lockable texture specification where full support is provided for direct
  access to texture pixel data. This texture can typically be loaded from
  disk and can have its pixels modified while the application is running.
  This is the most common type of textures used in Asphyre framework. }
 TAsphyreLockableTexture = class(TAsphyreCustomTexture)
 private
  FDynamicTexture: Boolean;

  function GetPixel(x, y: Integer): Cardinal;
  procedure SetPixel(x, y: Integer; const Value: Cardinal);
  procedure SetDynamicTexture(const Value: Boolean);
 public
  { This property provides direct access to texture's pixels. The pixel values
    are handled in 32-bit RGBA pixel format (@code(apf_A8R8G8B8). If the actual
    pixel format used in the texture is different, the conversion is done
    automatically. In some providers using this property may induce significant
    performance hit, especially if mipmapping is enabled. For
    performance-critical applications it is better to get access to all texture
    pixels at once using @link(Lock) and @link(Unlock) methods instead. }
  property Pixels[x, y: Integer]: Cardinal read GetPixel write SetPixel;

  { Determines whether the texture will be used for frequent access and
    updates. This is useful for textures that are modified at least once
    per rendering frame. }
  property DynamicTexture: Boolean read FDynamicTexture write SetDynamicTexture;

  { Provides access to the raw texture's pixel data. If mipmapping is enabled,
    this gives access to the top-level mipmap (other mipmaps will be updated
    automatically). After accessing the texture's pixel data it is necessary
    to call @link(Unlock).
     @param(Rect The rectangle inside the texture that will be updated. For
      dynamic textures this rectangle should cover the entire texture in some
      providers.)
     @param(Bits In this parameter the pointer to the top-left pixel is
      provided within the specified rectangle. If the method fails, @nil is
      returned.)
     @param(Pitch The number of bytes that each scanline occupies in the
      texture. This value can be used for accessing individual rows when
      accessing pixel data. If the method fails, zero is returned.) }
  procedure Lock(const Rect: TRect; out Bits: Pointer;
   out Pitch: Integer); virtual; abstract;

  { Finishes accessing texture's pixel data. If mipmapping is enabled, other
    mipmap levels are updated automatically. }
  procedure Unlock(); virtual; abstract;

  {@exclude}constructor Create(); override;
 end;

//---------------------------------------------------------------------------
{ Render target texture specification which supports drawing the entire
  scene directly on the texture. This type of texture may not be supported on
  some providers. It can be used for advanced multi-pass rendering effects. }
 TAsphyreRenderTargetTexture = class(TAsphyreCustomTexture)
 private
  FDepthStencil: Boolean;

  procedure SetDepthStencil(const Value: Boolean);
  procedure SetMultisamples(const Value: Integer);
 protected
  FMultisamples: Integer;
 public
  { Determines whether depth-stencil buffer should be created and used with
    this texture. }
  property DepthStencil: Boolean read FDepthStencil write SetDepthStencil;

  { Determines the number of samples used for antialiasing. This parameter is
    supported only on the newest DX10+ providers. }
  property Multisamples: Integer read FMultisamples write SetMultisamples;

  {@exclude}function BeginDrawTo(): Boolean; virtual; abstract;
  {@exclude}procedure EndDrawTo(); virtual; abstract;

  {@exclude}constructor Create(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Formats;

//---------------------------------------------------------------------------
constructor TAsphyreCustomTexture.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 FWidth := 256;
 FHeight:= 256;
 FActive:= False;
 FFormat:= apf_Unknown;

 FMipmapping:= False;
end;

//---------------------------------------------------------------------------
destructor TAsphyreCustomTexture.Destroy();
begin
 Dec(AsphyreClassInstances);

 if (FActive) then Finalize();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCustomTexture.SetFormat(const Value: TAsphyrePixelFormat);
begin
 if (not FActive) then FFormat:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCustomTexture.SetSize(const Index: Integer;
 Value: Integer);
begin
 case Index of
  0: FWidth := Value;
  1: FHeight:= Value;
 end;

 if (FActive) then UpdateSize();
end;

//---------------------------------------------------------------------------
procedure TAsphyreCustomTexture.UpdateSize();
begin
 // no code
end;

//---------------------------------------------------------------------------
function TAsphyreCustomTexture.GetBytesPerPixel(): Integer;
begin
 Result:= AsphyrePixelFormatBits[FFormat] div 8;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCustomTexture.SetMipmapping(const Value: Boolean);
begin
 if (not FActive) then FMipmapping:= Value;
end;

//---------------------------------------------------------------------------
function TAsphyreCustomTexture.CreateTexture(): Boolean;
begin
 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCustomTexture.DestroyTexture();
begin
 // no code
end;

//---------------------------------------------------------------------------
function TAsphyreCustomTexture.Initialize(): Boolean;
begin
 Result:= not FActive;
 if (not Result) then Exit;

 Result := CreateTexture();
 FActive:= Result;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCustomTexture.Finalize();
begin
 if (FActive) then DestroyTexture();
 FActive:= False;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCustomTexture.HandleDeviceReset();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TAsphyreCustomTexture.HandleDeviceLost();
begin
 // no code
end;

//---------------------------------------------------------------------------
function TAsphyreCustomTexture.GetResourceView(): Pointer;
begin
 Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TAsphyreCustomTexture.Bind(Stage: Integer);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TAsphyreCustomTexture.UpdateMipmaps();
begin
 // no code
end;

//---------------------------------------------------------------------------
function TAsphyreCustomTexture.PixelToLogical(const Pos: TPoint2): TPoint2;
begin
 if (FWidth > 0) then Result.x:= Pos.x / FWidth
  else Result.x:= 0.0;

 if (FHeight > 0) then Result.y:= Pos.y / FHeight
  else Result.y:= 0.0;
end;

//---------------------------------------------------------------------------
function TAsphyreCustomTexture.PixelToLogical(const Pos: TPoint2px): TPoint2;
begin
 if (FWidth > 0) then Result.x:= Pos.x / FWidth
  else Result.x:= 0.0;

 if (FHeight > 0) then Result.y:= Pos.y / FHeight
  else Result.y:= 0.0;
end;

//---------------------------------------------------------------------------
function TAsphyreCustomTexture.LogicalToPixel(const Pos: TPoint2): TPoint2px;
begin
 Result.x:= Round(Pos.x * FWidth);
 Result.y:= Round(Pos.y * FHeight);
end;

//---------------------------------------------------------------------------
constructor TAsphyreLockableTexture.Create();
begin
 inherited;

 FDynamicTexture:= False;
end;

//---------------------------------------------------------------------------
procedure TAsphyreLockableTexture.SetDynamicTexture(const Value: Boolean);
begin
 if (not Active) then FDynamicTexture:= Value;
end;

//---------------------------------------------------------------------------
function TAsphyreLockableTexture.GetPixel(x, y: Integer): Cardinal;
var
 Bits : Pointer;
 Pitch: Integer;
begin
 Result:= 0;
 if (x < 0)or(y < 0)or(x >= FWidth)or(y >= FHeight) then Exit;

 Lock(Bounds(0, y, FWidth, 1), Bits, Pitch);
 if (not Assigned(Bits)) then Exit;

 Result:= PixelXto32(Pointer(PtrInt(Bits) + PtrInt(x) * BytesPerPixel),
  FFormat);

 Unlock();
end;

//---------------------------------------------------------------------------
procedure TAsphyreLockableTexture.SetPixel(x, y: Integer;
 const Value: Cardinal);
var
 Bits : Pointer;
 Pitch: Integer;
begin
 if (x < 0)or(y < 0)or(x >= FWidth)or(y >= FHeight) then Exit;

 Lock(Bounds(0, y, FWidth, 1), Bits, Pitch);
 if (not Assigned(Bits)) then Exit;

 Pixel32toX(Value, Pointer(PtrInt(Bits) + PtrInt(x) * BytesPerPixel),
  FFormat);

 Unlock();
end;

//---------------------------------------------------------------------------
constructor TAsphyreRenderTargetTexture.Create();
begin
 inherited;

 FDepthStencil:= False;
 FMultisamples:= 0;
end;

//---------------------------------------------------------------------------
procedure TAsphyreRenderTargetTexture.SetDepthStencil(const Value: Boolean);
begin
 if (not Active) then FDepthStencil:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreRenderTargetTexture.SetMultisamples(const Value: Integer);
begin
 if (not Active) then FMultisamples:= Value;
end;

//---------------------------------------------------------------------------
end.
