-- ============================================================
-- DATA WAREHOUSE SCHEMA: Bookstore Analytics
-- DBMS  : PostgreSQL (database TERPISAH dari OLTP, nama: bookstore_dw)
--
-- Pola: STAR SCHEMA, kecuali Dim_Catalog yang nempel lewat bridge table
-- ke Dim_Books (satu-satunya cabang SNOWFLAKE, karena relasi Books<->Catalog
-- bersifat many-to-many, jadi tidak bisa didenormalisasi langsung ke fact).
--
-- Fact table: Fact_Order_Details (grain = satu baris per buku yang dibeli
-- dalam satu order). Semua dimensi lain (Publisher, Format, Author)
-- didenormalisasi langsung ke Dim_Books untuk mempercepat query laporan
-- (menghindari JOIN berlapis yang biasa terjadi di skema OLTP ternormalisasi).
-- ============================================================

-- Jalankan dulu sebagai superuser: CREATE DATABASE bookstore_dw;
-- Baru jalankan file ini setelah connect ke database bookstore_dw.

BEGIN;

CREATE TABLE Dim_Account (
    account_email    VARCHAR(255) PRIMARY KEY,
    nama_penerima    VARCHAR(255),
    no_telp          VARCHAR(20)
);

CREATE TABLE Dim_Address (
    address_id       INTEGER PRIMARY KEY,
    label_alamat     VARCHAR(100),
    provinsi         VARCHAR(100),
    kota             VARCHAR(100),
    kecamatan        VARCHAR(100),
    alamat_lengkap   TEXT
);

CREATE TABLE Dim_Payment (
    pembayaran_id      INTEGER PRIMARY KEY,
    metode_pembayaran  VARCHAR(100)
);

CREATE TABLE Dim_Shipping (
    pengiriman_id   INTEGER PRIMARY KEY,
    nama_jasa       VARCHAR(100)
);

-- Denormalized: publisher_name, format_name, author_name langsung jadi
-- kolom di sini (bukan tabel dimensi terpisah), karena relasinya 1:N dari
-- sisi Books -- menghindari JOIN tambahan saat query laporan.
CREATE TABLE Dim_Books (
    book_id          INTEGER PRIMARY KEY,
    title            VARCHAR(500) NOT NULL,
    isbn             VARCHAR(20),
    num_pages        INTEGER,
    publish_date     VARCHAR(50),
    is_discount      BOOLEAN,
    price            NUMERIC(12, 2),
    author_name      VARCHAR(255),
    publisher_name   VARCHAR(255),
    format_name      VARCHAR(100)
);

CREATE TABLE Dim_Catalog (
    catalog_id     INTEGER PRIMARY KEY,
    catalog_name   VARCHAR(255)
);

-- Bridge table -- satu-satunya bagian snowflake, karena Books<->Catalog M:N
CREATE TABLE Bridge_Book_Catalog (
    book_id      INTEGER REFERENCES Dim_Books(book_id) ON DELETE CASCADE,
    catalog_id   INTEGER REFERENCES Dim_Catalog(catalog_id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, catalog_id)
);

-- Fact table: grain = 1 baris per buku per order
CREATE TABLE Fact_Order_Details (
    order_detail_id    INTEGER PRIMARY KEY,
    account_email      VARCHAR(255) REFERENCES Dim_Account(account_email),
    address_id         INTEGER REFERENCES Dim_Address(address_id),
    pembayaran_id      INTEGER REFERENCES Dim_Payment(pembayaran_id),
    pengiriman_id      INTEGER REFERENCES Dim_Shipping(pengiriman_id),
    book_id            INTEGER REFERENCES Dim_Books(book_id),
    order_id           INTEGER,          -- degenerate dimension
    order_date         DATE,
    quantity           INTEGER,
    harga_saat_dibeli  NUMERIC(12, 2),
    subtotal           NUMERIC(12, 2)    -- quantity * harga_saat_dibeli
);

-- Index di semua FK fact table -- Postgres tidak otomatis index kolom FK
CREATE INDEX idx_fact_account   ON Fact_Order_Details(account_email);
CREATE INDEX idx_fact_address   ON Fact_Order_Details(address_id);
CREATE INDEX idx_fact_payment   ON Fact_Order_Details(pembayaran_id);
CREATE INDEX idx_fact_shipping  ON Fact_Order_Details(pengiriman_id);
CREATE INDEX idx_fact_book      ON Fact_Order_Details(book_id);
CREATE INDEX idx_fact_orderdate ON Fact_Order_Details(order_date);
CREATE INDEX idx_bridge_catalog ON Bridge_Book_Catalog(catalog_id);

-- Tabel log ETL -- dipakai untuk bukti automated scheduling (bonus #2):
-- mencatat kapan tiap batch ETL dijalankan dan berapa baris yang diproses.
CREATE TABLE Etl_Log (
    etl_log_id     SERIAL PRIMARY KEY,
    run_started_at TIMESTAMP NOT NULL DEFAULT now(),
    run_finished_at TIMESTAMP,
    rows_books     INTEGER,
    rows_catalog   INTEGER,
    rows_bridge    INTEGER,
    rows_fact      INTEGER,
    status         VARCHAR(20)
);

COMMIT;