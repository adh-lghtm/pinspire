# Pinspire

Aplikasi Flutter bertema gelap untuk tugas Mobile Development. Pinspire mengikuti pola penemuan inspirasi visual: feed masonry, pencarian, detail pin, simpan ke board, dan profil. Identitas visual memakai coral, charcoal, sage, dan lavender.

## Mulai dari sini

1. Ekstrak ZIP, lalu buka **folder `pinspire`** melalui VS Code atau Android Studio. Folder ini berisi `pubspec.yaml`.
2. Pastikan Flutter dan plugin Flutter/Dart sudah terpasang. Jalankan `flutter doctor` untuk memeriksa emulator atau perangkat.
3. Buka terminal pada folder `pinspire`, lalu jalankan:

```bash
flutter pub get
flutter run
```

Jika ingin mencoba melalui browser:

```bash
flutter run -d chrome
```

Pada penggunaan pertama, pilih minat, lalu tekan **Jelajahi dengan akun demo**. Tidak perlu mendaftarkan akun.

| Akun demo | Nilai |
| --- | --- |
| Email | `demo@pinspire.app` |
| Kata sandi | `Pinspire123!` |

Form pendaftaran dapat membuat satu akun lokal tambahan pada perangkat. Gunakan data percobaan. Akun demo dan akun tambahan memiliki aktivitas terpisah. Data akun demo adalah data contoh, bukan akun Pinterest.

## Halaman dan fungsi

| Halaman | Yang dapat dilakukan |
| --- | --- |
| Onboarding | Memilih kategori minat untuk urutan awal feed |
| Masuk dan daftar | Memakai akun demo atau profil lokal; validasi email, kata sandi, dan konfirmasi |
| Beranda | Feed masonry, filter kategori dan Vibe, tab Mengikuti, urutan relevan/populer/terbaru, tarik untuk mengganti susunan kurasi |
| Jelajah | Pencarian langsung pada judul, deskripsi, tag, kategori, dan nama kreator; riwayat; pencarian board milik sendiri dan kreator contoh |
| Detail pin | Like, simpan ke beberapa board, komentar lokal, mengikuti kreator, perbesar foto, salin palet, buka sumber, bagikan teks pin |
| Buat pin | Memilih foto galeri, gambar contoh offline, atau URL; judul, deskripsi, kategori, Vibe, palet, tag, sumber, dan board |
| Edit dan hapus pin | Mengelola pin buatan sendiri; penghapusan juga membersihkan referensi pin dari board, like, dan komentar |
| Board | Membuat, mencari, mengganti nama/deskripsi, menandai rahasia, menghapus, menambah atau mengeluarkan pin |
| Profil | Mengedit nama, username, bio, foto; melihat board, pin tersimpan, pin buatan sendiri, like, dan kreator yang diikuti |
| Profil kreator | Melihat koleksi kreator, mengikuti atau membatalkan ikuti, membuka percakapan contoh |
| Pesan | Membaca percakapan contoh dan menyimpan pesan lokal; tidak ada pesan yang dikirim ke orang sungguhan |
| Kabar | Membuka notifikasi contoh dan menandainya sudah dibaca |
| Pengaturan | Latar hitam pekat, jeda kabar, minat, pulihkan pin tersembunyi, hapus riwayat, reset aktivitas, keluar, hapus akun lokal |

## Pembeda Pinspire

- **Vibe** mengelompokkan ide menjadi Calm, Warm, Bold, dan Fresh.
- **Palet kurasi** menampilkan warna pada pin dan menggabungkan warna dari pin di sebuah board. Warna dipilih dari metadata; fitur ini tidak menjalankan analisis gambar atau AI.
- **The Slow Edit** membuka kurasi Interior + Calm dari beranda.
- Tema gelap memiliki aksen coral dan kartu dengan sudut membulat, berbeda dari identitas Pinterest.
- Dua kolom pada ponsel; kolom bertambah dan navigasi berpindah ke sisi kiri pada layar lebar.

## Struktur kode

```text
lib/
  main.dart                  Titik masuk dan registrasi route
  core/                      Tema, warna, validasi, utilitas
  models/                    Pin, Board, Creator, UserProfile, komentar, pesan
  data/                      24 pin, 4 kreator, kategori, Vibe, sumber foto
  services/                  Penyimpanan lokal, autentikasi contoh, pemilih gambar
  state/                     AppState + AppScope untuk data lintas halaman
  widgets/                   Masonry, kartu pin/board, modal simpan, komponen umum
  screens/
    auth/                    Onboarding dan akun lokal
    home/                    Beranda
    search/                  Jelajah
    pins/                    Detail, viewer, buat/edit pin
    boards/                  Daftar dan detail board
    profile/                 Profil sendiri, profil kreator, edit profil
    inbox/                   Pesan, percakapan, kabar
    settings/                Pengaturan dan tentang aplikasi
assets/
  images/                    Foto contoh yang disertakan agar dapat offline
  fonts/                     Plus Jakarta Sans dan lisensinya
  branding/                  Sumber ikon Pinspire
android/ ios/ web/            Konfigurasi platform dan launcher
test/                        Pengujian state dan widget
```

## Batas versi front end

Seluruh interaksi inti di atas bekerja dengan state dan penyimpanan lokal. **Belum ada backend atau sinkronisasi antarpengguna.** Like, komentar, follow, pesan, jumlah interaksi, dan kabar adalah simulasi lokal. Tidak ada push notification, layanan email pemulihan, rekomendasi ML, belanja, unggahan video, atau pencarian visual dari foto.

Board rahasia adalah penanda lokal dan tidak disertakan ketika ringkasan profil disalin. Penanda ini belum menjadi kontrol akses server. Tombol salin profil menghasilkan teks, bukan tautan profil publik. Berbagi pin menghasilkan judul, deskripsi, dan sumber foto jika ada, bukan deep link aplikasi.

Foto dari galeri dibatasi 400 KB setelah optimasi pemilih gambar. Total teks media unggahan pada pin dibatasi sekitar 1,8 juta karakter agar penyimpanan contoh tidak cepat penuh. Gunakan gambar contoh atau URL untuk mencoba banyak pin. Jika penyimpanan gagal, aplikasi menampilkan pemberitahuan. Menutup atau membatalkan form pin yang berubah memerlukan konfirmasi dan membuang perubahan yang belum disimpan.

Memuat ulang versi web mengembalikan tampilan ke Beranda. Data tetap ada setelah aplikasi ditutup, tetapi akan hilang jika aplikasi dihapus atau data browser dibersihkan. Aset contoh tidak memerlukan internet setelah aplikasi terpasang; foto URL dan tautan sumber membutuhkan internet. Galeri, lembar berbagi, dan pembukaan tautan bergantung pada kemampuan serta izin perangkat/browser.

## Platform

Kode disiapkan untuk Android, iOS, dan web. Minimum deklarasi: Flutter 3.47 dan Dart 3.13; gunakan Flutter stable yang sesuai `pubspec.lock` agar versi dependensi konsisten. Versi SDK yang dipakai untuk pemeriksaan dicatat dalam `VALIDASI.md`.

- Android: konfigurasi Kotlin/Gradle dari template SDK pembuat proyek, Java 17, `minSdk` sekurangnya 24. Periksa versi Java/Android SDK dengan `flutter doctor -v`.
- iOS: target proyek 15.0, memerlukan macOS dan Xcode untuk menjalankan/build. Keterangan akses galeri sudah ditambahkan ke `Info.plist`.
- Web: dapat dijalankan melalui Chrome. URL gambar eksternal memerlukan server gambar yang mendukung pemuatan lintas origin.

Jangan memindahkan `local.properties`, folder `build`, atau `.dart_tool` antarkomputer. Folder itu dibuat oleh Flutter pada komputer masing-masing.

## Untuk kerja kelompok

Lihat **`INTEGRASI_BACKEND.md`** untuk model, route, dan titik penggantian data lokal. Lihat **`PANDUAN_DEMO.md`** untuk urutan demonstrasi. Jika menggabungkan dengan proyek Flutter kelompok yang sudah ada, gabungkan dependensi, aset, tema, state, dan route secara bertahap; jangan menimpa keseluruhan `main.dart` kelompok tanpa memeriksa struktur mereka.

## Sumber

- Flutter: https://docs.flutter.dev/
- Plugin resmi dan dokumentasi: https://pub.dev/packages/shared_preferences , https://pub.dev/packages/image_picker , https://pub.dev/packages/url_launcher
- Share Plus: https://pub.dev/packages/share_plus
- Foto: Unsplash, daftar URL asli ada di `assets/image_sources.json`; lisensi: https://unsplash.com/license
- Plus Jakarta Sans: https://github.com/google/fonts/tree/main/ofl/plusjakartasans ; lisensi ada di `assets/fonts/OFL.txt`.

Nama kreator, caption, serta angka like dalam dataset dibuat sebagai data contoh. Ikon Pinspire merupakan aset geometris proyek ini.
