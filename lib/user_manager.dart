import 'package:flutter/foundation.dart';

class UserManager extends ChangeNotifier {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  String _userName = 'Usuario';
  String _userEmail = '';

  String get userName => _userName;
  String get userEmail => _userEmail;

  void setUserInfo(String name, String email) {
    _userName = name.isNotEmpty ? name : 'Usuario';
    _userEmail = email;
    notifyListeners();
  }

  void clearUserInfo() {
    _userName = 'Usuario';
    _userEmail = '';
    notifyListeners();
  }
}







