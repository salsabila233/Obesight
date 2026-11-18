import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/screening_history_model.dart';
import '../../models/user_model.dart';
import '../../services/admin_user_service.dart';
import '../../widgets/admin_capsule_bottom_nav.dart';
import '../skrining/skrining_result_screen.dart';
import '../../widgets/app_alert.dart';

class AdminUserScreeningDetailScreen extends StatelessWidget {
  final String userId;
  final UserModel? initialUser;

  const AdminUserScreeningDetailScreen({
    super.key,
    required this.userId,
    this.initialUser,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const sageGreen = Color(0xFF529471); // Warna hijau sage Obesight
    final pageBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: pageBgColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: sageGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detail Profil Skrining',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Hapus Akun Pengguna',
            onPressed: () => _confirmDeleteUser(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Latar belakang hijau sage di balik lengkungan atas agar lekukan terlihat sempurna identik dengan Pengguna & Laporan
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 32,
            child: Container(color: sageGreen),
          ),

          // Lembaran konten putih dengan sudut atas melengkung (Radius 28)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: pageBgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: StreamBuilder<UserModel?>(
                  stream: AdminUserService.instance.streamUserById(userId),
                  initialData: initialUser,
                  builder: (context, userSnapshot) {
                    final user =
                        userSnapshot.data ??
                        initialUser ??
                        UserModel(
                          id: userId,
                          name: 'Pengguna ObeSight',
                          email: '',
                          username: 'user',
                          role: UserRole.user,
                        );

                    return StreamBuilder<List<ScreeningHistoryItem>>(
                      stream: AdminUserService.instance.streamUserScreenings(userId),
                      builder: (context, screeningSnapshot) {
                        final screenings = screeningSnapshot.data ?? [];
                        final latestScreening = screenings.isNotEmpty
                            ? screenings.first
                            : null;
                        final totalScreenings = screenings.length;

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Header Card Profil Pengguna (Persis Gambar 2)
                              _buildTopProfileCard(
                                isDark: isDark,
                                user: user,
                                totalScreenings: totalScreenings,
                                lastScreeningDate: latestScreening?.date,
                              ),

                              const SizedBox(height: 18),

                              // 2. Card Hasil Skrining Terakhir (Dilebarkan Full Width)
                              _buildLatestScreeningColumn(
                                latestScreening,
                                isDark: isDark,
                              ),

                              const SizedBox(height: 22),

                              // 3. Section Riwayat Singkat (Persis Gambar 2)
                              _buildRiwayatSingkatSection(
                                context: context,
                                isDark: isDark,
                                screenings: screenings,
                                user: user,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AdminCapsuleBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pop(index);
          }
        },
      ),
    );
  }

  // ===========================================================================
  // 1. TOP PROFILE CARD (Identik dengan Gambar 2)
  // ===========================================================================
  Widget _buildTopProfileCard({
    required bool isDark,
    required UserModel user,
    required int totalScreenings,
    required DateTime? lastScreeningDate,
  }) {
    String formattedLastDate = '-';
    if (lastScreeningDate != null) {
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      formattedLastDate =
          '${lastScreeningDate.day} ${months[lastScreeningDate.month - 1]} ${lastScreeningDate.year}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar dengan border ring hijau melingkar
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF529471), width: 1.5),
            ),
            child: ClipOval(child: _buildAvatarImage(user)),
          ),

          const SizedBox(width: 12),

          // Tengah: Nama, Email, Nomor Telepon, Gender • Usia
          Expanded(
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : 'Pengguna ObeSight',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  user.email.isNotEmpty
                      ? user.email
                      : 'Email belum diisi',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    decoration: TextDecoration.underline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  (user.phone != null && user.phone!.trim().isNotEmpty)
                      ? user.phone!.trim()
                      : '-',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  user.genderAndAgeDotFormatted != '--'
                      ? user.genderAndAgeDotFormatted
                      : (user.isAdmin ? 'Administrator' : '-'),
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        (user.address != null && user.address!.trim().isNotEmpty)
                            ? user.address!.trim()
                            : 'Alamat belum diisi',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: (user.address != null && user.address!.trim().isNotEmpty)
                              ? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155))
                              : const Color(0xFF94A3B8),
                          fontStyle: (user.address != null && user.address!.trim().isNotEmpty)
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Garis Pembatas Vertikal
          Container(
            width: 1,
            height: 74,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),

          // Kanan: Bergabung, Total Skrining, Skrining Terakhir
          Expanded(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRightMetricItem(
                  isDark: isDark,
                  icon: Icons.calendar_today_outlined,
                  label: 'Bergabung',
                  value: user.joinedFormatted != 'Belum tersedia'
                      ? user.joinedFormatted
                      : '-',
                ),
                const SizedBox(height: 5),
                _buildRightMetricItem(
                  isDark: isDark,
                  icon: Icons.stacked_line_chart_rounded,
                  label: 'Total Skrining',
                  value: '$totalScreenings kali',
                ),
                const SizedBox(height: 5),
                _buildRightMetricItem(
                  isDark: isDark,
                  icon: Icons.access_time_rounded,
                  label: 'Skrining Terakhir',
                  value: formattedLastDate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightMetricItem({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 11, color: const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: const Color(0xFF94A3B8),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPER UNIFIKASI KLASIFIKASI & WARNA SKRINING
  // ===========================================================================
  static _ScreeningDisplayInfo _getScreeningDisplayInfo(ScreeningHistoryItem item) {
    final data = item.skriningData;
    final rawCatTitle = data.categoryTitle.replaceAll('\n', ' ').trim();
    final rawClassCat = data.classificationCategory.trim();
    final rawCategory = item.category.trim();
    final bmi = item.bmi > 0 ? item.bmi : data.bmi;

    final combined =
        '${rawCatTitle.toLowerCase()} ${rawClassCat.toLowerCase()} ${rawCategory.toLowerCase()}';

    final isObesity = combined.contains('obesi') ||
        combined.contains('morbid') ||
        bmi >= 27.0;
    final isOverweight = !isObesity &&
        (combined.contains('overweight') ||
            combined.contains('lebih') ||
            (bmi >= 23.0 && bmi < 27.0));
    final isUnderweight = !isObesity &&
        !isOverweight &&
        (combined.contains('underweight') ||
            combined.contains('insufficient') ||
            combined.contains('kurang') ||
            (bmi > 0 && bmi < 18.5));

    if (isObesity) {
      String sub = 'Level I';
      String badge = 'Tipe 1';
      if (combined.contains('iii') ||
          combined.contains('3') ||
          combined.contains('morbid') ||
          bmi >= 35.0) {
        sub = 'Level III';
        badge = 'Tipe 3';
      } else if (combined.contains('ii') ||
          combined.contains('2') ||
          bmi >= 30.0) {
        sub = 'Level II';
        badge = 'Tipe 2';
      } else if (combined.contains('i') || combined.contains('1')) {
        sub = 'Level I';
        badge = 'Tipe 1';
      }

      return _ScreeningDisplayInfo(
        categoryTitle: 'Obesitas',
        subCategory: sub,
        badgeLabel: badge,
        descriptionNote: data.riskDescription.isNotEmpty
            ? data.riskDescription
            : 'Perlu evaluasi klinis dan pemantauan dokter',
        themeColor: const Color(0xFFEF4444),
        badgeBg: const Color(0xFFFEE2E2),
        badgeTextColor: const Color(0xFFB91C1C),
        boxBg: const Color(0xFFFEF2F2),
        boxTextColor: const Color(0xFF991B1B),
        boxIcon: Icons.warning_amber_rounded,
        boxIconColor: const Color(0xFFEF4444),
        boxText:
            'Perlu evaluasi klinis & konsultasi dokter untuk penanganan obesitas secara terstruktur.',
      );
    }

    if (isOverweight) {
      String sub = 'Level I';
      String badge = 'Level 1';
      if (combined.contains('ii') || combined.contains('2') || bmi >= 25.0) {
        sub = 'Level II';
        badge = 'Level 2';
      }

      return _ScreeningDisplayInfo(
        categoryTitle: 'Overweight',
        subCategory: sub,
        badgeLabel: badge,
        descriptionNote: data.riskDescription.isNotEmpty
            ? data.riskDescription
            : 'Berat badan sedikit diatas rentang ideal',
        themeColor: const Color(0xFFF59E0B),
        badgeBg: const Color(0xFFFEF3C7),
        badgeTextColor: const Color(0xFF92400E),
        boxBg: const Color(0xFFFEF9C3),
        boxTextColor: const Color(0xFF854D0E),
        boxIcon: Icons.error_outline_rounded,
        boxIconColor: const Color(0xFFD97706),
        boxText:
            'Disarankan untuk mulai mengatur pola makan & meningkatkan aktivitas fisik secara teratur.',
      );
    }

    if (isUnderweight) {
      return _ScreeningDisplayInfo(
        categoryTitle: 'Insufficient Weight',
        subCategory: 'Kurang',
        badgeLabel: 'Kurang',
        descriptionNote: data.riskDescription.isNotEmpty
            ? data.riskDescription
            : 'Berat badan di bawah rentang ideal',
        themeColor: const Color(0xFF0284C7),
        badgeBg: const Color(0xFFE0F2FE),
        badgeTextColor: const Color(0xFF0369A1),
        boxBg: const Color(0xFFF0F9FF),
        boxTextColor: const Color(0xFF075985),
        boxIcon: Icons.info_outline_rounded,
        boxIconColor: const Color(0xFF0284C7),
        boxText:
            'Perhatikan pemenuhan nutrisi dan kalori harian untuk mencapai berat badan ideal.',
      );
    }

    return _ScreeningDisplayInfo(
      categoryTitle: 'Normal Weight',
      subCategory: 'Normal',
      badgeLabel: 'Ideal',
      descriptionNote: data.riskDescription.isNotEmpty
          ? data.riskDescription
          : 'Berat badan dalam rentang ideal',
      themeColor: const Color(0xFF10B981),
      badgeBg: const Color(0xFFDCFCE7),
      badgeTextColor: const Color(0xFF15803D),
      boxBg: const Color(0xFFF0FDF4),
      boxTextColor: const Color(0xFF166534),
      boxIcon: Icons.check_circle_outline_rounded,
      boxIconColor: const Color(0xFF10B981),
      boxText:
          'Kondisi berat badan dan pola hidup dalam batas normal. Pertahankan gaya hidup sehat Anda!',
    );
  }

  // ===========================================================================
  // 2A. CARD KIRI: HASIL SKRINING TERAKHIR (Persis Gambar 2)
  // ===========================================================================
  Widget _buildLatestScreeningColumn(
    ScreeningHistoryItem? screening, {
    required bool isDark,
  }) {
    if (screening == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hasil Skrining Terakhir',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_late_outlined,
                    size: 30,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum Ada Skrining',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pengguna belum pernah melakukan skrining obesitas.',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final info = _getScreeningDisplayInfo(screening);
    final heightVal = screening.skriningData.height?.toInt() ?? 0;
    final weightVal = screening.skriningData.weight?.toInt() ?? 0;
    final bmiVal = screening.bmi > 0 ? screening.bmi : screening.skriningData.bmi;
    final bmiFormatted = bmiVal.toStringAsFixed(1).replaceAll('.', ',');

    final categoryTitle = info.categoryTitle;
    final subCategory = info.subCategory;
    final descriptionNote = info.descriptionNote;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hasil Skrining Terakhir',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Atas: Ilustrasi Karakter & Judul Kategori
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ilustrasi Wanita Obesight
                  SizedBox(
                    width: 65,
                    height: 85,
                    child: Image.asset(
                      'assets/illustration_woman.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/avatar_zahra.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subCategory,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: info.themeColor,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: info.badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            descriptionNote,
                            style: GoogleFonts.poppins(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                              color: info.badgeTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Baris 3 Box Metrik: Tinggi Badan, Berat Badan, IMT
              Row(
                children: [
                  Expanded(
                    child: _buildMetricMiniBox(
                      isDark: isDark,
                      icon: Icons.height_rounded,
                      label: 'Tinggi Badan',
                      value: '$heightVal cm',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildMetricMiniBox(
                      isDark: isDark,
                      icon: Icons.monitor_weight_outlined,
                      label: 'Berat Badan',
                      value: '$weightVal kg',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildMetricMiniBox(
                      isDark: isDark,
                      icon: Icons.shopping_bag_outlined,
                      label: 'IMT',
                      value: bmiFormatted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Indikator Rentang IMT dengan Pointer Segitiga (Persis Gambar 2)
              _buildExactBmiGauge(bmiVal, isDark: isDark),

              const SizedBox(height: 10),

              // Dynamic Box di bagian bawah
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: info.boxBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      info.boxIcon,
                      size: 14,
                      color: info.boxIconColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        info.boxText,
                        style: GoogleFonts.poppins(
                          fontSize: 7.5,
                          color: info.boxTextColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricMiniBox({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: const Color(0xFF0D9488)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 7,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExactBmiGauge(double bmi, {required bool isDark}) {
    // Normalisasi posisi IMT: rentang 15.0 s/d 35.0
    final progress = ((bmi - 15.0) / (35.0 - 15.0)).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final pointerPos = (totalWidth * progress - 6).clamp(
          0.0,
          totalWidth - 12,
        );

        return Column(
          children: [
            // Pointer Segitiga Menunjuk ke Bawah
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(width: totalWidth, height: 10),
                Positioned(
                  left: pointerPos,
                  top: -4,
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),

            // Bar 4 Segmen Warna
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 5,
                child: Row(
                  children: [
                    // Kurang (< 18.49) -> Ungu
                    Expanded(
                      flex: 18,
                      child: Container(color: const Color(0xFFA855F7)),
                    ),
                    // Normal (18.5 - 24.9) -> Biru
                    Expanded(
                      flex: 32,
                      child: Container(color: const Color(0xFF38BDF8)),
                    ),
                    // Overweight (25 - 27) -> Oranye
                    Expanded(
                      flex: 25,
                      child: Container(color: const Color(0xFFF97316)),
                    ),
                    // Obesitas (> 27) -> Merah
                    Expanded(
                      flex: 25,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 4 Label di Bawah Bar Sesuai Screenshot Gambar 2
            Row(
              children: [
                _buildGaugeLabel('Kurang', '< 18,49', isDark: isDark),
                _buildGaugeLabel('Normal', '18,5–24,9 kg', isDark: isDark),
                _buildGaugeLabel('Overweight', '25–27 kg', isDark: isDark),
                _buildGaugeLabel('Obesitas', '> 27 kg', isDark: isDark),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildGaugeLabel(String title, String range, {required bool isDark}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                height: 1.0,
              ),
              maxLines: 1,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              range,
              style: GoogleFonts.poppins(
                fontSize: 6.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.1,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }



  // ===========================================================================
  // 3. RIWAYAT SINGKAT (Persis Gambar 2)
  // ===========================================================================
  Widget _buildRiwayatSingkatSection({
    required BuildContext context,
    required bool isDark,
    required List<ScreeningHistoryItem> screenings,
    required UserModel user,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Singkat',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        if (screenings.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: screenings.length,
            itemBuilder: (context, index) {
              final item = screenings[index];
              final info = _getScreeningDisplayInfo(item);

              final themeColor = info.themeColor;
              final categoryName = info.categoryTitle;
              final badgeLabel = info.badgeLabel;
              final dateStr =
                  '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}';
              final timeStr =
                  '${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')} WIB';
              final heightVal = item.skriningData.height?.toInt() ?? 0;
              final weightVal = item.skriningData.weight?.toInt() ?? 0;
              final bmiVal = (item.bmi > 0 ? item.bmi : item.skriningData.bmi)
                  .toStringAsFixed(1)
                  .replaceAll('.', ',');

              return _buildRiwayatCard(
                context: context,
                isDark: isDark,
                themeColor: themeColor,
                dateStr: dateStr,
                timeStr: timeStr,
                categoryName: categoryName,
                badgeLabel: badgeLabel,
                bmiVal: '$bmiVal kg',
                heightVal: '$heightVal cm',
                weightVal: '$weightVal kg',
                onDetailTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SkriningResultScreen(
                        data: item.skriningData,
                        user: user,
                        isFromHistory: true,
                      ),
                    ),
                  );
                },
              );
            },
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.history_toggle_off_rounded,
                  size: 32,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada riwayat skrining',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pengguna ini belum memiliki riwayat sesi skrining di database.',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRiwayatCard({
    required BuildContext context,
    required bool isDark,
    required Color themeColor,
    required String dateStr,
    required String timeStr,
    required String categoryName,
    required String badgeLabel,
    required String bmiVal,
    required String heightVal,
    required String weightVal,
    required VoidCallback onDetailTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Garis strip warna di tepi paling kiri sesuai desain
              Container(width: 3.5, color: themeColor),

              // Konten kartu riwayat
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kotak Tanggal di Kiri
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: themeColor,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dateStr,
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              timeStr,
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Konten Kanan: Kategori, Tombol Lihat Detail & 3 Metrik
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hasil Skrining',
                                        style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 6,
                                        runSpacing: 2,
                                        children: [
                                          Text(
                                            categoryName,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: themeColor,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: themeColor.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              badgeLabel,
                                              style: GoogleFonts.poppins(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: themeColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Tombol "Lihat Detail >"
                                InkWell(
                                  onTap: onDetailTap,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF3B82F6),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      'Lihat Detail >',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Baris 3 Metrik: IMT, Tinggi Badan, Berat Badan
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRiwayatStatItem(
                                    isDark: isDark,
                                    icon: Icons.accessibility_new_rounded,
                                    label: 'IMT',
                                    value: bmiVal,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildRiwayatStatItem(
                                    isDark: isDark,
                                    icon: Icons.height_rounded,
                                    label: 'Tinggi Badan',
                                    value: heightVal,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildRiwayatStatItem(
                                    isDark: isDark,
                                    icon: Icons.scale_rounded,
                                    label: 'Berat Badan',
                                    value: weightVal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiwayatStatItem({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 6.5,
                  color: const Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(UserModel user) {
    final photo = user.avatarUrl ?? user.photoPath;

    if (photo != null &&
        (photo.startsWith('http://') || photo.startsWith('https://'))) {
      return Image.network(
        photo,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderDetailAvatar(user),
      );
    } else if (photo != null && photo.startsWith('assets/')) {
      return Image.asset(
        photo,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderDetailAvatar(user),
      );
    }

    return _buildPlaceholderDetailAvatar(user);
  }

  Widget _buildPlaceholderDetailAvatar(UserModel user) {
    return Container(
      color: user.isAdmin ? const Color(0xFFE8F5EE) : const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Icon(
        user.isAdmin
            ? Icons.admin_panel_settings_rounded
            : Icons.person_rounded,
        size: 32,
        color: user.isAdmin ? const Color(0xFF267352) : const Color(0xFF64748B),
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context) {
    final displayName = initialUser?.name.trim().isNotEmpty == true
        ? initialUser!.name
<<<<<<< Updated upstream
        : 'Pengguna ObeSight';
=======
        : 'pengguna ini';
>>>>>>> Stashed changes
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
<<<<<<< Updated upstream
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFDC2626),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hapus Akun Pengguna?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Apakah kamu yakin ingin menghapus akun "$displayName"? Seluruh data riwayat skrining dan catatan kesehatannya akan dihapus secara permanen.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            if (initialUser != null && initialUser!.email.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  initialUser!.email,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
=======
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hapus Akun Pengguna?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
>>>>>>> Stashed changes
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Hapus',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
<<<<<<< Updated upstream
=======
        content: Text(
          'Apakah Anda yakin ingin menghapus akun "$displayName" beserta seluruh data riwayat skrining dan catatan kesehatannya? Tindakan ini bersifat permanen dan terisolasi.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              'Hapus Akun',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
>>>>>>> Stashed changes
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        final navigator = Navigator.of(context);
        final success = await AdminUserService.instance.deleteUserAccount(userId);
        if (context.mounted) {
          navigator.pop(true);
          if (success) {
            AppAlert.showSuccess(
              context,
              'Akun pengguna "$displayName" berhasil dihapus.',
            );
          } else {
            AppAlert.showError(
              context,
              'Gagal menghapus akun pengguna.',
            );
          }
        }
      }
    });
  }
}

class _ScreeningDisplayInfo {
  final String categoryTitle;
  final String subCategory;
  final String badgeLabel;
  final String descriptionNote;
  final Color themeColor;
  final Color badgeBg;
  final Color badgeTextColor;
  final Color boxBg;
  final Color boxTextColor;
  final IconData boxIcon;
  final Color boxIconColor;
  final String boxText;

  const _ScreeningDisplayInfo({
    required this.categoryTitle,
    required this.subCategory,
    required this.badgeLabel,
    required this.descriptionNote,
    required this.themeColor,
    required this.badgeBg,
    required this.badgeTextColor,
    required this.boxBg,
    required this.boxTextColor,
    required this.boxIcon,
    required this.boxIconColor,
    required this.boxText,
  });
}
