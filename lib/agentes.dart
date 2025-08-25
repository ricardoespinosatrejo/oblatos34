import 'package:flutter/material.dart';
import 'widgets/header_navigation.dart';
import 'widgets/bottom_navigation_menu.dart';

class AgentesCambioScreen extends StatefulWidget {
  @override
  _AgentesCambioScreenState createState() => _AgentesCambioScreenState();
}

class _AgentesCambioScreenState extends State<AgentesCambioScreen> {
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
                    subtitle: 'AGENTES DEL\nCAMBIO',
                  ),
                  
                  // Contenido específico de la pantalla de agentes del cambio
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icono de agentes del cambio
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF9800), // Naranja para cambio
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.people,
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
                                  text: 'AGENTES DEL\n',
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
                                  text: 'CAMBIO',
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
                              'Conoce a las personas y organizaciones que están transformando el mundo a través de la cooperación y la solidaridad.',
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
                                colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
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
                                'CONOCER AGENTES',
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
