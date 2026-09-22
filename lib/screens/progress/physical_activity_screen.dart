import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'activity_detail_screen.dart';

class PhysicalActivityScreen extends StatefulWidget {
  const PhysicalActivityScreen({super.key});

  @override
  State<PhysicalActivityScreen> createState() => _PhysicalActivityScreenState();
}

class _PhysicalActivityScreenState extends State<PhysicalActivityScreen> {
  late final ScrollController _dateScrollController;
  final int _todayOffset = 7; // Index of today in [-7 .. +13] (total 21 days)
  late int _selectedDayIndex;

  // Track completed activities (per activity id)
  final Set<String> _completedActivities = {};

  final List<Map<String, dynamic>> _activities = [
    {
      'id': 'jogging',
      'title': 'Jogging',
      'name': 'Jogging',
      'targetText': '30-60 menit',
      'heroImg': 'assets/progress/clean/hero_jogging.png',
      'thumbImg': 'assets/progress/clean/thumb_jogging.png',
      'thumb': 'assets/progress/clean/rec_thumb_jogging.png',
      'icon': 'assets/progress/clean/rec_icon_jogging.png',
      'desc': 'Membantu meningkatkan daya tahan tubuh, membakar kalori dan menjaga kesehatan jantung.',
      'duration': '30-60 menit',
      'frequency': '3-5x/minggu',
      'calories': '200-400 kkal',
      'aboutTitle': 'Tentang Jogging',
      'aboutDesc':
          'Jogging merupakan salah satu jenis latihan aerobik yang dapat meningkatkan kebugaran kardiorespirasi, membantu pembakaran kalori, serta mendukung penurunan berat badan. Aktivitas ini juga berkontribusi pada peningkatan kesehatan jantung dan metabolisme tubuh.',
      'benefits': [
        'Meningkatkan kebugaran jantung dan paru-paru',
        'Membantu pembakaran kalori dan lemak tubuh',
        'Menurunkan berat badan secara berkelanjutan',
        'Meningkatkan suasana hati dan mengurangi stres harian',
      ],
      'specs': {
        'duration': '30-60 menit',
        'frequency': '3-5 kali/minggu',
        'intensity': 'Sedang (60-70% HRmax)',
        'calories': '200-400 kkal',
      },
      'tipsTitle': 'Tips Melakukan Jogging',
      'tips': [
        'Lakukan pemanasan selama 5-10 menit sebelum mulai.',
        'Gunakan sepatu yang nyaman dan sesuai dengan bantalan yang baik.',
        'Jaga postur tubuh tetap tegak dan rileks saat melangkah.',
        'Tingkatkan durasi dan intensitas secara bertahap.',
        'Pastikan tubuh tetap terhidrasi dengan cukup minum air.',
      ],
      'refLink': 'https://doi.org/10.25182/jgp.2016.11.3.%25p',
    },
    {
      'id': 'bodyweight',
      'title': 'Latihan Kekuatan (Bodyweight/Gym)',
      'name': 'Latihan Kekuatan (Bodyweight/Gym)',
      'targetText': '20-45 menit',
      'heroImg': 'assets/progress/clean/hero_bodyweight.png',
      'thumbImg': 'assets/progress/clean/thumb_bodyweight.png',
      'thumb': 'assets/progress/clean/rec_thumb_bodyweight.png',
      'icon': 'assets/progress/clean/rec_icon_bodyweight.png',
      'desc': 'Meningkatkan masa otot, memperkuat tulang, serta meningkatkan metabolisme.',
      'duration': '20-45 menit',
      'frequency': '2-4x/minggu',
      'calories': '150-350 kkal',
      'aboutTitle': 'Tentang Latihan Bodyweight & Kekuatan',
      'aboutDesc':
          'Latihan kekuatan (strength training) adalah aktivitas fisik yang melibatkan kontraksi otot untuk meningkatkan massa otot, kekuatan, dan daya tahan tubuh. Selain membantu membentuk tubuh, latihan kekuatan juga berperan dalam meningkatkan metabolisme istirahat (BMR) dan menjaga kesehatan tulang.',
      'benefits': [
        'Meningkatkan massa dan kekuatan otot secara menyeluruh',
        'Mempercepat metabolisme pembakaran energi istirahat',
        'Meningkatkan kepadatan tulang dan persendian',
        'Memperbaiki postur tubuh dan keseimbangan fisik',
      ],
      'specs': {
        'duration': '20-45 menit',
        'frequency': '2-4 kali/minggu',
        'intensity': 'Sedang-Tinggi (60-80% HRmax)',
        'calories': '150-350 kkal',
      },
      'tipsTitle': 'Tips Melakukan Bodyweight',
      'tips': [
        'Lakukan pemanasan selama 5-10 menit sebelum mulai.',
        'Fokus pada gerakan yang benar dan kontrol penuh tubuh.',
        'Mulai dengan variasi gerakan sesuai kemampuan dasar (push-up, squat, plank).',
        'Istirahat antar set selama 30-60 detik.',
        'Lakukan pendinginan dan peregangan otot setelah selesai.',
      ],
      'refLink': 'https://doi.org/10.21831/jk.v8i1.31208',
    },
    {
      'id': 'cycling',
      'title': 'Bersepeda',
      'name': 'Bersepeda',
      'targetText': '30-60 menit',
      'heroImg': 'assets/progress/clean/hero_cycling.png',
      'thumbImg': 'assets/progress/clean/thumb_cycling.png',
      'thumb': 'assets/progress/clean/rec_thumb_cycling.png',
      'icon': 'assets/progress/clean/rec_icon_cycling.png',
      'desc': 'Melatih daya tahan kardiovaskular, memperkuat otot kaki dan membakar kalori.',
      'duration': '30-60 menit',
      'frequency': '3-5x/minggu',
      'calories': '200-400 kkal',
      'aboutTitle': 'Tentang Bersepeda',
      'aboutDesc':
          'Bersepeda merupakan salah satu bentuk aktivitas aerobik low-impact yang sangat ramah terhadap sendi lutut, sekaligus sangat efektif untuk melatih kebugaran kardiorespirasi dan membakar timbunan kalori.',
      'benefits': [
        'Meningkatkan kebugaran jantung dan paru tanpa membebani sendi',
        'Membantu pembakaran energi dan lemak tubuh',
        'Melatih kekuatan dan daya tahan otot paha dan betis',
        'Menyegarkan pikiran dengan menikmati pemandangan sekitar',
      ],
      'specs': {
        'duration': '30-60 menit',
        'frequency': '3-5 kali/minggu',
        'intensity': 'Sedang (50-70% HRmax)',
        'calories': '200-400 kkal',
      },
      'tipsTitle': 'Tips Melakukan Bersepeda',
      'tips': [
        'Pastikan sepeda dalam kondisi baik dan ketinggian sadel tepat.',
        'Gunakan perlengkapan keselamatan helm pelindung.',
        'Mulai dengan kayuhan santai lalu tingkatkan secara bertahap.',
        'Jaga postur punggung tetap ergonomis dan rileks.',
        'Pilih rute yang aman, bebas polusi, dan hindari jalanan padat.',
      ],
      'refLink': 'https://doi.org/10.21831/medikora.v14i2.7937',
    },
    {
      'id': 'yoga',
      'title': 'Yoga & Stretching',
      'name': 'Yoga / Stretching',
      'targetText': '20-40 menit',
      'heroImg': 'assets/progress/clean/hero_yoga.png',
      'thumbImg': 'assets/progress/clean/thumb_yoga.png',
      'thumb': 'assets/progress/clean/rec_thumb_yoga.png',
      'icon': 'assets/progress/clean/rec_icon_yoga.png',
      'desc': 'Meningkatkan fleksibilitas, mengurangi stres, dan memperbaiki postur tubuh.',
      'duration': '20-40 menit',
      'frequency': '3-5x/minggu',
      'calories': '100-200 kkal',
      'aboutTitle': 'Tentang Yoga & Peregangan',
      'aboutDesc':
          'Yoga dan stretching merupakan aktivitas fisik yang memadukan teknik pernapasan mendalam, kelenturan tubuh, dan relaksasi pikiran. Latihan ini membantu mengurangi ketegangan otot dan menurunkan hormon stres kortisol.',
      'benefits': [
        'Meningkatkan fleksibilitas sendi dan kelenturan otot',
        'Mendukung kestabilan hormon dan kesehatan mental',
        'Mengurangi hormon stres kortisol pemicu nafsu makan berlebih',
        'Memperbaiki kualitas tidur dan relaksasi malam hari',
      ],
      'specs': {
        'duration': '20-40 menit',
        'frequency': '3-5 kali/minggu',
        'intensity': 'Ringan-Sedang (40-60% HRmax)',
        'calories': '100-200 kkal',
      },
      'tipsTitle': 'Tips Melakukan Yoga',
      'tips': [
        'Lakukan gerakan secara perlahan dan fokus penuh pada pernapasan.',
        'Gunakan pakaian yang lentur, nyaman, dan menyerap keringat.',
        'Pilih ruangan yang tenang, sejuk, dan gunakan matras yoga.',
        'Jangan memaksakan peregangan melebihi batas kenyamanan tubuh.',
        'Tahan setiap pose selama 15-30 detik dengan napas teratur.',
      ],
      'refLink': 'https://doi.org/10.48144/jiks.v9i2.56',
    },
    {
      'id': 'hiit',
      'title': 'High-Intensity Interval Training (HIIT)',
      'name': 'Latihan HIIT (High Intensity)',
      'targetText': '15-30 menit',
      'heroImg': 'assets/progress/clean/hero_hiit.png',
      'thumbImg': 'assets/progress/clean/thumb_hiit.png',
      'thumb': 'assets/progress/clean/rec_thumb_hiit.png',
      'icon': 'assets/progress/clean/rec_icon_hiit.png',
      'desc': 'Membakar kalori intensif dalam waktu singkat dan meningkatkan kapasitas paru-paru.',
      'duration': '15-30 menit',
      'frequency': '2-3x/minggu',
      'calories': '250-450 kkal',
      'aboutTitle': 'Tentang Latihan HIIT',
      'aboutDesc':
          'High-Intensity Interval Training (HIIT) merupakan metode latihan yang menggabungkan interval gerakan intensif singkat dengan jeda pemulihan aktif secara bergantian. Sangat efisien bagi yang memiliki waktu terbatas.',
      'benefits': [
        'Membakar kalori tinggi dalam waktu yang sangat singkat',
        'Memicu efek Afterburn (EPOC) pembakaran kalori pasca latihan',
        'Meningkatkan kebugaran VO2max secara cepat',
        'Efektif menurunkan persentase lemak visceral perut',
      ],
      'specs': {
        'duration': '15-30 menit',
        'frequency': '2-3 kali/minggu',
        'intensity': 'Tinggi (80-90% HRmax)',
        'calories': '250-450 kkal',
      },
      'tipsTitle': 'Tips Melakukan HIIT',
      'tips': [
        'Wajib lakukan pemanasan komprehensif selama 5-10 menit.',
        'Kombinasikan 30 detik sprint/gerakan intens dengan 15-30 detik jalan santai.',
        'Prioritaskan bentuk gerakan yang aman sebelum menambah kecepatan.',
        'Batasi frekuensi maksimal 2-3 kali seminggu untuk memberi otot waktu pulih.',
        'Pastikan minum air sebelum, di sela, dan sesudah latihan.',
      ],
      'refLink': 'https://doi.org/10.15294/jpes.v8i2.31208',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = _todayOffset;
    _dateScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollController.hasClients) {
        // Scroll so today's pill is centered
        final scrollPosition = (_todayOffset * 64.0) - 120.0;
        _dateScrollController.animateTo(
          scrollPosition.clamp(0.0, _dateScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  void _openDetail(Map<String, dynamic> act) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activity: act),
      ),
    );
  }

  // Interactive Save Confirmation Modal (Matches HTML #progress-confirm-modal)
  void _confirmToggleActivity(Map<String, dynamic> act) {
    final actId = act['id'] as String;
    final actName = act['name'] as String;
    final isAlreadyCompleted = _completedActivities.contains(actId);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Circle with Clipboard & Question Mark Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2F1E8),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 36,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Modal Title
              Text(
                'Simpan Perubahan?',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // Modal Description
              Text(
                isAlreadyCompleted
                    ? 'Tandai aktivitas "$actName" sebagai belum selesai hari ini?'
                    : 'Perubahan yang kamu lakukan akan disimpan sebagai progress hari ini.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),

              // Action Buttons [BATAL] [YA]
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'BATAL',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF36785A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          if (isAlreadyCompleted) {
                            _completedActivities.remove(actId);
                          } else {
                            _completedActivities.add(actId);
                          }
                        });

                        // Toast Notification
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAlreadyCompleted
                                  ? 'Status $actName diperbarui (belum selesai)'
                                  : 'Aktivitas Disimpan: Sesi $actName berhasil diselesaikan!',
                              style: GoogleFonts.poppins(fontSize: 12.5),
                            ),
                            backgroundColor: const Color(0xFF2E6B4F),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        'YA',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36785A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Rekomendasi Aktivitas Fisik',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Horizontal Real-Time Date Scroller (21 days: -7 to +13)
            SizedBox(
              height: 74,
              child: ListView.builder(
                controller: _dateScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: 21,
                itemBuilder: (context, index) {
                  final offset = index - _todayOffset;
                  final date = now.add(Duration(days: offset));
                  final isSelected = _selectedDayIndex == index;
                  final isPast = offset < 0;
                  final isToday = offset == 0;

                  final dayName = isToday ? 'Hari ini' : dayNames[date.weekday % 7];
                  final dateStr = '${date.day}/${date.month}/${date.year.toString().substring(2)}';

                  Color bgColor;
                  Color textColor;
                  Color subTextColor;
                  Border border;

                  if (isSelected) {
                    bgColor = const Color(0xFF36785A);
                    textColor = Colors.white;
                    subTextColor = Colors.white.withValues(alpha: 0.9);
                    border = Border.all(color: const Color(0xFF36785A), width: 1.5);
                  } else if (isPast) {
                    // Past Days -> Merah, Teks Putih (sesuai spesifikasi main.js pill-past-red)
                    bgColor = const Color(0xFFEF4444);
                    textColor = Colors.white;
                    subTextColor = Colors.white.withValues(alpha: 0.85);
                    border = Border.all(color: const Color(0xFFDC2626));
                  } else if (isToday) {
                    // Today -> Hijau Pastel
                    bgColor = const Color(0xFFD1FAE5);
                    textColor = const Color(0xFF065F46);
                    subTextColor = const Color(0xFF047857);
                    border = Border.all(color: const Color(0xFF10B981), width: 1.5);
                  } else {
                    // Future Days -> Putih dengan Border Tipis Abu-abu
                    bgColor = Colors.white;
                    textColor = const Color(0xFF0F172A);
                    subTextColor = const Color(0xFF64748B);
                    border = Border.all(color: const Color(0xFFE2E8F0));
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDayIndex = index;
                      });
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
                                  color: const Color(0xFF36785A).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
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

            const SizedBox(height: 20),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pilihan Aktivitas Olahraga',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F1E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_completedActivities.length}/5 Selesai',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E6B4F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5 Activity Cards with Interactive Checklist & 3 Pills
            ..._activities.map((act) => _buildActivityCard(act)),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> act) {
    final actId = act['id'] as String;
    final isCompleted = _completedActivities.contains(actId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isCompleted ? const Color(0xFF36785A) : const Color(0xFFE2E8F0),
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetail(act),
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
                          color: const Color(0xFFE2F1E8),
                          child: const Icon(Icons.directions_run_rounded, color: Color(0xFF36785A), size: 36),
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
                                color: const Color(0xFF0F172A),
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
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 3 Pills: Duration, Frequency, Calories
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildPill(Icons.access_time_rounded, act['duration'] as String),
                          _buildPill(Icons.calendar_today_rounded, act['frequency'] as String),
                          _buildPill(Icons.local_fire_department_rounded, act['calories'] as String),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Interactive Checklist Toggle Button
                IconButton(
                  icon: Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isCompleted ? const Color(0xFF36785A) : const Color(0xFFCBD5E1),
                    size: 26,
                  ),
                  tooltip: isCompleted ? 'Batalkan status selesai' : 'Tandai selesai',
                  onPressed: () => _confirmToggleActivity(act),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: const Color(0xFF475569)),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}
