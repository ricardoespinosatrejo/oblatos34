import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:provider/provider.dart';
import '../user_manager.dart';

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
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _playBackgroundMusic();
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
    });
    
    _startGameLoop();
  }
  
  void _startGameLoop() {
    // Timer principal del juego
    _gameTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
    
    // Timer para spawn de elementos
    _spawnTimer = Timer.periodic(Duration(milliseconds: 1500), (timer) {
      _spawnElement();
    });
  }
  
  void _updateGame() {
    setState(() {
      // Mover elementos hacia abajo con velocidad progresiva
      double fallSpeed = 0.01 + (_level * 0.005); // Velocidad aumenta con el nivel
      _elements.removeWhere((element) {
        element.y += fallSpeed;
        return element.y > 1.2; // Fuera de pantalla
      });
      
      // Verificar colisiones
      _checkCollisions();
    });
  }
  
  void _spawnElement() {
    final random = Random();
    final elementType = random.nextBool() ? 'coin' : 'bad_card';
    
    _elements.add(GameElement(
      x: random.nextDouble(),
      y: -0.1,
      type: elementType,
      value: elementType == 'coin' ? random.nextInt(3) + 1 : -1,
    ));
  }
  
  void _checkCollisions() {
    bool coinCollected = false; // Bandera para saber si se recolectó una moneda
    bool levelUp = false; // Bandera para saber si subió de nivel
    
    for (int i = _elements.length - 1; i >= 0; i--) {
      final element = _elements[i];
      
      // Calcular la distancia entre el centro de la alcancía y el elemento
      double alcanciaCenterX = _playerX;
      double alcanciaCenterY = 0.85; // Posición Y aproximada de la alcancía (bottom: 30 con height: 200)
      
      double distanceX = (element.x - alcanciaCenterX).abs();
      double distanceY = (element.y - alcanciaCenterY).abs();
      
      // Detección más precisa: solo elementos que realmente toquen la alcancía
      double alcanciaRadius = 0.08; // Radio más pequeño para detección precisa
      
      // Verificar colisión solo si está realmente tocando la alcancía
      if (distanceX < alcanciaRadius && distanceY < alcanciaRadius && element.y > 0.8 && element.y < 1.0) {
        if (element.type == 'coin') {
          // Puntajes diferentes por tipo de moneda
          int points = 0;
          switch (element.value) {
            case 1: // Cobre
              points = 10;
              break;
            case 2: // Plata
              points = 25;
              break;
            case 3: // Oro
              points = 50;
              break;
          }
          _score += points;
          _coinsCollected++; // Incrementar contador de monedas
          coinCollected = true; // Marcar que se recolectó una moneda
        } else {
          _lives--;
          _playSound('error.mp3');
          
          if (_lives <= 0) {
            _gameOver = true;
            _playSound('gameover.mp3');
            _gameOverAnimationController.forward();
            _stopGame();
            _saveGameScore(); // Guardar puntaje cuando el juego termina
          }
        }
        
        _elements.removeAt(i);
        
        // Verificar si sube de nivel con puntos específicos por nivel
        int requiredPoints = _getRequiredPointsForLevel(_level);
        if (_score >= requiredPoints) {
          _level++;
          _playSound('bonus.mp3');
          levelUp = true; // Marcar que subió de nivel
          _adjustDifficulty(); // Ajustar dificultad al subir de nivel
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
  
  int _getRequiredPointsForLevel(int level) {
    switch (level) {
      case 1: return 200;
      case 2: return 400;
      case 3: return 700;
      case 4: return 900;
      case 5: return 1200;
      default: return 1200; // Después del nivel 5, mantener en 1200
    }
  }
  
  void _adjustDifficulty() {
    // Aumentar velocidad de caída y frecuencia de aparición según el nivel
    if (_level >= 2) {
      // Reducir el intervalo de spawn para más monedas
      _spawnTimer?.cancel();
      int spawnInterval = (2000 - (_level * 200)).clamp(500, 2000); // Más rápido cada nivel
      _spawnTimer = Timer.periodic(Duration(milliseconds: spawnInterval), (_) {
        _spawnElement();
      });
    }
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
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/game/fondo2.jpg'),
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
          ],
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
          
          // Título
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
          // Imagen de portada
          Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage('assets/images/game/portada.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          SizedBox(height: 40),
          
          // Título principal
          Text(
            'Nivel: $_level',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 10),
          
          // Ahorro actual
          Text(
            'Ahorro: $_score',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 10),
          
          // Puntos para siguiente nivel
          Text(
            '${_getRequiredPointsForLevel(_level) - _score} puntos',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 18,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 30),
          
          // Descripción
          Text(
            '¡Bienvenido al reto del ahorro!\nAtrapa monedas, evita los malos hábitos\ny haz crecer tu alcancía',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 40),
          
          // Botón jugar
          GestureDetector(
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
                          'Cobre: 10 pts • Plata: 20 pts • Oro: 30 pts',
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
          });
        }
      },
      child: AbsorbPointer(
        absorbing: true, // Bloquear completamente otros gestos
        child: Stack(
        children: [
          // Elementos del juego
          ..._elements.map((element) => _buildGameElement(element)),
          
          // Jugador (alcancía) - sin GestureDetector individual
          Positioned(
            left: MediaQuery.of(context).size.width * _playerX - 100,
            bottom: 30,
            child: Image.asset(
              'assets/images/game/alcancia.png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 100),
                );
              },
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
              
              // Segunda fila: Solo Vidas (Progreso oculto)
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
                    children: List.generate(3, (index) {
                      return Container(
                        margin: EdgeInsets.only(left: 3),
                        child: Image.asset(
                          'assets/images/game/vida.png',
                          width: index < _lives ? 25 : 18,
                          height: index < _lives ? 25 : 18,
                          color: index < _lives ? null : Colors.grey,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: index < _lives ? 25 : 18,
                              height: index < _lives ? 25 : 18,
                              decoration: BoxDecoration(
                                color: index < _lives ? Color(0xFFE91E63) : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.favorite, color: Colors.white, size: index < _lives ? 15 : 12),
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
    } else {
      imagePath = 'assets/images/game/tarjeta_mala0${Random().nextInt(3) + 1}.png';
      fallbackColor = Color(0xFFE91E63); // Rojo para tarjetas malas
      fallbackIcon = Icons.credit_card;
    }
    
    return Positioned(
      left: MediaQuery.of(context).size.width * element.x - 30,
      top: MediaQuery.of(context).size.height * element.y - 30,
      child: Image.asset(
        imagePath,
        width: 60,
        height: 60,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: fallbackColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(fallbackIcon, color: Colors.white, size: 30),
          );
        },
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
  
  GameElement({
    required this.x,
    required this.y,
    required this.type,
    required this.value,
  });
}
