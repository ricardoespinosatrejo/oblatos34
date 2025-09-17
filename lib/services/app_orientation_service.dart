class AppOrientationService {
  AppOrientationService._internal();
  static final AppOrientationService _instance = AppOrientationService._internal();
  factory AppOrientationService() => _instance;

  bool _allowLandscape = false;

  bool get allowLandscape => _allowLandscape;

  void setAllowLandscape(bool value) {
    _allowLandscape = value;
  }
}




