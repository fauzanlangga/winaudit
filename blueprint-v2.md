# Blueprint Satsiberau Endpoint Security Suite v2.0

**Versi Dokumen:** 1.0 (20 November 2026)
**Penyusun:** Lettu Lek Ahmad Fauzan Langga, S.T.

---

## 1. Executive Summary

Satsiberau Endpoint Security Audit Tool v2.0 adalah evolusi dari v1.0 (12 modul fokus IR/forensic) menjadi **comprehensive assessment suite** dengan **4 pilar fungsi** dan **38 modul** terstruktur.

| Pilar | Fokus | Jumlah Modul |
|-------|-------|--------------|
| **A — Vulnerability Assessment (VA)** | Apa yang bisa dieksploit di endpoint ini? | 10 modul |
| **B — Hidden Malware Detection (HMD)** | Apakah ada malware tersembunyi? | 10 modul |
| **C — Unauthorized Software (SUS)** | Ada aplikasi tidak sah atau bajakan? | 8 modul |
| **D — Compromise Evidence / IOC** | Jejak serangan sudah masuk kapan? | 10 modul |

---

## 2. Positioning

> **"Comprehensive Endpoint Security Assessment Suite — menggabungkan vulnerability scanner, malware hunter, software compliance checker, dan forensic triage dalam satu tools offline."**

Setara dengan subset Nessus + OSQuery + KAPE + Sysinternals Autoruns + CIS-CAT, tapi:
- Offline-native (air-gap compatible)
- Report tunggal terintegrasi
- Single executable (~15-35 MB)
- Zero runtime dependencies

---

## 3. Arsitektur 4 Pilar

### 3.1 Prinsip Desain

1. **Offline-native** — IoC database, CVE list, LOLDrivers DB di-bundle lokal
2. **Satu file EXE** — distribusi via PyInstaller `--onefile --uac-admin`
3. **Modular & opt-in** — CLI flag untuk run subset modul
4. **Severity CVSS-like** — CRITICAL/HIGH/MEDIUM/LOW/INFO dengan skor 0-10
5. **Evidence-first** — raw JSON per finding untuk audit trail
6. **Baseline-aware** — diff analysis di v2.1+

### 3.2 Overview Pilar A (Vulnerability Assessment)

| Modul | Nama |
|-------|------|
| VA-01 | Missing Patches & EOL Software |
| VA-02 | Vulnerable Third-Party Software |
| VA-03 | Security Feature Posture (Defender, UAC, Firewall, dll) |
| VA-04 | Account & Authentication Hygiene |
| VA-05 | Service & Scheduled Task Vulnerabilities |
| VA-06 | Network Attack Surface |
| VA-07 | Filesystem & Registry Permission |
| VA-08 | Hardware & Firmware Posture (TPM, Secure Boot) |
| VA-09 | Legacy Protocol & Weak Crypto |
| VA-10 | Browser Security Posture |

### 3.3 Overview Pilar B (Hidden Malware Detection)

| Modul | Nama | MITRE ATT&CK |
|-------|------|--------------|
| HMD-01 | Process Stealth Detection | T1036 Masquerading |
| HMD-02 | Fileless Persistence | T1546, T1547 |
| HMD-03 | Obscure Persistence Locations (50+) | T1547, T1546, T1543 |
| HMD-04 | Signature & Loading Anomaly (BYOVD) | T1068 |
| HMD-05 | Anti-Forensic Technique Detection | T1070 |
| HMD-06 | In-Memory / Fileless Indicators | T1055 |
| HMD-07 | LOLBAS Abuse Detection | T1218 |
| HMD-08 | Living-off-the-Land Persistence | T1562 |
| HMD-09 | Hidden Accounts & Objects | T1564 |
| HMD-10 | Behavioral Beacon Detection | T1071 |

### 3.4 Overview Pilar C (Unauthorized Software)

| Modul | Nama | Contoh |
|-------|------|--------|
| SUS-01 | Hacking & Pentesting Tools | Burp, Mimikatz, Cobalt Strike, dll |
| SUS-02 | Pirated / Cracked Software | KMS activators, Adobe GenP, dll |
| SUS-03 | Unauthorized Remote Access Tools | TeamViewer, AnyDesk, ngrok |
| SUS-04 | Crypto Mining Software | xmrig, nicehash, phoenixminer |
| SUS-05 | Anonymization / Tunneling | Tor, VPN non-dinas, Shadowsocks |
| SUS-06 | Data Exfiltration Tools | rclone, personal cloud sync |
| SUS-07 | Keylogger / Spyware | mSpy, FlexiSpy, Ardamax |
| SUS-08 | Game Cheats & Modifiers | Cheat Engine, trainers |

### 3.5 Overview Pilar D (Compromise Evidence)

| Modul | Nama |
|-------|------|
| IOC-01 | Recent Account Activity Anomaly |
| IOC-02 | Recent Suspicious File Creation |
| IOC-03 | Recent Service/Task/Persistence Creation |
| IOC-04 | Recent Network Activity Anomaly |
| IOC-05 | USB & Removable Media History |
| IOC-06 | Program Execution History (UserAssist, Amcache, Prefetch) |
| IOC-07 | Recent File Access History (ShellBags, Jump Lists) |
| IOC-08 | Lateral Movement Indicators |
| IOC-09 | Data Staging / Exfiltration Traces |
| IOC-10 | **Unified Timeline View** (killer feature) |

---

## 4. Roadmap Pengembangan

### Phase 1 — Quick Wins & Fondasi (DONE di v2.0-alpha-M3.4)
- Bug fix dari v1.0
- HMD-01, HMD-03 (top-15), VA-03, SUS-02, SUS-01
- Framework refactor
- 4-pillar architecture

### Phase 2 — Core Audit (IN PROGRESS)
- VA-01, VA-09 (partial)
- SUS-01, SUS-03
- IOC-05, IOC-06

### Phase 3 — Deep Malware Hunting (PLANNED Q1 2027)
- HMD-02, HMD-04 (LOLDrivers DB), HMD-07, HMD-08
- SUS-04, SUS-05, SUS-06
- IOC-02, IOC-03, IOC-04

### Phase 4 — Advanced Forensic & Timeline (PLANNED Q2 2027)
- IOC-07, IOC-08, IOC-09
- **IOC-10 Unified Timeline**
- HMD-05, HMD-06

### Phase 5 — Completeness (PLANNED Q3 2027)
- VA-02, VA-04-08, VA-10
- HMD-09, HMD-10
- SUS-07, SUS-08
- Full report redesign

---

## 5. Unified Report Engine (v2.0 Target)

```
┌─ HEADER ──────────────────────────────────────────────┐
│ Satsiberau | Hostname | IP | OS | Scan Time           │
│ Classification: UNTUK KEPERLUAN INTERNAL              │
├─ EXECUTIVE SUMMARY ───────────────────────────────────┤
│  VA Score | HMD Count | SUS Count | IOC Concern       │
├─ IMMEDIATE ACTION ITEMS (Top 10) ─────────────────────┤
│  1. [CRIT] Finding paling urgent                      │
│  ...                                                  │
├─ CHRONOLOGICAL TIMELINE (IOC-10) ─────────────────────┤
│  [Interactive timeline visualization]                 │
├─ PILAR A/B/C/D DETAIL (collapsible) ─────────────────┤
├─ RAW EVIDENCE APPENDIX ──────────────────────────────┤
└──────────────────────────────────────────────────────┘
```

### Scoring Model

**Pilar A (VA):** 0-100 (deduction per severity)
- 90-100: LOW RISK
- 75-89: MEDIUM RISK
- 50-74: HIGH RISK
- < 50: CRITICAL RISK

**Pilar B (HMD):** Count per severity
**Pilar C (SUS):** Compliance violation count
**Pilar D (IOC):** Compromise risk level (CLEAN / LOW / HIGH / CONFIRMED)

---

## 6. Dependencies & Bundled Databases

### 6.1 Python Dependencies (v2.0 Target)
```
psutil>=5.9
wmi>=1.5
pywin32>=306
pefile>=2023.2.7           # PE signature parsing
python-prefetch>=0.2       # SCCA parse
python-registry>=1.3       # Advanced registry hive
yara-python>=4.3           # YARA scan (optional)
olefile>=0.46              # Jump list parsing
```

### 6.2 Bundled Offline Databases

| Database | Ukuran | Sumber |
|----------|--------|--------|
| Critical KB mapping | ~50 KB | Manual kurasi |
| CVE subset (top-50 app) | ~500 KB | NVD JSON feed |
| LOLDrivers | ~2 MB | loldrivers.io |
| LOLBAS | ~200 KB | lolbas-project.github.io |
| KMS activator signatures | ~20 KB | Internal research |
| Tor exit nodes | ~500 KB | check.torproject.org |

**Total bundle:** ~3-5 MB

---

## 7. Status Saat Ini (v2.0-alpha-M3.4, 25 November 2026)

### Modul Aktif: 26 dari 38 target

**Implemented:**
- VA-01 ✅ (dengan KB supersedence heuristic)
- VA-03 ✅
- VA-09 ✅
- HMD-01 ✅
- HMD-03 (top-15) ✅
- HMD-04 ✅ (basic unsigned detection)
- HMD-07 ✅ (LOLBAS 18 patterns)
- HMD-08 ✅
- SUS-01 ✅ (hacking tools)
- SUS-02 ✅ (KMS activators)
- SUS-03 ✅ (portable tools)
- IOC-05 ✅
- IOC-06 ✅

**Planned next (M4+):**
- VA-02 (CVE DB untuk third-party)
- VA-04-08
- HMD-02, HMD-05-10
- IOC-01-04, IOC-07-10

Progress FP reduction: **236 → 87 → 29 → 21 → ~18 finding** (signal-to-noise 15% → ~95%)

---

**Lettu Lek Ahmad Fauzan Langga, S.T.**
**Satuan Siber TNI Angkatan Udara**
*Vâyusenã Mâyãvarman*
