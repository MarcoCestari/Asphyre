unit Asphyre.Providers;
//---------------------------------------------------------------------------
// Provides implementation of factory pattern for Asphyre.
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
{< General factory implementation that creates all provider-dependent classes
   such as device, canvas and textures. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
{$ifndef fpc}
 System.SysUtils,
{$else}
 SysUtils,
{$endif}
 Asphyre.Devices, Asphyre.Canvas, Asphyre.Textures;

//---------------------------------------------------------------------------
type
 { General definition of Asphyre provider, which should create all hardware
   specific classes. }
 TAsphyreProvider = class
 protected
  FProviderID: Cardinal;
 public
  { The numerical identifier of the provider that must be unique among all
    providers supported in Asphyre. }
  property ProviderID: Cardinal read FProviderID;

  { This function creates hardware-specific Asphyre device. }
  function CreateDevice(): TAsphyreDevice; virtual; abstract;

  { This function creates hardware-specific Asphyre canvas. }
  function CreateCanvas(): TAsphyreCanvas; virtual; abstract;

  { This function creates hardware-specific lockable texture. }
  function CreateLockableTexture(): TAsphyreLockableTexture; virtual; abstract;

  { This function creates hardware-specific render target texture.
    If render targets are not supported in this provider, @nil is returned. }
  function CreateRenderTargetTexture(): TAsphyreRenderTargetTexture; virtual; abstract;
 end;

//---------------------------------------------------------------------------
{ General factory object that creates all provider-dependant classes such
  as device, canvas and textures. }
 TAsphyreFactory = class
 private
  Providers: array of TAsphyreProvider;
  Provider : TAsphyreProvider;

  function IndexOf(AProvider: TAsphyreProvider): Integer;
  function Insert(AProvider: TAsphyreProvider): Integer;
  procedure Remove(Index: Integer; NoFree: Boolean);
  procedure RemoveAll();
  function FindProvider(ID: Cardinal): TAsphyreProvider;
 public
  { Creates Asphyre device that is specific to the currently selected
    provider.}
  function CreateDevice(): TAsphyreDevice;

  { Creates Asphyre canvas that is specific to the currently selected
    provider.}
  function CreateCanvas(): TAsphyreCanvas;

  { Creates lockable Asphyre texture that is specific to the currently
    selected provider.}
  function CreateLockableTexture(): TAsphyreLockableTexture;

  { Creates render target Asphyre texture texture that is specific to the
    currently selected provider.}
  function CreateRenderTargetTexture(): TAsphyreRenderTargetTexture;

  { Subscribes a new provider to the list of available providers that can be
    used by the application. This function is usually called automatically
    by each of the providers. }
  procedure Subscribe(AProvider: TAsphyreProvider);

  { Unsubscribes the specified provider from the list of available providers
    that can be used by the application. }
  procedure Unsubscribe(AProvider: TAsphyreProvider; NoFree: Boolean = False);

  { Activates the provider with the given numerical identifier to be used by
    the factory's creation functions. }
  procedure UseProvider(ProviderID: Cardinal);

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
{ Instance of @link(TAsphyreFactory) that is ready to use in applications
  without having to create that class explicitly. This factory object is used
  by the entire framework. }
 Factory: TAsphyreFactory{$ifndef PasDoc} = nil{$endif};

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyreFactory.Create();
begin
 inherited;

 Provider:= nil;
end;

//---------------------------------------------------------------------------
destructor TAsphyreFactory.Destroy();
begin
 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreFactory.IndexOf(AProvider: TAsphyreProvider): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Providers) - 1 do
  if (Providers[i] = AProvider) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreFactory.Insert(AProvider: TAsphyreProvider): Integer;
var
 Index: Integer;
begin
 Index:= Length(Providers);
 SetLength(Providers, Index + 1);

 Providers[Index]:= AProvider;
 Result:= Index;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFactory.RemoveAll();
var
 i: Integer;
begin
 for i:= 0 to Length(Providers) - 1 do
  if (Assigned(Providers[i])) then FreeAndNil(Providers[i]);

 SetLength(Providers, 0);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFactory.Remove(Index: Integer; NoFree: Boolean);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Providers)) then Exit;

 if (Assigned(Providers[Index]))and(not NoFree) then
  FreeAndNil(Providers[Index]);

 for i:= Index to Length(Providers) - 2 do
  Providers[i]:= Providers[i + 1];

 SetLength(Providers, Length(Providers) - 1);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFactory.Subscribe(AProvider: TAsphyreProvider);
var
 Index: Integer;
begin
 Index:= IndexOf(AProvider);
 if (Index = -1) then Insert(AProvider);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFactory.Unsubscribe(AProvider: TAsphyreProvider;
 NoFree: Boolean);
begin
 Remove(IndexOf(AProvider), NoFree);
end;

//---------------------------------------------------------------------------
function TAsphyreFactory.FindProvider(ID: Cardinal): TAsphyreProvider;
var
 Index, i: Integer;
begin
 Index:= -1;

 for i:= 0 to Length(Providers) - 1 do
  if (Providers[i].ProviderID = ID) then
   begin
    Index:= i;
    Break;
   end;

 if (Index = -1)and(Length(Providers) > 0) then Index:= 0;

 Result:= nil;
 if (Index <> -1) then Result:= Providers[Index];
end;

//---------------------------------------------------------------------------
procedure TAsphyreFactory.UseProvider(ProviderID: Cardinal);
begin
 Provider:= FindProvider(ProviderID);
end;

//---------------------------------------------------------------------------
function TAsphyreFactory.CreateDevice(): TAsphyreDevice;
begin
 Result:= nil;

 if (Assigned(Provider)) then
  Result:= Provider.CreateDevice();
end;

//---------------------------------------------------------------------------
function TAsphyreFactory.CreateCanvas(): TAsphyreCanvas;
begin
 Result:= nil;

 if (Assigned(Provider)) then
  Result:= Provider.CreateCanvas();
end;

//---------------------------------------------------------------------------
function TAsphyreFactory.CreateLockableTexture(): TAsphyreLockableTexture;
begin
 Result:= nil;

 if (Assigned(Provider)) then
  Result:= Provider.CreateLockableTexture();
end;

//---------------------------------------------------------------------------
function TAsphyreFactory.CreateRenderTargetTexture(): TAsphyreRenderTargetTexture;
begin
 Result:= nil;

 if (Assigned(Provider)) then
  Result:= Provider.CreateRenderTargetTexture();
end;

//---------------------------------------------------------------------------
initialization
 Factory:= TAsphyreFactory.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(Factory);

//---------------------------------------------------------------------------
end.



