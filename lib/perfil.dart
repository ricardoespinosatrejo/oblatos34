import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_manager.dart';
import 'widgets/header_navigation.dart';

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

  bool _isEditing = false;
  int _selectedProfileImage = 1; // 1, 2, o 3

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
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
    super.dispose();
  }

  void _loadUserData() {
    final userManager = Provider.of<UserManager>(context, listen: false);
    final user = userManager.currentUser;

    if (user != null) {
      _nombreController.text = user['nombre_menor'] ?? '';
      _emailController.text = user['email'] ?? '';
      _telefonoController.text = user['telefono'] ?? '';
      _nombrePadreController.text = user['nombre_padre_madre'] ?? '';
      _selectedProfileImage = user['profile_image'] ?? 1;
      
      // Actualizar sesión diaria automáticamente al cargar el perfil
      _updateSesionDiaria(userManager);
    }
  }

  void _updateSesionDiaria(UserManager userManager) async {
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
        // Actualizar UserManager con los nuevos datos
        userManager.updateSesionDiaria();
        print('✅ Sesión diaria actualizada automáticamente');
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

  String _getProfileImagePath(int imageNumber) {
    return 'assets/images/perfil/perfil$imageNumber.png';
  }

  String _getRangoEdad(String? rango) {
    return rango ?? '15-17';
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
                  padding: EdgeInsets.symmetric(horizontal: 20),
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
                            // Fondo de la ficha
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/perfil/ficha.png',
                                width: double.infinity,
                                fit: BoxFit.cover,
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
 
                                   SizedBox(height: 12), // Reducido de 15 a 12
                                   // Botón de puntos
                                   GestureDetector(
                                     onTap: () {
                                       _showPuntosDetalle();
                                     },
                                     child: _buildPointsButton(),
                                   ),
                                   
                                   SizedBox(height: 8), // Reducido de 15 a 8
                                   // Información adicional de puntos
                                   _buildPuntosInfo(),
 
                                   SizedBox(height: 18), // Reducido de 20 a 18
                                   // Información del padre/madre
                                   _buildParentInfoSection(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

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

        SizedBox(height: 13), // Reducido de 20 a 13 (subido 7 píxeles)
        // Selector de imágenes de perfil
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [1, 2, 3].map((imageNumber) {
            bool isSelected = _selectedProfileImage == imageNumber;
            return GestureDetector(
              onTap: () => _selectProfileImage(imageNumber),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Color(0xFF9C27B0)
                        : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    _getProfileImagePath(imageNumber),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          }).toList(),
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
  }) {
    return Container(
      width: double.infinity, // Forzar ancho completo
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9C27B0),
            ),
          ),
          SizedBox(height: 1), // Reducido de 2 a 1 (super pegado)
          if (isEditing && controller != null)
            TextField(
              controller: controller,
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF9C27B0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF9C27B0), width: 2),
                ),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPointsButton() {
    return Consumer<UserManager>(
      builder: (context, userManager, child) {
        final puntos = userManager.puntos;
        final rachaDias = userManager.rachaDias;
        
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFF9C27B0),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de puntos
              Image.asset(
                'assets/images/perfil/puntos.png',
                width: 24,
                height: 24,
                color: Colors.amber,
              ),
              SizedBox(width: 12),
              // Texto de puntos dinámico
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$puntos PUNTOS',
                    style: TextStyle(
                      fontFamily: 'Gotham Rounded',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (rachaDias > 0)
                    Text(
                      'Racha: $rachaDias días',
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPuntosInfo() {
    return Consumer<UserManager>(
      builder: (context, userManager, child) {
        final ultimaSesion = userManager.ultimaSesion;
        final fechaInicioRacha = userManager.fechaInicioRacha;
        
        return Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'INFORMACIÓN DE PUNTOS',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9C27B0),
                ),
              ),
              SizedBox(height: 8),
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
            color: Color(0xFF9C27B0).withOpacity(0.8),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Gotham Rounded',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
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
                  _buildPuntosDetalleItem('Puntos Totales', '${userManager.puntos}', Colors.amber),
                  _buildPuntosDetalleItem('Racha Actual', '${userManager.rachaDias} días', Color(0xFF9C27B0)),
                  _buildPuntosDetalleItem('Última Sesión', 
                    userManager.ultimaSesion != null 
                        ? '${userManager.ultimaSesion!.day}/${userManager.ultimaSesion!.month}/${userManager.ultimaSesion!.year}'
                        : 'Nunca', 
                    Colors.green),
                  SizedBox(height: 15),
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
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Color(0xFFE1BEE7), // Morado claro
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
              color: Color(0xFF9C27B0),
            ),
          ),

          SizedBox(height: 6), // Reducido de 8 a 6
          // Nombre del padre/madre
          _buildInfoField(
            label: 'NOMBRE',
            value: 'Ana Gabriela Chavez Del Rio',
            controller: _nombrePadreController,
            isEditing: _isEditing,
          ),

          SizedBox(height: 10), // Reducido de 12 a 10
          // Teléfono
          _buildInfoField(
            label: 'TELÉFONO',
            value: '+52 5574287982',
            controller: _telefonoController,
            isEditing: _isEditing,
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
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _toggleEdit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF9C27B0),
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
      );
    }
  }
}
