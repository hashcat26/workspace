$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$WorkspaceRepo = "https://github.com/hashcat26/workspace.git"
$ConfigsDir = "$PSScriptRoot\configs"
Set-Location -LiteralPath $PSScriptRoot

Invoke-Expression "scoop alias add sp 'scoop prefix $args[0]'"
Invoke-Expression "scoop update ; scoop update -a"
Invoke-Expression "git clone -v $WorkspaceRepo"

$AliasFile = "$ConfigsDir\aliases.sh"
$XmlFile = "$ConfigsDir\ConEmu.xml"
$ConfigFile = "$ConfigsDir\gitconfig"

Copy-Item $AliasFile "$(scoop sp 'git')\etc\profile.d"
Copy-Item $XmlFile "$(scoop sp 'cmder')\vendor\conemu-maximus5"
Copy-Item $ConfigFile "$(scoop sp 'git')\etc"

$KeyFile = "$ConfigsDir\keybindings.json"
$JsonFile = "$ConfigsDir\settings.json"
$TaskFile = "$ConfigsDir\tasks.json"

ForEach ($File In $KeyFile, $JsonFile, $TaskFile) {
    Copy-Item $File "$(scoop sp 'vscode')\data\user-data\User"
}

Invoke-Expression "cp.exe -r workspace/* workspace/.* ."
Invoke-Expression "rm.exe -drf workspace ; attrib +h .git"
Invoke-Expression "scoop alias rm sp ; git up ; git st"
