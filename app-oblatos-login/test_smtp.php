<?php
/**
 * Script de prueba para verificar configuración SMTP y PHPMailer
 * Accede desde: https://zumuradigital.com/app-oblatos-login/test_smtp.php
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>Test SMTP Configuration</h2>";

// Cargar configuración
$smtpConfig = require __DIR__ . '/smtp_config.php';
echo "<h3>Configuración actual:</h3>";
echo "<pre>";
print_r($smtpConfig);
echo "</pre>";

// Verificar rutas de PHPMailer
echo "<h3>Buscando PHPMailer:</h3>";
$phpmailerPaths = [
    __DIR__ . '/PHPMailer/PHPMailer.php',
    __DIR__ . '/PHPMailer-7.0.0/src/PHPMailer.php',
    __DIR__ . '/PHPMailer-7.0.0/PHPMailer.php',
    __DIR__ . '/vendor/phpmailer/phpmailer/src/PHPMailer.php',
];

$found = false;
foreach ($phpmailerPaths as $path) {
    $exists = file_exists($path);
    echo "Path: $path - " . ($exists ? "<strong style='color:green'>EXISTS</strong>" : "<span style='color:red'>NOT FOUND</span>") . "<br>";
    if ($exists) {
        $found = true;
        $basePath = dirname($path);
        echo "Base path: $basePath<br>";
        
        // Verificar archivos relacionados
        $smtpFile = $basePath . '/SMTP.php';
        $srcSmtpFile = $basePath . '/src/SMTP.php';
        $exceptionFile = $basePath . '/Exception.php';
        $srcExceptionFile = $basePath . '/src/Exception.php';
        
        echo "SMTP.php: " . (file_exists($smtpFile) ? $smtpFile : (file_exists($srcSmtpFile) ? $srcSmtpFile : "NOT FOUND")) . "<br>";
        echo "Exception.php: " . (file_exists($exceptionFile) ? $exceptionFile : (file_exists($srcExceptionFile) ? $srcExceptionFile : "NOT FOUND")) . "<br>";
    }
}

if (!$found) {
    echo "<p style='color:red'><strong>PHPMailer no encontrado. Verifica que la carpeta PHPMailer-7.0.0 esté en app-oblatos-login/</strong></p>";
    exit;
}

// Intentar cargar PHPMailer
echo "<h3>Intentando cargar PHPMailer:</h3>";
require_once __DIR__ . '/phpmailer_helper.php';

// Probar conexión SMTP (sin enviar email)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['test_email'])) {
    echo "<h3>Probando envío de email:</h3>";
    
    $testEmail = $_POST['test_email'];
    $subject = 'Test SMTP - Oblatos 34';
    $message = 'Este es un email de prueba. Si recibes este mensaje, la configuración SMTP está funcionando correctamente.';
    
    try {
        // Capturar output de debug si está habilitado
        ob_start();
        $result = sendEmailWithSMTP($testEmail, $subject, $message, $smtpConfig);
        $debugOutput = ob_get_clean();
        
        if ($result) {
            echo "<p style='color:green'><strong>✓ Email enviado exitosamente a: $testEmail</strong></p>";
            echo "<p>Revisa tu bandeja de entrada (y carpeta de spam) en unos minutos.</p>";
            if ($debugOutput) {
                echo "<h4>Debug Output:</h4><pre>" . htmlspecialchars($debugOutput) . "</pre>";
            }
        } else {
            echo "<p style='color:red'><strong>✗ Error al enviar email</strong></p>";
            if ($debugOutput) {
                echo "<h4>Debug Output:</h4><pre>" . htmlspecialchars($debugOutput) . "</pre>";
            }
            echo "<p>Revisa los logs de error del servidor o habilita debug en smtp_config.php</p>";
        }
    } catch (Exception $e) {
        echo "<p style='color:red'><strong>✗ Excepción capturada:</strong></p>";
        echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;'>" . htmlspecialchars($e->getMessage()) . "</pre>";
        echo "<p><strong>Stack trace:</strong></p>";
        echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;'>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
    }
} else {
    ?>
    <h3>Prueba de envío:</h3>
    <form method="POST">
        <label>Email de prueba:</label><br>
        <input type="email" name="test_email" value="<?php echo htmlspecialchars($smtpConfig['username']); ?>" style="padding: 5px; width: 300px;"><br><br>
        <button type="submit" style="padding: 10px 20px; background: #007cba; color: white; border: none; cursor: pointer;">Enviar Email de Prueba</button>
    </form>
    <p><small>Nota: Este script enviará un email de prueba. Asegúrate de que las credenciales en smtp_config.php sean correctas.</small></p>
    <?php
}

echo "<hr>";
echo "<p><small>Para ver logs detallados, habilita 'debug' => true en smtp_config.php</small></p>";
?>

