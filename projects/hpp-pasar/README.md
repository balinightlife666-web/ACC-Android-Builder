# HPP Pasar

Android APK untuk pencatatan belanja bahan dan laporan HPP harian.

## MVP v0.1

- Hitung berat otomatis dari `nominal belanja / harga per kg`.
- Tampilkan hasil dalam kg dan gram.
- Simpan item ke laporan harian.
- Catat harga/kg, nominal beli, berat, sumber harga, dan waktu.
- Total otomatis seluruh belanja.
- Bagikan laporan sebagai teks ke WhatsApp/email/aplikasi lain.
- Simpan laporan secara lokal/offline menggunakan SharedPreferences.
- Tombol `Cek Harga Hari Ini`.
  - Tanpa konfigurasi API: membuka Google Search dengan query harga 1 kg + lokasi.
  - Dengan Google Programmable Search API key + Search Engine ID: aplikasi mencoba mengambil kandidat harga dari hasil web, memilih median kandidat, lalu menandainya sebagai estimasi web yang harus diperiksa sebelum masuk laporan.

## Default lokasi

`Bali` — dapat diubah dari Pengaturan Harga Online.

## Android

- Application ID: `com.ardac.hpppasar`
- Min SDK: 26
- Target/Compile SDK: 35
- Version: 0.1.0

## Prinsip data harga

Harga online selalu dicatat bersama sumber dan tanggal. Harga web tidak dianggap harga pasar resmi tanpa verifikasi karena hasil pencarian dapat mencampur ukuran kemasan, toko, promo, dan wilayah yang berbeda.
