import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../home/user_home_screen.dart';
import 'skrining_models.dart';
import 'skrining_recommendation_screen.dart';

class SkriningResultScreen extends StatelessWidget {
  final SkriningData data;
  final UserModel? user;

  const SkriningResultScreen({
    super.key,
    required this.data,
    this.user,
  });

  String _formatTodayDate() {
    final now = DateTime.now();
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Color _getCategoryRingColor(String category, bool isDark) {
    final cat = category.toLowerCase();
    if (cat.contains('underweight') || cat.contains('insufficient') || cat.contains('kurang')) {
      return const Color(0xFF93C5FD); // Soft blue
    } else if (cat.contains('normal')) {
      return const Color(0xFF86EFAC); // Soft fresh green
    } else if (cat.contains('overweight') || cat.contains('kelebihan')) {
      return const Color(0xFFFDE047); // Soft sunny amber/yellow
    } else {
      return const Color(0xFFFCA5A5); // Soft coral/rose red for Obesitas / Obesity
    }
  }

  Color _getCategoryBadgeBg(String category, bool isDark) {
    final cat = category.toLowerCase();
    if (cat.contains('underweight') || cat.contains('insufficient') || cat.contains('kurang')) {
      return isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE0F2FE);
    } else if (cat.contains('normal')) {
      return isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7);
    } else if (cat.contains('overweight') || cat.contains('kelebihan')) {
      return isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
    } else {
      return isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
    }
  }

  Color _getCategoryBadgeTextColor(String category, bool isDark) {
    final cat = category.toLowerCase();
    if (cat.contains('underweight') || cat.contains('insufficient') || cat.contains('kurang')) {
      return isDark ? const Color(0xFFBFDBFE) : const Color(0xFF0369A1);
    } else if (cat.contains('normal')) {
      return isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
    } else if (cat.contains('overweight') || cat.contains('kelebihan')) {
      return isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
    } else {
      return isDark ? const Color(0xFFFECACA) : const Color(0xFFB91C1C);
    }
  }

  IconData _getRiskIcon(String riskTitle) {
    if (riskTitle.contains('Terkendali')) {
      return Icons.check_circle_outline_rounded;
    }
    return Icons.warning_amber_rounded;
  }

  Color _getRiskColor(String riskTitle, bool isDark) {
    if (riskTitle.contains('Terkendali')) {
      return isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    } else if (riskTitle.contains('Meningkat') || riskTitle.contains('Perhatian') || riskTitle.contains('Sedang')) {
      return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    }
    return isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
  }

  Color _getRiskBgColor(String riskTitle, bool isDark) {
    if (riskTitle.contains('Terkendali')) {
      return isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7);
    } else if (riskTitle.contains('Meningkat') || riskTitle.contains('Perhatian') || riskTitle.contains('Sedang')) {
      return isDark ? const Color(0xFF334155) : const Color(0xFFFEF3C7);
    }
    return isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user ?? AuthService().currentUser ?? AuthService.defaultUserAccount;
    final userName = currentUser.name.isNotEmpty ? currentUser.name : 'Zahra Fitriana';
    final dateString = _formatTodayDate();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = isDark ? const Color(0xFF58AF86) : const Color(0xFF4A8B6C); // Medical soft green
    final textDark = isDark ? Colors.white : const Color(0xFF1E293B);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: textDark, size: 28),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => UserHomeScreen(user: currentUser)),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Hasil Skrining',
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. CARD PROFIL (Nama & Tanggal Dual-Pills)
                    Row(
                      children: [
                        // Left Pill: Nama
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cardBorder, width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 14,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nama',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w400,
                                          color: textMuted,
                                        ),
                                      ),
                                      Text(
                                        userName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Right Pill: Tanggal
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cardBorder, width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tanggal',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w400,
                                          color: textMuted,
                                        ),
                                      ),
                                      Text(
                                        dateString,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: textDark,
                                        ),
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

                    const SizedBox(height: 18),

                    // 2. SEKSI STATUS/KATEGORI (Avatar Bulat Dinamis + Kategori Dinamis + Badge Dinamis)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar Bulat dengan warna cincin dinamis sesuai kategori
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: _getCategoryRingColor(data.classificationCategory, isDark),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/avatar_zahra.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                'assets/illustration_woman.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Judul Kategori & Badge Dinamis
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.categoryTitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getCategoryBadgeBg(data.classificationCategory, isDark),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  data.categoryBadge,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: _getCategoryBadgeTextColor(data.classificationCategory, isDark),
                                  ),
                                ),
                              ),
                              if (data.aiConfidence != null) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 13,
                                      color: primaryGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'AI Random Forest • Keyakinan ${data.aiConfidence!.toStringAsFixed(0)}%',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: textMuted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (data.isClinicallyAdjusted) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Diselaraskan dengan ambang batas IMT Kemenkes',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 3. SEKSI METRIK UTAMA (Tinggi Badan, Berat Badan, BMI)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          // Tinggi Badan
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F5EE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.height_rounded,
                                    size: 18,
                                    color: isDark ? const Color(0xFF58AF86) : const Color(0xFF2E6B4F),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tinggi Badan',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w400,
                                          color: textMuted,
                                        ),
                                      ),
                                      Text(
                                        '${data.height?.toInt() ?? 165} cm',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Divider
                          Container(
                            height: 32,
                            width: 1,
                            color: cardBorder,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          // Berat Badan
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.monitor_weight_outlined,
                                    size: 18,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Berat Badan',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w400,
                                          color: textMuted,
                                        ),
                                      ),
                                      Text(
                                        '${data.weight?.toInt() ?? 72} Kg',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Divider
                          Container(
                            height: 32,
                            width: 1,
                            color: cardBorder,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          // BMI
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F5EE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.pie_chart_outline_rounded,
                                    size: 18,
                                    color: isDark ? const Color(0xFF58AF86) : const Color(0xFF2E6B4F),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BMI',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w400,
                                          color: textMuted,
                                        ),
                                      ),
                                      Text(
                                        data.formattedBmi,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),



                    const SizedBox(height: 18),

                    // 4. HASIL ANALISIS RISIKO (Warning Card)
                    Text(
                      'Hasil Analisis Risiko',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder, width: 1.2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dynamic Risk Icon Container
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _getRiskBgColor(data.riskTitle, isDark),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getRiskIcon(data.riskTitle),
                              color: _getRiskColor(data.riskTitle, isDark),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.riskTitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: _getRiskColor(data.riskTitle, isDark),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data.riskDescription,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w400,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 5. SEKSI DETAIL POINT: RISIKO YANG DAPAT TERJADI
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Risiko yang dapat terjadi:',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444), // Soft red title
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...data.potentialRisks.map((point) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• ', style: TextStyle(fontSize: 14, color: textDark)),
                                    Expanded(
                                      child: Text(
                                        point,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w400,
                                          color: textDark,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 6. SEKSI DETAIL POINT: FAKTOR YANG PERLU DIPERHATIKAN (Soft Green Card)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFC6E7D2),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faktor yang perlu diperhatikan',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF58AF86) : const Color(0xFF1E3A2F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...data.attentionFactors.map((factor) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• ', style: TextStyle(fontSize: 14, color: textDark)),
                                    Expanded(
                                      child: Text(
                                        factor,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w400,
                                          color: textDark,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ACTION BUTTON: LIHAT REKOMENDASI
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SkriningRecommendationScreen(
                                data: data,
                                user: currentUser,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Lihat Rekomendasi',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
