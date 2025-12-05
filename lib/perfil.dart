import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_manager.dart';
import 'widgets/header_navigation.dart';
import 'inicio.dart';
import 'services/snippet_service.dart';

class PerfilScreen extends StatefulWidget {
  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _profileImageAudioPlayer = AudioPlayer();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _nombrePadreController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // FocusNodes para controlar el teclado
  final FocusNode _nombreFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _telefonoFocusNode = FocusNode();
  final FocusNode _nombrePadreFocusNode = FocusNode();

  bool _isEditing = false;
  int _selectedProfileImage = 1; // 1, 2, o 3
  int _mesesEnNivel5 = 0; // Meses consecutivos en nivel 5
  DateTime? _fechaPrimerNivel5; // Fecha en que alcanzó nivel 5 por primera vez
  
  // Modo debug: cambia a false cuando termines las pruebas
  static const bool DEBUG_UNLOCK_ALL_PROFILES = false; // Cambiar a false en producción

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSkinUnlockData();
    
    // Hacer que el scroll comience abajo y suba con animación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Ir directamente al final del scroll (sin animación)
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        
        // Después de 800ms, subir suavemente hacia arriba
        Future.delayed(Duration(milliseconds: 800), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: Duration(milliseconds: 1500),
              curve: Curves.easeInOutCubic,
            );
          }
        });
      }
    });
    
    // Escuchar cambios en el teclado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Scroll automático cuando aparece el teclado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && MediaQuery.of(context).viewInsets.bottom > 0) {
            Future.delayed(Duration(milliseconds: 300), () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _profileImageAudioPlayer.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _nombrePadreController.dispose();
    _scrollController.dispose();
    
    // Dispose de los FocusNodes
    _nombreFocusNode.dispose();
    _emailFocusNode.dispose();
    _telefonoFocusNode.dispose();
    _nombrePadreFocusNode.dispose();
    
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userManager = Provider.of<UserManager>(context, listen: false);
    final user = userManager.currentUser;

    if (user != null) {
      _nombreController.text = user['nombre_menor'] ?? '';
      _emailController.text = user['email'] ?? '';
      _telefonoController.text = user['telefono'] ?? '';
      _nombrePadreController.text = user['nombre_padre_madre'] ?? '';
      _selectedProfileImage = user['profile_image'] ?? 1;
      
      // Actualizar sesión diaria automáticamente al cargar el perfil
      await _updateSesionDiaria(userManager);
      await userManager.refreshAppPoints();
      await userManager.refreshGamePoints();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _updateSesionDiaria(UserManager userManager) async {
    try {
      final user = userManager.currentUser;
      if (user == null || user['id'] == null) return;

      // Llamar al backend para actualizar sesión diaria
      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/update_points.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user['id'],
          'action': 'sesion_diaria'
        }),
      );

      if (response.statusCode == 200) {
        await userManager.refreshAppPoints();
        print('✅ Sesión diaria sincronizada con backend');
      }
    } catch (e) {
      print('❌ Error actualizando sesión diaria: $e');
    }
  }

  void _toggleEdit() async {
    setState(() {
      _isEditing = !_isEditing;
    });

    if (_isEditing) {
      // Reproducir audio al entrar en modo edición
      try {
        await _audioPlayer.play(AssetSource('audios/ding.mp3'));
      } catch (_) {}
    }
  }

  void _saveChanges() async {
    try {
      final userManager = Provider.of<UserManager>(context, listen: false);
      final user = userManager.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Usuario no encontrado'),
            backgroundColor: Color(0xFFF44336),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Preparar datos para enviar al servidor
      final updateData = {
        'user_id': user['id'],
        'nombre_menor': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'nombre_padre_madre': _nombrePadreController.text.trim(),
        'profile_image': _selectedProfileImage,
      };

      // Enviar datos al servidor PHP
      final response = await http.post(
        Uri.parse(
          'https://zumuradigital.com/app-oblatos-login/update_profile.php',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          // Actualizar datos locales
          final updatedUser = Map<String, dynamic>.from(user);
          updatedUser['nombre_menor'] = updateData['nombre_menor'];
          updatedUser['email'] = updateData['email'];
          updatedUser['telefono'] = updateData['telefono'];
          updatedUser['nombre_padre_madre'] = updateData['nombre_padre_madre'];
          updatedUser['profile_image'] = updateData['profile_image'];

          userManager.setCurrentUser(updatedUser);

          // Reproducir audio de éxito
          try {
            await _audioPlayer.play(AssetSource('audios/ding.mp3'));
          } catch (_) {}

          setState(() {
            _isEditing = false;
          });

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cambios guardados exitosamente'),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception(responseData['message'] ?? 'Error al guardar');
        }
      } else {
        throw Exception('Error de conexión: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al guardar cambios: $e');

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${e.toString()}'),
          backgroundColor: Color(0xFFF44336),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    _loadUserData(); // Restaurar datos originales
  }

  void _selectProfileImage(int imageNumber) async {
    print('Seleccionando imagen de perfil: $imageNumber'); // Debug

    setState(() {
      _selectedProfileImage = imageNumber;
    });

    // Actualizar la imagen en UserManager para que se refleje en el header
    final userManager = Provider.of<UserManager>(context, listen: false);
    userManager.updateProfileImage(imageNumber);

    // Reproducir audio al cambiar imagen
    try {
      print('Intentando reproducir beep2.mp3...'); // Debug
      // Usar el AudioPlayer principal para mayor confiabilidad
      await _audioPlayer.play(AssetSource('audios/beep2.mp3'));
      print('Audio reproducido exitosamente'); // Debug
    } catch (e) {
      print('Error reproduciendo audio: $e');
    }
  }

  Widget _buildProfileImageSelector(int imageNumber, int rachaPoints) {
    final isUnlocked = _isProfileUnlocked(imageNumber, rachaPoints);
    final isSelected = _selectedProfileImage == imageNumber;
    final requiredMonths = _getRequiredMonths(imageNumber);

    return GestureDetector(
      onTap: isUnlocked ? () => _selectProfileImage(imageNumber) : () {
        // Mostrar mensaje si no está desbloqueado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              imageNumber == 1 
                ? 'Este perfil está disponible'
                : 'Necesitas alcanzar Nivel 5 y mantenerlo ${requiredMonths > 0 ? requiredMonths : ""} ${requiredMonths == 1 ? "mes" : requiredMonths > 1 ? "meses" : ""} para desbloquear este perfil',
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 14,
              ),
            ),
            backgroundColor: Color(0xFF9C27B0),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 7),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Color(0xFF5CF49D)
                      : (isUnlocked ? Colors.grey.shade400 : Colors.grey.shade600),
                  width: isSelected ? 5 : 3,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  _getProfileImagePathForSelector(imageNumber, isUnlocked),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 4),
            // Mostrar requisito
            Text(
              imageNumber == 1 
                ? 'Disponible' 
                : isUnlocked 
                  ? 'Nivel 5' 
                  : 'Nivel 5',
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isUnlocked ? Color(0xFF9C27B0) : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getProfileImagePath(int imageNumber) {
    return 'assets/images/perfil/perfil$imageNumber.png';
  }

  // Obtener meses requeridos para cada perfil (después de alcanzar nivel 5)
  int _getRequiredMonths(int imageNumber) {
    switch (imageNumber) {
      case 1:
        return 0; // Siempre activo
      case 2:
        return 0; // Se libera al alcanzar nivel 5 por primera vez
      case 3:
        return 1; // 1 mes en nivel 5
      case 4:
        return 2; // 2 meses en nivel 5
      case 5:
        return 3; // 3 meses en nivel 5
      case 6:
        return 4; // 4 meses en nivel 5
      default:
        return 0;
    }
  }

  // Verificar si un perfil está desbloqueado basado en nivel 5 y meses consecutivos
  bool _isProfileUnlocked(int imageNumber, int rachaPoints) {
    // En modo debug, todos los perfiles están desbloqueados
    if (DEBUG_UNLOCK_ALL_PROFILES) {
      return true;
    }
    
    // Perfil 1 siempre está disponible
    if (imageNumber == 1) {
      return true;
    }
    
    // Verificar si está en nivel 5 (2001+ racha_points)
    final isLevel5 = rachaPoints >= 2001;
    if (!isLevel5) {
      return false;
    }
    
    // Verificar meses requeridos
    final requiredMonths = _getRequiredMonths(imageNumber);
    return _mesesEnNivel5 >= requiredMonths;
  }
  
  // Cargar datos de desbloqueo de skins desde SharedPreferences
  Future<void> _loadSkinUnlockData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mesesEnNivel5 = prefs.getInt('meses_en_nivel5') ?? 0;
      final fechaPrimerNivel5Str = prefs.getString('fecha_primer_nivel5');
      
      setState(() {
        _mesesEnNivel5 = mesesEnNivel5;
        if (fechaPrimerNivel5Str != null) {
          _fechaPrimerNivel5 = DateTime.parse(fechaPrimerNivel5Str);
        }
      });
      
      // Verificar y actualizar meses en nivel 5
      _checkAndUpdateMesesEnNivel5();
    } catch (e) {
      print('Error cargando datos de skins: $e');
    }
  }
  
  // Verificar y actualizar meses consecutivos en nivel 5
  Future<void> _checkAndUpdateMesesEnNivel5() async {
    try {
      final userManager = Provider.of<UserManager>(context, listen: false);
      final rachaPoints = userManager.rachaPoints;
      final isLevel5 = rachaPoints >= 2001;
      
      final prefs = await SharedPreferences.getInstance();
      final ultimaVerificacionStr = prefs.getString('ultima_verificacion_nivel5');
      final ultimaVerificacion = ultimaVerificacionStr != null 
          ? DateTime.parse(ultimaVerificacionStr) 
          : null;
      final ahora = DateTime.now();
      
      // Verificar solo una vez al día
      if (ultimaVerificacion != null) {
        final diasDesdeUltimaVerificacion = ahora.difference(ultimaVerificacion).inDays;
        if (diasDesdeUltimaVerificacion < 1) {
          return; // Ya se verificó hoy
        }
      }
      
      // Guardar fecha de última verificación
      await prefs.setString('ultima_verificacion_nivel5', ahora.toIso8601String());
      
      if (!isLevel5) {
        // Si no está en nivel 5, resetear contador
        await prefs.setInt('meses_en_nivel5', 0);
        await prefs.remove('fecha_primer_nivel5');
        setState(() {
          _mesesEnNivel5 = 0;
          _fechaPrimerNivel5 = null;
        });
        return;
      }
      
      // Si está en nivel 5, verificar meses
      if (_fechaPrimerNivel5 == null) {
        // Primera vez que alcanza nivel 5
        await prefs.setString('fecha_primer_nivel5', ahora.toIso8601String());
        await prefs.setInt('meses_en_nivel5', 0);
        setState(() {
          _fechaPrimerNivel5 = ahora;
          _mesesEnNivel5 = 0;
        });
        return;
      }
      
      // Calcular meses transcurridos desde que alcanzó nivel 5
      // Usar diferencia de meses calendario para mayor precisión
      final mesesTranscurridos = _calcularMesesConsecutivos(_fechaPrimerNivel5!, ahora);
      
      // Actualizar si han pasado más meses
      if (mesesTranscurridos > _mesesEnNivel5) {
        await prefs.setInt('meses_en_nivel5', mesesTranscurridos);
        setState(() {
          _mesesEnNivel5 = mesesTranscurridos;
        });
      }
    } catch (e) {
      print('Error verificando meses en nivel 5: $e');
    }
  }
  
  // Calcular meses consecutivos entre dos fechas
  int _calcularMesesConsecutivos(DateTime inicio, DateTime fin) {
    int meses = 0;
    DateTime fechaActual = DateTime(inicio.year, inicio.month, 1);
    final fechaFin = DateTime(fin.year, fin.month, 1);
    
    while (fechaActual.isBefore(fechaFin) || fechaActual.isAtSameMomentAs(fechaFin)) {
      meses++;
      fechaActual = DateTime(fechaActual.year, fechaActual.month + 1, 1);
    }
    
    return meses;
  }

  // Obtener la ruta de la imagen (normal o "-no")
  String _getProfileImagePathForSelector(int imageNumber, bool isUnlocked) {
    if (isUnlocked) {
      return 'assets/images/perfil/perfil$imageNumber.png';
    } else {
      return 'assets/images/perfil/perfil$imageNumber-no.png';
    }
  }

  String _getRangoEdad(String? rango) {
    return rango ?? '15-17';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/perfil/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
          children: [
            // Header de navegación
            HeaderNavigation(
              onMenuTap: () {
                Navigator.pop(context);
              },
              title: 'BIENVENIDOS',
              subtitle: 'MI PERFIL',
            ),

            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 20),

                    // Ficha principal
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Fondo de la ficha (relleno completo)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/perfil/ficha.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          // Contenido de la ficha
                          Padding(
                            padding: EdgeInsets.all(30),
                            child: Column(
                              children: [
                                // Imagen de perfil y selector
                                _buildProfileImageSection(),

                                SizedBox(height: 18), // Reducido de 20 a 18
                                // Información del usuario
                                _buildUserInfoSection(),

                                SizedBox(height: 16),
                                // Contenedores de puntos y racha
                                _buildPointsRow(),

                                SizedBox(height: 8), // Reducido de 15 a 8
                                // Información adicional de puntos
                                _buildPuntosInfo(),

                                SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Información del padre/madre fuera de la ficha principal
                    _buildParentInfoSection(),

                    SizedBox(height: 30),

                    // Botones de acción
                    _buildActionButtons(),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        // Imagen de perfil principal
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFF9C27B0), width: 4),
          ),
          child: ClipOval(
            child: Image.asset(
              _getProfileImagePath(_selectedProfileImage),
              width: 190,
              height: 190,
              fit: BoxFit.cover,
            ),
          ),
        ),

        SizedBox(height: 13),
        // Selector de imágenes de perfil - Grid de 6 imágenes
        Consumer<UserManager>(
          builder: (context, userManager, child) {
            final rachaPoints = userManager.rachaPoints;
            
            // Verificar y actualizar meses en nivel 5 cuando cambian los puntos
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndUpdateMesesEnNivel5();
            });
            
            return Column(
              children: [
                // Primera fila: perfil 1, 2, 3
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 2, 3].map((imageNumber) {
                    return _buildProfileImageSelector(imageNumber, rachaPoints);
                  }).toList(),
                ),
                SizedBox(height: 15),
                // Segunda fila: perfil 4, 5, 6
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [4, 5, 6].map((imageNumber) {
                    return _buildProfileImageSelector(imageNumber, rachaPoints);
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

    Widget _buildUserInfoSection() {
    return Consumer<UserManager>(
      builder: (context, userManager, child) {
        final user = userManager.currentUser;
        
        return Column(
          children: [
            // Nombre completo
            _buildInfoField(
              label: 'NOMBRE COMPLETO',
              value: user?['nombre_menor'] ?? 'Usuario',
              controller: _nombreController,
              isEditing: _isEditing,
            ),
            
            SizedBox(height: 10), // Reducido de 12 a 10
            
            // Nombre de usuario
            _buildInfoField(
              label: 'USUARIO',
              value: user?['nombre_usuario'] ?? 'usuario',
              isEditing: false, // No editable
            ),
            
            SizedBox(height: 10), // Reducido de 12 a 10
            
            // Rango de edad
            _buildInfoField(
              label: 'EDAD',
              value: '${_getRangoEdad(user?['rango_edad'])} años',
              isEditing: false, // No editable
            ),
            
            SizedBox(height: 10), // Reducido de 12 a 10
            
            // Email
            _buildInfoField(
              label: 'EMAIL',
              value: user?['email'] ?? 'usuario@email.com',
              controller: _emailController,
              isEditing: _isEditing,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    TextEditingController? controller,
    required bool isEditing,
    Color? labelColor,
    Color? borderColor,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity, // Forzar ancho completo
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: labelColor ?? Color(0xFFAAA7C7),
            ),
          ),
          SizedBox(height: 1), // Reducido de 2 a 1 (super pegado)
          Container(
            width: double.infinity,
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            decoration: BoxDecoration(
              color: (isEditing && controller != null) ? Color(0xFFFFF59D) : Colors.transparent,
              border: Border.all(color: (borderColor ?? Color(0xFFAAA7C7)), width: 2),
              borderRadius: BorderRadius.circular(23),
            ),
            child: isEditing && controller != null
                ? TextField(
                    controller: controller,
                    textAlignVertical: TextAlignVertical.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'GothamRounded',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? Color(0xFF2B2372),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                    ),
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'GothamRounded',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: valueColor ?? Color(0xFF2B2372),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsRow() {
    return Consumer<UserManager>(
      builder: (context, userManager, child) {
        final puntosApp = userManager.puntos;
        final puntosJuego = userManager.gamePoints;

        final puntosTotales = puntosApp + puntosJuego;

        Widget buildCard({required String label, required int value, IconData? icon, Color color = const Color(0xFF703FC2), double height = 52, double fontSize = 16, VoidCallback? onTap}) {
          return GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: height,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: fontSize + 4),
                    SizedBox(width: 12),
                  ],
                  Text(
                    '$value',
                    style: TextStyle(
                      fontFamily: 'GothamRounded',
                      fontSize: fontSize + 2,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'GothamRounded',
                      fontSize: fontSize - 2,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            buildCard(
              label: 'Puntos App',
              value: puntosApp,
              icon: Icons.phone_android,
              color: Color(0xFF703FC2),
              height: 54,
              fontSize: 16,
              onTap: _showPuntosDetalle,
            ),
            SizedBox(height: 10),
            buildCard(
              label: 'Puntos Juego',
              value: puntosJuego,
              icon: Icons.videogame_asset,
              color: Color(0xFF5B3AA3),
              height: 52,
              fontSize: 15,
            ),
            SizedBox(height: 10),
            buildCard(
              label: 'Puntos Totales Usuario',
              value: puntosTotales,
              icon: Icons.stars,
              color: Color(0xFF9C27B0),
              height: 56,
              fontSize: 17,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPuntosInfo() {
    return Consumer<UserManager>(
      builder: (context, userManager, child) {
        final ultimaSesion = userManager.ultimaSesion;
        final fechaInicioRacha = userManager.fechaInicioRacha;
        final puntosApp = userManager.puntos;
        final puntosRacha = userManager.rachaPoints;
        final puntosDiarios = userManager.puntosDiarios;
        final rachaDias = userManager.rachaDias;
        final puntosJuego = userManager.gamePoints;

        final puntosTotales = puntosApp + puntosJuego;
        
        return Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'DETALLE DE PUNTOS',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFAAA7C7),
                ),
              ),
              SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPuntosDetalleItem('Puntos App (totales)', '$puntosApp', Colors.deepPurpleAccent),
                  _buildPuntosDetalleItem('Puntos por Racha', '$puntosRacha', Colors.purple.shade200),
                  _buildPuntosDetalleItem('Puntos por Sesiones Diarias', '$puntosDiarios', Colors.purple.shade200),
                  _buildPuntosDetalleItem('Racha actual', '${rachaDias} días', Colors.purple.shade200),
                  SizedBox(height: 10),
                  _buildPuntosDetalleItem('Puntos Juego acumulados', '$puntosJuego', Colors.green),
                  _buildPuntosDetalleItem('Puntos Totales Usuario', '$puntosTotales', Colors.amber),
                  SizedBox(height: 12),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPuntosItem(
                    'Última Sesión',
                    ultimaSesion != null 
                        ? '${ultimaSesion.day}/${ultimaSesion.month}/${ultimaSesion.year}'
                        : 'Nunca',
                  ),
                  _buildPuntosItem(
                    'Inicio Racha',
                    fechaInicioRacha != null 
                        ? '${fechaInicioRacha.day}/${fechaInicioRacha.month}/${fechaInicioRacha.year}'
                        : 'N/A',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPuntosItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Gotham Rounded',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFFAAA7C7),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Gotham Rounded',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B2372),
          ),
        ),
      ],
    );
  }

  void _showPuntosDetalle() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<UserManager>(
          builder: (context, userManager, child) {
            final puntosApp = userManager.puntos;
            final puntosSnippets = userManager.puntosSnippets;
            final puntosDiarios = userManager.puntosDiarios;
            final puntosRacha = userManager.rachaDias;
            final puntosJuego = userManager.gamePoints;
            final puntosTotales = puntosApp + puntosJuego;
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'SISTEMA DE PUNTOS',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9C27B0),
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPuntosDetalleItem('Puntos App (totales)', '$puntosApp', Colors.deepPurpleAccent),
                  _buildPuntosDetalleItem('Puntos por Snippets', '$puntosSnippets', Colors.purple.shade200),
                  _buildPuntosDetalleItem('Puntos por Sesiones Diarias', '$puntosDiarios', Colors.purple.shade200),
                  _buildPuntosDetalleItem('Racha actual', '${puntosRacha} días', Color(0xFF9C27B0)),
                  SizedBox(height: 10),
                  _buildPuntosDetalleItem('Puntos Juego acumulados', '$puntosJuego', Colors.green),
                  _buildPuntosDetalleItem('Puntos Totales Usuario', '$puntosTotales', Colors.amber),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CÓMO GANAR PUNTOS:',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9C27B0),
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildPuntosRegla('Sesión diaria', '+2 puntos'),
                        _buildPuntosRegla('Racha 7 días', '+50 puntos'),
                        _buildPuntosRegla('Racha 30 días', '+200 puntos'),
                        _buildPuntosRegla('Completar Caja', '+10 puntos'),
                        _buildPuntosRegla('Completar Aprendiendo', '+5 puntos'),
                        _buildPuntosRegla('Ver Videoblog', '+3 puntos'),
                        _buildPuntosRegla('Completar Poder', '+15 puntos'),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'CERRAR',
                    style: TextStyle(
                      fontFamily: 'Gotham Rounded',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9C27B0),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPuntosDetalleItem(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuntosRegla(String actividad, String puntos) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            actividad,
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            puntos,
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9C27B0),
            ),
          ),
        ],
      ),
    );
  }









  Widget _buildParentInfoSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFB85BF3),
            Color(0xFFE45BF3),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'DATOS DEL PADRE O MADRE:',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 22),
          // Nombre del padre/madre
          _buildInfoField(
            label: 'NOMBRE',
            value: _nombrePadreController.text.isNotEmpty ? _nombrePadreController.text : 'No especificado',
            controller: _nombrePadreController,
            isEditing: _isEditing,
            labelColor: Colors.white,
            borderColor: Colors.white.withOpacity(0.5),
            valueColor: _isEditing ? Color(0xFF2B2372) : Colors.white,
          ),

          SizedBox(height: 10), // Reducido de 12 a 10
          // Teléfono
          _buildInfoField(
            label: 'TELÉFONO',
            value: _telefonoController.text.isNotEmpty ? _telefonoController.text : 'No especificado',
            controller: _telefonoController,
            isEditing: _isEditing,
            labelColor: Colors.white,
            borderColor: Colors.white.withOpacity(0.5),
            valueColor: _isEditing ? Color(0xFF2B2372) : Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'GUARDAR CAMBIOS',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          SizedBox(width: 15),

          Expanded(
            child: ElevatedButton(
              onPressed: _cancelEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF44336),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'CANCELAR',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF44336),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'EDITAR PERFIL',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cerrarSesion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'CERRAR SESIÓN',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  void _cerrarSesion() async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'CERRAR SESIÓN',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9C27B0),
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            '¿Estás seguro de que deseas cerrar sesión?',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'CANCELAR',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'CERRAR SESIÓN',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9C27B0),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      // Limpiar información del usuario
      final userManager = Provider.of<UserManager>(context, listen: false);
      userManager.clearUserInfo();
      
      // Detener snippets
      try {
        SnippetService().stopAppTimer();
      } catch (_) {}

      // Navegar a la pantalla de inicio de sesión
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => InicioPage()),
        (route) => false, // Eliminar todas las rutas anteriores
      );
    }
  }
}
