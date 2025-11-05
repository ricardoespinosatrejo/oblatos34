<?php
/**
 * Script de prueba rápida para mail() nativo de PHP
 * Úsalo cuando SMTP no funciona
 */

header('Content-Type: text/html; charset=utf-8');
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>Test mail() nativo de PHP</h2>";
echo "<p><strong style='color:orange'>⚠️ Esta prueba usa mail() nativo, no SMTP.</strong></p>";

// Cargar configuración
$smtpConfig = require __DIR__ . '/smtp_config.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['test_email'])) {
    $testEmail = trim($_POST['test_email']);
    
    if (empty($testEmail)) {
        echo "<p style='color:red'><strong>✗ Error: Email no válido</strong></p>";
    } else {
        $subject = 'Test mail() nativo - Oblatos 34 - ' . date('Y-m-d H:i:s');
        $message = "Este es un email de prueba usando mail() nativo de PHP.\n\n";
        $message .= "Si recibes este mensaje, mail() está funcionando en tu servidor.\n\n";
        $message .= "Fecha de envío: " . date('Y-m-d H:i:s') . "\n";
        
        $headers = 'From: ' . $smtpConfig['from_name'] . ' <' . $smtpConfig['from_email'] . '>' . "\r\n" .
                   'Content-Type: text/plain; charset=UTF-8' . "\r\n" .
                   'X-Mailer: PHP/' . phpversion();
        
        echo "<p><strong>Enviando email a:</strong> $testEmail</p>";
        echo "<p><strong>Usando:</strong> mail() nativo de PHP</p>";
        echo "<p style='color:blue;'>⏳ Procesando...</p>";
        
        $result = @mail($testEmail, $subject, $message, $headers);
        
        if ($result) {
            echo "<div style='background:#d4edda;padding:15px;border-left:4px solid #28a745;margin:15px 0;'>";
            echo "<p style='color:green;font-size:18px;margin:0;'><strong>✓ Email enviado usando mail() nativo</strong></p>";
            echo "<p>Revisa tu bandeja de entrada (y carpeta de spam) en unos minutos.</p>";
            echo "<p><strong>Nota:</strong> mail() puede no funcionar en todos los servidores. Si no llega, prueba con SMTP o un servicio externo.</p>";
            echo "</div>";
        } else {
            echo "<div style='background:#f8d7da;padding:15px;border-left:4px solid #dc3545;margin:15px 0;'>";
            echo "<p style='color:red;font-size:18px;margin:0;'><strong>✗ Error: mail() no funcionó</strong></p>";
            echo "<p>La función mail() de PHP no está disponible o no está configurada en este servidor.</p>";
            echo "<p><strong>Alternativas:</strong></p>";
            echo "<ul>";
            echo "<li>Usar SMTP (si está configurado)</li>";
            echo "<li>Usar un servicio externo (SendGrid, Mailgun, etc.)</li>";
            echo "<li>Contactar al proveedor de hosting para configurar mail()</li>";
            echo "</ul>";
            echo "</div>";
            
            // Mostrar último error si está disponible
            $lastError = error_get_last();
            if ($lastError && strpos($lastError['message'], 'mail') !== false) {
                echo "<details style='margin-top:15px;'>";
                echo "<summary style='cursor:pointer;color:#dc3545;'>Ver detalles del error</summary>";
                echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;'>" . htmlspecialchars($lastError['message']) . "</pre>";
                echo "</details>";
            }
        }
    }
} else {
    ?>
    <hr>
    <h3>Prueba de envío con mail() nativo:</h3>
    <form method="POST" style="background:#f8f9fa;padding:20px;border-radius:8px;max-width:500px;">
        <div style="margin-bottom:15px;">
            <label style="display:block;margin-bottom:5px;font-weight:bold;">Email de destino:</label>
            <input type="email" name="test_email" value="<?php echo htmlspecialchars($smtpConfig['username']); ?>" 
                   style="padding: 10px; width: 100%; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box;" 
                   required placeholder="tu-email@ejemplo.com">
            <small style="color:#666;">Ingresa el email donde quieres recibir la prueba</small>
        </div>
        <button type="submit" style="padding: 12px 24px; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; font-weight: bold;">
            📧 Enviar Email con mail() nativo
        </button>
    </form>
    <div style="background:#fff3cd;padding:15px;border-left:4px solid #ffc107;margin:15px 0;max-width:500px;">
        <p style="margin:0;"><strong>⚠️ Nota:</strong> Esta prueba usa mail() nativo de PHP, no SMTP. Puede no funcionar en todos los servidores.</p>
    </div>
    <?php
}

echo "<hr>";
echo "<h3>Información del servidor:</h3>";
echo "<ul>";
echo "<li><strong>PHP Version:</strong> " . phpversion() . "</li>";
echo "<li><strong>mail() disponible:</strong> " . (function_exists('mail') ? '✅ Sí' : '❌ No') . "</li>";
echo "<li><strong>sendmail_path:</strong> " . ini_get('sendmail_path') . "</li>";
echo "<li><strong>SMTP (si está configurado):</strong> " . ini_get('SMTP') . "</li>";
echo "</ul>";

echo "<hr>";
echo "<p><a href='test_smtp.php'>← Volver a prueba SMTP</a></p>";
?>



