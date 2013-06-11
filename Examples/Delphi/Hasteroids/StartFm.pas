unit StartFm;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons;

//---------------------------------------------------------------------------
type
  TStartForm = class(TForm)
    Image1: TImage;
    Bevel1: TBevel;
    GroupBox1: TGroupBox;
    NameEdit: TEdit;
    GroupBox2: TGroupBox;
    PlayButton: TBitBtn;
    CloseButton: TBitBtn;
    CheckBoxVSync: TCheckBox;
    DXComboBox: TComboBox;
  private
    { Private declarations }
    function GetPlayerName(): string;
    function GetVSync: Boolean;
  public
    { Public declarations }
    property VSync: Boolean read GetVSync;
    property PlayerName: string read GetPlayerName;
  end;

//---------------------------------------------------------------------------
var
  StartForm: TStartForm;

//---------------------------------------------------------------------------
implementation
{$R *.dfm}

//---------------------------------------------------------------------------
function TStartForm.GetVSync(): Boolean;
begin
 Result:= CheckBoxVSync.Checked;
end;

//---------------------------------------------------------------------------
function TStartForm.GetPlayerName(): string;
begin
 Result:= NameEdit.Text;
end;

//---------------------------------------------------------------------------
end.
