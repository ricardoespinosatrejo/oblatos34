<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Configuración de OneSignal
$ONESIGNAL_APP_ID = "TU_ONESIGNAL_APP_ID"; // Reemplazar con tu App ID
$ONESIGNAL_REST_API_KEY = "TU_ONESIGNAL_REST_API_KEY"; // Reemplazar con tu REST API Key

// Función para enviar notificación
function sendNotification($title, $message, $playerIds = null, $url = null) {
    global $ONESIGNAL_APP_ID, $ONESIGNAL_REST_API_KEY;
    
    $fields = array(
        'app_id' => $ONESIGNAL_APP_ID,
        'headings' => array('en' => $title),
        'contents' => array('en' => $message),
        'included_segments' => array('All'), // Enviar a todos los usuarios
    );
    
    // Si se especifican player IDs específicos
    if ($playerIds && is_array($playerIds)) {
        $fields['include_player_ids'] = $playerIds;
        unset($fields['included_segments']); // No enviar a todos si hay IDs específicos
    }
    
    // Si se especifica una URL
    if ($url) {
        $fields['url'] = $url;
    }
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, "https://onesignal.com/api/v1/notifications");
    curl_setopt($ch, CURLOPT_HTTPHEADER, array(
        'Content-Type: application/json; charset=utf-8',
        'Authorization: Basic ' . $ONESIGNAL_REST_API_KEY
    ));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
    curl_setopt($ch, CURLOPT_HEADER, FALSE);
    curl_setopt($ch, CURLOPT_POST, TRUE);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return array(
        'success' => $httpCode == 200,
        'response' => json_decode($response, true),
        'http_code' => $httpCode
    );
}

// Función para enviar recordatorio de evento
function sendEventReminder($eventTitle, $eventDate, $eventTime, $playerIds = null) {
    $title = "🎉 Recordatorio de Evento";
    $message = "No olvides: $eventTitle\nFecha: $eventDate\nHora: $eventTime";
    
    return sendNotification($title, $message, $playerIds);
}

// Manejar las solicitudes
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        echo json_encode(array('error' => 'Datos JSON inválidos'));
        exit();
    }
    
    $action = $input['action'] ?? '';
    
    switch ($action) {
        case 'send_notification':
            $title = $input['title'] ?? '';
            $message = $input['message'] ?? '';
            $playerIds = $input['player_ids'] ?? null;
            $url = $input['url'] ?? null;
            
            if (empty($title) || empty($message)) {
                echo json_encode(array('error' => 'Título y mensaje son requeridos'));
                exit();
            }
            
            $result = sendNotification($title, $message, $playerIds, $url);
            echo json_encode($result);
            break;
            
        case 'send_event_reminder':
            $eventTitle = $input['event_title'] ?? '';
            $eventDate = $input['event_date'] ?? '';
            $eventTime = $input['event_time'] ?? '';
            $playerIds = $input['player_ids'] ?? null;
            
            if (empty($eventTitle) || empty($eventDate) || empty($eventTime)) {
                echo json_encode(array('error' => 'Título, fecha y hora del evento son requeridos'));
                exit();
            }
            
            $result = sendEventReminder($eventTitle, $eventDate, $eventTime, $playerIds);
            echo json_encode($result);
            break;
            
        default:
            echo json_encode(array('error' => 'Acción no válida'));
            break;
    }
} else {
    echo json_encode(array('error' => 'Método no permitido'));
}
?>
























