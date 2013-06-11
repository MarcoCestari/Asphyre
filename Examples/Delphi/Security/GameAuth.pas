unit GameAuth;
//---------------------------------------------------------------------------
// This unit must be added to USES list of the main project so that its class
// is properly created and registered in Asphyre events.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 System.SysUtils, Asphyre.Archives, Asphyre.Archives.Auth;

//---------------------------------------------------------------------------
type
 TPasswordProvider = class
 private
  AuthHandle: Cardinal;

  procedure Authorize(Sender: TObject; Auth: TAsphyreAuth;
   Archive: TAsphyreArchive; AuthType: TAuthType);
 public
  function GetKeyText(): string;

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
 PasswordProvider: TPasswordProvider = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Data;

//---------------------------------------------------------------------------
// This is the secret key that will be used for reading and writing ASVF
// archives with encryption enabled. These numbers were randomly generated.
//---------------------------------------------------------------------------
var
 SecretKey: array[0..3] of Cardinal = (
  $971BB0C0, $189F03DE, $1F504BDC, $B4822546);

//---------------------------------------------------------------------------
constructor TPasswordProvider.Create();
begin
 inherited;

 AuthHandle:= Auth.Subscribe(Authorize);
end;

//---------------------------------------------------------------------------
destructor TPasswordProvider.Destroy();
begin
 Auth.Unsubscribe(AuthHandle);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TPasswordProvider.Authorize(Sender: TObject; Auth: TAsphyreAuth;
 Archive: TAsphyreArchive; AuthType: TAuthType);
begin
 if (AuthType = atProvideKey) then
  Auth.ProvideKey(@SecretKey[0]);
end;

//---------------------------------------------------------------------------
function TPasswordProvider.GetKeyText(): string;
begin
 Result:= string(Base64String(@SecretKey[0], SizeOf(SecretKey)));
end;

//---------------------------------------------------------------------------
initialization
 PasswordProvider:= TPasswordProvider.Create();

//---------------------------------------------------------------------------
finalization
 PasswordProvider.Free();

//---------------------------------------------------------------------------
end.
