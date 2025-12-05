import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../widgets/daily_challenge_overlay.dart';

class DailyChallengeService {
  static final DailyChallengeService _instance = DailyChallengeService._internal();
  factory DailyChallengeService() => _instance;
  DailyChallengeService._internal();
  
  // Lista de retos disponibles
  final List<DailyChallenge> _availableChallenges = [
    // Retos de monedas (40, 60, 80, 100, 120)
    DailyChallenge(
      type: ChallengeType.coins,
      title: '¡Recolecta Monedas!',
      description: 'Juega y gana al menos 40 monedas',
      targetValue: 40,
      windowImage: 'racha-window-01.png',
    ),
    DailyChallenge(
      type: ChallengeType.coins,
      title: '¡Recolecta Monedas!',
      description: 'Juega y gana al menos 60 monedas',
      targetValue: 60,
      windowImage: 'racha-window-02.png',
    ),
    DailyChallenge(
      type: ChallengeType.coins,
      title: '¡Recolecta Monedas!',
      description: 'Juega y gana al menos 80 monedas',
      targetValue: 80,
      windowImage: 'racha-window-03.png',
    ),
    DailyChallenge(
      type: ChallengeType.coins,
      title: '¡Recolecta Monedas!',
      description: 'Juega y gana al menos 100 monedas',
      targetValue: 100,
      windowImage: 'racha-window-04.png',
    ),
    DailyChallenge(
      type: ChallengeType.coins,
      title: '¡Recolecta Monedas!',
      description: 'Juega y gana al menos 120 monedas',
      targetValue: 120,
      windowImage: 'racha-window-05.png',
    ),
    // Retos de videos
    DailyChallenge(
      type: ChallengeType.video,
      title: '¡Aprende con Videos!',
      description: 'Ve completo el video 1 "Tu alcancía Mágica"',
      videoId: 'video_1',
      windowImage: 'racha-window-01.png',
    ),
    DailyChallenge(
      type: ChallengeType.video,
      title: '¡Aprende con Videos!',
      description: 'Ve completo el video 2 "Presupuesto ¡Fácil!"',
      videoId: 'video_2',
      windowImage: 'racha-window-02.png',
    ),
    DailyChallenge(
      type: ChallengeType.video,
      title: '¡Aprende con Videos!',
      description: 'Ve completo el video 3 "Cambia hábitos ¡Ahorra mucho!"',
      videoId: 'video_3',
      windowImage: 'racha-window-03.png',
    ),
    DailyChallenge(
      type: ChallengeType.video,
      title: '¡Aprende con Videos!',
      description: 'Ve completo el video 4 "¡Alerta Online!"',
      videoId: 'video_4',
      windowImage: 'racha-window-04.png',
    ),
    DailyChallenge(
      type: ChallengeType.video,
      title: '¡Aprende con Videos!',
      description: 'Ve completo el video 5 "Cuida tus recursos"',
      videoId: 'video_5',
      windowImage: 'racha-window-05.png',
    ),
    // Retos de trivia - Se obtendrán del PHP dinámicamente
    // No agregar trivias hardcodeadas aquí
  ];
  
  DailyChallenge? _todayChallenge;
  
  /// Obtener el reto del día (genera uno nuevo si es necesario)
  Future<DailyChallenge?> getTodayChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    // Verificar si ya se mostró el reto hoy
    final lastShownDate = prefs.getString('daily_challenge_last_shown');
    if (lastShownDate == todayKey) {
      // Ya se mostró hoy, recuperar el reto guardado
      final challengeType = prefs.getString('daily_challenge_type');
      final challengeData = prefs.getString('daily_challenge_data');
      
      if (challengeType != null && challengeData != null) {
        _todayChallenge = _parseChallengeFromString(challengeType, challengeData);
        // Asegurar que daily_challenge_accepted existe (para retos antiguos)
        if (!prefs.containsKey('daily_challenge_accepted')) {
          await prefs.setBool('daily_challenge_accepted', false);
        }
        // Asegurar que daily_challenge_trivia_attempted existe (para retos antiguos)
        if (!prefs.containsKey('daily_challenge_trivia_attempted')) {
          await prefs.setBool('daily_challenge_trivia_attempted', false);
        }
        return _todayChallenge;
      }
    }
    
    // Generar nuevo reto para hoy
    final random = Random();
    DailyChallenge? selectedChallenge;
    int attempts = 0;
    const maxAttempts = 10; // Evitar loop infinito
    
    // Filtrar retos disponibles (excluir trivias de la lista inicial, se agregarán dinámicamente)
    final nonTriviaChallenges = _availableChallenges.where((c) => c.type != ChallengeType.trivia).toList();
    
    // Intentar seleccionar un reto
    while (attempts < maxAttempts && _todayChallenge == null) {
      // Decidir si intentar una trivia (10% de probabilidad) o un reto normal
      final tryTrivia = random.nextDouble() < 0.1 && nonTriviaChallenges.isNotEmpty;
      
      if (tryTrivia) {
        // Intentar obtener trivia del PHP
        try {
          final trivia = await _fetchTriviaFromPHP('normal');
          if (trivia != null) {
            // Seleccionar una imagen de ventana aleatoria
            final randomWindowImage = 'racha-window-${(random.nextInt(5) + 1).toString().padLeft(2, '0')}.png';
            
            _todayChallenge = DailyChallenge(
              type: ChallengeType.trivia,
              title: '¡Responde la Trivia!',
              description: trivia['pregunta'],
              triviaId: trivia['id'],
              windowImage: randomWindowImage,
              triviaOptions: (trivia['opciones'] as List).map<TriviaOption>((op) => TriviaOption(
                id: op['id'],
                texto: op['texto'],
                orden: op['orden'],
              )).toList(),
            );
            break; // Salir del loop si se obtuvo la trivia
          }
        } catch (e) {
          print('❌ Error obteniendo trivia del PHP: $e');
        }
      }
      
      // Si no se pudo obtener trivia o no se intentó, seleccionar un reto normal
      if (_todayChallenge == null && nonTriviaChallenges.isNotEmpty) {
        selectedChallenge = nonTriviaChallenges[random.nextInt(nonTriviaChallenges.length)];
        final randomWindowImage = 'racha-window-${(random.nextInt(5) + 1).toString().padLeft(2, '0')}.png';
        
        _todayChallenge = DailyChallenge(
          type: selectedChallenge.type,
          title: selectedChallenge.title,
          description: selectedChallenge.description,
          targetValue: selectedChallenge.targetValue,
          videoId: selectedChallenge.videoId,
          triviaId: selectedChallenge.triviaId,
          windowImage: randomWindowImage,
          options: selectedChallenge.options,
        );
        break; // Salir del loop
      }
      
      attempts++;
    }
    
    // Si después de todos los intentos no se pudo crear un reto, usar el primero disponible
    if (_todayChallenge == null && nonTriviaChallenges.isNotEmpty) {
      selectedChallenge = nonTriviaChallenges[0];
      final randomWindowImage = 'racha-window-01.png';
      _todayChallenge = DailyChallenge(
        type: selectedChallenge.type,
        title: selectedChallenge.title,
        description: selectedChallenge.description,
        targetValue: selectedChallenge.targetValue,
        videoId: selectedChallenge.videoId,
        triviaId: selectedChallenge.triviaId,
        windowImage: randomWindowImage,
        options: selectedChallenge.options,
      );
    }
    
    // Guardar el reto del día (pero NO marcarlo como aceptado todavía)
    await prefs.setString('daily_challenge_last_shown', todayKey);
    await prefs.setString('daily_challenge_type', _todayChallenge!.type.toString());
    await prefs.setString('daily_challenge_data', _serializeChallenge(_todayChallenge!));
    await prefs.setBool('daily_challenge_completed', false);
    await prefs.setBool('daily_challenge_accepted', false); // Inicialmente no aceptado
    await prefs.setBool('daily_challenge_trivia_attempted', false); // Inicialmente no intentado
    
    return _todayChallenge;
  }
  
  /// Verificar si se debe mostrar la ventana de reto hoy
  Future<bool> shouldShowChallengeToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    final lastShownDate = prefs.getString('daily_challenge_last_shown');
    final isAccepted = prefs.getBool('daily_challenge_accepted') ?? false;
    final isTriviaAttempted = prefs.getBool('daily_challenge_trivia_attempted') ?? false;
    
    // Si no se ha mostrado hoy, mostrar
    if (lastShownDate != todayKey) {
      return true;
    }
    
    // Obtener el tipo de reto para verificar si es trivia
    final challengeType = prefs.getString('daily_challenge_type');
    final isTrivia = challengeType != null && challengeType.contains('trivia');
    
    // Si es una trivia y ya fue intentada, no mostrar automáticamente
    if (isTrivia && isTriviaAttempted) {
      return false;
    }
    
    // Si ya se mostró hoy pero no se aceptó, también mostrar (para dar otra oportunidad)
    // Pero solo si no es una trivia intentada
    if (lastShownDate == todayKey && !isAccepted) {
      return true;
    }
    
    // Si ya se mostró hoy y se aceptó, no mostrar de nuevo
    return false;
  }
  
  /// Marcar el reto como completado
  Future<void> completeChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_challenge_completed', true);
  }
  
  /// Verificar si el reto de hoy está completado
  Future<bool> isChallengeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('daily_challenge_completed') ?? false;
  }
  
  /// Verificar si el reto de hoy fue aceptado
  Future<bool> isChallengeAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final lastShownDate = prefs.getString('daily_challenge_last_shown');
    
    // Verificar que sea el reto de hoy
    if (lastShownDate != todayKey) {
      return false;
    }
    
    // Verificar si se aceptó explícitamente
    return prefs.getBool('daily_challenge_accepted') ?? false;
  }
  
  /// Marcar el reto como aceptado
  Future<void> acceptChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    await prefs.setString('daily_challenge_last_shown', todayKey);
    await prefs.setBool('daily_challenge_accepted', true);
  }
  
  /// Verificar si la trivia ya fue intentada (contestada, correcta o incorrecta)
  Future<bool> isTriviaAttempted() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final lastShownDate = prefs.getString('daily_challenge_last_shown');
    
    // Verificar que sea el reto de hoy
    if (lastShownDate != todayKey) {
      return false;
    }
    
    // Verificar si ya se intentó (contestó) la trivia
    return prefs.getBool('daily_challenge_trivia_attempted') ?? false;
  }
  
  /// Marcar la trivia como intentada (se contestó, correcta o incorrecta)
  Future<void> markTriviaAttempted() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    await prefs.setString('daily_challenge_last_shown', todayKey);
    await prefs.setBool('daily_challenge_trivia_attempted', true);
  }
  
  /// Obtener el reto actual
  DailyChallenge? get currentChallenge => _todayChallenge;
  
  /// Serializar challenge para guardar en SharedPreferences
  String _serializeChallenge(DailyChallenge challenge) {
    final parts = <String>[];
    parts.add(challenge.title);
    parts.add(challenge.description);
    parts.add(challenge.windowImage);
    if (challenge.targetValue != null) {
      parts.add('target:${challenge.targetValue}');
    }
    if (challenge.videoId != null) {
      parts.add('video:${challenge.videoId}');
    }
    if (challenge.triviaId != null) {
      parts.add('trivia:${challenge.triviaId}');
      // Serializar opciones de trivia si existen
      if (challenge.triviaOptions != null) {
        final optionsJson = challenge.triviaOptions!.map((op) => 
          '${op.id}:${op.texto}:${op.orden}'
        ).join(';');
        parts.add('triviaOptions:$optionsJson');
      }
    }
    return parts.join('|');
  }
  
  /// Parsear challenge desde string
  DailyChallenge? _parseChallengeFromString(String typeStr, String data) {
    final parts = data.split('|');
    if (parts.length < 3) return null;
    
    final title = parts[0];
    final description = parts[1];
    final windowImage = parts[2];
    
    ChallengeType type;
    int? targetValue;
    String? videoId;
    int? triviaId;
    
    if (typeStr.contains('coins')) {
      type = ChallengeType.coins;
      for (int i = 3; i < parts.length; i++) {
        if (parts[i].startsWith('target:')) {
          targetValue = int.tryParse(parts[i].substring(7));
        }
      }
    } else if (typeStr.contains('video')) {
      type = ChallengeType.video;
      for (int i = 3; i < parts.length; i++) {
        if (parts[i].startsWith('video:')) {
          videoId = parts[i].substring(6);
        }
      }
    } else if (typeStr.contains('trivia')) {
      type = ChallengeType.trivia;
      List<TriviaOption>? triviaOptions;
      for (int i = 3; i < parts.length; i++) {
        if (parts[i].startsWith('trivia:')) {
          triviaId = int.tryParse(parts[i].substring(7));
        } else if (parts[i].startsWith('triviaOptions:')) {
          final optionsStr = parts[i].substring(14);
          final optionsList = optionsStr.split(';');
          triviaOptions = optionsList.map((opt) {
            final optParts = opt.split(':');
            if (optParts.length >= 3) {
              return TriviaOption(
                id: int.tryParse(optParts[0]) ?? 0,
                texto: optParts[1],
                orden: int.tryParse(optParts[2]) ?? 0,
              );
            }
            return null;
          }).whereType<TriviaOption>().toList();
        }
      }
      return DailyChallenge(
        type: type,
        title: title,
        description: description,
        triviaId: triviaId,
        windowImage: windowImage,
        triviaOptions: triviaOptions,
      );
    } else {
      return null;
    }
    
    return DailyChallenge(
      type: type,
      title: title,
      description: description,
      targetValue: targetValue,
      videoId: videoId,
      triviaId: triviaId,
      windowImage: windowImage,
    );
  }
  
  /// Verificar si se completó un reto de monedas
  Future<bool> checkCoinsChallenge(int coinsCollected) async {
    if (_todayChallenge == null || _todayChallenge!.type != ChallengeType.coins) {
      return false;
    }
    
    if (_todayChallenge!.targetValue != null && coinsCollected >= _todayChallenge!.targetValue!) {
      await completeChallenge();
      return true;
    }
    
    return false;
  }
  
  /// Verificar si se completó un reto de video
  Future<bool> checkVideoChallenge(String videoId) async {
    if (_todayChallenge == null || _todayChallenge!.type != ChallengeType.video) {
      return false;
    }
    
    if (_todayChallenge!.videoId == videoId) {
      await completeChallenge();
      return true;
    }
    
    return false;
  }
  
  /// Verificar si se completó un reto de trivia
  Future<bool> checkTriviaChallenge(int triviaId) async {
    if (_todayChallenge == null || _todayChallenge!.type != ChallengeType.trivia) {
      return false;
    }
    
    if (_todayChallenge!.triviaId == triviaId) {
      await completeChallenge();
      return true;
    }
    
    return false;
  }
  
  /// Obtener trivia del PHP
  Future<Map<String, dynamic>?> _fetchTriviaFromPHP(String tipo) async {
    try {
      final url = Uri.parse('https://zumuradigital.com/app-oblatos-login/get_trivia.php?tipo=$tipo');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['trivia'] != null) {
          return data['trivia'];
        }
      }
      return null;
    } catch (e) {
      print('❌ Error en _fetchTriviaFromPHP: $e');
      return null;
    }
  }
}

