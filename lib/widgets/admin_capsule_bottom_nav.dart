import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Komponen navigasi bawah berbentuk kapsul hijau khas Admin ObeSight.
/// Komponen ini digunakan secara konsisten di Beranda Admin, Halaman Pengguna Admin,
/// dan sub-halaman admin lainnya sehingga memiliki bentuk, warna, ukuran, ikon,
/// jarak, dan perilaku navigasi yang 100% seragam.
class AdminCapsuleBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AdminCapsuleBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color activeColor = Color(0xFF388E6B);
  static const Color capsuleBg = Color(0xFF246B4D);

  static const List<Map<String, dynamic>> navItems = [
    {
      'icon': Icons.home_rounded,
      'inactiveIcon': Icons.home_outlined,
      'label': 'Beranda',
    },
    {
      'icon': Icons.people_alt_rounded,
      'inactiveIcon': Icons.people_alt_outlined,
      'label': 'Pengguna',
    },
    {
      'icon': Icons.article_rounded,
      'inactiveIcon': Icons.article_outlined,
      'label': 'Artikel',
    },
    {
      'icon': Icons.bar_chart_rounded,
      'inactiveIcon': Icons.bar_chart_outlined,
      'label': 'Laporan',
    },
    {
      'icon': Icons.settings_rounded,
      'inactiveIcon': Icons.settings_outlined,
      'label': 'Pengaturan',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: capsuleBg,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: capsuleBg.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final isSelected = currentIndex == index;
            final item = navItems[index];
            final icon =
                (isSelected ? item['icon'] : item['inactiveIcon']) as IconData;
            final label = item['label'] as String;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
