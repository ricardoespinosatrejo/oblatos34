import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'menu.dart';
import 'services/snippet_service.dart';
import 'user_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oblatos 34',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Gotham Rounded',
      ),
      home: const InicioPage(),
    );
  }
}

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  // Controladores para los campos de texto
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _nombreCompletoController = TextEditingController();
  final TextEditingController _nombrePadreMadreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Focus nodes para manejar el foco
  final FocusNode _usuarioFocusNode = FocusNode();
  final FocusNode _nombreCompletoFocusNode = FocusNode();
  final FocusNode _nombrePadreMadreFocusNode = FocusNode();
  final FocusNode _telefonoFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Variables de estado
  String _selectedRangoEdad = '9-12';
  bool _showCrearCuentaForm = false;
  bool _showLoginForm = false;
  bool _showRecuperarPasswordForm = false;
  bool _usuarioYaExiste = false;
  bool _emailYaExiste = false;

  // Clave del formulario
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pausar snippets durante registro/login
    try {
      SnippetService().setGameOrCalculatorActive(true);
      print('🛑 Snippets pausados en pantalla de inicio/auth');
    } catch (e) {
      print('No se pudo pausar snippets en inicio: $e');
    }
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _nombreCompletoController.dispose();
    _nombrePadreMadreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usuarioFocusNode.dispose();
    _nombreCompletoFocusNode.dispose();
    _nombrePadreMadreFocusNode.dispose();
    _telefonoFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    try {
      SnippetService().setGameOrCalculatorActive(false);
      print('▶️ Snippets reanudados al salir de inicio/auth');
    } catch (e) {
      print('No se pudo reanudar snippets al salir de inicio: $e');
    }
    super.dispose();
  }

  // Verificar si el usuario ya existe
  Future<void> _verificarUsuarioExistente(String usuario) async {
    if (usuario.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/verificar_usuario.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre_usuario': usuario}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['existe'] == true) {
          setState(() {
            _usuarioYaExiste = true;
          });
          // Limpiar el campo
          _usuarioController.clear();
          _usuarioFocusNode.requestFocus();
        } else {
          setState(() {
            _usuarioYaExiste = false;
          });
        }
      }
    } catch (e) {
      print('Error verificando usuario: $e');
    }
  }

  // Verificar si el email ya existe
  Future<void> _verificarEmailExistente(String email) async {
    if (email.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/verificar_email.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['existe'] == true) {
          setState(() {
            _emailYaExiste = true;
          });
          // Limpiar el campo
          _emailController.clear();
          _emailFocusNode.requestFocus();
        } else {
          setState(() {
            _emailYaExiste = false;
          });
        }
      }
    } catch (e) {
      print('Error verificando email: $e');
    }
  }

  // Crear cuenta
  Future<void> _crearCuenta() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        },
      );

      final Map<String, dynamic> userData = {
        'nombre_usuario': _usuarioController.text.trim(),
        'nombre_menor': _nombreCompletoController.text.trim(),
        'rango_edad': _selectedRangoEdad,
        'nombre_padre_madre': _nombrePadreMadreController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'password': _passwordController.text,
      };

      print('Enviando datos de registro: $userData');

      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/registro.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      // Cerrar indicador de carga
      Navigator.of(context).pop();

      print('Respuesta de registro: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          // Registro exitoso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Usuario registrado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Guardar información completa del usuario después del registro
          final userManager = Provider.of<UserManager>(context, listen: false);
          
          // Si el registro devuelve información del usuario, usarla
          if (responseData['usuario'] != null) {
            userManager.setCurrentUser(responseData['usuario']);
          } else {
            // Si no devuelve el usuario completo, intentar hacer login para obtener datos completos
            await _loginAfterRegistration(_usuarioController.text.trim(), _passwordController.text, userManager);
          }
          
          // NUEVO: Otorgar puntos de sesión diaria a usuarios nuevos desde el primer registro
          await _actualizarSesionDiaria(userManager);
          
          // Reanudar snippets y navegar al menú
          try { SnippetService().setGameOrCalculatorActive(false); } catch (_) {}
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          // Error en el registro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Error al registrar usuario'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Error de conexión
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      print('Error en el registro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error en el registro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Login automático después del registro para obtener datos completos
  Future<void> _loginAfterRegistration(String username, String password, UserManager userManager) async {
    try {
      final Map<String, dynamic> loginData = {
        'nombre_usuario': username,
        'password': password,
      };

      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true && responseData['usuario'] != null) {
          // Guardar información completa del usuario
          userManager.setCurrentUser(responseData['usuario']);
          print('✅ Usuario registrado y datos completos obtenidos: ${responseData['usuario']['id']}');
        } else {
          print('❌ Error obteniendo datos completos después del registro');
          // Crear usuario temporal como fallback
          final Map<String, dynamic> tempUser = {
            'id': 0, // Esto causará problemas, pero es mejor que nada
            'nombre_usuario': username,
            'puntos': 0,
            'profile_image': 1,
          };
          userManager.setCurrentUser(tempUser);
        }
      }
    } catch (e) {
      print('❌ Error en login automático después del registro: $e');
      // Crear usuario temporal como fallback
      final Map<String, dynamic> tempUser = {
        'id': 0, // Esto causará problemas, pero es mejor que nada
        'nombre_usuario': username,
        'puntos': 0,
        'profile_image': 1,
      };
      userManager.setCurrentUser(tempUser);
    }
  }

  // Actualizar sesión diaria automáticamente
  Future<void> _actualizarSesionDiaria(UserManager userManager) async {
    try {
      final user = userManager.currentUser;
      if (user == null || user['id'] == null || user['id'] == 0) {
        print('❌ No se puede actualizar sesión diaria: user_id inválido (${user?['id']})');
        return;
      }

      print('🎯 Intentando actualizar sesión diaria para user_id: ${user['id']}');

      // Llamar al backend para actualizar sesión diaria
      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/update_points.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user['id'],
          'action': 'sesion_diaria'
        }),
      );

      print('🎯 Respuesta sesión diaria: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          // Actualizar UserManager con los nuevos datos
          userManager.updateSesionDiaria();
          print('✅ Sesión diaria actualizada automáticamente - puntos: ${responseData['data']['puntos']}');
        } else {
          print('❌ Error en respuesta de sesión diaria: ${responseData['error']}');
        }
      } else {
        print('❌ Error HTTP actualizando sesión diaria: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error actualizando sesión diaria: $e');
    }
  }

  // Hacer login
  Future<void> _hacerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        },
      );

      final Map<String, dynamic> loginData = {
        'nombre_usuario': _usuarioController.text.trim(),
        'password': _passwordController.text,
      };

      print('Enviando datos de login: $loginData');

      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );

      // Cerrar indicador de carga
      Navigator.of(context).pop();

      print('Respuesta de login: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          // Login exitoso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Login exitoso'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Guardar información del usuario
          final userManager = Provider.of<UserManager>(context, listen: false);
          userManager.setCurrentUser(responseData['usuario']);
          
          // NUEVO: Actualizar sesión diaria automáticamente al hacer login
          await _actualizarSesionDiaria(userManager);
          
          // Reanudar snippets y navegar al menú
          try { SnippetService().setGameOrCalculatorActive(false); } catch (_) {}
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          // Error en el login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Error en el login'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Error de conexión
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      print('Error en el login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error en el login'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Recuperar password
  Future<void> _recuperarPassword() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        },
      );

      final Map<String, dynamic> recoveryData = {
        'email': _emailController.text.trim(),
      };
      
      print('Enviando solicitud de recuperación: $recoveryData');
      
      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/recuperar_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(recoveryData),
      );
      
      // Cerrar indicador de carga
      Navigator.of(context).pop();
      
      print('Respuesta de recuperación: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          // Recuperación exitosa
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Password recuperado'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Cerrar el modal
          _closeRecuperarPasswordForm();
        } else {
          // Error en la recuperación
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Error al recuperar password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Error de conexión
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      print('Error en la recuperación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al recuperar password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Cerrar formulario de crear cuenta
  void _closeCrearCuentaForm() {
    setState(() {
      _showCrearCuentaForm = false;
      _usuarioYaExiste = false;
      _emailYaExiste = false;
    });
    _usuarioController.clear();
    _nombreCompletoController.clear();
    _nombrePadreMadreController.clear();
    _telefonoController.clear();
    _emailController.clear();
    _passwordController.clear();
    _selectedRangoEdad = '9-12';
  }

  // Cerrar formulario de login
  void _closeLoginForm() {
    setState(() {
      _showLoginForm = false;
    });
    _usuarioController.clear();
    _passwordController.clear();
  }

  // Cerrar formulario de recuperar password
  void _closeRecuperarPasswordForm() {
    setState(() {
      _showRecuperarPasswordForm = false;
    });
    _emailController.clear();
  }

  // Abrir formulario de recuperar password
  void _openRecuperarPasswordForm() {
    setState(() {
      _showRecuperarPasswordForm = true;
    });
  }

  // Widget helper para radio buttons horizontales de edad
  Widget _buildHorizontalRadioButton(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            unselectedWidgetColor: Colors.white.withValues(alpha: 0.5),
          ),
          child: Radio<String>(
            value: value,
            groupValue: _selectedRangoEdad,
            onChanged: (String? newValue) {
              setState(() {
                _selectedRangoEdad = newValue!;
              });
            },
            activeColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
                            // Contenido principal con Stack para z-index
              Stack(
                children: [
                  // Imagen de fondo (z-index más bajo)
                  Positioned(
                    top: 25,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      child: Opacity(
                        opacity: _showCrearCuentaForm || _showLoginForm ? 0.6 : 1.0, // 60% si hay formularios, 100% si no
                        child: Image.asset(
                          'assets/images/1inicio/home.png',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  
                  // Contenido principal (z-index más alto)
                  Column(
                    children: [
                      // Espacio para la imagen
                      const SizedBox(height: 0),
                      
                      // Botones principales en la parte inferior
                      if (!_showCrearCuentaForm && !_showLoginForm) ...[
                        const Spacer(),
                        // Fila de botones
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Botón "Soy nuevo"
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showCrearCuentaForm = true;
                                  });
                                },
                                child: Container(
                                  width: 160,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Soy nuevo',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Botón "Soy usuario"
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showLoginForm = true;
                                  });
                                },
                                child: Container(
                                  width: 160,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [Color(0xFFFF1744), Color(0xFFE91E63)],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Soy usuario',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                      
                      // Formulario de crear cuenta
                      if (_showCrearCuentaForm) _buildCrearCuentaForm(),
                      
                      // Formulario de login
                      if (_showLoginForm) ...[
                        const SizedBox(height: 100),
                        _buildLoginForm(),
                      ],
                      
                      // Formulario de recuperar password
                      if (_showRecuperarPasswordForm) _buildRecuperarPasswordForm(),
                    ],
                  ),
                ],
              ),
              
              // Submenu eliminado en inicio
            ],
          ),
        ),
      ),
    );
  }

  // Formulario de crear cuenta
  Widget _buildCrearCuentaForm() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height - 150, // Altura restaurada ya que no hay overlap
      decoration: BoxDecoration(
        color: const Color(0xFF161351).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del formulario
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Crear cuenta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: _closeCrearCuentaForm,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Campo Usuario
            TextFormField(
              controller: _usuarioController,
              focusNode: _usuarioFocusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Usuario',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.person, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                errorText: _usuarioYaExiste ? 'Usuario ya existe' : null,
                errorStyle: const TextStyle(fontSize: 12, height: 0.05),
              ),
              onChanged: (value) {
                if (_usuarioYaExiste) {
                  setState(() {
                    _usuarioYaExiste = false;
                  });
                }
                _verificarUsuarioExistente(value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Usuario requerido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Campo Nombre completo
            TextFormField(
              controller: _nombreCompletoController,
              focusNode: _nombreCompletoFocusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre completo del menor',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.child_care, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nombre completo requerido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Campo Rango de edad
            Row(
              children: [
                const Icon(Icons.cake, color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Edad:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHorizontalRadioButton('9-12', '9-12'),
                const SizedBox(width: 20),
                _buildHorizontalRadioButton('13-15', '13-15'),
                const SizedBox(width: 20),
                _buildHorizontalRadioButton('15-17', '15-17'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Campo Nombre del padre o madre
            TextFormField(
              controller: _nombrePadreMadreController,
              focusNode: _nombrePadreMadreFocusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre del papá o mamá',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.family_restroom, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nombre del padre o madre requerido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Campo Email
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.email, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                errorText: _emailYaExiste ? 'Email ya existe' : null,
                errorStyle: const TextStyle(fontSize: 12, height: 0.05),
              ),
              onChanged: (value) {
                if (_emailYaExiste) {
                  setState(() {
                    _emailYaExiste = false;
                  });
                }
                _verificarEmailExistente(value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email requerido';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Campo Teléfono
            TextFormField(
              controller: _telefonoController,
              focusNode: _telefonoFocusNode,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.phone, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Teléfono requerido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Campo Password
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password requerido';
                }
                if (value.length < 6) {
                  return 'Password debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 30),
            
            // Botón Crear cuenta
            GestureDetector(
              onTap: _crearCuenta,
              child: Container(
                width: 300,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFFFF1744), Color(0xFFE91E63)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Crear cuenta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Formulario de login
  Widget _buildLoginForm() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161351).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del formulario
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: _closeLoginForm,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Campo Usuario
            TextFormField(
              controller: _usuarioController,
              focusNode: _usuarioFocusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Usuario',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.person, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Usuario requerido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Campo Password
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password requerido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Botón ¿Olvidaste tu password?
            GestureDetector(
              onTap: _openRecuperarPasswordForm,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Text(
                  '¿Olvidaste tu password?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Botón Login
            GestureDetector(
              onTap: _hacerLogin,
              child: Container(
                width: 300,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFFFF1744), Color(0xFFE91E63)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Formulario de recuperar password
  Widget _buildRecuperarPasswordForm() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161351).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del formulario
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recuperar\nPassword',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                GestureDetector(
                  onTap: _closeRecuperarPasswordForm,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Descripción
            const Text(
              'Ingresa tu email y te enviaremos un password temporal',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 30),
            
            // Campo Email
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.email, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email requerido';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 30),
            
            // Botón Enviar
            GestureDetector(
              onTap: _recuperarPassword,
              child: Container(
                width: 300,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFFFF1744), Color(0xFFE91E63)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Enviar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
