-- SQL FILE buat nambah data Sistem RuangGuru
USE RuangGuru;
INSERT INTO Masters.[User]
VALUES
(1, 'Admin 1', 'admin1@mail.com', '12345678', 'Admin'),
(2, 'Guru 1', 'guru1@mail.com', '12345678', 'Guru'),
(3, 'Guru 2', 'guru2@mail.com', '12345678', 'Guru');

INSERT INTO Masters.Guru
VALUES
(1, 2, 'Budiono Siregar', '202401'),
(2, 3, 'Muhammad Sumbul', '202402');

INSERT INTO Masters.Mapel
VALUES
(1, 'ABD', 'Administrasi Basis Data'),
(2, 'PBD', 'Perencanaan Basis Data');

INSERT INTO Masters.Kelas
VALUES
(1, 'A'),
(2, 'B');

INSERT INTO Transactions.Jadwal
VALUES
(1, 2, 1, 1, 'Senin', '09:00:00', '12:00:00'),
(2, 2, 1, 1, 'Senin', '03:00:00', '15:00:00');

INSERT INTO Transactions.Absensi
VALUES
(1, 1, '2024-03-17', 'Hadir'),
(2, 2, '2024-03-17', 'Hadir'),
(3, 1, '2024-03-24', 'Izin'),
(4, 2, '2024-03-24', 'Alfa');