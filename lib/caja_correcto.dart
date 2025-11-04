import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'widgets/header_navigation.dart'; // Para el HeaderNavigation reutilizable

class CajaScreen extends StatefulWidget {
  @override
  _CajaScreenState createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> with TickerProviderStateMixin {
  bool _showFicha = true; // Controla si mostrar la ficha o la historia
  
  // Variables para el submenu
  bool _isSubmenuVisible = false;
  late AnimationController _submenuAnimationController;
  late Animation<Offset> _submenuSlideAnimation;
  
  // Audio player para el botón central
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Audio player para la historia
  final AudioPlayer _historiaAudioPlayer = AudioPlayer();
  bool _isHistoriaAudioPlaying = false;
  
  // Índice de la imagen actual de historia (1-5)
  int _currentHistoriaIndex = 1;
  
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
    
    // Escuchar cuando el audio termine para actualizar el estado y avanzar automáticamente
    _historiaAudioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isHistoriaAudioPlaying = false;
        });
        // Avanzar automáticamente a la siguiente imagen si no estamos en la última
        if (_currentHistoriaIndex < 5) {
          _nextHistoria();
        }
      }
    });
    
    // Reproducir audio inicial al cargar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playHistoriaAudio(_currentHistoriaIndex);
    });
  }
  
  @override
  void deactivate() {
    // Detener el audio cuando la pantalla sale de vista
    _stopHistoriaAudio();
    super.deactivate();
  }
  
  @override
  void dispose() {
    // Detener y limpiar los audios antes de destruir el widget
    _historiaAudioPlayer.stop();
    _audioPlayer.stop();
    _submenuAnimationController.dispose();
    _audioPlayer.dispose();
    _historiaAudioPlayer.dispose();
    super.dispose();
  }
  
  // Método para reproducir el audio de la historia actual
  void _playHistoriaAudio(int historiaIndex) async {
    // Detener cualquier audio anterior
    await _historiaAudioPlayer.stop();
    await _audioPlayer.stop();
    
    try {
      // Reproducir el audio correspondiente a la imagen actual
      await _historiaAudioPlayer.play(AssetSource('images/caja/historia$historiaIndex.mp3'));
      if (mounted) {
        setState(() {
          _isHistoriaAudioPlaying = true;
        });
      }
    } catch (e) {
      print('Error al reproducir audio: $e');
    }
  }
  
  // Método para navegar a la siguiente imagen
  void _nextHistoria() {
    if (_currentHistoriaIndex < 5) {
      setState(() {
        _currentHistoriaIndex++;
      });
      _playHistoriaAudio(_currentHistoriaIndex);
    }
  }
  
  // Método para navegar a la imagen anterior
  void _previousHistoria() {
    if (_currentHistoriaIndex > 1) {
      setState(() {
        _currentHistoriaIndex--;
      });
      _playHistoriaAudio(_currentHistoriaIndex);
    }
  }
  
  // Método para detener el audio de historia
  void _stopHistoriaAudio() async {
    await _historiaAudioPlayer.stop();
    if (mounted) {
      setState(() {
        _isHistoriaAudioPlaying = false;
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
      } catch (_) {}
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
            SafeArea(
              child: Column(
                children: [
                  // Header de navegación reutilizable
                  HeaderNavigation(
                    onMenuTap: () {
                      // Detener audio antes de navegar
                      _stopHistoriaAudio();
                      Navigator.pushNamed(context, '/menu');
                    },
                    onProfileTap: () {
                      // Detener audio de historia antes de navegar al perfil
                      _stopHistoriaAudio();
                    },
                    title: 'BIENVENIDOS',
                    subtitle: 'CAJA OBLATOS',
                  ),
                  
                  // Contenido específico de la pantalla de caja
                  Expanded(
                    child: _buildFichaPrincipal(),
                  ),
                ],
              ),
            ),
            
            // Submenu (se muestra cuando se activa)
            if (_isSubmenuVisible) _buildSubmenu(),
            
            // Menú inferior rojo (debe estar al final para estar por encima del submenú)
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
      onTap: () {
        // Detener audio antes de navegar
        _stopHistoriaAudio();
        Navigator.pushNamed(context, route);
      },
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

  // Ficha principal de Caja Oblatos
  Widget _buildFichaPrincipal() {
    return Stack(
      children: [
        // Contenedor principal con animación de slide
        AnimatedContainer(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(
            _showFicha ? 0 : -MediaQuery.of(context).size.width,
            0,
            0,
          ),
          child: Stack(
            children: [
              // Ficha base blanca posicionada en punto medio
              Positioned(
                left: 30, // Centrado: (60 - 40) / 2 = 10, entonces 20 + 10 = 30
                top: 30,
                child: Container(
                  width: MediaQuery.of(context).size.width - 60, // Reducido de 40 a 60 para más margen
                  height: 580,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/caja/base-ficha.png'),
                      fit: BoxFit.contain, // Cambiado de cover a contain para que no se estire
                      alignment: Alignment.center,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Imagen de historia con flechas de navegación - directamente en el contenedor blanco
                      Positioned(
                        bottom: 20, // Reducido de 60 a 20 para más espacio
                        left: 0, // Sin margen izquierdo para ocupar todo el ancho
                        right: 0, // Sin margen derecho para ocupar todo el ancho
                        top: 200, // Reducido de 260 a 200 para más espacio vertical
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // Imagen de historia actual - ocupa todo el espacio disponible
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/caja/historia$_currentHistoriaIndex.png',
                                fit: BoxFit.fill,
                              ),
                            ),
                            
                            // Flecha derecha (pegada al borde derecho de la imagen)
                            if (_currentHistoriaIndex < 5)
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: _nextHistoria,
                                  child: Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    child: Image.asset(
                                      'assets/images/caja/flecha-derecha.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Flecha izquierda (pegada al borde izquierdo de la imagen)
                            if (_currentHistoriaIndex > 1)
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: _previousHistoria,
                                  child: Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    child: Image.asset(
                                      'assets/images/caja/flecha-izquierda.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Indicadores de puntos (bolitas) en la parte inferior
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  final isActive = (index + 1) == _currentHistoriaIndex;
                                  return Container(
                                    margin: EdgeInsets.symmetric(horizontal: 4),
                                    width: isActive ? 12 : 8,
                                    height: isActive ? 12 : 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive 
                                          ? Color(0xFFE91E63) // Color rosa/morado cuando está activa
                                          : Colors.white.withOpacity(0.5), // Color blanco semitransparente cuando no está activa
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Título de la ficha encima de la plasta blanca
              Positioned(
                left: 30, // Centrado: (60 - 40) / 2 = 10, entonces 20 + 10 = 30
                top: 30,
                child: Container(
                  width: MediaQuery.of(context).size.width - 60, // Reducido de 40 a 60 para más margen
                  child: Image.asset(
                    'assets/images/caja/titulo-ficha1.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
              
              // Botón siguiente centrado encima del título de la ficha
              Positioned(
                left: (MediaQuery.of(context).size.width - 91.5) / 2, // Centrado responsive
                top: 160,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showFicha = false;
                      });
                    },
                    child: Image.asset(
                      'assets/images/caja/btn-siguiente.png',
                      width: 91.5,
                      height: 60,
                    ),
                  ),
                ),
              ),
              
              // Elementos decorativos chunche-f y chunche-g
              Positioned(
                left: 20, // Reducido de 43
                top: 215,
                child: Image.asset(
                  'assets/images/caja/chunche-f.png',
                  width: 40,
                  height: 40,
                ),
              ),
              Positioned(
                right: 20, // Reducido de 43
                top: 230,
                child: Image.asset(
                  'assets/images/caja/chunche-g.png',
                  width: 40,
                  height: 40,
                ),
              ),
            ],
          ),
        ),
        
        // Imagen de historia con animación de entrada desde la derecha
        AnimatedContainer(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(
            _showFicha ? MediaQuery.of(context).size.width : 0,
            0,
            0,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 700,
            child: Column(
              children: [
                // Botón regresar
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showFicha = true;
                          });
                        },
                        child: Image.asset(
                          'assets/images/caja/btn-regresar.png',
                          width: 120,
                          height: 40,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Imagen de historia con scroll horizontal
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.hardEdge,
                    child: Padding(
                      padding: EdgeInsets.only(left: 50),
                      child: Transform.translate(
                        offset: Offset(0, -50),
                        child: Image.asset(
                          'assets/images/caja/historia-oblatos.png',
                          height: 680,
                          fit: BoxFit.contain,
                        ),
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
                            // Detener audio antes de navegar
                            _stopHistoriaAudio();
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
                            // Detener audio antes de navegar
                            _stopHistoriaAudio();
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
                        // Etiqueta "Juego" - Movida 20px a la derecha
                        Transform.translate(
                          offset: Offset(20, 0), // Mover 20px a la derecha
                          child: SizedBox(
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
                        ),
                        SizedBox(width: 9),
                        // Etiqueta "Calculadora" - Movida 18px a la izquierda
                        Transform.translate(
                          offset: Offset(-18, 0), // Mover 18px a la izquierda
                          child: SizedBox(
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
