import os
import json
import time
import re
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By


def save_json(data, filename):
    output_dir = os.path.join("..", "data")
    os.makedirs(output_dir, exist_ok=True)
    filepath = os.path.join(output_dir, filename)
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)


# Daftar catalog yang mau di-scrape. Setiap buku yang ditemukan di sebuah catalog
# akan dicatat sebagai satu baris di book_catalog.json (relasi many-to-many).
# GANTI url di bawah sesuai catalog best-seller lain yang sebenarnya kamu mau ambil.
CATALOGS = [
    {"catalog_id": 1, "catalog_name": "Novel Fiksi Terfavorit", "url": "https://www.gramedia.com/best-seller/novel-fiksi/"},
    {"catalog_id": 2, "catalog_name": "Komik Terfavorit", "url": "https://www.gramedia.com/best-seller/komik/"},
    {"catalog_id": 3, "catalog_name": "Buku Anak Terfavorit", "url": "https://www.gramedia.com/best-seller/buku-anak/"},
]


def collect_product_links(driver, catalog_url, limit=100):
    """Ambil semua link produk dari satu halaman catalog, termasuk lewat tombol
    'Lihat Buku' dan tombol 'lainnya' kalau ada."""
    target_links = set()
    print(f"[*] Meluncur ke catalog: {catalog_url}")
    driver.get(catalog_url)
    time.sleep(4)

    lihat_buku_btns = driver.find_elements(By.XPATH, "//a[contains(text(), 'Lihat Buku')]")
    for btn in lihat_buku_btns:
        href = btn.get_attribute("href")
        if href and "/products/" in href:
            target_links.add(href)
    print(f"[+] {len(target_links)} link awal ditemukan di catalog ini.")

    try:
        lainnya_btn = driver.find_element(By.XPATH, "//a[contains(text(), 'Lainnya')]")
        kumpulan_url = lainnya_btn.get_attribute("href")
        print(f"[->] Tombol 'Lainnya' ditemukan, berpindah ke: {kumpulan_url}")
        driver.get(kumpulan_url)
        time.sleep(5)
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight/2);")
        time.sleep(3)

        product_elements = driver.find_elements(By.CSS_SELECTOR, "a[href*='/products/']")
        for prod in product_elements:
            href = prod.get_attribute("href")
            if href:
                target_links.add(href)
            if len(target_links) >= limit:
                break
    except Exception:
        print("[!] Tombol 'Lainnya' tidak ditemukan di catalog ini. Lanjut dengan data yang ada.")

    return list(target_links)[:limit]


def detect_discount(soup, final_price):
    """Deteksi apakah produk ini sedang diskon.
    Multi-fallback karena testid harga coret Gramedia belum pasti - sesuaikan
    lagi kalau setelah cek HTML asli testid-nya beda."""
    original_price = None
    original_price_tag = (
        soup.find(attrs={"data-testid": "productDetailInitialPrice"})
        or soup.find(attrs={"data-testid": "productDetailOriginalPrice"})
        or soup.find(attrs={"data-testid": "productDetailStrikethroughPrice"})
        or soup.find("s")
        or soup.find(class_=re.compile(r"strike|line-through", re.I))
    )
    if original_price_tag:
        try:
            original_price = int(re.sub(r"\D", "", original_price_tag.text))
        except Exception:
            original_price = None

    discount_badge = soup.find(attrs={"data-testid": "productDetailDiscountBadge"}) or soup.find(
        string=re.compile(r"(hemat|diskon|-\s*\d+%)", re.I)
    )

    if (original_price and final_price and original_price > final_price) or discount_badge:
        return True
    return False


def extract_book_detail(driver, link):
    """Parsing satu halaman detail produk. Return None kalau gagal parse."""
    driver.get(link)
    time.sleep(2)  # beri waktu render SPA agar data-testid muncul sempurna

    soup = BeautifulSoup(driver.page_source, "html.parser")

    # A. Judul
    title_tag = soup.find("h1") or soup.find("div", class_="title")
    title = title_tag.text.strip() if title_tag else "Unknown Title"
    if title == "Unknown Title" or "Error" in title:
        return None

    # B. Penulis
    author_tag = soup.find("a", href=re.compile(r"/author/")) or soup.find("span", class_="author")
    author_name = author_tag.text.strip() if author_tag else "Unknown Author"

    # C. Harga akhir
    price = 0
    price_tag = soup.find(attrs={"data-testid": "productDetailFinalPrice"})
    if price_tag:
        try:
            price = int(re.sub(r"\D", "", price_tag.text))
        except Exception:
            pass

    # D. is_discount
    is_discount = detect_discount(soup, price)

    # E. Spesifikasi lain
    isbn = "N/A"
    num_pages = None
    publish_date = "Unknown"
    publisher_name = "Unknown Publisher"
    format_type = "Soft Cover"

    spec_items = soup.find_all(attrs={"data-testid": "productDetailSpecificationItemValue"})
    for item in spec_items:
        text = item.text.strip()
        if re.match(r"^\d{10,13}$", text):
            isbn = text
        elif text.isdigit() and len(text) <= 4:
            num_pages = int(text)
        elif re.search(r"\d{4}", text) and ("Feb" in text or "Jan" in text or "Mar" in text or "-" in text or " " in text):
            publish_date = text

    text_murni = soup.get_text()
    pub_match = re.search(r"Penerbit\s*([A-Z][A-Za-z\s\.\-]+?)\s*(Tanggal|Berat|ISBN|\n)", text_murni)
    if pub_match:
        publisher_name = pub_match.group(1).replace(":", "").strip()

    return {
        "title": title,
        "isbn": isbn,
        "num_pages": num_pages,
        "publish_date": publish_date,
        "url": link,
        "author_name": author_name,
        "publisher_name": publisher_name,
        "format_type": format_type,
        "price_idr": price,
        "is_discount": is_discount,
    }


def run_real_scraper():
    print("[*] Membangunkan Robot Selenium Chrome (Mode Headless/Siluman)...")
    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-notifications")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--log-level=3")

    try:
        driver = webdriver.Chrome(options=options)
    except Exception as e:
        print(f"[!] Gagal membuka Chrome. Pastikan Google Chrome terinstall.\nDetail: {e}")
        return

    books_list, authors_list, publishers_list, formats_list, analytics_list = [], [], [], [], []
    catalogs_list, book_catalog_list = [], []
    seen_authors, seen_publishers = set(), set()
    seen_books_by_url = {}  # url produk -> book_id, biar buku yg sama di banyak catalog gak discrap ulang
    item_id = 1

    print("\n[*] ==========================================")
    print("[*] FASE 1-2: SCRAPE SEMUA CATALOG + DETAIL BUKU")
    print("[*] ==========================================")

    for catalog in CATALOGS:
        catalogs_list.append({"catalog_id": catalog["catalog_id"], "catalog_name": catalog["catalog_name"]})

        links = collect_product_links(driver, catalog["url"])
        print(f"[+] Catalog '{catalog['catalog_name']}': {len(links)} link produk siap diekstrak.")

        for link in links:
            try:
                if link in seen_books_by_url:
                    # Buku ini sudah pernah discrap lewat catalog lain -> cukup tambah relasi
                    book_catalog_list.append({"book_id": seen_books_by_url[link], "catalog_id": catalog["catalog_id"]})
                    continue

                detail = extract_book_detail(driver, link)
                if detail is None:
                    continue

                print(
                    f" [->] Sukses Ambil ({item_id}): {detail['title'][:30]}... "
                    f"| Rp{detail['price_idr']:,} | Diskon: {detail['is_discount']}"
                )

                books_list.append({
                    "book_id": item_id,
                    "title": detail["title"],
                    "isbn": detail["isbn"],
                    "num_pages": detail["num_pages"],
                    "publish_date": detail["publish_date"],
                    "url": detail["url"],
                    "is_discount": detail["is_discount"],
                })

                if detail["author_name"] not in seen_authors:
                    seen_authors.add(detail["author_name"])
                    authors_list.append({"author_name": detail["author_name"]})

                if detail["publisher_name"] not in seen_publishers:
                    seen_publishers.add(detail["publisher_name"])
                    publishers_list.append({"publisher_name": detail["publisher_name"]})

                formats_list = [{"format_type": "Soft Cover"}, {"format_type": "Hard Cover"}]

                analytics_list.append({
                    "book_id": item_id,
                    "author_name": detail["author_name"],
                    "publisher_name": detail["publisher_name"],
                    "format_type": detail["format_type"],
                    "price_idr": detail["price_idr"],
                })

                book_catalog_list.append({"book_id": item_id, "catalog_id": catalog["catalog_id"]})
                seen_books_by_url[link] = item_id

                # Simpan bertahap setiap 2 data agar aman jika interupsi terminal
                if item_id % 2 == 0:
                    save_json(books_list, "books.json")
                    save_json(authors_list, "authors.json")
                    save_json(publishers_list, "publishers.json")
                    save_json(formats_list, "formats.json")
                    save_json(analytics_list, "analytics.json")
                    save_json(catalogs_list, "catalogs.json")
                    save_json(book_catalog_list, "book_catalog.json")

                item_id += 1
            except Exception:
                continue

    driver.quit()

    # Simpan data final
    save_json(books_list, "books.json")
    save_json(authors_list, "authors.json")
    save_json(publishers_list, "publishers.json")
    save_json(formats_list, "formats.json")
    save_json(analytics_list, "analytics.json")
    save_json(catalogs_list, "catalogs.json")
    save_json(book_catalog_list, "book_catalog.json")

    print("\n[*] ==================================================")
    print(f"[*] DATA TARGET SELEKSI BERHASIL LENGKAP: {item_id - 1} Buku, {len(catalogs_list)} Catalog.")
    print(f"[*] Total relasi book_catalog: {len(book_catalog_list)}")
    print("[*] ==================================================")


if __name__ == "__main__":
    run_real_scraper()