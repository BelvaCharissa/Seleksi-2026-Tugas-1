"""
dw_load_data.py
================
ETL (Extract-Transform-Load) script: memindahkan data dari database OLTP
'bookstore' ke data warehouse 'bookstore_dw'.

Desain penting:
- IDEMPOTENT: semua INSERT pakai "ON CONFLICT ... DO UPDATE" (upsert), jadi
  script ini AMAN dijalankan berkali-kali / terjadwal berkala tanpa membuat
  data duplikat (syarat bonus #2: "pastikan tidak ada redundansi data").
- Setiap run dicatat ke tabel Etl_Log di warehouse (waktu mulai, waktu
  selesai, jumlah baris per tabel) -- ini bukti nyata untuk bonus #2
  (menunjukkan timestamp ekstraksi batch pertama vs batch berikutnya).
- Fact_Order_Details akan tetap 0 baris selama tabel Order/Order_details di
  OLTP masih kosong (sesuai instruksi tugas utama, tabel itu sengaja tidak
  diisi). Begitu ada data transaksi asli, tinggal jalankan ulang script ini.

Cara pakai:
    1. Buat database warehouse dulu: createdb -U postgres bookstore_dw
    2. Jalankan dw_schema.sql ke database itu.
    3. python dw_load_data.py
"""

import os
import logging
from datetime import datetime

import psycopg2
from psycopg2.extras import execute_values

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("dw_load_data")

SOURCE_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": os.environ.get("DB_PORT", "5432"),
    "dbname": os.environ.get("SOURCE_DB_NAME", "bookstore"),
    "user": os.environ.get("DB_USER", "postgres"),
    "password": os.environ.get("DB_PASSWORD", "postgres"),
}

TARGET_CONFIG = {
    **SOURCE_CONFIG,
    "dbname": os.environ.get("DW_DB_NAME", "bookstore_dw"),
}


def get_conn(config):
    return psycopg2.connect(**config)


def extract_dim_books(src_cur):
    """JOIN Books+Author+Publisher+Format di sisi source, supaya hasilnya
    sudah dalam bentuk denormalized yang siap masuk ke Dim_Books."""
    src_cur.execute("""
        SELECT b.book_id, b.title, b.isbn, b.num_pages, b.publish_date,
               b.is_discount, b.price,
               a.author_name, p.publisher_name, f.format_name
        FROM Books b
        LEFT JOIN Author a ON b.author_id = a.author_id
        LEFT JOIN Publishers p ON b.publisher_id = p.publisher_id
        LEFT JOIN Format f ON b.format_id = f.format_id
    """)
    return src_cur.fetchall()


def load_dim_books(tgt_cur, rows):
    if not rows:
        log.info("Dim_Books: tidak ada data di source, dilewati.")
        return 0
    execute_values(
        tgt_cur,
        """
        INSERT INTO Dim_Books
            (book_id, title, isbn, num_pages, publish_date, is_discount,
             price, author_name, publisher_name, format_name)
        VALUES %s
        ON CONFLICT (book_id) DO UPDATE SET
            title = EXCLUDED.title,
            isbn = EXCLUDED.isbn,
            num_pages = EXCLUDED.num_pages,
            publish_date = EXCLUDED.publish_date,
            is_discount = EXCLUDED.is_discount,
            price = EXCLUDED.price,
            author_name = EXCLUDED.author_name,
            publisher_name = EXCLUDED.publisher_name,
            format_name = EXCLUDED.format_name
        """,
        rows,
    )
    log.info(f"Dim_Books: {len(rows)} baris di-upsert.")
    return len(rows)


def load_dim_catalog(src_cur, tgt_cur):
    src_cur.execute("SELECT catalog_id, catalog_name FROM Catalog")
    rows = src_cur.fetchall()
    if not rows:
        log.info("Dim_Catalog: tidak ada data di source, dilewati.")
        return 0
    execute_values(
        tgt_cur,
        """
        INSERT INTO Dim_Catalog (catalog_id, catalog_name) VALUES %s
        ON CONFLICT (catalog_id) DO UPDATE SET catalog_name = EXCLUDED.catalog_name
        """,
        rows,
    )
    log.info(f"Dim_Catalog: {len(rows)} baris di-upsert.")
    return len(rows)


def load_bridge_book_catalog(src_cur, tgt_cur):
    src_cur.execute("SELECT book_id, catalog_id FROM Book_Catalog")
    rows = src_cur.fetchall()
    if not rows:
        log.info("Bridge_Book_Catalog: tidak ada data di source, dilewati.")
        return 0
    execute_values(
        tgt_cur,
        "INSERT INTO Bridge_Book_Catalog (book_id, catalog_id) VALUES %s ON CONFLICT DO NOTHING",
        rows,
    )
    log.info(f"Bridge_Book_Catalog: {len(rows)} baris di-upsert.")
    return len(rows)


def load_dim_account(src_cur, tgt_cur):
    src_cur.execute("SELECT account_email, nama_penerima, no_telp FROM Account")
    rows = src_cur.fetchall()
    if not rows:
        log.info("Dim_Account: tidak ada data di source (tabel Account memang kosong), dilewati.")
        return 0
    execute_values(
        tgt_cur,
        """
        INSERT INTO Dim_Account (account_email, nama_penerima, no_telp) VALUES %s
        ON CONFLICT (account_email) DO UPDATE SET
            nama_penerima = EXCLUDED.nama_penerima, no_telp = EXCLUDED.no_telp
        """,
        rows,
    )
    log.info(f"Dim_Account: {len(rows)} baris di-upsert.")
    return len(rows)


def load_dim_address(src_cur, tgt_cur):
    src_cur.execute("""
        SELECT address_id, label_alamat, provinsi, kota, kecamatan, alamat_lengkap
        FROM Address
    """)
    rows = src_cur.fetchall()
    if not rows:
        log.info("Dim_Address: tidak ada data di source, dilewati.")
        return 0
    execute_values(
        tgt_cur,
        """
        INSERT INTO Dim_Address
            (address_id, label_alamat, provinsi, kota, kecamatan, alamat_lengkap)
        VALUES %s
        ON CONFLICT (address_id) DO UPDATE SET
            label_alamat = EXCLUDED.label_alamat, provinsi = EXCLUDED.provinsi,
            kota = EXCLUDED.kota, kecamatan = EXCLUDED.kecamatan,
            alamat_lengkap = EXCLUDED.alamat_lengkap
        """,
        rows,
    )
    log.info(f"Dim_Address: {len(rows)} baris di-upsert.")
    return len(rows)


def load_dim_payment(src_cur, tgt_cur):
    src_cur.execute("SELECT pembayaran_id, metode_pembayaran FROM Pembayaran")
    rows = src_cur.fetchall()
    if not rows:
        log.info("Dim_Payment: tidak ada data di source, dilewati.")
        return 0
    execute_values(
        tgt_cur,
        """
        INSERT INTO Dim_Payment (pembayaran_id, metode_pembayaran) VALUES %s
        ON CONFLICT (pembayaran_id) DO UPDATE SET metode_pembayaran = EXCLUDED.metode_pembayaran
        """,
        rows,
    )
    log.info(f"Dim_Payment: {len(rows)} baris di-upsert.")
    return len(rows)


def load_dim_shipping(src_cur, tgt_cur):
    src_cur.execute("SELECT pengiriman_id, nama_jasa FROM Pengiriman")
    rows = src_cur.fetchall()
    if not rows:
        log.info("Dim_Shipping: tidak ada data di source, dilewati.")
        return 0
    execute_values(
        tgt_cur,
        """
        INSERT INTO Dim_Shipping (pengiriman_id, nama_jasa) VALUES %s
        ON CONFLICT (pengiriman_id) DO UPDATE SET nama_jasa = EXCLUDED.nama_jasa
        """,
        rows,
    )
    log.info(f"Dim_Shipping: {len(rows)} baris di-upsert.")
    return len(rows)


def load_fact_order_details(src_cur, tgt_cur):
    """Fact table -- akan 0 baris selama Order/Order_details di source masih
    kosong (sesuai instruksi tugas utama). Query ini sudah siap dipakai
    begitu ada data transaksi asli."""
    src_cur.execute("""
        SELECT
            od.order_detail_id, o.account_email, o.address_id,
            o.pembayaran_id, o.pengiriman_id, od.book_id, o.order_id,
            o.order_date, od.quantity, od.harga_saat_dibeli,
            (od.quantity * od.harga_saat_dibeli) AS subtotal
        FROM Order_details od
        JOIN "Order" o ON od.order_id = o.order_id
    """)
    rows = src_cur.fetchall()
    if not rows:
        log.info("Fact_Order_Details: tidak ada data transaksi di source, dilewati.")
        return 0
    execute_values(
        tgt_cur,
        """
        INSERT INTO Fact_Order_Details
            (order_detail_id, account_email, address_id, pembayaran_id,
             pengiriman_id, book_id, order_id, order_date, quantity,
             harga_saat_dibeli, subtotal)
        VALUES %s
        ON CONFLICT (order_detail_id) DO UPDATE SET
            quantity = EXCLUDED.quantity,
            harga_saat_dibeli = EXCLUDED.harga_saat_dibeli,
            subtotal = EXCLUDED.subtotal
        """,
        rows,
    )
    log.info(f"Fact_Order_Details: {len(rows)} baris di-upsert.")
    return len(rows)


def main():
    run_started_at = datetime.now()
    log.info(f"=== Mulai ETL run pada {run_started_at.isoformat()} ===")

    src_conn = get_conn(SOURCE_CONFIG)
    tgt_conn = get_conn(TARGET_CONFIG)
    rows_books = rows_catalog = rows_bridge = rows_fact = 0
    status = "SUCCESS"

    try:
        with src_conn.cursor() as src_cur, tgt_conn.cursor() as tgt_cur:
            # Urutan penting: dimensi dulu, baru bridge & fact (karena FK)
            book_rows = extract_dim_books(src_cur)
            rows_books = load_dim_books(tgt_cur, book_rows)
            rows_catalog = load_dim_catalog(src_cur, tgt_cur)
            rows_bridge = load_bridge_book_catalog(src_cur, tgt_cur)

            load_dim_account(src_cur, tgt_cur)
            load_dim_address(src_cur, tgt_cur)
            load_dim_payment(src_cur, tgt_cur)
            load_dim_shipping(src_cur, tgt_cur)

            rows_fact = load_fact_order_details(src_cur, tgt_cur)

        tgt_conn.commit()
        log.info("Semua data berhasil di-load ke warehouse.")
    except Exception:
        tgt_conn.rollback()
        status = "FAILED"
        log.exception("ETL run gagal, perubahan di-rollback.")
        raise
    finally:
        run_finished_at = datetime.now()
        # Catat log run ini ke tabel Etl_Log -- bukti untuk automated scheduling
        with tgt_conn.cursor() as log_cur:
            log_cur.execute(
                """
                INSERT INTO Etl_Log
                    (run_started_at, run_finished_at, rows_books, rows_catalog,
                     rows_bridge, rows_fact, status)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (run_started_at, run_finished_at, rows_books, rows_catalog,
                 rows_bridge, rows_fact, status),
            )
        tgt_conn.commit()
        src_conn.close()
        tgt_conn.close()
        duration = (run_finished_at - run_started_at).total_seconds()
        log.info(f"=== ETL run selesai pada {run_finished_at.isoformat()} (durasi {duration:.2f} detik) ===")


if __name__ == "__main__":
    main()