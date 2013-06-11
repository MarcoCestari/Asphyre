unit Asphyre.Images;
//---------------------------------------------------------------------------
// Hardware-accelerated multi-purpose image class for Asphyre.
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
// Note: this file has been preformatted to be used with PasDoc.
//---------------------------------------------------------------------------
{< Classes and utilities for handling images that contain multiple patterns
   and textures suitable for 2D and 3D rendering. The images can be loaded
   directly from disk, Asphyre archives or even created manually. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.Types, System.SysUtils, System.Classes, Asphyre.TypeDef, 
 Asphyre.Math, Asphyre.Types, Asphyre.Archives, Asphyre.Textures;

//---------------------------------------------------------------------------
type
{ 2-dimensional image implementation that may contain one or more patterns
  and/or textures which can be rendered on Asphyre's canvas. The image data can
  be loaded quickly from Asphyre archives or from external file on disk. The
  image supports different pixel formats with or without alpha-channel,
  mipmapping and dynamic access. }
 TAsphyreImage = class
 private
  FName: UniString;

  Textures: array of TAsphyreLockableTexture;

  FPatternCount: Integer;
  FPatternSize : TPoint2px;
  FVisibleSize : TPoint2px;
  FMipMapping  : Boolean;
  FPixelFormat : TAsphyrePixelFormat;
  FDynamicImage: Boolean;

  function GetTexture(Index: Integer): TAsphyreLockableTexture;
  function GetTextureCount(): Integer;

  function UploadStreamNative(Stream: TStream;
   Texture: TAsphyreLockableTexture): Boolean;
  function UploadStream32toX(Stream: TStream;
   Texture: TAsphyreLockableTexture): Boolean;
  function UploadStreamXtoX(Stream: TStream; Texture: TAsphyreLockableTexture;
   InFormat: TAsphyrePixelFormat): Boolean;

  function FindPatternTex(Pattern: Integer; out PatInRow,
   PatInCol: Integer): Integer;
  procedure FindPatternMapping(Pattern, PatInRow, PatInCol: Integer;
   Tex: TAsphyreLockableTexture; var Mapping: TPoint4); overload;
  procedure FindPatternMapping(Pattern, PatInRow, PatInCol: Integer;
   const ViewPos, ViewSize: TPoint2px; Tex: TAsphyreLockableTexture;
   var Mapping: TPoint4); overload;
 public
  { The unique name of image that identifies it in the owner's list. }
  property Name: UniString read FName write FName;

  { The total number of patterns contained within the image. }
  property PatternCount: Integer read FPatternCount write FPatternCount;

  { The size of individual pattern inside the image. If no patterns are
    stored, this size should match the texture's size. }
  property PatternSize: TPoint2px read FPatternSize write FPatternSize;

  { The visible area inside of each image's pattern that will be used in
    rendering. This size must be smaller or equal to @link(PatternSize). }
  property VisibleSize: TPoint2px read FVisibleSize write FVisibleSize;

  { Determines whether the image should contain mipmap data. This can increase
    memory consumption and slow down the loading of images, but produces better
    visual results when the image is shrunken to smaller sizes. }
  property MipMapping: Boolean read FMipMapping write FMipMapping;

  { The pixel format that will be used in all image's textures. This parameter
    is actually a suggestion and different format may be used in the textures,
    depending on hardware support; if this format is not supported, usually
    the closest format will be chosen in textures. When loading pixel data from
    archives or external files, the conversion will be done automatically, if
    the texture format does not match the stored pixel format. }
  property PixelFormat: TAsphyrePixelFormat read FPixelFormat write FPixelFormat;

  { Determines whether this image requires frequent access to its pixel data.
    If this parameter is set to @True, dynamic textures will be used, where
    pixel data can be updated frequently. This should be used when image pixels
    need to be updated at least once per frame. }
  property DynamicImage: Boolean read FDynamicImage write FDynamicImage;

  { The number of textures used in the image. }
  property TextureCount: Integer read GetTextureCount;

  { Provides access to image's individual textures by using index, which should
    be in range of [0..(TextureCount - 1)]. If the index is outside of valid
    range, the returned value will be @nil. }
  property Texture[Index: Integer]: TAsphyreLockableTexture read GetTexture;

  { Inserts new texture to the end of the list. The texture is added to the
    image's list of textures without initializing. The index of newly added
    texture is returned. }
  function InsertTexture(): Integer; overload;

  { Inserts new texture to the end of the list. The texture is initialized
    first with the specified size. The reference to newly added texture is
    returned and the texture is added to image's list of textures only
    if initialization succeeds. If initialization fails, @nil is returned and
    no texture is added to the list. }
  function InsertTexture(Width,
   Height: Integer): TAsphyreLockableTexture; overload;

  { Removes the texture specified by the given index from the list. The index
    should be in range of [0..(TextureCount - 1)]. If the index is outside
    of valid range, this method does nothing. }
  procedure RemoveTexture(Index: Integer);

  { Inserts the specified texture sample to the list of image's textures and
    returns its new index. }
  function IndexOfTexture(Sample: TAsphyreLockableTexture): Integer;

  { Removes and releases all image's textures. }
  procedure RemoveAllTextures();

  { Loads image in its native Asphyre specification from the stream. This
    function returns @True if it succeeds and @False otherwise. This image
    format is used when adding images to Asphyre archives using
    @italic(AsphyreManager) tool. }
  function LoadFromStream(Stream: TStream): Boolean;

  { Loads image consisting of a single texture from external file on disk.
    This function returns @True on success and @False otherwise. }
  function LoadFromFile(const FileName: StdString): Boolean;

  { Loads image in its native Asphyre specification from Asphyre archive. The
    image should be previously added to the archive using
    @italic(AsphyreManager) tool. }
  function LoadFromArchive(const Key: UniString;
   Archive: TAsphyreArchive): Boolean;

  //.........................................................................
  { Retrieves the texture's index that matches the specified pattern number.
    The texture mapping coordinates for that pattern are also returned. If no
    texture matches the specified pattern, -1 is returned and texture mapping
    coordinates are not modified. }
  function RetrieveTex(Pattern: Integer;
   var Mapping: TPoint4): Integer; overload;

  { Retrieves the texture's index that matches the specified pattern number.
    The texture mapping coordinates for that pattern are also returned. If no
    texture matches the specified pattern, -1 is returned and texture mapping
    coordinates are not modified. }
  function RetrieveTex(Pattern: Integer; const SrcRect: TRect; Mirror,
   Flip: Boolean; var Mapping: TPoint4): Integer; overload;

  {@exclude}procedure HandleDeviceReset(); virtual;
  {@exclude}procedure HandleDeviceLost(); virtual;

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{ The list of 2-dimensional images that may contain many patterns and/or
  textures which can be rendered on Asphyre's canvas. }
 TAsphyreImages = class
 private
  Images: array of TAsphyreImage;

  SearchObjects: array of Integer;
  SearchDirty  : Boolean;

  FOnItemLoad: TResourceProcessEvent;
  FOnItemFail: TResourceProcessEvent;

  Archive: TAsphyreArchive;

  function GetItem(Index: Integer): TAsphyreImage;
  function GetItemCount(): Integer;

  function FindEmptySlot(): Integer;
  function Insert(Image: TAsphyreImage): Integer;

  procedure OnDeviceDestroy(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);
  procedure OnDeviceReset(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);
  procedure OnDeviceLost(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);

  procedure InitSearchObjects();
  procedure SwapSearchObjects(Index1, Index2: Integer);
  function CompareSearchObjects(Obj1, Obj2: TAsphyreImage): Integer;
  function SplitSearchObjects(Start, Stop: Integer): Integer;
  procedure SortSearchObjects(Start, Stop: Integer);
  procedure UpdateSearchObjects();
  function GetImage(const Name: UniString): TAsphyreImage;
 public
  { The number of images in the list. }
  property ItemCount: Integer read GetItemCount;

  { Provides access to individual images in the list by using index that should
    be specified in [0..(ItemCount - 1)] range. If the index is outside of
    valid range, the returned value is @nil. }
  property Items[Index: Integer]: TAsphyreImage read GetItem; default;

  { Retrieves the image in the list that has the specified unique name (not
    case sensitive); binary search is used for looking for the requested
    image. }
  property Image[const Name: UniString]: TAsphyreImage read GetImage;

  //.........................................................................
  { This event occurs when a new image is being loaded on request inside
    @link(Resolve) function. }
  property OnItemLoad: TResourceProcessEvent read FOnItemLoad write FOnItemLoad;

  { This event occurs when the requested image could not be loaded inside
    @link(Resolve) function either because its meta-data is not found or
    because it could not be loaded from its specified location. }
  property OnItemFail: TResourceProcessEvent read FOnItemFail write FOnItemFail;

  //.........................................................................
  { Returns the index of the specified image in the list. If the image is not
    in the list, the returned value is -1. }
  function IndexOf(Element: TAsphyreImage): Integer; overload;

  { Returns the index of the image having the specified unique name (not
    case sensitive). This function uses binary search for finding the requested
    image quickly. If the image is not found, -1 is returned. }
  function IndexOf(const Name: UniString): Integer; overload;

  //.........................................................................
  { Includes the specified image to the end of the list and returns its
    index. If the image already exists in the list, this function returns
    the index where the image is found. }
  function Include(Element: TAsphyreImage): Integer;

  { Removes image at the specified index and releases its memory. The index
    must be specified in [0..(ItemCount - 1)] range. If the specified index is
    outside of valid range, this method does nothing. }
  procedure Remove(Index: Integer);

  //.........................................................................
  { Adds a new image to the list and loads its data from the specified
    Asphyre archive. If the function succeeds, the index of newly added image
    is returned. If the function fails, nothing is added to the list and
    -1 is returned. This function sets the pixel format that was used for
    storage to be used for image's texture creation. If the stored pixel
    format is not supported in hardware, the closest match will be used and
    the conversion will be done automatically.
     @param(Key The archive's key that identifies the image's record.)
     @param(AArchive The reference to the existing instance of Asphyre archive
      where the image should be loaded from.)
     @param(Name The name of the newly added image to the list. If this
      parameter is not set (or set to empty StdString), the default image name
      will be used equalling to @code(Key) parameter with any path information
      stripped.)
     @param(MipMapping This parameter determines whether mipmapping should
      be automatically enabled for the loaded image.) }
  function AddFromArchive(const Key: UniString; AArchive: TAsphyreArchive;
   const Name: UniString = ''; MipMapping: Boolean = True): Integer;

  //.........................................................................
  { Adds a new image to the list and loads its data from the specified
    Asphyre archive. If the function succeeds, the index of newly added image
    is returned. If the function fails, nothing is added to the list and
    -1 is returned. This function when compared to @link(AddFromArchive) has
    more parameters to be set for the loaded image.
     @param(Key The archive's key that identifies the image's record.)
     @param(AArchive The reference to the existing instance of Asphyre archive
      where the image should be loaded from.)
     @param(Name The name of the newly added image to the list. If this
      parameter is not set (or set to empty StdString), the default image name
      will be used equalling to @code(Key) parameter with any path information
      stripped.)
     @param(PixelFormat The pixel format that should be used for the created
      image. If this pixel format is not supported in hardware, the closest
      match will be used. If this value is set to @code(apf_Unknown), the
      pixel format matching the stored image will be used. If the image is
      created with different pixel format than the stored one, the conversion
      will be made automatically.
     @param(MipMapping This parameter determines whether mipmapping should
      be automatically enabled for the loaded image.)
     @param(DynamicImage This parameter can be used for specifying that the
      loaded image will be a dynamic image; that is, its pixel data will be
      updated frequently.) }
  function AddFromArchiveEx(const Key: UniString; AArchive: TAsphyreArchive;
   const Name: UniString = ''; PixelFormat: TAsphyrePixelFormat = apf_Unknown;
   MipMapping: Boolean = True; DynamicImage: Boolean = False): Integer;

  //.........................................................................
  { Adds a new image to the list and loads its data from the specified
    external file on disk. If the function succeeds, the index of newly added
    image is returned. If the function fails, nothing is added to the list and
    -1 is returned. This function sets the pixel format that best matches the
    loaded file's pixel format for image's texture creation. If the source
    pixel format is not supported in hardware, the closest match will be used
    and the conversion will be done automatically.
     @param(FileName The name of the file to load the image from. The image
      is loaded using functions from @code(Asphyre.Bitmaps.pas), so to support
      different image formats it is necessary to add the respective units to
      the project (e.g. "AsphyrePNG" to USES list).)
     @param(Name The name of the newly added image to the list. If this
      parameter is not set (or set to empty StdString), the default image name
      will be used equalling to file name with any path information stripped.)
     @param(MipMapping This parameter determines whether mipmapping should
      be automatically enabled for the loaded image.) }
  function AddFromFile(const FileName: StdString; const Name: UniString = '';
   MipMapping: Boolean = True): Integer;

  //.........................................................................
  { Adds a new image to the list and loads its data from the specified
    external file on disk. If the function succeeds, the index of newly added
    image is returned. If the function fails, nothing is added to the list and
    -1 is returned. This function when compared to @link(AddFromFile) has
    more parameters to be set for the loaded image.
     @param(FileName The name of the file to load the image from. The image
      is loaded using functions from @code(Asphyre.Bitmaps.pas), so to support
      different image formats it is necessary to add the respective units to
      the project (e.g. "AsphyrePNG" to USES list).)
     @param(Name The name of the newly added image to the list. If this
      parameter is not set (or set to empty StdString), the default image name
      will be used equalling to file name with any path information stripped.)
     @param(PixelFormat The pixel format that should be used for the created
      image. If this pixel format is not supported in hardware, the closest
      match will be used. If this value is set to @code(apf_Unknown), the
      pixel format that closely resembles the image file will be used. If the
      image is created with different pixel format than the stored one, the
      conversion will be made automatically.
     @param(MipMapping This parameter determines whether mipmapping should
      be automatically enabled for the loaded image.)
     @param(DynamicImage This parameter can be used for specifying that the
      loaded image will be a dynamic image; that is, its pixel data will be
      updated frequently.) }
  function AddFromFileEx(const FileName: StdString;
   const Name: UniString = ''; PixelFormat: TAsphyrePixelFormat = apf_Unknown;
   MipMapping: Boolean = True; DynamicImage: Boolean = False): Integer;

  //.........................................................................
  { Resolves the unique image name and returns its index in the list. This
    function uses meta-data describing all images available to the application
    and if the specified image name is not found among the existing images,
    the image is loaded from disk using its meta-data specification.
    @link(OnItemLoad) event is called when the image is about to be loaded and
    @link(OnItemFail) is called when the image is either not found in the
    meta-data or cannot be loaded with the specified information. If the
    method succeeds, the index of existing (or loaded) image is returned and
    -1 is returned otherwise. }
  function Resolve(const Name: UniString): Integer;

  //.........................................................................
  { Removes all images from the list and releases them from memory. }
  procedure RemoveAll();

  //.........................................................................
  { Notifies the image list that one of the image's names has been changed
    and that internal structure should be updated so that methods that
    search for images by their name can work properly. }
  procedure MarkSearchDirty();

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Streams, Asphyre.Strings, Asphyre.Formats, Asphyre.Providers,
 Asphyre.Events.Types, Asphyre.Events, Asphyre.Media.Utils,
 Asphyre.Archives.Auth, Asphyre.Surfaces, Asphyre.Bitmaps,
 Asphyre.Media.Images;

//---------------------------------------------------------------------------
constructor TAsphyreImage.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 FPatternCount:= -1;
 FPatternSize := ZeroPoint2px;
 FMipMapping  := False;
 FPixelFormat := apf_Unknown;
 FDynamicImage:= False;
end;

//---------------------------------------------------------------------------
destructor TAsphyreImage.Destroy();
begin
 Dec(AsphyreClassInstances);

 RemoveAllTextures();

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreImage.GetTexture(Index: Integer): TAsphyreLockableTexture;
begin
 if (Index >= 0)and(Index < Length(Textures)) then
  Result:= Textures[Index] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TAsphyreImage.GetTextureCount(): Integer;
begin
 Result:= Length(Textures);
end;

//---------------------------------------------------------------------------
procedure TAsphyreImage.HandleDeviceReset();
var
 i: Integer;
begin
 for i:= 0 to Length(Textures) - 1 do
  if (Assigned(Textures[i])) then Textures[i].HandleDeviceReset();
end;

//---------------------------------------------------------------------------
procedure TAsphyreImage.HandleDeviceLost();
var
 i: Integer;
begin
 for i:= 0 to Length(Textures) - 1 do
  if (Assigned(Textures[i])) then Textures[i].HandleDeviceLost();
end;

//---------------------------------------------------------------------------
function TAsphyreImage.InsertTexture(): Integer;
var
 Item: TAsphyreLockableTexture;
begin
 Item:= Factory.CreateLockableTexture();
 if (not Assigned(Item)) then
  begin
   Result:= -1;
   Exit;
  end;

 Result:= Length(Textures);
 SetLength(Textures, Result + 1);

 Textures[Result]:= Item;
end;

//---------------------------------------------------------------------------
function TAsphyreImage.IndexOfTexture(Sample: TAsphyreLockableTexture): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Textures) - 1 do
  if (Textures[i] = Sample) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImage.RemoveTexture(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Textures)) then Exit;

 if (Assigned(Textures[Index])) then FreeAndNil(Textures[Index]);

 for i:= Index to Length(Textures) - 2 do
  Textures[i]:= Textures[i + 1];

 SetLength(Textures, Length(Textures) - 1);
end;

//---------------------------------------------------------------------------
procedure TAsphyreImage.RemoveAllTextures();
var
 i: Integer;
begin
 for i:= 0 to Length(Textures) - 1 do
  if (Assigned(Textures[i])) then FreeAndNil(Textures[i]);

 SetLength(Textures, 0);
end;

//---------------------------------------------------------------------------
function TAsphyreImage.InsertTexture(Width,
 Height: Integer): TAsphyreLockableTexture;
var
 Index: Integer;
begin
 Result:= Factory.CreateLockableTexture();
 if (not Assigned(Result)) then Exit;

 Result.Width := Width;
 Result.Height:= Height;
 Result.Format:= FPixelFormat;

 Result.MipMapping:= FMipMapping;
 Result.DynamicTexture:= FDynamicImage;

 if (not Result.Initialize()) then
  begin
   FreeAndNil(Result);
   Exit;
  end;

 Index:= Length(Textures);
 SetLength(Textures, Index + 1);

 Textures[Index]:= Result;
end;

//---------------------------------------------------------------------------
function TAsphyreImage.LoadFromFile(const FileName: StdString): Boolean;
var
 Surf   : TSystemSurface;
 Bits   : Pointer;
 Pitch  : Integer;
 NewTex : TAsphyreLockableTexture;
 WritePx: Pointer;
 Index  : Integer;
begin
 Surf:= TSystemSurface.Create();

 Result:= BitmapManager.LoadFromFile(FileName, Surf);
 if (not Result) then
  begin
   FreeAndNil(Surf);
   Exit;
  end;

 RemoveAllTextures();

 FPixelFormat:= apf_A8R8G8B8;

 NewTex:= InsertTexture(Surf.Width, Surf.Height);
 if (not Assigned(NewTex)) then
  begin
   FreeAndNil(Surf);
   Result:= False;
   Exit;
  end;

 NewTex.Lock(Bounds(0, 0, NewTex.Width, NewTex.Height), Bits, Pitch);
 if (not Assigned(Bits))or(Pitch < 1) then
  begin
   RemoveAllTextures();
   FreeAndNil(Surf);
   Result:= False;
   Exit;
  end;

 WritePx:= Bits;

 for Index:= 0 to Surf.Height - 1 do
  begin
   Pixel32toXArray(Surf.ScanLine[Index], WritePx, NewTex.Format, Surf.Width);

   Inc(PtrInt(WritePx), Pitch);
  end;

 NewTex.Unlock();
 FreeAndNil(Surf);

 if (NewTex.MipMapping) then NewTex.UpdateMipmaps();
 Result:= True;
end;

//---------------------------------------------------------------------------
function TAsphyreImage.UploadStreamNative(Stream: TStream;
 Texture: TAsphyreLockableTexture): Boolean;
var
 Bits : Pointer;
 Pitch: Integer;
 Bytes: Integer;
 Index: Integer;
begin
 Texture.Lock(Bounds(0, 0, Texture.Width, Texture.Height), Bits, Pitch);

 Result:= (Assigned(Bits))and(Pitch > 0);
 if (not Result) then
  begin
   Result:= False;
   Exit;
  end;

 Bytes:= Texture.BytesPerPixel * Texture.Width;

 for Index:= 0 to Texture.Height - 1 do
  begin
   Result:= Stream.Read(Bits^, Bytes) = Bytes;
   if (not Result) then Break;

   Inc(PtrInt(Bits), Pitch);
  end;

 Texture.Unlock();
end;

//---------------------------------------------------------------------------
function TAsphyreImage.UploadStream32toX(Stream: TStream;
 Texture: TAsphyreLockableTexture): Boolean;
var
 Bits  : Pointer;
 Pitch : Integer;
 InMem : Pointer;
 InSize: Integer;
 Index : Integer;
begin
 Texture.Lock(Bounds(0, 0, Texture.Width, Texture.Height), Bits, Pitch);

 Result:= (Assigned(Bits))and(Pitch > 0);
 if (not Result) then
  begin
   Result:= False;
   Exit;
  end;

 InSize:= Texture.Width * 4;
 InMem := AllocMem(InSize);

 for Index:= 0 to Texture.Height - 1 do
  begin
   Result:= Stream.Read(InMem^, InSize) = InSize;
   if (not Result) then Break;

   Pixel32toXArray(InMem, Bits, Texture.Format, Texture.Width);

   Inc(PtrInt(Bits), Pitch);
  end;

 FreeMem(InMem);

 Texture.Unlock();
end;

//---------------------------------------------------------------------------
function TAsphyreImage.UploadStreamXtoX(Stream: TStream;
 Texture: TAsphyreLockableTexture; InFormat: TAsphyrePixelFormat): Boolean;
var
 Bits   : Pointer;
 Pitch  : Integer;
 InMem  : Pointer;
 InSize : Integer;
 AuxMem : Pointer;
 AuxSize: Integer;
 Index  : Integer;
begin
 Texture.Lock(Bounds(0, 0, Texture.Width, Texture.Height), Bits, Pitch);

 Result:= (Assigned(Bits))and(Pitch > 0);
 if (not Result) then
  begin
   Result:= False;
   Exit;
  end;

 InSize:= (AsphyrePixelFormatBits[InFormat] * Texture.Width) div 8;
 InMem := AllocMem(InSize);

 AuxSize:= Texture.Width * 4;
 AuxMem := AllocMem(AuxSize);

 for Index:= 0 to Texture.Height - 1 do
  begin
   Result:= Stream.Read(InMem^, InSize) = InSize;
   if (not Result) then Break;

   PixelXto32Array(InMem, AuxMem, InFormat, Texture.Width);
   Pixel32toXArray(AuxMem, Bits, Texture.Format, Texture.Width);

   Inc(PtrInt(Bits), Pitch);
  end;

 FreeMem(AuxMem);
 FreeMem(InMem);

 Texture.Unlock();
end;

//---------------------------------------------------------------------------
function TAsphyreImage.LoadFromStream(Stream: TStream): Boolean;
var
 StoredFormat: TAsphyrePixelFormat;
 TextureSize : TPoint2px;
 TextCount   : Integer;
 TextureNo   : Integer;
 TextureItem : TAsphyreLockableTexture;
begin
 RemoveAllTextures();

 Result:= True;

 try
  // --> Format
  StoredFormat:= TAsphyrePixelFormat(StreamGetByte(Stream));
  // --> Pattern Size
  FPatternSize.x:= StreamGetWord(Stream);
  FPatternSize.y:= StreamGetWord(Stream);
  // --> Pattern Count
  FPatternCount:= StreamGetLongint(Stream);
  // --> Visible Size
  FVisibleSize.x:= StreamGetWord(Stream);
  FVisibleSize.y:= StreamGetWord(Stream);
  // --> Texture Size
  TextureSize.x:= StreamGetWord(Stream);
  TextureSize.y:= StreamGetWord(Stream);
  // --> Texture Count
  TextCount:= StreamGetWord(Stream);
 except
  Result:= False;
  Exit;
 end;

 if (FPixelFormat = apf_Unknown) then FPixelFormat:= StoredFormat;

 for TextureNo:= 0 to TextCount - 1 do
  begin
   TextureItem:= InsertTexture(TextureSize.x, TextureSize.y);
   if (TextureItem = nil) then
    begin
     RemoveAllTextures();
     Result:= False;
     Exit;
    end;                           

   if (StoredFormat = TextureItem.Format) then
    begin
     Result:= UploadStreamNative(Stream, TextureItem);
    end else
    begin
     if (StoredFormat = apf_A8R8G8B8) then UploadStream32toX(Stream, TextureItem)
      else UploadStreamXtoX(Stream, TextureItem, StoredFormat);
    end;
   if (not Result) then
    begin
     RemoveAllTextures();
     Break;
    end;

   if (TextureItem.MipMapping) then TextureItem.UpdateMipmaps();
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreImage.LoadFromArchive(const Key: UniString;
 Archive: TAsphyreArchive): Boolean;
var
 Stream: TMemoryStream;
begin
 // (1) Provide password for the archive.
 Auth.Authorize(Self, Archive);

 // (2) Read the requested record as stream.
 Stream:= TMemoryStream.Create();

 Result:= Archive.ReadMemStream(Key, Stream);
 if (not Result) then
  begin
   Auth.Unauthorize();
   FreeAndNil(Stream);
   Exit;
  end;

 // (3) Burn the archive password.
 Auth.Unauthorize();

 // (4) Load graphics data from stream.
 Stream.Seek(0, soFromBeginning);
 Result:= LoadFromStream(Stream);

 // (5) Release the stream.
 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
function TAsphyreImage.FindPatternTex(Pattern: Integer; out PatInRow,
 PatInCol: Integer): Integer;
var
 TexIndex, PatInTex: Integer;
begin
 TexIndex:= 0;
 PatInTex:= -1;
 PatInRow:= 1;
 PatInCol:= 1;

 // Cycle through textures to find where Pattern is located.
 while (TexIndex < Length(Textures)) do
  begin
   PatInRow:= Textures[TexIndex].Width div FPatternSize.x;
   PatInCol:= Textures[TexIndex].Height div FPatternSize.y;
   PatInTex:= PatInRow * PatInCol;

   if (Pattern >= PatInTex) then
    begin
     Inc(TexIndex);
     Dec(Pattern, PatInTex);
    end else Break;
  end;

 // If couldn't find the desired texture, just exit.
 if (TexIndex >= Length(Textures))or(Pattern >= PatInTex) then
  begin
   Result:= -1;
   Exit;
  end;

 Result:= TexIndex;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImage.FindPatternMapping(Pattern, PatInRow,
 PatInCol: Integer; Tex: TAsphyreLockableTexture; var Mapping: TPoint4);
var
 Source: TPoint2px;
 Dest  : TPoint2px;
begin
 Source.x:= (Pattern mod PatInRow) * FPatternSize.x;
 Source.y:= ((Pattern div PatInRow) mod PatInCol) * FPatternSize.y;
 Dest    := Source + FVisibleSize;

 Mapping[0].x:= Source.x / Tex.Width;
 Mapping[0].y:= Source.y / Tex.Height;

 Mapping[1].x:= Dest.x / Tex.Width;
 Mapping[1].y:= Mapping[0].y;

 Mapping[2].x:= Mapping[1].x;
 Mapping[2].y:= Dest.y / Tex.Height;

 Mapping[3].x:= Mapping[0].x;
 Mapping[3].y:= Mapping[2].y;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImage.FindPatternMapping(Pattern, PatInRow,
 PatInCol: Integer; const ViewPos, ViewSize: TPoint2px;
 Tex: TAsphyreLockableTexture; var Mapping: TPoint4);
var
 Source : TPoint2px;
 Dest   : TPoint2px;
begin
 Source.x:= (Pattern mod PatInRow) * FPatternSize.x + ViewPos.x;
 Source.y:= ((Pattern div PatInRow) mod PatInCol) * FPatternSize.y + ViewPos.y;
 Dest.x  := Source.x + Min2(ViewSize.x, FVisibleSize.x);
 Dest.y  := Source.y + Min2(ViewSize.y, FVisibleSize.y);

 Mapping[0].x:= Source.x / Tex.Width;
 Mapping[0].y:= Source.y / Tex.Height;

 Mapping[1].x:= Dest.x / Tex.Width;
 Mapping[1].y:= Mapping[0].y;

 Mapping[2].x:= Mapping[1].x;
 Mapping[2].y:= Dest.y / Tex.Height;

 Mapping[3].x:= Mapping[0].x;
 Mapping[3].y:= Mapping[2].y;
end;

//---------------------------------------------------------------------------
function TAsphyreImage.RetrieveTex(Pattern: Integer;
 var Mapping: TPoint4): Integer;
var
 PatInRow, PatInCol: Integer;
begin
 Result:= FindPatternTex(Pattern, PatInRow, PatInCol);
 if (Result = -1) then Exit;

 FindPatternMapping(Pattern, PatInRow, PatInCol, Textures[Result], Mapping);
end;

//---------------------------------------------------------------------------
function TAsphyreImage.RetrieveTex(Pattern: Integer; const SrcRect: TRect;
 Mirror, Flip: Boolean; var Mapping: TPoint4): Integer;
var
 PatInRow, PatInCol: Integer;
 Aux: Single;
begin
 Result:= FindPatternTex(Pattern, PatInRow, PatInCol);
 if (Result = -1) then Exit;

 FindPatternMapping(Pattern, PatInRow, PatInCol, SrcRect.TopLeft,
  Point2px(SrcRect.Right - SrcRect.Left, SrcRect.Bottom - SrcRect.Top),
  Textures[Result], Mapping);

 if (Mirror) then
  begin
   Aux:= Mapping[0].x;

   Mapping[0].x:= Mapping[1].x;
   Mapping[3].x:= Mapping[1].x;
   Mapping[1].x:= Aux;
   Mapping[2].x:= Aux;
  end;
 if (Flip) then
  begin
   Aux:= Mapping[0].y;

   Mapping[0].y:= Mapping[2].y;
   Mapping[1].y:= Mapping[2].y;
   Mapping[2].y:= Aux;
   Mapping[3].y:= Aux;
  end;
end;

//---------------------------------------------------------------------------
constructor TAsphyreImages.Create();
begin
 inherited;

 Inc(AsphyreClassInstances);

 Archive:= TAsphyreArchive.Create();
 Archive.OpenMode:= aomReadOnly;

 EventDeviceDestroy.Subscribe(ClassName, OnDeviceDestroy);
 EventDeviceReset.Subscribe(ClassName, OnDeviceReset);
 EventDeviceLost.Subscribe(ClassName, OnDeviceLost);

 SearchDirty:= False;
end;

//---------------------------------------------------------------------------
destructor TAsphyreImages.Destroy();
begin
 Dec(AsphyreClassInstances);

 EventProviders.Unsubscribe(ClassName);

 RemoveAll();

 FreeAndNil(Archive);

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.GetItem(Index: Integer): TAsphyreImage;
begin
 if (Index >= 0)and(Index < Length(Images)) then
  Result:= Images[Index] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.GetItemCount(): Integer;
begin
 Result:= Length(Images);
end;

//---------------------------------------------------------------------------
function TAsphyreImages.FindEmptySlot(): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Images) - 1 do
  if (not Assigned(Images[i])) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.Insert(Image: TAsphyreImage): Integer;
var
 Index: Integer;
begin
 Index:= FindEmptySlot();
 if (Index = -1) then
  begin
   Index:= Length(Images);
   SetLength(Images, Index + 1);
  end;

 Images[Index]:= Image;
 Result:= Index;

 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.IndexOf(Element: TAsphyreImage): Integer;
var
 i: Integer;
begin
 Result:= -1;
 if (not Assigned(Element)) then Exit;

 for i:= 0 to Length(Images) - 1 do
  if (Images[i] = Element) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.Include(Element: TAsphyreImage): Integer;
begin
 Result:= IndexOf(Element);
 if (Result = -1) then Result:= Insert(Element);
end;

//---------------------------------------------------------------------------
procedure TAsphyreImages.Remove(Index: Integer);
begin
 if (Index < 0)or(Index >= Length(Images)) then Exit;

 if (Assigned(Images[Index])) then FreeAndNil(Images[Index]);

 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImages.RemoveAll();
var
 i: Integer;
begin
 for i:= Length(Images) - 1 downto 0 do
  if (Assigned(Images[i])) then FreeAndNil(Images[i]);

 SetLength(Images, 0);
 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImages.OnDeviceDestroy(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 RemoveAll();
end;

//---------------------------------------------------------------------------
procedure TAsphyreImages.OnDeviceReset(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
var
 i: Integer;
begin
 for i:= 0 to Length(Images) - 1 do
  if (Assigned(Images[i])) then Images[i].HandleDeviceReset();
end;

//---------------------------------------------------------------------------
procedure TAsphyreImages.OnDeviceLost(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
var
 i: Integer;
begin
 for i:= 0 to Length(Images) - 1 do
  if (Assigned(Images[i])) then Images[i].HandleDeviceLost();
end;

//---------------------------------------------------------------------------
function TAsphyreImages.AddFromArchiveEx(const Key: UniString;
 AArchive: TAsphyreArchive; const Name: UniString;
 PixelFormat: TAsphyrePixelFormat; MipMapping,
 DynamicImage: Boolean): Integer;
var
 ImageItem: TAsphyreImage;
begin
 ImageItem:= TAsphyreImage.Create();
 if (Name <> '') then ImageItem.Name:= Name
  else ImageItem.Name:= ExtractPipedName(Key);

 ImageItem.MipMapping  := MipMapping;
 ImageItem.DynamicImage:= DynamicImage;
 ImageItem.PixelFormat := PixelFormat;

 if (not ImageItem.LoadFromArchive(Key, AArchive)) then
  begin
   FreeAndNil(ImageItem);
   Result:= -1;
   Exit;
  end;

 Result:= Insert(ImageItem);
end;

//---------------------------------------------------------------------------
function TAsphyreImages.AddFromArchive(const Key: UniString;
 AArchive: TAsphyreArchive; const Name: UniString = '';
 MipMapping: Boolean = True): Integer;
begin
 Result:= AddFromArchiveEx(Key, AArchive, Name, apf_Unknown, MipMapping, False);
end;

//---------------------------------------------------------------------------
function TAsphyreImages.AddFromFileEx(const FileName: StdString;
 const Name: UniString; PixelFormat: TAsphyrePixelFormat; MipMapping,
 DynamicImage: Boolean): Integer;
var
 ImageItem: TAsphyreImage;
begin
 ImageItem:= TAsphyreImage.Create();
 if (Name <> '') then ImageItem.Name:= Name
  else ImageItem.Name:= ChangeFileExt(ExtractFileName(FileName), '');

 ImageItem.MipMapping  := MipMapping;
 ImageItem.DynamicImage:= DynamicImage;
 ImageItem.PixelFormat := PixelFormat;

 if (not ImageItem.LoadFromFile(FileName)) then
  begin
   FreeAndNil(ImageItem);
   Result:= -1;
   Exit;
  end;

 Result:= Insert(ImageItem);
end;

//---------------------------------------------------------------------------
function TAsphyreImages.AddFromFile(const FileName: StdString;
 const Name: UniString = ''; MipMapping: Boolean = True): Integer;
begin
 Result:= AddFromFileEx(FileName, Name, apf_Unknown, MipMapping, False);
end;

//---------------------------------------------------------------------------
procedure TAsphyreImages.InitSearchObjects();
var
 i, ObjCount, Index: Integer;
begin
 ObjCount:= 0;

 for i:= 0 to Length(Images) - 1 do
  if (Assigned(Images[i])) then Inc(ObjCount);

 if (Length(SearchObjects) <> ObjCount) then
  SetLength(SearchObjects, ObjCount);

 Index:= 0;

 for i:= 0 to Length(Images) - 1 do
  if (Assigned(Images[i])) then
   begin
    SearchObjects[Index]:= i;
    Inc(Index);
   end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImages.SwapSearchObjects(Index1, Index2: Integer);
var
 Aux: Integer;
begin
 Aux:= SearchObjects[Index1];

 SearchObjects[Index1]:= SearchObjects[Index2];
 SearchObjects[Index2]:= Aux;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.CompareSearchObjects(Obj1,
 Obj2: TAsphyreImage): Integer;
begin
 Result:= CompareText(Obj1.Name, Obj2.Name);
end;

//---------------------------------------------------------------------------
function TAsphyreImages.SplitSearchObjects(Start, Stop: Integer): Integer;
var
 Left, Right: Integer;
 Pivot: TAsphyreImage;
begin
 Left := Start + 1;
 Right:= Stop;
 Pivot:= Images[SearchObjects[Start]];

 while (Left <= Right) do
  begin
   while (Left <= Stop)and(CompareSearchObjects(Images[SearchObjects[Left]],
    Pivot) < 0) do Inc(Left);

   while (Right > Start)and(CompareSearchObjects(Images[SearchObjects[Right]],
    Pivot) >= 0) do Dec(Right);

   if (Left < Right) then SwapSearchObjects(Left, Right);
  end;

 SwapSearchObjects(Start, Right);

 Result:= Right;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImages.SortSearchObjects(Start, Stop: Integer);
var
 SplitPt: Integer;
begin
 if (Start < Stop) then
  begin
   SplitPt:= SplitSearchObjects(Start, Stop);

   SortSearchObjects(Start, SplitPt - 1);
   SortSearchObjects(SplitPt + 1, Stop);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImages.UpdateSearchObjects();
begin
 InitSearchObjects();
 SortSearchObjects(0, Length(SearchObjects) - 1);

 SearchDirty:= False;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.IndexOf(const Name: UniString): Integer;
var
 Lo, Hi, Mid, Res: Integer;
begin
 if (SearchDirty) then UpdateSearchObjects();

 Result:= -1;

 Lo:= 0;
 Hi:= Length(SearchObjects) - 1;

 while (Lo <= Hi) do
  begin
   Mid:= (Lo + Hi) div 2;
   Res:= UniCompareText(Images[SearchObjects[Mid]].Name, Name);

   if (Res = 0) then
    begin
     Result:= SearchObjects[Mid];
     Break;
    end;

   if (Res > 0) then Hi:= Mid - 1 else Lo:= Mid + 1;
 end;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.GetImage(const Name: UniString): TAsphyreImage;
var
 Index: Integer;
begin
 Index:= IndexOf(Name);

 if (Index <> -1) then Result:= Images[Index]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImages.MarkSearchDirty();
begin
 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.Resolve(const Name: UniString): Integer;
var
 Desc: PImageDesc;
 ArchiveName: StdString;
 ArchiveKey : UniString;
begin
 Result:= IndexOf(Name);
 if (Result <> -1) then Exit;

 Desc:= ImageGroups.Find(Name);
 if (not Assigned(Desc)) then
  begin
   if (Assigned(FOnItemFail)) then
     FOnItemFail(Self, Name, '');

   Exit;
  end;

 if (Assigned(FOnItemLoad)) then
  FOnItemLoad(Self, Name, Desc.MediaLink);

 if (IsArchiveLink(Desc.MediaLink)) then
  begin
   ArchiveName:= ExtractArchiveName(Desc.MediaLink);
   ArchiveKey := ExtractArchiveKey(Desc.MediaLink);

   if (not SameText(Archive.FileName, ArchiveName)) then
    if (not Archive.OpenFile(ArchiveName)) then
     begin
      if (Assigned(FOnItemFail)) then FOnItemFail(Self, Name, Desc.MediaLink);
      Exit;
     end;

   Auth.Authorize(Self, Archive);

   Result:= AddFromArchiveEx(ArchiveKey, Archive, Desc.Name, Desc.Format,
    Desc.MipMapping);

   Auth.Unauthorize();
  end else
  begin
   Result:= AddFromFileEx(Desc.MediaLink, Desc.Name, Desc.Format,
    Desc.MipMapping);
  end;

 if (Result <> -1) then
  begin
   if (Desc.PatternCount > 0) then
    Images[Result].PatternCount:= Desc.PatternCount;

   if (Desc.PatternSize.x > 0)and(Desc.PatternSize.y > 0) then
    Images[Result].PatternSize:= Desc.PatternSize;

   if (Desc.VisibleSize.x > 0)and(Desc.VisibleSize.y > 0) then
    Images[Result].VisibleSize:= Desc.VisibleSize;
  end else
   if (Assigned(FOnItemFail)) then FOnItemFail(Self, Name, Desc.MediaLink);
end;

//---------------------------------------------------------------------------
end.

