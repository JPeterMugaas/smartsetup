unit UConfigDefinition;
{$i ../../tmssetup.inc}

interface
uses Generics.Defaults, Generics.Collections, Masks, UMultiLogger, UConfigKeys,
     UNaming, UNamingList, SysUtils, Deget.CoreTypes, SyncObjs, ULogger,
     UConfigFolders, UOSFileLinks, Megafolders.Definition, BBArrays;

type
  TSkipRegisteringOptions = (Packages, StartMenu, Help, WindowsPath, WebCore, Registry, FileLinks);
  TSkipRegisteringSet = set of TSkipRegisteringOptions;

const
  TSkipRegisteringName: array[TSkipRegisteringOptions] of string = (
  'packages', 'startmenu', 'help', 'windowspath', 'webcore', 'registry', 'filelinks'
  );

  TMSUrl = 'https://api.landgraf.dev/tms';
  GitHubUrl = 'https://github.com/tmssoftware/smartsetup-registry/archive/refs/heads/main.zip';

type

  TSkipRegistering = record
  private
    FOptions: TSkipRegisteringSet;
  public
    constructor Create(const AOptions: TSkipRegisteringSet);
    function Packages: boolean;
    function StartMenu: boolean;
    function Help: boolean;
    function WindowsPath: boolean;
    function WebCore: boolean;
    function FileLinks: boolean;
    function Registry: boolean;

    class function All: TSkipRegistering; static;
    class function None: TSkipRegistering; static;
  end;

  TGlobalPrefixedProperties =(ExcludedProducts, IncludedProducts, AdditionalProductsFolders,
                             Servers, DcuMegafolders);
  TGlobalPrefixedPropertiesArray = Array[TGlobalPrefixedProperties] of TArrayOverrideBehavior;

  TProductPrefixedProperties =(DelphiVersions, Platforms, Defines);
  TProductPrefixedPropertiesArray = Array[TProductPrefixedProperties] of TArrayOverrideBehavior;


  TProductConfigDefinition = class
  private
    FProductId: string;
    StringProperties: TDictionary<string, string>;
    BoolProperties: TDictionary<string, boolean>;
    IntProperties: TDictionary<string, integer>;
    FPlatforms: TPlatformSet;
    FPlatformsModified: Boolean;
    FIdeNames: TIDENameSet;
    FIdeNamesModified: Boolean;
    FDefines: TDictionary<string, boolean>;
    FCreatedBy: String;
    FPrefixedProperties: TProductPrefixedPropertiesArray;
    function GetPrefixedProperties(
      index: TProductPrefixedProperties): TArrayOverrideBehavior;
    procedure SetPrefixedProperties(index: TProductPrefixedProperties;
      const Value: TArrayOverrideBehavior);

  public
    constructor Create(const aProductId: string);
    destructor Destroy; override;

    procedure SetBool(const v: string; const i: boolean);
    procedure SetInt(const v: string; const i: integer);
    procedure SetString(const v: string; const i: string);

    function GetInt(const v: string; const DefaultValue: integer): integer;
    function GetBool(const v: string; const DefaultValue: boolean): boolean;
    function GetString(const v, DefaultValue: string): string;

    function HasBool(const v: string): boolean;
    function HasInt(const v: string): boolean;
    function HasString(const v: string): boolean;


    procedure SetIDEName(const dv: TIDEName; const Include: boolean);
    procedure SetPlatform(const dp: TPlatform; const Include: boolean);
    procedure ClearIDENames;
    procedure ClearPlatforms;
    function GetIDENames: TIDENameSet;
    function GetPlatforms: TPlatformSet;

    procedure AddDefine(const def: string; const LineInfo: string);
    procedure RemoveDefine(const def: string; const LineInfo: string);
    procedure ClearDefines;
    property ProductId: string read FProductId;

    property Defines: TDictionary<string, boolean> read FDefines;

    function ListDefines: string;
    property CreatedBy: string read FCreatedBy write FCreatedBy;

    property PrefixedProperties[index: TProductPrefixedProperties]: TArrayOverrideBehavior read GetPrefixedProperties write SetPrefixedProperties;

  end;

  TGitConfig = record
  public
    GitCommand: string;
    Clone: string;
    Pull: string;
  end;

  TSvnConfig = record
  public
    SvnCommand: string;
    Checkout: string;
    Update: string;
  end;

  TServerType = (Api, ZipFile);

  TServerConfig = record
  public
  const
    BuiltinServers: array[0..1] of string = ('tms', 'community');
  public
    Name: string;
    ServerType: TServerType;
    Url: string;
    Enabled: boolean;

    constructor Create(const aName: string; const aServerType: TServerType; const aUrl: string; const aEnabled: boolean);
    constructor CreateInternalServer(const aName: string);
    function IsReservedName: boolean; overload;
    class function IsReservedName(const aName: string): boolean; overload; static;

    function ServerTypeString: string;
    class function ServerTypeFromString(const value: string; const ExtraInfo: string = ''): TServerType; static;
  end;

  type
    TVarProc<T> = reference to procedure (var Arg1: T);

  TServerConfigList = class
  private
    Servers: TArray<TServerConfig>;
  public
    constructor Create;
    destructor Destroy; override;
    function EnsureServer(const aName: string): integer;
    procedure AddServer(const ServerConfig: TServerConfig);
    procedure ClearServers;
    procedure RemoveServer(const index: integer);
    function ServerCount: integer;
    function GetServer(const index: integer): TServerConfig;
    procedure SetInfo(const index: integer; const Action: TVarProc<TServerConfig>);

    //Will return -1 if not found
    function FindServer(const Name: string): integer;
  end;

  TProductConfigDefinitionDictionary = class(TObjectDictionary<string, TProductConfigDefinition>)
  public
    constructor Create;
    procedure BestMatch(const ProductId: string; const IfMatched: TFunc<TProductConfigDefinition, boolean>);
    procedure LoopOverAllMatches(const ProductId: string; const IfMatched: TProc<TProductConfigDefinition>);

  end;

  TConfigDefinition = class
  private
    FRootFolder: string;
    FProducts: TProductConfigDefinitionDictionary;
    ExcludedComponents, IncludedComponents: TDictionary<string, string>;
    AdditionalProductsFolders: TDictionary<string, string>;
    Namings: TNamingList;
    FBuildCores: integer;
    FPreventSleep: boolean;
    FErrorIfSkipped: boolean;
    FAlternateRegistryKey: string;
    FMaxVersionsPerProduct: integer;
    FServerConfig: TServerConfigList;
    FGitConfig: TGitConfig;
    FSvnConfig: TSvnConfig;
    FPrefixedProperties: TGlobalPrefixedPropertiesArray;
    FDcuMegafolders: TMegafolderList;

    function GetSingleSettingsThatNeedRecompile(const Product: TProductConfigDefinition): string;

    function ReadIntProperty(const ProductId: string; const PropKey: string; const DefaultValue: integer): integer;
    function ReadStringProperty(const ProductId: string; const PropKey: string; const DefaultValue: string): string;
    function Match(const IdWithMask: string;
      const Projects: TDictionary<string, boolean>): boolean;
    function AllIDEsIfEmpty(const aIDENames: TIDENameSet): TIDENameSet;
    function AllPlatformsIfEmpty(const aPlatforms: TPlatformSet): TPlatformSet;
    function GetPrefixedProperties(
      index: TGlobalPrefixedProperties): TArrayOverrideBehavior;
    procedure SetPrefixedProperties(index: TGlobalPrefixedProperties;
      const Value: TArrayOverrideBehavior);
  public
    constructor Create(const ARootFolder: string);
    destructor Destroy; override;
    function Folders: IBuildFolders;
//    property FullPath: string read FFullPath;

    function GetProduct(ProductId: string): TProductConfigDefinition;

    procedure AddExcludedComponent(const Name, ErrorInfo: string);
    procedure AddIncludedComponent(const Name, ErrorInfo: string);
    procedure ClearExcludedComponents;
    procedure ClearIncludedComponents;
    function GetExcludedComponents: TEnumerable<string>;
    function GetIncludedComponents: TEnumerable<string>;
    function GetExcludedComponentsCount: integer;
    function GetIncludedComponentsCount: integer;

    procedure AddAdditionalProductsFolder(const Name, ErrorInfo: string);
    procedure ClearAdditionalProductsFolders;
    function GetAdditionalProductsFolders: TEnumerable<string>;
    function GetAdditionalProductsFoldersCount: integer;
    function GetAllRootFolders: TArray<string>;

    function ReadBoolProperty(const ProductId: string; const PropKey: string; const DefaultValue: boolean): boolean;

    property BuildCores: integer read FBuildCores write FBuildCores;
    property PreventSleep: boolean read FPreventSleep write FPreventSleep;
    property AlternateRegistryKey: string read FAlternateRegistryKey write FAlternateRegistryKey;
    property MaxVersionsPerProduct: integer read FMaxVersionsPerProduct write FMaxVersionsPerProduct;

    property ServerConfig: TServerConfigList read FServerConfig write FServerConfig;

    property GitConfig: TGitConfig read FGitConfig write FGitConfig;
    property SvnConfig: TSvnConfig read FSvnConfig write FSvnConfig;

    property DcuMegafolders: TMegafolderList read FDcuMegafolders;

    property PrefixedProperties[index: TGlobalPrefixedProperties]: TArrayOverrideBehavior read GetPrefixedProperties write SetPrefixedProperties;

    property ErrorIfSkipped: boolean read FErrorIfSkipped write FErrorIfSkipped;

    property Products: TProductConfigDefinitionDictionary read FProducts;

    function Verbosity(const ProductId: String; DefaultVerbosity: TVerbosity): TVerbosity;
    function SkipRegistering(const ProductId: String; DefaultValue: integer): integer;
    function DryRun(const ProductId: String): boolean;
    function IsIncluded(const ProductId: String): boolean;
    function GetAllDefines(const ProductId: string): TArray<string>;
    function GetDefinesOnlyForProject(const ProductId: string): TArray<string>;

    function GetIDENames(const ProductId: string): TIDENameSet;
    function GetPlatforms(const dv: TIDEName; const ProductId: string): TPlatformSet;

    function CompilerPath(const ProductId: String; const dv: TIDEName): string;
    function CompilerParameters(const ProductId: String; const dv: TIDEName): string;

    function KeepParallelFolders(const ProductId: String): Boolean;
    function ModifySources(const ProductId: String): Boolean;
    function FileLinkType(const ProductId: String): TFileLinkType;
    function PartialBuilds(const ProductId: String): Boolean;

    function GetNaming(const NamingId: String; const ProjectFilename: string): TNaming;

    function GetSettingsThatNeedRecompile(const ProductId: string): string;

    procedure Validate(const Projects: TDictionary<string, boolean>);

    procedure EnsureAllProducts;
  end;

implementation
uses IOUtils, UTmsBuildSystemUtils;

{ TConfigDefinition }

constructor TConfigDefinition.Create(const ARootFolder: string);
begin
  FRootFolder := ARootFolder;
  FProducts := TProductConfigDefinitionDictionary.Create;
  ExcludedComponents := TDictionary<string, string>.Create;
  IncludedComponents := TDictionary<string, string>.Create;
  AdditionalProductsFolders := TDictionary<string, string>.Create;
  FServerConfig := TServerConfigList.Create;
  Namings := TNamingList.Create;
  FBuildCores := 0; // make it parallel by default
  FPreventSleep := true;
  FMaxVersionsPerProduct := -1;
  FErrorIfSkipped := false;
  FDcuMegafolders := TMegafolderList.Create;
end;

destructor TConfigDefinition.Destroy;
begin
  FDcuMegafolders.Free;
  Namings.Free;
  FServerConfig.Free;
  IncludedComponents.Free;
  ExcludedComponents.Free;
  AdditionalProductsFolders.Free;
  FProducts.Free;
  inherited;
end;

function TConfigDefinition.DryRun(const ProductId: String): boolean;
begin
  Result := ReadBoolProperty(ProductId, ConfigKeys.DryRun, false);
end;

procedure TConfigDefinition.EnsureAllProducts;
begin
  if Products.ContainsKey(GlobalProductId) then exit;
  Products.Add(GlobalProductId, TProductConfigDefinition.Create(GlobalProductId));
end;

function TConfigDefinition.Folders: IBuildFolders;
begin
  Result := TBuildFolders.Create(FRootFolder);
end;

function TConfigDefinition.AllIDEsIfEmpty(const aIDENames: TIDENameSet): TIDENameSet;
begin
  if AIDENames = [] then exit([Low(TIDEName)..High(TIDEName)]);
  Result := AIDENames;
end;

function TConfigDefinition.GetIDENames(const ProductId: string): TIDENameSet;
begin
  // behavior change: build for all IDEs if nothing is configured. Review this later, but this was changed to
  // allow using Smart Setup without any config file
  var ResultValue := AllIDEsIfEmpty([]);

  Products.BestMatch(ProductId, function(Product: TProductConfigDefinition): boolean
  begin
    if Product.FIdeNamesModified then
    begin
      ResultValue := AllIDEsIfEmpty(Product.FIdeNames); //we override the platform selection completely, it is more intuitive.
      exit(true);
    end;
    Result := false;
  end);
  Result := ResultValue;
end;

function TConfigDefinition.AllPlatformsIfEmpty(const aPlatforms: TPlatformSet): TPlatformSet;
begin
  if aPlatforms = [] then exit([Low(TPlatform)..High(TPlatform)]);
  Result := aPlatforms;
end;

function TConfigDefinition.GetPlatforms(
  const dv: TIDEName; const ProductId: string): TPlatformSet;
begin
  // behavior change: build for all platforms if nothing is configured. Review this later, but this was changed to
  // allow using Smart Setup without any config file
  var ResultValue := AllPlatformsIfEmpty([]);

  Products.BestMatch(ProductId, function(Product: TProductConfigDefinition): boolean
  begin
    if Product.FPlatformsModified then
    begin
      ResultValue := AllPlatformsIfEmpty(Product.FPlatforms); //we override the platform selection completely, it is more intuitive.
      exit(true);
    end;
    Result := false;
  end);

  Result := ResultValue;
end;

function TConfigDefinition.GetAllDefines(
  const ProductId: string): TArray<string>;
begin
  var Defines := THashSet<string>.Create;
  try
    Products.LoopOverAllMatches(ProductId, procedure(Product: TProductConfigDefinition)
      begin
        for var s in Product.Defines.Keys do
        begin
          if Product.Defines[s] then Defines.Add(s) else Defines.Remove(s);
        end;
      end);

    Result := Defines.ToArray;
    //We'll sort them to avoid returning always different values as this is a dictionary.
    TArray.Sort<string>(Result);
  finally
    Defines.Free;
  end;

end;

function TConfigDefinition.GetDefinesOnlyForProject(
  const ProductId: string): TArray<string>;
begin
  Result := nil;
  var Product: TProductConfigDefinition;
  if Products.TryGetValue(ProductId, Product) then
  begin
    SetLength(Result, Product.Defines.Count);
    var i := 0;
    for var s in Product.Defines.Keys do
    begin
      if (Product.Defines[s]) then
      begin
        Result[i] := s;
        inc(i);
      end;
    end;
    if i < Length(Result) then SetLength(Result, i);

  end;

  //We'll sort them to avoid returning always different values as this is a dictionary.
  if Result <> nil then TArray.Sort<string>(Result);
end;

procedure CheckSameDrive(First, Second, ErrorInfo: string);
begin
{$IFDEF MSWINDOWS}
    //The renaming trick that requires us to have all projects in the same drive only applies to Windows.
  var FirstDrive := ExtractFileDrive(First);
  var SecondDrive := ExtractFileDrive(Second);
  if not SameText(FirstDrive, SecondDrive) then raise Exception.Create('The additional products folder "' + Second
       + '" is in a different disk than the root folder.("' + First + '").'
       + 'TMS Smart setup requires all projects to be in the same physical drive.' + ErrorInfo);

{$ENDIF}
end;

function TConfigDefinition.GetAllRootFolders: TArray<string>;
begin
  if AdditionalProductsFolders.Keys.Count = 0 then //Optimization for most common case.
  begin
    Result := [Folders.RootFolder];
    exit;
  end;

  var ResultList := TList<string>.Create;
  try
    ResultList.Add(Folders.RootFolder);
    for var root in AdditionalProductsFolders do
    begin
      AddPathsWithWildcards(ResultList, TPath.GetFullPath(TPath.Combine(Folders.RootFolder, root.Key)), root.Value,
        CheckSameDrive);
    end;

    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;

function TConfigDefinition.GetPrefixedProperties(
  index: TGlobalPrefixedProperties): TArrayOverrideBehavior;
begin
  Result := FPrefixedProperties[index];
end;

function TConfigDefinition.GetNaming(const NamingId,
  ProjectFilename: string): TNaming;
begin
  Result := Namings.GetNaming(NamingId, Folders.RootFolder, ProjectFilename);
end;

function TConfigDefinition.GetProduct(
  ProductId: string): TProductConfigDefinition;
begin
  if (Products.TryGetValue(ProductId, Result)) then exit;
  Result := TProductConfigDefinition.Create(ProductId);
  Products.Add(ProductId, Result);
end;


function TConfigDefinition.GetSettingsThatNeedRecompile(
  const ProductId: string): string;
begin
  var ResultValue := AlternateRegistryKey;
  Products.LoopOverAllMatches(ProductId, procedure(Product: TProductConfigDefinition)
  begin
    ResultValue := ResultValue + '|' + GetSingleSettingsThatNeedRecompile(Product);
  end);
  Result := ResultValue;
end;

function TConfigDefinition.GetSingleSettingsThatNeedRecompile(
  const Product: TProductConfigDefinition): string;
begin
   Result := Product.ListDefines;
   var DebugDcus: boolean;
   // an optimization would be to not rebuild everything if debug dcus changed.
   // but it is complex to do, and changing between compiling with debug and without shouldn't be common.
   if not Product.BoolProperties.TryGetValue(ConfigKeys.DebugDcus, DebugDcus) then DebugDcus := false;
   Result := Result + '~' + BoolToStr(DebugDcus);

end;

function TConfigDefinition.IsIncluded(const ProductId: String): boolean;
begin
  for var ExcludedId in ExcludedComponents.Keys do
    if MatchesMask(ProductId, ExcludedId) then
      Exit(False);

  if IncludedComponents.Count = 0 then
    Exit(True);

  Result := False;
  for var IncludedId in IncludedComponents.Keys do
    if MatchesMask(ProductId, IncludedId) then
      Exit(True);
end;

procedure TConfigDefinition.ClearAdditionalProductsFolders;
begin
  AdditionalProductsFolders.Clear;
end;

procedure TConfigDefinition.ClearExcludedComponents;
begin
  ExcludedComponents.Clear;
end;

procedure TConfigDefinition.ClearIncludedComponents;
begin
  IncludedComponents.Clear;
end;

function TConfigDefinition.GetExcludedComponentsCount: integer;
begin
  Result := ExcludedComponents.Count;
end;

function TConfigDefinition.GetIncludedComponentsCount: integer;
begin
  Result := IncludedComponents.Count;
end;


function TConfigDefinition.CompilerPath(const ProductId: String; const dv: TIDEName): string;
begin
  Result := ReadStringProperty(ProductId, ConfigKeys.CompilerPath + IDEId[dv], '');
end;

function TConfigDefinition.KeepParallelFolders(const ProductId: String): Boolean;
begin
  Result := ReadBoolProperty(ProductId, ConfigKeys.KeepParallelFolders, false);
end;

function TConfigDefinition.FileLinkType(const ProductId: String): TFileLinkType;
begin
  var UseSymLinks := ReadBoolProperty(ProductId, ConfigKeys.SymLinks, false);
  if UseSymLinks then Result := TFileLinkType.SymLink else Result := TFileLinkType.HardLink;
  
end;


function TConfigDefinition.ModifySources(const ProductId: String): Boolean;
begin
  Result := ReadBoolProperty(ProductId, ConfigKeys.ModifySources, false);
end;

function TConfigDefinition.PartialBuilds(const ProductId: String): Boolean;
begin
  Result := ReadBoolProperty(ProductId, ConfigKeys.PartialBuilds, false);
end;

function TConfigDefinition.CompilerParameters(const ProductId: String; const dv: TIDEName): string;
begin
  Result := ReadStringProperty(ProductId, ConfigKeys.CompilerParameters + IDEId[dv], '');
end;

function TConfigDefinition.ReadBoolProperty(const ProductId, PropKey: string;
  const DefaultValue: boolean): boolean;
begin
  var ResultValue := DefaultValue;
  MonitorEnter(Products);
  try
    Products.BestMatch(ProductId, function(Product: TProductConfigDefinition): boolean
    begin
      var LocalResultValue: boolean;
      Result := Product.BoolProperties.TryGetValue(PropKey, LocalResultValue);
      if Result then ResultValue := LocalResultValue;

    end);
  finally
    MonitorExit(Products);
  end;

  Result := ResultValue;
end;

function TConfigDefinition.ReadIntProperty(const ProductId, PropKey: string;
  const DefaultValue: integer): integer;
begin
  var ResultValue := DefaultValue;
  MonitorEnter(Products);
  try
    Products.BestMatch(ProductId, function(Product: TProductConfigDefinition): boolean
    begin
      var LocalResultValue: integer;
      Result := Product.IntProperties.TryGetValue(PropKey, LocalResultValue);
      if Result then ResultValue := LocalResultValue;

    end);
  finally
    MonitorExit(Products);
  end;

  Result := ResultValue;
end;

function TConfigDefinition.ReadStringProperty(const ProductId, PropKey,
  DefaultValue: string): string;
begin
  var ResultValue := DefaultValue;
  MonitorEnter(Products);
  try
    Products.BestMatch(ProductId, function(Product: TProductConfigDefinition): boolean
    begin
      var LocalResultValue: string;
      Result := Product.StringProperties.TryGetValue(PropKey, LocalResultValue);
      if Result then ResultValue := LocalResultValue;
      
    end);
  finally
    MonitorExit(Products);
  end;

  Result := ResultValue;
end;

procedure TConfigDefinition.SetPrefixedProperties(index: TGlobalPrefixedProperties;
  const Value: TArrayOverrideBehavior);
begin
  FPrefixedProperties[index] := value;
end;

function TConfigDefinition.SkipRegistering(const ProductId: String;
  DefaultValue: integer): integer;
begin
  Result := ReadIntProperty(ProductId, ConfigKeys.SkipRegister, DefaultValue);
end;

function TConfigDefinition.Match(const IdWithMask: string; const Projects: TDictionary<string, boolean>): boolean;
begin
  for var p in Projects.Keys do if MatchesMask(p, IdWithMask) then exit(true);
  Result := false;
end;

procedure TConfigDefinition.Validate(const Projects: TDictionary<string, boolean>);
begin
  for var p in Products.Values do
  begin
    if p.ProductId = GlobalProductId then continue;

    if not Match(p.ProductId, Projects) then
    begin
      Logger.Info('WARNING: The project "' + p.ProductId
      + '" was not found. Verify there are no typos. ' + p.CreatedBy);
    end;
  end;

  for var p in IncludedComponents do
  begin
    if not Match(p.Key, Projects) then
    begin
      Logger.Info('WARNING: The project "' + p.Key
      + '" in the section "included products" was not found. Verify there are no typos. ' + p.Value);
    end;
  end;

  for var p in ExcludedComponents do
  begin
    if not Match(p.Key, Projects) then
    begin
      Logger.Info('WARNING: The project "' + p.Key
      + '" in the section "excluded products" was not found. Verify there are no typos. ' + p.Value);
    end;
  end;

end;

function TConfigDefinition.Verbosity(const ProductId: String; DefaultVerbosity: TVerbosity): TVerbosity;
begin
  Result := TVerbosity(ReadIntProperty(ProductId, ConfigKeys.Verbosity, Ord(DefaultVerbosity)));
end;

procedure TConfigDefinition.AddAdditionalProductsFolder(const Name,
  ErrorInfo: string);
begin
  AdditionalProductsFolders.AddOrSetValue(Name, ErrorInfo);
end;

function TConfigDefinition.GetAdditionalProductsFolders: TEnumerable<string>;
begin
  Result := AdditionalProductsFolders.Keys;
end;

function TConfigDefinition.GetAdditionalProductsFoldersCount: integer;
begin
  Result := AdditionalProductsFolders.Count;
end;

procedure TConfigDefinition.AddExcludedComponent(const Name, ErrorInfo: string);
begin
  ExcludedComponents.AddOrSetValue(Name, ErrorInfo);
end;

procedure TConfigDefinition.AddIncludedComponent(const Name, ErrorInfo: string);
begin
  IncludedComponents.AddOrSetValue(Name, ErrorInfo);
end;

function TConfigDefinition.GetExcludedComponents: TEnumerable<string>;
begin
  Result := ExcludedComponents.Keys;
end;

function TConfigDefinition.GetIncludedComponents: TEnumerable<string>;
begin
  Result := IncludedComponents.Keys;
end;

{ TProductConfigDefinitionDictionary }

constructor TProductConfigDefinitionDictionary.Create;
begin
  inherited Create([doOwnsValues]);
end;

procedure TProductConfigDefinitionDictionary.BestMatch(const ProductId: string;
  const IfMatched: TFunc<TProductConfigDefinition, boolean>);
begin
  var Product: TProductConfigDefinition;

  //Always first see if an exact match.
  if TryGetValue(ProductId, Product) then
  begin
    if IfMatched(Product) then exit;
  end;

  //If no exact match, try wildcards
  var PartialMatches := TList<string>.Create;
  try
    for var ProductKey in Keys do
    begin
      if MatchesMask(ProductId, ProductKey) and (ProductId <> ProductKey) then PartialMatches.Add(ProductKey);
    end;

    //Sort them by length descending. So tms.biz.* is evaluated before tms.* in case you have both.
    //This is not perfect, as you could have more complex wildcards and not necessarily the longest is the
    //preferred match, but there is no other good criteria either. In most cases this should work.
    var WildcardComparer: IComparer<string> := TDelegatedComparer<string>.Create(
      function(const Left, Right: string): integer
      begin
        if Left.Length < Right.Length then
          Result := 1
        else if Left.Length > Right.Length then
          Result := -1
        else
          Result := 0;
      end);
    PartialMatches.Sort(WildcardComparer);

    for var Matched in PartialMatches do
    begin
      if IfMatched(Self[Matched]) then exit;
    end;

  finally
    PartialMatches.Free;
  end;


  //Last, try global config.
  if TryGetValue(GlobalProductId, Product) then
  begin
    if IfMatched(Product) then exit;
  end;
end;

procedure TProductConfigDefinitionDictionary.LoopOverAllMatches(
  const ProductId: string; const IfMatched: TProc<TProductConfigDefinition>);
begin
  var ProductNames := Self.Keys.ToArray;
  //See comments in WildcardComparer for method BestMatch
  var WildcardComparer: IComparer<string> := TDelegatedComparer<string>.Create(
    function(const Left, Right: string): integer
    begin
      if Left = Right then exit(0);
      if Left = GlobalProductId then exit(-1);
      if Right = GlobalProductId then exit(1);
      if Left = ProductId then exit(1);
      if Right = ProductId then exit(-1);

      exit (Right.Length - Left.Length);
    end);


  TArray.Sort<string>(ProductNames, WildcardComparer);

  for var Product in ProductNames do
  begin
    if MatchesMask(ProductId, Product) or (Product = GlobalProductId) then IfMatched(Self[Product]);
  end;
end;

{ TProductConfigDefinition }

procedure TProductConfigDefinition.SetBool(const v: string; const i: boolean);
begin
  BoolProperties.AddOrSetValue(v, i);
end;

procedure TProductConfigDefinition.SetInt(const v: string; const i: integer);
begin
  IntProperties.AddOrSetValue(v, i);
end;

function TProductConfigDefinition.GetBool(const v: string; const DefaultValue: boolean): boolean;
begin
  if not BoolProperties.TryGetValue(v, Result) then exit(DefaultValue);
end;

function TProductConfigDefinition.GetInt(const v: string; const DefaultValue: integer): integer;
begin
  if not IntProperties.TryGetValue(v, Result) then exit(DefaultValue);
end;

function TProductConfigDefinition.GetString(const v: string; const DefaultValue: string): string;
begin
  if not StringProperties.TryGetValue(v, Result) then exit(DefaultValue);
end;

function TProductConfigDefinition.HasBool(const v: string): boolean;
begin
  Result := BoolProperties.ContainsKey(v);
end;

function TProductConfigDefinition.HasInt(const v: string): boolean;
begin
  Result := IntProperties.ContainsKey(v);
end;

function TProductConfigDefinition.HasString(const v: string): boolean;
begin
  Result := StringProperties.ContainsKey(v);
end;

procedure TProductConfigDefinition.SetIDEName(const dv: TIDEName;
  const Include: boolean);
begin
  if Include then
    FIdeNames := FIdeNames + [dv]
  else
    FIdeNames := FIdeNames - [dv];
  FIdeNamesModified := True;
end;

procedure TProductConfigDefinition.SetPlatform(const dp: TPlatform;
  const Include: boolean);
begin
  if Include then
    FPlatforms := FPlatforms + [dp]
  else
    FPlatforms := FPlatforms - [dp];
  FPlatformsModified := True;
end;

procedure TProductConfigDefinition.SetPrefixedProperties(
  index: TProductPrefixedProperties; const Value: TArrayOverrideBehavior);
begin
  FPrefixedProperties[index] := value;
end;

procedure TProductConfigDefinition.ClearDefines;
begin
  FDefines.Clear;
end;

procedure TProductConfigDefinition.ClearIDENames;
begin
  FIdeNames := [];
  FIdeNamesModified := True;
end;

procedure TProductConfigDefinition.ClearPlatforms;
begin
  FPlatforms := [];
  FPlatformsModified := True;
end;

function TProductConfigDefinition.GetIDENames: TIDENameSet;
begin
  Result := FIdeNames;
end;

function TProductConfigDefinition.GetPlatforms: TPlatformSet;
begin
  Result := FPlatforms;
end;


function TProductConfigDefinition.GetPrefixedProperties(
  index: TProductPrefixedProperties): TArrayOverrideBehavior;
begin
  Result := FPrefixedProperties[index];
end;

procedure TProductConfigDefinition.SetString(const v, i: string);
begin
  StringProperties.AddOrSetValue(v, i);
end;

procedure TProductConfigDefinition.AddDefine(const def, LineInfo: string);
begin
  Defines.Add(def, true);
end;

procedure TProductConfigDefinition.RemoveDefine(const def, LineInfo: string);
begin
  Defines.Add(def, false);
end;

constructor TProductConfigDefinition.Create(const aProductId: string);
begin
  inherited Create;
  FProductId := aProductId;
  StringProperties := TDictionary<string, string>.Create;
  BoolProperties := TDictionary<string, boolean>.Create;
  IntProperties := TDictionary<string, integer>.Create;
  FDefines := TDictionary<string, boolean>.Create;
end;

destructor TProductConfigDefinition.Destroy;
begin
  BoolProperties.Free;
  StringProperties.Free;
  IntProperties.Free;
  FDefines.Free;
  inherited;
end;

function TProductConfigDefinition.ListDefines: string;
begin
  var Defs := Defines.Keys.ToArray;
  TArray.Sort<string>(Defs);
  Result := String.Join(', ', Defs);
end;

{ TSkipRegistering }

constructor TSkipRegistering.Create(const AOptions: TSkipRegisteringSet);
begin
  FOptions := AOptions;
end;

function TSkipRegistering.Help: boolean;
begin
  Result := TSkipRegisteringOptions.Help in FOptions;
end;

function TSkipRegistering.Packages: boolean;
begin
  Result := TSkipRegisteringOptions.Packages in FOptions;
end;

function TSkipRegistering.StartMenu: boolean;
begin
  Result := TSkipRegisteringOptions.StartMenu in FOptions;
end;

function TSkipRegistering.WebCore: boolean;
begin
  Result := TSkipRegisteringOptions.WebCore in FOptions;
end;

function TSkipRegistering.WindowsPath: boolean;
begin
  Result := TSkipRegisteringOptions.WindowsPath in FOptions;
end;

function TSkipRegistering.Registry: boolean;
begin
  Result := TSkipRegisteringOptions.Registry in FOptions;
end;

function TSkipRegistering.FileLinks: boolean;
begin
  Result := TSkipRegisteringOptions.FileLinks in FOptions;
end;

class function TSkipRegistering.All: TSkipRegistering;
begin
  Result := TSkipRegistering.Create([Low(TSkipRegisteringOptions)..High(TSkipRegisteringOptions)]);
end;

class function TSkipRegistering.None: TSkipRegistering;
begin
  Result := TSkipRegistering.Create([]);
end;

{ TServerConfigList }

procedure TServerConfigList.AddServer(const ServerConfig: TServerConfig);
begin
  if FindServer(ServerConfig.Name) >= 0 then raise Exception.Create('The server ' + ServerConfig.Name + ' was already added');

  SetLength(Servers, Length(Servers) + 1);
  Servers[Length(Servers) - 1] := ServerConfig;
end;

procedure TServerConfigList.ClearServers;
begin
  SetLength(Servers, Length(TServerConfig.BuiltinServers));
end;

constructor TServerConfigList.Create;
begin
  SetLength(Servers, Length(TServerConfig.BuiltinServers));
  for var i := Low(TServerConfig.BuiltinServers) to High(TServerConfig.BuiltinServers) do
  begin
    Servers[i] := TServerConfig.CreateInternalServer(TServerConfig.BuiltinServers[i]);
  end;
end;

destructor TServerConfigList.Destroy;
begin
  inherited;
end;

function TServerConfigList.FindServer(const Name: string): integer;
begin
  for var i := 0 to ServerCount - 1 do
  begin
    var Server := GetServer(i);
    if SameText(Server.Name.Trim, Name.Trim) then exit(i);
  end;

  Result := -1;
end;

function TServerConfigList.GetServer(const index: integer): TServerConfig;
begin
  Result := Servers[index];
end;

function TServerConfigList.EnsureServer(const aName: string): integer;
begin
  Result := FindServer(aName);
  if Result >= 0 then exit;

  AddServer(TServerConfig.Create(aName, TServerType.ZipFile, '', true));
  Result := Length(Servers) - 1;
end;

procedure TServerConfigList.RemoveServer(const index: integer);
begin
  if index < Length(TServerConfig.BuiltinServers) then raise Exception.Create('Cannot remove a built-in server. Disable it instead.');

  for var i := index to Length(Servers) - 2 do
  begin
    Servers[i] := Servers[i + 1];
  end;
  SetLength(Servers, Length(Servers) - 1);
end;

function TServerConfigList.ServerCount: integer;
begin
  exit(Length(Servers));
end;

procedure TServerConfigList.SetInfo(const index: integer;
  const Action: TVarProc<TServerConfig>);
begin
  var Server := GetServer(index);
  Action(Server);
  Servers[index] := Server;
end;

{ TServerConfig }
constructor TServerConfig.CreateInternalServer(const aName: string);
begin
  if SameText(aName, 'tms') then
  begin
    name := 'tms';
    Url := TMSUrl;
    ServerType := TServerType.Api;
    Enabled := true;
  end
  else if SameText(aName, 'community') then
  begin
    name := 'community';
    Url := GitHubUrl;
    ServerType := TServerType.ZipFile;
    Enabled := false;
  end
  else raise Exception.Create('The name ' + aName + ' is not a valid internal name.');

end;

constructor TServerConfig.Create(const aName: string;
  const aServerType: TServerType; const aUrl: string;
  const aEnabled: boolean);
begin
  Name := aName.Trim;
  ServerType := aServerType;
  Url := aUrl;
  Enabled := aEnabled;
end;

function TServerConfig.IsReservedName: boolean;
begin
  Result := IsReservedName(Name);
end;

class function TServerConfig.IsReservedName(const aName: string): boolean;
begin
  for var server in BuiltinServers do if SameText(aName.Trim, server) then exit(true);
  Result := false;
end;

class function TServerConfig.ServerTypeFromString(
  const value: string; const ExtraInfo: string = ''): TServerType;
begin
 var s1 := AnsiLowerCase(value.Trim);
 if (s1 = 'api') then exit(TServerType.Api);
 if (s1 = 'zipfile') then exit(TServerType.ZipFile);

 raise Exception.Create('"' + value + '" is not a valid Server Type value. It must be "api" or "zipfile".' + ExtraInfo);

end;

function TServerConfig.ServerTypeString: string;
begin
  case ServerType of
    TServerType.Api: exit('api');
    TServerType.ZipFile: exit('zipfile');
  end;

  raise Exception.Create('Invalid Server Type.');
end;

end.
