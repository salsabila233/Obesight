import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/physical_activity_service.dart';
import '../../services/screening_history_service.dart';
import '../../widgets/progress_page_scaffold.dart';
import '../skrining/skrining_landing_screen.dart';
import '../skrining/skrining_models.dart';
import '../skrining/skrining_recommendation_rules.dart';
import 'activity_detail_screen.dart';

class PhysicalActivityScreen extends StatefulWidget {
  final SkriningData? skriningData;
  final UserModel? user;

  const PhysicalActivityScreen({
    super.key,
    this.skriningData,
    this.user,
  });

  @override
  State<PhysicalActivityScreen> createState() => _PhysicalActivityScreenState();
}

class _PhysicalActivityScreenState extends State<PhysicalActivityScreen> {
  late final ScrollController _dateScrollController;
  late DateTime _selectedDate;
  late String _userKey;
  bool _hasInitialScrolled = false;

  UserModel get _effectiveUser =>
      widget.user ?? AuthService().currentUser ?? AuthService.defaultUserAccount;

  void _scrollToToday(int todayIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollController.hasClients) {
        final scrollPosition = (todayIndex * 68.0) - 120.0;
        _dateScrollController.animateTo(
          scrollPosition.clamp(0.0, _dateScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _dateScrollController = ScrollController();

    final user = _effectiveUser;
    _userKey = ScreeningHistoryService.instance.resolveUserKey(user.id, user.email);

    // Muat riwayat tersimpan spesifik untuk akun pengguna saat ini
    ScreeningHistoryService.instance.loadHistory(_userKey);

    // Pastikan dokumen utama pengguna tersedia di Cloud Firestore
    PhysicalActivityService.instance.ensureUserMainDoc(candidateName: user.name);

    // Muat data dan dengarkan pembaruan real-time dari Cloud Firestore (Requirement 9)
    PhysicalActivityService.instance.listenToFirestoreSessions(PhysicalActivityService.instance.todayKey);
  }

  @override
  void dispose() {
    PhysicalActivityService.instance.stopListeningToSessions();
    _dateScrollController.dispose();
    super.dispose();
  }

  void _openDetail(Map<String, dynamic> act, String dateKey) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(
          activity: act,
          dateKey: dateKey,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final cat = category.trim().toLowerCase();
    if (cat.contains('underweight') || cat.contains('insufficient') || cat.contains('kurang')) {
      return const Color(0xFF2563EB); // Biru (Underweight)
    } else if (cat.contains('normal')) {
      return const Color(0xFF16A34A); // Hijau (Normal)
    } else if (cat.contains('overweight') || cat.contains('lebih')) {
      return const Color(0xFFD97706); // Amber (Overweight)
    } else if (cat.contains('iii') || cat.contains('morbid') || cat.contains('3')) {
      return const Color(0xFF991B1B); // Merah Gelap (Obesitas III)
    } else if (cat.contains('ii') || cat.contains('2')) {
      return const Color(0xFFDC2626); // Merah (Obesitas II)
    } else if (cat.contains('obesitas') ||
        cat.contains('obesity') ||
        cat.contains('type_i') ||
        cat.contains('level_i') ||
        cat.contains('1')) {
      return const Color(0xFFEA580C); // Oranye (Obesitas I)
    }
    return const Color(0xFFD97706);
  }

  String _getCategoryActivityFocusSubtitle(String categoryKey) {
    final cat = categoryKey.trim().toLowerCase();
    if (cat.contains('underweight') || cat.contains('insufficient') || cat.contains('kurang')) {
      return 'Disesuaikan untuk stimulasi pembentukan massa otot & minim kardio berlebih';
    } else if (cat.contains('iii') || cat.contains('morbid') || cat.contains('3')) {
      return 'Disesuaikan tanpa beban gravitasi sendi (hydrotherapy, recumbent & duduk)';
    } else if (cat.contains('ii') || cat.contains('2')) {
      return 'Disesuaikan proteksi sendi maksimal (terapi air, reclined & latihan kursi)';
    } else if (cat.contains('obesitas') || cat.contains('obesity') || cat.contains('1')) {
      return 'Disesuaikan untuk latihan rendah beban sendi (aquarobics & sepeda statis)';
    } else if (cat.contains('overweight') || cat.contains('lebih')) {
      return 'Disesuaikan untuk pembakaran kalori ramah sendi (brisk walk & low-impact)';
    }
    return 'Disesuaikan untuk kebugaran kardiorespirasi & ketahanan fisik optimal';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return AnimatedBuilder(
      animation: Listenable.merge([
        PhysicalActivityService.instance,
        ScreeningHistoryService.instance,
      ]),
      builder: (context, _) {
        // 1. Dapatkan hasil skrining pengguna yang sedang login
        final history = ScreeningHistoryService.instance.getHistory(_userKey);
        final latestScreeningItem = history.isNotEmpty ? history.first : null;
        SkriningData? activeSkrining = widget.skriningData ?? latestScreeningItem?.skriningData;

        final bool hasScreening = activeSkrining != null;
        final String categoryKey = hasScreening
            ? activeSkrining.classificationCategory
            : 'Normal';
        final CategoryRecommendation rec =
            SkriningRecommendationRules.getRecommendationByCategory(categoryKey);

        // Kategori tampilan yang selaras dengan halaman hasil skrining ("Insufficient Weight", dsb.)
        final String displayCategory = hasScreening
            ? (categoryKey.toLowerCase().contains('underweight') ||
                    categoryKey.toLowerCase().contains('insufficient') ||
                    activeSkrining.classificationCategory.toLowerCase().contains('underweight') ||
                    activeSkrining.categoryTitle.toLowerCase().contains('insufficient') ||
                    rec.categoryDisplayName.toLowerCase().contains('underweight')
                ? 'Insufficient Weight'
                : rec.categoryDisplayName)
            : 'Normal';

        final List<Map<String, dynamic>> activities = hasScreening
            ? PhysicalActivityService.instance.getActivitiesForCategory(
                categoryKey,
                skriningData: activeSkrining,
              )
            : const [];

        // Sumber tanggal skrining terbaru (dinormalisasi tahun-bulan-hari)
        final DateTime? rawScreeningDate = latestScreeningItem?.date ?? activeSkrining?.date;
        final DateTime? screeningDate = rawScreeningDate != null
            ? DateTime(rawScreeningDate.year, rawScreeningDate.month, rawScreeningDate.day)
            : null;

        // Tanggal awal scroller: tanggal skrining terbaru (atau today jika belum ada skrining / deviasi waktu)
        final DateTime startDate;
        if (screeningDate != null) {
          startDate = screeningDate.isAfter(today) ? today : screeningDate;
        } else {
          startDate = today;
        }

        const int totalDays = 30; // Tepat 1 siklus skrining (30 hari / 4 minggu)
        final int pastDays = today.difference(startDate).inDays.clamp(0, totalDays - 1);
        final int todayIndex = pastDays;
        final DateTime endDate = DateTime(startDate.year, startDate.month, startDate.day + totalDays - 1);

        // Pastikan tanggal terpilih otomatis berada di dalam rentang siklus skrining [startDate, endDate]
        if (_selectedDate.isBefore(startDate) || _selectedDate.isAfter(endDate)) {
          _selectedDate = today.isBefore(startDate) ? startDate : (today.isAfter(endDate) ? endDate : today);
        }

        // Auto-scroll agar "Hari ini" terlihat jelas saat awal render
        if (!_hasInitialScrolled && hasScreening) {
          _hasInitialScrolled = true;
          _scrollToToday(todayIndex);
        }

        final selectedDateKey = PhysicalActivityService.instance.formatDateKey(_selectedDate);
        final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        final isFutureDate = selectedDateOnly.isAfter(today);

        return ProgressPageScaffold(
          title: 'Rekomendasi Aktivitas Fisik',
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. KONDISI BELUM ADA SKRINING
                if (!hasScreening) ...[
                  _buildNoScreeningState(context, isDark, textPrimary, textSecondary),
                ] else ...[
                  // Horizontal Real-Time Date Scroller (1 Siklus Skrining: 30 Hari Penuh)
                  SizedBox(
                    height: 74,
                    child: ListView.builder(
                      controller: _dateScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: totalDays,
                      itemBuilder: (context, index) {
                        final date = DateTime(startDate.year, startDate.month, startDate.day + index);
                        final isSelected = (_selectedDate.year == date.year &&
                            _selectedDate.month == date.month &&
                            _selectedDate.day == date.day);
                        final isPast = date.isBefore(today);
                        final isToday = (date.year == today.year &&
                            date.month == today.month &&
                            date.day == today.day);

                        final dayName = isToday ? 'Hari ini' : dayNames[date.weekday % 7];
                        final dateStr = '${date.day}/${date.month}/${date.year.toString().substring(2)}';

                        Color bgColor;
                        Color textColor;
                        Color subTextColor;
                        Border border;

                        if (isSelected) {
                          bgColor = isDark ? const Color(0xFF58AF86) : const Color(0xFF489874);
                          textColor = Colors.white;
                          subTextColor = Colors.white.withValues(alpha: 0.9);
                          border = Border.all(color: bgColor, width: 1.5);
                        } else if (isPast) {
                          // Past Days -> Merah, Teks Putih
                          bgColor = const Color(0xFFEF4444);
                          textColor = Colors.white;
                          subTextColor = Colors.white.withValues(alpha: 0.85);
                          border = Border.all(color: const Color(0xFFDC2626));
                        } else if (isToday) {
                          // Today -> Hijau Pastel
                          bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
                          textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
                          subTextColor = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857);
                          border = Border.all(color: const Color(0xFF10B981), width: 1.5);
                        } else {
                          // Future Days
                          bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
                          textColor = isDark ? Colors.white : const Color(0xFF0F172A);
                          subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
                          border = Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
                        }

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                            });
                            final dKey = PhysicalActivityService.instance.formatDateKey(date);
                            PhysicalActivityService.instance.listenToFirestoreSessions(dKey);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 58,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: border,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF489874).withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      )
                                    ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: isToday ? 9.5 : 11,
                                    fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: subTextColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  // 3. KARTU HASIL SKRINING & TARGET KLINIS PENGGUNA
                  _buildScreeningSummaryCard(
                    activeSkrining,
                    rec,
                    categoryKey,
                    displayCategory,
                    isDark,
                    textPrimary,
                    textSecondary,
                  ),

                  const SizedBox(height: 18),

                  // Section Header: Pilihan Aktivitas Olahraga
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilihan Aktivitas Olahraga',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getCategoryActivityFocusSubtitle(categoryKey),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Daftar Vertikal Kartu Aktivitas Fisik Sesuai Hasil Skrining
                  ...activities.map((act) => _buildActivityCard(
                        act,
                        isDark,
                        selectedDateKey,
                        isFuture: isFutureDate,
                      )),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Kartu Ringkasan Hasil Skrining & Target Klinis
  Widget _buildScreeningSummaryCard(
    SkriningData data,
    CategoryRecommendation rec,
    String categoryKey,
    String displayCategory,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final catColor = _getCategoryColor(categoryKey);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    // Kategori khusus yang butuh proteksi sendi / pengawasan
    final isObesitySpecialCare = categoryKey.contains('Obesitas II') ||
        categoryKey.contains('Obesitas III') ||
        categoryKey.contains('Obesitas I');
    final isUnderweightCare = categoryKey.toLowerCase().contains('underweight') ||
        categoryKey.toLowerCase().contains('insufficient') ||
        displayCategory.toLowerCase().contains('insufficient');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hasil Skrining',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: catColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    data.riskTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: catColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  size: 20,
                  color: catColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: catColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'IMT ${data.formattedBmi} kg/m²',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.track_changes_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Target: ${rec.clinicalGoal}',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isObesitySpecialCare || isUnderweightCare) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2314) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isUnderweightCare
                          ? 'Perhatian: Fokuskan latihan pada pembentukan massa otot dan batasi kardio panjang.'
                          : 'Perhatian Klinis: Olahraga difokuskan ramah sendi (low/non-weight bearing). Hindari gerakan hentakan tinggi/melompat.',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tampilan Kosong jika pengguna belum pernah melakukan skrining
  Widget _buildNoScreeningState(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF58AF86) : const Color(0xFF489874))
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_run_rounded,
              color: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Hasil Skrining',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rekomendasi aktivitas fisik dipersonalisasi berdasarkan hasil skrining kesehatan dan kategori IMT Anda.\nSilakan lakukan skrining terlebih dahulu.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SkriningLandingScreen(user: _effectiveUser),
                ),
              ).then((_) {
                if (mounted) {
                  ScreeningHistoryService.instance.loadHistory(_userKey);
                  _hasInitialScrolled = false;
                  setState(() {});
                }
              });
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
            label: Text(
              'Mulai Skrining Sekarang',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    Map<String, dynamic> act,
    bool isDark,
    String dateKey, {
    bool isFuture = false,
  }) {
    final actId = act['id'] as String;
    final isCompleted = PhysicalActivityService.instance.isCompleted(dateKey, actId);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isCompleted
        ? (isDark ? const Color(0xFF58AF86) : const Color(0xFF489874))
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final textTitle = isDark ? Colors.white : const Color(0xFF0F172A);
    final textDesc = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: cardBorder,
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetail(act, dateKey),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                // Thumbnail Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        act['thumb'] as String,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 76,
                          height: 76,
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2F1E8),
                          child: Icon(
                            Icons.directions_run_rounded,
                            color: isDark ? const Color(0xFF58AF86) : const Color(0xFF489874),
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Card Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with icon
                      Row(
                        children: [
                          Image.asset(
                            act['icon'] as String,
                            width: 18,
                            height: 18,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              act['name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textTitle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        act['desc'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: textDesc,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Pills: Duration, Frequency, Intensity, Calories
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildPill(Icons.access_time_rounded, act['duration'] as String, isDark),
                          _buildPill(Icons.calendar_today_rounded, act['frequency'] as String, isDark),
                          if (act['intensity'] != null)
                            _buildPill(Icons.speed_rounded, (act['intensity'] as String).split(' ').first, isDark),
                          _buildPill(Icons.local_fire_department_rounded, act['calories'] as String, isDark),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Status Indicator (Dapat ditekan untuk toggle selesai/belum atau otomatis via timer)
                // Hanya aktif pada hari ini dan tanggal lampau; nonaktif pada tanggal mendatang
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: isFuture
                      ? null
                      : () {
                          PhysicalActivityService.instance.toggleActivity(
                            dateKey: dateKey,
                            activity: act,
                            context: context,
                          );
                        },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6, left: 2),
                    child: Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isCompleted
                          ? (isDark ? const Color(0xFF58AF86) : const Color(0xFF489874))
                          : (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
