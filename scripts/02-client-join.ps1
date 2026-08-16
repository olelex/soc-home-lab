<#
.SYNOPSIS
    Stage 2 - Windows 11 client rename and domain join.

.DESCRIPTION
    Prepares CLIENT01 as a domain member workstation in lab.local.
    The IP address comes from the VMware NAT DHCP pool; only the DNS
    server is set manually so the client can resolve domain SRV records.

.NOTES
    Lab environment. Run as Administrator.
    The host reboots after Rename-Computer and again after Add-Computer.
    Add-Computer prompts for domain credentials interactively.
#>

# --- Step 1. Rename the host ---
Rename-Computer -NewName "CLIENT01" -Restart

# --- Step 2. Point DNS at the domain controller ---
# InterfaceIndex 13 on this VM - find yours with: Get-NetAdapter
# The gateway (192.168.2.2) is the VMware NAT resolver and knows nothing
# about lab.local, so the client must query DC01 directly.
Set-DnsClientServerAddress -InterfaceIndex 13 -ServerAddresses 192.168.2.10
Get-DnsClientServerAddress -InterfaceIndex 13

# --- Step 3. Join the domain ---
# Prompts for domain credentials.
Add-Computer -DomainName "lab.local" -Credential (Get-Credential) -Restart

# --- Step 4. Verification ---
$env:COMPUTERNAME
whoami
Get-ComputerInfo | Select-Object CsDomain, CsDomainRole
nltest /dsgetdc:lab.local
w32tm /query /status
Test-ComputerSecureChannel -Verbose