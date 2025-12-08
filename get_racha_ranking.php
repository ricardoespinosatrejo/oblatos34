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
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Consulta para obtener ranking de racha diaria ordenado por racha_points
    $sql = "SELECT 
                id, 
                nombre_usuario, 
                nombre_menor, 
                email, 
                racha_points,
                racha_dias,
                fecha_inicio_racha,
                ultima_sesion,
                profile_image
            FROM usuarios 
            WHERE racha_points > 0
            ORDER BY racha_points DESC, racha_dias DESC
            LIMIT 100";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    
    $usuarios = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Procesar datos
    foreach ($usuarios as &$usuario) {
        $usuario['racha_points'] = (int)($usuario['racha_points'] ?? 0);
        $usuario['racha_dias'] = (int)($usuario['racha_dias'] ?? 0);
        $usuario['profile_image'] = (int)($usuario['profile_image'] ?? 1);
        
        // Formatear fechas
        if ($usuario['ultima_sesion']) {
            $usuario['ultima_sesion_formatted'] = date('d/m/Y', strtotime($usuario['ultima_sesion']));
        }
        if ($usuario['fecha_inicio_racha']) {
            $usuario['fecha_inicio_racha_formatted'] = date('d/m/Y', strtotime($usuario['fecha_inicio_racha']));
        }
    }
    
    echo json_encode([
        'success' => true,
        'usuarios' => $usuarios,
        'total' => count($usuarios),
        'message' => 'Ranking de racha diaria obtenido correctamente'
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


