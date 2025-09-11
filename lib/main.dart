import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'inicio.dart';
import 'bienvenida.dart';
import 'main_container.dart';
import 'caja_correcto.dart' as caja;
import 'poder.dart' as poder;
import 'aprendiendo.dart' as aprendiendo;
import 'agentes.dart' as agentes;
import 'eventos.dart';
import 'videoblog.dart' as videoblog;
import 'perfil.dart';
import 'juego.dart';
import 'calculadora.dart';
import 'user_manager.dart';
import 'widgets/global_snippet_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar datos de localización para español
  await initializeDateFormatting('es_ES', null);
  // Android: Modo inmersivo (oculta barra del sistema; aparece con swipe)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserManager(),
      child: MaterialApp(
        title: 'Caja Oblatos - Bienvenida',
        theme: ThemeData(
          primarySwatch: Colors.red,
          fontFamily: 'GothamRounded',
          scaffoldBackgroundColor: Color(0xFF0A0E21),
        ),
        home: BienvenidaPage(),
        builder: (context, child) {
          return GlobalSnippetWrapper(
            child: child!,
          );
        },
        routes: {
          '/home': (context) => InicioPage(),
          // Rutas directas a cada pantalla para evitar menú duplicado
          '/menu': (context) => MainContainer(initialRoute: '/menu'),
          '/caja': (context) => caja.CajaScreen(),
          '/poder-cooperacion': (context) => poder.PoderCooperacionScreen(),
          '/aprendiendo-cooperativa': (context) => aprendiendo.AprendiendoCooperativaScreen(),
          '/agentes-cambio': (context) => agentes.AgentesCambioScreen(),
          '/eventos': (context) => EventosPage(),
          '/video-blog': (context) => videoblog.VideoBlogScreen(),
          '/perfil': (context) => PerfilScreen(),
          '/juego': (context) => GameScreen(),
          '/calculadora': (context) => CalculadoraScreen(),
        },
        onGenerateRoute: (settings) {
          // Transición personalizada de izquierda a derecha para ir al menú
          if (settings.name == '/menu') {
            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) => MainContainer(initialRoute: '/menu'),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0); // Comienza desde la derecha
                const end = Offset.zero; // Termina en el centro
                const curve = Curves.easeInOutCubic;
                
                var tween = Tween(begin: begin, end: end).chain(
                  CurveTween(curve: curve),
                );
                
                var offsetAnimation = animation.drive(tween);
                
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
              transitionDuration: Duration(milliseconds: 400),
            );
          }
          return null;
        },
      ),
    );
  }
}

// Clase HomeScreen duplicada eliminada - se usa la de menu.dart