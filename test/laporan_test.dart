import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pelaporan_fasilitas_kota/helpers/laporan_repository.dart';
import 'package:pelaporan_fasilitas_kota/helpers/pengaturan_helper.dart';
import 'package:pelaporan_fasilitas_kota/models/laporan_fasilitas.dart';
import 'package:pelaporan_fasilitas_kota/models/status_laporan.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Hive: CRUD laporan', () {
    late Directory dir;
    late Box<LaporanFasilitas> box;
    late LaporanRepository repo;

    setUpAll(() {
      dir = Directory.systemTemp.createTempSync('uji_laporan_');
      Hive.init(dir.path);
      Hive.registerAdapter(LaporanFasilitasAdapter());
    });

    setUp(() async {
      box = await Hive.openBox<LaporanFasilitas>('laporanFasilitasBox');
      await box.clear();
      repo = LaporanRepository(box);
    });

    tearDown(() async {
      await box.close();
    });

    tearDownAll(() async {
      await Hive.close();
      dir.deleteSync(recursive: true);
    });

    test('tambah SC01 dan SC02 berhasil, status awal Baru', () async {
      expect(
        await repo.tambah(
          kode: 'SC01',
          jenis: 'Lampu jalan mati',
          lokasi: 'Jl. Melati',
        ),
        isNull,
      );
      expect(
        await repo.tambah(
          kode: 'SC02',
          jenis: 'Trotoar rusak',
          lokasi: 'Jl. Kenanga',
        ),
        isNull,
      );
      expect(box.length, 2);
      expect(repo.ambil('SC01')!.status, statusBaru);
    });

    test('kode duplikat ditolak', () async {
      await repo.tambah(kode: 'SC01', jenis: 'Lampu', lokasi: 'Jl. Melati');
      final galat = await repo.tambah(
        kode: 'sc01',
        jenis: 'Lain',
        lokasi: 'Jl. Lain',
      );
      expect(galat, isNotNull);
      expect(box.length, 1);
      expect(repo.ambil('SC01')!.jenis, 'Lampu');
    });

    test('kode, jenis, dan lokasi kosong ditolak', () async {
      expect(
        await repo.tambah(kode: '  ', jenis: 'Lampu', lokasi: 'Jl. Melati'),
        isNotNull,
      );
      expect(
        await repo.tambah(kode: 'SC01', jenis: '', lokasi: 'Jl. Melati'),
        isNotNull,
      );
      expect(
        await repo.tambah(kode: 'SC01', jenis: 'Lampu', lokasi: '   '),
        isNotNull,
      );
      expect(box.isEmpty, isTrue);
    });

    test('ubah status lewat kode sama tidak menambah entri', () async {
      await repo.tambah(kode: 'SC01', jenis: 'Lampu', lokasi: 'Jl. Melati');
      expect(await repo.ubahStatus('SC01', statusSelesai), isTrue);
      expect(box.length, 1);
      expect(repo.ambil('SC01')!.status, statusSelesai);
      expect(await repo.ubahStatus('SC01', 'Ngawur'), isFalse);
      expect(await repo.ubahStatus('SC99', statusBaru), isFalse);
    });

    test('filter Baru hanya menampilkan SC02 setelah SC01 Selesai', () async {
      await repo.tambah(kode: 'SC01', jenis: 'Lampu', lokasi: 'Jl. Melati');
      await repo.tambah(kode: 'SC02', jenis: 'Trotoar', lokasi: 'Jl. Kenanga');
      await repo.ubahStatus('SC01', statusSelesai);

      final baru = repo.daftar(filter: statusBaru);
      expect(baru.map((l) => l.kode), ['SC02']);
      expect(repo.daftar().length, 2);
    });

    test('hapus menghapus satu laporan saja', () async {
      await repo.tambah(kode: 'SC01', jenis: 'Lampu', lokasi: 'Jl. Melati');
      await repo.tambah(kode: 'SC02', jenis: 'Trotoar', lokasi: 'Jl. Kenanga');
      await repo.hapus('SC02');
      expect(box.length, 1);
      expect(repo.ambil('SC02'), isNull);
    });

    test('data tetap ada setelah Box ditutup dan dibuka lagi', () async {
      await repo.tambah(kode: 'SC01', jenis: 'Lampu', lokasi: 'Jl. Melati');
      await box.close();

      box = await Hive.openBox<LaporanFasilitas>('laporanFasilitasBox');
      repo = LaporanRepository(box);
      expect(repo.ambil('SC01')!.lokasi, 'Jl. Melati');
    });
  });

  group('SharedPreferences: filter status', () {
    // Urutan penting: pengujian pertama menentukan nilai awal tiruan.
    test('nilai tersimpan yang tidak dikenal kembali ke Semua', () async {
      SharedPreferences.setMockInitialValues({
        'filter_status_laporan': 'Ngawur',
      });
      await PengaturanHelper.init();
      expect(PengaturanHelper.muatFilter(), filterSemua);
      expect(PengaturanHelper.filterStatus.value, filterSemua);
    });

    test('simpan filter Baru lalu muat kembali', () async {
      await PengaturanHelper.simpanFilter(statusBaru);
      expect(PengaturanHelper.muatFilter(), statusBaru);
      expect(PengaturanHelper.filterStatus.value, statusBaru);
    });

    test('reset filter kembali ke Semua', () async {
      await PengaturanHelper.simpanFilter(statusSelesai);
      await PengaturanHelper.resetFilter();
      expect(PengaturanHelper.muatFilter(), filterSemua);
      expect(PengaturanHelper.filterStatus.value, filterSemua);
    });
  });
}
