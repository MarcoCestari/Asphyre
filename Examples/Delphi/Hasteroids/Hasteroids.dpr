program Hasteroids;

uses
  Forms,
  MainFm in 'MainFm.pas' {MainForm},
  HAObjects in 'HAObjects.pas',
  dynamic_bass in 'dynamic_bass.pas',
  StartFm in 'StartFm.pas' {StartForm},
  HAScores in 'HAScores.pas',
  HATypes in 'HATypes.pas',
  AObjects in 'AObjects.pas',
  AParticles in 'AParticles.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
