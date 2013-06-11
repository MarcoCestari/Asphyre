program FullScreenApp;

uses
  Vcl.Forms,
  MainFm in 'MainFm.pas' {MainForm},
  GameTypes in 'GameTypes.pas',
  SecondFm in 'SecondFm.pas' {SecondForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
