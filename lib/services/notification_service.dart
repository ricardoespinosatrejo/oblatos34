import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  static String? _fcmToken;
  static bool _isInitialized = false;

  // Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializar timezone
      tz.initializeTimeZones();
      
      // Inicializar Firebase
      await Firebase.initializeApp();
      
      // Configurar notificaciones locales
      await _setupLocalNotifications();
      
      // Configurar notificaciones push
      await _setupPushNotifications();
      
      // Configurar tareas en segundo plano
      await _setupBackgroundTasks();
      
      _isInitialized = true;
      print('✅ Servicio de notificaciones inicializado correctamente');
      
    } catch (e) {
      print('❌ Error inicializando notificaciones: $e');
    }
  }

  // Configurar notificaciones locales
  static Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Configurar canal de notificaciones para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'eventos_caja_oblatos',
      'Eventos Caja Oblatos',
      description: 'Notificaciones de eventos y campañas',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Configurar notificaciones push
  static Future<void> _setupPushNotifications() async {
    // Solicitar permisos
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permisos de notificación concedidos');
      
      // Obtener token FCM
      _fcmToken = await _firebaseMessaging.getToken();
      print('🔑 FCM Token: $_fcmToken');
      
      // Guardar token en el servidor
      if (_fcmToken != null) {
        await _saveTokenToServer(_fcmToken!);
      }
      
      // Escuchar cambios en el token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToServer(newToken);
      });
      
      // Manejar mensajes en primer plano
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Manejar mensajes cuando la app está en segundo plano
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      
    } else {
      print('❌ Permisos de notificación denegados');
    }
  }

  // Configurar tareas en segundo plano
  static Future<void> _setupBackgroundTasks() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
    
    // Programar verificación de eventos cada 6 horas
    await Workmanager().registerPeriodicTask(
      'checkEvents',
      'checkUpcomingEvents',
      frequency: Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  // Guardar token en el servidor
  static Future<void> _saveTokenToServer(String token) async {
    try {
      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/save_fcm_token.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcm_token': token,
          'user_id': 'current_user_id', // Se actualizará con el ID real del usuario
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Token FCM guardado en el servidor');
      } else {
        print('❌ Error guardando token FCM');
      }
    } catch (e) {
      print('❌ Error de conexión guardando token: $e');
    }
  }

  // Manejar mensaje en primer plano
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Mensaje recibido en primer plano: ${message.notification?.title}');
    
    // Mostrar notificación local
    _showLocalNotification(
      message.notification?.title ?? 'Nuevo evento',
      message.notification?.body ?? 'Tienes un nuevo evento',
      message.data,
    );
  }

  // Manejar mensaje en segundo plano
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('📱 Mensaje abierto desde segundo plano: ${message.notification?.title}');
    
    // Navegar a la sección de eventos
    // Esto se manejará en el main.dart
  }

  // Mostrar notificación local
  static Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic>? payload,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'eventos_caja_oblatos',
      'Eventos Caja Oblatos',
      channelDescription: 'Notificaciones de eventos y campañas',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  // Manejar tap en notificación
  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Notificación tocada: ${response.payload}');
    
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      // Navegar a la sección correspondiente
      // Esto se manejará en el main.dart
    }
  }

  // Programar notificación para evento específico
  static Future<void> scheduleEventNotification({
    required int eventId,
    required String title,
    required String body,
    required DateTime eventTime,
    int reminderHours = 24,
  }) async {
    final scheduledTime = eventTime.subtract(Duration(hours: reminderHours));
    
    if (scheduledTime.isAfter(DateTime.now())) {
      await _localNotifications.zonedSchedule(
        eventId,
        '🔔 Recordatorio: $title',
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'eventos_caja_oblatos',
            'Eventos Caja Oblatos',
            channelDescription: 'Recordatorios de eventos',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({
          'event_id': eventId,
          'type': 'event_reminder',
        }),
      );
      
      print('✅ Notificación programada para evento $eventId');
    }
  }

  // Cancelar notificación programada
  static Future<void> cancelEventNotification(int eventId) async {
    await _localNotifications.cancel(eventId);
    print('❌ Notificación cancelada para evento $eventId');
  }

  // Verificar eventos próximos y enviar notificaciones
  static Future<void> checkUpcomingEvents() async {
    try {
      final response = await http.get(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/get_upcoming_events.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] && data['eventos'] != null) {
          final eventos = data['eventos'] as List;
          
          for (var evento in eventos) {
            final eventTime = DateTime.parse(evento['fecha_inicio']);
            final now = DateTime.now();
            final hoursUntilEvent = eventTime.difference(now).inHours;
            
            // Enviar notificación si el evento está en las próximas 24 horas
            if (hoursUntilEvent <= 24 && hoursUntilEvent > 0) {
              await _showLocalNotification(
                '🔔 Evento Próximo: ${evento['titulo']}',
                'El evento comienza en ${hoursUntilEvent} horas',
                {
                  'event_id': evento['id'],
                  'type': 'upcoming_event',
                },
              );
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error verificando eventos próximos: $e');
    }
  }

  // Obtener token FCM
  static String? get fcmToken => _fcmToken;
  
  // Verificar si está inicializado
  static bool get isInitialized => _isInitialized;
}

// Callback para tareas en segundo plano
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'checkUpcomingEvents':
        await NotificationService.checkUpcomingEvents();
        break;
    }
    return Future.value(true);
  });
}
