import 'package:flutter/material.dart';

class AnimatedProfileImage extends StatefulWidget {
  final int profileImage;
  final Widget imageWidget;

  const AnimatedProfileImage({
    Key? key,
    required this.profileImage,
    required this.imageWidget,
  }) : super(key: key);

  @override
  _AnimatedProfileImageState createState() => _AnimatedProfileImageState();
}

class _AnimatedProfileImageState extends State<AnimatedProfileImage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Widget? _previousWidget;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _controller.value = 1.0; // Iniciar con animación completa para mostrar la imagen inicial
    _previousWidget = widget.imageWidget;
    
    // Listener para limpiar imagen anterior después de la animación
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
          _previousWidget = null;
        });
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileImage != widget.profileImage) {
      _previousWidget = oldWidget.imageWidget;
      _isAnimating = true;
      _controller.reset(); // Resetear la animación
      _controller.forward(); // Iniciar animación
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Imagen anterior que sale hacia la derecha (de izquierda a derecha)
        if (_previousWidget != null && _isAnimating)
          SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: Offset(1.5, 0.0), // Sale completamente hacia la derecha
            ).animate(CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInCubic, // Curva más rápida para salida
            )),
            child: _previousWidget,
          ),
        // Nueva imagen que entra desde la derecha hacia la izquierda
        SlideTransition(
          position: Tween<Offset>(
            begin: Offset(1.5, 0.0), // Comienza completamente fuera de la pantalla a la derecha
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic, // Curva más suave para entrada
          )),
          child: KeyedSubtree(
            key: ValueKey<int>(widget.profileImage),
            child: widget.imageWidget,
          ),
        ),
      ],
    );
  }
}

