# eRemote NinjaOne Deployment Guide

This guide covers deploying eRemote to endpoints via NinjaOne and enabling technician access.

## Overview

eRemote integrates with NinjaOne to provide:
- **Automated deployment** to all managed endpoints
- **Centralized inventory** via NinjaOne custom fields
- **One-click remote access** for technicians

### Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         NinjaOne                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │  Device A   │    │  Device B   │    │  Device C   │  ...        │
│  │ eRemoteID:  │    │ eRemoteID:  │    │ eRemoteID:  │             │
│  │  123456789  │    │  987654321  │    │  456789123  │             │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘             │
└─────────┼──────────────────┼──────────────────┼─────────────────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                    ┌────────▼────────┐
                    │  eRemote Server │
                    │  (Your EC2)     │
                    └────────▲────────┘
                             │
                    ┌────────┴────────┐
                    │  Technician PC  │
                    │  (eRemote App)  │
                    └─────────────────┘
```

## Prerequisites

1. eRemote server deployed and running (see [deploy-ec2.md](../eremote-server/docs/deploy-ec2.md))
2. NinjaOne admin access
3. eRemote Windows client available for download

## Step 1: Configure NinjaOne Custom Fields

Create these custom fields in NinjaOne:

### Required Fields

| Field Name | Type | Scope | Description |
|------------|------|-------|-------------|
| `eRemoteServer` | Text | Organization | Your eRemote server hostname/IP |
| `eRemoteID` | Text | Device | Populated by Configure script |

### Optional Fields

| Field Name | Type | Scope | Description |
|------------|------|-------|-------------|
| `eRemoteUnattendedPassword` | Secure | Device | For unattended access (optional) |
| `eRemoteRelayServer` | Text | Organization | If relay differs from ID server |

### Setting Organization-Level Server Address

1. Go to **Administration** → **Custom Fields**
2. Create field `eRemoteServer` (Type: Text, Scope: Organization)
3. Go to each organization → **Custom Fields**
4. Set `eRemoteServer` to your server IP (e.g., `44.193.201.152`)

## Step 2: Upload Scripts to NinjaOne

Upload the three PowerShell scripts from `/ninja/windows/`:

### A. Install-eRemote.ps1
- **Purpose**: Downloads and installs eRemote client
- **Run as**: System
- **Parameters**: None (uses default download URL)

### B. Configure-eRemote.ps1
- **Purpose**: Configures server connection, outputs device ID
- **Run as**: System
- **Parameters**: Uses `eRemoteServer` custom field automatically

### C. Launch-eRemote.ps1
- **Purpose**: Initiates remote session to a device
- **Run as**: Current User (technician workstation)
- **Parameters**: Uses `eRemoteID` from target device

## Step 3: Create Deployment Policy

### For Endpoint Installation

1. Go to **Policies** → Create new policy
2. Add **Scheduled Script**:
   - Script: `Install-eRemote.ps1`
   - Schedule: Once, or on device first check-in
3. Add **Scheduled Script** (runs after install):
   - Script: `Configure-eRemote.ps1`
   - Schedule: 5 minutes after install script
4. Assign policy to target organizations/devices

### For Existing Devices (One-Time)

1. Select devices in **Devices** view
2. Click **Run Script**
3. Run `Install-eRemote.ps1`
4. Wait for completion
5. Run `Configure-eRemote.ps1`

## Step 4: Verify Deployment

After deployment completes:

1. Check device custom fields for `eRemoteID` value
2. Verify in NinjaOne device view that ID is populated
3. Test connection from technician workstation

### Manual Verification on Endpoint

```powershell
# Check if eRemote is installed
Get-Service eRemote

# Check configuration file
Get-Content "$env:APPDATA\eRemote\config\eRemote.toml"

# Get device ID
& "$env:ProgramFiles\eRemote\eRemote.exe" --get-id
```

## Step 5: Technician Access Setup

### Install eRemote on Technician Workstations

1. Download eRemote for Windows from releases
2. Install on technician workstation
3. Run `Configure-eRemote.ps1` with your server address

### Connecting to Endpoints

**Option A: From NinjaOne (Recommended)**
1. Select device in NinjaOne
2. Copy `eRemoteID` from custom fields
3. Run `Launch-eRemote.ps1` with the ID
   - Or: Open eRemote app and paste ID

**Option B: Direct Connection**
1. Open eRemote on technician workstation
2. Enter the endpoint's eRemote ID
3. Click Connect

## Security Considerations

### What's Stored Where

| Data | Location | Security |
|------|----------|----------|
| Server address | NinjaOne custom field | Organization-level |
| Device ID | NinjaOne custom field | Read-only after set |
| Unattended password | NinjaOne secure field | Encrypted |
| Server private key | EC2 host volume | Never leaves server |

### Best Practices

1. **Never hardcode passwords** in scripts
2. **Use NinjaOne secure fields** for unattended passwords
3. **Rotate passwords** periodically via NinjaOne
4. **Monitor connections** via eRemote server logs
5. **Restrict server access** to known IP ranges if possible

## Workflow Examples

### Deploy to New Customer

```
1. Add customer organization in NinjaOne
2. Set eRemoteServer custom field for organization
3. Apply deployment policy to organization
4. Devices auto-install and configure on next check-in
```

### Connect to Device for Support

```
1. Open device in NinjaOne
2. Copy eRemoteID from device custom fields
3. On technician workstation: .\Launch-eRemote.ps1 -RemoteID <ID>
   OR paste ID into eRemote app
4. Session connects through your server
```

### Emergency Password Reset

```
1. In NinjaOne, update device's eRemoteUnattendedPassword field
2. Run Configure-eRemote.ps1 on the device
3. New password takes effect immediately
```

## Troubleshooting

### Device Not Getting ID

```powershell
# Check if service is running
Get-Service eRemote

# Check logs
Get-EventLog -LogName Application -Source "eRemote" -Newest 20

# Re-run configuration
& "C:\path\to\Configure-eRemote.ps1"
```

### Can't Connect to Device

1. Verify device is online in NinjaOne
2. Check `eRemoteID` is populated
3. Verify server is reachable: `Test-NetConnection -ComputerName YOUR_SERVER -Port 21116`
4. Check security group allows traffic

### Script Fails in NinjaOne

1. Check script output in NinjaOne activity log
2. Verify script runs as System (not User)
3. Check custom fields are set at correct scope (Org vs Device)

## Inventory and Reporting

### Finding All eRemote IDs

1. Go to **Devices** in NinjaOne
2. Add `eRemoteID` column to view
3. Export to CSV for inventory

### Devices Without eRemote

1. Filter devices where `eRemoteID` is empty
2. These devices need deployment policy applied

## Uninstallation

To remove eRemote from devices:

```powershell
# Stop and remove service
Stop-Service eRemote -Force
& "$env:ProgramFiles\eRemote\eRemote.exe" --uninstall

# Clean up files
Remove-Item -Path "$env:ProgramFiles\eRemote" -Recurse -Force
Remove-Item -Path "$env:APPDATA\eRemote" -Recurse -Force
```

Create this as a script in NinjaOne for bulk uninstallation if needed.
