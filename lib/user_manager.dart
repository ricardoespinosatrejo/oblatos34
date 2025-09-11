import 'package:flutter/foundation.dart';

class UserManager extends ChangeNotifier {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  String _userName = 'Usuario';
  String _userEmail = '';
  Map<String, dynamic>? _currentUser;
  
  // Sistema de puntos
  int _puntos = 0;
  DateTime? _ultimaSesion;
  int _rachaDias = 0;
  DateTime? _fechaInicioRacha;
  DateTime? _ultimoBonusRacha;

  String get userName => _userName;
  String get userEmail => _userEmail;
  Map<String, dynamic>? get currentUser => _currentUser;
  
  // Getters para el sistema de puntos
  int get puntos => _puntos;
  DateTime? get ultimaSesion => _ultimaSesion;
  int get rachaDias => _rachaDias;
  DateTime? get fechaInicioRacha => _fechaInicioRacha;
  DateTime? get ultimoBonusRacha => _ultimoBonusRacha;

  void setUserInfo(String name, String email) {
    _userName = name.isNotEmpty ? name : 'Usuario';
    _userEmail = email;
    notifyListeners();
  }

  void setCurrentUser(Map<String, dynamic> user) {
    _currentUser = user;
    _userName = user['nombre_usuario'] ?? 'Usuario';
    _userEmail = user['email'] ?? '';
    
    // Cargar datos del sistema de puntos
    _puntos = user['puntos'] ?? 0;
    _ultimaSesion = user['ultima_sesion'] != null 
        ? DateTime.parse(user['ultima_sesion']) 
        : null;
    _rachaDias = user['racha_dias'] ?? 0;
    _fechaInicioRacha = user['fecha_inicio_racha'] != null 
        ? DateTime.parse(user['fecha_inicio_racha']) 
        : null;
    _ultimoBonusRacha = user['ultimo_bonus_racha'] != null 
        ? DateTime.parse(user['ultimo_bonus_racha']) 
        : null;
    
    notifyListeners();
  }

  void clearUserInfo() {
    _userName = 'Usuario';
    _userEmail = '';
    _currentUser = null;
    
    // Limpiar datos del sistema de puntos
    _puntos = 0;
    _ultimaSesion = null;
    _rachaDias = 0;
    _fechaInicioRacha = null;
    _ultimoBonusRacha = null;
    
    notifyListeners();
  }

  void updateProfileImage(int imageNumber) {
    if (_currentUser != null) {
      _currentUser!['profile_image'] = imageNumber;
      notifyListeners();
    }
  }

  // ===== SISTEMA DE PUNTOS =====
  
  /// Agregar puntos al usuario
  void addPuntos(int cantidad) {
    _puntos += cantidad;
    if (_currentUser != null) {
      _currentUser!['puntos'] = _puntos;
    }
    notifyListeners();
  }
  
  /// Actualizar puntos del usuario (desde base de datos)
  void updateUserPoints(int newTotalPoints) {
    _puntos = newTotalPoints;
    if (_currentUser != null) {
      _currentUser!['puntos'] = _puntos;
    }
    notifyListeners();
  }
  
  /// Actualizar sesión diaria y calcular puntos
  void updateSesionDiaria() {
    final hoy = DateTime.now();
    final hoyDate = DateTime(hoy.year, hoy.month, hoy.day);
    
    if (_ultimaSesion == null) {
      // Primera sesión
      _ultimaSesion = hoyDate;
      _fechaInicioRacha = hoyDate;
      _rachaDias = 1;
      _puntos += 2; // Puntos por primera sesión del día
    } else {
      final ultimaSesionDate = DateTime(
        _ultimaSesion!.year, 
        _ultimaSesion!.month, 
        _ultimaSesion!.day
      );
      
      if (hoyDate.isAfter(ultimaSesionDate)) {
        // Nueva sesión del día
        _ultimaSesion = hoyDate;
        _puntos += 2; // Puntos por sesión diaria
        
        // Verificar si es día consecutivo
        if (ultimaSesionDate.isAtSameMomentAs(
          DateTime(hoy.year, hoy.month, hoy.day - 1)
        )) {
          _rachaDias++;
          _checkBonusRacha();
        } else {
          // Rompió la racha
          _rachaDias = 1;
          _fechaInicioRacha = hoyDate;
        }
      }
    }
    
    // Actualizar currentUser
    if (_currentUser != null) {
      _currentUser!['puntos'] = _puntos;
      _currentUser!['ultima_sesion'] = _ultimaSesion?.toIso8601String().split('T')[0];
      _currentUser!['racha_dias'] = _rachaDias;
      _currentUser!['fecha_inicio_racha'] = _fechaInicioRacha?.toIso8601String().split('T')[0];
      _currentUser!['ultimo_bonus_racha'] = _ultimoBonusRacha?.toIso8601String().split('T')[0];
    }
    
    notifyListeners();
  }
  
  /// Verificar y otorgar bonus por racha
  void _checkBonusRacha() {
    final hoy = DateTime.now();
    final hoyDate = DateTime(hoy.year, hoy.month, hoy.day);
    
    if (_rachaDias == 7 && _ultimoBonusRacha == null) {
      // Bonus por 7 días consecutivos
      _puntos += 50;
      _ultimoBonusRacha = hoyDate;
      if (_currentUser != null) {
        _currentUser!['puntos'] = _puntos;
        _currentUser!['ultimo_bonus_racha'] = _ultimoBonusRacha?.toIso8601String().split('T')[0];
      }
    } else if (_rachaDias == 30 && 
               (_ultimoBonusRacha == null || 
                _ultimoBonusRacha!.isBefore(DateTime(hoy.year, hoy.month, hoy.day - 7)))) {
      // Bonus por 30 días consecutivos
      _puntos += 200;
      _ultimoBonusRacha = hoyDate;
      if (_currentUser != null) {
        _currentUser!['puntos'] = _puntos;
        _currentUser!['ultimo_bonus_racha'] = _ultimoBonusRacha?.toIso8601String().split('T')[0];
      }
    }
  }
  
  /// Obtener puntos por actividad específica
  int getPuntosActividad(String actividad) {
    switch (actividad.toLowerCase()) {
      case 'caja':
        return 10;
      case 'aprendiendo':
        return 5;
      case 'videoblog':
        return 3;
      case 'poder':
        return 15;
      default:
        return 0;
    }
  }
  
  /// Completar actividad y sumar puntos
  void completarActividad(String actividad) {
    final puntosGanados = getPuntosActividad(actividad);
    addPuntos(puntosGanados);
    
    // También actualizar sesión diaria
    updateSesionDiaria();
  }
}
