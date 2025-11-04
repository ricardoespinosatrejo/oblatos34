import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/snippet_overlay.dart';

class SnippetService {
  static final SnippetService _instance = SnippetService._internal();
  factory SnippetService() => _instance;
  SnippetService._internal();
  
  // Intervalo fijo de 2 minutos (120 segundos) entre snippets
  static const int _snippetInterval = 120; // 2 minutos en segundos
  
  Timer? _appTimer;
  int _currentSnippetIndex = 0;
  bool _isActive = false;
  bool _isGameOrCalculatorActive = false;
  bool _hasActiveSnippet = false; // Para evitar acumulación de snippets
  
  // Callback para mostrar el overlay
  Function(SnippetOverlay)? _onShowSnippet;
  // Callback para limpiar el overlay
  Function()? _onClearSnippet;
  // OverlayEntry global para aparecer encima de todo
  OverlayEntry? _overlayEntry;
  
  // Lista de snippets ya mostrados hoy (para evitar repeticiones)
  List<String> _shownSnippetsToday = [];
  
  // Lista completa de snippets disponibles
  final List<String> _availableSnippets = [
    'snippet-01.png',
    'snippet-02.png',
    'snippet-03.png',
    'snippet-04.png',
    'snippet-05.png',
    'snippet-06.png',
    'snippet-07.png',
    'snippet-08.png',
    'snippet-09.png',
    'snippet-10.png',
    'snippet-11.png',
    'snippet-12.png',
  ];
  
  void initialize(Function(SnippetOverlay) onShowSnippet, {Function()? onClearSnippet, BuildContext? context}) {
    print('🎯 SnippetService: Inicializando servicio de snippets');
    _onShowSnippet = onShowSnippet;
    _onClearSnippet = onClearSnippet;
    _resetDailyData();
    print('🎯 SnippetService: Servicio inicializado correctamente');
  }
  
  void startAppTimer() {
    if (_isActive) {
      print('🎯 SnippetService: Timer ya está activo');
      return;
    }
    
    print('🎯 SnippetService: Iniciando timer de snippets');
    _isActive = true;
    _currentSnippetIndex = 0;
    
    // Programar el primer snippet
    _scheduleNextSnippet();
  }
  
  void stopAppTimer() {
    _isActive = false;
    _appTimer?.cancel();
    _appTimer = null;
  }
  
  void _scheduleNextSnippet() {
    if (!_isActive) {
      print('🎯 SnippetService: No se puede programar snippet - no está activo');
      return;
    }
    
    // Usar intervalo fijo de 2 minutos (120 segundos) para todos los snippets
    int nextTime = _snippetInterval;
    print('🎯 SnippetService: Programando snippet ${_currentSnippetIndex + 1} en $nextTime segundos (2 minutos)');
    
    _appTimer = Timer(Duration(seconds: nextTime), () {
      if (_isActive) {
        print('🎯 SnippetService: Mostrando snippet ${_currentSnippetIndex + 1}');
        _showNextSnippet();
      }
    });
  }
  
  void _showNextSnippet() {
    if (!_isActive || _isGameOrCalculatorActive || _hasActiveSnippet) {
      print('🎯 SnippetService: No se puede mostrar snippet - activo: $_isActive, juego/calc: $_isGameOrCalculatorActive, snippet activo: $_hasActiveSnippet');
      return;
    }
    
    // Seleccionar snippet aleatorio que no se haya mostrado hoy
    String selectedSnippet = _getRandomUnshownSnippet();
    print('🎯 SnippetService: Snippet seleccionado: $selectedSnippet');
    
    if (selectedSnippet.isNotEmpty) {
      // Crear y mostrar el overlay
      print('🎯 SnippetService: Creando overlay para $selectedSnippet');
      int snippetId = int.parse(selectedSnippet.replaceAll(RegExp(r'[^0-9]'), ''));
      SnippetOverlay overlay = SnippetOverlay(
        onClose: () {
          _onSnippetClosed();
        },
        snippetImage: selectedSnippet,
        snippetId: snippetId,
      );
      
      // Mostrar usando Overlay global para aparecer encima de todo
      _showGlobalOverlay(overlay);
      
      // Marcar que hay un snippet activo
      _hasActiveSnippet = true;
      
      // Marcar snippet como mostrado
      _shownSnippetsToday.add(selectedSnippet);
      
      // Incrementar índice para el siguiente snippet
      _currentSnippetIndex++;
      
      // NO programar el siguiente snippet aquí - se programará cuando se cierre este snippet
      // El snippet se mostrará durante 10 segundos y luego se programará el siguiente
    }
  }
  
  String _getRandomUnshownSnippet() {
    // Si ya se mostraron todos los snippets, reiniciar la lista
    if (_shownSnippetsToday.length >= _availableSnippets.length) {
      _shownSnippetsToday.clear();
    }
    
    // Obtener snippets no mostrados
    List<String> unshownSnippets = _availableSnippets
        .where((snippet) => !_shownSnippetsToday.contains(snippet))
        .toList();
    
    if (unshownSnippets.isEmpty) {
      return _availableSnippets[Random().nextInt(_availableSnippets.length)];
    }
    
    return unshownSnippets[Random().nextInt(unshownSnippets.length)];
  }
  
  void _showGlobalOverlay(SnippetOverlay overlay) {
    // Por ahora, usar el método original hasta que tengamos el contexto
    _onShowSnippet?.call(overlay);
    print('🎯 SnippetService: Overlay mostrado (método original)');
  }
  
  void _onSnippetClosed() {
    print('🎯 SnippetService: Snippet cerrado, limpiando overlay');
    // Marcar que no hay snippet activo
    _hasActiveSnippet = false;
    
    // Remover overlay global
    _overlayEntry?.remove();
    _overlayEntry = null;
    
    // Limpiar el overlay
    _onClearSnippet?.call();
    
    // Programar el siguiente snippet para 2 minutos después
    // El snippet se muestra durante 10 segundos, y luego se programa el siguiente
    if (_isActive && !_isGameOrCalculatorActive) {
      _scheduleNextSnippet();
    }
  }
  
  void _resetDailyData() {
    // Resetear datos diarios (esto se puede mejorar con persistencia)
    _shownSnippetsToday.clear();
    _currentSnippetIndex = 0;
  }
  
  // Método para obtener estadísticas
  Map<String, dynamic> getStats() {
    return {
      'totalSnippetsShown': _shownSnippetsToday.length,
      'currentIndex': _currentSnippetIndex,
      'isActive': _isActive,
      'nextSnippetTime': _snippetInterval, // Siempre 2 minutos (120 segundos)
    };
  }
  
  // Método para reiniciar el servicio (útil para testing)
  void reset() {
    stopAppTimer();
    _resetDailyData();
    _isActive = false;
  }
  
  // Métodos para controlar el estado del juego/calculadora
  void setGameOrCalculatorActive(bool isActive) {
    _isGameOrCalculatorActive = isActive;
    
    // Si se activa el juego/calculadora, cancelar el timer actual
    if (isActive) {
      _appTimer?.cancel();
    } else {
      // Si se desactiva, reprogramar el siguiente snippet
      if (_isActive) {
        _scheduleNextSnippet();
      }
    }
  }
  
  bool get isGameOrCalculatorActive => _isGameOrCalculatorActive;
}
