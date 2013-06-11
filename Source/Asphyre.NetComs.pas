unit Asphyre.NetComs;
//---------------------------------------------------------------------------
// Simple UDP communication wrapper.
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
{< Provides communication and multiplayer capabilities by using simple
   message system based on UDP communication protocol. }
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
{$include Asphyre.Config.inc}

//---------------------------------------------------------------------------
uses
 System.SysUtils, System.Classes, Asphyre.TypeDef, Asphyre.NetComs.Types;

//---------------------------------------------------------------------------
const
 {@exclude}NetMaximumPacketSize = 8166;
 {@exclude}NetPacketHeaderSize  = 18;
 {@exclude}NetMaximumBodySize   = NetMaximumPacketSize - NetPacketHeaderSize;

//---------------------------------------------------------------------------
type
 {@exclude}PMessageBody = ^TMessageBody;
 {@exclude}TMessageBody = packed array[0..NetMaximumBodySize - 1] of Byte;

//---------------------------------------------------------------------------
// Message header added to all packets
//---------------------------------------------------------------------------
 {@exclude}PPacketMessage = ^TPacketMessage;
 {@exclude}TPacketMessage = packed record
  PacketSize: Word;
  Checksum: array[0..3] of LongWord;
  DataBody: TMessageBody;
 end;

//---------------------------------------------------------------------------
{ The declaration of data reception event. In this event the message should
  be interpreted and properly handled. After this event the memory referenced
  by the pointers is lost so to preserve the message it is necessary to copy
  it within this event. The source host and port can be used to identify the
  transceiver and for sending replies.
   @param(Sender Reference to the class that received the message,
    usually @link(TNetCom).)
   @param(Host Source host that sent the message.)
   @param(Port Source port through which the message was sent.)
   @param(Data Pointer to the beginning of message block.)
   @param(Size Size of the message block.) }
 TReceiveEvent = procedure(Sender: TObject; const Host: StdString;
  Port: Integer; Data: Pointer; Size: Integer) of object;

//---------------------------------------------------------------------------
{ UDP wrapper class that provides a simple way of UDP communication between
  different applications over network and Internet. The messages sent by
  this component are compressed using ZLib to save bandwidth when sending
  large packets. MD5 checksum verification is used internally for integrity
  checks. }
 TNetCom = class
 private
  hSocket: TAsphyreSocket;

  FInitialized: Boolean;
  FLocalPort  : Integer;
  FOnReceive  : TReceiveEvent;

  PacketMsg : TPacketMessage;
  DecodeBody: TMessageBody;

  FBytesReceived    : Integer;
  FBodyBytesReceived: Integer;
  FBytesSent        : Integer;
  FBodyBytesSent    : Integer;
  FSentPackets      : Integer;
  FDiscardedPackets : Integer;
  FReceivedPackets  : Integer;
  FBytesPerSec      : Integer;
  BytesTransferred  : Integer;

  LastTickCount: LongWord;

  function InitSock(): Boolean;
  procedure DoneSock();
  procedure SetLocalPort(const Value: Integer);
  procedure SockReceive();

  procedure EncodePacket(Data: Pointer; Size: Integer);
  function DecodePacket(out Data: Pointer; out Size: Integer): Boolean;
 public
  { Determines whether the component has been property initialized. }
  property Initialized: Boolean read FInitialized;

  { The local port that will be used for UDP communication both for sending
    and receiving packets. If the specified port is unavailable during
    initialization, a different (and possibly random) value will be used.
    In this case, this parameter will be updated accordingly. }
  property LocalPort: Integer read FLocalPort write SetLocalPort;

  { This event occurs when the data has been received. It should always be
    assigned to interpret any incoming messages. }
  property OnReceive: TReceiveEvent read FOnReceive write FOnReceive;

  { Indicates how many bytes were received during the entire session. }
  property BytesReceived: Integer read FBytesReceived;

  { Indicates how many bytes of message body have been received (uncompressed,
    without counting the header size). Can be used to determine the compression
    ratio of the incoming data. }
  property BodyBytesReceived: Integer read FBodyBytesReceived;

  { Indicates how many bytes were sent during the entire session. }
  property BytesSent: Integer read FBytesSent;

  { Indicates how many bytes of message body have been sent (uncompressed,
    without counting the header size). Can be used to determine the compression
    ratio of the outcoming data. }
  property BodyBytesSent: Integer read FBodyBytesSent;

  { Indicates how many packets were sent during the entire session. }
  property SentPackets: Integer read FSentPackets;

  { Indicates how many packets were discarded during the entire session. This
    can be a direct indication of errors during the session where packets were
    badly received. }
  property DiscardedPackets: Integer read FDiscardedPackets;

  { Indicates how many packets in total were received during the entire
    session. }
  property ReceivedPackets: Integer read FReceivedPackets;

  { Indicates the current bandwidth usage in bytes per second. In order for
    this variable to have meaningful values, it is necessary to call
    @link(Update) method at least once per second. }
  property BytesPerSec: Integer read FBytesPerSec;

  //.........................................................................
  { Initializes the component and begins listening to the given port for
    incoming messages. @link(LocalPort) should be set prior calling this
    method. If the method succeeds, @link(LocalPort) will be updated with
    a new port that is being used (if the suggested one could not be used). }
  function Initialize(): Boolean;

  { Finalizes the component and closes the communication link. }
  procedure Finalize();

  { Sends the specified message data block to the destination. This method
    returns @True if the message could be sent and @False if there were any
    errors. Please note that since messages are sent through UDP protocol, so
    a resulting @True value does not necessarily mean that the message was
    actually received.
     @param(Host Destination host or address where the message should be sent.
      Multicast and broadcast addresses are accepted, although should be
      used with care to not saturate the local network.)
     @param(Port Destination port where the receiver is currently listening at.)
     @param(Data Pointer to the message data block. The method copies the data
      to its internal structures, so it's not necessary to maintain the data
      after this call exits.)
     @param(Size Size of the message data block.) }
  function Send(const Host: StdString; Port: Integer; Data: Pointer;
   Size: Integer): Boolean;

  { Handles internal communication and receives incoming messages; in addition,
    internal structures and bandwidth usage are also updated. This method
    should be called as fast as possible and no less than once per second.
    During the call to this method, @link(OnReceive) event may occur to notify
    the reception of messages. }
  procedure Update();

  { Resets all statistic parameters related to the current session such as
    number of packets transmitted, bytes per second among others. }
  procedure ResetStatistics();

  {@exclude}constructor Create();
  {@exclude}destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
{ An active instance of @link(TNetCom) class that can be used for sending and
  receiving UDP messages without having to create it explicitly. This variable
  is always created and instantiated upon application's execution and freed
  when the application terminates. }
 NetCom: TNetCom{$ifndef PasDoc} = nil{$endif};

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 Asphyre.Types, Asphyre.Data, Asphyre.Timing;

//---------------------------------------------------------------------------
const
 UpdateRefreshTime = 1000; // milliseconds

//---------------------------------------------------------------------------
 ChecksumSize = 16;

//---------------------------------------------------------------------------
 ChecksumInitValues: array[0..3] of LongWord = ($B3369362, $F11C8276,
  $4B55106A, $3C1FD6F4);

//---------------------------------------------------------------------------
constructor TNetCom.Create();
begin
 inherited;

 FInitialized:= False;
 FLocalPort  := 8500;

 hSocket:= ASCK_INVALID_SOCKET;
end;

//---------------------------------------------------------------------------
destructor TNetCom.Destroy();
begin
 if (FInitialized) then Finalize();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TNetCom.SetLocalPort(const Value: Integer);
begin
 if (not FInitialized) then
  FLocalPort:= MinMax2(Value, 0, 65535);
end;

//---------------------------------------------------------------------------
function TNetCom.InitSock(): Boolean;
begin
 // (1) Create socket for sending datagrams over Internet.
 hSocket:= CreateSocket();
 if (hSocket = ASCK_INVALID_SOCKET) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Bind socket to the specified port.
 Result:= BindSocket(hSocket, FLocalPort);
 if (not Result) then
  begin
   DestroySocket(hSocket);
   Exit;
  end;

 // (4) Retrieve the local port (in case it is different from the
 // specified one).
 FLocalPort:= GetSocketPort(hSocket);

 // (5) Set socket to non-blocking mode.
 Result:= SetSocketToNonBlock(hSocket);
 if (not Result) then
  begin
   DestroySocket(hSocket);
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TNetCom.DoneSock();
begin
 DestroySocket(hSocket);
end;

//---------------------------------------------------------------------------
procedure TNetCom.ResetStatistics();
begin
 FBytesReceived    := 0;
 FBodyBytesReceived:= 0;
 FBytesSent        := 0;
 FBodyBytesSent    := 0;
 FSentPackets      := 0;
 FDiscardedPackets := 0;
 FReceivedPackets  := 0;
 FBytesPerSec      := 0;
 BytesTransferred  := 0;
end;

//---------------------------------------------------------------------------
function TNetCom.Initialize(): Boolean;
begin
 // (1) Check if the component is already initialized.
 if (FInitialized) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Initialize and prepare the socket for transmission.
 Result:= InitSock();
 if (not Result) then Exit;

 // (3) Update information counters and other variables.
 ResetStatistics();

 FInitialized := True;
 LastTickCount:= Timing.GetTickCount();
end;

//---------------------------------------------------------------------------
procedure TNetCom.Finalize();
begin
 if (not FInitialized) then Exit;

 DoneSock();

 FInitialized:= False;
end;

//---------------------------------------------------------------------------
procedure TNetCom.EncodePacket(Data: Pointer; Size: Integer);
begin
 // (1) Prepare message packet with tentative checksum value.
 PacketMsg.PacketSize:= NetPacketHeaderSize + Size;

 // -> Copy the initial values used for checksum calculation.
 Move(ChecksumInitValues, PacketMsg.Checksum, ChecksumSize);

 // -> Copy the message body to the packet.
 Move(Data^, PacketMsg.DataBody, Size);

 // (2) Compute the checksum based on the tentative data and store it.
 MD5Checksum(@PacketMsg, PacketMsg.PacketSize, @PacketMsg.Checksum[0]);
end;

//---------------------------------------------------------------------------
function TNetCom.Send(const Host: StdString; Port: Integer; Data: Pointer;
 Size: Integer): Boolean;
begin
 // (1) Verify initial conditions.
 Result:= (FInitialized)and(Assigned(Data))and(Size > 0)and
  (Size <= NetMaximumBodySize);
 if (not Result) then Exit;

 // (2) Place the data in message body.
 EncodePacket(Data, Size);

 // (3) Send the message.
 Result:= SocketSendData(hSocket, @PacketMsg, PacketMsg.PacketSize, Host, Port);

 // (4) Update information counters.
 if (Result) then
  begin
   Inc(FSentPackets);
   Inc(FBytesSent, PacketMsg.PacketSize);
   Inc(FBodyBytesSent, Size);
   Inc(BytesTransferred, PacketMsg.PacketSize);
  end;
end;

//---------------------------------------------------------------------------
function TNetCom.DecodePacket(out Data: Pointer; out Size: Integer): Boolean;
var
 StoredChecksum, Checksum: array[0..3] of LongWord;
begin
 Data:= nil;
 Size:= 0;

 // (1) Store the received checksum and put the initial values so that a real
 // checksum can be calculated.
 Move(PacketMsg.Checksum, StoredChecksum, ChecksumSize);
 Move(ChecksumInitValues, PacketMsg.Checksum, ChecksumSize);

 // (2) Compute the real checksum and compare it to the stored value.
 MD5Checksum(@PacketMsg, PacketMsg.PacketSize, @Checksum[0]);

 if (not CompareMem(@StoredChecksum[0], @Checksum[0], ChecksumSize)) then
  begin // Incoming packet failed integrity check.
   Inc(FDiscardedPackets);
   Result:= False;
   Exit;
  end;

 // (3) Determine the message (body) size and check if it's valid.
 Size:= PacketMsg.PacketSize - NetPacketHeaderSize;
 if (Size < 1)or(Size > NetMaximumBodySize) then
  begin // Incoming packet has invalid size.
   Inc(FDiscardedPackets);
   Result:= False;
   Exit;
  end;

 // (4) Transfer the packet body to a different buffer and return it.
 Move(PacketMsg.DataBody, DecodeBody, Size);

 Data:= @DecodeBody;
 Inc(FBodyBytesReceived, Size);

 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TNetCom.SockReceive();
var
 ReceivedBytes, FromPort, RelaySize: Integer;
 FromHost: StdString;
 RelayData: Pointer;
begin
 // (1) Attempt to read a message from packet queue.
 ReceivedBytes:= SocketReceiveData(hSocket, @PacketMsg, NetMaximumPacketSize,
  FromHost, FromPort);

 if (ReceivedBytes < 1) then Exit;

 // (2) Update information counters.
 Inc(FReceivedPackets);
 Inc(FBytesReceived, ReceivedBytes);
 Inc(BytesTransferred, ReceivedBytes);

 // (3) Perform a quick test to determine whether the packet is valid.
 // -> Incoming packet should have at least header and +1 byte to be processed.
 // -> The size of the received packet should match its declaration.
 // -> The output body size must fit in our body size and be non-zero.
 if (ReceivedBytes <= NetPacketHeaderSize)or
  (ReceivedBytes <> PacketMsg.PacketSize) then
  begin // Incoming packet has invalid header.
   Inc(FDiscardedPackets);
   Exit;
  end;

 // (4) Invoke the reception event if the packet can be decoded properly.
 if (Assigned(FOnReceive))and(DecodePacket(RelayData, RelaySize)) then
  FOnReceive(Self, FromHost, FromPort, RelayData, RelaySize);
end;

//---------------------------------------------------------------------------
procedure TNetCom.Update();
var
 NowTickCount, ElapsedTime: LongWord;
begin
 NowTickCount:= Timing.GetTickCount();
 ElapsedTime := NowTickCount - LastTickCount;

 if (ElapsedTime > UpdateRefreshTime) then
  begin
   LastTickCount:= NowTickCount;

   FBytesPerSec:= (Int64(BytesTransferred) * 1000) div ElapsedTime;
   BytesTransferred:= 0;
  end;

 if (FInitialized) then SockReceive();
end;

//---------------------------------------------------------------------------
initialization
 NetCom:= TNetCom.Create();

//---------------------------------------------------------------------------
finalization
 FreeAndNil(NetCom);

//---------------------------------------------------------------------------
end.
