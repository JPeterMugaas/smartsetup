unit Fetching.InstallInfo;

interface

uses
  System.Generics.Collections, System.SysUtils, System.IOUtils, System.Classes, Fetching.InfoFile;

procedure GetFetchedProducts(const RootFolder: string; Products: TObjectList<TFetchInfoFile>);
procedure GetRepoProducts(const RootFolder: string; Products: TObjectList<TFetchInfoFile>);

implementation

uses
  UTmsBuildSystemUtils, Commands.GlobalConfig;

procedure GetFetchedProducts(const RootFolder: string; Products: TObjectList<TFetchInfoFile>);
begin
  if not TDirectory.Exists(RootFolder) then exit;

  var Folders := TDirectory.GetDirectories(RootFolder, '*', TSearchOption.soTopDirectoryOnly);
  for var Folder in Folders do
  begin
    var Filename := TPath.Combine(Folder, TFetchInfoFile.FileName);
    if TFile.Exists(Filename) then  Products.Add(TFetchInfoFile.FromFile(Filename));
  end;

end;

procedure GetRepoProducts(const RootFolder: string; Products: TObjectList<TFetchInfoFile>);
begin
  if not TDirectory.Exists(RootFolder) then exit;
  var Folders := TDirectory.GetDirectories(RootFolder, '*', TSearchOption.soTopDirectoryOnly);
  for var Folder in Folders do
  begin
    var ProductId := TPath.GetFileName(Folder);
    if RegisteredVCSRepos.Contains(ProductId) then
    begin
      Products.Add(TFetchInfoFile.Create(ProductId, Folder, '', 'VCS'));
    end;
  end;
end;

end.
