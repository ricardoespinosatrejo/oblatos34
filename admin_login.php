<?php
session_start();
header('Content-Type: application/json');

// Solo permitir POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Método no permitido']);
    exit;
}

// Leer JSON de entrada
$input = json_decode(file_get_contents('php://input'), true);
$username = isset($input['username']) ? trim($input['username']) : '';
$password = isset($input['password']) ? trim($input['password']) : '';

// Credenciales de acceso (mantener solo en el servidor)
// TODO: si en el futuro quieres, mover a base de datos o variables de entorno
$ADMIN_USERNAME = 'admin';
$ADMIN_PASSWORD = 'oblatos2024';

if ($username === $ADMIN_USERNAME && $password === $ADMIN_PASSWORD) {
    // Login correcto: marcar sesión de administrador
    $_SESSION['is_admin'] = true;
    $_SESSION['admin_login_time'] = time();

    echo json_encode(['success' => true]);
    exit;
}

// Credenciales inválidas
http_response_code(401);
echo json_encode(['success' => false, 'message' => 'Usuario o contraseña incorrectos']);

