import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_manager.dart';
import 'services/google_calendar_service.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'widgets/header_navigation.dart';
import 'widgets/bottom_navigation_menu.dart';

// Clase para usar en main_container.dart (sin submenu)
class EventosPage extends StatefulWidget {
  @override
  _EventosPageState createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  List<Evento> _eventos = [];
  List<Evento> _eventosFiltrados = [];
  bool _isLoading = true;
  GoogleCalendarService _calendarService = GoogleCalendarService();
  
  // Filtros y búsqueda
  String _busqueda = '';
  String _categoriaSeleccionada = 'Todas';
  List<String> _categorias = ['Todas', 'Reuniones', 'Campañas', 'Talleres', 'Eventos Sociales', 'Asambleas', 'General'];
  
  // Controladores
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadEventos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadEventos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener eventos desde PHP
      final eventos = await _calendarService.getEventos();
      
      setState(() {
        _eventos = eventos;
        _aplicarFiltros();
        _isLoading = false;
      });
      
      print('Eventos cargados: ${eventos.length}');
    } catch (e) {
      print('Error cargando eventos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    _eventosFiltrados = _eventos.where((evento) {
      // Filtro por búsqueda
      bool coincideBusqueda = _busqueda.isEmpty ||
          evento.titulo.toLowerCase().contains(_busqueda.toLowerCase()) ||
          evento.descripcion.toLowerCase().contains(_busqueda.toLowerCase()) ||
          evento.ubicacion.toLowerCase().contains(_busqueda.toLowerCase());
      
      // Filtro por categoría
      bool coincideCategoria = _categoriaSeleccionada == 'Todas' ||
          evento.categoria == _categoriaSeleccionada;
      
      return coincideBusqueda && coincideCategoria;
    }).toList();
    
    // Ordenar por fecha
    _eventosFiltrados.sort((a, b) {
      if (a.fechaInicio == null && b.fechaInicio == null) return 0;
      if (a.fechaInicio == null) return 1;
      if (b.fechaInicio == null) return -1;
      return a.fechaInicio!.compareTo(b.fechaInicio!);
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha no especificada';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final eventDate = DateTime(date.year, date.month, date.day);
    
    if (eventDate == today) {
      return 'Hoy';
    } else if (eventDate == tomorrow) {
      return 'Mañana';
    } else {
      return DateFormat('EEEE, d MMMM', 'es_ES').format(date);
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Hora no especificada';
    return DateFormat('HH:mm').format(date);
  }

  Color _getCategoriaColor(String categoria) {
    switch (categoria) {
      case 'Reuniones':
        return Colors.blue;
      case 'Campañas':
        return Colors.green;
      case 'Talleres':
        return Colors.orange;
      case 'Eventos Sociales':
        return Colors.purple;
      case 'Asambleas':
        return Colors.red;
      case 'General':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            // Header con título y botón de regreso
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Eventos y Campañas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Barra de búsqueda
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar eventos...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _busqueda = value;
                    _aplicarFiltros();
                  });
                },
              ),
            ),
            
            SizedBox(height: 16),
            
            // Filtros por categoría
            Container(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categorias.length,
                itemBuilder: (context, index) {
                  final categoria = _categorias[index];
                  final isSelected = categoria == _categoriaSeleccionada;
                  
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        categoria,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: _getCategoriaColor(categoria),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      onSelected: (selected) {
                        setState(() {
                          _categoriaSeleccionada = categoria;
                          _aplicarFiltros();
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: 16),
            
            // Contenido principal
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _eventosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              SizedBox(height: 16),
                              Text(
                                _busqueda.isNotEmpty || _categoriaSeleccionada != 'Todas'
                                    ? 'No se encontraron eventos'
                                    : 'No hay eventos próximos',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Intenta ajustar los filtros',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadEventos,
                          color: Colors.white,
                          backgroundColor: Color(0xFF1E1E1E),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _eventosFiltrados.length,
                            itemBuilder: (context, index) {
                              return _buildEventoCard(_eventosFiltrados[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventoCard(Evento evento) {
    final categoriaColor = _getCategoriaColor(evento.categoria);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoriaColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con categoría y fecha
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoriaColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    evento.categoria,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  _formatDate(evento.fechaInicio),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Título
            Text(
              evento.titulo,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 8),
            
            // Descripción
            if (evento.descripcion.isNotEmpty)
              Text(
                evento.descripcion,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            
            SizedBox(height: 12),
            
            // Información adicional
            Row(
              children: [
                // Hora
                if (!evento.esTodoElDia && evento.fechaInicio != null) ...[
                  Icon(
                    Icons.access_time,
                    color: Colors.white.withOpacity(0.6),
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatTime(evento.fechaInicio),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 16),
                ],
                
                // Ubicación
                if (evento.ubicacion.isNotEmpty) ...[
                  Icon(
                    Icons.location_on,
                    color: Colors.white.withOpacity(0.6),
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      evento.ubicacion,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            
            // Indicador de todo el día
            if (evento.esTodoElDia)
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Todo el día',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Clase completa con submenu para usar directamente
class EventosScreen extends StatefulWidget {
  @override
  _EventosScreenState createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> with TickerProviderStateMixin {
  List<Evento> _eventos = [];
  List<Evento> _eventosFiltrados = [];
  bool _isLoading = true;
  GoogleCalendarService _calendarService = GoogleCalendarService();
  
  // Filtros y búsqueda
  String _busqueda = '';
  String _categoriaSeleccionada = 'Todas';
  List<String> _categorias = ['Todas', 'Reuniones', 'Campañas', 'Talleres', 'Eventos Sociales', 'Asambleas', 'General'];
  
  // Controladores
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();
  
  // Submenu state
  bool _isSubmenuVisible = false;
  late AnimationController _submenuAnimationController;
  late Animation<Offset> _submenuSlideAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
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
    
    _loadEventos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _submenuAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadEventos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener eventos desde PHP
      final eventos = await _calendarService.getEventos();
      
      setState(() {
        _eventos = eventos;
        _aplicarFiltros();
        _isLoading = false;
      });
      
      print('Eventos cargados: ${eventos.length}');
    } catch (e) {
      print('Error cargando eventos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    _eventosFiltrados = _eventos.where((evento) {
      // Filtro por búsqueda
      bool coincideBusqueda = _busqueda.isEmpty ||
          evento.titulo.toLowerCase().contains(_busqueda.toLowerCase()) ||
          evento.descripcion.toLowerCase().contains(_busqueda.toLowerCase()) ||
          evento.ubicacion.toLowerCase().contains(_busqueda.toLowerCase());
      
      // Filtro por categoría
      bool coincideCategoria = _categoriaSeleccionada == 'Todas' ||
          evento.categoria == _categoriaSeleccionada;
      
      return coincideBusqueda && coincideCategoria;
    }).toList();
    
    // Ordenar por fecha
    _eventosFiltrados.sort((a, b) {
      if (a.fechaInicio == null && b.fechaInicio == null) return 0;
      if (a.fechaInicio == null) return 1;
      if (b.fechaInicio == null) return -1;
      return a.fechaInicio!.compareTo(b.fechaInicio!);
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha no especificada';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final eventDate = DateTime(date.year, date.month, date.day);
    
    if (eventDate == today) {
      return 'Hoy';
    } else if (eventDate == tomorrow) {
      return 'Mañana';
    } else {
      return DateFormat('EEEE, d MMMM', 'es_ES').format(date);
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Hora no especificada';
    return DateFormat('HH:mm').format(date);
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

  Color _getCategoriaColor(String categoria) {
    switch (categoria) {
      case 'Reuniones':
        return Colors.blue;
      case 'Campañas':
        return Colors.green;
      case 'Talleres':
        return Colors.orange;
      case 'Eventos Sociales':
        return Colors.purple;
      case 'Asambleas':
        return Colors.red;
      case 'General':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            // Contenido principal
            SafeArea(
              child: Column(
                children: [
                  // Header de navegación reutilizable
                  HeaderNavigation(
                    onMenuTap: () {
                      Navigator.pushNamed(context, '/menu');
                    },
                    title: 'BIENVENIDOS',
                    subtitle: 'EVENTOS Y\nCAMPAÑAS',
                  ),
                  
                  // Barra de búsqueda
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar eventos...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _busqueda = value;
                          _aplicarFiltros();
                        });
                      },
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Filtros por categoría
                  Container(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categorias.length,
                      itemBuilder: (context, index) {
                        final categoria = _categorias[index];
                        final isSelected = categoria == _categoriaSeleccionada;
                        
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              categoria,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: _getCategoriaColor(categoria),
                            backgroundColor: Colors.white.withOpacity(0.1),
                            onSelected: (selected) {
                              setState(() {
                                _categoriaSeleccionada = categoria;
                                _aplicarFiltros();
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Contenido principal
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : _eventosFiltrados.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 64,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      _busqueda.isNotEmpty || _categoriaSeleccionada != 'Todas'
                                          ? 'No se encontraron eventos'
                                          : 'No hay eventos próximos',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Intenta ajustar los filtros',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadEventos,
                                color: Colors.white,
                                backgroundColor: Color(0xFF1E1E1E),
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _eventosFiltrados.length,
                                  itemBuilder: (context, index) {
                                    return _buildEventoCard(_eventosFiltrados[index]);
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            ),
            
            // Submenu (se muestra cuando se activa)
            if (_isSubmenuVisible) _buildEventosSubmenu(),
            
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

  Widget _buildEventoCard(Evento evento) {
    final categoriaColor = _getCategoriaColor(evento.categoria);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoriaColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con categoría y fecha
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoriaColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    evento.categoria,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  _formatDate(evento.fechaInicio),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Título
            Text(
              evento.titulo,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 8),
            
            // Descripción
            if (evento.descripcion.isNotEmpty)
              Text(
                evento.descripcion,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            
            SizedBox(height: 12),
            
            // Información adicional
            Row(
              children: [
                // Hora
                if (!evento.esTodoElDia && evento.fechaInicio != null) ...[
                  Icon(
                    Icons.access_time,
                    color: Colors.white.withOpacity(0.6),
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatTime(evento.fechaInicio),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 16),
                ],
                
                // Ubicación
                if (evento.ubicacion.isNotEmpty) ...[
                  Icon(
                    Icons.location_on,
                    color: Colors.white.withOpacity(0.6),
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      evento.ubicacion,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            
            // Indicador de todo el día
            if (evento.esTodoElDia)
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Todo el día',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventosSubmenu() {
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
                  'Herramientas de Eventos',
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
                          onTap: () { 
                            print('Navegar a calendario'); 
                          },
                          child: Image.asset('assets/images/submenu/btn-juego.png', height: 156),
                        ),
                        SizedBox(width: 9),
                        GestureDetector(
                          onTap: () { 
                            print('Navegar a recordatorios'); 
                          },
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
                          child: Text('Calendario', style: TextStyle(fontFamily: 'GothamRounded', fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        ),
                        SizedBox(width: 9),
                        SizedBox(
                          width: 150,
                          child: Text('Recordatorios', style: TextStyle(fontFamily: 'GothamRounded', fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
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
}
