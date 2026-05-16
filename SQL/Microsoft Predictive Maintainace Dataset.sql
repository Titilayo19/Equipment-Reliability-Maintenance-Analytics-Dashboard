---checking for duplicate
SELECT 
    machineID,
    datetime,
    COUNT(*)
FROM PdM_telemetry
GROUP BY machineID, datetime
HAVING COUNT(*) > 1;

--- checking for null
SELECT *
FROM PdM_telemetry
WHERE volt IS NULL
   OR rotate IS NULL
   OR pressure IS NULL
   OR vibration IS NULL;

--- Top failure 
SELECT 
    failure,
    COUNT(*) AS total_failures
FROM PdM_failures
GROUP BY failure
ORDER BY total_failures DESC;

--- which machine fails most?
SELECT TOP 10
    machineID,
    COUNT(*) AS failures
FROM PdM_failures
GROUP BY machineID
ORDER BY failures DESC;

--- which model fails most?
SELECT 
    m.model,
    COUNT(f.failure) AS total_failures
FROM PdM_failures f
JOIN PdM_machines m
ON f.machineID = m.machineID
GROUP BY m.model
ORDER BY total_failures DESC;

--- sensor average by model
SELECT 
    m.model,
    AVG(t.volt) AS avg_volt,
    AVG(t.rotate) AS avg_rotation,
    AVG(t.pressure) AS avg_pressure,
    AVG(t.vibration) AS avg_vibration
FROM PdM_telemetry t
JOIN PdM_machines m
ON t.machineID = m.machineID
GROUP BY m.model;

---To extract the sensor readings 24 hours before failure
SELECT TOP 100
    f.machineID,
    f.datetime AS failure_time,
    t.datetime AS telemetry_time,
    t.volt,
    t.rotate,
    t.pressure,
    t.vibration,
    f.failure
FROM PdM_failures f
JOIN PdM_telemetry t
ON f.machineID = t.machineID
AND t.datetime BETWEEN DATEADD(hour, -24, f.datetime)
                   AND f.datetime
ORDER BY f.machineID, f.datetime;

---machine with the highest vibration
SELECT TOP 10
    machineID,
    AVG(vibration) AS avg_vibration
FROM PdM_telemetry
GROUP BY machineID
ORDER BY avg_vibration DESC;

---machine age vs machine failure
SELECT 
    m.age,
    COUNT(f.failure) AS total_failures
FROM PdM_machines m
LEFT JOIN PdM_failures f
ON m.machineID = f.machineID
GROUP BY m.age
ORDER BY m.age;

SELECT TOP 200
    f.machineID,
    f.failure,
    f.datetime AS failure_time,
    AVG(t.vibration) AS avg_vibration_before_failure,
    AVG(t.pressure) AS avg_pressure_before_failure,
    AVG(t.rotate) AS avg_rotation_before_failure
FROM PdM_failures f
JOIN PdM_telemetry t
ON f.machineID = t.machineID
AND t.datetime BETWEEN DATEADD(hour, -24, f.datetime)
                   AND f.datetime
GROUP BY
    f.machineID,
    f.failure,
    f.datetime
ORDER BY avg_vibration_before_failure DESC;

SELECT
    m.machineID,
    m.age,
    m.model,
    COUNT(DISTINCT f.failure) AS total_failures,
    AVG(t.vibration) AS avg_vibration,
    AVG(t.pressure) AS avg_pressure
FROM PdM_machines m
LEFT JOIN PdM_failures f
ON m.machineID = f.machineID
LEFT JOIN PdM_telemetry t
ON m.machineID = t.machineID
GROUP BY
    m.machineID,
    m.age,
    m.model
ORDER BY total_failures DESC;

---failure trend over time
SELECT
    YEAR(datetime) AS year,
    MONTH(datetime) AS month,
    COUNT(*) AS total_failures
FROM PdM_failures
GROUP BY
    YEAR(datetime),
    MONTH(datetime)
ORDER BY year, month;

SELECT
    datetime,
    failure,
    COUNT(*) AS daily_failures,
    SUM(COUNT(*)) OVER (
        ORDER BY datetime
    ) AS running_total_failures
FROM PdM_failures
GROUP BY
    datetime,
    failure
ORDER BY datetime;

---order of machineID according to total failure
SELECT
    machineID,
    COUNT(*) AS total_failures,
    RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS failure_rank
FROM PdM_failures
GROUP BY machineID;