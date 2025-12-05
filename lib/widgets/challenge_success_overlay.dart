import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

class ChallengeSuccessOverlay extends StatefulWidget {
  final VoidCallback onClose;
  
  const ChallengeSuccessOverlay({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  _ChallengeSuccessOverlayState createState() => _ChallengeSuccessOverlayState();
}

class _ChallengeSuccessOverlayState extends State<ChallengeSuccessOverlay>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Offset> _confettiPositions = [];
  
  @override
  void initState() {
    super.initState();
    
    // Generar posiciones aleatorias para confetti
    final random = Random();
    for (int i = 0; i < 20; i++) {
      _confettiPositions.add(Offset(
        random.nextDouble() * 400,
        random.nextDouble() * 600,
      ));
    }
    
    // Configurar animaciones
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Iniciar animaciones
    _fadeController.forward();
    _scaleController.forward();
    
    // Reproducir sonido de éxito
    _playSuccessSound();
    
    // Cerrar automáticamente después de 3 segundos
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        _closeOverlay();
      }
    });
  }
  
  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('images/rachacoop/racha-window/win.mp3'));
    } catch (e) {
      print('Error reproduciendo sonido de éxito: $e');
    }
  }
  
  void _closeOverlay() {
    if (!mounted) return;
    
    _fadeController.reverse().then((_) {
      if (mounted) {
        widget.onClose();
      }
    });
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: GestureDetector(
              onTap: _closeOverlay, // Cerrar al tocar cualquier parte
              child: Container(
                width: double.infinity,
                height: double.infinity,
                // Sin fondo - solo la ventana
                color: Colors.transparent,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: screenSize.width * 0.85,
                          height: screenSize.height * 0.6,
                          decoration: BoxDecoration(
                            // Gradiente rosa/fucsia (de rosa brillante arriba a magenta abajo)
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFF00FF), // Rosa brillante/fucsia
                                Color(0xFFD14EED), // Magenta
                              ],
                            ),
                            borderRadius: BorderRadius.circular(40), // Squircle
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 30,
                                offset: Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Confetti decorativo usando las imágenes
                              Positioned(
                                top: 20,
                                left: 20,
                                child: Image.asset(
                                  'assets/images/rachacoop/confetti-1.png',
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                              Positioned(
                                top: 40,
                                right: 30,
                                child: Image.asset(
                                  'assets/images/rachacoop/confetti-2.png',
                                  width: 25,
                                  height: 25,
                                ),
                              ),
                              Positioned(
                                bottom: 60,
                                left: 30,
                                child: Image.asset(
                                  'assets/images/rachacoop/confetti-3.png',
                                  width: 28,
                                  height: 28,
                                ),
                              ),
                              Positioned(
                                bottom: 80,
                                right: 40,
                                child: Image.asset(
                                  'assets/images/rachacoop/confetti-4.png',
                                  width: 22,
                                  height: 22,
                                ),
                              ),
                              Positioned(
                                top: 100,
                                left: screenSize.width * 0.2,
                                child: Image.asset(
                                  'assets/images/rachacoop/confetti-5.png',
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              
                              // Contenido principal
                              Padding(
                                padding: EdgeInsets.all(40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Texto "FELICIDADES" en verde claro
                                    Text(
                                      'FELICIDADES',
                                      style: TextStyle(
                                        fontFamily: 'Gotham Rounded',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4ECDC4), // Verde claro
                                      ),
                                    ),
                                    
                                    SizedBox(height: 15),
                                    
                                    // Texto "¡CUMPLISTE EL RETO!" en blanco grande
                                    Text(
                                      '¡CUMPLISTE\nEL RETO!',
                                      style: TextStyle(
                                        fontFamily: 'Gotham Rounded',
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                    SizedBox(height: 30),
                                    
                                    // Icono de notificación rojo con estrella
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFE53E3E), // Rojo brillante
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    ),
                                    
                                    SizedBox(height: 30),
                                    
                                    // Estrellas amarillas decorativas
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/rachacoop/star.png',
                                          width: 50,
                                          height: 50,
                                        ),
                                        SizedBox(width: 15),
                                        Image.asset(
                                          'assets/images/rachacoop/star2.png',
                                          width: 40,
                                          height: 40,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Cintas decorativas (ribbons) - usando contenedores con gradientes
                              Positioned(
                                top: -10,
                                left: 20,
                                child: Transform.rotate(
                                  angle: -0.3,
                                  child: Container(
                                    width: 120,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFFFEB3B), // Amarillo
                                          Color(0xFFFFC107), // Amarillo oscuro
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 20,
                                right: 30,
                                child: Transform.rotate(
                                  angle: 0.3,
                                  child: Container(
                                    width: 100,
                                    height: 25,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFE91E63), // Rosa
                                          Color(0xFFC2185B), // Rosa oscuro
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 40,
                                left: 30,
                                child: Transform.rotate(
                                  angle: -0.2,
                                  child: Container(
                                    width: 110,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF4ECDC4), // Azul claro
                                          Color(0xFF26A69A), // Azul oscuro
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
}


