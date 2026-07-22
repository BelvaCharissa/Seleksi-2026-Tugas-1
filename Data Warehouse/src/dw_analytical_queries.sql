-- ============================================================
-- Contoh query analitik di atas data warehouse bookstore_dw.
-- Ini menunjukkan KEUNGGULAN star schema dibanding query yang sama
-- kalau dijalankan di skema OLTP ternormalisasi (butuh lebih sedikit JOIN
-- karena Author/Publisher/Format sudah didenormalisasi ke Dim_Books).
-- ============================================================

-- 1. Distribusi jumlah buku per penerbit (langsung dari Dim_Books,
--    TANPA JOIN sama sekali -- di skema OLTP ini butuh JOIN ke Publishers)
SELECT publisher_name, COUNT(*) AS jumlah_buku
FROM Dim_Books
GROUP BY publisher_name
ORDER BY jumlah_buku DESC;

-- 2. Persentase buku yang sedang diskon per format buku
SELECT
    format_name,
    COUNT(*) AS total_buku,
    SUM(CASE WHEN is_discount THEN 1 ELSE 0 END) AS jumlah_diskon,
    ROUND(100.0 * SUM(CASE WHEN is_discount THEN 1 ELSE 0 END) / COUNT(*), 1) AS persen_diskon
FROM Dim_Books
GROUP BY format_name
ORDER BY persen_diskon DESC;

-- 3. Rata-rata harga & jumlah halaman buku per catalog (butuh JOIN ke
--    bridge table karena Books<->Catalog many-to-many, satu-satunya
--    bagian snowflake di skema ini)
SELECT
    c.catalog_name,
    COUNT(DISTINCT b.book_id) AS jumlah_buku,
    ROUND(AVG(b.price), 0) AS rata_rata_harga,
    ROUND(AVG(b.num_pages), 0) AS rata_rata_halaman
FROM Dim_Catalog c
JOIN Bridge_Book_Catalog bc ON c.catalog_id = bc.catalog_id
JOIN Dim_Books b ON bc.book_id = b.book_id
GROUP BY c.catalog_name
ORDER BY jumlah_buku DESC;

-- 4. Top 5 penulis dengan buku terbanyak yang sedang diskon
SELECT author_name, COUNT(*) AS jumlah_buku_diskon
FROM Dim_Books
WHERE is_discount = TRUE
GROUP BY author_name
ORDER BY jumlah_buku_diskon DESC
LIMIT 5;

-- 5. (Contoh untuk saat Fact_Order_Details sudah terisi data transaksi asli)
--    Total pendapatan per bulan, per metode pembayaran -- ini query khas
--    data warehouse yang dioptimalkan buat laporan, sulit dilakukan
--    secepat ini di skema OLTP karena banyak JOIN antar tabel transaksi.
SELECT
    DATE_TRUNC('month', f.order_date) AS bulan,
    p.metode_pembayaran,
    SUM(f.subtotal) AS total_pendapatan,
    COUNT(DISTINCT f.order_id) AS jumlah_order
FROM Fact_Order_Details f
JOIN Dim_Payment p ON f.pembayaran_id = p.pembayaran_id
GROUP BY DATE_TRUNC('month', f.order_date), p.metode_pembayaran
ORDER BY bulan DESC;

-- 6. Riwayat ETL run (bukti automated scheduling / bonus #2) --
--    bandingkan run_started_at antar baris untuk lihat jarak antar batch
SELECT etl_log_id, run_started_at, run_finished_at,
       rows_books, rows_catalog, rows_bridge, rows_fact, status,
       (run_finished_at - run_started_at) AS durasi
FROM Etl_Log
ORDER BY run_started_at DESC;