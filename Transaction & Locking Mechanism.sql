CREATE DATABASE UniversityDB;
GO

USE UniversityDB;
GO

CREATE TABLE Mahasiswa (
	MahasiswaID CHAR(7) PRIMARY KEY CHECK (MahasiswaID LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	Name VARCHAR(100) NOT NULL,
	TanggalLahir DATE,
	Jurusan VARCHAR(50)
);

CREATE TABLE Dosen (
	DosenID CHAR(7) PRIMARY KEY CHECK (DosenID LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	Name VARCHAR(100) NOT NULL,
	NIDN VARCHAR(10) UNIQUE NOT NULL,
	Departemen VARCHAR(50)
);

CREATE TABLE MataKuliah (
	MataKuliahID CHAR(6) PRIMARY KEY CHECK (MataKuliahID LIKE 'TI-[0-9][0-9][0-9]'),
	NamaMataKuliah VARCHAR(100) NOT NULL,
	SKS INT CHECK (SKS BETWEEN 1 AND 6)
);

CREATE TABLE Enrollments (
	EnrollmentsID INT IDENTITY(1,1) PRIMARY KEY,
	MahasiswaID CHAR(7),
	MataKuliahID CHAR(6),
	Semester CHAR(2),

	FOREIGN KEY (MahasiswaID) REFERENCES Mahasiswa(MahasiswaID) ON DELETE CASCADE,
	FOREIGN KEY (MataKuliahID) REFERENCES MataKuliah(MataKuliahID) ON DELETE CASCADE
);

-- Membuat tabel AuditLogs untuk mencatat perubahan data
CREATE TABLE AuditLogs (
	LogID INT IDENTITY(1,1) PRIMARY KEY,
	TableName VARCHAR(50),
	ActionType VARCHAR(50),
	OldValue VARCHAR(255),
	NewValue VARCHAR(255),
	ChangeDate DATETIME DEFAULT GETDATE(),
	ChangedBy VARCHAR(100)
);


----- Pengaplikasian Transaction & Locking Mechanism
----- Atomicity
BEGIN TRY 
	-- Memulai transaksi
	BEGIN TRANSACTION;

	-- Langkah 1: Mendaftarkan mahasiswa ke mata kuliah
	INSERT INTO Enrollments (MahasiswaID, MataKuliahID, Semester)
	VALUES ('2024001', 'TI-102', '03'); -- mahasiswa '2024001' mendaftar di mata kuliah 'TI-102'

	-- Langkah 2: Mengecek apakah mahasiswa sudah terdaftar untuk mata kuliah yang sama
	IF EXISTS (SELECT 1 FROM Enrollments WHERE MahasiswaID = '2024001' AND MataKuliahID = 'TI-102')
	BEGIN
		-- Jika mahasiswa sudah terdaftar, throw error untuk membatalkan transaksi
		THROW 50000, 'Mahasiswa sudah terdaftar untuk mata kuliah ini.', 1;
	END

	-- Langkah 3: Jika tidak ada kesalahan, commit transaksi
	COMMIT;
END TRY

BEGIN CATCH
	-- Langkah 4: Jika terjadi kesalahan rollback transaksi
	PRINT 'Terjadi kesalahan, melakukan rollback...';
	ROLLBACK;

	-- menampilkan pesan error
	PRINT ERROR_MESSAGE();
END CATCH;
GO

----- Consistency
BEGIN TRY
	-- Memulai transaksi
	BEGIN TRANSACTION;

	-- langkah 1: Cek apakah mahasiswa sudah terdaftar di mata kuliah yang sama pada semester yang sama
	DECLARE @MahasiswaID CHAR(7) = '2024001';
	DECLARE @MataKuliahID CHAR(6) = 'TI-102';
	DECLARE @Semester CHAR(2) = '02';
	DECLARE @TotalSKS INT;

	-- Mengecek apakah mahasiswa sudah terdaftar
	iF EXISTS (SELECT 1 FROM Enrollments WHERE MahasiswaID = @MahasiswaID AND MataKuliahID = @MataKuliahID AND Semester = @Semester)
	BEGIN
		-- Jika sudah terdaftar, log di AuditLogs dan throw error
		INSERT INTO AuditLogs (TableName, ActionType, OldValue, NewValue, ChangedBy)
		VALUES ('Enrollments', 'ERROR', 'N/A', 'Mahasiswa sudah terdaftar', SUSER_SNAME());

		THROW 50000, 'Mahasiswa sudah terdaftar di mata kuliah TI-102 pada semester 02.', 1;
	END

	-- langkah 2: Mengecek total SKS yang sudah diambil mahasiswa pada semester yang sama
	-- Mendapatkan total SKS dari mata kuliah yang sudah diambil oleh mahasiswa
	SELECT @TotalSKS = SUM(SKS)
	FROM MataKuliah
	WHERE MataKuliahID IN (SELECT MataKuliahID FROM Enrollments WHERE MahasiswaID = @MahasiswaID AND Semester = @Semester);

	-- langkah 3: Mengecek apakah jumlah SKS melebihi batas
	DECLARE @NewSKS INT;
	SELECT @NewSKS = SKS FROM MataKuliah WHERE MataKuliahID = @MataKuliahID;

	IF (@TotalSKS + @NewSKS) > 6
	BEGIN
		-- Jika jumlah SKS melebihi 6, log di AuditLogs dan throw error
		INSERT INTO AuditLogs (TableName, ActionType, OldValue, NewValue, ChangedBy)
		VALUES ('Enrollments', 'ERROR', 'N/A', 'Jumlah SKS melebihi batas', SUSER_SNAME());

		THROW 50001, 'Jumlah SKS yang diambil melebihi batas 6 SKS per semester', 1;
	END

	-- langkah 4: Mendaftarkan mahasiswa ke mata kuliah TI-102
	INSERT INTO Enrollments (MahasiswaID, MataKuliahID, Semester)
	VALUES (@MahasiswaID, @MataKuliahID, @Semester);

	-- Log perubahan di tabel Enrollments
	INSERT INTO AuditLogs (TableName, ActionType, OldValue, NewValue, ChangedBy)
	VALUES ('Enrollments', 'INSERT', 'N/A', 'Mahasiswa 2024001 mendaftar di TI-102 semester 02', SUSER_SNAME());

	-- langkah 5: Commit transaksi jika tidak ada kesalahan
	COMMIT;
END TRY

BEGIN CATCH
	-- langkah 6: Jika terjadi kesalahan, rollback transaksi dan log ke AuditLogs
	PRINT 'Terjadi kesalahan, melakukan rollback...';
	ROLLBACK;

	-- Menyimpan log kesalahan di AuditLogs
	INSERT INTO AuditLogs (TableName, ActionType, OldValue, NewValue, ChangedBy)
	VALUES ('Enrollments', 'ERROR', 'N/A', ERROR_MESSAGE(), SUSER_SNAME());

	-- Menampilkan pesan error
	PRINT ERROR_MESSAGE();
END CATCH
GO

----- Isolation
-- Menambahkan mahasiswa
INSERT INTO Mahasiswa (MahasiswaID, Name, TanggalLahir, Jurusan)
VALUES 
('1234567', 'Ali', '2001-01-01', 'Teknik Informatika'),
('2345678', 'Budi', '2000-02-02', 'Sistem Informasi');

-- Menambahkan mata kuliah
INSERT INTO MataKuliah (MataKuliahID, NamaMataKuliah, SKS)
VALUES
('TI-101', 'Pemrograman Dasar', 3),
('TI-102', 'Database', 3);

-- Menambahkan pendaftaran mahasiswa
INSERT INTO Enrollments (MahasiswaID, MataKuliahID, Semester)
VALUES
('1234567', 'TI-101', 'A'),
('2345678', 'TI-102', 'A');


----- READ COMMITTED
BEGIN TRY
	-- mengatur level isolasi ke READ COMMITTED
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	-- memulai transaksi
	BEGIN TRANSACTION;

	-- langkah 1: mengecek apakah mahasiswa sudah terdaftar di mata kuliah yang sama pada semester yang sama
	DECLARE @MahasiswaID CHAR(7) = '2024001';
	DECLARE @MataKuliahID CHAR(6) = 'TI-102';
	DECLARE @Semester CHAR(2) = '02';

	-- mengunci tabel Enrollments untuk transaksi ini agar transaksi lain tidak bisa mengaksesnya sampai transaksi ini selesai
	-- menggunakan UPDLOCK untuk mengunci baris yang dibaca
	SELECT *
	FROM Enrollments WITH (UPDLOCK)
	WHERE MahasiswaID = @MahasiswaID AND MataKuliahID = @MataKuliahID AND Semester = @Semester;

	-- cek apakah mahasiswa sudah terdaftar di mata kuliah tersebut
	IF EXISTS (SELECT 1 FROM Enrollments WHERE MahasiswaID = @MahasiswaID AND MataKuliahID = @MataKuliahID AND Semester = @Semester)
	BEGIN
		-- jika sudah terdaftar, log di AuditLogs dan throw error
		INSERT INTO AuditLogs (TableName, ActionType, OldValue, NewValue, ChangedBy)
		VALUES ('Enrollments', 'ERROR', 'N/A', 'Mahasiswa sudah terdaftar', SUSER_SNAME());

		THROW 50000, 'Mahasiswa sudah terdaftar di mata kuliah TI-102 pada semester 02.', 1;
	END

	-- langkah 2: mendaftarkan mahasiswa ke mata kuliah TI-102
	INSERT INTO Enrollments (MahasiswaID, MataKuliahID, Semester)
	VALUES (@MahasiswaID, @MataKuliahID, @Semester);

	-- log perubahan di tabel AuditLogs
	INSERT INTO AuditLogs (TableName, ActionType, OldValue, NewValue, ChangedBy)
	VALUES ('Enrollments', 'INSERT', 'N/A', 'Mahasiswa 2024001 mendaftar di TI-102 semester 02', SUSER_SNAME());

	-- langkah 3: commit transaksi jika tidak ada kesalahan
	COMMIT;
END TRY

BEGIN CATCH
	-- langkah 4: jika terjadi kesalahan, rollback transaksi dan log ke AuditLogs
	PRINT 'Terjadi kesalahan, melakukan rollback...';
	ROLLBACK;

	-- menyimpan log kesalahan di 
	INSERT INTO AuditLogs (TableName, ActionType, OldValue, NewValue, ChangedBy)
	VALUES ('Enrollments', 'ERROR', 'N/A', ERROR_MESSAGE(), SUSER_SNAME());

	-- menampilkan pesan error
	PRINT ERROR_MESSAGE();
END CATCH
GO

----- READ UNCOMMITTED
BEGIN TRY
	-- mengatur level isolasi ke READ UNCOMMITTED (menyebabkan dirty read)
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	-- Langkah 1: Mengecek apakah mahasiswa sudah terdaftar di mata kuliah yang sama pada semester yang sama
	DECLARE @MahasiswaID CHAR(7) = '2024001';
	DECLARE @MataKuliahID CHAR(6) = 'TI-102';
	DECLARE @Semester CHAR(2) = '02';

	-- Menggunakan READ UNCOMMITTED untuk memungkinkan membaca data yang belum dikomit oleh transaksi lain
	SELECT * FROM Enrollments
	WHERE MahasiswaID = @MahasiswaID AND MataKuliahID = @MataKuliahID AND Semester = @Semester;

	-- Cek apakah mahasiswa sudah terdaftar di mata kuliah tersebut
	IF EXISTS (SELECT 1 FROM Enrollments WHERE MahasiswaID = @MahasiswaID AND MataKuliahID = @MataKuliahID AND Semester = @Semester)
	BEGIN
		-- Jika sudah terdaftar, log di AuditLogs dan throw error
		INSERT INTO AuditLogs (TableName, ActionType, OldValue, NewValue, ChangedBy)
		VALUES ('Enrollments', 'ERROR', 'N/A', 'Mahasiswa sudah terdaftar', SUSER_SNAME());

		THROW 50000, 'Mahasiswa sudah terdaftar di mata kuliah TI-102 pada semester 02.', 1;
	END

	-- Langkah 2: Mendaftarkan mahasiswa ke mata kuliah TI-102
	INSERT INTO Enrollments (MahasiswaID, MataKuliahID, Semester)
	VALUES (@MahasiswaID, @MataKuliahID, @Semester);

	-- Log perubahan di tabel Enrollments
	INSERT INTO AuditLogs (TableName, ActionType, OldValue, NewValue, ChangedBy)
	VALUES ('Enrollments', 'INSERT', 'N/A', 'Mahasiswa 2024001 mendaftar di TI-102 semester 02', SUSER_SNAME());

	-- Langkah 3: Commit transaksi jika tidak ada kesalahan
	COMMIT;
END TRY

BEGIN CATCH
	-- Langkah 4: Jika terjadi kesalahan, rollback transaksi dan log ke AuditLogs
	PRINT 'Terjadi kesalahan, melakukan rollback ... ';
	ROLLBACK;

	-- Menyimpan log kesalahan di AuditLogs
	INSERT INTO AuditLogs (TableName, ActionType, OldValue, NewValue, ChangedBy)
	VALUES ('Enrollments', 'ERROR', 'N/A', ERROR_MESSAGE(), SUSER_SNAME());

	-- Menampilkan pesan error
	PRINT ERROR_MESSAGE();
END CATCH;
GO

-- Transaksi A dimulai
BEGIN TRANSACTION;

	-- Membaca data pendaftaran mahasiswa Ali di mata kuliah TI-101
	SELECT * FROM Enrollments WHERE MahasiswaID = '1234567' AND MataKuliahID = 'TI-101';

-- Transaksi B dimulai
BEGIN TRANSACTION;

	-- Mahasiswa Budi mencoba mendaftar di mata kuliah TI-102 pada semester A
	INSERT INTO Enrollments (MahasiswaID, MataKuliahID, Semester)
	VALUES ('2345678', 'TI-101', 'A');

	-- Mengupdate status pendaftaran mahasiswa Ali
	UPDATE Enrollments SET Semester = 'B'
	WHERE MahasiswaID = '1234567' AND MataKuliahID = 'TI-101';
	-- Transaksi A di-commit
	COMMIT;

	-- Transaksi B melanjutkan dan berhasil memasukkan data setelah transaksi A di-commit
	INSERT INTO Enrollments (MahasiswaID, MataKuliahID, Semester)
	VALUES ('2345678', 'TI-101', 'A');
	COMMIT;

-- Transaksi A dimulai
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

	-- Membaca data pendaftaran mahasiswa Ali di mata kuliah TI-101
	SELECT * FROM Enrollments WHERE MahasiswaID = '1234567' AND MataKuliahID = 'TI-101';


-- Transaksi B dimulai
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

	-- Mahasiswa Budi mencoba mendaftar di mata kuliah TI-101 pada semester A
	INSERT INTO Enrollments (MahasiswaID, MataKuliahID, Semester)
	VALUES ('2345678', 'TI-101', 'A');

	-- Mengupdate status pendaftaran mahasiswa Ali
	UPDATE Enrollments SET Semester = 'B'
	WHERE MahasiswaID = '1234567' AND MataKuliahID = 'TI-101';
	-- Transaksi A di-commit
	COMMIT;

	-- Transaksi B melanjutkan dan berhasil memasukkan data setelah transaksi A di-commit
	INSERT INTO Enrollments (MahasiswaID, MataKuliahID, Semester)
	VALUES ('2345678', 'TI-101', 'A');
	COMMIT;

	ALTER DATABASE UniversityDB
	SET READ_COMMITTED_SNAPSHOT ON;

	ALTER DATABASE UniversityDB
	SET ALLOW_SNAPSHOT_ISOLATION ON;

	-- Transaksi A dimulai dengan SNAPSHOT isolation level
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	BEGIN TRANSACTION;

	-- Membaca data pendaftaran mahasiswa Ali di mata kuliah TI-101
	SELECT * FROM Enrollments WHERE MahasiswaID = '1234567' AND MataKuliahID = 'TI-101';

	-- Transaksi B dimulai
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	BEGIN TRANSACTION;

	-- Mengupdate status pendaftaran mahasiswa Ali
	UPDATE Enrollments SET Semester = 'B'
	WHERE MahasiswaID = '1234567' AND MataKuliahID = 'TI-101';
	-- Transaksi B di-commit
	COMMIT;

	-- Transaksi A memeriksa data setelah Transaksi B selesai
	SELECT * FROM Enrollments WHERE MahasiswaID = '1234567' AND MataKuliahID = 'TI-101';

	-- Hasil: Mahasiswa ali masih terdaftar di Mata Kuliah Pemrograman Dasar (smt A)
	-- Data yang dibaca oleh transaksi A adalah snapshot saat transaksi dimulai, jadi perubahan oleh transaksi B tidak terlihat

	-- Transaksi A di-commit
	COMMIT;

----- PRAKTIKUM MONITORING PERFORMA DATABASE
-- Insert 1000 data ke tabel Mahasiswa secara acak
DECLARE @i INT = 10;
WHILE @i <= 1000
BEGIN
	INSERT INTO Mahasiswa (MahasiswaID, Name, TanggalLahir, Jurusan)
	VALUES (
		RIGHT('0000000' + CAST(@i AS VARCHAR), 7),
		CONCAT('Mahasiswa', @i),
		DATEADD(DAY, @i, '2000-01-01'),
		CASE WHEN @i % 2 = 0 THEN 'Teknologi Informasi' ELSE 'Sistem Informasi' END
	);
	SET @i = @i + 1;
END;
GO

-- mengaktifkan statistik IO dan waktu
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- mencari mahasiswa dengan jurusan 'Teknologi Informasi'
SELECT Name, Jurusan FROM Mahasiswa
WHERE Jurusan = 'Teknologi Informasi';

CREATE INDEX IDX_Nama ON Mahasiswa (Name);
GO

-- mengaktifkan statistik IO dan waktu
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT MahasiswaID, Name FROM Mahasiswa
WHERE Name = 'Luna Maya';

SET SHOWPLAN_TEXT ON;
GO

SELECT Name, TanggalLahir FROM Mahasiswa
WHERE Jurusan = 'Teknologi Informasi';
GO

-- Buat index untuk kolom Jurusan pada tabel Mahasiswa
CREATE NONCLUSTERED INDEX idx_Mahasiswa_Jurusan
ON Mahasiswa(Jurusan);

-- Jalankan query untuk menguji penggunaan index
SELECT * FROM Mahasiswa
WHERE Jurusan = 'Teknologi Informasi';

----- Mempelajari monitoring SQL Server menggunakan DMV dan Profiler
SELECT * FROM Mahasiswa;
SELECT COUNT(*) FROM Dosen;
SELECT NamaMataKuliah FROM MataKuliah;
GO

ALTER DATABASE UniversityDB
SET QUERY_STORE = ON;
GO

GRANT VIEW SERVER STATE TO [sa];
GO

SELECT * FROM Mahasiswa;
SELECT COUNT(*) FROM Dosen;
SELECT NamaMataKuliah FROM MataKuliah;
GO

SELECT * FROM Mahasiswa WHERE Name LIKE 'Mahasiswa%';
GO
SELECT COUNT(*) FROM MataKuliah WHERE SKS >= 3;
GO

-- melihat query yang paling sering dieksekusi
SELECT TOP 5
	execution_count,
	total_logical_reads,
	total_elapsed_time,
	sql_handle
FROM sys.dm_exec_query_stats
ORDER BY execution_count DESC;

-- melihat index yang paling sering digunakan
SELECT 
	object_id,
	index_id,
	user_seeks,
	user_scans,
	user_lookups,
	user_updates
FROM sys.dm_db_index_usage_stats;

-- Tampilkan proses yang sedang berjalan di SQL Server
SELECT 
	session_id, 
	status, 
	start_time, 
	cpu_time, 
	logical_reads, 
	wait_type
FROM sys.dm_exec_requests;

-- Tampilkan penggunaan memori oleh SQL Server
SELECT 
	physical_memory_in_use_kb,
	large_page_allocations_kb,
	locked_page_allocations_kb,
	total_virtual_address_space_kb,
	process_physical_memory_low,
	process_virtual_memory_low
FROM sys.dm_os_process_memory;