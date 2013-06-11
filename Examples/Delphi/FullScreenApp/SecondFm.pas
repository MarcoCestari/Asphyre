unit SecondFm;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs;

//---------------------------------------------------------------------------
type
  TSecondForm = class(TForm)
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

//---------------------------------------------------------------------------
var
  SecondForm: TSecondForm;

//---------------------------------------------------------------------------
implementation
{$R *.dfm}

//---------------------------------------------------------------------------
uses
 Asphyre.Math, Asphyre.Devices, GameTypes, MainFm;

//---------------------------------------------------------------------------
procedure TSecondForm.FormResize(Sender: TObject);
begin
 SecondarySize:= Point2px(ClientWidth, ClientHeight);

 if (Assigned(GameDevice))and(GameDevice.State = adsActive) then
  GameDevice.Resize(1, SecondarySize);
end;

//---------------------------------------------------------------------------
procedure TSecondForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if (Assigned(MainForm))and(MainForm.Visible) then
  MainForm.Close();
end;

//---------------------------------------------------------------------------
end.
