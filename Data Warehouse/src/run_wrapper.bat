@echo off
REM ============================================================
REM run_wrapper.bat
REM Versi Windows dari run_wrapper.sh -- ini SATU-SATUNYA file yang
REM didaftarkan ke Task Scheduler. Tugasnya cuma memicu run_etl.py,
REM semua logika pipeline ada di sana (bukan di file ini).
REM ============================================================

cd /d "C:\Users\Belva\Seleksi-2026-Tugas-1\Data Warehouse\src"
python run_etl.py