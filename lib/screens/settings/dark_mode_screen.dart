import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DarkModeScreen extends StatefulWidget {
  final bool initialDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  const DarkModeScreen({
    super.key,
    this.initialDarkMode = false,
    this.onThemeChanged,
  });

  @override
  State<DarkModeScreen> createState() => _DarkModeScreenState();
}

class _DarkModeScreenState extends State<DarkModeScreen> {
  late int _selectedOption; // 0 = Light, 1 = Dark, 2 = System

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialDarkMode ? 1 : 0;
  }

  void _selectOption(int index) {
    setState(() {
      _selectedOption = index;
    });
    final isDark = index == 1;
    widget.onThemeChanged?.call(isDark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF489874),
      appBar: AppBar(
        backgroundColor: const Color(0xFF489874),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context, _selectedOption == 1),
        ),
        title: Text(
          'Mode Gelap',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF4F8F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preferensi Tampilan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih tampilan visual yang paling nyaman untuk mata Anda saat menggunakan aplikasi.',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Visual Preview Comparison
              Row(
                children: [
                  Expanded(
                    child: _buildThemePreviewCard(
                      title: 'Mode Terang',
                      isSelected: _selectedOption == 0,
                      isDarkPreview: false,
                      onTap: () => _selectOption(0),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildThemePreviewCard(
                      title: 'Mode Gelap',
                      isSelected: _selectedOption == 1,
                      isDarkPreview: true,
                      onTap: () => _selectOption(1),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Settings Options List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEAEFEA)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildOptionTile(
                      index: 0,
                      title: 'Terang',
                      subtitle: 'Warna cerah yang bersih dan jernih di siang hari',
                      icon: Icons.light_mode_rounded,
                      iconColor: const Color(0xFFEAB308),
                    ),
                    const Divider(height: 1, indent: 60, endIndent: 20, color: Color(0xFFF1F5F9)),
                    _buildOptionTile(
                      index: 1,
                      title: 'Gelap',
                      subtitle: 'Lebih teduh dan menghemat daya baterai perangkat',
                      icon: Icons.dark_mode_rounded,
                      iconColor: const Color(0xFF6366F1),
                    ),
                    const Divider(height: 1, indent: 60, endIndent: 20, color: Color(0xFFF1F5F9)),
                    _buildOptionTile(
                      index: 2,
                      title: 'Mengikuti Sistem',
                      subtitle: 'Secara otomatis mengikuti pengaturan tema di HP Anda',
                      icon: Icons.settings_brightness_rounded,
                      iconColor: const Color(0xFF36785A),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF36785A).withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF36785A), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pilihan tema Anda disimpan secara lokal dan akan otomatis diterapkan setiap kali aplikasi ObeSight dibuka.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF1E4534),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemePreviewCard({
    required String title,
    required bool isSelected,
    required bool isDarkPreview,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF36785A) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF36785A).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Mini screen frame preview
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkPreview ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkPreview ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App bar mockup
                  Container(
                    height: 18,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF36785A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Content pill 1
                  Container(
                    height: 12,
                    width: 70,
                    decoration: BoxDecoration(
                      color: isDarkPreview ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Content box
                  Container(
                    height: 38,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDarkPreview ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkPreview ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected ? const Color(0xFF36785A) : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedOption == index;
    return InkWell(
      onTap: () => _selectOption(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF36785A) : const Color(0xFF94A3B8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
