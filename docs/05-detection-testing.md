\# Stage 5 — Detection Testing with Atomic Red Team



\## Goal



Atomic Red Team replaces commands I invented myself with a catalogue of real techniques, each mapped to MITRE ATT\&CK and reproduced in a safe form. These are the same actions used in actual intrusions and the same techniques a SOC analyst deals with daily, which makes them the right thing to practise against — a detection that only catches the attacks I imagined proves very little.



\## Environment



| Component | Value |
|---|---|
| Framework | Atomic Red Team (invoke-atomicredteam) |
| Atomics path | `C:\\AtomicRedTeam\\atomics` |
| Executed on | CLIENT01 only |
| Detection stack | Wazuh 4.9.2 + Sysmon |
| Snapshot | `CLIENT01 - pre Atomic Red Team` |



\## Method



Each test followed the same sequence: read what the test does with `-ShowDetails`, check prerequisites with `-CheckPrereqs`, record the time with `Get-Date`, execute, then run `-Cleanup`. The timestamps were used to locate the resulting events in Wazuh.



!\[Atomic test execution with prerequisites, timestamp and cleanup](../img/05-01-atomic-test-run.png)



Windows Defender was excluded for `C:\\AtomicRedTeam` so the tests would not be blocked. This is acceptable in a lab, but worth noting: creating exclusions is itself a common attacker action and a legitimate reason to alert in production.



Tests were run only on CLIENT01. The domain controller was deliberately left out — restoring a DC is far more costly than restoring a workstation.



\## Results



| Technique | Test | Detected | Rule ID | Rule level | Notes |
|---|---|---|---|---|---|
| T1059.001 | Encoded PowerShell (Atomic #15) | Yes | 92027, 92213 | 4, 15 | Multiple rules fired across several sub-commands. 92213 (level 15) was a false positive — it fired on a temp file created by PowerShell's own script policy check, not an actual payload. The same core rule (92027) triggered as in the manual `-enc` test in stage 4. |
| T1136.001 | Create user via cmd (Atomic #4) | N/A | — | — | The test itself failed: Windows password policy rejected the account creation, so no account was ever created. Nothing for Wazuh to detect — the OS blocked the action before it happened. |
| T1053.005 | Scheduled task local (Atomic #2) | Yes | 92004, 92032, 92052, 92154 | 3–4 | Full command chain visible: PowerShell → cmd.exe → `SCHTASKS /Create`. No single high-severity rule, but strong multi-signal detection across both creation and cleanup. |
| T1087.001 | Enumerate accounts (Atomic #8) | Yes | 92036, 92031, 92032 | 3 | Each `net` command triggered matching rule pairs almost simultaneously, confirming the `net.exe` → `net1.exe` internal call is still captured. All level 3 — would easily blend into noise in a busy environment. |



Encoded PowerShell executed by the atomic test, captured with the full command line:



!\[PowerShell process created by the atomic test](../img/05-02-powershell-atomic.png)



The level 15 alert that turned out to be a false positive — note `ruleName: technique\_id=T1059.001` and the target filename `\_\_PSScriptPolicyTest\_\*.ps1`:



!\[False positive on rule 92213](../img/05-03-false-positive-92213.png)



Scheduled task creation captured as a full chain, ending in `SCHTASKS /Create`:



!\[Scheduled task creation event](../img/05-04-scheduled-task-event.png)



Account enumeration reaching the SIEM as `net1.exe` — the internal call first observed in stage 3:



!\[net1.exe process event](../img/05-05-net1-user.png)



Local accounts verified manually after cleanup:



!\[Local account check after cleanup](../img/05-06-cleanup-check.png)



\## Detection notes



\*\*False positive on rule 92213.\*\* This rule did not fire because something malicious was inside the file — it fired because a file appeared in the Temp directory. That directory is used by malware and by ordinary legitimate software alike. In my case the file was created by PowerShell itself as part of its own script policy check: normal behaviour, not an attack. The weakness is that the rule looks at where a file was written rather than what it contains, which makes it fire on harmless activity — and this one is level 15, the highest severity. Alerts like this are how analysts learn to ignore their own tooling.



\*\*Why T1136.001 is "N/A" rather than "No".\*\* "No" would mean the attack happened and the SIEM missed it. That is not what occurred here: Windows itself refused to create the account because the password did not meet the policy, so there was no attack to detect. The SIEM missed nothing — there was simply nothing to see. These are two different outcomes and they call for two different responses, so recording them under the same word would hide the distinction.



\*\*Why level 3 on discovery is a coverage problem.\*\* The SIEM did see `net user` and `net localgroup`, but assigned them the lowest severity. In a production environment level 3 events arrive constantly — routine logons, ordinary process starts — and no analyst can review each one by hand. So even when something is technically detected, in practice nobody notices it among thousands of similar low-priority events. Being seen is not the same as being noticed.



\## Problems encountered



\### Cleanup did not fully verify itself



\*\*Symptom.\*\* I assumed `-Cleanup` reliably removes everything a test creates. After T1136.001 (create local account) I could not actually be sure the account was gone until I checked manually with `Get-LocalUser`.



\*\*Root cause.\*\* "Done executing cleanup" reports that the cleanup command ran, not that the system is back to its previous state.



\*\*Resolution.\*\* Verified the result separately after each test — local accounts with `Get-LocalUser`, scheduled tasks with `Get-ScheduledTask`. Everything was clean this time.



\*\*Takeaway.\*\* Confirmation that a command executed is not confirmation that it worked. Without a separate check, test artefacts — extra users, tasks, files — accumulate in the lab unnoticed.



\## What I learned



Hunting is not what I thought it was. I pictured scrolling through logs looking for something strange, but with hundreds of fields per event that is physically impossible. Real hunting starts from a specific question — "did anyone run PowerShell with an encoded command?" — and filters for that question rather than trying to read everything.



Severity level does not map onto real significance. The loudest alert across all my tests was level 15 and turned out to be a false positive, while the quietest ones at level 3 were genuine traces of reconnaissance that would disappear into the daily noise. The number alone is not enough to act on — each alert still has to be checked against what actually happened.



And not everything that looks like a detection gap is one. When T1136.001 produced no alert, my first thought was that the SIEM had missed something. It had not: the attack never happened, because Windows blocked the account creation. Before writing "not detected," the first question has to be whether there was anything to detect.



\## Next steps



\- Re-run T1136.001 with a password that satisfies the domain policy, to replace the N/A with a real Yes or No.

\- Tune rule 92213 by excluding the known `\_\_PSScriptPolicyTest\_\*.ps1` artefact, rather than disabling the rule and losing the signal along with the noise.

\- Build a correlation rule for discovery activity: several reconnaissance commands from one process within a short window, instead of alerting on each command at level 3.

