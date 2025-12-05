import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../user_manager.dart';

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
  
  const DailyChallengeOverlay({
    Key? key,
    required this.onClose,
    required this.challenge,
    this.onChallengeAccepted,
    this.onOptionSelected,
  }) : super(key: key);

  @override
  _DailyChallengeOverlayState createState() => _DailyChallengeOverlayState();
}

class _DailyChallengeOverlayState extends State<DailyChallengeOverlay>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedOption;
  
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
  
  void _selectOption(int optionId) {
    print('🎯 _selectOption llamado con optionId: $optionId');
    setState(() {
      _selectedOption = optionId;
    });
    
    if (widget.onOptionSelected != null) {
      print('🎯 Llamando onOptionSelected con optionId: $optionId');
      widget.onOptionSelected!(optionId);
    } else {
      print('⚠️ onOptionSelected es null!');
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final userManager = Provider.of<UserManager>(context);
    final rachaDias = userManager.rachaDias;
    
    // Obtener la ruta de la imagen de la ventana
    final windowImagePath = 'assets/images/rachacoop/racha-window/${widget.challenge.windowImage}';
    
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
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
                    width: double.infinity,
                    height: double.infinity,
                    child: Stack(
                      children: [
                        // Fondo de snippets a pantalla completa (igual que en snippets)
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/snippets/Snippets-back.jpg',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
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
                                                
                                                // Días consecutivos
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
                                                        widget.challenge.description,
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
                                                
                                                // Botón de aceptar - Bloquear propagación de toques
                                                if (widget.challenge.type != ChallengeType.trivia)
                                                  GestureDetector(
                                                    onTap: () {
                                                      print('🎯 Botón Aceptar Reto presionado');
                                                      _acceptChallenge();
                                                    },
                                                    behavior: HitTestBehavior.opaque, // Bloquear propagación
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () {
                                                          print('🎯 InkWell onTap');
                                                          _acceptChallenge();
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
                                                            child: Text(
                                                              '¡Aceptar Reto!',
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
                // Botones de opciones FUERA del GestureDetector principal para que reciban toques
                if (widget.challenge.type == ChallengeType.trivia && 
                    (widget.challenge.triviaOptions != null || widget.challenge.options != null))
                  Positioned(
                    bottom: 140, // Aumentado de 40 a 140 píxeles (subir 100 píxeles)
                    left: 0,
                    right: 0,
                    child: AbsorbPointer(
                      absorbing: false, // Permitir toques en los botones
                      child: Column(
                      children: (widget.challenge.triviaOptions ?? 
                        widget.challenge.options!.asMap().entries.map((entry) => TriviaOption(
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
                                final optionId = widget.challenge.triviaOptions != null
                                  ? widget.challenge.triviaOptions![index].id
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
                                  color: _selectedOption == (widget.challenge.triviaOptions != null
                                    ? widget.challenge.triviaOptions![index].id
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
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
