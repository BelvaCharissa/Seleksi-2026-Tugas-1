"""
run_etl.py
==========
Orkestrator utama untuk seluruh pipeline ETL:
    1. Scraping data terbaru dari Gramedia  (scraper.py)
    2. Load hasil scraping ke database OLTP 'bookstore'  (load_data.py)
    3. Load dari OLTP ke data warehouse 'bookstore_dw'  (dw_load_data.py)

Ini SATU entry point tunggal yang dipanggil oleh scheduler (Windows Task
Scheduler / run_wrapper.bat), setara dengan pola run_etl.py + run_wrapper.sh
di lingkungan Linux/cron.

Kenapa dipisah jadi run_etl.py (orkestrator) vs run_wrapper.bat (pemicu):
- run_etl.py berisi LOGIKA (urutan step, error handling, logging) --
  bisa dites manual kapan saja dengan "python run_etl.py".
- run_wrapper.bat cuma bertugas MEMICU run_etl.py dari Task Scheduler,
  tanpa logika apa pun di dalamnya -- gampang di-maintain terpisah.

Setiap step dijalankan sebagai subprocess terpisah supaya kalau salah satu
gagal (misal scraping timeout), step lain TETAP bisa lanjut dicoba secara
independen pada run berikutnya, dan errornya jelas ketauan step mana yang
bermasalah.
"""

import subprocess
import sys
import logging
from datetime import datetime
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("run_etl")

# Sesuaikan path ini kalau struktur folder project kamu beda
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
STEPS = [
    ("Scraping data dari Gramedia", PROJECT_ROOT / "Data Scraping" / "src" / "scraper.py"),
    ("Load data ke OLTP (bookstore)", PROJECT_ROOT / "Data Storing" / "src" / "load_data.py"),
    ("Load data ke Data Warehouse (bookstore_dw)", PROJECT_ROOT / "Data Warehouse" / "src" / "dw_load_data.py"),
]


def run_step(step_name: str, script_path: Path) -> bool:
    """Jalankan satu script Python sebagai subprocess. Return True kalau sukses."""
    if not script_path.exists():
        log.error(f"[{step_name}] File tidak ditemukan: {script_path}")
        return False

    log.info(f"--- Mulai: {step_name} ---")
    result = subprocess.run(
        [sys.executable, str(script_path)],
        cwd=script_path.parent,  # jalankan dari folder script itu sendiri, biar path relatif di dalamnya benar
        capture_output=True,
        text=True,
    )

    # Teruskan output asli dari script ke log supaya tetap kelihatan detailnya
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr)

    if result.returncode != 0:
        log.error(f"--- GAGAL: {step_name} (exit code {result.returncode}) ---")
        return False

    log.info(f"--- Selesai: {step_name} ---")
    return True


def main():
    run_started_at = datetime.now()
    log.info(f"========== ETL PIPELINE DIMULAI: {run_started_at.isoformat()} ==========")

    all_success = True
    for step_name, script_path in STEPS:
        success = run_step(step_name, script_path)
        if not success:
            all_success = False
            log.warning(f"Step '{step_name}' gagal, tapi tetap lanjut ke step berikutnya.")

    run_finished_at = datetime.now()
    duration = (run_finished_at - run_started_at).total_seconds()

    status = "SEMUA STEP BERHASIL" if all_success else "ADA STEP YANG GAGAL, cek log di atas"
    log.info(f"========== ETL PIPELINE SELESAI: {run_finished_at.isoformat()} "
              f"(durasi {duration:.1f} detik) -- {status} ==========")

    sys.exit(0 if all_success else 1)


if __name__ == "__main__":
    main()