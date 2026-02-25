<?php
/**
 * Login de la app Oblatos34.
 * Usa la misma BD que recuperar_password/reset_password.
 * Acepta: POST JSON { "nombre_usuario": "...", "password": "..." }
 * Devuelve: { "success": true, "message": "...", "usuario": { ... } } sin el campo password.
 */
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

$input = json_decode(file_get_contents('php://input'), true);
$nombreUsuario = isset($input['nombre_usuario']) ? trim($input['nombre_usuario']) : '';
$password = isset($input['password']) ? (string)$input['password'] : '';

if ($nombreUsuario === '' || $password === '') {
    echo json_encode(['success' => false, 'message' => 'Usuario y contraseña requeridos']);
    exit;
}

$host = 'localhost';
$dbname = 'playcoop_Caja_OblatosMX';
$username = 'playcoop';
$dbPassword = '+B1xv*25Y2rQmT';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $dbPassword);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $pdo->prepare('
        SELECT id, nombre_usuario, nombre_menor, rango_edad, nombre_padre_madre, email, telefono,
               fecha_registro, puntos, puntos_diarios, ultima_sesion, racha_dias, racha_points,
               fecha_inicio_racha, ultimo_bonus_racha, profile_image, password
        FROM usuarios
        WHERE nombre_usuario = ?
        LIMIT 1
    ');
    $stmt->execute([$nombreUsuario]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        echo json_encode(['success' => false, 'message' => 'Usuario o contraseña incorrectos']);
        exit;
    }

    $storedHash = $row['password'] ?? '';
    unset($row['password']);

    // Si no hay hash (usuario antiguo), no permitir login por password
    if ($storedHash === '' || $storedHash === null) {
        echo json_encode(['success' => false, 'message' => 'Usuario o contraseña incorrectos']);
        exit;
    }

    if (!password_verify($password, $storedHash)) {
        echo json_encode(['success' => false, 'message' => 'Usuario o contraseña incorrectos']);
        exit;
    }

    // Valores por defecto para la app
    $usuario = [
        'id' => (int)$row['id'],
        'nombre_usuario' => $row['nombre_usuario'],
        'nombre_menor' => $row['nombre_menor'] ?? '',
        'rango_edad' => $row['rango_edad'] ?? '',
        'nombre_padre_madre' => $row['nombre_padre_madre'] ?? '',
        'email' => $row['email'] ?? '',
        'telefono' => $row['telefono'] ?? '',
        'fecha_registro' => $row['fecha_registro'] ?? '',
        'puntos' => (int)($row['puntos'] ?? 0),
        'puntos_diarios' => (int)($row['puntos_diarios'] ?? 0),
        'ultima_sesion' => $row['ultima_sesion'] ?? null,
        'racha_dias' => (int)($row['racha_dias'] ?? 0),
        'racha_points' => (int)($row['racha_points'] ?? 0),
        'fecha_inicio_racha' => $row['fecha_inicio_racha'] ?? null,
        'ultimo_bonus_racha' => $row['ultimo_bonus_racha'] ?? null,
        'profile_image' => (int)($row['profile_image'] ?? 1),
    ];

    echo json_encode([
        'success' => true,
        'message' => 'Login exitoso',
        'usuario' => $usuario,
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error del servidor']);
}
