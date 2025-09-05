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

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Obtener eventos en las próximas 48 horas que no han sido notificados
    $query = "SELECT id, titulo, descripcion, fecha_inicio, fecha_fin, ubicacion, es_todo_el_dia 
              FROM eventos 
              WHERE fecha_inicio BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 48 HOUR)
              AND (notificacion_enviada = FALSE OR notificacion_enviada IS NULL)
              AND enviar_notificacion = TRUE
              ORDER BY fecha_inicio ASC";
    
    $stmt = $pdo->prepare($query);
    $stmt->execute();
    $eventos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Marcar eventos como notificados
    if (!empty($eventos)) {
        $eventIds = array_column($eventos, 'id');
        $placeholders = str_repeat('?,', count($eventIds) - 1) . '?';
        
        $updateQuery = "UPDATE eventos SET notificacion_enviada = TRUE WHERE id IN ($placeholders)";
        $updateStmt = $pdo->prepare($updateQuery);
        $updateStmt->execute($eventIds);
    }
    
    $response = [
        'success' => true,
        'eventos' => $eventos,
        'total' => count($eventos),
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




