import 'package:flutter/material.dart';
import '../services/snippet_service.dart';
import '../widgets/snippet_overlay.dart';
import '../services/app_orientation_service.dart';

class GlobalSnippetWrapper extends StatefulWidget {
  final Widget child;
  
  const GlobalSnippetWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _GlobalSnippetWrapperState createState() => _GlobalSnippetWrapperState();
}

class _GlobalSnippetWrapperState extends State<GlobalSnippetWrapper> {
  SnippetOverlay? _currentSnippetOverlay;
  final SnippetService _snippetService = SnippetService();
  bool _snippetServiceStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeSnippetService();
  }

  void _initializeSnippetService() {
    // SNIPPETS DESACTIVADOS - Comentado para desactivar el sistema de snippets
    /*
    print('🎯 GlobalSnippetWrapper: Inicializando servicio de snippets');
    _snippetService.initialize((SnippetOverlay overlay) {
      print('🎯 GlobalSnippetWrapper: Recibiendo overlay de snippet');
      setState(() {
        _currentSnippetOverlay = overlay;
      });
    }, onClearSnippet: _clearSnippetOverlay);
    
    // Iniciar el timer de snippets después de un breve delay
    Future.delayed(Duration(seconds: 1), () {
      if (!_snippetServiceStarted) {
        print('🎯 GlobalSnippetWrapper: Iniciando timer de snippets');
        _snippetService.startAppTimer();
        _snippetServiceStarted = true;
      }
    });
    */
  }

  void _clearSnippetOverlay() {
    print('🎯 GlobalSnippetWrapper: Limpiando overlay de snippet');
    setState(() {
      _currentSnippetOverlay = null;
    });
  }

  @override
  void dispose() {
    _snippetService.stopAppTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscapeBlocked = MediaQuery.of(context).orientation == Orientation.landscape && !AppOrientationService().allowLandscape;
    return Stack(
      children: [
        // Contenido principal de la app
        widget.child,
        
        // Overlay de snippets (aparece encima de todo)
        if (_currentSnippetOverlay != null)
          Positioned.fill(
            child: _currentSnippetOverlay!,
          ),

        // Overlay de bloqueo de orientación (si no se permite landscape)
        if (isLandscapeBlocked)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/instrucciones/back-horizontal.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 280,
                      child: Image.asset(
                        'assets/images/instrucciones/aviso-horizontal.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.screen_rotation, color: Colors.white, size: 96);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

