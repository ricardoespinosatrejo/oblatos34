<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Configuración de la base de datos
$host = 'localhost';
$dbname = 'Caja_OblatosMX';
$username = 'Caja_OblatosMX';
$password = '5556374784Mexico***';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Obtener datos del POST
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('No se recibieron datos');
    }
    
    // Validar datos requeridos
    if (empty($input['titulo']) || empty($input['fecha_inicio'])) {
        throw new Exception('Título y fecha de inicio son requeridos');
    }
    
    // Preparar datos
    $titulo = trim($input['titulo']);
    $descripcion = trim($input['descripcion'] ?? '');
    $fecha_inicio = $input['fecha_inicio'];
    $fecha_fin = $input['fecha_fin'] ?? null;
    $ubicacion = trim($input['ubicacion'] ?? '');
    $categoria = trim($input['categoria'] ?? 'General');
    $es_todo_el_dia = $input['es_todo_el_dia'] ?? 0;
    
    // Si es evento de todo el día, ajustar fechas
    if ($es_todo_el_dia) {
        $fecha_inicio = date('Y-m-d 00:00:00', strtotime($fecha_inicio));
        $fecha_fin = date('Y-m-d 23:59:59', strtotime($fecha_inicio));
    }
    
    // Si es actualización
    if (isset($input['id']) && !empty($input['id'])) {
        $id = $input['id'];
        
        $query = "UPDATE eventos SET 
                    titulo = :titulo,
                    descripcion = :descripcion,
                    fecha_inicio = :fecha_inicio,
                    fecha_fin = :fecha_fin,
                    ubicacion = :ubicacion,
                    categoria = :categoria,
                    es_todo_el_dia = :es_todo_el_dia,
                    updated_at = NOW()
                  WHERE id = :id";
        
        $stmt = $pdo->prepare($query);
        $stmt->execute([
            ':titulo' => $titulo,
            ':descripcion' => $descripcion,
            ':fecha_inicio' => $fecha_inicio,
            ':fecha_fin' => $fecha_fin,
            ':ubicacion' => $ubicacion,
            ':categoria' => $categoria,
            ':es_todo_el_dia' => $es_todo_el_dia,
            ':id' => $id
        ]);
        
        $message = 'Evento actualizado correctamente';
        
    } else {
        // Si es nuevo evento
        $query = "INSERT INTO eventos (titulo, descripcion, fecha_inicio, fecha_fin, ubicacion, categoria, es_todo_el_dia) 
                  VALUES (:titulo, :descripcion, :fecha_inicio, :fecha_fin, :ubicacion, :categoria, :es_todo_el_dia)";
        
        $stmt = $pdo->prepare($query);
        $stmt->execute([
            ':titulo' => $titulo,
            ':descripcion' => $descripcion,
            ':fecha_inicio' => $fecha_inicio,
            ':fecha_fin' => $fecha_fin,
            ':ubicacion' => $ubicacion,
            ':categoria' => $categoria,
            ':es_todo_el_dia' => $es_todo_el_dia
        ]);
        
        $message = 'Evento creado correctamente';
    }
    
    $response = [
        'success' => true,
        'message' => $message,
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    $error = [
        'success' => false,
        'error' => $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    echo json_encode($error, JSON_UNESCAPED_UNICODE);
}
?>
