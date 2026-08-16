# SOC Home Lab

A personal detection lab I built to get a feel for how unpredictable SIEM alerts can be to experience every miss and every catch myself, instead of only reading about them.

I am moving into blue team work, and this lab is where I practicing. I build the environment, attack it, and then try to detect what I did. Every stage is documented here, including the parts that went wrong.

---

## Architecture

| VM       | Role                          | OS                       |     RAM | IP           |
| -------- | ----------------------------- | ------------------------ | ------: | ------------ |
| DC01     | Domain Controller, DNS        | Windows Server 2022 Core | 4096 MB | 192.168.2.10 |
| SIEM     | Log collection and detection  | Ubuntu Server 24.04 LTS  | 5120 MB | DHCP         |
| CLIENT01 | Workstation, telemetry source | Windows 11               | 4096 MB | DHCP         |

All machines run on VMware Workstation and share the NAT network `192.168.2.0/24` with gateway `192.168.2.2`.

The workstation is the main source of telemetry: process creation, PowerShell activity, and authentication events originate there.

The Domain Controller provides the realistic enterprise context. Active Directory is the backbone of many corporate environments and a primary target in real-world intrusions.

---

## Stages

|  # | Stage                                             | Status         |
| -: | ------------------------------------------------- | -------------- |
|  1 | [Active Directory Domain Controller on Server Core](docs/01-domain-controller.md) | ✅ Done |
|  2 | Windows 11 client and domain join                 | ✅ Done |
|  3 | Sysmon telemetry on the client                    | 🔄 In Progress     |
|  4 | Wazuh SIEM and agents on DC01 and CLIENT01        | ⏳ Planned      |
|  5 | Attack simulation and detection rules             | ⏳ Planned      |

Documentation for each stage lives in `/docs`.

Setup scripts are stored in `/scripts`.

---

## Tech Stack

`Windows Server 2022 Core` · `Active Directory` · `DNS` · `Windows 11` · `Ubuntu Server 24.04` · `VMware Workstation` · `PowerShell` · `Sysmon` · `Wazuh` · `Sigma` · `MITRE ATT&CK`

---

## Detection Workflow

The lab follows a simple attack-and-detect cycle:

```text
Build
  ↓
Generate telemetry
  ↓
Simulate an attack
  ↓
Collect logs
  ↓
Investigate the activity
  ↓
Create / tune detection
  ↓
Validate the detection
```

The goal is not just to make an alert appear.

The goal is to understand **why** it appeared, what telemetry produced it, what could be missed, and how the detection could be improved.

---

## Why I Document the Failures Too

Each stage has a **Problems Encountered** section.

I keep it deliberately.

The errors are where I actually learned something, and hiding them would make this a tutorial copy rather than a record of my own work.

If something breaks, the failure becomes part of the documentation:

**Problem → Investigation → Fix → Lesson learned**

---

## What I Am Practising

This lab is focused on practical blue team skills:

* Windows and Active Directory administration
* Windows event logs and telemetry
* Sysmon
* PowerShell logging
* SIEM deployment and log collection
* Alert investigation
* Detection engineering
* Sigma rules
* MITRE ATT&CK mapping
* Attack simulation
* False positives and false negatives
* Troubleshooting and documentation

---

## About

Career changer moving into cybersecurity and building practical blue team experience through hands-on labs.

Currently working through the TryHackMe SOC Level 1 path and preparing for CompTIA Security+.

The goal is simple:

**Learn every day and be a little better than yesterday.**

* LinkedIn: [oleksii-zanko](https://www.linkedin.com/in/oleksii-zanko-9a20b62b5)
* TryHackMe: [f8lex](https://tryhackme.com/p/f8lex)
