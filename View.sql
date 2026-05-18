USE ArkhangelskOrtpcDb;
GO

CREATE VIEW vw_SignalProblemAnalysis AS
SELECT 
    c.ComplaintId,
    c.ComplaintDate,
    s.Name AS CurrentStatus,
    u_app.LastName + ' ' + LEFT(u_app.FirstName, 1) + '.' AS ApplicantName,
    c.Address AS ProblemAddress,
    ts.Name AS TargetStation,
    ts.ReferencePower AS ExpectedPower,
    m.MaintenanceDate AS InspectionDate,
    m.SignalStrength AS ActualStrength,
    m.SignalQuality AS ActualQuality,
    (m.SignalStrength - ts.ReferencePower) AS SignalDeviation,
    u_emp.LastName AS InspectorLastName
FROM [Complaint] c
JOIN [ServiceStatus] s ON c.ServiceStatusId = s.ServiceStatusId
JOIN [Applicant] a ON c.ApplicantId = a.ApplicantId
JOIN [User] u_app ON a.UserId = u_app.UserId
LEFT JOIN [Maintenance] m ON c.ComplaintId = m.ComplaintId
LEFT JOIN [TransmittingStation] ts ON m.TransmittingStationId = ts.TransmittingStationId
LEFT JOIN [Employee] e ON m.EmployeeId = e.EmployeeId
LEFT JOIN [User] u_emp ON e.UserId = u_emp.UserId;
GO