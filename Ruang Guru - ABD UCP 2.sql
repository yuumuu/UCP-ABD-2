-- Membuat Database
USE master;
CREATE DATABASE RuangGuru
ON PRIMARY (
	NAME		= 'RG_MDF',
	FILENAME	= 'D:\Projects\databases\ABD UCP 2\RG_Primary.mdf',
	SIZE		= 10MB,
	MAXSIZE		= 100MB,
	FILEGROWTH	= 5MB
),
FILEGROUP RG_Main (
	NAME		= 'RG_Main_NDF',
	FILENAME	= 'D:\Projects\databases\ABD UCP 2\RG_Main.ndf',
	SIZE		= 10MB,
	MAXSIZE		= 100MB,
	FILEGROWTH	= 5MB
),
FILEGROUP RG_Transaction (
	NAME		= 'RG_Transaction_NDF',
	FILENAME	= 'D:\Projects\databases\ABD UCP 2\RG_Transaction.ndf',
	SIZE		= 10MB,
	MAXSIZE		= 100MB,
	FILEGROWTH	= 5MB
)
LOG ON (
	NAME		= 'RG_LDF',
	FILENAME	= 'D:\Projects\databases\ABD UCP 2\RG_Log.ldf',
	SIZE		= 10MB,
	MAXSIZE		= 100MB,
	FILEGROWTH	= 5MB
);
GO

-- Filegroup default
ALTER DATABASE RuangGuru MODIFY FILEGROUP RG_Main DEFAULT;

USE RuangGuru;
GO

-- Schema
CREATE SCHEMA Masters;
GO
CREATE SCHEMA Transactions;
GO

-- User Table
CREATE TABLE Masters.[User] (
	IDUser INT IDENTITY(1,1) PRIMARY KEY,
	Nama VARCHAR(100) NOT NULL,
	Email VARCHAR(100) NOT NULL,
	Password VARCHAR(255) NOT NULL,
	Role VARCHAR(50) CHECK (Role IN ('Admin', 'Guru'))
);

-- Guru Table
CREATE TABLE Masters.Guru (
	IDGuru INT IDENTITY(1,1) PRIMARY KEY,
	IDUser INT NOT NULL,
	Nama VARCHAR(100) NOT NULL,
	NIP VARCHAR(100) NOT NULL,

	FOREIGN KEY (IDUser) REFERENCES Masters.[User](IDUser)
);

-- Mapel Table
CREATE TABLE Masters.Mapel (
	IDMapel INT IDENTITY(1,1) PRIMARY KEY,
	Nama VARCHAR(100) NOT NULL,
	[Desc] TEXT NOT NULL
);

-- Kelas Table
CREATE TABLE Masters.Kelas (
	IDKelas INT IDENTITY(1,1) PRIMARY KEY,
	Nama VARCHAR(100) NOT NULL
);

-- Jadwal Table
CREATE TABLE Transactions.Jadwal (
	IDJadwal INT IDENTITY(1,1) PRIMARY KEY,
	IDGuru INT NOT NULL,
	IDMapel INT NOT NULL,
	IDKelas INT NOT NULL,
	Hari VARCHAR(20) CHECK (Hari IN ('Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu')),
	JamMulai TIME NOT NULL DEFAULT CAST(GETDATE() AS TIME),
	JamSelesai TIME NOT NULL DEFAULT CAST(GETDATE() AS TIME),

	FOREIGN KEY (IDGuru) REFERENCES Masters.Guru (IDGuru),
	FOREIGN KEY (IDMapel) REFERENCES Masters.Mapel (IDMapel),
	FOREIGN KEY (IDKelas) REFERENCES Masters.Kelas (IDKelas)
) ON RG_Transaction;

-- Absensi Table
CREATE TABLE Transactions.Absensi (
	IDAbsensi INT IDENTITY(1,1) PRIMARY KEY,
	IDJadwal INT NOT NULL,
	Tanggal DATETIME NOT NULL DEFAULT GETDATE(),
	Status VARCHAR(20) CHECK (Status IN ('Hadir', 'Izin', 'Sakit', 'Alfa')),

	FOREIGN KEY (IDJadwal) REFERENCES Transactions.Jadwal (IDJadwal)
) ON PS_AbsensiScheme(Tanggal);

-- Buat Akun Login Server
USE master;
CREATE LOGIN AdminRG WITH PASSWORD = '12345678';
CREATE LOGIN GuruRG WITH PASSWORD = '12345678';

-- Buat Akun Login Database
USE RuangGuru;
CREATE USER AdminRG FOR LOGIN AdminRG;
CREATE USER GuruRG FOR LOGIN GuruRG;

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Masters TO AdminRG;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Transactions TO AdminRG;

GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::Masters.Mapel TO GuruRG;
GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::Masters.Kelas TO GuruRG;
GRANT SELECT ON SCHEMA::Transactions TO GuruRG;
GRANT INSERT ON OBJECT::Transactions.Absensi TO GuruRG;

-- Partition Function
USE RuangGuru;
CREATE PARTITION FUNCTION PF_AbsensiDate (DATETIME)
AS RANGE LEFT FOR VALUES ('2019-12-31', '2024-12-31');

-- Partition Scheme
CREATE PARTITION SCHEME PS_AbsensiScheme
AS PARTITION PF_AbsensiDate
TO (RG_Main, RG_Transaction, RG_Transaction);

-- Index Guru
CREATE INDEX IDX_Guru_Nama
ON Masters.Guru (Nama);

-- Index Mapel
CREATE INDEX IDX_Mapel_Nama
ON Masters.Mapel (Nama);

-- Index Kelas
CREATE INDEX IDX_Kelas_Nama
ON Masters.Kelas (Nama);

-- Index Jadwal
CREATE INDEX IDX_Jadwal_Mapel_Kelas_Hari
ON Transactions.Jadwal (IDMapel, IDKelas, Hari);

-- Index Absensi
CREATE INDEX IDX_Absensi_Jadwal_Tanggal
ON Transactions.Absensi (IDJadwal, Tanggal)
ON PS_AbsensiScheme (Tanggal);

-- Melihat Statistik I/O dari File Database
SELECT
	db_name(database_id) AS DatabaseName,
	file_id,
	io_stall_read_ms,
	io_stall_write_ms,
	num_of_reads,
	num_of_writes
FROM sys.dm_io_virtual_file_stats(NULL, NULL);

-- Mengecek Aktivitas Disk di SQL Server
SELECT * FROM sys.dm_os_wait_stats
WHERE wait_type LIKE 'PAGEIOLATCH%';

-- Backup Database
-- tambahkan data sebelum backup full
INSERT INTO Transactions.Absensi
VALUES
(5, 1, '2024-03-31', 'Izin'),
(6, 2, '2024-03-31', 'Hadir'),
(7, 1, '2024-04-06', 'Hadir'),
(8, 2, '2024-04-06', 'Hadir');

-- FULL BACKUP
BACKUP DATABASE RuangGuru
TO DISK = 'D:\Projects\databases\ABD UCP 2\Backup_RG_Full.bak'
WITH INIT, FORMAT, NAME = 'Full Backup RuangGuru';

-- FULL RECOVERY
RESTORE DATABASE RuangGuru
FROM DISK = 'D:\Projects\databases\ABD UCP 2\Backup_RG_Full.bak'
WITH NORECOVERY;

-- tambahkan data sebelum backup diferensial
INSERT INTO Transactions.Absensi
VALUES
(9, 1, '2024-04-13', 'Hadir'),
(10, 2, '2024-04-13', 'Hadir'),
(11, 1, '2024-04-20', 'Hadir'),
(12, 2, '2024-04-20', 'Hadir');

-- DIFFERENTIAL BACKUP
BACKUP DATABASE RuangGuru
TO DISK = 'D:\Projects\databases\ABD UCP 2\Backup_RG_Diff.bak'
WITH DIFFERENTIAL, INIT, NAME = 'Differential Backup RuangGuru';

-- DIFFERENTIAL RESTORE
RESTORE DATABASE RuangGuru
FROM DISK = 'D:\Projects\databases\ABD UCP 2\Backup_RG_Diff.bak'
WITH NORECOVERY;

-- tambahkan data sebelum backup transaction log
INSERT INTO Transactions.Absensi
VALUES
(13, 1, '2024-04-27', 'Hadir'),
(14, 2, '2024-04-27', 'Hadir'),
(15, 1, '2024-05-04', 'Hadir'),
(16, 2, '2024-05-04', 'Sakit');

-- TRANSACTION LOG BACKUP
BACKUP LOG RuangGuru
TO DISK = 'D:\Projects\databases\ABD UCP 2\Backup_RG_Log.trn'
WITH INIT, NAME = 'Transaction Log Backup RuangGuru';

-- TRANSACTION LOG RESTORE
RESTORE LOG RuangGuru
FROM DISK = 'D:\Projects\databases\ABD UCP 2\Backup_RG_Log.trn'
WITH RECOVERY;



-- Setting isolation level dan transaksi
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

INSERT INTO Transactions.Absensi (IDJadwal, Tanggal, Status)
VALUES (1, GETDATE(), 'Hadir');

-- Commit Transaksi
COMMIT;

-- Query paling berat berdasarkan waktu rata-rata
SELECT TOP 5
    qs.total_elapsed_time / qs.execution_count AS [Avg Exec Time],
    qs.execution_count,
    qt.text AS [Query]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY [Avg Exec Time] DESC;

