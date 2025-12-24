import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'widgets/header_navigation.dart';
import 'services/app_orientation_service.dart';
import 'services/snippet_service.dart';
import 'services/daily_challenge_service.dart';
import 'widgets/daily_challenge_overlay.dart';
import 'widgets/challenge_success_overlay.dart';
import 'user_manager.dart';

class VideoBlogScreen extends StatefulWidget {
  final int? initialVideo; // Video inicial a mostrar (1-5), null para mostrar lista
  
  const VideoBlogScreen({Key? key, this.initialVideo}) : super(key: key);
  
  @override
  _VideoBlogScreenState createState() => _VideoBlogScreenState();
}

class _VideoBlogScreenState extends State<VideoBlogScreen> with TickerProviderStateMixin {
  int _currentVideo = 0; // 0 = lista de videos, 1-5 = video específico
  bool _showVideoList = true; // Controla si mostrar la lista o el video
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  ScrollController _textScrollController = ScrollController();
  
  // Variables para animación de fade-in secuencial
  List<bool> _buttonVisible = List.generate(5, (index) => false);
  int _currentButtonIndex = 0;
  
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
    
    // Si hay un video inicial, configurarlo
    if (widget.initialVideo != null && widget.initialVideo! >= 1 && widget.initialVideo! <= 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Reproducir el video directamente
        _playVideo(widget.initialVideo!);
      });
    } else {
      // Animar los botones de video secuencialmente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateButtonsSequentially();
      });
    }
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _textScrollController.dispose();
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
  
  // Anima el scroll del texto para mostrar que se puede hacer scroll
  void _animateTextScroll() {
    if (_textScrollController.hasClients) {
      // Ir al final del texto
      _textScrollController.jumpTo(_textScrollController.position.maxScrollExtent);
      
      // Después de un breve delay, animar hacia el principio
      Future.delayed(Duration(milliseconds: 500), () {
        if (_textScrollController.hasClients) {
          _textScrollController.animateTo(
            0,
            duration: Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }
  
  // Anima los botones de video con fade-in secuencial
  void _animateButtonsSequentially() {
    _currentButtonIndex = 0;
    _buttonVisible = List.generate(5, (index) => false);
    
    void showNextButton() {
      if (_currentButtonIndex < 5) {
        setState(() {
          _buttonVisible[_currentButtonIndex] = true;
        });
        _currentButtonIndex++;
        
        // Mostrar el siguiente botón después de 200ms
        Future.delayed(Duration(milliseconds: 200), showNextButton);
      }
    }
    
    // Comenzar la secuencia
    showNextButton();
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
                    subtitle: 'VIDEO\nBLOG',
                  ),
                  
                  // Contenido específico de la pantalla
                  Expanded(
                    child: _buildVideoSystem(),
                  ),
                ],
              ),
            ),
            
            // Submenu (se muestra cuando se activa)
            if (_isSubmenuVisible) _buildVideoBlogSubmenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSystem() {
    return Stack(
      children: [
        // Lista de videos (se despliega desde la izquierda)
        AnimatedContainer(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(
            _showVideoList ? 0 : -MediaQuery.of(context).size.width,
            0,
            0,
          ),
          child: _buildVideoList(),
        ),
        
        // Fichas de video específicas (entran desde la derecha)
        for (int i = 1; i <= 5; i++)
          AnimatedContainer(
            duration: Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            transform: Matrix4.translationValues(
              (_currentVideo == i && !_showVideoList) ? 0 : MediaQuery.of(context).size.width,
              0,
              0,
            ),
            child: _buildVideoFicha(i),
          ),
      ],
    );
  }

  Widget _buildVideoList() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Título
          Text(
            'VIDEOS DISPONIBLES',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          
          // Lista de botones de video
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildVideoButton(1, 'disco1.png', '¡Tu alcancía mágica!'),
                  SizedBox(height: 20),
                  _buildVideoButton(2, 'disco1.png', 'Presupuesto ¡Fácil!'),
                  SizedBox(height: 20),
                  _buildVideoButton(3, 'disco1.png', 'Cambia hábitos ¡Ahorra mucho!'),
                  SizedBox(height: 20),
                  _buildVideoButton(4, 'disco1.png', '¡Alerta Online!'),
                  SizedBox(height: 20),
                  _buildVideoButton(5, 'disco1.png', 'Cuida tus recursos'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Botón individual de video con animación de fade-in
  Widget _buildVideoButton(int videoIndex, String discoImage, String title) {
    // Colores para cada botón con alpha 80%
    final List<Color> buttonColors = [
      Color(0xCCDB2EB0), // #DB2EB0 con alpha 80%
      Color(0xCCDB2E90), // #DB2E90 con alpha 80%
      Color(0xCCCA2EDB), // #CA2EDB con alpha 80%
      Color(0xCCDB24BA), // #DB24BA con alpha 80%
      Color(0xCCCD2EDB), // #CD2EDB con alpha 80%
    ];
    
    return AnimatedOpacity(
      opacity: _buttonVisible[videoIndex - 1] ? 1.0 : 0.0,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      child: Transform.translate(
        offset: Offset(0, _buttonVisible[videoIndex - 1] ? 0 : 30),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _currentVideo = videoIndex;
              _showVideoList = false;
            });
          },
          child: Container(
            width: 370,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: buttonColors[videoIndex - 1],
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Stack(
              children: [
                // Imagen del disco (lado izquierdo)
                Positioned(
                  left: 20,
                  top: 15,
                  child: Image.asset(
                    'assets/videos/$discoImage',
                    width: 60,
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.music_note, color: Colors.white, size: 30),
                      );
                    },
                  ),
                ),
                
                // Título del video alineado a la izquierda
                Positioned(
                  left: 100,
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1, // Interlineado reducido para mantener altura
                      ),
                      textAlign: TextAlign.left,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Ficha de video específica
  Widget _buildVideoFicha(int videoIndex) {
    return Container(
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
                      _showVideoList = true;
                      _currentVideo = 0;
                    });
                  },
                  child: Image.asset(
                    'assets/videos/btn-regresar.png',
                    width: 120,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
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
          
          // Ficha de video
          Expanded(
            child: Center(
              child: Stack(
                children: [
                  // base-video-XX.png (contenedor centrado, 5px arriba)
                  Positioned(
                    top: 5,
                    left: 0,
                    right: 0,
                    child: Stack(
                      children: [
                        // Imagen base del video
                        Center(
                          child: Image.asset(
                            'assets/videos/base-video-0$videoIndex.png',
                            width: 390,
                            height: 555,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 390,
                                height: 555,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Video $videoIndex',
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
                        
                        // Contenedor de texto con scroll
                        Positioned(
                          top: 230,
                          left: 45,
                          right: 45,
                          child: Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Fecha en rojo 12pts
                                  Text(
                                    _getVideoDate(videoIndex),
                                    style: TextStyle(
                                      fontFamily: 'Gotham Rounded',
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                      color: Color(0xFFE91E63),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  // Título del video 16pts bold
                                  Text(
                                    _getVideoTitle(videoIndex),
                                    style: TextStyle(
                                      fontFamily: 'Gotham Rounded',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  // Cuerpo del texto 16pts regular con scroll
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        SingleChildScrollView(
                                          controller: _textScrollController,
                                          child: Text(
                                            _getVideoBody(videoIndex),
                                            style: TextStyle(
                                              fontFamily: 'Gotham Rounded',
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black87,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                        // Efecto de desvanecido en la parte inferior
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.white.withOpacity(0.0),
                                                  Colors.white.withOpacity(1.0),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // GestureDetector para reproducir video
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => _playVideo(videoIndex),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Métodos para obtener información del video
  String _getVideoDate(int videoIndex) {
    switch (videoIndex) {
      case 1:
        return '15 de Marzo, 2024';
      case 2:
        return '22 de Marzo, 2024';
      case 3:
        return '29 de Marzo, 2024';
      case 4:
        return '5 de Abril, 2024';
      case 5:
        return '12 de Abril, 2024';
      default:
        return 'Fecha por definir';
    }
  }

  String _getVideoTitle(int videoIndex) {
    switch (videoIndex) {
      case 1:
        return '¡Tu alcancía mágica!';
      case 2:
        return 'Presupuesto ¡Fácil!';
      case 3:
        return 'Cambia hábitos ¡Ahorra mucho!';
      case 4:
        return '¡Alerta Online!';
      case 5:
        return 'Cuida tus recursos';
      default:
        return 'Video $videoIndex';
    }
  }

  String _getVideoBody(int videoIndex) {
    switch (videoIndex) {
      case 1:
        return 'En este primer video "¡Tu Alcancía Mágica!" te llevamos a descubrir que el ahorro puede ser emocionante, sencillo y hasta mágico. A través de un personaje divertido —Anty— aprenderás que cada moneda que guardas es un paso hacia cumplir tus sueños. ¿Quieres unos tenis nuevos, ese videojuego que tanto esperas o un libro increíble? Tu alcancía puede ser la llave para conseguirlo.\n\nEste video no solo explica el concepto de ahorrar, también lo transforma en una aventura divertida, llena de emoción y motivación. Descubrirás que tu alcancía es como un superhéroe financiero que guarda tu dinero y te acerca cada día más a lo que quieres.';
      case 2:
        return 'En este segundo capítulo "El Mapa de tu Dinero: ¡Presupuesto Fácil!" descubrirás una herramienta que te hará sentir en control total: el presupuesto. Con la ayuda de Anty aprenderás que tu dinero no "desaparece", sino que viaja por distintos caminos… y tú puedes decidir hacia dónde va.\n\nEste video te mostrará que un presupuesto no es complicado ni aburrido, sino un superpoder para manejar tu dinero con inteligencia. Aprenderás a usar una libreta, una app o lo que prefieras para anotar tus ingresos y gastos, y así estar siempre preparado.';
      case 3:
        return 'En este episodio "¡Cambia Hábitos, Ahorra Mucho!" descubrirás que no necesitas hacer grandes sacrificios para tener más dinero, solo basta con pequeños cambios en tu día a día. Anty te mostrará cómo esas decisiones simples, como llevar tu propio termo en lugar de comprar botellas o preparar un snack en casa, pueden convertirse en grandes ahorros al final del mes.\n\nEste video transforma la idea del ahorro en un juego divertido donde cada acción cuenta y cada hábito suma. Aprenderás que ser constante con estos pequeños cambios te da más control, más dinero y más posibilidades de cumplir lo que te propones.';
      case 4:
        return 'En el capítulo "¡Alerta, Falsas Promesas Online!" aprenderás a detectar las trampas digitales más comunes y protegerte de los engaños que circulan en Internet. Anty te guiará con ejemplos claros de esas ofertas que parecen increíbles, pero en realidad son un fraude: desde ganar dinero en minutos hasta conseguir celulares o videojuegos gratis.\n\nTambién descubrirás la importancia de compartir cualquier duda con un adulto de confianza: papás, tíos o maestros, quienes pueden ayudarte a confirmar si algo es real o un intento de estafa.';
      case 5:
        return 'En el episodio "¡Practica el uso y administración de recursos!" descubrirás que los videojuegos no solo sirven para divertirse, también pueden enseñarte a manejar tu dinero y tus decisiones financieras. Anty te mostrará cómo los juegos de simulación —desde construir tu propia ciudad en SimCity, hasta crear mundos y economías en Roblox o administrar recursos en Minecraft— son una herramienta increíble para aprender jugando.';
      default:
        return 'Contenido del video $videoIndex. Este es un texto de ejemplo que muestra cómo se verá el contenido con scroll cuando se implemente la funcionalidad completa.';
    }
  }

  // Listener para detectar cuando el video termine
  void _videoListener() {
    if (_videoController != null && 
        _videoController!.value.position >= _videoController!.value.duration &&
        _videoController!.value.duration > Duration.zero) {
      // El video terminó completamente
      _onVideoCompleted(_currentVideo);
    }
  }
  
  // Manejar cuando un video se completa
  Future<void> _onVideoCompleted(int videoIndex) async {
    try {
      final challengeService = DailyChallengeService();
      final challenge = await challengeService.getTodayChallenge();
      
      if (challenge == null || challenge.type != ChallengeType.video) {
        return; // No hay reto de video hoy
      }
      
      // Verificar si ya se completó
      final isCompleted = await challengeService.isChallengeCompleted();
      if (isCompleted) {
        return; // Ya se completó
      }
      
      // Verificar si el video completado coincide con el reto
      final videoId = 'video_$videoIndex';
      if (challenge.videoId == videoId) {
        // ¡Reto completado!
        await challengeService.completeChallenge();
        final userManager = Provider.of<UserManager>(context, listen: false);
        
        // Llamar al PHP para registrar la completación
        try {
          final user = userManager.currentUser;
          if (user != null && user['id'] != null) {
            final response = await http.post(
              Uri.parse('https://zumuradigital.com/app-oblatos-login/complete_daily_challenge.php'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'user_id': user['id'],
                'challenge_type': 'video',
                'challenge_data': {
                  'video_id': videoId,
                },
              }),
            );
            print('🎯 Respuesta complete_daily_challenge: ${response.statusCode} - ${response.body}');
            
            if (response.statusCode == 200) {
              final responseData = jsonDecode(response.body);
              if (responseData['success'] == true && responseData['racha_points_total'] != null) {
                userManager.updateRachaPoints(int.tryParse(responseData['racha_points_total'].toString()) ?? 0);
              }
            }
          }
        } catch (e) {
          print('❌ Error registrando completación de reto: $e');
        }
        
        userManager.completarRetoDiario();
        
        // Mostrar ventana de éxito
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return ChallengeSuccessOverlay(
                onClose: () {
                  Navigator.of(context).pop();
                },
              );
            },
          );
        }
      }
    } catch (e) {
      print('Error verificando reto diario de video: $e');
    }
  }
  
  // Reproduce el video
  void _playVideo(int videoIndex) async {
    // Cambiar al video seleccionado
    setState(() {
      _currentVideo = videoIndex;
      _showVideoList = false;
    });
    
    // Animar el scroll del texto después de que se muestre la ficha
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateTextScroll();
    });
    
    try {
      // Liberar controladores anteriores
      _videoController?.dispose();
      _chewieController?.dispose();
      
      // Crear nuevo controlador
      _videoController = VideoPlayerController.asset(
        'assets/videos/video$videoIndex-videoblog.mp4',
      );
      
      await _videoController!.initialize();
      
      // Agregar listener para detectar cuando el video termine
      _videoController!.addListener(_videoListener);
      
      // Crear controlador de Chewie
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Color(0xFFE91E63),
          handleColor: Color(0xFFE91E63),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white,
        ),
      );
      
      // Pausar snippets mientras se reproduce el video
      try {
        SnippetService().setGameOrCalculatorActive(true);
        print('🛑 Snippets pausados durante reproducción de video');
      } catch (_) {}

      // Permitir landscape mientras se reproduce el video
      AppOrientationService().setAllowLandscape(true);

      // Navegar a la pantalla de video
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            chewieController: _chewieController!,
            videoTitle: 'Video $videoIndex',
            videoIndex: videoIndex,
            onVideoCompleted: () => _onVideoCompleted(videoIndex),
          ),
        ),
      );
      
      // Cuando regreses, pausar y resetear el video
      if (result == 'video_closed') {
        _videoController?.removeListener(_videoListener);
        _videoController?.pause();
        _videoController?.seekTo(Duration.zero);
      }

      // Reanudar snippets y bloquear landscape al cerrar el video
      try {
        SnippetService().setGameOrCalculatorActive(false);
        print('▶️ Snippets reanudados después de video');
      } catch (_) {}
      AppOrientationService().setAllowLandscape(false);
    } catch (e) {
      print('Error reproduciendo video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reproducir el video'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildVideoBlogSubmenu() {
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
                  'Herramientas de Video Blog',
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
                          onTap: () { 
                            Navigator.pushNamed(context, '/juego');
                          },
                          child: Image.asset('assets/images/submenu/btn-juego.png', height: 156),
                        ),
                        SizedBox(width: 9),
                        GestureDetector(
                          onTap: () { 
                            Navigator.pushNamed(context, '/calculadora');
                          },
                          child: Image.asset('assets/images/submenu/btn-calculadora.png', height: 150),
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
                            child: Text('Juego', style: TextStyle(fontFamily: 'GothamRounded', fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                          ),
                        ),
                        SizedBox(width: 9),
                        Transform.translate(
                          offset: Offset(-18, 0), // Mover 18px a la izquierda
                          child: SizedBox(
                            width: 150,
                            child: Text('Calculadora', style: TextStyle(fontFamily: 'GothamRounded', fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
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

// Pantalla del reproductor de video
class VideoPlayerScreen extends StatefulWidget {
  final ChewieController chewieController;
  final String videoTitle;
  final int videoIndex;
  final VoidCallback? onVideoCompleted;
  
  VideoPlayerScreen({
    required this.chewieController,
    required this.videoTitle,
    required this.videoIndex,
    this.onVideoCompleted,
  });
  
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _wasLandscape = false;

  @override
  void initState() {
    super.initState();
    // Agregar listener para cuando se cierre la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Asegurar que el video se pause cuando se cierre la pantalla
      widget.chewieController.videoPlayerController.pause();
    });
    
    // Agregar listener para detectar cuando el video termine
    widget.chewieController.videoPlayerController.addListener(_videoListener);
    
    // Pausar snippets al entrar al reproductor por seguridad
    try { SnippetService().setGameOrCalculatorActive(true); } catch (_) {}
    // Permitir landscape en reproductor
    AppOrientationService().setAllowLandscape(true);
  }
  
  void _videoListener() {
    final controller = widget.chewieController.videoPlayerController;
    if (controller.value.position >= controller.value.duration &&
        controller.value.duration > Duration.zero &&
        !controller.value.isPlaying) {
      // El video terminó completamente
      if (widget.onVideoCompleted != null) {
        widget.onVideoCompleted!();
      }
    }
  }
  
  @override
  void dispose() {
    // Remover listener
    widget.chewieController.videoPlayerController.removeListener(_videoListener);
    // Pausar el video al cerrar la pantalla
    widget.chewieController.videoPlayerController.pause();
    // Reanudar snippets al salir del reproductor
    try { SnippetService().setGameOrCalculatorActive(false); } catch (_) {}
    // Bloquear landscape al salir
    AppOrientationService().setAllowLandscape(false);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final bool isLandscape = orientation == Orientation.landscape;
            if (isLandscape && !_wasLandscape) {
              // Entrar a fullscreen al rotar a horizontal
              Future.delayed(Duration(milliseconds: 100), () {
                try { widget.chewieController.enterFullScreen(); } catch (_) {}
              });
              _wasLandscape = true;
            } else if (!isLandscape && _wasLandscape) {
              // Salir de fullscreen al volver a vertical
              Future.delayed(Duration(milliseconds: 100), () {
                try { widget.chewieController.exitFullScreen(); } catch (_) {}
              });
              _wasLandscape = false;
            }
            return Column(
              children: [
            // Header con botón regresar
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Pausar el video antes de regresar
                      widget.chewieController.videoPlayerController.pause();
                      Navigator.pop(context, 'video_closed');
                    },
                    child: Image.asset(
                      'assets/videos/btn-regresar.png',
                      width: 120,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) {
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
                  SizedBox(width: 20),
                  Text(
                    widget.videoTitle,
                    style: TextStyle(
                      fontFamily: 'Gotham Rounded',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Reproductor de video
            Expanded(
              child: Center(
                child: Chewie(controller: widget.chewieController),
              ),
            ),
              ],
            );
          },
        ),
      ),
    );
  }
}
