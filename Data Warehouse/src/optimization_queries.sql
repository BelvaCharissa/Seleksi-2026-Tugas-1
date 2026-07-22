-- ============================================================
-- Task 3: Query Optimasi
-- Cara pakai: jalankan tiap bagian SATU-SATU secara berurutan di psql,
-- lalu SCREENSHOT hasil EXPLAIN ANALYZE sebelum dan sesudah index dibuat.
-- Yang perlu diperhatikan di outputnya: perubahan dari "Seq Scan" jadi
-- "Index Scan"/"Bitmap Heap Scan", dan penurunan angka "Execution Time".
-- ============================================================


-- ============================================================
-- OPTIMASI 1: Pencarian judul buku (fitur search)
-- Kasus nyata: user ketik keyword di search box, sistem cari
-- semua judul yang mengandung kata itu.
-- ============================================================

-- SEBELUM: tidak ada index yang bisa dipakai untuk ILIKE '%keyword%'
-- (index B-tree biasa tidak berguna untuk wildcard di awal string)
EXPLAIN ANALYZE
SELECT book_id, title, price
FROM Books
WHERE title ILIKE '%dunia%';
-- Perhatikan di output: "Seq Scan on books" -- artinya database harus
-- membaca SEMUA baris satu-satu untuk mencocokkan pola teks.

-- FIX: aktifkan ekstensi pg_trgm, lalu buat GIN index khusus buat
-- pencarian teks dengan wildcard di posisi manapun.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_books_title_trgm ON Books USING GIN (title gin_trgm_ops);

-- SESUDAH: jalankan query yang SAMA PERSIS lagi
EXPLAIN ANALYZE
SELECT book_id, title, price
FROM Books
WHERE title ILIKE '%dunia%';
-- Perhatikan sekarang: "Bitmap Index Scan on idx_books_title_trgm" --
-- database langsung menuju baris yang relevan lewat index, bukan
-- membaca semua baris. Execution Time seharusnya jauh lebih kecil,
-- meskipun perbedaannya baru sangat terasa saat jumlah baris di Books
-- sudah ribuan (di data 22-31 baris hasil scraping kamu, bedanya
-- mungkin belum besar -- tapi PLAN QUERY-nya sudah pasti berubah,
-- itu yang jadi bukti optimasinya).


-- ============================================================
-- OPTIMASI 2: Cari semua buku dalam satu catalog tertentu
-- Kasus nyata: halaman "Novel Fiksi Terfavorit" perlu nampilin semua
-- buku yang tergabung di catalog itu.
-- ============================================================

-- SEBELUM: Book_Catalog PK-nya composite (book_id, catalog_id).
-- Karena catalog_id itu KOLOM KEDUA di composite index, Postgres TIDAK
-- bisa memakainya secara efisien kalau kita filter cuma dari catalog_id
-- saja (bukan dari book_id dulu).
EXPLAIN ANALYZE
SELECT b.book_id, b.title, b.price
FROM Book_Catalog bc
JOIN Books b ON bc.book_id = b.book_id
WHERE bc.catalog_id = 1;
-- Perhatikan: "Seq Scan on book_catalog" -- composite PK-nya gak kepakai
-- buat pencarian yang mulai dari catalog_id.

-- FIX: index terpisah khusus untuk catalog_id
CREATE INDEX idx_bookcatalog_catalog ON Book_Catalog(catalog_id);

-- SESUDAH:
EXPLAIN ANALYZE
SELECT b.book_id, b.title, b.price
FROM Book_Catalog bc
JOIN Books b ON bc.book_id = b.book_id
WHERE bc.catalog_id = 1;
-- Perhatikan: sekarang muncul "Bitmap Index Scan on idx_bookcatalog_catalog"
-- atau "Index Scan" -- lookup langsung ke baris yang catalog_id = 1.


-- ============================================================
-- OPTIMASI 3: Halaman promo -- tampilkan buku diskon, urut dari termurah
-- Kasus nyata: halaman "Lagi Diskon!" di homepage toko buku.
-- ============================================================

-- SEBELUM: tidak ada index di is_discount maupun price
EXPLAIN ANALYZE
SELECT book_id, title, price
FROM Books
WHERE is_discount = TRUE
ORDER BY price ASC;
-- Perhatikan: "Seq Scan on books" + "Sort" terpisah -- database baca
-- semua baris, filter manual, baru diurutkan.

-- FIX: partial index -- cuma nge-index baris yang is_discount = TRUE
-- (lebih hemat storage dibanding index biasa, karena kita tau query
-- ini SELALU filter is_discount = TRUE), sekalian diurutkan by price
-- supaya ORDER BY juga langsung kepakai dari index (gak perlu sort manual).
CREATE INDEX idx_books_discount_price ON Books(price) WHERE is_discount = TRUE;

-- SESUDAH:
EXPLAIN ANALYZE
SELECT book_id, title, price
FROM Books
WHERE is_discount = TRUE
ORDER BY price ASC;
-- Perhatikan: "Index Scan using idx_books_discount_price" -- database
-- langsung ambil baris yang is_discount=TRUE DAN sudah urut by price,
-- gak perlu langkah "Sort" terpisah lagi.


-- ============================================================
-- Verifikasi tambahan: pastikan hasil datanya SAMA PERSIS sebelum & sesudah
-- (index cuma mengubah CARA database mencari, bukan HASIL query)
-- ============================================================
SELECT COUNT(*) FROM Books WHERE title ILIKE '%dunia%';
SELECT COUNT(*) FROM Book_Catalog WHERE catalog_id = 1;
SELECT COUNT(*) FROM Books WHERE is_discount = TRUE;