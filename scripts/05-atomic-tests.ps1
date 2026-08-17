<#
.SYNOPSIS
    Stage 5 - Detection testing with Atomic Red Team on CLIENT01.

.DESCRIPTION
    Installs invoke-atomicredteam and runs four ATT&CK techniques, recording
    timestamps so the resulting events can be located in Wazuh.

.NOTES
    Lab environment. Run as Administrator on CLIENT01 only - never on a
    domain controller. Take a VM snapshot before running.
    The Defender exclusion below is acceptable in a lab; in production,
    creating exclusions is itself a common attacker action.
#>

# --- Step 1. Install ---
Add-MpPreference -ExclusionPath "C:\AtomicRedTeam"
Set-ExecutionPolicy Bypass -Scope Process -Force

IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing)
Install-AtomicRedTeam -getAtomics -Force

Import-Module "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force

# --- Step 2. T1059.001 - Obfuscated PowerShell ---
Invoke-AtomicTest T1059.001 -TestNumbers 15 -ShowDetails
Invoke-AtomicTest T1059.001 -TestNumbers 15 -CheckPrereqs
Get-Date
Invoke-AtomicTest T1059.001 -TestNumbers 15
Invoke-AtomicTest T1059.001 -TestNumbers 15 -Cleanup

# --- Step 3. T1136.001 - Create Local Account ---
Invoke-AtomicTest T1136.001 -TestNumbers 4 -CheckPrereqs
Get-Date
Invoke-AtomicTest T1136.001 -TestNumbers 4
Invoke-AtomicTest T1136.001 -TestNumbers 4 -Cleanup

# --- Step 4. T1053.005 - Scheduled Task ---
Invoke-AtomicTest T1053.005 -TestNumbers 2 -CheckPrereqs
Get-Date
Invoke-AtomicTest T1053.005 -TestNumbers 2
Invoke-AtomicTest T1053.005 -TestNumbers 2 -Cleanup

# --- Step 5. T1087.001 - Account Discovery ---
Invoke-AtomicTest T1087.001 -TestNumbers 8 -CheckPrereqs
Get-Date
Invoke-AtomicTest T1087.001 -TestNumbers 8
Invoke-AtomicTest T1087.001 -TestNumbers 8 -Cleanup

# --- Step 6. Verify cleanup independently ---
# "Done executing cleanup" only means the command ran, not that it worked.
Get-LocalUser
Get-ScheduledTask -TaskName spawn -ErrorAction SilentlyContinue