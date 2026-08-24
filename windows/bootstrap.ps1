[CmdletBinding()]
param(
    [switch]$SkipFont
)

$ErrorActionPreference = "Stop"

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    $installed = winget list --id $Id --exact --source winget --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and $installed -match [regex]::Escape($Id)) {
        Write-Host "Already installed: $Id"
        return
    }

    Write-Host "Installing: $Id"
    winget install --id $Id --exact --source winget `
        --accept-source-agreements --accept-package-agreements `
        --disable-interactivity
}

Install-WingetPackage "Microsoft.WSL"
Install-WingetPackage "Microsoft.WindowsTerminal"
Install-WingetPackage "Tailscale.Tailscale"
Install-WingetPackage "Docker.DockerDesktop"
Install-WingetPackage "WiresharkFoundation.Wireshark"
Install-WingetPackage "Nmap.Npcap"
Install-WingetPackage "NationalSecurityAgency.Ghidra"

if (-not $SkipFont) {
    $fontDirectory = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    New-Item -ItemType Directory -Force -Path $fontDirectory | Out-Null

    $fontUrls = @(
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf",
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf",
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf",
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
    )

    foreach ($url in $fontUrls) {
        $fileName = [System.IO.Path]::GetFileName(($url -split "\?")[0])
        $destination = Join-Path $fontDirectory $fileName
        if (-not (Test-Path $destination)) {
            Invoke-WebRequest -Uri $url -OutFile $destination
        }

        $fontName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" `
            -Name $fontName -Value $destination -PropertyType String -Force | Out-Null
    }
}

Write-Host ""
Write-Host "Next steps"
Write-Host "1. Put windows\.wslconfig at $env:USERPROFILE\.wslconfig."
Write-Host "2. Restart WSL with: wsl --shutdown"
Write-Host "3. Enable Docker Desktop's WSL integration for this distribution."
Write-Host "4. Docker Sandbox is shipped with supported Docker Desktop releases; check with: docker sandbox --help"
Write-Host "5. Set Windows Terminal's font face to MesloLGS Nerd Font."
