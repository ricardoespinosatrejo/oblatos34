<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Configuración de la base de datos
$host = 'localhost';
$dbname = 'Caja_OblatosMX'; // Cambiar por el nombre de tu base de datos
$username = 'Caja_OblatosMX'; // Cambiar por tu usuario de MySQL
$password = '5556374784Mexico***'; // Cambiar por tu contraseña de MySQL

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(['success' => false, 'error' => 'Error de conexión a la base de datos']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $type = isset($_GET['type']) ? $_GET['type'] : 'highest';
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
    
    try {
        if ($type === 'highest') {
            // Ranking por puntaje más alto
            $stmt = $pdo->prepare("
                SELECT 
                    gs.user_id,
                    gs.username,
                    MAX(gs.score) as highest_score,
                    MAX(gs.level_reached) as highest_level,
                    MAX(gs.coins_collected) as max_coins,
                    COUNT(gs.id) as total_games,
                    MAX(gs.game_date) as last_played
                FROM game_scores gs
                GROUP BY gs.user_id, gs.username
                ORDER BY highest_score DESC, highest_level DESC
                LIMIT ?
            ");
            $stmt->execute([$limit]);
            
        } elseif ($type === 'recent') {
            // Ranking por puntajes recientes
            $stmt = $pdo->prepare("
                SELECT 
                    user_id,
                    username,
                    score,
                    level_reached,
                    coins_collected,
                    game_date as last_played
                FROM game_scores
                ORDER BY game_date DESC
                LIMIT ?
            ");
            $stmt->execute([$limit]);
            
        } elseif ($type === 'level') {
            // Ranking por nivel más alto alcanzado
            $stmt = $pdo->prepare("
                SELECT 
                    gs.user_id,
                    gs.username,
                    MAX(gs.level_reached) as highest_level,
                    MAX(gs.score) as highest_score,
                    COUNT(gs.id) as total_games,
                    MAX(gs.game_date) as last_played
                FROM game_scores gs
                GROUP BY gs.user_id, gs.username
                ORDER BY highest_level DESC, highest_score DESC
                LIMIT ?
            ");
            $stmt->execute([$limit]);
            
        } else {
            echo json_encode(['success' => false, 'error' => 'Tipo de ranking inválido']);
            exit;
        }
        
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'type' => $type,
            'limit' => $limit,
            'ranking' => $results
        ]);
        
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Error al obtener ranking: ' . $e->getMessage()]);
    }
    
} else {
    echo json_encode(['success' => false, 'error' => 'Método no permitido']);
}
?>
