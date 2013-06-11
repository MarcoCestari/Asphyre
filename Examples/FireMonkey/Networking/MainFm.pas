unit MainFm;
//---------------------------------------------------------------------------
// Asphyre networking example (FireMonkey).
// Shows how to send simple messages by using Asphyre's TNetCom.
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
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.Edit, FMX.Layouts, FMX.Memo,
  FMX.StdCtrls;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    IncomingGroupBox: TGroupBox;
    IncomingMemo: TMemo;
    SendGroupBox: TGroupBox;
    DestHostEdit: TEdit;
    Label1: TLabel;
    DestPortEdit: TEdit;
    Label2: TLabel;
    TextEdit: TEdit;
    SendButton: TButton;
    Label3: TLabel;
    StatusBar: TStatusBar;
    StatusLabel1: TLabel;
    StatusLabel2: TLabel;
    SysTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SendButtonClick(Sender: TObject);
    procedure SysTimerTimer(Sender: TObject);
  private
    { Private declarations }
    InputStream : TMemoryStream;
    OutputStream: TMemoryStream;

    procedure OnReceiveData(Sender: TObject; const Host: string; Port: Integer;
     Data: Pointer; Size: Integer);
  public
    { Public declarations }
  end;

//---------------------------------------------------------------------------
var
  MainForm: TMainForm;

//---------------------------------------------------------------------------
implementation
{$R *.fmx}

//---------------------------------------------------------------------------
uses
 Asphyre.Streams, Asphyre.NetComs.Types, Asphyre.NetComs;

//---------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
 // The following streams will be used to send/receive network data.
 InputStream := TMemoryStream.Create();
 OutputStream:= TMemoryStream.Create();

 // Specify the event that is going to handle data reception.
 NetCom.OnReceive:= OnReceiveData;

 // Specify the local port.
 NetCom.LocalPort:= 7500;

 // Try to initialize NetCom using the specified local port.
 if (not NetCom.Initialize()) then
  begin
   // If the initialization failed, try initializing using any possible port.
   NetCom.LocalPort:= 0;

   // Still failed, there is nothing else to do.
   if (not NetCom.Initialize()) then
    begin
     ShowMessage('Failed initializing NetCom.');
     Exit;
    end;
  end;

 StatusLabel1.Text:= 'Local IP: ' + GetLocalIP();
 StatusLabel2.Text:= 'Local Port: ' + IntToStr(NetCom.LocalPort);
end;

//---------------------------------------------------------------------------
procedure TMainForm.FormDestroy(Sender: TObject);
begin
 NetCom.Finalize();

 FreeAndNil(OutputStream);
 FreeAndNil(InputStream);
end;

//---------------------------------------------------------------------------
procedure TMainForm.OnReceiveData(Sender: TObject; const Host: string;
 Port: Integer; Data: Pointer; Size: Integer);
var
 Text: string;
begin
 // Put the incoming data into our input stream.
 InputStream.Clear();
 InputStream.WriteBuffer(Data^, Size);

 // Start reading from the beginning.
 InputStream.Seek(0, soFromBeginning);

 // Read the UTF-8 string from the stream.
 Text:= StreamGetUtf8String(InputStream);

 // You can use other Get[whatever] methods from StreamUtils.pas to get other
 // kind of data from the stream, like integers, floats and so on. Just make
 // sure that the order is exactly the same as when it was sent (see below).

 // Show the resulting text in the memo.
 IncomingMemo.Lines.Add('Received "' + Text + '" from ' + Host + ':' +
  IntToStr(Port));
end;

//---------------------------------------------------------------------------
procedure TMainForm.SendButtonClick(Sender: TObject);
var
 DestHost: string;
 DestPort: Integer;
begin
 // Retreive the destination host and port.
 DestHost:= DestHostEdit.Text;
 DestPort:= StrToIntDef(DestPortEdit.Text, -1);

 // Start with a fresh data stream.
 OutputStream.Clear();

 // Put the message text into the stream as UTF-8 string.
 StreamPutUTF8String(OutputStream, TextEdit.Text);

 // You can use other Put[whatever] methods from StreamUtils.pas to put other
 // kind of data into the stream, like integers, floats and so on.

 // Send the data from our stream.
 NetCom.Send(DestHost, DestPort, OutputStream.Memory, OutputStream.Size);
end;

//---------------------------------------------------------------------------
procedure TMainForm.SysTimerTimer(Sender: TObject);
begin
 NetCom.Update();
end;

//---------------------------------------------------------------------------
end.
