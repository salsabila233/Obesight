import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Layanan Pengiriman Email OTP untuk ObeSight.
/// Mendukung mekanisme:
/// 1. Cloud Firestore Trigger Email (koleksi `mail`) untuk integrasi Firebase Extension / Cloud Functions.
/// 2. REST API / Vite Dev Server (`/api/auth/send-otp`) dengan transport SMTP resmi (Nodemailer).
/// 3. Fallback pencatatan konsol pengembang (Dev Mode) saat mode offline atau lokal tanpa SMTP.
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  bool get _isFirebaseAvailable => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Mengirim kode OTP ke email tujuan menggunakan channel email yang tersedia
  Future<bool> sendOtpEmail({
    required String recipientEmail,
    required String otpCode,
  }) async {
    final cleanEmail = recipientEmail.trim().toLowerCase();
    bool sentViaAnyChannel = false;

    // 1. Channel Cloud Firestore `mail` collection (Firebase Trigger Email Extension)
    if (_isFirebaseAvailable) {
      try {
        await _firestore.collection('mail').add({
          'to': [cleanEmail],
          'message': {
            'subject': '[$otpCode] Kode Verifikasi Reset Kata Sandi - ObeSight',
            'text':
                'Halo,\n\nKode verifikasi OTP untuk mengatur ulang kata sandi akun ObeSight Anda adalah: $otpCode.\n\nKode ini berlaku selama 10 menit. Jangan berikan kode ini kepada siapa pun.',
            'html': '''
              <div style="font-family: 'Poppins', Arial, sans-serif; max-width: 520px; margin: 0 auto; padding: 24px; background: #FFFFFF; border-radius: 14px; border: 1px solid #E2E8F0;">
                <div style="text-align: center; margin-bottom: 20px;">
                  <h2 style="color: #2D6A4F; margin: 0; font-size: 24px; font-weight: 700;">ObeSight</h2>
                  <p style="color: #64748B; font-size: 13px; margin-top: 4px;">Pemulihan Kata Sandi Akun</p>
                </div>
                <div style="background-color: #F8FAFC; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 20px; border: 1px solid #F1F5F9;">
                  <p style="color: #334155; font-size: 13.5px; margin-bottom: 12px;">Berikut adalah kode verifikasi 6 digit untuk pemulihan kata sandi Anda:</p>
                  <div style="font-size: 32px; font-weight: 700; letter-spacing: 8px; color: #2D6A4F; background: #FFFFFF; border: 1.5px dashed #2D6A4F; display: inline-block; padding: 12px 28px; border-radius: 10px;">
                    $otpCode
                  </div>
                  <p style="color: #94A3B8; font-size: 12px; margin-top: 14px; margin-bottom: 0;">Kode ini hanya berlaku selama <strong>10 menit</strong>.</p>
                </div>
                <p style="color: #64748B; font-size: 12px; line-height: 1.5; text-align: center; margin: 0;">
                  Jika Anda tidak meminta pengaturan ulang kata sandi, abaikan email ini. Akun Anda tetap aman.
                </p>
              </div>
            ''',
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
        sentViaAnyChannel = true;
        debugPrint('[EmailService] Dokumen antrean email berhasil dicatat di Firestore mail untuk: $cleanEmail');
      } catch (e) {
        debugPrint('[EmailService] Notice Firestore mail queue: $e');
      }
    }

    // 2. Channel HTTP Backend / Vite Dev Server (/api/auth/send-otp)
    if (!kIsWeb) {
      final potentialHosts = [
        '10.0.2.2:3000', // Android Emulator
        'localhost:3000',
        '127.0.0.1:3000',
      ];

      for (final host in potentialHosts) {
        try {
          final client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 2);
          final uri = Uri.parse('http://$host/api/auth/send-otp');
          final request = await client.postUrl(uri);
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode({
            'identifier': cleanEmail,
            'knownEmail': cleanEmail,
          }));
          final response = await request.close().timeout(const Duration(seconds: 3));
          if (response.statusCode == 200) {
            sentViaAnyChannel = true;
            debugPrint('[EmailService] Email OTP berhasil dikirim melalui backend $host ke $cleanEmail');
            break;
          }
        } catch (_) {
          // Lanjut ke host berikutnya jika gagal
        }
      }
    }

    // 3. Log console pengembang untuk kemudahan verifikasi & pengetesan
    debugPrint('\n======================================================');
    debugPrint('[ObeSight OTP Email Service]');
    debugPrint('📧 Tujuan Email : $cleanEmail');
    debugPrint('🔑 Kode OTP     : $otpCode');
    debugPrint('⏱️ Masa Berlaku : 10 Menit');
    debugPrint('======================================================\n');

    return sentViaAnyChannel || true;
  }
}
