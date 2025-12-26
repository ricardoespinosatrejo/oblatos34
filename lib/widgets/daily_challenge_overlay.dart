import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../user_manager.dart';
import '../utils/challenge_helper.dart';
import '../services/daily_challenge_service.dart';

/// Tipo de reto diario
enum ChallengeType {
  coins,      // Jugar y ganar monedas
  video,      // Ver video completo
  trivia,     // Responder trivia
}

/// Modelo de opción de trivia
class TriviaOption {
  final int id;
  final String texto;
  final int orden;
  
  TriviaOption({
    required this.id,
    required this.texto,
    required this.orden,
  });
}

/// Modelo de reto diario
class DailyChallenge {
  final ChallengeType type;
  final String title;
  final String description;
  final int? targetValue; // Para monedas: cantidad objetivo
  final String? videoId;  // Para videos: ID del video
  final int? triviaId;    // Para trivias: ID de la trivia
  final String windowImage; // Imagen de la ventana (racha-window-01.png, etc)
  final List<String>? options; // Opciones para trivia (texto) - DEPRECATED, usar triviaOptions
  final List<TriviaOption>? triviaOptions; // Opciones para trivia con IDs
  
  DailyChallenge({
    required this.type,
    required this.title,
    required this.description,
    this.targetValue,
    this.videoId,
    this.triviaId,
    required this.windowImage,
    this.options,
    this.triviaOptions,
  });
}

class DailyChallengeOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final DailyChallenge challenge;
  final VoidCallback? onChallengeAccepted;
  final Function(int)? onOptionSelected; // Para trivias: callback con el índice de la opción seleccionada
  final BuildContext? parentContext; // Contexto del padre para usar después de cerrar
  final int? initialRespuestaCorrectaId; // Para trivias de recuperación: respuesta correcta ya conocida
  
  const DailyChallengeOverlay({
    Key? key,
    required this.onClose,
    required this.challenge,
    this.onChallengeAccepted,
    this.onOptionSelected,
    this.parentContext,
    this.initialRespuestaCorrectaId,
  }) : super(key: key);

  @override
  _DailyChallengeOverlayState createState() => _DailyChallengeOverlayState();
}

class _DailyChallengeOverlayState extends State<DailyChallengeOverlay>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _contentFadeController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _contentFadeAnimation;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedOption;
  DailyChallenge? _loadedTriviaChallenge; // Challenge con las opciones cargadas
  int? _respuestaCorrectaId; // ID de la respuesta correcta
  bool _isLoadingTrivia = false;
  
  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 300),
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
      curve: Curves.easeOutBack,
    ));
    
    // Controlador para fade in del contenido de trivia
    _contentFadeController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentFadeController,
      curve: Curves.easeInOut,
    ));
    
    // Si el challenge ya tiene opciones cargadas (trivia de recuperación), usarlas directamente
    if (widget.challenge.type == ChallengeType.trivia && 
        widget.challenge.triviaOptions != null && 
        widget.challenge.triviaOptions!.isNotEmpty) {
      _loadedTriviaChallenge = widget.challenge;
      _respuestaCorrectaId = widget.initialRespuestaCorrectaId;
      // Iniciar animación de fade in del contenido inmediatamente
      Future.delayed(Duration(milliseconds: 200), () {
        _contentFadeController.forward();
      });
    }
    
    // Iniciar animaciones
    Future.delayed(Duration(milliseconds: 200), () {
      _fadeController.forward();
      _scaleController.forward();
    });
    
    // Reproducir sonido de la ventana
    _playWindowSound();
  }
  
  Future<void> _playWindowSound() async {
    try {
      await _audioPlayer.play(AssetSource('images/rachacoop/racha-window/win.mp3'));
    } catch (e) {
      print('Error reproduciendo sonido de ventana: $e');
    }
  }
  
  void _closeOverlay() {
    if (!mounted) return;
    
    // Cerrar inmediatamente sin animación para mejor UX
    // No usar animación reverse para que sea instantáneo
    widget.onClose();
  }
  
  void _acceptChallenge() {
    print('🎯 _acceptChallenge llamado');
    
    // Detener el audio inmediatamente (sin await para no bloquear)
    _audioPlayer.stop().catchError((e) {
      print('❌ Error deteniendo audio: $e');
    });
    
    // Cerrar el overlay inmediatamente
    _closeOverlay();
    
    // Marcar el reto como aceptado de forma asíncrona (sin bloquear)
    SharedPreferences.getInstance().then((prefs) {
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      prefs.setString('daily_challenge_last_shown', todayKey);
      prefs.setBool('daily_challenge_accepted', true); // Marcar como aceptado
      print('✅ Reto marcado como aceptado');
    }).catchError((e) {
      print('❌ Error marcando reto como aceptado: $e');
    });
    
    if (widget.onChallengeAccepted != null) {
      widget.onChallengeAccepted!();
    }
  }
  
  Future<void> _selectOption(int optionId) async {
    print('🎯 _selectOption llamado con optionId: $optionId');
    setState(() {
      _selectedOption = optionId;
    });
    
    // Procesar la respuesta ANTES de cerrar (para mantener el contexto válido)
    if (_loadedTriviaChallenge != null && _loadedTriviaChallenge!.triviaId != null) {
      final userManager = Provider.of<UserManager>(context, listen: false);
      final challengeService = DailyChallengeService();
      
      // Obtener el contexto a usar después de cerrar el overlay
      BuildContext? contextToUse = widget.parentContext;
      
      // Si no hay contexto padre, intentar obtener el del Navigator root
      if (contextToUse == null) {
        try {
          final navigator = Navigator.maybeOf(context, rootNavigator: true);
          if (navigator != null) {
            contextToUse = navigator.context;
          }
        } catch (e) {
          print('⚠️ No se pudo obtener contexto del Navigator root: $e');
        }
      }
      
      // Cerrar el overlay primero
      if (mounted) {
        _closeOverlay();
      }
      
      // Esperar un poco para que el overlay se cierre
      await Future.delayed(Duration(milliseconds: 300));
      
      // Procesar la respuesta usando el contexto obtenido
      if (contextToUse != null && contextToUse.mounted) {
        await ChallengeHelper.processTriviaAnswer(
          contextToUse,
          userManager,
          _loadedTriviaChallenge!.triviaId!,
          optionId,
          _respuestaCorrectaId,
          challengeService,
        );
      } else {
        print('❌ No se pudo obtener contexto válido para procesar respuesta');
      }
    } else if (widget.onOptionSelected != null) {
      print('🎯 Llamando onOptionSelected con optionId: $optionId');
      _closeOverlay();
      widget.onOptionSelected!(optionId);
    } else {
      print('⚠️ onOptionSelected es null!');
      _closeOverlay();
    }
  }
  
  Future<void> _loadTriviaOptions() async {
    if (_isLoadingTrivia || _loadedTriviaChallenge != null) {
      return; // Ya se está cargando o ya está cargado
    }
    
    setState(() {
      _isLoadingTrivia = true;
    });
    
    try {
      final userManager = Provider.of<UserManager>(context, listen: false);
      final triviaData = await ChallengeHelper.loadTriviaChallenge(
        widget.challenge,
        userManager,
      );
      
      if (triviaData != null && mounted) {
        setState(() {
          _loadedTriviaChallenge = triviaData.challenge;
          _respuestaCorrectaId = triviaData.respuestaCorrectaId;
          _isLoadingTrivia = false;
        });
        // Iniciar animación de fade in del contenido
        _contentFadeController.forward();
      } else {
        if (mounted) {
          setState(() {
            _isLoadingTrivia = false;
          });
          // Mostrar error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar la trivia'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error cargando trivia: $e');
      if (mounted) {
        setState(() {
          _isLoadingTrivia = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar la trivia'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _contentFadeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final userManager = Provider.of<UserManager>(context);
    final rachaDias = userManager.rachaDias;
    
    // Usar el challenge cargado si está disponible, sino el original
    final currentChallenge = _loadedTriviaChallenge ?? widget.challenge;
    
    // Obtener la ruta de la imagen de la ventana (ya viene completa desde el servicio)
    final windowImagePath = currentChallenge.windowImage;
    
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: screenSize.width,
              height: screenSize.height,
              margin: EdgeInsets.zero, // Sin márgenes
              child: Stack(
                children: [
                  // Fondo con GestureDetector para cerrar (permitir cerrar trivia también)
                  GestureDetector(
                    onTap: () {
                      // Permitir cerrar siempre (incluyendo trivia)
                      _closeOverlay();
                    },
                    behavior: HitTestBehavior.translucent, // Permitir que los toques pasen a los botones
                    child: Container(
                      width: screenSize.width,
                      height: screenSize.height,
                      margin: EdgeInsets.only(
                        top: -padding.top, // Extender hacia arriba
                        bottom: -padding.bottom, // Extender hacia abajo
                      ),
                      child: Stack(
                        children: [
                          // Fondo de snippets a pantalla completa (ocupando toda la pantalla incluyendo SafeArea)
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/snippets/Snippets-back.jpg',
                              width: screenSize.width,
                              height: screenSize.height + padding.top + padding.bottom,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                        
                        // Contenido del overlay
                        Stack(
                          children: [
                            // Ventana con imagen de fondo (racha-window-01.png a racha-window-05.png)
                            Transform.translate(
                              offset: Offset(0, -80), // Subir la imagen 80 píxeles
                              child: Align(
                                alignment: Alignment.center,
                                child: AnimatedBuilder(
                                  animation: _scaleAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _scaleAnimation.value,
                                      child: ClipRect(
                                        clipBehavior: Clip.none, // Permitir que el contenido se desborde
                                        child: Stack(
                                          clipBehavior: Clip.none, // Permitir desbordamiento
                                          children: [
                                            // Imagen de fondo con altura proporcional
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width, // 100% del ancho, sin márgenes
                                              child: Image.asset(
                                                windowImagePath,
                                                width: MediaQuery.of(context).size.width,
                                                fit: BoxFit.fitWidth, // Ajusta la altura proporcionalmente al ancho
                                              ),
                                            ),
                                            // Contenido dentro de la ventana
                                            Positioned.fill(
                                              child: OverflowBox(
                                                maxHeight: double.infinity, // Permitir que el contenido se extienda más allá
                                                child: Padding(
                                                  padding: EdgeInsets.all(30),
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                SizedBox(height: 130), // Espacio para bajar todo el contenido de texto (80 + 50)
                                                // Título "CUMPLE EL RETO"
                                                Text(
                                                  'CUMPLE EL RETO',
                                                  style: TextStyle(
                                                    fontFamily: 'Gotham Rounded',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFD14EED), // #D14EED
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                SizedBox(height: 5), // Reducido de 15 a 5 para acercar más el título a los días
                                                
                                                // Verificar si es trivia de recuperación
                                                Builder(
                                                  builder: (context) {
                                                    final isRecoveryTrivia = widget.challenge.title == 'RECUPERA TU RACHA';
                                                    
                                                    if (isRecoveryTrivia) {
                                                      // Mostrar "RECUPERA TU RACHA" para trivia de recuperación
                                                      return Text(
                                                        'RECUPERA TU RACHA',
                                                        style: TextStyle(
                                                          fontFamily: 'Gotham Rounded',
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF6F6E6E), // #6F6E6E
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      );
                                                    } else {
                                                      // Mostrar días consecutivos normal
                                                      return Column(
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                                            textBaseline: TextBaseline.alphabetic,
                                                            children: [
                                                              Text(
                                                                '$rachaDias',
                                                                style: TextStyle(
                                                                  fontFamily: 'Gotham Rounded',
                                                                  fontSize: 18,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Color(0xFF6F6E6E), // #6F6E6E
                                                                ),
                                                              ),
                                                              SizedBox(width: 8),
                                                              Text(
                                                                'días',
                                                                style: TextStyle(
                                                                  fontFamily: 'Gotham Rounded',
                                                                  fontSize: 18,
                                                                  fontWeight: FontWeight.w500,
                                                                  color: Color(0xFF6F6E6E), // #6F6E6E
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Transform.translate(
                                                            offset: Offset(0, -8), // Acercar "consecutivos" 8 píxeles hacia arriba
                                                            child: Text(
                                                              'consecutivos',
                                                              style: TextStyle(
                                                                fontFamily: 'Gotham Rounded',
                                                                fontSize: 18,
                                                                color: Color(0xFF6F6E6E), // #6F6E6E
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(height: 15), // Reducido de 30 a 15 para juntar más el texto
                                                
                                                // Sección Objetivo
                                                Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 40), // Aumentado de 20 a 40 píxeles
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Objetivo',
                                                        style: TextStyle(
                                                          fontFamily: 'Gotham Rounded',
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF706F6F), // #706F6F
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        currentChallenge.description,
                                                        style: TextStyle(
                                                          fontFamily: 'Gotham Rounded',
                                                          fontSize: 13,
                                                          color: Color(0xFF6E88A8), // #6E88A8
                                                          height: 1.5,
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'Obtienes +2 puntos al abrir la app y +10 puntos al completar el reto.',
                                                        style: TextStyle(
                                                          fontFamily: 'Gotham Rounded',
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF01A39B), // #01a39b
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                SizedBox(height: 210), // Espacio aumentado para bajar el botón 80px
                                                
                                                // Espacio para el botón (se renderizará fuera del GestureDetector)
                                                SizedBox(height: 60),
                                                      ],
                                                    ),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón de aceptar/ver trivia FUERA del GestureDetector principal para que reciba toques
                if (currentChallenge.type != ChallengeType.trivia || 
                    (currentChallenge.triviaOptions == null && currentChallenge.options == null && !_isLoadingTrivia))
                  Positioned(
                    bottom: 140,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            print('🎯 Botón ${currentChallenge.type == ChallengeType.trivia ? "Ver Trivia" : "Aceptar Reto"} presionado (fuera del GestureDetector)');
                            if (currentChallenge.type == ChallengeType.trivia) {
                              // Para trivias, cargar las opciones en el mismo overlay
                              print('🎯 Es trivia, cargando opciones...');
                              _loadTriviaOptions();
                            } else {
                              _acceptChallenge();
                            }
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFFE91E63), // Rosa vibrante
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoadingTrivia
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      currentChallenge.type == ChallengeType.trivia 
                                          ? '¡Ver Trivia!' 
                                          : '¡Aceptar Reto!',
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
                      ),
                    ),
                  ),
                // Botones de opciones FUERA del GestureDetector principal para que reciban toques
                if (currentChallenge.type == ChallengeType.trivia && 
                    (currentChallenge.triviaOptions != null || currentChallenge.options != null))
                  Positioned(
                    bottom: 140, // Aumentado de 40 a 140 píxeles (subir 100 píxeles)
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _contentFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _contentFadeAnimation.value,
                          child: AbsorbPointer(
                            absorbing: false, // Permitir toques en los botones
                            child: Column(
                            children: (currentChallenge.triviaOptions ?? 
                              currentChallenge.options!.asMap().entries.map((entry) => TriviaOption(
                                id: entry.key,
                                texto: entry.value,
                                orden: entry.key,
                              )).toList()).asMap().entries.map((entry) {
                              final index = entry.key;
                              final triviaOption = entry.value;
                              final option = triviaOption.texto;
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      print('🎯 Botón de opción presionado, índice: $index');
                                      // Si es TriviaOption, usar el ID real, sino usar el índice
                                      final optionId = currentChallenge.triviaOptions != null
                                        ? currentChallenge.triviaOptions![index].id
                                        : index;
                                      print('🎯 optionId calculado: $optionId');
                                      _selectOption(optionId);
                                    },
                                    borderRadius: BorderRadius.circular(15),
                                    // Prevenir que el tap se propague al GestureDetector del fondo
                                    splashColor: Colors.white.withOpacity(0.2),
                                    highlightColor: Colors.white.withOpacity(0.1),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: _selectedOption == (currentChallenge.triviaOptions != null
                                          ? currentChallenge.triviaOptions![index].id
                                          : index)
                                            ? Color(0xFFE91E63).withOpacity(0.8)
                                            : Color(0xFFE91E63), // Rosa vibrante
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                        child: Center(
                                          child: Text(
                                            option,
                                            style: TextStyle(
                                              fontFamily: 'Gotham Rounded',
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
