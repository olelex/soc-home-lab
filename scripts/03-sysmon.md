<#

.SYNOPSIS

&#x20;   Stage 3 - Sysmon deployment on CLIENT01 and DC01.



.DESCRIPTION

&#x20;   Installs Sysmon with the sysmon-modular configuration by Olaf Hartong,

&#x20;   then generates and reviews discovery-style telemetry.



.NOTES

&#x20;   Lab environment. Run as Administrator.

\#>



\# --- Step 1. Download Sysmon and configuration ---

Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "$env:TEMP\\Sysmon.zip"

Expand-Archive "$env:TEMP\\Sysmon.zip" -DestinationPath "C:\\Tools\\Sysmon" -Force



Invoke-WebRequest -Uri "https://raw.githubusercontent.com/olafhartong/sysmon-modular/master/sysmonconfig.xml" `

&#x20;   -OutFile "C:\\Tools\\Sysmon\\sysmonconfig.xml"



\# --- Step 2. Install ---

cd C:\\Tools\\Sysmon

.\\Sysmon64.exe -accepteula -i sysmonconfig.xml



\# --- Step 3. Verify the service and the log ---

Get-Service Sysmon64

Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5 |

&#x20;   Format-List TimeCreated, Id, Message



\# --- Step 4. Generate discovery telemetry ---

\# T1033 - System Owner/User Discovery

whoami /all

\# T1087.001 - Account Discovery: Local Account

net user

\# T1027 - Obfuscated Files or Information (base64 for "whoami")

powershell -enc dwBoAG8AYQBtAGkA



\# --- Step 5. Review process creation events ---

Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Sysmon/Operational"; ID=1} -MaxEvents 20 |

&#x20;   ForEach-Object { $\_.Properties\[10].Value }



\# Full detail of a single event - parent process, hashes, user, working directory

Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Sysmon/Operational"; ID=1} -MaxEvents 1 |

&#x20;   Format-List \*

