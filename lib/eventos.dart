import 'package:flutter/material.dart';
import 'widgets/header_navigation.dart';
import 'widgets/bottom_navigation_menu.dart';
import 'package:audioplayers/audioplayers.dart';

class EventosScreen extends StatefulWidget {
  @override
  _EventosScreenState createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> with TickerProviderStateMixin {
  // Submenu state
  bool _isSubmenuVisible = false;
  late AnimationController _submenuAnimationController;
  late Animation<Offset> _submenuSlideAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _submenuAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
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
                      Navigator.pushReplacementNamed(context, '/menu');
                    },
                    title: 'BIENVENIDOS',
                    subtitle: 'EVENTOS Y\nCAMPAÑAS',
                  ),
                  
                  // Contenido específico de la pantalla de eventos y campañas
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icono de eventos
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2196F3), // Azul para eventos
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.event,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                          
                          SizedBox(height: 30),
                          
                          // Título de la pantalla
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'EVENTOS Y\n',
                                  style: TextStyle(
                                    fontFamily: 'Gryzensa',
                                    fontSize: 42,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    height: 0.8,
                                  ),
                                ),
                                TextSpan(
                                  text: 'CAMPAÑAS',
                                  style: TextStyle(
                                    fontFamily: 'Gryzensa',
                                    fontSize: 42,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    height: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: 20),
                          
                          // Descripción
                          Container(
                            width: 300,
                            child: Text(
                              'Participa en eventos emocionantes y campañas que promueven la cooperación y el cambio social positivo en tu comunidad.',
                              style: TextStyle(
                                fontFamily: 'Gotham Rounded',
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          SizedBox(height: 40),
                          
                          // Botón de acción
                          Container(
                            width: 280,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                // Acción del botón
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Text(
                                'VER EVENTOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
            ),
            
            // Submenu (se muestra cuando se activa)
            if (_isSubmenuVisible) _buildSubmenu(),
            
            // Menú inferior reutilizable
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: BottomNavigationMenu(onCenterTap: _toggleSubmenu),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmenu() {
    return Positioned(
      bottom: -10,
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
                child: Image.asset('assets/images/submenu/moneda2.png', width: 30, height: 130),
              ),
              Positioned(
                top: 58,
                right: 10,
                child: Image.asset('assets/images/submenu/moneda1.png', width: 46, height: 47),
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
                          onTap: () { print('Navegar al juego'); },
                          child: Image.asset('assets/images/submenu/btn-juego.png', height: 156),
                        ),
                        SizedBox(width: 9),
                        GestureDetector(
                          onTap: () { print('Navegar a la calculadora'); },
                          child: Image.asset('assets/images/submenu/btn-calculadora.png', height: 150),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 156,
                          child: Text('Juego', style: TextStyle(fontFamily: 'GothamRounded', fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        ),
                        SizedBox(width: 9),
                        SizedBox(
                          width: 150,
                          child: Text('Calculadora', style: TextStyle(fontFamily: 'GothamRounded', fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
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
