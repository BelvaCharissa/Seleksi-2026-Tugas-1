"""
load_data.py
============
Script untuk memuat (load) data hasil scraping Gramedia (file-file JSON
di folder ../data) ke dalam database PostgreSQL sesuai schema.sql.

Urutan load PENTING karena ada foreign key:
    1. Author, Publishers, Format   (master data, tanpa dependency)
    2. Books                        (butuh author_id, publisher_id, format_id)
    3. Catalog                      (master data, tanpa dependency)
    4. Book_Catalog                 (butuh book_id & catalog_id)

Script ini idempotent: bisa dijalankan berkali-kali tanpa membuat data
duplikat, karena semua INSERT pakai "ON CONFLICT ... DO NOTHING".

Cara pakai:
    1. Pastikan schema.sql sudah dijalankan lebih dulu ke database.
    2. Set environment variable koneksi database (lihat DB_CONFIG di
       bawah), atau edit langsung nilainya.
    3. Jalankan:  python load_data.py
"""

import os
import json
import logging
from pathlib import Path

import psycopg2
from psycopg2.extras import execute_values

# ------------------------------------------------------------------
# Konfigurasi
# ------------------------------------------------------------------

DATA_DIR = Path(__file__).resolve().parent.parent.parent / "Data Scraping" / "data"

DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": os.environ.get("DB_PORT", "5432"),
    "dbname": os.environ.get("DB_NAME", "bookstore"),
    "user": os.environ.get("DB_USER", "postgres"),
    "password": os.environ.get("DB_PASSWORD", "postgres"),
}

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("load_data")


# ------------------------------------------------------------------
# Helper
# ------------------------------------------------------------------

def load_json(filename: str) -> list[dict]:
    """Baca satu file JSON dari folder data, return list kosong kalau
    file tidak ditemukan (supaya script tidak crash total)."""
    filepath = DATA_DIR / filename
    if not filepath.exists():
        log.warning(f"File tidak ditemukan, dilewati: {filepath}")
        return []
    with open(filepath, "r", encoding="utf-8") as f:
        return json.load(f)


def get_connection():
    log.info(f"Menghubungkan ke database '{DB_CONFIG['dbname']}' di {DB_CONFIG['host']}:{DB_CONFIG['port']}...")
    return psycopg2.connect(**DB_CONFIG)


# ------------------------------------------------------------------
# Load per tabel
# ------------------------------------------------------------------

def load_authors(cur) -> None:
    authors = load_json("authors.json")
    rows = [(a["author_name"],) for a in authors if a.get("author_name")]
    if not rows:
        log.info("authors.json kosong, tidak ada yang di-load.")
        return
    execute_values(
        cur,
        "INSERT INTO Author (author_name) VALUES %s ON CONFLICT (author_name) DO NOTHING",
        rows,
    )
    log.info(f"Author: {len(rows)} baris diproses.")


def load_publishers(cur) -> None:
    publishers = load_json("publishers.json")
    rows = [(p["publisher_name"],) for p in publishers if p.get("publisher_name")]
    if not rows:
        log.info("publishers.json kosong, tidak ada yang di-load.")
        return
    execute_values(
        cur,
        "INSERT INTO Publishers (publisher_name) VALUES %s ON CONFLICT (publisher_name) DO NOTHING",
        rows,
    )
    log.info(f"Publishers: {len(rows)} baris diproses.")


def load_formats(cur) -> None:
    formats = load_json("formats.json")
    rows = [(f["format_type"],) for f in formats if f.get("format_type")]
    if not rows:
        log.info("formats.json kosong, tidak ada yang di-load.")
        return
    execute_values(
        cur,
        "INSERT INTO Format (format_name) VALUES %s ON CONFLICT (format_name) DO NOTHING",
        rows,
    )
    log.info(f"Format: {len(rows)} baris diproses.")


def load_catalogs(cur) -> None:
    catalogs = load_json("catalogs.json")
    rows = [(c["catalog_id"], c["catalog_name"]) for c in catalogs if c.get("catalog_name")]
    if not rows:
        log.info("catalogs.json kosong, tidak ada yang di-load.")
        return
    execute_values(
        cur,
        "INSERT INTO Catalog (catalog_id, catalog_name) VALUES %s ON CONFLICT (catalog_id) DO NOTHING",
        rows,
    )
    log.info(f"Catalog: {len(rows)} baris diproses.")
    # Samakan sequence catalog_id supaya insert berikutnya (kalau ada
    # yang tanpa id eksplisit) tidak bentrok dengan id yang sudah dipakai.
    cur.execute(
        "SELECT setval(pg_get_serial_sequence('catalog', 'catalog_id'), "
        "COALESCE((SELECT MAX(catalog_id) FROM Catalog), 1))"
    )


def build_lookup(cur, table: str, id_col: str, name_col: str) -> dict[str, int]:
    """Ambil mapping {nama: id} dari sebuah tabel master data,
    dipakai untuk resolve FK saat insert Books."""
    cur.execute(f"SELECT {id_col}, {name_col} FROM {table}")
    return {name: id_ for id_, name in cur.fetchall()}


def load_books(cur) -> None:
    books = load_json("books.json")
    analytics = load_json("analytics.json")
    if not books:
        log.info("books.json kosong, tidak ada yang di-load.")
        return

    # analytics.json menyimpan author_name/publisher_name/format_type/price
    # per book_id (karena books.json sendiri tidak menyimpan FK ke master
    # data lain, cuma atribut buku itu sendiri).
    analytics_by_book = {a["book_id"]: a for a in analytics}

    author_lookup = build_lookup(cur, "Author", "author_id", "author_name")
    publisher_lookup = build_lookup(cur, "Publishers", "publisher_id", "publisher_name")
    format_lookup = build_lookup(cur, "Format", "format_id", "format_name")

    rows = []
    skipped = 0
    for b in books:
        book_id = b["book_id"]
        meta = analytics_by_book.get(book_id)
        if meta is None:
            # publisher_id/format_id/author_id di schema sekarang NOT NULL,
            # jadi buku tanpa metadata lengkap tidak bisa diinsert -> skip.
            log.warning(f"book_id {book_id} tidak ada di analytics.json, buku ini DILEWATI (FK wajib NOT NULL).")
            skipped += 1
            continue

        author_id = author_lookup.get(meta.get("author_name"))
        publisher_id = publisher_lookup.get(meta.get("publisher_name"))
        format_id = format_lookup.get(meta.get("format_type"))
        price = meta.get("price_idr", 0)

        if author_id is None or publisher_id is None or format_id is None:
            log.warning(f"book_id {book_id} punya author/publisher/format yang tidak ditemukan di master data, DILEWATI.")
            skipped += 1
            continue

        # Sanitasi num_pages: constraint DB mewajibkan > 0 atau NULL.
        # Beberapa produk (misal paket bundling) ke-scrape num_pages=0
        # karena bukan buku tunggal -- anggap saja data tidak tersedia.
        raw_num_pages = b.get("num_pages")
        num_pages = raw_num_pages if (raw_num_pages is not None and raw_num_pages > 0) else None

        rows.append((
            book_id,
            publisher_id,
            format_id,
            author_id,
            b.get("title"),
            b.get("isbn"),
            num_pages,
            b.get("publish_date"),
            b.get("url"),
            price,
            bool(b.get("is_discount", False)),
        ))

    execute_values(
        cur,
        """
        INSERT INTO Books
            (book_id, publisher_id, format_id, author_id, title, isbn,
             num_pages, publish_date, url, price, is_discount)
        VALUES %s
        ON CONFLICT (book_id) DO NOTHING
        """,
        rows,
    )
    log.info(f"Books: {len(rows)} baris diproses ({skipped} dilewati karena tanpa metadata).")


def load_book_catalog(cur) -> None:
    relations = load_json("book_catalog.json")
    rows = [(r["book_id"], r["catalog_id"]) for r in relations]
    if not rows:
        log.info("book_catalog.json kosong, tidak ada yang di-load.")
        return
    execute_values(
        cur,
        "INSERT INTO Book_Catalog (book_id, catalog_id) VALUES %s ON CONFLICT DO NOTHING",
        rows,
    )
    log.info(f"Book_Catalog: {len(rows)} baris diproses.")


# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

def main() -> None:
    conn = get_connection()
    try:
        with conn:
            with conn.cursor() as cur:
                # Urutan wajib: master data dulu, baru yang punya FK ke situ.
                load_authors(cur)
                load_publishers(cur)
                load_formats(cur)
                load_catalogs(cur)
                load_books(cur)          # butuh Author/Publishers/Format
                load_book_catalog(cur)   # butuh Books & Catalog
        log.info("Selesai. Semua data berhasil dimuat ke database.")
    except Exception:
        log.exception("Terjadi error saat load data, transaksi di-rollback.")
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()