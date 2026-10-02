#Requires -Version 5.1
#Requires -Modules @{ModuleName = "BuildHelpers"; ModuleVersion = "2.0.1"}
#Requires -Modules @{ModuleName = "Pester"; ModuleVersion = "5.2.0"}

$PesterConfig = New-PesterConfiguration -HashTable @{
    Run = @{
        Path = "$PSScriptRoot/.."
        PassThru = $True
    }
    Output = @{
        Verbosity = "Detailed"
    }
}

$Result = Invoke-Pester -Configuration $PesterConfig
Exit $Result.FailedCount
