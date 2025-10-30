import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';
import 'package:provider/provider.dart';
import '../user_manager.dart';
import '../services/snippet_service.dart';

class LevelConfig {
  final int pointsToNext;
  final double speedBase;
  final int negativeIntervalMs;
  final double coinRatio; // 0..1
  final int maxObjects;
  final double frequencyBaseSeconds;
  final double starChance; // 0..1

  const LevelConfig({
    required this.pointsToNext,
    required this.speedBase,
    required this.negativeIntervalMs,
    required this.coinRatio,
    required this.maxObjects,
    required this.frequencyBaseSeconds,
    required this.starChance,
  });
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Estados del juego
  int _currentScreen = 0; // 0: Bienvenida, 1: Instrucciones, 2: Juego
  int _score = 0;
  int _level = 1;
  int _lives = 3;
  bool _gameOver = false;
  bool _isLevelUpAnimating = false; // Bandera para evitar animaciones duplicadas
  int _coinsCollected = 0; // Contador de monedas recolectadas
  final Map<int, LevelConfig> _levelConfigs = {
    1: LevelConfig(pointsToNext: 500, speedBase: 4, negativeIntervalMs: 8000, coinRatio: 0.85, maxObjects: 3, frequencyBaseSeconds: 2.5, starChance: 0.0),
    2: LevelConfig(pointsToNext: 1000, speedBase: 5, negativeIntervalMs: 5000, coinRatio: 0.65, maxObjects: 3, frequencyBaseSeconds: 1.8, starChance: 0.05),
    3: LevelConfig(pointsToNext: 1500, speedBase: 6, negativeIntervalMs: 3500, coinRatio: 0.55, maxObjects: 4, frequencyBaseSeconds: 1.5, starChance: 0.05),
    4: LevelConfig(pointsToNext: 2000, speedBase: 7, negativeIntervalMs: 3000, coinRatio: 0.45, maxObjects: 5, frequencyBaseSeconds: 1.3, starChance: 0.05),
    5: LevelConfig(pointsToNext: 0,    speedBase: 8, negativeIntervalMs: 2500, coinRatio: 0.35, maxObjects: 6, frequencyBaseSeconds: 1.2, starChance: 0.05),
  };

  LevelConfig get _currentLevelConfig {
    final cfg = _levelConfigs[_level];
    if (cfg != null) return cfg;
    return _levelConfigs[_levelConfigs.keys.last]!;
  }
  
  // Controladores de animación
  late AnimationController _coinAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _gameOverAnimationController;
  late AnimationController _levelUpAnimationController;
  
  // Animaciones
  late Animation<double> _gameOverAnimation;
  late Animation<double> _levelUpAnimation;
  
  // Audio players
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _soundPlayer = AudioPlayer();
  
  // Timer para el juego
  Timer? _gameTimer;
  Timer? _spawnTimer;
  
  // Lista de elementos en pantalla
  List<GameElement> _elements = [];
  
  // Posición del jugador (alcancía)
  double _playerX = 0.5;
  double _playerScale = 0.5; // 0.5x por defecto
  bool _facingRight = true; // orientación visual
  bool _shieldActive = false;
  Timer? _shieldTimer;
  DateTime? _shieldUntil;
  bool _inLevelTransition = false;
  Timer? _levelTransitionTimer;
  DateTime? _lastNegativeSpawn;
  int _level5SecondsLeft = 60;
  Timer? _level5Timer;
  int? _lastCountdownPlayedSecond;
  DateTime? _bonusTextUntil;
  double _parallaxAlignX = 0.0;
  late AnimationController _shakeController;
  double _shakeDx = 0.0;
  DateTime? _damageTintUntil;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _playBackgroundMusic();
    
    // Desactivar snippets durante el juego
    SnippetService().setGameOrCalculatorActive(true);
  }
  
  void _initializeAnimations() {
    _coinAnimationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _gameOverAnimationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _gameOverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gameOverAnimationController, curve: Curves.easeInOut),
    );
    
    _levelUpAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _levelUpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _levelUpAnimationController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      duration: Duration(milliseconds: 280),
      vsync: this,
    )..addListener(() {
        // oscilación decreciente
      final t = _shakeController.value;
      _shakeDx = (1 - t) * 8.0 * (math.sin(2 * math.pi * 6 * t));
        if (mounted) setState(() {});
      });
  }
  
  void _playBackgroundMusic() async {
    try {
      print('Intentando reproducir música de fondo...');
      await _musicPlayer.play(AssetSource('images/game/sounds/music.mp3'));
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      print('Música de fondo iniciada correctamente');
    } catch (e) {
      print('Error playing background music: $e');
    }
  }
  
  void _playSound(String sound) async {
    try {
      print('Intentando reproducir sonido: $sound');
      await _soundPlayer.play(AssetSource('images/game/sounds/$sound'));
      print('Sonido $sound reproducido correctamente');
    } catch (e) {
      print('Error playing sound $sound: $e');
    }
  }
  
  void _startGame() {
    setState(() {
      _currentScreen = 2;
      _score = 0;
      _level = 1;
      _lives = 3;
      _gameOver = false;
      _elements.clear();
      _coinsCollected = 0; // Resetear contador de monedas
      _shieldActive = false;
      _inLevelTransition = false;
      _level5SecondsLeft = 60;
      _level5Timer?.cancel();
      _bonusTextUntil = null;
    });
    
    _startGameLoop();
  }
  
  void _startGameLoop() {
    // Timer principal del juego
    _gameTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
    
    // Timer para spawn de elementos (usa configuración del nivel)
    final int spawnIntervalMs = (_currentLevelConfig.frequencyBaseSeconds * 1000).round();
    _spawnTimer = Timer.periodic(Duration(milliseconds: spawnIntervalMs), (timer) {
      _spawnElement();
    });
  }
  
  void _updateGame() {
    if (_inLevelTransition) return; // Pausa completa durante transición
    setState(() {
      // Mover elementos: velocidad y rotación por elemento
      _elements.removeWhere((element) {
        // Actualizar rotación y caída variable
        element.rotation += element.rotationSpeed * (16 / 1000);
        element.y += element.vy;
        return element.y > 1.2; // Fuera de pantalla
      });
      
      // Verificar colisiones
      _checkCollisions();
    });
  }
  
  void _spawnElement() {
    final random = math.Random();

    // Respetar máximo de objetos simultáneos
    if (_elements.length >= _currentLevelConfig.maxObjects) return;

    // Posible estrella (desde nivel 2)
    if (_level >= 2 && math.Random().nextDouble() < _currentLevelConfig.starChance) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double dxNorm = (120.0 / screenWidth).clamp(0.0, 0.5);
      final double offsetNorm = (random.nextDouble() * 2 - 1) * dxNorm;
      _elements.add(
        GameElement(
          x: (0.5 + offsetNorm).clamp(0.0, 1.0),
          y: -0.1,
          type: 'star',
          value: 0,
          vy: _computeElementVy(),
          rotation: 0,
          rotationSpeed: 0,
        ),
      );
      return;
    }

    // Proporción de monedas vs negativos según nivel con intervalo mínimo
    bool spawnCoin = random.nextDouble() < _currentLevelConfig.coinRatio;
    String elementType = spawnCoin ? 'coin' : 'bad_card';
    if (elementType == 'bad_card') {
      final now = DateTime.now();
      if (_lastNegativeSpawn != null && now.difference(_lastNegativeSpawn!).inMilliseconds < _currentLevelConfig.negativeIntervalMs) {
        elementType = 'coin';
      } else {
        _lastNegativeSpawn = now;
      }
    }

    // Bonus (solo nivel 5): 50 puntos, tamaño 20% ancho
    if (_level >= 5 && elementType == 'coin' && random.nextDouble() < 0.15) {
      elementType = 'bonus';
    }

    void spawnOne(String t) {
      _elements.add(
        GameElement(
          x: random.nextDouble(),
          y: -0.1,
          type: t,
          value: t == 'coin' ? (random.nextInt(3) + 1) : (t == 'bonus' ? 50 : -1),
          vy: _computeElementVy(),
          rotation: 0,
          rotationSpeed: t == 'coin' || t == 'bonus' ? _randomRotationSpeed() : 0,
        ),
      );
    }

    // Spawns simultáneos: a veces dos monedas con velocidades distintas
    spawnOne(elementType);
    if (elementType == 'coin' && random.nextDouble() < 0.3 && _elements.length < _currentLevelConfig.maxObjects) {
      spawnOne('coin');
    }

    // Ocasionalmente añade un negativo si no se agregó y hay espacio y respeta intervalo
    if (elementType != 'bad_card' && random.nextDouble() < 0.25 && _elements.length < _currentLevelConfig.maxObjects) {
      final now = DateTime.now();
      if (_lastNegativeSpawn == null || now.difference(_lastNegativeSpawn!).inMilliseconds >= _currentLevelConfig.negativeIntervalMs) {
        _lastNegativeSpawn = now;
        spawnOne('bad_card');
      }
    }
  }
  
  void _checkCollisions() {
    bool coinCollected = false; // Bandera para saber si se recolectó una moneda
    bool levelUp = false; // Bandera para saber si subió de nivel
    
    // Dimensiones y hitbox del jugador
    final size = MediaQuery.of(context).size;
    final double canvasWidth = size.width;
    final double canvasHeight = size.height;
    final double playerWidthPx = 200 * _playerScale; // base 200x380 escalado
    final double playerHeightPx = 380 * _playerScale;
    final double playerCenterX = canvasWidth * _playerX;
    final double playerBottomOffset = 30; // ~25-30px desde borde inferior
    final double playerTop = canvasHeight - playerBottomOffset - playerHeightPx;
    final Rect playerRect = Rect.fromLTWH(
      playerCenterX - playerWidthPx / 2,
      playerTop,
      playerWidthPx,
      playerHeightPx,
    );

    for (int i = _elements.length - 1; i >= 0; i--) {
      final element = _elements[i];
      // Dimensiones del elemento en px (monedas/estrellas 13% del ancho, negativos también por ahora)
      final double elemSizePx = canvasWidth * 0.13; // 13% del ancho
      final double elemHalf = elemSizePx / 2;
      final double elemCenterX = canvasWidth * element.x;
      final double elemCenterY = canvasHeight * element.y;
      final Rect elemRect = Rect.fromLTWH(
        elemCenterX - elemHalf,
        elemCenterY - elemHalf,
        elemSizePx,
        elemSizePx,
      );

      if (playerRect.overlaps(elemRect)) {
        if (element.type == 'coin') {
          // Puntajes diferentes por tipo de moneda (1/5/10)
          int points = 0;
          switch (element.value) {
            case 1: // Cobre
              points = 1;
              break;
            case 2: // Plata
              points = 5;
              break;
            case 3: // Oro
              points = 10;
              break;
          }
          _score += points;
          _coinsCollected++; // Incrementar contador de monedas
          coinCollected = true; // Marcar que se recolectó una moneda
          if (_coinsCollected % 10 == 0 && !_shieldActive) {
            _activateShield();
          }
        } else if (element.type == 'star') {
          if (_lives < 6) {
            _lives++;
          }
          _playSound('star.mp3');
        } else if (element.type == 'bonus') {
          _score += 50;
          _playSound('star.mp3');
          _bonusTextUntil = DateTime.now().add(Duration(milliseconds: 1500));
        } else {
          if (!_shieldActive) {
            _lives--;
            _playSound('error.mp3');
            HapticFeedback.mediumImpact();
            _shakeController.forward(from: 0);
            _damageTintUntil = DateTime.now().add(Duration(milliseconds: 320));
            if (_lives <= 0) {
              _gameOver = true;
              _playSound('gameover.mp3');
              _gameOverAnimationController.forward();
              _stopGame();
              _saveGameScore(); // Guardar puntaje cuando el juego termina
            }
          }
        }
        
        _elements.removeAt(i);
        
        // Verificar si sube de nivel con puntos específicos por nivel
        int requiredPoints = _getRequiredPointsForLevel(_level);
        if (_score >= requiredPoints && !_inLevelTransition) {
          levelUp = true; // Marcar que sube de nivel
          _beginLevelTransition();
        }
      }
    }
    
    // Reproducir sonido de moneda fuera del bucle para evitar conflictos
    if (coinCollected) {
      _playSound('coin.mp3');
    }
    
    // Mostrar animación de nivel fuera del bucle para evitar duplicados
    if (levelUp) {
      _showLevelUpAnimation();
    }
  }

  void _activateShield() {
    _shieldActive = true;
    _playerScale = 0.6; // agrandamiento 20%
    _playSound('star.mp3');
    _shieldTimer?.cancel();
    _shieldUntil = DateTime.now().add(Duration(seconds: 10));
    _shieldTimer = Timer(Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() {
        _shieldActive = false;
        _playerScale = 0.5;
        _shieldUntil = null;
      });
    });
    setState(() {});
  }
  
  void _showLevelUpAnimation() {
    if (_isLevelUpAnimating) return; // Solo una verificación simple
    
    _isLevelUpAnimating = true; // Activar inmediatamente
    
    // Aparecer inmediatamente sin fade in
    _levelUpAnimationController.value = 1.0;
    
    // Después de 1.5 segundos, desaparecer
    Future.delayed(Duration(milliseconds: 1500), () {
      _levelUpAnimationController.reverse().then((_) {
        _isLevelUpAnimating = false; // Resetear la bandera
      });
    });
  }

  void _beginLevelTransition() {
    _inLevelTransition = true;
    _spawnTimer?.cancel();
    setState(() {});
    _levelTransitionTimer?.cancel();
    _levelTransitionTimer = Timer(Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _level++;
        _inLevelTransition = false;
        _adjustDifficulty();
        if (_level >= 5) {
          _startLevel5Timer();
        }
      });
    });
  }

  void _startLevel5Timer() {
    _level5Timer?.cancel();
    _level5SecondsLeft = 60;
    _lastCountdownPlayedSecond = null;
    _level5Timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (!mounted || _gameOver) return;
      setState(() {
        _level5SecondsLeft--;
        if (_level5SecondsLeft <= 10 && _level5SecondsLeft >= 1) {
          if (_lastCountdownPlayedSecond != _level5SecondsLeft) {
            _lastCountdownPlayedSecond = _level5SecondsLeft;
            _playSound('countdown.mp3');
          }
        }
        if (_level5SecondsLeft <= 0) {
          _level5Timer?.cancel();
          _gameOver = true;
          _playSound('gameover.mp3');
          _gameOverAnimationController.forward();
          _stopGame();
          _saveGameScore();
        }
      });
    });
  }
  
  int _getRequiredPointsForLevel(int level) {
    switch (level) {
      case 1: return 500;
      case 2: return 1000;
      case 3: return 1500;
      case 4: return 2000;
      default: return 1 << 30; // Nivel 5+: sin siguiente por ahora (modo final se implementará luego)
    }
  }
  
  void _adjustDifficulty() {
    // Actualizar frecuencia de spawn basada en la configuración del nivel
    _spawnTimer?.cancel();
    final int spawnIntervalMs = (_currentLevelConfig.frequencyBaseSeconds * 1000).round();
    _spawnTimer = Timer.periodic(Duration(milliseconds: spawnIntervalMs), (_) {
      _spawnElement();
    });
  }

  double _computeElementVy() {
    // Base depende del nivel; convertir a delta por frame (~60 fps)
    final base = 0.006 + (_level * 0.003);
    final variance = 0.6 + math.Random().nextDouble() * 1.0; // 0.6..1.6
    return base * variance;
  }

  double _randomRotationSpeed() {
    // rad/s entre -6 y 6 para giro visible
    return (math.Random().nextDouble() * 12 - 6);
  }
  
  void _stopGame() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _saveScore();
  }
  
  void _saveScore() async {
    try {
      final userManager = Provider.of<UserManager>(context, listen: false);
      final userId = userManager.currentUser?['id'];
      
      if (userId != null) {
        final response = await http.post(
          Uri.parse('https://zumuradigital.com/oblatos/save_game_score.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'score': _score,
            'level': _level,
            'date': DateTime.now().toIso8601String(),
          }),
        );
        
        if (response.statusCode == 200) {
          print('Score saved successfully');
        }
      }
    } catch (e) {
      print('Error saving score: $e');
    }
  }
  
  void _restartGame() {
    setState(() {
      _currentScreen = 0;
      _gameOver = false;
      _score = 0;
      _level = 1;
      _lives = 3;
      _elements.clear();
    });
    
    _gameOverAnimationController.reset();
  }
  
  @override
  void dispose() {
    _coinAnimationController.dispose();
    _cardAnimationController.dispose();
    _gameOverAnimationController.dispose();
    _musicPlayer.dispose();
    _soundPlayer.dispose();
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _shieldTimer?.cancel();
    
    // Reactivar snippets al salir del juego
    SnippetService().setGameOrCalculatorActive(false);
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Solo permitir salir con swipe en pantallas de bienvenida e instrucciones
        // Durante el juego (pantalla 2), bloquear el swipe
        if (_currentScreen == 2) {
          return false; // Bloquear swipe durante el juego
        }
        return true; // Permitir swipe en otras pantallas
      },
      child: Scaffold(
        backgroundColor: Color(0xFF0A0E21),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: _currentScreen == 2
              ? null
              : BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_currentScreen == 0
                        ? 'assets/images/game/portada2.jpg'
                        : 'assets/images/game/fondo2.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
          child: Stack(
            children: [
              // Contenido principal
              SafeArea(
                child: Column(
                  children: [
                    // Header de navegación
                    _buildHeader(),
                    
                    // Contenido según la pantalla actual
                    Expanded(
                      child: _buildCurrentScreen(),
                    ),
                  ],
                ),
              ),
              
              // Overlay de game over
              if (_gameOver) _buildGameOverOverlay(),

              // Overlay de transición de nivel (2s)
              if (_inLevelTransition)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Nivel ${_level + 1}',
                        style: TextStyle(
                          fontFamily: 'Gotham Rounded',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

              // Texto flotante simple para bonus
              if (_bonusTextUntil != null && DateTime.now().isBefore(_bonusTextUntil!))
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+50!',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellowAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // Botón de regreso
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          Spacer(),
          
          // Título (oculto en la pantalla de bienvenida)
          if (_currentScreen != 0)
            Column(
              children: [
                Text(
                  'BIENVENIDOS',
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'JUEGO DE AHORRO',
                  style: TextStyle(
                    fontFamily: 'Gryzensa',
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.white70,
                    height: 0.8,
                  ),
                ),
              ],
            ),
          
          Spacer(),
          
          // Espacio para balancear
          Container(width: 50),
        ],
      ),
    );
  }
  
  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 0:
        return _buildWelcomeScreen();
      case 1:
        return _buildInstructionsScreen();
      case 2:
        return _buildGameScreen();
      default:
        return _buildWelcomeScreen();
    }
  }
  
  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón jugar (subido 150 px)
          Transform.translate(
            offset: Offset(0, -100),
            child: GestureDetector(
            onTap: () {
              setState(() {
                _currentScreen = 1;
              });
            },
            child: Container(
              width: 200,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'JUGAR',
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstructionsScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Título
            Text(
              'Instrucciones',
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: 20),
            
            // Instrucción 1 - Monedas
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 10),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/game/moneda_oro.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFFFD700),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.monetization_on, color: Colors.white),
                      );
                    },
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atrapa las monedas',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Cobre: 1 • Plata: 5 • Oro: 10',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Instrucción 2 - Tarjetas malas
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 10),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Color(0xFFE91E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Color(0xFFE91E63).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/game/tarjeta_mala01.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFE91E63),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.credit_card, color: Colors.white),
                      );
                    },
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evita las tarjetas malas',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Restan 1 vida si las tocas',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Instrucción 3 - Vidas
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 10),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Color(0xFF4CAF50).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/game/vida.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.favorite, color: Colors.white),
                      );
                    },
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cuida tus vidas',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Tienes 3 vidas, cada 500 pts subes de nivel',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // Botón comenzar
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentScreen = 2; // Ir al juego
                });
                _startGame();
              },
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'COMENZAR JUEGO',
                    style: TextStyle(
                      fontFamily: 'Gotham Rounded',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  
  Widget _buildGameScreen() {
    return Listener(
      onPointerMove: (details) {
        // Solo permitir movimiento horizontal, bloquear completamente el vertical
        double deltaX = details.delta.dx;
        double deltaY = details.delta.dy;
        
        // Solo mover si el movimiento horizontal es significativo y mayor que el vertical
        if (deltaX.abs() > 3 && deltaX.abs() > deltaY.abs() * 2) {
          setState(() {
            _playerX = (details.position.dx / MediaQuery.of(context).size.width).clamp(0.0, 1.0);
            if (deltaX > 0) _facingRight = true;
            if (deltaX < 0) _facingRight = false;
            // Parallax: factor 0.3 mapea a alignment -0.3..0.3
            _parallaxAlignX = ((_playerX - 0.5) * 2.0 * 0.3).clamp(-0.6, 0.6);
          });
        }
      },
      child: AbsorbPointer(
        absorbing: true, // Bloquear completamente otros gestos
        child: Stack(
        children: [
          // Fondo con paralaje
          Positioned.fill(
            child: Image.asset(
              _currentScreen == 0
                ? 'assets/images/game/portada2.jpg'
                : 'assets/images/game/fondo2.jpg',
              fit: BoxFit.cover,
              alignment: _currentScreen == 2 ? Alignment(_parallaxAlignX, 0) : Alignment.center,
            ),
          ),
          // Elementos del juego
          ..._elements.map((element) => _buildGameElement(element)),
          
          // Jugador (alcancía) - sin GestureDetector individual
          Positioned(
            left: MediaQuery.of(context).size.width * _playerX - (200 * _playerScale) / 2,
            bottom: 30,
            child: Transform.translate(
              offset: Offset(_shakeDx, 0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(_facingRight ? 1.0 : -1.0, 1.0, 1.0),
                child: ColorFiltered(
                  colorFilter: (_damageTintUntil != null && DateTime.now().isBefore(_damageTintUntil!))
                      ? ColorFilter.mode(Colors.red.withOpacity(0.28), BlendMode.modulate)
                      : const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                  child: Image.asset(
                    'assets/images/game/alcancia.png',
                    width: 200 * _playerScale,
                    height: 380 * _playerScale,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200 * _playerScale,
                        height: 380 * _playerScale,
                        decoration: BoxDecoration(
                          color: Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 80),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Efectos del escudo: halo + texto
          if (_shieldActive)
            Positioned(
              left: MediaQuery.of(context).size.width * _playerX - (220 * _playerScale) / 2,
              bottom: 20,
              child: Column(
                children: [
                  Container(
                    width: 220 * _playerScale,
                    height: 400 * _playerScale,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.yellowAccent.withOpacity(0.35),
                          Colors.transparent,
                        ],
                        radius: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'PROTEGIDO',
                    style: TextStyle(
                      fontFamily: 'Gotham Rounded',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellowAccent,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Contador numérico del escudo arriba del personaje
          if (_shieldActive && _shieldUntil != null)
            Positioned(
              left: MediaQuery.of(context).size.width * _playerX - 18,
              bottom: 30 + (380 * _playerScale) + 8,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.yellowAccent, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0,2))],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${(_shieldUntil!.difference(DateTime.now()).inSeconds).clamp(0, 10)}',
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        
        // UI del juego - Layout vertical para evitar overflow
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Column(
            children: [
              // Primera fila: Puntuación y Nivel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Puntuación
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'Puntos: $_score',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  // Nivel
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'Nivel: $_level',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 10),
              
              // Cuenta regresiva nivel 5
              if (_level >= 5 && !_gameOver)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Tiempo: ${_level5SecondsLeft}s',
                    style: TextStyle(
                      fontFamily: 'Gotham Rounded',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _level5SecondsLeft <= 10 ? Colors.redAccent : Colors.white,
                    ),
                  ),
                ),

              // Segunda fila: Solo Vidas (mostrar solo las activas)
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Solo alineado a la derecha
                children: [
                  // Progreso oculto
                  // Container(
                  //   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  //   decoration: BoxDecoration(
                  //     color: Colors.black.withOpacity(0.7),
                  //     borderRadius: BorderRadius.circular(15),
                  //   ),
                  //   child: Text(
                  //     '${_getRequiredPointsForLevel(_level) - _score} pts',
                  //     style: TextStyle(
                  //       fontFamily: 'Gotham Rounded',
                  //       fontSize: 12,
                  //       color: Colors.white70,
                  //     ),
                  //   ),
                  // ),
                  
                  // Vidas
                  Row(
                    children: List.generate(_lives.clamp(0, 6), (index) {
                      return Container(
                        margin: EdgeInsets.only(left: 3),
                        child: Image.asset(
                          'assets/images/game/vida.png',
                          width: 25,
                          height: 25,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: Color(0xFFE91E63),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.favorite, color: Colors.white, size: 15),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Animación de cambio de nivel
        if (_levelUpAnimationController.isAnimating)
          FadeTransition(
            opacity: _levelUpAnimation,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '¡NIVEL $_level!',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '¡Sigue así!',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
        ),
      ),
    );
  }
  
  Widget _buildGameElement(GameElement element) {
    String imagePath;
    Color fallbackColor;
    IconData fallbackIcon;
    
    if (element.type == 'coin') {
      switch (element.value) {
        case 1:
          imagePath = 'assets/images/game/moneda_cobre.png';
          fallbackColor = Color(0xFFCD7F32); // Cobre
          fallbackIcon = Icons.monetization_on;
          break;
        case 2:
          imagePath = 'assets/images/game/moneda_plata.png';
          fallbackColor = Color(0xFFC0C0C0); // Plata
          fallbackIcon = Icons.monetization_on;
          break;
        case 3:
          imagePath = 'assets/images/game/moneda_oro.png';
          fallbackColor = Color(0xFFFFD700); // Oro
          fallbackIcon = Icons.monetization_on;
          break;
        default:
          imagePath = 'assets/images/game/moneda_cobre.png';
          fallbackColor = Color(0xFFCD7F32);
          fallbackIcon = Icons.monetization_on;
      }
    } else if (element.type == 'star') {
      imagePath = 'assets/images/game/vida.png';
      fallbackColor = Color(0xFFFFD700);
      fallbackIcon = Icons.star;
    } else {
      imagePath = 'assets/images/game/tarjeta_mala0${math.Random().nextInt(3) + 1}.png';
      fallbackColor = Color(0xFFE91E63); // Rojo para tarjetas malas
      fallbackIcon = Icons.credit_card;
    }
    
    final size = MediaQuery.of(context).size;
    final double elemSizePx = size.width * 0.13; // 13% del ancho
    final double bonusSizePx = size.width * 0.20;
    final bool isBonus = element.type == 'bonus';
    final double renderSize = isBonus ? bonusSizePx : elemSizePx;
    return Positioned(
      left: size.width * element.x - (renderSize / 2),
      top: size.height * element.y - (renderSize / 2),
      child: Transform.rotate(
        angle: element.rotation,
        child: Image.asset(
          imagePath,
          width: renderSize,
          height: renderSize,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: renderSize,
              height: renderSize,
              decoration: BoxDecoration(
                color: fallbackColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(fallbackIcon, color: Colors.white, size: renderSize * 0.5),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildGameOverOverlay() {
    return FadeTransition(
      opacity: _gameOverAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            width: 300,
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¡Juego Terminado!',
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                
                SizedBox(height: 20),
                
                Text(
                  'Tu ahorro fue de $_score puntos',
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                
                SizedBox(height: 10),
                
                Text(
                  'Terminaste en el ${_level}° nivel',
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                
                SizedBox(height: 10),
                
                Text(
                  '¡Sigue así! Tu ahorro está cada vez más cerca 🌟',
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 30),
                
                // Botón reintentar
                GestureDetector(
                  onTap: _restartGame,
                  child: Container(
                    width: 200,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'REINTENTAR',
                        style: TextStyle(
                          fontFamily: 'Gotham Rounded',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _saveGameScore() async {
    try {
      // Obtener información del usuario
      final userManager = Provider.of<UserManager>(context, listen: false);
      final userId = userManager.currentUser?['id'] ?? 1; // Usar ID por defecto si no hay usuario
      final username = userManager.userName;
      
      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/save_game_score.php'), // Tu URL actualizada
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'username': username,
          'score': _score,
          'level_reached': _level,
          'coins_collected': _coinsCollected,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          print('Puntaje guardado correctamente: ${data['score_id']}');
        } else {
          print('Error al guardar puntaje: ${data['error']}');
        }
      } else {
        print('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al guardar puntaje: $e');
    }
  }
}

class GameElement {
  double x;
  double y;
  String type; // 'coin' or 'bad_card'
  int value; // 1-3 for coins, -1 for bad cards
  double vy; // velocidad vertical normalizada por frame
  double rotation; // radianes
  double rotationSpeed; // radianes/seg
  
  GameElement({
    required this.x,
    required this.y,
    required this.type,
    required this.value,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
  });
}
