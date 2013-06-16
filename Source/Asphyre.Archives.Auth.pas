unit Asphyre.Archives.Auth;
//---------------------------------------------------------------------------
// Asphyre password authorization provider.
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
{< Archive password authentication management, where passwords are provided
   for encrypted Asphyre archives. }
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
 Asphyre.Archives;

//---------------------------------------------------------------------------
type
{ Password authentication type for Asphyre archives. }
 TAuthType = (
  { Indicates that the secure key should be provided for decrypting
    sensitive content. @br @br }
  atProvideKey,

  { Indicates that the secure key should be destroyed as it is no longer
    necessary to prevent third party from acquiring it. The memory used to
    store the key should be replaced with zeros or other random data. }
  atBurnKey);

//---------------------------------------------------------------------------
 TAsphyreAuth = class;

//---------------------------------------------------------------------------
{ Archive password authentication callback function. In this event it is
  necessary to call @code(ProvideKey) function of @link(TAsphyreAuth) to
  provide the password for archive access.
   @param(Sender Sender class that requires secure access to sensitive
    content in Asphyre archive.)
   @param(Auth Reference to authentication class that handles the transaction.)
   @param(Archive Reference to Asphyre's archive class that is currently being
    accessed.)
   @param(AuthType The required authentication type.) }
 TAuthCallback = procedure(Sender: TObject; Auth: TAsphyreAuth;
  Archive: TAsphyreArchive; AuthType: TAuthType) of object;

//---------------------------------------------------------------------------
{@exclude}
 TAuthItem = record
  Callback: TAuthCallback;
  ItemID  : Cardinal;
 end;

//---------------------------------------------------------------------------
{ Archive password authentication class that implements observer pattern for
  providing passwords to archives for encrypting and decrypting sensitive
  information. }
 TAsphyreAuth = class
 private
  Items: array of TAuthItem;
  CurrentID: Cardinal;

  Authorized : Boolean;
  AuthArchive: TAsphyreArchive;
  AuthSender : TObject;
  AuthIndex  : Integer;

  function NextID(): Cardinal;
  function IndexOf(ItemID: Cardinal): Integer;
  procedure Remove(Index: Integer);
 public
  { Subscribes a new callback function that will provide secure password
    authentication to Asphyre archives. The returned ID can be used to
    unsubscribe the callback function. }
  function Subscribe(Callback: TAuthCallback): Cardinal;

  { Removes the subscribed callback function from the list. }
  procedure Unsubscribe(EventID: Cardinal);

  { Provides password authentication to the provided Asphyre archive by
    calling existing callback functions to provide the password. If the
    password has been provided, the returned value is @True and @False
    otherwise. }
  function Authorize(Sender: TObject; Archive: TAsphyreArchive): Boolean;

  { Removes and burns the provided password for the existing Asphyre
    archive so that the password cannot be acquired by a third party. }
  procedure Unauthorize();

  { Provides the password to the archive that is currently being
    authenticated. The @code(Key) parameter should point to a valid memory
    block of 16 bytes that contain 128-bit password. }
  procedure ProvideKey(Key: Pointer);
 end;

//---------------------------------------------------------------------------
var
{ Instance of @link(TAsphyreAuth) that is used by Asphyre components for
  providing passwords to Asphyre archives for encrypting and decrypting
  secure information. }
 Auth: TAsphyreAuth = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
function TAsphyreAuth.NextID(): Cardinal;
begin
 Result:= CurrentID;
 Inc(CurrentID);
end;

//---------------------------------------------------------------------------
function TAsphyreAuth.IndexOf(ItemID: Cardinal): Integer;
var
 i: Integer;
begin
 Result:= -1;

 for i:= 0 to Length(Items) - 1 do
  if (Items[i].ItemID = ItemID) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreAuth.Subscribe(Callback: TAuthCallback): Cardinal;
var
 Index: Integer;
begin
 Result:= NextID();

 Index:= Length(Items);
 SetLength(Items, Length(Items) + 1);

 Items[Index].Callback:= Callback;
 Items[Index].ItemID  := Result;
end;

//---------------------------------------------------------------------------
procedure TAsphyreAuth.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Items)) then Exit;

 for i:= Index to Length(Items) - 2 do
  Items[i]:= Items[i + 1];

 SetLength(Items, Length(Items) - 1);
end;

//---------------------------------------------------------------------------
procedure TAsphyreAuth.Unsubscribe(EventID: Cardinal);
begin
 Unauthorize();
 Remove(IndexOf(EventID));
end;

//---------------------------------------------------------------------------
function TAsphyreAuth.Authorize(Sender: TObject;
 Archive: TAsphyreArchive): Boolean;
var
 i: Integer;
begin
 Authorized := False;
 AuthArchive:= Archive;
 AuthSender := Sender;
 AuthIndex  := -1;

 for i:= 0 to Length(Items) - 1 do
  begin
   Items[i].Callback(AuthSender, Self, AuthArchive, atProvideKey);
   if (Authorized) then
    begin
     AuthIndex:= i;
     Break;
    end;
  end;

 Result:= Authorized;
 if (not Result) then
  begin
   AuthArchive:= nil;
   AuthSender := nil;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreAuth.Unauthorize();
begin
 if (Authorized)and(AuthIndex >= 0)and(AuthIndex < Length(Items)) then
  Items[AuthIndex].Callback(AuthSender, Self, AuthArchive, atBurnKey);

 Authorized := False;
 AuthIndex  := -1;
 AuthArchive:= nil;
end;

//---------------------------------------------------------------------------
procedure TAsphyreAuth.ProvideKey(Key: Pointer);
begin
 if (Assigned(AuthArchive)) then
  begin
   AuthArchive.Password:= Key;
   Authorized:= True;
  end;
end;

//---------------------------------------------------------------------------
initialization
 Auth:= TAsphyreAuth.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(Auth);

//---------------------------------------------------------------------------
end.
