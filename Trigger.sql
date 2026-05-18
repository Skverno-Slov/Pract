USE ArkhangelskOrtpcDb;
GO

CREATE TRIGGER tr_Maintenance_CheckEquipmentStatus
ON [Maintenance]
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN [Equipment] e ON i.EquipmentId = e.EquipmentId
        JOIN [EquipmentStatus] es ON e.EquipmentStatusId = es.EquipmentStatusId
        WHERE es.Name IN (N'В ремонте', N'Списано', N'Утеряно')
    )
    BEGIN
        RAISERROR (N'Ошибка: Выбранное оборудование находится в ремонте или списано.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    INSERT INTO [Maintenance] (
        [EmployeeId], [EquipmentId], [ServiceTypeId], [ComplaintId], 
        [TransmittingStationId], [MaintenanceDate], [MeasurementLatitude], 
        [MeasurementLongitude], [SignalStrength], [SignalQuality], [PhotoReportPath]
    )
    SELECT 
        [EmployeeId], [EquipmentId], [ServiceTypeId], [ComplaintId], 
        [TransmittingStationId], ISNULL([MaintenanceDate], GETDATE()), [MeasurementLatitude], 
        [MeasurementLongitude], [SignalStrength], [SignalQuality], [PhotoReportPath]
    FROM inserted;
END;
GO