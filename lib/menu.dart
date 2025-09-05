import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'inicio.dart'; // Para acceder a ProfileImageManager
import 'user_manager.dart';

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
  late AnimationController _submenuAnimationController;
  late Animation<Offset> _submenuSlideAnimation;
  final AudioPlayer _centerButtonPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores de animación para los 6 botones
    _buttonAnimationControllers = List.generate(6, (index) => 
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
                  
                  // Contenido principal
                  Expanded(
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 40),
                          
                          // Botones principales con animaciones fade in
                          FadeTransition(
                            opacity: _buttonAnimations[0],
                            child: _buildCustomCajaButton(
                              () => Navigator.pushNamed(context, '/caja'),
                            ),
                          ),
                          SizedBox(height: 15),
                          
                          FadeTransition(
                            opacity: _buttonAnimations[1],
                            child: _buildCustomCooperacionButton(
                              () => Navigator.pushNamed(context, '/poder-cooperacion'),
                            ),
                          ),
                          SizedBox(height: 15),
                          
                          FadeTransition(
                            opacity: _buttonAnimations[2],
                            child: _buildCustomAprendiendoButton(
                              () => Navigator.pushNamed(context, '/aprendiendo-cooperativa'),
                            ),
                          ),
                          SizedBox(height: 15),
                          
                          FadeTransition(
                            opacity: _buttonAnimations[3],
                            child: _buildCustomAgentesButton(
                              () => Navigator.pushNamed(context, '/agentes-cambio'),
                            ),
                          ),
                          SizedBox(height: 15),
                          
                          FadeTransition(
                            opacity: _buttonAnimations[4],
                            child: _buildCustomEventosButton(
                              () => Navigator.pushNamed(context, '/eventos'),
                            ),
                          ),
                          SizedBox(height: 15),
                          
                          FadeTransition(
                            opacity: _buttonAnimations[5],
                            child: _buildCustomVideoBlogButton(
                              () => Navigator.pushNamed(context, '/video-blog'),
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
            
            // Imagen de degradado pegada al borde inferior
            Positioned(
              bottom: 0,
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
              bottom: 113,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: _buildBottomSection(),
              ),
            ),
            
            // Submenu (se muestra cuando se activa)
            if (_isSubmenuVisible) _buildSubmenu(),
            
            // Bottom Navigation (debe estar al final para estar por encima del submenú)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavigation(),
            ),
            
// Menú lateral eliminado - ya no se usa
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
          // Menú hamburguesa (ya estás en menu, no hace nada)
          GestureDetector(
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
          
          Spacer(),
          
          // Título central
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
                'MENU NAV',
                style: TextStyle(
                  fontFamily: 'Gryzensa',
                  fontSize: 35,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
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
              ),
            ],
          ),
          
          Spacer(),
          
          // Perfil de usuario
          Column(
            children: [
              GestureDetector(
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
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFFE91E63), width: 2),
                    color: Colors.white,
                  ),
                  child: Stack(
                    children: [
                      // Foto de perfil o imagen por defecto
                      Center(
                        child: ClipOval(
                          child: Consumer<UserManager>(
                            builder: (context, userManager, child) {
                              final profileImage = userManager.currentUser?['profile_image'] ?? 1;
                              return Image.asset(
                                'assets/images/perfil/perfil$profileImage.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Si falla, mostrar imagen por defecto
                                  return Image.asset(
                                    'assets/images/1inicio/perfil.png',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 4),
              Consumer<UserManager>(
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
            ],
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

  Widget _buildBottomNavigation() {
    return Container(
      height: 98,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/menu/menu-barra.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            spreadRadius: 2,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem('m-icono1.png', 'Caja\nOblatos', '/caja'),
          _buildNavItem('m-icono2.png', 'Agentes\nCambio', '/agentes-cambio'),
          _buildCenterNavItem('m-icono3.png'),
          _buildNavItem('m-icono4.png', 'Eventos', '/eventos'),
          _buildNavItem('m-icono5.png', 'Video\nBlog', '/video-blog'),
        ],
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, String? route, {bool isCenter = false}) {
    return GestureDetector(
      onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isCenter ? 68 : 25,
            height: isCenter ? 68 : 25,
            decoration: isCenter ? BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFFF1744),
                  Color(0xFFE91E63),
                ],
              ),
              border: Border.all(color: Colors.black, width: 1),
            ) : null,
            child: isCenter ? Center(
              child: Image.asset(
                'assets/images/menu/$iconPath',
                width: 24,
                height: 24,
                color: Colors.white,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.home, color: Colors.white, size: 24);
                },
              ),
            ) : Image.asset(
              'assets/images/menu/$iconPath',
              width: 8,
              height: 8,
              color: Colors.white,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.home, color: Colors.white, size: 8);
              },
            ),
          ),
          if (!isCenter && label.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCenterNavItem(String iconPath) {
    return Transform.translate(
      offset: Offset(-6, -14),
      child: GestureDetector(
        onTap: _toggleSubmenu,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFFF1744),
                    Color(0xFFE91E63),
                  ],
                ),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/menu/$iconPath',
                  width: 24,
                  height: 24,
                  color: Colors.white,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.home, color: Colors.white, size: 24);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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
                        // Etiqueta "Juego"
                        SizedBox(
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
                        SizedBox(width: 9), // Gap de 9px entre etiquetas
                        // Etiqueta "Calculadora"
                        SizedBox(
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

  @override
  void dispose() {
    // Dispose de todos los controladores de animación de botones
    for (var controller in _buttonAnimationControllers) {
      controller.dispose();
    }
    
    // Dispose del controlador de animación del submenu
    _submenuAnimationController.dispose();
    _centerButtonPlayer.dispose();
    
    super.dispose();
  }
}