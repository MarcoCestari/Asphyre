unit Asphyre.Monkey.Connectors;
//---------------------------------------------------------------------------
// FireMonkey Connection Manager.
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
{< Asphyre and FireMonkey hook management. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.SysUtils, FMX.Types3D;

//---------------------------------------------------------------------------
type
{ Asphyre and FireMonkey hook manager. }
 TMonkeyAsphyreConnect = class
 private
  FInitialized: Boolean;
 public
  { Determines whether the connection between Asphyre and FireMonkey is
    currently established. }
  property Initialized: Boolean read FInitialized;

  { Creates the connection between Asphyre and FireMonkey, returning @True if
    the connection is successful, and @False otherwise. If the connection has
    previously been established, this function does nothing and returns @True.
    This function can be called as many times as possible in timer events to
    make sure that the connection remains established.
     @param(Context Valid FireMonkey's context taken from the main form
      (e.g. use @code(Self.Context) in the form's code).) }
  function Init(Context: TContext3D): Boolean;

  { Finalizes the connection between Asphyre and FireMonkey. }
  procedure Done();

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
{ Instance of @link(TMonkeyAsphyreConnect) that is ready to use in
  applications without having to create that class explicitly. }
 MonkeyAsphyreConnect: TMonkeyAsphyreConnect{$ifndef PasDoc} = nil{$endif};

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 FMX.Types,

{$ifdef Windows}
 Asphyre.D3D9, FMX.Context.DX9, Asphyre.Types.DX9, Asphyre.Providers.DX9,
{$endif}

{$if Declared(IOS) or Declared(ANDROID)}
 Asphyre.Providers.GLES,
{$else}
 {$if Declared(Posix)}
 Asphyre.Providers.GL,
 {$endif}
{$endif}

 Asphyre.Monkey.Types, Asphyre.Events, Asphyre.Providers;

//---------------------------------------------------------------------------
constructor TMonkeyAsphyreConnect.Create();
begin
 inherited;

 FInitialized:= False;
end;

//---------------------------------------------------------------------------
destructor TMonkeyAsphyreConnect.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
function TMonkeyAsphyreConnect.Init(Context: TContext3D): Boolean;
begin
 Result:= False;
 if (not Assigned(Context)) then Exit;

 if (FInitialized) then
  begin
   Result:= Context = FireContext;
   Exit;
  end;

 FireContext:= Context;

 //..........................................................................
 // Windows: Hook into FireMonkey (DirectX 9).
 //..........................................................................
{$ifdef Windows}
 {$ifdef DelphiXE2}
 if (not (Context is TCustomDirectXContext)) then
  begin
   FireContext:= nil;
   Exit;
  end;

 D3D9Device:= TCustomDirectXContext(Context).Device;
 if (not Assigned(D3D9Device)) then
  begin
   FireContext:= nil;
   Exit;
  end;

 if (not Succeeded(D3D9Device.GetDirect3D(D3D9Object))) then
  begin
   D3D9Device:= nil;
   FireContext:= nil;
   Exit;
  end;
 {$endif}

 {$ifdef DelphiXE3}
 if (not (Context is TCustomDX9Context)) then
  begin
   FireContext:= nil;
   Exit;
  end;

 D3D9Object:= Asphyre.D3D9.IDirect3D9(TCustomDX9Context(Context).Direct3D9Obj);
 D3D9Device:= Asphyre.D3D9.IDirect3DDevice9(TCustomDX9Context(Context).SharedDevice);

 if (not Assigned(D3D9Device)) then
  begin
   D3D9Object := nil;
   FireContext:= nil;
   Exit;
  end;
 {$endif}

 Factory.UseProvider(idDirectX9);
{$endif}

 //..........................................................................
 // Mac OS X: Hook into FireMonkey (OpenGL).
 //..........................................................................
{$if Declared(IOS) or Declared(ANDROID)}
 Factory.UseProvider(idOpenGL_ES);
{$else}
 {$if Declared(Posix)}
 Factory.UseProvider(idOpenGL);
 {$endif}
{$endif}

 FInitialized:= True;
 Result:= True;

 EventAsphyreCreate.Notify(Self);
 EventTimerReset.Notify(Self);
end;

//---------------------------------------------------------------------------
procedure TMonkeyAsphyreConnect.Done();
begin
 if (not FInitialized) then Exit;

 EventAsphyreDestroy.Notify(Self);

{$ifdef Windows}
 if (Assigned(D3D9Device)) then D3D9Device:= nil;
 if (Assigned(D3D9Object)) then D3D9Object:= nil;
{$endif}

 FireContext := nil;
 FInitialized:= False;
end;

//---------------------------------------------------------------------------
initialization
{$ifdef DelphiXE3}
 GlobalUseDX10:= False;
{$endif}

 MonkeyAsphyreConnect:= TMonkeyAsphyreConnect.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(MonkeyAsphyreConnect);

//---------------------------------------------------------------------------
end.
