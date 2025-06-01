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