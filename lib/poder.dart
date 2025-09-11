import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'widgets/header_navigation.dart';

class PoderCooperacionScreen extends StatefulWidget {
  @override
  _PoderCooperacionScreenState createState() => _PoderCooperacionScreenState();
}

class _PoderCooperacionScreenState extends State<PoderCooperacionScreen> with TickerProviderStateMixin {
  int _currentFicha = 0; // 0 = ficha base, 1-9 = fichas específicas
  final ScrollController _scrollController = ScrollController();
  
  // Variables para el submenu
  bool _isSubmenuVisible = false;
  late AnimationController _submenuAnimationController;
  late Animation<Offset> _submenuSlideAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  @override
  void initState() {
    super.initState();
    
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
    
    // Programar la animación del scroll después de que se construya el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateScrollToTop();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _submenuAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  void _animateScrollToTop() {
    if (_scrollController.hasClients) {
      // Ir al final del scroll
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      
      // Después de un breve delay, animar hacia el principio
      Future.delayed(Duration(milliseconds: 500), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: Duration(milliseconds: 1500),
            curve: Curves.easeInOut,
          );
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
      
      // Reproducir audio ding.mp3
      try {
        await _audioPlayer.play(AssetSource('audios/ding.mp3'));
      } catch (e) {
        print('Error reproduciendo audio: $e');
      }
    }
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
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Contenido principal de la pantalla
            MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              removeRight: true,
              child: SafeArea(
                maintainBottomViewPadding: false,
                child: Column(
                  children: [
                    // Header de navegación reutilizable
                    HeaderNavigation(
                      onMenuTap: () {
                        Navigator.pushNamed(context, '/menu');
                      },
                      title: 'BIENVENIDOS',
                      subtitle: 'EL CORAZÓN DE\nCAJA OBLATOS',
                    ),
                    
                    // Contenido específico de la pantalla
                    Expanded(
                      child: _buildFichasSystem(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Submenu (se muestra cuando se activa)
            if (_isSubmenuVisible) _buildSubmenu(),
            
            // Menú inferior rojo
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 25,
            height: 25,
            child: Image.asset(
              'assets/images/menu/$iconPath',
              width: 8,
              height: 8,
              color: Colors.white,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.home, color: Colors.white, size: 8);
              },
            ),
          ),
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

  // Sistema de fichas deslizantes
  Widget _buildFichasSystem() {
    return Stack(
      children: [
        // Ficha base (con botones A, B, C, D, E)
        AnimatedContainer(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(
            _currentFicha == 0 ? 0 : -MediaQuery.of(context).size.width,
            0,
            0,
          ),
          child: _buildFichaBase(),
        ),
        
        // Fichas específicas (1a, 2a, 3a, etc.)
        for (int i = 1; i <= 9; i++)
          AnimatedContainer(
            duration: Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            transform: Matrix4.translationValues(
              _currentFicha == i ? 0 : MediaQuery.of(context).size.width,
              0,
              0,
            ),
            child: _buildFichaEspecifica(i),
          ),
      ],
    );
  }

  // Ficha base con botones A, B, C, D, E
  Widget _buildFichaBase() {
    return Stack(
      children: [
        // Ficha base blanca posicionada en punto medio
        Positioned(
          left: 20, // Reducido de 23
          top: 30,
          child: Container(
            width: MediaQuery.of(context).size.width - 40, // Responsive en lugar de 393 fijo
            height: 580,
            decoration: BoxDecoration(
              image: DecorationImage(
                                  image: AssetImage('assets/images/poder/base-ficha.png'),
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
            child: Stack(
              children: [
                                                  // Botones A, B, C, D, E con scroll
                 Positioned(
                   top: 220,
                   left: 20,
                   right: 20,
                                      child: Container(
                     height: 300,
                     child: SingleChildScrollView(
                       controller: _scrollController,
                       child: Column(
                         children: [
                           _buildPrincipioButton('A', 'AYUDA MUTUA', '¡Uno para todos y todos para uno!', 1),
                           SizedBox(height: 20),
                           _buildPrincipioButton('B', 'RESPONSABILIDAD', '¡Si lo dices, hazlo!', 2),
                           SizedBox(height: 20),
                           _buildPrincipioButton('C', 'DEMOCRACIA', '¡Tu opinión cuenta!', 3),
                           SizedBox(height: 20),
                           _buildPrincipioButton('D', 'IGUALDAD', '¡Mismos derechos, mismas oportunidades!', 4),
                           SizedBox(height: 20),
                           _buildPrincipioButton('E', 'EQUIDAD', '¡Justicia para todos!', 5),
                           SizedBox(height: 20),
                           _buildPrincipioButton('F', 'SOLIDARIDAD', '¡Juntos somos más fuertes!', 6),
                           SizedBox(height: 20),
                           _buildPrincipioButton('G', 'TRANSPARENCIA', '¡Claridad en todo!', 7),
                           SizedBox(height: 20),
                           _buildPrincipioButton('H', 'EDUCACIÓN', '¡Aprender para crecer!', 8),
                           SizedBox(height: 20),
                           _buildPrincipioButton('I', 'COMPROMISO', '¡Cumplir lo prometido!', 9),
                         ],
                       ),
                     ),
                   ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Botón de principio individual
  Widget _buildPrincipioButton(String letter, String title, String description, int fichaIndex) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFicha = fichaIndex;
        });
      },
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Círculo con letra
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF1744), Color(0xFFE91E63)],
                ),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 15),
            
            // Título y descripción
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Gotham Rounded',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Gotham Rounded',
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            
            // Icono plus
            Icon(
              Icons.add,
              color: Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

    // Ficha específica individual
  Widget _buildFichaEspecifica(int fichaIndex) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 700,
      child: Column(
        children: [
          // Botón regresar (mismas medidas que en Caja)
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentFicha = 0;
                    });
                  },
                  child: Image.asset(
                    'assets/images/poder/btn-regresar.png',
                    width: 120,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error cargando btn-regresar: $error');
                      return Container(
                        width: 120,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFE91E63),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'REGRESAR',
                            style: TextStyle(
                              fontFamily: 'Gotham Rounded',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Ficha específica
          Container(
            height: 565,
            child: Center(
              child: Image.asset(
                'assets/images/poder/ficha${fichaIndex}a.png',
                width: 393,
                height: 580,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('Error cargando ficha$fichaIndex: $error');
                  return Container(
                    width: 393,
                    height: 580,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Ficha $fichaIndex',
                            style: TextStyle(
                              fontFamily: 'Gotham Rounded',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Imagen no encontrada: ficha${fichaIndex}a.png',
                            style: TextStyle(
                              fontFamily: 'Gotham Rounded',
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Ruta: assets/images/poder/ficha${fichaIndex}a.png',
                            style: TextStyle(
                              fontFamily: 'Gotham Rounded',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubmenu() {
    return Positioned(
      bottom: -10, // Pegado al borde inferior de la pantalla
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
                top: 40,
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
                top: 68,
                left: 0,
                child: Image.asset(
                  'assets/images/submenu/moneda2.png',
                  width: 30,
                  height: 130,
                ),
              ),
              Positioned(
                top: 58,
                right: 10,
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
                        SizedBox(width: 9),
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
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Etiqueta "Juego"
                        SizedBox(
                          width: 156,
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
                        SizedBox(width: 9),
                        // Etiqueta "Calculadora"
                        SizedBox(
                          width: 150,
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
}
