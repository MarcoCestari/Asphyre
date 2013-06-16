unit Asphyre.Surfaces;
//---------------------------------------------------------------------------
// 32-bit and custom pixel format image processing classes.
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

//----------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.Types, System.Classes, System.SysUtils,
{$else}
 Types, Classes, SysUtils,
{$endif}
 Asphyre.TypeDef,
 Asphyre.Types, Asphyre.Math, Asphyre.Archives;

//---------------------------------------------------------------------------
{$REGION 'System Surface Declaration'}

//----------------------------------------------------------------------------
type
 TSystemSurface = class
 private
  FName  : StdString;

  FBits  : Pointer;
  FPitch : Integer;
  FWidth : Integer;
  FHeight: Integer;

  SearchIndex: Integer;

  function GetPixel(x, y: Integer): Cardinal;
  procedure SetPixel(x, y: Integer; const Value: Cardinal);
  function GetScanline(Index: Integer): Pointer;
  procedure LoadFromStream(Stream: TStream);
 public
  property Name: StdString read FName write FName;

  property Bits : Pointer read FBits;
  property Pitch: Integer read FPitch;

  property Width : Integer read FWidth;
  property Height: Integer read FHeight;

  property Pixels[x, y: Integer]: Cardinal read GetPixel write SetPixel;
  property Scanline[Index: Integer]: Pointer read GetScanline;

  procedure SetSize(AWidth, AHeight: Integer);
  procedure CopyFrom(Source: TSystemSurface);

  procedure Clear(Color: Cardinal);
  procedure ResetAlpha();

  procedure Shrink2x(Source: TSystemSurface);

  procedure CopyRect(const DestPos: TPoint2px; Source: TSystemSurface;
   const SrcRect: TRect);

  procedure StretchBi(Source: TSystemSurface; x, y, AWidth, AHeight, SrcX, SrcY,
   SrcWidth, SrcHeight: Integer);

  function BiPixel(x, y, xDelta, yDelta: Integer): Cardinal;

  function HasAlphaChannel(): Boolean;

  function LoadFromArchive(const Key: UniString;
   Archive: TAsphyreArchive): Boolean;

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'System Surfaces Declaration'}

//----------------------------------------------------------------------------
 TSystemSurfaces = class
 private
  Surfaces: array of TSystemSurface;

  SearchList : array of TSystemSurface;
  SearchDirty: Boolean;

  function GetCount(): Integer;
  procedure SetCount(const Value: Integer);
  function GetItem(Index: Integer): TSystemSurface;
  function FindEmptySlot(): Integer;

  procedure InitSearchList();
  procedure SearchListSwap(Index1, Index2: Integer);
  function SearchListCompare(Item1, Item2: TSystemSurface): Integer;
  function SearchListSplit(Start, Stop: Integer): Integer;
  procedure SearchListSort(Start, Stop: Integer);
  procedure UpdateSearchList();
 public
  property Count: Integer read GetCount write SetCount;
  property Items[Index: Integer]: TSystemSurface read GetItem; default;

  function Add(): Integer; overload;
  function Add(Width, Height: Integer): Integer; overload;
  function Insert(Surface: TSystemSurface): Integer;

  function AddFromArchive(const Key: UniString;
   Archive: TAsphyreArchive): Integer;
  function IndexOf(const ImageName: StdString): Integer;
  procedure Remove(Index: Integer);

  procedure RemoveAll();

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Pixel Surface Declaration'}

//---------------------------------------------------------------------------
 TPixelSurfaces = class;

//---------------------------------------------------------------------------
 TPixelSurface = class
 private
  FMipMaps: TPixelSurfaces;

  FName  : StdString;
  FBits  : Pointer;
  FPitch : Integer;
  FWidth : Integer;
  FHeight: Integer;
  FPixelFormat: TAsphyrePixelFormat;
  FBytesPerPixel: Integer;

  function GetScanline(Index: Integer): Pointer;
  function GetPixel(x, y: Integer): Cardinal;
  procedure SetPixel(x, y: Integer; const Value: Cardinal);
 public
  property Name: StdString read FName;

  property Bits : Pointer read FBits;
  property Pitch: Integer read FPitch;

  property Width : Integer read FWidth;
  property Height: Integer read FHeight;

  property PixelFormat: TAsphyrePixelFormat read FPixelFormat;

  property Scanline[Index: Integer]: Pointer read GetScanline;
  property Pixels[x, y: Integer]: Cardinal read GetPixel write SetPixel;

  property BytesPerPixel: Integer read FBytesPerPixel;

  property MipMaps: TPixelSurfaces read FMipMaps;

  function GetPixelPtr(x, y: Integer): Pointer;

  procedure SetSize(AWidth, AHeight: Integer;
   APixelFormat: TAsphyrePixelFormat = apf_Unknown;
   ABytesPerPixel: Integer = 0);

  function ConvertPixelFormat(NewFormat: TAsphyrePixelFormat): Boolean;

  procedure CopyFrom(Source: TPixelSurface);

  procedure Clear(Color: Cardinal);
  procedure ResetAlpha();

  function HasAlphaChannel(): Boolean;
  function Shrink2xFrom(Source: TPixelSurface): Boolean;

  procedure GenerateMipMaps();
  procedure RemoveMipMaps();

  constructor Create(const AName: StdString = '');
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Pixel Surfaces Declaration'}

//---------------------------------------------------------------------------
 TPixelSurfaces = class
 private
  Data: array of TPixelSurface;

  function GetCount(): Integer;
  function GetItem(Index: Integer): TPixelSurface;
 public
  property Count: Integer read GetCount;
  property Items[Index: Integer]: TPixelSurface read GetItem; default;

  function Add(const AName: StdString = ''): Integer;
  procedure Remove(Index: Integer);
  procedure RemoveAll();

  function IndexOf(const AName: StdString): Integer;

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
{$ENDREGION}

//----------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Formats, Asphyre.Streams;

//---------------------------------------------------------------------------
{$REGION 'System Surface'}

//----------------------------------------------------------------------------
constructor TSystemSurface.Create();
begin
 inherited;

 SearchIndex:= -1;

 FBits:= nil;
 FPitch := 0;
 FWidth := 0;
 FHeight:= 0;
end;

//---------------------------------------------------------------------------
destructor TSystemSurface.Destroy();
begin
 if (Assigned(FBits)) then FreeNullMem(FBits);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TSystemSurface.SetSize(AWidth, AHeight: Integer);
begin
 FWidth := AWidth;
 FHeight:= AHeight;
 FPitch := FWidth * 4;

 ReallocMem(FBits, AWidth * AHeight * 4);
 Clear(0);
end;

//---------------------------------------------------------------------------
function TSystemSurface.GetPixel(x, y: Integer): Cardinal;
begin
 if (x < 0)or(y < 0)or(x >= FWidth)or(y >= FHeight) then
  begin
   Result:= 0;
   Exit;
  end;

 Result:= PLongWord(PtrInt(FBits) + (PtrInt(FPitch) * y) + (PtrInt(x) * 4))^;
end;

//---------------------------------------------------------------------------
procedure TSystemSurface.SetPixel(x, y: Integer; const Value: Cardinal);
begin
 if (x < 0)or(y < 0)or(x >= FWidth)or(y >= FHeight) then Exit;
 PLongWord(PtrInt(FBits) + (PtrInt(FPitch) * y) + (PtrInt(x) * 4))^:= Value;
end;

//---------------------------------------------------------------------------
function TSystemSurface.GetScanline(Index: Integer): Pointer;
begin
 if (Index >= 0)and(Index < FHeight) then
  Result:= Pointer(PtrInt(FBits) + FPitch * Index) else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TSystemSurface.CopyFrom(Source: TSystemSurface);
begin
 if (FWidth <> Source.Width)or(FHeight <> Source.Height) then
  SetSize(Source.Width, Source.Height);

 Move(Source.Bits^, FBits^, Width * Height * 4);
end;

//---------------------------------------------------------------------------
procedure TSystemSurface.Clear(Color: Cardinal);
var
 Pixel: PLongWord;
 i: Integer;
begin
 Pixel:= FBits;

 for i:= 0 to (Width * Height) - 1 do
  begin
   Pixel^:= Color;
   Inc(Pixel);
  end;
end;

//---------------------------------------------------------------------------
procedure TSystemSurface.ResetAlpha();
var
 SrcPx: PLongWord;
 i: Integer;
begin
 SrcPx:= FBits;
 for i:= 0 to (FWidth * FHeight) - 1 do
  begin
   SrcPx^:= SrcPx^ or $FF000000;
   Inc(SrcPx);
  end;
end;

//---------------------------------------------------------------------------
procedure TSystemSurface.Shrink2x(Source: TSystemSurface);
var
 j, i: Integer;
 DestPx: PLongWord;
 SrcPx1a, SrcPx1b, SrcPx2a, SrcPx2b: PLongWord;
begin
 if (FWidth <> Source.Width div 2)or(FHeight <> Source.Height div 2) then
  SetSize(Source.Width div 2, Source.Height div 2);

 for j:= 0 to FHeight - 1 do
  begin
   DestPx:= GetScanline(j);

   SrcPx1a:= Source.Scanline[j * 2];
   SrcPx1b:= SrcPx1a;
   Inc(SrcPx1b);

   SrcPx2a:= Source.Scanline[(j * 2) + 1];
   SrcPx2b:= SrcPx2a;
   Inc(SrcPx2b);

   for i:= 0 to FWidth - 1 do
    begin
     DestPx^:= AvgFourPixels(SrcPx1a^, SrcPx1b^, SrcPx2a^, SrcPx2b^);

     Inc(SrcPx1a, 2);
     Inc(SrcPx1b, 2);
     Inc(SrcPx2a, 2);
     Inc(SrcPx2b, 2);
     Inc(DestPx);
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TSystemSurface.StretchBi(Source: TSystemSurface; x, y, AWidth,
 AHeight, SrcX, SrcY, SrcWidth, SrcHeight: Integer);
var
 i, j: Integer;
 FixedPt: TPoint2px;
 DeltaPt: TPoint2px;
 DestPx: PLongWord;
 Color1, Color2: Cardinal;
begin
 FixedPt.y:= SrcY shl 16;
 DeltaPt.x:= ((SrcWidth - 1) shl 16) div AWidth;
 DeltaPt.y:= ((SrcHeight - 1) shl 16) div AHeight;

 for j:= 0 to AHeight - 1 do
  begin
   FixedPt.x:= SrcX shl 16;

   DestPx:= Pointer(PtrInt(FBits) + (PtrInt(FPitch) * (PtrInt(j) + y)) +
    (PtrInt(x) * 4));

   for i:= 0 to AWidth - 1 do
    begin
     Color1:= BlendPixels(
      Source.Pixels[FixedPt.x shr 16, FixedPt.y shr 16],
      Source.Pixels[(FixedPt.x shr 16) + 1, FixedPt.y shr 16],
      (FixedPt.x and $FFFF) shr 8);

     Color2:= BlendPixels(
      Source.Pixels[FixedPt.x shr 16, (FixedPt.y shr 16) + 1],
      Source.Pixels[(FixedPt.x shr 16) + 1, (FixedPt.y shr 16) + 1],
      (FixedPt.x and $FFFF) shr 8);

     DestPx^:= BlendPixels(Color1, Color2, (FixedPt.Y and $FFFF) shr 8);

     Inc(FixedPt.x, DeltaPt.x);
     Inc(DestPx);
    end;

   Inc(FixedPt.y, DeltaPt.y);
  end;
end;

//---------------------------------------------------------------------------
function TSystemSurface.BiPixel(x, y, xDelta, yDelta: Integer): Cardinal;
var
 nx, ny: Integer;
begin
 nx:= Min2(x + 1, FWidth);
 ny:= Min2(y + 1, FHeight);

 Result:=
  BlendPixels(
   BlendPixels(GetPixel(x, y), GetPixel(nx, y), xDelta),
   BlendPixels(GetPixel(x, ny), GetPixel(nx, ny), xDelta),
   yDelta);
end;

//---------------------------------------------------------------------------
procedure TSystemSurface.CopyRect(const DestPos: TPoint2px;
 Source: TSystemSurface; const SrcRect: TRect);
var
 i: Integer;
 SrcPos, SrcSize: TPoint2px;
 SrcPx, DestPx: PLongWord;
begin
 SrcPos.x:= SrcRect.Left;
 SrcPos.y:= SrcRect.Top;
 SrcSize.x:= SrcRect.Right - SrcRect.Left;
 SrcSize.y:= SrcRect.Bottom - SrcRect.Top;

 if (SrcPos.x > Source.Width)or(SrcPos.y > Source.Height) then Exit;
 if (SrcPos.x < 0)or(SrcPos.y < 0)or(SrcPos.x + SrcSize.x > Source.Width)or
  (SrcPos.y + SrcSize.y > Source.Height) then Exit;
 if (DestPos.x < 0)or(DestPos.y < 0)or(DestPos.x + SrcSize.x > Width)or
  (DestPos.y + SrcSize.y > Height) then Exit;

 for i:= 0 to SrcSize.y - 1 do
  begin
   SrcPx := Pointer(PtrInt(Source.Scanline[SrcPos.y + i]) + SrcPos.x * 4);
   DestPx:= Pointer(PtrInt(Scanline[DestPos.y + i]) + DestPos.x * 4);

   Move(SrcPx^, DestPx^, SrcSize.x * 4);
  end;
end;

//---------------------------------------------------------------------------
function TSystemSurface.HasAlphaChannel(): Boolean;
var
 i, j : Integer;
 SrcPx: PLongWord;
begin
 for j:= 0 to FHeight - 1 do
  begin
   SrcPx:= ScanLine[j];

   for i:= 0 to FWidth - 1 do
    begin
     if (SrcPx^ and $FF000000 > 0) then
      begin
       Result:= True;
       Exit;
      end;

     Inc(SrcPx);
    end;
  end;

 Result:= False;
end;

//---------------------------------------------------------------------------
procedure TSystemSurface.LoadFromStream(Stream: TStream);
var
 TextureSize : TPoint2px;
 TextureCount: Integer;
 PixelFormat : TAsphyrePixelFormat;
 AuxMem : Pointer;
 AuxSize: Integer;
 Index  : Integer;
 DestPtr: Pointer;
begin
 // (1) Read the information about the image.
 // --> Format
 PixelFormat:= TAsphyrePixelFormat(StreamGetByte(Stream));
 // --> Pattern Size
 StreamGetLongWord(Stream);
 // --> Pattern Count
 StreamGetLongint(Stream);
 // --> Visible Size
 StreamGetLongWord(Stream);
 // --> Texture Size
 TextureSize.x:= StreamGetWord(Stream);
 TextureSize.y:= StreamGetWord(Stream);
 // --> Texture Count
 TextureCount:= StreamGetWord(Stream);

 // (2) Allocate temporary memory, if necessary.
 AuxMem := nil;
 AuxSize:= 0;

 if (PixelFormat <> apf_A8R8G8B8)and(PixelFormat <> apf_X8R8G8B8) then
  begin
   AuxSize:= (TextureSize.X * AsphyrePixelFormatBits[PixelFormat]) div 8;
   AuxMem := AllocMem(AuxSize);
  end;

 // (3) Resize surface's memory.
 SetSize(TextureSize.x, TextureSize.y * TextureCount);

 // (4) Read pixel information.
 for Index:= 0 to FHeight - 1 do
  begin
   DestPtr:= Scanline[Index];
   if (Assigned(AuxMem)) then
    begin
     Stream.Read(AuxMem^, AuxSize);
     PixelXto32Array(AuxMem, DestPtr, PixelFormat, FWidth);
    end else
    begin // native format
     Stream.Read(DestPtr^, FPitch);
    end;
  end;

 // (5) Release memory.
 if (Assigned(AuxMem)) then FreeNullMem(AuxMem);

 // (6) Reset alpha, if necessary.
 if (PixelFormat = apf_X8R8G8B8) then ResetAlpha();
end;

//---------------------------------------------------------------------------
function TSystemSurface.LoadFromArchive(const Key: UniString;
 Archive: TAsphyreArchive): Boolean;
var
 Stream: TMemoryStream;
begin
 Stream:= TMemoryStream.Create();
 Result:= Archive.ReadStream(Key, Stream);

 if (Result) then
  begin
   try
    Stream.Seek(0, soFromBeginning);
    LoadFromStream(Stream);
   except
    Result:= False;
   end;
  end;

 FreeAndNil(Stream);
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'System Surfaces'}

//---------------------------------------------------------------------------
constructor TSystemSurfaces.Create();
begin
 inherited;

 SetLength(Surfaces, 0);
 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
destructor TSystemSurfaces.Destroy();
begin
 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
function TSystemSurfaces.GetCount(): Integer;
begin
 Result:= Length(Surfaces);
end;

//---------------------------------------------------------------------------
procedure TSystemSurfaces.SetCount(const Value: Integer);
begin
 if (Value <= 0) then
  begin
   RemoveAll();
   Exit;
  end;

 if (Length(Surfaces) > Value) then RemoveAll();
 while (Length(Surfaces) < Value) do Add();
end;

//---------------------------------------------------------------------------
function TSystemSurfaces.GetItem(Index: Integer): TSystemSurface;
begin
 if (Index >= 0)and(Index < Length(Surfaces)) then
  Result:= Surfaces[Index] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TSystemSurfaces.FindEmptySlot(): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Surfaces) - 1 do
  if (not Assigned(Surfaces[i])) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TSystemSurfaces.Insert(Surface: TSystemSurface): Integer;
begin
 Result:= FindEmptySlot();
 if (Result = -1) then
  begin
   Result:= Length(Surfaces);
   SetLength(Surfaces, Result + 1);
  end;

 Surfaces[Result]:= Surface;
 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
function TSystemSurfaces.Add(): Integer;
var
 Index: Integer;
begin
 Index:= FindEmptySlot();
 if (Index = -1) then
  begin
   Index:= Length(Surfaces);
   SetLength(Surfaces, Index + 1);
  end;

 Surfaces[Index]:= TSystemSurface.Create();

 Result:= Index;
 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
function TSystemSurfaces.Add(Width, Height: Integer): Integer;
var
 Index: Integer;
begin
 Index:= FindEmptySlot();
 if (Index = -1) then
  begin
   Index:= Length(Surfaces);
   SetLength(Surfaces, Index + 1);
  end;

 Surfaces[Index]:= TSystemSurface.Create();
 Surfaces[Index].SetSize(Width, Height);

 Result:= Index;
 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TSystemSurfaces.Remove(Index: Integer);
begin
 if (Index < 0)or(Index >= Length(Surfaces)) then Exit;

 if (Assigned(Surfaces[Index])) then FreeAndNil(Surfaces[Index]);

 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TSystemSurfaces.RemoveAll();
var
 i: Integer;
begin
 for i:= Length(Surfaces) - 1 downto 0 do
  if (Assigned(Surfaces[i])) then 
   FreeAndNil(Surfaces[i]);

 SetLength(Surfaces, 0);
 SearchDirty:= True;
end;

//---------------------------------------------------------------------------
procedure TSystemSurfaces.InitSearchList();
var
 i, ObjCount, Index: Integer;
begin
 ObjCount:= 0;

 for i:= 0 to Length(Surfaces) - 1 do
  if (Assigned(Surfaces[i])) then Inc(ObjCount);

 if (Length(SearchList) <> ObjCount) then
  SetLength(SearchList, ObjCount);

 Index:= 0;

 for i:= 0 to Length(Surfaces) - 1 do
  if (Assigned(Surfaces[i])) then
   begin
    SearchList[Index]:= Surfaces[i];
    SearchList[Index].SearchIndex:= i;

    Inc(Index);
   end;
end;

//---------------------------------------------------------------------------
procedure TSystemSurfaces.SearchListSwap(Index1, Index2: Integer);
var
 Aux: TSystemSurface;
begin
 Aux:= SearchList[Index1];

 SearchList[Index1]:= SearchList[Index2];
 SearchList[Index2]:= Aux;
end;

//---------------------------------------------------------------------------
function TSystemSurfaces.SearchListCompare(Item1,
 Item2: TSystemSurface): Integer;
begin
 Result:= CompareText(Item1.Name, Item2.Name);
end;

//---------------------------------------------------------------------------
function TSystemSurfaces.SearchListSplit(Start, Stop: Integer): Integer;
var
 Left, Right: Integer;
 Pivot: TSystemSurface;
begin
 Left := Start + 1;
 Right:= Stop;
 Pivot:= SearchList[Start];

 while (Left <= Right) do
  begin
   while (Left <= Stop)and(SearchListCompare(SearchList[Left], Pivot) < 0) do
    Inc(Left);

   while (Right > Start)and(SearchListCompare(SearchList[Right], Pivot) >= 0) do
    Dec(Right);

   if (Left < Right) then SearchListSwap(Left, Right);
  end;

 SearchListSwap(Start, Right);

 Result:= Right;
end;

//---------------------------------------------------------------------------
procedure TSystemSurfaces.SearchListSort(Start, Stop: Integer);
var
 SplitPt: Integer;
begin
 if (Start < Stop) then
  begin
   SplitPt:= SearchListSplit(Start, Stop);

   SearchListSort(Start, SplitPt - 1);
   SearchListSort(SplitPt + 1, Stop);
  end;
end;

//---------------------------------------------------------------------------
procedure TSystemSurfaces.UpdateSearchList();
begin
 InitSearchList();
 if (Length(SearchList) > 1) then SearchListSort(0, Length(SearchList) - 1);

 SearchDirty:= False;
end;

//---------------------------------------------------------------------------
function TSystemSurfaces.IndexOf(const ImageName: StdString): Integer;
var
 Lo, Hi, Mid: Integer;
begin
 if (SearchDirty) then UpdateSearchList();

 Result:= -1;

 Lo:= 0;
 Hi:= Length(SearchList) - 1;

 while (Lo <= Hi) do
  begin
   Mid:= (Lo + Hi) div 2;

   if (SameText(SearchList[Mid].Name, ImageName)) then
    begin
     Result:= SearchList[Mid].SearchIndex;
     Break;
    end;

   if (CompareText(SearchList[Mid].Name, ImageName) > 0) then
    Hi:= Mid - 1
     else Lo:= Mid + 1;
 end;
end;

//---------------------------------------------------------------------------
function TSystemSurfaces.AddFromArchive(const Key: UniString;
 Archive: TAsphyreArchive): Integer;
var
 Surface: TSystemSurface;
begin
 Surface:= TSystemSurface.Create();
 Surface.Name:= Key;

 if (not Surface.LoadFromArchive(Key, Archive)) then
  begin
   FreeAndNil(Surface);
   Result:= -1;
   Exit;
  end;

 Result:= Insert(Surface);
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Pixel Surface'}

//---------------------------------------------------------------------------
constructor TPixelSurface.Create(const AName: StdString = '');
begin
 inherited Create();

 FMipMaps:= TPixelSurfaces.Create();
 FName:= AName;

 FBits  := nil;
 FPitch := 0;
 FWidth := 0;
 FHeight:= 0;

 FPixelFormat:= apf_Unknown;
 FBytesPerPixel:= 0;
end;

//---------------------------------------------------------------------------
destructor TPixelSurface.Destroy();
begin
 if (Assigned(FBits)) then FreeNullMem(FBits);
 FreeAndNil(FMipMaps);

 inherited;
end;

//---------------------------------------------------------------------------
function TPixelSurface.GetScanline(Index: Integer): Pointer;
begin
 if (Index >= 0)and(Index < FHeight) then
  Result:= Pointer(PtrInt(FBits) + (PtrInt(FPitch) * Index)) else Result:= nil;
end;

//---------------------------------------------------------------------------
function TPixelSurface.GetPixel(x, y: Integer): Cardinal;
var
 SrcPtr: Pointer;
begin
 if (x < 0)or(y < 0)or(x >= FWidth)or(y >= FHeight)or
  (FPixelFormat = apf_Unknown) then
  begin
   Result:= 0;
   Exit;
  end;

 SrcPtr:= Pointer(PtrInt(FBits) + (PtrInt(FPitch) * y) + ((PtrInt(x) *
  AsphyrePixelFormatBits[FPixelFormat]) div 8));

 Result:= PixelXto32(SrcPtr, FPixelFormat);
end;

//---------------------------------------------------------------------------
procedure TPixelSurface.SetPixel(x, y: Integer; const Value: Cardinal);
var
 DestPtr: Pointer;
begin
 if (x < 0)or(y < 0)or(x >= FWidth)or(y >= FHeight)or
  (FPixelFormat = apf_Unknown) then Exit;

 DestPtr:= Pointer(PtrInt(FBits) + (PtrInt(FPitch) * y) + ((PtrInt(x) *
  AsphyrePixelFormatBits[FPixelFormat]) div 8));

 Pixel32toX(Value, DestPtr, FPixelFormat);
end;

//---------------------------------------------------------------------------
function TPixelSurface.GetPixelPtr(x, y: Integer): Pointer;
begin
 if (x < 0)or(y < 0)or(x >= FWidth)or(y >= FHeight) then
  begin
   Result:= nil;
   Exit;
  end;

 if (FPixelFormat <> apf_Unknown) then
  begin
   Result:= Pointer(PtrInt(FBits) + (PtrInt(FPitch) * y) + ((PtrInt(x) *
    AsphyrePixelFormatBits[FPixelFormat]) div 8));
  end else
  begin
   Result:= Pointer(PtrInt(FBits) + (PtrInt(FPitch) * y) + (PtrInt(x) *
    FBytesPerPixel));
  end;
end;

//---------------------------------------------------------------------------
procedure TPixelSurface.SetSize(AWidth, AHeight: Integer;
 APixelFormat: TAsphyrePixelFormat = apf_Unknown;
 ABytesPerPixel: Integer = 0);
var
 NewSize: Integer;
begin
 FPixelFormat  := APixelFormat;
 FBytesPerPixel:= Max2(ABytesPerPixel, 0);

 if (FPixelFormat = apf_Unknown)and(FBytesPerPixel < 1) then
  FPixelFormat:= apf_A8R8G8B8;

 FWidth := Max2(AWidth, 0);
 FHeight:= Max2(AHeight, 0);

 if (FPixelFormat <> apf_Unknown) then
  begin
   FPitch := (FWidth * AsphyrePixelFormatBits[FPixelFormat]) div 8;
   NewSize:= (FWidth * FHeight * AsphyrePixelFormatBits[FPixelFormat]) div 8;

   FBytesPerPixel:= AsphyrePixelFormatBits[FPixelFormat] div 8;
  end else
  begin
   FPitch := FWidth * FBytesPerPixel;
   NewSize:= FWidth * FHeight * FBytesPerPixel;
  end;

 ReallocMem(FBits, NewSize);
 FillChar(FBits^, NewSize, 0);
end;

//---------------------------------------------------------------------------
function TPixelSurface.ConvertPixelFormat(
 NewFormat: TAsphyrePixelFormat): Boolean;
var
 NewBits, TempBits: Pointer;
 NewSize: Integer;
begin
 Result:= (FPixelFormat <> apf_Unknown)and(NewFormat <> apf_Unknown);
 if (not Result) then Exit;

 FBytesPerPixel:= AsphyrePixelFormatBits[NewFormat] div 8;

 if (FWidth < 1)or(FHeight < 1)or(not Assigned(FBits)) then
  begin
   FPixelFormat:= NewFormat;
   Exit;
  end;

 NewSize:= (FWidth * FHeight * AsphyrePixelFormatBits[NewFormat]) div 8;
 NewBits:= AllocMem(NewSize);

 if (FPixelFormat = apf_A8R8G8B8) then
  begin // Source is 32-bit ARGB.
   Pixel32toXArray(FBits, NewBits, NewFormat, FWidth * FHeight);
  end else
 if (NewFormat = apf_A8R8G8B8) then
  begin // Destination is 32-bit ARGB.
   PixelXto32Array(FBits, NewBits, FPixelFormat, FWidth * FHeight);
  end else
  begin // Source and Destination are NOT 32-bit ARGB.
   TempBits:= AllocMem(FWidth * FHeight * 4);

   PixelXto32Array(FBits, TempBits, FPixelFormat, FWidth * FHeight);
   Pixel32toXArray(TempBits, NewBits, NewFormat, FWidth * FHeight);

   FreeNullMem(TempBits);
  end;

 FreeNullMem(FBits);

 FPixelFormat:= NewFormat;

 FBits := NewBits;
 FPitch:= (FWidth * AsphyrePixelFormatBits[FPixelFormat]) div 8;
end;

//---------------------------------------------------------------------------
procedure TPixelSurface.CopyFrom(Source: TPixelSurface);
begin
 if (FPixelFormat <> Source.PixelFormat)or(FWidth <> Source.Width)or
  (FHeight <> Source.Height)or(FBytesPerPixel <> Source.BytesPerPixel) then
  SetSize(Source.Width, Source.Height, Source.PixelFormat,
   Source.BytesPerPixel);

 Move(Source.Bits^, FBits^, FHeight * FPitch);
end;

//---------------------------------------------------------------------------
procedure TPixelSurface.Clear(Color: Cardinal);
var
 i: Integer;
 DestPtr: Pointer;
begin
 if (FWidth < 1)or(FHeight < 1)or(not Assigned(FBits)) then Exit;

 if (FPixelFormat = apf_Unknown) then
  begin
   FillChar(FBits^, FHeight * FPitch, Color and $FF);
   Exit;
  end;

 for i:= 0 to (FWidth * FHeight) - 1 do
  begin
   DestPtr:= Pointer(PtrInt(FBits) + ((PtrInt(i) *
    AsphyrePixelFormatBits[FPixelFormat]) div 8));

   Pixel32toX(Color, DestPtr, FPixelFormat);
  end;
end;

//---------------------------------------------------------------------------
procedure TPixelSurface.ResetAlpha();
var
 i, j  : Integer;
 PixPtr: Pointer;
 Value : Cardinal;
begin
 if (FWidth < 1)or(FHeight < 1)or(not Assigned(FBits))or
  (FPixelFormat = apf_Unknown) then Exit;

 for j:= 0 to FHeight - 1 do
  for i:= 0 to FWidth - 1 do
   begin
    PixPtr:= Pointer(PtrInt(FBits) + FPitch * j + ((i *
     AsphyrePixelFormatBits[FPixelFormat]) div 8));

    Value:= PixelXto32(PixPtr, FPixelFormat);
    Pixel32toX(Value or $FF000000, PixPtr, FPixelFormat);
   end;
end;

//---------------------------------------------------------------------------
function TPixelSurface.HasAlphaChannel(): Boolean;
var
 i, j  : Integer;
 SrcPtr: Pointer;
 Value : Cardinal;
begin
 if (FWidth < 1)or(FHeight < 1)or(not Assigned(FBits))or
  (FPixelFormat = apf_Unknown) then
  begin
   Result:= False;
   Exit;
  end;

 for j:= 0 to FHeight - 1 do
  for i:= 0 to FWidth - 1 do
   begin
    SrcPtr:= Pointer(PtrInt(FBits) + FPitch * j + ((i *
     AsphyrePixelFormatBits[FPixelFormat]) div 8));

    Value:= PixelXto32(SrcPtr, FPixelFormat);
    if (Value and $FF000000 > 0) then
     begin
      Result:= True;
      Exit;
     end;
   end;

 Result:= False;
end;

//---------------------------------------------------------------------------
function TPixelSurface.Shrink2xFrom(Source: TPixelSurface): Boolean;
var
 i, j: Integer;
begin
 Result:= (Source.PixelFormat <> apf_Unknown)and(Source.Width > 1)and
  (Source.Height > 1);
 if (not Result) then Exit;

 if (FWidth <> Source.Width div 2)or(FHeight <> Source.Height div 2)or
  (FPixelFormat <> Source.PixelFormat) then
  SetSize(Source.Width div 2, Source.Height div 2, Source.PixelFormat);

 for j:= 0 to FHeight - 1 do
  for i:= 0 to FWidth - 1 do
   begin
    SetPixel(i, j, AvgFourPixels(Source.GetPixel(i * 2, j * 2),
     Source.GetPixel((i * 2) + 1, j * 2), Source.GetPixel(i * 2, (j * 2) + 1),
     Source.GetPixel((i * 2) + 1, (j * 2) + 1)));
   end;
end;

//---------------------------------------------------------------------------
procedure TPixelSurface.GenerateMipMaps();
var
 Source, Dest: TPixelSurface;
 NewIndex: Integer;
begin
 FMipMaps.RemoveAll();

 Source:= Self;
 while (Source.Width > 1)and(Source.Height > 1)and
  (Source.PixelFormat <> apf_Unknown) do
  begin
   NewIndex:= FMipMaps.Add();

   Dest:= FMipMaps[NewIndex];
   if (not Assigned(Dest)) then Break;

   Dest.Shrink2xFrom(Source);
   Source:= Dest;
  end;
end;

//---------------------------------------------------------------------------
procedure TPixelSurface.RemoveMipMaps();
begin
 FMipMaps.RemoveAll();
end;

//---------------------------------------------------------------------------
{$ENDREGION}
{$REGION 'Pixel Surfaces'}

//---------------------------------------------------------------------------
constructor TPixelSurfaces.Create();
begin
 inherited;

end;

//---------------------------------------------------------------------------
destructor TPixelSurfaces.Destroy();
begin
 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
function TPixelSurfaces.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TPixelSurfaces.GetItem(Index: Integer): TPixelSurface;
begin
 if (Index >= 0)and(Index < Length(Data)) then
  Result:= Data[Index] 
   else Result:= nil;
end;

//---------------------------------------------------------------------------
function TPixelSurfaces.Add(const AName: StdString = ''): Integer;
begin
 Result:= Length(Data);
 SetLength(Data, Result + 1);

 Data[Result]:= TPixelSurface.Create(AName);
end;

//---------------------------------------------------------------------------
procedure TPixelSurfaces.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Data)) then Exit;

 FreeAndNil(Data[Index]);

 for i:= Index to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);
end;

//---------------------------------------------------------------------------
procedure TPixelSurfaces.RemoveAll();
var
 i: Integer;
begin
 for i:= Length(Data) - 1 downto 0 do
  FreeAndNil(Data[i]);

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
function TPixelSurfaces.IndexOf(const AName: StdString): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Data) - 1 do
  if (SameText(AName, Data[i].Name)) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
{$ENDREGION}

//---------------------------------------------------------------------------
end.
