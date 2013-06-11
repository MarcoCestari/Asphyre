unit MainFm;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs,
  FMX.StdCtrls, FMX.Edit, FMX.Layouts, FMX.Memo;

//---------------------------------------------------------------------------
type
  TMainForm = class(TForm)
    IncomingGroupBox: TGroupBox;
    IncomingMemo: TMemo;
    SendGroupBox: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    DestHostEdit: TEdit;
    DestPortEdit: TEdit;
    Label3: TLabel;
    TextEdit: TEdit;
    SendButton: TButton;
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
 StreamUtils, NetComTypes, NetComs;

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
     IncomingMemo.Lines.Add('Failed initializing NetCom.');
     Exit;
    end;
  end;

 IncomingMemo.Lines.Add('NetCom is active on port ' +
  IntToStr(NetCom.LocalPort));
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
 IncomingMemo.Repaint();
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
