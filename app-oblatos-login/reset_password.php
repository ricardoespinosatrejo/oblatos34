<?php
// Sirve el formulario (GET con token) y procesa el cambio (POST con token y new_password)

function render_form($token, $error = '', $success = '') {
    // HTML con diseño mejorado
    echo '<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
        . '<title>Restablecer password</title>'
        . '<style>'
        . 'body{font-family:sans-serif;margin:0;padding:0;height:100vh;display:flex;align-items:center;justify-content:center;'
        . 'background:linear-gradient(180deg, #1A1B3E 0%, #2D1B69 30%, #6B2C91 70%, #E91E63 100%);'
        . 'background-attachment:fixed;}'
        . '.card{background:rgba(22,19,81,0.95);padding:32px 24px;border-radius:16px;max-width:400px;width:92%;'
        . 'box-shadow:0 12px 40px rgba(0,0,0,0.5);backdrop-filter:blur(10px);text-align:center;}'
        . '.logo-container{margin-bottom:24px;}'
        . '.logo-container img{max-width:120px;height:auto;border-radius:12px;}'
        . 'h1{font-size:28px;font-weight:bold;color:#fff;margin:0 0 24px 0;text-align:center;letter-spacing:1px;}'
        . 'label{display:block;margin:16px 0 8px;color:#fff;text-align:left;font-size:14px;}'
        . 'input{width:100%;padding:14px;border-radius:10px;border:2px solid #3949ab;background:#0d0b3a;color:#fff;'
        . 'box-sizing:border-box;font-size:15px;transition:border-color 0.3s;}'
        . 'input:focus{outline:none;border-color:#E91E63;}'
        . '.btn{margin-top:24px;width:100%;padding:14px;border:none;border-radius:24px;'
        . 'background:linear-gradient(90deg,#FF1744,#E91E63);color:#fff;font-weight:700;cursor:pointer;'
        . 'font-size:16px;transition:transform 0.2s,box-shadow 0.2s;}'
        . '.btn:hover{transform:translateY(-2px);box-shadow:0 6px 20px rgba(233,30,99,0.4);}'
        . '.btn:active{transform:translateY(0);}'
        . '.msg{margin:12px 0;padding:12px;border-radius:8px;font-size:14px;text-align:left;}'
        . '.err{background:#b00020;color:#fff;}'
        . '.ok{background:#2e7d32;color:#fff;text-align:center;}'
        . '</style></head><body><div class="card">'
        . '<div class="logo-container"><img src="anty.png" alt="Anty"></div>'
        . '<h1>App Oblatos</h1>';
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







