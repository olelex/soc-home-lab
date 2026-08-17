# Stage 4 — Wazuh SIEM and Agent Deployment

## Goal

Centralised collection makes correlation possible: events from different hosts mean more together than they do in isolation, and a chain of activity only becomes visible when the logs sit side by side. The SIEM also assesses each event rather than just storing it, assigning a rule and a severity level automatically. And because the logs are shipped off the host, they survive a compromise — clearing local event logs is one of the first things an attacker does.

## Environment

| Component | Value |
|---|---|
| SIEM | Wazuh 4.9.2 (all-in-one) |
| SIEM host OS | Ubuntu 24.04 LTS |
| SIEM IP | 192.168.2.128 |
| RAM | 3.8 GB |
| Agent version | 4.9.0 (Windows MSI) |
| Agents enrolled | 001 — CLIENT01 |
| Dashboard | `https://192.168.2.128` (port 443) |

## Implementation

Full command sequence: [scripts/04-wazuh-agent.ps1](../scripts/04-wazuh-agent.ps1)

**1. Server installation.** Installed Wazuh 4.9.2 on Ubuntu with the all-in-one assistant (`wazuh-install.sh -a`), which deploys the manager, indexer and dashboard on a single host.

![Wazuh installation](../img/04-01-wazuh-install.png)

**2. Service check.** Confirmed `wazuh-manager`, `wazuh-indexer` and `wazuh-dashboard` were all active.

![Wazuh services active](../img/04-02-services-status.png)

**3. Dashboard access.** Reached the dashboard over HTTPS on port 443.

![Wazuh dashboard login](../img/04-03-dashboard-login.png)

**4. Agent installation on CLIENT01.** Installed the Windows agent with `WAZUH_MANAGER=192.168.2.128` and `WAZUH_AGENT_NAME=CLIENT01`.

**5. Sysmon log collection.** Wazuh does not read the Sysmon channel by default. Added it explicitly in `ossec.conf` and restarted the service:

```xml
<localfile>
  <location>Microsoft-Windows-Sysmon/Operational</location>
  <log_format>eventchannel</log_format>
</localfile>
```

![Agent configuration with the Sysmon channel](../img/04-04-agent-sysmon-config.png)

The agent on DC01 has not been deployed yet — that is the next step for this stage.

## Verification

Confirmed that CLIENT01 was enrolled as agent 001 and reporting as Active.

![Agent CLIENT01 active](../img/04-05-agent-active.png)

Ran the encoded PowerShell command on CLIENT01 and located the resulting alert in Threat Hunting.

![Encoded PowerShell command found in the SIEM](../img/04-06-threat-hunting-event.png)

## Detection notes

Hunting query used:

```
agent.name: CLIENT01 AND data.win.eventdata.commandLine: *enc*
```

Fields that carried the most weight in the resulting alert:

| Field | Value | Why it matters |
|---|---|---|
| `rule.description` | Powershell process spawned | A built-in rule fired — the event was assessed, not merely stored |
| `integrityLevel` | High | Elevated process; the same command from a standard user is a different incident |
| `hashes` | SHA1 / MD5 / SHA256 / IMPHASH | Ready-made IOCs for threat intelligence lookups |
| `parentCommandLine` | `powershell.exe` | Expected parent for a console-launched command — this is what normal looks like |
| `currentDirectory` |