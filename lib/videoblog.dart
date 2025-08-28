import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'widgets/header_navigation.dart';
import 'widgets/bottom_navigation_menu.dart';
import 'package:audioplayers/audioplayers.dart';

class VideoBlogScreen extends StatefulWidget {
  @override
  _VideoBlogScreenState createState() => _VideoBlogScreenState();
}

class _VideoBlogScreenState extends State<VideoBlogScreen> with TickerProviderStateMixin {
  int _currentVideo = 0; // 0 = lista de videos, 1-5 = video específico
  bool _showVideoList = true; // Controla si mostrar la lista o el video
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  ScrollController _textScrollController = ScrollController();
  
  // Submenu state
  bool _isSubmenuVisible = false;
  late AnimationController _submenuAnimationController;
  late Animation<Offset> _submenuSlideAnimation;
  final AudioPlayer _beepPlayer = AudioPlayer();
  
  // Variables para animación de fade-in secuencial
  List<bool> _buttonVisible = List.generate(5, (index) => false);
  int _currentButtonIndex = 0;
  
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
    // Animar los botones de video secuencialmente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateButtonsSequentially();
    });
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _textScrollController.dispose();
    _submenuAnimationController.dispose();
    _beepPlayer.dispose();
    super.dispose();
  }
  
  void _toggleSubmenu() async {
    if (_isSubmenuVisible) {
      _submenuAnimationController.reverse().then((_) {
        if (mounted) {
          setState(() { _isSubmenuVisible = false; });
        }
      });
    } else {
      setState(() { _isSubmenuVisible = true; });
      _submenuAnimationController.forward();
      try { await _beepPlayer.play(AssetSource('audios/ding.mp3')); } catch (_) {}
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
            if (_isSubmenuVisible) _buildSubmenu(),

            // Menú inferior rojo reutilizable
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
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
                  return Icon(Icons.lightbulb, color: Colors.white, size: 24);
                },
              ),
            ),
          ),
        ],
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
                  _buildVideoButton(1, 'disco1.png', 'Cooperación en Acción'),
                  SizedBox(height: 20),
                  _buildVideoButton(2, 'disco1.png', 'Valores Cooperativos'),
                  SizedBox(height: 20),
                  _buildVideoButton(3, 'disco1.png', 'Trabajo en Equipo'),
                  SizedBox(height: 20),
                  _buildVideoButton(4, 'disco1.png', 'Liderazgo Compartido'),
                  SizedBox(height: 20),
                  _buildVideoButton(5, 'disco1.png', 'Comunidad Unida'),
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
        return 'Introducción a la Cooperación';
      case 2:
        return 'Principios Básicos';
      case 3:
        return 'Historia de Caja Oblatos';
      case 4:
        return 'Beneficios de la Cooperación';
      case 5:
        return 'Futuro de la Cooperación';
      default:
        return 'Video $videoIndex';
    }
  }

  String _getVideoBody(int videoIndex) {
    switch (videoIndex) {
      case 1:
        return 'En este primer episodio, exploramos los fundamentos de la cooperación y cómo Caja Oblatos ha sido pionera en este modelo económico. Descubriremos por qué la cooperación es más que una simple estrategia de negocio, sino una filosofía de vida que beneficia a toda la comunidad.\n\nLa cooperación se basa en principios de solidaridad, democracia y equidad, valores que han guiado a Caja Oblatos desde su fundación. A través de ejemplos prácticos y testimonios reales, entenderemos cómo estos principios se aplican en el día a día.';
      case 2:
        return 'Los principios básicos de la cooperación son la base sobre la cual se construye todo el sistema. En este episodio, profundizamos en cada uno de estos principios y cómo se manifiestan en las operaciones diarias de Caja Oblatos.\n\nDesde la adhesión voluntaria hasta la preocupación por la comunidad, cada principio tiene un propósito específico y contribuye al éxito del modelo cooperativo. Analizaremos casos de estudio y veremos cómo estos principios han evolucionado con el tiempo.';
      case 3:
        return 'La historia de Caja Oblatos es una historia de perseverancia, innovación y compromiso con la comunidad. Desde sus humildes comienzos hasta convertirse en una institución financiera líder, cada paso ha sido guiado por la visión de crear un futuro mejor para todos.\n\nExploraremos los momentos clave de esta trayectoria, los desafíos superados y las lecciones aprendidas. Esta historia no solo nos enseña sobre el pasado, sino que también ilumina el camino hacia el futuro.';
      case 4:
        return 'Los beneficios de la cooperación van más allá de los aspectos financieros. En este episodio, exploramos cómo la cooperación mejora la calidad de vida de las personas, fortalece las comunidades y crea un sistema económico más justo y sostenible.\n\nDesde mejores tasas de interés hasta programas de educación financiera, los beneficios son tangibles y duraderos. Veremos cómo estos beneficios se distribuyen equitativamente entre todos los miembros de la cooperativa.';
      case 5:
        return 'El futuro de la cooperación es brillante y lleno de posibilidades. En este episodio final, exploramos las tendencias emergentes, las nuevas tecnologías y las oportunidades que se presentan para el modelo cooperativo.\n\nDesde la digitalización hasta la expansión internacional, las cooperativas están evolucionando para enfrentar los desafíos del siglo XXI. Descubriremos cómo Caja Oblatos se está preparando para este futuro y qué significa para sus miembros.';
      default:
        return 'Contenido del video $videoIndex. Este es un texto de ejemplo que muestra cómo se verá el contenido con scroll cuando se implemente la funcionalidad completa.';
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
      
      // Navegar a la pantalla de video
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            chewieController: _chewieController!,
            videoTitle: 'Video $videoIndex',
          ),
        ),
      );
      
      // Cuando regreses, pausar y resetear el video
      if (result == 'video_closed') {
        _videoController?.pause();
        _videoController?.seekTo(Duration.zero);
      }
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
}

// Pantalla del reproductor de video
class VideoPlayerScreen extends StatefulWidget {
  final ChewieController chewieController;
  final String videoTitle;
  
  VideoPlayerScreen({
    required this.chewieController,
    required this.videoTitle,
  });
  
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Agregar listener para cuando se cierre la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Asegurar que el video se pause cuando se cierre la pantalla
      widget.chewieController.videoPlayerController.pause();
    });
  }
  
  @override
  void dispose() {
    // Pausar el video al cerrar la pantalla
    widget.chewieController.videoPlayerController.pause();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
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
        ),
      ),
    );
  }
}
