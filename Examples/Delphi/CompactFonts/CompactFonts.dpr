program CompactFonts;

uses
  Vcl.Forms,
  MainFm in 'MainFm.pas' {MainForm},
  GameTypes in 'GameTypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
