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
  const profileScreen = document.getElementById('profile-screen');
  const editProfileScreen = document.getElementById('edit-profile-screen');
  const articleListScreen = document.getElementById('article-list-screen');
  const articleDetailScreen = document.getElementById('article-detail-screen');
  const photoSheetBackdrop = document.getElementById('photo-sheet-backdrop');
  const cancelModalBackdrop = document.getElementById('modal-cancel-edit-backdrop');
  const statusBar = document.getElementById('phone-status-bar');

  // Controls & Toolbar
  const btnSkipSplash = document.getElementById('btn-skip-splash');
  const btnReplay = document.getElementById('btn-replay');
  const btnToggleFrame = document.getElementById('btn-toggle-frame');
  const frameToggleLabel = document.getElementById('frame-toggle-label');
  const viewportWrapper = document.getElementById('viewport-wrapper');
  const btnDemoBeranda = document.getElementById('btn-demo-beranda');
  const btnDemoArticles = document.getElementById('btn-demo-articles');
  const btnDemoProfil = document.getElementById('btn-demo-profil');
  const btnDemoEdit = document.getElementById('btn-demo-edit');
  const btnToggleBiodataDemo = document.getElementById('btn-toggle-biodata-demo');
  const badgeBiodataStatus = document.getElementById('badge-biodata-status');

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
    if (splashScreen) {
      splashScreen.style.display = 'flex';
      splashScreen.classList.remove('fade-out');
    }
    if (authScreen) authScreen.classList.add('hidden');
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
    if (splashScreen) splashScreen.classList.add('fade-out');

    setTimeout(() => {
      if (splashScreen) splashScreen.style.display = 'none';
      if (statusBar) statusBar.classList.add('dark-text');
      if (authScreen) authScreen.classList.remove('hidden');
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

  function getCurrentMonthYearIndo() {
    const monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    const now = new Date();
    return `${monthNames[now.getMonth()]} ${now.getFullYear()}`;
  }

  const DEFAULT_AVATAR_PLACEHOLDER = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><circle cx='50' cy='50' r='50' fill='%23D1FAE5'/><circle cx='50' cy='38' r='18' fill='%234E9070'/><path d='M20 86c0-16.5 13.5-30 30-30s30 13.5 30 30z' fill='%234E9070'/></svg>";

  // User Profile full data model
  let userProfile = {
    fullName: 'Zahra Fitriana',
    dob: '12 Juli 2003',
    gender: 'Perempuan',
    email: 'zahraafitriana@gmail.com',
    phone: '089334212098',
    avatar: './assets/avatar_zahra.png',
    joinedDate: 'Agustus 2025'
  };

  function loadUserProfile(email, initialName) {
    const cleanEmail = (email || currentUser.email || '').toLowerCase();
    const key = `obesight_profile_data_${cleanEmail}`;
    const saved = localStorage.getItem(key);
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        userProfile = { ...userProfile, ...parsed };
      } catch (e) {
        console.error('Failed to parse user profile', e);
      }
    } else {
      // Find from registered users if exists
      const regUser = (registeredUsers || []).find(u => u.email && u.email.toLowerCase() === cleanEmail);
      const nameToUse = initialName || (regUser ? regUser.name : (cleanEmail.includes('zahra') ? 'Zahra Fitriana' : 'Pengguna'));
      const joinedToUse = (regUser && regUser.joinedDate) ? regUser.joinedDate : (cleanEmail.includes('zahra') ? 'Agustus 2025' : getCurrentMonthYearIndo());
      userProfile = {
        fullName: nameToUse,
        dob: cleanEmail.includes('zahra') ? '12 Juli 2003' : '',
        gender: cleanEmail.includes('zahra') ? 'Perempuan' : '',
        email: cleanEmail || 'zahraafitriana@gmail.com',
        phone: cleanEmail.includes('zahra') ? '089334212098' : '',
        avatar: './assets/avatar_zahra.png',
        joinedDate: joinedToUse
      };
    }
    renderUserProfileUI();
  }

  function saveUserProfile(email) {
    const cleanEmail = (email || currentUser.email || '').toLowerCase();
    const key = `obesight_profile_data_${cleanEmail}`;
    localStorage.setItem(key, JSON.stringify(userProfile));
    renderUserProfileUI();
  }

  function renderUserProfileUI() {
    // Profil Saya display elements
    const dispName = document.getElementById('profile-display-name');
    const dispEmail = document.getElementById('profile-display-email');
    const dispJoined = document.getElementById('profile-display-joined');
    const viewAvatar = document.getElementById('view-profile-avatar');
    const valName = document.getElementById('detail-val-name');
    const valDob = document.getElementById('detail-val-dob');
    const valGender = document.getElementById('detail-val-gender');
    const valEmail = document.getElementById('detail-val-email');
    const valPhone = document.getElementById('detail-val-phone');
    const topAvatar = document.getElementById('topbar-avatar-img');

    if (dispName) dispName.textContent = userProfile.fullName;
    if (dispEmail) dispEmail.textContent = userProfile.email;
    if (dispJoined) dispJoined.textContent = `Bergabung sejak ${userProfile.joinedDate || 'Agustus 2025'}`;
    if (viewAvatar) viewAvatar.src = userProfile.avatar || DEFAULT_AVATAR_PLACEHOLDER;
    if (topAvatar) topAvatar.src = userProfile.avatar || DEFAULT_AVATAR_PLACEHOLDER;
    if (valName) valName.textContent = userProfile.fullName || '-';
    if (valDob) valDob.textContent = userProfile.dob || '-';
    if (valGender) valGender.textContent = userProfile.gender || '-';
    if (valEmail) valEmail.textContent = userProfile.email || '-';
    if (valPhone) valPhone.textContent = userProfile.phone || '-';

    // Edit Profil inputs
    const inName = document.getElementById('input-edit-fullname');
    const inDob = document.getElementById('input-edit-dob');
    const inGender = document.getElementById('input-edit-gender');
    const inEmail = document.getElementById('input-edit-email');
    const inPhone = document.getElementById('input-edit-phone');
    const editAvatar = document.getElementById('edit-avatar-preview');

    if (inName) inName.value = userProfile.fullName || '';
    if (inDob) inDob.value = userProfile.dob || '';
    if (inGender) inGender.value = userProfile.gender || 'Perempuan';
    if (inEmail) inEmail.value = userProfile.email || '';
    if (inPhone) inPhone.value = userProfile.phone || '';
    if (editAvatar) editAvatar.src = userProfile.avatar || DEFAULT_AVATAR_PLACEHOLDER;

    // Update greeting on Home screen
    const greetingTitle = document.getElementById('greeting-title-text');
    if (greetingTitle) {
      const firstName = userProfile.fullName ? userProfile.fullName.trim().split(' ')[0] : 'Pengguna';
      greetingTitle.textContent = `Halo, ${firstName}! 👋`;
    }
  }

  let profileToastTimer = null;
  function showProfileToast(message) {
    const alertBox = document.getElementById('profile-toast-alert');
    const alertText = document.getElementById('profile-toast-text');
    if (!alertBox) return;

    if (alertText && message) alertText.textContent = message;
    alertBox.classList.remove('hidden');

    if (profileToastTimer) clearTimeout(profileToastTimer);
    profileToastTimer = setTimeout(() => {
      alertBox.classList.add('hidden');
    }, 3500);
  }

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
    const isComplete = getUserBiodataStatus(currentUser.email);
    if (banner) {
      if (isComplete) {
        banner.classList.add('hidden');
      } else {
        banner.classList.remove('hidden');
      }
    }
    updateDemoBadge();
  }

  function updateDemoBadge() {
    if (badgeBiodataStatus) {
      const isComplete = getUserBiodataStatus(currentUser.email);
      if (isComplete) {
        badgeBiodataStatus.textContent = '✅ Biodata: Lengkap';
        badgeBiodataStatus.style.color = '#4E9070';
      } else {
        badgeBiodataStatus.textContent = '⚠️ Biodata: Belum Lengkap';
        badgeBiodataStatus.style.color = '#F59E0B';
      }
    }
  }

  let previousScreenForArticle = 'home';

  function showScreen(screenName) {
    // Hide subpage overlays
    if (profileScreen) profileScreen.classList.add('hidden');
    if (editProfileScreen) editProfileScreen.classList.add('hidden');
    if (articleListScreen) articleListScreen.classList.add('hidden');
    if (articleDetailScreen) articleDetailScreen.classList.add('hidden');
    if (photoSheetBackdrop) photoSheetBackdrop.classList.add('hidden');
    if (cancelModalBackdrop) cancelModalBackdrop.classList.add('hidden');

    if (screenName === 'home') {
      if (splashScreen) splashScreen.style.display = 'none';
      if (authScreen) authScreen.classList.add('hidden');
      if (adminDash) adminDash.classList.add('hidden');
      if (userDash) {
        userDash.classList.remove('hidden');
        switchHomeTab('home');
      }
      if (statusBar) statusBar.classList.add('dark-text');
      updateReminderBannerVisibility();
    } else if (screenName === 'profile') {
      if (splashScreen) splashScreen.style.display = 'none';
      if (authScreen) authScreen.classList.add('hidden');
      if (adminDash) adminDash.classList.add('hidden');
      if (userDash) userDash.classList.add('hidden');
      if (profileScreen) profileScreen.classList.remove('hidden');
      if (statusBar) statusBar.classList.remove('dark-text');
      renderUserProfileUI();
    } else if (screenName === 'edit-profile') {
      if (splashScreen) splashScreen.style.display = 'none';
      if (authScreen) authScreen.classList.add('hidden');
      if (adminDash) adminDash.classList.add('hidden');
      if (userDash) userDash.classList.add('hidden');
      if (editProfileScreen) editProfileScreen.classList.remove('hidden');
      if (statusBar) statusBar.classList.remove('dark-text');
      renderUserProfileUI();
    } else if (screenName === 'article-list' || screenName === 'articles') {
      if (splashScreen) splashScreen.style.display = 'none';
      if (authScreen) authScreen.classList.add('hidden');
      if (adminDash) adminDash.classList.add('hidden');
      if (userDash) userDash.classList.add('hidden');
      if (articleListScreen) {
        articleListScreen.classList.remove('hidden');
        const scrollContainer = document.getElementById('article-list-scroll-container');
        if (scrollContainer) scrollContainer.scrollTop = 0;
      }
      if (statusBar) statusBar.classList.remove('dark-text');
      renderArticleCards();
    } else if (screenName === 'article-detail') {
      if (splashScreen) splashScreen.style.display = 'none';
      if (authScreen) authScreen.classList.add('hidden');
      if (adminDash) adminDash.classList.add('hidden');
      if (userDash) userDash.classList.add('hidden');
      if (articleDetailScreen) {
        articleDetailScreen.classList.remove('hidden');
        const scrollContainer = document.getElementById('article-detail-scroll-view');
        if (scrollContainer) scrollContainer.scrollTop = 0;
      }
      if (statusBar) statusBar.classList.remove('dark-text');
    }
    updateDemoBadge();
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
      loadUserProfile(email || 'zahraafitriana@gmail.com', name);
      showScreen('home');
      updateUserData(name || userProfile.fullName, email || userProfile.email);
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
      const joinedStr = getCurrentMonthYearIndo();
      registeredUsers.push({
        name: nameVal,
        email: emailVal,
        password: pwdVal,
        joinedDate: joinedStr
      });

      try {
        localStorage.setItem('obesight_registered_users', JSON.stringify(registeredUsers));
      } catch (err) { }

      // Initialize fresh user profile for newly registered user
      userProfile = {
        fullName: nameVal,
        dob: '',
        gender: 'Perempuan',
        email: emailVal,
        phone: '',
        avatar: './assets/avatar_zahra.png',
        joinedDate: joinedStr
      };
      saveUserProfile(emailVal);
      // New registered account initially has incomplete profile biodata
      setUserBiodataStatus(emailVal, false);

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

  // Profile Avatar Navigation to Profil Saya
  const btnProfileAvatar = document.getElementById('btn-profile-avatar');
  if (btnProfileAvatar) {
    btnProfileAvatar.addEventListener('click', (e) => {
      e.stopPropagation();
      showScreen('profile');
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
      userDash.classList.toggle('in-settings', targetTab === 'settings');
    }
    if (statusBar) {
      if (targetTab === 'stats' || targetTab === 'settings') {
        statusBar.classList.remove('dark-text');
      } else {
        statusBar.classList.add('dark-text');
      }
    }
    if (targetTab === 'stats') {
      switchMonitoringSubpage('main');
    }
    if (targetTab === 'settings') {
      switchSettingsSubpage('main');
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
  // SETTINGS (PENGATURAN) SUBPAGE NAVIGATION & CONTROLLER
  // ========================================================
  const settingsSubpages = {
    main: document.getElementById('settings-subpage-main'),
    email: document.getElementById('settings-subpage-email'),
    password: document.getElementById('settings-subpage-password'),
    info: document.getElementById('settings-subpage-info'),
    help: document.getElementById('settings-subpage-help'),
    about: document.getElementById('settings-subpage-about')
  };

  function switchSettingsSubpage(targetSubpage) {
    Object.keys(settingsSubpages).forEach(key => {
      const page = settingsSubpages[key];
      if (!page) return;
      const isTarget = key === targetSubpage;
      page.classList.toggle('hidden', !isTarget);
      page.classList.toggle('active', isTarget);
    });
  }

  // Header Back Buttons
  const btnSettingsBackHome = document.getElementById('btn-settings-back-home');
  if (btnSettingsBackHome) {
    btnSettingsBackHome.addEventListener('click', () => switchHomeTab('home'));
  }

  const btnBackFromEmail = document.getElementById('btn-back-from-email');
  if (btnBackFromEmail) {
    btnBackFromEmail.addEventListener('click', () => switchSettingsSubpage('main'));
  }

  const btnBackFromPassword = document.getElementById('btn-back-from-password');
  if (btnBackFromPassword) {
    btnBackFromPassword.addEventListener('click', () => switchSettingsSubpage('main'));
  }

  const btnBackFromInfo = document.getElementById('btn-back-from-info');
  if (btnBackFromInfo) {
    btnBackFromInfo.addEventListener('click', () => switchSettingsSubpage('main'));
  }

  const btnBackFromHelp = document.getElementById('btn-back-from-help');
  if (btnBackFromHelp) {
    btnBackFromHelp.addEventListener('click', () => switchSettingsSubpage('main'));
  }

  const btnBackFromAbout = document.getElementById('btn-back-from-about');
  if (btnBackFromAbout) {
    btnBackFromAbout.addEventListener('click', () => switchSettingsSubpage('main'));
  }

  // Sub-menu Navigation Rows
  const btnGotoPassword = document.getElementById('btn-goto-password');
  if (btnGotoPassword) {
    btnGotoPassword.addEventListener('click', () => {
      if (inputPwdOld) inputPwdOld.value = '';
      if (inputPwdNew) inputPwdNew.value = '';
      if (inputPwdConfirm) inputPwdConfirm.value = '';
      validatePasswordRules('');
      switchSettingsSubpage('password');
    });
  }

  const btnGotoEmail = document.getElementById('btn-goto-email');
  if (btnGotoEmail) {
    btnGotoEmail.addEventListener('click', () => {
      if (inputEmailCurrent) {
        inputEmailCurrent.value = currentUser?.email || 'zahraafitriana@gmail.com';
      }
      if (inputEmailNew) inputEmailNew.value = '';
      switchSettingsSubpage('email');
    });
  }

  const btnGotoInfo = document.getElementById('btn-goto-info');
  if (btnGotoInfo) {
    btnGotoInfo.addEventListener('click', () => switchSettingsSubpage('info'));
  }

  const btnGotoHelp = document.getElementById('btn-goto-help');
  if (btnGotoHelp) {
    btnGotoHelp.addEventListener('click', () => switchSettingsSubpage('help'));
  }

  const btnGotoAbout = document.getElementById('btn-goto-about');
  if (btnGotoAbout) {
    btnGotoAbout.addEventListener('click', () => switchSettingsSubpage('about'));
  }

  // Dark Mode Switch Toggle
  const toggleDarkMode = document.getElementById('toggle-dark-mode');
  const savedDarkMode = localStorage.getItem('obesight_dark_mode') === 'true';
  if (toggleDarkMode) {
    toggleDarkMode.checked = savedDarkMode;
    if (savedDarkMode) {
      document.body.classList.add('theme-dark');
      document.body.classList.remove('theme-light');
    }

    toggleDarkMode.addEventListener('change', (e) => {
      const isDark = e.target.checked;
      if (isDark) {
        document.body.classList.add('theme-dark');
        document.body.classList.remove('theme-light');
      } else {
        document.body.classList.remove('theme-dark');
        document.body.classList.add('theme-light');
      }
      localStorage.setItem('obesight_dark_mode', isDark);
      showToast('Mode Tampilan', isDark ? 'Mode Gelap diaktifkan' : 'Mode Terang diaktifkan');
    });
  }

  // Ubah Email Form Logic
  const inputEmailCurrent = document.getElementById('input-email-current');
  const inputEmailNew = document.getElementById('input-email-new');
  const btnSaveEmail = document.getElementById('btn-save-email');
  if (btnSaveEmail) {
    btnSaveEmail.addEventListener('click', () => {
      const newEmail = (inputEmailNew?.value || '').trim();
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!newEmail) {
        alert('Silakan masukkan email baru Anda');
        inputEmailNew?.focus();
        return;
      }
      if (!emailRegex.test(newEmail)) {
        alert('Format email tidak valid (contoh: nama@email.com)');
        inputEmailNew?.focus();
        return;
      }
      if (inputEmailCurrent && inputEmailCurrent.value.trim().toLowerCase() === newEmail.toLowerCase()) {
        alert('Email baru tidak boleh sama dengan email saat ini');
        inputEmailNew?.focus();
        return;
      }

      if (currentUser) {
        currentUser.email = newEmail;
      }
      if (inputEmailCurrent) inputEmailCurrent.value = newEmail;
      if (inputEmailNew) inputEmailNew.value = '';

      showToast('Email Diperbarui', 'Alamat email Anda berhasil diperbarui!');
      setTimeout(() => {
        switchSettingsSubpage('main');
      }, 900);
    });
  }

  // Ubah Kata Sandi Form & Live Validation
  const inputPwdOld = document.getElementById('input-pwd-old');
  const inputPwdNew = document.getElementById('input-pwd-new');
  const inputPwdConfirm = document.getElementById('input-pwd-confirm');
  const btnSavePassword = document.getElementById('btn-save-password');

  const chkPwdLen = document.getElementById('chk-pwd-len');
  const chkPwdDigit = document.getElementById('chk-pwd-digit');
  const chkPwdCase = document.getElementById('chk-pwd-case');

  function validatePasswordRules(pwd) {
    const isLenValid = pwd.length >= 8 && pwd.length <= 16;
    const isDigitValid = /[0-9]/.test(pwd);
    const isCaseValid = /[A-Z]/.test(pwd) && /[a-z]/.test(pwd);

    if (chkPwdLen) chkPwdLen.classList.toggle('valid', isLenValid);
    if (chkPwdDigit) chkPwdDigit.classList.toggle('valid', isDigitValid);
    if (chkPwdCase) chkPwdCase.classList.toggle('valid', isCaseValid);

    return isLenValid && isDigitValid && isCaseValid;
  }

  if (inputPwdNew) {
    inputPwdNew.addEventListener('input', (e) => {
      validatePasswordRules(e.target.value);
    });
  }

  // Password Visibility Toggles
  function setupPwdToggle(btnId, inputId) {
    const btn = document.getElementById(btnId);
    const input = document.getElementById(inputId);
    if (!btn || !input) return;

    btn.addEventListener('click', () => {
      const isPwd = input.type === 'password';
      input.type = isPwd ? 'text' : 'password';
      btn.innerHTML = isPwd
        ? `<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#489874" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
            <circle cx="12" cy="12" r="3" />
           </svg>`
        : `<svg class="icon-eye-closed" viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#6B7280" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z" />
            <circle cx="12" cy="12" r="3" />
           </svg>`;
    });
  }

  setupPwdToggle('btn-toggle-pwd-old', 'input-pwd-old');
  setupPwdToggle('btn-toggle-pwd-new', 'input-pwd-new');
  setupPwdToggle('btn-toggle-pwd-confirm', 'input-pwd-confirm');

  if (btnSavePassword) {
    btnSavePassword.addEventListener('click', () => {
      const oldPwd = inputPwdOld?.value || '';
      const newPwd = inputPwdNew?.value || '';
      const confirmPwd = inputPwdConfirm?.value || '';

      if (!oldPwd) {
        alert('Silakan masukkan kata sandi lama Anda.');
        inputPwdOld?.focus();
        return;
      }
      if (!validatePasswordRules(newPwd)) {
        alert('Kata sandi baru belum memenuhi semua kriteria keamanan.');
        inputPwdNew?.focus();
        return;
      }
      if (newPwd !== confirmPwd) {
        alert('Konfirmasi kata sandi baru tidak cocok.');
        inputPwdConfirm?.focus();
        return;
      }

      showToast('Kata Sandi Berhasil Diubah', 'Kata sandi akun Anda telah diperbarui.');
      if (inputPwdOld) inputPwdOld.value = '';
      if (inputPwdNew) inputPwdNew.value = '';
      if (inputPwdConfirm) inputPwdConfirm.value = '';
      validatePasswordRules('');

      setTimeout(() => {
        switchSettingsSubpage('main');
      }, 900);
    });
  }

  // Modal Hapus Akun
  const btnTriggerDeleteAccount = document.getElementById('btn-trigger-delete-account');
  const modalDeleteAccount = document.getElementById('modal-delete-account');
  const btnCancelDeleteAccount = document.getElementById('btn-cancel-delete-account');
  const btnConfirmDeleteAccount = document.getElementById('btn-confirm-delete-account');

  if (btnTriggerDeleteAccount && modalDeleteAccount) {
    btnTriggerDeleteAccount.addEventListener('click', () => {
      modalDeleteAccount.classList.remove('hidden');
    });
  }

  if (btnCancelDeleteAccount && modalDeleteAccount) {
    btnCancelDeleteAccount.addEventListener('click', () => {
      modalDeleteAccount.classList.add('hidden');
    });
  }

  if (btnConfirmDeleteAccount && modalDeleteAccount) {
    btnConfirmDeleteAccount.addEventListener('click', () => {
      modalDeleteAccount.classList.add('hidden');
      localStorage.removeItem('obesight_registered_users');
      localStorage.removeItem('obesight_monitoring_progress');
      showToast('Akun Dihapus', 'Data akun Anda telah berhasil dihapus.');
      setTimeout(() => {
        performLogout();
      }, 1000);
    });
  }

  // Modal Logout dari Seksi 4 Pengaturan
  const btnSettingsLogoutAction = document.getElementById('btn-settings-logout-action');
  const modalLogoutConfirm = document.getElementById('modal-logout-confirm');
  const btnCancelLogout = document.getElementById('btn-cancel-logout');
  const btnConfirmLogout = document.getElementById('btn-confirm-logout');

  if (btnSettingsLogoutAction && modalLogoutConfirm) {
    btnSettingsLogoutAction.addEventListener('click', () => {
      modalLogoutConfirm.classList.remove('hidden');
    });
  }

  if (btnCancelLogout && modalLogoutConfirm) {
    btnCancelLogout.addEventListener('click', () => {
      modalLogoutConfirm.classList.add('hidden');
    });
  }

  if (btnConfirmLogout && modalLogoutConfirm) {
    btnConfirmLogout.addEventListener('click', () => {
      modalLogoutConfirm.classList.add('hidden');
      performLogout();
    });
  }

  // ========================================================
  // MONITORING SUBPAGE NAVIGATION & INTERACTIONS
  // ========================================================
  // UNIFIED PROGRESS & MONITORING SUBPAGE CONTROLLER
  // ========================================================
  const monitoringSubpages = {
    main: document.getElementById('monitoring-subpage-main'),
    progress: document.getElementById('monitoring-subpage-progress'),
    riwayat: document.getElementById('monitoring-subpage-riwayat')
  };

  const progressSubviews = {
    landing: document.getElementById('progress-subview-landing'),
    recommendation: document.getElementById('progress-subview-recommendation'),
    detail: document.getElementById('progress-subview-detail'),
    timer: document.getElementById('progress-subview-timer')
  };

  let progressEntryOrigin = 'monitoring'; // 'home' | 'monitoring'
  let activeActivityId = 'jogging';

  function switchMonitoringSubpage(targetSubpage) {
    Object.keys(monitoringSubpages).forEach(key => {
      const page = monitoringSubpages[key];
      if (!page) return;
      const isTarget = key === targetSubpage;
      page.classList.toggle('hidden', !isTarget);
      page.classList.toggle('active', isTarget);
    });

    if (targetSubpage !== 'progress' && userDash) {
      userDash.classList.remove('hide-floating-nav');
    }
  }

  function showProgressSubView(targetView) {
    if (targetView !== 'timer' && isTimerRunning) {
      pauseCountdown();
    }

    Object.keys(progressSubviews).forEach(key => {
      const v = progressSubviews[key];
      if (!v) return;
      const isTarget = key === targetView;
      v.classList.toggle('hidden', !isTarget);
    });

    // Hide bottom nav on detail & timer screens for full-screen focus
    const shouldHideNav = (targetView === 'detail' || targetView === 'timer');
    if (userDash) {
      userDash.classList.toggle('hide-floating-nav', shouldHideNav);
    }

    if (targetView === 'recommendation') {
      initRecommendationDateScroller();
    }
  }

  function openProgressFeature(origin = 'monitoring') {
    progressEntryOrigin = origin;

    if (userDash) {
      userDash.classList.add('in-monitoring');
      userDash.classList.remove('in-settings');
      userDash.classList.remove('hide-floating-nav');
    }
    if (statusBar) {
      statusBar.classList.remove('dark-text');
    }

    navBtns.forEach(item => {
      if (!item.btn || !item.content) return;
      const isActive = item.tab === 'stats';
      item.btn.classList.toggle('active', isActive);
      item.content.classList.toggle('hidden', !isActive);
      item.content.classList.toggle('active', isActive);
    });

    switchMonitoringSubpage('progress');
    showProgressSubView('landing');
  }

  // Header Back Buttons
  const btnBackToHome = document.getElementById('btn-back-to-home');
  if (btnBackToHome) {
    btnBackToHome.addEventListener('click', () => switchHomeTab('home'));
  }

  const btnBackFromProgress = document.getElementById('btn-back-from-progress');
  if (btnBackFromProgress) {
    btnBackFromProgress.addEventListener('click', () => {
      if (progressEntryOrigin === 'home') {
        switchHomeTab('home');
      } else {
        switchMonitoringSubpage('main');
      }
    });
  }

  const btnBackFromRecommendation = document.getElementById('btn-back-from-recommendation');
  if (btnBackFromRecommendation) {
    btnBackFromRecommendation.addEventListener('click', () => {
      showProgressSubView('landing');
    });
  }

  const btnBackFromDetail = document.getElementById('btn-back-from-detail');
  if (btnBackFromDetail) {
    btnBackFromDetail.addEventListener('click', () => {
      showProgressSubView('recommendation');
    });
  }

  const btnBackFromTimer = document.getElementById('btn-back-from-timer');
  if (btnBackFromTimer) {
    btnBackFromTimer.addEventListener('click', () => {
      cancelTimer();
    });
  }

  const btnBackFromRiwayat = document.getElementById('btn-back-from-riwayat');
  if (btnBackFromRiwayat) {
    btnBackFromRiwayat.addEventListener('click', () => switchMonitoringSubpage('main'));
  }

  // Monitoring Main Menu Cards
  const btnOpenProgress = document.getElementById('btn-open-progress');
  if (btnOpenProgress) {
    btnOpenProgress.addEventListener('click', () => openProgressFeature('monitoring'));
  }

  const btnOpenRiwayat = document.getElementById('btn-open-riwayat');
  if (btnOpenRiwayat) {
    btnOpenRiwayat.addEventListener('click', () => switchMonitoringSubpage('riwayat'));
  }

  // Landing Progress Cards & Buttons
  const btnQuickMakananku = document.getElementById('btn-quick-makananku');
  if (btnQuickMakananku) {
    btnQuickMakananku.addEventListener('click', () => {
      showToast('Fitur Segera Hadir', 'Fitur Makananku sedang dalam tahap pengembangan.');
    });
  }

  const btnQuickMinumanku = document.getElementById('btn-quick-minumanku');
  if (btnQuickMinumanku) {
    btnQuickMinumanku.addEventListener('click', () => {
      showToast('Fitur Segera Hadir', 'Fitur Minumanku sedang dalam tahap pengembangan.');
    });
  }

  const btnProgressMenuMakanan = document.getElementById('btn-progress-menu-makanan');
  if (btnProgressMenuMakanan) {
    btnProgressMenuMakanan.addEventListener('click', () => {
      showToast('Fitur Segera Hadir', 'Fitur Makanan & Minuman sedang dalam tahap pengembangan.');
    });
  }

  const btnProgressMenuAktivitas = document.getElementById('btn-progress-menu-aktivitas');
  if (btnProgressMenuAktivitas) {
    btnProgressMenuAktivitas.addEventListener('click', () => {
      showProgressSubView('recommendation');
    });
  }

  const btnProgressMenuIstirahat = document.getElementById('btn-progress-menu-istirahat');
  if (btnProgressMenuIstirahat) {
    btnProgressMenuIstirahat.addEventListener('click', () => {
      showToast('Fitur Segera Hadir', 'Fitur Waktu Istirahat sedang dalam tahap pengembangan.');
    });
  }

  // ========================================================
  // REAL-TIME DATE SCROLLER (AUTO-GENERATED BASED ON NEW DATE)
  // ========================================================
  const recDateScrollerContainer = document.getElementById('recommendation-date-scroller');
  function initRecommendationDateScroller() {
    if (!recDateScrollerContainer) return;
    recDateScrollerContainer.innerHTML = '';

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', "Jum'at", 'Sabtu'];

    // Menampilkan 7 hari sebelum hari ini, hari ini, dan 13 hari setelah hari ini
    for (let offset = -7; offset <= 13; offset++) {
      const d = new Date(today);
      d.setDate(today.getDate() + offset);

      const dayOfWeek = dayNames[d.getDay()];
      const dateStr = `${d.getDate()}/${d.getMonth() + 1}/${String(d.getFullYear()).slice(-2)}`;

      const pill = document.createElement('div');
      pill.className = 'rec-date-pill';
      pill.dataset.date = dateStr;

      if (offset < 0) {
        // Tanggal yang sudah lewat (kemarin dan sebelumnya) -> Merah, Teks Putih
        pill.classList.add('pill-past-red');
        pill.innerHTML = `
          <span class="rec-date-pill-day">${dayOfWeek}</span>
          <span class="rec-date-pill-num">${dateStr}</span>
        `;
      } else if (offset === 0) {
        // Tanggal hari ini -> Hijau Pastel
        pill.classList.add('pill-today-green');
        pill.classList.add('selected');
        pill.innerHTML = `
          <span class="rec-date-pill-day">Hari ini</span>
          <span class="rec-date-pill-num">${dateStr}</span>
        `;
      } else {
        // Tanggal besok dan seterusnya -> Putih dengan Border Tipis Abu-abu
        pill.classList.add('pill-future-white');
        pill.innerHTML = `
          <span class="rec-date-pill-day">${dayOfWeek}</span>
          <span class="rec-date-pill-num">${dateStr}</span>
        `;
      }

      pill.addEventListener('click', () => {
        document.querySelectorAll('.rec-date-pill').forEach(p => p.classList.remove('selected'));
        pill.classList.add('selected');
      });

      recDateScrollerContainer.appendChild(pill);
    }

    setTimeout(() => {
      const todayPill = recDateScrollerContainer.querySelector('.rec-date-pill.pill-today-green');
      if (todayPill) {
        todayPill.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
      }
    }, 120);
  }

  // ========================================================
  // DATA DICTIONARY 5 AKTIVITAS FISIK
  // ========================================================
  const activitiesData = {
    jogging: {
      id: 'jogging',
      title: 'Jogging',
      targetText: '30-60 menit',
      heroImg: './assets/progress/clean/hero_jogging.png',
      thumbImg: './assets/progress/clean/thumb_jogging.png',
      iconSvg: '<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="5" r="2"/><path d="M10 22l4-8 2 2 3 4"/><path d="M4 17l5-4 3 2 4-6"/></svg>',
      aboutTitle: 'Tentang Jogging',
      aboutDesc: 'Jogging merupakan salah satu jenis latihan aerobik yang dapat meningkatkan kebugaran kardiorespirasi, membantu pembakaran kalori, serta mendukung penurunan berat badan. Aktivitas ini juga berkontribusi pada peningkatan kesehatan jantung dan metabolisme tubuh.',
      quote: 'Berdasarkan penilitan Komala, Riyadi, & Setiawan (2016), latihan aerobik seperti jogging dengan intesntias sedang hingga berat terbukti dapat memperbaiki VO2max, indeks masa tubuh (IMT), dan presentase lemak tubuh pada remaja obesitas',
      benefits: [
        'Meningkatkan kebugaran jantung dan paru-paru',
        'Membantu pembakaran kalori dan lemak tubuh',
        'Menurunkan berat badan',
        'Meningkatkan suasana hati dan mengurangi stres'
      ],
      specs: {
        duration: '30-60 menit',
        frequency: '3-5 kali/minggu',
        intensity: 'Sedang (60-70% HRmax)',
        calories: '200-400 kkal'
      },
      tipsTitle: 'Tips Melakukan Jogging',
      tips: [
        'Lakukan pemanasan selama 5-10 menit sebelum mulai.',
        'Gunakan sepatu yang nyaman dan sesuai',
        'Jaga postur tubuh tetap tegak dan rileks',
        'Tingkatkan durasi dan intensitas secara bertahap',
        'Pastikan tubuh tetap terhidrasi'
      ],
      refLink: 'https://doi.org/10.25182/jgp.2016.11.3.%25p'
    },
    bodyweight: {
      id: 'bodyweight',
      title: 'Latihan Bodyweight',
      targetText: '20-45 menit',
      heroImg: './assets/progress/clean/hero_bodyweight.png',
      thumbImg: './assets/progress/clean/thumb_bodyweight.png',
      iconSvg: '<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 5v14M18 5v14M2 9v6M22 9v6M6 12h12"/></svg>',
      aboutTitle: 'Tentang Latihan Bodyweight',
      aboutDesc: 'Latihan kekuatan (strength training) adalah aktivitas fisik yang melibatkan kontraksi otot untuk meningkatkan massa otot, kekuatan, dan daya tahan tubuh. Latihan ini dapat dilakukan dengan menggunakan berat badan sendiri (bodyweight) atau alat beban (gym/fitness). Selain membantu membentuk tubuh, latihan kekuatan juga berperan dalam meningkatkan metabolisme istirahat dan menjaga kesehatan tulang.',
      quote: 'Berdasarkan pedoman WHO, latihan penguatan otot sebaiknya dilakukan minimal 2 hari per minggu untuk semua kelompok usia dewasa bersama dengan aktivitas aerobik. (World Health Organization, 2020)',
      benefits: [
        'Meningkatkan massa dan kekuatan otot',
        'Mempercepat metabolisme tubuh',
        'Meningkatkan kepadatan tulang',
        'Memperbaiki postur tubuh dan keseimbangan'
      ],
      specs: {
        duration: '20-45 menit',
        frequency: '2-4 kali/minggu',
        intensity: 'Sedang-Tinggi (60-80% HRmax)',
        calories: '150-350 kkal'
      },
      tipsTitle: 'Tips Melakukan Bodyweight',
      tips: [
        'Lakukan pemanasan selama 5-10 menit sebelum mulai.',
        'Fokus pada gerakan yang benar dan kontrol penuh',
        'Mulai dengan beban atau intensitas yang sesuai kemampuan',
        'Istirahat antar set 30-60 detik',
        'Lakukan pendinginan dan peregangan setelah latihan'
      ],
      refLink: 'https://doi.org/10.21831/jk.v8i1.31208'
    },
    cycling: {
      id: 'cycling',
      title: 'Bersepeda',
      targetText: '30-60 menit',
      heroImg: './assets/progress/clean/hero_cycling.png',
      thumbImg: './assets/progress/clean/thumb_cycling.png',
      iconSvg: '<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="5.5" cy="17.5" r="3.5"/><circle cx="18.5" cy="17.5" r="3.5"/><path d="M15 6a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm-3 11.5L9 9l3-3 3 4 3.5 2"/></svg>',
      aboutTitle: 'Tentang Bersepeda',
      aboutDesc: 'Bersepeda merupakan salah satu bentuk aktivitas aerobik yang dapat membantu meningkatkan kebugaran kardiorespirasi. Aktivitas ini melibatkan kerja otot tubuh secara berulang dan dapat dilakukan dengan berbagai tingkat intensitas. Penelitian pada atlet balap sepeda menunjukkan bahwa intensitas latihan berkaitan dengan perubahan berat badan dan persentase lemak tubuh.',
      quote: 'Pribadi (2015) membahas program latihan aerobik untuk kebugaran paru dan jantung. Bersepeda termasuk salah satu jenis latihan aerobik yang direkomendasikan dalam artikel tersebut.',
      benefits: [
        'Meningkatkan kebugaran jantung dan paru',
        'Membantu pembakaran energi dan lemak tubuh',
        'Melatih kekuatan dan daya tahan otot tungkai',
        'Meningkatkan kapasitas kardiorespirasi'
      ],
      specs: {
        duration: '30-60 menit',
        frequency: '3-5 kali/minggu',
        intensity: 'Sedang (50-70% HRmax)',
        calories: '200-400 kkal'
      },
      tipsTitle: 'Tips Melakukan Bersepeda',
      tips: [
        'Pastikan sepeda dalam posisi baik dan sesuai ukuran tubuh.',
        'Gunakan perlengkapan keselamatan seperti helm',
        'Mulai dengan intensitas ringan, lalu tingkatkan secara bertahap',
        'Jaga postur tubuh tetap tegak dan rileks',
        'Pilih rute yang aman dan hindari jalan yang terlalu ramai'
      ],
      refLink: 'https://doi.org/10.21831/medikora.v14i2.7937'
    },
    yoga: {
      id: 'yoga',
      title: 'Yoga',
      targetText: '20-40 menit',
      heroImg: './assets/progress/clean/hero_yoga.png',
      thumbImg: './assets/progress/clean/thumb_yoga.png',
      iconSvg: '<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="4" r="2"/><path d="M5 20l4-7 3 2 3-2 4 7"/><path d="M4 12l5-2 3 3 3-3 5 2"/></svg>',
      aboutTitle: 'Tentang Yoga',
      aboutDesc: 'Yoga dan stretching merupakan bentuk aktivitas fisik yang menggabungkan latihan pernapasan, gerakan tubuh, dan relaksasi. Aktivitas ini membantu meningkatkan fleksibilitas, keseimbangan, serta kekuatan otot, sekaligus dapat berkontribusi dalam mengurangi stres dan meningkatkan kesehatan mental.',
      quote: 'Penelitian di Indonesia menunjukkan bahwa senam yoga dapat membantu menurunkan tingkat stres pada remaja serta memberikan manfaat terhadap kesejahteraan psikologis. (Aini et al., 2020; Widiastuti et al., 2022)',
      benefits: [
        'Meningkatkan fleksibilitas dan keseimbangan',
        'Mendukung kesehatan mental dan emosional',
        'Mengurangi stres dan kecemasan',
        'Memperkuat otot dan tulang'
      ],
      specs: {
        duration: '20-40 menit',
        frequency: '3-5 kali/minggu',
        intensity: 'Ringan-Sedang (40-60% HRmax)',
        calories: '150-300 kkal'
      },
      tipsTitle: 'Tips Melakukan Yoga',
      tips: [
        'Lakukan gerakan secara perlahan dan fokus pada pernapasan.',
        'Gunakan pakaian yang nyaman dan tidak membatasi gerak.',
        'Pilih tempat yang tenang dan aman.',
        'Lakukan secara rutin agar manfaatnya lebih optimal.',
        'Jika baru pertama kali melakukan yoga, ikuti panduan instruktur atau sumber yang terpercaya.'
      ],
      refLink: 'https://doi.org/10.48144/jiks.v9i2.56'
    },
    hiit: {
      id: 'hiit',
      title: 'High-Intensity Interval Training',
      targetText: '15-30 menit',
      heroImg: './assets/progress/clean/hero_hiit.png',
      thumbImg: './assets/progress/clean/thumb_hiit.png',
      iconSvg: '<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>',
      aboutTitle: 'Tentang HIIT',
      aboutDesc: 'High-Intensity Interval Training (HIIT) merupakan metode latihan yang menggabungkan periode aktivitas dengan intensitas tinggi dan periode pemulihan secara bergantian. Latihan ini dapat dilakukan menggunakan berbagai gerakan seperti lari, jumping jack, squat, mountain climber, atau burpee. HIIT dapat menjadi salah satu pilihan aktivitas fisik bagi orang yang memiliki waktu terbatas karena latihan dilakukan dalam interval dengan intensitas yang lebih tinggi.',
      quote: 'Penelitian pada remaja dengan kategori overweight menunjukkan bahwa running high-intensity interval training yang dilakukan 3 kali seminggu selama 4 minggu dapat menurunkan persentase lemak tubuh secara signifikan.',
      benefits: [
        'Membantu meningkatkan kebugaran kardiorespirasi',
        'Membantu meningkatkan pembakaran energi',
        'Membantu menurunkan persentase lemak tubuh',
        'Meningkatkan daya tahan tubuh'
      ],
      specs: {
        duration: '15-30 menit',
        frequency: '2-4 kali/minggu',
        intensity: 'Tinggi (70-90% HRmax)',
        calories: '250-450 kkal'
      },
      tipsTitle: 'Tips Melakukan HIIT',
      tips: [
        'Lakukan pemanasan selama 5–10 menit sebelum memulai latihan.',
        'Mulai dengan gerakan dan intensitas yang sesuai dengan kemampuan tubuh.',
        'Berikan waktu pemulihan di antara interval latihan.',
        'Pertahankan teknik gerakan yang benar untuk mengurangi risiko cedera.',
        'Tingkatkan intensitas latihan secara bertahap.'
      ],
      refLink: 'https://doi.org/10.12928/dpphj.v17i2.8469'
    }
  };

  function openActivityDetail(activityId) {
    const act = activitiesData[activityId];
    if (!act) return;
    activeActivityId = activityId;

    const heroImg = document.getElementById('activity-detail-hero-img');
    if (heroImg) heroImg.src = act.heroImg;

    const badgeIcon = document.getElementById('activity-detail-badge-icon');
    if (badgeIcon) badgeIcon.innerHTML = act.iconSvg;

    const badgeTitle = document.getElementById('activity-detail-badge-title');
    if (badgeTitle) badgeTitle.textContent = act.title;

    const aboutTitle = document.getElementById('activity-detail-about-title');
    if (aboutTitle) aboutTitle.textContent = act.aboutTitle;

    const aboutDesc = document.getElementById('activity-detail-about-desc');
    if (aboutDesc) aboutDesc.textContent = act.aboutDesc;

    const quoteText = document.getElementById('activity-detail-quote-text');
    if (quoteText) quoteText.textContent = act.quote;

    const benefitsGrid = document.getElementById('activity-detail-benefits-grid');
    if (benefitsGrid) {
      benefitsGrid.innerHTML = act.benefits.map(b => `
        <div class="detail-benefit-item">
          <div class="detail-benefit-icon">
            <svg viewBox="0 0 24 24" width="12" height="12" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
          </div>
          <span class="detail-benefit-text">${b}</span>
        </div>
      `).join('');
    }

    const specDur = document.getElementById('spec-duration');
    if (specDur) specDur.textContent = act.specs.duration;
    const specFreq = document.getElementById('spec-frequency');
    if (specFreq) specFreq.textContent = act.specs.frequency;
    const specIntens = document.getElementById('spec-intensity');
    if (specIntens) specIntens.textContent = act.specs.intensity;
    const specCal = document.getElementById('spec-calories');
    if (specCal) specCal.textContent = act.specs.calories;

    const tipsTitle = document.getElementById('activity-detail-tips-title');
    if (tipsTitle) tipsTitle.textContent = act.tipsTitle;

    const tipsList = document.getElementById('activity-detail-tips-list');
    if (tipsList) {
      tipsList.innerHTML = act.tips.map(t => `<li class="detail-tips-item">${t}</li>`).join('');
    }

    const refSection = document.getElementById('activity-detail-ref-section');
    const refLink = document.getElementById('activity-detail-ref-link');
    if (refLink) {
      if (act.refLink) {
        refLink.href = act.refLink;
        refLink.textContent = act.refLink;
        if (refSection) refSection.style.display = 'block';
      } else {
        if (refSection) refSection.style.display = 'none';
      }
    }

    showProgressSubView('detail');
  }

  // Click listeners on 5 Activity Cards in Recommendation View
  const recActivityCards = document.querySelectorAll('.rec-activity-card');
  recActivityCards.forEach(card => {
    card.addEventListener('click', () => {
      const actId = card.getAttribute('data-activity-id');
      if (actId) openActivityDetail(actId);
    });
  });

  // Click listener for "Mulai" button on Detail Page -> opens Timer
  const btnStartActivityTimer = document.getElementById('btn-start-activity-timer');
  if (btnStartActivityTimer) {
    btnStartActivityTimer.addEventListener('click', () => {
      openActivityTimer(activeActivityId);
    });
  }

  // ========================================================
  // TIMER COUNTDOWN ENGINE (SCROLL PICKER & STACKED NUMBERS)
  // ========================================================
  const WHEEL_ITEM_HEIGHT = 42;
  const wheelMinutes = [];
  for (let m = 5; m <= 90; m++) {
    wheelMinutes.push(m);
  }

  let timerDurationSec = 1800; // default 30 menit
  let remainingSec = 1800;
  let timerInterval = null;
  let isTimerRunning = false;
  let isWheelPickerInit = false;
  const CIRCLE_CIRCUMFERENCE = 640.88; // 2 * Math.PI * 102

  const timerWheelScroller = document.getElementById('timer-wheel-scroller');
  const timerWheelContainer = document.getElementById('timer-wheel-container');

  function formatMMSS(totalSeconds) {
    const safeSec = Math.max(0, Math.floor(totalSeconds));
    const m = Math.floor(safeSec / 60);
    const s = safeSec % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }

  function updateTimerUI() {
    const numTop = document.getElementById('timer-num-top');
    const numMain = document.getElementById('timer-num-main');
    const numBottom = document.getElementById('timer-num-bottom');
    const circle = document.getElementById('timer-indicator-circle');
    const playIcon = document.getElementById('timer-play-icon');

    // Rule 2: Baris atas selalu '59:59', baris bawah selalu '00:00' (batas visual dekoratif)
    if (numTop) {
      numTop.textContent = '59:59';
    }
    if (numBottom) {
      numBottom.textContent = '00:00';
    }

    // Baris tengah (bold, hitam, paling jelas) = durasi terpilih / remaining countdown
    if (numMain) {
      const displaySec = isTimerRunning || remainingSec < timerDurationSec ? remainingSec : timerDurationSec;
      numMain.textContent = formatMMSS(displaySec > 0 ? displaySec : timerDurationSec);
    }

    if (circle) {
      if (timerDurationSec > 0) {
        const fraction = remainingSec / timerDurationSec;
        const offset = CIRCLE_CIRCUMFERENCE * (1 - fraction);
        circle.style.strokeDashoffset = offset;
      } else {
        circle.style.strokeDashoffset = 0;
      }
    }

    if (playIcon) {
      if (isTimerRunning) {
        // Pause Icon
        playIcon.innerHTML = '<rect x="6" y="4" width="4" height="16" rx="1"/><rect x="14" y="4" width="4" height="16" rx="1"/>';
      } else {
        // Play Icon
        playIcon.innerHTML = '<polygon points="6 4 20 12 6 20 6 4"></polygon>';
      }
    }

    if (timerWheelContainer) {
      timerWheelContainer.classList.toggle('disabled', isTimerRunning);
    }
  }

  function initTimerWheelPicker() {
    if (isWheelPickerInit || !timerWheelScroller) return;
    isWheelPickerInit = true;

    timerWheelScroller.innerHTML = '';

    // Spacer atas agar item pertama bisa tepat berada di tengah
    const topSpacer = document.createElement('div');
    topSpacer.className = 'timer-wheel-spacer';
    timerWheelScroller.appendChild(topSpacer);

    wheelMinutes.forEach(m => {
      const item = document.createElement('div');
      item.className = 'timer-wheel-item';
      item.dataset.minute = String(m);
      item.textContent = String(m);

      item.addEventListener('click', () => {
        if (isTimerRunning) return;
        selectWheelMinute(m, true);
      });

      timerWheelScroller.appendChild(item);
    });

    // Spacer bawah agar item terakhir bisa tepat berada di tengah
    const bottomSpacer = document.createElement('div');
    bottomSpacer.className = 'timer-wheel-spacer';
    timerWheelScroller.appendChild(bottomSpacer);

    let scrollDebounceTimer = null;
    timerWheelScroller.addEventListener('scroll', () => {
      if (isTimerRunning) return;

      const scrollTop = timerWheelScroller.scrollTop;
      const activeIdx = Math.round(scrollTop / WHEEL_ITEM_HEIGHT);
      const safeIdx = Math.max(0, Math.min(wheelMinutes.length - 1, activeIdx));
      const activeMin = wheelMinutes[safeIdx];

      const allItems = timerWheelScroller.querySelectorAll('.timer-wheel-item');
      allItems.forEach((it, idx) => {
        it.classList.toggle('active', idx === safeIdx);
      });

      timerDurationSec = activeMin * 60;
      remainingSec = timerDurationSec;
      updateTimerUI();

      // Debounced magnetic alignment snap
      clearTimeout(scrollDebounceTimer);
      scrollDebounceTimer = setTimeout(() => {
        if (!isTimerRunning && timerWheelScroller) {
          const targetTop = safeIdx * WHEEL_ITEM_HEIGHT;
          if (Math.abs(timerWheelScroller.scrollTop - targetTop) > 1) {
            timerWheelScroller.scrollTo({ top: targetTop, behavior: 'smooth' });
          }
        }
      }, 150);
    });
  }

  function selectWheelMinute(minute, smooth = true) {
    initTimerWheelPicker();
    const idx = wheelMinutes.indexOf(minute);
    if (idx === -1 || !timerWheelScroller) return;

    timerWheelScroller.scrollTo({
      top: idx * WHEEL_ITEM_HEIGHT,
      behavior: smooth ? 'smooth' : 'auto'
    });

    const allItems = timerWheelScroller.querySelectorAll('.timer-wheel-item');
    allItems.forEach((it, i) => {
      it.classList.toggle('active', i === idx);
    });

    timerDurationSec = minute * 60;
    remainingSec = timerDurationSec;
    updateTimerUI();
  }

  function startCountdown() {
    if (timerDurationSec <= 0) {
      selectWheelMinute(30, false);
    }
    if (remainingSec <= 0) {
      remainingSec = timerDurationSec;
    }
    isTimerRunning = true;
    updateTimerUI();

    if (timerInterval) clearInterval(timerInterval);
    timerInterval = setInterval(() => {
      if (remainingSec > 0) {
        remainingSec--;
        updateTimerUI();
        if (remainingSec <= 0) {
          clearInterval(timerInterval);
          timerInterval = null;
          isTimerRunning = false;
          updateTimerUI();
          onTimerComplete();
        }
      }
    }, 1000);
  }

  function pauseCountdown() {
    if (timerInterval) {
      clearInterval(timerInterval);
      timerInterval = null;
    }
    isTimerRunning = false;
    updateTimerUI();
  }

  function toggleTimerPlay() {
    if (isTimerRunning) {
      pauseCountdown();
    } else {
      startCountdown();
    }
  }

  function onTimerComplete() {
    const act = activitiesData[activeActivityId];
    showToast('Selamat!', `Aktivitas ${act ? act.title : ''} selesai! Tetap konsisten menjaga pola hidup sehat.`);
    showProgressSubView('recommendation');
  }

  function finishTimerEarly() {
    pauseCountdown();
    const act = activitiesData[activeActivityId];
    showToast('Aktivitas Disimpan', `Sesi ${act ? act.title : 'aktivitas'} berhasil diselesaikan.`);
    showProgressSubView('recommendation');
  }

  function cancelTimer() {
    pauseCountdown();
    showProgressSubView('detail');
  }

  function openActivityTimer(activityId) {
    const act = activitiesData[activityId];
    if (!act) return;
    activeActivityId = activityId;

    const timerHeroImg = document.getElementById('activity-timer-hero-img');
    if (timerHeroImg) timerHeroImg.src = act.heroImg;

    const timerBadgeIcon = document.getElementById('activity-timer-badge-icon');
    if (timerBadgeIcon) timerBadgeIcon.innerHTML = act.iconSvg;

    const timerBadgeTitle = document.getElementById('activity-timer-badge-title');
    if (timerBadgeTitle) timerBadgeTitle.textContent = act.title;

    const targetVal = document.getElementById('timer-target-duration-val');
    if (targetVal) targetVal.textContent = act.targetText;

    // Reset ke kondisi awal paused
    pauseCountdown();

    initTimerWheelPicker();

    // Default durasi berdasarkan rekomendasi aktivitas (misal HIIT 20 menit, yang lain 30 menit)
    const defaultMin = activityId === 'hiit' ? 20 : 30;
    setTimeout(() => {
      selectWheelMinute(defaultMin, false);
    }, 50);

    updateTimerUI();
    showProgressSubView('timer');
  }

  // Play / Pause Toggle button
  const btnTimerPlayToggle = document.getElementById('btn-timer-play-toggle');
  if (btnTimerPlayToggle) {
    btnTimerPlayToggle.addEventListener('click', toggleTimerPlay);
  }

  // Finish Activity button
  const btnTimerFinishAction = document.getElementById('btn-timer-finish-action');
  if (btnTimerFinishAction) {
    btnTimerFinishAction.addEventListener('click', finishTimerEarly);
  }

  // Cancel button
  const btnTimerCancelAction = document.getElementById('btn-timer-cancel-action');
  if (btnTimerCancelAction) {
    btnTimerCancelAction.addEventListener('click', cancelTimer);
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

  // Profil Saya & Edit Profil Navigation and Handlers
  const btnReminderBiodata = document.getElementById('btn-reminder-biodata');
  const btnBackFromProfile = document.getElementById('btn-back-from-profile');
  const btnGotoEditProfile = document.getElementById('btn-goto-edit-profile');
  const btnBackFromEdit = document.getElementById('btn-back-from-edit');
  const btnCancelStay = document.getElementById('btn-cancel-stay');
  const btnCancelSave = document.getElementById('btn-cancel-save');
  const btnSubmitEditProfile = document.getElementById('btn-submit-edit-profile');
  const btnCloseProfileToast = document.getElementById('btn-close-profile-toast');

  // Photo change & Bottom Sheet elements
  const btnBadgeChangePhoto = document.getElementById('btn-badge-change-photo');
  const btnTextChangePhoto = document.getElementById('btn-text-change-photo');
  const btnClosePhotoSheet = document.getElementById('btn-close-photo-sheet');
  const btnCancelPhotoSheet = document.getElementById('btn-cancel-photo-sheet');
  const optTakePhoto = document.getElementById('opt-take-photo');
  const optChooseGallery = document.getElementById('opt-choose-gallery');
  const optDeletePhoto = document.getElementById('opt-delete-photo');
  const inputCameraCapture = document.getElementById('input-camera-capture');
  const inputGalleryPick = document.getElementById('input-gallery-pick');

  // Bottom Navigation from Profil Saya & Edit Profil
  const profileNavHome = document.getElementById('profile-nav-home');
  const profileNavStats = document.getElementById('profile-nav-stats');
  const profileNavSettings = document.getElementById('profile-nav-settings');
  const editNavHome = document.getElementById('edit-nav-home');
  const editNavStats = document.getElementById('edit-nav-stats');
  const editNavSettings = document.getElementById('edit-nav-settings');

  // 1. Tapping reminder card in Beranda opens Profil Saya directly
  if (btnReminderBiodata) {
    btnReminderBiodata.addEventListener('click', () => {
      showScreen('profile');
    });
  }

  // 2. Back button from Profil Saya returns to Beranda
  if (btnBackFromProfile) {
    btnBackFromProfile.addEventListener('click', () => {
      showScreen('home');
    });
  }

  // 3. Edit Profil button opens Edit Profil screen
  if (btnGotoEditProfile) {
    btnGotoEditProfile.addEventListener('click', () => {
      showScreen('edit-profile');
    });
  }

  // 4. Back button from Edit Profil: cancels all unsaved changes and directly returns to Profil Saya without saving
  if (btnBackFromEdit) {
    btnBackFromEdit.addEventListener('click', () => {
      // Revert input values to saved userProfile
      renderUserProfileUI();
      // Immediately return to Profil Saya screen without saving anything
      showScreen('profile');
    });
  }

  // Confirmation Modal actions (for modal if triggered):
  // "Batal" -> stay on Edit Profil screen
  if (btnCancelStay) {
    btnCancelStay.addEventListener('click', () => {
      if (cancelModalBackdrop) cancelModalBackdrop.classList.add('hidden');
    });
  }

  // "Simpan" in Modal -> save and return to Profil Saya with toast
  if (btnCancelSave) {
    btnCancelSave.addEventListener('click', () => {
      if (cancelModalBackdrop) cancelModalBackdrop.classList.add('hidden');
      executeSaveProfile();
    });
  }

  // 5. Submit button "Simpan" at bottom of Edit Profil
  if (btnSubmitEditProfile) {
    btnSubmitEditProfile.addEventListener('click', () => {
      executeSaveProfile();
    });
  }

  function executeSaveProfile() {
    const inName = document.getElementById('input-edit-fullname');
    const inDob = document.getElementById('input-edit-dob');
    const inGender = document.getElementById('input-edit-gender');
    const inEmail = document.getElementById('input-edit-email');
    const inPhone = document.getElementById('input-edit-phone');

    if (inName && inName.value.trim()) userProfile.fullName = inName.value.trim();
    if (inDob && inDob.value.trim()) userProfile.dob = inDob.value.trim();
    if (inGender && inGender.value.trim()) userProfile.gender = inGender.value.trim();
    if (inEmail && inEmail.value.trim()) userProfile.email = inEmail.value.trim();
    if (inPhone && inPhone.value.trim()) userProfile.phone = inPhone.value.trim();

    currentUser.name = userProfile.fullName;
    currentUser.email = userProfile.email;

    // Save profile data
    saveUserProfile(currentUser.email);

    // Dynamic Rule: Mark profile data complete, hiding reminder card in Beranda
    setUserBiodataStatus(currentUser.email, true);
    updateReminderBannerVisibility();

    // Update greeting and other dashboard displays
    updateUserData(userProfile.fullName, userProfile.email);

    // Smoothly transition back to Profil Saya screen
    showScreen('profile');

    // Trigger success toast alert at top of Profil Saya
    showProfileToast('Profil berhasil diperbarui!');
  }

  // 6. Photo Bottom Sheet triggers
  function openPhotoSheet() {
    if (photoSheetBackdrop) photoSheetBackdrop.classList.remove('hidden');
  }

  function closePhotoSheet() {
    if (photoSheetBackdrop) photoSheetBackdrop.classList.add('hidden');
  }

  if (btnBadgeChangePhoto) btnBadgeChangePhoto.addEventListener('click', openPhotoSheet);
  if (btnTextChangePhoto) btnTextChangePhoto.addEventListener('click', openPhotoSheet);
  if (btnClosePhotoSheet) btnClosePhotoSheet.addEventListener('click', closePhotoSheet);
  if (btnCancelPhotoSheet) btnCancelPhotoSheet.addEventListener('click', closePhotoSheet);

  if (photoSheetBackdrop) {
    photoSheetBackdrop.addEventListener('click', (e) => {
      if (e.target === photoSheetBackdrop) closePhotoSheet();
    });
  }

  // "Ambil Foto" & "Pilih dari Galeri"
  if (optTakePhoto && inputCameraCapture) {
    optTakePhoto.addEventListener('click', () => {
      inputCameraCapture.click();
    });
  }

  if (optChooseGallery && inputGalleryPick) {
    optChooseGallery.addEventListener('click', () => {
      inputGalleryPick.click();
    });
  }

  // "Hapus Foto Profil"
  if (optDeletePhoto) {
    optDeletePhoto.addEventListener('click', () => {
      userProfile.avatar = DEFAULT_AVATAR_PLACEHOLDER;
      const editAvatar = document.getElementById('edit-avatar-preview');
      const viewAvatar = document.getElementById('view-profile-avatar');
      const topAvatar = document.getElementById('topbar-avatar-img');
      if (editAvatar) editAvatar.src = userProfile.avatar;
      if (viewAvatar) viewAvatar.src = userProfile.avatar;
      if (topAvatar) topAvatar.src = userProfile.avatar;
      saveUserProfile(currentUser.email);
      closePhotoSheet();
      showToast('Foto Profil Dihapus', 'Foto profil berhasil dihapus dan dikembalikan ke avatar bawaan.');
    });
  }

  function handleProfileImageFile(file) {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      const dataUrl = event.target.result;
      userProfile.avatar = dataUrl;
      const editAvatar = document.getElementById('edit-avatar-preview');
      const viewAvatar = document.getElementById('view-profile-avatar');
      const topAvatar = document.getElementById('topbar-avatar-img');
      if (editAvatar) editAvatar.src = dataUrl;
      if (viewAvatar) viewAvatar.src = dataUrl;
      if (topAvatar) topAvatar.src = dataUrl;
      saveUserProfile(currentUser.email);
      closePhotoSheet();
      showToast('Foto Profil Diperbarui', 'Foto profil Anda berhasil diunggah.');
    };
    reader.readAsDataURL(file);
  }

  if (inputCameraCapture) {
    inputCameraCapture.addEventListener('change', (e) => {
      if (e.target.files && e.target.files[0]) {
        handleProfileImageFile(e.target.files[0]);
      }
    });
  }

  if (inputGalleryPick) {
    inputGalleryPick.addEventListener('change', (e) => {
      if (e.target.files && e.target.files[0]) {
        handleProfileImageFile(e.target.files[0]);
      }
    });
  }

  // Toast close button
  if (btnCloseProfileToast) {
    btnCloseProfileToast.addEventListener('click', () => {
      const alertBox = document.getElementById('profile-toast-alert');
      if (alertBox) alertBox.classList.add('hidden');
    });
  }

  // Bottom navigation inside Profil Saya & Edit Profil
  if (profileNavHome) profileNavHome.addEventListener('click', () => showScreen('home'));
  if (profileNavStats) profileNavStats.addEventListener('click', () => { showScreen('home'); switchHomeTab('stats'); });
  if (profileNavSettings) profileNavSettings.addEventListener('click', () => { showScreen('home'); switchHomeTab('settings'); });

  if (editNavHome) editNavHome.addEventListener('click', () => showScreen('home'));
  if (editNavStats) editNavStats.addEventListener('click', () => { showScreen('home'); switchHomeTab('stats'); });
  if (editNavSettings) editNavSettings.addEventListener('click', () => { showScreen('home'); switchHomeTab('settings'); });

  // Preview Toolbar Quick Demo Shortcuts
  if (btnDemoBeranda) btnDemoBeranda.addEventListener('click', () => showScreen('home'));
  if (btnDemoProfil) btnDemoProfil.addEventListener('click', () => showScreen('profile'));
  if (btnDemoEdit) btnDemoEdit.addEventListener('click', () => showScreen('edit-profile'));
  if (btnToggleBiodataDemo) {
    btnToggleBiodataDemo.addEventListener('click', () => {
      const curr = getUserBiodataStatus(currentUser.email);
      setUserBiodataStatus(currentUser.email, !curr);
      updateReminderBannerVisibility();
      showToast('Status Biodata Diubah', !curr ? 'Status profil diset menjadi LENGKAP (peringatan hilang)' : 'Status profil diset menjadi BELUM LENGKAP (peringatan muncul)');
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
      openProgressFeature('home');
    });
  }

  if (menuBtnHistory) {
    menuBtnHistory.addEventListener('click', () => {
      switchHomeTab('stats');
      switchMonitoringSubpage('riwayat');
    });
  }

  // ========================================================
  // HEALTH ARTICLES COMPREHENSIVE DATA ENGINE (8 ARTIKEL KESEHATAN)
  // ========================================================
  const articlesData = {
    1: {
      id: 1,
      title: '5 Pola Makan Penyebab Obesitas',
      category: 'Pola Makan & Nutrisi',
      snippet: 'Kenali Kebiasaan makan yang tanpa disadari meningkatkan resiko berat badan berlebih',
      author: 'Dr. Hendra Wijaya, Sp.GK',
      date: '21 September 2026',
      readTime: '4 Menit Baca',
      thumbSvg: `
        <svg viewBox="0 0 130 95" fill="none" width="100%" height="100%">
          <rect width="130" height="95" rx="10" fill="#7E96AC" />
          <circle cx="65" cy="46" r="34" fill="#F8FAFC" />
          <!-- Snack Table & Fastfood Illustration matching Mockup -->
          <rect x="30" y="65" width="70" height="18" rx="4" fill="#CBD5E1" />
          <!-- Fast food cup & burger -->
          <rect x="42" y="52" width="12" height="16" rx="2" fill="#EF4444" />
          <line x1="48" y1="46" x2="48" y2="52" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" />
          <!-- Burger -->
          <ellipse cx="65" cy="58" rx="13" ry="5" fill="#EAB308" />
          <ellipse cx="65" cy="62" rx="13" ry="4" fill="#78350F" />
          <ellipse cx="65" cy="65" rx="14" ry="5" fill="#EAB308" />
          <!-- Person eating -->
          <circle cx="85" cy="38" r="8" fill="#FCD34D" />
          <path d="M76 56C76 48 83 46 85 46C87 46 94 48 94 56Z" fill="#3B82F6" />
          <!-- Overlay badge text -->
          <rect x="6" y="6" width="118" height="22" rx="4" fill="#3B536B" fill-opacity="0.9" />
          <text x="65" y="16" fill="#FFFFFF" font-size="7.5" font-family="Poppins" font-weight="700" text-anchor="middle">5 Pola Makan</text>
          <text x="65" y="24" fill="#93C5FD" font-size="6.5" font-family="Poppins" font-weight="600" text-anchor="middle">Penyebab Obesitas</text>
        </svg>
      `,
      heroSvg: `
        <svg viewBox="0 0 400 220" fill="none" width="100%" height="100%">
          <rect width="400" height="220" fill="url(#heroGrad1)" />
          <defs>
            <linearGradient id="heroGrad1" x1="0" y1="0" x2="400" y2="220" gradientUnits="userSpaceOnUse">
              <stop stop-color="#4A6572" />
              <stop offset="0.6" stop-color="#344955" />
              <stop offset="1" stop-color="#232F34" />
            </linearGradient>
          </defs>
          <circle cx="330" cy="90" r="80" fill="#FFFFFF" fill-opacity="0.08" />
          <circle cx="70" cy="180" r="110" fill="#FFFFFF" fill-opacity="0.05" />
          <!-- Healthy bowl vs Junk food elements -->
          <g transform="translate(140, 45)">
            <rect width="120" height="90" rx="16" fill="#FFFFFF" fill-opacity="0.92" filter="drop-shadow(0 6px 16px rgba(0,0,0,0.15))" />
            <!-- Plate -->
            <ellipse cx="60" cy="48" rx="40" ry="24" fill="#F1F5F9" />
            <!-- Veggies & Healthy Bowl -->
            <path d="M35 48C35 34 50 30 60 30C70 30 85 34 85 48Z" fill="#16A34A" />
            <circle cx="48" cy="42" r="5" fill="#EF4444" />
            <circle cx="72" cy="42" r="4.5" fill="#F59E0B" />
            <circle cx="60" cy="38" r="4" fill="#84CC16" />
            <text x="60" y="74" fill="#0F172A" font-size="9" font-family="Poppins" font-weight="700" text-anchor="middle">PANDUAN POLA MAKAN</text>
          </g>
        </svg>
      `,
      contentHtml: `
        <p>Banyak orang tidak menyadari bahwa kenaikan berat badan berlebih dan obesitas sering kali bukan disebabkan oleh porsi makan yang besar semata, melainkan kebiasaan atau pola makan harian yang salah dan dilakukan berulang-ulang tanpa disadari.</p>
        
        <h3>1. Konsumsi Minuman Manis & Tinggi Gula Tersembunyi</h3>
        <p>Minuman kemasan, boba, kopi susu dengan sirup, soda, dan jus buah olahan mengandung kadar gula cair (fruktosa) yang sangat tinggi. Gula cair diserap tubuh dengan cepat tanpa memberikan rasa kenyang pada lambung, sehingga kalori berlebih langsung disimpan menjadi lemak visceral.</p>

        <h3>2. Makan Terburu-buru (Mindless Eating)</h3>
        <p>Otak membutuhkan waktu sekitar 15 hingga 20 menit sejak suapan pertama untuk menerima sinyal rasa kenyang dari hormon leptin di saluran pencernaan. Makan terburu-buru sambil menatap layar ponsel atau televisi membuat kita mengonsumsi 30-50% lebih banyak kalori sebelum otak menyadari bahwa tubuh sudah kenyang.</p>

        <div class="article-callout-quote">
          "Mengunyah makanan secara perlahan (20-30 kali kunyah per suapan) terbukti klinis membantu kerja enzim pencernaan dan mengurangi asupan kalori harian secara alami." — <strong>Dr. Hendra Wijaya, Sp.GK</strong>
        </div>

        <h3>3. Melewatkan Sarapan Bergizi</h3>
        <p>Melewatkan sarapan sering memicu rasa lapar ekstrem saat jam makan siang. Akibatnya, seseorang cenderung memilih makanan padat karbohidrat sederhana dan lemak tinggi dengan porsi dobel karena penurunan kadar gula darah yang drastis di pagi hari.</p>

        <h3>4. Kebiasaan Mengudap Larut Malam (Late-Night Snacking)</h3>
        <p>Makan camilan tinggi garam dan gula setelah jam 8 malam saat tubuh minim aktivitas fisik menyebabkan kalori tidak terpakai sebagai energi, melainkan langsung diubah menjadi cadangan lemak tubuh saat tidur.</p>

        <h3>5. Emotional Eating saat Stres</h3>
        <p>Saat mengalami stres kerja atau emosional, hormon kortisol meningkat dan memicu rasa ngidam makanan manis atau berlemak (comfort food) sebagai mekanisme pelarian sementara.</p>

        <div class="article-nutrition-tip-box">
          <div class="tip-box-header">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="#B45309" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <span>Tips Praktis Perubahan Kebiasaan:</span>
          </div>
          <p class="tip-box-desc">Ganti camilan manis dengan buah segar utuh (seperti apel atau pir) dan selalu minum segelas air putih 15 menit sebelum waktu makan utama.</p>
        </div>
      `,
      takeaways: [
        'Hindari kalori cair dari minuman manis dan bersoda.',
        'Makan secara perlahan dan nikmati setiap suapan tanpa distraksi gadget.',
        'Jaga jam makan tetap teratur untuk menstabilkan hormon lapar dan kenyang.',
        'Kenali pemicu emosional sebelum memutuskan untuk mengambil camilan.'
      ],
      relatedIds: [3, 4, 2]
    },

    2: {
      id: 2,
      title: 'Obesitas Bukan Sekadar Masalah Penampilan',
      category: 'Edukasi Kesehatan',
      snippet: 'Pola hidup sehat sangat bermanfaat dimasa depan untuk mencegah risiko penyakit metabolik.',
      author: 'dr. Nurul Aisyah, M.Kes',
      date: '20 September 2026',
      readTime: '5 Menit Baca',
      thumbSvg: `
        <svg viewBox="0 0 130 95" fill="none" width="100%" height="100%">
          <rect width="130" height="95" rx="10" fill="#E5BD87" />
          <!-- Body Comparison & Healthy Icons matching Mockup -->
          <circle cx="45" cy="48" r="28" fill="#FDF8F0" />
          <!-- Woman Plus Silhouette -->
          <ellipse cx="45" cy="42" rx="14" ry="18" fill="#D97706" fill-opacity="0.85" />
          <circle cx="45" cy="22" r="6.5" fill="#B45309" />
          <!-- Woman Slim Silhouette -->
          <ellipse cx="88" cy="42" rx="9" ry="18" fill="#16A34A" fill-opacity="0.85" />
          <circle cx="88" cy="22" r="6" fill="#15803D" />
          <!-- Floating Veggies & Pizza -->
          <circle cx="22" cy="22" r="7" fill="#EF4444" fill-opacity="0.3" />
          <circle cx="108" cy="22" r="7" fill="#22C55E" fill-opacity="0.3" />
          <rect x="6" y="68" width="118" height="20" rx="4" fill="#92400E" fill-opacity="0.85" />
          <text x="65" y="81" fill="#FFFFFF" font-size="7.5" font-family="Poppins" font-weight="700" text-anchor="middle">MASA DEPAN SEHAT</text>
        </svg>
      `,
      heroSvg: `
        <svg viewBox="0 0 400 220" fill="none" width="100%" height="100%">
          <rect width="400" height="220" fill="url(#heroGrad2)" />
          <defs>
            <linearGradient id="heroGrad2" x1="0" y1="0" x2="400" y2="220" gradientUnits="userSpaceOnUse">
              <stop stop-color="#D97706" />
              <stop offset="0.6" stop-color="#B45309" />
              <stop offset="1" stop-color="#78350F" />
            </linearGradient>
          </defs>
          <circle cx="310" cy="110" r="90" fill="#FFFFFF" fill-opacity="0.1" />
          <circle cx="90" cy="50" r="60" fill="#FFFFFF" fill-opacity="0.06" />
          <g transform="translate(130, 45)">
            <rect width="140" height="90" rx="16" fill="#FFFFFF" fill-opacity="0.95" filter="drop-shadow(0 6px 16px rgba(0,0,0,0.2))" />
            <!-- Health Vital Heart & Metric -->
            <path d="M70 60C62 52 48 45 48 35C48 27 54 22 62 22C67 22 71 25 73 28C75 25 79 22 84 22C92 22 98 27 98 35C98 45 84 52 76 60L73 63L70 60Z" fill="#DC2626" />
            <text x="70" y="76" fill="#78350F" font-size="9" font-family="Poppins" font-weight="700" text-anchor="middle">KESEHATAN ORGAN VITAL</text>
          </g>
        </svg>
      `,
      contentHtml: `
        <p>Stigma yang sering berkembang di masyarakat menganggap obesitas hanya sekadar persoalan estetika atau ukuran pakaian. Padahal secara medis, Organisasi Kesehatan Dunia (WHO) telah mengkategorikan obesitas sebagai penyakit kronis progresif yang kompleks.</p>

        <h3>Dampak Obesitas pada Organ Dalam Tubuh</h3>
        <p>Ketika lemak tubuh menumpuk secara berlebih, sel-sel lemak (adiposit) tidak hanya pasif menyimpan energi, melainkan aktif melepaskan zat sitokin pro-inflamasi yang menyebabkan peradangan kronis tingkat rendah di seluruh pembuluh darah dan organ:</p>

        <ul>
          <li><strong>Jantung & Pembuluh Darah:</strong> Beban kerja jantung meningkat untuk memompa darah ke jaringan tubuh yang lebih besar, memicu hipertensi dan aterosklerosis.</li>
          <li><strong>Pankreas & Resistensi Insulin:</strong> Lemak visceral mengganggu reseptor insulin, memicu lonjakan gula darah dan Diabetes Melitus Tipe 2.</li>
          <li><strong>Hati (Fatty Liver):</strong> Penumpukan lemak pada sel hati dapat berkembang menjadi peradangan hati (NASH) hingga sirosis.</li>
          <li><strong>Sendi & Tulang:</strong> Sendi penopang berat badan seperti lutut dan pinggul mengalami keausan tulang rawan lebih cepat (Osteoartritis).</li>
        </ul>

        <div class="article-callout-quote">
          "Menurunkan hanya 5-10% dari total berat badan berlebih sudah terbukti secara klinis mampu menurunkan tekanan darah, kadar kolesterol jahat (LDL), dan resistensi insulin secara signifikan."
        </div>

        <h3>Pentingnya Mengetahui IMT dan Lingkar Perut</h3>
        <p>Selain Indeks Massa Tubuh (IMT), lingkar perut adalah indikator krusial lemak visceral. Batas aman lingkar perut untuk orang Asia adalah &le; 90 cm untuk pria dan &le; 80 cm untuk wanita.</p>
      `,
      takeaways: [
        'Obesitas adalah kondisi medis metabolik, bukan sekadar masalah penampilan luar.',
        'Penurunan berat badan bertahap (5-10%) memberikan proteksi kardiovaskular luar biasa.',
        'Rutin ukur lingkar perut dan cek profil lipid darah secara berkala.'
      ],
      relatedIds: [5, 1, 4]
    },

    3: {
      id: 3,
      title: 'Isi Piringku: Cara Sederhana Mengatur Porsi Makan',
      category: 'Panduan Kemenkes',
      snippet: 'Konsep 4 Sehat 5 Sempurna vs Isi Piringku untuk panduan porsi gizi seimbang harian.',
      author: 'Kementerian Kesehatan RI',
      date: '19 September 2026',
      readTime: '4 Menit Baca',
      thumbSvg: `
        <svg viewBox="0 0 130 95" fill="none" width="100%" height="100%">
          <rect width="130" height="95" rx="10" fill="#F472B6" />
          <circle cx="65" cy="48" r="30" fill="#FFFFFF" />
          <!-- Plate 4 quadrants -->
          <path d="M65 48 L65 20 A28 28 0 0 1 93 48 Z" fill="#22C55E" />
          <path d="M65 48 L93 48 A28 28 0 0 1 65 76 Z" fill="#F59E0B" />
          <path d="M65 48 L65 76 A28 28 0 0 1 37 48 Z" fill="#EAB308" />
          <path d="M65 48 L37 48 A28 28 0 0 1 65 20 Z" fill="#EC4899" />
          <circle cx="65" cy="48" r="6" fill="#FFFFFF" />
          <!-- Spoon illustration -->
          <ellipse cx="110" cy="48" rx="4" ry="12" fill="#E2E8F0" />
          <line x1="110" y1="60" x2="110" y2="78" stroke="#CBD5E1" stroke-width="2.5" stroke-linecap="round" />
          <rect x="6" y="6" width="118" height="20" rx="4" fill="#9D174D" fill-opacity="0.9" />
          <text x="65" y="19" fill="#FFFFFF" font-size="7.5" font-family="Poppins" font-weight="700" text-anchor="middle">ISI PIRINGKU</text>
        </svg>
      `,
      heroSvg: `
        <svg viewBox="0 0 400 220" fill="none" width="100%" height="100%">
          <rect width="400" height="220" fill="url(#heroGrad3)" />
          <defs>
            <linearGradient id="heroGrad3" x1="0" y1="0" x2="400" y2="220" gradientUnits="userSpaceOnUse">
              <stop stop-color="#0F766E" />
              <stop offset="0.6" stop-color="#0D9488" />
              <stop offset="1" stop-color="#14B8A6" />
            </linearGradient>
          </defs>
          <circle cx="80" cy="80" r="70" fill="#FFFFFF" fill-opacity="0.08" />
          <circle cx="320" cy="140" r="90" fill="#FFFFFF" fill-opacity="0.08" />
          <g transform="translate(130, 35)">
            <rect width="140" height="110" rx="18" fill="#FFFFFF" fill-opacity="0.95" filter="drop-shadow(0 6px 18px rgba(0,0,0,0.15))" />
            <circle cx="70" cy="55" r="36" fill="#F8FAFC" stroke="#E2E8F0" stroke-width="2" />
            <path d="M70 55 L70 21 A34 34 0 0 1 104 55 Z" fill="#22C55E" />
            <path d="M70 55 L104 55 A34 34 0 0 1 70 89 Z" fill="#F59E0B" />
            <path d="M70 55 L70 89 A34 34 0 0 1 36 55 Z" fill="#EAB308" />
            <path d="M70 55 L36 55 A34 34 0 0 1 70 21 Z" fill="#06B6D4" />
            <circle cx="70" cy="55" r="8" fill="#FFFFFF" />
            <text x="70" y="100" fill="#0F766E" font-size="8.5" font-family="Poppins" font-weight="700" text-anchor="middle">PEDOMAN GIZI SEIMBANG</text>
          </g>
        </svg>
      `,
      contentHtml: `
        <p>Sebagai pengganti slogan lama "4 Sehat 5 Sempurna", Kementerian Kesehatan Republik Indonesia kini menggalakkan pedoman visual baru bertajuk <strong>"Isi Piringku"</strong>. Pedoman ini menitikberatkan pada proporsi porsi setiap kelompok makanan dalam satu piring makan sekali saji.</p>

        <h3>Pembagian 4 Kuadran Isi Piringku:</h3>
        <ul>
          <li><strong>1/3 Piring Makanan Pokok:</strong> Karbohidrat kompleks seperti nasi merah, jagung, kentang rebus, atau ubi jalar yang kaya serat dan memperlambat lonjakan insulin.</li>
          <li><strong>1/3 Piring Sayur-Mayur:</strong> Berbagai jenis sayuran hijau dan berwarna seperti bayam, brokoli, wortel, dan buncis yang kaya vitamin, mineral, dan fitonutrien.</li>
          <li><strong>1/6 Piring Lauk-Pauk:</strong> Sumber protein berkualitas rendah lemak jenuh seperti ikan laut, tempe, tahu, dada ayam tanpa kulit, atau telur rebus.</li>
          <li><strong>1/6 Piring Buah-Buahan:</strong> Buah segar utuh seperti pepaya, pisang, apel, jeruk, atau melon sebagai sumber antioksidan alami.</li>
        </ul>

        <div class="article-nutrition-tip-box">
          <div class="tip-box-header">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="#B45309" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
            <span>Batasan Konsumsi GGL (Gula, Garam, Lemak) per Hari:</span>
          </div>
          <p class="tip-box-desc"><strong>G4 - G1 - L5:</strong> Maksimal 4 sendok makan Gula (50 gram), 1 sendok teh Garam (5 gram / 2000 mg natrium), dan 5 sendok makan Lemak/Minyak (67 gram) per orang per hari.</p>
        </div>

        <h3>Kebiasaan Pelengkap yang Wajib Diterapkan:</h3>
        <p>1. Cuci tangan pakai sabun dengan air mengalir sebelum makan.<br>
        2. Minum air putih minimal 8 gelas (2 liter) setiap hari.<br>
        3. Lakukan aktivitas fisik minimal 30 menit setiap hari.</p>
      `,
      takeaways: [
        'Separuh piring diisi oleh sayuran dan buah-buahan (kaya serat dan mikronutrien).',
        'Separuh piring lainnya dibagi seimbang antara karbohidrat kompleks dan lauk protein.',
        'Patuhi anjuran G4-G1-L5 untuk membatasi risiko hipertensi dan obesitas.'
      ],
      relatedIds: [1, 4, 6]
    },

    4: {
      id: 4,
      title: 'Cegah Obesitas dengan Pola Hidup Sehat',
      category: 'Gaya Hidup Sehat',
      snippet: 'Kenali kebiasaan sederhana yang dapat menjaga berat badan ideal dan tubuh bugar.',
      author: 'Tim Medis ObeSight',
      date: '18 September 2026',
      readTime: '4 Menit Baca',
      thumbSvg: `
        <svg viewBox="0 0 130 95" fill="none" width="100%" height="100%">
          <rect width="130" height="95" rx="10" fill="#86EFAC" />
          <!-- Active Lifestyle Graphic matching Mockup -->
          <circle cx="65" cy="46" r="32" fill="#F0FDF4" />
          <!-- Runner girl silhouette -->
          <circle cx="65" cy="30" r="5" fill="#15803D" />
          <path d="M62 38L68 44L63 54L71 64M59 47L54 57M68 44L76 49" stroke="#15803D" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />
          <!-- Running shoe & fruit icon -->
          <circle cx="34" cy="32" r="7" fill="#22C55E" />
          <circle cx="96" cy="32" r="7" fill="#3B82F6" />
          <rect x="6" y="68" width="118" height="20" rx="4" fill="#166534" />
          <text x="65" y="81" fill="#FFFFFF" font-size="7.5" font-family="Poppins" font-weight="700" text-anchor="middle">POLA HIDUP SEHAT</text>
        </svg>
      `,
      heroSvg: `
        <svg viewBox="0 0 400 220" fill="none" width="100%" height="100%">
          <rect width="400" height="220" fill="url(#heroGrad4)" />
          <defs>
            <linearGradient id="heroGrad4" x1="0" y1="0" x2="400" y2="220" gradientUnits="userSpaceOnUse">
              <stop stop-color="#166534" />
              <stop offset="0.6" stop-color="#15803D" />
              <stop offset="1" stop-color="#22C55E" />
            </linearGradient>
          </defs>
          <circle cx="90" cy="110" r="80" fill="#FFFFFF" fill-opacity="0.08" />
          <circle cx="320" cy="60" r="70" fill="#FFFFFF" fill-opacity="0.08" />
          <g transform="translate(130, 45)">
            <rect width="140" height="90" rx="16" fill="#FFFFFF" fill-opacity="0.95" filter="drop-shadow(0 6px 16px rgba(0,0,0,0.15))" />
            <!-- Active Person Icon -->
            <circle cx="70" cy="40" r="10" fill="#22C55E" />
            <path d="M50 72C50 58 60 54 70 54C80 54 90 58 90 72Z" fill="#15803D" />
            <text x="70" y="78" fill="#14532D" font-size="9" font-family="Poppins" font-weight="700" text-anchor="middle">AKTIF & BUGAR</text>
          </g>
        </svg>
      `,
      contentHtml: `
        <p>Mencegah obesitas tidak memerlukan langkah ekstrem atau diet ketat yang menyiksa. Kunci utama keberhasilan terletak pada konsistensi menerapkan 5 pilar kebiasaan sehat dalam kehidupan sehari-hari.</p>

        <h3>5 Pilar Pencegahan Obesitas:</h3>
        <p><strong>1. Tingkatkan Aktivitas Fisik Harian (NEAT):</strong> Usahakan jalan kaki minimal 7.000 hingga 10.000 langkah setiap hari. Gunakan tangga ketimbang lift dan luangkan waktu berdiri setiap 45 menit duduk.</p>
        
        <p><strong>2. Olahraga Aerobik & Latihan Beban:</strong> Kombinasikan latihan kardio (jogging, bersepeda, senam) 150 menit per minggu dengan latihan kekuatan otot 2 kali seminggu untuk meningkatkan massa otot dan laju metabolisme basal (BMR).</p>
        
        <p><strong>3. Kualitas Tidur yang Terjaga:</strong> Tidur malam cukup selama 7-8 jam membantu meregulasi hormon leptin (penekan nafsu makan) dan menurunkan hormon ghrelin (pemicu lapar).</p>
        
        <p><strong>4. Manajemen Stres yang Efektif:</strong> Praktikkan teknik pernapasan dalam, yoga, meditasi, atau hobi santai untuk mencegah lonjakan kortisol yang memicu penumpukan lemak di area perut.</p>

        <p><strong>5. Pemantauan Berkala (Self-Monitoring):</strong> Gunakan fitur monitoring ObeSight untuk mencatat asupan, aktivitas fisik, dan perkembangan berat badan secara teratur.</p>
      `,
      takeaways: [
        'Konsistensi kebiasaan kecil jauh lebih efektif daripada diet ketat sementara.',
        'Kombinasikan kardio dengan latihan beban untuk metabolisme optimal.',
        'Tidur cukup 7-8 jam dan kelola stres dengan baik.'
      ],
      relatedIds: [6, 1, 3]
    },

    5: {
      id: 5,
      title: 'Obesitas Sebagai Pemicu Komplikasi',
      category: 'Klinis & Medis',
      snippet: 'Memahami bagaimana resistensi insulin dan peradangan kronis memicu berbagai komplikasi kesehatan.',
      author: 'Dr. Hendra Wijaya, Sp.GK',
      date: '17 September 2026',
      readTime: '5 Menit Baca',
      thumbSvg: `
        <svg viewBox="0 0 130 95" fill="none" width="100%" height="100%">
          <rect width="130" height="95" rx="10" fill="#94A3B8" />
          <!-- Medical & Heart Monitor Graphic matching Mockup -->
          <circle cx="65" cy="48" r="30" fill="#F8FAFC" />
          <!-- ECG line & heart -->
          <path d="M42 48H52L56 36L62 60L68 42L72 52L76 48H88" stroke="#EF4444" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
          <rect x="6" y="6" width="118" height="20" rx="4" fill="#334155" />
          <text x="65" y="19" fill="#FFFFFF" font-size="7.5" font-family="Poppins" font-weight="700" text-anchor="middle">PEMICU KOMPLIKASI</text>
        </svg>
      `,
      heroSvg: `
        <svg viewBox="0 0 400 220" fill="none" width="100%" height="100%">
          <rect width="400" height="220" fill="url(#heroGrad5)" />
          <defs>
            <linearGradient id="heroGrad5" x1="0" y1="0" x2="400" y2="220" gradientUnits="userSpaceOnUse">
              <stop stop-color="#334155" />
              <stop offset="0.6" stop-color="#1E293B" />
              <stop offset="1" stop-color="#0F172A" />
            </linearGradient>
          </defs>
          <circle cx="330" cy="110" r="90" fill="#FFFFFF" fill-opacity="0.06" />
          <g transform="translate(130, 45)">
            <rect width="140" height="90" rx="16" fill="#FFFFFF" fill-opacity="0.95" filter="drop-shadow(0 6px 16px rgba(0,0,0,0.25))" />
            <!-- Stethoscope & Shield -->
            <path d="M70 30L90 40V60C90 75 70 85 70 85C70 85 50 75 50 60V40L70 30Z" fill="#38BDF8" fill-opacity="0.2" stroke="#0284C7" stroke-width="2" />
            <path d="M62 55L68 61L78 51" stroke="#0284C7" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
            <text x="70" y="78" fill="#0F172A" font-size="8.5" font-family="Poppins" font-weight="700" text-anchor="middle">DETEKSI DINI KOMPLIKASI</text>
          </g>
        </svg>
      `,
      contentHtml: `
        <p>Obesitas merupakan faktor risiko utama (independen) terhadap berkembangnya sindrom metabolik dan berbagai penyakit tidak menular (PTM) yang dapat menurunkan kualitas serta harapan hidup seseorang.</p>

        <h3>Rantai Komplikasi Akibat Obesitas:</h3>
        <p><strong>1. Diabetes Melitus Tipe 2:</strong> Penumpukan asam lemak bebas dalam darah menurunkan sensitivitas reseptor insulin pada otot dan hati. Hal ini memaksa pankreas memproduksi lebih banyak insulin hingga akhirnya mengalami kelelahan sel beta.</p>

        <p><strong>2. Penyakit Jantung Koroner & Stroke:</strong> Kadar kolesterol LDL dan trigliserida yang tinggi memicu pembentukan plak aterosklerosis di dinding arteri, menyumbat aliran darah ke jantung dan otak.</p>

        <p><strong>3. Obstructive Sleep Apnea (OSA):</strong> Penumpukan jaringan lemak di sekitar saluran pernapasan atas menyebabkan penyempitan jalan napas saat tidur, memicu dengkuran keras dan henti napas sesaat yang berbahaya.</p>

        <p><strong>4. Gangguan Kesehatan Mental:</strong> Tekanan sosial dan penurunan mobilitas fisik sering memicu kecemasan, penurunan rasa percaya diri, dan depresi.</p>
      `,
      takeaways: [
        'Komplikasi obesitas bersifat sistemik dan menyerang banyak organ vital.',
        'Lakukan skrining risiko secara dini untuk intervensi sebelum komplikasi permanen.',
        'Konsultasikan dengan dokter spesialis gizi untuk penanganan terstruktur.'
      ],
      relatedIds: [2, 1, 4]
    },

    6: {
      id: 6,
      title: 'Yuk, Kenali Pola Hidup Sehat untuk Cegah Obesitas',
      category: 'Artikel Unggulan',
      snippet: 'Temukan informasi risiko obesitas berdasarkan pola hidup dan kebiasaan sehari-hari.',
      author: 'Tim Ahli Gizi & Medis ObeSight',
      date: '21 September 2026',
      readTime: '6 Menit Baca',
      thumbSvg: `
        <svg viewBox="0 0 130 95" fill="none" width="100%" height="100%">
          <rect width="130" height="95" rx="10" fill="#D4F1E4" />
          <circle cx="65" cy="48" r="30" fill="#FFFFFF" />
          <circle cx="65" cy="40" r="14" fill="#2E6B4F" />
          <circle cx="85" cy="30" r="7" fill="#84CC16" />
          <rect x="6" y="68" width="118" height="20" rx="4" fill="#2E6B4F" />
          <text x="65" y="81" fill="#FFFFFF" font-size="7.5" font-family="Poppins" font-weight="700" text-anchor="middle">ARTIKEL UNGGULAN</text>
        </svg>
      `,
      heroSvg: `
        <svg viewBox="0 0 400 220" fill="none" width="100%" height="100%">
          <rect width="400" height="220" fill="url(#heroGrad6)" />
          <defs>
            <linearGradient id="heroGrad6" x1="0" y1="0" x2="400" y2="220" gradientUnits="userSpaceOnUse">
              <stop stop-color="#2E6B4F" />
              <stop offset="0.6" stop-color="#1B4D36" />
              <stop offset="1" stop-color="#0E2E1F" />
            </linearGradient>
          </defs>
          <circle cx="340" cy="120" r="90" fill="#FFFFFF" fill-opacity="0.08" />
          <circle cx="60" cy="60" r="60" fill="#FFFFFF" fill-opacity="0.05" />
          <g transform="translate(120, 35)">
            <rect width="160" height="110" rx="18" fill="#FFFFFF" fill-opacity="0.95" filter="drop-shadow(0 8px 22px rgba(0,0,0,0.2))" />
            <!-- Star & Apple Ribbon -->
            <circle cx="80" cy="48" r="24" fill="#E8F5EE" />
            <circle cx="80" cy="48" r="14" fill="#22C55E" />
            <text x="80" y="94" fill="#143728" font-size="9.5" font-family="Poppins" font-weight="700" text-anchor="middle">PANDUAN LENGKAP OBESIGHT</text>
          </g>
        </svg>
      `,
      contentHtml: `
        <p>Mencegah obesitas berakar dari kesadaran diri terhadap pola hidup yang dijalani setiap hari. Mulai dari apa yang Anda konsumsi di meja makan, berapa lama Anda bergerak, hingga bagaimana Anda beristirahat di malam hari—semuanya saling terhubung dalam menjaga keseimbangan energi tubuh.</p>

        <h3>Kenali Sinyal Tubuh Anda</h3>
        <p>Banyak dari kita terbiasa makan karena dorongan visual, aroma, atau kebiasaan jam tertentu, bukan karena rasa lapar fisiologis. Belajarlah membedakan rasa lapar fisik (yang timbul bertahap dan terasa di lambung) dengan lapar emosional (yang datang mendadak dan menuntut makanan tertentu seperti manis atau asin).</p>

        <h3>Langkah Memulai Hidup Sehat Tanpa Beban:</h3>
        <ul>
          <li><strong>Mulai dari Air Putih:</strong> Ganti semua minuman berpemanis dengan air putih. Menghilangkan 1 botol soda per hari dapat memotong hingga 50.000 kalori dalam setahun.</li>
          <li><strong>Jadwalkan Waktu Bergerak:</strong> Tidak perlu langsung ke gym berat. Cukup jalan cepat 30 menit setiap pagi atau sore.</li>
          <li><strong>Siapkan Makanan Sendiri (Meal Prep):</strong> Memasak sendiri memberi Anda kendali penuh atas takaran minyak, garam, dan gula.</li>
        </ul>
      `,
      takeaways: [
        'Pola hidup sehat adalah perjalanan jangka panjang, bukan perlombaan kilat.',
        'Fokus pada pembentukan kebiasaan baru yang berkelanjutan dan menyenangkan.',
        'Gunakan aplikasi ObeSight untuk memantau kemajuan Anda setiap hari.'
      ],
      relatedIds: [1, 3, 4]
    },

    7: {
      id: 7,
      title: 'Pentingnya Kualitas Tidur untuk Metabolisme',
      category: 'Gaya Hidup Sehat',
      snippet: 'Kurang tidur mengacaukan hormon ghrelin dan leptin yang memicu nafsu makan berlebih.',
      author: 'dr. Nurul Aisyah, M.Kes',
      date: '16 September 2026',
      readTime: '3 Menit Baca',
      thumbSvg: `
        <svg viewBox="0 0 130 95" fill="none" width="100%" height="100%">
          <rect width="130" height="95" rx="10" fill="#6366F1" />
          <circle cx="65" cy="48" r="30" fill="#EEF2FF" />
          <!-- Moon & Bed Icon -->
          <path d="M72 32C64 32 58 38 58 46C58 54 64 60 72 60C76 60 80 58 82 55C75 55 69 49 69 42C69 37 72 33 76 32C74.5 32 73.2 32 72 32Z" fill="#4F46E5" />
          <rect x="6" y="68" width="118" height="20" rx="4" fill="#3730A3" />
          <text x="65" y="81" fill="#FFFFFF" font-size="7.5" font-family="Poppins" font-weight="700" text-anchor="middle">KUALITAS TIDUR</text>
        </svg>
      `,
      heroSvg: `
        <svg viewBox="0 0 400 220" fill="none" width="100%" height="100%">
          <rect width="400" height="220" fill="url(#heroGrad7)" />
          <defs>
            <linearGradient id="heroGrad7" x1="0" y1="0" x2="400" y2="220" gradientUnits="userSpaceOnUse">
              <stop stop-color="#3730A3" />
              <stop offset="0.6" stop-color="#4F46E5" />
              <stop offset="1" stop-color="#6366F1" />
            </linearGradient>
          </defs>
          <circle cx="320" cy="110" r="80" fill="#FFFFFF" fill-opacity="0.1" />
          <g transform="translate(130, 45)">
            <rect width="140" height="90" rx="16" fill="#FFFFFF" fill-opacity="0.95" filter="drop-shadow(0 6px 16px rgba(0,0,0,0.2))" />
            <path d="M70 28C62 28 56 34 56 42C56 50 62 56 70 56C74 56 78 54 80 51C73 51 67 45 67 38C67 33 70 29 74 28Z" fill="#4F46E5" />
            <text x="70" y="76" fill="#312E81" font-size="9" font-family="Poppins" font-weight="700" text-anchor="middle">TIDUR & METABOLISME</text>
          </g>
        </svg>
      `,
      contentHtml: `
        <p>Banyak program penurunan berat badan gagal karena mengabaikan faktor tidur. Kurang tidur kronis (< 6 jam per malam) mengganggu keseimbangan dua hormon pengatur nafsu makan utama:</p>
        <ul>
          <li><strong>Hormon Ghrelin Meningkat:</strong> Hormon yang memberi sinyal lapar pada otak meningkat hingga 15-20%.</li>
          <li><strong>Hormon Leptin Menurun:</strong> Hormon yang memberi sinyal kenyang menurun, membuat Anda selalu merasa ingin makan.</li>
        </ul>
        <p>Selain itu, kurang tidur meningkatkan hormon kortisol yang mendorong tubuh menimbun lemak di area perut dan menurunkan sensitivitas insulin.</p>
      `,
      takeaways: [
        'Tidur 7-8 jam per malam adalah bagian krusial dari pencegahan obesitas.',
        'Hindari penggunaan ponsel 30 menit sebelum tidur untuk kualitas tidur nyenyak.'
      ],
      relatedIds: [4, 1, 6]
    },

    8: {
      id: 8,
      title: 'Aktivitas Fisik Ringan Pembakar Kalori',
      category: 'Kebugaran & Olahraga',
      snippet: 'Aktivitas fisik tidak selalu harus berat, konsistensi jalan kaki dan peregangan harian efektif membakar energi.',
      author: 'Fisioterapis ObeSight',
      date: '15 September 2026',
      readTime: '4 Menit Baca',
      thumbSvg: `
        <svg viewBox="0 0 130 95" fill="none" width="100%" height="100%">
          <rect width="130" height="95" rx="10" fill="#38BDF8" />
          <circle cx="65" cy="48" r="30" fill="#F0F9FF" />
          <circle cx="65" cy="30" r="5" fill="#0284C7" />
          <path d="M62 38L68 44L63 54L71 64M59 47L54 57M68 44L76 49" stroke="#0284C7" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />
          <rect x="6" y="68" width="118" height="20" rx="4" fill="#0369A1" />
          <text x="65" y="81" fill="#FFFFFF" font-size="7.5" font-family="Poppins" font-weight="700" text-anchor="middle">AKTIVITAS FISIK</text>
        </svg>
      `,
      heroSvg: `
        <svg viewBox="0 0 400 220" fill="none" width="100%" height="100%">
          <rect width="400" height="220" fill="url(#heroGrad8)" />
          <defs>
            <linearGradient id="heroGrad8" x1="0" y1="0" x2="400" y2="220" gradientUnits="userSpaceOnUse">
              <stop stop-color="#0284C7" />
              <stop offset="0.6" stop-color="#0369A1" />
              <stop offset="1" stop-color="#075985" />
            </linearGradient>
          </defs>
          <circle cx="320" cy="110" r="80" fill="#FFFFFF" fill-opacity="0.1" />
          <g transform="translate(130, 45)">
            <rect width="140" height="90" rx="16" fill="#FFFFFF" fill-opacity="0.95" filter="drop-shadow(0 6px 16px rgba(0,0,0,0.2))" />
            <circle cx="70" cy="36" r="8" fill="#0284C7" />
            <path d="M60 66C60 52 70 48 70 48C70 48 80 52 80 66Z" fill="#0369A1" />
            <text x="70" y="78" fill="#075985" font-size="9" font-family="Poppins" font-weight="700" text-anchor="middle">PEMBAKAR KALORI</text>
          </g>
        </svg>
      `,
      contentHtml: `
        <p>Banyak orang mengira pembakaran kalori hanya terjadi saat berolahraga intens di gym. Faktanya, porsi terbesar energi harian di luar metabolisme basal dihabiskan melalui <strong>NEAT (Non-Exercise Activity Thermogenesis)</strong>—yaitu semua gerakan fisik selain tidur, makan, dan olahraga terstruktur.</p>

        <h3>Contoh Aktivitas NEAT yang Efektif:</h3>
        <ul>
          <li>Memilih naik tangga daripada eskalator membakar 5-10 kalori per menit.</li>
          <li>Membersihkan rumah dan menyapu selama 30 menit membakar hingga 100 kalori.</li>
          <li>Berjalan saat menerima panggilan telepon menambah ratusan langkah tanpa terasa.</li>
          <li>Peregangan ringan setiap jam kerja melancarkan peredaran darah dan mencegah kekakuan otot.</li>
        </ul>
      `,
      takeaways: [
        'Aktivitas bergerak sederhana sepanjang hari memberikan dampak kumulatif besar.',
        'Jangan duduk diam lebih dari 60 menit berturut-turut.'
      ],
      relatedIds: [4, 6, 1]
    }
  };

  // Article DOM elements
  const articleCardsListContainer = document.getElementById('article-cards-list');
  const inputArticleSearch = document.getElementById('input-article-search');
  const btnClearArticleSearch = document.getElementById('btn-clear-article-search');
  const articleEmptySearch = document.getElementById('article-empty-search');
  const emptySearchQuery = document.getElementById('empty-search-query');
  const btnResetSearch = document.getElementById('btn-reset-search');
  const bannerFeaturedArticle = document.getElementById('banner-featured-article');

  const btnBackFromArticleList = document.getElementById('btn-back-from-article-list');
  const btnBackFromArticleDetail = document.getElementById('btn-back-from-article-detail');
  const btnHeroFloatingBack = document.getElementById('btn-hero-floating-back');
  const articleDetailScrollView = document.getElementById('article-detail-scroll-view');
  const articleDetailStickyBar = document.getElementById('article-detail-sticky-bar');
  const articleDetailStickyTitle = document.getElementById('article-detail-sticky-title');
  const heroCanvasArt = document.getElementById('hero-canvas-art');
  const articleDetailHeroCanvas = document.getElementById('article-detail-hero-canvas');

  const btnBookmarkArticle = document.getElementById('btn-bookmark-article');
  const btnShareArticle = document.getElementById('btn-share-article');
  const btnSeeAllArticles = document.getElementById('btn-see-all-articles');
  const homeHorizontalArticleCards = document.querySelectorAll('.articles-horizontal-scroll .article-card');

  // Bottom Navigation on Article List Screen
  const articleNavHome = document.getElementById('article-nav-home');
  const articleNavStats = document.getElementById('article-nav-stats');
  const articleNavSettings = document.getElementById('article-nav-settings');

  let currentActiveArticleId = 1;

  /**
   * Render Article Cards into List with Filter Query
   */
  function renderArticleCards(query = '') {
    if (!articleCardsListContainer) return;

    const cleanQuery = query.trim().toLowerCase();
    const allArticleList = Object.values(articlesData);

    const filtered = allArticleList.filter(art => {
      if (!cleanQuery) return true;
      const matchTitle = (art.title || '').toLowerCase().includes(cleanQuery);
      const matchSnippet = (art.snippet || '').toLowerCase().includes(cleanQuery);
      const matchCategory = (art.category || '').toLowerCase().includes(cleanQuery);
      return matchTitle || matchSnippet || matchCategory;
    });

    if (filtered.length === 0) {
      articleCardsListContainer.innerHTML = '';
      if (articleEmptySearch) {
        articleEmptySearch.classList.remove('hidden');
        if (emptySearchQuery) emptySearchQuery.textContent = query;
      }
      return;
    }

    if (articleEmptySearch) articleEmptySearch.classList.add('hidden');

    articleCardsListContainer.innerHTML = filtered.map(art => `
      <div class="article-item-card" data-article-id="${art.id}" role="button" tabindex="0">
        <div class="article-card-thumb-col">
          ${art.thumbSvg}
        </div>
        <div class="article-card-info-col">
          <div class="article-card-info-top">
            <h4 class="article-card-title">${art.title}</h4>
            <p class="article-card-snippet">${art.snippet}</p>
          </div>
          <div class="article-card-info-bottom">
            <button type="button" class="btn-article-more" data-article-id="${art.id}">
              <span>Selengkapnya</span>
              <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="9 18 15 12 9 6" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    `).join('');

    // Attach click listeners to each card and Selengkapnya button
    const cardElements = articleCardsListContainer.querySelectorAll('.article-item-card');
    cardElements.forEach(card => {
      card.addEventListener('click', () => {
        const id = card.getAttribute('data-article-id');
        openArticleDetail(id, 'article-list');
      });
    });

    const moreButtons = articleCardsListContainer.querySelectorAll('.btn-article-more');
    moreButtons.forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const id = btn.getAttribute('data-article-id');
        openArticleDetail(id, 'article-list');
      });
    });
  }

  /**
   * Open Article Detail Screen with Animation & Formatted Body
   */
  function openArticleDetail(articleId, sourceScreen = 'article-list') {
    const art = articlesData[articleId] || articlesData[1];
    currentActiveArticleId = art.id;
    previousScreenForArticle = sourceScreen;

    // Populate Detail Screen Elements
    if (heroCanvasArt) heroCanvasArt.innerHTML = art.heroSvg;
    const catEl = document.getElementById('article-detail-category');
    if (catEl) catEl.textContent = art.category;
    const readTimeEl = document.getElementById('article-detail-readtime');
    if (readTimeEl) readTimeEl.textContent = `⏱️ ${art.readTime}`;
    const mainTitleEl = document.getElementById('article-detail-main-title');
    if (mainTitleEl) mainTitleEl.textContent = art.title;
    if (articleDetailStickyTitle) articleDetailStickyTitle.textContent = art.title;
    const authorEl = document.getElementById('article-detail-author');
    if (authorEl) authorEl.textContent = art.author;
    const dateEl = document.getElementById('article-detail-date');
    if (dateEl) dateEl.textContent = art.date;
    const bodyEl = document.getElementById('article-detail-body-content');
    if (bodyEl) bodyEl.innerHTML = art.contentHtml;

    // Takeaways list
    const takeawaysList = document.getElementById('article-takeaways-list');
    if (takeawaysList && art.takeaways) {
      takeawaysList.innerHTML = art.takeaways.map(item => `<li>${item}</li>`).join('');
    }

    // Related Articles grid
    const relatedGrid = document.getElementById('related-articles-grid');
    if (relatedGrid) {
      const relIds = art.relatedIds || [1, 2, 3];
      relatedGrid.innerHTML = relIds.map(rid => {
        const rArt = articlesData[rid];
        if (!rArt) return '';
        return `
          <div class="related-mini-card" data-rel-id="${rArt.id}" role="button" tabindex="0">
            <span class="related-mini-title">${rArt.title}</span>
            <div class="related-mini-chevron">
              <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="9 18 15 12 9 6" />
              </svg>
            </div>
          </div>
        `;
      }).join('');

      relatedGrid.querySelectorAll('.related-mini-card').forEach(item => {
        item.addEventListener('click', () => {
          const targetId = item.getAttribute('data-rel-id');
          openArticleDetail(targetId, sourceScreen);
        });
      });
    }

    // Reset sticky header & floating button states
    if (articleDetailStickyBar) articleDetailStickyBar.classList.remove('visible');
    if (btnHeroFloatingBack) btnHeroFloatingBack.classList.remove('hidden-fade');
    if (articleDetailHeroCanvas) articleDetailHeroCanvas.style.transform = 'translateY(0px)';

    // Show Detail Screen
    showScreen('article-detail');
  }

  // Live Search Input Listener
  if (inputArticleSearch) {
    inputArticleSearch.addEventListener('input', (e) => {
      const val = e.target.value;
      if (btnClearArticleSearch) {
        btnClearArticleSearch.classList.toggle('hidden', !val);
      }
      renderArticleCards(val);
    });
  }

  if (btnClearArticleSearch) {
    btnClearArticleSearch.addEventListener('click', () => {
      if (inputArticleSearch) {
        inputArticleSearch.value = '';
        inputArticleSearch.focus();
      }
      btnClearArticleSearch.classList.add('hidden');
      renderArticleCards('');
    });
  }

  if (btnResetSearch) {
    btnResetSearch.addEventListener('click', () => {
      if (inputArticleSearch) inputArticleSearch.value = '';
      if (btnClearArticleSearch) btnClearArticleSearch.classList.add('hidden');
      renderArticleCards('');
    });
  }

  // Top Featured Banner Click -> Open Article 6 (Yuk, Kenali Pola Hidup Sehat untuk Cegah Obesitas)
  if (bannerFeaturedArticle) {
    bannerFeaturedArticle.addEventListener('click', () => {
      openArticleDetail(6, 'article-list');
    });
  }

  // Article Detail Parallax and Sticky Header Scroll Listener
  if (articleDetailScrollView) {
    articleDetailScrollView.addEventListener('scroll', () => {
      const st = articleDetailScrollView.scrollTop;

      // Parallax smooth translation on hero banner
      if (articleDetailHeroCanvas) {
        if (st >= 0 && st < 220) {
          articleDetailHeroCanvas.style.transform = `translateY(${st * 0.35}px)`;
        }
      }

      // Transition sticky header bar & floating back button
      if (st > 110) {
        if (articleDetailStickyBar) articleDetailStickyBar.classList.add('visible');
        if (btnHeroFloatingBack) btnHeroFloatingBack.classList.add('hidden-fade');
      } else {
        if (articleDetailStickyBar) articleDetailStickyBar.classList.remove('visible');
        if (btnHeroFloatingBack) btnHeroFloatingBack.classList.remove('hidden-fade');
      }
    });
  }

  // Back Navigation Handlers
  if (btnBackFromArticleList) {
    btnBackFromArticleList.addEventListener('click', () => {
      showScreen('home');
    });
  }

  if (btnBackFromArticleDetail) {
    btnBackFromArticleDetail.addEventListener('click', () => {
      showScreen(previousScreenForArticle || 'article-list');
    });
  }

  if (btnHeroFloatingBack) {
    btnHeroFloatingBack.addEventListener('click', () => {
      showScreen(previousScreenForArticle || 'article-list');
    });
  }

  // Connect Home screen "SELENGKAPNYA" button to Article List screen
  if (btnSeeAllArticles) {
    btnSeeAllArticles.addEventListener('click', () => {
      showScreen('article-list');
    });
  }

  // Connect Horizontal Article Cards on Home Screen to Detail Screen
  homeHorizontalArticleCards.forEach(card => {
    card.addEventListener('click', () => {
      const id = card.getAttribute('data-article-id') || '1';
      openArticleDetail(id, 'home');
    });
  });

  // Preview Toolbar Shortcut
  if (btnDemoArticles) {
    btnDemoArticles.addEventListener('click', () => {
      showScreen('article-list');
    });
  }

  // Bottom Navigation on Article List Screen
  if (articleNavHome) {
    articleNavHome.addEventListener('click', () => showScreen('home'));
  }
  if (articleNavStats) {
    articleNavStats.addEventListener('click', () => {
      showScreen('home');
      switchHomeTab('stats');
    });
  }
  if (articleNavSettings) {
    articleNavSettings.addEventListener('click', () => {
      showScreen('home');
      switchHomeTab('settings');
    });
  }

  // Share & Bookmark Toast Actions
  if (btnShareArticle) {
    btnShareArticle.addEventListener('click', () => {
      const art = articlesData[currentActiveArticleId] || articlesData[1];
      if (navigator.share) {
        navigator.share({
          title: art.title,
          text: art.snippet,
          url: window.location.href
        }).catch(() => {});
      } else {
        navigator.clipboard?.writeText(window.location.href);
        showToast('Tautan Disalin', `Tautan artikel "${art.title}" berhasil disalin ke papan klip.`);
      }
    });
  }

  if (btnBookmarkArticle) {
    btnBookmarkArticle.addEventListener('click', () => {
      const art = articlesData[currentActiveArticleId] || articlesData[1];
      showToast('Artikel Disimpan', `Artikel "${art.title}" telah ditambahkan ke daftar bacaan.`);
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

  // Initial data load
  loadUserProfile(currentUser.email);
  updateReminderBannerVisibility();

  // URL Hash Navigation / Direct Route Support
  const initialHash = (window.location.hash || '').toLowerCase();
  if (initialHash === '#profile' || initialHash === '#profil') {
    clearAllTimers();
    showScreen('profile');
  } else if (initialHash === '#edit' || initialHash === '#edit-profile') {
    clearAllTimers();
    showScreen('edit-profile');
  } else if (initialHash === '#articles' || initialHash === '#artikel' || initialHash === '#daftar-artikel') {
    clearAllTimers();
    showScreen('article-list');
  } else if (initialHash === '#home' || initialHash === '#beranda') {
    clearAllTimers();
    showScreen('home');
  } else if (splashScreen) {
    runSplashAnimation();
  } else if (document.getElementById('tab-content-settings')) {
    switchSettingsSubpage('main');
  }

  // Window hashchange listener
  window.addEventListener('hashchange', () => {
    const h = (window.location.hash || '').toLowerCase();
    if (h === '#profile' || h === '#profil') showScreen('profile');
    else if (h === '#edit' || h === '#edit-profile') showScreen('edit-profile');
    else if (h === '#articles' || h === '#artikel' || h === '#daftar-artikel') showScreen('article-list');
    else if (h === '#home' || h === '#beranda') showScreen('home');
  });
});

