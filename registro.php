<?php
/**
 * Registro de nuevos usuarios - App Oblatos34 / PlayCoop
 * POST JSON: nombre_usuario, nombre_menor, rango_edad, nombre_padre_madre, email, telefono, password
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit(0); }

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
if (!$input || empty($input['nombre_usuario']) || empty($input['email']) || empty($input['password'])) {
    echo json_encode(['success' => false, 'message' => 'Faltan datos requeridos (usuario, email, contraseña)']);
    exit;
}

$nombreUsuario = trim($input['nombre_usuario']);
$nombreMenor = trim($input['nombre_menor'] ?? '');
$rangoEdad = trim($input['rango_edad'] ?? '');
$nombrePadreMadre = trim($input['nombre_padre_madre'] ?? '');
$email = trim($input['email']);
$telefono = trim($input['telefono'] ?? '');
$password = (string)$input['password'];

if (strlen($password) < 6) {
    echo json_encode(['success' => false, 'message' => 'La contraseña debe tener al menos 6 caracteres']);
    exit;
}

$host = 'localhost';
$dbname = 'playcoop_Caja_OblatosMX';
$user = 'playcoop';
$pass = '+B1xv*25Y2rQmT';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $pdo->prepare('SELECT id FROM usuarios WHERE nombre_usuario = ? LIMIT 1');
    $stmt->execute([$nombreUsuario]);
    if ($stmt->fetch()) {
        echo json_encode(['success' => false, 'message' => 'Ese nombre de usuario ya está registrado']);
        exit;
    }

    $stmt = $pdo->prepare('SELECT id FROM usuarios WHERE email = ? LIMIT 1');
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        echo json_encode(['success' => false, 'message' => 'Ese correo ya está registrado']);
        exit;
    }

    $hash = password_hash($password, PASSWORD_BCRYPT);

    $sql = "INSERT INTO usuarios (
                nombre_usuario, nombre_menor, rango_edad, nombre_padre_madre, email, telefono,
                password, puntos, puntos_diarios, racha_dias, profile_image
            ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 1)";
    $ins = $pdo->prepare($sql);
    $ins->execute([
        $nombreUsuario,
        $nombreMenor,
        $rangoEdad,
        $nombrePadreMadre,
        $email,
        $telefono,
        $hash,
    ]);

    echo json_encode([
        'success' => true,
        'message' => 'Usuario registrado exitosamente',
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error al registrar. Intenta de nuevo.']);
}
