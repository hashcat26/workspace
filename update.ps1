$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$AppsDir = "$PSScriptRoot\packages\apps"
$ConfigsDir = "$PSScriptRoot\configs"
Set-Location -LiteralPath $PSScriptRoot

$AliasFile = "$ConfigsDir\aliases.sh"
$XmlFile = "$ConfigsDir\ConEmu.xml"
$ConfigFile = "$ConfigsDir\gitconfig"

Copy-Item $AliasFile "$AppsDir\git\current\etc\profile.d"
Copy-Item $XmlFile "$AppsDir\cmder\current\vendor\conemu-maximus5"
Copy-Item $ConfigFile "$AppsDir\git\current\etc"

$KeyFile = "$ConfigsDir\keybindings.json"
$JsonFile = "$ConfigsDir\settings.json"
$TaskFile = "$ConfigsDir\tasks.json"

ForEach ($FileName In $KeyFile, $JsonFile, $TaskFile) {
    Copy-Item $FileName "$AppsDir\vscode\current\data\user-data\User"
}

Invoke-Expression "sal cp cp.exe -o allscope"
Invoke-Expression "sal rm rm.exe -o allscope"
Invoke-Expression "git cl https://github.com/hashcat26/workspace.git"

Invoke-Expression "cp -r workspace/* workspace/.* ."
Invoke-Expression "rm -drf workspace"
Invoke-Expression "attrib +h .git ; git st ; git lg | head"
