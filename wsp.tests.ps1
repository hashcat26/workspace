if (!$Env:SCOOP_HOME) {
    $Env:SCOOP_HOME = Resolve-Path (scoop prefix scoop)
}

. "$Env:SCOOP_HOME\test\Scoop-00File.Tests.ps1"
