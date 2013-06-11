unit Asphyre.NetComs.Types;
//---------------------------------------------------------------------------
// Common types for Simple UDP Communication class.
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
{< Data types, constants and helper cross-platform routines that form part of
   or complement @link(TNetCom) class. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
{$ifdef Windows}
 Winapi.WinSock,
{$endif}

//...........................................................................
{$ifdef fpc}
{$ifdef Unix}
 termio, BaseUnix,
{$endif}
 Sockets,
{$endif}

{$if defined(Delphi) and defined(Posix)}
{$define DelphiPosix}
{$warn unit_platform off}
 Posix.Errno, Posix.NetinetIn, Posix.Unistd, Posix.StrOpts, Posix.SysSocket,
{$ifend}

//...........................................................................
 System.SysUtils, System.StrUtils, Asphyre.TypeDef;

//---------------------------------------------------------------------------
type
{$ifdef DelphiPosix}
 {@exclude}TSocket = Integer;

 {@exclude}TInAddr = packed record
   S_addr: Longword;
  end;

 {@exclude}TSockAddr = packed record
  sin_family: Word;
  sin_port: Word;
  sin_addr: TInAddr;
  sin_zero: array [0..7] of Byte;
 end;
{$endif}

 {@exclude}PAsphyreSocket = ^TAsphyreSocket;
 {@exclude}TAsphyreSocket = TSocket;

//---------------------------------------------------------------------------
 {@exclude}PAsphyreSockAddr = ^TAsphyreSockAddr;
 {@exclude}TAsphyreSockAddr = TSockAddr;

//---------------------------------------------------------------------------
const
 {@exclude}ASCK_TRUE  = 1;
 {@exclude}ASCK_FALSE = 0;

//---------------------------------------------------------------------------
 {@exclude}ASCK_INVALID_SOCKET = TAsphyreSocket($FFFFFFFF);
 {@exclude}ASCK_SOCKET_ERROR   = -1;

//---------------------------------------------------------------------------
 {@exclude}ASCK_WOULD_BLOCK =
  {$ifdef fpc}EsockEWOULDBLOCK{$else}EWOULDBLOCK{$endif};

//---------------------------------------------------------------------------
{ Converts binary IPv4 address representation to text string. }
function IntToHost(Value: LongWord): StdString;

//---------------------------------------------------------------------------
{ Converts text string containing host address into IPv4 binary address. }
function HostToInt(const Host: StdString): LongWord;

//---------------------------------------------------------------------------
{ Converts text containing host address into the corresponding IP address. }
function ResolveHost(const Host: StdString): StdString;

//---------------------------------------------------------------------------
{ Converts text containing IP address into the corresponding host string. }
function ResolveIP(const IPAddr: StdString): StdString;

//---------------------------------------------------------------------------
{ Returns IP address of current machine. If several IP addresses are present,
  the last address in the list is returned. }
function GetLocalIP(): StdString;

//---------------------------------------------------------------------------
{@exclude}function CreateSocket(): TAsphyreSocket;
{@exclude}procedure DestroySocket(var Handle: TAsphyreSocket);

//---------------------------------------------------------------------------
{@exclude}function BindSocket(Handle: TAsphyreSocket;
 LocalPort: Integer): Boolean;
{@exclude}function GetSocketPort(Handle: TAsphyreSocket): Integer;
{@exclude}function SetSocketToNonBlock(Handle: TAsphyreSocket): Boolean;

//---------------------------------------------------------------------------
{@exclude}function SocketSendData(Handle: TAsphyreSocket; Data: Pointer;
 DataSize: Integer; const DestHost: StdString; DestPort: Integer): Boolean;

//---------------------------------------------------------------------------
{@exclude}function SocketReceiveData(Handle: TAsphyreSocket; Data: Pointer;
 MaxDataSize: Integer; out SrcHost: StdString; out SrcPort: Integer): Integer;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
{$ifdef Windows}
var
 TempStringBuf: array[0..511] of AnsiChar;
{$endif}

//---------------------------------------------------------------------------
{$ifdef Windows}
 WinSockSession: TWSAdata;
 WinSockEnabled: Boolean = False;
{$endif}

//---------------------------------------------------------------------------
function IntToHost(Value: LongWord): StdString;
var
 InpByte: PByte;
begin
 InpByte:= @Value;
 Result:= IntToStr(InpByte^) + '.';

 Inc(InpByte);
 Result:= Result + IntToStr(InpByte^) + '.';

 Inc(InpByte);
 Result:= Result + IntToStr(InpByte^) + '.';

 Inc(InpByte);
 Result:= Result + IntToStr(InpByte^);
end;

//---------------------------------------------------------------------------
function IP4AddrToInt(const Text: StdString): LongWord;
var
 i, DotAt, LastPos, Value: Integer;
 DestByte: PByte;
 NumText: StdString;
begin
 Result:= 0;
 LastPos:= 1;

 DestByte:= @Result;

 for i:= 0 to 3 do
  begin
   if (i < 3) then
    begin
     DotAt:= PosEx('.', Text, LastPos);
     if (DotAt = 0) then Exit;

     NumText:= Copy(Text, LastPos, DotAt - LastPos);
     LastPos:= DotAt + 1;
    end else
     NumText:= Copy(Text, LastPos, (Length(Text) - LastPos) + 1);

   Value:= StrToIntDef(NumText, -1);
   if (Value < 0)or(Value > 255) then Exit;

   DestByte^:= Value;
   Inc(DestByte);
  end;
end;

//---------------------------------------------------------------------------
function HostToInt(const Host: StdString): LongWord;
{$ifdef Windows}
var
 HostEnt: PHostEnt;
{$endif}
begin
 Result:= IP4AddrToInt(Host);

 {$ifdef Windows}
 if (Result = 0) then
  begin
   StrPCopy(@TempStringBuf, AnsiString(Host));
   HostEnt:= GetHostByName(TempStringBuf);
   if (not Assigned(HostEnt)) then
    begin
     Result:= 0;
     Exit;
    end;

   Result:= PLongWord(HostEnt.h_addr_list^)^;
  end;
 {$endif}
end;

//---------------------------------------------------------------------------
function ResolveHost(const Host: StdString): StdString;
var
 Addr: LongWord;
begin
 Addr:= HostToInt(Host);
 Result:= IntToHost(Addr);
end;

//---------------------------------------------------------------------------
function ResolveIP(const IPAddr: StdString): StdString;
{$ifdef Windows}
var
 HostEnt: PHostEnt;
 Addr   : LongWord;
{$endif}
begin
 {$ifdef Windows}
 Addr:= HostToInt(IPAddr);
 HostEnt:= GetHostByAddr(@Addr, 4, AF_INET);

 if (Assigned(HostEnt)) then Result:= StdString(AnsiString(HostEnt.h_name))
  else Result:= IntToHost(LongWord(INADDR_NONE));
 {$else}
 Result:= '0.0.0.0';
 {$endif}
end;

//---------------------------------------------------------------------------
function GetLocalIP(): StdString;
{$ifdef Windows}
type
 PInAddrs = ^TInAddrs;
 TInAddrs = array[Word] of PInAddr;
var
 HostEnt: PHostEnt;
 Index  : Integer;
 InAddp : PInAddrs;
{$endif}
begin
 {$ifdef Windows}
 GetHostName(TempStringBuf, SizeOf(TempStringBuf));
 HostEnt:= GetHostByName(TempStringBuf);
 if (not Assigned(HostEnt)) then Exit;

 Index:= 0;
 InAddp:= Pointer(HostEnt.h_addr_list);

 while (Assigned(InAddp[Index])) do
  begin
   Result:= IntToHost(InAddp[Index].S_addr);
   Inc(Index);
  end;
 {$else}
 Result:= '127.0.0.1';
 {$endif}
end;

//---------------------------------------------------------------------------
function CreateSocket(): TAsphyreSocket;
var
 SocketOption: LongWord;
begin
{$ifdef fpc}
 Result:= fpSocket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
{$else}
 Result:= Socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
{$endif}

 if (Result <> ASCK_INVALID_SOCKET) then
  begin
   SocketOption:= ASCK_TRUE;

  {$ifdef fpc}
   fpSetSockOpt(Result, SOL_SOCKET, SO_BROADCAST, @SocketOption,
    SizeOf(SocketOption));
  {$else}
   {$ifdef DelphiPosix}
   SetSockOpt(Result, SOL_SOCKET, SO_BROADCAST, SocketOption,
    SizeOf(SocketOption));
   {$else}
   SetSockOpt(Result, SOL_SOCKET, SO_BROADCAST, @SocketOption,
    SizeOf(SocketOption));
   {$endif}
  {$endif}
  end;
end;

//---------------------------------------------------------------------------
procedure DestroySocket(var Handle: TAsphyreSocket);
begin
 if (Handle <> ASCK_INVALID_SOCKET) then
  begin
  {$ifdef DelphiPosix}
   __close(Handle);
  {$else}
   CloseSocket(Handle);
  {$endif}

   Handle:= ASCK_INVALID_SOCKET;
  end;
end;

//---------------------------------------------------------------------------
function BindSocket(Handle: TAsphyreSocket; LocalPort: Integer): Boolean;
var
 TempAddr: TAsphyreSockAddr;
begin
 FillChar(TempAddr, SizeOf(TAsphyreSockAddr), 0);

 TempAddr.sin_port  := LocalPort;
 TempAddr.sin_family:= AF_INET;

{$ifdef fpc}
 Result:= fpBind(Handle, @TempAddr, SizeOf(TAsphyreSockAddr)) = 0;
{$else}
 {$ifdef DelphiPosix}
 Result:= Bind(Handle, sockaddr(TempAddr), SizeOf(TAsphyreSockAddr)) = 0;
 {$else}
 Result:= Bind(Handle, TempAddr, SizeOf(TAsphyreSockAddr)) = 0;
 {$endif}
{$endif}
end;

//---------------------------------------------------------------------------
function GetSocketPort(Handle: TAsphyreSocket): Integer;
var
 TempAddr: TAsphyreSockAddr;
 SocketOption: LongWord;
begin
 FillChar(TempAddr, SizeOf(TAsphyreSockAddr), 0);
 SocketOption:= SizeOf(TempAddr);

{$ifdef fpc}
 fpGetSockName(Handle, @TempAddr, @SocketOption);
{$else}
 {$ifdef DelphiPosix}
 GetSockName(Handle, sockaddr(TempAddr), SocketOption);
 {$else}
 GetSockName(Handle, TempAddr, Integer(SocketOption));
 {$endif}
{$endif}

 Result:= TempAddr.sin_port;
end;

//---------------------------------------------------------------------------
function SetSocketToNonBlock(Handle: TAsphyreSocket): Boolean;
var
 SocketOption: LongWord;
begin
 SocketOption:= Cardinal(True);

{$ifdef Windows}
 {$ifdef fpc}
 Result:= ioctlsocket(Handle, FIONBIO, @SocketOption) = 0;
 {$else}
 Result:= ioctlsocket(Handle, FIONBIO, Integer(SocketOption)) = 0;
 {$endif}
{$endif}

{$if defined(fpc) and defined(Unix)}
 Result:= fpioctl(Handle, FIONBIO, @SocketOption) = 0;
{$ifend}

{$ifdef DelphiPosix}
 Result:= ioctl(Handle, Integer(FIONBIO), @SocketOption) = 0;
{$endif}
end;

//---------------------------------------------------------------------------
function SocketSendData(Handle: TAsphyreSocket; Data: Pointer;
 DataSize: Integer; const DestHost: StdString; DestPort: Integer): Boolean;
var
 TempAddr: TAsphyreSockAddr;
 Res: Integer;
begin
 FillChar(TempAddr, SizeOf(TAsphyreSockAddr), 0);

 TempAddr.sin_addr.S_addr:= HostToInt(DestHost);
 if (Integer(TempAddr.sin_addr.S_addr) = 0) then
  begin
   Result:= False;
   Exit;
  end;

 TempAddr.sin_family:= AF_INET;
 TempAddr.sin_port  := DestPort;

{$ifdef fpc}
 Res:= fpSendTo(Handle, Data, DataSize, 0, @TempAddr, SizeOf(TSockAddr));
{$else}
 {$ifdef DelphiPosix}
 Res:= SendTo(Handle, Data^, DataSize, 0, sockaddr(TempAddr),
  SizeOf(TSockAddr));
 {$else}
 Res:= SendTo(Handle, Data^, DataSize, 0, TempAddr, SizeOf(TSockAddr));
 {$endif}
{$endif}

 Result:= (Res > 0)and(Res = DataSize);
end;

//---------------------------------------------------------------------------
function SocketReceiveData(Handle: TAsphyreSocket; Data: Pointer;
 MaxDataSize: Integer; out SrcHost: StdString; out SrcPort: Integer): Integer;
var
 SocketOption: LongWord;
 TempAddr: TAsphyreSockAddr;
 Res: Integer;
begin
 Result:= 0;

 SocketOption:= SizeOf(TSockAddr);
 FillChar(TempAddr, SizeOf(TAsphyreSockAddr), 0);

{$ifdef fpc}
 Res:= fpRecvFrom(Handle, Data, MaxDataSize, 0, @TempAddr, @SocketOption);
{$else}
 {$ifdef DelphiPosix}
 Res:= RecvFrom(Handle, Data^, MaxDataSize, 0, sockaddr(TempAddr), SocketOption);
 {$else}
 Res:= RecvFrom(Handle, Data^, MaxDataSize, 0, TempAddr, Integer(SocketOption));
 {$endif}
{$endif}

 if (Res = ASCK_SOCKET_ERROR)or(Res = ASCK_WOULD_BLOCK)or(Res < 1) then Exit;

 SrcPort:= TempAddr.sin_port;
 SrcHost:= IntToHost(TempAddr.sin_addr.S_addr);

 Result:= Res;
end;

//---------------------------------------------------------------------------
initialization
{$ifdef Windows}
 WinSockEnabled:= WSAStartup($101, WinSockSession) = 0;
{$endif}

//---------------------------------------------------------------------------
finalization
{$ifdef Windows}
 if (WinSockEnabled) then
  begin
   WSACleanup();
   FillChar(WinSockSession, SizeOf(TWSAdata), 0);

   WinSockEnabled:= False;
  end;
{$endif}

//---------------------------------------------------------------------------
end.
