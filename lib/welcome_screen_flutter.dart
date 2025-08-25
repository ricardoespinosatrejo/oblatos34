import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1B3E), // Azul oscuro superior
              Color(0xFF2D1B69), // Púrpura medio
              Color(0xFF6B2C91), // Púrpura
              Color(0xFFE91E63), // Rosa magenta inferior
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Elementos decorativos de fondo
            _buildBackgroundElements(),
            
            // Contenido principal
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: 60),
                    
                    // Logo principal
                    _buildLogo(),
                    
                    SizedBox(height: 40),
                    
                    // Título principal
                    _buildMainTitle(),
                    
                    SizedBox(height: 16),
                    
                    // Texto descriptivo
                    _buildDescriptionText(),
                    
                    SizedBox(height: 32),
                    
                    // Botón Crear cuenta
                    _buildCreateAccountButton(context),
                    
                    Spacer(),
                    
                    // Personajes en la parte inferior
                    _buildCharacters(),
                    
                    SizedBox(height: 40),
                    
                    // Botón inferior de navegación
                    _buildBottomNavigation(context),
                    
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // Cohete en la parte superior derecha
        Positioned(
          top: 50,
          right: 20,
          child: Transform.rotate(
            angle: 0.3,
            child: Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Monedas doradas dispersas
        Positioned(
          top: 120,
          right: 60,
          child: _buildCoinGroup(),
        ),
        
        // Elementos brillantes dispersos
        Positioned(
          top: 200,
          left: 30,
          child: _buildSparkle(12),
        ),
        
        Positioned(
          top: 300,
          right: 40,
          child: _buildSparkle(8),
        ),
        
        Positioned(
          bottom: 200,
          left: 50,
          child: _buildSparkle(10),
        ),
        
        // Moneda grande en la parte inferior derecha
        Positioned(
          bottom: 180,
          right: 30,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '\$',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoinGroup() {
    return Stack(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            ),
          ),
        ),
        Positioned(
          left: 20,
          top: 10,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 10,
          top: -15,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSparkle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.account_balance,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildMainTitle() {
    return Column(
      children: [
        Text(
          'BIENVENIDO A',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2.0,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: Offset(2, 2),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'NUESTRA APP',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2.0,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: Offset(2, 2),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDescriptionText() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '¡Hola, futuro genio financiero! Te damos la bienvenida más cool al mundo de la app de finanzas para jóvenes de Caja Oblatos. Aquí no solo vas a aprender a administrar tu dinero, ¡vas a empoderarte de verdad!',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white.withOpacity(0.9),
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCreateAccountButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Acción para crear cuenta
        print('Crear cuenta pressed');
      },
      child: Container(
        width: 200,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFE91E63).withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Crear cuenta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacters() {
    return Container(
      height: 200,
      child: Stack(
        children: [
          // Robot personaje (izquierda)
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 120,
              height: 180,
              child: Stack(
                children: [
                  // Cuerpo del robot
                  Positioned(
                    bottom: 40,
                    left: 20,
                    child: Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFD84315)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Cabeza del robot
                  Positioned(
                    top: 0,
                    left: 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFD84315)],
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00BCD4),
                              ),
                            ),
                            SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00BCD4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Brazo levantado
                  Positioned(
                    top: 80,
                    right: 0,
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Container(
                        width: 40,
                        height: 15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Personaje humano (derecha)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 120,
              height: 180,
              child: Stack(
                children: [
                  // Cuerpo
                  Positioned(
                    bottom: 40,
                    left: 20,
                    child: Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [Color(0xFFE1BEE7), Color(0xFFBA68C8)],
                        ),
                      ),
                    ),
                  ),
                  // Cabeza
                  Positioned(
                    top: 0,
                    left: 35,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFDBCF),
                      ),
                    ),
                  ),
                  // Cabello
                  Positioned(
                    top: -5,
                    left: 30,
                    child: Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color(0xFF3E2723),
                      ),
                    ),
                  ),
                  // Brazo levantado
                  Positioned(
                    top: 70,
                    right: 10,
                    child: Transform.rotate(
                      angle: 0.5,
                      child: Container(
                        width: 35,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Color(0xFFFFDBCF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Efectos de celebración
          Positioned(
            top: 20,
            left: 80,
            child: Text(
              '🎉',
              style: TextStyle(fontSize: 30),
            ),
          ),
          
          Positioned(
            top: 40,
            right: 80,
            child: Text(
              '✨',
              style: TextStyle(fontSize: 25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón INICIAR
          GestureDetector(
            onTap: () {
              print('Iniciar pressed');
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'INICIAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          
          // Botón circular central
          GestureDetector(
            onTap: () {
              print('Central button pressed');
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFE91E63).withOpacity(0.4),
                    blurRadius: 15,
                    offset: Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          
          // Botón SESIÓN
          GestureDetector(
            onTap: () {
              print('Sesión pressed');
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'SESIÓN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}