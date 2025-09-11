<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
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
    echo json_encode(['success' => false, 'error' => 'Error de conexión a la base de datos']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    try {
        // Obtener estadísticas generales de snippets
        $stats = [];
        
        // Total de snippets vistos hoy
        $stmt = $pdo->query("
            SELECT COUNT(*) as total_snippets_hoy 
            FROM snippet_points 
            WHERE DATE(created_at) = CURDATE()
        ");
        $stats['total_snippets_hoy'] = $stmt->fetchColumn();
        
        // Total de snippets vistos en total
        $stmt = $pdo->query("SELECT COUNT(*) as total_snippets FROM snippet_points");
        $stats['total_snippets'] = $stmt->fetchColumn();
        
        // Total de puntos otorgados por snippets
        $stmt = $pdo->query("SELECT SUM(points) as total_puntos_snippets FROM snippet_points");
        $stats['total_puntos_snippets'] = $stmt->fetchColumn() ?: 0;
        
        // Usuarios activos hoy (que vieron snippets)
        $stmt = $pdo->query("
            SELECT COUNT(DISTINCT user_id) as usuarios_activos_hoy 
            FROM snippet_points 
            WHERE DATE(created_at) = CURDATE()
        ");
        $stats['usuarios_activos_hoy'] = $stmt->fetchColumn();
        
        // Top snippets más vistos
        $stmt = $pdo->query("
            SELECT snippet_id, COUNT(*) as veces_visto 
            FROM snippet_points 
            GROUP BY snippet_id 
            ORDER BY veces_visto DESC 
            LIMIT 5
        ");
        $stats['top_snippets'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Usuarios con más snippets vistos
        $stmt = $pdo->query("
            SELECT u.id, u.nombre_usuario, u.nombre_menor, 
                   COUNT(sp.id) as snippets_vistos,
                   SUM(sp.points) as puntos_snippets,
                   MAX(sp.created_at) as ultimo_snippet
            FROM usuarios u
            LEFT JOIN snippet_points sp ON u.id = sp.user_id
            GROUP BY u.id, u.nombre_usuario, u.nombre_menor
            HAVING snippets_vistos > 0
            ORDER BY snippets_vistos DESC
            LIMIT 20
        ");
        $stats['top_usuarios'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Estadísticas por día (últimos 7 días)
        $stmt = $pdo->query("
            SELECT DATE(created_at) as fecha, 
                   COUNT(*) as snippets_vistos,
                   COUNT(DISTINCT user_id) as usuarios_unicos
            FROM snippet_points 
            WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
            GROUP BY DATE(created_at)
            ORDER BY fecha DESC
        ");
        $stats['estadisticas_7_dias'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'stats' => $stats
        ]);
        
    } catch(PDOException $e) {
        echo json_encode(['success' => false, 'error' => 'Error en la consulta: ' . $e->getMessage()]);
    }
    
} else {
    echo json_encode(['success' => false, 'error' => 'Método no permitido']);
}
?>
