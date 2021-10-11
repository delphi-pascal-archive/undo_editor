unit unitMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Menus, ImgList, ComCtrls;

type
  TfrmContactInfo = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Edit1: TMenuItem;
    Undo1: TMenuItem;
    Redo1: TMenuItem;
    ImageList1: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    edFirstName: TEdit;
    edLastName: TEdit;
    edPhone: TEdit;
    edFax: TEdit;
    edMobile: TEdit;
    edEmail: TEdit;
    edWebPage: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    procedure Exit1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Undo1Click(Sender: TObject);
    procedure Redo1Click(Sender: TObject);
    procedure ContactInfoKeyPress(Sender: TObject; var Key: Char);
  private
    function GetFocusLabelCaption(AEdit: TEdit): string;
    procedure CommandManagerChange(Sender: TObject);
  public
    { Public declarations }
  end;

var
  frmContactInfo: TfrmContactInfo;

implementation

uses CommandPatternClasses, EditTypingCommand;

{$R *.dfm}

procedure TfrmContactInfo.Exit1Click(Sender: TObject);
begin
  Close;  
end;

procedure TfrmContactInfo.CommandManagerChange(Sender: TObject);
begin
  Undo1.Enabled := CommandManager.CanUndo;
  Redo1.Enabled := CommandManager.CanRedo;

  Undo1.Caption := 'Undo '+CommandManager.GetNextUndoActionText;
  Redo1.Caption := 'Redo '+CommandManager.GetNextRedoActionText;
end;

procedure TfrmContactInfo.FormCreate(Sender: TObject);
begin
  CommandManager.OnUpdateEvent := CommandManagerChange;
end;

procedure TfrmContactInfo.Undo1Click(Sender: TObject);
begin
  CommandManager.Undo;
end;

procedure TfrmContactInfo.Redo1Click(Sender: TObject);
begin
  CommandManager.Redo;
end;

function TfrmContactInfo.GetFocusLabelCaption(AEdit: TEdit): string;
var
  counter: integer;
  ALabel: TLabel;
begin
  //This function loops through the Labels and returns the
  //caption of the label if is FocusControl property is set to the
  //edit. Otherwise, it returns nil.
  Result := '';
  for counter := 0 to ControlCount - 1 do
    if Controls[counter] is TLabel then
    begin
      ALabel := TLabel(Controls[counter]);
      if ALabel.FocusControl = AEdit then
      begin
        Result := ALabel.Caption;
        break;
      end;
    end;
end;

procedure TfrmContactInfo.ContactInfoKeyPress(Sender: TObject; var Key: Char);
begin
  //We will keep this simple and only allow alpha numerics
  if (Ord(Key) in [32..128]) or ((Key = #8) and (TEdit(Sender).Text <> '')) then
  begin
    CommandManager.AddCommand(TEditTypeCommand.Create(TEdit(Sender),
      GetFocusLabelCaption(TEdit(Sender)), Key), true);
    Key := #0;
  end;
end;

end.
