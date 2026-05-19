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
--Представление
--Процедура
--Запросы