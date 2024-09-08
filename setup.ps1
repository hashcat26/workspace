$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$BucketRepo = "https://github.com/hashcat26/bucket"
$PackagesDir = "$PSScriptRoot\packages"
Set-Location -LiteralPath $PSScriptRoot

New-Item downloads\scripts -ItemType Dir *> $Null
New-Item utilities\.venv -ItemType Dir *> $Null
New-Item binaries, configs, packages -ItemType Dir *> $Null

$ScoopFile = "downloads\scripts\scoop.ps1"
Invoke-RestMethod get.scoop.sh -OutFile $ScoopFile
.$ScoopFile -ScoopDir $PackagesDir

Invoke-Expression "scoop config use_isolated_path true"
Invoke-Expression "scoop config use_external_7zip true"
Invoke-Expression "scoop config aria2-enabled false"

Invoke-Expression "scoop install 7zip git" *> $Null
Invoke-Expression "scoop bucket add extras"
Invoke-Expression "scoop bucket add hashcat $BucketRepo"

If (Invoke-Expression "scoop list 6>&1" | Select-String main) {
    Invoke-Expression "scoop uninstall -p 7zip git" *> $Null
} Invoke-Expression "scoop install hashcat/7zip hashcat/git"

$AppDir = "$PSScriptRoot\packages\buckets\hashcat\bucket"
$AppList = @(Get-ChildItem $AppDir -Exclude 7z*, git*).BaseName
$PkgList = @("gallery-dl", "spotdl", "yt-dlp")

ForEach ($App In $AppList) {
    Invoke-Expression "scoop install hashcat/$App"
} Invoke-Expression "scoop status" *> $Null

Invoke-Expression "python -m pip install -U pip pip-review"
Invoke-Expression "pip install setuptools wheel pipenv"
Invoke-Expression "pip-review -aC ; cd utilities"

ForEach ($Pkg In $PkgList) {
    Invoke-Expression "pipenv install $Pkg"
} Invoke-Expression "pipenv clean ; cd .." *> $Null

$BaseUrl = "https://raw.githubusercontent.com/hashcat26"
$FileUrl = "workspace\master\configs\extensions.lst"
$ExtList = @(Invoke-RestMethod $BaseUrl/$FileUrl) -Split "\n"

ForEach ($Ext In $ExtList | Select-Object -SkipLast 1) {
    Invoke-Expression "code --install-extension $Ext"
} Invoke-Expression "code --status" *> $Null
