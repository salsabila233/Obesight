import { defineConfig } from 'vite';
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';

// Load .env if present
function loadEnv() {
  const envPath = path.resolve(process.cwd(), '.env');
  if (fs.existsSync(envPath)) {
    const content = fs.readFileSync(envPath, 'utf8');
    content.split('\n').forEach(line => {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const idx = trimmed.indexOf('=');
        if (idx !== -1) {
          const key = trimmed.slice(0, idx).trim();
          let val = trimmed.slice(idx + 1).trim();
          if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
            val = val.slice(1, -1);
          }
          process.env[key] = val;
        }
      }
    });
  }
}
loadEnv();

// In-Memory Secure OTP & Reset Token Store
const otpStore = new Map(); // email -> { otp, expiresAt, attempts }
const resetTokenStore = new Map(); // resetToken -> { email, expiresAt }

// Preset mock accounts
const presetUsers = [
  { email: 'zahraafitriana@gmail.com', username: 'zahraafitriana', name: 'Zahra Fitriana' },
  { email: 'zahrafitrie@gmail.com', username: 'zahrafitrie', name: 'Zahra Fitrie' },
  { email: 'zahraalfitiarisa@gmail.com', username: 'zahraalfitiarisa', name: 'Zahra Alfitiarisa' },
  { email: 'admin@obesight.com', username: 'admin', name: 'Administrator' }
];

async function sendEmailOtp(email, otp) {
  const smtpUser = process.env.SMTP_USER;
  const smtpPass = process.env.SMTP_PASS;
  const smtpHost = process.env.SMTP_HOST || 'smtp.gmail.com';
  const smtpPort = parseInt(process.env.SMTP_PORT || '465', 10);
  const smtpSecure = process.env.SMTP_SECURE !== 'false';
  const smtpFrom = process.env.SMTP_FROM || `"ObeSight Official" <${smtpUser || 'no-reply@obesight.com'}>`;

  if (smtpUser && smtpPass && smtpUser !== 'emailanda@gmail.com') {
    try {
      const nodemailer = await import('nodemailer');
      const transporter = nodemailer.createTransport({
        host: smtpHost,
        port: smtpPort,
        secure: smtpSecure,
        auth: {
          user: smtpUser,
          pass: smtpPass
        }
      });

      const htmlContent = `
        <div style="font-family: 'Poppins', Arial, sans-serif; max-width: 520px; margin: 0 auto; padding: 28px; background: #FFFFFF; border-radius: 16px; border: 1px solid #E2E8F0; box-shadow: 0 4px 20px rgba(0,0,0,0.05);">
          <div style="text-align: center; margin-bottom: 24px;">
            <h2 style="color: #234C37; margin: 8px 0 0 0; font-size: 24px; font-weight: 700;">ObeSight</h2>
            <p style="color: #4A5568; font-size: 14px; margin-top: 4px;">Sistem Pemulihan Akun</p>
          </div>
          <div style="background-color: #F8FAF9; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 24px;">
            <p style="color: #4A5568; font-size: 14px; margin-bottom: 12px;">Berikut adalah kode verifikasi 6-digit untuk memulihkan kata sandi akun Anda:</p>
            <div style="font-size: 32px; font-weight: 700; letter-spacing: 8px; color: #4F9B77; background: #FFFFFF; border: 1px dashed #4F9B77; display: inline-block; padding: 12px 28px; border-radius: 10px;">
              ${otp}
            </div>
            <p style="color: #9CA3AF; font-size: 12px; margin-top: 14px; margin-bottom: 0;">Kode ini hanya berlaku selama <strong>5 menit</strong>. Jangan berikan kode ini kepada siapa pun.</p>
          </div>
          <p style="color: #718096; font-size: 12px; line-height: 1.5; text-align: center; margin: 0;">
            Jika Anda tidak meminta pengaturan ulang kata sandi, abaikan email ini. Akun Anda tetap aman.
          </p>
        </div>
      `;

      await transporter.sendMail({
        from: smtpFrom,
        to: email,
        subject: `[ObeSight] ${otp} adalah Kode Verifikasi Pemulihan Sandi Anda`,
        text: `Kode verifikasi pemulihan kata sandi ObeSight Anda adalah: ${otp}. Kode ini berlaku selama 5 menit.`,
        html: htmlContent
      });

      console.log(`[ObeSight Email] Kode OTP ${otp} berhasil dikirim via SMTP ke ${email}`);
      return { sent: true, mode: 'smtp' };
    } catch (err) {
      console.error('[ObeSight Email Error] Gagal mengirim via SMTP:', err.message);
      return { sent: false, mode: 'smtp_failed', error: err.message };
    }
  } else {
    console.log(`\n======================================================`);
    console.log(`[ObeSight Auth - DEV MODE] Email Pengiriman OTP`);
    console.log(`📧 Kepada     : ${email}`);
    console.log(`🔑 Kode OTP   : ${otp}`);
    console.log(`⏱️ Masa Berlaku: 5 Menit`);
    console.log(`💡 Info       : Konfigurasikan SMTP di file .env untuk pengiriman nyata.`);
    console.log(`======================================================\n`);
    return { sent: true, mode: 'dev_mode' };
  }
}

// Plugin API Auth Middleware
function authOtpApiPlugin() {
  return {
    name: 'obesight-auth-otp-api',
    configureServer(server) {
      server.middlewares.use(async (req, res, next) => {
        if (!req.url.startsWith('/api/auth/')) {
          return next();
        }

        const parseBody = () => new Promise((resolve) => {
          let body = '';
          req.on('data', chunk => { body += chunk; });
          req.on('end', () => {
            try {
              resolve(body ? JSON.parse(body) : {});
            } catch (e) {
              resolve({});
            }
          });
        });

        const sendJson = (status, data) => {
          res.writeHead(status, {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          });
          res.end(JSON.stringify(data));
        };

        // 1. POST /api/auth/send-otp
        if (req.method === 'POST' && req.url === '/api/auth/send-otp') {
          const body = await parseBody();
          const identifier = (body.identifier || '').trim().toLowerCase();

          if (!identifier) {
            return sendJson(400, { success: false, message: 'Nama pengguna atau email wajib diisi.' });
          }

          // Determine target email
          let targetEmail = identifier;
          let matched = presetUsers.find(u => u.email.toLowerCase() === identifier || u.username.toLowerCase() === identifier);
          
          if (matched) {
            targetEmail = matched.email;
          } else if (identifier.includes('@')) {
            targetEmail = identifier;
          } else {
            if (body.knownEmail) {
              targetEmail = body.knownEmail.toLowerCase();
            }
          }

          // Basic email format validation
          const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
          if (!emailRegex.test(targetEmail)) {
            return sendJson(400, { success: false, message: 'Format email tidak valid.' });
          }

          // Generate 6 digit OTP
          const otp = Math.floor(100000 + Math.random() * 900000).toString();
          const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes

          otpStore.set(targetEmail, {
            otp,
            expiresAt,
            attempts: 0
          });

          // Send email or log to console
          const emailResult = await sendEmailOtp(targetEmail, otp);

          return sendJson(200, {
            success: true,
            email: targetEmail,
            message: `Kode verifikasi telah dikirim ke email ${targetEmail}.`,
            mode: emailResult.mode,
            devOtp: emailResult.mode === 'dev_mode' ? otp : undefined
          });
        }

        // 2. POST /api/auth/verify-otp
        if (req.method === 'POST' && req.url === '/api/auth/verify-otp') {
          const body = await parseBody();
          const email = (body.email || '').trim().toLowerCase();
          const otp = (body.otp || '').trim();

          if (!email || !otp) {
            return sendJson(400, { success: false, message: 'Email dan kode OTP wajib diisi.' });
          }

          const record = otpStore.get(email);
          if (!record) {
            return sendJson(400, { success: false, message: 'Kode verifikasi belum dikirim atau telah kedaluwarsa.' });
          }

          if (Date.now() > record.expiresAt) {
            otpStore.delete(email);
            return sendJson(400, { success: false, message: 'Kode verifikasi telah kedaluwarsa (lebih dari 5 menit). Silakan kirim ulang.' });
          }

          record.attempts += 1;
          if (record.attempts > 5) {
            otpStore.delete(email);
            return sendJson(429, { success: false, message: 'Terlalu banyak percobaan salah. Silakan minta kode baru.' });
          }

          if (record.otp !== otp) {
            return sendJson(400, { success: false, message: 'Kode verifikasi 6 digit yang Anda masukkan salah.' });
          }

          // OTP Valid: consume OTP so it cannot be reused
          otpStore.delete(email);

          // Generate temporary reset token valid for 10 minutes
          const resetToken = crypto.randomBytes(24).toString('hex');
          resetTokenStore.set(resetToken, {
            email,
            expiresAt: Date.now() + 10 * 60 * 1000
          });

          return sendJson(200, {
            success: true,
            resetToken,
            message: 'Kode verifikasi berhasil diverifikasi.'
          });
        }

        // 3. POST /api/auth/reset-password
        if (req.method === 'POST' && req.url === '/api/auth/reset-password') {
          const body = await parseBody();
          const resetToken = (body.resetToken || '').trim();
          const newPassword = body.newPassword || '';

          if (!resetToken) {
            return sendJson(400, { success: false, message: 'Token reset kata sandi tidak valid atau sesi telah berakhir.' });
          }

          const tokenRecord = resetTokenStore.get(resetToken);
          if (!tokenRecord || Date.now() > tokenRecord.expiresAt) {
            resetTokenStore.delete(resetToken);
            return sendJson(400, { success: false, message: 'Sesi pembuatan kata sandi telah kedaluwarsa. Silakan ulangi alur dari awal.' });
          }

          // Validate password criteria
          const isLenValid = newPassword.length >= 8;
          const isDigitValid = /\d/.test(newPassword);
          const isCaseValid = /[a-z]/.test(newPassword) && /[A-Z]/.test(newPassword);

          if (!isLenValid || !isDigitValid || !isCaseValid) {
            return sendJson(400, {
              success: false,
              message: 'Kata sandi harus minimal 8 karakter, mengandung huruf besar dan kecil, serta angka.'
            });
          }

          // Hash password with SHA-256
          const hashedPassword = crypto.createHash('sha256').update(newPassword).digest('hex');

          // Consume reset token
          const userEmail = tokenRecord.email;
          resetTokenStore.delete(resetToken);

          console.log(`[ObeSight Auth] Kata sandi akun ${userEmail} berhasil direset (Hash: ${hashedPassword.slice(0, 10)}...).`);

          return sendJson(200, {
            success: true,
            email: userEmail,
            hashedPassword,
            message: 'Kata sandi baru berhasil disimpan! Silakan masuk dengan kata sandi baru Anda.'
          });
        }

        // 4. GET & POST /api/auth/google-config
        if (req.url === '/api/auth/google-config') {
          if (req.method === 'GET') {
            loadEnv();
            const clientId = process.env.VITE_GOOGLE_CLIENT_ID || process.env.GOOGLE_CLIENT_ID || '';
            return sendJson(200, { success: true, clientId });
          }
          if (req.method === 'POST') {
            const body = await parseBody();
            const clientId = (body.clientId || '').trim();
            process.env.VITE_GOOGLE_CLIENT_ID = clientId;
            // Update or write to .env
            const envPath = path.resolve(process.cwd(), '.env');
            let content = fs.existsSync(envPath) ? fs.readFileSync(envPath, 'utf8') : '';
            if (content.includes('VITE_GOOGLE_CLIENT_ID=')) {
              content = content.replace(/VITE_GOOGLE_CLIENT_ID=.*/g, `VITE_GOOGLE_CLIENT_ID=${clientId}`);
            } else {
              content += `\nVITE_GOOGLE_CLIENT_ID=${clientId}\n`;
            }
            fs.writeFileSync(envPath, content, 'utf8');
            console.log(`[ObeSight Auth] Google Client ID berhasil diperbarui: ${clientId}`);
            return sendJson(200, { success: true, clientId, message: 'Google Client ID berhasil disimpan!' });
          }
        }

        next();
      });
    }
  };
}

export default defineConfig({
  server: {
    host: true,
    port: 3000
  },
  plugins: [authOtpApiPlugin()]
});
