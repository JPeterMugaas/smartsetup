unit UConfigKeys;

interface
const
  GlobalProductId = 'all products';

type
  ConfigKeys = record
  public
  const
    Verbosity = 'verbosity';
    DryRun = 'dry-run';
    CompilerPath = 'compiler-path.';
    CompilerParameters = 'compiler-parameters.';
    SkipRegister = 'skip-register';
    DebugDcus = 'debug-dcus';
    AddSourceCodeToLibraryPath = 'add-source-code-to-library-path';
    KeepParallelFolders = 'keep-parallel-folders';
    SymLinks = 'symlinks';
    ModifySources = 'modify-sources';
    PartialBuilds = 'partial-builds';
  end;
implementation

end.
