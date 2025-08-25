import 'package:flutter/material.dart';
import 'widgets/header_navigation.dart';

class PoderCooperacionScreen extends StatefulWidget {
  @override
  _PoderCooperacionScreenState createState() => _PoderCooperacionScreenState();
}

class _PoderCooperacionScreenState extends State<PoderCooperacionScreen> {
  int _currentFicha = 0; // 0 = ficha base, 1-9 = fichas específicas
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Programar la animación del scroll después de que se construya el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateScrollToTop();
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
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
                    subtitle: 'EL CORAZÓN DE\nCAJA OBLATOS',
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
          left: 23,
          top: 30,
          child: Container(
            width: 393,
            height: 580,
            decoration: BoxDecoration(
              image: DecorationImage(
                                  image: AssetImage('assets/images/poder/base-ficha.png'),
                fit: BoxFit.cover,
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
}
