import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleCalendarService {
  static const String _calendarId = 'primary'; // O el ID específico del calendario de Caja Oblatos
  
  // Credenciales de la API (necesitarás configurar esto en Google Cloud Console)
  static const String _apiKey = 'TU_API_KEY_REAL_AQUI'; // Reemplaza con tu clave real
  static const String _clientId = 'TU_CLIENT_ID_REAL_AQUI'; // Reemplaza con tu Client ID real
  static const String _clientSecret = 'TU_CLIENT_SECRET_REAL_AQUI'; // Reemplaza con tu Client Secret real
  
  // Scopes necesarios
  static const List<String> _scopes = [
    calendar.CalendarApi.calendarReadonlyScope,
  ];

  // Método obsoleto - usar getEventos() que obtiene desde PHP
  @deprecated
  Future<List<Evento>> getEventosFromGoogleCalendar() async {
    return getEventos();
  }

  // Obtener eventos desde PHP
  Future<List<Evento>> getEventos() async {
    try {
      final response = await http.get(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/get_eventos.php'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true && responseData['eventos'] != null) {
          final List<dynamic> eventosData = responseData['eventos'];
          return eventosData.map((json) => Evento.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error obteniendo eventos: $e');
      return [];
    }
  }
}

class Evento {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String ubicacion;
  final bool esTodoElDia;
  final String categoria;

  Evento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.fechaInicio,
    this.fechaFin,
    this.ubicacion = '',
    this.esTodoElDia = false,
    this.categoria = 'General',
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaInicio: json['fecha_inicio'] != null 
          ? DateTime.parse(json['fecha_inicio']) 
          : null,
      fechaFin: json['fecha_fin'] != null 
          ? DateTime.parse(json['fecha_fin']) 
          : null,
      ubicacion: json['ubicacion'] ?? '',
      esTodoElDia: json['es_todo_el_dia'] == 1 || json['es_todo_el_dia'] == true,
      categoria: json['categoria'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'ubicacion': ubicacion,
      'es_todo_el_dia': esTodoElDia,
      'categoria': categoria,
    };
  }
}
