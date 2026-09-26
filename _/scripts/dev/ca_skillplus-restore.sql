--

--
-- PostgreSQL database dump
--


-- Dumped from database version 15.12-YB-2026.1.1.1-b0
-- Dumped by pg_dump version 16.15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ca_skillplus; Type: DATABASE; Schema: -; Owner: csa
--





SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
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
-- Name: a_announcement; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_announcement (
    id text DEFAULT 'default'::text NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.a_announcement OWNER TO csa;

--
-- Name: a_article; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_article (
    id text NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_archived boolean DEFAULT false NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.a_article OWNER TO csa;

--
-- Name: a_chat; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_chat (
    cid bigint NOT NULL,
    reservasi_id text DEFAULT ''::text NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.a_chat OWNER TO csa;

--
-- Name: a_chat_member; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_chat_member (
    cid bigint NOT NULL,
    uid bigint NOT NULL,
    role text DEFAULT 'member'::text NOT NULL
);


ALTER TABLE public.a_chat_member OWNER TO csa;

--
-- Name: a_chat_msg; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_chat_msg (
    cid bigint NOT NULL,
    msg_id bigint NOT NULL,
    uid bigint DEFAULT 0 NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    ts timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.a_chat_msg OWNER TO csa;

--
-- Name: a_config; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_config (
    k text NOT NULL,
    v jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.a_config OWNER TO csa;

--
-- Name: a_file; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_file (
    hash text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    s3_path text DEFAULT ''::text NOT NULL,
    mime text DEFAULT 'application/octet-stream'::text NOT NULL,
    size bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.a_file OWNER TO csa;

--
-- Name: a_file_bytes; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_file_bytes (
    hash text NOT NULL,
    bytes bytea NOT NULL
);


ALTER TABLE public.a_file_bytes OWNER TO csa;

--
-- Name: a_knowledge; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_knowledge (
    id text NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.a_knowledge OWNER TO csa;

--
-- Name: a_payment_account; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_payment_account (
    id text NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_archived boolean DEFAULT false NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.a_payment_account OWNER TO csa;

--
-- Name: a_product_category; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_product_category (
    id text NOT NULL,
    parent_id text DEFAULT ''::text NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_archived boolean DEFAULT false NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.a_product_category OWNER TO csa;

--
-- Name: a_product_tag; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_product_tag (
    id text NOT NULL,
    label text DEFAULT ''::text NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.a_product_tag OWNER TO csa;

--
-- Name: a_slide; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_slide (
    id text NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_archived boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.a_slide OWNER TO csa;

--
-- Name: a_user; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.a_user (
    uid bigint NOT NULL,
    alien_id text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    pic text DEFAULT ''::text NOT NULL,
    email text DEFAULT ''::text NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_banned boolean DEFAULT false NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.a_user OWNER TO csa;

--
-- Name: platform_app_version; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.platform_app_version (
    platform text NOT NULL,
    version integer NOT NULL,
    version_name text DEFAULT ''::text NOT NULL,
    min_version integer DEFAULT 0 NOT NULL,
    store_url text DEFAULT ''::text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.platform_app_version OWNER TO csa;

--
-- Name: s_jadwal; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.s_jadwal (
    id text NOT NULL,
    kursus_id text NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    geo_lat double precision,
    geo_lng double precision,
    is_archived boolean DEFAULT false NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.s_jadwal OWNER TO csa;

--
-- Name: s_kursus; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.s_kursus (
    id text NOT NULL,
    tutor_uid bigint DEFAULT 0 NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    desc_text text DEFAULT ''::text NOT NULL,
    can_reserve boolean DEFAULT true NOT NULL,
    is_archived boolean DEFAULT false NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    search tsvector,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    geo_lat double precision,
    geo_lng double precision,
    has_bookable_slots boolean DEFAULT false NOT NULL,
    next_bookable_at timestamp with time zone
);


ALTER TABLE public.s_kursus OWNER TO csa;

--
-- Name: s_reservasi; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.s_reservasi (
    id text NOT NULL,
    student_uid bigint DEFAULT 0 NOT NULL,
    tutor_uid bigint DEFAULT 0 NOT NULL,
    kursus_id text DEFAULT ''::text NOT NULL,
    state text DEFAULT 'draft'::text NOT NULL,
    total bigint DEFAULT 0 NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    ts timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.s_reservasi OWNER TO csa;

--
-- Name: s_reservasi_item; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.s_reservasi_item (
    reservasi_id text NOT NULL,
    item_id bigint NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    start_at timestamp with time zone NOT NULL,
    end_at timestamp with time zone NOT NULL,
    state text DEFAULT 'pending'::text NOT NULL,
    is_no_show boolean DEFAULT false NOT NULL,
    is_unavailable boolean DEFAULT false NOT NULL
);


ALTER TABLE public.s_reservasi_item OWNER TO csa;

--
-- Name: u_access; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.u_access (
    uid bigint NOT NULL,
    role text DEFAULT 'student'::text NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.u_access OWNER TO csa;

--
-- Name: u_asset_access; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.u_asset_access (
    uid bigint NOT NULL,
    asset_type text NOT NULL,
    asset_id text NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE public.u_asset_access OWNER TO csa;

--
-- Name: u_auth_google; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.u_auth_google (
    sub text NOT NULL,
    uid bigint NOT NULL,
    email text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    pic text DEFAULT ''::text NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.u_auth_google OWNER TO csa;

--
-- Name: u_auth_password; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.u_auth_password (
    uid bigint NOT NULL,
    salt bytea NOT NULL,
    hash bytea NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.u_auth_password OWNER TO csa;

--
-- Name: u_fcm; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.u_fcm (
    uid bigint NOT NULL,
    client_id text NOT NULL,
    token text NOT NULL,
    platform integer DEFAULT 0 NOT NULL,
    ts timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.u_fcm OWNER TO csa;

--
-- Name: u_notif_sent; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.u_notif_sent (
    dedup_key text NOT NULL,
    uid bigint NOT NULL,
    ts timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.u_notif_sent OWNER TO csa;

--
-- Name: u_review; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.u_review (
    id text NOT NULL,
    reviewer_uid bigint NOT NULL,
    asset_type text NOT NULL,
    asset_id text NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    ts timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.u_review OWNER TO csa;

--
-- Name: u_wallet; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.u_wallet (
    wid text NOT NULL,
    uid bigint NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    currency text DEFAULT 'IDR'::text NOT NULL,
    balance bigint DEFAULT 0 NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.u_wallet OWNER TO csa;

--
-- Name: u_wallet_hold; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.u_wallet_hold (
    ref_type text NOT NULL,
    ref_id text NOT NULL,
    wid text NOT NULL,
    uid bigint NOT NULL,
    amount bigint DEFAULT 0 NOT NULL,
    state text DEFAULT 'active'::text NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.u_wallet_hold OWNER TO csa;

--
-- Name: u_wallet_tx; Type: TABLE; Schema: public; Owner: csa
--

CREATE TABLE public.u_wallet_tx (
    id text NOT NULL,
    wid text NOT NULL,
    uid bigint NOT NULL,
    type text DEFAULT ''::text NOT NULL,
    state text DEFAULT 'pending'::text NOT NULL,
    amount bigint DEFAULT 0 NOT NULL,
    d jsonb DEFAULT '{}'::jsonb NOT NULL,
    ts timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.u_wallet_tx OWNER TO csa;

--
-- Data for Name: a_announcement; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_announcement (id, d, updated) FROM stdin;
\.


--
-- Data for Name: a_article; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_article (id, d, is_archived, updated) FROM stdin;
\.


--
-- Data for Name: a_chat; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_chat (cid, reservasi_id, d, updated) FROM stdin;
80995577151619264	01KZTXXPAJEMCYZPBGFHZK1KFZ	{"cid": "80995577151619264", "title": "Reservasi 01KZTXXPAJEMCYZPBGFHZK1KFZ"}	2026-08-12 12:07:30.419399+00
80930507046518784	01KZTF47ND80YEBS676JMXB9JS	{"cid": "80930507046518784", "title": "Reservasi 01KZTF47ND80YEBS676JMXB9JS"}	2026-08-12 07:48:58.376615+00
\.


--
-- Data for Name: a_chat_member; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_chat_member (cid, uid, role) FROM stdin;
80995577151619264	10000004	member
80995577151619264	10000005	member
80930507046518784	10000000	member
80930507046518784	10000004	member
\.


--
-- Data for Name: a_chat_msg; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_chat_msg (cid, msg_id, uid, d, ts) FROM stdin;
\.


--
-- Data for Name: a_config; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_config (k, v, updated) FROM stdin;
\.


--
-- Data for Name: a_file; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_file (hash, created_at, s3_path, mime, size) FROM stdin;
4e7b4296a17ae8ddc78118655679c370448649cc0bfc5850c876bdd76237056b	2026-08-12 07:35:06.262548+00	fs/4e7b4296a17ae8ddc78118655679c370448649cc0bfc5850c876bdd76237056b	image/jpeg	304677
ecf9b2a608d747daf5b4527f763a866985d9d871821737907234809328a65531	2026-08-13 02:50:28.66615+00	fs/ecf9b2a608d747daf5b4527f763a866985d9d871821737907234809328a65531	image/webp	21554
c53fa7168900c416b0bfde939312b8d2b0d531bd3aad667081375ac0f278e0a8	2026-08-09 05:10:39.1702+00	fs/c53fa7168900c416b0bfde939312b8d2b0d531bd3aad667081375ac0f278e0a8	image/webp	610434
23a52f6f2bf36920c22c108dbf974fd7ca6301192bed1fa7e948858ea24c1fc2	2026-08-13 02:45:27.05807+00		image/webp	1862
aa4a9dcac2bd5d1907579e323efd5d9b346792add62c456ea73f6c647d09b7a3	2026-08-13 02:47:55.641159+00		image/webp	4748
97e16bc3c9bdb420ab6a504149d5706d04fb3e6813524358cb087ffbc846951b	2026-08-12 06:25:44.047221+00	fs/97e16bc3c9bdb420ab6a504149d5706d04fb3e6813524358cb087ffbc846951b	image/png	167702
decbb3aea23819825a27639978c9c285c6da0844ce67cd5796344269e5ba0185	2026-08-13 02:38:55.497165+00	fs/decbb3aea23819825a27639978c9c285c6da0844ce67cd5796344269e5ba0185	image/webp	29604
c3f9e34d02f24097eb4f6683fc92201ec18a4d3edbf4017165d0d401527434ef	2026-08-13 02:40:29.594958+00		image/webp	1452
\.


--
-- Data for Name: a_file_bytes; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_file_bytes (hash, bytes) FROM stdin;
23a52f6f2bf36920c22c108dbf974fd7ca6301192bed1fa7e948858ea24c1fc2	\\x524946463e07000057454250565038580a000000200000006e00008d000049434350c8010000000001c800000000043000006d6e74725247422058595a2007e00001000100000000000061637370000000000000000000000000000000000000000000000000000000010000f6d6000100000000d32d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000964657363000000f0000000247258595a00000114000000146758595a00000128000000146258595a0000013c00000014777470740000015000000014725452430000016400000028675452430000016400000028625452430000016400000028637072740000018c0000003c6d6c756300000000000000010000000c656e5553000000080000001c007300520047004258595a200000000000006fa2000038f50000039058595a2000000000000062990000b785000018da58595a2000000000000024a000000f840000b6cf58595a20000000000000f6d6000100000000d32d706172610000000000040000000266660000f2a700000d59000013d000000a5b00000000000000006d6c756300000000000000010000000c656e5553000000200000001c0047006f006f0067006c006500200049006e0063002e002000320030003100365650382050050000301b009d012a6f008e003e612a9345a422a1969a7514400604b4800af47ebf3fbcf4717a69231f61bf77c26f002f56fdd0f03c000dd5b4934ccfc8f7d49ec1e6cf23434c9e1621c27dca867cde0eef32463fdb0fd3dad1bf9944a73f2483bdb35cd34b0b78d8d218d77e5667d5a7c0f073b6d870dfc49f50f52a4158b8ffc83c2940543e5226e38b5da5b48caa412145a23ebe6fd94562d487f4e6e7cf1826211adca8f894ff45f2dbf7553482a61666757ebbe09cf4f24ee2076800d96abd903505316cfd6176d91d954e5c3acb35a8f8ba521f10b5930252261b198d305125e56000fefcf40274647051c4f28efd033bb1cafbeec360dfb93d739d3b819b7bca8669e3add2961f824c9b658e23d75e41471c054cc3cf3fbd9af78bb6b02d11def79331917a4bd1139d8c3bc678ceba3f6557c8fd5d25cfef99d7dd12d6378c3ebda78a4b74f6ff24066d04421c07c6cc6bd2ef85ff2f3bb64b1b1324ef49eb58b0a0a8a1cd58b80c564e63c38fc3c8e9e8f3fab8d5ee21c1373ff7138cb231cd5b1bcd48dc705b019041ef1210d8679e293c46cde1946eae1b8eca93a177e769d33f8503598be95c78bc6fa77841962431784fc7069bf3b18fe2bb9c6cd41755087588d74c39b52e3efe701035c63f531474c4471c1a55b7ff6ffeff8a12d46606591ad420afe33f8505277b59da72310d7ec8de01a6d27481d92295fe14128707a2e024f5787bdc31b683da0d1fdb4f1eb3b0389a79316e21badbe3473a055e483c750ee14fd4cb8c1998c11e7469206ce92c1d361188770c8507306ddaec2defcb0b51b0eb8be1f4a17417e9e5d81fb3b61d9fcf2b8ad7836d4fcdb4740b2b736b2a16c00e2bf3922cbd2e7cbb6ec7e93d077ed3c953b739be0ba5117a8c447580cab506b130b06f9d130df8dee68d18fdd57d4559f8f6ce6d63cc2f749080aa64379d4e898d7fa3ec75ed1c0421d3977d9cb845bcd31cfff5ff30b249442ae4ecdc9d04f06833f6e48d93e0c446685df4fe5b831145f4499be1ab12b71aaf9c3992598f9c32623bae542885b81a5954a154b5d63a86eae7d064894122c3e0751f59f292fc56a4fce35fbd006294c5386eb39adcf15749b332159a993d5d35fd4d62f634a2be15f75b46e5b8d173f2d814ac1ed74373b80a23ba638e90e05296fac910751371269bac373f505ffb52849d584dcac8c9f0af93cdd0609fcbbe2b06211f1a94e6c96c6a49a2ce8b0ca1bbb55a60d1e9a3d7cb0f4db4182f775b6d7a2a9acc7b989fdef7e76dd59f1807140a39e800d4ca496b8e85beb4c969ca9417a22c7b4346e301b3613032c8a9d58b081c35730522c2c83617b852e1287e9e9ea4ef5c2effe2f18de05a9037db659ea499feb8ee483f3c0cfc11fddf4b09ac5f8e9966d332a7d1f9b2d4409de1ce82c619aa56d24a09a9a038f6bc2a82ab6b2a45eba38a8276e01f9875150bdf3cf22de251047a209c2c3e7ea20da235743763af89c05c68546ef698339873fa7e4b9b9c093ef9d4e2e46ff5062b8da775e792256b33187677f24cf4dcabed407533e7637426cf581c28bf538b65bfcdee865fd5cc7cd9147ed87735611ba22788bc94885dcb9275ba4fcd41453d55f4dde652a5ac6841039b59f669e0738bdab4d9f778553a5a20076be5756fe369f2a90d2316fe199144b34e0febd0051907d5649de006d81689676599b916fcb4945e89aac88836c8e17d8bee09d132e1b703aaf7a4a487261f37e60aecaffb076320d1857c28dbe48a49359589455973d14a463b5f7c699f821bb827ac86ee587101bbbf7ebf1332cc14f6a8ec811b9587c294d8107fcd08b2d56db9171f9c3d4711a340fe562f6281d31ecb3ee287a160223e491097e8f3dc1fd86efa115c468b1f5cc8eb5522260be0e093fa4e000000
aa4a9dcac2bd5d1907579e323efd5d9b346792add62c456ea73f6c647d09b7a3	\\x524946468412000057454250565038580a0000002000000067010067010049434350c8010000000001c800000000043000006d6e74725247422058595a2007e00001000100000000000061637370000000000000000000000000000000000000000000000000000000010000f6d6000100000000d32d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000964657363000000f0000000247258595a00000114000000146758595a00000128000000146258595a0000013c00000014777470740000015000000014725452430000016400000028675452430000016400000028625452430000016400000028637072740000018c0000003c6d6c756300000000000000010000000c656e5553000000080000001c007300520047004258595a200000000000006fa2000038f50000039058595a2000000000000062990000b785000018da58595a2000000000000024a000000f840000b6cf58595a20000000000000f6d6000100000000d32d706172610000000000040000000266660000f2a700000d59000013d000000a5b00000000000000006d6c756300000000000000010000000c656e5553000000200000001c0047006f006f0067006c006500200049006e0063002e0020003200300031003656503820961000003062009d012a680168013e612e9547a422222121d099d0800c09696efc70398eeb50cafd33feb1d997f56fe95fb67fdafdc7f139e43fcc7f60399cc49be29f5a3f3bfd77f73ff2d7ef97eefdf2f002fc4ff947f96fca1fccee341001f56bfceff66f170d477c0ffebfdc03f5a3fd47af3dea7e97ec01fce3fafffd7ff21f977f4d3fc5ffe0ff03fe9bd2ffe83fdfbff37f88f810fe6ffd9bfe67f74f6b4f613fba5ec89fb19ffe05f3e86100f007f70eccfa18403c01fdc3b33e86100f007e47abeb997f04c401212f185101b3c1c660811b75a559077fc65982709d483dd362f244e61629940340e9b366ba6e965254fc997dbedd62adc1bb36473417acae133bbfc04968c28384ee11d92d155ec933f051f1349107b7dc954ff857473334d3a4609b9470ac56d359fa249fac67f5960f007f70ecb67e6bc266b954420286a82c963c873d244e1fd5d10723bf53c8b43d1816f73bf854b73002c6eb34f9e225ccfe73886c775b737b2b91553e9723cc14091e62ddddf79807f1cb73098de4d89959e089f51af0f342b4ba9e64475436be1547cb7a93d2c9ae9d06245b6c548c03bfef0fa8b5e0a35a1a058389ccd7d668991367a640e32d658044fed2ea207f70eb2e726465297d75f75686baed37a7c9d0e228d5844cd6e490dc7beb7ab18d5197d50c40bf95d45e039723621e91a593bd9679bbee1d6a8f779517ea4dfab9edf085c06fadc0bbc01fdc3acfa3b2cde749c362c9be921610307f2faf17e00fee1d96e4f245c824f3b54a53f2d30d9decdf4d9dc239b6bdf363aac8042cd5d418b7ad4308071ce0a57d363229e026498cfa7c1161ae040a2e0780712406caef693e510c9aaedd1baccfa18403bcadfc9515771c7959628dc54dc4943b002564483eb94100f007f5e8a6e3207766ef228ca1b043cd7fd71ae16fd6bcdb2a5c8a1ee2d712e63cd0b7300e47d451e0615fb1e7f041802f389e8681abbd007f70eccdcbc989050242adcffa4ee0e16288f7d4e8ecb783c01fdbdc3418a4dc9c77131bea8b1a79d2bcf8fecdf58403c01fdc3b33e8605d9ba92bcef395bee343b33e86100f007f70eccfa18403c01fdc3b33e86100f007f70eccf7c000feffbf400083f9e32757e2c9dec3971bcab3a956686515a0c61916c9cfeebb141baf7c358f732ff541810a1629d0dc7eec1c78a569bb56e018227c2381427e1d9d39dd547b5d428683841b91a37f0112c6b9b41f53e78886fe4278306fa2f7ac00a1af8ef290583360df5799c9d860f3357549e5e9a77ae1a45b389ebc7e6d837f3e07ff143687d2cbc7f1d427ff4212a78dcafe1f3f6df19e5c265c30534cf8705070756f65891b061b1eee99921fbff11894fab986dbac8a79237ea0aa98d96a6b9416313809a6fb6ca3a41ef846c77742d8f3cb2ebbf46f920980cfe9b6631e3b0426f63717ca597b977af2679538c529fe237c4fe5d19c000ea766003365cb4b1c8a944cb1cf2338156929ce0f58d21a9ba7d61373ff137936fc46a438429faf5b9b8d48c87220059fd3051c7f9b0f1b1d84247914e0422142e95cf113b6ac6b77f36e192e2734ca2c57a5e2af7a367fa70c4ac2ea6c6a0e0fd6ffdf2c84380fbfb1932cf3a595d7a93cf7693776e3508ba00a39ad360002a6b8cec9b2d7e59c8b7a4b269286e4d735ebb792e720db039267cc3491530e99d8dc798a18e403de2848c5fd320757e0d23c93647720bded52453107eb469bbaa9f158a583a50e4dbffed65befdf2bed1fe0c59c64f826f5c922371e3d61f283274c11c3f1800e9837458641c026918df4f82a9021e67d632ddf7337fba32ae62c34ac6d31233da8e523c3f10d3b55432d8ec07036a2d4a377a428305a71dad221e23827ffe07ff51cdd5b46f90688d64caed89d3b8c891d325b1fb60ca90de0acfc18f5afdcc982256b3bcbe0cfdab62b7385545b4b51e75d3eb807957a57a629131a578d6c76971326f391f83ec11f44732fc57c0f36b5ae44588600cd6292b11231bebb810e42f5e90be621f3e1c81c2819a43fe8bf287b195d5e9a6fcc9adce692ca327a2639ee9f97edacf7f84a39b6bc118fb6e356c093ec6664050e96d414d9dda60fec40894729b735ff7e3cb48624d52d521a26ffc2af168e6ad11df8c4f88fa26b6ef7665a9f285b9cad266dac2194f14370cee3bbe30f8235da872b02c7e4e2e79481f5d045efd37fd7438927de766663d1c7e225e7e6396632ec38a94dc89da6357831fc8bf1b4d1c10ca887f245d535638806338ff70e2efa50593c7f1692f0a5999291d82d3d444a3960df786b268ff2f4362a859bd351d76559f0fc332656e56184bf17c3a907d21a11f160186be994b86810bd1ced91598f1760fb49c10620d8b5705f2bb9c3953e6c391bdefc442ad920cbe5e9f12c12c04f86ade7515209d2bd2d17e3352c0968ab504b5afc0d8ff7da4bb658a0910fba85b1cb79e14c18c09ff8ee436edd70a42524d7379a68dd9cf8bf7aa735241a4bae607191bfb930345589dcee767faa1b59d2be2ac4e7b62a6ef6b5ad24868f84fe300c67c40e7be0f053654c859c5a2fb39a79b33de7e6cbc15ec249bddd339621651b75dedbf3eaf45e6b5e8c440e5345502d0d781f551189b9cf8297f4fb26efa1e805afad6cfc8108036b9fb6ebccf0fe458e489d8294f2aab8a88eb47bfead63df31d666ba906a5e7505cef80fb99ed1cd256c82956894eb593cedf1c71f32942275872980003476c254b80144e08f7b321cf9d91d0fe22b4df692503243bbd40b92af6c35bc9c850d91d5e29818b065d765f0f8db03661f59e09cf600abbcfc62e6e4befc6753039394a15787667d04a391abc4b129fb9672b12d97fea4c1159902740a1abfd78bfc943d182df11511a597bcb11fcb2d88d73de12cd01461ca8714cb6b0c8376af54bca6c0a030f18528b09ca062aa5b63cf2005c0d9bdb5aa41f2c4e5611dd09059df0a073dc1ad788739fd5edc8fbe9b8605fcf0816f705254815a289ba1db1e94e5704298c73142e826d92f3d5877a7c1f30aa51689447fe02069297c051a365060a3b32e668a549884e781b9d251074da3d3d5739d2e50f773e60ab9073eaa3a8d66e7bb7e1025ca970daec1edd104fa277ec1d0ec4ec840e7a621cfdfd84e62dcb67619fde4ec0c8bd6949209fe0d7e630d0f0769146216449a74acda514671e2bbd2c3047d2af76425cf7b45d625c3280e5ec878b0264d25eb0234891c1da28be8188ba43402dc46d701e8993542e8fd73f8f70c1100e6197ba33cbba5f28bc44ba7dee7c7337e4e87c393fcf6a64bbf1606d918fa9ae5a923e5dc198f2509e0332a24245070cde56ae4b2e5b430a446bd6274085cbc41509833d69c498c7826c5062262137af7a692169d1f7d85e23d4aaab24f11e5fc097c05bfd43c0fa9ef0740d3aca8a06668fceec0b7fef83ad036168d3f60aaa547edbebab274a5de6557be187c5dc06d3eb17ed1e1dee693ac9d6a18cd37696907f375090eed38ad1203a2cf087d650593de66ad86c63c183f4c3ecd8942a20523c5b66814ea04ce695ce42cfb1467cf9d7641a9756ff36768905bd457ec2e325118f65dadb0ce4770965bcfa40563d0cf0139fea22c2b7660d1d041fd0f7b0e53a20b2b2c57c487fe7730571424b0bc7b62869ea9d8bed6f862a236e7af12b87061e878aa8b3aa64c7bdf148fefdc8923d099c5222b22860ec76967140ebedf0e4c7f68de4917d548aa791c1927313123ec029875538d1d2931d1d5eef0e2856aad7ac59d8701a7d7deb20fcb5111b3871f44278e8935dd24c8c9fe3ecf93e6f2e273adcbe39e5443254f9cc063b0a6306972b2519b21ab7b711039b8d8d9bd78c3a8099c7a12e8dbff4bec9a347398fc6127d3362b6da777d743f207ab15156f7546a0b2310db2bdd82cb31b74fb6ee98004bc7080520fd3b10f0325990986931371bb15d7f9afab8e940d8a56518875b7f0fc3a33125ac0a1d81e3dc4dc7600c4530f8a951b531532ecc07a9fe32a299dd256634dead49d972fc6e0ac54e02f83ee8cc2c0004b0d71abba3b83334e53a8086cd7d898b81329d9affd37ef17e5bf9444ea140da4590abbe02ce94eeb9d2ddb0e8431fc65ad62b276a72f1b030dd3439f40bd1778f4b60d1325116ad63e5765a36004125013a3b8f71815c6f36982b16e021415163da19674d904365c3ad98e16ed88536d74a3b21e4858374f410fce2deedf24f4351048dd83d1b3d40109893b3f7edffd092b9e5e673f5fc173b3926084db674d16bcb1c0e69f2b9bce2f4746f7f6574c71e02019ebd9da253e5928fee1f3b6de0d348de3d9ae5c561f95c0b13a5c395c56d770dc84e62855a53def1cd1764fc0529520e6f847929e49286693f00dad1c4477a6b44577da6e0b2ed003b6b4d2f431d2c61f21991785a1bb92961e46ad80015b95d71fe3e2abf294e93ca9add3db75562c7f41856922c4163c09a0720ceacc7dd45b5c37350389041ce69499480f38476b7b1fc1023a63d3b5cbd10cbf4195bc57d8d6ccc8f912ba17b5d9e865a3c8804d3ecf0f21377933d60da14a0839dcbc11c9963f33d9e3d9a2aa8f979f65f8d119e3567960704c515b34532c75e33d5ca74aac75209bf062ee29f25b3dcb031d1d5c52c5943a2947541a200bae48d08747f46535e4f3fd33693e177eb2a20065b7de5007fe4f8b7aefe72989afafb4a276ef95a8d1525ee398aeaadbfa3b6893841e4924a3b4ea55977f656f1a0a05fd23878c002227073f4bacbda7d83332baa5a4060b6bdebc696c84f077a8ca34fc2d7c9f05e38cd40d452a566bf834586d290f2af51ddcd662778eebf9a7f042743cfdcb2253be0e13ae637f33b601f36fe6437b1ecc2d6c29b507db6706959dcd220705b3ff9cab7f33f6cc9002f48db41252e6ba6afb4f9d36e11e32e74dd0d09821ed374fff6e3d7496c35e1fcaa664d5f92ebe83d4015b858a497b33ebf07aebf07fcd508fe9a5252d467f3788b4f9c3f79da29a54f175cb8fff467fb331fa18a2084484432e15f3ee617b25c1ce3164f14da2691ef45513b8a38b21298b77bd9834af526f1d4a702474dfd15ae8e70c16d12c265627bcd372df362a780775c09194ee9e15ff4996a4eae22a92334bcf28963ae9e6b6fe63ce3a4ee8dc1a24b885e57b2fd725f7727590da9f049724b2d9856f59bbe4cc1d9d24241e6398332c60aa3ff5729ffe0812be8fd69579c74f6c1aaa9f1a5d0394f2ba5dfc2cbc8e63f5480322c93d57bccd7e589fc08fca504186aa79caebdd5b889135588442af012087beaf3b8c3038c504c9744dad1d7f0cade3c442ca6c4bdff0eae124a77a83e8735605641e6d2eda8a8d32cc3410b3b4f7c0a309c35e08e4f39708db51249786986d3b94148d9287f65157d89a3c53e465e463db5995a471af518f24022aa63f7b83200b58b3bb2d02e8391c921870b2e47d6cb30d7fa13e1dcd1c4083e59f58d4bdc71c98389a600def1c42fe1f5c8782726bb9635fa9c9ade6d0347bccff1a5b0d6c86176e37e2d57919c0caba392058e991e31e8549f3f1b35eb82dc000389afe90645be13f2b2f2074cc8637fe79e6353d802711b79fb07e21b67baece234419cd3a5c46cdae88197aafbc3d9f43321bcaf56aa2b89dff0aebb73f126713bc15690e01ac178c47cb9206336788803700ad7d7a50f724a23d51d4266e18d8dd43aa1561dc87368e662873d937471478120815d3e7d1c60a1efa4de6eca23f32be362e314764d73f6260bc2e2a7d33ee28d658d197fa9d1560a7625038c912acb0974c0edc74a02f1094f7893e5dae4060c5243804e41c70d4c8f965505333cb5c24cd6c5065de18f74d9c656ba756f04f4117175f2423223cb362448edf6bb899f70c0aa4754a998014041ed088280537274c92d396553dff020aa913670bd717175e209f0fcf1e0ffb1c60765b04fdc1bf62dfc080280c01de2c44fb60000000
c3f9e34d02f24097eb4f6683fc92201ec18a4d3edbf4017165d0d401527434ef	\\x52494646a405000057454250565038580a000000200000008f000097000049434350c8010000000001c800000000043000006d6e74725247422058595a2007e00001000100000000000061637370000000000000000000000000000000000000000000000000000000010000f6d6000100000000d32d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000964657363000000f0000000247258595a00000114000000146758595a00000128000000146258595a0000013c00000014777470740000015000000014725452430000016400000028675452430000016400000028625452430000016400000028637072740000018c0000003c6d6c756300000000000000010000000c656e5553000000080000001c007300520047004258595a200000000000006fa2000038f50000039058595a2000000000000062990000b785000018da58595a2000000000000024a000000f840000b6cf58595a20000000000000f6d6000100000000d32d706172610000000000040000000266660000f2a700000d59000013d000000a5b00000000000000006d6c756300000000000000010000000c656e5553000000200000001c0047006f006f0067006c006500200049006e0063002e0020003200300031003656503820b60300009017009d012a900098003e612e95472422a22127949908800c09696ee17121c6bfd40ec53fc3da08fc67eea7e9f85f95db06f4b14d2bcbb2992fcccccccc0aeacd37db5b0af3d9110ec5c9ca66a971ce3ba3c9817939bcb22a9483ad77cf3266ea67a5fd4b68041e30061196a55537d3074d0e4125639a432582b08e8d0fa27293f82f3e6602542b84e28c4a6df68ddf63312764e149837899803207ae254a8366592d6c831245d11e427947efb51fbbb184cf9321d3bbbbb9c39fd84c014fb568666664a000feff5d00fb2cfe6dfd1e1941ff114ae1e123d9711dd43d2858a4a7f0f31377f825c456a03d877fcd4b5cb0b41c0c692ae4b7948b92060a7a8b4e102c974ac6dc04f5ad960c89b596be3cd844f21f5715d11b62bcff982b2c35c4f04c0dcde5b40d3bc008c18c8317bd6ed273154bd349ad048f93f6273cabcef4adfdfde98f3bdcda6796e4d1b1205803d8f99236b7c436db9407eaebda51e931fba7b50307b4aa1e302cb225f42f9285221d4a59ffd2f5d031354277f0c4bcdacfc13fea4a251f03eceb0c2ba326141113a88e55f3fc776f40202717af2ac3a5794df16fed1c2d469b0a3e13bd6263a1de4c47ee852fd7a2cf5de32575ef521b955bc7490afe867ec310554a7af443a107b27711fe2997e5a7497708c5381c4de2bb7bbb57da613acec3efea28b44e10a417cdb9262d2387701a23fab66a705795be66a10840fc58323924f4e6a3fc8a1c69943b545c9f0813896bddf79be67b44e2d46f92df9567422d86f33e6f552c6a491f7a8f8cb26336d08009702e505393581fad7bfb150d4644f677fa5d6ff0a1faf77e387c78fec31ee25132e17676549520844e6ba8a059d0de2739f767ab499ad22cc0c5ea50ba2d9c842fcf859c9efcbe1234d02b44744469cb0e2e192b957685c6144cbef430454e3770b343dd2ebb35fd26291fb85f4a3ba11f5b5b4894b8c7feaa541b9db86a07e93be5cf3a0706c6401b2246bc39a159d55488a6277d0608c8fc605a4adc6bd1d7fec22137dc9399583208f851ee8352a5e2e2d5b168fce23eab10ff7caef9577269a7b191f215ff886a0a7f3e47b2dfdfe9ce736ccf6d6ff6a4e0b45df4479e1ca845c4ee8c18a4a5eb1ec43685481c807d6fb3d434e9188088ad3945dd0f42acca3ca2ba608e1235df1eab9de9e82f369d6dd5bf280e0b215c1cf78ce5530a69a0448d9f52d7822fcd9059dc9e9086ddfbd99a38b175c968fccc1d0f879f776d731ebd171064a9f8b53f331f42283888c3a5430f333839cb2458cb25af1a9c8b0d942948984c49219e76e985b9e2ece4fcb441fdbdf1ed400000
\.


--
-- Data for Name: a_knowledge; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_knowledge (id, d, updated) FROM stdin;
\.


--
-- Data for Name: a_payment_account; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_payment_account (id, d, is_archived, updated) FROM stdin;
01kzjg7aq1dqsx3wvm81snw1zw	{"id": "01kzjg7aq1dqsx3wvm81snw1zw", "bank": {"bankName": "BCA", "accountName": "Erick Febriyanto", "accountNumber": "8223558788"}, "name": "BCA", "type": "P_WALLET_TYPE_BANK"}	f	2026-08-09 05:34:11.065587+00
\.


--
-- Data for Name: a_product_category; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_product_category (id, parent_id, d, is_archived, updated) FROM stdin;
01KZWMVT62RNCCY630R1TTPRCJ	01KZWEKDY90GSBSH7D2JNKAG6H	{"id": "01KZWMVT62RNCCY630R1TTPRCJ", "pic": "iconify://mdi:brush-outline", "name": "Menggambar", "parentId": "01KZWEKDY90GSBSH7D2JNKAG6H"}	f	2026-08-13 04:07:40.500233+00
01KZWGAG1JBC0KH2T4WVY7P8A7	01KZWG9VBJ5R7ZCGYHRSPA317P	{"id": "01KZWGAG1JBC0KH2T4WVY7P8A7", "pic": "/fs/23a52f6f2bf36920c22c108dbf974fd7ca6301192bed1fa7e948858ea24c1fc2", "name": "Tradisional Dance", "parentId": "01KZWG9VBJ5R7ZCGYHRSPA317P"}	f	2026-08-13 02:48:18.740366+00
01KZTZV9FK7DC98GCZADQQTT7S	01KZTZTMWWNKPA56M6G77PRSDN	{"id": "01KZTZV9FK7DC98GCZADQQTT7S", "pic": "iconify://codicon:piano", "name": "Piano", "parentId": "01KZTZTMWWNKPA56M6G77PRSDN"}	f	2026-08-12 12:41:11.353788+00
01KZWFEB8SKK95RSNEAV892WZT	01KZTZTMWWNKPA56M6G77PRSDN	{"id": "01KZWFEB8SKK95RSNEAV892WZT", "pic": "iconify://qlementine-icons:cello-24", "name": "Cello", "parentId": "01KZTZTMWWNKPA56M6G77PRSDN"}	f	2026-08-13 02:32:56.347913+00
01KZWEW6S52QAMFTDV9SW9DX71	01KZWETSZV53FM5P5TQ80CJBS9	{"id": "01KZWEW6S52QAMFTDV9SW9DX71", "pic": "iconify://twemoji:badminton", "name": "Badminton", "parentId": "01KZWETSZV53FM5P5TQ80CJBS9"}	f	2026-08-13 02:23:01.927382+00
01KZWF2PM8V14NTNCVCKXT577J	01KZTZTMWWNKPA56M6G77PRSDN	{"id": "01KZWF2PM8V14NTNCVCKXT577J", "pic": "iconify://mingcute:guitar-fill", "name": "Gitar", "parentId": "01KZTZTMWWNKPA56M6G77PRSDN"}	f	2026-08-13 02:26:34.762843+00
01KZWEYK4BHHX7M3X7FAVVHRVP	01KZWETSZV53FM5P5TQ80CJBS9	{"id": "01KZWEYK4BHHX7M3X7FAVVHRVP", "pic": "iconify://iconoir:gym", "name": "Gym/Fitness", "parentId": "01KZWETSZV53FM5P5TQ80CJBS9"}	f	2026-08-13 02:24:20.109313+00
01KZTZTMWWNKPA56M6G77PRSDN		{"id": "01KZTZTMWWNKPA56M6G77PRSDN", "pic": "iconify://mdi:music", "name": "Musik"}	f	2026-08-12 12:40:50.272543+00
01KZWG9VBJ5R7ZCGYHRSPA317P	01KZWEKDY90GSBSH7D2JNKAG6H	{"id": "01KZWG9VBJ5R7ZCGYHRSPA317P", "pic": "/fs/aa4a9dcac2bd5d1907579e323efd5d9b346792add62c456ea73f6c647d09b7a3", "name": "Dance", "parentId": "01KZWEKDY90GSBSH7D2JNKAG6H"}	f	2026-08-13 02:47:57.556331+00
01KZWEKDY90GSBSH7D2JNKAG6H		{"id": "01KZWEKDY90GSBSH7D2JNKAG6H", "pic": "iconify://mdi:palette-outline", "name": "Seni"}	f	2026-08-13 02:18:14.346316+00
01KZWETSZV53FM5P5TQ80CJBS9		{"id": "01KZWETSZV53FM5P5TQ80CJBS9", "pic": "iconify://mdi:run-fast", "name": "Olah raga/Sport"}	f	2026-08-13 02:22:16.059757+00
01KZWGGRXTZH9S9A63FW7V2CND	01KZWG9VBJ5R7ZCGYHRSPA317P	{"id": "01KZWGGRXTZH9S9A63FW7V2CND", "pic": "/fs/ecf9b2a608d747daf5b4527f763a866985d9d871821737907234809328a65531", "name": "Hip-Hop Dance", "parentId": "01KZWG9VBJ5R7ZCGYHRSPA317P"}	f	2026-08-13 02:51:44.443866+00
01KZWF48F6A9PNMVS9QTDH36BA	01KZTZTMWWNKPA56M6G77PRSDN	{"id": "01KZWF48F6A9PNMVS9QTDH36BA", "pic": "iconify://lucide:drum", "name": "Drum", "parentId": "01KZTZTMWWNKPA56M6G77PRSDN"}	f	2026-08-13 02:27:25.800294+00
01KZWGAYFM3DGMWKZRNHV4J6GK	01KZWG9VBJ5R7ZCGYHRSPA317P	{"id": "01KZWGAYFM3DGMWKZRNHV4J6GK", "pic": "/fs/c3f9e34d02f24097eb4f6683fc92201ec18a4d3edbf4017165d0d401527434ef", "name": "Break Dance", "parentId": "01KZWG9VBJ5R7ZCGYHRSPA317P"}	f	2026-08-13 02:48:33.525791+00
01KZWEVESK8XJV2E5KF2KHFR7J	01KZWETSZV53FM5P5TQ80CJBS9	{"id": "01KZWEVESK8XJV2E5KF2KHFR7J", "pic": "iconify://material-symbols:padel", "name": "Padel", "parentId": "01KZWETSZV53FM5P5TQ80CJBS9"}	f	2026-08-13 02:22:37.365895+00
01KZWFC3G6Q18PR36AV60FEFYB	01KZTZTMWWNKPA56M6G77PRSDN	{"id": "01KZWFC3G6Q18PR36AV60FEFYB", "pic": "iconify://noto:violin", "name": "Biola/Violin", "parentId": "01KZTZTMWWNKPA56M6G77PRSDN"}	f	2026-08-13 02:31:42.855566+00
01KZWFKZAW9N8REPE1A1JG8CMX	01KZWEKDY90GSBSH7D2JNKAG6H	{"id": "01KZWFKZAW9N8REPE1A1JG8CMX", "pic": "iconify://mdi:photography", "name": "Fotografi/Photography", "parentId": "01KZWEKDY90GSBSH7D2JNKAG6H"}	f	2026-08-13 02:36:00.733758+00
\.


--
-- Data for Name: a_product_tag; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_product_tag (id, label, updated) FROM stdin;
01KZTYBB068JD12KSKV0X11XFP	Akademik	2026-08-12 12:14:59.99086+00
01KZTYH7C4QHVYY78N462JGG9J	Matematika	2026-08-12 12:18:12.855885+00
01KZTYH79P3401JWTPKJ9J9DM8	Kelas 1 SMA	2026-08-12 12:18:12.811282+00
01KZTYC4R22JEWFCP0XQP84J6J	Music	2026-08-12 12:15:23.909858+00
\.


--
-- Data for Name: a_slide; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_slide (id, d, is_archived, sort_order, updated) FROM stdin;
seed_slide_5	{"id": "seed_slide_5", "pic": "assets://slides/5.png", "order": 4, "title": "Slide 5", "active": true, "activeApp": true}	f	4	2026-08-12 08:25:06.881368+00
seed_slide_3	{"id": "seed_slide_3", "pic": "assets://slides/3.png", "order": 2, "title": "Slide 3", "active": true, "activeApp": true}	f	2	2026-08-12 08:25:06.668104+00
seed_slide_1	{"id": "seed_slide_1", "pic": "assets://slides/1.png", "title": "Slide 1", "active": true, "activeApp": true}	f	0	2026-08-12 08:25:06.411075+00
seed_slide_4	{"id": "seed_slide_4", "pic": "assets://slides/4.png", "order": 3, "title": "Slide 4", "active": true, "activeApp": true}	f	3	2026-08-12 08:25:06.775156+00
seed_slide_2	{"id": "seed_slide_2", "pic": "assets://slides/2.png", "order": 1, "title": "Slide 2", "active": true, "activeApp": true}	f	1	2026-08-12 08:25:06.561946+00
\.


--
-- Data for Name: a_user; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.a_user (uid, alien_id, name, pic, email, data, is_banned, created, updated) FROM stdin;
10000006		Jaime Clegane	https://lh3.googleusercontent.com/a/ACg8ocIhoGKmqQmo1I3ngMZgckpOxIjFljp3oNMgs03hgHZI7U0Jxt0NFA=s96-c	jaimeclegane001@gmail.com	{"aid": "10000006", "pic": "https://lh3.googleusercontent.com/a/ACg8ocIhoGKmqQmo1I3ngMZgckpOxIjFljp3oNMgs03hgHZI7U0Jxt0NFA=s96-c", "name": "Jaime Clegane", "user": {}, "created": "2026-08-12T23:43:03.060706397Z", "updated": "2026-08-12T23:43:03.060706397Z"}	f	2026-08-12 23:43:03.063102+00	2026-08-12 23:43:03.12104+00
10000002	skillplus_tester	Skill+ Tester			{"aid": "10000002", "name": "Skill+ Tester", "user": {}, "alienId": "skillplus_tester", "created": "2026-08-06T02:10:20.239858Z", "updated": "2026-08-06T02:10:20.239858Z"}	f	2026-08-06 02:10:20.846893+00	2026-08-06 02:10:20.846893+00
10000004		Chito	https://lh3.googleusercontent.com/a/ACg8ocIhzzCiDFqX91GWQsOSUmPkGrkElL4Zak12GaPzkAXOUEbHsUz8dw=s96-c	chitoadinugraha@gmail.com	{"aid": "10000004", "pic": "https://lh3.googleusercontent.com/a/ACg8ocIhzzCiDFqX91GWQsOSUmPkGrkElL4Zak12GaPzkAXOUEbHsUz8dw=s96-c", "name": "Chito", "user": {"prefs": {"notifications": {"remindTutorHours": [24, 1], "remindStudentHours": [6]}}}, "created": "2026-08-09T11:56:28.051761959Z", "updated": "2026-08-12T12:33:06.147674300Z"}	f	2026-08-09 11:56:28.058449+00	2026-08-12 12:33:08.663233+00
10000000		User 10000000			{"aid": "10000000", "name": "User 10000000", "user": {}, "created": "2026-08-12T07:40:18.647637300Z", "updated": "2026-08-12T07:40:18.647637300Z"}	f	2026-08-12 07:40:20.564082+00	2026-08-12 07:40:20.630859+00
10000005		Erick Febriyanto	https://lh3.googleusercontent.com/a/ACg8ocJjVe6PXxlMK7AGEOgMAHG7j2H0l3s5CO1NyybwqjlrLGdODA=s96-c	erickfeb88@gmail.com	{"aid": "10000005", "pic": "https://lh3.googleusercontent.com/a/ACg8ocJjVe6PXxlMK7AGEOgMAHG7j2H0l3s5CO1NyybwqjlrLGdODA=s96-c", "name": "Erick Febriyanto", "user": {}, "created": "2026-08-12T09:49:58.206089885Z", "updated": "2026-08-12T09:49:58.206089885Z"}	f	2026-08-12 09:49:58.208272+00	2026-08-12 09:49:58.241905+00
10000003		Guru Math SD	https://lh3.googleusercontent.com/a/ACg8ocKsbb1TYdQ7LbjjV8CjDaKw7QPTYZPuone3Ag9qFyN4II3MMQ=s96-c	hello.macan.minton@gmail.com	{"aid": "10000003", "pic": "https://lh3.googleusercontent.com/a/ACg8ocKsbb1TYdQ7LbjjV8CjDaKw7QPTYZPuone3Ag9qFyN4II3MMQ=s96-c", "name": "Guru Math SD", "user": {}, "created": "2026-08-06T04:53:36.922334541Z", "updated": "2026-08-09T05:15:16.844454544Z"}	f	2026-08-06 04:53:36.9262+00	2026-08-09 05:15:16.847699+00
\.


--
-- Data for Name: platform_app_version; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.platform_app_version (platform, version, version_name, min_version, store_url, updated_at) FROM stdin;
web	27	11.27.0	0	https://skillplus.alienai.id/	2026-08-12 01:58:05.697486+00
web	29	11.29.0	0	https://skillplus.alienai.id/	2026-08-12 10:53:00.15807+00
web	30	11.30.0	0	https://skillplus.alienai.id/	2026-08-12 13:03:02.890262+00
web	31	11.31.0	0	https://skillplus.alienai.id/	2026-08-13 02:27:11.068311+00
web	32	11.32.0	0	https://skillplus.alienai.id/	2026-08-13 04:41:40.590099+00
android	27	11.27.0	0	https://play.google.com/store/apps/details?id=id.alienai.skillplus	2026-08-12 01:58:05.34496+00
android	29	11.29.0	0	https://play.google.com/store/apps/details?id=id.alienai.skillplus	2026-08-12 10:52:59.808537+00
android	30	11.30.0	0	https://play.google.com/store/apps/details?id=id.alienai.skillplus	2026-08-12 13:03:02.533101+00
android	31	11.31.0	0	https://play.google.com/store/apps/details?id=id.alienai.skillplus	2026-08-13 02:27:10.645633+00
android	32	11.32.0	0	https://play.google.com/store/apps/details?id=id.alienai.skillplus	2026-08-13 04:41:40.182508+00
\.


--
-- Data for Name: s_jadwal; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.s_jadwal (id, kursus_id, d, geo_lat, geo_lng, is_archived, updated) FROM stdin;
\.


--
-- Data for Name: s_kursus; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.s_kursus (id, tutor_uid, name, desc_text, can_reserve, is_archived, d, search, updated, geo_lat, geo_lng, has_bookable_slots, next_bookable_at) FROM stdin;
01KZTDT4GYKD5TRPF63CGPYZQ7	10000000	Matematika		f	t	{"id": "01KZTDT4GYKD5TRPF63CGPYZQ7", "data": {"skillplus_geo_lat": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "-7.976256012043493"}, "skillplus_geo_lng": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "112.63695010875662"}, "skillplus_capacity": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "1"}, "skillplus_can_cancel": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_type": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "one_time"}, "skillplus_duration_minutes": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "60"}, "skillplus_location_options": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "[\\"tutor_to_student\\"]"}, "skillplus_location_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Indonesia, Kota Malang, no. 46 Jalan Trunojoyo"}, "skillplus_schedule_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Sekali: Rabu, 12 Agustus 2026 ┬╖ 15.24"}, "skillplus_has_bookable_slots": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "false"}, "skillplus_schedule_one_time_at": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "2026-08-12T08:24:48.891354Z"}}, "name": "Matematika", "prices": {"IDR": "150000"}, "saleWeb": "P_SALE_MODE_SALE", "saleStore": "P_SALE_MODE_SALE", "canReserve": true, "reserveDuration": "3600s", "minCancelDuration": "86400s", "maxRescheduleCount": 3, "minRescheduleDuration": "86400s"}	\N	2026-08-12 07:25:58.47923+00	\N	\N	f	\N
01KZTYG15SXVEZ5HYTSF1AY8T9	10000005	Piano		t	f	{"id": "01KZTYG15SXVEZ5HYTSF1AY8T9", "data": {"skillplus_geo_lat": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "-7.9817"}, "skillplus_geo_lng": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "112.6314"}, "skillplus_capacity": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "1"}, "skillplus_can_cancel": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_type": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "one_time"}, "skillplus_duration_minutes": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "60"}, "skillplus_location_options": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "[\\"tutor_to_student\\"]"}, "skillplus_location_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Indonesia, Kota Malang, No. 3 Jalan Merdeka Utara"}, "skillplus_next_bookable_at": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "2026-08-12T13:17:00Z"}, "skillplus_schedule_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Sekali: Rabu, 12 Agustus 2026 ┬╖ 20.17"}, "skillplus_has_bookable_slots": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_one_time_at": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "2026-08-12T13:17:00.555521Z"}}, "name": "Piano", "tags": ["Music"], "prices": {"IDR": "150000"}, "saleWeb": "P_SALE_MODE_SALE", "saleStore": "P_SALE_MODE_SALE", "canReserve": true, "reserveDuration": "3600s", "minCancelDuration": "86400s", "maxRescheduleCount": 3, "minRescheduleDuration": "86400s"}	'piano':1	2026-08-12 12:17:31.32168+00	-7.9817	112.6314	t	2026-08-12 13:17:00+00
01KZXMXDGCSP1NPY0ZYAMNPAX0	10000005	Gitar		t	f	{"id": "01KZXMXDGCSP1NPY0ZYAMNPAX0", "data": {"skillplus_geo_lat": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "-7.9666204"}, "skillplus_geo_lng": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "112.6326321"}, "skillplus_capacity": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "1"}, "skillplus_can_cancel": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_type": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "repeating"}, "skillplus_duration_minutes": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "60"}, "skillplus_location_options": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "[\\"tutor_to_student\\"]"}, "skillplus_location_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Indonesia, Malang, Kota Malang"}, "skillplus_next_bookable_at": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "2026-08-18T04:30:00Z"}, "skillplus_schedule_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Mingguan: Selasa 04:30-05:30"}, "skillplus_has_bookable_slots": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_weekly_json": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "[{\\"weekday\\":2,\\"ranges\\":[{\\"start_minute\\":270,\\"end_minute\\":330}]}]"}}, "name": "Gitar", "tags": ["Music"], "prices": {"IDR": "150000"}, "saleWeb": "P_SALE_MODE_SALE", "saleStore": "P_SALE_MODE_SALE", "canReserve": true, "categoryId": ["01KZWF2PM8V14NTNCVCKXT577J"], "reserveDuration": "3600s", "minCancelDuration": "86400s", "maxRescheduleCount": 3, "minRescheduleDuration": "86400s"}	'gitar':1	2026-08-13 13:27:47.469367+00	-7.9666204	112.6326321	t	2026-08-18 04:30:00+00
01KZTN7C5CB0S4MDFEAWBBPT86	10000004	Matematika Mudah		t	f	{"id": "01KZTN7C5CB0S4MDFEAWBBPT86", "data": {"skillplus_geo_lat": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "-7.9817"}, "skillplus_geo_lng": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "112.6314"}, "skillplus_capacity": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "1"}, "skillplus_can_cancel": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_type": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "repeating"}, "skillplus_duration_minutes": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "60"}, "skillplus_location_options": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "[\\"tutor_to_student\\"]"}, "skillplus_location_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Indonesia, Kota Malang, No. 3 Jalan Merdeka Utara"}, "skillplus_next_bookable_at": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "2026-08-17T12:00:00Z"}, "skillplus_schedule_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Mingguan: Senin 19:00-20:00; Selasa 19:00-20:00"}, "skillplus_has_bookable_slots": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_weekly_json": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "[{\\"weekday\\":1,\\"ranges\\":[{\\"start_minute\\":1140,\\"end_minute\\":1200}]},{\\"weekday\\":2,\\"ranges\\":[{\\"start_minute\\":1140,\\"end_minute\\":1200}]}]"}}, "name": "Matematika Mudah", "prices": {"IDR": "150000"}, "saleWeb": "P_SALE_MODE_SALE", "saleStore": "P_SALE_MODE_SALE", "canReserve": true, "reserveDuration": "3600s", "minCancelDuration": "3600s", "maxRescheduleCount": 3, "minRescheduleDuration": "3600s"}	'matematika':1 'mudah':2	2026-08-12 09:35:32.552081+00	-7.9817	112.6314	t	2026-08-17 12:00:00+00
01KZWPDKHRP9X3G1Y7EQ1QH1YX	10000002	Wizard kursus 1786595692044	mengajar matematika SD	t	t	{"id": "01KZWPDKHRP9X3G1Y7EQ1QH1YX", "data": {"skillplus_capacity": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "1"}, "skillplus_can_cancel": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_type": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "one_time"}, "skillplus_duration_minutes": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "60"}, "skillplus_location_options": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "[\\"tutor_to_student\\"]"}, "skillplus_location_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": ""}, "skillplus_next_bookable_at": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "2026-08-16T06:34:00Z"}, "skillplus_schedule_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Sekali: sesi uji"}, "skillplus_has_bookable_slots": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_one_time_at": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "2026-08-16T06:34:52.044904Z"}}, "desc": "mengajar matematika SD", "name": "Wizard kursus 1786595692044", "tags": ["matematika"], "prices": {"IDR": "150000"}, "saleWeb": "P_SALE_MODE_SALE", "saleStore": "P_SALE_MODE_SALE", "canReserve": true, "isArchived": true, "reserveDuration": "3600s", "minCancelDuration": "86400s", "maxRescheduleCount": 3, "minRescheduleDuration": "86400s"}	'1786595692044':3 'kursus':2 'matematika':5 'mengajar':4 'sd':6 'wizard':1	2026-08-13 04:34:52.742869+00	\N	\N	t	2026-08-16 06:34:00+00
01KZWN8YGNPVPZRD09PMFFNE5K	10000005	Piano Cak Kin		t	f	{"id": "01KZWN8YGNPVPZRD09PMFFNE5K", "data": {"skillplus_geo_lat": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "-7.472613399999998"}, "skillplus_geo_lng": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "112.6675398"}, "skillplus_capacity": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "1"}, "skillplus_can_cancel": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_type": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "both"}, "skillplus_duration_minutes": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "60"}, "skillplus_location_options": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "[\\"tutor_to_student\\"]"}, "skillplus_location_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Indonesia, Kabupaten Sidoarjo, GMG9+X23"}, "skillplus_next_bookable_at": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "2026-08-13T10:00:00Z"}, "skillplus_schedule_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Sekali: Kamis, 13 Agustus 2026 ┬╖ 17.00 ┬╖ Mingguan: Senin 04:30-05:30"}, "skillplus_has_bookable_slots": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_one_time_at": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "2026-08-13T10:00:00.000Z"}, "skillplus_schedule_weekly_json": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "[{\\"weekday\\":1,\\"ranges\\":[{\\"start_minute\\":270,\\"end_minute\\":330}]}]"}}, "name": "Piano Cak Kin", "tags": ["Music"], "prices": {"IDR": "125000"}, "saleWeb": "P_SALE_MODE_SALE", "saleStore": "P_SALE_MODE_SALE", "canReserve": true, "categoryId": ["01KZTZV9FK7DC98GCZADQQTT7S"], "reserveDuration": "3600s", "minCancelDuration": "86400s", "maxRescheduleCount": 3, "minRescheduleDuration": "86400s"}	'cak':2 'kin':3 'piano':1	2026-08-13 04:14:50.90243+00	-7.472613399999998	112.6675398	t	2026-08-13 10:00:00+00
01KZTDZGHR15PP2J3Q6G01ZGSF	10000000	Matematika		t	f	{"id": "01KZTDZGHR15PP2J3Q6G01ZGSF", "data": {"skillplus_geo_lat": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "-7.976256012043493"}, "skillplus_geo_lng": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "112.63695010875662"}, "skillplus_capacity": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "1"}, "skillplus_can_cancel": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_type": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "one_time"}, "skillplus_duration_minutes": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "60"}, "skillplus_location_options": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "[\\"tutor_to_student\\"]"}, "skillplus_location_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Indonesia, Kota Malang, no. 46 Jalan Trunojoyo"}, "skillplus_schedule_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Sekali: Rabu, 12 Agustus 2026 ┬╖ 15.24"}, "skillplus_has_bookable_slots": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "false"}, "skillplus_schedule_one_time_at": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "2026-08-12T08:24:48.891354Z"}}, "name": "Matematika", "prices": {"IDR": "150000"}, "saleWeb": "P_SALE_MODE_SALE", "saleStore": "P_SALE_MODE_SALE", "canReserve": true, "reserveDuration": "3600s", "minCancelDuration": "86400s", "maxRescheduleCount": 3, "minRescheduleDuration": "86400s"}	'matematika':1	2026-08-12 07:28:54.628664+00	-7.976256012043493	112.63695010875662	f	\N
01KZWPDMVBWD966000AN6Z3FE0	10000002	Integration kursus 1786595693378	Created by segment_kursus integration test	t	t	{"id": "01KZWPDMVBWD966000AN6Z3FE0", "data": {"skillplus_capacity": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "1"}, "skillplus_can_cancel": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "true"}, "skillplus_schedule_type": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "one_time"}, "skillplus_duration_minutes": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "60"}, "skillplus_location_summary": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "Online"}, "skillplus_has_bookable_slots": {"@type": "type.googleapis.com/google.protobuf.StringValue", "value": "false"}}, "desc": "Created by segment_kursus integration test", "name": "Integration kursus 1786595693378", "tags": ["integration"], "prices": {"IDR": "50000"}, "saleWeb": "P_SALE_MODE_SALE", "saleStore": "P_SALE_MODE_SALE", "canReserve": true, "isArchived": true, "reserveDuration": "3600s", "minCancelDuration": "86400s", "maxRescheduleCount": 3, "minRescheduleDuration": "86400s"}	'1786595693378':3 'by':5 'created':4 'integration':1,8 'kursus':2,7 'segment':6 'test':9	2026-08-13 04:34:54.073498+00	\N	\N	f	\N
\.


--
-- Data for Name: s_reservasi; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.s_reservasi (id, student_uid, tutor_uid, kursus_id, state, total, d, ts, updated) FROM stdin;
01KZTXXPAJEMCYZPBGFHZK1KFZ	10000005	10000004	01KZTN7C5CB0S4MDFEAWBBPT86	done	150000	{"id": "01KZTXXPAJEMCYZPBGFHZK1KFZ", "time": "2026-08-17T12:00:00Z", "type": "P_TX_TYPE_SALE", "items": [{"qty": 1, "price": 150000, "product": "01KZTN7C5CB0S4MDFEAWBBPT86", "reservations": [{"end": "2026-08-17T13:00:00Z", "qty": 1, "start": "2026-08-17T12:00:00Z", "state": "P_TX_ITEM_RESERVATION_STATE_DONE", "durationQty": 60}]}], "total": "150000", "createdAt": "2026-08-12T12:07:30.386600813Z", "createdBy": "10000005", "subjectId": "10000005", "updatedAt": "2026-08-15T11:40:30.267829315Z", "itemsTotal": "150000"}	2026-08-12 12:07:30.388758+00	2026-08-15 11:40:30.270194+00
01KZTF47ND80YEBS676JMXB9JS	10000004	10000000	01KZTDZGHR15PP2J3Q6G01ZGSF	done	150000	{"id": "01KZTF47ND80YEBS676JMXB9JS", "time": "2026-08-12T08:24:00Z", "type": "P_TX_TYPE_SALE", "items": [{"qty": 1, "price": 150000, "product": "01KZTDZGHR15PP2J3Q6G01ZGSF", "reservations": [{"end": "2026-08-12T09:24:00Z", "qty": 1, "start": "2026-08-12T08:24:00Z", "state": "P_TX_ITEM_RESERVATION_STATE_DONE", "durationQty": 60}]}], "total": "150000", "createdAt": "2026-08-12T07:48:56.109995Z", "createdBy": "10000004", "subjectId": "10000004", "updatedAt": "2026-08-12T08:00:28.294021300Z", "itemsTotal": "150000"}	2026-08-12 07:48:58.058582+00	2026-08-12 08:00:30.199559+00
\.


--
-- Data for Name: s_reservasi_item; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.s_reservasi_item (reservasi_id, item_id, d, start_at, end_at, state, is_no_show, is_unavailable) FROM stdin;
01KZTXXPAJEMCYZPBGFHZK1KFZ	1	{"qty": 1, "price": 150000, "product": "01KZTN7C5CB0S4MDFEAWBBPT86", "reservations": [{"end": "2026-08-17T13:00:00Z", "qty": 1, "start": "2026-08-17T12:00:00Z", "state": "P_TX_ITEM_RESERVATION_STATE_DONE", "durationQty": 60}]}	2026-08-17 12:00:00+00	2026-08-17 13:00:00+00	done	f	f
01KZTF47ND80YEBS676JMXB9JS	1	{"qty": 1, "price": 150000, "product": "01KZTDZGHR15PP2J3Q6G01ZGSF", "reservations": [{"end": "2026-08-12T09:24:00Z", "qty": 1, "start": "2026-08-12T08:24:00Z", "state": "P_TX_ITEM_RESERVATION_STATE_DONE", "durationQty": 60}]}	2026-08-12 08:24:00+00	2026-08-12 09:24:00+00	done	f	f
\.


--
-- Data for Name: u_access; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.u_access (uid, role, data, updated) FROM stdin;
10000006	student	{"skillplus_role": {"value": "CgdzdHVkZW50", "type_url": "type.googleapis.com/google.protobuf.StringValue"}}	2026-08-24 04:58:19.604301+00
10000002	manager	{"skillplus_role": {"value": "CgV0dXRvcg==", "type_url": "type.googleapis.com/google.protobuf.StringValue"}}	2026-08-24 04:58:19.627539+00
10000004	manager	{"skillplus_role": {"value": "CgdtYW5hZ2Vy", "type_url": "type.googleapis.com/google.protobuf.StringValue"}}	2026-08-24 04:58:19.709423+00
10000000	student	{"skillplus_role": {"value": "CgdzdHVkZW50", "type_url": "type.googleapis.com/google.protobuf.StringValue"}}	2026-08-24 04:58:19.618596+00
10000005	manager	{"display_email": {"value": "ChRlcmlja2ZlYjg4QGdtYWlsLmNvbQ==", "type_url": "type.googleapis.com/google.protobuf.StringValue"}, "skillplus_role": {"value": "CgdzdHVkZW50", "type_url": "type.googleapis.com/google.protobuf.StringValue"}}	2026-08-12 12:06:29.416037+00
10000003	manager	{"skillplus_role": {"value": "CgdtYW5hZ2Vy", "type_url": "type.googleapis.com/google.protobuf.StringValue"}}	2026-08-24 04:58:19.71207+00
\.


--
-- Data for Name: u_asset_access; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.u_asset_access (uid, asset_type, asset_id, data) FROM stdin;
10000002	s_kursus	01KZWPDKHRP9X3G1Y7EQ1QH1YX	{"uid": "10000002", "assetId": "01KZWPDKHRP9X3G1Y7EQ1QH1YX", "assetType": "s_kursus"}
10000002	s_kursus	01KZWPDMVBWD966000AN6Z3FE0	{"uid": "10000002", "assetId": "01KZWPDMVBWD966000AN6Z3FE0", "assetType": "s_kursus"}
10000004	s_kursus	01KZTN7C5CB0S4MDFEAWBBPT86	{"uid": "10000004", "assetId": "01KZTN7C5CB0S4MDFEAWBBPT86", "assetType": "s_kursus"}
10000000	s_kursus	01KZTDZGHR15PP2J3Q6G01ZGSF	{"uid": "10000000", "assetId": "01KZTDZGHR15PP2J3Q6G01ZGSF", "assetType": "s_kursus"}
10000005	s_kursus	01KZTYG15SXVEZ5HYTSF1AY8T9	{"uid": "10000005", "assetId": "01KZTYG15SXVEZ5HYTSF1AY8T9", "assetType": "s_kursus"}
10000005	s_kursus	01KZWN8YGNPVPZRD09PMFFNE5K	{"uid": "10000005", "assetId": "01KZWN8YGNPVPZRD09PMFFNE5K", "assetType": "s_kursus"}
10000005	s_kursus	01KZXMXDGCSP1NPY0ZYAMNPAX0	{"uid": "10000005", "assetId": "01KZXMXDGCSP1NPY0ZYAMNPAX0", "assetType": "s_kursus"}
\.


--
-- Data for Name: u_auth_google; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.u_auth_google (sub, uid, email, name, pic, updated) FROM stdin;
102004931260244923813	10000004	chitoadinugraha@gmail.com	Chito Adinugraha	https://lh3.googleusercontent.com/a/ACg8ocIhzzCiDFqX91GWQsOSUmPkGrkElL4Zak12GaPzkAXOUEbHsUz8dw=s96-c	2026-08-09 11:56:28.078328+00
101654954814082955450	10000006	jaimeclegane001@gmail.com	Jaime Clegane	https://lh3.googleusercontent.com/a/ACg8ocIhoGKmqQmo1I3ngMZgckpOxIjFljp3oNMgs03hgHZI7U0Jxt0NFA=s96-c	2026-08-12 23:43:03.107347+00
108292224661747076005	10000005	erickfeb88@gmail.com	Erick Febriyanto	https://lh3.googleusercontent.com/a/ACg8ocJjVe6PXxlMK7AGEOgMAHG7j2H0l3s5CO1NyybwqjlrLGdODA=s96-c	2026-08-12 09:49:58.224537+00
105174028414493179490	10000003	hello.macan.minton@gmail.com	Macan Minton	https://lh3.googleusercontent.com/a/ACg8ocKsbb1TYdQ7LbjjV8CjDaKw7QPTYZPuone3Ag9qFyN4II3MMQ=s96-c	2026-08-06 04:53:36.941756+00
\.


--
-- Data for Name: u_auth_password; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.u_auth_password (uid, salt, hash, updated) FROM stdin;
10000002	\\x6efcf0e159ff2f963aaaaeacdf824c9a	\\x243261243130247832593567725271713643613352627242766959332e4b5a366c494b5646566a3174656e6a54465875644339377743317a536c4753	2026-08-24 04:58:19.699139+00
\.


--
-- Data for Name: u_fcm; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.u_fcm (uid, client_id, token, platform, ts) FROM stdin;
10000006	KwIb0UddYktoL-tGI6H_L50mmURkufED	cxRFZx_hRT2WCD5mI6UMp_:APA91bEMbtbzTOAWPkQWybUsxfeprufOGoaqTAA2LrYuOBnIzEVUjG-t3RIm_X9FsgyMjhGZ46lKPzs1P9ub7mZXSj9lyo_I0W_YDLUPvVdi0zEmOEMR4rk	1	2026-08-12 23:43:03.57402+00
10000002	KJJIefAtVLTB-F9oW0GSB25f97KnZA1-	e8_zlcIVROqi8WcaZs77Wn:APA91bF1liSYTfoSzf1unvkV4iVqFbZE66wsgydezUwFtGX5CrMKJbIXFd2mLhg6soz83fr3vc-ZkINKAUOUdpAoC1YLYUbXpU1voMjniGvueWlIZDmXpX8	1	2026-08-12 09:47:50.48712+00
10000004	gy8FLProLh-CovF4N9GqBTQT-I017EKD	fVzsvRJcTue7auW9eC9FYc:APA91bGLfwc-oCmfSJwYYR5fFuZr3DJnMSg8XRYFgGaPyPA6BeBFnqYxJwN0TG6q-nfLgvdxZuUJuoTFaOaMvKPtYuca5FmrD_vyCdl1H-CVtlFgYvYknVo	1	2026-08-12 12:44:26.036968+00
10000005	cH5XTM2vZ7M6Hz_sOS79tFNPvTXI_514	ftgPkIUbT_KVkRAvfrZ3pV:APA91bFqGCVuvUu2u4Z2noGl0USvnSrsuYApjw190IpaxeJIJrDkbGJ9RFvMyZLp8wAEUsDj0u69RDBfjR94teyMDjDC1zp45UFQtf3Zv_9cCDXbJlciR3U	1	2026-08-15 11:39:54.637535+00
10000003	hJ9a0bzE22C145RYt0iXJzdeeWRaF91_	fMyjn4U1QeaaMdC3J8XzgB:APA91bGATKeoU9YuS4YWds9VICxbsco2CyAkauesZbmLtt2sZbUqgVIFKHskPSX7AWAgg9dioCVSkXAeu8PkOy6s-lTFDmb6H6T99Hco7LqNo9NpS4efNMo	1	2026-08-12 05:34:39.879481+00
\.


--
-- Data for Name: u_notif_sent; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.u_notif_sent (dedup_key, uid, ts) FROM stdin;
\.


--
-- Data for Name: u_review; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.u_review (id, reviewer_uid, asset_type, asset_id, d, ts) FROM stdin;
s_reservasi|01KZTXXPAJEMCYZPBGFHZK1KFZ|10000004	10000004	s_reservasi	01KZTXXPAJEMCYZPBGFHZK1KFZ	{"rating": 5, "assetId": "01KZTXXPAJEMCYZPBGFHZK1KFZ", "assetType": "s_reservasi", "createdAt": "1786536595938", "updatedAt": "1786536595938", "reviewerUid": "10000004"}	2026-08-12 12:09:58.405147+00
s_reservasi|01KZTF47ND80YEBS676JMXB9JS|10000004	10000004	s_reservasi	01KZTF47ND80YEBS676JMXB9JS	{"rating": 5, "assetId": "01KZTF47ND80YEBS676JMXB9JS", "assetType": "s_reservasi", "createdAt": "1786523064048", "updatedAt": "1786523064048", "reviewerUid": "10000004"}	2026-08-12 08:24:26.043963+00
s_reservasi|01KZTXXPAJEMCYZPBGFHZK1KFZ|10000005	10000005	s_reservasi	01KZTXXPAJEMCYZPBGFHZK1KFZ	{"rating": 5, "assetId": "01KZTXXPAJEMCYZPBGFHZK1KFZ", "assetType": "s_reservasi", "createdAt": "1786794060409", "updatedAt": "1786794060409", "reviewerUid": "10000005"}	2026-08-15 11:41:00.412819+00
s_reservasi|01KZTF47ND80YEBS676JMXB9JS|10000005	10000005	s_reservasi	01KZTF47ND80YEBS676JMXB9JS	{"rating": 5, "assetId": "01KZTF47ND80YEBS676JMXB9JS", "comment": "bagus gurunya mantap", "assetType": "s_reservasi", "createdAt": "1786794069771", "updatedAt": "1786794069771", "reviewerUid": "10000005"}	2026-08-15 11:41:09.773149+00
\.


--
-- Data for Name: u_wallet; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.u_wallet (wid, uid, name, currency, balance, data, updated) FROM stdin;
skillplus-10000000-idr	10000000	Skill+	IDR	150000	{"uid": "10000000", "wid": "skillplus-10000000-idr", "name": "Skill+", "balance": "150000", "currency": "IDR", "autoVerify": true}	2026-08-12 08:00:31.095491+00
skillplus-10000004-idr	10000004	Skill+	IDR	500000	{"uid": "10000004", "wid": "skillplus-10000004-idr", "name": "Skill+", "balance": "500000", "currency": "IDR", "autoVerify": true}	2026-08-15 11:40:30.452073+00
skillplus-10000003-idr	10000003	Skill+	IDR	0	{"uid": "10000003", "wid": "skillplus-10000003-idr", "name": "Skill+", "currency": "IDR", "autoVerify": true}	2026-08-06 04:53:37.000758+00
skillplus-10000005-idr	10000005	Skill+	IDR	4550000	{"uid": "10000005", "wid": "skillplus-10000005-idr", "name": "Skill+", "balance": "4550000", "currency": "IDR", "autoVerify": true}	2026-08-15 11:40:30.445556+00
skillplus-10000002-idr	10000002	Skill+	IDR	0	{"uid": "10000002", "wid": "skillplus-10000002-idr", "name": "Skill+", "currency": "IDR", "autoVerify": true}	2026-08-12 10:14:03.45735+00
skillplus-10000006-idr	10000006	Skill+	IDR	0	{"uid": "10000006", "wid": "skillplus-10000006-idr", "name": "Skill+", "currency": "IDR"}	2026-08-12 23:43:03.172656+00
\.


--
-- Data for Name: u_wallet_hold; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.u_wallet_hold (ref_type, ref_id, wid, uid, amount, state, d, created) FROM stdin;
p_tx	01KZTF47ND80YEBS676JMXB9JS	skillplus-10000004-idr	10000004	150000	captured	{}	2026-08-12 07:48:58.829893+00
p_tx	01KZTXXPAJEMCYZPBGFHZK1KFZ	skillplus-10000005-idr	10000005	150000	captured	{}	2026-08-12 12:07:30.47129+00
\.


--
-- Data for Name: u_wallet_tx; Type: TABLE DATA; Schema: public; Owner: csa
--

COPY public.u_wallet_tx (id, wid, uid, type, state, amount, d, ts) FROM stdin;
01KZTEB4ATJSYH9GTRFBSXA105	skillplus-10000000-idr	10000000	DEPOSIT	REJECTED	500000	{"id": "01KZTEB4ATJSYH9GTRFBSXA105", "uid": "10000000", "wid": "skillplus-10000000-idr", "note": "bank_id:01kzjg7aq1dqsx3wvm81snw1zw", "pics": ["/fs/4e7b4296a17ae8ddc78118655679c370448649cc0bfc5850c876bdd76237056b"], "amount": "500000", "status": "WALLET_TX_STATUS_REJECTED", "currency": "IDR", "createdAt": "1786520113498", "verifiedAt": "1786520681395", "verifiedBy": "10000004"}	2026-08-12 07:44:43.268784+00
01KZTECVTV29NA8FEJ3Q399EVG	skillplus-10000000-idr	10000000	DEPOSIT	REJECTED	500000	{"id": "01KZTECVTV29NA8FEJ3Q399EVG", "uid": "10000000", "wid": "skillplus-10000000-idr", "note": "bank_id:01kzjg7aq1dqsx3wvm81snw1zw", "pics": ["/fs/4e7b4296a17ae8ddc78118655679c370448649cc0bfc5850c876bdd76237056b"], "amount": "500000", "status": "WALLET_TX_STATUS_REJECTED", "currency": "IDR", "createdAt": "1786520170331", "verifiedAt": "1786520678731", "verifiedBy": "10000004"}	2026-08-12 07:44:40.56689+00
01KZTENTKWAE2GARWP4YCSZD8Q	skillplus-10000000-idr	10000000	DEPOSIT	REJECTED	500000	{"id": "01KZTENTKWAE2GARWP4YCSZD8Q", "uid": "10000000", "wid": "skillplus-10000000-idr", "note": "bank_id:01kzjg7aq1dqsx3wvm81snw1zw", "pics": ["/fs/4e7b4296a17ae8ddc78118655679c370448649cc0bfc5850c876bdd76237056b"], "amount": "500000", "status": "WALLET_TX_STATUS_REJECTED", "currency": "IDR", "createdAt": "1786520463996", "verifiedAt": "1786520675201", "verifiedBy": "10000004"}	2026-08-12 07:44:37.03775+00
01KZTFSCSY5X5E4ZVV1ARREQSF	skillplus-10000000-idr	10000000	DEPOSIT	APPROVED	150000	{"id": "01KZTFSCSY5X5E4ZVV1ARREQSF", "uid": "10000000", "wid": "skillplus-10000000-idr", "note": "Penyelesaian Kursus Matematika", "amount": "150000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786521629409", "verifiedAt": "1786521629409"}	2026-08-12 08:00:31.372718+00
01KZTETHYF1GCXEES49RTPTDQ3	skillplus-10000004-idr	10000004	DEPOSIT	APPROVED	500000	{"id": "01KZTETHYF1GCXEES49RTPTDQ3", "uid": "10000004", "wid": "skillplus-10000004-idr", "note": "bank_id:01kzjg7aq1dqsx3wvm81snw1zw", "pics": ["/fs/4e7b4296a17ae8ddc78118655679c370448649cc0bfc5850c876bdd76237056b"], "amount": "500000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786520618959", "verifiedAt": "1786520666207", "verifiedBy": "10000004"}	2026-08-12 07:44:28.483508+00
01KZTFSCQ1R90FW70N76JEKHTM	skillplus-10000004-idr	10000004	TRANSFER	APPROVED	150000	{"id": "01KZTFSCQ1R90FW70N76JEKHTM", "uid": "10000004", "wid": "skillplus-10000004-idr", "note": "Penyelesaian Kursus Matematika", "type": "WALLET_TX_TYPE_TRANSFER", "amount": "150000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786521629409", "verifiedAt": "1786521629409", "transferWid": "skillplus-10000000-idr"}	2026-08-12 08:00:31.320204+00
01M02KJDCW29BB5RT4HGAEMW8M	skillplus-10000004-idr	10000004	DEPOSIT	APPROVED	150000	{"id": "01M02KJDCW29BB5RT4HGAEMW8M", "uid": "10000004", "wid": "skillplus-10000004-idr", "note": "Penyelesaian Kursus Matematika Mudah", "amount": "150000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786794030428", "verifiedAt": "1786794030428"}	2026-08-15 11:40:30.493149+00
01KZTP3A7MPK6C266WRC7W6W6F	skillplus-10000005-idr	10000005	DEPOSIT	APPROVED	4700000	{"id": "01KZTP3A7MPK6C266WRC7W6W6F", "uid": "10000005", "wid": "skillplus-10000005-idr", "note": "bank_id:01kzjg7aq1dqsx3wvm81snw1zw", "pics": ["/fs/97e16bc3c9bdb420ab6a504149d5706d04fb3e6813524358cb087ffbc846951b"], "amount": "4700000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786528246004", "verifiedAt": "1786528246004"}	2026-08-12 09:50:46.018736+00
01KZTQCQHYJV8821YNEFR248VF	skillplus-10000005-idr	10000005	WITHDRAW	APPROVED	4700000	{"id": "01KZTQCQHYJV8821YNEFR248VF", "uid": "10000005", "wid": "skillplus-10000005-idr", "note": "Batal", "type": "WALLET_TX_TYPE_WITHDRAW", "amount": "4700000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786529603134", "verifiedAt": "1786529603134", "verifiedBy": "10000004"}	2026-08-12 10:13:25.43884+00
01KZTXTG7SS1GND5NEKXEMCZDF	skillplus-10000005-idr	10000005	DEPOSIT	APPROVED	4700000	{"id": "01KZTXTG7SS1GND5NEKXEMCZDF", "uid": "10000005", "wid": "skillplus-10000005-idr", "note": "bank_id:01kzjg7aq1dqsx3wvm81snw1zw", "pics": ["/fs/97e16bc3c9bdb420ab6a504149d5706d04fb3e6813524358cb087ffbc846951b"], "amount": "4700000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "userName": "Erick Febriyanto ┬╖ erickfeb88@gmail.com", "createdAt": "1786536345849", "verifiedAt": "1786536420674", "verifiedBy": "10000005"}	2026-08-12 12:07:00.704856+00
01M02KJDC3SWRXSH5WAE9BG4M2	skillplus-10000005-idr	10000005	TRANSFER	APPROVED	150000	{"id": "01M02KJDC3SWRXSH5WAE9BG4M2", "uid": "10000005", "wid": "skillplus-10000005-idr", "note": "Penyelesaian Kursus Matematika Mudah", "type": "WALLET_TX_TYPE_TRANSFER", "amount": "150000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786794030428", "verifiedAt": "1786794030428", "transferWid": "skillplus-10000004-idr"}	2026-08-15 11:40:30.47384+00
01KZTAE6JASS3X3RHD0KAM60AN	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	4700000	{"id": "01KZTAE6JASS3X3RHD0KAM60AN", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "bank_id:01kzjg7aq1dqsx3wvm81snw1zw", "pics": ["/fs/97e16bc3c9bdb420ab6a504149d5706d04fb3e6813524358cb087ffbc846951b"], "amount": "4700000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516019786", "verifiedAt": "1786516019786"}	2026-08-12 06:26:59.806067+00
01KZTAEB9BTA88CDXZPKS4MWKW	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	4700000	{"id": "01KZTAEB9BTA88CDXZPKS4MWKW", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "bank_id:01kzjg7aq1dqsx3wvm81snw1zw", "pics": ["/fs/97e16bc3c9bdb420ab6a504149d5706d04fb3e6813524358cb087ffbc846951b"], "amount": "4700000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516024619", "verifiedAt": "1786516024619"}	2026-08-12 06:27:04.629596+00
01KZTANDCZDMRGQ7M8GDPTFD0Z	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTANDCZDMRGQ7M8GDPTFD0Z", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "integration test", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516256159", "verifiedAt": "1786516256159"}	2026-08-12 06:30:57.993548+00
01KZTAP2ZQYV7BWCNM2EDTAQ33	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTAP2ZQYV7BWCNM2EDTAQ33", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "integration test", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516278263", "verifiedAt": "1786516278263"}	2026-08-12 06:31:18.27678+00
01KZTAR37Z30SFHF55CYJP4KF3	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTAR37Z30SFHF55CYJP4KF3", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "integration test", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516344063", "verifiedAt": "1786516344063"}	2026-08-12 06:32:24.079878+00
01KZTARCTSHSCGA01NGXHCHCHN	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTARCTSHSCGA01NGXHCHCHN", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "integration test", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516353881", "verifiedAt": "1786516353881"}	2026-08-12 06:32:35.727527+00
01KZTAWHGPW0WE9XN5N9QC5J98	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTAWHGPW0WE9XN5N9QC5J98", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516489750", "verifiedAt": "1786516489750"}	2026-08-12 06:34:51.593099+00
01KZTAWTQ54CYR8RZVBPVSCAG4	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTAWTQ54CYR8RZVBPVSCAG4", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516499173", "verifiedAt": "1786516499173"}	2026-08-12 06:34:59.186379+00
01KZTAX8BSG7Z1HX8GVN1KKJF0	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTAX8BSG7Z1HX8GVN1KKJF0", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "integration test", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516513145", "verifiedAt": "1786516513145"}	2026-08-12 06:35:13.156838+00
01KZTAYWBKW8VB7BT2EZ4T4GAN	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTAYWBKW8VB7BT2EZ4T4GAN", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516566387", "verifiedAt": "1786516566387"}	2026-08-12 06:36:06.398441+00
01KZTB0T67H5QJRRYJKDM7W8D4	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB0T67H5QJRRYJKDM7W8D4", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516629703", "verifiedAt": "1786516629703"}	2026-08-12 06:37:09.715215+00
01KZTB1B56WTXSBVJNBE887X6Z	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB1B56WTXSBVJNBE887X6Z", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516647078", "verifiedAt": "1786516647078"}	2026-08-12 06:37:27.089009+00
01KZTB1B73XMAHCM3BBC1922QM	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB1B73XMAHCM3BBC1922QM", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516647139", "verifiedAt": "1786516647139"}	2026-08-12 06:37:27.146756+00
01KZTB46B1RHP6DHT7T422EXKG	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB46B1RHP6DHT7T422EXKG", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516740449", "verifiedAt": "1786516740449"}	2026-08-12 06:39:00.459932+00
01KZTB46F88Q6V8PMGV02J21HH	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB46F88Q6V8PMGV02J21HH", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516740584", "verifiedAt": "1786516740584"}	2026-08-12 06:39:00.590627+00
01KZTB46GVC9WT866QJ4M25BFG	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB46GVC9WT866QJ4M25BFG", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516740635", "verifiedAt": "1786516740635"}	2026-08-12 06:39:00.642014+00
01KZTB4WS6N7ZFZM4RH1RNR07V	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB4WS6N7ZFZM4RH1RNR07V", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516763430", "verifiedAt": "1786516763430"}	2026-08-12 06:39:23.440865+00
01KZTB4WWV4501MFF73RBY8GJS	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB4WWV4501MFF73RBY8GJS", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe2", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516763547", "verifiedAt": "1786516763547"}	2026-08-12 06:39:23.553546+00
01KZTB5N1NHJ99V4EQ4YCZXV7T	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB5N1NHJ99V4EQ4YCZXV7T", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe2", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516788277", "verifiedAt": "1786516788277"}	2026-08-12 06:39:48.288777+00
01KZTB5N8JN37J80CPH3BAN0YQ	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB5N8JN37J80CPH3BAN0YQ", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "probe", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516788498", "verifiedAt": "1786516788498"}	2026-08-12 06:39:48.504076+00
01KZTB6CQ2E0PZE5YT8R2VXHCB	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB6CQ2E0PZE5YT8R2VXHCB", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "inline", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516812514", "verifiedAt": "1786516812514"}	2026-08-12 06:40:12.525491+00
01KZTB6CS4VWWTTT4CCA7FSS46	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB6CS4VWWTTT4CCA7FSS46", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "inline", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516812580", "verifiedAt": "1786516812580"}	2026-08-12 06:40:12.586841+00
01KZTB6W4FERAR8G9KPGR0QFZ9	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB6W4FERAR8G9KPGR0QFZ9", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "fresh-only", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516828303", "verifiedAt": "1786516828303"}	2026-08-12 06:40:28.314578+00
01KZTB7R2Z10N0TNVTG5K03MJ4	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB7R2Z10N0TNVTG5K03MJ4", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "compare", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516856927", "verifiedAt": "1786516856927"}	2026-08-12 06:40:56.939729+00
01KZTB7R53R773TJN3HYSBQRN4	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10001	{"id": "01KZTB7R53R773TJN3HYSBQRN4", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "compare2", "amount": "10001", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516856995", "verifiedAt": "1786516856995"}	2026-08-12 06:40:57.001908+00
01KZTB8TG38ED8DQYYRBKQ05HB	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTB8TG38ED8DQYYRBKQ05HB", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "n0", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516892163", "verifiedAt": "1786516892163"}	2026-08-12 06:41:32.175736+00
01KZTB8THZYK059Q2ZPJ9F8R7A	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10001	{"id": "01KZTB8THZYK059Q2ZPJ9F8R7A", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "n1", "amount": "10001", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516892223", "verifiedAt": "1786516892223"}	2026-08-12 06:41:32.230166+00
01KZTBAAS66JK40P8Z1758VSM5	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	20000	{"id": "01KZTBAAS66JK40P8Z1758VSM5", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "via-wallet", "amount": "20000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786516941606", "verifiedAt": "1786516941606"}	2026-08-12 06:42:21.624206+00
01KZTBF7BQWBVTEP0RK6WZMNGC	skillplus-10000002-idr	10000002	DEPOSIT	REJECTED	10000	{"id": "01KZTBF7BQWBVTEP0RK6WZMNGC", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "integration test", "amount": "10000", "status": "WALLET_TX_STATUS_REJECTED", "currency": "IDR", "createdAt": "1786517101943", "verifiedAt": "1786520685273", "verifiedBy": "10000004"}	2026-08-12 07:44:47.110093+00
01KZTBFNK5GKN2GPVKEG9T1VYS	skillplus-10000002-idr	10000002	DEPOSIT	APPROVED	10000	{"id": "01KZTBFNK5GKN2GPVKEG9T1VYS", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "integration test", "amount": "10000", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786517116517", "verifiedAt": "1786517116517"}	2026-08-12 06:45:16.529156+00
01KZTQDWRK588G4T5DH92YEZT9	skillplus-10000002-idr	10000002	WITHDRAW	APPROVED	9680002	{"id": "01KZTQDWRK588G4T5DH92YEZT9", "uid": "10000002", "wid": "skillplus-10000002-idr", "note": "X", "type": "WALLET_TX_TYPE_WITHDRAW", "amount": "9680002", "status": "WALLET_TX_STATUS_APPROVED", "currency": "IDR", "createdAt": "1786529641235", "verifiedAt": "1786529641235", "verifiedBy": "10000004"}	2026-08-12 10:14:03.545095+00
\.


--
-- Name: a_announcement a_announcement_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_announcement
    ADD CONSTRAINT a_announcement_pkey PRIMARY KEY (id);


--
-- Name: a_article a_article_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_article
    ADD CONSTRAINT a_article_pkey PRIMARY KEY (id);


--
-- Name: a_chat_member a_chat_member_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_chat_member
    ADD CONSTRAINT a_chat_member_pkey PRIMARY KEY (cid, uid);


--
-- Name: a_chat_msg a_chat_msg_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_chat_msg
    ADD CONSTRAINT a_chat_msg_pkey PRIMARY KEY (cid, msg_id);


--
-- Name: a_chat a_chat_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_chat
    ADD CONSTRAINT a_chat_pkey PRIMARY KEY (cid);


--
-- Name: a_config a_config_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_config
    ADD CONSTRAINT a_config_pkey PRIMARY KEY (k);


--
-- Name: a_file_bytes a_file_bytes_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_file_bytes
    ADD CONSTRAINT a_file_bytes_pkey PRIMARY KEY (hash);


--
-- Name: a_file a_file_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_file
    ADD CONSTRAINT a_file_pkey PRIMARY KEY (hash);


--
-- Name: a_knowledge a_knowledge_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_knowledge
    ADD CONSTRAINT a_knowledge_pkey PRIMARY KEY (id);


--
-- Name: a_payment_account a_payment_account_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_payment_account
    ADD CONSTRAINT a_payment_account_pkey PRIMARY KEY (id);


--
-- Name: a_product_category a_product_category_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_product_category
    ADD CONSTRAINT a_product_category_pkey PRIMARY KEY (id);


--
-- Name: a_product_tag a_product_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_product_tag
    ADD CONSTRAINT a_product_tag_pkey PRIMARY KEY (id);


--
-- Name: a_slide a_slide_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_slide
    ADD CONSTRAINT a_slide_pkey PRIMARY KEY (id);


--
-- Name: a_user a_user_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_user
    ADD CONSTRAINT a_user_pkey PRIMARY KEY (uid);


--
-- Name: platform_app_version platform_app_version_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.platform_app_version
    ADD CONSTRAINT platform_app_version_pkey PRIMARY KEY (platform, version);


--
-- Name: s_jadwal s_jadwal_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.s_jadwal
    ADD CONSTRAINT s_jadwal_pkey PRIMARY KEY (id);


--
-- Name: s_kursus s_kursus_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.s_kursus
    ADD CONSTRAINT s_kursus_pkey PRIMARY KEY (id);


--
-- Name: s_reservasi_item s_reservasi_item_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.s_reservasi_item
    ADD CONSTRAINT s_reservasi_item_pkey PRIMARY KEY (reservasi_id, item_id);


--
-- Name: s_reservasi s_reservasi_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.s_reservasi
    ADD CONSTRAINT s_reservasi_pkey PRIMARY KEY (id);


--
-- Name: u_access u_access_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.u_access
    ADD CONSTRAINT u_access_pkey PRIMARY KEY (uid);


--
-- Name: u_asset_access u_asset_access_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.u_asset_access
    ADD CONSTRAINT u_asset_access_pkey PRIMARY KEY (uid, asset_type, asset_id);


--
-- Name: u_auth_google u_auth_google_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.u_auth_google
    ADD CONSTRAINT u_auth_google_pkey PRIMARY KEY (sub);


--
-- Name: u_auth_password u_auth_password_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.u_auth_password
    ADD CONSTRAINT u_auth_password_pkey PRIMARY KEY (uid);


--
-- Name: u_fcm u_fcm_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.u_fcm
    ADD CONSTRAINT u_fcm_pkey PRIMARY KEY (uid, client_id);


--
-- Name: u_notif_sent u_notif_sent_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.u_notif_sent
    ADD CONSTRAINT u_notif_sent_pkey PRIMARY KEY (dedup_key);


--
-- Name: u_review u_review_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.u_review
    ADD CONSTRAINT u_review_pkey PRIMARY KEY (id);


--
-- Name: u_wallet_hold u_wallet_hold_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.u_wallet_hold
    ADD CONSTRAINT u_wallet_hold_pkey PRIMARY KEY (ref_type, ref_id, wid);


--
-- Name: u_wallet u_wallet_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.u_wallet
    ADD CONSTRAINT u_wallet_pkey PRIMARY KEY (wid);


--
-- Name: u_wallet_tx u_wallet_tx_pkey; Type: CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.u_wallet_tx
    ADD CONSTRAINT u_wallet_tx_pkey PRIMARY KEY (wid, id);


--
-- Name: a_chat_reservasi_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE UNIQUE INDEX a_chat_reservasi_idx ON public.a_chat USING lsm (reservasi_id HASH) WHERE (reservasi_id <> ''::text);


--
-- Name: a_product_category_parent_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX a_product_category_parent_idx ON public.a_product_category USING lsm (parent_id HASH);


--
-- Name: a_user_alien_id_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE UNIQUE INDEX a_user_alien_id_idx ON public.a_user USING lsm (alien_id HASH) WHERE (alien_id <> ''::text);


--
-- Name: s_jadwal_geo_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX s_jadwal_geo_idx ON public.s_jadwal USING lsm (geo_lat HASH, geo_lng ASC) WHERE ((geo_lat IS NOT NULL) AND (geo_lng IS NOT NULL));


--
-- Name: s_jadwal_kursus_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX s_jadwal_kursus_idx ON public.s_jadwal USING lsm (kursus_id HASH) WHERE (is_archived = false);


--
-- Name: s_kursus_bookable_list_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX s_kursus_bookable_list_idx ON public.s_kursus USING lsm (has_bookable_slots DESC, next_bookable_at ASC, id ASC);


--
-- Name: s_kursus_geo_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX s_kursus_geo_idx ON public.s_kursus USING lsm (geo_lat HASH, geo_lng ASC) WHERE ((geo_lat IS NOT NULL) AND (geo_lng IS NOT NULL));


--
-- Name: s_kursus_search_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX s_kursus_search_idx ON public.s_kursus USING ybgin (search);


--
-- Name: s_kursus_tutor_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX s_kursus_tutor_idx ON public.s_kursus USING lsm (tutor_uid HASH) WHERE (is_archived = false);


--
-- Name: s_reservasi_student_ts_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX s_reservasi_student_ts_idx ON public.s_reservasi USING lsm (student_uid HASH, ts DESC);


--
-- Name: s_reservasi_tutor_ts_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX s_reservasi_tutor_ts_idx ON public.s_reservasi USING lsm (tutor_uid HASH, ts DESC);


--
-- Name: u_asset_access_asset_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX u_asset_access_asset_idx ON public.u_asset_access USING lsm (asset_type HASH, asset_id ASC);


--
-- Name: u_auth_google_email_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX u_auth_google_email_idx ON public.u_auth_google USING lsm (lower(email) HASH) WHERE (email <> ''::text);


--
-- Name: u_auth_google_uid_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE UNIQUE INDEX u_auth_google_uid_idx ON public.u_auth_google USING lsm (uid HASH);


--
-- Name: u_review_asset_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX u_review_asset_idx ON public.u_review USING lsm (asset_type HASH, asset_id ASC);


--
-- Name: u_review_reviewer_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX u_review_reviewer_idx ON public.u_review USING lsm (reviewer_uid HASH, ts DESC);


--
-- Name: u_wallet_tx_uid_ts_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX u_wallet_tx_uid_ts_idx ON public.u_wallet_tx USING lsm (uid HASH, ts DESC);


--
-- Name: u_wallet_uid_idx; Type: INDEX; Schema: public; Owner: csa
--

CREATE INDEX u_wallet_uid_idx ON public.u_wallet USING lsm (uid HASH);


--
-- Name: a_file_bytes a_file_bytes_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.a_file_bytes
    ADD CONSTRAINT a_file_bytes_hash_fkey FOREIGN KEY (hash) REFERENCES public.a_file(hash) ON DELETE CASCADE;


--
-- Name: u_auth_google u_auth_google_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.u_auth_google
    ADD CONSTRAINT u_auth_google_uid_fkey FOREIGN KEY (uid) REFERENCES public.a_user(uid) ON DELETE CASCADE;


--
-- Name: u_auth_password u_auth_password_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: csa
--

ALTER TABLE ONLY public.u_auth_password
    ADD CONSTRAINT u_auth_password_uid_fkey FOREIGN KEY (uid) REFERENCES public.a_user(uid) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO csa;


--
-- PostgreSQL database dump complete
--


--
