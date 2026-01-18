<#
.SYNOPSIS
    Installs eRemote client silently on Windows endpoints.

.DESCRIPTION
    This script is designed to be run via NinjaOne or similar RMM tools.
    It downloads and installs eRemote silently without user interaction.
    
    SECURITY: No secrets are embedded in this script.
    Configuration is done separately via Configure-eRemote.ps1.

.NOTES
    Run this script with elevated (Administrator) privileges.
    
    NinjaOne Deployment:
    1. Upload this script to NinjaOne script library
    2. Create a scheduled task or run on-demand
    3. Run Configure-eRemote.ps1 after installation
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$DownloadUrl = "https://github.com/Celeratec/eRemote/releases/latest/download/eRemote-windows-x86_64.exe",
    
    [Parameter()]
    [string]$InstallPath = "$env:ProgramFiles\eRemote"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

try {
    Write-Log "=== eRemote Installation Starting ==="
    
    # Check for admin privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw "This script requires Administrator privileges. Please run as Administrator."
    }
    
    # Create installation directory
    Write-Log "Creating installation directory: $InstallPath"
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }
    
    # Download eRemote
    $installerPath = Join-Path $env:TEMP "eRemote-installer.exe"
    Write-Log "Downloading eRemote from: $DownloadUrl"
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $installerPath -UseBasicParsing
    
    if (-not (Test-Path $installerPath)) {
        throw "Download failed - installer not found"
    }
    
    Write-Log "Download complete: $installerPath"
    
    # Stop existing eRemote service if running
    $serviceName = "eRemote"
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Log "Stopping existing eRemote service..."
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    
    # Run installer silently
    Write-Log "Running installer..."
    $installArgs = "--silent-install"
    $process = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -ne 0) {
        # Try alternative installation method
        Write-Log "Standard install returned exit code $($process.ExitCode), trying direct copy..."
        Copy-Item -Path $installerPath -Destination (Join-Path $InstallPath "eRemote.exe") -Force
    }
    
    # Verify installation
    $exePath = Join-Path $InstallPath "eRemote.exe"
    if (-not (Test-Path $exePath)) {
        # Check common installation locations
        $possiblePaths = @(
            "$env:ProgramFiles\eRemote\eRemote.exe",
            "$env:ProgramFiles\RustDesk\rustdesk.exe",
            "${env:ProgramFiles(x86)}\eRemote\eRemote.exe"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $exePath = $path
                Write-Log "Found eRemote at: $exePath"
                break
            }
        }
    }
    
    if (Test-Path $exePath) {
        Write-Log "eRemote installed successfully at: $exePath"
    } else {
        Write-Log "WARNING: Could not verify installation location"
    }
    
    # Clean up installer
    Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
    
    # Start service if it exists
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Log "Starting eRemote service..."
        Start-Service -Name $serviceName -ErrorAction SilentlyContinue
    }
    
    Write-Log "=== eRemote Installation Complete ==="
    Write-Log "Next step: Run Configure-eRemote.ps1 to configure server settings"
    
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
