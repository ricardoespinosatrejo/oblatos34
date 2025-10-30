import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:math';
import '../user_manager.dart';

class SnippetOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onEarlyClose; // Callback cuando se cierra antes del tiempo
  final String snippetImage;
  final int snippetId;
  
  const SnippetOverlay({
    Key? key,
    required this.onClose,
    this.onEarlyClose,
    required this.snippetImage,
    required this.snippetId,
  }) : super(key: key);

  @override
  _SnippetOverlayState createState() => _SnippetOverlayState();
}

class _SnippetOverlayState extends State<SnippetOverlay> 
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _countdownController;
  late AnimationController _backgroundFadeController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundFadeAnimation;
  
  int _countdown = 10;
  bool _showPoints = false;
  bool _isClosing = false;
  bool _completedCountdown = false; // Para saber si se completó el contador
  
  // Lista de snippets disponibles (1-12)
  final List<String> _snippets = [
    'snippet-01.png',
    'snippet-02.png',
    'snippet-03.png',
    'snippet-04.png',
    'snippet-05.png',
    'snippet-06.png',
    'snippet-07.png',
    'snippet-08.png',
    'snippet-09.png',
    'snippet-10.png',
    'snippet-11.png',
    'snippet-12.png',
  ];
  
  String _currentSnippet = '';
  
  @override
  void initState() {
    super.initState();
    
    // Seleccionar snippet aleatorio
    _currentSnippet = _snippets[Random().nextInt(_snippets.length)];
    
    // Configurar animaciones
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _countdownController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    );
    
    _backgroundFadeController = AnimationController(
      duration: Duration(milliseconds: 800),
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
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _backgroundFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundFadeController,
      curve: Curves.easeInOut,
    ));
    
    // Iniciar animaciones
    _fadeController.forward();
    _scaleController.forward();
    _backgroundFadeController.forward();
    
    // Iniciar countdown
    _startCountdown();
  }
  
  void _startCountdown() {
    _countdownController.forward();
    
    // Actualizar countdown cada segundo
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (mounted && !_isClosing) {
        setState(() {
          _countdown--;
        });
        
        if (_countdown <= 0) {
          _completedCountdown = true;
          _showPointsMessage();
          return false;
        }
      }
      return _countdown > 0 && !_isClosing;
    });
  }
  
  void _showPointsMessage() async {
    setState(() {
      _showPoints = true;
    });
    
    // Reproducir sonido de puntos
    try {
      final audioPlayer = AudioPlayer();
      await audioPlayer.play(AssetSource('audios/ding.mp3'));
      await Future.delayed(Duration(milliseconds: 200));
      audioPlayer.dispose();
    } catch (e) {
      print('Error reproduciendo audio: $e');
    }
    
    // Solo enviar puntos si se completó el contador
    if (_completedCountdown) {
      await _addPointsToDatabase();
    }
    
    // NO cerrar automáticamente - esperar a que el usuario haga click
    // El snippet se queda hasta que el usuario lo cierre manualmente
  }
  
  Future<void> _addPointsToDatabase() async {
    try {
      // Obtener el user_id del UserManager
      final userManager = Provider.of<UserManager>(context, listen: false);
      final user = userManager.currentUser;
      final userId = user?['id']?.toString();
      
      if (userId == null || userId == '0') {
        print('❌ No se puede otorgar puntos: usuario no logueado o user_id inválido (${user?['id']})');
        return;
      }
      
      print('🎯 Otorgando puntos de snippet para user_id: $userId');
      
      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/add_snippet_points.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'points': 10,
          'snippet_id': _currentSnippet,
        }),
      );
      
      print('🎯 Respuesta snippet: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          print('✅ Puntos de snippet agregados exitosamente: ${responseData['total_points']} puntos totales');
          // Actualizar los puntos en el UserManager
          userManager.updateUserPoints(responseData['total_points']);
        } else {
          print('❌ Error al agregar puntos de snippet: ${responseData['error']}');
        }
      } else {
        print('❌ Error HTTP agregando puntos de snippet: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la petición: $e');
    }
  }
  
  void _closeOverlay() async {
    if (_isClosing) return;
    
    print('🎯 SnippetOverlay: Cerrando overlay');
    setState(() {
      _isClosing = true;
    });
    
    // Si se cierra antes del tiempo, llamar al callback de cierre temprano
    if (!_completedCountdown && widget.onEarlyClose != null) {
      widget.onEarlyClose!();
    }
    
    // Animación de salida más rápida
    await _fadeController.reverse();
    await _scaleController.reverse();
    await _backgroundFadeController.reverse();
    
    print('🎯 SnippetOverlay: Overlay cerrado completamente');
    widget.onClose();
  }
  
  void _closeOnImageTap() {
    _closeOverlay();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _countdownController.dispose();
    _backgroundFadeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
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
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Fondo del snippet con fade-in
                            AnimatedBuilder(
                              animation: _backgroundFadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _backgroundFadeAnimation.value,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(0),
                                    child: Image.asset(
                                      'assets/images/snippets/Snippets-back.jpg',
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            // Snippet principal centrado y clickeable - Solo 1px de margen
                            Center(
                              child: GestureDetector(
                                onTap: _closeOnImageTap,
                                child: Container(
                                  width: MediaQuery.of(context).size.width - 2, // 1px de cada lado
                                  height: MediaQuery.of(context).size.height * 0.6,
                                  child: Image.asset(
                                    'assets/images/snippets/${widget.snippetImage}',
                                    fit: BoxFit.contain, // Cambiar a contain para que no se corte
                                  ),
                                ),
                              ),
                            ),
                            
                            // Contador o mensaje de puntos - Subido 100px más arriba
                            Positioned(
                              bottom: 150,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _showPoints
                                    ? Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 30,
                                          vertical: 15,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF4CAF50),
                                          borderRadius: BorderRadius.circular(25),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '¡Ganaste 10 puntos!',
                                          style: TextStyle(
                                            fontFamily: 'Gotham Rounded',
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '$_countdown',
                                          style: TextStyle(
                                            fontFamily: 'Gotham Rounded',
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            
                            // Botón de cerrar eliminado - Solo se cierra haciendo click en la imagen
                          ],
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
