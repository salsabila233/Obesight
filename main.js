/**
 * OBESIGHT - SPLASH SCREEN & AUTHENTICATION CONTROLLER
 * Connects the multi-stage animated splash to the Figma Login Screen
 * Supports multi-role dashboards (User vs Admin), animated illustration, and Google account picker
 */

document.addEventListener('DOMContentLoaded', () => {
  // Navigation & Screens
  const splashScreen = document.getElementById('splash-screen');
  const authScreen = document.getElementById('auth-screen');
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
   * Run Splash Animation Sequence
   * 1. Initial State: Green background (#529A7B), small logo centered
   * 2. White Ellipse zooms in from center
   * 3. Center Logo Fade-in
   * 4. Logo shifts smoothly to the left
   * 5. Brand text "ObeSight" reveals beside logo
   * 6. Transition to Login Screen
   */
  function runSplashAnimation() {
    clearAllTimers();

    // Reset visual states
    splashScreen.className = 'splash-screen stage-init';
    splashScreen.style.display = 'flex';
    authScreen.classList.add('hidden');
    if (userDash) userDash.classList.add('hidden');
    if (adminDash) adminDash.classList.add('hidden');
    statusBar.classList.remove('dark-text');

    // Stage 2: Ellipse Zoom-In begins (at 700ms)
    animationTimers.push(setTimeout(() => {
      splashScreen.classList.add('stage-ellipse');
    }, 700));

    // Stage 3: Logo Fade-In (at 1400ms)
    animationTimers.push(setTimeout(() => {
      splashScreen.classList.add('stage-logo-fadein');
      statusBar.classList.add('dark-text');
    }, 1400));

    // Stage 4: Logo Shifts Left (at 3200ms)
    animationTimers.push(setTimeout(() => {
      splashScreen.classList.add('stage-logo-shift');
    }, 3200));

    // Stage 5: "ObeSight" Text Reveals beside Logo (at 3800ms)
    animationTimers.push(setTimeout(() => {
      splashScreen.classList.add('stage-text-reveal');
    }, 3800));

    // Stage 6: Transition to Login Screen (at 5200ms)
    animationTimers.push(setTimeout(() => {
      transitionToLogin();
    }, 5200));
  }

  function transitionToLogin() {
    clearAllTimers();
    splashScreen.classList.add('fade-out');

    setTimeout(() => {
      splashScreen.style.display = 'none';
      authScreen.classList.remove('hidden');
      if (userDash) userDash.classList.add('hidden');
      if (adminDash) adminDash.classList.add('hidden');
    }, 400);
  }

  // Skip Splash Button
  if (btnSkipSplash) {
    btnSkipSplash.addEventListener('click', transitionToLogin);
  }

  // Replay Animation Button
  if (btnReplay) {
    btnReplay.addEventListener('click', runSplashAnimation);
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
    role: 'user'
  };

  function updateUserData(fullName) {
    currentUser.name = fullName || 'Zahra Fitriana';
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
  }

  function navigateToDashboard(role, name) {
    authScreen.classList.add('hidden');
    if (role === 'admin') {
      adminDash.classList.remove('hidden');
      userDash.classList.add('hidden');
      const adminGreeting = document.getElementById('admin-greeting-name');
      if (adminGreeting) adminGreeting.textContent = name || 'Dr. Hendra Wijaya, Sp.GK';
    } else {
      userDash.classList.remove('hidden');
      adminDash.classList.add('hidden');
      updateUserData(name || 'Zahra Fitriana');
      // Reset to Home Tab
      switchHomeTab('home');
    }
    showToast('Berhasil Masuk!', `Selamat datang di Beranda ${role === 'admin' ? 'Administrator' : 'Pengguna'}.`);
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
        navigateToDashboard('admin', 'Dr. Hendra Wijaya, Sp.GK');
        return;
      }

      // Normal user check
      if (
        (cleanId === 'zahraafitriana@gmail.com' || cleanId === 'zahraafitriana' || cleanId === 'zahrafitrie@gmail.com' || cleanId === 'zahra') &&
        (password === 'Zahra1234' || password === 'zahra1234' || password === 'zohf1234')
      ) {
        navigateToDashboard('user', 'Zahra Fitriana');
        return;
      }

      // Allow any custom user name demo if password matches
      if (password === '123456' || password === 'password' || password === 'Zahra1234' || password === 'zahra1234') {
        const displayName = identifier.includes('@') ? identifier.split('@')[0] : identifier;
        const capitalized = displayName.charAt(0).toUpperCase() + displayName.slice(1);
        navigateToDashboard('user', capitalized);
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
    authScreen.classList.remove('hidden');
    if (inputPassword) inputPassword.value = '';
    const profileDropdown = document.getElementById('profile-dropdown');
    if (profileDropdown) profileDropdown.classList.add('hidden');
    clearErrors();
    showToast('Sesi Berakhir', 'Anda telah keluar dari akun.');
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

  // Skrining Obesitas Modal Handlers
  const btnStartScreening = document.getElementById('btn-start-screening');
  const screeningModal = document.getElementById('screening-modal-backdrop');
  const btnCloseScreeningModal = document.getElementById('btn-close-screening-modal');
  const btnCalcScreening = document.getElementById('btn-calc-screening');
  const screeningResultBox = document.getElementById('screening-result-box');

  if (btnStartScreening && screeningModal) {
    btnStartScreening.addEventListener('click', () => {
      screeningModal.classList.remove('hidden');
      if (screeningResultBox) screeningResultBox.classList.add('hidden');
    });
  }

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
    if (bmiVal < 18.5) {
      if (bmiCalcCategory) bmiCalcCategory.textContent = 'Kurus (Kekurangan Berat)';
      if (bmiCalcAdvice) bmiCalcAdvice.textContent = 'Tingkatkan asupan kalori bernutrisi dan protein untuk mencapai berat badan ideal.';
      if (bmiCalcScore) bmiCalcScore.style.color = '#0284C7';
    } else if (bmiVal <= 22.9) {
      if (bmiCalcCategory) bmiCalcCategory.textContent = 'Normal (Berat Ideal)';
      if (bmiCalcAdvice) bmiCalcAdvice.textContent = 'Selamat! Berat badan Anda ideal. Pertahankan dengan pola makan bergizi dan olahraga teratur.';
      if (bmiCalcScore) bmiCalcScore.style.color = '#15803D';
    } else if (bmiVal <= 24.9) {
      if (bmiCalcCategory) bmiCalcCategory.textContent = 'Kelebihan Berat Badan (Overweight)';
      if (bmiCalcAdvice) bmiCalcAdvice.textContent = 'Waspada peningkatan berat badan. Kurangi karbohidrat olahan dan gula tambahan.';
      if (bmiCalcScore) bmiCalcScore.style.color = '#D97706';
    } else {
      if (bmiCalcCategory) bmiCalcCategory.textContent = 'Obesitas';
      if (bmiCalcAdvice) bmiCalcAdvice.textContent = 'Disarankan untuk melakukan penyesuaian defisit kalori sehat dan konsultasi medis.';
      if (bmiCalcScore) bmiCalcScore.style.color = '#DC2626';
    }
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
        updateUserData(newName);
      }
      biodataModal.classList.add('hidden');
      showToast('Biodata Tersimpan', 'Informasi profil dan kesehatan Anda telah diperbarui.');
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
      googleModalBackdrop.classList.remove('hidden');
    });
  }

  function closeGoogleModal() {
    googleModalBackdrop.classList.add('hidden');
  }

  if (btnCloseGoogleModal) btnCloseGoogleModal.addEventListener('click', closeGoogleModal);
  if (btnCancelGoogle) btnCancelGoogle.addEventListener('click', closeGoogleModal);
  if (googleModalBackdrop) {
    googleModalBackdrop.addEventListener('click', (e) => {
      if (e.target === googleModalBackdrop) closeGoogleModal();
    });
  }

  // Google Account Select
  googleAccountItems.forEach(item => {
    item.addEventListener('click', () => {
      const role = item.getAttribute('data-role');
      const name = item.getAttribute('data-name');
      closeGoogleModal();
      navigateToDashboard(role, name);
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

