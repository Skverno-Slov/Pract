USE ArkhangelskOrtpcDb;
GO

CREATE PROCEDURE sp_RecordMaintenance
    @EmployeeId INT,
    @EquipmentId INT,
    @ServiceTypeId INT,
    @ComplaintId INT,
    @StationId INT,
    @Lat DECIMAL(9,6),
    @Lon DECIMAL(9,6),
    @Strength DECIMAL(5,2),
    @Quality DECIMAL(5,2),
    @PhotoPath NVARCHAR(500),
    @NewStatusId INT 
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO [Maintenance] (
            [EmployeeId], [EquipmentId], [ServiceTypeId], [ComplaintId], 
            [TransmittingStationId], [MeasurementLatitude], [MeasurementLongitude], 
            [SignalStrength], [SignalQuality], [PhotoReportPath], [MaintenanceDate]
        )
        VALUES (
            @EmployeeId, @EquipmentId, @ServiceTypeId, @ComplaintId, 
            @StationId, @Lat, @Lon, @Strength, @Quality, @PhotoPath, GETDATE()
        );

        IF @ComplaintId IS NOT NULL
        BEGIN
            UPDATE [Complaint]
            SET [ServiceStatusId] = @NewStatusId
            WHERE [ComplaintId] = @ComplaintId;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

EXEC sp_RecordMaintenance 
    @EmployeeId = 5, 
    @EquipmentId = 2, 
    @ServiceTypeId = 1, 
    @ComplaintId = 10, 
    @StationId = 1, 
    @Lat = 64.53, @Lon = 40.54, 
    @Strength = -75.4, @Quality = 98.0, 
    @PhotoPath = 'path/to/img.jpg',
    @NewStatusId = 3; 