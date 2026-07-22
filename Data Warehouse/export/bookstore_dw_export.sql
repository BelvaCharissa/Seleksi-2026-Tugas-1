--
-- PostgreSQL database dump
--

\restrict Jw1LO6ecRVVPPJvZ5aC18QNi0XZIistOJpKKFPBCfT0zUERfokAuwqbiDtGH9nf

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bridge_book_catalog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bridge_book_catalog (
    book_id integer NOT NULL,
    catalog_id integer NOT NULL
);


ALTER TABLE public.bridge_book_catalog OWNER TO postgres;

--
-- Name: dim_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_account (
    account_email character varying(255) NOT NULL,
    nama_penerima character varying(255),
    no_telp character varying(20)
);


ALTER TABLE public.dim_account OWNER TO postgres;

--
-- Name: dim_address; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_address (
    address_id integer NOT NULL,
    label_alamat character varying(100),
    provinsi character varying(100),
    kota character varying(100),
    kecamatan character varying(100),
    alamat_lengkap text
);


ALTER TABLE public.dim_address OWNER TO postgres;

--
-- Name: dim_books; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_books (
    book_id integer NOT NULL,
    title character varying(500) NOT NULL,
    isbn character varying(20),
    num_pages integer,
    publish_date character varying(50),
    is_discount boolean,
    price numeric(12,2),
    author_name character varying(255),
    publisher_name character varying(255),
    format_name character varying(100)
);


ALTER TABLE public.dim_books OWNER TO postgres;

--
-- Name: dim_catalog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_catalog (
    catalog_id integer NOT NULL,
    catalog_name character varying(255)
);


ALTER TABLE public.dim_catalog OWNER TO postgres;

--
-- Name: dim_payment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_payment (
    pembayaran_id integer NOT NULL,
    metode_pembayaran character varying(100)
);


ALTER TABLE public.dim_payment OWNER TO postgres;

--
-- Name: dim_shipping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_shipping (
    pengiriman_id integer NOT NULL,
    nama_jasa character varying(100)
);


ALTER TABLE public.dim_shipping OWNER TO postgres;

--
-- Name: etl_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.etl_log (
    etl_log_id integer NOT NULL,
    run_started_at timestamp without time zone DEFAULT now() NOT NULL,
    run_finished_at timestamp without time zone,
    rows_books integer,
    rows_catalog integer,
    rows_bridge integer,
    rows_fact integer,
    status character varying(20)
);


ALTER TABLE public.etl_log OWNER TO postgres;

--
-- Name: etl_log_etl_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.etl_log_etl_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.etl_log_etl_log_id_seq OWNER TO postgres;

--
-- Name: etl_log_etl_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.etl_log_etl_log_id_seq OWNED BY public.etl_log.etl_log_id;


--
-- Name: fact_order_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fact_order_details (
    order_detail_id integer NOT NULL,
    account_email character varying(255),
    address_id integer,
    pembayaran_id integer,
    pengiriman_id integer,
    book_id integer,
    order_id integer,
    order_date date,
    quantity integer,
    harga_saat_dibeli numeric(12,2),
    subtotal numeric(12,2)
);


ALTER TABLE public.fact_order_details OWNER TO postgres;

--
-- Name: etl_log etl_log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.etl_log ALTER COLUMN etl_log_id SET DEFAULT nextval('public.etl_log_etl_log_id_seq'::regclass);


--
-- Data for Name: bridge_book_catalog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bridge_book_catalog (book_id, catalog_id) FROM stdin;
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
-- Data for Name: dim_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_account (account_email, nama_penerima, no_telp) FROM stdin;
\.


--
-- Data for Name: dim_address; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_address (address_id, label_alamat, provinsi, kota, kecamatan, alamat_lengkap) FROM stdin;
\.


--
-- Data for Name: dim_books; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_books (book_id, title, isbn, num_pages, publish_date, is_discount, price, author_name, publisher_name, format_name) FROM stdin;
1	Perpustakaan Tengah Malam (The Midnight Library)	9786020649320	368	10 Jun 2021	t	84000.00	Matt Haig	Gramedia Pustaka Utama	Soft Cover
2	Shaka Oh Shaka	9786235953014	268	31 Jan 2022	t	84150.00	Jocelyn Suherman	Kawah Media	Soft Cover
3	Black Showman Dan Pembunuhan Di Kota Tak Bernama	9786020657691	516	22 Des 2021	t	101250.00	Keigo Higashino	Gramedia Pustaka Utama	Soft Cover
4	Wingit	9786230021831	256	16 Des 2020	t	75000.00	Sara Wijayanto	Elex Media Komputindo	Soft Cover
5	Melangkah	9786020523316	368	23 Mar 2020	t	74250.00	J.S. Khairen	Gramedia Widiasarana Indonesia	Soft Cover
6	Brianna dan Bottomwise	9786022919421	380	5 Agu 2022	t	103500.00	Andrea Hirata	Bentang Pustaka	Soft Cover
7	The Chronicles of Narnia #3: The Horse & His Boy (Kuda dan Anak Manusia)	9786020336411	312	2 Jun 2022	t	20700.00	C. S. Lewis	Gramedia Pustaka Utama	Soft Cover
8	Atomic Habits: Perubahan Kecil yang Memberikan Hasil Luar Biasa	9786020633176	352	16 Sep 2019	t	86400.00	James Clear	Gramedia Pustaka Utama	Soft Cover
9	Laut Bercerita	9786024818722	400	3 Agu 2022	t	152000.00	Leila S. Chudori	Kepustakaan Populer Gramedia	Soft Cover
10	Keajaiban Toko Kelontong Namiya	9786020648293	400	16 Des 2020	t	111200.00	Keigo Higashino	Gramedia Pustaka Utama	Soft Cover
11	Pembunuhan di Rumah Miring (Murder in the Crooked House)	9786020638447	400	23 Mar 2020	t	78750.00	Soji Shimada	Gramedia Pustaka Utama	Soft Cover
12	Layangan Putus	9786020729091	268	20 Feb 2010	t	67500.00	MOMMY ASF	Rdm Publishers	Soft Cover
13	Kim Ji-Yeong Lahir Tahun 1982	9786020636191	192	11 Nov 2019	t	48300.00	Cho Nam-Joo	Gramedia Pustaka Utama	Soft Cover
14	Heartbreak Motel	9786020658841	400	8 Apr 2022	t	69300.00	Ika Natassa	Gramedia Pustaka Utama	Soft Cover
15	Seporsi Mie Ayam Sebelum Mati	9786020531328	216	20 Jan 2025	t	74400.00	Brian Khrisna	Gramedia Widiasarana Indonesia	Soft Cover
16	Laut Bercerita	9786024246945	400	21 Des 2017	t	92000.00	Leila S. Chudori	Kepustakaan Populer Gramedia	Soft Cover
17	Teka-Teki Gambar Aneh	9786020687209	312	2 Feb 2026	t	79200.00	Uketsu	Gramedia Pustaka Utama	Soft Cover
18	Eccedentesiast	9786235953106	356	27 Apr 2022	t	92650.00	Ita krn	Kawah Media	Soft Cover
19	Sang Alkemis (The Alchemist)	9786020656069	224	21 Agu 2021	t	55200.00	Paulo Coelho	Gramedia Pustaka Utama	Soft Cover
20	Funiculi Funicula (Kōhī Ga Samenai Uchi Ni---Before the Coffee Gets Cold)	9786020651927	224	21 Apr 2021	t	56000.00	Toshikazu Kawaguchi	Gramedia Pustaka Utama	Soft Cover
21	Rich Dad Poor Dad	9786020333175	244	22 Agu 2016	t	54400.00	Robert T. Kiyosaki	Gramedia Pustaka Utama	Soft Cover
22	Funiculi Funicula (Kōhī Ga Samenai Uchi Ni---Before the Coffee Gets Cold)	9786020651927	224	21 Apr 2021	t	56000.00	Toshikazu Kawaguchi	Gramedia Pustaka Utama	Soft Cover
23	Sagaras	9786239726256	384	4 Mar 2022	t	98100.00	Tere Liye	Sabak Grip Nusantara	Soft Cover
24	Home Sweet Loan	9786020658049	312	16 Feb 2022	t	74250.00	Almira Bastari	Gramedia Pustaka Utama	Soft Cover
25	The Let Them Theory	N/A	328	10 Des 2025	t	95200.00	Mel Robbins	Gramedia Pustaka Utama	Soft Cover
26	The Chronicles Of Narnia #1: The Magician`s Nephew (Keponakan Penyihir)	9786020336398	264	2 Jun 2022	f	69000.00	C. S. Lewis	Gramedia Pustaka Utama	Soft Cover
27	Educated (Terdidik): Sebuah Memoar	9786020650357	520	14 Apr 2021	t	96000.00	TARA WESTOVER	Gramedia Pustaka Utama	Soft Cover
28	Understand-Inc People 2.0: Cara Menjadi Ambivert dengan Menavigasi 4 Tipe Kepribadian	9786020659107	160	17 Feb 2022	t	35100.00	Erwin Parengkuan	Gramedia Pustaka Utama	Soft Cover
29	Pasta Kacang Merah (An Sweet Bean Paste)	9786020665078	240	6 Okt 2022	t	66750.00	Durian Sukegawa	Gramedia Pustaka Utama	Soft Cover
30	Laut Bercerita	9786024246945	400	21 Des 2017	t	92000.00	Leila S. Chudori	Kepustakaan Populer Gramedia	Soft Cover
31	Almond	9786020519807	232	1 Apr 2019	t	66000.00	Sohn Won - Pyung	Nan Giho	Soft Cover
32	Koloni Rajasa and the Flag Bearer	9786230314810	184	27 Okt 2024	f	49000.00	Akhmad Fadly	Unknown Publisher	Soft Cover
33	Rondaman: Setan Kena Mental	9786347205148	143	2 Apr 2026	t	88200.00	Bagus R. Nugraha	Andam	Soft Cover
34	Bertahan	9786235235073	128	15 Mei 2025	t	67150.00	Muhammad Mice Misrad	Penerbit Buku Kompas	Soft Cover
35	The Familiar: Sang Karib	9786231345936	504	25 Jun 2026	f	140000.00	Leigh Bardugo	Kepustakaan Populer Gramedia	Soft Cover
36	Omen - Komik	9786020673745	200	18 Feb 2026	f	89000.00	Lexie Xu	Gramedia Pustaka Utama	Soft Cover
37	Light Novel: The Apothecary Diaries Vol. 02 - Jinshi Sama, Premium Package	N/A	320	15 Jul 2026	f	180000.00	Hyuganatsu / Touko Shino	Unknown Publisher	Soft Cover
38	Light Novel: The Apothecary Diaries Vol. 01 - Jishi Sama, Premium Package	N/A	308	9 Jan 2026	t	110500.00	Hyuganatsu / Touko Shino	Unknown Publisher	Soft Cover
39	Dedes Babak 2	N/A	376	11 Mei 2026	f	115000.00	Egestigi	Akad	Soft Cover
40	Light Novel : Scarlet	9786347375575	256	8 Des 2025	f	98000.00	MAMORU HOSODA	Phoenix Gramedia Indonesia	Soft Cover
41	Light Novel Mushoku Tensei – Jobless Reincarnation 05	9786347574190	332	5 Mar 2026	f	115000.00	Rifujin Na Magonote	Unknown Publisher	Soft Cover
42	Soloist in a Cage 2	9786230077784	230	5 Mei 2026	t	38500.00	Shiro Moriya	Elex Media Komputindo	Soft Cover
43	Bandits of Batavia	9786230078538	64	26 Jun 2026	f	72000.00	Bryan Valenza	Elex Media Komputindo	Soft Cover
44	Martin & Friends	N/A	172	10 Jun 2025	t	80100.00	Vernando Altamirano	Bumi Aksara	Soft Cover
45	Yuyu Hakusho Premium 03	9786230078309	304	9 Jun 2026	f	85000.00	Yoshihiro Togashi	Elex Media Komputindo	Soft Cover
46	Light Novel: The Apothecary Diaries Vol. 02 - Maomao, Special Package	N/A	320	22 Jul 2026	f	118000.00	Hyuganatsu / Touko Shino	Unknown Publisher	Soft Cover
47	Light Novel: The Summer Hikaru Died 2 Special Set	N/A	226	22 Apr 2026	f	178000.00	Mio Nukaga	Phoenix Gramedia Indonesia	Soft Cover
48	Light Novel: Re:Zero - Starting Life in Another World - 22	9786347574282	352	12 Mei 2026	f	98000.00	Tappei Nagatsuki	Phoenix Gramedia Indonesia	Soft Cover
49	Muros	9786238956180	148	28 Agu 2025	t	76500.00	Surya Putra	Andam	Soft Cover
50	Soloist in a Cage 1	9786230074141	230	9 Jan 2026	t	38500.00	Shiro Moriya	Elex Media Komputindo	Soft Cover
51	I Parry Everything #2	9786230319907	312	6 Mei 2026	t	78000.00	Nabeshiki	Unknown Publisher	Soft Cover
52	Buddha 6: Ananda	9786231340535	368	15 Okt 2024	t	82500.00	Osamu Tezuka	Kepustakaan Populer Gramedia	Soft Cover
53	I "Parry" Everything #1	9786230318979	328	5 Jan 2026	t	74750.00	Nabeshiki	Unknown Publisher	Soft Cover
54	Mice Cartoon - Telekomunikasi Mengubah Peradaban	9786231343857	152	19 Mei 2025	f	90000.00	Muhammad Mice Misrad	Kepustakaan Populer Gramedia	Soft Cover
55	Johan Series#1: Obsesi	9786020686301	240	1 Des 2025	t	59250.00	Lexie Xu	Gramedia Pustaka Utama	Soft Cover
56	Koloni : Gundala Vs Sancaka	9786230319792	72	15 Apr 2026	t	44200.00	Bumilangit Comics	Unknown Publisher	Soft Cover
57	Koloni: We Are Pharmacists 2	9786230320439	120	25 Jun 2026	f	72000.00	Qoni	Unknown Publisher	Soft Cover
58	Ichi the Witch 02	9786230074677	200	15 Jan 2026	t	31500.00	Osamu Nishi, Shiro Usazaki	Elex Media Komputindo	Soft Cover
59	Komik Ga Jelas Vol. 03 - Edisi Revisi	9786020485515	160	1 Jul 2025	t	58500.00	Jasmine H. Surkatty	Elex Media Komputindo	Soft Cover
60	Halte Alam Baka	9786020682389	280	18 Feb 2026	f	89000.00	Kai Elian	Gramedia Pustaka Utama	Soft Cover
61	Light Novel The Eminence in Shadow 5	9786347375780	322	9 Jan 2026	f	115000.00	Daisuke Aizawa	Phoenix Gramedia Indonesia	Soft Cover
62	Berupaya	9786235235097	120	15 Mei 2025	t	67150.00	Muhammad Mice Misrad	Penerbit Buku Kompas	Soft Cover
63	Panji Tengkorak	9786238728169	200	2 Sep 2025	f	89000.00	Hans Jaladara	Falcon Publishing	Soft Cover
64	Light Novel: Who Killed The Brave? Chapter of Prophecy	9786347574244	248	30 Apr 2026	f	108000.00	Daken	Phoenix Gramedia Indonesia	Soft Cover
65	Light Novel: The Apothecary Diaries Vol. 01 - Maomao, Special Package	9786230318948	308	8 Jan 2026	t	81000.00	Hyuganatsu / Touko Shino	Unknown Publisher	Soft Cover
66	Light Novel: Re:Zero - Starting Life in Another World - 21	9786347375933	360	23 Feb 2026	f	98000.00	Tappei Nagatsuki	Phoenix Gramedia Indonesia	Soft Cover
67	Koloni: Anay-Nay 2 - Tamat	9786230320453	128	25 Jun 2026	f	68000.00	Olvyanda Ariesta	Unknown Publisher	Soft Cover
68	Akasha : The Grand Study of Ito Junji (Bundling Lanyard)	9786230316692	340	20 Jan 2026	t	115500.00	Ito Junji	Unknown Publisher	Soft Cover
69	Light Novel: The Summer Hikaru Died 2	9786347574497	226	18 Mei 2026	f	98000.00	Mio Nukaga	Phoenix Gramedia Indonesia	Soft Cover
70	Murder at Shijinso (New Cover)	9786235467474	412	8 Jul 2026	f	129000.00	Imamura Masahiro	Haru	Soft Cover
71	Light Novel The Eminence in Shadow 6	9786347574831	306	2 Jul 2026	f	115000.00	Daisuke Aizawa	Phoenix Gramedia Indonesia	Soft Cover
72	Sandi Nusantara 2	9786027829800	204	21 Mar 2024	t	78300.00	Hokky Situngkir	Expose Publika	Soft Cover
73	My Stupid Boss Vol. 1	9786238728077	172	10 Jan 2025	f	84000.00	Tim Kumata	Falcon Publishing	Soft Cover
74	Ichi the Witch 03	9786230077500	200	8 Apr 2026	t	33750.00	Osamu Nishi, Shiro Usazaki	Elex Media Komputindo	Soft Cover
75	Bundling Komik 4 - CS1	N/A	\N	13 Mei 2026	f	30000.00	Yoshito Usui & Uy Studio	Elex Media Komputindo	Soft Cover
76	Komik Ga Jelas Vol. 02 - Edisi Revisi	9786020454474	160	7 Mei 2025	f	78000.00	Jasmine H. Surkatty	Elex Media Komputindo	Soft Cover
77	Privately	9786347031525	396	6 Jul 2026	f	119000.00	Omenilno	Akad	Soft Cover
78	Dedes	N/A	420	6 Jan 2026	t	97750.00	Egestigi	Akad	Soft Cover
79	Detektif Conan the Movie: The Bride of Halloween 01	9786230073298	200	31 Okt 2025	t	33750.00	Aoyama Gosho	Elex Media Komputindo	Soft Cover
80	Sandi Nusantara 3	9786027829862	206	23 Jul 2025	t	78300.00	Hokky Situngkir	Expose Publika	Soft Cover
81	Sepotong Kisah di Balik 98 : Cerita Pilihan Luluk HF	9786026714893	450	16 Feb 2024	t	98100.00	Lukita lova, M. Gani Dhafin R. Yulistiana Prasetya & Tary Lestari, Foggy FF	Falcon Publishing	Soft Cover
82	Ensiklopedia 4D: Tubuh Manusia	9786020629544	88	6 Apr 2020	t	65600.00	Devar Entertainment	Gramedia Pustaka Utama	Soft Cover
\.


--
-- Data for Name: dim_catalog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_catalog (catalog_id, catalog_name) FROM stdin;
1	Novel Fiksi Terfavorit
2	Komik Terfavorit
3	Buku Anak Terfavorit
\.


--
-- Data for Name: dim_payment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_payment (pembayaran_id, metode_pembayaran) FROM stdin;
\.


--
-- Data for Name: dim_shipping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_shipping (pengiriman_id, nama_jasa) FROM stdin;
\.


--
-- Data for Name: etl_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.etl_log (etl_log_id, run_started_at, run_finished_at, rows_books, rows_catalog, rows_bridge, rows_fact, status) FROM stdin;
1	2026-07-22 11:51:47.598877	2026-07-22 11:51:47.744736	82	3	92	0	SUCCESS
\.


--
-- Data for Name: fact_order_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fact_order_details (order_detail_id, account_email, address_id, pembayaran_id, pengiriman_id, book_id, order_id, order_date, quantity, harga_saat_dibeli, subtotal) FROM stdin;
\.


--
-- Name: etl_log_etl_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.etl_log_etl_log_id_seq', 1, true);


--
-- Name: bridge_book_catalog bridge_book_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bridge_book_catalog
    ADD CONSTRAINT bridge_book_catalog_pkey PRIMARY KEY (book_id, catalog_id);


--
-- Name: dim_account dim_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_account
    ADD CONSTRAINT dim_account_pkey PRIMARY KEY (account_email);


--
-- Name: dim_address dim_address_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_address
    ADD CONSTRAINT dim_address_pkey PRIMARY KEY (address_id);


--
-- Name: dim_books dim_books_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_books
    ADD CONSTRAINT dim_books_pkey PRIMARY KEY (book_id);


--
-- Name: dim_catalog dim_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_catalog
    ADD CONSTRAINT dim_catalog_pkey PRIMARY KEY (catalog_id);


--
-- Name: dim_payment dim_payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_payment
    ADD CONSTRAINT dim_payment_pkey PRIMARY KEY (pembayaran_id);


--
-- Name: dim_shipping dim_shipping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_shipping
    ADD CONSTRAINT dim_shipping_pkey PRIMARY KEY (pengiriman_id);


--
-- Name: etl_log etl_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.etl_log
    ADD CONSTRAINT etl_log_pkey PRIMARY KEY (etl_log_id);


--
-- Name: fact_order_details fact_order_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_order_details
    ADD CONSTRAINT fact_order_details_pkey PRIMARY KEY (order_detail_id);


--
-- Name: idx_bridge_catalog; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bridge_catalog ON public.bridge_book_catalog USING btree (catalog_id);


--
-- Name: idx_fact_account; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fact_account ON public.fact_order_details USING btree (account_email);


--
-- Name: idx_fact_address; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fact_address ON public.fact_order_details USING btree (address_id);


--
-- Name: idx_fact_book; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fact_book ON public.fact_order_details USING btree (book_id);


--
-- Name: idx_fact_orderdate; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fact_orderdate ON public.fact_order_details USING btree (order_date);


--
-- Name: idx_fact_payment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fact_payment ON public.fact_order_details USING btree (pembayaran_id);


--
-- Name: idx_fact_shipping; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fact_shipping ON public.fact_order_details USING btree (pengiriman_id);


--
-- Name: bridge_book_catalog bridge_book_catalog_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bridge_book_catalog
    ADD CONSTRAINT bridge_book_catalog_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.dim_books(book_id) ON DELETE CASCADE;


--
-- Name: bridge_book_catalog bridge_book_catalog_catalog_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bridge_book_catalog
    ADD CONSTRAINT bridge_book_catalog_catalog_id_fkey FOREIGN KEY (catalog_id) REFERENCES public.dim_catalog(catalog_id) ON DELETE CASCADE;


--
-- Name: fact_order_details fact_order_details_account_email_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_order_details
    ADD CONSTRAINT fact_order_details_account_email_fkey FOREIGN KEY (account_email) REFERENCES public.dim_account(account_email);


--
-- Name: fact_order_details fact_order_details_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_order_details
    ADD CONSTRAINT fact_order_details_address_id_fkey FOREIGN KEY (address_id) REFERENCES public.dim_address(address_id);


--
-- Name: fact_order_details fact_order_details_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_order_details
    ADD CONSTRAINT fact_order_details_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.dim_books(book_id);


--
-- Name: fact_order_details fact_order_details_pembayaran_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_order_details
    ADD CONSTRAINT fact_order_details_pembayaran_id_fkey FOREIGN KEY (pembayaran_id) REFERENCES public.dim_payment(pembayaran_id);


--
-- Name: fact_order_details fact_order_details_pengiriman_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_order_details
    ADD CONSTRAINT fact_order_details_pengiriman_id_fkey FOREIGN KEY (pengiriman_id) REFERENCES public.dim_shipping(pengiriman_id);


--
-- PostgreSQL database dump complete
--

\unrestrict Jw1LO6ecRVVPPJvZ5aC18QNi0XZIistOJpKKFPBCfT0zUERfokAuwqbiDtGH9nf

