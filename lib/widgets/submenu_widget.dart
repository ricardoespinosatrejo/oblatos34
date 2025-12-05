import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class SubmenuWidget extends StatefulWidget {
  const SubmenuWidget({Key? key}) : super(key: key);

  @override
  State<SubmenuWidget> createState() => _SubmenuWidgetState();
}

class _SubmenuWidgetState extends State<SubmenuWidget> with TickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _submenuAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
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
      
      // Reproducir audio beep2.mp3
      try {
        await _audioPlayer.play(AssetSource('audios/ding.mp3'));
      } catch (e) {
        print('Error reproduciendo audio: $e');
      }
    }
  }

  void _navigateToGame() {
    // TODO: Navegar al juego
    print('Navegar al juego');
  }

  void _navigateToCalculator() {
    // TODO: Navegar a la calculadora
    print('Navegar a la calculadora');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Botón central para activar el submenu
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.translate(
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
                        child: Icon(
                          Icons.home,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Submenu (se muestra cuando se activa)
        if (_isSubmenuVisible) _buildSubmenu(),
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
                          onTap: _navigateToGame,
                          child: Image.asset(
                            'assets/images/submenu/btn-juego.png',
                            height: 156,
                          ),
                        ),
                        SizedBox(width: 9),
                        GestureDetector(
                          onTap: _navigateToCalculator,
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
                        // Etiqueta "Juego" - Movida 10px a la derecha con Transform
                        Transform.translate(
                          offset: Offset(10, 0), // Mover 10px a la derecha
                          child: SizedBox(
                            width: 156,
                            child: Text(
                              'JUEGO MOVIDO',
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
                        // Etiqueta "Calculadora" - Con padding derecho para moverla a la izquierda
                        Container(
                          width: 150,
                          padding: EdgeInsets.only(right: 30), // Padding derecho grande
                          child: Text(
                            'CALCULADORA',
                            style: TextStyle(
                              fontFamily: 'GothamRounded',
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right, // Cambiado a right para que se vea el efecto
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
