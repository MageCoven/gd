#! /opt/microsoft/powershell/7/pwsh

# Define all the flags and arguments
param(
    [Parameter(ValueFromPipeline)]
    [Alias("t")]
    [string]$Target,

    [Parameter(ValueFromPipeline, HelpMessage = "Path to associate target with")]
    [Alias("p")]
    [string]$Path,

    [Parameter(HelpMessage = "Path to the config file")]
    [Alias("c")]
    [string]$Config,

    [Parameter(HelpMessage = "Delete target")]
    [switch]$Delete = $False,

    [Parameter(HelpMessage = "List all targets")]
    [Alias("ls")]
    [switch]$List = $False
)

# Set £config to default value of "~/.gd/config.json"
if (-not($Config)) {
    $Config = "~/.gd/config.json"
}

# Create config file if default one does not exist, if a custom path is used do not create one
if (-not(Test-Path -Path $Config -PathType Leaf)) {
    if ($Config -eq "~/.gd/config.json") {
        New-Item -ItemType Directory -Force -Path "~/.gd/" | out-null
        Write-Output "{`n    `"targets`": {}`n}" | Out-File -FilePath $Config
    }
    else {
        Write-Error "ERROR: Config file `"$Config`" does not exist"
        exit 1
    }
}

# Get the config data
$configObject = (Get-Content -Raw -Path $Config | ConvertFrom-Json)

# Test for missing targets property
if (-not($configObject.targets)) {
    $configObject | Add-Member -NotePropertyName "targets" -NotePropertyValue @{}
    Write-Output $configObject | ConvertTo-Json | Out-File -FilePath $Config
    Write-Error "ERROR: Config file missing targets property, adding an empty one"
    exit 1
}

# Add target
if ($Target -and $Path) {
    $configObject.targets | Add-Member -Force -NotePropertyName $Target -NotePropertyValue $Path
    Write-Output $configObject | ConvertTo-Json | Out-File -FilePath $Config
    exit 0
}

# Change directory to target's path
if ($Target -and -not($Delete) -and -not($List)) {
    if (-not($configObject.targets | Select-Object -ExpandProperty $Target)) {
        Write-Error "ERROR: Target `"$Target`" not defined"
        exit 1
    }

    $configObject.targets | Select-Object -ExpandProperty $Target | Set-Location
    exit 0
}

# Change directory to path if only path was specified
if ($Path) {
    Set-Location $Path
    exit 0
}

# Delete target
if ($Delete) {
    if (-not($Target)) {
        Write-Error "ERROR: Cannot delete without a specified target"
        exit 1
    }

    if (-not($configObject.targets | Select-Object -ExpandProperty $Target)) {
        Write-Error "ERROR: Target `"$Target`" is not defined"
        exit 1
    }

    $configObject.targets.PSObject.Properties.Remove($Target)
    Write-Output $configObject | ConvertTo-Json | Out-File -FilePath $Config
    exit 0
}

# List target's path
if ($List -and $Target) {
    if (-not($configObject.targets | Select-Object -ExpandProperty $Target)) {
        Write-Error "ERROR: Target `"$Target`" not defined"
        exit 1
    }

    $configObject.targets | Select-Object -ExpandProperty $Target | Write-Output
    exit 0
}

# List all targets
if ($List) {
    $result = $configObject.targets.PSObject.Properties | Select-Object -ExpandProperty Name
    Write-Output $result
    exit 0
}