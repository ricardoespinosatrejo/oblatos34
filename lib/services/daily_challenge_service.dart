import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/daily_challenge_overlay.dart';

class DailyChallengeService {
  static final DailyChallengeService _instance = DailyChallengeService._internal();
  factory DailyChallengeService() => _instance;
  DailyChallengeService._internal();

  /// Obtener el reto diario de hoy
  Future<DailyChallenge?> getTodayChallenge() async {
    try {
      // Por ahora, retornamos un reto de ejemplo
      // En el futuro, esto debería obtener el reto desde el servidor
      final today = DateTime.now();
      final dayOfWeek = today.weekday;
      
      // Rotar entre diferentes tipos de retos según el día de la semana
      switch (dayOfWeek % 3) {
        case 0:
          return DailyChallenge(
            type: ChallengeType.coins,
            title: 'Gana Monedas',
            description: 'Juega y gana 50 monedas',
            targetValue: 50,
            windowImage: 'assets/images/rachacoop/racha-window/racha-window-01.png',
          );
        case 1:
          return DailyChallenge(
            type: ChallengeType.video,
            title: 'Ver Video',
            description: 'Ve el video completo del día',
            videoId: 'video_1',
            windowImage: 'assets/images/rachacoop/racha-window/racha-window-02.png',
          );
        case 2:
          return DailyChallenge(
            type: ChallengeType.trivia,
            title: 'Responde la Trivia',
            description: 'Responde correctamente la trivia del día',
            triviaId: 1,
            windowImage: 'assets/images/rachacoop/racha-window/racha-window-03.png',
          );
        default:
          return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error obteniendo reto diario: $e');
      }
      return null;
    }
  }

  /// Verificar si el reto de hoy fue aceptado
  Future<bool> isChallengeAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final lastShown = prefs.getString('daily_challenge_last_shown');
      final isAccepted = prefs.getBool('daily_challenge_accepted') ?? false;
      
      return lastShown == todayKey && isAccepted;
    } catch (e) {
      if (kDebugMode) {
        print('Error verificando reto aceptado: $e');
      }
      return false;
    }
  }

  /// Verificar si el reto de hoy fue completado
  Future<bool> isChallengeCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final isCompleted = prefs.getBool('daily_challenge_completed_$todayKey') ?? false;
      
      return isCompleted;
    } catch (e) {
      if (kDebugMode) {
        print('Error verificando reto completado: $e');
      }
      return false;
    }
  }

  /// Verificar si la trivia de hoy fue intentada
  Future<bool> isTriviaAttempted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final isAttempted = prefs.getBool('daily_trivia_attempted_$todayKey') ?? false;
      
      return isAttempted;
    } catch (e) {
      if (kDebugMode) {
        print('Error verificando trivia intentada: $e');
      }
      return false;
    }
  }

  /// Aceptar el reto de hoy
  Future<void> acceptChallenge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      await prefs.setString('daily_challenge_last_shown', todayKey);
      await prefs.setBool('daily_challenge_accepted', true);
    } catch (e) {
      if (kDebugMode) {
        print('Error aceptando reto: $e');
      }
    }
  }

  /// Completar el reto de hoy
  Future<void> completeChallenge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      await prefs.setBool('daily_challenge_completed_$todayKey', true);
    } catch (e) {
      if (kDebugMode) {
        print('Error completando reto: $e');
      }
    }
  }

  /// Marcar trivia como intentada
  Future<void> markTriviaAttempted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      await prefs.setBool('daily_trivia_attempted_$todayKey', true);
    } catch (e) {
      if (kDebugMode) {
        print('Error marcando trivia como intentada: $e');
      }
    }
  }
}
