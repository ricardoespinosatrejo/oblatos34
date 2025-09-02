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
    
    // Obtener datos del POST
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || !isset($input['id'])) {
        throw new Exception('ID del evento es requerido');
    }
    
    $id = $input['id'];
    
    // Verificar que el evento existe
    $checkQuery = "SELECT id FROM eventos WHERE id = :id";
    $checkStmt = $pdo->prepare($checkQuery);
    $checkStmt->execute([':id' => $id]);
    
    if (!$checkStmt->fetch()) {
        throw new Exception('Evento no encontrado');
    }
    
    // Eliminar el evento
    $query = "DELETE FROM eventos WHERE id = :id";
    $stmt = $pdo->prepare($query);
    $stmt->execute([':id' => $id]);
    
    $response = [
        'success' => true,
        'message' => 'Evento eliminado correctamente',
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
