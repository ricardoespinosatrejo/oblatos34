import 'package:flutter/material.dart';
import 'widgets/bottom_navigation_menu.dart';
import 'menu.dart';
import 'caja_correcto.dart' as caja;
import 'poder.dart' as poder;
import 'aprendiendo.dart' as aprendiendo;
import 'agentes.dart' as agentes;
import 'eventos.dart' as eventos;
import 'videoblog.dart' as videoblog;

class MainContainer extends StatefulWidget {
  final String initialRoute;
  
  const MainContainer({Key? key, this.initialRoute = '/menu'}) : super(key: key);

  @override
  _MainContainerState createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  String _currentRoute = '/menu';
  late PageController _pageController;
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentRoute = widget.initialRoute;
    _currentIndex = _getIndexForRoute(_currentRoute);
    _pageController = PageController(initialPage: _currentIndex);
  }

  int _getIndexForRoute(String route) {
    switch (route) {
      case '/menu':
        return 0;
      case '/caja':
        return 1;
      case '/poder-cooperacion':
        return 2;
      case '/aprendiendo-cooperativa':
        return 3;
      case '/agentes-cambio':
        return 4;
      case '/eventos':
        return 5;
      case '/video-blog':
        return 6;
      default:
        return 0;
    }
  }

  void _navigateToRoute(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  Widget _getCurrentScreen() {
    switch (_currentRoute) {
      case '/menu':
        return HomeScreen(); // Usar el HomeScreen completo de menu.dart
      case '/caja':
        return caja.CajaScreen(); // Usar el CajaScreen completo
      case '/poder-cooperacion':
        return poder.PoderCooperacionScreen(); // Usar el PoderScreen completo
      case '/aprendiendo-cooperativa':
        return aprendiendo.AprendiendoCooperativaScreen(); // Usar el AprendiendoScreen completo
      case '/agentes-cambio':
        return agentes.AgentesCambioScreen(); // Usar el AgentesScreen completo
      case '/eventos':
        return eventos.EventosScreen(); // Usar el EventosScreen completo
      case '/video-blog':
        return videoblog.VideoBlogScreen(); // Usar el VideoBlogScreen completo
      default:
        return HomeScreen(); // Usar el HomeScreen completo de menu.dart
    }
  }



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
            // Contenido principal que cambia (con espacio para el menú)
            Positioned.fill(
              bottom: 98, // Altura del menú rojo
              child: _getCurrentScreen(),
            ),
            
            // Menú inferior FIJO (en Stack con Positioned)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNavigationMenu(),
            ),
          ],
        ),
      ),
    );
  }

  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/menu';
      case 1:
        return '/caja';
      case 2:
        return '/poder-cooperacion';
      case 3:
        return '/aprendiendo-cooperativa';
      case 4:
        return '/agentes-cambio';
      case 5:
        return '/eventos';
      case 6:
        return '/video-blog';
      default:
        return '/menu';
    }
  }
}



// Contenido del menú principal (copiado de menu.dart sin menú inferior)
class HomeScreenContent extends StatefulWidget {
  final Function(String) onNavigate;
  
  const HomeScreenContent({Key? key, required this.onNavigate}) : super(key: key);
  
  @override
  _HomeScreenContentState createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> with TickerProviderStateMixin {
  // Controladores para las animaciones fade in de los botones
  late List<AnimationController> _buttonAnimationControllers;
  late List<Animation<double>> _buttonAnimations;

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Contenido principal (sin scroll)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botones principales con animaciones fade in
                  FadeTransition(
                    opacity: _buttonAnimations[0],
                    child: _buildCustomCajaButton(() {
                      // No navegación externa, se maneja internamente
                    }),
                  ),
                  SizedBox(height: 15),
                  
                  FadeTransition(
                    opacity: _buttonAnimations[1],
                    child: _buildCustomCooperacionButton(() {
                      // No navegación externa
                    }),
                  ),
                  SizedBox(height: 15),
                  
                  FadeTransition(
                    opacity: _buttonAnimations[2],
                    child: _buildCustomAprendiendoButton(() {
                      // No navegación externa
                    }),
                  ),
                  SizedBox(height: 15),
                  
                  FadeTransition(
                    opacity: _buttonAnimations[3],
                    child: _buildCustomAgentesButton(() {
                      // Navegar a Agentes
                      widget.onNavigate('/agentes-cambio');
                    }),
                  ),
                  SizedBox(height: 15),
                  
                  FadeTransition(
                    opacity: _buttonAnimations[4],
                    child: _buildCustomEventosButton(() {
                      // No navegación externa
                    }),
                  ),
                  SizedBox(height: 15),
                  
                  FadeTransition(
                    opacity: _buttonAnimations[5],
                    child: _buildCustomVideoBlogButton(() {
                      // No navegación externa
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header completo copiado de menu.dart
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
              Container(
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
                        child: Image.asset(
                          'assets/images/1inicio/logo-CO.png', // Usar logo como foto por defecto
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
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
              SizedBox(height: 4),
              Text(
                'Usuario', // Nombre temporal
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCajaButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        // Cambiar contenido a Caja
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MainContainer(initialRoute: '/caja'),
            ),
          );
        }
      },
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
      onTap: () {
        // Cambiar contenido a Poder de la Cooperación
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MainContainer(initialRoute: '/poder-cooperacion'),
            ),
          );
        }
      },
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
    return Center(
      child: Text(
        'Botón Aprendiendo (temporal)',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildCustomAgentesButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        // Usar el callback para navegar
        onTap();
      },
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50), // Esquinas muy redondeadas
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFF8A65),
              Color(0xFFFF7043),
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
                  color: Color(0xFFE65100),
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
                        Icons.people,
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
                      'Agentes del\ncambio',
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
                      'Líderes cooperativos',
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
    return Center(
      child: Text(
        'Botón Eventos (temporal)',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildCustomVideoBlogButton(VoidCallback onTap) {
    return Center(
      child: Text(
        'Botón Video Blog (temporal)',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose de todos los controladores de animación de botones
    for (var controller in _buttonAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class CajaScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header completo igual que en menu.dart
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Menú hamburguesa (navega al menú principal)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => MainContainer(initialRoute: '/menu'),
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
                      'CAJA OBLATOS',
                      style: TextStyle(
                        fontFamily: 'Gryzensa',
                        fontSize: 35,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: 2.0,
                        height: 0.8,
                      ),
                    ),
                  ],
                ),
                
                Spacer(),
                
                // Perfil de usuario (igual que en menu.dart)
                Column(
                  children: [
                    Container(
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
                              child: Image.asset(
                                'assets/images/1inicio/logo-CO.png', // Usar logo como foto por defecto
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
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
                    SizedBox(height: 4),
                    Text(
                      'Usuario', // Nombre temporal
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono de Caja
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF50ABFF),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Título de la pantalla
                  Text(
                    'CAJA OBLATOS',
                    style: TextStyle(
                      fontFamily: 'Gryzensa',
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Descripción
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Sistema de gestión cooperativa para la comunidad Oblatos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 18,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Botón de acción principal
                  Container(
                    width: 280,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
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
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'ACCEDER A CAJA',
                        style: TextStyle(
                          fontFamily: 'Gotham Rounded',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
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
}

class PoderScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'El Poder de la Cooperación - Contenido temporal',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

class AprendiendoScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Aprendiendo la Manera Cooperativa - Contenido temporal',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

class AgentesScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Agentes del Cambio - Contenido temporal',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

class EventosScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Eventos y Campañas - Contenido temporal',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

class VideoblogScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Video Blog - Contenido temporal',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}
