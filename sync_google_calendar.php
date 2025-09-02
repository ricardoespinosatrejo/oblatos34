<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Configuración de la base de datos
$host = 'localhost';
$dbname = 'Caja_OblatosMX';
$username = 'Caja_OblatosMX';
$password = '5556374784Mexico***';

// Configuración de Google Calendar API
$apiKey = 'AIzaSyA0jeJ-Fck1MyOq_6_FaUQV6YOnGE3vZwU';
$calendarId = 'primary'; // O el ID específico del calendario

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Función para obtener eventos de Google Calendar
    function getGoogleCalendarEvents($apiKey, $calendarId) {
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
        return json_decode($response, true);
    }
    
    // Función para sincronizar eventos
    function syncEvents($pdo, $googleEvents) {
        $syncedCount = 0;
        $updatedCount = 0;
        $errors = [];
        
        if (!isset($googleEvents['items'])) {
            throw new Exception('No se pudieron obtener eventos de Google Calendar');
        }
        
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
                                    updated_at = NOW()
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
                } else {
                    // Insertar nuevo evento
                    $insertQuery = "INSERT INTO eventos (titulo, descripcion, fecha_inicio, fecha_fin, ubicacion, es_todo_el_dia, google_event_id) 
                                   VALUES (:titulo, :descripcion, :fecha_inicio, :fecha_fin, :ubicacion, :es_todo_el_dia, :google_event_id)";
                    
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
                }
                
            } catch (Exception $e) {
                $errors[] = "Error procesando evento '{$title}': " . $e->getMessage();
            }
        }
        
        return [
            'synced' => $syncedCount,
            'updated' => $updatedCount,
            'errors' => $errors
        ];
    }
    
    // Ejecutar sincronización
    $googleEvents = getGoogleCalendarEvents($apiKey, $calendarId);
    $syncResult = syncEvents($pdo, $googleEvents);
    
    $response = [
        'success' => true,
        'message' => "Sincronización completada: {$syncResult['synced']} eventos nuevos, {$syncResult['updated']} eventos actualizados",
        'synced_count' => $syncResult['synced'],
        'updated_count' => $syncResult['updated'],
        'errors' => $syncResult['errors'],
        'total_google_events' => count($googleEvents['items'] ?? []),
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    $error = [
        'success' => false,
        'error' => $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    echo json_encode($error, JSON_UNESCAPED_UNICODE);
}
?>
