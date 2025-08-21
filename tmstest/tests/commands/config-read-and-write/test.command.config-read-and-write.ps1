. test.setup
tms config -reset -print

$buildCores = 0
$altRegistryKey = ""
$preventSleep = "true"
$versionsToKeep = "-1"
$errorIfSkipped = "false"
$excludedProducts = "[]"
$includedProducts = "[]"
$additionalProductsFolders = "[]"
$tmsServerEnabled = "true"
$communityServerEnabled = "false"
$gitLocation = ""
$gitCloneCommand = ""
$gitPullCommand = ""
$svnLocation = ""
$svnCheckoutCommand = ""
$svnUpdateCommand = ""
$dcuMegafolders = "[]"

$productArray = @("all products", "test1", "test2")

function Test-ValuesOk() {
tms config-read "tms smart setup options:build cores" | Assert-ValueIs $buildCores
tms config-read "tms smart setup options:alternate registry key" | Assert-ValueIs $altRegistryKey
tms config-read "tms smart setup options:prevent sleep" | Assert-ValueIs $preventSleep
tms config-read "tms smart setup options:versions to keep" | Assert-ValueIs $versionsToKeep
tms config-read "tms smart setup options:error if skipped" | Assert-ValueIs $errorIfSkipped
tms config-read "tms smart setup options:excluded products" | Assert-ValueIs $excludedProducts
tms config-read "tms smart setup options:included products" | Assert-ValueIs $includedProducts
tms config-read "tms smart setup options:additional products folders" | Assert-ValueIs $additionalProductsFolders
tms config-read "tms smart setup options:servers:tms:enabled" | Assert-ValueIs $tmsServerEnabled
tms config-read "tms smart setup options:servers:community:enabled" | Assert-ValueIs $communityServerEnabled
tms config-read "tms smart setup options:git:git location" | Assert-ValueIs $gitLocation
tms config-read "tms smart setup options:git:clone command" | Assert-ValueIs $gitCloneCommand
tms config-read "tms smart setup options:git:pull command" | Assert-ValueIs $gitPullCommand
tms config-read "tms smart setup options:svn:svn location" | Assert-ValueIs $svnLocation
tms config-read "tms smart setup options:svn:checkout command" | Assert-ValueIs $svnCheckoutCommand
tms config-read "tms smart setup options:svn:update command" | Assert-ValueIs $svnUpdateCommand
tms config-read "tms smart setup options:dcu megafolders" | Assert-ValueIs $dcuMegafolders
}

Test-ValuesOk

$buildCores = 4
tms config-write -p:"tms smart setup options:build cores=$buildCores"
Test-ValuesOk

$altRegistryKey = "myProduct"
tms config-write -p:"tms smart setup options:alternate registry key=$altRegistryKey"
Test-ValuesOk

$preventSleep = "false"
tms config-write -p:"tms smart setup options:prevent sleep=$preventSleep"
Test-ValuesOk

$versionsToKeep = "3"
tms config-write -p:"tms smart setup options:versions to keep=$versionsToKeep"
Test-ValuesOk

$errorIfSkipped = "true"
tms config-write -p:"tms smart setup options:error if skipped=$errorIfSkipped"
Test-ValuesOk

$excludedProducts = "[tms-fnc,tms-fnc-cloud]"
tms config-write -p:"tms smart setup options:excluded products=$excludedProducts"
Test-ValuesOk

$includedProducts = "[tms-fnc-cloud]"
tms config-write -p:"tms smart setup options:included products=$includedProducts"
Test-ValuesOk

$additionalProductsFolders = "[..\landgraf\aws-sdk-delphi,..\landgraf\tms-biz,..\tms\delphi-graphql]"
tms config-write -p:"tms smart setup options:additional products folders=$additionalProductsFolders"
Test-ValuesOk

$tmsServerEnabled = "false"
tms config-write -p:"tms smart setup options:servers:tms:enabled=$tmsServerEnabled"
Test-ValuesOk

$communityServerEnabled = "true"
tms config-write -p:"tms smart setup options:servers:community:enabled=$communityServerEnabled"
Test-ValuesOk

$gitLocation = "C:\Program Files\Git\cmd\git.exe"
tms config-write -p:"tms smart setup options:git:git location=$gitLocation"
Test-ValuesOk

$gitCloneCommand = "clone --depth 1"
tms config-write -p:"tms smart setup options:git:clone command=$gitCloneCommand"
Test-ValuesOk

$gitPullCommand = "pull"
tms config-write -p:"tms smart setup options:git:pull command=$gitPullCommand"
Test-ValuesOk

$svnLocation = "C:\Program Files\TortoiseSVN\bin\svn.exe"
tms config-write -p:"tms smart setup options:svn:svn location=$svnLocation"
Test-ValuesOk

$svnCheckoutCommand = "checkout --depth immediates"
tms config-write -p:"tms smart setup options:svn:checkout command=$svnCheckoutCommand"
Test-ValuesOk

$svnUpdateCommand = "update"
tms config-write -p:"tms smart setup options:svn:update command=$svnUpdateCommand"
Test-ValuesOk

$dcuMegafolders = "[tms: '*.tms',none: test,other: '*']"
tms config-write -p:"tms smart setup options:dcu megafolders=$dcuMegafolders"
Test-ValuesOk

tms config-write -p:"tms smart setup options:dcu megafolders=[tms:*.tms, none: test,other:*, all: p]"
$dcuMegafolders = "[tms: '*.tms',none: test,other: '*',all: p]"
Test-ValuesOk

Invoke-WithExitCodeIgnored {
    tms config-read "tms smart setup options:build cores2" | Assert-ValueContains "Error: Unknown property: ""tms smart setup options:build cores2"""
}
