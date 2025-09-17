import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../user_manager.dart';
import '../services/snippet_service.dart';

class CalculadoraScreen extends StatefulWidget {
  @override
  _CalculadoraScreenState createState() => _CalculadoraScreenState();
}

class _CalculadoraScreenState extends State<CalculadoraScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Controladores de texto
  final TextEditingController _deseoController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _ahorroController = TextEditingController();
  
  // Variables del estado
  String _frecuencia = 'por semana';
  bool _mostrarResultado = false;
  Map<String, dynamic> _resultado = {};
  
  @override
  void initState() {
    super.initState();
    
    // Desactivar snippets durante la calculadora
    SnippetService().setGameOrCalculatorActive(true);
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    _deseoController.dispose();
    _valorController.dispose();
    _ahorroController.dispose();
    
    // Reactivar snippets al salir de la calculadora
    SnippetService().setGameOrCalculatorActive(false);
    
    super.dispose();
  }
  
  void _calcularTiempo() {
    final valor = double.tryParse(_valorController.text) ?? 0;
    final ahorro = double.tryParse(_ahorroController.text) ?? 0;
    final deseo = _deseoController.text.trim();
    
    if (valor <= 0 || ahorro <= 0 || deseo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor completa todos los campos correctamente'),
          backgroundColor: Color(0xFFE91E63),
        ),
      );
      return;
    }
    
    // Calcular tiempo según frecuencia
    double tiempoEnDias;
    String unidadTiempo;
    
    switch (_frecuencia) {
      case 'por día':
        tiempoEnDias = valor / ahorro;
        unidadTiempo = tiempoEnDias < 30 ? 'días' : 'meses';
        break;
      case 'por semana':
        tiempoEnDias = (valor / ahorro) * 7;
        unidadTiempo = tiempoEnDias < 30 ? 'días' : 'meses';
        break;
      case 'por mes':
        tiempoEnDias = (valor / ahorro) * 30;
        unidadTiempo = 'meses';
        break;
      default:
        tiempoEnDias = (valor / ahorro) * 7;
        unidadTiempo = tiempoEnDias < 30 ? 'días' : 'meses';
    }
    
    // Convertir a la unidad más apropiada
    double tiempoFinal;
    if (unidadTiempo == 'meses') {
      tiempoFinal = tiempoEnDias / 30;
    } else {
      tiempoFinal = tiempoEnDias;
    }
    
    // Calcular progreso (asumiendo que ya tiene algo ahorrado)
    double progreso = 0.0; // Por defecto 0%, se puede modificar después
    
    setState(() {
      _resultado = {
        'deseo': deseo,
        'valor': valor,
        'ahorro': ahorro,
        'frecuencia': _frecuencia,
        'tiempo': tiempoFinal.round(),
        'unidad': unidadTiempo,
        'progreso': progreso,
      };
      _mostrarResultado = true;
    });
  }
  
  void _resetearCalculadora() {
    setState(() {
      _mostrarResultado = false;
      _deseoController.clear();
      _valorController.clear();
      _ahorroController.clear();
      _frecuencia = 'por semana';
    });
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Contenedor con imagen de fondo para la sección de la calculadora
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(minHeight: 400),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(_mostrarResultado 
                              ? 'assets/images/calculadora/fondo-calculadora2.png'
                              : 'assets/images/calculadora/fondo-calculadora.png'),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(top: 266, left: 16, right: 16, bottom: 16),
                          child: Column(
                            children: [
                              if (!_mostrarResultado) ...[
                                _buildFormulario(),
                              ] else ...[
                                _buildResultados(),
                              ],
                            ],
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
    return Container(
      height: 120,
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
                  'BIENVENIDOS',
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
                  'CALCULADORA',
                  style: TextStyle(
                    fontFamily: 'Gryzensa',
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.white70,
                    height: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Botón de regreso (izquierda)
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
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
          ),
          
          // Perfil de usuario (derecha)
          Positioned(
            right: 0,
            top: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    // Reproducir audio antes de navegar
                    try {
                      final audioPlayer = AudioPlayer();
                      await audioPlayer.play(AssetSource('audios/perfil.mp3'));
                      // Esperar un poco para que se escuche el audio
                      await Future.delayed(Duration(milliseconds: 200));
                      audioPlayer.dispose();
                    } catch (e) {
                      // Si hay error con el audio, continuar con la navegación
                      print('Error reproduciendo audio: $e');
                    }
                    
                    Navigator.pushNamed(context, '/perfil');
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFFE91E63), 
                        width: 2
                      ),
                      color: Colors.white,
                    ),
                    child: Stack(
                      children: [
                        // Foto de perfil o imagen por defecto
                        Center(
                          child: ClipOval(
                            child: Consumer<UserManager>(
                              builder: (context, userManager, child) {
                                final profileImage = userManager.currentUser?['profile_image'] ?? 1;
                                return Image.asset(
                                  'assets/images/perfil/perfil$profileImage.png',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Si falla, mostrar imagen por defecto
                                    return Image.asset(
                                      'assets/images/1inicio/perfil.png',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                );
                              },
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
  
  Widget _buildHeaderCalculadora() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 25, horizontal: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  '✨ Calculadora de Deseos ✨',
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.star, color: Colors.white, size: 18),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Aprende a ahorrar para conseguir lo que quieres',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 14,
              color: Color(0xFF8B4513),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFormulario() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo: ¿Qué deseas comprar?
          Text(
            '¿Qué deseas comprar?',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E88A8),
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _deseoController,
            decoration: InputDecoration(
              hintText: 'Ej: Un juguete nuevo, un libro...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF4CAF50)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Campo: Costo de lo que deseas
          Text(
            'Costo de lo que deseas',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E88A8),
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _valorController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF4CAF50)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Campo: Cuánto dinero puedes ahorrar
          Text(
            'Cuánto dinero puedes ahorrar',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E88A8),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _ahorroController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF4CAF50)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _frecuencia,
                      isExpanded: true,
                      isDense: true,
                      items: ['por día', 'por semana', 'por mes'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              value,
                              style: TextStyle(
                                fontFamily: 'Gotham Rounded',
                                fontSize: 12,
                                color: Color(0xFF6E88A8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _frecuencia = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 30),
          
          // Botón calcular
          GestureDetector(
            onTap: _calcularTiempo,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF9C27B0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Calcular Tiempo',
                  style: TextStyle(
                    fontFamily: 'Gotham Rounded',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultados() {
    return Column(
      children: [
        // Resultados principales
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Espacio superior (icono de moneda removido)
              SizedBox(height: 8),
              
              // Detalles del deseo
              Text(
                'Tu deseo: ${_resultado['deseo']}',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              
              SizedBox(height: 8),
              
              Text(
                'Valor: ${_resultado['valor'].toStringAsFixed(0)} monedas',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 8),
              
              Text(
                'Ahorro: ${_resultado['ahorro'].toStringAsFixed(0)} cada ${_resultado['frecuencia']}',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 20),
              
              Text(
                'Necesitas ahorrar durante ${_resultado['tiempo']} ${_resultado['unidad']}',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Mensaje motivacional
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB85BF3), Color(0xFFE35BF3)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '¡Tu esfuerzo vale la pena! En ${_resultado['tiempo']} ${_resultado['unidad']} disfrutarás de tu deseo 🎁',
            style: TextStyle(
              fontFamily: 'Gotham Rounded',
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
        
        SizedBox(height: 30),
        
        // Botón para nueva calculación
        GestureDetector(
          onTap: _resetearCalculadora,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFE91E63).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Nuevo Cálculo',
                style: TextStyle(
                  fontFamily: 'Gotham Rounded',
                  fontSize: 18,
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
}






