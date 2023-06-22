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
