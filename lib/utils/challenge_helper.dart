import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/daily_challenge_overlay.dart';
import '../services/daily_challenge_service.dart';
import '../user_manager.dart';
import '../widgets/challenge_success_overlay.dart';

class ChallengeHelper {
  /// Mostrar y manejar la trivia del reto diario
  static Future<void> showTriviaChallenge(
    BuildContext context,
    DailyChallenge challenge,
    DailyChallengeService challengeService,
    UserManager userManager,
  ) async {
    if (challenge.type != ChallengeType.trivia || challenge.triviaId == null) {
      return;
    }

    // Marcar como intentada
    await challengeService.markTriviaAttempted();

    // Obtener la trivia desde el servidor
    try {
      final user = userManager.currentUser;
      if (user == null || user['id'] == null) {
        _showErrorDialog(context, 'No se pudo obtener la información del usuario');
        return;
      }

      final response = await http.get(
        Uri.parse('https://zumuradigital.com/app-oblatos-login/get_trivia.php?trivia_id=${challenge.triviaId}'),
      );

      if (response.statusCode != 200) {
        _showErrorDialog(context, 'Error al obtener la trivia');
        return;
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true || data['trivia'] == null) {
        _showErrorDialog(context, 'No se pudo cargar la trivia');
        return;
      }

      final trivia = data['trivia'];
      final pregunta = trivia['pregunta'] ?? 'Pregunta no disponible';
      final opciones = trivia['opciones'] as List<dynamic>? ?? [];
      final respuestaCorrectaId = trivia['respuesta_correcta_id'] as int?;

      // Mostrar diálogo con la trivia
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return _TriviaDialog(
            pregunta: pregunta,
            opciones: opciones,
            respuestaCorrectaId: respuestaCorrectaId,
            challenge: challenge,
            challengeService: challengeService,
            userManager: userManager,
          );
        },
      );
    } catch (e) {
      print('❌ Error mostrando trivia: $e');
      _showErrorDialog(context, 'Error al cargar la trivia: $e');
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
