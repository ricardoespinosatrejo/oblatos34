import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'user_manager.dart';
import 'widgets/animated_profile_image.dart';
import 'utils/challenge_helper.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Variables del menú lateral eliminadas
  
  // Controladores para las animaciones fade in de los botones
  late List<AnimationController> _buttonAnimationControllers;
  late List<Animation<double>> _buttonAnimations;
  
  // Variables para el submenu
  bool _isSubmenuVisible = false;
  bool _isCooperativaViewVisible = false; // Vista de Tu Cooperativa (swipe)
  late AnimationController _submenuAnimationController;
  late AnimationController _cooperativaSwipeController;
  late Animation<Offset> _submenuSlideAnimation;
  late Animation<Offset> _cooperativaSwipeAnimation;
  final AudioPlayer _centerButtonPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores de animación para los 4 botones principales
    _buttonAnimationControllers = List.generate(4, (index) => 
      AnimationController(
        duration: Duration(milliseconds: 1000), // 1 segundo
        vsync: this,
      )
    );
    
    _buttonAnimations = _buttonAnimationControllers.map((controller) => 
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeIn),
      )
    ).toList();
    
    // Iniciar animaciones con delay escalonado
    _startButtonAnimations();
    
    // Inicializar controlador de animación del submenu
    _submenuAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _submenuSlideAnimation = Tween<Offset>(
      begin: Offset(0, 1), // Comienza debajo de la pantalla
      end: Offset(0, 0),   // Termina en su posición final
    ).animate(CurvedAnimation(
      parent: _submenuAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Inicializar controlador de animación del swipe de Tu Cooperativa
    _cooperativaSwipeController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _cooperativaSwipeAnimation = Tween<Offset>(
      begin: Offset(1, 0), // Comienza desde la derecha
      end: Offset(0, 0),   // Termina en su posición
    ).animate(CurvedAnimation(
      parent: _cooperativaSwipeController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Mostrar ventana de reto diario después de que la pantalla se monte
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          ChallengeHelper.showDailyChallengeIfNeeded(context);
        }
      });
    });
  }
  
  
  void _startButtonAnimations() {
    for (int i = 0; i < _buttonAnimationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _buttonAnimationControllers[i].forward();
        }
      });
    }
  }
  
  void _toggleSubmenu() async {
    if (_isSubmenuVisible) {
      // Si está visible, animar hacia abajo y luego ocultar
      _submenuAnimationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isSubmenuVisible = false;
          });
        }
      });
    } else {
      // Si está oculto, mostrar y animar hacia arriba
      setState(() {
        _isSubmenuVisible = true;
      });
      _submenuAnimationController.forward();
      try {
        await _centerButtonPlayer.play(AssetSource('audios/ding.mp3'));
      } catch (_) {}
    }
  }
  
  void _toggleCooperativaView() async {
    if (_isCooperativaViewVisible) {
      // Si está visible, animar hacia la derecha y ocultar
      _cooperativaSwipeController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isCooperativaViewVisible = false;
          });
        }
      });
    } else {
      // Si está oculto, mostrar y animar desde la derecha
      setState(() {
        _isCooperativaViewVisible = true;
      });
      _cooperativaSwipeController.forward();
      try {
        await _centerButtonPlayer.play(AssetSource('audios/ding.mp3'));
      } catch (_) {}
    }
  }

  // Función _toggleMenu eliminada - ya no se usa

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Contenido principal
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  // Contenido principal con swipe
                  Expanded(
                    child: Stack(
                      children: [
                        // Vista principal del menú (se desliza a la izquierda cuando se muestra Tu Cooperativa)
                        SlideTransition(
                          position: _isCooperativaViewVisible
                              ? Tween<Offset>(begin: Offset.zero, end: Offset(-1, 0))
                                  .animate(CurvedAnimation(
                                    parent: _cooperativaSwipeController,
                                    curve: Curves.easeInOutCubic,
                                  ))
                              : AlwaysStoppedAnimation(Offset.zero),
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: 40),
                                
                                // Botones principales con animaciones fade in
                                // 1. Rachacoop (Rojo)
                                FadeTransition(
                                  opacity: _buttonAnimations[0],
                                  child: Center(
                                    child: _buildRachacoopButton(
                                      () => Navigator.pushNamed(context, '/rachacoop'),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 15),
                                
                                // 2. Eventos (Naranja)
                                FadeTransition(
                                  opacity: _buttonAnimations[1],
                                  child: Center(
                                    child: _buildCustomEventosButton(
                                      () => Navigator.pushNamed(context, '/eventos'),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 15),
                                
                                // 3. Tu Cooperativa (Verde) - con swipe
                                FadeTransition(
                                  opacity: _buttonAnimations[2],
                                  child: Center(
                                    child: _buildTuCooperativaButton(
                                      () => _toggleCooperativaView(),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 15),
                                
                                // 4. Calculadora
                                FadeTransition(
                                  opacity: _buttonAnimations[3],
                                  child: Center(
                                    child: _buildCalculadoraButton(
                                      () => Navigator.pushNamed(context, '/calculadora'),
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: 300),
                              ],
                            ),
                          ),
                        ),
                        
                        // Vista de Tu Cooperativa (swipe desde la derecha)
                        SlideTransition(
                          position: _cooperativaSwipeAnimation,
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 40),
                                
                                // Botón de volver
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: GestureDetector(
                                    onTap: _toggleCooperativaView,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Volver',
                                            style: TextStyle(
                                              fontFamily: 'Gotham Rounded',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                
                                // Título de la sección
                                Text(
                                  'Tu Cooperativa',
                                  style: TextStyle(
                                    fontFamily: 'Gotham Rounded',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 30),
                                
                                // Botones de las secciones (todos en verde)
                                // 1. Historia (antes Caja)
                                FadeTransition(
                                  opacity: _buttonAnimations[0],
                                  child: _buildCooperativaSectionButton(
                                    'Historia',
                                    'Conoce nuestra historia',
                                    'assets/images/menu/icono1.png',
                                    () => Navigator.pushNamed(context, '/caja'),
                                  ),
                                ),
                                SizedBox(height: 15),
                                
                                // 2. El poder de la cooperación
                                FadeTransition(
                                  opacity: _buttonAnimations[1],
                                  child: _buildCooperativaSectionButton(
                                    'El poder de\nla cooperación',
                                    'Descubre el poder',
                                    'assets/images/menu/icono2.png',
                                    () => Navigator.pushNamed(context, '/poder-cooperacion'),
                                  ),
                                ),
                                SizedBox(height: 15),
                                
                                // 3. Aprendiendo la manera cooperativa
                                FadeTransition(
                                  opacity: _buttonAnimations[2],
                                  child: _buildCooperativaSectionButton(
                                    'Aprendiendo la\nmanera cooperativa',
                                    'Aprende con nosotros',
                                    'assets/images/menu/icono3.png',
                                    () => Navigator.pushNamed(context, '/aprendiendo-cooperativa'),
                                  ),
                                ),
                                SizedBox(height: 15),
                                
                                // 4. Agentes del cambio
                                FadeTransition(
                                  opacity: _buttonAnimations[3],
                                  child: _buildCooperativaSectionButton(
                                    'Agentes del cambio',
                                    'Conoce a los agentes',
                                    'assets/images/menu/icono2.png',
                                    () => Navigator.pushNamed(context, '/agentes-cambio'),
                                  ),
                                ),
                                
                                SizedBox(height: 300),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Imagen de degradado pegada al borde inferior (bajada 60px)
            Positioned(
              bottom: -60,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/menu/d-fondo.png',
                fit: BoxFit.contain,
                width: 440,
                height: 391,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xFF15134E).withOpacity(0.8),
                          Color(0xFF15134E),
                        ],
                        stops: [0.0, 0.7, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Sección fija de texto (en capa superior)
            Positioned(
              bottom: 15,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: _buildBottomSection(),
              ),
            ),
            
            // Submenu (se muestra cuando se activa)
            if (_isSubmenuVisible) _buildSubmenu(),
            
// Menú lateral eliminado - ya no se usa
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20.0),
      color: Colors.transparent, // Asegurar que el container sea transparente
      child: Stack(
        clipBehavior: Clip.none, // Permitir overflow controlado
        children: [
          // Título central centrado
          Positioned(
            left: 15,
            right: 0,
            top: 0,
            child: Column(
              children: [
                Text(
                  '¡HOLA!',
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'MENU',
                  style: TextStyle(
                    fontFamily: 'Gryzensa',
                    fontSize: 35,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2),
                Text(
                  '¿Qué quieres aprender hoy?',
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Menú hamburguesa (izquierda)
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                // Ya estás en menu.dart, no hace nada
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ya estás en el menú principal'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Color(0xFFE91E63),
                ),
              );
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          
          // Indicador de racha (a la derecha del menú hamburguesa)
          Positioned(
            left: 60, // A la derecha del menú hamburguesa (50px + 10px de espacio)
            top: 0,
            child: Consumer<UserManager>(
              builder: (context, userManager, child) {
                final rachaPoints = userManager.rachaPoints;
                final levelNumber = _getLevelNumber(rachaPoints);
                
                return GestureDetector(
                  onTap: () {
                    // Navegar a la sección de Rachacoop
                    Navigator.pushNamed(context, '/rachacoop');
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Imagen del nivel
                      Container(
                        width: 50,
                        height: 50,
                        child: Image.asset(
                          'assets/images/rachacoop/level$levelNumber-pq.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Si falla, mostrar un contenedor con el número del nivel
                            return Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFE91E63),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '$levelNumber',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Esfera con puntos de racha (encima del personaje)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(0xFF4CAF50), // Verde
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$rachaPoints',
                              style: TextStyle(
                                fontFamily: 'Gotham Rounded',
                                fontSize: 10,
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
              },
            ),
          ),
          
          // Perfil de usuario (derecha) - mismo estilo que HeaderNavigation
          Positioned(
            right: -20, // Compensar padding y pegar al borde
            top: -30,
            child: GestureDetector(
              onTap: () async {
                // Reproducir audio antes de navegar
                try {
                  final audioPlayer = AudioPlayer();
                  await audioPlayer.play(AssetSource('audios/perfil.mp3'));
                  await Future.delayed(Duration(milliseconds: 200));
                  audioPlayer.dispose();
                } catch (e) {
                  print('Error reproduciendo audio: $e');
                }
                
                Navigator.pushNamed(context, '/perfil');
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Imagen de perfil con animación
                  Consumer<UserManager>(
                    builder: (context, userManager, child) {
                      final profileImage = userManager.currentUser?['profile_image'] ?? 1;
                      
                      Widget imageWidget;
                      
                      if (profileImage >= 1 && profileImage <= 6) {
                        imageWidget = ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 120,
                            maxWidth: MediaQuery.of(context).size.width * 0.4,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Image.asset(
                              'assets/images/perfil/perfil$profileImage-big.png',
                              fit: BoxFit.fitHeight,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/1inicio/perfil.png',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        );
                      } else {
                        imageWidget = ClipOval(
                          child: Image.asset(
                            'assets/images/perfil/perfil$profileImage.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      
                      return AnimatedProfileImage(
                        key: ValueKey('profile_image_menu'),
                        profileImage: profileImage,
                        imageWidget: imageWidget,
                      );
                    },
                  ),
                  // Nombre del usuario
                  Positioned(
                    top: 80,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Color(0xFFF44336).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Consumer<UserManager>(
                        builder: (context, userManager, child) {
                          return Text(
                            userManager.userName,
                            style: TextStyle(
                              fontFamily: 'Gotham Rounded',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCajaButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50), // Esquinas muy redondeadas
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF50ABFF),
              Color(0xFF4E99FF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Esfera del ícono - 80x80px
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1B66DE),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/menu/icono1.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.account_balance_outlined,
                        size: 36,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Caja',
                      style: TextStyle(
                        fontFamily: 'Gotham Book',
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        height: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Conoce nuestra historia',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCooperacionButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50), // Esquinas muy redondeadas
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFB07FFF),
              Color(0xFFCC5AFF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Esfera del ícono - 80x80px
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF9811D7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/menu/icono2.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.handshake,
                        size: 36,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'El poder de\nla cooperación',
                      style: TextStyle(
                        fontFamily: 'Gotham Book',
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        height: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Valores cooperativos',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAprendiendoButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50), // Esquinas muy redondeadas
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF5AFDAB),
              Color(0xFF1DE680),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Esfera del ícono - 80x80px
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF098947),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/menu/icono3.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.school,
                        size: 36,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Aprendiendo\nla manera\ncooperativa',
                      style: TextStyle(
                        fontFamily: 'Gotham Book',
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        height: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Historias que inspiran',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAgentesButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50), // Esquinas muy redondeadas
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFF51B7),
              Color(0xFFE83DA1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Esfera del ícono - 80x80px
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFC50B78),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/menu/icono4.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.favorite,
                        size: 36,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Agentes de\ncambio',
                      style: TextStyle(
                        fontFamily: 'Gotham Book',
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        height: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tú puedes hacer la diferencia',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomEventosButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50), // Esquinas muy redondeadas
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFCD527),
              Color(0xFFFF9F51),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Esfera del ícono - 80x80px
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEC6E00),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/menu/icono5.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.event,
                        size: 36,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Eventos y\ncampañas',
                      style: TextStyle(
                        fontFamily: 'Gotham Book',
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        height: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Participa en nuestras actividades',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomVideoBlogButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50), // Esquinas muy redondeadas
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF50F3FF),
              Color(0xFF44CAFF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Esfera del ícono - 80x80px
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF028FC7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/menu/icono6.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.play_circle_outline,
                        size: 36,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Video blog',
                      style: TextStyle(
                        fontFamily: 'Gotham Book',
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        height: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Contenido multimedia',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        // Texto principal
        Text(
          'Caja no es solo una\ninstitución financiera más.',
          style: TextStyle(
            fontFamily: 'Gotham Rounded',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 12),
        
        // Texto secundario
        Text(
          'Su historia demuestra que nació de una visión\nde servicio a la comunidad. Sus valores, como\nla ayuda mutua, la responsabilidad y...',
          style: TextStyle(
            fontFamily: 'Gotham Rounded',
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: Colors.white60,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubmenu() {
    return Positioned(
      bottom: -10, // Más pegado al borde inferior de la pantalla
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _submenuSlideAnimation,
        child: Container(
          height: 375,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/submenu/plasta-menu.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Título "Herramientas Financieras"
              Positioned(
                top: 40, // Centrado entre borde superior y botones
                left: 0,
                right: 0,
                child: Text(
                  'Herramientas Financieras',
                  style: TextStyle(
                    fontFamily: 'GothamRounded',
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Elementos decorativos - Monedas
              Positioned(
                top: 68, // Misma altura que btn-juego
                left: 0, // Pegada totalmente al borde izquierdo
                child: Image.asset(
                  'assets/images/submenu/moneda2.png',
                  width: 30,
                  height: 130,
                ),
              ),
              Positioned(
                top: 58, // 10px más arriba que antes
                right: 10, // 10px separada del borde derecho
                child: Image.asset(
                  'assets/images/submenu/moneda1.png',
                  width: 46,
                  height: 47,
                ),
              ),
              
              // Botones del submenu
              Positioned(
                top: 68,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/juego');
                          },
                          child: Image.asset(
                            'assets/images/submenu/btn-juego.png',
                            height: 156,
                          ),
                        ),
                        SizedBox(width: 9), // Gap de 9px entre botones
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/calculadora');
                          },
                          child: Image.asset(
                            'assets/images/submenu/btn-calculadora.png',
                            height: 150,
                          ),
                        ),
                      ],
                    ),
                    
                    // Etiquetas de los botones
                    SizedBox(height: 10), // Espacio entre botones y etiquetas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Etiqueta "Juego" - Movida 10px a la derecha
                        Transform.translate(
                          offset: Offset(20, 0), // Mover 20px a la derecha (10px + 10px más)
                          child: SizedBox(
                            width: 156, // Mismo ancho que btn-juego
                            child: Text(
                              'Juego',
                              style: TextStyle(
                                fontFamily: 'GothamRounded',
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(width: 9), // Gap de 9px entre etiquetas
                        // Etiqueta "Calculadora" - Movida 15px a la izquierda
                        Transform.translate(
                          offset: Offset(-18, 0), // Mover 18px a la izquierda (15px + 3px más)
                          child: SizedBox(
                            width: 150, // Mismo ancho que btn-calculadora
                            child: Text(
                              'Calculadora',
                              style: TextStyle(
                                fontFamily: 'GothamRounded',
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Menú lateral eliminado - ya no se usa

  Widget _buildRachacoopButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFE91E63), // Rojo
              Color(0xFFC2185B),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFB71C1C),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/menu/icono8.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.emoji_events, size: 36, color: Colors.white);
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Rachacoop',
                      style: TextStyle(
                        fontFamily: 'Gotham Book',
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        height: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Completa tus retos diarios',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTuCooperativaButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF4CAF50), // Verde
              Color(0xFF388E3C),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2E7D32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/menu/icono1.png', // Ícono de Caja
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.account_balance, size: 36, color: Colors.white);
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tu Cooperativa',
                      style: TextStyle(
                        fontFamily: 'Gotham Book',
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        height: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Explora nuestra cooperativa',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCalculadoraButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF9E9E9E), // Gris
              Color(0xFF757575),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF616161),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/menu/icono7.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.calculate, size: 36, color: Colors.white);
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Calculadora',
                      style: TextStyle(
                        fontFamily: 'Gotham Book',
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        height: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Calcula tus ahorros',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Obtener número de nivel (1-5) basado en puntos de racha
  int _getLevelNumber(int rachaPoints) {
    if (rachaPoints >= 2001) return 5;
    if (rachaPoints >= 1201) return 4;
    if (rachaPoints >= 501) return 3;
    if (rachaPoints >= 101) return 2;
    return 1;
  }
  
  Widget _buildCooperativaSectionButton(String title, String subtitle, String iconPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF4CAF50), // Verde
              Color(0xFF388E3C),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2E7D32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    iconPath,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.circle, size: 36, color: Colors.white);
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Gotham Book',
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                        height: 0.8,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    for (var controller in _buttonAnimationControllers) {
      controller.dispose();
    }
    _submenuAnimationController.dispose();
    _cooperativaSwipeController.dispose();
    _centerButtonPlayer.dispose();
    super.dispose();
  }
}