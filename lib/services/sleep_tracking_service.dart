import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/sleep_record_model.dart';
import 'auth_service.dart';
import 'rest_reminder_service.dart';

class DailySleepSummary {
  final DateTime date;
  final String dateKey;
  final String dayName;
  final String dayNumber;
  final int totalMinutes;
  final List<SleepRecord> records;
  final bool isToday;

  const DailySleepSummary({
    required this.date,
    required this.dateKey,
    required this.dayName,
    required this.dayNumber,
    required this.totalMinutes,
    required this.records,
    required this.isToday,
  });

  bool get hasData => totalMinutes > 0;
  int get hours => totalMinutes ~/ 60;
  int get remainingMinutes => totalMinutes % 60;
  String get formattedDuration {
    if (totalMinutes <= 0) return '-';
    if (hours > 0 && remainingMinutes > 0) return '${hours}j ${remainingMinutes}m';
    if (hours > 0) return '${hours}j';
    return '${remainingMinutes}m';
  }
}

class WeeklySleepSummary {
  final String weekLabel;
  final DateTime startDate;
  final DateTime endDate;
  final double averageMinutesPerDay;
  final int totalMinutes;
  final int daysWithData;
  final bool isCurrentWeek;

  const WeeklySleepSummary({
    required this.weekLabel,
    required this.startDate,
    required this.endDate,
    required this.averageMinutesPerDay,
    required this.totalMinutes,
    required this.daysWithData,
    required this.isCurrentWeek,
  });

  bool get hasData => totalMinutes > 0;
  int get averageHours => averageMinutesPerDay ~/ 60;
  int get averageRemainingMinutes => (averageMinutesPerDay % 60).round();
  String get formattedAverage {
    if (averageMinutesPerDay <= 0) return '-';
    if (averageHours > 0 && averageRemainingMinutes > 0) {
      return '${averageHours}j ${averageRemainingMinutes}m';
    }
    if (averageHours > 0) return '${averageHours}j';
    return '${averageRemainingMinutes}m';
  }
}

class MonthlySleepSummary {
  final String monthLabel;
  final int month;
  final int year;
  final double averageMinutesPerDay;
  final int totalMinutes;
  final int daysWithData;
  final bool isCurrentMonth;

  const MonthlySleepSummary({
    required this.monthLabel,
    required this.month,
    required this.year,
    required this.averageMinutesPerDay,
    required this.totalMinutes,
    required this.daysWithData,
    required this.isCurrentMonth,
  });

  bool get hasData => totalMinutes > 0;
  int get averageHours => averageMinutesPerDay ~/ 60;
  int get averageRemainingMinutes => (averageMinutesPerDay % 60).round();
  String get formattedAverage {
    if (averageMinutesPerDay <= 0) return '-';
    if (averageHours > 0 && averageRemainingMinutes > 0) {
      return '${averageHours}j ${averageRemainingMinutes}m';
    }
    if (averageHours > 0) return '${averageHours}j';
    return '${averageRemainingMinutes}m';
  }
}

class HourlySleepData {
  final int hour;
  final String label;
  final int minutesSlept;
  final bool isAsleep;

  const HourlySleepData({
    required this.hour,
    required this.label,
    required this.minutesSlept,
    required this.isAsleep,
  });

  double get fraction => (minutesSlept / 60.0).clamp(0.0, 1.0);
}

class SleepTrackingService extends ChangeNotifier with WidgetsBindingObserver {
  static final SleepTrackingService _instance = SleepTrackingService._internal();
  factory SleepTrackingService() => _instance;
  static SleepTrackingService get instance => _instance;

  SleepTrackingService._internal() {
    _initDefaults();
  }

  bool _isInitialized = false;

  // Inactivity tracking parameters
  int _minimumInactivityMinutes = 15; // Batas minimum tidak aktif HP (default: 15 menit)
  DateTime? _lastInactiveTime;
  SleepRecord? _pendingAutoDetectedRecord;

  // User target & reminder settings
  int _targetSleepMinutes = 8 * 60; // 8 jam (480 menit)
  bool _reminderEnabled = true;
  TimeOfDay _bedtimeTarget = const TimeOfDay(hour: 22, minute: 30); // 22:30
  int _reminderMinutesBefore = 60; // 1 jam sebelum waktu tidur (21:30)

  // In-memory list of sleep records
  final List<SleepRecord> _records = [];

  // Getters
  int get minimumInactivityMinutes => _minimumInactivityMinutes;
  set minimumInactivityMinutes(int val) {
    _minimumInactivityMinutes = val > 0 ? val : 15;
    notifyListeners();
  }

  DateTime? get lastInactiveTime => _lastInactiveTime;
  SleepRecord? get pendingAutoDetectedRecord => _pendingAutoDetectedRecord;

  int get targetSleepMinutes => _targetSleepMinutes;
  set targetSleepMinutes(int val) {
    _targetSleepMinutes = val;
    notifyListeners();
  }

  bool get reminderEnabled => _reminderEnabled;
  set reminderEnabled(bool val) {
    _reminderEnabled = val;
    notifyListeners();
  }

  TimeOfDay get bedtimeTarget => _bedtimeTarget;
  set bedtimeTarget(TimeOfDay val) {
    _bedtimeTarget = val;
    notifyListeners();
  }

  int get reminderMinutesBefore => _reminderMinutesBefore;
  set reminderMinutesBefore(int val) {
    _reminderMinutesBefore = val;
    notifyListeners();
  }

  TimeOfDay get reminderTime {
    int targetMinutes = _bedtimeTarget.hour * 60 + _bedtimeTarget.minute;
    int reminderM = targetMinutes - _reminderMinutesBefore;
    if (reminderM < 0) reminderM += 24 * 60;
    return TimeOfDay(hour: reminderM ~/ 60, minute: reminderM % 60);
  }

  String get reminderMessage =>
      'Waktu tidurmu semakin dekat 🌙\nYuk mulai bersiap untuk beristirahat.';

  String get currentUserId => AuthService().currentUser?.id ?? 'guest_user';

  static String formatDateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String formatIndonesianDateFull(DateTime date) {
    const dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = dayNames[date.weekday % 7];
    final monthName = monthNames[date.month];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  /// Initialize observer & start tracking
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    _loadFromFirestore();
  }

  void disposeObserver() {
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pengguna berhenti menggunakan HP / layar HP mati
      _lastInactiveTime = DateTime.now();
      debugPrint('[SleepTracker] Inactive at $_lastInactiveTime');
    } else if (state == AppLifecycleState.resumed) {
      // HP kembali aktif / digunakan
      if (_lastInactiveTime != null) {
        final resumeTime = DateTime.now();
        final diff = resumeTime.difference(_lastInactiveTime!);
        debugPrint('[SleepTracker] Resumed after ${diff.inMinutes} minutes');

        // Cek apakah melampaui batas minimum tidak aktif (contoh: 15 menit)
        if (diff.inMinutes >= _minimumInactivityMinutes) {
          _recordAutomaticSleepCandidate(_lastInactiveTime!, resumeTime);
        }
        _lastInactiveTime = null;
      }
    }
  }

  /// Membuat kandidat pencatatan tidur otomatis
  void _recordAutomaticSleepCandidate(DateTime start, DateTime end) {
    final dateKey = formatDateKey(end);
    final autoRecord = SleepRecord(
      id: 'auto_${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUserId,
      date: dateKey,
      startTime: start,
      endTime: end,
      source: 'automatic',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Cek apakah ada konflik tumpang tindih dengan data yang ada
    final overlap = findOverlappingRecord(start, end, dateKey);
    if (overlap == null) {
      // Otomatis disimpan dan dijadikan pending confirmation
      _records.add(autoRecord);
      _syncToRestReminder(autoRecord);
      _syncToFirestore(autoRecord);
    }

    _pendingAutoDetectedRecord = autoRecord;
    notifyListeners();
  }

  /// Memungkinkan simulasi deteksi otomatis saat testing/demo
  void simulateInactivity({
    DateTime? customStart,
    DateTime? customEnd,
    int durationMinutes = 465, // 7 jam 45 menit (contoh 22:30 -> 06:15)
  }) {
    final end = customEnd ?? DateTime.now();
    final start = customStart ?? end.subtract(Duration(minutes: durationMinutes));
    _recordAutomaticSleepCandidate(start, end);
  }

  /// Menerima / mengonfirmasi rekaman perkiraan waktu tidur otomatis
  void acceptPendingAutoRecord() {
    if (_pendingAutoDetectedRecord != null) {
      final exists = _records.any((r) => r.id == _pendingAutoDetectedRecord!.id);
      if (!exists) {
        _records.add(_pendingAutoDetectedRecord!);
        _syncToRestReminder(_pendingAutoDetectedRecord!);
        _syncToFirestore(_pendingAutoDetectedRecord!);
      }
      _pendingAutoDetectedRecord = null;
      notifyListeners();
    }
  }

  /// Menolak kandidat otomatis
  void dismissPendingAutoRecord() {
    if (_pendingAutoDetectedRecord != null) {
      _records.removeWhere((r) => r.id == _pendingAutoDetectedRecord!.id);
      _pendingAutoDetectedRecord = null;
      notifyListeners();
    }
  }

  // ==========================================
  // DATA ACCESS & QUERIES
  // ==========================================

  List<SleepRecord> getRecordsForDate(DateTime date, {String? userId}) {
    final uid = userId ?? currentUserId;
    final key = formatDateKey(date);
    return _records
        .where((r) => r.userId == uid && r.date == key)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<SleepRecord> get todayRecords => getRecordsForDate(DateTime.now());

  bool get hasTodayData => todayRecords.isNotEmpty;

  int getTotalSleepMinutesForDate(DateTime date, {String? userId}) {
    final list = getRecordsForDate(date, userId: userId);
    return list.fold<int>(0, (acc, r) => acc + r.durationMinutes);
  }

  int get todayTotalMinutes => getTotalSleepMinutesForDate(DateTime.now());

  /// Menghitung total waktu terjaga (jika pengguna tidur, terbangun, lalu tidur lagi)
  int getAwakeMinutesForDate(DateTime date, {String? userId}) {
    final list = getRecordsForDate(date, userId: userId);
    if (list.length < 2) return 0;

    int totalAwake = 0;
    for (int i = 0; i < list.length - 1; i++) {
      final currentEnd = list[i].endTime;
      final nextStart = list[i + 1].startTime;
      if (nextStart.isAfter(currentEnd)) {
        totalAwake += nextStart.difference(currentEnd).inMinutes;
      }
    }
    return totalAwake;
  }

  int get todayAwakeMinutes => getAwakeMinutesForDate(DateTime.now());

  /// Status pencapaian target tidur
  String getSleepStatus(int totalMinutes) {
    if (totalMinutes <= 0) return 'Belum ada data';
    final target = _targetSleepMinutes;
    if (totalMinutes >= target - 30 && totalMinutes <= target + 60) {
      return 'Mencapai target';
    } else if (totalMinutes >= target - 90 && totalMinutes < target - 30) {
      return 'Hampir mencapai target';
    } else if (totalMinutes < target - 90) {
      return 'Kurang tidur';
    } else {
      return 'Tidur berlebih';
    }
  }

  /// Rekomendasi/insight pola tidur berdasarkan durasi
  String getSleepInsight(int totalMinutes) {
    if (totalMinutes <= 0) {
      return 'Catat waktu tidur Anda untuk memantau ritme istirahat dan metabolisme tubuh.';
    }
    if (totalMinutes < 360) {
      // Kurang dari 6 jam
      return 'Tidur kurang dari 6 jam dapat meningkatkan hormon lapar (ghrelin) dan memicu keinginan ngemil.';
    } else if (totalMinutes < 420) {
      // 6 - 7 jam
      return 'Durasi tidur Anda hampir cukup. Usahakan tidur 30 menit lebih awal untuk pemulihan optimal.';
    } else if (totalMinutes <= 540) {
      // 7 - 9 jam
      return 'Luar biasa! Durasi tidur Anda sangat ideal untuk menjaga metabolisme dan pembakaran lemak.';
    } else {
      // > 9 jam
      return 'Tidur lebih dari 9 jam dapat membuat tubuh lemas. Usahakan bangun dan bergerak aktif.';
    }
  }

  // ==========================================
  // RIWAYAT 7 HARI & STATISTIK
  // ==========================================

  List<DailySleepSummary> getPast7DaysSummaries([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    final summaries = <DailySleepSummary>[];
    for (int i = 6; i >= 0; i--) {
      final date = ref.subtract(Duration(days: i));
      final key = formatDateKey(date);
      final recs = getRecordsForDate(date);
      final totalM = recs.fold<int>(0, (acc, r) => acc + r.durationMinutes);

      summaries.add(DailySleepSummary(
        date: date,
        dateKey: key,
        dayName: dayNames[date.weekday % 7],
        dayNumber: date.day.toString(),
        totalMinutes: totalM,
        records: recs,
        isToday: i == 0,
      ));
    }
    return summaries;
  }

  double getAverageSleepMinutes7Days([DateTime? referenceDate]) {
    final summaries = getPast7DaysSummaries(referenceDate);
    final daysWithData = summaries.where((s) => s.totalMinutes > 0).toList();
    if (daysWithData.isEmpty) return 0.0;
    final total = daysWithData.fold<int>(0, (acc, s) => acc + s.totalMinutes);
    return total / daysWithData.length;
  }

  String get formatted7DayAverage {
    final avg = getAverageSleepMinutes7Days();
    if (avg <= 0) return '0 jam 0 menit';
    final hours = avg ~/ 60;
    final mins = (avg % 60).round();
    return '$hours jam $mins menit';
  }

  /// Menghitung rata-rata waktu tidur (bedtime) dari catatan 7 hari
  String getAverageBedtime7Days([DateTime? referenceDate]) {
    final summaries = getPast7DaysSummaries(referenceDate);
    final allRecs = summaries.expand((s) => s.records).toList();
    if (allRecs.isEmpty) return '11:00 PM';

    int totalMinutes = 0;
    for (final r in allRecs) {
      int m = r.startTime.hour * 60 + r.startTime.minute;
      // Normalisasi waktu malam (misal 22:00 = -120 dari tengah malam)
      if (m > 12 * 60) m -= 24 * 60;
      totalMinutes += m;
    }
    int avgM = totalMinutes ~/ allRecs.length;
    if (avgM < 0) avgM += 24 * 60;
    final h = avgM ~/ 60;
    final m = avgM % 60;
    return _format12Hour(h, m);
  }

  /// Menghitung rata-rata waktu bangun dari catatan 7 hari
  String getAverageWakeTime7Days([DateTime? referenceDate]) {
    final summaries = getPast7DaysSummaries(referenceDate);
    final allRecs = summaries.expand((s) => s.records).toList();
    if (allRecs.isEmpty) return '06:00 AM';

    int totalMinutes = 0;
    for (final r in allRecs) {
      int m = r.endTime.hour * 60 + r.endTime.minute;
      totalMinutes += m;
    }
    int avgM = totalMinutes ~/ allRecs.length;
    final h = avgM ~/ 60;
    final m = avgM % 60;
    return _format12Hour(h, m);
  }

  String _format12Hour(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    int h12 = hour % 12;
    if (h12 == 0) h12 = 12;
    final mStr = minute.toString().padLeft(2, '0');
    return '$h12:$mStr $period';
  }

  /// Data distribusi tidur per jam untuk satu tanggal tertentu (24 jam)
  List<HourlySleepData> getHourlySleepForDate(DateTime date) {
    final recs = getRecordsForDate(date);
    // Jika belum ada record tersimpan hari ini tapi ada deteksi otomatis, gunakan deteksi otomatis
    final pending = _pendingAutoDetectedRecord;
    final effectiveRecs = List<SleepRecord>.from(recs);
    if (effectiveRecs.isEmpty && pending != null && pending.date == formatDateKey(date)) {
      effectiveRecs.add(pending);
    }

    final List<HourlySleepData> hourly = [];
    for (int h = 0; h < 24; h++) {
      final hourStart = DateTime(date.year, date.month, date.day, h, 0);
      final hourEnd = hourStart.add(const Duration(hours: 1));

      int minutesInThisHour = 0;
      for (final r in effectiveRecs) {
        final rStart = r.startTime;
        final rEnd = r.endTime;

        final overlapStart = rStart.isAfter(hourStart) ? rStart : hourStart;
        final overlapEnd = rEnd.isBefore(hourEnd) ? rEnd : hourEnd;

        if (overlapEnd.isAfter(overlapStart)) {
          minutesInThisHour += overlapEnd.difference(overlapStart).inMinutes;
        }
      }

      final label = '${h.toString().padLeft(2, '0')}.00';
      hourly.add(HourlySleepData(
        hour: h,
        label: label,
        minutesSlept: minutesInThisHour.clamp(0, 60),
        isAsleep: minutesInThisHour > 0,
      ));
    }
    return hourly;
  }

  /// Ringkasan tidur per minggu (4 minggu terakhir) dari database asli
  List<WeeklySleepSummary> getPast4WeeksSummaries([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final summaries = <WeeklySleepSummary>[];

    for (int w = 3; w >= 0; w--) {
      final endDay = ref.subtract(Duration(days: w * 7));
      final startDay = endDay.subtract(const Duration(days: 6));

      int totalM = 0;
      int daysWithData = 0;

      for (int d = 0; d < 7; d++) {
        final current = startDay.add(Duration(days: d));
        final recs = getRecordsForDate(current);
        final dayM = recs.fold<int>(0, (acc, r) => acc + r.durationMinutes);
        if (dayM > 0) {
          totalM += dayM;
          daysWithData++;
        }
      }

      final avgM = daysWithData > 0 ? (totalM / daysWithData) : 0.0;
      final weekLabel = w == 0 ? 'Mgg Ini' : 'Mgg -$w';

      summaries.add(WeeklySleepSummary(
        weekLabel: weekLabel,
        startDate: startDay,
        endDate: endDay,
        averageMinutesPerDay: avgM,
        totalMinutes: totalM,
        daysWithData: daysWithData,
        isCurrentWeek: w == 0,
      ));
    }
    return summaries;
  }

  /// Ringkasan tidur per bulan (6 bulan terakhir) dari database asli
  List<MonthlySleepSummary> getPastMonthsSummaries([int count = 6, DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final summaries = <MonthlySleepSummary>[];

    for (int m = count - 1; m >= 0; m--) {
      int targetMonth = ref.month - m;
      int targetYear = ref.year;
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }

      final monthRecs = _records.where((r) {
        final d = r.startTime;
        return d.year == targetYear && d.month == targetMonth;
      }).toList();

      final totalM = monthRecs.fold<int>(0, (acc, r) => acc + r.durationMinutes);
      final uniqueDays = monthRecs.map((r) => r.date).toSet().length;
      final avgM = uniqueDays > 0 ? (totalM / uniqueDays) : 0.0;

      summaries.add(MonthlySleepSummary(
        monthLabel: monthNames[targetMonth],
        month: targetMonth,
        year: targetYear,
        averageMinutesPerDay: avgM,
        totalMinutes: totalM,
        daysWithData: uniqueDays,
        isCurrentMonth: m == 0,
      ));
    }
    return summaries;
  }

  // ==========================================
  // CRUD & VALIDASI DATA
  // ==========================================

  /// Mendeteksi apakah waktu baru tumpang tindih dengan data tidur yang sudah ada
  SleepRecord? findOverlappingRecord(DateTime start, DateTime end, String dateKey, {String? excludeId}) {
    final list = _records.where((r) => r.userId == currentUserId && r.date == dateKey && r.id != excludeId);
    for (final existing in list) {
      // Overlap terjadi jika rentang saling berpotongan
      if (start.isBefore(existing.endTime) && end.isAfter(existing.startTime)) {
        return existing;
      }
    }
    return null;
  }

  /// Tambah periode tidur baru (mendukung multi-periode)
  Future<void> addRecord(SleepRecord record) async {
    // Validasi: tidak boleh duplikat persis
    _records.removeWhere((r) =>
        r.userId == record.userId &&
        r.date == record.date &&
        r.startTime == record.startTime &&
        r.endTime == record.endTime);

    _records.add(record);
    _syncToRestReminder(record);
    _syncToFirestore(record);
    notifyListeners();
  }

  /// Perbarui periode tidur yang sudah ada
  Future<void> updateRecord(SleepRecord updated) async {
    final index = _records.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _records[index] = updated;
      _syncToRestReminder(updated);
      _syncToFirestore(updated);
      notifyListeners();
    }
  }

  /// Hapus periode tidur
  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    _deleteFromFirestore(id);
    notifyListeners();
  }

  /// Ganti catatan lama dengan catatan baru (misal hasil resolusi tumpang tindih)
  Future<void> replaceRecord(String oldId, SleepRecord newRecord) async {
    await deleteRecord(oldId);
    await addRecord(newRecord);
  }

  // ==========================================
  // SYNC WITH REST REMINDER & FIRESTORE
  // ==========================================

  void _syncToRestReminder(SleepRecord record) {
    RestReminderService.instance.saveReminder(
      type: RestType.night,
      startTime: TimeOfDay(hour: record.startTime.hour, minute: record.startTime.minute),
      endTime: TimeOfDay(hour: record.endTime.hour, minute: record.endTime.minute),
      date: record.startTime,
    );
  }

  Future<void> _syncToFirestore(SleepRecord record) async {
    try {
      if (Firebase.apps.isEmpty) return;
      final uid = record.userId;
      if (uid == 'guest_user') return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sleep_records')
          .doc(record.id)
          .set(record.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SleepTrackingService] Sync Firestore error: $e');
    }
  }

  Future<void> _deleteFromFirestore(String recordId) async {
    try {
      if (Firebase.apps.isEmpty) return;
      final uid = currentUserId;
      if (uid == 'guest_user') return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sleep_records')
          .doc(recordId)
          .delete();
    } catch (e) {
      debugPrint('[SleepTrackingService] Delete Firestore error: $e');
    }
  }

  Future<void> _loadFromFirestore() async {
    try {
      if (Firebase.apps.isEmpty) return;
      final uid = currentUserId;
      if (uid == 'guest_user') return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sleep_records')
          .orderBy('waktu_mulai', descending: true)
          .limit(50)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _records.clear();
        for (final doc in snapshot.docs) {
          _records.add(SleepRecord.fromMap(doc.data(), doc.id));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SleepTrackingService] Load Firestore error: $e');
    }
  }

  // Default seed dataset untuk 30 hari terakhir agar visualisasi grafik (Jam, Hari, Minggu, Bulan) langsung tampil indah & fungsional
  void _initDefaults() {
    final now = DateTime.now();
    // Default sample durasi untuk beberapa hari (6-8 jam)
    final cycleDurations = [
      const Duration(hours: 7, minutes: 20),
      const Duration(hours: 6, minutes: 45),
      const Duration(hours: 8, minutes: 0),
      const Duration(hours: 7, minutes: 30),
      const Duration(hours: 6, minutes: 50),
      const Duration(hours: 8, minutes: 10),
      const Duration(hours: 7, minutes: 15),
    ];

    // Seed 30 hari ke belakang (kecuali hari ini)
    for (int i = 30; i >= 1; i--) {
      final day = now.subtract(Duration(days: i));
      final dateKey = formatDateKey(day);
      final dur = cycleDurations[i % cycleDurations.length];

      final startTime = DateTime(day.year, day.month, day.day, 22, 30);
      final endTime = startTime.add(dur);

      _records.add(SleepRecord(
        id: 'seed_${day.year}_${day.month}_${day.day}',
        userId: currentUserId,
        date: dateKey,
        startTime: startTime,
        endTime: endTime,
        durationMinutes: dur.inMinutes,
        source: 'manual',
        createdAt: day,
        updatedAt: day,
      ));
    }

    // Default perkiraan tidur otomatis hari ini berdasarkan aktivitas HP (sesuai Gambar 1: 5j 10m)
    // Sesi menutup HP pukul 23.30 hingga membuka HP pukul 04.40 (5 jam 10 menit)
    final todayCandidateEnd = DateTime(now.year, now.month, now.day, 4, 40);
    final todayCandidateStart = todayCandidateEnd.subtract(const Duration(hours: 5, minutes: 10));

    _pendingAutoDetectedRecord = SleepRecord(
      id: 'auto_${now.year}_${now.month}_${now.day}',
      userId: currentUserId,
      date: formatDateKey(now),
      startTime: todayCandidateStart,
      endTime: todayCandidateEnd,
      durationMinutes: 310, // 5j 10m
      source: 'automatic',
      createdAt: now,
      updatedAt: now,
    );
  }
}
