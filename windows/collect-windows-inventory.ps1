[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path (Get-Location) "windows-inventory")
)

$ErrorActionPreference = "Continue"
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

function Save-CommandOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command
    )

    & $Command 2>&1 | Out-File -Encoding utf8 (Join-Path $OutputDirectory $Name)
}

$wingetExport = Join-Path $OutputDirectory "winget-export.json"
winget export --output $wingetExport --include-unknown --accept-source-agreements

Save-CommandOutput "winget-list.txt" {
    winget list --accept-source-agreements
}

Save-CommandOutput "wsl-list.txt" {
    wsl --list --verbose
}

Save-CommandOutput "wsl-status.txt" {
    wsl --status
}

Save-CommandOutput "windows-version.txt" {
    Get-ComputerInfo -Property WindowsProductName,WindowsVersion,OsBuildNumber,OsArchitecture
}

Save-CommandOutput "powershell-version.txt" {
    $PSVersionTable
}

Save-CommandOutput "path.txt" {
    $env:Path -split [IO.Path]::PathSeparator
}

Write-Host "Inventory written to $OutputDirectory"
Write-Host "For a full WSL emergency backup, stop WSL first, then run:"
Write-Host "  wsl --shutdown"
Write-Host "  wsl --export <distribution-name> <backup-path>.vhdx --vhd"
