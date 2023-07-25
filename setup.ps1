$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$PackagesDir = "$PSScriptRoot\packages"
$GlobalsDir = "$PSScriptRoot\packages\globals"
Set-Location -LiteralPath $PSScriptRoot

$ScoopFile = "downloads\scripts\scoop.ps1"
$AppList = "cmder", "ffmpeg", "git", "python", "qemu", "vscode"
$PackageList = "gallery-dl", "spotdl", "yt-dlp"

New-Item downloads, packages, utilities -ItemType Directory
Invoke-RestMethod get.scoop.sh -OutFile $ScoopFile
.$ScoopFile -ScoopDir $PackagesDir -ScoopGlobalDir $GlobalsDir

$BucketRepo = "https://github.com/hashcat26/bucket"
Invoke-Expression "scoop bucket add hashcat $BucketRepo"
Invoke-Expression "scoop bucket add extras ; scoop status"

ForEach ($App In $AppList) {
    Invoke-Expression "scoop install $App"
}

$UpgradeCmd = "python -m pip install -U pip pipenv setuptools"
Invoke-Expression "pip install pipenv ; $UpgradeCmd"
Invoke-Expression "md -f utilities\.venv > $null ; cd utilities"

ForEach ($Package In $PackageList) {
    Invoke-Expression "pipenv install $Package"
}
