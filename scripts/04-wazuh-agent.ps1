<#
.SYNOPSIS
    Stage 4 - Wazuh agent deployment on CLIENT01.

.DESCRIPTION
    Installs the Wazuh Windows agent, enrols it with the manager at
    192.168.2.128, and adds the Sysmon event channel to the agent
    configuration so process-creation telemetry reaches the SIEM.

.NOTES
    Lab environment. Run as Administrator.
    The Wazuh server itself was installed on Ubuntu with the all-in-one
    assistant: curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
                sudo bash ./wazuh-install.sh -a
#>

# --- Step 1. Download the agent ---
Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.9.0-1.msi" `
    -OutFile "$env:TEMP\wazuh-agent.msi"

# --- Step 2. Install and enrol ---
msiexec.exe /i "$env:TEMP\wazuh-agent.msi" /q `
    WAZUH_MANAGER="192.168.2.128" `
    WAZUH_AGENT_NAME="CLIENT01"

Start-Service WazuhSvc
Get-Service WazuhSvc

# --- Step 3. Add the Sysmon channel ---
# Wazuh does not read Microsoft-Windows-Sysmon/Operational by default.
# The following block was added inside <ossec_config> in
# C:\Program Files (x86)\ossec-agent\ossec.conf:
#
#   <localfile>
#     <location>Microsoft-Windows-Sysmon/Operational</location>
#     <log_format>eventchannel</log_format>
#   </localfile>
#
notepad "C:\Program Files (x86)\ossec-agent\ossec.conf"
Restart-Service WazuhSvc

# --- Step 4. Generate a test event ---
# T1027 - Obfuscated Files or Information (base64 for "whoami")
powershell -enc dwBoAG8AYQBtAGkA

# --- Step 5. Verification (run on the Wazuh server) ---
# sudo /var/ossec/bin/agent_control -l
#
# Hunting query used in the dashboard:
# agent.name: CLIENT01 AND data.win.eventdata.commandLine: *enc*