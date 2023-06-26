$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$PackagesDir = "$PSScriptRoot\packages"
$GlobalsDir = "$PSScriptRoot\packages\globals"
Set-Location -LiteralPath $PSScriptRoot

$ScoopFile = "downloads\scoop.ps1"
$AppList = "cmder", "ffmpeg", "git", "python" ,"vscode"
$PackageList = "gallery-dl", "spotdl", "yt-dlp"

New-Item downloads, packages, utilities -ItemType Directory
Invoke-RestMethod get.scoop.sh -OutFile $ScoopFile
.$ScoopFile -ScoopDir $PackagesDir -ScoopGlobalDir $GlobalsDir

Invoke-Expression "scoop bucket add extras"
Invoke-Expression "scoop update"
Invoke-Expression "scoop status"

foreach ($AppName in $AppList) {
    Invoke-Expression "scoop install $AppName"
}

Invoke-Expression "pip install virtualenv"
Invoke-Expression "virtualenv utilities"
Invoke-Expression ". utilities\Scripts\activate"

foreach ($PackageName in $PackageList) {
    Invoke-Expression "pip install $PackageName"
}
