<#
.SYNOPSIS
    Stage 1 - Active Directory Domain Controller on Windows Server Core.

.DESCRIPTION
    Deploys the first domain controller of a new forest (lab.local) in a
    VMware Workstation lab. Commands are listed in the order they were
    actually executed, including the DNS fix that was required after promotion.

.NOTES
    Lab environment only. Run as Administrator.
    The host reboots after Rename-Computer and again after Install-ADDSForest.
    Install-ADDSForest prompts for the DSRM password interactively - it is
    never stored in this file.
#>

# --- Baseline: roles installed before we start ---
Get-WindowsFeature | Where-Object Installed | Select-Object Name

# --- Step 1. Rename the host ---
Rename-Computer -NewName "DC01" -Restart

# --- Step 2. Static IP configuration ---
# InterfaceIndex 6 on this VM - find yours with: Get-NetAdapter
New-NetIPAddress -InterfaceIndex 6 -IPAddress 192.168.2.10 `
    -PrefixLength 24 `
    -DefaultGateway 192.168.2.2

# VMware NAT resolver - temporary, replaced in Step 5
Set-DnsClientServerAddress -InterfaceIndex 6 -ServerAddresses 192.168.2.2

Get-NetIPAddress -InterfaceIndex 6 -AddressFamily IPv4

# --- Step 3. Install the AD DS role ---
# -IncludeManagementTools is required, otherwise the RSAT-AD-PowerShell module
# is missing and Get-ADDomain / Get-ADUser are not available after promotion.
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Get-WindowsFeature AD-Domain-Services, RSAT-AD-PowerShell

# --- Step 4. Promote to the first DC in a new forest ---
# Prompts for the DSRM password.
Install-ADDSForest `
    -DomainName "lab.local" `
    -DomainNetbiosName "LAB" `
    -InstallDNS `
    -Force

# --- Step 5. Point DNS at itself ---
# After promotion the DC hosts its own AD-integrated zone and must resolve
# through 127.0.0.1, not through the NAT resolver set in Step 2.
Set-DnsClientServerAddress -InterfaceIndex 6 -ServerAddresses 127.0.0.1
Get-DnsClientServerAddress -AddressFamily IPv4

# --- Step 6. Verification ---
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode, InfrastructureMaster
Get-Service NTDS, ADWS, Netlogon, DNS
Get-DnsServerZone | Format-Table ZoneName, ZoneType, IsDsIntegrated -AutoSize
whoami