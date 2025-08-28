import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caja Button Test',
      theme: ThemeData(
        fontFamily: 'Gotham Rounded',
      ),
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0E23), // Fondo oscuro como en tu diseño
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título de prueba
            Text(
              'Prueba del Botón Caja',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 40),
            
            // Botón Caja Exacto
            CajaButton(
              onTap: () async {
                print('Botón Caja presionado');
                try {
                  await _audioPlayer.play(AssetSource('audios/ding.mp3'));
                } catch (_) {}
              },
            ),
            
            SizedBox(height: 40),
            
            // Información de las medidas
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Especificaciones del botón:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Tamaño: 300px x 100px\n'
                    '• Esfera del ícono: 80px x 80px\n'
                    '• Título "Caja": Gotham 22pts\n'
                    '• Subtítulo: Gotham 11px\n'
                    '• Gradiente azul exacto\n'
                    '• Ícono de cerdito/alcancía',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CajaButton extends StatelessWidget {
  final VoidCallback onTap;

  const CajaButton({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300, // Exactamente 300px
        height: 100, // Exactamente 100px
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50), // Bordes muy redondeados
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5DADE2), // Azul claro superior
              Color(0xFF3498DB), // Azul medio
              Color(0xFF2E86C1), // Azul más oscuro inferior
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Efecto de brillo interno en la parte superior
            Positioned(
              top: 8,
              left: 20,
              right: 20,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // Contenido principal
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Esfera del ícono - 80x80px exacto
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.2,
                        colors: [
                          Color(0xFF85C1E9), // Azul más claro para la esfera
                          Color(0xFF5DADE2), // Azul medio
                          Color(0xFF3498DB), // Azul más oscuro en los bordes
                        ],
                        stops: [0.0, 0.6, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.savings, // Ícono de cerdito/alcancía
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 20),
                  
                  // Textos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Título "Caja" - 22pts
                        Text(
                          'Caja',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 22, // 22pts exacto
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        
                        SizedBox(height: 4),
                        
                        // Subtítulo - 11px
                        Text(
                          'Conoce nuestra historia',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            fontSize: 11, // 11px exacto
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}