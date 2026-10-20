# Panduan integrasi kelompok

Proyek ini berdiri sendiri. Tidak ada kontrak API milik kelompok yang diasumsikan atau ditimpa. Tabel berikut menjelaskan kontrak internal aplikasi yang sudah dipakai halaman.

## State dan pembagian tanggung jawab

| Bagian | Lokasi | Tanggung jawab |
| --- | --- | --- |
| Tampilan dan navigasi | `lib/screens/`, `lib/widgets/` | Komposisi UI, input, validasi form, pemanggilan state |
| State bersama | `lib/state/app_state.dart` | Sumber data semua halaman: pin, board, profil, follow, komentar, pesan, preferensi |
| Penyimpanan | `lib/services/local_store.dart` | Antarmuka `LocalStore`; implementasi PreferencesStore dan MemoryStore |
| Autentikasi contoh | `lib/services/auth_service.dart` | Akun demo serta satu registrasi lokal tambahan |
| Gambar | `lib/services/media_service.dart` | Memilih gambar, membaca byte, dan pemulihan hasil pemilih foto Android |
| Data awal | `lib/data/demo_data.dart` | Ganti pemuatan data ini dengan repository backend |

UI mendengarkan `AppState` melalui `AppScope.of(context)`; event menggunakan `AppScope.read(context)`. Pemanggilan mutasi memperbarui semua layar yang bergantung pada state. Penulisan lokal diantrikan agar perubahan lama tidak menimpa perubahan baru. `flush()` menunggu antrean selesai. UI menampilkan `storageError` jika penulisan gagal.

## Route internal yang sudah terdaftar

Semua argumen berikut bertipe `String`, bukan objek JSON. Tidak ada route atau format respons eksternal yang telah disepakati dengan kelompok.

| Nama route | Argumen | Fungsi |
| --- | --- | --- |
| `/pin` | ID pin | Detail pin |
| `/image` | Sumber gambar | Viewer gambar |
| `/create` | ID board, opsional | Form buat pin; memilih board awal bila ada |
| `/edit-pin` | ID pin buatan sendiri | Form edit |
| `/search` | Teks awal, opsional | Pencarian mandiri |
| `/boards` | Tidak ada | Semua board |
| `/board` | ID board | Detail board |
| `/profile` | Tidak ada | Profil sendiri |
| `/creator` | ID kreator; `me` untuk diri sendiri | Profil kreator |
| `/edit-profile` | Tidak ada | Edit profil |
| `/notifications` | Tidak ada | Kabar |
| `/chat` | ID kreator | Percakapan lokal |
| `/settings` | Tidak ada | Pengaturan |
| `/about` | Tidak ada | Tentang dan sumber aset |

Beranda, Jelajah, Pesan, dan Profil berada dalam `ShellScreen` menggunakan `IndexedStack` agar state layar tetap dipertahankan ketika berpindah tab. Route dibuka dengan `Navigator.pushNamed`.

## Contoh model pin

```json
{
  "id": "p01",
  "title": "Sudut tenang, ide baru",
  "description": "Referensi ruangan yang ingin disimpan.",
  "image": "https://server-kelompok.example/images/p01.jpg",
  "authorId": "user_123",
  "category": "Interior",
  "vibe": "Calm",
  "tags": ["minimalis", "ruang"],
  "palette": [4292520375, 4287467631, 4282533436],
  "aspectRatio": 0.74,
  "likes": 1240,
  "sourceUrl": "https://example.com/ide",
  "createdAt": "2026-10-19T01:00:00.000Z"
}
```

`palette` berisi integer ARGB 32 bit (`0xAARRGGBB`); contoh di atas hanya ilustrasi format. `image` pada versi lokal menerima path aset, URL HTTP(S), atau data URI. Pada backend, gunakan URL media hasil unggah. `authorId` lokal `me` perlu dipetakan ke ID pengguna server. Jangan menebak pemetaan JSON backend sebelum kelompok menetapkannya.

Model lainnya tersedia di `lib/models/models.dart`:

- `Board`: `id`, `title`, `description`, `createdAt`, `secret`, `pinIds`.
- `UserProfile`: `name`, `username`, `email`, `bio`, `avatar`.
- `PinComment`: `id`, `pinId`, `author`, `text`, `createdAt`.
- `ChatMessage`: `id`, `text`, `mine`, `createdAt`; ID percakapan berada di key map state.

## Langkah mengganti simulasi dengan backend

1. Sepakati autentikasi, ID pengguna, bentuk respons, pagination, dan penamaan field bersama anggota backend.
2. Tambahkan repository API; jangan meletakkan request HTTP langsung di widget.
3. Ganti login/registrasi `AuthService` dengan autentikasi backend. Hash lokal pada versi demo bukan sistem login produksi. Gunakan penyimpanan token yang sesuai platform; jangan memakai SharedPreferences untuk menyimpan password atau token sensitif.
4. Muat daftar pin/board/kreator melalui repository dan tambah state loading, error, pagination, serta retry untuk request jaringan.
5. Ganti mutasi pada `AppState` dengan pemanggilan API. Tentukan apakah UI memperbarui secara optimistis, serta cara mengembalikan state ketika request gagal.
6. Ganti data URI galeri dengan unggahan media ke server, lalu simpan URL hasil unggah.
7. Terapkan pemilik pin/board, pembatasan board rahasia, izin komentar, dan validasi di server. Penanda rahasia lokal belum memberi otorisasi server.
8. Ganti percakapan dan kabar contoh dengan layanan pesan/notifikasi nyata. Jangan menampilkan status terkirim atau dibaca sebelum ada konfirmasi server.
9. Ulangi pengujian alur: masuk → cari → simpan → buat board → unggah → profil → keluar/masuk.

## Warna

Semua warna UI utama berada di `lib/core/theme.dart`.

| Token | Hex |
| --- | --- |
| Background | `#101114` |
| Surface | `#1A1C21` |
| Elevated | `#25282F` |
| Border | `#32353D` |
| Text | `#F5F1EB` |
| Muted | `#9A9EA9` |
| Coral | `#FF806B` |
| Sage | `#B6CDA0` |
| Lavender | `#C3B2E7` |

Untuk mengganti branding, ubah `Brand` di `widgets/common.dart`, ikon pada `assets/branding`, serta launcher platform. Nama aplikasi sudah menjadi Pinspire di Android, iOS, dan web.
