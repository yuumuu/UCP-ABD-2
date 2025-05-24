-- Database
USE master;
CREATE DATABASE SiteFormDB
ON PRIMARY (
	NAME = 'SiteFormDB_MDF',
	FILENAME = 'D:\Projects\databases\ABD UCP 1\SiteFormDB_Master.mdf',
	SIZE = 10MB,
	MAXSIZE = 100MB,
	FILEGROWTH = 20MB
),
FILEGROUP FG_MainData (
	NAME = 'SiteFormDB_MainData_NDF',
	FILENAME = 'D:\Projects\databases\ABD UCP 1\SiteFormDB_Main.ndf',
	SIZE = 10MB,
	MAXSIZE = 100MB,
	FILEGROWTH = 20MB
),
FILEGROUP FG_Transaction (
	NAME = 'SiteFormDB_Transaction_NDF',
	FILENAME = 'D:\Projects\databases\ABD UCP 1\SiteFormDB_Transaction.ndf',
	SIZE = 10MB,
	MAXSIZE = 100MB,
	FILEGROWTH = 20MB
)
LOG ON (
	NAME = 'SiteForm_LDF',
	FILENAME = 'D:\Projects\databases\ABD UCP 1\SiteFormDB_Log.ldf',
	SIZE = 10MB,
	MAXSIZE = 100MB,
	FILEGROWTH = 20MB
);
GO

-- Filegroup Default
ALTER DATABASE SiteFormDB MODIFY FILEGROUP FG_MainData DEFAULT;

USE SiteFormDB;
GO

-- Bikin Schema
CREATE SCHEMA MasterData;
GO
CREATE SCHEMA Transaksi;
GO

-- Unit
CREATE TABLE MasterData.Unit (
	id VARCHAR(10) PRIMARY KEY,

	name NVARCHAR(100) UNIQUE NOT NULL
);

-- User
CREATE TABLE MasterData.[User] (
	id INT IDENTITY(1,1) PRIMARY KEY,
	unit_id VARCHAR(10),

	name NVARCHAR(50) NOT NULL,
	email VARCHAR(100) UNIQUE NOT NULL,
	password VARCHAR(255) NOT NULL,
	role VARCHAR(20) CHECK (role IN ('Admin', 'Platform Manager', 'Content Manager', 'Data Analyst')),

	FOREIGN KEY (unit_id) REFERENCES MasterData.Unit(id)
);

-- CustomUI
CREATE TABLE MasterData.CustomUI (
	id INT IDENTITY(1,1) PRIMARY KEY,

	custom_data NVARCHAR(MAX), -- ntar dijadiin JSON
);

-- Template
CREATE TABLE MasterData.Template (
	id INT IDENTITY(1,1) PRIMARY KEY,

	name NVARCHAR(100) UNIQUE NOT NULL,
	description NVARCHAR(MAX),
	template_data NVARCHAR(MAX) -- JSON juga
);

-- Microsite
CREATE TABLE MasterData.Microsite (
	id INT IDENTITY(1,1) PRIMARY KEY,
	unit_id VARCHAR(10),
	template_id INT,
	custom_ui_id INT,
	user_id INT,

	title NVARCHAR(100) NOT NULL,
	subdomain NVARCHAR(255) UNIQUE NOT NULL,

	FOREIGN KEY (unit_id) REFERENCES MasterData.Unit(id),
	FOREIGN KEY (template_id) REFERENCES MasterData.Template(id),
	FOREIGN KEY (custom_ui_id) REFERENCES MasterData.CustomUI(id),
	FOREIGN KEY (user_id) REFERENCES MasterData.[User](id)
);

-- Section
CREATE TABLE MasterData.Section (
	id INT IDENTITY(1,1) PRIMARY KEY,
	microsite_id INT,

	title NVARCHAR(100) NOT NULL,
	content NVARCHAR(MAX),
	[order] INT,

	FOREIGN KEY (microsite_id) REFERENCES MasterData.Microsite(id)
);

-- Formulir
CREATE TABLE MasterData.Formulir (
	id INT IDENTITY(1,1) PRIMARY KEY,
	microsite_id INT,

	title NVARCHAR(100),
	custom_url NVARCHAR(255),
	description NVARCHAR(MAX),

	FOREIGN KEY (microsite_id) REFERENCES MasterData.Microsite(id)
);

-- Field
CREATE TABLE MasterData.Field (
	id INT IDENTITY(1,1) PRIMARY KEY,
	formulir_id INT,

	label NVARCHAR(100),
	field_type NVARCHAR(50),
	[order] INT,
	settings NVARCHAR(MAX),

	FOREIGN KEY (formulir_id) REFERENCES MasterData.Formulir(id)
);

-- Submission
CREATE TABLE Transaksi.Submission (
	id INT IDENTITY(1,1) PRIMARY KEY,
	formulir_id INT,

	submission_data NVARCHAR(MAX),
	submitted_at DATETIME,
	FOREIGN KEY (formulir_id) REFERENCES MasterData.Formulir(id)
) ON FG_Transaction;

-- Bikin akun
USE master;
-- CREATE LOGIN AdminUser WITH PASSWORD = 'AU123'; -- ga dijalankan soalnya dah ada dari yang sebelum2nya
CREATE LOGIN ContentManagerUser WITH PASSWORD = 'CMU123';
CREATE LOGIN PlatformManagerUser WITH PASSWORD = 'PMU123';
CREATE LOGIN DataAnalystUser WITH PASSWORD = 'DAU123';

USE SiteFormDB;
CREATE USER ContentManagerUser FOR LOGIN ContentManagerUser;
CREATE USER PlatformManagerUser FOR LOGIN PlatformManagerUser;
CREATE USER DataAnalystUser FOR LOGIN DataAnalystUser;

USE SiteFormDB;
CREATE ROLE ContentManagerRole;
CREATE ROLE PlatformManagerRole;
CREATE ROLE DataAnalystRole;

-- PlatformManager
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::MasterData TO PlatformManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Transaksi TO PlatformManagerRole;

REVOKE DELETE ON Transaksi.Submission TO PlatformManagerRole;
DENY DELETE ON Transaksi.Submission TO PlatformManagerRole;

-- ContentManager
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::MasterData TO ContentManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Transaksi TO ContentManagerRole;

REVOKE DELETE ON Transaksi.Submission TO ContentManagerRole;
DENY DELETE ON Transaksi.Submission TO ContentManagerRole;

-- DataAnalyst
GRANT SELECT ON SCHEMA::MasterData TO DataAnalystRole;
GRANT SELECT ON SCHEMA::Transaksi TO DataAnalystRole;

REVOKE SELECT ON MasterData.Template TO DataAnalystRole;
REVOKE SELECT ON MasterData.CustomUI TO DataAnalystRole;

-- Nambahin User ke Role
EXEC sp_addrolemember 'ContentManagerRole', 'ContentManagerUser';
EXEC sp_addrolemember 'PlatformManagerRole', 'PlatformManagerUser';
EXEC sp_addrolemember 'DataAnalystRole', 'DataAnalystUser';

-- Partition
USE SiteFormDB;
CREATE PARTITION FUNCTION PF_SubmissionDateRange (DATETIME)
AS RANGE LEFT FOR VALUES ('2022-12-31', '2024-12-31');

CREATE PARTITION SCHEME PS_SubmissionScheme
AS PARTITION PF_SubmissionDateRange
TO (FG_MainData, FG_Transaction, FG_Transaction);

-- INDEX
CREATE INDEX IDX_Submission_Date
ON Transaksi.Submission (submitted_at)
ON PS_SubmissionScheme (submitted_at);

CREATE INDEX IDX_User_Name
ON MasterData.[User] (username);

CREATE INDEX IDX_Microsite_Subdomain
ON MasterData.Microsite (subdomain);

SELECT * FROM sys.dm_io_virtual_file_stats(NULL, NULL); 

SELECT * FROM sys.dm_os_wait_stats
WHERE wait_type LIKE 'PAGEIOLATCH_%' OR wait_type LIKE 'IO_COMPLETION';

SELECT
	total_physical_memory_kb / 1024 AS Total_Physical_Memory_MB,
	available_physical_memory_kb / 1024 AS Available_Physical_Memory_MB,
	system_memory_state_desc
FROM sys.dm_os_sys_memory;

-- mengaktifkan buffer pool extension
ALTER SERVER CONFIGURATION
SET BUFFER POOL EXTENSION ON
(FILENAME = 'D:\Projects\databases\BPECache.bpe', SIZE = 20GB);

ALTER SERVER CONFIGURATION SET BUFFER POOL EXTENSION OFF;