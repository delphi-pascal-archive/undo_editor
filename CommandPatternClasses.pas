unit CommandPatternClasses;

interface

uses
  Classes, SysUtils, Contnrs, Controls, Dialogs, DateUtils;

type
  //The TCommand class wraps the functionality of executing a simple command
  //It is based on the Command design pattern by the gang of four, but allows
  //the ability to undo a command
  TCommandClass = class of TCommand;
  TCommand = class
  protected
    FCreationTime: TDateTime;
    function GetCreationTime: TDateTime; virtual;
  public
    property CreationTime: TDateTime read GetCreationTime;
    //Method for executing the command
    procedure Execute; virtual; abstract;
    //Method for the ability to undo an command
    procedure Undo; virtual; abstract;
    //The text that shows up in the undo list
    function ActionText: string; virtual; abstract;
    //Returns whether or not the command can be undone
    function CanUndo: Boolean; virtual; abstract;
    //Default Constructor that simply defines the execution time
    constructor Create; virtual;
  end;

  //The TCommandManager class manages the current list of commands
  //and provides the ability to perform multiple level undo and redo.
  //The class itself is instantiated with the number of undo level that can
  //be performed.
  TCommandList = class(TObjectList)
  private
    function GetCommand(Index: integer): TCommand;
  public
    property Commands[Index: integer]: TCommand read GetCommand; default;
  end;

  TCommandManagerClass = class of TCommandManager;
  TCommandManager = class
  protected
    //Hold the number of commands that are stored
    FMaxUndoLevels: integer;
    //Holds the list of commands and position to work out the
    //undo/redo list.
    FCommands: TCommandList;
    FCommandPosition: integer;
    //Event for Notification that an change has occurred.
    FUpdateEvent: TNotifyEvent;
    procedure UndoSingleLevel; virtual;
    procedure RedoSingleLevel; virtual;
    procedure SetMaxUndoLevels(const Value: integer);
  public
    //Constructor and Destructor
    constructor Create; virtual;
    destructor Destroy; override;
    //Functions for working out the position of the Undo/Redo facility
    function AddCommand(ACommand: TCommand; ExecuteCommand: boolean = false): boolean;
    procedure Undo(UndoLevels: integer = 1); virtual;
    procedure Redo(UndoLevels: integer = 1); virtual;
    function CanUndo: boolean; virtual;
    function CanRedo: boolean; virtual;
    function CommandPosition: integer; virtual;
    procedure ClearCommandList; virtual;
    //The function returns the list of Undo/Redo Commands and each item
    //will contain the TCommand object to execute.
    procedure GetUndoList(AList: TStrings); virtual;
    procedure GetRedoList(AList: TStrings); virtual;
    function GetNextUndoActionText: string; virtual;
    function GetNextRedoActionText: string; virtual;
    //Methods to control the number of commands that are stored
    property MaxUndoLevels: integer read FMaxUndoLevels write SetMaxUndoLevels;
    //This notifies some object that a change has occurred to the update list
    procedure NotifyOfUpdate; virtual;
    property OnUpdateEvent: TNotifyEvent read FUpdateEvent write FUpdateEvent;
  end;

  //TCompositeCommand is a class that is designed to be used for
  //similar commands that are related or to subclass for commands
  //that execute closely in time, so they should behave like
  //a single command
  TCompositeCommandClass = class of TCompositeCommand;
  TCompositeCommand = class(TCommand)
  protected
    FCommands: TCommandList;
    function GetCommand(Index: Integer): TCommand; virtual;
    function GetCreationTime: TDateTime; override;
  public
    //Methods of TCommand
    function CanUndo: Boolean; override;
    procedure Execute; override;
    procedure Undo; override;
    function ActionText: String; override;
    //Composite Classes
    procedure Add(ACommand: TCommand); virtual;
    procedure Remove(ACommand: TCommand); virtual;
    property Commands[Index: Integer]: TCommand read GetCommand;
    function Count: integer;
    //Method for determaning if a Command can be added to the composite
    function CanAdd(ACommand: TCommand): boolean; virtual;
    //Constructors and Destructors
    constructor Create; override;
    destructor Destroy; override;
  end;

  //Another useful aspect is automatically applying the composite
  //pattern to commands that execute within a period of time together
  //such as typing characters in a word processor.
  TCompositeCommandFactoryEntry = class
  public
    CommandClass: TCommandClass;
    CompositeCommandClass: TCompositeCommandClass;
    TimeDifferenceInMilliSeconds: integer;
  end;

  TCompositeCommandFactoryEntryList = class(TObjectList)
  private
    function GetEntry(Index: integer): TCompositeCommandFactoryEntry;
  public
    property Entries[Index: integer]: TCompositeCommandFactoryEntry read GetEntry; default;
  end;

  TCompositeCommandFactoryClass = class of TCompositeCommandFactory;
  TCompositeCommandFactory = class
  protected
    entryList: TCompositeCommandFactoryEntryList;
  public
    //Register the Automatic Handling of Composite Commands
    procedure RegisterAutomaticCompositeCommand(ACommandClass: TCommandClass;
      ACompositeCommandClass: TCompositeCommandClass;
      ATimeDifferenceInMilliSeconds: integer);
    //Return if a Command should be automatically grouped. Return
    //the CompositeClass for yes, or nil for no.
    function ShouldAutoComposite(ACommandClass: TCommandClass;
      ATimeDifferenceInMilliSeconds: integer): TCompositeCommandClass;
    //Constructors and Destructors
    constructor Create;
    destructor Destroy; override;
  end;

//The Singleton function to manage the Command class
function CommandManager: TCommandManager;
//Function for Registering TCommandManager descndants
procedure RegisterCommandManagerClass(AClass: TCommandManagerClass);

//Singleton function for the TCompositeCommandFactory class
function CompositeCommandFactory: TCompositeCommandFactory;
//Function for Registering TCompositeCommandFactory descendants
procedure RegisterCompositeCommandFactoryClass(AClass: TCompositeCommandFactoryClass);

implementation

{ TCommand }

constructor TCommand.Create;
begin
  FCreationTime := Now;
end;

function TCommand.GetCreationTime: TDateTime;
begin
  Result := FCreationTime;
end;

{ TCommandList }

function TCommandList.GetCommand(Index: integer): TCommand;
begin
  Result := Items[Index] as TCommand;
end;

{ TCommandManager }

var
  __CommandManager: TCommandManager = nil;
  __CommandManagerClass: TCommandManagerClass = TCommandManager;

function CommandManager: TCommandManager;
begin
  if __CommandManager = nil then
    __CommandManager := __CommandManagerClass.Create;

  Result := __CommandManager;
end;

procedure RegisterCommandManagerClass(AClass: TCommandManagerClass);
begin
  __CommandManagerClass := AClass;
end;

function TCommandManager.AddCommand(ACommand: TCommand;
  ExecuteCommand: boolean = false): boolean;
var
  i: integer;
  ClearListAfter: boolean;
  PossibleCompositeClass: TCompositeCommandClass;
  CompositeCommand: TCompositeCommand;
begin
  Result := false;
  ClearListAfter := false;
  //Adds a command to the list. The usual syntax to call this is
  //CommandManager.AddCommand(TConcreteCommand.Create(SomeParams));
  if ExecuteCommand then
    if not ACommand.CanUndo then
    begin
      if MessageDlg('Executing '+ AnsiQuotedStr(ACommand.ActionText, '''') +
        'cannot be undone. Are you sure you want to execute this command?',
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
          ACommand.Execute;
          ClearListAfter := true;
        end
      else begin
        //The command will not be added. We should free the command
        //and the next time the command is executed it should be dynamically
        //created.
        ACommand.Free;
        Exit;
      end;
    end else
      ACommand.Execute;

  //When a new command is executes, it removes the ability for the other
  //commands to be redone.
  for i := FCommands.Count - 1 downto FCommandPosition do
    FCommands.Delete(i);

  //Add the command to the list
  //We will see if the command should take advantage of the automatic composite

  PossibleCompositeClass := nil;
  if (FCommands.Count > 0) and (not CanRedo) then
    PossibleCompositeClass := CompositeCommandFactory.ShouldAutoComposite(TCommandClass(ACommand.ClassType),
      millisecondsbetween(ACommand.CreationTime, FCommands[FCommandPosition-1].CreationTime));

  if PossibleCompositeClass <> nil then
  begin
    //We need to create a composite component and add that instead
    //If the last command is already a composite then we add to that
    //composite, otherwise we add the two command together in a new
    //composite group
    if FCommands[FCommandPosition-1] is PossibleCompositeClass then
    begin
      if TCompositeCommand(FCommands[FCommandPosition-1]).CanAdd(ACommand) then
        (FCommands[FCommandPosition-1] as PossibleCompositeClass).Add(ACommand)
      else
        FCommands.Add(ACommand);
    end else begin
      //Create the new Composite
      CompositeCommand := PossibleCompositeClass.Create;
      CompositeCommand.Add(FCommands[FCommandPosition-1]);
      CompositeCommand.Add(ACommand);
      //Delete the reference to the command that we have added to
      //the composite command. I am using the extract method, so the
      //command reference is not deleted.
      FCommands.Extract(FCommands[FCommandPosition-1]);

      //Add the new composite command
      FCommands.Add(CompositeCommand);
    end;
  end else begin
    FCommands.Add(ACommand);
  end;

  //Make sure that the number of commands does not exceed FUndoLevels
  if FCommands.Count > FMaxUndoLevels then
    FCommands.Delete(0);

  //Set the new cursor position
  FCommandPosition := FCommands.Count;

  //we clear the list after when the command cannot be undone.
  if ClearListAfter then
    ClearCommandList
  else begin
    //Update the component(s) that want to recieve notification.
    NotifyOfUpdate;
  end;

  Result := true;
end;

function TCommandManager.CanRedo: boolean;
begin
  Result := FCommandPosition < FCommands.Count;
end;

function TCommandManager.CanUndo: boolean;
begin
  Result := FCommandPosition > 0;
end;

procedure TCommandManager.ClearCommandList;
begin
  //Clear the list of commands from the list
  FCommandPosition := 0;
  FCommands.Clear;

  //Update the component(s) that want to recieve notification.
  NotifyOfUpdate;
end;

function TCommandManager.CommandPosition: integer;
begin
  Result := FCommandPosition;
end;

constructor TCommandManager.Create;
begin
  FCommands := TCommandList.Create(true);
  FCommandPosition := 0;
  FMaxUndoLevels := 25;
end;

destructor TCommandManager.Destroy;
begin
  FCommands.Free;
  FCommands := nil;

  inherited;
end;

function TCommandManager.GetNextRedoActionText: string;
begin
  //Returns the Action Text of the next redo item
  if FCommandPosition in [0..FCommands.Count-1] then
    Result := FCommands[FCommandPosition].ActionText
  else
    Result := '';
end;

function TCommandManager.GetNextUndoActionText: string;
begin
  //Returns the Action Text of the next undo item
  if (FCommandPosition - 1) in [0..FCommands.Count-1] then
    Result := FCommands[FCommandPosition-1].ActionText
  else
    Result := '';
end;

procedure TCommandManager.GetRedoList(AList: TStrings);
var
  i: integer;
begin
  //The Redo List is the list of commands above the current
  //command list position
  AList.Clear;
  for i := FCommandPosition to FCommands.Count - 1 do
    AList.Add(FCommands[i].ActionText);
end;

procedure TCommandManager.GetUndoList(AList: TStrings);
var
  i: integer;
begin
  //The Undo List is the list of commands below the current
  //command list position
  AList.Clear;
  for i := FCommandPosition-1 downto 0 do
    AList.Add(FCommands[i].ActionText);
end;

procedure TCommandManager.NotifyOfUpdate;
begin
  //Send the update to the component interested in listing to it.
  if Assigned(OnUpdateEvent) then
    OnUpdateEvent(Self);
end;

procedure TCommandManager.Redo(UndoLevels: integer = 1);
var
  counter: integer;
begin
  //Redo the commands
  for counter := 1 to UndoLevels do
    RedoSingleLevel;

  //Update the component(s) that want to recieve notification.
  NotifyOfUpdate;
end;

procedure TCommandManager.RedoSingleLevel;
begin
  //Redo the command from the command list
  if FCommandPosition < FCommands.Count then
  begin
    //We can redo this action
    //Lets redo it
    FCommandPosition := FCommandPosition + 1;
    FCommands[FCommandPosition-1].Execute;
  end;
end;

procedure TCommandManager.SetMaxUndoLevels(const Value: integer);
begin
  FMaxUndoLevels := Value;

  //When the new max undo levels are set clear the commands
  ClearCommandList;
end;

procedure TCommandManager.Undo(UndoLevels: integer = 1);
var
  counter: integer;
begin
  //Undo the commands
  for counter := 1 to UndoLevels do
    UndoSingleLevel;

  //Update the component(s) that want to recieve notification.
  NotifyOfUpdate;
end;

procedure TCommandManager.UndoSingleLevel;
begin
  //Undo a single command
  if FCommandPosition > 0 then
  begin
    //We can undo this action
    //Lets undo it
    FCommands[FCommandPosition-1].Undo;
    FCommandPosition := FCommandPosition - 1;
  end;
end;

{ TCompositeCommand }

function TCompositeCommand.ActionText: String;
begin
  //This method should be overrided by TCompositeCommand descendants
  //so that they can define the text that is actually returned.
  if Count = 1 then
    Result := Commands[0].ActionText
  else
    Result := 'Group of Commands';
end;

procedure TCompositeCommand.Add(ACommand: TCommand);
begin
  FCommands.Add(ACommand);
end;

function TCompositeCommand.CanAdd(ACommand: TCommand): boolean;
begin
  //Subclasses should override this to provide default
  //behaviour for their specific classes. For
  //example, a Composite that deals only with edits
  //should check that the edit controls that are
  //being edited are the same.
  Result := true;
end;

function TCompositeCommand.CanUndo: Boolean;
var
  counter: integer;
begin
  Result := true;
  for counter := 0 to FCommands.Count - 1 do
  begin
    Result := Result and Commands[counter].CanUndo;
    if not Result then
      break;
  end;
end;

function TCompositeCommand.Count: integer;
begin
  Result := FCommands.Count;
end;

constructor TCompositeCommand.Create;
begin
  inherited;
  
  FCommands := TCommandList.Create;
end;

destructor TCompositeCommand.Destroy;
begin
  FCommands.Free;

  inherited;
end;

procedure TCompositeCommand.Execute;
var
  counter: integer;
begin
  //Execute the Commands in the order they were given
  for counter := 0 to FCommands.Count - 1 do
    Commands[counter].Execute;
end;

function TCompositeCommand.GetCommand(Index: Integer): TCommand;
begin
  Result := FCommands[Index];
end;

function TCompositeCommand.GetCreationTime: TDateTime;
begin
  //When returning the creation time of a composite,
  //we return the creation time of the last command
  //that was added to the composite list.
  if FCommands.Count = 0 then
    Result := inherited GetCreationTime
  else
    Result := FCommands[FCommands.Count-1].CreationTime;
end;

procedure TCompositeCommand.Remove(ACommand: TCommand);
begin
  FCommands.Remove(ACommand);
end;

procedure TCompositeCommand.Undo;
var
  counter: integer;
begin
  //Undo the Commands in the reverse order they were added
  for counter := FCommands.Count - 1 downto 0 do
    Commands[counter].Undo;
end;

{ TCompositeCommandFactoryEntryList }

function TCompositeCommandFactoryEntryList.GetEntry(
  Index: integer): TCompositeCommandFactoryEntry;
begin
  Result := inherited Items[Index] as TCompositeCommandFactoryEntry;
end;

{ TCompositeCommandFactory Singleton Functions and declarations }

var
  __CompositeCommandFactory: TCompositeCommandFactory = nil;
  __CompositeCommandFactoryClass: TCompositeCommandFactoryClass = TCompositeCommandFactory;

function CompositeCommandFactory: TCompositeCommandFactory;
begin
  if __CompositeCommandFactory = nil then
    __CompositeCommandFactory := __CompositeCommandFactoryClass.Create;

  Result := __CompositeCommandFactory;
end;

procedure RegisterCompositeCommandFactoryClass(AClass: TCompositeCommandFactoryClass);
begin
  __CompositeCommandFactoryClass := AClass;
end;

{ TCompositeCommandFactory }

constructor TCompositeCommandFactory.Create;
begin
  entryList := TCompositeCommandFactoryEntryList.Create(true);
end;

destructor TCompositeCommandFactory.Destroy;
begin
  entryList.Free;

  inherited;
end;

procedure TCompositeCommandFactory.RegisterAutomaticCompositeCommand(
  ACommandClass: TCommandClass;
  ACompositeCommandClass: TCompositeCommandClass;
  ATimeDifferenceInMilliSeconds: integer);
var
  entry: TCompositeCommandFactoryEntry;
begin
  entry := TCompositeCommandFactoryEntry.Create;
  entry.CommandClass := ACommandClass;
  entry.CompositeCommandClass := ACompositeCommandClass;
  entry.TimeDifferenceInMilliSeconds := ATimeDifferenceInMilliSeconds;

  //Add the entry into the factory
  entryList.Add(entry);
end;

function TCompositeCommandFactory.ShouldAutoComposite(
  ACommandClass: TCommandClass;
  ATimeDifferenceInMilliSeconds: integer): TCompositeCommandClass;
var
  counter: integer;
  entry: TCompositeCommandFactoryEntry;
begin
  Result := nil;
  for counter := 0 to entryList.Count - 1 do
  begin
    entry := entryList[counter];
    if (ACommandClass.InheritsFrom(entry.CommandClass)) or
       (ACommandClass = entry.CommandClass) then
    begin
      //We have a match for the classes. Lets see the time.
      if not (ATimeDifferenceInMilliSeconds > entry.TimeDifferenceInMilliSeconds) then
        Result := entry.CompositeCommandClass;
    end;
  end;
end;

end.
