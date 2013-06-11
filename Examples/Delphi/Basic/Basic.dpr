program Basic;

uses
  Forms,
  MainFm in 'MainFm.pas' {MainForm},
  GameTypes in 'GameTypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
