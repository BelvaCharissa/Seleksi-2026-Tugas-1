![Header](Data%20Warehouse/screenshot/readme_header.png)

<h2 align="center">
  <br>
  Data Scraping, Storing, Warehousing, and Automation of
  <br>
  <a href="https://www.gramedia.com">Gramedia</a> Book Store Catalog
  <br>
  <br>
</h2>

## Short Description

Gramedia adalah salah satu toko buku terbesar di Indonesia yang memiliki platform online di **gramedia.com**, menampilkan katalog buku lengkap dari berbagai kategori best-seller (novel fiksi, komik, buku anak, dan lainnya) beserta detail penulis, penerbit, format, jumlah halaman, harga, dan status diskon.

Dalam pembuatan *ETL Project* ini, saya membangun model data toko buku secara menyeluruh: mulai dari entitas yang murni didapat dari hasil *scraping* (`Books`, `Author`, `Publishers`, `Format`, `Catalog`, `Book_Catalog`), hingga entitas tambahan yang relevan untuk melengkapi model transaksional sebuah toko buku online (`Account`, `Address`, `Cart`, `Cart_Item`, `Order`, `Order_details`, `Pengiriman`, `Pembayaran`). Seluruh data hasil scraping diperoleh menggunakan Selenium (untuk menangani rendering dinamis berbasis JavaScript) dan BeautifulSoup (untuk parsing HTML), disimpan dalam format JSON, lalu dimuat ke dalam RDBMS PostgreSQL.

Alasan saya memilih Gramedia sebagai objek *web scraping* adalah karena datanya sangat lengkap dan terstruktur (ISBN, jumlah halaman, tanggal terbit, penulis, penerbit tercatat rapi per produk), serta situsnya memuat data secara dinamis lewat *client-side rendering*, sehingga relevan untuk mensimulasikan kondisi nyata scraping di platform e-commerce modern. Selain itu, relasi antar entitasnya (buku-penulis, buku-penerbit, buku-catalog many-to-many) cukup kaya untuk didemonstrasikan dalam studi kasus desain basis data relasional.

## Program Requirements & Specification

### Requirements

Untuk menjalankan program ini, diperlukan:
- **Bahasa Pemrograman**: Python (versi ≥ 3.9)
- **RDBMS**: PostgreSQL (versi 16)
- **Browser**: Google Chrome (versi terbaru) + ChromeDriver yang sesuai (otomatis dikelola oleh Selenium Manager)
- **Library Python**:
  - selenium
  - beautifulsoup4
  - psycopg2-binary
  - json (built-in)
  - re (built-in)
  - time (built-in)
  - os (built-in)
  - logging (built-in)
  - subprocess (built-in)

### Specification

Bahasa pemrograman **Python** digunakan untuk seluruh pipeline (scraping, storing, warehousing, orkestrasi), sedangkan **PostgreSQL** digunakan sebagai RDBMS baik untuk database operasional (OLTP) maupun data warehouse (OLAP). Library yang digunakan:

- `selenium`
  - **Pertimbangan**: Halaman produk Gramedia me-render harga, ISBN, dan detail buku lain secara dinamis lewat JavaScript (client-side rendering), sehingga request HTTP biasa (tanpa browser) tidak akan menampilkan data itu.
- `beautifulsoup4`
  - **Pertimbangan**: Dipakai untuk mem-parsing HTML yang sudah selesai dirender Selenium, lebih ringan dibanding terus-menerus query lewat Selenium API untuk tiap elemen.
- `psycopg2-binary`
  - **Pertimbangan**: Menghubungkan Python ke PostgreSQL untuk proses *insertion* data JSON ke database (Data Storing) maupun proses ETL dari OLTP ke Data Warehouse.
- `json`
  - **Pertimbangan**: Menyimpan hasil scraping dalam format terstruktur yang mudah diverifikasi sebelum masuk ke database.
- `re`
  - **Pertimbangan**: Ekstraksi pola tertentu dari teks halaman, seperti ISBN (10-13 digit angka), jumlah halaman, dan pembersihan format harga (`Rp84.000` → `84000`).
- `time`
  - **Pertimbangan**: Memberi jeda supaya elemen dinamis (harga, badge diskon) sempat selesai dirender sebelum dibaca oleh scraper.
- `subprocess` & `logging`
  - **Pertimbangan**: Dipakai di `run_etl.py` untuk mengorkestrasi seluruh pipeline (scraping → storing → warehousing) sebagai satu entry point terjadwal, dengan log yang jelas per step.

## How to Use

Berikut panduan langkah demi langkah menjalankan scraper, memuat data ke database operasional, memuat ke data warehouse, dan menjadwalkannya otomatis.

### Bagian 1: Data Scraping (Menghasilkan File JSON)

Langkah ini mengambil data mentah dari `gramedia.com` dan menyimpannya sebagai file `.json`.

1. **Clone Repository**
    Buka terminal, lalu clone repository
   ```sh
   git clone https://github.com/BelvaCharissa/Seleksi-2026-Tugas-1.git
   cd Seleksi-2026-Tugas-1
   ```

2. **Install Library Python**
    Install semua library yang dibutuhkan untuk scraper melalui pip di terminal 
   ```sh
   pip install -U pip
   pip install selenium beautifulsoup4
   ```

3. **Chrome & ChromeDriver**
   Pastikan Google Chrome sudah terinstall. Selenium versi terbaru otomatis mengunduh ChromeDriver yang sesuai (Selenium Manager), jadi tidak perlu instalasi manual.

4. **Jalankan Skrip Scraper**
   ```sh
   cd "Data Scraping/src"
   python scraper.py
   ```
   Scraper ini mengambil data dari 3 catalog best-seller Gramedia (Novel Fiksi, Komik, Buku Anak), lalu menyimpan detail tiap buku (judul, ISBN, jumlah halaman, tanggal terbit, harga, status diskon, penulis, penerbit, format). Proses ini bisa memakan waktu beberapa menit karena scraper menunggu tiap elemen harga benar-benar ter-render sebelum membacanya (dengan retry otomatis kalau gagal).

   Setelah selesai, akan muncul 7 file `.json` di dalam folder `Data Scraping/data`.

### Bagian 2: Data Storing (Storing ke Database Operasional)

Langkah ini membaca file-file `.json` dan memasukkannya ke database PostgreSQL yang terstruktur.

1. **Siapkan Database PostgreSQL**
    * Buat sebuah database baru, misalnya dengan nama `duma_website`.
    * Buat semua tabel yang diperlukan dengan menjalankan file skema SQL yang telah disediakan. Ganti `[USERNAME_ANDA]` dengan username PostgreSQL Anda.
   ```sh
   createdb -U postgres bookstore
   psql -U postgres -d bookstore -f "Data Storing/src/schema.sql"
   ```
   File `schema.sql` membuat seluruh tabel (termasuk constraint PK/FK/CHECK) beserta trigger `trg_update_order_total` yang otomatis menghitung ulang `total_harga` di tabel `Order` setiap kali `Order_details` berubah.

2. **Install Library Database**
    Install library Python yang dibutuhkan untuk menghubungkan skrip dengan PostgreSQL.
   ```sh
   pip install psycopg2-binary
   ```

3. **Jalankan Skrip Penyimpanan (Loader)**
   ```sh
   cd "Data Storing/src"
   python load_data.py
   ```
   Skrip ini membaca semua file JSON hasil scraping dan memasukkannya ke tabel `Author`, `Publishers`, `Format`, `Catalog`, `Books`, dan `Book_Catalog`. Tabel tambahan (`Account`, `Address`, `Order`, `Order_details`, `Cart`, `Cart_Item`, `Pengiriman`, `Pembayaran`) sengaja dibiarkan kosong sesuai ketentuan tugas. Proses ini bersifat idempotent (`ON CONFLICT DO NOTHING`), sehingga aman dijalankan ulang tanpa membuat data duplikat.

4. **Export Database ke Format SQL**
    Dump data yang sudah dimasukkan ke dalam file SQL.
   ```sh
   pg_dump -U postgres -d bookstore -f "Data Storing/export/bookstore_export.sql"
   ```

### Bagian 3 (Bonus): Data Warehousing

Langkah ini memindahkan data dari database operasional (OLTP) ke **database Data Warehouse** (OLAP) yang dirancang untuk analisis, lewat proses ETL (Extract, Transform, Load).

1. **Siapkan Database Data Warehouse**
   ```sh
   createdb -U postgres bookstore_dw
   psql -U postgres -d bookstore_dw -f "Data Warehouse/src/dw_schema.sql"
   ```

2. **Load Data dari OLTP ke Data Warehouse**
   ```sh
   cd "Data Warehouse/src"
   python dw_load_data.py
   ```
   Skrip ini melakukan JOIN antara `Books`, `Author`, `Publishers`, `Format` di sisi OLTP untuk didenormalisasi langsung ke `Dim_Books`, sehingga query analitik di warehouse tidak perlu JOIN berlapis. Proses ini idempotent (`ON CONFLICT DO UPDATE`) dan setiap eksekusi dicatat ke tabel `Etl_Log` (dipakai sebagai bukti automated scheduling di Bagian 4).

3. **Verifikasi Tabel di Data Warehouse**
    Setelah proses ETL selesai, periksa apakah tabel-tabel dimensi dan fakta di database `duma_dw` sudah terisi dengan benar.
   ```sh
   psql -U postgres -d bookstore_dw -c "\dt"
   ```

4. **Export Database Data Warehouse**
    Untuk keperluan submisi atau backup, *dump* struktur dan data dari Data Warehouse ke dalam sebuah file `.sql`.
   ```sh
   pg_dump -U postgres -d bookstore_dw -f "Data Warehouse/export/bookstore_dw_export.sql"
   ```

### Bagian 4 (Bonus): Automated Scheduling

Tahap ini mengotomatisasi keseluruhan pipeline (scraping → storing → warehousing) agar berjalan berkala sesuai jadwal, menggunakan **Windows Task Scheduler** (karena environment pengerjaan menggunakan Windows, berbeda dengan `cron` yang dipakai di macOS/Linux — konsepnya identik, cuma tooling OS-nya berbeda).

1. **Menjalankan Pipeline Secara Manual**
   ```sh
   cd "Data Warehouse/src"
   python run_etl.py
   ```
   `run_etl.py` adalah orkestrator tunggal yang menjalankan `scraper.py` → `load_data.py` → `dw_load_data.py` secara berurutan sebagai subprocess terpisah, dengan log jelas per step dan tetap lanjut ke step berikutnya meski satu step gagal.

2. **Menjadwalkan dengan Windows Task Scheduler**
   - Buka **Task Scheduler** → **Create Basic Task**
   - Nama: `Bookstore ETL Pipeline`
   - Trigger: pilih frekuensi yang diinginkan (mis. Daily / Hourly)
   - Action: **Start a program** → arahkan ke `Data Warehouse/src/run_wrapper.bat`

   `run_wrapper.bat` sengaja dibuat minimal (cuma memicu `run_etl.py`), supaya seluruh logika pipeline tetap terpusat di satu file Python yang mudah di-maintain dan ditest manual.

3. **Verifikasi Jadwal Berjalan (Bukti Timestamp Antar Batch)**
   ```sh
   psql -U postgres -d bookstore_dw -c "SELECT etl_log_id, run_started_at, run_finished_at, status FROM Etl_Log ORDER BY run_started_at;"
   ```
   Contoh hasil setelah pipeline berjalan 2 batch:

   | etl_log_id | run_started_at | run_finished_at | status |
   |---|---|---|---|
   | 1 | 2026-07-22 11:50:47 | 2026-07-22 11:51:05 | SUCCESS |
   | 2 | 2026-07-22 15:30:12 | 2026-07-22 15:30:34 | SUCCESS |

   Semua proses load (baik ke OLTP maupun Data Warehouse) menggunakan `ON CONFLICT DO NOTHING` / `DO UPDATE`, sehingga **tidak ada redundansi data** meskipun pipeline dijalankan berkali-kali secara terjadwal.

### Bagian 5 (Bonus): Query Optimization

Berikut 3 query yang dioptimalkan menggunakan index, beserta perbandingan `EXPLAIN ANALYZE` sebelum dan sesudah (lihat detail lengkap di `Query Optimization/optimization_queries.sql`).

| # | Kasus Penggunaan | Index yang Ditambahkan | Perubahan Query Plan |
|---|---|---|---|
| 1 | Pencarian judul buku (`ILIKE '%keyword%'`) | GIN index dengan `pg_trgm` di `Books.title` | `Seq Scan` → `Bitmap Index Scan` |
| 2 | Daftar buku per catalog (JOIN `Book_Catalog`) | B-tree index di `Book_Catalog.catalog_id` | `Seq Scan` → `Index Scan` |
| 3 | Halaman buku diskon terurut harga | Partial index di `Books.price WHERE is_discount = TRUE` | `Seq Scan + Sort` → `Index Scan` (tanpa sort terpisah) |

Hasil query (jumlah baris & datanya) dipastikan **identik** sebelum dan sesudah index ditambahkan — index cuma mengubah cara database *mencari* data, bukan hasil akhirnya.

```sh
psql -U postgres -d bookstore -f "Query Optimization/optimization_queries.sql"
```

## JSON Structure

Scraper menghasilkan 7 berkas JSON terstruktur pada folder `Data Scraping/data/`:

- `books.json`
- `authors.json`
- `publishers.json`
- `formats.json`
- `analytics.json`
- `catalogs.json`
- `book_catalog.json`

Berikut struktur dan contoh data masing-masing file:

1. **books.json**
   Menyimpan detail utama tiap buku.
   ```json
   {
       "book_id": 5,
       "title": "Laut Bercerita",
       "isbn": "9786024246945",
       "num_pages": 400,
       "publish_date": "21 Des 2017",
       "url": "https://www.gramedia.com/products/laut-bercerita",
       "is_discount": true
   }
   ```

2. **authors.json**
   Daftar penulis unik.
   ```json
   { "author_name": "Leila S. Chudori" }
   ```

3. **publishers.json**
   Daftar penerbit unik.
   ```json
   { "publisher_name": "Kepustakaan Populer Gramedia" }
   ```

4. **formats.json**
   Daftar format buku.
   ```json
   { "format_type": "Soft Cover" }
   ```

5. **analytics.json**
   Menyimpan relasi buku ke author/publisher/format beserta harga, dipakai sebagai penghubung untuk resolve foreign key saat loading ke database.
   ```json
   {
       "book_id": 5,
       "author_name": "Leila S. Chudori",
       "publisher_name": "Kepustakaan Populer Gramedia",
       "format_type": "Soft Cover",
       "price_idr": 92000
   }
   ```

6. **catalogs.json**
   Daftar catalog/koleksi kurasi yang di-scrape.
   ```json
   { "catalog_id": 1, "catalog_name": "Novel Fiksi Terfavorit" }
   ```

7. **book_catalog.json**
   Relasi many-to-many antara buku dan catalog (satu buku bisa masuk lebih dari satu catalog).
   ```json
   { "book_id": 5, "catalog_id": 1 }
   ```

## Database Structure

Bagian ini menampilkan desain struktur database untuk kedua sistem: database operasional (OLTP) untuk Data Storing, dan Data Warehouse (OLAP) untuk analisis.

### 1. Database Operasional (OLTP) — Data Storing

#### Entity Relationship Diagram (ERD)
<div align="center">
  <img src="Data Storing/design/ERD.png" alt="ERD Database Operasional"/>
</div>

#### Diagram Relasional
<div align="center">
  <img src="Data Storing/design/relational_diagram.png" alt="Diagram Relasional"/>
</div>

### Penjelasan Translasi ERD ke Relasional

1. **Setiap Entitas Dijadikan Tabel**
   *Strong entity* seperti `Account`, `Books`, `Order`, dan lainnya langsung menjadi tabel dengan primary key masing-masing (`account_email`, `book_id`, `order_id`, dst). *Weak entity* seperti `Address`, `Cart_Item`, dan `Order_details` ditranslasi dengan menambahkan foreign key dari induknya (`account_email`, `cart_id`, `order_id`), karena baris-baris ini tidak bisa berdiri sendiri tanpa entitas induknya.

2. **Relasi One-to-Many (1:N) Ditranslasi dengan Menambahkan Foreign Key di Sisi "Many"**
   - **Contoh (`Publishers` dan `Books`)**: satu penerbit menerbitkan banyak buku, maka tabel `Books` menyimpan `publisher_id` sebagai foreign key.
   - **Contoh (`Order` dan `Order_details`)**: satu order berisi banyak baris detail, maka `Order_details` menyimpan `order_id` sebagai foreign key. Relasi ini unik karena **kedua sisi bersifat total** — Order tidak boleh kosong (wajib ≥1 detail), dan Order_details tidak bisa berdiri sendiri tanpa Order induknya.

3. **Relasi Many-to-Many (M:N) Ditranslasi Menjadi Tabel Penghubung**
   - **Contoh (`Books` dan `Catalog`)**: satu buku bisa masuk banyak catalog kurasi, dan satu catalog berisi banyak buku. Dibuat tabel penghubung `Book_Catalog` dengan composite primary key (`book_id`, `catalog_id`).
   - **Contoh (`Cart` dan `Books`)**: satu cart bisa berisi banyak buku, satu buku bisa ada di banyak cart berbeda. Dibuat tabel `Cart_Item` sebagai junction table, dengan `cart_id` dan `book_id` sebagai foreign key.

4. **Snapshot Data Historis untuk Integritas Transaksi**
   Kolom `harga_saat_dibeli` di `Order_details` sengaja disimpan terpisah dari `Books.price`, supaya riwayat transaksi tidak berubah meskipun harga buku di-update setelahnya.

5. **Constraint sebagai Representasi Business Rule**
   - `CHECK` constraint memastikan `quantity > 0`, `price >= 0`, dan `status_order` hanya boleh salah satu dari nilai yang telah ditentukan.
   - `UNIQUE` constraint di `author_name`, `publisher_name`, `format_name`, `catalog_name` mencegah duplikasi master data.
   - Trigger `trg_update_order_total` menjaga konsistensi `total_harga` di `Order` secara otomatis setiap kali `Order_details` berubah.

---

### 2. Data Warehouse (OLAP) — Data Warehousing

Skema ini dirancang menggunakan pendekatan **Star Schema**, dengan satu pengecualian **Snowflake** pada `Dim_Catalog` (karena relasi Books↔Catalog bersifat many-to-many, sehingga tidak bisa didenormalisasi langsung ke fact table seperti dimensi lainnya).

#### Entity Relationship Diagram (ERD)
<div align="center">
  <img src="Data Warehouse/design/ERD.png" alt="ERD Data Warehouse"/>
</div>

#### Diagram Relasional
<div align="center">
  <img src="Data Warehouse/design/snowflake_schema.png" alt="Diagram Relasional DW"/>
</div>

### Penjelasan Translasi ERD ke Star Schema

1. **Pembagian Menjadi Tabel Dimensi dan Tabel Fakta**
   - **Tabel Dimensi**: `Dim_Account`, `Dim_Address`, `Dim_Payment`, `Dim_Shipping`, `Dim_Books`, `Dim_Catalog` menyimpan atribut deskriptif ("who, what, where"). `Dim_Books` sengaja didenormalisasi — kolom `author_name`, `publisher_name`, `format_name` langsung jadi kolom di sini (bukan tabel dimensi terpisah), karena relasinya 1:N dari sisi Books, sehingga menghindari JOIN berlapis saat query laporan.
   - **Tabel Fakta**: `Fact_Order_Details` berisi ukuran numerik (`quantity`, `harga_saat_dibeli`, `subtotal`) beserta foreign key ke setiap tabel dimensi.

2. **Relasi Many-to-One dari Fakta ke Dimensi**
   Karena fact table merekam kombinasi granular (per buku, per akun, per alamat, per pengiriman, per pembayaran), dan setiap entitas dimensi bisa dipakai berulang (satu buku dibeli banyak kali, satu akun order banyak kali, dst), maka semua relasinya bersifat **many-to-one** dari fact ke dimension — **kecuali** Books ke Catalog yang tetap **many-to-many** (lewat `Bridge_Book_Catalog`) karena satu buku bisa masuk ke lebih dari satu catalog kurasi sekaligus.

3. **Grain dari Tabel Fakta**
   *Grain* dari `Fact_Order_Details` adalah **satu baris per buku yang dibeli dalam satu order** — kombinasi unik antara order, buku, dan atribut transaksi lainnya (harga saat dibeli, jumlah, subtotal).

4. **Tabel Log untuk Bukti Automated Scheduling**
   Tabel `Etl_Log` mencatat `run_started_at`, `run_finished_at`, jumlah baris tiap tabel, dan status tiap kali pipeline ETL dijalankan — dipakai sebagai bukti nyata bahwa proses scheduling (Bonus #2) benar-benar berjalan berkala.

Pendekatan denormalisasi ini sengaja dipilih untuk menghindari JOIN kompleks saat melakukan query analitik (lihat contoh di `Data Warehouse/src/dw_analytical_queries.sql`), sehingga proses agregasi data menjadi jauh lebih cepat dibanding query yang sama di skema OLTP ternormalisasi.

## Screenshot

### 1. Data Scraping
<div align="left">
  <img src="Data Scraping/screenshots/ss_scraping1.png" alt="Scraping 1" width="800"/>
  <img src="Data Scraping/screenshots/ss_scraping2.png" alt="Scraping 2" width="800"/>
</div>

### 2. Data Storing

#### Tabel From Scraping to Storing
<div align="left">
  <img src="Data Storing/screenshots/from scraping to storing.png" alt="Tabel Storing" width="400"/>
</div>

#### Pembuatan Tabel pada Database
<div align="left">
  <img src="Data Storing/screenshots/create table.png" alt="PembuatanTabel Database" width="400"/>
</div>

#### Tabel pada Database
<div align="left">
  <img src="Data Storing/screenshots/data_storing_table.png" alt="Tabel Database" width="400"/>
</div>

#### Query SELECT ... WHERE (Bukti Data Tersimpan)
<div align="left">
  <img src="Data Storing/screenshots/query_discount_books.png" alt="Query Buku Diskon"/>
</div>
<div align="left">
  <img src="Data Storing/screenshots/query_join_author_publisher.png" alt="Query Join Author Publisher"/>
</div>

### 3. Data Warehouse

#### ETL Run
<div align="left">
  <img src="Data Warehouse/screenshots/inserting_data.png" alt="Inserting Data" width="300"/>
</div>

#### Tabel pada Database
<div align="left">
  <img src="Data Warehouse/screenshots/data_warehouse_table.png" alt="DW Table" width="300"/>
</div>

#### Query Jumlah Buku per Penerbit
<div align="left">
  <img src="Data Warehouse/screenshots/try_queries.png" alt="Query Publisher" width="600"/>
</div>

#### Query Persentase Diskon per Format
<div align="left">
  <img src="Data Warehouse/screenshots/try_queries.png" alt="Query Format Discount" width="600"/>
</div>

#### Query Rata-Rata Harga per Catalog
<div align="left">
  <img src="Data Warehouse/screenshots/try_queries.png" alt="Query Catalog" width="600"/>
</div>

### 4. Automated Scheduling

#### Riwayat Etl_Log (Bukti Timestamp Antar Batch)
<div align="left">
  <img src="Data Warehouse/screenshots/etl_log_2_baris.png" alt="ETL Log" width="700"/>
</div>

#### Windows Task Scheduler
<div align="left">
  <img src="Data Warehouse/screenshots/task_scheduler.png" alt="Task Scheduler" width="700"/>
</div>

### 5. Query Optimization

#### Optimasi 1: Pencarian Judul Buku
<div align="left">
  <img src="Query Optimization/screenshots/optimasi1_sebelum.png" alt="Optimasi 1 Sebelum" width="700"/>
</div>
<div align="left">
  <img src="Query Optimization/screenshots/optimasi1_sesudah.png" alt="Optimasi 1 Sesudah" width="700"/>
</div>

#### Optimasi 2: Buku per Catalog
<div align="left">
  <img src="Query Optimization/screenshots/optimasi2_sebelum.png" alt="Optimasi 2 Sebelum" width="700"/>
</div>
<div align="left">
  <img src="Query Optimization/screenshots/optimasi2_sesudah.png" alt="Optimasi 2 Sesudah" width="700"/>
</div>

#### Optimasi 3: Halaman Buku Diskon
<div align="left">
  <img src="Query Optimization/screenshots/optimasi3_sebelum.png" alt="Optimasi 3 Sebelum" width="700"/>
</div>
<div align="left">
  <img src="Query Optimization/screenshots/optimasi3_sesudah.png" alt="Optimasi 3 Sesudah" width="700"/>
</div>

## Penggunaan AI
 
Saya menggunakan Claude (Anthropic) sebagai *pair-programming assistant* dan *tutor* sepanjang pengerjaan tugas ini. Berikut rincian jujur mengenai bagian mana yang dibantu AI, mana yang saya kerjakan sendiri, serta refleksi dari proses ini.
 
### 1. Bagian yang Dibantu AI
 
- **Review dan validasi desain ERD**: saya menggambar ERD sendiri di draw.io, lalu meminta Claude mengecek arah panah (notasi one/many), garis double (total/partial participation), dan konsistensi kardinalitas antar relasi. Banyak kesalahan (arah panah terbalik, relasi yang belum digambar, entity yang salah ditandai weak/bukan) baru saya sadari setelah ditunjukkan dan dijelaskan alasannya oleh Claude bukan langsung diberi jawaban jadi.
- **Penjelasan konsep desain database**: konsep weak entity, composite key, many-to-many via junction table, snapshot data historis (`harga_saat_dibeli`), dan perbedaan star vs snowflake schema saya pahami lewat tanya-jawab berulang dengan Claude sampai saya bisa menjelaskan ulang alasannya sendiri.
- **Penulisan kode**: `load_data.py`, `dw_load_data.py`, `run_etl.py`, `run_wrapper.bat`, dan `scraper.py` ditulis oleh Claude berdasarkan spesifikasi skema yang sudah saya rancang dan validasi sebelumnya.
- **Debugging**: saya menjalankan sendiri semua command dan script di terminal, lalu men-*share* pesan error yang muncul (misal `InvalidSessionIdException` saat Chrome crash, `CheckViolation` saat `num_pages = 0`, salah baca `data-testid` untuk deteksi diskon) ke Claude untuk didiagnosis dan diperbaiki.
- **Penyusunan dokumentasi**: struktur dan draft README ini dibantu disusun oleh Claude, saya sesuaikan isinya dengan hasil kerja nyata saya

### 2. Bagian yang Dikerjakan Sendiri
 
- Riset awal dan pemilihan objek scraping (gramedia.com), termasuk eksplorasi manual struktur halaman lewat DevTools browser untuk menemukan `data-testid` yang benar (misal `productDetailSlicePrice`, `productDetailDiscount`), Claude tidak bisa mengakses halaman yang di-render JavaScript, jadi saya yang inspect elemen secara manual dan melaporkan hasilnya.
- Instalasi dan konfigurasi environment (PostgreSQL, Python, ChromeDriver, Windows PATH, reset password PostgreSQL lewat `pg_hba.conf`) — dijalankan dan di-troubleshoot sendiri di komputer saya, dengan panduan dari Claude.
- Eksekusi seluruh pipeline (menjalankan scraper, load data, ETL warehouse) dan verifikasi hasilnya lewat query manual.
- Pengambilan seluruh screenshot bukti dan penyusunan folder submission sesuai struktur yang diminta.
- Pengambilan keputusan desain akhir (misal: memutuskan `Catalog` bersifat many-to-many terhadap `Books` karena satu buku bisa masuk lebih dari satu koleksi kurasi  ini keputusan bisnis dari saya, bukan usulan AI).

### 3. Refleksi Penggunaan AI
 
Awalnya saya beberapa kali salah desain (misal menaruh `author_id` di tabel yang salah, arah panah kardinalitas terbalik berkali-kali di banyak relasi berbeda). Proses tanya-jawab berulang dengan Claude — di mana saya diminta menjelaskan alasan di balik setiap keputusan desain, bukan cuma diberi jawaban akhir — membantu saya benar-benar memahami *kenapa* suatu relasi harus digambar dengan cara tertentu, bukan sekadar meniru. Saya merasa proses ini lebih mendekati *belajar dibimbing* dibanding *dikerjakan otomatis*, karena saya tetap harus mengeksekusi, menguji, dan melaporkan hasil nyata di komputer saya sendiri — termasuk menghadapi error yang tidak terduga (Chrome crash, encoding UTF-8 di terminal Windows, constraint violation) yang harus saya diagnosis bareng-bareng lewat log yang saya kirim sendiri.
 
### 4. Detail Lainnya
 
- Semua kode di repository ini sudah saya jalankan sendiri dan verifikasi hasilnya (bukan disalin mentah tanpa dites).
- Percakapan penuh dengan AI (termasuk seluruh proses debugging dan revisi desain) dapat ditunjukkan sebagai bukti proses jika diperlukan.

## Referensi
1. **[Gramedia - Best Seller Books](https://www.gramedia.com/best-seller)**
2. **[Dokumentasi PostgreSQL](https://www.postgresql.org/)**
3. **[Dokumentasi Selenium](https://pypi.org/project/selenium/)**
4. **[Dokumentasi BeautifulSoup4](https://pypi.org/project/beautifulsoup4/)**
5. **[Dokumentasi psycopg2](https://pypi.org/project/psycopg2-binary/)**


## Author
Belva Charissa | 18224051
