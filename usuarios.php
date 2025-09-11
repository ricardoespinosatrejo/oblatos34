<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Configuración de la base de datos
$host = 'localhost';
$dbname = 'Caja_OblatosMX';
$username = 'Caja_OblatosMX';
$password = '5556374784Mexico***';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Consulta simple para obtener usuarios (manteniendo funcionalidad original)
    $sql = "SELECT 
                id, 
                nombre_usuario, 
                nombre_menor, 
                rango_edad, 
                nombre_padre_madre, 
                email, 
                telefono, 
                fecha_registro,
                puntos,
                puntos_diarios,
                ultima_sesion,
                racha_dias,
                fecha_inicio_racha,
                ultimo_bonus_racha,
                profile_image
            FROM usuarios 
            ORDER BY fecha_registro DESC";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    
    $usuarios = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Procesar datos para asegurar formato correcto
    foreach ($usuarios as &$usuario) {
        // Asegurar que los campos de puntos tengan valores por defecto
        $usuario['puntos'] = $usuario['puntos'] ?? 0;
        $usuario['puntos_diarios'] = $usuario['puntos_diarios'] ?? 0;
        $usuario['racha_dias'] = $usuario['racha_dias'] ?? 0;
        $usuario['profile_image'] = $usuario['profile_image'] ?? 1;
        
        // Agregar estadísticas de snippets por separado
        $usuario_id = $usuario['id'];
        
        // Contar snippets vistos total
        $stmt_snippets = $pdo->prepare("SELECT COUNT(*) FROM snippet_points WHERE user_id = ?");
        $stmt_snippets->execute([$usuario_id]);
        $usuario['snippets_vistos_total'] = $stmt_snippets->fetchColumn();
        
        // Contar puntos de snippets
        $stmt_puntos = $pdo->prepare("SELECT SUM(points) FROM snippet_points WHERE user_id = ?");
        $stmt_puntos->execute([$usuario_id]);
        $usuario['puntos_snippets'] = $stmt_puntos->fetchColumn() ?: 0;
        
        // Contar snippets de hoy
        $stmt_hoy = $pdo->prepare("SELECT COUNT(*) FROM snippet_points WHERE user_id = ? AND DATE(created_at) = CURDATE()");
        $stmt_hoy->execute([$usuario_id]);
        $usuario['snippets_hoy'] = $stmt_hoy->fetchColumn();
        
        // Último snippet visto
        $stmt_ultimo = $pdo->prepare("SELECT MAX(created_at) FROM snippet_points WHERE user_id = ?");
        $stmt_ultimo->execute([$usuario_id]);
        $ultimo_snippet = $stmt_ultimo->fetchColumn();
        $usuario['ultimo_snippet_visto'] = $ultimo_snippet;
        if ($ultimo_snippet) {
            $usuario['ultimo_snippet_visto_formatted'] = date('d/m/Y H:i', strtotime($ultimo_snippet));
        }
        
        // Formatear fechas si existen
        if ($usuario['ultima_sesion']) {
            $usuario['ultima_sesion_formatted'] = date('d/m/Y', strtotime($usuario['ultima_sesion']));
        }
        if ($usuario['fecha_inicio_racha']) {
            $usuario['fecha_inicio_racha_formatted'] = date('d/m/Y', strtotime($usuario['fecha_inicio_racha']));
        }
        if ($usuario['ultimo_bonus_racha']) {
            $usuario['ultimo_bonus_racha_formatted'] = date('d/m/Y', strtotime($usuario['ultimo_bonus_racha']));
        }
    }
    
    echo json_encode([
        'success' => true,
        'usuarios' => $usuarios,
        'total' => count($usuarios),
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
} catch(PDOException $e) {
    echo json_encode([
        'success' => false,
        'error' => 'Error de base de datos: ' . $e->getMessage()
    ]);
}
?>
