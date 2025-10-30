<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Configuración de la base de datos - CREDENCIALES ACTUALIZADAS
$host = 'localhost';
$dbname = 'Caja_OblatosMX'; // Tu nombre de base de datos
$username = 'Caja_OblatosMX'; // Tu usuario de MySQL
$password = '5556374784Mexico***'; // Tu contraseña de MySQL

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(['success' => false, 'error' => 'Error de conexión a la base de datos']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        echo json_encode(['success' => false, 'error' => 'Datos JSON inválidos']);
        exit;
    }
    
    $user_id = isset($input['user_id']) ? intval($input['user_id']) : 0;
    $username = isset($input['username']) ? trim($input['username']) : 'Usuario';
    $score = isset($input['score']) ? intval($input['score']) : 0;
    $level_reached = isset($input['level_reached']) ? intval($input['level_reached']) : 1;
    $coins_collected = isset($input['coins_collected']) ? intval($input['coins_collected']) : 0;
    
    if ($user_id <= 0 || $score < 0) {
        echo json_encode(['success' => false, 'error' => 'Datos inválidos']);
        exit;
    }
    
    try {
        // Insertar puntaje del juego
        $stmt = $pdo->prepare("
            INSERT INTO game_scores (user_id, username, score, level_reached, coins_collected) 
            VALUES (?, ?, ?, ?, ?)
        ");
        $stmt->execute([$user_id, $username, $score, $level_reached, $coins_collected]);
        
        // Actualizar estadísticas del usuario
        $stmt = $pdo->prepare("
            INSERT INTO game_user_stats (user_id, username, total_games_played, highest_score, highest_level, total_coins_collected) 
            VALUES (?, ?, 1, ?, ?, ?)
            ON DUPLICATE KEY UPDATE 
                total_games_played = total_games_played + 1,
                highest_score = GREATEST(highest_score, ?),
                highest_level = GREATEST(highest_level, ?),
                total_coins_collected = total_coins_collected + ?,
                last_played = CURRENT_TIMESTAMP
        ");
        $stmt->execute([$user_id, $username, $score, $level_reached, $coins_collected, $score, $level_reached, $coins_collected]);
        
        echo json_encode([
            'success' => true, 
            'message' => 'Puntaje guardado correctamente',
            'score_id' => $pdo->lastInsertId()
        ]);
        
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Error al guardar puntaje: ' . $e->getMessage()]);
    }
    
} else {
    echo json_encode(['success' => false, 'error' => 'Método no permitido']);
}
?>






















