program DYDownFMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {frmMain},
  SettingsForm in 'SettingsForm.pas' {frmSettings},
  ProjectConstants in 'ProjectConstants.pas',
  ConfigUnit in 'ConfigUnit.pas',
  ShellKnownPath in 'ShellKnownPath.pas',
  fOpen in 'fOpen.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmSettings, frmSettings);
  Application.Run;
end.
