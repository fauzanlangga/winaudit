@echo off
title Satsiberau - Build EXE v2.0-alpha-M3.4
color 0A
cls

echo.
echo   +====================================================+
echo   ^|   SATSIBERAU - BUILD TOOL  v2.0-alpha-M3.4           ^|
echo   ^|   Lettu Lek Ahmad Fauzan Langga, S.T.              ^|
echo   +====================================================+
echo.

:: ── CEK PYTHON ───────────────────────────────────────────
echo   [1/5] Mengecek Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo   [!] Python tidak ditemukan.
    echo   [!] Download : https://www.python.org/downloads/
    echo   [!] Centang  : "Add Python to PATH" saat install.
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo   [+] %%v ditemukan

:: ── INSTALL PYINSTALLER ──────────────────────────────────
echo.
echo   [2/5] Menginstall PyInstaller...
python -m pip install pyinstaller --quiet --disable-pip-version-check
if errorlevel 1 (
    echo   [!] Gagal install PyInstaller.
    pause
    exit /b 1
)
echo   [+] PyInstaller siap

:: ── INSTALL DEPENDENCIES ─────────────────────────────────
echo.
echo   [3/5] Menginstall dependencies...
python -m pip install psutil pywin32 wmi --quiet --disable-pip-version-check
if errorlevel 1 (
    echo   [!] Gagal install dependencies.
    pause
    exit /b 1
)
echo   [+] psutil, pywin32, wmi siap

:: ── BERSIHKAN BUILD LAMA ─────────────────────────────────
echo.
echo   [4/5] Membersihkan build sebelumnya...
if exist build   rmdir /s /q build  >nul 2>&1
if exist dist    rmdir /s /q dist   >nul 2>&1
if exist *.spec  del   /q   *.spec  >nul 2>&1
echo   [+] Folder build bersih

:: ── BUILD EXE ────────────────────────────────────────────
echo.
echo   [5/5] Building SatsiberauAudit.exe...
echo         (Proses ini memerlukan beberapa menit)
echo.

python -m PyInstaller ^
    --onefile ^
    --console ^
    --uac-admin ^
    --name "SatsiberauAudit" ^
    --hidden-import psutil ^
    --hidden-import wmi ^
    --hidden-import win32evtlog ^
    --hidden-import win32net ^
    --hidden-import win32security ^
    --hidden-import win32api ^
    --hidden-import pywintypes ^
    --hidden-import winreg ^
    --hidden-import sqlite3 ^
    --hidden-import ctypes ^
    --hidden-import shutil ^
    --hidden-import hashlib ^
    --hidden-import getpass ^
    audit.py

if errorlevel 1 (
    echo.
echo   +====================================================+
echo   ^|   [!] BUILD GAGAL                                  ^|
echo   ^|   Cek pesan error di atas untuk detail.            ^|
echo   +====================================================+
    echo.
    pause
    exit /b 1
)

:: ── BERSIHKAN FILE SEMENTARA ─────────────────────────────
if exist build   rmdir /s /q build  >nul 2>&1
if exist *.spec  del   /q   *.spec  >nul 2>&1

:: ── SELESAI ──────────────────────────────────────────────
echo.
echo   +====================================================+
echo   ^|   [+] BUILD SUKSES!                                ^|
echo   +----------------------------------------------------+
echo   ^|   File   : dist\SatsiberauAudit.exe                ^|
echo   ^|   Cara   : Klik kanan - Run as Administrator       ^|
echo   ^|   Report : audit_NAMAPC.html di folder yg sama     ^|
echo   +====================================================+
echo.
pause
