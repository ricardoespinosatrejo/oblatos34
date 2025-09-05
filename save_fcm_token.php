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
    
    if (!$input || !isset($input['fcm_token'])) {
        throw new Exception('Token FCM es requerido');
    }
    
    $fcmToken = $input['fcm_token'];
    $userId = $input['user_id'] ?? null;
    
    // Verificar si el token ya existe
    $checkQuery = "SELECT id FROM fcm_tokens WHERE token = :token";
    $checkStmt = $pdo->prepare($checkQuery);
    $checkStmt->execute([':token' => $fcmToken]);
    $existingToken = $checkStmt->fetch();
    
    if ($existingToken) {
        // Actualizar token existente
        $updateQuery = "UPDATE fcm_tokens SET 
                        user_id = :user_id,
                        updated_at = NOW()
                       WHERE token = :token";
        
        $updateStmt = $pdo->prepare($updateQuery);
        $updateStmt->execute([
            ':user_id' => $userId,
            ':token' => $fcmToken
        ]);
        
        $message = 'Token FCM actualizado correctamente';
        
    } else {
        // Insertar nuevo token
        $insertQuery = "INSERT INTO fcm_tokens (token, user_id, created_at) 
                       VALUES (:token, :user_id, NOW())";
        
        $insertStmt = $pdo->prepare($insertQuery);
        $insertStmt->execute([
            ':token' => $fcmToken,
            ':user_id' => $userId
        ]);
        
        $message = 'Token FCM guardado correctamente';
    }
    
    $response = [
        'success' => true,
        'message' => $message,
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




