# Dokumentasi Sistem Basis Data "Ruang Guru"

## 1. Tujuan
Sistem basis data ini dirancang untuk mengelola data administrasi Ruang Guru, meliputi data user, guru, mapel, kelas, jadwal, absensi, serta audit log aktivitas. Sistem juga menerapkan konsep backup, recovery, transaksi (ACID), partisi, serta monitoring performa.

## 2. Struktur Database
- **Skema Masters**: Menyimpan data master (User, Guru, Mapel, Kelas)
- **Skema Transactions**: Menyimpan data transaksi (Jadwal, Absensi)
- **Tabel AuditLogs**: Mencatat aktivitas penting (insert, update, error)

## 3. Fitur Utama & Skenario
- Pembuatan database dengan filegroup dan partisi untuk efisiensi.
- Implementasi backup (full, differential, log) dan recovery.
- Penerapan transaksi dengan mekanisme ACID:
  - **Atomicity**: Penambahan jadwal guru, rollback jika gagal.
  - **Consistency**: Validasi sebelum insert guru baru.
  - **Isolation**: Penggunaan isolation level (SERIALIZABLE, REPEATABLE READ, READ COMMITTED, READ UNCOMMITTED) pada absensi.
  - **Durability**: Data tetap tersimpan walau terjadi kegagalan.
- Monitoring performa: Query berat, statistik I/O, index usage.
- Indexing: Clustered, non-clustered, composite, covering index.

## 4. Penjelasan Skenario Transaksi & Locking
- **Atomicity**  
  Menambahkan jadwal guru, dicek bentrok jadwal, jika gagal rollback.
- **Consistency**  
  Validasi user sebelum menjadi guru, cek role, cek NIP unik.
- **Isolation**  
  Absensi hanya bisa dilakukan sekali per hari per jadwal. Dicontohkan dengan berbagai isolation level untuk menghindari dirty read, phantom read, dsb.
- **Durability**  
  Data user baru tetap tersimpan walau terjadi error setelah commit.

## 5. Skenario Query (Per Tabel)
- **Absensi**: Menampilkan guru dengan jumlah alfa > 3 dalam periode tertentu.
- **Guru**: Menampilkan guru yang belum memiliki jadwal.
- **Mapel**: Menampilkan jumlah guru per mapel.
- **Jadwal**: Menampilkan jadwal di hari Senin sebelum jam 9 pagi.

## 6. Monitoring & Optimasi Performa
- Query berat berdasarkan rata-rata waktu eksekusi.
- Statistik I/O file database.
- Statistik aktivitas disk terkait I/O.
- Statistik penggunaan index pada tabel Mapel.
- Query absensi pada periode tertentu.

## 7. Catatan
- Seluruh transaksi penting dicatat pada tabel AuditLogs.
- Penggunaan partisi pada tabel Absensi untuk efisiensi query.
- Hak akses diatur untuk user Admin dan Guru.
- Backup dan recovery dilakukan secara berkala.
- Index dibuat untuk optimasi query.

---

**Penulis:** [Haidar yahya Mudhofar]  
**Tanggal:** [Ahad, 1 Juni 2025]