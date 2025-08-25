import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'widgets/header_navigation.dart';

class AprendiendoCooperativaScreen extends StatefulWidget {
  @override
  _AprendiendoCooperativaScreenState createState() => _AprendiendoCooperativaScreenState();
}

class _AprendiendoCooperativaScreenState extends State<AprendiendoCooperativaScreen> {
  int _currentFicha = 0; // 0 = ficha 1, 1 = ficha 2, 2 = ficha 3
  bool _showFoto = false; // Controla la animación de la foto
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  @override
  void initState() {
    super.initState();
    
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
            SafeArea(
              child: Column(
                children: [
                  // Header de navegación reutilizable
                  HeaderNavigation(
                    onMenuTap: () {
                      Navigator.pushReplacementNamed(context, '/menu');
                    },
                    title: 'BIENVENIDOS',
                    subtitle: 'APRENDIENDO LA\nMANERA COOPERATIVA',
                  ),
                  
                  // Contenido específico de la pantalla
                  Expanded(
                    child: _buildFichasSystem(),
                  ),
                ],
              ),
            ),
            
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
    );
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

  // Construye una ficha completa con todas sus capas
  Widget _buildFichaCompleta(int fichaIndex) {
    return Center(
      child: Stack(
        children: [
          // base01-fondo (z-index 2) - Fondo base
          Positioned(
            left: 23,
            top: 30,
            child: Container(
              width: 393,
              height: 646,
              child: Image.asset(
                'assets/images/aprendiendo/base0${fichaIndex}-fondo.png',
                width: 393,
                height: 646,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 393,
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
             left: 23,
             top: 30,
             child: Container(
               width: 393,
               height: 646,
               child: Align(
                 alignment: Alignment.bottomCenter,
                                    child: Transform.translate(
                     offset: Offset(0, 50),
                     child: Image.asset(
                       'assets/images/aprendiendo/base0${fichaIndex}.png',
                       width: 393,
                       height: 646,
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
            right: 23,
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
