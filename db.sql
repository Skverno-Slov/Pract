CREATE DATABASE ArkhangelskOrtpcDb;
GO

USE ArkhangelskOrtpcDb;
GO

CREATE TABLE [Role] (
    [RoleId] INT PRIMARY KEY IDENTITY(1,1),
    [Name] NVARCHAR(50) NOT NULL
);

CREATE TABLE [User] (
    [UserId] INT PRIMARY KEY IDENTITY(1,1),
    [PhoneNumber] NVARCHAR(20) NOT NULL,
    [PasswordHash] NVARCHAR(255) NOT NULL,
    [LastName] NVARCHAR(100) NOT NULL,
    [FirstName] NVARCHAR(100) NOT NULL,
    [MiddleName] NVARCHAR(100),
    CONSTRAINT [UQ_User_Phone] UNIQUE ([PhoneNumber])
);

CREATE TABLE [UserRole] (
    [UserId] INT NOT NULL,
    [RoleId] INT NOT NULL,
    PRIMARY KEY ([UserId], [RoleId]),
    CONSTRAINT [FK_UserRole_User] FOREIGN KEY ([UserId]) REFERENCES [User]([UserId]) ON DELETE CASCADE,
    CONSTRAINT [FK_UserRole_Role] FOREIGN KEY ([RoleId]) REFERENCES [Role]([RoleId]) ON DELETE CASCADE
);

CREATE TABLE [Applicant] (
    [ApplicantId] INT PRIMARY KEY IDENTITY(1,1),
    [UserId] INT NOT NULL,
    [Address] NVARCHAR(255),
    [ContactInfo] NVARCHAR(MAX),
    CONSTRAINT [FK_Applicant_User] FOREIGN KEY ([UserId]) REFERENCES [User]([UserId])
);

CREATE TABLE [ServiceStatus] (
    [ServiceStatusId] INT PRIMARY KEY IDENTITY(1,1),
    [Name] NVARCHAR(50) NOT NULL
);

CREATE TABLE [Complaint] (
    [ComplaintId] INT PRIMARY KEY IDENTITY(1,1),
    [ApplicantId] INT NOT NULL,
    [ServiceStatusId] INT NOT NULL,
    [Address] NVARCHAR(255) NOT NULL,
    [Description] NVARCHAR(MAX) NOT NULL,
    [ComplaintDate] DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [FK_Complaint_Applicant] FOREIGN KEY ([ApplicantId]) REFERENCES [Applicant]([ApplicantId]),
    CONSTRAINT [FK_Complaint_Status] FOREIGN KEY ([ServiceStatusId]) REFERENCES [ServiceStatus]([ServiceStatusId])
);

CREATE TABLE [Employee] (
    [EmployeeId] INT PRIMARY KEY IDENTITY(1,1),
    [UserId] INT NOT NULL,
    [ManagerId] INT NULL,
    [ContactInfo] NVARCHAR(MAX),
    CONSTRAINT [FK_Employee_User] FOREIGN KEY ([UserId]) REFERENCES [User]([UserId]),
    CONSTRAINT [FK_Employee_Manager] FOREIGN KEY ([ManagerId]) REFERENCES [Employee]([EmployeeId])
);

CREATE TABLE [EquipmentStatus] (
    [EquipmentStatusId] INT PRIMARY KEY IDENTITY(1,1),
    [Name] NVARCHAR(50) NOT NULL
);

CREATE TABLE [Equipment] (
    [EquipmentId] INT PRIMARY KEY IDENTITY(1,1),
    [EquipmentStatusId] INT NOT NULL,
    [Model] NVARCHAR(100) NOT NULL,
    [SerialNumber] NVARCHAR(100) NOT NULL,
    [LastVerificationDate] DATE,
    CONSTRAINT [FK_Equipment_Status] FOREIGN KEY ([EquipmentStatusId]) REFERENCES [EquipmentStatus]([EquipmentStatusId])
);

CREATE TABLE [ServiceType] (
    [ServiceTypeId] INT PRIMARY KEY IDENTITY(1,1),
    [Name] NVARCHAR(100) NOT NULL
);

CREATE TABLE [TransmittingStation] (
    [TransmittingStationId] INT PRIMARY KEY IDENTITY(1,1),
    [Name] NVARCHAR(150) NOT NULL,
    [Latitude] DECIMAL(9, 6) NOT NULL,
    [Longitude] DECIMAL(9, 6) NOT NULL,
    [Address] NVARCHAR(255),
    [AntennaHeight] DECIMAL(6, 2),
    [ReferencePower] DECIMAL(10, 2)
);

CREATE TABLE [Maintenance] (
    [MaintenanceId] INT PRIMARY KEY IDENTITY(1,1),
    [EmployeeId] INT NOT NULL,
    [EquipmentId] INT NOT NULL,
    [ServiceTypeId] INT NOT NULL,
    [ComplaintId] INT NULL,
    [TransmittingStationId] INT NOT NULL,
    [MaintenanceDate] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [MeasurementLatitude] DECIMAL(9, 6),
    [MeasurementLongitude] DECIMAL(9, 6),
    [SignalStrength] DECIMAL(5, 2), -- дЅм
    [SignalQuality] DECIMAL(5, 2), -- например, BER или %
    [PhotoReportPath] NVARCHAR(500),
    CONSTRAINT [FK_Maintenance_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [Employee]([EmployeeId]),
    CONSTRAINT [FK_Maintenance_Equipment] FOREIGN KEY ([EquipmentId]) REFERENCES [Equipment]([EquipmentId]),
    CONSTRAINT [FK_Maintenance_ServiceType] FOREIGN KEY ([ServiceTypeId]) REFERENCES [ServiceType]([ServiceTypeId]),
    CONSTRAINT [FK_Maintenance_Complaint] FOREIGN KEY ([ComplaintId]) REFERENCES [Complaint]([ComplaintId]),
    CONSTRAINT [FK_Maintenance_Station] FOREIGN KEY ([TransmittingStationId]) REFERENCES [TransmittingStation]([TransmittingStationId])
);
GO
