import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../user_manager.dart';

class HeaderNavigation extends StatelessWidget {
  final VoidCallback onMenuTap;
  final String title;
  final String subtitle;

  const HeaderNavigation({
    Key? key,
    required this.onMenuTap,
    this.title = 'BIENVENIDOS',
    this.subtitle = 'MENU NAV',
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
        children: [
          // Título central centrado
          Positioned(
            left: 0,
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
          
          // Perfil de usuario (derecha)
          Positioned(
            right: 0,
            top: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    // Solo navegar si no estamos ya en la página de perfil
                    final currentRoute = ModalRoute.of(context)?.settings.name;
                    if (currentRoute != '/perfil') {
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
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isCurrentRoutePerfil(context) 
                            ? Colors.grey.shade400 
                            : Color(0xFFE91E63), 
                        width: 2
                      ),
                      color: _isCurrentRoutePerfil(context) 
                          ? Colors.grey.shade200 
                          : Colors.white,
                    ),
                    child: Stack(
                      children: [
                        // Foto de perfil o imagen por defecto
                        Center(
                          child: ClipOval(
                            child: Consumer<UserManager>(
                              builder: (context, userManager, child) {
                                final profileImage = userManager.currentUser?['profile_image'] ?? 1;
                                return Image.asset(
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
                              color: _isCurrentRoutePerfil(context) 
                                  ? Colors.grey.shade400 
                                  : Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Consumer<UserManager>(
                  builder: (context, userManager, child) {
                    return Text(
                      userManager.userName,
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
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
}

