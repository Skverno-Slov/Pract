--Статистика использования оборудования
SELECT 
    e.Model,
    e.SerialNumber,
    es.Name AS CurrentStatus,
    COUNT(m.MaintenanceId) AS UsageCount,
    MAX(m.MaintenanceDate) AS LastUsedDate
FROM [Equipment] e
LEFT JOIN [EquipmentStatus] es ON e.EquipmentStatusId = es.EquipmentStatusId
LEFT JOIN [Maintenance] m ON e.EquipmentId = m.EquipmentId
GROUP BY e.Model, e.SerialNumber, es.Name
ORDER BY UsageCount DESC;

--Рейтинг инженеров по количеству закрытых жалоб
SELECT 
    u.LastName + ' ' + u.FirstName AS EngineerName,
    COUNT(DISTINCT m.ComplaintId) AS ClosedComplaintsCount
FROM [Employee] e
JOIN [User] u ON e.UserId = u.UserId
JOIN [Maintenance] m ON e.EmployeeId = m.EmployeeId
WHERE m.ComplaintId IS NOT NULL 
  AND m.MaintenanceDate >= DATEADD(MONTH, -1, GETDATE()) -- За последний месяц
GROUP BY u.LastName, u.FirstName
ORDER BY ClosedComplaintsCount DESC;

--Поиск вышек с самым низким качеством сигнала
SELECT 
    ts.Name AS StationName,
    COUNT(m.MaintenanceId) AS TotalMeasurements,
    AVG(m.SignalStrength) AS AvgStrength,
    AVG(m.SignalQuality) AS AvgQuality
FROM [TransmittingStation] ts
JOIN [Maintenance] m ON ts.TransmittingStationId = m.TransmittingStationId
GROUP BY ts.Name
HAVING AVG(m.SignalQuality) < 70.0
ORDER BY AvgQuality ASC;