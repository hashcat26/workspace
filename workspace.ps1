# ==================================================
# SCRIPT CONFIGURATION
# ==================================================

[CmdletBinding(SupportsShouldProcess)]

Param (
    [ValidateSet("Initialize", "Update", "Debug", "Remove")]
    [String]$TaskMode = "Update",
    [Switch]$RemoveMode
)

$ErrorActionPreference = "Continue"
$WarningPreference = "Continue"


# ==================================================
# SCRIPT VARIABLES
# ==================================================

$WorkspaceRoot = $PSScriptRoot
$ConfigHome = Join-Path $WorkspaceRoot ".xdg"
$ConfigsDir = Join-Path $WorkspaceRoot "configs"
$ScriptsDir = Join-Path $WorkspaceRoot "downloads\scripts"
$PackagesDir = Join-Path $WorkspaceRoot "packages"
$UtilitiesDir = Join-Path $WorkspaceRoot "utilities"

$ScoopDir = Join-Path $PackagesDir "apps\scoop\current"
$CodeDir = Join-Path $PackagesDir "apps\vscode\current"
$BucketDir = Join-Path $PackagesDir "buckets\hashcat\bucket"

$StateFile = Join-Path $ConfigHome "workspace.json"
$ScoopFile = Join-Path $ScriptsDir "scoop.ps1"
$ProjectFile = Join-Path $UtilitiesDir "pyproject.toml"
$LockFile = Join-Path $UtilitiesDir "uv.lock"

$WorkspaceUrl = "https://github.com/hashcat26/workspace.git"
$BucketUrl = "https://github.com/hashcat26/bucket"
$BaseUrl = "https://raw.githubusercontent.com/hashcat26"
$FileUrl = "workspace/master/configs/extensions.lst"

$DepList = "aria2", "7zip", "innounp", "dotnetsdk", "wixtoolset"
$PkgList = "ipykernel", "gallery-dl", "spotdl", "yt-dlp"
$ExtList = (Invoke-RestMethod "$BaseUrl/$FileUrl") -Split "\r?\n" | Where-Object {$_}


# ==================================================
# WORKSPACE SETUP
# ==================================================

Function Set-Directories {
    $WorkspaceDirs = @(
        (Join-Path $WorkspaceRoot "binaries")
        $ConfigHome
        $ConfigsDir
        $ScriptsDir
        $PackagesDir
        $UtilitiesDir
    )

    ForEach ($WorkspaceDir In $WorkspaceDirs) {
        New-Item $WorkspaceDir -ItemType "Directory" -Force | Out-Null
    }
}

Function Set-Environment {
    $Env:WORKSPACE_ROOT = $WorkspaceRoot
    $Env:XDG_CONFIG_HOME = $ConfigHome
    $Env:NODE_OPTIONS = "--no-deprecation"

    [Environment]::SetEnvironmentVariable("WORKSPACE_ROOT", $WorkspaceRoot, "User")
    [Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", $ConfigHome, "User")
}


# ==================================================
# COMPONENT INSTALLATION
# ==================================================

Function Install-Scoop {
    Invoke-RestMethod "https://get.scoop.sh" -OutFile $ScoopFile
    & $ScoopFile -ScoopDir $PackagesDir

    Invoke-Expression "scoop config use_isolated_path true"
    Invoke-Expression "scoop config aria2-warning-enabled false"
}

Function Install-Buckets {
    Write-Host "Adding Scoop buckets..."

    Invoke-Expression "scoop install 7zip git" *> $Null
    Invoke-Expression "scoop bucket add extras"
    Invoke-Expression "scoop bucket add nerd-fonts"
    Invoke-Expression "scoop bucket add java"
    Invoke-Expression "scoop bucket add hashcat $BucketUrl"
    Invoke-Expression "scoop uninstall --purge 7zip git" *> $Null
}

Function Install-Applications {
    $BucketFilter = $DepList | ForEach-Object {"$_*"}

    $AppList = @(
        $DepList
        (Get-ChildItem $BucketDir -Exclude $BucketFilter).BaseName
    )

    ForEach ($AppName In $AppList) {
        Invoke-Expression "scoop install hashcat/$AppName"
    }
}

Function Install-Project {
    Invoke-Expression "uv init --bare --directory `"$UtilitiesDir`""
    Invoke-Expression "uv lock --directory `"$UtilitiesDir`""
}

Function Install-Packages {
    ForEach ($PkgName In $PkgList) {
        Invoke-Expression "uv add $PkgName --directory `"$UtilitiesDir`""
    }
}

Function Install-Extensions {
    ForEach ($ExtName In $ExtList) {
        Invoke-Expression "code --install-extension $ExtName"
    }
}

Function Install-Repository {
    Invoke-Expression "git init --initial-branch master"
    Invoke-Expression "git remote add origin $WorkspaceUrl"
    Invoke-Expression "git fetch origin"
    Invoke-Expression "git checkout --force master"
}


# ==================================================
# COMPONENT TESTING
# ==================================================

Function Test-Scoop {
    $PrefixDir = Invoke-Expression "scoop prefix scoop"
    $ConfigList = Invoke-Expression "scoop config"

    [PSCustomObject]@{
        ScoopInstalled = $PrefixDir -Eq $ScoopDir
        PathIsolated = $ConfigList.'use_isolated_path' -Eq $True
        WarningDisabled = $ConfigList.'aria2-warning-enabled' -Eq $False
    }
}

Function Test-Buckets {
    $BucketList = Invoke-Expression "scoop bucket list"

    [PSCustomObject]@{
        ExtrasInstalled = $BucketList.Name -Contains "extras"
        FontsInstalled = $BucketList.Name -Contains "nerd-fonts"
        JavaInstalled = $BucketList.Name -Contains "java"
        HashcatInstalled = $BucketList.Name -Contains "hashcat"
    }
}

Function Test-Applications {
    $AppList = (Get-ChildItem $BucketDir).BaseName
    $ActList = Invoke-Expression "scoop list" 6> $Null

    ForEach ($AppName In $AppList) {
        $AppEntry = $ActList | Where-Object {$_.Name -Eq $AppName}

        [PSCustomObject]@{
            AppName = $AppName
            AppInstalled = $Null -Ne $AppEntry -And $AppEntry.Info -NotLike "*failed"
        }
    }
}

Function Test-Project {
    Invoke-Expression "uv lock --check --directory `"$UtilitiesDir`"" *> $Null
    $LockState = $LASTEXITCODE -Eq 0

    Invoke-Expression "uv sync --check --directory `"$UtilitiesDir`"" *> $Null
    $VenvState = $LASTEXITCODE -Eq 0

    [PSCustomObject]@{
        ProjectCreated = Test-Path -LiteralPath $ProjectFile -PathType "Leaf"
        LockCreated = Test-Path -LiteralPath $LockFile -PathType "Leaf"
        LockValidated = $LockState
        VenvSynced = $VenvState
    }
}

Function Test-Packages {
    $ActList = Invoke-Expression "uv pip list --directory `"$UtilitiesDir`""

    ForEach ($PkgName In $PkgList) {
        $PkgEntry = $ActList | Where-Object {$_ -Like "$PkgName *"}

        [PSCustomObject]@{
            PkgName = $PkgName
            PkgInstalled = $Null -Ne $PkgEntry
        }
    }
}

Function Test-Extensions {
    $ActList = Invoke-Expression "code --list-extensions"

    ForEach ($ExtName In $ExtList) {
        $ExtEntry = $ActList | Where-Object {$_ -Eq $ExtName}

        [PSCustomObject]@{
            ExtName = $ExtName
            ExtInstalled = $Null -Ne $ExtEntry
        }
    }
}

Function Test-Repository {
    $RemoteList = Invoke-Expression "git remote"
    $RemoteUrl = Invoke-Expression "git remote get-url origin"
    $BranchName = Invoke-Expression "git branch --show-current"

    Invoke-Expression "git rev-parse --resolve-git-dir .git" *> $Null
    $GitState = $LASTEXITCODE -Eq 0

    Invoke-Expression "git rev-parse --verify origin/master" *> $Null
    $RemoteState = $LASTEXITCODE -Eq 0

    [PSCustomObject]@{
        GitInitialized = $GitState
        RemoteAdded = $RemoteList -Contains "origin"
        RemoteConfigured = $RemoteUrl -Eq $WorkspaceUrl
        RemoteFetched = $RemoteState
        BranchSwitched = $BranchName -Eq "master"
    }
}


# ==================================================
# COMPONENT REPAIR
# ==================================================

Function Repair-Scoop {
    $ScoopState = Test-Scoop

    If (-Not $ScoopState.ScoopInstalled) {
        Install-Scoop
    }
    If (-Not $ScoopState.PathIsolated) {
        Invoke-Expression "scoop config use_isolated_path true"
    }
    If (-Not $ScoopState.WarningDisabled) {
        Invoke-Expression "scoop config aria2-warning-enabled false"
    }
}

Function Repair-Buckets {
    $BucketState = Test-Buckets

    If (-Not $BucketState.ExtrasInstalled) {
        Invoke-Expression "scoop bucket add extras"
    }
    If (-Not $BucketState.FontsInstalled) {
        Invoke-Expression "scoop bucket add nerd-fonts"
    }
    If (-Not $BucketState.JavaInstalled) {
        Invoke-Expression "scoop bucket add java"
    }
    If (-Not $BucketState.HashcatInstalled) {
        Invoke-Expression "scoop bucket add hashcat $BucketUrl"
    }
}

Function Repair-Applications {
    $AppState = Test-Applications
    $AppEntries = $AppState | Where-Object {-Not $_.AppInstalled}

    ForEach ($AppEntry In $AppEntries) {
        Invoke-Expression "scoop install hashcat/$($AppEntry.AppName)"
    }
}

Function Repair-Project {
    $ProjectState = Test-Project

    If (-Not $ProjectState.ProjectCreated) {
        Invoke-Expression "uv init --bare --directory `"$UtilitiesDir`""
    }
    If (-Not $ProjectState.LockCreated -Or -Not $ProjectState.LockValidated) {
        Invoke-Expression "uv lock --directory `"$UtilitiesDir`""
    }
    If (-Not $ProjectState.VenvSynced) {
        Invoke-Expression "uv sync --directory `"$UtilitiesDir`""
    }
}

Function Repair-Packages {
    $PkgState = Test-Packages
    $PkgEntries = $PkgState | Where-Object {-Not $_.PkgInstalled}

    ForEach ($PkgEntry In $PkgEntries) {
        Invoke-Expression "uv add $($PkgEntry.PkgName) --directory `"$UtilitiesDir`""
    }
}

Function Repair-Extensions {
    $ExtState = Test-Extensions
    $ExtEntries = $ExtState | Where-Object {-Not $_.ExtInstalled}

    ForEach ($ExtEntry In $ExtEntries) {
        Invoke-Expression "code --install-extension $($ExtEntry.ExtName)"
    }
}

Function Repair-Repository {
    $RepositoryState = Test-Repository

    If (-Not $RepositoryState.GitInitialized) {
        Invoke-Expression "git init --initial-branch master"
    }
    If (-Not $RepositoryState.RemoteAdded) {
        Invoke-Expression "git remote add origin $WorkspaceUrl"
    }
    ElseIf (-Not $RepositoryState.RemoteConfigured) {
        Invoke-Expression "git remote set-url origin $WorkspaceUrl"
    }
    If (-Not $RepositoryState.RemoteFetched) {
        Invoke-Expression "git fetch origin"
    }
    If (-Not $RepositoryState.BranchSwitched) {
        Invoke-Expression "git checkout --force master"
    }
}


# ==================================================
# COMPONENT UPDATE
# ==================================================

Function Update-Components {
    Invoke-Expression "scoop update scoop"
    Invoke-Expression "scoop update --all"
    Invoke-Expression "scoop cleanup --all"
    Invoke-Expression "scoop cache rm --all"

    Invoke-Expression "uv sync --upgrade --directory `"$UtilitiesDir`""
    Invoke-Expression "code --update-extensions"
    Invoke-Expression "git pull --ff-only"
}

Function Update-Configurations {
    $ConfigFiles = @{
        "gitconfig" = "git\config"
        "wezterm.lua" = "wezterm\wezterm.lua"
        "config.nu" = "nushell\config.nu"
        "env.nu" = "nushell\env.nu"
        "prompt.nu" = "nushell\prompt.nu"
    }

    ForEach ($ConfigFile In $ConfigFiles.GetEnumerator()) {
        $SrcFile = Join-Path $ConfigsDir $ConfigFile.Key
        $DestFile = Join-Path $ConfigHome $ConfigFile.Value

        New-Item (Split-Path $DestFile) -ItemType "Directory" -Force | Out-Null
        New-Item $DestFile -Target $SrcFile -ItemType "HardLink" -Force | Out-Null
    }

    $UserDir = Join-Path $CodeDir "data\user-data\User"
    $CodeFiles = "keybindings.json", "settings.json", "tasks.json"

    ForEach ($CodeFile In $CodeFiles) {
        $SrcFile = Join-Path $ConfigsDir $CodeFile
        $DestFile = Join-Path $UserDir $CodeFile

        New-Item (Split-Path $DestFile) -ItemType "Directory" -Force | Out-Null
        New-Item $DestFile -Target $SrcFile -ItemType "HardLink" -Force | Out-Null
    }
}


# ==================================================
# STATE MANAGEMENT
# ==================================================

Function Import-Tests {
    [Ordered]@{
        Scoop = {Test-Scoop}
        Buckets = {Test-Buckets}
        Applications = {@(Test-Applications)}
        Project = {Test-Project}
        Packages = {@(Test-Packages)}
        Extensions = {@(Test-Extensions)}
        Repository = {Test-Repository}
    }
}

Function Read-State {
    Write-Host "Checking workspace state..."
    $WorkspaceState = [Ordered]@{}

    (Import-Tests).GetEnumerator() | ForEach-Object {
        $WorkspaceState[$_.Key] = & $_.Value
    }

    [PSCustomObject]$WorkspaceState
}

Function Write-State {
    Read-State | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $StateFile
    Write-Host "Workspace state saved to $StateFile"
}


# ==================================================
# CLEANUP UTILITIES
# ==================================================

Function Protect-Action {
    [CmdletBinding(SupportsShouldProcess)]

    Param (
        [Parameter(Mandatory)][String]$ActionMessage,
        [Parameter(Mandatory)][String]$ActionTarget,
        [Parameter(Mandatory)][ScriptBlock]$ActionBlock
    )

    If ($PSCmdlet.ShouldProcess($ActionTarget, $ActionMessage)) {
        & $ActionBlock
    }
}

Function Search-Processes {
    Param (
        [Parameter(Mandatory)][String]$AppName
    )

    $AppDir = Join-Path $PackagesDir "apps\$AppName\"
    $ProcList = Get-CimInstance "Win32_Process"

    $ProcMap, $ChildMap = @(@{}, @{})
    $ParentQueue = [System.Collections.Generic.Queue[Object]]::New()

    ForEach ($ProcName In $ProcList) {
        $ParentId = [Int]$ProcName.ParentProcessId

        If (-Not $ChildMap.Contains($ParentId)) {
            $ChildMap[$ParentId] = [System.Collections.Generic.List[Object]]::New()
        }

        $ChildMap[$ParentId].Add($ProcName)
    }

    ForEach ($ProcName In $ProcList) {
        If ($ProcName.ExecutablePath -Like "$AppDir*") {
            $ProcId = [Int]$ProcName.ProcessId
            $ProcMap[$ProcId] = 0
            $ParentQueue.Enqueue($ProcName)
        }
    }

    While ($ParentQueue.Count -Gt 0) {
        $ParentProc = $ParentQueue.Dequeue()
        $ParentId = [Int]$ParentProc.ProcessId

        If ($ChildMap.Contains($ParentId)) {
            ForEach ($ChildProc In $ChildMap[$ParentId]) {
                $ChildId = [Int]$ChildProc.ProcessId

                If (-Not $ProcMap.Contains($ChildId)) {
                    $ProcMap[$ChildId] = $ProcMap[$ParentId] + 1
                    $ParentQueue.Enqueue($ChildProc)
                }
            }
        }
    }

    $TargetList = $ProcList | Where-Object {$ProcMap.Contains([Int]$_.ProcessId)}
    $TargetList | Sort-Object {-$ProcMap[[Int]$_.ProcessId]}
}


# ==================================================
# TASK LISTING
# ==================================================

Function Initialize-Workspace {
    Set-Directories
    Set-Environment

    Install-Scoop
    Install-Buckets
    Install-Applications
    Install-Project
    Install-Packages
    Install-Extensions
    Install-Repository

    Update-Configurations
    Write-State
}

Function Update-Workspace {
    If (-Not (Test-Path -LiteralPath $StateFile -PathType "Leaf")) {
        Initialize-Workspace
        Return
    }

    Set-Directories
    Set-Environment

    Repair-Scoop
    Repair-Buckets
    Repair-Applications
    Repair-Project
    Repair-Packages
    Repair-Extensions
    Repair-Repository

    Update-Components
    Update-Configurations
    Write-State
}

Function Debug-Workspace {
    Write-Host "Testing workspace components..." -ForegroundColor "Red"

    ForEach ($TestSection In (Import-Tests).GetEnumerator()) {
        $TestResult = & $TestSection.Value
        Write-Host "`n$($TestSection.Key.ToUpper())" -ForegroundColor "Cyan"

        $OutputFormat = If ($TestResult -Is [Array]) {"Table"} Else {"List"}
        $OutputLines = ($TestResult | & "Format-$OutputFormat" | Out-String).Trim()

        ForEach ($OutputLine In $OutputLines -Split "\r?\n") {
            $OutputColor = If ($OutputLine -Match "\bFalse\b") {"Red"} Else {"Gray"}
            Write-Host $OutputLine -ForegroundColor $OutputColor
        }
    }
}

Function Remove-Workspace {
    $ProcessArguments = @(
        "-NoProfile"
        "-ExecutionPolicy", "Bypass"
        "-File", "`"$PSCommandPath`""
        "-RemoveMode"
        $(If ($WhatIfPreference) {"-WhatIf"})
    )

    $ProcessParameters = @{
        FilePath = "powershell.exe"
        WindowStyle = "Maximized"
        ArgumentList = $ProcessArguments
    }

    Start-Process @ProcessParameters
}


# ==================================================
# TASK DISPATCH
# ==================================================

If ($RemoveMode) {
    $AppList = Invoke-Expression "scoop list" 6> $Null
    $AppList += [PSCustomObject]@{Name = "scoop"}

    $EnvList = "WORKSPACE_ROOT", "XDG_CONFIG_HOME", "NODE_OPTIONS"
    $EnvList += "SCOOP_PATH"

    $ItemFilter = "workspace.ps1", "downloads"
    $ItemList = Get-ChildItem $WorkspaceRoot -Exclude $ItemFilter -Force

    ForEach ($AppEntry In $AppList) {
        Search-Processes -AppName $AppEntry.Name | ForEach-Object {
            Protect-Action "Terminate Process" "$($_.Name):$($_.ProcessId)" {
                Stop-Process $_.ProcessId -ErrorAction "SilentlyContinue" -Force
            }
        }

        Protect-Action "Purge Application" $AppEntry.Name {
            Invoke-Expression "scoop uninstall --purge $($AppEntry.Name)"
        }
    }

    ForEach ($EnvEntry In $EnvList) {
        Protect-Action "Unset Environment" $EnvEntry {
            [Environment]::SetEnvironmentVariable($EnvEntry, $Null, "User")
            [Environment]::SetEnvironmentVariable($EnvEntry, $Null, "Process")
        }
    }

    ForEach ($ItemEntry In $ItemList) {
        Protect-Action "Remove Item" $ItemEntry.FullName {
            Remove-Item $ItemEntry.FullName -Recurse -Force
        }
    }

    Write-Host "`nPress any key to close this window..." -ForegroundColor "Yellow"
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null; Exit
}

Switch ($TaskMode) {
    "Initialize" {Initialize-Workspace}
    "Update" {Update-Workspace}
    "Debug" {Debug-Workspace}
    "Remove" {Remove-Workspace}
}
