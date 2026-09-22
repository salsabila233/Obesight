import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityTimerScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const ActivityTimerScreen({super.key, required this.activity});

  @override
  State<ActivityTimerScreen> createState() => _ActivityTimerScreenState();
}

class _ActivityTimerScreenState extends State<ActivityTimerScreen> {
  Timer? _timer;
  int _selectedMinutes = 30;
  late int _remainingSeconds;
  bool _isRunning = false;

  late FixedExtentScrollController _wheelController;
  double _dragAccumulator = 0;
  bool _isSyncingFromCircle = false;

  final int _minMinutes = 1;
  final int _maxMinutes = 90;

  @override
  void initState() {
    super.initState();
    // Default 20 for HIIT, 30 for others
    final id = widget.activity['id'] as String? ?? '';
    _selectedMinutes = (id == 'hiit') ? 20 : 30;
    _remainingSeconds = _selectedMinutes * 60;
    _wheelController = FixedExtentScrollController(initialItem: _selectedMinutes - _minMinutes);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wheelController.dispose();
    super.dispose();
  }

  void _setMinutes(int minutes, {bool syncWheel = true}) {
    final clamped = minutes.clamp(_minMinutes, _maxMinutes);
    if (_selectedMinutes == clamped && _remainingSeconds == clamped * 60) return;

    setState(() {
      _selectedMinutes = clamped;
      if (!_isRunning) {
        _remainingSeconds = _selectedMinutes * 60;
      }
    });

    if (syncWheel && _wheelController.hasClients) {
      final targetIndex = clamped - _minMinutes;
      if (_wheelController.selectedItem != targetIndex) {
        _isSyncingFromCircle = true;
        _wheelController.animateToItem(
          targetIndex,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        ).then((_) => _isSyncingFromCircle = false);
      }
    }
  }

  void _handleCircleDragUpdate(DragUpdateDetails details) {
    if (_isRunning) return;

    // Negated: dragging up increases duration, dragging down decreases
    _dragAccumulator -= (details.primaryDelta ?? 0.0);
    const double threshold = 14.0; // pixels per 1 minute change

    if (_dragAccumulator.abs() >= threshold) {
      final steps = (_dragAccumulator / threshold).truncate();
      _dragAccumulator -= steps * threshold;
      final newMinutes = _selectedMinutes + steps;
      _setMinutes(newMinutes, syncWheel: true);
    }
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (_remainingSeconds <= 0) {
        _remainingSeconds = _selectedMinutes * 60;
      }
      setState(() => _isRunning = true);

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
          _showCompletionDialog();
        }
      });
    }
  }

  void _finishEarly() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    _showCompletionDialog();
  }

  void _cancelTimer() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  void _showCompletionDialog() {
    final title = widget.activity['title'] as String? ?? 'Aktivitas';
    final calories = (widget.activity['specs'] as Map<String, dynamic>?)?['calories'] ?? '200-400 kkal';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF16A34A), size: 40),
            ),
            const SizedBox(height: 14),
            Text(
              'Latihan Selesai! 🎉',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Luar biasa! Kamu telah menyelesaikan sesi $title hari ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEA580C), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Estimasi kalori: $calories',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36785A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
              child: Text('Simpan & Selesai', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMMSS(int totalSeconds) {
    final safeSec = totalSeconds < 0 ? 0 : totalSeconds;
    final m = safeSec ~/ 60;
    final s = safeSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.activity['title'] as String? ?? 'Jogging';
    final heroImg = widget.activity['heroImg'] as String? ?? 'assets/progress/clean/hero_jogging.png';
    final iconImg = widget.activity['icon'] as String? ?? 'assets/progress/clean/rec_icon_jogging.png';
    final targetText = widget.activity['targetText'] as String? ?? '30-60 menit';

    final totalSec = _selectedMinutes * 60;
    final double progressFraction = totalSec > 0 ? (_remainingSeconds / totalSec).clamp(0.0, 1.0) : 0.0;

    // 3 Stacked Numbers inside the Big Circle
    final String centerText = _isRunning
        ? _formatMMSS(_remainingSeconds)
        : _formatMMSS(_selectedMinutes * 60);

    final String topText = _isRunning
        ? '59:59'
        : _formatMMSS(((_selectedMinutes > _minMinutes ? _selectedMinutes - 1 : _maxMinutes) * 60));

    final String bottomText = _isRunning
        ? '00:00'
        : _formatMMSS(((_selectedMinutes < _maxMinutes ? _selectedMinutes + 1 : _minMinutes) * 60));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // 1. Hero Header Banner (Posisi Awal dengan Overlay Icon + Title)
            Stack(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  color: const Color(0xFF2D6A4F),
                  child: Image.asset(
                    heroImg,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF2D6A4F),
                      child: const Icon(Icons.fitness_center_rounded, size: 72, color: Colors.white),
                    ),
                  ),
                ),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Back Button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                // Bottom-left Icon + Name Overlay
                Positioned(
                  bottom: 18,
                  left: 20,
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF36785A).withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: Image.asset(
                          iconImg,
                          color: Colors.white,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.directions_run_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 2. White Rounded Container (Target, Lingkaran Timer, Mini Picker, Presets, Controls)
            Container(
              transform: Matrix4.translationValues(0, -20, 0),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Target Header
                  Text(
                    'Target',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF36785A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    targetText,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 3.1 Lingkaran Besar Timer (GestureDetector Drag Scroll Manual Bebas)
                  GestureDetector(
                    onVerticalDragUpdate: _handleCircleDragUpdate,
                    child: Container(
                      width: 236,
                      height: 236,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF36785A).withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background Ring Track
                          SizedBox(
                            width: 224,
                            height: 224,
                            child: CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 14,
                              color: const Color(0xFFD1EBE1),
                            ),
                          ),
                          // Active Progress Indicator Ring
                          SizedBox(
                            width: 224,
                            height: 224,
                            child: CircularProgressIndicator(
                              value: progressFraction,
                              strokeWidth: 14,
                              color: const Color(0xFF529A7B),
                              strokeCap: StrokeCap.round,
                            ),
                          ),

                          // 3 Stacked Numbers inside circle
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Baris Atas (Pudar)
                              Text(
                                topText,
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFCBD5E1),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Baris Tengah (Aktif, Tebal & Jelas)
                              Text(
                                centerText,
                                style: GoogleFonts.poppins(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E293B),
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Baris Bawah (Pudar)
                              Text(
                                bottomText,
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFCBD5E1),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Hint geser manual
                  if (!_isRunning)
                    Text(
                      'Geser ke atas/bawah pada lingkaran untuk durasi bebas',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 18),

                  // 3.2 Opsi Cepat: Mini Scroll-Picker "Pilih Durasi Waktu" (Sinkron 2-Arah)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pilih Durasi Waktu:',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Mini Wheel Picker
                        Container(
                          width: 86,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Highlight center band
                              Container(
                                height: 26,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF36785A).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              ListWheelScrollView.useDelegate(
                                controller: _wheelController,
                                itemExtent: 26,
                                perspective: 0.003,
                                diameterRatio: 1.2,
                                physics: _isRunning
                                    ? const NeverScrollableScrollPhysics()
                                    : const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (index) {
                                  if (_isSyncingFromCircle || _isRunning) return;
                                  final m = index + _minMinutes;
                                  setState(() {
                                    _selectedMinutes = m;
                                    _remainingSeconds = m * 60;
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: _maxMinutes - _minMinutes + 1,
                                  builder: (context, index) {
                                    final m = index + _minMinutes;
                                    final isSelected = m == _selectedMinutes;
                                    return Center(
                                      child: Text(
                                        '$m mnt',
                                        style: GoogleFonts.poppins(
                                          fontSize: isSelected ? 13 : 11,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF36785A) : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3 Tombol Preset Cepat (30:00, 45:00, 60:00) Sesuai Referensi Gambar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPresetCircle(30),
                      const SizedBox(width: 18),
                      _buildPresetCircle(45),
                      const SizedBox(width: 18),
                      _buildPresetCircle(60),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tombol Play / Pause (Lingkaran Hijau dengan Ikon)
                  GestureDetector(
                    onTap: _toggleTimer,
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF529A7B), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF529A7B).withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 38,
                          color: const Color(0xFF529A7B),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Tombol Selesaikan Aktivitas
                  SizedBox(
                    width: 250,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF529A7B),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: const Color(0xFF529A7B).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: _finishEarly,
                      child: Text(
                        'Selesaikan Aktivitas',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tombol Batal
                  TextButton(
                    onPressed: _cancelTimer,
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF529A7B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCircle(int minutes) {
    final isSelected = _selectedMinutes == minutes;
    return GestureDetector(
      onTap: _isRunning ? null : () => _setMinutes(minutes, syncWheel: true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? const Color(0xFFE2F1E8) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF529A7B) : const Color(0xFFCBD5E1),
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '${minutes.toString().padLeft(2, '0')}:00',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? const Color(0xFF2E6B4F) : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
