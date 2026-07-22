--
-- PostgreSQL database dump
--

\restrict GG5QS1MjvKFEOoheGN0kBa1j00GwHc6u2u4tjfOTE8cKjyvPqoGu3XulITzs82E

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fn_update_order_total(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_update_order_total() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.fn_update_order_total() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Order" (
    order_id integer NOT NULL,
    account_email character varying(255) NOT NULL,
    address_id integer NOT NULL,
    pengiriman_id integer NOT NULL,
    pembayaran_id integer NOT NULL,
    order_date date DEFAULT CURRENT_DATE NOT NULL,
    ongkos_kirim numeric(12,2) DEFAULT 0 NOT NULL,
    total_harga numeric(12,2) DEFAULT 0 NOT NULL,
    status_order character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    CONSTRAINT "Order_ongkos_kirim_check" CHECK ((ongkos_kirim >= (0)::numeric)),
    CONSTRAINT "Order_status_order_check" CHECK (((status_order)::text = ANY ((ARRAY['pending'::character varying, 'paid'::character varying, 'shipped'::character varying, 'completed'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT "Order_total_harga_check" CHECK ((total_harga >= (0)::numeric))
);


ALTER TABLE public."Order" OWNER TO postgres;

--
-- Name: Order_order_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Order_order_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Order_order_id_seq" OWNER TO postgres;

--
-- Name: Order_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Order_order_id_seq" OWNED BY public."Order".order_id;


--
-- Name: account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.account (
    account_email character varying(255) NOT NULL,
    nama_penerima character varying(255) NOT NULL,
    no_telp character varying(20)
);


ALTER TABLE public.account OWNER TO postgres;

--
-- Name: address; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.address (
    address_id integer NOT NULL,
    account_email character varying(255) NOT NULL,
    label_alamat character varying(100),
    provinsi character varying(100),
    kota character varying(100),
    kecamatan character varying(100),
    kode_pos character varying(10),
    alamat_lengkap text
);


ALTER TABLE public.address OWNER TO postgres;

--
-- Name: address_address_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.address_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.address_address_id_seq OWNER TO postgres;

--
-- Name: address_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.address_address_id_seq OWNED BY public.address.address_id;


--
-- Name: author; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.author (
    author_id integer NOT NULL,
    author_name character varying(255) NOT NULL
);


ALTER TABLE public.author OWNER TO postgres;

--
-- Name: author_author_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.author_author_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.author_author_id_seq OWNER TO postgres;

--
-- Name: author_author_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.author_author_id_seq OWNED BY public.author.author_id;


--
-- Name: book_catalog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.book_catalog (
    book_id integer NOT NULL,
    catalog_id integer NOT NULL
);


ALTER TABLE public.book_catalog OWNER TO postgres;

--
-- Name: books; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.books (
    book_id integer NOT NULL,
    publisher_id integer NOT NULL,
    format_id integer NOT NULL,
    author_id integer NOT NULL,
    title character varying(500) NOT NULL,
    isbn character varying(20),
    num_pages integer,
    publish_date character varying(50),
    url text,
    price numeric(12,2),
    is_discount boolean DEFAULT false NOT NULL,
    CONSTRAINT books_num_pages_check CHECK (((num_pages IS NULL) OR (num_pages > 0))),
    CONSTRAINT books_price_check CHECK ((price >= (0)::numeric))
);


ALTER TABLE public.books OWNER TO postgres;

--
-- Name: cart; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cart (
    cart_id integer NOT NULL,
    account_email character varying(255) NOT NULL
);


ALTER TABLE public.cart OWNER TO postgres;

--
-- Name: cart_cart_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cart_cart_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cart_cart_id_seq OWNER TO postgres;

--
-- Name: cart_cart_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cart_cart_id_seq OWNED BY public.cart.cart_id;


--
-- Name: cart_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cart_item (
    cart_item_id integer NOT NULL,
    cart_id integer NOT NULL,
    book_id integer NOT NULL,
    quantity integer NOT NULL,
    CONSTRAINT cart_item_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE public.cart_item OWNER TO postgres;

--
-- Name: cart_item_cart_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cart_item_cart_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cart_item_cart_item_id_seq OWNER TO postgres;

--
-- Name: cart_item_cart_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cart_item_cart_item_id_seq OWNED BY public.cart_item.cart_item_id;


--
-- Name: catalog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.catalog (
    catalog_id integer NOT NULL,
    catalog_name character varying(255) NOT NULL
);


ALTER TABLE public.catalog OWNER TO postgres;

--
-- Name: catalog_catalog_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.catalog_catalog_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.catalog_catalog_id_seq OWNER TO postgres;

--
-- Name: catalog_catalog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.catalog_catalog_id_seq OWNED BY public.catalog.catalog_id;


--
-- Name: format; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.format (
    format_id integer NOT NULL,
    format_name character varying(100) NOT NULL
);


ALTER TABLE public.format OWNER TO postgres;

--
-- Name: format_format_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.format_format_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.format_format_id_seq OWNER TO postgres;

--
-- Name: format_format_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.format_format_id_seq OWNED BY public.format.format_id;


--
-- Name: order_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_details (
    order_detail_id integer NOT NULL,
    order_id integer NOT NULL,
    book_id integer NOT NULL,
    quantity integer NOT NULL,
    harga_saat_dibeli numeric(12,2) NOT NULL,
    CONSTRAINT order_details_harga_saat_dibeli_check CHECK ((harga_saat_dibeli >= (0)::numeric)),
    CONSTRAINT order_details_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE public.order_details OWNER TO postgres;

--
-- Name: order_details_order_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_details_order_detail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_details_order_detail_id_seq OWNER TO postgres;

--
-- Name: order_details_order_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_details_order_detail_id_seq OWNED BY public.order_details.order_detail_id;


--
-- Name: pembayaran; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pembayaran (
    pembayaran_id integer NOT NULL,
    metode_pembayaran character varying(100) NOT NULL
);


ALTER TABLE public.pembayaran OWNER TO postgres;

--
-- Name: pembayaran_pembayaran_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pembayaran_pembayaran_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pembayaran_pembayaran_id_seq OWNER TO postgres;

--
-- Name: pembayaran_pembayaran_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pembayaran_pembayaran_id_seq OWNED BY public.pembayaran.pembayaran_id;


--
-- Name: pengiriman; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pengiriman (
    pengiriman_id integer NOT NULL,
    nama_jasa character varying(100) NOT NULL
);


ALTER TABLE public.pengiriman OWNER TO postgres;

--
-- Name: pengiriman_pengiriman_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pengiriman_pengiriman_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pengiriman_pengiriman_id_seq OWNER TO postgres;

--
-- Name: pengiriman_pengiriman_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pengiriman_pengiriman_id_seq OWNED BY public.pengiriman.pengiriman_id;


--
-- Name: publishers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.publishers (
    publisher_id integer NOT NULL,
    publisher_name character varying(255) NOT NULL
);


ALTER TABLE public.publishers OWNER TO postgres;

--
-- Name: publishers_publisher_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.publishers_publisher_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.publishers_publisher_id_seq OWNER TO postgres;

--
-- Name: publishers_publisher_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.publishers_publisher_id_seq OWNED BY public.publishers.publisher_id;


--
-- Name: Order order_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order" ALTER COLUMN order_id SET DEFAULT nextval('public."Order_order_id_seq"'::regclass);


--
-- Name: address address_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.address ALTER COLUMN address_id SET DEFAULT nextval('public.address_address_id_seq'::regclass);


--
-- Name: author author_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.author ALTER COLUMN author_id SET DEFAULT nextval('public.author_author_id_seq'::regclass);


--
-- Name: cart cart_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart ALTER COLUMN cart_id SET DEFAULT nextval('public.cart_cart_id_seq'::regclass);


--
-- Name: cart_item cart_item_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_item ALTER COLUMN cart_item_id SET DEFAULT nextval('public.cart_item_cart_item_id_seq'::regclass);


--
-- Name: catalog catalog_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.catalog ALTER COLUMN catalog_id SET DEFAULT nextval('public.catalog_catalog_id_seq'::regclass);


--
-- Name: format format_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.format ALTER COLUMN format_id SET DEFAULT nextval('public.format_format_id_seq'::regclass);


--
-- Name: order_details order_detail_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_details ALTER COLUMN order_detail_id SET DEFAULT nextval('public.order_details_order_detail_id_seq'::regclass);


--
-- Name: pembayaran pembayaran_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pembayaran ALTER COLUMN pembayaran_id SET DEFAULT nextval('public.pembayaran_pembayaran_id_seq'::regclass);


--
-- Name: pengiriman pengiriman_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pengiriman ALTER COLUMN pengiriman_id SET DEFAULT nextval('public.pengiriman_pengiriman_id_seq'::regclass);


--
-- Name: publishers publisher_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishers ALTER COLUMN publisher_id SET DEFAULT nextval('public.publishers_publisher_id_seq'::regclass);


--
-- Data for Name: Order; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Order" (order_id, account_email, address_id, pengiriman_id, pembayaran_id, order_date, ongkos_kirim, total_harga, status_order) FROM stdin;
\.


--
-- Data for Name: account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.account (account_email, nama_penerima, no_telp) FROM stdin;
\.


--
-- Data for Name: address; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.address (address_id, account_email, label_alamat, provinsi, kota, kecamatan, kode_pos, alamat_lengkap) FROM stdin;
\.


--
-- Data for Name: author; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.author (author_id, author_name) FROM stdin;
1	Matt Haig
2	Jocelyn Suherman
3	Keigo Higashino
4	Sara Wijayanto
5	J.S. Khairen
6	Andrea Hirata
7	C. S. Lewis
8	James Clear
9	Leila S. Chudori
10	Soji Shimada
11	MOMMY ASF
12	Cho Nam-Joo
13	Ika Natassa
14	Brian Khrisna
15	Uketsu
16	Ita krn
17	Paulo Coelho
18	Toshikazu Kawaguchi
19	Robert T. Kiyosaki
20	Tere Liye
21	Almira Bastari
22	Mel Robbins
23	TARA WESTOVER
24	Erwin Parengkuan
25	Durian Sukegawa
26	Sohn Won - Pyung
27	Akhmad Fadly
28	Bagus R. Nugraha
29	Muhammad Mice Misrad
30	Leigh Bardugo
31	Lexie Xu
32	Hyuganatsu / Touko Shino
33	Egestigi
34	MAMORU HOSODA
35	Rifujin Na Magonote
36	Shiro Moriya
37	Bryan Valenza
38	Vernando Altamirano
39	Yoshihiro Togashi
40	Mio Nukaga
41	Tappei Nagatsuki
42	Surya Putra
43	Nabeshiki
44	Osamu Tezuka
45	Bumilangit Comics
46	Qoni
47	Osamu Nishi, Shiro Usazaki
48	Jasmine H. Surkatty
49	Kai Elian
50	Daisuke Aizawa
51	Hans Jaladara
52	Daken
53	Olvyanda Ariesta
54	Ito Junji
55	Imamura Masahiro
56	Hokky Situngkir
57	Tim Kumata
58	Yoshito Usui & Uy Studio
59	Omenilno
60	Aoyama Gosho
61	Lukita lova, M. Gani Dhafin R. Yulistiana Prasetya & Tary Lestari, Foggy FF
62	Devar Entertainment
\.


--
-- Data for Name: book_catalog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.book_catalog (book_id, catalog_id) FROM stdin;
1	1
2	1
3	1
4	1
5	1
6	1
7	1
8	1
9	1
10	1
11	1
12	1
13	1
14	1
15	1
16	1
17	1
18	1
19	1
20	1
21	1
22	1
23	1
24	1
25	1
26	1
27	1
28	1
29	1
30	1
31	1
32	2
33	2
34	2
35	2
36	2
37	2
38	2
39	2
40	2
41	2
42	2
43	2
44	2
45	2
46	2
47	2
48	2
49	2
50	2
51	2
52	2
53	2
54	2
55	2
56	2
57	2
58	2
59	2
60	2
61	2
62	2
63	2
64	2
65	2
66	2
67	2
68	2
69	2
70	2
71	2
72	2
73	2
74	2
75	2
76	2
77	2
78	2
79	2
80	2
81	2
15	3
21	3
25	3
10	3
82	3
28	3
19	3
17	3
8	3
16	3
20	3
\.


--
-- Data for Name: books; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.books (book_id, publisher_id, format_id, author_id, title, isbn, num_pages, publish_date, url, price, is_discount) FROM stdin;
1	1	1	1	Perpustakaan Tengah Malam (The Midnight Library)	9786020649320	368	10 Jun 2021	https://www.gramedia.com/products/perpustakaan-tengah-malam-the-midnight-library?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	84000.00	t
2	2	1	2	Shaka Oh Shaka	9786235953014	268	31 Jan 2022	https://www.gramedia.com/products/shaka-oh-shaka?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	84150.00	t
3	1	1	3	Black Showman Dan Pembunuhan Di Kota Tak Bernama	9786020657691	516	22 Des 2021	https://www.gramedia.com/products/black-showman-dan-pembunuhan-di-kota-tak-bernama?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	101250.00	t
4	3	1	4	Wingit	9786230021831	256	16 Des 2020	https://www.gramedia.com/products/wingit?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=Best_Seller_Buku	75000.00	t
5	4	1	5	Melangkah	9786020523316	368	23 Mar 2020	https://www.gramedia.com/products/melangkah-1?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	74250.00	t
6	5	1	6	Brianna dan Bottomwise	9786022919421	380	5 Agu 2022	https://www.gramedia.com/products/brianna-dan-bottomwise?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	103500.00	t
7	1	1	7	The Chronicles of Narnia #3: The Horse & His Boy (Kuda dan Anak Manusia)	9786020336411	312	2 Jun 2022	https://www.gramedia.com/products/the-chronicles-of-narnia-3-the-horse-his-boy-kuda-dan-anak-manusia?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	20700.00	t
8	1	1	8	Atomic Habits: Perubahan Kecil yang Memberikan Hasil Luar Biasa	9786020633176	352	16 Sep 2019	https://www.gramedia.com/products/atomic-habits-perubahan-kecil-yang-memberikan-hasil-luar-bi	86400.00	t
9	6	1	9	Laut Bercerita	9786024818722	400	3 Agu 2022	https://www.gramedia.com/products/laut-bercerita-2?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	152000.00	t
10	1	1	3	Keajaiban Toko Kelontong Namiya	9786020648293	400	16 Des 2020	https://www.gramedia.com/products/keajaiban-toko-kelontong-namiya-namiya-zakkaten-no-kisekithe-miracles-of-the-namiya-general-store-1	111200.00	t
11	1	1	10	Pembunuhan di Rumah Miring (Murder in the Crooked House)	9786020638447	400	23 Mar 2020	https://www.gramedia.com/products/pembunuhan-di-rumah-miring-murder-in-the-crooked-house?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	78750.00	t
12	7	1	11	Layangan Putus	9786020729091	268	20 Feb 2010	https://www.gramedia.com/products/layangan-putus?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	67500.00	t
13	1	1	12	Kim Ji-Yeong Lahir Tahun 1982	9786020636191	192	11 Nov 2019	https://www.gramedia.com/products/kim-ji-yeong-lahir-tahun-1982?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=Best_Seller_Buku	48300.00	t
14	1	1	13	Heartbreak Motel	9786020658841	400	8 Apr 2022	https://www.gramedia.com/products/heartbreak-motel?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	69300.00	t
15	4	1	14	Seporsi Mie Ayam Sebelum Mati	9786020531328	216	20 Jan 2025	https://www.gramedia.com/products/seporsi-mie-ayam-sebelum-mati	74400.00	t
16	6	1	9	Laut Bercerita	9786024246945	400	21 Des 2017	https://www.gramedia.com/products/laut-bercerita	92000.00	t
17	1	1	15	Teka-Teki Gambar Aneh	9786020687209	312	2 Feb 2026	https://www.gramedia.com/products/tekateki-gambar-aneh	79200.00	t
18	2	1	16	Eccedentesiast	9786235953106	356	27 Apr 2022	https://www.gramedia.com/products/eccedentesiast?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	92650.00	t
19	1	1	17	Sang Alkemis (The Alchemist)	9786020656069	224	21 Agu 2021	https://www.gramedia.com/products/sang-alkemis-the-alchemist	55200.00	t
20	1	1	18	Funiculi Funicula (Kōhī Ga Samenai Uchi Ni---Before the Coffee Gets Cold)	9786020651927	224	21 Apr 2021	https://www.gramedia.com/products/funiculi-funicula-kohi-ga-samenai-uchi-ni-before-the-coffee-gets-cold	56000.00	t
21	1	1	19	Rich Dad Poor Dad	9786020333175	244	22 Agu 2016	https://www.gramedia.com/products/rich-dad-poor-dad-edisi-revisi	54400.00	t
22	1	1	18	Funiculi Funicula (Kōhī Ga Samenai Uchi Ni---Before the Coffee Gets Cold)	9786020651927	224	21 Apr 2021	https://www.gramedia.com/products/funiculi-funicula-kohi-ga-samenai-uchi-ni-before-the-coffee-gets-cold?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	56000.00	t
23	8	1	20	Sagaras	9786239726256	384	4 Mar 2022	https://www.gramedia.com/products/sagaras?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	98100.00	t
24	1	1	21	Home Sweet Loan	9786020658049	312	16 Feb 2022	https://www.gramedia.com/products/home-sweet-loan?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	74250.00	t
25	1	1	22	The Let Them Theory	N/A	328	10 Des 2025	https://www.gramedia.com/products/the-let-them-theory	95200.00	t
26	1	1	7	The Chronicles Of Narnia #1: The Magician`s Nephew (Keponakan Penyihir)	9786020336398	264	2 Jun 2022	https://www.gramedia.com/products/the-chronicles-of-narnia-1-the-magicians-nephew-keponakan-penyihir?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	69000.00	f
27	1	1	23	Educated (Terdidik): Sebuah Memoar	9786020650357	520	14 Apr 2021	https://www.gramedia.com/products/terdidik-educated-sebuah-memoar?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	96000.00	t
28	1	1	24	Understand-Inc People 2.0: Cara Menjadi Ambivert dengan Menavigasi 4 Tipe Kepribadian	9786020659107	160	17 Feb 2022	https://www.gramedia.com/products/understand-inc-people-20-cara-menjadi-ambivert-dengan-menavigasi-4-tipe-kepribadian	35100.00	t
29	1	1	25	Pasta Kacang Merah (An Sweet Bean Paste)	9786020665078	240	6 Okt 2022	https://www.gramedia.com/products/pasta-kacang-merah-an-sweet-bean-paste?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=BestSellerRekomendasi	66750.00	t
30	6	1	9	Laut Bercerita	9786024246945	400	21 Des 2017	https://www.gramedia.com/products/laut-bercerita?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=Best_Seller_Buku	92000.00	t
31	9	1	26	Almond	9786020519807	232	1 Apr 2019	https://www.gramedia.com/products/almond?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=Best_Seller_Buku	66000.00	t
32	10	1	27	Koloni Rajasa and the Flag Bearer	9786230314810	184	27 Okt 2024	https://www.gramedia.com/products/koloni-rajasa-and-the-flag-bearer	49000.00	f
33	11	1	28	Rondaman: Setan Kena Mental	9786347205148	143	2 Apr 2026	https://www.gramedia.com/products/rondaman-setan-kena-mental	88200.00	t
34	12	1	29	Bertahan	9786235235073	128	15 Mei 2025	https://www.gramedia.com/products/bertahan-1	67150.00	t
35	6	1	30	The Familiar: Sang Karib	9786231345936	504	25 Jun 2026	https://www.gramedia.com/products/the-familiar-sang-karib	140000.00	f
36	1	1	31	Omen - Komik	9786020673745	200	18 Feb 2026	https://www.gramedia.com/products/omen--komik	89000.00	f
37	10	1	32	Light Novel: The Apothecary Diaries Vol. 02 - Jinshi Sama, Premium Package	N/A	320	15 Jul 2026	https://www.gramedia.com/products/light-novel-the-apothecary-diaries-vol-02--jinshi-sama-premium-package	180000.00	f
38	10	1	32	Light Novel: The Apothecary Diaries Vol. 01 - Jishi Sama, Premium Package	N/A	308	9 Jan 2026	https://www.gramedia.com/products/light-novel-the-apothecary-diaries-vol-01--jishi-sama-premium-package	110500.00	t
39	13	1	33	Dedes Babak 2	N/A	376	11 Mei 2026	https://www.gramedia.com/products/dedes-babak-2	115000.00	f
40	14	1	34	Light Novel : Scarlet	9786347375575	256	8 Des 2025	https://www.gramedia.com/products/light-novel--scarlet	98000.00	f
41	10	1	35	Light Novel Mushoku Tensei – Jobless Reincarnation 05	9786347574190	332	5 Mar 2026	https://www.gramedia.com/products/light-novel-mushoku-tensei--jobless-reincarnation-05	115000.00	f
42	3	1	36	Soloist in a Cage 2	9786230077784	230	5 Mei 2026	https://www.gramedia.com/products/soloist-in-a-cage-2	38500.00	t
43	3	1	37	Bandits of Batavia	9786230078538	64	26 Jun 2026	https://www.gramedia.com/products/bandits-of-batavia	72000.00	f
44	15	1	38	Martin & Friends	N/A	172	10 Jun 2025	https://www.gramedia.com/products/martin--friends	80100.00	t
45	3	1	39	Yuyu Hakusho Premium 03	9786230078309	304	9 Jun 2026	https://www.gramedia.com/products/yuyu-hakusho-premium-03	85000.00	f
46	10	1	32	Light Novel: The Apothecary Diaries Vol. 02 - Maomao, Special Package	N/A	320	22 Jul 2026	https://www.gramedia.com/products/light-novel-the-apothecary-diaries-vol-02--maomao-special-package	118000.00	f
47	14	1	40	Light Novel: The Summer Hikaru Died 2 Special Set	N/A	226	22 Apr 2026	https://www.gramedia.com/products/light-novel-the-summer-hikaru-died-2-special-set	178000.00	f
48	14	1	41	Light Novel: Re:Zero - Starting Life in Another World - 22	9786347574282	352	12 Mei 2026	https://www.gramedia.com/products/light-novel-rezero--starting-life-in-another-world--22	98000.00	f
49	11	1	42	Muros	9786238956180	148	28 Agu 2025	https://www.gramedia.com/products/muros	76500.00	t
50	3	1	36	Soloist in a Cage 1	9786230074141	230	9 Jan 2026	https://www.gramedia.com/products/soloist-in-a-cage-1	38500.00	t
51	10	1	43	I Parry Everything #2	9786230319907	312	6 Mei 2026	https://www.gramedia.com/products/i-parry-everything-2	78000.00	t
52	6	1	44	Buddha 6: Ananda	9786231340535	368	15 Okt 2024	https://www.gramedia.com/products/buddha-6-ananda	82500.00	t
53	10	1	43	I "Parry" Everything #1	9786230318979	328	5 Jan 2026	https://www.gramedia.com/products/i-parry-everything-1	74750.00	t
54	6	1	29	Mice Cartoon - Telekomunikasi Mengubah Peradaban	9786231343857	152	19 Mei 2025	https://www.gramedia.com/products/mice-cartoon--telekomunikasi-mengubah-peradaban	90000.00	f
55	1	1	31	Johan Series#1: Obsesi	9786020686301	240	1 Des 2025	https://www.gramedia.com/products/johan-series1-obsesi	59250.00	t
56	10	1	45	Koloni : Gundala Vs Sancaka	9786230319792	72	15 Apr 2026	https://www.gramedia.com/products/koloni--gundala-vs-sancaka	44200.00	t
57	10	1	46	Koloni: We Are Pharmacists 2	9786230320439	120	25 Jun 2026	https://www.gramedia.com/products/koloni-we-are-pharmacists-2	72000.00	f
58	3	1	47	Ichi the Witch 02	9786230074677	200	15 Jan 2026	https://www.gramedia.com/products/ichi-the-witch-02	31500.00	t
59	3	1	48	Komik Ga Jelas Vol. 03 - Edisi Revisi	9786020485515	160	1 Jul 2025	https://www.gramedia.com/products/komik-ga-jelas-vol-03--edisi-revisi	58500.00	t
60	1	1	49	Halte Alam Baka	9786020682389	280	18 Feb 2026	https://www.gramedia.com/products/halte-alam-baka-1	89000.00	f
61	14	1	50	Light Novel The Eminence in Shadow 5	9786347375780	322	9 Jan 2026	https://www.gramedia.com/products/light-novel-the-eminence-in-shadow-5	115000.00	f
62	12	1	29	Berupaya	9786235235097	120	15 Mei 2025	https://www.gramedia.com/products/berupaya	67150.00	t
63	16	1	51	Panji Tengkorak	9786238728169	200	2 Sep 2025	https://www.gramedia.com/products/panji-tengkorak	89000.00	f
64	14	1	52	Light Novel: Who Killed The Brave? Chapter of Prophecy	9786347574244	248	30 Apr 2026	https://www.gramedia.com/products/light-novel-who-killed-the-brave-chapter-of-prophecy	108000.00	f
65	10	1	32	Light Novel: The Apothecary Diaries Vol. 01 - Maomao, Special Package	9786230318948	308	8 Jan 2026	https://www.gramedia.com/products/light-novel-the-apothecary-diaries-vol-01--maomao-special-package	81000.00	t
66	14	1	41	Light Novel: Re:Zero - Starting Life in Another World - 21	9786347375933	360	23 Feb 2026	https://www.gramedia.com/products/light-novel-rezero--starting-life-in-another-world--21	98000.00	f
67	10	1	53	Koloni: Anay-Nay 2 - Tamat	9786230320453	128	25 Jun 2026	https://www.gramedia.com/products/koloni-anaynay-2--tamat	68000.00	f
68	10	1	54	Akasha : The Grand Study of Ito Junji (Bundling Lanyard)	9786230316692	340	20 Jan 2026	https://www.gramedia.com/products/akasha--the-grand-study-of-ito-junji-bundling-lanyard	115500.00	t
69	14	1	40	Light Novel: The Summer Hikaru Died 2	9786347574497	226	18 Mei 2026	https://www.gramedia.com/products/light-novel-the-summer-hikaru-died-2-1	98000.00	f
70	17	1	55	Murder at Shijinso (New Cover)	9786235467474	412	8 Jul 2026	https://www.gramedia.com/products/murder-at-shijinso-new-cover	129000.00	f
71	14	1	50	Light Novel The Eminence in Shadow 6	9786347574831	306	2 Jul 2026	https://www.gramedia.com/products/light-novel-the-eminence-in-shadow-6	115000.00	f
72	18	1	56	Sandi Nusantara 2	9786027829800	204	21 Mar 2024	https://www.gramedia.com/products/sandi-nusantara-2	78300.00	t
73	16	1	57	My Stupid Boss Vol. 1	9786238728077	172	10 Jan 2025	https://www.gramedia.com/products/my-stupid-boss-vol-1	84000.00	f
74	3	1	47	Ichi the Witch 03	9786230077500	200	8 Apr 2026	https://www.gramedia.com/products/ichi-the-witch-03	33750.00	t
75	3	1	58	Bundling Komik 4 - CS1	N/A	\N	13 Mei 2026	https://www.gramedia.com/products/bundling-komik-4--cs1	30000.00	f
76	3	1	48	Komik Ga Jelas Vol. 02 - Edisi Revisi	9786020454474	160	7 Mei 2025	https://www.gramedia.com/products/komik-ga-jelas-vol-02--edisi-revisi	78000.00	f
77	13	1	59	Privately	9786347031525	396	6 Jul 2026	https://www.gramedia.com/products/privately	119000.00	f
78	13	1	33	Dedes	N/A	420	6 Jan 2026	https://www.gramedia.com/products/dedes	97750.00	t
79	3	1	60	Detektif Conan the Movie: The Bride of Halloween 01	9786230073298	200	31 Okt 2025	https://www.gramedia.com/products/detektif-conan-the-movie-the-bride-of-halloween-01	33750.00	t
80	18	1	56	Sandi Nusantara 3	9786027829862	206	23 Jul 2025	https://www.gramedia.com/products/sandi-nusantara-3	78300.00	t
81	16	1	61	Sepotong Kisah di Balik 98 : Cerita Pilihan Luluk HF	9786026714893	450	16 Feb 2024	https://www.gramedia.com/products/sepotong-kisah-di-balik-98-cerita-pilihan-luluk-hf	98100.00	t
82	1	1	62	Ensiklopedia 4D: Tubuh Manusia	9786020629544	88	6 Apr 2020	https://www.gramedia.com/products/ensiklopedia-4d-tubuh-manusia?utm_source=bestseller&utm_medium=bestsellerbuku&utm_campaign=seo&utm_content=Best_Seller_Buku	65600.00	t
\.


--
-- Data for Name: cart; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cart (cart_id, account_email) FROM stdin;
\.


--
-- Data for Name: cart_item; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cart_item (cart_item_id, cart_id, book_id, quantity) FROM stdin;
\.


--
-- Data for Name: catalog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.catalog (catalog_id, catalog_name) FROM stdin;
1	Novel Fiksi Terfavorit
2	Komik Terfavorit
3	Buku Anak Terfavorit
\.


--
-- Data for Name: format; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.format (format_id, format_name) FROM stdin;
1	Soft Cover
2	Hard Cover
\.


--
-- Data for Name: order_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_details (order_detail_id, order_id, book_id, quantity, harga_saat_dibeli) FROM stdin;
\.


--
-- Data for Name: pembayaran; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pembayaran (pembayaran_id, metode_pembayaran) FROM stdin;
\.


--
-- Data for Name: pengiriman; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pengiriman (pengiriman_id, nama_jasa) FROM stdin;
\.


--
-- Data for Name: publishers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.publishers (publisher_id, publisher_name) FROM stdin;
1	Gramedia Pustaka Utama
2	Kawah Media
3	Elex Media Komputindo
4	Gramedia Widiasarana Indonesia
5	Bentang Pustaka
6	Kepustakaan Populer Gramedia
7	Rdm Publishers
8	Sabak Grip Nusantara
9	Nan Giho
10	Unknown Publisher
11	Andam
12	Penerbit Buku Kompas
13	Akad
14	Phoenix Gramedia Indonesia
15	Bumi Aksara
16	Falcon Publishing
17	Haru
18	Expose Publika
\.


--
-- Name: Order_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Order_order_id_seq"', 1, false);


--
-- Name: address_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.address_address_id_seq', 1, false);


--
-- Name: author_author_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.author_author_id_seq', 62, true);


--
-- Name: cart_cart_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cart_cart_id_seq', 1, false);


--
-- Name: cart_item_cart_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cart_item_cart_item_id_seq', 1, false);


--
-- Name: catalog_catalog_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.catalog_catalog_id_seq', 3, true);


--
-- Name: format_format_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.format_format_id_seq', 2, true);


--
-- Name: order_details_order_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_details_order_detail_id_seq', 1, false);


--
-- Name: pembayaran_pembayaran_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pembayaran_pembayaran_id_seq', 1, false);


--
-- Name: pengiriman_pengiriman_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pengiriman_pengiriman_id_seq', 1, false);


--
-- Name: publishers_publisher_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.publishers_publisher_id_seq', 18, true);


--
-- Name: Order Order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_pkey" PRIMARY KEY (order_id);


--
-- Name: account account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_pkey PRIMARY KEY (account_email);


--
-- Name: address address_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (address_id);


--
-- Name: author author_author_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_author_name_key UNIQUE (author_name);


--
-- Name: author author_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_pkey PRIMARY KEY (author_id);


--
-- Name: book_catalog book_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_catalog
    ADD CONSTRAINT book_catalog_pkey PRIMARY KEY (book_id, catalog_id);


--
-- Name: books books_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (book_id);


--
-- Name: cart_item cart_item_cart_id_book_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_item
    ADD CONSTRAINT cart_item_cart_id_book_id_key UNIQUE (cart_id, book_id);


--
-- Name: cart_item cart_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_item
    ADD CONSTRAINT cart_item_pkey PRIMARY KEY (cart_item_id);


--
-- Name: cart cart_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart
    ADD CONSTRAINT cart_pkey PRIMARY KEY (cart_id);


--
-- Name: catalog catalog_catalog_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.catalog
    ADD CONSTRAINT catalog_catalog_name_key UNIQUE (catalog_name);


--
-- Name: catalog catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.catalog
    ADD CONSTRAINT catalog_pkey PRIMARY KEY (catalog_id);


--
-- Name: format format_format_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.format
    ADD CONSTRAINT format_format_name_key UNIQUE (format_name);


--
-- Name: format format_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.format
    ADD CONSTRAINT format_pkey PRIMARY KEY (format_id);


--
-- Name: order_details order_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_details
    ADD CONSTRAINT order_details_pkey PRIMARY KEY (order_detail_id);


--
-- Name: pembayaran pembayaran_metode_pembayaran_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pembayaran
    ADD CONSTRAINT pembayaran_metode_pembayaran_key UNIQUE (metode_pembayaran);


--
-- Name: pembayaran pembayaran_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pembayaran
    ADD CONSTRAINT pembayaran_pkey PRIMARY KEY (pembayaran_id);


--
-- Name: pengiriman pengiriman_nama_jasa_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pengiriman
    ADD CONSTRAINT pengiriman_nama_jasa_key UNIQUE (nama_jasa);


--
-- Name: pengiriman pengiriman_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pengiriman
    ADD CONSTRAINT pengiriman_pkey PRIMARY KEY (pengiriman_id);


--
-- Name: publishers publishers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT publishers_pkey PRIMARY KEY (publisher_id);


--
-- Name: publishers publishers_publisher_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT publishers_publisher_name_key UNIQUE (publisher_name);


--
-- Name: idx_books_author; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_books_author ON public.books USING btree (author_id);


--
-- Name: idx_books_publisher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_books_publisher ON public.books USING btree (publisher_id);


--
-- Name: idx_cartitem_cart; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cartitem_cart ON public.cart_item USING btree (cart_id);


--
-- Name: idx_orderdetails_book; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orderdetails_book ON public.order_details USING btree (book_id);


--
-- Name: idx_orderdetails_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orderdetails_order ON public.order_details USING btree (order_id);


--
-- Name: order_details trg_update_order_total; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_order_total AFTER INSERT OR DELETE OR UPDATE ON public.order_details FOR EACH ROW EXECUTE FUNCTION public.fn_update_order_total();


--
-- Name: Order Order_account_email_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_account_email_fkey" FOREIGN KEY (account_email) REFERENCES public.account(account_email);


--
-- Name: Order Order_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_address_id_fkey" FOREIGN KEY (address_id) REFERENCES public.address(address_id);


--
-- Name: Order Order_pembayaran_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_pembayaran_id_fkey" FOREIGN KEY (pembayaran_id) REFERENCES public.pembayaran(pembayaran_id);


--
-- Name: Order Order_pengiriman_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Order"
    ADD CONSTRAINT "Order_pengiriman_id_fkey" FOREIGN KEY (pengiriman_id) REFERENCES public.pengiriman(pengiriman_id);


--
-- Name: address address_account_email_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_account_email_fkey FOREIGN KEY (account_email) REFERENCES public.account(account_email) ON DELETE CASCADE;


--
-- Name: book_catalog book_catalog_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_catalog
    ADD CONSTRAINT book_catalog_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(book_id) ON DELETE CASCADE;


--
-- Name: book_catalog book_catalog_catalog_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book_catalog
    ADD CONSTRAINT book_catalog_catalog_id_fkey FOREIGN KEY (catalog_id) REFERENCES public.catalog(catalog_id) ON DELETE CASCADE;


--
-- Name: books books_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.author(author_id);


--
-- Name: books books_format_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_format_id_fkey FOREIGN KEY (format_id) REFERENCES public.format(format_id);


--
-- Name: books books_publisher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_publisher_id_fkey FOREIGN KEY (publisher_id) REFERENCES public.publishers(publisher_id);


--
-- Name: cart cart_account_email_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart
    ADD CONSTRAINT cart_account_email_fkey FOREIGN KEY (account_email) REFERENCES public.account(account_email) ON DELETE CASCADE;


--
-- Name: cart_item cart_item_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_item
    ADD CONSTRAINT cart_item_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(book_id);


--
-- Name: cart_item cart_item_cart_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_item
    ADD CONSTRAINT cart_item_cart_id_fkey FOREIGN KEY (cart_id) REFERENCES public.cart(cart_id) ON DELETE CASCADE;


--
-- Name: order_details order_details_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_details
    ADD CONSTRAINT order_details_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(book_id);


--
-- Name: order_details order_details_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_details
    ADD CONSTRAINT order_details_order_id_fkey FOREIGN KEY (order_id) REFERENCES public."Order"(order_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict GG5QS1MjvKFEOoheGN0kBa1j00GwHc6u2u4tjfOTE8cKjyvPqoGu3XulITzs82E

