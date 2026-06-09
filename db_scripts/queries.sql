INSERT INTO "reading_log" (
    "equipment_id", 
    "status_id", 
    "reading_type_id", 
    "write_date_time", 
    "value"
)
SELECT 
    1 AS "equipment_id",
    floor(random() * 3 + 1)::int AS "status_id",
    t.reading_type_id,
    NOW() - interval '6 month' + (h.hour * INTERVAL '1 hour') AS "write_date_time",
    round((random() * 100)::numeric, 2) AS "value"
FROM 
    generate_series(0, 4368) AS h(hour)
CROSS JOIN 
    generate_series(1, 5) AS t(reading_type_id)
ORDER BY 
    h.hour, t.reading_type_id;

TRUNCATE TABLE "reading_log";

SELECT equipment_id, serial_number, name, last_check_date
FROM "equipment"
WHERE "model" = 'МФ-2000' 
  AND "status_id" = 1
ORDER BY last_check_date ASC;

SELECT rt.name AS reading_name, COUNT(rl.reading_log_id) AS total_logs
FROM "reading_log" rl
JOIN "reading_type" rt ON rl.reading_type_id = rt.reading_type_id
GROUP BY rt.name
HAVING COUNT(rl.reading_log_id) > 1;

SELECT s.session_id, u.login, s.session_end_date_time
FROM "session" s
JOIN "user" u ON s.user_id = u.user_id
WHERE s.device = 'samsung SM-A5660' 
  AND s.session_end_date_time > NOW()
ORDER BY s.session_end_date_time DESC;

SELECT e.name AS equipment_name, e.serial_number, MAX(rl.value) AS max_value
FROM "reading_log" rl
JOIN "equipment" e ON rl.equipment_id = e.equipment_id
JOIN "reading_type" rt ON rl.reading_type_id = rt.reading_type_id
WHERE rt.identifier = 'TEMP_CELSIUS'
GROUP BY e.name, e.serial_number
ORDER BY max_value DESC;

SELECT r.name AS role_name, COUNT(ur.user_id) AS total_users
FROM "role" r
LEFT JOIN "user_role" ur ON r.role_id = ur.role_id
GROUP BY r.name
ORDER BY total_users DESC;