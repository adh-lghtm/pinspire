# Integrasi Pinspire dengan Backend

Dokumen ini menjelaskan keadaan integrasi **saat ini**. Aplikasi Flutter
`pinspire` sudah memakai API Laravel `Pinspire-Api` untuk seluruh data dan aksi.
Tidak ada lagi fallback ke data demo lokal: bila API gagal, UI menampilkan
status loading, pesan error, dan tombol coba lagi.

- Backend: Laravel 13 + Sanctum + MySQL (`Pinspire-Api`)
- Klien: Flutter Web (Chrome), tanpa dependency HTTP baru
- Token: disimpan di SharedPreferences (pilihan pemilik proyek)
- Base URL: `http://127.0.0.1:8000/api/v1` (dapat diubah lewat `--dart-define`)

---

## 1. Menjalankan Proyek

### Backend

```powershell
cd Pinspire-Api
composer install
copy .env.example .env
php artisan key:generate

# Sesuaikan DB_* di .env (contoh: MySQL XAMPP di 127.0.0.1:3306, database pinspire)
php artisan migrate:fresh --seed
php artisan storage:link
php artisan serve --host=127.0.0.1 --port=8000
```

Pastikan `APP_URL=http://127.0.0.1:8000` di `.env` agar `image_url` dan
`avatar_url` mengarah ke server yang benar. File publik disajikan melalui
`GET /media/{path}` (bukan symlink `/storage`) supaya header CORS ikut terkirim.

### Flutter

```powershell
cd pinspire
flutter pub get

# Chrome, memakai URL default
flutter run -d chrome

# Chrome, URL kustom
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1

# Build web
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Build statis dapat diuji dengan server lokal, misalnya:

```powershell
cd build/web
python -m http.server 8080 --bind 127.0.0.1
```

Akun demo: `demo@pinspire.test` / `password`.

---

## 2. Struktur Klien

| Berkas | Tanggung jawab |
| --- | --- |
| `lib/services/api_client.dart` | Envelope `{success, message, data, meta}`, header Bearer, parsing error validasi, timeout 35 detik, callback 401, `multipartUpdate()` |
| `lib/services/api_transport.dart` | Kontrak `ApiTransport`, `ApiRequest`, `ApiResponse`, `ApiFile`, `ApiTransportException` |
| `lib/services/api_transport_web.dart` | XHR + `FormData` + `Blob` lewat `dart:js_interop` untuk Web |
| `lib/services/api_transport_io.dart` | `HttpClient` + multipart manual untuk Android/iOS/desktop |
| `lib/services/auth_service.dart` | Login, register, `me`, logout, simpan/hapus token |
| `lib/services/local_store.dart` | `LocalStore` berbasis SharedPreferences dan `MemoryStore` untuk tes |
| `lib/services/media_service.dart` | Memilih gambar dan membaca byte (tanpa dependency baru) |
| `lib/models/models.dart` | Mapping JSON API ke `Pin`, `Creator`, `Board`, `UserProfile`, `PinComment`, `ChatMessage`, `Conversation`, `AppNotice` |
| `lib/state/app_state.dart` | Sumber data seluruh layar, loading/error, mutasi optimistis + rollback, sesi dan preferensi |

`api_transport.dart` memakai conditional import:

```dart
export 'api_transport_io.dart'
    if (dart.library.js_interop) 'api_transport_web.dart';
```

Dengan begitu Web memakai XHR/FormData, sedangkan platform native memakai
`HttpClient`. Tidak ada `package:http` atau dependency baru.

---

## 3. Token dan Sesi

- Token disimpan di SharedPreferences dengan key `pinspire.api_token.v1`.
- Password tidak pernah disimpan.
- Saat aplikasi dibuka, `AppState.initialize()` memulihkan token, memanggil
  `GET /auth/me`, lalu `refreshAll()`.
- Respons `401` memicu `ApiClient.onUnauthorized`: token dihapus dan pengguna
  dikembalikan ke layar masuk.
- Preferensi lokal memakai key `pinspire.prefs.v1`; penanda onboarding memakai
  `pinspire.session.v2`.

> SharedPreferences tidak terenkripsi. Ini keputusan eksplisit pemilik proyek;
> untuk produksi, pertimbangkan penyimpanan aman platform.

---

## 4. Endpoint yang Dipakai

| Fitur | Method & path | Catatan |
| --- | --- | --- |
| Login / register | `POST /auth/login`, `POST /auth/register` | Menyimpan `access_token` |
| Sesi | `GET /auth/me`, `POST /auth/logout` | Logout mencabut token aktif |
| Feed | `GET /pins?per_page=50` | Token opsional untuk `is_saved`/`is_liked` |
| Detail pin | `GET /pins/{id}` | Dimuat saat layar detail dibuka bila belum ada di cache |
| Buat pin | `POST /pins` | Multipart (`image`) atau `image_url` + metadata |
| Edit pin | `POST /pins/{id}` + `_method=PUT` | Multipart; PHP hanya mem-parsing multipart pada POST |
| Hapus pin | `DELETE /pins/{id}` | Hanya pemilik |
| Cari | `GET /search?q=` | Mencari judul, deskripsi, kategori, vibe, tags |
| Board | `GET/POST /boards`, `PUT/DELETE /boards/{id}` | `pin_ids` menandai isi board |
| Pin di board | `GET /boards/{id}/pins` | Dipakai saat membuka detail board |
| Simpan | `POST /pins/{id}/save` body `{board_id}` | Idempoten |
| Hapus simpanan | `DELETE /pins/{id}/save` body `{board_id}` | Body tetap dikirim pada DELETE |
| Daftar simpanan | `GET /saves` | Mengisi `savedPins` |
| Suka | `POST/DELETE /pins/{id}/like` | Optimistis, rollback bila gagal |
| Daftar suka | `GET /likes` | Mengisi `likedPins` |
| Komentar | `GET/POST /pins/{id}/comments`, `DELETE /comments/{id}` | Hapus hanya oleh penulis |
| Profil | `GET /users/{username}`, `GET /users/{username}/pins` | Profil kreator |
| Profil sendiri | `GET/PUT /profile` | Termasuk `email` |
| Avatar | `POST/DELETE /profile/avatar` | Multipart `avatar`, maks. 2 MB |
| Hapus akun | `DELETE /profile` | Token ikut dicabut |
| Pengaturan | `GET/PUT /settings`, `PUT /settings/password` | Ganti password mencabut token lain |
| Follow | `POST/DELETE /users/{username}/follow`, `GET /following` | Optimistis, rollback bila gagal |
| Notifikasi | `GET /notifications`, `POST /notifications/{id}/read`, `POST /notifications/read-all`, `DELETE /notifications/{id}` | `meta.unread_count` |
| Percakapan | `GET /conversations`, `GET /conversations/{username}` | Daftar tanpa paginasi |
| Kirim pesan | `POST /conversations/{username}/messages` | Body `{body}` |
| Tandai dibaca | `POST /conversations/{username}/read` | |

Kontrak lengkap, contoh request/response, dan aturan validasi ada di
`Pinspire-Api/API_DOCUMENTATION.md`.

---

## 5. Kontrak Data Penting

### Envelope

```json
{ "success": true, "message": "...", "data": {}, "meta": {} }
```

`ApiClient` mengembalikan `ApiResult`; `result.items` untuk list dan
`result.object` untuk objek. Error non-2xx dilempar sebagai `ApiException`
berisi `message`, `statusCode`, dan `errors` validasi.

### Pin

Field API dipetakan ke model Flutter:

| API | Model | Keterangan |
| --- | --- | --- |
| `image_url` | `image` | URL `/media/...` atau URL eksternal |
| `category`, `vibe`, `tags`, `palette` | field sama | Menjaga tampilan filter dan palet |
| `likes_count`, `saves_count`, `comments_count` | `likes`, `saves`, `comments` | Angka dari server |
| `is_liked`, `is_saved` | `liked`, `saved` | Bergantung token viewer |
| `user` | `Creator` | `authorId`, `authorName`, `authorAvatar` |

`image_width`/`image_height` dipakai menghitung `aspectRatio`. Bila kosong,
rasio fallback digunakan.

### Board

`pin_ids` hanya dikirim saat relasi `pins` di-*eager load*. Klien memakai field
ini untuk menghitung isi board dan menandai pin yang sudah disimpan. Respons
`POST /pins/{id}/save` juga mengembalikan board dengan `pin_ids` dan
`pins_count` terbaru; klien tetap menggabungkan `pin_id` secara defensif bila
field tersebut tidak ada.

### Komentar

Payload komentar memakai `user.id` numerik dan `text`; model `PinComment`
menyimpan `authorId` sebagai string serta `authorName`/`authorAvatar` untuk UI.
`mine` dihitung dari kecocokan ID profil.

### Notifikasi

`target_type` bernilai `pin` atau `user`; `target_id` numerik. UI membuka detail
pin atau profil kreator berdasarkan pasangan tersebut.

### Media

Semua URL media memakai `http://<host>/media/...`. Route ini publik, mendukung
CORS, dan tidak memerlukan token. Jangan memakai `/storage/...` langsung karena
header CORS tidak dijamin.

---

## 6. State, Loading, Error, dan Retry

- `AppState.initialize()` memulihkan sesi, lalu `refreshAll()` memuat feed,
  board, simpanan, suka, pin buatan sendiri, following, pengguna, notifikasi,
  dan percakapan secara paralel dengan `_guard`.
- `loading` dan `error` dipakai layar untuk spinner, pesan gagal, dan tombol
  coba lagi. Tidak ada data demo yang menggantikan hasil API.
- Detail pin, komentar, board, dan pin kreator dimuat sesuai kebutuhan
  (`loadPin`, `loadComments`, `loadBoard`, `loadCreatorPins`).
- Like, follow, simpan, komentar, dan pesan memperbarui UI lebih dulu, lalu
  memanggil API. Bila gagal, perubahan lokal dikembalikan dan `error` diisi.
- `flush()` menunggu antrean penulisan preferensi selesai.

---

## 7. Pengujian

### Backend

```powershell
cd Pinspire-Api
php artisan test
```

Hasil terakhir: **56 tes lulus** (220 assertion), termasuk auth, pin, board,
save, like, komentar, follow, notifikasi, pesan, pencarian tag, media, dan
pengaturan.

### Flutter

```powershell
cd pinspire
dart analyze
flutter test
flutter build web
```

Hasil terakhir:

- `dart analyze`: tidak ada issue.
- `flutter test`: **16 tes lulus**.
- `flutter build web`: berhasil.

Tes Flutter memakai `test/fake_api.dart`, yaitu `ApiTransport` in-memory yang
meniru envelope dan endpoint API. Tidak ada lagi data demo lokal di jalur tes.
`flutter analyze` di Windows saat ini terblokir pesan "Building with plugins
requires symlink support" (Developer Mode belum aktif); `dart analyze` dipakai
sebagai pengganti dan memberi hasil bersih.

### Verifikasi end-to-end

Alur berikut sudah dijalankan di Chrome dengan Selenium:

1. Onboarding → login demo → feed termuat dari API.
2. Detail pin, like/unlike, tambah/hapus komentar.
3. Pencarian dan filter.
4. Profil, inbox/daftar percakapan, notifikasi.
5. Simpan pin dari feed ke board, buka kembali sheet, pastikan jumlah board
   bertambah, muat ulang halaman, lalu batalkan simpanan dan pastikan kembali
   ke keadaan semula (diverifikasi juga lewat API).

---

## 8. Troubleshooting

| Gejala | Penyebab umum | Solusi |
| --- | --- | --- |
| "Tidak dapat terhubung ke server" | Backend belum berjalan / URL salah | Jalankan `php artisan serve`; cek `API_BASE_URL` |
| Gambar tidak muncul, error CORS | `APP_URL` salah atau memakai `/storage` | Set `APP_URL`, akses lewat `/media/...` |
| 401 setelah beberapa saat | Token dicabut / ganti password / hapus akun | Login ulang; token lama otomatis dibersihkan |
| 429 saat login | Rate limit 6 percobaan/menit | Tunggu satu menit |
| Simpan berhasil tetapi jumlah board salah | Respons board tanpa `pin_ids` | Pastikan backend meng-*eager load* `pins` (sudah diperbaiki) |
| Edit pin multipart gagal | PHP tidak mem-parsing multipart pada PUT | Gunakan `POST` + `_method=PUT` (sudah diterapkan) |
| Mixed content di Web | Halaman HTTPS memanggil API HTTP | Sajikan keduanya lewat HTTP lokal atau HTTPS |

---

## 9. Catatan Data Demo

Seeder menyediakan 5 user (demo + 4 kreator), 12 board, 40 pin, 30 like,
18 komentar, 10 follow, 4 pesan, dan 3 notifikasi. Data sementara dari smoke
test dan E2E sudah dibersihkan sehingga akun demo kembali ke keadaan seeder.
