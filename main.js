/**
 * OBESIGHT - SPLASH SCREEN & AUTHENTICATION CONTROLLER
 * Orchestrates the exact Figma splash animation and initial screen interactions
 */

document.addEventListener('DOMContentLoaded', () => {
  // Elements
  const splashScreen = document.getElementById('splash-screen');
  const authScreen = document.getElementById('auth-screen');
  const statusBar = document.getElementById('phone-status-bar');
  const btnSkipSplash = document.getElementById('btn-skip-splash');
  const btnReplay = document.getElementById('btn-replay');
  const btnToggleFrame = document.getElementById('btn-toggle-frame');
  const frameToggleLabel = document.getElementById('frame-toggle-label');
  const viewportWrapper = document.getElementById('viewport-wrapper');

  // Auth Tabs & Form
  const tabLogin = document.getElementById('tab-login');
  const tabRegister = document.getElementById('tab-register');
  const authTabs = document.querySelector('.auth-tabs');
  const fieldNameGroup = document.getElementById('field-name-group');
  const submitBtnText = document.getElementById('submit-btn-text');
  const googleBtnText = document.getElementById('google-btn-text');
  const authTitle = document.querySelector('.auth-title');
  const authSubtitle = document.querySelector('.auth-subtitle');
  const authForm = document.getElementById('auth-form');

  // Password Toggle
  const inputPassword = document.getElementById('input-password');
  const btnTogglePwd = document.getElementById('btn-toggle-pwd');

  // Google Modal & Toast
  const btnGoogleAuth = document.getElementById('btn-google-auth');
  const googleModalBackdrop = document.getElementById('google-modal-backdrop');
  const btnCloseGoogleModal = document.getElementById('btn-close-google-modal');
  const btnCancelGoogle = document.getElementById('btn-cancel-google');
  const googleAccountItems = document.querySelectorAll('.google-account-item');
  const toastNotification = document.getElementById('toast-notification');
  const toastTitle = document.getElementById('toast-title');
  const toastMsg = document.getElementById('toast-msg');

  // Animation Timers
  let animationTimers = [];

  function clearAllTimers() {
    animationTimers.forEach(t => clearTimeout(t));
    animationTimers = [];
  }

  /**
   * Run Splash Animation Sequence
   * 1. Initial State: Green background (#529A7B), small logo centered (Figma image 1)
   * 2. White Ellipse zooms in from center (Figma image 2)
   * 3. Center Logo Fade-in for 2 seconds (Figma image 2 & 3)
   * 4. Logo shifts smoothly to the left (Figma image 4)
   * 5. Brand text "ObeSight" reveals beside logo (Figma image 5)
   * 6. Splash dissolves, Auth screen emerges
   */
  function runSplashAnimation() {
    clearAllTimers();

    // Reset visual states
    splashScreen.className = 'splash-screen stage-init';
    splashScreen.style.display = 'flex';
    authScreen.className = 'auth-screen hidden';
    statusBar.classList.remove('dark-text');

    // Stage 2: Ellipse Zoom-In begins (at 700ms)
    animationTimers.push(setTimeout(() => {
      splashScreen.classList.add('stage-ellipse');
    }, 700));

    // Stage 3: Logo Fade-In 2 Seconds (at 1400ms)
    animationTimers.push(setTimeout(() => {
      splashScreen.classList.add('stage-logo-fadein');
      statusBar.classList.add('dark-text'); // background is now white
    }, 1400));

    // Stage 4: Logo Shifts Left (at 3500ms - after 2s fade-in)
    animationTimers.push(setTimeout(() => {
      splashScreen.classList.add('stage-logo-shift');
    }, 3500));

    // Stage 5: "ObeSight" Text Reveals beside Logo (at 4000ms)
    animationTimers.push(setTimeout(() => {
      splashScreen.classList.add('stage-text-reveal');
    }, 4000));

    // Stage 6: Transition to Auth / Login Screen (at 5400ms)
    animationTimers.push(setTimeout(() => {
      transitionToAuth();
    }, 5400));
  }

  function transitionToAuth() {
    clearAllTimers();
    splashScreen.classList.add('fade-out');
    
    setTimeout(() => {
      splashScreen.style.display = 'none';
      authScreen.classList.remove('hidden');
      authScreen.classList.add('visible');
    }, 400);
  }

  // Skip Splash Button
  if (btnSkipSplash) {
    btnSkipSplash.addEventListener('click', () => {
      transitionToAuth();
    });
  }

  // Replay Animation Button
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

  // Auth Tabs (Masuk vs Daftar Baru)
  function setAuthMode(mode) {
    if (mode === 'register') {
      tabRegister.classList.add('active');
      tabRegister.setAttribute('aria-selected', 'true');
      tabLogin.classList.remove('active');
      tabLogin.setAttribute('aria-selected', 'false');
      authTabs.classList.add('tab-register-active');

      fieldNameGroup.classList.remove('hidden');
      submitBtnText.textContent = 'Daftar Akun ObeSight';
      googleBtnText.textContent = 'Daftar dengan Google';
      authTitle.textContent = 'Mulai Perjalanan Anda';
      authSubtitle.textContent = 'Daftar akun ObeSight dan raih pola hidup sehat yang terukur.';
    } else {
      tabLogin.classList.add('active');
      tabLogin.setAttribute('aria-selected', 'true');
      tabRegister.classList.remove('active');
      tabRegister.setAttribute('aria-selected', 'false');
      authTabs.classList.remove('tab-register-active');

      fieldNameGroup.classList.add('hidden');
      submitBtnText.textContent = 'Masuk ke ObeSight';
      googleBtnText.textContent = 'Lanjutkan dengan Google';
      authTitle.textContent = 'Selamat Datang Kembali';
      authSubtitle.textContent = 'Kelola dan pantau pola hidup sehat Anda dengan panduan akurat ObeSight.';
    }
  }

  tabLogin.addEventListener('click', () => setAuthMode('login'));
  tabRegister.addEventListener('click', () => setAuthMode('register'));

  // Password Visibility Toggle
  if (btnTogglePwd && inputPassword) {
    btnTogglePwd.addEventListener('click', () => {
      const isPassword = inputPassword.type === 'password';
      inputPassword.type = isPassword ? 'text' : 'password';
      btnTogglePwd.innerHTML = isPassword 
        ? `<svg class="eye-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>`
        : `<svg class="eye-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>`;
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

  // Google Sign In Modal
  btnGoogleAuth.addEventListener('click', () => {
    googleModalBackdrop.classList.remove('hidden');
  });

  function closeGoogleModal() {
    googleModalBackdrop.classList.add('hidden');
  }

  btnCloseGoogleModal.addEventListener('click', closeGoogleModal);
  btnCancelGoogle.addEventListener('click', closeGoogleModal);
  googleModalBackdrop.addEventListener('click', (e) => {
    if (e.target === googleModalBackdrop) {
      closeGoogleModal();
    }
  });

  // Google Account Select
  googleAccountItems.forEach(item => {
    item.addEventListener('click', () => {
      const name = item.getAttribute('data-name');
      const email = item.getAttribute('data-email');
      closeGoogleModal();

      showToast(`Halo, ${name}!`, `Berhasil masuk via Google (${email}).`);
    });
  });

  // Form Submit
  authForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const isRegister = tabRegister.classList.contains('active');
    const email = document.getElementById('input-email').value;

    showToast(
      isRegister ? 'Pendaftaran Berhasil!' : 'Berhasil Masuk!',
      `Selamat datang di ObeSight (${email}).`
    );
  });

  // Start the Splash sequence on initial load
  runSplashAnimation();
});
