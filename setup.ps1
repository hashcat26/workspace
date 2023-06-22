$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$GlobalsDir = "$PSScriptRoot\packages\globals"
$ScoopFile = "$PSScriptRoot\downloads\scoop.ps1"
Set-Location -LiteralPath $PSScriptRoot

New-Item downloads, packages, utilities -ItemType Directory
Invoke-RestMethod get.scoop.sh -OutFile $ScoopFile
.$ScoopFile -ScoopDir $PSScriptRoot -ScoopGlobalDir $GlobalsDir

scoop bucket add hashcat https://github.com/hashcat26/bucket
scoop bucket add main ; scoop bucket add extras
scoop update ; scoop status

scoop install 7zip
scoop install cmder
scoop install dark
scoop install ffmpeg
scoop install git
scoop install python
scoop install vscode
