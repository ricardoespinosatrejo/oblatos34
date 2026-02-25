<?php
/**
 * Prueba de envío de email (recuperación de contraseña).
 * Sube este archivo a admin-playcoop/ y abre en el navegador:
 *   https://playcoop.com.mx/admin-playcoop/test_email_send.php?email=TU_EMAIL
 * Sustituye TU_EMAIL por un correo real donde quieras recibir la prueba.
 * BORRA este archivo cuando termines de depurar.
 */
header('Content-Type: text/html; charset=UTF-8');
error_reporting(E_ALL);
ini_set('display_errors', 1);

$testEmail = isset($_GET['email']) ? trim($_GET['email']) : '';
if ($testEmail === '') {
    echo '<p style="color:red">Usa: <code>?email=tu_correo@ejemplo.com</code> en la URL.</p>';
    exit;
}

echo "<h2>Prueba de envío SMTP (recuperación de contraseña)</h2>";

// Misma ruta que recuperar_password: mismo directorio
$configPath = __DIR__ . '/smtp_config.php';
$helperPath = __DIR__ . '/phpmailer_helper.php';

if (!file_exists($configPath)) {
    echo "<p style='color:red'>No se encontró <code>smtp_config.php</code> en " . __DIR__ . "</p>";
    exit;
}
if (!file_exists($helperPath)) {
    echo "<p style='color:red'>No se encontró <code>phpmailer_helper.php</code> en " . __DIR__ . "</p>";
    exit;
}

$smtpConfig = require $configPath;
require_once $helperPath;

echo "<p><strong>Enviando correo de prueba a:</strong> " . htmlspecialchars($testEmail) . "</p>";
echo "<p>Host SMTP: " . htmlspecialchars($smtpConfig['host']) . ":" . $smtpConfig['port'] . " (" . $smtpConfig['encryption'] . ")</p>";

try {
    $subject = 'Prueba recuperación - Oblatos34';
    $body = "Este es un correo de prueba.\nSi lo recibes, el envío desde el servidor funciona.";
    $ok = sendEmailWithSMTP($testEmail, $subject, $body, $smtpConfig);
    if ($ok) {
        echo "<p style='color:green; font-weight:bold'>Correo enviado correctamente. Revisa la bandeja (y spam) de " . htmlspecialchars($testEmail) . "</p>";
    } else {
        echo "<p style='color:red'>sendEmailWithSMTP devolvió false (sin mensaje de error).</p>";
    }
} catch (Exception $e) {
    echo "<p style='color:red'><strong>Error:</strong> " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<p>Revisa host, puerto, usuario y contraseña en <code>smtp_config.php</code>. Algunos servidores usan <code>smtp.playcoop.com.mx</code> y puerto 587 con TLS.</p>";
}
