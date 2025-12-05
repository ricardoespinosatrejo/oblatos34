import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class ChallengeFailedOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onRecoverTrivia; // Callback para iniciar trivia de recuperación
  
  const ChallengeFailedOverlay({
    Key? key,
    required this.onClose,
    required this.onRecoverTrivia,
  }) : super(key: key);

  @override
  _ChallengeFailedOverlayState createState() => _ChallengeFailedOverlayState();
}

class _ChallengeFailedOverlayState extends State<ChallengeFailedOverlay>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _shakeController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _shakeAnimation;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
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
      curve: Curves.easeOutBack,
    ));
    
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: Offset(-10, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(-10, 0), end: Offset(10, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(10, 0), end: Offset(-10, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(-10, 0), end: Offset(10, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(10, 0), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
    
    // Iniciar animaciones
    _fadeController.forward();
    _scaleController.forward();
    _shakeController.forward();
    
    // Reproducir sonido de error
    _playErrorSound();
  }
  
  Future<void> _playErrorSound() async {
    try {
      await _audioPlayer.play(AssetSource('images/rachacoop/racha-window/error.mp3'));
    } catch (e) {
      print('Error reproduciendo sonido de error: $e');
    }
  }
  
  void _closeOverlay() {
    if (!mounted) return;
    
    // Detener el audio al cerrar
    _audioPlayer.stop();
    
    _fadeController.reverse().then((_) {
      if (mounted) {
        widget.onClose();
      }
    });
  }
  
  void _startRecoveryTrivia() {
    widget.onRecoverTrivia();
    _closeOverlay();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _shakeController.dispose();
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
            child: Container(
              width: double.infinity,
              height: double.infinity,
              // Fondo transparente (sin fondo negro)
              color: Colors.transparent,
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_scaleAnimation, _shakeAnimation]),
                  builder: (context, child) {
                    return SlideTransition(
                      position: _shakeAnimation,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: screenSize.width * 0.85,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Panel superior con gradiente
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF2C2C2C), // Primer color
                                      Color(0xFF707070), // Segundo color
                                    ],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(25),
                                    topRight: Radius.circular(25),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Estrella verde (star3.png) en la parte superior
                                    Image.asset(
                                      'assets/images/rachacoop/star3.png',
                                      width: 80,
                                      height: 80,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.star,
                                          color: Color(0xFF4ECDC4),
                                          size: 80,
                                        );
                                      },
                                    ),
                                    
                                    SizedBox(height: 20),
                                    
                                    // Texto "NOOOOOOO"
                                    Text(
                                      'NOOOOOOO',
                                      style: TextStyle(
                                        fontFamily: 'Gotham Rounded',
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4ECDC4), // Verde vibrante
                                      ),
                                    ),
                                    
                                    SizedBox(height: 20),
                                    
                                    // Texto "¡NO CUMPLISTE EL RETO!"
                                    Text(
                                      '¡NO CUMPLISTE EL RETO!',
                                      style: TextStyle(
                                        fontFamily: 'Gotham Rounded',
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                    SizedBox(height: 20),
                                    
                                    // Texto informativo
                                    Text(
                                      'Mucha suerte para la próxima trivia',
                                      style: TextStyle(
                                        fontFamily: 'Gotham Rounded',
                                        fontSize: 16,
                                        color: Color(0xFF44A3F7), // Azul claro
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                    SizedBox(height: 30),
                                    
                                    // Estrella amarilla (star5.png) en la parte inferior del panel
                                    Image.asset(
                                      'assets/images/rachacoop/star5.png',
                                      width: 60,
                                      height: 60,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.star,
                                          color: Color(0xFFFFD700),
                                          size: 60,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Botón "¡LISTO!" amarillo brillante
                              GestureDetector(
                                onTap: _startRecoveryTrivia,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFD700), // Amarillo brillante
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(25),
                                      bottomRight: Radius.circular(25),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '¡LISTO!',
                                      style: TextStyle(
                                        fontFamily: 'Gotham Rounded',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


