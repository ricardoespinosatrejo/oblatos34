<?php
// Script para sincronización automática con Google Calendar
// Se puede ejecutar con cron: 0 */6 * * * php /path/to/cron_sync_google_calendar.php

// Configuración de la base de datos
$host = 'localhost';
$dbname = 'Caja_OblatosMX';
$username = 'Caja_OblatosMX';
$password = '5556374784Mexico***';

// Configuración de Google Calendar API
$apiKey = 'AIzaSyA0jeJ-Fck1MyOq_6_FaUQV6YOnGE3vZwU';
$calendarId = 'primary';

// Archivo de log
$logFile = __DIR__ . '/sync_log.txt';

function writeLog($message) {
    global $logFile;
    $timestamp = date('Y-m-d H:i:s');
    $logMessage = "[$timestamp] $message\n";
    file_put_contents($logFile, $logMessage, FILE_APPEND);
}

try {
    writeLog("Iniciando sincronización automática con Google Calendar");
    
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Obtener eventos de Google Calendar
    $now = date('c');
    $thirtyDaysFromNow = date('c', strtotime('+30 days'));
    
    $url = "https://www.googleapis.com/calendar/v3/calendars/{$calendarId}/events?" .
           "key={$apiKey}&" .
           "timeMin={$now}&" .
           "timeMax={$thirtyDaysFromNow}&" .
           "orderBy=startTime&" .
           "singleEvents=true&" .
           "maxResults=50";
    
    $response = file_get_contents($url);
    $googleEvents = json_decode($response, true);
    
    if (!$googleEvents || !isset($googleEvents['items'])) {
        throw new Exception('No se pudieron obtener eventos de Google Calendar');
    }
    
    writeLog("Obtenidos " . count($googleEvents['items']) . " eventos de Google Calendar");
    
    $syncedCount = 0;
    $updatedCount = 0;
    $errors = [];
    
    foreach ($googleEvents['items'] as $event) {
        try {
            $eventId = $event['id'];
            $title = $event['summary'] ?? 'Sin título';
            $description = $event['description'] ?? '';
            $location = $event['location'] ?? '';
            
            // Procesar fecha de inicio
            $startDate = null;
            $isAllDay = false;
            
            if (isset($event['start']['dateTime'])) {
                $startDate = date('Y-m-d H:i:s', strtotime($event['start']['dateTime']));
            } elseif (isset($event['start']['date'])) {
                $startDate = date('Y-m-d 00:00:00', strtotime($event['start']['date']));
                $isAllDay = true;
            }
            
            // Procesar fecha de fin
            $endDate = null;
            if (isset($event['end']['dateTime'])) {
                $endDate = date('Y-m-d H:i:s', strtotime($event['end']['dateTime']));
            } elseif (isset($event['end']['date'])) {
                $endDate = date('Y-m-d 23:59:59', strtotime($event['end']['date']));
            }
            
            // Verificar si el evento ya existe
            $checkQuery = "SELECT id FROM eventos WHERE google_event_id = :google_event_id";
            $checkStmt = $pdo->prepare($checkQuery);
            $checkStmt->execute([':google_event_id' => $eventId]);
            $existingEvent = $checkStmt->fetch();
            
            if ($existingEvent) {
                // Actualizar evento existente
                $updateQuery = "UPDATE eventos SET 
                                titulo = :titulo,
                                descripcion = :descripcion,
                                fecha_inicio = :fecha_inicio,
                                fecha_fin = :fecha_fin,
                                ubicacion = :ubicacion,
                                es_todo_el_dia = :es_todo_el_dia,
                                last_sync_at = NOW(),
                                sync_status = 'synced'
                               WHERE google_event_id = :google_event_id";
                
                $updateStmt = $pdo->prepare($updateQuery);
                $updateStmt->execute([
                    ':titulo' => $title,
                    ':descripcion' => $description,
                    ':fecha_inicio' => $startDate,
                    ':fecha_fin' => $endDate,
                    ':ubicacion' => $location,
                    ':es_todo_el_dia' => $isAllDay ? 1 : 0,
                    ':google_event_id' => $eventId
                ]);
                
                $updatedCount++;
                writeLog("Actualizado evento: $title");
                
            } else {
                // Insertar nuevo evento
                $insertQuery = "INSERT INTO eventos (titulo, descripcion, fecha_inicio, fecha_fin, ubicacion, es_todo_el_dia, google_event_id, last_sync_at, sync_status) 
                               VALUES (:titulo, :descripcion, :fecha_inicio, :fecha_fin, :ubicacion, :es_todo_el_dia, :google_event_id, NOW(), 'synced')";
                
                $insertStmt = $pdo->prepare($insertQuery);
                $insertStmt->execute([
                    ':titulo' => $title,
                    ':descripcion' => $description,
                    ':fecha_inicio' => $startDate,
                    ':fecha_fin' => $endDate,
                    ':ubicacion' => $location,
                    ':es_todo_el_dia' => $isAllDay ? 1 : 0,
                    ':google_event_id' => $eventId
                ]);
                
                $syncedCount++;
                writeLog("Nuevo evento sincronizado: $title");
            }
            
        } catch (Exception $e) {
            $errorMsg = "Error procesando evento '{$title}': " . $e->getMessage();
            $errors[] = $errorMsg;
            writeLog("ERROR: $errorMsg");
        }
    }
    
    // Limpiar eventos obsoletos (más de 30 días sin sincronizar)
    $cleanupQuery = "DELETE FROM eventos WHERE last_sync_at < DATE_SUB(NOW(), INTERVAL 30 DAY) AND google_event_id IS NOT NULL";
    $cleanupStmt = $pdo->prepare($cleanupQuery);
    $cleanupStmt->execute();
    $deletedCount = $cleanupStmt->rowCount();
    
    writeLog("Sincronización completada: $syncedCount nuevos, $updatedCount actualizados, $deletedCount eliminados");
    writeLog("Errores encontrados: " . count($errors));
    
    if (!empty($errors)) {
        writeLog("Detalles de errores: " . implode('; ', $errors));
    }
    
    // Enviar notificación de resumen por email (opcional)
    $summaryMessage = "Sincronización automática completada:\n";
    $summaryMessage .= "- Eventos nuevos: $syncedCount\n";
    $summaryMessage .= "- Eventos actualizados: $updatedCount\n";
    $summaryMessage .= "- Eventos eliminados: $deletedCount\n";
    $summaryMessage .= "- Errores: " . count($errors) . "\n";
    
    // mail('admin@cajaoblatos.com', 'Sincronización Google Calendar', $summaryMessage);
    
} catch (Exception $e) {
    $errorMsg = "Error en sincronización automática: " . $e->getMessage();
    writeLog("ERROR CRÍTICO: $errorMsg");
    
    // mail('admin@cajaoblatos.com', 'Error en Sincronización Google Calendar', $errorMsg);
}

writeLog("Sincronización automática finalizada\n");
?>










