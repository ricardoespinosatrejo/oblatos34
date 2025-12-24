import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_manager.dart';
import 'services/daily_challenge_service.dart';
import 'widgets/daily_challenge_overlay.dart';
import 'widgets/header_navigation.dart';
import 'utils/challenge_helper.dart';

class RachacoopScreen extends StatefulWidget {
  @override
  _RachacoopScreenState createState() => _RachacoopScreenState();
}

class _RachacoopScreenState extends State<RachacoopScreen> {
  final DailyChallengeService _challengeService = DailyChallengeService();
  DailyChallenge? _todayChallenge;
  bool _isChallengeAccepted = false;
  bool _isChallengeCompleted = false;
  bool _isTriviaAttempted = false; // Para trivias: si ya se intentó (contestó)
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadTodayChallenge();
    _checkChallengeStatus();
    // Refrescar puntos al cargar la pantalla para asegurar que se muestren los valores actualizados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userManager = Provider.of<UserManager>(context, listen: false);
      userManager.refreshAppPoints();
    });
    
    // Hacer que el scroll comience abajo y suba con animación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Ir directamente al final del scroll (sin animación)
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        
        // Después de 800ms, subir suavemente hacia arriba
        Future.delayed(Duration(milliseconds: 800), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: Duration(milliseconds: 1500),
              curve: Curves.easeInOutCubic,
            );
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTodayChallenge() async {
    final challenge = await _challengeService.getTodayChallenge();
    setState(() {
      _todayChallenge = challenge;
    });
    _checkChallengeStatus();
  }
  
  Future<void> _checkChallengeStatus() async {
    if (_todayChallenge == null) return;
    
    final isAccepted = await _challengeService.isChallengeAccepted();
    final isCompleted = await _challengeService.isChallengeCompleted();
    final isTriviaAttempted = _todayChallenge!.type == ChallengeType.trivia
        ? await _challengeService.isTriviaAttempted()
        : false;
    
    setState(() {
      _isChallengeAccepted = isAccepted;
      _isChallengeCompleted = isCompleted;
      _isTriviaAttempted = isTriviaAttempted;
    });
  }
  
  Future<void> _acceptChallengeFromModule() async {
    if (_todayChallenge == null) return;
    
    // Marcar el reto como aceptado usando el servicio
    await _challengeService.acceptChallenge();
    
    setState(() {
      _isChallengeAccepted = true;
    });
    
    // Navegar según el tipo de reto
    if (_todayChallenge!.type == ChallengeType.coins) {
      // Navegar al juego
      Navigator.pushNamed(context, '/juego');
    } else if (_todayChallenge!.type == ChallengeType.video) {
      // Extraer el número del video del videoId (ej: "video_1" -> 1, "video_5" -> 5)
      int? videoNumber;
      if (_todayChallenge!.videoId != null) {
        final videoIdStr = _todayChallenge!.videoId.toString();
        final match = RegExp(r'video_(\d+)').firstMatch(videoIdStr);
        if (match != null) {
          videoNumber = int.tryParse(match.group(1)!);
        }
      }
      
      // Navegar al video blog con el video específico
      if (videoNumber != null && videoNumber >= 1 && videoNumber <= 5) {
        Navigator.pushNamed(
          context,
          '/video-blog',
          arguments: videoNumber,
        );
      } else {
        // Si no se puede determinar el video, navegar a la lista
        Navigator.pushNamed(context, '/video-blog');
      }
    } else if (_todayChallenge!.type == ChallengeType.trivia) {
      // Para trivias, ya se maneja en el botón con _showTriviaChallenge()
      // No hacer nada aquí
    }
  }
  
  Future<void> _showTriviaChallenge() async {
    if (_todayChallenge == null || _todayChallenge!.type != ChallengeType.trivia) {
      return;
    }
    
    // Mostrar la trivia usando el helper
    final userManager = Provider.of<UserManager>(context, listen: false);
    await ChallengeHelper.showTriviaChallenge(
      context,
      _todayChallenge!,
      _challengeService,
      userManager,
    );
    
    // Refrescar el estado después de cerrar la trivia
    _checkChallengeStatus();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refrescar estado cuando se vuelve a la pantalla
    _checkChallengeStatus();
  }
  
  /// Obtener nivel actual basado en puntos de racha
  String _getCurrentLevel(int rachaPoints) {
    if (rachaPoints >= 2001) {
      return 'EMBAJADOR DEL AHORRO';
    } else if (rachaPoints >= 1201) {
      return 'LÍDER COOPERATIVO';
    } else if (rachaPoints >= 501) {
      return 'JUGADOR CONSTANTE';
    } else if (rachaPoints >= 101) {
      return 'AHORRADOR ACTIVO';
    } else {
      return 'APRENDIZ COOPERATIVO';
    }
  }
  
  /// Obtener número de nivel (1-5)
  int _getLevelNumber(int rachaPoints) {
    if (rachaPoints >= 2001) return 5;
    if (rachaPoints >= 1201) return 4;
    if (rachaPoints >= 501) return 3;
    if (rachaPoints >= 101) return 2;
    return 1;
  }
  
  @override
  Widget build(BuildContext context) {
    final userManager = Provider.of<UserManager>(context);
    final rachaDias = userManager.rachaDias;
    final rachaPoints = userManager.rachaPoints; // Necesitaremos agregar esto al UserManager
    final currentLevel = _getCurrentLevel(rachaPoints);
    final levelNumber = _getLevelNumber(rachaPoints);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/snippets/Snippets-back.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header de navegación con menú hamburguesa, título y perfil
              HeaderNavigation(
                onMenuTap: () {
                  Navigator.pushNamed(context, '/menu');
                },
                title: 'SECCIÓN',
                subtitle: 'RACHACOOP',
                leftPadding: 15,
              ),
              
              // Contenido con scroll
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      // Header con iconos VIDEOS y JUEGO
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildHeaderIcon(
                              'VIDEOS', 
                              'assets/images/rachacoop/video.jpg',
                              onTap: () {
                                Navigator.pushNamed(context, '/video-blog');
                              },
                            ),
                            _buildHeaderIcon(
                              'JUEGO', 
                              'assets/images/rachacoop/video-juego.jpg',
                              onTap: () {
                                Navigator.pushNamed(context, '/juego');
                              },
                            ),
                          ],
                        ),
                      ),
                
                // Sección RACHACOOP
                _buildRachacoopSection(rachaDias, currentLevel, rachaPoints),
                
                SizedBox(height: 20),
                
                // Sección "LA RACHA DE HOY ES..."
                if (_todayChallenge != null)
                  _buildTodayChallengeSection(_todayChallenge!),
                
                SizedBox(height: 20),
                
                // Sección NIVELES
                _buildLevelsSection(levelNumber),
                
                SizedBox(height: 20),
                
                // Sección INFORMACIÓN DE LAS RACHAS
                _buildRachaInfoSection(),
                
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeaderIcon(String label, String imagePath, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white.withOpacity(0.2),
                    child: Icon(Icons.play_circle, color: Colors.white, size: 40),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRachacoopSection(int rachaDias, String currentLevel, int rachaPoints) {
    final levelNumber = _getLevelNumber(rachaPoints);
    final characterImage = 'assets/images/rachacoop/level$levelNumber.png';
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6B46C1).withOpacity(0.8),
            Color(0xFF4A148C),
          ],
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // Título RACHACOOP con imagen
              Image.asset(
                'assets/images/rachacoop/rachacoop-title.png',
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    'RACHACOOP',
                    style: TextStyle(
                      fontFamily: 'Gotham Rounded',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Color(0xFFE91E63),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              SizedBox(height: 12),
              
              Text(
                'CADA DÍA SE ACTIVA UNA MISIÓN DIVERTIDA Y EXCLUSIVA.',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.2, // Reducir interlineado
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 25),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actualmente tienes el nivel de',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 11,
                            color: Color(0xFFB794F6), // Morado claro
                            height: 1.2, // Reducir interlineado
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          currentLevel,
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 15, // Reducido de 18 a 15 (3 píxeles menos)
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            height: 1.2, // Reducir interlineado
                          ),
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Llevas acumulados',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 11,
                            color: Color(0xFFB794F6), // Morado claro
                            height: 1.2, // Reducir interlineado
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '$rachaDias días consecutivos',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2, // Reducir interlineado
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Espacio para la imagen que está posicionada absolutamente
                  SizedBox(width: 180),
                ],
              ),
            ],
          ),
          // Personaje con badge de puntos - posicionado al borde derecho
          Positioned(
            right: -20, // Pegado al borde derecho, saliendo un poco del contenedor
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Personaje - tamaño más grande
                Image.asset(
                  characterImage,
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 110,
                      ),
                    );
                  },
                ),
                // Badge de puntos - más grande y mejor posicionado
                Positioned(
                  bottom: -8,
                  right: -12,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Color(0xFFE91E63), // Rosa vibrante
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TIENES',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '$rachaPoints',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'PUNTOS',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTodayChallengeSection(DailyChallenge challenge) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Color(0xFFE91E63), // Rosa vibrante
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 15),
            child: Text(
              '¡SUPÉRALA!',
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(left: 15),
            child: Text(
              'LA RACHA DE HOY ES...',
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 15),
          Text(
            challenge.description,
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SU VALOR ES DE ',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              Text(
                '10 PUNTOS!',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Image.asset(
                'assets/images/rachacoop/star.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.star,
                    color: Color(0xFFFFD700),
                    size: 20,
                  );
                },
              ),
            ],
          ),
          
          // Mensaje de reto completado (para todos los tipos: video, monedas, trivia completada)
          if (_isChallengeCompleted)
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(0xFF4ECDC4),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF4ECDC4),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '¡El reto de hoy ya se ha logrado!',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Mensaje de trivia ya intentada pero no completada (contestada incorrectamente)
          if (challenge.type == ChallengeType.trivia && _isTriviaAttempted && !_isChallengeCompleted)
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(0xFF4ECDC4),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cancel,
                      color: Color(0xFF4ECDC4),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Esta trivia ya se contestó hoy',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Botón de aceptar/ver reto
          // Para trivias: mostrar solo si NO está completado Y NO se ha intentado
          // Para otros retos: mostrar solo si no se ha aceptado y no está completado
          if ((challenge.type == ChallengeType.trivia && !_isChallengeCompleted && !_isTriviaAttempted) ||
              (challenge.type != ChallengeType.trivia && !_isChallengeAccepted && !_isChallengeCompleted))
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: GestureDetector(
                onTap: () {
                  if (challenge.type == ChallengeType.trivia) {
                    // Para trivias, mostrar directamente la trivia
                    _showTriviaChallenge();
                  } else {
                    // Para otros retos, solo aceptar
                    _acceptChallengeFromModule();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    challenge.type == ChallengeType.trivia ? '¡Ver Trivia!' : '¡Aceptar Reto!',
                    style: TextStyle(
                      fontFamily: 'Gotham Rounded',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildLevelsSection(int currentLevel) {
    final levels = [
      {'name': 'APRENDIZ COOPERATIVO', 'nameLine1': 'APRENDIZ', 'nameLine2': 'COOPERATIVO', 'range': '0 - 100', 'image': 'level1-pq.png'},
      {'name': 'AHORRADOR ACTIVO', 'nameLine1': 'AHORRADOR', 'nameLine2': 'ACTIVO', 'range': '101 - 500', 'image': 'level2-pq.png'},
      {'name': 'JUGADOR CONSTANTE', 'nameLine1': 'JUGADOR', 'nameLine2': 'CONSTANTE', 'range': '501 - 1200', 'image': 'level3-pq.png'},
      {'name': 'LÍDER COOPERATIVO', 'nameLine1': 'LÍDER', 'nameLine2': 'COOPERATIVO', 'range': '1201 - 2000', 'image': 'level4-pq.png'},
      {'name': 'EMBAJADOR DEL AHORRO', 'nameLine1': 'EMBAJADOR', 'nameLine2': ' DEL AHORRO', 'range': '+2000', 'image': 'level5-pq.png'},
    ];
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6B46C1).withOpacity(0.8),
            Color(0xFF4A148C),
          ],
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 15),
            child: Text(
              'NIVELES',
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 20),
          // Niveles en fila horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: levels.asMap().entries.map((entry) {
                final index = entry.key;
                final level = entry.value;
                final isUnlocked = (index + 1) <= currentLevel;
                
                return Container(
                  margin: EdgeInsets.only(right: 8), // Reducido de 15 a 8 para juntar más los elementos
                  child: Column(
                    children: [
                      // Imagen del personaje - sin opacidad, tamaño ajustado para que no se corte
                      Image.asset(
                        'assets/images/rachacoop/${level['image']}',
                        width: 50, // Reducido de 70 a 50 (aproximadamente 30% más pequeño)
                        height: 50, // Reducido de 70 a 50 (aproximadamente 30% más pequeño)
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isUnlocked 
                                  ? Color(0xFF4ECDC4) 
                                  : Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: isUnlocked ? Colors.white : Colors.white54,
                              size: 25,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 9), // Aumentado de 8 a 9 para bajar 1 píxel
                      // Nombre del nivel en dos líneas pegadas
                      SizedBox(
                        width: 60, // Ancho fijo para forzar dos líneas
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              level['nameLine1'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Gotham Rounded',
                                fontSize: 7, // Reducido de 9 a 7 (2 píxeles más pequeño)
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.0, // Sin interlineado
                              ),
                            ),
                            SizedBox(height: 0), // Sin espacio entre líneas
                            Text(
                              level['nameLine2'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Gotham Rounded',
                                fontSize: 7, // Reducido de 9 a 7 (2 píxeles más pequeño)
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.0, // Sin interlineado
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      // Número de nivel
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontFamily: 'Gotham Rounded',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: (index + 1) >= 2 ? Colors.white : (isUnlocked ? Colors.white : Colors.white38), // Niveles 2-5 al 100%
                        ),
                      ),
                      SizedBox(height: 4),
                      // Rango de puntos
                      Text(
                        level['range'] as String,
                        style: TextStyle(
                          fontFamily: 'Gotham Rounded',
                          fontSize: 10,
                          color: (index + 1) >= 2 ? Colors.white70 : (isUnlocked ? Colors.white70 : Colors.white38), // Niveles 2-5 al 100%
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRachaInfoSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Color(0xFF2D3748), // Gris oscuro
        borderRadius: BorderRadius.circular(40),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Título
            Padding(
              padding: EdgeInsets.only(left: 15),
              child: Text(
                'INFORMACIÓN DE LAS RACHAS',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 10),
            // Estrella centrada debajo del título
            Center(
              child: Image.asset(
                'assets/images/rachacoop/star.png',
                width: 30,
                height: 30,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(0xFFE53E3E),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 18,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            _buildRachaInfoItem(
              'Racha Diaria',
              'De 1 a 7 días consecutivos. Implica entrar al juego, ver completo un video o responder una trivia. Obtienes +10 puntos al día.',
            ),
            SizedBox(height: 15),
            _buildRachaInfoItem(
              'Racha Semanal',
              'Al completar 7 días consecutivos se activa la Racha Semanal. Obtienes +100 puntos.',
            ),
            SizedBox(height: 15),
            _buildRachaInfoItem(
              'Racha Mensual',
              '30 días de actividad consecutiva. Te otorga la posibilidad de cambiar de skin en tu perfil. Obtienes +500 puntos.',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRachaInfoItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Gotham Rounded',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4ECDC4), // Verde claro
          ),
        ),
        SizedBox(height: 5),
        Text(
          description,
          style: TextStyle(
            fontFamily: 'Gotham Rounded',
            fontSize: 12,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

