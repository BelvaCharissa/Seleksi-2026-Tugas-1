-- SCHEMA: Bookstore Database (Seleksi 2026 - Tugas 1)
-- DBMS  : PostgreSQL
-- Berisi seluruh tabel hasil turunan ERD, termasuk tabel yang
-- datanya berasal dari scraping (Books, Author, Publishers,
-- Format, Catalog, Book_Catalog) DAN tabel tambahan yang relevan
-- untuk melengkapi model transaksional (Account, Address, Order,
-- Order_details, Cart, Cart_Item, Pengiriman, Pembayaran).
-- Tabel tambahan sengaja dibiarkan KOSONG .

BEGIN;

CREATE TABLE Author (
    author_id     SERIAL PRIMARY KEY,
    author_name   VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE Publishers (
    publisher_id    SERIAL PRIMARY KEY,
    publisher_name  VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE Format (
    format_id     SERIAL PRIMARY KEY,
    format_name   VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Catalog (
    catalog_id     SERIAL PRIMARY KEY,
    catalog_name   VARCHAR(255) NOT NULL UNIQUE
);

-- book_id TIDAK pakai SERIAL karena id-nya sudah ditentukan oleh
-- scraper (item_id yang dihasilkan waktu proses scraping),
-- supaya id di database konsisten dengan id di file JSON.
CREATE TABLE Books (
    book_id        INTEGER PRIMARY KEY,
    publisher_id   INTEGER NOT NULL REFERENCES Publishers(publisher_id),
    format_id      INTEGER NOT NULL REFERENCES Format(format_id),
    author_id      INTEGER NOT NULL REFERENCES Author(author_id),
    title          VARCHAR(500) NOT NULL,
    isbn           VARCHAR(20),
    num_pages      INTEGER CHECK (num_pages IS NULL OR num_pages > 0),
    -- disimpan sebagai teks karena hasil scraping tanggal terbit
    -- formatnya tidak selalu konsisten (mis. "16 Feb 2022" atau "Unknown")
    publish_date   VARCHAR(50),
    url            TEXT,
    price          NUMERIC(12, 2) CHECK (price >= 0),
    is_discount    BOOLEAN NOT NULL DEFAULT FALSE
);

-- Tabel penghubung many-to-many Books <-> Catalog
CREATE TABLE Book_Catalog (
    book_id      INTEGER REFERENCES Books(book_id) ON DELETE CASCADE,
    catalog_id   INTEGER REFERENCES Catalog(catalog_id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, catalog_id)
);


-- TABEL TAMBAHAN (model transaksional, dibiarkan kosong)

CREATE TABLE Account (
    account_email   VARCHAR(255) PRIMARY KEY,
    nama_penerima   VARCHAR(255) NOT NULL,
    no_telp         VARCHAR(20)
);

CREATE TABLE Address (
    address_id       SERIAL PRIMARY KEY,
    account_email    VARCHAR(255) NOT NULL REFERENCES Account(account_email) ON DELETE CASCADE,
    label_alamat     VARCHAR(100),
    provinsi         VARCHAR(100),
    kota             VARCHAR(100),
    kecamatan        VARCHAR(100),
    kode_pos         VARCHAR(10),
    alamat_lengkap   TEXT
);

CREATE TABLE Pengiriman (
    pengiriman_id   SERIAL PRIMARY KEY,
    nama_jasa       VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Pembayaran (
    pembayaran_id      SERIAL PRIMARY KEY,
    metode_pembayaran  VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Cart (
    cart_id         SERIAL PRIMARY KEY,
    account_email   VARCHAR(255) NOT NULL REFERENCES Account(account_email) ON DELETE CASCADE
);

CREATE TABLE Cart_Item (
    cart_item_id   SERIAL PRIMARY KEY,
    cart_id        INTEGER NOT NULL REFERENCES Cart(cart_id) ON DELETE CASCADE,
    book_id        INTEGER NOT NULL REFERENCES Books(book_id),
    quantity       INTEGER NOT NULL CHECK (quantity > 0),
    UNIQUE (cart_id, book_id)   -- satu buku cuma 1 baris per cart; nambah qty tinggal update
);

CREATE TABLE "Order" (
    order_id        SERIAL PRIMARY KEY,
    account_email   VARCHAR(255) NOT NULL REFERENCES Account(account_email),
    address_id      INTEGER NOT NULL REFERENCES Address(address_id),
    pengiriman_id   INTEGER NOT NULL REFERENCES Pengiriman(pengiriman_id),
    pembayaran_id   INTEGER NOT NULL REFERENCES Pembayaran(pembayaran_id),
    order_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    ongkos_kirim    NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (ongkos_kirim >= 0),
    total_harga     NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (total_harga >= 0),
    status_order    VARCHAR(20) NOT NULL DEFAULT 'pending'
                     CHECK (status_order IN ('pending', 'paid', 'shipped', 'completed', 'cancelled'))
);

CREATE TABLE Order_details (
    order_detail_id     SERIAL PRIMARY KEY,
    order_id            INTEGER NOT NULL REFERENCES "Order"(order_id) ON DELETE CASCADE,
    book_id             INTEGER NOT NULL REFERENCES Books(book_id),
    quantity            INTEGER NOT NULL CHECK (quantity > 0),
    -- snapshot harga saat transaksi, sengaja terpisah dari Books.price
    -- supaya riwayat transaksi tidak berubah meski harga buku berubah kemudian
    harga_saat_dibeli   NUMERIC(12, 2) NOT NULL CHECK (harga_saat_dibeli >= 0)
);

CREATE INDEX idx_books_author     ON Books(author_id);
CREATE INDEX idx_books_publisher  ON Books(publisher_id);
CREATE INDEX idx_orderdetails_order ON Order_details(order_id);
CREATE INDEX idx_orderdetails_book  ON Order_details(book_id);
CREATE INDEX idx_cartitem_cart      ON Cart_Item(cart_id);

-- ------------------------------------------------------------
-- TRIGGER: auto-update total_harga di Order
-- Setiap kali Order_details ditambah/diubah/dihapus, total_harga
-- di tabel Order otomatis dihitung ulang (SUM harga_saat_dibeli*qty
-- + ongkos_kirim), supaya tidak perlu dihitung manual di aplikasi.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_update_order_total()
RETURNS TRIGGER AS $$
DECLARE
    affected_order_id INTEGER;
BEGIN
    IF TG_OP = 'DELETE' THEN
        affected_order_id := OLD.order_id;
    ELSE
        affected_order_id := NEW.order_id;
    END IF;

    UPDATE "Order"
    SET total_harga = (
        SELECT COALESCE(SUM(quantity * harga_saat_dibeli), 0)
        FROM Order_details
        WHERE order_id = affected_order_id
    ) + ongkos_kirim
    WHERE order_id = affected_order_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_order_total
AFTER INSERT OR UPDATE OR DELETE ON Order_details
FOR EACH ROW
EXECUTE FUNCTION fn_update_order_total();

COMMIT;

