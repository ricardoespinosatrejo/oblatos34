<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Incluir configuración de base de datos
require_once 'config.php';

try {
    // Consulta que funciona con la estructura actual de la base de datos
    $sql = "SELECT 
                u.id, 
                u.nombre_usuario, 
                u.nombre_menor, 
                u.rango_edad, 
                u.nombre_padre_madre, 
                u.email, 
                u.telefono, 
                u.fecha_registro,
                u.puntos,
                u.puntos_diarios,
                u.ultima_sesion,
                u.racha_dias,
                u.fecha_inicio_racha,
                u.ultimo_bonus_racha,
                u.profile_image,
                COUNT(sp.id) as snippets_vistos_total,
                SUM(sp.points) as puntos_snippets,
                COUNT(CASE WHEN DATE(sp.created_at) = CURDATE() THEN 1 END) as snippets_hoy,
                MAX(sp.created_at) as ultimo_snippet_visto
            FROM usuarios u
            LEFT JOIN snippet_points sp ON u.id = sp.user_id
            GROUP BY u.id, u.nombre_usuario, u.nombre_menor, u.rango_edad, 
                     u.nombre_padre_madre, u.email, u.telefono, u.fecha_registro,
                     u.puntos, u.puntos_diarios, u.ultima_sesion, u.racha_dias,
                     u.fecha_inicio_racha, u.ultimo_bonus_racha, u.profile_image
            ORDER BY u.fecha_registro DESC";
    
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
        
        // Procesar campos de snippets
        $usuario['snippets_vistos_total'] = $usuario['snippets_vistos_total'] ?? 0;
        $usuario['puntos_snippets'] = $usuario['puntos_snippets'] ?? 0;
        $usuario['snippets_hoy'] = $usuario['snippets_hoy'] ?? 0;
        
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
        if ($usuario['ultimo_snippet_visto']) {
            $usuario['ultimo_snippet_visto_formatted'] = date('d/m/Y H:i', strtotime($usuario['ultimo_snippet_visto']));
        }
    }
    
    echo json_encode([
        'success' => true,
        'usuarios' => $usuarios,
        'total' => count($usuarios),
        'message' => 'Usuarios obtenidos con sistema de puntos completo'
    ]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error en la base de datos: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error interno del servidor: ' . $e->getMessage()
    ]);
}
?>
















