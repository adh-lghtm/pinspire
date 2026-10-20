Nama Anggota
1. Rafikhar Luciano - 24051214110
2. Syahrindra Alwi Z. - 24051214123
3. Teuku Rifqi Ar Rafi' - 24051214129
4. Adhipramana S. A. - 24051214135
5. Belva Dzakwan M. R. - 24051214138

1. Panduan Menjalankan Aplikasi Pinspire

Panduan ini menjelaskan langkah-langkah untuk menjalankan aplikasi Pinspire di komputer lokal, mulai dari menyiapkan backend, menjalankan frontend, hingga melakukan pengujian. Sebelum memulai, pastikan seluruh kebutuhan perangkat lunak sudah terpasang.

2. Prasyarat

Beberapa perangkat lunak yang perlu disiapkan:

- Flutter stable dengan Dart versi 3.13 atau lebih baru, serta Google Chrome.
- PHP versi 8.3 atau lebih baru dan Composer.
- MySQL atau MariaDB, misalnya melalui XAMPP.
- Python, jika ingin menjalankan aplikasi dari hasil build web.

3. Menjalankan Frontend

Buka terminal baru, lalu masuk ke folder frontend Flutter.

cd pinspire
flutter pub get
flutter run -d chrome


Flutter akan mengunduh dependensi yang diperlukan dan menjalankan Pinspire melalui Google Chrome.

Secara default, frontend menggunakan alamat API berikut:

http://127.0.0.1:8000/api/v1

Jika alamat backend berbeda, sesuaikan melalui parameter `API_BASE_URL`. Contohnya:

flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1

Pastikan server backend tetap berjalan selama aplikasi digunakan agar permintaan data dari frontend dapat diproses.

4. Akun Demo

Untuk mencoba fitur aplikasi menggunakan akun demo yang disediakan, gunakan informasi berikut.

Email    : demo@pinspire.test
Password : password

Jika akun tersebut tidak dapat digunakan, periksa kembali apakah proses seeding backend berhasil dijalankan.

5. Menjalankan Pengujian

Pengujian dapat dilakukan untuk memeriksa kondisi backend dan memastikan kode frontend tidak memiliki masalah yang terdeteksi oleh alat analisis.

- Pengujian backend

Masuk ke folder `Pinspire-Api`, kemudian jalankan:

php artisan test

- Pemeriksaan frontend

Masuk ke folder `pinspire`, kemudian jalankan:

dart analyze
flutter test

Perintah `dart analyze` digunakan untuk memeriksa masalah pada kode Dart, sedangkan `flutter test` menjalankan pengujian otomatis yang tersedia pada proyek.

6. Penutup

Setelah seluruh tahapan selesai, Pinspire dapat dijalankan melalui browser dengan backend Laravel sebagai penyedia API dan frontend Flutter sebagai antarmuka pengguna. Pastikan konfigurasi database, alamat API, dan dependensi sudah sesuai agar fitur aplikasi dapat berjalan dengan baik.
