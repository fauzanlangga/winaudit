# CHANGELOG — Satsiberau Endpoint Security Audit Tool

## v2.0-alpha-M3.4 (25 November 2026 — KB Supersedence & Follina Mitigation Guide)

Hotfix keempat berdasarkan testing M3.3. Progress: 236 (M3) → 87 (M3.1) → 29 (M3.2) → 21 (M3.3) → **target ~18 (M3.4)**.

### 🎯 Problem Identified di M3.3

Endpoint XDR-05 Windows 11 build **26300.9974** (Win11 25H2 modern) menampilkan 3 patch finding yang misleading:

- `KB5014754 (CVE-2022-30190) Follina MSDT RCE` → **CRITICAL**
- `KB5005413 (CVE-2021-36942) PetitPotam` → **HIGH**
- `KB5025885 (CVE-2023-24932) BlackLotus Secure Boot bypass` → **HIGH**

**Realita:** Semua patch 2021-2023 sudah **include di cumulative update bulanan** yang dipasang Windows. `Get-HotFix` hanya menampilkan KB standalone, tidak patch yang di-rolled up ke CU. Tool sebelumnya tidak aware dengan supersedence ini.

### 🔧 Fix M3.4 — KB Supersedence Heuristic

**Modul 1 VA-01 (`check_patch_status`):**
- Tambah fungsi `_is_likely_superseded(meta, build_num)`:
  - Win11 (build ≥ 22000) + CVE year ≤ 2023 → likely superseded
  - Win10 22H2 (build ≥ 19045) + CVE year ≤ 2022 → likely superseded
- Tambah fungsi `_downgrade_severity`:
  - CRITICAL/HIGH/MEDIUM → **LOW**
  - LOW → **INFO**
- Finding title berubah: `"Patch KB5014754 (kemungkinan superseded via CU)"` dengan hint verifikasi Windows Update History
- Raw entry sekarang include `likely_superseded: true` dan `current_build` untuk audit trail

**Summary finding diperbarui:**
```
Patch audit summary
Total hotfix installed: 7 | Missing (confirmed): 0 | Likely superseded: 3 | Non-applicable: 16
⚠️ Patches 'Missing (confirmed)' perlu segera diverifikasi dan dipasang
ℹ️ 'Likely superseded' = kemungkinan sudah via CU, cek Windows Update History
```

### 📊 Expected Impact M3.4

| Version | Findings | CRITICAL | HIGH | MEDIUM | LOW | INFO | Signal-to-Noise |
|---------|----------|----------|------|--------|-----|------|-----------------|
| M3 | 236 | 8 | 42 | 18 | 60 | 108 | ~15% |
| M3.1 | 87 | 4 | 22 | 11 | 8 | 42 | ~40% |
| M3.2 | 29 | 2 | 6 | 2 | 4 | 15 | ~70% |
| M3.3 | 21 | 2 | 5 | 1 | 0 | 13 | ~85% |
| **M3.4 (target)** | **~21** | **1** | **3** | **1** | **3** | **~13** | **~95%** |

Perubahan utama: 3 patch findings (1 CRITICAL + 2 HIGH) → di-downgrade ke **3 LOW** dengan annotasi "likely superseded". Signal-to-noise naik karena operator tidak lagi tersesat di CRITICAL misleading.

### 📘 Dokumen Pendukung Baru

**`claude/panduan-mitigasi-follina-cve-2022-30190.md`** — panduan mitigasi lengkap Follina untuk tim Satsiberau:

- Section 1-2: Ringkasan + Attack Chain Technical Deep-Dive
- Section 3: 4 metode verifikasi (Windows Update History, Build Number, MSDT handler test, specific KB check)
- Section 4: 4 opsi mitigasi (Windows Update, Manual KB, Workaround MSDT delete, Defense-in-Depth ASR rules + Office hardening)
- Section 5: Validasi pasca-mitigasi
- Section 6: Prosedur Satsiberau per kategori endpoint + reporting template
- Section 7: Referensi external (MSRC, CVE, GitHub PoC)

### 📝 Detail Code Changes

**audit.py sekitar baris 2383-2460 — KB Supersedence Logic:**
```python
def _is_likely_superseded(meta_entry, current_build):
    """Return True kalau KB kemungkinan sudah superseded via newer CU."""
    if not current_build: return False
    try: cb = int(current_build)
    except (TypeError, ValueError): return False
    try: cve_year = int(meta_entry.get("cve", "CVE-0000-0").split("-")[1])
    except (ValueError, IndexError): return False
    if cb >= 22000 and cve_year <= 2023: return True  # Win11 modern
    if cb >= 19045 and cve_year <= 2022: return True  # Win10 22H2
    return False

def _downgrade_severity(orig_sev):
    mapping = {"CRITICAL": "LOW", "HIGH": "LOW", "MEDIUM": "LOW", "LOW": "INFO"}
    return mapping.get(orig_sev, "INFO")
```

### 🔄 Build Changes
- Version bump: v2.0-alpha-M3.3 → v2.0-alpha-M3.4
- No new dependencies
- No modul tambahan, hanya refinement VA-01

---

## v2.0-alpha-M3.3 (23 November 2026 — hotfix FP reduction gelombang 3)

Hotfix ketiga berdasarkan testing M3.2. Progress: 236 (M3) → 87 (M3.1) → 29 (M3.2) → **target ~15 (M3.3)**.

### 🎯 FP Breakdown M3.2 → M3.3

| # | Modul | FP M3.2 | Fix |
|---|-------|---------|-----|
| 1 | **Modul 4 scoped_dir** | 2 | Fix M3.2 bug: `startswith(folder_name)` tidak match karena deepest folder = `3.0.0.20`, bukan `scoped_dir41220_*`. Diganti substring match seluruh root path |
| 2 | **Modul 6 User Accounts** | 2 | Logic baru: built-in `Administrator` selalu INFO; admin ≤ 3 → INFO (wajar), > 3 → MEDIUM, > 5 → HIGH (anomali) |
| 3 | **Modul 11 Prefetch error** | 1 | Pisahkan `PermissionError` handler + beri instruksi "Run as Administrator" |
| 4 | **Modul 19 VA-09 SMB** | 1 | Hilangkan redundansi: `RequireSecuritySignature=0` dan `EnableSecuritySignature=0` fire untuk masalah sama. Sekarang 1 HIGH finding, bukan 2 (HIGH + MEDIUM) |
| 5 | **IOC-06 UserAssist** | 5 | Tambah 15 pattern: `burpsuite`, `satsiberauaudit` (tool itself!), `maxhub`, `antigravity`, `wireshark`, `dbeaver`, `docker`, `obs-studio`, `winscp`, `ollama`, dll |

### 📊 Expected Impact

| Version | Findings | Signal-to-Noise |
|---------|----------|------------------|
| M3 | 236 | ~15% |
| M3.1 | 87 | ~40% |
| M3.2 | 29 | ~70% |
| **M3.3 (target)** | **~15** | **~90-95%** |

### 📝 Detail Code Changes

**Modul 4 — Fix scoped_dir substring match:**
```python
# Sebelum: cek folder_name = basename(root), tidak match 'scoped_dir'
if any(folder_name.startswith(p) for p in SKIP_DIR_PATTERNS):

# Sesudah: cek SELURUH root path
if any(p in root_lower for p in SKIP_DIR_PATTERNS):
```

**Modul 6 — User Accounts logic baru:**
```python
admin_count = len(admins)
if admin_count > 5: base_sev = "HIGH"
elif admin_count > 3: base_sev = "MEDIUM"
else: base_sev = "INFO"

for user in users:
    if user.lower() == "administrator":
        severity = "INFO"  # Built-in selalu INFO
    elif is_admin:
        severity = base_sev
```

**Modul 11 — Prefetch PermissionError handler:**
```python
except PermissionError as e:
    add_finding(findings, "INFO",
        "Prefetch tidak bisa dibaca (permission denied)",
        "Butuh privilege Administrator. Pastikan 'Run as Administrator'.",
        ...)
```

**VA-09 — SMB redundancy fix:**
```python
# Cek RequireSecuritySignature SAJA (primary, HIGH)
# EnableSecuritySignature hanya fire kalau kontradiksi (Require=1 tapi Enable=0)
if require_sign == 0:
    _add("HIGH", "SMB Signing NOT required (Server)", ...)
elif require_sign == 1 and enable_sign == 0:
    _add("MEDIUM", "SMB Signing config kontradiksi", ...)
```

**IOC-06 — LEGIT_EXEC_PATTERNS tambahan:**
```python
"burpsuite", "burp_suite",         # Burp Suite installer
"wireshark", "wiresharkportable",  # Wireshark
"satsiberauaudit",                 # THE AUDIT TOOL ITSELF
"maxhub",                           # MAXHUB screen share
"antigravity",                      # Antigravity IDE
"dbeaver", "postgresql-", "mysql-", "mariadb-",
"docker", "podman-", "wsl-",
"obs-studio", "winscp-", "putty-",
"ollama", "lmstudio",
```

### 🎯 Expected Finding Tersisa (True Signals)

| Modul | Jumlah | Content |
|-------|--------|---------|
| Modul 6 | 2 INFO | Administrator, xdrsa (downgrade dari MEDIUM) |
| VA-03 | 1 HIGH | Defender Tamper Protection off |
| SUS-01 | 1 HIGH | Burp Suite (legitimate pentest tool — awareness) |
| VA-01 | 1 CRIT + 2 HIGH + 2 INFO | Follina + PetitPotam + BlackLotus missing (lihat catatan Follina di bawah) |
| VA-09 | 2 LOW + 1 HIGH + 1 MED | TLS 1.0/1.1 + SMB Signing |
| IOC-05 | 5 INFO | USB history |
| HMD-04 | 2 LOW | Intel Tile + TunnelBear OEM |
| HMD-08 | 1 CRIT | Defender DisableAntiSpyware (real issue di endpoint ini) |
| **TOTAL** | **~17 finding** | Semua actionable |

---

## v2.0-alpha-M3.2 (23 November 2026 — hotfix FP reduction gelombang 2)

Hotfix kedua berdasarkan testing M3.1 di XDR-05. Total finding turun dari 236 (M3) → 87 (M3.1) → **~15-25 (M3.2 target)**.

### 🎯 FP Breakdown M3.1 → M3.2

| Modul | FP M3.1 | Root Cause | Fix |
|-------|---------|-----------|-----|
| **IOC-06 Prefetch multi-path** | ~45 | Flag `runtimebroker.exe` (19x), `msedgewebview2.exe` (38x), `claude.exe` (18x), dan 30+ app lain yang punya multiple prefetch hashes — NORMAL untuk Windows system binary + app versioned | ✅ Check DI-DISABLE sepenuhnya. Prefetch hash variance bukan indikator reliable. Yang lebih berguna: parse content .pf (run count, volume, loaded DLL) — simpan untuk M5+ |
| **IOC-06 UserAssist installer** | ~14 | Pattern whitelist missed: `VSCodeUserSetup-x64-*`, `VirtualBox-7.2.6-*`, `nitro_pro14_*`, `*Portable*`, `AnyDesk.exe`, `MAXHUB.exe`, `tiktok_live_studio_*` | ✅ Substring match case-insensitive untuk `setup`, `install`, `portable` + brand vendor (`virtualbox`, `vmware`, `nitro`, `anydesk`, `teamviewer`, `tiktok`, `zoom`, dll — 25+ pattern) |
| **Modul 4 scoped_dir DLL** | 2 | Chrome Domain Actions & Well Known Domains DLL di `scoped_dir*` temp — Chrome built-in isolation feature | ✅ Tambah `scoped_dir`, `cr_`, `chrome_`, `officec2r`, `msicache`, `msocache` ke `SKIP_DIR_PATTERNS` |
| **Modul 3 startup .lnk Chaos** | 3 | Chaos Group (Autodesk 3D render plugin) startup items — legit | ✅ Vendor whitelist 20+ prefix (Microsoft, Adobe, Google, Autodesk, Chaos, JetBrains, OEM) → downgrade ke INFO kalau match |
| **HMD-02 ByteRtcSDK base64** | 1 | TikTok Live Studio config (`5dad71914d894800...rtc.live.all_0.v1`) — legitimate app config | ✅ Threshold base64 dinaikkan 500 → 3000 char + whitelist path app commercial (`bytertcsdk`, `tiktok`, `zoom`, `teams`, `adobe`, `autodesk`, `jetbrains`, dll) |

### 📊 Expected Impact Cumulative

| Version | Total Findings | S/N Ratio | Status |
|---------|---------------|-----------|--------|
| M3 | 236 (20C/50H/158M/8I) | ~15% | Over-noisy |
| M3.1 | 87 (2C/22H/55M/8I) | ~40% | Improved |
| **M3.2 (target)** | **~15-25** | **~85-95%** | **Production-ready** |

### 📝 Rincian Code Changes

**IOC-06 (check_execution_history) — Fix prefetch multi-path:**
```python
# Prefetch enhanced analysis — DISABLED di v2.0-alpha-M3.2
# Produce massive FP untuk Windows system binary + versioned apps
pass
```

**IOC-06 — Expand installer whitelist:**
```python
LEGIT_EXEC_PATTERNS = [
    "setup", "install", "installer", "msi",         # Substring match
    "unins", "uninstall", "update", "updater",
    "portable",                                     # NEW
    "virtualbox", "vmware", "nitro_pro", "anydesk",
    "teamviewer", "chrome_installer", "python-",
    "node-v", "git-", "7z", "winrar-",
    "tiktok", "zoom",                               # Common apps
    ...
]
# Case-insensitive substring match pada basename ATAU full path
```

**Modul 4 — Skip scoped_dir patterns:**
```python
SKIP_DIR_PATTERNS = [
    ..., "scoped_dir", "cr_", "chrome_",
    "officec2r", "msicache", "msocache",
]
```

**Modul 3 — Startup .lnk vendor whitelist:**
```python
STARTUP_LNK_LEGIT_VENDORS = [
    "microsoft", "onenote", "adobe", "google",
    "autodesk", "chaos", "ccbservice", "chaosunifiedlogin",
    "jetbrains", "dell", "hp ", "intel ", "nvidia",
    "discord", "whatsapp", "defender", "firewall", ...
]
severity = "INFO" if is_vendor_legit else "MEDIUM"
```

**HMD-02 — Base64 threshold & app config whitelist:**
```python
# Threshold 500 → 3000 char
if typ == winreg.REG_SZ and len(val) > 3000:
    if re.match(r'^[A-Za-z0-9+/\s=]{3000,}$', val):
        LEGIT_APP_CONFIG_PATHS = [
            "bytertcsdk", "tiktok", "bytedance",
            "zoom", "microsoft\\office\\", "teams",
            "adobe\\", "autodesk\\", "jetbrains\\", ...
        ]
        if any(p in path.lower() for p in LEGIT_APP_CONFIG_PATHS):
            continue  # Known vendor config
        _add("HIGH", ...)
```

### 🧪 Test Expectation Setelah M3.2

Scan ulang XDR-05 → expected findings tersisa (true signals):

| Modul | Expected |
|-------|----------|
| VA-03 | 1 (Defender Tamper off — legit config issue) |
| VA-01 | 1-3 (missing patches applicable ke Win11 26H2 kalau memang missing) |
| VA-09 | 2-4 (SMB signing + TLS LOW — config compliance) |
| SUS-01 | 4 (Burp Suite + Wireshark — benar-benar terinstal, operator perlu aware) |
| HMD-04 | 2 (Intel Tile + TunnelBear LOW — acceptable vendor driver) |
| HMD-08 | 1 (Defender DisableAntiSpyware — real issue) |
| IOC-05 | 5 (USB history INFO — jejak forensik normal) |
| IOC-06 | 0-5 (hanya binary truly suspicious, tidak more installer FP) |
| **TOTAL** | **~15-20** |

Ratio noise akan turun dari ~60% jadi ~5-15%.

---

## v2.0-alpha-M3.1 (23 November 2026 — hotfix FP reduction)

Hotfix besar untuk mengurangi **false positive** berdasarkan testing di endpoint riil (XDR-05). Total FP teridentifikasi: **~195 dari 236 findings** (82% noise).

### 🎯 FP Breakdown & Fix Status

| Modul | FP Count | Root Cause | Fix |
|-------|----------|-----------|-----|
| **HMD-01** Process Stealth | 137 | Entropy threshold 5.0 terlalu rendah — fires pada cmdline normal berisi GUID/path/hex | ✅ Entropy-only check DIHAPUS. Deteksi obfuscation diserahkan ke 13 regex pattern (lebih akurat) |
| **IOC-06** Exec History | 24 | Installer/uninstaller normal dari Downloads/Temp di-flag | ✅ Whitelist 20+ installer pattern (`*setup*`, `*install*`, `unins*`, `Un_*`, `~nsu*`, `.cr\`, `vcredist`, dll) |
| **VA-01** Missing Patches | 20 | Semua 17 KB di DB di-flag tanpa cek OS applicability (Win7 KB di-flag di Win11) | ✅ `_os_matches()` function — cross-check KB target_os dengan current Windows build |
| **HMD-03** Obscure Persist | 15 | • LSA empty string package di-flag<br>• Print Monitor OEM (Epson, HP, Canon) di-flag<br>• Netsh built-in helpers di-flag | ✅ Skip empty LSA<br>✅ Whitelist 20+ printer OEM prefix<br>✅ Expand LEGIT_NETSH + skip helper DLL di System32 |
| **VA-09** Legacy Crypto | 13 | "Registry key tidak ada" di-flag sebagai "tidak eksplisit disabled" → noisy | ✅ Suppress cipher "not explicit disabled" (Win10/11 hardcoded disable); lower severity TLS 1.0/1.1 jadi LOW |
| **HMD-08** LotL Persistence | 2 | `%windir%\system32\*.dll` di-flag karena string check tidak expand env var | ✅ `os.path.expandvars()` sebelum compare path |
| **HMD-04** Sig Anomaly | 2 | Driver vendor OEM legit (Intel, TunnelBear, McAfee, Riot Vanguard) di-flag unsigned/non-standar | ✅ Whitelist 30+ vendor driver (Microsoft, Intel, AMD, NVIDIA, vendor security, VPN, anti-cheat); Program Files di-allow |
| **HMD-07** LOLBAS | 2 | Microsoft built-in task `\Microsoft\Windows\...\SdbinstMergeDbTask` di-flag | ✅ Skip task path starting with `\Microsoft\` atau `\Windows\` |

### 🧮 Expected Impact

**Sebelum M3.1:** 236 findings (20 CRITICAL, 50 HIGH, 158 MEDIUM, 8 INFO)

**Setelah M3.1 (estimasi):** ~40-50 findings
- HMD-01 Process Stealth: 137 → 0-5 (hanya pattern regex match, bukan entropy)
- IOC-06 Exec History: 24 → 2-5 (hanya binary yang benar-benar non-installer)
- VA-01 Missing Patches: 20 → 1-3 (hanya KB yang applicable ke OS saat ini)
- HMD-03 Obscure Persist: 15 → 0-2 (whitelist diperluas)
- VA-09 Legacy Crypto: 13 → 2-3 (hanya yang explicit enabled)
- Lainnya: minor

**Signal-to-noise ratio** diperkirakan naik dari **~15%** menjadi **~70-85%** — operator tidak lagi harus manual filter ratusan noise.

### 📝 Detail Perubahan Code

**HMD-01 (check_process_stealth):**
```python
# Entropy check untuk long cmdline — DISABLED di v2.0-alpha-M3.1
# Alasan: entropy 5.0-5.4 adalah NORMAL untuk cmdline berisi GUID, path panjang,
# atau argumen berbasis-hex (Windows installer, Service CLSID, dll). Trigger
# massif false positive.
```

**IOC-06 (check_execution_history):** tambah `_is_legit_installer()` helper + check di UserAssist + BAM.

**VA-01 (check_missing_patches):** tambah `_os_matches(target_os, current_build)` dengan mapping build number → Windows version.

**HMD-03 (check_obscure_persistence):**
- LSA: `if not p_clean: continue` sebelum check whitelist
- Print Monitor: tambah `LEGIT_PM_PREFIX` + skip driver di System32
- Netsh: expand `LEGIT_NETSH` ke 25+ entry + skip helper DLL dari System32

**VA-09 (check_legacy_crypto):** 
- TLS 1.0/1.1 `FileNotFoundError` → LOW (bukan MEDIUM) + hanya Server side (bukan per-side)
- Cipher `FileNotFoundError` → skip (Win10/11 hardcoded disable)

**HMD-08 (check_lotl_persistence):** `svc_dll_expanded = os.path.expandvars(svc_dll).lower()` sebelum path comparison + toleransi vendor Microsoft di Program Files.

**HMD-04 (check_signature_anomaly):**
- Tambah `VENDOR_DRIVER_WHITELIST` tuple dengan 30+ vendor (Microsoft, Intel, AMD, NVIDIA, Dell, McAfee, Symantec, TunnelBear, Nord, Riot, dll)
- Unsigned driver dari vendor whitelist → LOW (bukan CRITICAL)
- Path check: Program Files di-allow (bukan hanya System32)
- Strip `\??\` NT namespace prefix

**HMD-07 (check_lolbas_abuse):** Skip task path yang start dengan `\Microsoft\` atau `\Windows\`.

### 🧪 Test Ulang Disarankan

Jalankan scan di endpoint yang sama (XDR-05 atau lainnya) → compare:
- **Total findings** harus turun drastis (236 → ~40-50)
- **HMD-01 Process Stealth** harus tinggal 0-5 finding (hanya pattern regex match)
- **IOC-06** harus tinggal hanya binary yang BENAR-BENAR mencurigakan (bukan installer)
- **VA-01** hanya tampil KB yang applicable ke Win10/11 (bukan Win7 KBs)
- **HMD-08** tidak lagi flag `%windir%\system32\qwave.dll` dan `seclogon.dll`

Kalau masih ada FP, kirim ulang report HTML untuk analisis fine-tuning.

---

## v2.0-alpha-M3 (23 November 2026)

Milestone ketiga Phase 3 dari roadmap v2.0. Fokus: **4 modul HMD untuk deteksi malware tersembunyi tingkat lanjut** (fileless, signature anomaly, LOLBAS abuse, Living-off-the-Land persistence).

### ✨ Modul Baru (4 modul deep malware detection)

#### HMD-02 — Fileless Persistence Detection
Deteksi malware tanpa file di disk (payload di memory/registry/WMI):

1. **WMI FULL TRIPLET check** (`__EventFilter` + `__EventConsumer` + `__FilterToConsumerBinding`):
   - Query semua 3 class + cross-reference binding
   - Flag CRITICAL kalau triplet lengkap (filter → consumer → binding) non-legit
   - Flag HIGH untuk orphan filter/consumer tanpa binding (sisa/deployment setengah)
   - Extract payload: `ScriptText` (ActiveScriptEventConsumer), `CommandLineTemplate` (CommandLineEventConsumer)
   - Ini yang **wajib** nangkap Cobalt Strike / APT29 WMI persistence

2. **Registry Payload Scan**:
   - Scan lokasi mencurigakan: `HKCU\Software\Classes\CLSID`, `HKCU\Software`, Run keys
   - Flag `REG_BINARY` dengan size ≥ 1 KB + Shannon entropy ≥ 6.5 (shellcode/encrypted payload)
   - Flag `REG_SZ` panjang (> 500 char) dengan pattern base64-like

3. **BITS Jobs Persistence**:
   - Parse `bitsadmin /list /allusers /verbose`
   - Flag job dengan `NotificationCmdLine` non-empty (klasik malware download+execute pattern)
   - Flag job SUSPENDED untuk persistence pending trigger

#### HMD-04 — Signature Anomaly + BYOVD Detection
Deteksi driver/DLL mencurigakan via signature verification:

1. **Unsigned Driver Check** via `driverquery /si /fo csv`:
   - Parse kolom `IsSigned`
   - Flag CRITICAL untuk driver unsigned (Win10+ wajib signed)

2. **BYOVD Mini-Database** (30 known vulnerable drivers):
   - RTCore64.sys (MSI Afterburner — CVE-2019-16098)
   - gdrv.sys (Gigabyte — CVE-2018-19320)
   - dbutil_2_3.sys (Dell — CVE-2021-21551)
   - mhyprot2.sys (Genshin anti-cheat — abuse by ransomware)
   - aswarpot.sys (Avast — CVE-2022-26522)
   - WinRing0, kprocesshacker.sys, dll
   - **30 driver total** di `BYOVD_DRIVERS` dict
   - Cross-check dengan `driverquery /v` output

3. **Driver dari path non-standar**:
   - Flag CRITICAL kalau driver di-load dari user-writable path
   - Flag HIGH untuk path non-System32 non-user-writable

4. **Signed process load DLL dari user-writable path**:
   - Enum memory_maps proses system (svchost, lsass, csrss, winlogon, services, spoolsv, explorer, dwm, rundll32, regsvr32)
   - Flag CRITICAL kalau DLL yang di-load path-nya dari `%TEMP%`, `C:\Users\*`, dll
   - Indikator klasik DLL side-loading (Lazarus, APT41)

#### HMD-07 — LOLBAS Abuse Detection
Deteksi penyalahgunaan Living-Off-the-Land Binaries (18 LOLBin pattern):

| LOLBin | Pattern Abuse | Severity |
|--------|---------------|----------|
| `certutil.exe` | `-urlcache -f`, `-decode`, `-encode` | CRITICAL |
| `bitsadmin.exe` | `/transfer`, `/addfile`, `/setnotifycmdline` | CRITICAL |
| `regsvr32.exe` | Squiblydoo `/i:http://` | CRITICAL |
| `mshta.exe` | URL, `javascript:`, `vbscript:` | CRITICAL |
| `rundll32.exe` | `javascript:`, `shdocvw`, `.dll,#N` | HIGH |
| `wmic.exe` | XSL `/format:http://`, `process call create` | CRITICAL |
| `installutil.exe` | .NET assembly abuse | HIGH |
| `msbuild.exe` | Load `.xml`/`.proj` | MEDIUM |
| `cscript`/`wscript` | Script dari TEMP/AppData/Downloads/Public | HIGH |
| `forfiles.exe` | `/c cmd /c` proxy | HIGH |
| `fodhelper`, `computerdefaults`, `eventvwr`, `sdbinst` | UAC bypass | MEDIUM-LOW |
| `msiexec.exe` | Remote MSI `/i https://` | HIGH |
| `dnscmd.exe` | ServerLevelPluginDll (RCE) | CRITICAL |
| `control.exe` | `.cpl` dari user path | HIGH |

Scan di 3 tempat:
- Running process cmdline
- Scheduled task command
- Registry Run keys

#### HMD-08 — Living-off-the-Land Persistence
Deteksi persistence klasik yang dilakukan attacker **setelah masuk**:

1. **Defender Tamper Indicators** (9 registry check):
   - `DisableAntiSpyware = 1` → CRITICAL (Defender mati total)
   - `DisableRealtimeMonitoring = 1` → CRITICAL
   - `DisableBehaviorMonitoring = 1` → HIGH
   - `DisableOnAccessProtection = 1` → HIGH
   - `DisableScanOnRealtimeEnable = 1` → HIGH
   - `DisableIOAVProtection = 1` → HIGH (download scanning off)
   - Spynet/SubmitSamplesConsent/SpynetReporting disabled

2. **WDigest plaintext re-enabled** (post-exploit indicator):
   - `UseLogonCredential = 1` → CRITICAL (Mimikatz-ready)

3. **Office Trust Center Bypass** (per app × per version, 5 apps × 3 versions):
   - `VBAWarnings = 1` → CRITICAL (all macros enabled tanpa warning)
   - `DisableAttachmentsInPV = 1` → HIGH (attachment bypass Protected View)
   - `DisableInternetFilesInPV = 1` → HIGH (internet files bypass PV)

4. **Service DLL Hijack**:
   - Enum semua service, cek `Parameters\ServiceDLL`
   - Flag HIGH kalau DLL dari path non-System32 (svchost-based service harusnya load dari System32)

5. **Misc misconfig**:
   - Netlogon RequireSignOrSeal=0 (Zerologon vector)
   - Defender exclusion count > 20 (anomali)

### 📊 Statistik v2.0-alpha-M3

- **Total modul aktif:** 25 (dari 21 di M2.1, +4)
- **Total modul source code:** 26 (modul 5 Event Log tetap di source tapi disabled)
- **Total baris kode:** 4.357 (dari 3.579 di M2.1, +22%)
- **Database baru:** `BYOVD_DRIVERS` (30 entry) + `LOLBAS_PATTERNS` (18 pattern)
- **Dependencies baru:** TIDAK ADA — masih pakai library yang sama

### 🎯 Capability Progress vs Roadmap v2.0

| Pilar | Target | Sudah Ada | Progress |
|-------|--------|-----------|----------|
| **A** Vulnerability Assessment | 10 modul | 3 (VA-01, VA-03, VA-09) | 30% |
| **B** Hidden Malware Detection | 10 modul | **6** (HMD-01, 02, 03, 04, 07, 08) | **60%** |
| **C** Unauthorized Software | 8 modul | 3 (SUS-01, SUS-02, SUS-03) | 38% |
| **D** IOC / Timeline | 10 modul | 2 (IOC-05, IOC-06) | 20% |
| **TOTAL** | **38 modul** | **14 modul** | **37%** |

Pilar B (Hidden Malware Detection) sekarang sudah **60% coverage** — tools sudah masuk tier **semi-EDR** untuk deteksi malware tingkat lanjut.

### 🧪 Rekomendasi Testing M3

| Modul | Test Scenario |
|-------|---------------|
| **HMD-02** WMI Triplet | Buat WMI persistence manual via `wmic` → scan → harus flag CRITICAL |
| **HMD-02** Registry Payload | Buat REG_BINARY 2KB random → scan → harus flag HIGH |
| **HMD-02** BITS | `bitsadmin /create test` + set NotificationCmdLine → scan |
| **HMD-04** Unsigned Driver | Install unsigned driver test (sulit di Win10+ secure boot) atau cek default output di VM |
| **HMD-04** BYOVD | Install salah satu driver di BYOVD_DRIVERS list → scan → harus CRITICAL |
| **HMD-04** DLL Sideload | Copy DLL ke folder user, trigger svchost load — cek `tasklist /m` |
| **HMD-07** LOLBAS | Jalankan `certutil -urlcache -f http://example.com/test.txt test.txt` → scan |
| **HMD-08** Defender Tamper | `reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f` (lalu kembalikan) |
| **HMD-08** Office Macro | Office → Trust Center → "Enable all macros" → scan |

### 🔜 Milestone M4 — Kandidat

Sisa 4 modul HMD + sisa modul pilar lain:
- **HMD-05** Anti-Forensic (timestomping, ADS, shadow copy deletion)
- **HMD-06** In-Memory Indicators (named pipes Cobalt Strike, mutex, AMSI patch)
- **HMD-09** Hidden Accounts & Cross-view Rootkit Detection
- **HMD-10** Behavioral Beacon (sampling network)
- **VA-02** Vulnerable Third-Party Software (bangun CVE DB offline)
- **SUS-04** Crypto mining
- **SUS-05** Anonymization / Tor / VPN tak-dinas
- **SUS-06** Data exfiltration tools (rclone, dll)

---

## v2.0-alpha-M2.1 (23 November 2026 — hotfix)

Hotfix berdasarkan feedback testing awal M2:

### 🐛 Fix

1. **Modul 5 (Event Log Analysis) di-DISABLE** dari modules list
   - Comment-out di `modules = [...]` di `main()`
   - Function `check_event_logs()` tetap ada di source code untuk re-enable nanti kalau dibutuhkan
   - Alasan: user minta event log skip karena sulit PoC validasi tanpa simulasi serangan
   - **Total modul aktif sekarang: 21** (sebelumnya 22)

2. **Path file sekarang selalu visible di main row** (tidak tersembunyi di JSON "Lihat detail")
   - **SUS-02** `_flag` function: auto-merge `extra` parameter ke detail string jika berisi path
   - **SUS-03** `_flag` function: auto-append `path`/`service_name`/`subkey` dari `data` dict ke detail
   - **HMD-01** `_flag` function: auto-append `exe` path dari proses info ke detail

Dampak: output `audit_<HOST>.html` sekarang langsung menampilkan lokasi file di kolom detail — operator bisa verify lokasi tanpa harus klik tombol "Lihat detail" untuk setiap finding.

### Contoh sebelum/sesudah

**Sebelum (v2.0-alpha-M2):**
```
HIGH | File .nfo (warez release info): Install_Notes.nfo
     | File .nfo biasanya dari scene release warez (-CORE/-SKIDROW/-CODEX/dll)
     | [Lihat detail] ← path tersembunyi di sini
```

**Sesudah (v2.0-alpha-M2.1):**
```
HIGH | File .nfo (warez release info): Install_Notes.nfo
     | File .nfo biasanya dari scene release warez (-CORE/-SKIDROW/-CODEX/dll)
     | Path: C:\Program Files\CrackedApp\Install_Notes.nfo  ← langsung visible
```

---

## v2.0-alpha-M2 (23 November 2026)

Milestone kedua Phase 2 dari roadmap v2.0. Fokus: 5 modul baru untuk Vulnerability Assessment mendalam + USB & Execution forensik.

### 📌 Keputusan Scope

**Dihilangkan dari roadmap Phase 2:** IOC-01 Account Activity Anomaly (Event Log based). Alasan: validasi hasil deteksi event log sulit tanpa simulasi serangan / PoC riil. Modul event log existing (Modul 5) tetap ada tapi tidak di-expand.

### ✨ Modul Baru (5 dari target Phase 2)

#### VA-01 — Missing Patches & EOL Software
Audit security patch Windows:
- **Windows version check** dengan database EOL built-in (Win10 1507 s/d Win11 24H2)
  - Flag CRITICAL kalau build sudah EOL
  - Info untuk versi yang masih supported
- **Hotfix enumeration** via WMI `Win32_QuickFixEngineering` (fallback `wmic qfe`)
- **Critical KB cross-check** dengan database 17 CVE utama:
  - MS17-010 EternalBlue (CVE-2017-0144)
  - Zerologon (CVE-2020-1472)
  - PrintNightmare (CVE-2021-34527)
  - Follina (CVE-2022-30190)
  - PetitPotam, HiveNightmare, SeriousSAM
  - SMBGhost (CVE-2020-0796)
  - BlueKeep (CVE-2019-0708)
  - SigRed, ProxyLogon, BlackLotus
- Database tersimpan di `CRITICAL_KB_DATABASE` dict — update manual quarterly

#### VA-09 — Legacy Protocol & Weak Crypto
Audit SCHANNEL registry untuk TLS/SSL/cipher yang lemah:
- **Protocol versions** (8 kombinasi Server/Client):
  - SSL 2.0, SSL 3.0 → CRITICAL kalau enabled
  - TLS 1.0, TLS 1.1 → HIGH kalau enabled (MEDIUM kalau tidak eksplisit disabled)
- **Weak Cipher Suites**:
  - NULL (no encryption) → CRITICAL
  - RC4 (semua variant) → HIGH
  - DES 56-bit → HIGH
  - 3DES 168-bit → MEDIUM (SWEET32)
- **Weak Hash**:
  - MD5 → MEDIUM
  - SHA-1 → LOW
- **SMB Signing** (Server + Client):
  - `RequireSecuritySignature = 0` → HIGH (rentan SMB relay)
  - `EnableSecuritySignature = 0` → MEDIUM

#### SUS-03 — Unauthorized Remote Access Tools
Deteksi 26 remote access tools via 4 jalur:
1. Registry Uninstall (HKLM + WOW6432Node + HKCU)
2. Service name scan via `sc query`
3. Running process name/path
4. Listening port cross-check

**Severity policy:**
- CRITICAL: Tunneling tools yang bypass firewall perimeter (ngrok, Cloudflare Tunnel, Pinggy, Serveo, frpc)
- HIGH: NetSupport Manager (sering jadi C2 attacker)
- MEDIUM: Standard remote access (TeamViewer, AnyDesk, VNC variants, LogMeIn, GoToMyPC, Splashtop, Parsec, ScreenConnect)
- INFO: RDP built-in Windows (dengan warning untuk NLA)

**Port monitoring:** 5900 (VNC), 5938 (TeamViewer), 7070 (AnyDesk), 3389 (RDP), 8041 (ngrok)

#### IOC-05 — USB & Removable Media History
Parse 3 sumber untuk tahu semua USB yang pernah dicolok:
1. **USBSTOR Registry** (`HKLM\SYSTEM\CurrentControlSet\Enum\USBSTOR\*`):
   - Vendor, Product, Serial number
   - Friendly name
   - Satu entry per unique device
2. **setupapi.dev.log** parsing:
   - First install timestamp per device
   - Cross-reference serial number
3. **MountedDevices** registry:
   - Drive letter history untuk USB
   - Device ID binding

Berguna untuk investigasi: "USB apa yang pernah dicolok ke endpoint ini?"

#### IOC-06 — Program Execution History
Analisis 3 sumber forensik untuk eksekusi binary:
1. **UserAssist** (`HKCU\...\Explorer\UserAssist\*\Count`):
   - ROT13 decode nama binary
   - Fokus flag HIGH untuk binary dari path mencurigakan (TEMP, AppData, Downloads, Public)
2. **BAM / DAM** (`HKLM\SYSTEM\CurrentControlSet\Services\bam\*\UserSettings\<SID>`):
   - Background Activity Moderator — tracks all app executions
   - Flag HIGH kalau binary dari suspicious path
3. **Prefetch enhanced analysis**:
   - Deteksi binary yang sama dengan hash berbeda (indikator execution dari multiple path)
   - Skip system binaries umum (svchost, cmd, powershell, dll) untuk reduce noise

### 📊 Statistik v2.0-alpha-M2

- **Total modul:** 22 (17 di M1 + 5 baru)
- **Total baris kode:** 3.558 (dari 2.708 di M1, +31%)
- **Total ukuran:** ~247 KB (dari ~207 KB)
- **Dependencies baru:** TIDAK ADA — masih pakai library yang sama
- **Build command:** tetap sama

### 🧪 Rekomendasi Testing M2

Yang perlu di-test khusus untuk M2:
| Modul | Skenario Test |
|-------|---------------|
| VA-01 | Jalankan di VM Windows 10 1909 (EOL) → harus flag CRITICAL. Di Win11 22H2 → INFO |
| VA-09 | Default install biasanya OK. Untuk tes positive: enable SSL 2.0 via regedit sementara |
| SUS-03 | Install TeamViewer trial → harus terdeteksi via registry + service + process |
| IOC-05 | Colok USB flash drive baru → scan → harus muncul serial-nya di USBSTOR |
| IOC-06 | Jalankan binary dari `%TEMP%\test.exe` → scan → harus terdeteksi via BAM/UserAssist |

### 🔜 Next Milestone Candidates

Pilihan modul untuk M3 (Phase 3):
- **HMD-02** Fileless persistence (WMI full triplet + registry payload + BITS)
- **HMD-04** Signature anomaly + BYOVD check
- **HMD-07** LOLBAS abuse detection
- **HMD-08** LotL persistence (Defender tampered)
- **SUS-04** Crypto mining
- **SUS-05** Anonymization/tunneling (Tor, VPN tak-dinas)
- **SUS-06** Data exfiltration tools (rclone, dll)

Prioritas tergantung feedback dari testing M1 + M2 di endpoint riil.

---

## v2.0-alpha-M1 (20 November 2026)

Milestone pertama Phase 1 dari roadmap v2.0. Fokus: bug fix + 5 modul baru.

### 🐛 Bug Fixes (6 bugs dari v1.0)

| # | Bug | Perubahan |
|---|-----|-----------|
| 1 | HTML line 919 pakai backtick `` ` `` sebagai pembuka string atribut HTML | Diganti dengan `"` — tombol "Lihat detail" di report sekarang berfungsi |
| 2 | MD5 hanya hash 1 MB pertama file (tidak bisa cross-check VirusTotal) | Full-file MD5 + SHA256 untuk file ≤ 50 MB |
| 3 | `schtasks` CSV parsing pakai `split(',')` naif | Diganti `csv.reader` dengan quote handling + auto-detect kolom per locale |
| 4 | `driverquery` CSV parsing idem | Diganti `csv.reader` dengan quote handling |
| 5 | Report overwrite karena nama file tanpa timestamp | Nama file sekarang `audit_<HOST>_<TIMESTAMP>.html` + `.json` |
| 6 | Report hanya HTML (tidak bisa di-feed ke SIEM) | Tambah export JSON terstruktur paralel dengan HTML |

### ✨ Modul Baru (5 dari 38 target v2.0)

#### VA-03 — Security Feature Posture Audit
Audit konfigurasi fitur keamanan built-in Windows:
- Defender Real-time Protection status (policy + lokal)
- Defender Tamper Protection
- Defender Behavior Monitoring + Script Scanning
- Defender Exclusions (flag HIGH jika di user-writable path, CRITICAL jika ekstensi `.exe`/`.dll`)
- UAC status (EnableLUA + ConsentPromptBehaviorAdmin)
- LSA Protection (RunAsPPL)
- Firewall per profile (Domain/Private/Public)
- SMBv1 enabled (via PowerShell `Get-SmbServerConfiguration`)
- WDigest plaintext (Mimikatz enabler)
- NTLMv1 allowed (LmCompatibilityLevel)
- LM Hash stored (NoLMHash)

#### SUS-01 — Hacking & Pentest Tools Detection
Deteksi 50+ hacking tools via 4 jalur:
1. Registry Uninstall (HKLM + WOW6432Node + HKCU)
2. Running processes
3. Install folder scan di Program Files
4. Prefetch cross-check (bahkan untuk binary yang sudah dihapus)

Kategori: Network Scanner, Packet Capture/MITM, Web Pentest, Exploitation Framework (Metasploit/CobaltStrike/Sliver/dll), Password Cracker, Credential Dumper (Mimikatz/LaZagne), Reverse Engineering, PowerShell Framework (Empire/PowerSploit).

#### SUS-02 — Pirated / Cracked Software Detection
Deteksi software bajakan via 6 jalur:
1. **KMS Activator** detection: service name, scheduled task, registry, install folder (KMSAuto, KMSPico, MAS-AIO, HWIDGen, Windows Loader, Ratiborus, dll)
2. **Windows Activation Status** via `slmgr.vbs /dlv`: flag Notification mode, Grace period, KMS→localhost (crack confirmed)
3. **Office Activation Status** via `OSPP.VBS /dstatus`: flag KMS→localhost
4. **Hosts file manipulation**: parse untuk block domain Adobe/Autodesk/JetBrains/Microsoft activation
5. **Crack artifact scanning** di Program Files: folder `Crack`/`Keygen`/`Patch`/`Loader`/`Activator`, file `.nfo` (warez scene), binary `amtlib.dll`/`xf-adsk*`/`keygen.exe`
6. **Port 1688 listening** oleh non-Microsoft binary (KMS emulator lokal)

#### HMD-01 — Process Stealth Detection
Deteksi malware yang menyamar sebagai proses system:
1. **Masquerading**: nama system binary (`svchost.exe`, `lsass.exe`, `csrss.exe`, dll) dari path SELAIN `System32`
2. **Unicode homoglyph**: karakter non-ASCII di nama proses (Cyrillic `а` menyamar `a`, dll)
3. **Parent-child anomaly matrix**:
   - Office (Word/Excel/PowerPoint/Outlook) → script engine = Office macro malware
   - Web server (w3wp/httpd/tomcat) → cmd/powershell = web shell
   - winlogon.exe → child non-standard
   - explorer.exe → powershell -enc
4. **Command-line obfuscation**: 13 pattern regex (PowerShell encoded, IEX, DownloadString, certutil abuse, bitsadmin, Squiblydoo, mshta remote, rundll32 javascript, wmic XSL, dll)
5. **Entropy check**: cmdline > 100 char dengan Shannon entropy > 5.0 (possible obfuscated payload)
6. **System-like names dari user-writable path**: proses bernama `svc*`/`ms*`/`win*`/`sys*` dari TEMP/APPDATA

#### HMD-03 — Obscure Persistence Locations (15 lokasi)
Scan 15 lokasi persistence tersembunyi (expansion dari 5 lokasi di v1.0 modul 3):
1. **IFEO Debugger hijack** (klasik: sethc.exe/osk.exe/utilman.exe)
2. **AppInit_DLLs** (HKLM + WOW64)
3. **LSA Notification/Security/Authentication Packages** (Mimikatz memssp)
4. **Winlogon** (Userinit/Shell/Taskman/GinaDLL/AppSetup modification)
5. **COM hijacking** (HKCU shadow HKLM di CLSID\InprocServer32)
6. **Office Test key** (`Software\Microsoft\Office test\Special\Perf`)
7. **Office Addins HKCU** (per app × per version)
8. **Print Monitors** non-standard (PrintNightmare era vector)
9. **Netsh helper DLLs** non-standard
10. **ShellExecuteHooks** non-default
11. **SCRNSAVE.EXE** dari path non-standar
12. **BootExecute** entry non-default (pre-login execution)
13. **AppCertDlls** (DLL di-load setiap CreateProcess)
14. **PowerShell profile scripts** (4 lokasi)
15. **Scheduled task** dengan PowerShell encoded command

### 📊 Statistik v2.0-alpha-M1

- **Total modul:** 17 (12 lama + 5 baru)
- **Total baris kode:** 2.708 (dari 1.496 di v1.0, +81%)
- **Total ukuran:** ~207 KB (dari ~153 KB)
- **Dependencies baru:** TIDAK ADA (semua pakai standard library + psutil/pywin32/wmi yang sudah ada)
- **Build command:** tetap sama (`build.bat`), tidak ada perubahan hidden-import

### 📝 Output Baru

Setiap scan menghasilkan 2 file:
- `audit_<HOSTNAME>_<TIMESTAMP>.html` — report HTML interaktif (sama seperti v1.0 tapi fix bug line 919)
- `audit_<HOSTNAME>_<TIMESTAMP>.json` — export JSON terstruktur untuk SIEM/arsip/baseline diff

### 🧪 Rekomendasi Testing

Sebelum deploy ke endpoint produksi, uji di:
1. **VM Windows 10/11 bersih** — pastikan zero false positive
2. **VM dengan aplikasi legit** (Office, Adobe trial, dll) — pastikan tidak di-flag salah
3. **Mesin dengan KMS activator** (kalau ada untuk testing) — pastikan SUS-02 deteksi
4. **Mesin dengan Wireshark/Nmap terinstal** (untuk testing SUS-01)

### 🔜 Next Milestone (v2.0-alpha-M2)

Rencana Session 2:
- **IOC-05** USB history (registry USBSTOR + setupapi.dev.log)
- **IOC-06** Program execution history (UserAssist + Prefetch deep parse + BAM)
- **VA-01** Patch audit (hotfix cross-check dengan daftar critical KB)
- **VA-09** Legacy protocol & weak crypto (SMBv1, NTLMv1, WDigest, TLS lama)
- Bug fix dari feedback hasil tes M1

---

## v1.0 — Baseline (sebelum pengembangan v2.0)

Tools original dengan 12 modul IR/forensic. Lihat `README.md` untuk detail.
