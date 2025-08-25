import 'package:flutter/material.dart';

class BienvenidaPage extends StatefulWidget {
  const BienvenidaPage({super.key});

  @override
  State<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage> {
  int _currentSlide = 1; // 1 = slide1, 2 = slide2, 3 = slide3, 4 = slide4
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/instrucciones/fondo-frame.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Contenido principal de la pantalla
            SafeArea(
              child: Column(
                children: [

                  
                  // Contenido principal
                  Expanded(
                    child: _buildSlideSystem(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Sistema principal de slides - Carrusel directo
  Widget _buildSlideSystem() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 700,
      child: Column(
        children: [
          // Espacio superior de 50px
          SizedBox(height: 50),
          
          // Carrusel de slides
          Expanded(
            child: PageView.builder(
              onPageChanged: (index) {
                setState(() {
                  _currentSlide = index + 1;
                });
              },
              itemCount: 4,
              itemBuilder: (context, index) {
                return _buildSlideContent(index + 1);
              },
            ),
          ),
          
          // Indicadores de página (puntos)
          Container(
            margin: EdgeInsets.only(bottom: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentSlide == index + 1 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Contenido individual de cada slide
  Widget _buildSlideContent(int slideIndex) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          // Imagen del slide
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: Image.asset(
              'assets/images/instrucciones/slide${slideIndex}.png',
              width: 334,
              height: 603,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 334,
                  height: 603,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'Slide $slideIndex',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Botón "Comenzar" solo en el slide 4
          if (slideIndex == 4)
            Container(
              margin: EdgeInsets.only(top: 30),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: Container(
                  width: 260,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFFF1744), Color(0xFFE91E63)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Comenzar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    }
}
