# Security Policy

## 🛡️ Supported Versions

Hanya versi berikut yang menerima security update aktif:

| Version | Supported |
|---------|-----------|
| 2.0-alpha-M3.4 | ✅ Yes (current) |
| 2.0-alpha-M3.x (M3.0 - M3.3) | ⚠️ Transitional (upgrade recommended) |
| 1.x | ❌ No (deprecated) |

Pengguna versi lama **sangat disarankan upgrade** ke versi terbaru.

---

## 🚨 Reporting a Vulnerability

Apabila Anda menemukan kerentanan keamanan pada tool ini, **JANGAN** laporkan melalui GitHub Issues publik.

### Jalur Pelaporan yang Benar:

#### Untuk Internal Satsiberau TNI AU:
Hubungi langsung:
- **Penanggung Jawab Tool:** Lettu Lek Ahmad Fauzan Langga, S.T.
- **Jalur Dinas:** Komando Satuan Siber TNI AU
- **Email Dinas:** (gunakan email institusional yang berlaku)

#### Untuk Pelapor Eksternal:
- Buat laporan via **GitHub Security Advisories** (tab Security → Advisories → New draft security advisory)
- Atau kirim enkripsi via PGP (public key akan di-publish terpisah)

### Informasi yang Perlu Disertakan:

1. **Deskripsi vulnerability** — apa yang rentan, dimana, bagaimana trigger-nya
2. **Proof of Concept (PoC)** — minimal reproducer, screenshot, atau video
3. **Impact assessment** — apa yang bisa dilakukan attacker
4. **Suggested fix** — kalau ada rekomendasi mitigasi
5. **Discovery context** — bagaimana Anda menemukan ini (research, testing, dll)
6. **Disclosure timeline preference** — kapan Anda ingin publikasi fix

### Response Timeline:

| Severity | Response Awal | Fix Target |
|----------|---------------|------------|
| 🔴 Critical | ≤ 48 jam | ≤ 7 hari |
| 🟠 High | ≤ 72 jam | ≤ 14 hari |
| 🟡 Medium | ≤ 7 hari | ≤ 30 hari |
| 🔵 Low | ≤ 14 hari | Next release |

---

## 🔒 Known Security Considerations

### 1. Hardcoded Password Hash
Password gate SHA-256 hash **harus diubah** sebelum deployment di luar environment internal Satsiberau. Lihat section "Keamanan Operasional" di [README.md](./README.md).

### 2. Administrator Privilege Requirement
Tool memerlukan **Administrator privilege** untuk akses registry, prefetch, WMI, dan driver enumeration. Jangan jalankan via LocalSystem atau SYSTEM context kecuali benar-benar diperlukan.

### 3. Report HTML Berisi Sensitive Data
Output report HTML dapat berisi:
- Hostname, OS version, build number
- Daftar installed software
- USB history (serial numbers)
- User account names
- Registry values yang bisa jadi sensitive

**Treat all reports as CONFIDENTIAL** — jangan upload ke public storage/sharing.

### 4. .gitignore Default Sudah Block Report
File `audit_*.html`, `*.json`, dan pattern report lainnya sudah di-ignore oleh `.gitignore`. Pastikan Anda **tidak force-add** file tersebut saat commit.

---

## 🧪 Security Testing di Lab

Developer/contributor disarankan test perubahan di **isolated VM** dengan snapshot sebelum deploy ke production endpoint. Rekomendasi:

- **VM Platform:** VirtualBox, VMware Workstation, Hyper-V
- **OS Target:** Windows 10 22H2 + Windows 11 (21H2, 23H2, 24H2)
- **Baseline Snapshot:** Clean install + sysinternals installed
- **Test Scenario:** Clean, Compromised (Follina PoC in isolated VM), Hardened (CIS Benchmark)

---

## 📜 Responsible Disclosure Principles

Kami menghargai komunitas security researcher yang melakukan responsible disclosure. Dengan melaporkan via jalur resmi (bukan publik), Anda membantu:

1. **Melindungi pengguna** yang belum sempat patch
2. **Memberikan waktu** untuk menyiapkan fix yang proper
3. **Mencegah eksploitasi** sebelum solusi tersedia

Setelah fix tersedia dan di-release, kontribusi Anda akan diapresiasi:
- Credit di CHANGELOG.md (dengan izin)
- Acknowledgment di README.md (kalau signifikan)

---

## 🚫 Out of Scope

Hal-hal berikut **BUKAN** security vulnerability:
- Perilaku yang sudah di-dokumentasikan (bukan hidden)
- Issue yang memerlukan physical access ke endpoint
- Social engineering attacks (bukan vulnerability tool)
- Issue pada dependency eksternal (lapor ke upstream)
- False positive detection (laporkan via GitHub Issues biasa)

---

**Terima kasih atas kontribusi untuk meningkatkan keamanan tool ini.**

*Satuan Siber TNI Angkatan Udara*
*Vâyusenã Mâyãvarman*
