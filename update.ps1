$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$WorkspaceRepo = "https://github.com/hashcat26/workspace.git"
$PersistsDir = "$PSScriptRoot\packages\persist"
Set-Location -LiteralPath $PSScriptRoot

Invoke-Expression "scoop update ; scoop update -a"
Invoke-Expression "cd utilities ; pipenv update ; cd .."
Invoke-Expression "git clone -v $WorkspaceRepo"

ForEach ($File In @(Get-ChildItem workspace\configs).Name) {
    Copy-Item workspace\configs\$File "$PersistsDir\nu\nushell"
} Invoke-Expression "del $PersistsDir\nu\nushell -e *.nu"

$AliasFile = "workspace\configs\aliases.sh"
$TermFile = "workspace\configs\ConEmu.xml"
$ConfigFile = "workspace\configs\gitconfig"

Copy-Item $AliasFile "$PersistsDir\git\etc\profile.d"
Copy-Item $TermFile "$PersistsDir\cmder\vendor\conemu-maximus5"
Copy-Item $ConfigFile "$PersistsDir\git\etc"

$WindowFile = "workspace\configs\komorebi.json"
$AppFile = "workspace\configs\applications.json"
$MacroFile = "workspace\configs\whkdrc"

Copy-Item $WindowFile "$PersistsDir\komorb\config"
Copy-Item $AppFile "$PersistsDir\komorb\config"
Copy-Item $MacroFile "$PersistsDir\whkd\config"

$KeyFile = "workspace\configs\keybindings.json"
$OptFile = "workspace\configs\settings.json"
$TaskFile = "workspace\configs\tasks.json"

ForEach ($File In $KeyFile, $OptFile, $TaskFile) {
    Copy-Item $File "$PersistsDir\vscode\data\user-data\User"
} Invoke-Expression "code --update-extensions"

Invoke-Expression "cp -r -force workspace\* ."
Invoke-Expression "rm -r -force workspace ; attrib +h .git"
Invoke-Expression "git remote update ; git pull"

ForEach ($Cache In @(Get-ChildItem packages\cache).Name) {
    Invoke-Expression "del packages\cache\$Cache"
} Invoke-Expression "scoop cleanup -a" *> $Null
