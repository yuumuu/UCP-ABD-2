-- Membuat Database
USE master;
GO

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
	UserID INT IDENTITY(1,1) PRIMARY KEY,
	Nama VARCHAR(100) NOT NULL,
	Email VARCHAR(100) NOT NULL UNIQUE,
	Password VARCHAR(255) NOT NULL,
	Role VARCHAR(10) NOT NULL CHECK (Role IN ('Admin', 'Guru'))
);

-- Guru Table
CREATE TABLE Masters.Guru (
	GuruID INT IDENTITY(1,1) PRIMARY KEY,
	UserID INT NOT NULL,
	NamaLengkap VARCHAR(100) NOT NULL,
	NIP VARCHAR(30) NOT NULL UNIQUE,

	FOREIGN KEY (UserID) REFERENCES Masters.[User](UserID)
);

-- Mapel Table
CREATE TABLE Masters.Mapel (
	MapelID INT IDENTITY(1,1) PRIMARY KEY,
	Nama VARCHAR(100) NOT NULL,
	[Desc] TEXT NOT NULL
);

-- Kelas Table
CREATE TABLE Masters.Kelas (
	KelasID INT IDENTITY(1,1) PRIMARY KEY,
	Nama VARCHAR(100) NOT NULL
);

-- Jadwal Table
CREATE TABLE Transactions.Jadwal (
	JadwalID INT IDENTITY(1,1) PRIMARY KEY,
	GuruID INT NOT NULL,
	MapelID INT NOT NULL,
	KelasID INT NOT NULL,
	Hari VARCHAR(10) NOT NULL CHECK (Hari IN ('Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu')),
	JamMulai TIME NOT NULL,
	JamSelesai TIME NOT NULL,

	FOREIGN KEY (GuruID) REFERENCES Masters.Guru (GuruID),
	FOREIGN KEY (MapelID) REFERENCES Masters.Mapel (MapelID),
	FOREIGN KEY (KelasID) REFERENCES Masters.Kelas (KelasID)
) ON RG_Transaction;

-- Absensi Table
CREATE TABLE Transactions.Absensi (
	AbsensiID INT IDENTITY(1,1) PRIMARY KEY,
	JadwalID INT NOT NULL,
	Tanggal DATETIME NOT NULL DEFAULT GETDATE(),
	Status VARCHAR(10) CHECK (Status IN ('Hadir', 'Izin', 'Sakit', 'Alfa')),

	FOREIGN KEY (JadwalID) REFERENCES Transactions.Jadwal (JadwalID)
) ON RG_Transaction;

CREATE TABLE AuditLogs (
	LogID INT IDENTITY(1,1) PRIMARY KEY,
	TableName VARCHAR(50),
	[Status] CHAR(10) CHECK ([Status] IN ('SUCCESS', 'ERROR')),
	ActionType VARCHAR(50) CHECK (ActionType IN ('INSERT', 'SELECT', 'UPDATE', 'DELETE')),
	Detail TEXT,
	ChangedBy VARCHAR(100),
	ChangeDate DATETIME DEFAULT GETDATE()
);

-- Buat Akun Login Server
USE master;
CREATE LOGIN AdminRG WITH PASSWORD = '12345678';
CREATE LOGIN GuruRG WITH PASSWORD = '12345678';

-- Buat Akun User Database
USE RuangGuru;
GO

CREATE USER AdminRG FOR LOGIN AdminRG;
CREATE USER GuruRG FOR LOGIN GuruRG;

-- Hak Akses Admin
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Masters TO AdminRG;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Transactions TO AdminRG;

-- Hak Akses Guru
GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::Masters.Mapel TO GuruRG;
GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::Masters.Kelas TO GuruRG;
GRANT SELECT ON SCHEMA::Transactions TO GuruRG;
GRANT INSERT ON OBJECT::Transactions.Absensi TO GuruRG;

-- Data Dummy
-- SQL FILE buat nambah data Sistem RuangGuru
USE RuangGuru;
INSERT INTO Masters.[User]
VALUES
('Admin 1', 'admin1@mail.com', '12345678', 'Admin'),
('Guru 1', 'guru1@mail.com', '12345678', 'Guru'),
('Guru 2', 'guru2@mail.com', '12345678', 'Guru');

INSERT INTO Masters.Guru
VALUES
(2, 'Budiono Siregar', '202401'),
(3, 'Muhammad Sumbul', '202402');

INSERT INTO Masters.Mapel
VALUES
('ABD', 'Administrasi Basis Data'),
('PBD', 'Perencanaan Basis Data');

INSERT INTO Masters.Kelas
VALUES
('A'),
('B');

INSERT INTO Transactions.Jadwal
VALUES
(1, 1, 1, 'Senin', '09:00:00', '12:00:00'),
(2, 2, 2, 'Senin', '03:00:00', '15:00:00');

INSERT INTO Transactions.Absensi
VALUES
(1, '2024-03-17', 'Hadir'),
(2, '2024-03-17', 'Hadir'),
(1, '2024-03-24', 'Izin'),
(2, '2024-03-24', 'Alfa');

-- Backup Database
-- tambahkan data sebelum backup full
INSERT INTO Transactions.Absensi
VALUES
(1, '2024-03-31', 'Izin'),
(2, '2024-03-31', 'Hadir'),
(1, '2024-04-06', 'Hadir'),
(2, '2024-04-06', 'Hadir');

-- FULL BACKUP
BACKUP DATABASE RuangGuru
TO DISK = 'D:\Projects\databases\ABD UCP 2\Backup_RG_Full.bak'
WITH INIT, FORMAT, NAME = 'Full Backup RuangGuru';
GO
-- FULL RECOVERY
RESTORE DATABASE RuangGuru
FROM DISK = 'D:\Projects\databases\ABD UCP 2\Backup_RG_Full.bak'
WITH NORECOVERY;

USE RuangGuru;
-- tambahkan data sebelum backup diferensial
INSERT INTO Transactions.Absensi
VALUES
(1, '2024-04-13', 'Hadir'),
(2, '2024-04-13', 'Hadir'),
(1, '2024-04-20', 'Hadir'),
(2, '2024-04-20', 'Hadir');

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
(1, '2024-04-27', 'Hadir'),
(2, '2024-04-27', 'Hadir'),
(1, '2024-05-04', 'Hadir'),
(2, '2024-05-04', 'Sakit');

ALTER DATABASE RuangGuru SET RECOVERY FULL;

-- TRANSACTION LOG BACKUP
BACKUP LOG RuangGuru
TO DISK = 'D:\Projects\databases\ABD UCP 2\Backup_RG_Log.trn'
WITH INIT, NAME = 'Transaction Log Backup RuangGuru';

-- TRANSACTION LOG RESTORE
RESTORE LOG RuangGuru
FROM DISK = 'D:\Projects\databases\ABD UCP 2\Backup_RG_Log.trn'
WITH NORECOVERY;

RESTORE DATABASE RuangGuru WITH RECOVERY;

-- Pengaplikasian Transaction & Locking Mechanism
-- Atomicity
BEGIN TRY
	-- memulai transaction
	BEGIN TRANSACTION;
	DECLARE @GuruID INT = 2;
	DECLARE @MapelID INT = 1;
	DECLARE @KelasID INT = 1;
	DECLARE @Hari VARCHAR(20) = 'Selasa';
	DECLARE @JamMulai TIME = '12:00:00';
	DECLARE @JamSelesai TIME = '14:00:00';

	-- langkah 1 : mengecek apakah guru sudah ada jadwal di waktu yang sama
	IF EXISTS (
		SELECT 1 FROM Transactions.Jadwal 
		WHERE GuruID = @GuruID AND Hari = @Hari 
		AND (@JamMulai < JamSelesai AND @JamSelesai > JamMulai)
		)
	BEGIN
		INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
		VALUES ('Transactions.Jadwal', 'ERROR', 'SELECT', 'Guru memiliki jadwal bentrok', SUSER_SNAME());

		THROW 50000, 'Guru sudah memiliki jadwal yang bentrok pada hari dan pukul yang sama', 1;
	END
	
	-- langkah 2 : mendaftarkan guru ke jadwal
	INSERT INTO Transactions.Jadwal 
	(GuruID, MapelID, KelasID, Hari, JamMulai, JamSelesai)
	VALUES (@GuruID, @MapelID, @KelasID, @Hari, @JamMulai, @JamSelesai);

	INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
	VALUES ('Transactions.Jadwal', 'SUCCESS', 'INSERT', 'Guru ID 2 ditambahkan ke jadwal hari Selasa 12:00 - 14:00', SUSER_SNAME());

	-- langkah 3 : commit klo berhasil
	COMMIT;
END TRY
BEGIN CATCH
	-- langkah 4 : klo terjadi kesalahan, rollback dilakukan
	PRINT 'Terjadi kesalahan, melakukan rollback...';
	ROLLBACK;

	-- menampilkan pesan error
	PRINT ERROR_MESSAGE();
END CATCH;

-- Consistency
BEGIN TRY
	-- memulai transaction
	BEGIN TRANSACTION

	-- langkah 1 : Cek apakah user sudah terdaftar sebagai guru
	DECLARE @UserID INT = 2;
	DECLARE @NIP VARCHAR(30) = '202401';

	-- mengecek apakah data user tersedia
	IF NOT EXISTS (SELECT 1 FROM Masters.[User] WHERE UserID = @UserID)
	BEGIN
		INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
		VALUES ('Masters.User', 'ERROR', 'SELECT', 'Akun User ID 2 tidak ditemukan', SUSER_SNAME());

		THROW 50000, 'Data user tidak tersedia', 1;
	END

	DECLARE @Role VARCHAR(10);
	SELECT @Role = Role FROM Masters.[User] WHERE UserID = @UserID;

	-- mengecek apakah user yang didaftarkan memiliki role guru
	IF (@Role = 'Admin')
	BEGIN
		INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
		VALUES ('Masters.User', 'ERROR', 'SELECT', 'User tidak memiliki role Guru', SUSER_SNAME());

		THROW 50000, 'User gagal didaftarkan sebagai guru karena tidak memiliki role Guru', 1;
	END

	-- mengecek apakah user sudah terdaftar sebagai guru
	IF EXISTS (SELECT 1 FROM Masters.Guru WHERE UserID = @UserID)
	BEGIN
		INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
		VALUES ('Masters.Guru', 'ERROR', 'SELECT', 'User sudah terdaftar sebagai Guru', SUSER_SNAME());

		-- jika sudah terdaftar, throw error
		THROW 50000, 'Tidak bisa menambahkan guru karena User sudah terdaftar sebagai Guru', 1;
	END
	
	-- mengecek apakah NIP guru sudah terdaftar
	IF LEN(@NIP) >= 30
	BEGIN
		IF EXISTS (SELECT 1 FROM Masters.Guru WHERE NIP = @NIP)
		BEGIN
			INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
			VALUES ('Masters.Guru', 'ERROR', 'SELECT', 'NIP sudah digunakan oleh guru lain', SUSER_SNAME());

			THROW 50000, 'Tidak bisa menambahkan guru karena NIP sudah digunakan oleh guru lain', 1;
		END
	END

	-- daftarkan user sebagai guru ketika semua kondisi terpenuhi
	INSERT INTO Masters.Guru 
	(UserID, NamaLengkap, NIP)
	VALUES
	(@UserID, 'Ismail Ahmad Kanabawi', '202403');

	INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
	VALUES ('Masters.Guru', 'SUCCESS', 'INSERT', 'Data Guru berhasil ditambahkan', SUSER_SNAME());

	-- commit
	COMMIT;
END TRY
BEGIN CATCH
	-- klo terjadi kesalahan, rollback dilakukan
	PRINT 'Terjadi kesalahan, melakukan rollback...';
	ROLLBACK;

	-- menampilkan pesan error
	PRINT ERROR_MESSAGE();
END CATCH;

-- Isolation
BEGIN TRY
	-- Setting isolation level dan transaksi
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
	BEGIN TRANSACTION;

	IF EXISTS (SELECT 1 FROM Transactions.Absensi WHERE JadwalID = 1 AND Tanggal = CAST(GETDATE() AS DATE))
	BEGIN
		INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
		VALUES ('Transactions.Absensi', 'ERROR', 'SELECT', 'Absensi sudah tercatat hari ini', SUSER_SNAME());

		THROW 50000, 'Tidak dapat melakukan absensi dua kali atau lebih', 1;
	END

	INSERT INTO Transactions.Absensi (JadwalID, Tanggal, Status)
	VALUES (1, GETDATE(), 'Hadir');
	
	INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
	VALUES ('Transactions.Absensi', 'SUCCESS', 'INSERT', 'Absensi berhasil tercatat ke dalam sistem', SUSER_SNAME());

	-- Commit Transaksi
	COMMIT;
END TRY
BEGIN CATCH
	PRINT 'Terjadi kesalahan, melakukan rollback...';
	ROLLBACK;

	PRINT ERROR_MESSAGE();
END CATCH;

-- Durability
BEGIN TRY
	BEGIN TRANSACTION;

	INSERT INTO Masters.[User] (Nama, Email, [Password], [Role])
	VALUES ('Andhika', 'andhika@mail.com', '123StrongPassword', 'Guru');

	INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
	VALUES ('Masters.User', 'SUCCESS', 'INSERT', 'User berhasil ditambahkan ke dalam sistem', SUSER_SNAME());

	COMMIT;
END TRY
BEGIN CATCH
	PRINT 'Terjadi kesalahan, melakukan rollback...';
	ROLLBACK;

	INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
	VALUES ('Masters.User', 'ERROR', 'INSERT', 'User gagal ditambahkan ke dalam sistem', SUSER_SNAME());

	PRINT ERROR_MESSAGE();
END CATCH;

SELECT * FROM Masters.[User];

----- Isolation
-- READ UNCOMMITTED
-- Transaksi A
BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRANSACTION;

    SELECT * FROM Transactions.Absensi WHERE JadwalID = 1;

    WAITFOR DELAY '00:00:10'; -- Simulasi waktu transaksi berjalan

    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'SUCCESS', 'SELECT', 'Transaksi A READ UNCOMMITTED selesai', SUSER_SNAME());

    COMMIT;
END TRY
BEGIN CATCH
    PRINT 'Terjadi kesalahan, melakukan rollback...';
    ROLLBACK;
    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'ERROR', 'SELECT', 'Transaksi A READ UNCOMMITTED gagal', SUSER_SNAME());
    PRINT ERROR_MESSAGE();
END CATCH;

-- Transaksi B
BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    BEGIN TRANSACTION;

    UPDATE Transactions.Absensi SET Status = 'Alfa' WHERE JadwalID = 1 AND Status = 'Hadir';

    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'SUCCESS', 'UPDATE', 'Transaksi B READ UNCOMMITTED selesai', SUSER_SNAME());

    COMMIT;
END TRY
BEGIN CATCH
    PRINT 'Terjadi kesalahan, melakukan rollback...';
    ROLLBACK;
    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'ERROR', 'UPDATE', 'Transaksi B READ UNCOMMITTED gagal', SUSER_SNAME());
    PRINT ERROR_MESSAGE();
END CATCH;

-- READ COMMITTED
-- Transaksi A
BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    SELECT * FROM Transactions.Absensi WHERE JadwalID = 2;

    WAITFOR DELAY '00:00:10';

    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'SUCCESS', 'SELECT', 'Transaksi A READ COMMITTED selesai', SUSER_SNAME());

    COMMIT;
END TRY
BEGIN CATCH
    PRINT 'Terjadi kesalahan, melakukan rollback...';
    ROLLBACK;
    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'ERROR', 'SELECT', 'Transaksi A READ COMMITTED gagal', SUSER_SNAME());
    PRINT ERROR_MESSAGE();
END CATCH;

-- Transaksi B
BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    UPDATE Transactions.Absensi SET Status = 'Izin' WHERE JadwalID = 2 AND Status = 'Hadir';

    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'SUCCESS', 'UPDATE', 'Transaksi B READ COMMITTED selesai', SUSER_SNAME());

    COMMIT;
END TRY
BEGIN CATCH
    PRINT 'Terjadi kesalahan, melakukan rollback...';
    ROLLBACK;
    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'ERROR', 'UPDATE', 'Transaksi B READ COMMITTED gagal', SUSER_SNAME());
    PRINT ERROR_MESSAGE();
END CATCH;

-- REPEATABLE READ
-- Transaksi A
BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    BEGIN TRANSACTION;

    SELECT * FROM Transactions.Absensi WHERE JadwalID = 3;

    WAITFOR DELAY '00:00:10';

    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'SUCCESS', 'SELECT', 'Transaksi A REPEATABLE READ selesai', SUSER_SNAME());

    COMMIT;
END TRY
BEGIN CATCH
    PRINT 'Terjadi kesalahan, melakukan rollback...';
    ROLLBACK;
    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'ERROR', 'SELECT', 'Transaksi A REPEATABLE READ gagal', SUSER_SNAME());
    PRINT ERROR_MESSAGE();
END CATCH;

-- Transaksi B
BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    BEGIN TRANSACTION;

    DELETE FROM Transactions.Absensi WHERE JadwalID = 3 AND Status = 'Hadir';

    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'SUCCESS', 'DELETE', 'Transaksi B REPEATABLE READ selesai', SUSER_SNAME());

    COMMIT;
END TRY
BEGIN CATCH
    PRINT 'Terjadi kesalahan, melakukan rollback...';
    ROLLBACK;
    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'ERROR', 'DELETE', 'Transaksi B REPEATABLE READ gagal', SUSER_SNAME());
    PRINT ERROR_MESSAGE();
END CATCH;

-- SERIALIZABLE
-- Transaksi A
BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    SELECT * FROM Transactions.Absensi WHERE JadwalID = 1 AND Tanggal BETWEEN '2024-03-01' AND '2024-04-30';

    WAITFOR DELAY '00:00:10';

    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'SUCCESS', 'SELECT', 'Transaksi A SERIALIZABLE selesai', SUSER_SNAME());

    COMMIT;
END TRY
BEGIN CATCH
    PRINT 'Terjadi kesalahan, melakukan rollback...';
    ROLLBACK;
    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'ERROR', 'SELECT', 'Transaksi A SERIALIZABLE gagal', SUSER_SNAME());
    PRINT ERROR_MESSAGE();
END CATCH;

-- Transaksi B
BEGIN TRY
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    INSERT INTO Transactions.Absensi (JadwalID, Tanggal, Status)
    VALUES (1, GETDATE(), 'Hadir');

    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'SUCCESS', 'INSERT', 'Transaksi B SERIALIZABLE selesai', SUSER_SNAME());

    COMMIT;
END TRY
BEGIN CATCH
    PRINT 'Terjadi kesalahan, melakukan rollback...';
    ROLLBACK;
    INSERT INTO AuditLogs (TableName, [Status], ActionType, Detail, ChangedBy)
    VALUES ('Transactions.Absensi', 'ERROR', 'INSERT', 'Transaksi B SERIALIZABLE gagal', SUSER_SNAME());
    PRINT ERROR_MESSAGE();
END CATCH;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Monitoring & Optimasi Performa Database
-- Index Guru - Clustered
CREATE CLUSTERED INDEX IDX_Guru_NamaLengkap ON Masters.Guru (NamaLengkap);

SELECT GuruID, NamaLengkap FROM Masters.Guru;

-- Index Mapel - Non-Clustered
CREATE NONCLUSTERED INDEX IDX_Mapel_Nama ON Masters.Mapel (Nama);

SELECT MapelID, Nama FROM Masters.Mapel;

-- Index Jadwal - Composite
CREATE NONCLUSTERED INDEX IDX_Jadwal_Mapel_Kelas_Hari ON Transactions.Jadwal (MapelID, KelasID, Hari);

SELECT JadwalID, MapelID, KelasID, Hari FROM Transactions.Jadwal;

-- Index Absensi - Covering
CREATE NONCLUSTERED INDEX IDX_Absensi_Jadwal_Tanggal ON Transactions.Absensi (JadwalID, Tanggal) INCLUDE ([Status]) ON PS_AbsensiScheme (Tanggal);

SELECT AbsensiID, JadwalID, Tanggal, [Status] FROM Transactions.Absensi
WHERE JadwalID = 1 AND Tanggal BETWEEN '2024-01-01' AND '2024-05-30';

-- Index AuditLogs
CREATE INDEX IDX_AuditLogs_ChangeDate ON AuditLogs(ChangeDate);
CREATE INDEX IDX_AuditLogs_ChangedBy ON AuditLogs(ChangedBy);

SELECT LogID, TableName, [Status], ActionType, ChangedBy, ChangeDate FROM AuditLogs;

-- nampilin semua index yang ada di database RuangGuru
SELECT *
FROM 
	sys.indexes i
	INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE 
	t.is_ms_shipped = 0
ORDER BY 
	t.name, i.name;

-- Tabel yang digunakan: Transactions.Absensi
-- Skenario: Memantau kehadiran Guru
SELECT 
    J.GuruID, G.NamaLengkap,
    COUNT(CASE WHEN A.Status = 'Hadir' THEN 1 ELSE 0 END) AS JumlahHadir,
    COUNT(CASE WHEN A.Status = 'Sakit' THEN 1 ELSE 0 END) AS JumlahSakit,
    COUNT(CASE WHEN A.Status = 'Izin' THEN 1 ELSE 0 END) AS JumlahIzin,
    COUNT(CASE WHEN A.Status = 'Alfa' THEN 1 ELSE 0 END) AS JumlahAlfa
FROM Transactions.Absensi A
JOIN Transactions.Jadwal J ON A.JadwalID = J.JadwalID
JOIN Masters.Guru G ON J.GuruID = G.GuruID
WHERE A.Tanggal BETWEEN '2010-05-01' AND '2024-05-31'
GROUP BY J.GuruID, G.NamaLengkap;

-- Tabel yang digunakan: Transactions.Jadwal
-- Skenario: Memantau penjadwalan guru
SELECT J.JadwalID, G.NamaLengkap, M.Nama AS Mapel, K.Nama AS Kelas, J.Hari, J.JamMulai, J.JamSelesai
FROM Transactions.Jadwal J
JOIN Masters.Guru G ON J.GuruID = G.GuruID
JOIN Masters.Mapel M ON J.MapelID = M.MapelID
JOIN Masters.Kelas K ON J.KelasID = K.KelasID
ORDER BY J.Hari;

-- Tabel yang digunakan: Masters.User
-- Skenario: Memonitor User dengan role Guru
SELECT 
    UserID, Nama, Email, [Role]
FROM Masters.[User]
WHERE [Role] = 'Guru';

-- Tabel yang digunakan: Masters.Mapel
-- Skenario: Memonitor Mapel yang tidak ada pada jadwal
SELECT 
    M.MapelID, M.Nama
FROM Masters.Mapel M
LEFT JOIN Transactions.Jadwal J ON M.MapelID = J.MapelID
WHERE J.JadwalID IS NULL;

-- Query berat berdasar rata-rata waktu eksekusi
SELECT TOP 10
    qs.total_elapsed_time / qs.execution_count AS AvgExecTime,
    qs.execution_count,
    qt.text AS QueryText
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY AvgExecTime DESC;

-- Statistik I/O file database
SELECT
    DB_NAME(database_id) AS DatabaseName,
    file_id,
    io_stall_read_ms,
    io_stall_write_ms,
    num_of_reads,
    num_of_writes
FROM sys.dm_io_virtual_file_stats(NULL, NULL);

-- Aktivitas disk terkait I/O wait stats
SELECT *
FROM sys.dm_os_wait_stats
WHERE wait_type LIKE 'PAGEIOLATCH%';

-- Statistik index pada tabel Mapel
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates
FROM sys.dm_db_index_usage_stats s
JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE OBJECT_NAME(s.object_id) = 'Mapel'
  AND s.database_id = DB_ID()
ORDER BY s.user_seeks DESC;

-- ngeliatin semua data
SELECT * FROM Masters.[User];
SELECT * FROM Masters.Guru;
SELECT * FROM Masters.Mapel;
SELECT * FROM Masters.Kelas;
SELECT * FROM Transactions.Jadwal;
SELECT * FROM Transactions.Absensi;
SELECT * FROM AuditLogs;