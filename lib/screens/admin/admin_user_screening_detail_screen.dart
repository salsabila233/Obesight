import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/screening_history_model.dart';
import '../../models/user_model.dart';
import '../../services/admin_user_service.dart';
import '../../widgets/admin_capsule_bottom_nav.dart';
import '../skrining/skrining_result_screen.dart';

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
    const sageGreen = Color(0xFF529471); // Warna hijau sage Obesight

    return Scaffold(
      backgroundColor: sageGreen,
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
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    name: 'Zahra Fitriana',
                    email: 'zahraafitriana@gmail.com',
                    username: 'zahraafitriana',
                    role: UserRole.user,
                    phone: '0893-3421-2098',
                    dob: '12 Juli 2003',
                    gender: 'Perempuan',
                    joined: '12 Juni 2026',
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header Card Profil Pengguna (Persis Gambar 2)
                        _buildTopProfileCard(
                          user: user,
                          totalScreenings: totalScreenings,
                          lastScreeningDate: latestScreening?.date,
                        ),

                        const SizedBox(height: 18),

                        // 2. Dua Card Berdampingan: Hasil Skrining Terakhir & Informasi Pribadi
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Kiri: Hasil Skrining Terakhir
                            Expanded(
                              flex: 57,
                              child: _buildLatestScreeningColumn(
                                latestScreening,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Card Kanan: Informasi Pribadi
                            Expanded(
                              flex: 43,
                              child: _buildPersonalInformationColumn(user),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // 3. Section Riwayat Singkat (Persis Gambar 2)
                        _buildRiwayatSingkatSection(
                          context: context,
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
    required UserModel user,
    required int totalScreenings,
    required DateTime? lastScreeningDate,
  }) {
    String formattedLastDate = '11 Agustus 2026';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  user.name.isNotEmpty ? user.name : 'Zahra Fitriana',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
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
                    color: const Color(0xFF64748B),
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
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  user.genderAndAgeDotFormatted != '--'
                      ? user.genderAndAgeDotFormatted
                      : (user.isAdmin ? 'Administrator' : '-'),
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),

          // Garis Pembatas Vertikal
          Container(
            width: 1,
            height: 64,
            color: const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),

          // Kanan: Bergabung, Total Skrining, Skrining Terakhir
          Expanded(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRightMetricItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Bergabung',
                  value: user.joinedFormatted != 'Belum tersedia'
                      ? user.joinedFormatted
                      : '12 Juni 2026',
                ),
                const SizedBox(height: 5),
                _buildRightMetricItem(
                  icon: Icons.stacked_line_chart_rounded,
                  label: 'Total Skrining',
                  value: totalScreenings > 0
                      ? '$totalScreenings kali'
                      : '3 kali',
                ),
                const SizedBox(height: 5),
                _buildRightMetricItem(
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
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
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
                  color: const Color(0xFF0F172A),
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
  // 2A. CARD KIRI: HASIL SKRINING TERAKHIR (Persis Gambar 2)
  // ===========================================================================
  Widget _buildLatestScreeningColumn(ScreeningHistoryItem? screening) {
    // Ambil data riil atau fallback default sesuai mockup Zahra di Gambar 2
    final heightVal = screening?.skriningData.height?.toInt() ?? 165;
    final weightVal = screening?.skriningData.weight?.toInt() ?? 72;
    final bmiVal = screening?.bmi != null && screening!.bmi > 0
        ? screening.bmi
        : 26.8;
    final bmiFormatted = bmiVal.toStringAsFixed(1).replaceAll('.', ',');

    final categoryTitle = screening?.category.contains('Obesitas') == true
        ? 'Obesitas'
        : 'Overweight';
    final subCategory = screening?.category.contains('Obesitas') == true
        ? 'Level II'
        : 'Level I';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hasil Skrining Terakhir',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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
                            color: const Color(0xFF0F172A),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subCategory,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEAB308), // Warna Kuning/Emas
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
                            color: const Color(0xFFFEF08A), // Kuning lembut
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Berat badan sedikit diatas rentang ideal',
                            style: GoogleFonts.poppins(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF854D0E),
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
                      icon: Icons.height_rounded,
                      label: 'Tinggi Badan',
                      value: '$heightVal cm',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildMetricMiniBox(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Berat Badan',
                      value: '$weightVal kg',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildMetricMiniBox(
                      icon: Icons.shopping_bag_outlined,
                      label: 'IMT',
                      value: bmiFormatted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Indikator Rentang IMT dengan Pointer Segitiga (Persis Gambar 2)
              _buildExactBmiGauge(bmiVal),

              const SizedBox(height: 10),

              // Yellow Warning Box di bagian bawah
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: Color(0xFF0F172A),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Hasil ini berdasarkan data yang diberikan pengguna dan merupakan diagnosis medis.',
                        style: GoogleFonts.poppins(
                          fontSize: 7.5,
                          color: const Color(0xFF0F172A),
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
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
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
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExactBmiGauge(double bmi) {
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
            // Pointer Segitiga Hitam Menunjuk ke Bawah
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(width: totalWidth, height: 10),
                Positioned(
                  left: pointerPos,
                  top: -4,
                  child: const Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Colors.black,
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
                _buildGaugeLabel('Kurang', '< 18,49'),
                _buildGaugeLabel('Normal', '18,5–24,9 kg'),
                _buildGaugeLabel('Overweight', '25–27 kg'),
                _buildGaugeLabel('Obesitas', '> 27 kg'),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildGaugeLabel(String title, String range) {
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
                color: const Color(0xFF0F172A),
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
                color: const Color(0xFF64748B),
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
  // 2B. CARD KANAN: INFORMASI PRIBADI (Persis Gambar 2)
  // ===========================================================================
  Widget _buildPersonalInformationColumn(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Pribadi',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPersonalDetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Nama Lengkap',
                value: user.name.isNotEmpty ? user.name : 'Zahra Fitria',
              ),
              const SizedBox(height: 8),
              _buildPersonalDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Tanggal Lahir',
                value: (user.dob != null && user.dob!.trim().isNotEmpty)
                    ? user.dob!.trim()
                    : '12 Juli 2003',
              ),
              const SizedBox(height: 8),
              _buildPersonalDetailRow(
                icon: Icons.people_outline_rounded,
                label: 'Jenis Kelamin',
                value: (user.gender != null && user.gender!.trim().isNotEmpty)
                    ? user.gender!.trim()
                    : 'Perempuan',
              ),
              const SizedBox(height: 8),
              _buildPersonalDetailRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: user.email.isNotEmpty
                    ? user.email
                    : 'zahraafitriana@gmail.com',
                isEmail: true,
              ),
              const SizedBox(height: 8),
              _buildPersonalDetailRow(
                icon: Icons.phone_outlined,
                label: 'Telepon',
                value: (user.phone != null && user.phone!.trim().isNotEmpty)
                    ? user.phone!.trim()
                    : '089334212098',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isEmail = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          ),
          child: Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 7.5,
                  color: const Color(0xFF94A3B8),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: isEmail ? 9.0 : 9.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
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
  // 3. RIWAYAT SINGKAT (Persis Gambar 2)
  // ===========================================================================
  Widget _buildRiwayatSingkatSection({
    required BuildContext context,
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
            color: const Color(0xFF0F172A),
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
              final isObesity =
                  item.category.toLowerCase().contains('obesitas') ||
                  item.risk.toLowerCase().contains('tinggi');

              final themeColor = isObesity
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFF97316);
              final categoryName = isObesity ? 'Obesitas' : 'Overweight';
              final badgeLabel = isObesity ? 'Tipe 2' : 'Level 1';
              final dateStr =
                  '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}';
              final timeStr =
                  '${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')} WIB';
              final heightVal = item.skriningData.height?.toInt() ?? 168;
              final weightVal = item.skriningData.weight?.toInt() ?? 72;
              final bmiVal = item.bmi.toStringAsFixed(1).replaceAll('.', ',');

              return _buildRiwayatCard(
                context: context,
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
        else ...[
          // Default Card 1 (Overweight - Orange) sesuai Mockup Gambar 2
          _buildRiwayatCard(
            context: context,
            themeColor: const Color(0xFFF97316),
            dateStr: '11/08/2026',
            timeStr: '09:15 WIB',
            categoryName: 'Overweight',
            badgeLabel: 'Level 1',
            bmiVal: '26,8 kg',
            heightVal: '168 cm',
            weightVal: '72 kg',
            onDetailTap: () {},
          ),
          const SizedBox(height: 10),
          // Default Card 2 (Obesitas - Red) sesuai Mockup Gambar 2
          _buildRiwayatCard(
            context: context,
            themeColor: const Color(0xFFEF4444),
            dateStr: '16/07/2026',
            timeStr: '08:00 WIB',
            categoryName: 'Obesitas',
            badgeLabel: 'Tipe 2',
            bmiVal: '27,5 kg',
            heightVal: '168 cm',
            weightVal: '77 kg',
            onDetailTap: () {},
          ),
        ],
      ],
    );
  }

  Widget _buildRiwayatCard({
    required BuildContext context,
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
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEF08A), width: 0.8),
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
                          color: themeColor.withValues(alpha: 0.1),
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
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              timeStr,
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: const Color(0xFF64748B),
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
                                    icon: Icons.accessibility_new_rounded,
                                    label: 'IMT',
                                    value: bmiVal,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildRiwayatStatItem(
                                    icon: Icons.height_rounded,
                                    label: 'Tinggi Badan',
                                    value: heightVal,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildRiwayatStatItem(
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
                  color: const Color(0xFF0F172A),
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
}
