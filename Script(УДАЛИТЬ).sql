CREATE TABLE "role" (
    "role_id" SERIAL PRIMARY KEY,
    "name" VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE "status" (
    "status_id" SERIAL PRIMARY KEY,
    "name" VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE "reading_type" (
    "reading_type_id" SERIAL PRIMARY KEY,
    "identifier" VARCHAR(19) NOT NULL UNIQUE, 
    "name" VARCHAR(50) NOT NULL,       
    "unit" VARCHAR(20)                             
);

CREATE TABLE "user" (
    "user_id" SERIAL PRIMARY KEY,
    "login" VARCHAR(50) NOT NULL UNIQUE,
    "hashed_password" VARCHAR(255) NOT NULL,
    "second_name" VARCHAR(100) NOT NULL,
    "first_name" VARCHAR(100) NOT NULL,
    "last_name" VARCHAR(100)
);

CREATE TABLE "equipment" (
    "equipment_id" SERIAL PRIMARY KEY,
    "status_id" INT NOT NULL REFERENCES "status" ("status_id") ON DELETE RESTRICT,
    "serial_number" VARCHAR(100) NOT NULL UNIQUE,
    "name" VARCHAR(150) NOT NULL,
    "model" VARCHAR(100) NOT NULL,
    "last_check_date" TIMESTAMP WITH TIME ZONE
);

CREATE TABLE "user_role" (
    "user_id" INT  REFERENCES "user" ("user_id") ON DELETE CASCADE,
    "role_id" INT  REFERENCES "role" ("role_id") ON DELETE CASCADE,
    PRIMARY KEY ("user_id", "role_id")
);

CREATE TABLE "session" (
    "session_id" SERIAL PRIMARY KEY,
    "user_id" INT NOT NULL REFERENCES "user" ("user_id") ON DELETE CASCADE,
    "refresh_token" TEXT NOT NULL UNIQUE,
    "device" VARCHAR(255),
    "session_end_date_time" TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE "reading_log" (
    "reading_log_id" SERIAL PRIMARY KEY,
    "equipment_id" INT NOT NULL REFERENCES "equipment" ("equipment_id") ON DELETE CASCADE,
    "status_id" INT NOT NULL REFERENCES "status" ("status_id") ON DELETE RESTRICT,
    "reading_type_id" INT NOT NULL REFERENCES "reading_type" ("reading_type_id") ON DELETE RESTRICT,
    "write_date_time" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    "value" VARCHAR(50) NOT NULL 
);

--Индексы
CREATE INDEX idx_metrics_device_time 
ON "reading_log" ("equipment_id", "write_date_time" DESC);

CREATE INDEX idx_sessions_user ON "session" ("user_id");

--trigger
CREATE OR REPLACE FUNCTION clean_expired_sessions()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM "session" 
    WHERE "user_id" = NEW."user_id" 
      AND "session_end_date_time" < NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_clean_expired_sessions
BEFORE INSERT ON "session"
FOR EACH ROW
EXECUTE FUNCTION clean_expired_sessions();

CREATE OR REPLACE FUNCTION clean_old_reading_logs()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM reading_log 
    WHERE write_date_time < NOW() - INTERVAL '1 year';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_clean_old_logs
AFTER INSERT ON reading_log
FOR EACH STATEMENT 
EXECUTE FUNCTION clean_old_reading_logs();

--Представление
CREATE OR REPLACE VIEW view_latest_equipment_readings AS
WITH ranked_readings AS (
    SELECT 
        rl.equipment_id,
        rl.reading_type_id,
        rl.write_date_time,
        rl.value,
        rl.status_id,
        ROW_NUMBER() OVER (
            PARTITION BY rl.equipment_id, rl.reading_type_id 
            ORDER BY rl.write_date_time DESC
        ) as rn
    FROM reading_log rl
)

SELECT 
    rr.equipment_id,
    rt.identifier AS metric_key,
    rt.name AS label,
    rr.value AS value,
    rt.unit AS unit,
    st.name AS status,
    rr.write_date_time AS datetime
FROM ranked_readings rr
JOIN reading_type rt ON rr.reading_type_id = rt.reading_type_id
JOIN status st ON rr.status_id = st.status_id
WHERE rr.rn = 1; 

--Процедура
CREATE OR REPLACE PROCEDURE create_new_user(
    p_login VARCHAR(20),
    p_hashed_password VARCHAR(255),
    p_first_name VARCHAR(100),
    p_last_name VARCHAR(100),
    p_second_name VARCHAR(100),
    p_role_name VARCHAR(50)
)
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

CALL create_new_user(
    '+79991112233', 
    '$2b$хэшпароля', 
    'Иван', 
    'Иванов', 
    'Игоревич', 
    'Инженер'
);
--Запросы

SELECT * FROM view_latest_equipment_readings;

