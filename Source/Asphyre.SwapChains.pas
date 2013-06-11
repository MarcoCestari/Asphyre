unit Asphyre.SwapChains;
//---------------------------------------------------------------------------
// Description structures for Asphyre generic swap chains.
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
{< Specification and implementation of rendering swap chains used in Asphyre
   providers. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 Asphyre.Math, Asphyre.Types;

//---------------------------------------------------------------------------
type
{ The type of depth and stencil buffers to be created in the swap chain. }
 TDepthStencilType = (
  { No depth-stencil buffer is needed. @br @br }
  dstNone,

  { Only depth buffer is required, stencil buffer is not needed. @br @br }
  dstDepthOnly,

  { Both depth and stencil buffers are required. }
  dstDepthStencil);

//---------------------------------------------------------------------------
{ Pointer to @link(TSwapChainDesc) structure typically used to pass it by
  reference. }
 PSwapChainDesc = ^TSwapChainDesc;

{ General description of rendering swap chain. }
 TSwapChainDesc = record
  { The width of rendering surface. }
  Width : Integer;

  { The height of rendering surface. }
  Height: Integer;

  { This parameter determines whether to wait for vertical retrace to provide
    flicker-free animations. }
  VSync: Boolean;

  { The desired pixel format to be used in the rendering target. This is a
    suggestion and different format may be choosen by the provider depending
    on hardware support. If this parameter is set to @code(apf_Unknown)
    (by default), the best possible pixel format will be used. }
  Format: TAsphyrePixelFormat;

  { The handle to the application's main window or a control where the
    rendering should be made (can be another window or even a panel). }
  WindowHandle: THandle;

  { Number of samples to use for antialiasing. This is a suggestion and
    different value may actually be used by the provider depending on
    hardware support; values of zero and one are treated as no multisampling. }
  Multisamples: Integer;

  { The type of depth-stencil buffer to be used with the swap chain. }
  DepthStencil: TDepthStencilType;
 end;

//---------------------------------------------------------------------------
{ List of all rendering swap chains that are to be used with Asphyre device.
  This class describes all swap chains that should be created and used with
  the device; if the device is already initialized, modifying swap chains is
  not allowed. }
 TAsphyreSwapChains = class
 private
  Data: array of TSwapChainDesc;
  FDevice: TObject;

  function IsDeviceInactive(): Boolean;

  function GetCount(): Integer;
  function GetItem(Index: Integer): PSwapChainDesc;
 public
  { The pointer to a valid Asphyre device which owns this list of rendering
    swap chains. }
  property Device: TObject read FDevice;

  { Number of swap chains in the list. }
  property Count: Integer read GetCount;

  { Provides access to each of the rendering swap chains in the list by index,
    which should be in range of [0..(Count - 1)] range. If the index is
    outside of valid range, @nil is returned. }
  property Items[Index: Integer]: PSwapChainDesc read GetItem; default;

  { Inserts a new swap chain to the end of list and returns its index. }
  function Insert(): Integer;

  { Adds a new rendering swap chain with the specified parameters to the end
    of list and returns its index. }
  function Add(WindowHandle: THandle; const Size: TPoint2px;
   Multisamples: Integer = 0; VSync: Boolean = False;
   Format: TAsphyrePixelFormat = apf_Unknown;
   DepthStencil: TDepthStencilType = dstNone): Integer; overload;

  { Adds a new rendering swap chain specified in the given structure to the
    end of list and returns its index. }
  function Add(const Desc: TSwapChainDesc): Integer; overload;

  { Removes the swap at the specified index from the list, shifting all
    elements by one. The index should be in range of [0..(Count - 1)] range;
    if it is outside of valid range, this function does nothing. }
  procedure Remove(Index: Integer);

  { Removes all rendering swap chains from the list. }
  procedure RemoveAll();

  {@exclude}constructor Create(ADevice: TObject);
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Devices;

//---------------------------------------------------------------------------
constructor TAsphyreSwapChains.Create(ADevice: TObject);
begin
 inherited Create();

 FDevice:= ADevice;
end;

//---------------------------------------------------------------------------
destructor TAsphyreSwapChains.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreSwapChains.IsDeviceInactive(): Boolean;
begin
 Result:= True;

 if (Assigned(FDevice))and(FDevice is TAsphyreDevice) then
  Result:= TAsphyreDevice(FDevice).State = adsNotActive;
end;

//---------------------------------------------------------------------------
function TAsphyreSwapChains.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TAsphyreSwapChains.GetItem(Index: Integer): PSwapChainDesc;
begin
 if (Index >= 0)and(Index < Length(Data)) then
  Result:= @Data[Index] 
   else Result:= nil;
end;

//---------------------------------------------------------------------------
function TAsphyreSwapChains.Insert(): Integer;
begin
 if (not IsDeviceInactive()) then
  begin
   Result:= -1;
   Exit;
  end;

 Result:= Length(Data);
 SetLength(Data, Result + 1);

 FillChar(Data[Result], SizeOf(TSwapChainDesc), 0);
end;

//---------------------------------------------------------------------------
function TAsphyreSwapChains.Add(WindowHandle: THandle; const Size: TPoint2px;
 Multisamples: Integer = 0; VSync: Boolean = False;
 Format: TAsphyrePixelFormat = apf_Unknown;
 DepthStencil: TDepthStencilType = dstNone): Integer;
begin
 Result:= Insert();
 if (Result = -1) then Exit;

 Data[Result].WindowHandle:= WindowHandle;

 Data[Result].Width := Size.x;
 Data[Result].Height:= Size.y;
 Data[Result].Format:= Format;
 Data[Result].VSync := VSync;

 Data[Result].Multisamples:= Multisamples;
 Data[Result].DepthStencil:= DepthStencil;
end;

//---------------------------------------------------------------------------
function TAsphyreSwapChains.Add(const Desc: TSwapChainDesc): Integer;
begin
 Result:= Insert();
 if (Result = -1) then Exit;

 Move(Desc, Data[Result], SizeOf(TSwapChainDesc));
end;

//---------------------------------------------------------------------------
procedure TAsphyreSwapChains.Remove(Index: Integer);
var
 i: Integer;
begin
 if (not IsDeviceInactive())or(Index < 0)or(Index >= Length(Data)) then Exit;

 for i:= Index to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);
end;

//---------------------------------------------------------------------------
procedure TAsphyreSwapChains.RemoveAll();
begin
 if (not IsDeviceInactive()) then Exit;

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
end.
