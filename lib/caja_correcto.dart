import 'package:flutter/material.dart';
import 'inicio.dart'; // Para acceder a ProfileImageManager
import 'widgets/header_navigation.dart'; // Para el HeaderNavigation reutilizable

class CajaScreen extends StatefulWidget {
  @override
  _CajaScreenState createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  bool _showFicha = true; // Controla si mostrar la ficha o la historia
  
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
                    subtitle: 'CAJA OBLATOS',
                  ),
                  
                  // Contenido específico de la pantalla de caja
                  Expanded(
                    child: _buildFichaPrincipal(),
                  ),
                ],
              ),
            ),
            
            // Menú inferior rojo
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 98,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/menu/menu-barra.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem('m-icono1.png', 'Caja\nOblatos', '/caja'),
                    _buildNavItem('m-icono2.png', 'Agentes\nCambio', '/agentes-cambio'),
                    _buildCenterNavItem('m-icono3.png'),
                    _buildNavItem('m-icono4.png', 'Eventos', '/eventos'),
                    _buildNavItem('m-icono5.png', 'Video\nBlog', '/video-blog'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 25,
            height: 25,
            child: Image.asset(
              'assets/images/menu/$iconPath',
              width: 8,
              height: 8,
              color: Colors.white,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.home, color: Colors.white, size: 8);
              },
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCenterNavItem(String iconPath) {
    return Transform.translate(
      offset: Offset(-6, -14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFFF1744),
                  Color(0xFFE91E63),
                ],
              ),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/menu/$iconPath',
                width: 24,
                height: 24,
                color: Colors.white,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.home, color: Colors.white, size: 24);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ficha principal de Caja Oblatos
  Widget _buildFichaPrincipal() {
    return Stack(
      children: [
        // Contenedor principal con animación de slide
        AnimatedContainer(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(
            _showFicha ? 0 : -MediaQuery.of(context).size.width,
            0,
            0,
          ),
          child: Stack(
            children: [
              // Ficha base blanca posicionada en punto medio
              Positioned(
                left: 23,
                top: 30,
                child: Container(
                  width: 393,
                  height: 580,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/caja/base-ficha.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Plasta de texto con scroll
                      Positioned(
                        bottom: 30,
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 350,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/caja/plasta-texto-scroll.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Descubre Caja Oblatos',
                                  style: TextStyle(
                                    fontFamily: 'Gotham Rounded',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFE91E63),
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'PUES BIEN, LA HISTORIA DE CAJA POPULAR OBLATOS COMENZÓ EL 11 DE MAYO DE 1966.',
                                  style: TextStyle(
                                    fontFamily: 'Gotham Rounded',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'En ese momento histórico, un grupo visionario de líderes comunitarios se unió con el propósito de crear una organización que fuera más allá de los servicios financieros tradicionales. Su visión era establecer una institución que ofreciera una amplia gama de servicios comunitarios, desde préstamos y ahorros hasta programas de desarrollo social y educativo.',
                                  style: TextStyle(
                                    fontFamily: 'Gotham Rounded',
                                    fontSize: 14,
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'La fecha del 11 de mayo de 1966 no fue elegida al azar. Representa el momento en que se materializó un sueño colectivo de empoderamiento financiero y desarrollo comunitario. Esta fecha marca el inicio de una trayectoria que ha transformado la vida de miles de familias en la región de Oblatos y más allá.',
                                  style: TextStyle(
                                    fontFamily: 'Gotham Rounded',
                                    fontSize: 14,
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'Desde sus inicios, Caja Popular Oblatos se ha distinguido por su compromiso inquebrantable con los valores cooperativos. La institución nació de la convicción de que el acceso a servicios financieros de calidad no debería ser un privilegio, sino un derecho fundamental para todos los miembros de la comunidad.',
                                  style: TextStyle(
                                    fontFamily: 'Gotham Rounded',
                                    fontSize: 14,
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'La cooperativa se fundó sobre principios sólidos de democracia, igualdad, equidad y solidaridad. Cada miembro tiene voz y voto en las decisiones importantes, y los beneficios se distribuyen de manera justa entre todos los participantes. Este modelo de gobernanza ha sido fundamental para construir la confianza y la lealtad que caracterizan a la institución.',
                                  style: TextStyle(
                                    fontFamily: 'Gotham Rounded',
                                    fontSize: 14,
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'A lo largo de más de cinco décadas, Caja Popular Oblatos ha evolucionado y se ha adaptado a los cambios económicos y sociales, pero siempre manteniendo su esencia cooperativa y su compromiso con la comunidad. La institución ha sido testigo y protagonista del crecimiento y desarrollo de la región, contribuyendo activamente al bienestar de sus habitantes.',
                                  style: TextStyle(
                                    fontFamily: 'Gotham Rounded',
                                    fontSize: 14,
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'Hoy, Caja Popular Oblatos representa mucho más que una institución financiera. Es un símbolo de la capacidad de las comunidades para organizarse y crear soluciones sostenibles a sus necesidades. Es un ejemplo de cómo la cooperación y la solidaridad pueden transformar realidades y construir un futuro más próspero para todos.',
                                  style: TextStyle(
                                    fontFamily: 'Gotham Rounded',
                                    fontSize: 14,
                                    color: Colors.black54,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Título de la ficha encima de la plasta blanca
              Positioned(
                left: 23,
                top: 30,
                child: Image.asset(
                  'assets/images/caja/titulo-ficha1.png',
                  width: 393,
                  fit: BoxFit.fitWidth,
                ),
              ),
              
              // Botón siguiente centrado encima del título de la ficha
              Positioned(
                left: 123,
                top: 160,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showFicha = false;
                      });
                    },
                    child: Image.asset(
                      'assets/images/caja/btn-siguiente.png',
                      width: 91.5,
                      height: 60,
                    ),
                  ),
                ),
              ),
              
              // Elementos decorativos chunche-f y chunche-g
              Positioned(
                left: 43,
                top: 215,
                child: Image.asset(
                  'assets/images/caja/chunche-f.png',
                  width: 40,
                  height: 40,
                ),
              ),
              Positioned(
                right: 43,
                top: 230,
                child: Image.asset(
                  'assets/images/caja/chunche-g.png',
                  width: 40,
                  height: 40,
                ),
              ),
            ],
          ),
        ),
        
        // Imagen de historia con animación de entrada desde la derecha
        AnimatedContainer(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(
            _showFicha ? MediaQuery.of(context).size.width : 0,
            0,
            0,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 700,
            child: Column(
              children: [
                // Botón regresar
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showFicha = true;
                          });
                        },
                        child: Image.asset(
                          'assets/images/caja/btn-regresar.png',
                          width: 120,
                          height: 40,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Imagen de historia con scroll horizontal
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.hardEdge,
                    child: Padding(
                      padding: EdgeInsets.only(left: 50),
                      child: Transform.translate(
                        offset: Offset(0, -50),
                        child: Image.asset(
                          'assets/images/caja/historia-oblatos.png',
                          height: 680,
                          fit: BoxFit.contain,
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
    );
  }


}
