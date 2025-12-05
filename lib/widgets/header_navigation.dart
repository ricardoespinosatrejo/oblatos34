import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../user_manager.dart';
import 'animated_profile_image.dart';

class HeaderNavigation extends StatelessWidget {
  final VoidCallback onMenuTap;
  final String title;
  final String subtitle;
  final VoidCallback? onProfileTap; // Callback opcional para acciones antes de navegar al perfil
  final double leftPadding; // Padding izquierdo opcional para los títulos

  const HeaderNavigation({
    Key? key,
    required this.onMenuTap,
    this.title = 'BIENVENIDOS',
    this.subtitle = 'MENU',
    this.onProfileTap,
    this.leftPadding = 0, // Por defecto sin padding
  }) : super(key: key);

  // Función para verificar si estamos en la página de perfil
  bool _isCurrentRoutePerfil(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    return currentRoute == '/perfil';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120, // Altura fija para la barra de navegación
      padding: const EdgeInsets.all(20.0),
      child: Stack(
        clipBehavior: Clip.none, // Permitir que los hijos se salgan del Stack
        children: [
          // Título central centrado
          Positioned(
            left: leftPadding,
            right: 0,
            top: 0,
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Gryzensa',
                    fontSize: 28, // Reducido de 30 a 28
                    fontWeight: FontWeight.w300,
                    color: Colors.white70,
                    height: 0.8, // Reducir interlineado para juntar las líneas
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Menú hamburguesa o flecha de regreso (izquierda)
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onTap: onMenuTap,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _isCurrentRoutePerfil(context) 
                      ? Color(0xFF9C27B0)  // Morado para perfil
                      : Color(0xFFE91E63), // Rosa para menú
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isCurrentRoutePerfil(context) 
                      ? Icons.arrow_back  // Flecha de regreso para perfil
                      : Icons.menu,       // Menú hamburguesa para otras páginas
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          
          // Indicador de racha (a la derecha del menú hamburguesa)
          Positioned(
            left: 60, // A la derecha del menú hamburguesa (50px + 10px de espacio)
            top: 0,
            child: Consumer<UserManager>(
              builder: (context, userManager, child) {
                final rachaPoints = userManager.rachaPoints;
                final levelNumber = _getLevelNumber(rachaPoints);
                
                return GestureDetector(
                  onTap: () {
                    // Navegar a la sección de Rachacoop
                    Navigator.pushNamed(context, '/rachacoop');
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Imagen del nivel
                      Container(
                        width: 50,
                        height: 50,
                        child: Image.asset(
                          'assets/images/rachacoop/level$levelNumber-pq.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Si falla, mostrar un contenedor con el número del nivel
                            return Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFE91E63),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '$levelNumber',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Esfera con puntos de racha (encima del personaje)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(0xFF4CAF50), // Verde
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$rachaPoints',
                              style: TextStyle(
                                fontFamily: 'Gotham Rounded',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Perfil de usuario (derecha)
          Positioned(
            right: -20, // Compensar el padding del Container padre para pegar al borde
            top: -30, // Compensar el padding superior y subir 10px más
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Imagen de perfil (z-index inferior) con animación
                GestureDetector(
                  onTap: () async {
                    // Solo navegar si no estamos ya en la página de perfil
                    final currentRoute = ModalRoute.of(context)?.settings.name;
                    if (currentRoute != '/perfil') {
                      // Ejecutar callback opcional (por ejemplo, para detener audio de caja)
                      if (onProfileTap != null) {
                        onProfileTap!();
                      }
                      
                      // Reproducir audio antes de navegar
                      try {
                        final audioPlayer = AudioPlayer();
                        await audioPlayer.play(AssetSource('audios/perfil.mp3'));
                        // Esperar un poco para que se escuche el audio
                        await Future.delayed(Duration(milliseconds: 200));
                        audioPlayer.dispose();
                      } catch (e) {
                        // Si hay error con el audio, continuar con la navegación
                        print('Error reproduciendo audio: $e');
                      }
                      
                      Navigator.pushNamed(context, '/perfil');
                    }
                  },
                  child: Consumer<UserManager>(
                    builder: (context, userManager, child) {
                      final profileImage = userManager.currentUser?['profile_image'] ?? 1;
                      
                      Widget imageWidget;
                      
                      // Para todos los perfiles (1-6), usar versión -big.png sin contenedor circular
                      if (profileImage >= 1 && profileImage <= 6) {
                        imageWidget = ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 120, // Altura del header
                            maxWidth: MediaQuery.of(context).size.width * 0.5, // Ancho máximo
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Image.asset(
                              'assets/images/perfil/perfil$profileImage-big.png',
                              fit: BoxFit.fitHeight,
                              errorBuilder: (context, error, stackTrace) {
                                // Si falla, mostrar imagen normal en círculo
                                return _buildCircularProfileImage(context, profileImage);
                              },
                            ),
                          ),
                        );
                      } else {
                        // Para perfiles fuera del rango esperado, usar el círculo normal
                        imageWidget = _buildCircularProfileImage(context, profileImage);
                      }
                      
                      // Usar widget personalizado para animar el cambio de imagen
                      // Usar una key estable para mantener el mismo widget entre reconstrucciones
                      return AnimatedProfileImage(
                        key: ValueKey('profile_image_header'), // Key estable para mantener el estado
                        profileImage: profileImage,
                        imageWidget: imageWidget,
                      );
                    },
                  ),
                ),
                // Nombre del usuario (z-index superior, encima de la imagen)
                Consumer<UserManager>(
                  builder: (context, userManager, child) {
                    final profileImage = userManager.currentUser?['profile_image'] ?? 1;
                    return Positioned(
                      top: (profileImage >= 1 && profileImage <= 6) ? 80 : 74, // Posición ajustada para perfiles 1-6
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Color(0xFFF44336).withOpacity(0.7), // Color rojo con 70% de transparencia
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          userManager.userName,
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Obtener número de nivel (1-5) basado en puntos de racha
  int _getLevelNumber(int rachaPoints) {
    if (rachaPoints >= 2001) return 5;
    if (rachaPoints >= 1201) return 4;
    if (rachaPoints >= 501) return 3;
    if (rachaPoints >= 101) return 2;
    return 1;
  }

  // Widget helper para mostrar imagen de perfil en círculo (para perfiles 1, 3, 4, 5, 6)
  Widget _buildCircularProfileImage(BuildContext context, int profileImage) {
    final isPerfilRoute = _isCurrentRoutePerfil(context);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isPerfilRoute 
              ? Colors.grey.shade400 
              : Color(0xFFE91E63), 
          width: 2
        ),
        color: isPerfilRoute 
            ? Colors.grey.shade200 
            : Colors.white,
      ),
      child: Stack(
        children: [
          // Foto de perfil o imagen por defecto
          Center(
            child: ClipOval(
              child: Image.asset(
                'assets/images/perfil/perfil$profileImage.png',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Si falla, mostrar imagen por defecto
                  return Image.asset(
                    'assets/images/1inicio/perfil.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isPerfilRoute 
                    ? Colors.grey.shade400 
                    : Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

