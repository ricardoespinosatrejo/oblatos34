import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/snippet_overlay.dart';

class SnippetService {
  static final SnippetService _instance = SnippetService._internal();
  factory SnippetService() => _instance;
  SnippetService._internal();
  
  // Tiempos progresivos para mostrar snippets
  final List<int> _snippetTimes = [
    30,   // Primer snippet a los 30 segundos
    45,   // Segundo snippet a los 45 segundos
    60,   // Tercer snippet a los 60 segundos
    90,   // Cuarto snippet a los 90 segundos
    150,  // Quinto snippet a los 150 segundos
    240,  // Sexto snippet a los 4 minutos
    360,  // Séptimo snippet a los 6 minutos
    480,  // Octavo snippet a los 8 minutos
    600,  // Noveno snippet a los 10 minutos
    720,  // Décimo snippet a los 12 minutos
    900,  // Undécimo snippet a los 15 minutos
    1200, // Duodécimo snippet a los 20 minutos
  ];
  
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
    if (!_isActive || _currentSnippetIndex >= _snippetTimes.length) {
      print('🎯 SnippetService: No se puede programar snippet - activo: $_isActive, índice: $_currentSnippetIndex');
      return;
    }
    
    int nextTime = _snippetTimes[_currentSnippetIndex];
    print('🎯 SnippetService: Programando snippet ${_currentSnippetIndex + 1} en $nextTime segundos');
    
    _appTimer = Timer(Duration(seconds: nextTime), () {
      if (_isActive) {
        print('🎯 SnippetService: Mostrando snippet ${_currentSnippetIndex + 1}');
        _showNextSnippet();
      }
    });
  }
  
  void _showNextSnippet() {
    if (!_isActive || _currentSnippetIndex >= _snippetTimes.length || _isGameOrCalculatorActive || _hasActiveSnippet) {
      print('🎯 SnippetService: No se puede mostrar snippet - activo: $_isActive, índice: $_currentSnippetIndex, juego/calc: $_isGameOrCalculatorActive, snippet activo: $_hasActiveSnippet');
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
      
      // Programar el siguiente snippet
      _scheduleNextSnippet();
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
    
    // El snippet se cerró, continuar con el siguiente si es necesario
    if (_isActive && _currentSnippetIndex < _snippetTimes.length) {
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
      'nextSnippetTime': _currentSnippetIndex < _snippetTimes.length 
          ? _snippetTimes[_currentSnippetIndex] 
          : null,
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
      if (_isActive && _currentSnippetIndex < _snippetTimes.length) {
        _scheduleNextSnippet();
      }
    }
  }
  
  bool get isGameOrCalculatorActive => _isGameOrCalculatorActive;
}
