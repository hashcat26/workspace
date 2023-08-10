$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$WorkspaceRepo = "https://github.com/hashcat26/workspace.git"
$PersistsDir = "$PSScriptRoot\packages\persist"
Set-Location -LiteralPath $PSScriptRoot

Invoke-Expression "scoop update ; scoop update -a"
Invoke-Expression "cd utilities ; pipenv update ; cd .."
Invoke-Expression "git clone -v $WorkspaceRepo" *> $Null

$AliasFile = "workspace\configs\aliases.sh"
$TermFile = "workspace\configs\ConEmu.xml"
$ConfigFile = "workspace\configs\gitconfig"

Copy-Item $AliasFile "$PersistsDir\git\etc\profile.d"
Copy-Item $TermFile "$PersistsDir\cmder\vendor\conemu-maximus5"
Copy-Item $ConfigFile "$PersistsDir\git\etc"

$KeyFile = "workspace\configs\keybindings.json"
$OptFile = "workspace\configs\settings.json"
$TaskFile = "workspace\configs\tasks.json"

ForEach ($File In $KeyFile, $OptFile, $TaskFile) {
    Copy-Item $File "$PersistsDir\vscode\data\user-data\User"
} Invoke-Expression "scoop cleanup -a" *> $Null

Invoke-Expression "cp -r -force workspace/* ."
Invoke-Expression "rm -r -force workspace ; attrib +h .git"
Invoke-Expression "git remote update ; git pull" *> $Null
