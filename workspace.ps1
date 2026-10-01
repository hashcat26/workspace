$ErrorActionPreference = "Continue"
$WarningPreference = "Continue"

$WorkspaceRoot = $PSScriptRoot
$ConfigHome = Join-Path $WorkspaceRoot ".xdg"
$ConfigsDir = Join-Path $WorkspaceRoot "configs"
$ScriptsDir = Join-Path $WorkspaceRoot "downloads\scripts"
$PackagesDir = Join-Path $WorkspaceRoot "packages"
$UtilitiesDir = Join-Path $WorkspaceRoot "utilities"

$WorkspaceDirs = @(
    (Join-Path $WorkspaceRoot "binaries")
    $ConfigHome
    $ConfigsDir
    $ScriptsDir
    $PackagesDir
    $UtilitiesDir
)

ForEach ($WorkspaceDir In $WorkspaceDirs) {
    New-Item -Path $WorkspaceDir -ItemType Directory -Force | Out-Null
}

$Env:WORKSPACE_ROOT = $WorkspaceRoot
$Env:XDG_CONFIG_HOME = $ConfigHome
$Env:NODE_OPTIONS = "--no-deprecation"

[Environment]::SetEnvironmentVariable("WORKSPACE_ROOT", $WorkspaceRoot, "User")
[Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", $ConfigHome, "User")


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


Function Install-Scoop {
    Invoke-RestMethod "https://get.scoop.sh" -OutFile $ScoopFile
    & $ScoopFile -ScoopDir $PackagesDir

    Invoke-Expression "scoop config use_isolated_path true"
    Invoke-Expression "scoop config aria2-warning-enabled false"
}

Function Test-Scoop {
    $PrefixDir = Invoke-Expression "scoop prefix scoop"
    $ConfigList = Invoke-Expression "scoop config"

    [PSCustomObject]@{
        ScoopInstalled = $PrefixDir -Eq $ScoopDir
        PathIsolated = $ConfigList.'use_isolated_path' -Eq $True
        WarningDisabled = $ConfigList.'aria2-warning-enabled' -Eq $False
    }
}

Function Repair-Scoop {
    $ScoopState = $WorkspaceState.Scoop

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


Function Install-Buckets {
    Write-Host "Adding Scoop buckets..."

    Invoke-Expression "scoop install 7zip git" *> $Null
    Invoke-Expression "scoop bucket add extras"
    Invoke-Expression "scoop bucket add hashcat $BucketUrl"
    Invoke-Expression "scoop uninstall --purge 7zip git" *> $Null
}

Function Test-Buckets {
    $BucketList = Invoke-Expression "scoop bucket list"

    [PSCustomObject]@{
        ExtrasInstalled = $BucketList.Name -Contains "extras"
        HashcatInstalled = $BucketList.Name -Contains "hashcat"
    }
}

Function Repair-Buckets {
    $BucketState = $WorkspaceState.Buckets

    If (-Not $BucketState.ExtrasInstalled) {
        Invoke-Expression "scoop bucket add extras"
    }
    If (-Not $BucketState.HashcatInstalled) {
        Invoke-Expression "scoop bucket add hashcat $BucketUrl"
    }
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

Function Repair-Applications {
    $AppState = $WorkspaceState.Applications
    $AppEntries = $AppState | Where-Object {-Not $_.AppInstalled}

    ForEach ($AppEntry In $AppEntries) {
        Invoke-Expression "scoop install hashcat/$($AppEntry.AppName)"
    }
}


Function Install-Project {
    Invoke-Expression "uv init --bare --no-readme --directory `"$UtilitiesDir`""
    Invoke-Expression "uv lock --directory `"$UtilitiesDir`""
}

Function Test-Project {
    Invoke-Expression "uv lock --check --directory `"$UtilitiesDir`"" *> $Null
    $LockState = $LASTEXITCODE -Eq 0

    Invoke-Expression "uv sync --check --directory `"$UtilitiesDir`"" *> $Null
    $VenvState = $LASTEXITCODE -Eq 0

    [PSCustomObject]@{
        ProjectCreated = Test-Path -LiteralPath $ProjectFile -PathType Leaf
        LockCreated = Test-Path -LiteralPath $LockFile -PathType Leaf
        LockValidated = $LockState
        VenvSynced = $VenvState
    }
}

Function Repair-Project {
    $ProjectState = $WorkspaceState.Project

    If (-Not $ProjectState.ProjectCreated) {
        Invoke-Expression "uv init --bare --no-readme --directory `"$UtilitiesDir`""
    }
    If (-Not $ProjectState.LockCreated -Or -Not $ProjectState.LockValidated) {
        Invoke-Expression "uv lock --directory `"$UtilitiesDir`""
    }
    If (-Not $ProjectState.VenvSynced) {
        Invoke-Expression "uv sync --directory `"$UtilitiesDir`""
    }
}


Function Install-Packages {
    ForEach ($PkgName In $PkgList) {
        Invoke-Expression "uv add $PkgName --directory `"$UtilitiesDir`""
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

Function Repair-Packages {
    $PkgState = $WorkspaceState.Packages
    $PkgEntries = $PkgState | Where-Object {-Not $_.PkgInstalled}

    ForEach ($PkgEntry In $PkgEntries) {
        Invoke-Expression "uv add $($PkgEntry.PkgName) --directory `"$UtilitiesDir`""
    }
}


Function Install-Extensions {
    ForEach ($ExtName In $ExtList) {
        Invoke-Expression "code --install-extension $ExtName"
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

Function Repair-Extensions {
    $ExtState = $WorkspaceState.Extensions
    $ExtEntries = $ExtState | Where-Object {-Not $_.ExtInstalled}

    ForEach ($ExtEntry In $ExtEntries) {
        Invoke-Expression "code --install-extension $($ExtEntry.ExtName)"
    }
}


Function Install-Repository {
    Invoke-Expression "git init --initial-branch master"
    Invoke-Expression "git remote add origin $WorkspaceUrl"
    Invoke-Expression "git fetch origin"
    Invoke-Expression "git checkout --force master"
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

Function Repair-Repository {
    $RepositoryState = $WorkspaceState.Repository

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


Function Update-Components {
    Invoke-Expression "scoop update scoop"
    Invoke-Expression "scoop update --all"
    Invoke-Expression "scoop cleanup --all"
    Invoke-Expression "scoop cache rm --all"

    Invoke-Expression "uv sync --upgrade --directory `"$UtilitiesDir`""
    Invoke-Expression "code --update-extensions"
    Invoke-Expression "git pull --ff-only"
}

Function Copy-Configurations {
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

        New-Item -Path (Split-Path $DestFile) -ItemType Directory -Force | Out-Null
        Copy-Item -LiteralPath $SrcFile -Destination $DestFile -Force
    }

    $UserDir = Join-Path $CodeDir "data\user-data\User"
    $CodeFiles = "keybindings.json", "settings.json", "tasks.json"

    ForEach ($CodeFile In $CodeFiles) {
        $SrcFile = Join-Path $ConfigsDir $CodeFile
        $DestFile = Join-Path $UserDir $CodeFile

        New-Item -Path (Split-Path $DestFile) -ItemType Directory -Force | Out-Null
        Copy-Item -LiteralPath $SrcFile -Destination $DestFile -Force
    }
}

Function Read-State {
    Write-Host "Checking workspace state..."

    [PSCustomObject]@{
        Scoop = Test-Scoop
        Buckets = Test-Buckets
        Applications = @(Test-Applications)
        Project = Test-Project
        Packages = @(Test-Packages)
        Extensions = @(Test-Extensions)
        Repository = Test-Repository
    }
}

Function Write-State {
    $WorkspaceState = Read-State
    $WorkspaceState | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $StateFile

    Write-Host "Workspace state saved to $StateFile"
}


If (-Not (Test-Path -LiteralPath $StateFile -PathType Leaf)) {
    Install-Scoop
    Install-Buckets
    Install-Applications
    Install-Project
    Install-Packages
    Install-Extensions
    Install-Repository

    Copy-Configurations
    Write-State
}

Else {
    $WorkspaceState = Read-State

    Repair-Scoop
    Repair-Buckets
    Repair-Applications
    Repair-Project
    Repair-Packages
    Repair-Extensions
    Repair-Repository

    Update-Components
    Copy-Configurations
    Write-State
}
