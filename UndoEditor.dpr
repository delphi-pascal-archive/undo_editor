program UndoEditor;

uses
  Forms,
  unitMainForm in 'unitMainForm.pas' {frmContactInfo},
  CommandPatternClasses in 'CommandPatternClasses.pas',
  EditTypingCommand in 'EditTypingCommand.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmContactInfo, frmContactInfo);
  Application.Run;
end.
