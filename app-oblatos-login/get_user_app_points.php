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

    // Si no hay user_id pero hay username, buscar el user_id
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

    // Obtener datos del usuario desde la tabla usuarios
    $stmt = $pdo->prepare("SELECT 
            COALESCE(puntos, 0) AS puntos,
            COALESCE(racha_dias, 0) AS racha_dias,
            ultima_sesion,
            fecha_inicio_racha,
            ultimo_bonus_racha,
            COALESCE(puntos_diarios, 0) AS puntos_diarios
        FROM usuarios
        WHERE id = ?");
    $stmt->execute([$userId]);
    $userData = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$userData) {
        echo json_encode(['success' => false, 'error' => 'Usuario no encontrado']);
        exit;
    }

    // Obtener suma de puntos de snippets desde la tabla snippet_points
    $stmtSnippets = $pdo->prepare("SELECT 
            COALESCE(SUM(points), 0) AS puntos_snippets
        FROM snippet_points
        WHERE user_id = ?");
    $stmtSnippets->execute([$userId]);
    $snippetData = $stmtSnippets->fetch(PDO::FETCH_ASSOC);
    $puntosSnippets = isset($snippetData['puntos_snippets']) ? intval($snippetData['puntos_snippets']) : 0;

    // Calcular puntos totales de la app (base + snippets + diarios)
    $puntosBase = intval($userData['puntos']);
    $puntosDiarios = intval($userData['puntos_diarios']);
    
    // Preparar respuesta
    $response = [
        'success' => true,
        'data' => [
            'puntos' => $puntosBase,
            'puntos_snippets' => $puntosSnippets,
            'puntos_diarios' => $puntosDiarios,
            'racha_dias' => intval($userData['racha_dias']),
            'ultima_sesion' => $userData['ultima_sesion'] ?? null,
            'fecha_inicio_racha' => $userData['fecha_inicio_racha'] ?? null,
            'ultimo_bonus_racha' => $userData['ultimo_bonus_racha'] ?? null,
            'total_app_points' => $puntosBase // Los puntos totales de la app están en 'puntos'
        ]
    ];
    
    // Retornar los datos en el formato esperado por Flutter
    echo json_encode($response);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Error de base de datos: ' . $e->getMessage()]);
}
?>

