$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$BucketRepo = "https://github.com/hashcat26/bucket"
$PackagesDir = "$PSScriptRoot\packages"
Set-Location -LiteralPath $PSScriptRoot

$ScoopFile = "downloads\scripts\scoop.ps1"
$AppList = "cmder", "ffmpeg", "git", "python", "qemu", "vscode"
$PackageList = "gallery-dl", "spotdl", "yt-dlp"

New-Item downloads\scripts, packages, utilities -ItemType Dir
Invoke-RestMethod get.scoop.sh -OutFile $ScoopFile
.$ScoopFile -ScoopDir $PackagesDir

Invoke-Expression "scoop install git ; scoop bucket add extras"
Invoke-Expression "scoop bucket add hashcat $BucketRepo"
Invoke-Expression "scoop uninstall -p 7zip git" *> $Null

ForEach ($App In $AppList) {
    Invoke-Expression "scoop install hashcat/$App"
} Invoke-Expression "scoop install hashcat/7zip" *> $Null

Invoke-Expression "python -m pip install -U setuptools"
Invoke-Expression "python -m pip install -U pip pipenv"
Invoke-Expression "cd utilities ; md -f .venv" *> $Null

ForEach ($Package In $PackageList) {
    Invoke-Expression "pipenv install $Package"
} Invoke-Expression "cd .. ; scoop status" *> $Null
