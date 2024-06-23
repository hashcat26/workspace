$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$BucketRepo = "https://github.com/hashcat26/bucket"
$PackagesDir = "$PSScriptRoot\packages"
Set-Location -LiteralPath $PSScriptRoot

New-Item downloads\scripts -ItemType Directory
New-Item utilities\.venv -ItemType Directory
New-Item binaries, configs, packages -ItemType Directory

$ScoopFile = "downloads\scripts\scoop.ps1"
Invoke-RestMethod get.scoop.sh -OutFile $ScoopFile
.$ScoopFile -ScoopDir $PackagesDir

Invoke-Expression "scoop install git ; scoop bucket add extras"
Invoke-Expression "scoop bucket add hashcat $BucketRepo"
Invoke-Expression "scoop uninstall -p 7zip git" *> $Null

$BucketDir = "$PSScriptRoot\packages\buckets\hashcat\bucket"
$AppList = @(Get-ChildItem $BucketDir -Exclude 7zip*).BaseName
$PackageList = @("gallery-dl", "spotdl", "yt-dlp")

ForEach ($App In $AppList) {
    Invoke-Expression "scoop install hashcat/$App"
} Invoke-Expression "scoop install hashcat/7zip" *> $Null

Invoke-Expression "python -m pip install -U pip pip-review"
Invoke-Expression "pip install setuptools wheel pipenv"
Invoke-Expression "pip-review -aC ; cd utilities"

ForEach ($Package In $PackageList) {
    Invoke-Expression "pipenv install $Package"
} Invoke-Expression "cd .. ; scoop status" *> $Null

$ExtensionList = @("icrawl.discord-vscode",
    "ms-vscode.powershell", "ms-vscode.cpptools",
    "ms-python.python", "platformio.platformio-ide")

ForEach ($Extension In $ExtensionList) {
    Invoke-Expression "code --install-extension $Extension"
} Invoke-Expression "code --status" *> $Null
