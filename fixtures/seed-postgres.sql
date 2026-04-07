-- flat-white fixture data (seed-postgres.sql)
-- Generated: 2026-04-02
-- Source: G-NAF February 2026 (GDA2020), gnaf-loader v202602
-- Fixture: 451 VIC addresses covering all edge case categories
--
-- Load: docker compose exec db psql -U postgres -d gnaf -f /fixtures/seed-postgres.sql
-- Time: <30 seconds on commodity hardware
--
-- This file captures gnaf-loader's exact output schema + a subset of data.
-- If gnaf-loader changes its schema, this file becomes incompatible -> drift detected.
--
-- Structure:
--   1. Drop existing schemas (clean slate)
--   1A. Schema + table creation — gnaf_202602 (processed)
--   1B. Schema + table creation — raw_gnaf_202602 (raw, for flatten pipeline)
--   2. Data load (COPY) — processed tables
--   2B. Data load (COPY) — raw tables
--   3. Constraints + indexes

-- Clean slate — drop if exists
DROP SCHEMA IF EXISTS gnaf_202602 CASCADE;
DROP SCHEMA IF EXISTS raw_gnaf_202602 CASCADE;
DROP SCHEMA IF EXISTS admin_bdys_202602 CASCADE;

-- ============================================
-- PART 1: Schema + table creation
-- ============================================
--
-- PostgreSQL database dump
--


-- Dumped from database version 16.10 (Debian 16.10-1.pgdg12+1)
-- Dumped by pg_dump version 16.10 (Debian 16.10-1.pgdg12+1)

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
-- Name: gnaf_202602; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA gnaf_202602;


SET default_table_access_method = heap;

--
-- Name: address_alias_admin_boundaries; Type: TABLE; Schema: gnaf_202602; Owner: -
--

CREATE TABLE gnaf_202602.address_alias_admin_boundaries (
    gid integer NOT NULL,
    gnaf_pid text NOT NULL,
    locality_pid text NOT NULL,
    locality_name text NOT NULL,
    postcode text,
    state text NOT NULL,
    ce_pid text,
    ce_name text,
    lga_pid text,
    lga_name text,
    ward_pid text,
    ward_name text,
    se_lower_pid text,
    se_lower_name text,
    se_upper_pid text,
    se_upper_name text
);


--
-- Name: address_principal_admin_boundaries; Type: TABLE; Schema: gnaf_202602; Owner: -
--

CREATE TABLE gnaf_202602.address_principal_admin_boundaries (
    gid integer NOT NULL,
    gnaf_pid text NOT NULL,
    locality_pid text NOT NULL,
    locality_name text NOT NULL,
    postcode text,
    state text NOT NULL,
    ce_pid text,
    ce_name text,
    lga_pid text,
    lga_name text,
    ward_pid text,
    ward_name text,
    se_lower_pid text,
    se_lower_name text,
    se_upper_pid text,
    se_upper_name text
);


--
-- Name: address_admin_boundaries; Type: VIEW; Schema: gnaf_202602; Owner: -
--

CREATE VIEW gnaf_202602.address_admin_boundaries AS
 SELECT address_principal_admin_boundaries.gid,
    address_principal_admin_boundaries.gnaf_pid,
    address_principal_admin_boundaries.locality_pid,
    address_principal_admin_boundaries.locality_name,
    address_principal_admin_boundaries.postcode,
    address_principal_admin_boundaries.state,
    address_principal_admin_boundaries.ce_pid,
    address_principal_admin_boundaries.ce_name,
    address_principal_admin_boundaries.lga_pid,
    address_principal_admin_boundaries.lga_name,
    address_principal_admin_boundaries.ward_pid,
    address_principal_admin_boundaries.ward_name,
    address_principal_admin_boundaries.se_lower_pid,
    address_principal_admin_boundaries.se_lower_name,
    address_principal_admin_boundaries.se_upper_pid,
    address_principal_admin_boundaries.se_upper_name
   FROM gnaf_202602.address_principal_admin_boundaries
UNION ALL
 SELECT address_alias_admin_boundaries.gid,
    address_alias_admin_boundaries.gnaf_pid,
    address_alias_admin_boundaries.locality_pid,
    address_alias_admin_boundaries.locality_name,
    address_alias_admin_boundaries.postcode,
    address_alias_admin_boundaries.state,
    address_alias_admin_boundaries.ce_pid,
    address_alias_admin_boundaries.ce_name,
    address_alias_admin_boundaries.lga_pid,
    address_alias_admin_boundaries.lga_name,
    address_alias_admin_boundaries.ward_pid,
    address_alias_admin_boundaries.ward_name,
    address_alias_admin_boundaries.se_lower_pid,
    address_alias_admin_boundaries.se_lower_name,
    address_alias_admin_boundaries.se_upper_pid,
    address_alias_admin_boundaries.se_upper_name
   FROM gnaf_202602.address_alias_admin_boundaries;


--
-- Name: address_alias_admin_boundaries_gid_seq; Type: SEQUENCE; Schema: gnaf_202602; Owner: -
--

CREATE SEQUENCE gnaf_202602.address_alias_admin_boundaries_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: address_alias_admin_boundaries_gid_seq; Type: SEQUENCE OWNED BY; Schema: gnaf_202602; Owner: -
--

ALTER SEQUENCE gnaf_202602.address_alias_admin_boundaries_gid_seq OWNED BY gnaf_202602.address_alias_admin_boundaries.gid;


--
-- Name: address_alias_lookup; Type: TABLE; Schema: gnaf_202602; Owner: -
--

CREATE TABLE gnaf_202602.address_alias_lookup (
    principal_pid text NOT NULL,
    alias_pid text NOT NULL,
    alias_type text NOT NULL
);


--
-- Name: address_aliases; Type: TABLE; Schema: gnaf_202602; Owner: -
--

CREATE TABLE gnaf_202602.address_aliases (
    gid integer NOT NULL,
    gnaf_pid text NOT NULL,
    street_locality_pid text NOT NULL,
    locality_pid text NOT NULL,
    alias_principal character(1) NOT NULL,
    primary_secondary text,
    building_name text,
    lot_number text,
    flat_number text,
    level_number text,
    number_first text,
    number_last text,
    street_name text NOT NULL,
    street_type text,
    street_suffix text,
    address text NOT NULL,
    locality_name text NOT NULL,
    postcode text,
    state text NOT NULL,
    locality_postcode text,
    confidence smallint NOT NULL,
    legal_parcel_id text,
    mb_2016_code bigint,
    mb_2021_code bigint,
    latitude numeric(10,8) NOT NULL,
    longitude numeric(11,8) NOT NULL,
    geocode_type text NOT NULL,
    reliability smallint NOT NULL,
    geom public.geometry(Point,7844) NOT NULL
);


--
-- Name: address_aliases_gid_seq; Type: SEQUENCE; Schema: gnaf_202602; Owner: -
--

CREATE SEQUENCE gnaf_202602.address_aliases_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: address_aliases_gid_seq; Type: SEQUENCE OWNED BY; Schema: gnaf_202602; Owner: -
--

ALTER SEQUENCE gnaf_202602.address_aliases_gid_seq OWNED BY gnaf_202602.address_aliases.gid;


--
-- Name: address_principals; Type: TABLE; Schema: gnaf_202602; Owner: -
--

CREATE TABLE gnaf_202602.address_principals (
    gid integer NOT NULL,
    gnaf_pid text NOT NULL,
    street_locality_pid text NOT NULL,
    locality_pid text NOT NULL,
    alias_principal character(1) NOT NULL,
    primary_secondary text,
    building_name text,
    lot_number text,
    flat_number text,
    level_number text,
    number_first text,
    number_last text,
    street_name text NOT NULL,
    street_type text,
    street_suffix text,
    address text NOT NULL,
    locality_name text NOT NULL,
    postcode text,
    state text NOT NULL,
    locality_postcode text,
    confidence smallint NOT NULL,
    legal_parcel_id text,
    mb_2016_code bigint,
    mb_2021_code bigint,
    latitude numeric(10,8) NOT NULL,
    longitude numeric(11,8) NOT NULL,
    geocode_type text NOT NULL,
    reliability smallint NOT NULL,
    geom public.geometry(Point,7844) NOT NULL
);


--
-- Name: address_mb_lookup; Type: VIEW; Schema: gnaf_202602; Owner: -
--

CREATE VIEW gnaf_202602.address_mb_lookup AS
 SELECT address_principals.gnaf_pid,
    address_principals.mb_2021_code
   FROM gnaf_202602.address_principals
UNION ALL
 SELECT address_aliases.gnaf_pid,
    address_aliases.mb_2021_code
   FROM gnaf_202602.address_aliases;


--
-- Name: address_principal_admin_boundaries_gid_seq; Type: SEQUENCE; Schema: gnaf_202602; Owner: -
--

CREATE SEQUENCE gnaf_202602.address_principal_admin_boundaries_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: address_principal_admin_boundaries_gid_seq; Type: SEQUENCE OWNED BY; Schema: gnaf_202602; Owner: -
--

ALTER SEQUENCE gnaf_202602.address_principal_admin_boundaries_gid_seq OWNED BY gnaf_202602.address_principal_admin_boundaries.gid;


--
-- Name: address_principals_gid_seq; Type: SEQUENCE; Schema: gnaf_202602; Owner: -
--

CREATE SEQUENCE gnaf_202602.address_principals_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: address_principals_gid_seq; Type: SEQUENCE OWNED BY; Schema: gnaf_202602; Owner: -
--

ALTER SEQUENCE gnaf_202602.address_principals_gid_seq OWNED BY gnaf_202602.address_principals.gid;


--
-- Name: address_secondary_lookup; Type: TABLE; Schema: gnaf_202602; Owner: -
--

CREATE TABLE gnaf_202602.address_secondary_lookup (
    primary_pid text NOT NULL,
    secondary_pid text NOT NULL,
    join_type text NOT NULL
);


--
-- Name: addresses; Type: VIEW; Schema: gnaf_202602; Owner: -
--

CREATE VIEW gnaf_202602.addresses AS
 SELECT address_principals.gid,
    address_principals.gnaf_pid,
    address_principals.street_locality_pid,
    address_principals.locality_pid,
    address_principals.alias_principal,
    address_principals.primary_secondary,
    address_principals.building_name,
    address_principals.lot_number,
    address_principals.flat_number,
    address_principals.level_number,
    address_principals.number_first,
    address_principals.number_last,
    address_principals.street_name,
    address_principals.street_type,
    address_principals.street_suffix,
    address_principals.address,
    address_principals.locality_name,
    address_principals.postcode,
    address_principals.state,
    address_principals.locality_postcode,
    address_principals.confidence,
    address_principals.legal_parcel_id,
    address_principals.mb_2016_code,
    address_principals.mb_2021_code,
    address_principals.latitude,
    address_principals.longitude,
    address_principals.geocode_type,
    address_principals.reliability,
    address_principals.geom
   FROM gnaf_202602.address_principals
UNION ALL
 SELECT address_aliases.gid,
    address_aliases.gnaf_pid,
    address_aliases.street_locality_pid,
    address_aliases.locality_pid,
    address_aliases.alias_principal,
    address_aliases.primary_secondary,
    address_aliases.building_name,
    address_aliases.lot_number,
    address_aliases.flat_number,
    address_aliases.level_number,
    address_aliases.number_first,
    address_aliases.number_last,
    address_aliases.street_name,
    address_aliases.street_type,
    address_aliases.street_suffix,
    address_aliases.address,
    address_aliases.locality_name,
    address_aliases.postcode,
    address_aliases.state,
    address_aliases.locality_postcode,
    address_aliases.confidence,
    address_aliases.legal_parcel_id,
    address_aliases.mb_2016_code,
    address_aliases.mb_2021_code,
    address_aliases.latitude,
    address_aliases.longitude,
    address_aliases.geocode_type,
    address_aliases.reliability,
    address_aliases.geom
   FROM gnaf_202602.address_aliases;


--
-- Name: localities; Type: TABLE; Schema: gnaf_202602; Owner: -
--

CREATE TABLE gnaf_202602.localities (
    gid integer NOT NULL,
    locality_pid text NOT NULL,
    locality_name text NOT NULL,
    postcode text,
    state text NOT NULL,
    std_locality_name text DEFAULT ''::text NOT NULL,
    latitude numeric(10,8),
    longitude numeric(11,8),
    locality_class text NOT NULL,
    reliability smallint DEFAULT 6 NOT NULL,
    address_count integer DEFAULT 0 NOT NULL,
    street_count integer DEFAULT 0 NOT NULL,
    has_boundary character(1) DEFAULT 'N'::bpchar NOT NULL,
    unique_locality_state character(1) DEFAULT 'N'::bpchar NOT NULL,
    geom public.geometry(Point,7844)
);


--
-- Name: localities_gid_seq; Type: SEQUENCE; Schema: gnaf_202602; Owner: -
--

CREATE SEQUENCE gnaf_202602.localities_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: localities_gid_seq; Type: SEQUENCE OWNED BY; Schema: gnaf_202602; Owner: -
--

ALTER SEQUENCE gnaf_202602.localities_gid_seq OWNED BY gnaf_202602.localities.gid;


--
-- Name: locality_aliases; Type: TABLE; Schema: gnaf_202602; Owner: -
--

CREATE TABLE gnaf_202602.locality_aliases (
    locality_pid text NOT NULL,
    locality_name text NOT NULL,
    postcode text,
    state text NOT NULL,
    locality_alias_name text NOT NULL,
    std_alias_name text NOT NULL,
    alias_type text,
    unique_alias_state character(1) NOT NULL
);


--
-- Name: locality_neighbour_lookup; Type: TABLE; Schema: gnaf_202602; Owner: -
--

CREATE TABLE gnaf_202602.locality_neighbour_lookup (
    locality_pid text NOT NULL,
    neighbour_locality_pid text NOT NULL
);


--
-- Name: qa; Type: TABLE; Schema: gnaf_202602; Owner: -
--

CREATE TABLE gnaf_202602.qa (
    table_name text,
    aus integer,
    act integer,
    nsw integer,
    nt integer,
    ot integer,
    qld integer,
    sa integer,
    tas integer,
    vic integer,
    wa integer
);


--
-- Name: street_aliases; Type: TABLE; Schema: gnaf_202602; Owner: -
--

CREATE TABLE gnaf_202602.street_aliases (
    gid integer NOT NULL,
    street_locality_pid text NOT NULL,
    alias_street_name text NOT NULL,
    alias_street_type text,
    alias_street_suffix text,
    full_alias_street_name text NOT NULL,
    alias_type text
);


--
-- Name: street_aliases_gid_seq; Type: SEQUENCE; Schema: gnaf_202602; Owner: -
--

CREATE SEQUENCE gnaf_202602.street_aliases_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: street_aliases_gid_seq; Type: SEQUENCE OWNED BY; Schema: gnaf_202602; Owner: -
--

ALTER SEQUENCE gnaf_202602.street_aliases_gid_seq OWNED BY gnaf_202602.street_aliases.gid;


--
-- Name: streets; Type: TABLE; Schema: gnaf_202602; Owner: -
--

CREATE TABLE gnaf_202602.streets (
    gid integer NOT NULL,
    street_locality_pid text NOT NULL,
    locality_pid text NOT NULL,
    street_name text NOT NULL,
    street_type text,
    street_suffix text,
    full_street_name text NOT NULL,
    locality_name text NOT NULL,
    postcode text,
    state text NOT NULL,
    street_type_abbrev text,
    street_suffix_abbrev text,
    street_class text,
    latitude numeric(10,8),
    longitude numeric(11,8),
    reliability smallint DEFAULT 4 NOT NULL,
    address_count integer DEFAULT 0 NOT NULL,
    geom public.geometry(Point,7844)
);


--
-- Name: streets_gid_seq; Type: SEQUENCE; Schema: gnaf_202602; Owner: -
--

CREATE SEQUENCE gnaf_202602.streets_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: streets_gid_seq; Type: SEQUENCE OWNED BY; Schema: gnaf_202602; Owner: -
--

ALTER SEQUENCE gnaf_202602.streets_gid_seq OWNED BY gnaf_202602.streets.gid;


--
-- Name: address_alias_admin_boundaries gid; Type: DEFAULT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_alias_admin_boundaries ALTER COLUMN gid SET DEFAULT nextval('gnaf_202602.address_alias_admin_boundaries_gid_seq'::regclass);


--
-- Name: address_aliases gid; Type: DEFAULT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_aliases ALTER COLUMN gid SET DEFAULT nextval('gnaf_202602.address_aliases_gid_seq'::regclass);


--
-- Name: address_principal_admin_boundaries gid; Type: DEFAULT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_principal_admin_boundaries ALTER COLUMN gid SET DEFAULT nextval('gnaf_202602.address_principal_admin_boundaries_gid_seq'::regclass);


--
-- Name: address_principals gid; Type: DEFAULT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_principals ALTER COLUMN gid SET DEFAULT nextval('gnaf_202602.address_principals_gid_seq'::regclass);


--
-- Name: localities gid; Type: DEFAULT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.localities ALTER COLUMN gid SET DEFAULT nextval('gnaf_202602.localities_gid_seq'::regclass);


--
-- Name: street_aliases gid; Type: DEFAULT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.street_aliases ALTER COLUMN gid SET DEFAULT nextval('gnaf_202602.street_aliases_gid_seq'::regclass);


--
-- Name: streets gid; Type: DEFAULT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.streets ALTER COLUMN gid SET DEFAULT nextval('gnaf_202602.streets_gid_seq'::regclass);


--
-- PostgreSQL database dump complete
--



-- ============================================
-- ============================================
-- PART 1B: Raw tables schema (for flatten pipeline)
-- These tables provide: allGeocodes[], flat/level/street type
-- expansion, and geocode type names.
-- ============================================

CREATE SCHEMA raw_gnaf_202602;

--
-- PostgreSQL database dump
--


-- Dumped from database version 16.10 (Debian 16.10-1.pgdg12+1)
-- Dumped by pg_dump version 16.10 (Debian 16.10-1.pgdg12+1)

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

SET default_table_access_method = heap;

--
-- Name: address_alias_type_aut; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.address_alias_type_aut (
    code character varying(10) NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(30)
);


--
-- Name: address_default_geocode; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.address_default_geocode (
    address_default_geocode_pid character varying(15) NOT NULL,
    date_created date NOT NULL,
    date_retired date,
    address_detail_pid character varying(15) NOT NULL,
    geocode_type_code character varying(4) NOT NULL,
    longitude numeric(11,8),
    latitude numeric(10,8)
);


--
-- Name: address_detail; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.address_detail (
    address_detail_pid character varying(15) NOT NULL,
    date_created date NOT NULL,
    date_last_modified date,
    date_retired date,
    building_name character varying(100),
    lot_number_prefix character varying(2),
    lot_number character varying(5),
    lot_number_suffix character varying(2),
    flat_type_code character varying(7),
    flat_number_prefix character varying(2),
    flat_number numeric(5,0),
    flat_number_suffix character varying(2),
    level_type_code character varying(4),
    level_number_prefix character varying(2),
    level_number numeric(3,0),
    level_number_suffix character varying(2),
    number_first_prefix character varying(3),
    number_first numeric(6,0),
    number_first_suffix character varying(2),
    number_last_prefix character varying(3),
    number_last numeric(6,0),
    number_last_suffix character varying(2),
    street_locality_pid character varying(15),
    location_description character varying(45),
    locality_pid character varying(15) NOT NULL,
    alias_principal character(1),
    postcode character varying(4),
    private_street character varying(75),
    legal_parcel_id character varying(20),
    confidence numeric(1,0),
    address_site_pid character varying(15) NOT NULL,
    level_geocoded_code numeric(2,0) NOT NULL,
    property_pid character varying(15),
    gnaf_property_pid character varying(15),
    primary_secondary character varying(1)
);


--
-- Name: address_site; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.address_site (
    address_site_pid character varying(15) NOT NULL,
    date_created date NOT NULL,
    date_retired date,
    address_type character varying(8),
    address_site_name character varying(45)
);


--
-- Name: address_site_geocode; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.address_site_geocode (
    address_site_geocode_pid character varying(15) NOT NULL,
    date_created date NOT NULL,
    date_retired date,
    address_site_pid character varying(15),
    geocode_site_name character varying(46),
    geocode_site_description character varying(45),
    geocode_type_code character varying(4),
    reliability_code numeric(1,0) NOT NULL,
    boundary_extent numeric(7,0),
    planimetric_accuracy numeric(12,0),
    elevation numeric(7,0),
    longitude numeric(11,8),
    latitude numeric(10,8)
);


--
-- Name: address_type_aut; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.address_type_aut (
    code character varying(8) NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(30)
);


--
-- Name: flat_type_aut; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.flat_type_aut (
    code character varying(7) NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(30)
);


--
-- Name: geocode_reliability_aut; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.geocode_reliability_aut (
    code numeric(1,0) NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(100)
);


--
-- Name: geocode_type_aut; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.geocode_type_aut (
    code character varying(4) NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(250)
);


--
-- Name: level_type_aut; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.level_type_aut (
    code character varying(4) NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(30)
);


--
-- Name: locality_class_aut; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.locality_class_aut (
    code character(1) NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(200)
);


--
-- Name: street_class_aut; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.street_class_aut (
    code character(1) NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(200)
);


--
-- Name: street_suffix_aut; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.street_suffix_aut (
    code character varying(15) NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(30)
);


--
-- Name: street_type_aut; Type: TABLE; Schema: raw_gnaf_202602; Owner: -
--

CREATE TABLE raw_gnaf_202602.street_type_aut (
    code character varying(15) NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(15)
);


--
-- PostgreSQL database dump complete
--


-- ============================================
-- ============================================
-- PART 1C: ABS mesh block lookup (for SA1-SA4, GCCSA, MB category)
-- Lightweight table WITHOUT geometry — only the columns the flatten pipeline needs.
-- The flatten pipeline joins address_principals.mb_2021_code → mb21_code.
-- ============================================

CREATE SCHEMA IF NOT EXISTS admin_bdys_202602;

CREATE TABLE admin_bdys_202602.abs_2021_mb_lookup (
    mb21_code bigint NOT NULL,
    mb_cat text,
    sa1_21code character varying(11),
    sa2_21code character varying(9),
    sa2_21name text,
    sa3_21code character varying(5),
    sa3_21name text,
    sa4_21code character varying(3),
    sa4_21name text,
    gcc_21code text,
    gcc_21name text,
    state text
);


-- PART 2: Fixture data (451 addresses + related)
-- ============================================

-- gnaf_202602.localities: 267 rows
\copy gnaf_202602.localities FROM stdin
2552	loce0707ac065f9	THOMSON	3219	VIC	THOMSON	-38.16949782	144.37893641	GAZETTED LOCALITY	5	1193	53	Y	N	0101000020A41E0000D606403F200C624057D2C41AB21543C0
2998	loc9901d119afda_2	MELBOURNE	3004	VIC	MELBOURNE	-37.83356762	144.97757127	GAZETTED LOCALITY	5	17524	69	Y	N	0101000020A41E000018458B43481F6240C8730158B2EA42C0
2611	loc1c5f2c23fc52	TOWONG	3707	VIC	TOWONG	-36.12948539	147.97111114	GAZETTED LOCALITY	5	98	24	Y	Y	0101000020A41E00009A62AB57137F62400EAE2DFA921042C0
2377	loc34a55c4d0462	ST ALBANS	3021	VIC	SAINT ALBANS	-37.74536136	144.80528340	GAZETTED LOCALITY	5	18355	412	Y	Y	0101000020A41E00006060B1E1C41962407773440068DF42C0
2400	locfe955a87410d	ST KILDA	3182	VIC	SAINT KILDA	-37.86368633	144.98179855	GAZETTED LOCALITY	5	21928	179	Y	Y	0101000020A41E000054F0CAE46A1F624017AD0E468DEE42C0
2403	loc2c9ce0acd6de	ST LEONARDS	3223	VIC	SAINT LEONARDS	-38.17820978	144.68545247	GAZETTED LOCALITY	5	5605	199	Y	Y	0101000020A41E000099B3043AEF156240B476FC93CF1643C0
370	loc79e45c9fa669	BRUNSWICK EAST	3057	VIC	EAST BRUNSWICK	-37.76886491	144.97743275	GAZETTED LOCALITY	5	10460	124	Y	Y	0101000020A41E000042E90B21471F6240F9BE552A6AE242C0
674	locae977e7a8d83	CRANBOURNE EAST	3977	VIC	EAST CRANBOURNE	-38.11002714	145.30545117	GAZETTED LOCALITY	5	9928	520	Y	Y	0101000020A41E000099358841C629624078FC8B5E150E43C0
782	loc7a8164839d54	DONCASTER EAST	3109	VIC	EAST DONCASTER	-37.77896240	145.16391985	GAZETTED LOCALITY	5	15565	481	Y	Y	0101000020A41E00004A5DD7D43E2562402668380AB5E342C0
1172	loc4fa4b090ce9e	HAWTHORN EAST	3123	VIC	EAST HAWTHORN	-37.83118944	145.05007851	GAZETTED LOCALITY	5	10360	166	Y	Y	0101000020A41E0000D6553F3E9A21624050CA626A64EA42C0
1268	locb17fb225139f	IVANHOE EAST	3079	VIC	EAST IVANHOE	-37.77346492	145.06182246	GAZETTED LOCALITY	5	2142	63	Y	Y	0101000020A41E0000777B1873FA2162406B0004E600E342C0
1614	loc2d817b7080e2	MALVERN EAST	3145	VIC	EAST MALVERN	-37.87662110	145.06540291	GAZETTED LOCALITY	5	14151	265	Y	Y	0101000020A41E00006CF0D7C717226240E5BDC51E35F042C0
1926	loc4e07cec4cde4	NARRE WARREN EAST	3804	VIC	EAST NARRE WARREN	-37.96317606	145.35948455	GAZETTED LOCALITY	5	160	27	Y	Y	0101000020A41E00005A35BEE5802B6240BDFE665A49FB42C0
2210	loc46f8f01fbac9	RINGWOOD EAST	3135	VIC	EAST RINGWOOD	-37.81331501	145.25356410	GAZETTED LOCALITY	5	5677	161	Y	Y	0101000020A41E0000129E75321D286240E0A5CCB41AE842C0
2618	loc8f498b475ec6	TRARALGON EAST	3844	VIC	EAST TRARALGON	-38.18715216	146.58935850	GAZETTED LOCALITY	5	1102	81	Y	Y	0101000020A41E0000D4635B06DC526240B2491B9AF41743C0
2721	loc2424df148d7d	WANDIN EAST	3139	VIC	EAST WANDIN	-37.81232135	145.45489002	GAZETTED LOCALITY	5	209	20	Y	Y	0101000020A41E0000A8E583758E2E6240D90B6025FAE742C0
2401	loc695c9ddc8068	ST KILDA EAST	3183	VIC	EAST ST KILDA	-37.86678876	145.00212681	GAZETTED LOCALITY	5	8691	145	Y	Y	0101000020A41E0000A26C3E6C11206240C55E20EFF2EE42C0
371	loc11b2a92fb5f0	BRUNSWICK WEST	3055	VIC	WEST BRUNSWICK	-37.76311279	144.94284505	GAZETTED LOCALITY	5	10241	166	Y	Y	0101000020A41E000041DE61C92B1E6240CB1A0EAEADE142C0
677	loc9ea2b366d63f	CRANBOURNE WEST	3977	VIC	WEST CRANBOURNE	-38.09941751	145.24951306	GAZETTED LOCALITY	5	8969	400	Y	Y	0101000020A41E0000FF13D002FC276240C50C85B6B90C43C0
988	loc910a14938d48	GEELONG WEST	3218	VIC	WEST GEELONG	-38.13936488	144.34488917	GAZETTED LOCALITY	5	5114	133	Y	Y	0101000020A41E0000A03C0355090B6240CEE758B5D61143C0
1189	loc1492a23dbc74	HEIDELBERG WEST	3081	VIC	WEST HEIDELBERG	-37.73815197	145.04351165	GAZETTED LOCALITY	5	4972	109	Y	Y	0101000020A41E0000D7378B7264216240615085C37BDE42C0
2442	loc46443686a430	SUNSHINE WEST	3020	VIC	WEST SUNSHINE	-37.79808760	144.81108236	GAZETTED LOCALITY	5	9102	309	Y	Y	0101000020A41E00000052FE62F4196240ECAB06BC27E642C0
37	loc08caad3924ee	ALTONA NORTH	3025	VIC	NORTH ALTONA	-37.83782838	144.83433143	GAZETTED LOCALITY	5	8471	248	Y	Y	0101000020A41E0000FFBBD3D7B21A62405DE1D9F53DEB42C0
126	loc0621c45c46f4	BALWYN NORTH	3104	VIC	NORTH BALWYN	-37.79174580	145.08433919	GAZETTED LOCALITY	5	9453	282	Y	Y	0101000020A41E000047DA19E8B222624068DF26ED57E542C0
178	loc9165cd64854f	BAYSWATER NORTH	3153	VIC	NORTH BAYSWATER	-37.82688124	145.28366402	GAZETTED LOCALITY	5	5631	149	Y	Y	0101000020A41E0000761E91C613296240EBBC953ED7E942C0
256	loc786911d8fa57	BLACKBURN NORTH	3130	VIC	NORTH BLACKBURN	-37.80536979	145.15435592	GAZETTED LOCALITY	5	3376	129	Y	Y	0101000020A41E0000028BD37BF0246240429E765B16E742C0
675	loc9fe59dbd0874	CRANBOURNE NORTH	3977	VIC	NORTH CRANBOURNE	-38.07751044	145.29878122	GAZETTED LOCALITY	5	8873	415	Y	Y	0101000020A41E0000E311A29D8F2962400473B2DCEB0943C0
719	locd755ccb7197e	DANDENONG NORTH	3175	VIC	NORTH DANDENONG	-37.95584876	145.21409050	GAZETTED LOCALITY	5	9748	366	Y	Y	0101000020A41E00004CFC51D4D9266240A30F8E4059FA42C0
962	locf57f2052e543	FRANKSTON NORTH	3200	VIC	NORTH FRANKSTON	-38.12391087	145.16386270	GAZETTED LOCALITY	5	2853	139	Y	Y	0101000020A41E00001931FD5C3E2562406C22B74FDC0F43C0
1761	loca1efec8fa041	MONT ALBERT NORTH	3129	VIC	NORTH MONT ALBERT	-37.80330984	145.11080914	GAZETTED LOCALITY	5	2778	90	Y	Y	0101000020A41E0000BB0C9CBF8B23624070AD59DBD2E642C0
194	locb281644d861d	BELGRAVE SOUTH	3160	VIC	SOUTH BELGRAVE	-37.94246879	145.35731473	GAZETTED LOCALITY	5	672	52	Y	Y	0101000020A41E000055F74C1F6F2B62407D463BD1A2F842C0
323	loc6ae7eaa3c1f3	BOX HILL SOUTH	3128	VIC	SOUTH BOX HILL	-37.83660617	145.12337998	GAZETTED LOCALITY	5	4586	149	Y	Y	0101000020A41E0000996292BAF223624013E435E915EB42C0
533	loc1b5a0e70afd4	CAULFIELD SOUTH	3162	VIC	SOUTH CAULFIELD	-37.89465354	145.02492847	GAZETTED LOCALITY	5	6707	148	Y	Y	0101000020A41E0000756CCA36CC2062407BC6D70184F242C0
1016	loc630ef4fec09d	GISBORNE SOUTH	3437	VIC	SOUTH GISBORNE	-37.54876343	144.62450046	GAZETTED LOCALITY	5	356	38	Y	Y	0101000020A41E00002F8163E8FB1362409F8B4CE13DC642C0
1928	loc6280f9052ec0	NARRE WARREN SOUTH	3805	VIC	SOUTH NARRE WARREN	-38.05530003	145.30251506	GAZETTED LOCALITY	5	10228	497	Y	Y	0101000020A41E0000EB271034AE296240AE284612140743C0
2373	loc3b583afba248	SPRINGVALE SOUTH	3172	VIC	SOUTH SPRINGVALE	-37.97075742	145.14802007	GAZETTED LOCALITY	5	4865	201	Y	Y	0101000020A41E0000A7F99594BC246240EA9F75C741FC42C0
2517	loc6de6554b144b	TAWONGA SOUTH	3698	VIC	SOUTH TAWONGA	-36.76619595	147.13768276	GAZETTED LOCALITY	5	851	50	Y	Y	0101000020A41E000089EDACE567646240F0C979B5126242C0
2735	loc37efd432abe4	WANTIRNA SOUTH	3152	VIC	SOUTH WANTIRNA	-37.87387750	145.22194081	GAZETTED LOCALITY	5	10335	365	Y	Y	0101000020A41E000021139D231A276240E99AC937DBEF42C0
2	locb9872f35df41	ABBOTSFORD	3067	VIC	ABBOTSFORD	-37.80436802	144.99970718	GAZETTED LOCALITY	5	8155	98	Y	Y	0101000020A41E0000A575E999FD1F624094EC0188F5E642C0
36	locec99dd6d0979	ALTONA MEADOWS	3028	VIC	ALTONA MEADOWS	-37.88082423	144.78426985	GAZETTED LOCALITY	5	9373	281	Y	Y	0101000020A41E0000A49F15BD18196240ECAF2ED9BEF042C0
77	locfdc6079b562f	ASCOT VALE	3032	VIC	ASCOT VALE	-37.77696479	144.91369882	GAZETTED LOCALITY	5	8947	180	Y	Y	0101000020A41E000067C94E053D1D6240C5980D9573E342C0
80	loc4ff8c926c940	ASHWOOD	3147	VIC	ASHWOOD	-37.86653017	145.10232098	GAZETTED LOCALITY	5	4076	114	Y	Y	0101000020A41E00006ED9A53646236240DB92EA75EAEE42C0
97	locd777103bd088	BACCHUS MARSH	3340	VIC	BACCHUS MARSH	-37.67604526	144.44261954	GAZETTED LOCALITY	5	5009	237	Y	Y	0101000020A41E0000DC1B74F0290E62406D28ADA688D642C0
105	loc232da9d11723	BAIRNSDALE	3875	VIC	BAIRNSDALE	-37.85951315	147.58897901	GAZETTED LOCALITY	5	6207	204	Y	Y	0101000020A41E0000603F82EAD8726240B0DDE28604EE42C0
133	locf3fc3fca2acd	BANGHOLME	3175	VIC	BANGHOLME	-38.04836638	145.17207763	GAZETTED LOCALITY	5	652	88	Y	Y	0101000020A41E00002427F2A881256240B7299ADE300643C0
139	locba8f7a4a0c92	BARANDUDA	3691	VIC	BARANDUDA	-36.18265294	146.95736570	GAZETTED LOCALITY	5	2139	171	Y	Y	0101000020A41E0000FD7964BDA25E6240BCE8E92B611742C0
165	locbbb93e2c6c42	BARWON HEADS	3227	VIC	BARWON HEADS	-38.27481890	144.48812755	GAZETTED LOCALITY	5	2946	96	Y	Y	0101000020A41E0000DAF0AABD9E0F62404EE905442D2343C0
177	loc2f9c80de6f7d	BAYSWATER	3153	VIC	BAYSWATER	-37.84517818	145.26476010	GAZETTED LOCALITY	5	9410	232	Y	Y	0101000020A41E000024592CEA78286240473271CC2EEC42C0
189	locb7bca082fca0	BEECH FOREST	3237	VIC	BEECH FOREST	-38.63470679	143.59258970	GAZETTED LOCALITY	5	217	98	Y	Y	0101000020A41E000049AEAC7EF6F26140B1CC74123E5143C0
208	locff58d0167065	BENALLA	3672	VIC	BENALLA	-36.57886218	145.99675701	GAZETTED LOCALITY	5	7520	382	Y	Y	0101000020A41E00004800F56EE53F6240E2FEE927184A42C0
211	loce6098ac5df0c	BENDIGO	3550	VIC	BENDIGO	-36.75700296	144.27939607	GAZETTED LOCALITY	5	5959	218	Y	Y	0101000020A41E0000FDE806D0F00862406D161679E56042C0
218	locd8470b65d64b	BENTLEIGH	3204	VIC	BENTLEIGH	-37.92264066	145.03858436	GAZETTED LOCALITY	5	9797	201	Y	Y	0101000020A41E0000C98A44153C2162407654D21619F642C0
237	loc4161e46afd2f	BEVERIDGE	3753	VIC	BEVERIDGE	-37.47615486	144.97191534	GAZETTED LOCALITY	5	6045	359	Y	Y	0101000020A41E0000FCF832EE191F624007C477A4F2BC42C0
261	locad899e5d272f	BLACK ROCK	3193	VIC	BLACK ROCK	-37.97112493	145.02165139	GAZETTED LOCALITY	5	3735	84	Y	Y	0101000020A41E0000D07E415EB120624014575BD24DFC42C0
264	loc7f158a48110c	BLAIRGOWRIE	3942	VIC	BLAIRGOWRIE	-38.36852599	144.77224943	GAZETTED LOCALITY	5	4395	170	Y	Y	0101000020A41E00008CC66F44B6186240556311DC2B2F43C0
284	locc70453923b8e	BONBEACH	3196	VIC	BONBEACH	-38.06309304	145.12761739	GAZETTED LOCALITY	5	4246	79	Y	Y	0101000020A41E00006E8E107115246240DEB3C76E130843C0
311	loc7d9d9818d4b9	BORONIA	3155	VIC	BORONIA	-37.85619100	145.28602380	GAZETTED LOCALITY	5	13872	346	Y	Y	0101000020A41E0000165C621B272962409510ACAA97ED42C0
321	loca5de38b84720	BOX HILL	3128	VIC	BOX HILL	-37.82150890	145.12610078	GAZETTED LOCALITY	5	13127	158	Y	Y	0101000020A41E000034C3800409246240BC6F213427E942C0
344	loc3319215a0a10	BRIGHTON	3186	VIC	BRIGHTON	-37.90840678	144.99569211	GAZETTED LOCALITY	5	15918	302	Y	Y	0101000020A41E0000BA2AB3B5DC1F624047C861AC46F442C0
354	loc74f8893fb76e	BROADMEADOWS	3047	VIC	BROADMEADOWS	-37.68255423	144.93132998	GAZETTED LOCALITY	5	7427	209	Y	Y	0101000020A41E00004CBC8774CD1D624059CCDFEF5DD742C0
359	loc29841cc6d6f1	BROOKFIELD	3338	VIC	BROOKFIELD	-37.69932000	144.54137738	GAZETTED LOCALITY	5	4441	241	Y	Y	0101000020A41E00009DBCA7F65211624028B8585183D942C0
394	loca56f2b16461e	BULLEEN	3105	VIC	BULLEEN	-37.76864666	145.08696722	GAZETTED LOCALITY	5	5786	166	Y	Y	0101000020A41E00002BB77A6FC82262409870850363E242C0
407	loc712bc92c5924	BUNDOORA	3083	VIC	BUNDOORA	-37.69856936	145.05962241	GAZETTED LOCALITY	5	13979	583	Y	Y	0101000020A41E0000E1A1416DE8216240059885B86AD942C0
461	loc913bf4728c4e	CAMBERWELL	3124	VIC	CAMBERWELL	-37.83845050	145.07362622	GAZETTED LOCALITY	5	12610	304	Y	Y	0101000020A41E0000E6E05F255B2262404D68925852EB42C0
477	locb694454fbbb1	CANTERBURY	3126	VIC	CANTERBURY	-37.82359585	145.07571033	GAZETTED LOCALITY	5	4103	141	Y	Y	0101000020A41E000038EA11386C226240876FBC966BE942C0
482	locf8d60bf51b6b	CAPEL SOUND	3940	VIC	CAPEL SOUND	-38.37228685	144.87408803	GAZETTED LOCALITY	5	4686	237	Y	Y	0101000020A41E00009AD57587F81B62408DBD7218A72F43C0
504	loca0398a35cf5e	CARLTON	3053	VIC	CARLTON	-37.80043730	144.96815465	GAZETTED LOCALITY	5	27532	207	Y	Y	0101000020A41E00000DE7751FFB1E6240D0FFBCBA74E642C0
507	loc86cf2bd4847b	CARNEGIE	3163	VIC	CARNEGIE	-37.89336926	145.05560162	GAZETTED LOCALITY	5	11966	149	Y	Y	0101000020A41E000026700C7DC7216240D27985EC59F242C0
509	loc17a18f5ff3a6	CAROLINE SPRINGS	3023	VIC	CAROLINE SPRINGS	-37.73445832	144.73721933	GAZETTED LOCALITY	5	9141	492	Y	Y	0101000020A41E0000870AFE4C971762406A56F0BA02DE42C0
517	locff62fb6a898a	CARRUM DOWNS	3201	VIC	CARRUM DOWNS	-38.09277451	145.17595194	GAZETTED LOCALITY	5	13068	506	Y	Y	0101000020A41E0000F87EF665A12562401C2DFF08E00B43C0
537	loc9b20cd160517	CHADSTONE	3148	VIC	CHADSTONE	-37.88212697	145.10017821	GAZETTED LOCALITY	5	5481	140	Y	Y	0101000020A41E000019F7EEA834236240E8885B89E9F042C0
546	locffd0eebac0eb	CHELSEA	3196	VIC	CHELSEA	-38.04971663	145.12140374	GAZETTED LOCALITY	5	5665	124	Y	Y	0101000020A41E0000309D188AE22362406BF5511D5D0643C0
547	locc25e0bed112f	CHELSEA HEIGHTS	3196	VIC	CHELSEA HEIGHTS	-38.04081911	145.13410102	GAZETTED LOCALITY	5	2560	117	Y	Y	0101000020A41E000054E8388E4A2462403C40838F390543C0
548	loc0a03ed3531fd	CHELTENHAM	3192	VIC	CHELTENHAM	-37.96356461	145.06031317	GAZETTED LOCALITY	5	17038	415	Y	Y	0101000020A41E00006195E215EE21624039C4CB1556FB42C0
555	loc1a7553da1009	CHETWYND	3312	VIC	CHETWYND	-37.29605057	141.37584769	GAZETTED LOCALITY	5	72	45	Y	Y	0101000020A41E0000781ABCF106AC61405B0E2EFCE4A542C0
575	loc39cd317eec9d	CLARINDA	3169	VIC	CLARINDA	-37.94367893	145.10608841	GAZETTED LOCALITY	5	3231	132	Y	Y	0101000020A41E0000E96D8513652362401B239F78CAF842C0
578	loc86dc9bf35404	CLAYTON	3168	VIC	CLAYTON	-37.91816786	145.13043131	GAZETTED LOCALITY	5	12815	215	Y	Y	0101000020A41E0000625A487E2C2462401A78418686F542C0
584	loc36422efcb9c0	CLIFTON SPRINGS	3222	VIC	CLIFTON SPRINGS	-38.15307861	144.57272698	GAZETTED LOCALITY	5	4413	183	Y	Y	0101000020A41E0000611488C75312624065D57314981343C0
605	locbd7d4fd6b9e7	COBURG	3058	VIC	COBURG	-37.74485608	144.96430352	GAZETTED LOCALITY	5	15501	297	Y	Y	0101000020A41E00002A3A0E93DB1E6240D3E9AB7157DF42C0
625	loc6de0828869d7	COLLINGWOOD	3066	VIC	COLLINGWOOD	-37.80194257	144.98817027	GAZETTED LOCALITY	5	9128	110	Y	Y	0101000020A41E0000F21042179F1F6240C9B5DB0DA6E642C0
673	locc0b6d754799e	CRANBOURNE	3977	VIC	CRANBOURNE	-38.11282226	145.27525433	GAZETTED LOCALITY	5	11286	440	Y	Y	0101000020A41E0000D62D2BE2CE286240FC7AB6F5700E43C0
681	loc87f2ad0c0fd7	CREMORNE	3121	VIC	CREMORNE	-37.82901427	144.99305526	GAZETTED LOCALITY	5	2593	88	Y	Y	0101000020A41E0000441AD31BC71F62409EC8BC231DEA42C0
693	loccb9bfb1fb49a	CROYDON	3136	VIC	CROYDON	-37.79493972	145.28404910	GAZETTED LOCALITY	5	16150	434	Y	Y	0101000020A41E0000AA5E23EE1629624080D8B195C0E542C0
737	locfa38377aaf29	DEDERANG	3691	VIC	DEDERANG	-36.48257435	147.00127471	GAZETTED LOCALITY	5	112	25	Y	Y	0101000020A41E000061B842710A606240B9910DFFC43D42C0
740	loc70eb03d586f8	DEER PARK	3023	VIC	DEER PARK	-37.76935363	144.77170305	GAZETTED LOCALITY	5	8145	253	Y	Y	0101000020A41E0000273F98CAB118624056F4032E7AE242C0
752	loca2fd80ef71d3	DEREEL	3352	VIC	DEREEL	-37.82134279	143.75826329	GAZETTED LOCALITY	5	407	59	Y	Y	0101000020A41E0000D60960B143F861407EEDB2C221E942C0
777	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	DOCKLANDS	-37.81846198	144.94320607	GAZETTED LOCALITY	5	32105	151	Y	Y	0101000020A41E00003D017FBE2E1E6240498FB65CC3E842C0
781	loc7ab22202aac3	DONCASTER	3108	VIC	DONCASTER	-37.78478379	145.12408527	GAZETTED LOCALITY	5	15112	405	Y	Y	0101000020A41E00001712AC81F82362408F3D94CB73E442C0
799	locf4e180745c81	DROMANA	3936	VIC	DROMANA	-38.33199504	145.00982168	GAZETTED LOCALITY	5	6799	248	Y	Y	0101000020A41E0000894C8E7550206240FB9D3FD07E2A43C0
827	loceb6884033cea	DURHAM LEAD	3352	VIC	DURHAM LEAD	-37.69786946	143.88802269	GAZETTED LOCALITY	5	196	41	Y	Y	0101000020A41E0000FE748FAE6AFC6140E1C955C953D942C0
839	loc86b22e8e6ecf	EAST BENDIGO	3550	VIC	EAST BENDIGO	-36.73980552	144.32234698	GAZETTED LOCALITY	5	2388	127	Y	Y	0101000020A41E00000F229DAA500A62406FE680F2B15E42C0
876	loccbfe7d3f7b9f	ELSTERNWICK	3185	VIC	ELSTERNWICK	-37.88583832	145.00701303	GAZETTED LOCALITY	5	7102	130	Y	Y	0101000020A41E0000DECF637339206240C7F86A2663F142C0
877	locc7ee8539a72b	ELTHAM	3095	VIC	ELTHAM	-37.71743485	145.15909924	GAZETTED LOCALITY	5	9001	328	Y	Y	0101000020A41E0000CA134A57172562405DE1B8E7D4DB42C0
890	loca1a84d46e52a	EPPING	3076	VIC	EPPING	-37.63791598	145.01044881	GAZETTED LOCALITY	5	17636	829	Y	Y	0101000020A41E00006E27BE985520624010D9173BA7D142C0
904	loca674ab421c49	EUROA	3666	VIC	EUROA	-36.76862436	145.56183084	GAZETTED LOCALITY	5	2666	169	Y	Y	0101000020A41E0000E575AB84FA316240F18D7448626242C0
908	loc0de2086617a5	EVERTON	3678	VIC	EVERTON	-36.43910984	146.55408200	GAZETTED LOCALITY	5	111	20	Y	Y	0101000020A41E0000ACA92C0ABB5162406E1351C0343842C0
918	locd6190ebbe554	FALLS CREEK	3699	VIC	FALLS CREEK	-36.87278922	147.23973176	GAZETTED LOCALITY	5	579	165	Y	Y	0101000020A41E000067A0F0E1AB676240C619A28EB76F42C0
921	loc7213d03738b9	FAWKNER	3060	VIC	FAWKNER	-37.70461888	144.96929577	GAZETTED LOCALITY	5	6792	169	Y	Y	0101000020A41E0000A3099078041F624040DF92F330DA42C0
929	loccd13bd88b567	FERNTREE GULLY	3156	VIC	FERNTREE GULLY	-37.88435027	145.28043523	GAZETTED LOCALITY	5	14231	425	Y	Y	0101000020A41E0000E1AF4D53F9286240ECEDBF6332F142C0
932	loca5643321b976	FIERY FLAT	3518	VIC	FIERY FLAT	-36.41138551	143.81058695	GAZETTED LOCALITY	5	14	19	Y	Y	0101000020A41E00000F1A0B54F0F96140C8BFC747A83442C0
937	loc875118ed8437	FITZROY	3065	VIC	FITZROY	-37.80089516	144.97916306	GAZETTED LOCALITY	5	10128	110	Y	Y	0101000020A41E0000D704C54D551F6240C3DC8BBB83E642C0
942	loc92bf5bc798e7	FLEMINGTON	3031	VIC	FLEMINGTON	-37.78673870	144.91929735	GAZETTED LOCALITY	5	6429	122	Y	Y	0101000020A41E000095B146E26A1D6240B07F8DDAB3E442C0
943	loc5c94ac6107ca	FLINDERS	3929	VIC	FLINDERS	-38.45878777	144.97839944	GAZETTED LOCALITY	5	1451	72	Y	Y	0101000020A41E000031A7570C4F1F624036FAC18EB93A43C0
948	loc67a11408d754	FOOTSCRAY	3011	VIC	FOOTSCRAY	-37.79813977	144.89719898	GAZETTED LOCALITY	5	17072	237	Y	Y	0101000020A41E000059A3A2DAB51C6240BBE4A87129E642C0
961	loc6413994c2b24	FRANKSTON	3199	VIC	FRANKSTON	-38.14815340	145.14568453	GAZETTED LOCALITY	5	24471	843	Y	Y	0101000020A41E0000437C9A72A924624046E5CBB0F61243C0
964	loc8733d13ded2e	FRASER RISE	3336	VIC	FRASER RISE	-37.70480866	144.71262742	GAZETTED LOCALITY	5	9717	556	Y	Y	0101000020A41E000040E404D8CD1662409C51902B37DA42C0
979	loc4195fdfecc8e	GARDENVALE	3185	VIC	GARDENVALE	-37.89811245	145.00913401	GAZETTED LOCALITY	5	692	21	Y	Y	0101000020A41E0000674768D34A206240B2704859F5F242C0
1015	loce11f06c54f46	GISBORNE	3437	VIC	GISBORNE	-37.51046544	144.56957927	GAZETTED LOCALITY	5	5879	306	Y	Y	0101000020A41E000025244EFE39126240E54479EE56C142C0
1041	locadc5cabaa80e	GLEN IRIS	3146	VIC	GLEN IRIS	-37.85596271	145.06499614	GAZETTED LOCALITY	5	13959	285	Y	Y	0101000020A41E000052F5C87214226240D405A32F90ED42C0
1059	loc4858bcc1d912	GLENROY	3046	VIC	GLENROY	-37.70262151	144.92729012	GAZETTED LOCALITY	5	13213	233	Y	Y	0101000020A41E0000BA69545CAC1D624044756B80EFD942C0
1074	loc338a35dd09f0	GOLDEN SQUARE	3555	VIC	GOLDEN SQUARE	-36.77381908	144.25278585	GAZETTED LOCALITY	5	5765	228	Y	Y	0101000020A41E000088D459D21608624077CFEC800C6342C0
1113	locb53ace4ff1b6	GREAT WESTERN	3374	VIC	GREAT WESTERN	-37.16670390	142.88196153	GAZETTED LOCALITY	5	325	77	Y	Y	0101000020A41E0000C4F5620739DC6140CE4EAB8D569542C0
1120	loc4883549a5421	GREENVALE	3059	VIC	GREENVALE	-37.63652820	144.87974370	GAZETTED LOCALITY	5	10260	516	Y	Y	0101000020A41E0000968B42DC261C6240AAFD8CC179D142C0
1132	loc098e933e1fd2	GROVEDALE	3216	VIC	GROVEDALE	-38.20306981	144.33184114	GAZETTED LOCALITY	5	7857	308	Y	Y	0101000020A41E00008E784F719E0A6240A2600831FE1943C0
1143	locf066999b6a14	HALLAM	3803	VIC	HALLAM	-38.00755370	145.26892255	GAZETTED LOCALITY	5	6156	206	Y	Y	0101000020A41E000006AD76039B2862405E3B0785F70043C0
1147	loc4423238fcdd8	HAMILTON	3300	VIC	HAMILTON	-37.74554533	142.01791629	GAZETTED LOCALITY	5	6826	315	Y	Y	0101000020A41E0000B3F32EC592C061408C0485076EDF42C0
1148	loc780d4ed4ca46	HAMLYN HEIGHTS	3215	VIC	HAMLYN HEIGHTS	-38.12098853	144.32399087	GAZETTED LOCALITY	5	3591	132	Y	Y	0101000020A41E000048DB19225E0A624043C5598D7C0F43C0
1149	loce42a110faa48	HAMPTON	3188	VIC	HAMPTON	-37.93786730	145.00926445	GAZETTED LOCALITY	5	8402	149	Y	Y	0101000020A41E00007EB8F5E44B20624071BE22090CF842C0
1164	loc7c934a667999	HASTINGS	3915	VIC	HASTINGS	-38.29722876	145.18521960	GAZETTED LOCALITY	5	6974	249	Y	Y	0101000020A41E00008192A751ED256240B9D08D970B2643C0
1171	loc5c27e3f22fc1	HAWTHORN	3122	VIC	HAWTHORN	-37.82479779	145.03208102	GAZETTED LOCALITY	5	17535	265	Y	Y	0101000020A41E00001D77C6CE0621624079EE56F992E942C0
1175	loc47e9d5554e9d	HAZELWOOD	3840	VIC	HAZELWOOD	-38.28856339	146.37488114	GAZETTED LOCALITY	5	104	25	Y	Y	0101000020A41E0000FE85BB06FF4B6240BB6F29A5EF2443C0
1178	locc84be248155b	HEALESVILLE	3777	VIC	HEALESVILLE	-37.66025120	145.55092288	GAZETTED LOCALITY	5	4681	263	Y	Y	0101000020A41E0000FB060529A131624087927F1C83D442C0
1179	loc0e534d470df9	HEATHCOTE	3523	VIC	HEATHCOTE	-36.91536367	144.72251241	GAZETTED LOCALITY	5	2440	206	Y	Y	0101000020A41E0000EF7C58D21E1762405B4C01A32A7542C0
1182	loc3d949ab3c987	HEATHERTON	3202	VIC	HEATHERTON	-37.95601698	145.09288076	GAZETTED LOCALITY	5	1605	85	Y	Y	0101000020A41E0000165412E1F8226240A6C2AFC35EFA42C0
1188	loccaca39f133a7	HEIDELBERG HEIGHTS	3081	VIC	HEIDELBERG HEIGHTS	-37.74323715	145.05349245	GAZETTED LOCALITY	5	4520	90	Y	Y	0101000020A41E0000A76ACC35B62162400C361A6522DF42C0
1192	loc245c69160468	HEPBURN	3461	VIC	HEPBURN	-37.31188511	144.12765935	GAZETTED LOCALITY	5	498	30	Y	Y	0101000020A41E0000EAA80FC91504624099C7EDD9EBA742C0
1205	locf16910f90fb9	HIGHETT	3190	VIC	HIGHETT	-37.95036349	145.04045010	GAZETTED LOCALITY	5	8811	160	Y	Y	0101000020A41E0000D613025E4B216240646EC682A5F942C0
1249	loc02a3a330fe2f	INDENTED HEAD	3223	VIC	INDENTED HEAD	-38.13771298	144.70198618	GAZETTED LOCALITY	5	1909	68	Y	Y	0101000020A41E000002ABB8AB76166240D8AA3494A01143C0
1266	loc9fb289b0a33e	IRYMPLE	3498	VIC	IRYMPLE	-34.25256109	142.16878233	GAZETTED LOCALITY	5	3634	175	Y	Y	0101000020A41E0000C46F33AA66C5614064E5FAEB532041C0
1267	loc201e214973bd	IVANHOE	3079	VIC	IVANHOE	-37.76782855	145.04369306	GAZETTED LOCALITY	5	9625	170	Y	Y	0101000020A41E000064F8FCEE65216240B197B73448E242C0
1270	loc9a86c6faf562	JACKASS FLAT	3556	VIC	JACKASS FLAT	-36.71847848	144.28437962	GAZETTED LOCALITY	5	1115	77	Y	Y	0101000020A41E000091F149A3190962406A3D531AF75B42C0
1299	loc1a22f173d7f3	JUNCTION VILLAGE	3977	VIC	JUNCTION VILLAGE	-38.13601217	145.29143107	GAZETTED LOCALITY	5	1245	59	Y	Y	0101000020A41E000006564067532962400601C7D8681143C0
1351	loccdfc709471ce	KERANG	3579	VIC	KERANG	-35.72458805	143.94550487	GAZETTED LOCALITY	5	2574	150	Y	Y	0101000020A41E00007BDB6D9341FE614045E91C4DBFDC41C0
1359	loc00a9769647d7	KEW	3101	VIC	KEW	-37.80340822	145.03317877	GAZETTED LOCALITY	5	14272	346	Y	Y	0101000020A41E00004A82ECCC0F216240691E9F14D6E642C0
1373	loc09a99bf786b9	KILLAWARRA	3678	VIC	KILLAWARRA	-36.24796084	146.20827010	GAZETTED LOCALITY	5	171	81	Y	Y	0101000020A41E000082870E26AA4662408D3E492EBD1F42C0
1376	loce25dfc481765	KILMORE	3764	VIC	KILMORE	-37.30159212	144.94976249	GAZETTED LOCALITY	5	5976	311	Y	Y	0101000020A41E000090304E74641E6240CF1012929AA642C0
1378	loc38cbe92d1159	KILSYTH	3137	VIC	KILSYTH	-37.81437399	145.31849534	GAZETTED LOCALITY	5	6846	253	Y	Y	0101000020A41E00004FA7231D312A6240ABE12A683DE842C0
1380	loca37d9a7b347e	KIMBOLTON	3551	VIC	KIMBOLTON	-36.91950880	144.50356819	GAZETTED LOCALITY	5	81	40	Y	Y	0101000020A41E0000646B093B1D1062402E31E076B27542C0
1385	loce3f8de63f06a	KINGSBURY	3083	VIC	KINGSBURY	-37.71617919	145.03406236	GAZETTED LOCALITY	5	1917	43	Y	Y	0101000020A41E00003047F2091721624019907BC2ABDB42C0
1386	loca307cf61ba97	KINGS PARK	3021	VIC	KINGS PARK	-37.73370384	144.77197453	GAZETTED LOCALITY	5	3064	134	Y	Y	0101000020A41E00003DF6ED03B4186240F3DFE601EADD42C0
1393	locbf553ce41d73	KIRWANS BRIDGE	3608	VIC	KIRWANS BRIDGE	-36.72888897	145.14690796	GAZETTED LOCALITY	5	121	19	Y	Y	0101000020A41E00001B775278B32462405648D83B4C5D42C0
1398	locd6f79866f950	KNOXFIELD	3180	VIC	KNOXFIELD	-37.89055081	145.24938568	GAZETTED LOCALITY	5	4443	124	Y	Y	0101000020A41E00001A76ADF7FA2762402B30A691FDF142C0
1410	loc0a8087d68433	KOORLONG	3501	VIC	KOORLONG	-34.31478223	142.04594225	GAZETTED LOCALITY	5	259	53	Y	Y	0101000020A41E000026A8E15B78C16140219BBBC84A2841C0
1423	loc0067a4549ed1	KORUMBURRA	3950	VIC	KORUMBURRA	-38.43779948	145.81514797	GAZETTED LOCALITY	5	3142	206	Y	Y	0101000020A41E0000A01132B1153A6240256738D0093843C0
1435	locabdfa0718385	KURUNJANG	3337	VIC	KURUNJANG	-37.66090353	144.59149418	GAZETTED LOCALITY	5	4399	204	Y	Y	0101000020A41E0000FBDB3385ED1262409A94A37C98D442C0
1436	loc62ed665318da	KYABRAM	3620	VIC	KYABRAM	-36.32707394	145.03640401	GAZETTED LOCALITY	5	4662	236	Y	Y	0101000020A41E0000960CBE382A21624041D6118FDD2942C0
1492	locbcb60f6b546d	LANGWARRIN	3910	VIC	LANGWARRIN	-38.15455928	145.19739512	GAZETTED LOCALITY	5	10795	434	Y	Y	0101000020A41E00004819920F5126624058723699C81343C0
1494	loce16236caf708	LARA	3212	VIC	LARA	-38.00478584	144.40190323	GAZETTED LOCALITY	5	12450	607	Y	Y	0101000020A41E000037A02964DC0C6240562489D29C0043C0
1502	loc098ac8eaabef	LAVERTON	3028	VIC	LAVERTON	-37.85912878	144.76753923	GAZETTED LOCALITY	5	3066	129	Y	Y	0101000020A41E0000E8676EAE8F18624081938EEEF7ED42C0
1512	loc8a2c57a8fa9c	LEITCHVILLE	3567	VIC	LEITCHVILLE	-35.91299829	144.29118610	GAZETTED LOCALITY	5	383	84	Y	Y	0101000020A41E000098118365510962404D6DC220DDF441C0
1516	loc5900b8cc74c8	LEONGATHA	3953	VIC	LEONGATHA	-38.47401955	145.94372051	GAZETTED LOCALITY	5	4148	228	Y	Y	0101000020A41E000076E05AF5323E6240137530ACAC3C43C0
1519	loc5ba812288f5b	LEOPOLD	3224	VIC	LEOPOLD	-38.19443096	144.46708335	GAZETTED LOCALITY	5	7466	296	Y	Y	0101000020A41E00003218C858F20E6240D3431B1DE31843C0
1564	loceb41e8eec3ee	LONGWARRY	3816	VIC	LONGWARRY	-38.12253531	145.77198309	GAZETTED LOCALITY	5	1442	110	Y	Y	0101000020A41E0000AE93E115B43862401287AE3CAF0F43C0
1568	locc672a234fa5a	LORNE	3232	VIC	LORNE	-38.53328012	143.92577917	GAZETTED LOCALITY	5	3285	120	Y	Y	0101000020A41E0000FA4EA3FB9FFD6140E480E185424443C0
1576	loc98325a7e67bf	LUCAS	3350	VIC	LUCAS	-37.55409834	143.76911588	GAZETTED LOCALITY	5	3386	194	Y	Y	0101000020A41E0000E5EDE7989CF86140B188C4B1ECC642C0
1596	loccabf2d0215b8	MADDINGLEY	3340	VIC	MADDINGLEY	-37.69743912	144.41952920	GAZETTED LOCALITY	5	3366	192	Y	Y	0101000020A41E0000F23680C86C0D6240EEAC61AF45D942C0
1613	loc76dea039b41f	MALVERN	3144	VIC	MALVERN	-37.85680884	145.03502037	GAZETTED LOCALITY	5	7265	142	Y	Y	0101000020A41E000001FB09E31E216240A25C7DE9ABED42C0
1615	locffa1c8993b70	MAMBOURIN	3024	VIC	MAMBOURIN	-37.89963431	144.55410106	GAZETTED LOCALITY	5	2992	273	Y	Y	0101000020A41E0000206C2532BB1162409FE7913727F342C0
1625	loc875f8bb64843	MANOR LAKES	3024	VIC	MANOR LAKES	-37.86692870	144.58123627	GAZETTED LOCALITY	5	6642	389	Y	Y	0101000020A41E0000C55CCE7C991262405E3B0785F7EE42C0
1626	loc515028b0f98a	MANSFIELD	3722	VIC	MANSFIELD	-37.05810260	146.07974940	GAZETTED LOCALITY	5	4332	232	Y	Y	0101000020A41E0000051C9D4E8D4262400268EFE76F8742C0
1639	locb48ce003b11e	MARONG	3515	VIC	MARONG	-36.75142624	144.10358100	GAZETTED LOCALITY	5	1018	99	Y	Y	0101000020A41E000095EF19895003624000142BBC2E6042C0
1662	locc67851215f08	MEADOW HEIGHTS	3048	VIC	MEADOW HEIGHTS	-37.65117995	144.91820964	GAZETTED LOCALITY	5	5774	197	Y	Y	0101000020A41E000080D52EF9611D6240CC8756DD59D342C0
1669	loc556974a8bc81	MELTON	3337	VIC	MELTON	-37.67562844	144.61176602	GAZETTED LOCALITY	5	5433	192	Y	Y	0101000020A41E00008816559693136240140623FE7AD642C0
1675	locdd716f1059c5	MENTONE	3194	VIC	MENTONE	-37.98157499	145.06941311	GAZETTED LOCALITY	5	8993	192	Y	Y	0101000020A41E0000A3ABD7A1382262408E4FD03FA4FD42C0
1680	loc63a05a113f90	MERBEIN	3505	VIC	MERBEIN	-34.16132067	142.04750971	GAZETTED LOCALITY	5	1743	132	Y	Y	0101000020A41E00002956153385C16140CFE8DC27A61441C0
1703	loc1b271c01e3dc	MICKLEHAM	3064	VIC	MICKLEHAM	-37.53982082	144.90062723	GAZETTED LOCALITY	5	12960	711	Y	Y	0101000020A41E0000965732F0D11C6240CACC3FD918C542C0
1710	locb71d10cf3b7c	MILDURA	3500	VIC	MILDURA	-34.20800367	142.12456014	GAZETTED LOCALITY	5	22458	842	Y	Y	0101000020A41E0000EDF58B65FCC361408A0C40DD9F1A41C0
1770	loc4a7c5154c298	MOONEE PONDS	3039	VIC	MOONEE PONDS	-37.76561153	144.92143477	GAZETTED LOCALITY	5	11086	195	Y	Y	0101000020A41E00008351C5647C1D62403065018FFFE142C0
1775	locea2e2e01b99c	MOORABBIN	3189	VIC	MOORABBIN	-37.94144518	145.05778652	GAZETTED LOCALITY	5	6364	178	Y	Y	0101000020A41E000097B11D63D9216240D689914681F842C0
1789	loc3b64e6146ff8	MORDIALLOC	3195	VIC	MORDIALLOC	-37.99938366	145.09608095	GAZETTED LOCALITY	5	6318	155	Y	Y	0101000020A41E000098405B1813236240ABEDC3CDEBFF42C0
1798	loc11fb0b5df130	MORWELL	3840	VIC	MORWELL	-38.22759164	146.41460722	GAZETTED LOCALITY	5	9858	409	Y	Y	0101000020A41E0000BC525C76444D62404E520DB9211D43C0
1809	loc8688ba223de1	MOUNT BULLER	3723	VIC	MOUNT BULLER	-37.26159972	146.43615646	GAZETTED LOCALITY	5	862	304	Y	Y	0101000020A41E0000747464FEF44D6240790581197CA142C0
1812	loc12cc6354a4ba	MOUNT CAMEL	3523	VIC	MOUNT CAMEL	-36.80777715	144.74685066	GAZETTED LOCALITY	5	122	47	Y	Y	0101000020A41E000046F65A33E617624061DADC3D656742C0
1821	loc90b2f4dd8c2d	MOUNT DUNEED	3217	VIC	MOUNT DUNEED	-38.24981904	144.31279449	GAZETTED LOCALITY	5	5947	336	Y	Y	0101000020A41E0000681D9769020A6240EB5BFF11FA1F43C0
1827	loc20a81a4bf246	MOUNT EVELYN	3796	VIC	MOUNT EVELYN	-37.78744675	145.38803017	GAZETTED LOCALITY	5	4304	193	Y	Y	0101000020A41E00005D403FBE6A2C6240B64B1B0ECBE442C0
1835	loc5100fc96abff	MOUNT MARTHA	3934	VIC	MOUNT MARTHA	-38.27546769	145.03065420	GAZETTED LOCALITY	5	10756	431	Y	Y	0101000020A41E0000854F841EFB206240CCD37786422343C0
1848	loca1b6ce72e35a	MOUNT WAVERLEY	3149	VIC	MOUNT WAVERLEY	-37.87836713	145.12850255	GAZETTED LOCALITY	5	19046	559	Y	Y	0101000020A41E00007C3661B11C2462409E9D88556EF042C0
1858	loc264c2d9ba83e	MULGRAVE	3170	VIC	MULGRAVE	-37.92567326	145.17598025	GAZETTED LOCALITY	5	9879	433	Y	Y	0101000020A41E0000BE4F55A1A1256240A93D1D767CF642C0
1899	loce01ddbd8c8e5	NAGAMBIE	3608	VIC	NAGAMBIE	-36.78330457	145.21540257	GAZETTED LOCALITY	5	2463	115	Y	Y	0101000020A41E0000FB33EE93E42662408A7AFB52436442C0
1918	loc15a8d395ef61	NAR NAR GOON	3812	VIC	NAR NAR GOON	-38.10594660	145.56891443	GAZETTED LOCALITY	5	1253	120	Y	Y	0101000020A41E000052E2088C34326240AB0F7FA88F0D43C0
1984	loca4e166a620d9	NOBLE PARK	3174	VIC	NOBLE PARK	-37.96949556	145.17690561	GAZETTED LOCALITY	5	16287	359	Y	Y	0101000020A41E0000BA2DF435A92562409AE8356E18FC42C0
1992	loce1597eda1cc3	NORLANE	3214	VIC	NORLANE	-38.09186574	144.35369471	GAZETTED LOCALITY	5	6005	176	Y	Y	0101000020A41E0000FC869177510B62402076AE41C20B43C0
1995	locd06d20cbea22	NORTH BENDIGO	3550	VIC	NORTH BENDIGO	-36.73744770	144.28044117	GAZETTED LOCALITY	5	2630	98	Y	Y	0101000020A41E000043B3C25FF90862405501ADAF645E42C0
1997	locbb6ca08c118e	NORTHCOTE	3070	VIC	NORTHCOTE	-37.77251920	145.00056873	GAZETTED LOCALITY	5	15268	229	Y	Y	0101000020A41E00000298B6A8042062401BC4BDE8E1E242C0
1999	loc1e06c486c813	NORTH MELBOURNE	3051	VIC	NORTH MELBOURNE	-37.79843875	144.94482109	GAZETTED LOCALITY	5	20008	246	Y	Y	0101000020A41E0000E04370F93B1E6240F88DAF3D33E642C0
2003	loc1e33f92d8409	NORTH WONTHAGGI	3995	VIC	NORTH WONTHAGGI	-38.57949655	145.59416246	GAZETTED LOCALITY	5	2169	94	Y	Y	0101000020A41E0000C0C6FD60033362408A3265F12C4A43C0
2034	loc51ba976fe589	OAK PARK	3046	VIC	OAK PARK	-37.71748734	144.91701444	GAZETTED LOCALITY	5	3822	88	Y	Y	0101000020A41E000050B8AA2E581D6240094C0AA0D6DB42C0
2035	loc5e68bb81d75d	OAKVALE	3540	VIC	OAKVALE	-35.93005382	143.54326982	GAZETTED LOCALITY	5	7	20	Y	Y	0101000020A41E0000B9B9637762F16140BE35EA000CF741C0
2037	loc0b665c0fe535	OCEAN GROVE	3226	VIC	OCEAN GROVE	-38.25953426	144.53821157	GAZETTED LOCALITY	5	13584	465	Y	Y	0101000020A41E0000526F7807391162401F722B6B382143C0
2038	loc64c822b0bad5	OFFICER	3809	VIC	OFFICER	-38.05422611	145.41254027	GAZETTED LOCALITY	5	12112	734	Y	Y	0101000020A41E0000DBFDA687332D6240088594E1F00643C0
2048	loc0b6e17218dd4	ORMOND	3204	VIC	ORMOND	-37.90390176	145.04175981	GAZETTED LOCALITY	5	4858	103	Y	Y	0101000020A41E00009747AB185621624098FF880DB3F342C0
2054	locf3eb6fff8056	OXLEY	3678	VIC	OXLEY	-36.44878450	146.37717351	GAZETTED LOCALITY	5	346	39	Y	Y	0101000020A41E0000C34B2ECE114C6240D2393FC5713942C0
2059	loc82baa1179308	PAKENHAM	3810	VIC	PAKENHAM	-38.07356414	145.48515783	GAZETTED LOCALITY	5	27319	1205	Y	Y	0101000020A41E0000F2A7B669862F6240ACBABB8C6A0943C0
2068	loc025dead673cc	PARKDALE	3195	VIC	PARKDALE	-37.99180688	145.08129939	GAZETTED LOCALITY	5	6802	158	Y	Y	0101000020A41E000083A72D019A2262401EC62087F3FE42C0
2071	loc9e7da77def26	PARKVILLE	3052	VIC	PARKVILLE	-37.78683182	144.95130149	GAZETTED LOCALITY	5	5756	127	Y	Y	0101000020A41E0000F485D20F711E6240142DB3E7B6E442C0
2074	loc12c0177d3d38	PASCOE VALE	3044	VIC	PASCOE VALE	-37.72500600	144.93817594	GAZETTED LOCALITY	5	10555	195	Y	Y	0101000020A41E000036868C89051E6240AFB321FFCCDC42C0
2083	locb344fc28a060	PEARCEDALE	3912	VIC	PEARCEDALE	-38.19775043	145.24773800	GAZETTED LOCALITY	5	1723	74	Y	Y	0101000020A41E00003FFF3D78ED2762405ACFD6E24F1943C0
2119	locc5abea08e85d	POINT COOK	3030	VIC	POINT COOK	-37.90559622	144.75160970	GAZETTED LOCALITY	5	26044	1157	Y	Y	0101000020A41E0000671BC92F0D186240FF23B293EAF342C0
2137	loc956fa85c7b0c	PORTARLINGTON	3223	VIC	PORTARLINGTON	-38.13765510	144.66362811	GAZETTED LOCALITY	5	5753	172	Y	Y	0101000020A41E000000A504713C1562405650ACAE9E1143C0
2141	locd665688d0e4d	PORTLAND	3305	VIC	PORTLAND	-38.36088187	141.60412211	GAZETTED LOCALITY	5	7076	320	Y	Y	0101000020A41E0000B227E4F754B3614046AF8A60312E43C0
2144	loc9a48431374e1	PORT MELBOURNE	3207	VIC	PORT MELBOURNE	-37.83291801	144.92186945	GAZETTED LOCALITY	5	15064	273	Y	Y	0101000020A41E0000CF5D5CF47F1D62408699AE0E9DEA42C0
2145	loc67d2e4d427ab	PORTSEA	3944	VIC	PORTSEA	-38.32266610	144.70016395	GAZETTED LOCALITY	5	2020	123	Y	Y	0101000020A41E0000D2623ABE6716624091836D1F4D2943C0
2151	loc250adfcbc82d	PRAHRAN	3181	VIC	PRAHRAN	-37.85174788	145.00034300	GAZETTED LOCALITY	5	11649	174	Y	Y	0101000020A41E00000AB952CF02206240C784141306ED42C0
2154	loc2c4c767ea9b7	PRESTON	3072	VIC	PRESTON	-37.74167026	145.00803234	GAZETTED LOCALITY	5	22947	387	Y	Y	0101000020A41E000088B309CD41206240D38E130DEFDE42C0
2186	loc3fe991822440	RED HILL	3937	VIC	RED HILL	-38.36344884	145.01610344	GAZETTED LOCALITY	5	753	59	Y	Y	0101000020A41E0000E6845CEB83206240D9C8D87D852E43C0
2196	loc656f84726510	RESERVOIR	3073	VIC	RESERVOIR	-37.71200590	145.00690838	GAZETTED LOCALITY	5	30178	475	Y	Y	0101000020A41E00006345EC97382062408F87630223DB42C0
2205	loce48c38ae2d6a	RICHMOND	3121	VIC	RICHMOND	-37.82032239	145.00246345	GAZETTED LOCALITY	5	24141	350	Y	Y	0101000020A41E0000EEA53A2E14206240009DF65200E942C0
2207	loc2508c9e5a93c	RIDDELLS CREEK	3431	VIC	RIDDELLS CREEK	-37.44376746	144.68321415	GAZETTED LOCALITY	5	2095	121	Y	Y	0101000020A41E000043CDEBE3DC1562404FDD435FCDB842C0
2209	loc72d1f0339be6	RINGWOOD	3134	VIC	RINGWOOD	-37.81150624	145.23341414	GAZETTED LOCALITY	5	13199	341	Y	Y	0101000020A41E00002B37EE207827624064A6BC6FDFE742C0
2232	loc1fbfb471eb7c	ROMSEY	3434	VIC	ROMSEY	-37.35261197	144.72902632	GAZETTED LOCALITY	5	2920	129	Y	Y	0101000020A41E0000584A012F5417624000AA976322AD42C0
2236	locc81a6ec90a1b	ROSEBUD	3939	VIC	ROSEBUD	-38.37371498	144.91359221	GAZETTED LOCALITY	5	11699	332	Y	Y	0101000020A41E000092FABA253C1D62400A9078E4D52F43C0
2247	locfd8472c41cbe	ROWVILLE	3178	VIC	ROWVILLE	-37.92435918	145.24393668	GAZETTED LOCALITY	5	14146	593	Y	Y	0101000020A41E0000A2DC4B54CE276240BFEDCF6651F642C0
2248	loc3754c5fc3408	ROXBURGH PARK	3064	VIC	ROXBURGH PARK	-37.62575497	144.92540148	GAZETTED LOCALITY	5	7921	440	Y	Y	0101000020A41E0000A48890E39C1D6240D0BA25BD18D042C0
2266	locc586266ef8cc	SALE	3850	VIC	SALE	-38.10258716	147.07303207	GAZETTED LOCALITY	5	10223	341	Y	Y	0101000020A41E0000B2065A475662624042987893210D43C0
2274	loc679429866800	SANDY CREEK	3695	VIC	SANDY CREEK	-36.36298904	147.12186585	GAZETTED LOCALITY	5	98	28	Y	Y	0101000020A41E0000FA073653E6636240A0CDC36C762E42C0
2295	locb948618ae376	SEBASTOPOL	3356	VIC	SEBASTOPOL	-37.60018612	143.83564293	GAZETTED LOCALITY	5	6665	192	Y	Y	0101000020A41E00007AEF3D96BDFA6140E17416E6D2CC42C0
2316	loc1b289d3ff2fc	SHEPPARTON	3630	VIC	SHEPPARTON	-36.37263142	145.39781134	GAZETTED LOCALITY	5	19363	686	Y	Y	0101000020A41E0000E5E8D8DEBA2C6240572EE962B22F42C0
2344	locc098f71b2faf	SOLDIERS HILL	3350	VIC	SOLDIERS HILL	-37.54944324	143.85871908	GAZETTED LOCALITY	5	1732	37	Y	Y	0101000020A41E0000A3A16FA07AFB61407667F52754C642C0
2348	loc3b6fd5dcd874	SORRENTO	3943	VIC	SORRENTO	-38.34461348	144.74196733	GAZETTED LOCALITY	5	4170	196	Y	Y	0101000020A41E00009D214532BE1762402D2E654B1C2C43C0
2349	loc31f384e524fe	SOUTHBANK	3006	VIC	SOUTHBANK	-37.82586063	144.96227816	GAZETTED LOCALITY	5	52880	98	Y	Y	0101000020A41E00005D5B91FBCA1E6240B57316CDB5E942C0
2354	locf51f6cd689bb	SOUTH MELBOURNE	3205	VIC	SOUTH MELBOURNE	-37.83392841	144.95747163	GAZETTED LOCALITY	5	14693	202	Y	Y	0101000020A41E000054368B9BA31E6240E013882ABEEA42C0
2355	loc22c42e389de3	SOUTH MORANG	3752	VIC	SOUTH MORANG	-37.63229697	145.08470014	GAZETTED LOCALITY	5	11099	556	Y	Y	0101000020A41E0000886811DDB522624044C16B1BEFD042C0
2358	locc2ea2de6af6c	SOUTH YARRA	3141	VIC	SOUTH YARRA	-37.83921837	144.99186548	GAZETTED LOCALITY	5	28436	222	Y	Y	0101000020A41E000034D4AC5CBD1F62401CADEE816BEB42C0
2421	loc13ed320cd188	STRATHFIELDSAYE	3551	VIC	STRATHFIELDSAYE	-36.80424396	144.35579449	GAZETTED LOCALITY	5	3483	212	Y	Y	0101000020A41E0000B45420AB620B62404F1A5177F16642C0
2438	loc1eda86883ae9	SUNDERLAND BAY	3922	VIC	SUNDERLAND BAY	-38.50305783	145.27164714	GAZETTED LOCALITY	5	359	27	Y	Y	0101000020A41E000043CB5755B128624062ECEF32644043C0
2450	locedacea740a10	SWAN HILL	3585	VIC	SWAN HILL	-35.36217734	143.51179958	GAZETTED LOCALITY	5	7107	310	Y	Y	0101000020A41E00009C4683A960F061407E53BBD35BAE41C0
2495	loc108a649ba4ae	TARILTA	3451	VIC	TARILTA	-37.17781010	144.19126160	GAZETTED LOCALITY	5	17	8	Y	Y	0101000020A41E0000619FA5D01E06624002333A7BC29642C0
2497	loc819a06b032e3	TARNEIT	3029	VIC	TARNEIT	-37.83546749	144.66467179	GAZETTED LOCALITY	5	31442	1537	Y	Y	0101000020A41E0000F613C6FD44156240EA354599F0EA42C0
2519	locc91f4a31a1bc	TAYLORS HILL	3037	VIC	TAYLORS HILL	-37.71514756	144.75291252	GAZETTED LOCALITY	5	4912	242	Y	Y	0101000020A41E0000C444FFDB17186240D1018BF489DB42C0
2520	locf065e41cfac9	TAYLORS LAKES	3038	VIC	TAYLORS LAKES	-37.69856354	144.78639377	GAZETTED LOCALITY	5	6203	262	Y	Y	0101000020A41E0000B37D44232A1962402F3DB3876AD942C0
2529	loc406d1f7b5fe3	TEMPLESTOWE	3106	VIC	TEMPLESTOWE	-37.75398577	145.14875308	GAZETTED LOCALITY	5	7927	331	Y	Y	0101000020A41E0000F0B8D195C224624052E60F9B82E042C0
2533	loc75d84680b181	TENNYSON	3572	VIC	TENNYSON	-36.29115027	144.37569600	GAZETTED LOCALITY	5	80	32	Y	Y	0101000020A41E00009E279EB3050C624090EF7B69442542C0
2551	loc8f565e81c655	THOMASTOWN	3074	VIC	THOMASTOWN	-37.68376853	145.00803925	GAZETTED LOCALITY	5	12476	407	Y	Y	0101000020A41E0000B37A87DB41206240273129BA85D742C0
2555	loc82b861dfb765	THORNBURY	3071	VIC	THORNBURY	-37.75817285	145.00580105	GAZETTED LOCALITY	5	11626	129	Y	Y	0101000020A41E00000A01AF852F20624089BBD5CE0BE142C0
2599	locba5e689e47f8	TORQUAY	3228	VIC	TORQUAY	-38.30810147	144.32255282	GAZETTED LOCALITY	5	12123	427	Y	Y	0101000020A41E00003EA44A5A520A6240F0BF74DE6F2743C0
2601	loc6c0f29d040f7	TORRUMBARRY	3562	VIC	TORRUMBARRY	-36.04631358	144.52768035	GAZETTED LOCALITY	5	167	39	Y	Y	0101000020A41E0000BDBFE6C1E2106240F8BA779AED0542C0
2613	loc5e975e2e1c0e	TRAFALGAR	3824	VIC	TRAFALGAR	-38.16961347	146.14716760	GAZETTED LOCALITY	5	2458	151	Y	Y	0101000020A41E0000FCA0D398B5446240384EE9E4B51543C0
2617	loc8e5a2b16aaaa	TRARALGON	3844	VIC	TRARALGON	-38.20339273	146.51980204	GAZETTED LOCALITY	5	16429	716	Y	Y	0101000020A41E00003646E337A25062400DCCE1C5081A43C0
2634	loc8fef59c1c585	TULLAMARINE	3043	VIC	TULLAMARINE	-37.70540772	144.87228824	GAZETTED LOCALITY	5	6369	166	Y	Y	0101000020A41E000088EF06C9E91B62407ADFD7CC4ADA42C0
2645	loc399d9bd46679	TYLDEN	3444	VIC	TYLDEN	-37.32838364	144.41097324	GAZETTED LOCALITY	5	339	31	Y	Y	0101000020A41E0000992A5AB1260D6240B42BA17908AA42C0
2657	loc94fdc21035b3	ULTIMA	3544	VIC	ULTIMA	-35.48169816	143.27936675	GAZETTED LOCALITY	5	257	61	Y	Y	0101000020A41E0000E0DA8992F0E8614027DF0949A8BD41C0
2666	loc991c414cb6c9	UPPER PLENTY	3756	VIC	UPPER PLENTY	-37.41973034	145.05463320	GAZETTED LOCALITY	5	233	28	Y	Y	0101000020A41E0000D4E81F8EBF21624030B849B9B9B542C0
2675	loc4a6dd2077a69	VENUS BAY	3956	VIC	VENUS BAY	-38.67655229	145.79109280	GAZETTED LOCALITY	5	2696	100	Y	Y	0101000020A41E00003C03D9A150396240BDCAF343995643C0
2676	loc46b3ff1e6b9a	VERMONT	3133	VIC	VERMONT	-37.83844492	145.19918393	GAZETTED LOCALITY	5	5101	183	Y	Y	0101000020A41E0000A427FAB65F266240DC72C32952EB42C0
2708	locc605118e951a	WALLAN	3756	VIC	WALLAN	-37.40812840	144.96389829	GAZETTED LOCALITY	5	8814	423	Y	Y	0101000020A41E00000D073A41D81E6240CF48298D3DB442C0
2712	loc532c3dac4248	WALMER	3463	VIC	WALMER	-36.97806922	144.16036198	GAZETTED LOCALITY	5	237	43	Y	Y	0101000020A41E0000E67372AF21056240E78F485F317D42C0
2729	loc5c7c3d320a8a	WANGARATTA	3677	VIC	WANGARATTA	-36.36826478	146.31722081	GAZETTED LOCALITY	5	12553	518	Y	Y	0101000020A41E0000F19141AC264A62402F2FE14C232F42C0
2734	loc4a341f4d3e02	WANTIRNA	3152	VIC	WANTIRNA	-37.85234166	145.22588593	GAZETTED LOCALITY	5	6670	281	Y	Y	0101000020A41E0000403F21753A276240F35B118819ED42C0
2748	locd724f9a08a75	WARRAGUL	3820	VIC	WARRAGUL	-38.15368646	145.92981314	GAZETTED LOCALITY	5	12815	630	Y	Y	0101000020A41E00001D767C07C13D6240DEC477FFAB1343C0
2754	locae68612e5fe1	WARRANWOOD	3134	VIC	WARRANWOOD	-37.77261721	145.24978167	GAZETTED LOCALITY	5	1894	89	Y	Y	0101000020A41E00004AF92036FE2762406DA3E81EE5E242C0
2760	loc1f73672977ce	WARRNAMBOOL	3280	VIC	WARRNAMBOOL	-38.36867716	142.49821362	GAZETTED LOCALITY	5	21980	798	Y	Y	0101000020A41E00004C8AB05DF1CF6140B77D2CD0302F43C0
2771	loc06cc48b309e5	WATSONIA	3087	VIC	WATSONIA	-37.71050943	145.08356765	GAZETTED LOCALITY	5	2792	105	Y	Y	0101000020A41E00001D781096AC226240C0AC16F9F1DA42C0
2792	loce36428dd6505	WELSHMANS REEF	3462	VIC	WELSHMANS REEF	-37.06174830	144.03565710	GAZETTED LOCALITY	5	298	34	Y	Y	0101000020A41E0000D9CB5B1A24016240B38A485EE78742C0
2800	loc29a798d6921b	WERRIBEE	3030	VIC	WERRIBEE	-37.90680357	144.64218431	GAZETTED LOCALITY	5	28324	1245	Y	Y	0101000020A41E00008A2E1CC68C146240E585AE2312F442C0
2808	loca818c5eaa373	WEST FOOTSCRAY	3012	VIC	WEST FOOTSCRAY	-37.80051862	144.87089837	GAZETTED LOCALITY	5	7148	134	Y	Y	0101000020A41E000045294266DE1B6240995EE66477E642C0
2810	loc0b8afd71fce1	WEST MELBOURNE	3003	VIC	WEST MELBOURNE	-37.80950643	144.92559156	GAZETTED LOCALITY	5	14308	108	Y	Y	0101000020A41E0000EAF430729E1D624038601DE89DE742C0
2812	loc3832b905a97e	WEST WODONGA	3690	VIC	WEST WODONGA	-36.11103572	146.82190102	GAZETTED LOCALITY	5	7669	414	Y	Y	0101000020A41E00005F2E5E034D5A62403D0B216B360E42C0
2816	locb8f595af5fb8	WHEELERS HILL	3150	VIC	WHEELERS HILL	-37.90752269	145.18700820	GAZETTED LOCALITY	5	10142	391	Y	Y	0101000020A41E0000AFE29EF8FB256240C7F618B429F442C0
2842	loc8c9f2867857c	WILLIAMSTOWN	3016	VIC	WILLIAMSTOWN	-37.86128768	144.89009225	GAZETTED LOCALITY	5	8866	246	Y	Y	0101000020A41E00008A05BEA27B1C62401B06B9AC3EEE42C0
2852	locf2d2a267a354	WINCHELSEA	3241	VIC	WINCHELSEA	-38.23835407	143.95024252	GAZETTED LOCALITY	5	1925	140	Y	Y	0101000020A41E00006555006368FE61405EC2DB62821E43C0
2864	loc6a54ce63b777	WINTER VALLEY	3358	VIC	WINTER VALLEY	-37.58011476	143.79280531	GAZETTED LOCALITY	5	4068	209	Y	Y	0101000020A41E000072D13DA95EF961403E10513341CA42C0
2869	locdf0288b649a4	WODONGA	3690	VIC	WODONGA	-36.12408101	146.88176978	GAZETTED LOCALITY	5	12716	544	Y	Y	0101000020A41E000070F64175375C62409800F4E2E10F42C0
2870	loc6d7f0d49a3d6	WOLLERT	3750	VIC	WOLLERT	-37.59201147	145.00557191	GAZETTED LOCALITY	5	16760	1129	Y	Y	0101000020A41E00003D6724A52D206240E2402708C7CB42C0
2934	loceac5d85ea01d	WYNDHAM VALE	3024	VIC	WYNDHAM VALE	-37.85918632	144.60816298	GAZETTED LOCALITY	5	11648	643	Y	Y	0101000020A41E00009DB735127613624009C93CD1F9ED42C0
2963	loc610e6e8cd167	YARRA GLEN	3775	VIC	YARRA GLEN	-37.64677910	145.38155300	GAZETTED LOCALITY	5	1548	87	Y	Y	0101000020A41E00001A16A3AE352C6240401E55A8C9D242C0
2971	locb0a9c63101c7	YARRAWONGA	3730	VIC	YARRAWONGA	-36.03704952	146.00178980	GAZETTED LOCALITY	5	7041	284	Y	Y	0101000020A41E0000ED8E7BA90E406240C25DE609BE0442C0
2997	loc9901d119afda_1	MELBOURNE	3000	VIC	MELBOURNE	-37.81348464	144.96326770	GAZETTED LOCALITY	5	118635	392	Y	N	0101000020A41E00006199C816D31E6240964CC24320E842C0
\.

-- gnaf_202602.locality_aliases: 500 rows
\copy gnaf_202602.locality_aliases FROM stdin
loc1e33f92d8409	NORTH WONTHAGGI	\N	VIC	ST CLAIR	SAINT CLAIR	SYNONYM	N
locb281644d861d	BELGRAVE SOUTH	\N	VIC	NARRE WARREN EAST	EAST NARRE WARREN	SYNONYM	N
loce6098ac5df0c	BENDIGO	\N	VIC	BENDIGO EAST	EAST BENDIGO	SYNONYM	N
locd8470b65d64b	BENTLEIGH	\N	VIC	BENTLEIGH EAST	EAST BENTLEIGH	SYNONYM	N
loc7ab22202aac3	DONCASTER	\N	VIC	DONCASTER EAST	EAST DONCASTER	SYNONYM	N
locadc5cabaa80e	GLEN IRIS	\N	VIC	MALVERN EAST	EAST MALVERN	SYNONYM	N
loc1a22f173d7f3	JUNCTION VILLAGE	\N	VIC	CRANBOURNE EAST	EAST CRANBOURNE	SYNONYM	N
loc76dea039b41f	MALVERN	\N	VIC	MALVERN EAST	EAST MALVERN	SYNONYM	N
loc8e5a2b16aaaa	TRARALGON	\N	VIC	TRARALGON EAST	EAST TRARALGON	SYNONYM	N
locf8d60bf51b6b	CAPEL SOUND	\N	VIC	ROSEBUD WEST	WEST ROSEBUD	SYNONYM	N
locbd7d4fd6b9e7	COBURG	\N	VIC	HEIDELBERG WEST	WEST HEIDELBERG	SYNONYM	N
loc67a11408d754	FOOTSCRAY	\N	VIC	FOOTSCRAY WEST	WEST FOOTSCRAY	SYNONYM	N
loccaca39f133a7	HEIDELBERG HEIGHTS	\N	VIC	HEIDELBERG WEST	WEST HEIDELBERG	SYNONYM	N
locabdfa0718385	KURUNJANG	\N	VIC	MELTON WEST	WEST MELTON	SYNONYM	N
loc63a05a113f90	MERBEIN	\N	VIC	MERBEIN WEST	WEST MERBEIN	SYNONYM	N
locd665688d0e4d	PORTLAND	\N	VIC	PORTLAND WEST	WEST PORTLAND	SYNONYM	N
locc81a6ec90a1b	ROSEBUD	\N	VIC	ROSEBUD WEST	WEST ROSEBUD	SYNONYM	N
loce6098ac5df0c	BENDIGO	\N	VIC	BENDIGO NORTH	NORTH BENDIGO	SYNONYM	N
locc0b6d754799e	CRANBOURNE	\N	VIC	CRANBOURNE NORTH	NORTH CRANBOURNE	SYNONYM	N
locf066999b6a14	HALLAM	\N	VIC	NARRE WARREN NORTH	NORTH NARRE WARREN	SYNONYM	N
loc098ac8eaabef	LAVERTON	\N	VIC	LAVERTON NORTH	NORTH LAVERTON	SYNONYM	N
loc20a81a4bf246	MOUNT EVELYN	\N	VIC	WANDIN NORTH	NORTH WANDIN	SYNONYM	N
loc4e07cec4cde4	NARRE WARREN EAST	\N	VIC	NARRE WARREN NORTH	NORTH NARRE WARREN	SYNONYM	N
loc6280f9052ec0	NARRE WARREN SOUTH	\N	VIC	CRANBOURNE NORTH	NORTH CRANBOURNE	SYNONYM	N
loc82baa1179308	PAKENHAM	\N	VIC	NAR NAR GOON NORTH	NORTH NAR NAR GOON	SYNONYM	N
loc12c0177d3d38	PASCOE VALE	\N	VIC	COBURG NORTH	NORTH COBURG	SYNONYM	N
loc2c4c767ea9b7	PRESTON	\N	VIC	COBURG NORTH	NORTH COBURG	SYNONYM	N
loc72d1f0339be6	RINGWOOD	\N	VIC	RINGWOOD NORTH	NORTH RINGWOOD	SYNONYM	N
loc1b289d3ff2fc	SHEPPARTON	\N	VIC	SHEPPARTON NORTH	NORTH SHEPPARTON	SYNONYM	N
locc098f71b2faf	SOLDIERS HILL	\N	VIC	BALLARAT NORTH	NORTH BALLARAT	SYNONYM	N
loc2424df148d7d	WANDIN EAST	\N	VIC	WANDIN NORTH	NORTH WANDIN	SYNONYM	N
loc5c7c3d320a8a	WANGARATTA	\N	VIC	WANGARATTA NORTH	NORTH WANGARATTA	SYNONYM	N
loc8c9f2867857c	WILLIAMSTOWN	\N	VIC	WILLIAMSTOWN NORTH	NORTH WILLIAMSTOWN	SYNONYM	N
loc29841cc6d6f1	BROOKFIELD	\N	VIC	MELTON SOUTH	SOUTH MELTON	SYNONYM	N
loc39cd317eec9d	CLARINDA	\N	VIC	CLAYTON SOUTH	SOUTH CLAYTON	SYNONYM	N
loc86dc9bf35404	CLAYTON	\N	VIC	CLAYTON SOUTH	SOUTH CLAYTON	SYNONYM	N
locbd7d4fd6b9e7	COBURG	\N	VIC	PASCOE VALE SOUTH	SOUTH PASCOE VALE	SYNONYM	N
loccbfe7d3f7b9f	ELSTERNWICK	\N	VIC	CAULFIELD SOUTH	SOUTH CAULFIELD	SYNONYM	N
loc0e534d470df9	HEATHCOTE	\N	VIC	HEATHCOTE SOUTH	SOUTH HEATHCOTE	SYNONYM	N
loc3d949ab3c987	HEATHERTON	\N	VIC	CLAYTON SOUTH	SOUTH CLAYTON	SYNONYM	N
loc38cbe92d1159	KILSYTH	\N	VIC	CROYDON SOUTH	SOUTH CROYDON	SYNONYM	N
loc0a8087d68433	KOORLONG	\N	VIC	MERBEIN SOUTH	SOUTH MERBEIN	SYNONYM	N
loc556974a8bc81	MELTON	\N	VIC	MELTON SOUTH	SOUTH MELTON	SYNONYM	N
loc63a05a113f90	MERBEIN	\N	VIC	MERBEIN SOUTH	SOUTH MERBEIN	SYNONYM	N
locb71d10cf3b7c	MILDURA	\N	VIC	MERBEIN SOUTH	SOUTH MERBEIN	SYNONYM	N
loc12c0177d3d38	PASCOE VALE	\N	VIC	PASCOE VALE SOUTH	SOUTH PASCOE VALE	SYNONYM	N
loc3fe991822440	RED HILL	\N	VIC	RED HILL SOUTH	SOUTH RED HILL	SYNONYM	N
loc46f8f01fbac9	RINGWOOD EAST	\N	VIC	CROYDON SOUTH	SOUTH CROYDON	SYNONYM	N
loc399d9bd46679	TYLDEN	\N	VIC	KYNETON SOUTH	SOUTH KYNETON	SYNONYM	N
locd724f9a08a75	WARRAGUL	\N	VIC	WARRAGUL SOUTH	SOUTH WARRAGUL	SYNONYM	N
loc0de2086617a5	EVERTON	\N	VIC	EVERTON UPPER	UPPER EVERTON	SYNONYM	N
loc64c822b0bad5	OFFICER	\N	VIC	BEACONSFIELD UPPER	UPPER BEACONSFIELD	SYNONYM	N
loc82baa1179308	PAKENHAM	\N	VIC	BEACONSFIELD UPPER	UPPER BEACONSFIELD	SYNONYM	N
locc098f71b2faf	SOLDIERS HILL	\N	VIC	BALLARAT CENTRAL	CENTRAL BALLARAT	SYNONYM	N
locb9872f35df41	ABBOTSFORD	\N	VIC	RICHMOND	RICHMOND	SYNONYM	N
locec99dd6d0979	ALTONA MEADOWS	\N	VIC	LAVERTON	LAVERTON	SYNONYM	N
locec99dd6d0979	ALTONA MEADOWS	\N	VIC	POINT COOK	POINT COOK	SYNONYM	N
loc232da9d11723	BAIRNSDALE	\N	VIC	HILLSIDE	HILLSIDE	SYNONYM	N
loc232da9d11723	BAIRNSDALE	\N	VIC	PAYNESVILLE	PAYNESVILLE	SYNONYM	N
loc9165cd64854f	BAYSWATER NORTH	\N	VIC	KILSYTH	KILSYTH	SYNONYM	N
locb7bca082fca0	BEECH FOREST	\N	VIC	FERGUSON	FERGUSON	SYNONYM	N
locb7bca082fca0	BEECH FOREST	\N	VIC	GELLIBRAND	GELLIBRAND	SYNONYM	N
locb281644d861d	BELGRAVE SOUTH	\N	VIC	BELGRAVE	BELGRAVE	SYNONYM	N
locb281644d861d	BELGRAVE SOUTH	\N	VIC	BELGRAVE HEIGHTS	BELGRAVE HEIGHTS	SYNONYM	N
locb281644d861d	BELGRAVE SOUTH	\N	VIC	LYSTERFIELD	LYSTERFIELD	SYNONYM	N
locff58d0167065	BENALLA	\N	VIC	BADDAGINNIE	BADDAGINNIE	SYNONYM	N
locff58d0167065	BENALLA	\N	VIC	LURG	LURG	SYNONYM	N
locff58d0167065	BENALLA	\N	VIC	TATONG	TATONG	SYNONYM	N
loce6098ac5df0c	BENDIGO	\N	VIC	EAGLEHAWK	EAGLEHAWK	SYNONYM	N
loce6098ac5df0c	BENDIGO	\N	VIC	EAST BENDIGO	EAST BENDIGO	SYNONYM	N
loce6098ac5df0c	BENDIGO	\N	VIC	MANDURANG	MANDURANG	SYNONYM	N
locd8470b65d64b	BENTLEIGH	\N	VIC	MCKINNON	MCKINNON	SYNONYM	N
locd8470b65d64b	BENTLEIGH	\N	VIC	MOORABBIN	MOORABBIN	SYNONYM	N
loc4161e46afd2f	BEVERIDGE	\N	VIC	DARRAWEIT GUIM	DARRAWEIT GUIM	SYNONYM	N
loc4161e46afd2f	BEVERIDGE	\N	VIC	EDEN PARK	EDEN PARK	SYNONYM	N
loc4161e46afd2f	BEVERIDGE	\N	VIC	KALKALLO	KALKALLO	SYNONYM	N
loc4161e46afd2f	BEVERIDGE	\N	VIC	MICKLEHAM	MICKLEHAM	SYNONYM	N
loc4161e46afd2f	BEVERIDGE	\N	VIC	WHITTLESEA	WHITTLESEA	SYNONYM	N
loc4161e46afd2f	BEVERIDGE	\N	VIC	WOODSTOCK	WOODSTOCK	SYNONYM	N
locad899e5d272f	BLACK ROCK	\N	VIC	SANDRINGHAM	SANDRINGHAM	SYNONYM	N
loc6ae7eaa3c1f3	BOX HILL SOUTH	\N	VIC	BOX HILL	BOX HILL	SYNONYM	N
loc79e45c9fa669	BRUNSWICK EAST	\N	VIC	CARLTON	CARLTON	SYNONYM	N
loc11b2a92fb5f0	BRUNSWICK WEST	\N	VIC	BRUNSWICK	BRUNSWICK	SYNONYM	N
loc712bc92c5924	BUNDOORA	\N	VIC	EPPING	EPPING	SYNONYM	N
loc712bc92c5924	BUNDOORA	\N	VIC	THOMASTOWN	THOMASTOWN	SYNONYM	N
loc913bf4728c4e	CAMBERWELL	\N	VIC	CANTERBURY	CANTERBURY	SYNONYM	N
loc913bf4728c4e	CAMBERWELL	\N	VIC	GLEN IRIS	GLEN IRIS	SYNONYM	N
locf8d60bf51b6b	CAPEL SOUND	\N	VIC	BONEO	BONEO	SYNONYM	N
loca0398a35cf5e	CARLTON	\N	VIC	BRUNSWICK	BRUNSWICK	SYNONYM	N
loc17a18f5ff3a6	CAROLINE SPRINGS	\N	VIC	BURNSIDE	BURNSIDE	SYNONYM	N
locff62fb6a898a	CARRUM DOWNS	\N	VIC	PATTERSON LAKES	PATTERSON LAKES	SYNONYM	N
locff62fb6a898a	CARRUM DOWNS	\N	VIC	SKYE	SKYE	SYNONYM	N
loc36422efcb9c0	CLIFTON SPRINGS	\N	VIC	DRYSDALE	DRYSDALE	SYNONYM	N
locae977e7a8d83	CRANBOURNE EAST	\N	VIC	CLYDE	CLYDE	SYNONYM	N
locae977e7a8d83	CRANBOURNE EAST	\N	VIC	CRANBOURNE	CRANBOURNE	SYNONYM	N
loc9fe59dbd0874	CRANBOURNE NORTH	\N	VIC	CRANBOURNE	CRANBOURNE	SYNONYM	N
loc9ea2b366d63f	CRANBOURNE WEST	\N	VIC	CRANBOURNE	CRANBOURNE	SYNONYM	N
loc87f2ad0c0fd7	CREMORNE	\N	VIC	MELBOURNE	MELBOURNE	SYNONYM	N
loc87f2ad0c0fd7	CREMORNE	\N	VIC	RICHMOND	RICHMOND	SYNONYM	N
loccb9bfb1fb49a	CROYDON	\N	VIC	KILSYTH	KILSYTH	SYNONYM	N
locd755ccb7197e	DANDENONG NORTH	\N	VIC	DANDENONG	DANDENONG	SYNONYM	N
locddc4a1bcd8ba	DOCKLANDS	\N	VIC	WEST MELBOURNE	WEST MELBOURNE	SYNONYM	N
loc7a8164839d54	DONCASTER EAST	\N	VIC	TEMPLESTOWE	TEMPLESTOWE	SYNONYM	N
locf4e180745c81	DROMANA	\N	VIC	ARTHURS SEAT	ARTHURS SEAT	SYNONYM	N
loc86b22e8e6ecf	EAST BENDIGO	\N	VIC	ASCOT	ASCOT	SYNONYM	N
loc86b22e8e6ecf	EAST BENDIGO	\N	VIC	BENDIGO	BENDIGO	SYNONYM	N
loc86b22e8e6ecf	EAST BENDIGO	\N	VIC	KENNINGTON	KENNINGTON	SYNONYM	N
loc86b22e8e6ecf	EAST BENDIGO	\N	VIC	STRATHDALE	STRATHDALE	SYNONYM	N
loc86b22e8e6ecf	EAST BENDIGO	\N	VIC	WHITE HILLS	WHITE HILLS	SYNONYM	N
loca1a84d46e52a	EPPING	\N	VIC	LALOR	LALOR	SYNONYM	N
loca1a84d46e52a	EPPING	\N	VIC	MILL PARK	MILL PARK	SYNONYM	N
loca1a84d46e52a	EPPING	\N	VIC	WOLLERT	WOLLERT	SYNONYM	N
loca674ab421c49	EUROA	\N	VIC	LONGWOOD	LONGWOOD	SYNONYM	N
loc7213d03738b9	FAWKNER	\N	VIC	THOMASTOWN	THOMASTOWN	SYNONYM	N
loccd13bd88b567	FERNTREE GULLY	\N	VIC	LYSTERFIELD	LYSTERFIELD	SYNONYM	N
loccd13bd88b567	FERNTREE GULLY	\N	VIC	UPPER FERNTREE GULLY	UPPER FERNTREE GULLY	SYNONYM	N
loc67a11408d754	FOOTSCRAY	\N	VIC	WEST MELBOURNE	WEST MELBOURNE	SYNONYM	N
loc6413994c2b24	FRANKSTON	\N	VIC	LANGWARRIN	LANGWARRIN	SYNONYM	N
loc6413994c2b24	FRANKSTON	\N	VIC	SEAFORD	SEAFORD	SYNONYM	N
loc8733d13ded2e	FRASER RISE	\N	VIC	HILLSIDE	HILLSIDE	SYNONYM	N
loc8733d13ded2e	FRASER RISE	\N	VIC	PLUMPTON	PLUMPTON	SYNONYM	N
loca674ab421c49	EUROA	\N	VIC	MIEPOLL	MIEPOLL	SYNONYM	Y
loc910a14938d48	GEELONG WEST	\N	VIC	GEELONG	GEELONG	SYNONYM	N
loce11f06c54f46	GISBORNE	\N	VIC	RIDDELLS CREEK	RIDDELLS CREEK	SYNONYM	N
loc630ef4fec09d	GISBORNE SOUTH	\N	VIC	GISBORNE	GISBORNE	SYNONYM	N
loc630ef4fec09d	GISBORNE SOUTH	\N	VIC	SUNBURY	SUNBURY	SYNONYM	N
loc630ef4fec09d	GISBORNE SOUTH	\N	VIC	TOOLERN VALE	TOOLERN VALE	SYNONYM	N
locadc5cabaa80e	GLEN IRIS	\N	VIC	CAMBERWELL	CAMBERWELL	SYNONYM	N
loc4858bcc1d912	GLENROY	\N	VIC	BROADMEADOWS	BROADMEADOWS	SYNONYM	N
loc7c934a667999	HASTINGS	\N	VIC	TYABB	TYABB	SYNONYM	N
loc338a35dd09f0	GOLDEN SQUARE	\N	VIC	BENDIGO	BENDIGO	SYNONYM	N
loc338a35dd09f0	GOLDEN SQUARE	\N	VIC	KANGAROO FLAT	KANGAROO FLAT	SYNONYM	N
loc338a35dd09f0	GOLDEN SQUARE	\N	VIC	MAIDEN GULLY	MAIDEN GULLY	SYNONYM	N
loc338a35dd09f0	GOLDEN SQUARE	\N	VIC	QUARRY HILL	QUARRY HILL	SYNONYM	N
loc4883549a5421	GREENVALE	\N	VIC	CRAIGIEBURN	CRAIGIEBURN	SYNONYM	N
loc4423238fcdd8	HAMILTON	\N	VIC	COLERAINE	COLERAINE	SYNONYM	N
loc4423238fcdd8	HAMILTON	\N	VIC	STRATHKELLAR	STRATHKELLAR	SYNONYM	N
loce42a110faa48	HAMPTON	\N	VIC	SANDRINGHAM	SANDRINGHAM	SYNONYM	N
loc7c934a667999	HASTINGS	\N	VIC	TUERONG	TUERONG	SYNONYM	N
loc4fa4b090ce9e	HAWTHORN EAST	\N	VIC	CAMBERWELL	CAMBERWELL	SYNONYM	N
loc4fa4b090ce9e	HAWTHORN EAST	\N	VIC	HAWTHORN	HAWTHORN	SYNONYM	N
loc47e9d5554e9d	HAZELWOOD	\N	VIC	YINNAR	YINNAR	SYNONYM	N
locc84be248155b	HEALESVILLE	\N	VIC	LAUNCHING PLACE	LAUNCHING PLACE	SYNONYM	N
locc84be248155b	HEALESVILLE	\N	VIC	TOOLANGI	TOOLANGI	SYNONYM	N
locc84be248155b	HEALESVILLE	\N	VIC	WARBURTON	WARBURTON	SYNONYM	N
locc84be248155b	HEALESVILLE	\N	VIC	YARRA GLEN	YARRA GLEN	SYNONYM	N
loc0e534d470df9	HEATHCOTE	\N	VIC	KNOWSLEY	KNOWSLEY	SYNONYM	N
loc245c69160468	HEPBURN	\N	VIC	HEPBURN SPRINGS	HEPBURN SPRINGS	SYNONYM	N
locf16910f90fb9	HIGHETT	\N	VIC	SANDRINGHAM	SANDRINGHAM	SYNONYM	N
loc5900b8cc74c8	LEONGATHA	\N	VIC	RUBY	RUBY	SYNONYM	N
loc02a3a330fe2f	INDENTED HEAD	\N	VIC	PORTARLINGTON	PORTARLINGTON	SYNONYM	N
loc9fb289b0a33e	IRYMPLE	\N	VIC	CARDROSS	CARDROSS	SYNONYM	N
loc9fb289b0a33e	IRYMPLE	\N	VIC	KOORLONG	KOORLONG	SYNONYM	N
loc9fb289b0a33e	IRYMPLE	\N	VIC	MILDURA	MILDURA	SYNONYM	N
loc9fb289b0a33e	IRYMPLE	\N	VIC	RED CLIFFS	RED CLIFFS	SYNONYM	N
loc9a86c6faf562	JACKASS FLAT	\N	VIC	EAGLEHAWK	EAGLEHAWK	SYNONYM	N
loc9a86c6faf562	JACKASS FLAT	\N	VIC	EPSOM	EPSOM	SYNONYM	N
loc9a86c6faf562	JACKASS FLAT	\N	VIC	NORTH BENDIGO	NORTH BENDIGO	SYNONYM	N
loc9a86c6faf562	JACKASS FLAT	\N	VIC	WHITE HILLS	WHITE HILLS	SYNONYM	N
loc1a22f173d7f3	JUNCTION VILLAGE	\N	VIC	CRANBOURNE	CRANBOURNE	SYNONYM	N
loc00a9769647d7	KEW	\N	VIC	HAWTHORN	HAWTHORN	SYNONYM	N
loce25dfc481765	KILMORE	\N	VIC	BYLANDS	BYLANDS	SYNONYM	N
loc38cbe92d1159	KILSYTH	\N	VIC	CROYDON	CROYDON	SYNONYM	N
loc38cbe92d1159	KILSYTH	\N	VIC	MONTROSE	MONTROSE	SYNONYM	N
loc38cbe92d1159	KILSYTH	\N	VIC	MOOROOLBARK	MOOROOLBARK	SYNONYM	N
loca37d9a7b347e	KIMBOLTON	\N	VIC	REDESDALE	REDESDALE	SYNONYM	N
locbf553ce41d73	KIRWANS BRIDGE	\N	VIC	NAGAMBIE	NAGAMBIE	SYNONYM	N
locd6f79866f950	KNOXFIELD	\N	VIC	ROWVILLE	ROWVILLE	SYNONYM	N
loc0067a4549ed1	KORUMBURRA	\N	VIC	ARAWATA	ARAWATA	SYNONYM	N
loc0067a4549ed1	KORUMBURRA	\N	VIC	LEONGATHA	LEONGATHA	SYNONYM	N
loc0067a4549ed1	KORUMBURRA	\N	VIC	LOCH	LOCH	SYNONYM	N
loc0067a4549ed1	KORUMBURRA	\N	VIC	MEENIYAN	MEENIYAN	SYNONYM	N
loc0067a4549ed1	KORUMBURRA	\N	VIC	OUTTRIM	OUTTRIM	SYNONYM	N
loc0067a4549ed1	KORUMBURRA	\N	VIC	WHITELAW	WHITELAW	SYNONYM	N
locabdfa0718385	KURUNJANG	\N	VIC	MELTON	MELTON	SYNONYM	N
loc62ed665318da	KYABRAM	\N	VIC	TATURA	TATURA	SYNONYM	N
loc62ed665318da	KYABRAM	\N	VIC	TONGALA	TONGALA	SYNONYM	N
locbcb60f6b546d	LANGWARRIN	\N	VIC	FRANKSTON	FRANKSTON	SYNONYM	N
locbcb60f6b546d	LANGWARRIN	\N	VIC	SEAFORD	SEAFORD	SYNONYM	N
locbcb60f6b546d	LANGWARRIN	\N	VIC	SKYE	SKYE	SYNONYM	N
loc8a2c57a8fa9c	LEITCHVILLE	\N	VIC	GUNBOWER	GUNBOWER	SYNONYM	N
loc5900b8cc74c8	LEONGATHA	\N	VIC	KORUMBURRA	KORUMBURRA	SYNONYM	N
loc5900b8cc74c8	LEONGATHA	\N	VIC	MEENIYAN	MEENIYAN	SYNONYM	N
loc5ba812288f5b	LEOPOLD	\N	VIC	MOOLAP	MOOLAP	SYNONYM	N
loceb41e8eec3ee	LONGWARRY	\N	VIC	BUNYIP	BUNYIP	SYNONYM	N
loceb41e8eec3ee	LONGWARRY	\N	VIC	DROUIN	DROUIN	SYNONYM	N
locc672a234fa5a	LORNE	\N	VIC	WINCHELSEA	WINCHELSEA	SYNONYM	N
loccabf2d0215b8	MADDINGLEY	\N	VIC	BACCHUS MARSH	BACCHUS MARSH	SYNONYM	N
loc76dea039b41f	MALVERN	\N	VIC	ARMADALE	ARMADALE	SYNONYM	N
loc2d817b7080e2	MALVERN EAST	\N	VIC	GLEN IRIS	GLEN IRIS	SYNONYM	N
locffa1c8993b70	MAMBOURIN	\N	VIC	WYNDHAM VALE	WYNDHAM VALE	SYNONYM	N
loc875f8bb64843	MANOR LAKES	\N	VIC	WYNDHAM VALE	WYNDHAM VALE	SYNONYM	N
loc515028b0f98a	MANSFIELD	\N	VIC	GOUGHS BAY	GOUGHS BAY	SYNONYM	N
loc515028b0f98a	MANSFIELD	\N	VIC	NILLAHCOOTIE	NILLAHCOOTIE	SYNONYM	N
locb48ce003b11e	MARONG	\N	VIC	MAIDEN GULLY	MAIDEN GULLY	SYNONYM	N
loc556974a8bc81	MELTON	\N	VIC	ROCKBANK	ROCKBANK	SYNONYM	N
loc556974a8bc81	MELTON	\N	VIC	TOOLERN VALE	TOOLERN VALE	SYNONYM	N
loc63a05a113f90	MERBEIN	\N	VIC	BIRDWOODTON	BIRDWOODTON	SYNONYM	N
loc63a05a113f90	MERBEIN	\N	VIC	MILDURA	MILDURA	SYNONYM	N
loc1b271c01e3dc	MICKLEHAM	\N	VIC	CRAIGIEBURN	CRAIGIEBURN	SYNONYM	N
loc1b271c01e3dc	MICKLEHAM	\N	VIC	KALKALLO	KALKALLO	SYNONYM	N
loc1b271c01e3dc	MICKLEHAM	\N	VIC	YUROKE	YUROKE	SYNONYM	N
locb71d10cf3b7c	MILDURA	\N	VIC	CABARITA	CABARITA	SYNONYM	N
locb71d10cf3b7c	MILDURA	\N	VIC	IRYMPLE	IRYMPLE	SYNONYM	N
loc9901d119afda_1	MELBOURNE	\N	VIC	CARLTON	CARLTON	SYNONYM	N
locb71d10cf3b7c	MILDURA	\N	VIC	KOORLONG	KOORLONG	SYNONYM	N
locb71d10cf3b7c	MILDURA	\N	VIC	MERBEIN	MERBEIN	SYNONYM	N
loc4a7c5154c298	MOONEE PONDS	\N	VIC	ESSENDON	ESSENDON	SYNONYM	N
locea2e2e01b99c	MOORABBIN	\N	VIC	BENTLEIGH	BENTLEIGH	SYNONYM	N
loc11fb0b5df130	MORWELL	\N	VIC	TRARALGON	TRARALGON	SYNONYM	N
loc12cc6354a4ba	MOUNT CAMEL	\N	VIC	HEATHCOTE	HEATHCOTE	SYNONYM	N
loc90b2f4dd8c2d	MOUNT DUNEED	\N	VIC	CHARLEMONT	CHARLEMONT	SYNONYM	N
loc90b2f4dd8c2d	MOUNT DUNEED	\N	VIC	FRESHWATER CREEK	FRESHWATER CREEK	SYNONYM	N
loc90b2f4dd8c2d	MOUNT DUNEED	\N	VIC	GROVEDALE	GROVEDALE	SYNONYM	N
loc90b2f4dd8c2d	MOUNT DUNEED	\N	VIC	TORQUAY	TORQUAY	SYNONYM	N
loc20a81a4bf246	MOUNT EVELYN	\N	VIC	KALORAMA	KALORAMA	SYNONYM	N
loc20a81a4bf246	MOUNT EVELYN	\N	VIC	LILYDALE	LILYDALE	SYNONYM	N
loc20a81a4bf246	MOUNT EVELYN	\N	VIC	SILVAN	SILVAN	SYNONYM	N
loc5100fc96abff	MOUNT MARTHA	\N	VIC	BALNARRING	BALNARRING	SYNONYM	N
loc5100fc96abff	MOUNT MARTHA	\N	VIC	DROMANA	DROMANA	SYNONYM	N
loc15a8d395ef61	NAR NAR GOON	\N	VIC	BAYLES	BAYLES	SYNONYM	N
loc15a8d395ef61	NAR NAR GOON	\N	VIC	PAKENHAM	PAKENHAM	SYNONYM	N
loc4e07cec4cde4	NARRE WARREN EAST	\N	VIC	LYSTERFIELD	LYSTERFIELD	SYNONYM	N
loc6280f9052ec0	NARRE WARREN SOUTH	\N	VIC	BERWICK	BERWICK	SYNONYM	N
loc6280f9052ec0	NARRE WARREN SOUTH	\N	VIC	NARRE WARREN	NARRE WARREN	SYNONYM	N
loca4e166a620d9	NOBLE PARK	\N	VIC	DANDENONG	DANDENONG	SYNONYM	N
loce1597eda1cc3	NORLANE	\N	VIC	BELL PARK	BELL PARK	SYNONYM	N
loce1597eda1cc3	NORLANE	\N	VIC	CORIO	CORIO	SYNONYM	N
locd06d20cbea22	NORTH BENDIGO	\N	VIC	BENDIGO	BENDIGO	SYNONYM	N
locd06d20cbea22	NORTH BENDIGO	\N	VIC	EAGLEHAWK	EAGLEHAWK	SYNONYM	N
locd06d20cbea22	NORTH BENDIGO	\N	VIC	JACKASS FLAT	JACKASS FLAT	SYNONYM	N
locd06d20cbea22	NORTH BENDIGO	\N	VIC	WHITE HILLS	WHITE HILLS	SYNONYM	N
locbb6ca08c118e	NORTHCOTE	\N	VIC	FAIRFIELD	FAIRFIELD	SYNONYM	N
loc1e06c486c813	NORTH MELBOURNE	\N	VIC	WEST MELBOURNE	WEST MELBOURNE	SYNONYM	N
loc1e33f92d8409	NORTH WONTHAGGI	\N	VIC	WONTHAGGI	WONTHAGGI	SYNONYM	N
loc0b665c0fe535	OCEAN GROVE	\N	VIC	CERES	CERES	SYNONYM	N
loc0b665c0fe535	OCEAN GROVE	\N	VIC	HIGHTON	HIGHTON	SYNONYM	N
loc0b665c0fe535	OCEAN GROVE	\N	VIC	MARCUS HILL	MARCUS HILL	SYNONYM	N
loc0b665c0fe535	OCEAN GROVE	\N	VIC	WALLINGTON	WALLINGTON	SYNONYM	N
loc64c822b0bad5	OFFICER	\N	VIC	BEACONSFIELD	BEACONSFIELD	SYNONYM	N
loc64c822b0bad5	OFFICER	\N	VIC	PAKENHAM	PAKENHAM	SYNONYM	N
loc0b6e17218dd4	ORMOND	\N	VIC	BENTLEIGH	BENTLEIGH	SYNONYM	N
loc0b6e17218dd4	ORMOND	\N	VIC	MCKINNON	MCKINNON	SYNONYM	N
locf3eb6fff8056	OXLEY	\N	VIC	SPRINGHURST	SPRINGHURST	SYNONYM	N
loc82baa1179308	PAKENHAM	\N	VIC	NAR NAR GOON	NAR NAR GOON	SYNONYM	N
loc82baa1179308	PAKENHAM	\N	VIC	OFFICER	OFFICER	SYNONYM	N
loc9e7da77def26	PARKVILLE	\N	VIC	CARLTON	CARLTON	SYNONYM	N
locb344fc28a060	PEARCEDALE	\N	VIC	BAXTER	BAXTER	SYNONYM	N
locc5abea08e85d	POINT COOK	\N	VIC	WERRIBEE	WERRIBEE	SYNONYM	N
loc9a48431374e1	PORT MELBOURNE	\N	VIC	DOCKLANDS	DOCKLANDS	SYNONYM	N
loc250adfcbc82d	PRAHRAN	\N	VIC	ARMADALE	ARMADALE	SYNONYM	N
loc2c4c767ea9b7	PRESTON	\N	VIC	COBURG	COBURG	SYNONYM	N
loc2c4c767ea9b7	PRESTON	\N	VIC	RESERVOIR	RESERVOIR	SYNONYM	N
loc3fe991822440	RED HILL	\N	VIC	DROMANA	DROMANA	SYNONYM	N
loc3fe991822440	RED HILL	\N	VIC	MAIN RIDGE	MAIN RIDGE	SYNONYM	N
loc656f84726510	RESERVOIR	\N	VIC	PRESTON	PRESTON	SYNONYM	N
loc2508c9e5a93c	RIDDELLS CREEK	\N	VIC	GISBORNE	GISBORNE	SYNONYM	N
loc2508c9e5a93c	RIDDELLS CREEK	\N	VIC	MONEGEETTA	MONEGEETTA	SYNONYM	N
loc2508c9e5a93c	RIDDELLS CREEK	\N	VIC	MOUNT MACEDON	MOUNT MACEDON	SYNONYM	N
loc2508c9e5a93c	RIDDELLS CREEK	\N	VIC	ROMSEY	ROMSEY	SYNONYM	N
loc2508c9e5a93c	RIDDELLS CREEK	\N	VIC	SUNBURY	SUNBURY	SYNONYM	N
loc72d1f0339be6	RINGWOOD	\N	VIC	CROYDON	CROYDON	SYNONYM	N
loc46f8f01fbac9	RINGWOOD EAST	\N	VIC	CROYDON	CROYDON	SYNONYM	N
loc46f8f01fbac9	RINGWOOD EAST	\N	VIC	RINGWOOD	RINGWOOD	SYNONYM	N
loc1fbfb471eb7c	ROMSEY	\N	VIC	MONEGEETTA	MONEGEETTA	SYNONYM	N
locc81a6ec90a1b	ROSEBUD	\N	VIC	ARTHURS SEAT	ARTHURS SEAT	SYNONYM	N
locc81a6ec90a1b	ROSEBUD	\N	VIC	BONEO	BONEO	SYNONYM	N
locfd8472c41cbe	ROWVILLE	\N	VIC	FERNTREE GULLY	FERNTREE GULLY	SYNONYM	N
loc3754c5fc3408	ROXBURGH PARK	\N	VIC	CRAIGIEBURN	CRAIGIEBURN	SYNONYM	N
locc586266ef8cc	SALE	\N	VIC	GOLDEN BEACH	GOLDEN BEACH	SYNONYM	N
locc586266ef8cc	SALE	\N	VIC	ROSEDALE	ROSEDALE	SYNONYM	N
loc679429866800	SANDY CREEK	\N	VIC	CHARLEROI	CHARLEROI	SYNONYM	N
loc679429866800	SANDY CREEK	\N	VIC	TANGAMBALANGA	TANGAMBALANGA	SYNONYM	N
locb948618ae376	SEBASTOPOL	\N	VIC	DELACOMBE	DELACOMBE	SYNONYM	N
locb948618ae376	SEBASTOPOL	\N	VIC	MOUNT CLEAR	MOUNT CLEAR	SYNONYM	N
loc1b289d3ff2fc	SHEPPARTON	\N	VIC	CONGUPNA	CONGUPNA	SYNONYM	N
locc098f71b2faf	SOLDIERS HILL	\N	VIC	BLACK HILL	BLACK HILL	SYNONYM	N
locf51f6cd689bb	SOUTH MELBOURNE	\N	VIC	ALBERT PARK	ALBERT PARK	SYNONYM	N
loc22c42e389de3	SOUTH MORANG	\N	VIC	EPPING	EPPING	SYNONYM	N
loc22c42e389de3	SOUTH MORANG	\N	VIC	MILL PARK	MILL PARK	SYNONYM	N
locc2ea2de6af6c	SOUTH YARRA	\N	VIC	ARMADALE	ARMADALE	SYNONYM	N
loc3b583afba248	SPRINGVALE SOUTH	\N	VIC	NOBLE PARK	NOBLE PARK	SYNONYM	N
locfe955a87410d	ST KILDA	\N	VIC	ALBERT PARK	ALBERT PARK	SYNONYM	N
loc13ed320cd188	STRATHFIELDSAYE	\N	VIC	EMU CREEK	EMU CREEK	SYNONYM	N
loc13ed320cd188	STRATHFIELDSAYE	\N	VIC	EPPALOCK	EPPALOCK	SYNONYM	N
loc13ed320cd188	STRATHFIELDSAYE	\N	VIC	JUNORTOUN	JUNORTOUN	SYNONYM	N
loc13ed320cd188	STRATHFIELDSAYE	\N	VIC	KENNINGTON	KENNINGTON	SYNONYM	N
loc1eda86883ae9	SUNDERLAND BAY	\N	VIC	COWES	COWES	SYNONYM	N
loc46443686a430	SUNSHINE WEST	\N	VIC	SUNSHINE	SUNSHINE	SYNONYM	N
loc819a06b032e3	TARNEIT	\N	VIC	WERRIBEE	WERRIBEE	SYNONYM	N
loc6de6554b144b	TAWONGA SOUTH	\N	VIC	DEDERANG	DEDERANG	SYNONYM	N
loc6de6554b144b	TAWONGA SOUTH	\N	VIC	MOUNT BEAUTY	MOUNT BEAUTY	SYNONYM	N
locc91f4a31a1bc	TAYLORS HILL	\N	VIC	CAROLINE SPRINGS	CAROLINE SPRINGS	SYNONYM	N
locc91f4a31a1bc	TAYLORS HILL	\N	VIC	HILLSIDE	HILLSIDE	SYNONYM	N
locc91f4a31a1bc	TAYLORS HILL	\N	VIC	SYDENHAM	SYDENHAM	SYNONYM	N
locf065e41cfac9	TAYLORS LAKES	\N	VIC	KEILOR	KEILOR	SYNONYM	N
loc406d1f7b5fe3	TEMPLESTOWE	\N	VIC	ELTHAM	ELTHAM	SYNONYM	N
loc75d84680b181	TENNYSON	\N	VIC	LOCKINGTON	LOCKINGTON	SYNONYM	N
loc75d84680b181	TENNYSON	\N	VIC	MITIAMO	MITIAMO	SYNONYM	N
loc75d84680b181	TENNYSON	\N	VIC	PRAIRIE	PRAIRIE	SYNONYM	N
loc8f565e81c655	THOMASTOWN	\N	VIC	BUNDOORA	BUNDOORA	SYNONYM	N
loc8f565e81c655	THOMASTOWN	\N	VIC	LALOR	LALOR	SYNONYM	N
loce0707ac065f9	THOMSON	3219	VIC	BREAKWATER	BREAKWATER	SYNONYM	N
loce0707ac065f9	THOMSON	3219	VIC	EAST GEELONG	EAST GEELONG	SYNONYM	N
loc82b861dfb765	THORNBURY	\N	VIC	RESERVOIR	RESERVOIR	SYNONYM	N
loc6c0f29d040f7	TORRUMBARRY	\N	VIC	WHARPARILLA	WHARPARILLA	SYNONYM	N
loc1c5f2c23fc52	TOWONG	\N	VIC	CORRYONG	CORRYONG	SYNONYM	N
loc5e975e2e1c0e	TRAFALGAR	\N	VIC	WESTBURY	WESTBURY	SYNONYM	N
loc5e975e2e1c0e	TRAFALGAR	\N	VIC	YARRAGON	YARRAGON	SYNONYM	N
loc8e5a2b16aaaa	TRARALGON	\N	VIC	MORWELL	MORWELL	SYNONYM	N
loc8f498b475ec6	TRARALGON EAST	\N	VIC	GLENGARRY	GLENGARRY	SYNONYM	N
loc8f498b475ec6	TRARALGON EAST	\N	VIC	TRARALGON	TRARALGON	SYNONYM	N
loc399d9bd46679	TYLDEN	\N	VIC	KYNETON	KYNETON	SYNONYM	N
loc399d9bd46679	TYLDEN	\N	VIC	TRENTHAM	TRENTHAM	SYNONYM	N
loc399d9bd46679	TYLDEN	\N	VIC	WOODEND	WOODEND	SYNONYM	N
loc991c414cb6c9	UPPER PLENTY	\N	VIC	HEATHCOTE JUNCTION	HEATHCOTE JUNCTION	SYNONYM	N
loc991c414cb6c9	UPPER PLENTY	\N	VIC	WALLAN	WALLAN	SYNONYM	N
loc991c414cb6c9	UPPER PLENTY	\N	VIC	WHITTLESEA	WHITTLESEA	SYNONYM	N
locc605118e951a	WALLAN	\N	VIC	BYLANDS	BYLANDS	SYNONYM	N
locc605118e951a	WALLAN	\N	VIC	DARRAWEIT GUIM	DARRAWEIT GUIM	SYNONYM	N
loc532c3dac4248	WALMER	\N	VIC	BARKERS CREEK	BARKERS CREEK	SYNONYM	N
loc532c3dac4248	WALMER	\N	VIC	MALDON	MALDON	SYNONYM	N
loc2424df148d7d	WANDIN EAST	\N	VIC	SILVAN	SILVAN	SYNONYM	N
loc5c7c3d320a8a	WANGARATTA	\N	VIC	WANGANDARY	WANGANDARY	SYNONYM	N
locd724f9a08a75	WARRAGUL	\N	VIC	DROUIN	DROUIN	SYNONYM	N
locae68612e5fe1	WARRANWOOD	\N	VIC	WONGA PARK	WONGA PARK	SYNONYM	N
loc1f73672977ce	WARRNAMBOOL	\N	VIC	WANGOOM	WANGOOM	SYNONYM	N
loc1f73672977ce	WARRNAMBOOL	\N	VIC	WOODFORD	WOODFORD	SYNONYM	N
loce36428dd6505	WELSHMANS REEF	\N	VIC	MALDON	MALDON	SYNONYM	N
loc29a798d6921b	WERRIBEE	\N	VIC	TARNEIT	TARNEIT	SYNONYM	N
loca818c5eaa373	WEST FOOTSCRAY	\N	VIC	TOTTENHAM	TOTTENHAM	SYNONYM	N
loc0b8afd71fce1	WEST MELBOURNE	\N	VIC	DOCKLANDS	DOCKLANDS	SYNONYM	N
loc3832b905a97e	WEST WODONGA	\N	VIC	WODONGA	WODONGA	SYNONYM	N
locf2d2a267a354	WINCHELSEA	\N	VIC	BIRREGURRA	BIRREGURRA	SYNONYM	N
locf2d2a267a354	WINCHELSEA	\N	VIC	BUCKLEY	BUCKLEY	SYNONYM	N
locf2d2a267a354	WINCHELSEA	\N	VIC	OMBERSLEY	OMBERSLEY	SYNONYM	N
locf2d2a267a354	WINCHELSEA	\N	VIC	WURDIBOLUC	WURDIBOLUC	SYNONYM	N
loc6a54ce63b777	WINTER VALLEY	\N	VIC	DELACOMBE	DELACOMBE	SYNONYM	N
loc6a54ce63b777	WINTER VALLEY	\N	VIC	SMYTHES CREEK	SMYTHES CREEK	SYNONYM	N
loc6d7f0d49a3d6	WOLLERT	\N	VIC	CRAIGIEBURN	CRAIGIEBURN	SYNONYM	N
loc6d7f0d49a3d6	WOLLERT	\N	VIC	EPPING	EPPING	SYNONYM	N
loceac5d85ea01d	WYNDHAM VALE	\N	VIC	WERRIBEE	WERRIBEE	SYNONYM	N
loc610e6e8cd167	YARRA GLEN	\N	VIC	CHRISTMAS HILLS	CHRISTMAS HILLS	SYNONYM	N
locb0a9c63101c7	YARRAWONGA	\N	VIC	LAKE ROWAN	LAKE ROWAN	SYNONYM	N
loc956fa85c7b0c	PORTARLINGTON	\N	VIC	ST LEONARDS	SAINT LEONARDS	SYNONYM	Y
locb694454fbbb1	CANTERBURY	\N	VIC	HAWTHORN EAST	EAST HAWTHORN	SYNONYM	Y
loc86dc9bf35404	CLAYTON	\N	VIC	OAKLEIGH EAST	EAST OAKLEIGH	SYNONYM	Y
loca674ab421c49	EUROA	\N	VIC	LONGWOOD EAST	EAST LONGWOOD	SYNONYM	Y
locb71d10cf3b7c	MILDURA	\N	VIC	MILDURA EAST	EAST MILDURA	SYNONYM	Y
loc0b6e17218dd4	ORMOND	\N	VIC	BRIGHTON EAST	EAST BRIGHTON	SYNONYM	Y
loc72d1f0339be6	RINGWOOD	\N	VIC	RINGWOOD EAST	EAST RINGWOOD	SYNONYM	Y
loc6c0f29d040f7	TORRUMBARRY	\N	VIC	TORRUMBARRY EAST	EAST TORRUMBARRY	SYNONYM	Y
locc605118e951a	WALLAN	\N	VIC	WALLAN EAST	EAST WALLAN	SYNONYM	Y
loc5c7c3d320a8a	WANGARATTA	\N	VIC	WANGARATTA EAST	EAST WANGARATTA	SYNONYM	Y
locd724f9a08a75	WARRAGUL	\N	VIC	DROUIN EAST	EAST DROUIN	SYNONYM	Y
loc7c934a667999	HASTINGS	\N	VIC	HASTINGS WEST	WEST HASTINGS	SYNONYM	Y
loc62ed665318da	KYABRAM	\N	VIC	KY WEST	WEST KY	SYNONYM	Y
locb71d10cf3b7c	MILDURA	\N	VIC	MILDURA WEST	WEST MILDURA	SYNONYM	Y
loc11fb0b5df130	MORWELL	\N	VIC	MORWELL WEST	WEST MORWELL	SYNONYM	Y
loc8e5a2b16aaaa	TRARALGON	\N	VIC	TRARALGON WEST	WEST TRARALGON	SYNONYM	Y
locdf0288b649a4	WODONGA	\N	VIC	WODONGA WEST	WEST WODONGA	SYNONYM	Y
loc712bc92c5924	BUNDOORA	\N	VIC	WATSONIA NORTH	NORTH WATSONIA	SYNONYM	Y
locd755ccb7197e	DANDENONG NORTH	\N	VIC	NOBLE PARK NORTH	NORTH NOBLE PARK	SYNONYM	Y
locc7ee8539a72b	ELTHAM	\N	VIC	ELTHAM NORTH	NORTH ELTHAM	SYNONYM	Y
loceb41e8eec3ee	LONGWARRY	\N	VIC	LONGWARRY NORTH	NORTH LONGWARRY	SYNONYM	Y
loc11fb0b5df130	MORWELL	\N	VIC	MORWELL NORTH	NORTH MORWELL	SYNONYM	Y
loc46f8f01fbac9	RINGWOOD EAST	\N	VIC	BAYSWATER NORTH	NORTH BAYSWATER	SYNONYM	Y
locd724f9a08a75	WARRAGUL	\N	VIC	WARRAGUL NORTH	NORTH WARRAGUL	SYNONYM	Y
loca5de38b84720	BOX HILL	\N	VIC	BOX HILL SOUTH	SOUTH BOX HILL	SYNONYM	Y
loc9fb289b0a33e	IRYMPLE	\N	VIC	IRYMPLE SOUTH	SOUTH IRYMPLE	SYNONYM	Y
locb71d10cf3b7c	MILDURA	\N	VIC	MILDURA SOUTH	SOUTH MILDURA	SYNONYM	Y
loc82baa1179308	PAKENHAM	\N	VIC	OFFICER SOUTH	SOUTH OFFICER	SYNONYM	Y
loc399d9bd46679	TYLDEN	\N	VIC	TYLDEN SOUTH	SOUTH TYLDEN	SYNONYM	Y
loc532c3dac4248	WALMER	\N	VIC	RAVENSWOOD SOUTH	SOUTH RAVENSWOOD	SYNONYM	Y
loc4a341f4d3e02	WANTIRNA	\N	VIC	WANTIRNA SOUTH	SOUTH WANTIRNA	SYNONYM	Y
loc679429866800	SANDY CREEK	\N	VIC	SANDY CREEK UPPER	UPPER SANDY CREEK	SYNONYM	Y
locb9872f35df41	ABBOTSFORD	\N	VIC	CLIFTON HILL	CLIFTON HILL	SYNONYM	Y
locb9872f35df41	ABBOTSFORD	\N	VIC	FITZROY	FITZROY	SYNONYM	Y
locec99dd6d0979	ALTONA MEADOWS	\N	VIC	SEABROOK	SEABROOK	SYNONYM	Y
loc08caad3924ee	ALTONA NORTH	\N	VIC	BROOKLYN	BROOKLYN	SYNONYM	Y
loc08caad3924ee	ALTONA NORTH	\N	VIC	NEWPORT	NEWPORT	SYNONYM	Y
loc08caad3924ee	ALTONA NORTH	\N	VIC	SOUTH KINGSVILLE	SOUTH KINGSVILLE	SYNONYM	Y
locd777103bd088	BACCHUS MARSH	\N	VIC	PENTLAND HILLS	PENTLAND HILLS	SYNONYM	Y
locba8f7a4a0c92	BARANDUDA	\N	VIC	BARANDUDA GROVE	BARANDUDA GROVE	SYNONYM	Y
locba8f7a4a0c92	BARANDUDA	\N	VIC	BARANDUDA RANGE	BARANDUDA RANGE	SYNONYM	Y
locff58d0167065	BENALLA	\N	VIC	GOOMALIBEE	GOOMALIBEE	SYNONYM	Y
loce6098ac5df0c	BENDIGO	\N	VIC	BENDIGO FORWARD	BENDIGO FORWARD	SYNONYM	Y
locad899e5d272f	BLACK ROCK	\N	VIC	BEAUMARIS	BEAUMARIS	SYNONYM	Y
loc74f8893fb76e	BROADMEADOWS	\N	VIC	DALLAS	DALLAS	SYNONYM	Y
loc712bc92c5924	BUNDOORA	\N	VIC	KINGSBURY	KINGSBURY	SYNONYM	Y
locb694454fbbb1	CANTERBURY	\N	VIC	SURREY HILLS	SURREY HILLS	SYNONYM	Y
loca0398a35cf5e	CARLTON	\N	VIC	PARKVILLE	PARKVILLE	SYNONYM	Y
loc86cf2bd4847b	CARNEGIE	\N	VIC	MURRUMBEENA	MURRUMBEENA	SYNONYM	Y
locffd0eebac0eb	CHELSEA	\N	VIC	BONBEACH	BONBEACH	SYNONYM	Y
locbd7d4fd6b9e7	COBURG	\N	VIC	MORELAND	MORELAND	SYNONYM	Y
loc9fe59dbd0874	CRANBOURNE NORTH	\N	VIC	CARRUM DOWNS	CARRUM DOWNS	SYNONYM	Y
loc70eb03d586f8	DEER PARK	\N	VIC	ALBANVALE	ALBANVALE	SYNONYM	Y
loc70eb03d586f8	DEER PARK	\N	VIC	DERRIMUT	DERRIMUT	SYNONYM	Y
loc70eb03d586f8	DEER PARK	\N	VIC	KINGS PARK	KINGS PARK	SYNONYM	Y
loca2fd80ef71d3	DEREEL	\N	VIC	CORINDHAP	CORINDHAP	SYNONYM	Y
locddc4a1bcd8ba	DOCKLANDS	\N	VIC	WORLD TRADE CENTRE	WORLD TRADE CENTRE	SYNONYM	Y
loc7ab22202aac3	DONCASTER	\N	VIC	BULLEEN	BULLEEN	SYNONYM	Y
loc7a8164839d54	DONCASTER EAST	\N	VIC	DONVALE	DONVALE	SYNONYM	Y
locc7ee8539a72b	ELTHAM	\N	VIC	RESEARCH	RESEARCH	SYNONYM	Y
loca674ab421c49	EUROA	\N	VIC	SHEANS CREEK	SHEANS CREEK	SYNONYM	Y
loca5643321b976	FIERY FLAT	\N	VIC	KINYPANIAL	KINYPANIAL	SYNONYM	Y
loca5643321b976	FIERY FLAT	\N	VIC	POWLETT PLAINS	POWLETT PLAINS	SYNONYM	Y
loc92bf5bc798e7	FLEMINGTON	\N	VIC	ASCOT VALE	ASCOT VALE	SYNONYM	Y
loc92bf5bc798e7	FLEMINGTON	\N	VIC	KENSINGTON	KENSINGTON	SYNONYM	Y
loc67a11408d754	FOOTSCRAY	\N	VIC	SEDDON	SEDDON	SYNONYM	Y
loce11f06c54f46	GISBORNE	\N	VIC	NEW GISBORNE	NEW GISBORNE	SYNONYM	Y
locadc5cabaa80e	GLEN IRIS	\N	VIC	ASHBURTON	ASHBURTON	SYNONYM	Y
loc4858bcc1d912	GLENROY	\N	VIC	OAK PARK	OAK PARK	SYNONYM	Y
loc338a35dd09f0	GOLDEN SQUARE	\N	VIC	SPECIMEN HILL	SPECIMEN HILL	SYNONYM	Y
locb53ace4ff1b6	GREAT WESTERN	\N	VIC	BLACK RANGE	BLACK RANGE	SYNONYM	Y
loc4883549a5421	GREENVALE	\N	VIC	ATTWOOD	ATTWOOD	SYNONYM	Y
loc4423238fcdd8	HAMILTON	\N	VIC	BUCKLEY SWAMP	BUCKLEY SWAMP	SYNONYM	Y
loc4423238fcdd8	HAMILTON	\N	VIC	HAMILTON PARK	HAMILTON PARK	SYNONYM	Y
loc7c934a667999	HASTINGS	\N	VIC	HASTINGS FORWARD	HASTINGS FORWARD	SYNONYM	Y
loc201e214973bd	IVANHOE	\N	VIC	HEIDELBERG HEIGHTS	HEIDELBERG HEIGHTS	SYNONYM	Y
loc1a22f173d7f3	JUNCTION VILLAGE	\N	VIC	BOTANIC RIDGE	BOTANIC RIDGE	SYNONYM	Y
loce25dfc481765	KILMORE	\N	VIC	WILLOWMAVIN	WILLOWMAVIN	SYNONYM	Y
loc38cbe92d1159	KILSYTH	\N	VIC	BORONIA	BORONIA	SYNONYM	Y
locbf553ce41d73	KIRWANS BRIDGE	\N	VIC	BAILIESTON	BAILIESTON	SYNONYM	Y
locbf553ce41d73	KIRWANS BRIDGE	\N	VIC	KIRWINS BRIDGE	KIRWINS BRIDGE	SYNONYM	Y
loc62ed665318da	KYABRAM	\N	VIC	KYVALLEY	KYVALLEY	SYNONYM	Y
loc62ed665318da	KYABRAM	\N	VIC	LANCASTER	LANCASTER	SYNONYM	Y
loc62ed665318da	KYABRAM	\N	VIC	MOUNT SCOBIE	MOUNT SCOBIE	SYNONYM	Y
loce16236caf708	LARA	\N	VIC	LITTLE RIVER	LITTLE RIVER	SYNONYM	Y
loc556974a8bc81	MELTON	\N	VIC	HARKNESS	HARKNESS	SYNONYM	Y
locdd716f1059c5	MENTONE	\N	VIC	MOORABBIN AIRPORT	MOORABBIN AIRPORT	SYNONYM	Y
locb71d10cf3b7c	MILDURA	\N	VIC	LAKE HAWTHORN	LAKE HAWTHORN	SYNONYM	Y
locb71d10cf3b7c	MILDURA	\N	VIC	MILDURA CENTRE PLAZA	MILDURA CENTRE PLAZA	SYNONYM	Y
locb71d10cf3b7c	MILDURA	\N	VIC	NICHOLS POINT	NICHOLS POINT	SYNONYM	Y
locb71d10cf3b7c	MILDURA	\N	VIC	OUYEN	OUYEN	SYNONYM	Y
loc4a7c5154c298	MOONEE PONDS	\N	VIC	ABERFELDIE	ABERFELDIE	SYNONYM	Y
locea2e2e01b99c	MOORABBIN	\N	VIC	BRIGHTON	BRIGHTON	SYNONYM	Y
loc8688ba223de1	MOUNT BULLER	\N	VIC	BLACK DOG CREEK	BLACK DOG CREEK	SYNONYM	Y
loc8688ba223de1	MOUNT BULLER	\N	VIC	KNOCKWOOD	KNOCKWOOD	SYNONYM	Y
loc8688ba223de1	MOUNT BULLER	\N	VIC	MT BULLER	MT BULLER	SYNONYM	Y
loc12cc6354a4ba	MOUNT CAMEL	\N	VIC	LADYS PASS	LADYS PASS	SYNONYM	Y
loc12cc6354a4ba	MOUNT CAMEL	\N	VIC	MT CAMEL	MT CAMEL	SYNONYM	Y
loc12cc6354a4ba	MOUNT CAMEL	\N	VIC	REDCASTLE	REDCASTLE	SYNONYM	Y
loc90b2f4dd8c2d	MOUNT DUNEED	\N	VIC	MT DUNEED	MT DUNEED	SYNONYM	Y
loc20a81a4bf246	MOUNT EVELYN	\N	VIC	MT EVELYN	MT EVELYN	SYNONYM	Y
loc5100fc96abff	MOUNT MARTHA	\N	VIC	MT MARTHA	MT MARTHA	SYNONYM	Y
loc5100fc96abff	MOUNT MARTHA	\N	VIC	SAFETY BEACH	SAFETY BEACH	SYNONYM	Y
loca1b6ce72e35a	MOUNT WAVERLEY	\N	VIC	MT WAVERLEY	MT WAVERLEY	SYNONYM	Y
loce01ddbd8c8e5	NAGAMBIE	\N	VIC	TABILK	TABILK	SYNONYM	Y
loce1597eda1cc3	NORLANE	\N	VIC	NORTH SHORE	NORTH SHORE	SYNONYM	Y
loc1e33f92d8409	NORTH WONTHAGGI	\N	VIC	POWLETT RIVER	POWLETT RIVER	SYNONYM	Y
loc51ba976fe589	OAK PARK	\N	VIC	GLENROY	GLENROY	SYNONYM	Y
loc025dead673cc	PARKDALE	\N	VIC	MORDIALLOC	MORDIALLOC	SYNONYM	Y
loc9e7da77def26	PARKVILLE	\N	VIC	ROYAL MELBOURNE HOSPITAL	ROYAL MELBOURNE HOSPITAL	SYNONYM	Y
locc5abea08e85d	POINT COOK	\N	VIC	PT COOK	PT COOK	SYNONYM	Y
locc5abea08e85d	POINT COOK	\N	VIC	WESTERN GARDENS	WESTERN GARDENS	SYNONYM	Y
loc67d2e4d427ab	PORTSEA	\N	VIC	SORRENTO	SORRENTO	SYNONYM	Y
loce48c38ae2d6a	RICHMOND	\N	VIC	ABBOTSFORD	ABBOTSFORD	SYNONYM	Y
loce48c38ae2d6a	RICHMOND	\N	VIC	BURNLEY	BURNLEY	SYNONYM	Y
loc2508c9e5a93c	RIDDELLS CREEK	\N	VIC	SPRING CREEK	SPRING CREEK	SYNONYM	Y
loc1fbfb471eb7c	ROMSEY	\N	VIC	KERRIE	KERRIE	SYNONYM	Y
locc81a6ec90a1b	ROSEBUD	\N	VIC	CAPEL SOUND	CAPEL SOUND	SYNONYM	Y
loc3754c5fc3408	ROXBURGH PARK	\N	VIC	GREENVALE	GREENVALE	SYNONYM	Y
locc586266ef8cc	SALE	\N	VIC	COBAINS	COBAINS	SYNONYM	Y
locc586266ef8cc	SALE	\N	VIC	SALE EAST RAAF	SALE EAST RAAF	SYNONYM	Y
loc679429866800	SANDY CREEK	\N	VIC	HUON	HUON	SYNONYM	Y
loc3b583afba248	SPRINGVALE SOUTH	\N	VIC	SPRINGVALE	SPRINGVALE	SYNONYM	Y
loc34a55c4d0462	ST ALBANS	\N	VIC	CAIRNLEA	CAIRNLEA	SYNONYM	Y
locfe955a87410d	ST KILDA	\N	VIC	BALACLAVA	BALACLAVA	SYNONYM	Y
locfe955a87410d	ST KILDA	\N	VIC	WINDSOR	WINDSOR	SYNONYM	Y
loc2c9ce0acd6de	ST LEONARDS	\N	VIC	INDENTED HEAD	INDENTED HEAD	SYNONYM	Y
loc46443686a430	SUNSHINE WEST	\N	VIC	ARDEER	ARDEER	SYNONYM	Y
locedacea740a10	SWAN HILL	\N	VIC	MURRAWEE	MURRAWEE	SYNONYM	Y
locf065e41cfac9	TAYLORS LAKES	\N	VIC	ROBERTSON	ROBERTSON	SYNONYM	Y
loc75d84680b181	TENNYSON	\N	VIC	DIGGORA	DIGGORA	SYNONYM	Y
loc75d84680b181	TENNYSON	\N	VIC	PIAVELLA	PIAVELLA	SYNONYM	Y
locba5e689e47f8	TORQUAY	\N	VIC	TORQUAY HEIGHTS	TORQUAY HEIGHTS	SYNONYM	Y
loc6c0f29d040f7	TORRUMBARRY	\N	VIC	ROSLYNMEAD	ROSLYNMEAD	SYNONYM	Y
loc8fef59c1c585	TULLAMARINE	\N	VIC	MELBOURNE AIRPORT	MELBOURNE AIRPORT	SYNONYM	Y
loc991c414cb6c9	UPPER PLENTY	\N	VIC	BEVERIDGE	BEVERIDGE	SYNONYM	Y
loc991c414cb6c9	UPPER PLENTY	\N	VIC	PLENTY	PLENTY	SYNONYM	Y
loc532c3dac4248	WALMER	\N	VIC	PORCUPINE FLAT	PORCUPINE FLAT	SYNONYM	Y
loc2424df148d7d	WANDIN EAST	\N	VIC	WANDIN YALLOCK	WANDIN YALLOCK	SYNONYM	Y
loc5c7c3d320a8a	WANGARATTA	\N	VIC	WALDARA	WALDARA	SYNONYM	Y
loc5c7c3d320a8a	WANGARATTA	\N	VIC	WANGARATTA FORWARD	WANGARATTA FORWARD	SYNONYM	Y
loc4a341f4d3e02	WANTIRNA	\N	VIC	BAYSWATER	BAYSWATER	SYNONYM	Y
loc1f73672977ce	WARRNAMBOOL	\N	VIC	ALLANSFORD	ALLANSFORD	SYNONYM	Y
loc06cc48b309e5	WATSONIA	\N	VIC	MACLEOD	MACLEOD	SYNONYM	Y
loc29a798d6921b	WERRIBEE	\N	VIC	HOPPERS CROSSING	HOPPERS CROSSING	SYNONYM	Y
loc0b8afd71fce1	WEST MELBOURNE	\N	VIC	NORTH MELBOURNE	NORTH MELBOURNE	SYNONYM	Y
loc8c9f2867857c	WILLIAMSTOWN	\N	VIC	ALTONA	ALTONA	SYNONYM	Y
locf2d2a267a354	WINCHELSEA	\N	VIC	ARMYTAGE	ARMYTAGE	SYNONYM	Y
locf2d2a267a354	WINCHELSEA	\N	VIC	RICKETTS MARSH	RICKETTS MARSH	SYNONYM	Y
locdf0288b649a4	WODONGA	\N	VIC	BANDIANA	BANDIANA	SYNONYM	Y
locdf0288b649a4	WODONGA	\N	VIC	LENEVA	LENEVA	SYNONYM	Y
locdf0288b649a4	WODONGA	\N	VIC	WODONGA FORWARD	WODONGA FORWARD	SYNONYM	Y
loc6d7f0d49a3d6	WOLLERT	\N	VIC	YAN YEAN	YAN YEAN	SYNONYM	Y
loceac5d85ea01d	WYNDHAM VALE	\N	VIC	MANOR LAKES	MANOR LAKES	SYNONYM	Y
loc9901d119afda_1	MELBOURNE	\N	VIC	EAST MELBOURNE	EAST MELBOURNE	SYNONYM	Y
loc9901d119afda_1	MELBOURNE	\N	VIC	UNIVERSITY OF MELBOURNE	UNIVERSITY OF MELBOURNE	SYNONYM	Y
\.

-- gnaf_202602.locality_neighbour_lookup: 1709 rows
\copy gnaf_202602.locality_neighbour_lookup FROM stdin
loc712bc92c5924	locd8a8ad3be01a
loc4423238fcdd8	loced9b7fe29630
loc09a99bf786b9	loce7aa43e88406
locea2e2e01b99c	locf16910f90fb9
loc0a03ed3531fd	locf16910f90fb9
loc201e214973bd	loc2c4c767ea9b7
loc5c27e3f22fc1	locb9872f35df41
locb344fc28a060	loc5bf094d10d8e
loc08caad3924ee	locc134b649436c
locedacea740a10	loc848b39f37561
loc556974a8bc81	locb3584a0e11e8
loc3754c5fc3408	locc67851215f08
loc47e9d5554e9d	loce6fe9cedd8c7
locb948618ae376	locf1acbec8baed
loc6de6554b144b	loc3e25831f96a8
loc8733d13ded2e	loccaf1b7ac7ed3
locffa1c8993b70	loceac5d85ea01d
loc38cbe92d1159	loc9165cd64854f
loc63a05a113f90	loc0f38b5d63616
locabdfa0718385	loc556974a8bc81
loc12c0177d3d38	loc4dfb8458b2e2
loce01ddbd8c8e5	locbf553ce41d73
locba5e689e47f8	locea47e3f6990f
loc0e534d470df9	loc12cc6354a4ba
loc6280f9052ec0	loc0475beb19ff3
locc67851215f08	loc3754c5fc3408
locdd716f1059c5	loce237bfb5fc0e
loc82b861dfb765	loc42979bc97c35
loc15a8d395ef61	loc7b6dac86f8e1
loc3754c5fc3408	locfb9f1336aa98
locc84be248155b	loca6d8813738eb
loc92bf5bc798e7	loc67a11408d754
loc8688ba223de1	loca8d2b4d0b1b2
locc586266ef8cc	loc69354e91c0cc
loc47e9d5554e9d	loc3e010de7b16c
locc5abea08e85d	loc098ac8eaabef
loca56f2b16461e	loc2ef00ac196a6
loc5c7c3d320a8a	loc91986fb3c2b4
loc0a03ed3531fd	loce237bfb5fc0e
loc6a54ce63b777	loc98325a7e67bf
loc780d4ed4ca46	loc346283553b3d
loc6de6554b144b	loc71cd3ca85009
loc5c27e3f22fc1	loc00a9769647d7
loc12c0177d3d38	locbb5f291d781d
loc0a8087d68433	loc6442dc787b13
loc2508c9e5a93c	loc7c970583e8e4
loca1b6ce72e35a	loc00d1503504f1
loc0067a4549ed1	loca27c9809ab3c
locc7ee8539a72b	loc42e60600a8c9
loc70eb03d586f8	loc1cd13a25341f
loce48c38ae2d6a	locc2ea2de6af6c
loc17a18f5ff3a6	loc05e50c5030cd
loc17a18f5ff3a6	locbb31ea1d3b07
locc81a6ec90a1b	loc4cdd1af01845
locedacea740a10	loc89da05c8787d
loca37d9a7b347e	loc3267756bcd76
locc67851215f08	loc74f8893fb76e
loc991c414cb6c9	loc69381be73d8b
loce48c38ae2d6a	loc00a9769647d7
loca1b6ce72e35a	loc86a790ccadf9
loc9a86c6faf562	loc66b84c1dbc12
locb9872f35df41	loc00a9769647d7
loc15a8d395ef61	loc9e030c68a944
loc79e45c9fa669	loc82b861dfb765
locf8d60bf51b6b	loca529180576a5
locc586266ef8cc	locaec34a061bc8
loce6098ac5df0c	locd7ab572b3677
loc17a18f5ff3a6	loc8733d13ded2e
loc515028b0f98a	loc806561c3d7fa
loc12c0177d3d38	loc731aac9d3e93
locc5abea08e85d	loc29a798d6921b
loc00a9769647d7	locb694454fbbb1
loc67a11408d754	loca818c5eaa373
locf4e180745c81	loc819aeb5db205
loc06cc48b309e5	loc712bc92c5924
loc0b8afd71fce1	loc1e06c486c813
loc5c94ac6107ca	loced6917ed9b9b
loc1eda86883ae9	loc9525dc779efd
loc7213d03738b9	loc74f8893fb76e
locc098f71b2faf	locf293eac14028
loc5c7c3d320a8a	locdb359fd94a95
locf4e180745c81	loce69259513060
loce25dfc481765	loc8ce71441c12b
loc1e06c486c813	loc0b8afd71fce1
locb9872f35df41	loc1032c5d1ed5f
locff58d0167065	locede7f63fcf49
locd724f9a08a75	locb967fc3f46bc
loccd13bd88b567	loc7d9d9818d4b9
loc819a06b032e3	loceac5d85ea01d
loc399d9bd46679	loc03c8729d5d9f
loc2c9ce0acd6de	loc44075823cebd
loc70eb03d586f8	locc7baa224b862
loc9165cd64854f	loc7d9d9818d4b9
locedacea740a10	loc4ddd342eb849
loc9fe59dbd0874	loc2f79d3187e1a
loc76dea039b41f	loc8c9914c41758
locfdc6079b562f	loc11b2a92fb5f0
locc672a234fa5a	loc244a8ca56662
locc586266ef8cc	loce76eead3fa8b
locf4e180745c81	loca868732226b1
locba5e689e47f8	loc90b2f4dd8c2d
locb948618ae376	locb2505e62d563
loce01ddbd8c8e5	loc6b57f730f7be
locd6f79866f950	loc7d9d9818d4b9
locd6190ebbe554	locc89924437933
loc399d9bd46679	loc7857297a552f
locf57f2052e543	locccf64b3f1134
locff58d0167065	locc89198ff476b
loc875118ed8437	loca0398a35cf5e
loca56f2b16461e	loc7ab22202aac3
locba5e689e47f8	loc6a5903165043
loce48c38ae2d6a	loc7c0af2fd89ec
loc4161e46afd2f	loc69381be73d8b
loca37d9a7b347e	loc489b61204e02
loc87f2ad0c0fd7	locc2ea2de6af6c
loc4a341f4d3e02	loc72d1f0339be6
loc712bc92c5924	loc8f565e81c655
loc3d949ab3c987	loc89cee4954cc2
loc86cf2bd4847b	locc1978682d520
loc7ab22202aac3	locc89665bfa152
loc13ed320cd188	loc48c6f7d1f300
locb344fc28a060	locbcb60f6b546d
loca1efec8fa041	loca5de38b84720
loc76dea039b41f	locadc5cabaa80e
loc264c2d9ba83e	locd755ccb7197e
loc201e214973bd	loccaca39f133a7
loc4883549a5421	locc67851215f08
locb48ce003b11e	loc30d885ad4b78
loc232da9d11723	loc518f8efa17e7
locb948618ae376	loc853ce1db7b4e
locddc4a1bcd8ba	loc9a48431374e1
loc8e5a2b16aaaa	loc32796261b6b3
loccdfc709471ce	loc8364b6f15ca0
loc00a9769647d7	loc64cc79e3a232
locf066999b6a14	loc923aef8e6b56
loce0707ac065f9	loc210d5f2116dd
loc38cbe92d1159	loc21df90314583
loc9ea2b366d63f	locb52441c1176c
loca674ab421c49	locf6551c962b40
loc9165cd64854f	loc2f9c80de6f7d
loc4fa4b090ce9e	loc76dea039b41f
loc201e214973bd	locb17fb225139f
loc1c5f2c23fc52	loca3335b78b5f1
loc532c3dac4248	loc3def6eff924a
loc712bc92c5924	loc6047e494e110
locadc5cabaa80e	loc2d817b7080e2
loce48c38ae2d6a	locb9872f35df41
loce0707ac065f9	locb86ef7760cec
loc4ff8c926c940	locff0c4d75067f
loc09a99bf786b9	locd25529f04104
loc70eb03d586f8	loc46443686a430
loc201e214973bd	loc1492a23dbc74
locc0b6d754799e	locae977e7a8d83
loc9165cd64854f	locab56fbb21cf8
locf4e180745c81	loc5100fc96abff
loceb6884033cea	locf28996abee51
loc630ef4fec09d	locfd2b1f4a0ddc
locbd7d4fd6b9e7	loc12c0177d3d38
loc29a798d6921b	locb778a527feda
loc4858bcc1d912	loc93dc0822fb9e
loc62ed665318da	locfe4a1adfd013
loc6d7f0d49a3d6	loca1a84d46e52a
loc656f84726510	loce3f8de63f06a
loccbfe7d3f7b9f	loc6c390adc806d
loc34a55c4d0462	loca307cf61ba97
loce01ddbd8c8e5	loc96a2cf1f703c
loc1b271c01e3dc	locd93626afdf47
loca0398a35cf5e	loc7c32e0d95873
loc4161e46afd2f	loc991c414cb6c9
loc15a8d395ef61	loca4ac31a7c768
locc605118e951a	loce8e8e9e3c9b6
loc712bc92c5924	loc656f84726510
loceac5d85ea01d	loc875f8bb64843
loccbfe7d3f7b9f	locf10c34e07e7d
loca0398a35cf5e	loc875118ed8437
locb53ace4ff1b6	locefdacd147f2f
locff58d0167065	loc143aeb12a0a3
loc406d1f7b5fe3	loc5d01e4efc615
loc556974a8bc81	loc2ca9d59200dd
loc86b22e8e6ecf	locf58dcfe36263
loc72d1f0339be6	loc37f7d645fb7e
locd724f9a08a75	loc1e36ff40f8a5
loc556974a8bc81	loc29841cc6d6f1
loc82baa1179308	loca12042a36968
loc2508c9e5a93c	loc1fbfb471eb7c
loc6de0828869d7	loc875118ed8437
loc5c7c3d320a8a	loc94865d03eaac
loc51ba976fe589	loc12c0177d3d38
loc82b861dfb765	locbb6ca08c118e
loc0067a4549ed1	locc25e23d3036a
loc1c5f2c23fc52	loc3dcfd1bf0f21
locb7bca082fca0	loc48b6090e855b
loca5de38b84720	loc693599a76582
locc7ee8539a72b	locf1ab93029011
loc9fb289b0a33e	loc7940cee91449
loc86b22e8e6ecf	loc9fc9cdac1e1a
loc1eda86883ae9	loc1fc92c0da5b7
loccaca39f133a7	locac7743d369bc
loc7a8164839d54	locc89665bfa152
loc7d9d9818d4b9	locf0acc5d27c08
loc2c9ce0acd6de	loc02a3a330fe2f
loc70eb03d586f8	locaa3e42e45c6a
locb71d10cf3b7c	loc7f48d2360090
loc82baa1179308	loc2b7e9f3441dd
loc399d9bd46679	locfb34b8ac194f
locabdfa0718385	locfd2b1f4a0ddc
loce48c38ae2d6a	loc5c27e3f22fc1
loc37efd432abe4	locd6f79866f950
loca1b6ce72e35a	loc86dc9bf35404
loca1b6ce72e35a	loc90b3cd765444
loc264c2d9ba83e	loc00d1503504f1
loccb9bfb1fb49a	locdc955a0a97c9
loca5643321b976	loc985d41c71df1
locb17fb225139f	loc0621c45c46f4
loc3754c5fc3408	loc4883549a5421
loc0de2086617a5	loce7c31dfc7645
loc90b2f4dd8c2d	loc99016095ec57
loc515028b0f98a	loc1405f7fa7e41
loc92bf5bc798e7	locc40c10b3741d
loc94fdc21035b3	loc4ddefd6ecc39
loc7213d03738b9	loc3271d3814fc5
loc37efd432abe4	loc2f9c80de6f7d
loc75d84680b181	loc8a1ff79e32d8
loca1b6ce72e35a	loc4ff8c926c940
loc39cd317eec9d	loce4c31fa791f4
loc1b5a0e70afd4	loccbfe7d3f7b9f
loc9b20cd160517	loca1b6ce72e35a
loc695c9ddc8068	loc517fb29cebaa
loc6ae7eaa3c1f3	loca5de38b84720
loc2c9ce0acd6de	loc06d0d0aef5d7
loc3b583afba248	loca4e166a620d9
loc610e6e8cd167	loc628752a263dc
locf57f2052e543	locbcb60f6b546d
loc0067a4549ed1	loc95cab71f5486
loc6de6554b144b	loc932a1d24c387
loc0e534d470df9	locebcbc7bb3ea0
locd777103bd088	loc5a81b7e76276
loca56f2b16461e	locac7743d369bc
loc3b64e6146ff8	locd6810256cc93
loc4161e46afd2f	locc605118e951a
loca818c5eaa373	loc1e3ac2d49583
loc630ef4fec09d	loc21e213c7452c
loc5900b8cc74c8	locf9fb01474d0a
loc2f9c80de6f7d	loc4a341f4d3e02
locc7ee8539a72b	loc21871af600bf
loc29a798d6921b	locc3e899f0043c
loc250adfcbc82d	loc517fb29cebaa
locfe955a87410d	loc0e52a8070878
loc46b3ff1e6b9a	loc72d1f0339be6
loce36428dd6505	loc248b98674e83
loc8a2c57a8fa9c	loc4f5a9781c984
locbf553ce41d73	loc48776dde54f4
loc1a22f173d7f3	locc0b6d754799e
loc8f498b475ec6	loce160899f1697
loc1c5f2c23fc52	loccfacf870bf34
loc86dc9bf35404	loc264c2d9ba83e
loc7a8164839d54	loc786911d8fa57
loc2d817b7080e2	loc9b20cd160517
loc532c3dac4248	loc77f8249bd999
loc75d84680b181	loc9e3160d1ab2a
loc3754c5fc3408	loc6ae8cb311823
locf3eb6fff8056	loc59c95f4b0c1d
loca5de38b84720	loc6ae7eaa3c1f3
loc6de6554b144b	loc58fa3791b4e9
locdf0288b649a4	loc398d22e7ad86
loccd13bd88b567	loc645cc36e078e
loc29a798d6921b	loc819a06b032e3
loc1b289d3ff2fc	loc097cc7707d4c
locd6f79866f950	loc37efd432abe4
loc94fdc21035b3	loc89da05c8787d
locc0b6d754799e	locc24586754a19
loc7d9d9818d4b9	loccd13bd88b567
locb7bca082fca0	loc2820989ce5f9
loc8f498b475ec6	locb59f0be3fd6d
loc0b8afd71fce1	loceea4a7d012b2
loc0a8087d68433	loc7940cee91449
locc5abea08e85d	locf5fef268f8cd
loc5c27e3f22fc1	loc4fa4b090ce9e
loc7ab22202aac3	loca56f2b16461e
loc9b20cd160517	loc2d817b7080e2
locb344fc28a060	loc8466fa581083
loccabf2d0215b8	locc38231fee5ef
loca0398a35cf5e	loc7024d58288dd
locf3fc3fca2acd	loc6abb7485886c
loc9a86c6faf562	locd06d20cbea22
loc34a55c4d0462	locda8805a3e9bb
locbcb60f6b546d	loc846cf797318d
locc605118e951a	locf09eea4c4a58
loc4a341f4d3e02	loc2f9c80de6f7d
loc819a06b032e3	locf72490d7eaa6
loc4e07cec4cde4	locb281644d861d
loc4161e46afd2f	loce511a62cea4b
locf3fc3fca2acd	locc25e0bed112f
locffd0eebac0eb	locc70453923b8e
locdf0288b649a4	loc6ab2426ba50a
locc7ee8539a72b	loc406d1f7b5fe3
locdf0288b649a4	loc3832b905a97e
locc84be248155b	loc2289e2e7a389
loce6098ac5df0c	locb2d0013fa2c6
loc38cbe92d1159	locdcb72e93920d
locc81a6ec90a1b	locf8d60bf51b6b
loc00a9769647d7	loce48c38ae2d6a
locec99dd6d0979	loc65a4fa5b2f2a
loc9ea2b366d63f	locc0b6d754799e
loc8a2c57a8fa9c	loc73be2879ab2d
loc245c69160468	locb935740daafb
loc679429866800	loc39a81501f6a9
loc1e06c486c813	loc9e7da77def26
loc3d949ab3c987	loce4c31fa791f4
loc3832b905a97e	locdf0288b649a4
loce01ddbd8c8e5	loc38939a80b87e
loc4858bcc1d912	loc74f8893fb76e
locb53ace4ff1b6	loca9f4c2994bec
locd777103bd088	loccabf2d0215b8
loc532c3dac4248	loc631445166691
locb8f595af5fb8	loc982a183f8eaa
loc5e68bb81d75d	locf933bb59d13e
loc4883549a5421	locabd4ee5e179a
locf16910f90fb9	locea2e2e01b99c
loceb41e8eec3ee	loc0389d45a51bc
locffa1c8993b70	loc875f8bb64843
loc70eb03d586f8	locff0c231b0f12
loc8e5a2b16aaaa	loc11fb0b5df130
loc20a81a4bf246	loc1d8e4b29407f
loccdfc709471ce	loc228d608829eb
loca818c5eaa373	loc4291fa503e5c
locf065e41cfac9	loc218bfbe8ef2b
locbb6ca08c118e	locb20cdea6f682
loc36422efcb9c0	loc8bbe850fb3d2
loca2fd80ef71d3	loc4a7ec2b4b43b
loc67a11408d754	loc92bf5bc798e7
locbcb60f6b546d	loc312e1aba6ed5
loc82b861dfb765	loc1032c5d1ed5f
locbcb60f6b546d	locff62fb6a898a
loc780d4ed4ca46	loc1d20a85119e7
loccd13bd88b567	locf0acc5d27c08
loc1492a23dbc74	loce578d6ccca3a
loc3b64e6146ff8	loc588c867d4a80
loc1492a23dbc74	loc712bc92c5924
loc9e7da77def26	loc92bf5bc798e7
loc0e534d470df9	locc8f89e3be9f3
locc7ee8539a72b	locf678eadaf2e3
loc2f9c80de6f7d	loc37efd432abe4
loce25dfc481765	loc1b7030deca31
loc11fb0b5df130	loce6fe9cedd8c7
locadc5cabaa80e	loc913bf4728c4e
loc956fa85c7b0c	loc8bbe850fb3d2
loc86dc9bf35404	loc86a790ccadf9
loc9a86c6faf562	locb29f2cfd6756
loc098ac8eaabef	loc08caad3924ee
loc76dea039b41f	loc7e96c43cdd6c
loc201e214973bd	loc42979bc97c35
loc108a649ba4ae	loc22af9465d3c4
loc86b22e8e6ecf	loce6098ac5df0c
loc338a35dd09f0	locbd15dbd99fc7
loc819a06b032e3	loc29a798d6921b
loc0b6e17218dd4	loc8415ce7f7160
loc4423238fcdd8	loca6b49df57905
loc4858bcc1d912	loc9721f9d95eee
loc786911d8fa57	loc10fc59c40668
loc1b5a0e70afd4	loc2c805e9e142d
locbd7d4fd6b9e7	loc3271d3814fc5
loc3fe991822440	loc049b23459881
locdd716f1059c5	locace3209a1388
loc38cbe92d1159	locf9242b623b72
loc0b8afd71fce1	loc67a11408d754
loc108a649ba4ae	locdf4e25f54490
locd06d20cbea22	loc51f77eba864c
loc15a8d395ef61	loc139c325d29ef
loc46443686a430	loc631dce7fd76a
locc25e0bed112f	locf3fc3fca2acd
locff62fb6a898a	loc28350a6fd21f
locc84be248155b	locaf8d2e9e4584
loc22c42e389de3	loc6d7f0d49a3d6
locbb6ca08c118e	loc79e45c9fa669
loc201e214973bd	loc82b861dfb765
loc02a3a330fe2f	loc2c9ce0acd6de
loc3319215a0a10	loce42a110faa48
locd06d20cbea22	locb2d0013fa2c6
loc8688ba223de1	locdf1748f3f781
loce25dfc481765	locce3df103519c
loc72d1f0339be6	locab56fbb21cf8
loc875f8bb64843	loceac5d85ea01d
loc72d1f0339be6	locdc955a0a97c9
loc76dea039b41f	loc2d817b7080e2
loc34a55c4d0462	loc167afe1d878c
locc91f4a31a1bc	loce6085a4cf5c8
loc51ba976fe589	loc9721f9d95eee
loc5900b8cc74c8	loc7bf3a4364d08
loc2c4c767ea9b7	loc3271d3814fc5
loc1f73672977ce	locd3d0aa4dde7c
loc232da9d11723	locc90ab58112e3
loca674ab421c49	loc36df131f7f2f
loc4423238fcdd8	loc85e4166d9d5b
loc08caad3924ee	loc65a4fa5b2f2a
loccdfc709471ce	loc076543f8c80c
locf8d60bf51b6b	locc81a6ec90a1b
loc0b6e17218dd4	loc65b04ce00376
loc29841cc6d6f1	locfd0ac2a1c5e8
loc62ed665318da	loc3d451791a2bc
loceac5d85ea01d	loce8f39e233734
locbd7d4fd6b9e7	loc11b2a92fb5f0
loc5c94ac6107ca	loc0a12a9e2e03f
loc34a55c4d0462	loc37017194a2d7
loca5643321b976	locfacbd57c724a
loc098e933e1fd2	loc90b2f4dd8c2d
loc79e45c9fa669	locbd7d4fd6b9e7
locf065e41cfac9	loc4bb64766c12a
loc8a2c57a8fa9c	loc1693aeac104d
loca307cf61ba97	locff0c231b0f12
loc1b271c01e3dc	loc974441b38fa0
loc7a8164839d54	loc49db457e2be8
loca1efec8fa041	locc89665bfa152
loce6098ac5df0c	loc9fc9cdac1e1a
loc6de0828869d7	loce48c38ae2d6a
locc586266ef8cc	loce35b0278cf3c
loccdfc709471ce	locc98c206ba48a
loc11fb0b5df130	loc12e784b16dde
locd724f9a08a75	loca2d931c486c4
loc00a9769647d7	loc4fa4b090ce9e
locb9872f35df41	locb20cdea6f682
loc515028b0f98a	locfdb55e6f8522
loc86dc9bf35404	loc1d6e4fac2710
loc0a8087d68433	loc9fb289b0a33e
loc9fb289b0a33e	loc0a8087d68433
loc08caad3924ee	loc098ac8eaabef
locd724f9a08a75	loc3addf29ad792
loce1597eda1cc3	loc8585329cc409
loc695c9ddc8068	loc6c390adc806d
loc3fe991822440	loc4cdd1af01845
loc6d7f0d49a3d6	loc6ae8cb311823
locc84be248155b	locc2eca36bc712
loc09a99bf786b9	loc89fc2edfdfe4
loc786911d8fa57	loc7a8164839d54
loc232da9d11723	loc2509f7276f3e
loc8688ba223de1	loc22d7825c3923
loc2c9ce0acd6de	loc956fa85c7b0c
locbb6ca08c118e	loc82b861dfb765
loc72d1f0339be6	locae68612e5fe1
loc7c934a667999	loc85eb5f11b3d4
loc098ac8eaabef	locaf6f4327a65a
locb7bca082fca0	locb4edf1d963ad
loc13ed320cd188	loce991f1dc2338
locb17fb225139f	loc39ed15931919
loc9fe59dbd0874	loc0475beb19ff3
loc87f2ad0c0fd7	loce48c38ae2d6a
loca2fd80ef71d3	loc282e256216af
loc11fb0b5df130	locb219cc0746f5
loccabf2d0215b8	loc9f89abda4997
locc7ee8539a72b	loc08f132cbeca5
loc679429866800	loc5b8c67e3b281
loc1b271c01e3dc	loce511a62cea4b
loc11b2a92fb5f0	locbb5f291d781d
loccbfe7d3f7b9f	loc450465b4eebb
loc74f8893fb76e	locf07f0a553979
loc29841cc6d6f1	locbeeb46e9ccb4
loc29841cc6d6f1	loc9f89abda4997
loc4161e46afd2f	locbdf0138dcf54
loca818c5eaa373	loc2380192cce6d
locf3fc3fca2acd	loc28350a6fd21f
loc6413994c2b24	locf57f2052e543
loceb6884033cea	loc24c93e0a473d
locddc4a1bcd8ba	loc31f384e524fe
loc2f9c80de6f7d	loc9165cd64854f
locb9872f35df41	loc6de0828869d7
loc5900b8cc74c8	locba52fafa71f9
locea2e2e01b99c	loc71ab0a32dd36
loc5c27e3f22fc1	loc7c0af2fd89ec
loc1b289d3ff2fc	loc1fcd28cddafe
locadc5cabaa80e	loc4ff8c926c940
loccb9bfb1fb49a	loc72d1f0339be6
locc0b6d754799e	loc9fe59dbd0874
loc08caad3924ee	loc8c9f2867857c
loc630ef4fec09d	loc00f0949ea0ad
locb48ce003b11e	locc0409070f61c
loceb41e8eec3ee	locc32e1f27cb07
loc556974a8bc81	loc0de9fd520875
loc1fbfb471eb7c	loc204f0f0ca6e2
loc11fb0b5df130	loc3e010de7b16c
loc0621c45c46f4	loca1efec8fa041
loc38cbe92d1159	loc558550055434
loc4ff8c926c940	loc9b20cd160517
loc0067a4549ed1	loc9214f734f5e9
loc29a798d6921b	loc620b77ab764b
loc5c7c3d320a8a	loc2174b697a652
loc245c69160468	loc1238ab1662bb
loc38cbe92d1159	loc7d9d9818d4b9
loc201e214973bd	loc0621c45c46f4
loc338a35dd09f0	loc30d885ad4b78
loca4e166a620d9	loc9ee54c810992
loc5ba812288f5b	locbacb63b5901d
loc4fa4b090ce9e	loc913bf4728c4e
loc62ed665318da	locfadf7b35dabf
locb8f595af5fb8	loc00d1503504f1
locc84be248155b	loc385f89c30443
locd8470b65d64b	loc71ab0a32dd36
locf066999b6a14	loc82e9519dd9b6
locb48ce003b11e	loc202ce2987f6d
loc1f73672977ce	loc8b0cbde7b1f2
loc0b6e17218dd4	loc1b5a0e70afd4
locc70453923b8e	locd991ee63e1ae
loc9165cd64854f	locdcb72e93920d
loc5e975e2e1c0e	locfcabeab829f5
loca4e166a620d9	loc7767bba5f04d
loc264c2d9ba83e	loc9ee54c810992
loc09a99bf786b9	loc6881ad99ba61
loc6a54ce63b777	loc82f5b45a790d
loc09a99bf786b9	locb5e6487c69a4
loc201e214973bd	loc39ed15931919
locff62fb6a898a	locccf64b3f1134
locbcb60f6b546d	locb344fc28a060
loc17a18f5ff3a6	locc91f4a31a1bc
loc2508c9e5a93c	locd7f7a27169c2
loc11b2a92fb5f0	loca4f3a116d4ba
loc5900b8cc74c8	loc44e7525b33ad
loc3b583afba248	locd6810256cc93
loc956fa85c7b0c	loc02a3a330fe2f
loc12c0177d3d38	locbd7d4fd6b9e7
loc67a11408d754	locebf4f333240b
loc29841cc6d6f1	loc556974a8bc81
loc63a05a113f90	loc325c0b30e951
loc399d9bd46679	locaa6592c1d4fc
loccd13bd88b567	loce94c02bf1598
loc1b271c01e3dc	loc4161e46afd2f
locea2e2e01b99c	loc3d949ab3c987
locb8f595af5fb8	loc264c2d9ba83e
locae977e7a8d83	loc9fe59dbd0874
locb0a9c63101c7	loc860b95b61d88
locc605118e951a	loc991c414cb6c9
loc4a341f4d3e02	loc37efd432abe4
locedacea740a10	loc6809b7c5e3e1
loc72d1f0339be6	loc49db457e2be8
loc991c414cb6c9	loc4161e46afd2f
locb53ace4ff1b6	loc4e6d9830aae4
loc8f565e81c655	loc656f84726510
loc913bf4728c4e	loc4fa4b090ce9e
loc3b6fd5dcd874	loc67d2e4d427ab
loc098ac8eaabef	locc5abea08e85d
loce42a110faa48	loc71ab0a32dd36
loca307cf61ba97	loc167afe1d878c
locf3fc3fca2acd	locb31c88860761
loc4a7c5154c298	loc8297291648ae
loca1a84d46e52a	loc22c42e389de3
loc0a8087d68433	locb71d10cf3b7c
loc9e7da77def26	loca4f3a116d4ba
locd755ccb7197e	loc642caba35d41
locabdfa0718385	loc0de9fd520875
loc875f8bb64843	loc1a1d44d067f2
loc0621c45c46f4	locb17fb225139f
locf2d2a267a354	loc6583132c3a24
loca307cf61ba97	loc34a55c4d0462
locbb6ca08c118e	loc1032c5d1ed5f
loc910a14938d48	loc91ee39d5afd8
loc712bc92c5924	loc1492a23dbc74
loccb9bfb1fb49a	locfeb30fa2d21c
loc6c0f29d040f7	locbe0ebdbfa3f3
locc91f4a31a1bc	loc17a18f5ff3a6
locbf553ce41d73	loc6b57f730f7be
loc7a8164839d54	loc7ab22202aac3
loc9e7da77def26	loca0398a35cf5e
loc4a341f4d3e02	loc137c40f435ae
loc0a8087d68433	loc86d9a613f84b
loc4e07cec4cde4	loc3f54d4127b06
loc8733d13ded2e	loce2babe59103e
locb17fb225139f	loc2ef00ac196a6
locfd8472c41cbe	loc43b106f3f7f3
loc0b665c0fe535	loc253c87b50989
loca37d9a7b347e	loc9154637132c3
loc0b6e17218dd4	loc89cee4954cc2
loc12cc6354a4ba	loca537fcb250e1
loc2d817b7080e2	loc433bbb473372
locc84be248155b	loc71a7f701b292
loc8fef59c1c585	locdeefa3afa7c5
loc3b64e6146ff8	locdd716f1059c5
locc5abea08e85d	locf72490d7eaa6
loc2508c9e5a93c	loc0749ce7d63b9
loc656f84726510	locfb9f1336aa98
loc7c934a667999	loce69259513060
locc70453923b8e	loc28350a6fd21f
loce1597eda1cc3	loc91ee39d5afd8
locd8470b65d64b	loc89cee4954cc2
loc532c3dac4248	loc3a1355c4e9b8
loc0a03ed3531fd	loc3d949ab3c987
loc06cc48b309e5	loc6047e494e110
loc7d9d9818d4b9	locd6f79866f950
locedacea740a10	loc8ba36309839a
loc0b8afd71fce1	loc7ee7acc30be1
loc1fbfb471eb7c	loceec6ae91e339
locb9872f35df41	loce48c38ae2d6a
loc8e5a2b16aaaa	locb0a03ed92a58
loc5c7c3d320a8a	loc6881ad99ba61
loc5c94ac6107ca	locc7ed59ac01ad
locae68612e5fe1	locba769f27c374
locadc5cabaa80e	loc4fa4b090ce9e
loc06cc48b309e5	loce578d6ccca3a
loc47e9d5554e9d	loc4c759768d65b
loc15a8d395ef61	loc10bbee6c6788
loca5de38b84720	locc89665bfa152
loc5100fc96abff	loce69259513060
locadc5cabaa80e	locff0c4d75067f
loc0a03ed3531fd	locad899e5d272f
locb7bca082fca0	loc06c4966b14cd
loc7d9d9818d4b9	loc9165cd64854f
locf16910f90fb9	loc71ab0a32dd36
loca674ab421c49	locd00cdea60da8
loc5ba812288f5b	loc6a5903165043
loca4e166a620d9	loc3b583afba248
loc1e33f92d8409	loc6f86b30b85f7
loc9a48431374e1	loc1e3ac2d49583
loc4195fdfecc8e	loccbfe7d3f7b9f
loc1e33f92d8409	loc6c5d7b519796
locc84be248155b	loca0aaf21ba3d0
loc4858bcc1d912	loc2546709d8859
loc3319215a0a10	locf10c34e07e7d
loc1b5a0e70afd4	loc0b6e17218dd4
loc679429866800	loc2dda2a8b5d76
loc4ff8c926c940	loc2d817b7080e2
locc84be248155b	loc21d2a43ddc0f
loc00a9769647d7	loc39ed15931919
locc605118e951a	locbc5a8bc32e3c
loce01ddbd8c8e5	loc3532f7182cf4
loca674ab421c49	locb7a8a8d0ef4f
loc0a8087d68433	loc590aa68ce959
loc29a798d6921b	locf72490d7eaa6
loc4161e46afd2f	locd93626afdf47
loc37efd432abe4	loc00d1503504f1
loc7a8164839d54	loc406d1f7b5fe3
loc75d84680b181	locc4f5be22debf
loc0de2086617a5	loc77f5ea3845ee
loc5e975e2e1c0e	loc1ce48a403c33
loc72d1f0339be6	locde7f91aff148
loc098ac8eaabef	locec99dd6d0979
loc11b2a92fb5f0	locfdc6079b562f
loc08caad3924ee	loc41819ba29eb2
loc9a48431374e1	loce7252de87492
locb948618ae376	loc9f7af461be53
loc4858bcc1d912	loc12c0177d3d38
locc25e0bed112f	loc62bb1a0efe24
loc39cd317eec9d	loc3d949ab3c987
locbf553ce41d73	loc5b05103f6f82
loc1492a23dbc74	loccaca39f133a7
loc780d4ed4ca46	loc8585329cc409
loc910a14938d48	loc6f04d479b43f
loc9fe59dbd0874	loc6280f9052ec0
loc11b2a92fb5f0	loc8297291648ae
locedacea740a10	loc3f8811476d10
loc09a99bf786b9	loc91986fb3c2b4
loccb9bfb1fb49a	loc46f8f01fbac9
loc31f384e524fe	locf51f6cd689bb
loc0a8087d68433	loc325c0b30e951
locff62fb6a898a	loc6849c4e53590
loc63a05a113f90	loc016f1437298f
loc94fdc21035b3	loc6dfe4c7d1b71
locb71d10cf3b7c	loc0a8087d68433
loc4a6dd2077a69	locc14e6fa711f7
loc3b583afba248	loc1d6e4fac2710
loc1b5a0e70afd4	loc65b04ce00376
loca674ab421c49	loc063ba48baa63
locd6190ebbe554	loc5703a8d074b6
locc67851215f08	loc9baff2540961
loc34a55c4d0462	loc631dce7fd76a
loc8c9f2867857c	loc65a4fa5b2f2a
locdf0288b649a4	locac29edf21afb
loc656f84726510	loc7213d03738b9
loc0b8afd71fce1	loc1e3ac2d49583
loc0067a4549ed1	locd17262cd91b9
loc1492a23dbc74	loc2c4c767ea9b7
loce0707ac065f9	loc91ba08d312cb
loc7f158a48110c	loc9f3cac243db7
locea2e2e01b99c	locd8470b65d64b
loc8a2c57a8fa9c	loc461f48ed43e3
loc9e7da77def26	loc533a569e6f80
loc90b2f4dd8c2d	loc96655641e3a2
loc3319215a0a10	loccbfe7d3f7b9f
locfe955a87410d	loc695c9ddc8068
locfe955a87410d	loc77c523d8c2ba
loc13ed320cd188	locf44a583273a6
loc13ed320cd188	locc9201bcd8c48
loc5c7c3d320a8a	locf3eb6fff8056
loc5e975e2e1c0e	loc9a28bfe6d6b3
locd6f79866f950	loccd13bd88b567
loc3b583afba248	locde8437240459
locff58d0167065	locc8ba50393823
loc8f565e81c655	loc712bc92c5924
loc20a81a4bf246	loc709dcb832d80
loc4195fdfecc8e	loc1b5a0e70afd4
loceac5d85ea01d	loc819a06b032e3
loc8688ba223de1	loc4612f375ea9f
loc556974a8bc81	locfd2b1f4a0ddc
loce0707ac065f9	locabef03e2a2a0
loc4858bcc1d912	loc51ba976fe589
loc5e975e2e1c0e	locb66e684d7ddf
loc79e45c9fa669	locf328dcebf414
locc605118e951a	loc4cca17382228
loceac5d85ea01d	loc4ad964a82468
loc780d4ed4ca46	loc305838be86ce
loc74f8893fb76e	locee4a8f85818e
loc11b2a92fb5f0	loc4a7c5154c298
loc90b2f4dd8c2d	loc830fece5a42c
loc4423238fcdd8	loc25349ac08f9b
locff58d0167065	loc72c8cfe49f57
loc025dead673cc	locdd716f1059c5
loc1a7553da1009	loc1e9704dd3823
loc67a11408d754	loceea4a7d012b2
loc532c3dac4248	locb87e603e1ad4
loca5de38b84720	loca1efec8fa041
locfdc6079b562f	locc40c10b3741d
loc13ed320cd188	locb34e9b4fa925
locf2d2a267a354	loc644bdb89d46b
loc2c4c767ea9b7	loc1492a23dbc74
locb344fc28a060	loccc0f4c785f6c
loc0067a4549ed1	loc63a46e63a71a
loc515028b0f98a	loc25122932d6df
loc70eb03d586f8	loc05e50c5030cd
loc610e6e8cd167	loca0aaf21ba3d0
loc09a99bf786b9	loc3d3c12a8d309
locb694454fbbb1	loc64cc79e3a232
loc1b289d3ff2fc	locb767b2dd1e8c
loce36428dd6505	locca627b6056a1
loce11f06c54f46	loc630ef4fec09d
loc4883549a5421	loc3754c5fc3408
loc2d817b7080e2	loc51f316792e18
locf2d2a267a354	loc1da1d4fb358b
loc0b665c0fe535	locf5e258559e72
loc8a2c57a8fa9c	locdb2da1385174
loc098e933e1fd2	loc830fece5a42c
loc3d949ab3c987	locde8437240459
loc0621c45c46f4	loca56f2b16461e
loc2c9ce0acd6de	locdbb9e644cdbc
locb281644d861d	loc2d7496657dea
loc86cf2bd4847b	loc0b6e17218dd4
locb71d10cf3b7c	loc9fb289b0a33e
loca5de38b84720	loc4add9dd25668
loc9fe59dbd0874	loc9ea2b366d63f
loc695c9ddc8068	loc250adfcbc82d
loc62ed665318da	locf1f0ff374a2f
loccbfe7d3f7b9f	loc3319215a0a10
locb7bca082fca0	loc4ea040922166
locfa38377aaf29	loccc67f8d76605
loc712bc92c5924	loce3f8de63f06a
loc338a35dd09f0	loce6098ac5df0c
loceb6884033cea	loc930abd97fea8
locb48ce003b11e	loc2286a8725de5
locc586266ef8cc	loc245b9b3ede1b
loc1b289d3ff2fc	loc1a5355e79b24
loc532c3dac4248	locd15f477b7685
loc8688ba223de1	loc729e2fc98e77
locc91f4a31a1bc	locbb31ea1d3b07
locae977e7a8d83	loc0475beb19ff3
loc0e534d470df9	loc62382d5f8851
loc5100fc96abff	locf4e180745c81
loc82baa1179308	loc15a8d395ef61
loc64c822b0bad5	loc0475beb19ff3
loc7ab22202aac3	loc7a8164839d54
loc5e975e2e1c0e	loce5e36539b5f6
loce1597eda1cc3	locc08b3f37ebf5
loc6ae7eaa3c1f3	loc4add9dd25668
loc6de0828869d7	loc7024d58288dd
loc4161e46afd2f	locbc5a8bc32e3c
loce42a110faa48	locf16910f90fb9
loc6280f9052ec0	loc82e9519dd9b6
loc406d1f7b5fe3	loc7a8164839d54
locc586266ef8cc	loc1476af0a8dc2
loc3d949ab3c987	loc39cd317eec9d
loc1a7553da1009	loc436e47a2dad6
loc3b64e6146ff8	loc0ea7f7dc5047
locba8f7a4a0c92	loc3253b162ad37
loccabf2d0215b8	loc5524fe9b9f36
loccabf2d0215b8	locd777103bd088
locbf553ce41d73	loc33485da56335
loc79e45c9fa669	loc533a569e6f80
loc98325a7e67bf	loc82f5b45a790d
loc2c4c767ea9b7	locbd7d4fd6b9e7
locb7bca082fca0	locffacfe0fbc5c
loc9ea2b366d63f	locc24586754a19
loc1a7553da1009	loc75a7e2ef9542
loce6098ac5df0c	loc86b22e8e6ecf
locadc5cabaa80e	loc76dea039b41f
locfa38377aaf29	locc6e4c59f9a01
loce6098ac5df0c	loc8a4f8d6b9718
loc6d7f0d49a3d6	loc22c42e389de3
locc0b6d754799e	locb52441c1176c
loc46443686a430	loc61addd636cfb
loc0a03ed3531fd	locdd716f1059c5
loc46f8f01fbac9	loc9165cd64854f
loc712bc92c5924	loc06cc48b309e5
loc338a35dd09f0	loc60657db3db42
locfe955a87410d	loc7ea958f6824d
locf3fc3fca2acd	loc62bb1a0efe24
loca4e166a620d9	loc1d6e4fac2710
loc780d4ed4ca46	loc91ee39d5afd8
loc1fbfb471eb7c	loc7c970583e8e4
locfd8472c41cbe	loce94c02bf1598
locc81a6ec90a1b	loc819aeb5db205
loc00a9769647d7	loce587d8cdc0f5
locf51f6cd689bb	loc9a48431374e1
locf4e180745c81	loc3fe991822440
loc92bf5bc798e7	loceea4a7d012b2
locc672a234fa5a	locfa8eb1577adf
locb53ace4ff1b6	locab2619c6639f
locf065e41cfac9	loc59a00d8fcb2e
loc4161e46afd2f	loc0fd97b838ab9
loc92bf5bc798e7	loc9e7da77def26
loc62ed665318da	locabb788a18618
locb0a9c63101c7	loc0a94e94d2f51
loc1b271c01e3dc	loccd065e8b9b5f
loc656f84726510	loc2c4c767ea9b7
locd724f9a08a75	loc16a7b6be7aff
loc8688ba223de1	loc993c29e386e0
locd665688d0e4d	loc3dd402b6945d
loc46443686a430	loc41819ba29eb2
loc0621c45c46f4	loc201e214973bd
locf3eb6fff8056	loc5c43c0f368e0
locf066999b6a14	locb453101c5355
locba8f7a4a0c92	locaedc1a0bcb5a
locc586266ef8cc	locb8d22c0e701d
loc338a35dd09f0	locd7ab572b3677
loc29a798d6921b	locc5abea08e85d
loca37d9a7b347e	loc6a58ffb032fe
loc29a798d6921b	loceac5d85ea01d
loc1e33f92d8409	loc7033a498c044
loc0e534d470df9	loc5d49b0dadcea
locfd8472c41cbe	locd755ccb7197e
loc51ba976fe589	loc4858bcc1d912
loc86dc9bf35404	loca1b6ce72e35a
loc8e5a2b16aaaa	loc3e010de7b16c
loc3832b905a97e	loc0cb55cb965ad
loc08caad3924ee	loc1e3ac2d49583
loc67a11408d754	loc0b8afd71fce1
loc64c822b0bad5	loc88487743ffc5
loc5900b8cc74c8	loc026e47177cdd
locb17fb225139f	loca56f2b16461e
locfdc6079b562f	loc92bf5bc798e7
locf066999b6a14	loc5f0c59159354
loccb9bfb1fb49a	locdcb72e93920d
loc656f84726510	loc1492a23dbc74
loc08caad3924ee	loc88ebb657408f
locf066999b6a14	locb10305db77b5
loc67a11408d754	loc1e3ac2d49583
loc8688ba223de1	loc2a421a3cedca
loc3832b905a97e	loc47d6c4f1ca81
locc81a6ec90a1b	loced6917ed9b9b
loc22c42e389de3	loceb44a3a54ace
loc94fdc21035b3	loc962b242ca82b
loccaca39f133a7	loc89825e26f3b9
loc47e9d5554e9d	loc12e784b16dde
loc819a06b032e3	loc7a8cc16cce19
loc8f498b475ec6	loccddbad92d002
locc84be248155b	locac65b599176b
locff58d0167065	loca8a725aac99c
locf51f6cd689bb	loce7252de87492
loc46f8f01fbac9	loccb9bfb1fb49a
locbcb60f6b546d	locf57f2052e543
loc232da9d11723	loccb4e3657c256
loce25dfc481765	loc3f59ecd72d34
loc2c4c767ea9b7	loc656f84726510
locc91f4a31a1bc	loc4b34c45998d4
loc4883549a5421	loc1556821a864f
locddc4a1bcd8ba	loc0b8afd71fce1
loce25dfc481765	loce8e8e9e3c9b6
loc4858bcc1d912	loc4dfb8458b2e2
locb17fb225139f	loc201e214973bd
loc3fe991822440	loceb4ecf2e7464
locb0a9c63101c7	loc2e7877cb2c34
loc695c9ddc8068	loc433bbb473372
loc86b22e8e6ecf	loc7dfc13a0fbf3
locb71d10cf3b7c	locc90f113d3978
loce48c38ae2d6a	loc6de0828869d7
loc0de2086617a5	loc25273574cf84
loc2c4c767ea9b7	loc82b861dfb765
loc991c414cb6c9	loc756873fe7d89
locb694454fbbb1	loc4fa4b090ce9e
loc556974a8bc81	loccaf1b7ac7ed3
loc90b2f4dd8c2d	locba5e689e47f8
loce11f06c54f46	loc2508c9e5a93c
loc6de0828869d7	locb20cdea6f682
loc74f8893fb76e	loc9baff2540961
loc8a2c57a8fa9c	loc474d5ff63731
loc90b2f4dd8c2d	locea47e3f6990f
loc00a9769647d7	loc61df9930af3b
loc79e45c9fa669	loc7c32e0d95873
loca818c5eaa373	locf4512129a85e
loca2fd80ef71d3	loc2063c96ef070
loc556974a8bc81	loc08859c84b2aa
loc8a2c57a8fa9c	loc6dac7364b2f8
loc250adfcbc82d	loc7e96c43cdd6c
loc695c9ddc8068	locfe955a87410d
loccb9bfb1fb49a	loc38cbe92d1159
locb948618ae376	locc2fcd7774115
loc5c27e3f22fc1	loc76dea039b41f
loc63a05a113f90	locb71d10cf3b7c
locba5e689e47f8	locb4db14713fd7
loc6de6554b144b	locfd9fc9892f2c
loc610e6e8cd167	loce718575b31cf
loca5643321b976	locbd3b6450a40f
loc098e933e1fd2	loc315bbea2e96e
loc37efd432abe4	loc982a183f8eaa
loc08caad3924ee	loc01c2784fcea2
loc0067a4549ed1	loc38acfa921aa5
loc2d817b7080e2	locfc54031c1c5a
locf57f2052e543	locff62fb6a898a
loc8733d13ded2e	loce4ce9f3183f9
locd724f9a08a75	loc45862f2c9521
loc94fdc21035b3	loc3753cbda503c
loca674ab421c49	loc7816a5f66ad7
locff58d0167065	loc04e53eaf32eb
loc1fbfb471eb7c	locefdfb6c544cc
loc656f84726510	loc3271d3814fc5
loc3b64e6146ff8	loc62bb1a0efe24
locd8470b65d64b	loc8415ce7f7160
loc9ea2b366d63f	loc6849c4e53590
loc4a7c5154c298	locfdc6079b562f
loca1a84d46e52a	loc6755f6d71124
locd6f79866f950	loc982a183f8eaa
loc264c2d9ba83e	loc1d6e4fac2710
locc098f71b2faf	loc0da1e4cdebda
loccabf2d0215b8	loc72ce64beb561
loca1a84d46e52a	loc6d7f0d49a3d6
loc3b64e6146ff8	locace3209a1388
loc8e5a2b16aaaa	locb59f0be3fd6d
locc25e0bed112f	loc28350a6fd21f
locff62fb6a898a	locf57f2052e543
loc780d4ed4ca46	loc961ba83e9723
loc46b3ff1e6b9a	loc4a341f4d3e02
locd724f9a08a75	loc1bc3a79f96ad
locae977e7a8d83	loc8466fa581083
loc12cc6354a4ba	locfe57383287a4
loc79e45c9fa669	locbb6ca08c118e
loc6d7f0d49a3d6	loceb44a3a54ace
loc9b20cd160517	loc4ff8c926c940
loca1efec8fa041	loc0621c45c46f4
loc34a55c4d0462	locc7baa224b862
loca1b6ce72e35a	loc67f13bfe7b6c
locb7bca082fca0	loc7a9f0f1030d4
loc399d9bd46679	locc1a0d959fb46
loc4ff8c926c940	loca1b6ce72e35a
locb53ace4ff1b6	locc8cf2a27e6e0
loc82baa1179308	loc64c822b0bad5
loc7213d03738b9	loc4858bcc1d912
loc1a7553da1009	locc12d00a14d83
loc8688ba223de1	loc7d6ff2a5c8c5
loceb41e8eec3ee	loc961d8ef37c6a
locb281644d861d	locf40bda10826e
loc9a48431374e1	loc7ee7acc30be1
loca2fd80ef71d3	loc55df2bbde6c8
loc86cf2bd4847b	loc2c805e9e142d
loc90b2f4dd8c2d	locc5ddbf838716
locdf0288b649a4	loc0cb55cb965ad
loc74f8893fb76e	loc4858bcc1d912
loce11f06c54f46	locd7f7a27169c2
loc46443686a430	locc7baa224b862
loc0b8afd71fce1	loc9a48431374e1
loc338a35dd09f0	loc1acb177d8c03
loc64c822b0bad5	loc2b7e9f3441dd
loc875118ed8437	locb20cdea6f682
locfe955a87410d	locf10c34e07e7d
locb53ace4ff1b6	loc5d65bafd7419
loca56f2b16461e	loc5d01e4efc615
loc991c414cb6c9	locc605118e951a
loc025dead673cc	loc3b64e6146ff8
loc72d1f0339be6	loccb9bfb1fb49a
loc0621c45c46f4	loc64cc79e3a232
loc2d817b7080e2	loc65593405a665
locbd7d4fd6b9e7	locbb5f291d781d
loca818c5eaa373	loc01478eda4021
locbcb60f6b546d	loc3ccb852d09c7
loccdfc709471ce	loc89a34a2a749a
loce0707ac065f9	loc8a97c8ce83aa
loc679429866800	loc553164f6c50c
locf066999b6a14	loc3f54d4127b06
locff62fb6a898a	locf3fc3fca2acd
loc22c42e389de3	loc14b657721382
loc6c0f29d040f7	loc620b432a2035
loc2508c9e5a93c	locd93626afdf47
loc11fb0b5df130	loc6f4bb38bc95b
locd6190ebbe554	loc46de7f572469
loc2f9c80de6f7d	loc7d9d9818d4b9
loca2fd80ef71d3	loce4bf9e3f4c7f
loc9fe59dbd0874	locae977e7a8d83
locc70453923b8e	locffd0eebac0eb
loc5ba812288f5b	loc484201bfd782
loc4a7c5154c298	loc11b2a92fb5f0
loc9e7da77def26	loc4a7c5154c298
loc515028b0f98a	loc37ffbe4ce368
loc7ab22202aac3	loc406d1f7b5fe3
loc6ae7eaa3c1f3	loc693599a76582
loc67a11408d754	locf4512129a85e
loc82b861dfb765	loc201e214973bd
loc7d9d9818d4b9	loc38cbe92d1159
locad899e5d272f	loc0a03ed3531fd
locf066999b6a14	locb31c88860761
loc399d9bd46679	loc62155f23f2c5
loc39cd317eec9d	locde8437240459
loc15a8d395ef61	loc82baa1179308
locc7ee8539a72b	locb929ada4170a
loc1e33f92d8409	loc3e1dd0bfd942
locea2e2e01b99c	loc0a03ed3531fd
locc81a6ec90a1b	loceb4ecf2e7464
loce42a110faa48	loc6f887e0e8e31
locff58d0167065	locdceb1195f0ca
loc1492a23dbc74	loc201e214973bd
locc2ea2de6af6c	loc7c0af2fd89ec
locc2ea2de6af6c	loc250adfcbc82d
loc51ba976fe589	loc731aac9d3e93
loc02a3a330fe2f	loc956fa85c7b0c
loc7213d03738b9	loc656f84726510
locdd716f1059c5	loc025dead673cc
loc1c5f2c23fc52	locf696ab3aafac
loc2d817b7080e2	loc86cf2bd4847b
locb9872f35df41	loc5c27e3f22fc1
loc67a11408d754	locfdc6079b562f
loc17a18f5ff3a6	loc7a8cc16cce19
loc1a7553da1009	locbdaf4c33ca5b
locae977e7a8d83	loc1a22f173d7f3
locc2ea2de6af6c	loc7e96c43cdd6c
loc1f73672977ce	loc6db1a4fe1633
loc913bf4728c4e	locadc5cabaa80e
loc0a03ed3531fd	locace3209a1388
loc8fef59c1c585	loc9721f9d95eee
locae68612e5fe1	loc72d1f0339be6
locb0a9c63101c7	loc46fc52688371
loc712bc92c5924	loc49fb687cbcb9
loc9fb289b0a33e	loc590aa68ce959
loc9e7da77def26	loc11b2a92fb5f0
locb48ce003b11e	loc13554647591e
loc1b289d3ff2fc	loc81fb8801b3c1
loc75d84680b181	locbac72a9b9112
loc406d1f7b5fe3	loc8b861551a212
loc250adfcbc82d	loc77c523d8c2ba
loc34a55c4d0462	loc0eced751f474
loc8688ba223de1	loc1bd709abefa0
loc8e5a2b16aaaa	loce160899f1697
locfd8472c41cbe	loc264c2d9ba83e
loc6d7f0d49a3d6	loc0fd97b838ab9
loc0067a4549ed1	loc20875e292053
loc8688ba223de1	locfdb55e6f8522
loc232da9d11723	loc349bb9642578
loccbfe7d3f7b9f	loc4195fdfecc8e
loc74f8893fb76e	locc67851215f08
loc1a22f173d7f3	locc24586754a19
loc9ea2b366d63f	loc3ccb852d09c7
locf8d60bf51b6b	loced6917ed9b9b
loc556974a8bc81	loce2babe59103e
loc8e5a2b16aaaa	locb219cc0746f5
loce36428dd6505	loc736a986172a0
locb48ce003b11e	loc244b2e5d1207
loc1b271c01e3dc	loc6ae8cb311823
loce01ddbd8c8e5	locb74efcea775d
loc1eda86883ae9	loc56c5896345b2
loccbfe7d3f7b9f	loc1b5a0e70afd4
locb7bca082fca0	loc496d70f9c930
locc67851215f08	locee4a8f85818e
loce01ddbd8c8e5	loc7816a5f66ad7
loc8688ba223de1	locf27adad3ec91
loca4e166a620d9	loc642caba35d41
loc875118ed8437	loc7c32e0d95873
loc991c414cb6c9	loc69e74375b841
loc7c934a667999	loca04892bcffe9
locd8470b65d64b	locea2e2e01b99c
loc46b3ff1e6b9a	loc125ac9d5de09
locd777103bd088	loc72ce64beb561
loca674ab421c49	loc6597d444ca5c
loc82b861dfb765	loc61df9930af3b
loc82b861dfb765	loc2c4c767ea9b7
loc22c42e389de3	loc65bfa3da7f89
loc9a48431374e1	locf51f6cd689bb
loc08caad3924ee	loc7ee7acc30be1
loca1a84d46e52a	locfb9f1336aa98
locbbb93e2c6c42	loc6a5903165043
loc37efd432abe4	loc4a341f4d3e02
locc25e0bed112f	locc70453923b8e
locc2ea2de6af6c	loc87f2ad0c0fd7
locb7bca082fca0	locab436b86eb1a
loc515028b0f98a	locd7ad53b0d1eb
loc64c822b0bad5	loc4df40037d8c0
loc13ed320cd188	loc9fc9cdac1e1a
loccdfc709471ce	loc1a53a1d670c3
loc8e5a2b16aaaa	loc8f498b475ec6
loc74f8893fb76e	loc7213d03738b9
loca674ab421c49	loc949ba8e90a2d
loc0621c45c46f4	loc39ed15931919
loca307cf61ba97	locbb31ea1d3b07
loc8f565e81c655	loc7213d03738b9
loc656f84726510	loc712bc92c5924
loc3fe991822440	locf4e180745c81
locf57f2052e543	loc6413994c2b24
loc86dc9bf35404	loce4c31fa791f4
loc875118ed8437	loc7024d58288dd
locfd8472c41cbe	loc982a183f8eaa
loc46443686a430	locaa3e42e45c6a
locfdc6079b562f	loc67a11408d754
locf3eb6fff8056	loc72811653f4ea
loc6d7f0d49a3d6	locbdf0138dcf54
loc47e9d5554e9d	locb43c247a8faa
loc3b6fd5dcd874	loc7f158a48110c
loc250adfcbc82d	locc2ea2de6af6c
loc3b583afba248	loc7767bba5f04d
locc91f4a31a1bc	loc167afe1d878c
loce01ddbd8c8e5	loc5b05103f6f82
loc819a06b032e3	loce8f39e233734
loc712bc92c5924	loc14b657721382
loc4a341f4d3e02	locab56fbb21cf8
locae68612e5fe1	loc08c532fb125f
loc264c2d9ba83e	locfd8472c41cbe
loc8f565e81c655	locfb9f1336aa98
loc264c2d9ba83e	locb8f595af5fb8
loc406d1f7b5fe3	locc7ee8539a72b
loc515028b0f98a	loc0425405c5bfd
locc672a234fa5a	loc8c28aafe5f9e
loc1e33f92d8409	loc9b22ab8c108e
loc910a14938d48	loc780d4ed4ca46
loc37efd432abe4	loc7d9d9818d4b9
loc4e07cec4cde4	loc2aba432ff405
loc20a81a4bf246	loc5ca016a59345
locd8470b65d64b	loc65b04ce00376
loc3754c5fc3408	loc9baff2540961
loc12cc6354a4ba	loc622403923b50
loc5c7c3d320a8a	loc89fc2edfdfe4
loc2508c9e5a93c	loca96159199116
loc098e933e1fd2	loc99016095ec57
loc1a7553da1009	loc52381735d3aa
loca1efec8fa041	locaaacb1131c06
loc46f8f01fbac9	loc72d1f0339be6
loc5e975e2e1c0e	loc09a44571c760
loca674ab421c49	loc8a8629abf63d
loc36422efcb9c0	locbacb63b5901d
loc5c27e3f22fc1	loce48c38ae2d6a
loc46b3ff1e6b9a	loc137c40f435ae
locb53ace4ff1b6	loc586aee79b3cd
loc2d817b7080e2	locc1978682d520
loc7ab22202aac3	loca1efec8fa041
loca674ab421c49	locf3a32f2950bf
loc9a48431374e1	locddc4a1bcd8ba
loc201e214973bd	locac7743d369bc
loc46f8f01fbac9	locab56fbb21cf8
loccd13bd88b567	locfd8472c41cbe
locddc4a1bcd8ba	locb87676ac9be6
locd755ccb7197e	loc9ee54c810992
loc3fe991822440	loca868732226b1
loc098e933e1fd2	locf49b5afa8d59
locbd7d4fd6b9e7	loca4f3a116d4ba
locc098f71b2faf	loc387ede10db16
loc9fe59dbd0874	loc6849c4e53590
loceb41e8eec3ee	loc33cff9526850
locff58d0167065	locffba4992fc2a
loc46443686a430	locaf6f4327a65a
locea2e2e01b99c	loc89cee4954cc2
loce48c38ae2d6a	loc7024d58288dd
loc74f8893fb76e	locf91c2122e305
loc9fe59dbd0874	locc0b6d754799e
loc5900b8cc74c8	loc00f17fd098b9
loca307cf61ba97	loc1cd13a25341f
loc532c3dac4248	loc5f898c91f906
loc00a9769647d7	loc5c27e3f22fc1
locfdc6079b562f	loc9e7da77def26
loc679429866800	loc8f1124adee14
loce6098ac5df0c	loc338a35dd09f0
loc82baa1179308	loc139c325d29ef
loc98325a7e67bf	loc6a54ce63b777
loccaca39f133a7	loc42979bc97c35
locbb6ca08c118e	loc7c32e0d95873
locff62fb6a898a	locbb2eb3c34acf
locf065e41cfac9	loc167afe1d878c
locfa38377aaf29	locc474326381e9
loc11fb0b5df130	loc47e9d5554e9d
loc3d949ab3c987	loc0a03ed3531fd
loc4195fdfecc8e	loc65b04ce00376
locae977e7a8d83	loc517609e09c88
loc5e68bb81d75d	loc58ed21f010b4
locfd8472c41cbe	locb8f595af5fb8
loc556974a8bc81	loc2bac131c9af5
loc29841cc6d6f1	loc5313769385e6
loc232da9d11723	loc8d13e5004506
locb694454fbbb1	loc913bf4728c4e
loc5900b8cc74c8	loca27c9809ab3c
loc2f9c80de6f7d	locab56fbb21cf8
locd724f9a08a75	loc33cff9526850
loca1a84d46e52a	loc49fb687cbcb9
locabdfa0718385	loc6f542385dd44
loc0b665c0fe535	locbbb93e2c6c42
loc532c3dac4248	loc736a986172a0
loc8fef59c1c585	locee4a8f85818e
loc0a8087d68433	loc0f38b5d63616
loc913bf4728c4e	locb694454fbbb1
loc786911d8fa57	locc89665bfa152
locf3fc3fca2acd	loc6849c4e53590
loc2508c9e5a93c	loce11f06c54f46
loc74f8893fb76e	locfb9f1336aa98
loc09a99bf786b9	loc195f12d6882f
loce25dfc481765	loc756873fe7d89
loce16236caf708	locb778a527feda
loc4883549a5421	locee4a8f85818e
loc90b2f4dd8c2d	loc098e933e1fd2
locc25e0bed112f	locffd0eebac0eb
locc5abea08e85d	loc620b77ab764b
loc86cf2bd4847b	loc89cee4954cc2
loc0a03ed3531fd	locea2e2e01b99c
loc29841cc6d6f1	loc0f418377e392
loc5100fc96abff	loca2dba6250aa2
loc2d817b7080e2	loc4ff8c926c940
locd06d20cbea22	loc9a86c6faf562
loc82baa1179308	loc88487743ffc5
loc9fb289b0a33e	locb71d10cf3b7c
loca818c5eaa373	loc67a11408d754
loc9165cd64854f	loc46f8f01fbac9
locb7bca082fca0	locdad186d625ec
locae68612e5fe1	locde7f91aff148
loc76dea039b41f	loc517fb29cebaa
loc6413994c2b24	locccf64b3f1134
loc6de6554b144b	loc6b1692d65d02
loc6413994c2b24	loc312e1aba6ed5
loc6a54ce63b777	locf6de7ad02342
loceb41e8eec3ee	loc3b77572d819c
loc6280f9052ec0	loc4df40037d8c0
loceb41e8eec3ee	loc5746dd073881
loc2424df148d7d	loc5ca016a59345
loc8c9f2867857c	loc01c2784fcea2
loc9fe59dbd0874	loc82e9519dd9b6
loc406d1f7b5fe3	loc08f132cbeca5
loc7ab22202aac3	loc5d01e4efc615
loc11fb0b5df130	loc8e5a2b16aaaa
locc672a234fa5a	loc52b530498621
locf3eb6fff8056	loc5c7c3d320a8a
locbd7d4fd6b9e7	loc79e45c9fa669
loc98325a7e67bf	locf6de7ad02342
locae977e7a8d83	locc0b6d754799e
loc82b861dfb765	loc79e45c9fa669
loceb6884033cea	locc1d3550695e9
loc2d817b7080e2	locadc5cabaa80e
loca1b6ce72e35a	loc2ed32abac511
locb948618ae376	loc7b0a16b98291
locfd8472c41cbe	locb10305db77b5
loc6a54ce63b777	loc853ce1db7b4e
loc4195fdfecc8e	loc3319215a0a10
loc8e5a2b16aaaa	loc82e1fbce0752
loccdfc709471ce	loc0787c217a18e
loc86dc9bf35404	locde8437240459
loc4883549a5421	loc6ae8cb311823
loc875118ed8437	loc6de0828869d7
loc7d9d9818d4b9	loc2f9c80de6f7d
loc3832b905a97e	loce16c47ba0da0
locd755ccb7197e	locb453101c5355
loc0067a4549ed1	loc44e7525b33ad
loce36428dd6505	loc631445166691
loc94fdc21035b3	locb5e58c390fb7
loc679429866800	loc90c60f5d2011
loc9ea2b366d63f	loc9fe59dbd0874
loce1597eda1cc3	loc112bde4669f8
loc5ba812288f5b	locf5e258559e72
loc5c7c3d320a8a	loc5c43c0f368e0
loc46443686a430	loc70eb03d586f8
locff62fb6a898a	locbcb60f6b546d
locc84be248155b	loc376ed9d2771c
loc06cc48b309e5	locd8a8ad3be01a
loc47e9d5554e9d	loc11fb0b5df130
loccb9bfb1fb49a	loc21df90314583
loce1597eda1cc3	loc9b557da50675
loce11f06c54f46	loc00f0949ea0ad
locf2d2a267a354	loc362a83851d1d
loc72d1f0339be6	loc46b3ff1e6b9a
locf51f6cd689bb	loc31f384e524fe
loc399d9bd46679	loc45ea5b7f228b
locfa38377aaf29	loc945b94d8a45a
loce6098ac5df0c	loc51f77eba864c
locc7ee8539a72b	locff6258c8ea42
loc2508c9e5a93c	loc488293f7746c
locc2ea2de6af6c	loce48c38ae2d6a
loc556974a8bc81	loc6f542385dd44
loc6280f9052ec0	loc9fe59dbd0874
loc17a18f5ff3a6	loc1cd13a25341f
loc82b861dfb765	locbd7d4fd6b9e7
locb48ce003b11e	loc08d8263cd319
loc5c27e3f22fc1	loc8c9914c41758
loc6a54ce63b777	loc4a26362045e1
loc34a55c4d0462	loc133dbb57fdfa
loca0398a35cf5e	loc9e7da77def26
locd755ccb7197e	locfd8472c41cbe
loc1fbfb471eb7c	loc273baad8537b
loca818c5eaa373	loce01794437106
loc94fdc21035b3	loc8710c53a552c
loc098e933e1fd2	loc22deaf46b773
loc7213d03738b9	locfb9f1336aa98
loc3754c5fc3408	loc6755f6d71124
loc098ac8eaabef	locf5fef268f8cd
locc0b6d754799e	loc9ea2b366d63f
loc712bc92c5924	loced93b3da3f2b
loc12c0177d3d38	loc4858bcc1d912
locfdc6079b562f	loc4a7c5154c298
loc910a14938d48	loc346283553b3d
loc8fef59c1c585	loc1556821a864f
loceac5d85ea01d	locffa1c8993b70
loc00a9769647d7	loc0621c45c46f4
loc90b2f4dd8c2d	loc6a5903165043
loc00a9769647d7	locb9872f35df41
loc712bc92c5924	loce578d6ccca3a
locd724f9a08a75	loc5a5cdc0d3a63
loc8688ba223de1	locf13848e11d5e
loc8688ba223de1	locced14f419065
loca1a84d46e52a	loc6ae8cb311823
locfd8472c41cbe	loccd13bd88b567
loca2fd80ef71d3	locdc708fb671c8
loc5e975e2e1c0e	loce515c2e1a55e
loc92bf5bc798e7	locfdc6079b562f
loc695c9ddc8068	loccbfe7d3f7b9f
loc610e6e8cd167	locaf8d2e9e4584
loc098ac8eaabef	loc65a4fa5b2f2a
loc92bf5bc798e7	loc1e06c486c813
loc3d949ab3c987	locd6810256cc93
locb71d10cf3b7c	loc325c0b30e951
loc264c2d9ba83e	loc86dc9bf35404
locd06d20cbea22	loce6098ac5df0c
loc67a11408d754	loce01794437106
loc695c9ddc8068	loc0e52a8070878
loc0621c45c46f4	loc7ab22202aac3
loca1efec8fa041	loc64cc79e3a232
loc7ab22202aac3	loc786911d8fa57
locc25e0bed112f	locc4bf59133c77
loc201e214973bd	loc61df9930af3b
locb694454fbbb1	loc00a9769647d7
loc4fa4b090ce9e	locadc5cabaa80e
loc4161e46afd2f	loc1b271c01e3dc
loc6413994c2b24	loc846cf797318d
loc6c0f29d040f7	locd0290dd0bcb8
loccd13bd88b567	locd6f79866f950
loc94fdc21035b3	locc3c3ee587a70
loc86b22e8e6ecf	loc4fbe8e7f70da
loc29841cc6d6f1	loc6f542385dd44
loc31f384e524fe	locddc4a1bcd8ba
loc532c3dac4248	loc87af61b59301
locdd716f1059c5	loc0a03ed3531fd
locc0b6d754799e	loc1a22f173d7f3
locddc4a1bcd8ba	locf51f6cd689bb
loc62ed665318da	locf904e0923e0a
loc4ff8c926c940	loc67f13bfe7b6c
loce36428dd6505	loc00055278d626
locfa38377aaf29	locc9e8f86ebac8
loc4a7c5154c298	locebf4f333240b
loc1e06c486c813	loceea4a7d012b2
locfe955a87410d	loce7252de87492
locd777103bd088	loc9f89abda4997
locf3eb6fff8056	locdb359fd94a95
loc7213d03738b9	loc4dfb8458b2e2
loccb9bfb1fb49a	loc0f84961f7515
loc22c42e389de3	loc49fb687cbcb9
locfd8472c41cbe	locd6f79866f950
loca1b6ce72e35a	loc9b20cd160517
loc7213d03738b9	loc8f565e81c655
loc910a14938d48	loc8494a97d1462
loc875118ed8437	loc533a569e6f80
loc4fa4b090ce9e	loc00a9769647d7
locf2d2a267a354	loc5f554e877a66
loceb6884033cea	locd6e269b7e86d
loc76dea039b41f	loc4fa4b090ce9e
locb281644d861d	loc4e07cec4cde4
loc62ed665318da	locaaae9e603891
locd755ccb7197e	locb10305db77b5
loca0398a35cf5e	loc533a569e6f80
loce16236caf708	loc668a2937fcd8
loc86b22e8e6ecf	locf44a583273a6
loc17a18f5ff3a6	loce6085a4cf5c8
loc0e534d470df9	locfe57383287a4
locff58d0167065	loc4adf369ac573
locb948618ae376	locac09c3fe5989
locd6f79866f950	locfd8472c41cbe
loceac5d85ea01d	loc29a798d6921b
loc0067a4549ed1	loc7d26824d03a7
loc1b5a0e70afd4	loc450465b4eebb
loc1b289d3ff2fc	locfa061fb813bf
loce48c38ae2d6a	loc87f2ad0c0fd7
loc1eda86883ae9	locbdef0302d160
loca5643321b976	loc78542407f81d
loc39cd317eec9d	loc86dc9bf35404
loc1c5f2c23fc52	loc8e2916c92321
locb281644d861d	loc1787c3eae691
loc15a8d395ef61	locc3639fd0463f
loce3f8de63f06a	loc656f84726510
loc75d84680b181	loc668bbb760814
loc22c42e389de3	loca1a84d46e52a
locf4e180745c81	loc91cd8110d36c
locbf553ce41d73	loce01ddbd8c8e5
locff58d0167065	locadd0c24c200e
loc46b3ff1e6b9a	loc3c9dab9168cc
loc556974a8bc81	locabdfa0718385
loc12c0177d3d38	loc51ba976fe589
loc9e7da77def26	loc1e06c486c813
locf3fc3fca2acd	locff62fb6a898a
loce42a110faa48	loc3319215a0a10
loc6de6554b144b	locd6190ebbe554
loc0b8afd71fce1	locddc4a1bcd8ba
locf16910f90fb9	loc6f887e0e8e31
locdd716f1059c5	loc3b64e6146ff8
loc20a81a4bf246	locc4cc828c785c
loceb6884033cea	loc2d968a2b2b3c
loc13ed320cd188	locaddb8f975411
loc7f158a48110c	loc3b6fd5dcd874
locd777103bd088	loc7dfeba59b581
loc15a8d395ef61	loc5060abf8fe2d
loc82baa1179308	loc7b6dac86f8e1
loca1b6ce72e35a	locfc54031c1c5a
loc6413994c2b24	locbcb60f6b546d
loc9b20cd160517	locfc54031c1c5a
locf2d2a267a354	loc01699d7adbaa
locff58d0167065	loca0ff70132823
loc4e07cec4cde4	loc88487743ffc5
locb344fc28a060	locb52441c1176c
loc4883549a5421	loccd065e8b9b5f
loc86cf2bd4847b	loc2d817b7080e2
locd724f9a08a75	loce2f3ad490448
loc64c822b0bad5	locfb463ae5ac4b
locba8f7a4a0c92	loc398d22e7ad86
loca56f2b16461e	locb17fb225139f
locedacea740a10	loc8710c53a552c
loc2c4c767ea9b7	loc201e214973bd
loc4423238fcdd8	loc528325f2a993
locc7ee8539a72b	loc8b861551a212
locb53ace4ff1b6	locc4ed4fb834d3
loc610e6e8cd167	loc6751854c9968
locd6190ebbe554	loc6de6554b144b
locb281644d861d	loc23852a0ecbdb
loc9a86c6faf562	locb2d0013fa2c6
loc12c0177d3d38	loc3271d3814fc5
locfa38377aaf29	loc07952153427c
loc4423238fcdd8	loc387e057eab15
loc9a86c6faf562	loc44a32f330f55
loccbfe7d3f7b9f	loc695c9ddc8068
loc956fa85c7b0c	loc2c9ce0acd6de
locb71d10cf3b7c	loc63a05a113f90
loc338a35dd09f0	loc2aab588344a9
loc38cbe92d1159	loccb9bfb1fb49a
loc11b2a92fb5f0	loc9e7da77def26
loc70eb03d586f8	loc0eced751f474
loca674ab421c49	loc070655c28fae
locd755ccb7197e	loc264c2d9ba83e
loce16236caf708	loc697cc69c0201
loca1a84d46e52a	loced93b3da3f2b
loc7d9d9818d4b9	loc558550055434
loca1efec8fa041	loc7ab22202aac3
loc4423238fcdd8	loc1895ded7c994
loc610e6e8cd167	loc8907106aa438
loc1a7553da1009	loc4be7292f21af
locc586266ef8cc	loc08a84015fde0
loc4858bcc1d912	locf07f0a553979
loc12cc6354a4ba	loc0e534d470df9
loc4fa4b090ce9e	locb694454fbbb1
locc70453923b8e	locc25e0bed112f
loc108a649ba4ae	loc2ec56077d62c
locc5abea08e85d	locec99dd6d0979
loc1b5a0e70afd4	loc4195fdfecc8e
loc76dea039b41f	loc5c27e3f22fc1
loc5e68bb81d75d	loc70a31d7a71da
loc86dc9bf35404	loc39cd317eec9d
loc3d949ab3c987	locea2e2e01b99c
loc94fdc21035b3	loca0d2fd235790
loc46f8f01fbac9	locdcb72e93920d
loc8fef59c1c585	loc2546709d8859
loc956fa85c7b0c	loc06d0d0aef5d7
loc5c94ac6107ca	loceb4ecf2e7464
loc13ed320cd188	loc8a4f8d6b9718
loc3d949ab3c987	locace3209a1388
loccdfc709471ce	loc0697a21b44b0
loc515028b0f98a	loc692ebcbd748b
loc46b3ff1e6b9a	loc37f7d645fb7e
loc63a05a113f90	loc54237c4302db
locffa1c8993b70	locb778a527feda
loc0067a4549ed1	loc2833f5edae08
locbd7d4fd6b9e7	loc82b861dfb765
loc6de6554b144b	locc89924437933
loc786911d8fa57	loc7ab22202aac3
locba5e689e47f8	locca4ba0d70672
loc2d817b7080e2	loc76dea039b41f
loc515028b0f98a	loc1d612b58d12f
loc2424df148d7d	loc7769aef63ae9
loc86cf2bd4847b	loc51f316792e18
loc0067a4549ed1	loc4e0cff58457d
loc0e534d470df9	loc83fcba1701d6
locec99dd6d0979	locc5abea08e85d
loc9e7da77def26	locfdc6079b562f
loc2424df148d7d	loc709dcb832d80
loc1a7553da1009	loc25d0560189ac
loc9165cd64854f	loc38cbe92d1159
loce11f06c54f46	loca7a0c0db6b97
loccdfc709471ce	loc9ea755dc73b5
locea2e2e01b99c	loce4c31fa791f4
loccbfe7d3f7b9f	loc433bbb473372
loc630ef4fec09d	loce11f06c54f46
locf4e180745c81	loc4cdd1af01845
loc1f73672977ce	loc09eb23893c4a
locbcb60f6b546d	locb52441c1176c
loc9a48431374e1	loc0b8afd71fce1
loc8733d13ded2e	loc17a18f5ff3a6
loc67d2e4d427ab	loc3b6fd5dcd874
locf3fc3fca2acd	loc7767bba5f04d
loce6098ac5df0c	locd06d20cbea22
locd6190ebbe554	loc58fa3791b4e9
locb0a9c63101c7	loc4f3728f8eede
loc5c27e3f22fc1	loc7e96c43cdd6c
loc74f8893fb76e	loc2546709d8859
locd777103bd088	locfd0ac2a1c5e8
loc7d9d9818d4b9	loc37efd432abe4
locbcb60f6b546d	loc6413994c2b24
loc86dc9bf35404	loc90b3cd765444
loc9fe59dbd0874	loc4df40037d8c0
loce6098ac5df0c	locbd15dbd99fc7
loc2d817b7080e2	locff0c4d75067f
loc1f73672977ce	locc2fe654c18e1
loc37efd432abe4	loc137c40f435ae
loc5100fc96abff	loc91cd8110d36c
loce42a110faa48	loc65b04ce00376
loc8c9f2867857c	loc08caad3924ee
loc36422efcb9c0	loc06d0d0aef5d7
loccaca39f133a7	loc1492a23dbc74
loc2508c9e5a93c	loc00f0949ea0ad
loc1492a23dbc74	loc656f84726510
loc6c0f29d040f7	loc1e1a054408cd
loc0e534d470df9	loc615a8cfd40bb
loc264c2d9ba83e	loc90b3cd765444
loc2508c9e5a93c	loc273baad8537b
loc786911d8fa57	loc49db457e2be8
loc0de2086617a5	loc0879ced62e91
loc515028b0f98a	locea401be8d5d9
loccaca39f133a7	loc201e214973bd
loc4423238fcdd8	locf07cdad512c3
locba5e689e47f8	loc96c2ce4280fb
loc8688ba223de1	locc5b7a8a809bf
loc38cbe92d1159	loce47e16b2ae23
loc1f73672977ce	loc60566a23e081
loce16236caf708	loc9b557da50675
loc7c934a667999	loc3453b73ac5e6
loc4ff8c926c940	locadc5cabaa80e
loc29841cc6d6f1	locb3584a0e11e8
loc399d9bd46679	loc5a1724a82257
loc9e7da77def26	locc40c10b3741d
loc245c69160468	locca9f8b1cf0b0
loca5de38b84720	locaaacb1131c06
loc09a99bf786b9	loc3549fec27c38
loce0707ac065f9	locc63a6c94740e
loca56f2b16461e	loc0971566e0102
locad899e5d272f	loce237bfb5fc0e
loca5de38b84720	loc10fc59c40668
loca2fd80ef71d3	loc242cedc10c00
loc6de0828869d7	loc7c32e0d95873
locbbb93e2c6c42	loc0b665c0fe535
locffd0eebac0eb	locc25e0bed112f
loc913bf4728c4e	loc67f13bfe7b6c
locc098f71b2faf	loc76166a14c514
loc4423238fcdd8	loc24c3b5111572
loce16236caf708	loc24a73b7c0f1f
loce25dfc481765	loc4cca17382228
loc695c9ddc8068	loc77c523d8c2ba
locc605118e951a	loc4161e46afd2f
loc0621c45c46f4	loc00a9769647d7
loc245c69160468	loc85e82c7c178e
loc250adfcbc82d	loc695c9ddc8068
loc09a99bf786b9	loc57796ca45e3b
loc1a22f173d7f3	locae977e7a8d83
loc12cc6354a4ba	locc2b1ccff24c4
loc4883549a5421	loc974441b38fa0
loc4e07cec4cde4	loc1787c3eae691
loc532c3dac4248	loce5c522e6590e
loceb41e8eec3ee	loc7847de196bbe
loca5643321b976	loc13a6ec04747e
loc991c414cb6c9	locf09eea4c4a58
loc6ae7eaa3c1f3	loc10fc59c40668
locea2e2e01b99c	loc65b04ce00376
locec99dd6d0979	locfbb2aa2cb994
loc72d1f0339be6	loc46f8f01fbac9
loc31f384e524fe	locb87676ac9be6
locb344fc28a060	loc846cf797318d
locf065e41cfac9	loc4b34c45998d4
loc1fbfb471eb7c	loce21ef8eb86c0
locb694454fbbb1	loce587d8cdc0f5
loc13ed320cd188	loc489b61204e02
loc4e07cec4cde4	loce94c02bf1598
loc39cd317eec9d	locd6810256cc93
loce11f06c54f46	loca29090f76301
loc29a798d6921b	locffa1c8993b70
loc17a18f5ff3a6	loce4ce9f3183f9
locadc5cabaa80e	loc67f13bfe7b6c
loc0a03ed3531fd	loc6f887e0e8e31
loc4fa4b090ce9e	loc5c27e3f22fc1
locffa1c8993b70	loc29a798d6921b
locd06d20cbea22	loc44a32f330f55
loc7ab22202aac3	loc0621c45c46f4
loce3f8de63f06a	loc712bc92c5924
locffa1c8993b70	loc1a1d44d067f2
locba8f7a4a0c92	loc076ac89bbcfd
loc98325a7e67bf	loc8c852c59ffe5
loc62ed665318da	loc1d422408d336
loc22c42e389de3	loc20067eb0384a
loc13ed320cd188	loc4fbe8e7f70da
loca56f2b16461e	loc0621c45c46f4
loccaca39f133a7	loce578d6ccca3a
locdf0288b649a4	loc3253b162ad37
locf16910f90fb9	loce42a110faa48
loc0b6e17218dd4	loc2c805e9e142d
loc20a81a4bf246	locf9242b623b72
loc780d4ed4ca46	loc910a14938d48
loc86b22e8e6ecf	locb2d0013fa2c6
loc6de0828869d7	locb9872f35df41
loc9165cd64854f	loc558550055434
locc098f71b2faf	loc29baf1548f7a
loc7d9d9818d4b9	loce47e16b2ae23
loc72d1f0339be6	loc4a341f4d3e02
loce11f06c54f46	locfd2b1f4a0ddc
locf065e41cfac9	loc133dbb57fdfa
loce11f06c54f46	loc14f8110c3a65
locc5abea08e85d	locfbb2aa2cb994
loc1b289d3ff2fc	loc9b3965d0a929
loc6280f9052ec0	loc5f0c59159354
loc5100fc96abff	loc3453b73ac5e6
loc3b64e6146ff8	loc025dead673cc
locc84be248155b	loc4131e469737e
locbbb93e2c6c42	locf5e258559e72
loc3319215a0a10	loc4195fdfecc8e
loc12cc6354a4ba	locebcbc7bb3ea0
locedacea740a10	locbab0764027eb
loc0b665c0fe535	locb110c53383ed
loc232da9d11723	loce85021b8a41e
loc0de2086617a5	loc2a07d1186bc2
locf065e41cfac9	loc129f19b99706
loc910a14938d48	loc277951454068
loc00a9769647d7	loc1032c5d1ed5f
loc1a22f173d7f3	loc8466fa581083
locbd7d4fd6b9e7	loc2c4c767ea9b7
loc108a649ba4ae	loc32e841d50c5c
locc67851215f08	loc4883549a5421
locec99dd6d0979	loc098ac8eaabef
loc8fef59c1c585	loc5e1166b18e85
loc875f8bb64843	locffa1c8993b70
loc201e214973bd	loc2ef00ac196a6
locff62fb6a898a	loc3ccb852d09c7
locfdc6079b562f	locebf4f333240b
loc7a8164839d54	loc8b861551a212
loc4883549a5421	loc125dcdb1e951
locb694454fbbb1	loc4add9dd25668
loc245c69160468	loce8cc4236dbff
locb281644d861d	loce94c02bf1598
loc9a48431374e1	locc134b649436c
locb344fc28a060	locd1d128ec42fa
loc1a7553da1009	loc7bdb81a803ef
locfe955a87410d	locac6f70db6abd
loccdfc709471ce	loc78e7b14fd31c
loc8f565e81c655	loced93b3da3f2b
locd665688d0e4d	loc410264755cec
loceac5d85ea01d	loc1a1d44d067f2
locad899e5d272f	loc6f887e0e8e31
locb281644d861d	loc8230c2a8625c
loc913bf4728c4e	loc4add9dd25668
loc4a7c5154c298	loc9e7da77def26
loc9fb289b0a33e	locc90f113d3978
loc1fbfb471eb7c	loc2508c9e5a93c
locae68612e5fe1	locdc955a0a97c9
loc34a55c4d0462	locff0c231b0f12
loc406d1f7b5fe3	loc7ab22202aac3
loc8fef59c1c585	loc93dc0822fb9e
loc64c822b0bad5	loc82baa1179308
loc780d4ed4ca46	locc08b3f37ebf5
locf16910f90fb9	loc0a03ed3531fd
loc1e06c486c813	loc92bf5bc798e7
loc8f498b475ec6	loc8e5a2b16aaaa
loc5e68bb81d75d	locf51265a10fb9
loc2c4c767ea9b7	loc42979bc97c35
locf51f6cd689bb	locddc4a1bcd8ba
loc0e534d470df9	loca70615658d27
loc4fa4b090ce9e	loc8c9914c41758
loc1492a23dbc74	loc42979bc97c35
loc4a7c5154c298	loc8123ed12ea8d
loc76dea039b41f	loc433bbb473372
loc6ae7eaa3c1f3	loc67f13bfe7b6c
loc0b6e17218dd4	loc86cf2bd4847b
locff58d0167065	loc6e00aed8d598
loc4858bcc1d912	loc7213d03738b9
loc8c9f2867857c	locc134b649436c
locb53ace4ff1b6	locecad945e7138
locb8f595af5fb8	locfd8472c41cbe
loc786911d8fa57	loc3c9dab9168cc
locc84be248155b	loc5548f3005a10
loc75d84680b181	locc31c8ee3782e
loc11b2a92fb5f0	locbd7d4fd6b9e7
locffd0eebac0eb	locc4bf59133c77
loc656f84726510	loc8f565e81c655
locc84be248155b	loce718575b31cf
loc3319215a0a10	loc65b04ce00376
loc79e45c9fa669	loca4f3a116d4ba
loc08caad3924ee	locaf6f4327a65a
loc4a341f4d3e02	loc46b3ff1e6b9a
loceb41e8eec3ee	loc0a64ce1e836f
loce1597eda1cc3	loc668a2937fcd8
loc8733d13ded2e	loce6085a4cf5c8
loc9901d119afda_1	loce48c38ae2d6a
loc9901d119afda_1	loc9901d119afda_2
loc9901d119afda_1	locc2ea2de6af6c
loc9901d119afda_1	loc87f2ad0c0fd7
loc9901d119afda_1	locddc4a1bcd8ba
loc9901d119afda_1	locb87676ac9be6
loc9901d119afda_1	loc31f384e524fe
loc9901d119afda_1	loc7024d58288dd
loc9901d119afda_1	loca0398a35cf5e
loc9901d119afda_1	loc9e7da77def26
loc9901d119afda_1	loc1e06c486c813
loc9901d119afda_1	loc0b8afd71fce1
loc9901d119afda_2	locfe955a87410d
loc9901d119afda_2	loc250adfcbc82d
loc9901d119afda_2	loc77c523d8c2ba
loc9901d119afda_2	loce7252de87492
loc9901d119afda_2	locc2ea2de6af6c
loc9901d119afda_2	locf51f6cd689bb
loc9901d119afda_2	loc31f384e524fe
loc9901d119afda_2	loc9901d119afda_1
\.

-- gnaf_202602.streets: 405 rows
\copy gnaf_202602.streets FROM stdin
116	VIC1930047	locad899e5d272f	BENT	PARADE	\N	BENT PARADE	BLACK ROCK	3193	VIC	PDE	\N	CONFIRMED	-37.96934005	145.01449478	4	34	0101000020A41E000002C2C1BD76206240FCB9B25513FC42C0
583	VIC1930548	loc2c4c767ea9b7	BRUCE	STREET	\N	BRUCE STREET	PRESTON	3072	VIC	ST	\N	CONFIRMED	-37.74167445	144.99406282	4	187	0101000020A41E00003AC2D45CCF1F6240AF833930EFDE42C0
800	VIC1930780	loc399d9bd46679	CEMETERY	ROAD	\N	CEMETERY ROAD	TYLDEN	3444	VIC	RD	\N	CONFIRMED	-37.32195322	144.41435402	4	15	0101000020A41E0000B79B5C63420D6240F65E5BC335A942C0
918	VIC1930906	locea2e2e01b99c	CENTRAL	AVENUE	\N	CENTRAL AVENUE	MOORABBIN	3189	VIC	AV	\N	CONFIRMED	-37.93510109	145.03875395	4	164	0101000020A41E0000E87AEC783D21624082007C64B1F742C0
929	VIC1930917	loc7f158a48110c	CENTRAL	AVENUE	\N	CENTRAL AVENUE	BLAIRGOWRIE	3942	VIC	AV	\N	CONFIRMED	-38.36450830	144.76085892	4	51	0101000020A41E0000A348CEF4581862406ECF3D35A82E43C0
1057	VIC1931054	loc0a03ed3531fd	CENTRE DANDENONG	ROAD	\N	CENTRE DANDENONG ROAD	CHELTENHAM	3192	VIC	RD	\N	CONFIRMED	-37.96777126	145.07512399	4	462	0101000020A41E00003E066D6A67226240B7DABBEDDFFB42C0
2276	VIC1932338	loc656f84726510	CHALEYER	STREET	\N	CHALEYER STREET	RESERVOIR	3073	VIC	ST	\N	CONFIRMED	-37.72791240	145.02512875	4	239	0101000020A41E00000FEECEDACD2062402B2DC83B2CDD42C0
2587	VIC1932666	loc4a6dd2077a69	ATHERTON	DRIVE	\N	ATHERTON DRIVE	VENUS BAY	3956	VIC	DR	\N	CONFIRMED	-38.67354276	145.78606915	4	158	0101000020A41E0000A0747D7A273962402B542FA6365643C0
2631	VIC1932710	loca674ab421c49	ATKINS	STREET	\N	ATKINS STREET	EUROA	3666	VIC	ST	\N	CONFIRMED	-36.75706336	145.57691793	4	32	0101000020A41E00006F3A971C763262409519C273E76042C0
3109	VIC1933214	loc5c27e3f22fc1	BILLS	STREET	\N	BILLS STREET	HAWTHORN	3122	VIC	ST	\N	CONFIRMED	-37.83841382	145.04173933	4	200	0101000020A41E0000D329B8ED552162400CB5E02451EB42C0
3789	VIC1933940	locfdc6079b562f	CHARLES	STREET	\N	CHARLES STREET	ASCOT VALE	3032	VIC	ST	\N	CONFIRMED	-37.78003312	144.90740671	4	146	0101000020A41E0000DFF3CB79091D624032191220D8E342C0
5038	VIC1935251	loce48c38ae2d6a	BURNLEY	STREET	\N	BURNLEY STREET	RICHMOND	3121	VIC	ST	\N	CONFIRMED	-37.82084397	145.00805430	4	1481	0101000020A41E0000F36217FB4120624068224B6A11E942C0
5319	VIC1935569	loc1e06c486c813	ABBOTSFORD	STREET	\N	ABBOTSFORD STREET	NORTH MELBOURNE	3051	VIC	ST	\N	CONFIRMED	-37.79922277	144.94613738	4	750	0101000020A41E0000F113E6C1461E62402CAF85EE4CE642C0
5351	VIC1935602	loc00a9769647d7	ABECKETT	STREET	\N	ABECKETT STREET	KEW	3101	VIC	ST	\N	CONFIRMED	-37.80278700	145.02826815	4	20	0101000020A41E000097789B92E7206240B55373B9C1E642C0
5353	VIC1935604	loc9901d119afda_1	ABECKETT	STREET	\N	ABECKETT STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.80959128	144.95964390	4	10635	0101000020A41E0000CAC91F67B51E6240075DE3AFA0E742C0
5358	VIC1935609	locbd7d4fd6b9e7	ABECKETT	STREET	\N	ABECKETT STREET	COBURG	3058	VIC	ST	\N	CONFIRMED	-37.73494180	144.95654238	4	52	0101000020A41E0000D1EAC3FE9B1E624050BBA99212DE42C0
5664	VIC1935950	loc098ac8eaabef	BADGE	COURT	\N	BADGE COURT	LAVERTON	3028	VIC	CT	\N	CONFIRMED	-37.86090163	144.76764004	4	18	0101000020A41E0000CE5CD8819018624028F64C0632EE42C0
7089	VIC1937464	locdd716f1059c5	BALCOMBE	ROAD	\N	BALCOMBE ROAD	MENTONE	3194	VIC	RD	\N	CONFIRMED	-37.98092054	145.06208790	4	755	0101000020A41E0000467FC39FFC21624028A3E3CD8EFD42C0
7100	VIC1937475	loc245c69160468	BALD HILL	ROAD	\N	BALD HILL ROAD	HEPBURN	3461	VIC	RD	\N	CONFIRMED	-37.31224832	144.12364674	4	14	0101000020A41E0000D31102EAF4036240C350C1C0F7A742C0
7593	VIC1937990	loc9fe59dbd0874	BLUEBERRY	CLOSE	\N	BLUEBERRY CLOSE	CRANBOURNE NORTH	3977	VIC	CL	\N	CONFIRMED	-38.08010654	145.27747611	4	20	0101000020A41E0000E23B9415E128624074BF5CEE400A43C0
7769	VIC1938173	loc4423238fcdd8	BYRON	STREET	\N	BYRON STREET	HAMILTON	3300	VIC	ST	\N	CONFIRMED	-37.74041416	142.01718563	4	34	0101000020A41E0000F5D9E0C88CC06140005925E4C5DE42C0
8015	VIC1938427	loc02a3a330fe2f	CAIRNES	STREET	\N	CAIRNES STREET	INDENTED HEAD	3223	VIC	ST	\N	CONFIRMED	-38.13675754	144.70889915	4	26	0101000020A41E0000312D454DAF16624005E46445811143C0
8385	VIC1938826	loc8e5a2b16aaaa	ALAMERE	DRIVE	\N	ALAMERE DRIVE	TRARALGON	3844	VIC	DR	\N	CONFIRMED	-38.19938477	146.50667162	4	40	0101000020A41E0000C3B666A736506240393CAD70851943C0
8560	VIC1939009	locd665688d0e4d	BALMORAL	STREET	\N	BALMORAL STREET	PORTLAND	3305	VIC	ST	\N	CONFIRMED	-38.36030649	141.59787591	4	30	0101000020A41E00008510A9CC21B36140148BE7851E2E43C0
8659	VIC1939111	loccaca39f133a7	BAMFIELD	ROAD	\N	BAMFIELD ROAD	HEIDELBERG HEIGHTS	3081	VIC	RD	\N	CONFIRMED	-37.73690009	145.05632620	4	210	0101000020A41E00000E5D9A6CCD216240177CFDBD52DE42C0
9955	VIC1940488	locd06d20cbea22	BANNISTER	STREET	\N	BANNISTER STREET	NORTH BENDIGO	3550	VIC	ST	\N	CONFIRMED	-36.74269707	144.28227820	4	120	0101000020A41E0000F6AB4A6C08096240153E95B2105F42C0
10133	VIC1940668	loce1597eda1cc3	BARCELONA	STREET	\N	BARCELONA STREET	NORLANE	3214	VIC	ST	\N	CONFIRMED	-38.08421778	144.34315233	4	43	0101000020A41E0000AE5C981AFB0A6240BE6BF1A5C70A43C0
10263	VIC1940808	loca1b6ce72e35a	BOND	STREET	\N	BOND STREET	MOUNT WAVERLEY	3149	VIC	ST	\N	CONFIRMED	-37.88025304	145.13809534	4	38	0101000020A41E0000F620EB466B2462409680B121ACF042C0
11378	VIC1941988	loc17a18f5ff3a6	BARKLY	CLOSE	\N	BARKLY CLOSE	CAROLINE SPRINGS	3023	VIC	CL	\N	CONFIRMED	-37.72347161	144.74108815	4	7	0101000020A41E000080F67EFEB61762406944BCB79ADC42C0
11422	VIC1942036	locc0b6d754799e	BARKLY	STREET	\N	BARKLY STREET	CRANBOURNE	3977	VIC	ST	\N	CONFIRMED	-38.10080464	145.28762620	4	44	0101000020A41E0000214FDC3B34296240E30A9C2AE70C43C0
12052	VIC1942695	loc4e07cec4cde4	BOUNDARY	ROAD	\N	BOUNDARY ROAD	NARRE WARREN EAST	3804	VIC	RD	\N	CONFIRMED	-37.97073563	145.35381300	4	25	0101000020A41E0000CAFCA36F522B6240BBF4AB1041FC42C0
12208	VIC1942857	locbd7d4fd6b9e7	CAMPBELL	STREET	\N	CAMPBELL STREET	COBURG	3058	VIC	ST	\N	CONFIRMED	-37.75354847	144.96797300	4	81	0101000020A41E0000274D83A2F91E6240E84CB94674E042C0
12400	VIC1943059	loc1e06c486c813	CANNING	STREET	\N	CANNING STREET	NORTH MELBOURNE	3051	VIC	ST	\N	CONFIRMED	-37.79590054	144.94278549	4	749	0101000020A41E000030D6794C2B1E62409915A311E0E542C0
13259	VIC1943976	loccdfc709471ce	BOUNDARY	STREET	\N	BOUNDARY STREET	KERANG	3579	VIC	ST	\N	CONFIRMED	-35.73861532	143.92317884	4	169	0101000020A41E000018C559AE8AFD6140BFDC61F28ADE41C0
13261	VIC1943978	loc9a48431374e1	BOUNDARY	STREET	\N	BOUNDARY STREET	PORT MELBOURNE	3207	VIC	ST	\N	CONFIRMED	-37.82882324	144.94369194	4	81	0101000020A41E0000907970B9321E62407DFB42E116EA42C0
13395	VIC1944127	loc9901d119afda_1	BOURKE	STREET	\N	BOURKE STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81426536	144.96305878	4	2994	0101000020A41E00003987A560D11E62409BBBE9D839E842C0
13434	VIC1944167	loca0398a35cf5e	BOUVERIE	STREET	\N	BOUVERIE STREET	CARLTON	3053	VIC	ST	\N	CONFIRMED	-37.80337109	144.96196992	4	1890	0101000020A41E000058442475C81E62400A0D27DDD4E642C0
13607	VIC1944348	locb694454fbbb1	CANTERBURY	ROAD	\N	CANTERBURY ROAD	CANTERBURY	3126	VIC	RD	\N	CONFIRMED	-37.82312158	145.07338480	4	393	0101000020A41E0000C180142B59226240AD5D450C5CE942C0
13887	VIC1944650	loca0398a35cf5e	CARDIGAN	STREET	\N	CARDIGAN STREET	CARLTON	3053	VIC	ST	\N	CONFIRMED	-37.80018559	144.96552777	4	1266	0101000020A41E0000F4707E9AE51E6240E6E33D7B6CE642C0
14017	VIC1944783	locc91f4a31a1bc	AMBERLEA	CIRCUIT	\N	AMBERLEA CIRCUIT	TAYLORS HILL	3037	VIC	CCT	\N	CONFIRMED	-37.72130610	144.75252256	4	51	0101000020A41E0000781631AA14186240E1F31EC253DC42C0
14334	VIC1945124	loce42a110faa48	BATEMAN	STREET	\N	BATEMAN STREET	HAMPTON	3188	VIC	ST	\N	CONFIRMED	-37.93279352	145.01577763	4	52	0101000020A41E0000789B1640812062400D292FC765F742C0
14341	VIC1945132	loc0067a4549ed1	BATES	AVENUE	\N	BATES AVENUE	KORUMBURRA	3950	VIC	AV	\N	CONFIRMED	-38.43911401	145.82993562	4	21	0101000020A41E0000EF3525D58E3A62402C154CE3343843C0
14426	VIC1945221	loc0b8afd71fce1	BATMAN	STREET	\N	BATMAN STREET	WEST MELBOURNE	3003	VIC	ST	\N	CONFIRMED	-37.81098845	144.95059349	4	2054	0101000020A41E0000E5EA09436B1E624085173378CEE742C0
14654	VIC1945465	loc9165cd64854f	BAYSWATER	ROAD	\N	BAYSWATER ROAD	BAYSWATER NORTH	3153	VIC	RD	\N	CONFIRMED	-37.82716493	145.26866487	4	406	0101000020A41E00007EC711E798286240C35F598AE0E942C0
14734	VIC1945552	loc63a05a113f90	BOX	STREET	\N	BOX STREET	MERBEIN	3505	VIC	ST	\N	CONFIRMED	-34.16649958	142.05653180	4	104	0101000020A41E0000E305C71BCFC16140E972B5DB4F1541C0
15275	VIC1946124	loc29a798d6921b	CARMARTHEN	CLOSE	\N	CARMARTHEN CLOSE	WERRIBEE	3030	VIC	CL	\N	CONFIRMED	-37.90733338	144.63715249	4	17	0101000020A41E0000AE639E8D63146240A6D50C8023F442C0
15619	VIC1946485	loc3fe991822440	ANDREWS	LANE	\N	ANDREWS LANE	RED HILL	3937	VIC	LANE	\N	CONFIRMED	-38.36909570	145.01848224	4	6	0101000020A41E00006B0B116897206240104C24873E2F43C0
16466	VIC1947379	loc2c4c767ea9b7	BREFFNA	STREET	\N	BREFFNA STREET	PRESTON	3072	VIC	ST	\N	CONFIRMED	-37.74827184	145.01416868	4	52	0101000020A41E00004827E01174206240ACA8245FC7DF42C0
17063	VIC1947995	loc0b665c0fe535	ANTARES	COURT	\N	ANTARES COURT	OCEAN GROVE	3226	VIC	CT	\N	CONFIRMED	-38.26997363	144.54405622	4	18	0101000020A41E0000BB0297E868116240F3D0F37E8E2243C0
17350	VIC1948301	loc86dc9bf35404	BEDDOE	AVENUE	\N	BEDDOE AVENUE	CLAYTON	3168	VIC	AV	\N	CONFIRMED	-37.91064408	145.12807814	4	135	0101000020A41E00003ED4533719246240B0F236FC8FF442C0
17441	VIC1948395	locb7bca082fca0	BEECH FOREST-LAVERS HILL	ROAD	\N	BEECH FOREST-LAVERS HILL ROAD	BEECH FOREST	3237	VIC	RD	\N	CONFIRMED	-38.63260211	143.54839759	4	14	0101000020A41E00002B481A798CF1614051EA1E1BF95043C0
17894	VIC1948877	locff58d0167065	BRIDGE	STREET	WEST	BRIDGE STREET WEST	BENALLA	3672	VIC	ST	W	CONFIRMED	-36.55592869	145.97282629	4	173	0101000020A41E0000A6879964213F6240A43ADBAB284742C0
17906	VIC1948889	loce6098ac5df0c	BRIDGE	STREET	\N	BRIDGE STREET	BENDIGO	3550	VIC	ST	\N	CONFIRMED	-36.74999060	144.28579762	4	148	0101000020A41E000097E50C412509624059A725B1FF5F42C0
17923	VIC1948906	locc7ee8539a72b	BRIDGE	STREET	\N	BRIDGE STREET	ELTHAM	3095	VIC	ST	\N	CONFIRMED	-37.71902033	145.14635331	4	208	0101000020A41E0000900323EDAE2462402B41B1DB08DC42C0
19880	VIC1950981	loc22c42e389de3	ARMITAGE	PLACE	\N	ARMITAGE PLACE	SOUTH MORANG	3752	VIC	PL	\N	CONFIRMED	-37.63717200	145.06445333	4	12	0101000020A41E0000FC0E6E0010226240A5F622DA8ED142C0
19917	VIC1951022	locc098f71b2faf	ARMSTRONG	STREET	NORTH	ARMSTRONG STREET NORTH	SOLDIERS HILL	3350	VIC	ST	N	CONFIRMED	-37.54998258	143.85847249	4	147	0101000020A41E00001AA24C9B78FB61401F3C45D465C642C0
19921	VIC1951026	loc098ac8eaabef	ARMSTRONG	STREET	\N	ARMSTRONG STREET	LAVERTON	3028	VIC	ST	\N	CONFIRMED	-37.86050629	144.77223583	4	53	0101000020A41E0000C854EA27B6186240B1C6F21125EE42C0
20022	VIC1951129	loc7f158a48110c	ARNOLD	STREET	\N	ARNOLD STREET	BLAIRGOWRIE	3942	VIC	ST	\N	CONFIRMED	-38.37213221	144.77271499	4	17	0101000020A41E0000BA65C914BA1862407DDE3B07A22F43C0
20026	VIC1951133	loc79e45c9fa669	ARNOLD	STREET	\N	ARNOLD STREET	BRUNSWICK EAST	3057	VIC	ST	\N	CONFIRMED	-37.77454209	144.97532053	4	56	0101000020A41E0000F56E66D3351F624076F6F83124E342C0
20054	VIC1951161	loc09a99bf786b9	ARNOTT	ROAD	\N	ARNOTT ROAD	KILLAWARRA	3678	VIC	RD	\N	CONFIRMED	-36.28992379	146.26166412	4	9	0101000020A41E0000F9BD6E8D5F486240F23006391C2542C0
20679	VIC1951821	loc6ae7eaa3c1f3	BROOK	CRESCENT	\N	BROOK CRESCENT	BOX HILL SOUTH	3128	VIC	CR	\N	CONFIRMED	-37.84318225	145.12234951	4	28	0101000020A41E000036048549EA236240AA285E65EDEB42C0
21381	VIC1952570	loc5c27e3f22fc1	FINDON	STREET	\N	FINDON STREET	HAWTHORN	3122	VIC	ST	\N	CONFIRMED	-37.81369368	145.02008075	4	91	0101000020A41E0000EF906280A4206240EC47501D27E842C0
21668	VIC1952872	loc3832b905a97e	GOLFLINKS	AVENUE	\N	GOLFLINKS AVENUE	WEST WODONGA	3690	VIC	AV	\N	CONFIRMED	-36.12754719	146.84237104	4	68	0101000020A41E0000B87C1CB4F45A624094DF6077531042C0
21725	VIC1952931	loc5c27e3f22fc1	GOODALL	STREET	\N	GOODALL STREET	HAWTHORN	3122	VIC	ST	\N	CONFIRMED	-37.82618559	145.04318305	4	21	0101000020A41E0000BB6F6BC161216240FDBC0C73C0E942C0
21947	VIC1953162	loc67a11408d754	GORDON	STREET	\N	GORDON STREET	FOOTSCRAY	3011	VIC	ST	\N	CONFIRMED	-37.79436537	144.88894294	4	743	0101000020A41E0000ECE97638721C6240CB9CB2C3ADE542C0
22045	VIC1953262	loc31f384e524fe	COVENTRY	STREET	\N	COVENTRY STREET	SOUTHBANK	3006	VIC	ST	\N	CONFIRMED	-37.82958402	144.96799683	4	2098	0101000020A41E00006AEF7CD4F91E6240949725CF2FEA42C0
22143	VIC1953363	loc9fb289b0a33e	COWRA	AVENUE	\N	COWRA AVENUE	IRYMPLE	3498	VIC	AV	\N	CONFIRMED	-34.22310105	142.15624654	4	93	0101000020A41E0000396DBEF8FFC4614004BA40938E1C41C0
22148	VIC1953368	loc3319215a0a10	COWRA	STREET	\N	COWRA STREET	BRIGHTON	3186	VIC	ST	\N	CONFIRMED	-37.90502794	145.00682510	4	77	0101000020A41E000057A945E93720624014229EF4D7F342C0
22362	VIC1953594	locbcb60f6b546d	CRANBOURNE-FRANKSTON	ROAD	\N	CRANBOURNE-FRANKSTON ROAD	LANGWARRIN	3910	VIC	RD	\N	CONFIRMED	-38.14662968	145.20028015	4	563	0101000020A41E000037C9EAB168266240891CE8C2C41243C0
22443	VIC1953679	loc1b5a0e70afd4	DUKE	STREET	\N	DUKE STREET	CAULFIELD SOUTH	3162	VIC	ST	\N	CONFIRMED	-37.89204603	145.01527644	4	46	0101000020A41E0000614604257D20624036B076902EF242C0
22570	VIC1953813	loca4e166a620d9	DUNBLANE	ROAD	\N	DUNBLANE ROAD	NOBLE PARK	3174	VIC	RD	\N	CONFIRMED	-37.96096358	145.18079064	4	332	0101000020A41E000022C77309C9256240A05FC6DA00FB42C0
22717	VIC1953967	loca1efec8fa041	DUNLOE	AVENUE	\N	DUNLOE AVENUE	MONT ALBERT NORTH	3129	VIC	AV	\N	CONFIRMED	-37.80902883	145.11166433	4	109	0101000020A41E00005AAF12C192236240822FB7418EE742C0
23426	VIC1954730	loc06cc48b309e5	GRACE	STREET	\N	GRACE STREET	WATSONIA	3087	VIC	ST	\N	CONFIRMED	-37.71008824	145.08003854	4	42	0101000020A41E000007F7FBAC8F2262407F09E42BE4DA42C0
24267	VIC1955611	loc1e06c486c813	FLEMINGTON	ROAD	\N	FLEMINGTON ROAD	NORTH MELBOURNE	3051	VIC	RD	\N	CONFIRMED	-37.79459235	144.94870305	4	1833	0101000020A41E0000B2AB7FC65B1E62406E73BE33B5E542C0
24363	VIC1955713	loc9901d119afda_1	FLINDERS	STREET	\N	FLINDERS STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81818703	144.96487675	4	4648	0101000020A41E000077BD3445E01E624041EE435ABAE842C0
24380	VIC1955730	locddc4a1bcd8ba	FLINDERS	STREET	\N	FLINDERS STREET	DOCKLANDS	3008	VIC	ST	\N	CONFIRMED	-37.82151689	144.95358518	4	2276	0101000020A41E00009C4111C5831E6240B0D4277727E942C0
24679	VIC1956038	loc74f8893fb76e	GRAHAM	STREET	\N	GRAHAM STREET	BROADMEADOWS	3047	VIC	ST	\N	CONFIRMED	-37.69146174	144.92489570	4	267	0101000020A41E0000C1F6DDBE981D62401DDE7BD181D842C0
24864	VIC1956233	loc4858bcc1d912	GRANDVIEW	STREET	\N	GRANDVIEW STREET	GLENROY	3046	VIC	ST	\N	CONFIRMED	-37.70844674	144.91295884	4	238	0101000020A41E00009C0C75F5361D624000A1FD61AEDA42C0
25807	VIC1957218	loc3319215a0a10	FOOTE	STREET	\N	FOOTE STREET	BRIGHTON	3186	VIC	ST	\N	CONFIRMED	-37.89514631	144.99353550	4	71	0101000020A41E000048FDF50ACB1F6240E44A7F2794F242C0
25942	VIC1957356	loc3832b905a97e	FORDE	COURT	\N	FORDE COURT	WEST WODONGA	3690	VIC	CT	\N	CONFIRMED	-36.13615955	146.86048668	4	26	0101000020A41E0000CCA75C1B895B6240E02417AD6D1142C0
26482	VIC1957930	loc87f2ad0c0fd7	CUBITT	STREET	\N	CUBITT STREET	CREMORNE	3121	VIC	ST	\N	CONFIRMED	-37.82912832	144.99231950	4	202	0101000020A41E0000DCF5D214C11F6240314B75E020EA42C0
26884	VIC1958350	locf51f6cd689bb	EASTERN	ROAD	\N	EASTERN ROAD	SOUTH MELBOURNE	3205	VIC	RD	\N	CONFIRMED	-37.83391347	144.96583314	4	283	0101000020A41E00002DB6E61AE81E624004AC34ADBDEA42C0
27032	VIC1958513	locdd716f1059c5	EBLANA	AVENUE	\N	EBLANA AVENUE	MENTONE	3194	VIC	AV	\N	CONFIRMED	-37.98733388	145.06577641	4	19	0101000020A41E00008C3921D71A226240996AE2F460FE42C0
27957	VIC1959477	loc34a55c4d0462	CURRUNGHI	COURT	\N	CURRUNGHI COURT	ST ALBANS	3021	VIC	CT	\N	CONFIRMED	-37.75305104	144.82585415	4	81	0101000020A41E000082B0AE656D1A62406882FAF963E042C0
28306	VIC1959852	loca1a84d46e52a	EDGARS	ROAD	\N	EDGARS ROAD	EPPING	3076	VIC	RD	\N	CONFIRMED	-37.63945637	145.00598451	4	155	0101000020A41E000071576D0631206240372FD2B4D9D142C0
28473	VIC1960025	loc70eb03d586f8	EDMONDSHAW	DRIVE	\N	EDMONDSHAW DRIVE	DEER PARK	3023	VIC	DR	\N	CONFIRMED	-37.77840121	144.76389573	4	50	0101000020A41E0000EE3C75D571186240F40E9EA6A2E342C0
28867	VIC1960434	loc9901d119afda_1	FRANKLIN	STREET	\N	FRANKLIN STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.80829188	144.95994903	4	4907	0101000020A41E0000A93507E7B71E6240761CBB1B76E742C0
29369	VIC1960955	locf51f6cd689bb	CITY	ROAD	\N	CITY ROAD	SOUTH MELBOURNE	3205	VIC	RD	\N	CONFIRMED	-37.83249117	144.95238848	4	138	0101000020A41E0000FDD567F7791E6240ECAD16128FEA42C0
29477	VIC1961067	loc5900b8cc74c8	DALE	DRIVE	\N	DALE DRIVE	LEONGATHA	3953	VIC	DR	\N	CONFIRMED	-38.47143494	145.93584980	4	53	0101000020A41E0000FB9E477BF23D6240F1BEE8FA573C43C0
29495	VIC1961086	loc1f73672977ce	DALES	ROAD	\N	DALES ROAD	WARRNAMBOOL	3280	VIC	RD	\N	CONFIRMED	-38.37767930	142.53416587	4	38	0101000020A41E000043C905E317D1614026F098CB573043C0
29764	VIC1961369	loc22c42e389de3	DANAHER	DRIVE	\N	DANAHER DRIVE	SOUTH MORANG	3752	VIC	DR	\N	CONFIRMED	-37.64859516	145.08471608	4	203	0101000020A41E000073217FFEB52262409E458C2A05D342C0
29776	VIC1961381	loc6413994c2b24	DANDENONG	ROAD	EAST	DANDENONG ROAD EAST	FRANKSTON	3199	VIC	RD	E	CONFIRMED	-38.13521089	145.12970688	4	178	0101000020A41E000051F50A8F26246240794E27974E1143C0
29780	VIC1961385	loc2d817b7080e2	DANDENONG	ROAD	\N	DANDENONG ROAD	MALVERN EAST	3145	VIC	RD	\N	CONFIRMED	-37.88447479	145.06280375	4	2541	0101000020A41E00001E8A027D02226240DE974C7836F142C0
29855	VIC1961465	loc12cc6354a4ba	EICKERTS	LANE	\N	EICKERTS LANE	MOUNT CAMEL	3523	VIC	LANE	\N	CONFIRMED	-36.76209168	144.77072314	4	7	0101000020A41E0000411293C3A9186240AC135D388C6142C0
30371	VIC1962002	loc31f384e524fe	FRESHWATER	PLACE	\N	FRESHWATER PLACE	SOUTHBANK	3006	VIC	PL	\N	CONFIRMED	-37.82196276	144.96246287	4	925	0101000020A41E000075C8EE7ECC1E62406D5D621336E942C0
30554	VIC1962198	loccb9bfb1fb49a	CIVIC	SQUARE	\N	CIVIC SQUARE	CROYDON	3136	VIC	SQ	\N	CONFIRMED	-37.80041997	145.28220894	4	37	0101000020A41E00000BFE0ADB072962408F1B5D2974E642C0
30715	VIC1962365	loc31f384e524fe	CLARENDON	STREET	\N	CLARENDON STREET	SOUTHBANK	3006	VIC	ST	\N	CONFIRMED	-37.82645398	144.95756471	4	1784	0101000020A41E00001F28BF5EA41E6240E0DF773EC9E942C0
30756	VIC1962407	loc39cd317eec9d	CLARINDA	ROAD	\N	CLARINDA ROAD	CLARINDA	3169	VIC	RD	\N	CONFIRMED	-37.93548363	145.09893941	4	158	0101000020A41E00008A47FB822A2362408D6576EDBDF742C0
31176	VIC1962844	loc17a18f5ff3a6	DARLEITH	TERRACE	\N	DARLEITH TERRACE	CAROLINE SPRINGS	3023	VIC	TCE	\N	CONFIRMED	-37.71875089	144.73447299	4	15	0101000020A41E00000DFB7FCD80176240AD42770700DC42C0
31304	VIC1962976	locfd8472c41cbe	ELIZABETH	COURT	\N	ELIZABETH COURT	ROWVILLE	3178	VIC	CT	\N	CONFIRMED	-37.91908407	145.23154189	4	25	0101000020A41E000087A689CA682762405876FB8BA4F542C0
31316	VIC1962988	locc81a6ec90a1b	ELIZABETH	DRIVE	\N	ELIZABETH DRIVE	ROSEBUD	3939	VIC	DR	\N	CONFIRMED	-38.37301278	144.92040659	4	94	0101000020A41E0000556285F8731D6240878BFDE1BE2F43C0
31340	VIC1963013	loc9901d119afda_1	ELIZABETH	STREET	\N	ELIZABETH STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.80899776	144.96076269	4	7066	0101000020A41E00008B986591BE1E62405EDE143D8DE742C0
31440	VIC1963115	locffd0eebac0eb	ELLA	GROVE	\N	ELLA GROVE	CHELSEA	3196	VIC	GR	\N	CONFIRMED	-38.04276677	145.12250579	4	250	0101000020A41E0000DC334391EB236240B640AB61790543C0
31461	VIC1963136	loc8f498b475ec6	ELLAVALE	DRIVE	\N	ELLAVALE DRIVE	TRARALGON EAST	3844	VIC	DR	\N	CONFIRMED	-38.19628618	146.56966384	4	116	0101000020A41E00007150A9AF3A526240DEE0D1E71F1943C0
31680	VIC1963362	loc6c0f29d040f7	FULHAM	ROAD	\N	FULHAM ROAD	TORRUMBARRY	3562	VIC	RD	\N	CONFIRMED	-36.01878747	144.54531318	4	7	0101000020A41E0000B045A03473116240BF9CB8A0670242C0
33329	VIC1965101	loce3f8de63f06a	GARDEN	CLOSE	\N	GARDEN CLOSE	KINGSBURY	3083	VIC	CL	\N	CONFIRMED	-37.71423300	145.02844791	4	23	0101000020A41E0000DE62970BE9206240AB5CA8FC6BDB42C0
33409	VIC1965184	loc4195fdfecc8e	GARDENIA	ROAD	\N	GARDENIA ROAD	GARDENVALE	3185	VIC	RD	\N	CONFIRMED	-37.89816721	145.00886771	4	114	0101000020A41E0000188EEFA44820624010A5A424F7F242C0
34440	VIC1966266	loc0b665c0fe535	ENDEAVOUR	DRIVE	\N	ENDEAVOUR DRIVE	OCEAN GROVE	3226	VIC	DR	\N	CONFIRMED	-38.26307662	144.55354881	4	90	0101000020A41E00001276FEABB6116240019FA37EAC2143C0
35512	VIC1967421	loc9901d119afda_1	DEGRAVES	STREET	\N	DEGRAVES STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81736459	144.96581316	4	183	0101000020A41E0000E30700F1E71E6240AE7A23679FE842C0
36447	VIC1968404	loc74f8893fb76e	GERBERT	STREET	\N	GERBERT STREET	BROADMEADOWS	3047	VIC	ST	\N	CONFIRMED	-37.68749448	144.93018873	4	114	0101000020A41E0000A6CE271BC41D6240E8E3B1D1FFD742C0
37438	VIC1969439	loc9b20cd160517	EVANS	STREET	\N	EVANS STREET	CHADSTONE	3148	VIC	ST	\N	CONFIRMED	-37.88325772	145.09752853	4	45	0101000020A41E0000DDD826F41E23624076ABC6960EF142C0
37667	VIC1969682	locf3eb6fff8056	GIBB	STREET	\N	GIBB STREET	OXLEY	3678	VIC	ST	\N	CONFIRMED	-36.43952844	146.38823671	4	3	0101000020A41E0000D091646F6C4C62401FBBC977423842C0
37702	VIC1969720	loc610e6e8cd167	GIBBS	ROAD	\N	GIBBS ROAD	YARRA GLEN	3775	VIC	RD	\N	CONFIRMED	-37.63549404	145.37837938	4	15	0101000020A41E000096D212AF1B2C62402C4D63DE57D142C0
37851	VIC1969874	loc201e214973bd	GILBERT	ROAD	\N	GILBERT ROAD	IVANHOE	3079	VIC	RD	\N	CONFIRMED	-37.77337107	145.04798314	4	25	0101000020A41E0000E721F0138921624049A9BED2FDE242C0
37858	VIC1969882	loc2c9ce0acd6de	GILBERT	STREET	\N	GILBERT STREET	ST LEONARDS	3223	VIC	ST	\N	CONFIRMED	-38.18336313	144.71060746	4	58	0101000020A41E0000CC1FDB4BBD16624033526B71781743C0
37989	VIC1970018	loc9901d119afda_1	COLLINS	STREET	\N	COLLINS STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81623506	144.96396742	4	10337	0101000020A41E0000E7E933D2D81E62403846F4637AE842C0
38162	VIC1970192	loc82b861dfb765	COMAS	GROVE	\N	COMAS GROVE	THORNBURY	3071	VIC	GR	\N	CONFIRMED	-37.75428279	144.98499234	4	77	0101000020A41E000089E3A70E851F6240297EA5568CE042C0
38277	VIC1970315	loc3b64e6146ff8	COMO	PARADE	WEST	COMO PARADE WEST	MORDIALLOC	3195	VIC	PDE	W	CONFIRMED	-38.00009786	145.08268170	4	62	0101000020A41E000049AF1754A5226240F2BFE834030043C0
38697	VIC1970763	loc0de2086617a5	DIFFEY	ROAD	\N	DIFFEY ROAD	EVERTON	3678	VIC	RD	\N	CONFIRMED	-36.42068667	146.57888840	4	20	0101000020A41E00001541F74086526240AFC1900FD93542C0
39160	VIC1971247	locb281644d861d	GILMORE	COURT	\N	GILMORE COURT	BELGRAVE SOUTH	3160	VIC	CT	\N	CONFIRMED	-37.93126745	145.35775712	4	16	0101000020A41E0000F5490FBF722B624027CA94C533F742C0
39502	VIC1971604	loc74f8893fb76e	CONGRAM	STREET	\N	CONGRAM STREET	BROADMEADOWS	3047	VIC	ST	\N	CONFIRMED	-37.68867052	144.93275260	4	59	0101000020A41E00004908FB1BD91D6240468F085B26D842C0
39899	VIC1972025	loc94fdc21035b3	DILLON	STREET	\N	DILLON STREET	ULTIMA	3544	VIC	ST	\N	CONFIRMED	-35.47348925	143.26791641	4	60	0101000020A41E000060606FC592E86140F8E0B54B9BBC41C0
41647	VIC1973863	loc3b6fd5dcd874	DONALDA	AVENUE	\N	DONALDA AVENUE	SORRENTO	3943	VIC	AV	\N	CONFIRMED	-38.33827228	144.73381403	4	22	0101000020A41E000045868F677B17624026DF8D814C2B43C0
42079	VIC1974317	loc5c27e3f22fc1	GLENFERRIE	ROAD	\N	GLENFERRIE ROAD	HAWTHORN	3122	VIC	RD	\N	CONFIRMED	-37.82600335	145.03472500	4	1676	0101000020A41E0000516B9A771C21624077514F7ABAE942C0
42949	VIC1975240	loc913bf4728c4e	DOONKUNA	AVENUE	\N	DOONKUNA AVENUE	CAMBERWELL	3124	VIC	AV	\N	CONFIRMED	-37.83798447	145.07592310	4	57	0101000020A41E00005AF047F66D2262405B9A3A1343EB42C0
43269	VIC1975583	loc5e975e2e1c0e	FERNLEA	CLOSE	\N	FERNLEA CLOSE	TRAFALGAR	3824	VIC	CL	\N	CONFIRMED	-38.21878693	146.15706321	4	29	0101000020A41E00005ACB6CA9064562403592CA35011C43C0
43317	VIC1975631	loccd13bd88b567	FERNTREE GULLY	ROAD	\N	FERNTREE GULLY ROAD	FERNTREE GULLY	3156	VIC	RD	\N	CONFIRMED	-37.88616189	145.26663722	4	337	0101000020A41E00007C79C74A882862407A41B8C06DF142C0
43679	VIC1976022	locc70453923b8e	GOLDEN	AVENUE	\N	GOLDEN AVENUE	BONBEACH	3196	VIC	AV	\N	CONFIRMED	-38.05710675	145.12290498	4	186	0101000020A41E0000B2B36CD6EE236240C0D023464F0743C0
43708	VIC1976052	locc67851215f08	GOLDEN ASH	COURT	\N	GOLDEN ASH COURT	MEADOW HEIGHTS	3048	VIC	CT	\N	CONFIRMED	-37.64980032	144.92495078	4	26	0101000020A41E00004FD06032991D624048AA29A82CD342C0
43892	VIC1976256	loc9901d119afda_1	CORRS	LANE	\N	CORRS LANE	MELBOURNE	3000	VIC	LANE	\N	CONFIRMED	-37.81108035	144.96825133	4	20	0101000020A41E0000129536EAFB1E6240D0D61C7BD1E742C0
44309	VIC1976701	loc1eda86883ae9	DOVER	STREET	\N	DOVER STREET	SUNDERLAND BAY	3922	VIC	ST	\N	CONFIRMED	-38.50607544	145.27699165	4	35	0101000020A41E00007CC0971DDD286240ED0D7C14C74043C0
44428	VIC1976825	loceac5d85ea01d	DOWNHAM	WAY	\N	DOWNHAM WAY	WYNDHAM VALE	3024	VIC	WAY	\N	CONFIRMED	-37.89690297	144.61958665	4	23	0101000020A41E000039D961A7D3136240EAEA6DB7CDF242C0
44539	VIC1976942	loc0b6e17218dd4	DRAPER	STREET	\N	DRAPER STREET	ORMOND	3204	VIC	ST	\N	CONFIRMED	-37.90741795	145.05052201	4	63	0101000020A41E0000B49555E09D216240D586794526F442C0
44927	VIC1977358	locc81a6ec90a1b	JETTY	ROAD	\N	JETTY ROAD	ROSEBUD	3939	VIC	RD	\N	CONFIRMED	-38.37012915	144.90879168	4	481	0101000020A41E0000430F4AD2141D6240EC455964602F43C0
45726	VIC1978203	locfd8472c41cbe	HENDERSON	ROAD	\N	HENDERSON ROAD	ROWVILLE	3178	VIC	RD	\N	CONFIRMED	-37.90754315	145.24241482	4	60	0101000020A41E0000E77EB9DCC1276240BB7ABA5F2AF442C0
45957	VIC1978444	loc7ab22202aac3	HENRY	STREET	\N	HENRY STREET	DONCASTER	3108	VIC	ST	\N	CONFIRMED	-37.77518980	145.12892142	4	85	0101000020A41E0000ED54D01F20246240AD985B6B39E342C0
46044	VIC1978531	loc82baa1179308	HENTY	STREET	\N	HENTY STREET	PAKENHAM	3810	VIC	ST	\N	CONFIRMED	-38.07939104	145.47913058	4	114	0101000020A41E0000A273A709552F62409D32507C290A43C0
46340	VIC1978845	loc08caad3924ee	JOHN	STREET	\N	JOHN STREET	ALTONA NORTH	3025	VIC	ST	\N	CONFIRMED	-37.83176536	144.83673198	4	64	0101000020A41E0000C1332582C61A6240A5928D4977EA42C0
46713	VIC1979239	locf066999b6a14	LARA	COURT	\N	LARA COURT	HALLAM	3803	VIC	CT	\N	CONFIRMED	-37.99687452	145.26081005	4	16	0101000020A41E0000FB66518E58286240CFCE929599FF42C0
46832	VIC1979366	loc15a8d395ef61	MAIN	STREET	\N	MAIN STREET	NAR NAR GOON	3812	VIC	ST	\N	CONFIRMED	-38.08640725	145.56915942	4	84	0101000020A41E000088E3D08D3632624093718C640F0B43C0
47114	VIC1979663	loce36428dd6505	MALDON-NEWSTEAD	ROAD	\N	MALDON-NEWSTEAD ROAD	WELSHMANS REEF	3462	VIC	RD	\N	CONFIRMED	-37.06504795	144.04554759	4	58	0101000020A41E0000C62E382075016240FFF5C07D538842C0
47196	VIC1979753	loca307cf61ba97	HERALD	WALK	\N	HERALD WALK	KINGS PARK	3021	VIC	WALK	\N	CONFIRMED	-37.73537549	144.76371164	4	12	0101000020A41E0000FCAB6453701862403DEAB7C820DE42C0
48120	VIC1980714	locd6f79866f950	LAURA	ROAD	\N	LAURA ROAD	KNOXFIELD	3180	VIC	RD	\N	CONFIRMED	-37.89150890	145.24395880	4	77	0101000020A41E00004972AF82CE276240E5CBB0F61CF242C0
48385	VIC1980990	locb17fb225139f	MALTRAVERS	ROAD	\N	MALTRAVERS ROAD	IVANHOE EAST	3079	VIC	RD	\N	CONFIRMED	-37.76919399	145.05772688	4	99	0101000020A41E000067B60AE6D821624035AADBF274E242C0
48401	VIC1981006	locadc5cabaa80e	MALVERN	ROAD	\N	MALVERN ROAD	GLEN IRIS	3146	VIC	RD	\N	CONFIRMED	-37.85422685	145.05056316	4	1456	0101000020A41E0000A3D2A1369E216240BC0E304E57ED42C0
48869	VIC1981503	loce01ddbd8c8e5	HIGH	STREET	\N	HIGH STREET	NAGAMBIE	3608	VIC	ST	\N	CONFIRMED	-36.78753587	145.15269413	4	609	0101000020A41E000084D4CCDEE2246240D809B3F9CD6442C0
48873	VIC1981507	locbb6ca08c118e	HIGH	STREET	\N	HIGH STREET	NORTHCOTE	3070	VIC	ST	\N	CONFIRMED	-37.77353585	144.99815934	4	1464	0101000020A41E0000E72FDBEBF01F62404C04053903E342C0
48881	VIC1981515	loc2c4c767ea9b7	HIGH	STREET	\N	HIGH STREET	PRESTON	3072	VIC	ST	\N	CONFIRMED	-37.74113122	145.00354749	4	1871	0101000020A41E00000D31A00F1D206240E8F84763DDDE42C0
49292	VIC1981938	locc84be248155b	JULIET	CRESCENT	\N	JULIET CRESCENT	HEALESVILLE	3777	VIC	CR	\N	CONFIRMED	-37.64931699	145.53633083	4	23	0101000020A41E0000F8D5459F29316240C264B2D11CD342C0
50323	VIC1983036	loc36422efcb9c0	HILL	STREET	\N	HILL STREET	CLIFTON SPRINGS	3222	VIC	ST	\N	CONFIRMED	-38.16296714	144.55741942	4	65	0101000020A41E0000C5614061D6116240B34F741BDC1443C0
50358	VIC1983076	loc630ef4fec09d	HILL VIEW	RISE	\N	HILL VIEW RISE	GISBORNE SOUTH	3437	VIC	RISE	\N	CONFIRMED	-37.54981987	144.63810005	4	7	0101000020A41E00006ECACB506B146240A52B5C7F60C642C0
50707	VIC1983442	loc695c9ddc8068	KALYMNA	GROVE	\N	KALYMNA GROVE	ST KILDA EAST	3183	VIC	GR	\N	CONFIRMED	-37.86615143	145.00531062	4	46	0101000020A41E000016672D812B206240E89DD00CDEEE42C0
51504	VIC1984283	loc5100fc96abff	GREEN ISLAND	AVENUE	\N	GREEN ISLAND AVENUE	MOUNT MARTHA	3934	VIC	AV	\N	CONFIRMED	-38.24730247	145.04134214	4	247	0101000020A41E0000E567C0AC522162405D6F7A9BA71F43C0
51565	VIC1984350	loc8e5a2b16aaaa	GREENFIELD	DRIVE	\N	GREENFIELD DRIVE	TRARALGON	3844	VIC	DR	\N	CONFIRMED	-38.18165091	146.54489064	4	65	0101000020A41E00004AD67EBE6F5162408CDE4656401743C0
52036	VIC1984845	locf16910f90fb9	KAREN	STREET	\N	KAREN STREET	HIGHETT	3190	VIC	ST	\N	CONFIRMED	-37.95737529	145.05408546	4	44	0101000020A41E0000743C6E11BB216240364604468BFA42C0
52314	VIC1985134	loc31f384e524fe	KAVANAGH	STREET	\N	KAVANAGH STREET	SOUTHBANK	3006	VIC	ST	\N	CONFIRMED	-37.82422317	144.96415521	4	6282	0101000020A41E0000FAE6065CDA1E6240B3E0132580E942C0
52924	VIC1985787	loc38cbe92d1159	GREEVES	DRIVE	\N	GREEVES DRIVE	KILSYTH	3137	VIC	DR	\N	CONFIRMED	-37.80753321	145.30863862	4	204	0101000020A41E0000D865195EE029624024B18B3F5DE742C0
52965	VIC1985830	loc51ba976fe589	GREGORY	STREET	\N	GREGORY STREET	OAK PARK	3046	VIC	ST	\N	CONFIRMED	-37.72222003	144.91575461	4	96	0101000020A41E00008FA39CDC4D1D6240DEAEB8B471DC42C0
53116	VIC1985993	locfe955a87410d	GREY	STREET	\N	GREY STREET	ST KILDA	3182	VIC	ST	\N	CONFIRMED	-37.86193963	144.97955322	4	637	0101000020A41E0000EE92FE7F581F6240F9FCAC0954EE42C0
53608	VIC1986516	loc025dead673cc	KEILLER	AVENUE	\N	KEILLER AVENUE	PARKDALE	3195	VIC	AV	\N	CONFIRMED	-37.98648131	145.09153598	4	51	0101000020A41E00003C10DDDCED2262405A48020545FE42C0
55445	VIC1988452	loce42a110faa48	LINACRE	ROAD	\N	LINACRE ROAD	HAMPTON	3188	VIC	RD	\N	CONFIRMED	-37.94320263	145.01135934	4	366	0101000020A41E0000BC39430E5D206240F4AC20DDBAF842C0
55471	VIC1988479	loca56f2b16461e	LINCOLN	DRIVE	\N	LINCOLN DRIVE	BULLEEN	3105	VIC	DR	\N	CONFIRMED	-37.77091349	145.09506115	4	87	0101000020A41E0000D84BAEBD0A23624030CC114BADE242C0
56292	VIC1989339	loca1a84d46e52a	HORSESHOE	CRESCENT	\N	HORSESHOE CRESCENT	EPPING	3076	VIC	CR	\N	CONFIRMED	-37.64063842	145.05306818	4	55	0101000020A41E0000DD310ABCB2216240063B937000D242C0
56419	VIC1989474	loc67d2e4d427ab	HOTHAM	ROAD	\N	HOTHAM ROAD	PORTSEA	3944	VIC	RD	\N	CONFIRMED	-38.33167909	144.71742595	4	42	0101000020A41E0000A8114427F51662409528DE75742A43C0
57153	VIC1990231	loc9901d119afda_1	LITTLE COLLINS	STREET	\N	LITTLE COLLINS STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81521669	144.96360864	4	3578	0101000020A41E00002D5EC9E1D51E6240085A3F0559E842C0
57221	VIC1990305	loc9901d119afda_1	LITTLE LONSDALE	STREET	\N	LITTLE LONSDALE STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81129102	144.96179691	4	9680	0101000020A41E0000013B500AC71E624020385762D8E742C0
57308	VIC1990396	loc31f384e524fe	HAIG	STREET	\N	HAIG STREET	SOUTHBANK	3006	VIC	ST	\N	CONFIRMED	-37.82729540	144.95685395	4	1862	0101000020A41E00008DC92C8C9E1E6240CC90CFD0E4E942C0
57342	VIC1990433	loc1e06c486c813	HAINES	STREET	\N	HAINES STREET	NORTH MELBOURNE	3051	VIC	ST	\N	CONFIRMED	-37.79847810	144.94664020	4	849	0101000020A41E0000868263E04A1E62403E09C78734E642C0
59036	VIC1992219	loce42a110faa48	HAMPTON	STREET	\N	HAMPTON STREET	HAMPTON	3188	VIC	ST	\N	CONFIRMED	-37.93673059	145.00265298	4	1080	0101000020A41E0000C8CAB3BB152062403D9BB8C9E6F742C0
59248	VIC1992446	loc46f8f01fbac9	HUME	STREET	\N	HUME STREET	RINGWOOD EAST	3135	VIC	ST	\N	CONFIRMED	-37.82342307	145.25918844	4	69	0101000020A41E0000A4298E454B28624001365AED65E942C0
59536	VIC1992749	loc9901d119afda_1	KING	STREET	\N	KING STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81630905	144.95570434	4	1787	0101000020A41E0000409E4421951E6240E496A0D07CE842C0
59578	VIC1992791	loc406d1f7b5fe3	KING	STREET	\N	KING STREET	TEMPLESTOWE	3106	VIC	ST	\N	CONFIRMED	-37.77343390	145.14978312	4	177	0101000020A41E0000923CF805CB246240120FCDE1FFE242C0
60416	VIC1993696	locddc4a1bcd8ba	HARBOUR	ESPLANADE	\N	HARBOUR ESPLANADE	DOCKLANDS	3008	VIC	ESP	\N	CONFIRMED	-37.81727940	144.94596299	4	2495	0101000020A41E0000D8282D54451E6240E558839C9CE842C0
60927	VIC1994235	loc3d949ab3c987	KINGSTON	ROAD	\N	KINGSTON ROAD	HEATHERTON	3202	VIC	RD	\N	CONFIRMED	-37.95470578	145.09005213	4	173	0101000020A41E0000202901B5E12262407A338BCC33FA42C0
61084	VIC1994400	loc913bf4728c4e	KINTORE	STREET	\N	KINTORE STREET	CAMBERWELL	3124	VIC	ST	\N	CONFIRMED	-37.82270152	145.06060193	4	37	0101000020A41E0000956D7573F02162407F628D484EE942C0
61505	VIC1994837	loc9901d119afda_1	LONSDALE	STREET	\N	LONSDALE STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81224364	144.96234814	4	11277	0101000020A41E00005395538ECB1E62408D177F99F7E742C0
61857	VIC1995210	loc4a341f4d3e02	HAROLD	STREET	\N	HAROLD STREET	WANTIRNA	3152	VIC	ST	\N	CONFIRMED	-37.85776772	145.23060579	4	409	0101000020A41E00002FCA641F61276240747B2855CBED42C0
63725	VIC1997189	locdf0288b649a4	IONA	COURT	\N	IONA COURT	WODONGA	3690	VIC	CT	\N	CONFIRMED	-36.12570886	146.89507552	4	9	0101000020A41E000035BB6A75A45C62403C42593A171042C0
64368	VIC1997861	loc656f84726510	LUCILLE	AVENUE	\N	LUCILLE AVENUE	RESERVOIR	3073	VIC	AV	\N	CONFIRMED	-37.70000715	145.02197567	4	34	0101000020A41E0000A5FE5106B4206240AB1B94D599D942C0
64597	VIC1998102	loc79e45c9fa669	LYGON	STREET	\N	LYGON STREET	BRUNSWICK EAST	3057	VIC	ST	\N	CONFIRMED	-37.77061896	144.97185753	4	2382	0101000020A41E00001577F674191F624053705FA4A3E242C0
64998	VIC1998523	loca5de38b84720	IRVING	AVENUE	\N	IRVING AVENUE	BOX HILL	3128	VIC	AV	\N	CONFIRMED	-37.81588278	145.12241145	4	393	0101000020A41E0000FDCC6ACBEA2362401BBCD0D86EE842C0
65517	VIC1999075	loc9901d119afda_1	LA TROBE	STREET	\N	LA TROBE STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81041122	144.96099693	4	7454	0101000020A41E0000013DA27CC01E6240111B0B8EBBE742C0
65600	VIC1999163	loc46443686a430	LACHLAN	ROAD	\N	LACHLAN ROAD	SUNSHINE WEST	3020	VIC	RD	\N	CONFIRMED	-37.79257933	144.81386957	4	92	0101000020A41E0000824B32380B1A6240F5EA4E3D73E542C0
66057	VIC1999638	loc1c5f2c23fc52	MACADAM	STREET	\N	MACADAM STREET	TOWONG	3707	VIC	ST	\N	CONFIRMED	-36.12645326	147.98920079	4	6	0101000020A41E000047476A88A77F62401716D49E2F1042C0
66225	VIC1999814	loc8e5a2b16aaaa	HAZELWOOD	ROAD	\N	HAZELWOOD ROAD	TRARALGON	3844	VIC	RD	\N	CONFIRMED	-38.22909051	146.51781373	4	228	0101000020A41E0000A27819EE9150624011237CD6521D43C0
66267	VIC1999859	loc6c0f29d040f7	HEADWORKS	ROAD	\N	HEADWORKS ROAD	TORRUMBARRY	3562	VIC	RD	\N	CONFIRMED	-35.97951931	144.48423475	4	33	0101000020A41E0000C7DADFD97E0F6240102085E360FD41C0
66975	VIC2000595	loc70eb03d586f8	LAKE BOGA	AVENUE	\N	LAKE BOGA AVENUE	DEER PARK	3023	VIC	AV	\N	CONFIRMED	-37.76854495	144.76052331	4	95	0101000020A41E00007609FB3456186240C3E050AE5FE242C0
67909	VIC2001577	loc0621c45c46f4	HELSTON	STREET	\N	HELSTON STREET	BALWYN NORTH	3104	VIC	ST	\N	CONFIRMED	-37.78545497	145.09410504	4	51	0101000020A41E00000AA692E802236240BA50D8C989E442C0
68846	VIC2002547	locd6190ebbe554	PARALLEL	STREET	\N	PARALLEL STREET	FALLS CREEK	3699	VIC	ST	\N	CONFIRMED	-36.86567600	147.28052865	4	60	0101000020A41E0000EA2A3817FA6862404F779E78CE6E42C0
69042	VIC2002748	loc3b6fd5dcd874	PARK	ROAD	\N	PARK ROAD	SORRENTO	3943	VIC	RD	\N	CONFIRMED	-38.34441728	144.73601128	4	48	0101000020A41E0000CA2287678D1762407EE38CDD152C43C0
69392	VIC2003128	loc92bf5bc798e7	RACECOURSE	ROAD	\N	RACECOURSE ROAD	FLEMINGTON	3031	VIC	RD	\N	CONFIRMED	-37.78818242	144.92983343	4	659	0101000020A41E00007B920932C11D624050975A29E3E442C0
69980	VIC2003761	loc8c9f2867857c	NELSON	PLACE	\N	NELSON PLACE	WILLIAMSTOWN	3016	VIC	PL	\N	CONFIRMED	-37.86348194	144.90569063	4	428	0101000020A41E00009984EA6AFB1C62404A7E829386EE42C0
70074	VIC2003856	loccbfe7d3f7b9f	NEPEAN	HIGHWAY	\N	NEPEAN HIGHWAY	ELSTERNWICK	3185	VIC	HWY	\N	CONFIRMED	-37.88962058	145.00157962	4	196	0101000020A41E0000AF07B4F00C2062406A795016DFF142C0
70430	VIC2004239	loc819a06b032e3	PARKLEA	WAY	\N	PARKLEA WAY	TARNEIT	3029	VIC	WAY	\N	CONFIRMED	-37.83979536	144.69299454	4	32	0101000020A41E000069B3E2022D1662402A44136A7EEB42C0
71079	VIC2004921	loc786911d8fa57	MIDDLEFIELD	DRIVE	\N	MIDDLEFIELD DRIVE	BLACKBURN NORTH	3130	VIC	DR	\N	CONFIRMED	-37.80169959	145.15200235	4	59	0101000020A41E000049450834DD246240202298179EE642C0
71106	VIC2004950	locf16910f90fb9	MIDDLETON	STREET	\N	MIDDLETON STREET	HIGHETT	3190	VIC	ST	\N	CONFIRMED	-37.95201470	145.03904270	4	120	0101000020A41E0000B9F479D63F216240D7E7209EDBF942C0
71393	VIC2005249	loc3319215a0a10	NEW	STREET	\N	NEW STREET	BRIGHTON	3186	VIC	ST	\N	CONFIRMED	-37.90769781	144.99253448	4	1099	0101000020A41E00001378ABD7C21F6240E84C1C712FF442C0
72309	VIC2006220	loca0398a35cf5e	RATHDOWNE	STREET	\N	RATHDOWNE STREET	CARLTON	3053	VIC	ST	\N	CONFIRMED	-37.79982051	144.97009681	4	1728	0101000020A41E0000ED1C77080B1F62405E8FBA8460E642C0
72634	VIC2006569	loc0b8afd71fce1	MILLER	STREET	\N	MILLER STREET	WEST MELBOURNE	3003	VIC	ST	\N	CONFIRMED	-37.80554196	144.94434226	4	85	0101000020A41E0000C95D420D381E6240BCE0BAFF1BE742C0
72961	VIC2006911	locb9872f35df41	NICHOLSON	STREET	\N	NICHOLSON STREET	ABBOTSFORD	3067	VIC	ST	\N	CONFIRMED	-37.80517306	144.99676489	4	440	0101000020A41E00003C8B7B7FE51F6240FE282CE90FE742C0
73183	VIC2007148	locb0a9c63101c7	PAUL	COURT	\N	PAUL COURT	YARRAWONGA	3730	VIC	CT	\N	CONFIRMED	-36.00810602	146.01885243	4	16	0101000020A41E00009B4969709A4062407E66399E090142C0
73440	VIC2007417	locb344fc28a060	PEARCEDALE	ROAD	\N	PEARCEDALE ROAD	PEARCEDALE	3912	VIC	RD	\N	CONFIRMED	-38.19585504	145.23645349	4	174	0101000020A41E000067D2E8069127624044C727C7111943C0
73470	VIC2007449	locddc4a1bcd8ba	PEARL RIVER	ROAD	\N	PEARL RIVER ROAD	DOCKLANDS	3008	VIC	RD	\N	CONFIRMED	-37.81301112	144.93663282	4	1090	0101000020A41E0000544864E5F81D624098D795BF10E842C0
73495	VIC2007474	locc586266ef8cc	PEARSON	STREET	\N	PEARSON STREET	SALE	3850	VIC	ST	\N	CONFIRMED	-38.10469328	147.06246242	4	133	0101000020A41E0000216430B1FF61624001DBE296660D43C0
73620	VIC2007606	loc0a8087d68433	MAPLE	AVENUE	\N	MAPLE AVENUE	KOORLONG	3501	VIC	AV	\N	CONFIRMED	-34.24245637	142.03645944	4	23	0101000020A41E0000C6CDFCAC2AC16140AEED71CF081F41C0
74719	VIC2008804	loceb6884033cea	PEERS	LANE	\N	PEERS LANE	DURHAM LEAD	3352	VIC	LANE	\N	CONFIRMED	-37.69871999	143.88496651	4	5	0101000020A41E00002B5049A551FC6140440E19A86FD942C0
75216	VIC2009322	loc29a798d6921b	MARKET	ROAD	\N	MARKET ROAD	WERRIBEE	3030	VIC	RD	\N	CONFIRMED	-37.89435342	144.65737674	4	209	0101000020A41E00006FEEF13A091562409EFB402C7AF242C0
75822	VIC2009968	loc7a8164839d54	NORMAN	STREET	\N	NORMAN STREET	DONCASTER EAST	3109	VIC	ST	\N	CONFIRMED	-37.78614206	145.14741237	4	36	0101000020A41E0000A185259AB7246240E4DA924DA0E442C0
75919	VIC2010068	loc1492a23dbc74	NORTH	CRESCENT	\N	NORTH CRESCENT	HEIDELBERG WEST	3081	VIC	CR	\N	CONFIRMED	-37.73965609	145.04511874	4	59	0101000020A41E00009317DB9C712162402A6BFE0CADDE42C0
76864	VIC2011064	loca2fd80ef71d3	MOFFATS	ROAD	\N	MOFFATS ROAD	DEREEL	3352	VIC	RD	\N	CONFIRMED	-37.83818865	143.79027957	4	29	0101000020A41E00001A7B61F849F961406FD003C449EB42C0
78252	VIC2012550	loc2424df148d7d	MONBULK-SEVILLE	ROAD	\N	MONBULK-SEVILLE ROAD	WANDIN EAST	3139	VIC	RD	\N	CONFIRMED	-37.82068686	145.45813222	4	32	0101000020A41E00009BC4E604A92E62407DFA5B440CE942C0
78709	VIC2013030	loc46b3ff1e6b9a	NURLENDI	ROAD	\N	NURLENDI ROAD	VERMONT	3133	VIC	RD	\N	CONFIRMED	-37.84091111	145.19299096	4	97	0101000020A41E0000F5B360FB2C2662408325AAF9A2EB42C0
79146	VIC2013487	locf4e180745c81	PIER	STREET	\N	PIER STREET	DROMANA	3936	VIC	ST	\N	CONFIRMED	-38.33487854	144.96724812	4	135	0101000020A41E00008F5054B2F31E624053B7CC4CDD2A43C0
79642	VIC2014019	locdf0288b649a4	MAXWELL	DRIVE	\N	MAXWELL DRIVE	WODONGA	3690	VIC	DR	\N	CONFIRMED	-36.13093553	146.90571182	4	26	0101000020A41E000005D05A97FB5C6240029ED57EC21042C0
79861	VIC2014245	loc712bc92c5924	MOONSTONE	WALK	\N	MOONSTONE WALK	BUNDOORA	3083	VIC	WALK	\N	CONFIRMED	-37.71357322	145.05625927	4	16	0101000020A41E0000E6973DE0CC216240C899055E56DB42C0
79867	VIC2014251	loc86cf2bd4847b	MOONYA	ROAD	\N	MOONYA ROAD	CARNEGIE	3163	VIC	RD	\N	CONFIRMED	-37.89685459	145.06024839	4	522	0101000020A41E0000F915088EED216240A3A89621CCF242C0
80851	VIC2015298	loc3832b905a97e	MAYFAIR	DRIVE	\N	MAYFAIR DRIVE	WEST WODONGA	3690	VIC	DR	\N	CONFIRMED	-36.11678334	146.86045947	4	162	0101000020A41E0000DF654CE2885B62404202A9C1F20E42C0
81095	VIC2015559	loc0e534d470df9	MCCARTHY	DRIVE	\N	MCCARTHY DRIVE	HEATHCOTE	3523	VIC	DR	\N	CONFIRMED	-36.95556660	144.78260095	4	24	0101000020A41E000031C225110B1962403013A001507A42C0
81160	VIC2015632	loc679429866800	MCCLURES	LANE	\N	MCCLURES LANE	SANDY CREEK	3695	VIC	LANE	\N	CONFIRMED	-36.37148640	147.11417892	4	7	0101000020A41E00005DE98C5AA76362405374C9DD8C2F42C0
82041	VIC2016584	locba8f7a4a0c92	PLATYPUS	COURT	\N	PLATYPUS COURT	BARANDUDA	3691	VIC	CT	\N	CONFIRMED	-36.18606366	146.94550252	4	10	0101000020A41E0000F035808E415E624048561BEFD01742C0
83295	VIC2017941	locc5abea08e85d	POINT COOK	ROAD	\N	POINT COOK ROAD	POINT COOK	3030	VIC	RD	\N	CONFIRMED	-37.90439096	144.75280635	4	493	0101000020A41E000013AF57FD16186240C0FF3D15C3F342C0
83301	VIC2017947	loca37d9a7b347e	POINT FORTUNA	ROAD	\N	POINT FORTUNA ROAD	KIMBOLTON	3551	VIC	RD	\N	CONFIRMED	-36.89200960	144.53147775	4	9	0101000020A41E0000A759A0DD01116240E9DBDD5E2D7242C0
83774	VIC2018444	loc47e9d5554e9d	MCFARLANE	ROAD	\N	MCFARLANE ROAD	HAZELWOOD	3840	VIC	RD	\N	CONFIRMED	-38.30448492	146.34728373	4	11	0101000020A41E00000DD9C4F21C4B624039C3A25CF92643C0
83804	VIC2018477	locd755ccb7197e	MCFEES	ROAD	\N	MCFEES ROAD	DANDENONG NORTH	3175	VIC	RD	\N	CONFIRMED	-37.96409285	145.21534348	4	207	0101000020A41E000038800218E42662405A87FE6467FB42C0
84942	VIC2019697	loc6280f9052ec0	POUND	ROAD	\N	POUND ROAD	NARRE WARREN SOUTH	3805	VIC	RD	\N	CONFIRMED	-38.04450959	145.29375935	4	65	0101000020A41E00009D24027A6629624045B4807DB20543C0
85962	VIC2020817	locb71d10cf3b7c	ONTARIO	AVENUE	\N	ONTARIO AVENUE	MILDURA	3500	VIC	AV	\N	CONFIRMED	-34.20003429	142.12461716	4	406	0101000020A41E00000E5720DDFCC3614075D03EB99A1941C0
86054	VIC2020912	loc1b289d3ff2fc	ORCHARD	CIRCUIT	\N	ORCHARD CIRCUIT	SHEPPARTON	3630	VIC	CCT	\N	CONFIRMED	-36.35818389	145.40689572	4	82	0101000020A41E000009492C4A052D624085C03EF8D82D42C0
86991	VIC2021931	loc991c414cb6c9	MUGAVINS	ROAD	\N	MUGAVINS ROAD	UPPER PLENTY	3756	VIC	RD	\N	CONFIRMED	-37.43279669	145.07901230	4	13	0101000020A41E00006A8FCD4487226240FCAEC6E165B742C0
87014	VIC2021954	locf16910f90fb9	MUIR	STREET	\N	MUIR STREET	HIGHETT	3190	VIC	ST	\N	CONFIRMED	-37.94534714	145.03560338	4	39	0101000020A41E00004417B3A92321624065D5942201F942C0
87693	VIC2022663	loc82baa1179308	PRINCES	HIGHWAY	\N	PRINCES HIGHWAY	PAKENHAM	3810	VIC	HWY	\N	CONFIRMED	-38.07136846	145.48186190	4	300	0101000020A41E000008B6A5696B2F62403CD5089A220943C0
88130	VIC2023132	loc4a7c5154c298	MCPHERSON	STREET	\N	MCPHERSON STREET	MOONEE PONDS	3039	VIC	ST	\N	CONFIRMED	-37.76096981	144.92830271	4	71	0101000020A41E00009F87E2A7B41D6240BF986F7567E142C0
88415	VIC2023428	loc3754c5fc3408	MURCHISON	DRIVE	\N	MURCHISON DRIVE	ROXBURGH PARK	3064	VIC	DR	\N	CONFIRMED	-37.63486964	144.93363559	4	45	0101000020A41E0000D0ADBE57E01D6240FB828A6843D142C0
88902	VIC2023947	loc8f565e81c655	OXFORD	DRIVE	\N	OXFORD DRIVE	THOMASTOWN	3074	VIC	DR	\N	CONFIRMED	-37.68287586	145.03302283	4	58	0101000020A41E0000E2DBE4850E216240C5F6E67968D742C0
88943	VIC2023988	loc74f8893fb76e	OXLEY	COURT	\N	OXLEY COURT	BROADMEADOWS	3047	VIC	CT	\N	CONFIRMED	-37.68426526	144.91958029	4	23	0101000020A41E000014F3A4336D1D624095BE080196D742C0
89106	VIC2024158	loca5de38b84720	PROSPECT	STREET	\N	PROSPECT STREET	BOX HILL	3128	VIC	ST	\N	CONFIRMED	-37.81807144	145.11742251	4	499	0101000020A41E00007508DAECC1236240BA4BA090B6E842C0
89275	VIC2024336	loc5c94ac6107ca	PUNCHBOWL	ROAD	\N	PUNCHBOWL ROAD	FLINDERS	3929	VIC	RD	\N	CONFIRMED	-38.46960069	144.97904009	4	28	0101000020A41E0000BC00E24B541F624051DD1AE01B3C43C0
90416	VIC2025537	locf51f6cd689bb	PALMERSTON	CRESCENT	\N	PALMERSTON CRESCENT	SOUTH MELBOURNE	3205	VIC	CR	\N	CONFIRMED	-37.83505184	144.96909090	4	805	0101000020A41E00003D4BEBCA021F6240DFA18BFAE2EA42C0
90816	VIC2025962	loc9901d119afda_2	QUEENS	LANE	\N	QUEENS LANE	MELBOURNE	3004	VIC	LANE	\N	CONFIRMED	-37.84431725	144.97718553	4	99	0101000020A41E00002FAF961A451F62406E19709612EC42C0
90825	VIC2025971	loc9901d119afda_2	QUEENS	ROAD	\N	QUEENS ROAD	MELBOURNE	3004	VIC	RD	\N	CONFIRMED	-37.84580910	144.97665167	4	3842	0101000020A41E00007BC700BB401F62406094FB7843EC42C0
91875	VIC2027065	loc9901d119afda_1	SPENCER	STREET	\N	SPENCER STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81801510	144.95367605	4	6452	0101000020A41E000050B7A283841E62402C1103B8B4E842C0
92547	VIC2027792	locd777103bd088	UNDERBANK	BOULEVARD	\N	UNDERBANK BOULEVARD	BACCHUS MARSH	3340	VIC	BVD	\N	CONFIRMED	-37.67388751	144.42103822	4	396	0101000020A41E000084282525790D6240025128F241D642C0
92842	VIC2028102	loc67a11408d754	RYAN	STREET	\N	RYAN STREET	FOOTSCRAY	3011	VIC	ST	\N	CONFIRMED	-37.79876405	144.90300477	4	100	0101000020A41E00000669426AE51C62403AFC7FE63DE642C0
93162	VIC2028446	loc76dea039b41f	SPRING	ROAD	\N	SPRING ROAD	MALVERN	3144	VIC	RD	\N	CONFIRMED	-37.85474309	145.03442359	4	106	0101000020A41E0000592880FF192162401804B93868ED42C0
93278	VIC2028573	loc406d1f7b5fe3	SPRING VALLEY	DRIVE	\N	SPRING VALLEY DRIVE	TEMPLESTOWE	3106	VIC	DR	\N	CONFIRMED	-37.75354033	145.15793842	4	40	0101000020A41E0000D295DFD40D25624095C8700274E042C0
93374	VIC2028669	loc3b583afba248	SPRINGVALE	ROAD	\N	SPRINGVALE ROAD	SPRINGVALE SOUTH	3172	VIC	RD	\N	CONFIRMED	-37.97263174	145.14823160	4	295	0101000020A41E00007B473250BE246240002D65327FFC42C0
93547	VIC2028859	loc0b665c0fe535	THE ESPLANADE	\N	\N	THE ESPLANADE	OCEAN GROVE	3226	VIC	\N	\N	CONFIRMED	-38.27138877	144.51989368	4	274	0101000020A41E0000E81F12F8A21062406AD301DEBC2243C0
94727	VIC2030169	loc2c4c767ea9b7	ST GEORGES	ROAD	\N	ST GEORGES ROAD	PRESTON	3072	VIC	RD	\N	CONFIRMED	-37.74448282	144.99749531	4	214	0101000020A41E0000A1CB487BEB1F6240BC2A8A364BDF42C0
94834	VIC2030282	loc9901d119afda_2	ST KILDA	ROAD	\N	ST KILDA ROAD	MELBOURNE	3004	VIC	RD	\N	CONFIRMED	-37.83707193	144.97567615	4	12082	0101000020A41E0000977730BD381F6240F3DF492C25EB42C0
95007	VIC2030489	loca4e166a620d9	THEODORE	AVENUE	\N	THEODORE AVENUE	NOBLE PARK	3174	VIC	AV	\N	CONFIRMED	-37.97465959	145.16775965	4	81	0101000020A41E0000D44A7C495E25624032E43BA5C1FC42C0
96145	VIC2031732	loc8f498b475ec6	STANDING	DRIVE	\N	STANDING DRIVE	TRARALGON EAST	3844	VIC	DR	\N	CONFIRMED	-38.19112845	146.56564739	4	52	0101000020A41E0000C5238EC819526240E70AA5E5761843C0
96156	VIC2031747	loc7213d03738b9	STANFORD	CLOSE	\N	STANFORD CLOSE	FAWKNER	3060	VIC	CL	\N	CONFIRMED	-37.69609372	144.96424073	4	49	0101000020A41E0000471A600FDB1E6240ED2C599919D942C0
96507	VIC2032116	locc586266ef8cc	THOMSON	STREET	\N	THOMSON STREET	SALE	3850	VIC	ST	\N	CONFIRMED	-38.10434522	147.05947930	4	137	0101000020A41E00003F092241E76162406CB2252F5B0D43C0
96615	VIC2032237	locf065e41cfac9	THOROGOOD	COURT	\N	THOROGOOD COURT	TAYLORS LAKES	3038	VIC	CT	\N	CONFIRMED	-37.70640814	144.77994053	4	22	0101000020A41E000099A5D745F5186240CF76F9946BDA42C0
98878	VIC2034660	loc2f9c80de6f7d	SCORESBY	ROAD	\N	SCORESBY ROAD	BAYSWATER	3153	VIC	RD	\N	CONFIRMED	-37.84798463	145.26946735	4	247	0101000020A41E0000E0F2FD799F2862402AAEA6C28AEC42C0
99015	VIC2034802	loce11f06c54f46	STEPHEN	STREET	\N	STEPHEN STREET	GISBORNE	3437	VIC	ST	\N	CONFIRMED	-37.48920122	144.58479259	4	69	0101000020A41E0000C81FF39EB61262401A8844259EBE42C0
99056	VIC2034844	locb53ace4ff1b6	STEPHENSON	STREET	\N	STEPHENSON STREET	GREAT WESTERN	3374	VIC	ST	\N	CONFIRMED	-37.14925540	142.85197178	4	28	0101000020A41E0000E186525A43DB61402EE00ACD1A9342C0
99112	VIC2034902	loc5ba812288f5b	STEVENS	COURT	\N	STEVENS COURT	LEOPOLD	3224	VIC	CT	\N	CONFIRMED	-38.18699058	144.45864593	4	17	0101000020A41E000064B93A3AAD0E62404AE1AC4EEF1743C0
99918	VIC2035753	loc0a03ed3531fd	RESERVE	ROAD	\N	RESERVE ROAD	CHELTENHAM	3192	VIC	RD	\N	CONFIRMED	-37.96338387	145.03733715	4	134	0101000020A41E0000A1C5ADDD312162406C92A32950FB42C0
100558	VIC2036451	loc2508c9e5a93c	STOKES	LANE	WEST	STOKES LANE WEST	RIDDELLS CREEK	3431	VIC	LANE	W	CONFIRMED	-37.46838612	144.69656916	4	6	0101000020A41E00004533684B4A16624071A68D13F4BB42C0
100821	VIC2036742	locc2ea2de6af6c	TOORAK	ROAD	\N	TOORAK ROAD	SOUTH YARRA	3141	VIC	RD	\N	CONFIRMED	-37.83882349	144.99044353	4	2199	0101000020A41E0000503CA1B6B11F6240535570915EEB42C0
100837	VIC2036759	locadc5cabaa80e	TOORONGA	ROAD	\N	TOORONGA ROAD	GLEN IRIS	3146	VIC	RD	\N	CONFIRMED	-37.85440015	145.04192002	4	354	0101000020A41E0000535EA7685721624047F9EEFB5CED42C0
101239	VIC2037177	loc29a798d6921b	RHUS	COURT	\N	RHUS COURT	WERRIBEE	3030	VIC	CT	\N	CONFIRMED	-37.88612667	144.66575435	4	15	0101000020A41E00006E0D11DC4D156240B7E145996CF142C0
101872	VIC2037856	loc6ae7eaa3c1f3	STOTT	STREET	\N	STOTT STREET	BOX HILL SOUTH	3128	VIC	ST	\N	CONFIRMED	-37.84285370	145.11284017	4	119	0101000020A41E000067FAFC629C23624003684AA1E2EB42C0
101900	VIC2037884	locb8f595af5fb8	STRADA	CRESCENT	\N	STRADA CRESCENT	WHEELERS HILL	3150	VIC	CR	\N	CONFIRMED	-37.90784812	145.16758650	4	104	0101000020A41E000009185DDE5C2562404A91005E34F442C0
102129	VIC2038134	locf57f2052e543	STRINGYBARK	CRESCENT	\N	STRINGYBARK CRESCENT	FRANKSTON NORTH	3200	VIC	CR	\N	CONFIRMED	-38.12207728	145.14717870	4	16	0101000020A41E00005FE51AB0B5246240A297723AA00F43C0
102592	VIC2038936	locf066999b6a14	RIMFIRE	DRIVE	\N	RIMFIRE DRIVE	HALLAM	3803	VIC	DR	\N	CONFIRMED	-38.01922417	145.27577706	4	96	0101000020A41E0000FCB5692AD3286240ACB806F0750243C0
103559	VIC2040420	locc2ea2de6af6c	RIVER	STREET	\N	RIVER STREET	SOUTH YARRA	3141	VIC	ST	\N	CONFIRMED	-37.83712568	144.99767488	4	675	0101000020A41E000081B4DEF3EC1F6240F21E2DEF26EB42C0
103647	VIC2040515	loc4fa4b090ce9e	RIVERSDALE	ROAD	\N	RIVERSDALE ROAD	HAWTHORN EAST	3123	VIC	RD	\N	CONFIRMED	-37.83061428	145.05035320	4	1076	0101000020A41E0000F767507E9C2162406518989151EA42C0
103702	VIC2040573	locff58d0167065	RIVERVIEW	ROAD	\N	RIVERVIEW ROAD	BENALLA	3672	VIC	RD	\N	CONFIRMED	-36.55680614	145.99066320	4	48	0101000020A41E000039AB4F83B33F624089C1706C454742C0
103817	VIC2040693	loc656f84726510	SHAND	ROAD	\N	SHAND ROAD	RESERVOIR	3073	VIC	RD	\N	CONFIRMED	-37.72206668	145.01954220	4	95	0101000020A41E00008ABCF616A0206240CE1054AE6CDC42C0
104825	VIC2042282	loc6de0828869d7	ROBERT	STREET	\N	ROBERT STREET	COLLINGWOOD	3066	VIC	ST	\N	CONFIRMED	-37.80570288	144.98725463	4	412	0101000020A41E000096950597971F62404EF29F4521E742C0
104873	VIC2042335	locbbb93e2c6c42	SHEEPWASH	ROAD	\N	SHEEPWASH ROAD	BARWON HEADS	3227	VIC	RD	\N	CONFIRMED	-38.26861373	144.48966587	4	126	0101000020A41E0000C233C257AB0F6240A4CD48EF612243C0
105534	VIC2043038	locfa38377aaf29	SWAMP	LANE	\N	SWAMP LANE	DEDERANG	3691	VIC	LANE	\N	CONFIRMED	-36.47968328	147.03915636	4	4	0101000020A41E00002CB4D6C440616240DE040043663D42C0
106254	VIC2044273	locddc4a1bcd8ba	SIDDELEY	STREET	\N	SIDDELEY STREET	DOCKLANDS	3008	VIC	ST	\N	CONFIRMED	-37.82222216	144.95351428	4	1740	0101000020A41E0000CF1B6130831E62408D9F63933EE942C0
106303	VIC2044329	loc11fb0b5df130	SWAN	ROAD	\N	SWAN ROAD	MORWELL	3840	VIC	RD	\N	CONFIRMED	-38.23947175	146.44353967	4	67	0101000020A41E00001E241B7A314E62406F48A302A71E43C0
106539	VIC2044583	loc20a81a4bf246	SYCAMORE	GROVE	\N	SYCAMORE GROVE	MOUNT EVELYN	3796	VIC	GR	\N	CONFIRMED	-37.80089948	145.37545033	4	26	0101000020A41E0000EB1369B0032C6240E0FDC8DF83E642C0
107233	VIC2045776	loc6de6554b144b	SIMMONDS CREEK	ROAD	\N	SIMMONDS CREEK ROAD	TAWONGA SOUTH	3698	VIC	RD	\N	CONFIRMED	-36.76222836	147.14715448	4	91	0101000020A41E0000EBE14F7DB56462405124EBB2906142C0
107539	VIC2046096	loc8fef59c1c585	TADSTAN	DRIVE	\N	TADSTAN DRIVE	TULLAMARINE	3043	VIC	DR	\N	CONFIRMED	-37.69484249	144.87806205	4	84	0101000020A41E00007B939515191C6240EA354599F0D842C0
107655	VIC2046214	locec99dd6d0979	TALBOT	STREET	\N	TALBOT STREET	ALTONA MEADOWS	3028	VIC	ST	\N	CONFIRMED	-37.86968484	144.78574962	4	124	0101000020A41E0000D21763DC2419624041D034D551EF42C0
108132	VIC2046842	loc3319215a0a10	ROODING	STREET	\N	ROODING STREET	BRIGHTON	3186	VIC	ST	\N	CONFIRMED	-37.90360711	145.00006972	4	60	0101000020A41E0000D6A336920020624009F1D465A9F342C0
110156	VIC2048971	locd724f9a08a75	SMITH	STREET	\N	SMITH STREET	WARRAGUL	3820	VIC	ST	\N	CONFIRMED	-38.15960461	145.93255446	4	140	0101000020A41E00000C6E737CD73D6240D41E82EC6D1443C0
110711	VIC2049549	locd8470b65d64b	TUCKER	ROAD	\N	TUCKER ROAD	BENTLEIGH	3204	VIC	RD	\N	CONFIRMED	-37.92479351	145.05008719	4	380	0101000020A41E0000F45F73509A21624064803CA25FF642C0
111170	VIC2050036	loc86b22e8e6ecf	ROWENA	STREET	\N	ROWENA STREET	EAST BENDIGO	3550	VIC	ST	\N	CONFIRMED	-36.74155456	144.31182965	4	34	0101000020A41E00008A952C82FA09624028B38342EB5E42C0
112690	VIC2051667	locd6f79866f950	RUSHDALE	STREET	\N	RUSHDALE STREET	KNOXFIELD	3180	VIC	ST	\N	CONFIRMED	-37.90069600	145.25318156	4	191	0101000020A41E0000CF0437101A286240ABD1AB014AF342C0
112746	VIC2051723	loc9901d119afda_1	RUSSELL	STREET	\N	RUSSELL STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81189856	144.96769815	4	2666	0101000020A41E0000CA541C62F71E62404C6FC14AECE742C0
113119	VIC2052113	loc9fe59dbd0874	SOUTH GIPPSLAND	HIGHWAY	\N	SOUTH GIPPSLAND HIGHWAY	CRANBOURNE NORTH	3977	VIC	HWY	\N	CONFIRMED	-38.07414757	145.27125381	4	52	0101000020A41E0000B15B781CAE2862402B1DE6AA7D0943C0
114208	VIC2053277	loc2d817b7080e2	WAVERLEY	ROAD	\N	WAVERLEY ROAD	MALVERN EAST	3145	VIC	RD	\N	CONFIRMED	-37.87819838	145.06661204	4	1247	0101000020A41E00003CAA92AF2122624006C0F4CD68F042C0
114227	VIC2053297	loc11b2a92fb5f0	WAXMAN	PARADE	\N	WAXMAN PARADE	BRUNSWICK WEST	3055	VIC	PDE	\N	CONFIRMED	-37.75939747	144.93579393	4	122	0101000020A41E0000A6A41C06F21D62405728B1EF33E142C0
114747	VIC2053844	locc605118e951a	DUDLEY	STREET	\N	DUDLEY STREET	WALLAN	3756	VIC	ST	\N	CONFIRMED	-37.41249943	144.97374806	4	164	0101000020A41E0000CA07B1F1281F6240FCBB04C8CCB442C0
114889	VIC2053994	loc5e68bb81d75d	COUGHLAN	ROAD	\N	COUGHLAN ROAD	OAKVALE	3540	VIC	RD	\N	CONFIRMED	-35.90946143	143.55433875	4	4	0101000020A41E0000FA449E24BDF1614065696D3B69F441C0
115164	VIC2054286	loc913bf4728c4e	WEBSTER	STREET	\N	WEBSTER STREET	CAMBERWELL	3124	VIC	ST	\N	CONFIRMED	-37.83678165	145.09562451	4	48	0101000020A41E0000ACE4215B0F2362404B523EA91BEB42C0
115784	VIC2054946	loc0a03ed3531fd	BERNARD	STREET	\N	BERNARD STREET	CHELTENHAM	3192	VIC	ST	\N	CONFIRMED	-37.95391478	145.06724810	4	233	0101000020A41E0000FBC67CE526226240B1A227E119FA42C0
115799	VIC2054961	loc1a22f173d7f3	CRAIG	ROAD	\N	CRAIG ROAD	JUNCTION VILLAGE	3977	VIC	RD	\N	CONFIRMED	-38.13712839	145.29432634	4	222	0101000020A41E0000D894121F6B2962409A334F6C8D1143C0
115891	VIC2055058	locfe955a87410d	FITZROY	STREET	\N	FITZROY STREET	ST KILDA	3182	VIC	ST	\N	CONFIRMED	-37.85964110	144.97758035	4	2275	0101000020A41E0000CB0E9656481F6240136635B808EE42C0
116249	VIC2055433	locc25e0bed112f	WELLS	ROAD	\N	WELLS ROAD	CHELSEA HEIGHTS	3196	VIC	RD	\N	CONFIRMED	-38.03980426	145.13765771	4	430	0101000020A41E0000C14F24B1672462408278554E180543C0
118655	VIC2058076	locb8f595af5fb8	WHALLEY	DRIVE	\N	WHALLEY DRIVE	WHEELERS HILL	3150	VIC	DR	\N	CONFIRMED	-37.92023097	145.19403329	4	542	0101000020A41E0000545C4D85352662404B75E020CAF542C0
119512	VIC2058977	locadc5cabaa80e	VALENCY	ROAD	\N	VALENCY ROAD	GLEN IRIS	3146	VIC	RD	\N	CONFIRMED	-37.85701779	145.05326403	4	24	0101000020A41E0000E75CC456B4216240F2114AC2B2ED42C0
119570	VIC2059036	loc11b2a92fb5f0	WHITBY	STREET	\N	WHITBY STREET	BRUNSWICK WEST	3055	VIC	ST	\N	CONFIRMED	-37.76403941	144.94423883	4	150	0101000020A41E0000D3CE5934371E62400F671B0BCCE142C0
119768	VIC2059240	loc264c2d9ba83e	WHITEHAVEN	CRESCENT	\N	WHITEHAVEN CRESCENT	MULGRAVE	3170	VIC	CR	\N	CONFIRMED	-37.92756651	145.17736719	4	38	0101000020A41E0000DF0DF5FDAC2562404DA8D87FBAF642C0
119992	VIC2059476	loc1b289d3ff2fc	ACACIA	STREET	\N	ACACIA STREET	SHEPPARTON	3630	VIC	ST	\N	CONFIRMED	-36.36554491	145.41903070	4	31	0101000020A41E0000A41012B3682D6240AAD5F42CCA2E42C0
120045	VIC2059530	loc1e06c486c813	BLACKWOOD	STREET	\N	BLACKWOOD STREET	NORTH MELBOURNE	3051	VIC	ST	\N	CONFIRMED	-37.80132041	144.95503824	4	965	0101000020A41E000057E75AAC8F1E62409E48CDAA91E642C0
120248	VIC2059743	loc31f384e524fe	CITY	ROAD	\N	CITY ROAD	SOUTHBANK	3006	VIC	RD	\N	CONFIRMED	-37.82550849	144.96059822	4	15330	0101000020A41E0000DE6F7A38BD1E6240678F1F43AAE942C0
120530	VIC2060041	loc11fb0b5df130	VARY	STREET	\N	VARY STREET	MORWELL	3840	VIC	ST	\N	CONFIRMED	-38.22679377	146.42374444	4	174	0101000020A41E00002EF57F508F4D6240148B0894071D43C0
121454	VIC2061025	locb948618ae376	VERDON	STREET	\N	VERDON STREET	SEBASTOPOL	3356	VIC	ST	\N	CONFIRMED	-37.58379200	143.83706792	4	61	0101000020A41E0000C99DA942C9FA61404ED53DB2B9CA42C0
121725	VIC2061305	loc82b861dfb765	VICTORIA	ROAD	\N	VICTORIA ROAD	THORNBURY	3071	VIC	RD	\N	CONFIRMED	-37.75925881	145.01317983	4	149	0101000020A41E0000245A1BF86B2062402F1387642FE142C0
121803	VIC2061385	loca0398a35cf5e	VICTORIA	STREET	\N	VICTORIA STREET	CARLTON	3053	VIC	ST	\N	CONFIRMED	-37.80707509	144.96692824	4	2256	0101000020A41E00001F0C7E13F11E6240AE7B8E3C4EE742C0
121824	VIC2061406	loc656f84726510	WILKINSON	STREET	\N	WILKINSON STREET	RESERVOIR	3073	VIC	ST	\N	CONFIRMED	-37.72643710	145.01821558	4	69	0101000020A41E0000160CD73895206240F08C11E4FBDC42C0
121958	VIC2061549	loc9901d119afda_1	WILLIAM	STREET	\N	WILLIAM STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81500291	144.95791275	4	3146	0101000020A41E00007CB5A338A71E6240234CEE0352E842C0
122094	VIC2061689	loc250adfcbc82d	WILLIAMS	ROAD	\N	WILLIAMS ROAD	PRAHRAN	3181	VIC	RD	\N	CONFIRMED	-37.85353953	145.00236305	4	355	0101000020A41E000001CFAC5B13206240BB9887C840ED42C0
122325	VIC2061938	loc9a86c6faf562	CALLAGHAN	STREET	\N	CALLAGHAN STREET	JACKASS FLAT	3556	VIC	ST	\N	CONFIRMED	-36.71300512	144.28908464	4	51	0101000020A41E00006E526E2E40096240E92374C0435B42C0
122432	VIC2062049	loc9e7da77def26	GALADA	AVENUE	\N	GALADA AVENUE	PARKVILLE	3052	VIC	AV	\N	CONFIRMED	-37.78054904	144.94000625	4	1414	0101000020A41E000024B9FC87141E6240B2DCEB07E9E342C0
123357	VIC2063014	loc13ed320cd188	ALEXANDER	CLOSE	\N	ALEXANDER CLOSE	STRATHFIELDSAYE	3551	VIC	CL	\N	CONFIRMED	-36.79540711	144.33698827	4	53	0101000020A41E000024D99F9BC80A62405A3A72E6CF6542C0
123870	VIC2063543	loc7d9d9818d4b9	VIVIENNE	AVENUE	\N	VIVIENNE AVENUE	BORONIA	3155	VIC	AV	\N	CONFIRMED	-37.86476159	145.27457945	4	24	0101000020A41E0000EBBCD75AC928624088F1FD81B0EE42C0
124683	VIC2064406	loc92bf5bc798e7	EPSOM	ROAD	\N	EPSOM ROAD	FLEMINGTON	3031	VIC	RD	\N	CONFIRMED	-37.78425174	144.91824501	4	816	0101000020A41E000049F55B43621D6240C8906B5C62E442C0
124685	VIC2064408	loc656f84726510	EPSTEIN	STREET	\N	EPSTEIN STREET	RESERVOIR	3073	VIC	ST	\N	CONFIRMED	-37.70963115	144.99311555	4	89	0101000020A41E0000C50C439AC71F624087BC8A31D5DA42C0
124882	VIC2064616	loccaca39f133a7	WAIORA	ROAD	\N	WAIORA ROAD	HEIDELBERG HEIGHTS	3081	VIC	RD	\N	CONFIRMED	-37.73844639	145.05938255	4	253	0101000020A41E000080C63B76E62162401B734B6985DE42C0
125389	VIC2065164	loc76dea039b41f	WINTER	STREET	\N	WINTER STREET	MALVERN	3144	VIC	ST	\N	CONFIRMED	-37.86028850	145.03135812	4	84	0101000020A41E0000A67BBEE200216240FD4FFEEE1DEE42C0
125553	VIC2065334	locae68612e5fe1	WISTERIA	WAY	\N	WISTERIA WAY	WARRANWOOD	3134	VIC	WAY	\N	CONFIRMED	-37.77762852	145.25274787	4	7	0101000020A41E00001479B382162862401FEBD25489E342C0
125947	VIC2065745	loc1fbfb471eb7c	DESMOND	CRESCENT	\N	DESMOND CRESCENT	ROMSEY	3434	VIC	CR	\N	CONFIRMED	-37.35812303	144.73355034	4	26	0101000020A41E0000A108903E79176240B0E5B6F9D6AD42C0
126012	VIC2065815	loc232da9d11723	WALLACE	STREET	\N	WALLACE STREET	BAIRNSDALE	3875	VIC	ST	\N	CONFIRMED	-37.82415170	147.60357129	4	169	0101000020A41E000058EBBC7450736240AE388BCD7DE942C0
126618	VIC2066462	loc1a7553da1009	WOODACRES	ROAD	\N	WOODACRES ROAD	CHETWYND	3312	VIC	RD	\N	CONFIRMED	-37.32825147	141.41622813	4	6	0101000020A41E0000CFC0A7BD51AD6140C841E82404AA42C0
126751	VIC2066602	loc9a48431374e1	BAY	STREET	\N	BAY STREET	PORT MELBOURNE	3207	VIC	ST	\N	CONFIRMED	-37.83780391	144.94305578	4	1445	0101000020A41E0000ECAC50832D1E624099F494283DEB42C0
127031	VIC2066892	loc875118ed8437	CONDELL	STREET	\N	CONDELL STREET	FITZROY	3065	VIC	ST	\N	CONFIRMED	-37.80256656	144.98127504	4	31	0101000020A41E0000CCA5E99A661F624018084480BAE642C0
128144	VIC2068062	loceb41e8eec3ee	COOK	ROAD	\N	COOK ROAD	LONGWARRY	3816	VIC	RD	\N	CONFIRMED	-38.10476296	145.75433256	4	32	0101000020A41E00004170097E233862401E8467DF680D43C0
128360	VIC2068283	loc72d1f0339be6	WARRANDYTE	ROAD	\N	WARRANDYTE ROAD	RINGWOOD	3134	VIC	RD	\N	CONFIRMED	-37.80794485	145.23050703	4	297	0101000020A41E0000246B4750602762405EDCA1BC6AE742C0
128637	VIC2068568	locedacea740a10	WOORINEN	ROAD	\N	WOORINEN ROAD	SWAN HILL	3585	VIC	RD	\N	CONFIRMED	-35.32162398	143.51597488	4	29	0101000020A41E00000A65C0DD82F06140CCDA7DF92AA941C0
128989	VIC2068940	locfd8472c41cbe	WYNDHAM	PLACE	\N	WYNDHAM PLACE	ROWVILLE	3178	VIC	PL	\N	CONFIRMED	-37.93794909	145.24250195	4	26	0101000020A41E0000EB0E7393C2276240756E3DB70EF842C0
129141	VIC2069101	locc2ea2de6af6c	ARGO	STREET	\N	ARGO STREET	SOUTH YARRA	3141	VIC	ST	\N	CONFIRMED	-37.84405177	144.98826416	4	141	0101000020A41E000049E028DC9F1F6240F5236EE309EC42C0
129731	VIC2069720	loce16236caf708	WATT	STREET	\N	WATT STREET	LARA	3212	VIC	ST	\N	CONFIRMED	-38.02942100	144.42466154	4	425	0101000020A41E00006845CCD3960D624066683C11C40343C0
130193	VIC2070226	locc7ee8539a72b	LALEHAM	COURT	\N	LALEHAM COURT	ELTHAM	3095	VIC	CT	\N	CONFIRMED	-37.71617062	145.16014714	4	16	0101000020A41E0000221BE5EC1F256240C6A0977AABDB42C0
130574	VIC2070646	loc4ff8c926c940	YOORALLA	STREET	\N	YOORALLA STREET	ASHWOOD	3147	VIC	ST	\N	CONFIRMED	-37.86841000	145.10427920	4	36	0101000020A41E0000E6345541562362407AC2120F28EF42C0
130872	VIC2070959	loc656f84726510	RADFORD	ROAD	\N	RADFORD ROAD	RESERVOIR	3073	VIC	RD	\N	CONFIRMED	-37.70584996	144.98331746	4	152	0101000020A41E000025892D56771F62409D0A9F4A59DA42C0
132100	VIC2072267	loc9fe59dbd0874	LAWLESS	DRIVE	\N	LAWLESS DRIVE	CRANBOURNE NORTH	3977	VIC	DR	\N	CONFIRMED	-38.06948581	145.27528746	4	149	0101000020A41E00005DB6A527CF28624038BE38E9E40843C0
132410	VIC2072594	loc37efd432abe4	TINARRA	COURT	\N	TINARRA COURT	WANTIRNA SOUTH	3152	VIC	CT	\N	CONFIRMED	-37.86921116	145.21771766	4	26	0101000020A41E0000C6AE068BF726624055C2B04F42EF42C0
132786	VIC2072985	loc2f9c80de6f7d	HIGHMOOR	AVENUE	\N	HIGHMOOR AVENUE	BAYSWATER	3153	VIC	AV	\N	CONFIRMED	-37.84274736	145.26435434	4	103	0101000020A41E0000629B3B9775286240C3FE3E25DFEB42C0
133142	VIC2073360	loc12c0177d3d38	STEWART	STREET	\N	STEWART STREET	PASCOE VALE	3044	VIC	ST	\N	CONFIRMED	-37.72825613	144.92539853	4	57	0101000020A41E0000BAC360DD9C1D624013BB327F37DD42C0
133458	VIC2073696	loc4ff8c926c940	WIPPA	COURT	\N	WIPPA COURT	ASHWOOD	3147	VIC	CT	\N	CONFIRMED	-37.87213527	145.09769038	4	22	0101000020A41E00007B67934720236240482BE720A2EF42C0
133643	VIC2073892	loc8a2c57a8fa9c	LEITCHVILLE-PYRAMID	ROAD	\N	LEITCHVILLE-PYRAMID ROAD	LEITCHVILLE	3567	VIC	RD	\N	CONFIRMED	-35.94079711	144.24614762	4	10	0101000020A41E00006C3CF970E007624087CF290A6CF841C0
135238	VIC2075671	loc4ff8c926c940	MONTPELLIER	ROAD	\N	MONTPELLIER ROAD	ASHWOOD	3147	VIC	RD	\N	CONFIRMED	-37.85890461	145.10751013	4	13	0101000020A41E0000D78A15B970236240B52A1596F0ED42C0
135353	VIC2075791	loca818c5eaa373	SUFFOLK	STREET	\N	SUFFOLK STREET	WEST FOOTSCRAY	3012	VIC	ST	\N	CONFIRMED	-37.79053312	144.87327849	4	94	0101000020A41E0000355BBBE5F11B62400567743030E542C0
135634	VIC2076198	locf3fc3fca2acd	PILLARS	ROAD	\N	PILLARS ROAD	BANGHOLME	3175	VIC	RD	\N	CONFIRMED	-38.02758237	145.15906164	4	34	0101000020A41E000024BB6F08172562404F8CB0D1870343C0
135777	VIC2076350	loc910a14938d48	OCONNELL	STREET	\N	OCONNELL STREET	GEELONG WEST	3218	VIC	ST	\N	CONFIRMED	-38.13927314	144.35116086	4	96	0101000020A41E0000BA2AB3B53C0B624070C1C6B3D31143C0
135959	VIC2076646	locc67851215f08	HADDON	COURT	\N	HADDON COURT	MEADOW HEIGHTS	3048	VIC	CT	\N	CONFIRMED	-37.65776728	144.92537298	4	22	0101000020A41E000077B6CBA79C1D62404CFDDDB731D442C0
137227	VIC2078131	locc672a234fa5a	MOUNTJOY	PARADE	\N	MOUNTJOY PARADE	LORNE	3232	VIC	PDE	\N	CONFIRMED	-38.54373843	143.97845385	4	567	0101000020A41E0000A6CC727E4FFF6140D5368B38994543C0
137573	VIC2078595	loc1e33f92d8409	KIRRAK	STREET	\N	KIRRAK STREET	NORTH WONTHAGGI	3995	VIC	ST	\N	CONFIRMED	-38.59263720	145.59822444	4	70	0101000020A41E0000F9AE94A7243362404E322889DB4B43C0
138048	VIC2079106	loc780d4ed4ca46	SLADEN	STREET	\N	SLADEN STREET	HAMLYN HEIGHTS	3215	VIC	ST	\N	CONFIRMED	-38.12288200	144.32120068	4	167	0101000020A41E0000B201A646470A62402FA2ED98BA0F43C0
138364	VIC2079446	loc62ed665318da	OSWALD	STREET	\N	OSWALD STREET	KYABRAM	3620	VIC	ST	\N	CONFIRMED	-36.31094048	145.05183975	4	69	0101000020A41E000040DCD5ABA8216240204DCCE5CC2742C0
138542	VIC2079635	loc7c934a667999	ROSS	STREET	\N	ROSS STREET	HASTINGS	3915	VIC	ST	\N	CONFIRMED	-38.31500565	145.18967029	4	16	0101000020A41E000055926DC7112662401267EA1A522843C0
139204	VIC2080341	loc12c0177d3d38	SOMERSET	STREET	\N	SOMERSET STREET	PASCOE VALE	3044	VIC	ST	\N	CONFIRMED	-37.73060904	144.92623368	4	27	0101000020A41E0000B881D0B4A31D6240217BD69884DD42C0
139533	VIC2080683	loc9901d119afda_1	QUEEN	STREET	\N	QUEEN STREET	MELBOURNE	3000	VIC	ST	\N	CONFIRMED	-37.81271979	144.95967106	4	3350	0101000020A41E0000C43315A0B51E6240566EBB3307E842C0
139564	VIC2080714	loc1e06c486c813	QUEENSBERRY	STREET	\N	QUEENSBERRY STREET	NORTH MELBOURNE	3051	VIC	ST	\N	CONFIRMED	-37.80304119	144.94965524	4	546	0101000020A41E0000CDC86293631E62400A32C00DCAE642C0
140046	VIC2554240	loc532c3dac4248	OTTREYS SCRUB	ROAD	\N	OTTREYS SCRUB ROAD	WALMER	3463	VIC	RD	\N	CONFIRMED	-36.98874826	144.18152888	4	23	0101000020A41E0000255CA715CF056240A556904D8F7E42C0
140976	VIC2981005	locff62fb6a898a	MYHAVEN	CIRCUIT	\N	MYHAVEN CIRCUIT	CARRUM DOWNS	3201	VIC	CCT	\N	CONFIRMED	-38.08815431	145.18347612	4	42	0101000020A41E0000E7DF4F09DF256240C939F3A3480B43C0
142094	VIC2997584	loceac5d85ea01d	NARUNG	WAY	\N	NARUNG WAY	WYNDHAM VALE	3024	VIC	WAY	\N	CONFIRMED	-37.88493525	144.61171880	4	14	0101000020A41E0000260B4E3393136240EEE9EA8E45F142C0
142981	VIC3136743	locb48ce003b11e	OSCAR	DRIVE	\N	OSCAR DRIVE	MARONG	3515	VIC	DR	\N	CONFIRMED	-36.72816437	144.13024980	4	55	0101000020A41E0000F0E9A0012B04624098A1757D345D42C0
143355	VIC3137203	loc108a649ba4ae	MCGINTY	ROAD	\N	MCGINTY ROAD	TARILTA	3451	VIC	RD	\N	CONFIRMED	-37.16916858	144.18625307	4	1	0101000020A41E0000BF8DFFC8F50562402D4EE750A79542C0
144369	VIC3259081	loc46443686a430	DAVID	DRIVE	\N	DAVID DRIVE	SUNSHINE WEST	3020	VIC	DR	\N	CONFIRMED	-37.78878195	144.78884842	4	107	0101000020A41E0000D7AC0A3F3E1962406A7693CEF6E442C0
145291	VIC3338061	loce25dfc481765	ROYAL	PARADE	\N	ROYAL PARADE	KILMORE	3764	VIC	PDE	\N	CONFIRMED	-37.29362977	144.93177640	4	231	0101000020A41E0000E8A5BD1CD11D624019A409A995A542C0
146297	VIC3347454	loc232da9d11723	MAIN	STREET	\N	MAIN STREET	BAIRNSDALE	3875	VIC	ST	\N	CONFIRMED	-37.83068344	147.61217323	4	492	0101000020A41E0000C64A50EC967362407C10C0D553EA42C0
147167	VIC3353154	loce16236caf708	BENETTI	DRIVE	\N	BENETTI DRIVE	LARA	3212	VIC	DR	\N	CONFIRMED	-38.03230067	144.40209696	4	63	0101000020A41E0000ACA071FADD0C6240FAA4A86D220443C0
147423	VIC3353446	locc5abea08e85d	TARCOOLA	CRESCENT	\N	TARCOOLA CRESCENT	POINT COOK	3030	VIC	CR	\N	CONFIRMED	-37.90613179	144.76866725	4	30	0101000020A41E000033880FEC981862403EF56120FCF342C0
147757	VIC3353866	loc29841cc6d6f1	MANOOKA	ROAD	\N	MANOOKA ROAD	BROOKFIELD	3338	VIC	RD	\N	CONFIRMED	-37.69790233	144.54232256	4	58	0101000020A41E0000A862D7B45A1162407B9311DD54D942C0
148077	VIC3374991	loc338a35dd09f0	FUTURA	AVENUE	\N	FUTURA AVENUE	GOLDEN SQUARE	3555	VIC	AV	\N	CONFIRMED	-36.77909862	144.23475980	4	44	0101000020A41E00004CEDFB26830762401EA1EA80B96342C0
149106	VIC3382134	locc5abea08e85d	APPLEBOX	CIRCUIT	\N	APPLEBOX CIRCUIT	POINT COOK	3030	VIC	CCT	\N	CONFIRMED	-37.90796978	144.72961095	4	35	0101000020A41E0000B62110F9581762409C6D8F5A38F442C0
154540	VIC3556163	loc4161e46afd2f	SOLOMON	WAY	\N	SOLOMON WAY	BEVERIDGE	3753	VIC	WAY	\N	CONFIRMED	-37.48053591	144.95294154	4	8	0101000020A41E000099A9417F7E1E62407600613382BD42C0
157337	VIC3559217	loc64c822b0bad5	LANSELL	AVENUE	\N	LANSELL AVENUE	OFFICER	3809	VIC	AV	\N	CONFIRMED	-38.06325835	145.42920457	4	40	0101000020A41E000033EE380BBC2D6240763980D9180843C0
163533	VIC3565705	loc8688ba223de1	COBBLER	LANE	\N	COBBLER LANE	MOUNT BULLER	3723	VIC	LANE	\N	CONFIRMED	-37.14532834	146.44488534	4	13	0101000020A41E0000A3382E803C4E6240B1BD791E9A9242C0
164128	VIC3566690	locbf553ce41d73	KIRWANS BRIDGE	ROAD	\N	KIRWANS BRIDGE ROAD	KIRWANS BRIDGE	3608	VIC	RD	\N	CONFIRMED	-36.75201591	145.15692151	4	8	0101000020A41E0000A52F428005256240C6C2AD0E426042C0
165329	VIC3568169	locae977e7a8d83	ELMSLIE	DRIVE	\N	ELMSLIE DRIVE	CRANBOURNE EAST	3977	VIC	DR	\N	CONFIRMED	-38.11903569	145.29793751	4	143	0101000020A41E000074B63EB488296240ABCDBD8F3C0F43C0
165976	VIC3568919	loc9ea2b366d63f	RANFURLIE	BOULEVARD	\N	RANFURLIE BOULEVARD	CRANBOURNE WEST	3977	VIC	BVD	\N	CONFIRMED	-38.11281994	145.24675983	4	69	0101000020A41E000021FADE74E52762407F5140E2700E43C0
166675	VIC3569786	loc9a86c6faf562	GHOST GUM	WAY	\N	GHOST GUM WAY	JACKASS FLAT	3556	VIC	WAY	\N	CONFIRMED	-36.70843370	144.28402085	4	18	0101000020A41E00003AC4E4B21609624030719AF4AD5A42C0
167609	VIC3570907	loc82baa1179308	LAVIT	LANE	\N	LAVIT LANE	PAKENHAM	3810	VIC	LANE	\N	CONFIRMED	-38.05548657	145.49526316	4	10	0101000020A41E0000A3632032D92F624034C2152F1A0743C0
168627	VIC3572033	locddc4a1bcd8ba	DIGITAL	DRIVE	\N	DIGITAL DRIVE	DOCKLANDS	3008	VIC	DR	\N	CONFIRMED	-37.81343429	144.94582128	4	472	0101000020A41E0000BF2EFD2A441E62405B7F649D1EE842C0
168717	VIC3572139	loca5643321b976	WEDDERBURN JUNCTION EAST	ROAD	\N	WEDDERBURN JUNCTION EAST ROAD	FIERY FLAT	3518	VIC	RD	\N	CONFIRMED	-36.42257349	143.80978350	4	3	0101000020A41E0000E52A16BFE9F9614071DA5BE3163642C0
169002	VIC3572470	loc6d7f0d49a3d6	BOBOLI	WALK	\N	BOBOLI WALK	WOLLERT	3750	VIC	WALK	\N	CONFIRMED	-37.61400232	144.99832685	4	6	0101000020A41E0000006F264BF21F6240B808C6A097CE42C0
169108	VIC3572604	loc9901d119afda_1	ROSE	LANE	\N	ROSE LANE	MELBOURNE	3000	VIC	LANE	\N	CONFIRMED	-37.81516397	144.95414159	4	3164	0101000020A41E0000B699F153881E62408603004B57E842C0
170077	VIC3573679	locb9872f35df41	ACACIA	PLACE	\N	ACACIA PLACE	ABBOTSFORD	3067	VIC	PL	\N	CONFIRMED	-37.81162960	145.01377368	4	765	0101000020A41E0000A92480D570206240983B8E7AE3E742C0
170390	VIC3574045	loc75d84680b181	ELLIOTT	ROAD	\N	ELLIOTT ROAD	TENNYSON	3572	VIC	RD	\N	CONFIRMED	-36.31232749	144.47979695	4	3	0101000020A41E00000F1F227F5A0F62408C98E158FA2742C0
171307	VIC3575102	loce0707ac065f9	BARLING	COURT	\N	BARLING COURT	THOMSON	3219	VIC	CT	\N	CONFIRMED	-38.16753968	144.37399848	4	25	0101000020A41E0000520BA9CBF70B6240EF30B3F0711543C0
174464	VIC3615353	loc90b2f4dd8c2d	UNITY	DRIVE	\N	UNITY DRIVE	MOUNT DUNEED	3217	VIC	DR	\N	CONFIRMED	-38.22498512	144.32926978	4	131	0101000020A41E00002815C760890A62404A3EFA4FCC1C43C0
175240	VIC3616200	loc0a03ed3531fd	BELLEVUE	ROAD	\N	BELLEVUE ROAD	CHELTENHAM	3192	VIC	RD	\N	CONFIRMED	-37.96221558	145.04053734	4	47	0101000020A41E000023B2F6144C2162409DE64FE129FB42C0
176906	VIC3618044	loc098e933e1fd2	TORQUAY	ROAD	\N	TORQUAY ROAD	GROVEDALE	3216	VIC	RD	\N	CONFIRMED	-38.20058101	144.34133847	4	273	0101000020A41E000089B0A73EEC0A6240071377A3AC1943C0
176988	VIC3618129	loc6a54ce63b777	ELEGANTE	ROAD	\N	ELEGANTE ROAD	WINTER VALLEY	3358	VIC	RD	\N	CONFIRMED	-37.57995626	143.79603613	4	74	0101000020A41E00001A19C32079F96140BEE7B8013CCA42C0
177431	VIC3618602	loc64c822b0bad5	MANCHESTER	BOULEVARD	\N	MANCHESTER BOULEVARD	OFFICER	3809	VIC	BVD	\N	CONFIRMED	-38.07681827	145.42305093	4	33	0101000020A41E00008E9C1AA2892D624051B15A2ED50943C0
178030	VIC3619244	locba5e689e47f8	ROSSER	BOULEVARD	\N	ROSSER BOULEVARD	TORQUAY	3228	VIC	BVD	\N	CONFIRMED	-38.31158229	144.32151256	4	64	0101000020A41E0000814EB5D4490A624009C8B0EDE12743C0
178725	VIC3619998	locf8d60bf51b6b	BALAKA	STREET	\N	BALAKA STREET	CAPEL SOUND	3940	VIC	ST	\N	CONFIRMED	-38.36912544	144.88046961	4	49	0101000020A41E00004D829ACE2C1C6240F7759E803F2F43C0
180026	VIC3621392	loc98325a7e67bf	REEVES	STREET	\N	REEVES STREET	LUCAS	3350	VIC	ST	\N	CONFIRMED	-37.54984486	143.78410295	4	28	0101000020A41E00004FDE115F17F961406FC9FD5061C642C0
180245	VIC3621616	loc1b271c01e3dc	GUARDIAN	STREET	\N	GUARDIAN STREET	MICKLEHAM	3064	VIC	ST	\N	CONFIRMED	-37.54152910	144.90438268	4	27	0101000020A41E00006735F2B3F01C6240892A57D350C542C0
181998	VIC3623473	loc6a54ce63b777	PRESENTATION	BOULEVARD	\N	PRESENTATION BOULEVARD	WINTER VALLEY	3358	VIC	BVD	\N	CONFIRMED	-37.57497369	143.79012684	4	84	0101000020A41E0000BD2F15B848F96140234EE5BC98C942C0
183665	VIC3625244	loc5c7c3d320a8a	PLYMOUTH	STREET	\N	PLYMOUTH STREET	WANGARATTA	3677	VIC	ST	\N	CONFIRMED	-36.33953046	146.28833628	4	28	0101000020A41E0000369B010D3A49624011D9EEBB752B42C0
184482	VIC3626122	loc4883549a5421	REGALLA	DRIVE	\N	REGALLA DRIVE	GREENVALE	3059	VIC	DR	\N	CONFIRMED	-37.64105456	144.87375025	4	19	0101000020A41E0000E69315C3F51B62406A1369130ED242C0
184727	VIC3626389	loc5ba812288f5b	KANGAROO PAW	DRIVE	\N	KANGAROO PAW DRIVE	LEOPOLD	3224	VIC	DR	\N	CONFIRMED	-38.20288720	144.46359505	4	42	0101000020A41E0000CD4A49C5D50E624075633035F81943C0
185950	VIC3627687	loc875f8bb64843	CHAI	WALK	\N	CHAI WALK	MANOR LAKES	3024	VIC	WALK	\N	CONFIRMED	-37.86383761	144.58246822	4	12	0101000020A41E0000807B6494A31262409D00163B92EE42C0
188179	VIC3630043	loce16236caf708	HOLLANDER	STREET	\N	HOLLANDER STREET	LARA	3212	VIC	ST	\N	CONFIRMED	-38.01716866	144.36161524	4	15	0101000020A41E000020B11F5A920B6240AB9B2895320243C0
191586	VIC4111949	locffa1c8993b70	TRIBE	STREET	\N	TRIBE STREET	MAMBOURIN	3024	VIC	ST	\N	CONFIRMED	-37.89023084	144.58386071	4	25	0101000020A41E0000D2DBA7FCAE12624066D88B15F3F142C0
192635	VIC4123121	loc8733d13ded2e	SHIRAZ	AVENUE	\N	SHIRAZ AVENUE	FRASER RISE	3336	VIC	AV	\N	CONFIRMED	-37.69349373	144.71353874	4	20	0101000020A41E00005417324FD5166240602A0D67C4D842C0
193454	VIC4127252	loc1b271c01e3dc	STRATEGIC	CIRCUIT	\N	STRATEGIC CIRCUIT	MICKLEHAM	3064	VIC	CCT	\N	CONFIRMED	-37.52725700	144.94299080	4	7	0101000020A41E0000B9CD0AFB2C1E624025CB49287DC342C0
193744	VIC4127542	loc956fa85c7b0c	FOURTH	AVENUE	\N	FOURTH AVENUE	PORTARLINGTON	3223	VIC	AV	\N	CONFIRMED	-38.11288755	144.64580831	4	49	0101000020A41E0000EC5D3076AA14624013B06719730E43C0
197754	VIC4172014	loc556974a8bc81	BLAZE	CIRCUIT	\N	BLAZE CIRCUIT	MELTON	3337	VIC	CCT	\N	CONFIRMED	-37.68461856	144.60451340	4	11	0101000020A41E0000CD5F7C2C58136240A1B7BA94A1D742C0
199607	VIC4187098	locf2d2a267a354	MYRTLE	STREET	\N	MYRTLE STREET	WINCHELSEA	3241	VIC	ST	\N	CONFIRMED	-38.23359572	144.00020271	4	10	0101000020A41E0000421A1DA9010062405AF1EC76E61D43C0
201106	VIC653423	loc515028b0f98a	HOWES CREEK	ROAD	\N	HOWES CREEK ROAD	MANSFIELD	3722	VIC	RD	\N	CONFIRMED	-37.08665422	146.01470447	4	107	0101000020A41E00002938827578406240EE7A487C178B42C0
201567	VICL3552638	locc5abea08e85d	BRINDABELLA	CHASE	\N	BRINDABELLA CHASE	POINT COOK	3030	VIC	CH	\N	CONFIRMED	-37.90653502	144.76512383	4	24	0101000020A41E0000B067F8E47B18624013CAEB5609F442C0
201765	VICL3557670	loccabf2d0215b8	REMBRANDT	DRIVE	\N	REMBRANDT DRIVE	MADDINGLEY	3340	VIC	DR	\N	CONFIRMED	-37.68671323	144.42911472	4	27	0101000020A41E00003B14CB4EBB0D62404F4A1838E6D742C0
203802	VICL3620952	locabdfa0718385	SILVEREYE	STREET	\N	SILVEREYE STREET	KURUNJANG	3337	VIC	ST	\N	CONFIRMED	-37.65580088	144.58192007	4	21	0101000020A41E000027B1D6169F126240DE248248F1D342C0
206185	VICL4176453	locfd8472c41cbe	HAMILTON	WAY	\N	HAMILTON WAY	ROWVILLE	3178	VIC	WAY	\N	CONFIRMED	-37.91900696	145.22211765	4	11	0101000020A41E0000A95379961B27624089FF2205A2F542C0
\.

-- gnaf_202602.street_aliases: 32 rows
\copy gnaf_202602.street_aliases FROM stdin
41	VIC1930780	CEMETERY	LANE	\N	CEMETERY LANE	SYNONYM
309	VIC1935602	A BECKETT	STREET	\N	A BECKETT STREET	SYNONYM
311	VIC1935604	A'BECKETT	STREET	\N	A'BECKETT STREET	SYNONYM
315	VIC1935609	A'BECKETT	STREET	\N	A'BECKETT STREET	SYNONYM
1301	VIC1952872	GOLF LINKS	AVENUE	\N	GOLF LINKS AVENUE	SYNONYM
1325	VIC1953363	COWRA	AVENUE	EXTENSION	COWRA AVENUE EXTENSION	SYNONYM
2259	VIC1969874	GILBERT	STREET	\N	GILBERT STREET	SYNONYM
2615	VIC1976942	DRAPER	SQUARE	\N	DRAPER SQUARE	SYNONYM
2744	VIC1979663	MALDON NEWSTEAD	ROAD	\N	MALDON NEWSTEAD ROAD	SYNONYM
2930	VIC1983076	HILLVIEW	RISE	\N	HILLVIEW RISE	SYNONYM
2941	VIC1983442	KALYMNA	GRANGE	\N	KALYMNA GRANGE	SYNONYM
3000	VIC1984283	GREENISLAND	AVENUE	\N	GREENISLAND AVENUE	SYNONYM
4070	VIC2003761	NELSON	STREET	\N	NELSON STREET	SYNONYM
4593	VIC2014251	MOONYA	STREET	\N	MOONYA STREET	SYNONYM
4791	VIC2015559	MCCARTHY	ROAD	\N	MCCARTHY ROAD	SYNONYM
4993	VIC2017941	PT COOK	ROAD	\N	PT COOK ROAD	SYNONYM
4997	VIC2017947	PT FORTUNA	ROAD	\N	PT FORTUNA ROAD	SYNONYM
5852	VIC2028446	SPRING	STREET	\N	SPRING STREET	SYNONYM
5972	VIC2030282	STKILDA	ROAD	\N	STKILDA ROAD	SYNONYM
6298	VIC2036742	TOORAK	ROAD	WEST	TOORAK ROAD WEST	SYNONYM
7417	VIC2061938	CALLAGHANS	ROAD	\N	CALLAGHANS ROAD	SYNONYM
7550	VIC2064406	EPSON	ROAD	\N	EPSON ROAD	SYNONYM
7614	VIC2065815	WALLACE	PLACE	\N	WALLACE PLACE	SYNONYM
7860	VIC2069720	WATT	CLOSE	\N	WATT CLOSE	SYNONYM
8042	VIC2073892	LEITCHVILLE PYRAMID	ROAD	\N	LEITCHVILLE PYRAMID ROAD	SYNONYM
8166	VIC2076350	O'CONNELL	STREET	\N	O'CONNELL STREET	SYNONYM
8429	VIC2554240	OTTERY SCRUB	ROAD	\N	OTTERY SCRUB ROAD	SYNONYM
9432	VIC3572139	WEDDERBURN JUCTION EAST	ROAD	\N	WEDDERBURN JUCTION EAST ROAD	SYNONYM
9718	VIC3618602	SABRINA	AVENUE	\N	SABRINA AVENUE	SYNONYM
11020	VIC4127542	4TH	AVENUE	\N	4TH AVENUE	SYNONYM
11519	VIC653423	HOWES CREEK-GOUGHS BAY	ROAD	\N	HOWES CREEK-GOUGHS BAY ROAD	SYNONYM
11520	VIC653423	MANSFIELD-HOWES CREEK	ROAD	\N	MANSFIELD-HOWES CREEK ROAD	SYNONYM
\.

-- gnaf_202602.address_principals: 451 rows
\copy gnaf_202602.address_principals FROM stdin
2487731	GAVIC423917985	VIC2066602	loc9a48431374e1	P	S	\N	\N	UNIT 704	\N	57	\N	BAY	STREET	\N	UNIT 704, 57 BAY STREET	PORT MELBOURNE	3207	VIC	3207	2	A704\\PS500744	20631914110	20631914110	-37.84128419	144.93953230	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E000024C10AA6101E62408F584933AFEB42C0
1542390	GAVIC421107468	VIC1945124	loce42a110faa48	P	\N	\N	\N	\N	\N	10	\N	BATEMAN	STREET	\N	10 BATEMAN STREET	HAMPTON	3188	VIC	3188	2	36\\LP8090	20049510000	20049510000	-37.93198184	145.01610791	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000555BCF48320624009A2512E4BF742C0
3609954	GAVIC419920752	VIC1947379	loc2c4c767ea9b7	P	P	\N	\N	\N	\N	14	\N	BREFFNA	STREET	\N	14 BREFFNA STREET	PRESTON	3072	VIC	3072	1	CM1\\PS525004	20146160000	20146160000	-37.74821083	145.01488403	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A5C212EE7920624077AE5A5FC5DF42C0
3785325	GAVIC425167658	VIC2080683	loc9901d119afda_1	P	S	\N	\N	\N	LEVEL 2	53	57	QUEEN	STREET	\N	LEVEL 2, 53-57 QUEEN STREET	MELBOURNE	3000	VIC	3000	0	1\\TP758232	20664260000	21328660000	-37.81752885	144.96159702	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000981A1D67C51E6240AC240DC9A4E842C0
882568	GAVIC721366499	VIC2024158	loca5de38b84720	P	S	\N	\N	UNIT 1801	\N	36	\N	PROSPECT	STREET	\N	UNIT 1801, 36 PROSPECT STREET	BOX HILL	3128	VIC	3128	2	1801\\PS831941	20587790000	20587790000	-37.81786505	145.11682777	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000446D970DBD2362404D254DCDAFE842C0
934458	GAVIC421548655	VIC2034844	locb53ace4ff1b6	P	\N	\N	\N	\N	\N	81	83	STEPHENSON	STREET	\N	81-83 STEPHENSON STREET	GREAT WESTERN	3374	VIC	3374	2	1\\PS546647	20519280000	20519280000	-37.15033645	142.85439001	FRONTAGE CENTRE SETBACK	2	0101000020A41E000055DFB72957DB6140C8128C393E9342C0
3580062	GAVIC719925941	VIC1953368	loc3319215a0a10	P	S	\N	\N	UNIT 204	LEVEL 2	7	\N	COWRA	STREET	\N	UNIT 204, LEVEL 2, 7 COWRA STREET	BRIGHTON	3186	VIC	3186	0	204\\PS807792	20046460000	20046460000	-37.90494907	145.00724733	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000ABAAC05E3B2062400A19025FD5F342C0
3737183	GAVIC718991138	VIC1944167	loca0398a35cf5e	P	S	\N	\N	UNIT 610	LEVEL 6	28	\N	BOUVERIE	STREET	\N	UNIT 610, LEVEL 6, 28 BOUVERIE STREET	CARLTON	3053	VIC	3053	0	610\\PS720330	20401931000	21320150000	-37.80563395	144.96183795	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A7696160C71E62400EE665031FE742C0
1090488	GAVIC424750944	VIC3374991	loc338a35dd09f0	P	\N	\N	\N	\N	\N	24	\N	FUTURA	AVENUE	\N	24 FUTURA AVENUE	GOLDEN SQUARE	3555	VIC	3555	2	58\\PS645147	20631965560	20631965560	-36.77892429	144.23386480	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F07508D27B07624015CE87CAB36342C0
3242763	GAVIC420583086	VIC1962407	loc39cd317eec9d	P	P	\N	\N	\N	\N	48	\N	CLARINDA	ROAD	\N	48 CLARINDA ROAD	CLARINDA	3169	VIC	3169	1	1\\PS918522	20307330000	20307330000	-37.93092621	145.10002570	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004EC818693323624039780D9728F742C0
1167231	GAVIC423974946	VIC2017947	loca37d9a7b347e	P	\N	COMMODORE ANGLNG BOAT CLB	\N	\N	\N	182	\N	POINT FORTUNA	ROAD	\N	182 POINT FORTUNA ROAD	KIMBOLTON	3551	VIC	3551	1	37H\\PP2879	20217800000	20217800000	-36.88749014	144.53814538	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000FEF2A87C381162404669E346997142C0
2936699	GAVIC421694057	VIC2003128	loc92bf5bc798e7	P	S	\N	\N	UNIT 77	\N	126	\N	RACECOURSE	ROAD	\N	UNIT 77, 126 RACECOURSE ROAD	FLEMINGTON	3031	VIC	3031	2	PC367391	20450811000	20450811000	-37.78690307	144.93719722	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000AB390685FD1D6240D162633DB9E442C0
395143	GAVIC419661586	VIC1940668	loce1597eda1cc3	P	P	\N	\N	\N	\N	30	\N	BARCELONA	STREET	\N	30 BARCELONA STREET	NORLANE	3214	VIC	3214	1	CM\\PS311984	20241680000	20241680000	-38.08284840	144.34360216	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001E01F5C9FE0A62405243C0C69A0A43C0
2649680	GAVIC425169775	VIC2034802	loce11f06c54f46	P	S	\N	\N	UNIT 1	\N	48	\N	STEPHEN	STREET	\N	UNIT 1, 48 STEPHEN STREET	GISBORNE	3437	VIC	3437	2	1\\PS638421	20355352000	20355352000	-37.49016711	144.58434507	FRONTAGE CENTRE SETBACK	2	0101000020A41E000053A76EF4B21262402E83BDCBBDBE42C0
1672039	GAVIC420701723	VIC1942857	locbd7d4fd6b9e7	P	\N	\N	\N	\N	\N	59	\N	CAMPBELL	STREET	\N	59 CAMPBELL STREET	COBURG	3058	VIC	3058	2	1\\TP693857	20468700000	20468700000	-37.75350484	144.96913994	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008471C331031F6240BF96BAD872E042C0
600657	GAVIC421146125	VIC2046096	loc8fef59c1c585	P	\N	\N	\N	\N	\N	36	\N	TADSTAN	DRIVE	\N	36 TADSTAN DRIVE	TULLAMARINE	3043	VIC	3043	2	41\\LP74406	20292910000	20292910000	-37.69411483	144.87903596	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A8860510211C6240614237C1D8D842C0
2499992	GAVIC424795446	VIC2040420	locc2ea2de6af6c	P	S	\N	\N	UNIT 908	FLOOR 9	77	\N	RIVER	STREET	\N	UNIT 908, FLOOR 9, 77 RIVER STREET	SOUTH YARRA	3141	VIC	3141	0	908\\PS617851	20631953570	20631953570	-37.83684594	144.99740670	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F6A974C1EA1F6240920B8CC41DEB42C0
1618753	GAVIC719754089	VIC2007449	locddc4a1bcd8ba	P	S	\N	\N	UNIT 3010	LEVEL 30	8	\N	PEARL RIVER	ROAD	\N	UNIT 3010, LEVEL 30, 8 PEARL RIVER ROAD	DOCKLANDS	3008	VIC	3008	0	3010\\PS728852	20631953180	21313600000	-37.81532063	144.93801394	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BF6FCF35041E624054CD286D5CE842C0
1756076	GAVIC423402710	VIC2018444	loc47e9d5554e9d	P	\N	\N	4	\N	\N	\N	\N	MCFARLANE	ROAD	\N	LOT 4 MCFARLANE ROAD	HAZELWOOD	3840	VIC	3840	0	\N	20631912200	20631912200	-38.30448492	146.34728373	STREET LOCALITY	4	0101000020A41E00000DD9C4F21C4B624039C3A25CF92643C0
3701966	GAVIC719042751	VIC1990305	loc9901d119afda_1	P	S	\N	\N	UNIT 308	\N	108	\N	LITTLE LONSDALE	STREET	\N	UNIT 308, 108 LITTLE LONSDALE STREET	MELBOURNE	3000	VIC	3000	0	\N	20664600000	20664600000	-37.80918104	144.96847178	FRONTAGE CENTRE SETBACK	2	0101000020A41E00005DC687B8FD1E6240F0AB8B3E93E742C0
3887556	GAVIC720296037	VIC1963115	locffd0eebac0eb	P	\N	\N	\N	\N	\N	80A	\N	ELLA	GROVE	\N	80A ELLA GROVE	CHELSEA	3196	VIC	3196	2	2\\PS819538	20324250000	20324250000	-38.04202953	145.12558764	FRONTAGE CENTRE SETBACK	2	0101000020A41E00009ED25ED0042462407B684039610543C0
2604249	GAVIC425367645	VIC3338061	loce25dfc481765	P	S	\N	\N	UNIT 3	\N	40	\N	ROYAL	PARADE	\N	UNIT 3, 40 ROYAL PARADE	KILMORE	3764	VIC	3764	0	B\\PS602264	20631972830	20631972830	-37.29327587	144.93277234	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003BDD6045D91D6240902D4F108AA542C0
3430038	GAVIC719913128	VIC2010068	loc1492a23dbc74	P	S	\N	\N	UNIT 3	\N	10	\N	NORTH	CRESCENT	\N	UNIT 3, 10 NORTH CRESCENT	HEIDELBERG WEST	3081	VIC	3081	2	3\\PS814603	20020210000	20020210000	-37.73923500	145.04487647	FRONTAGE CENTRE SETBACK	2	0101000020A41E00005160C7A06F2162407F87A2409FDE42C0
2428604	GAVIC419688276	VIC1970315	loc3b64e6146ff8	P	S	\N	\N	UNIT 3	\N	460	\N	COMO	PARADE	WEST	UNIT 3, 460 COMO PARADE WEST	MORDIALLOC	3195	VIC	3195	1	3\\RP8465	20316740000	20316740000	-38.00120185	145.08300690	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F41A16FEA7226240EC38D961270043C0
3283875	GAVIC412670644	VIC1969682	locf3eb6fff8056	P	\N	\N	2	\N	\N	\N	\N	GIBB	STREET	\N	LOT 2 GIBB STREET	OXLEY	3678	VIC	3678	0	\N	20572181000	20572181000	-36.43952844	146.38823671	STREET LOCALITY	4	0101000020A41E0000D091646F6C4C62401FBBC977423842C0
1056394	GAVIC424926818	VIC1930780	loc399d9bd46679	P	\N	\N	6	\N	\N	\N	\N	CEMETERY	ROAD	\N	LOT 6 CEMETERY ROAD	TYLDEN	3444	VIC	3444	0	\N	20352921000	20352921000	-37.32195322	144.41435402	STREET LOCALITY	4	0101000020A41E0000B79B5C63420D6240F65E5BC335A942C0
3355296	GAVIC425821887	VIC1956233	loc4858bcc1d912	P	S	\N	\N	UNIT 6	\N	30	32	GRANDVIEW	STREET	\N	UNIT 6, 30-32 GRANDVIEW STREET	GLENROY	3046	VIC	3046	1	6\\PS739781	20473110000	20473110000	-37.70846694	144.91169648	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004EAF189E2C1D624071CC700BAFDA42C0
3877847	GAVIC719523562	VIC1963013	loc9901d119afda_1	P	S	\N	\N	UNIT 6104	LEVEL 61	442	\N	ELIZABETH	STREET	\N	UNIT 6104, LEVEL 61, 442 ELIZABETH STREET	MELBOURNE	3000	VIC	3000	0	6105\\PS728842	20401811000	21328440000	-37.80833027	144.96073354	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000DCF4354BE1E62402802C55D77E742C0
917798	GAVIC719439819	VIC2043038	locfa38377aaf29	P	\N	\N	\N	\N	\N	68	\N	SWAMP	LANE	\N	68 SWAMP LANE	DEDERANG	3691	VIC	3691	0	19~6\\PP2863	20001250000	20001250000	-36.47912795	147.03927940	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000024DDFC641616240BDEC8D10543D42C0
49755	GAVIC424754823	VIC3566690	locbf553ce41d73	P	P	\N	\N	\N	\N	305	\N	KIRWANS BRIDGE	ROAD	\N	305 KIRWANS BRIDGE ROAD	KIRWANS BRIDGE	3608	VIC	3608	2	1\\TP124821	20631945640	20631945640	-36.75186307	145.16888267	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E00005B10A17C672562402E5C900C3D6042C0
338488	GAVIC420418242	VIC2014245	loc712bc92c5924	P	\N	\N	\N	\N	\N	4	\N	MOONSTONE	WALK	\N	4 MOONSTONE WALK	BUNDOORA	3083	VIC	3083	2	10\\PS328980	20155310000	20155310000	-37.71338684	145.05646293	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002AB9588BCE21624030998D4250DB42C0
32014	GAVIC424581128	VIC1975631	loccd13bd88b567	P	S	\N	\N	SHOP 1	FLOOR 1	1880	\N	FERNTREE GULLY	ROAD	\N	SHOP 1, FLOOR 1, 1880 FERNTREE GULLY ROAD	FERNTREE GULLY	3156	VIC	3156	0	1\\LP53936	20330854000	20330854000	-37.88333706	145.27714110	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000141C0357DE286240BC05543011F142C0
141873	GAVIC425085888	VIC3570907	loc82baa1179308	P	\N	\N	\N	\N	\N	2	\N	LAVIT	LANE	\N	2 LAVIT LANE	PAKENHAM	3810	VIC	3810	0	\N	20631925510	21308310000	-38.05568418	145.49596135	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008F4A56EADE2F62409600C2A8200743C0
2503706	GAVIC419682437	VIC2011064	loca2fd80ef71d3	P	\N	DUNROAMIN	\N	\N	\N	179	\N	MOFFATS	ROAD	\N	179 MOFFATS ROAD	DEREEL	3352	VIC	3352	2	45\\LP110098	20203412000	20203412000	-37.83920614	143.79257358	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000C2B844C35CF9614082F3561B6BEB42C0
3292397	GAVIC412378116	VIC1985993	locfe955a87410d	P	S	\N	\N	UNIT 1	\N	81	\N	GREY	STREET	\N	UNIT 1, 81 GREY STREET	ST KILDA	3182	VIC	3182	2	1\\PS618095	20528570000	20528570000	-37.86242684	144.97975428	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000EAD6A5255A1F62400E7FB00064EE42C0
651444	GAVIC421304891	VIC2018477	locd755ccb7197e	P	\N	\N	\N	\N	\N	61	\N	MCFEES	ROAD	\N	61 MCFEES ROAD	DANDENONG NORTH	3175	VIC	3175	2	5\\LP72611	20222990000	20222990000	-37.96374586	145.21388388	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BBB70123D82662407E2D3B065CFB42C0
759481	GAVIC720913095	VIC2078131	locc672a234fa5a	P	S	ANNUAL SITE 72	\N	SITE 72	\N	1	\N	MOUNTJOY	PARADE	\N	SITE 72, 1 MOUNTJOY PARADE	LORNE	3232	VIC	3232	0	P\\PP5478	20563100000	20563100000	-38.53454590	143.97236401	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E00003DD8209B1DFF6140FE5A03006C4443C0
236845	GAVIC419854308	VIC1930917	loc7f158a48110c	P	\N	\N	\N	\N	\N	27	\N	CENTRAL	AVENUE	\N	27 CENTRAL AVENUE	BLAIRGOWRIE	3942	VIC	3942	2	14\\LP6027	20488530000	20488530000	-38.36497883	144.76053791	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002F5A9953561862408A4A55A0B72E43C0
3621379	GAVIC721374676	VIC1933214	loc5c27e3f22fc1	P	S	\N	\N	UNIT 102	\N	8	\N	BILLS	STREET	\N	UNIT 102, 8 BILLS STREET	HAWTHORN	3122	VIC	3122	2	PC381123	20071660000	20071660000	-37.83841614	145.04121525	FRONTAGE CENTRE SETBACK	2	0101000020A41E000016DBA4A25121624089DE563851EB42C0
3452871	GAVIC411968423	VIC1981503	loce01ddbd8c8e5	P	S	\N	\N	UNIT 5	\N	362	\N	HIGH	STREET	\N	UNIT 5, 362 HIGH STREET	NAGAMBIE	3608	VIC	3608	2	1\\PS715833	20631996680	20631996680	-36.78140824	145.15540573	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000C1FE6F15F9246240FDCF692F056442C0
1926708	GAVIC422161681	VIC1994400	loc913bf4728c4e	P	P	\N	\N	\N	\N	15A	\N	KINTORE	STREET	\N	15A KINTORE STREET	CAMBERWELL	3124	VIC	3124	1	1\\RP5526	20063430000	20063430000	-37.82256113	145.06104233	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B1600B0FF4216240C827E0AE49E942C0
2680400	GAVIC425742442	VIC2079106	loc780d4ed4ca46	P	S	\N	\N	UNIT 2	\N	15	\N	SLADEN	STREET	\N	UNIT 2, 15 SLADEN STREET	HAMLYN HEIGHTS	3215	VIC	3215	0	91\\LP23927	20244100000	20244100000	-38.12673070	144.32061091	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001BA6CF71420A624019F329B6381043C0
2868526	GAVIC425309480	VIC1932338	loc656f84726510	P	S	\N	\N	UNIT 4	\N	40	\N	CHALEYER	STREET	\N	UNIT 4, 40 CHALEYER STREET	RESERVOIR	3073	VIC	3073	2	4\\PS719130	20151200000	20151200000	-37.72730375	145.02356726	FRONTAGE CENTRE SETBACK	2	0101000020A41E00009A5E2010C12062400B410E4A18DD42C0
2930507	GAVIC424285382	VIC2053297	loc11b2a92fb5f0	P	S	\N	\N	UNIT 14	\N	47	\N	WAXMAN	PARADE	\N	UNIT 14, 47 WAXMAN PARADE	BRUNSWICK WEST	3055	VIC	3055	2	1\\PS705721	20464870000	20464870000	-37.75970427	144.93704183	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B0DA253FFC1D62400A2451FD3DE142C0
1345292	GAVIC422086500	VIC1959477	loc34a55c4d0462	P	P	\N	\N	\N	\N	49	\N	CURRUNGHI	COURT	\N	49 CURRUNGHI COURT	ST ALBANS	3021	VIC	3021	1	1\\PS333157	20086810000	20086810000	-37.75222183	144.82657597	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E7D9724F731A6240F9970FCE48E042C0
3464119	GAVIC421708673	VIC1999163	loc46443686a430	P	P	\N	\N	\N	\N	68	\N	LACHLAN	ROAD	\N	68 LACHLAN ROAD	SUNSHINE WEST	3020	VIC	3020	1	100\\LP12795	20093470000	20093470000	-37.79205213	144.80946570	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007B979C24E7196240E089D5F661E542C0
1748699	GAVIC420886416	VIC2065745	loc1fbfb471eb7c	P	\N	\N	\N	\N	\N	2	\N	DESMOND	CRESCENT	\N	2 DESMOND CRESCENT	ROMSEY	3434	VIC	3434	2	1251\\LP206571	20354040000	20354040000	-37.36058091	144.73283607	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000553FA164731762408701E88327AE42C0
2810289	GAVIC421739766	VIC2040693	loc656f84726510	P	P	\N	\N	\N	\N	39	\N	SHAND	ROAD	\N	39 SHAND ROAD	RESERVOIR	3073	VIC	3073	2	1\\PS807551	20147990000	20147990000	-37.72071175	145.01962355	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000682F91C1A0206240E50B5A4840DC42C0
3477204	GAVIC422138212	VIC1970192	loc82b861dfb765	P	S	\N	\N	UNIT 3	\N	23	\N	COMAS	GROVE	\N	UNIT 3, 23 COMAS GROVE	THORNBURY	3071	VIC	3071	1	3\\PS632362	20631903760	20631903760	-37.75514597	144.98428438	FRONTAGE CENTRE SETBACK	2	0101000020A41E000009C2F4417F1F6240986D869FA8E042C0
3027455	GAVIC420051005	VIC1961381	loc6413994c2b24	P	S	\N	\N	UNIT 3	\N	115	\N	DANDENONG	ROAD	EAST	UNIT 3, 115 DANDENONG ROAD EAST	FRANKSTON	3199	VIC	3199	2	3\\RP14278	20172140000	20172140000	-38.13116385	145.13202287	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002B9F0688392462406F151FFAC91043C0
1489621	GAVIC419679289	VIC2051667	locd6f79866f950	P	P	\N	\N	\N	\N	51	\N	RUSHDALE	STREET	\N	51 RUSHDALE STREET	KNOXFIELD	3180	VIC	3180	1	27\\LP120227	20338390000	20338390000	-37.89960386	145.25627688	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000454A926B332862401607233826F342C0
3697434	GAVIC425367514	VIC2025971	loc9901d119afda_2	P	S	MONARC APARTMENTS	\N	UNIT 305	\N	74	\N	QUEENS	ROAD	\N	UNIT 305, 74 QUEENS ROAD	MELBOURNE	3004	VIC	3004	2	305\\PS641029	20522900000	21329200000	-37.85228554	144.97922971	FRONTAGE CENTRE SETBACK	2	0101000020A41E000017778BD9551F6240AC934CB117ED42C0
1083398	GAVIC422119571	VIC2054286	loc913bf4728c4e	P	P	\N	\N	\N	\N	1	\N	WEBSTER	STREET	\N	1 WEBSTER STREET	CAMBERWELL	3124	VIC	3124	1	2\\PS332618	20065710000	20065710000	-37.83619744	145.09397738	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003EB5D9DC0123624043E6888408EB42C0
1664178	GAVIC420118258	VIC1951821	loc6ae7eaa3c1f3	P	\N	\N	\N	\N	\N	8	\N	BROOK	CRESCENT	\N	8 BROOK CRESCENT	BOX HILL SOUTH	3128	VIC	3128	2	1\\TP548176	20593300000	20593300000	-37.84329385	145.12195891	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FC3C5F16E72362407F55890DF1EB42C0
3770075	GAVIC423910455	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 3504	\N	368	\N	ST KILDA	ROAD	\N	UNIT 3504, 368 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	2	3504\\PS419703	20533110000	20533110000	-37.83180171	144.97111975	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FED7B969131F62407B9A7A7A78EA42C0
2678557	GAVIC424589454	VIC3353446	locc5abea08e85d	P	\N	\N	\N	\N	\N	28	\N	TARCOOLA	CRESCENT	\N	28 TARCOOLA CRESCENT	POINT COOK	3030	VIC	3030	2	1939\\PS511700	20631941560	20631941560	-37.90628083	144.76763784	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001B3F3B7D90186240BEEB9E0201F442C0
137879	GAVIC721038984	VIC4127542	loc956fa85c7b0c	P	S	CAMPSITE 42	\N	\N	\N	42	\N	FOURTH	AVENUE	\N	42 FOURTH AVENUE	PORTARLINGTON	3223	VIC	3223	0	73C\\PP5647	20631995870	20631995870	-38.11139145	144.64116180	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000394EC06584146240EA663513420E43C0
1746679	GAVIC720284643	VIC3618044	loc098e933e1fd2	P	S	\N	\N	UNIT 22	\N	278	280	TORQUAY	ROAD	\N	UNIT 22, 278-280 TORQUAY ROAD	GROVEDALE	3216	VIC	3216	2	8\\PS829165	20251730000	20251730000	-38.20607026	144.34093461	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C900B3EFE80A624069B0A182601A43C0
3058260	GAVIC423716042	VIC1951022	locc098f71b2faf	P	\N	COLIN MCCLELLAND AND ASSOCIATES	\N	\N	\N	201	\N	ARMSTRONG	STREET	NORTH	201 ARMSTRONG STREET NORTH	SOLDIERS HILL	3350	VIC	3350	2	2\\PS448234	20008090000	20008090000	-37.55606340	143.85708571	FRONTAGE CENTRE SETBACK	2	0101000020A41E000035CA023F6DFB614054C0E2152DC742C0
3768101	GAVIC423490030	VIC2030282	loc9901d119afda_2	P	S	\N	\N	CARSPACE 137	\N	431	\N	ST KILDA	ROAD	\N	CARSPACE 137, 431 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	0	137\\RP18468	20631975640	20631975640	-37.83862075	144.97687491	FRONTAGE CENTRE SETBACK	2	0101000020A41E000074D72B8F421F62409D7FBBEC57EB42C0
3893424	GAVIC721290639	VIC1990305	loc9901d119afda_1	P	S	\N	\N	UNIT 1907	LEVEL 19	633	\N	LITTLE LONSDALE	STREET	\N	UNIT 1907, LEVEL 19, 633 LITTLE LONSDALE STREET	MELBOURNE	3000	VIC	3000	0	1907C\\PS746092	20664921000	20664921000	-37.81403592	144.95327786	FRONTAGE CENTRE SETBACK	2	0101000020A41E00006D169240811E6240AB153B5432E842C0
1896627	GAVIC423648868	VIC2044273	locddc4a1bcd8ba	P	S	\N	\N	UNIT 1103	LEVEL 11	60	\N	SIDDELEY	STREET	\N	UNIT 1103, LEVEL 11, 60 SIDDELEY STREET	DOCKLANDS	3008	VIC	3008	0	1103\\PS448830	20395090000	20395090000	-37.82267981	144.95252330	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B2C524127B1E6240C6836F924DE942C0
593118	GAVIC420533207	VIC1978444	loc7ab22202aac3	P	\N	\N	\N	\N	\N	34	\N	HENRY	STREET	\N	34 HENRY STREET	DONCASTER	3108	VIC	3108	2	30\\LP143954	20359680000	20359680000	-37.77534685	145.13164391	FRONTAGE CENTRE SETBACK	2	0101000020A41E00005D054A6D362462403FE7C9903EE342C0
3879528	GAVIC720520900	VIC1990305	loc9901d119afda_1	P	S	\N	\N	CARSPACE 6027Z	\N	659	\N	LITTLE LONSDALE	STREET	\N	CARSPACE 6027Z, 659 LITTLE LONSDALE STREET	MELBOURNE	3000	VIC	3000	0	6027Z\\PS746092	20664921000	20664921000	-37.81421733	144.95248254	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F4E9A9BC7A1E6240DD17024638E842C0
146370	GAVIC425311495	VIC2053844	locc605118e951a	P	S	\N	\N	UNIT 3	\N	8	\N	DUDLEY	STREET	\N	UNIT 3, 8 DUDLEY STREET	WALLAN	3756	VIC	3756	2	3\\PS707077	20417390000	20417390000	-37.41798163	144.97378966	FRONTAGE CENTRE SETBACK	2	0101000020A41E000041DCEE48291F6240E2960B6C80B542C0
3482220	GAVIC420178764	VIC2004921	loc786911d8fa57	P	P	\N	\N	\N	\N	11	\N	MIDDLEFIELD	DRIVE	\N	11 MIDDLEFIELD DRIVE	BLACKBURN NORTH	3130	VIC	3130	1	CM1\\PS548498	20600520000	20600520000	-37.80161910	145.15254066	FRONTAGE CENTRE SETBACK	2	0101000020A41E00005440F39CE1246240AB2C65749BE642C0
3685838	GAVIC425741622	VIC3572604	loc9901d119afda_1	P	S	\N	\N	CARSPACE 2166Z	\N	11	\N	ROSE	LANE	\N	CARSPACE 2166Z, 11 ROSE LANE	MELBOURNE	3000	VIC	3000	0	2166Z\\PS633275	20664901000	20664901000	-37.81543898	144.95408699	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000DA7270E1871E6240E77DF34D60E842C0
1666490	GAVIC423402509	VIC2015559	loc0e534d470df9	P	\N	\N	77	\N	\N	\N	\N	MCCARTHY	DRIVE	\N	LOT 77 MCCARTHY DRIVE	HEATHCOTE	3523	VIC	3523	0	\N	20216820000	20216820000	-36.95556660	144.78260095	STREET LOCALITY	4	0101000020A41E000031C225110B1962403013A001507A42C0
3237692	GAVIC424879721	VIC1984283	loc5100fc96abff	P	S	\N	\N	UNIT 3	\N	50	\N	GREEN ISLAND	AVENUE	\N	UNIT 3, 50 GREEN ISLAND AVENUE	MOUNT MARTHA	3934	VIC	3934	2	3\\PS642200	20631968150	20631968150	-38.24811862	145.04324942	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000128F9B4C62216240DE36D759C21F43C0
1456008	GAVIC424785567	VIC3353866	loc29841cc6d6f1	P	\N	\N	\N	\N	\N	38	\N	MANOOKA	ROAD	\N	38 MANOOKA ROAD	BROOKFIELD	3338	VIC	3338	2	1611\\PS638308	20631953690	20631953690	-37.69778807	144.54173615	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F3E90CE7551162403018961E51D942C0
2582133	GAVIC420538231	VIC1969882	loc2c9ce0acd6de	P	\N	\N	\N	\N	\N	8	\N	GILBERT	STREET	\N	8 GILBERT STREET	ST LEONARDS	3223	VIC	3223	2	13\\LP43093	20259380000	20259380000	-38.18351371	144.71298395	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000557AB7C3D0166240A86893607D1743C0
1948037	GAVIC419754099	VIC2079446	loc62ed665318da	P	\N	\N	\N	\N	\N	32	\N	OSWALD	STREET	\N	32 OSWALD STREET	KYABRAM	3620	VIC	3620	2	1\\TP428890	20097170000	20097170000	-36.31143352	145.05301034	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CB94BD42B22162409BA3B70DDD2742C0
780099	GAVIC423943682	VIC2032237	locf065e41cfac9	P	S	\N	\N	UNIT 2	\N	1A	\N	THOROGOOD	COURT	\N	UNIT 2, 1A THOROGOOD COURT	TAYLORS LAKES	3038	VIC	3038	2	2\\PS606091	20076780000	20076780000	-37.70673193	144.77974789	FRONTAGE CENTRE SETBACK	2	0101000020A41E00009AD5D8B1F3186240C9311F3176DA42C0
2414270	GAVIC424676885	VIC2007474	locc586266ef8cc	P	P	\N	\N	\N	\N	104	\N	PEARSON	STREET	\N	104 PEARSON STREET	SALE	3850	VIC	3850	2	1\\PS918970	20584440000	20584440000	-38.10435588	147.06264578	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A30AB9310162624066DF91885B0D43C0
2279464	GAVIC423509973	VIC2013030	loc46b3ff1e6b9a	P	S	\N	\N	UNIT 1	\N	9	\N	NURLENDI	ROAD	\N	UNIT 1, 9 NURLENDI ROAD	VERMONT	3133	VIC	3133	2	1\\PS529260	20599410000	20599410000	-37.83764050	145.19454599	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C61383B8392662400DA7CCCD37EB42C0
617017	GAVIC721504260	VIC2004950	locf16910f90fb9	P	\N	\N	\N	\N	\N	9B	\N	MIDDLETON	STREET	\N	9B MIDDLETON STREET	HIGHETT	3190	VIC	3190	0	42\\LP12181	20051100000	20051100000	-37.95146084	145.03897191	FRONTAGE CENTRE SETBACK	2	0101000020A41E000034DD04423F216240C39C0378C9F942C0
1191142	GAVIC423748775	VIC1962844	loc17a18f5ff3a6	P	\N	\N	\N	\N	\N	8	\N	DARLEITH	TERRACE	\N	8 DARLEITH TERRACE	CAROLINE SPRINGS	3023	VIC	3023	2	356\\PS533498	20631961150	20631961150	-37.71861448	144.73451975	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008410902F811762401A042D8FFBDB42C0
2239601	GAVIC420674743	VIC2032116	locc586266ef8cc	P	P	\N	\N	\N	\N	112	114	THOMSON	STREET	\N	112-114 THOMSON STREET	SALE	3850	VIC	3850	0	1\\SP25881	20584160000	20584160000	-38.10053998	147.05952448	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002ADDE19FE76162402F057B7EDE0C43C0
1361845	GAVIC411087566	VIC1953679	loc1b5a0e70afd4	P	S	\N	\N	FLAT 14	\N	5	\N	DUKE	STREET	\N	FLAT 14, 5 DUKE STREET	CAULFIELD SOUTH	3162	VIC	3162	2	14\\PS349838	20192490000	20192490000	-37.89180933	145.01510717	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B92208C27B206240104FE1CE26F242C0
3254415	GAVIC425512108	VIC1945221	loc0b8afd71fce1	P	S	\N	\N	UNIT 1304	LEVEL 13	53	\N	BATMAN	STREET	\N	UNIT 1304, LEVEL 13, 53 BATMAN STREET	WEST MELBOURNE	3003	VIC	3003	0	1304\\PS703332	20401400000	21339200000	-37.81094876	144.95151565	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003BCCF2D0721E62404477412BCDE742C0
981734	GAVIC420648830	VIC2036451	loc2508c9e5a93c	P	\N	\N	\N	\N	\N	41	\N	STOKES	LANE	WEST	41 STOKES LANE WEST	RIDDELLS CREEK	3431	VIC	3431	1	2\\LP144550	20354290000	20354290000	-37.46671163	144.69508343	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000EEFA9A1F3E166240A5C1E934BDBB42C0
2066682	GAVIC420870124	VIC1972025	loc94fdc21035b3	P	\N	\N	\N	\N	\N	67	69	DILLON	STREET	\N	67-69 DILLON STREET	ULTIMA	3544	VIC	3544	1	1~13\\LP6006	20567050000	20567050000	-35.47597811	143.26832660	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B374AA2196E86140EC07C8D9ECBC41C0
3875253	GAVIC719921421	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 216	\N	450	\N	ST KILDA	ROAD	\N	UNIT 216, 450 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	2	216\\PS738892	20631933390	20631933390	-37.83867611	144.97599334	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003E8D62563B1F6240793120BD59EB42C0
3378799	GAVIC422024006	VIC2028446	loc76dea039b41f	P	P	\N	\N	\N	\N	7	\N	SPRING	ROAD	\N	7 SPRING ROAD	MALVERN	3144	VIC	3144	2	7\\PS714394	20555660000	20555660000	-37.85515594	145.03415549	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000EC1041CD17216240DCA3F5BF75ED42C0
2058893	GAVIC424282372	VIC2997584	loceac5d85ea01d	P	\N	\N	\N	\N	\N	6	\N	NARUNG	WAY	\N	6 NARUNG WAY	WYNDHAM VALE	3024	VIC	3024	2	411\\PS510502	20635922000	20635922000	-37.88539910	144.61177349	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008383FFA5931362403434F9C154F142C0
209144	GAVIC721915145	VIC4187098	locf2d2a267a354	P	\N	\N	\N	\N	\N	8	\N	MYRTLE	STREET	\N	8 MYRTLE STREET	WINCHELSEA	3241	VIC	3241	1	109\\PS918241	20562210000	20562210000	-38.23372644	144.00019719	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003C93899D0100624058017CBFEA1D43C0
1253365	GAVIC421481149	VIC2061406	loc656f84726510	P	\N	\N	\N	\N	\N	25	\N	WILKINSON	STREET	\N	25 WILKINSON STREET	RESERVOIR	3073	VIC	3073	2	1\\PS600500	20146170000	20146170000	-37.72591659	145.01737789	FRONTAGE CENTRE SETBACK	2	0101000020A41E000027A7135C8E20624040D6B6D5EADC42C0
242130	GAVIC420108368	VIC2009968	loc7a8164839d54	P	S	\N	\N	\N	\N	10B	\N	NORMAN	STREET	\N	10B NORMAN STREET	DONCASTER EAST	3109	VIC	3109	0	1\\PS338154	20361550000	20361550000	-37.78618585	145.14758191	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CD9DB2FDB8246240FB29E9BCA1E442C0
1062761	GAVIC719528632	VIC3621616	loc1b271c01e3dc	P	\N	\N	\N	\N	\N	17	\N	GUARDIAN	STREET	\N	17 GUARDIAN STREET	MICKLEHAM	3064	VIC	3064	2	710\\PS805186	20301030000	21342850000	-37.54162868	144.90398265	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000D8BC056DED1C62407C96AD1654C542C0
169669	GAVIC424895492	VIC3136743	locb48ce003b11e	P	\N	\N	22	\N	\N	\N	\N	OSCAR	DRIVE	\N	LOT 22 OSCAR DRIVE	MARONG	3515	VIC	3515	0	\N	20631933080	20631933080	-36.72816437	144.13024980	STREET LOCALITY	4	0101000020A41E0000F0E9A0012B04624098A1757D345D42C0
2076894	GAVIC420323810	VIC2058977	locadc5cabaa80e	P	S	\N	\N	UNIT 5	\N	3	5	VALENCY	ROAD	\N	UNIT 5, 3-5 VALENCY ROAD	GLEN IRIS	3146	VIC	3146	2	1\\PS847991	20631925250	20631925250	-37.85679108	145.05291414	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007999FE78B1216240610D8254ABED42C0
3705661	GAVIC423910551	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 5146	\N	368	\N	ST KILDA	ROAD	\N	UNIT 5146, 368 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	0	5146\\PS419703	20533110000	20533110000	-37.83180171	144.97111975	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FED7B969131F62407B9A7A7A78EA42C0
1712348	GAVIC421042152	VIC2079635	loc7c934a667999	P	\N	\N	\N	\N	\N	4	\N	ROSS	STREET	\N	4 ROSS STREET	HASTINGS	3915	VIC	3915	2	55\\LP91242	20479940000	20479940000	-38.31542186	145.18953684	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FD2590AF102662405E9256BE5F2843C0
2001243	GAVIC425277959	VIC1990396	loc31f384e524fe	P	S	\N	\N	UNIT 133AS	\N	50	\N	HAIG	STREET	\N	UNIT 133AS, 50 HAIG STREET	SOUTHBANK	3006	VIC	3006	0	133A\\PS629585	20631981920	20631981920	-37.82686811	144.95707987	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000EBA9F665A01E6240154771D0D6E942C0
1155864	GAVIC419640745	VIC2054946	loc0a03ed3531fd	P	\N	\N	\N	\N	\N	71	\N	BERNARD	STREET	\N	71 BERNARD STREET	CHELTENHAM	3192	VIC	3192	2	49\\LP40376	20308190000	20308190000	-37.95367685	145.06666090	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000802D0A1622226240E5D9401512FA42C0
3235564	GAVIC425013948	VIC1961385	loc2d817b7080e2	P	S	\N	\N	UNIT 312	FLOOR 3	839	\N	DANDENONG	ROAD	\N	UNIT 312, FLOOR 3, 839 DANDENONG ROAD	MALVERN EAST	3145	VIC	3145	0	312\\PS629876	20554564000	20554564000	-37.87483964	145.04077496	FRONTAGE CENTRE SETBACK	2	0101000020A41E000043F649074E216240AF85CDBEFAEF42C0
1385578	GAVIC720523963	VIC3559217	loc64c822b0bad5	P	\N	\N	\N	\N	\N	42	\N	LANSELL	AVENUE	\N	42 LANSELL AVENUE	OFFICER	3809	VIC	3809	1	22\\PS836963	20631951110	21311400000	-38.06293073	145.42716137	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007748524EAB2D6240B7A1391D0E0843C0
2827533	GAVIC425820590	VIC2064408	loc656f84726510	P	S	\N	\N	UNIT 3	\N	2	\N	EPSTEIN	STREET	\N	UNIT 3, 2 EPSTEIN STREET	RESERVOIR	3073	VIC	3073	2	3\\PS738693	20148320000	20148320000	-37.71063418	144.99333331	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000470FF062C91F62408842910FF6DA42C0
1693283	GAVIC721425406	VIC3630043	loce16236caf708	P	\N	\N	\N	\N	\N	22	\N	HOLLANDER	STREET	\N	22 HOLLANDER STREET	LARA	3212	VIC	3212	1	128\\PS913039	20242060000	20242060000	-38.01736342	144.36216360	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A7391ED8960B6240FB85ECF6380243C0
98440	GAVIC423991217	VIC2554240	loc532c3dac4248	P	\N	\N	19	\N	\N	\N	\N	OTTREYS SCRUB	ROAD	\N	LOT 19 OTTREYS SCRUB ROAD	WALMER	3463	VIC	3463	0	\N	20506221000	20506221000	-36.98874826	144.18152888	STREET LOCALITY	4	0101000020A41E0000255CA715CF056240A556904D8F7E42C0
920350	GAVIC721549117	VIC2044273	locddc4a1bcd8ba	P	S	\N	\N	UNIT 1707	LEVEL 17	7	\N	SIDDELEY	STREET	\N	UNIT 1707, LEVEL 17, 7 SIDDELEY STREET	DOCKLANDS	3008	VIC	3008	0	S6\\PS644635	20394823000	20394823000	-37.82154241	144.95444368	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002AEF78CD8A1E62400F9D3B4D28E942C0
3680232	GAVIC420749468	VIC1977358	locc81a6ec90a1b	P	P	\N	\N	\N	\N	281	\N	JETTY	ROAD	\N	281 JETTY ROAD	ROSEBUD	3939	VIC	3939	1	CM1\\PS820041	20484580000	20484580000	-38.37942785	144.91246400	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E0D8B3E7321D624086787F17913043C0
1918525	GAVIC721162609	VIC1962976	locfd8472c41cbe	P	S	\N	\N	UNIT 2	\N	8	\N	ELIZABETH	COURT	\N	UNIT 2, 8 ELIZABETH COURT	ROWVILLE	3178	VIC	3178	2	2\\PS901024	20338940000	20338940000	-37.91936213	145.23153380	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000655D92B968276240F5C384A8ADF542C0
3620868	GAVIC422289520	VIC1963136	loc8f498b475ec6	P	\N	\N	\N	\N	\N	18	\N	ELLAVALE	DRIVE	\N	18 ELLAVALE DRIVE	TRARALGON EAST	3844	VIC	3844	2	41\\PS448339	20348770000	20348770000	-38.19945322	146.56532248	FRONTAGE CENTRE SETBACK	2	0101000020A41E000065692B1F17526240AF7DE0AE871943C0
1692607	GAVIC421059470	VIC2072594	loc37efd432abe4	P	\N	\N	\N	\N	\N	15	\N	TINARRA	COURT	\N	15 TINARRA COURT	WANTIRNA SOUTH	3152	VIC	3152	2	75\\LP146524	20333752000	20333752000	-37.86998686	145.21695789	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001845AC51F12662402AD3BBBA5BEF42C0
1475826	GAVIC420100287	VIC1940808	loca1b6ce72e35a	P	P	\N	\N	\N	\N	10	12	BOND	STREET	\N	10-12 BOND STREET	MOUNT WAVERLEY	3149	VIC	3149	0	1\\SP27650	20440860000	20440860000	-37.88006953	145.13832838	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000AD86A32F6D2462402EC74C1EA6F042C0
3481810	GAVIC425774710	VIC1935251	loce48c38ae2d6a	P	S	\N	\N	UNIT 110	\N	8	\N	BURNLEY	STREET	\N	UNIT 110, 8 BURNLEY STREET	RICHMOND	3121	VIC	3121	2	110E\\PS631302	20631952760	20631952760	-37.81159295	145.00952113	FRONTAGE CENTRE SETBACK	2	0101000020A41E000012BF41FF4D20624003F51C47E2E742C0
2397878	GAVIC419660068	VIC1940488	locd06d20cbea22	P	\N	\N	\N	\N	\N	10	\N	BANNISTER	STREET	\N	10 BANNISTER STREET	NORTH BENDIGO	3550	VIC	3550	2	1\\PS615811	20203780000	20203780000	-36.74546263	144.27939626	FRONTAGE CENTRE SETBACK	2	0101000020A41E000064EA6CD0F0086240BD1EC8516B5F42C0
3529566	GAVIC425084593	VIC1983076	loc630ef4fec09d	P	S	\N	\N	UNIT 1	\N	39	\N	HILL VIEW	RISE	\N	UNIT 1, 39 HILL VIEW RISE	GISBORNE SOUTH	3437	VIC	3437	0	33\\LP110304	20356110000	20356110000	-37.54800545	144.63756583	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B59C74F066146240CFE3E60A25C642C0
156603	GAVIC721914294	VIC4111949	locffa1c8993b70	P	\N	\N	\N	\N	\N	20	\N	TRIBE	STREET	\N	20 TRIBE STREET	MAMBOURIN	3024	VIC	3024	0	27040\\PS832163	20636071700	21333250000	-37.89035611	144.58409748	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000D5C832EDB0126240341F6330F7F142C0
3692192	GAVIC412739960	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 106	\N	620	\N	ST KILDA	ROAD	\N	UNIT 106, 620 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	1	106\\RP18567	20528120000	20528120000	-37.85282693	144.98115145	FRONTAGE CENTRE SETBACK	2	0101000020A41E000089C5B997651F6240C1BFCE6E29ED42C0
730947	GAVIC419676903	VIC1948301	loc86dc9bf35404	P	P	\N	\N	\N	\N	52	\N	BEDDOE	AVENUE	\N	52 BEDDOE AVENUE	CLAYTON	3168	VIC	3168	1	CM1\\PS706305	20631936790	20631936790	-37.91164390	145.12807186	FRONTAGE CENTRE SETBACK	2	0101000020A41E00009D47282A19246240880C50BFB0F442C0
522107	GAVIC421219047	VIC1969439	loc9b20cd160517	P	\N	\N	\N	\N	\N	16	\N	EVANS	STREET	\N	16 EVANS STREET	CHADSTONE	3148	VIC	3148	2	2\\PS409121	20426770000	20426770000	-37.88350685	145.09827891	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C50AD019252362406045A1C016F142C0
2439542	GAVIC412089403	VIC2080341	loc12c0177d3d38	P	S	\N	\N	\N	\N	14	\N	SOMERSET	STREET	\N	14 SOMERSET STREET	PASCOE VALE	3044	VIC	3044	2	2\\PS502102	20467730000	20467730000	-37.73040617	144.92642616	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007C6B7948A51D62402B790AF37DDD42C0
3789289	GAVIC719608433	VIC2025971	loc9901d119afda_2	P	S	\N	\N	UNIT 1408	\N	12	\N	QUEENS	ROAD	\N	UNIT 1408, 12 QUEENS ROAD	MELBOURNE	3004	VIC	3004	2	1408\\PS726142	20533300000	21331550000	-37.83877571	144.97430770	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B67757872D1F62408990A1005DEB42C0
2582876	GAVIC425274073	VIC2059743	loc31f384e524fe	P	S	\N	\N	UNIT 4005	LEVEL 40	241	\N	CITY	ROAD	\N	UNIT 4005, LEVEL 40, 241 CITY ROAD	SOUTHBANK	3006	VIC	3006	1	4005\\PS638212	20631945480	21311300000	-37.82639623	144.95991751	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000D909EDA4B71E6240A0B1065AC7E942C0
3561422	GAVIC721089117	VIC2028859	loc0b665c0fe535	P	S	CAMPSITE 150	\N	SITE 150	\N	15	\N	THE ESPLANADE	\N	\N	SITE 150, 15 THE ESPLANADE	OCEAN GROVE	3226	VIC	3226	0	61\\LP1857	20258850000	20258850000	-38.26980689	144.51664265	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E000000AF2A56881062408A643C08892243C0
3338544	GAVIC425703440	VIC2055433	locc25e0bed112f	P	S	LIFESTYLE CHELSEA HEIGHTS	\N	UNIT 162	\N	29	\N	WELLS	ROAD	\N	UNIT 162, 29 WELLS ROAD	CHELSEA HEIGHTS	3196	VIC	3196	2	2\\PS646783	20631905500	20631905500	-38.03119682	145.13471236	FRONTAGE CENTRE SETBACK	2	0101000020A41E000025924B904F246240D1D1E441FE0343C0
2744468	GAVIC719244724	VIC2052113	loc9fe59dbd0874	P	S	\N	\N	SHOP 7	\N	945	\N	SOUTH GIPPSLAND	HIGHWAY	\N	SHOP 7, 945 SOUTH GIPPSLAND HIGHWAY	CRANBOURNE NORTH	3977	VIC	3977	0	4\\PS611693	20631955290	20631955290	-38.07502010	145.27250387	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000DF35095AB8286240760536429A0943C0
608939	GAVIC419908615	VIC1976052	locc67851215f08	P	\N	\N	\N	\N	\N	11	\N	GOLDEN ASH	COURT	\N	11 GOLDEN ASH COURT	MEADOW HEIGHTS	3048	VIC	3048	2	8\\PS403232	20291970000	20291970000	-37.64974783	144.92478696	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F49ED2DA971D62409D3FD8EF2AD342C0
3028682	GAVIC423705816	VIC1984350	loc8e5a2b16aaaa	P	\N	\N	\N	\N	\N	38	40	GREENFIELD	DRIVE	\N	38-40 GREENFIELD DRIVE	TRARALGON	3844	VIC	3844	1	40\\PS504138	20350290000	20350290000	-38.18180381	146.54473742	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000D6792B7D6E5162407D1EE558451743C0
3271760	GAVIC419625837	VIC1930906	locea2e2e01b99c	P	S	\N	\N	UNIT 20	\N	2	\N	CENTRAL	AVENUE	\N	UNIT 20, 2 CENTRAL AVENUE	MOORABBIN	3189	VIC	3189	1	20\\PS331818	20311950000	20311950000	-37.93518384	145.03824291	FRONTAGE CENTRE SETBACK	2	0101000020A41E000020F83149392162401B46A41AB4F742C0
3473505	GAVIC411670057	VIC1935602	loc00a9769647d7	P	\N	MOTHER ROMANA HOME	\N	\N	\N	11	15	ABECKETT	STREET	\N	11-15 ABECKETT STREET	KEW	3101	VIC	3101	2	CP167086	20072380000	20072380000	-37.80287784	145.02782593	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000966A34F3E3206240D7BD78B3C4E642C0
1313859	GAVIC720458378	VIC3627687	loc875f8bb64843	P	\N	\N	\N	\N	\N	3	\N	CHAI	WALK	\N	3 CHAI WALK	MANOR LAKES	3024	VIC	3024	1	16632\\PS837859	20631937090	21309300000	-37.86395465	144.58284186	FRONTAGE CENTRE SETBACK	2	0101000020A41E000013EEF8A3A6126240127DE31096EE42C0
3489035	GAVIC419912498	VIC1951026	loc098ac8eaabef	P	P	\N	\N	\N	\N	17	\N	ARMSTRONG	STREET	\N	17 ARMSTRONG STREET	LAVERTON	3028	VIC	3028	1	CM1\\PS722115	20280490000	20280490000	-37.86065106	144.77224395	FRONTAGE CENTRE SETBACK	2	0101000020A41E000015B9F138B6186240DFFB5DD029EE42C0
3327635	GAVIC425272843	VIC1948906	locc7ee8539a72b	P	S	\N	\N	UNIT 15	\N	91	\N	BRIDGE	STREET	\N	UNIT 15, 91 BRIDGE STREET	ELTHAM	3095	VIC	3095	2	15\\PS708003	20512540000	20512540000	-37.71905657	145.14830823	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007CB2E6F0BE246240DD0FB20B0ADC42C0
1898831	GAVIC423399692	VIC1981938	locc84be248155b	P	\N	\N	35	\N	\N	\N	\N	JULIET	CRESCENT	\N	LOT 35 JULIET CRESCENT	HEALESVILLE	3777	VIC	3777	0	\N	20659930000	20659930000	-37.64931699	145.53633083	STREET LOCALITY	4	0101000020A41E0000F8D5459F29316240C264B2D11CD342C0
628046	GAVIC420615360	VIC1957930	loc87f2ad0c0fd7	P	\N	\N	\N	\N	\N	15A	\N	CUBITT	STREET	\N	15A CUBITT STREET	CREMORNE	3121	VIC	3121	2	3\\PS336159	20644661000	20644661000	-37.82675684	144.99287793	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A5C8EFA7C51F6240ACC50A2BD3E942C0
1323158	GAVIC423409956	VIC2044329	loc11fb0b5df130	P	\N	\N	6	\N	\N	\N	\N	SWAN	ROAD	\N	LOT 6 SWAN ROAD	MORWELL	3840	VIC	3840	0	\N	20346731000	20346731000	-38.23947175	146.44353967	STREET LOCALITY	4	0101000020A41E00001E241B7A314E62406F48A302A71E43C0
3863595	GAVIC423232139	VIC2025971	loc9901d119afda_2	P	S	\N	\N	UNIT 17	\N	33	34	QUEENS	ROAD	\N	UNIT 17, 33-34 QUEENS ROAD	MELBOURNE	3004	VIC	3004	0	17\\RP14334	20531000000	20531000000	-37.84404234	144.97620603	FRONTAGE CENTRE SETBACK	2	0101000020A41E000041A06D143D1F6240A25E539409EC42C0
1769608	GAVIC721917030	VIC2059743	loc31f384e524fe	P	S	\N	\N	CARPARK 1605C	\N	270	\N	CITY	ROAD	\N	CARPARK 1605C, 270 CITY ROAD	SOUTHBANK	3006	VIC	3006	0	1605A\\PS918394	20395112000	21302230000	-37.82615118	144.95946292	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FDE394EBB31E62406ED36552BFE942C0
3090482	GAVIC420119751	VIC2006911	locb9872f35df41	P	\N	\N	\N	\N	\N	224	\N	NICHOLSON	STREET	\N	224 NICHOLSON STREET	ABBOTSFORD	3067	VIC	3067	2	1\\RP17155	20638720000	20638720000	-37.80112584	144.99771793	FRONTAGE CENTRE SETBACK	2	0101000020A41E000073FF264EED1F6240E863A14A8BE642C0
754127	GAVIC721849526	VIC3572033	locddc4a1bcd8ba	P	S	\N	\N	UNIT 1502	\N	52	\N	DIGITAL	DRIVE	\N	UNIT 1502, 52 DIGITAL DRIVE	DOCKLANDS	3008	VIC	3008	0	1502\\PS531777	20395374000	20395374000	-37.81319205	144.94614424	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000290349D0461E6240000F56AD16E842C0
3253150	GAVIC720052842	VIC1985134	loc31f384e524fe	P	S	\N	\N	UNIT 3314	LEVEL 33	60	\N	KAVANAGH	STREET	\N	UNIT 3314, LEVEL 33, 60 KAVANAGH STREET	SOUTHBANK	3006	VIC	3006	0	3314\\PS745414	20631983400	21302270000	-37.82421909	144.96356449	FRONTAGE CENTRE SETBACK	2	0101000020A41E000062843285D51E6240FA24DA0280E942C0
2995127	GAVIC423436506	VIC1944783	locc91f4a31a1bc	P	\N	\N	\N	\N	\N	11	\N	AMBERLEA	CIRCUIT	\N	11 AMBERLEA CIRCUIT	TAYLORS HILL	3037	VIC	3037	2	5211\\PS523497	20631954430	20631954430	-37.72164337	144.75166398	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CC759EA10D1862403BC358CF5EDC42C0
665742	GAVIC421670970	VIC1952931	loc5c27e3f22fc1	P	\N	\N	\N	\N	\N	18	\N	GOODALL	STREET	\N	18 GOODALL STREET	HAWTHORN	3122	VIC	3122	2	80\\LP8025	20066880000	20066880000	-37.82659684	145.04291892	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F3B87F975F2162407363DDECCDE942C0
3567813	GAVIC420796526	VIC1953813	loca4e166a620d9	P	P	\N	\N	\N	\N	53	\N	DUNBLANE	ROAD	\N	53 DUNBLANE ROAD	NOBLE PARK	3174	VIC	3174	0	\N	20231850000	20231850000	-37.95878525	145.18141778	FRONTAGE CENTRE SETBACK	2	0101000020A41E00006A00A92CCE2562408F519E79B9FA42C0
94880	GAVIC420061429	VIC1957356	loc3832b905a97e	P	S	\N	\N	UNIT 1	\N	3	\N	FORDE	COURT	\N	UNIT 1, 3 FORDE COURT	WEST WODONGA	3690	VIC	3690	2	1\\PS428797	20622990000	20622990000	-36.13640441	146.86124471	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B2E910518F5B624076FD1FB3751142C0
3764	GAVIC425325004	VIC3569786	loc9a86c6faf562	P	\N	\N	510	\N	\N	\N	\N	GHOST GUM	WAY	\N	LOT 510 GHOST GUM WAY	JACKASS FLAT	3556	VIC	3556	1	\N	20632004300	21316150000	-36.70843370	144.28402085	STREET LOCALITY	4	0101000020A41E00003AC4E4B21609624030719AF4AD5A42C0
1423957	GAVIC421049989	VIC2023132	loc4a7c5154c298	P	\N	\N	\N	\N	\N	71	\N	MCPHERSON	STREET	\N	71 MCPHERSON STREET	MOONEE PONDS	3039	VIC	3039	2	1\\TP379434	20448650000	20448650000	-37.75882583	144.92848295	FRONTAGE CENTRE SETBACK	2	0101000020A41E00009824E021B61D6240E39A6D3421E142C0
1494597	GAVIC421885685	VIC2065815	loc232da9d11723	P	\N	\N	\N	\N	\N	145	\N	WALLACE	STREET	\N	145 WALLACE STREET	BAIRNSDALE	3875	VIC	3875	2	2\\LP20539	20157450000	20157450000	-37.82359215	147.59748794	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BE41079F1E73624005BFB2776BE942C0
1984398	GAVIC420987849	VIC2007148	locb0a9c63101c7	P	\N	\N	\N	\N	\N	7	\N	PAUL	COURT	\N	7 PAUL COURT	YARRAWONGA	3730	VIC	3730	2	26\\LP207676	20420330000	20420330000	-36.00805913	146.01850091	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000AE6C388F9740624061E4E114080142C0
3826290	GAVIC424918055	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 901	\N	568	\N	ST KILDA	ROAD	\N	UNIT 901, 568 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	1	901\\PS621195	20631943540	20631943540	-37.84701078	144.97902922	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004F371635541F6240CFBA67D96AEC42C0
3845439	GAVIC423789992	VIC1967421	loc9901d119afda_1	P	S	\N	\N	UNIT 206	LEVEL 2	9	\N	DEGRAVES	STREET	\N	UNIT 206, LEVEL 2, 9 DEGRAVES STREET	MELBOURNE	3000	VIC	3000	0	206A\\PS508080	20631944140	21334360000	-37.81756618	144.96576928	FRONTAGE CENTRE SETBACK	2	0101000020A41E00009B22FA94E71E624034B53202A6E842C0
166802	GAVIC420637602	VIC1937990	loc9fe59dbd0874	P	S	\N	\N	UNIT 2	\N	4	\N	BLUEBERRY	CLOSE	\N	UNIT 2, 4 BLUEBERRY CLOSE	CRANBOURNE NORTH	3977	VIC	3977	2	2\\SP36612	20631906600	20631906600	-38.07971786	145.27655085	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CB0D2B81D9286240B6CDE031340A43C0
3098536	GAVIC423397050	VIC1969720	loc610e6e8cd167	P	\N	\N	19	\N	\N	\N	\N	GIBBS	ROAD	\N	LOT 19 GIBBS ROAD	YARRA GLEN	3775	VIC	3775	0	\N	20659350000	20659350000	-37.63549404	145.37837938	STREET LOCALITY	4	0101000020A41E000096D212AF1B2C62402C4D63DE57D142C0
1688110	GAVIC419987098	VIC1938173	loc4423238fcdd8	P	P	\N	\N	\N	\N	29	\N	BYRON	STREET	\N	29 BYRON STREET	HAMILTON	3300	VIC	3300	2	3\\PS316650	20540970000	20540970000	-37.73995574	142.01663921	FRONTAGE CENTRE SETBACK	2	0101000020A41E000000D9F34E88C06140CCE4A3DEB6DE42C0
3736370	GAVIC424765376	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 7G	\N	566	\N	ST KILDA	ROAD	\N	UNIT 7G, 566 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	0	G7\\PS402478	20533233000	20533233000	-37.84679697	144.97895103	FRONTAGE CENTRE SETBACK	2	0101000020A41E000089471C91531F62403E40D6D763EC42C0
3733304	GAVIC719439210	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 103	LEVEL 1	499	\N	ST KILDA	ROAD	\N	UNIT 103, LEVEL 1, 499 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	0	103\\PS737521	20631995350	21328350000	-37.84341251	144.97862647	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CC7475E8501F62405FBEEDF0F4EB42C0
2361079	GAVIC421983130	VIC2004239	loc819a06b032e3	P	\N	\N	\N	\N	\N	5	\N	PARKLEA	WAY	\N	5 PARKLEA WAY	TARNEIT	3029	VIC	3029	2	461\\PS510193	20631130000	20631130000	-37.84058603	144.69173458	FRONTAGE CENTRE SETBACK	2	0101000020A41E000098D38EB0221662408829B25298EB42C0
974351	GAVIC421924109	VIC2028573	loc406d1f7b5fe3	P	\N	\N	\N	\N	\N	24	\N	SPRING VALLEY	DRIVE	\N	24 SPRING VALLEY DRIVE	TEMPLESTOWE	3106	VIC	3106	2	76\\LP121572	20361840000	20361840000	-37.75359385	145.15823591	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001750C14410256240BE1B66C375E042C0
3180100	GAVIC414839745	VIC1951129	loc7f158a48110c	P	P	\N	\N	\N	\N	7	9	ARNOLD	STREET	\N	7-9 ARNOLD STREET	BLAIRGOWRIE	3942	VIC	3942	1	1931\\LP43379	20488510000	20488510000	-38.37210524	144.77300509	FRONTAGE CENTRE SETBACK	2	0101000020A41E000021A62B75BC186240313CFE24A12F43C0
3491739	GAVIC424354717	VIC1960025	loc70eb03d586f8	P	\N	\N	\N	\N	\N	46	\N	EDMONDSHAW	DRIVE	\N	46 EDMONDSHAW DRIVE	DEER PARK	3023	VIC	3023	2	952\\PS613831	20092653200	20092653200	-37.77770331	144.76417232	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000125D821974186240713835C88BE342C0
958970	GAVIC421856523	VIC2059036	loc11b2a92fb5f0	P	S	\N	\N	UNIT 4	\N	40	\N	WHITBY	STREET	\N	UNIT 4, 40 WHITBY STREET	BRUNSWICK WEST	3055	VIC	3055	2	3\\LP4289	20462000000	20462000000	-37.76406510	144.94564894	FRONTAGE CENTRE SETBACK	2	0101000020A41E000082D990C1421E6240EB419CE2CCE142C0
1617384	GAVIC721711659	VICL4176453	locfd8472c41cbe	P	\N	\N	\N	\N	\N	2	\N	HAMILTON	WAY	\N	2 HAMILTON WAY	ROWVILLE	3178	VIC	3178	1	7\\PS917468	20339571000	20339571000	-37.91920783	145.22167130	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C7FE68EE17276240DF09289AA8F542C0
3113313	GAVIC425314633	VIC1992791	loc406d1f7b5fe3	P	S	\N	\N	UNIT 36	\N	31	\N	KING	STREET	\N	UNIT 36, 31 KING STREET	TEMPLESTOWE	3106	VIC	3106	1	36\\PS711492	20362460000	20362460000	-37.77324143	145.14957729	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C7185056C924624092E13E93F9E242C0
3174127	GAVIC423750017	VIC1962002	loc31f384e524fe	P	S	\N	\N	UNIT 2007	LEVEL 20	1	\N	FRESHWATER	PLACE	\N	UNIT 2007, LEVEL 20, 1 FRESHWATER PLACE	SOUTHBANK	3006	VIC	3006	0	2007\\PS504017	20631945440	20631945440	-37.82152105	144.96247736	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E50A529DCC1E6240E05C0D9A27E942C0
3912884	GAVIC422035533	VIC2037856	loc6ae7eaa3c1f3	P	P	\N	\N	\N	\N	1	\N	STOTT	STREET	\N	1 STOTT STREET	BOX HILL SOUTH	3128	VIC	3128	1	4\\LP11227	20591630000	20591630000	-37.84251506	145.11100077	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000639F7C518D236240328B9288D7EB42C0
2539949	GAVIC421279891	VIC2059476	loc1b289d3ff2fc	P	\N	\N	\N	\N	\N	14	\N	ACACIA	STREET	\N	14 ACACIA STREET	SHEPPARTON	3630	VIC	3630	2	131\\LP27673	20265140000	20265140000	-36.36611726	145.41878792	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000848BECB5662D6240BF192DEEDC2E42C0
56481	GAVIC420987808	VIC2073696	loc4ff8c926c940	P	\N	\N	\N	\N	\N	4	\N	WIPPA	COURT	\N	4 WIPPA COURT	ASHWOOD	3147	VIC	3147	2	90\\LP53678	20443370000	20443370000	-37.87256485	145.09782991	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A900316C21236240D0317B34B0EF42C0
341841	GAVIC721800565	VIC4127252	loc1b271c01e3dc	P	\N	\N	\N	\N	\N	2	\N	STRATEGIC	CIRCUIT	\N	2 STRATEGIC CIRCUIT	MICKLEHAM	3064	VIC	3064	0	1008\\PS908944	20301030000	21343120000	-37.53100433	144.94090814	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E33A63EB1B1E624034B12BF3F7C342C0
253919	GAVIC424265017	VIC653423	loc515028b0f98a	P	\N	THE CARD LOT	\N	\N	\N	489	\N	HOWES CREEK	ROAD	\N	489 HOWES CREEK ROAD	MANSFIELD	3722	VIC	3722	2	1\\PS324581	20631982830	20631982830	-37.06902526	146.01260217	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E00004780AA3C674062402126D9D1D58842C0
1187442	GAVIC425613744	VIC3568169	locae977e7a8d83	P	\N	\N	\N	\N	\N	71	\N	ELMSLIE	DRIVE	\N	71 ELMSLIE DRIVE	CRANBOURNE EAST	3977	VIC	3977	2	726\\PS721478	20631984480	21304160000	-38.11927653	145.30070638	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008E79FC629F296240E3C30D74440F43C0
3280788	GAVIC421863134	VIC2078595	loc1e33f92d8409	P	\N	\N	\N	\N	\N	22	\N	KIRRAK	STREET	\N	22 KIRRAK STREET	NORTH WONTHAGGI	3995	VIC	3995	2	1\\TP111265	20034520000	20034520000	-38.59345478	145.59827028	FRONTAGE CENTRE SETBACK	2	0101000020A41E00009AD8B60725336240A0E08353F64B43C0
190617	GAVIC423390367	VIC1946485	loc3fe991822440	P	\N	\N	2	\N	\N	\N	\N	ANDREWS	LANE	\N	LOT 2 ANDREWS LANE	RED HILL	3937	VIC	3937	0	\N	20495120000	20495120000	-38.36909570	145.01848224	STREET LOCALITY	4	0101000020A41E00006B0B116897206240104C24873E2F43C0
3017353	GAVIC719985042	VIC2061385	loca0398a35cf5e	P	S	\N	\N	UNIT 1718	LEVEL 17	160	\N	VICTORIA	STREET	\N	UNIT 1718, LEVEL 17, 160 VICTORIA STREET	CARLTON	3053	VIC	3053	0	1718\\PS742732	20401931000	21330620000	-37.80632196	144.96191382	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000ECF7DFFC71E6240911FD88E35E742C0
1606157	GAVIC420591242	VIC1968404	loc74f8893fb76e	P	P	\N	\N	\N	\N	17	\N	GERBERT	STREET	\N	17 GERBERT STREET	BROADMEADOWS	3047	VIC	3047	1	1018\\LP58934	20294390000	20294390000	-37.68788889	144.93233076	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000286851A7D51D624077EA3EBE0CD842C0
3300863	GAVIC424263895	VIC1965101	loce3f8de63f06a	P	S	\N	\N	UNIT 1	\N	8	\N	GARDEN	CLOSE	\N	UNIT 1, 8 GARDEN CLOSE	KINGSBURY	3083	VIC	3083	1	1\\PS543069	20155590000	20155590000	-37.71415954	145.02790178	FRONTAGE CENTRE SETBACK	2	0101000020A41E000035134692E420624094366E9469DB42C0
2720159	GAVIC420656885	VIC1953967	loca1efec8fa041	P	S	\N	\N	UNIT 1	\N	7	\N	DUNLOE	AVENUE	\N	UNIT 1, 7 DUNLOE AVENUE	MONT ALBERT NORTH	3129	VIC	3129	2	1\\SP24381	20588380000	20588380000	-37.80968285	145.11537391	FRONTAGE CENTRE SETBACK	2	0101000020A41E00005F48A024B1236240E87008B0A3E742C0
3256076	GAVIC424906559	VIC1937464	locdd716f1059c5	P	S	\N	\N	UNIT 59	FLOOR 3	80	\N	BALCOMBE	ROAD	\N	UNIT 59, FLOOR 3, 80 BALCOMBE ROAD	MENTONE	3194	VIC	3194	1	59\\PS612989	20631971350	20631971350	-37.98102750	145.06543874	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002006FC1218226240037D224F92FD42C0
388435	GAVIC719439216	VIC2080714	loc1e06c486c813	P	S	\N	\N	UNIT 307	LEVEL 3	388	\N	QUEENSBERRY	STREET	\N	UNIT 307, LEVEL 3, 388 QUEENSBERRY STREET	NORTH MELBOURNE	3051	VIC	3051	0	307CA\\PS721454	20399801000	20399801000	-37.80319690	144.95513882	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004861497F901E6240D2DFF027CFE642C0
1610292	GAVIC720475626	VIC3619244	locba5e689e47f8	P	\N	\N	\N	\N	\N	2B	\N	ROSSER	BOULEVARD	\N	2B ROSSER BOULEVARD	TORQUAY	3228	VIC	3228	2	2110\\PS819032	20631931560	21333790000	-38.30843736	144.32161328	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E6F1EEA74A0A624044081BE07A2743C0
3898862	GAVIC423837828	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 16	\N	539	\N	ST KILDA	ROAD	\N	UNIT 16, 539 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	2	16\\PS526704	20400701000	21327870000	-37.84556706	144.97940721	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000550DCA4D571F62402FA39A8A3BEC42C0
297375	GAVIC420964291	VIC2005249	loc3319215a0a10	P	S	\N	\N	UNIT 4	\N	249	\N	NEW	STREET	\N	UNIT 4, 249 NEW STREET	BRIGHTON	3186	VIC	3186	2	4\\SP23999	20045030000	20045030000	-37.91060984	144.99138092	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E9A87A64B91F62409F1BFDDC8EF442C0
2061928	GAVIC721916596	VIC2031732	loc8f498b475ec6	P	S	\N	\N	UNIT 5	\N	28	\N	STANDING	DRIVE	\N	UNIT 5, 28 STANDING DRIVE	TRARALGON EAST	3844	VIC	3844	0	5\\PS935877	20350346000	20350346000	-38.19143803	146.56651988	FRONTAGE CENTRE SETBACK	2	0101000020A41E000048A44CEE20526240C407970A811843C0
1226367	GAVIC420881388	VIC2061689	loc250adfcbc82d	P	S	\N	\N	UNIT 7	\N	32	\N	WILLIAMS	ROAD	\N	UNIT 7, 32 WILLIAMS ROAD	PRAHRAN	3181	VIC	3181	2	7\\RP12674	20549760000	20549760000	-37.85654984	145.00201593	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000792DB68310206240D618D76CA3ED42C0
3545125	GAVIC425484937	VIC2001577	loc0621c45c46f4	P	\N	\N	\N	\N	\N	7A	\N	HELSTON	STREET	\N	7A HELSTON STREET	BALWYN NORTH	3104	VIC	3104	2	2\\PS716444	20057910000	20057910000	-37.78634830	145.09232289	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001C27224FF4226240F2E1A30FA7E442C0
3927283	GAVIC720919065	VIC1971604	loc74f8893fb76e	P	S	\N	\N	UNIT 3	\N	10	\N	CONGRAM	STREET	\N	UNIT 3, 10 CONGRAM STREET	BROADMEADOWS	3047	VIC	3047	2	2C\\RP15895	20293530000	20293530000	-37.68866198	144.93382902	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000959E65EDE11D62409F0C651326D842C0
3015317	GAVIC719745362	VIC2070959	loc656f84726510	P	S	\N	\N	UNIT 7	\N	87	93	RADFORD	ROAD	\N	UNIT 7, 87-93 RADFORD ROAD	RESERVOIR	3073	VIC	3073	2	7\\PS802357	20149752000	20149752000	-37.70188264	144.98435522	FRONTAGE CENTRE SETBACK	2	0101000020A41E000080B184D67F1F62400F37544AD7D942C0
3141458	GAVIC422294300	VIC1952872	loc3832b905a97e	P	\N	\N	\N	\N	\N	36	\N	GOLFLINKS	AVENUE	\N	36 GOLFLINKS AVENUE	WEST WODONGA	3690	VIC	3690	2	60\\PS518071	20631992910	20631992910	-36.12677250	146.84235497	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BDF86892F45A62401EC4CE143A1042C0
930913	GAVIC420841495	VIC2042335	locbbb93e2c6c42	P	\N	\N	\N	\N	\N	76	\N	SHEEPWASH	ROAD	\N	76 SHEEPWASH ROAD	BARWON HEADS	3227	VIC	3227	2	32\\LP87498	20260020000	20260020000	-38.26645855	144.49026312	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B85A483CB00F6240ABFE52501B2243C0
2857454	GAVIC421448648	VIC2064616	loccaca39f133a7	P	P	\N	\N	\N	\N	171	\N	WAIORA	ROAD	\N	171 WAIORA ROAD	HEIDELBERG HEIGHTS	3081	VIC	3081	1	1\\SP24480	20017620000	20017620000	-37.73417184	145.05990293	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001BA98CB9EA216240DA38C557F9DD42C0
1910802	GAVIC421262022	VIC2065164	loc76dea039b41f	P	P	\N	\N	\N	\N	1A	\N	WINTER	STREET	\N	1A WINTER STREET	MALVERN	3144	VIC	3144	0	1\\LP39932	20556812000	20556812000	-37.85982673	145.02909470	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000951F0258EE206240CFC962CD0EEE42C0
497974	GAVIC424283355	VIC2035753	loc0a03ed3531fd	P	S	\N	\N	FACTORY 14	\N	354	\N	RESERVE	ROAD	\N	FACTORY 14, 354 RESERVE ROAD	CHELTENHAM	3192	VIC	3192	0	CM\\SP26245	20050630000	21309710000	-37.95885229	145.03850284	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004DD34E6A3B216240539FFDABBBFA42C0
1385511	GAVIC420980761	VIC2059240	loc264c2d9ba83e	P	\N	\N	\N	\N	\N	16	\N	WHITEHAVEN	CRESCENT	\N	16 WHITEHAVEN CRESCENT	MULGRAVE	3170	VIC	3170	2	645\\LP70821	20631992360	20631992360	-37.92766985	145.17622189	FRONTAGE CENTRE SETBACK	2	0101000020A41E000075CC169CA32562401C9EB9E2BDF642C0
3315770	GAVIC423471646	VIC1998102	loc79e45c9fa669	P	S	\N	\N	UNIT 202	\N	416	\N	LYGON	STREET	\N	UNIT 202, 416 LYGON STREET	BRUNSWICK EAST	3057	VIC	3057	2	202\\PS512620	20461472000	20461472000	-37.76496434	144.97307567	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000DD65966F231F6240FF73FB59EAE142C0
3540241	GAVIC419571030	VIC2006569	loc0b8afd71fce1	P	\N	KATHEGA	\N	\N	\N	94	\N	MILLER	STREET	\N	94 MILLER STREET	WEST MELBOURNE	3003	VIC	3003	2	1\\TP760553	20399641000	20399641000	-37.80536765	144.94457917	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000407418FE391E6240D100834916E742C0
3847593	GAVIC719915818	VIC1963013	loc9901d119afda_1	P	S	\N	\N	UNIT 5405	LEVEL 54	462	\N	ELIZABETH	STREET	\N	UNIT 5405, LEVEL 54, 462 ELIZABETH STREET	MELBOURNE	3000	VIC	3000	0	5405\\PS728807	20401423000	21313460000	-37.80786078	144.96051896	FRONTAGE CENTRE SETBACK	2	0101000020A41E00006A0C4292BC1E624018E966FB67E742C0
3580999	GAVIC720518002	VIC1955730	locddc4a1bcd8ba	P	S	\N	\N	UNIT 1601	LEVEL 16	628	\N	FLINDERS	STREET	\N	UNIT 1601, LEVEL 16, 628 FLINDERS STREET	DOCKLANDS	3008	VIC	3008	0	11601\\PS704437	20395174000	20395174000	-37.82127148	144.95351739	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F4C6E636831E624067DE816C1FE942C0
2083383	GAVIC424424026	VIC2053277	loc2d817b7080e2	P	P	\N	\N	\N	\N	92	94	WAVERLEY	ROAD	\N	92-94 WAVERLEY ROAD	MALVERN EAST	3145	VIC	3145	0	\N	20556521000	20556521000	-37.87604151	145.04748732	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FDCB200485216240B9B1D12022F042C0
1760264	GAVIC420215992	VIC1973863	loc3b6fd5dcd874	P	S	\N	\N	\N	\N	32	\N	DONALDA	AVENUE	\N	32 DONALDA AVENUE	SORRENTO	3943	VIC	3943	1	4\\LP217798	20491500000	20491500000	-38.33777483	144.73374592	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000263FB9D87A1762408821A4343C2B43C0
2048489	GAVIC412667511	VIC2076198	locf3fc3fca2acd	P	\N	\N	2	\N	\N	\N	\N	PILLARS	ROAD	\N	LOT 2 PILLARS ROAD	BANGHOLME	3175	VIC	3175	0	\N	20631918050	20631918050	-38.02758237	145.15906164	STREET LOCALITY	4	0101000020A41E000024BB6F08172562404F8CB0D1870343C0
2916032	GAVIC424628057	VIC2017941	locc5abea08e85d	P	S	POINT COOK RET VILLAGE	\N	UNIT 34	\N	320	\N	POINT COOK	ROAD	\N	UNIT 34, 320 POINT COOK ROAD	POINT COOK	3030	VIC	3030	2	NB\\PS627343	20631953360	20631953360	-37.89898736	144.75305218	FRONTAGE CENTRE SETBACK	2	0101000020A41E000002A9E20019186240D35B8F0412F342C0
3486295	GAVIC420502224	VIC1978531	loc82baa1179308	P	P	\N	\N	\N	\N	27	\N	HENTY	STREET	\N	27 HENTY STREET	PAKENHAM	3810	VIC	3810	1	\N	20104480000	20104480000	-38.07937173	145.47806519	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FE8C5E4F4C2F6240D94954DA280A43C0
756899	GAVIC721025623	VIC4123121	loc8733d13ded2e	P	\N	\N	\N	\N	\N	10	\N	SHIRAZ	AVENUE	\N	10 SHIRAZ AVENUE	FRASER RISE	3336	VIC	3336	2	163\\PS902772	20405930000	20405930000	-37.69387698	144.71366136	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CE335950D61662400C46FCF5D0D842C0
3686893	GAVIC720000915	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 419	\N	450	\N	ST KILDA	ROAD	\N	UNIT 419, 450 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	1	306\\PS738892	20631933390	20631933390	-37.83867611	144.97599334	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003E8D62563B1F6240793120BD59EB42C0
3904641	GAVIC420015455	VIC1944127	loc9901d119afda_1	P	S	\N	\N	UNIT 507	\N	155	\N	BOURKE	STREET	\N	UNIT 507, 155 BOURKE STREET	MELBOURNE	3000	VIC	3000	1	507\\PS418979	20664440000	21340930000	-37.81280333	144.96881327	FRONTAGE CENTRE SETBACK	2	0101000020A41E000096D2AF84001F6240073784F009E842C0
3306077	GAVIC425084495	VIC1981507	locbb6ca08c118e	P	S	\N	\N	UNIT 5	\N	18A	\N	HIGH	STREET	\N	UNIT 5, 18A HIGH STREET	NORTHCOTE	3070	VIC	3070	1	5\\PS640884	20145322000	20145322000	-37.78304333	144.99673413	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000665F93EE51F6240B8D98AC33AE442C0
938772	GAVIC425530619	VIC2068568	locedacea740a10	P	\N	\N	\N	\N	\N	595	\N	WOORINEN	ROAD	\N	595 WOORINEN ROAD	SWAN HILL	3585	VIC	3585	1	3\\PS912957	20631985290	20631985290	-35.30658547	143.49085693	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000AEAB9719B5EF6140168A53313EA741C0
3151754	GAVIC425083938	VIC1985830	loc51ba976fe589	P	S	\N	\N	UNIT 1	\N	26	\N	GREGORY	STREET	\N	UNIT 1, 26 GREGORY STREET	OAK PARK	3046	VIC	3046	2	1\\PS706421	20474111000	20474111000	-37.72201345	144.91613447	FRONTAGE CENTRE SETBACK	2	0101000020A41E00006D6C3CF9501D6240D582CDEF6ADC42C0
2626519	GAVIC420099787	VIC1976022	locc70453923b8e	P	P	\N	\N	\N	\N	62	\N	GOLDEN	AVENUE	\N	62 GOLDEN AVENUE	BONBEACH	3196	VIC	3196	2	CM1\\PS626060	20322330000	20322330000	-38.05617128	145.12613163	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000EB3A3345092462408849D99E300743C0
65202	GAVIC720543934	VIC2008804	loceb6884033cea	P	\N	\N	10A	\N	\N	\N	\N	PEERS	LANE	\N	LOT 10A PEERS LANE	DURHAM LEAD	3352	VIC	3352	0	\N	20015080000	20015080000	-37.69871999	143.88496651	STREET LOCALITY	4	0101000020A41E00002B5049A551FC6140440E19A86FD942C0
1490242	GAVIC719919340	VIC3625244	loc5c7c3d320a8a	P	\N	\N	\N	\N	\N	16	\N	PLYMOUTH	STREET	\N	16 PLYMOUTH STREET	WANGARATTA	3677	VIC	3677	2	142\\PS820939	20631935730	20631935730	-36.33965077	146.28813510	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008DEA196738496240099B2AAD792B42C0
1010200	GAVIC421832935	VIC1930548	loc2c4c767ea9b7	P	S	\N	\N	UNIT 2	\N	72	\N	BRUCE	STREET	\N	UNIT 2, 72 BRUCE STREET	PRESTON	3072	VIC	3072	2	2\\RP12205	20152720000	20152720000	-37.74126784	144.99292794	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B5B2D010C61F6240333055DDE1DE42C0
3567648	GAVIC425622336	VIC2006220	loca0398a35cf5e	P	S	\N	\N	UNIT 405	LEVEL 4	525	\N	RATHDOWNE	STREET	\N	UNIT 405, LEVEL 4, 525 RATHDOWNE STREET	CARLTON	3053	VIC	3053	0	405N3S\\PS627030	20631924810	21329140000	-37.79308649	144.97100474	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F4518878121F624087B9ACDB83E542C0
3270299	GAVIC720443226	VIC2066462	loc1a7553da1009	P	\N	\N	\N	\N	\N	15	\N	WOODACRES	ROAD	\N	15 WOODACRES ROAD	CHETWYND	3312	VIC	3312	0	2\\PS818721	20587332000	20587332000	-37.32063544	141.40787780	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007678BE550DAD6140895E04950AA942C0
2581982	GAVIC421943442	VIC1954730	loc06cc48b309e5	P	P	\N	\N	\N	\N	5	\N	GRACE	STREET	\N	5 GRACE STREET	WATSONIA	3087	VIC	3087	1	CM1\\PS645053	20028860000	20028860000	-37.71045753	145.08213818	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004B9B3FE0A02262400246B845F0DA42C0
1641883	GAVIC420429255	VIC2068062	loceb41e8eec3ee	P	\N	\N	\N	\N	\N	8	\N	COOK	ROAD	\N	8 COOK ROAD	LONGWARRY	3816	VIC	3816	2	4\\LP125750	20041512000	20041512000	-38.11003101	145.76596901	FRONTAGE CENTRE SETBACK	2	0101000020A41E000062F670D18238624078BF027F150E43C0
2240953	GAVIC421753831	VIC2076646	locc67851215f08	P	\N	\N	\N	\N	\N	9	\N	HADDON	COURT	\N	9 HADDON COURT	MEADOW HEIGHTS	3048	VIC	3048	2	135\\LP135690	20289930000	20289930000	-37.65794683	144.92547596	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E5ADC27F9D1D6240AEAD0A9A37D442C0
3877093	GAVIC719524538	VIC1963013	loc9901d119afda_1	P	S	\N	\N	UNIT 3504	LEVEL 35	442	\N	ELIZABETH	STREET	\N	UNIT 3504, LEVEL 35, 442 ELIZABETH STREET	MELBOURNE	3000	VIC	3000	0	3505\\PS728842	20401811000	21328440000	-37.80833027	144.96073354	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000DCF4354BE1E62402802C55D77E742C0
3109545	GAVIC420751807	VIC2002748	loc3b6fd5dcd874	P	\N	\N	\N	\N	\N	22	\N	PARK	ROAD	\N	22 PARK ROAD	SORRENTO	3943	VIC	3943	2	13\\LP13917	20486870000	20486870000	-38.34410083	144.73612392	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008246C0538E17624030B0F97E0B2C43C0
800509	GAVIC419868312	VIC1986516	loc025dead673cc	P	\N	\N	\N	\N	\N	26	\N	KEILLER	AVENUE	\N	26 KEILLER AVENUE	PARKDALE	3195	VIC	3195	2	21\\LP43256	20318810000	20318810000	-37.98621985	145.09049090	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BD022C4DE52262404035B9733CFE42C0
1484620	GAVIC419568757	VIC2063543	loc7d9d9818d4b9	P	\N	\N	\N	\N	\N	10	\N	VIVIENNE	AVENUE	\N	10 VIVIENNE AVENUE	BORONIA	3155	VIC	3155	2	33\\LP41879	20328100000	20328100000	-37.86501586	145.27522388	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B4754FA2CE286240549CF6D6B8EE42C0
3699104	GAVIC721706405	VIC1959852	loca1a84d46e52a	P	S	\N	\N	UNIT 1	\N	625	\N	EDGARS	ROAD	\N	UNIT 1, 625 EDGARS ROAD	EPPING	3076	VIC	3076	0	11\\PS914841	20608847000	20608847000	-37.63683577	145.00483643	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BE95BA9E272062405789A2D583D142C0
2413909	GAVIC719754869	VIC1994235	loc3d949ab3c987	P	S	\N	\N	UNIT 1	\N	11	\N	KINGSTON	ROAD	\N	UNIT 1, 11 KINGSTON ROAD	HEATHERTON	3202	VIC	3202	2	1\\PS801055	20312600000	20312600000	-37.95347890	145.08095040	FRONTAGE CENTRE SETBACK	2	0101000020A41E000024134B25972262408976BA980BFA42C0
970161	GAVIC425272501	VIC3572470	loc6d7f0d49a3d6	P	\N	\N	\N	\N	\N	10	\N	BOBOLI	WALK	\N	10 BOBOLI WALK	WOLLERT	3750	VIC	3750	2	2649\\PS645334	20631982150	20631982150	-37.61384918	144.99807193	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FB4C8B34F01F62406263249C92CE42C0
3175055	GAVIC424272695	VIC1962198	loccb9bfb1fb49a	P	S	\N	\N	UNIT 3	\N	4	\N	CIVIC	SQUARE	\N	UNIT 3, 4 CIVIC SQUARE	CROYDON	3136	VIC	3136	2	3\\PS605912	20386220000	20386220000	-37.79951261	145.28054568	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004A14EF3AFA2862404558E06D56E642C0
1920452	GAVIC419837839	VIC1962988	locc81a6ec90a1b	P	\N	\N	\N	\N	\N	70	\N	ELIZABETH	DRIVE	\N	70 ELIZABETH DRIVE	ROSEBUD	3939	VIC	3939	2	55\\LP50907	20486250000	20486250000	-38.37319584	144.92440088	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CC7F27B1941D6240D1E69BE1C42F43C0
1941104	GAVIC421741216	VIC1945552	loc63a05a113f90	P	\N	\N	\N	\N	\N	48	\N	BOX	STREET	\N	48 BOX STREET	MERBEIN	3505	VIC	3505	2	14~5\\PP5516	20411240000	20411240000	-34.16670897	142.05971691	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FBEE6F33E9C16140C80C33B8561541C0
157276	GAVIC720693565	VIC3626122	loc4883549a5421	P	\N	\N	\N	\N	\N	26	\N	REGALLA	DRIVE	\N	26 REGALLA DRIVE	GREENVALE	3059	VIC	3059	0	RES2\\PS817578	20300270000	21320530000	-37.64068727	144.87308230	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000EDA64A4AF01B624088CE5B0A02D242C0
2205732	GAVIC421479094	VIC1947995	loc0b665c0fe535	P	\N	\N	\N	\N	\N	16	\N	ANTARES	COURT	\N	16 ANTARES COURT	OCEAN GROVE	3226	VIC	3226	2	225\\LP55384	20257270000	20257270000	-38.26942449	144.54439636	FRONTAGE CENTRE SETBACK	2	0101000020A41E00005E48EAB16B1162404FA56E807C2243C0
1457645	GAVIC420622820	VIC2014019	locdf0288b649a4	P	\N	\N	\N	\N	\N	21	\N	MAXWELL	DRIVE	\N	21 MAXWELL DRIVE	WODONGA	3690	VIC	3690	2	1\\PS317132	20621460000	20621460000	-36.13174471	146.90513845	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004523E9E4F65C62407D6FBA02DD1042C0
2026704	GAVIC420355278	VIC1943976	loccdfc709471ce	P	\N	\N	\N	\N	\N	167	\N	BOUNDARY	STREET	\N	167 BOUNDARY STREET	KERANG	3579	VIC	3579	2	1\\TP108762	20180720000	20180720000	-35.73322369	143.92348651	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E9D794338DFD6140EA991C46DADD41C0
2321823	GAVIC421499309	VIC1980990	locb17fb225139f	P	S	\N	\N	UNIT 9	\N	61	\N	MALTRAVERS	ROAD	\N	UNIT 9, 61 MALTRAVERS ROAD	IVANHOE EAST	3079	VIC	3079	1	9\\SP20936	20015890000	20015890000	-37.76930735	145.05733918	FRONTAGE CENTRE SETBACK	2	0101000020A41E000025DCF9B8D52162404569CAA978E242C0
3851717	GAVIC719987520	VIC1990305	loc9901d119afda_1	P	S	\N	\N	UNIT 23S	\N	296	\N	LITTLE LONSDALE	STREET	\N	UNIT 23S, 296 LITTLE LONSDALE STREET	MELBOURNE	3000	VIC	3000	0	23S\\PS742122	20631945320	21315200000	-37.81150292	144.96065746	FRONTAGE CENTRE SETBACK	2	0101000020A41E000078ABB6B4BD1E62401701E353DFE742C0
3338108	GAVIC420510289	VIC2000595	loc70eb03d586f8	P	\N	\N	\N	\N	\N	34	\N	LAKE BOGA	AVENUE	\N	34 LAKE BOGA AVENUE	DEER PARK	3023	VIC	3023	2	387\\LP13508	20085010000	20085010000	-37.76937482	144.76059798	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001E3093D1561862400922C5DF7AE242C0
1425972	GAVIC421826494	VIC2034660	loc2f9c80de6f7d	P	P	\N	\N	\N	\N	59	\N	SCORESBY	ROAD	\N	59 SCORESBY ROAD	BAYSWATER	3153	VIC	3153	2	10\\LP20578	20331950000	20331950000	-37.84593386	145.27006588	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B24B3361A4286240B8A38B8F47EC42C0
3291329	GAVIC719979296	VIC1962365	loc31f384e524fe	P	S	\N	\N	UNIT 3810	LEVEL 38	105	\N	CLARENDON	STREET	\N	UNIT 3810, LEVEL 38, 105 CLARENDON STREET	SOUTHBANK	3006	VIC	3006	0	3810\\PS734580	20395113000	20395113000	-37.82714046	144.95816137	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000198E0842A91E6240FF7214BDDFE942C0
2844669	GAVIC411852098	VIC1958513	locdd716f1059c5	P	\N	\N	\N	\N	\N	14	\N	EBLANA	AVENUE	\N	14 EBLANA AVENUE	MENTONE	3194	VIC	3194	2	3\\PS409828	20314550000	20314550000	-37.98681620	145.06609708	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C19E9F771D226240DD1445FE4FFE42C0
3432133	GAVIC412527332	VIC1995210	loc4a341f4d3e02	P	S	LEVANDE SALFORD PARK	\N	UNIT 127	\N	100	\N	HAROLD	STREET	\N	UNIT 127, 100 HAROLD STREET	WANTIRNA	3152	VIC	3152	2	2\\PS728985	20335681000	20335681000	-37.85445861	145.22971282	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000E72BB3CE5927624029DE54E65EED42C0
3803385	GAVIC424599194	VIC2027792	locd777103bd088	P	S	BELLBROOK GARDENS VILLAGE	\N	UNIT 98	\N	168	\N	UNDERBANK	BOULEVARD	\N	UNIT 98, 168 UNDERBANK BOULEVARD	BACCHUS MARSH	3340	VIC	3340	2	1\\PS913850	20458270000	20458270000	-37.67368602	144.41881532	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000D7CE62EF660D624011D6EF573BD642C0
369189	GAVIC420229782	VIC1989339	loca1a84d46e52a	P	\N	\N	\N	\N	\N	28	\N	HORSESHOE	CRESCENT	\N	28 HORSESHOE CRESCENT	EPPING	3076	VIC	3076	2	321\\LP206964	20618650000	20618650000	-37.64075884	145.05269194	FRONTAGE CENTRE SETBACK	2	0101000020A41E000002E201A7AF2162402136BB6204D242C0
619577	GAVIC718988205	VIC3618129	loc6a54ce63b777	P	\N	\N	\N	\N	\N	22	\N	ELEGANTE	ROAD	\N	22 ELEGANTE ROAD	WINTER VALLEY	3358	VIC	3358	2	182\\PS716071	20631972050	21306790000	-37.58030430	143.80032960	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000AA40D24C9CF96140351D4B6947CA42C0
1607663	GAVIC425685265	VIC2002547	locd6190ebbe554	P	S	\N	\N	UNIT 2	\N	1	\N	PARALLEL	STREET	\N	UNIT 2, 1 PARALLEL STREET	FALLS CREEK	3699	VIC	3699	0	2046\\PP2486	20663853000	20663853000	-36.86512101	147.27784059	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A5F1F211E468624029840649BC6E42C0
3602862	GAVIC424626663	VIC2020912	loc1b289d3ff2fc	P	\N	\N	\N	\N	\N	26	28	ORCHARD	CIRCUIT	\N	26-28 ORCHARD CIRCUIT	SHEPPARTON	3630	VIC	3630	1	47\\LP203266	20266260000	20266260000	-36.35998165	145.40725152	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000AEF45634082D62407FF4F2E0132E42C0
1241255	GAVIC719210454	VIC3618602	loc64c822b0bad5	P	\N	\N	\N	\N	\N	55	\N	MANCHESTER	BOULEVARD	\N	55 MANCHESTER BOULEVARD	OFFICER	3809	VIC	3809	2	37\\PS735758	20632004710	21336180000	-38.07634274	145.42060832	FRONTAGE CENTRE SETBACK	2	0101000020A41E00006B5A949F752D624024CB5199C50943C0
3830978	GAVIC421565163	VIC1976256	loc9901d119afda_1	P	\N	\N	\N	\N	\N	9	\N	CORRS	LANE	\N	9 CORRS LANE	MELBOURNE	3000	VIC	3000	1	9\\PS337555	20393110000	20393110000	-37.81131701	144.96770029	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000273C9966F71E6240BB515C3CD9E742C0
3093879	GAVIC412681818	VIC1938826	loc8e5a2b16aaaa	P	\N	\N	6	\N	\N	\N	\N	ALAMERE	DRIVE	\N	LOT 6 ALAMERE DRIVE	TRARALGON	3844	VIC	3844	0	\N	20350411000	20350411000	-38.19938477	146.50667162	STREET LOCALITY	4	0101000020A41E0000C3B666A736506240393CAD70851943C0
949439	GAVIC721479211	VIC1961369	loc22c42e389de3	P	S	\N	\N	UNIT 105	\N	43	\N	DANAHER	DRIVE	\N	UNIT 105, 43 DANAHER DRIVE	SOUTH MORANG	3752	VIC	3752	0	102\\PS849875	20631914610	20631914610	-37.64786543	145.08578837	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000DE7040C7BE2262408D072141EDD242C0
100812	GAVIC720746274	VIC1963362	loc6c0f29d040f7	P	\N	\N	\N	\N	\N	172	\N	FULHAM	ROAD	\N	172 FULHAM ROAD	TORRUMBARRY	3562	VIC	3562	0	1\\PS818996	20098990000	20098990000	-36.01112965	144.55463388	FRONTAGE CENTRE SETBACK	2	0101000020A41E000051FB8C8FBF1162400A6245B26C0142C0
1847787	GAVIC424633603	VIC2068283	loc72d1f0339be6	P	S	\N	\N	UNIT 4	\N	83	\N	WARRANDYTE	ROAD	\N	UNIT 4, 83 WARRANDYTE ROAD	RINGWOOD	3134	VIC	3134	1	4\\PS631475	20389280000	20389280000	-37.80532324	145.23009869	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E18CEDF75C2762401F41F9D414E742C0
3874598	GAVIC423639265	VIC1990231	loc9901d119afda_1	P	S	\N	\N	\N	LEVEL 15	530	\N	LITTLE COLLINS	STREET	\N	LEVEL 15, 530 LITTLE COLLINS STREET	MELBOURNE	3000	VIC	3000	0	\N	20664842000	20664842000	-37.81689612	144.95715084	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007264CCFAA01E62408DD0530D90E842C0
403773	GAVIC420049828	VIC1932666	loc4a6dd2077a69	P	\N	\N	\N	\N	\N	27	\N	ATHERTON	DRIVE	\N	27 ATHERTON DRIVE	VENUS BAY	3956	VIC	3956	1	467\\LP56449	20536410000	20536410000	-38.67927285	145.78890327	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000700B12B23E396240C5E7A969F25643C0
791741	GAVIC422409795	VIC2015298	loc3832b905a97e	P	S	\N	\N	UNIT 1	\N	53	\N	MAYFAIR	DRIVE	\N	UNIT 1, 53 MAYFAIR DRIVE	WEST WODONGA	3690	VIC	3690	2	1\\PS315404	20623640000	20623640000	-36.11670451	146.85930216	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A1523E677F5B624073DF622CF00E42C0
1470805	GAVIC419724052	VIC1953162	loc67a11408d754	P	S	\N	\N	UNIT 30	\N	123	\N	GORDON	STREET	\N	UNIT 30, 123 GORDON STREET	FOOTSCRAY	3011	VIC	3011	2	PC355367	20377160000	20377160000	-37.79520947	144.88899581	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000654757A7721C62404C8F856CC9E542C0
1314143	GAVIC420556912	VIC1976942	loc0b6e17218dd4	P	\N	\N	\N	\N	\N	22	\N	DRAPER	STREET	\N	22 DRAPER STREET	ORMOND	3204	VIC	3204	2	13\\LP20056	20194680000	20194680000	-37.90914884	145.05021891	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E802B0649B216240887F3BFD5EF442C0
574028	GAVIC720238978	VIC3621392	loc98325a7e67bf	P	\N	LUCAS LIFESTYLE ESTATE	\N	\N	\N	3	\N	REEVES	STREET	\N	3 REEVES STREET	LUCAS	3350	VIC	3350	2	35\\PS701379	20632004990	21318670000	-37.54967619	143.78368987	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000683BC7FC13F961404EB815CA5BC642C0
285706	GAVIC423890759	VIC2076350	loc910a14938d48	P	S	\N	\N	UNIT 4	\N	58	60	OCONNELL	STREET	\N	UNIT 4, 58-60 OCONNELL STREET	GEELONG WEST	3218	VIC	3218	2	4\\PS546320	20247600000	20247600000	-38.13903178	144.35024515	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A51A5135350B6240331A1ACBCB1143C0
3463920	GAVIC420812068	VIC2037177	loc29a798d6921b	P	P	\N	\N	\N	\N	1	\N	RHUS	COURT	\N	1 RHUS COURT	WERRIBEE	3030	VIC	3030	1	232\\LP132461	20626500000	20626500000	-37.88617430	144.66593933	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000B6FFF5F4F1562402187D2286EF142C0
3896584	GAVIC721705028	VIC2025962	loc9901d119afda_2	P	S	\N	\N	UNIT 804	LEVEL 8	31	\N	QUEENS	LANE	\N	UNIT 804, LEVEL 8, 31 QUEENS LANE	MELBOURNE	3004	VIC	3004	0	804\\PS913307	20532410000	20532410000	-37.84306552	144.97587008	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000D6D7E3533A1F624083642A92E9EB42C0
1189493	GAVIC420647207	VIC2034902	loc5ba812288f5b	P	P	\N	\N	\N	\N	11	\N	STEVENS	COURT	\N	11 STEVENS COURT	LEOPOLD	3224	VIC	3224	1	1\\PS520267	20234280000	20234280000	-38.18678995	144.45844070	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F9B4D48BAB0E6240593CABBBE81743C0
831238	GAVIC425730031	VIC3616200	loc0a03ed3531fd	P	\N	\N	\N	\N	\N	19	\N	BELLEVUE	ROAD	\N	19 BELLEVUE ROAD	CHELTENHAM	3192	VIC	3192	2	32\\PS727996	20050630000	21339270000	-37.96212191	145.04088787	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000800E14F44E216240871B8DCF26FB42C0
618376	GAVIC425511946	VIC3575102	loce0707ac065f9	P	P	\N	\N	\N	\N	6	\N	BARLING	COURT	\N	6 BARLING COURT	THOMSON	3219	VIC	3219	1	CM1\\PS644026	20246080000	20246080000	-38.16740494	144.37409513	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002C9E5996F80B6240923E6B866D1543C0
3709302	GAVIC424796248	VIC2061549	loc9901d119afda_1	P	S	\N	\N	SUITE 1	LEVEL 1	84	\N	WILLIAM	STREET	\N	SUITE 1, LEVEL 1, 84 WILLIAM STREET	MELBOURNE	3000	VIC	3000	0	1\\TP821947	20664851000	20664851000	-37.81715463	144.95917280	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CFE6278BB11E6240FFCFDD8598E842C0
3273566	GAVIC419701922	VIC1961086	loc1f73672977ce	P	S	\N	\N	UNIT 1	\N	24	\N	DALES	ROAD	\N	UNIT 1, 24 DALES ROAD	WARRNAMBOOL	3280	VIC	3280	2	60\\PS330936	20572640000	20572640000	-38.37631556	142.51798353	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000EF26325293D061408596B71B2B3043C0
3874680	GAVIC720512281	VIC1990305	loc9901d119afda_1	P	S	\N	\N	CARSPACE 2108Y	\N	659	\N	LITTLE LONSDALE	STREET	\N	CARSPACE 2108Y, 659 LITTLE LONSDALE STREET	MELBOURNE	3000	VIC	3000	0	2108Y\\PS746092	20664921000	20664921000	-37.81421733	144.95248254	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F4E9A9BC7A1E6240DD17024638E842C0
2227032	GAVIC411685451	VIC1985787	loc38cbe92d1159	P	\N	WALMSLEY VILLAGE	\N	\N	\N	51	\N	GREEVES	DRIVE	\N	51 GREEVES DRIVE	KILSYTH	3137	VIC	3137	2	51\\PS404622	20631994740	20631994740	-37.80704431	145.30974852	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E00004D6CBA75E9296240BBEF5A3A4DE742C0
3302344	GAVIC421862656	VIC1939111	loccaca39f133a7	P	S	\N	\N	UNIT 3	\N	23	\N	BAMFIELD	ROAD	\N	UNIT 3, 23 BAMFIELD ROAD	HEIDELBERG HEIGHTS	3081	VIC	3081	1	3\\RP15518	20022580000	20022580000	-37.74198384	145.05494793	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A74A2922C2216240F27A9353F9DE42C0
2705094	GAVIC425734206	VIC2062049	loc9e7da77def26	P	S	\N	\N	UNIT 406	LEVEL 4	67	\N	GALADA	AVENUE	\N	UNIT 406, LEVEL 4, 67 GALADA AVENUE	PARKVILLE	3052	VIC	3052	0	12406\\PS709099	20631904290	21309260000	-37.77969041	144.93938448	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000A7F0A700F1E624038FA35E5CCE342C0
973218	GAVIC419827679	VIC1983442	loc695c9ddc8068	P	\N	\N	\N	\N	\N	1	\N	KALYMNA	GROVE	\N	1 KALYMNA GROVE	ST KILDA EAST	3183	VIC	3183	2	1\\TP618386	20523090000	20523090000	-37.86659484	145.00504092	FRONTAGE CENTRE SETBACK	2	0101000020A41E00005651934B2920624057576894ECEE42C0
2775186	GAVIC412676977	VIC2007606	loc0a8087d68433	P	\N	\N	3	\N	\N	\N	\N	MAPLE	AVENUE	\N	LOT 3 MAPLE AVENUE	KOORLONG	3501	VIC	3501	0	\N	20631911250	20631911250	-34.24245637	142.03645944	STREET LOCALITY	4	0101000020A41E0000C6CDFCAC2AC16140AEED71CF081F41C0
3824306	GAVIC424746499	VIC1970018	loc9901d119afda_1	P	S	\N	\N	UNIT 116B	LEVEL 1	480	\N	COLLINS	STREET	\N	UNIT 116B, LEVEL 1, 480 COLLINS STREET	MELBOURNE	3000	VIC	3000	0	116B\\PS523999	20664863000	21315070000	-37.81774134	144.95798148	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C2D8C6C8A71E624090F18BBFABE842C0
3751472	GAVIC423826364	VIC1955713	loc9901d119afda_1	P	S	\N	\N	UNIT 218	LEVEL 2	268	\N	FLINDERS	STREET	\N	UNIT 218, LEVEL 2, 268 FLINDERS STREET	MELBOURNE	3000	VIC	3000	0	218B\\PS508080	20631944140	21334360000	-37.81775091	144.96565347	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000681D1BA2E61E6240B45CD30FACE842C0
3902539	GAVIC423837989	VIC2030282	loc9901d119afda_2	P	\N	CHARTIS BUILDING	\N	\N	\N	549	551	ST KILDA	ROAD	\N	549-551 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	0	35~9\\PP3084E	20400701000	21327870000	-37.84670035	144.97980325	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007768588C5A1F6240816154AD60EC42C0
1946376	GAVIC425732776	VIC1961067	loc5900b8cc74c8	P	S	\N	\N	UNIT 26	\N	1	\N	DALE	DRIVE	\N	UNIT 26, 1 DALE DRIVE	LEONGATHA	3953	VIC	3953	1	S3\\PS717009	20631994390	20631994390	-38.47219566	145.93627347	FRONTAGE CENTRE SETBACK	2	0101000020A41E000066B8C7F3F53D6240AE814AE8703C43C0
847671	GAVIC420298014	VIC2040515	loc4fa4b090ce9e	P	S	\N	\N	UNIT 15	\N	247	249	RIVERSDALE	ROAD	\N	UNIT 15, 247-249 RIVERSDALE ROAD	HAWTHORN EAST	3123	VIC	3123	1	15\\RP6990	20069550000	20069550000	-37.82989084	145.04535392	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A764108A732162406586F0DC39EA42C0
157526	GAVIC720474883	VIC1961465	loc12cc6354a4ba	P	\N	\N	6	\N	\N	\N	\N	EICKERTS	LANE	\N	LOT 6 EICKERTS LANE	MOUNT CAMEL	3523	VIC	3523	0	\N	20216831000	20216831000	-36.76209168	144.77072314	STREET LOCALITY	4	0101000020A41E0000411293C3A9186240AC135D388C6142C0
3024599	GAVIC421362480	VIC2021954	locf16910f90fb9	P	S	\N	\N	UNIT 1	\N	12	\N	MUIR	STREET	\N	UNIT 1, 12 MUIR STREET	HIGHETT	3190	VIC	3190	2	1\\PS337878	20052480000	20052480000	-37.94511464	145.03583624	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F9D90A9225216240AAE23A84F9F842C0
679108	GAVIC425707510	VIC3565705	loc8688ba223de1	P	P	\N	\N	\N	\N	2A	\N	COBBLER	LANE	\N	2A COBBLER LANE	MOUNT BULLER	3723	VIC	3723	0	181~A\\PP2370	20663884000	20663884000	-37.14516436	146.44446396	FRONTAGE CENTRE SETBACK	2	0101000020A41E00006C8E7B0C394E6240555FE9BE949242C0
1028498	GAVIC422034832	VIC2045776	loc6de6554b144b	P	S	\N	\N	\N	\N	113	\N	SIMMONDS CREEK	ROAD	\N	113 SIMMONDS CREEK ROAD	TAWONGA SOUTH	3698	VIC	3698	1	1\\LP216224	20001320000	20001320000	-36.74692880	147.15681829	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000DE5ECAA7046562406338E85C9B5F42C0
3860626	GAVIC719527287	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 1201	LEVEL 12	499	\N	ST KILDA	ROAD	\N	UNIT 1201, LEVEL 12, 499 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	0	1201\\PS737521	20631995350	21328350000	-37.84341251	144.97862647	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CC7475E8501F62405FBEEDF0F4EB42C0
3275084	GAVIC719430501	VIC2003761	loc8c9f2867857c	P	S	\N	\N	UNIT 101	\N	47	\N	NELSON	PLACE	\N	UNIT 101, 47 NELSON PLACE	WILLIAMSTOWN	3016	VIC	3016	2	101\\PS731964	20285524000	20285524000	-37.86452547	144.90815748	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F88646A00F1D6240C11A46C5A8EE42C0
1109772	GAVIC425539243	VICL3557670	loccabf2d0215b8	P	\N	PROVIDENCE VILLAGE	\N	\N	\N	27	\N	REMBRANDT	DRIVE	\N	27 REMBRANDT DRIVE	MADDINGLEY	3340	VIC	3340	2	2\\TP536334	20458571000	20458571000	-37.68646938	144.43016290	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E00007B6EFCE4C30D62401767883ADED742C0
3431043	GAVIC720144307	VIC2028102	loc67a11408d754	P	S	\N	\N	UNIT 202	\N	39	\N	RYAN	STREET	\N	UNIT 202, 39 RYAN STREET	FOOTSCRAY	3011	VIC	3011	1	202\\PS815389	20379442000	20379442000	-37.79888118	144.90259812	FRONTAGE CENTRE SETBACK	2	0101000020A41E000098DA7315E21C6240B5BE0EBD41E642C0
2131145	GAVIC412549753	VIC2012550	loc2424df148d7d	P	\N	\N	\N	\N	\N	68	\N	MONBULK-SEVILLE	ROAD	\N	68 MONBULK-SEVILLE ROAD	WANDIN EAST	3139	VIC	3139	2	1\\TP169088	20661460000	20661460000	-37.81416067	145.46469105	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CECFC3BFDE2E624073ABB56A36E842C0
1391972	GAVIC424776713	VIC3347454	loc232da9d11723	P	S	NRMA RIVERSIDE HOLIDAY PK	\N	SITE 62	\N	2	\N	MAIN	STREET	\N	SITE 62, 2 MAIN STREET	BAIRNSDALE	3875	VIC	3875	0	2B~1\\PP5027	20158530000	20158530000	-37.82535527	147.63783836	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B20AFE2B697462409A1DD23DA5E942C0
1473821	GAVIC422273680	VIC2063014	loc13ed320cd188	P	\N	\N	\N	\N	\N	35	\N	ALEXANDER	CLOSE	\N	35 ALEXANDER CLOSE	STRATHFIELDSAYE	3551	VIC	3551	1	CM1\\PS907241	20216412000	20216412000	-36.79372982	144.33627905	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008F4248CCC20A6240476151F0986542C0
2617573	GAVIC425368628	VIC2061938	loc9a86c6faf562	P	\N	\N	820	\N	\N	\N	\N	CALLAGHAN	STREET	\N	LOT 820 CALLAGHAN STREET	JACKASS FLAT	3556	VIC	3556	1	\N	20631994840	21316710000	-36.71300512	144.28908464	STREET LOCALITY	4	0101000020A41E00006E526E2E40096240E92374C0435B42C0
3539028	GAVIC720058933	VIC1981515	loc2c4c767ea9b7	P	S	\N	\N	UNIT 602	FLOOR 6	191	\N	HIGH	STREET	\N	UNIT 602, FLOOR 6, 191 HIGH STREET	PRESTON	3072	VIC	3072	0	611\\PS805184	20153581000	20153581000	-37.74644453	145.00241335	FRONTAGE CENTRE SETBACK	2	0101000020A41E00005D6A29C51320624065508E7E8BDF42C0
3542527	GAVIC425044566	VIC2038134	locf57f2052e543	P	\N	MENS SHED	\N	\N	\N	14	\N	STRINGYBARK	CRESCENT	\N	14 STRINGYBARK CRESCENT	FRANKSTON NORTH	3200	VIC	3200	1	13\\LP58497	20169440000	20169440000	-38.12221616	145.14787116	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E000017874C5CBB246240111F75C7A40F43C0
3344003	GAVIC425489617	VIC2055433	locc25e0bed112f	P	S	LIFESTYLE CHELSEA HEIGHTS	\N	UNIT 39	\N	29	\N	WELLS	ROAD	\N	UNIT 39, 29 WELLS ROAD	CHELSEA HEIGHTS	3196	VIC	3196	2	1\\PS646783	20631905500	20631905500	-38.02967451	145.13427691	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000DB2117FF4B246240C7FCD45FCC0343C0
3484225	GAVIC421307669	VIC1981006	locadc5cabaa80e	P	P	\N	\N	\N	\N	1456	\N	MALVERN	ROAD	\N	1456 MALVERN ROAD	GLEN IRIS	3146	VIC	3146	1	1\\PS336123	20556230000	20556230000	-37.85376115	145.04523577	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004D1849927221624034EC9C0B48ED42C0
1493334	GAVIC420206310	VIC1946124	loc29a798d6921b	P	\N	\N	\N	\N	\N	5	\N	CARMARTHEN	CLOSE	\N	5 CARMARTHEN CLOSE	WERRIBEE	3030	VIC	3030	2	26\\PS306342	20634910000	20634910000	-37.90765382	144.63738498	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F9812F7565146240A77E18002EF442C0
1045763	GAVIC422277019	VIC1948395	locb7bca082fca0	P	\N	\N	\N	\N	\N	35	\N	BEECH FOREST-LAVERS HILL	ROAD	\N	35 BEECH FOREST-LAVERS HILL ROAD	BEECH FOREST	3237	VIC	3237	1	2\\TP171629	20136091000	20136091000	-38.63253256	143.55789826	FRONTAGE CENTRE SETBACK	2	0101000020A41E000040A6734DDAF16140766DB1D3F65043C0
3028828	GAVIC721019485	VIC3259081	loc46443686a430	P	S	\N	\N	UNIT 2	\N	10	\N	DAVID	DRIVE	\N	UNIT 2, 10 DAVID DRIVE	SUNSHINE WEST	3020	VIC	3020	2	2\\PS844010	20632005060	20632005060	-37.79154382	144.78943090	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000763E9704431962401E20D24E51E542C0
2627235	GAVIC425032219	VIC2065334	locae68612e5fe1	P	\N	\N	\N	\N	\N	6	\N	WISTERIA	WAY	\N	6 WISTERIA WAY	WARRANWOOD	3134	VIC	3134	2	3A\\PS506101	20386850000	20386850000	-37.77740320	145.25265085	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000D0413CB71528624023E7B3F281E342C0
3815903	GAVIC413384563	VIC1944348	locb694454fbbb1	P	\N	\N	\N	\N	\N	275	\N	CANTERBURY	ROAD	\N	275 CANTERBURY ROAD	CANTERBURY	3126	VIC	3126	1	CP101885	20060072000	20060072000	-37.82413270	145.08375985	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F90E2329AE2262403708292E7DE942C0
9038	GAVIC425089969	VIC2022663	loc82baa1179308	P	S	\N	\N	UNIT 4	\N	3	\N	PRINCES	HIGHWAY	\N	UNIT 4, 3 PRINCES HIGHWAY	PAKENHAM	3810	VIC	3810	2	4\\PS708252	20632000370	20632000370	-38.07282307	145.48748069	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000699F1A71992F6240AC053044520943C0
3645329	GAVIC421986723	VIC1938427	loc02a3a330fe2f	P	S	\N	\N	UNIT 1	\N	11	13	CAIRNES	STREET	\N	UNIT 1, 11-13 CAIRNES STREET	INDENTED HEAD	3223	VIC	3223	2	CP156814	20262930000	20262930000	-38.13695688	144.70921964	FRONTAGE CENTRE SETBACK	2	0101000020A41E000063EF62EDB1166240F64794CD871143C0
3828904	GAVIC419598648	VIC1935950	loc098ac8eaabef	P	P	\N	\N	\N	\N	7	\N	BADGE	COURT	\N	7 BADGE COURT	LAVERTON	3028	VIC	3028	2	CM1\\PS914625	20281931000	20281931000	-37.86095143	144.76699564	FRONTAGE CENTRE SETBACK	2	0101000020A41E000030BF703A8B186240B0A50DA833EE42C0
2289640	GAVIC421787496	VIC2040573	locff58d0167065	P	\N	\N	\N	\N	\N	31	\N	RIVERVIEW	ROAD	\N	31 RIVERVIEW ROAD	BENALLA	3672	VIC	3672	2	1\\LP21901	20054420000	20054420000	-36.55703206	145.99080275	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002E01F8A7B43F6240024398D34C4742C0
2796679	GAVIC419898327	VIC1930047	locad899e5d272f	P	\N	\N	\N	\N	\N	12	\N	BENT	PARADE	\N	12 BENT PARADE	BLACK ROCK	3193	VIC	3193	2	1\\TP748491	20050080000	20050080000	-37.96762884	145.01379491	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A4E9050271206240B43B0743DBFB42C0
3279602	GAVIC422091233	VIC1957218	loc3319215a0a10	P	P	\N	\N	\N	\N	19	\N	FOOTE	STREET	\N	19 FOOTE STREET	BRIGHTON	3186	VIC	3186	1	CM\\RP8001	20042210000	20042210000	-37.89518376	144.99332219	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001D0E9E4BC91F62401F8EA66195F242C0
2723885	GAVIC419623906	VIC2013487	locf4e180745c81	P	P	\N	\N	\N	\N	63	\N	PIER	STREET	\N	63 PIER STREET	DROMANA	3936	VIC	3936	2	CM1\\PS623307	20631905960	20631905960	-38.33626879	144.96910952	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008DD4F7F1021F624095DB0FDB0A2B43C0
3867513	GAVIC411809712	VIC2025971	loc9901d119afda_2	P	S	\N	\N	UNIT 9A	\N	29	\N	QUEENS	ROAD	\N	UNIT 9A, 29 QUEENS ROAD	MELBOURNE	3004	VIC	3004	2	29\\SP25910	20530930000	20530930000	-37.84253725	144.97568145	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000BE24DC8381F6240B534B742D8EB42C0
112248	GAVIC424732111	VIC2075791	loca818c5eaa373	P	P	\N	\N	\N	\N	1E	\N	SUFFOLK	STREET	\N	1E SUFFOLK STREET	WEST FOOTSCRAY	3012	VIC	3012	0	2\\TP854883	20373630000	20373630000	-37.79081851	144.88186802	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003A294843381C6240BFC27A8A39E542C0
3405973	GAVIC425685032	VIC2025537	locf51f6cd689bb	P	S	MOMENTUM	\N	FLAT 101	\N	99	\N	PALMERSTON	CRESCENT	\N	FLAT 101, 99 PALMERSTON CRESCENT	SOUTH MELBOURNE	3205	VIC	3205	2	2101\\PS701488	20529470000	20529470000	-37.83622425	144.96722002	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000F83D6677F31E6240A2EF6E6509EB42C0
3202792	GAVIC419723191	VIC2060041	loc11fb0b5df130	P	\N	\N	\N	\N	\N	177	\N	VARY	STREET	\N	177 VARY STREET	MORWELL	3840	VIC	3840	2	82\\LP138947	20346020000	20346020000	-38.21986689	146.42878989	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F94C93A5B84D6240F9022799241C43C0
3339248	GAVIC719983320	VIC1990433	loc1e06c486c813	P	S	\N	\N	UNIT 108	LEVEL 1	108	\N	HAINES	STREET	\N	UNIT 108, LEVEL 1, 108 HAINES STREET	NORTH MELBOURNE	3051	VIC	3051	0	108\\PS742791	20401230000	21319870000	-37.79846579	144.94365758	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001F976171321E62402D83832034E642C0
3428406	GAVIC421736429	VIC2046842	loc3319215a0a10	P	P	\N	\N	\N	\N	15	\N	ROODING	STREET	\N	15 ROODING STREET	BRIGHTON	3186	VIC	3186	1	CM1\\PS843884	20043310000	20043310000	-37.90359279	145.00086460	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002C97321507206240C7F9B4EDA8F342C0
3140767	GAVIC424490619	VIC1962988	locc81a6ec90a1b	P	P	\N	\N	\N	\N	94	\N	ELIZABETH	DRIVE	\N	94 ELIZABETH DRIVE	ROSEBUD	3939	VIC	3939	0	RES1\\LP50907	20679480000	20679480000	-38.37560022	144.92224944	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BDF14111831D62409DA202AB133043C0
385552	GAVIC425369445	VIC3574045	loc75d84680b181	P	\N	\N	4	\N	\N	\N	\N	ELLIOTT	ROAD	\N	LOT 4 ELLIOTT ROAD	TENNYSON	3572	VIC	3572	0	\N	20099280000	20099280000	-36.31232749	144.47979695	STREET LOCALITY	4	0101000020A41E00000F1F227F5A0F62408C98E158FA2742C0
988883	GAVIC420734999	VIC2070226	locc7ee8539a72b	P	\N	\N	\N	\N	\N	4	\N	LALEHAM	COURT	\N	4 LALEHAM COURT	ELTHAM	3095	VIC	3095	2	340\\LP98918	20511710000	20511710000	-37.71607385	145.16041291	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CC49411A22256240AAA2D34EA8DB42C0
2078318	GAVIC719764462	VIC2007449	locddc4a1bcd8ba	P	S	\N	\N	UNIT 413	LEVEL 4	8	\N	PEARL RIVER	ROAD	\N	UNIT 413, LEVEL 4, 8 PEARL RIVER ROAD	DOCKLANDS	3008	VIC	3008	0	413\\PS728852	20631953180	21313600000	-37.81532063	144.93801394	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BF6FCF35041E624054CD286D5CE842C0
1626872	GAVIC721704323	VIC4172014	loc556974a8bc81	P	\N	\N	\N	\N	\N	12	\N	BLAZE	CIRCUIT	\N	12 BLAZE CIRCUIT	MELTON	3337	VIC	3337	1	26\\PS925472	20631907700	20631907700	-37.68506957	144.60475668	FRONTAGE CENTRE SETBACK	2	0101000020A41E00006754AE2A5A1362404151135CB0D742C0
1220652	GAVIC720699788	VIC1979366	loc15a8d395ef61	P	S	\N	\N	UNIT 23	\N	25	\N	MAIN	STREET	\N	UNIT 23, 25 MAIN STREET	NAR NAR GOON	3812	VIC	3812	0	4\\PS727423	20102750000	20102750000	-38.08411955	145.56881932	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000741793C433326240241AEE6DC40A43C0
345849	GAVIC420040549	VIC1956038	loc74f8893fb76e	P	S	\N	\N	UNIT 3	\N	64	74	GRAHAM	STREET	\N	UNIT 3, 64-74 GRAHAM STREET	BROADMEADOWS	3047	VIC	3047	1	PC350785	20631935260	20631935260	-37.69164883	144.92750496	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007DC2E11EAE1D62405595E8F287D842C0
3551406	GAVIC425614233	VIC1952570	loc5c27e3f22fc1	P	S	\N	\N	UNIT 202	\N	22	\N	FINDON	STREET	\N	UNIT 202, 22 FINDON STREET	HAWTHORN	3122	VIC	3122	2	11\\PS734295	20070660000	20070660000	-37.81291837	145.02045030	FRONTAGE CENTRE SETBACK	2	0101000020A41E000030366387A7206240DBBB8AB50DE842C0
2263000	GAVIC423081290	VIC2015632	loc679429866800	P	\N	\N	\N	\N	\N	9	\N	MCCLURES	LANE	\N	9 MCCLURES LANE	SANDY CREEK	3695	VIC	3695	2	14~D\\PP2734	20305911000	20305911000	-36.36565171	147.11768394	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E000010321C11C46362409716DCACCD2E42C0
2136194	GAVIC421930895	VIC1988479	loca56f2b16461e	P	\N	\N	\N	\N	\N	3	\N	LINCOLN	DRIVE	\N	3 LINCOLN DRIVE	BULLEEN	3105	VIC	3105	2	72\\LP13075	20366190000	20366190000	-37.76869185	145.09553392	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E1C1269D0E236240D3399A7E64E242C0
1882628	GAVIC419784455	VIC2037884	locb8f595af5fb8	P	\N	\N	\N	\N	\N	33	\N	STRADA	CRESCENT	\N	33 STRADA CRESCENT	WHEELERS HILL	3150	VIC	3150	2	49\\LP82206	20430970000	20430970000	-37.90814685	145.16734389	FRONTAGE CENTRE SETBACK	2	0101000020A41E000089D792E15A256240935BEE273EF442C0
2460034	GAVIC424531851	VIC3353154	loce16236caf708	P	\N	\N	\N	\N	\N	11	\N	BENETTI	DRIVE	\N	11 BENETTI DRIVE	LARA	3212	VIC	3212	2	14\\PS623387	20243894000	20243894000	-38.03352096	144.40048822	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000AAEAABCCD00C62401B77316A4A0443C0
3283826	GAVIC419621302	VIC1945465	loc9165cd64854f	P	S	\N	\N	UNIT 23	\N	346	354	BAYSWATER	ROAD	\N	UNIT 23, 346-354 BAYSWATER ROAD	BAYSWATER NORTH	3153	VIC	3153	2	23\\RP12800	20385610000	20385610000	-37.83366186	145.26791988	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008B51B6CC92286240AF4F8C6EB5EA42C0
1889105	GAVIC420255830	VIC2023947	loc8f565e81c655	P	\N	\N	\N	\N	\N	28	\N	OXFORD	DRIVE	\N	28 OXFORD DRIVE	THOMASTOWN	3074	VIC	3074	2	14\\LP96082	20613420000	20613420000	-37.68269584	145.03281694	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C1811CD60C21624027F5C89362D742C0
2687973	GAVIC424353303	VIC1953363	loc9fb289b0a33e	P	\N	\N	\N	\N	\N	1064	1068	COWRA	AVENUE	\N	1064-1068 COWRA AVENUE	IRYMPLE	3498	VIC	3498	1	2\\LP210288	20631960980	20631960980	-34.23335670	142.14417227	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007C142A0F9DC46140B866E1A1DE1D41C0
2198307	GAVIC420684174	VIC2070646	loc4ff8c926c940	P	P	\N	\N	\N	\N	13	\N	YOORALLA	STREET	\N	13 YOORALLA STREET	ASHWOOD	3147	VIC	3147	0	340\\LP53681	20631968970	20631968970	-37.86815522	145.10391638	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CCB371485323624037E0D2B51FEF42C0
2045145	GAVIC425275442	VIC1961385	loc2d817b7080e2	P	S	\N	\N	UNIT 302	FLOOR 3	839	\N	DANDENONG	ROAD	\N	UNIT 302, FLOOR 3, 839 DANDENONG ROAD	MALVERN EAST	3145	VIC	3145	0	302\\PS629876	20554564000	20554564000	-37.87483964	145.04077496	FRONTAGE CENTRE SETBACK	2	0101000020A41E000043F649074E216240AF85CDBEFAEF42C0
1848317	GAVIC423402101	VIC1979663	loce36428dd6505	P	\N	\N	26	\N	\N	\N	\N	MALDON-NEWSTEAD	ROAD	\N	LOT 26 MALDON-NEWSTEAD ROAD	WELSHMANS REEF	3462	VIC	3462	0	\N	20505520000	20505520000	-37.06504795	144.04554759	STREET LOCALITY	4	0101000020A41E0000C62E382075016240FFF5C07D538842C0
1563246	GAVIC421689281	VIC1980714	locd6f79866f950	P	\N	\N	\N	\N	\N	63	\N	LAURA	ROAD	\N	63 LAURA ROAD	KNOXFIELD	3180	VIC	3180	2	38\\LP52614	20335960000	20335960000	-37.89255286	145.24271688	FRONTAGE CENTRE SETBACK	2	0101000020A41E000030B93056C42762405DD30F2C3FF242C0
2432594	GAVIC420504897	VIC1974317	loc5c27e3f22fc1	P	P	\N	\N	\N	\N	563	\N	GLENFERRIE	ROAD	\N	563 GLENFERRIE ROAD	HAWTHORN	3122	VIC	3122	0	CM1\\PS610457	20070880000	20070880000	-37.82695143	145.03433532	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000ED8F6246192162407F9D618BD9E942C0
3148239	GAVIC425520470	VIC1985134	loc31f384e524fe	P	S	\N	\N	UNIT 2504	LEVEL 25	118	\N	KAVANAGH	STREET	\N	UNIT 2504, LEVEL 25, 118 KAVANAGH STREET	SOUTHBANK	3006	VIC	3006	0	2504\\PS647246	20631979060	20631979060	-37.82567255	144.96208951	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CAA8F06FC91E62403BBA5BA3AFE942C0
3042299	GAVIC425786720	VIC2042282	loc6de0828869d7	P	S	\N	\N	UNIT 205D	\N	21	\N	ROBERT	STREET	\N	UNIT 205D, 21 ROBERT STREET	COLLINGWOOD	3066	VIC	3066	2	205D\\PS411166	20642471000	20642471000	-37.80579441	144.98717136	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000EE5764E8961F6240F31F6F4524E742C0
2471242	GAVIC419711232	VIC1984845	locf16910f90fb9	P	\N	\N	\N	\N	\N	19	\N	KAREN	STREET	\N	19 KAREN STREET	HIGHETT	3190	VIC	3190	2	3A\\PS420083	20312320000	20312320000	-37.95650684	145.05521891	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004492725AC4216240A419EED06EFA42C0
2844711	GAVIC423792711	VIC1993696	locddc4a1bcd8ba	P	S	\N	\N	UNIT 3001	LEVEL 30	100	\N	HARBOUR	ESPLANADE	\N	UNIT 3001, LEVEL 30, 100 HARBOUR ESPLANADE	DOCKLANDS	3008	VIC	3008	0	3001\\PS509916	20631926900	20631926900	-37.81829164	144.94697159	FRONTAGE CENTRE SETBACK	2	0101000020A41E000051295D974D1E6240F231CCC7BDE842C0
590997	GAVIC419906596	VIC2061305	loc82b861dfb765	P	\N	\N	\N	\N	\N	263	\N	VICTORIA	ROAD	\N	263 VICTORIA ROAD	THORNBURY	3071	VIC	3071	2	1\\TP861600	20140990000	20140990000	-37.76388184	145.01220893	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003762FB0364206240776750E1C6E142C0
1275053	GAVIC719213944	VIC3619998	locf8d60bf51b6b	P	\N	\N	\N	\N	\N	33	\N	BALAKA	STREET	\N	33 BALAKA STREET	CAPEL SOUND	3940	VIC	3940	2	502\\LP89700	20485920000	20485920000	-38.37019588	144.88061497	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000941072FF2D1C624062DB1E94622F43C0
3726220	GAVIC421300189	VIC2019697	loc6280f9052ec0	P	\N	\N	\N	\N	\N	358	360	POUND	ROAD	\N	358-360 POUND ROAD	NARRE WARREN SOUTH	3805	VIC	3805	1	8\\LP41754	20111180000	20111180000	-38.03968301	145.28998847	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BF5BE6954729624013143755140543C0
3906587	GAVIC423874856	VIC1944127	loc9901d119afda_1	P	S	\N	\N	\N	LEVEL 32	600	\N	BOURKE	STREET	\N	LEVEL 32, 600 BOURKE STREET	MELBOURNE	3000	VIC	3000	1	PC369270	20664810000	20664810000	-37.81598779	144.95632191	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BFFC67309A1E62401FFEB34972E842C0
591602	GAVIC421300826	VIC1979239	locf066999b6a14	P	\N	\N	\N	\N	\N	9	\N	LARA	COURT	\N	9 LARA COURT	HALLAM	3803	VIC	3803	2	21\\LP208558	20124160000	20124160000	-37.99747286	145.26113486	FRONTAGE CENTRE SETBACK	2	0101000020A41E000075717E375B2862407E2CD030ADFF42C0
3697309	GAVIC719607123	VIC1935604	loc9901d119afda_1	P	S	\N	\N	UNIT 4608	LEVEL 46	81	\N	ABECKETT	STREET	\N	UNIT 4608, LEVEL 46, 81 ABECKETT STREET	MELBOURNE	3000	VIC	3000	0	4608\\PS726465	20631917160	21328320000	-37.80936093	144.96121215	FRONTAGE CENTRE SETBACK	2	0101000020A41E00009298FB3FC21E62404C81922399E742C0
2628813	GAVIC421524934	VIC1965184	loc4195fdfecc8e	P	S	\N	\N	FLAT 6	\N	34	\N	GARDENIA	ROAD	\N	FLAT 6, 34 GARDENIA ROAD	GARDENVALE	3185	VIC	3185	2	6\\RP10477	20186940000	20186940000	-37.89690153	145.00928409	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008ADD250E4C2062408B8A59ABCDF242C0
43516	GAVIC421281678	VIC2075671	loc4ff8c926c940	P	\N	\N	\N	\N	\N	47	61	MONTPELLIER	ROAD	\N	47-61 MONTPELLIER ROAD	ASHWOOD	3147	VIC	3147	1	1\\TP257898	20436380000	20436380000	-37.85929785	145.10725291	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003A9BA79D6E236240F5A2D178FDED42C0
2185064	GAVIC420191477	VIC2066892	loc875118ed8437	P	S	\N	\N	UNIT 6	\N	60	\N	CONDELL	STREET	\N	UNIT 6, 60 CONDELL STREET	FITZROY	3065	VIC	3065	2	1\\TP249892	20641410000	20641410000	-37.80273850	144.98180443	FRONTAGE CENTRE SETBACK	2	0101000020A41E000060BD1FF16A1F6240BB5E9A22C0E642C0
2452938	GAVIC424637478	VIC1961385	loc2d817b7080e2	P	S	CHADSTONE SHOPPING CENTRE	\N	UNIT 339A	\N	1341	\N	DANDENONG	ROAD	\N	UNIT 339A, 1341 DANDENONG ROAD	MALVERN EAST	3145	VIC	3145	1	1\\TP950949	20555600000	20555600000	-37.88768200	145.08061617	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B9B55C6894226240BA9F53909FF142C0
3767234	GAVIC423490362	VIC2030282	loc9901d119afda_2	P	S	\N	\N	CARSPACE 303	\N	431	\N	ST KILDA	ROAD	\N	CARSPACE 303, 431 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	0	303\\RP18468	20631975640	20631975640	-37.83862075	144.97687491	FRONTAGE CENTRE SETBACK	2	0101000020A41E000074D72B8F421F62409D7FBBEC57EB42C0
2743445	GAVIC423401833	VIC1999638	loc1c5f2c23fc52	P	\N	\N	12	\N	\N	\N	\N	MACADAM	STREET	\N	LOT 12 MACADAM STREET	TOWONG	3707	VIC	3707	0	\N	20568310000	20568310000	-36.12645326	147.98920079	STREET LOCALITY	4	0101000020A41E000047476A88A77F62401716D49E2F1042C0
826684	GAVIC420048609	VIC1960955	locf51f6cd689bb	P	P	\N	\N	\N	\N	536	\N	CITY	ROAD	\N	536 CITY ROAD	SOUTH MELBOURNE	3205	VIC	3205	2	3\\RP18126	20528882000	20528882000	-37.83279084	144.95148594	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000EC5CA492721E6240AC1AE7E398EA42C0
1930336	GAVIC421612837	VIC1935609	locbd7d4fd6b9e7	P	\N	\N	\N	\N	\N	48	\N	ABECKETT	STREET	\N	48 ABECKETT STREET	COBURG	3058	VIC	3058	2	35~E\\LP1653	20471770000	20471770000	-37.73377284	144.95686895	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000DAD9A1AB9E1E62401C3FB744ECDD42C0
1292165	GAVIC721476998	VIC2005249	loc3319215a0a10	P	S	\N	\N	UNIT 213	FLOOR 2	538	\N	NEW	STREET	\N	UNIT 213, FLOOR 2, 538 NEW STREET	BRIGHTON	3186	VIC	3186	0	PC382446	20046650000	20046650000	-37.88790169	144.99668006	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CFC894CDE41F62407B4E38C3A6F142C0
984420	GAVIC424034425	VIC2038936	locf066999b6a14	P	S	\N	\N	FACTORY 2	\N	14	\N	RIMFIRE	DRIVE	\N	FACTORY 2, 14 RIMFIRE DRIVE	HALLAM	3803	VIC	3803	1	1\\PS604177	20127070000	20127070000	-38.01934566	145.27359847	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000571C9451C1286240808228EB790243C0
2825420	GAVIC423215409	VIC2055058	locfe955a87410d	P	S	\N	\N	UNIT 86	\N	151	\N	FITZROY	STREET	\N	UNIT 86, 151 FITZROY STREET	ST KILDA	3182	VIC	3182	2	1\\PS324369	20522370000	20522370000	-37.85909600	144.97901820	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000BE6F91D541F6240ED0F94DBF6ED42C0
3897721	GAVIC721369066	VIC1992749	loc9901d119afda_1	P	S	\N	\N	UNIT 4205	LEVEL 42	299	\N	KING	STREET	\N	UNIT 4205, LEVEL 42, 299 KING STREET	MELBOURNE	3000	VIC	3000	0	4205\\PS827459	20664910000	20664910000	-37.81323986	144.95401004	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000613B1040871E62407740653E18E842C0
470755	GAVIC424551158	VIC1937475	loc245c69160468	P	\N	\N	7	\N	\N	\N	\N	BALD HILL	ROAD	\N	LOT 7 BALD HILL ROAD	HEPBURN	3461	VIC	3461	0	\N	20273020000	20273020000	-37.31224832	144.12364674	STREET LOCALITY	4	0101000020A41E0000D31102EAF4036240C350C1C0F7A742C0
3748394	GAVIC411803305	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 1006	\N	582	\N	ST KILDA	ROAD	\N	UNIT 1006, 582 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	2	76\\PS404635	20532210000	20532210000	-37.84919580	144.97982610	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008DE843BC5A1F62404573AE72B2EC42C0
3072756	GAVIC411441273	VIC2036759	locadc5cabaa80e	P	S	\N	\N	UNIT 2	\N	159	\N	TOORONGA	ROAD	\N	UNIT 2, 159 TOORONGA ROAD	GLEN IRIS	3146	VIC	3146	0	2\\RP13641	20555940000	20555940000	-37.86009234	145.04063792	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000142CE5E74C21624089EB7B8117EE42C0
3597593	GAVIC421379520	VIC1978203	locfd8472c41cbe	P	P	\N	\N	\N	\N	43	\N	HENDERSON	ROAD	\N	43 HENDERSON ROAD	ROWVILLE	3178	VIC	3178	1	CM\\SP34466	20338560000	20338560000	-37.90586486	145.24739088	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B85D47A0EA276240D7253661F3F342C0
1584782	GAVIC720126989	VICL3620952	locabdfa0718385	P	\N	\N	\N	\N	\N	4	\N	SILVEREYE	STREET	\N	4 SILVEREYE STREET	KURUNJANG	3337	VIC	3337	2	191\\PS820751	20631979930	21327970000	-37.65572307	144.58248534	FRONTAGE CENTRE SETBACK	2	0101000020A41E000062B64BB8A3126240FD70CABBEED342C0
3564106	GAVIC425157653	VIC1960955	locf51f6cd689bb	P	\N	\N	\N	\N	\N	512	512A	CITY	ROAD	\N	512-512A CITY ROAD	SOUTH MELBOURNE	3205	VIC	3205	0	CM1\\PS630408	20530491000	20530491000	-37.83226723	144.95228428	FRONTAGE CENTRE SETBACK	2	0101000020A41E000009E3E11C791E6240F6308BBB87EA42C0
899027	GAVIC413630613	VIC2072985	loc2f9c80de6f7d	P	P	\N	\N	\N	\N	11	\N	HIGHMOOR	AVENUE	\N	11 HIGHMOOR AVENUE	BAYSWATER	3153	VIC	3153	1	1\\PS307961	20326870000	20326870000	-37.84333097	145.26442452	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002335692A762862404EEDEB44F2EB42C0
2629350	GAVIC421143250	VIC1983036	loc36422efcb9c0	P	\N	\N	\N	\N	\N	25	\N	HILL	STREET	\N	25 HILL STREET	CLIFTON SPRINGS	3222	VIC	3222	2	1334\\LP54102	20259980000	20259980000	-38.16280641	144.55745027	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007CD9F2A1D6116240BC4327D7D61443C0
1732063	GAVIC423406602	VIC2024336	loc5c94ac6107ca	P	\N	\N	7	\N	\N	\N	\N	PUNCHBOWL	ROAD	\N	LOT 7 PUNCHBOWL ROAD	FLINDERS	3929	VIC	3929	0	\N	20495980000	20495980000	-38.46960069	144.97904009	STREET LOCALITY	4	0101000020A41E0000BC00E24B541F624051DD1AE01B3C43C0
2255996	GAVIC423401116	VIC2073892	loc8a2c57a8fa9c	P	\N	\N	18	\N	\N	\N	\N	LEITCHVILLE-PYRAMID	ROAD	\N	LOT 18 LEITCHVILLE-PYRAMID ROAD	LEITCHVILLE	3567	VIC	3567	0	\N	20351381000	20351381000	-35.94079711	144.24614762	STREET LOCALITY	4	0101000020A41E00006C3CF970E007624087CF290A6CF841C0
1843250	GAVIC420949509	VIC1997189	locdf0288b649a4	P	P	\N	\N	\N	\N	4	\N	IONA	COURT	\N	4 IONA COURT	WODONGA	3690	VIC	3690	2	5\\LP114867	20631923100	20631923100	-36.12617623	146.89489306	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C143C5F6A25C6240F8B0EE8A261042C0
1538375	GAVIC720132188	VIC3626389	loc5ba812288f5b	P	\N	\N	\N	\N	\N	42	\N	KANGAROO PAW	DRIVE	\N	42 KANGAROO PAW DRIVE	LEOPOLD	3224	VIC	3224	2	23\\PS816120	20631919120	20631919120	-38.20247914	144.46241460	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002C06B419CC0E62400B3622D6EA1943C0
3556537	GAVIC419645242	VIC2014251	loc86cf2bd4847b	P	P	\N	\N	\N	\N	74	\N	MOONYA	ROAD	\N	74 MOONYA ROAD	CARNEGIE	3163	VIC	3163	1	CM1\\PS509940	20188460000	20188460000	-37.89712682	145.06369376	FRONTAGE CENTRE SETBACK	2	0101000020A41E000019057FC709226240DA21380DD5F242C0
826388	GAVIC420610243	VIC1950981	loc22c42e389de3	P	\N	\N	\N	\N	\N	6	\N	ARMITAGE	PLACE	\N	6 ARMITAGE PLACE	SOUTH MORANG	3752	VIC	3752	2	68\\PS422011	20606930000	20606930000	-37.63707884	145.06421894	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000AEE2E0140E2262400663A7CC8BD142C0
987719	GAVIC421658800	VIC2016584	locba8f7a4a0c92	P	\N	\N	\N	\N	\N	7	\N	PLATYPUS	COURT	\N	7 PLATYPUS COURT	BARANDUDA	3691	VIC	3691	2	240\\LP211937	20621310000	20621310000	-36.18544068	146.94689729	FRONTAGE CENTRE SETBACK	2	0101000020A41E000013A78BFB4C5E624058F92B85BC1742C0
1549727	GAVIC421147883	VIC2073360	loc12c0177d3d38	P	P	\N	\N	\N	\N	10	\N	STEWART	STREET	\N	10 STEWART STREET	PASCOE VALE	3044	VIC	3044	1	\N	20631910580	20631910580	-37.72752400	144.92603870	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000926AE91BA21D62400E87A5811FDD42C0
835807	GAVIC420833582	VIC1985830	loc51ba976fe589	P	\N	\N	\N	\N	\N	32	\N	GREGORY	STREET	\N	32 GREGORY STREET	OAK PARK	3046	VIC	3046	2	350\\LP11526	20474111000	20474111000	-37.72169983	144.91638095	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000AD5D24FE521D62407BB0F7A860DC42C0
3894304	GAVIC721284836	VIC1994837	loc9901d119afda_1	P	S	\N	\N	UNIT 6706	LEVEL 67	648	\N	LONSDALE	STREET	\N	UNIT 6706, LEVEL 67, 648 LONSDALE STREET	MELBOURNE	3000	VIC	3000	0	6706D\\PS746092	20664921000	20664921000	-37.81448127	144.95342148	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000ED7CC36D821E624062ED18EC40E842C0
1272328	GAVIC424877747	VIC2064406	loc92bf5bc798e7	P	S	SHOWGROUNDS VILLAGE SHOPPING M	\N	SHOP 22	\N	320	380	EPSOM	ROAD	\N	SHOP 22, 320-380 EPSOM ROAD	FLEMINGTON	3031	VIC	3031	1	2216\\PP2541	20400290000	20400290000	-37.78236924	144.91614705	FRONTAGE CENTRE SETBACK	2	0101000020A41E000076429E13511D62402399DDAC24E442C0
3399333	GAVIC419943868	VIC1931054	loc0a03ed3531fd	P	\N	\N	\N	\N	\N	82	\N	CENTRE DANDENONG	ROAD	\N	82 CENTRE DANDENONG ROAD	CHELTENHAM	3192	VIC	3192	2	5\\LP51716	20308110000	20308110000	-37.96700885	145.06742590	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E86C5C5A28226240A6D82CF2C6FB42C0
2156994	GAVIC421756773	VIC2058076	locb8f595af5fb8	P	P	COMMUNITY CENTRE	\N	\N	\N	101	121	WHALLEY	DRIVE	\N	101-121 WHALLEY DRIVE	WHEELERS HILL	3150	VIC	3150	1	1\\PS648520	20631989070	20631989070	-37.92066388	145.19469529	FRONTAGE CENTRE SETBACK	2	0101000020A41E000087E79DF13A266240AF9A6350D8F542C0
3482362	GAVIC424777831	VIC1971247	locb281644d861d	P	P	\N	\N	\N	\N	10	12	GILMORE	COURT	\N	10-12 GILMORE COURT	BELGRAVE SOUTH	3160	VIC	3160	0	6\\LP9574	20651040000	20651040000	-37.93104574	145.35682189	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008081BD156B2B6240A830BE812CF742C0
1010520	GAVIC423394320	VIC2053994	loc5e68bb81d75d	P	\N	\N	19	\N	\N	\N	\N	COUGHLAN	ROAD	\N	LOT 19 COUGHLAN ROAD	OAKVALE	3540	VIC	3540	0	\N	20181836000	20181836000	-35.90946143	143.55433875	STREET LOCALITY	4	0101000020A41E0000FA449E24BDF1614065696D3B69F441C0
1873473	GAVIC420454965	VIC1989474	loc67d2e4d427ab	P	\N	\N	\N	\N	\N	358	\N	HOTHAM	ROAD	\N	358 HOTHAM ROAD	PORTSEA	3944	VIC	3944	2	4\\LP110711	20492500000	20492500000	-38.33081682	144.70910593	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FD57EBFEB0166240F16E9F34582A43C0
3760651	GAVIC719913448	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 615	\N	450	\N	ST KILDA	ROAD	\N	UNIT 615, 450 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	2	615\\PS738892	20631933390	20631933390	-37.83867611	144.97599334	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003E8D62563B1F6240793120BD59EB42C0
780498	GAVIC421242246	VIC1969874	loc201e214973bd	P	\N	\N	\N	\N	\N	38	\N	GILBERT	ROAD	\N	38 GILBERT ROAD	IVANHOE	3079	VIC	3079	2	2\\PS423690	20017970000	20017970000	-37.77270184	145.04675093	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000B6DCEFB7E216240F52DD6E4E7E242C0
939642	GAVIC419618007	VIC1997861	loc656f84726510	P	\N	\N	\N	\N	\N	9	\N	LUCILLE	AVENUE	\N	9 LUCILLE AVENUE	RESERVOIR	3073	VIC	3073	2	8\\LP44181	20150610000	20150610000	-37.70012084	145.02125194	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000DA688C18AE2062402686478F9DD942C0
2014788	GAVIC719413114	VIC2061025	locb948618ae376	P	S	\N	\N	UNIT 1	\N	11	\N	VERDON	STREET	\N	UNIT 1, 11 VERDON STREET	SEBASTOPOL	3356	VIC	3356	2	1\\PS800139	20014000000	20014000000	-37.58334028	143.83740943	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C966DC0ECCFA61400E85F0E4AACA42C0
3768806	GAVIC412717346	VIC2027065	loc9901d119afda_1	P	\N	\N	\N	\N	\N	8	\N	SPENCER	STREET	\N	8 SPENCER STREET	MELBOURNE	3000	VIC	3000	1	CP109146	20664190000	20664190000	-37.82074898	144.95546114	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C49C3D23931E6240A5A9754D0EE942C0
145166	GAVIC424263462	VIC1975583	loc5e975e2e1c0e	P	\N	\N	\N	\N	\N	12	\N	FERNLEA	CLOSE	\N	12 FERNLEA CLOSE	TRAFALGAR	3824	VIC	3824	2	160\\PS542238	20037872000	20037872000	-38.21939215	146.15804669	FRONTAGE CENTRE SETBACK	2	0101000020A41E00005099EEB70E456240E39FBE0A151C43C0
286285	GAVIC424246587	VIC2048971	locd724f9a08a75	P	\N	\N	\N	\N	\N	88	\N	SMITH	STREET	\N	88 SMITH STREET	WARRAGUL	3820	VIC	3820	0	CP159156	20040260000	20040260000	-38.15891757	145.93303540	FRONTAGE CENTRE SETBACK	2	0101000020A41E000054200E6DDB3D624074F43269571443C0
2328317	GAVIC419802779	VIC2046214	locec99dd6d0979	P	\N	\N	\N	\N	\N	60	\N	TALBOT	STREET	\N	60 TALBOT STREET	ALTONA MEADOWS	3028	VIC	3028	2	15~P\\LP1204	20632003550	20632003550	-37.87069403	144.78540965	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CF166B132219624013D6E7E672EF42C0
2219132	GAVIC424917511	VIC3556163	loc4161e46afd2f	P	\N	\N	\N	\N	\N	9	\N	SOLOMON	WAY	\N	9 SOLOMON WAY	BEVERIDGE	3753	VIC	3753	2	243\\PS617320	20631967000	20631967000	-37.48082776	144.95340078	FRONTAGE CENTRE SETBACK	2	0101000020A41E000097425A42821E6240BE1A98C38BBD42C0
1547738	GAVIC420703086	VIC1975240	loc913bf4728c4e	P	\N	\N	\N	\N	\N	5	\N	DOONKUNA	AVENUE	\N	5 DOONKUNA AVENUE	CAMBERWELL	3124	VIC	3124	2	25~C\\LP8259	20060940000	20060940000	-37.83804685	145.07381991	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CC6792BB5C22624006A2821E45EB42C0
1932539	GAVIC421444901	VIC2028669	loc3b583afba248	P	\N	\N	\N	\N	\N	551	\N	SPRINGVALE	ROAD	\N	551 SPRINGVALE ROAD	SPRINGVALE SOUTH	3172	VIC	3172	2	20\\LP79867	20228130000	20228130000	-37.97050256	145.14903033	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C92E41DBC424624030F1896D39FC42C0
624289	GAVIC419784186	VIC1942036	locc0b6d754799e	P	\N	\N	\N	\N	\N	7	\N	BARKLY	STREET	\N	7 BARKLY STREET	CRANBOURNE	3977	VIC	3977	2	249\\LP40698	20118600000	20118600000	-38.10147586	145.28727385	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000DFD7ED583129624049043629FD0C43C0
2289492	GAVIC412676699	VIC1970763	loc0de2086617a5	P	\N	\N	1	\N	\N	\N	\N	DIFFEY	ROAD	\N	LOT 1 DIFFEY ROAD	EVERTON	3678	VIC	3678	0	\N	20571470000	20571470000	-36.42068667	146.57888840	STREET LOCALITY	4	0101000020A41E00001541F74086526240AFC1900FD93542C0
1537611	GAVIC425274882	VIC1953262	loc31f384e524fe	P	S	\N	\N	UNIT 1905	LEVEL 19	39	\N	COVENTRY	STREET	\N	UNIT 1905, LEVEL 19, 39 COVENTRY STREET	SOUTHBANK	3006	VIC	3006	0	1905\\PS638768	20631981110	20631981110	-37.82945629	144.96918736	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B1DC3595031F62407981AB9F2BEA42C0
3436121	GAVIC412527335	VIC1995210	loc4a341f4d3e02	P	S	LEVANDE SALFORD PARK	\N	UNIT 115B	\N	100	\N	HAROLD	STREET	\N	UNIT 115B, 100 HAROLD STREET	WANTIRNA	3152	VIC	3152	2	2\\PS728985	20335682000	20335682000	-37.85362056	145.22722126	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000FD148565452762405532427043ED42C0
2785377	GAVIC719010591	VIC2059530	loc1e06c486c813	P	S	\N	\N	UNIT 524	LEVEL 5	33	\N	BLACKWOOD	STREET	\N	UNIT 524, LEVEL 5, 33 BLACKWOOD STREET	NORTH MELBOURNE	3051	VIC	3051	0	524\\PS719578	20401531000	20401531000	-37.80043670	144.95542694	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008EA084DB921E62405382B4B574E642C0
2915868	GAVIC424675889	VIC2981005	locff62fb6a898a	P	\N	\N	\N	\N	\N	42	\N	MYHAVEN	CIRCUIT	\N	42 MYHAVEN CIRCUIT	CARRUM DOWNS	3201	VIC	3201	2	85\\PS611686	20631986160	20631986160	-38.08837093	145.18359652	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E721CF05E0256240312217BD4F0B43C0
861446	GAVIC420695756	VIC2023428	loc3754c5fc3408	P	\N	\N	\N	\N	\N	48	\N	MURCHISON	DRIVE	\N	48 MURCHISON DRIVE	ROXBURGH PARK	3064	VIC	3064	2	1846\\PS344030	20300460000	20300460000	-37.63298383	144.93415096	FRONTAGE CENTRE SETBACK	2	0101000020A41E000044D78D90E41D6240985F389D05D142C0
3597328	GAVIC424684358	VIC2037884	locb8f595af5fb8	P	S	\N	\N	UNIT 1	\N	53	\N	STRADA	CRESCENT	\N	UNIT 1, 53 STRADA CRESCENT	WHEELERS HILL	3150	VIC	3150	2	1\\PS835402	20430970000	20430970000	-37.90973248	145.16705403	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007B70B18158256240C0DA281D72F442C0
2848511	GAVIC420921756	VIC1976701	loc1eda86883ae9	P	\N	\N	\N	\N	\N	23	\N	DOVER	STREET	\N	23 DOVER STREET	SUNDERLAND BAY	3922	VIC	3922	2	151\\LP54853	20032220000	20032220000	-38.50680422	145.27731319	FRONTAGE CENTRE SETBACK	2	0101000020A41E00009539E9BFDF286240F92FEFF5DE4043C0
1805803	GAVIC419780964	VIC2007417	locb344fc28a060	P	\N	\N	\N	\N	\N	149	155	PEARCEDALE	ROAD	\N	149-155 PEARCEDALE ROAD	PEARCEDALE	3912	VIC	3912	0	4\\PS749865	20128480000	20128480000	-38.19602626	145.23626340	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BD0743788F276240B8ED7363171943C0
3493947	GAVIC719096818	VIC1955611	loc1e06c486c813	P	S	\N	\N	UNIT 208	LEVEL 2	83	\N	FLEMINGTON	ROAD	\N	UNIT 208, LEVEL 2, 83 FLEMINGTON ROAD	NORTH MELBOURNE	3051	VIC	3051	0	208\\PS704450	20395952000	21301480000	-37.79869617	144.95324680	FRONTAGE CENTRE SETBACK	2	0101000020A41E000088E06EFF801E624094CB14AD3BE642C0
230301	GAVIC424727151	VICL3552638	locc5abea08e85d	P	\N	\N	\N	\N	\N	9	\N	BRINDABELLA	CHASE	\N	9 BRINDABELLA CHASE	POINT COOK	3030	VIC	3030	2	2165\\PS511700	20631941560	20631941560	-37.90634255	144.76479556	FRONTAGE CENTRE SETBACK	2	0101000020A41E00006FCA893479186240939C5D0803F442C0
1896296	GAVIC420390898	VIC2072267	loc9fe59dbd0874	P	\N	\N	\N	\N	\N	124	\N	LAWLESS	DRIVE	\N	124 LAWLESS DRIVE	CRANBOURNE NORTH	3977	VIC	3977	2	224\\PS300273	20117410000	20117410000	-38.06949586	145.27640385	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A207E34CD828624026F4863DE50843C0
192197	GAVIC720743838	VIC3623473	loc6a54ce63b777	P	\N	\N	\N	\N	\N	74	\N	PRESENTATION	BOULEVARD	\N	74 PRESENTATION BOULEVARD	WINTER VALLEY	3358	VIC	3358	2	131\\PS825905	20012516000	21307740000	-37.57346998	143.79015646	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008A4D33F648F961403CABDC7667C942C0
2188412	GAVIC719115528	VIC1998523	loca5de38b84720	P	S	\N	\N	UNIT 604	\N	5	7	IRVING	AVENUE	\N	UNIT 604, 5-7 IRVING AVENUE	BOX HILL	3128	VIC	3128	2	604\\PS738539	20631906470	21302510000	-37.81609649	145.12306020	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000ECEF11BF023624017778BD975E842C0
2408472	GAVIC420732404	VIC1942695	loc4e07cec4cde4	P	\N	\N	\N	\N	\N	116	\N	BOUNDARY	ROAD	\N	116 BOUNDARY ROAD	NARRE WARREN EAST	3804	VIC	3804	2	8\\LP81131	20650060000	20650060000	-37.97087587	145.35609185	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E943BC1A652B6240121017A945FC42C0
2607007	GAVIC425461232	VIC2069101	locc2ea2de6af6c	P	S	\N	\N	UNIT 104	\N	68	\N	ARGO	STREET	\N	UNIT 104, 68 ARGO STREET	SOUTH YARRA	3141	VIC	3141	2	104\\PS713407	20547120000	20547120000	-37.84423607	144.98884738	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BBBA42A3A41F6240756073ED0FEC42C0
2108838	GAVIC412674706	VIC1951161	loc09a99bf786b9	P	\N	\N	7	\N	\N	\N	\N	ARNOTT	ROAD	\N	LOT 7 ARNOTT ROAD	KILLAWARRA	3678	VIC	3678	0	\N	20571390000	20571390000	-36.28992379	146.26166412	STREET LOCALITY	4	0101000020A41E0000F9BD6E8D5F486240F23006391C2542C0
1198237	GAVIC425231579	VIC3568919	loc9ea2b366d63f	P	\N	\N	\N	\N	\N	24	\N	RANFURLIE	BOULEVARD	\N	24 RANFURLIE BOULEVARD	CRANBOURNE WEST	3977	VIC	3977	2	950\\PS711413	20631980740	20631980740	-38.11300223	145.24940385	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E367C81DFB276240CF1C69DB760E43C0
2457670	GAVIC412227164	VIC2068940	locfd8472c41cbe	P	P	\N	\N	\N	\N	10	\N	WYNDHAM	PLACE	\N	10 WYNDHAM PLACE	ROWVILLE	3178	VIC	3178	1	CM1\\PS517666	20340640000	20340640000	-37.93776924	145.24129037	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000ACFF94A6B8276240557F8CD208F842C0
3832219	GAVIC425028781	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT 1206	\N	470	\N	ST KILDA	ROAD	\N	UNIT 1206, 470 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	2	1206\\PS634058	20631963120	20631963120	-37.84125908	144.97693229	FRONTAGE CENTRE SETBACK	2	0101000020A41E00009B7E8107431F62401208A660AEEB42C0
2602484	GAVIC721704334	VIC1958350	locf51f6cd689bb	P	S	\N	\N	UNIT 201	\N	159	\N	EASTERN	ROAD	\N	UNIT 201, 159 EASTERN ROAD	SOUTH MELBOURNE	3205	VIC	3205	2	201\\PS918614	20529470000	20529470000	-37.83654004	144.96725679	FRONTAGE CENTRE SETBACK	2	0101000020A41E000049FC82C4F31E62401ACC78BE13EB42C0
857344	GAVIC425093622	VIC3572139	loca5643321b976	P	\N	\N	\N	\N	\N	1118	\N	WEDDERBURN JUNCTION EAST	ROAD	\N	1118 WEDDERBURN JUNCTION EAST ROAD	FIERY FLAT	3518	VIC	3518	2	101\\PP3415	20352124000	20352124000	-36.42267564	143.80901847	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E000052D0B37AE3F96140D54E413C1A3642C0
848730	GAVIC421109751	VIC2023988	loc74f8893fb76e	P	P	\N	\N	\N	\N	6	\N	OXLEY	COURT	\N	6 OXLEY COURT	BROADMEADOWS	3047	VIC	3047	0	581\\LP59116	20289790000	20289790000	-37.68425868	144.91933848	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BD3188386B1D6240544DD6C995D742C0
1451020	GAVIC421731563	VIC2009322	loc29a798d6921b	P	P	\N	\N	\N	\N	7	\N	MARKET	ROAD	\N	7 MARKET ROAD	WERRIBEE	3030	VIC	3030	2	7\\LP10129	20626580000	20626580000	-37.89781982	144.66250098	FRONTAGE CENTRE SETBACK	2	0101000020A41E00006055413533156240E14C86C2EBF242C0
1135244	GAVIC420757091	VIC1951133	loc79e45c9fa669	P	P	\N	\N	\N	\N	10	\N	ARNOLD	STREET	\N	10 ARNOLD STREET	BRUNSWICK EAST	3057	VIC	3057	1	1\\PS346158	20631985720	20631985720	-37.77439431	144.97527015	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007BE0BE69351F624049D44D5A1FE342C0
2372987	GAVIC421458512	VIC1948889	loce6098ac5df0c	P	\N	\N	\N	\N	\N	70	\N	BRIDGE	STREET	\N	70 BRIDGE STREET	BENDIGO	3550	VIC	3550	2	290~E\\PP3473A	20205930000	20205930000	-36.75068194	144.28538056	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A78369D621096240B9FF8658166042C0
1532121	GAVIC420773569	VIC1979753	loca307cf61ba97	P	\N	\N	\N	\N	\N	7	\N	HERALD	WALK	\N	7 HERALD WALK	KINGS PARK	3021	VIC	3021	2	833\\LP210155	20082000000	20082000000	-37.73560182	144.76389298	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CFD7B0CF7118624098E34F3328DE42C0
2602725	GAVIC423669472	VIC2030169	loc2c4c767ea9b7	P	S	THE PINNACLE	\N	UNIT 30	\N	102	106	ST GEORGES	ROAD	\N	UNIT 30, 102-106 ST GEORGES ROAD	PRESTON	3072	VIC	3072	0	1\\TP618847	20153770000	20153770000	-37.73804234	145.00025242	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A3F45C110220624081AEE02B78DE42C0
3871741	GAVIC421674160	VIC1944127	loc9901d119afda_1	P	\N	\N	\N	\N	\N	179	\N	BOURKE	STREET	\N	179 BOURKE STREET	MELBOURNE	3000	VIC	3000	0	1\\TP418919	20664450000	21315230000	-37.81305954	144.96795863	FRONTAGE CENTRE SETBACK	2	0101000020A41E000064776084F91E62401A00C35512E842C0
3311459	GAVIC420205676	VIC2030489	loca4e166a620d9	P	P	\N	\N	\N	\N	6	\N	THEODORE	AVENUE	\N	6 THEODORE AVENUE	NOBLE PARK	3174	VIC	3174	1	1\\PS908068	20227850000	20227850000	-37.97385510	145.16746051	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004ABA24D65B2562407BC5AE48A7FC42C0
2935109	GAVIC423398421	VIC1999859	loc6c0f29d040f7	P	\N	\N	3	\N	\N	\N	\N	HEADWORKS	ROAD	\N	LOT 3 HEADWORKS ROAD	TORRUMBARRY	3562	VIC	3562	0	\N	20099380000	20099380000	-35.97951931	144.48423475	STREET LOCALITY	4	0101000020A41E0000C7DADFD97E0F6240102085E360FD41C0
3710862	GAVIC719420229	VIC2030282	loc9901d119afda_2	P	S	\N	\N	UNIT P210	\N	348	\N	ST KILDA	ROAD	\N	UNIT P210, 348 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	0	P210\\PS409115	20533261000	20533261000	-37.83106671	144.97095196	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FD45D809121F6240461FDA6460EA42C0
3839838	GAVIC425285314	VIC2027065	loc9901d119afda_1	P	S	\N	\N	APARTMENT 1609	LEVEL 16	220	\N	SPENCER	STREET	\N	APARTMENT 1609, LEVEL 16, 220 SPENCER STREET	MELBOURNE	3000	VIC	3000	1	1609S\\PS633275	20664901000	20664901000	-37.81557058	144.95308018	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001B7201A27F1E62400257E49D64E842C0
3209015	GAVIC719988843	VIC1990396	loc31f384e524fe	P	S	\N	\N	UNIT 2002	LEVEL 20	63	\N	HAIG	STREET	\N	UNIT 2002, LEVEL 20, 63 HAIG STREET	SOUTHBANK	3006	VIC	3006	0	2002\\PS739783	20395362000	20395362000	-37.82766595	144.95670034	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E80B084A9D1E6240A2A135F5F0E942C0
3381041	GAVIC719537604	VIC1999814	loc8e5a2b16aaaa	P	S	DALKEITH HEIGHTS	\N	UNIT 84	\N	49	53	HAZELWOOD	ROAD	\N	UNIT 84, 49-53 HAZELWOOD ROAD	TRARALGON	3844	VIC	3844	2	1\\PS836326	20631987310	21339700000	-38.20900349	146.52229436	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BA62A9A2B6506240622659A0C01A43C0
3769884	GAVIC419811494	VIC1992446	loc46f8f01fbac9	P	P	\N	\N	\N	\N	26	\N	HUME	STREET	\N	26 HUME STREET	RINGWOOD EAST	3135	VIC	3135	1	CM1\\PS901115	20380550000	20380550000	-37.82476095	145.25936400	FRONTAGE CENTRE SETBACK	2	0101000020A41E00005038BBB54C2862404AA24DC491E942C0
2006173	GAVIC719539171	VIC2069720	loce16236caf708	P	S	INGENIA LIFESTYLE LARA	\N	UNIT 64	\N	40	\N	WATT	STREET	\N	UNIT 64, 40 WATT STREET	LARA	3212	VIC	3212	2	PC366289	20242860000	20242860000	-38.03023298	144.42534506	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000E3463E6D9C0D6240292E9EACDE0343C0
3836174	GAVIC423280693	VIC1999075	loc9901d119afda_1	P	\N	\N	\N	\N	\N	157	\N	LA TROBE	STREET	\N	157 LA TROBE STREET	MELBOURNE	3000	VIC	3000	0	\N	20394100000	20394100000	-37.80879726	144.96730862	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003F013531F41E6240AF652AAB86E742C0
3829811	GAVIC411825992	VIC2030282	loc9901d119afda_2	P	S	CITY CONDOS	\N	UNIT 53	\N	416	\N	ST KILDA	ROAD	\N	UNIT 53, 416 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	2	53\\PS416159	20529360000	20529360000	-37.83550076	144.97471609	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000EB2DCCDF301F6240D8FD5BB0F1EA42C0
3528683	GAVIC420787418	VIC1992219	loce42a110faa48	P	P	\N	\N	\N	\N	575	\N	HAMPTON	STREET	\N	575 HAMPTON STREET	HAMPTON	3188	VIC	3188	2	1\\TP339099	20051680000	20051680000	-37.93029719	145.00364361	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000433934D91D2062402B4E73FA13F742C0
3882793	GAVIC423632802	VIC1960434	loc9901d119afda_1	P	S	\N	\N	CARSPACE 806	\N	58	\N	FRANKLIN	STREET	\N	CARSPACE 806, 58 FRANKLIN STREET	MELBOURNE	3000	VIC	3000	0	806\\PS442086	20401423000	21313430000	-37.80776941	144.96096404	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000D38DA837C01E62406154EFFC64E742C0
902133	GAVIC420900117	VIC1939009	locd665688d0e4d	P	\N	\N	\N	\N	\N	20	\N	BALMORAL	STREET	\N	20 BALMORAL STREET	PORTLAND	3305	VIC	3305	2	1\\TP604100	20201760000	20201760000	-38.36005649	141.59728856	FRONTAGE CENTRE SETBACK	2	0101000020A41E000033EFE5FC1CB361409BA1C054162E43C0
66511	GAVIC420135739	VIC1933940	locfdc6079b562f	P	\N	\N	\N	\N	\N	23	\N	CHARLES	STREET	\N	23 CHARLES STREET	ASCOT VALE	3032	VIC	3032	2	1\\TP407700	20444130000	20444130000	-37.77861483	144.91010495	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B0856A941F1D6240EB8397A6A9E342C0
1738513	GAVIC420083984	VIC2031747	loc7213d03738b9	P	S	\N	\N	UNIT 6	\N	14	\N	STANFORD	CLOSE	\N	UNIT 6, 14 STANFORD CLOSE	FAWKNER	3060	VIC	3060	2	12\\PS341620	20474400000	20474400000	-37.69607084	144.96591795	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000D2BBC2CCE81E6240E7BF6AD918D942C0
1985590	GAVIC419620282	VIC1976825	loceac5d85ea01d	P	\N	\N	\N	\N	\N	24	\N	DOWNHAM	WAY	\N	24 DOWNHAM WAY	WYNDHAM VALE	3024	VIC	3024	2	1126\\LP114465	20634290000	20634290000	-37.89747281	144.61954999	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003029805AD3136240E6FF9763E0F242C0
1344593	GAVIC423444001	VIC1944650	loca0398a35cf5e	P	S	\N	\N	FLAT 54	\N	422	432	CARDIGAN	STREET	\N	FLAT 54, 422-432 CARDIGAN STREET	CARLTON	3053	VIC	3053	1	54\\RP2074	20399980000	20399980000	-37.79425274	144.96682147	FRONTAGE CENTRE SETBACK	2	0101000020A41E000010579433F01E62407987E312AAE542C0
151782	GAVIC423623835	VIC1943059	loc1e06c486c813	P	S	\N	\N	UNIT 5	LEVEL 1	1A	\N	CANNING	STREET	\N	UNIT 5, LEVEL 1, 1A CANNING STREET	NORTH MELBOURNE	3051	VIC	3051	0	10\\PS433630	20397050000	20397050000	-37.79682005	144.94629899	FRONTAGE CENTRE SETBACK	2	0101000020A41E000036C9D114481E624007C60B33FEE542C0
2589278	GAVIC425486221	VIC3137203	loc108a649ba4ae	P	\N	\N	1A	\N	\N	\N	\N	MCGINTY	ROAD	\N	LOT 1A MCGINTY ROAD	TARILTA	3451	VIC	3451	0	\N	20708590000	20708590000	-37.16916858	144.18625307	STREET LOCALITY	4	0101000020A41E0000BF8DFFC8F50562402D4EE750A79542C0
2709962	GAVIC424478303	VIC2036742	locc2ea2de6af6c	P	S	COMO CENTRE	\N	SUITE 11A	LEVEL 3	299	\N	TOORAK	ROAD	\N	SUITE 11A, LEVEL 3, 299 TOORAK ROAD	SOUTH YARRA	3141	VIC	3141	1	S3\\PS920557	20544740000	20544740000	-37.83903096	144.99710497	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000889AAE48E81F624008C4D25D65EB42C0
2035816	GAVIC421995183	VIC1941988	loc17a18f5ff3a6	P	\N	\N	\N	\N	\N	8	\N	BARKLY	CLOSE	\N	8 BARKLY CLOSE	CAROLINE SPRINGS	3023	VIC	3023	2	89\\PS415872	20404640000	20404640000	-37.72359677	144.74124003	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C1EA023DB81762401452A7D19EDC42C0
3745901	GAVIC423648049	VIC2051723	loc9901d119afda_1	P	S	\N	\N	APARTMENT 2201	LEVEL 22	222	\N	RUSSELL	STREET	\N	APARTMENT 2201, LEVEL 22, 222 RUSSELL STREET	MELBOURNE	3000	VIC	3000	0	2201A\\PS337555	20393110000	20393110000	-37.81131701	144.96770029	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000273C9966F71E6240BB515C3CD9E742C0
928655	GAVIC719309027	VIC3615353	loc90b2f4dd8c2d	P	\N	\N	\N	\N	\N	111	117	UNITY	DRIVE	\N	111-117 UNITY DRIVE	MOUNT DUNEED	3217	VIC	3217	0	RES20\\PS709524	20631901740	21313040000	-38.22548958	144.32718535	FRONTAGE CENTRE SETBACK	2	0101000020A41E00005F3F694D780A62402AD8B1D7DC1C43C0
2419329	GAVIC420257417	VIC1966266	loc0b665c0fe535	P	\N	\N	\N	\N	\N	50	\N	ENDEAVOUR	DRIVE	\N	50 ENDEAVOUR DRIVE	OCEAN GROVE	3226	VIC	3226	2	332\\LP116133	20258590000	20258590000	-38.26152596	144.55466591	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FFF4B8D2BF116240A4A0C2AE792143C0
3839576	GAVIC425008870	VIC1944127	loc9901d119afda_1	P	S	\N	\N	CARSPACE 38	\N	140	\N	BOURKE	STREET	\N	CARSPACE 38, 140 BOURKE STREET	MELBOURNE	3000	VIC	3000	0	38\\PS428191	20393902000	20393902000	-37.81231826	144.96896432	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000822C76C1011F62406252740BFAE742C0
2756096	GAVIC424667096	VIC3382134	locc5abea08e85d	P	\N	\N	\N	\N	\N	22	\N	APPLEBOX	CIRCUIT	\N	22 APPLEBOX CIRCUIT	POINT COOK	3030	VIC	3030	2	817\\PS620424	20631957560	20631957560	-37.90809188	144.73032763	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E3C60CD85E1762407C2ECF5A3CF442C0
3434066	GAVIC719622334	VIC2003856	loccbfe7d3f7b9f	P	S	\N	\N	FLAT 5	\N	7	\N	NEPEAN	HIGHWAY	\N	FLAT 5, 7 NEPEAN HIGHWAY	ELSTERNWICK	3185	VIC	3185	2	G05\\PS742542	20189370000	20189370000	-37.88463722	144.99828331	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F712D7EFF11F6240B85CDCCA3BF142C0
3929256	GAVIC423935363	VIC1948877	locff58d0167065	P	P	COURT HOUSE	\N	\N	\N	19	\N	BRIDGE	STREET	WEST	19 BRIDGE STREET WEST	BENALLA	3672	VIC	3672	1	2017\\PP5066	20053780000	20053780000	-36.55570371	145.97512786	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CA83573F343F6240A25B964C214742C0
1771529	GAVIC423404123	VIC2021931	loc991c414cb6c9	P	\N	\N	5	\N	\N	\N	\N	MUGAVINS	ROAD	\N	LOT 5 MUGAVINS ROAD	UPPER PLENTY	3756	VIC	3756	0	\N	20419510000	20419510000	-37.43279669	145.07901230	STREET LOCALITY	4	0101000020A41E00006A8FCD4487226240FCAEC6E165B742C0
3569965	GAVIC721289923	VIC1988452	loce42a110faa48	P	S	\N	\N	UNIT 104	LEVEL 1	24	\N	LINACRE	ROAD	\N	UNIT 104, LEVEL 1, 24 LINACRE ROAD	HAMPTON	3188	VIC	3188	0	7\\PS810583	20631913430	20631913430	-37.94247202	145.00426485	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B7E809F022206240C4A553ECA2F842C0
149105	GAVIC421774336	VIC2049549	locd8470b65d64b	P	S	\N	\N	UNIT 2	\N	96	\N	TUCKER	ROAD	\N	UNIT 2, 96 TUCKER ROAD	BENTLEIGH	3204	VIC	3204	2	2\\PS340334	20195181000	20195181000	-37.92571484	145.05035091	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C3F882799C216240669CE9D27DF642C0
2510611	GAVIC411935231	VIC2044583	loc20a81a4bf246	P	\N	\N	1	\N	\N	\N	\N	SYCAMORE	GROVE	\N	LOT 1 SYCAMORE GROVE	MOUNT EVELYN	3796	VIC	3796	0	\N	20658320000	20658320000	-37.80089948	145.37545033	STREET LOCALITY	4	0101000020A41E0000EB1369B0032C6240E0FDC8DF83E642C0
2767025	GAVIC719207295	VIC1943978	loc9a48431374e1	P	\N	\N	\N	\N	\N	69	\N	BOUNDARY	STREET	\N	69 BOUNDARY STREET	PORT MELBOURNE	3207	VIC	3207	2	19\\PS718981	20533221000	20533221000	-37.82967437	144.94431849	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000DCF168DB371E62405DBD0EC532EA42C0
3499359	GAVIC423643559	VIC2020817	locb71d10cf3b7c	P	\N	\N	\N	\N	\N	122	\N	ONTARIO	AVENUE	\N	122 ONTARIO AVENUE	MILDURA	3500	VIC	3500	0	\N	20412290000	20412290000	-34.20003429	142.12461716	STREET LOCALITY	4	0101000020A41E00000E5720DDFCC3614075D03EB99A1941C0
3780347	GAVIC423911067	VIC2030282	loc9901d119afda_2	P	P	\N	\N	\N	\N	368	\N	ST KILDA	ROAD	\N	368 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	0	\N	20533110000	20533110000	-37.83180171	144.97111975	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000FED7B969131F62407B9A7A7A78EA42C0
2012023	GAVIC420148109	VIC1932710	loca674ab421c49	P	\N	\N	\N	\N	\N	6	\N	ATKINS	STREET	\N	6 ATKINS STREET	EUROA	3666	VIC	3666	2	1\\TP21771	20631970470	20631970470	-36.75530318	145.57699318	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000AEC366BA7632624018554CC6AD6042C0
202239	GAVIC423620402	VIC1935569	loc1e06c486c813	P	S	\N	\N	CARSPACE 22	\N	369	\N	ABBOTSFORD	STREET	\N	CARSPACE 22, 369 ABBOTSFORD STREET	NORTH MELBOURNE	3051	VIC	3051	0	22\\RP1880	20398590000	20398590000	-37.79807410	144.94606971	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F505FC33461E62406FA4C74A27E642C0
2024913	GAVIC421838556	VIC1945132	loc0067a4549ed1	P	S	\N	\N	UNIT 2	\N	20	\N	BATES	AVENUE	\N	UNIT 2, 20 BATES AVENUE	KORUMBURRA	3950	VIC	3950	2	2\\PS634718	20539420000	20539420000	-38.44012569	145.83101011	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000DA383A2973A6240F856E209563843C0
1633896	GAVIC423110860	VIC2054961	loc1a22f173d7f3	P	S	BOTANIC GARDENS RET VLGE	\N	UNIT 133	\N	41	\N	CRAIG	ROAD	\N	UNIT 133, 41 CRAIG ROAD	JUNCTION VILLAGE	3977	VIC	3977	2	133\\PS306331	20631970870	20631970870	-38.13844700	145.29331660	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E0000F78B7ED9622962405A9D9CA1B81143C0
1122465	GAVIC425480664	VIC3573679	locb9872f35df41	P	S	\N	\N	UNIT 308	\N	6	\N	ACACIA	PLACE	\N	UNIT 308, 6 ACACIA PLACE	ABBOTSFORD	3067	VIC	3067	2	320B\\PS641350	20631982020	20631982020	-37.81175875	145.01414918	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B02BFBE873206240F5BEF1B5E7E742C0
3208308	GAVIC420058003	VIC1953594	locbcb60f6b546d	P	S	\N	\N	UNIT 5	\N	55	\N	CRANBOURNE-FRANKSTON	ROAD	\N	UNIT 5, 55 CRANBOURNE-FRANKSTON ROAD	LANGWARRIN	3910	VIC	3910	2	5\\PS310696	20166050000	20166050000	-38.15497185	145.17748186	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000AA0A70EEAD2562407BC6191ED61343C0
3713967	GAVIC719424466	VIC2025971	loc9901d119afda_2	P	S	\N	\N	UNIT A1	\N	1	\N	QUEENS	ROAD	\N	UNIT A1, 1 QUEENS ROAD	MELBOURNE	3004	VIC	3004	0	A1\\PS500424	20533270000	20533270000	-37.83579341	144.97370122	FRONTAGE CENTRE SETBACK	2	0101000020A41E000036FF758F281F6240C7144947FBEA42C0
2939029	GAVIC719111600	VIC2050036	loc86b22e8e6ecf	P	\N	\N	\N	\N	\N	80	\N	ROWENA	STREET	\N	80 ROWENA STREET	EAST BENDIGO	3550	VIC	3550	1	1\\PS807966	20213402000	20213402000	-36.74158052	144.30785872	FRONTAGE CENTRE SETBACK	2	0101000020A41E000008C687FAD90962401660481CEC5E42C0
3844260	GAVIC421481958	VIC1978845	loc08caad3924ee	P	P	\N	\N	\N	\N	9	\N	JOHN	STREET	\N	9 JOHN STREET	ALTONA NORTH	3025	VIC	3025	1	CM\\RP7760	20278570000	20278570000	-37.83086983	144.83558596	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004C66C41EBD1A6240A28A4DF159EA42C0
\.

-- gnaf_202602.address_aliases: 75 rows
\copy gnaf_202602.address_aliases FROM stdin
134737	GAVIC721504027	VIC2005249	loc3319215a0a10	A	S	\N	\N	UNIT 213	\N	538	\N	NEW	STREET	\N	UNIT 213, 538 NEW STREET	BRIGHTON	3186	VIC	3186	1	PC382446	20046650000	20046650000	-37.88790169	144.99668006	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CFC894CDE41F62407B4E38C3A6F142C0
73405	GAVIC425027132	VIC2040420	locc2ea2de6af6c	A	S	\N	\N	UNIT 908	\N	77	\N	RIVER	STREET	\N	UNIT 908, 77 RIVER STREET	SOUTH YARRA	3141	VIC	3141	1	908\\PS617851	20631953570	20631953570	-37.83684594	144.99740670	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F6A974C1EA1F6240920B8CC41DEB42C0
22255	GAVIC421987657	VIC1939111	loccaca39f133a7	A	S	\N	\N	UNIT 3	\N	21	23	BAMFIELD	ROAD	\N	UNIT 3, 21-23 BAMFIELD ROAD	HEIDELBERG HEIGHTS	3081	VIC	3081	0	3\\RP15518	20022580000	20022580000	-37.74198384	145.05494793	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A74A2922C2216240F27A9353F9DE42C0
74867	GAVIC719749191	VIC1990433	loc1e06c486c813	A	S	\N	\N	UNIT 108	\N	108	\N	HAINES	STREET	\N	UNIT 108, 108 HAINES STREET	NORTH MELBOURNE	3051	VIC	3051	1	108\\PS742791	20401230000	21319870000	-37.79846579	144.94365758	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001F976171321E62402D83832034E642C0
12100	GAVIC721459739	VIC2044273	locddc4a1bcd8ba	A	S	\N	\N	UNIT 1707	\N	7	\N	SIDDELEY	STREET	\N	UNIT 1707, 7 SIDDELEY STREET	DOCKLANDS	3008	VIC	3008	1	S6\\PS644635	20394823000	20394823000	-37.82154241	144.95444368	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002AEF78CD8A1E62400F9D3B4D28E942C0
19592	GAVIC719767317	VIC2007449	locddc4a1bcd8ba	A	S	\N	\N	UNIT 3010	\N	8	\N	PEARL RIVER	ROAD	\N	UNIT 3010, 8 PEARL RIVER ROAD	DOCKLANDS	3008	VIC	3008	1	3010\\PS728852	20631953180	21313600000	-37.81532063	144.93801394	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BF6FCF35041E624054CD286D5CE842C0
48941	GAVIC422080427	VIC1940808	loca1b6ce72e35a	A	\N	\N	\N	\N	\N	10	\N	BOND	STREET	\N	10 BOND STREET	MOUNT WAVERLEY	3149	VIC	3149	0	1\\SP27650	20440860000	20440860000	-37.88006953	145.13832838	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000AD86A32F6D2462402EC74C1EA6F042C0
82736	GAVIC425042539	VIC1961385	loc2d817b7080e2	A	S	\N	\N	UNIT 312	\N	839	\N	DANDENONG	ROAD	\N	UNIT 312, 839 DANDENONG ROAD	MALVERN EAST	3145	VIC	3145	1	312\\PS629876	20554564000	20554564000	-37.87483964	145.04077496	FRONTAGE CENTRE SETBACK	2	0101000020A41E000043F649074E216240AF85CDBEFAEF42C0
197344	GAVIC423728755	VIC1984350	loc8e5a2b16aaaa	A	\N	\N	\N	\N	\N	40	\N	GREENFIELD	DRIVE	\N	40 GREENFIELD DRIVE	TRARALGON	3844	VIC	3844	0	40\\PS504138	20350290000	20350290000	-38.18180381	146.54473742	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000D6792B7D6E5162407D1EE558451743C0
73462	GAVIC421611304	VIC2020912	loc1b289d3ff2fc	A	\N	\N	\N	\N	\N	28	\N	ORCHARD	CIRCUIT	\N	28 ORCHARD CIRCUIT	SHEPPARTON	3630	VIC	3630	0	47\\LP203266	20266260000	20266260000	-36.35998165	145.40725152	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000AEF45634082D62407FF4F2E0132E42C0
201345	GAVIC422412680	VIC2075671	loc4ff8c926c940	A	\N	\N	\N	\N	\N	47	\N	MONTPELLIER	ROAD	\N	47 MONTPELLIER ROAD	ASHWOOD	3147	VIC	3147	0	1\\TP257898	20436380000	20436380000	-37.85929785	145.10725291	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003A9BA79D6E236240F5A2D178FDED42C0
193771	GAVIC719937293	VIC1990396	loc31f384e524fe	A	S	\N	\N	UNIT 2002	\N	63	\N	HAIG	STREET	\N	UNIT 2002, 63 HAIG STREET	SOUTHBANK	3006	VIC	3006	1	2002\\PS739783	20395362000	20395362000	-37.82766595	144.95670034	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E80B084A9D1E6240A2A135F5F0E942C0
24281	GAVIC422113816	VIC2080356	loc3754c5fc3408	A	\N	\N	\N	\N	\N	26	\N	SOMMEVILLE	DRIVE	\N	26 SOMMEVILLE DRIVE	ROXBURGH PARK	3064	VIC	3064	0	1846\\PS344030	20300460000	20300460000	-37.63298383	144.93415096	FRONTAGE CENTRE SETBACK	2	0101000020A41E000044D78D90E41D6240985F389D05D142C0
32871	GAVIC422419032	VIC2007417	locb344fc28a060	A	\N	\N	\N	\N	\N	151	155	PEARCEDALE	ROAD	\N	151-155 PEARCEDALE ROAD	PEARCEDALE	3912	VIC	3912	0	4\\PS749865	20128480000	20128480000	-38.19602626	145.23626340	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BD0743788F276240B8ED7363171943C0
143826	GAVIC410965788	VIC1956038	loc74f8893fb76e	A	S	\N	\N	UNIT 3	\N	64	\N	GRAHAM	STREET	\N	UNIT 3, 64 GRAHAM STREET	BROADMEADOWS	3047	VIC	3047	0	PC350785	20631935260	20631935260	-37.69164883	144.92750496	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007DC2E11EAE1D62405595E8F287D842C0
169998	GAVIC719459374	VIC1963013	loc9901d119afda_1	A	S	\N	\N	UNIT 6104	\N	442	\N	ELIZABETH	STREET	\N	UNIT 6104, 442 ELIZABETH STREET	MELBOURNE	3000	VIC	3000	1	6105\\PS728842	20401811000	21328440000	-37.80833027	144.96073354	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000DCF4354BE1E62402802C55D77E742C0
43065	GAVIC425325821	VIC1992791	loc406d1f7b5fe3	A	S	\N	\N	UNIT 36	\N	31	33	KING	STREET	\N	UNIT 36, 31-33 KING STREET	TEMPLESTOWE	3106	VIC	3106	0	36\\PS711492	20362460000	20362460000	-37.77324143	145.14957729	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000C7185056C924624092E13E93F9E242C0
75612	GAVIC719770314	VIC1962365	loc31f384e524fe	A	S	\N	\N	UNIT 3810	\N	105	\N	CLARENDON	STREET	\N	UNIT 3810, 105 CLARENDON STREET	SOUTHBANK	3006	VIC	3006	1	3810\\PS734580	20395113000	20395113000	-37.82714046	144.95816137	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000198E0842A91E6240FF7214BDDFE942C0
106646	GAVIC420755745	VIC1978051	locf57f2052e543	A	\N	\N	\N	\N	\N	24	\N	MAHOGANY	AVENUE	\N	24 MAHOGANY AVENUE	FRANKSTON NORTH	3200	VIC	3200	1	13\\LP58497	20169440000	20169440000	-38.12221616	145.14787116	PROPERTY ACCESS POINT SETBACK	2	0101000020A41E000017874C5CBB246240111F75C7A40F43C0
6926	GAVIC413382151	VIC2040515	loc4fa4b090ce9e	A	S	\N	\N	UNIT 15	\N	247	\N	RIVERSDALE	ROAD	\N	UNIT 15, 247 RIVERSDALE ROAD	HAWTHORN EAST	3123	VIC	3123	0	15\\RP6990	20069550000	20069550000	-37.82989084	145.04535392	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A764108A732162406586F0DC39EA42C0
101274	GAVIC423769586	VIC1993696	locddc4a1bcd8ba	A	S	VICTORIA POINT	\N	UNIT 3001	\N	100	\N	HARBOUR	ESPLANADE	\N	UNIT 3001, 100 HARBOUR ESPLANADE	DOCKLANDS	3008	VIC	3008	1	3001\\PS509916	20631926900	20631926900	-37.81829164	144.94697159	FRONTAGE CENTRE SETBACK	2	0101000020A41E000051295D974D1E6240F231CCC7BDE842C0
181798	GAVIC425032577	VIC1937464	locdd716f1059c5	A	S	\N	\N	UNIT 59	\N	80	\N	BALCOMBE	ROAD	\N	UNIT 59, 80 BALCOMBE ROAD	MENTONE	3194	VIC	3194	0	59\\PS612989	20631971350	20631971350	-37.98102750	145.06543874	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002006FC1218226240037D224F92FD42C0
111645	GAVIC421523064	VIC1974317	loc5c27e3f22fc1	A	\N	\N	\N	\N	\N	563	565	GLENFERRIE	ROAD	\N	563-565 GLENFERRIE ROAD	HAWTHORN	3122	VIC	3122	0	CM1\\PS610457	20070880000	20070880000	-37.82695143	145.03433532	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000ED8F6246192162407F9D618BD9E942C0
190227	GAVIC720234958	VIC1981515	loc2c4c767ea9b7	A	S	\N	\N	UNIT 602	\N	191	\N	HIGH	STREET	\N	UNIT 602, 191 HIGH STREET	PRESTON	3072	VIC	3072	1	611\\PS805184	20153581000	20153581000	-37.74644453	145.00241335	FRONTAGE CENTRE SETBACK	2	0101000020A41E00005D6A29C51320624065508E7E8BDF42C0
65354	GAVIC719044287	VIC1956233	loc4858bcc1d912	A	S	\N	\N	UNIT 6	\N	30	\N	GRANDVIEW	STREET	\N	UNIT 6, 30 GRANDVIEW STREET	GLENROY	3046	VIC	3046	0	6\\PS739781	20473110000	20473110000	-37.70846694	144.91169648	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004EAF189E2C1D624071CC700BAFDA42C0
159283	GAVIC719459794	VIC2030282	loc9901d119afda_2	A	S	\N	\N	UNIT 103	\N	499	\N	ST KILDA	ROAD	\N	UNIT 103, 499 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	1	103\\PS737521	20631995350	21328350000	-37.84341251	144.97862647	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CC7475E8501F62405FBEEDF0F4EB42C0
49801	GAVIC425246317	VIC2059743	loc31f384e524fe	A	S	\N	\N	UNIT 4005	\N	241	243	CITY	ROAD	\N	UNIT 4005, 241-243 CITY ROAD	SOUTHBANK	3006	VIC	3006	0	4005\\PS638212	20631945480	21311300000	-37.82639623	144.95991751	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000D909EDA4B71E6240A0B1065AC7E942C0
5689	GAVIC411282405	VIC2009968	loc7a8164839d54	A	S	\N	\N	UNIT 2	\N	10	\N	NORMAN	STREET	\N	UNIT 2, 10 NORMAN STREET	DONCASTER EAST	3109	VIC	3109	1	1\\PS338154	20361550000	20361550000	-37.78618585	145.14758191	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CD9DB2FDB8246240FB29E9BCA1E442C0
188168	GAVIC413977671	VIC1970315	loc3b64e6146ff8	A	S	\N	\N	UNIT 3	\N	458	460	COMO	PARADE	WEST	UNIT 3, 458-460 COMO PARADE WEST	MORDIALLOC	3195	VIC	3195	0	3\\RP8465	20316740000	20316740000	-38.00120185	145.08300690	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F41A16FEA7226240EC38D961270043C0
149747	GAVIC411050404	VIC1944650	loca0398a35cf5e	A	S	\N	\N	UNIT 54	\N	422	\N	CARDIGAN	STREET	\N	UNIT 54, 422 CARDIGAN STREET	CARLTON	3053	VIC	3053	0	54\\RP2074	20399980000	20399980000	-37.79425274	144.96682147	FRONTAGE CENTRE SETBACK	2	0101000020A41E000010579433F01E62407987E312AAE542C0
1594	GAVIC424091347	VIC1953363	loc9fb289b0a33e	A	\N	\N	\N	\N	\N	1064	\N	COWRA	AVENUE	\N	1064 COWRA AVENUE	IRYMPLE	3498	VIC	3498	0	2\\LP210288	20631960980	20631960980	-34.23335670	142.14417227	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007C142A0F9DC46140B866E1A1DE1D41C0
137066	GAVIC424474882	VIC2080683	loc9901d119afda_1	A	S	\N	\N	\N	LEVEL 2	53	\N	QUEEN	STREET	\N	LEVEL 2, 53 QUEEN STREET	MELBOURNE	3000	VIC	3000	0	1\\TP758232	20664260000	21328660000	-37.81752885	144.96159702	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000981A1D67C51E6240AC240DC9A4E842C0
109551	GAVIC412010761	VIC1943059	loc1e06c486c813	A	S	\N	\N	UNIT 5	\N	1A	\N	CANNING	STREET	\N	UNIT 5, 1A CANNING STREET	NORTH MELBOURNE	3051	VIC	3051	1	10\\PS433630	20397050000	20397050000	-37.79682005	144.94629899	FRONTAGE CENTRE SETBACK	2	0101000020A41E000036C9D114481E624007C60B33FEE542C0
85633	GAVIC425580055	VIC2006220	loca0398a35cf5e	A	S	\N	\N	UNIT 405	\N	525	\N	RATHDOWNE	STREET	\N	UNIT 405, 525 RATHDOWNE STREET	CARLTON	3053	VIC	3053	1	405N3S\\PS627030	20631924810	21329140000	-37.79308649	144.97100474	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F4518878121F624087B9ACDB83E542C0
58331	GAVIC425762632	VIC2062049	loc9e7da77def26	A	S	\N	\N	UNIT 406	\N	67	\N	GALADA	AVENUE	\N	UNIT 406, 67 GALADA AVENUE	PARKVILLE	3052	VIC	3052	1	12406\\PS709099	20631904290	21309260000	-37.77969041	144.93938448	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000A7F0A700F1E624038FA35E5CCE342C0
21187	GAVIC413192636	VIC1980990	locb17fb225139f	A	S	\N	\N	UNIT 9	\N	61	63	MALTRAVERS	ROAD	\N	UNIT 9, 61-63 MALTRAVERS ROAD	IVANHOE EAST	3079	VIC	3079	0	9\\SP20936	20015890000	20015890000	-37.76930735	145.05733918	FRONTAGE CENTRE SETBACK	2	0101000020A41E000025DCF9B8D52162404569CAA978E242C0
169371	GAVIC719457195	VIC1963013	loc9901d119afda_1	A	S	\N	\N	UNIT 3504	\N	442	\N	ELIZABETH	STREET	\N	UNIT 3504, 442 ELIZABETH STREET	MELBOURNE	3000	VIC	3000	1	3505\\PS728842	20401811000	21328440000	-37.80833027	144.96073354	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000DCF4354BE1E62402802C55D77E742C0
91116	GAVIC425294479	VIC1953262	loc31f384e524fe	A	S	\N	\N	UNIT 1905	\N	39	\N	COVENTRY	STREET	\N	UNIT 1905, 39 COVENTRY STREET	SOUTHBANK	3006	VIC	3006	1	1905\\PS638768	20631981110	20631981110	-37.82945629	144.96918736	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B1DC3595031F62407981AB9F2BEA42C0
65225	GAVIC719939375	VIC2061385	loca0398a35cf5e	A	S	\N	\N	UNIT 1718	\N	160	\N	VICTORIA	STREET	\N	UNIT 1718, 160 VICTORIA STREET	CARLTON	3053	VIC	3053	1	1718\\PS742732	20401931000	21330620000	-37.80632196	144.96191382	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000ECF7DFFC71E6240911FD88E35E742C0
115451	GAVIC721387488	VIC1988452	loce42a110faa48	A	S	\N	\N	UNIT 104	\N	24	\N	LINACRE	ROAD	\N	UNIT 104, 24 LINACRE ROAD	HAMPTON	3188	VIC	3188	1	7\\PS810583	20631913430	20631913430	-37.94247202	145.00426485	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B7E809F022206240C4A553ECA2F842C0
87829	GAVIC425420428	VIC1985134	loc31f384e524fe	A	S	\N	\N	UNIT 2504	\N	118	\N	KAVANAGH	STREET	\N	UNIT 2504, 118 KAVANAGH STREET	SOUTHBANK	3006	VIC	3006	1	2504\\PS647246	20631979060	20631979060	-37.82567255	144.96208951	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CAA8F06FC91E62403BBA5BA3AFE942C0
142182	GAVIC720001539	VIC1953368	loc3319215a0a10	A	S	\N	\N	UNIT 204	\N	7	\N	COWRA	STREET	\N	UNIT 204, 7 COWRA STREET	BRIGHTON	3186	VIC	3186	1	204\\PS807792	20046460000	20046460000	-37.90494907	145.00724733	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000ABAAC05E3B2062400A19025FD5F342C0
20128	GAVIC720471214	VIC1955730	locddc4a1bcd8ba	A	S	\N	\N	UNIT 1601	\N	628	\N	FLINDERS	STREET	\N	UNIT 1601, 628 FLINDERS STREET	DOCKLANDS	3008	VIC	3008	1	11601\\PS704437	20395174000	20395174000	-37.82127148	144.95351739	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000F4C6E636831E624067DE816C1FE942C0
70544	GAVIC719006374	VIC2080714	loc1e06c486c813	A	S	\N	\N	UNIT 307	\N	388	\N	QUEENSBERRY	STREET	\N	UNIT 307, 388 QUEENSBERRY STREET	NORTH MELBOURNE	3051	VIC	3051	1	307CA\\PS721454	20399801000	20399801000	-37.80319690	144.95513882	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004861497F901E6240D2DFF027CFE642C0
2778	GAVIC719765629	VIC2007449	locddc4a1bcd8ba	A	S	\N	\N	UNIT 413	\N	8	\N	PEARL RIVER	ROAD	\N	UNIT 413, 8 PEARL RIVER ROAD	DOCKLANDS	3008	VIC	3008	1	413\\PS728852	20631953180	21313600000	-37.81532063	144.93801394	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BF6FCF35041E624054CD286D5CE842C0
165065	GAVIC425232920	VIC2027065	loc9901d119afda_1	A	S	\N	\N	UNIT 1609	\N	220	\N	SPENCER	STREET	\N	UNIT 1609, 220 SPENCER STREET	MELBOURNE	3000	VIC	3000	0	1609S\\PS633275	20664901000	20664901000	-37.81557058	144.95308018	FRONTAGE CENTRE SETBACK	2	0101000020A41E00001B7201A27F1E62400257E49D64E842C0
111733	GAVIC720075106	VIC1985134	loc31f384e524fe	A	S	\N	\N	UNIT 3314	\N	60	\N	KAVANAGH	STREET	\N	UNIT 3314, 60 KAVANAGH STREET	SOUTHBANK	3006	VIC	3006	1	3314\\PS745414	20631983400	21302270000	-37.82421909	144.96356449	FRONTAGE CENTRE SETBACK	2	0101000020A41E000062843285D51E6240FA24DA0280E942C0
136582	GAVIC721460023	VIC1992749	loc9901d119afda_1	A	S	\N	\N	UNIT 4205	\N	299	\N	KING	STREET	\N	UNIT 4205, 299 KING STREET	MELBOURNE	3000	VIC	3000	1	4205\\PS827459	20664910000	20664910000	-37.81323986	144.95401004	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000613B1040871E62407740653E18E842C0
30021	GAVIC411975916	VIC2019697	loc6280f9052ec0	A	\N	\N	\N	\N	\N	360	\N	POUND	ROAD	\N	360 POUND ROAD	NARRE WARREN SOUTH	3805	VIC	3805	0	8\\LP41754	20111180000	20111180000	-38.03968301	145.28998847	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000BF5BE6954729624013143755140543C0
114383	GAVIC718990761	VIC1955611	loc1e06c486c813	A	S	\N	\N	UNIT 208	\N	83	\N	FLEMINGTON	ROAD	\N	UNIT 208, 83 FLEMINGTON ROAD	NORTH MELBOURNE	3051	VIC	3051	1	208\\PS704450	20395952000	21301480000	-37.79869617	144.95324680	FRONTAGE CENTRE SETBACK	2	0101000020A41E000088E06EFF801E624094CB14AD3BE642C0
197343	GAVIC423728754	VIC1984350	loc8e5a2b16aaaa	A	\N	\N	\N	\N	\N	38	\N	GREENFIELD	DRIVE	\N	38 GREENFIELD DRIVE	TRARALGON	3844	VIC	3844	0	40\\PS504138	20350290000	20350290000	-38.18180381	146.54473742	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000D6792B7D6E5162407D1EE558451743C0
156256	GAVIC423804130	VIC1955713	loc9901d119afda_1	A	S	\N	\N	UNIT 218	\N	268	\N	FLINDERS	STREET	\N	UNIT 218, 268 FLINDERS STREET	MELBOURNE	3000	VIC	3000	1	218B\\PS508080	20631944140	21334360000	-37.81775091	144.96565347	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000681D1BA2E61E6240B45CD30FACE842C0
158587	GAVIC719457877	VIC2030282	loc9901d119afda_2	A	S	\N	\N	UNIT 1201	\N	499	\N	ST KILDA	ROAD	\N	UNIT 1201, 499 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	1	1201\\PS737521	20631995350	21328350000	-37.84341251	144.97862647	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000CC7475E8501F62405FBEEDF0F4EB42C0
146601	GAVIC421544966	VIC2051723	loc9901d119afda_1	A	S	\N	\N	UNIT 2201	\N	222	\N	RUSSELL	STREET	\N	UNIT 2201, 222 RUSSELL STREET	MELBOURNE	3000	VIC	3000	1	2201\\PS337555	20393110000	20393110000	-37.81131701	144.96770029	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000273C9966F71E6240BB515C3CD9E742C0
59319	GAVIC719053315	VIC2059530	loc1e06c486c813	A	S	\N	\N	UNIT 524	\N	33	\N	BLACKWOOD	STREET	\N	UNIT 524, 33 BLACKWOOD STREET	NORTH MELBOURNE	3051	VIC	3051	1	524\\PS719578	20401531000	20401531000	-37.80043670	144.95542694	FRONTAGE CENTRE SETBACK	2	0101000020A41E00008EA084DB921E62405382B4B574E642C0
165421	GAVIC719816339	VIC1963013	loc9901d119afda_1	A	S	\N	\N	UNIT 5405	\N	462	\N	ELIZABETH	STREET	\N	UNIT 5405, 462 ELIZABETH STREET	MELBOURNE	3000	VIC	3000	1	5405\\PS728807	20401423000	21313460000	-37.80786078	144.96051896	FRONTAGE CENTRE SETBACK	2	0101000020A41E00006A0C4292BC1E624018E966FB67E742C0
151697	GAVIC425372485	VIC2030282	loc9901d119afda_2	A	S	\N	\N	UNIT 901	LEVEL 9	568	\N	ST KILDA	ROAD	\N	UNIT 901, LEVEL 9, 568 ST KILDA ROAD	MELBOURNE	3004	VIC	3004	0	901\\PS621195	20631943540	20631943540	-37.84701078	144.97902922	FRONTAGE CENTRE SETBACK	2	0101000020A41E00004F371635541F6240CFBA67D96AEC42C0
135059	GAVIC412739901	VIC2025971	loc9901d119afda_2	A	S	\N	\N	UNIT 17	\N	33	\N	QUEENS	ROAD	\N	UNIT 17, 33 QUEENS ROAD	MELBOURNE	3004	VIC	3004	1	17\\RP14334	20531000000	20531000000	-37.84404234	144.97620603	FRONTAGE CENTRE SETBACK	2	0101000020A41E000041A06D143D1F6240A25E539409EC42C0
43377	GAVIC423555143	VIC1998102	loc79e45c9fa669	A	S	\N	\N	UNIT 202	\N	408	\N	LYGON	STREET	\N	UNIT 202, 408 LYGON STREET	BRUNSWICK EAST	3057	VIC	3057	1	202\\PS512620	20461472000	20461472000	-37.76496434	144.97307567	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000DD65966F231F6240FF73FB59EAE142C0
150225	GAVIC719227954	VIC2025971	loc9901d119afda_2	A	S	\N	\N	UNIT 91	\N	29	\N	QUEENS	ROAD	\N	UNIT 91, 29 QUEENS ROAD	MELBOURNE	3004	VIC	3004	0	29\\SP25910	20530930000	20530930000	-37.84253725	144.97568145	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000BE24DC8381F6240B534B742D8EB42C0
76477	GAVIC422443247	VIC1963615	loc12c0177d3d38	A	S	\N	\N	UNIT 2	\N	455	\N	GAFFNEY	STREET	\N	UNIT 2, 455 GAFFNEY STREET	PASCOE VALE	3044	VIC	3044	0	2\\PS502102	20467730000	20467730000	-37.73040617	144.92642616	FRONTAGE CENTRE SETBACK	2	0101000020A41E00007C6B7948A51D62402B790AF37DDD42C0
110702	GAVIC425013938	VIC1961385	loc2d817b7080e2	A	S	\N	\N	UNIT 302	\N	839	\N	DANDENONG	ROAD	\N	UNIT 302, 839 DANDENONG ROAD	MALVERN EAST	3145	VIC	3145	1	302\\PS629876	20554564000	20554564000	-37.87483964	145.04077496	FRONTAGE CENTRE SETBACK	2	0101000020A41E000043F649074E216240AF85CDBEFAEF42C0
91594	GAVIC425096507	VIC1981507	locbb6ca08c118e	A	S	\N	\N	UNIT 5	\N	18	\N	HIGH	STREET	\N	UNIT 5, 18 HIGH STREET	NORTHCOTE	3070	VIC	3070	0	5\\PS640884	20145322000	20145322000	-37.78304333	144.99673413	FRONTAGE CENTRE SETBACK	2	0101000020A41E00000665F93EE51F6240B8D98AC33AE442C0
94830	GAVIC425335858	VIC1945221	loc0b8afd71fce1	A	S	\N	\N	UNIT 1304	\N	53	\N	BATMAN	STREET	\N	UNIT 1304, 53 BATMAN STREET	WEST MELBOURNE	3003	VIC	3003	1	1304\\PS703332	20401400000	21339200000	-37.81094876	144.95151565	FRONTAGE CENTRE SETBACK	2	0101000020A41E00003BCCF2D0721E62404477412BCDE742C0
134036	GAVIC719512693	VIC1935604	loc9901d119afda_1	A	S	\N	\N	UNIT 4608	\N	81	\N	ABECKETT	STREET	\N	UNIT 4608, 81 ABECKETT STREET	MELBOURNE	3000	VIC	3000	1	4608\\PS726465	20631917160	21328320000	-37.80936093	144.96121215	FRONTAGE CENTRE SETBACK	2	0101000020A41E00009298FB3FC21E62404C81922399E742C0
175460	GAVIC423728050	VIC1967421	loc9901d119afda_1	A	S	\N	\N	UNIT 206	\N	9	\N	DEGRAVES	STREET	\N	UNIT 206, 9 DEGRAVES STREET	MELBOURNE	3000	VIC	3000	1	206A\\PS508080	20631944140	21334360000	-37.81756618	144.96576928	FRONTAGE CENTRE SETBACK	2	0101000020A41E00009B22FA94E71E624034B53202A6E842C0
197092	GAVIC425294823	VIC1990396	loc31f384e524fe	A	S	\N	\N	SHOP 133A	\N	50	\N	HAIG	STREET	\N	SHOP 133A, 50 HAIG STREET	SOUTHBANK	3006	VIC	3006	0	133A\\PS629585	20631981920	20631981920	-37.82686811	144.95707987	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000EBA9F665A01E6240154771D0D6E942C0
177093	GAVIC721251051	VIC1990305	loc9901d119afda_1	A	S	\N	\N	UNIT 1907	\N	633	\N	LITTLE LONSDALE	STREET	\N	UNIT 1907, 633 LITTLE LONSDALE STREET	MELBOURNE	3000	VIC	3000	1	S33\\PS746092	20664921000	20664921000	-37.81403592	144.95327786	FRONTAGE CENTRE SETBACK	2	0101000020A41E00006D169240811E6240AB153B5432E842C0
69050	GAVIC421992539	VIC2044273	locddc4a1bcd8ba	A	S	FLINDERS WHARF	\N	UNIT 1103	\N	60	\N	SIDDELEY	STREET	\N	UNIT 1103, 60 SIDDELEY STREET	DOCKLANDS	3008	VIC	3008	1	1103\\PS448830	20395090000	20395090000	-37.82267981	144.95252330	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000B2C524127B1E6240C6836F924DE942C0
30295	GAVIC423659466	VIC1970192	loc82b861dfb765	A	S	\N	\N	UNIT 3	\N	23	25	COMAS	GROVE	\N	UNIT 3, 23-25 COMAS GROVE	THORNBURY	3071	VIC	3071	0	3\\PS632362	20631903760	20631903760	-37.75514597	144.98428438	FRONTAGE CENTRE SETBACK	2	0101000020A41E000009C2F4417F1F6240986D869FA8E042C0
119181	GAVIC423537704	VIC1962002	loc31f384e524fe	A	S	\N	\N	UNIT 2007	\N	1	\N	FRESHWATER	PLACE	\N	UNIT 2007, 1 FRESHWATER PLACE	SOUTHBANK	3006	VIC	3006	1	2007\\PS504017	20631945440	20631945440	-37.82152105	144.96247736	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E50A529DCC1E6240E05C0D9A27E942C0
183647	GAVIC721333432	VIC1994837	loc9901d119afda_1	A	S	\N	\N	UNIT 6706	\N	648	\N	LONSDALE	STREET	\N	UNIT 6706, 648 LONSDALE STREET	MELBOURNE	3000	VIC	3000	1	S33\\PS746092	20664921000	20664921000	-37.81448127	144.95342148	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000ED7CC36D821E624062ED18EC40E842C0
130185	GAVIC424636555	VIC2068283	loc72d1f0339be6	A	S	\N	\N	UNIT 4	\N	83	85	WARRANDYTE	ROAD	\N	UNIT 4, 83-85 WARRANDYTE ROAD	RINGWOOD	3134	VIC	3134	0	4\\PS631475	20389280000	20389280000	-37.80532324	145.23009869	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000E18CEDF75C2762401F41F9D414E742C0
98731	GAVIC422117058	VIC2032116	locc586266ef8cc	A	\N	\N	\N	\N	\N	112	\N	THOMSON	STREET	\N	112 THOMSON STREET	SALE	3850	VIC	3850	0	1\\SP25881	20584160000	20584160000	-38.10053998	147.05952448	FRONTAGE CENTRE SETBACK	2	0101000020A41E00002ADDE19FE76162402F057B7EDE0C43C0
90438	GAVIC425853242	VIC1944167	loca0398a35cf5e	A	S	\N	\N	UNIT 610	\N	28	\N	BOUVERIE	STREET	\N	UNIT 610, 28 BOUVERIE STREET	CARLTON	3053	VIC	3053	1	610\\PS720330	20401931000	21320150000	-37.80563395	144.96183795	FRONTAGE CENTRE SETBACK	2	0101000020A41E0000A7696160C71E62400EE665031FE742C0
\.

-- gnaf_202602.address_alias_lookup: 75 rows
\copy gnaf_202602.address_alias_lookup FROM stdin
GAVIC425167658	GAVIC424474882	RANGED ADDRESS
GAVIC719925941	GAVIC720001539	LEVEL DUPLICATION
GAVIC718991138	GAVIC425853242	LEVEL DUPLICATION
GAVIC424795446	GAVIC425027132	LEVEL DUPLICATION
GAVIC719754089	GAVIC719767317	LEVEL DUPLICATION
GAVIC419688276	GAVIC413977671	RANGED ADDRESS
GAVIC425821887	GAVIC719044287	RANGED ADDRESS
GAVIC719523562	GAVIC719459374	LEVEL DUPLICATION
GAVIC422138212	GAVIC423659466	RANGED ADDRESS
GAVIC721290639	GAVIC721251051	LEVEL DUPLICATION
GAVIC423648868	GAVIC421992539	LEVEL DUPLICATION
GAVIC420674743	GAVIC422117058	RANGED ADDRESS
GAVIC425512108	GAVIC425335858	LEVEL DUPLICATION
GAVIC420108368	GAVIC411282405	FLAT NUMBER - NO FIRST SUFFIX CORRELATION
GAVIC425277959	GAVIC425294823	SYNONYM
GAVIC425013948	GAVIC425042539	LEVEL DUPLICATION
GAVIC721549117	GAVIC721459739	LEVEL DUPLICATION
GAVIC420100287	GAVIC422080427	RANGED ADDRESS
GAVIC412089403	GAVIC422443247	SYNONYM
GAVIC425274073	GAVIC425246317	SYNONYM
GAVIC423705816	GAVIC423728755	SYNONYM
GAVIC423705816	GAVIC423728754	SYNONYM
GAVIC423232139	GAVIC412739901	RANGED ADDRESS
GAVIC720052842	GAVIC720075106	LEVEL DUPLICATION
GAVIC424918055	GAVIC425372485	LEVEL DUPLICATION
GAVIC423789992	GAVIC423728050	LEVEL DUPLICATION
GAVIC719439210	GAVIC719459794	LEVEL DUPLICATION
GAVIC425314633	GAVIC425325821	RANGED ADDRESS
GAVIC423750017	GAVIC423537704	LEVEL DUPLICATION
GAVIC719985042	GAVIC719939375	LEVEL DUPLICATION
GAVIC424906559	GAVIC425032577	LEVEL DUPLICATION
GAVIC719439216	GAVIC719006374	LEVEL DUPLICATION
GAVIC423471646	GAVIC423555143	SYNONYM
GAVIC719915818	GAVIC719816339	LEVEL DUPLICATION
GAVIC720518002	GAVIC720471214	LEVEL DUPLICATION
GAVIC425084495	GAVIC425096507	CONTRIBUTOR DEFINED
GAVIC425622336	GAVIC425580055	LEVEL DUPLICATION
GAVIC719524538	GAVIC719457195	LEVEL DUPLICATION
GAVIC421499309	GAVIC413192636	RANGED ADDRESS
GAVIC719979296	GAVIC719770314	LEVEL DUPLICATION
GAVIC424626663	GAVIC421611304	RANGED ADDRESS
GAVIC424633603	GAVIC424636555	RANGED ADDRESS
GAVIC421862656	GAVIC421987657	RANGED ADDRESS
GAVIC425734206	GAVIC425762632	LEVEL DUPLICATION
GAVIC423826364	GAVIC423804130	LEVEL DUPLICATION
GAVIC420298014	GAVIC413382151	RANGED ADDRESS
GAVIC719527287	GAVIC719457877	LEVEL DUPLICATION
GAVIC720058933	GAVIC720234958	LEVEL DUPLICATION
GAVIC425044566	GAVIC420755745	SYNONYM
GAVIC411809712	GAVIC719227954	CONTRIBUTOR DEFINED
GAVIC719983320	GAVIC719749191	LEVEL DUPLICATION
GAVIC719764462	GAVIC719765629	LEVEL DUPLICATION
GAVIC420040549	GAVIC410965788	RANGED ADDRESS
GAVIC424353303	GAVIC424091347	RANGED ADDRESS
GAVIC425275442	GAVIC425013938	LEVEL DUPLICATION
GAVIC420504897	GAVIC421523064	RANGED ADDRESS
GAVIC425520470	GAVIC425420428	LEVEL DUPLICATION
GAVIC423792711	GAVIC423769586	LEVEL DUPLICATION
GAVIC421300189	GAVIC411975916	RANGED ADDRESS
GAVIC719607123	GAVIC719512693	LEVEL DUPLICATION
GAVIC421281678	GAVIC422412680	RANGED ADDRESS
GAVIC721476998	GAVIC721504027	LEVEL DUPLICATION
GAVIC721369066	GAVIC721460023	LEVEL DUPLICATION
GAVIC721284836	GAVIC721333432	LEVEL DUPLICATION
GAVIC425274882	GAVIC425294479	LEVEL DUPLICATION
GAVIC719010591	GAVIC719053315	LEVEL DUPLICATION
GAVIC420695756	GAVIC422113816	SYNONYM
GAVIC419780964	GAVIC422419032	SYNONYM
GAVIC719096818	GAVIC718990761	LEVEL DUPLICATION
GAVIC425285314	GAVIC425232920	LEVEL DUPLICATION
GAVIC719988843	GAVIC719937293	LEVEL DUPLICATION
GAVIC423444001	GAVIC411050404	RANGED ADDRESS
GAVIC423623835	GAVIC412010761	LEVEL DUPLICATION
GAVIC423648049	GAVIC421544966	LEVEL DUPLICATION
GAVIC721289923	GAVIC721387488	LEVEL DUPLICATION
\.

-- gnaf_202602.address_secondary_lookup: 1161 rows
\copy gnaf_202602.address_secondary_lookup FROM stdin
GAVIC423911067	GAVIC423910973	AUTO
GAVIC421147883	GAVIC719312412	AUTO
GAVIC421147883	GAVIC719313057	AUTO
GAVIC421147883	GAVIC719325630	AUTO
GAVIC421147883	GAVIC719326201	AUTO
GAVIC421147883	GAVIC719326364	AUTO
GAVIC421147883	GAVIC719326522	AUTO
GAVIC423911067	GAVIC423910623	AUTO
GAVIC421756773	GAVIC425790683	AUTO
GAVIC421756773	GAVIC425801396	AUTO
GAVIC421756773	GAVIC425801397	AUTO
GAVIC422119571	GAVIC420117915	AUTO
GAVIC423911067	GAVIC423910652	AUTO
GAVIC423911067	GAVIC423910743	AUTO
GAVIC421481958	GAVIC410756335	AUTO
GAVIC419811494	GAVIC721255904	AUTO
GAVIC423911067	GAVIC423910762	AUTO
GAVIC423911067	GAVIC423910945	AUTO
GAVIC423911067	GAVIC423910585	AUTO
GAVIC421756773	GAVIC420639150	AUTO
GAVIC424777831	GAVIC424879183	AUTO
GAVIC420504897	GAVIC421711186	AUTO
GAVIC425511946	GAVIC425511931	AUTO
GAVIC423911067	GAVIC423910291	AUTO
GAVIC421826494	GAVIC413632175	AUTO
GAVIC421826494	GAVIC413632176	AUTO
GAVIC421826494	GAVIC413632177	AUTO
GAVIC421756773	GAVIC420824528	AUTO
GAVIC421756773	GAVIC420523793	AUTO
GAVIC423911067	GAVIC423910648	AUTO
GAVIC421756773	GAVIC421120583	AUTO
GAVIC423911067	GAVIC423910581	AUTO
GAVIC420504897	GAVIC413358157	AUTO
GAVIC420504897	GAVIC413388157	AUTO
GAVIC420504897	GAVIC413345040	AUTO
GAVIC420100287	GAVIC411949303	AUTO
GAVIC421379520	GAVIC413820446	AUTO
GAVIC423911067	GAVIC423910732	AUTO
GAVIC423911067	GAVIC423910738	AUTO
GAVIC423911067	GAVIC423910811	AUTO
GAVIC421756773	GAVIC420013828	AUTO
GAVIC419679289	GAVIC413855401	AUTO
GAVIC423911067	GAVIC423910833	AUTO
GAVIC423911067	GAVIC423910716	AUTO
GAVIC423911067	GAVIC423910718	AUTO
GAVIC423911067	GAVIC423910719	AUTO
GAVIC423911067	GAVIC423910722	AUTO
GAVIC423911067	GAVIC423910724	AUTO
GAVIC423911067	GAVIC423910726	AUTO
GAVIC423911067	GAVIC423910335	AUTO
GAVIC423911067	GAVIC423910365	AUTO
GAVIC423911067	GAVIC423766103	AUTO
GAVIC423911067	GAVIC423807228	AUTO
GAVIC423911067	GAVIC423807240	AUTO
GAVIC423911067	GAVIC423850556	AUTO
GAVIC423911067	GAVIC423910318	AUTO
GAVIC423911067	GAVIC423910326	AUTO
GAVIC423911067	GAVIC423910881	AUTO
GAVIC423911067	GAVIC423910889	AUTO
GAVIC423911067	GAVIC423910900	AUTO
GAVIC423911067	GAVIC423910915	AUTO
GAVIC423911067	GAVIC423910925	AUTO
GAVIC423911067	GAVIC423910934	AUTO
GAVIC423911067	GAVIC423910943	AUTO
GAVIC423911067	GAVIC423910963	AUTO
GAVIC423911067	GAVIC423910742	AUTO
GAVIC423911067	GAVIC423910957	AUTO
GAVIC423911067	GAVIC423910961	AUTO
GAVIC423911067	GAVIC423910965	AUTO
GAVIC423911067	GAVIC423910970	AUTO
GAVIC423911067	GAVIC423910974	AUTO
GAVIC423911067	GAVIC423910979	AUTO
GAVIC423911067	GAVIC423910631	AUTO
GAVIC423911067	GAVIC423910658	AUTO
GAVIC420647207	GAVIC421997892	AUTO
GAVIC423911067	GAVIC423910720	AUTO
GAVIC423911067	GAVIC423910826	AUTO
GAVIC423911067	GAVIC423910352	AUTO
GAVIC423911067	GAVIC423910612	AUTO
GAVIC419912498	GAVIC425666825	AUTO
GAVIC419912498	GAVIC425666828	AUTO
GAVIC421448648	GAVIC421768591	AUTO
GAVIC420504897	GAVIC419582899	AUTO
GAVIC421756773	GAVIC419935588	AUTO
GAVIC420504897	GAVIC420303374	AUTO
GAVIC420504897	GAVIC421101603	AUTO
GAVIC420504897	GAVIC421379348	AUTO
GAVIC423911067	GAVIC423910656	AUTO
GAVIC423911067	GAVIC423910966	AUTO
GAVIC423911067	GAVIC423910453	AUTO
GAVIC423911067	GAVIC423910813	AUTO
GAVIC423911067	GAVIC423910821	AUTO
GAVIC423911067	GAVIC423910739	AUTO
GAVIC422091233	GAVIC420280996	AUTO
GAVIC422161681	GAVIC411043315	AUTO
GAVIC423911067	GAVIC423910454	AUTO
GAVIC423911067	GAVIC423910820	AUTO
GAVIC421756773	GAVIC419925097	AUTO
GAVIC421756773	GAVIC419935763	AUTO
GAVIC424424026	GAVIC423512837	AUTO
GAVIC424424026	GAVIC423512844	AUTO
GAVIC424424026	GAVIC423512851	AUTO
GAVIC424424026	GAVIC423808046	AUTO
GAVIC420504897	GAVIC413350264	AUTO
GAVIC420504897	GAVIC413358158	AUTO
GAVIC421943442	GAVIC424672048	AUTO
GAVIC421943442	GAVIC424672049	AUTO
GAVIC421943442	GAVIC424672050	AUTO
GAVIC420504897	GAVIC419582896	AUTO
GAVIC423911067	GAVIC423910908	AUTO
GAVIC423911067	GAVIC423910733	AUTO
GAVIC423911067	GAVIC423910803	AUTO
GAVIC423911067	GAVIC423910804	AUTO
GAVIC423911067	GAVIC423910805	AUTO
GAVIC423911067	GAVIC423910807	AUTO
GAVIC423911067	GAVIC423910808	AUTO
GAVIC423911067	GAVIC423910809	AUTO
GAVIC423911067	GAVIC423910814	AUTO
GAVIC423911067	GAVIC423910816	AUTO
GAVIC423911067	GAVIC423910818	AUTO
GAVIC423911067	GAVIC423910830	AUTO
GAVIC423911067	GAVIC423910851	AUTO
GAVIC423911067	GAVIC423910852	AUTO
GAVIC423911067	GAVIC423910853	AUTO
GAVIC423911067	GAVIC423910856	AUTO
GAVIC423911067	GAVIC423910857	AUTO
GAVIC423911067	GAVIC423910859	AUTO
GAVIC423911067	GAVIC423910860	AUTO
GAVIC423911067	GAVIC423910863	AUTO
GAVIC423911067	GAVIC423910864	AUTO
GAVIC423911067	GAVIC423910865	AUTO
GAVIC423911067	GAVIC423910867	AUTO
GAVIC423911067	GAVIC423910869	AUTO
GAVIC423911067	GAVIC423910871	AUTO
GAVIC423911067	GAVIC423910872	AUTO
GAVIC423911067	GAVIC423910873	AUTO
GAVIC423911067	GAVIC423910875	AUTO
GAVIC423911067	GAVIC423910877	AUTO
GAVIC423911067	GAVIC423910878	AUTO
GAVIC423911067	GAVIC423910880	AUTO
GAVIC423911067	GAVIC423910884	AUTO
GAVIC423911067	GAVIC423910885	AUTO
GAVIC423911067	GAVIC423910886	AUTO
GAVIC423911067	GAVIC423910888	AUTO
GAVIC423911067	GAVIC423910892	AUTO
GAVIC423911067	GAVIC423910893	AUTO
GAVIC423911067	GAVIC423910894	AUTO
GAVIC423911067	GAVIC423910896	AUTO
GAVIC423911067	GAVIC423910898	AUTO
GAVIC423911067	GAVIC423910901	AUTO
GAVIC423911067	GAVIC423910902	AUTO
GAVIC423911067	GAVIC423910904	AUTO
GAVIC423911067	GAVIC423910906	AUTO
GAVIC423911067	GAVIC423910909	AUTO
GAVIC423911067	GAVIC423910910	AUTO
GAVIC423911067	GAVIC423910913	AUTO
GAVIC423911067	GAVIC423910914	AUTO
GAVIC423911067	GAVIC423910917	AUTO
GAVIC423911067	GAVIC423910919	AUTO
GAVIC423911067	GAVIC423910921	AUTO
GAVIC423911067	GAVIC423910922	AUTO
GAVIC423911067	GAVIC423910923	AUTO
GAVIC423911067	GAVIC423910927	AUTO
GAVIC423911067	GAVIC423910929	AUTO
GAVIC423911067	GAVIC423910930	AUTO
GAVIC423911067	GAVIC423910931	AUTO
GAVIC423911067	GAVIC423910935	AUTO
GAVIC423911067	GAVIC423910937	AUTO
GAVIC423911067	GAVIC423910938	AUTO
GAVIC423911067	GAVIC423910939	AUTO
GAVIC423911067	GAVIC423910942	AUTO
GAVIC423911067	GAVIC423910948	AUTO
GAVIC423911067	GAVIC423910950	AUTO
GAVIC423911067	GAVIC423910744	AUTO
GAVIC423911067	GAVIC423910746	AUTO
GAVIC423911067	GAVIC423910747	AUTO
GAVIC423911067	GAVIC423910748	AUTO
GAVIC423911067	GAVIC423910749	AUTO
GAVIC423911067	GAVIC423910750	AUTO
GAVIC423911067	GAVIC423910752	AUTO
GAVIC423911067	GAVIC423910753	AUTO
GAVIC423911067	GAVIC423910755	AUTO
GAVIC423911067	GAVIC423910757	AUTO
GAVIC423911067	GAVIC423910758	AUTO
GAVIC423911067	GAVIC423910759	AUTO
GAVIC423911067	GAVIC423910760	AUTO
GAVIC423911067	GAVIC423910761	AUTO
GAVIC423911067	GAVIC423910763	AUTO
GAVIC423911067	GAVIC423910764	AUTO
GAVIC423911067	GAVIC423910765	AUTO
GAVIC423911067	GAVIC423910766	AUTO
GAVIC423911067	GAVIC423910768	AUTO
GAVIC423911067	GAVIC423910769	AUTO
GAVIC423911067	GAVIC423910770	AUTO
GAVIC423911067	GAVIC423910771	AUTO
GAVIC423911067	GAVIC423910772	AUTO
GAVIC423911067	GAVIC423910774	AUTO
GAVIC423911067	GAVIC423910775	AUTO
GAVIC423911067	GAVIC423910776	AUTO
GAVIC423911067	GAVIC423910777	AUTO
GAVIC423911067	GAVIC423910780	AUTO
GAVIC423911067	GAVIC423910781	AUTO
GAVIC423911067	GAVIC423910782	AUTO
GAVIC423911067	GAVIC423910783	AUTO
GAVIC423911067	GAVIC423910785	AUTO
GAVIC423911067	GAVIC423910786	AUTO
GAVIC423911067	GAVIC423910787	AUTO
GAVIC423911067	GAVIC423910788	AUTO
GAVIC423911067	GAVIC423910789	AUTO
GAVIC423911067	GAVIC423910791	AUTO
GAVIC423911067	GAVIC423910792	AUTO
GAVIC423911067	GAVIC423910793	AUTO
GAVIC423911067	GAVIC423910794	AUTO
GAVIC423911067	GAVIC423910796	AUTO
GAVIC423911067	GAVIC423910797	AUTO
GAVIC423911067	GAVIC423910798	AUTO
GAVIC423911067	GAVIC423910800	AUTO
GAVIC423911067	GAVIC423910802	AUTO
GAVIC423911067	GAVIC423910832	AUTO
GAVIC420787418	GAVIC721478611	AUTO
GAVIC423911067	GAVIC423910956	AUTO
GAVIC424777831	GAVIC719604838	AUTO
GAVIC424777831	GAVIC719608742	AUTO
GAVIC420591242	GAVIC423705367	AUTO
GAVIC422035533	GAVIC420801193	AUTO
GAVIC423911067	GAVIC423910459	AUTO
GAVIC423911067	GAVIC423910982	AUTO
GAVIC423911067	GAVIC423911002	AUTO
GAVIC423911067	GAVIC423911009	AUTO
GAVIC423911067	GAVIC423910868	AUTO
GAVIC423911067	GAVIC423910876	AUTO
GAVIC423911067	GAVIC423910882	AUTO
GAVIC423911067	GAVIC423910890	AUTO
GAVIC423911067	GAVIC423910897	AUTO
GAVIC423911067	GAVIC423910905	AUTO
GAVIC423911067	GAVIC423910911	AUTO
GAVIC423911067	GAVIC423910918	AUTO
GAVIC423911067	GAVIC423910926	AUTO
GAVIC423911067	GAVIC423910933	AUTO
GAVIC423911067	GAVIC423910940	AUTO
GAVIC423911067	GAVIC423910947	AUTO
GAVIC423911067	GAVIC423910954	AUTO
GAVIC423911067	GAVIC423910962	AUTO
GAVIC423911067	GAVIC423910968	AUTO
GAVIC423911067	GAVIC423910977	AUTO
GAVIC423911067	GAVIC423910386	AUTO
GAVIC423911067	GAVIC423910387	AUTO
GAVIC423911067	GAVIC423910389	AUTO
GAVIC423911067	GAVIC423910390	AUTO
GAVIC423911067	GAVIC423910391	AUTO
GAVIC423911067	GAVIC423910392	AUTO
GAVIC423911067	GAVIC423910393	AUTO
GAVIC423911067	GAVIC423910395	AUTO
GAVIC423911067	GAVIC423910396	AUTO
GAVIC423911067	GAVIC423910397	AUTO
GAVIC423911067	GAVIC423910399	AUTO
GAVIC423911067	GAVIC423910401	AUTO
GAVIC423911067	GAVIC423910402	AUTO
GAVIC423911067	GAVIC423910404	AUTO
GAVIC423911067	GAVIC423910405	AUTO
GAVIC423911067	GAVIC423910411	AUTO
GAVIC423911067	GAVIC423910422	AUTO
GAVIC423911067	GAVIC423910424	AUTO
GAVIC423911067	GAVIC423910433	AUTO
GAVIC423911067	GAVIC423910434	AUTO
GAVIC423911067	GAVIC423910439	AUTO
GAVIC423911067	GAVIC423910440	AUTO
GAVIC423911067	GAVIC423910456	AUTO
GAVIC423911067	GAVIC423910458	AUTO
GAVIC423911067	GAVIC423910517	AUTO
GAVIC423911067	GAVIC423910520	AUTO
GAVIC423911067	GAVIC423910521	AUTO
GAVIC423911067	GAVIC423910523	AUTO
GAVIC423911067	GAVIC423910524	AUTO
GAVIC423911067	GAVIC423910526	AUTO
GAVIC423911067	GAVIC423910527	AUTO
GAVIC423911067	GAVIC423910528	AUTO
GAVIC423911067	GAVIC423910529	AUTO
GAVIC423911067	GAVIC423910530	AUTO
GAVIC423911067	GAVIC423910532	AUTO
GAVIC423911067	GAVIC423910534	AUTO
GAVIC423911067	GAVIC423910535	AUTO
GAVIC423911067	GAVIC423910536	AUTO
GAVIC423911067	GAVIC423910538	AUTO
GAVIC423911067	GAVIC423910539	AUTO
GAVIC423911067	GAVIC423910540	AUTO
GAVIC423911067	GAVIC423910541	AUTO
GAVIC423911067	GAVIC423910542	AUTO
GAVIC423911067	GAVIC423910545	AUTO
GAVIC423911067	GAVIC423910546	AUTO
GAVIC423911067	GAVIC423910547	AUTO
GAVIC423911067	GAVIC423910548	AUTO
GAVIC423911067	GAVIC423910550	AUTO
GAVIC423911067	GAVIC423910551	AUTO
GAVIC423911067	GAVIC423911006	AUTO
GAVIC423911067	GAVIC423910388	AUTO
GAVIC423911067	GAVIC423910590	AUTO
GAVIC423911067	GAVIC423910596	AUTO
GAVIC423911067	GAVIC423910603	AUTO
GAVIC423911067	GAVIC423910621	AUTO
GAVIC423911067	GAVIC423910637	AUTO
GAVIC423911067	GAVIC423910509	AUTO
GAVIC423911067	GAVIC423910394	AUTO
GAVIC423911067	GAVIC423910400	AUTO
GAVIC423911067	GAVIC423910406	AUTO
GAVIC423911067	GAVIC423910423	AUTO
GAVIC423911067	GAVIC423910438	AUTO
GAVIC423911067	GAVIC423910452	AUTO
GAVIC423911067	GAVIC423910457	AUTO
GAVIC423911067	GAVIC423910503	AUTO
GAVIC423911067	GAVIC423910508	AUTO
GAVIC423911067	GAVIC423910513	AUTO
GAVIC423911067	GAVIC423910519	AUTO
GAVIC423911067	GAVIC423910525	AUTO
GAVIC423911067	GAVIC423910531	AUTO
GAVIC423911067	GAVIC423910537	AUTO
GAVIC423911067	GAVIC423910543	AUTO
GAVIC423911067	GAVIC423910549	AUTO
GAVIC423911067	GAVIC423910554	AUTO
GAVIC423911067	GAVIC423910568	AUTO
GAVIC423911067	GAVIC423910575	AUTO
GAVIC423911067	GAVIC423931399	AUTO
GAVIC423911067	GAVIC423910848	AUTO
GAVIC423911067	GAVIC423910576	AUTO
GAVIC423911067	GAVIC423910593	AUTO
GAVIC423911067	GAVIC423910605	AUTO
GAVIC423911067	GAVIC423910609	AUTO
GAVIC423911067	GAVIC423910615	AUTO
GAVIC420504897	GAVIC419690809	AUTO
GAVIC420504897	GAVIC419890141	AUTO
GAVIC420504897	GAVIC420303377	AUTO
GAVIC420504897	GAVIC420596731	AUTO
GAVIC420504897	GAVIC421101880	AUTO
GAVIC420504897	GAVIC421379345	AUTO
GAVIC420504897	GAVIC421379352	AUTO
GAVIC421756773	GAVIC421120581	AUTO
GAVIC423911067	GAVIC423910363	AUTO
GAVIC421756773	GAVIC420522920	AUTO
GAVIC421756773	GAVIC423670892	AUTO
GAVIC423911067	GAVIC423910912	AUTO
GAVIC423911067	GAVIC423910941	AUTO
GAVIC423911067	GAVIC423910636	AUTO
GAVIC423911067	GAVIC423911003	AUTO
GAVIC423911067	GAVIC423910999	AUTO
GAVIC423911067	GAVIC423911008	AUTO
GAVIC421756773	GAVIC420212050	AUTO
GAVIC421756773	GAVIC420221085	AUTO
GAVIC420504897	GAVIC413345024	AUTO
GAVIC423911067	GAVIC423911011	AUTO
GAVIC420504897	GAVIC421194421	AUTO
GAVIC421756773	GAVIC420534387	AUTO
GAVIC421756773	GAVIC420834596	AUTO
GAVIC421756773	GAVIC420834605	AUTO
GAVIC419623906	GAVIC424097065	AUTO
GAVIC419623906	GAVIC424097067	AUTO
GAVIC421756773	GAVIC421424025	AUTO
GAVIC421756773	GAVIC421424026	AUTO
GAVIC421756773	GAVIC421424027	AUTO
GAVIC421756773	GAVIC421424029	AUTO
GAVIC421756773	GAVIC421459238	AUTO
GAVIC421756773	GAVIC421460701	AUTO
GAVIC421756773	GAVIC421471703	AUTO
GAVIC421756773	GAVIC421471705	AUTO
GAVIC421756773	GAVIC421471706	AUTO
GAVIC421756773	GAVIC421471707	AUTO
GAVIC423911067	GAVIC423910378	AUTO
GAVIC421756773	GAVIC420221086	AUTO
GAVIC423911067	GAVIC423910572	AUTO
GAVIC422091233	GAVIC421825689	AUTO
GAVIC420100287	GAVIC420364185	AUTO
GAVIC420100287	GAVIC420364186	AUTO
GAVIC420504897	GAVIC419582900	AUTO
GAVIC423911067	GAVIC423910630	AUTO
GAVIC421756773	GAVIC419925094	AUTO
GAVIC421756773	GAVIC419935583	AUTO
GAVIC421756773	GAVIC419935757	AUTO
GAVIC421756773	GAVIC419935765	AUTO
GAVIC421756773	GAVIC420209392	AUTO
GAVIC421756773	GAVIC420210359	AUTO
GAVIC421756773	GAVIC420221084	AUTO
GAVIC421756773	GAVIC420221090	AUTO
GAVIC421756773	GAVIC420228152	AUTO
GAVIC421756773	GAVIC420230137	AUTO
GAVIC421756773	GAVIC420523791	AUTO
GAVIC421756773	GAVIC420523798	AUTO
GAVIC421756773	GAVIC420530870	AUTO
GAVIC421756773	GAVIC420534390	AUTO
GAVIC421756773	GAVIC420824530	AUTO
GAVIC421756773	GAVIC420834597	AUTO
GAVIC421756773	GAVIC420834604	AUTO
GAVIC421756773	GAVIC420834609	AUTO
GAVIC421756773	GAVIC421113699	AUTO
GAVIC421756773	GAVIC421113704	AUTO
GAVIC421756773	GAVIC421117058	AUTO
GAVIC421756773	GAVIC421120585	AUTO
GAVIC421756773	GAVIC421130991	AUTO
GAVIC421756773	GAVIC421134503	AUTO
GAVIC421756773	GAVIC421424017	AUTO
GAVIC421756773	GAVIC421424023	AUTO
GAVIC421756773	GAVIC421424028	AUTO
GAVIC420504897	GAVIC419999138	AUTO
GAVIC420583086	GAVIC423110633	AUTO
GAVIC420583086	GAVIC423110634	AUTO
GAVIC423911067	GAVIC423910836	AUTO
GAVIC421756773	GAVIC421120590	AUTO
GAVIC421756773	GAVIC421424015	AUTO
GAVIC412227164	GAVIC423657181	AUTO
GAVIC420504897	GAVIC413345038	AUTO
GAVIC421756773	GAVIC419925091	AUTO
GAVIC421756773	GAVIC420209394	AUTO
GAVIC421736429	GAVIC720570385	AUTO
GAVIC421736429	GAVIC720572732	AUTO
GAVIC421736429	GAVIC720573704	AUTO
GAVIC421736429	GAVIC720578030	AUTO
GAVIC421736429	GAVIC720578348	AUTO
GAVIC412227164	GAVIC422436721	AUTO
GAVIC423911067	GAVIC423910972	AUTO
GAVIC420504897	GAVIC413354798	AUTO
GAVIC420504897	GAVIC413350250	AUTO
GAVIC420100287	GAVIC411990822	AUTO
GAVIC423911067	GAVIC423910626	AUTO
GAVIC423911067	GAVIC423910647	AUTO
GAVIC423911067	GAVIC423910599	AUTO
GAVIC423911067	GAVIC423910823	AUTO
GAVIC421756773	GAVIC421424019	AUTO
GAVIC420684174	GAVIC720505977	AUTO
GAVIC420684174	GAVIC720517583	AUTO
GAVIC423911067	GAVIC423850563	AUTO
GAVIC421756773	GAVIC420221088	AUTO
GAVIC421307669	GAVIC420279882	AUTO
GAVIC424754823	GAVIC425518682	MANUAL
GAVIC424490619	GAVIC421372945	MANUAL
GAVIC420812068	GAVIC719410916	AUTO
GAVIC420812068	GAVIC719427826	AUTO
GAVIC423911067	GAVIC719413756	AUTO
GAVIC423911067	GAVIC719428550	AUTO
GAVIC420100287	GAVIC421230479	AUTO
GAVIC423911067	GAVIC423910515	AUTO
GAVIC423911067	GAVIC423910506	AUTO
GAVIC423911067	GAVIC423910964	AUTO
GAVIC422091233	GAVIC420570484	AUTO
GAVIC422024006	GAVIC419744898	AUTO
GAVIC420504897	GAVIC421379353	AUTO
GAVIC420504897	GAVIC421523066	AUTO
GAVIC423911067	GAVIC423910510	AUTO
GAVIC423911067	GAVIC423910613	AUTO
GAVIC421756773	GAVIC419935756	AUTO
GAVIC421756773	GAVIC425373684	AUTO
GAVIC420504897	GAVIC421379346	AUTO
GAVIC412227164	GAVIC422436723	AUTO
GAVIC412227164	GAVIC423657182	AUTO
GAVIC421756773	GAVIC419935586	AUTO
GAVIC421756773	GAVIC419935762	AUTO
GAVIC421756773	GAVIC420212039	AUTO
GAVIC421756773	GAVIC419607421	AUTO
GAVIC421756773	GAVIC419607460	AUTO
GAVIC421379520	GAVIC413820441	AUTO
GAVIC421756773	GAVIC419607463	AUTO
GAVIC421756773	GAVIC419607468	AUTO
GAVIC421756773	GAVIC419620876	AUTO
GAVIC421756773	GAVIC419620880	AUTO
GAVIC421756773	GAVIC419925088	AUTO
GAVIC421756773	GAVIC419925092	AUTO
GAVIC421756773	GAVIC419925096	AUTO
GAVIC421756773	GAVIC419925103	AUTO
GAVIC421756773	GAVIC419935585	AUTO
GAVIC421756773	GAVIC419935760	AUTO
GAVIC423911067	GAVIC423910516	AUTO
GAVIC419645242	GAVIC421989643	AUTO
GAVIC420205676	GAVIC719003303	AUTO
GAVIC420205676	GAVIC719008547	AUTO
GAVIC424732111	GAVIC424722543	AUTO
GAVIC421756773	GAVIC419935766	AUTO
GAVIC423911067	GAVIC423910455	AUTO
GAVIC423911067	GAVIC423910290	AUTO
GAVIC420674743	GAVIC419766223	AUTO
GAVIC424424026	GAVIC423512839	AUTO
GAVIC424424026	GAVIC423512840	AUTO
GAVIC424424026	GAVIC423512841	AUTO
GAVIC424424026	GAVIC423512843	AUTO
GAVIC424424026	GAVIC423512845	AUTO
GAVIC424424026	GAVIC423512847	AUTO
GAVIC424424026	GAVIC423512848	AUTO
GAVIC424424026	GAVIC423512850	AUTO
GAVIC424424026	GAVIC423512852	AUTO
GAVIC424424026	GAVIC423512854	AUTO
GAVIC424424026	GAVIC423512855	AUTO
GAVIC424424026	GAVIC423512856	AUTO
GAVIC424424026	GAVIC424274934	AUTO
GAVIC424424026	GAVIC424550733	AUTO
GAVIC423911067	GAVIC423910332	AUTO
GAVIC423911067	GAVIC423910604	AUTO
GAVIC423911067	GAVIC423910944	AUTO
GAVIC423911067	GAVIC423910650	AUTO
GAVIC423911067	GAVIC423910951	AUTO
GAVIC412227164	GAVIC422436724	AUTO
GAVIC420504897	GAVIC413350268	AUTO
GAVIC420504897	GAVIC413358159	AUTO
GAVIC420504897	GAVIC413345036	AUTO
GAVIC420504897	GAVIC413354797	AUTO
GAVIC420504897	GAVIC413345026	AUTO
GAVIC420100287	GAVIC411947529	AUTO
GAVIC420100287	GAVIC411954170	AUTO
GAVIC423911067	GAVIC423910936	AUTO
GAVIC419623906	GAVIC424097066	AUTO
GAVIC423911067	GAVIC423911005	AUTO
GAVIC421756773	GAVIC421120586	AUTO
GAVIC423911067	GAVIC423910955	AUTO
GAVIC423911067	GAVIC423910727	AUTO
GAVIC423911067	GAVIC423910730	AUTO
GAVIC423911067	GAVIC423910741	AUTO
GAVIC423911067	GAVIC423910980	AUTO
GAVIC423911067	GAVIC423910829	AUTO
GAVIC423911067	GAVIC423910410	AUTO
GAVIC421756773	GAVIC420534385	AUTO
GAVIC423911067	GAVIC423910646	AUTO
GAVIC423911067	GAVIC423910653	AUTO
GAVIC423911067	GAVIC423910661	AUTO
GAVIC423911067	GAVIC423910669	AUTO
GAVIC423911067	GAVIC423910680	AUTO
GAVIC423911067	GAVIC423910687	AUTO
GAVIC423911067	GAVIC423910694	AUTO
GAVIC423911067	GAVIC423910702	AUTO
GAVIC423911067	GAVIC423910709	AUTO
GAVIC423911067	GAVIC423910715	AUTO
GAVIC423911067	GAVIC423910723	AUTO
GAVIC423911067	GAVIC423910597	AUTO
GAVIC423911067	GAVIC423910854	AUTO
GAVIC423911067	GAVIC423910887	AUTO
GAVIC423911067	GAVIC423910916	AUTO
GAVIC423911067	GAVIC423910514	AUTO
GAVIC420504897	GAVIC420497780	AUTO
GAVIC420504897	GAVIC421194420	AUTO
GAVIC420504897	GAVIC421523065	AUTO
GAVIC423911067	GAVIC423910625	AUTO
GAVIC423911067	GAVIC423910634	AUTO
GAVIC423911067	GAVIC423910645	AUTO
GAVIC422086500	GAVIC419913712	AUTO
GAVIC419623906	GAVIC424097064	AUTO
GAVIC419623906	GAVIC424097068	AUTO
GAVIC423911067	GAVIC423910672	AUTO
GAVIC423911067	GAVIC423910679	AUTO
GAVIC423911067	GAVIC423910683	AUTO
GAVIC423911067	GAVIC423910688	AUTO
GAVIC423911067	GAVIC423910692	AUTO
GAVIC423911067	GAVIC423910696	AUTO
GAVIC423911067	GAVIC423910700	AUTO
GAVIC423911067	GAVIC423910704	AUTO
GAVIC423911067	GAVIC423910708	AUTO
GAVIC423911067	GAVIC423910712	AUTO
GAVIC423911067	GAVIC423910717	AUTO
GAVIC423911067	GAVIC423910721	AUTO
GAVIC423911067	GAVIC423910725	AUTO
GAVIC423911067	GAVIC423910450	AUTO
GAVIC423911067	GAVIC423910622	AUTO
GAVIC423911067	GAVIC423910728	AUTO
GAVIC425707510	GAVIC425670912	AUTO
GAVIC420048609	GAVIC412313998	AUTO
GAVIC413630613	GAVIC421490669	AUTO
GAVIC423911067	GAVIC423910834	AUTO
GAVIC420502224	GAVIC719316368	AUTO
GAVIC420502224	GAVIC719319802	AUTO
GAVIC420502224	GAVIC719321680	AUTO
GAVIC421109751	GAVIC721598830	AUTO
GAVIC420504897	GAVIC413350270	AUTO
GAVIC420504897	GAVIC413388156	AUTO
GAVIC421736429	GAVIC721106242	AUTO
GAVIC419679289	GAVIC413855375	AUTO
GAVIC419679289	GAVIC413855397	AUTO
GAVIC419679289	GAVIC413855398	AUTO
GAVIC419679289	GAVIC413855399	AUTO
GAVIC421756773	GAVIC419620879	AUTO
GAVIC421756773	GAVIC419925087	AUTO
GAVIC421756773	GAVIC419925089	AUTO
GAVIC421756773	GAVIC419925090	AUTO
GAVIC421756773	GAVIC419925095	AUTO
GAVIC421756773	GAVIC419935584	AUTO
GAVIC421756773	GAVIC419935758	AUTO
GAVIC421756773	GAVIC419935759	AUTO
GAVIC421756773	GAVIC419935761	AUTO
GAVIC421756773	GAVIC420209396	AUTO
GAVIC421756773	GAVIC420212049	AUTO
GAVIC421756773	GAVIC420210362	AUTO
GAVIC423911067	GAVIC423910298	AUTO
GAVIC423911067	GAVIC423910845	AUTO
GAVIC412227164	GAVIC422436725	AUTO
GAVIC420100287	GAVIC420364187	AUTO
GAVIC421756773	GAVIC420228158	AUTO
GAVIC421756773	GAVIC420530868	AUTO
GAVIC421756773	GAVIC420831084	AUTO
GAVIC423911067	GAVIC423910582	AUTO
GAVIC421756773	GAVIC421134501	AUTO
GAVIC421756773	GAVIC421424018	AUTO
GAVIC420674743	GAVIC412274123	AUTO
GAVIC420674743	GAVIC412276990	AUTO
GAVIC422024006	GAVIC419745736	AUTO
GAVIC422024006	GAVIC420344668	AUTO
GAVIC422024006	GAVIC420649644	AUTO
GAVIC423911067	GAVIC423910838	AUTO
GAVIC421756773	GAVIC421120589	AUTO
GAVIC423911067	GAVIC423910349	AUTO
GAVIC424424026	GAVIC423512838	AUTO
GAVIC424424026	GAVIC423512842	AUTO
GAVIC420504897	GAVIC413388159	AUTO
GAVIC420504897	GAVIC413388158	AUTO
GAVIC420504897	GAVIC413358155	AUTO
GAVIC421739766	GAVIC719313427	AUTO
GAVIC421739766	GAVIC719317657	AUTO
GAVIC423911067	GAVIC423910334	AUTO
GAVIC423911067	GAVIC423910842	AUTO
GAVIC421756773	GAVIC419935587	AUTO
GAVIC423911067	GAVIC423910408	AUTO
GAVIC423911067	GAVIC423910552	AUTO
GAVIC423911067	GAVIC423910553	AUTO
GAVIC423911067	GAVIC423910556	AUTO
GAVIC423911067	GAVIC423910557	AUTO
GAVIC423911067	GAVIC423910558	AUTO
GAVIC423911067	GAVIC423910559	AUTO
GAVIC423911067	GAVIC423910560	AUTO
GAVIC423911067	GAVIC423910562	AUTO
GAVIC423911067	GAVIC423910563	AUTO
GAVIC423911067	GAVIC423910564	AUTO
GAVIC423911067	GAVIC423910567	AUTO
GAVIC423911067	GAVIC423910569	AUTO
GAVIC423911067	GAVIC423910570	AUTO
GAVIC423911067	GAVIC423910571	AUTO
GAVIC423911067	GAVIC423910573	AUTO
GAVIC423911067	GAVIC423910574	AUTO
GAVIC423911067	GAVIC423910577	AUTO
GAVIC423911067	GAVIC423910578	AUTO
GAVIC423911067	GAVIC423910579	AUTO
GAVIC423911067	GAVIC423910580	AUTO
GAVIC423911067	GAVIC423910583	AUTO
GAVIC423911067	GAVIC423910584	AUTO
GAVIC423911067	GAVIC423910586	AUTO
GAVIC423911067	GAVIC423910587	AUTO
GAVIC423911067	GAVIC423910588	AUTO
GAVIC423911067	GAVIC423910591	AUTO
GAVIC423911067	GAVIC423910594	AUTO
GAVIC423911067	GAVIC423910598	AUTO
GAVIC423911067	GAVIC423910607	AUTO
GAVIC423911067	GAVIC423910627	AUTO
GAVIC423911067	GAVIC423910641	AUTO
GAVIC423911067	GAVIC423910660	AUTO
GAVIC423911067	GAVIC423910662	AUTO
GAVIC423911067	GAVIC423910665	AUTO
GAVIC423911067	GAVIC423910666	AUTO
GAVIC423911067	GAVIC423910668	AUTO
GAVIC423911067	GAVIC423910671	AUTO
GAVIC423911067	GAVIC423910673	AUTO
GAVIC423911067	GAVIC423910678	AUTO
GAVIC423911067	GAVIC423910681	AUTO
GAVIC423911067	GAVIC423910682	AUTO
GAVIC423911067	GAVIC423910684	AUTO
GAVIC423911067	GAVIC423910686	AUTO
GAVIC423911067	GAVIC423910689	AUTO
GAVIC423911067	GAVIC423910690	AUTO
GAVIC423911067	GAVIC423910691	AUTO
GAVIC423911067	GAVIC423910693	AUTO
GAVIC423911067	GAVIC423910697	AUTO
GAVIC423911067	GAVIC423910698	AUTO
GAVIC423911067	GAVIC423910699	AUTO
GAVIC423911067	GAVIC423910701	AUTO
GAVIC423911067	GAVIC423910705	AUTO
GAVIC423911067	GAVIC423910706	AUTO
GAVIC423911067	GAVIC423910707	AUTO
GAVIC423911067	GAVIC423910710	AUTO
GAVIC423911067	GAVIC423910711	AUTO
GAVIC423911067	GAVIC423910714	AUTO
GAVIC421756773	GAVIC420516154	AUTO
GAVIC421756773	GAVIC420523799	AUTO
GAVIC421756773	GAVIC420534389	AUTO
GAVIC421756773	GAVIC420824532	AUTO
GAVIC423911067	GAVIC423910967	AUTO
GAVIC423911067	GAVIC423910601	AUTO
GAVIC423911067	GAVIC423910616	AUTO
GAVIC421756773	GAVIC421117056	AUTO
GAVIC423911067	GAVIC423910366	AUTO
GAVIC423911067	GAVIC423910667	AUTO
GAVIC423911067	GAVIC423766101	AUTO
GAVIC423911067	GAVIC423807229	AUTO
GAVIC423911067	GAVIC423807243	AUTO
GAVIC423911067	GAVIC423910663	AUTO
GAVIC421756773	GAVIC423670896	AUTO
GAVIC423911067	GAVIC423910481	AUTO
GAVIC423911067	GAVIC423910827	AUTO
GAVIC420100287	GAVIC411947535	AUTO
GAVIC423911067	GAVIC423910512	AUTO
GAVIC420504897	GAVIC413349596	AUTO
GAVIC420504897	GAVIC413345039	AUTO
GAVIC420504897	GAVIC421379350	AUTO
GAVIC421307669	GAVIC420909085	AUTO
GAVIC423911067	GAVIC423807245	AUTO
GAVIC423911067	GAVIC423850558	AUTO
GAVIC423911067	GAVIC423850562	AUTO
GAVIC423911067	GAVIC423850566	AUTO
GAVIC423911067	GAVIC423905286	AUTO
GAVIC423911067	GAVIC423905291	AUTO
GAVIC423911067	GAVIC423905295	AUTO
GAVIC423911067	GAVIC423910289	AUTO
GAVIC423911067	GAVIC423910306	AUTO
GAVIC423911067	GAVIC423910317	AUTO
GAVIC423911067	GAVIC423910321	AUTO
GAVIC423911067	GAVIC423910325	AUTO
GAVIC423911067	GAVIC423910329	AUTO
GAVIC423911067	GAVIC423910333	AUTO
GAVIC423911067	GAVIC423910338	AUTO
GAVIC423911067	GAVIC423910642	AUTO
GAVIC421448648	GAVIC420524155	AUTO
GAVIC423911067	GAVIC423910620	AUTO
GAVIC423911067	GAVIC425689556	AUTO
GAVIC423911067	GAVIC425689557	AUTO
GAVIC423911067	GAVIC423910606	AUTO
GAVIC423911067	GAVIC423910460	AUTO
GAVIC419598648	GAVIC721019681	AUTO
GAVIC423911067	GAVIC423910831	AUTO
GAVIC420504897	GAVIC419880895	AUTO
GAVIC420504897	GAVIC421101877	AUTO
GAVIC420674743	GAVIC420374475	AUTO
GAVIC420674743	GAVIC420666766	AUTO
GAVIC420674743	GAVIC421581724	AUTO
GAVIC423911067	GAVIC423910825	AUTO
GAVIC423911067	GAVIC423910624	AUTO
GAVIC423911067	GAVIC423910640	AUTO
GAVIC421756773	GAVIC423161219	AUTO
GAVIC421756773	GAVIC425373685	AUTO
GAVIC423911067	GAVIC423910409	AUTO
GAVIC424732111	GAVIC424722544	AUTO
GAVIC420591242	GAVIC423827588	AUTO
GAVIC423911067	GAVIC423910323	AUTO
GAVIC421756773	GAVIC420221089	AUTO
GAVIC421756773	GAVIC420228147	AUTO
GAVIC421756773	GAVIC420228148	AUTO
GAVIC421756773	GAVIC420228151	AUTO
GAVIC421756773	GAVIC420228154	AUTO
GAVIC421756773	GAVIC420228157	AUTO
GAVIC421756773	GAVIC420230878	AUTO
GAVIC421756773	GAVIC420230881	AUTO
GAVIC421756773	GAVIC420230882	AUTO
GAVIC421756773	GAVIC420522921	AUTO
GAVIC421756773	GAVIC420523794	AUTO
GAVIC421756773	GAVIC420523795	AUTO
GAVIC421756773	GAVIC420523797	AUTO
GAVIC421756773	GAVIC420523804	AUTO
GAVIC421756773	GAVIC420523805	AUTO
GAVIC421756773	GAVIC420530869	AUTO
GAVIC421756773	GAVIC420530871	AUTO
GAVIC421756773	GAVIC420534386	AUTO
GAVIC421756773	GAVIC420534391	AUTO
GAVIC421756773	GAVIC420823137	AUTO
GAVIC421756773	GAVIC420823141	AUTO
GAVIC421756773	GAVIC420824531	AUTO
GAVIC421756773	GAVIC420824534	AUTO
GAVIC421756773	GAVIC420831083	AUTO
GAVIC421756773	GAVIC420834598	AUTO
GAVIC421756773	GAVIC420834600	AUTO
GAVIC421756773	GAVIC420834602	AUTO
GAVIC421756773	GAVIC420834606	AUTO
GAVIC421756773	GAVIC420834607	AUTO
GAVIC421756773	GAVIC420834608	AUTO
GAVIC421756773	GAVIC421111733	AUTO
GAVIC421756773	GAVIC421113696	AUTO
GAVIC421756773	GAVIC421113697	AUTO
GAVIC421756773	GAVIC421113698	AUTO
GAVIC421756773	GAVIC421113700	AUTO
GAVIC421756773	GAVIC421113701	AUTO
GAVIC421756773	GAVIC421113702	AUTO
GAVIC421756773	GAVIC421113703	AUTO
GAVIC421756773	GAVIC421117054	AUTO
GAVIC421756773	GAVIC421117055	AUTO
GAVIC421756773	GAVIC421117057	AUTO
GAVIC421756773	GAVIC421117059	AUTO
GAVIC421756773	GAVIC421120582	AUTO
GAVIC421756773	GAVIC421134499	AUTO
GAVIC421756773	GAVIC421134500	AUTO
GAVIC421756773	GAVIC421134504	AUTO
GAVIC421756773	GAVIC421272101	AUTO
GAVIC421756773	GAVIC421424021	AUTO
GAVIC421731563	GAVIC721381547	AUTO
GAVIC421731563	GAVIC721381691	AUTO
GAVIC421731563	GAVIC721381732	AUTO
GAVIC421731563	GAVIC721381965	AUTO
GAVIC421731563	GAVIC721381987	AUTO
GAVIC421731563	GAVIC721382381	AUTO
GAVIC421731563	GAVIC721382433	AUTO
GAVIC421756773	GAVIC420209390	AUTO
GAVIC421756773	GAVIC420212038	AUTO
GAVIC421756773	GAVIC420228159	AUTO
GAVIC421756773	GAVIC420523802	AUTO
GAVIC421756773	GAVIC419607422	AUTO
GAVIC421756773	GAVIC419607458	AUTO
GAVIC421756773	GAVIC419607459	AUTO
GAVIC421756773	GAVIC419607461	AUTO
GAVIC421756773	GAVIC419607465	AUTO
GAVIC421756773	GAVIC419607466	AUTO
GAVIC421756773	GAVIC419607467	AUTO
GAVIC421756773	GAVIC419607469	AUTO
GAVIC421756773	GAVIC419620875	AUTO
GAVIC421756773	GAVIC419620877	AUTO
GAVIC421756773	GAVIC419620878	AUTO
GAVIC421756773	GAVIC421471708	AUTO
GAVIC421756773	GAVIC421471710	AUTO
GAVIC421756773	GAVIC421471711	AUTO
GAVIC421756773	GAVIC421471712	AUTO
GAVIC421756773	GAVIC421471713	AUTO
GAVIC421756773	GAVIC421475119	AUTO
GAVIC421756773	GAVIC421475121	AUTO
GAVIC421756773	GAVIC421475122	AUTO
GAVIC421756773	GAVIC421475123	AUTO
GAVIC421756773	GAVIC421475124	AUTO
GAVIC421756773	GAVIC421713300	AUTO
GAVIC421756773	GAVIC421713983	AUTO
GAVIC421756773	GAVIC421713984	AUTO
GAVIC421756773	GAVIC421713985	AUTO
GAVIC421756773	GAVIC421717600	AUTO
GAVIC421756773	GAVIC421717601	AUTO
GAVIC421756773	GAVIC421717602	AUTO
GAVIC421756773	GAVIC421717603	AUTO
GAVIC421756773	GAVIC421717604	AUTO
GAVIC421756773	GAVIC421717606	AUTO
GAVIC421756773	GAVIC421717607	AUTO
GAVIC421756773	GAVIC421717608	AUTO
GAVIC421756773	GAVIC421717609	AUTO
GAVIC421756773	GAVIC421717611	AUTO
GAVIC421756773	GAVIC421717612	AUTO
GAVIC421756773	GAVIC421717613	AUTO
GAVIC421756773	GAVIC421717614	AUTO
GAVIC421756773	GAVIC421728400	AUTO
GAVIC421756773	GAVIC421728401	AUTO
GAVIC421756773	GAVIC421728402	AUTO
GAVIC421756773	GAVIC421728403	AUTO
GAVIC421756773	GAVIC421940561	AUTO
GAVIC421756773	GAVIC423161240	AUTO
GAVIC421756773	GAVIC423512959	AUTO
GAVIC421756773	GAVIC423670893	AUTO
GAVIC421756773	GAVIC423670894	AUTO
GAVIC421756773	GAVIC423670895	AUTO
GAVIC412227164	GAVIC422436722	AUTO
GAVIC423911067	GAVIC423910850	AUTO
GAVIC423911067	GAVIC423910589	AUTO
GAVIC421756773	GAVIC421471704	AUTO
GAVIC421756773	GAVIC421471709	AUTO
GAVIC421756773	GAVIC421475120	AUTO
GAVIC421756773	GAVIC421713299	AUTO
GAVIC421756773	GAVIC421717599	AUTO
GAVIC421756773	GAVIC421717605	AUTO
GAVIC421756773	GAVIC421717610	AUTO
GAVIC421756773	GAVIC421728399	AUTO
GAVIC421756773	GAVIC421764509	AUTO
GAVIC421756773	GAVIC423512960	AUTO
GAVIC420504897	GAVIC419690814	AUTO
GAVIC420504897	GAVIC420596729	AUTO
GAVIC420504897	GAVIC413349599	AUTO
GAVIC423911067	GAVIC423910657	AUTO
GAVIC422086500	GAVIC421112698	AUTO
GAVIC420757091	GAVIC420488133	AUTO
GAVIC423911067	GAVIC423910470	AUTO
GAVIC419598648	GAVIC721032053	AUTO
GAVIC419598648	GAVIC721039683	AUTO
GAVIC423911067	GAVIC423850560	AUTO
GAVIC423911067	GAVIC423905285	AUTO
GAVIC423911067	GAVIC423905296	AUTO
GAVIC423911067	GAVIC423910299	AUTO
GAVIC423911067	GAVIC423910322	AUTO
GAVIC423911067	GAVIC423910330	AUTO
GAVIC423911067	GAVIC423910350	AUTO
GAVIC423911067	GAVIC423910379	AUTO
GAVIC423911067	GAVIC423910861	AUTO
GAVIC421481958	GAVIC410749974	AUTO
GAVIC420099787	GAVIC424446946	AUTO
GAVIC420099787	GAVIC424446952	AUTO
GAVIC422035533	GAVIC419590797	AUTO
GAVIC422035533	GAVIC419736496	AUTO
GAVIC421708673	GAVIC719638644	AUTO
GAVIC421708673	GAVIC719638912	AUTO
GAVIC423911067	GAVIC423910339	AUTO
GAVIC423911067	GAVIC423910946	AUTO
GAVIC423911067	GAVIC423910969	AUTO
GAVIC423911067	GAVIC423910837	AUTO
GAVIC423911067	GAVIC423910841	AUTO
GAVIC423911067	GAVIC423910858	AUTO
GAVIC423911067	GAVIC423910862	AUTO
GAVIC423911067	GAVIC423910866	AUTO
GAVIC423911067	GAVIC423910870	AUTO
GAVIC423911067	GAVIC423910883	AUTO
GAVIC423911067	GAVIC423910891	AUTO
GAVIC423911067	GAVIC423910895	AUTO
GAVIC423911067	GAVIC423910903	AUTO
GAVIC423911067	GAVIC423910920	AUTO
GAVIC423911067	GAVIC423910928	AUTO
GAVIC423911067	GAVIC423910932	AUTO
GAVIC423911067	GAVIC423910949	AUTO
GAVIC424676885	GAVIC721167340	AUTO
GAVIC421262022	GAVIC720231351	AUTO
GAVIC423911067	GAVIC423910958	AUTO
GAVIC414839745	GAVIC420773301	MANUAL
GAVIC420504897	GAVIC413358156	AUTO
GAVIC420504897	GAVIC413354795	AUTO
GAVIC423911067	GAVIC423910828	AUTO
GAVIC420504897	GAVIC413349602	AUTO
GAVIC424424026	GAVIC423512846	AUTO
GAVIC424424026	GAVIC423512849	AUTO
GAVIC424424026	GAVIC423512853	AUTO
GAVIC424424026	GAVIC423808045	AUTO
GAVIC420504897	GAVIC413350248	AUTO
GAVIC422091233	GAVIC420890532	AUTO
GAVIC423911067	GAVIC423910628	AUTO
GAVIC421307669	GAVIC419691603	AUTO
GAVIC421307669	GAVIC420607415	AUTO
GAVIC421307669	GAVIC421779026	AUTO
GAVIC423911067	GAVIC423766105	AUTO
GAVIC423911067	GAVIC423807226	AUTO
GAVIC423911067	GAVIC423807233	AUTO
GAVIC423911067	GAVIC423807239	AUTO
GAVIC423911067	GAVIC423910324	AUTO
GAVIC421756773	GAVIC421424022	AUTO
GAVIC421756773	GAVIC419620881	AUTO
GAVIC421756773	GAVIC420230880	AUTO
GAVIC421756773	GAVIC420534388	AUTO
GAVIC421756773	GAVIC421764508	AUTO
GAVIC423911067	GAVIC423910981	AUTO
GAVIC423911067	GAVIC423910983	AUTO
GAVIC423911067	GAVIC423910984	AUTO
GAVIC423911067	GAVIC423910985	AUTO
GAVIC423911067	GAVIC423910995	AUTO
GAVIC423911067	GAVIC423910996	AUTO
GAVIC423911067	GAVIC423910998	AUTO
GAVIC423911067	GAVIC423911001	AUTO
GAVIC423911067	GAVIC423931406	AUTO
GAVIC419661586	GAVIC412033660	AUTO
GAVIC423911067	GAVIC423910592	AUTO
GAVIC421756773	GAVIC420209393	AUTO
GAVIC421731563	GAVIC721382287	AUTO
GAVIC420504897	GAVIC413349603	AUTO
GAVIC421756773	GAVIC423851222	AUTO
GAVIC421756773	GAVIC419935764	AUTO
GAVIC421756773	GAVIC420209388	AUTO
GAVIC421756773	GAVIC420209391	AUTO
GAVIC421756773	GAVIC420209395	AUTO
GAVIC421756773	GAVIC420210360	AUTO
GAVIC421756773	GAVIC420212040	AUTO
GAVIC421756773	GAVIC420221083	AUTO
GAVIC421756773	GAVIC420221087	AUTO
GAVIC421756773	GAVIC420227306	AUTO
GAVIC421756773	GAVIC420228150	AUTO
GAVIC421756773	GAVIC420228153	AUTO
GAVIC421756773	GAVIC420523792	AUTO
GAVIC421756773	GAVIC420523796	AUTO
GAVIC421756773	GAVIC420523800	AUTO
GAVIC421756773	GAVIC420824529	AUTO
GAVIC421756773	GAVIC420824533	AUTO
GAVIC421756773	GAVIC420834599	AUTO
GAVIC421756773	GAVIC423161236	AUTO
GAVIC421307669	GAVIC421779027	AUTO
GAVIC423911067	GAVIC423910734	AUTO
GAVIC422119571	GAVIC411034089	AUTO
GAVIC419645242	GAVIC421989642	AUTO
GAVIC423911067	GAVIC423911007	AUTO
GAVIC423911067	GAVIC423910504	AUTO
GAVIC423911067	GAVIC423910737	AUTO
GAVIC420949509	GAVIC412650597	AUTO
GAVIC420504897	GAVIC420596732	AUTO
GAVIC423911067	GAVIC423910600	AUTO
GAVIC421736429	GAVIC721107179	AUTO
GAVIC421448648	GAVIC420828143	AUTO
GAVIC420100287	GAVIC420017315	AUTO
GAVIC423911067	GAVIC423910327	AUTO
GAVIC423911067	GAVIC423807232	AUTO
GAVIC423911067	GAVIC423807235	AUTO
GAVIC423911067	GAVIC423807237	AUTO
GAVIC423911067	GAVIC423807238	AUTO
GAVIC423911067	GAVIC423807241	AUTO
GAVIC423911067	GAVIC423807244	AUTO
GAVIC423911067	GAVIC423850555	AUTO
GAVIC423911067	GAVIC423850557	AUTO
GAVIC423911067	GAVIC423850559	AUTO
GAVIC423911067	GAVIC423850561	AUTO
GAVIC423911067	GAVIC423850564	AUTO
GAVIC423911067	GAVIC423850565	AUTO
GAVIC423911067	GAVIC423850567	AUTO
GAVIC423911067	GAVIC423850568	AUTO
GAVIC423911067	GAVIC423905289	AUTO
GAVIC423911067	GAVIC423905290	AUTO
GAVIC423911067	GAVIC423905292	AUTO
GAVIC423911067	GAVIC423905293	AUTO
GAVIC423911067	GAVIC423905297	AUTO
GAVIC421109751	GAVIC721609962	AUTO
GAVIC423911067	GAVIC423910425	AUTO
GAVIC423911067	GAVIC423910308	AUTO
GAVIC422119571	GAVIC411038901	AUTO
GAVIC423911067	GAVIC423910307	AUTO
GAVIC423911067	GAVIC423905287	AUTO
GAVIC419661586	GAVIC412038629	AUTO
GAVIC419987098	GAVIC411503214	AUTO
GAVIC419987098	GAVIC411517384	AUTO
GAVIC423911067	GAVIC423910847	AUTO
GAVIC421756773	GAVIC425801395	AUTO
GAVIC423911067	GAVIC423910959	AUTO
GAVIC423911067	GAVIC423910385	AUTO
GAVIC423911067	GAVIC423910978	AUTO
GAVIC424777831	GAVIC424671695	AUTO
GAVIC421756773	GAVIC421134502	AUTO
GAVIC421756773	GAVIC421424024	AUTO
GAVIC423911067	GAVIC423910644	AUTO
GAVIC420749468	GAVIC720127515	AUTO
GAVIC420749468	GAVIC720131203	AUTO
GAVIC420749468	GAVIC720133374	AUTO
GAVIC420749468	GAVIC720135822	AUTO
GAVIC423911067	GAVIC423910815	AUTO
GAVIC423911067	GAVIC423910635	AUTO
GAVIC421756773	GAVIC420209389	AUTO
GAVIC423911067	GAVIC423910507	AUTO
GAVIC423911067	GAVIC423910518	AUTO
GAVIC423911067	GAVIC423910610	AUTO
GAVIC423911067	GAVIC423910639	AUTO
GAVIC423911067	GAVIC423910449	AUTO
GAVIC421307669	GAVIC421518311	AUTO
GAVIC422035533	GAVIC420480009	AUTO
GAVIC423911067	GAVIC423905294	AUTO
GAVIC421109751	GAVIC721611223	AUTO
GAVIC419920752	GAVIC423821926	AUTO
GAVIC419920752	GAVIC423821927	AUTO
GAVIC423911067	GAVIC423910505	AUTO
GAVIC423911067	GAVIC423910745	AUTO
GAVIC423911067	GAVIC423910751	AUTO
GAVIC423911067	GAVIC423910756	AUTO
GAVIC423911067	GAVIC423910767	AUTO
GAVIC423911067	GAVIC423910773	AUTO
GAVIC423911067	GAVIC423910778	AUTO
GAVIC423911067	GAVIC423910784	AUTO
GAVIC423911067	GAVIC423910790	AUTO
GAVIC423911067	GAVIC423910801	AUTO
GAVIC423911067	GAVIC423910806	AUTO
GAVIC423911067	GAVIC423910812	AUTO
GAVIC423911067	GAVIC423910817	AUTO
GAVIC423911067	GAVIC423910822	AUTO
GAVIC423911067	GAVIC423910840	AUTO
GAVIC423911067	GAVIC423910849	AUTO
GAVIC420757091	GAVIC419865075	AUTO
GAVIC414839745	GAVIC421100726	MANUAL
GAVIC420504897	GAVIC413350267	AUTO
GAVIC420504897	GAVIC413345029	AUTO
GAVIC421756773	GAVIC420834603	AUTO
GAVIC423911067	GAVIC423910611	AUTO
GAVIC423911067	GAVIC423910654	AUTO
GAVIC423911067	GAVIC423905298	AUTO
GAVIC423911067	GAVIC423910316	AUTO
GAVIC423911067	GAVIC423910328	AUTO
GAVIC423911067	GAVIC423910364	AUTO
GAVIC419811494	GAVIC721255977	AUTO
GAVIC425511946	GAVIC425511928	AUTO
GAVIC425511946	GAVIC425511934	AUTO
GAVIC423911067	GAVIC423910602	AUTO
GAVIC421826494	GAVIC423090751	AUTO
GAVIC421756773	GAVIC419607462	AUTO
GAVIC421756773	GAVIC419620874	AUTO
GAVIC423911067	GAVIC423910655	AUTO
GAVIC423911067	GAVIC423910664	AUTO
GAVIC423911067	GAVIC423910685	AUTO
GAVIC423911067	GAVIC423910695	AUTO
GAVIC423911067	GAVIC423910703	AUTO
GAVIC423911067	GAVIC423910713	AUTO
GAVIC423911067	GAVIC423910633	AUTO
GAVIC423911067	GAVIC423910846	AUTO
GAVIC423911067	GAVIC423910874	AUTO
GAVIC423911067	GAVIC423910899	AUTO
GAVIC423911067	GAVIC423910924	AUTO
GAVIC423911067	GAVIC423910953	AUTO
GAVIC421756773	GAVIC421424020	AUTO
GAVIC421756773	GAVIC421424016	AUTO
GAVIC421756773	GAVIC419925093	AUTO
GAVIC423911067	GAVIC423911010	AUTO
GAVIC421756773	GAVIC419925099	AUTO
GAVIC421307669	GAVIC419691604	AUTO
GAVIC421307669	GAVIC420595946	AUTO
GAVIC421307669	GAVIC421779028	AUTO
GAVIC421307669	GAVIC421779029	AUTO
GAVIC420099787	GAVIC424446948	AUTO
GAVIC420099787	GAVIC424446949	AUTO
GAVIC420099787	GAVIC424446950	AUTO
GAVIC420099787	GAVIC424446951	AUTO
GAVIC421756773	GAVIC419925098	AUTO
GAVIC423911067	GAVIC423910643	AUTO
GAVIC421756773	GAVIC421120587	AUTO
GAVIC420178764	GAVIC423770817	AUTO
GAVIC420178764	GAVIC423770818	AUTO
GAVIC423911067	GAVIC423910632	AUTO
GAVIC421736429	GAVIC721106813	AUTO
GAVIC423911067	GAVIC423910844	AUTO
GAVIC421756773	GAVIC421134498	AUTO
GAVIC423911067	GAVIC423910320	AUTO
GAVIC423911067	GAVIC423910907	AUTO
GAVIC423911067	GAVIC423910381	AUTO
GAVIC424754823	GAVIC424754822	MANUAL
GAVIC420674743	GAVIC412252849	AUTO
GAVIC423911067	GAVIC423910835	AUTO
GAVIC421448648	GAVIC420828142	AUTO
GAVIC423911067	GAVIC423910595	AUTO
GAVIC423911067	GAVIC423910608	AUTO
GAVIC423911067	GAVIC423910879	AUTO
GAVIC423911067	GAVIC423910754	AUTO
GAVIC423911067	GAVIC423910839	AUTO
GAVIC423911067	GAVIC423910331	AUTO
GAVIC420504897	GAVIC420497782	AUTO
GAVIC423911067	GAVIC423910736	AUTO
GAVIC423911067	GAVIC423910810	AUTO
GAVIC423911067	GAVIC423910819	AUTO
GAVIC423911067	GAVIC423910843	AUTO
GAVIC423911067	GAVIC423910451	AUTO
GAVIC423911067	GAVIC423910511	AUTO
GAVIC421307669	GAVIC421180175	AUTO
GAVIC423911067	GAVIC423911000	AUTO
GAVIC419676903	GAVIC425077940	AUTO
GAVIC419676903	GAVIC425077941	AUTO
GAVIC419676903	GAVIC425077942	AUTO
GAVIC420757091	GAVIC410989504	AUTO
GAVIC423911067	GAVIC423766104	AUTO
GAVIC423911067	GAVIC423766106	AUTO
GAVIC423911067	GAVIC423807223	AUTO
GAVIC423911067	GAVIC423807225	AUTO
GAVIC421731563	GAVIC721328440	AUTO
GAVIC419811494	GAVIC721255057	AUTO
GAVIC419811494	GAVIC721256570	AUTO
GAVIC419811494	GAVIC721256747	AUTO
GAVIC422161681	GAVIC411026932	AUTO
GAVIC422161681	GAVIC411044203	AUTO
GAVIC422161681	GAVIC420956451	AUTO
GAVIC420796526	GAVIC424073770	AUTO
GAVIC420796526	GAVIC424073771	AUTO
GAVIC421756773	GAVIC419607420	AUTO
GAVIC420757091	GAVIC410983036	AUTO
GAVIC423911067	GAVIC423910351	AUTO
GAVIC423911067	GAVIC423910824	AUTO
GAVIC423911067	GAVIC423910319	AUTO
GAVIC423911067	GAVIC423910731	AUTO
GAVIC421448648	GAVIC421768592	AUTO
GAVIC412227164	GAVIC412221049	AUTO
GAVIC421481958	GAVIC410753282	AUTO
GAVIC421481958	GAVIC410762327	AUTO
GAVIC423911067	GAVIC721187591	AUTO
GAVIC419912498	GAVIC425666826	AUTO
GAVIC421756773	GAVIC420209397	AUTO
GAVIC423911067	GAVIC423910651	AUTO
GAVIC423911067	GAVIC423910960	AUTO
GAVIC423911067	GAVIC423910337	AUTO
GAVIC423935363	GAVIC721702269	MANUAL
GAVIC413630613	GAVIC421194638	AUTO
GAVIC420647207	GAVIC422193110	AUTO
GAVIC423911067	GAVIC423910380	AUTO
GAVIC423911067	GAVIC423910729	AUTO
GAVIC423911067	GAVIC423910735	AUTO
GAVIC423911067	GAVIC423910740	AUTO
GAVIC420504897	GAVIC420303375	AUTO
GAVIC421756773	GAVIC420228149	AUTO
GAVIC421756773	GAVIC420228155	AUTO
GAVIC423911067	GAVIC423910855	AUTO
GAVIC419645242	GAVIC421989641	AUTO
GAVIC421756773	GAVIC420834601	AUTO
GAVIC420674743	GAVIC412269805	AUTO
GAVIC420504897	GAVIC413349600	AUTO
GAVIC424777831	GAVIC424671696	AUTO
\.

-- gnaf_202602.address_principal_admin_boundaries: 451 rows
\copy gnaf_202602.address_principal_admin_boundaries FROM stdin
638721	GAVIC423917985	loc9a48431374e1	PORT MELBOURNE	3207	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad0yeVgdkzJlKJ	Port Melbourne Ward	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
46354	GAVIC421107468	loce42a110faa48	HAMPTON	3188	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad4c653401ab5d	Castlefield Ward	VIC364	BRIGHTON	VIC394	SOUTHERN METROPOLITAN
1272475	GAVIC419920752	loc2c4c767ea9b7	PRESTON	3072	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wad8f5a9db3d21b	Central Ward	VIC326	NORTHCOTE	VIC398	NORTHERN METROPOLITAN
2084573	GAVIC425167658	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
1306789	GAVIC721366499	loca5de38b84720	BOX HILL	3128	VIC	VIC76	MENZIES	lga0450031d71ce	Whitehorse	wad5935a963ef9d	Sparks Ward	VIC363	BOX HILL	VIC397	NORTH-EASTERN METROPOLITAN
2289039	GAVIC421548655	locb53ace4ff1b6	GREAT WESTERN	3374	VIC	VIC72	MALLEE	lga8751f70e5df3	Northern Grampians	wadGYBvJj6CPTEz	Grampians Ward	VIC308	LOWAN	VIC399	WESTERN VICTORIA
2326877	GAVIC719925941	loc3319215a0a10	BRIGHTON	3186	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad828d750c07c7	Bleazby Ward	VIC364	BRIGHTON	VIC394	SOUTHERN METROPOLITAN
2836362	GAVIC718991138	loca0398a35cf5e	CARLTON	3053	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3235356	GAVIC424750944	loc338a35dd09f0	GOLDEN SQUARE	3555	VIC	VIC46	BENDIGO	lga575ae7e97596	Greater Bendigo	wadFmg_w4Q0SKqU	Golden Square Ward	VIC360	BENDIGO WEST	VIC392	NORTHERN VICTORIA
2839348	GAVIC420583086	loc39cd317eec9d	CLARINDA	3169	VIC	VIC64	HOTHAM	lga691f580f3258	Kingston	wad2082444c3373	Bunjil Ward	VIC371	CLARINDA	VIC393	SOUTH-EASTERN METROPOLITAN
3465511	GAVIC423974946	loca37d9a7b347e	KIMBOLTON	3551	VIC	VIC46	BENDIGO	lga575ae7e97596	Greater Bendigo	wad57319f4584c9	Eppalock Ward	VIC379	EUROA	VIC392	NORTHERN VICTORIA
2856358	GAVIC421694057	loc92bf5bc798e7	FLEMINGTON	3031	VIC	VIC73	MARIBYRNONG	lga638d2708b9ab	Moonee Valley	wad80623869e39d	Myrnong Ward	VIC377	ESSENDON	VIC398	NORTHERN METROPOLITAN
862502	GAVIC419661586	loce1597eda1cc3	NORLANE	3214	VIC	VIC53	CORIO	lga227fb535494c	Greater Geelong	wadXxYaTgrTcF_X	Corio Ward	VIC306	LARA	VIC399	WESTERN VICTORIA
3528143	GAVIC425169775	loce11f06c54f46	GISBORNE	3437	VIC	VIC74	MCEWEN	lgaa61a81fb4118	Macedon Ranges	wad448ce116b942	South Ward	VIC309	MACEDON	VIC392	NORTHERN VICTORIA
3543712	GAVIC420701723	locbd7d4fd6b9e7	COBURG	3058	VIC	VIC81	WILLS	lgaJ2LPN2y4pll0	Merri-Bek	wadwzZNpXX3lEX6	Pentridge Ward	VIC330	PASCOE VALE	VIC398	NORTHERN METROPOLITAN
228270	GAVIC421146125	loc8fef59c1c585	TULLAMARINE	3043	VIC	VIC73	MARIBYRNONG	lga3476c1d9fd7f	Hume	wadUUqYuS9FIlUf	Tullamarine Ward	VIC344	SUNBURY	VIC395	WESTERN METROPOLITAN
2006422	GAVIC424795446	locc2ea2de6af6c	SOUTH YARRA	3141	VIC	VIC75	MELBOURNE	lgae1dcbacb8510	Stonnington	wadSdQj5ZcEpUYw	Como Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
3478557	GAVIC719754089	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3626897	GAVIC423402710	loc47e9d5554e9d	HAZELWOOD	3840	VIC	VIC59	GIPPSLAND	lga5e8f0b6a35b1	Latrobe	wadLf4uPgHBqUsk	Morwell River Ward	VIC318	MORWELL	VIC396	EASTERN VICTORIA
3692544	GAVIC719042751	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3026929	GAVIC720296037	locffd0eebac0eb	CHELSEA	3196	VIC	VIC66	ISAACS	lga691f580f3258	Kingston	wad253892513dc2	Sandpiper Ward	VIC316	MORDIALLOC	VIC393	SOUTH-EASTERN METROPOLITAN
2978880	GAVIC425367645	loce25dfc481765	KILMORE	3764	VIC	VIC78	NICHOLLS	lgaae260494d80c	Mitchell	wad8c29bdb30e60	Central Ward	VIC379	EUROA	VIC392	NORTHERN VICTORIA
3244701	GAVIC719913128	loc1492a23dbc74	HEIDELBERG WEST	3081	VIC	VIC67	JAGAJAGA	lga5591321694d6	Banyule	wada6a3e547acbc	Olympia Ward	VIC390	IVANHOE	VIC397	NORTH-EASTERN METROPOLITAN
2936016	GAVIC419688276	loc3b64e6146ff8	MORDIALLOC	3195	VIC	VIC66	ISAACS	lga691f580f3258	Kingston	wad4b7424fe2c1a	Melaleuca Ward	VIC316	MORDIALLOC	VIC393	SOUTH-EASTERN METROPOLITAN
1643080	GAVIC412670644	locf3eb6fff8056	OXLEY	3678	VIC	VIC65	INDI	lgabff52ad8fdf9	Wangaratta	wadArdtLcXM18QM	King River Ward	VIC328	OVENS VALLEY	VIC392	NORTHERN VICTORIA
3800288	GAVIC424926818	loc399d9bd46679	TYLDEN	3444	VIC	VIC46	BENDIGO	lgaa61a81fb4118	Macedon Ranges	wada1e81dc1a459	West Ward	VIC309	MACEDON	VIC392	NORTHERN VICTORIA
2904060	GAVIC425821887	loc4858bcc1d912	GLENROY	3046	VIC	VIC73	MARIBYRNONG	lgaJ2LPN2y4pll0	Merri-Bek	wad10bOEnGsV8dy	Djirri-Djirri Ward	VIC365	BROADMEADOWS	VIC398	NORTHERN METROPOLITAN
1966573	GAVIC719523562	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
647656	GAVIC719439819	locfa38377aaf29	DEDERANG	3691	VIC	VIC65	INDI	lga136d886cbd2c	Alpine	wad9ff7d2981028	Alpine Shire	VIC328	OVENS VALLEY	VIC392	NORTHERN VICTORIA
573388	GAVIC424754823	locbf553ce41d73	KIRWANS BRIDGE	3608	VIC	VIC78	NICHOLLS	lga7831afcaf1e2	Strathbogie	wado4SJap0btdNC	Strathbogie Shire	VIC379	EUROA	VIC392	NORTHERN VICTORIA
2824676	GAVIC420418242	loc712bc92c5924	BUNDOORA	3083	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wad9576ecab049a	North East Ward	VIC368	BUNDOORA	VIC397	NORTH-EASTERN METROPOLITAN
2151913	GAVIC424581128	loccd13bd88b567	FERNTREE GULLY	3156	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wadfde0a79062c6	Friberg Ward	VIC356	BAYSWATER	VIC397	NORTH-EASTERN METROPOLITAN
2473092	GAVIC425085888	loc82baa1179308	PAKENHAM	3810	VIC	VIC69	LA TROBE	lgac69cfd288672	Cardinia	wadce0c3a80bf85	Pakenham Hills Ward	VIC329	PAKENHAM	VIC396	EASTERN VICTORIA
1437727	GAVIC419682437	loca2fd80ef71d3	DEREEL	3352	VIC	VIC45	BALLARAT	lgaca1dd9cec0f0	Golden Plains	wad23832134f3e4	Golden Plains Shire	VIC378	EUREKA	VIC399	WESTERN VICTORIA
1377853	GAVIC412378116	locfe955a87410d	ST KILDA	3182	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad49OyljM8Of_R	St Kilda Ward	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
2336438	GAVIC421304891	locd755ccb7197e	DANDENONG NORTH	3175	VIC	VIC47	BRUCE	lgab65bc8ec7820	Greater Dandenong	wad89dbd0afc658	Cleeland Ward	VIC374	DANDENONG	VIC393	SOUTH-EASTERN METROPOLITAN
1974546	GAVIC720913095	locc672a234fa5a	LORNE	3232	VIC	VIC80	WANNON	lgaeb9321b0357b	Surf Coast	wadFESQVKEsPDOS	Otway Range Ward	VIC332	POLWARTH	VIC399	WESTERN VICTORIA
957610	GAVIC419854308	loc7f158a48110c	BLAIRGOWRIE	3942	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	wad869d0407f3ba	Nepean Ward	VIC324	NEPEAN	VIC396	EASTERN VICTORIA
1066975	GAVIC721374676	loc5c27e3f22fc1	HAWTHORN	3122	VIC	VIC68	KOOYONG	lga0930e8ebad68	Boroondara	wadb5ad118a1aa8	Riversdale Ward	VIC389	HAWTHORN	VIC394	SOUTHERN METROPOLITAN
3340551	GAVIC411968423	loce01ddbd8c8e5	NAGAMBIE	3608	VIC	VIC78	NICHOLLS	lga7831afcaf1e2	Strathbogie	wado4SJap0btdNC	Strathbogie Shire	VIC379	EUROA	VIC392	NORTHERN VICTORIA
3144962	GAVIC422161681	loc913bf4728c4e	CAMBERWELL	3124	VIC	VIC68	KOOYONG	lga0930e8ebad68	Boroondara	wade92eddaadf67	Junction Ward	VIC389	HAWTHORN	VIC394	SOUTHERN METROPOLITAN
3445467	GAVIC425742442	loc780d4ed4ca46	HAMLYN HEIGHTS	3215	VIC	VIC53	CORIO	lga227fb535494c	Greater Geelong	wadhYtowwOuh5RV	Hamlyn Heights Ward	VIC306	LARA	VIC399	WESTERN VICTORIA
2365327	GAVIC425309480	loc656f84726510	RESERVOIR	3073	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wade6b6cc7ad2db	North Central Ward	VIC334	PRESTON	VIC398	NORTHERN METROPOLITAN
578256	GAVIC424285382	loc11b2a92fb5f0	BRUNSWICK WEST	3055	VIC	VIC73	MARIBYRNONG	lgaJ2LPN2y4pll0	Merri-Bek	wadLMZRg2myfctY	Brunswick West Ward	VIC330	PASCOE VALE	VIC398	NORTHERN METROPOLITAN
1431830	GAVIC422086500	loc34a55c4d0462	ST ALBANS	3021	VIC	VIC57	FRASER	lgaf76bb579e827	Brimbank	waddvaYKG49r0Rf	St Albans East Ward	VIC343	ST ALBANS	VIC395	WESTERN METROPOLITAN
2386269	GAVIC421708673	loc46443686a430	SUNSHINE WEST	3020	VIC	VIC57	FRASER	lgaf76bb579e827	Brimbank	wadwhtAgHxBhzif	Kororoit Creek Ward	VIC307	LAVERTON	VIC395	WESTERN METROPOLITAN
1753990	GAVIC420886416	loc1fbfb471eb7c	ROMSEY	3434	VIC	VIC74	MCEWEN	lgaa61a81fb4118	Macedon Ranges	wada0c2d176c7b8	East Ward	VIC309	MACEDON	VIC392	NORTHERN VICTORIA
1488882	GAVIC421739766	loc656f84726510	RESERVOIR	3073	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wade6b6cc7ad2db	North Central Ward	VIC334	PRESTON	VIC398	NORTHERN METROPOLITAN
3530581	GAVIC422138212	loc82b861dfb765	THORNBURY	3071	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wade68903703ea0	South West Ward	VIC326	NORTHCOTE	VIC398	NORTHERN METROPOLITAN
2491954	GAVIC420051005	loc6413994c2b24	FRANKSTON	3199	VIC	VIC55	DUNKLEY	lgadd7fe82edc77	Frankston	wadYcbqjXzvzeHZ	Kananook Ward	VIC382	FRANKSTON	VIC393	SOUTH-EASTERN METROPOLITAN
669892	GAVIC419679289	locd6f79866f950	KNOXFIELD	3180	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wadfde0a79062c6	Friberg Ward	VIC338	ROWVILLE	VIC393	SOUTH-EASTERN METROPOLITAN
1173375	GAVIC425367514	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
2976924	GAVIC422119571	loc913bf4728c4e	CAMBERWELL	3124	VIC	VIC50	CHISHOLM	lga0930e8ebad68	Boroondara	wada3ca41faf88e	Lynden Ward	VIC389	HAWTHORN	VIC394	SOUTHERN METROPOLITAN
1474534	GAVIC420118258	loc6ae7eaa3c1f3	BOX HILL SOUTH	3128	VIC	VIC76	MENZIES	lga0450031d71ce	Whitehorse	wada5e70a2a8728	Wattle Ward	VIC363	BOX HILL	VIC397	NORTH-EASTERN METROPOLITAN
3526957	GAVIC423910455	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wadyBOUDailkzZ2	South Melbourne Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
1738945	GAVIC424589454	locc5abea08e85d	POINT COOK	3030	VIC	VIC58	GELLIBRAND	lga53026dafea91	Wyndham	wad8Xd3NHzIUcZi	Cheetham Ward	VIC331	POINT COOK	VIC395	WESTERN METROPOLITAN
341083	GAVIC721038984	loc956fa85c7b0c	PORTARLINGTON	3223	VIC	VIC52	CORANGAMITE	lga227fb535494c	Greater Geelong	wadzqyNP4wsaqEj	Murradoc Ward	VIC357	BELLARINE	VIC399	WESTERN VICTORIA
2056479	GAVIC720284643	loc098e933e1fd2	GROVEDALE	3216	VIC	VIC52	CORANGAMITE	lga227fb535494c	Greater Geelong	wadbEmlHutlbaow	Charlemont Ward	VIC341	SOUTH BARWON	VIC399	WESTERN VICTORIA
415815	GAVIC423716042	locc098f71b2faf	SOLDIERS HILL	3350	VIC	VIC45	BALLARAT	lgab70a9914e5bc	Ballarat	wad56152dcfe8bc	Central Ward	VIC349	WENDOUREE	VIC399	WESTERN VICTORIA
1728586	GAVIC423490030	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
757773	GAVIC721290639	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
549719	GAVIC423648868	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
384334	GAVIC420533207	loc7ab22202aac3	DONCASTER	3108	VIC	VIC76	MENZIES	lgab3be0b9eb31a	Manningham	wad3600de311f72	Ruffey Ward	VIC367	BULLEEN	VIC397	NORTH-EASTERN METROPOLITAN
2944407	GAVIC720520900	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
523665	GAVIC425311495	locc605118e951a	WALLAN	3756	VIC	VIC74	MCEWEN	lgaae260494d80c	Mitchell	wad9ac23ae23a13	South Ward	VIC391	KALKALLO	VIC398	NORTHERN METROPOLITAN
3506096	GAVIC420178764	loc786911d8fa57	BLACKBURN NORTH	3130	VIC	VIC76	MENZIES	lga0450031d71ce	Whitehorse	wad615c37be4236	Cootamundra Ward	VIC363	BOX HILL	VIC397	NORTH-EASTERN METROPOLITAN
2960489	GAVIC425741622	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
2482980	GAVIC423402509	loc0e534d470df9	HEATHCOTE	3523	VIC	VIC46	BENDIGO	lga575ae7e97596	Greater Bendigo	wad57319f4584c9	Eppalock Ward	VIC379	EUROA	VIC392	NORTHERN VICTORIA
2583756	GAVIC424879721	loc5100fc96abff	MOUNT MARTHA	3934	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	wade277c1992c30	Briars Ward	VIC317	MORNINGTON	VIC396	EASTERN VICTORIA
1306924	GAVIC424785567	loc29841cc6d6f1	BROOKFIELD	3338	VIC	VIC62	HAWKE	lga42b2fd54c1e9	Melton	wad9p56oRmceP46	Cambrian Ward	VIC312	MELTON	VIC399	WESTERN VICTORIA
2356918	GAVIC420538231	loc2c9ce0acd6de	ST LEONARDS	3223	VIC	VIC52	CORANGAMITE	lga227fb535494c	Greater Geelong	wadzqyNP4wsaqEj	Murradoc Ward	VIC357	BELLARINE	VIC399	WESTERN VICTORIA
702293	GAVIC419754099	loc62ed665318da	KYABRAM	3620	VIC	VIC78	NICHOLLS	lgaf4d7671cd990	Campaspe	wad-_EZ61IArian	Campaspe Shire	VIC320	MURRAY PLAINS	VIC392	NORTHERN VICTORIA
2230947	GAVIC423943682	locf065e41cfac9	TAYLORS LAKES	3038	VIC	VIC61	GORTON	lgaf76bb579e827	Brimbank	wadK-IbQ32f8QSj	Copernicus Ward	VIC345	SYDENHAM	VIC395	WESTERN METROPOLITAN
730181	GAVIC424676885	locc586266ef8cc	SALE	3850	VIC	VIC59	GIPPSLAND	lga4d167b5c075b	Wellington	wadd44e8a9553ef	Central Ward	VIC385	GIPPSLAND SOUTH	VIC396	EASTERN VICTORIA
3770492	GAVIC423509973	loc46b3ff1e6b9a	VERMONT	3133	VIC	VIC54	DEAKIN	lga0450031d71ce	Whitehorse	wadd0905f6cad1b	Simpson Ward	VIC386	GLEN WAVERLEY	VIC397	NORTH-EASTERN METROPOLITAN
1936961	GAVIC721504260	locf16910f90fb9	HIGHETT	3190	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wadd9f02c005f7c	Ivison Ward	VIC339	SANDRINGHAM	VIC394	SOUTHERN METROPOLITAN
955601	GAVIC423748775	loc17a18f5ff3a6	CAROLINE SPRINGS	3023	VIC	VIC61	GORTON	lga42b2fd54c1e9	Melton	wadCgMjDLgIjm3M	Sugar Gum Ward	VIC345	SYDENHAM	VIC395	WESTERN METROPOLITAN
605283	GAVIC420674743	locc586266ef8cc	SALE	3850	VIC	VIC59	GIPPSLAND	lga4d167b5c075b	Wellington	wadd44e8a9553ef	Central Ward	VIC385	GIPPSLAND SOUTH	VIC396	EASTERN VICTORIA
2737566	GAVIC411087566	loc1b5a0e70afd4	CAULFIELD SOUTH	3162	VIC	VIC60	GOLDSTEIN	lga9bd137c30d17	Glen Eira	wadCWc1YCoAd-4T	Bambra Ward	VIC370	CAULFIELD	VIC394	SOUTHERN METROPOLITAN
2578385	GAVIC425512108	loc0b8afd71fce1	WEST MELBOURNE	3003	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
1514569	GAVIC420648830	loc2508c9e5a93c	RIDDELLS CREEK	3431	VIC	VIC74	MCEWEN	lgaa61a81fb4118	Macedon Ranges	wada0c2d176c7b8	East Ward	VIC309	MACEDON	VIC392	NORTHERN VICTORIA
1475994	GAVIC420870124	loc94fdc21035b3	ULTIMA	3544	VIC	VIC72	MALLEE	lga2f887f3655b9	Swan Hill	wad06be12aa2c37	Swan Hill Rural City	VIC320	MURRAY PLAINS	VIC392	NORTHERN VICTORIA
203164	GAVIC719921421	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
3733778	GAVIC422024006	loc76dea039b41f	MALVERN	3144	VIC	VIC68	KOOYONG	lgae1dcbacb8510	Stonnington	wadXdFA1Wq5yoqK	Tooronga Ward	VIC310	MALVERN	VIC394	SOUTHERN METROPOLITAN
1641107	GAVIC424282372	loceac5d85ea01d	WYNDHAM VALE	3024	VIC	VIC70	LALOR	lga53026dafea91	Wyndham	wad5MfwywcyKQtC	Quandong Ward	VIC350	WERRIBEE	VIC395	WESTERN METROPOLITAN
3232098	GAVIC721915145	locf2d2a267a354	WINCHELSEA	3241	VIC	VIC80	WANNON	lgaeb9321b0357b	Surf Coast	wad19afb15ebd49	Winchelsea Ward	VIC332	POLWARTH	VIC399	WESTERN VICTORIA
3278909	GAVIC421481149	loc656f84726510	RESERVOIR	3073	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wade6b6cc7ad2db	North Central Ward	VIC334	PRESTON	VIC398	NORTHERN METROPOLITAN
1467719	GAVIC420108368	loc7a8164839d54	DONCASTER EAST	3109	VIC	VIC76	MENZIES	lgab3be0b9eb31a	Manningham	wad00ce24084fec	Waldau Ward	VIC348	WARRANDYTE	VIC397	NORTH-EASTERN METROPOLITAN
276752	GAVIC719528632	loc1b271c01e3dc	MICKLEHAM	3064	VIC	VIC48	CALWELL	lga3476c1d9fd7f	Hume	wadVD09aRdeVUF4	Yubup Ward	VIC391	KALKALLO	VIC398	NORTHERN METROPOLITAN
615810	GAVIC424895492	locb48ce003b11e	MARONG	3515	VIC	VIC46	BENDIGO	lga575ae7e97596	Greater Bendigo	wada683dc47ff30	Lockwood Ward	VIC360	BENDIGO WEST	VIC392	NORTHERN VICTORIA
613540	GAVIC420323810	locadc5cabaa80e	GLEN IRIS	3146	VIC	VIC50	CHISHOLM	lgae1dcbacb8510	Stonnington	wadXdFA1Wq5yoqK	Tooronga Ward	VIC310	MALVERN	VIC394	SOUTHERN METROPOLITAN
468144	GAVIC423910551	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wadyBOUDailkzZ2	South Melbourne Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
242642	GAVIC421042152	loc7c934a667999	HASTINGS	3915	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	wadNV0rYNZ9D2Q2	Warringine Ward	VIC388	HASTINGS	VIC396	EASTERN VICTORIA
3197718	GAVIC425277959	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
2788114	GAVIC419640745	loc0a03ed3531fd	CHELTENHAM	3192	VIC	VIC66	ISAACS	lga691f580f3258	Kingston	wad55ea8956cf9d	Karkarook Ward	VIC361	BENTLEIGH	VIC394	SOUTHERN METROPOLITAN
3325443	GAVIC425013948	loc2d817b7080e2	MALVERN EAST	3145	VIC	VIC50	CHISHOLM	lgae1dcbacb8510	Stonnington	wad4GOUAzunjtQ3	Hedgeley Dene Ward	VIC310	MALVERN	VIC394	SOUTHERN METROPOLITAN
61000	GAVIC720523963	loc64c822b0bad5	OFFICER	3809	VIC	VIC69	LA TROBE	lgac69cfd288672	Cardinia	wadd2cf225a1e5c	Toomuc Ward	VIC329	PAKENHAM	VIC396	EASTERN VICTORIA
3364426	GAVIC425820590	loc656f84726510	RESERVOIR	3073	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wadaaf7b81c6267	North West Ward	VIC334	PRESTON	VIC398	NORTHERN METROPOLITAN
3820926	GAVIC721425406	loce16236caf708	LARA	3212	VIC	VIC53	CORIO	lga227fb535494c	Greater Geelong	wadzWnDzRGqmtuN	You Yangs Ward	VIC306	LARA	VIC399	WESTERN VICTORIA
2306002	GAVIC423991217	loc532c3dac4248	WALMER	3463	VIC	VIC46	BENDIGO	lga0eac1885ea16	Mount Alexander	wada8d157a920f8	Calder Ward	VIC360	BENDIGO WEST	VIC392	NORTHERN VICTORIA
3391798	GAVIC721549117	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3177948	GAVIC420749468	locc81a6ec90a1b	ROSEBUD	3939	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	wad7dxsK5rEAxTh	Benbenjie Ward	VIC324	NEPEAN	VIC396	EASTERN VICTORIA
2175158	GAVIC721162609	locfd8472c41cbe	ROWVILLE	3178	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wadeaa4b13b2374	Tirhatuan Ward	VIC338	ROWVILLE	VIC393	SOUTH-EASTERN METROPOLITAN
3788090	GAVIC422289520	loc8f498b475ec6	TRARALGON EAST	3844	VIC	VIC59	GIPPSLAND	lga5e8f0b6a35b1	Latrobe	wadi_iIuZAP6zAv	Loy Yang Ward	VIC318	MORWELL	VIC396	EASTERN VICTORIA
3663423	GAVIC421059470	loc37efd432abe4	WANTIRNA SOUTH	3152	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wadcfea20d05544	Collier Ward	VIC338	ROWVILLE	VIC393	SOUTH-EASTERN METROPOLITAN
2218566	GAVIC420100287	loca1b6ce72e35a	MOUNT WAVERLEY	3149	VIC	VIC50	CHISHOLM	lga15c9c80d4be7	Monash	wadB4dkXVU1StzL	Scotchmans Creek Ward	VIC354	ASHWOOD	VIC394	SOUTHERN METROPOLITAN
150304	GAVIC425774710	loce48c38ae2d6a	RICHMOND	3121	VIC	VIC75	MELBOURNE	lga4449559268d6	Yarra	wad393a480edfcf	Melba Ward	VIC335	RICHMOND	VIC398	NORTHERN METROPOLITAN
2132745	GAVIC419660068	locd06d20cbea22	NORTH BENDIGO	3550	VIC	VIC46	BENDIGO	lga575ae7e97596	Greater Bendigo	wadYMFosQIy2siY	Lake Weeroona Ward	VIC360	BENDIGO WEST	VIC392	NORTHERN VICTORIA
1808643	GAVIC425084593	loc630ef4fec09d	GISBORNE SOUTH	3437	VIC	VIC74	MCEWEN	lgaa61a81fb4118	Macedon Ranges	wad448ce116b942	South Ward	VIC309	MACEDON	VIC392	NORTHERN VICTORIA
448268	GAVIC721914294	locffa1c8993b70	MAMBOURIN	3024	VIC	VIC53	CORIO	lga53026dafea91	Wyndham	wadc4af85febd67	Iramoo Ward	VIC350	WERRIBEE	VIC395	WESTERN METROPOLITAN
3376838	GAVIC412739960	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
1713466	GAVIC419676903	loc86dc9bf35404	CLAYTON	3168	VIC	VIC64	HOTHAM	lga15c9c80d4be7	Monash	wad5c0NcFU0xPu0	University Ward	VIC327	OAKLEIGH	VIC394	SOUTHERN METROPOLITAN
1661342	GAVIC421219047	loc9b20cd160517	CHADSTONE	3148	VIC	VIC50	CHISHOLM	lga15c9c80d4be7	Monash	wadGd1pnVhDLFHY	Mayfield Ward	VIC354	ASHWOOD	VIC394	SOUTHERN METROPOLITAN
86004	GAVIC412089403	loc12c0177d3d38	PASCOE VALE	3044	VIC	VIC81	WILLS	lgaJ2LPN2y4pll0	Merri-Bek	wadMEHdC-S5s8qs	Pascoe Vale South Ward	VIC330	PASCOE VALE	VIC398	NORTHERN METROPOLITAN
1049183	GAVIC719608433	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
3323079	GAVIC425274073	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
2144864	GAVIC721089117	loc0b665c0fe535	OCEAN GROVE	3226	VIC	VIC52	CORANGAMITE	lga227fb535494c	Greater Geelong	wadHD-xGynvazEU	Connewarre Ward	VIC357	BELLARINE	VIC399	WESTERN VICTORIA
1919604	GAVIC425703440	locc25e0bed112f	CHELSEA HEIGHTS	3196	VIC	VIC66	ISAACS	lga691f580f3258	Kingston	wad253892513dc2	Sandpiper Ward	VIC316	MORDIALLOC	VIC393	SOUTH-EASTERN METROPOLITAN
3931963	GAVIC719244724	loc9fe59dbd0874	CRANBOURNE NORTH	3977	VIC	VIC63	HOLT	lga891e1f62b45e	Casey	wadAPt6k3MRzlsb	Correa Ward	VIC323	NARRE WARREN SOUTH	VIC393	SOUTH-EASTERN METROPOLITAN
1392989	GAVIC419908615	locc67851215f08	MEADOW HEIGHTS	3048	VIC	VIC48	CALWELL	lga3476c1d9fd7f	Hume	wadOmZ549iHV4Uv	Bababi Marning Ward	VIC387	GREENVALE	VIC398	NORTHERN METROPOLITAN
3433244	GAVIC423705816	loc8e5a2b16aaaa	TRARALGON	3844	VIC	VIC59	GIPPSLAND	lga5e8f0b6a35b1	Latrobe	wadt47MKKQlcBwn	Boola Boola Ward	VIC318	MORWELL	VIC396	EASTERN VICTORIA
1030646	GAVIC419625837	locea2e2e01b99c	MOORABBIN	3189	VIC	VIC60	GOLDSTEIN	lga691f580f3258	Kingston	wad55ea8956cf9d	Karkarook Ward	VIC361	BENTLEIGH	VIC394	SOUTHERN METROPOLITAN
533299	GAVIC411670057	loc00a9769647d7	KEW	3101	VIC	VIC68	KOOYONG	lga0930e8ebad68	Boroondara	wadfc81ecfdf52a	Studley Ward	VIC304	KEW	VIC394	SOUTHERN METROPOLITAN
2938439	GAVIC720458378	loc875f8bb64843	MANOR LAKES	3024	VIC	VIC70	LALOR	lga53026dafea91	Wyndham	wad5MfwywcyKQtC	Quandong Ward	VIC350	WERRIBEE	VIC395	WESTERN METROPOLITAN
2519909	GAVIC419912498	loc098ac8eaabef	LAVERTON	3028	VIC	VIC58	GELLIBRAND	lga224186279c28	Hobsons Bay	wadM6fFaXdiVDBj	Laverton Ward	VIC307	LAVERTON	VIC395	WESTERN METROPOLITAN
1315641	GAVIC425272843	locc7ee8539a72b	ELTHAM	3095	VIC	VIC67	JAGAJAGA	lga977c9605ab7d	Nillumbik	wad9a8033d1081a	Wingrove Ward	VIC376	ELTHAM	VIC397	NORTH-EASTERN METROPOLITAN
100426	GAVIC423399692	locc84be248155b	HEALESVILLE	3777	VIC	VIC49	CASEY	lgadbd419ff24e3	Yarra Ranges	wad3f530a6484b8	Ryrie Ward	VIC375	EILDON	VIC392	NORTHERN VICTORIA
84697	GAVIC420615360	loc87f2ad0c0fd7	CREMORNE	3121	VIC	VIC75	MELBOURNE	lga4449559268d6	Yarra	wad0NKqnSwoDzUo	Lennox Ward	VIC335	RICHMOND	VIC398	NORTHERN METROPOLITAN
1556909	GAVIC423409956	loc11fb0b5df130	MORWELL	3840	VIC	VIC59	GIPPSLAND	lga5e8f0b6a35b1	Latrobe	wadLf4uPgHBqUsk	Morwell River Ward	VIC318	MORWELL	VIC396	EASTERN VICTORIA
2637305	GAVIC423232139	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
1049942	GAVIC721917030	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
3861104	GAVIC420119751	locb9872f35df41	ABBOTSFORD	3067	VIC	VIC75	MELBOURNE	lga4449559268d6	Yarra	wada2452b82710e	Langridge Ward	VIC335	RICHMOND	VIC398	NORTHERN METROPOLITAN
3632812	GAVIC721849526	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3686692	GAVIC720052842	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
3854704	GAVIC423436506	locc91f4a31a1bc	TAYLORS HILL	3037	VIC	VIC61	GORTON	lga42b2fd54c1e9	Melton	waddc89uz_zLf_D	Lake Caroline Ward	VIC345	SYDENHAM	VIC395	WESTERN METROPOLITAN
256178	GAVIC421670970	loc5c27e3f22fc1	HAWTHORN	3122	VIC	VIC68	KOOYONG	lga0930e8ebad68	Boroondara	wadb5ad118a1aa8	Riversdale Ward	VIC389	HAWTHORN	VIC394	SOUTHERN METROPOLITAN
2300831	GAVIC420796526	loca4e166a620d9	NOBLE PARK	3174	VIC	VIC64	HOTHAM	lgab65bc8ec7820	Greater Dandenong	wadfccc777e477d	Yarraman Ward	VIC319	MULGRAVE	VIC393	SOUTH-EASTERN METROPOLITAN
2918623	GAVIC420061429	loc3832b905a97e	WEST WODONGA	3690	VIC	VIC65	INDI	lga79b8fe15ee4f	Wodonga	wadHZjhNG7ogmhe	Huon Creek Ward	VIC358	BENAMBRA	VIC392	NORTHERN VICTORIA
2242372	GAVIC425325004	loc9a86c6faf562	JACKASS FLAT	3556	VIC	VIC46	BENDIGO	lga575ae7e97596	Greater Bendigo	wad28e15eea45da	Whipstick Ward	VIC359	BENDIGO EAST	VIC392	NORTHERN VICTORIA
500156	GAVIC421049989	loc4a7c5154c298	MOONEE PONDS	3039	VIC	VIC73	MARIBYRNONG	lga638d2708b9ab	Moonee Valley	wadizrg5wm7Ua-1	Queens Park Ward	VIC377	ESSENDON	VIC398	NORTHERN METROPOLITAN
270189	GAVIC421885685	loc232da9d11723	BAIRNSDALE	3875	VIC	VIC59	GIPPSLAND	lga72904b64c519	East Gippsland	wad2fb8cdde0b4a	East Gippsland Shire	VIC384	GIPPSLAND EAST	VIC396	EASTERN VICTORIA
2709830	GAVIC420987849	locb0a9c63101c7	YARRAWONGA	3730	VIC	VIC78	NICHOLLS	lga4e7c0f04e5f4	Moira	wade57be90e56a3	Moira Shire	VIC328	OVENS VALLEY	VIC392	NORTHERN VICTORIA
561173	GAVIC424918055	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
2575638	GAVIC423789992	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
1860529	GAVIC420637602	loc9fe59dbd0874	CRANBOURNE NORTH	3977	VIC	VIC63	HOLT	lga891e1f62b45e	Casey	wadAPt6k3MRzlsb	Correa Ward	VIC323	NARRE WARREN SOUTH	VIC393	SOUTH-EASTERN METROPOLITAN
3873339	GAVIC423397050	loc610e6e8cd167	YARRA GLEN	3775	VIC	VIC49	CASEY	lgadbd419ff24e3	Yarra Ranges	wad3f530a6484b8	Ryrie Ward	VIC375	EILDON	VIC392	NORTHERN VICTORIA
3084859	GAVIC419987098	loc4423238fcdd8	HAMILTON	3300	VIC	VIC80	WANNON	lga1a08aa92f8c2	Southern Grampians	wadc52b977fe913	Southern Grampians Shire	VIC308	LOWAN	VIC399	WESTERN VICTORIA
1049333	GAVIC424765376	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
632711	GAVIC719439210	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
2279096	GAVIC421983130	loc819a06b032e3	TARNEIT	3029	VIC	VIC70	LALOR	lga53026dafea91	Wyndham	wadBUF5KMtu8z-g	Wimba Ward	VIC346	TARNEIT	VIC395	WESTERN METROPOLITAN
506086	GAVIC421924109	loc406d1f7b5fe3	TEMPLESTOWE	3106	VIC	VIC76	MENZIES	lgab3be0b9eb31a	Manningham	wad4a4aa96101ba	Westerfolds Ward	VIC367	BULLEEN	VIC397	NORTH-EASTERN METROPOLITAN
2988290	GAVIC414839745	loc7f158a48110c	BLAIRGOWRIE	3942	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	wad869d0407f3ba	Nepean Ward	VIC324	NEPEAN	VIC396	EASTERN VICTORIA
1750977	GAVIC424354717	loc70eb03d586f8	DEER PARK	3023	VIC	VIC61	GORTON	lgaf76bb579e827	Brimbank	wadx14J8-Nlx3Wq	Mount Derrimut Ward	VIC305	KOROROIT	VIC395	WESTERN METROPOLITAN
2541847	GAVIC421856523	loc11b2a92fb5f0	BRUNSWICK WEST	3055	VIC	VIC81	WILLS	lgaJ2LPN2y4pll0	Merri-Bek	wadLMZRg2myfctY	Brunswick West Ward	VIC366	BRUNSWICK	VIC398	NORTHERN METROPOLITAN
3273439	GAVIC721711659	locfd8472c41cbe	ROWVILLE	3178	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wadeaa4b13b2374	Tirhatuan Ward	VIC338	ROWVILLE	VIC393	SOUTH-EASTERN METROPOLITAN
1772772	GAVIC425314633	loc406d1f7b5fe3	TEMPLESTOWE	3106	VIC	VIC76	MENZIES	lgab3be0b9eb31a	Manningham	wad00ce24084fec	Waldau Ward	VIC367	BULLEEN	VIC397	NORTH-EASTERN METROPOLITAN
1970384	GAVIC423750017	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
2764031	GAVIC422035533	loc6ae7eaa3c1f3	BOX HILL SOUTH	3128	VIC	VIC50	CHISHOLM	lga0450031d71ce	Whitehorse	wada5e70a2a8728	Wattle Ward	VIC363	BOX HILL	VIC397	NORTH-EASTERN METROPOLITAN
3293426	GAVIC421279891	loc1b289d3ff2fc	SHEPPARTON	3630	VIC	VIC78	NICHOLLS	lga1a793093877f	Greater Shepparton	wadILqLGXlIxqFo	Balaclava Ward	VIC340	SHEPPARTON	VIC392	NORTHERN VICTORIA
2155663	GAVIC420987808	loc4ff8c926c940	ASHWOOD	3147	VIC	VIC50	CHISHOLM	lga15c9c80d4be7	Monash	wadTfHiT64vDmQ1	Gardiners Creek Ward	VIC354	ASHWOOD	VIC394	SOUTHERN METROPOLITAN
3364158	GAVIC721800565	loc1b271c01e3dc	MICKLEHAM	3064	VIC	VIC48	CALWELL	lga3476c1d9fd7f	Hume	wadVD09aRdeVUF4	Yubup Ward	VIC391	KALKALLO	VIC398	NORTHERN METROPOLITAN
2153017	GAVIC424265017	loc515028b0f98a	MANSFIELD	3722	VIC	VIC65	INDI	lga744d9df35829	Mansfield	wadfe04dd09ca94	Mansfield Shire	VIC375	EILDON	VIC392	NORTHERN VICTORIA
3772202	GAVIC425613744	locae977e7a8d83	CRANBOURNE EAST	3977	VIC	VIC63	HOLT	lga891e1f62b45e	Casey	wad_Tj6_svm1UbT	Tooradin Ward	VIC372	CRANBOURNE	VIC393	SOUTH-EASTERN METROPOLITAN
2654867	GAVIC421863134	loc1e33f92d8409	NORTH WONTHAGGI	3995	VIC	VIC77	MONASH	lgaac2e88625ea2	Bass Coast	wad819f7c7cf820	Western Port Ward	VIC355	BASS	VIC396	EASTERN VICTORIA
242285	GAVIC423390367	loc3fe991822440	RED HILL	3937	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	waddL6bRNz6XgeX	Coolart Ward	VIC324	NEPEAN	VIC396	EASTERN VICTORIA
1365213	GAVIC719985042	loca0398a35cf5e	CARLTON	3053	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3740780	GAVIC420591242	loc74f8893fb76e	BROADMEADOWS	3047	VIC	VIC48	CALWELL	lga3476c1d9fd7f	Hume	wadXsV2_er3gqTy	Merlynston Creek Ward	VIC365	BROADMEADOWS	VIC398	NORTHERN METROPOLITAN
2380022	GAVIC424263895	loce3f8de63f06a	KINGSBURY	3083	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wad9576ecab049a	North East Ward	VIC368	BUNDOORA	VIC397	NORTH-EASTERN METROPOLITAN
2368904	GAVIC420656885	loca1efec8fa041	MONT ALBERT NORTH	3129	VIC	VIC76	MENZIES	lga0450031d71ce	Whitehorse	wad8b0439dfb4fb	Kingsley Ward	VIC363	BOX HILL	VIC397	NORTH-EASTERN METROPOLITAN
3745819	GAVIC424906559	locdd716f1059c5	MENTONE	3194	VIC	VIC66	ISAACS	lga691f580f3258	Kingston	wadd1bbf3e2721d	Como Ward	VIC339	SANDRINGHAM	VIC394	SOUTHERN METROPOLITAN
1176375	GAVIC719439216	loc1e06c486c813	NORTH MELBOURNE	3051	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
2796234	GAVIC720475626	locba5e689e47f8	TORQUAY	3228	VIC	VIC52	CORANGAMITE	lgaeb9321b0357b	Surf Coast	wada94e80fc0adb	Torquay Ward	VIC332	POLWARTH	VIC399	WESTERN VICTORIA
873554	GAVIC423837828	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
998594	GAVIC420964291	loc3319215a0a10	BRIGHTON	3186	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad086a5a9284d6	Dendy Ward	VIC364	BRIGHTON	VIC394	SOUTHERN METROPOLITAN
442812	GAVIC721916596	loc8f498b475ec6	TRARALGON EAST	3844	VIC	VIC59	GIPPSLAND	lga5e8f0b6a35b1	Latrobe	wadt47MKKQlcBwn	Boola Boola Ward	VIC318	MORWELL	VIC396	EASTERN VICTORIA
3295879	GAVIC420881388	loc250adfcbc82d	PRAHRAN	3181	VIC	VIC68	KOOYONG	lgae1dcbacb8510	Stonnington	wadGcQBXlY6EXem	Orrong Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
2812332	GAVIC425484937	loc0621c45c46f4	BALWYN NORTH	3104	VIC	VIC68	KOOYONG	lga0930e8ebad68	Boroondara	wad80ec090a6e95	Bellevue Ward	VIC304	KEW	VIC394	SOUTHERN METROPOLITAN
643237	GAVIC720919065	loc74f8893fb76e	BROADMEADOWS	3047	VIC	VIC48	CALWELL	lga3476c1d9fd7f	Hume	wadXsV2_er3gqTy	Merlynston Creek Ward	VIC365	BROADMEADOWS	VIC398	NORTHERN METROPOLITAN
3365516	GAVIC719745362	loc656f84726510	RESERVOIR	3073	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wadaaf7b81c6267	North West Ward	VIC334	PRESTON	VIC398	NORTHERN METROPOLITAN
3672718	GAVIC422294300	loc3832b905a97e	WEST WODONGA	3690	VIC	VIC65	INDI	lga79b8fe15ee4f	Wodonga	wadwJvF9vhtyZGS	Barnawartha North Ward	VIC358	BENAMBRA	VIC392	NORTHERN VICTORIA
731808	GAVIC420841495	locbbb93e2c6c42	BARWON HEADS	3227	VIC	VIC52	CORANGAMITE	lga227fb535494c	Greater Geelong	wadHD-xGynvazEU	Connewarre Ward	VIC357	BELLARINE	VIC399	WESTERN VICTORIA
963287	GAVIC421448648	loccaca39f133a7	HEIDELBERG HEIGHTS	3081	VIC	VIC67	JAGAJAGA	lga5591321694d6	Banyule	wad57d6bb56db1d	Ibbott Ward	VIC390	IVANHOE	VIC397	NORTH-EASTERN METROPOLITAN
1958867	GAVIC421262022	loc76dea039b41f	MALVERN	3144	VIC	VIC68	KOOYONG	lgae1dcbacb8510	Stonnington	wadTbedye7mfV-b	Wattletree Ward	VIC310	MALVERN	VIC394	SOUTHERN METROPOLITAN
2386112	GAVIC424283355	loc0a03ed3531fd	CHELTENHAM	3192	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad39d5f838e441	Ebden Ward	VIC339	SANDRINGHAM	VIC394	SOUTHERN METROPOLITAN
146796	GAVIC420980761	loc264c2d9ba83e	MULGRAVE	3170	VIC	VIC64	HOTHAM	lga15c9c80d4be7	Monash	wadHydqxaWDBatM	Wellington Ward	VIC319	MULGRAVE	VIC393	SOUTH-EASTERN METROPOLITAN
2270449	GAVIC423471646	loc79e45c9fa669	BRUNSWICK EAST	3057	VIC	VIC81	WILLS	lgaJ2LPN2y4pll0	Merri-Bek	wadlMZ140e5e2tn	Warrk-Warrk Ward	VIC366	BRUNSWICK	VIC398	NORTHERN METROPOLITAN
3200547	GAVIC419571030	loc0b8afd71fce1	WEST MELBOURNE	3003	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
2460503	GAVIC719915818	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
988542	GAVIC720518002	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
1303943	GAVIC424424026	loc2d817b7080e2	MALVERN EAST	3145	VIC	VIC50	CHISHOLM	lgae1dcbacb8510	Stonnington	wadGRxTsj9GscKr	Malvern Valley Ward	VIC310	MALVERN	VIC394	SOUTHERN METROPOLITAN
2664673	GAVIC420215992	loc3b6fd5dcd874	SORRENTO	3943	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	wad869d0407f3ba	Nepean Ward	VIC324	NEPEAN	VIC396	EASTERN VICTORIA
3730395	GAVIC412667511	locf3fc3fca2acd	BANGHOLME	3175	VIC	VIC66	ISAACS	lgab65bc8ec7820	Greater Dandenong	wad16e199e3d481	Keysborough South Ward	VIC316	MORDIALLOC	VIC393	SOUTH-EASTERN METROPOLITAN
2061002	GAVIC424628057	locc5abea08e85d	POINT COOK	3030	VIC	VIC58	GELLIBRAND	lga53026dafea91	Wyndham	wadIisBVS3hc3vA	Featherbrook Ward	VIC331	POINT COOK	VIC395	WESTERN METROPOLITAN
279516	GAVIC420502224	loc82baa1179308	PAKENHAM	3810	VIC	VIC69	LA TROBE	lgac69cfd288672	Cardinia	wad033292abab50	Henty Ward	VIC329	PAKENHAM	VIC396	EASTERN VICTORIA
822264	GAVIC721025623	loc8733d13ded2e	FRASER RISE	3336	VIC	VIC61	GORTON	lga42b2fd54c1e9	Melton	wadCXsP0Ee7ou9B	Jackwood Ward	VIC345	SYDENHAM	VIC395	WESTERN METROPOLITAN
3497804	GAVIC720000915	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
1116060	GAVIC420015455	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
111544	GAVIC425084495	locbb6ca08c118e	NORTHCOTE	3070	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wad3fb5999d4db1	South Ward	VIC326	NORTHCOTE	VIC398	NORTHERN METROPOLITAN
2563924	GAVIC425530619	locedacea740a10	SWAN HILL	3585	VIC	VIC72	MALLEE	lga2f887f3655b9	Swan Hill	wad06be12aa2c37	Swan Hill Rural City	VIC320	MURRAY PLAINS	VIC392	NORTHERN VICTORIA
464143	GAVIC425083938	loc51ba976fe589	OAK PARK	3046	VIC	VIC73	MARIBYRNONG	lgaJ2LPN2y4pll0	Merri-Bek	wad10bOEnGsV8dy	Djirri-Djirri Ward	VIC365	BROADMEADOWS	VIC398	NORTHERN METROPOLITAN
3260409	GAVIC420099787	locc70453923b8e	BONBEACH	3196	VIC	VIC55	DUNKLEY	lga691f580f3258	Kingston	wad39774553a495	Longbeach Ward	VIC369	CARRUM	VIC393	SOUTH-EASTERN METROPOLITAN
2668017	GAVIC720543934	loceb6884033cea	DURHAM LEAD	3352	VIC	VIC45	BALLARAT	lgab70a9914e5bc	Ballarat	wad4V7EkNIaOhR5	Buninyong Ward	VIC378	EUREKA	VIC399	WESTERN VICTORIA
117448	GAVIC719919340	loc5c7c3d320a8a	WANGARATTA	3677	VIC	VIC65	INDI	lgabff52ad8fdf9	Wangaratta	wadcV16ds_b6_8M	Appin Ward	VIC328	OVENS VALLEY	VIC392	NORTHERN VICTORIA
2700220	GAVIC421832935	loc2c4c767ea9b7	PRESTON	3072	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wad4964b853357e	West Ward	VIC334	PRESTON	VIC398	NORTHERN METROPOLITAN
1971887	GAVIC425622336	loca0398a35cf5e	CARLTON	3053	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3514095	GAVIC720443226	loc1a7553da1009	CHETWYND	3312	VIC	VIC72	MALLEE	lga82035025d67f	West Wimmera	wad1e131124c085	West Wimmera Shire	VIC308	LOWAN	VIC399	WESTERN VICTORIA
920552	GAVIC421943442	loc06cc48b309e5	WATSONIA	3087	VIC	VIC67	JAGAJAGA	lga5591321694d6	Banyule	wadf537fb66c529	Bakewell Ward	VIC368	BUNDOORA	VIC397	NORTH-EASTERN METROPOLITAN
150687	GAVIC420429255	loceb41e8eec3ee	LONGWARRY	3816	VIC	VIC77	MONASH	lga77d96c3addfd	Baw Baw	wadde002fa6d7b0	West Ward	VIC321	NARRACAN	VIC396	EASTERN VICTORIA
1166153	GAVIC421753831	locc67851215f08	MEADOW HEIGHTS	3048	VIC	VIC48	CALWELL	lga3476c1d9fd7f	Hume	wadOmZ549iHV4Uv	Bababi Marning Ward	VIC387	GREENVALE	VIC398	NORTHERN METROPOLITAN
2704255	GAVIC719524538	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3230448	GAVIC420751807	loc3b6fd5dcd874	SORRENTO	3943	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	wad869d0407f3ba	Nepean Ward	VIC324	NEPEAN	VIC396	EASTERN VICTORIA
3895270	GAVIC419868312	loc025dead673cc	PARKDALE	3195	VIC	VIC66	ISAACS	lga691f580f3258	Kingston	wad9b7ebaac29bf	Chicquita Ward	VIC316	MORDIALLOC	VIC393	SOUTH-EASTERN METROPOLITAN
3097030	GAVIC419568757	loc7d9d9818d4b9	BORONIA	3155	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wadb3eb619c9025	Baird Ward	VIC356	BAYSWATER	VIC397	NORTH-EASTERN METROPOLITAN
368648	GAVIC721706405	loca1a84d46e52a	EPPING	3076	VIC	VIC79	SCULLIN	lgaa0f71a56be3f	Whittlesea	wadQ7y0_YB6rXPF	Epping Ward	VIC347	THOMASTOWN	VIC398	NORTHERN METROPOLITAN
2236655	GAVIC719754869	loc3d949ab3c987	HEATHERTON	3202	VIC	VIC66	ISAACS	lga691f580f3258	Kingston	wad55ea8956cf9d	Karkarook Ward	VIC371	CLARINDA	VIC393	SOUTH-EASTERN METROPOLITAN
3861248	GAVIC425272501	loc6d7f0d49a3d6	WOLLERT	3750	VIC	VIC79	SCULLIN	lgaa0f71a56be3f	Whittlesea	wadPTVq9llNpN_1	Ganbu Gulinj Ward	VIC347	THOMASTOWN	VIC398	NORTHERN METROPOLITAN
340796	GAVIC424272695	loccb9bfb1fb49a	CROYDON	3136	VIC	VIC54	DEAKIN	lgafa7d75c94e0c	Maroondah	wadb4cad035c737	Wicklow Ward	VIC373	CROYDON	VIC397	NORTH-EASTERN METROPOLITAN
800601	GAVIC419837839	locc81a6ec90a1b	ROSEBUD	3939	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	wad7dxsK5rEAxTh	Benbenjie Ward	VIC324	NEPEAN	VIC396	EASTERN VICTORIA
2639841	GAVIC421741216	loc63a05a113f90	MERBEIN	3505	VIC	VIC72	MALLEE	lgaee4000c6a5c1	Mildura	wad5GqnPaKLTOBU	Millewa Ward	VIC313	MILDURA	VIC392	NORTHERN VICTORIA
3115029	GAVIC720693565	loc4883549a5421	GREENVALE	3059	VIC	VIC48	CALWELL	lga3476c1d9fd7f	Hume	wadmhDGM7qm9bdA	Woodlands Ward	VIC387	GREENVALE	VIC398	NORTHERN METROPOLITAN
755624	GAVIC421479094	loc0b665c0fe535	OCEAN GROVE	3226	VIC	VIC52	CORANGAMITE	lga227fb535494c	Greater Geelong	wadHD-xGynvazEU	Connewarre Ward	VIC357	BELLARINE	VIC399	WESTERN VICTORIA
736302	GAVIC420622820	locdf0288b649a4	WODONGA	3690	VIC	VIC65	INDI	lga79b8fe15ee4f	Wodonga	wadGqfgKOwrYnpj	Lake Hume Ward	VIC358	BENAMBRA	VIC392	NORTHERN VICTORIA
308061	GAVIC420355278	loccdfc709471ce	KERANG	3579	VIC	VIC72	MALLEE	lga292a6552ec8c	Gannawarra	waddSLcadpqglEJ	Gannawarra Shire	VIC320	MURRAY PLAINS	VIC392	NORTHERN VICTORIA
1696425	GAVIC421499309	locb17fb225139f	IVANHOE EAST	3079	VIC	VIC67	JAGAJAGA	lga5591321694d6	Banyule	wadd52b1e7fef89	Griffin Ward	VIC390	IVANHOE	VIC397	NORTH-EASTERN METROPOLITAN
1477753	GAVIC719987520	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3344281	GAVIC420510289	loc70eb03d586f8	DEER PARK	3023	VIC	VIC61	GORTON	lgaf76bb579e827	Brimbank	wadx14J8-Nlx3Wq	Mount Derrimut Ward	VIC305	KOROROIT	VIC395	WESTERN METROPOLITAN
3096690	GAVIC421826494	loc2f9c80de6f7d	BAYSWATER	3153	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wadb3eb619c9025	Baird Ward	VIC356	BAYSWATER	VIC397	NORTH-EASTERN METROPOLITAN
2093957	GAVIC719979296	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
2876111	GAVIC411852098	locdd716f1059c5	MENTONE	3194	VIC	VIC66	ISAACS	lga691f580f3258	Kingston	wadd1bbf3e2721d	Como Ward	VIC339	SANDRINGHAM	VIC394	SOUTHERN METROPOLITAN
2266072	GAVIC412527332	loc4a341f4d3e02	WANTIRNA	3152	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wadcfea20d05544	Collier Ward	VIC356	BAYSWATER	VIC397	NORTH-EASTERN METROPOLITAN
3213795	GAVIC424599194	locd777103bd088	BACCHUS MARSH	3340	VIC	VIC62	HAWKE	lga4eb6e129e4f4	Moorabool	wadYHMzEdr6_gD1	Moorabool Shire	VIC378	EUREKA	VIC399	WESTERN VICTORIA
2273238	GAVIC420229782	loca1a84d46e52a	EPPING	3076	VIC	VIC79	SCULLIN	lgaa0f71a56be3f	Whittlesea	wadQ7y0_YB6rXPF	Epping Ward	VIC314	MILL PARK	VIC397	NORTH-EASTERN METROPOLITAN
1617692	GAVIC718988205	loc6a54ce63b777	WINTER VALLEY	3358	VIC	VIC45	BALLARAT	lgab70a9914e5bc	Ballarat	wadxupXdB4SFZlj	Delacombe Ward	VIC349	WENDOUREE	VIC399	WESTERN VICTORIA
3211016	GAVIC425685265	locd6190ebbe554	FALLS CREEK	3699	VIC	VIC65	INDI	lgad235bc15860c	Falls Creek Alpine Resort (Uninc)	\N	\N	VIC328	OVENS VALLEY	VIC392	NORTHERN VICTORIA
3167720	GAVIC424626663	loc1b289d3ff2fc	SHEPPARTON	3630	VIC	VIC78	NICHOLLS	lga1a793093877f	Greater Shepparton	wadILqLGXlIxqFo	Balaclava Ward	VIC340	SHEPPARTON	VIC392	NORTHERN VICTORIA
3512819	GAVIC719210454	loc64c822b0bad5	OFFICER	3809	VIC	VIC69	LA TROBE	lgac69cfd288672	Cardinia	wad61f8fb87ae0c	Central Ward	VIC329	PAKENHAM	VIC396	EASTERN VICTORIA
2590356	GAVIC421565163	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
2976503	GAVIC412681818	loc8e5a2b16aaaa	TRARALGON	3844	VIC	VIC59	GIPPSLAND	lga5e8f0b6a35b1	Latrobe	wadtyGwzL6YJLXL	Jeeralang Ward	VIC318	MORWELL	VIC396	EASTERN VICTORIA
1754175	GAVIC721479211	loc22c42e389de3	SOUTH MORANG	3752	VIC	VIC79	SCULLIN	lgaa0f71a56be3f	Whittlesea	wadmMQ3EW_HJnq2	South Morang Ward	VIC314	MILL PARK	VIC397	NORTH-EASTERN METROPOLITAN
2183912	GAVIC720746274	loc6c0f29d040f7	TORRUMBARRY	3562	VIC	VIC78	NICHOLLS	lgaf4d7671cd990	Campaspe	wad-_EZ61IArian	Campaspe Shire	VIC320	MURRAY PLAINS	VIC392	NORTHERN VICTORIA
2591494	GAVIC424633603	loc72d1f0339be6	RINGWOOD	3134	VIC	VIC54	DEAKIN	lgafa7d75c94e0c	Maroondah	wade9a60dcb613e	Wonga Ward	VIC336	RINGWOOD	VIC397	NORTH-EASTERN METROPOLITAN
26345	GAVIC423639265	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
1839606	GAVIC420049828	loc4a6dd2077a69	VENUS BAY	3956	VIC	VIC77	MONASH	lga5c66b4f8531c	South Gippsland	wad6aa1f2ba6f26	Coastal-Promontory Ward	VIC385	GIPPSLAND SOUTH	VIC396	EASTERN VICTORIA
2030659	GAVIC422409795	loc3832b905a97e	WEST WODONGA	3690	VIC	VIC65	INDI	lga79b8fe15ee4f	Wodonga	wadxDRroDC4syra	Marimba Park Ward	VIC358	BENAMBRA	VIC392	NORTHERN VICTORIA
2888352	GAVIC419724052	loc67a11408d754	FOOTSCRAY	3011	VIC	VIC57	FRASER	lga2513fbdd7033	Maribyrnong	wadh3mUkNZii3d4	Burndap Ward	VIC381	FOOTSCRAY	VIC395	WESTERN METROPOLITAN
2437105	GAVIC420556912	loc0b6e17218dd4	ORMOND	3204	VIC	VIC60	GOLDSTEIN	lga9bd137c30d17	Glen Eira	wadqSoXat8DB55S	Wattle Grove Ward	VIC361	BENTLEIGH	VIC394	SOUTHERN METROPOLITAN
1760922	GAVIC720238978	loc98325a7e67bf	LUCAS	3350	VIC	VIC45	BALLARAT	lgab70a9914e5bc	Ballarat	wadt6eKiNyxBWf9	Alfredton Ward	VIC337	RIPON	VIC399	WESTERN VICTORIA
466390	GAVIC423890759	loc910a14938d48	GEELONG WEST	3218	VIC	VIC53	CORIO	lga227fb535494c	Greater Geelong	wad1484ec1e9472	Kardinia Ward	VIC383	GEELONG	VIC399	WESTERN VICTORIA
3577374	GAVIC420812068	loc29a798d6921b	WERRIBEE	3030	VIC	VIC70	LALOR	lga53026dafea91	Wyndham	wadD3yldScPPI45	Heathdale Ward	VIC350	WERRIBEE	VIC395	WESTERN METROPOLITAN
2881318	GAVIC721705028	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
493338	GAVIC420647207	loc5ba812288f5b	LEOPOLD	3224	VIC	VIC52	CORANGAMITE	lga227fb535494c	Greater Geelong	wad5M41RFN1lqIK	Leopold Ward	VIC357	BELLARINE	VIC399	WESTERN VICTORIA
3490480	GAVIC425730031	loc0a03ed3531fd	CHELTENHAM	3192	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad39d5f838e441	Ebden Ward	VIC339	SANDRINGHAM	VIC394	SOUTHERN METROPOLITAN
2698678	GAVIC425511946	loce0707ac065f9	THOMSON	3219	VIC	VIC53	CORIO	lga227fb535494c	Greater Geelong	wadgHDLb4jS-cZL	Cheetham Ward	VIC383	GEELONG	VIC399	WESTERN VICTORIA
2094341	GAVIC424796248	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3828449	GAVIC419701922	loc1f73672977ce	WARRNAMBOOL	3280	VIC	VIC80	WANNON	lgada11866a4071	Warrnambool	wadrGvBnbNGNRGd	Hopkins River Ward	VIC342	SOUTH-WEST COAST	VIC399	WESTERN VICTORIA
2331541	GAVIC720512281	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
748308	GAVIC411685451	loc38cbe92d1159	KILSYTH	3137	VIC	VIC49	CASEY	lgadbd419ff24e3	Yarra Ranges	wade92fdb55483e	Walling Ward	VIC373	CROYDON	VIC397	NORTH-EASTERN METROPOLITAN
2634352	GAVIC421862656	loccaca39f133a7	HEIDELBERG HEIGHTS	3081	VIC	VIC67	JAGAJAGA	lga5591321694d6	Banyule	wada6a3e547acbc	Olympia Ward	VIC390	IVANHOE	VIC397	NORTH-EASTERN METROPOLITAN
3437064	GAVIC425734206	loc9e7da77def26	PARKVILLE	3052	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
1636430	GAVIC419827679	loc695c9ddc8068	ST KILDA EAST	3183	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad_oTYg07BQp9J	Alma Ward	VIC370	CAULFIELD	VIC394	SOUTHERN METROPOLITAN
334314	GAVIC412676977	loc0a8087d68433	KOORLONG	3501	VIC	VIC72	MALLEE	lgaee4000c6a5c1	Mildura	wad5GqnPaKLTOBU	Millewa Ward	VIC313	MILDURA	VIC392	NORTHERN VICTORIA
1848683	GAVIC424746499	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
1471246	GAVIC423826364	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3817184	GAVIC423837989	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
1448544	GAVIC425732776	loc5900b8cc74c8	LEONGATHA	3953	VIC	VIC77	MONASH	lga5c66b4f8531c	South Gippsland	wad007f14b55568	Tarwin Valley Ward	VIC385	GIPPSLAND SOUTH	VIC396	EASTERN VICTORIA
98404	GAVIC420298014	loc4fa4b090ce9e	HAWTHORN EAST	3123	VIC	VIC68	KOOYONG	lga0930e8ebad68	Boroondara	wadb5ad118a1aa8	Riversdale Ward	VIC389	HAWTHORN	VIC394	SOUTHERN METROPOLITAN
1269377	GAVIC720474883	loc12cc6354a4ba	MOUNT CAMEL	3523	VIC	VIC46	BENDIGO	lga575ae7e97596	Greater Bendigo	wadih37tODrdjSK	Axedale Ward	VIC379	EUROA	VIC392	NORTHERN VICTORIA
1869166	GAVIC421362480	locf16910f90fb9	HIGHETT	3190	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wadd9f02c005f7c	Ivison Ward	VIC339	SANDRINGHAM	VIC394	SOUTHERN METROPOLITAN
2020622	GAVIC425707510	loc8688ba223de1	MOUNT BULLER	3723	VIC	VIC65	INDI	lga69dad94a9718	Mount Buller Alpine Resort (Uninc)	\N	\N	VIC375	EILDON	VIC392	NORTHERN VICTORIA
1635348	GAVIC422034832	loc6de6554b144b	TAWONGA SOUTH	3698	VIC	VIC65	INDI	lga136d886cbd2c	Alpine	wad9ff7d2981028	Alpine Shire	VIC328	OVENS VALLEY	VIC392	NORTHERN VICTORIA
3074551	GAVIC719527287	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
3396554	GAVIC719430501	loc8c9f2867857c	WILLIAMSTOWN	3016	VIC	VIC58	GELLIBRAND	lga224186279c28	Hobsons Bay	wadAGHYYrpkmktP	Williamstown Ward	VIC351	WILLIAMSTOWN	VIC395	WESTERN METROPOLITAN
3134773	GAVIC425539243	loccabf2d0215b8	MADDINGLEY	3340	VIC	VIC62	HAWKE	lga4eb6e129e4f4	Moorabool	wadYHMzEdr6_gD1	Moorabool Shire	VIC378	EUREKA	VIC399	WESTERN VICTORIA
1675942	GAVIC720144307	loc67a11408d754	FOOTSCRAY	3011	VIC	VIC57	FRASER	lga2513fbdd7033	Maribyrnong	wady8yCvqkB58YX	Sheoak Ward	VIC381	FOOTSCRAY	VIC395	WESTERN METROPOLITAN
3478112	GAVIC412549753	loc2424df148d7d	WANDIN EAST	3139	VIC	VIC49	CASEY	lgadbd419ff24e3	Yarra Ranges	wadafc695e2558b	Chandler Ward	VIC315	MONBULK	VIC396	EASTERN VICTORIA
517192	GAVIC424776713	loc232da9d11723	BAIRNSDALE	3875	VIC	VIC59	GIPPSLAND	lga72904b64c519	East Gippsland	wad2fb8cdde0b4a	East Gippsland Shire	VIC384	GIPPSLAND EAST	VIC396	EASTERN VICTORIA
1755125	GAVIC422273680	loc13ed320cd188	STRATHFIELDSAYE	3551	VIC	VIC46	BENDIGO	lga575ae7e97596	Greater Bendigo	wadih37tODrdjSK	Axedale Ward	VIC359	BENDIGO EAST	VIC392	NORTHERN VICTORIA
1047524	GAVIC425368628	loc9a86c6faf562	JACKASS FLAT	3556	VIC	VIC46	BENDIGO	lga575ae7e97596	Greater Bendigo	wadFruXXMk_cC01	Epsom Ward	VIC359	BENDIGO EAST	VIC392	NORTHERN VICTORIA
3604540	GAVIC720058933	loc2c4c767ea9b7	PRESTON	3072	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wad8f5a9db3d21b	Central Ward	VIC326	NORTHCOTE	VIC398	NORTHERN METROPOLITAN
2770137	GAVIC425044566	locf57f2052e543	FRANKSTON NORTH	3200	VIC	VIC55	DUNKLEY	lgadd7fe82edc77	Frankston	wadhxD2G_0oKCn0	Pines Ward	VIC382	FRANKSTON	VIC393	SOUTH-EASTERN METROPOLITAN
583860	GAVIC425489617	locc25e0bed112f	CHELSEA HEIGHTS	3196	VIC	VIC66	ISAACS	lga691f580f3258	Kingston	wad253892513dc2	Sandpiper Ward	VIC316	MORDIALLOC	VIC393	SOUTH-EASTERN METROPOLITAN
3483234	GAVIC421307669	locadc5cabaa80e	GLEN IRIS	3146	VIC	VIC50	CHISHOLM	lgae1dcbacb8510	Stonnington	wadXdFA1Wq5yoqK	Tooronga Ward	VIC310	MALVERN	VIC394	SOUTHERN METROPOLITAN
3133409	GAVIC420206310	loc29a798d6921b	WERRIBEE	3030	VIC	VIC70	LALOR	lga53026dafea91	Wyndham	wadc4af85febd67	Iramoo Ward	VIC350	WERRIBEE	VIC395	WESTERN METROPOLITAN
359647	GAVIC422277019	locb7bca082fca0	BEECH FOREST	3237	VIC	VIC80	WANNON	lgaa40be6b352b7	Colac Otway	wad47d3bb0ccf8c	Colac Otway Shire	VIC332	POLWARTH	VIC399	WESTERN VICTORIA
2625314	GAVIC721019485	loc46443686a430	SUNSHINE WEST	3020	VIC	VIC57	FRASER	lgaf76bb579e827	Brimbank	wadjEGl4Fy-94ge	Cherry Creek Ward	VIC307	LAVERTON	VIC395	WESTERN METROPOLITAN
3408490	GAVIC425032219	locae68612e5fe1	WARRANWOOD	3134	VIC	VIC54	DEAKIN	lgafa7d75c94e0c	Maroondah	wad89da7f95b671	Yarrunga Ward	VIC348	WARRANDYTE	VIC397	NORTH-EASTERN METROPOLITAN
3672221	GAVIC413384563	locb694454fbbb1	CANTERBURY	3126	VIC	VIC68	KOOYONG	lga0930e8ebad68	Boroondara	wadd7b39038802b	Maling Ward	VIC389	HAWTHORN	VIC394	SOUTHERN METROPOLITAN
681626	GAVIC425089969	loc82baa1179308	PAKENHAM	3810	VIC	VIC69	LA TROBE	lgac69cfd288672	Cardinia	wad033292abab50	Henty Ward	VIC329	PAKENHAM	VIC396	EASTERN VICTORIA
3605546	GAVIC421986723	loc02a3a330fe2f	INDENTED HEAD	3223	VIC	VIC52	CORANGAMITE	lga227fb535494c	Greater Geelong	wadzqyNP4wsaqEj	Murradoc Ward	VIC357	BELLARINE	VIC399	WESTERN VICTORIA
1784756	GAVIC419598648	loc098ac8eaabef	LAVERTON	3028	VIC	VIC58	GELLIBRAND	lga224186279c28	Hobsons Bay	wadM6fFaXdiVDBj	Laverton Ward	VIC307	LAVERTON	VIC395	WESTERN METROPOLITAN
809406	GAVIC421787496	locff58d0167065	BENALLA	3672	VIC	VIC65	INDI	lga6f3147bcaaee	Benalla	wadf0f7e80f56a5	Benalla Rural City	VIC379	EUROA	VIC392	NORTHERN VICTORIA
1794176	GAVIC419898327	locad899e5d272f	BLACK ROCK	3193	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad39d5f838e441	Ebden Ward	VIC339	SANDRINGHAM	VIC394	SOUTHERN METROPOLITAN
2900198	GAVIC422091233	loc3319215a0a10	BRIGHTON	3186	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad086a5a9284d6	Dendy Ward	VIC364	BRIGHTON	VIC394	SOUTHERN METROPOLITAN
451278	GAVIC419623906	locf4e180745c81	DROMANA	3936	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	wadpmAbgHWmCICe	Brokil Ward	VIC324	NEPEAN	VIC396	EASTERN VICTORIA
1172093	GAVIC411809712	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
2037320	GAVIC424732111	loca818c5eaa373	WEST FOOTSCRAY	3012	VIC	VIC57	FRASER	lga2513fbdd7033	Maribyrnong	wadtcIDtIUnPw_G	Bluestone Ward	VIC381	FOOTSCRAY	VIC395	WESTERN METROPOLITAN
110566	GAVIC425685032	locf51f6cd689bb	SOUTH MELBOURNE	3205	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wadyBOUDailkzZ2	South Melbourne Ward	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
3277909	GAVIC419723191	loc11fb0b5df130	MORWELL	3840	VIC	VIC59	GIPPSLAND	lga5e8f0b6a35b1	Latrobe	wadBQ4dvCZJUl76	Yallourn Ward	VIC318	MORWELL	VIC396	EASTERN VICTORIA
160145	GAVIC719983320	loc1e06c486c813	NORTH MELBOURNE	3051	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3644549	GAVIC421736429	loc3319215a0a10	BRIGHTON	3186	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad086a5a9284d6	Dendy Ward	VIC364	BRIGHTON	VIC394	SOUTHERN METROPOLITAN
1463896	GAVIC424490619	locc81a6ec90a1b	ROSEBUD	3939	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	wad7dxsK5rEAxTh	Benbenjie Ward	VIC324	NEPEAN	VIC396	EASTERN VICTORIA
1689582	GAVIC425369445	loc75d84680b181	TENNYSON	3572	VIC	VIC46	BENDIGO	lgaf4d7671cd990	Campaspe	wad-_EZ61IArian	Campaspe Shire	VIC320	MURRAY PLAINS	VIC392	NORTHERN VICTORIA
106189	GAVIC420734999	locc7ee8539a72b	ELTHAM	3095	VIC	VIC67	JAGAJAGA	lga977c9605ab7d	Nillumbik	wad9a8033d1081a	Wingrove Ward	VIC376	ELTHAM	VIC397	NORTH-EASTERN METROPOLITAN
2193823	GAVIC719764462	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
746794	GAVIC721704323	loc556974a8bc81	MELTON	3337	VIC	VIC62	HAWKE	lga42b2fd54c1e9	Melton	wad57701c871e30	Watts Ward	VIC312	MELTON	VIC399	WESTERN VICTORIA
3251567	GAVIC720699788	loc15a8d395ef61	NAR NAR GOON	3812	VIC	VIC69	LA TROBE	lgac69cfd288672	Cardinia	wad7780701db473	Bunyip Ward	VIC321	NARRACAN	VIC396	EASTERN VICTORIA
3642841	GAVIC420040549	loc74f8893fb76e	BROADMEADOWS	3047	VIC	VIC48	CALWELL	lga3476c1d9fd7f	Hume	wadXsV2_er3gqTy	Merlynston Creek Ward	VIC365	BROADMEADOWS	VIC398	NORTHERN METROPOLITAN
3428748	GAVIC425614233	loc5c27e3f22fc1	HAWTHORN	3122	VIC	VIC68	KOOYONG	lga0930e8ebad68	Boroondara	wad89a568d4dc5f	Glenferrie Ward	VIC389	HAWTHORN	VIC394	SOUTHERN METROPOLITAN
3086612	GAVIC423081290	loc679429866800	SANDY CREEK	3695	VIC	VIC65	INDI	lga5c6d68bc8aa6	Indigo	wade95c83ee5bad	Indigo Shire	VIC358	BENAMBRA	VIC392	NORTHERN VICTORIA
3313691	GAVIC421930895	loca56f2b16461e	BULLEEN	3105	VIC	VIC76	MENZIES	lgab3be0b9eb31a	Manningham	wad93d957bf0e83	Bolin Ward	VIC367	BULLEEN	VIC397	NORTH-EASTERN METROPOLITAN
3020876	GAVIC419784455	locb8f595af5fb8	WHEELERS HILL	3150	VIC	VIC64	HOTHAM	lga15c9c80d4be7	Monash	wadaxLPH8xNPb2d	Jells Ward	VIC319	MULGRAVE	VIC393	SOUTH-EASTERN METROPOLITAN
2416293	GAVIC424531851	loce16236caf708	LARA	3212	VIC	VIC53	CORIO	lga227fb535494c	Greater Geelong	wadzWnDzRGqmtuN	You Yangs Ward	VIC306	LARA	VIC399	WESTERN VICTORIA
3724950	GAVIC419621302	loc9165cd64854f	BAYSWATER NORTH	3153	VIC	VIC44	ASTON	lgafa7d75c94e0c	Maroondah	wad328366eaf3dc	Tarralla Ward	VIC373	CROYDON	VIC397	NORTH-EASTERN METROPOLITAN
1207044	GAVIC420255830	loc8f565e81c655	THOMASTOWN	3074	VIC	VIC79	SCULLIN	lgaa0f71a56be3f	Whittlesea	waddvQNFWtBq90t	Thomastown Ward	VIC347	THOMASTOWN	VIC398	NORTHERN METROPOLITAN
2847645	GAVIC424353303	loc9fb289b0a33e	IRYMPLE	3498	VIC	VIC72	MALLEE	lgaee4000c6a5c1	Mildura	wadWxWdJFaA5OC5	Sunset Country Ward	VIC313	MILDURA	VIC392	NORTHERN VICTORIA
2311418	GAVIC420684174	loc4ff8c926c940	ASHWOOD	3147	VIC	VIC50	CHISHOLM	lga15c9c80d4be7	Monash	wadTfHiT64vDmQ1	Gardiners Creek Ward	VIC354	ASHWOOD	VIC394	SOUTHERN METROPOLITAN
1451995	GAVIC425275442	loc2d817b7080e2	MALVERN EAST	3145	VIC	VIC50	CHISHOLM	lgae1dcbacb8510	Stonnington	wad4GOUAzunjtQ3	Hedgeley Dene Ward	VIC310	MALVERN	VIC394	SOUTHERN METROPOLITAN
1962111	GAVIC423402101	loce36428dd6505	WELSHMANS REEF	3462	VIC	VIC46	BENDIGO	lga0eac1885ea16	Mount Alexander	wad52905cdfee54	Loddon River Ward	VIC360	BENDIGO WEST	VIC392	NORTHERN VICTORIA
1523020	GAVIC421689281	locd6f79866f950	KNOXFIELD	3180	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wadfde0a79062c6	Friberg Ward	VIC338	ROWVILLE	VIC393	SOUTH-EASTERN METROPOLITAN
773589	GAVIC420504897	loc5c27e3f22fc1	HAWTHORN	3122	VIC	VIC68	KOOYONG	lga0930e8ebad68	Boroondara	wadb5ad118a1aa8	Riversdale Ward	VIC389	HAWTHORN	VIC394	SOUTHERN METROPOLITAN
3436396	GAVIC425520470	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
401521	GAVIC425786720	loc6de0828869d7	COLLINGWOOD	3066	VIC	VIC75	MELBOURNE	lga4449559268d6	Yarra	wadGo-6IsXi2b_Q	Hoddle Ward	VIC335	RICHMOND	VIC398	NORTHERN METROPOLITAN
2753890	GAVIC419711232	locf16910f90fb9	HIGHETT	3190	VIC	VIC60	GOLDSTEIN	lga691f580f3258	Kingston	wadc4d2321c51cd	Wattle Ward	VIC361	BENTLEIGH	VIC394	SOUTHERN METROPOLITAN
1945166	GAVIC423792711	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
2499004	GAVIC419906596	loc82b861dfb765	THORNBURY	3071	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wadd51102c6b3b7	South Central Ward	VIC326	NORTHCOTE	VIC398	NORTHERN METROPOLITAN
725350	GAVIC719213944	locf8d60bf51b6b	CAPEL SOUND	3940	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	wadPNCbSgrRhSFB	Tootgarook Ward	VIC324	NEPEAN	VIC396	EASTERN VICTORIA
776044	GAVIC421300189	loc6280f9052ec0	NARRE WARREN SOUTH	3805	VIC	VIC47	BRUCE	lga891e1f62b45e	Casey	wad-Zifaq6Gq01M	Casuarina Ward	VIC323	NARRE WARREN SOUTH	VIC393	SOUTH-EASTERN METROPOLITAN
754869	GAVIC423874856	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
1225201	GAVIC421300826	locf066999b6a14	HALLAM	3803	VIC	VIC47	BRUCE	lga891e1f62b45e	Casey	wadzmgLpWoSfrcA	Waratah Ward	VIC322	NARRE WARREN NORTH	VIC393	SOUTH-EASTERN METROPOLITAN
2462005	GAVIC719607123	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3495778	GAVIC421524934	loc4195fdfecc8e	GARDENVALE	3185	VIC	VIC60	GOLDSTEIN	lga9bd137c30d17	Glen Eira	wad1u0ukfvW35MB	Orrong Ward	VIC370	CAULFIELD	VIC394	SOUTHERN METROPOLITAN
2649106	GAVIC421281678	loc4ff8c926c940	ASHWOOD	3147	VIC	VIC50	CHISHOLM	lga15c9c80d4be7	Monash	wadTfHiT64vDmQ1	Gardiners Creek Ward	VIC354	ASHWOOD	VIC394	SOUTHERN METROPOLITAN
1672137	GAVIC420191477	loc875118ed8437	FITZROY	3065	VIC	VIC75	MELBOURNE	lga4449559268d6	Yarra	wadJuReK-oSjcph	Mackillop Ward	VIC335	RICHMOND	VIC398	NORTHERN METROPOLITAN
557263	GAVIC424637478	loc2d817b7080e2	MALVERN EAST	3145	VIC	VIC50	CHISHOLM	lgae1dcbacb8510	Stonnington	wadGRxTsj9GscKr	Malvern Valley Ward	VIC310	MALVERN	VIC394	SOUTHERN METROPOLITAN
3195319	GAVIC423490362	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
67933	GAVIC423401833	loc1c5f2c23fc52	TOWONG	3707	VIC	VIC65	INDI	lga6ede3850c9ef	Towong	wad4e5a13c9f650	Towong Shire	VIC358	BENAMBRA	VIC392	NORTHERN VICTORIA
191799	GAVIC420048609	locf51f6cd689bb	SOUTH MELBOURNE	3205	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wadb7KdXAavZi4R	Montague Ward	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
685576	GAVIC421612837	locbd7d4fd6b9e7	COBURG	3058	VIC	VIC81	WILLS	lgaJ2LPN2y4pll0	Merri-Bek	wad302S-MiFLVrK	Harmony Park Ward	VIC330	PASCOE VALE	VIC398	NORTHERN METROPOLITAN
2583608	GAVIC721476998	loc3319215a0a10	BRIGHTON	3186	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad086a5a9284d6	Dendy Ward	VIC364	BRIGHTON	VIC394	SOUTHERN METROPOLITAN
605999	GAVIC424034425	locf066999b6a14	HALLAM	3803	VIC	VIC47	BRUCE	lga891e1f62b45e	Casey	wadzmgLpWoSfrcA	Waratah Ward	VIC322	NARRE WARREN NORTH	VIC393	SOUTH-EASTERN METROPOLITAN
2968341	GAVIC423215409	locfe955a87410d	ST KILDA	3182	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad49OyljM8Of_R	St Kilda Ward	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
880693	GAVIC721369066	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
2544628	GAVIC424551158	loc245c69160468	HEPBURN	3461	VIC	VIC45	BALLARAT	lga90413c6e7ea0	Hepburn	wad6Tj4-86FeWqd	Hepburn Shire	VIC309	MACEDON	VIC392	NORTHERN VICTORIA
2393739	GAVIC411803305	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
1176777	GAVIC411441273	locadc5cabaa80e	GLEN IRIS	3146	VIC	VIC68	KOOYONG	lgae1dcbacb8510	Stonnington	wadTbedye7mfV-b	Wattletree Ward	VIC310	MALVERN	VIC394	SOUTHERN METROPOLITAN
2619546	GAVIC421379520	locfd8472c41cbe	ROWVILLE	3178	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wadeaa4b13b2374	Tirhatuan Ward	VIC338	ROWVILLE	VIC393	SOUTH-EASTERN METROPOLITAN
2401644	GAVIC720126989	locabdfa0718385	KURUNJANG	3337	VIC	VIC62	HAWKE	lga42b2fd54c1e9	Melton	wadt8bYJfCSBAB1	Stringybark Ward	VIC312	MELTON	VIC399	WESTERN VICTORIA
1258199	GAVIC425157653	locf51f6cd689bb	SOUTH MELBOURNE	3205	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wadb7KdXAavZi4R	Montague Ward	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
634322	GAVIC413630613	loc2f9c80de6f7d	BAYSWATER	3153	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wade5ae1544c76a	Dinsdale Ward	VIC356	BAYSWATER	VIC397	NORTH-EASTERN METROPOLITAN
1011923	GAVIC421143250	loc36422efcb9c0	CLIFTON SPRINGS	3222	VIC	VIC52	CORANGAMITE	lga227fb535494c	Greater Geelong	wad5M41RFN1lqIK	Leopold Ward	VIC357	BELLARINE	VIC399	WESTERN VICTORIA
986886	GAVIC423406602	loc5c94ac6107ca	FLINDERS	3929	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	waddL6bRNz6XgeX	Coolart Ward	VIC324	NEPEAN	VIC396	EASTERN VICTORIA
233680	GAVIC423401116	loc8a2c57a8fa9c	LEITCHVILLE	3567	VIC	VIC72	MALLEE	lga0061bf039442	Loddon	wadf5b958023ee2	Terrick Ward	VIC320	MURRAY PLAINS	VIC392	NORTHERN VICTORIA
2190434	GAVIC420949509	locdf0288b649a4	WODONGA	3690	VIC	VIC65	INDI	lga79b8fe15ee4f	Wodonga	wadGqfgKOwrYnpj	Lake Hume Ward	VIC358	BENAMBRA	VIC392	NORTHERN VICTORIA
1839911	GAVIC720132188	loc5ba812288f5b	LEOPOLD	3224	VIC	VIC52	CORANGAMITE	lga227fb535494c	Greater Geelong	wad5M41RFN1lqIK	Leopold Ward	VIC357	BELLARINE	VIC399	WESTERN VICTORIA
664649	GAVIC419645242	loc86cf2bd4847b	CARNEGIE	3163	VIC	VIC64	HOTHAM	lga9bd137c30d17	Glen Eira	wadUipm-KKhjrfJ	Murrumbeena Ward	VIC327	OAKLEIGH	VIC394	SOUTHERN METROPOLITAN
904051	GAVIC420610243	loc22c42e389de3	SOUTH MORANG	3752	VIC	VIC79	SCULLIN	lgaa0f71a56be3f	Whittlesea	wadQ7y0_YB6rXPF	Epping Ward	VIC314	MILL PARK	VIC397	NORTH-EASTERN METROPOLITAN
3102116	GAVIC421658800	locba8f7a4a0c92	BARANDUDA	3691	VIC	VIC65	INDI	lga79b8fe15ee4f	Wodonga	wad6bqrBKnATSMy	Baranduda Range Ward	VIC358	BENAMBRA	VIC392	NORTHERN VICTORIA
1375277	GAVIC421147883	loc12c0177d3d38	PASCOE VALE	3044	VIC	VIC81	WILLS	lgaJ2LPN2y4pll0	Merri-Bek	wad10bOEnGsV8dy	Djirri-Djirri Ward	VIC330	PASCOE VALE	VIC398	NORTHERN METROPOLITAN
2984131	GAVIC420833582	loc51ba976fe589	OAK PARK	3046	VIC	VIC73	MARIBYRNONG	lgaJ2LPN2y4pll0	Merri-Bek	wad10bOEnGsV8dy	Djirri-Djirri Ward	VIC365	BROADMEADOWS	VIC398	NORTHERN METROPOLITAN
1352880	GAVIC721284836	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3600602	GAVIC424877747	loc92bf5bc798e7	FLEMINGTON	3031	VIC	VIC73	MARIBYRNONG	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC377	ESSENDON	VIC398	NORTHERN METROPOLITAN
3861486	GAVIC419943868	loc0a03ed3531fd	CHELTENHAM	3192	VIC	VIC66	ISAACS	lga691f580f3258	Kingston	wadc4d2321c51cd	Wattle Ward	VIC371	CLARINDA	VIC393	SOUTH-EASTERN METROPOLITAN
1258437	GAVIC421756773	locb8f595af5fb8	WHEELERS HILL	3150	VIC	VIC50	CHISHOLM	lga15c9c80d4be7	Monash	wad_afsMdcZSJAn	Waverley Park Ward	VIC319	MULGRAVE	VIC393	SOUTH-EASTERN METROPOLITAN
3051492	GAVIC424777831	locb281644d861d	BELGRAVE SOUTH	3160	VIC	VIC49	CASEY	lgadbd419ff24e3	Yarra Ranges	wad9815aa1d069f	Lyster Ward	VIC315	MONBULK	VIC396	EASTERN VICTORIA
2862740	GAVIC423394320	loc5e68bb81d75d	OAKVALE	3540	VIC	VIC72	MALLEE	lga292a6552ec8c	Gannawarra	waddSLcadpqglEJ	Gannawarra Shire	VIC320	MURRAY PLAINS	VIC392	NORTHERN VICTORIA
1327688	GAVIC420454965	loc67d2e4d427ab	PORTSEA	3944	VIC	VIC56	FLINDERS	lga69684c885dd2	Mornington Peninsula	wad869d0407f3ba	Nepean Ward	VIC324	NEPEAN	VIC396	EASTERN VICTORIA
802047	GAVIC719913448	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
1089845	GAVIC421242246	loc201e214973bd	IVANHOE	3079	VIC	VIC67	JAGAJAGA	lga5591321694d6	Banyule	wad3b3c629a6f23	Chelsworth Ward	VIC390	IVANHOE	VIC397	NORTH-EASTERN METROPOLITAN
1830845	GAVIC419618007	loc656f84726510	RESERVOIR	3073	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wad9576ecab049a	North East Ward	VIC334	PRESTON	VIC398	NORTHERN METROPOLITAN
1815609	GAVIC719413114	locb948618ae376	SEBASTOPOL	3356	VIC	VIC45	BALLARAT	lgab70a9914e5bc	Ballarat	wadyjJCxzyN4pyg	Golden Point Ward	VIC349	WENDOUREE	VIC399	WESTERN VICTORIA
3064622	GAVIC412717346	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
773086	GAVIC424263462	loc5e975e2e1c0e	TRAFALGAR	3824	VIC	VIC77	MONASH	lga77d96c3addfd	Baw Baw	wad42e6aa4ccc5b	East Ward	VIC321	NARRACAN	VIC396	EASTERN VICTORIA
1821038	GAVIC424246587	locd724f9a08a75	WARRAGUL	3820	VIC	VIC77	MONASH	lga77d96c3addfd	Baw Baw	wad8e9b046d6253	Central Ward	VIC321	NARRACAN	VIC396	EASTERN VICTORIA
3627481	GAVIC419802779	locec99dd6d0979	ALTONA MEADOWS	3028	VIC	VIC58	GELLIBRAND	lga224186279c28	Hobsons Bay	wadM6fFaXdiVDBj	Laverton Ward	VIC331	POINT COOK	VIC395	WESTERN METROPOLITAN
2781508	GAVIC424917511	loc4161e46afd2f	BEVERIDGE	3753	VIC	VIC74	MCEWEN	lgaae260494d80c	Mitchell	wad9ac23ae23a13	South Ward	VIC391	KALKALLO	VIC398	NORTHERN METROPOLITAN
2976825	GAVIC420703086	loc913bf4728c4e	CAMBERWELL	3124	VIC	VIC68	KOOYONG	lga0930e8ebad68	Boroondara	wada3ca41faf88e	Lynden Ward	VIC389	HAWTHORN	VIC394	SOUTHERN METROPOLITAN
1551756	GAVIC421444901	loc3b583afba248	SPRINGVALE SOUTH	3172	VIC	VIC66	ISAACS	lgab65bc8ec7820	Greater Dandenong	wad84f8c3ad8ad9	Springvale South Ward	VIC371	CLARINDA	VIC393	SOUTH-EASTERN METROPOLITAN
2724207	GAVIC419784186	locc0b6d754799e	CRANBOURNE	3977	VIC	VIC63	HOLT	lga891e1f62b45e	Casey	wadAPt6k3MRzlsb	Correa Ward	VIC372	CRANBOURNE	VIC393	SOUTH-EASTERN METROPOLITAN
1251669	GAVIC412676699	loc0de2086617a5	EVERTON	3678	VIC	VIC65	INDI	lgabff52ad8fdf9	Wangaratta	wadNQf3aLZQ6qje	Ovens Ward	VIC328	OVENS VALLEY	VIC392	NORTHERN VICTORIA
1774161	GAVIC425274882	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
77523	GAVIC412527335	loc4a341f4d3e02	WANTIRNA	3152	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wadcfea20d05544	Collier Ward	VIC356	BAYSWATER	VIC397	NORTH-EASTERN METROPOLITAN
2083265	GAVIC719010591	loc1e06c486c813	NORTH MELBOURNE	3051	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3541497	GAVIC424675889	locff62fb6a898a	CARRUM DOWNS	3201	VIC	VIC55	DUNKLEY	lgadd7fe82edc77	Frankston	wadogU04oDrKKlP	Lyrebird Ward	VIC369	CARRUM	VIC393	SOUTH-EASTERN METROPOLITAN
2857353	GAVIC420695756	loc3754c5fc3408	ROXBURGH PARK	3064	VIC	VIC48	CALWELL	lga3476c1d9fd7f	Hume	wadHld8m0wD7Ey9	Roxburgh Park Ward	VIC387	GREENVALE	VIC398	NORTHERN METROPOLITAN
3098930	GAVIC424684358	locb8f595af5fb8	WHEELERS HILL	3150	VIC	VIC64	HOTHAM	lga15c9c80d4be7	Monash	wadaxLPH8xNPb2d	Jells Ward	VIC319	MULGRAVE	VIC393	SOUTH-EASTERN METROPOLITAN
1341538	GAVIC420921756	loc1eda86883ae9	SUNDERLAND BAY	3922	VIC	VIC77	MONASH	lgaac2e88625ea2	Bass Coast	wadbc805720b430	Island Ward	VIC355	BASS	VIC396	EASTERN VICTORIA
3550786	GAVIC419780964	locb344fc28a060	PEARCEDALE	3912	VIC	VIC63	HOLT	lga891e1f62b45e	Casey	wad6sK7FI4NeSmJ	Cranbourne Gardens Ward	VIC355	BASS	VIC396	EASTERN VICTORIA
878321	GAVIC719096818	loc1e06c486c813	NORTH MELBOURNE	3051	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
2080653	GAVIC424727151	locc5abea08e85d	POINT COOK	3030	VIC	VIC58	GELLIBRAND	lga53026dafea91	Wyndham	wad8Xd3NHzIUcZi	Cheetham Ward	VIC331	POINT COOK	VIC395	WESTERN METROPOLITAN
504307	GAVIC420390898	loc9fe59dbd0874	CRANBOURNE NORTH	3977	VIC	VIC63	HOLT	lga891e1f62b45e	Casey	wad6a6c459fc221	River Gum Ward	VIC323	NARRE WARREN SOUTH	VIC393	SOUTH-EASTERN METROPOLITAN
2857507	GAVIC720743838	loc6a54ce63b777	WINTER VALLEY	3358	VIC	VIC45	BALLARAT	lgab70a9914e5bc	Ballarat	wadxupXdB4SFZlj	Delacombe Ward	VIC349	WENDOUREE	VIC399	WESTERN VICTORIA
2422681	GAVIC719115528	loca5de38b84720	BOX HILL	3128	VIC	VIC76	MENZIES	lga0450031d71ce	Whitehorse	wad6687dc63caac	Elgar Ward	VIC363	BOX HILL	VIC397	NORTH-EASTERN METROPOLITAN
424898	GAVIC420732404	loc4e07cec4cde4	NARRE WARREN EAST	3804	VIC	VIC49	CASEY	lgadbd419ff24e3	Yarra Ranges	wad9815aa1d069f	Lyster Ward	VIC315	MONBULK	VIC396	EASTERN VICTORIA
2415090	GAVIC425461232	locc2ea2de6af6c	SOUTH YARRA	3141	VIC	VIC75	MELBOURNE	lgae1dcbacb8510	Stonnington	wad5ABFHeA5kyfo	South Yarra Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
2135650	GAVIC412674706	loc09a99bf786b9	KILLAWARRA	3678	VIC	VIC65	INDI	lgabff52ad8fdf9	Wangaratta	wadNQf3aLZQ6qje	Ovens Ward	VIC328	OVENS VALLEY	VIC392	NORTHERN VICTORIA
2819992	GAVIC425231579	loc9ea2b366d63f	CRANBOURNE WEST	3977	VIC	VIC63	HOLT	lga891e1f62b45e	Casey	wadeRHdijIY343D	Quarters Ward	VIC372	CRANBOURNE	VIC393	SOUTH-EASTERN METROPOLITAN
3600930	GAVIC412227164	locfd8472c41cbe	ROWVILLE	3178	VIC	VIC44	ASTON	lgaacfaedf6a58f	Knox	wadef545fe30498	Taylor Ward	VIC338	ROWVILLE	VIC393	SOUTH-EASTERN METROPOLITAN
2022450	GAVIC425028781	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
410535	GAVIC721704334	locf51f6cd689bb	SOUTH MELBOURNE	3205	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wadyBOUDailkzZ2	South Melbourne Ward	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
3824937	GAVIC425093622	loca5643321b976	FIERY FLAT	3518	VIC	VIC72	MALLEE	lga0061bf039442	Loddon	wad7ffea4a2d5e2	Wedderburn Ward	VIC337	RIPON	VIC399	WESTERN VICTORIA
1926011	GAVIC421109751	loc74f8893fb76e	BROADMEADOWS	3047	VIC	VIC48	CALWELL	lga3476c1d9fd7f	Hume	wadXsV2_er3gqTy	Merlynston Creek Ward	VIC365	BROADMEADOWS	VIC398	NORTHERN METROPOLITAN
1175326	GAVIC421731563	loc29a798d6921b	WERRIBEE	3030	VIC	VIC70	LALOR	lga53026dafea91	Wyndham	wadD3yldScPPI45	Heathdale Ward	VIC350	WERRIBEE	VIC395	WESTERN METROPOLITAN
488456	GAVIC420757091	loc79e45c9fa669	BRUNSWICK EAST	3057	VIC	VIC81	WILLS	lgaJ2LPN2y4pll0	Merri-Bek	wadlMZ140e5e2tn	Warrk-Warrk Ward	VIC366	BRUNSWICK	VIC398	NORTHERN METROPOLITAN
3928859	GAVIC421458512	loce6098ac5df0c	BENDIGO	3550	VIC	VIC46	BENDIGO	lga575ae7e97596	Greater Bendigo	wadYMFosQIy2siY	Lake Weeroona Ward	VIC360	BENDIGO WEST	VIC392	NORTHERN VICTORIA
2356941	GAVIC420773569	loca307cf61ba97	KINGS PARK	3021	VIC	VIC61	GORTON	lgaf76bb579e827	Brimbank	waddDVaCDsFNYe0	Albanvale Ward	VIC305	KOROROIT	VIC395	WESTERN METROPOLITAN
3867532	GAVIC423669472	loc2c4c767ea9b7	PRESTON	3072	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wad4964b853357e	West Ward	VIC334	PRESTON	VIC398	NORTHERN METROPOLITAN
2091572	GAVIC421674160	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
1033981	GAVIC420205676	loca4e166a620d9	NOBLE PARK	3174	VIC	VIC66	ISAACS	lgab65bc8ec7820	Greater Dandenong	wad1ad3a9f03b24	Noble Park Ward	VIC374	DANDENONG	VIC393	SOUTH-EASTERN METROPOLITAN
1717275	GAVIC423398421	loc6c0f29d040f7	TORRUMBARRY	3562	VIC	VIC78	NICHOLLS	lgaf4d7671cd990	Campaspe	wad-_EZ61IArian	Campaspe Shire	VIC320	MURRAY PLAINS	VIC392	NORTHERN VICTORIA
1559147	GAVIC719420229	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wadyBOUDailkzZ2	South Melbourne Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
2960150	GAVIC425285314	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
1962891	GAVIC719988843	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
3469012	GAVIC719537604	loc8e5a2b16aaaa	TRARALGON	3844	VIC	VIC59	GIPPSLAND	lga5e8f0b6a35b1	Latrobe	wadtyGwzL6YJLXL	Jeeralang Ward	VIC318	MORWELL	VIC396	EASTERN VICTORIA
3650727	GAVIC419811494	loc46f8f01fbac9	RINGWOOD EAST	3135	VIC	VIC54	DEAKIN	lgafa7d75c94e0c	Maroondah	wade54a601add90	Wombolano Ward	VIC336	RINGWOOD	VIC397	NORTH-EASTERN METROPOLITAN
3884600	GAVIC719539171	loce16236caf708	LARA	3212	VIC	VIC53	CORIO	lga227fb535494c	Greater Geelong	wadzWnDzRGqmtuN	You Yangs Ward	VIC306	LARA	VIC399	WESTERN VICTORIA
1477342	GAVIC423280693	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
2172104	GAVIC411825992	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wadyBOUDailkzZ2	South Melbourne Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
531684	GAVIC420787418	loce42a110faa48	HAMPTON	3188	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad4c653401ab5d	Castlefield Ward	VIC364	BRIGHTON	VIC394	SOUTHERN METROPOLITAN
1964844	GAVIC423632802	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3864043	GAVIC420900117	locd665688d0e4d	PORTLAND	3305	VIC	VIC80	WANNON	lga26260a89bb1b	Glenelg	wad11cce03bd400	Glenelg Shire	VIC342	SOUTH-WEST COAST	VIC399	WESTERN VICTORIA
1278941	GAVIC420135739	locfdc6079b562f	ASCOT VALE	3032	VIC	VIC73	MARIBYRNONG	lga638d2708b9ab	Moonee Valley	wadOnh5Z0A-KLO_	Fairbairn Ward	VIC377	ESSENDON	VIC398	NORTHERN METROPOLITAN
3711055	GAVIC420083984	loc7213d03738b9	FAWKNER	3060	VIC	VIC81	WILLS	lgaJ2LPN2y4pll0	Merri-Bek	wadWaFpW6GZfIhW	Bababi Djinanang Ward	VIC365	BROADMEADOWS	VIC398	NORTHERN METROPOLITAN
2712671	GAVIC419620282	loceac5d85ea01d	WYNDHAM VALE	3024	VIC	VIC70	LALOR	lga53026dafea91	Wyndham	wadc4af85febd67	Iramoo Ward	VIC350	WERRIBEE	VIC395	WESTERN METROPOLITAN
2023113	GAVIC423444001	loca0398a35cf5e	CARLTON	3053	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
3394274	GAVIC423623835	loc1e06c486c813	NORTH MELBOURNE	3051	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
457118	GAVIC425486221	loc108a649ba4ae	TARILTA	3451	VIC	VIC45	BALLARAT	lga90413c6e7ea0	Hepburn	wad6Tj4-86FeWqd	Hepburn Shire	VIC309	MACEDON	VIC392	NORTHERN VICTORIA
1753556	GAVIC424478303	locc2ea2de6af6c	SOUTH YARRA	3141	VIC	VIC75	MELBOURNE	lgae1dcbacb8510	Stonnington	wadSdQj5ZcEpUYw	Como Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
1626398	GAVIC421995183	loc17a18f5ff3a6	CAROLINE SPRINGS	3023	VIC	VIC61	GORTON	lga42b2fd54c1e9	Melton	waddc89uz_zLf_D	Lake Caroline Ward	VIC305	KOROROIT	VIC395	WESTERN METROPOLITAN
1853912	GAVIC423648049	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
1121944	GAVIC719309027	loc90b2f4dd8c2d	MOUNT DUNEED	3217	VIC	VIC52	CORANGAMITE	lga227fb535494c	Greater Geelong	wadWc0RZDpevyBq	Deakin Ward	VIC341	SOUTH BARWON	VIC399	WESTERN VICTORIA
1251914	GAVIC420257417	loc0b665c0fe535	OCEAN GROVE	3226	VIC	VIC52	CORANGAMITE	lga227fb535494c	Greater Geelong	wadHD-xGynvazEU	Connewarre Ward	VIC357	BELLARINE	VIC399	WESTERN VICTORIA
868544	GAVIC425008870	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
2677519	GAVIC424667096	locc5abea08e85d	POINT COOK	3030	VIC	VIC58	GELLIBRAND	lga53026dafea91	Wyndham	wadIisBVS3hc3vA	Featherbrook Ward	VIC331	POINT COOK	VIC395	WESTERN METROPOLITAN
200198	GAVIC719622334	loccbfe7d3f7b9f	ELSTERNWICK	3185	VIC	VIC60	GOLDSTEIN	lga9bd137c30d17	Glen Eira	wad1u0ukfvW35MB	Orrong Ward	VIC370	CAULFIELD	VIC394	SOUTHERN METROPOLITAN
3556956	GAVIC423935363	locff58d0167065	BENALLA	3672	VIC	VIC65	INDI	lga6f3147bcaaee	Benalla	wadf0f7e80f56a5	Benalla Rural City	VIC379	EUROA	VIC392	NORTHERN VICTORIA
959965	GAVIC423404123	loc991c414cb6c9	UPPER PLENTY	3756	VIC	VIC74	MCEWEN	lgaae260494d80c	Mitchell	wad8c29bdb30e60	Central Ward	VIC352	YAN YEAN	VIC392	NORTHERN VICTORIA
1237482	GAVIC721289923	loce42a110faa48	HAMPTON	3188	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad402ca2ca8a7a	Boyd Ward	VIC339	SANDRINGHAM	VIC394	SOUTHERN METROPOLITAN
2677894	GAVIC421774336	locd8470b65d64b	BENTLEIGH	3204	VIC	VIC60	GOLDSTEIN	lga9bd137c30d17	Glen Eira	wadj89dtxG4ZPmY	Moorleigh Ward	VIC361	BENTLEIGH	VIC394	SOUTHERN METROPOLITAN
60662	GAVIC411935231	loc20a81a4bf246	MOUNT EVELYN	3796	VIC	VIC49	CASEY	lgadbd419ff24e3	Yarra Ranges	wadafc695e2558b	Chandler Ward	VIC380	EVELYN	VIC396	EASTERN VICTORIA
710555	GAVIC719207295	loc9a48431374e1	PORT MELBOURNE	3207	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wadb7KdXAavZi4R	Montague Ward	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
2838463	GAVIC423643559	locb71d10cf3b7c	MILDURA	3500	VIC	VIC72	MALLEE	lgaee4000c6a5c1	Mildura	wadaC4rKKejsES3	Mildura Wetlands Ward	VIC313	MILDURA	VIC392	NORTHERN VICTORIA
349553	GAVIC423911067	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wadyBOUDailkzZ2	South Melbourne Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
2472177	GAVIC420148109	loca674ab421c49	EUROA	3666	VIC	VIC65	INDI	lga7831afcaf1e2	Strathbogie	wado4SJap0btdNC	Strathbogie Shire	VIC379	EUROA	VIC392	NORTHERN VICTORIA
1050076	GAVIC423620402	loc1e06c486c813	NORTH MELBOURNE	3051	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
2226295	GAVIC421838556	loc0067a4549ed1	KORUMBURRA	3950	VIC	VIC77	MONASH	lga5c66b4f8531c	South Gippsland	wad361ad2280132	Strzelecki Ward	VIC385	GIPPSLAND SOUTH	VIC396	EASTERN VICTORIA
3551243	GAVIC423110860	loc1a22f173d7f3	JUNCTION VILLAGE	3977	VIC	VIC63	HOLT	lga891e1f62b45e	Casey	wad6sK7FI4NeSmJ	Cranbourne Gardens Ward	VIC372	CRANBOURNE	VIC393	SOUTH-EASTERN METROPOLITAN
1169775	GAVIC425480664	locb9872f35df41	ABBOTSFORD	3067	VIC	VIC75	MELBOURNE	lga4449559268d6	Yarra	wadgRo9qUAhAfJZ	Boulevard Ward	VIC335	RICHMOND	VIC398	NORTHERN METROPOLITAN
2854067	GAVIC420058003	locbcb60f6b546d	LANGWARRIN	3910	VIC	VIC55	DUNKLEY	lgadd7fe82edc77	Frankston	wadb6eT0ZIAcbRV	Centenary Park Ward	VIC388	HASTINGS	VIC396	EASTERN VICTORIA
3277363	GAVIC719424466	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wadyBOUDailkzZ2	South Melbourne Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
1379855	GAVIC719111600	loc86b22e8e6ecf	EAST BENDIGO	3550	VIC	VIC46	BENDIGO	lga575ae7e97596	Greater Bendigo	wadYMFosQIy2siY	Lake Weeroona Ward	VIC359	BENDIGO EAST	VIC392	NORTHERN VICTORIA
1686818	GAVIC421481958	loc08caad3924ee	ALTONA NORTH	3025	VIC	VIC58	GELLIBRAND	lga224186279c28	Hobsons Bay	wadlgX-ru5ZxVr3	Altona North Ward	VIC351	WILLIAMSTOWN	VIC395	WESTERN METROPOLITAN
\.




-- ============================================

-- ============================================
-- PART 2B: Raw table data (for flatten pipeline)
-- ============================================

-- raw_gnaf_202602.flat_type_aut: 54 rows
\copy raw_gnaf_202602.flat_type_aut FROM stdin
ATM	AUTOMATED TELLER MACHINE	AUTOMATED TELLER MACHINE
BTSD	BOATSHED	BOATSHED
COOL	COOLROOM	COOLROOM
DUPL	DUPLEX	DUPLEX
FCTY	FACTORY	FACTORY
FLAT	FLAT	FLAT
LBBY	LOBBY	LOBBY
LOFT	LOFT	LOFT
MBTH	MARINE BERTH	MARINE BERTH
OFFC	OFFICE	OFFICE
RESV	RESERVE	RESERVE
ROOM	ROOM	ROOM
STLL	STALL	STALL
STOR	STORE	STORE
STR	STRATA UNIT	STRATA UNIT
UNIT	UNIT	UNIT
WHSE	WAREHOUSE	WAREHOUSE
WKSH	WORKSHOP	WORKSHOP
ANT	ANTENNA	ANTENNA
APT	APARTMENT	APARTMENT
BBQ	BARBECUE	BARBECUE
BLCK	BLOCK	BLOCK
BLDG	BUILDING	BUILDING
BNGW	BUNGALOW	BUNGALOW
CAGE	CAGE	CAGE
CARP	CARPARK	CARPARK
CARS	CARSPACE	CARSPACE
CLUB	CLUB	CLUB
CTGE	COTTAGE	COTTAGE
GRGE	GARAGE	GARAGE
HALL	HALL	HALL
HSE	HOUSE	HOUSE
KSK	KIOSK	KIOSK
LOT	LOT	LOT
LSE	LEASE	LEASE
MSNT	MAISONETTE	MAISONETTE
PTHS	PENTHOUSE	PENTHOUSE
REAR	REAR	REAR
SE	SUITE	SUITE
SEC	SECTION	SECTION
SHED	SHED	SHED
SHOP	SHOP	SHOP
SHRM	SHOWROOM	SHOWROOM
SIGN	SIGN	SIGN
SITE	SITE	SITE
STU	STUDIO	STUDIO
SUBS	SUBSTATION	SUBSTATION
TNCY	TENANCY	TENANCY
TNHS	TOWNHOUSE	TOWNHOUSE
TWR	TOWER	TOWER
VLLA	VILLA	VILLA
VLT	VAULT	VAULT
WARD	WARD	WARD
RTCE	ROOF TERRACE	ROOF TERRACE
\.

-- raw_gnaf_202602.level_type_aut: 16 rows
\copy raw_gnaf_202602.level_type_aut FROM stdin
OD	OBSERVATION DECK	OBSERVATION DECK
P	PARKING	PARKING
PDM	PODIUM	PODIUM
PLF	PLATFORM	PLATFORM
PTHS	PENTHOUSE	PENTHOUSE
SB	SUB-BASEMENT	SUB-BASEMENT
B	BASEMENT	BASEMENT
FL	FLOOR	FLOOR
G	GROUND	GROUND
L	LEVEL	LEVEL
LB	LOBBY	LOBBY
LG	LOWER GROUND FLOOR	LOWER GROUND FLOOR
M	MEZZANINE	MEZZANINE
RT	ROOFTOP	ROOFTOP
UG	UPPER GROUND FLOOR	UPPER GROUND FLOOR
UNGD	UNDERGROUND	UNDERGROUND
\.

-- raw_gnaf_202602.street_type_aut: 276 rows
\copy raw_gnaf_202602.street_type_aut FROM stdin
EAST	EAST	EAST
WEST	WEST	WEST
PART	PART	PART
TRIANGLE	TRIANGLE	TRIANGLE
AIRWALK	AWLK	AIRWALK
PRECINCT	PREC	PREC
SHUNT	SHUN	SHUN
ARTERIAL	ARTL	ARTL
BANAN	BA	BA
RIGHT OF WAY	ROFW	ROFW
ACRE	ACRE	ACRE
WOOD	WD	WD
BULL	BULL	BULL
VILLA	VLLA	VLLA
TRAVERSE	TVSE	TVSE
MART	MART	MART
ACCESS	ACCS	ACCS
ALLEY	ALLY	ALLY
ALLEYWAY	ALWY	ALWY
AMBLE	AMBL	AMBL
APPROACH	APP	APP
ARCADE	ARC	ARC
ARTERY	ARTY	ARTY
AVENUE	AV	AV
BANK	BANK	BANK
BAY	BAY	BAY
BEACH	BCH	BCH
BEND	BEND	BEND
BOARDWALK	BWLK	BWLK
BOULEVARD	BVD	BVD
BOULEVARDE	BVDE	BVDE
BOWL	BOWL	BOWL
BRACE	BR	BR
BRAE	BRAE	BRAE
BRANCH	BRAN	BRAN
BREAK	BRK	BRK
BRETT	BRET	BRET
BRIDGE	BDGE	BDGE
BROADWALK	BRDWLK	BRDWLK
BROADWAY	BDWY	BDWY
BROW	BROW	BROW
BYPASS	BYPA	BYPA
BYWAY	BYWY	BYWY
CAUSEWAY	CSWY	CSWY
CENTRE	CTR	CTR
CENTREWAY	CNWY	CNWY
CHASE	CH	CH
CIRCLE	CIR	CIR
CIRCLET	CLT	CLT
CIRCUIT	CCT	CCT
CIRCUS	CRCS	CRCS
CLOSE	CL	CL
CLUSTER	CLR	CLR
COLONNADE	CLDE	CLDE
COMMON	CMMN	CMMN
COMMONS	CMMNS	CMMNS
CONCORD	CNCD	CNCD
CONCOURSE	CON	CON
CONNECTION	CNTN	CNTN
COPSE	CPS	CPS
CORNER	CNR	CNR
CORSO	CSO	CSO
COURSE	CRSE	CRSE
COURT	CT	CT
COURTYARD	CTYD	CTYD
COVE	COVE	COVE
CRESCENT	CR	CR
CREST	CRST	CRST
CRIEF	CRF	CRF
CROOK	CRK	CRK
CROSS	CRSS	CRSS
CROSSING	CRSG	CRSG
CRUISEWAY	CUWY	CUWY
CUL-DE-SAC	CSAC	CSAC
CUT	CUT	CUT
CUTTING	CUTT	CUTT
DALE	DALE	DALE
DELL	DELL	DELL
DENE	DENE	DENE
DEVIATION	DE	DE
DIP	DIP	DIP
DISTRIBUTOR	DSTR	DSTR
DIVIDE	DIV	DIV
DOCK	DOCK	DOCK
DOMAIN	DOM	DOM
DOWN	DOWN	DOWN
DOWNS	DWNS	DWNS
DRIVE	DR	DR
DRIVEWAY	DVWY	DVWY
EASEMENT	ESMT	ESMT
EDGE	EDGE	EDGE
ELBOW	ELB	ELB
END	END	END
ENTRANCE	ENT	ENT
ESPLANADE	ESP	ESP
ESTATE	EST	EST
EXPRESSWAY	EXP	EXP
EXTENSION	EXTN	EXTN
FAIRWAY	FAWY	FAWY
FIREBREAK	FBRK	FBRK
FIRELINE	FLNE	FLNE
FIRETRACK	FTRK	FTRK
FIRETRAIL	FITR	FITR
FLAT	FLAT	FLAT
FOLLOW	FOLW	FOLW
FOOTWAY	FTWY	FTWY
FORD	FORD	FORD
FORESHORE	FSHR	FSHR
FORK	FORK	FORK
FORMATION	FORM	FORM
FREEWAY	FWY	FWY
FRONT	FRNT	FRNT
FRONTAGE	FRTG	FRTG
GAP	GAP	GAP
GARDEN	GDN	GDN
GARDENS	GDNS	GDNS
GATE	GTE	GTE
GATEWAY	GWY	GWY
GLADE	GLDE	GLDE
GLEN	GLEN	GLEN
GRANGE	GRA	GRA
GREEN	GRN	GRN
GROVE	GR	GR
GULLY	GLY	GLY
HARBOUR	HRBR	HRBR
HAVEN	HVN	HVN
HEATH	HTH	HTH
HEIGHTS	HTS	HTS
HIGHROAD	HIRD	HIRD
HIGHWAY	HWY	HWY
HILL	HILL	HILL
HOLLOW	HLLW	HLLW
HUB	HUB	HUB
INLET	INLT	INLT
INTERCHANGE	INTG	INTG
ISLAND	ID	ID
JUNCTION	JNC	JNC
KEY	KEY	KEY
KEYS	KEYS	KEYS
KNOLL	KNOL	KNOL
LADDER	LADR	LADR
LANDING	LDG	LDG
LANE	LANE	LANE
LANEWAY	LNWY	LNWY
LEADER	LEDR	LEDR
LINE	LINE	LINE
LINK	LINK	LINK
LOOKOUT	LKT	LKT
LOOP	LOOP	LOOP
LYNNE	LYNN	LYNN
MALL	MALL	MALL
MANOR	MANR	MANR
MEAD	MEAD	MEAD
MEANDER	MNDR	MNDR
MEW	MEW	MEW
MEWS	MEWS	MEWS
MILE	MILE	MILE
MOTORWAY	MTWY	MTWY
NOOK	NOOK	NOOK
NORTH	NTH	NTH
NULL	NULL	NULL
OUTLET	OTLT	OTLT
OUTLOOK	OTLK	OTLK
OVAL	OVAL	OVAL
PALMS	PLMS	PLMS
PARADE	PDE	PDE
PARADISE	PRDS	PRDS
PARK	PARK	PARK
PARKWAY	PWY	PWY
PASS	PASS	PASS
PASSAGE	PSGE	PSGE
PATH	PATH	PATH
PATHWAY	PWAY	PWAY
PENINSULA	PSLA	PSLA
PIAZZA	PIAZ	PIAZ
PLACE	PL	PL
PLAZA	PLZA	PLZA
POCKET	PKT	PKT
POINT	PNT	PNT
PORT	PORT	PORT
PROMENADE	PROM	PROM
PURSUIT	PRST	PRST
QUAD	QUAD	QUAD
QUADRANT	QDRT	QDRT
QUAY	QY	QY
QUAYS	QYS	QYS
RAMBLE	RMBL	RMBL
RAMP	RAMP	RAMP
RANGE	RNGE	RNGE
REACH	RCH	RCH
REEF	REEF	REEF
RESERVE	RES	RES
REST	REST	REST
RETREAT	RTT	RTT
RETURN	RTN	RTN
RIDE	RIDE	RIDE
RIDGE	RDGE	RDGE
RING	RING	RING
RISE	RISE	RISE
RISING	RSNG	RSNG
RIVER	RVR	RVR
ROAD	RD	RD
ROADS	RDS	RDS
ROADWAY	RDWY	RDWY
ROTARY	RTY	RTY
ROUND	RND	RND
ROUTE	RTE	RTE
ROW	ROW	ROW
ROWE	ROWE	ROWE
RUE	RUE	RUE
RUN	RUN	RUN
SERVICEWAY	SVWY	SVWY
SKYLINE	SKLN	SKLN
SLOPE	SLPE	SLPE
SOUTH	STH	STH
SPUR	SPUR	SPUR
SQUARE	SQ	SQ
STEPS	STPS	STPS
STRAIGHT	STRT	STRT
STRAIT	STAI	STAI
STRAND	STRA	STRA
STREET	ST	ST
STRIP	STRP	STRP
SUBWAY	SBWY	SBWY
TARN	TARN	TARN
TERRACE	TCE	TCE
THOROUGHFARE	THFR	THFR
THROUGHWAY	THRU	THRU
TOLLWAY	TLWY	TLWY
TOP	TOP	TOP
TOR	TOR	TOR
TRACK	TRK	TRK
TRAIL	TRL	TRL
TRAMWAY	TMWY	TMWY
TRUNKWAY	TKWY	TKWY
TUNNEL	TUNL	TUNL
TURN	TURN	TURN
UNDERPASS	UPAS	UPAS
VALE	VALE	VALE
VALLEY	VLLY	VLLY
VERGE	VERGE	VERGE
VIADUCT	VIAD	VIAD
VIEW	VIEW	VIEW
VIEWS	VWS	VWS
VILLAGE	VLGE	VLGE
VILLAS	VLLS	VLLS
VISTA	VSTA	VSTA
VUE	VUE	VUE
WADE	WADE	WADE
WALK	WALK	WALK
WALKWAY	WKWY	WKWY
WATERS	WTRS	WTRS
WATERWAY	WTWY	WTWY
WAY	WAY	WAY
WHARF	WHRF	WHRF
WOODS	WDS	WDS
WYND	WYND	WYND
YARD	YARD	YARD
TWIST	TWIST	TWIST
DASH	DASH	DASH
HILLS	HILLS	HILLS
LEAD	LEAD	LEAD
BUSWAY	BSWY	BSWY
FLATS	FLTS	FLTS
MAZE	MZ	MZ
HIKE	HIKE	HIKE
CONNECTOR	CONR	CONR
BOUNDARY	BDY	BDY
CROSSOVER	CRVR	CRVR
LINKWAY	LNKWAY	LNKWAY
ANNEX	ANNEX	ANNEX
BIDI	BIDI	BIDI
YARDS	YARDS	YARDS
NEST	NEST	NEST
SIDING	SDNG	SDNG
PERCH	PRCH	PRCH
\.

-- raw_gnaf_202602.street_suffix_aut: 19 rows
\copy raw_gnaf_202602.street_suffix_aut FROM stdin
DE	DEVIATION	DEVIATION
OP	OVERPASS	OVERPASS
CN	CENTRAL	CENTRAL
E	EAST	EAST
EX	EXTENSION	EXTENSION
IN	INNER	INNER
LR	LOWER	LOWER
ML	MALL	MALL
N	NORTH	NORTH
NE	NORTH EAST	NORTH EAST
NW	NORTH WEST	NORTH WEST
OF	OFF	OFF
ON	ON	ON
OT	OUTER	OUTER
S	SOUTH	SOUTH
SE	SOUTH EAST	SOUTH EAST
SW	SOUTH WEST	SOUTH WEST
UP	UPPER	UPPER
W	WEST	WEST
\.

-- raw_gnaf_202602.geocode_type_aut: 30 rows
\copy raw_gnaf_202602.geocode_type_aut FROM stdin
CDF	CENTRE-LINE DROPPED FRONTAGE	A POINT ON THE ROAD CENTRE-LINE OPPOSITE THE CENTRE OF THE ROAD FRONTAGE OF AN ADDRESS SITE.
LB	LETTERBOX	PLACE WHERE MAIL IS DEPOSITED.
STL	STREET LOCALITY	POINT REPRESENTING THE EXTENT OF A STREET WITHIN A LOCALITY
LOC	LOCALITY	POINT REPRESENTING A LOCALITY
BAP	BUILDING ACCESS POINT	POINT OF ACCESS TO THE BUILDING.
BC	BUILDING CENTROID	POINT AS CENTRE OF BUILDING AND LYING WITHIN ITS BOUNDS (E.G. FOR U-SHAPED BUILDING).
DF	DRIVEWAY FRONTAGE	CENTRE OF DRIVEWAY ON ADDRESS SITE FRONTAGE.
EA	EMERGENCY ACCESS	SPECIFIC BUILDING OR PROPERTY ACCESS POINT FOR EMERGENCY SERVICES.
EAS	EMERGENCY ACCESS SECONDARY	SPECIFIC BUILDING OR PROPERTY SECONDARY ACCESS POINT FOR EMERGENCY SERVICES.
FDA	FRONT DOOR ACCESS	FRONT DOOR OF BUILDING.
FC	FRONTAGE CENTRE	POINT ON THE CENTRE OF THE ADDRESS SITE FRONTAGE.
FCS	FRONTAGE CENTRE SETBACK	A POINT SET BACK FROM THE CENTRE OF THE ROAD FRONTAGE WITHIN AN ADDRESS SITE.
PAP	PROPERTY ACCESS POINT	ACCESS POINT (CENTRE OF) AT THE ROAD FRONTAGE OF THE PROPERTY.
PAPS	PROPERTY ACCESS POINT SETBACK	A POINT SET BACK FROM THE (CENTRE OF THE) ACCESS POINT AT THE ROAD FRONTAGE OF THE PROPERTY.
PC	PROPERTY CENTROID	POINT OF CENTRE OF PARCELS MAKING UP A PROPERTY AND LYING WITHIN ITS BOUNDARIES (E.G. FOR L-SHAPED PROPERTY).
PCM	PROPERTY CENTROID MANUAL	POINT MANUALLY PLACED APPROXIMATELY AT CENTRE OF PARCELS MAKING UP A PROPERTY AND LYING WITHIN ITS BOUNDARIES (E.G. FOR L-SHAPED PROPERTY).
UC	UNIT CENTROID	POINT AT CENTRE OF UNIT AND LYING WITHIN ITS BOUNDS (E.G. FOR U-SHAPED UNIT).
UCM	UNIT CENTROID MANUAL	POINT MANUALLY PLACED APPROXIMATELY AT CENTRE OF UNIT AND LYING WITHIN ITS BOUNDS (E.G. FOR U-SHAPED UNIT).
GG	GAP GEOCODE	POINT PROGRAMMATICALLY ALLOCATED DURING THE G-NAF PRODUCTION PROCESS PROPORTIONALLY BETWEEN ADJACENT ADDRESS LOCATIONS (BASED ON NUMBER_FIRST).
WCP	WATER CONNECTION POINT	WATER CONNECTION POINT (E.G. BOX, OR UNDERGROUND CHAMBER).
WM	WATER METER	WATER METER POINT (E.G. BOX, OR UNDERGROUND CHAMBER).
SCP	SEWERAGE CONNECTION POINT	SEWERAGE CONNECTION POINT (E.G. BOX, OR UNDERGROUND CHAMBER).
GCP	GAS CONNECTION POINT	GAS CONNECTION POINT (E.G. BOX, OR UNDERGROUND CHAMBER).
GM	GAS METER	GAS METER POINT (E.G. BOX, OR UNDERGROUND CHAMBER).
TCP	TELEPHONE CONNECTION POINT	TELEPHONE CONNECTION POINT (E.G. BOX, OR UNDERGROUND CHAMBER).
ECP	ELECTRICITY CONNECTION POINT	ELECTRICITY CONNECTION POINT (E.G. BOX, OR UNDERGROUND CHAMBER).
EM	ELECTRICITY METER	ELECTRICITY METER POINT (E.G. BOX, OR UNDERGROUND CHAMBER).
ICP	INTERNET CONNECTION POINT	INTERNET CONNECTION POINT (E.G. BOX, OR UNDERGROUND CHAMBER).
UNK	UNKNOWN	THE TYPE OF REAL WORLD FEATURE THE POINT REPRESENTS IS NOT KNOWN.
BCM	BUILDING CENTROID MANUAL	POINT MANUALLY PLACED APPROXIMATELY AT CENTRE OF BUILDING AND LYING WITHIN ITS BOUNDS (E.G. FOR U-SHAPED BUILDING).
\.

-- raw_gnaf_202602.geocode_reliability_aut: 6 rows
\copy raw_gnaf_202602.geocode_reliability_aut FROM stdin
1	SURVEYING STANDARD	GEOCODE ACCURACY RECORDED TO APPROPRIATE SURVEYING STANDARD
2	WITHIN ADDRESS SITE BOUNDARY OR ACCESS POINT	GEOCODE ACCURACY SUFFICIENT TO PLACE CENTROID WITHIN ADDRESS SITE BOUNDARY OR ACCESS POINT
3	NEAR (OR POSSIBLY WITHIN) ADDRESS SITE BOUNDARY	GEOCODE ACCURACY SUFFICIENT TO PLACE CENTROID NEAR (OR POSSIBLY WITHIN) ADDRESS SITE BOUNDARY
4	UNIQUE ROAD FEATURE	GEOCODE ACCURACY SUFFICIENT TO ASSOCIATE ADDRESS SITE WITH A UNIQUE ROAD FEATURE
5	UNIQUE LOCALITY OR NEIGHBOURHOOD	GEOCODE ACCURACY SUFFICIENT TO ASSOCIATE ADDRESS SITE WITH A UNIQUE LOCALITY OR NEIGHBOURHOOD
6	UNIQUE REGION	GEOCODE ACCURACY SUFFICIENT TO ASSOCIATE ADDRESS SITE WITH A UNIQUE REGION
\.

-- raw_gnaf_202602.locality_class_aut: 9 rows
\copy raw_gnaf_202602.locality_class_aut FROM stdin
A	ALIAS ONLY LOCALITY	ALIAS ONLY LOCALITY
D	DISTRICT	DISTRICT
G	GAZETTED LOCALITY	GAZETTED LOCALITY
H	HUNDRED	HUNDRED
M	MANUALLY VALIDATED	MANUALLY VALIDATED
T	TOPOGRAPHIC LOCALITY	TOPOGRAPHIC LOCALITY
U	UNOFFICIAL SUBURB	UNOFFICIAL SUBURB
V	UNOFFICIAL TOPOGRAPHIC FEATURE	UNOFFICIAL TOPOGRAPHIC FEATURE
I	INDIGENOUS LOCATION	LOCATION IDENTIFIED IN THE AUSTRALIAN GOVERNMENT INDIGENOUS PROGRAMS AND POLICY LOCATIONS (AGIL) DATASET AVAILABLE VIA https://data.gov.au/
\.

-- raw_gnaf_202602.address_type_aut: 3 rows
\copy raw_gnaf_202602.address_type_aut FROM stdin
R	RURAL	RURAL
UN	UNKNOWN	UNKNOWN
UR	URBAN	URBAN
\.

-- raw_gnaf_202602.address_alias_type_aut: 8 rows
\copy raw_gnaf_202602.address_alias_type_aut FROM stdin
RA	RANGED ADDRESS	RANGED ADDRESS
AL	ALTERNATIVE LOCALITY	ALTERNATIVE LOCALITY
CD	CONTRIBUTOR DEFINED	CONTRIBUTOR DEFINED
MR	MAINTENANCE REFERENCE	MAINTENANCE REFERENCE
SYN	SYNONYM	SYNONYM
LD	LEVEL DUPLICATION	LEVEL DUPLICATION
FNNFS	FLAT NUMBER - NO FIRST SUFFIX CORRELATION	FL NO-ST NO SUFF CORRELATION
FPS	FLAT PREFIX - SUFFIX DE-DUPLICATION	FLAT PREFIX - SUFFIX DE-DUP
\.

-- raw_gnaf_202602.street_class_aut: 2 rows
\copy raw_gnaf_202602.street_class_aut FROM stdin
C	CONFIRMED	A confirmed street is present in the roads data of the PSMA Transport and Topography product for the same release.
U	UNCONFIRMED	An unconfirmed street is NOT present in the roads data of the PSMA Transport and Topography product for the same release and will not have a street locality geocode.
\.

-- raw_gnaf_202602.address_detail: 451 rows
\copy raw_gnaf_202602.address_detail FROM stdin
GAVIC425325004	2013-10-22	2021-08-03	\N	\N	\N	510	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC3569786	\N	loc9a86c6faf562	P	3556	\N	\N	1	425413267	6	\N	\N	\N
GAVIC421281678	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	47	\N	\N	61	\N	VIC2075671	\N	loc4ff8c926c940	P	3147	\N	1\\TP257898	1	421430383	7	\N	550779	\N
GAVIC420135739	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	23	\N	\N	\N	\N	VIC1933940	\N	locfdc6079b562f	P	3032	\N	1\\TP407700	2	420271959	7	\N	999471	\N
GAVIC420987808	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4	\N	\N	\N	\N	VIC2073696	\N	loc4ff8c926c940	P	3147	\N	90\\LP53678	2	421124709	7	\N	568383	\N
GAVIC425741622	2015-10-26	2021-07-07	\N	\N	\N	\N	\N	CARS	\N	2166	Z	\N	\N	\N	\N	\N	11	\N	\N	\N	\N	VIC3572604	\N	loc9901d119afda	P	3000	\N	2166Z\\PS633275	0	425829932	7	\N	422616655	S
GAVIC424581128	2010-04-09	2021-07-07	\N	\N	\N	\N	\N	SHOP	\N	1	\N	FL	\N	1	\N	\N	1880	\N	\N	\N	\N	VIC1975631	\N	loccd13bd88b567	P	3156	\N	1\\LP53936	0	424666593	7	\N	2006295	S
GAVIC412739960	2009-07-21	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	106	\N	\N	\N	\N	\N	\N	620	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	106\\RP18567	1	412875612	7	\N	172699569	S
GAVIC420637602	2004-11-02	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	2	\N	\N	\N	\N	\N	\N	4	\N	\N	\N	\N	VIC1937990	\N	loc9fe59dbd0874	P	3977	\N	2\\SP36612	2	420783355	7	\N	52900161	S
GAVIC421774336	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	2	\N	\N	\N	\N	\N	\N	96	\N	\N	\N	\N	VIC2049549	\N	locd8470b65d64b	P	3204	\N	2\\PS340334	2	421907605	7	\N	441961	S
GAVIC720543934	2020-10-18	2021-08-03	\N	\N	\N	10	A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2008804	\N	loceb6884033cea	P	3352	\N	\N	0	715928975	6	\N	\N	\N
GAVIC719607123	2018-01-19	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	4608	\N	L	\N	46	\N	\N	81	\N	\N	\N	\N	VIC1935604	\N	loc9901d119afda	P	3000	\N	4608\\PS726465	0	714992137	7	\N	426890862	S
GAVIC425367514	2016-04-25	2021-08-14	\N	MONARC APARTMENTS	\N	\N	\N	UNIT	\N	305	\N	\N	\N	\N	\N	\N	74	\N	\N	\N	\N	VIC2025971	\N	loc9901d119afda	P	3004	\N	305\\PS641029	2	425455777	7	\N	219001989	S
GAVIC420061429	2005-04-20	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	3	\N	\N	\N	\N	VIC1957356	\N	loc3832b905a97e	P	3690	\N	1\\PS428797	2	420195833	7	\N	53004205	S
GAVIC720746274	2021-07-25	2021-11-11	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	172	\N	\N	\N	\N	VIC1963362	\N	loc6c0f29d040f7	P	3562	\N	1\\PS818996	0	716131219	7	\N	431906463	\N
GAVIC420040549	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3	\N	\N	\N	\N	\N	\N	64	\N	\N	74	\N	VIC1956038	\N	loc74f8893fb76e	P	3047	\N	PC350785	1	420180173	7	\N	52727790	S
GAVIC420964291	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	4	\N	\N	\N	\N	\N	\N	249	\N	\N	\N	\N	VIC2005249	\N	loc3319215a0a10	P	3186	\N	4\\SP23999	2	421090069	7	\N	52877649	S
GAVIC420418242	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4	\N	\N	\N	\N	VIC2014245	\N	loc712bc92c5924	P	3083	\N	10\\PS328980	2	420546063	7	\N	915600	\N
GAVIC423991217	2007-10-07	2021-08-03	\N	\N	\N	19	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2554240	\N	loc532c3dac4248	P	3463	\N	\N	0	424079728	6	\N	\N	\N
GAVIC424263462	2011-08-06	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12	\N	\N	\N	\N	VIC1975583	\N	loc5e975e2e1c0e	P	3824	\N	160\\PS542238	2	424350293	7	\N	128298286	\N
GAVIC719042751	2016-07-25	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	308	\N	\N	\N	\N	\N	\N	108	\N	\N	\N	\N	VIC1990305	\N	loc9901d119afda	P	3000	\N	\N	0	714427784	7	\N	\N	S
GAVIC424283355	2009-01-07	2021-07-07	\N	\N	\N	\N	\N	FCTY	\N	14	\N	\N	\N	\N	\N	\N	354	\N	\N	\N	\N	VIC2035753	\N	loc0a03ed3531fd	P	3192	\N	CM\\SP26245	0	424370186	7	\N	\N	S
GAVIC720474883	2020-07-18	2021-08-03	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1961465	\N	loc12cc6354a4ba	P	3523	\N	\N	0	715859924	6	\N	\N	\N
GAVIC423910551	2007-07-23	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	5146	\N	\N	\N	\N	\N	\N	368	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	5146\\PS419703	0	424001182	7	\N	206368764	S
GAVIC425311495	2014-10-17	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3	\N	\N	\N	\N	\N	\N	8	\N	\N	\N	\N	VIC2053844	\N	locc605118e951a	P	3756	\N	3\\PS707077	2	425399758	7	\N	135878939	S
GAVIC421304891	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	61	\N	\N	\N	\N	VIC2018477	\N	locd755ccb7197e	P	3175	\N	5\\LP72611	2	421436117	7	\N	587581	\N
GAVIC423390367	2005-07-11	2021-08-03	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1946485	\N	loc3fe991822440	P	3937	\N	\N	0	423485745	6	\N	\N	\N
GAVIC420108368	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10	B	\N	\N	\N	VIC2009968	\N	loc7a8164839d54	P	3109	\N	1\\PS338154	0	420246858	7	\N	958423	S
GAVIC419676903	2014-10-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	52	\N	\N	\N	\N	VIC1948301	\N	loc86dc9bf35404	P	3168	\N	CM1\\PS706305	1	419810399	7	\N	219504920	P
GAVIC424796248	2011-07-29	2021-07-07	\N	\N	\N	\N	\N	SE	\N	1	\N	L	\N	1	\N	\N	84	\N	\N	\N	\N	VIC2061549	\N	loc9901d119afda	P	3000	\N	1\\TP821947	0	424881609	7	\N	\N	S
GAVIC721504260	2024-04-17	2024-04-30	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	9	B	\N	\N	\N	VIC2004950	\N	locf16910f90fb9	P	3190	\N	42\\LP12181	0	717706362	7	\N	\N	\N
GAVIC421109751	2025-04-18	2025-07-21	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	6	\N	\N	\N	\N	VIC2023988	\N	loc74f8893fb76e	P	3047	\N	581\\LP59116	0	421255051	7	\N	275189	P
GAVIC420049828	2009-07-22	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	27	\N	\N	\N	\N	VIC1932666	\N	loc4a6dd2077a69	P	3956	\N	467\\LP56449	1	420186048	7	\N	5279420	\N
GAVIC424246587	2008-10-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	88	\N	\N	\N	\N	VIC2048971	\N	locd724f9a08a75	P	3820	\N	CP159156	0	424333656	7	\N	123939530	\N
GAVIC419908615	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	11	\N	\N	\N	\N	VIC1976052	\N	locc67851215f08	P	3048	\N	8\\PS403232	2	420053915	7	\N	2052270	\N
GAVIC413630613	2012-01-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	11	\N	\N	\N	\N	VIC2072985	\N	loc2f9c80de6f7d	P	3153	\N	1\\PS307961	1	413788284	7	\N	217970074	P
GAVIC420757091	2012-01-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10	\N	\N	\N	\N	VIC1951133	\N	loc79e45c9fa669	P	3057	\N	1\\PS346158	1	420891722	7	\N	217878105	P
GAVIC420841495	2005-10-14	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	76	\N	\N	\N	\N	VIC2042335	\N	locbbb93e2c6c42	P	3227	\N	32\\LP87498	2	420984525	7	\N	41040606	\N
GAVIC719439210	2017-07-26	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	103	\N	L	\N	1	\N	\N	499	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	103\\PS737521	0	714824238	7	\N	426189126	S
GAVIC420610243	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	6	\N	\N	\N	\N	VIC1950981	\N	loc22c42e389de3	P	3752	\N	68\\PS422011	2	420758704	7	\N	52556708	\N
GAVIC420048609	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	536	\N	\N	\N	\N	VIC1960955	\N	locf51f6cd689bb	P	3205	\N	3\\RP18126	2	420182105	7	\N	52812052	P
GAVIC420648830	2006-08-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	41	\N	\N	\N	\N	VIC2036451	\N	loc2508c9e5a93c	P	3431	\N	2\\LP144550	1	420775290	7	\N	52618179	\N
GAVIC423943682	2007-09-28	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	2	\N	\N	\N	\N	\N	\N	1	A	\N	\N	\N	VIC2032237	\N	locf065e41cfac9	P	3038	\N	2\\PS606091	2	424032234	7	\N	208658325	S
GAVIC422409795	2005-04-20	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	53	\N	\N	\N	\N	VIC2015298	\N	loc3832b905a97e	P	3690	\N	1\\PS315404	2	422521967	7	\N	5259676	S
GAVIC419827679	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	VIC1983442	\N	loc695c9ddc8068	P	3183	\N	1\\TP618386	2	419958905	7	\N	1700777	\N
GAVIC424926818	2012-01-21	2021-08-03	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1930780	\N	loc399d9bd46679	P	3444	\N	\N	0	425012182	6	\N	\N	\N
GAVIC721476998	2024-04-16	2024-04-30	\N	\N	\N	\N	\N	UNIT	\N	213	\N	FL	\N	2	\N	\N	538	\N	\N	\N	\N	VIC2005249	\N	loc3319215a0a10	P	3186	\N	PC382446	0	717679200	7	\N	456392825	S
GAVIC720699788	2021-04-11	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	23	\N	\N	\N	\N	\N	\N	25	\N	\N	\N	\N	VIC1979366	\N	loc15a8d395ef61	P	3812	\N	4\\PS727423	0	716084829	7	\N	\N	S
GAVIC421826494	2012-04-14	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	59	\N	\N	\N	\N	VIC2034660	\N	loc2f9c80de6f7d	P	3153	\N	10\\LP20578	2	421932764	7	\N	219016662	P
GAVIC420703086	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	5	\N	\N	\N	\N	VIC1975240	\N	loc913bf4728c4e	P	3124	\N	25~C\\LP8259	2	420842711	7	\N	791145	\N
GAVIC420556912	2005-10-14	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	22	\N	\N	\N	\N	VIC1976942	\N	loc0b6e17218dd4	P	3204	\N	13\\LP20056	2	420691543	7	\N	414145	\N
GAVIC720693565	2021-04-10	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	26	\N	\N	\N	\N	VIC3626122	\N	loc4883549a5421	P	3059	\N	RES2\\PS817578	0	716078606	7	\N	\N	\N
GAVIC422086500	2012-01-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	49	\N	\N	\N	\N	VIC1959477	\N	loc34a55c4d0462	P	3021	\N	1\\PS333157	1	422217313	7	\N	217673959	P
GAVIC425085888	2012-10-16	2021-08-03	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2	\N	\N	\N	\N	VIC3570907	\N	loc82baa1179308	P	3810	\N	\N	0	425171577	7	\N	\N	\N
GAVIC423826364	2007-01-05	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	218	\N	L	\N	2	\N	\N	268	\N	\N	\N	\N	VIC1955713	\N	loc9901d119afda	P	3000	\N	218B\\PS508080	0	423917070	7	\N	207788712	S
GAVIC424750944	2014-07-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	24	\N	\N	\N	\N	VIC3374991	\N	loc338a35dd09f0	P	3555	\N	58\\PS645147	2	424836305	7	\N	134200342	\N
GAVIC425530619	2017-07-26	2024-01-26	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	595	\N	\N	\N	\N	VIC2068568	\N	locedacea740a10	P	3585	\N	3\\PS912957	1	425618909	7	\N	52479831	\N
GAVIC421107468	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10	\N	\N	\N	\N	VIC1945124	\N	loce42a110faa48	P	3188	\N	36\\LP8090	2	421236655	7	\N	1591389	\N
GAVIC421689281	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	63	\N	\N	\N	\N	VIC1980714	\N	locd6f79866f950	P	3180	\N	38\\LP52614	2	421826182	7	\N	1295273	\N
GAVIC423648049	2024-07-14	2024-07-30	\N	\N	\N	\N	\N	APT	\N	2201	\N	L	\N	22	\N	\N	222	\N	\N	\N	\N	VIC2051723	\N	loc9901d119afda	P	3000	\N	2201A\\PS337555	0	423741522	7	\N	456950228	S
GAVIC424776713	2012-07-15	2024-10-25	\N	NRMA RIVERSIDE HOLIDAY PK	\N	\N	\N	SITE	\N	62	\N	\N	\N	\N	\N	\N	2	\N	\N	\N	\N	VIC3347454	\N	loc232da9d11723	P	3875	\N	2B~1\\PP5027	0	424862074	7	\N	\N	S
GAVIC419987098	2007-12-15	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	29	\N	\N	\N	\N	VIC1938173	\N	loc4423238fcdd8	P	3300	\N	3\\PS316650	2	420127405	7	\N	5090176	P
GAVIC420881388	2005-07-05	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	7	\N	\N	\N	\N	\N	\N	32	\N	\N	\N	\N	VIC2061689	\N	loc250adfcbc82d	P	3181	\N	7\\RP12674	2	421019197	7	\N	50091652	S
GAVIC424785567	2012-07-15	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	38	\N	\N	\N	\N	VIC3353866	\N	loc29841cc6d6f1	P	3338	\N	1611\\PS638308	2	424870928	7	\N	215388699	\N
GAVIC420215992	2004-07-02	2025-01-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	32	\N	\N	\N	\N	VIC1973863	\N	loc3b6fd5dcd874	P	3943	\N	4\\LP217798	1	420356298	7	\N	1062245	S
GAVIC422161681	2004-07-02	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	15	A	\N	\N	\N	VIC1994400	\N	loc913bf4728c4e	P	3124	\N	1\\RP5526	1	422292427	7	\N	60051327	P
GAVIC423402509	2005-07-11	2021-08-03	\N	\N	\N	77	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2015559	\N	loc0e534d470df9	P	3523	\N	\N	0	423497886	6	\N	\N	\N
GAVIC419568757	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10	\N	\N	\N	\N	VIC2063543	\N	loc7d9d9818d4b9	P	3155	\N	33\\LP41879	2	419704523	7	\N	1318236	\N
GAVIC421885685	2007-12-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	145	\N	\N	\N	\N	VIC2065815	\N	loc232da9d11723	P	3875	\N	2\\LP20539	2	422008521	7	\N	52927748	\N
GAVIC420083984	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	6	\N	\N	\N	\N	\N	\N	14	\N	\N	\N	\N	VIC2031747	\N	loc7213d03738b9	P	3060	\N	12\\PS341620	2	420226560	7	\N	76942	S
GAVIC423402101	2005-07-11	2021-08-03	\N	\N	\N	26	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1979663	\N	loce36428dd6505	P	3462	\N	\N	0	423497478	6	\N	\N	\N
GAVIC423402710	2005-07-11	2021-08-03	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2018444	\N	loc47e9d5554e9d	P	3840	\N	\N	0	423498087	6	\N	\N	\N
GAVIC419780964	2004-04-29	2021-08-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	149	\N	\N	155	\N	VIC2007417	\N	locb344fc28a060	P	3912	\N	4\\PS749865	0	419929442	7	\N	629166	\N
GAVIC421741216	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	48	\N	\N	\N	\N	VIC1945552	\N	loc63a05a113f90	P	3505	\N	14~5\\PP5516	2	421901952	7	\N	45129853	\N
GAVIC420949509	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4	\N	\N	\N	\N	VIC1997189	\N	locdf0288b649a4	P	3690	\N	5\\LP114867	2	421079146	7	\N	5272569	P
GAVIC719115528	2018-01-20	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	604	\N	\N	\N	\N	\N	\N	5	\N	\N	7	\N	VIC1998523	\N	loca5de38b84720	P	3128	\N	604\\PS738539	2	714500561	7	\N	424506747	S
GAVIC420255830	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	28	\N	\N	\N	\N	VIC2023947	\N	loc8f565e81c655	P	3074	\N	14\\LP96082	2	420390915	7	\N	320862	\N
GAVIC719913448	2019-01-25	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	615	\N	\N	\N	\N	\N	\N	450	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	615\\PS738892	2	715298489	7	\N	428576328	S
GAVIC420355278	2008-06-27	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	167	\N	\N	\N	\N	VIC1943976	\N	loccdfc709471ce	P	3579	\N	1\\TP108762	2	420498308	7	\N	52975527	\N
GAVIC422273680	2024-04-16	2025-01-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	35	\N	\N	\N	\N	VIC2063014	\N	loc13ed320cd188	P	3551	\N	CM1\\PS907241	1	422385892	7	\N	454192102	\N
GAVIC419679289	2012-04-14	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	51	\N	\N	\N	\N	VIC2051667	\N	locd6f79866f950	P	3180	\N	27\\LP120227	1	419828675	7	\N	219016653	P
GAVIC420987849	2004-10-21	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	7	\N	\N	\N	\N	VIC2007148	\N	locb0a9c63101c7	P	3730	\N	26\\LP207676	2	421124750	7	\N	5353951	\N
GAVIC420390898	2004-11-02	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	124	\N	\N	\N	\N	VIC2072267	\N	loc9fe59dbd0874	P	3977	\N	224\\PS300273	2	420525075	7	\N	621780	\N
GAVIC420429255	2006-01-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	8	\N	\N	\N	\N	VIC2068062	\N	loceb41e8eec3ee	P	3816	\N	4\\LP125750	2	420562978	7	\N	770846	\N
GAVIC719764462	2018-05-07	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	413	\N	L	\N	4	\N	\N	8	\N	\N	\N	\N	VIC2007449	\N	locddc4a1bcd8ba	P	3008	\N	413\\PS728852	0	715149485	7	\N	427230274	S
GAVIC421059470	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	15	\N	\N	\N	\N	VIC2072594	\N	loc37efd432abe4	P	3152	\N	75\\LP146524	2	421192512	7	\N	1316356	\N
GAVIC420099787	2010-07-12	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	62	\N	\N	\N	\N	VIC1976022	\N	locc70453923b8e	P	3196	\N	CM1\\PS626060	2	420241455	7	\N	212652258	P
GAVIC412717346	2005-10-12	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	8	\N	\N	\N	\N	VIC2027065	\N	loc9901d119afda	P	3000	\N	CP109146	1	412861624	7	\N	203494966	\N
GAVIC721917030	2026-01-16	2026-01-29	\N	\N	\N	\N	\N	CARP	\N	1605	C	\N	\N	\N	\N	\N	270	\N	\N	\N	\N	VIC2059743	\N	loc31f384e524fe	P	3006	\N	1605A\\PS918394	0	718119838	7	\N	459101457	S
GAVIC411685451	2005-10-12	2021-08-05	\N	WALMSLEY VILLAGE	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	51	\N	\N	\N	\N	VIC1985787	\N	loc38cbe92d1159	P	3137	\N	51\\PS404622	2	411832680	7	\N	2087894	\N
GAVIC424727151	2016-04-25	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	9	\N	\N	\N	\N	VICL3552638	\N	locc5abea08e85d	P	3030	\N	2165\\PS511700	2	424812537	7	\N	215927720	\N
GAVIC424633603	2010-10-22	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	4	\N	\N	\N	\N	\N	\N	83	\N	\N	\N	\N	VIC2068283	\N	loc72d1f0339be6	P	3134	\N	4\\PS631475	1	424718994	7	\N	214381631	S
GAVIC424917511	2013-01-12	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	9	\N	\N	\N	\N	VIC3556163	\N	loc4161e46afd2f	P	3753	\N	243\\PS617320	2	425002879	7	\N	131144334	\N
GAVIC423911067	2007-03-23	2021-08-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	368	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	\N	0	424001698	7	\N	\N	P
GAVIC424676885	2024-10-17	2025-01-27	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	104	\N	\N	\N	\N	VIC2007474	\N	locc586266ef8cc	P	3850	\N	1\\PS918970	2	424762274	7	\N	456566829	P
GAVIC419711232	2004-04-29	2025-10-28	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	19	\N	\N	\N	\N	VIC1984845	\N	locf16910f90fb9	P	3190	\N	3A\\PS420083	2	419854489	7	\N	52477474	\N
GAVIC421943442	2012-10-16	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	5	\N	\N	\N	\N	VIC1954730	\N	loc06cc48b309e5	P	3087	\N	CM1\\PS645053	1	422073533	7	\N	218230252	P
GAVIC420538231	2004-11-02	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	8	\N	\N	\N	\N	VIC1969882	\N	loc2c9ce0acd6de	P	3223	\N	13\\LP43093	2	420676040	7	\N	41020287	\N
GAVIC419682437	2004-10-21	2021-08-05	\N	DUNROAMIN	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	179	\N	\N	\N	\N	VIC2011064	\N	loca2fd80ef71d3	P	3352	\N	45\\LP110098	2	419822291	7	\N	5016100	\N
GAVIC719539171	2022-07-21	2025-10-27	\N	INGENIA LIFESTYLE LARA	\N	\N	\N	UNIT	\N	64	\N	\N	\N	\N	\N	\N	40	\N	\N	\N	\N	VIC2069720	\N	loce16236caf708	P	3212	\N	PC366289	2	714924203	7	\N	212905550	S
GAVIC421524934	2005-10-12	2023-11-05	\N	\N	\N	\N	\N	FLAT	\N	6	\N	\N	\N	\N	\N	\N	34	\N	\N	\N	\N	VIC1965184	\N	loc4195fdfecc8e	P	3185	\N	6\\RP10477	2	421624178	7	\N	50055317	S
GAVIC419802779	2009-07-21	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	60	\N	\N	\N	\N	VIC2046214	\N	locec99dd6d0979	P	3028	\N	15~P\\LP1204	2	419934459	7	\N	204361917	\N
GAVIC423669472	2006-01-15	2021-08-05	\N	THE PINNACLE	\N	\N	\N	UNIT	\N	30	\N	\N	\N	\N	\N	\N	102	\N	\N	106	\N	VIC2030169	\N	loc2c4c767ea9b7	P	3072	\N	1\\TP618847	0	423762945	7	\N	\N	S
GAVIC424353303	2009-04-03	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1064	\N	\N	1068	\N	VIC1953363	\N	loc9fb289b0a33e	P	3498	\N	2\\LP210288	1	424439560	7	\N	5103527	\N
GAVIC719608433	2018-05-08	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	1408	\N	\N	\N	\N	\N	\N	12	\N	\N	\N	\N	VIC2025971	\N	loc9901d119afda	P	3004	\N	1408\\PS726142	2	714993447	7	\N	426238177	S
GAVIC424424026	2009-04-22	2021-07-27	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	92	\N	\N	94	\N	VIC2053277	\N	loc2d817b7080e2	P	3145	\N	\N	0	424510130	7	\N	\N	P
GAVIC420323810	2006-01-15	2023-11-05	\N	\N	\N	\N	\N	UNIT	\N	5	\N	\N	\N	\N	\N	\N	3	\N	\N	5	\N	VIC2058977	\N	locadc5cabaa80e	P	3146	\N	1\\PS847991	2	420465478	7	\N	52714421	S
GAVIC721800565	2025-07-15	2025-07-31	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2	\N	\N	\N	\N	VIC4127252	\N	loc1b271c01e3dc	P	3064	\N	1008\\PS908944	0	718002861	7	\N	453123307	\N
GAVIC425169775	2017-07-26	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	48	\N	\N	\N	\N	VIC2034802	\N	loce11f06c54f46	P	3437	\N	1\\PS638421	2	425258034	7	\N	134347646	S
GAVIC424272695	2009-10-12	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3	\N	\N	\N	\N	\N	\N	4	\N	\N	\N	\N	VIC1962198	\N	loccb9bfb1fb49a	P	3136	\N	3\\PS605912	2	424359526	7	\N	212006781	S
GAVIC721849526	2025-10-15	2025-10-30	\N	\N	\N	\N	\N	UNIT	\N	1502	\N	\N	\N	\N	\N	\N	52	\N	\N	\N	\N	VIC3572033	\N	locddc4a1bcd8ba	P	3008	\N	1502\\PS531777	0	718052177	7	\N	458360061	S
GAVIC420191477	2009-10-08	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	6	\N	\N	\N	\N	\N	\N	60	\N	\N	\N	\N	VIC2066892	\N	loc875118ed8437	P	3065	\N	1\\TP249892	2	420321341	7	\N	150768433	S
GAVIC419623906	2010-01-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	63	\N	\N	\N	\N	VIC2013487	\N	locf4e180745c81	P	3936	\N	CM1\\PS623307	2	419771930	7	\N	211711767	P
GAVIC424478303	2025-10-15	2025-10-30	\N	COMO CENTRE	\N	\N	\N	SE	\N	11	A	L	\N	3	\N	\N	299	\N	\N	\N	\N	VIC2036742	\N	locc2ea2de6af6c	P	3141	\N	S3\\PS920557	1	424564343	7	\N	456895066	S
GAVIC420119751	2010-01-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	224	\N	\N	\N	\N	VIC2006911	\N	locb9872f35df41	P	3067	\N	1\\RP17155	2	420256879	7	\N	869718	\N
GAVIC423401116	2020-10-19	2021-08-03	\N	\N	\N	18	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2073892	\N	loc8a2c57a8fa9c	P	3567	\N	\N	0	423496493	6	\N	\N	\N
GAVIC419943868	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	82	\N	\N	\N	\N	VIC1931054	\N	loc0a03ed3531fd	P	3192	\N	5\\LP51716	2	420073732	7	\N	409407	\N
GAVIC421694057	2013-07-16	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	77	\N	\N	\N	\N	\N	\N	126	\N	\N	\N	\N	VIC2003128	\N	loc92bf5bc798e7	P	3031	\N	PC367391	2	421844576	7	\N	221191222	S
GAVIC423471646	2025-10-16	2025-10-30	\N	\N	\N	\N	\N	UNIT	\N	202	\N	\N	\N	\N	\N	\N	416	\N	\N	\N	\N	VIC1998102	\N	loc79e45c9fa669	P	3057	\N	202\\PS512620	2	423566656	7	\N	202764701	S
GAVIC423397050	2005-07-11	2021-08-03	\N	\N	\N	19	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1969720	\N	loc610e6e8cd167	P	3775	\N	\N	0	423492428	6	\N	\N	\N
GAVIC421362480	2012-10-17	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	12	\N	\N	\N	\N	VIC2021954	\N	locf16910f90fb9	P	3190	\N	1\\PS337878	2	421476681	7	\N	9736	S
GAVIC424918055	2012-10-17	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	901	\N	\N	\N	\N	\N	\N	568	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	901\\PS621195	1	425003423	7	\N	215160166	S
GAVIC720238978	2026-01-16	2026-01-29	\N	LUCAS LIFESTYLE ESTATE	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3	\N	\N	\N	\N	VIC3621392	\N	loc98325a7e67bf	P	3350	\N	35\\PS701379	2	715624039	7	\N	454866784	\N
GAVIC411935231	2012-07-15	2021-08-03	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2044583	\N	loc20a81a4bf246	P	3796	\N	\N	0	412080871	6	\N	\N	\N
GAVIC420058003	2013-10-23	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	5	\N	\N	\N	\N	\N	\N	55	\N	\N	\N	\N	VIC1953594	\N	locbcb60f6b546d	P	3910	\N	5\\PS310696	2	420198528	7	\N	52835535	S
GAVIC423789992	2013-07-16	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	206	\N	L	\N	2	\N	\N	9	\N	\N	\N	\N	VIC1967421	\N	loc9901d119afda	P	3000	\N	206A\\PS508080	0	423880954	7	\N	206452428	S
GAVIC425028781	2013-04-19	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	1206	\N	\N	\N	\N	\N	\N	470	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	1206\\PS634058	2	425114129	7	\N	217966779	S
GAVIC425084495	2012-10-17	2021-07-27	\N	\N	\N	\N	\N	UNIT	\N	5	\N	\N	\N	\N	\N	\N	18	A	\N	\N	\N	VIC1981507	\N	locbb6ca08c118e	P	3070	\N	5\\PS640884	1	425170184	7	\N	217034186	S
GAVIC424795446	2013-07-16	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	908	\N	FL	\N	9	\N	\N	77	\N	\N	\N	\N	VIC2040420	\N	locc2ea2de6af6c	P	3141	\N	908\\PS617851	0	424880807	7	\N	218476022	S
GAVIC425707510	2015-08-01	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2	A	\N	\N	\N	VIC3565705	\N	loc8688ba223de1	P	3723	\N	181~A\\PP2370	0	425795800	7	\N	\N	P
GAVIC425314633	2014-04-20	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	36	\N	\N	\N	\N	\N	\N	31	\N	\N	\N	\N	VIC1992791	\N	loc406d1f7b5fe3	P	3106	\N	36\\PS711492	1	425402896	7	\N	220164261	S
GAVIC425285314	2014-01-22	2021-07-07	\N	\N	\N	\N	\N	APT	\N	1609	\N	L	\N	16	\N	\N	220	\N	\N	\N	\N	VIC2027065	\N	loc9901d119afda	P	3000	\N	1609S\\PS633275	1	425373580	7	\N	220201047	S
GAVIC424263895	2015-07-30	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	8	\N	\N	\N	\N	VIC1965101	\N	loce3f8de63f06a	P	3083	\N	1\\PS543069	1	424350726	7	\N	204382353	S
GAVIC424285382	2014-04-18	2025-01-27	\N	\N	\N	\N	\N	UNIT	\N	14	\N	\N	\N	\N	\N	\N	47	\N	\N	\N	\N	VIC2053297	\N	loc11b2a92fb5f0	P	3055	\N	1\\PS705721	2	424372213	7	\N	219579826	S
GAVIC425520470	2014-10-17	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	2504	\N	L	\N	25	\N	\N	118	\N	\N	\N	\N	VIC1985134	\N	loc31f384e524fe	P	3006	\N	2504\\PS647246	0	425608760	7	\N	220786583	S
GAVIC424589454	2014-07-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	28	\N	\N	\N	\N	VIC3353446	\N	locc5abea08e85d	P	3030	\N	1939\\PS511700	2	424674919	7	\N	213012407	\N
GAVIC425032219	2014-07-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	6	\N	\N	\N	\N	VIC2065334	\N	locae68612e5fe1	P	3134	\N	3A\\PS506101	2	425117567	7	\N	216106456	\N
GAVIC420205676	2023-10-23	2023-11-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	6	\N	\N	\N	\N	VIC2030489	\N	loca4e166a620d9	P	3174	\N	1\\PS908068	1	420332142	7	\N	423902533	P
GAVIC425821887	2016-04-22	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	6	\N	\N	\N	\N	\N	\N	30	\N	\N	32	\N	VIC1956233	\N	loc4858bcc1d912	P	3046	\N	6\\PS739781	1	425910197	7	\N	422802129	S
GAVIC411968423	2015-07-27	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	5	\N	\N	\N	\N	\N	\N	362	\N	\N	\N	\N	VIC1981503	\N	loce01ddbd8c8e5	P	3608	\N	1\\PS715833	2	412114290	7	\N	421806532	S
GAVIC719983320	2019-01-24	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	108	\N	L	\N	1	\N	\N	108	\N	\N	\N	\N	VIC1990433	\N	loc1e06c486c813	P	3051	\N	108\\PS742791	0	715368361	7	\N	427629619	S
GAVIC424667096	2016-01-15	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	22	\N	\N	\N	\N	VIC3382134	\N	locc5abea08e85d	P	3030	\N	817\\PS620424	2	424752485	7	\N	214016747	\N
GAVIC425786720	2016-04-25	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	205	D	\N	\N	\N	\N	\N	21	\N	\N	\N	\N	VIC2042282	\N	loc6de0828869d7	P	3066	\N	205D\\PS411166	2	425875030	7	\N	423146733	S
GAVIC425613744	2016-04-25	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	71	\N	\N	\N	\N	VIC3568169	\N	locae977e7a8d83	P	3977	\N	726\\PS721478	2	425702034	7	\N	420898134	\N
GAVIC718991138	2016-07-22	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	610	\N	L	\N	6	\N	\N	28	\N	\N	\N	\N	VIC1944167	\N	loca0398a35cf5e	P	3053	\N	610\\PS720330	0	714376171	7	\N	423877251	S
GAVIC425774710	2016-04-25	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	110	\N	\N	\N	\N	\N	\N	8	\N	\N	\N	\N	VIC1935251	\N	loce48c38ae2d6a	P	3121	\N	110E\\PS631302	2	425863020	7	\N	422849699	S
GAVIC719010591	2016-07-22	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	524	\N	L	\N	5	\N	\N	33	\N	\N	\N	\N	VIC2059530	\N	loc1e06c486c813	P	3051	\N	524\\PS719578	0	714395624	7	\N	424011652	S
GAVIC719096818	2016-10-25	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	208	\N	L	\N	2	\N	\N	83	\N	\N	\N	\N	VIC1955611	\N	loc1e06c486c813	P	3051	\N	208\\PS704450	0	714481851	7	\N	424114615	S
GAVIC421739766	2019-01-24	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	39	\N	\N	\N	\N	VIC2040693	\N	loc656f84726510	P	3073	\N	1\\PS807551	2	421880072	7	\N	425489925	P
GAVIC720052842	2019-04-24	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3314	\N	L	\N	33	\N	\N	60	\N	\N	\N	\N	VIC1985134	\N	loc31f384e524fe	P	3006	\N	3314\\PS745414	0	715437863	7	\N	429526559	S
GAVIC719524538	2017-10-17	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3504	\N	L	\N	35	\N	\N	442	\N	\N	\N	\N	VIC1963013	\N	loc9901d119afda	P	3000	\N	3505\\PS728842	0	714909570	7	\N	426506475	S
GAVIC720058933	2019-04-24	2021-07-27	\N	\N	\N	\N	\N	UNIT	\N	602	\N	FL	\N	6	\N	\N	191	\N	\N	\N	\N	VIC1981515	\N	loc2c4c767ea9b7	P	3072	\N	611\\PS805184	0	715443954	7	\N	429440250	S
GAVIC423232139	2017-10-26	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	17	\N	\N	\N	\N	\N	\N	33	\N	\N	34	\N	VIC2025971	\N	loc9901d119afda	P	3004	\N	17\\RP14334	0	423328381	7	\N	50211615	S
GAVIC420796526	2017-10-26	2021-08-03	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	53	\N	\N	\N	\N	VIC1953813	\N	loca4e166a620d9	P	3174	\N	\N	0	420933654	7	\N	\N	P
GAVIC412378116	2017-10-26	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	81	\N	\N	\N	\N	VIC1985993	\N	locfe955a87410d	P	3182	\N	1\\PS618095	2	412520578	7	\N	211728033	S
GAVIC421448648	2017-10-26	2023-11-05	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	171	\N	\N	\N	\N	VIC2064616	\N	loccaca39f133a7	P	3081	\N	1\\SP24480	1	421564892	7	\N	208780275	P
GAVIC419854308	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	27	\N	\N	\N	\N	VIC1930917	\N	loc7f158a48110c	P	3942	\N	14\\LP6027	2	419986896	7	\N	1042746	\N
GAVIC424732111	2024-04-19	2024-04-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1	E	\N	\N	\N	VIC2075791	\N	loca818c5eaa373	P	3012	\N	2\\TP854883	0	424817497	7	\N	\N	P
GAVIC423623835	2006-01-14	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	5	\N	L	\N	1	\N	\N	1	A	\N	\N	\N	VIC1943059	\N	loc1e06c486c813	P	3051	\N	10\\PS433630	0	423717308	7	\N	52868126	S
GAVIC419784186	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	7	\N	\N	\N	\N	VIC1942036	\N	locc0b6d754799e	P	3977	\N	249\\LP40698	2	419926535	7	\N	602296	\N
GAVIC423620402	2006-01-14	2021-07-07	\N	\N	\N	\N	\N	CARS	\N	22	\N	\N	\N	\N	\N	\N	369	\N	\N	\N	\N	VIC1935569	\N	loc1e06c486c813	P	3051	\N	22\\RP1880	0	423713875	7	\N	52380202	S
GAVIC424551158	2010-01-20	2021-08-03	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1937475	\N	loc245c69160468	P	3461	\N	\N	0	424636988	6	\N	\N	\N
GAVIC424895492	2011-11-02	2021-08-03	\N	\N	\N	22	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC3136743	\N	locb48ce003b11e	P	3515	\N	\N	0	424980860	6	\N	\N	\N
GAVIC719424466	2017-07-26	2021-08-14	\N	\N	\N	\N	\N	UNIT	A	1	\N	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	VIC2025971	\N	loc9901d119afda	P	3004	\N	A1\\PS500424	0	714809494	7	\N	426006767	S
GAVIC423890759	2009-04-05	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	4	\N	\N	\N	\N	\N	\N	58	\N	\N	60	\N	VIC2076350	\N	loc910a14938d48	P	3218	\N	4\\PS546320	2	423981390	7	\N	206511666	S
GAVIC421670970	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	18	\N	\N	\N	\N	VIC1952931	\N	loc5c27e3f22fc1	P	3122	\N	80\\LP8025	2	421821487	7	\N	122541	\N
GAVIC424754823	2011-08-06	2025-01-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	305	\N	\N	\N	\N	VIC3566690	\N	locbf553ce41d73	P	3608	\N	1\\TP124821	2	424840184	7	\N	5021904	P
GAVIC421658800	2005-01-20	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	7	\N	\N	\N	\N	VIC2016584	\N	locba8f7a4a0c92	P	3691	\N	240\\LP211937	2	421802511	7	\N	5276640	\N
GAVIC420298014	2006-08-17	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	15	\N	\N	\N	\N	\N	\N	247	\N	\N	249	\N	VIC2040515	\N	loc4fa4b090ce9e	P	3123	\N	15\\RP6990	1	420437639	7	\N	52372605	S
GAVIC424034425	2008-10-20	2021-07-07	\N	\N	\N	\N	\N	FCTY	\N	2	\N	\N	\N	\N	\N	\N	14	\N	\N	\N	\N	VIC2038936	\N	locf066999b6a14	P	3803	\N	1\\PS604177	1	424122311	7	\N	208710226	S
GAVIC421856523	2005-02-15	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	4	\N	\N	\N	\N	\N	\N	40	\N	\N	\N	\N	VIC2059036	\N	loc11b2a92fb5f0	P	3055	\N	3\\LP4289	2	422003187	7	\N	53001898	S
GAVIC424765376	2011-04-27	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	7	G	\N	\N	\N	\N	\N	566	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	G7\\PS402478	0	424850737	7	\N	52435880	S
GAVIC721479211	2024-10-17	2024-10-30	\N	\N	\N	\N	\N	UNIT	\N	105	\N	\N	\N	\N	\N	\N	43	\N	\N	\N	\N	VIC1961369	\N	loc22c42e389de3	P	3752	\N	102\\PS849875	0	717681413	7	\N	457301174	S
GAVIC423444001	2008-12-29	2021-07-07	\N	\N	\N	\N	\N	FLAT	\N	54	\N	\N	\N	\N	\N	\N	422	\N	\N	432	\N	VIC1944650	\N	loca0398a35cf5e	P	3053	\N	54\\RP2074	1	423539011	7	\N	203511554	S
GAVIC721549117	2024-07-14	2024-10-28	\N	\N	\N	\N	\N	UNIT	\N	1707	\N	L	\N	17	\N	\N	7	\N	\N	\N	\N	VIC2044273	\N	locddc4a1bcd8ba	P	3008	\N	S6\\PS644635	0	717751011	7	\N	457007259	S
GAVIC411087566	2008-12-29	2021-07-07	\N	\N	\N	\N	\N	FLAT	\N	14	\N	\N	\N	\N	\N	\N	5	\N	\N	\N	\N	VIC1953679	\N	loc1b5a0e70afd4	P	3162	\N	14\\PS349838	2	411236384	7	\N	50058012	S
GAVIC419906596	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	263	\N	\N	\N	\N	VIC2061305	\N	loc82b861dfb765	P	3071	\N	1\\TP861600	2	420039411	7	\N	171882	\N
GAVIC421146125	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	36	\N	\N	\N	\N	VIC2046096	\N	loc8fef59c1c585	P	3043	\N	41\\LP74406	2	421278486	7	\N	283367	\N
GAVIC422119571	2006-01-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	VIC2054286	\N	loc913bf4728c4e	P	3124	\N	2\\PS332618	1	422250333	7	\N	60063747	P
GAVIC419640745	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	71	\N	\N	\N	\N	VIC2054946	\N	loc0a03ed3531fd	P	3192	\N	49\\LP40376	2	419776057	7	\N	403847	\N
GAVIC423394320	2005-07-11	2021-08-03	\N	\N	\N	19	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2053994	\N	loc5e68bb81d75d	P	3540	\N	\N	0	423489698	6	\N	\N	\N
GAVIC411803305	2005-04-14	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	1006	\N	\N	\N	\N	\N	\N	582	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	76\\PS404635	2	411947810	7	\N	52570065	S
GAVIC721038984	2022-07-21	2025-01-24	\N	CAMPSITE 42	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	42	\N	\N	\N	\N	VIC4127542	\N	loc956fa85c7b0c	P	3223	\N	73C\\PP5647	0	717239943	7	\N	221661586	S
GAVIC420701723	2010-01-21	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	59	\N	\N	\N	\N	VIC1942857	\N	locbd7d4fd6b9e7	P	3058	\N	1\\TP693857	2	420834992	7	\N	843219	\N
GAVIC419724052	2025-10-16	2025-10-30	\N	\N	\N	\N	\N	UNIT	\N	30	\N	\N	\N	\N	\N	\N	123	\N	\N	\N	\N	VIC1953162	\N	loc67a11408d754	P	3011	\N	PC355367	2	419865039	7	\N	52629776	S
GAVIC420622820	2007-09-28	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	21	\N	\N	\N	\N	VIC2014019	\N	locdf0288b649a4	P	3690	\N	1\\PS317132	2	420768801	7	\N	5281226	\N
GAVIC421612837	2006-01-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	48	\N	\N	\N	\N	VIC1935609	\N	locbd7d4fd6b9e7	P	3058	\N	35~E\\LP1653	2	421749284	7	\N	840048	\N
GAVIC720743838	2022-04-20	2022-05-09	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	74	\N	\N	\N	\N	VIC3623473	\N	loc6a54ce63b777	P	3358	\N	131\\PS825905	2	716128783	7	\N	434157200	\N
GAVIC425685265	2016-01-18	2025-04-27	\N	\N	\N	\N	\N	UNIT	\N	2	\N	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	VIC2002547	\N	locd6190ebbe554	P	3699	\N	2046\\PP2486	0	425773555	7	\N	421377069	S
GAVIC423406602	2005-07-11	2021-08-03	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2024336	\N	loc5c94ac6107ca	P	3929	\N	\N	0	423501977	6	\N	\N	\N
GAVIC721915145	2026-01-16	2026-01-29	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	8	\N	\N	\N	\N	VIC4187098	\N	locf2d2a267a354	P	3241	\N	109\\PS918241	1	718117953	7	\N	457845883	\N
GAVIC421838556	2012-04-14	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	2	\N	\N	\N	\N	\N	\N	20	\N	\N	\N	\N	VIC1945132	\N	loc0067a4549ed1	P	3950	\N	2\\PS634718	2	422005646	7	\N	133007055	S
GAVIC421458512	2008-06-27	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	70	\N	\N	\N	\N	VIC1948889	\N	loce6098ac5df0c	P	3550	\N	290~E\\PP3473A	2	421605628	7	\N	45199531	\N
GAVIC420870124	2008-06-27	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	67	\N	\N	69	\N	VIC1972025	\N	loc94fdc21035b3	P	3544	\N	1~13\\LP6006	1	421013154	7	\N	5062956	\N
GAVIC425277959	2013-07-16	2021-08-05	\N	\N	\N	\N	\N	UNIT	\N	133	AS	\N	\N	\N	\N	\N	50	\N	\N	\N	\N	VIC1990396	\N	loc31f384e524fe	P	3006	\N	133A\\PS629585	0	425366225	7	\N	217595341	S
GAVIC412674706	2004-10-28	2021-08-03	\N	\N	\N	7	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1951161	\N	loc09a99bf786b9	P	3678	\N	\N	0	412833862	6	\N	\N	\N
GAVIC423110860	2009-04-05	2021-08-05	\N	BOTANIC GARDENS RET VLGE	\N	\N	\N	UNIT	\N	133	\N	\N	\N	\N	\N	\N	41	\N	\N	\N	\N	VIC2054961	\N	loc1a22f173d7f3	P	3977	\N	133\\PS306331	2	423222907	7	\N	202574096	S
GAVIC412549753	2005-10-12	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	68	\N	\N	\N	\N	VIC2012550	\N	loc2424df148d7d	P	3139	\N	1\\TP169088	2	412671558	7	\N	1354555	\N
GAVIC421042152	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4	\N	\N	\N	\N	VIC2079635	\N	loc7c934a667999	P	3915	\N	55\\LP91242	2	421177464	7	\N	1167500	\N
GAVIC412676699	2004-10-28	2021-08-03	\N	\N	\N	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1970763	\N	loc0de2086617a5	P	3678	\N	\N	0	412830940	6	\N	\N	\N
GAVIC420674743	2024-04-16	2024-04-30	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	112	\N	\N	114	\N	VIC2032116	\N	locc586266ef8cc	P	3850	\N	1\\SP25881	0	420803245	7	\N	125441736	P
GAVIC420732404	2005-10-14	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	116	\N	\N	\N	\N	VIC1942695	\N	loc4e07cec4cde4	P	3804	\N	8\\LP81131	2	420867943	7	\N	2049935	\N
GAVIC420257417	2005-10-14	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	50	\N	\N	\N	\N	VIC1966266	\N	loc0b665c0fe535	P	3226	\N	332\\LP116133	2	420387962	7	\N	41007336	\N
GAVIC419688276	2006-05-02	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3	\N	\N	\N	\N	\N	\N	460	\N	\N	\N	\N	VIC1970315	\N	loc3b64e6146ff8	P	3195	\N	3\\RP8465	1	419816780	7	\N	50102788	S
GAVIC423081290	2006-01-15	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	9	\N	\N	\N	\N	VIC2015632	\N	loc679429866800	P	3695	\N	14~D\\PP2734	2	423193444	7	\N	45353569	\N
GAVIC420504897	2010-07-12	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	563	\N	\N	\N	\N	VIC1974317	\N	loc5c27e3f22fc1	P	3122	\N	CM1\\PS610457	0	420632037	7	\N	212390373	P
GAVIC423509973	2006-01-14	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	9	\N	\N	\N	\N	VIC2013030	\N	loc46b3ff1e6b9a	P	3133	\N	1\\PS529260	2	423604983	7	\N	203254493	S
GAVIC420684174	2021-01-19	2021-08-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	13	\N	\N	\N	\N	VIC2070646	\N	loc4ff8c926c940	P	3147	\N	340\\LP53681	0	420823345	7	\N	568961	P
GAVIC424265017	2008-12-29	2021-08-05	\N	THE CARD LOT	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	489	\N	\N	\N	\N	VIC653423	\N	loc515028b0f98a	P	3722	\N	1\\PS324581	2	424351848	7	\N	5408305	\N
GAVIC421983130	2007-03-22	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	5	\N	\N	\N	\N	VIC2004239	\N	loc819a06b032e3	P	3029	\N	461\\PS510193	2	422113967	7	\N	150336209	\N
GAVIC419754099	2008-12-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	32	\N	\N	\N	\N	VIC2079446	\N	loc62ed665318da	P	3620	\N	1\\TP428890	2	419886687	7	\N	52964139	\N
GAVIC721704334	2025-01-17	2025-07-21	\N	\N	\N	\N	\N	UNIT	\N	201	\N	\N	\N	\N	\N	\N	159	\N	\N	\N	\N	VIC1958350	\N	locf51f6cd689bb	P	3205	\N	201\\PS918614	2	717906857	7	\N	456043942	S
GAVIC420656885	2005-04-14	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	7	\N	\N	\N	\N	VIC1953967	\N	loca1efec8fa041	P	3129	\N	1\\SP24381	2	420788115	7	\N	52924174	S
GAVIC424282372	2010-07-13	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	6	\N	\N	\N	\N	VIC2997584	\N	loceac5d85ea01d	P	3024	\N	411\\PS510502	2	424369203	7	\N	210235932	\N
GAVIC719207295	2018-05-08	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	69	\N	\N	\N	\N	VIC1943978	\N	loc9a48431374e1	P	3207	\N	19\\PS718981	2	714592328	7	\N	420699489	\N
GAVIC411852098	2009-07-21	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	14	\N	\N	\N	\N	VIC1958513	\N	locdd716f1059c5	P	3194	\N	3\\PS409828	2	411999327	7	\N	52423898	\N
GAVIC421756773	2021-07-25	2025-04-27	\N	COMMUNITY CENTRE	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	101	\N	\N	121	\N	VIC2058076	\N	locb8f595af5fb8	P	3150	\N	1\\PS648520	1	421859624	7	\N	220285922	P
GAVIC721025623	2025-10-16	2025-10-30	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10	\N	\N	\N	\N	VIC4123121	\N	loc8733d13ded2e	P	3336	\N	163\\PS902772	2	717226582	7	\N	452807763	\N
GAVIC420583086	2025-10-15	2025-10-30	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	48	\N	\N	\N	\N	VIC1962407	\N	loc39cd317eec9d	P	3169	\N	1\\PS918522	1	420723393	7	\N	455880293	P
GAVIC420921756	2010-10-21	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	23	\N	\N	\N	\N	VIC1976701	\N	loc1eda86883ae9	P	3922	\N	151\\LP54853	2	421050712	7	\N	5213430	\N
GAVIC421753831	2010-01-21	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	9	\N	\N	\N	\N	VIC2076646	\N	locc67851215f08	P	3048	\N	135\\LP135690	2	421873707	7	\N	261511	\N
GAVIC419621302	2013-10-23	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	23	\N	\N	\N	\N	\N	\N	346	\N	\N	354	\N	VIC1945465	\N	loc9165cd64854f	P	3153	\N	23\\RP12800	2	419749804	7	\N	2077104	S
GAVIC424746499	2011-11-01	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	116	B	L	\N	1	\N	\N	480	\N	\N	\N	\N	VIC1970018	\N	loc9901d119afda	P	3000	\N	116B\\PS523999	0	424831860	7	\N	209514138	S
GAVIC420051005	2011-11-02	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3	\N	\N	\N	\N	\N	\N	115	\N	\N	\N	\N	VIC1961381	\N	loc6413994c2b24	P	3199	\N	3\\RP14278	2	420200380	7	\N	52835744	S
GAVIC424490619	2009-10-08	2025-01-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	94	\N	\N	\N	\N	VIC1962988	\N	locc81a6ec90a1b	P	3939	\N	RES1\\LP50907	0	424576649	7	\N	1060609	P
GAVIC423705816	2007-12-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	38	\N	\N	40	\N	VIC1984350	\N	loc8e5a2b16aaaa	P	3844	\N	40\\PS504138	1	423799056	7	\N	53088013	\N
GAVIC423716042	2007-07-24	2021-08-05	\N	COLIN MCCLELLAND AND ASSOCIATES	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	201	\N	\N	\N	\N	VIC1951022	\N	locc098f71b2faf	P	3350	\N	2\\PS448234	2	423809282	7	\N	53073763	\N
GAVIC412089403	2010-07-12	2023-04-23	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	14	\N	\N	\N	\N	VIC2080341	\N	loc12c0177d3d38	P	3044	\N	2\\PS502102	2	412233908	7	\N	214936883	S
GAVIC719244724	2017-01-24	2021-07-07	\N	\N	\N	\N	\N	SHOP	\N	7	\N	\N	\N	\N	\N	\N	945	\N	\N	\N	\N	VIC2052113	\N	loc9fe59dbd0874	P	3977	\N	4\\PS611693	0	714629757	7	\N	\N	S
GAVIC423398421	2020-10-19	2021-08-03	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1999859	\N	loc6c0f29d040f7	P	3562	\N	\N	0	423493799	6	\N	\N	\N
GAVIC424777831	2012-07-13	2023-11-05	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10	\N	\N	12	\N	VIC1971247	\N	locb281644d861d	P	3160	\N	6\\LP9574	0	424863192	7	\N	219084818	P
GAVIC420510289	2004-11-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	34	\N	\N	\N	\N	VIC2000595	\N	loc70eb03d586f8	P	3023	\N	387\\LP13508	2	420658313	7	\N	2002826	\N
GAVIC412227164	2009-04-03	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10	\N	\N	\N	\N	VIC2068940	\N	locfd8472c41cbe	P	3178	\N	CM1\\PS517666	1	412379387	7	\N	172107232	P
GAVIC425013948	2012-07-13	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	312	\N	FL	\N	3	\N	\N	839	\N	\N	\N	\N	VIC1961385	\N	loc2d817b7080e2	P	3145	\N	312\\PS629876	0	425099296	7	\N	219236181	S
GAVIC412681818	2004-10-28	2021-08-03	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1938826	\N	loc8e5a2b16aaaa	P	3844	\N	\N	0	412843484	6	\N	\N	\N
GAVIC424531851	2011-04-27	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	11	\N	\N	\N	\N	VIC3353154	\N	loce16236caf708	P	3212	\N	14\\PS623387	2	424617681	7	\N	212856856	\N
GAVIC425093622	2012-10-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1118	\N	\N	\N	\N	VIC3572139	\N	loca5643321b976	P	3518	\N	101\\PP3415	2	425179311	7	\N	45417983	\N
GAVIC422294300	2008-06-27	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	36	\N	\N	\N	\N	VIC1952872	\N	loc3832b905a97e	P	3690	\N	60\\PS518071	2	422406512	7	\N	103040094	\N
GAVIC412670644	2012-07-15	2021-08-03	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1969682	\N	locf3eb6fff8056	P	3678	\N	\N	0	412839624	6	\N	\N	\N
GAVIC411825992	2013-04-19	2021-08-14	\N	CITY CONDOS	\N	\N	\N	UNIT	\N	53	\N	\N	\N	\N	\N	\N	416	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	53\\PS416159	2	411967773	7	\N	52599817	S
GAVIC425167658	2013-01-10	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	L	\N	2	\N	\N	53	\N	\N	57	\N	VIC2080683	\N	loc9901d119afda	P	3000	\N	1\\TP758232	0	425255917	7	\N	203499765	S
GAVIC411441273	2012-10-17	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	2	\N	\N	\N	\N	\N	\N	159	\N	\N	\N	\N	VIC2036759	\N	locadc5cabaa80e	P	3146	\N	2\\RP13641	0	411585778	7	\N	\N	S
GAVIC719915818	2018-10-28	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	5405	\N	L	\N	54	\N	\N	462	\N	\N	\N	\N	VIC1963013	\N	loc9901d119afda	P	3000	\N	5405\\PS728807	0	715300859	7	\N	428305072	S
GAVIC423750017	2013-07-16	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	2007	\N	L	\N	20	\N	\N	1	\N	\N	\N	\N	VIC1962002	\N	loc31f384e524fe	P	3006	\N	2007\\PS504017	0	423841412	7	\N	206307060	S
GAVIC719925941	2018-10-28	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	204	\N	L	\N	2	\N	\N	7	\N	\N	\N	\N	VIC1953368	\N	loc3319215a0a10	P	3186	\N	204\\PS807792	0	715310982	7	\N	427925496	S
GAVIC420751807	2014-04-18	2021-07-27	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	22	\N	\N	\N	\N	VIC2002748	\N	loc3b6fd5dcd874	P	3943	\N	13\\LP13917	2	420894156	7	\N	1066600	\N
GAVIC424675889	2014-10-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	42	\N	\N	\N	\N	VIC2981005	\N	locff62fb6a898a	P	3201	\N	85\\PS611686	2	424761278	7	\N	212646708	\N
GAVIC425367645	2014-01-21	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3	\N	\N	\N	\N	\N	\N	40	\N	\N	\N	\N	VIC3338061	\N	loce25dfc481765	P	3764	\N	B\\PS602264	0	425455908	7	\N	\N	S
GAVIC425368628	2014-04-18	2021-08-03	\N	\N	\N	820	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2061938	\N	loc9a86c6faf562	P	3556	\N	\N	1	425456891	6	\N	\N	\N
GAVIC425484937	2014-10-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	7	A	\N	\N	\N	VIC2001577	\N	loc0621c45c46f4	P	3104	\N	2\\PS716444	2	425573227	7	\N	420183241	\N
GAVIC425461232	2014-10-17	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	104	\N	\N	\N	\N	\N	\N	68	\N	\N	\N	\N	VIC2069101	\N	locc2ea2de6af6c	P	3141	\N	104\\PS713407	2	425549522	7	\N	221743512	S
GAVIC425512108	2014-10-17	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1304	\N	L	\N	13	\N	\N	53	\N	\N	\N	\N	VIC1945221	\N	loc0b8afd71fce1	P	3003	\N	1304\\PS703332	0	425600398	7	\N	221194187	S
GAVIC419645242	2014-07-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	74	\N	\N	\N	\N	VIC2014251	\N	loc86cf2bd4847b	P	3163	\N	CM1\\PS509940	1	419773744	7	\N	150526733	P
GAVIC425734206	2015-10-26	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	406	\N	L	\N	4	\N	\N	67	\N	\N	\N	\N	VIC2062049	\N	loc9e7da77def26	P	3052	\N	12406\\PS709099	0	425822516	7	\N	422777428	S
GAVIC425622336	2015-04-10	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	405	\N	L	\N	4	\N	\N	525	\N	\N	\N	\N	VIC2006220	\N	loca0398a35cf5e	P	3053	\N	405N3S\\PS627030	0	425710626	7	\N	421376062	S
GAVIC425480664	2015-01-19	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	308	\N	\N	\N	\N	\N	\N	6	\N	\N	\N	\N	VIC3573679	\N	locb9872f35df41	P	3067	\N	320B\\PS641350	2	425568954	7	\N	420674570	S
GAVIC719987520	2019-01-24	2021-08-05	\N	\N	\N	\N	\N	UNIT	\N	23	S	\N	\N	\N	\N	\N	296	\N	\N	\N	\N	VIC1990305	\N	loc9901d119afda	P	3000	\N	23S\\PS742122	0	715372561	7	\N	429048847	S
GAVIC719985042	2019-01-24	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1718	\N	L	\N	17	\N	\N	160	\N	\N	\N	\N	VIC2061385	\N	loca0398a35cf5e	P	3053	\N	1718\\PS742732	0	715370083	7	\N	428795600	S
GAVIC719988843	2019-01-24	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	2002	\N	L	\N	20	\N	\N	63	\N	\N	\N	\N	VIC1990396	\N	loc31f384e524fe	P	3006	\N	2002\\PS739783	0	715373884	7	\N	428246202	S
GAVIC425231579	2016-07-25	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	24	\N	\N	\N	\N	VIC3568919	\N	loc9ea2b366d63f	P	3977	\N	950\\PS711413	2	425319845	7	\N	220950247	\N
GAVIC420502224	2020-07-22	2021-07-27	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	27	\N	\N	\N	\N	VIC1978531	\N	loc82baa1179308	P	3810	\N	\N	1	420631407	7	\N	\N	P
GAVIC422024006	2016-07-25	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	7	\N	\N	\N	\N	VIC2028446	\N	loc76dea039b41f	P	3144	\N	7\\PS714394	2	422154843	7	\N	422153741	P
GAVIC719528632	2019-01-25	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	17	\N	\N	\N	\N	VIC3621616	\N	loc1b271c01e3dc	P	3064	\N	710\\PS805186	2	714913664	7	\N	425974561	\N
GAVIC425820590	2017-04-21	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3	\N	\N	\N	\N	\N	\N	2	\N	\N	\N	\N	VIC2064408	\N	loc656f84726510	P	3073	\N	3\\PS738693	2	425908900	7	\N	423418940	S
GAVIC719527287	2017-10-17	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	1201	\N	L	\N	12	\N	\N	499	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	1201\\PS737521	0	714912319	7	\N	426500616	S
GAVIC425272501	2017-10-18	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10	\N	\N	\N	\N	VIC3572470	\N	loc6d7f0d49a3d6	P	3750	\N	2649\\PS645334	2	425360767	7	\N	220492644	\N
GAVIC411670057	2017-10-26	2021-08-05	\N	MOTHER ROMANA HOME	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	11	\N	\N	15	\N	VIC1935602	\N	loc00a9769647d7	P	3101	\N	CP167086	2	411814562	7	\N	100011	\N
GAVIC413384563	2017-10-26	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	275	\N	\N	\N	\N	VIC1944348	\N	locb694454fbbb1	P	3126	\N	CP101885	1	413526344	7	\N	210161442	\N
GAVIC421307669	2017-10-26	2023-11-05	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1456	\N	\N	\N	\N	VIC1981006	\N	locadc5cabaa80e	P	3146	\N	1\\PS336123	1	421436852	7	\N	208432940	P
GAVIC423632802	2017-10-26	2021-07-07	\N	\N	\N	\N	\N	CARS	\N	806	\N	\N	\N	\N	\N	\N	58	\N	\N	\N	\N	VIC1960434	\N	loc9901d119afda	P	3000	\N	806\\PS442086	0	423726275	7	\N	206159518	S
GAVIC719913128	2019-04-25	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3	\N	\N	\N	\N	\N	\N	10	\N	\N	\N	\N	VIC2010068	\N	loc1492a23dbc74	P	3081	\N	3\\PS814603	2	715298169	7	\N	426527490	S
GAVIC421219047	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	16	\N	\N	\N	\N	VIC1969439	\N	loc9b20cd160517	P	3148	\N	2\\PS409121	2	421346876	7	\N	52470262	\N
GAVIC420615360	2004-04-29	2024-04-18	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	15	A	\N	\N	\N	VIC1957930	\N	loc87f2ad0c0fd7	P	3121	\N	3\\PS336159	2	420756334	7	\N	52482806	\N
GAVIC719420229	2017-07-26	2021-08-14	\N	\N	\N	\N	\N	UNIT	P	210	\N	\N	\N	\N	\N	\N	348	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	P210\\PS409115	0	714805257	7	\N	52557085	S
GAVIC420229782	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	28	\N	\N	\N	\N	VIC1989339	\N	loca1a84d46e52a	P	3076	\N	321\\LP206964	2	420359646	7	\N	309525	\N
GAVIC421300826	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	9	\N	\N	\N	\N	VIC1979239	\N	locf066999b6a14	P	3803	\N	21\\LP208558	2	421442494	7	\N	673565	\N
GAVIC420533207	2005-01-11	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	34	\N	\N	\N	\N	VIC1978444	\N	loc7ab22202aac3	P	3108	\N	30\\LP143954	2	420671470	7	\N	2065879	\N
GAVIC419661586	2008-10-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	30	\N	\N	\N	\N	VIC1940668	\N	loce1597eda1cc3	P	3214	\N	CM\\PS311984	1	419788726	7	\N	207907426	P
GAVIC421242246	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	38	\N	\N	\N	\N	VIC1969874	\N	loc201e214973bd	P	3079	\N	2\\PS423690	2	421377558	7	\N	52784063	\N
GAVIC721366499	2024-01-16	2024-01-29	\N	\N	\N	\N	\N	UNIT	\N	1801	\N	\N	\N	\N	\N	\N	36	\N	\N	\N	\N	VIC2024158	\N	loca5de38b84720	P	3128	\N	1801\\PS831941	2	717568260	7	\N	454314290	S
GAVIC422277019	2004-10-21	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	35	\N	\N	\N	\N	VIC1948395	\N	locb7bca082fca0	P	3237	\N	2\\TP171629	1	422389231	7	\N	45514694	\N
GAVIC719439216	2017-07-26	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	307	\N	L	\N	3	\N	\N	388	\N	\N	\N	\N	VIC2080714	\N	loc1e06c486c813	P	3051	\N	307CA\\PS721454	0	714824244	7	\N	426128064	S
GAVIC421548655	2024-01-16	2024-01-29	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	81	\N	\N	83	\N	VIC2034844	\N	locb53ace4ff1b6	P	3374	\N	1\\PS546647	2	421712789	7	\N	126216278	\N
GAVIC420900117	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	20	\N	\N	\N	\N	VIC1939009	\N	locd665688d0e4d	P	3305	\N	1\\TP604100	2	421034752	7	\N	5127181	\N
GAVIC719439819	2017-07-26	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	68	\N	\N	\N	\N	VIC2043038	\N	locfa38377aaf29	P	3691	\N	19~6\\PP2863	0	714824847	7	\N	136254837	\N
GAVIC419868312	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	26	\N	\N	\N	\N	VIC1986516	\N	loc025dead673cc	P	3195	\N	21\\LP43256	2	420012023	7	\N	1432369	\N
GAVIC420833582	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	32	\N	\N	\N	\N	VIC1985830	\N	loc51ba976fe589	P	3046	\N	350\\LP11526	2	420967986	7	\N	261234	\N
GAVIC423748775	2006-10-26	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	8	\N	\N	\N	\N	VIC1962844	\N	loc17a18f5ff3a6	P	3023	\N	356\\PS533498	2	423840170	7	\N	202818295	\N
GAVIC420695756	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	48	\N	\N	\N	\N	VIC2023428	\N	loc3754c5fc3408	P	3064	\N	1846\\PS344030	2	420840829	7	\N	65334	\N
GAVIC421832935	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	2	\N	\N	\N	\N	\N	\N	72	\N	\N	\N	\N	VIC1930548	\N	loc2c4c767ea9b7	P	3072	\N	2\\RP12205	2	421972789	7	\N	52680859	S
GAVIC419618007	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	9	\N	\N	\N	\N	VIC1997861	\N	loc656f84726510	P	3073	\N	8\\LP44181	2	419752865	7	\N	194152	\N
GAVIC720913095	2022-01-25	2022-02-09	\N	ANNUAL SITE 72	\N	\N	\N	SITE	\N	72	\N	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	VIC2078131	\N	locc672a234fa5a	P	3232	\N	P\\PP5478	0	717113574	7	\N	41112926	S
GAVIC421924109	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	24	\N	\N	\N	\N	VIC2028573	\N	loc406d1f7b5fe3	P	3106	\N	76\\LP121572	2	422054200	7	\N	965940	\N
GAVIC423974946	2018-01-20	2023-05-07	\N	COMMODORE ANGLNG BOAT CLB	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	182	\N	\N	\N	\N	VIC2017947	\N	loca37d9a7b347e	P	3551	\N	37H\\PP2879	1	424063457	7	\N	126932420	\N
GAVIC420647207	2012-01-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	11	\N	\N	\N	\N	VIC2034902	\N	loc5ba812288f5b	P	3224	\N	1\\PS520267	1	420778434	7	\N	218125876	P
GAVIC420734999	2010-01-21	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4	\N	\N	\N	\N	VIC2070226	\N	locc7ee8539a72b	P	3095	\N	340\\LP98918	2	420868495	7	\N	984576	\N
GAVIC420591242	2012-04-14	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	17	\N	\N	\N	\N	VIC1968404	\N	loc74f8893fb76e	P	3047	\N	1018\\LP58934	1	420725420	7	\N	219012138	P
GAVIC420118258	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	8	\N	\N	\N	\N	VIC1951821	\N	loc6ae7eaa3c1f3	P	3128	\N	1\\TP548176	2	420246079	7	\N	722855	\N
GAVIC420100287	2005-01-11	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10	\N	\N	12	\N	VIC1940808	\N	loca1b6ce72e35a	P	3149	\N	1\\SP27650	0	420234237	7	\N	60042768	P
GAVIC420206310	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	5	\N	\N	\N	\N	VIC1946124	\N	loc29a798d6921b	P	3030	\N	26\\PS306342	2	420339350	7	\N	1775613	\N
GAVIC421049989	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	71	\N	\N	\N	\N	VIC2023132	\N	loc4a7c5154c298	P	3039	\N	1\\TP379434	2	421175767	7	\N	1010205	\N
GAVIC420773569	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	7	\N	\N	\N	\N	VIC1979753	\N	loca307cf61ba97	P	3021	\N	833\\LP210155	2	420910016	7	\N	1234570	\N
GAVIC425274882	2013-07-16	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1905	\N	L	\N	19	\N	\N	39	\N	\N	\N	\N	VIC1953262	\N	loc31f384e524fe	P	3006	\N	1905\\PS638768	0	425363148	7	\N	220404799	S
GAVIC421731563	2004-04-29	2023-08-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	7	\N	\N	\N	\N	VIC2009322	\N	loc29a798d6921b	P	3030	\N	7\\LP10129	2	421861654	7	\N	1792100	P
GAVIC422034832	2004-06-24	2025-01-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	113	\N	\N	\N	\N	VIC2045776	\N	loc6de6554b144b	P	3698	\N	1\\LP216224	1	422165669	7	\N	52510952	S
GAVIC721914294	2026-01-16	2026-01-29	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	20	\N	\N	\N	\N	VIC4111949	\N	locffa1c8993b70	P	3024	\N	27040\\PS832163	0	718117102	7	\N	452388407	\N
GAVIC719754089	2018-05-07	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3010	\N	L	\N	30	\N	\N	8	\N	\N	\N	\N	VIC2007449	\N	locddc4a1bcd8ba	P	3008	\N	3010\\PS728852	0	715139112	7	\N	427232166	S
GAVIC421995183	2004-07-02	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	8	\N	\N	\N	\N	VIC1941988	\N	loc17a18f5ff3a6	P	3023	\N	89\\PS415872	2	422126020	7	\N	150211688	\N
GAVIC421481149	2008-04-06	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	25	\N	\N	\N	\N	VIC2061406	\N	loc656f84726510	P	3073	\N	1\\PS600500	2	421563343	7	\N	208530357	\N
GAVIC424877747	2012-01-21	2023-07-31	\N	SHOWGROUNDS VILLAGE SHOPPING M	\N	\N	\N	SHOP	\N	22	\N	\N	\N	\N	\N	\N	320	\N	\N	380	\N	VIC2064406	\N	loc92bf5bc798e7	P	3031	\N	2216\\PP2541	1	424963115	7	\N	215548597	S
GAVIC423409956	2005-07-11	2021-08-03	\N	\N	\N	6	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2044329	\N	loc11fb0b5df130	P	3840	\N	\N	0	423505331	6	\N	\N	\N
GAVIC423404123	2005-07-11	2021-08-03	\N	\N	\N	5	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2021931	\N	loc991c414cb6c9	P	3756	\N	\N	0	423499498	6	\N	\N	\N
GAVIC423399692	2005-07-11	2021-08-03	\N	\N	\N	35	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1981938	\N	locc84be248155b	P	3777	\N	\N	0	423495070	6	\N	\N	\N
GAVIC721162609	2024-07-14	2025-01-19	\N	\N	\N	\N	\N	UNIT	\N	2	\N	\N	\N	\N	\N	\N	8	\N	\N	\N	\N	VIC1962976	\N	locfd8472c41cbe	P	3178	\N	2\\PS901024	2	717363938	7	\N	454092909	S
GAVIC419837839	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	70	\N	\N	\N	\N	VIC1962988	\N	locc81a6ec90a1b	P	3939	\N	55\\LP50907	2	419982912	7	\N	1047968	\N
GAVIC420980761	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	16	\N	\N	\N	\N	VIC2059240	\N	loc264c2d9ba83e	P	3170	\N	645\\LP70821	2	421126511	7	\N	567188	\N
GAVIC421930895	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3	\N	\N	\N	\N	VIC1988479	\N	loca56f2b16461e	P	3105	\N	72\\LP13075	2	422047366	7	\N	952991	\N
GAVIC425732776	2024-04-16	2024-04-30	\N	\N	\N	\N	\N	UNIT	\N	26	\N	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	VIC1961067	\N	loc5900b8cc74c8	P	3953	\N	S3\\PS717009	1	425821086	7	\N	456611699	S
GAVIC419620282	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	24	\N	\N	\N	\N	VIC1976825	\N	loceac5d85ea01d	P	3024	\N	1126\\LP114465	2	419746060	7	\N	1780208	\N
GAVIC419784455	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	33	\N	\N	\N	\N	VIC2037884	\N	locb8f595af5fb8	P	3150	\N	49\\LP82206	2	419915681	7	\N	560418	\N
GAVIC420454965	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	358	\N	\N	\N	\N	VIC1989474	\N	loc67d2e4d427ab	P	3944	\N	4\\LP110711	2	420587553	7	\N	1054970	\N
GAVIC420148109	2007-07-23	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	6	\N	\N	\N	\N	VIC1932710	\N	loca674ab421c49	P	3666	\N	1\\TP21771	2	420281832	7	\N	52902723	\N
GAVIC421444901	2024-04-16	2024-04-30	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	551	\N	\N	\N	\N	VIC2028669	\N	loc3b583afba248	P	3172	\N	20\\LP79867	2	421561145	7	\N	454406362	\N
GAVIC425275442	2013-07-16	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	302	\N	FL	\N	3	\N	\N	839	\N	\N	\N	\N	VIC1961385	\N	loc2d817b7080e2	P	3145	\N	302\\PS629876	0	425363708	7	\N	219236161	S
GAVIC421147883	2020-07-22	2021-07-27	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10	\N	\N	\N	\N	VIC2073360	\N	loc12c0177d3d38	P	3044	\N	\N	1	421278882	7	\N	\N	P
GAVIC721916596	2026-01-16	2026-01-29	\N	\N	\N	\N	\N	UNIT	\N	5	\N	\N	\N	\N	\N	\N	28	\N	\N	\N	\N	VIC2031732	\N	loc8f498b475ec6	P	3844	\N	5\\PS935877	0	718119404	7	\N	459327581	S
GAVIC421479094	2004-11-19	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	16	\N	\N	\N	\N	VIC1947995	\N	loc0b665c0fe535	P	3226	\N	225\\LP55384	2	421588755	7	\N	41005319	\N
GAVIC423490362	2005-10-12	2021-08-14	\N	\N	\N	\N	\N	CARS	\N	303	\N	\N	\N	\N	\N	\N	431	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	303\\RP18468	0	423585372	7	\N	203512793	S
GAVIC421499309	2005-10-12	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	9	\N	\N	\N	\N	\N	\N	61	\N	\N	\N	\N	VIC1980990	\N	locb17fb225139f	P	3079	\N	9\\SP20936	1	421618968	7	\N	50040615	S
GAVIC421143250	2005-10-14	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	25	\N	\N	\N	\N	VIC1983036	\N	loc36422efcb9c0	P	3222	\N	1334\\LP54102	2	421274476	7	\N	41007275	\N
GAVIC423490030	2005-10-12	2021-08-14	\N	\N	\N	\N	\N	CARS	\N	137	\N	\N	\N	\N	\N	\N	431	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	137\\RP18468	0	423585040	7	\N	203512968	S
GAVIC420886416	2005-10-14	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2	\N	\N	\N	\N	VIC2065745	\N	loc1fbfb471eb7c	P	3434	\N	1251\\LP206571	2	421027630	7	\N	5068349	\N
GAVIC412667511	2012-07-15	2021-08-03	\N	\N	\N	2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2076198	\N	locf3fc3fca2acd	P	3175	\N	\N	0	412827101	6	\N	\N	\N
GAVIC423910455	2010-01-19	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	3504	\N	\N	\N	\N	\N	\N	368	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	3504\\PS419703	2	424001086	7	\N	206371825	S
GAVIC419660068	2008-06-27	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10	\N	\N	\N	\N	VIC1940488	\N	locd06d20cbea22	P	3550	\N	1\\PS615811	2	419795153	7	\N	128070046	\N
GAVIC424637478	2018-05-07	2021-08-05	\N	CHADSTONE SHOPPING CENTRE	\N	\N	\N	UNIT	\N	339	A	\N	\N	\N	\N	\N	1341	\N	\N	\N	\N	VIC1961385	\N	loc2d817b7080e2	P	3145	\N	1\\TP950949	1	424722869	7	\N	213320046	S
GAVIC423648868	2010-01-17	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1103	\N	L	\N	11	\N	\N	60	\N	\N	\N	\N	VIC2044273	\N	locddc4a1bcd8ba	P	3008	\N	1103\\PS448830	0	423742341	7	\N	152639738	S
GAVIC419898327	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12	\N	\N	\N	\N	VIC1930047	\N	locad899e5d272f	P	3193	\N	1\\TP748491	2	420033639	7	\N	1592748	\N
GAVIC421262022	2005-01-11	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1	A	\N	\N	\N	VIC2065164	\N	loc76dea039b41f	P	3144	\N	1\\LP39932	0	421389843	7	\N	\N	P
GAVIC719754869	2018-05-08	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	11	\N	\N	\N	\N	VIC1994235	\N	loc3d949ab3c987	P	3202	\N	1\\PS801055	2	715139892	7	\N	427437196	S
GAVIC421787496	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	31	\N	\N	\N	\N	VIC2040573	\N	locff58d0167065	P	3672	\N	1\\LP21901	2	421944818	7	\N	5198605	\N
GAVIC719413114	2018-05-08	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	11	\N	\N	\N	\N	VIC2061025	\N	locb948618ae376	P	3356	\N	1\\PS800139	2	714798142	7	\N	424056056	S
GAVIC425730031	2018-05-08	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	19	\N	\N	\N	\N	VIC3616200	\N	loc0a03ed3531fd	P	3192	\N	32\\PS727996	2	425818341	7	\N	422103926	\N
GAVIC425309480	2014-07-19	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	4	\N	\N	\N	\N	\N	\N	40	\N	\N	\N	\N	VIC1932338	\N	loc656f84726510	P	3073	\N	4\\PS719130	2	425397743	7	\N	221298151	S
GAVIC414839745	2009-10-08	2025-01-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	7	\N	\N	9	\N	VIC1951129	\N	loc7f158a48110c	P	3942	\N	1931\\LP43379	1	414965183	7	\N	1036076	P
GAVIC425369445	2014-01-22	2021-08-03	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC3574045	\N	loc75d84680b181	P	3572	\N	\N	0	425457708	6	\N	\N	\N
GAVIC423401833	2020-10-19	2021-08-03	\N	\N	\N	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC1999638	\N	loc1c5f2c23fc52	P	3707	\N	\N	0	423497210	6	\N	\N	\N
GAVIC412676977	2010-01-21	2021-08-03	\N	\N	\N	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC2007606	\N	loc0a8087d68433	P	3501	\N	\N	0	412834080	6	\N	\N	\N
GAVIC422091233	2025-10-15	2025-10-30	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	19	\N	\N	\N	\N	VIC1957218	\N	loc3319215a0a10	P	3186	\N	CM\\RP8001	1	422222039	7	\N	52853017	P
GAVIC423792711	2013-07-16	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3001	\N	L	\N	30	\N	\N	100	\N	\N	\N	\N	VIC1993696	\N	locddc4a1bcd8ba	P	3008	\N	3001\\PS509916	0	423883673	7	\N	206189352	S
GAVIC424628057	2011-11-03	2021-08-05	\N	POINT COOK RET VILLAGE	\N	\N	\N	UNIT	\N	34	\N	\N	\N	\N	\N	\N	320	\N	\N	\N	\N	VIC2017941	\N	locc5abea08e85d	P	3030	\N	NB\\PS627343	2	424713448	7	\N	216801606	S
GAVIC423436506	2005-10-14	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	11	\N	\N	\N	\N	VIC1944783	\N	locc91f4a31a1bc	P	3037	\N	5211\\PS523497	2	423531516	7	\N	172537324	\N
GAVIC421565163	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	9	\N	\N	\N	\N	VIC1976256	\N	loc9901d119afda	P	3000	\N	9\\PS337555	1	421685051	7	\N	52903099	\N
GAVIC424354717	2009-07-22	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	46	\N	\N	\N	\N	VIC1960025	\N	loc70eb03d586f8	P	3023	\N	952\\PS613831	2	424440974	7	\N	210239463	\N
GAVIC424879721	2012-07-15	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3	\N	\N	\N	\N	\N	\N	50	\N	\N	\N	\N	VIC1984283	\N	loc5100fc96abff	P	3934	\N	3\\PS642200	2	424965089	7	\N	215500201	S
GAVIC424906559	2012-04-17	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	59	\N	FL	\N	3	\N	\N	80	\N	\N	\N	\N	VIC1937464	\N	locdd716f1059c5	P	3194	\N	59\\PS612989	1	424991927	7	\N	217455958	S
GAVIC425008870	2012-07-13	2021-07-07	\N	\N	\N	\N	\N	CARS	\N	38	\N	\N	\N	\N	\N	\N	140	\N	\N	\N	\N	VIC1944127	\N	loc9901d119afda	P	3000	\N	38\\PS428191	0	425094218	7	\N	219433177	S
GAVIC423917985	2012-07-15	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	704	\N	\N	\N	\N	\N	\N	57	\N	\N	\N	\N	VIC2066602	\N	loc9a48431374e1	P	3207	\N	A704\\PS500744	2	424006537	7	\N	208098670	S
GAVIC419625837	2012-10-18	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	20	\N	\N	\N	\N	\N	\N	2	\N	\N	\N	\N	VIC1930906	\N	locea2e2e01b99c	P	3189	\N	20\\PS331818	1	419761603	7	\N	23398	S
GAVIC425083938	2013-04-19	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	26	\N	\N	\N	\N	VIC1985830	\N	loc51ba976fe589	P	3046	\N	1\\PS706421	2	425169627	7	\N	219419014	S
GAVIC421279891	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	14	\N	\N	\N	\N	VIC2059476	\N	loc1b289d3ff2fc	P	3630	\N	131\\LP27673	2	421404996	7	\N	5350966	\N
GAVIC423280693	2007-03-27	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	157	\N	\N	\N	\N	VIC1999075	\N	loc9901d119afda	P	3000	\N	\N	0	423376896	7	\N	\N	\N
GAVIC420178764	2007-01-05	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	11	\N	\N	\N	\N	VIC2004921	\N	loc786911d8fa57	P	3130	\N	CM1\\PS548498	1	420314530	7	\N	206456899	P
GAVIC425274073	2014-01-22	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	4005	\N	L	\N	40	\N	\N	241	\N	\N	\N	\N	VIC2059743	\N	loc31f384e524fe	P	3006	\N	4005\\PS638212	1	425362339	7	\N	219291893	S
GAVIC425486221	2014-07-19	2021-08-03	\N	\N	\N	1	A	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	VIC3137203	\N	loc108a649ba4ae	P	3451	\N	\N	0	425574511	6	\N	\N	\N
GAVIC421862656	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3	\N	\N	\N	\N	\N	\N	23	\N	\N	\N	\N	VIC1939111	\N	loccaca39f133a7	P	3081	\N	3\\RP15518	1	421985493	7	\N	52804606	S
GAVIC425511946	2014-10-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	6	\N	\N	\N	\N	VIC3575102	\N	loce0707ac065f9	P	3219	\N	CM1\\PS644026	1	425600236	7	\N	215993193	P
GAVIC718988205	2016-07-25	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	22	\N	\N	\N	\N	VIC3618129	\N	loc6a54ce63b777	P	3358	\N	182\\PS716071	2	714373238	7	\N	136321708	\N
GAVIC425272843	2014-07-19	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	15	\N	\N	\N	\N	\N	\N	91	\N	\N	\N	\N	VIC1948906	\N	locc7ee8539a72b	P	3095	\N	15\\PS708003	2	425361109	7	\N	221001025	S
GAVIC419701922	2015-04-10	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	24	\N	\N	\N	\N	VIC1961086	\N	loc1f73672977ce	P	3280	\N	60\\PS330936	2	419838142	7	\N	421649932	S
GAVIC425742442	2015-10-26	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	2	\N	\N	\N	\N	\N	\N	15	\N	\N	\N	\N	VIC2079106	\N	loc780d4ed4ca46	P	3215	\N	91\\LP23927	0	425830752	7	\N	422723015	S
GAVIC719979296	2019-01-24	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3810	\N	L	\N	38	\N	\N	105	\N	\N	\N	\N	VIC1962365	\N	loc31f384e524fe	P	3006	\N	3810\\PS734580	0	715364337	7	\N	427782169	S
GAVIC719309027	2017-04-21	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	111	\N	\N	117	\N	VIC3615353	\N	loc90b2f4dd8c2d	P	3217	\N	RES20\\PS709524	0	714694055	7	\N	424718402	\N
GAVIC419912498	2016-07-22	2022-04-23	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	17	\N	\N	\N	\N	VIC1951026	\N	loc098ac8eaabef	P	3028	\N	CM1\\PS722115	1	420044405	7	\N	421950589	P
GAVIC421674160	2019-01-24	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	179	\N	\N	\N	\N	VIC1944127	\N	loc9901d119afda	P	3000	\N	1\\TP418919	0	421817871	7	\N	429232422	\N
GAVIC719213944	2017-01-20	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	33	\N	\N	\N	\N	VIC3619998	\N	locf8d60bf51b6b	P	3940	\N	502\\LP89700	2	714598977	7	\N	1036902	\N
GAVIC719523562	2017-10-17	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	6104	\N	L	\N	61	\N	\N	442	\N	\N	\N	\N	VIC1963013	\N	loc9901d119afda	P	3000	\N	6105\\PS728842	0	714908594	7	\N	426506452	S
GAVIC425539243	2017-10-17	2021-08-05	\N	PROVIDENCE VILLAGE	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	27	\N	\N	\N	\N	VICL3557670	\N	loccabf2d0215b8	P	3340	\N	2\\TP536334	2	425627533	7	\N	426832350	\N
GAVIC719430501	2017-10-18	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	101	\N	\N	\N	\N	\N	\N	47	\N	\N	\N	\N	VIC2003761	\N	loc8c9f2867857c	P	3016	\N	101\\PS731964	2	714815529	7	\N	425415705	S
GAVIC411809712	2017-10-26	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	9	A	\N	\N	\N	\N	\N	29	\N	\N	\N	\N	VIC2025971	\N	loc9901d119afda	P	3004	\N	29\\SP25910	2	411960119	7	\N	52818346	S
GAVIC421379520	2017-10-26	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	43	\N	\N	\N	\N	VIC1978203	\N	locfd8472c41cbe	P	3178	\N	CM\\SP34466	1	421546605	7	\N	150981234	P
GAVIC419920752	2017-10-26	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	14	\N	\N	\N	\N	VIC1947379	\N	loc2c4c767ea9b7	P	3072	\N	CM1\\PS525004	1	420046530	7	\N	172534138	P
GAVIC423215409	2017-10-26	2023-11-05	\N	\N	\N	\N	\N	UNIT	\N	86	\N	\N	\N	\N	\N	\N	151	\N	\N	\N	\N	VIC2055058	\N	locfe955a87410d	P	3182	\N	1\\PS324369	2	423311651	7	\N	172744551	S
GAVIC425084593	2017-10-26	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	39	\N	\N	\N	\N	VIC1983076	\N	loc630ef4fec09d	P	3437	\N	33\\LP110304	0	425170282	7	\N	\N	S
GAVIC423643559	2017-10-26	2021-08-18	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	122	\N	\N	\N	\N	VIC2020817	\N	locb71d10cf3b7c	P	3500	\N	\N	0	423737032	6	\N	\N	\N
GAVIC720512281	2020-10-17	2021-07-07	\N	\N	\N	\N	\N	CARS	\N	2108	Y	\N	\N	\N	\N	\N	659	\N	\N	\N	\N	VIC1990305	\N	loc9901d119afda	P	3000	\N	2108Y\\PS746092	0	715897322	7	\N	432371173	S
GAVIC719921421	2019-04-25	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	216	\N	\N	\N	\N	\N	\N	450	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	216\\PS738892	2	715306462	7	\N	428575993	S
GAVIC720520900	2020-10-17	2021-07-07	\N	\N	\N	\N	\N	CARS	\N	6027	Z	\N	\N	\N	\N	\N	659	\N	\N	\N	\N	VIC1990305	\N	loc9901d119afda	P	3000	\N	6027Z\\PS746092	0	715905941	7	\N	432370584	S
GAVIC720518002	2020-10-17	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	1601	\N	L	\N	16	\N	\N	628	\N	\N	\N	\N	VIC1955730	\N	locddc4a1bcd8ba	P	3008	\N	11601\\PS704437	0	715903043	7	\N	432377514	S
GAVIC720296037	2020-01-21	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	80	A	\N	\N	\N	VIC1963115	\N	locffd0eebac0eb	P	3196	\N	2\\PS819538	2	715681078	7	\N	430855312	\N
GAVIC719745362	2020-01-21	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	7	\N	\N	\N	\N	\N	\N	87	\N	\N	93	\N	VIC2070959	\N	loc656f84726510	P	3073	\N	7\\PS802357	2	715130385	7	\N	425984071	S
GAVIC424599194	2021-04-10	2025-04-27	\N	BELLBROOK GARDENS VILLAGE	\N	\N	\N	UNIT	\N	98	\N	\N	\N	\N	\N	\N	168	\N	\N	\N	\N	VIC2027792	\N	locd777103bd088	P	3340	\N	1\\PS913850	2	424684659	7	\N	130691186	S
GAVIC720458378	2020-07-16	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3	\N	\N	\N	\N	VIC3627687	\N	loc875f8bb64843	P	3024	\N	16632\\PS837859	1	715843419	7	\N	431579374	\N
GAVIC721374676	2024-10-18	2024-10-30	\N	\N	\N	\N	\N	UNIT	\N	102	\N	\N	\N	\N	\N	\N	8	\N	\N	\N	\N	VIC1933214	\N	loc5c27e3f22fc1	P	3122	\N	PC381123	2	717576437	7	\N	455627624	S
GAVIC425703440	2020-10-17	2025-04-26	\N	LIFESTYLE CHELSEA HEIGHTS	\N	\N	\N	UNIT	\N	162	\N	\N	\N	\N	\N	\N	29	\N	\N	\N	\N	VIC2055433	\N	locc25e0bed112f	P	3196	\N	2\\PS646783	2	425791730	7	\N	432785118	S
GAVIC412527332	2020-10-17	2025-10-27	\N	LEVANDE SALFORD PARK	\N	\N	\N	UNIT	\N	127	\N	\N	\N	\N	\N	\N	100	\N	\N	\N	\N	VIC1995210	\N	loc4a341f4d3e02	P	3152	\N	2\\PS728985	2	412686819	7	\N	151453037	S
GAVIC425489617	2020-10-17	2025-04-26	\N	LIFESTYLE CHELSEA HEIGHTS	\N	\N	\N	UNIT	\N	39	\N	\N	\N	\N	\N	\N	29	\N	\N	\N	\N	VIC2055433	\N	locc25e0bed112f	P	3196	\N	1\\PS646783	2	425577907	7	\N	432785217	S
GAVIC425044566	2021-07-25	2021-08-14	\N	MENS SHED	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	14	\N	\N	\N	\N	VIC2038134	\N	locf57f2052e543	P	3200	\N	13\\LP58497	1	425129914	7	\N	217458630	\N
GAVIC420812068	2023-10-25	2023-11-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	VIC2037177	\N	loc29a798d6921b	P	3030	\N	232\\LP132461	1	420955779	7	\N	\N	P
GAVIC421708673	2023-10-25	2023-11-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	68	\N	\N	\N	\N	VIC1999163	\N	loc46443686a430	P	3020	\N	100\\LP12795	1	421848752	7	\N	\N	P
GAVIC721290639	2023-07-20	2023-11-05	\N	\N	\N	\N	\N	UNIT	\N	1907	\N	L	\N	19	\N	\N	633	\N	\N	\N	\N	VIC1990305	\N	loc9901d119afda	P	3000	\N	1907C\\PS746092	0	717492300	7	\N	455237987	S
GAVIC721284836	2023-07-20	2023-11-05	\N	\N	\N	\N	\N	UNIT	\N	6706	\N	L	\N	67	\N	\N	648	\N	\N	\N	\N	VIC1994837	\N	loc9901d119afda	P	3000	\N	6706D\\PS746092	0	717486497	7	\N	455366050	S
GAVIC721289923	2023-07-20	2023-08-06	\N	\N	\N	\N	\N	UNIT	\N	104	\N	L	\N	1	\N	\N	24	\N	\N	\N	\N	VIC1988452	\N	loce42a110faa48	P	3188	\N	7\\PS810583	0	717491584	7	\N	454791693	S
GAVIC720475626	2023-04-20	2023-05-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2	B	\N	\N	\N	VIC3619244	\N	locba5e689e47f8	P	3228	\N	2110\\PS819032	2	715860667	7	\N	432189657	\N
GAVIC721019485	2023-04-20	2024-04-18	\N	\N	\N	\N	\N	UNIT	\N	2	\N	\N	\N	\N	\N	\N	10	\N	\N	\N	\N	VIC3259081	\N	loc46443686a430	P	3020	\N	2\\PS844010	2	717220444	7	\N	453322852	S
GAVIC423935363	2025-04-15	2025-07-29	\N	COURT HOUSE	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	19	\N	\N	\N	\N	VIC1948877	\N	locff58d0167065	P	3672	\N	2017\\PP5066	1	424023915	7	\N	439537592	P
GAVIC721705028	2025-01-16	2025-01-28	\N	\N	\N	\N	\N	UNIT	\N	804	\N	L	\N	8	\N	\N	31	\N	\N	\N	\N	VIC2025962	\N	loc9901d119afda	P	3000	\N	804\\PS913307	0	717907551	7	\N	457429885	S
GAVIC721706405	2025-01-16	2025-01-28	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	625	\N	\N	\N	\N	VIC1959852	\N	loca1a84d46e52a	P	3076	\N	11\\PS914841	0	717908928	7	\N	457553748	S
GAVIC721369066	2023-10-23	2023-11-07	\N	\N	\N	\N	\N	UNIT	\N	4205	\N	L	\N	42	\N	\N	299	\N	\N	\N	\N	VIC1992749	\N	loc9901d119afda	P	3000	\N	4205\\PS827459	0	717570827	7	\N	455659235	S
GAVIC419723191	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	177	\N	\N	\N	\N	VIC2060041	\N	loc11fb0b5df130	P	3840	\N	82\\LP138947	2	419864859	7	\N	5261680	\N
GAVIC423837828	2017-10-26	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	16	\N	\N	\N	\N	\N	\N	539	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	16\\PS526704	2	423928534	7	\N	209013757	S
GAVIC419571030	2007-12-15	2021-08-05	\N	KATHEGA	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	94	\N	\N	\N	\N	VIC2006569	\N	loc0b8afd71fce1	P	3003	\N	1\\TP760553	2	419712244	7	\N	1386592	\N
GAVIC721425406	2024-01-15	2024-10-19	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	22	\N	\N	\N	\N	VIC3630043	\N	loce16236caf708	P	3212	\N	128\\PS913039	1	717627424	7	\N	456036054	\N
GAVIC423874856	2025-01-16	2025-01-28	\N	\N	\N	\N	\N	\N	\N	\N	\N	L	\N	32	\N	\N	600	\N	\N	\N	\N	VIC1944127	\N	loc9901d119afda	P	3000	\N	PC369270	1	423965487	7	\N	457829596	S
GAVIC419598648	2024-01-15	2024-01-29	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	7	\N	\N	\N	\N	VIC1935950	\N	loc098ac8eaabef	P	3028	\N	CM1\\PS914625	2	419740543	7	\N	454315126	P
GAVIC720284643	2023-07-20	2023-08-06	\N	\N	\N	\N	\N	UNIT	\N	22	\N	\N	\N	\N	\N	\N	278	\N	\N	280	\N	VIC3618044	\N	loc098e933e1fd2	P	3216	\N	8\\PS829165	2	715669684	7	\N	430900589	S
GAVIC425614233	2017-10-26	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	202	\N	\N	\N	\N	\N	\N	22	\N	\N	\N	\N	VIC1952570	\N	loc5c27e3f22fc1	P	3122	\N	11\\PS734295	2	425702523	7	\N	421528441	S
GAVIC719622334	2019-04-25	2021-07-07	\N	\N	\N	\N	\N	FLAT	\N	5	\N	\N	\N	\N	\N	\N	7	\N	\N	\N	\N	VIC2003856	\N	loccbfe7d3f7b9f	P	3185	\N	G05\\PS742542	2	715007348	7	\N	427050164	S
GAVIC720443226	2020-07-16	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	15	\N	\N	\N	\N	VIC2066462	\N	loc1a7553da1009	P	3312	\N	2\\PS818721	0	715828267	7	\N	429658888	\N
GAVIC719111600	2021-10-26	2021-11-11	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	80	\N	\N	\N	\N	VIC2050036	\N	loc86b22e8e6ecf	P	3550	\N	1\\PS807966	1	714496633	7	\N	431667102	\N
GAVIC719210454	2020-01-21	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	55	\N	\N	\N	\N	VIC3618602	\N	loc64c822b0bad5	P	3809	\N	37\\PS735758	2	714595487	7	\N	424424420	\N
GAVIC721089117	2022-10-22	2022-11-15	\N	CAMPSITE 150	\N	\N	\N	SITE	\N	150	\N	\N	\N	\N	\N	\N	15	\N	\N	\N	\N	VIC2028859	\N	loc0b665c0fe535	P	3226	\N	61\\LP1857	0	717290269	7	\N	213766925	S
GAVIC720523963	2020-10-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	42	\N	\N	\N	\N	VIC3559217	\N	loc64c822b0bad5	P	3809	\N	22\\PS836963	1	715909004	7	\N	432378053	\N
GAVIC425157653	2020-10-17	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	512	\N	\N	512	A	VIC1960955	\N	locf51f6cd689bb	P	3205	\N	CM1\\PS630408	0	425245912	7	\N	214171591	\N
GAVIC421986723	2023-10-24	2023-11-07	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	11	\N	\N	13	\N	VIC1938427	\N	loc02a3a330fe2f	P	3223	\N	CP156814	2	422117560	7	\N	212177047	S
GAVIC420787418	2024-10-18	2024-10-30	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	575	\N	\N	\N	\N	VIC1992219	\N	loce42a110faa48	P	3188	\N	1\\TP339099	2	420920688	7	\N	1597270	P
GAVIC420015455	2021-07-26	2021-08-14	\N	\N	\N	\N	\N	UNIT	\N	507	\N	\N	\N	\N	\N	\N	155	\N	\N	\N	\N	VIC1944127	\N	loc9901d119afda	P	3000	\N	507\\PS418979	1	420152356	7	\N	52499553	S
GAVIC720126989	2021-07-26	2021-08-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4	\N	\N	\N	\N	VICL3620952	\N	locabdfa0718385	P	3337	\N	191\\PS820751	2	715512010	7	\N	430162976	\N
GAVIC720919065	2023-07-20	2023-08-06	\N	\N	\N	\N	\N	UNIT	\N	3	\N	\N	\N	\N	\N	\N	10	\N	\N	\N	\N	VIC1971604	\N	loc74f8893fb76e	P	3047	\N	2C\\RP15895	2	717119544	7	\N	454569438	S
GAVIC721711659	2025-01-16	2025-10-17	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2	\N	\N	\N	\N	VICL4176453	\N	locfd8472c41cbe	P	3178	\N	7\\PS917468	1	717914182	7	\N	456006134	\N
GAVIC419811494	2024-01-15	2024-04-18	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	26	\N	\N	\N	\N	VIC1992446	\N	loc46f8f01fbac9	P	3135	\N	CM1\\PS901115	1	419947487	7	\N	452043918	P
GAVIC424684358	2023-01-14	2023-02-03	\N	\N	\N	\N	\N	UNIT	\N	1	\N	\N	\N	\N	\N	\N	53	\N	\N	\N	\N	VIC2037884	\N	locb8f595af5fb8	P	3150	\N	1\\PS835402	2	424769747	7	\N	430612232	S
GAVIC421863134	2004-11-02	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	22	\N	\N	\N	\N	VIC2078595	\N	loc1e33f92d8409	P	3995	\N	1\\TP111265	2	421992777	7	\N	5272058	\N
GAVIC421481958	2017-10-26	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	9	\N	\N	\N	\N	VIC1978845	\N	loc08caad3924ee	P	3025	\N	CM\\RP7760	1	421632471	7	\N	53007947	P
GAVIC423639265	2017-10-26	2021-08-18	\N	\N	\N	\N	\N	\N	\N	\N	\N	L	\N	15	\N	\N	530	\N	\N	\N	\N	VIC1990231	\N	loc9901d119afda	P	3000	\N	\N	0	423732738	7	\N	\N	S
GAVIC720144307	2019-07-21	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	202	\N	\N	\N	\N	\N	\N	39	\N	\N	\N	\N	VIC2028102	\N	loc67a11408d754	P	3011	\N	202\\PS815389	1	715529328	7	\N	430061711	S
GAVIC422138212	2019-04-24	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	3	\N	\N	\N	\N	\N	\N	23	\N	\N	\N	\N	VIC1970192	\N	loc82b861dfb765	P	3071	\N	3\\PS632362	1	422268958	7	\N	216518826	S
GAVIC719537604	2019-07-21	2021-08-14	\N	DALKEITH HEIGHTS	\N	\N	\N	UNIT	\N	84	\N	\N	\N	\N	\N	\N	49	\N	\N	53	\N	VIC1999814	\N	loc8e5a2b16aaaa	P	3844	\N	1\\PS836326	2	714922636	7	\N	430365108	S
GAVIC420749468	2019-10-20	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	281	\N	\N	\N	\N	VIC1977358	\N	locc81a6ec90a1b	P	3939	\N	CM1\\PS820041	1	420879105	7	\N	428440845	P
GAVIC425685032	2022-04-19	2022-05-09	\N	MOMENTUM	\N	\N	\N	FLAT	\N	101	\N	\N	\N	\N	\N	\N	99	\N	\N	\N	\N	VIC2025537	\N	locf51f6cd689bb	P	3205	\N	2101\\PS701488	2	425773322	7	\N	421400832	S
GAVIC412527335	2020-10-17	2025-10-27	\N	LEVANDE SALFORD PARK	\N	\N	\N	UNIT	\N	115	B	\N	\N	\N	\N	\N	100	\N	\N	\N	\N	VIC1995210	\N	loc4a341f4d3e02	P	3152	\N	2\\PS728985	2	412686822	7	\N	151453425	S
GAVIC719919340	2022-01-27	2022-02-09	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	16	\N	\N	\N	\N	VIC3625244	\N	loc5c7c3d320a8a	P	3677	\N	142\\PS820939	2	715304381	7	\N	430624591	\N
GAVIC720132188	2021-07-26	2021-08-14	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	42	\N	\N	\N	\N	VIC3626389	\N	loc5ba812288f5b	P	3224	\N	23\\PS816120	2	715517209	7	\N	429584329	\N
GAVIC422289520	2005-10-14	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	18	\N	\N	\N	\N	VIC1963136	\N	loc8f498b475ec6	P	3844	\N	41\\PS448339	2	422401732	7	\N	53038708	\N
GAVIC421736429	2022-10-22	2022-11-15	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	15	\N	\N	\N	\N	VIC2046842	\N	loc3319215a0a10	P	3186	\N	CM1\\PS843884	1	421883545	7	\N	432683060	P
GAVIC721704323	2025-01-16	2025-04-18	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12	\N	\N	\N	\N	VIC4172014	\N	loc556974a8bc81	P	3337	\N	26\\PS925472	1	717906846	7	\N	456988594	\N
GAVIC421300189	2004-04-29	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	358	\N	\N	360	\N	VIC2019697	\N	loc6280f9052ec0	P	3805	\N	8\\LP41754	1	421431415	7	\N	680508	\N
GAVIC422035533	2012-04-14	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1	\N	\N	\N	\N	VIC2037856	\N	loc6ae7eaa3c1f3	P	3128	\N	4\\LP11227	1	422166370	7	\N	219073487	P
GAVIC423837989	2013-01-10	2021-08-14	\N	CHARTIS BUILDING	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	549	\N	\N	551	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	35~9\\PP3084E	0	423928695	7	\N	219720230	\N
GAVIC424626663	2010-07-12	2021-07-07	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	26	\N	\N	28	\N	VIC2020912	\N	loc1b289d3ff2fc	P	3630	\N	47\\LP203266	1	424712054	7	\N	5351449	\N
GAVIC425089969	2014-04-18	2021-07-07	\N	\N	\N	\N	\N	UNIT	\N	4	\N	\N	\N	\N	\N	\N	3	\N	\N	\N	\N	VIC2022663	\N	loc82baa1179308	P	3810	\N	4\\PS708252	2	425175658	7	\N	219452145	S
GAVIC720000915	2019-01-25	2024-10-30	\N	\N	\N	\N	\N	UNIT	\N	419	\N	\N	\N	\N	\N	\N	450	\N	\N	\N	\N	VIC2030282	\N	loc9901d119afda	P	3004	\N	306\\PS738892	1	715385956	7	\N	\N	S
\.

-- raw_gnaf_202602.address_site: 451 rows
\copy raw_gnaf_202602.address_site FROM stdin
420152356	2017-10-31	\N	UR	\N
419712244	2007-12-15	\N	UR	\N
424440974	2009-04-03	\N	UR	\N
717491584	2023-07-20	\N	UR	\N
423717308	2010-01-17	\N	UR	\N
420933654	2006-08-17	\N	UN	\N
717492300	2023-07-20	\N	UR	\N
425012182	2018-11-05	\N	UN	\N
421126511	2017-10-31	\N	UR	\N
715300859	2018-10-28	\N	UR	\N
715298169	2018-10-28	\N	UR	\N
715306462	2018-10-28	\N	UR	\N
419864859	2017-10-31	\N	UR	\N
422047366	2017-10-31	\N	UR	\N
425627533	2021-01-14	\N	UR	PROVIDENCE VILLAGE
420033639	2017-10-31	\N	UR	\N
423928695	2009-04-03	\N	UR	\N
422166370	2012-04-14	\N	UR	\N
424063457	2023-04-28	\N	UN	\N
425875030	2016-01-14	\N	UR	\N
425822516	2015-10-26	\N	UR	\N
425863020	2016-01-14	\N	UR	\N
420891722	2012-01-19	\N	UR	\N
420783355	2017-10-31	\N	UR	\N
421255051	2025-04-18	\N	UN	\N
423840170	2017-10-31	\N	UR	\N
424840184	2011-04-27	\N	R	\N
421873707	2017-10-31	\N	UR	\N
425170184	2012-10-16	\N	UR	\N
425170282	2017-10-31	\N	UN	\N
425456891	2018-11-05	\N	UN	\N
420339350	2017-10-31	\N	UR	\N
420200380	2017-10-31	\N	UR	\N
419816780	2017-10-31	\N	UR	\N
420321341	2009-10-08	\N	UR	\N
420186048	2017-10-31	\N	UR	\N
422268958	2017-10-31	\N	UR	\N
411832680	2020-08-07	\N	UR	AUSTRALIAN UNITY WALMSLEY
717570827	2023-10-23	\N	UR	\N
420127405	2007-12-15	\N	UR	\N
424684659	2010-10-20	\N	UR	\N
412520578	2010-04-09	\N	UR	\N
422073533	2010-01-17	\N	UR	\N
420465478	2017-10-31	\N	UR	\N
420246858	2017-10-31	\N	UR	\N
425171577	2012-10-16	\N	UR	\N
420073732	2017-10-31	\N	UR	\N
419947487	2017-10-31	\N	UR	\N
419746060	2017-10-31	\N	UR	\N
425179311	2012-10-16	\N	R	\N
715149485	2018-05-07	\N	UR	\N
420756334	2017-10-31	\N	UR	\N
419773744	2017-10-31	\N	UR	\N
425003423	2012-01-19	\N	UR	\N
716078606	2021-04-10	\N	UN	\N
421278882	2018-11-05	\N	UN	\N
412114290	2015-07-27	\N	R	\N
421618968	2011-07-27	\N	UR	\N
419865039	2017-10-31	\N	UR	\N
714500561	2016-10-25	\N	UR	\N
425361109	2013-07-16	\N	UR	\N
425577907	2019-10-20	\N	UR	LIFESTYLE CHELSEA HEIGHTS
419761603	2017-10-31	\N	UR	\N
420984525	2009-04-03	\N	UR	\N
424862074	2018-11-05	\N	UN	\N
424718994	2010-07-12	\N	UR	\N
425363148	2013-07-16	\N	UR	\N
423741522	2013-07-16	\N	UR	\N
423883673	2013-07-16	\N	UR	\N
419886687	2008-06-27	\N	UR	\N
419704523	2017-10-31	\N	UR	\N
421476681	2017-10-31	\N	UR	\N
714824847	2017-07-26	\N	R	\N
714815529	2017-07-26	\N	UR	\N
714809494	2017-07-26	\N	UR	\N
423531516	2017-10-31	\N	UR	\N
423604983	2017-10-31	\N	UR	\N
421124709	2017-10-31	\N	UR	\N
425773322	2015-07-27	\N	UR	\N
425457708	2018-11-05	\N	UN	\N
421992777	2017-10-31	\N	UR	\N
425829932	2015-10-26	\N	UR	\N
714481851	2016-10-25	\N	UR	\N
419929442	2017-10-31	\N	UR	\N
717568260	2023-10-23	\N	UR	\N
424350726	2008-12-24	\N	UR	\N
422385892	2008-06-27	\N	UR	\N
411947810	2017-10-31	\N	UR	\N
421564892	2017-10-31	\N	UR	\N
419915681	2017-10-31	\N	UR	\N
425114129	2012-07-13	\N	UR	\N
421034752	2017-10-31	\N	UR	\N
424812537	2011-04-27	\N	UR	\N
422406512	2008-06-27	\N	UR	\N
715139892	2018-05-07	\N	UR	\N
421972789	2017-10-31	\N	UR	\N
423493799	2018-11-05	\N	UN	\N
421624178	2017-10-31	\N	UR	\N
424831860	2011-04-27	\N	UR	\N
715681078	2020-01-20	\N	UR	\N
422389231	2017-04-21	\N	UR	\N
421848752	2019-10-29	\N	UN	\N
423809282	2017-10-31	\N	UR	\N
422005646	2008-10-17	\N	UR	\N
420920688	2017-10-31	\N	UR	\N
423499498	2018-11-05	\N	UN	\N
413788284	2012-01-19	\N	UR	\N
421588755	2009-04-03	\N	UR	\N
717907551	2025-01-16	\N	UR	\N
717906857	2025-01-16	\N	UR	\N
715368361	2019-01-24	\N	UR	\N
421712789	2009-04-03	\N	UR	\N
715624039	2026-01-16	\N	UR	\N
419926535	2017-10-31	\N	UR	\N
421685051	2017-10-31	\N	UR	\N
419771930	2010-01-17	\N	UR	\N
425366225	2013-07-16	\N	UR	\N
419958905	2017-10-31	\N	UR	\N
423799056	2007-12-15	\N	UR	\N
419822291	2017-10-31	\N	R	\N
421274476	2017-10-31	\N	UR	\N
424369203	2009-04-03	\N	UR	\N
715443954	2019-04-24	\N	UR	\N
425129914	2021-07-25	\N	UR	\N
716128783	2021-07-25	\N	UR	\N
422250333	2017-10-31	\N	UR	\N
420198528	2017-10-31	\N	UR	\N
423726275	2017-10-31	\N	UR	\N
421817871	2010-01-17	\N	UR	\N
424372213	2010-10-20	\N	UR	\N
421404996	2017-10-31	\N	UR	\N
420390915	2017-10-31	\N	UR	\N
420387962	2009-04-03	\N	UR	\N
422117560	2009-04-03	\N	UR	\N
717226582	2022-07-21	\N	UR	\N
419982912	2017-10-31	\N	UR	\N
715529328	2019-07-21	\N	UR	\N
425608760	2014-10-17	\N	UR	\N
423501977	2018-11-05	\N	UN	\N
423917070	2017-10-31	\N	UR	\N
423762945	2006-01-15	\N	UN	\N
425600236	2014-10-17	\N	UR	\N
421027630	2017-10-31	\N	UR	\N
420955779	2018-11-05	\N	UN	\N
424713448	2020-08-07	\N	UR	POINT COOK VILLAGE
715903043	2020-10-17	\N	UR	\N
717908928	2025-01-16	\N	UR	\N
420046530	2009-04-03	\N	UR	\N
420182105	2017-10-31	\N	UR	\N
421944818	2017-10-31	\N	UR	\N
420195833	2017-10-31	\N	UR	\N
425910197	2016-04-22	\N	UR	\N
425399758	2013-10-22	\N	UR	\N
714805257	2017-07-26	\N	UR	\N
412861624	2017-10-31	\N	UR	\N
425773555	2021-08-18	\N	UR	\N
715385956	2019-01-25	\N	UN	\N
425319845	2013-04-17	\N	UR	\N
420437639	2017-10-31	\N	UR	\N
423566656	2010-01-17	\N	UR	\N
425795800	2023-10-31	\N	UN	\N
714629757	2023-10-31	\N	UN	\N
717290269	2022-10-22	\N	UR	WYNNDEAN HOLIDAY RESORTS
411967773	2017-10-31	\N	UR	\N
717363938	2023-01-14	\N	UR	\N
718052177	2025-10-15	\N	UR	\N
715304381	2018-10-28	\N	UR	\N
717119544	2023-07-20	\N	UR	\N
715310982	2018-10-28	\N	UR	\N
718117102	2026-01-16	\N	UR	\N
714427784	2016-07-25	\N	UN	\N
420823345	2021-01-19	\N	UN	\N
424817497	2023-10-23	\N	UN	\N
420803245	2007-12-15	\N	UR	\N
420775290	2010-07-12	\N	R	\N
422222039	2025-10-15	\N	UR	\N
421932764	2012-04-14	\N	UR	\N
420723393	2012-04-14	\N	UR	\N
420725420	2012-04-14	\N	UR	\N
425618909	2017-07-26	\N	R	\N
425702523	2015-04-10	\N	UR	\N
425397743	2013-10-22	\N	UR	\N
421278486	2017-10-31	\N	UR	\N
420246079	2017-10-31	\N	UR	\N
424439560	2009-04-03	\N	UR	\N
717906846	2025-01-16	\N	UR	\N
717113574	2022-01-25	\N	UR	KIA ORA - LORNE FORESHORE CARAVAN PARK
425908900	2016-04-22	\N	UR	\N
717914182	2025-01-16	\N	UR	\N
423376896	2005-04-15	\N	UN	\N
420044405	2016-07-22	\N	UR	\N
421563343	2008-04-06	\N	UR	\N
714376171	2016-07-22	\N	UR	\N
423841412	2013-07-16	\N	UR	\N
424880807	2013-07-16	\N	UR	\N
412843484	2018-11-05	\N	UN	\N
425402896	2013-10-22	\N	UR	\N
420768801	2017-10-31	\N	UR	\N
423328381	2017-10-31	\N	UR	\N
424850737	2011-04-27	\N	UR	\N
715909004	2020-10-17	\N	UR	\N
424032234	2017-10-31	\N	UR	\N
423505331	2018-11-05	\N	UN	\N
420359646	2017-10-31	\N	UR	\N
421826182	2017-10-31	\N	UR	\N
421377558	2017-10-31	\N	UR	\N
715512010	2019-07-21	\N	UR	\N
424863192	2019-08-07	\N	UR	BELGRAVE SOUTH RECREATION PRECINCT
425791730	2019-10-20	\N	UR	LIFESTYLE CHELSEA HEIGHTS
424836305	2011-04-27	\N	UR	\N
424991927	2012-01-19	\N	UR	\N
423485745	2018-11-05	\N	UN	\N
420676040	2008-06-27	\N	UR	\N
717576437	2023-10-23	\N	UR	\N
421346876	2017-10-31	\N	UR	\N
714912319	2017-10-17	\N	UR	\N
423880954	2013-07-16	\N	UR	\N
419776057	2017-10-31	\N	UR	\N
425245912	2013-01-10	\N	UR	\N
411585778	2012-10-17	\N	UN	\N
425258034	2013-01-10	\N	UR	\N
423742341	2010-01-17	\N	UR	\N
424079728	2018-11-05	\N	UN	\N
714824238	2017-07-26	\N	UR	\N
714824244	2017-07-26	\N	UR	\N
421050712	2017-10-31	\N	UR	\N
419934459	2009-07-21	\N	UR	\N
420587553	2017-10-31	\N	UR	\N
423737032	2008-12-24	\N	UR	\N
425830752	2015-10-26	\N	UR	\N
425710626	2015-04-10	\N	UR	\N
424965089	2011-11-01	\N	UR	\N
424963115	2011-11-01	\N	UR	\N
421802511	2017-10-31	\N	UR	\N
420834992	2017-10-31	\N	UR	\N
412830940	2018-11-05	\N	UN	\N
717706362	2024-04-17	\N	UN	\N
714909570	2017-10-17	\N	UR	\N
425169627	2012-10-16	\N	UR	\N
717681413	2024-04-16	\N	UR	\N
422165669	2017-10-31	\N	R	\N
419854489	2017-10-31	\N	UR	\N
421821487	2017-10-31	\N	UR	\N
715372561	2019-01-24	\N	UR	\N
424722869	2018-05-07	\N	UR	CHADSTONE SHOPPING CENTRE
715139112	2018-05-07	\N	UR	\N
715370083	2019-01-24	\N	UR	\N
424617681	2010-01-17	\N	UR	\N
419828675	2012-04-14	\N	UR	\N
424870928	2011-07-27	\N	UR	\N
420562978	2017-10-31	\N	UR	\N
421175767	2017-10-31	\N	UR	\N
421019197	2017-10-31	\N	UR	\N
425413267	2018-11-05	\N	UN	\N
420631407	2017-10-31	\N	UN	\N
715860667	2020-10-17	\N	UR	\N
424001698	2020-07-22	\N	UN	\N
412686819	2020-10-17	\N	UR	SALFORD PARK RETIREMENT VILLAGE
423311651	2017-10-31	\N	UR	\N
425821086	2021-08-18	\N	UR	\N
422113967	2017-10-31	\N	UR	\N
715437863	2019-04-24	\N	UR	\N
715905941	2020-10-17	\N	UR	\N
420226560	2017-10-31	\N	UR	\N
718119404	2026-01-16	\N	UR	\N
424001182	2017-10-31	\N	UR	\N
423492428	2018-11-05	\N	UN	\N
420546063	2017-10-31	\N	UR	\N
425099296	2012-07-13	\N	UR	\N
420788115	2017-10-31	\N	UR	\N
716131219	2021-07-25	\N	UR	\N
420691543	2017-10-31	\N	UR	\N
423713875	2017-10-31	\N	UR	\N
423928534	2017-10-31	\N	UR	\N
421561145	2017-10-31	\N	UR	\N
421907605	2017-10-31	\N	UR	\N
717486497	2023-07-20	\N	UR	\N
717239943	2022-07-21	\N	UR	PORTARLINGTON HOILDAY PARK
425455908	2014-01-21	\N	UN	\N
714924203	2022-07-21	\N	UR	INGENIA LIFESTYLE LARA
421124750	2008-06-27	\N	UR	\N
423489698	2018-11-05	\N	UN	\N
421389843	2011-11-01	\N	UR	\N
425702034	2015-04-10	\N	UR	\N
420256879	2010-01-17	\N	UR	\N
423193444	2017-10-31	\N	R	\N
424350293	2008-12-24	\N	UR	\N
423222907	2020-05-08	\N	UR	AVEO BOTANIC GARDENS RETIREMENT VILLAGE
715859924	2020-07-28	\N	UN	\N
420012023	2017-10-31	\N	UR	\N
425363708	2013-07-16	\N	UR	\N
423497210	2018-11-05	\N	UN	\N
423539011	2017-10-31	\N	UR	\N
420271959	2017-10-31	\N	UR	\N
420180173	2017-10-31	\N	UR	\N
715517209	2019-07-21	\N	UR	\N
420879105	2017-10-31	\N	UR	\N
714798142	2017-07-26	\N	UR	\N
422292427	2017-10-31	\N	UR	\N
419986896	2017-10-31	\N	UR	\N
423496493	2018-11-05	\N	UN	\N
412080871	2018-11-05	\N	UN	\N
424510130	2023-10-31	\N	UN	\N
421090069	2017-10-31	\N	UR	\N
421883545	2017-10-31	\N	UR	\N
421749284	2017-10-31	\N	UR	\N
420967986	2017-10-31	\N	UR	\N
718117953	2026-01-16	\N	UR	\N
718119838	2026-01-16	\N	UR	\N
422003187	2017-10-31	\N	UR	\N
413526344	2008-12-24	\N	UR	\N
419795153	2008-06-27	\N	UR	\N
420314530	2017-10-31	\N	UR	\N
423497478	2018-11-05	\N	UN	\N
424351848	2017-10-31	\N	R	\N
423981390	2008-10-17	\N	UR	\N
420778434	2012-01-19	\N	UR	\N
412834080	2018-11-05	\N	UN	\N
420525075	2017-10-31	\N	UR	\N
424122311	2007-12-15	\N	UR	\N
714598977	2017-01-20	\N	UR	\N
421901952	2017-10-31	\N	UR	\N
424752485	2010-10-20	\N	UR	\N
717627424	2024-01-15	\N	UR	\N
412839624	2018-11-05	\N	UN	\N
420758704	2017-10-31	\N	UR	\N
423732738	2023-10-31	\N	UN	\N
421880072	2017-10-31	\N	UR	\N
411236384	2017-10-31	\N	UR	\N
717751011	2024-07-14	\N	UR	\N
421436117	2017-10-31	\N	UR	\N
718002861	2025-07-15	\N	UR	\N
420671470	2017-10-31	\N	UR	\N
420658313	2017-10-31	\N	UR	\N
716084829	2023-10-31	\N	UN	\N
714373238	2016-07-22	\N	UR	\N
420498308	2008-06-27	\N	UR	\N
420332142	2016-07-22	\N	UR	\N
421861654	2017-10-31	\N	UR	\N
717220444	2022-07-21	\N	UR	\N
419810399	2014-10-17	\N	UR	\N
420868495	2017-10-31	\N	UR	\N
424576649	2009-10-08	\N	UR	\N
425574511	2018-11-05	\N	UN	\N
425549522	2014-07-17	\N	UR	\N
420281832	2017-10-31	\N	UR	\N
412833862	2018-11-05	\N	UN	\N
411960119	2011-04-27	\N	UR	\N
420910016	2017-10-31	\N	UR	\N
424564343	2011-04-27	\N	UR	\N
715669684	2020-01-20	\N	UR	\N
421632471	2017-10-31	\N	UR	\N
425818341	2015-10-26	\N	UR	\N
424769747	2011-01-29	\N	UR	\N
714496633	2016-10-25	\N	UR	\N
419740543	2024-01-15	\N	UR	\N
421236655	2017-10-31	\N	UR	\N
424636988	2018-11-05	\N	UN	\N
421442494	2017-10-31	\N	UR	\N
419788726	2008-10-17	\N	UR	\N
420867943	2017-10-31	\N	UR	\N
424359526	2009-04-03	\N	UR	\N
425373580	2013-07-16	\N	UR	\N
425255917	2013-01-10	\N	UR	\N
424370186	2023-10-31	\N	UN	\N
421985493	2017-10-31	\N	UR	\N
424001086	2017-10-31	\N	UR	\N
420356298	2017-10-31	\N	UR	\N
715373884	2019-01-24	\N	UR	\N
424006537	2011-01-29	\N	UR	\N
714694055	2017-04-21	\N	UR	\N
421431415	2017-10-31	\N	UR	\N
419749804	2017-10-31	\N	UR	\N
421430383	2017-10-31	\N	UR	\N
420632037	2010-07-12	\N	UR	\N
422154843	2016-04-22	\N	UR	\N
420241455	2010-07-12	\N	UR	\N
422521967	2008-06-27	\N	UR	\N
423498087	2018-11-05	\N	UN	\N
714908594	2017-10-17	\N	UR	\N
420053915	2017-10-31	\N	UR	\N
411814562	2017-10-31	\N	UR	\N
425455777	2014-10-17	\N	UR	\N
424674919	2010-04-09	\N	UR	\N
425175658	2012-10-16	\N	UR	\N
422126020	2017-10-31	\N	UR	\N
715843419	2020-07-16	\N	UR	\N
421177464	2017-10-31	\N	UR	\N
420894156	2017-10-31	\N	UR	\N
715364337	2019-01-24	\N	UR	\N
421546605	2017-10-31	\N	UR	\N
421079146	2017-10-31	\N	UR	\N
714993447	2018-01-19	\N	UR	\N
715130385	2018-05-07	\N	UR	\N
425117567	2012-07-13	\N	UR	\N
714395624	2016-07-22	\N	UR	\N
715928975	2020-10-18	\N	UN	\N
717679200	2024-04-16	\N	UR	\N
424333656	2008-10-17	\N	UR	\N
421013154	2008-06-27	\N	UR	\N
412686822	2020-10-17	\N	UR	SALFORD PARK RETIREMENT VILLAGE
715298489	2018-10-28	\N	UR	\N
422008521	2017-10-31	\N	UR	\N
419752865	2017-10-31	\N	UR	\N
422401732	2007-12-15	\N	UR	\N
423965487	2010-04-09	\N	UR	\N
425002879	2012-01-19	\N	UR	\N
715897322	2020-10-17	\N	UR	\N
421436852	2017-10-31	\N	UR	\N
424980860	2018-11-05	\N	UN	\N
425094218	2012-07-13	\N	UR	\N
421192512	2017-10-31	\N	UR	\N
412875612	2009-07-21	\N	UR	\N
424666593	2010-04-09	\N	UR	\N
420842711	2017-10-31	\N	UR	\N
423495070	2018-11-05	\N	UN	\N
411999327	2009-07-21	\N	UR	\N
425362339	2013-07-16	\N	UR	\N
715007348	2018-01-19	\N	UR	\N
714992137	2018-01-19	\N	UR	\N
423585040	2017-10-31	\N	UR	\N
421859624	2021-07-25	\N	UR	CUMBERLAND VIEW RETIREMENT VILLAGE
424762274	2010-10-20	\N	UR	\N
714913664	2017-10-17	\N	UR	\N
422054200	2017-10-31	\N	UR	\N
423585372	2017-10-31	\N	UR	\N
425360767	2013-07-16	\N	UR	\N
425568954	2015-01-19	\N	UR	\N
424023915	2022-04-19	\N	UR	\N
420039411	2017-10-31	\N	UR	\N
420840829	2017-10-31	\N	UR	\N
412233908	2010-07-12	\N	UR	\N
420234237	2017-10-31	\N	UR	\N
421844576	2011-07-27	\N	UR	\N
424712054	2010-07-12	\N	UR	\N
419838142	2015-04-10	\N	UR	\N
424761278	2010-10-20	\N	UR	\N
423497886	2018-11-05	\N	UN	\N
421605628	2008-06-27	\N	UR	\N
425573227	2014-10-17	\N	UR	\N
714592328	2017-01-20	\N	UR	\N
714595487	2017-01-20	\N	UR	\N
425600398	2014-10-17	\N	UR	\N
715828267	2020-07-16	\N	UR	\N
414965183	2009-10-08	\N	UR	\N
412379387	2009-04-03	\N	UR	\N
714922636	2019-07-21	\N	UR	DALKEITH HEIGHTS RETIREMENT VILLAGE
412671558	2017-10-31	\N	UR	\N
412827101	2018-11-05	\N	UN	\N
422217313	2012-01-19	\N	UR	\N
424881609	2023-10-31	\N	UN	\N
\.

-- raw_gnaf_202602.address_site_geocode: 828 rows
\copy raw_gnaf_202602.address_site_geocode FROM stdin
FCS421817871	2016-08-02	\N	421817871	\N	\N	FCS	2	\N	\N	\N	144.96795863	-37.81305954
4122768	2012-11-01	\N	421546605	\N	\N	FCS	2	\N	\N	\N	145.24739088	-37.90586486
2153991	2012-11-01	\N	421985493	\N	\N	FCS	2	\N	\N	\N	145.05494793	-37.74198384
424684659	2021-04-13	\N	424684659	\N	\N	FCS	2	\N	\N	\N	144.41881532	-37.67368602
FCS717906857	2025-01-16	\N	717906857	\N	\N	FCS	2	\N	\N	\N	144.96725679	-37.83654004
3334665	2012-11-01	\N	420546063	\N	\N	FCS	2	\N	\N	\N	145.05646293	-37.71338684
1746755	2012-11-01	\N	420246079	\N	\N	FCS	2	\N	\N	\N	145.12195891	-37.84329385
2565196	2012-11-01	\N	421972789	\N	\N	FCS	2	\N	\N	\N	144.99292794	-37.74126784
FCS714908594	2023-04-27	\N	714908594	\N	\N	FCS	2	\N	\N	\N	144.96073354	-37.80833027
2846952	2012-11-01	\N	420339350	\N	\N	FCS	2	\N	\N	\N	144.63738498	-37.90765382
2149428	2012-11-01	\N	421821487	\N	\N	FCS	2	\N	\N	\N	145.04291892	-37.82659684
FCS425875030	2023-10-30	\N	425875030	\N	\N	FCS	2	\N	\N	\N	144.98717136	-37.80579441
2580925	2024-01-17	\N	419947487	\N	\N	FCS	2	\N	\N	\N	145.25936400	-37.82476095
FCS717363938	2023-01-14	\N	717363938	\N	\N	FCS	2	\N	\N	\N	145.23153380	-37.91936213
FCS718119838	2026-01-16	\N	718119838	\N	\N	FCS	2	\N	\N	\N	144.95946292	-37.82615118
2329157	2012-11-01	\N	421873707	\N	\N	FCS	2	\N	\N	\N	144.92547596	-37.65794683
2754763	2012-11-01	\N	420390915	\N	\N	FCS	2	\N	\N	\N	145.03281694	-37.68269584
FCS422154843	2016-04-27	\N	422154843	\N	\N	FCS	2	\N	\N	\N	145.03415549	-37.85515594
3326126	2012-11-01	\N	419776057	\N	\N	FCS	2	\N	\N	\N	145.06666090	-37.95367685
FCS424370186	2013-10-30	\N	424370186	\N	\N	FCS	2	\N	\N	\N	145.03850284	-37.95885229
FCS425361109	2014-10-25	\N	425361109	\N	\N	FCS	2	\N	\N	\N	145.14830823	-37.71905657
3576861	2024-04-18	\N	422008521	\N	\N	FCS	2	\N	\N	\N	147.59748794	-37.82359215
FCS420933654	2021-08-03	\N	420933654	\N	\N	FCS	2	\N	\N	\N	145.18141778	-37.95878525
FCS419929442	2021-08-03	\N	419929442	\N	\N	FCS	2	\N	\N	\N	145.23626340	-38.19602626
424006537	2019-08-07	\N	424006537	\N	\N	PAPS	2	\N	\N	\N	144.93953230	-37.84128419
FCS425360767	2013-07-16	\N	425360767	\N	\N	FCS	2	\N	\N	\N	144.99807193	-37.61384918
4397937	2020-08-07	\N	411832680	\N	\N	PAPS	2	\N	\N	\N	145.30974852	-37.80704431
1874136	2012-11-01	\N	420834992	\N	\N	FCS	2	\N	\N	\N	144.96913994	-37.75350484
420632037	2012-11-01	\N	420632037	\N	\N	FCS	2	\N	\N	\N	145.03433532	-37.82695143
422401732	2023-10-24	\N	422401732	\N	\N	FCS	2	\N	\N	\N	146.56532248	-38.19945322
PAPS412114290	2017-08-12	\N	412114290	\N	\N	PAPS	2	\N	\N	\N	145.15540573	-36.78140824
FCS715373884	2019-01-24	\N	715373884	\N	\N	FCS	2	\N	\N	\N	144.95670034	-37.82766595
423840170	2012-11-01	\N	423840170	\N	\N	FCS	2	\N	\N	\N	144.73451975	-37.71861448
3066999	2012-11-01	\N	411814562	\N	\N	FCS	2	\N	\N	\N	145.02782593	-37.80287784
PAPS425618909	2017-08-12	\N	425618909	\N	\N	PAPS	2	\N	\N	\N	143.49085693	-35.30658547
3479783	2012-11-01	\N	419752865	\N	\N	FCS	2	\N	\N	\N	145.02125194	-37.70012084
423809282	2012-11-01	\N	423809282	\N	\N	FCS	2	\N	\N	\N	143.85708571	-37.55606340
PC422126020	2017-08-08	\N	422126020	\N	\N	PC	2	\N	\N	\N	144.74133430	-37.72361322
PC420910016	2017-08-08	\N	420910016	\N	\N	PC	2	\N	\N	\N	144.76398194	-37.73564701
FCS715385956	2019-01-31	\N	715385956	\N	\N	FCS	2	\N	\N	\N	144.97599334	-37.83867611
PC421561145	2017-08-08	\N	421561145	\N	\N	PC	2	\N	\N	\N	145.14906168	-37.97047404
PC425363148	2017-08-08	\N	425363148	\N	\N	PC	2	\N	\N	\N	144.96939817	-37.82955243
PC717576437	2023-11-07	\N	717576437	\N	\N	PC	2	\N	\N	\N	145.04080559	-37.83828759
PC422008521	2017-08-08	\N	422008521	\N	\N	PC	2	\N	\N	\N	147.59746485	-37.82368512
PC425702034	2017-08-08	\N	425702034	\N	\N	PC	2	\N	\N	\N	145.30070012	-38.11934862
PC715828267	2020-08-05	\N	715828267	\N	\N	PC	2	\N	\N	\N	141.40791300	-37.31808953
PC421126511	2017-08-08	\N	421126511	\N	\N	PC	2	\N	\N	\N	145.17618351	-37.92775613
PC425791730	2023-11-07	\N	425791730	\N	\N	PC	2	\N	\N	\N	145.13471436	-38.03116254
PC425258034	2017-08-08	\N	425258034	\N	\N	PC	2	\N	\N	\N	144.58427276	-37.49015355
PC425170184	2018-05-11	\N	425170184	\N	\N	PC	2	\N	\N	\N	144.99686417	-37.78305107
PC423717308	2017-08-08	\N	423717308	\N	\N	PC	2	\N	\N	\N	144.94628516	-37.79680030
PC424023915	2025-07-31	\N	424023915	\N	\N	PC	2	\N	\N	\N	145.97512729	-36.55573851
PC422154843	2017-08-08	\N	422154843	\N	\N	PC	2	\N	\N	\N	145.03415066	-37.85515397
PC715681078	2020-02-01	\N	715681078	\N	\N	PC	2	\N	\N	\N	145.12564215	-38.04212958
PC424713448	2018-05-11	\N	424713448	\N	\N	PC	2	\N	\N	\N	144.75305373	-37.89901611
PC424564343	2017-08-08	\N	424564343	\N	\N	PC	2	\N	\N	\N	144.99650130	-37.83908967
PC425362339	2017-08-08	\N	425362339	\N	\N	PC	2	\N	\N	\N	144.96000946	-37.82649727
PC421873707	2017-08-08	\N	421873707	\N	\N	PC	2	\N	\N	\N	144.92561092	-37.65797795
PC425363708	2017-08-08	\N	425363708	\N	\N	PC	2	\N	\N	\N	145.04073634	-37.87474539
PC422521967	2017-08-08	\N	422521967	\N	\N	PC	2	\N	\N	\N	146.85932821	-36.11670493
PC420967986	2017-08-08	\N	420967986	\N	\N	PC	2	\N	\N	\N	144.91658521	-37.72177795
PC715370083	2019-05-06	\N	715370083	\N	\N	PC	2	\N	\N	\N	144.96194659	-37.80613287
PC412379387	2018-05-11	\N	412379387	\N	\N	PC	2	\N	\N	\N	145.24102930	-37.93761415
PC419865039	2017-08-08	\N	419865039	\N	\N	PC	2	\N	\N	\N	144.88939746	-37.79527476
PC717908928	2025-01-27	\N	717908928	\N	\N	PC	2	\N	\N	\N	145.00483790	-37.63683527
PC714809494	2023-11-07	\N	714809494	\N	\N	PC	2	\N	\N	\N	144.97387824	-37.83587746
PC421274476	2017-08-08	\N	421274476	\N	\N	PC	2	\N	\N	\N	144.55747531	-38.16269812
PC715300859	2018-11-05	\N	715300859	\N	\N	PC	2	\N	\N	\N	144.96062994	-37.80782400
PC715897322	2023-11-07	\N	715897322	\N	\N	PC	2	\N	\N	\N	144.95248392	-37.81423051
PC412233908	2017-08-08	\N	412233908	\N	\N	PC	2	\N	\N	\N	144.92642148	-37.73040772
PC419761603	2018-05-11	\N	419761603	\N	\N	PC	2	\N	\N	\N	145.03824640	-37.93518796
PC424881609	2018-05-11	\N	424881609	\N	\N	PC	2	\N	\N	\N	144.95928640	-37.81712784
PC423809282	2023-11-07	\N	423809282	\N	\N	PC	2	\N	\N	\N	143.85709216	-37.55602082
PC419810399	2018-05-11	\N	419810399	\N	\N	PC	2	\N	\N	\N	145.12822217	-37.91160013
PC715139892	2018-05-11	\N	715139892	\N	\N	PC	2	\N	\N	\N	145.08094128	-37.95347459
PC412861624	2017-08-08	\N	412861624	\N	\N	PC	2	\N	\N	\N	144.95534236	-37.82069811
PC715385956	2019-02-04	\N	715385956	\N	\N	PC	2	\N	\N	\N	144.97566530	-37.83875126
PC420180173	2023-11-07	\N	420180173	\N	\N	PC	2	\N	\N	\N	144.92754184	-37.69133802
PC714376171	2023-11-07	\N	714376171	\N	\N	PC	2	\N	\N	\N	144.96198155	-37.80564757
PC715443954	2019-05-06	\N	715443954	\N	\N	PC	2	\N	\N	\N	145.00225793	-37.74643355
PC715149485	2023-11-07	\N	715149485	\N	\N	PC	2	\N	\N	\N	144.93829864	-37.81544355
PC421618968	2018-05-11	\N	421618968	\N	\N	PC	2	\N	\N	\N	145.05705567	-37.76974524
PC421431415	2017-08-08	\N	421431415	\N	\N	PC	2	\N	\N	\N	145.29148465	-38.03888084
PC411585778	2017-08-11	\N	411585778	\N	\N	PC	2	\N	\N	\N	145.04051310	-37.86007472
PC715298489	2020-05-05	\N	715298489	\N	\N	PC	2	\N	\N	\N	144.97566530	-37.83875126
PC420788115	2018-05-11	\N	420788115	\N	\N	PC	2	\N	\N	\N	145.11534828	-37.80971520
PC423566656	2017-08-08	\N	423566656	\N	\N	PC	2	\N	\N	\N	144.97315601	-37.76496628
PC421859624	2021-08-14	\N	421859624	\N	\N	PC	2	\N	\N	\N	145.19499805	-37.92150264
PC424440974	2017-08-08	\N	424440974	\N	\N	PC	2	\N	\N	\N	144.76426288	-37.77771142
PC714992137	2018-01-30	\N	714992137	\N	\N	PC	2	\N	\N	\N	144.96134036	-37.80932404
PC714798142	2018-01-30	\N	714798142	\N	\N	PC	2	\N	\N	\N	143.83744109	-37.58334028
PC420053915	2017-08-08	\N	420053915	\N	\N	PC	2	\N	\N	\N	144.92471667	-37.64973703
PC423328381	2017-08-08	\N	423328381	\N	\N	PC	2	\N	\N	\N	144.97659471	-37.84408254
PC714427784	2018-05-11	\N	714427784	\N	\N	PC	2	\N	\N	\N	144.96845202	-37.80912660
PC425399758	2017-08-08	\N	425399758	\N	\N	PC	2	\N	\N	\N	144.97375770	-37.41798767
PC715512010	2019-08-05	\N	715512010	\N	\N	PC	2	\N	\N	\N	144.58249890	-37.65565182
PC421278486	2018-05-11	\N	421278486	\N	\N	PC	2	\N	\N	\N	144.87890939	-37.69409519
PC422047366	2018-05-11	\N	422047366	\N	\N	PC	2	\N	\N	\N	145.09539575	-37.76863781
PC420437639	2017-08-08	\N	420437639	\N	\N	PC	2	\N	\N	\N	145.04535756	-37.82971416
PC717226582	2022-08-08	\N	717226582	\N	\N	PC	2	\N	\N	\N	144.71368949	-37.69387977
PC714395624	2018-05-11	\N	714395624	\N	\N	PC	2	\N	\N	\N	144.95518335	-37.80066403
PC411967773	2017-08-08	\N	411967773	\N	\N	PC	2	\N	\N	\N	144.97447222	-37.83559668
PC716084829	2021-04-27	\N	716084829	\N	\N	PC	2	\N	\N	\N	145.56883227	-38.08407286
PC422003187	2017-08-08	\N	422003187	\N	\N	PC	2	\N	\N	\N	144.94566423	-37.76393089
PC714592328	2017-08-08	\N	714592328	\N	\N	PC	2	\N	\N	\N	144.94432896	-37.82966676
PC717568260	2023-11-07	\N	717568260	\N	\N	PC	2	\N	\N	\N	145.11685361	-37.81775394
PC425829932	2017-08-08	\N	425829932	\N	\N	PC	2	\N	\N	\N	144.95408773	-37.81544617
PC425114129	2017-08-08	\N	425114129	\N	\N	PC	2	\N	\N	\N	144.97659020	-37.84129614
PC422165669	2018-05-11	\N	422165669	\N	\N	PC	2	\N	\N	\N	147.15704748	-36.74702693
PC714924203	2017-10-24	\N	714924203	\N	\N	PC	2	\N	\N	\N	144.42671964	-38.02926339
PC718052177	2025-10-29	\N	718052177	\N	\N	PC	2	\N	\N	\N	144.94606241	-37.81328140
PC424372213	2017-08-08	\N	424372213	\N	\N	PC	2	\N	\N	\N	144.93701585	-37.75993919
PC419795153	2017-08-08	\N	419795153	\N	\N	PC	2	\N	\N	\N	144.27941668	-36.74543794
PC425169627	2017-08-08	\N	425169627	\N	\N	PC	2	\N	\N	\N	144.91616131	-37.72202963
PC716128783	2023-11-07	\N	716128783	\N	\N	PC	2	\N	\N	\N	143.79005185	-37.57344701
PC714815529	2018-01-30	\N	714815529	\N	\N	PC	2	\N	\N	\N	144.90812212	-37.86459277
PC421632471	2017-08-08	\N	421632471	\N	\N	PC	2	\N	\N	\N	144.83569899	-37.83087064
PC421588755	2017-08-08	\N	421588755	\N	\N	PC	2	\N	\N	\N	144.54446866	-38.26943694
PC425402896	2017-08-08	\N	425402896	\N	\N	PC	2	\N	\N	\N	145.14969271	-37.77288351
PC411947810	2017-08-08	\N	411947810	\N	\N	PC	2	\N	\N	\N	144.97950646	-37.84929335
424617681	2012-11-01	\N	424617681	\N	\N	FCS	2	\N	\N	\N	144.40048822	-38.03352096
FCS715828267	2020-07-16	\N	715828267	\N	\N	FCS	2	\N	\N	\N	141.40787780	-37.32063544
424718994	2012-11-01	\N	424718994	\N	\N	FCS	2	\N	\N	\N	145.23009869	-37.80532324
FCS714913664	2017-10-17	\N	714913664	\N	\N	FCS	2	\N	\N	\N	144.90398265	-37.54162868
414965183	2012-11-01	\N	414965183	\N	\N	FCS	2	\N	\N	\N	144.77300509	-38.37210524
424963115	2024-07-24	\N	424963115	\N	\N	FCS	2	\N	\N	\N	144.91614705	-37.78236924
424122311	2012-11-01	\N	424122311	\N	\N	FCS	2	\N	\N	\N	145.27359847	-38.01934566
PC424880807	2017-08-08	\N	424880807	\N	\N	PC	2	\N	\N	\N	144.99743240	-37.83673075
PC414965183	2018-05-11	\N	414965183	\N	\N	PC	2	\N	\N	\N	144.77309797	-38.37217955
PC413788284	2018-05-11	\N	413788284	\N	\N	PC	2	\N	\N	\N	145.26457531	-37.84343251
PC420671470	2018-05-11	\N	420671470	\N	\N	PC	2	\N	\N	\N	145.13179344	-37.77539515
PC425600236	2017-08-08	\N	425600236	\N	\N	PC	2	\N	\N	\N	144.37425053	-38.16734728
PC425366225	2018-05-11	\N	425366225	\N	\N	PC	2	\N	\N	\N	144.95695175	-37.82681693
PC424666593	2017-08-08	\N	424666593	\N	\N	PC	2	\N	\N	\N	145.27715064	-37.88333358
PC423376896	2023-11-07	\N	423376896	\N	\N	PC	2	\N	\N	\N	144.96737305	-37.80891332
1637488	2012-11-01	\N	420271959	\N	\N	FCS	2	\N	\N	\N	144.91010495	-37.77861483
3465560	2012-11-01	\N	419816780	\N	\N	FCS	2	\N	\N	\N	145.08300690	-38.00120185
3839488	2012-11-01	\N	421430383	\N	\N	FCS	2	\N	\N	\N	145.10725291	-37.85929785
424812537	2012-11-01	\N	424812537	\N	\N	FCS	2	\N	\N	\N	144.76479556	-37.90634255
PC419816780	2018-05-11	\N	419816780	\N	\N	PC	2	\N	\N	\N	145.08275564	-38.00126556
PC420840829	2017-08-08	\N	420840829	\N	\N	PC	2	\N	\N	\N	144.93421738	-37.63295453
PC425002879	2017-08-08	\N	425002879	\N	\N	PC	2	\N	\N	\N	144.95354839	-37.48078214
PC420920688	2017-08-08	\N	420920688	\N	\N	PC	2	\N	\N	\N	145.00350737	-37.93028534
FCS423376896	2015-02-04	\N	423376896	\N	\N	FCS	2	\N	\N	\N	144.96730862	-37.80879726
419886687	2012-11-01	\N	419886687	\N	\N	FCS	2	\N	\N	\N	145.05301034	-36.31143352
FCS717681413	2024-10-19	\N	717681413	\N	\N	PAPS	2	\N	\N	\N	145.08578837	-37.64786543
3697793	2024-01-17	\N	420186048	\N	\N	FCS	2	\N	\N	\N	145.78890327	-38.67927285
FCS715130385	2018-05-07	\N	715130385	\N	\N	FCS	2	\N	\N	\N	144.98435522	-37.70188264
FCS715529328	2019-07-21	\N	715529328	\N	\N	FCS	2	\N	\N	\N	144.90259812	-37.79888118
PC424831860	2017-08-08	\N	424831860	\N	\N	PC	2	\N	\N	\N	144.95795905	-37.81763705
PC424963115	2017-08-08	\N	424963115	\N	\N	PC	2	\N	\N	\N	144.91512328	-37.78225813
PC420783355	2017-08-08	\N	420783355	\N	\N	PC	2	\N	\N	\N	145.27647172	-38.07972707
424350726	2012-11-01	\N	424350726	\N	\N	FCS	2	\N	\N	\N	145.02790178	-37.71415954
3866471	2015-02-04	\N	420465478	\N	\N	FCS	2	\N	\N	\N	145.05291414	-37.85679108
FCS425791730	2023-04-23	\N	425791730	\N	\N	FCS	2	\N	\N	\N	145.13471236	-38.03119682
412686822	2020-10-20	\N	412686822	\N	\N	PAPS	2	\N	\N	\N	145.22722126	-37.85362056
3064702	2015-02-04	\N	421624178	\N	\N	FCS	2	\N	\N	\N	145.00928409	-37.89690153
FCS714922636	2019-07-23	\N	714922636	\N	\N	FCS	2	\N	\N	\N	146.52229436	-38.20900349
2249814	2016-07-27	\N	420044405	\N	\N	FCS	2	\N	\N	\N	144.77224395	-37.86065106
PC715298169	2018-11-05	\N	715298169	\N	\N	PC	2	\N	\N	\N	145.04485332	-37.73926507
PC419773744	2018-05-11	\N	419773744	\N	\N	PC	2	\N	\N	\N	145.06381254	-37.89693683
PC419864859	2017-08-08	\N	419864859	\N	\N	PC	2	\N	\N	\N	146.42868762	-38.21985408
PC421901952	2020-08-05	\N	421901952	\N	\N	PC	2	\N	\N	\N	142.05972271	-34.16690896
PC424001182	2017-08-08	\N	424001182	\N	\N	PC	2	\N	\N	\N	144.97057427	-37.83175520
PC420200380	2017-08-08	\N	420200380	\N	\N	PC	2	\N	\N	\N	145.13200971	-38.13115808
FCS424510130	2015-02-04	\N	424510130	\N	\N	FCS	2	\N	\N	\N	145.04748732	-37.87604151
FCS715903043	2023-07-26	\N	715903043	\N	\N	FCS	2	\N	\N	\N	144.95351739	-37.82127148
FCS715368361	2019-01-24	\N	715368361	\N	\N	FCS	2	\N	\N	\N	144.94365758	-37.79846579
PC421992777	2018-05-11	\N	421992777	\N	\N	PC	2	\N	\N	\N	145.59843139	-38.59346244
PC715517209	2019-08-05	\N	715517209	\N	\N	PC	2	\N	\N	\N	144.46242208	-38.20244264
PC421436852	2023-11-07	\N	421436852	\N	\N	PC	2	\N	\N	\N	145.04521677	-37.85391583
PC425573227	2017-08-08	\N	425573227	\N	\N	PC	2	\N	\N	\N	145.09234097	-37.78626362
PC411832680	2017-08-08	\N	411832680	\N	\N	PC	2	\N	\N	\N	145.30975483	-37.80705725
FCS718117953	2026-01-16	\N	718117953	\N	\N	FCS	2	\N	\N	\N	144.00019719	-38.23372644
423965487	2023-04-27	\N	423965487	\N	\N	FCS	2	\N	\N	\N	144.95632191	-37.81598779
PC424991927	2017-08-08	\N	424991927	\N	\N	PC	2	\N	\N	\N	145.06508618	-37.98088470
PC425455777	2017-08-08	\N	425455777	\N	\N	PC	2	\N	\N	\N	144.97956477	-37.85222765
3357078	2012-11-01	\N	420756334	\N	\N	FCS	2	\N	\N	\N	144.99287793	-37.82675684
2325773	2025-10-24	\N	420152356	\N	\N	FCS	2	\N	\N	\N	144.96881327	-37.81280333
FCS423732738	2023-04-27	\N	423732738	\N	\N	FCS	2	\N	\N	\N	144.95715084	-37.81689612
2441031	2012-11-01	\N	421126511	\N	\N	FCS	2	\N	\N	\N	145.17622189	-37.92766985
FCS717570827	2023-10-23	\N	717570827	\N	\N	FCS	2	\N	\N	\N	144.95401004	-37.81323986
422389231	2024-01-17	\N	422389231	\N	\N	FCS	2	\N	\N	\N	143.55789826	-38.63253256
FCS715905941	2023-07-26	\N	715905941	\N	\N	FCS	2	\N	\N	\N	144.95248254	-37.81421733
FCS425099296	2012-11-01	\N	425099296	\N	\N	FCS	2	\N	\N	\N	145.04077496	-37.87483964
PC422401732	2018-05-11	\N	422401732	\N	\N	PC	2	\N	\N	\N	146.56537648	-38.19952509
FCS425170282	2016-01-20	\N	425170282	\N	\N	FCS	2	\N	\N	\N	144.63756583	-37.54800545
FCS717906846	2025-01-16	\N	717906846	\N	\N	FCS	2	\N	\N	\N	144.60475668	-37.68506957
424359526	2012-11-01	\N	424359526	\N	\N	FCS	2	\N	\N	\N	145.28054568	-37.79951261
423799056	2012-11-01	\N	423799056	\N	\N	FCS	2	\N	\N	\N	146.54473742	-38.18180381
422217313	2012-11-01	\N	422217313	\N	\N	FCS	2	\N	\N	\N	144.82657597	-37.75222183
FCS714500561	2023-10-30	\N	714500561	\N	\N	FCS	2	\N	\N	\N	145.12306020	-37.81609649
2840050	2012-11-01	\N	421192512	\N	\N	FCS	2	\N	\N	\N	145.21695789	-37.86998686
423928534	2023-04-23	\N	423928534	\N	\N	FCS	2	\N	\N	\N	144.97940721	-37.84556706
3910463	2012-11-01	\N	421019197	\N	\N	FCS	2	\N	\N	\N	145.00201593	-37.85654984
FCS423762945	2013-10-30	\N	423762945	\N	\N	FCS	2	\N	\N	\N	145.00025242	-37.73804234
2910888	2012-11-01	\N	420033639	\N	\N	FCS	2	\N	\N	\N	145.01379491	-37.96762884
413788284	2012-11-01	\N	413788284	\N	\N	FCS	2	\N	\N	\N	145.26442452	-37.84333097
3791217	2024-01-23	\N	423311651	\N	\N	FCS	2	\N	\N	\N	144.97901820	-37.85909600
FCS715681078	2020-01-20	\N	715681078	\N	\N	FCS	2	\N	\N	\N	145.12558764	-38.04202953
FCS421278882	2020-07-23	\N	421278882	\N	\N	FCS	2	\N	\N	\N	144.92603870	-37.72752400
424032234	2012-11-01	\N	424032234	\N	\N	FCS	2	\N	\N	\N	144.77974789	-37.70673193
FCS425702034	2015-04-10	\N	425702034	\N	\N	FCS	2	\N	\N	\N	145.30070638	-38.11927653
FCS425455908	2024-01-21	\N	425455908	\N	\N	FCS	2	\N	\N	\N	144.93277234	-37.29327587
FCS425821086	2024-04-18	\N	425821086	\N	\N	FCS	2	\N	\N	\N	145.93627347	-38.47219566
4438306	2012-11-01	\N	412671558	\N	\N	FCS	2	\N	\N	\N	145.46469105	-37.81416067
2857545	2012-11-01	\N	419915681	\N	\N	FCS	2	\N	\N	\N	145.16734389	-37.90814685
3377706	2012-11-01	\N	420437639	\N	\N	FCS	2	\N	\N	\N	145.04535392	-37.82989084
420241455	2012-11-01	\N	420241455	\N	\N	FCS	2	\N	\N	\N	145.12613163	-38.05617128
3627090	2019-04-26	\N	422268958	\N	\N	FCS	2	\N	\N	\N	144.98428438	-37.75514597
424712054	2024-01-17	\N	424712054	\N	\N	FCS	2	\N	\N	\N	145.40725152	-36.35998165
424440974	2012-11-01	\N	424440974	\N	\N	FCS	2	\N	\N	\N	144.76417232	-37.77770331
4420034	2012-11-01	\N	412861624	\N	\N	FCS	2	\N	\N	\N	144.95546114	-37.82074898
4407587	2023-10-30	\N	423585040	\N	\N	FCS	2	\N	\N	\N	144.97687491	-37.83862075
PC715860667	2020-11-04	\N	715860667	\N	\N	PC	2	\N	\N	\N	144.32158067	-38.30851479
PC718119838	2026-01-28	\N	718119838	\N	\N	PC	2	\N	\N	\N	144.95928381	-37.82610944
PC420356298	2017-08-08	\N	420356298	\N	\N	PC	2	\N	\N	\N	144.73423511	-38.33770031
PC421844576	2017-08-08	\N	421844576	\N	\N	PC	2	\N	\N	\N	144.93719798	-37.78690045
PC419929442	2021-08-14	\N	419929442	\N	\N	PC	2	\N	\N	\N	145.23596636	-38.19600441
PC424718994	2017-08-08	\N	424718994	\N	\N	PC	2	\N	\N	\N	145.23011417	-37.80532995
PC419771930	2017-08-08	\N	419771930	\N	\N	PC	2	\N	\N	\N	144.96922390	-38.33621334
PC424350293	2017-08-08	\N	424350293	\N	\N	PC	2	\N	\N	\N	146.15808432	-38.21945775
PC424369203	2018-05-11	\N	424369203	\N	\N	PC	2	\N	\N	\N	144.61186095	-37.88540877
PC714922636	2023-11-07	\N	714922636	\N	\N	PC	2	\N	\N	\N	146.52229304	-38.20901553
PC419886687	2018-05-11	\N	419886687	\N	\N	PC	2	\N	\N	\N	145.05303893	-36.31154900
PC419958905	2017-08-08	\N	419958905	\N	\N	PC	2	\N	\N	\N	145.00492836	-37.86659051
PC421476681	2017-08-08	\N	421476681	\N	\N	PC	2	\N	\N	\N	145.03588401	-37.94510609
PC421019197	2017-08-08	\N	421019197	\N	\N	PC	2	\N	\N	\N	145.00209854	-37.85655384
PC423840170	2017-08-08	\N	423840170	\N	\N	PC	2	\N	\N	\N	144.73453176	-37.71854304
PC424836305	2017-08-08	\N	424836305	\N	\N	PC	2	\N	\N	\N	144.23383426	-36.77890195
PC425170282	2017-08-11	\N	425170282	\N	\N	PC	2	\N	\N	\N	144.63725797	-37.54666495
PC424370186	2017-08-11	\N	424370186	\N	\N	PC	2	\N	\N	\N	145.03899498	-37.95894401
PC421389843	2017-08-08	\N	421389843	\N	\N	PC	2	\N	\N	\N	145.02908828	-37.85984219
PC714824244	2017-08-08	\N	714824244	\N	\N	PC	2	\N	\N	\N	144.95507788	-37.80314051
PC420676040	2017-08-08	\N	420676040	\N	\N	PC	2	\N	\N	\N	144.71300530	-38.18340864
PC421932764	2018-05-11	\N	421932764	\N	\N	PC	2	\N	\N	\N	145.27027989	-37.84594329
PC419740543	2024-01-28	\N	419740543	\N	\N	PC	2	\N	\N	\N	144.76693577	-37.86102708
PC420198528	2017-08-08	\N	420198528	\N	\N	PC	2	\N	\N	\N	145.17744777	-38.15496681
PC421880072	2018-05-11	\N	421880072	\N	\N	PC	2	\N	\N	\N	145.01947382	-37.72069347
PC714912319	2017-11-23	\N	714912319	\N	\N	PC	2	\N	\N	\N	144.97908249	-37.84330435
PC714913664	2017-11-23	\N	714913664	\N	\N	PC	2	\N	\N	\N	144.90396955	-37.54170001
PC422250333	2018-05-11	\N	422250333	\N	\N	PC	2	\N	\N	\N	145.09390133	-37.83630760
PC714496633	2021-11-11	\N	714496633	\N	\N	PC	2	\N	\N	\N	144.30776988	-36.74155108
PC420658313	2017-08-08	\N	420658313	\N	\N	PC	2	\N	\N	\N	144.76070044	-37.76938253
PC425361109	2017-08-08	\N	425361109	\N	\N	PC	2	\N	\N	\N	145.14830745	-37.71904526
PC425255917	2017-08-08	\N	425255917	\N	\N	PC	2	\N	\N	\N	144.96153787	-37.81754563
PC420756334	2017-11-23	\N	420756334	\N	\N	PC	2	\N	\N	\N	144.99294888	-37.82677131
PC424350726	2017-08-08	\N	424350726	\N	\N	PC	2	\N	\N	\N	145.02787578	-37.71414026
PC420723393	2018-05-11	\N	420723393	\N	\N	PC	2	\N	\N	\N	145.10019124	-37.93095039
PC423965487	2023-11-07	\N	423965487	\N	\N	PC	2	\N	\N	\N	144.95614544	-37.81566178
PC423585372	2017-08-08	\N	423585372	\N	\N	PC	2	\N	\N	\N	144.97706111	-37.83851543
PC424722869	2017-08-11	\N	424722869	\N	\N	PC	2	\N	\N	\N	145.08243456	-37.88640009
PC412686819	2018-05-11	\N	412686819	\N	\N	PC	2	\N	\N	\N	145.22973988	-37.85448858
PC422385892	2023-11-07	\N	422385892	\N	\N	PC	2	\N	\N	\N	144.33647824	-36.79375157
PC421090069	2017-08-08	\N	421090069	\N	\N	PC	2	\N	\N	\N	144.99139370	-37.91059125
PC419986896	2017-08-08	\N	419986896	\N	\N	PC	2	\N	\N	\N	144.76070847	-38.36511090
PC421685051	2017-08-08	\N	421685051	\N	\N	PC	2	\N	\N	\N	144.96796651	-37.81132505
PC717491584	2023-08-06	\N	717491584	\N	\N	PC	2	\N	\N	\N	145.00422419	-37.94268589
PC717290269	2022-11-15	\N	717290269	\N	\N	PC	2	\N	\N	\N	144.51661862	-38.26996797
PC425875030	2017-08-08	\N	425875030	\N	\N	PC	2	\N	\N	\N	144.98711872	-37.80597122
PC425600398	2017-08-08	\N	425600398	\N	\N	PC	2	\N	\N	\N	144.95156049	-37.81110284
PC419947487	2024-01-28	\N	419947487	\N	\N	PC	2	\N	\N	\N	145.25936876	-37.82473487
PC425455908	2018-05-11	\N	425455908	\N	\N	PC	2	\N	\N	\N	144.93330342	-37.29252638
PC425373580	2023-11-07	\N	425373580	\N	\N	PC	2	\N	\N	\N	144.95303422	-37.81572283
PC419776057	2017-08-08	\N	419776057	\N	\N	PC	2	\N	\N	\N	145.06670588	-37.95356824
PC717906857	2025-01-27	\N	717906857	\N	\N	PC	2	\N	\N	\N	144.96735108	-37.83651759
PC715306462	2020-05-05	\N	715306462	\N	\N	PC	2	\N	\N	\N	144.97566530	-37.83875126
PC422268958	2019-05-06	\N	422268958	\N	\N	PC	2	\N	\N	\N	144.98429567	-37.75514669
PC425568954	2017-08-08	\N	425568954	\N	\N	PC	2	\N	\N	\N	145.01423987	-37.81138622
PC421546605	2023-11-07	\N	421546605	\N	\N	PC	2	\N	\N	\N	145.24736086	-37.90591220
PC717486497	2023-11-07	\N	717486497	\N	\N	PC	2	\N	\N	\N	144.95342350	-37.81449853
PC717220444	2023-11-07	\N	717220444	\N	\N	PC	2	\N	\N	\N	144.78943723	-37.79145894
PC715304381	2020-02-01	\N	715304381	\N	\N	PC	2	\N	\N	\N	146.28802901	-36.33963846
PC420321341	2017-08-08	\N	420321341	\N	\N	PC	2	\N	\N	\N	144.98179291	-37.80280087
PC425627533	2017-11-23	\N	425627533	\N	\N	PC	2	\N	\N	\N	144.43015980	-37.68650305
PC424439560	2017-08-08	\N	424439560	\N	\N	PC	2	\N	\N	\N	142.14437098	-34.23352438
PC420868495	2018-05-11	\N	420868495	\N	\N	PC	2	\N	\N	\N	145.16043003	-37.71598358
PC714824847	2018-05-11	\N	714824847	\N	\N	PC	2	\N	\N	\N	147.04167989	-36.47250015
PC717906846	2025-01-27	\N	717906846	\N	\N	PC	2	\N	\N	\N	144.60459257	-37.68500925
PC717914182	2025-01-27	\N	717914182	\N	\N	PC	2	\N	\N	\N	145.22164586	-37.91918982
PC425821086	2024-07-29	\N	425821086	\N	\N	PC	2	\N	\N	\N	145.93611948	-38.47241578
PC715905941	2023-11-07	\N	715905941	\N	\N	PC	2	\N	\N	\N	144.95248392	-37.81423051
PC424769747	2022-02-07	\N	424769747	\N	\N	PC	2	\N	\N	\N	145.16699720	-37.90972505
PC421192512	2023-11-07	\N	421192512	\N	\N	PC	2	\N	\N	\N	145.21688097	-37.87012396
PC421346876	2017-08-08	\N	421346876	\N	\N	PC	2	\N	\N	\N	145.09826673	-37.88351795
PC421377558	2017-08-08	\N	421377558	\N	\N	PC	2	\N	\N	\N	145.04677113	-37.77270081
PC420359646	2017-08-08	\N	420359646	\N	\N	PC	2	\N	\N	\N	145.05265605	-37.64083143
PC421749284	2018-05-11	\N	421749284	\N	\N	PC	2	\N	\N	\N	144.95698171	-37.73377884
PC420241455	2017-08-08	\N	420241455	\N	\N	PC	2	\N	\N	\N	145.12628097	-38.05645628
PC421050712	2017-08-08	\N	421050712	\N	\N	PC	2	\N	\N	\N	145.27723366	-38.50689480
PC420525075	2018-05-11	\N	420525075	\N	\N	PC	2	\N	\N	\N	145.27642524	-38.06940387
PC420778434	2018-05-11	\N	420778434	\N	\N	PC	2	\N	\N	\N	144.45844552	-38.18673286
PC425818341	2017-08-08	\N	425818341	\N	\N	PC	2	\N	\N	\N	145.04089614	-37.96207970
PC422389231	2024-01-28	\N	422389231	\N	\N	PC	2	\N	\N	\N	143.55807817	-38.63459219
PC425129914	2017-08-11	\N	425129914	\N	\N	PC	2	\N	\N	\N	145.14780239	-38.12263652
PC718117953	2026-01-28	\N	718117953	\N	\N	PC	2	\N	\N	\N	144.00020227	-38.23375040
PC421907605	2018-05-11	\N	421907605	\N	\N	PC	2	\N	\N	\N	145.05035613	-37.92572516
PC421436117	2017-08-08	\N	421436117	\N	\N	PC	2	\N	\N	\N	145.21390536	-37.96366644
PC424006537	2017-08-08	\N	424006537	\N	\N	PC	2	\N	\N	\N	144.93898220	-37.84125612
PC715624039	2026-01-28	\N	715624039	\N	\N	PC	2	\N	\N	\N	143.78368972	-37.54965128
PC419982912	2018-05-11	\N	419982912	\N	\N	PC	2	\N	\N	\N	144.92442784	-38.37332825
PC424850737	2017-08-08	\N	424850737	\N	\N	PC	2	\N	\N	\N	144.97862422	-37.84687562
PC717751011	2024-10-29	\N	717751011	\N	\N	PC	2	\N	\N	\N	144.95458348	-37.82165348
PC425618909	2023-11-07	\N	425618909	\N	\N	PC	2	\N	\N	\N	143.49190005	-35.31304770
PC425094218	2023-11-07	\N	425094218	\N	\N	PC	2	\N	\N	\N	144.96884633	-37.81201998
PC420127405	2018-05-11	\N	420127405	\N	\N	PC	2	\N	\N	\N	142.01654249	-37.73999729
PC421972789	2017-08-08	\N	421972789	\N	\N	PC	2	\N	\N	\N	144.99292272	-37.74126878
PC425360767	2017-08-08	\N	425360767	\N	\N	PC	2	\N	\N	\N	144.99809363	-37.61378753
PC420725420	2018-05-11	\N	420725420	\N	\N	PC	2	\N	\N	\N	144.93229795	-37.68800449
PC422073533	2023-11-07	\N	422073533	\N	\N	PC	2	\N	\N	\N	145.08211969	-37.71057877
PC419926535	2017-08-08	\N	419926535	\N	\N	PC	2	\N	\N	\N	145.28719046	-38.10146399
PC425822516	2017-08-08	\N	425822516	\N	\N	PC	2	\N	\N	\N	144.93930005	-37.77973357
PC422406512	2018-05-11	\N	422406512	\N	\N	PC	2	\N	\N	\N	146.84215566	-36.12672107
PC424351848	2017-08-08	\N	424351848	\N	\N	PC	2	\N	\N	\N	146.01314194	-37.07030165
PC424333656	2023-11-07	\N	424333656	\N	\N	PC	2	\N	\N	\N	145.93348816	-38.15904171
PC420339350	2018-05-11	\N	420339350	\N	\N	PC	2	\N	\N	\N	144.63750599	-37.90774766
PC423585040	2017-08-08	\N	423585040	\N	\N	PC	2	\N	\N	\N	144.97706111	-37.83851543
PC412875612	2017-08-08	\N	412875612	\N	\N	PC	2	\N	\N	\N	144.98082439	-37.85291634
PAPS717290269	2022-10-22	\N	717290269	\N	\N	PAPS	2	\N	\N	\N	144.51664265	-38.26980689
FCS715512010	2019-07-21	\N	715512010	\N	\N	FCS	2	\N	\N	\N	144.58248534	-37.65572307
3475762	2019-10-22	\N	420879105	\N	\N	FCS	2	\N	\N	\N	144.91246400	-38.37942785
PC423883673	2023-11-07	\N	423883673	\N	\N	PC	2	\N	\N	\N	144.94705758	-37.81822401
412520578	2012-11-01	\N	412520578	\N	\N	FCS	2	\N	\N	\N	144.97975428	-37.86242684
1731506	2012-11-01	\N	419986896	\N	\N	FCS	2	\N	\N	\N	144.76053791	-38.36497883
PC424617681	2018-05-11	\N	424617681	\N	\N	PC	2	\N	\N	\N	144.40038283	-38.03350445
PC717119544	2023-05-07	\N	717119544	\N	\N	PC	2	\N	\N	\N	144.93384977	-37.68855654
FCS424862074	2013-10-30	\N	424862074	\N	\N	FCS	2	\N	\N	\N	147.63783836	-37.82535527
FCS424863192	2012-11-01	\N	424863192	\N	\N	FCS	2	\N	\N	\N	145.35682189	-37.93104574
FCS718117102	2026-01-16	\N	718117102	\N	\N	FCS	2	\N	\N	\N	144.58409748	-37.89035611
FCS425094218	2025-10-24	\N	425094218	\N	\N	FCS	2	\N	\N	\N	144.96896432	-37.81231826
424674919	2012-11-01	\N	424674919	\N	\N	FCS	2	\N	\N	\N	144.76763784	-37.90628083
424850737	2023-10-30	\N	424850737	\N	\N	FCS	2	\N	\N	\N	144.97895103	-37.84679697
420387962	2012-11-01	\N	420387962	\N	\N	FCS	2	\N	\N	\N	144.55466591	-38.26152596
PC422222039	2025-10-29	\N	422222039	\N	\N	PC	2	\N	\N	\N	144.99315459	-37.89515697
PC419749804	2018-05-11	\N	419749804	\N	\N	PC	2	\N	\N	\N	145.26787900	-37.83364952
FCS425710626	2015-07-31	\N	425710626	\N	\N	FCS	2	\N	\N	\N	144.97100474	-37.79308649
420046530	2012-11-01	\N	420046530	\N	\N	FCS	2	\N	\N	\N	145.01488403	-37.74821083
3140198	2015-02-04	\N	422003187	\N	\N	FCS	2	\N	\N	\N	144.94564894	-37.76406510
421605628	2012-11-01	\N	421605628	\N	\N	FCS	2	\N	\N	\N	144.28538056	-36.75068194
FCS424722869	2023-04-23	\N	424722869	\N	\N	FCS	2	\N	\N	\N	145.08061617	-37.88768200
FCS425170184	2023-10-30	\N	425170184	\N	\N	FCS	2	\N	\N	\N	144.99673413	-37.78304333
2950687	2012-11-01	\N	420691543	\N	\N	FCS	2	\N	\N	\N	145.05021891	-37.90914884
PC421013154	2017-08-08	\N	421013154	\N	\N	PC	2	\N	\N	\N	143.26851330	-35.47596711
PC420891722	2023-11-07	\N	420891722	\N	\N	PC	2	\N	\N	\N	144.97530297	-37.77428143
PC421430383	2017-08-08	\N	421430383	\N	\N	PC	2	\N	\N	\N	145.10651595	-37.85926460
PC424001086	2017-08-08	\N	424001086	\N	\N	PC	2	\N	\N	\N	144.97057427	-37.83175520
PC423917070	2017-08-08	\N	423917070	\N	\N	PC	2	\N	\N	\N	144.96563154	-37.81759423
FCS425829932	2015-10-26	\N	425829932	\N	\N	FCS	2	\N	\N	\N	144.95408699	-37.81543898
424840184	2012-11-01	\N	424840184	\N	\N	PAPS	2	\N	\N	\N	145.16888267	-36.75186307
FCS425114129	2012-11-01	\N	425114129	\N	\N	FCS	2	\N	\N	\N	144.97693229	-37.84125908
4369076	2023-10-30	\N	423585372	\N	\N	FCS	2	\N	\N	\N	144.97687491	-37.83862075
PC420046530	2017-08-08	\N	420046530	\N	\N	PC	2	\N	\N	\N	145.01489833	-37.74814373
PC714595487	2017-08-08	\N	714595487	\N	\N	PC	2	\N	\N	\N	145.42056055	-38.07633959
PC714629757	2018-05-11	\N	714629757	\N	\N	PC	2	\N	\N	\N	145.27283979	-38.07485338
FCS421859624	2021-07-27	\N	421859624	\N	\N	FCS	2	\N	\N	\N	145.19469529	-37.92066388
420195833	2024-01-17	\N	420195833	\N	\N	FCS	2	\N	\N	\N	146.86124471	-36.13640441
2705563	2012-11-01	\N	419958905	\N	\N	FCS	2	\N	\N	\N	145.00504092	-37.86659484
425003423	2012-11-01	\N	425003423	\N	\N	FCS	2	\N	\N	\N	144.97902922	-37.84701078
FCS425830752	2015-10-26	\N	425830752	\N	\N	FCS	2	\N	\N	\N	144.32061091	-38.12673070
FCS715843419	2020-07-16	\N	715843419	\N	\N	FCS	2	\N	\N	\N	144.58284186	-37.86395465
1912438	2012-11-01	\N	420783355	\N	\N	FCS	2	\N	\N	\N	145.27655085	-38.07971786
FCS411585778	2013-10-30	\N	411585778	\N	\N	FCS	2	\N	\N	\N	145.04063792	-37.86009234
PC425099296	2017-08-08	\N	425099296	\N	\N	PC	2	\N	\N	\N	145.04073634	-37.87474539
PC425397743	2017-08-08	\N	425397743	\N	\N	PC	2	\N	\N	\N	145.02358278	-37.72729563
PC421826182	2017-08-08	\N	421826182	\N	\N	PC	2	\N	\N	\N	145.24280665	-37.89260621
PC422113967	2017-08-08	\N	422113967	\N	\N	PC	2	\N	\N	\N	144.69164347	-37.84058131
4450665	2012-11-01	\N	420562978	\N	\N	FCS	2	\N	\N	\N	145.76596901	-38.11003101
FCS714395624	2023-10-30	\N	714395624	\N	\N	FCS	2	\N	\N	\N	144.95542694	-37.80043670
421932764	2012-11-01	\N	421932764	\N	\N	FCS	2	\N	\N	\N	145.27006588	-37.84593386
PC425245912	2018-05-11	\N	425245912	\N	\N	PC	2	\N	\N	\N	144.95223137	-37.83223060
PC714694055	2017-08-08	\N	714694055	\N	\N	PC	2	\N	\N	\N	144.32818404	-38.22701936
PAPS717239943	2022-07-21	\N	717239943	\N	\N	PAPS	2	\N	\N	\N	144.64116180	-38.11139145
419771930	2012-11-01	\N	419771930	\N	\N	FCS	2	\N	\N	\N	144.96910952	-38.33626879
424991927	2012-11-01	\N	424991927	\N	\N	FCS	2	\N	\N	\N	145.06543874	-37.98102750
423566656	2025-01-22	\N	423566656	\N	\N	FCS	2	\N	\N	\N	144.97307567	-37.76496434
3044429	2015-02-04	\N	411947810	\N	\N	FCS	2	\N	\N	\N	144.97982610	-37.84919580
FCS717627424	2024-01-15	\N	717627424	\N	\N	FCS	2	\N	\N	\N	144.36216360	-38.01736342
3848356	2012-11-01	\N	421901952	\N	\N	FCS	2	\N	\N	\N	142.05971691	-34.16670897
2330630	2024-07-24	\N	421685051	\N	\N	FCS	2	\N	\N	\N	144.96770029	-37.81131701
FCS425258034	2017-07-29	\N	425258034	\N	\N	FCS	2	\N	\N	\N	144.58434507	-37.49016711
FCS715364337	2023-10-30	\N	715364337	\N	\N	FCS	2	\N	\N	\N	144.95816137	-37.82714046
1739698	2012-11-01	\N	419704523	\N	\N	FCS	2	\N	\N	\N	145.27522388	-37.86501586
419934459	2013-07-21	\N	419934459	\N	\N	FCS	2	\N	\N	\N	144.78540965	-37.87069403
1878089	2012-11-01	\N	421749284	\N	\N	FCS	2	\N	\N	\N	144.95686895	-37.73377284
2760083	2012-11-01	\N	420039411	\N	\N	FCS	2	\N	\N	\N	145.01220893	-37.76388184
2407138	2012-11-01	\N	421175767	\N	\N	FCS	2	\N	\N	\N	144.92848295	-37.75882583
FCS714598977	2017-01-20	\N	714598977	\N	\N	FCS	2	\N	\N	\N	144.88061497	-38.37019588
3872938	2024-04-25	\N	420920688	\N	\N	FCS	2	\N	\N	\N	145.00364361	-37.93029719
FCS715669684	2020-01-20	\N	715669684	\N	\N	FCS	2	\N	\N	\N	144.34093461	-38.20607026
FCS425549522	2014-07-17	\N	425549522	\N	\N	FCS	2	\N	\N	\N	144.98884738	-37.84423607
2484268	2012-11-01	\N	420967986	\N	\N	FCS	2	\N	\N	\N	144.91638095	-37.72169983
4081814	2012-11-01	\N	420053915	\N	\N	FCS	2	\N	\N	\N	144.92478696	-37.64974783
413526344	2012-11-01	\N	413526344	\N	\N	FCS	2	\N	\N	\N	145.08375985	-37.82413270
3573601	2012-11-01	\N	422165669	\N	\N	PAPS	2	\N	\N	\N	147.15681829	-36.74692880
FCS715370083	2019-01-24	\N	715370083	\N	\N	FCS	2	\N	\N	\N	144.96191382	-37.80632196
FCS425773322	2022-04-23	\N	425773322	\N	\N	PAPS	2	\N	\N	\N	144.96722002	-37.83622425
FCS424881609	2013-10-30	\N	424881609	\N	\N	FCS	2	\N	\N	\N	144.95917280	-37.81715463
FCS714376171	2016-07-22	\N	714376171	\N	\N	FCS	2	\N	\N	\N	144.96183795	-37.80563395
424333656	2024-01-17	\N	424333656	\N	\N	FCS	2	\N	\N	\N	145.93303540	-38.15891757
3639848	2023-10-24	\N	419864859	\N	\N	FCS	2	\N	\N	\N	146.42878989	-38.21986689
3502236	2012-11-01	\N	423193444	\N	\N	PAPS	2	\N	\N	\N	147.11768394	-36.36565171
2607877	2012-11-01	\N	420840829	\N	\N	FCS	2	\N	\N	\N	144.93415096	-37.63298383
423841412	2023-04-27	\N	423841412	\N	\N	FCS	2	\N	\N	\N	144.96247736	-37.82152105
FCS425455777	2014-10-25	\N	425455777	\N	\N	FCS	2	\N	\N	\N	144.97922971	-37.85228554
FCS715139892	2018-05-07	\N	715139892	\N	\N	FCS	2	\N	\N	\N	145.08095040	-37.95347890
PC715909004	2020-11-04	\N	715909004	\N	\N	PC	2	\N	\N	\N	145.42705359	-38.06291598
PC423311651	2017-08-08	\N	423311651	\N	\N	PC	2	\N	\N	\N	144.97934204	-37.85932988
PC424359526	2017-08-08	\N	424359526	\N	\N	PC	2	\N	\N	\N	145.28034203	-37.79955028
PC420182105	2017-08-08	\N	420182105	\N	\N	PC	2	\N	\N	\N	144.95142692	-37.83273121
PC420691543	2017-08-08	\N	420691543	\N	\N	PC	2	\N	\N	\N	145.05037106	-37.90916513
PC718119404	2026-01-28	\N	718119404	\N	\N	PC	2	\N	\N	\N	146.56652641	-38.19143672
PC412686822	2018-05-11	\N	412686822	\N	\N	PC	2	\N	\N	\N	145.22724167	-37.85359218
PC424863192	2023-11-07	\N	424863192	\N	\N	PC	2	\N	\N	\N	145.35603146	-37.93121622
PC420246858	2017-08-08	\N	420246858	\N	\N	PC	2	\N	\N	\N	145.14760103	-37.78617003
PC420465478	2022-05-09	\N	420465478	\N	\N	PC	2	\N	\N	\N	145.05280278	-37.85679014
PC422292427	2018-05-11	\N	422292427	\N	\N	PC	2	\N	\N	\N	145.06104367	-37.82246127
PC714598977	2018-05-11	\N	714598977	\N	\N	PC	2	\N	\N	\N	144.88074405	-38.37019280
PC714481851	2017-08-08	\N	714481851	\N	\N	PC	2	\N	\N	\N	144.95314608	-37.79877501
PC421124709	2017-08-08	\N	421124709	\N	\N	PC	2	\N	\N	\N	145.09791978	-37.87264183
PC424965089	2017-08-08	\N	424965089	\N	\N	PC	2	\N	\N	\N	145.04326363	-38.24812597
PC425908900	2017-08-08	\N	425908900	\N	\N	PC	2	\N	\N	\N	144.99332906	-37.71066530
PC413526344	2017-08-08	\N	413526344	\N	\N	PC	2	\N	\N	\N	145.08377651	-37.82399973
PC715310982	2018-11-05	\N	715310982	\N	\N	PC	2	\N	\N	\N	145.00729244	-37.90470858
PC424870928	2017-08-08	\N	424870928	\N	\N	PC	2	\N	\N	\N	144.54175054	-37.69771619
PC411236384	2018-05-11	\N	411236384	\N	\N	PC	2	\N	\N	\N	145.01490263	-37.89180905
PC421605628	2017-08-08	\N	421605628	\N	\N	PC	2	\N	\N	\N	144.28552196	-36.75078534
PC716131219	2021-11-11	\N	716131219	\N	\N	PC	2	\N	\N	\N	144.55462734	-36.01014372
PC425577907	2023-11-07	\N	425577907	\N	\N	PC	2	\N	\N	\N	145.13430328	-38.02965135
PC425795800	2017-08-11	\N	425795800	\N	\N	PC	2	\N	\N	\N	146.44445067	-37.14511018
PC420152356	2017-08-08	\N	420152356	\N	\N	PC	2	\N	\N	\N	144.96881535	-37.81286808
PC423762945	2023-11-07	\N	423762945	\N	\N	PC	2	\N	\N	\N	145.00038735	-37.73891901
PC420758704	2017-08-08	\N	420758704	\N	\N	PC	2	\N	\N	\N	145.06419078	-37.63699707
PC714908594	2018-05-11	\N	714908594	\N	\N	PC	2	\N	\N	\N	144.96086467	-37.80829488
PC420033639	2018-05-11	\N	420033639	\N	\N	PC	2	\N	\N	\N	145.01386230	-37.96746922
PC715364337	2019-05-06	\N	715364337	\N	\N	PC	2	\N	\N	\N	144.95826294	-37.82711797
PC423742341	2017-08-08	\N	423742341	\N	\N	PC	2	\N	\N	\N	144.95248483	-37.82287047
PC424122311	2018-05-11	\N	424122311	\N	\N	PC	2	\N	\N	\N	145.27358590	-38.01939447
PC420234237	2018-05-11	\N	420234237	\N	\N	PC	2	\N	\N	\N	145.13846534	-37.88018423
PC715372561	2019-05-06	\N	715372561	\N	\N	PC	2	\N	\N	\N	144.96064127	-37.81146513
PC425702523	2017-08-08	\N	425702523	\N	\N	PC	2	\N	\N	\N	145.02042646	-37.81304418
PC717679200	2024-04-29	\N	717679200	\N	\N	PC	2	\N	\N	\N	144.99672618	-37.88793794
PC422005646	2017-08-08	\N	422005646	\N	\N	PC	2	\N	\N	\N	145.83100573	-38.44013289
PC717570827	2023-11-07	\N	717570827	\N	\N	PC	2	\N	\N	\N	144.95393459	-37.81334737
PC419854489	2018-05-11	\N	419854489	\N	\N	PC	2	\N	\N	\N	145.05521718	-37.95651349
PC420390915	2017-08-08	\N	420390915	\N	\N	PC	2	\N	\N	\N	145.03282547	-37.68262236
PC420842711	2017-08-08	\N	420842711	\N	\N	PC	2	\N	\N	\N	145.07380155	-37.83793398
PC421624178	2017-08-08	\N	421624178	\N	\N	PC	2	\N	\N	\N	145.00947752	-37.89691673
PC424752485	2017-08-08	\N	424752485	\N	\N	PC	2	\N	\N	\N	144.73023810	-37.90807878
PC419828675	2018-05-11	\N	419828675	\N	\N	PC	2	\N	\N	\N	145.25681956	-37.89985306
PC422054200	2023-11-07	\N	422054200	\N	\N	PC	2	\N	\N	\N	145.15826746	-37.75364051
PC419934459	2018-05-11	\N	419934459	\N	\N	PC	2	\N	\N	\N	144.78526551	-37.87068137
PC422166370	2018-05-11	\N	422166370	\N	\N	PC	2	\N	\N	\N	145.11099153	-37.84234720
PC419788726	2023-11-07	\N	419788726	\N	\N	PC	2	\N	\N	\N	144.34372651	-38.08289282
PC715007348	2018-11-05	\N	715007348	\N	\N	PC	2	\N	\N	\N	144.99849227	-37.88452611
PC717907551	2025-01-27	\N	717907551	\N	\N	PC	2	\N	\N	\N	144.97619914	-37.84299175
PC420195833	2024-04-29	\N	420195833	\N	\N	PC	2	\N	\N	\N	146.86132024	-36.13639771
PC715529328	2019-08-05	\N	715529328	\N	\N	PC	2	\N	\N	\N	144.90258846	-37.79893230
PC421883545	2022-08-08	\N	421883545	\N	\N	PC	2	\N	\N	\N	145.00087688	-37.90353302
PC715669684	2020-02-01	\N	715669684	\N	\N	PC	2	\N	\N	\N	144.34093324	-38.20607794
PC412520578	2018-05-11	\N	412520578	\N	\N	PC	2	\N	\N	\N	144.97956645	-37.86252312
PC421817871	2019-05-06	\N	421817871	\N	\N	PC	2	\N	\N	\N	144.96797431	-37.81309613
PC420879105	2019-10-31	\N	420879105	\N	\N	PC	2	\N	\N	\N	144.91246424	-38.37945172
PC419752865	2017-08-08	\N	419752865	\N	\N	PC	2	\N	\N	\N	145.02118467	-37.70004520
PC424762274	2025-01-27	\N	424762274	\N	\N	PC	2	\N	\N	\N	147.06279476	-38.10435206
PC421034752	2018-05-11	\N	421034752	\N	\N	PC	2	\N	\N	\N	141.59732469	-38.35994140
PC714500561	2017-08-08	\N	714500561	\N	\N	PC	2	\N	\N	\N	145.12303728	-37.81619979
PC714993447	2018-05-11	\N	714993447	\N	\N	PC	2	\N	\N	\N	144.97463637	-37.83870081
PC715843419	2021-08-14	\N	715843419	\N	\N	PC	2	\N	\N	\N	144.58280480	-37.86388884
PC421712789	2017-08-08	\N	421712789	\N	\N	PC	2	\N	\N	\N	142.85453981	-37.15012549
PC420044405	2017-08-08	\N	420044405	\N	\N	PC	2	\N	\N	\N	144.77225957	-37.86072472
PC715139112	2023-11-07	\N	715139112	\N	\N	PC	2	\N	\N	\N	144.93829864	-37.81544355
PC420834992	2017-08-08	\N	420834992	\N	\N	PC	2	\N	\N	\N	144.96915488	-37.75341572
PC420562978	2017-08-08	\N	420562978	\N	\N	PC	2	\N	\N	\N	145.76606695	-38.10990673
PC420867943	2023-11-07	\N	420867943	\N	\N	PC	2	\N	\N	\N	145.35619749	-37.96870421
PC425319845	2018-05-11	\N	425319845	\N	\N	PC	2	\N	\N	\N	145.24941915	-38.11293107
PC420246079	2017-08-08	\N	420246079	\N	\N	PC	2	\N	\N	\N	145.12191929	-37.84338696
PC421236655	2017-08-08	\N	421236655	\N	\N	PC	2	\N	\N	\N	145.01626692	-37.93198526
PC425910197	2017-08-08	\N	425910197	\N	\N	PC	2	\N	\N	\N	144.91169852	-37.70848832
PC421177464	2018-05-11	\N	421177464	\N	\N	PC	2	\N	\N	\N	145.18936651	-38.31542108
PC423741522	2017-08-08	\N	423741522	\N	\N	PC	2	\N	\N	\N	144.96796651	-37.81132505
PC714824238	2017-08-08	\N	714824238	\N	\N	PC	2	\N	\N	\N	144.97908249	-37.84330435
PC424840184	2023-11-07	\N	424840184	\N	\N	PC	2	\N	\N	\N	145.16832684	-36.74100886
PC423928695	2020-08-05	\N	423928695	\N	\N	PC	2	\N	\N	\N	144.98028783	-37.84657592
PC419915681	2018-05-11	\N	419915681	\N	\N	PC	2	\N	\N	\N	145.16722053	-37.90814933
PC424576649	2018-05-11	\N	424576649	\N	\N	PC	2	\N	\N	\N	144.92124159	-38.37443029
PC717363938	2023-11-07	\N	717363938	\N	\N	PC	2	\N	\N	\N	145.23152159	-37.91936029
PC420073732	2017-08-08	\N	420073732	\N	\N	PC	2	\N	\N	\N	145.06741535	-37.96709204
PC420332142	2018-01-30	\N	420332142	\N	\N	PC	2	\N	\N	\N	145.16749544	-37.97390360
PC423981390	2017-08-08	\N	423981390	\N	\N	PC	2	\N	\N	\N	144.35026112	-38.13898530
PC425710626	2017-08-08	\N	425710626	\N	\N	PC	2	\N	\N	\N	144.97094340	-37.79310736
PC425179311	2017-08-08	\N	425179311	\N	\N	PC	2	\N	\N	\N	143.80955025	-36.43240323
PC421404996	2017-08-08	\N	421404996	\N	\N	PC	2	\N	\N	\N	145.41867383	-36.36612010
PC423193444	2017-08-08	\N	423193444	\N	\N	PC	2	\N	\N	\N	147.11835104	-36.37107825
PC421442494	2017-08-08	\N	421442494	\N	\N	PC	2	\N	\N	\N	145.26107362	-37.99749477
PC423713875	2018-05-11	\N	423713875	\N	\N	PC	2	\N	\N	\N	144.94589754	-37.79807427
PC419822291	2023-11-07	\N	419822291	\N	\N	PC	2	\N	\N	\N	143.79357522	-37.83747105
PC423539011	2017-08-08	\N	423539011	\N	\N	PC	2	\N	\N	\N	144.96728894	-37.79433828
PC423841412	2017-08-08	\N	423841412	\N	\N	PC	2	\N	\N	\N	144.96218853	-37.82170194
FCS424023915	2025-04-17	\N	424023915	\N	\N	FCS	2	\N	\N	\N	145.97512786	-36.55570371
4262598	2020-10-20	\N	412686819	\N	\N	PAPS	2	\N	\N	\N	145.22971282	-37.85445861
423917070	2015-02-04	\N	423917070	\N	\N	FCS	2	\N	\N	\N	144.96565347	-37.81775091
PC420632037	2017-08-08	\N	420632037	\N	\N	PC	2	\N	\N	\N	145.03390642	-37.82692660
PC423222907	2017-08-08	\N	423222907	\N	\N	PC	2	\N	\N	\N	145.29331809	-38.13844245
PC420387962	2017-08-08	\N	420387962	\N	\N	PC	2	\N	\N	\N	144.55458522	-38.26148237
PC425549522	2018-05-11	\N	425549522	\N	\N	PC	2	\N	\N	\N	144.98885131	-37.84432442
PC420775290	2017-08-08	\N	420775290	\N	\N	PC	2	\N	\N	\N	144.69848762	-37.46796284
FCS717491584	2023-07-20	\N	717491584	\N	\N	FCS	2	\N	\N	\N	145.00426485	-37.94247202
FCS425773555	2025-04-22	\N	425773555	\N	\N	FCS	2	\N	\N	\N	147.27784059	-36.86512101
3851258	2012-11-01	\N	421090069	\N	\N	FCS	2	\N	\N	\N	144.99138092	-37.91060984
3406882	2012-11-01	\N	420198528	\N	\N	FCS	2	\N	\N	\N	145.17748186	-38.15497185
PC421985493	2017-08-08	\N	421985493	\N	\N	PC	2	\N	\N	\N	145.05495211	-37.74201229
PC411960119	2018-05-11	\N	411960119	\N	\N	PC	2	\N	\N	\N	144.97600504	-37.84246398
PC425003423	2018-05-11	\N	425003423	\N	\N	PC	2	\N	\N	\N	144.97872137	-37.84714089
PC420012023	2017-08-08	\N	420012023	\N	\N	PC	2	\N	\N	\N	145.09053367	-37.98610467
PC422217313	2018-05-11	\N	422217313	\N	\N	PC	2	\N	\N	\N	144.82652591	-37.75213013
PC421802511	2018-05-11	\N	421802511	\N	\N	PC	2	\N	\N	\N	146.94796367	-36.18573452
PC717681413	2024-10-29	\N	717681413	\N	\N	PC	2	\N	\N	\N	145.08567041	-37.64776539
PC716078606	2021-04-27	\N	716078606	\N	\N	PC	2	\N	\N	\N	144.87306849	-37.64075559
PC420281832	2017-08-08	\N	420281832	\N	\N	PC	2	\N	\N	\N	145.57686045	-36.75528572
PC423928534	2018-05-11	\N	423928534	\N	\N	PC	2	\N	\N	\N	144.97987654	-37.84554394
FCS424001698	2015-02-04	\N	424001698	\N	\N	FCS	2	\N	\N	\N	144.97111975	-37.83180171
2458370	2023-07-22	\N	421431415	\N	\N	FCS	2	\N	\N	\N	145.28998847	-38.03968301
PAPS717113574	2022-01-25	\N	717113574	\N	\N	PAPS	2	\N	\N	\N	143.97236401	-38.53454590
FCS715372561	2019-01-24	\N	715372561	\N	\N	FCS	2	\N	\N	\N	144.96065746	-37.81150292
PC420186048	2024-01-28	\N	420186048	\N	\N	PC	2	\N	\N	\N	145.78885566	-38.67936596
PC411814562	2017-08-08	\N	411814562	\N	\N	PC	2	\N	\N	\N	145.02785535	-37.80310309
PC714909570	2018-05-11	\N	714909570	\N	\N	PC	2	\N	\N	\N	144.96086467	-37.80829488
4005881	2012-11-01	\N	421907605	\N	\N	FCS	2	\N	\N	\N	145.05035091	-37.92571484
PC715130385	2019-05-06	\N	715130385	\N	\N	PC	2	\N	\N	\N	144.98435575	-37.70188264
PC714373238	2018-05-11	\N	714373238	\N	\N	PC	2	\N	\N	\N	143.80033814	-37.58021883
PC424761278	2017-08-08	\N	424761278	\N	\N	PC	2	\N	\N	\N	145.18356342	-38.08842866
PC717113574	2023-11-07	\N	717113574	\N	\N	PC	2	\N	\N	\N	143.97234720	-38.53508879
FCS425319845	2013-04-17	\N	425319845	\N	\N	FCS	2	\N	\N	\N	145.24940385	-38.11300223
420127405	2012-11-01	\N	420127405	\N	\N	FCS	2	\N	\N	\N	142.01663921	-37.73995574
FCS425822516	2015-10-26	\N	425822516	\N	\N	FCS	2	\N	\N	\N	144.93938448	-37.77969041
2135164	2012-11-01	\N	421236655	\N	\N	FCS	2	\N	\N	\N	145.01610791	-37.93198184
2683297	2024-04-18	\N	421561145	\N	\N	FCS	2	\N	\N	\N	145.14903033	-37.97050256
FCS714481851	2016-10-25	\N	714481851	\N	\N	FCS	2	\N	\N	\N	144.95324680	-37.79869617
FCS425175658	2012-11-01	\N	425175658	\N	\N	FCS	2	\N	\N	\N	145.48748069	-38.07282307
FCS717576437	2023-10-23	\N	717576437	\N	\N	FCS	2	\N	\N	\N	145.04121525	-37.83841614
FCS715909004	2020-10-17	\N	715909004	\N	\N	FCS	2	\N	\N	\N	145.42716137	-38.06293073
PC714805257	2018-05-11	\N	714805257	\N	\N	PC	2	\N	\N	\N	144.97043632	-37.83111090
PC419838142	2017-08-08	\N	419838142	\N	\N	PC	2	\N	\N	\N	142.51797009	-38.37639554
424001086	2015-02-04	\N	424001086	\N	\N	FCS	2	\N	\N	\N	144.97111975	-37.83180171
FCS714427784	2016-08-01	\N	714427784	\N	\N	FCS	2	\N	\N	\N	144.96847178	-37.80918104
FCS425702523	2015-04-10	\N	425702523	\N	\N	FCS	2	\N	\N	\N	145.02045030	-37.81291837
FCS420631407	2020-07-23	\N	420631407	\N	\N	FCS	2	\N	\N	\N	145.47806519	-38.07937173
PC420768801	2020-02-01	\N	420768801	\N	\N	PC	2	\N	\N	\N	146.90511721	-36.13181517
PC717706362	2024-04-29	\N	717706362	\N	\N	PC	2	\N	\N	\N	145.03883605	-37.95143934
2152688	2012-11-01	\N	421177464	\N	\N	FCS	2	\N	\N	\N	145.18953684	-38.31542186
423222907	2020-05-08	\N	423222907	\N	\N	PAPS	2	\N	\N	\N	145.29331660	-38.13844700
FCS714595487	2017-01-20	\N	714595487	\N	\N	FCS	2	\N	\N	\N	145.42060832	-38.07634274
FCS716078606	2021-04-18	\N	716078606	\N	\N	FCS	2	\N	\N	\N	144.87308230	-37.64068727
PC424674919	2017-08-08	\N	424674919	\N	\N	PC	2	\N	\N	\N	144.76762062	-37.90621119
PC421563343	2017-08-08	\N	421563343	\N	\N	PC	2	\N	\N	\N	145.01724396	-37.72599919
421712789	2012-11-01	\N	421712789	\N	\N	FCS	2	\N	\N	\N	142.85439001	-37.15033645
FCS714373238	2016-07-22	\N	714373238	\N	\N	FCS	2	\N	\N	\N	143.80032960	-37.58030430
2742620	2012-11-01	\N	422054200	\N	\N	FCS	2	\N	\N	\N	145.15823591	-37.75359385
FCS715517209	2019-07-21	\N	715517209	\N	\N	FCS	2	\N	\N	\N	144.46241460	-38.20247914
3333111	2012-11-01	\N	420842711	\N	\N	FCS	2	\N	\N	\N	145.07381991	-37.83804685
FCS715139112	2018-05-07	\N	715139112	\N	\N	FCS	2	\N	\N	\N	144.93801394	-37.81532063
PC424812537	2017-08-08	\N	424812537	\N	\N	PC	2	\N	\N	\N	144.76481207	-37.90626657
PC419746060	2017-08-08	\N	419746060	\N	\N	PC	2	\N	\N	\N	144.61944404	-37.89747201
PC715903043	2020-11-04	\N	715903043	\N	\N	PC	2	\N	\N	\N	144.95341602	-37.82109805
PC411999327	2017-08-08	\N	411999327	\N	\N	PC	2	\N	\N	\N	145.06610418	-37.98682554
FCS423928695	2023-04-23	\N	423928695	\N	\N	FCS	2	\N	\N	\N	144.97980325	-37.84670035
424769747	2023-01-18	\N	424769747	\N	\N	FCS	2	\N	\N	\N	145.16705403	-37.90973248
PC718117102	2026-01-28	\N	718117102	\N	\N	PC	2	\N	\N	\N	144.58410694	-37.89042779
PC419712244	2018-05-11	\N	419712244	\N	\N	PC	2	\N	\N	\N	144.94460843	-37.80527782
PC421175767	2017-08-08	\N	421175767	\N	\N	PC	2	\N	\N	\N	144.92833958	-37.75882396
PC421944818	2017-08-08	\N	421944818	\N	\N	PC	2	\N	\N	\N	145.99093362	-36.55705980
424836305	2024-04-18	\N	424836305	\N	\N	FCS	2	\N	\N	\N	144.23386480	-36.77892429
FCS717914182	2025-01-16	\N	717914182	\N	\N	FCS	2	\N	\N	\N	145.22167130	-37.91920783
3089018	2025-01-22	\N	419865039	\N	\N	FCS	2	\N	\N	\N	144.88899581	-37.79520947
4527103	2012-11-01	\N	423604983	\N	\N	FCS	2	\N	\N	\N	145.19454599	-37.83764050
420498308	2024-07-15	\N	420498308	\N	\N	FCS	2	\N	\N	\N	143.92348651	-35.73322369
FCS425373580	2013-07-16	\N	425373580	\N	\N	FCS	2	\N	\N	\N	144.95308018	-37.81557058
PC717239943	2023-11-07	\N	717239943	\N	\N	PC	2	\N	\N	\N	144.63300651	-38.11385514
421013154	2012-11-01	\N	421013154	\N	\N	FCS	2	\N	\N	\N	143.26832660	-35.47597811
FCS425577907	2020-10-20	\N	425577907	\N	\N	FCS	2	\N	\N	\N	145.13427691	-38.02967451
FCS425255917	2023-10-30	\N	425255917	\N	\N	FCS	2	\N	\N	\N	144.96159702	-37.81752885
4115999	2019-01-28	\N	421880072	\N	\N	FCS	2	\N	\N	\N	145.01962355	-37.72071175
4118844	2012-11-01	\N	420356298	\N	\N	FCS	2	\N	\N	\N	144.73374592	-38.33777483
3339078	2022-10-26	\N	421883545	\N	\N	FCS	2	\N	\N	\N	145.00086460	-37.90359279
FCS717568260	2023-10-23	\N	717568260	\N	\N	FCS	2	\N	\N	\N	145.11682777	-37.81786505
FCS419838142	2015-04-17	\N	419838142	\N	\N	FCS	2	\N	\N	\N	142.51798353	-38.37631556
FCS717119544	2023-07-22	\N	717119544	\N	\N	FCS	2	\N	\N	\N	144.93382902	-37.68866198
2516633	2012-11-01	\N	420012023	\N	\N	FCS	2	\N	\N	\N	145.09049090	-37.98621985
FCS715897322	2023-07-26	\N	715897322	\N	\N	FCS	2	\N	\N	\N	144.95248254	-37.81421733
FCS425397743	2013-10-22	\N	425397743	\N	\N	FCS	2	\N	\N	\N	145.02356726	-37.72730375
424762274	2024-10-19	\N	424762274	\N	\N	FCS	2	\N	\N	\N	147.06264578	-38.10435588
422406512	2024-01-17	\N	422406512	\N	\N	FCS	2	\N	\N	\N	146.84235497	-36.12677250
FCS716131219	2021-07-25	\N	716131219	\N	\N	FCS	2	\N	\N	\N	144.55463388	-36.01112965
FCS715437863	2025-04-24	\N	715437863	\N	\N	FCS	2	\N	\N	\N	144.96356449	-37.82421909
FCS716128783	2024-04-18	\N	716128783	\N	\N	FCS	2	\N	\N	\N	143.79015646	-37.57346998
1611583	2012-11-01	\N	420256879	\N	\N	FCS	2	\N	\N	\N	144.99771793	-37.80112584
3360410	2012-11-01	\N	420226560	\N	\N	FCS	2	\N	\N	\N	144.96591795	-37.69607084
419828675	2012-11-01	\N	419828675	\N	\N	FCS	2	\N	\N	\N	145.25627688	-37.89960386
FCS715310982	2018-10-28	\N	715310982	\N	\N	FCS	2	\N	\N	\N	145.00724733	-37.90494907
FCS715298489	2018-10-28	\N	715298489	\N	\N	FCS	2	\N	\N	\N	144.97599334	-37.83867611
4192570	2012-11-01	\N	421404996	\N	\N	FCS	2	\N	\N	\N	145.41878792	-36.36611726
FCS716084829	2021-04-16	\N	716084829	\N	\N	FCS	2	\N	\N	\N	145.56881932	-38.08411955
1917484	2012-11-01	\N	420525075	\N	\N	FCS	2	\N	\N	\N	145.27640385	-38.06949586
4060566	2012-11-01	\N	421564892	\N	\N	FCS	2	\N	\N	\N	145.05990293	-37.73417184
4016698	2012-11-01	\N	421124709	\N	\N	FCS	2	\N	\N	\N	145.09782991	-37.87256485
2259932	2012-11-01	\N	421826182	\N	\N	FCS	2	\N	\N	\N	145.24271688	-37.89255286
FCS715306462	2018-10-28	\N	715306462	\N	\N	FCS	2	\N	\N	\N	144.97599334	-37.83867611
FCS715860667	2020-10-20	\N	715860667	\N	\N	FCS	2	\N	\N	\N	144.32161328	-38.30843736
424666593	2012-11-01	\N	424666593	\N	\N	FCS	2	\N	\N	\N	145.27714110	-37.88333706
422521967	2012-11-01	\N	422521967	\N	\N	FCS	2	\N	\N	\N	146.85930216	-36.11670451
420984525	2012-11-01	\N	420984525	\N	\N	FCS	2	\N	\N	\N	144.49026312	-38.26645855
1860648	2012-11-01	\N	420073732	\N	\N	FCS	2	\N	\N	\N	145.06742590	-37.96700885
FCS714798142	2017-07-26	\N	714798142	\N	\N	FCS	2	\N	\N	\N	143.83740943	-37.58334028
FCS714805257	2017-07-26	\N	714805257	\N	\N	FCS	2	\N	\N	\N	144.97095196	-37.83106671
1632498	2024-01-17	\N	421802511	\N	\N	FCS	2	\N	\N	\N	146.94689729	-36.18544068
FCS715007348	2018-01-19	\N	715007348	\N	\N	FCS	2	\N	\N	\N	144.99828331	-37.88463722
2877949	2012-11-01	\N	421861654	\N	\N	FCS	2	\N	\N	\N	144.66250098	-37.89781982
FCS714629757	2019-02-01	\N	714629757	\N	\N	FCS	2	\N	\N	\N	145.27250387	-38.07502010
424369203	2012-11-01	\N	424369203	\N	\N	FCS	2	\N	\N	\N	144.61177349	-37.88539910
PAPS714824847	2017-07-26	\N	714824847	\N	\N	PAPS	2	\N	\N	\N	147.03927940	-36.47912795
2756780	2012-11-01	\N	421278486	\N	\N	FCS	2	\N	\N	\N	144.87903596	-37.69411483
FCS718052177	2025-10-15	\N	718052177	\N	\N	FCS	2	\N	\N	\N	144.94614424	-37.81319205
421618968	2012-11-01	\N	421618968	\N	\N	FCS	2	\N	\N	\N	145.05733918	-37.76930735
FCS714592328	2017-01-20	\N	714592328	\N	\N	FCS	2	\N	\N	\N	144.94431849	-37.82967437
2015148	2012-11-01	\N	420359646	\N	\N	FCS	2	\N	\N	\N	145.05269194	-37.64075884
FCS425627533	2021-01-18	\N	425627533	\N	\N	PAPS	2	\N	\N	\N	144.43016290	-37.68646938
2093384	2020-10-27	\N	421436852	\N	\N	FCS	2	\N	\N	\N	145.04523577	-37.85376115
FCS425399758	2024-01-17	\N	425399758	\N	\N	FCS	2	\N	\N	\N	144.97378966	-37.41798163
FCS425568954	2015-01-19	\N	425568954	\N	\N	FCS	2	\N	\N	\N	145.01414918	-37.81175875
3421641	2012-11-01	\N	421377558	\N	\N	FCS	2	\N	\N	\N	145.04675093	-37.77270184
FCS717706362	2024-04-24	\N	717706362	\N	\N	FCS	2	\N	\N	\N	145.03897191	-37.95146084
4161621	2012-11-01	\N	420180173	\N	\N	FCS	2	\N	\N	\N	144.92750496	-37.69164883
PC420803245	2018-05-11	\N	420803245	\N	\N	PC	2	\N	\N	\N	147.05972100	-38.10053984
PC412114290	2017-08-08	\N	412114290	\N	\N	PC	2	\N	\N	\N	145.15526470	-36.78138704
PC424712054	2017-08-08	\N	424712054	\N	\N	PC	2	\N	\N	\N	145.40726231	-36.35987214
PC420984525	2018-05-11	\N	420984525	\N	\N	PC	2	\N	\N	\N	144.49039666	-38.26647429
PC420894156	2017-08-08	\N	420894156	\N	\N	PC	2	\N	\N	\N	144.73592716	-38.34394737
PC423726275	2017-08-08	\N	423726275	\N	\N	PC	2	\N	\N	\N	144.96082262	-37.80740714
2727616	2012-11-01	\N	421079146	\N	\N	FCS	2	\N	\N	\N	146.89489306	-36.12617623
3524113	2012-11-01	\N	419746060	\N	\N	FCS	2	\N	\N	\N	144.61954999	-37.89747281
2159173	2012-11-01	\N	419854489	\N	\N	FCS	2	\N	\N	\N	145.05521891	-37.95650684
FCS714993447	2023-10-30	\N	714993447	\N	\N	FCS	2	\N	\N	\N	144.97430770	-37.83877571
PC717627424	2024-01-28	\N	717627424	\N	\N	PC	2	\N	\N	\N	144.36215582	-38.01740348
PC420039411	2017-08-08	\N	420039411	\N	\N	PC	2	\N	\N	\N	145.01206748	-37.76386661
PC715373884	2019-02-04	\N	715373884	\N	\N	PC	2	\N	\N	\N	144.95679290	-37.82773457
PC420271959	2017-08-08	\N	420271959	\N	\N	PC	2	\N	\N	\N	144.91021356	-37.77869048
PC424862074	2023-11-07	\N	424862074	\N	\N	PC	2	\N	\N	\N	147.63765340	-37.82508882
PC425773322	2017-08-08	\N	425773322	\N	\N	PC	2	\N	\N	\N	144.96760061	-37.83631456
3963548	2012-11-01	\N	421944818	\N	\N	FCS	2	\N	\N	\N	145.99080275	-36.55703206
PAPS424063457	2023-04-27	\N	424063457	\N	\N	PAPS	2	\N	\N	\N	144.53814538	-36.88749014
FCS715300859	2023-04-27	\N	715300859	\N	\N	FCS	2	\N	\N	\N	144.96051896	-37.80786078
420725420	2012-11-01	\N	420725420	\N	\N	FCS	2	\N	\N	\N	144.93233076	-37.68788889
423883673	2023-07-26	\N	423883673	\N	\N	FCS	2	\N	\N	\N	144.94697159	-37.81829164
FCS714909570	2023-04-27	\N	714909570	\N	\N	FCS	2	\N	\N	\N	144.96073354	-37.80833027
424576649	2012-11-01	\N	424576649	\N	\N	FCS	2	\N	\N	\N	144.92224944	-38.37560022
3650050	2012-11-01	\N	421050712	\N	\N	FCS	2	\N	\N	\N	145.27731319	-38.50680422
PC425608760	2017-08-08	\N	425608760	\N	\N	PC	2	\N	\N	\N	144.96206592	-37.82546939
PC421564892	2023-11-07	\N	421564892	\N	\N	PC	2	\N	\N	\N	145.05964150	-37.73414283
PC424510130	2017-08-11	\N	424510130	\N	\N	PC	2	\N	\N	\N	145.04746882	-37.87615128
PC715437863	2019-05-06	\N	715437863	\N	\N	PC	2	\N	\N	\N	144.96371205	-37.82409383
PC423531516	2018-05-11	\N	423531516	\N	\N	PC	2	\N	\N	\N	144.75165280	-37.72168290
PC425175658	2017-08-08	\N	425175658	\N	\N	PC	2	\N	\N	\N	145.48749043	-38.07283752
PC419704523	2018-05-11	\N	419704523	\N	\N	PC	2	\N	\N	\N	145.27522173	-37.86510372
FCS425366225	2013-07-16	\N	425366225	\N	\N	FCS	2	\N	\N	\N	144.95707987	-37.82686811
1957946	2012-11-01	\N	420671470	\N	\N	FCS	2	\N	\N	\N	145.13164391	-37.77534685
1955089	2012-11-01	\N	420658313	\N	\N	FCS	2	\N	\N	\N	144.76059798	-37.76937482
FCS717486497	2023-07-20	\N	717486497	\N	\N	FCS	2	\N	\N	\N	144.95342148	-37.81448127
FCS717226582	2022-07-21	\N	717226582	\N	\N	FCS	2	\N	\N	\N	144.71366136	-37.69387698
2362073	2012-11-01	\N	420788115	\N	\N	FCS	2	\N	\N	\N	145.11537391	-37.80968285
420676040	2012-11-01	\N	420676040	\N	\N	FCS	2	\N	\N	\N	144.71298395	-38.18351371
FCS421848752	2019-10-28	\N	421848752	\N	\N	FCS	2	\N	\N	\N	144.80946570	-37.79205213
FCS425363148	2013-07-16	\N	425363148	\N	\N	FCS	2	\N	\N	\N	144.96918736	-37.82945629
420778434	2012-11-01	\N	420778434	\N	\N	FCS	2	\N	\N	\N	144.45844070	-38.18678995
FCS424372213	2013-01-11	\N	424372213	\N	\N	FCS	2	\N	\N	\N	144.93704183	-37.75970427
FCS715443954	2019-04-24	\N	715443954	\N	\N	FCS	2	\N	\N	\N	145.00241335	-37.74644453
419712244	2023-04-23	\N	419712244	\N	\N	FCS	2	\N	\N	\N	144.94457917	-37.80536765
421588755	2012-11-01	\N	421588755	\N	\N	FCS	2	\N	\N	\N	144.54439636	-38.26942449
FCS425910197	2016-04-22	\N	425910197	\N	\N	FCS	2	\N	\N	\N	144.91169648	-37.70846694
4302164	2012-11-01	\N	422113967	\N	\N	FCS	2	\N	\N	\N	144.69173458	-37.84058603
2660718	2012-11-01	\N	420182105	\N	\N	FCS	2	\N	\N	\N	144.95148594	-37.83279084
2658528	2012-11-01	\N	420758704	\N	\N	FCS	2	\N	\N	\N	145.06421894	-37.63707884
FCS717908928	2025-01-16	\N	717908928	\N	\N	FCS	2	\N	\N	\N	145.00483643	-37.63683577
420775290	2012-11-01	\N	420775290	\N	\N	PAPS	2	\N	\N	\N	144.69508343	-37.46671163
FCS714694055	2017-04-21	\N	714694055	\N	\N	FCS	2	\N	\N	\N	144.32718535	-38.22548958
3989108	2012-11-01	\N	420234237	\N	\N	FCS	2	\N	\N	\N	145.13832838	-37.88006953
FCS714496633	2021-10-28	\N	714496633	\N	\N	FCS	2	\N	\N	\N	144.30785872	-36.74158052
FCS718119404	2026-01-16	\N	718119404	\N	\N	FCS	2	\N	\N	\N	146.56651988	-38.19143803
3621285	2015-02-04	\N	422292427	\N	\N	FCS	2	\N	\N	\N	145.06104233	-37.82256113
1912636	2012-11-01	\N	419926535	\N	\N	FCS	2	\N	\N	\N	145.28727385	-38.10147586
1941919	2012-11-01	\N	421436117	\N	\N	FCS	2	\N	\N	\N	145.21388388	-37.96374586
3670566	2012-11-01	\N	421027630	\N	\N	FCS	2	\N	\N	\N	144.73283607	-37.36058091
FCS717679200	2024-04-16	\N	717679200	\N	\N	FCS	2	\N	\N	\N	144.99668006	-37.88790169
FCS425171577	2012-11-01	\N	425171577	\N	\N	FCS	2	\N	\N	\N	145.49596135	-38.05568418
3862291	2024-01-17	\N	419740543	\N	\N	FCS	2	\N	\N	\N	144.76699564	-37.86095143
424351848	2012-11-01	\N	424351848	\N	\N	PAPS	2	\N	\N	\N	146.01260217	-37.06902526
2266947	2012-11-01	\N	420910016	\N	\N	FCS	2	\N	\N	\N	144.76389298	-37.73560182
4261796	2012-11-01	\N	419822291	\N	\N	PAPS	2	\N	\N	\N	143.79257358	-37.83920614
3697098	2012-11-01	\N	421274476	\N	\N	FCS	2	\N	\N	\N	144.55745027	-38.16280641
FCS717907551	2025-01-16	\N	717907551	\N	\N	FCS	2	\N	\N	\N	144.97587008	-37.84306552
4332178	2012-11-01	\N	423531516	\N	\N	FCS	2	\N	\N	\N	144.75166398	-37.72164337
411960119	2026-01-24	\N	411960119	\N	\N	FCS	2	\N	\N	\N	144.97568145	-37.84253725
FCS425402896	2013-10-22	\N	425402896	\N	\N	FCS	2	\N	\N	\N	145.14957729	-37.77324143
4019178	2012-11-01	\N	419749804	\N	\N	FCS	2	\N	\N	\N	145.26791988	-37.83366186
4454300	2012-11-01	\N	411236384	\N	\N	FCS	2	\N	\N	\N	145.01510717	-37.89180933
422005646	2012-11-01	\N	422005646	\N	\N	FCS	2	\N	\N	\N	145.83101011	-38.44012569
FCS715304381	2018-10-28	\N	715304381	\N	\N	FCS	2	\N	\N	\N	146.28813510	-36.33965077
2917371	2015-02-04	\N	423328381	\N	\N	FCS	2	\N	\N	\N	144.97620603	-37.84404234
419795153	2024-04-18	\N	419795153	\N	\N	FCS	2	\N	\N	\N	144.27939626	-36.74546263
421124750	2012-11-01	\N	421124750	\N	\N	FCS	2	\N	\N	\N	146.01850091	-36.00805913
422385892	2024-04-18	\N	422385892	\N	\N	FCS	2	\N	\N	\N	144.33627905	-36.79372982
3056571	2023-07-26	\N	411967773	\N	\N	FCS	2	\N	\N	\N	144.97471609	-37.83550076
FCS421844576	2013-07-21	\N	421844576	\N	\N	FCS	2	\N	\N	\N	144.93719722	-37.78690307
FCS425245912	2013-01-10	\N	425245912	\N	\N	FCS	2	\N	\N	\N	144.95228428	-37.83226723
FCS425169627	2012-11-01	\N	425169627	\N	\N	FCS	2	\N	\N	\N	144.91613447	-37.72201345
412875612	2015-02-04	\N	412875612	\N	\N	FCS	2	\N	\N	\N	144.98115145	-37.85282693
FCS422073533	2012-11-01	\N	422073533	\N	\N	FCS	2	\N	\N	\N	145.08213818	-37.71045753
FCS425818341	2015-10-26	\N	425818341	\N	\N	FCS	2	\N	\N	\N	145.04088787	-37.96212191
420281832	2012-11-01	\N	420281832	\N	\N	FCS	2	\N	\N	\N	145.57699318	-36.75530318
420768801	2012-11-01	\N	420768801	\N	\N	FCS	2	\N	\N	\N	146.90513845	-36.13174471
1869047	2014-10-25	\N	419810399	\N	\N	FCS	2	\N	\N	\N	145.12807186	-37.91164390
1854316	2012-11-01	\N	421346876	\N	\N	FCS	2	\N	\N	\N	145.09827891	-37.88350685
FCS714992137	2018-01-19	\N	714992137	\N	\N	FCS	2	\N	\N	\N	144.96121215	-37.80936093
FCS424817497	2023-10-24	\N	424817497	\N	\N	FCS	2	\N	\N	\N	144.88186802	-37.79081851
1626440	2012-11-01	\N	421632471	\N	\N	FCS	2	\N	\N	\N	144.83558596	-37.83086983
2662959	2012-11-01	\N	420894156	\N	\N	FCS	2	\N	\N	\N	144.73612392	-38.34410083
2863670	2017-08-03	\N	420955779	\N	\N	FCS	2	\N	\N	\N	144.66593933	-37.88617430
FCS714815529	2017-07-26	\N	714815529	\N	\N	FCS	2	\N	\N	\N	144.90815748	-37.86452547
FCS717492300	2023-07-20	\N	717492300	\N	\N	FCS	2	\N	\N	\N	144.95327786	-37.81403592
4478281	2015-02-04	\N	422250333	\N	\N	FCS	2	\N	\N	\N	145.09397738	-37.83619744
4101512	2012-11-01	\N	420867943	\N	\N	FCS	2	\N	\N	\N	145.35609185	-37.97087587
4517788	2015-02-04	\N	423713875	\N	\N	FCS	2	\N	\N	\N	144.94606971	-37.79807410
4486161	2015-02-04	\N	423726275	\N	\N	FCS	2	\N	\N	\N	144.96096404	-37.80776941
424752485	2012-11-01	\N	424752485	\N	\N	FCS	2	\N	\N	\N	144.73032763	-37.90809188
PC420498308	2017-08-08	\N	420498308	\N	\N	PC	2	\N	\N	\N	143.92356699	-35.73320744
FCS425600236	2014-10-17	\N	425600236	\N	\N	FCS	2	\N	\N	\N	144.37409513	-38.16740494
423981390	2012-11-01	\N	423981390	\N	\N	FCS	2	\N	\N	\N	144.35024515	-38.13903178
2130486	2012-11-01	\N	421442494	\N	\N	FCS	2	\N	\N	\N	145.26113486	-37.99747286
PC423604983	2017-08-08	\N	423604983	\N	\N	PC	2	\N	\N	\N	145.19454436	-37.83764955
PC425773555	2025-04-29	\N	425773555	\N	\N	PC	2	\N	\N	\N	147.27789583	-36.86509348
PC424032234	2017-08-08	\N	424032234	\N	\N	PC	2	\N	\N	\N	144.77975049	-37.70672705
PC425830752	2018-05-11	\N	425830752	\N	\N	PC	2	\N	\N	\N	144.32072688	-38.12674496
PC425863020	2018-05-11	\N	425863020	\N	\N	PC	2	\N	\N	\N	145.00950251	-37.81169927
PC420546063	2017-08-08	\N	420546063	\N	\N	PC	2	\N	\N	\N	145.05641073	-37.71341093
PC425117567	2018-05-11	\N	425117567	\N	\N	PC	2	\N	\N	\N	145.25260347	-37.77743884
PC420226560	2017-08-08	\N	420226560	\N	\N	PC	2	\N	\N	\N	144.96592191	-37.69607746
424870928	2012-11-01	\N	424870928	\N	\N	FCS	2	\N	\N	\N	144.54173615	-37.69778807
420803245	2024-04-18	\N	420803245	\N	\N	FCS	2	\N	\N	\N	147.05952448	-38.10053998
424564343	2025-10-17	\N	424564343	\N	\N	FCS	2	\N	\N	\N	144.99710497	-37.83903096
420321341	2013-07-21	\N	420321341	\N	\N	FCS	2	\N	\N	\N	144.98180443	-37.80273850
2953424	2012-11-01	\N	420587553	\N	\N	FCS	2	\N	\N	\N	144.70910593	-38.33081682
PC421027630	2017-08-08	\N	421027630	\N	\N	PC	2	\N	\N	\N	144.73302645	-37.36057068
PC422117560	2017-08-08	\N	422117560	\N	\N	PC	2	\N	\N	\N	144.70934967	-38.13692633
PC421821487	2017-08-08	\N	421821487	\N	\N	PC	2	\N	\N	\N	145.04278238	-37.82657749
PC717492300	2023-11-07	\N	717492300	\N	\N	PC	2	\N	\N	\N	144.95327985	-37.81405295
PC420587553	2017-08-08	\N	420587553	\N	\N	PC	2	\N	\N	\N	144.70912730	-38.33074766
PC420256879	2017-08-08	\N	420256879	\N	\N	PC	2	\N	\N	\N	144.99776642	-37.80114362
PC420314530	2023-11-07	\N	420314530	\N	\N	PC	2	\N	\N	\N	145.15254784	-37.80160720
PC715368361	2023-11-07	\N	715368361	\N	\N	PC	2	\N	\N	\N	144.94347307	-37.79825835
PC718002861	2025-07-31	\N	718002861	\N	\N	PC	2	\N	\N	\N	144.94089596	-37.53108996
PAPS425179311	2012-11-01	\N	425179311	\N	\N	PAPS	2	\N	\N	\N	143.80901847	-36.42267564
PC421124750	2017-08-08	\N	421124750	\N	\N	PC	2	\N	\N	\N	146.01840013	-36.00797001
PC423799056	2018-05-11	\N	423799056	\N	\N	PC	2	\N	\N	\N	146.54446789	-38.18179156
PC423880954	2017-08-08	\N	423880954	\N	\N	PC	2	\N	\N	\N	144.96563154	-37.81759423
PC412671558	2017-08-08	\N	412671558	\N	\N	PC	2	\N	\N	\N	145.46411527	-37.81358138
PC424684659	2023-11-07	\N	424684659	\N	\N	PC	2	\N	\N	\N	144.41881454	-37.67369860
PC421861654	2018-05-11	\N	421861654	\N	\N	PC	2	\N	\N	\N	144.66248689	-37.89766288
PC421079146	2018-05-11	\N	421079146	\N	\N	PC	2	\N	\N	\N	146.89487647	-36.12629041
3760466	2012-11-01	\N	421034752	\N	\N	FCS	2	\N	\N	\N	141.59728856	-38.36005649
424713448	2012-11-01	\N	424713448	\N	\N	FCS	2	\N	\N	\N	144.75305218	-37.89898736
4511735	2024-07-15	\N	423741522	\N	\N	FCS	2	\N	\N	\N	144.96770029	-37.81131701
3718225	2012-11-01	\N	422126020	\N	\N	FCS	2	\N	\N	\N	144.74124003	-37.72359677
2497217	2023-07-26	\N	420332142	\N	\N	FCS	2	\N	\N	\N	145.16746051	-37.97385510
411999327	2012-11-01	\N	411999327	\N	\N	FCS	2	\N	\N	\N	145.06609708	-37.98681620
FCS714809494	2023-07-26	\N	714809494	\N	\N	FCS	2	\N	\N	\N	144.97370122	-37.83579341
2593114	2012-11-01	\N	419982912	\N	\N	FCS	2	\N	\N	\N	144.92440088	-38.37319584
FCS420823345	2025-10-23	\N	420823345	\N	\N	FCS	2	\N	\N	\N	145.10391638	-37.86815522
FCS718002861	2025-07-15	\N	718002861	\N	\N	FCS	2	\N	\N	\N	144.94090814	-37.53100433
4499418	2025-04-24	\N	423742341	\N	\N	FCS	2	\N	\N	\N	144.95252330	-37.82267981
2062139	2012-11-01	\N	420200380	\N	\N	FCS	2	\N	\N	\N	145.13202287	-38.13116385
2012438	2012-11-01	\N	420868495	\N	\N	FCS	2	\N	\N	\N	145.16041291	-37.71607385
412379387	2012-11-01	\N	412379387	\N	\N	FCS	2	\N	\N	\N	145.24129037	-37.93776924
425002879	2012-11-01	\N	425002879	\N	\N	FCS	2	\N	\N	\N	144.95340078	-37.48082776
421563343	2012-11-01	\N	421563343	\N	\N	FCS	2	\N	\N	\N	145.01737789	-37.72591659
FCS421255051	2025-04-23	\N	421255051	\N	\N	FCS	2	\N	\N	\N	144.91933848	-37.68425868
FCS425129914	2021-07-27	\N	425129914	\N	\N	PAPS	2	\N	\N	\N	145.14787116	-38.12221616
FCS717751011	2024-07-14	\N	717751011	\N	\N	FCS	2	\N	\N	\N	144.95444368	-37.82154241
FCS425363708	2013-07-16	\N	425363708	\N	\N	FCS	2	\N	\N	\N	145.04077496	-37.87483964
4022379	2012-11-01	\N	422047366	\N	\N	FCS	2	\N	\N	\N	145.09553392	-37.76869185
423880954	2023-07-26	\N	423880954	\N	\N	FCS	2	\N	\N	\N	144.96576928	-37.81756618
424761278	2012-11-01	\N	424761278	\N	\N	FCS	2	\N	\N	\N	145.18359652	-38.08837093
420314530	2012-11-01	\N	420314530	\N	\N	FCS	2	\N	\N	\N	145.15254066	-37.80161910
424965089	2012-11-01	\N	424965089	\N	\N	FCS	2	\N	\N	\N	145.04324942	-38.24811862
420723393	2025-10-24	\N	420723393	\N	\N	FCS	2	\N	\N	\N	145.10002570	-37.93092621
3672479	2024-01-17	\N	421992777	\N	\N	FCS	2	\N	\N	\N	145.59827028	-38.59345478
FCS425362339	2013-07-16	\N	425362339	\N	\N	FCS	2	\N	\N	\N	144.95991751	-37.82639623
FCS717220444	2022-07-21	\N	717220444	\N	\N	FCS	2	\N	\N	\N	144.78943090	-37.79154382
424350293	2024-01-17	\N	424350293	\N	\N	FCS	2	\N	\N	\N	146.15804669	-38.21939215
FCS425600398	2014-10-17	\N	425600398	\N	\N	FCS	2	\N	\N	\N	144.95151565	-37.81094876
FCS425608760	2014-10-17	\N	425608760	\N	\N	FCS	2	\N	\N	\N	144.96208951	-37.82567255
3361278	2012-11-01	\N	420246858	\N	\N	FCS	2	\N	\N	\N	145.14758191	-37.78618585
421389843	2012-11-01	\N	421389843	\N	\N	FCS	2	\N	\N	\N	145.02909470	-37.85982673
FCS715149485	2018-05-07	\N	715149485	\N	\N	FCS	2	\N	\N	\N	144.93801394	-37.81532063
FCS425117567	2012-11-01	\N	425117567	\N	\N	FCS	2	\N	\N	\N	145.25265085	-37.77740320
419788726	2012-11-01	\N	419788726	\N	\N	FCS	2	\N	\N	\N	144.34360216	-38.08284840
FCS714924203	2022-07-25	\N	714924203	\N	\N	PAPS	2	\N	\N	\N	144.42534506	-38.03023298
FCS424880807	2013-07-21	\N	424880807	\N	\N	FCS	2	\N	\N	\N	144.99740670	-37.83684594
424831860	2017-08-03	\N	424831860	\N	\N	FCS	2	\N	\N	\N	144.95798148	-37.81774134
422117560	2012-11-01	\N	422117560	\N	\N	FCS	2	\N	\N	\N	144.70921964	-38.13695688
422166370	2023-07-22	\N	422166370	\N	\N	FCS	2	\N	\N	\N	145.11100077	-37.84251506
FCS715624039	2026-01-16	\N	715624039	\N	\N	FCS	2	\N	\N	\N	143.78368987	-37.54967619
FCS715298169	2018-10-28	\N	715298169	\N	\N	FCS	2	\N	\N	\N	145.04487647	-37.73923500
421476681	2017-01-06	\N	421476681	\N	\N	FCS	2	\N	\N	\N	145.03583624	-37.94511464
4495335	2023-10-30	\N	423717308	\N	\N	FCS	2	\N	\N	\N	144.94629899	-37.79682005
FCS714912319	2017-10-17	\N	714912319	\N	\N	FCS	2	\N	\N	\N	144.97862647	-37.84341251
FCS425795800	2015-08-06	\N	425795800	\N	\N	FCS	2	\N	\N	\N	146.44446396	-37.14516436
412233908	2012-11-01	\N	412233908	\N	\N	FCS	2	\N	\N	\N	144.92642616	-37.73040617
4336541	2012-11-01	\N	423539011	\N	\N	FCS	2	\N	\N	\N	144.96682147	-37.79425274
424001182	2015-02-04	\N	424001182	\N	\N	FCS	2	\N	\N	\N	144.97111975	-37.83180171
FCS425863020	2016-01-14	\N	425863020	\N	\N	FCS	2	\N	\N	\N	145.00952113	-37.81159295
FCS425908900	2016-04-22	\N	425908900	\N	\N	FCS	2	\N	\N	\N	144.99333331	-37.71063418
FCS422222039	2025-10-17	\N	422222039	\N	\N	FCS	2	\N	\N	\N	144.99332219	-37.89518376
FCS425573227	2014-10-25	\N	425573227	\N	\N	FCS	2	\N	\N	\N	145.09232289	-37.78634830
419773744	2012-11-01	\N	419773744	\N	\N	FCS	2	\N	\N	\N	145.06369376	-37.89712682
420891722	2012-11-01	\N	420891722	\N	\N	FCS	2	\N	\N	\N	144.97527015	-37.77439431
FCS714824238	2017-07-26	\N	714824238	\N	\N	FCS	2	\N	\N	\N	144.97862647	-37.84341251
FCS714824244	2017-07-26	\N	714824244	\N	\N	FCS	2	\N	\N	\N	144.95513882	-37.80319690
3454035	2012-11-01	\N	419761603	\N	\N	FCS	2	\N	\N	\N	145.03824291	-37.93518384
424439560	2012-11-01	\N	424439560	\N	\N	FCS	2	\N	\N	\N	142.14417227	-34.23335670
\.

-- raw_gnaf_202602.address_default_geocode: 451 rows
\copy raw_gnaf_202602.address_default_geocode FROM stdin
1942485	2019-08-05	\N	GAVIC423917985	PAPS	144.93953230	-37.84128419
3679204	2012-11-01	\N	GAVIC421107468	FCS	145.01610791	-37.93198184
3954081	2012-11-01	\N	GAVIC419920752	FCS	145.01488403	-37.74821083
7635068	2023-11-07	\N	GAVIC425167658	FCS	144.96159702	-37.81752885
3022177901	2023-11-07	\N	GAVIC721366499	FCS	145.11682777	-37.81786505
2416627	2012-11-01	\N	GAVIC421548655	FCS	142.85439001	-37.15033645
3012883761	2018-11-06	\N	GAVIC719925941	FCS	145.00724733	-37.90494907
3007198176	2016-08-07	\N	GAVIC718991138	FCS	144.96183795	-37.80563395
3964774	2024-04-30	\N	GAVIC424750944	FCS	144.23386480	-36.77892429
1767021	2025-10-30	\N	GAVIC420583086	FCS	145.10002570	-37.93092621
3084067	2018-11-06	\N	GAVIC423974946	PAPS	144.53814538	-36.88749014
3953334	2013-08-06	\N	GAVIC421694057	FCS	144.93719722	-37.78690307
3305084	2012-11-01	\N	GAVIC419661586	FCS	144.34360216	-38.08284840
7638720	2017-08-08	\N	GAVIC425169775	FCS	144.58434507	-37.49016711
2877957	2012-11-01	\N	GAVIC420701723	FCS	144.96913994	-37.75350484
2899648	2012-11-01	\N	GAVIC421146125	FCS	144.87903596	-37.69411483
1329010	2012-11-01	\N	GAVIC424795446	FCS	144.99740670	-37.83684594
3010395602	2018-05-11	\N	GAVIC719754089	FCS	144.93801394	-37.81532063
4533916	2024-04-30	\N	GAVIC423402710	STL	146.34728373	-38.30448492
3007193261	2016-08-07	\N	GAVIC719042751	FCS	144.96847178	-37.80918104
3018195225	2020-02-02	\N	GAVIC720296037	FCS	145.12558764	-38.04202953
7848460	2024-01-29	\N	GAVIC425367645	FCS	144.93277234	-37.29327587
3012872884	2018-11-06	\N	GAVIC719913128	FCS	145.04487647	-37.73923500
2089544	2012-11-01	\N	GAVIC419688276	FCS	145.08300690	-38.00120185
4555230	2023-11-07	\N	GAVIC412670644	STL	146.38823671	-36.43952844
4525477	2024-04-30	\N	GAVIC424926818	STL	144.41435402	-37.32195322
9962759	2016-05-03	\N	GAVIC425821887	FCS	144.91169648	-37.70846694
3008962725	2023-05-07	\N	GAVIC719523562	FCS	144.96073354	-37.80833027
3008894634	2017-08-08	\N	GAVIC719439819	PAPS	147.03927940	-36.47912795
1523397	2012-11-01	\N	GAVIC424754823	PAPS	145.16888267	-36.75186307
2301090	2012-11-01	\N	GAVIC420418242	FCS	145.05646293	-37.71338684
2242126	2012-11-01	\N	GAVIC424581128	FCS	145.27714110	-37.88333706
1757179	2012-11-01	\N	GAVIC425085888	FCS	145.49596135	-38.05568418
2009618	2012-11-01	\N	GAVIC419682437	PAPS	143.79257358	-37.83920614
4142193	2012-11-01	\N	GAVIC412378116	FCS	144.97975428	-37.86242684
3471021	2012-11-01	\N	GAVIC421304891	FCS	145.21388388	-37.96374586
3020840600	2022-02-09	\N	GAVIC720913095	PAPS	143.97236401	-38.53454590
2146273	2012-11-01	\N	GAVIC419854308	FCS	144.76053791	-38.36497883
3022171874	2023-11-07	\N	GAVIC721374676	FCS	145.04121525	-37.83841614
1280648	2015-08-07	\N	GAVIC411968423	PAPS	145.15540573	-36.78140824
4320064	2015-02-04	\N	GAVIC422161681	FCS	145.06104233	-37.82256113
9890574	2015-11-05	\N	GAVIC425742442	FCS	144.32061091	-38.12673070
7790022	2013-11-05	\N	GAVIC425309480	FCS	145.02356726	-37.72730375
3399503	2013-01-25	\N	GAVIC424285382	FCS	144.93704183	-37.75970427
4222217	2012-11-01	\N	GAVIC422086500	FCS	144.82657597	-37.75222183
4021159	2019-10-31	\N	GAVIC421708673	FCS	144.80946570	-37.79205213
4307638	2012-11-01	\N	GAVIC420886416	FCS	144.73283607	-37.36058091
2911832	2019-02-05	\N	GAVIC421739766	FCS	145.01962355	-37.72071175
2518136	2019-05-06	\N	GAVIC422138212	FCS	144.98428438	-37.75514597
4064382	2012-11-01	\N	GAVIC420051005	FCS	145.13202287	-38.13116385
3892353	2012-11-01	\N	GAVIC419679289	FCS	145.25627688	-37.89960386
7841446	2014-02-01	\N	GAVIC425367514	FCS	144.97922971	-37.85228554
4161315	2015-02-04	\N	GAVIC422119571	FCS	145.09397738	-37.83619744
2954250	2012-11-01	\N	GAVIC420118258	FCS	145.12195891	-37.84329385
2589151	2015-02-04	\N	GAVIC423910455	FCS	144.97111975	-37.83180171
3848345	2012-11-01	\N	GAVIC424589454	FCS	144.76763784	-37.90628083
3021251859	2022-08-09	\N	GAVIC721038984	PAPS	144.64116180	-38.11139145
3018188586	2020-02-02	\N	GAVIC720284643	FCS	144.34093461	-38.20607026
2326599	2012-11-01	\N	GAVIC423716042	FCS	143.85708571	-37.55606340
3110036	2023-11-07	\N	GAVIC423490030	FCS	144.97687491	-37.83862075
3021921675	2023-08-06	\N	GAVIC721290639	FCS	144.95327786	-37.81403592
4430806	2025-04-30	\N	GAVIC423648868	FCS	144.95252330	-37.82267981
3874093	2012-11-01	\N	GAVIC420533207	FCS	145.13164391	-37.77534685
3018403030	2023-08-06	\N	GAVIC720520900	FCS	144.95248254	-37.81421733
7787089	2024-01-29	\N	GAVIC425311495	FCS	144.97378966	-37.41798163
4354509	2012-11-01	\N	GAVIC420178764	FCS	145.15254066	-37.80161910
9885795	2015-11-05	\N	GAVIC425741622	FCS	144.95408699	-37.81543898
4504431	2024-04-30	\N	GAVIC423402509	STL	144.78260095	-36.95556660
4502959	2012-11-01	\N	GAVIC424879721	FCS	145.04324942	-38.24811862
4073170	2012-11-01	\N	GAVIC424785567	FCS	144.54173615	-37.69778807
4352220	2012-11-01	\N	GAVIC420538231	FCS	144.71298395	-38.18351371
2451561	2012-11-01	\N	GAVIC419754099	FCS	145.05301034	-36.31143352
2529464	2012-11-01	\N	GAVIC423943682	FCS	144.77974789	-37.70673193
4056244	2024-10-30	\N	GAVIC424676885	FCS	147.06264578	-38.10435588
1827695	2012-11-01	\N	GAVIC423509973	FCS	145.19454599	-37.83764050
3022250783	2024-04-30	\N	GAVIC721504260	FCS	145.03897191	-37.95146084
3792530	2012-11-01	\N	GAVIC423748775	FCS	144.73451975	-37.71861448
1497082	2024-04-30	\N	GAVIC420674743	FCS	147.05952448	-38.10053998
3827612	2012-11-01	\N	GAVIC411087566	FCS	145.01510717	-37.89180933
8410883	2014-11-04	\N	GAVIC425512108	FCS	144.95151565	-37.81094876
3166253	2012-11-01	\N	GAVIC420648830	PAPS	144.69508343	-37.46671163
2918125	2012-11-01	\N	GAVIC420870124	FCS	143.26832660	-35.47597811
3012876805	2018-11-06	\N	GAVIC719921421	FCS	144.97599334	-37.83867611
1328856	2016-05-03	\N	GAVIC422024006	FCS	145.03415549	-37.85515594
2026281	2012-11-01	\N	GAVIC424282372	FCS	144.61177349	-37.88539910
3022905658	2026-01-29	\N	GAVIC721915145	FCS	144.00019719	-38.23372644
1909138	2012-11-01	\N	GAVIC421481149	FCS	145.01737789	-37.72591659
1491716	2012-11-01	\N	GAVIC420108368	FCS	145.14758191	-37.78618585
3008971176	2017-10-28	\N	GAVIC719528632	FCS	144.90398265	-37.54162868
4467641	2023-05-07	\N	GAVIC424895492	STL	144.13024980	-36.72816437
1811023	2015-02-04	\N	GAVIC420323810	FCS	145.05291414	-37.85679108
4314460	2015-02-04	\N	GAVIC423910551	FCS	144.97111975	-37.83180171
3775930	2012-11-01	\N	GAVIC421042152	FCS	145.18953684	-38.31542186
7755154	2013-08-06	\N	GAVIC425277959	FCS	144.95707987	-37.82686811
3192368	2012-11-01	\N	GAVIC419640745	FCS	145.06666090	-37.95367685
1852986	2012-11-01	\N	GAVIC425013948	FCS	145.04077496	-37.87483964
3018413510	2020-11-06	\N	GAVIC720523963	FCS	145.42716137	-38.06293073
9943322	2016-05-03	\N	GAVIC425820590	FCS	144.99333331	-37.71063418
3022210974	2024-01-29	\N	GAVIC721425406	FCS	144.36216360	-38.01736342
4501614	2022-05-09	\N	GAVIC423991217	STL	144.18152888	-36.98874826
3022310703	2024-07-30	\N	GAVIC721549117	FCS	144.95444368	-37.82154241
2400201	2019-10-31	\N	GAVIC420749468	FCS	144.91246400	-38.37942785
3021794024	2023-02-03	\N	GAVIC721162609	FCS	145.23153380	-37.91936213
3907254	2023-11-07	\N	GAVIC422289520	FCS	146.56532248	-38.19945322
1771980	2012-11-01	\N	GAVIC421059470	FCS	145.21695789	-37.86998686
3935200	2012-11-01	\N	GAVIC420100287	FCS	145.13832838	-37.88006953
9918411	2016-01-22	\N	GAVIC425774710	FCS	145.00952113	-37.81159295
3976748	2024-04-30	\N	GAVIC419660068	FCS	144.27939626	-36.74546263
4282291	2016-01-22	\N	GAVIC425084593	FCS	144.63756583	-37.54800545
3022903987	2026-01-29	\N	GAVIC721914294	FCS	144.58409748	-37.89035611
3877998	2015-02-04	\N	GAVIC412739960	FCS	144.98115145	-37.85282693
1756792	2014-11-04	\N	GAVIC419676903	FCS	145.12807186	-37.91164390
1350617	2012-11-01	\N	GAVIC421219047	FCS	145.09827891	-37.88350685
1524782	2012-11-01	\N	GAVIC412089403	FCS	144.92642616	-37.73040617
3009059808	2023-11-07	\N	GAVIC719608433	FCS	144.97430770	-37.83877571
7744116	2013-08-06	\N	GAVIC425274073	FCS	144.95991751	-37.82639623
3021640549	2022-11-15	\N	GAVIC721089117	PAPS	144.51664265	-38.26980689
9831954	2023-05-07	\N	GAVIC425703440	FCS	145.13471236	-38.03119682
3007404911	2019-02-05	\N	GAVIC719244724	FCS	145.27250387	-38.07502010
1802293	2012-11-01	\N	GAVIC419908615	FCS	144.92478696	-37.64974783
2212732	2012-11-01	\N	GAVIC423705816	FCS	146.54473742	-38.18180381
3316147	2012-11-01	\N	GAVIC419625837	FCS	145.03824291	-37.93518384
2196407	2012-11-01	\N	GAVIC411670057	FCS	145.02782593	-37.80287784
3018334028	2020-08-05	\N	GAVIC720458378	FCS	144.58284186	-37.86395465
1768817	2016-08-07	\N	GAVIC419912498	FCS	144.77224395	-37.86065106
7753495	2014-11-04	\N	GAVIC425272843	FCS	145.14830823	-37.71905657
4519111	2022-02-09	\N	GAVIC423399692	STL	145.53633083	-37.64931699
3721486	2012-11-01	\N	GAVIC420615360	FCS	144.99287793	-37.82675684
4511907	2017-10-28	\N	GAVIC423409956	STL	146.44353967	-38.23947175
2492037	2015-02-04	\N	GAVIC423232139	FCS	144.97620603	-37.84404234
3022910711	2026-01-29	\N	GAVIC721917030	FCS	144.95946292	-37.82615118
2345043	2012-11-01	\N	GAVIC420119751	FCS	144.99771793	-37.80112584
3022795274	2025-10-30	\N	GAVIC721849526	FCS	144.94614424	-37.81319205
3014264417	2025-04-30	\N	GAVIC720052842	FCS	144.96356449	-37.82421909
3723057	2012-11-01	\N	GAVIC423436506	FCS	144.75166398	-37.72164337
3175319	2012-11-01	\N	GAVIC421670970	FCS	145.04291892	-37.82659684
2037175	2021-08-14	\N	GAVIC420796526	FCS	145.18141778	-37.95878525
2324728	2024-01-29	\N	GAVIC420061429	FCS	146.86124471	-36.13640441
7810122	2021-04-28	\N	GAVIC425325004	STL	144.28402085	-36.70843370
3094842	2012-11-01	\N	GAVIC421049989	FCS	144.92848295	-37.75882583
3015248	2024-04-30	\N	GAVIC421885685	FCS	147.59748794	-37.82359215
3145934	2012-11-01	\N	GAVIC420987849	FCS	146.01850091	-36.00805913
3748776	2012-11-01	\N	GAVIC424918055	FCS	144.97902922	-37.84701078
1614758	2023-08-06	\N	GAVIC423789992	FCS	144.96576928	-37.81756618
4081730	2012-11-01	\N	GAVIC420637602	FCS	145.27655085	-38.07971786
4548293	2024-01-29	\N	GAVIC423397050	STL	145.37837938	-37.63549404
3927821	2012-11-01	\N	GAVIC419987098	FCS	142.01663921	-37.73995574
3506530	2023-11-07	\N	GAVIC424765376	FCS	144.97895103	-37.84679697
3008869899	2017-08-08	\N	GAVIC719439210	FCS	144.97862647	-37.84341251
4433059	2012-11-01	\N	GAVIC421983130	FCS	144.69173458	-37.84058603
4207637	2012-11-01	\N	GAVIC421924109	FCS	145.15823591	-37.75359385
1749550	2012-11-01	\N	GAVIC414839745	FCS	144.77300509	-38.37210524
2471919	2012-11-01	\N	GAVIC424354717	FCS	144.76417232	-37.77770331
3277828	2015-02-04	\N	GAVIC421856523	FCS	144.94564894	-37.76406510
3022448385	2025-01-28	\N	GAVIC721711659	FCS	145.22167130	-37.91920783
7807914	2013-11-05	\N	GAVIC425314633	FCS	145.14957729	-37.77324143
3001875	2023-05-07	\N	GAVIC423750017	FCS	144.96247736	-37.82152105
2947867	2023-08-06	\N	GAVIC422035533	FCS	145.11100077	-37.84251506
2421293	2012-11-01	\N	GAVIC421279891	FCS	145.41878792	-36.36611726
4039527	2012-11-01	\N	GAVIC420987808	FCS	145.09782991	-37.87256485
3022714116	2025-07-31	\N	GAVIC721800565	FCS	144.94090814	-37.53100433
3389696	2012-11-01	\N	GAVIC424265017	PAPS	146.01260217	-37.06902526
8498648	2015-04-22	\N	GAVIC425613744	FCS	145.30070638	-38.11927653
3727046	2024-01-29	\N	GAVIC421863134	FCS	145.59827028	-38.59345478
4499368	2015-04-22	\N	GAVIC423390367	STL	145.01848224	-38.36909570
3014214886	2019-02-05	\N	GAVIC719985042	FCS	144.96191382	-37.80632196
4015425	2012-11-01	\N	GAVIC420591242	FCS	144.93233076	-37.68788889
3399743	2012-11-01	\N	GAVIC424263895	FCS	145.02790178	-37.71415954
3989247	2012-11-01	\N	GAVIC420656885	FCS	145.11537391	-37.80968285
2458460	2012-11-01	\N	GAVIC424906559	FCS	145.06543874	-37.98102750
3008894617	2017-08-08	\N	GAVIC719439216	FCS	144.95513882	-37.80319690
3018321427	2020-11-06	\N	GAVIC720475626	FCS	144.32161328	-38.30843736
4263248	2023-05-07	\N	GAVIC423837828	FCS	144.97940721	-37.84556706
3415979	2012-11-01	\N	GAVIC420964291	FCS	144.99138092	-37.91060984
3022908220	2026-01-29	\N	GAVIC721916596	FCS	146.56651988	-38.19143803
1494115	2012-11-01	\N	GAVIC420881388	FCS	145.00201593	-37.85654984
8343277	2014-11-04	\N	GAVIC425484937	FCS	145.09232289	-37.78634830
3020846420	2023-08-06	\N	GAVIC720919065	FCS	144.93382902	-37.68866198
3010383463	2018-05-11	\N	GAVIC719745362	FCS	144.98435522	-37.70188264
1432098	2024-01-29	\N	GAVIC422294300	FCS	146.84235497	-36.12677250
3243965	2012-11-01	\N	GAVIC420841495	FCS	144.49026312	-38.26645855
2731426	2012-11-01	\N	GAVIC421448648	FCS	145.05990293	-37.73417184
2753389	2012-11-01	\N	GAVIC421262022	FCS	145.02909470	-37.85982673
4382831	2012-11-01	\N	GAVIC424283355	FCS	145.03850284	-37.95885229
3697582	2012-11-01	\N	GAVIC420980761	FCS	145.17622189	-37.92766985
4301100	2025-01-28	\N	GAVIC423471646	FCS	144.97307567	-37.76496434
2200663	2023-05-07	\N	GAVIC419571030	FCS	144.94457917	-37.80536765
3012878830	2023-05-07	\N	GAVIC719915818	FCS	144.96051896	-37.80786078
3018416309	2023-08-06	\N	GAVIC720518002	FCS	144.95351739	-37.82127148
1846310	2015-02-04	\N	GAVIC424424026	FCS	145.04748732	-37.87604151
3908095	2012-11-01	\N	GAVIC420215992	FCS	144.73374592	-38.33777483
4558409	2023-11-07	\N	GAVIC412667511	STL	145.15906164	-38.02758237
1407687	2012-11-01	\N	GAVIC424628057	FCS	144.75305218	-37.89898736
3284482	2020-08-05	\N	GAVIC420502224	FCS	145.47806519	-38.07937173
3021247587	2022-08-09	\N	GAVIC721025623	FCS	144.71366136	-37.69387698
3014214620	2019-02-05	\N	GAVIC720000915	FCS	144.97599334	-37.83867611
1359809	2025-10-30	\N	GAVIC420015455	FCS	144.96881327	-37.81280333
3065771	2023-11-07	\N	GAVIC425084495	FCS	144.99673413	-37.78304333
8402431	2017-08-08	\N	GAVIC425530619	PAPS	143.49085693	-35.30658547
4410072	2012-11-01	\N	GAVIC425083938	FCS	144.91613447	-37.72201345
1799944	2012-11-01	\N	GAVIC420099787	FCS	145.12613163	-38.05617128
3018411559	2020-11-06	\N	GAVIC720543934	STL	143.88496651	-37.69871999
3012886247	2018-11-06	\N	GAVIC719919340	FCS	146.28813510	-36.33965077
3201241	2012-11-01	\N	GAVIC421832935	FCS	144.99292794	-37.74126784
8505088	2015-08-07	\N	GAVIC425622336	FCS	144.97100474	-37.79308649
3018323902	2020-08-05	\N	GAVIC720443226	FCS	141.40787780	-37.32063544
1968860	2012-11-01	\N	GAVIC421943442	FCS	145.08213818	-37.71045753
2648841	2012-11-01	\N	GAVIC420429255	FCS	145.76596901	-38.11003101
2567392	2012-11-01	\N	GAVIC421753831	FCS	144.92547596	-37.65794683
3008968538	2023-05-07	\N	GAVIC719524538	FCS	144.96073354	-37.80833027
2280324	2012-11-01	\N	GAVIC420751807	FCS	144.73612392	-38.34410083
3814334	2012-11-01	\N	GAVIC419868312	FCS	145.09049090	-37.98621985
2462723	2012-11-01	\N	GAVIC419568757	FCS	145.27522388	-37.86501586
3022460077	2025-01-28	\N	GAVIC721706405	FCS	145.00483643	-37.63683577
3010392009	2018-05-11	\N	GAVIC719754869	FCS	145.08095040	-37.95347890
7754464	2013-08-06	\N	GAVIC425272501	FCS	144.99807193	-37.61384918
2012331	2012-11-01	\N	GAVIC424272695	FCS	145.28054568	-37.79951261
2069034	2012-11-01	\N	GAVIC419837839	FCS	144.92440088	-38.37319584
1603092	2012-11-01	\N	GAVIC421741216	FCS	142.05971691	-34.16670897
3018570804	2021-04-28	\N	GAVIC720693565	FCS	144.87308230	-37.64068727
2026702	2012-11-01	\N	GAVIC421479094	FCS	144.54439636	-38.26942449
3244073	2012-11-01	\N	GAVIC420622820	FCS	146.90513845	-36.13174471
3412232	2024-07-30	\N	GAVIC420355278	FCS	143.92348651	-35.73322369
1634755	2012-11-01	\N	GAVIC421499309	FCS	145.05733918	-37.76930735
3014217202	2019-02-05	\N	GAVIC719987520	FCS	144.96065746	-37.81150292
3164892	2012-11-01	\N	GAVIC420510289	FCS	144.76059798	-37.76937482
2393965	2012-11-01	\N	GAVIC421826494	FCS	145.27006588	-37.84593386
3014207905	2023-11-07	\N	GAVIC719979296	FCS	144.95816137	-37.82714046
3662619	2012-11-01	\N	GAVIC411852098	FCS	145.06609708	-37.98681620
2620840	2020-11-06	\N	GAVIC412527332	PAPS	145.22971282	-37.85445861
2540303	2021-04-28	\N	GAVIC424599194	FCS	144.41881532	-37.67368602
3352848	2012-11-01	\N	GAVIC420229782	FCS	145.05269194	-37.64075884
3007195894	2016-08-07	\N	GAVIC718988205	FCS	143.80032960	-37.58030430
9807282	2025-04-30	\N	GAVIC425685265	FCS	147.27784059	-36.86512101
2004962	2024-01-29	\N	GAVIC424626663	FCS	145.40725152	-36.35998165
3007403525	2017-02-01	\N	GAVIC719210454	FCS	145.42060832	-38.07634274
1760852	2024-07-30	\N	GAVIC421565163	FCS	144.96770029	-37.81131701
4550572	2018-11-06	\N	GAVIC412681818	STL	146.50667162	-38.19938477
3022248957	2024-10-30	\N	GAVIC721479211	PAPS	145.08578837	-37.64786543
3020603416	2021-08-14	\N	GAVIC720746274	FCS	144.55463388	-36.01112965
3153685	2012-11-01	\N	GAVIC424633603	FCS	145.23009869	-37.80532324
4281267	2023-05-07	\N	GAVIC423639265	FCS	144.95715084	-37.81689612
4023942	2024-01-29	\N	GAVIC420049828	FCS	145.78890327	-38.67927285
1318664	2012-11-01	\N	GAVIC422409795	FCS	146.85930216	-36.11670451
2699998	2025-01-28	\N	GAVIC419724052	FCS	144.88899581	-37.79520947
1579227	2012-11-01	\N	GAVIC420556912	FCS	145.05021891	-37.90914884
3015665564	2026-01-29	\N	GAVIC720238978	FCS	143.78368987	-37.54967619
3117264	2012-11-01	\N	GAVIC423890759	FCS	144.35024515	-38.13903178
2466548	2017-08-08	\N	GAVIC420812068	FCS	144.66593933	-37.88617430
3022450510	2025-01-28	\N	GAVIC721705028	FCS	144.97587008	-37.84306552
3233180	2012-11-01	\N	GAVIC420647207	FCS	144.45844070	-38.18678995
9897331	2015-11-05	\N	GAVIC425730031	FCS	145.04088787	-37.96212191
8409288	2014-11-04	\N	GAVIC425511946	FCS	144.37409513	-38.16740494
2343966	2013-05-01	\N	GAVIC424796248	FCS	144.95917280	-37.81715463
3577024	2015-04-22	\N	GAVIC419701922	FCS	142.51798353	-38.37631556
3018396577	2023-08-06	\N	GAVIC720512281	FCS	144.95248254	-37.81421733
4376585	2020-08-05	\N	GAVIC411685451	PAPS	145.30974852	-37.80704431
1461398	2012-11-01	\N	GAVIC421862656	FCS	145.05494793	-37.74198384
9892304	2015-11-05	\N	GAVIC425734206	FCS	144.93938448	-37.77969041
1972166	2012-11-01	\N	GAVIC419827679	FCS	145.00504092	-37.86659484
4561789	2012-11-01	\N	GAVIC412676977	STL	142.03645944	-34.24245637
3862911	2017-08-08	\N	GAVIC424746499	FCS	144.95798148	-37.81774134
1921686	2015-02-04	\N	GAVIC423826364	FCS	144.96565347	-37.81775091
4451099	2023-05-07	\N	GAVIC423837989	FCS	144.97980325	-37.84670035
9890080	2024-04-30	\N	GAVIC425732776	FCS	145.93627347	-38.47219566
4112037	2012-11-01	\N	GAVIC420298014	FCS	145.04535392	-37.82989084
3018342887	2024-04-30	\N	GAVIC720474883	STL	144.77072314	-36.76209168
2232010	2017-02-01	\N	GAVIC421362480	FCS	145.03583624	-37.94511464
9819219	2015-08-07	\N	GAVIC425707510	FCS	146.44446396	-37.14516436
2622272	2012-11-01	\N	GAVIC422034832	PAPS	147.15681829	-36.74692880
3008974495	2017-10-28	\N	GAVIC719527287	FCS	144.97862647	-37.84341251
3008872646	2017-08-08	\N	GAVIC719430501	FCS	144.90815748	-37.86452547
8425534	2021-02-04	\N	GAVIC425539243	PAPS	144.43016290	-37.68646938
3014366549	2019-08-05	\N	GAVIC720144307	FCS	144.90259812	-37.79888118
3053911	2012-11-01	\N	GAVIC412549753	FCS	145.46469105	-37.81416067
2249640	2012-11-01	\N	GAVIC424776713	FCS	147.63783836	-37.82535527
3984318	2024-04-30	\N	GAVIC422273680	FCS	144.33627905	-36.79372982
7852117	2020-02-02	\N	GAVIC425368628	STL	144.28908464	-36.71300512
3014269761	2019-05-06	\N	GAVIC720058933	FCS	145.00241335	-37.74644453
1536363	2021-08-14	\N	GAVIC425044566	PAPS	145.14787116	-38.12221616
8354569	2020-11-06	\N	GAVIC425489617	FCS	145.13427691	-38.02967451
4077066	2020-11-06	\N	GAVIC421307669	FCS	145.04523577	-37.85376115
1482112	2012-11-01	\N	GAVIC420206310	FCS	144.63738498	-37.90765382
4020854	2024-01-29	\N	GAVIC422277019	FCS	143.55789826	-38.63253256
3021267988	2022-08-09	\N	GAVIC721019485	FCS	144.78943090	-37.79154382
1261946	2012-11-01	\N	GAVIC425032219	FCS	145.25265085	-37.77740320
1261750	2012-11-01	\N	GAVIC413384563	FCS	145.08375985	-37.82413270
2894298	2012-11-01	\N	GAVIC425089969	FCS	145.48748069	-38.07282307
3692736	2012-11-01	\N	GAVIC421986723	FCS	144.70921964	-38.13695688
2212707	2024-01-29	\N	GAVIC419598648	FCS	144.76699564	-37.86095143
3532324	2012-11-01	\N	GAVIC421787496	FCS	145.99080275	-36.55703206
2391633	2012-11-01	\N	GAVIC419898327	FCS	145.01379491	-37.96762884
2984018	2025-10-30	\N	GAVIC422091233	FCS	144.99332219	-37.89518376
2340029	2012-11-01	\N	GAVIC419623906	FCS	144.96910952	-38.33626879
4076861	2026-01-29	\N	GAVIC411809712	FCS	144.97568145	-37.84253725
2838021	2023-11-07	\N	GAVIC424732111	FCS	144.88186802	-37.79081851
9803699	2022-05-09	\N	GAVIC425685032	PAPS	144.96722002	-37.83622425
3800966	2023-11-07	\N	GAVIC419723191	FCS	146.42878989	-38.21986689
3014210092	2019-02-05	\N	GAVIC719983320	FCS	144.94365758	-37.79846579
4332199	2022-11-15	\N	GAVIC421736429	FCS	145.00086460	-37.90359279
1517644	2012-11-01	\N	GAVIC424490619	FCS	144.92224944	-38.37560022
7852268	2023-05-07	\N	GAVIC425369445	STL	144.47979695	-36.31232749
3352717	2012-11-01	\N	GAVIC420734999	FCS	145.16041291	-37.71607385
3010388421	2018-05-11	\N	GAVIC719764462	FCS	144.93801394	-37.81532063
3022460766	2025-01-28	\N	GAVIC721704323	FCS	144.60475668	-37.68506957
3018574364	2021-04-28	\N	GAVIC720699788	FCS	145.56881932	-38.08411955
4254865	2012-11-01	\N	GAVIC420040549	FCS	144.92750496	-37.69164883
8488228	2015-04-22	\N	GAVIC425614233	FCS	145.02045030	-37.81291837
3785595	2012-11-01	\N	GAVIC423081290	PAPS	147.11768394	-36.36565171
4435119	2012-11-01	\N	GAVIC421930895	FCS	145.09553392	-37.76869185
4323928	2012-11-01	\N	GAVIC419784455	FCS	145.16734389	-37.90814685
1633770	2012-11-01	\N	GAVIC424531851	FCS	144.40048822	-38.03352096
2215547	2012-11-01	\N	GAVIC419621302	FCS	145.26791988	-37.83366186
3295066	2012-11-01	\N	GAVIC420255830	FCS	145.03281694	-37.68269584
4002905	2012-11-01	\N	GAVIC424353303	FCS	142.14417227	-34.23335670
2611678	2025-10-30	\N	GAVIC420684174	FCS	145.10391638	-37.86815522
7755337	2013-08-06	\N	GAVIC425275442	FCS	145.04077496	-37.87483964
4521622	2024-07-30	\N	GAVIC423402101	STL	144.04554759	-37.06504795
2980366	2012-11-01	\N	GAVIC421689281	FCS	145.24271688	-37.89255286
1736074	2012-11-01	\N	GAVIC420504897	FCS	145.03433532	-37.82695143
8418681	2014-11-04	\N	GAVIC425520470	FCS	144.96208951	-37.82567255
9916302	2023-11-07	\N	GAVIC425786720	FCS	144.98717136	-37.80579441
4401869	2012-11-01	\N	GAVIC419711232	FCS	145.05521891	-37.95650684
4428725	2023-08-06	\N	GAVIC423792711	FCS	144.94697159	-37.81829164
3196520	2012-11-01	\N	GAVIC419906596	FCS	145.01220893	-37.76388184
3007406887	2017-02-01	\N	GAVIC719213944	FCS	144.88061497	-38.37019588
1876878	2023-08-06	\N	GAVIC421300189	FCS	145.28998847	-38.03968301
4362428	2023-05-07	\N	GAVIC423874856	FCS	144.95632191	-37.81598779
1557437	2012-11-01	\N	GAVIC421300826	FCS	145.26113486	-37.99747286
3009058026	2018-01-31	\N	GAVIC719607123	FCS	144.96121215	-37.80936093
2288534	2015-02-04	\N	GAVIC421524934	FCS	145.00928409	-37.89690153
1806648	2012-11-01	\N	GAVIC421281678	FCS	145.10725291	-37.85929785
3855742	2013-08-06	\N	GAVIC420191477	FCS	144.98180443	-37.80273850
3235935	2023-05-07	\N	GAVIC424637478	FCS	145.08061617	-37.88768200
3740671	2023-11-07	\N	GAVIC423490362	FCS	144.97687491	-37.83862075
4550646	2012-11-01	\N	GAVIC423401833	STL	147.98920079	-36.12645326
3399137	2012-11-01	\N	GAVIC420048609	FCS	144.95148594	-37.83279084
3280868	2012-11-01	\N	GAVIC421612837	FCS	144.95686895	-37.73377284
3022248411	2024-04-30	\N	GAVIC721476998	FCS	144.99668006	-37.88790169
3995960	2012-11-01	\N	GAVIC424034425	FCS	145.27359847	-38.01934566
2987818	2024-01-29	\N	GAVIC423215409	FCS	144.97901820	-37.85909600
3022168172	2023-11-07	\N	GAVIC721369066	FCS	144.95401004	-37.81323986
4489697	2023-11-07	\N	GAVIC424551158	STL	144.12364674	-37.31224832
3019450	2015-02-04	\N	GAVIC411803305	FCS	144.97982610	-37.84919580
3513625	2012-11-01	\N	GAVIC411441273	FCS	145.04063792	-37.86009234
2810856	2012-11-01	\N	GAVIC421379520	FCS	145.24739088	-37.90586486
3014356122	2019-08-05	\N	GAVIC720126989	FCS	144.58248534	-37.65572307
7638081	2013-01-25	\N	GAVIC425157653	FCS	144.95228428	-37.83226723
1882995	2012-11-01	\N	GAVIC413630613	FCS	145.26442452	-37.84333097
3136314	2012-11-01	\N	GAVIC421143250	FCS	144.55745027	-38.16280641
4528962	2012-11-01	\N	GAVIC423406602	STL	144.97904009	-38.46960069
4571017	2025-10-30	\N	GAVIC423401116	STL	144.24614762	-35.94079711
2791108	2012-11-01	\N	GAVIC420949509	FCS	146.89489306	-36.12617623
3014357797	2019-08-05	\N	GAVIC720132188	FCS	144.46241460	-38.20247914
2441163	2012-11-01	\N	GAVIC419645242	FCS	145.06369376	-37.89712682
3992246	2012-11-01	\N	GAVIC420610243	FCS	145.06421894	-37.63707884
1435463	2024-01-29	\N	GAVIC421658800	FCS	146.94689729	-36.18544068
3624261	2020-08-05	\N	GAVIC421147883	FCS	144.92603870	-37.72752400
1762240	2012-11-01	\N	GAVIC420833582	FCS	144.91638095	-37.72169983
3021924578	2023-08-06	\N	GAVIC721284836	FCS	144.95342148	-37.81448127
1637032	2024-07-30	\N	GAVIC424877747	FCS	144.91614705	-37.78236924
2148921	2012-11-01	\N	GAVIC419943868	FCS	145.06742590	-37.96700885
3937783	2021-08-14	\N	GAVIC421756773	FCS	145.19469529	-37.92066388
2457433	2012-11-01	\N	GAVIC424777831	FCS	145.35682189	-37.93104574
4518384	2021-04-28	\N	GAVIC423394320	STL	143.55433875	-35.90946143
2596375	2012-11-01	\N	GAVIC420454965	FCS	144.70910593	-38.33081682
3012880739	2018-11-06	\N	GAVIC719913448	FCS	144.97599334	-37.83867611
2190327	2012-11-01	\N	GAVIC421242246	FCS	145.04675093	-37.77270184
1395420	2012-11-01	\N	GAVIC419618007	FCS	145.02125194	-37.70012084
3008866688	2017-08-08	\N	GAVIC719413114	FCS	143.83740943	-37.58334028
1310002	2012-11-01	\N	GAVIC412717346	FCS	144.95546114	-37.82074898
2390745	2024-01-29	\N	GAVIC424263462	FCS	146.15804669	-38.21939215
1524891	2024-01-29	\N	GAVIC424246587	FCS	145.93303540	-38.15891757
1726349	2013-08-06	\N	GAVIC419802779	FCS	144.78540965	-37.87069403
3523206	2012-11-01	\N	GAVIC424917511	FCS	144.95340078	-37.48082776
1681592	2012-11-01	\N	GAVIC420703086	FCS	145.07381991	-37.83804685
2282167	2024-04-30	\N	GAVIC421444901	FCS	145.14903033	-37.97050256
3594281	2012-11-01	\N	GAVIC419784186	FCS	145.28727385	-38.10147586
4546840	2023-11-07	\N	GAVIC412676699	STL	146.57888840	-36.42068667
7746946	2013-08-06	\N	GAVIC425274882	FCS	144.96918736	-37.82945629
3091702	2020-11-06	\N	GAVIC412527335	PAPS	145.22722126	-37.85362056
3007221941	2023-11-07	\N	GAVIC719010591	FCS	144.95542694	-37.80043670
2961001	2012-11-01	\N	GAVIC424675889	FCS	145.18359652	-38.08837093
3482350	2012-11-01	\N	GAVIC420695756	FCS	144.93415096	-37.63298383
2608855	2023-02-03	\N	GAVIC424684358	FCS	145.16705403	-37.90973248
1386254	2012-11-01	\N	GAVIC420921756	FCS	145.27731319	-38.50680422
2545170	2021-08-14	\N	GAVIC419780964	FCS	145.23626340	-38.19602626
3007303954	2016-11-07	\N	GAVIC719096818	FCS	144.95324680	-37.79869617
3631017	2012-11-01	\N	GAVIC424727151	FCS	144.76479556	-37.90634255
1857538	2012-11-01	\N	GAVIC420390898	FCS	145.27640385	-38.06949586
3020601564	2024-04-30	\N	GAVIC720743838	FCS	143.79015646	-37.57346998
3007327762	2023-11-07	\N	GAVIC719115528	FCS	145.12306020	-37.81609649
4039713	2012-11-01	\N	GAVIC420732404	FCS	145.35609185	-37.97087587
8345770	2014-08-02	\N	GAVIC425461232	FCS	144.98884738	-37.84423607
4534555	2012-11-01	\N	GAVIC412674706	STL	146.26166412	-36.28992379
7679186	2013-05-01	\N	GAVIC425231579	FCS	145.24940385	-38.11300223
4351549	2012-11-01	\N	GAVIC412227164	FCS	145.24129037	-37.93776924
3481109	2012-11-01	\N	GAVIC425028781	FCS	144.97693229	-37.84125908
3022458522	2025-01-28	\N	GAVIC721704334	FCS	144.96725679	-37.83654004
3068343	2012-11-01	\N	GAVIC425093622	PAPS	143.80901847	-36.42267564
3362380	2025-04-30	\N	GAVIC421109751	FCS	144.91933848	-37.68425868
4138797	2012-11-01	\N	GAVIC421731563	FCS	144.66250098	-37.89781982
2166901	2012-11-01	\N	GAVIC420757091	FCS	144.97527015	-37.77439431
4458805	2012-11-01	\N	GAVIC421458512	FCS	144.28538056	-36.75068194
2268170	2012-11-01	\N	GAVIC420773569	FCS	144.76389298	-37.73560182
3351787	2012-11-01	\N	GAVIC423669472	FCS	145.00025242	-37.73804234
3613830	2016-08-07	\N	GAVIC421674160	FCS	144.96795863	-37.81305954
3611568	2023-08-06	\N	GAVIC420205676	FCS	145.16746051	-37.97385510
4550204	2023-11-07	\N	GAVIC423398421	STL	144.48423475	-35.97951931
3008884952	2017-08-08	\N	GAVIC719420229	FCS	144.97095196	-37.83106671
7748749	2013-08-06	\N	GAVIC425285314	FCS	144.95308018	-37.81557058
3014222548	2019-02-05	\N	GAVIC719988843	FCS	144.95670034	-37.82766595
3008959417	2019-08-05	\N	GAVIC719537604	FCS	146.52229436	-38.20900349
3903054	2024-01-29	\N	GAVIC419811494	FCS	145.25936400	-37.82476095
3008961781	2022-08-09	\N	GAVIC719539171	PAPS	144.42534506	-38.03023298
1327983	2015-02-04	\N	GAVIC423280693	FCS	144.96730862	-37.80879726
2289721	2023-08-06	\N	GAVIC411825992	FCS	144.97471609	-37.83550076
1502672	2024-04-30	\N	GAVIC420787418	FCS	145.00364361	-37.93029719
3429921	2015-02-04	\N	GAVIC423632802	FCS	144.96096404	-37.80776941
2918668	2012-11-01	\N	GAVIC420900117	FCS	141.59728856	-38.36005649
1244256	2012-11-01	\N	GAVIC420135739	FCS	144.91010495	-37.77861483
4104522	2012-11-01	\N	GAVIC420083984	FCS	144.96591795	-37.69607084
2599612	2012-11-01	\N	GAVIC419620282	FCS	144.61954999	-37.89747281
2220138	2012-11-01	\N	GAVIC423444001	FCS	144.96682147	-37.79425274
2448442	2023-11-07	\N	GAVIC423623835	FCS	144.94629899	-37.79682005
8361433	2022-05-09	\N	GAVIC425486221	STL	144.18625307	-37.16916858
1738884	2025-10-30	\N	GAVIC424478303	FCS	144.99710497	-37.83903096
1498034	2012-11-01	\N	GAVIC421995183	FCS	144.74124003	-37.72359677
3456902	2024-07-30	\N	GAVIC423648049	FCS	144.96770029	-37.81131701
3008704402	2017-05-01	\N	GAVIC719309027	FCS	144.32718535	-38.22548958
4376292	2012-11-01	\N	GAVIC420257417	FCS	144.55466591	-38.26152596
3891075	2025-10-30	\N	GAVIC425008870	FCS	144.96896432	-37.81231826
1930184	2012-11-01	\N	GAVIC424667096	FCS	144.73032763	-37.90809188
3009070062	2018-01-31	\N	GAVIC719622334	FCS	144.99828331	-37.88463722
1339207	2025-04-30	\N	GAVIC423935363	FCS	145.97512786	-36.55570371
4511701	2022-08-09	\N	GAVIC423404123	STL	145.07901230	-37.43279669
3021913198	2023-08-06	\N	GAVIC721289923	FCS	145.00426485	-37.94247202
4325668	2012-11-01	\N	GAVIC421774336	FCS	145.05035091	-37.92571484
4552938	2015-04-22	\N	GAVIC411935231	STL	145.37545033	-37.80089948
3007394657	2017-02-01	\N	GAVIC719207295	FCS	144.94431849	-37.82967437
4571176	2015-04-22	\N	GAVIC423643559	STL	142.12461716	-34.20003429
4093712	2015-02-04	\N	GAVIC423911067	FCS	144.97111975	-37.83180171
2472113	2012-11-01	\N	GAVIC420148109	FCS	145.57699318	-36.75530318
4450952	2015-02-04	\N	GAVIC423620402	FCS	144.94606971	-37.79807410
4207958	2012-11-01	\N	GAVIC421838556	FCS	145.83101011	-38.44012569
3115410	2020-05-06	\N	GAVIC423110860	PAPS	145.29331660	-38.13844700
8362575	2015-02-04	\N	GAVIC425480664	FCS	145.01414918	-37.81175875
3931837	2012-11-01	\N	GAVIC420058003	FCS	145.17748186	-38.15497185
3008887073	2023-08-06	\N	GAVIC719424466	FCS	144.97370122	-37.83579341
3007321306	2021-11-11	\N	GAVIC719111600	FCS	144.30785872	-36.74158052
4078780	2012-11-01	\N	GAVIC421481958	FCS	144.83558596	-37.83086983
\.

-- gnaf_202602.address_alias_admin_boundaries: 75 rows
\copy gnaf_202602.address_alias_admin_boundaries FROM stdin
5670	GAVIC422443247	loc12c0177d3d38	PASCOE VALE	3044	VIC	VIC81	WILLS	lgaJ2LPN2y4pll0	Merri-Bek	wadMEHdC-S5s8qs	Pascoe Vale South Ward	VIC330	PASCOE VALE	VIC398	NORTHERN METROPOLITAN
6029	GAVIC413382151	loc4fa4b090ce9e	HAWTHORN EAST	3123	VIC	VIC68	KOOYONG	lga0930e8ebad68	Boroondara	wadb5ad118a1aa8	Riversdale Ward	VIC389	HAWTHORN	VIC394	SOUTHERN METROPOLITAN
6396	GAVIC425096507	locbb6ca08c118e	NORTHCOTE	3070	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wad3fb5999d4db1	South Ward	VIC326	NORTHCOTE	VIC398	NORTHERN METROPOLITAN
17650	GAVIC421992539	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
55659	GAVIC719937293	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
56462	GAVIC423537704	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
76389	GAVIC424636555	loc72d1f0339be6	RINGWOOD	3134	VIC	VIC54	DEAKIN	lgafa7d75c94e0c	Maroondah	wade9a60dcb613e	Wonga Ward	VIC336	RINGWOOD	VIC397	NORTH-EASTERN METROPOLITAN
84268	GAVIC425232920	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
93230	GAVIC425294823	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
95841	GAVIC423728755	loc8e5a2b16aaaa	TRARALGON	3844	VIC	VIC59	GIPPSLAND	lga5e8f0b6a35b1	Latrobe	wadt47MKKQlcBwn	Boola Boola Ward	VIC318	MORWELL	VIC396	EASTERN VICTORIA
95842	GAVIC423728754	loc8e5a2b16aaaa	TRARALGON	3844	VIC	VIC59	GIPPSLAND	lga5e8f0b6a35b1	Latrobe	wadt47MKKQlcBwn	Boola Boola Ward	VIC318	MORWELL	VIC396	EASTERN VICTORIA
96114	GAVIC425420428	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
99928	GAVIC423659466	loc82b861dfb765	THORNBURY	3071	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wade68903703ea0	South West Ward	VIC326	NORTHCOTE	VIC398	NORTHERN METROPOLITAN
125186	GAVIC411975916	loc6280f9052ec0	NARRE WARREN SOUTH	3805	VIC	VIC47	BRUCE	lga891e1f62b45e	Casey	wad-Zifaq6Gq01M	Casuarina Ward	VIC323	NARRE WARREN SOUTH	VIC393	SOUTH-EASTERN METROPOLITAN
130898	GAVIC721460023	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
147453	GAVIC425013938	loc2d817b7080e2	MALVERN EAST	3145	VIC	VIC50	CHISHOLM	lgae1dcbacb8510	Stonnington	wad4GOUAzunjtQ3	Hedgeley Dene Ward	VIC310	MALVERN	VIC394	SOUTHERN METROPOLITAN
147644	GAVIC411282405	loc7a8164839d54	DONCASTER EAST	3109	VIC	VIC76	MENZIES	lgab3be0b9eb31a	Manningham	wad00ce24084fec	Waldau Ward	VIC348	WARRANDYTE	VIC397	NORTH-EASTERN METROPOLITAN
167000	GAVIC423555143	loc79e45c9fa669	BRUNSWICK EAST	3057	VIC	VIC81	WILLS	lgaJ2LPN2y4pll0	Merri-Bek	wadlMZ140e5e2tn	Warrk-Warrk Ward	VIC366	BRUNSWICK	VIC398	NORTHERN METROPOLITAN
178057	GAVIC719457195	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
185061	GAVIC425853242	loca0398a35cf5e	CARLTON	3053	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
185461	GAVIC424091347	loc9fb289b0a33e	IRYMPLE	3498	VIC	VIC72	MALLEE	lgaee4000c6a5c1	Mildura	wadWxWdJFaA5OC5	Sunset Country Ward	VIC313	MILDURA	VIC392	NORTHERN VICTORIA
197908	GAVIC425246317	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
200479	GAVIC412010761	loc1e06c486c813	NORTH MELBOURNE	3051	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
18394	GAVIC425372485	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
20308	GAVIC422117058	locc586266ef8cc	SALE	3850	VIC	VIC59	GIPPSLAND	lga4d167b5c075b	Wellington	wadd44e8a9553ef	Central Ward	VIC385	GIPPSLAND SOUTH	VIC396	EASTERN VICTORIA
26898	GAVIC421523064	loc5c27e3f22fc1	HAWTHORN	3122	VIC	VIC68	KOOYONG	lga0930e8ebad68	Boroondara	wadb5ad118a1aa8	Riversdale Ward	VIC389	HAWTHORN	VIC394	SOUTHERN METROPOLITAN
28459	GAVIC720471214	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
38087	GAVIC719006374	loc1e06c486c813	NORTH MELBOURNE	3051	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
52559	GAVIC413192636	locb17fb225139f	IVANHOE EAST	3079	VIC	VIC67	JAGAJAGA	lga5591321694d6	Banyule	wadd52b1e7fef89	Griffin Ward	VIC390	IVANHOE	VIC397	NORTH-EASTERN METROPOLITAN
56027	GAVIC719459374	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
60951	GAVIC719053315	loc1e06c486c813	NORTH MELBOURNE	3051	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
74808	GAVIC425335858	loc0b8afd71fce1	WEST MELBOURNE	3003	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
77824	GAVIC421987657	loccaca39f133a7	HEIDELBERG HEIGHTS	3081	VIC	VIC67	JAGAJAGA	lga5591321694d6	Banyule	wada6a3e547acbc	Olympia Ward	VIC390	IVANHOE	VIC397	NORTH-EASTERN METROPOLITAN
88946	GAVIC719457877	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
104269	GAVIC720234958	loc2c4c767ea9b7	PRESTON	3072	VIC	VIC51	COOPER	lga5bfafb32b8d5	Darebin	wad8f5a9db3d21b	Central Ward	VIC326	NORTHCOTE	VIC398	NORTHERN METROPOLITAN
105455	GAVIC410965788	loc74f8893fb76e	BROADMEADOWS	3047	VIC	VIC48	CALWELL	lga3476c1d9fd7f	Hume	wadXsV2_er3gqTy	Merlynston Creek Ward	VIC365	BROADMEADOWS	VIC398	NORTHERN METROPOLITAN
124652	GAVIC721251051	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
142517	GAVIC721333432	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
144136	GAVIC719939375	loca0398a35cf5e	CARLTON	3053	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
152886	GAVIC425294479	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
157674	GAVIC421544966	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
160823	GAVIC423769586	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
162004	GAVIC425027132	locc2ea2de6af6c	SOUTH YARRA	3141	VIC	VIC75	MELBOURNE	lgae1dcbacb8510	Stonnington	wadSdQj5ZcEpUYw	Como Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
165262	GAVIC422080427	loca1b6ce72e35a	MOUNT WAVERLEY	3149	VIC	VIC50	CHISHOLM	lga15c9c80d4be7	Monash	wadB4dkXVU1StzL	Scotchmans Creek Ward	VIC354	ASHWOOD	VIC394	SOUTHERN METROPOLITAN
169099	GAVIC720001539	loc3319215a0a10	BRIGHTON	3186	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad828d750c07c7	Bleazby Ward	VIC364	BRIGHTON	VIC394	SOUTHERN METROPOLITAN
187658	GAVIC413977671	loc3b64e6146ff8	MORDIALLOC	3195	VIC	VIC66	ISAACS	lga691f580f3258	Kingston	wad4b7424fe2c1a	Melaleuca Ward	VIC316	MORDIALLOC	VIC393	SOUTH-EASTERN METROPOLITAN
190363	GAVIC421611304	loc1b289d3ff2fc	SHEPPARTON	3630	VIC	VIC78	NICHOLLS	lga1a793093877f	Greater Shepparton	wadILqLGXlIxqFo	Balaclava Ward	VIC340	SHEPPARTON	VIC392	NORTHERN VICTORIA
201448	GAVIC425762632	loc9e7da77def26	PARKVILLE	3052	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
204688	GAVIC720075106	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
207557	GAVIC425032577	locdd716f1059c5	MENTONE	3194	VIC	VIC66	ISAACS	lga691f580f3258	Kingston	wadd1bbf3e2721d	Como Ward	VIC339	SANDRINGHAM	VIC394	SOUTHERN METROPOLITAN
9502	GAVIC719749191	loc1e06c486c813	NORTH MELBOURNE	3051	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
22235	GAVIC719459794	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
37914	GAVIC719227954	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
41970	GAVIC423804130	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
56578	GAVIC425580055	loca0398a35cf5e	CARLTON	3053	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
58339	GAVIC411050404	loca0398a35cf5e	CARLTON	3053	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
61153	GAVIC424474882	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
62282	GAVIC719770314	loc31f384e524fe	SOUTHBANK	3006	VIC	VIC71	MACNAMARA	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC353	ALBERT PARK	VIC394	SOUTHERN METROPOLITAN
65784	GAVIC719765629	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
69628	GAVIC719816339	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
69851	GAVIC719512693	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
74367	GAVIC423728050	loc9901d119afda_1	MELBOURNE	3000	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
75558	GAVIC721504027	loc3319215a0a10	BRIGHTON	3186	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad086a5a9284d6	Dendy Ward	VIC364	BRIGHTON	VIC394	SOUTHERN METROPOLITAN
77907	GAVIC412739901	loc9901d119afda_2	MELBOURNE	3004	VIC	VIC71	MACNAMARA	lgad68479123642	Port Phillip	wad1UZuH3bVedRB	Lakeside Ward	VIC333	PRAHRAN	VIC394	SOUTHERN METROPOLITAN
78198	GAVIC422412680	loc4ff8c926c940	ASHWOOD	3147	VIC	VIC50	CHISHOLM	lga15c9c80d4be7	Monash	wadTfHiT64vDmQ1	Gardiners Creek Ward	VIC354	ASHWOOD	VIC394	SOUTHERN METROPOLITAN
98333	GAVIC719767317	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
100419	GAVIC422419032	locb344fc28a060	PEARCEDALE	3912	VIC	VIC63	HOLT	lga891e1f62b45e	Casey	wad6sK7FI4NeSmJ	Cranbourne Gardens Ward	VIC355	BASS	VIC396	EASTERN VICTORIA
130678	GAVIC718990761	loc1e06c486c813	NORTH MELBOURNE	3051	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
137057	GAVIC721387488	loce42a110faa48	HAMPTON	3188	VIC	VIC60	GOLDSTEIN	lga53f7b61b0ed6	Bayside	wad402ca2ca8a7a	Boyd Ward	VIC339	SANDRINGHAM	VIC394	SOUTHERN METROPOLITAN
152815	GAVIC425325821	loc406d1f7b5fe3	TEMPLESTOWE	3106	VIC	VIC76	MENZIES	lgab3be0b9eb31a	Manningham	wad00ce24084fec	Waldau Ward	VIC367	BULLEEN	VIC397	NORTH-EASTERN METROPOLITAN
180726	GAVIC420755745	locf57f2052e543	FRANKSTON NORTH	3200	VIC	VIC55	DUNKLEY	lgadd7fe82edc77	Frankston	wadhxD2G_0oKCn0	Pines Ward	VIC382	FRANKSTON	VIC393	SOUTH-EASTERN METROPOLITAN
185698	GAVIC422113816	loc3754c5fc3408	ROXBURGH PARK	3064	VIC	VIC48	CALWELL	lga3476c1d9fd7f	Hume	wadHld8m0wD7Ey9	Roxburgh Park Ward	VIC387	GREENVALE	VIC398	NORTHERN METROPOLITAN
186898	GAVIC719044287	loc4858bcc1d912	GLENROY	3046	VIC	VIC73	MARIBYRNONG	lgaJ2LPN2y4pll0	Merri-Bek	wad10bOEnGsV8dy	Djirri-Djirri Ward	VIC365	BROADMEADOWS	VIC398	NORTHERN METROPOLITAN
198251	GAVIC425042539	loc2d817b7080e2	MALVERN EAST	3145	VIC	VIC50	CHISHOLM	lgae1dcbacb8510	Stonnington	wad4GOUAzunjtQ3	Hedgeley Dene Ward	VIC310	MALVERN	VIC394	SOUTHERN METROPOLITAN
200378	GAVIC721459739	locddc4a1bcd8ba	DOCKLANDS	3008	VIC	VIC75	MELBOURNE	lgadd6ba71d5cd0	Melbourne	wad851b1ea7d8b8	Melbourne City	VIC311	MELBOURNE	VIC398	NORTHERN METROPOLITAN
\.





-- admin_bdys_202602.abs_2021_mb_lookup: 430 rows
\copy admin_bdys_202602.abs_2021_mb_lookup FROM stdin
20015080000	Primary Production	20102101203	201021012	Gordon (Vic.)	20102	Creswick - Daylesford - Ballan	201	Ballarat	2RVIC	Rest of Vic.	VIC
20015890000	Residential	20901120105	209011201	Ivanhoe East - Eaglemont	20901	Banyule	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20017620000	Residential	20901119930	209011199	Heidelberg West	20901	Banyule	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20017970000	Residential	20901120019	209011200	Ivanhoe	20901	Banyule	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20020210000	Residential	20901119904	209011199	Heidelberg West	20901	Banyule	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20022580000	Residential	20901119926	209011199	Heidelberg West	20901	Banyule	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20028860000	Residential	20901120405	209011204	Watsonia	20901	Banyule	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20032220000	Residential	20503109142	205031091	Phillip Island	20503	Gippsland - South West	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20034520000	Residential	20503109332	205031093	Wonthaggi - Inverloch	20503	Gippsland - South West	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20037872000	Residential	20501107812	205011078	Trafalgar (Vic.)	20501	Baw Baw	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20040260000	Residential	20501107916	205011079	Warragul	20501	Baw Baw	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20041512000	Residential	20501107642	205011076	Drouin	20501	Baw Baw	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20042210000	Residential	20801116924	208011169	Brighton (Vic.)	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20043310000	Residential	20801116954	208011169	Brighton (Vic.)	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20045030000	Residential	20801116917	208011169	Brighton (Vic.)	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20046460000	Residential	20801116953	208011169	Brighton (Vic.)	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20046650000	Residential	20801116905	208011169	Brighton (Vic.)	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20049510000	Residential	20801117203	208011172	Hampton	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20050080000	Residential	20801117336	208011173	Sandringham - Black Rock	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20051100000	Residential	20801117120	208011171	Highett (West) - Cheltenham	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20051680000	Commercial	20801117201	208011172	Hampton	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20052480000	Residential	20801117109	208011171	Highett (West) - Cheltenham	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20053780000	Parkland	20402106308	204021063	Benalla	20402	Wangaratta - Benalla	204	Hume	2RVIC	Rest of Vic.	VIC
20054420000	Residential	20402106314	204021063	Benalla	20402	Wangaratta - Benalla	204	Hume	2RVIC	Rest of Vic.	VIC
20057910000	Residential	20701114851	207011148	Balwyn North	20701	Boroondara	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20060072000	Commercial	20701115524	207011155	Surrey Hills (West) - Canterbury	20701	Boroondara	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20060940000	Residential	20701114947	207011149	Camberwell	20701	Boroondara	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20063430000	Residential	20701114932	207011149	Camberwell	20701	Boroondara	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20065710000	Residential	20701114946	207011149	Camberwell	20701	Boroondara	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20066880000	Residential	20701152011	207011520	Hawthorn - South	20701	Boroondara	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20069550000	Residential	20701115201	207011152	Hawthorn East	20701	Boroondara	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20070660000	Residential	20701151922	207011519	Hawthorn - North	20701	Boroondara	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20070880000	Residential	20701152002	207011520	Hawthorn - South	20701	Boroondara	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20071660000	Residential	20701152019	207011520	Hawthorn - South	20701	Boroondara	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20072380000	Residential	20701152216	207011522	Kew - West	20701	Boroondara	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20076780000	Residential	21301134048	213011340	Taylors Lakes	21301	Brimbank	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20082000000	Residential	21301133333	213011333	Kings Park (Vic.)	21301	Brimbank	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20085010000	Residential	21301156922	213011569	Deer Park	21301	Brimbank	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20086810000	Residential	21301133530	213011335	St Albans - South	21301	Brimbank	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20092653200	Residential	21301156930	213011569	Deer Park	21301	Brimbank	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20093470000	Residential	21301133826	213011338	Sunshine West	21301	Brimbank	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20097170000	Residential	21601140706	216011407	Kyabram	21601	Campaspe	216	Shepparton	2RVIC	Rest of Vic.	VIC
20098990000	Primary Production	21601140811	216011408	Lockington - Gunbower	21601	Campaspe	216	Shepparton	2RVIC	Rest of Vic.	VIC
20099280000	Primary Production	21601140803	216011408	Lockington - Gunbower	21601	Campaspe	216	Shepparton	2RVIC	Rest of Vic.	VIC
20099380000	Primary Production	21601140811	216011408	Lockington - Gunbower	21601	Campaspe	216	Shepparton	2RVIC	Rest of Vic.	VIC
20102750000	Residential	21201154706	212011547	Bunyip - Garfield	21201	Cardinia	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20104480000	Residential	21201155240	212011552	Pakenham - South West	21201	Cardinia	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20111180000	Residential	21203145813	212031458	Narre Warren South - West	21203	Casey - South	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20117410000	Residential	21203156022	212031560	Cranbourne North - West	21203	Casey - South	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20118600000	Residential	21203130040	212031300	Cranbourne	21203	Casey - South	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20124160000	Residential	21202129715	212021297	Hallam	21202	Casey - North	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20127070000	Industrial	21202129720	212021297	Hallam	21202	Casey - North	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20128480000	Residential	21203130806	212031308	Pearcedale - Tooradin	21203	Casey - South	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20136091000	Residential	21703147604	217031476	Otway	21703	Colac - Corangamite	217	Warrnambool and South West	2RVIC	Rest of Vic.	VIC
20140990000	Residential	20602111218	206021112	Thornbury	20602	Darebin - South	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20145322000	Residential	20602149915	206021499	Northcote - East	20602	Darebin - South	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20146160000	Residential	20902142834	209021428	Preston - East	20902	Darebin - North	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20146170000	Residential	20902152519	209021525	Reservoir - South East	20902	Darebin - North	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20147990000	Residential	20902152516	209021525	Reservoir - South East	20902	Darebin - North	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20148320000	Residential	20902152616	209021526	Reservoir - South West	20902	Darebin - North	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20149752000	Residential	20902152419	209021524	Reservoir - North West	20902	Darebin - North	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20150610000	Residential	20902152319	209021523	Reservoir - North East	20902	Darebin - North	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20151200000	Residential	20902152514	209021525	Reservoir - South East	20902	Darebin - North	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20152720000	Residential	20902142912	209021429	Preston - West	20902	Darebin - North	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20153581000	Residential	20902142850	209021428	Preston - East	20902	Darebin - North	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20153770000	Residential	20902142818	209021428	Preston - East	20902	Darebin - North	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20155310000	Residential	20902120503	209021205	Kingsbury	20902	Darebin - North	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20155590000	Residential	20902120521	209021205	Kingsbury	20902	Darebin - North	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20157450000	Residential	20502108124	205021081	Bairnsdale	20502	Gippsland - East	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20158530000	Residential	20502108112	205021081	Bairnsdale	20502	Gippsland - East	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20166050000	Residential	21401137442	214011374	Langwarrin	21401	Frankston	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20169440000	Residential	21401137241	214011372	Frankston North	21401	Frankston	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20172140000	Residential	21401137124	214011371	Frankston	21401	Frankston	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20180720000	Residential	21503140202	215031402	Kerang	21503	Murray River - Swan Hill	215	North West	2RVIC	Rest of Vic.	VIC
20181836000	Primary Production	21503140109	215031401	Gannawarra	21503	Murray River - Swan Hill	215	North West	2RVIC	Rest of Vic.	VIC
20186940000	Residential	20802117910	208021179	Elsternwick	20802	Glen Eira	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20188460000	Residential	20802117612	208021176	Carnegie	20802	Glen Eira	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20189370000	Residential	20802117923	208021179	Elsternwick	20802	Glen Eira	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20192490000	Residential	20802117831	208021178	Caulfield - South	20802	Glen Eira	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20194680000	Residential	20802118226	208021182	Ormond - Glen Huntly	20802	Glen Eira	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20195181000	Residential	20802142707	208021427	Bentleigh East - South	20802	Glen Eira	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20201760000	Residential	21701142221	217011422	Portland	21701	Glenelg - Southern Grampians	217	Warrnambool and South West	2RVIC	Rest of Vic.	VIC
20203412000	Other	20301103512	203011035	Golden Plains - South	20301	Barwon - West	203	Geelong	2RVIC	Rest of Vic.	VIC
20203780000	Residential	20201101831	202011018	Bendigo	20201	Bendigo	202	Bendigo	2RVIC	Rest of Vic.	VIC
20205930000	Residential	20201101835	202011018	Bendigo	20201	Bendigo	202	Bendigo	2RVIC	Rest of Vic.	VIC
20213402000	Industrial	20201102036	202011020	East Bendigo - Kennington	20201	Bendigo	202	Bendigo	2RVIC	Rest of Vic.	VIC
20216412000	Residential	20201102413	202011024	Strathfieldsaye	20201	Bendigo	202	Bendigo	2RVIC	Rest of Vic.	VIC
20216820000	Residential	20202102906	202021029	Heathcote	20202	Heathcote - Castlemaine - Kyneton	202	Bendigo	2RVIC	Rest of Vic.	VIC
20216831000	Primary Production	20202102904	202021029	Heathcote	20202	Heathcote - Castlemaine - Kyneton	202	Bendigo	2RVIC	Rest of Vic.	VIC
20217800000	Other	20202102617	202021026	Bendigo Surrounds - South	20202	Heathcote - Castlemaine - Kyneton	202	Bendigo	2RVIC	Rest of Vic.	VIC
20222990000	Residential	21204131232	212041312	Dandenong North	21204	Dandenong	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20227850000	Residential	21204146001	212041460	Noble Park - West	21204	Dandenong	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20228130000	Residential	21204131816	212041318	Springvale South	21204	Dandenong	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20231850000	Residential	21204145919	212041459	Noble Park - East	21204	Dandenong	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20234280000	Residential	20302104407	203021044	Leopold	20302	Geelong	203	Geelong	2RVIC	Rest of Vic.	VIC
20241680000	Residential	20302148804	203021488	Norlane	20302	Geelong	203	Geelong	2RVIC	Rest of Vic.	VIC
20242060000	Residential	20302104317	203021043	Lara	20302	Geelong	203	Geelong	2RVIC	Rest of Vic.	VIC
20242860000	Residential	20302104348	203021043	Lara	20302	Geelong	203	Geelong	2RVIC	Rest of Vic.	VIC
20243894000	Residential	20302104331	203021043	Lara	20302	Geelong	203	Geelong	2RVIC	Rest of Vic.	VIC
20244100000	Residential	20302104044	203021040	Geelong West - Hamlyn Heights	20302	Geelong	203	Geelong	2RVIC	Rest of Vic.	VIC
20246080000	Residential	20302103929	203021039	Geelong	20302	Geelong	203	Geelong	2RVIC	Rest of Vic.	VIC
20247600000	Residential	20302104024	203021040	Geelong West - Hamlyn Heights	20302	Geelong	203	Geelong	2RVIC	Rest of Vic.	VIC
20251730000	Residential	20302148713	203021487	Grovedale - Mount Duneed	20302	Geelong	203	Geelong	2RVIC	Rest of Vic.	VIC
20257270000	Residential	20303149033	203031490	Ocean Grove	20303	Surf Coast - Bellarine Peninsula	203	Geelong	2RVIC	Rest of Vic.	VIC
20258590000	Residential	20303149006	203031490	Ocean Grove	20303	Surf Coast - Bellarine Peninsula	203	Geelong	2RVIC	Rest of Vic.	VIC
20258850000	Residential	20303149015	203031490	Ocean Grove	20303	Surf Coast - Bellarine Peninsula	203	Geelong	2RVIC	Rest of Vic.	VIC
20259380000	Residential	20303105120	203031051	Portarlington	20303	Surf Coast - Bellarine Peninsula	203	Geelong	2RVIC	Rest of Vic.	VIC
20259980000	Residential	20303104821	203031048	Clifton Springs	20303	Surf Coast - Bellarine Peninsula	203	Geelong	2RVIC	Rest of Vic.	VIC
20260020000	Residential	20303148908	203031489	Barwon Heads - Armstrong Creek	20303	Surf Coast - Bellarine Peninsula	203	Geelong	2RVIC	Rest of Vic.	VIC
20262930000	Residential	20303105125	203031051	Portarlington	20303	Surf Coast - Bellarine Peninsula	203	Geelong	2RVIC	Rest of Vic.	VIC
20265140000	Residential	21603141616	216031416	Shepparton - North	21603	Shepparton	216	Shepparton	2RVIC	Rest of Vic.	VIC
20266260000	Residential	21603141606	216031416	Shepparton - North	21603	Shepparton	216	Shepparton	2RVIC	Rest of Vic.	VIC
20273020000	Other	20102101120	201021011	Daylesford	20102	Creswick - Daylesford - Ballan	201	Ballarat	2RVIC	Rest of Vic.	VIC
20278570000	Residential	21302134327	213021343	Altona North	21302	Hobsons Bay	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20280490000	Residential	21305136301	213051363	Laverton	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20281931000	Residential	21305136302	213051363	Laverton	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20285524000	Residential	21302134604	213021346	Williamstown	21302	Hobsons Bay	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20289790000	Residential	21005124212	210051242	Broadmeadows	21005	Tullamarine - Broadmeadows	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20289930000	Residential	21005124721	210051247	Meadow Heights	21005	Tullamarine - Broadmeadows	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20291970000	Residential	21005124701	210051247	Meadow Heights	21005	Tullamarine - Broadmeadows	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20292910000	Residential	21005125007	210051250	Tullamarine	21005	Tullamarine - Broadmeadows	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20293530000	Residential	21005124225	210051242	Broadmeadows	21005	Tullamarine - Broadmeadows	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20294390000	Residential	21005124211	210051242	Broadmeadows	21005	Tullamarine - Broadmeadows	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20300460000	Residential	21005154403	210051544	Roxburgh Park (South) - Somerton	21005	Tullamarine - Broadmeadows	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20305911000	Primary Production	20403107510	204031075	Yackandandah	20403	Wodonga - Alpine	204	Hume	2RVIC	Rest of Vic.	VIC
20307330000	Residential	21204130903	212041309	Clarinda - Oakleigh South	21204	Dandenong	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20308110000	Residential	20803118836	208031188	Highett (East) - Cheltenham	20803	Kingston	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20308190000	Residential	20803118865	208031188	Highett (East) - Cheltenham	20803	Kingston	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20311950000	Commercial	20803119125	208031191	Moorabbin - Heatherton	20803	Kingston	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20312320000	Residential	20803118812	208031188	Highett (East) - Cheltenham	20803	Kingston	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20312600000	Residential	20803119120	208031191	Moorabbin - Heatherton	20803	Kingston	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20314550000	Residential	20803119028	208031190	Mentone	20803	Kingston	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20316740000	Residential	20803119336	208031193	Mordialloc - Parkdale	20803	Kingston	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20318810000	Residential	20803119317	208031193	Mordialloc - Parkdale	20803	Kingston	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20322330000	Residential	20803118626	208031186	Chelsea - Bonbeach	20803	Kingston	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20324250000	Residential	20803118604	208031186	Chelsea - Bonbeach	20803	Kingston	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20326870000	Residential	21101125110	211011251	Bayswater	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20328100000	Residential	21101144620	211011446	Boronia	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20330854000	Commercial	21101144801	211011448	Ferntree Gully (South) - Upper Ferntree Gully	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20331950000	Industrial	21101125128	211011251	Bayswater	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20333752000	Residential	21101126013	211011260	Wantirna South	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20335960000	Residential	21101125428	211011254	Knoxfield - Scoresby	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20335681000	Residential	21101125924	211011259	Wantirna	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20335682000	Residential	21101125924	211011259	Wantirna	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20338390000	Industrial	21101125432	211011254	Knoxfield - Scoresby	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20338560000	Industrial	21101125701	211011257	Rowville - North	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20338940000	Residential	21101125635	211011256	Rowville - Central	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20339571000	Residential	21101125607	211011256	Rowville - Central	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20340640000	Residential	21101125812	211011258	Rowville - South	21101	Knox	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20346020000	Residential	20504109608	205041096	Morwell	20504	Latrobe Valley	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20346731000	Industrial	20504109625	205041096	Morwell	20504	Latrobe Valley	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20348770000	Residential	20504149322	205041493	Traralgon - East	20504	Latrobe Valley	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20350290000	Residential	20504149330	205041493	Traralgon - East	20504	Latrobe Valley	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20350346000	Industrial	20504149323	205041493	Traralgon - East	20504	Latrobe Valley	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20350411000	Residential	20504149411	205041494	Traralgon - West	20504	Latrobe Valley	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20351381000	Primary Production	20203103317	202031033	Loddon	20203	Loddon - Elmore	202	Bendigo	2RVIC	Rest of Vic.	VIC
20352124000	Primary Production	20203103311	202031033	Loddon	20203	Loddon - Elmore	202	Bendigo	2RVIC	Rest of Vic.	VIC
20352921000	Primary Production	20202103005	202021030	Kyneton	20202	Heathcote - Castlemaine - Kyneton	202	Bendigo	2RVIC	Rest of Vic.	VIC
20354040000	Residential	21002123511	210021235	Romsey	21002	Macedon Ranges	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20354290000	Primary Production	21002123406	210021234	Riddells Creek	21002	Macedon Ranges	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20355352000	Residential	21002123215	210021232	Gisborne	21002	Macedon Ranges	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20356110000	Residential	21002123216	210021232	Gisborne	21002	Macedon Ranges	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20359680000	Residential	20702115716	207021157	Doncaster	20702	Manningham - West	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20361550000	Residential	20702142502	207021425	Doncaster East - South	20702	Manningham - West	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20361840000	Residential	20702115915	207021159	Templestowe	20702	Manningham - West	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20362460000	Residential	20702115901	207021159	Templestowe	20702	Manningham - West	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20366190000	Residential	20702115619	207021156	Bulleen	20702	Manningham - West	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20373630000	Residential	21303135104	213031351	West Footscray - Tottenham	21303	Maribyrnong	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20377160000	Residential	21303134824	213031348	Footscray	21303	Maribyrnong	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20379442000	Residential	21303134811	213031348	Footscray	21303	Maribyrnong	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20380550000	Residential	21103126707	211031267	Ringwood East	21103	Maroondah	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20385610000	Residential	21103126303	211031263	Bayswater North	21103	Maroondah	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20386220000	Residential	21103145010	211031450	Croydon - East	21103	Maroondah	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20386850000	Residential	21103126523	211031265	Croydon Hills - Warranwood	21103	Maroondah	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20389280000	Residential	21103126635	211031266	Ringwood	21103	Maroondah	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20393110000	Residential	20604150313	206041503	Melbourne CBD - East	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20393902000	Commercial	20604150312	206041503	Melbourne CBD - East	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20394100000	Commercial	20604150305	206041503	Melbourne CBD - East	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20394823000	Commercial	20604111823	206041118	Docklands	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20395090000	Residential	20604111823	206041118	Docklands	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20395113000	Residential	20604150811	206041508	Southbank (West) - South Wharf	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20395174000	Commercial	20604111834	206041118	Docklands	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20395362000	Residential	20604150813	206041508	Southbank (West) - South Wharf	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20395374000	Commercial	20604111817	206041118	Docklands	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20397050000	Residential	20604150630	206041506	North Melbourne	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20398590000	Residential	20604150630	206041506	North Melbourne	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20399641000	Commercial	20604151012	206041510	West Melbourne - Residential	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20399801000	Residential	20604150637	206041506	North Melbourne	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20399980000	Residential	20604111745	206041117	Carlton	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20400290000	Commercial	20604112001	206041120	Flemington Racecourse	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20401531000	Residential	20604150619	206041506	North Melbourne	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20404640000	Residential	21304146301	213041463	Caroline Springs	21304	Melton - Bacchus Marsh	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20405930000	Primary Production	21304157408	213041574	Fraser Rise - Plumpton	21304	Melton - Bacchus Marsh	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20411240000	Residential	21502139608	215021396	Merbein	21502	Mildura	215	North West	2RVIC	Rest of Vic.	VIC
20412290000	Residential	21502147025	215021470	Mildura - South	21502	Mildura	215	North West	2RVIC	Rest of Vic.	VIC
20417390000	Residential	20904122405	209041224	Wallan	20904	Whittlesea - Wallan	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20419510000	Primary Production	20904122408	209041224	Wallan	20904	Whittlesea - Wallan	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20420330000	Residential	21602141401	216021414	Yarrawonga	21602	Moira	216	Shepparton	2RVIC	Rest of Vic.	VIC
20426770000	Residential	21205131902	212051319	Ashwood - Chadstone	21205	Monash	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20430970000	Residential	21205132747	212051327	Wheelers Hill	21205	Monash	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20436380000	Education	21205131915	212051319	Ashwood - Chadstone	21205	Monash	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20440860000	Residential	21205132423	212051324	Mount Waverley - South	21205	Monash	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20443370000	Residential	21205131946	212051319	Ashwood - Chadstone	21205	Monash	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20444130000	Residential	20603111304	206031113	Ascot Vale	20603	Essendon	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20448650000	Residential	20603111601	206031116	Moonee Ponds	20603	Essendon	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20450811000	Residential	20603111519	206031115	Flemington	20603	Essendon	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20458270000	Residential	21304135356	213041353	Bacchus Marsh	21304	Melton - Bacchus Marsh	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20458571000	Residential	21304135302	213041353	Bacchus Marsh	21304	Melton - Bacchus Marsh	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20461472000	Residential	20601110612	206011106	Brunswick East	20601	Brunswick - Coburg	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20462000000	Residential	20601110705	206011107	Brunswick West	20601	Brunswick - Coburg	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20464870000	Residential	20601110715	206011107	Brunswick West	20601	Brunswick - Coburg	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20467730000	Residential	21003153710	210031537	Oak Park	21003	Moreland - North	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20468700000	Residential	20601149704	206011497	Coburg - East	20601	Brunswick - Coburg	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20471770000	Residential	20601149828	206011498	Coburg - West	20601	Brunswick - Coburg	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20473110000	Residential	21003153607	210031536	Glenroy - West	21003	Moreland - North	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20474111000	Residential	21003153704	210031537	Oak Park	21003	Moreland - North	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20474400000	Residential	21003123727	210031237	Fawkner	21003	Moreland - North	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20479940000	Residential	21402137932	214021379	Hastings - Somers	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20484580000	Residential	21402138453	214021384	Rosebud - McCrae	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20485920000	Residential	21402138469	214021384	Rosebud - McCrae	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20486250000	Residential	21402138413	214021384	Rosebud - McCrae	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20486870000	Residential	21402138330	214021383	Point Nepean	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20488510000	Residential	21402138317	214021383	Point Nepean	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20488530000	Residential	21402138303	214021383	Point Nepean	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20491500000	Residential	21402138348	214021383	Point Nepean	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20492500000	Residential	21402138341	214021383	Point Nepean	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20495120000	Primary Production	21402137809	214021378	Flinders	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20495980000	Primary Production	21402137816	214021378	Flinders	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20505520000	Residential	20202102820	202021028	Castlemaine Surrounds	20202	Heathcote - Castlemaine - Kyneton	202	Bendigo	2RVIC	Rest of Vic.	VIC
20506221000	Primary Production	20202102804	202021028	Castlemaine Surrounds	20202	Heathcote - Castlemaine - Kyneton	202	Bendigo	2RVIC	Rest of Vic.	VIC
20511710000	Residential	20903120901	209031209	Eltham	20903	Nillumbik - Kinglake	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20512540000	Residential	20903120915	209031209	Eltham	20903	Nillumbik - Kinglake	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20519280000	Residential	21501139226	215011392	Stawell	21501	Grampians	215	North West	2RVIC	Rest of Vic.	VIC
20523090000	Residential	20605113415	206051134	St Kilda East	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20522370000	Residential	20605151405	206051514	St Kilda - West	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20528120000	Residential	20605151420	206051514	St Kilda - West	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20528570000	Residential	20605151414	206051514	St Kilda - West	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20528882000	Residential	20605151102	206051511	Port Melbourne Industrial	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20529360000	Residential	20605112830	206051128	Albert Park	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20529470000	Residential	20605151224	206051512	South Melbourne	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20530491000	Industrial	20605151102	206051511	Port Melbourne Industrial	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20530930000	Residential	20605112828	206051128	Albert Park	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20531000000	Residential	20605112828	206051128	Albert Park	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20532210000	Residential	20605112835	206051128	Albert Park	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20532410000	Residential	20605112828	206051128	Albert Park	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20533110000	Residential	20605151203	206051512	South Melbourne	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20533221000	Residential	20605151101	206051511	Port Melbourne Industrial	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20533233000	Commercial	20605112834	206051128	Albert Park	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20533261000	Residential	20605151203	206051512	South Melbourne	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20533270000	Commercial	20605112840	206051128	Albert Park	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20536410000	Residential	20503108702	205031087	Foster	20503	Gippsland - South West	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20539420000	Residential	20503108907	205031089	Korumburra	20503	Gippsland - South West	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20540970000	Residential	21701142119	217011421	Hamilton (Vic.)	21701	Glenelg - Southern Grampians	217	Warrnambool and South West	2RVIC	Rest of Vic.	VIC
20544740000	Commercial	20606151520	206061515	South Yarra - North	20606	Stonnington - West	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20547120000	Residential	20606151601	206061516	South Yarra - South	20606	Stonnington - West	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20549760000	Residential	20606113625	206061136	Prahran - Windsor	20606	Stonnington - West	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20554564000	Residential	20804119553	208041195	Malvern East	20804	Stonnington - East	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20555600000	Commercial	20804119550	208041195	Malvern East	20804	Stonnington - East	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20555660000	Residential	20804119431	208041194	Malvern - Glen Iris	20804	Stonnington - East	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20555940000	Residential	20804119443	208041194	Malvern - Glen Iris	20804	Stonnington - East	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20556230000	Residential	20804119407	208041194	Malvern - Glen Iris	20804	Stonnington - East	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20556521000	Residential	20804119515	208041195	Malvern East	20804	Stonnington - East	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20556812000	Commercial	20804119448	208041194	Malvern - Glen Iris	20804	Stonnington - East	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20562210000	Residential	20301103615	203011036	Winchelsea	20301	Barwon - West	203	Geelong	2RVIC	Rest of Vic.	VIC
20563100000	Residential	20303104908	203031049	Lorne - Anglesea	20303	Surf Coast - Bellarine Peninsula	203	Geelong	2RVIC	Rest of Vic.	VIC
20567050000	Residential	21503140503	215031405	Swan Hill Surrounds	21503	Murray River - Swan Hill	215	North West	2RVIC	Rest of Vic.	VIC
20568310000	Residential	20403107211	204031072	Towong	20403	Wodonga - Alpine	204	Hume	2RVIC	Rest of Vic.	VIC
20571390000	Other	20402106723	204021067	Wangaratta Surrounds	20402	Wangaratta - Benalla	204	Hume	2RVIC	Rest of Vic.	VIC
20571470000	Primary Production	20402106706	204021067	Wangaratta Surrounds	20402	Wangaratta - Benalla	204	Hume	2RVIC	Rest of Vic.	VIC
20572181000	Primary Production	20402106718	204021067	Wangaratta Surrounds	20402	Wangaratta - Benalla	204	Hume	2RVIC	Rest of Vic.	VIC
20572640000	Residential	21704147925	217041479	Warrnambool - North	21704	Warrnambool	217	Warrnambool and South West	2RVIC	Rest of Vic.	VIC
20584160000	Residential	20505110326	205051103	Sale	20505	Wellington	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20584440000	Residential	20505110328	205051103	Sale	20505	Wellington	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20588380000	Residential	20703116426	207031164	Box Hill North	20703	Whitehorse - West	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20587332000	Primary Production	21501139303	215011393	West Wimmera	21501	Grampians	215	North West	2RVIC	Rest of Vic.	VIC
20587790000	Commercial	20703116357	207031163	Box Hill	20703	Whitehorse - West	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20591630000	Residential	20703116316	207031163	Box Hill	20703	Whitehorse - West	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20593300000	Residential	20703116339	207031163	Box Hill	20703	Whitehorse - West	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20599410000	Residential	21104127202	211041272	Vermont	21104	Whitehorse - East	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20600520000	Residential	20703116105	207031161	Blackburn	20703	Whitehorse - West	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
20606930000	Residential	20904143609	209041436	South Morang - South	20904	Whittlesea - Wallan	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20608847000	Other	20904143319	209041433	Epping (Vic.) - West	20904	Whittlesea - Wallan	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20613420000	Residential	20904122343	209041223	Thomastown	20904	Whittlesea - Wallan	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20618650000	Residential	20904143125	209041431	Epping - East	20904	Whittlesea - Wallan	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20621310000	Residential	20403149114	204031491	Baranduda - Leneva	20403	Wodonga - Alpine	204	Hume	2RVIC	Rest of Vic.	VIC
20621460000	Residential	20403149224	204031492	Wodonga	20403	Wodonga - Alpine	204	Hume	2RVIC	Rest of Vic.	VIC
20622990000	Residential	20403107316	204031073	West Wodonga	20403	Wodonga - Alpine	204	Hume	2RVIC	Rest of Vic.	VIC
20623640000	Residential	20403107329	204031073	West Wodonga	20403	Wodonga - Alpine	204	Hume	2RVIC	Rest of Vic.	VIC
20626500000	Residential	21305146728	213051467	Werribee - East	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20626580000	Residential	21305146716	213051467	Werribee - East	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20631130000	Residential	21305158325	213051583	Tarneit - Central	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20631903760	Residential	20602111221	206021112	Thornbury	20602	Darebin - South	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631905500	Residential	20803118713	208031187	Chelsea Heights	20803	Kingston	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20631905960	Residential	21402137713	214021377	Dromana	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20631906600	Residential	21203156017	212031560	Cranbourne North - West	21203	Casey - South	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20631907700	Industrial	21304157708	213041577	Melton	21304	Melton - Bacchus Marsh	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20631910580	Residential	21003153706	210031537	Oak Park	21003	Moreland - North	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20631911250	Primary Production	21502139815	215021398	Mildura Surrounds	21502	Mildura	215	North West	2RVIC	Rest of Vic.	VIC
20631912200	Primary Production	20504109404	205041094	Churchill	20504	Latrobe Valley	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20631913430	Residential	20801117238	208011172	Hampton	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20631914110	Residential	20605113034	206051130	Port Melbourne	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631914610	Commercial	20904143610	209041436	South Morang - South	20904	Whittlesea - Wallan	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20631918050	Primary Production	21204156616	212041566	Keysborough - South	21204	Dandenong	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20631919120	Primary Production	20302104429	203021044	Leopold	20302	Geelong	203	Geelong	2RVIC	Rest of Vic.	VIC
20631923100	Residential	20403149226	204031492	Wodonga	20403	Wodonga - Alpine	204	Hume	2RVIC	Rest of Vic.	VIC
20631925250	Residential	20804119401	208041194	Malvern - Glen Iris	20804	Stonnington - East	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20631926900	Residential	20604111828	206041118	Docklands	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631933080	Residential	20202102608	202021026	Bendigo Surrounds - South	20202	Heathcote - Castlemaine - Kyneton	202	Bendigo	2RVIC	Rest of Vic.	VIC
20631933390	Commercial	20605112836	206051128	Albert Park	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631935260	Residential	21005124210	210051242	Broadmeadows	21005	Tullamarine - Broadmeadows	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20631935730	Residential	20402106649	204021066	Wangaratta	20402	Wangaratta - Benalla	204	Hume	2RVIC	Rest of Vic.	VIC
20631936790	Residential	21205156713	212051567	Clayton (North) - Notting Hill	21205	Monash	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20631941560	Residential	21305146412	213051464	Point Cook - East	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20631943540	Residential	20605112834	206051128	Albert Park	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631945440	Residential	20604150803	206041508	Southbank (West) - South Wharf	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631945640	Primary Production	20401105812	204011058	Nagambie	20401	Upper Goulburn Valley	204	Hume	2RVIC	Rest of Vic.	VIC
20631952760	Residential	20607151804	206071518	Richmond - North	20607	Yarra	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631953360	Residential	21305158033	213051580	Point Cook - North East	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20631953570	Residential	20606151523	206061515	South Yarra - North	20606	Stonnington - West	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631953690	Residential	21304157102	213041571	Brookfield	21304	Melton - Bacchus Marsh	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20631954430	Residential	21304136013	213041360	Taylors Hill	21304	Melton - Bacchus Marsh	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20631955290	Residential	21203156003	212031560	Cranbourne North - West	21203	Casey - South	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20631957560	Residential	21305146620	213051466	Point Cook - South	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20631960980	Primary Production	21502139523	215021395	Irymple	21502	Mildura	215	North West	2RVIC	Rest of Vic.	VIC
20631961150	Residential	21304136037	213041360	Taylors Hill	21304	Melton - Bacchus Marsh	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20631963120	Residential	20605112842	206051128	Albert Park	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631965560	Residential	20201102245	202011022	Kangaroo Flat - Golden Square	20201	Bendigo	202	Bendigo	2RVIC	Rest of Vic.	VIC
20631967000	Residential	20904122459	209041224	Wallan	20904	Whittlesea - Wallan	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20631968150	Residential	21402138228	214021382	Mount Martha	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20631968970	Residential	21205131934	212051319	Ashwood - Chadstone	21205	Monash	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20631970470	Residential	20401105508	204011055	Euroa	20401	Upper Goulburn Valley	204	Hume	2RVIC	Rest of Vic.	VIC
20631970870	Residential	21203130351	212031303	Cranbourne South	21203	Casey - South	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20631971350	Residential	20803119009	208031190	Mentone	20803	Kingston	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
20631972830	Residential	20401105637	204011056	Kilmore - Broadford	20401	Upper Goulburn Valley	204	Hume	2RVIC	Rest of Vic.	VIC
20631975640	Residential	20604112506	206041125	South Yarra - West	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631979060	Residential	20604150901	206041509	Southbank - East	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631980740	Residential	21203130452	212031304	Cranbourne West	21203	Casey - South	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20631981110	Residential	20604150919	206041509	Southbank - East	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631981920	Residential	20604150806	206041508	Southbank (West) - South Wharf	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631982020	Residential	20607113919	206071139	Abbotsford	20607	Yarra	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631982150	Residential	20904143716	209041437	Wollert	20904	Whittlesea - Wallan	209	Melbourne - North East	2GMEL	Greater Melbourne	VIC
20631982830	Primary Production	20401105705	204011057	Mansfield (Vic.)	20401	Upper Goulburn Valley	204	Hume	2RVIC	Rest of Vic.	VIC
20631985290	Primary Production	21503140412	215031404	Swan Hill	21503	Murray River - Swan Hill	215	North West	2RVIC	Rest of Vic.	VIC
20631985720	Residential	20601110606	206011106	Brunswick East	20601	Brunswick - Coburg	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20631986160	Residential	21401137046	214011370	Carrum Downs	21401	Frankston	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20631989070	Residential	21205132750	212051327	Wheelers Hill	21205	Monash	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20631992360	Residential	21205132539	212051325	Mulgrave	21205	Monash	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20631992910	Residential	20403107337	204031073	West Wodonga	20403	Wodonga - Alpine	204	Hume	2RVIC	Rest of Vic.	VIC
20631994390	Residential	20503109018	205031090	Leongatha	20503	Gippsland - South West	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
20631994740	Residential	21105127719	211051277	Kilsyth	21105	Yarra Ranges	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20631995870	Commercial	20303105105	203031051	Portarlington	20303	Surf Coast - Bellarine Peninsula	203	Geelong	2RVIC	Rest of Vic.	VIC
20631996680	Residential	20401105814	204011058	Nagambie	20401	Upper Goulburn Valley	204	Hume	2RVIC	Rest of Vic.	VIC
20632000370	Residential	21201155115	212011551	Pakenham - South East	21201	Cardinia	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
20632003550	Residential	21302134229	213021342	Altona Meadows	21302	Hobsons Bay	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20632005060	Residential	21301133804	213011338	Sunshine West	21301	Brimbank	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20634290000	Residential	21305159032	213051590	Wyndham Vale - South	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20634910000	Residential	21305146814	213051468	Werribee - West	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20635922000	Residential	21305159005	213051590	Wyndham Vale - South	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
20638720000	Residential	20607113902	206071139	Abbotsford	20607	Yarra	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20641410000	Residential	20607114220	206071142	Fitzroy	20607	Yarra	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20642471000	Residential	20607114123	206071141	Collingwood	20607	Yarra	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20644661000	Commercial	20607151712	206071517	Richmond (South) - Cremorne	20607	Yarra	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20650060000	Primary Production	21105127401	211051274	Belgrave - Selby	21105	Yarra Ranges	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20651040000	Residential	21105127403	211051274	Belgrave - Selby	21105	Yarra Ranges	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20658320000	Residential	21105128323	211051283	Mount Evelyn	21105	Yarra Ranges	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20659350000	Primary Production	21105127628	211051276	Healesville - Yarra Glen	21105	Yarra Ranges	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20659930000	Residential	21105127603	211051276	Healesville - Yarra Glen	21105	Yarra Ranges	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20661460000	Primary Production	21105128514	211051285	Wandin - Seville	21105	Yarra Ranges	211	Melbourne - Outer East	2GMEL	Greater Melbourne	VIC
20663853000	Residential	20403106925	204031069	Bright - Mount Beauty	20403	Wodonga - Alpine	204	Hume	2RVIC	Rest of Vic.	VIC
20663884000	Residential	20401105720	204011057	Mansfield (Vic.)	20401	Upper Goulburn Valley	204	Hume	2RVIC	Rest of Vic.	VIC
20664190000	Commercial	20604150502	206041505	Melbourne CBD - West	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20664600000	Residential	20604150309	206041503	Melbourne CBD - East	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20664810000	Commercial	20604150524	206041505	Melbourne CBD - West	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20664842000	Commercial	20604150501	206041505	Melbourne CBD - West	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20664851000	Commercial	20604150515	206041505	Melbourne CBD - West	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20664901000	Residential	20604150504	206041505	Melbourne CBD - West	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20664910000	Commercial	20604150516	206041505	Melbourne CBD - West	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20664921000	Commercial	20604150529	206041505	Melbourne CBD - West	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
20679480000	Parkland	21402138422	214021384	Rosebud - McCrae	21402	Mornington Peninsula	214	Mornington Peninsula	2GMEL	Greater Melbourne	VIC
20708590000	Parkland	20102101119	201021011	Daylesford	20102	Creswick - Daylesford - Ballan	201	Ballarat	2RVIC	Rest of Vic.	VIC
21301480000	Residential	20604150605	206041506	North Melbourne	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21302230000	Residential	20604150815	206041508	Southbank (West) - South Wharf	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21302270000	Residential	20604150916	206041509	Southbank - East	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21302510000	Residential	20703116358	207031163	Box Hill	20703	Whitehorse - West	207	Melbourne - Inner East	2GMEL	Greater Melbourne	VIC
21304160000	Residential	21203155819	212031558	Cranbourne East - South	21203	Casey - South	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
21306790000	Residential	20101100624	201011006	Delacombe	20101	Ballarat	201	Ballarat	2RVIC	Rest of Vic.	VIC
21307740000	Residential	20101100631	201011006	Delacombe	20101	Ballarat	201	Ballarat	2RVIC	Rest of Vic.	VIC
21308310000	Residential	21201154933	212011549	Pakenham - North East	21201	Cardinia	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
21309260000	Residential	20604112419	206041124	Parkville	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21309300000	Residential	21305157922	213051579	Manor Lakes - Quandong	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
21309710000	Industrial	20801117114	208011171	Highett (West) - Cheltenham	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
21311300000	Residential	20604150913	206041509	Southbank - East	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21311400000	Residential	21201155010	212011550	Pakenham - North West	21201	Cardinia	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
21313040000	Residential	20302148724	203021487	Grovedale - Mount Duneed	20302	Geelong	203	Geelong	2RVIC	Rest of Vic.	VIC
21313430000	Commercial	20604150427	206041504	Melbourne CBD - North	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21313460000	Residential	20604150408	206041504	Melbourne CBD - North	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21313600000	Residential	20604111819	206041118	Docklands	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21315070000	Commercial	20604150510	206041505	Melbourne CBD - West	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21315200000	Residential	20604150410	206041504	Melbourne CBD - North	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21315230000	Residential	20604150301	206041503	Melbourne CBD - East	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21316150000	Residential	20201101930	202011019	California Gully - Eaglehawk	20201	Bendigo	202	Bendigo	2RVIC	Rest of Vic.	VIC
21316710000	Residential	20201101925	202011019	California Gully - Eaglehawk	20201	Bendigo	202	Bendigo	2RVIC	Rest of Vic.	VIC
21318670000	Residential	20101100134	201011001	Alfredton	20101	Ballarat	201	Ballarat	2RVIC	Rest of Vic.	VIC
21319870000	Residential	20604150628	206041506	North Melbourne	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21320150000	Commercial	20604111743	206041117	Carlton	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21320530000	Residential	21005124649	210051246	Greenvale - Bulla	21005	Tullamarine - Broadmeadows	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
21329140000	Residential	20604111750	206041117	Carlton	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21327870000	Residential	20604112522	206041125	South Yarra - West	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21327970000	Residential	21304157612	213041576	Kurunjang - Toolern Vale	21304	Melton - Bacchus Marsh	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
21328320000	Residential	20604150426	206041504	Melbourne CBD - North	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21328350000	Residential	20604112518	206041125	South Yarra - West	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21328440000	Residential	20604150401	206041504	Melbourne CBD - North	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21328660000	Commercial	20604150503	206041505	Melbourne CBD - West	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21329200000	Residential	20605151428	206051514	St Kilda - West	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21330620000	Commercial	20604111737	206041117	Carlton	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21331550000	Residential	20605112837	206051128	Albert Park	20605	Port Phillip	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21333250000	Primary Production	21305146843	213051468	Werribee - West	21305	Wyndham	213	Melbourne - West	2GMEL	Greater Melbourne	VIC
21333790000	Residential	20303105339	203031053	Torquay	20303	Surf Coast - Bellarine Peninsula	203	Geelong	2RVIC	Rest of Vic.	VIC
21334360000	Residential	20604150319	206041503	Melbourne CBD - East	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21336180000	Residential	21201154618	212011546	Beaconsfield - Officer	21201	Cardinia	212	Melbourne - South East	2GMEL	Greater Melbourne	VIC
21339200000	Residential	20604151004	206041510	West Melbourne - Residential	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21339270000	Residential	20801117114	208011171	Highett (West) - Cheltenham	20801	Bayside	208	Melbourne - Inner South	2GMEL	Greater Melbourne	VIC
21339700000	Residential	20504149432	205041494	Traralgon - West	20504	Latrobe Valley	205	Latrobe - Gippsland	2RVIC	Rest of Vic.	VIC
21340930000	Residential	20604150304	206041503	Melbourne CBD - East	20604	Melbourne City	206	Melbourne - Inner	2GMEL	Greater Melbourne	VIC
21342850000	Residential	21005144552	210051445	Mickleham - Yuroke	21005	Tullamarine - Broadmeadows	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
21343120000	Residential	21005144519	210051445	Mickleham - Yuroke	21005	Tullamarine - Broadmeadows	210	Melbourne - North West	2GMEL	Greater Melbourne	VIC
20001250000	Primary Production	20403106928	204031069	Bright - Mount Beauty	20403	Wodonga - Alpine	204	Hume	2RVIC	Rest of Vic.	VIC
20001320000	Residential	20403106921	204031069	Bright - Mount Beauty	20403	Wodonga - Alpine	204	Hume	2RVIC	Rest of Vic.	VIC
20008090000	Residential	20101148211	201011482	Ballarat North - Invermay	20101	Ballarat	201	Ballarat	2RVIC	Rest of Vic.	VIC
20014000000	Residential	20101148402	201011484	Sebastopol - Redan	20101	Ballarat	201	Ballarat	2RVIC	Rest of Vic.	VIC
\.


-- Mirror abs_2021_mb_lookup as abs_2021_mb so the materialize/production SQL path
-- (sql/address_full_main.sql, which reads admin_bdys_202602.abs_2021_mb) produces
-- byte-identical output to the legacy path against the fixture. In production
-- gnaf-loader creates abs_2021_mb directly from shapefiles.
DROP TABLE IF EXISTS admin_bdys_202602.abs_2021_mb;
CREATE TABLE admin_bdys_202602.abs_2021_mb AS
SELECT
  (ROW_NUMBER() OVER (ORDER BY mb21_code))::int AS gid,
  mb21_code, mb_cat, sa1_21code, sa2_21code, sa2_21name,
  sa3_21code, sa3_21name, sa4_21code, sa4_21name,
  gcc_21code, gcc_21name, state
FROM admin_bdys_202602.abs_2021_mb_lookup;


-- Reset sequences to match loaded data
SELECT setval('gnaf_202602.address_principals_gid_seq', (SELECT COALESCE(MAX(gid), 0) FROM gnaf_202602.address_principals));
SELECT setval('gnaf_202602.address_aliases_gid_seq', (SELECT COALESCE(MAX(gid), 0) FROM gnaf_202602.address_aliases));
SELECT setval('gnaf_202602.streets_gid_seq', (SELECT COALESCE(MAX(gid), 0) FROM gnaf_202602.streets));
SELECT setval('gnaf_202602.street_aliases_gid_seq', (SELECT COALESCE(MAX(gid), 0) FROM gnaf_202602.street_aliases));
SELECT setval('gnaf_202602.address_principal_admin_boundaries_gid_seq', (SELECT COALESCE(MAX(gid), 0) FROM gnaf_202602.address_principal_admin_boundaries));
SELECT setval('gnaf_202602.address_alias_admin_boundaries_gid_seq', (SELECT COALESCE(MAX(gid), 0) FROM gnaf_202602.address_alias_admin_boundaries));

-- PART 3: Constraints + indexes
-- (FK constraints referencing rows outside the fixture subset are excluded:
--  address_aliases_fk2, locality_neighbour_lookup_fk2)
-- ============================================
--
-- PostgreSQL database dump
--


-- Dumped from database version 16.10 (Debian 16.10-1.pgdg12+1)
-- Dumped by pg_dump version 16.10 (Debian 16.10-1.pgdg12+1)

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
-- Name: address_alias_lookup address_alias_lookup_pk; Type: CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_alias_lookup
    ADD CONSTRAINT address_alias_lookup_pk PRIMARY KEY (alias_pid);


--
-- Name: address_aliases address_aliases_pk; Type: CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_aliases
    ADD CONSTRAINT address_aliases_pk PRIMARY KEY (gnaf_pid);


--
-- Name: address_principals address_principals_pk; Type: CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_principals
    ADD CONSTRAINT address_principals_pk PRIMARY KEY (gnaf_pid);


--
-- Name: address_secondary_lookup address_secondary_lookup_pk; Type: CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_secondary_lookup
    ADD CONSTRAINT address_secondary_lookup_pk PRIMARY KEY (secondary_pid);


--
-- Name: localities localities_pkey; Type: CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.localities
    ADD CONSTRAINT localities_pkey PRIMARY KEY (locality_pid);


--
-- Name: locality_aliases locality_aliases_pk; Type: CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.locality_aliases
    ADD CONSTRAINT locality_aliases_pk PRIMARY KEY (locality_pid, locality_alias_name);


--
-- Name: locality_neighbour_lookup locality_neighbour_lookup_pk; Type: CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.locality_neighbour_lookup
    ADD CONSTRAINT locality_neighbour_lookup_pk PRIMARY KEY (locality_pid, neighbour_locality_pid);


--
-- Name: street_aliases street_aliases_pk; Type: CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.street_aliases
    ADD CONSTRAINT street_aliases_pk PRIMARY KEY (street_locality_pid, full_alias_street_name);


--
-- Name: streets streets_pk; Type: CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.streets
    ADD CONSTRAINT streets_pk PRIMARY KEY (street_locality_pid);


--
-- Name: address_alias_lookup_alias_pid_idx; Type: INDEX; Schema: gnaf_202602; Owner: -
--

CREATE INDEX address_alias_lookup_alias_pid_idx ON gnaf_202602.address_alias_lookup USING btree (alias_pid);


--
-- Name: address_alias_lookup_principal_pid_idx; Type: INDEX; Schema: gnaf_202602; Owner: -
--

CREATE INDEX address_alias_lookup_principal_pid_idx ON gnaf_202602.address_alias_lookup USING btree (principal_pid);


--
-- Name: address_aliases_geom_idx; Type: INDEX; Schema: gnaf_202602; Owner: -
--

CREATE INDEX address_aliases_geom_idx ON gnaf_202602.address_aliases USING gist (geom);

ALTER TABLE gnaf_202602.address_aliases CLUSTER ON address_aliases_geom_idx;


--
-- Name: address_aliases_gid_idx; Type: INDEX; Schema: gnaf_202602; Owner: -
--

CREATE INDEX address_aliases_gid_idx ON gnaf_202602.address_aliases USING btree (gid);


--
-- Name: address_principal_admin_boundaries_gnaf_pid_idx; Type: INDEX; Schema: gnaf_202602; Owner: -
--

CREATE INDEX address_principal_admin_boundaries_gnaf_pid_idx ON gnaf_202602.address_principal_admin_boundaries USING btree (gnaf_pid);


--
-- Name: address_principals_geom_idx; Type: INDEX; Schema: gnaf_202602; Owner: -
--

CREATE INDEX address_principals_geom_idx ON gnaf_202602.address_principals USING gist (geom);

ALTER TABLE gnaf_202602.address_principals CLUSTER ON address_principals_geom_idx;


--
-- Name: address_principals_gid_idx; Type: INDEX; Schema: gnaf_202602; Owner: -
--

CREATE INDEX address_principals_gid_idx ON gnaf_202602.address_principals USING btree (gid);


--
-- Name: localities_geom_idx; Type: INDEX; Schema: gnaf_202602; Owner: -
--

CREATE INDEX localities_geom_idx ON gnaf_202602.localities USING gist (geom);

ALTER TABLE gnaf_202602.localities CLUSTER ON localities_geom_idx;


--
-- Name: localities_gid_idx; Type: INDEX; Schema: gnaf_202602; Owner: -
--

CREATE UNIQUE INDEX localities_gid_idx ON gnaf_202602.localities USING btree (gid);


--
-- Name: streets_geom_idx; Type: INDEX; Schema: gnaf_202602; Owner: -
--

CREATE INDEX streets_geom_idx ON gnaf_202602.streets USING gist (geom);

ALTER TABLE gnaf_202602.streets CLUSTER ON streets_geom_idx;


--
-- Name: streets_gid_idx; Type: INDEX; Schema: gnaf_202602; Owner: -
--

CREATE UNIQUE INDEX streets_gid_idx ON gnaf_202602.streets USING btree (gid);


--
-- Name: address_alias_lookup address_alias_lookup_fk1; Type: FK CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_alias_lookup
    ADD CONSTRAINT address_alias_lookup_fk1 FOREIGN KEY (alias_pid) REFERENCES gnaf_202602.address_aliases(gnaf_pid);


--
-- Name: address_alias_lookup address_alias_lookup_fk2; Type: FK CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_alias_lookup
    ADD CONSTRAINT address_alias_lookup_fk2 FOREIGN KEY (principal_pid) REFERENCES gnaf_202602.address_principals(gnaf_pid);


--
-- Name: address_aliases address_aliases_fk1; Type: FK CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_aliases
    ADD CONSTRAINT address_aliases_fk1 FOREIGN KEY (locality_pid) REFERENCES gnaf_202602.localities(locality_pid);


--
--


--
-- Name: address_principals address_principals_fk1; Type: FK CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_principals
    ADD CONSTRAINT address_principals_fk1 FOREIGN KEY (locality_pid) REFERENCES gnaf_202602.localities(locality_pid);


--
-- Name: address_principals address_principals_fk2; Type: FK CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.address_principals
    ADD CONSTRAINT address_principals_fk2 FOREIGN KEY (street_locality_pid) REFERENCES gnaf_202602.streets(street_locality_pid);


--
-- Name: locality_aliases locality_aliases_fk1; Type: FK CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.locality_aliases
    ADD CONSTRAINT locality_aliases_fk1 FOREIGN KEY (locality_pid) REFERENCES gnaf_202602.localities(locality_pid);


--
-- Name: locality_neighbour_lookup locality_neighbour_lookup_fk1; Type: FK CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.locality_neighbour_lookup
    ADD CONSTRAINT locality_neighbour_lookup_fk1 FOREIGN KEY (locality_pid) REFERENCES gnaf_202602.localities(locality_pid);


--
--


--
-- Name: street_aliases street_aliases_fk1; Type: FK CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.street_aliases
    ADD CONSTRAINT street_aliases_fk1 FOREIGN KEY (street_locality_pid) REFERENCES gnaf_202602.streets(street_locality_pid);


--
-- Name: streets streets_fk1; Type: FK CONSTRAINT; Schema: gnaf_202602; Owner: -
--

ALTER TABLE ONLY gnaf_202602.streets
    ADD CONSTRAINT streets_fk1 FOREIGN KEY (locality_pid) REFERENCES gnaf_202602.localities(locality_pid);


--
-- PostgreSQL database dump complete
--





-- ============================================
