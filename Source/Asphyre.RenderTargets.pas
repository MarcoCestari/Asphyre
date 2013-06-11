unit Asphyre.RenderTargets;
//---------------------------------------------------------------------------
// Render Target storage container for Asphyre.
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
{< Container classes that facilitate storage, usage and handling of render
   target textures. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.SysUtils, Asphyre.Types, Asphyre.Textures;

//---------------------------------------------------------------------------
type
{ List of render target textures that can be used for rendering scenes into
  and also as source textures for drawing. }
 TAsphyreRenderTargets = class
 private
  Textures: array of TAsphyreRenderTargetTexture;

  function GetTexture(Index: Integer): TAsphyreRenderTargetTexture;
  function GetCount(): Integer;

  procedure OnDeviceDestroy(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);
  procedure OnDeviceReset(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);
  procedure OnDeviceLost(const Sender: TObject; const Param: Pointer;
   var Handled: Boolean);
 public
  { The number of render target textures in the list. }
  property Count: Integer read GetCount;

  { Provides access to individual render target textures in the list by using
    the index in range of [0..(Count - 1)]. If the specified index is outside
    of valid range, @nil is returned. }
  property Texture[Index: Integer]: TAsphyreRenderTargetTexture
   read GetTexture; default;

  { Inserts a new render target texture to the list without initializing it. }
  function Insert(): Integer;

  { Returns the index of existing render target texture in the list. If the
    given element is not found in the list, the returned value is -1. }
  function IndexOf(Element: TAsphyreRenderTargetTexture): Integer; overload;

  { Removes element at the given index from the list, shifting all further
    elements by one. Index must be specified in range of [0..(Count - 1)]. If
    the specified index is outside of valid range, this method does nothing. }
  procedure Remove(Index: Integer);

  { Adds one or more render target textures to the end of the list and
    initializes them. If the method succeeds, the index to first added element
    is returned; if the method fails, -1 is returned.
     @param(AddCount The number of render target textures to add.)
     @param(Width The width of added render target textures.)
     @param(Height The height of added render target textures.)
     @param(Format The pixel format to be used in added render target
      textures.)
     @param(DepthStencil Determines whether to create depth-stencil buffer in
      the added render target textures.)
     @param(Mipmapping Determines whether to use mipmapping in added render
      target textures.)
     @param(Multisamples Indicates the number of samples to use for
      antialiasing in added render target textures. This parameter is only
      supported on latest DX10+ providers.) }
  function Add(AddCount, Width, Height: Integer; Format: TAsphyrePixelFormat;
   DepthStencil: Boolean = False; MipMapping: Boolean = False;
   Multisamples: Integer = 0): Integer;

  { Removes all existing render target textures from the list. }
  procedure RemoveAll();

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Devices, Asphyre.Providers, Asphyre.Events.Types, Asphyre.Events;

//---------------------------------------------------------------------------
constructor TAsphyreRenderTargets.Create();
begin
 inherited;

 EventDeviceDestroy.Subscribe(ClassName, OnDeviceDestroy);
 EventDeviceReset.Subscribe(ClassName, OnDeviceReset);
 EventDeviceLost.Subscribe(ClassName, OnDeviceLost);
end;

//---------------------------------------------------------------------------
destructor TAsphyreRenderTargets.Destroy();
begin
 EventProviders.Unsubscribe(ClassName);

 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreRenderTargets.GetTexture(
 Index: Integer): TAsphyreRenderTargetTexture;
begin
 if (Index >= 0)and(Index < Length(Textures)) then
  Result:= Textures[Index] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TAsphyreRenderTargets.GetCount(): Integer;
begin
 Result:= Length(Textures);
end;

//---------------------------------------------------------------------------
function TAsphyreRenderTargets.Insert(): Integer;
var
 TexItem: TAsphyreRenderTargetTexture;
 Index  : Integer;
begin
 TexItem:= Factory.CreateRenderTargetTexture();
 if (not Assigned(TexItem)) then
  begin
   Result:= -1;
   Exit;
  end;

 Index:= Length(Textures);
 SetLength(Textures, Index + 1);

 Textures[Index]:= TexItem;
 Result:= Index;
end;

//---------------------------------------------------------------------------
function TAsphyreRenderTargets.IndexOf(
 Element: TAsphyreRenderTargetTexture): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Textures) - 1 do
  if (Textures[i] = Element) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreRenderTargets.RemoveAll();
var
 i: Integer;
begin
 for i:= 0 to Length(Textures) - 1 do
  if (Assigned(Textures[i])) then FreeAndNil(Textures[i]);

 SetLength(Textures, 0);
end;

//---------------------------------------------------------------------------
procedure TAsphyreRenderTargets.OnDeviceDestroy(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
begin
 RemoveAll();
end;

//---------------------------------------------------------------------------
procedure TAsphyreRenderTargets.OnDeviceReset(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
var
 i: Integer;
begin
 for i:= 0 to Length(Textures) - 1 do
  if (Assigned(Textures[i])) then Textures[i].HandleDeviceReset();
end;

//---------------------------------------------------------------------------
procedure TAsphyreRenderTargets.OnDeviceLost(const Sender: TObject;
 const Param: Pointer; var Handled: Boolean);
var
 i: Integer;
begin
 for i:= 0 to Length(Textures) - 1 do
  if (Assigned(Textures[i])) then Textures[i].HandleDeviceLost();
end;

//---------------------------------------------------------------------------
procedure TAsphyreRenderTargets.Remove(Index: Integer);
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
function TAsphyreRenderTargets.Add(AddCount, Width, Height: Integer;
 Format: TAsphyrePixelFormat; DepthStencil: Boolean = False;
 MipMapping: Boolean = False; Multisamples: Integer = 0): Integer;
var
 i, Index: Integer;
begin
 Result:= -1;

 for i:= 0 to AddCount - 1 do
  begin
   Index:= Insert();
   if (Index = -1) then Break;
   if (Result = -1) then Result:= Index;

   Textures[Index].Width := Width;
   Textures[Index].Height:= Height;
   Textures[Index].Format:= Format;
   Textures[Index].DepthStencil:= DepthStencil;
   Textures[Index].Mipmapping  := MipMapping;
   Textures[Index].Multisamples:= Multisamples;

   if (not Textures[Index].Initialize()) then
    begin
     if (Result = Index) then Result:= -1;
     Remove(Index);
     Break;
    end;
  end;
end;

//---------------------------------------------------------------------------
end.
