$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$WorkspaceRepo = "https://github.com/hashcat26/workspace.git"
$ConfigsDir = "$PSScriptRoot\configs"
Set-Location -LiteralPath $PSScriptRoot

Invoke-Expression "scoop update ; scoop update -a"
Invoke-Expression "cd utilities ; pipenv update ; cd .."
Invoke-Expression "git clone -v $WorkspaceRepo"

$AliasFile = "$ConfigsDir\aliases.sh"
$XmlFile = "$ConfigsDir\ConEmu.xml"
$ConfigFile = "$ConfigsDir\gitconfig"

Copy-Item $AliasFile "$(scoop prefix git)\etc\profile.d"
Copy-Item $XmlFile "$(scoop prefix cmder)\vendor\conemu-maximus5"
Copy-Item $ConfigFile "$(scoop prefix git)\etc"

$KeyFile = "$ConfigsDir\keybindings.json"
$JsonFile = "$ConfigsDir\settings.json"
$TaskFile = "$ConfigsDir\tasks.json"

ForEach ($File In $KeyFile, $JsonFile, $TaskFile) {
    Copy-Item $File "$(scoop prefix vscode)\data\user-data\User"
}

Invoke-Expression "cp.exe -r workspace/* workspace/.* ."
Invoke-Expression "rm.exe -drf workspace ; attrib +h .git"
Invoke-Expression "git up ; git st ; git lg | head"
