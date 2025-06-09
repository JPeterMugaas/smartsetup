unit UDelphi2007Installer;
{$i ../../tmssetup.inc}

interface
uses Deget.CoreTypes, UInstaller, UDcc32Installer;

type
  TDelphi2007Installer = class(TDcc32Installer)
  public
    function IDEName: TIDEName; override;
    function DisplayName: string; override;
    function DllSuffix: string; override;
    function PlatformsSupported: TPlatformSet; override;
  end;
implementation

{ TDelphi2007Installer }

function TDelphi2007Installer.IDEName: TIDEName;
begin
  Result := TIDEName.delphi2007;
end;

function TDelphi2007Installer.DisplayName: string;
begin
  Result := 'Delphi 2007';
end;

function TDelphi2007Installer.DllSuffix: string;
begin
  Result := '110';
end;

function TDelphi2007Installer.PlatformsSupported: TPlatformSet;
begin
  Result := [TPlatform.win32intel];
end;
end.
