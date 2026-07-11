import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:universal_html/js.dart' as js;

enum PwaInstallResult {
  accepted,
  dismissed,
  unavailable,
}

/// Web-only bridge to `window.ctrimPwaInstall` in `web/pwa_install.js`.
class PwaInstallService {
  PwaInstallService._();

  static final PwaInstallService instance = PwaInstallService._();

  dynamic get _bridge {
    if (!kIsWeb) return null;
    return js.context['ctrimPwaInstall'];
  }

  bool get isInstalled {
    if (!kIsWeb) return false;
    try {
      final bridge = _bridge;
      if (bridge == null) return false;
      return js.callMethod(bridge, 'isStandalone', []) == true;
    } catch (_) {
      return false;
    }
  }

  bool get canPromptInstall {
    if (!kIsWeb || isInstalled) return false;
    try {
      final bridge = _bridge;
      if (bridge == null) return false;
      return js.callMethod(bridge, 'canPrompt', []) == true;
    } catch (_) {
      return false;
    }
  }

  bool get isIosBrowser {
    if (!kIsWeb) return false;
    try {
      final bridge = _bridge;
      if (bridge == null) return false;
      return js.callMethod(bridge, 'isIos', []) == true;
    } catch (_) {
      return false;
    }
  }

  bool get shouldShowInstallOption => kIsWeb && !isInstalled;

  String get installSubtitle {
    if (canPromptInstall) {
      return 'Install CTRIM as a home screen app';
    }
    if (isIosBrowser) {
      return 'Add to your home screen via Safari';
    }
    return 'Install from your browser menu';
  }

  void listenForAvailability(void Function() onAvailable) {
    if (!kIsWeb) return;
    html.window.addEventListener('ctrim-pwa-install-available', (_) => onAvailable());
  }

  Future<PwaInstallResult> promptInstall() async {
    if (!kIsWeb) return PwaInstallResult.unavailable;
    try {
      final bridge = _bridge;
      if (bridge == null) return PwaInstallResult.unavailable;

      final outcome = await js.promiseToFuture(
        js.callMethod(bridge, 'promptInstall', []),
      );
      return _resultFromJs(outcome?.toString());
    } catch (_) {
      return PwaInstallResult.unavailable;
    }
  }

  PwaInstallResult _resultFromJs(String? value) {
    switch (value) {
      case 'accepted':
        return PwaInstallResult.accepted;
      case 'dismissed':
        return PwaInstallResult.dismissed;
      default:
        return PwaInstallResult.unavailable;
    }
  }
}
