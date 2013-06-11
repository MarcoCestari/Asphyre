program BasicGUI;

uses
  FMX.Forms,
  MainFm in 'MainFm.pas' {MainForm: TForm3D},
  GameTypes in 'GameTypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
