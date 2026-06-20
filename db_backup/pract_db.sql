--
-- PostgreSQL database dump
--

\restrict 6H2IOscjQmzahbc9c9G0QW4b81PtnO6o69IWC1GufO9CS1vn87rQjpCk0HY1Kgo

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-06-14 22:03:07

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
-- TOC entry 247 (class 1255 OID 17035)
-- Name: check_reading_status(); Type: FUNCTION; Schema: public; Owner: user1
--

CREATE FUNCTION public.check_reading_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_min NUMERIC;
    v_max NUMERIC;
    v_numeric_value NUMERIC;
    v_ok_id INT;
    v_warning_id INT;
    v_error_id INT;
BEGIN
    SELECT status_id INTO v_ok_id FROM "status" WHERE "name" ILIKE 'OK' LIMIT 1;
    SELECT status_id INTO v_warning_id FROM "status" WHERE "name" ILIKE 'WARNING' LIMIT 1;
    SELECT status_id INTO v_error_id FROM "status" WHERE "name" ILIKE 'ERROR' LIMIT 1;

    SELECT min_value, max_value 
    INTO v_min, v_max 
    FROM "reading_type" 
    WHERE "reading_type_id" = NEW.reading_type_id;

    IF v_min IS NULL AND v_max IS NULL THEN
        NEW.status_id := v_ok_id;
        RETURN NEW;
    END IF;

    BEGIN
        v_numeric_value := CAST(NEW.value AS NUMERIC);
    EXCEPTION WHEN others THEN
        v_numeric_value := NULL;
    END;

    IF v_numeric_value IS NULL THEN
        NEW.status_id := v_error_id;
        RETURN NEW;
    END IF;

    IF v_min IS NOT NULL AND v_numeric_value < v_min THEN
        NEW.status_id := v_error_id;
    ELSIF v_max IS NOT NULL AND v_numeric_value > v_max THEN
        NEW.status_id := v_warning_id;
    ELSE
        NEW.status_id := v_ok_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_reading_status() OWNER TO user1;

--
-- TOC entry 248 (class 1255 OID 17036)
-- Name: clean_expired_sessions(); Type: FUNCTION; Schema: public; Owner: user1
--

CREATE FUNCTION public.clean_expired_sessions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "session" 
    WHERE "user_id" = NEW."user_id" 
      AND "session_end_date_time" < NOW();

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.clean_expired_sessions() OWNER TO user1;

--
-- TOC entry 249 (class 1255 OID 17037)
-- Name: clean_old_reading_logs(); Type: FUNCTION; Schema: public; Owner: user1
--

CREATE FUNCTION public.clean_old_reading_logs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM reading_log 
    WHERE write_date_time < NOW() - INTERVAL '1 year';
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.clean_old_reading_logs() OWNER TO user1;

--
-- TOC entry 250 (class 1255 OID 17038)
-- Name: create_new_user(character varying, character varying, character varying, character varying, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: user1
--

CREATE PROCEDURE public.create_new_user(IN p_login character varying, IN p_hashed_password character varying, IN p_first_name character varying, IN p_last_name character varying, IN p_second_name character varying, IN p_role_name character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INT;
    v_role_id INT;
BEGIN
    SELECT role_id INTO v_role_id FROM role WHERE name = p_role_name;
    
    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Роль % не найдена', p_role_name;
    END IF;

    INSERT INTO "user" (login, hashed_password, first_name, last_name, second_name)
    VALUES (p_login, p_hashed_password, p_first_name, p_last_name, p_second_name)
    RETURNING user_id INTO v_user_id;

    INSERT INTO user_role (user_id, role_id)
    VALUES (v_user_id, v_role_id);

    RAISE NOTICE 'Пользователь % успешно создан с ролью %', p_login, p_role_name;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Пользователь с логином % уже существует', p_login;
    WHEN OTHERS THEN
        RAISE;
END;
$$;


ALTER PROCEDURE public.create_new_user(IN p_login character varying, IN p_hashed_password character varying, IN p_first_name character varying, IN p_last_name character varying, IN p_second_name character varying, IN p_role_name character varying) OWNER TO user1;

--
-- TOC entry 251 (class 1255 OID 17039)
-- Name: get_equipment_logs(integer); Type: FUNCTION; Schema: public; Owner: user1
--

CREATE FUNCTION public.get_equipment_logs(p_id integer) RETURNS TABLE(reading_log_id integer, write_date_time timestamp with time zone, value character varying, status_id integer)
    LANGUAGE sql
    AS $$ 
    SELECT "reading_log_id", "write_date_time", "value", "status_id" 
    FROM "reading_log" 
    WHERE "equipment_id" = p_id;
$$;


ALTER FUNCTION public.get_equipment_logs(p_id integer) OWNER TO user1;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 17040)
-- Name: equipment; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.equipment (
    equipment_id integer NOT NULL,
    status_id integer NOT NULL,
    serial_number character varying(100) NOT NULL,
    name character varying(150) NOT NULL,
    model character varying(100) NOT NULL,
    ip_address character varying(39)
);


ALTER TABLE public.equipment OWNER TO user1;

--
-- TOC entry 220 (class 1259 OID 17048)
-- Name: equipment_equipment_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.equipment_equipment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipment_equipment_id_seq OWNER TO user1;

--
-- TOC entry 5124 (class 0 OID 0)
-- Dependencies: 220
-- Name: equipment_equipment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.equipment_equipment_id_seq OWNED BY public.equipment.equipment_id;


--
-- TOC entry 221 (class 1259 OID 17049)
-- Name: reading_log; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.reading_log (
    reading_log_id integer NOT NULL,
    equipment_id integer NOT NULL,
    status_id integer NOT NULL,
    reading_type_id integer NOT NULL,
    write_date_time timestamp with time zone DEFAULT now() NOT NULL,
    value character varying(50) NOT NULL
);


ALTER TABLE public.reading_log OWNER TO user1;

--
-- TOC entry 222 (class 1259 OID 17059)
-- Name: reading_log_reading_log_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.reading_log_reading_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reading_log_reading_log_id_seq OWNER TO user1;

--
-- TOC entry 5127 (class 0 OID 0)
-- Dependencies: 222
-- Name: reading_log_reading_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.reading_log_reading_log_id_seq OWNED BY public.reading_log.reading_log_id;


--
-- TOC entry 223 (class 1259 OID 17060)
-- Name: reading_type; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.reading_type (
    reading_type_id integer NOT NULL,
    identifier character varying(19) NOT NULL,
    name character varying(50) NOT NULL,
    unit character varying(20),
    min_value numeric(10,2),
    max_value numeric(10,2)
);


ALTER TABLE public.reading_type OWNER TO user1;

--
-- TOC entry 224 (class 1259 OID 17066)
-- Name: reading_type_reading_type_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.reading_type_reading_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reading_type_reading_type_id_seq OWNER TO user1;

--
-- TOC entry 5130 (class 0 OID 0)
-- Dependencies: 224
-- Name: reading_type_reading_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.reading_type_reading_type_id_seq OWNED BY public.reading_type.reading_type_id;


--
-- TOC entry 225 (class 1259 OID 17067)
-- Name: role; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.role (
    role_id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.role OWNER TO user1;

--
-- TOC entry 226 (class 1259 OID 17072)
-- Name: role_role_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.role_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_role_id_seq OWNER TO user1;

--
-- TOC entry 5133 (class 0 OID 0)
-- Dependencies: 226
-- Name: role_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.role_role_id_seq OWNED BY public.role.role_id;


--
-- TOC entry 227 (class 1259 OID 17073)
-- Name: session; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.session (
    session_id integer NOT NULL,
    user_id integer NOT NULL,
    refresh_token text NOT NULL,
    device character varying(255),
    session_end_date_time timestamp with time zone NOT NULL
);


ALTER TABLE public.session OWNER TO user1;

--
-- TOC entry 228 (class 1259 OID 17082)
-- Name: session_session_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.session_session_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.session_session_id_seq OWNER TO user1;

--
-- TOC entry 5136 (class 0 OID 0)
-- Dependencies: 228
-- Name: session_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.session_session_id_seq OWNED BY public.session.session_id;


--
-- TOC entry 229 (class 1259 OID 17083)
-- Name: status; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.status (
    status_id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.status OWNER TO user1;

--
-- TOC entry 230 (class 1259 OID 17088)
-- Name: status_status_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.status_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.status_status_id_seq OWNER TO user1;

--
-- TOC entry 5139 (class 0 OID 0)
-- Dependencies: 230
-- Name: status_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.status_status_id_seq OWNED BY public.status.status_id;


--
-- TOC entry 231 (class 1259 OID 17089)
-- Name: user; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public."user" (
    user_id integer NOT NULL,
    login character varying(50) NOT NULL,
    hashed_password character varying(255) NOT NULL,
    second_name character varying(100) NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100)
);


ALTER TABLE public."user" OWNER TO user1;

--
-- TOC entry 232 (class 1259 OID 17099)
-- Name: user_role; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.user_role (
    user_id integer NOT NULL,
    role_id integer NOT NULL
);


ALTER TABLE public.user_role OWNER TO user1;

--
-- TOC entry 233 (class 1259 OID 17104)
-- Name: user_user_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.user_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_user_id_seq OWNER TO user1;

--
-- TOC entry 5143 (class 0 OID 0)
-- Dependencies: 233
-- Name: user_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.user_user_id_seq OWNED BY public."user".user_id;


--
-- TOC entry 234 (class 1259 OID 17105)
-- Name: view_latest_equipment_readings; Type: VIEW; Schema: public; Owner: user1
--

CREATE VIEW public.view_latest_equipment_readings AS
 WITH ranked_readings AS (
         SELECT rl.equipment_id,
            rl.reading_type_id,
            rl.write_date_time,
            rl.value,
            rl.status_id,
            row_number() OVER (PARTITION BY rl.equipment_id, rl.reading_type_id ORDER BY rl.write_date_time DESC) AS rn
           FROM public.reading_log rl
        )
 SELECT eq.serial_number,
    rt.identifier AS metric_key,
    rt.name AS label,
    rr.value,
    rt.unit,
    st.name AS status,
    rr.write_date_time AS datetime,
    rt.min_value,
    rt.max_value
   FROM (((ranked_readings rr
     JOIN public.equipment eq ON ((rr.equipment_id = eq.equipment_id)))
     JOIN public.reading_type rt ON ((rr.reading_type_id = rt.reading_type_id)))
     JOIN public.status st ON ((rr.status_id = st.status_id)))
  WHERE (rr.rn = 1);


ALTER VIEW public.view_latest_equipment_readings OWNER TO user1;

--
-- TOC entry 235 (class 1259 OID 17110)
-- Name: view_new_equipment; Type: VIEW; Schema: public; Owner: user1
--

CREATE VIEW public.view_new_equipment AS
 SELECT equipment_id,
    status_id,
    serial_number,
    name,
    model,
    ip_address
   FROM public.equipment
  WHERE ((name)::text = 'New Equipment'::text);


ALTER VIEW public.view_new_equipment OWNER TO user1;

--
-- TOC entry 4905 (class 2604 OID 17114)
-- Name: equipment equipment_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment ALTER COLUMN equipment_id SET DEFAULT nextval('public.equipment_equipment_id_seq'::regclass);


--
-- TOC entry 4906 (class 2604 OID 17115)
-- Name: reading_log reading_log_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_log ALTER COLUMN reading_log_id SET DEFAULT nextval('public.reading_log_reading_log_id_seq'::regclass);


--
-- TOC entry 4908 (class 2604 OID 17116)
-- Name: reading_type reading_type_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_type ALTER COLUMN reading_type_id SET DEFAULT nextval('public.reading_type_reading_type_id_seq'::regclass);


--
-- TOC entry 4909 (class 2604 OID 17117)
-- Name: role role_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.role ALTER COLUMN role_id SET DEFAULT nextval('public.role_role_id_seq'::regclass);


--
-- TOC entry 4910 (class 2604 OID 17118)
-- Name: session session_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.session ALTER COLUMN session_id SET DEFAULT nextval('public.session_session_id_seq'::regclass);


--
-- TOC entry 4911 (class 2604 OID 17119)
-- Name: status status_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.status ALTER COLUMN status_id SET DEFAULT nextval('public.status_status_id_seq'::regclass);


--
-- TOC entry 4912 (class 2604 OID 17120)
-- Name: user user_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public."user" ALTER COLUMN user_id SET DEFAULT nextval('public.user_user_id_seq'::regclass);


--
-- TOC entry 5102 (class 0 OID 17040)
-- Dependencies: 219
-- Data for Name: equipment; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.equipment (equipment_id, status_id, serial_number, name, model, ip_address) FROM stdin;
11	1	SerNumEx	Мегафон Н3	Other	192.168.100.192
12	1	SerNumEx2	Ex Eq	new model	Some IP
\.


--
-- TOC entry 5104 (class 0 OID 17049)
-- Dependencies: 221
-- Data for Name: reading_log; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.reading_log (reading_log_id, equipment_id, status_id, reading_type_id, write_date_time, value) FROM stdin;
309574	11	1	29	2026-06-11 09:51:58.698148+03	n/a
309575	11	1	30	2026-06-11 09:51:58.90394+03	n/a
309576	11	1	31	2026-06-11 09:51:59.008717+03	+30
309577	11	1	32	2026-06-11 09:51:59.115386+03	-47.8
309578	11	1	33	2026-06-11 09:51:59.207184+03	OFF due to front...
309579	11	1	34	2026-06-11 09:51:59.318145+03	HDB3
309580	11	1	29	2026-06-11 09:52:09.624572+03	n/a
309581	11	1	30	2026-06-11 09:52:09.720782+03	n/a
309582	11	1	31	2026-06-11 09:52:09.82816+03	+30
309583	11	1	32	2026-06-11 09:52:09.93555+03	-47.8
309584	11	1	33	2026-06-11 09:52:10.042838+03	OFF due to front...
309585	11	1	34	2026-06-11 09:52:10.131157+03	HDB3
309586	11	1	29	2026-06-11 09:52:20.386546+03	n/a
309587	11	1	30	2026-06-11 09:52:20.479244+03	n/a
309588	11	1	31	2026-06-11 09:52:20.588369+03	+31
309589	11	1	32	2026-06-11 09:52:20.697426+03	-47.8
309590	11	1	33	2026-06-11 09:52:20.789038+03	OFF due to front...
309591	11	1	34	2026-06-11 09:52:20.897339+03	HDB3
309592	11	1	29	2026-06-11 09:52:31.211556+03	n/a
309593	11	1	30	2026-06-11 09:52:31.301702+03	n/a
309594	11	1	31	2026-06-11 09:52:31.4077+03	+30
309595	11	1	32	2026-06-11 09:52:31.51562+03	-47.4
309596	11	1	33	2026-06-11 09:52:31.6127+03	OFF due to front...
309597	11	1	34	2026-06-11 09:52:31.717363+03	HDB3
309598	11	1	29	2026-06-11 09:52:42.021317+03	n/a
309599	11	1	30	2026-06-11 09:52:42.11751+03	n/a
309600	11	1	31	2026-06-11 09:52:42.236414+03	+30
309601	11	1	32	2026-06-11 09:52:42.319832+03	-47.3
309602	11	1	33	2026-06-11 09:52:42.383005+03	OFF due to front...
309603	11	1	34	2026-06-11 09:52:42.476762+03	HDB3
309604	11	1	29	2026-06-11 09:52:52.708437+03	n/a
309605	11	1	30	2026-06-11 09:52:52.815489+03	n/a
309606	11	1	31	2026-06-11 09:52:52.910758+03	+30
309607	11	1	32	2026-06-11 09:52:52.972715+03	-47.8
309608	11	1	33	2026-06-11 09:52:53.06734+03	OFF due to front...
309609	11	1	34	2026-06-11 09:52:53.13581+03	HDB3
309610	11	1	29	2026-06-11 09:53:03.475232+03	n/a
309611	11	1	30	2026-06-11 09:53:03.586116+03	n/a
309612	11	1	31	2026-06-11 09:53:03.678834+03	+30
309613	11	1	32	2026-06-11 09:53:03.790389+03	-47.7
309614	11	1	33	2026-06-11 09:53:03.896464+03	OFF due to front...
309615	11	1	34	2026-06-11 09:53:04.006449+03	HDB3
309616	11	1	29	2026-06-11 09:53:14.36331+03	n/a
309617	11	1	30	2026-06-11 09:53:14.472807+03	n/a
309618	11	1	31	2026-06-11 09:53:14.565144+03	+30
309619	11	1	32	2026-06-11 09:53:14.67715+03	-47.4
309620	11	1	33	2026-06-11 09:53:14.767253+03	OFF due to front...
309621	11	1	34	2026-06-11 09:53:14.880969+03	HDB3
309622	11	1	29	2026-06-11 09:53:25.229956+03	n/a
309623	11	1	30	2026-06-11 09:53:25.29273+03	n/a
309624	11	1	31	2026-06-11 09:53:25.386149+03	+30
309625	11	1	32	2026-06-11 09:53:25.500163+03	-47.2
309626	11	1	33	2026-06-11 09:53:25.604742+03	OFF due to front...
309627	11	1	34	2026-06-11 09:53:25.695584+03	HDB3
309628	11	1	29	2026-06-11 09:53:35.994868+03	n/a
309629	11	1	30	2026-06-11 09:53:36.083159+03	n/a
309630	11	1	31	2026-06-11 09:53:36.190758+03	+30
309631	11	1	32	2026-06-11 09:53:36.301439+03	-47.5
309632	11	1	33	2026-06-11 09:53:36.408974+03	OFF due to front...
309633	11	1	34	2026-06-11 09:53:36.49988+03	HDB3
309634	11	1	29	2026-06-11 09:53:46.846729+03	n/a
309635	11	1	30	2026-06-11 09:53:46.94735+03	n/a
309636	11	1	31	2026-06-11 09:53:47.041175+03	+30
309637	11	1	32	2026-06-11 09:53:47.103304+03	-47.4
309638	11	1	33	2026-06-11 09:53:47.211425+03	OFF due to front...
309639	11	1	34	2026-06-11 09:53:47.304668+03	HDB3
309640	11	1	29	2026-06-11 09:53:57.658804+03	n/a
309641	11	1	30	2026-06-11 09:53:57.761979+03	n/a
309642	11	1	31	2026-06-11 09:53:57.8562+03	+30
309643	11	1	32	2026-06-11 09:53:57.963855+03	-47.5
309644	11	1	33	2026-06-11 09:53:58.071881+03	OFF due to front...
309645	11	1	34	2026-06-11 09:53:58.165942+03	HDB3
309646	11	1	29	2026-06-11 09:54:08.471041+03	n/a
309647	11	1	30	2026-06-11 09:54:08.563502+03	n/a
309648	11	1	31	2026-06-11 09:54:08.67814+03	+30
309649	11	1	32	2026-06-11 09:54:08.784292+03	-47.6
309650	11	1	33	2026-06-11 09:54:08.880324+03	OFF due to front...
309651	11	1	34	2026-06-11 09:54:08.986654+03	HDB3
309652	11	1	29	2026-06-11 09:54:19.226347+03	n/a
309653	11	1	30	2026-06-11 09:54:19.34197+03	n/a
309654	11	1	31	2026-06-11 09:54:19.44047+03	+30
309655	11	1	32	2026-06-11 09:54:19.534983+03	-47.2
309656	11	1	33	2026-06-11 09:54:19.599321+03	OFF due to front...
309657	11	1	34	2026-06-11 09:54:19.719817+03	HDB3
309658	11	1	29	2026-06-11 09:54:30.060992+03	n/a
309659	11	1	30	2026-06-11 09:54:30.171665+03	n/a
309660	11	1	31	2026-06-11 09:54:30.280734+03	+30
309661	11	1	32	2026-06-11 09:54:30.373913+03	-47.7
309662	11	1	33	2026-06-11 09:54:30.481949+03	OFF due to front...
309663	11	1	34	2026-06-11 09:54:30.5772+03	HDB3
309664	11	1	29	2026-06-11 09:54:40.926707+03	n/a
309665	11	1	30	2026-06-11 09:54:41.036477+03	n/a
309666	11	1	31	2026-06-11 09:54:41.135299+03	+30
309667	11	1	32	2026-06-11 09:54:41.238166+03	-47.6
309668	11	1	33	2026-06-11 09:54:41.332934+03	OFF due to front...
309669	11	1	34	2026-06-11 09:54:41.395766+03	HDB3
309670	11	1	29	2026-06-11 09:54:51.705033+03	n/a
309671	11	1	30	2026-06-11 09:54:51.792912+03	n/a
309672	11	1	31	2026-06-11 09:54:51.901044+03	+30
309673	11	1	32	2026-06-11 09:54:52.009213+03	-47.6
309674	11	1	33	2026-06-11 09:54:52.103122+03	OFF due to front...
309675	11	1	34	2026-06-11 09:54:52.215021+03	HDB3
309676	11	1	29	2026-06-11 09:55:02.502354+03	n/a
309677	11	1	30	2026-06-11 09:55:02.611129+03	n/a
309678	11	1	31	2026-06-11 09:55:02.716605+03	+31
309679	11	1	32	2026-06-11 09:55:02.821489+03	-47.6
309680	11	1	33	2026-06-11 09:55:02.925302+03	OFF due to front...
309681	11	1	34	2026-06-11 09:55:03.024298+03	HDB3
309682	11	1	29	2026-06-11 09:55:13.330568+03	n/a
309683	11	1	30	2026-06-11 09:55:13.426236+03	n/a
309684	11	1	31	2026-06-11 09:55:13.537639+03	+30
309685	11	1	32	2026-06-11 09:55:13.62861+03	-47.4
309686	11	1	33	2026-06-11 09:55:13.739475+03	OFF due to front...
309687	11	1	34	2026-06-11 09:55:13.844761+03	HDB3
309688	11	1	29	2026-06-11 09:55:24.091738+03	n/a
309689	11	1	30	2026-06-11 09:55:24.18307+03	n/a
309690	11	1	31	2026-06-11 09:55:24.297055+03	+30
309691	11	1	32	2026-06-11 09:55:24.400502+03	-47.7
309692	11	1	33	2026-06-11 09:55:24.492984+03	OFF due to front...
309693	11	1	34	2026-06-11 09:55:24.601484+03	HDB3
309694	11	1	29	2026-06-11 09:55:34.846895+03	n/a
309695	11	1	30	2026-06-11 09:55:34.95364+03	n/a
309696	11	1	31	2026-06-11 09:55:35.049348+03	+30
309697	11	1	32	2026-06-11 09:55:35.158548+03	-47.9
309698	11	1	33	2026-06-11 09:55:35.269299+03	OFF due to front...
309699	11	1	34	2026-06-11 09:55:35.355176+03	HDB3
309700	11	1	29	2026-06-11 09:55:45.6141+03	n/a
309701	11	1	30	2026-06-11 09:55:45.706174+03	n/a
309702	11	1	31	2026-06-11 09:55:45.815154+03	+30
309703	11	1	32	2026-06-11 09:55:45.926747+03	-48.3
309704	11	1	33	2026-06-11 09:55:46.018216+03	OFF due to front...
309705	11	1	34	2026-06-11 09:55:46.129312+03	HDB3
309706	11	1	29	2026-06-11 09:55:56.433256+03	n/a
309707	11	1	30	2026-06-11 09:55:56.581975+03	n/a
309708	11	2	31	2026-06-11 09:55:56.67794+03	+30
309709	11	1	32	2026-06-11 09:55:56.791699+03	-48.7
309710	11	1	33	2026-06-11 09:55:56.895126+03	OFF due to front...
309711	11	1	34	2026-06-11 09:55:56.995989+03	HDB3
309712	11	1	29	2026-06-11 09:56:07.341548+03	n/a
309713	11	1	30	2026-06-11 09:56:07.447529+03	n/a
309714	11	2	31	2026-06-11 09:56:07.545259+03	+30
309715	11	1	32	2026-06-11 09:56:07.65414+03	-48.6
309716	11	1	33	2026-06-11 09:56:07.749255+03	OFF due to front...
309717	11	1	34	2026-06-11 09:56:07.85813+03	HDB3
309718	11	1	29	2026-06-11 09:56:18.160382+03	n/a
309719	11	1	30	2026-06-11 09:56:18.25159+03	n/a
309720	11	2	31	2026-06-11 09:56:18.364772+03	+31
309721	11	1	32	2026-06-11 09:56:18.458108+03	-48.5
309722	11	1	33	2026-06-11 09:56:18.5655+03	OFF due to front...
309723	11	1	34	2026-06-11 09:56:18.676203+03	HDB3
309724	11	1	29	2026-06-11 09:56:29.039984+03	n/a
309725	11	1	30	2026-06-11 09:56:29.140606+03	n/a
309726	11	3	31	2026-06-11 09:56:29.234088+03	+31
309727	11	1	32	2026-06-11 09:56:29.34635+03	-48.6
309728	11	1	33	2026-06-11 09:56:29.450894+03	OFF due to front...
309729	11	1	34	2026-06-11 09:56:29.542613+03	HDB3
309730	11	1	29	2026-06-11 09:56:39.838878+03	n/a
309731	11	1	30	2026-06-11 09:56:39.94671+03	n/a
309732	11	3	31	2026-06-11 09:56:40.039996+03	+30
309733	11	1	32	2026-06-11 09:56:40.16041+03	-48.4
309734	11	1	33	2026-06-11 09:56:40.256007+03	OFF due to front...
309735	11	1	34	2026-06-11 09:56:40.346691+03	HDB3
309736	11	1	29	2026-06-11 09:56:50.603546+03	n/a
309737	11	1	30	2026-06-11 09:56:50.695173+03	n/a
309738	11	1	31	2026-06-11 09:56:50.804838+03	+31
309739	11	1	32	2026-06-11 09:56:50.897447+03	-48.8
309740	11	1	33	2026-06-11 09:56:51.005929+03	OFF due to front...
309741	11	1	34	2026-06-11 09:56:51.117023+03	HDB3
309742	11	1	29	2026-06-11 09:57:01.458513+03	n/a
309743	11	1	30	2026-06-11 09:57:01.565199+03	n/a
309744	11	1	31	2026-06-11 09:57:01.658979+03	+30
309745	11	1	32	2026-06-11 09:57:01.766143+03	-48.8
309746	11	1	33	2026-06-11 09:57:01.87548+03	OFF due to front...
309747	11	1	34	2026-06-11 09:57:01.966667+03	HDB3
309748	11	1	29	2026-06-11 09:57:12.216657+03	n/a
309749	11	1	30	2026-06-11 09:57:12.31037+03	n/a
309750	11	1	31	2026-06-11 09:57:12.417827+03	+30
309751	11	1	32	2026-06-11 09:57:12.529682+03	-49.0
309752	11	1	33	2026-06-11 09:57:12.620949+03	OFF due to front...
309753	11	1	34	2026-06-11 09:57:12.729804+03	HDB3
309754	11	1	29	2026-06-11 09:57:23.032751+03	n/a
309755	11	1	30	2026-06-11 09:57:23.13195+03	n/a
309756	11	1	31	2026-06-11 09:57:23.236587+03	+30
309757	11	1	32	2026-06-11 09:57:23.346511+03	-48.9
309758	11	1	33	2026-06-11 09:57:23.439045+03	OFF due to front...
309759	11	1	34	2026-06-11 09:57:23.546738+03	HDB3
309760	11	1	29	2026-06-11 09:57:33.844832+03	n/a
309761	11	1	30	2026-06-11 09:57:33.966248+03	n/a
309762	11	1	31	2026-06-11 09:57:34.053421+03	+31
309763	11	1	32	2026-06-11 09:57:34.163231+03	-49.0
309764	11	1	33	2026-06-11 09:57:34.271434+03	OFF due to front...
309765	11	1	34	2026-06-11 09:57:34.364989+03	HDB3
309766	11	1	29	2026-06-11 09:57:44.738393+03	n/a
309767	11	1	30	2026-06-11 09:57:44.828036+03	n/a
309768	11	1	31	2026-06-11 09:57:44.93521+03	+30
309769	11	1	32	2026-06-11 09:57:45.027463+03	-48.9
309770	11	1	33	2026-06-11 09:57:45.141351+03	OFF due to front...
309771	11	1	34	2026-06-11 09:57:45.247646+03	HDB3
309772	11	1	29	2026-06-11 09:57:55.552122+03	n/a
309773	11	1	30	2026-06-11 09:57:55.647889+03	n/a
309774	11	1	31	2026-06-11 09:57:55.756443+03	+30
309775	11	1	32	2026-06-11 09:57:55.852967+03	-48.9
309776	11	1	33	2026-06-11 09:57:55.91692+03	OFF due to front...
309777	11	1	34	2026-06-11 09:57:56.009867+03	HDB3
309778	11	1	29	2026-06-11 09:58:06.265725+03	n/a
309779	11	1	30	2026-06-11 09:58:06.376434+03	n/a
309780	11	1	31	2026-06-11 09:58:06.466324+03	+30
309781	11	1	32	2026-06-11 09:58:06.576596+03	-48.9
309782	11	1	33	2026-06-11 09:58:06.684947+03	OFF due to front...
309783	11	1	34	2026-06-11 09:58:06.781071+03	HDB3
309784	11	1	29	2026-06-11 09:58:17.083716+03	n/a
309785	11	1	30	2026-06-11 09:58:17.176597+03	n/a
309786	11	1	31	2026-06-11 09:58:17.282701+03	+31
309787	11	1	32	2026-06-11 09:58:17.392441+03	-49.0
309788	11	1	33	2026-06-11 09:58:17.487071+03	OFF due to front...
309789	11	1	34	2026-06-11 09:58:17.599416+03	HDB3
309790	11	1	29	2026-06-11 09:58:27.900258+03	n/a
309791	11	1	30	2026-06-11 09:58:27.997247+03	n/a
309792	11	1	31	2026-06-11 09:58:28.10446+03	+30
309793	11	1	32	2026-06-11 09:58:28.197649+03	-48.8
309794	11	1	33	2026-06-11 09:58:28.259541+03	OFF due to front...
309795	11	1	34	2026-06-11 09:58:28.35342+03	HDB3
309796	11	1	29	2026-06-11 09:58:38.60521+03	n/a
309797	11	1	30	2026-06-11 09:58:38.693055+03	n/a
309798	11	1	31	2026-06-11 09:58:38.761805+03	+30
309799	11	1	32	2026-06-11 09:58:38.855814+03	-48.7
309800	11	1	33	2026-06-11 09:58:38.961912+03	OFF due to front...
309801	11	1	34	2026-06-11 09:58:39.061057+03	HDB3
309802	11	1	29	2026-06-11 09:58:49.352979+03	n/a
309803	11	1	30	2026-06-11 09:58:49.444107+03	n/a
309804	11	1	31	2026-06-11 09:58:49.557239+03	+31
309805	11	1	32	2026-06-11 09:58:49.648124+03	-48.9
309806	11	1	33	2026-06-11 09:58:49.709954+03	OFF due to front...
309807	11	1	34	2026-06-11 09:58:49.821747+03	HDB3
309808	11	1	29	2026-06-11 09:59:00.069102+03	n/a
309809	11	1	30	2026-06-11 09:59:00.165583+03	n/a
309810	11	1	31	2026-06-11 09:59:00.277097+03	+30
309811	11	1	32	2026-06-11 09:59:00.367545+03	-48.9
309812	11	1	33	2026-06-11 09:59:00.430697+03	OFF due to front...
309813	11	1	34	2026-06-11 09:59:00.536507+03	HDB3
309814	11	1	29	2026-06-11 09:59:10.780361+03	n/a
309815	11	1	30	2026-06-11 09:59:10.891823+03	n/a
309816	11	1	31	2026-06-11 09:59:10.994852+03	+30
309817	11	1	32	2026-06-11 09:59:11.090017+03	-48.9
309818	11	1	33	2026-06-11 09:59:11.200592+03	OFF due to front...
309819	11	1	34	2026-06-11 09:59:11.293307+03	HDB3
309820	11	1	29	2026-06-11 09:59:21.532504+03	n/a
309821	11	1	30	2026-06-11 09:59:21.64632+03	n/a
309822	11	1	31	2026-06-11 09:59:21.756423+03	+31
309823	11	1	32	2026-06-11 09:59:21.844298+03	-48.8
309824	11	1	33	2026-06-11 09:59:21.954061+03	OFF due to front...
309825	11	1	34	2026-06-11 09:59:22.058924+03	HDB3
309826	11	1	29	2026-06-11 09:59:32.402472+03	n/a
309827	11	1	30	2026-06-11 09:59:32.502941+03	n/a
309828	11	1	31	2026-06-11 09:59:32.607338+03	+31
309829	11	1	32	2026-06-11 09:59:32.718974+03	-48.9
309830	11	1	33	2026-06-11 09:59:32.812213+03	OFF due to front...
309831	11	1	34	2026-06-11 09:59:32.923335+03	HDB3
309832	11	1	29	2026-06-11 09:59:43.241435+03	n/a
309833	11	1	30	2026-06-11 09:59:43.325887+03	n/a
309834	11	1	31	2026-06-11 09:59:43.434727+03	+30
309835	11	1	32	2026-06-11 09:59:43.550008+03	-48.8
309836	11	1	33	2026-06-11 09:59:43.636595+03	OFF due to front...
309837	11	1	34	2026-06-11 09:59:43.742552+03	HDB3
309838	11	1	29	2026-06-11 09:59:54.096629+03	n/a
309839	11	1	30	2026-06-11 09:59:54.205005+03	n/a
309840	11	1	31	2026-06-11 09:59:54.300418+03	+31
309841	11	1	32	2026-06-11 09:59:54.417591+03	-48.5
309842	11	1	33	2026-06-11 09:59:54.517253+03	OFF due to front...
309843	11	1	34	2026-06-11 09:59:54.609739+03	HDB3
309844	11	1	29	2026-06-11 10:00:04.909317+03	n/a
309845	11	1	30	2026-06-11 10:00:05.004333+03	n/a
309846	11	1	31	2026-06-11 10:00:05.112373+03	+31
309847	11	1	32	2026-06-11 10:00:05.208646+03	-48.5
309848	11	1	33	2026-06-11 10:00:05.317039+03	OFF due to front...
309849	11	1	34	2026-06-11 10:00:05.428022+03	HDB3
309850	11	1	29	2026-06-11 10:00:15.746733+03	n/a
309851	11	1	30	2026-06-11 10:00:15.847212+03	n/a
309852	11	1	31	2026-06-11 10:00:15.941884+03	+30
309853	11	1	32	2026-06-11 10:00:16.049839+03	-48.0
309854	11	1	33	2026-06-11 10:00:16.143408+03	OFF due to front...
309855	11	1	34	2026-06-11 10:00:16.251394+03	HDB3
309856	11	1	29	2026-06-11 10:00:26.556098+03	n/a
309857	11	1	30	2026-06-11 10:00:26.647038+03	n/a
309858	11	1	31	2026-06-11 10:00:26.711052+03	+30
309859	11	1	32	2026-06-11 10:00:26.817845+03	-48.3
309860	11	1	33	2026-06-11 10:00:26.912409+03	OFF due to front...
309861	11	1	34	2026-06-11 10:00:27.021766+03	HDB3
309862	11	1	29	2026-06-11 10:00:37.359712+03	n/a
309863	11	1	30	2026-06-11 10:00:37.469444+03	n/a
309864	11	1	31	2026-06-11 10:00:37.579889+03	+31
309865	11	1	32	2026-06-11 10:00:37.675623+03	-48.5
309866	11	1	33	2026-06-11 10:00:37.863175+03	OFF due to front...
309867	11	1	34	2026-06-11 10:00:37.981367+03	HDB3
309868	11	1	29	2026-06-11 10:00:48.331572+03	n/a
309869	11	1	30	2026-06-11 10:00:48.448913+03	n/a
309870	11	1	31	2026-06-11 10:00:48.538187+03	+31
309871	11	1	32	2026-06-11 10:00:48.649257+03	-48.7
309872	11	1	33	2026-06-11 10:00:48.742201+03	OFF due to front...
309873	11	1	34	2026-06-11 10:00:48.850688+03	HDB3
309874	11	1	29	2026-06-11 10:00:59.08535+03	n/a
309875	11	1	30	2026-06-11 10:00:59.191928+03	n/a
309876	11	1	31	2026-06-11 10:00:59.298674+03	+30
309877	11	1	32	2026-06-11 10:00:59.396542+03	-48.4
309878	11	1	33	2026-06-11 10:00:59.50862+03	OFF due to front...
309879	11	1	34	2026-06-11 10:00:59.612752+03	HDB3
309880	11	1	29	2026-06-11 10:01:09.917882+03	n/a
309881	11	1	30	2026-06-11 10:01:10.007073+03	n/a
309882	11	1	31	2026-06-11 10:01:10.123662+03	+31
309883	11	1	32	2026-06-11 10:01:10.223546+03	-48.7
309884	11	1	33	2026-06-11 10:01:10.320229+03	OFF due to front...
309885	11	1	34	2026-06-11 10:01:10.425876+03	HDB3
309886	11	1	29	2026-06-11 10:01:20.722741+03	n/a
309887	11	1	30	2026-06-11 10:01:20.830815+03	n/a
309888	11	1	31	2026-06-11 10:01:20.927359+03	+30
309889	11	1	32	2026-06-11 10:01:21.036744+03	-48.5
309890	11	1	33	2026-06-11 10:01:21.123745+03	OFF due to front...
309891	11	1	34	2026-06-11 10:01:21.234957+03	HDB3
309892	11	1	29	2026-06-11 10:01:31.541824+03	n/a
309893	11	1	30	2026-06-11 10:01:31.648782+03	n/a
309894	11	1	31	2026-06-11 10:01:31.756393+03	+31
309895	11	1	32	2026-06-11 10:01:31.848415+03	-48.7
309896	11	1	33	2026-06-11 10:01:31.96088+03	OFF due to front...
309897	11	1	34	2026-06-11 10:01:32.071601+03	HDB3
309898	11	1	29	2026-06-11 10:01:42.42321+03	n/a
309899	11	1	30	2026-06-11 10:01:42.532574+03	n/a
309900	11	1	31	2026-06-11 10:01:42.626524+03	+31
309901	11	1	32	2026-06-11 10:01:42.735913+03	-48.4
309902	11	1	33	2026-06-11 10:01:42.84596+03	OFF due to front...
309903	11	1	34	2026-06-11 10:01:42.940113+03	HDB3
309904	11	1	29	2026-06-11 10:01:53.241222+03	n/a
309905	11	1	30	2026-06-11 10:01:53.346983+03	n/a
309906	11	1	31	2026-06-11 10:01:53.458297+03	+31
309907	11	1	32	2026-06-11 10:01:53.551096+03	-48.6
309908	11	1	33	2026-06-11 10:01:53.660758+03	OFF due to front...
309909	11	1	34	2026-06-11 10:01:53.769775+03	HDB3
309910	11	1	29	2026-06-11 10:02:04.053586+03	n/a
309911	11	1	30	2026-06-11 10:02:04.164297+03	n/a
309912	11	1	31	2026-06-11 10:02:04.272732+03	+31
309913	11	1	32	2026-06-11 10:02:04.365244+03	-48.5
309914	11	1	33	2026-06-11 10:02:04.472257+03	OFF due to front...
309915	11	1	34	2026-06-11 10:02:04.581961+03	HDB3
309916	11	1	29	2026-06-11 10:02:14.929687+03	n/a
309917	11	1	30	2026-06-11 10:02:15.039485+03	n/a
309918	11	1	31	2026-06-11 10:02:15.128662+03	+30
309919	11	1	32	2026-06-11 10:02:15.239117+03	-48.6
309920	11	1	33	2026-06-11 10:02:15.348431+03	OFF due to front...
309921	11	1	34	2026-06-11 10:02:15.441766+03	HDB3
\.


--
-- TOC entry 5106 (class 0 OID 17060)
-- Dependencies: 223
-- Data for Name: reading_type; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.reading_type (reading_type_id, identifier, name, unit, min_value, max_value) FROM stdin;
29	ber	ber	\N	\N	\N
30	ebn	ebn	\N	\N	\N
32	rsl	rsl	\N	\N	\N
33	txo	txo	\N	\N	\N
34	ttc	ttc	\N	\N	\N
31	tmp	Температура	°C	27.00	33.00
\.


--
-- TOC entry 5108 (class 0 OID 17067)
-- Dependencies: 225
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.role (role_id, name) FROM stdin;
2	Инженер
1	Администратор
\.


--
-- TOC entry 5110 (class 0 OID 17073)
-- Dependencies: 227
-- Data for Name: session; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.session (session_id, user_id, refresh_token, device, session_end_date_time) FROM stdin;
69	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIwMzI1LCJleHAiOjE3ODExNzk1MjUsImlhdCI6MTc4MDkyMDMyNSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.CHO8rda9t9LJ3X6PDw_vZGrKR6Juhq6iLrBI8CBUjGU	Unknown Android Device	2026-06-11 15:05:25.205808+03
71	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIwOTY4LCJleHAiOjE3ODExODAxNjgsImlhdCI6MTc4MDkyMDk2OCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.cqOt893ilI8nUjXNceQdpiBHy1yl1TwIBptL3bzwvqM	Unknown Android Device	2026-06-11 15:16:08.12069+03
72	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIwOTc1LCJleHAiOjE3ODExODAxNzUsImlhdCI6MTc4MDkyMDk3NSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.oRneb_BybH0eLwJsiNs8xiojjVwWyWOlhY3GouHOpWY	Unknown Android Device	2026-06-11 15:16:15.026537+03
76	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIxNDM3LCJleHAiOjE3ODExODA2MzcsImlhdCI6MTc4MDkyMTQzNywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.k6gPiQXWgtJMnAOS88goBB4oWDgQMpqGsxTLBl4PpaU	Unknown Android Device	2026-06-11 15:23:57.034986+03
77	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIxNDY5LCJleHAiOjE3ODExODA2NjksImlhdCI6MTc4MDkyMTQ2OSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.tGtggoFxiH7sCF7EcLSysI_2QLCPNd6uTHVZQ-upEOI	Unknown Android Device	2026-06-11 15:24:29.082176+03
80	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIyMTIxLCJleHAiOjE3ODExODEzMjEsImlhdCI6MTc4MDkyMjEyMSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.IOyV26YbtUMZ4GOQfdsMhRNeGxHzb7W3iyAIurAdEXI	Unknown Android Device	2026-06-11 15:35:21.103373+03
81	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIyMTUzLCJleHAiOjE3ODExODEzNTMsImlhdCI6MTc4MDkyMjE1MywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.H9f5f9RKjjF6Do55yp8PDBdmf51xM0p4DOfz4C84luE	Unknown Android Device	2026-06-11 15:35:53.98782+03
82	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIyMTkxLCJleHAiOjE3ODExODEzOTEsImlhdCI6MTc4MDkyMjE5MSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.iSqu_ZGCTRYjlOVz1_gISqv4kM7WPeqiDQZIDtAz9Jo	Unknown Android Device	2026-06-11 15:36:31.380794+03
83	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIyMzQ4LCJleHAiOjE3ODExODE1NDgsImlhdCI6MTc4MDkyMjM0OCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.xySKA0VqJBA99Ajvd89bD-NmMOkPyGYQLwr2sy3Mk3c	Unknown Android Device	2026-06-11 15:39:08.551229+03
88	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIyOTc3LCJleHAiOjE3ODExODIxNzcsImlhdCI6MTc4MDkyMjk3NywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.PGUIq0bLFNMXtA6AiFfSGds6xhrrCsHRVANcRIHIKiw	Unknown Android Device	2026-06-11 15:49:37.444619+03
89	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIzMDA1LCJleHAiOjE3ODExODIyMDUsImlhdCI6MTc4MDkyMzAwNSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.V4FtJIQDFVn_GhSFRFiAwQx_dDr4z82wyCL0VFKi2RQ	Unknown Android Device	2026-06-11 15:50:05.331738+03
90	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIzMDQ0LCJleHAiOjE3ODExODIyNDQsImlhdCI6MTc4MDkyMzA0NCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.CJpYHrEtJoXcxHQiQHsduzgecthnzDq60fSitP_4GEc	Unknown Android Device	2026-06-11 15:50:44.003668+03
95	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI0MjM4LCJleHAiOjE3ODExODM0MzgsImlhdCI6MTc4MDkyNDIzOCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.OgiLFyKyReI4VvQOWka0ex1LI1vbOnnxbHg1M4ZWDtQ	Unknown Android Device	2026-06-11 16:10:38.948057+03
96	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI0MzEwLCJleHAiOjE3ODExODM1MTAsImlhdCI6MTc4MDkyNDMxMCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.6zbz2kkZkYPsp2EZe_Aar3IKqhORpjUVuHxJN6_Nnx4	Unknown Android Device	2026-06-11 16:11:50.296455+03
97	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI0NDc0LCJleHAiOjE3ODExODM2NzQsImlhdCI6MTc4MDkyNDQ3NCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.yxxjvUBlOvJfNjxk5b4djIcIqJCP_L4QXCgL1WeDrHk	Unknown Android Device	2026-06-11 16:14:34.047317+03
101	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI1NjE2LCJleHAiOjE3ODExODQ4MTYsImlhdCI6MTc4MDkyNTYxNiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.2Z6D3a4Hx19c-ddQIlP7WVl2LgelZshxjhgN1CnA5MI	Unknown Android Device	2026-06-11 16:33:36.819454+03
102	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI1ODg0LCJleHAiOjE3ODExODUwODQsImlhdCI6MTc4MDkyNTg4NCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.dV9zIPSQ4ME9zRx4oTac4lYn49wNLW1MMJ88jsHxKm8	Unknown Android Device	2026-06-11 16:38:04.152093+03
106	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI3MTQzLCJleHAiOjE3ODExODYzNDMsImlhdCI6MTc4MDkyNzE0MywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.IQfqad_wR-wdKqJq-w8vYLQLNXrqWbLzTlWDghKTb2U	Unknown Android Device	2026-06-11 16:59:03.236112+03
108	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI4MTk2LCJleHAiOjE3ODExODczOTYsImlhdCI6MTc4MDkyODE5NiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.gDvK9rQScRpmNXI8qoabhY0l6rsG_QNTTNGcnqeyE4E	Unknown Android Device	2026-06-11 17:16:36.658422+03
111	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI4NTE2LCJleHAiOjE3ODExODc3MTYsImlhdCI6MTc4MDkyODUxNiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.GhQl_v6rwTfSROpCWA72XvXLgg1CCPq7pGh_VOvRsl8	Unknown Android Device	2026-06-11 17:21:56.973337+03
113	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTMyNDcyLCJleHAiOjE3ODExOTE2NzIsImlhdCI6MTc4MDkzMjQ3MiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.ias_ANe4mQKu4trRrIEwj8Py-Rker_v67M8GOCUpmPo	Unknown Android Device	2026-06-11 18:27:52.491809+03
115	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTMzNDQyLCJleHAiOjE3ODExOTI2NDIsImlhdCI6MTc4MDkzMzQ0MiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.Km4YNjPEsci9IailYOO--Ed-fl3hsnoltdeyFVFiYBQ	Unknown Android Device	2026-06-11 18:44:02.658328+03
116	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTMzNTY3LCJleHAiOjE3ODExOTI3NjcsImlhdCI6MTc4MDkzMzU2NywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.iLKNsoLbcsk5GfzJMypT_NxoTAo6AHZPL3yHOoCcv84	Unknown Android Device	2026-06-11 18:46:07.124545+03
118	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTMzOTExLCJleHAiOjE3ODExOTMxMTEsImlhdCI6MTc4MDkzMzkxMSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.sPRkui4m3SfEIpYwPCp9t5LG3bMvVlnizRe7JlGgvsw	Unknown Android Device	2026-06-11 18:51:51.943393+03
119	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTMzOTY4LCJleHAiOjE3ODExOTMxNjgsImlhdCI6MTc4MDkzMzk2OCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.1niwzI1QSFOr1ExJ474U5NmXhkymUuTkEUsvqjfWag4	Unknown Android Device	2026-06-11 18:52:48.532606+03
120	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM0MDYyLCJleHAiOjE3ODExOTMyNjIsImlhdCI6MTc4MDkzNDA2MiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.qBswgyvlccWltqBkrEgSWsqk4L-9uD6JV7m6smYpZgc	Unknown Android Device	2026-06-11 18:54:22.783407+03
121	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM0MTMwLCJleHAiOjE3ODExOTMzMzAsImlhdCI6MTc4MDkzNDEzMCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.rZ4lc9wnXzOJuV9TeUQi-BibOjbd_WYEt9XNac-T08Q	Unknown Android Device	2026-06-11 18:55:30.543832+03
70	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIwODg5LCJleHAiOjE3ODExODAwODksImlhdCI6MTc4MDkyMDg4OSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.MDy1ani3qzDjPTzSLgjh1BjhZODeR8bgDk2CZW9JkdI	Unknown Android Device	2026-06-11 15:14:49.313231+03
73	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIxMDE2LCJleHAiOjE3ODExODAyMTYsImlhdCI6MTc4MDkyMTAxNiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.04xc_bV7dn6IzW6hX6kI8xvGpjquFezu0hDVlME2uxU	Unknown Android Device	2026-06-11 15:16:56.054879+03
74	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIxMDUwLCJleHAiOjE3ODExODAyNTAsImlhdCI6MTc4MDkyMTA1MCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.0DSn6S0qTlu_T3tmdrGXmR_-6xg2EWG93HhnOu2rcQM	Unknown Android Device	2026-06-11 15:17:30.949098+03
75	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIxMTQzLCJleHAiOjE3ODExODAzNDMsImlhdCI6MTc4MDkyMTE0MywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.rZH9ADUZq4FVgDpOvsWU5fQ-OFlrt9si_6PX3_C3qnY	Unknown Android Device	2026-06-11 15:19:03.537864+03
78	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIxODA4LCJleHAiOjE3ODExODEwMDgsImlhdCI6MTc4MDkyMTgwOCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.w6XDB_cH7OsbBFt_G6vG9ZUDx_ECOj4zpuZAbOZ2zA8	Unknown Android Device	2026-06-11 15:30:08.893558+03
79	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIxODg3LCJleHAiOjE3ODExODEwODcsImlhdCI6MTc4MDkyMTg4NywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.ECrwbtLaAhi8Iwg4teiEPnnZAnyH9ZTno7lW-MTXads	Unknown Android Device	2026-06-11 15:31:27.524394+03
84	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIyNjYzLCJleHAiOjE3ODExODE4NjMsImlhdCI6MTc4MDkyMjY2MywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.gZwxkHEohAhGoOp3pBQ6kflwgPo2EA1qquPb1Ob9BDw	Unknown Android Device	2026-06-11 15:44:23.87069+03
85	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIyNzMwLCJleHAiOjE3ODExODE5MzAsImlhdCI6MTc4MDkyMjczMCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.02nRy9_bSElxawJ3ZCxJxKPE_Ts8xuE4ehOOPczEnj8	Unknown Android Device	2026-06-11 15:45:30.037513+03
86	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIyNzY0LCJleHAiOjE3ODExODE5NjQsImlhdCI6MTc4MDkyMjc2NCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.V-VH0FVvxSAECFKnEhOuWu19yprtIJ48q5MH62BWUPM	Unknown Android Device	2026-06-11 15:46:04.979122+03
87	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIyODY0LCJleHAiOjE3ODExODIwNjQsImlhdCI6MTc4MDkyMjg2NCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.9-ckQUfvs_-f7FxvFfaocxqZQbZWA-8YIse7JMVSv8A	Unknown Android Device	2026-06-11 15:47:44.664927+03
91	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTIzOTE3LCJleHAiOjE3ODExODMxMTcsImlhdCI6MTc4MDkyMzkxNywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.ybKE0RGLT7mMvYQWBnEeSY3lda_lHV8TMRnrK36Mves	Unknown Android Device	2026-06-11 16:05:17.806384+03
92	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI0MDczLCJleHAiOjE3ODExODMyNzMsImlhdCI6MTc4MDkyNDA3MywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.30ceBxsU49GH0zGLSeXul_gp3xy9DohVSf-DHe8fAfo	Unknown Android Device	2026-06-11 16:07:53.241054+03
93	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI0MTEzLCJleHAiOjE3ODExODMzMTMsImlhdCI6MTc4MDkyNDExMywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.VTx6Zier3xY-xJtV-a9eIcTxBM1g4-yICElWmrJp14k	Unknown Android Device	2026-06-11 16:08:33.618702+03
94	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI0MTQyLCJleHAiOjE3ODExODMzNDIsImlhdCI6MTc4MDkyNDE0MiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.Mn3Vl7Fol__4dM0SPmSZJt0OvXoW5O8DQg8RFKZmQIs	Unknown Android Device	2026-06-11 16:09:02.376336+03
98	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI0ODM0LCJleHAiOjE3ODExODQwMzQsImlhdCI6MTc4MDkyNDgzNCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.sHSdB-CsMN3W0uop9kdwgTEhSi7XWTm3DfBmvciyoV4	Unknown Android Device	2026-06-11 16:20:34.239667+03
99	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI0ODY3LCJleHAiOjE3ODExODQwNjcsImlhdCI6MTc4MDkyNDg2NywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.2PAMH3x_o-zeKDGNkS63Pi1el3ZBK3BUyNZa9cAxIhg	Unknown Android Device	2026-06-11 16:21:07.91654+03
100	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI0OTE5LCJleHAiOjE3ODExODQxMTksImlhdCI6MTc4MDkyNDkxOSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.uiSP1r3U9G2Ll_lFe7aDxUXwNSjRFiXj0HsJHoT9HrY	Unknown Android Device	2026-06-11 16:21:59.155854+03
103	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI1OTM4LCJleHAiOjE3ODExODUxMzgsImlhdCI6MTc4MDkyNTkzOCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.4Wlgve24PwCB_9z-ta_pIZ2OJSERm5JgvfHkztnxR6Q	Unknown Android Device	2026-06-11 16:38:58.419186+03
104	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI2MTIzLCJleHAiOjE3ODExODUzMjMsImlhdCI6MTc4MDkyNjEyMywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.BefETSb31N6_jGPLETwi_6Vvjc3t8elyjLoAiz1RIlc	Unknown Android Device	2026-06-11 16:42:03.437871+03
105	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI2MjIwLCJleHAiOjE3ODExODU0MjAsImlhdCI6MTc4MDkyNjIyMCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.psP0xGHQdoLN2pONlfoKwY-U8PbjXZJ2aK1KpwSn3Ns	Unknown Android Device	2026-06-11 16:43:40.154702+03
107	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI3NzM5LCJleHAiOjE3ODExODY5MzksImlhdCI6MTc4MDkyNzczOSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.GlIX59YJksaV5EzEw6op7IAKeoUGC68kZuOoGSrhNnA	Unknown Android Device	2026-06-11 17:08:59.180951+03
112	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTI4ODc3LCJleHAiOjE3ODExODgwNzcsImlhdCI6MTc4MDkyODg3NywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.RCG2D3qAWHZjvSkPVAoxI4M2aJxeRzsj-eHYzGhrQA0	Unknown Android Device	2026-06-11 17:27:57.159527+03
114	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTMzMTg4LCJleHAiOjE3ODExOTIzODgsImlhdCI6MTc4MDkzMzE4OCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.4zpWxJqiDhrLi2LS6UehUAz0uly6zP01kMlrl0QIN4w	Unknown Android Device	2026-06-11 18:39:48.131091+03
117	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTMzNzMyLCJleHAiOjE3ODExOTI5MzIsImlhdCI6MTc4MDkzMzczMiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.heS_-T7iuDhtCPivdh6CoOvVmd6LS-YJWXZVjr_C-8k	Unknown Android Device	2026-06-11 18:48:52.845021+03
122	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM0MjUwLCJleHAiOjE3ODExOTM0NTAsImlhdCI6MTc4MDkzNDI1MCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.DFeD-iCun9lFI5_CW-8wUYmCCbqINtPn_34EUM1VO5Y	Unknown Android Device	2026-06-11 18:57:30.853535+03
123	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM0Mzk2LCJleHAiOjE3ODExOTM1OTYsImlhdCI6MTc4MDkzNDM5NiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.YThPtNPN74CuQ9-aNtbVnCO4Ey5IqoTYD3b0H2PTi0M	Unknown Android Device	2026-06-11 18:59:56.979704+03
124	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM0NDc5LCJleHAiOjE3ODExOTM2NzksImlhdCI6MTc4MDkzNDQ3OSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.ue_rNHOJvycdR1u_oW_6olGy9Y9yf7BbmkKHdPxhjEM	Unknown Android Device	2026-06-11 19:01:23.694071+03
125	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM0NTUwLCJleHAiOjE3ODExOTM3NTAsImlhdCI6MTc4MDkzNDU1MCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.BBkUeeFxOq1IHHKSRWGTkcZqsDWg7Zr-9d-9RNtEe98	Unknown Android Device	2026-06-11 19:02:30.482159+03
126	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM0NTk2LCJleHAiOjE3ODExOTM3OTYsImlhdCI6MTc4MDkzNDU5NiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.EZ1ydhZbED4kchlmvftQxSVn2u1TdoIC4eBQQwpuWzw	Unknown Android Device	2026-06-11 19:03:16.800145+03
127	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM1MjQ4LCJleHAiOjE3ODExOTQ0NDgsImlhdCI6MTc4MDkzNTI0OCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.IrpOmykTp7u6q3bVqQAI-k22h0maMVUK8I1th6Tm1uE	Unknown Android Device	2026-06-11 19:14:08.056193+03
128	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM1MjgwLCJleHAiOjE3ODExOTQ0ODAsImlhdCI6MTc4MDkzNTI4MCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.7oxN8R1dsjpiqXFGjcPpUluBG2YF_mMlQx_NI6Ou0Qg	Unknown Android Device	2026-06-11 19:14:40.885495+03
129	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM1MzM5LCJleHAiOjE3ODExOTQ1MzksImlhdCI6MTc4MDkzNTMzOSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.jSrLR3zwP6K1HYyoqEicCEQNLx_HHhq2_nqLM4er9rs	Unknown Android Device	2026-06-11 19:15:39.573047+03
130	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM1NDQ2LCJleHAiOjE3ODExOTQ2NDYsImlhdCI6MTc4MDkzNTQ0NiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.-oWju2kV-yGfqFUB7qoKMKWJnaxPQ1khhUh65A3VpWc	Unknown Android Device	2026-06-11 19:17:26.702608+03
131	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM1NjM3LCJleHAiOjE3ODExOTQ4MzcsImlhdCI6MTc4MDkzNTYzNywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.G5vjTMB6fb24HuyjmxxYZFDpriE7Zri_FGbak5jIA1U	samsung SM-A5660	2026-06-11 19:20:37.312226+03
132	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM2NDA1LCJleHAiOjE3ODExOTU2MDUsImlhdCI6MTc4MDkzNjQwNSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.OhUVxLzi7eT-5y-Tb2YP0piqP-MeaJLec81BdfItk5Y	Unknown Android Device	2026-06-11 19:33:25.830881+03
133	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM2NzU4LCJleHAiOjE3ODExOTU5NTgsImlhdCI6MTc4MDkzNjc1OCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.HU7HpJBrri73cxBDxn1qpydRJfpjW4l9RhtybsrNJqw	Unknown Android Device	2026-06-11 19:39:18.855963+03
134	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM3NjE0LCJleHAiOjE3ODExOTY4MTQsImlhdCI6MTc4MDkzNzYxNCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.AFG2oN3_BwtKOtHSUfgEwUA7O-pjRFosoSc5wU5XqMY	Unknown Android Device	2026-06-11 19:53:34.570334+03
135	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM4MTM4LCJleHAiOjE3ODExOTczMzgsImlhdCI6MTc4MDkzODEzOCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.TXOXxlDvM2qNd-7m_LX7sjgR5IY2ckymwJwdGp27uuc	Unknown Android Device	2026-06-11 20:02:18.98796+03
136	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTM4MjA1LCJleHAiOjE3ODExOTc0MDUsImlhdCI6MTc4MDkzODIwNSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.ZyJET1mj5bKd2ZtlVJrQyaUGB9o7_1lz-8ECEQtHu_k	Unknown Android Device	2026-06-11 20:03:25.066379+03
138	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgwOTk1NjAyLCJleHAiOjE3ODEyNTQ4MDIsImlhdCI6MTc4MDk5NTYwMiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.-K_dm5yFs7IfQPSs7ID9YpX-9sxlckzh2Z8reE9u_jc	Unknown Android Device	2026-06-12 12:00:02.008229+03
139	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTM1MTA5LCJleHAiOjE3ODEzOTQzMDksImlhdCI6MTc4MTEzNTEwOSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.84fnE7bZd3SFAUQiK0a0DbLlSRO1blctQ9Y1YFt6i4I	Unknown Android Device	2026-06-14 02:45:09.78366+03
140	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTM4NTYxLCJleHAiOjE3ODEzOTc3NjEsImlhdCI6MTc4MTEzODU2MSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.zg07BiQv9jSsvRj_8lvDQtZKAWiTpVxrq7PgGnkU9h8	Unknown Android Device	2026-06-14 03:42:41.461535+03
141	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTM4NjA0LCJleHAiOjE3ODEzOTc4MDQsImlhdCI6MTc4MTEzODYwNCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.3lZzQqEO9HHcq7CUFwDwL_73tPkOuZ9hvQCgMQrUE9Q	Unknown Android Device	2026-06-14 03:43:24.303304+03
142	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTM4NjgyLCJleHAiOjE3ODEzOTc4ODIsImlhdCI6MTc4MTEzODY4MiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.2A96SRwDIMZN79tCSPbJuWeRN0iLNEec2G-V4bJDNuo	Unknown Android Device	2026-06-14 03:44:42.654036+03
143	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTM4OTU1LCJleHAiOjE3ODEzOTgxNTUsImlhdCI6MTc4MTEzODk1NSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.N8Nf4fFeSdqbLPLFTz577FFbjOlqXAWb0Pe9yE8YfKQ	Unknown Android Device	2026-06-14 03:49:15.229924+03
144	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTM5MDQzLCJleHAiOjE3ODEzOTgyNDMsImlhdCI6MTc4MTEzOTA0MywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.nFPllFMO2vyYB1bRIdpH3s9vZwuGSXNZyDpeqLQ6V8M	Unknown Android Device	2026-06-14 03:50:43.980912+03
145	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTM5NDU2LCJleHAiOjE3ODEzOTg2NTYsImlhdCI6MTc4MTEzOTQ1NiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.X9C9CQhdjaqx3t8JearJzsgyEm9W-Mlp4jh32ACY73E	Unknown Android Device	2026-06-14 03:57:36.402758+03
146	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTQyMzkyLCJleHAiOjE3ODE0MDE1OTIsImlhdCI6MTc4MTE0MjM5MiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.KRpqU_sk88SREh_IHqeWuRJ46l-QCGV-RWlk0vaaUDc	Unknown Android Device	2026-06-14 04:46:32.668741+03
147	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTQyNDQxLCJleHAiOjE3ODE0MDE2NDEsImlhdCI6MTc4MTE0MjQ0MSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.YNgNUolM8NOkyTogpeu3gS4oK2lov_filQPI9rF1R7g	Unknown Android Device	2026-06-14 04:47:21.7748+03
148	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTQyNzI1LCJleHAiOjE3ODE0MDE5MjUsImlhdCI6MTc4MTE0MjcyNSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.JY_-vf-jeHRJl1oNgT9HjMv0HlpXbJvcIaouxYVo8Ic	Unknown Android Device	2026-06-14 04:52:05.649227+03
149	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTQzMDYwLCJleHAiOjE3ODE0MDIyNjAsImlhdCI6MTc4MTE0MzA2MCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.5zgx6qK-V4NggflORDcIW0IEyRKVuHALjF_yaY0siQw	Unknown Android Device	2026-06-14 04:57:40.815865+03
150	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTU5MTU1LCJleHAiOjE3ODE0MTgzNTUsImlhdCI6MTc4MTE1OTE1NSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.jAkChMkQGWP7iWLVYsQnVwuJCML_Z-fHE_Yy1q-3n0g	Unknown Android Device	2026-06-14 09:25:55.665129+03
152	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTYwMDI5LCJleHAiOjE3ODE0MTkyMjksImlhdCI6MTc4MTE2MDAyOSwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.wJUGXqIwSo_16r4mIUCmWIDZauWkJ64CRaUD20LVKrE	Unknown Android Device	2026-06-14 09:40:29.537674+03
153	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTYwMDgzLCJleHAiOjE3ODE0MTkyODMsImlhdCI6MTc4MTE2MDA4MywiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.afKf9MYTLMToE-om38S3L5Sc1DSGknHN3usorRWSkmc	Unknown Android Device	2026-06-14 09:41:23.595499+03
154	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTYwNDYwLCJleHAiOjE3ODE0MTk2NjAsImlhdCI6MTc4MTE2MDQ2MCwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.eOVOdeCeo1k0QmmVnZDj8GdmpVPAKc3SYemLuuN0ieY	Unknown Android Device	2026-06-14 09:47:40.791427+03
155	4	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0IiwibmJmIjoxNzgxMTYwNTE2LCJleHAiOjE3ODE0MTk3MTYsImlhdCI6MTc4MTE2MDUxNiwiaXNzIjoiU2lnbmFsVHJhY2siLCJhdWQiOiJTaWduYWxUcmFjayJ9.XzVJXGQh1uF6bMln1SYjP6MlTjDJ25fig79i3NGnQKo	Unknown Android Device	2026-06-14 09:48:36.263837+03
\.


--
-- TOC entry 5112 (class 0 OID 17083)
-- Dependencies: 229
-- Data for Name: status; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.status (status_id, name) FROM stdin;
1	ok
2	warning
3	error
\.


--
-- TOC entry 5114 (class 0 OID 17089)
-- Dependencies: 231
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public."user" (user_id, login, hashed_password, second_name, first_name, last_name) FROM stdin;
4	admin	$2b$12$O1iqmrfuMgMrlRtGvUgggeM1X5EJzJKmDj/qydpMUiP7UVZ.gkmpu	admin	admin	admin
\.


--
-- TOC entry 5115 (class 0 OID 17099)
-- Dependencies: 232
-- Data for Name: user_role; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.user_role (user_id, role_id) FROM stdin;
4	1
\.


--
-- TOC entry 5147 (class 0 OID 0)
-- Dependencies: 220
-- Name: equipment_equipment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.equipment_equipment_id_seq', 12, true);


--
-- TOC entry 5148 (class 0 OID 0)
-- Dependencies: 222
-- Name: reading_log_reading_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.reading_log_reading_log_id_seq', 309921, true);


--
-- TOC entry 5149 (class 0 OID 0)
-- Dependencies: 224
-- Name: reading_type_reading_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.reading_type_reading_type_id_seq', 34, true);


--
-- TOC entry 5150 (class 0 OID 0)
-- Dependencies: 226
-- Name: role_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.role_role_id_seq', 2, true);


--
-- TOC entry 5151 (class 0 OID 0)
-- Dependencies: 228
-- Name: session_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.session_session_id_seq', 157, true);


--
-- TOC entry 5152 (class 0 OID 0)
-- Dependencies: 230
-- Name: status_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.status_status_id_seq', 3, true);


--
-- TOC entry 5153 (class 0 OID 0)
-- Dependencies: 233
-- Name: user_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.user_user_id_seq', 26, true);


--
-- TOC entry 4914 (class 2606 OID 17122)
-- Name: equipment equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_pkey PRIMARY KEY (equipment_id);


--
-- TOC entry 4916 (class 2606 OID 17124)
-- Name: equipment equipment_serial_number_key; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_serial_number_key UNIQUE (serial_number);


--
-- TOC entry 4919 (class 2606 OID 17126)
-- Name: reading_log reading_log_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_log
    ADD CONSTRAINT reading_log_pkey PRIMARY KEY (reading_log_id);


--
-- TOC entry 4921 (class 2606 OID 17128)
-- Name: reading_type reading_type_identifier_key; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_type
    ADD CONSTRAINT reading_type_identifier_key UNIQUE (identifier);


--
-- TOC entry 4923 (class 2606 OID 17130)
-- Name: reading_type reading_type_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_type
    ADD CONSTRAINT reading_type_pkey PRIMARY KEY (reading_type_id);


--
-- TOC entry 4925 (class 2606 OID 17132)
-- Name: role role_name_key; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_name_key UNIQUE (name);


--
-- TOC entry 4927 (class 2606 OID 17134)
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (role_id);


--
-- TOC entry 4930 (class 2606 OID 17136)
-- Name: session session_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (session_id);


--
-- TOC entry 4932 (class 2606 OID 17138)
-- Name: session session_refresh_token_key; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_refresh_token_key UNIQUE (refresh_token);


--
-- TOC entry 4934 (class 2606 OID 17140)
-- Name: status status_name_key; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_name_key UNIQUE (name);


--
-- TOC entry 4936 (class 2606 OID 17142)
-- Name: status status_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (status_id);


--
-- TOC entry 4938 (class 2606 OID 17144)
-- Name: user user_login_key; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_login_key UNIQUE (login);


--
-- TOC entry 4940 (class 2606 OID 17146)
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4942 (class 2606 OID 17148)
-- Name: user_role user_role_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_pkey PRIMARY KEY (user_id, role_id);


--
-- TOC entry 4917 (class 1259 OID 17149)
-- Name: idx_metrics_device_time; Type: INDEX; Schema: public; Owner: user1
--

CREATE INDEX idx_metrics_device_time ON public.reading_log USING btree (equipment_id, write_date_time DESC);


--
-- TOC entry 4928 (class 1259 OID 17150)
-- Name: idx_sessions_user; Type: INDEX; Schema: public; Owner: user1
--

CREATE INDEX idx_sessions_user ON public.session USING btree (user_id);


--
-- TOC entry 4950 (class 2620 OID 17151)
-- Name: reading_log trg_bi_reading_log_status; Type: TRIGGER; Schema: public; Owner: user1
--

CREATE TRIGGER trg_bi_reading_log_status BEFORE INSERT ON public.reading_log FOR EACH ROW EXECUTE FUNCTION public.check_reading_status();


--
-- TOC entry 4952 (class 2620 OID 17152)
-- Name: session trg_clean_expired_sessions; Type: TRIGGER; Schema: public; Owner: user1
--

CREATE TRIGGER trg_clean_expired_sessions BEFORE INSERT ON public.session FOR EACH ROW EXECUTE FUNCTION public.clean_expired_sessions();


--
-- TOC entry 4951 (class 2620 OID 17153)
-- Name: reading_log trg_clean_old_logs; Type: TRIGGER; Schema: public; Owner: user1
--

CREATE TRIGGER trg_clean_old_logs AFTER INSERT ON public.reading_log FOR EACH STATEMENT EXECUTE FUNCTION public.clean_old_reading_logs();


--
-- TOC entry 4943 (class 2606 OID 17154)
-- Name: equipment equipment_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.status(status_id) ON DELETE RESTRICT;


--
-- TOC entry 4944 (class 2606 OID 17159)
-- Name: reading_log reading_log_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_log
    ADD CONSTRAINT reading_log_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(equipment_id) ON DELETE CASCADE;


--
-- TOC entry 4945 (class 2606 OID 17164)
-- Name: reading_log reading_log_reading_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_log
    ADD CONSTRAINT reading_log_reading_type_id_fkey FOREIGN KEY (reading_type_id) REFERENCES public.reading_type(reading_type_id) ON DELETE RESTRICT;


--
-- TOC entry 4946 (class 2606 OID 17169)
-- Name: reading_log reading_log_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_log
    ADD CONSTRAINT reading_log_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.status(status_id) ON DELETE RESTRICT;


--
-- TOC entry 4947 (class 2606 OID 17174)
-- Name: session session_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(user_id) ON DELETE CASCADE;


--
-- TOC entry 4948 (class 2606 OID 17179)
-- Name: user_role user_role_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.role(role_id) ON DELETE CASCADE;


--
-- TOC entry 4949 (class 2606 OID 17184)
-- Name: user_role user_role_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(user_id) ON DELETE CASCADE;


--
-- TOC entry 5122 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO db_editor;
GRANT USAGE ON SCHEMA public TO engineer_reader;
GRANT ALL ON SCHEMA public TO admin_editor;


--
-- TOC entry 5123 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE equipment; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.equipment TO db_editor;
GRANT SELECT ON TABLE public.equipment TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.equipment TO admin_editor;


--
-- TOC entry 5125 (class 0 OID 0)
-- Dependencies: 220
-- Name: SEQUENCE equipment_equipment_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.equipment_equipment_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.equipment_equipment_id_seq TO admin_editor;


--
-- TOC entry 5126 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE reading_log; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.reading_log TO db_editor;
GRANT SELECT ON TABLE public.reading_log TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.reading_log TO admin_editor;


--
-- TOC entry 5128 (class 0 OID 0)
-- Dependencies: 222
-- Name: SEQUENCE reading_log_reading_log_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.reading_log_reading_log_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.reading_log_reading_log_id_seq TO admin_editor;


--
-- TOC entry 5129 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE reading_type; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.reading_type TO db_editor;
GRANT SELECT ON TABLE public.reading_type TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.reading_type TO admin_editor;


--
-- TOC entry 5131 (class 0 OID 0)
-- Dependencies: 224
-- Name: SEQUENCE reading_type_reading_type_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.reading_type_reading_type_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.reading_type_reading_type_id_seq TO admin_editor;


--
-- TOC entry 5132 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE role; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.role TO db_editor;
GRANT SELECT ON TABLE public.role TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.role TO admin_editor;


--
-- TOC entry 5134 (class 0 OID 0)
-- Dependencies: 226
-- Name: SEQUENCE role_role_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.role_role_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.role_role_id_seq TO admin_editor;


--
-- TOC entry 5135 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE session; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.session TO db_editor;
GRANT SELECT ON TABLE public.session TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.session TO admin_editor;


--
-- TOC entry 5137 (class 0 OID 0)
-- Dependencies: 228
-- Name: SEQUENCE session_session_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.session_session_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.session_session_id_seq TO admin_editor;


--
-- TOC entry 5138 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE status; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.status TO db_editor;
GRANT SELECT ON TABLE public.status TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.status TO admin_editor;


--
-- TOC entry 5140 (class 0 OID 0)
-- Dependencies: 230
-- Name: SEQUENCE status_status_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.status_status_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.status_status_id_seq TO admin_editor;


--
-- TOC entry 5141 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE "user"; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."user" TO db_editor;
GRANT SELECT ON TABLE public."user" TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."user" TO admin_editor;


--
-- TOC entry 5142 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE user_role; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.user_role TO db_editor;
GRANT SELECT ON TABLE public.user_role TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.user_role TO admin_editor;


--
-- TOC entry 5144 (class 0 OID 0)
-- Dependencies: 233
-- Name: SEQUENCE user_user_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.user_user_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.user_user_id_seq TO admin_editor;


--
-- TOC entry 5145 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE view_latest_equipment_readings; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.view_latest_equipment_readings TO db_editor;
GRANT SELECT ON TABLE public.view_latest_equipment_readings TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.view_latest_equipment_readings TO admin_editor;


--
-- TOC entry 5146 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE view_new_equipment; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.view_new_equipment TO db_editor;
GRANT SELECT ON TABLE public.view_new_equipment TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.view_new_equipment TO admin_editor;


--
-- TOC entry 2099 (class 826 OID 16856)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES TO db_editor;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES TO admin_editor;


--
-- TOC entry 2100 (class 826 OID 16855)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO db_editor;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES TO engineer_reader;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO admin_editor;


-- Completed on 2026-06-14 22:03:07

--
-- PostgreSQL database dump complete
--

\unrestrict 6H2IOscjQmzahbc9c9G0QW4b81PtnO6o69IWC1GufO9CS1vn87rQjpCk0HY1Kgo

