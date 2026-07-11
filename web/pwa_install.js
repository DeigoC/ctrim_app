// PWA install bridge for Flutter web (beforeinstallprompt + iOS detection).
(function () {
  let deferredPrompt = null;

  function isStandalone() {
    return (
      window.matchMedia('(display-mode: standalone)').matches ||
      window.navigator.standalone === true
    );
  }

  function isIosBrowser() {
    const ua = window.navigator.userAgent;
    const isAppleMobile = /iPad|iPhone|iPod/.test(ua);
    const isIpadOs =
      navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1;
    return isAppleMobile || isIpadOs;
  }

  function notifyAvailability() {
    window.dispatchEvent(new Event('ctrim-pwa-install-available'));
  }

  window.addEventListener('beforeinstallprompt', function (event) {
    event.preventDefault();
    deferredPrompt = event;
    notifyAvailability();
  });

  window.addEventListener('appinstalled', function () {
    deferredPrompt = null;
    notifyAvailability();
  });

  window.ctrimPwaInstall = {
    canPrompt: function () {
      return !!deferredPrompt;
    },
    isStandalone: isStandalone,
    isIos: isIosBrowser,
    promptInstall: async function () {
      if (!deferredPrompt) {
        return 'unavailable';
      }

      deferredPrompt.prompt();
      const choice = await deferredPrompt.userChoice;
      deferredPrompt = null;
      notifyAvailability();
      return choice.outcome;
    },
  };
})();
