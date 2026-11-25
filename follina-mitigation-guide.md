# Panduan Mitigasi Follina (CVE-2022-30190)

**Versi Dokumen:** 1.0 (25 November 2026)
**Target Audiens:** Security operator yang menangani endpoint Windows
**Penyusun:** Lettu Lek Ahmad Fauzan Langga, S.T.

---

## 1. Ringkasan Eksekutif

**Follina** (CVE-2022-30190) adalah kerentanan **Remote Code Execution (RCE)** di komponen **Microsoft Support Diagnostic Tool (MSDT)** yang memungkinkan attacker menjalankan kode arbitrary melalui dokumen Office berbahaya **tanpa perlu Enable Macro**.

- **CVSS Score:** 7.8 (HIGH, dalam praktik CRITICAL)
- **Published:** 30 Mei 2022 (zero-day — eksploit ditemukan sebelum patch)
- **Patch resmi:** KB5014754 (14 Juni 2022)
- **Status 2026:** Fix sudah di-include dalam **semua cumulative update (CU)** sejak Juli 2022
- **Dampak:** Full RCE dengan privilege user yang buka dokumen

---

## 2. Cara Kerja Follina (Technical Deep-Dive)

### 2.1 Attack Chain

```
┌─────────────────────────────────────────────────────────────────┐
│                       FOLLINA ATTACK CHAIN                      │
└─────────────────────────────────────────────────────────────────┘

[1] Attacker membuat dokumen Word berbahaya (.docx / .rtf)
    └── Berisi reference ke template HTML eksternal
    └── Template HTML punya payload URL schema: ms-msdt://

[2] User menerima dokumen via:
    ├── Email phishing (attachment)
    ├── Download dari website (link)
    ├── Share via chat/messenger
    └── USB drop

[3] User buka dokumen di Word
    └── TIDAK PERLU Enable Macro!
    └── TIDAK PERLU Protected View bypass (dalam beberapa kasus)
    └── Bahkan .rtf bisa trigger dari preview pane di Explorer

[4] Word parse template eksternal → HTML di-load
    └── HTML berisi: <iframe src="ms-msdt:/id PCWDiagnostic /skip force /param
         'IT_RebrowseForFile=? IT_LaunchMethod=ContextMenu
          IT_SelectProgram=NotListed IT_BrowseForFile=h$(payload)i/..'">

[5] Windows OS auto-launch MSDT sesuai URL schema
    └── MSDT execute parameter yang berisi PowerShell payload

[6] CODE EXECUTION
    ├── Download tahap berikutnya (ransomware / infostealer / RAT)
    ├── Persistence installation
    ├── Credential harvesting
    └── Lateral movement initialization
```

### 2.2 Technical Root Cause

Vulnerability ada di **URL schema handler `ms-msdt://`** yang:
1. Tidak melakukan sanitasi parameter dengan benar
2. Allow injection payload PowerShell via parameter `IT_BrowseForFile`
3. Execute payload tanpa warning / sandbox

### 2.3 Kenapa Follina Sangat Berbahaya?

| Faktor | Penjelasan |
|--------|-----------|
| **Zero-click dari .rtf** | File .rtf tidak perlu dibuka, preview di Explorer saja cukup |
| **Bypass Protected View** | Tidak perlu user klik "Enable Editing" |
| **Tidak perlu macro** | Macro-based defense (disable macro) tidak efektif |
| **Payload via PowerShell** | PowerShell = powerful, bisa download tahap berikutnya |
| **Living-off-the-Land** | MSDT & PowerShell = tools bawaan Windows, bypass whitelisting |
| **Wormable** | Bisa dikombinasi dengan phishing massal untuk spread cepat |

---

## 3. Verifikasi: Apakah Endpoint Sudah Aman?

### 3.1 Metode #1 — Cek Windows Update History (PALING AKURAT)

```powershell
# Buka PowerShell sebagai Administrator, jalankan:
Get-WinEvent -LogName 'Microsoft-Windows-WindowsUpdateClient/Operational' |
    Where-Object { $_.Message -like '*KB5014754*' -or $_.Message -like '*Juni 2022*' } |
    Select-Object TimeCreated, Message | Format-List
```

Atau GUI: **Settings → Windows Update → Update history** → cari "Cumulative Update for Windows" setelah Juni 2022.

**Interpretasi:**
- **Aman** kalau ada CU terinstall setelah Juli 2022
- **Perlu verifikasi** kalau last update sebelum Juni 2022

### 3.2 Metode #2 — Cek Build Number Windows

```powershell
[System.Environment]::OSVersion.Version
# Atau:
winver
```

Tabel aman (fix Follina sudah included):

| Windows Version | Build Minimum Aman |
|-----------------|-------------------|
| Windows 10 1809 | 17763.3046 (Juni 2022) |
| Windows 10 20H2/21H1/21H2 | 19042.1766 / 19043.1766 / 19044.1766 |
| Windows 10 22H2 | 19045.xxx (semua aman) |
| Windows 11 21H2 | 22000.739 |
| Windows 11 22H2 | 22621.xxx (semua aman) |
| Windows 11 23H2 | 22631.xxx (semua aman) |
| Windows 11 24H2 | 26100.xxx (semua aman) |
| **Windows 11 25H2+ (build 26300+)** | **Semua aman** (jauh setelah patch) |

### 3.3 Metode #3 — Cek Specific KB

```powershell
$follina_fix_kbs = @(
    "KB5014697",   # Windows 11 Juni 2022
    "KB5014747",   # Win10 1809 Juni 2022
    "KB5014754",   # Main Follina patch
    "KB5014692",   # Win10 20H2/21H1/21H2 Juni 2022
)

Get-HotFix | Where-Object { $_.HotFixID -in $follina_fix_kbs } |
    Select-Object HotFixID, InstalledOn
```

---

## 4. Mitigasi

### 4.1 Opsi A — Windows Update (RECOMMENDED)

1. Buka **Settings → Windows Update**
2. **Check for updates** + install semua Quality Update
3. **Restart** endpoint
4. Verify dengan metode #1

### 4.2 Opsi B — Manual Install KB5014754

1. Download dari [Microsoft Update Catalog](https://www.catalog.update.microsoft.com/Search.aspx?q=KB5014754)
2. Pilih versi sesuai OS (x64/x86/ARM64)
3. Install sebagai Administrator → Restart

### 4.3 Opsi C — Workaround (DARURAT)

Microsoft's official workaround — disable MSDT URL Protocol:

```cmd
:: Command Prompt as Administrator

:: 1. Backup registry MSDT handler
reg export HKEY_CLASSES_ROOT\ms-msdt C:\msdt_backup.reg

:: 2. Delete MSDT URL handler
reg delete HKEY_CLASSES_ROOT\ms-msdt /f
```

Restore setelah patch:
```cmd
reg import C:\msdt_backup.reg
```

### 4.4 Opsi D — Defense in Depth (Hardening)

#### D1. Disable Office Template Loading dari URL Eksternal

```powershell
$office_versions = @("16.0", "15.0", "14.0")
foreach ($ver in $office_versions) {
    foreach ($app in @("Word", "Excel", "PowerPoint", "Outlook")) {
        $path = "HKCU:\Software\Microsoft\Office\$ver\$app\Security"
        if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "BlockContentExecutionFromInternet" -Value 1 -Type DWord
        Set-ItemProperty -Path $path -Name "DisableInternetFilesInPV" -Value 0 -Type DWord
    }
}
```

#### D2. Enable Windows Defender ASR Rules

```powershell
# Block Office apps from creating child processes
Add-MpPreference -AttackSurfaceReductionRules_Ids D4F940AB-401B-4EFC-AADC-AD5F3C50688A `
                 -AttackSurfaceReductionRules_Actions Enabled

# Block Office from injecting code into other processes
Add-MpPreference -AttackSurfaceReductionRules_Ids 75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84 `
                 -AttackSurfaceReductionRules_Actions Enabled

# Block executable content from email
Add-MpPreference -AttackSurfaceReductionRules_Ids BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550 `
                 -AttackSurfaceReductionRules_Actions Enabled
```

#### D3. Disable MSDT Troubleshooting Wizards

```powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\ScriptedDiagnostics" `
                 -Name "EnableDiagnostics" -Value 0 -Type DWord
```

---

## 5. Validasi Pasca-Mitigasi

### 5.1 Verifikasi Handler MSDT

```powershell
$testHandler = Get-ItemProperty "HKLM:\SOFTWARE\Classes\ms-msdt" -ErrorAction SilentlyContinue
if ($testHandler) {
    Write-Host "ms-msdt handler still registered. Verify via Windows Update History." -ForegroundColor Yellow
} else {
    Write-Host "ms-msdt handler removed (workaround applied)." -ForegroundColor Green
}
```

### 5.2 Scan Ulang via Satsiberau Audit Tool

```cmd
SatsiberauAudit.exe
```

Expected setelah M3.4:
- Follina → **LOW** (kemungkinan superseded) dengan note verifikasi manual
- Bukan lagi CRITICAL false alarm

---

## 6. Prosedur Response per Kategori Endpoint

| Kategori | Tindakan |
|----------|----------|
| **Endpoint Modern** (Win11 22H2+, Win10 22H2, Win Server 2022+) | Verify via Windows Update History. Kalau CU 2022+ terinstall → DONE |
| **Endpoint Semi-Modern** (Win10 21H2, Win11 21H2, Win Server 2019) | Force install CU terbaru via Windows Update |
| **Endpoint Legacy** (Win10 1809 LTSC, Win Server 2016) | Install KB5014754 manual atau CU terbaru dari Update Catalog |
| **Endpoint EOL** (Win10 1507-1909, Win7, Win8.1) | Apply workaround (delete MSDT handler) + rencana upgrade segera |

### Reporting Template

```
LAPORAN HASIL MITIGASI FOLLINA - CVE-2022-30190

Endpoint       : [Hostname / IP]
OS Version     : [winver output]
Patch Status   : [ ] Patched via CU [ ] Workaround applied [ ] Belum
Verifikasi     : [Metode yang dipakai]
KB Terpasang   : [Daftar KB relevan yang ditemukan]
Hardening      : [ ] D1 Office [ ] D2 ASR Rules [ ] D3 Disable MSDT
Tanggal        : [DD/MM/YYYY]
Operator       : [Nama + NRP]
```

---

## 7. Referensi

- **CVE-2022-30190** (MITRE): https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-30190
- **MSRC**: https://msrc.microsoft.com/update-guide/vulnerability/CVE-2022-30190
- **KB5014754**: https://www.catalog.update.microsoft.com/Search.aspx?q=KB5014754
- **ASR Rules Reference**: https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-reference
- **PoC Follina** (edukasi, lab only): https://github.com/JohnHammond/msdt-follina

---

## 8. Catatan untuk Audit Tool v2.0-alpha-M3.4+

Satsiberau Audit Tool v2.0-alpha-M3.4 sekarang **otomatis handle KB supersedence**:

- Patches dari 2021-2023 (termasuk Follina) **di-downgrade** ke **LOW** untuk Windows build modern
- Finding bertuliskan "**Patch XXX (kemungkinan superseded via CU)**" dengan hint verifikasi
- Summary audit menampilkan breakdown: Missing (confirmed) / Likely superseded / Non-applicable

Ini mengurangi false alarm dari CRITICAL misleading ke LOW informational untuk endpoint yang sudah modern dan ter-update.

---

**Lettu Lek Ahmad Fauzan Langga, S.T.**
**Satuan Siber TNI Angkatan Udara**
*Vâyusenã Mâyãvarman*
