import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/daily_challenge_service.dart';
import '../widgets/daily_challenge_overlay.dart';
import '../widgets/challenge_success_overlay.dart';
import '../widgets/challenge_failed_overlay.dart';
import '../user_manager.dart';

/// Helper para mostrar la ventana de reto diario
class ChallengeHelper {
  static Future<void> showDailyChallengeIfNeeded(BuildContext context) async {
    try {
      print('🔍 ChallengeHelper: Verificando si se debe mostrar reto diario...');
      final challengeService = DailyChallengeService();
      final userManager = Provider.of<UserManager>(context, listen: false);
      
      // Verificar si se debe mostrar el reto hoy
      final shouldShow = await challengeService.shouldShowChallengeToday();
      print('🔍 ChallengeHelper: shouldShow = $shouldShow');
      
      if (!shouldShow) {
        // Ya se mostró hoy, no mostrar de nuevo
        print('🔍 ChallengeHelper: Ya se mostró hoy, no mostrar de nuevo');
        return;
      }
      
      // Verificar si el usuario perdió la racha (debe mostrar trivia de recuperación)
      // Un usuario perdió la racha si: racha_dias = 1 y fecha_inicio_racha = hoy
      bool shouldUseRecoveryTrivia = false;
      final rachaDias = userManager.rachaDias;
      final fechaInicioRacha = userManager.fechaInicioRacha;
      final hoy = DateTime.now();
      final hoyDate = DateTime(hoy.year, hoy.month, hoy.day);
      
      if (rachaDias == 1 && fechaInicioRacha != null) {
        final fechaInicioDate = DateTime(
          fechaInicioRacha.year,
          fechaInicioRacha.month,
          fechaInicioRacha.day,
        );
        // Si la fecha de inicio de racha es hoy y tiene solo 1 día, perdió la racha
        if (fechaInicioDate.isAtSameMomentAs(hoyDate)) {
          shouldUseRecoveryTrivia = true;
          print('🔍 Usuario perdió la racha, se usará trivia de recuperación');
        }
      }
      
      // Obtener el reto del día (con indicador de trivia de recuperación si aplica)
      final challenge = await challengeService.getTodayChallenge(
        shouldUseRecoveryTrivia: shouldUseRecoveryTrivia,
      );
      print('🔍 ChallengeHelper: challenge = ${challenge?.description}');
      
      if (challenge == null) {
        print('🔍 ChallengeHelper: No hay reto disponible');
        return;
      }
      
      // Esperar un poco para que la navegación se complete
      await Future.delayed(Duration(milliseconds: 500));
      
      // Verificar que el contexto sigue siendo válido
      if (!context.mounted) {
        print('🔍 ChallengeHelper: Context no está montado');
        return;
      }
      
      print('🔍 ChallengeHelper: Mostrando ventana de reto diario...');
      // Mostrar la ventana de reto diario
      await _showChallengeOverlay(context, challenge, challengeService, userManager);
      print('🔍 ChallengeHelper: Ventana de reto mostrada');
    } catch (e) {
      print('❌ ChallengeHelper Error: $e');
    }
  }
  
  static Future<void> _showChallengeOverlay(
    BuildContext context,
    DailyChallenge challenge,
    DailyChallengeService challengeService,
    UserManager userManager,
  ) async {
    // Si es una trivia, mostrar con opciones
    if (challenge.type == ChallengeType.trivia && 
        (challenge.triviaOptions != null || challenge.options != null)) {
      print('🎯 Mostrando trivia challenge con opciones');
      await showTriviaChallenge(context, challenge, challengeService, userManager);
    } else {
      // Para retos de monedas o videos, solo mostrar información
      print('🎯 Mostrando info challenge (no es trivia o no tiene opciones)');
      await _showInfoChallenge(context, challenge, challengeService, userManager);
    }
  }
  
  static Future<void> _showInfoChallenge(
    BuildContext context,
    DailyChallenge challenge,
    DailyChallengeService challengeService,
    UserManager userManager,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useSafeArea: false, // No usar SafeArea para que ocupe toda la pantalla
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero, // Sin padding, ocupar toda la pantalla
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: DailyChallengeOverlay(
              challenge: challenge,
              onClose: () {
                Navigator.of(context).pop();
              },
              onChallengeAccepted: () {
                // El usuario aceptó el reto, pero aún no lo completó
                // Se completará cuando cumpla la condición (monedas, video, etc.)
              },
            ),
          ),
        );
      },
    );
  }
  
  /// Mostrar trivia challenge (público para poder llamarlo desde Rachacoop)
  static Future<void> showTriviaChallenge(
    BuildContext context,
    DailyChallenge challenge,
    DailyChallengeService challengeService,
    UserManager userManager,
  ) async {
    int? selectedOptionId;
    bool? isCorrect;
    final navigator = Navigator.of(context);
    final completer = Completer<int?>();
    
    await showDialog(
      context: context,
      barrierDismissible: true, // Permitir cerrar tocando fuera
      barrierColor: Colors.transparent,
      useSafeArea: false, // No usar SafeArea para que ocupe toda la pantalla
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero, // Sin padding, ocupar toda la pantalla
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: DailyChallengeOverlay(
              challenge: challenge,
              onClose: () {
                print('🎯 Trivia cerrada sin seleccionar opción');
                navigator.pop();
                if (!completer.isCompleted) {
                  completer.complete(null); // null indica que se cerró sin seleccionar
                }
              },
              onOptionSelected: (int optionId) {
                print('🎯 Opción seleccionada: $optionId');
                selectedOptionId = optionId;
                // Cerrar el overlay inmediatamente cuando se selecciona una opción
                navigator.pop();
                if (!completer.isCompleted) {
                  completer.complete(optionId);
                }
              },
            ),
          ),
        );
      },
    );
    
    // Esperar a que se complete la selección (o que se cierre sin seleccionar)
    final result = await completer.future;
    selectedOptionId = result;
    
    print('🎯 selectedOptionId después del diálogo: $selectedOptionId');
    
    // Si el usuario seleccionó una opción, verificar respuesta en el PHP
    if (selectedOptionId != null && challenge.triviaId != null) {
      // Verificar que el contexto sigue siendo válido
      if (!context.mounted) return;
      
      try {
        final user = userManager.currentUser;
        if (user == null || user['id'] == null) {
          print('❌ Usuario no disponible para verificar trivia');
          return;
        }
        
        // Llamar al PHP para verificar la respuesta
        final response = await http.post(
          Uri.parse('https://zumuradigital.com/app-oblatos-login/verify_trivia_answer.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': user['id'],
            'trivia_id': challenge.triviaId,
            'opcion_id': selectedOptionId,
          }),
        );
        
        print('🎯 Respuesta verify_trivia_answer: ${response.statusCode} - ${response.body}');
        
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            isCorrect = responseData['es_correcta'] == true;
            final puntosObtenidos = responseData['puntos_obtenidos'] ?? 0;
            
            // Actualizar puntos de racha si se obtuvo respuesta del servidor
            if (responseData['racha_points_total'] != null) {
              userManager.updateRachaPoints(int.tryParse(responseData['racha_points_total'].toString()) ?? 0);
            } else if (isCorrect == true && puntosObtenidos > 0) {
              // Si no viene el total, actualizar localmente
              userManager.addRachaPoints(puntosObtenidos);
            }
            
            // Marcar la trivia como intentada (se contestó, correcta o incorrecta)
            await challengeService.markTriviaAttempted();
            
            if (isCorrect == true) {
              // Marcar reto como completado
              await challengeService.completeChallenge();
              userManager.completarRetoDiario();
              
              // Mostrar ventana de éxito
              await _showSuccessOverlay(context);
            } else {
              // Mostrar ventana de fallo (ya se marcó como intentada arriba)
              await _showFailedOverlay(context, challengeService);
            }
          } else {
            print('❌ Error en verify_trivia_answer: ${responseData['error']}');
            // Marcar como intentada incluso si hay error
            await challengeService.markTriviaAttempted();
            // En caso de error, mostrar ventana de fallo
            await _showFailedOverlay(context, challengeService);
          }
        } else {
          print('❌ Error HTTP en verify_trivia_answer: ${response.statusCode}');
          // Marcar como intentada incluso si hay error HTTP
          await challengeService.markTriviaAttempted();
          // En caso de error, mostrar ventana de fallo
          await _showFailedOverlay(context, challengeService);
        }
      } catch (e) {
        print('❌ Error verificando respuesta de trivia: $e');
        // Marcar como intentada incluso si hay excepción
        await challengeService.markTriviaAttempted();
        // En caso de error, mostrar ventana de fallo
        if (context.mounted) {
          await _showFailedOverlay(context, challengeService);
        }
      }
    }
  }
  
  static Future<void> _showSuccessOverlay(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ChallengeSuccessOverlay(
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
  
  static Future<void> _showFailedOverlay(
    BuildContext context,
    DailyChallengeService challengeService,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ChallengeFailedOverlay(
          onClose: () {
            Navigator.of(context).pop();
          },
          onRecoverTrivia: () {
            Navigator.of(context).pop();
            // TODO: Mostrar trivia de recuperación de racha
            // Por ahora solo cerramos
          },
        );
      },
    );
  }
  
  /// Verificar y mostrar ventana de éxito si se completó un reto
  static Future<void> checkAndShowSuccessIfCompleted(
    BuildContext context,
    DailyChallengeService challengeService,
    UserManager userManager,
  ) async {
    final isCompleted = await challengeService.isChallengeCompleted();
    
    if (isCompleted) {
      // El reto ya estaba completado, mostrar éxito
      await _showSuccessOverlay(context);
    }
  }
}

