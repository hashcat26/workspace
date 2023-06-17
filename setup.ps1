$ErrorActionPreference = "SilentlyContinue"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

md configs, downloads, packages, utilities
irm get.scoop.sh -outfile "downloads/scoop.ps1"
