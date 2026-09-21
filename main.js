/**
 * OBESIGHT - SPLASH SCREEN & AUTHENTICATION CONTROLLER
 * Connects the multi-stage animated splash to the Figma Login Screen
 * Supports multi-role dashboards (User vs Admin), animated illustration, and Google account picker
 */

document.addEventListener('DOMContentLoaded', () => {
  // Navigation & Screens
  const splashScreen = document.getElementById('splash-screen');
  const authScreen = document.getElementById('auth-screen');
  const registerScreen = document.getElementById('register-screen');
  const forgotEmailScreen = document.getElementById('forgot-email-screen');
  const forgotOtpScreen = document.getElementById('forgot-otp-screen');
  const forgotResetScreen = document.getElementById('forgot-reset-screen');
  const userDash = document.getElementById('user-dashboard-screen');
  const adminDash = document.getElementById('admin-dashboard-screen');
  const statusBar = document.getElementById('phone-status-bar');

  // Controls & Toolbar
  const btnSkipSplash = document.getElementById('btn-skip-splash');
  const btnReplay = document.getElementById('btn-replay');
  const btnToggleFrame = document.getElementById('btn-toggle-frame');
  const frameToggleLabel = document.getElementById('frame-toggle-label');
  const viewportWrapper = document.getElementById('viewport-wrapper');

  // Login Form Elements
  const loginForm = document.getElementById('login-form');
  const inputIdentifier = document.getElementById('input-identifier');
  const inputPassword = document.getElementById('input-password');
  const errIdentifier = document.getElementById('err-identifier');
  const errPassword = document.getElementById('err-password');
  const authErrorBanner = document.getElementById('auth-error-banner');
  const authErrorMsg = document.getElementById('auth-error-msg');
  const btnTogglePwd = document.getElementById('btn-toggle-pwd');
  const iconEyeClosed = document.querySelector('.icon-eye-closed');
  const iconEyeOpen = document.querySelector('.icon-eye-open');
  const linkForgot = document.getElementById('link-forgot');

  // Forgot Password Screen Elements
  // Step 1:
  const formForgotEmail = document.getElementById('form-forgot-email');
  const forgotEmailInput = document.getElementById('forgot-email');
  const errForgotEmail = document.getElementById('err-forgot-email');
  const bannerForgotEmail = document.getElementById('banner-forgot-email');
  const bannerForgotEmailMsg = document.getElementById('banner-forgot-email-msg');
  const btnKirimKode = document.getElementById('btn-kirim-kode');
  const linkBackLogin1 = document.getElementById('link-back-login-1');

  // Step 2:
  const formVerifyOtp = document.getElementById('form-verify-otp');
  const otpDisplayEmail = document.getElementById('otp-display-email');
  const otpDigitBoxes = document.querySelectorAll('.otp-digit-box');
  const errOtpCode = document.getElementById('err-otp-code');
  const bannerVerifyOtp = document.getElementById('banner-verify-otp');
  const bannerVerifyOtpMsg = document.getElementById('banner-verify-otp-msg');
  const btnVerifikasiOtp = document.getElementById('btn-verifikasi-otp');
  const btnResendCode = document.getElementById('btn-resend-code');
  const resendTimerBadge = document.getElementById('resend-timer-badge');
  const linkBackLogin2 = document.getElementById('link-back-login-2');

  // Step 3:
  const formResetPassword = document.getElementById('form-reset-password');
  const resetPasswordVal = document.getElementById('reset-password-val');
  const resetConfirmPasswordVal = document.getElementById('reset-confirm-password-val');
  const btnToggleResetPwd = document.getElementById('btn-toggle-reset-pwd');
  const btnToggleResetConfirm = document.getElementById('btn-toggle-reset-confirm');
  const errResetPasswordVal = document.getElementById('err-reset-password-val');
  const errResetConfirmVal = document.getElementById('err-reset-confirm-val');
  const bannerResetPassword = document.getElementById('banner-reset-password');
  const bannerResetPasswordMsg = document.getElementById('banner-reset-password-msg');
  const btnSimpanPassword = document.getElementById('btn-simpan-password');
  const linkBackLogin3 = document.getElementById('link-back-login-3');

  // Criteria rules for Step 3
  const resetRuleLen = document.getElementById('reset-rule-len');
  const resetRuleCase = document.getElementById('reset-rule-case');
  const resetRuleDigit = document.getElementById('reset-rule-digit');

  // Register Form Elements
  const linkDaftar = document.getElementById('link-daftar');
  const linkKembaliMasuk = document.getElementById('link-kembali-masuk');
  const registerForm = document.getElementById('register-form');
  const regName = document.getElementById('reg-name');
  const regEmail = document.getElementById('reg-email');
  const regPassword = document.getElementById('reg-password');
  const regConfirmPassword = document.getElementById('reg-confirm-password');
  const regTermsCheckbox = document.getElementById('reg-terms-checkbox');
  const btnToggleRegPwd = document.getElementById('btn-toggle-reg-pwd');
  const btnToggleRegConfirmPwd = document.getElementById('btn-toggle-reg-confirm-pwd');
  const errRegName = document.getElementById('err-reg-name');
  const errRegEmail = document.getElementById('err-reg-email');
  const errRegPassword = document.getElementById('err-reg-password');
  const errRegConfirmPassword = document.getElementById('err-reg-confirm-password');
  const errRegTerms = document.getElementById('err-reg-terms');
  const regErrorBanner = document.getElementById('reg-error-banner');
  const regErrorMsg = document.getElementById('reg-error-msg');
  const ruleLength = document.getElementById('rule-length');
  const ruleDigit = document.getElementById('rule-digit');
  const ruleCase = document.getElementById('rule-case');

  // Google Modal & Toast
  const btnGoogleAuth = document.getElementById('btn-google-auth');
  const googleModalBackdrop = document.getElementById('google-modal-backdrop');
  const btnCloseGoogleModal = document.getElementById('btn-close-google-modal');
  const btnCancelGoogle = document.getElementById('btn-cancel-google');
  const googleAccountItems = document.querySelectorAll('.google-account-item');
  const toastNotification = document.getElementById('toast-notification');
  const toastTitle = document.getElementById('toast-title');
  const toastMsg = document.getElementById('toast-msg');

  // Logout buttons
  const btnUserLogout = document.getElementById('btn-user-logout');
  const btnAdminLogout = document.getElementById('btn-admin-logout');

  // Animation Timers
  let animationTimers = [];

  function clearAllTimers() {
    animationTimers.forEach(t => clearTimeout(t));
    animationTimers = [];
  }

  /**
   * Set Specific Splash Screen Stage (1 - 5)
   */
  function setSplashStage(stageNum) {
    if (!splashScreen) return;
    splashScreen.className = `splash-screen stage-${stageNum}`;
    splashScreen.style.display = 'flex';

    // Status bar text color: light on stage 1 (green bg), dark on stages 2-5 (white bg)
    if (statusBar) {
      if (stageNum === 1) {
        statusBar.classList.remove('dark-text');
      } else {
        statusBar.classList.add('dark-text');
      }
    }
  }

  /**
   * Run Splash Animation Sequence (5 Tahap Mulus Sesuai Urutan Gambar)
   * 1. Tahap 1 (Gambar 4): Latar Hijau Tua (#529A7B) + Logo Kecil di Tengah
   * 2. Tahap 2 (Gambar 3): Latar Putih Bersih + Logo Ukuran Sedang Pas di Tengah
   * 3. Tahap 3 (Gambar 5): Zoom-in Membesar Dramatis Menampilkan Logo ObeSight Besar di Tengah
   * 4. Tahap 4 (Gambar 2): Logo Scale Down Kembali ke Ukuran Lencana + Jeda Singkat & Subtle Drop Shadow
   * 5. Tahap 5 (Gambar 1): Teks "ObeSight" Muncul di Kanan Logo (Horizontal), Keduanya Pas di Tengah Layar
   * 6. Transisi Mulus ke Layar Login Utama
   */
  function runSplashAnimation() {
    clearAllTimers();

    // Reset visual states
    splashScreen.style.display = 'flex';
    splashScreen.classList.remove('fade-out');
    authScreen.classList.add('hidden');
    if (registerScreen) registerScreen.classList.add('hidden');
    if (forgotEmailScreen) forgotEmailScreen.classList.add('hidden');
    if (forgotOtpScreen) forgotOtpScreen.classList.add('hidden');
    if (forgotResetScreen) forgotResetScreen.classList.add('hidden');
    if (userDash) userDash.classList.add('hidden');
    if (adminDash) adminDash.classList.add('hidden');

    // Tahap 1 (Gambar 4): Dimulai seketika (0ms)
    setSplashStage(1);

    // Tahap 2 (Gambar 3): Latar berubah jadi putih, logo lencana sedang di tengah (setelah 1300ms)
    animationTimers.push(setTimeout(() => {
      setSplashStage(2);
    }, 1300));

    // Tahap 3 (Gambar 5): Zoom-in besar dramatis di tengah layar (setelah 2600ms)
    animationTimers.push(setTimeout(() => {
      setSplashStage(3);
    }, 2600));

    // Tahap 4 (Gambar 2): Scale down kembali & jeda singkat dengan subtle drop shadow (setelah 3900ms)
    animationTimers.push(setTimeout(() => {
      setSplashStage(4);
    }, 3900));

    // Tahap 5 (Gambar 1): Teks ObeSight muncul di kanan logo, keduanya pas di tengah (setelah 5200ms)
    animationTimers.push(setTimeout(() => {
      setSplashStage(5);
    }, 5200));

    // Selesai: Transisi crossfade ke Layar Login Utama (setelah 7000ms)
    animationTimers.push(setTimeout(() => {
      transitionToLogin();
    }, 7000));
  }

  function transitionToLogin() {
    clearAllTimers();
    if (!splashScreen) return;
    splashScreen.classList.add('fade-out');

    setTimeout(() => {
      splashScreen.style.display = 'none';
      if (statusBar) statusBar.classList.add('dark-text');
      authScreen.classList.remove('hidden');
      if (registerScreen) registerScreen.classList.add('hidden');
      if (forgotEmailScreen) forgotEmailScreen.classList.add('hidden');
      if (forgotOtpScreen) forgotOtpScreen.classList.add('hidden');
      if (forgotResetScreen) forgotResetScreen.classList.add('hidden');
      if (userDash) userDash.classList.add('hidden');
      if (adminDash) adminDash.classList.add('hidden');
    }, 500);
  }

  // Replay Animation Button in Toolbar
  if (btnReplay) {
    btnReplay.addEventListener('click', () => {
      runSplashAnimation();
    });
  }

  // Toggle Frame / Fullscreen Mode
  if (btnToggleFrame) {
    btnToggleFrame.addEventListener('click', () => {
      const isFullscreen = viewportWrapper.classList.toggle('fullscreen-mode');
      viewportWrapper.classList.toggle('frame-mode', !isFullscreen);
      frameToggleLabel.textContent = isFullscreen ? 'Mode Bingkai HP' : 'Mode Layar Penuh';
    });
  }



  // Password Visibility Toggle
  if (btnTogglePwd && inputPassword) {
    btnTogglePwd.addEventListener('click', () => {
      const isPassword = inputPassword.type === 'password';
      inputPassword.type = isPassword ? 'text' : 'password';
      if (isPassword) {
        iconEyeClosed.classList.add('hidden');
        iconEyeOpen.classList.remove('hidden');
      } else {
        iconEyeClosed.classList.remove('hidden');
        iconEyeOpen.classList.add('hidden');
      }
    });
  }

  function clearErrors() {
    if (errIdentifier) errIdentifier.classList.add('hidden');
    if (errPassword) errPassword.classList.add('hidden');
    if (authErrorBanner) authErrorBanner.classList.add('hidden');
  }

  // Clear error banners as soon as user types
  if (inputIdentifier) {
    inputIdentifier.addEventListener('input', () => {
      if (errIdentifier) errIdentifier.classList.add('hidden');
      if (authErrorBanner) authErrorBanner.classList.add('hidden');
    });
  }

  if (inputPassword) {
    inputPassword.addEventListener('input', () => {
      if (errPassword) errPassword.classList.add('hidden');
      if (authErrorBanner) authErrorBanner.classList.add('hidden');
    });
  }

  // Toast Notification
  let toastTimer;
  function showToast(title, message) {
    clearTimeout(toastTimer);
    toastTitle.textContent = title;
    toastMsg.textContent = message;
    toastNotification.classList.remove('hidden');

    toastTimer = setTimeout(() => {
      toastNotification.classList.add('hidden');
    }, 3500);
  }

  // Current active user state
  let currentUser = {
    name: 'Zahra Fitriana',
    firstName: 'Zahra',
    email: 'zahraafitriana@gmail.com',
    role: 'user'
  };

  function getUserBiodataStatus(userEmail) {
    const email = (userEmail || '').toLowerCase();
    const key = `obesight_biodata_complete_${email}`;
    const stored = localStorage.getItem(key);
    if (stored !== null) {
      return stored === 'true';
    }
    // Default preset rules:
    // zahrafitrie is already complete
    if (email.includes('zahrafitrie')) {
      return true;
    }
    // zahraafitriana is incomplete by default
    return false;
  }

  function setUserBiodataStatus(userEmail, isComplete) {
    const email = (userEmail || '').toLowerCase();
    const key = `obesight_biodata_complete_${email}`;
    localStorage.setItem(key, isComplete ? 'true' : 'false');
  }

  function updateReminderBannerVisibility() {
    const banner = document.getElementById('btn-reminder-biodata');
    if (!banner) return;
    const isComplete = getUserBiodataStatus(currentUser.email);
    if (isComplete) {
      banner.classList.add('hidden');
    } else {
      banner.classList.remove('hidden');
    }
  }

  function getUserBmiData(userEmail) {
    const email = (userEmail || '').toLowerCase();
    const key = `obesight_user_bmi_${email}`;
    const stored = localStorage.getItem(key);
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch (e) { }
    }
    return {
      bmi: '22.8',
      category: 'Normal',
      risk: 'Rendah'
    };
  }

  function setUserBmiData(userEmail, data) {
    const email = (userEmail || '').toLowerCase();
    const key = `obesight_user_bmi_${email}`;
    localStorage.setItem(key, JSON.stringify(data));
  }

  function updateHealthStatusCard(bmiData) {
    const imtVal = document.getElementById('status-imt-value');
    const imtTag = document.getElementById('status-imt-tag');
    const riskTag = document.getElementById('status-risk-tag');

    if (imtVal) imtVal.textContent = bmiData.bmi;
    if (imtTag) {
      imtTag.textContent = bmiData.category;
      imtTag.className = 'status-metric-tag';
      const catLower = (bmiData.category || '').toLowerCase();
      if (catLower.includes('kurus')) imtTag.classList.add('kurus');
      else if (catLower.includes('normal')) imtTag.classList.add('normal');
      else if (catLower.includes('kelebihan') || catLower.includes('overweight')) imtTag.classList.add('overweight');
      else imtTag.classList.add('obesitas');
    }
    if (riskTag) {
      riskTag.textContent = bmiData.risk;
      riskTag.className = 'status-metric-tag';
      const riskLower = (bmiData.risk || '').toLowerCase();
      if (riskLower.includes('rendah')) riskTag.classList.add('risk-rendah');
      else if (riskLower.includes('sedang')) riskTag.classList.add('risk-sedang');
      else riskTag.classList.add('risk-tinggi');
    }
  }

  function updateUserData(fullName, email) {
    currentUser.name = fullName || 'Zahra Fitriana';
    if (email) currentUser.email = email;
    const parts = currentUser.name.trim().split(' ');
    currentUser.firstName = parts[0] || 'Zahra';

    // Update greeting on Home screen
    const greetingTitle = document.getElementById('greeting-title-text');
    if (greetingTitle) {
      greetingTitle.textContent = `Halo, ${currentUser.firstName}! 👋`;
    }

    // Update profile dropdown
    const profileFullname = document.getElementById('profile-user-fullname');
    if (profileFullname) profileFullname.textContent = currentUser.name;
    const profileInitial = document.getElementById('profile-avatar-initial');
    if (profileInitial) profileInitial.textContent = currentUser.firstName.charAt(0).toUpperCase();

    const bioName = document.getElementById('bio-name');
    if (bioName) bioName.value = currentUser.name;

    updateReminderBannerVisibility();

    // Auto-sync Health Status Card with current user's latest BMI
    const bmiData = getUserBmiData(currentUser.email);
    updateHealthStatusCard(bmiData);
  }

  function navigateToDashboard(role, name, email, customToastTitle, customToastMsg) {
    authScreen.classList.add('hidden');
    if (registerScreen) registerScreen.classList.add('hidden');
    if (role === 'admin') {
      adminDash.classList.remove('hidden');
      userDash.classList.add('hidden');
      const adminGreeting = document.getElementById('admin-greeting-name');
      if (adminGreeting) adminGreeting.textContent = name || 'Dr. Hendra Wijaya, Sp.GK';
    } else {
      userDash.classList.remove('hidden');
      adminDash.classList.add('hidden');
      updateUserData(name || 'Zahra Fitriana', email || 'zahraafitriana@gmail.com');
      // Reset to Home Tab
      switchHomeTab('home');
    }
    const tTitle = customToastTitle || 'Berhasil Masuk!';
    const tMsg = customToastMsg || `Selamat datang di Beranda ${role === 'admin' ? 'Administrator' : 'Pengguna'}.`;
    showToast(tTitle, tMsg);
  }

  // Saved / registered users repository (persists across page reloads in localStorage)
  let registeredUsers = [];
  try {
    const saved = localStorage.getItem('obesight_registered_users');
    if (saved) registeredUsers = JSON.parse(saved);
  } catch (err) {
    console.error('Error loading registered users', err);
  }

  // Form Submit / Login Logic
  if (loginForm) {
    loginForm.addEventListener('submit', (e) => {
      e.preventDefault();
      clearErrors();

      const identifier = inputIdentifier.value.trim();
      const password = inputPassword.value.trim();

      let hasError = false;
      if (!identifier) {
        errIdentifier.classList.remove('hidden');
        hasError = true;
      }
      if (!password) {
        errPassword.classList.remove('hidden');
        hasError = true;
      }
      if (hasError) return;

      const cleanId = identifier.toLowerCase();

      // Admin account check
      if ((cleanId === 'admin@obesight.com' || cleanId === 'admin') && password === 'admin123') {
        navigateToDashboard('admin', 'Dr. Hendra Wijaya, Sp.GK', 'admin@obesight.com');
        return;
      }

      // Default normal user check
      if (
        (cleanId === 'zahraafitriana@gmail.com' || cleanId === 'zahraafitriana' || cleanId === 'zahrafitrie@gmail.com' || cleanId === 'zahra') &&
        (password === 'Zahra1234' || password === 'zahra1234' || password === 'zohf1234')
      ) {
        const userEmail = cleanId.includes('@') ? cleanId : (cleanId.includes('zahrafitrie') ? 'zahrafitrie@gmail.com' : 'zahraafitriana@gmail.com');
        navigateToDashboard('user', 'Zahra Fitriana', userEmail);
        return;
      }

      // Check dynamically registered users
      const matchRegistered = registeredUsers.find(u =>
        (u.email.toLowerCase() === cleanId || u.name.toLowerCase() === cleanId) && u.password === password
      );
      if (matchRegistered) {
        navigateToDashboard('user', matchRegistered.name, matchRegistered.email);
        return;
      }

      // Allow any custom user name demo if password matches
      if (password === '123456' || password === 'password' || password === 'Zahra1234' || password === 'zahra1234') {
        const displayName = identifier.includes('@') ? identifier.split('@')[0] : identifier;
        const capitalized = displayName.charAt(0).toUpperCase() + displayName.slice(1);
        const userEmail = identifier.includes('@') ? identifier : `${displayName.toLowerCase()}@example.com`;
        navigateToDashboard('user', capitalized, userEmail);
        return;
      }

      // Invalid credentials
      authErrorBanner.classList.remove('hidden');
    });
  }

  // Logout handlers
  function performLogout() {
    userDash.classList.add('hidden');
    if (adminDash) adminDash.classList.add('hidden');
    if (registerScreen) registerScreen.classList.add('hidden');
    if (forgotEmailScreen) forgotEmailScreen.classList.add('hidden');
    if (forgotOtpScreen) forgotOtpScreen.classList.add('hidden');
    if (forgotResetScreen) forgotResetScreen.classList.add('hidden');
    authScreen.classList.remove('hidden');
    if (inputPassword) inputPassword.value = '';
    const profileDropdown = document.getElementById('profile-dropdown');
    if (profileDropdown) profileDropdown.classList.add('hidden');
    clearErrors();
    clearRegErrors();
    clearForgotErrors();
    showToast('Sesi Berakhir', 'Anda telah keluar dari akun.');
  }

  // ========================================================
  // REGISTER SCREEN CONTROLLER & VALIDATIONS
  // ========================================================

  function clearRegErrors() {
    if (errRegName) errRegName.classList.add('hidden');
    if (errRegEmail) errRegEmail.classList.add('hidden');
    if (errRegPassword) errRegPassword.classList.add('hidden');
    if (errRegConfirmPassword) errRegConfirmPassword.classList.add('hidden');
    if (errRegTerms) errRegTerms.classList.add('hidden');
    if (regErrorBanner) regErrorBanner.classList.add('hidden');
  }

  function setRuleItemState(ruleEl, isValid) {
    if (!ruleEl) return;
    ruleEl.classList.toggle('valid', isValid);
    const circle = ruleEl.querySelector('.icon-circle');
    const checked = ruleEl.querySelector('.icon-checked');
    if (circle && checked) {
      if (isValid) {
        circle.classList.add('hidden');
        checked.classList.remove('hidden');
      } else {
        circle.classList.remove('hidden');
        checked.classList.add('hidden');
      }
    }
  }

  function checkPasswordCriteria(pwd) {
    const isLenValid = pwd.length >= 8 && pwd.length <= 16;
    const isDigitValid = /\d/.test(pwd);
    const isCaseValid = /[a-z]/.test(pwd) && /[A-Z]/.test(pwd);

    setRuleItemState(ruleLength, isLenValid);
    setRuleItemState(ruleDigit, isDigitValid);
    setRuleItemState(ruleCase, isCaseValid);

    return isLenValid && isDigitValid && isCaseValid;
  }

  function isValidEmailFormat(email) {
    return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(email);
  }

  // Password Visibility Toggle for Register Screen
  function setupPasswordToggle(btn, input) {
    if (!btn || !input) return;
    const eyeClosed = btn.querySelector('.icon-eye-closed');
    const eyeOpen = btn.querySelector('.icon-eye-open');

    btn.addEventListener('click', () => {
      const isPassword = input.type === 'password';
      input.type = isPassword ? 'text' : 'password';
      if (eyeClosed && eyeOpen) {
        if (isPassword) {
          eyeClosed.classList.add('hidden');
          eyeOpen.classList.remove('hidden');
        } else {
          eyeClosed.classList.remove('hidden');
          eyeOpen.classList.add('hidden');
        }
      }
    });
  }

  setupPasswordToggle(btnToggleRegPwd, regPassword);
  setupPasswordToggle(btnToggleRegConfirmPwd, regConfirmPassword);

  // Live Input & Validation Listeners
  if (regPassword) {
    regPassword.addEventListener('input', () => {
      checkPasswordCriteria(regPassword.value);
      if (errRegPassword) errRegPassword.classList.add('hidden');
      if (regErrorBanner) regErrorBanner.classList.add('hidden');
    });
  }

  if (regConfirmPassword) {
    regConfirmPassword.addEventListener('input', () => {
      if (errRegConfirmPassword) errRegConfirmPassword.classList.add('hidden');
      if (regErrorBanner) regErrorBanner.classList.add('hidden');
    });
  }

  if (regName) {
    regName.addEventListener('input', () => {
      if (errRegName) errRegName.classList.add('hidden');
      if (regErrorBanner) regErrorBanner.classList.add('hidden');
    });
  }

  if (regEmail) {
    regEmail.addEventListener('input', () => {
      if (errRegEmail) errRegEmail.classList.add('hidden');
      if (regErrorBanner) regErrorBanner.classList.add('hidden');
    });
  }

  if (regTermsCheckbox) {
    regTermsCheckbox.addEventListener('change', () => {
      if (errRegTerms) errRegTerms.classList.add('hidden');
      if (regErrorBanner) regErrorBanner.classList.add('hidden');
    });
  }

  // Navigation: Login -> Register
  if (linkDaftar) {
    linkDaftar.addEventListener('click', (e) => {
      e.preventDefault();
      authScreen.classList.add('hidden');
      registerScreen.classList.remove('hidden');
      clearRegErrors();
      if (regPassword) checkPasswordCriteria(regPassword.value);
    });
  }

  // Navigation: Register -> Login
  if (linkKembaliMasuk) {
    linkKembaliMasuk.addEventListener('click', (e) => {
      e.preventDefault();
      registerScreen.classList.add('hidden');
      authScreen.classList.remove('hidden');
      clearErrors();
    });
  }

  // Register Form Submit Logic
  if (registerForm) {
    registerForm.addEventListener('submit', (e) => {
      e.preventDefault();
      clearRegErrors();

      const nameVal = regName ? regName.value.trim() : '';
      const emailVal = regEmail ? regEmail.value.trim() : '';
      const pwdVal = regPassword ? regPassword.value : '';
      const confirmPwdVal = regConfirmPassword ? regConfirmPassword.value : '';
      const termsAccepted = regTermsCheckbox ? regTermsCheckbox.checked : false;

      let hasError = false;

      // 1. Nama validation
      if (!nameVal) {
        if (errRegName) errRegName.classList.remove('hidden');
        hasError = true;
      }

      // 2. Email format validation
      if (!emailVal || !isValidEmailFormat(emailVal)) {
        if (errRegEmail) {
          errRegEmail.textContent = !emailVal ? 'Email wajib diisi' : 'Format email tidak valid (contoh: nama@email.com)';
          errRegEmail.classList.remove('hidden');
        }
        hasError = true;
      }

      // 3. Password criteria validation
      const pwdValid = checkPasswordCriteria(pwdVal);
      if (!pwdValid) {
        if (errRegPassword) errRegPassword.classList.remove('hidden');
        hasError = true;
      }

      // 4. Confirm password match
      if (!confirmPwdVal || confirmPwdVal !== pwdVal) {
        if (errRegConfirmPassword) {
          errRegConfirmPassword.textContent = !confirmPwdVal ? 'Konfirmasi kata sandi wajib diisi' : 'Konfirmasi kata sandi tidak cocok';
          errRegConfirmPassword.classList.remove('hidden');
        }
        hasError = true;
      }

      // 5. Terms & conditions checkbox
      if (!termsAccepted) {
        if (errRegTerms) errRegTerms.classList.remove('hidden');
        hasError = true;
      }

      if (hasError) {
        if (regErrorBanner) {
          regErrorBanner.classList.remove('hidden');
          regErrorBanner.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
        return;
      }

      // Save user to repository
      registeredUsers.push({
        name: nameVal,
        email: emailVal,
        password: pwdVal
      });

      try {
        localStorage.setItem('obesight_registered_users', JSON.stringify(registeredUsers));
      } catch (err) { }

      // Reset form & criteria
      registerForm.reset();
      checkPasswordCriteria('');

      // Redirect immediately to User Dashboard
      navigateToDashboard('user', nameVal, emailVal, 'Akun Berhasil Dibuat!', `Selamat datang di ObeSight, ${nameVal}!`);
    });
  }

  // ========================================================
  // FORGOT PASSWORD CONTROLLER (3 CONNECTED SCREENS & OTP)
  // ========================================================

  let recoverySession = {
    email: '',
    resetToken: '',
    cooldownTimer: null,
    cooldownSeconds: 0
  };

  function setButtonLoading(btn, isLoading, defaultText) {
    if (!btn) return;
    const spinner = btn.querySelector('.btn-spinner-icon');
    const label = btn.querySelector('.btn-label-text');
    btn.classList.toggle('loading', isLoading);
    btn.disabled = isLoading;
    if (spinner) spinner.classList.toggle('hidden', !isLoading);
    if (label && defaultText) {
      label.textContent = isLoading ? 'Memproses...' : defaultText;
    }
  }

  function clearForgotErrors() {
    if (errForgotEmail) errForgotEmail.classList.add('hidden');
    if (bannerForgotEmail) bannerForgotEmail.classList.add('hidden');
    if (errOtpCode) errOtpCode.classList.add('hidden');
    if (bannerVerifyOtp) bannerVerifyOtp.classList.add('hidden');
    if (errResetPasswordVal) errResetPasswordVal.classList.add('hidden');
    if (errResetConfirmVal) errResetConfirmVal.classList.add('hidden');
    if (bannerResetPassword) bannerResetPassword.classList.add('hidden');
  }

  function resetOtpBoxes() {
    otpDigitBoxes.forEach((box) => {
      box.value = '';
      box.classList.remove('filled');
    });
  }

  function checkResetPasswordCriteria(pwd) {
    const isLenValid = pwd.length >= 8;
    const isCaseValid = /[a-z]/.test(pwd) && /[A-Z]/.test(pwd);
    const isDigitValid = /\d/.test(pwd);

    setRuleItemState(resetRuleLen, isLenValid);
    setRuleItemState(resetRuleCase, isCaseValid);
    setRuleItemState(resetRuleDigit, isDigitValid);

    return isLenValid && isCaseValid && isDigitValid;
  }

  function startResendCooldown(seconds = 60) {
    if (recoverySession.cooldownTimer) {
      clearInterval(recoverySession.cooldownTimer);
    }
    recoverySession.cooldownSeconds = seconds;
    if (btnResendCode) btnResendCode.disabled = true;
    if (resendTimerBadge) {
      resendTimerBadge.textContent = `(${seconds}s)`;
      resendTimerBadge.classList.remove('hidden');
    }

    recoverySession.cooldownTimer = setInterval(() => {
      recoverySession.cooldownSeconds -= 1;
      if (recoverySession.cooldownSeconds <= 0) {
        clearInterval(recoverySession.cooldownTimer);
        recoverySession.cooldownTimer = null;
        if (btnResendCode) btnResendCode.disabled = false;
        if (resendTimerBadge) resendTimerBadge.classList.add('hidden');
      } else {
        if (resendTimerBadge) {
          resendTimerBadge.textContent = `(${recoverySession.cooldownSeconds}s)`;
        }
      }
    }, 1000);
  }

  // Public/Global navigation to Screen 1
  function tampilkanFormLupaSandi() {
    authScreen.classList.add('hidden');
    if (registerScreen) registerScreen.classList.add('hidden');
    if (forgotOtpScreen) forgotOtpScreen.classList.add('hidden');
    if (forgotResetScreen) forgotResetScreen.classList.add('hidden');
    if (forgotEmailScreen) {
      forgotEmailScreen.classList.remove('hidden');
      clearForgotErrors();
      if (forgotEmailInput) {
        forgotEmailInput.value = '';
        setTimeout(() => forgotEmailInput.focus(), 150);
      }
    }
  }
  // Expose globally for inline onclick="tampilkanFormLupaSandi()"
  window.tampilkanFormLupaSandi = tampilkanFormLupaSandi;

  function kembaliKeLogin() {
    if (forgotEmailScreen) forgotEmailScreen.classList.add('hidden');
    if (forgotOtpScreen) forgotOtpScreen.classList.add('hidden');
    if (forgotResetScreen) forgotResetScreen.classList.add('hidden');
    if (registerScreen) registerScreen.classList.add('hidden');
    authScreen.classList.remove('hidden');
    clearErrors();
    clearRegErrors();
    clearForgotErrors();
  }

  // Setup Password Visibility Toggles for Reset Screen
  setupPasswordToggle(btnToggleResetPwd, resetPasswordVal);
  setupPasswordToggle(btnToggleResetConfirm, resetConfirmPasswordVal);

  // Wire navigation back buttons
  if (linkForgot) {
    linkForgot.addEventListener('click', (e) => {
      e.preventDefault();
      tampilkanFormLupaSandi();
    });
  }

  if (linkBackLogin1) linkBackLogin1.addEventListener('click', (e) => { e.preventDefault(); kembaliKeLogin(); });
  if (linkBackLogin2) linkBackLogin2.addEventListener('click', (e) => { e.preventDefault(); kembaliKeLogin(); });
  if (linkBackLogin3) linkBackLogin3.addEventListener('click', (e) => { e.preventDefault(); kembaliKeLogin(); });

  // Clear errors when typing in forgot inputs
  if (forgotEmailInput) {
    forgotEmailInput.addEventListener('input', () => {
      if (errForgotEmail) errForgotEmail.classList.add('hidden');
      if (bannerForgotEmail) bannerForgotEmail.classList.add('hidden');
    });
  }

  if (resetPasswordVal) {
    resetPasswordVal.addEventListener('input', () => {
      checkResetPasswordCriteria(resetPasswordVal.value);
      if (errResetPasswordVal) errResetPasswordVal.classList.add('hidden');
      if (bannerResetPassword) bannerResetPassword.classList.add('hidden');
    });
  }

  if (resetConfirmPasswordVal) {
    resetConfirmPasswordVal.addEventListener('input', () => {
      if (errResetConfirmVal) errResetConfirmVal.classList.add('hidden');
      if (bannerResetPassword) bannerResetPassword.classList.add('hidden');
    });
  }

  // ----------------------------------------------------
  // STEP 1: KIRIM KODE OTP
  // ----------------------------------------------------
  if (formForgotEmail) {
    formForgotEmail.addEventListener('submit', async (e) => {
      e.preventDefault();
      clearForgotErrors();

      const idVal = forgotEmailInput ? forgotEmailInput.value.trim() : '';
      if (!idVal) {
        if (errForgotEmail) {
          errForgotEmail.textContent = 'Nama pengguna atau email wajib diisi';
          errForgotEmail.classList.remove('hidden');
        }
        return;
      }

      const cleanId = idVal.toLowerCase();

      // Check registered accounts
      let matchedEmail = '';
      if (cleanId === 'zahraafitriana' || cleanId === 'zahraafitriana@gmail.com') {
        matchedEmail = 'zahraafitriana@gmail.com';
      } else if (cleanId === 'zahrafitrie' || cleanId === 'zahrafitrie@gmail.com') {
        matchedEmail = 'zahrafitrie@gmail.com';
      } else if (cleanId === 'zahraalfitiarisa' || cleanId === 'zahraalfitiarisa@gmail.com') {
        matchedEmail = 'zahraalfitiarisa@gmail.com';
      } else if (cleanId === 'admin' || cleanId === 'admin@obesight.com') {
        matchedEmail = 'admin@obesight.com';
      } else {
        const found = registeredUsers.find(u =>
          u.email.toLowerCase() === cleanId || u.name.toLowerCase() === cleanId
        );
        if (found) {
          matchedEmail = found.email;
        } else if (isValidEmailFormat(cleanId)) {
          matchedEmail = cleanId;
        }
      }

      if (!matchedEmail) {
        if (bannerForgotEmail) {
          if (bannerForgotEmailMsg) bannerForgotEmailMsg.textContent = 'Akun atau email tidak ditemukan di sistem.';
          bannerForgotEmail.classList.remove('hidden');
        }
        return;
      }

      setButtonLoading(btnKirimKode, true, 'Kirim Kode');

      try {
        const res = await fetch('/api/auth/send-otp', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ identifier: idVal, knownEmail: matchedEmail })
        });

        const data = await res.json();
        if (!data.success) {
          if (bannerForgotEmail) {
            if (bannerForgotEmailMsg) bannerForgotEmailMsg.textContent = data.message || 'Gagal mengirim kode verifikasi.';
            bannerForgotEmail.classList.remove('hidden');
          }
          setButtonLoading(btnKirimKode, false, 'Kirim Kode');
          return;
        }

        recoverySession.email = data.email || matchedEmail;
        if (data.devOtp) {
          console.log(`[ObeSight Auth - DEV] Kode OTP: ${data.devOtp}`);
          showToast('Kode OTP Terkirim', `Kode 6 digit: ${data.devOtp} (Dev Mode)`);
        } else {
          showToast('Kode OTP Terkirim', `Kode verifikasi telah dikirim ke ${recoverySession.email}`);
        }
      } catch (err) {
        // Fallback in-memory OTP if backend API is not responding
        const fallbackOtp = Math.floor(100000 + Math.random() * 900000).toString();
        window.__obesightFallbackOtp = {
          email: matchedEmail,
          otp: fallbackOtp,
          expiresAt: Date.now() + 5 * 60 * 1000
        };
        recoverySession.email = matchedEmail;
        console.log(`[ObeSight Auth - Fallback] Email: ${matchedEmail} | OTP: ${fallbackOtp}`);
        showToast('Kode OTP Terkirim', `Kode verifikasi: ${fallbackOtp} (Dev Mode)`);
      }

      setButtonLoading(btnKirimKode, false, 'Kirim Kode');

      // Navigate to Step 2
      forgotEmailScreen.classList.add('hidden');
      forgotOtpScreen.classList.remove('hidden');
      if (otpDisplayEmail) otpDisplayEmail.textContent = recoverySession.email;

      resetOtpBoxes();
      clearForgotErrors();
      startResendCooldown(60);

      // Focus first OTP box
      if (otpDigitBoxes[0]) {
        setTimeout(() => otpDigitBoxes[0].focus(), 150);
      }
    });
  }

  // ----------------------------------------------------
  // STEP 2: VERIFIKASI 6 DIGIT KODE OTP
  // ----------------------------------------------------
  otpDigitBoxes.forEach((box, index) => {
    // Digits input & auto-advance
    box.addEventListener('input', (e) => {
      box.value = box.value.replace(/\D/g, '');
      if (box.value) {
        box.classList.add('filled');
        if (index < otpDigitBoxes.length - 1) {
          otpDigitBoxes[index + 1].focus();
        }
      } else {
        box.classList.remove('filled');
      }
      if (errOtpCode) errOtpCode.classList.add('hidden');
      if (bannerVerifyOtp) bannerVerifyOtp.classList.add('hidden');
    });

    // Backspace & arrow keys navigation
    box.addEventListener('keydown', (e) => {
      if (e.key === 'Backspace') {
        if (!box.value && index > 0) {
          otpDigitBoxes[index - 1].focus();
          otpDigitBoxes[index - 1].value = '';
          otpDigitBoxes[index - 1].classList.remove('filled');
        } else {
          box.value = '';
          box.classList.remove('filled');
        }
      } else if (e.key === 'ArrowLeft' && index > 0) {
        otpDigitBoxes[index - 1].focus();
      } else if (e.key === 'ArrowRight' && index < otpDigitBoxes.length - 1) {
        otpDigitBoxes[index + 1].focus();
      }
    });

    // Paste handling (distributes 6 digits across all boxes)
    box.addEventListener('paste', (e) => {
      e.preventDefault();
      const pasteData = (e.clipboardData || window.clipboardData).getData('text');
      const digits = pasteData.replace(/\D/g, '').slice(0, 6);
      if (digits) {
        digits.split('').forEach((d, i) => {
          if (otpDigitBoxes[i]) {
            otpDigitBoxes[i].value = d;
            otpDigitBoxes[i].classList.add('filled');
          }
        });
        const lastIdx = Math.min(digits.length - 1, 5);
        if (otpDigitBoxes[lastIdx]) otpDigitBoxes[lastIdx].focus();
      }
    });
  });

  // Resend OTP button
  if (btnResendCode) {
    btnResendCode.addEventListener('click', async () => {
      if (recoverySession.cooldownSeconds > 0) return;
      if (!recoverySession.email) return;

      btnResendCode.disabled = true;
      try {
        const res = await fetch('/api/auth/send-otp', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ identifier: recoverySession.email })
        });
        const data = await res.json();
        if (data.devOtp) {
          console.log(`[ObeSight Auth - RESEND] OTP: ${data.devOtp}`);
          showToast('Kode Baru Terkirim', `Kode OTP baru: ${data.devOtp} (Dev Mode)`);
        } else {
          showToast('Kode Baru Terkirim', `Kode verifikasi baru telah dikirim ke ${recoverySession.email}`);
        }
      } catch (err) {
        const fallbackOtp = Math.floor(100000 + Math.random() * 900000).toString();
        window.__obesightFallbackOtp = {
          email: recoverySession.email,
          otp: fallbackOtp,
          expiresAt: Date.now() + 5 * 60 * 1000
        };
        console.log(`[ObeSight Auth - RESEND Fallback] OTP: ${fallbackOtp}`);
        showToast('Kode Baru Terkirim', `Kode baru: ${fallbackOtp} (Dev Mode)`);
      }

      resetOtpBoxes();
      clearForgotErrors();
      startResendCooldown(60);
      if (otpDigitBoxes[0]) otpDigitBoxes[0].focus();
    });
  }

  // Verify OTP Form Submit
  if (formVerifyOtp) {
    formVerifyOtp.addEventListener('submit', async (e) => {
      e.preventDefault();
      clearForgotErrors();

      const enteredOtp = Array.from(otpDigitBoxes).map(b => b.value.trim()).join('');
      if (enteredOtp.length < 6) {
        if (errOtpCode) {
          errOtpCode.textContent = 'Masukkan lengkap 6 digit kode verifikasi';
          errOtpCode.classList.remove('hidden');
        }
        return;
      }

      setButtonLoading(btnVerifikasiOtp, true, 'Verifikasi');

      let verifySuccess = false;
      let returnedToken = '';

      try {
        const res = await fetch('/api/auth/verify-otp', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: recoverySession.email, otp: enteredOtp })
        });
        const data = await res.json();
        if (data.success) {
          verifySuccess = true;
          returnedToken = data.resetToken;
        } else {
          if (bannerVerifyOtp) {
            if (bannerVerifyOtpMsg) bannerVerifyOtpMsg.textContent = data.message || 'Kode verifikasi salah atau kedaluwarsa.';
            bannerVerifyOtp.classList.remove('hidden');
          }
          if (errOtpCode) {
            errOtpCode.textContent = data.message || 'Kode verifikasi salah';
            errOtpCode.classList.remove('hidden');
          }
        }
      } catch (err) {
        // Fallback in-memory validation
        const record = window.__obesightFallbackOtp;
        if (record && record.email === recoverySession.email) {
          if (Date.now() > record.expiresAt) {
            if (bannerVerifyOtp) {
              if (bannerVerifyOtpMsg) bannerVerifyOtpMsg.textContent = 'Kode verifikasi telah kedaluwarsa (lebih dari 5 menit).';
              bannerVerifyOtp.classList.remove('hidden');
            }
          } else if (record.otp === enteredOtp) {
            verifySuccess = true;
            returnedToken = 'fb_token_' + Date.now();
            delete window.__obesightFallbackOtp;
          } else {
            if (bannerVerifyOtp) {
              if (bannerVerifyOtpMsg) bannerVerifyOtpMsg.textContent = 'Kode verifikasi 6 digit yang Anda masukkan salah.';
              bannerVerifyOtp.classList.remove('hidden');
            }
            if (errOtpCode) errOtpCode.classList.remove('hidden');
          }
        } else {
          if (bannerVerifyOtp) {
            if (bannerVerifyOtpMsg) bannerVerifyOtpMsg.textContent = 'Kode verifikasi tidak ditemukan atau kedaluwarsa.';
            bannerVerifyOtp.classList.remove('hidden');
          }
        }
      }

      setButtonLoading(btnVerifikasiOtp, false, 'Verifikasi');

      if (verifySuccess) {
        recoverySession.resetToken = returnedToken;
        showToast('Verifikasi Berhasil', 'Silakan tentukan kata sandi baru akun Anda.');

        // Navigate to Step 3
        forgotOtpScreen.classList.add('hidden');
        forgotResetScreen.classList.remove('hidden');
        clearForgotErrors();

        if (resetPasswordVal) resetPasswordVal.value = '';
        if (resetConfirmPasswordVal) resetConfirmPasswordVal.value = '';
        checkResetPasswordCriteria('');

        if (resetPasswordVal) {
          setTimeout(() => resetPasswordVal.focus(), 150);
        }
      }
    });
  }

  // ----------------------------------------------------
  // STEP 3: BUAT KATA SANDI BARU
  // ----------------------------------------------------
  if (formResetPassword) {
    formResetPassword.addEventListener('submit', async (e) => {
      e.preventDefault();
      clearForgotErrors();

      const newPwd = resetPasswordVal ? resetPasswordVal.value : '';
      const confirmPwd = resetConfirmPasswordVal ? resetConfirmPasswordVal.value : '';

      let hasError = false;

      if (!newPwd) {
        if (errResetPasswordVal) {
          errResetPasswordVal.textContent = 'Kata sandi baru wajib diisi';
          errResetPasswordVal.classList.remove('hidden');
        }
        hasError = true;
      } else if (!checkResetPasswordCriteria(newPwd)) {
        if (errResetPasswordVal) {
          errResetPasswordVal.textContent = 'Kata sandi belum memenuhi kriteria';
          errResetPasswordVal.classList.remove('hidden');
        }
        hasError = true;
      }

      if (!confirmPwd) {
        if (errResetConfirmVal) {
          errResetConfirmVal.textContent = 'Konfirmasi kata sandi wajib diisi';
          errResetConfirmVal.classList.remove('hidden');
        }
        hasError = true;
      } else if (confirmPwd !== newPwd) {
        if (errResetConfirmVal) {
          errResetConfirmVal.textContent = 'Konfirmasi kata sandi tidak cocok';
          errResetConfirmVal.classList.remove('hidden');
        }
        hasError = true;
      }

      if (hasError) {
        if (bannerResetPassword) {
          if (bannerResetPasswordMsg) bannerResetPasswordMsg.textContent = 'Mohon periksa kembali kriteria kata sandi Anda.';
          bannerResetPassword.classList.remove('hidden');
        }
        return;
      }

      setButtonLoading(btnSimpanPassword, true, 'Simpan Kata Sandi');

      try {
        await fetch('/api/auth/reset-password', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            email: recoverySession.email,
            resetToken: recoverySession.resetToken,
            newPassword: newPwd
          })
        });
      } catch (err) { }

      // Update registered users repository in localStorage
      const userIdx = registeredUsers.findIndex(u => u.email.toLowerCase() === recoverySession.email.toLowerCase());
      if (userIdx !== -1) {
        registeredUsers[userIdx].password = newPwd;
      } else {
        // Preset user updated: store as registered entry so subsequent logins accept new password
        registeredUsers.push({
          name: recoverySession.email.split('@')[0],
          email: recoverySession.email,
          password: newPwd
        });
      }

      try {
        localStorage.setItem('obesight_registered_users', JSON.stringify(registeredUsers));
      } catch (err) { }

      setButtonLoading(btnSimpanPassword, false, 'Simpan Kata Sandi');

      // Navigate back to Login Screen
      forgotResetScreen.classList.add('hidden');
      authScreen.classList.remove('hidden');

      if (inputIdentifier) inputIdentifier.value = recoverySession.email;
      if (inputPassword) inputPassword.value = '';
      clearErrors();

      showToast('Kata Sandi Berhasil Diperbarui!', 'Silakan masuk menggunakan kata sandi baru Anda.');
    });
  }

  if (btnUserLogout) btnUserLogout.addEventListener('click', performLogout);
  if (btnAdminLogout) btnAdminLogout.addEventListener('click', performLogout);
  const btnSettingsLogout = document.getElementById('btn-settings-logout');
  if (btnSettingsLogout) btnSettingsLogout.addEventListener('click', performLogout);

  // Profile Avatar Dropdown Toggle
  const btnProfileAvatar = document.getElementById('btn-profile-avatar');
  const profileDropdown = document.getElementById('profile-dropdown');
  if (btnProfileAvatar && profileDropdown) {
    btnProfileAvatar.addEventListener('click', (e) => {
      e.stopPropagation();
      profileDropdown.classList.toggle('hidden');
    });

    document.addEventListener('click', (e) => {
      if (!profileDropdown.contains(e.target) && e.target !== btnProfileAvatar) {
        profileDropdown.classList.add('hidden');
      }
    });
  }

  // Floating Bottom Nav Tabs Switching
  const navBtns = [
    { btn: document.getElementById('nav-btn-home'), tab: 'home', content: document.getElementById('tab-content-home') },
    { btn: document.getElementById('nav-btn-stats'), tab: 'stats', content: document.getElementById('tab-content-stats') },
    { btn: document.getElementById('nav-btn-settings'), tab: 'settings', content: document.getElementById('tab-content-settings') }
  ];

  function switchHomeTab(targetTab) {
    if (userDash) {
      userDash.classList.toggle('in-monitoring', targetTab === 'stats');
    }
    if (statusBar) {
      if (targetTab === 'stats') {
        statusBar.classList.remove('dark-text');
      } else {
        statusBar.classList.add('dark-text');
      }
    }
    if (targetTab === 'stats') {
      switchMonitoringSubpage('main');
    }

    navBtns.forEach(item => {
      if (!item.btn || !item.content) return;
      const isActive = item.tab === targetTab;
      item.btn.classList.toggle('active', isActive);
      item.content.classList.toggle('hidden', !isActive);
      item.content.classList.toggle('active', isActive);

      // Re-apply pill styling
      if (isActive) {
        item.btn.innerHTML = `
          <div class="nav-active-pill">
            ${item.tab === 'home'
            ? '<svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>'
            : item.tab === 'stats'
              ? '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/><path d="M4 11L9 6L14 11L20 4"/></svg>'
              : '<svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/></svg>'
          }
          </div>
        `;
      } else {
        item.btn.innerHTML = `
          <div class="nav-icon-box">
            ${item.tab === 'home'
            ? '<svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>'
            : item.tab === 'stats'
              ? '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/><path d="M4 11L9 6L14 11L20 4"/></svg>'
              : '<svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/></svg>'
          }
          </div>
        `;
      }
    });
  }

  navBtns.forEach(item => {
    if (item.btn) {
      item.btn.addEventListener('click', () => switchHomeTab(item.tab));
    }
  });

  // ========================================================
  // MONITORING SUBPAGE NAVIGATION & INTERACTIONS
  // ========================================================
  const monitoringSubpages = {
    main: document.getElementById('monitoring-subpage-main'),
    progress: document.getElementById('monitoring-subpage-progress'),
    riwayat: document.getElementById('monitoring-subpage-riwayat')
  };

  function switchMonitoringSubpage(targetSubpage) {
    Object.keys(monitoringSubpages).forEach(key => {
      const page = monitoringSubpages[key];
      if (!page) return;
      const isTarget = key === targetSubpage;
      page.classList.toggle('hidden', !isTarget);
      page.classList.toggle('active', isTarget);
    });

    if (targetSubpage === 'progress') {
      setTimeout(() => {
        const todayPill = document.querySelector('.date-pill.pill-today');
        if (todayPill) {
          todayPill.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
        }
      }, 80);
    }
  }

  // Header Back Buttons
  const btnBackToHome = document.getElementById('btn-back-to-home');
  if (btnBackToHome) {
    btnBackToHome.addEventListener('click', () => switchHomeTab('home'));
  }

  const btnBackFromProgress = document.getElementById('btn-back-from-progress');
  if (btnBackFromProgress) {
    btnBackFromProgress.addEventListener('click', () => switchMonitoringSubpage('main'));
  }

  const btnBackFromRiwayat = document.getElementById('btn-back-from-riwayat');
  if (btnBackFromRiwayat) {
    btnBackFromRiwayat.addEventListener('click', () => switchMonitoringSubpage('main'));
  }

  // Menu Navigation Cards
  const btnOpenProgress = document.getElementById('btn-open-progress');
  if (btnOpenProgress) {
    btnOpenProgress.addEventListener('click', () => switchMonitoringSubpage('progress'));
  }

  const btnOpenRiwayat = document.getElementById('btn-open-riwayat');
  if (btnOpenRiwayat) {
    btnOpenRiwayat.addEventListener('click', () => switchMonitoringSubpage('riwayat'));
  }

  // Horizontal Date Scroller (31 days of August 2026, 15 is Hari ini)
  const dateScrollerContainer = document.getElementById('progress-date-scroller');
  function initDateScroller() {
    if (!dateScrollerContainer) return;
    dateScrollerContainer.innerHTML = '';

    const dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jum\'at', 'Sabtu'];

    for (let dayNum = 1; dayNum <= 31; dayNum++) {
      const d = new Date(2026, 7, dayNum);
      const dayOfWeek = dayNames[d.getDay()];
      const dateStr = `${dayNum}/8/26`;

      const pill = document.createElement('div');
      pill.className = 'date-pill';
      pill.dataset.date = dateStr;

      if (dayNum < 15) {
        pill.classList.add('pill-past');
        pill.innerHTML = `
          <span class="date-pill-day">${dayOfWeek}</span>
          <span class="date-pill-num">${dateStr}</span>
        `;
      } else if (dayNum === 15) {
        pill.classList.add('pill-today');
        pill.classList.add('selected');
        pill.innerHTML = `
          <span class="date-pill-day">Hari ini</span>
          <span class="date-pill-num">${dateStr}</span>
        `;
      } else {
        pill.classList.add('pill-future');
        pill.innerHTML = `
          <span class="date-pill-day">${dayOfWeek}</span>
          <span class="date-pill-num">${dateStr}</span>
        `;
      }

      pill.addEventListener('click', () => {
        document.querySelectorAll('.date-pill').forEach(p => p.classList.remove('selected'));
        pill.classList.add('selected');
      });

      dateScrollerContainer.appendChild(pill);
    }
  }
  initDateScroller();

  // Activity Checklist & Badges
  const activityCheckboxes = document.querySelectorAll('.activity-checkbox');
  function updateCategoryProgress(cat) {
    const catCheckboxes = document.querySelectorAll(`.activity-checkbox[data-cat="${cat}"]`);
    const total = catCheckboxes.length;
    let checked = 0;
    catCheckboxes.forEach(cb => {
      if (cb.checked) checked++;
    });

    const badge = document.getElementById(`badge-cat-${cat}`);
    if (badge) {
      badge.textContent = `${checked}/${total} Selesai`;
      if (checked === total && total > 0) {
        badge.classList.remove('badge-pending');
        badge.classList.add('badge-done');
      } else {
        badge.classList.remove('badge-done');
        badge.classList.add('badge-pending');
      }
    }
  }

  activityCheckboxes.forEach(cb => {
    cb.addEventListener('change', () => {
      const cat = cb.getAttribute('data-cat');
      if (cat) updateCategoryProgress(cat);
    });
  });

  // Simpan Progress & Confirmation Modal
  const btnSaveProgress = document.getElementById('btn-save-progress');
  const progressConfirmModal = document.getElementById('progress-confirm-modal');
  const btnCancelProgressModal = document.getElementById('btn-cancel-progress-modal');
  const btnYesProgressModal = document.getElementById('btn-yes-progress-modal');

  if (btnSaveProgress && progressConfirmModal) {
    btnSaveProgress.addEventListener('click', () => {
      progressConfirmModal.classList.remove('hidden');
    });
  }

  if (btnCancelProgressModal && progressConfirmModal) {
    btnCancelProgressModal.addEventListener('click', () => {
      progressConfirmModal.classList.add('hidden');
    });
  }

  if (progressConfirmModal) {
    progressConfirmModal.addEventListener('click', (e) => {
      if (e.target === progressConfirmModal) {
        progressConfirmModal.classList.add('hidden');
      }
    });
  }

  if (btnYesProgressModal && progressConfirmModal) {
    btnYesProgressModal.addEventListener('click', () => {
      progressConfirmModal.classList.add('hidden');
      showToast('Berhasil!', 'Rekomendasi berhasil disimpan!');
    });
  }

  // Skrining Obesitas Modal Handlers
  const btnStartScreening = document.getElementById('btn-start-screening');
  const btnScreeningBanner = document.getElementById('btn-screening-banner');
  const screeningModal = document.getElementById('screening-modal-backdrop');
  const btnCloseScreeningModal = document.getElementById('btn-close-screening-modal');
  const btnCalcScreening = document.getElementById('btn-calc-screening');
  const screeningResultBox = document.getElementById('screening-result-box');

  function openScreeningModal() {
    if (screeningModal) {
      screeningModal.classList.remove('hidden');
      if (screeningResultBox) screeningResultBox.classList.add('hidden');
    }
  }

  if (btnStartScreening) btnStartScreening.addEventListener('click', openScreeningModal);
  if (btnScreeningBanner) btnScreeningBanner.addEventListener('click', openScreeningModal);

  if (btnCloseScreeningModal && screeningModal) {
    btnCloseScreeningModal.addEventListener('click', () => {
      screeningModal.classList.add('hidden');
    });
  }

  if (btnCalcScreening && screeningResultBox) {
    btnCalcScreening.addEventListener('click', () => {
      const q1 = parseInt(document.querySelector('input[name="q1"]:checked')?.value || '0', 10);
      const q2 = parseInt(document.querySelector('input[name="q2"]:checked')?.value || '0', 10);
      const q3 = parseInt(document.querySelector('input[name="q3"]:checked')?.value || '0', 10);
      const score = q1 + q2 + q3;

      const riskBadge = document.getElementById('result-risk-badge');
      const riskTitle = document.getElementById('result-risk-title');
      const riskDesc = document.getElementById('result-risk-desc');

      if (score <= 1) {
        riskBadge.textContent = 'Risiko Rendah';
        riskBadge.style.background = '#16A34A';
        riskTitle.textContent = 'Pola Hidup Anda Sangat Baik!';
        riskDesc.textContent = 'Terus pertahankan konsumsi makanan berserat dan rutinitas olahraga 150 menit per minggu.';
      } else if (score <= 3) {
        riskBadge.textContent = 'Risiko Sedang';
        riskBadge.style.background = '#D97706';
        riskTitle.textContent = 'Perlu Perhatian Pada Pola Hidup';
        riskDesc.textContent = 'Tingkatkan durasi aktivitas fisik dan kurangi konsumsi gula harian untuk mencegah kenaikan berat badan.';
      } else {
        riskBadge.textContent = 'Risiko Tinggi';
        riskBadge.style.background = '#DC2626';
        riskTitle.textContent = 'Segera Konsultasikan Pola Gizi';
        riskDesc.textContent = 'Faktor risiko Anda tergolong tinggi. Dianjurkan melakukan skrining komprehensif dan berkonsultasi dengan ahli gizi.';
      }

      screeningResultBox.classList.remove('hidden');
      screeningResultBox.scrollIntoView({ behavior: 'smooth' });
    });
  }

  // Kalkulator IMT Modal Handlers
  const btnOpenBmiCalc = document.getElementById('btn-open-bmi-calc');
  const bmiModal = document.getElementById('bmi-modal-backdrop');
  const btnCloseBmiModal = document.getElementById('btn-close-bmi-modal');
  const btnRecalcBmi = document.getElementById('btn-recalc-bmi');
  const bmiInputHeight = document.getElementById('bmi-input-height');
  const bmiInputWeight = document.getElementById('bmi-input-weight');
  const bmiCalcScore = document.getElementById('bmi-calc-score');
  const bmiCalcCategory = document.getElementById('bmi-calc-category');
  const bmiCalcAdvice = document.getElementById('bmi-calc-advice');

  function calculateBmi() {
    const heightCm = parseFloat(bmiInputHeight?.value || '165');
    const weightKg = parseFloat(bmiInputWeight?.value || '58');

    if (!heightCm || !weightKg || heightCm <= 0 || weightKg <= 0) return;

    const heightM = heightCm / 100;
    const bmi = (weightKg / (heightM * heightM)).toFixed(1);
    if (bmiCalcScore) bmiCalcScore.textContent = bmi;

    const bmiVal = parseFloat(bmi);
    let category = 'Normal';
    let risk = 'Rendah';

    if (bmiVal < 18.5) {
      category = 'Kurus';
      risk = 'Rendah';
      if (bmiCalcCategory) bmiCalcCategory.textContent = 'Kurus (Kekurangan Berat)';
      if (bmiCalcAdvice) bmiCalcAdvice.textContent = 'Tingkatkan asupan kalori bernutrisi dan protein untuk mencapai berat badan ideal.';
      if (bmiCalcScore) bmiCalcScore.style.color = '#0284C7';
    } else if (bmiVal <= 22.9) {
      category = 'Normal';
      risk = 'Rendah';
      if (bmiCalcCategory) bmiCalcCategory.textContent = 'Normal (Berat Ideal)';
      if (bmiCalcAdvice) bmiCalcAdvice.textContent = 'Selamat! Berat badan Anda ideal. Pertahankan dengan pola makan bergizi dan olahraga teratur.';
      if (bmiCalcScore) bmiCalcScore.style.color = '#15803D';
    } else if (bmiVal <= 24.9) {
      category = 'Overweight';
      risk = 'Sedang';
      if (bmiCalcCategory) bmiCalcCategory.textContent = 'Kelebihan Berat Badan (Overweight)';
      if (bmiCalcAdvice) bmiCalcAdvice.textContent = 'Waspada peningkatan berat badan. Kurangi karbohidrat olahan dan gula tambahan.';
      if (bmiCalcScore) bmiCalcScore.style.color = '#D97706';
    } else {
      category = 'Obesitas';
      risk = 'Tinggi';
      if (bmiCalcCategory) bmiCalcCategory.textContent = 'Obesitas';
      if (bmiCalcAdvice) bmiCalcAdvice.textContent = 'Disarankan untuk melakukan penyesuaian defisit kalori sehat dan konsultasi medis.';
      if (bmiCalcScore) bmiCalcScore.style.color = '#DC2626';
    }

    // Automatically persist latest BMI calculation and synchronize Status Kesehatan card
    const currentBmiData = {
      bmi: bmi,
      category: category,
      risk: risk
    };
    setUserBmiData(currentUser.email, currentBmiData);
    updateHealthStatusCard(currentBmiData);
  }

  if (btnOpenBmiCalc && bmiModal) {
    btnOpenBmiCalc.addEventListener('click', () => {
      bmiModal.classList.remove('hidden');
      calculateBmi();
    });
  }

  if (btnCloseBmiModal && bmiModal) {
    btnCloseBmiModal.addEventListener('click', () => {
      bmiModal.classList.add('hidden');
    });
  }

  if (btnRecalcBmi) {
    btnRecalcBmi.addEventListener('click', calculateBmi);
  }
  if (bmiInputHeight) bmiInputHeight.addEventListener('input', calculateBmi);
  if (bmiInputWeight) bmiInputWeight.addEventListener('input', calculateBmi);

  // Lengkapi Biodata Modal Handlers
  const btnReminderBiodata = document.getElementById('btn-reminder-biodata');
  const btnOpenBiodataProfile = document.getElementById('btn-open-biodata-profile');
  const btnSettingsBiodata = document.getElementById('btn-settings-biodata');
  const biodataModal = document.getElementById('biodata-modal-backdrop');
  const btnCloseBiodataModal = document.getElementById('btn-close-biodata-modal');
  const btnSaveBiodata = document.getElementById('btn-save-biodata');

  function openBiodataModal() {
    if (profileDropdown) profileDropdown.classList.add('hidden');
    if (biodataModal) biodataModal.classList.remove('hidden');
  }

  if (btnReminderBiodata) btnReminderBiodata.addEventListener('click', openBiodataModal);
  if (btnOpenBiodataProfile) btnOpenBiodataProfile.addEventListener('click', openBiodataModal);
  if (btnSettingsBiodata) btnSettingsBiodata.addEventListener('click', openBiodataModal);

  if (btnCloseBiodataModal && biodataModal) {
    btnCloseBiodataModal.addEventListener('click', () => {
      biodataModal.classList.add('hidden');
    });
  }

  if (btnSaveBiodata && biodataModal) {
    btnSaveBiodata.addEventListener('click', () => {
      const bioNameInput = document.getElementById('bio-name');
      const newName = bioNameInput?.value.trim();
      if (newName) {
        currentUser.name = newName;
      }
      // Update biodata completion status to true and refresh visibility immediately
      setUserBiodataStatus(currentUser.email, true);
      updateUserData(currentUser.name, currentUser.email);
      biodataModal.classList.add('hidden');
      showToast('Biodata Tersimpan', 'Informasi profil dan kesehatan Anda telah diperbarui.');
    });
  }

  // 4 Menu Ikon Beranda Click Handlers
  const menuBtnScreening = document.getElementById('menu-btn-screening');
  const menuBtnBmi = document.getElementById('menu-btn-bmi');
  const menuBtnProgress = document.getElementById('menu-btn-progress');
  const menuBtnHistory = document.getElementById('menu-btn-history');

  if (menuBtnScreening) {
    menuBtnScreening.addEventListener('click', () => {
      if (screeningModal) {
        screeningModal.classList.remove('hidden');
        if (screeningResultBox) screeningResultBox.classList.add('hidden');
      }
    });
  }

  if (menuBtnBmi) {
    menuBtnBmi.addEventListener('click', () => {
      if (bmiModal) {
        bmiModal.classList.remove('hidden');
        calculateBmi();
      }
    });
  }

  if (menuBtnProgress) {
    menuBtnProgress.addEventListener('click', () => {
      switchHomeTab('stats');
      switchMonitoringSubpage('progress');
    });
  }

  if (menuBtnHistory) {
    menuBtnHistory.addEventListener('click', () => {
      switchHomeTab('stats');
      switchMonitoringSubpage('riwayat');
    });
  }

  // Artikel Kesehatan Modal Handlers
  const articlesData = {
    1: {
      category: 'PANDUAN GIZI',
      title: '5 Pola Makan Sehat Cegah Obesitas',
      heroBg: 'linear-gradient(135deg, #7E96AC, #4A6572)',
      content: `
        <p>Menerapkan pola makan sehat merupakan fondasi utama dalam mencegah dan mengendalikan obesitas. Berikut adalah 5 prinsip utama yang direkomendasikan dokter spesialis gizi:</p><br>
        <p><strong>1. Perbanyak Asupan Serat Alami:</strong> Konsumsi sayuran berdaun hijau dan buah utuh setiap kali makan untuk menjaga rasa kenyang lebih lama.</p><br>
        <p><strong>2. Batasi Gula, Garam, dan Lemak (GGL):</strong> Ikuti anjuran Kemenkes: maksimal 4 sdm gula, 1 sdt garam, dan 5 sdm lemak per hari.</p><br>
        <p><strong>3. Jangan Lewatkan Sarapan Bergizi:</strong> Pilih sarapan kaya protein seperti telur atau oatmeal untuk menstabilkan gula darah sepanjang hari.</p><br>
        <p><strong>4. Minum Air Putih Cukup:</strong> Minum 2 liter air putih sehari dan hindari minuman berpemanis dalam kemasan.</p><br>
        <p><strong>5. Mindful Eating:</strong> Makan secara perlahan tanpa terdistraksi gawai agar otak dapat mendeteksi sinyal kenyang tepat waktu.</p>
      `
    },
    2: {
      category: 'PANDUAN KEMENKES',
      title: 'Porsi Piring Gizi Seimbang Kemenkes',
      heroBg: 'linear-gradient(135deg, #E5BD87, #D97706)',
      content: `
        <p>Konsep <strong>Isi Piringku</strong> dari Kementerian Kesehatan RI membagi satu piring makan menjadi 4 bagian ideal:</p><br>
        <p>• <strong>1/3 Piring Makanan Pokok:</strong> Sumber karbohidrat kompleks seperti nasi merah, jagung, atau ubi jalar.</p><br>
        <p>• <strong>1/3 Piring Sayuran:</strong> Beraneka ragam sayur kaya vitamin, mineral, dan antioksidan.</p><br>
        <p>• <strong>1/6 Piring Lauk Pauk:</strong> Sumber protein hewani atau nabati rendah lemak seperti ikan, tempe, tahu, atau ayam tanpa kulit.</p><br>
        <p>• <strong>1/6 Piring Buah-buahan:</strong> Buah segar seperti pepaya, pisang, jeruk, atau apel sebagai camilan sehat.</p>
      `
    },
    3: {
      category: 'EDUKASI GIZI',
      title: 'Isi Piringku: Pedoman Gizi Sehari-hari',
      heroBg: 'linear-gradient(135deg, #58B29C, #0F766E)',
      content: `
        <p>Makan sehat tidak harus rumit atau mahal. Memahami keseimbangan nutrisi makro (karbohidrat, protein, lemak) dan mikro (vitamin, mineral) dalam menu sehari-hari membantu mengoptimalkan metabolisme dan menjaga berat badan tetap stabil.</p><br>
        <p>Jadwalkan jam makan teratur dan kombinasikan dengan camilan sehat di antara waktu makan utama untuk mencegah makan berlebih saat malam hari.</p>
      `
    },
    4: {
      category: 'GAYA HIDUP AKTIF',
      title: 'Aktivitas Fisik Ringan Pembakar Kalori',
      heroBg: 'linear-gradient(135deg, #818CF8, #4338CA)',
      content: `
        <p>Aktivitas fisik tidak selalu berarti harus ke gym atau mengangkat beban berat. Rutinitas sederhana yang konsisten memberikan dampak besar:</p><br>
        <p>• Jalan kaki cepat 30 menit setiap hari membakar hingga 150-200 kalori.</p><br>
        <p>• Gunakan tangga daripada lift untuk melatih otot kaki dan kardiovaskular.</p><br>
        <p>• Peregangan ringan setiap 1 jam duduk saat bekerja mencegah penumpukan lemak visceral.</p>
      `
    }
  };

  const articleModal = document.getElementById('article-modal-backdrop');
  const btnCloseArticleModal = document.getElementById('btn-close-article-modal');
  const btnSeeAllArticles = document.getElementById('btn-see-all-articles');
  const articleCards = document.querySelectorAll('.article-card');

  function openArticleModal(id) {
    const data = articlesData[id] || articlesData[1];
    const catEl = document.getElementById('article-modal-category');
    const titleEl = document.getElementById('article-modal-title');
    const heroEl = document.getElementById('article-modal-hero');
    const textEl = document.getElementById('article-modal-content-text');

    if (catEl) catEl.textContent = data.category;
    if (titleEl) titleEl.textContent = data.title;
    if (heroEl) heroEl.style.background = data.heroBg;
    if (textEl) textEl.innerHTML = data.content;

    if (articleModal) articleModal.classList.remove('hidden');
  }

  articleCards.forEach(card => {
    card.addEventListener('click', () => {
      const id = card.getAttribute('data-article-id') || '1';
      openArticleModal(id);
    });
  });

  if (btnSeeAllArticles) {
    btnSeeAllArticles.addEventListener('click', () => {
      openArticleModal(1);
    });
  }

  if (btnCloseArticleModal && articleModal) {
    btnCloseArticleModal.addEventListener('click', () => {
      articleModal.classList.add('hidden');
    });
  }

  // Google Sign In Modal
  if (btnGoogleAuth) {
    btnGoogleAuth.addEventListener('click', () => {
      if (googleModalBackdrop) {
        googleModalBackdrop.classList.remove('hidden');
      }
    });
  }

  function closeGoogleModal() {
    if (googleModalBackdrop) {
      googleModalBackdrop.classList.add('hidden');
    }
  }

  if (btnCloseGoogleModal) btnCloseGoogleModal.addEventListener('click', closeGoogleModal);
  if (btnCancelGoogle) btnCancelGoogle.addEventListener('click', closeGoogleModal);
  if (googleModalBackdrop) {
    googleModalBackdrop.addEventListener('click', (e) => {
      if (e.target === googleModalBackdrop) closeGoogleModal();
    });
  }

  // Google Account Select
  const currentGoogleAccountItems = document.querySelectorAll('.google-account-item');
  currentGoogleAccountItems.forEach(item => {
    item.addEventListener('click', () => {
      const role = item.getAttribute('data-role');
      const name = item.getAttribute('data-name');
      closeGoogleModal();
      navigateToDashboard(role, name, email);
    });
  });

  // Forgot Password Link
  const linkForgotPwd = document.getElementById('link-forgot-pwd');
  if (linkForgotPwd) {
    linkForgotPwd.addEventListener('click', (e) => {
      e.preventDefault();
      alert('Tautan reset kata sandi telah disiapkan dan dapat dikirim ke email Anda.');
    });
  }

  // Start the Splash sequence on initial load
  runSplashAnimation();
});

