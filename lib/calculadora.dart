import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class CalculadoraScreen extends StatefulWidget {
  @override
  _CalculadoraScreenState createState() => _CalculadoraScreenState();
}

class _CalculadoraScreenState extends State<CalculadoraScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header de navegación
              _buildHeader(),
              
              // Contenido principal
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono de calculadora
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.calculate,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      
                      SizedBox(height: 30),
                      
                      // Título
                      Text(
                        'Calculadora Financiera',
                        style: TextStyle(
                          fontFamily: 'Gotham Rounded',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Descripción
                      Text(
                        'Próximamente disponible\nHerramientas para calcular ahorros,\npréstamos y metas financieras',
                        style: TextStyle(
                          fontFamily: 'Gotham Rounded',
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Botón de regreso
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 200,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: LinearGradient(
                              colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'REGRESAR',
                              style: TextStyle(
                                fontFamily: 'Gotham Rounded',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // Botón de regreso
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          Spacer(),
          
          // Título
          Column(
            children: [
              Text(
                'BIENVENIDOS',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'CALCULADORA',
                style: TextStyle(
                  fontFamily: 'Gryzensa',
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.white70,
                  height: 0.8,
                ),
              ),
            ],
          ),
          
          Spacer(),
          
          // Espacio para balancear
          Container(width: 50),
        ],
      ),
    );
  }
}
