// This will utilse both approaches - SharedPref and File read/writing
import 'package:shared_preferences/shared_preferences.dart';

class AppDataManager {
  static late final SharedPreferences _pref;
  static const String _isFirstOpen = 'isFirstOpen', _email = 'email', _pass = 'password', _clear = '';

  AppDataManager({required SharedPreferences preferences}) {
    _pref = preferences;
  }

  void saveCreds(String email, String password) {
    _pref.setString(_email, email);
    _pref.setString(_pass, password);
  }

  void clearCreds() {
    _pref.setString(_email, _clear);
    _pref.setString(_pass, _clear);
  }

  bool get isFirstOpen => _pref.getBool(_isFirstOpen) ?? true;
  void nowOpened() => _pref.setBool(_isFirstOpen, true); // activated once user resolves notifications
}
