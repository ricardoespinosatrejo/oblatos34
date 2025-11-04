<?php
// Sirve el formulario (GET con token) y procesa el cambio (POST con token y new_password)

function render_form($token, $error = '', $success = '') {
    // HTML mínimo embebido
    echo '<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
        . '<title>Restablecer password</title>'
        . '<style>body{font-family:sans-serif;background:#0A0E21;color:#fff;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}'
        . '.card{background:#161351;padding:24px;border-radius:12px;max-width:360px;width:92%;box-shadow:0 8px 24px rgba(0,0,0,0.3)}'
        . 'label{display:block;margin:12px 0 8px;color:#fff}input{width:100%;padding:12px;border-radius:8px;border:1px solid #3949ab;background:#0d0b3a;color:#fff}'
        . '.btn{margin-top:18px;width:100%;padding:12px;border:none;border-radius:24px;background:linear-gradient(90deg,#FF1744,#E91E63);color:#fff;font-weight:700;cursor:pointer}'
        . '.msg{margin:8px 0;padding:10px;border-radius:8px;font-size:14px}'
        . '.err{background:#b00020} .ok{background:#2e7d32}'
        . '</style></head><body><div class="card">'
        . '<h2 style="margin:0 0 12px">Restablecer password</h2>';
    if ($error) echo '<div class="msg err">' . htmlspecialchars($error) . '</div>';
    if ($success) echo '<div class="msg ok">' . htmlspecialchars($success) . '</div>';
    if (!$success) {
        echo '<form method="POST">'
            . '<input type="hidden" name="token" value="' . htmlspecialchars($token) . '">'
            . '<label>Nuevo password</label>'
            . '<input type="password" name="new_password" minlength="6" required>'
            . '<label>Confirmar password</label>'
            . '<input type="password" name="confirm_password" minlength="6" required>'
            . '<button class="btn" type="submit">Guardar</button>'
            . '</form>';
    }
    echo '</div></body></html>';
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

// Configuración BD
$host = 'localhost';
$dbname = 'Caja_OblatosMX';
$username = 'Caja_OblatosMX';
$password = '5556374784Mexico***';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    if ($method === 'GET') {
        $token = isset($_GET['token']) ? trim($_GET['token']) : '';
        if ($token === '') {
            render_form('', 'Token inválido');
            exit;
        }

        // Validar token
        $stmt = $pdo->prepare('SELECT pr.id, pr.user_id, pr.expires_at, pr.used, u.nombre_usuario FROM password_resets pr JOIN usuarios u ON u.id = pr.user_id WHERE pr.token = ? LIMIT 1');
        $stmt->execute([$token]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            render_form('', 'Token no válido');
            exit;
        }
        if (intval($row['used']) === 1) {
            render_form('', 'Este enlace ya fue utilizado');
            exit;
        }
        if (strtotime($row['expires_at']) < time()) {
            render_form('', 'El enlace ha expirado');
            exit;
        }

        render_form($token);
        exit;
    }

    if ($method === 'POST') {
        $token = isset($_POST['token']) ? trim($_POST['token']) : '';
        $newPassword = isset($_POST['new_password']) ? (string)$_POST['new_password'] : '';
        $confirmPassword = isset($_POST['confirm_password']) ? (string)$_POST['confirm_password'] : '';

        if ($token === '') { render_form('', 'Token inválido'); exit; }
        if ($newPassword === '' || strlen($newPassword) < 6) { render_form($token, 'Password mínimo 6 caracteres'); exit; }
        if ($newPassword !== $confirmPassword) { render_form($token, 'Los passwords no coinciden'); exit; }

        $pdo->beginTransaction();

        // Validar token vigente y no usado
        $stmt = $pdo->prepare('SELECT id, user_id, expires_at, used FROM password_resets WHERE token = ? FOR UPDATE');
        $stmt->execute([$token]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) { $pdo->rollBack(); render_form('', 'Token no válido'); exit; }
        if (intval($row['used']) === 1) { $pdo->rollBack(); render_form('', 'Este enlace ya fue utilizado'); exit; }
        if (strtotime($row['expires_at']) < time()) { $pdo->rollBack(); render_form('', 'El enlace ha expirado'); exit; }

        $userId = intval($row['user_id']);

        // Actualizar password en usuarios (hash seguro)
        $hash = password_hash($newPassword, PASSWORD_BCRYPT);
        $up = $pdo->prepare('UPDATE usuarios SET password = ? WHERE id = ?');
        $up->execute([$hash, $userId]);

        // Marcar token como usado e invalidar otros tokens activos del mismo usuario
        $use = $pdo->prepare('UPDATE password_resets SET used = 1 WHERE id = ?');
        $use->execute([intval($row['id'])]);
        $inv = $pdo->prepare('UPDATE password_resets SET used = 1 WHERE user_id = ? AND token <> ?');
        $inv->execute([$userId, $token]);

        $pdo->commit();

        render_form('', '', 'Tu password ha sido actualizado. Ya puedes cerrar esta ventana.');
        exit;
    }

    http_response_code(405);
    echo 'Método no permitido';
} catch (Throwable $e) {
    if (isset($pdo) && $pdo->inTransaction()) { $pdo->rollBack(); }
    render_form('', 'Error del servidor');
}
?>


