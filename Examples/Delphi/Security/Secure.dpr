program Secure;

uses
  Forms,
  MainFm in 'MainFm.pas' {MainForm},
  GameTypes in 'GameTypes.pas',
  GameAuth in 'GameAuth.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
