<#
.SYNOPSIS
    Launches an eRemote session to a specific endpoint.

.DESCRIPTION
    This script is designed for TECHNICIAN use to quickly connect
    to an endpoint via its eRemote ID.
    
    Can be run from NinjaOne to launch a remote session to the
    currently selected device.
    
    SECURITY: No secrets are embedded. Connection uses public key
    authentication configured on the server.

.PARAMETER RemoteID
    The eRemote ID of the target endpoint.
    In NinjaOne, use custom field: eRemoteID

.PARAMETER Server
    The eRemote server address (optional, uses default if not specified).

.EXAMPLE
    .\Launch-eRemote.ps1 -RemoteID "123456789"
    
.EXAMPLE
    # From NinjaOne, variables are auto-populated:
    .\Launch-eRemote.ps1

.NOTES
    This script should be run on the TECHNICIAN workstation,
    not on the endpoint being connected to.
    
    NinjaOne Setup:
    1. Create custom field "eRemoteID" on devices
    2. Use this script in a "Run on This Device" policy for technicians
    3. Pass $eRemoteID from the target device context
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RemoteID = $env:eRemoteID,
    
    [Parameter(Mandatory = $false)]
    [string]$Server = $env:eRemoteServer
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

function Find-eRemoteExe {
    $possiblePaths = @(
        "$env:ProgramFiles\eRemote\eRemote.exe",
        "$env:ProgramFiles\RustDesk\rustdesk.exe",
        "${env:ProgramFiles(x86)}\eRemote\eRemote.exe",
        "$env:LOCALAPPDATA\eRemote\eRemote.exe",
        "$env:USERPROFILE\Desktop\eRemote.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Try to find in PATH
    $inPath = Get-Command "eRemote.exe" -ErrorAction SilentlyContinue
    if ($inPath) {
        return $inPath.Source
    }
    
    $inPath = Get-Command "rustdesk.exe" -ErrorAction SilentlyContinue
    if ($inPath) {
        return $inPath.Source
    }
    
    return $null
}

try {
    Write-Log "=== eRemote Session Launcher ==="
    
    # Validate remote ID
    if ([string]::IsNullOrWhiteSpace($RemoteID)) {
        throw "Remote ID is required. Pass -RemoteID parameter or set eRemoteID environment variable."
    }
    
    # Clean up the ID (remove any whitespace)
    $RemoteID = $RemoteID.Trim()
    
    Write-Log "Target ID: $RemoteID"
    
    # Find eRemote executable
    $exePath = Find-eRemoteExe
    
    if (-not $exePath) {
        throw "eRemote is not installed. Please install eRemote first using Install-eRemote.ps1"
    }
    
    Write-Log "Using: $exePath"
    
    # Build connection command
    # RustDesk/eRemote supports connecting via: rustdesk.exe --connect <ID>
    $arguments = @("--connect", $RemoteID)
    
    # Add server if specified
    if (-not [string]::IsNullOrWhiteSpace($Server)) {
        Write-Log "Server: $Server"
        # Note: Server should already be configured via Configure-eRemote.ps1
        # but we can pass it explicitly for one-time connections
    }
    
    Write-Log "Launching connection to: $RemoteID"
    
    # Start eRemote connection
    Start-Process -FilePath $exePath -ArgumentList $arguments
    
    Write-Log "Connection initiated. eRemote window should open shortly."
    Write-Log "=== Launch Complete ==="
    
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    
    # Provide helpful error messages
    if ($_.Exception.Message -like "*Remote ID is required*") {
        Write-Log ""
        Write-Log "USAGE: .\Launch-eRemote.ps1 -RemoteID <ID>"
        Write-Log ""
        Write-Log "Get the Remote ID from:"
        Write-Log "  - NinjaOne custom field: eRemoteID"
        Write-Log "  - The eRemote app on the target device"
        Write-Log "  - Your eRemote server admin panel"
    }
    
    exit 1
}
