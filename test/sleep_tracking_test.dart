import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/models/sleep_record_model.dart';
import 'package:obesight/services/sleep_tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SleepRecord Model Tests', () {
    test('Menghitung durasi tidur normal pada hari yang sama', () {
      final start = DateTime(2026, 10, 5, 13, 0);
      final end = DateTime(2026, 10, 5, 14, 0);
      final record = SleepRecord(
        id: 'rec_1',
        userId: 'user_1',
        date: '2026-10-05',
        startTime: start,
        endTime: end,
      );

      expect(record.durationMinutes, 60);
      expect(record.durationHours, 1);
      expect(record.durationRemainingMinutes, 0);
      expect(record.durationFormatted, '1 jam');
      expect(record.shortDurationFormatted, '1j');
      expect(record.timeRangeFormatted, '13:00 – 14:00');
    });

    test('Menghitung durasi tidur melewati tengah malam (22:30 -> 06:15) = 7 jam 45 menit', () {
      final start = DateTime(2026, 10, 4, 22, 30);
      final end = DateTime(2026, 10, 5, 6, 15);
      final record = SleepRecord(
        id: 'rec_2',
        userId: 'user_1',
        date: '2026-10-05',
        startTime: start,
        endTime: end,
      );

      expect(record.durationMinutes, 465); // 7 * 60 + 45 = 465
      expect(record.durationHours, 7);
      expect(record.durationRemainingMinutes, 45);
      expect(record.durationFormatted, '7 jam 45 menit');
      expect(record.shortDurationFormatted, '7j 45m');
      expect(record.timeRangeFormatted, '22:30 – 06:15');
    });

    test('Durasi tidak pernah negatif saat end < start di tanggal yang sama', () {
      final start = DateTime(2026, 10, 5, 23, 0);
      final end = DateTime(2026, 10, 5, 6, 0); // sama hari tapi jam lebih kecil
      final duration = SleepRecord.calculateDurationMinutes(start, end);

      expect(duration, 7 * 60); // 7 jam
    });

    test('Pembedaan sumber data automatic vs manual', () {
      final autoRec = SleepRecord(
        id: 'auto_1',
        userId: 'user_1',
        date: '2026-10-05',
        startTime: DateTime(2026, 10, 4, 22, 30),
        endTime: DateTime(2026, 10, 5, 6, 15),
        source: 'automatic',
      );
      final manualRec = SleepRecord(
        id: 'manual_1',
        userId: 'user_1',
        date: '2026-10-05',
        startTime: DateTime(2026, 10, 4, 22, 30),
        endTime: DateTime(2026, 10, 5, 6, 15),
        source: 'manual',
      );

      expect(autoRec.isAutomatic, isTrue);
      expect(autoRec.sourceLabel, 'Perkiraan berdasarkan aktivitas HP');
      expect(manualRec.isAutomatic, isFalse);
      expect(manualRec.sourceLabel, 'Dicatat oleh pengguna');
    });
  });

  group('SleepTrackingService Logic Tests', () {
    late SleepTrackingService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = SleepTrackingService.instance;
      await service.clearAll();
    });

    test('1 Tanggal = 1 Data unik: Menimpa rekaman lama jika tanggal sama', () async {
      final testDate = DateTime(2026, 10, 10);
      final dateKey = SleepTrackingService.formatDateKey(testDate);

      // Periode 1: 22:30 - 02:00 (3 jam 30 menit = 210 menit)
      final p1 = SleepRecord(
        id: 'multi_p1',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(2026, 10, 9, 22, 30),
        endTime: DateTime(2026, 10, 10, 2, 0),
        source: 'manual',
      );
      await service.addRecord(p1);

      expect(service.getRecordsForDate(testDate).length, 1);
      expect(service.getTotalSleepMinutesForDate(testDate), 210);

      // Periode 2: Input baru pada tanggal yang sama (misal perbaikan / 7 jam = 420 menit)
      // Harus menimpa rekaman lama p1
      final p2 = SleepRecord(
        id: 'multi_p2',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(2026, 10, 9, 23, 0),
        endTime: DateTime(2026, 10, 10, 6, 0),
        source: 'automatic',
      );
      await service.addRecord(p2);

      final records = service.getRecordsForDate(testDate);
      expect(records.length, 1);
      expect(records.first.id, 'multi_p2');

      final totalMinutes = service.getTotalSleepMinutesForDate(testDate);
      expect(totalMinutes, 420);
      expect(totalMinutes ~/ 60, 7);
      expect(totalMinutes % 60, 0);
    });

    test('Deteksi tumpang tindih (overlap) untuk mencegah data ganda', () async {
      final testDate = DateTime(2026, 10, 12);
      final dateKey = SleepTrackingService.formatDateKey(testDate);

      // Data otomatis tersimpan: 22:30 - 06:00
      final autoRec = SleepRecord(
        id: 'overlap_auto',
        userId: service.currentUserId,
        date: dateKey,
        startTime: DateTime(2026, 10, 11, 22, 30),
        endTime: DateTime(2026, 10, 12, 6, 0),
        source: 'automatic',
      );
      await service.addRecord(autoRec);

      // Data manual yang tumpang tindih: 22:45 - 06:00
      final overlap = service.findOverlappingRecord(
        DateTime(2026, 10, 11, 22, 45),
        DateTime(2026, 10, 12, 6, 0),
        dateKey,
      );

      expect(overlap, isNotNull);
      expect(overlap!.id, 'overlap_auto');

      // Waktu yang tidak tumpang tindih: 13:00 - 14:00 (misal tidur siang)
      final nonOverlap = service.findOverlappingRecord(
        DateTime(2026, 10, 12, 13, 0),
        DateTime(2026, 10, 12, 14, 0),
        dateKey,
      );
      expect(nonOverlap, isNull);
    });

    test('Status pencapaian target tidur', () {
      service.targetSleepMinutes = 480; // 8 jam

      expect(service.getSleepStatus(480), 'Mencapai target');
      expect(service.getSleepStatus(450), 'Mencapai target'); // 7.5 jam
      expect(service.getSleepStatus(420), 'Hampir mencapai target'); // 7 jam
      expect(service.getSleepStatus(300), 'Kurang tidur'); // 5 jam
      expect(service.getSleepStatus(600), 'Tidur berlebih'); // 10 jam
    });

    test('Pengaturan pengingat tidur (1 jam sebelum target tidur)', () {
      service.reminderMinutesBefore = 60;
      service.bedtimeTarget = const TimeOfDay(hour: 22, minute: 30);

      expect(service.reminderTime.hour, 21);
      expect(service.reminderTime.minute, 30);
    });
  });
}
