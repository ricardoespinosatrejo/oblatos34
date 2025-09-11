<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Incluir configuración de base de datos
require_once 'config.php';

try {
    // Consulta actualizada para incluir todos los campos del sistema de puntos
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

















