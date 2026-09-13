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
      const userGreeting = document.getElementById('user-greeting-name');
      if (userGreeting) userGreeting.textContent = `Halo, ${name || 'Zahra Fitriana'}!`;
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
        (cleanId === 'zahraafitriana@gmail.com' || cleanId === 'zahraafitriana' || cleanId === 'zahrafitrie@gmail.com') &&
        (password === 'Zahra1234' || password === 'zahra1234' || password === 'zohf1234')
      ) {
        navigateToDashboard('user', 'Zahra Fitriana');
        return;
      }

      // Invalid credentials
      authErrorBanner.classList.remove('hidden');
    });
  }

  // Logout handlers
  if (btnUserLogout) {
    btnUserLogout.addEventListener('click', () => {
      userDash.classList.add('hidden');
      authScreen.classList.remove('hidden');
      if (inputPassword) inputPassword.value = '';
      clearErrors();
      showToast('Sesi Berakhir', 'Anda telah keluar dari akun.');
    });
  }

  if (btnAdminLogout) {
    btnAdminLogout.addEventListener('click', () => {
      adminDash.classList.add('hidden');
      authScreen.classList.remove('hidden');
      if (inputPassword) inputPassword.value = '';
      clearErrors();
      showToast('Sesi Berakhir', 'Anda telah keluar dari akun Admin.');
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
