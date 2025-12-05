<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Incluir configuración de base de datos
require_once 'config.php';

try {
    // Consulta actualizada para usar el nuevo sistema de racha_points
    $sql = "SELECT 
                u.id, 
                u.nombre_usuario, 
                u.nombre_menor, 
                u.rango_edad, 
                u.nombre_padre_madre, 
                u.email, 
                u.telefono, 
                u.fecha_registro,
                u.racha_points,
                u.racha_dias,
                u.ultima_sesion,
                u.fecha_inicio_racha,
                u.ultimo_bonus_racha,
                u.profile_image
            FROM usuarios u
            ORDER BY u.fecha_registro DESC";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    
    $usuarios = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Procesar datos para asegurar formato correcto
    foreach ($usuarios as &$usuario) {
        // Asegurar que los campos de racha tengan valores por defecto
        $usuario['racha_points'] = $usuario['racha_points'] ?? 0;
        $usuario['racha_dias'] = $usuario['racha_dias'] ?? 0;
        $usuario['profile_image'] = $usuario['profile_image'] ?? 1;
        
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
        'message' => 'Usuarios obtenidos con sistema de racha_points'
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
















