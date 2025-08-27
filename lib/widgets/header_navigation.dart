import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          
          // Menú hamburguesa (izquierda)
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onTap: onMenuTap,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu,
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
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFFE91E63), width: 2),
                    color: Colors.white,
                  ),
                  child: Stack(
                    children: [
                      // Foto de perfil o imagen por defecto
                      Center(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/1inicio/perfil.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
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
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
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

