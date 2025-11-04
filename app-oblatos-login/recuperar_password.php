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

// Leer entrada JSON
$input = json_decode(file_get_contents('php://input'), true);
if (!$input || empty($input['email'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Email requerido']);
    exit;
}

$email = trim($input['email']);

// Configuración BD (mantener consistente con otros endpoints)
$host = 'localhost';
$dbname = 'Caja_OblatosMX';
$username = 'Caja_OblatosMX';
$password = '5556374784Mexico***';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Verificar usuario por email
    $stmt = $pdo->prepare('SELECT id, nombre_usuario, email FROM usuarios WHERE email = ? LIMIT 1');
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    // Respondemos mensaje genérico aunque no exista, por seguridad
    $genericOk = function() {
        echo json_encode([
            'success' => true,
            'message' => 'Si el email existe, enviaremos un enlace para restablecer tu password.'
        ]);
        exit;
    };

    if (!$user) {
        $genericOk();
    }

    // Crear tabla de resets si no existe (idempotente)
    $pdo->exec('CREATE TABLE IF NOT EXISTS password_resets (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        token VARCHAR(255) NOT NULL,
        expires_at DATETIME NOT NULL,
        used TINYINT(1) NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX (user_id),
        INDEX (token)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

    // Generar token seguro y expiración (1 hora)
    $token = bin2hex(random_bytes(32));
    $expiresAt = (new DateTime('+1 hour'))->format('Y-m-d H:i:s');

    // Guardar token
    $ins = $pdo->prepare('INSERT INTO password_resets (user_id, token, expires_at) VALUES (?, ?, ?)');
    $ins->execute([$user['id'], $token, $expiresAt]);

    // URL base del sitio (ajustar dominio si cambia ruta)
    $baseUrl = 'https://zumuradigital.com/app-oblatos-login';
    $resetLink = $baseUrl . '/reset_password.php?token=' . urlencode($token);

    // Cargar configuración SMTP y helper
    $smtpConfig = require __DIR__ . '/smtp_config.php';
    require_once __DIR__ . '/phpmailer_helper.php';

    // Preparar email
    $to = $user['email'];
    $subject = 'Restablecer tu password - Oblatos 34';
    $message = "Hola {$user['nombre_usuario']},\n\n".
               "Recibimos una solicitud para restablecer tu password.\n".
               "Usa este enlace para crear un nuevo password (válido 1 hora):\n\n".
               "$resetLink\n\n".
               "Si no solicitaste el cambio, ignora este mensaje.";

    // Enviar correo usando SMTP
    sendEmailWithSMTP($to, $subject, $message, $smtpConfig);

    $genericOk();
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error del servidor']);
}
?>


