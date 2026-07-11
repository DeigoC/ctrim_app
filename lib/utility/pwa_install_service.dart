import 'dart:async';

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

  js.JsObject? get _bridge {
    if (!kIsWeb) return null;
    final bridge = js.context['ctrimPwaInstall'];
    return bridge is js.JsObject ? bridge : null;
  }

  bool get isInstalled => _callBridgeBool('isStandalone');

  bool get canPromptInstall {
    if (!kIsWeb || isInstalled) return false;
    return _callBridgeBool('canPrompt');
  }

  bool get isIosBrowser => _callBridgeBool('isIos');

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

    final bridge = _bridge;
    if (bridge == null) return PwaInstallResult.unavailable;

    final completer = Completer<PwaInstallResult>();

    void onResult(html.Event event) {
      html.window.removeEventListener('ctrim-pwa-install-result', onResult);
      final detail = event is html.CustomEvent ? event.detail?.toString() : null;
      if (!completer.isCompleted) {
        completer.complete(_resultFromJs(detail));
      }
    }

    html.window.addEventListener('ctrim-pwa-install-result', onResult);
    bridge.callMethod('promptInstall', []);
    return completer.future;
  }

  bool _callBridgeBool(String methodName) {
    if (!kIsWeb) return false;
    try {
      final bridge = _bridge;
      if (bridge == null) return false;
      return bridge.callMethod(methodName, []) == true;
    } catch (_) {
      return false;
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
