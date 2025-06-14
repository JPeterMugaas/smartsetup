
unit BBYaml;
{$i ../tmscommon.inc}

// This is *not* a YAML parser. Not even near.
// When investigating the best format to store our configuration files,
// we settled in YAML: It has a nice syntax (different from xml), it can have
// comments (different from JSON), and it handles multiple levels of hierarchy (different from ini)
// But there doesn't seem to exist a YAML parser in
// pure pascal, and we don't want to add dependencies to a C library, so this can compile anywhere.
// On the other side, we don't need to support all the YAML features, we basically need to store properties in hierarchies.
// So we created this "Bare-Bones" YAML parser, which doesn't actually try to parse YAML,
// but something similar enough so you can use YAML syntax highlighting
// in text editors. It is enough for our needs, but I wouldn't use as a general YAML parser unless you can control the format.

interface
uses BBClasses;
type

TBBYamlReader = class
  private
    class function CountSpaces(const Line: string): integer;
    class function UnescapeLine(const Line: string): string; static;
  public
    class procedure ProcessFile(const FileName: string; const MainSection: TSection; const aStopAt: string; const aIgnoreOtherFiles: boolean);
end;


implementation
uses Classes, SysUtils, Generics.Collections;

{ TNotLockingStreamReader }

type
  TNotLockingStreamReader = class(TStreamReader)
  public
    constructor Create(const FileName: string);
  end;

constructor TNotLockingStreamReader.Create(const FileName: string);
begin
  var TmpStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    inherited Create(TmpStream, TEncoding.UTF8);
  except
     TmpStream.Free;
     raise;
  end;

  OwnStream;
end;

{ TFileErrorInfo }
type
TFileErrorInfo = class(TErrorInfo)
  private
    FFileName: string;
    FLineNumber: integer;
  public
  property FileName: string read FFileName write FFileName;
  property LineNumber: integer read FLineNumber write FLineNumber;

  function ToString: string; override;
end;

{ TBBYamlProcessor }
TBBYamlSectionProcessor = class
private
  ErrorInfo: TFileErrorInfo;
  Levels: TStack<integer>;
  Aborted: boolean;
  StopAt: string;

  function ChangeSection(const Section: TSection; const Line: string; const Level: integer): TSection;

  function SectionIsContainer(const Section: TSection; const childValue: string): boolean; virtual;

  procedure ProcessValue(const Section: TSection; const Line: string; const Level: integer);
  procedure ProcessArray(const Section: TSection; const Line, Name, Value: string);

  function RemoveArray(const name: string): string;
  procedure ParseColon(const Line: string; var Name, Value: string; const MustHaveValue, CanBeEmpty: boolean);

public
  constructor Create(const FileName: string; const aStopAt: string; const aIgnoreOtherFiles: boolean);
  destructor Destroy; override;
  function Process(const Section: TSection; const Line: string; const Level: integer): TSection;
  procedure IncrementLineNumber;

end;

constructor TBBYamlSectionProcessor.Create(const FileName: string; const aStopAt: string; const aIgnoreOtherFiles: boolean);
begin
  ErrorInfo := TFileErrorInfo.Create(aIgnoreOtherFiles);
  ErrorInfo.FileName := FileName;
  ErrorInfo.LineNumber := 0;
  Levels := TStack<integer>.Create;
  Levels.Push(-1);
  StopAt := aStopAt;

end;

destructor TBBYamlSectionProcessor.Destroy;
begin
  ErrorInfo.Free;
  Levels.Free;
  inherited;
end;

procedure TBBYamlSectionProcessor.IncrementLineNumber;
begin
  ErrorInfo.LineNumber := ErrorInfo.LineNumber + 1;
end;

function TBBYamlSectionProcessor.Process(const Section: TSection;
         const Line: string; const Level: integer): TSection;
begin
  if (Level <= Levels.Peek) or (SectionIsContainer(Section, Line)) then
  begin
    exit(ChangeSection(Section, Line, Level));
  end;

  ProcessValue(Section, Line, Level);
  if Aborted then exit(nil);

  Result := Section;
end;

procedure TBBYamlSectionProcessor.ProcessValue(const Section: TSection;
  const Line: string;
  const Level: integer);
var
  Name, Value: string;
  Action: TAction;
begin
  if Aborted then exit;

  Name := Line;
  Value := '';

  case Section.SectionValueTypes of
    TSectionValueTypes.Values:
      ParseColon(Line, Name, Value, true, true);

    TSectionValueTypes.Both:
      if Line.Contains(':') then ParseColon(Line, Name, Value, true, false);

  end;

  if (Assigned(Section.ArrayMainAction)) then
  begin
    ProcessArray(Section, Line, RemoveArray(Name), Value);
    if (StopAt <> '') and (Section.FullSectionName + ':' + RemoveArray(Name) = StopAt) then Aborted := true;
    exit;
  end;
  if Section.ContainsArrays then Name := RemoveArray(Name);

  if ((Section.Actions <> nil) and Section.Actions.TryGetValue(Name, Action)) then
  begin
    Action(Value, ErrorInfo);
  end
  else Section.ThrowInvalidTag(Name, ErrorInfo);

  if (StopAt <> '') and (Section.FullSectionName + ':' + Name = StopAt) then Aborted := true;

end;


procedure TBBYamlSectionProcessor.ProcessArray(const Section: TSection; const Line, Name, Value: string);
begin
  if (Section.Duplicated <> nil) then
  begin
    if (Section.Duplicated.ContainsKey(Name)) then raise Exception.Create('Duplicated item in section ' + Section.SectionName + ': "' + Name + '" is already defined. ' + ErrorInfo.ToString);
    Section.Duplicated.Add(Name, true);
  end;

  if Assigned(Section.ArrayMainAction) then Section.ArrayMainAction(Name, Value, ErrorInfo);
  if Section.ArrayActions <> nil then
  begin
    Section.GetArray(Value, Section.ArrayActions, nil, ErrorInfo);
  end;

end;

function TBBYamlSectionProcessor.RemoveArray(const name: string): string;
begin
  if not name.StartsWith('-') then raise Exception.Create('The name "' + name + '" is part of an array and must start with "-". ' + ErrorInfo.ToString);
  Result := name.Substring(1).Trim;
  if (Result = '') then raise Exception.Create('The name "' + name + '" is empty. It must be in the form "- value". ' + ErrorInfo.ToString);

end;

function TBBYamlSectionProcessor.SectionIsContainer(const Section: TSection; const childValue: string): boolean;
begin
  if (Section.Actions = nil) and (not Assigned(Section.ArrayMainAction)) then exit(true);
  if not childValue.EndsWith(':') then exit (false);

  if (Section.Actions <> nil) and (Section.Actions.ContainsKey(childValue.Substring(0, childValue.Length - 1))) then exit(false);

  Result := Section.ChildSections.Count > 0;
end;

function TBBYamlSectionProcessor.ChangeSection(const Section: TSection; const Line: string; const Level: integer): TSection;
var
  Name, Value: string;
begin
  Result := Section;
  var LevelDecreased := Level <= Levels.Peek;
  var LastLevel := -1;
  while Level <= Levels.Peek do
  begin
    LastLevel := Levels.Pop;
    Result := Result.Parent;
  end;

  if (LevelDecreased) and (Level <= Lastlevel) and (Level > Levels.Peek) and (not SectionIsContainer(Result, Section.RemoveDoubleSpaces(Line))) then
  begin
    //We are continuing an older section.
    ProcessValue(Result, Line, Level);
    exit;
  end;


  if (Level = Levels.Peek) then
  begin
    Levels.Pop;
    Result := Result.Parent;
  end;


  Levels.Push(Level);

  ParseColon(Line, Name, Value, false, false);
  if Result.ContainsArrays then Name := RemoveArray(Name);
  exit(Result.GotoChild(Name, ErrorInfo));
end;

procedure TBBYamlSectionProcessor.ParseColon(const Line: string; var Name, Value: string; const MustHaveValue: boolean; const CanBeEmpty: boolean);
var
  idx: integer;
begin
  idx := Line.IndexOf(':');
  if (idx < 0) then raise Exception.Create('The text "' + Line + '" needs a colon. ' + ErrorInfo.ToString);
  Name := TSection.RemoveDoubleSpaces(Line.Substring(0, idx).Trim());
  Value := Line.Substring(idx + 1).Trim();
  if CanBeEmpty then exit;

  if MustHaveValue and (Value = '') then raise Exception.Create('Empty value for tag "' + Name + '". It must be have a value. ' + ErrorInfo.ToString);
  if not MustHaveValue and (Value <> '') then raise Exception.Create('Invalid value: "' + Value + '" for tag "' + Name + '". It must be empty. ' + ErrorInfo.ToString);
end;


{ TBBYamlReader }

class function TBBYamlReader.CountSpaces(const Line: string): integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Line.Length do
  begin
    case Line[i] of
     ' ': inc(Result);
     #9: inc(Result, 4);
     else exit;
    end;

  end;

end;

class procedure TBBYamlReader.ProcessFile(const FileName: string;
  const MainSection: TSection; const aStopAt: string; const aIgnoreOtherFiles: boolean);
var
  Reader: TStreamReader;
  Line, FullLine: string;
  Section: TSection;
  Level: integer;
  SectionProcessor: TBBYamlSectionProcessor;
begin
    Section := MainSection;
    SectionProcessor := TBBYamlSectionProcessor.Create(FileName, aStopAt, aIgnoreOtherFiles);
    try
      Reader := TNotLockingStreamReader.Create(FileName);
      try
        while not Reader.EndOfStream do
        begin
          FullLine := Reader.ReadLine;
          SectionProcessor.IncrementLineNumber;
          Line := TBBYamlReader.UnescapeLine(FullLine).Trim();
          if Line = '' then continue;

          Level := CountSpaces(FullLine);
          Section := SectionProcessor.Process(Section, Line, Level);
          if Section = nil then exit;
          
        end;

      finally
        Reader.Free;
      end;
    finally
      SectionProcessor.Free;
    end;
end;

class function TBBYamlReader.UnescapeLine(const Line: string): string;
var
  idx: integer;
begin
  Result := Line.Trim();
  idx := 0;
  //The only escape allowed is ## for #
  while true do
  begin
    idx := Result.IndexOf('#', idx);
    if idx < 0 then exit;
    if idx + 1 >= Result.Length then exit (Result.Substring(0, Result.Length - 1));
    if Result[idx + 2] <> '#' then exit (Result.Substring(0, idx));
    Result := Result.Remove(Idx, 1);
    inc(Idx);
  end;
end;

{ TFileErrorInfo }

function TFileErrorInfo.ToString: string;
begin
  Result := 'In line ' + IntToStr(LineNumber) + ' of file "' + FileName + '"';
end;


end.
