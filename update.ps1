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

Copy-Item $KeyFile "$AppsDir\vscode\current\data\user-data\User"
Copy-Item $JsonFile "$AppsDir\vscode\current\data\user-data\User"
Copy-Item $TaskFile "$AppsDir\vscode\current\data\user-data\User"

Invoke-Expression "git cl https://github.com/hashcat26/workspace.git"
Invoke-Expression "cp.exe -r workspace/* workspace/.* ."
Invoke-Expression "rm.exe -drf workspace"

Invoke-Expression "attrib +h .git"
Invoke-Expression "git ru ; git pl"
Invoke-Expression "git st ; git lg | head"
