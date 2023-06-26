$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$PackagesDir = "$PSScriptRoot\packages"
$GlobalsDir = "$PSScriptRoot\packages\globals"
Set-Location -LiteralPath $PSScriptRoot

$ScoopFile = "$PSScriptRoot\downloads\scoop.ps1"
$AppList = "cmder", "ffmpeg", "git", "python" ,"vscode"
$PackageList = "gallery-dl", "spotdl", "yt-dlp"

New-Item downloads, packages, utilities -ItemType Directory
Invoke-RestMethod get.scoop.sh -OutFile $ScoopFile
.$ScoopFile -ScoopDir $PackagesDir -ScoopGlobalDir $GlobalsDir

scoop.exe bucket add hashcat https://github.com/hashcat26/bucket
scoop.exe bucket add main ; scoop.exe bucket add extras
scoop.exe update ; scoop.exe status

foreach ($AppName in $AppList) {
    scoop.exe install $AppName
}

python.exe -mod pip install --upgrade pip
pip.exe install virtualenv ; virtualenv.exe utilities
. "$PSScriptRoot\utilities\Scripts\activate"

foreach ($PackageName in $PackageList) {
    pip.exe install $PackageName
}
