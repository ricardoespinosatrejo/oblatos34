<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Manejar preflight requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Configuración de la base de datos
$host = 'localhost';
$dbname = 'Caja_OblatosMX';
$username = 'Caja_OblatosMX';
$password = '5556374784Mexico***';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(['success' => false, 'error' => 'Error de conexión a la base de datos: ' . $e->getMessage()]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        echo json_encode(['success' => false, 'error' => 'Datos JSON inválidos']);
        exit;
    }
    
    $user_id = $input['user_id'] ?? null;
    $points = $input['points'] ?? 10; // Por defecto 10 puntos
    $snippet_id = $input['snippet_id'] ?? null;
    
    if (!$user_id || !$snippet_id) {
        echo json_encode(['success' => false, 'error' => 'user_id y snippet_id son requeridos']);
        exit;
    }
    
    try {
        // Verificar si el usuario existe
        $stmt = $pdo->prepare("SELECT id, nombre_usuario, puntos FROM usuarios WHERE id = ?");
        $stmt->execute([$user_id]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$user) {
            echo json_encode(['success' => false, 'error' => 'Usuario no encontrado']);
            exit;
        }
        
        // Obtener la fecha actual
        $current_date = date('Y-m-d');
        
        // Verificar si ya existe un registro para este snippet hoy
        $stmt = $pdo->prepare("
            SELECT id FROM snippet_points 
            WHERE user_id = ? AND snippet_id = ? AND DATE(created_at) = ?
        ");
        $stmt->execute([$user_id, $snippet_id, $current_date]);
        
        if ($stmt->fetch()) {
            echo json_encode(['success' => false, 'error' => 'Ya se otorgaron puntos por este snippet hoy']);
            exit;
        }
        
        // Insertar el registro de puntos del snippet
        $stmt = $pdo->prepare("
            INSERT INTO snippet_points (user_id, snippet_id, points, created_at) 
            VALUES (?, ?, ?, NOW())
        ");
        $stmt->execute([$user_id, $snippet_id, $points]);
        
        // Actualizar los puntos totales del usuario
        $stmt = $pdo->prepare("
            UPDATE usuarios 
            SET puntos = puntos + ? 
            WHERE id = ?
        ");
        $stmt->execute([$points, $user_id]);
        
        // Obtener el total de puntos actualizado
        $stmt = $pdo->prepare("SELECT puntos FROM usuarios WHERE id = ?");
        $stmt->execute([$user_id]);
        $total_points = $stmt->fetchColumn();
        
        // Contar snippets vistos hoy
        $stmt = $pdo->prepare("
            SELECT COUNT(*) FROM snippet_points 
            WHERE user_id = ? AND DATE(created_at) = ?
        ");
        $stmt->execute([$user_id, $current_date]);
        $snippets_today = $stmt->fetchColumn();
        
        echo json_encode([
            'success' => true,
            'points_added' => $points,
            'total_points' => $total_points,
            'snippets_today' => $snippets_today,
            'user_name' => $user['nombre_usuario'],
            'message' => "¡Ganaste $points puntos!"
        ]);
        
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Error en la base de datos: ' . $e->getMessage()]);
    }
    
} else {
    echo json_encode(['success' => false, 'error' => 'Método no permitido']);
}
?>





