import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  int _cooldownSeconds = 60;
  Timer? _cooldownTimer;
  String _email = 'zahraalfitiarisa@gmail.com';

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['email'] is String) {
      _email = args['email'];
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownSeconds = 60;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleResendCode() {
    if (_cooldownSeconds > 0) return;
    _startCooldown();
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Kode verifikasi baru telah dikirimkan ke $_email',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF4F9B77),
      ),
    );
  }

  Future<void> _handleVerify() async {
    setState(() {
      _errorMessage = null;
    });

    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() {
        _errorMessage = 'Masukkan lengkap 6 digit kode verifikasi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate backend verification
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    // Navigate to Reset Password Screen
    Navigator.of(context).pushNamed(
      '/reset-password',
      arguments: {'email': _email},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Logo & Brand Name Centered
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 66,
                        height: 66,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ObeSight',
                        style: GoogleFonts.poppins(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2C6348),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Verifikasi Kode',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF234C37),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF4A5568),
                            height: 1.45,
                          ),
                          children: [
                            const TextSpan(text: 'Kode verifikasi telah dikirim ke email\n'),
                            TextSpan(
                              text: '$_email.\n',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const TextSpan(text: 'Masukkan kode 6 digit di bawah ini.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 6-Digit OTP Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isFilled = _controllers[index].text.isNotEmpty;
                    return Container(
                      width: 46,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                        decoration: InputDecoration(
                          hintText: '-',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor: isFilled ? const Color(0xFFF0FDF4) : Colors.white,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isFilled ? const Color(0xFF4F9B77) : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isFilled ? const Color(0xFF4F9B77) : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4F9B77),
                              width: 1.8,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            if (index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else {
                              _focusNodes[index].unfocus();
                            }
                          } else {
                            if (index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          }
                          setState(() {});
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                // Resend code link & timer
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _cooldownSeconds == 0 ? _handleResendCode : null,
                        child: Row(
                          children: [
                            Text(
                              'Kirim ulang kode ',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _cooldownSeconds == 0
                                    ? const Color(0xFF4F9B77)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                            Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: _cooldownSeconds == 0
                                  ? const Color(0xFF4F9B77)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                      if (_cooldownSeconds > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${_cooldownSeconds}s)',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Button: Verifikasi
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F9B77),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Verifikasi',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                // Link: Kembali ke Login
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    child: Text(
                      'Kembali ke Login',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4F9B77),
                      ),
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
}
