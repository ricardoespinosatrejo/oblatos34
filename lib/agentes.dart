import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'widgets/header_navigation.dart';
import 'widgets/bottom_navigation_menu.dart';

class AgentesCambioScreen extends StatefulWidget {
  @override
  _AgentesCambioScreenState createState() => _AgentesCambioScreenState();
}

class _AgentesCambioScreenState extends State<AgentesCambioScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _selectedCategory = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Submenu state
  bool _isSubmenuVisible = false;
  late AnimationController _submenuAnimationController;
  late Animation<Offset> _submenuSlideAnimation;

                final List<String> categories = [
                'Inicio',
                'Paso 1',
                'Paso 2',
              ];

  final List<Map<String, dynamic>> agentes = [
    {
      'nombre': 'María González',
      'tipo': 'Individual',
      'descripcion': 'Líder comunitaria que ha transformado su barrio a través de huertos urbanos cooperativos.',
      'imagen': 'assets/images/aprendiendo/foto01.png',
      'logros': '500+ familias beneficiadas',
      'color': Color(0xFF4CAF50),
    },
    {
      'nombre': 'Fundación Solidaridad',
      'tipo': 'Organización',
      'descripcion': 'ONG que promueve la cooperación entre comunidades rurales para el desarrollo sostenible.',
      'imagen': 'assets/images/aprendiendo/foto02.png',
      'logros': '15 comunidades activas',
      'color': Color(0xFF2196F3),
    },
    {
      'nombre': 'Cooperativa El Futuro',
      'tipo': 'Comunidad',
      'descripcion': 'Grupo de jóvenes que crearon una red de apoyo para emprendedores locales.',
      'imagen': 'assets/images/aprendiendo/foto03.png',
      'logros': '25 emprendimientos lanzados',
      'color': Color(0xFFFF9800),
    },
    {
      'nombre': 'Carlos Mendoza',
      'tipo': 'Individual',
      'descripcion': 'Educador que implementó programas de cooperación en escuelas públicas.',
      'imagen': 'assets/images/aprendiendo/foto01.png',
      'logros': '10 escuelas transformadas',
      'color': Color(0xFF9C27B0),
    },
    {
      'nombre': 'Red Verde',
      'tipo': 'Organización',
      'descripcion': 'Colectivo ambiental que coordina acciones de reforestación comunitaria.',
      'imagen': 'assets/images/aprendiendo/foto02.png',
      'logros': '1000+ árboles plantados',
      'color': Color(0xFF4CAF50),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _pageController = PageController();
    
    _submenuAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _submenuSlideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _submenuAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _submenuAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleSubmenu() async {
    if (_isSubmenuVisible) {
      _submenuAnimationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isSubmenuVisible = false;
          });
        }
      });
    } else {
      setState(() {
        _isSubmenuVisible = true;
      });
      _submenuAnimationController.forward();
      try {
        await _audioPlayer.play(AssetSource('audios/ding.mp3'));
      } catch (_) {}
    }
  }

                List<Map<String, dynamic>> get filteredAgentes {
                if (_selectedCategory == 0) return agentes;
                // Para Slide1 y Slide2, no filtramos por tipo, solo retornamos lista vacía
                return [];
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
            image: AssetImage('assets/images/agentes/fondo-agentes.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Contenido principal de la pantalla
            MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              removeRight: true,
              child: SafeArea(
                maintainBottomViewPadding: false,
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
                  
                  // Tabs de categorías
                          Container(
                    margin: EdgeInsets.symmetric(horizontal: 15), // Reducido de 20 a 15
                            decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Color(0xFFFF9800),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                                      onTap: (index) async {
                  // Reproducir audio beep2.mp3
                  await _audioPlayer.play(AssetSource('audios/beep2.mp3'));
                  
                  setState(() {
                    _selectedCategory = index;
                  });
                  // Transiciones fluidas con PageController
                  _pageController.animateToPage(
                    index, 
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                  );
                },
                      tabs: categories.map((category) => Tab(text: category)).toList(),
                    ),
                          ),
                          
                          SizedBox(height: 20),
                          
                              // Contenido de agentes con transiciones fluidas
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedCategory = index;
                  });
                  _tabController.animateTo(index);
                },
                children: [
                  _buildTodosSection(), // Tab "Todos" - contenido específico
                  _buildSlide1(), // Tab "Slide1"
                  _buildSlide2(), // Tab "Slide2"
                ],
                    ),
                  ),
                ],
              ),
              ),
            ),
            
            // Submenu (se muestra cuando se activa)
            if (_isSubmenuVisible) _buildSubmenu(),
            
            // Menú inferior reutilizable
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: BottomNavigationMenu(onCenterTap: _toggleSubmenu),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmenu() {
    return Positioned(
      bottom: -10,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _submenuSlideAnimation,
        child: Container(
          height: 375,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/submenu/plasta-menu.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Text(
                  'Herramientas Financieras',
                  style: TextStyle(
                    fontFamily: 'GothamRounded',
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                top: 68,
                left: 0,
                child: Image.asset('assets/images/submenu/moneda2.png', width: 30, height: 130),
              ),
              Positioned(
                top: 58,
                right: 10,
                child: Image.asset('assets/images/submenu/moneda1.png', width: 46, height: 47),
              ),
              Positioned(
                top: 68,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () { print('Navegar al juego'); },
                          child: Image.asset('assets/images/submenu/btn-juego.png', height: 156),
                        ),
                        SizedBox(width: 9),
                        GestureDetector(
                          onTap: () { print('Navegar a la calculadora'); },
                          child: Image.asset('assets/images/submenu/btn-calculadora.png', height: 150),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 156,
                          child: Text('Juego', style: TextStyle(fontFamily: 'GothamRounded', fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        ),
                        SizedBox(width: 9),
                        SizedBox(
                          width: 150,
                          child: Text('Calculadora', style: TextStyle(fontFamily: 'GothamRounded', fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgentesList(List<Map<String, dynamic>> agentesList) {
    // Si es el tab "Todos" (índice 0), mostrar la nueva sección
    if (_selectedCategory == 0) {
      return _buildTodosSection();
    }
    
    // Para otros tabs, mostrar la lista filtrada
    if (agentesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.white70,
              size: 64,
            ),
            SizedBox(height: 20),
            Text(
              'No hay agentes en esta categoría',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontFamily: 'Gotham Rounded',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: agentesList.length,
      itemBuilder: (context, index) {
        final agente = agentesList[index];
        return Container(
          margin: EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: agente['color'].withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header del agente
                Row(
                  children: [
                    // Imagen del agente
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          agente['imagen'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 15),
                    
                    // Información del agente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agente['nombre'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Gotham Rounded',
                            ),
                          ),
                          Text(
                            agente['tipo'],
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontFamily: 'Gotham Rounded',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Badge de logros
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        agente['logros'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Gotham Rounded',
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 15),
                
                // Descripción
                Text(
                  agente['descripcion'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                    fontFamily: 'Gotham Rounded',
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(22.5),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: Text(
                            'VER PERFIL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Gotham Rounded',
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 15),
                    
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22.5),
                        ),
                        child: Center(
                          child: Text(
                            'CONTACTAR',
                            style: TextStyle(
                              color: agente['color'],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Gotham Rounded',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

    // Nueva sección para el tab "Todos"
  Widget _buildTodosSection() {
    return Column(
        children: [
          // 1. Personajes-agentes como fondo + Cubitos + Texto-intro + Botón (z-index completo)
                    Expanded(
            child: Stack(
              children: [
                // Personajes-agentes como fondo (z-index abajo) - Subido 30px desde bottom
                Positioned(
                  bottom: 30,
                  left: 0, // Sin margen izquierdo - se pega al borde
                  right: 0, // Sin margen derecho - se pega al borde
                  child: Container(
                    width: double.infinity, // Ancho completo
                    child: Image.asset(
                      'assets/images/agentes/personajes-agentes.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                                  // Cubitos encima (z-index medio-bajo) - Bajado 20px
                  Positioned(
                    top: 20,
                    left: 0, // Sin margen izquierdo - se pega al borde
                    right: 0, // Sin margen derecho - se pega al borde
                    child: Container(
                      width: double.infinity, // Ancho completo
                      child: Image.asset(
                        'assets/images/agentes/cubitos.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                
                // Texto-intro encima de cubitos (z-index medio-alto) - Ancho reducido y subido 10px
                Positioned(
                  top: -10,
                  left: 30, // Reducido de 40 a 30
                  right: 30, // Reducido de 40 a 30
                  child: Container(
                    width: MediaQuery.of(context).size.width - 60, // Responsive
                    child: Image.asset(
                      'assets/images/agentes/texto-intro.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
        ],
      );
    }

  // Método para mostrar slide1.png
  Widget _buildSlide1() {
    return Transform.translate(
      offset: Offset(0, -20), // Mueve el contenedor 20px arriba
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        physics: AlwaysScrollableScrollPhysics(), // Permite overscroll de ~200px
        children: [
          SizedBox(height: 20),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/agentes/slide1.png',
                fit: BoxFit.contain, // Mantiene proporciones completas
              ),
            ),
          ),
          SizedBox(height: 20),
          // Nueva imagen agregada para la prueba
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/agentes/anty1.png',
                width: MediaQuery.of(context).size.width * 0.8, // 80% del ancho de pantalla
                fit: BoxFit.contain, // Mantiene proporciones completas
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // Método para mostrar slide2.png
  Widget _buildSlide2() {
    return Transform.translate(
      offset: Offset(0, -20), // Mueve el contenedor 20px arriba
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        physics: AlwaysScrollableScrollPhysics(), // Permite overscroll de ~200px
        children: [
          SizedBox(height: 20),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/agentes/slide2.png',
                fit: BoxFit.contain, // Mantiene proporciones completas
              ),
            ),
          ),
          SizedBox(height: 20),
          // Nueva imagen agregada para la prueba
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/agentes/anty2.png',
                width: MediaQuery.of(context).size.width * 0.8, // 80% del ancho de pantalla
                fit: BoxFit.contain, // Mantiene proporciones completas
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
