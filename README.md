# Pelaporan Fasilitas Kota

Tugas akhir praktikum Modul 9 (Penyimpanan Lokal Flutter) – Smart City.
Aplikasi untuk membuat laporan fasilitas publik (lampu jalan mati, trotoar rusak,
tempat sampah penuh). **Hive** menyimpan laporan, **SharedPreferences** menyimpan
filter status.

## Menjalankan

```bash
flutter create pelaporan_fasilitas_kota        # membuat android/, ios/, web/, dll.
cd pelaporan_fasilitas_kota
# salin lib/, test/, pubspec.yaml, README.md dari proyek ini (timpa), lalu:
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # opsional, lihat catatan adapter
flutter analyze
flutter test
flutter run
```

Hapus `test/widget_test.dart` bawaan Flutter jika ada, karena merujuk ke `MyApp`.

Catatan adapter: `lib/models/laporan_fasilitas.g.dart` sudah disertakan (format sama
dengan keluaran hive_generator). Menjalankan `build_runner` akan menimpanya dengan
hasil generator resmi, dan itu aman.

## Struktur folder

```
lib/
  main.dart                      inisialisasi Hive + SharedPreferences, 3 tab
  models/
    laporan_fasilitas.dart       model + anotasi Hive (typeId 0)
    laporan_fasilitas.g.dart     adapter Hive
    status_laporan.dart          konstanta status dan filter
  helpers/
    hive_helper.dart             buka Box laporanFasilitasBox
    laporan_repository.dart      CRUD + validasi
    pengaturan_helper.dart       filter_status_laporan (SharedPreferences)
  pages/
    halaman_daftar.dart          Read, Update status, Delete (konfirmasi)
    halaman_tambah.dart          Create + validasi
    halaman_filter.dart          pilih/reset filter status
test/
  laporan_test.dart              pengujian CRUD, validasi, persistensi, filter
```

## Penggunaan key

| Penyimpanan | Key / identitas | Nilai |
|---|---|---|
| Hive Box `laporanFasilitasBox` | kode laporan, huruf besar (`SC01`) | objek `LaporanFasilitas` |
| Hive adapter | `typeId: 0` | tipe `LaporanFasilitas` |
| Hive field | `@HiveField(0..3)` | kode, jenis, lokasi, status |
| SharedPreferences | `filter_status_laporan` | `Semua` / `Baru` / `Diproses` / `Selesai` |

Kode dibersihkan dengan `trim()` dan dijadikan huruf besar sebelum dipakai sebagai key,
sehingga `sc01` dan `SC01` dianggap duplikat.

## Ketentuan tugas dan implementasinya

| Aspek | Implementasi |
|---|---|
| Model | `LaporanFasilitas`: kode, jenis, lokasi, status (String) |
| Hive | Box `laporanFasilitasBox`, kode sebagai key, adapter terdaftar di `bukaBoxLaporan()` |
| Tambah | Menolak kode duplikat serta kode/jenis/lokasi kosong (validator form + pemeriksaan ulang di repositori) |
| Baca | `ValueListenableBuilder` pada `box.listenable()`, UI ikut berubah saat Box berubah |
| Ubah | Status Baru / Diproses / Selesai, ditulis ulang dengan `put` pada kode yang sama |
| Hapus | Dialog konfirmasi sebelum `delete` |
| Preferensi | Filter disimpan dengan `SharedPreferences` (key `filter_status_laporan`) |
| Persistensi | Laporan dan filter dimuat ulang saat aplikasi dibuka |

## Skenario pengujian manual (Hasil diisi setelah dijalankan)

| No | Langkah | Hasil yang diharapkan | Hasil |
|---|---|---|---|
| 1 | Tambah SC01 (lampu jalan mati, Jl. Melati) | Tersimpan, status Baru | |
| 2 | Tambah SC02 (trotoar rusak, Jl. Kenanga) | Tersimpan, status Baru | |
| 3 | Tambah SC01 lagi | Ditolak: kode sudah dipakai | |
| 4 | Tambah dengan lokasi kosong | Ditolak: lokasi tidak boleh kosong | |
| 5 | Ubah status SC01 menjadi Selesai | SC01 berstatus Selesai, tetap dua entri | |
| 6 | Pilih filter Baru | Hanya SC02 tampil | |
| 7 | Tutup aplikasi sepenuhnya, buka kembali | Filter Baru tetap aktif, hanya SC02 tampil | |
| 8 | Reset filter ke Semua | SC01 dan SC02 tampil | |
| 9 | Hapus SC02 (konfirmasi) | Dialog muncul; setelah Hapus, SC02 hilang | |

Hot reload tidak cukup sebagai uji persistensi. Tutup proses aplikasi sepenuhnya, lalu
buka lagi tanpa uninstall atau clear data.

## Tangkapan layar

Letakkan di folder `screenshots/`: halaman Daftar, halaman Tambah, dan halaman Filter.
