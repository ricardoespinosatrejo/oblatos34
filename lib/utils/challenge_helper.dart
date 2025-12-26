import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/daily_challenge_overlay.dart';
import '../services/daily_challenge_service.dart';
import '../user_manager.dart';
import '../widgets/challenge_success_overlay.dart';
import '../widgets/challenge_failed_overlay.dart';

/// Datos de trivia cargada
class TriviaData {
  final DailyChallenge challenge;
  final int? respuestaCorrectaId;
  
  TriviaData({
    required this.challenge,
    required this.respuestaCorrectaId,
  });
}

class ChallengeHelper {
  /// Cargar trivia desde el servidor
  static Future<TriviaData?> loadTriviaChallenge(
    DailyChallenge challenge,
    UserManager userManager,
  ) async {
    try {
      final user = userManager.currentUser;
      if (user == null || user['id'] == null) {
        return null;
      }

      // Intentar obtener la trivia por tipo "normal" (para retos diarios)
      print('🎯 Obteniendo trivia normal (tipo=normal)');
      var response = await http.get(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/get_trivia.php?tipo=normal'),
      );

      print('🎯 Respuesta del servidor (tipo=normal): ${response.statusCode} - ${response.body}');

      // Si no se encuentra por tipo, intentar con ID (si está disponible)
      if (response.statusCode != 200) {
        if (challenge.triviaId != null && challenge.triviaId! > 0) {
          print('🔄 Intentando obtener trivia por ID: ${challenge.triviaId}');
          response = await http.get(
            Uri.parse('https://zumuradigital.com/app-oblatos-login/get_trivia.php?trivia_id=${challenge.triviaId}'),
          );
          print('🎯 Respuesta del servidor (ID): ${response.statusCode} - ${response.body}');
        }
      }

      if (response.statusCode != 200) {
        print('❌ Error HTTP al obtener la trivia: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      print('🎯 Datos de trivia: ${data.toString()}');
      
      if (data['success'] != true || data['trivia'] == null) {
        print('❌ Error en los datos: success=${data['success']}, trivia=${data['trivia']}, error=${data['error'] ?? 'unknown'}');
        return null;
      }

      final trivia = data['trivia'];
      final triviaId = trivia['id'] as int? ?? challenge.triviaId;
      final pregunta = trivia['pregunta'] ?? 'Pregunta no disponible';
      final opciones = trivia['opciones'] as List<dynamic>? ?? [];

      // Convertir opciones a TriviaOption
      final triviaOptions = opciones.map((opt) {
        return TriviaOption(
          id: opt['id'] as int? ?? 0,
          texto: opt['texto'] ?? opt['text'] ?? '',
          orden: opt['orden'] as int? ?? 0,
        );
      }).toList();

      final respuestaCorrectaId = trivia['respuesta_correcta_id'] as int?;
      print('🎯 respuesta_correcta_id obtenido: $respuestaCorrectaId');
      
      // Crear un challenge actualizado con las opciones de trivia
      final loadedChallenge = DailyChallenge(
        type: challenge.type,
        title: challenge.title,
        description: pregunta, // Usar la pregunta como descripción
        targetValue: challenge.targetValue,
        videoId: challenge.videoId,
        triviaId: triviaId,
        windowImage: challenge.windowImage,
        triviaOptions: triviaOptions,
      );
      
      return TriviaData(
        challenge: loadedChallenge,
        respuestaCorrectaId: respuestaCorrectaId,
      );
    } catch (e) {
      print('❌ Error cargando trivia: $e');
      return null;
    }
  }

  /// Mostrar trivia de recuperación de racha usando el mismo diseño que las trivias normales
  static Future<void> showRecoveryTrivia(
    BuildContext context,
    int triviaId,
    String pregunta,
    List<dynamic> opciones,
    int? respuestaCorrectaId,
    DailyChallengeService challengeService,
    UserManager userManager,
  ) async {
    // Convertir opciones a TriviaOption
    final triviaOptions = opciones.map((opt) {
      return TriviaOption(
        id: opt['id'] as int? ?? 0,
        texto: opt['texto'] ?? opt['text'] ?? '',
        orden: opt['orden'] as int? ?? 0,
      );
    }).toList();

    // Crear un DailyChallenge para la trivia de recuperación con las opciones ya cargadas
    final recoveryChallenge = DailyChallenge(
      type: ChallengeType.trivia,
      title: 'RECUPERA TU RACHA',
      description: pregunta,
      triviaId: triviaId,
      windowImage: 'assets/images/rachacoop/racha-window/racha-window-03.png',
      triviaOptions: triviaOptions,
    );

    // Mostrar el overlay usando el mismo diseño que las trivias normales
    // El overlay detectará que ya tiene opciones cargadas y las usará directamente
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return DailyChallengeOverlay(
          challenge: recoveryChallenge,
          onClose: () {
            Navigator.of(dialogContext).pop();
          },
          parentContext: context,
          initialRespuestaCorrectaId: respuestaCorrectaId, // Pasar la respuesta correcta
        );
      },
    );
  }

  static Future<void> processTriviaAnswer(
    BuildContext? context,
    UserManager userManager,
    int triviaId,
    int selectedOptionId,
    int? respuestaCorrectaId,
    DailyChallengeService challengeService,
  ) async {
    try {
      final user = userManager.currentUser;
      if (user == null || user['id'] == null) {
        throw Exception('Usuario no encontrado');
      }

      // Marcar como intentada cuando el usuario realmente selecciona una opción
      await challengeService.markTriviaAttempted();

      final userId = user['id'];
      print('🎯 Verificando respuesta: trivia_id=$triviaId, option_id=$selectedOptionId, user_id=$userId, respuesta_correcta_id=$respuestaCorrectaId');
      
      // SOLUCIÓN TEMPORAL: Verificar localmente usando respuesta_correcta_id
      // Esto es necesario porque verify_trivia_answer.php está devolviendo "Datos incompletos"
      // TODO: Corregir el endpoint PHP para que acepte los datos correctamente
      bool isCorrect = false;
      
      if (respuestaCorrectaId != null) {
        // Verificar localmente si la respuesta es correcta (para trivias de recuperación que sí tienen respuesta_correcta_id)
        isCorrect = selectedOptionId == respuestaCorrectaId;
        print('🎯 Verificación local: selectedOptionId=$selectedOptionId, respuestaCorrectaId=$respuestaCorrectaId, isCorrect=$isCorrect');
      } else {
        // Para trivias normales, intentar verificarlo en el servidor
        // NOTA: Actualmente verify_trivia_answer.php está devolviendo "Datos incompletos"
        // Se necesita corregir el servidor PHP para que funcione correctamente
        print('⚠️ No hay respuesta_correcta_id, intentando verificar en el servidor...');
        
        final userIdInt = userId is int ? userId : (userId is String ? int.tryParse(userId) : null);
        
        if (userIdInt == null) {
          throw Exception('user_id inválido: $userId');
        }
        
        final payload = {
          'user_id': userIdInt,
          'trivia_id': triviaId,
          'option_id': selectedOptionId,
        };
        
        print('🎯 Payload enviado: ${jsonEncode(payload)}');
        
        final response = await http.post(
          Uri.parse('https://zumuradigital.com/app-oblatos-login/verify_trivia_answer.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        print('🎯 Respuesta de verificación: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (data['success'] == false) {
            final errorMessage = data['error'] ?? 'Error desconocido';
            print('❌ Error en la respuesta del servidor: $errorMessage');
            
            // Si el error es "Datos incompletos", es un problema del servidor
            if (errorMessage.contains('incompletos') || errorMessage.contains('incompleto')) {
              print('⚠️ El servidor requiere corrección: verify_trivia_answer.php necesita revisión');
              if (context != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error del servidor: Por favor contacta al soporte técnico'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
              return; // No podemos continuar sin verificar la respuesta
            }
            
            if (context != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $errorMessage'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }
          
          isCorrect = data['correct'] == true;
        } else {
          // Si el servidor falla con otro código de error
          print('⚠️ El servidor falló con código: ${response.statusCode}');
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al verificar la respuesta en el servidor (código: ${response.statusCode})'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (isCorrect) {
        // Completar el reto
        await challengeService.completeChallenge();

        // Llamar al PHP para registrar la completación
        try {
          final completeResponse = await http.post(
            Uri.parse('https://zumuradigital.com/app-oblatos-login/complete_daily_challenge.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': user['id'],
              'challenge_type': 'trivia',
              'challenge_data': {
                'trivia_id': triviaId,
                'option_id': selectedOptionId,
              },
            }),
          );

          if (completeResponse.statusCode == 200) {
            final responseData = jsonDecode(completeResponse.body);
            if (responseData['success'] == true && responseData['racha_points_total'] != null) {
              userManager.updateRachaPoints(
                int.tryParse(responseData['racha_points_total'].toString()) ?? 0,
              );
            }
          }
        } catch (e) {
          print('❌ Error registrando completación de reto: $e');
        }

        userManager.completarRetoDiario();

        // Mostrar ventana de éxito si tenemos contexto válido
        if (context != null && context.mounted) {
          try {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext ctx) {
                return ChallengeSuccessOverlay(
                  onClose: () {
                    Navigator.of(ctx).pop();
                  },
                );
              },
            );
          } catch (e) {
            print('❌ Error mostrando ventana de éxito: $e');
          }
        }
      } else {
        // Respuesta incorrecta - mostrar ventana de error
        if (context != null && context.mounted) {
          try {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext ctx) {
                return ChallengeFailedOverlay(
                  onClose: () {
                    Navigator.of(ctx).pop();
                  },
                  onRecoverTrivia: () {
                    // No hacer nada, solo cerrar
                    Navigator.of(ctx).pop();
                  },
                );
              },
            );
          } catch (e) {
            print('❌ Error mostrando ventana de error: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error verificando respuesta: $e');
      if (context != null && context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al verificar la respuesta'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e2) {
          print('❌ Error mostrando SnackBar de error: $e2');
        }
      }
    }
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _TriviaDialog extends StatefulWidget {
  final String pregunta;
  final List<dynamic> opciones;
  final int? respuestaCorrectaId;
  final DailyChallenge challenge;
  final DailyChallengeService challengeService;
  final UserManager userManager;

  const _TriviaDialog({
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrectaId,
    required this.challenge,
    required this.challengeService,
    required this.userManager,
  });

  @override
  _TriviaDialogState createState() => _TriviaDialogState();
}

class _TriviaDialogState extends State<_TriviaDialog> {
  int? _selectedOptionId;
  bool _isSubmitting = false;

  Future<void> _submitAnswer() async {
    if (_selectedOptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona una opción')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = widget.userManager.currentUser;
      if (user == null || user['id'] == null) {
        throw Exception('Usuario no encontrado');
      }

      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/verify_trivia_answer.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user['id'],
          'trivia_id': widget.challenge.triviaId,
          'option_id': _selectedOptionId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error en la respuesta del servidor');
      }

      final data = jsonDecode(response.body);
      final isCorrect = data['correct'] == true;

      Navigator.of(context).pop(); // Cerrar el diálogo de trivia

      if (isCorrect) {
        // Completar el reto
        await widget.challengeService.completeChallenge();

        // Llamar al PHP para registrar la completación
        try {
          final completeResponse = await http.post(
            Uri.parse('https://zumuradigital.com/app-oblatos-login/complete_daily_challenge.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': user['id'],
              'challenge_type': 'trivia',
              'challenge_data': {
                'trivia_id': widget.challenge.triviaId,
                'option_id': _selectedOptionId,
              },
            }),
          );

          if (completeResponse.statusCode == 200) {
            final responseData = jsonDecode(completeResponse.body);
            if (responseData['success'] == true && responseData['racha_points_total'] != null) {
              widget.userManager.updateRachaPoints(
                int.tryParse(responseData['racha_points_total'].toString()) ?? 0,
              );
            }
          }
        } catch (e) {
          print('❌ Error registrando completación de reto: $e');
        }

        widget.userManager.completarRetoDiario();

        // Mostrar ventana de éxito
        if (mounted) {
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
      } else {
        // Respuesta incorrecta
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Respuesta incorrecta. Intenta de nuevo mañana.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error verificando respuesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al verificar la respuesta'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF0A0E21),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF4ECDC4), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TRIVIA DEL DÍA',
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4ECDC4),
              ),
            ),
            SizedBox(height: 20),
            Text(
              widget.pregunta,
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ...widget.opciones.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final optionId = option['id'] as int?;
              final optionText = option['texto'] ?? option['text'] ?? 'Opción ${index + 1}';

              return Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: _isSubmitting ? null : () {
                    setState(() {
                      _selectedOptionId = optionId;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedOptionId == optionId
                          ? Color(0xFF4ECDC4).withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedOptionId == optionId
                            ? Color(0xFF4ECDC4)
                            : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      optionText,
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'Gotham Rounded',
                      color: Colors.white70,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4ECDC4),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Enviar',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryTriviaDialog extends StatefulWidget {
  final String pregunta;
  final List<dynamic> opciones;
  final int? respuestaCorrectaId;
  final int triviaId;
  final DailyChallengeService challengeService;
  final UserManager userManager;

  const _RecoveryTriviaDialog({
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrectaId,
    required this.triviaId,
    required this.challengeService,
    required this.userManager,
  });

  @override
  _RecoveryTriviaDialogState createState() => _RecoveryTriviaDialogState();
}

class _RecoveryTriviaDialogState extends State<_RecoveryTriviaDialog> {
  int? _selectedOptionId;
  bool _isSubmitting = false;

  Future<void> _submitAnswer() async {
    if (_selectedOptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona una opción')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = widget.userManager.currentUser;
      if (user == null || user['id'] == null) {
        throw Exception('Usuario no encontrado');
      }

      // AHORA sí marcar como intentada, cuando el usuario realmente responde
      await widget.challengeService.markTriviaAttempted();

      final response = await http.post(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/verify_trivia_answer.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user['id'],
          'trivia_id': widget.triviaId,
          'option_id': _selectedOptionId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error en la respuesta del servidor');
      }

      final data = jsonDecode(response.body);
      final isCorrect = data['correct'] == true;

      Navigator.of(context).pop(); // Cerrar el diálogo de trivia

      if (isCorrect) {
        // Completar el reto
        await widget.challengeService.completeChallenge();

        // Marcar que se mostró la trivia de recuperación para evitar que se muestre el reto diario
        final prefs = await SharedPreferences.getInstance();
        final today = DateTime.now();
        final todayKey = '${today.year}-${today.month}-${today.day}';
        await prefs.setBool('recovery_trivia_shown_$todayKey', true);

        // Llamar al PHP para registrar la completación
        try {
          final completeResponse = await http.post(
            Uri.parse('https://zumuradigital.com/app-oblatos-login/complete_daily_challenge.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': user['id'],
              'challenge_type': 'trivia',
              'challenge_data': {
                'trivia_id': widget.triviaId,
                'option_id': _selectedOptionId,
              },
            }),
          );

          if (completeResponse.statusCode == 200) {
            final responseData = jsonDecode(completeResponse.body);
            if (responseData['success'] == true && responseData['racha_points_total'] != null) {
              widget.userManager.updateRachaPoints(
                int.tryParse(responseData['racha_points_total'].toString()) ?? 0,
              );
            }
          }
        } catch (e) {
          print('❌ Error registrando completación de reto: $e');
        }

        widget.userManager.completarRetoDiario();

        // Mostrar ventana de éxito
        if (mounted) {
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
      } else {
        // Respuesta incorrecta
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Respuesta incorrecta. No pudiste recuperar tu racha.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error verificando respuesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al verificar la respuesta'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF0A0E21),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF4ECDC4), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¡RECUPERA TU RACHA!',
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4ECDC4),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Responde correctamente para no perder tu racha',
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 12,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              widget.pregunta,
              style: TextStyle(
                fontFamily: 'Gotham Rounded',
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ...widget.opciones.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final optionId = option['id'] as int?;
              final optionText = option['texto'] ?? option['text'] ?? 'Opción ${index + 1}';

              return Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: _isSubmitting ? null : () {
                    setState(() {
                      _selectedOptionId = optionId;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedOptionId == optionId
                          ? Color(0xFF4ECDC4).withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedOptionId == optionId
                            ? Color(0xFF4ECDC4)
                            : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      optionText,
                      style: TextStyle(
                        fontFamily: 'Gotham Rounded',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'Gotham Rounded',
                      color: Colors.white70,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4ECDC4),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Enviar',
                          style: TextStyle(
                            fontFamily: 'Gotham Rounded',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
