$DefaultDir = Convert-Path(pwd)
$GlobalsDir = "$DefaultDir\globals"

echo $DefaultDir
echo $GlobalsDir

$ErrorActionPreference = "SilentlyContinue"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

mkdir downloads, packages, utilities
irm get.scoop.sh -outfile "downloads/scoop.ps1"

./downloads/scoop.ps1 -ScoopDir $DefaultDir -ScoopGlobalDir $GlobalsDir

scoop status
