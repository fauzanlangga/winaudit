# Satsiberau Endpoint Security Audit Tool (SSAUDIT)

![Version](https://img.shields.io/badge/version-v2.0--alpha--M3.4-blue)
![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-informational)
![Python](https://img.shields.io/badge/python-3.11%2B-green)
![Status](https://img.shields.io/badge/status-Alpha-orange)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

Tool audit keamanan offline untuk endpoint Windows (laptop/komputer) yang dikembangkan oleh **Satuan Siber TNI Angkatan Udara (Satsiberau)**. Dirancang untuk melakukan assessment komprehensif pada endpoint yang **tidak memiliki akses internet** (air-gapped environment), tanpa perlu instalasi agent atau dependensi cloud.

---

## 📋 Daftar Isi

- [Fitur Utama](#-fitur-utama)
- [Arsitektur: 4 Pillar](#-arsitektur-4-pillar)
- [Persyaratan Sistem](#-persyaratan-sistem)
- [Instalasi](#-instalasi)
- [Build dari Source](#-build-dari-source)
- [Penggunaan](#-penggunaan)
- [Output Report](#-output-report)
- [Keamanan Operasional](#-keamanan-operasional)
- [Roadmap](#-roadmap)
- [Disclaimer](#-disclaimer)
- [Lisensi](#-lisensi)
- [Author](#-author)

---

## ✨ Fitur Utama

- **100% Offline** — Tidak memerlukan koneksi internet saat runtime
- **Single Executable** — Portable `.exe` sekitar 10-15 MB (via PyInstaller)
- **Password Gate** — SHA-256 authentication sebelum scan
- **Interactive HTML Report** — Filter per severity/category, search, JSON export
- **26 Modul Aktif** — 4 pillar comprehensive assessment
- **False Positive Reduction** — Vendor whitelist 100+ patterns, OS-aware supersedence check
- **Forensic Artifacts** — UserAssist, BAM, Prefetch, USB history parsing
- **Watermark Digital** — Operator & endpoint tracking untuk chain-of-custody

---

## 🏛️ Arsitektur: 4 Pillar

### Pillar 1: Vulnerability Assessment (VA)
Menilai postur keamanan dan patch status endpoint.

| Modul | Nama | MITRE ATT&CK |
|-------|------|--------------|
| VA-01 | Missing KB Patches + Supersedence Heuristic | - |
| VA-03 | Windows Defender Tamper Protection | T1562.001 |
| VA-09 | SMB Signing & TLS Protocols | T1557 |

### Pillar 2: Hidden Malware Detection (HMD)
Mendeteksi indikasi malware tersembunyi via forensic artifacts.

| Modul | Nama | MITRE ATT&CK |
|-------|------|--------------|
| HMD-01 | Suspicious Executables in AppData/Temp | T1105 |
| HMD-03 | WMI Event Subscription Persistence | T1546.003 |
| HMD-04 | Unsigned Driver Detection (BYOVD) | T1068 |
| HMD-07 | LOLBAS Pattern Detection | T1218 |
| HMD-08 | Defender Tampering (Registry) | T1562.001 |

### Pillar 3: Unauthorized Software (SUS)
Mendeteksi aplikasi yang tidak sah atau berpotensi berbahaya.

| Modul | Nama | Kategori |
|-------|------|----------|
| SUS-01 | Hacking Tools Detection | Burp Suite, Mimikatz, Cobalt Strike, dll (50+) |
| SUS-02 | KMS/Crack Activators | KMSPico, AAct, Re-Loader, dll |
| SUS-03 | Portable Suspicious Tools | PsExec, Process Hacker, dll |

### Pillar 4: Indicators of Compromise (IOC)
Menganalisis forensic evidence aktivitas mencurigakan.

| Modul | Nama | Artifact |
|-------|------|----------|
| IOC-05 | USB Storage History | Registry (USBSTOR, MountedDevices) |
| IOC-06 | UserAssist Execution History | Registry (NTUSER.DAT, ROT13) |

---

## 💻 Persyaratan Sistem

### Runtime (Target Endpoint)
- **OS:** Windows 10 (1809+) atau Windows 11 (semua versi)
- **Privilege:** Administrator (wajib — untuk akses registry, prefetch, WMI)
- **RAM:** Minimal 512 MB free
- **Disk:** ~50 MB untuk tool + report
- **Internet:** **TIDAK DIPERLUKAN** saat runtime

### Development (Build Environment)
- Python 3.11 atau lebih baru
- Windows 10/11 (untuk build target native)
- PyInstaller 6.x

---

## 📥 Instalasi

### Opsi A: Download Pre-built Executable
Unduh `SatsiberauAudit.exe` dari halaman [Releases](../../releases).

### Opsi B: Build dari Source (lihat section di bawah)

---

## 🔨 Build dari Source

### 1. Clone Repository
```bash
git clone https://github.com/<your-org>/satsiberau-endpoint-audit.git
cd satsiberau-endpoint-audit
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Jalankan Build Script
```cmd
build.bat
```

Output executable akan ada di: `dist\SatsiberauAudit.exe`

### 4. Manual Build (Advanced)
```cmd
pyinstaller --onefile --uac-admin --name SatsiberauAudit ^
    --hidden-import=psutil ^
    --hidden-import=wmi ^
    --hidden-import=win32com.client ^
    --hidden-import=win32evtlog ^
    --hidden-import=win32security ^
    --hidden-import=win32api ^
    audit.py
```

---

## 🚀 Penggunaan

### 1. Jalankan sebagai Administrator
Klik kanan `SatsiberauAudit.exe` → **Run as Administrator**

### 2. Masukkan Password
Default: **[HARUS DIGANTI SEBELUM DEPLOYMENT]** — lihat section [Keamanan Operasional](#-keamanan-operasional)

### 3. Tunggu Scan Selesai
Scan biasanya memakan waktu **2-5 menit** tergantung ukuran endpoint.

### 4. Buka Report HTML
Report otomatis ter-generate di folder yang sama dengan nama:
```
audit_<HOSTNAME>_<YYYYMMDD>_<HHMMSS>.html
```

---

## 📊 Output Report

Report HTML interaktif berisi:

- **Header** — Operator, hostname, OS version, scan timestamp, watermark
- **Summary Dashboard** — Count per severity (CRITICAL/HIGH/MEDIUM/LOW/INFO)
- **Finding List** — Kolom: severity, module, title, detail, raw data
- **Filter & Search** — Per severity, per module, atau keyword search
- **JSON Export** — Button untuk export seluruh findings ke `.json`
- **Detail Modal** — Klik "Lihat detail" untuk raw data per finding

### Contoh Severity Mapping

| Severity | Warna | Contoh |
|----------|-------|--------|
| 🔴 CRITICAL | Red | Defender fully disabled, WMI persistence, Mimikatz detected |
| 🟠 HIGH | Orange | SMB signing off, Tamper Protection off, Burp Suite installed |
| 🟡 MEDIUM | Yellow | SMB client signing off, TLS 1.0 not explicitly disabled |
| 🔵 LOW | Blue | OEM driver unsigned, patch likely superseded |
| ⚪ INFO | Grey | Normal admin accounts, USB history, startup items vendor OK |

---

## 🔐 Keamanan Operasional

### ⚠️ WAJIB: Ganti Password Default Sebelum Deployment

Password default `@Cyber2026` hanya untuk testing internal Satsiberau. **Setiap instansi WAJIB membuat password unik sendiri.**

#### Cara Mengganti Password:

1. Generate hash SHA-256 password baru:
```python
import hashlib
password_baru = "<password_pilihan_anda>"
hash_baru = hashlib.sha256(password_baru.encode()).hexdigest()
print(hash_baru)
```

2. Edit `audit.py` baris ~47:
```python
_H = "<paste_hash_baru_disini>"
```

3. Rebuild executable dengan `build.bat`.

### 📌 Best Practices

- **Air-gapped operation** — tool tidak akan pernah memanggil internet
- **Chain of custody** — simpan report + hash SHA-256 report di secure storage
- **Access control** — bagikan executable hanya ke operator berwenang
- **Report classification** — treat as CONFIDENTIAL (berisi sensitive endpoint info)
- **Audit trail** — operator & timestamp ter-watermark di setiap report

---

## 🗺️ Roadmap

Lihat [CHANGELOG.md](./CHANGELOG.md) untuk detail per release.

### Current (v2.0-alpha-M3.4)
- ✅ 4 Pillar Architecture (VA + HMD + SUS + IOC)
- ✅ 26 active modules
- ✅ FP reduction gelombang 4 (signal-to-noise ~95%)
- ✅ KB Supersedence Heuristic

### Planned v2.0-beta (Q1 2027)
- [ ] VA-02: Service Misconfiguration
- [ ] VA-04-08: Firewall, UAC, BitLocker, Credential Guard, LAPS
- [ ] HMD-05: Scheduled Task Hidden Persistence
- [ ] HMD-06: Reflective DLL Injection Detection
- [ ] HMD-09: Alternate Data Stream (ADS) Detection
- [ ] IOC-01-04: Shimcache, Amcache, SRUM, Timeline
- [ ] IOC-07-10: Network artifacts, DNS cache, Recent files

### Planned v2.1 (Q2 2027)
- [ ] YARA integration (offline rules)
- [ ] IOC matching (file hash blacklist)
- [ ] Baseline comparison (delta scan)
- [ ] CLI mode untuk headless scan

### Documentation
- 📘 [Blueprint v2.0](./docs/blueprint-v2.md) — Arsitektur lengkap
- 🛡️ [Panduan Mitigasi Follina](./docs/follina-mitigation-guide.md) — CVE-2022-30190

---

## ⚖️ Disclaimer

Tool ini dirancang untuk **assessment defensif internal** oleh personel berwenang. Penggunaan di luar lingkungan yang di-authorize adalah **tanggung jawab penuh pengguna**.

- **BUKAN** tool untuk offensive security atau unauthorized access
- **BUKAN** pengganti EDR/XDR solution komersial
- **BUKAN** menggantikan penetration testing profesional
- **TIDAK** disertai jaminan apapun (lihat [LICENSE](./LICENSE))

Hasil scan bersifat **indikatif** — verifikasi lebih lanjut (manual investigation, cross-check dengan sumber lain) tetap diperlukan sebelum mengambil tindakan konkret.

---

## 📄 Lisensi

Didistribusikan di bawah lisensi MIT dengan attribution ke Satsiberau. Lihat [LICENSE](./LICENSE) untuk detail.

---

## 👤 Author

**Lettu Lek Ahmad Fauzan Langga, S.T.**
Satuan Siber TNI Angkatan Udara (Satsiberau)
*Vâyusenã Mâyãvarman*

---

## 🙏 Acknowledgments

- **MITRE ATT&CK®** — framework mapping
- **LOLBAS Project** — Living-off-the-Land binaries database
- **Microsoft Security Response Center** — patch references
- **Satsiberau Team** — testing, feedback, dan validasi di lapangan

---

## 📞 Kontak

Untuk pertanyaan internal Satsiberau, laporan bug, atau security issue:
- **Issues GitHub:** [GitHub Issues](../../issues) (untuk bug & feature request umum)
- **Security Issues:** lihat [SECURITY.md](./SECURITY.md) (jangan lapor via Issues publik)

---

*Dikembangkan dengan dedikasi untuk mendukung ketahanan siber TNI Angkatan Udara.*
