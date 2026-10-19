# Hasil validasi

Tanggal pemeriksaan: 19 Oktober 2026.

SDK: Flutter 3.47.7 stable, Dart 3.13.5. Pemeriksaan dijalankan pada Linux.

| Pemeriksaan | Hasil |
| --- | --- |
| `flutter analyze --no-pub` | Lulus, tidak ada masalah yang dilaporkan |
| `flutter test --no-pub --reporter expanded` | 13 pengujian lulus |
| `flutter build web --no-pub --release --no-web-resources-cdn` | Build release web berhasil |
| Foto dan font contoh | Disertakan sebagai aset lokal |
| Uji browser Chromium, 390 × 844 dan 1440 × 1000 | Masuk demo, cari, profil, buat pin, muat ulang sesi, dan pemeriksaan visual berhasil |

## Cakupan pengujian

Delapan pengujian state mencakup simpan ke beberapa board tanpa penghitungan ganda, penghapusan pin yang membersihkan referensi terkait, edit pin yang mempertahankan ID, kombinasi pencarian/filter/follow, pemulihan aktivitas setelah aplikasi dibuka ulang, pemisahan data akun, autentikasi contoh, dan reset/hapus akun lokal.

Lima pengujian widget mencakup navigasi dan like pada detail pin, layout home/form pada lebar 320 dan 1440 piksel, pemuatan awal dari URL detail tanpa argumen, dan perpindahan onboarding menuju form masuk. Pengujian layout memakai font Plus Jakarta Sans yang disertakan dalam proyek.

Pengujian browser menjalankan alur dari onboarding ke akun demo, mencari `pantai`, membuka profil, memilih gambar contoh, menerbitkan pin, kemudian memuat ulang aplikasi. Sesi berhasil dipulihkan ke Beranda dan pin baru tetap muncul. Tidak ditemukan exception JavaScript pada alur yang dicoba.

## Batas verifikasi

Build APK dan iOS belum dijalankan. Dialog galeri, izin foto, dan lembar berbagi sistem perlu dicoba kembali pada perangkat Android/iOS yang akan dipakai presentasi. Konfigurasi platform, launcher, serta keterangan akses galeri iOS sudah disertakan.

Pemeriksaan ini memvalidasi front end dan simulasi lokal. Pengujian API, otorisasi server, sinkronisasi pengguna, serta push notification memerlukan implementasi backend terpisah.
