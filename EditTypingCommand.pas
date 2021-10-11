unit EditTypingCommand;

interface

uses
  SysUtils, Classes, StdCtrls, CommandPatternClasses;

type
  //Class to work with characterd being typed into an TEdit
  TEditTypeCommand = class(TCommand)
  protected
    FEdit: TEdit;
    FEditTitle: string;
    Character: Char;
    InsertedPosition: integer;
    FDeletedCharacter: Char;
  public
    function ActionText: String; override;
    function CanUndo: Boolean; override;
    procedure Execute; override;
    procedure Undo; override;
    constructor Create(AEdit: TEdit; AEditTitle: string; AChar: char); reintroduce;
  end;

  //Composite Command Class so that typing which is done quickly
  //can be grouped into one command
  TEditTypeCompositeCommand = class(TCompositeCommand)
  public
    function ActionText: String; override;
    function CanAdd(ACommand: TCommand): Boolean; override;
  end;

implementation

{ TEditTypeCommand }

function TEditTypeCommand.ActionText: String;
begin
  if Character <> #8 then
    Result := 'Type ' + Character + ' in ' + FEditTitle
  else begin
    if FDeletedCharacter = '' then
      Result := 'Delete Text in ' + FEditTitle
    else
      Result := 'Delete ' + AnsiQuotedStr(FDeletedCharacter, '"') +
        ' in ' + FEditTitle;
  end;
end;

function TEditTypeCommand.CanUndo: Boolean;
begin
  Result := true;
end;

constructor TEditTypeCommand.Create(AEdit: TEdit; AEditTitle: string; AChar: char);
begin
  inherited Create;
  
  FEdit := AEdit;
  FEditTitle := AEditTitle;
  Character := AChar;
  InsertedPosition := AEdit.SelStart;
end;

procedure TEditTypeCommand.Execute;
var
  s: string;
begin
  //Replace the selected text
  FEdit.SetFocus;
  case Character of
    #8: begin
          s := FEdit.Text;
          FDeletedCharacter := Copy(s, InsertedPosition, 1)[1];
          Delete(s, InsertedPosition, 1);
          FEdit.Text := s;
          FEdit.SelStart := InsertedPosition;
        end;
    else
        begin
          FEdit.SelStart := InsertedPosition;
          FEdit.SelLength := 0;
          FEdit.SelText := Character;
        end;
  end;
end;

procedure TEditTypeCommand.Undo;
begin
  //Replace the selected text
  //Remove the old text
  with FEdit do
  begin
    SelStart := InsertedPosition;
    if Character <> #8 then
    begin
      SelLength := 1;
      SelText := '';
    end else begin
      //Restore the old character
      SelText := FDeletedCharacter;
    end;
  end;
  FEdit.SetFocus;
end;

{ TEditTypeCompositeCommand }

function TEditTypeCompositeCommand.ActionText: String;
var
  counter: integer;
  txt: string;
  c: char;
begin
  //This method overrides the default Composite events by grouping
  //all the TEditTypeCommands so that the command shows the actual typing
  //that occurred.
  txt := '';
  for counter := 0 to FCommands.Count - 1 do
    if FCommands.Commands[counter] is TEditTypeCommand then
    begin
      c := TEditTypeCommand(FCommands.Commands[counter]).Character;
      if c <> #8 then
        txt := txt + c
      else
        Delete(txt, Length(txt), 1);
    end;

  Result := 'Type '+AnsiQuotedStr(txt, '"') + ' in ' +
    TEditTypeCommand(FCommands.Commands[0]).FEditTitle;
end;

function TEditTypeCompositeCommand.CanAdd(ACommand: TCommand): Boolean;
var
  firstCommand: TEditTypeCommand;
begin
  //Make sure the memo controls are the same, before adding
  if ACommand is TEditTypeCommand then
  begin
    if Count = 0 then
      Result := true
    else begin
      firstCommand := TEditTypeCommand(FCommands[0]);
      Result := (firstCommand.FEdit = TEditTypeCommand(ACommand).FEdit);
    end;
  end else
    Result := false;
end;

initialization
  CompositeCommandFactory.RegisterAutomaticCompositeCommand(TEditTypeCommand,
    TEditTypeCompositeCommand, 500);
end.
