import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserManager extends ChangeNotifier {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  String _userName = 'Usuario';
  String _userEmail = '';
  Map<String, dynamic>? _currentUser;
  
  // Sistema de puntos
  int _puntos = 0; // Puntos totales (legacy, se mantiene para compatibilidad)
  DateTime? _ultimaSesion;
  int _rachaDias = 0;
  DateTime? _fechaInicioRacha;
  DateTime? _ultimoBonusRacha;
  int _puntosSnippets = 0; // Legacy, ya no se usa
  int _puntosDiarios = 0; // Legacy, ya no se usa
  int _gamePoints = 0; // Puntos del juego (independiente, para ranking)
  
  // Nuevo sistema de puntos de racha (principal)
  int _rachaPoints = 0; // Puntos acumulados por rachas

  String get userName => _userName;
  String get userEmail => _userEmail;
  Map<String, dynamic>? get currentUser => _currentUser;
  
  // Getters para el sistema de puntos
  int get puntos => _puntos; // Legacy
  int get puntosSnippets => _puntosSnippets; // Legacy
  int get puntosDiarios => _puntosDiarios; // Legacy
  int get gamePoints => _gamePoints; // Puntos del juego (independiente)
  DateTime? get ultimaSesion => _ultimaSesion;
  int get rachaDias => _rachaDias;
  DateTime? get fechaInicioRacha => _fechaInicioRacha;
  DateTime? get ultimoBonusRacha => _ultimoBonusRacha;
  int get rachaPoints => _rachaPoints; // Puntos de racha (sistema principal)

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
    _puntosSnippets = user['puntos_snippets'] ?? 0;
    _puntosDiarios = user['puntos_diarios'] ?? 0;
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
    _gamePoints = user['total_game_points'] ?? 0;
    _rachaPoints = user['racha_points'] ?? user['puntos_racha'] ?? 0; // Puntos de racha
    
    notifyListeners();
  }

  void clearUserInfo() {
    _userName = 'Usuario';
    _userEmail = '';
    _currentUser = null;
    
    // Limpiar datos del sistema de puntos
    _puntos = 0;
    _puntosSnippets = 0;
    _puntosDiarios = 0;
    _ultimaSesion = null;
    _rachaDias = 0;
    _fechaInicioRacha = null;
    _ultimoBonusRacha = null;
    _gamePoints = 0;
    _rachaPoints = 0;
    
    notifyListeners();
  }

  void updateProfileImage(int imageNumber) {
    if (_currentUser != null) {
      _currentUser!['profile_image'] = imageNumber;
      notifyListeners();
    }
  }

  // ===== SISTEMA DE PUNTOS =====
  
  /// Agregar puntos al usuario (legacy)
  void addPuntos(int cantidad) {
    _puntos += cantidad;
    if (_currentUser != null) {
      _currentUser!['puntos'] = _puntos;
    }
    notifyListeners();
  }
  
  /// Agregar puntos de racha (sistema principal)
  void addRachaPoints(int cantidad) {
    _rachaPoints += cantidad;
    if (_currentUser != null) {
      _currentUser!['racha_points'] = _rachaPoints;
    }
    notifyListeners();
  }
  
  /// Actualizar puntos de racha desde base de datos
  void updateRachaPoints(int newRachaPoints) {
    _rachaPoints = newRachaPoints;
    if (_currentUser != null) {
      _currentUser!['racha_points'] = _rachaPoints;
    }
    notifyListeners();
  }
  
  /// Actualizar días de racha desde base de datos
  void updateRachaDias(int newRachaDias) {
    _rachaDias = newRachaDias;
    if (_currentUser != null) {
      _currentUser!['racha_dias'] = _rachaDias;
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

  void updateGamePoints(int newTotalGamePoints) {
    _gamePoints = newTotalGamePoints;
    if (_currentUser != null) {
      _currentUser!['total_game_points'] = _gamePoints;
    }
    notifyListeners();
  }

  Future<void> refreshGamePoints() async {
    if (_currentUser == null || _currentUser!['id'] == null) return;
    final userId = _currentUser!['id'];
    try {
      final uri = Uri.parse('https://zumuradigital.com/app-oblatos-login/get_user_game_points.php?user_id=$userId&username=$_userName');
      if (kDebugMode) {
        print('🎮 Llamando a: $uri');
      }
      final response = await http.get(uri);
      if (kDebugMode) {
        print('🎮 Respuesta HTTP: ${response.statusCode}');
        print('🎮 Body: ${response.body}');
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          print('🎮 Data decodificada: $data');
        }
        if (data is Map && data['success'] == true) {
          // Usar highest_score (mejor puntaje de una partida) como muestra el ranking
          final rawHighest = data['highest_score'] ?? data['total_score'] ?? 0;
          if (kDebugMode) {
            print('🎮 rawHighest: $rawHighest (tipo: ${rawHighest.runtimeType})');
          }
          final parsedHighest = (rawHighest is int)
              ? rawHighest
              : int.tryParse(rawHighest.toString()) ?? _gamePoints;
          if (kDebugMode) {
            print('🎮 parsedHighest: $parsedHighest (gamePoints anterior: $_gamePoints)');
          }
          updateGamePoints(parsedHighest);
          if (kDebugMode) {
            print('🎮 Game points actualizados: $parsedHighest (highest_score: ${data['highest_score']}, total_score: ${data['total_score']})');
          }
        } else if (data is Map) {
          if (kDebugMode) {
            print('🎮 Error en respuesta: ${data['error'] ?? 'unknown'}');
          }
        }
      } else {
        if (kDebugMode) {
          print('🎮 Error HTTP: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshGamePoints: $e');
      }
    }
  }

  Future<void> refreshAppPoints() async {
    if (_currentUser == null || _currentUser!['id'] == null) return;
    final userId = _currentUser!['id'];
    try {
      final uri = Uri.parse('https://zumuradigital.com/app-oblatos-login/get_user_app_points.php?user_id=$userId&username=$_userName');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true) {
          final payload = (data['data'] ?? data) as Map;
          if (kDebugMode) {
            print('📱 Payload puntos app: $payload');
          }
          final base = payload['puntos'];
          final diarios = payload['puntos_diarios'];
          final snippets = payload['puntos_snippets'];
          final racha = payload['racha_dias'];
          final rachaPoints = payload['racha_points'] ?? 0; // Nuevo campo de puntos de racha
          final fechaInicio = payload['fecha_inicio_racha'];
          final ultimoBonus = payload['ultimo_bonus_racha'];
          final ultimaSesion = payload['ultima_sesion'] ?? payload['ultimaSesion'];
          final totalApp = payload['total_app_points'] ?? payload['puntos_app'] ?? base;

          final parsedBase = (base is int) ? base : int.tryParse(base.toString()) ?? 0;
          final parsedSnippets = (snippets is int) ? snippets : int.tryParse(snippets.toString()) ?? 0;
          final parsedDiarios = (diarios is int) ? diarios : int.tryParse(diarios.toString()) ?? 0;
          final parsedRacha = (racha is int) ? racha : int.tryParse(racha.toString()) ?? 0;
          final parsedTotalApp = (totalApp is int)
              ? totalApp
              : int.tryParse(totalApp.toString()) ?? (parsedBase + parsedSnippets + parsedDiarios);

          _puntos = parsedTotalApp;
          _puntosDiarios = (diarios is int) ? diarios : int.tryParse(diarios.toString()) ?? _puntosDiarios;
          _puntosSnippets = (snippets is int) ? snippets : int.tryParse(snippets.toString()) ?? _puntosSnippets;
          _rachaDias = parsedRacha;
          _rachaPoints = (rachaPoints is int) ? rachaPoints : int.tryParse(rachaPoints.toString()) ?? _rachaPoints;
          _fechaInicioRacha = (fechaInicio != null && fechaInicio.toString().isNotEmpty)
              ? DateTime.tryParse(fechaInicio.toString())
              : _fechaInicioRacha;
          _ultimoBonusRacha = (ultimoBonus != null && ultimoBonus.toString().isNotEmpty)
              ? DateTime.tryParse(ultimoBonus.toString())
              : _ultimoBonusRacha;
          _ultimaSesion = (ultimaSesion != null && ultimaSesion.toString().isNotEmpty)
              ? DateTime.tryParse(ultimaSesion.toString())
              : _ultimaSesion;

          if (_currentUser != null) {
            _currentUser!['puntos'] = _puntos;
            _currentUser!['puntos_diarios'] = _puntosDiarios;
            _currentUser!['puntos_snippets'] = _puntosSnippets;
            _currentUser!['racha_dias'] = _rachaDias;
            _currentUser!['racha_points'] = _rachaPoints;
            _currentUser!['fecha_inicio_racha'] = _fechaInicioRacha?.toIso8601String().split('T')[0];
            _currentUser!['ultimo_bonus_racha'] = _ultimoBonusRacha?.toIso8601String().split('T')[0];
            _currentUser!['ultima_sesion'] = _ultimaSesion?.toIso8601String().split('T')[0];
          }

          notifyListeners();
          if (kDebugMode) {
            print('📱 Puntos app refrescados: base=$_puntos, snippets=$_puntosSnippets, diarios=$_puntosDiarios, racha=$_rachaDias, rachaPoints=$_rachaPoints');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshAppPoints: $e');
      }
    }
  }
  
  /// Actualizar sesión diaria y calcular puntos
  /// NOTA: La lógica principal está en el PHP (update_points.php)
  /// Este método solo actualiza los valores locales después de recibir la respuesta del servidor
  void updateSesionDiaria() {
    // La lógica de puntos y racha se maneja en el backend PHP
    // Este método se mantiene por compatibilidad pero no otorga puntos localmente
    final hoy = DateTime.now();
    final hoyDate = DateTime(hoy.year, hoy.month, hoy.day);
    
    if (_ultimaSesion == null) {
      // Primera sesión
      _ultimaSesion = hoyDate;
      _fechaInicioRacha = hoyDate;
      _rachaDias = 1;
    } else {
      final ultimaSesionDate = DateTime(
        _ultimaSesion!.year, 
        _ultimaSesion!.month, 
        _ultimaSesion!.day
      );
      
      if (hoyDate.isAfter(ultimaSesionDate)) {
        // Nueva sesión del día
        _ultimaSesion = hoyDate;
        
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
  /// NOTA: La lógica principal está en el PHP (update_points.php)
  /// Este método solo actualiza los valores locales después de recibir la respuesta del servidor
  void _checkBonusRacha() {
    // La lógica de bonus se maneja en el backend PHP
    // Este método se mantiene por compatibilidad pero no otorga puntos localmente
    final hoy = DateTime.now();
    final hoyDate = DateTime(hoy.year, hoy.month, hoy.day);
    
    // Bonus por racha semanal: cada 7 días consecutivos = +100 puntos (días 7, 14, 21, 28, etc.)
    if (_rachaDias % 7 == 0 && (_ultimoBonusRacha == null || 
        _daysSinceLastBonus(_ultimoBonusRacha!) >= 7)) {
      _ultimoBonusRacha = hoyDate;
      if (_currentUser != null) {
        _currentUser!['ultimo_bonus_racha'] = _ultimoBonusRacha?.toIso8601String().split('T')[0];
      }
    }
    
    // Bonus por racha mensual (28 días = 4 semanas consecutivas) = +500 puntos de racha
    // Este bonus se otorga ADEMÁS del bonus semanal del día 28
    if (_rachaDias == 28 && (_ultimoBonusRacha == null || 
        _daysSinceLastBonus(_ultimoBonusRacha!) >= 28)) {
      _ultimoBonusRacha = hoyDate;
      if (_currentUser != null) {
        _currentUser!['ultimo_bonus_racha'] = _ultimoBonusRacha?.toIso8601String().split('T')[0];
      }
    }
  }
  
  /// Calcular días desde el último bonus
  int _daysSinceLastBonus(DateTime lastBonus) {
    final hoy = DateTime.now();
    final hoyDate = DateTime(hoy.year, hoy.month, hoy.day);
    final lastBonusDate = DateTime(lastBonus.year, lastBonus.month, lastBonus.day);
    return hoyDate.difference(lastBonusDate).inDays;
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
  
  /// Completar actividad y sumar puntos (legacy)
  void completarActividad(String actividad) {
    final puntosGanados = getPuntosActividad(actividad);
    addPuntos(puntosGanados);
    
    // También actualizar sesión diaria
    updateSesionDiaria();
  }
  
  /// Completar reto diario - marca el reto como completado
  /// Los 10 puntos ya se otorgan al abrir la app (en updateSesionDiaria)
  void completarRetoDiario() {
    // No otorgar puntos adicionales aquí, ya se dan 10 puntos al abrir la app
    // Solo actualizar sesión diaria para mantener la racha
    updateSesionDiaria();
  }
}
