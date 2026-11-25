# Contributing to Satsiberau Endpoint Audit Tool

Terima kasih atas minat Anda untuk berkontribusi pada tool ini!

---

## 🎯 Kategori Kontribusi yang Diterima

### 1. Bug Reports
Laporkan bug via **GitHub Issues** dengan template berikut:

```markdown
**Deskripsi Bug:**
[Jelaskan apa yang tidak berjalan]

**Reproduksi:**
1. Langkah pertama
2. Langkah kedua
3. ...

**Expected Behavior:**
[Apa yang seharusnya terjadi]

**Actual Behavior:**
[Apa yang sebenarnya terjadi]

**Environment:**
- OS Version: [Windows 10 22H2 / Windows 11 24H2 / dll]
- Build Number: [misal 26100.1234]
- Tool Version: [v2.0-alpha-M3.4]
- Python Version (kalau dari source): [3.11.x]

**Screenshot/Log:**
[Kalau ada, attach disini]
```

### 2. False Positive Reports
Kalau tool mendeteksi sesuatu yang **sebenarnya legitimate**:

```markdown
**Modul yang Fire:**
[Modul 1 / VA-03 / HMD-07 / dll]

**Finding Title:**
[Judul finding dari HTML report]

**Detail Finding:**
[Copy detail lengkap]

**Kenapa Ini False Positive:**
[Jelaskan konteks yang bikin ini bukan masalah real]

**Vendor/Software Info (kalau relevan):**
- Vendor: [misal "Intel Corporation"]
- Software: [misal "Intel Graphics Driver v31.0.101.5074"]
- Legitimate Source: [misal "OEM pre-install" / "Official download URL"]
```

### 3. Feature Requests
Untuk modul baru atau fitur tambahan:

- Jelaskan **use case** dari sudut pandang SOC/CSIRT
- Referensi ke **MITRE ATT&CK** technique kalau ada
- Contoh artefak atau data yang dianalisis
- Kontribusi PoC code kalau memungkinkan

### 4. Pull Requests
Welcome untuk:
- Bug fixes
- Vendor whitelist additions (reduce false positive)
- Dokumentasi
- New modules (koordinasi dulu via Issue)

---

## 🔧 Development Setup

### Prerequisites
- Python 3.11+
- Git
- Windows 10/11 (untuk testing native)
- Virtual environment (recommended)

### Setup Langkah-Langkah

```bash
# 1. Fork repository ini di GitHub, kemudian clone fork Anda
git clone https://github.com/<username>/satsiberau-endpoint-audit.git
cd satsiberau-endpoint-audit

# 2. Buat virtual environment
python -m venv venv
venv\Scripts\activate   # Windows
# atau: source venv/bin/activate   # Linux/Mac

# 3. Install dependencies
pip install -r requirements.txt
pip install pyinstaller  # untuk build .exe

# 4. Buat branch untuk fitur/fix Anda
git checkout -b feat/nama-fitur
# atau: git checkout -b fix/nama-bug
```

---

## 📝 Coding Standards

### Python Style
- Ikuti **PEP 8** sebisa mungkin
- Line length max **120 karakter**
- Indentasi **4 spaces** (bukan tab)
- Nama variabel: `snake_case`
- Nama konstanta: `UPPER_SNAKE_CASE`
- Nama kelas: `PascalCase`

### Docstrings
Setiap fungsi modul utama wajib punya docstring:

```python
def check_wmi_persistence(findings, context):
    """
    Deteksi WMI Event Subscription persistence (MITRE T1546.003).

    Scan triplet __EventFilter + __EventConsumer + __FilterToConsumerBinding
    di namespace root\\subscription. Finding di-rate CRITICAL kalau ada
    binding ke suspicious consumer (ActiveScript, CommandLine).

    Args:
        findings: List[Dict] - target list untuk append finding
        context: Dict - context dict dengan key 'os_version', 'build_num', dll

    Returns:
        None (append ke findings)
    """
    ...
```

### Komentar Bahasa
- **Bahasa Indonesia** untuk komentar user-facing dan explain-what
- **Bahasa Inggris** untuk variable names, function names, technical terms
- Komentar harus explain **KENAPA**, bukan **APA** (code sudah explain apa)

### Finding Format
Setiap finding baru harus mengikuti format:

```python
add_finding(findings,
    severity="HIGH",                    # CRITICAL / HIGH / MEDIUM / LOW / INFO
    title="Judul singkat finding",      # ≤ 80 karakter
    detail="Detail lengkap...",         # Bisa multi-line, deskriptif
    raw=json.dumps(entry, ensure_ascii=False)  # Raw data untuk audit trail
)
```

---

## 🧪 Testing

### Manual Testing
Sebelum submit PR, test di minimal 2 environment:

1. **Clean Install Windows 11** (baseline)
2. **Dirty Workstation** (banyak software terpasang)

Pastikan:
- Tidak ada Python exception
- Report HTML ter-generate dengan baik
- Filter & search berfungsi
- JSON export valid

### Regression Testing
Kalau Anda mengubah modul existing, pastikan:

- Finding yang sebelumnya terdeteksi masih muncul (positive test)
- Known false positive yang sudah di-whitelist tidak kembali muncul (negative test)
- Performance tidak degradation signifikan

### Test Data
Untuk testing malware detection, gunakan:

- **VM Isolated** (VirtualBox/VMware)
- **Snapshot** sebelum test
- **Benign PoC** (JohnHammond/msdt-follina untuk Follina, dll)

**JANGAN** test di endpoint produksi dengan live malware!

---

## 📦 Commit Convention

Format commit message:

```
<type>: <subject> (≤ 72 char)

<body optional, ≤ 100 char per line>

<footer optional>
```

### Types:

| Type | Kegunaan |
|------|----------|
| `feat` | Fitur baru (modul baru, capability baru) |
| `fix` | Bug fix |
| `fp-reduce` | False positive reduction (whitelist addition) |
| `perf` | Performance improvement |
| `refactor` | Refactor tanpa ubah behavior |
| `docs` | Perubahan dokumentasi saja |
| `test` | Add/modify test |
| `build` | Perubahan build config |
| `chore` | Maintenance (dependency update, dll) |

### Contoh:

```
feat: tambah modul VA-04 Firewall Configuration Check

Modul baru untuk audit Windows Firewall:
- Cek profile Domain/Private/Public status
- Cek default inbound/outbound action
- Cek suspicious inbound rules
- MITRE ATT&CK: T1562.004

Reference: CIS Benchmark Windows 11 section 9
```

```
fp-reduce: whitelist vendor Autodesk untuk HMD-04

Autodesk pakai catalog-signed driver yang tidak
terdeteksi sebagai signed oleh driverquery.

Fix: Fixes #42
```

---

## 🚀 Pull Request Process

1. **Fork & branch** dari `main`
2. **Commit** sesuai convention di atas
3. **Test** di minimal 1 environment Windows
4. **Update CHANGELOG.md** section `[Unreleased]`
5. **Update dokumentasi** kalau ada perubahan user-facing
6. **Submit PR** dengan deskripsi:
   - What: apa yang berubah
   - Why: kenapa diperlukan
   - How: pendekatan teknis
   - Testing: environment yang di-test
   - Screenshots: before/after kalau ada UI change

### PR Review Timeline

- **Initial response:** ≤ 7 hari
- **Full review:** 14-30 hari (tergantung kompleksitas)
- **Merge:** setelah approval + testing lulus

---

## 🤝 Code of Conduct

- **Respect** — hormati kontribusi orang lain
- **Constructive** — kritik yang membangun
- **Professional** — ini tool untuk institusi militer, jaga profesionalisme
- **Zero tolerance** — harassment, offensive content, atau bad faith contribution akan di-reject

---

## ❓ Pertanyaan?

- **Technical questions:** buka Discussion di GitHub
- **Internal Satsiberau:** koordinasi via jalur dinas
- **Security issues:** lihat [SECURITY.md](./SECURITY.md)

---

**Kontribusi Anda membantu memperkuat ketahanan siber Indonesia. Terima kasih!**

*Satuan Siber TNI Angkatan Udara*
