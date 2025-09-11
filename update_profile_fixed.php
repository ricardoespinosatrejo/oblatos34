<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
    exit;
}

// Obtener datos del POST
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Datos inválidos']);
    exit;
}

// Validar datos requeridos
$required_fields = ['user_id', 'nombre_menor', 'email', 'telefono', 'nombre_padre_madre', 'profile_image'];
foreach ($required_fields as $field) {
    if (!isset($input[$field]) || empty($input[$field])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => "Campo requerido: $field"]);
        exit;
    }
}

// Configuración CORRECTA de la base de datos
$host = 'localhost';
$dbname = 'Caja_OblatosMX';
$username = 'Caja_OblatosMX';
$password = '5556374784Mexico***';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Preparar la consulta de actualización
    $sql = "UPDATE usuarios SET 
            nombre_menor = :nombre_menor,
            email = :email,
            telefono = :telefono,
            nombre_padre_madre = :nombre_padre_madre,
            profile_image = :profile_image
            WHERE id = :user_id";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':nombre_menor' => $input['nombre_menor'],
        ':email' => $input['email'],
        ':telefono' => $input['telefono'],
        ':nombre_padre_madre' => $input['nombre_padre_madre'],
        ':profile_image' => $input['profile_image'],
        ':user_id' => $input['user_id']
    ]);
    
    if ($stmt->rowCount() > 0) {
        // Actualización exitosa
        echo json_encode([
            'success' => true,
            'message' => 'Perfil actualizado exitosamente',
            'user_id' => $input['user_id']
        ]);
    } else {
        // No se encontró el usuario o no hubo cambios
        echo json_encode([
            'success' => false,
            'message' => 'No se pudo actualizar el perfil'
        ]);
    }
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error de base de datos: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error interno del servidor: ' . $e->getMessage()
    ]);
}
?>
















