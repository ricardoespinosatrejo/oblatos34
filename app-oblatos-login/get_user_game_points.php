<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Método no permitido']);
    exit;
}

$userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
$usernameFilter = isset($_GET['username']) ? trim($_GET['username']) : '';

$host = 'localhost';
$dbname = 'Caja_OblatosMX';
$username = 'Caja_OblatosMX';
$password = '5556374784Mexico***';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    if ($userId <= 0 && $usernameFilter !== '') {
        $stmtLookup = $pdo->prepare("SELECT id FROM usuarios WHERE nombre_usuario = ? LIMIT 1");
        $stmtLookup->execute([$usernameFilter]);
        $lookup = $stmtLookup->fetch(PDO::FETCH_ASSOC);
        if ($lookup) {
            $userId = intval($lookup['id']);
        }
    }

    if ($userId <= 0) {
        echo json_encode(['success' => false, 'error' => 'user_id o username requerido']);
        exit;
    }

    // Obtener datos de game_scores (puntajes de todas las partidas)
    $stmt = $pdo->prepare("SELECT 
            COALESCE(SUM(score), 0) AS total_score,
            COUNT(*) AS total_games,
            COALESCE(MAX(score), 0) AS highest_score
        FROM game_scores
        WHERE user_id = ?");
    $stmt->execute([$userId]);
    $scoreData = $stmt->fetch(PDO::FETCH_ASSOC);

    // Si no hay datos en game_scores, inicializar con valores por defecto
    if (!$scoreData) {
        $scoreData = [
            'total_score' => 0,
            'total_games' => 0,
            'highest_score' => 0
        ];
    }

    // Obtener datos de game_user_stats (estadísticas agregadas)
    $statsStmt = $pdo->prepare("SELECT 
            total_games_played,
            highest_score,
            highest_level,
            total_coins_collected,
            last_played
        FROM game_user_stats
        WHERE user_id = ?");
    $statsStmt->execute([$userId]);
    $statsData = $statsStmt->fetch(PDO::FETCH_ASSOC);

    // Calcular total_score (suma de todos los scores) - este es el acumulado
    $totalScore = intval($scoreData['total_score'] ?? 0);
    
    // Si total_score es 0 pero hay registros, puede ser que los scores sean null
    // Intentar recalcular si es necesario
    if ($totalScore == 0 && intval($scoreData['total_games'] ?? 0) > 0) {
        $checkStmt = $pdo->prepare("SELECT SUM(COALESCE(score, 0)) AS total FROM game_scores WHERE user_id = ?");
        $checkStmt->execute([$userId]);
        $checkData = $checkStmt->fetch(PDO::FETCH_ASSOC);
        $totalScore = intval($checkData['total'] ?? 0);
    }

    // Determinar highest_score: priorizar game_user_stats si existe y es > 0, 
    // sino usar el MAX de game_scores
    $highestFromStats = isset($statsData['highest_score']) ? intval($statsData['highest_score']) : 0;
    $highestFromScores = intval($scoreData['highest_score'] ?? 0);
    $finalHighest = ($highestFromStats > 0) ? $highestFromStats : $highestFromScores;
    
    // Si aún es 0, hacer una consulta directa para obtener el MAX
    if ($finalHighest == 0) {
        $maxStmt = $pdo->prepare("SELECT MAX(score) AS max_score FROM game_scores WHERE user_id = ?");
        $maxStmt->execute([$userId]);
        $maxData = $maxStmt->fetch(PDO::FETCH_ASSOC);
        if ($maxData && $maxData['max_score'] !== null) {
            $finalHighest = intval($maxData['max_score']);
        }
    }

    echo json_encode([
        'success' => true,
        'user_id' => $userId,
        'total_score' => $totalScore,
        'total_games' => intval($scoreData['total_games'] ?? 0),
        'highest_score' => $finalHighest,
        'highest_level' => isset($statsData['highest_level']) ? intval($statsData['highest_level']) : 0,
        'total_coins_collected' => isset($statsData['total_coins_collected']) ? intval($statsData['total_coins_collected']) : 0,
        'last_played' => $statsData['last_played'] ?? null
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Error de base de datos: ' . $e->getMessage()]);
}
?>

