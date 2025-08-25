import 'package:flutter/material.dart';
import 'widgets/header_navigation.dart';
import 'widgets/bottom_navigation_menu.dart';

class EventosScreen extends StatefulWidget {
  @override
  _EventosScreenState createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
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
                    subtitle: 'EVENTOS Y\nCAMPAÑAS',
                  ),
                  
                  // Contenido específico de la pantalla de eventos y campañas
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icono de eventos
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2196F3), // Azul para eventos
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.event,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                          
                          SizedBox(height: 30),
                          
                          // Título de la pantalla
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'EVENTOS Y\n',
                                  style: TextStyle(
                                    fontFamily: 'Gryzensa',
                                    fontSize: 42,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    height: 0.8,
                                  ),
                                ),
                                TextSpan(
                                  text: 'CAMPAÑAS',
                                  style: TextStyle(
                                    fontFamily: 'Gryzensa',
                                    fontSize: 42,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    height: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: 20),
                          
                          // Descripción
                          Container(
                            width: 300,
                            child: Text(
                              'Participa en eventos emocionantes y campañas que promueven la cooperación y el cambio social positivo en tu comunidad.',
                              style: TextStyle(
                                fontFamily: 'Gotham Rounded',
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          SizedBox(height: 40),
                          
                          // Botón de acción
                          Container(
                            width: 280,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                // Acción del botón
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Text(
                                'VER EVENTOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Menú inferior reutilizable
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNavigationMenu(),
            ),
          ],
        ),
      ),
    );
  }


}
