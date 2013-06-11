program ImageASVF;

uses
  Forms,
  MainFm in 'MainFm.pas' {MainForm},
  pxfm in 'pxfm.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Image to ASVF example';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
