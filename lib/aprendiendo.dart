import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'widgets/header_navigation.dart';

class AprendiendoCooperativaScreen extends StatefulWidget {
  @override
  _AprendiendoCooperativaScreenState createState() => _AprendiendoCooperativaScreenState();
}

class _AprendiendoCooperativaScreenState extends State<AprendiendoCooperativaScreen> with TickerProviderStateMixin {
  int _currentFicha = 0; // 0 = ficha 1, 1 = ficha 2, 2 = ficha 3
  bool _showFoto = false; // Controla la animación de la foto
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Submenu state
  bool _isSubmenuVisible = false;
  late AnimationController _submenuAnimationController;
  late Animation<Offset> _submenuSlideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar animación del submenu
    _submenuAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _submenuSlideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _submenuAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Activa la animación inicial de la foto
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _showFoto = true;
      });
    });
    
    // Reproduce el sonido inicial del primer slide
    Future.delayed(Duration(milliseconds: 800), () {
      _playHitSound();
    });
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    _submenuAnimationController.dispose();
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
                      title: 'SECCIÓN',
                      subtitle: 'APRENDIENDO LA\nMANERA COOPERATIVA',
                      leftPadding: 15,
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
          ],
        ),
      ),
    );
  }

  void _toggleSubmenu() async {
    if (_isSubmenuVisible) {
      _submenuAnimationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isSubmenuVisible = false;
          });
        }
      });
    } else {
      setState(() {
        _isSubmenuVisible = true;
      });
      _submenuAnimationController.forward();

      try {
        await _audioPlayer.play(AssetSource('audios/ding.mp3'));
      } catch (e) {
        print('Error reproduciendo audio: $e');
      }
    }
  }
  
  // Reproduce el sonido de cambio de ficha
  void _playHitSound() async {
    try {
      await _audioPlayer.play(AssetSource('audios/hit.mp3'));
    } catch (e) {
      print('Error reproduciendo sonido: $e');
    }
  }
  
  // Activa la animación de la foto cuando cambia la ficha
  void _activateFotoAnimation() {
    setState(() {
      _showFoto = false; // Reinicia la animación
    });
    
    // Reproduce el sonido
    _playHitSound();
    
    // Después de un breve delay, activa la animación
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _showFoto = true;
      });
    });
  }
  
  // Métodos helper para obtener las medidas específicas de cada foto
  double _getFotoWidth(int fichaIndex) {
    switch (fichaIndex) {
      case 1:
        return 170.0;
      case 2:
        return 180.0;
      case 3:
        return 180.0;
      default:
        return 180.0;
    }
  }
  
  double _getFotoHeight(int fichaIndex) {
    switch (fichaIndex) {
      case 1:
        return 189.0;
      case 2:
        return 199.0;
      case 3:
        return 198.0;
      default:
        return 199.0;
    }
  }

  // Sistema de fichas en capas con z-index
  Widget _buildFichasSystem() {
    return Stack(
      children: [
        // Ficha 1
        AnimatedContainer(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(
            _currentFicha == 0 ? 0 : -MediaQuery.of(context).size.width,
            0,
            0,
          ),
          child: _buildFichaCompleta(1),
        ),
        
        // Ficha 2
        AnimatedContainer(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(
            _currentFicha == 1 ? 0 : MediaQuery.of(context).size.width,
            0,
            0,
          ),
          child: _buildFichaCompleta(2),
        ),
        
        // Ficha 3
        AnimatedContainer(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(
            _currentFicha == 2 ? 0 : MediaQuery.of(context).size.width,
            0,
            0,
          ),
          child: _buildFichaCompleta(3),
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
                            print('Navegar al juego');
                          },
                          child: Image.asset(
                            'assets/images/submenu/btn-juego.png',
                            height: 156,
                          ),
                        ),
                        SizedBox(width: 9),
                        GestureDetector(
                          onTap: () {
                            print('Navegar a la calculadora');
                          },
                          child: Image.asset(
                            'assets/images/submenu/btn-calculadora.png',
                            height: 150,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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

  // Construye una ficha completa con todas sus capas
  Widget _buildFichaCompleta(int fichaIndex) {
    return Center(
      child: Stack(
        children: [
          // base01-fondo (z-index 2) - Fondo base
          Positioned(
            left: 20, // Reducido de 23
            top: 30,
            child: Container(
              width: MediaQuery.of(context).size.width - 40, // Responsive en lugar de 393 fijo
              height: 646,
              child: Image.asset(
                'assets/images/aprendiendo/base0${fichaIndex}-fondo.png',
                width: MediaQuery.of(context).size.width - 40, // Responsive
                height: 646,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: MediaQuery.of(context).size.width - 40, // Responsive
                    height: 646,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Fondo $fichaIndex',
                        style: TextStyle(
                          fontFamily: 'Gotham Rounded',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
                     // foto01 (z-index 3) - Foto pegada arriba, en el borde superior con animación
           Positioned(
             left: 23,
             top: 30,
             child: Container(
               width: 393,
               height: 646,
               child: Align(
                 alignment: Alignment.topCenter,
                 child: AnimatedContainer(
                   duration: Duration(milliseconds: 1200),
                   curve: Curves.easeOutCubic,
                   transform: Matrix4.translationValues(
                     0,
                     _showFoto ? 0 : 200, // 200 píxeles abajo cuando no está animada
                     0,
                   ),
                                        child: Image.asset(
                       'assets/images/aprendiendo/foto0${fichaIndex}.png',
                       width: _getFotoWidth(fichaIndex),
                       height: _getFotoHeight(fichaIndex),
                       fit: BoxFit.contain,
                       errorBuilder: (context, error, stackTrace) {
                         return Container(
                           width: 393,
                           height: 646,
                           decoration: BoxDecoration(
                             color: Colors.transparent,
                           ),
                           child: Center(
                             child: Text(
                               'Foto $fichaIndex',
                               style: TextStyle(
                                 fontFamily: 'Gotham Rounded',
                                 fontSize: 24,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.black87,
                               ),
                             ),
                           ),
                         );
                       },
                     ),
                   ),
              ),
            ),
          ),
          
                     // base01 (z-index 4) - Contenido principal, 50 píxeles arriba del bottom
           Positioned(
             left: 20, // Reducido de 23
             top: 30,
             child: Container(
               width: MediaQuery.of(context).size.width - 40, // Responsive en lugar de 393 fijo
               height: 646,
               child: Align(
                 alignment: Alignment.bottomCenter,
                                    child: Transform.translate(
                     offset: Offset(0, 50),
                     child: Image.asset(
                       'assets/images/aprendiendo/base0${fichaIndex}.png',
                       width: MediaQuery.of(context).size.width - 40, // Responsive
                       height: 646,
                       fit: BoxFit.contain,
                       errorBuilder: (context, error, stackTrace) {
                         return Container(
                           width: MediaQuery.of(context).size.width - 40, // Responsive
                           height: 646,
                           decoration: BoxDecoration(
                             color: Colors.transparent,
                           ),
                           child: Center(
                             child: Text(
                               'Base $fichaIndex',
                               style: TextStyle(
                                 fontFamily: 'Gotham Rounded',
                                 fontSize: 24,
                                 fontWeight: FontWeight.bold,
                                 color: Colors.black87,
                               ),
                             ),
                           ),
                         );
                       },
                     ),
                   ),
                 ),
            ),
          ),
          
          // mas-info (z-index 5) - Botón pegado al margen derecho
          Positioned(
            right: 20, // Reducido de 23
            top: 30,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  // Rotación cíclica: 1 -> 2 -> 3 -> 1
                  _currentFicha = (_currentFicha + 1) % 3;
                });
                // Activa la animación de la foto
                _activateFotoAnimation();
              },
              child: Image.asset(
                'assets/images/aprendiendo/mas-info.png',
                width: 56, // 80 * 0.7 = 56 (30% más pequeño)
                height: 56, // 80 * 0.7 = 56 (30% más pequeño)
                errorBuilder: (context, error, stackTrace) {
                                     return Container(
                     width: 56, // 30% más pequeño
                     height: 56, // 30% más pequeño
                     decoration: BoxDecoration(
                       color: Color(0xFFE91E63),
                       shape: BoxShape.circle,
                     ),
                     child: Center(
                       child: Icon(
                         Icons.info,
                         color: Colors.white,
                         size: 28, // 40 * 0.7 = 28 (30% más pequeño)
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
}
