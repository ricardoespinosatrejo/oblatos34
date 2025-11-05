<?php
/**
 * Script de prueba para verificar configuración SMTP y PHPMailer
 * IMPORTANTE: Eliminar o proteger este archivo en producción
 * Puedes protegerlo con .htaccess o eliminarlo después de las pruebas
 */

// Protección básica: requerir autenticación o IP específica
// Descomenta las siguientes líneas para proteger este script:
/*
$allowedIPs = ['TU_IP_AQUI']; // Cambiar por tu IP
if (!in_array($_SERVER['REMOTE_ADDR'], $allowedIPs)) {
    die('Acceso denegado');
}
*/

error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>Test SMTP Configuration</h2>";
echo "<p><strong style='color:orange'>⚠️ ADVERTENCIA:</strong> Este archivo debería eliminarse o protegerse en producción.</p>";

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

// Verificar configuración DNS antes de probar
echo "<h3>Estado de configuración DNS:</h3>";
$domain = 'zumuradigital.com';
$spfFound = false;
$dmarcFound = false;

$spfRecords = dns_get_record($domain, DNS_TXT);
foreach ($spfRecords as $record) {
    if (isset($record['txt']) && (stripos($record['txt'], 'v=spf1') !== false)) {
        $spfFound = true;
        break;
    }
}

$dmarcRecords = dns_get_record('_dmarc.' . $domain, DNS_TXT);
foreach ($dmarcRecords as $record) {
    if (isset($record['txt']) && (stripos($record['txt'], 'v=DMARC1') !== false)) {
        $dmarcFound = true;
        break;
    }
}

echo "<ul>";
echo "<li>SPF: " . ($spfFound ? "<span style='color:green'>✓ Configurado</span>" : "<span style='color:orange'>⚠ No encontrado</span>") . "</li>";
echo "<li>DMARC: " . ($dmarcFound ? "<span style='color:green'>✓ Configurado</span>" : "<span style='color:orange'>⚠ No encontrado</span>") . "</li>";
echo "</ul>";

// Probar conexión SMTP (sin enviar email)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['test_email'])) {
    echo "<hr>";
    echo "<h3>Probando envío de email:</h3>";
    
    $testEmail = trim($_POST['test_email']);
    if (empty($testEmail)) {
        echo "<p style='color:red'><strong>✗ Error: Email no válido</strong></p>";
    } else {
        $subject = 'Test SMTP - Oblatos 34 - ' . date('Y-m-d H:i:s');
        $message = "Este es un email de prueba enviado desde el sistema Oblatos 34.\n\n";
        $message .= "Si recibes este mensaje, la configuración SMTP está funcionando correctamente.\n\n";
        $message .= "Configuración actual:\n";
        $message .= "- Servidor: {$smtpConfig['host']}:{$smtpConfig['port']}\n";
        $message .= "- Encriptación: {$smtpConfig['encryption']}\n";
        $message .= "- Remitente: {$smtpConfig['from_name']} <{$smtpConfig['from_email']}>\n\n";
        $message .= "Fecha de envío: " . date('Y-m-d H:i:s') . "\n";
        
        try {
            echo "<p><strong>Enviando email a:</strong> $testEmail</p>";
            echo "<p><strong>Asunto:</strong> $subject</p>";
            echo "<p style='color:blue;'>⏳ Procesando...</p>";
            
            // Habilitar debug temporalmente para ver qué pasa
            $originalDebug = $smtpConfig['debug'];
            $smtpConfig['debug'] = true; // Habilitar debug para la prueba
            
            // Capturar output de debug y errores
            ob_start();
            $debugOutput = ''; // Inicializar variable
            $errorLog = [];
            
            // Interceptar error_log para capturar los mensajes de debug
            $originalErrorHandler = null;
            if (function_exists('error_get_last')) {
                // Guardar errores anteriores
                $previousErrors = error_get_last();
            }
            
            // Capturar salida estándar y errores
            $result = false;
            $exceptionCaught = null;
            
            // Limpiar variable global de debug
            global $phpmailer_last_debug;
            $phpmailer_last_debug = '';
            
            try {
                $result = sendEmailWithSMTP($testEmail, $subject, $message, $smtpConfig);
                
                // Obtener debug output si está disponible
                if (isset($phpmailer_last_debug) && !empty($phpmailer_last_debug)) {
                    $debugOutput = "\n\n=== PHPMailer Debug Output (Comunicación SMTP Completa) ===\n" . $phpmailer_last_debug;
                }
            } catch (Exception $e) {
                $exceptionCaught = $e;
                $result = false;
                
                // Si la excepción tiene debug info, agregarlo
                $errorMsg = $e->getMessage();
                if (strpos($errorMsg, 'Debug Info:') !== false) {
                    $debugOutput = "\n\n=== PHPMailer Debug Output (Error) ===\n" . $errorMsg;
                } else {
                    $debugOutput = "\n\n=== Error ===\n" . $errorMsg;
                }
            }
            
            $debugOutput .= "\n\n=== Output Buffer ===\n" . ob_get_clean();
            
            // Restaurar configuración original
            $smtpConfig['debug'] = $originalDebug;
            
            // Verificar logs de PHP si están disponibles
            $phpErrors = [];
            if (function_exists('error_get_last')) {
                $lastError = error_get_last();
                if ($lastError && ($lastError !== $previousErrors)) {
                    $phpErrors[] = $lastError['message'] . ' en ' . $lastError['file'] . ':' . $lastError['line'];
                }
            }
            
            if ($exceptionCaught) {
                echo "<div style='background:#f8d7da;padding:15px;border-left:4px solid #dc3545;margin:15px 0;'>";
                echo "<p style='color:red;font-size:18px;margin:0;'><strong>✗ Error al enviar email</strong></p>";
                echo "<pre style='background:#fff;padding:10px;border:1px solid #ccc;max-height:300px;overflow:auto;'>" . htmlspecialchars($exceptionCaught->getMessage()) . "</pre>";
                echo "</div>";
                
                if ($debugOutput) {
                    echo "<details style='margin-top:15px;'>";
                    echo "<summary style='cursor:pointer;color:#dc3545;'>Ver detalles de debug (click para expandir)</summary>";
                    echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;max-height:400px;overflow:auto;'>" . htmlspecialchars($debugOutput) . "</pre>";
                    echo "</details>";
                }
            } elseif ($result) {
                echo "<div style='background:#d4edda;padding:15px;border-left:4px solid #28a745;margin:15px 0;'>";
                echo "<p style='color:green;font-size:18px;margin:0;'><strong>✓ Email aceptado por el servidor SMTP</strong></p>";
                echo "<p><strong>⚠️ Importante:</strong> El servidor SMTP aceptó el email, pero si no llega, puede ser:</p>";
                echo "<ul>";
                echo "<li>El servidor SMTP no está realmente enviando el email (solo lo acepta)</li>";
                echo "<li>El email está en cola y tardará más tiempo</li>";
                echo "<li>Filtros de spam están bloqueando el email</li>";
                echo "<li>Problema de configuración en el servidor SMTP</li>";
                echo "</ul>";
                echo "<p><strong>Revisa tu bandeja de entrada (y carpeta de spam) en unos minutos.</strong></p>";
                echo "</div>";
                
                // Mostrar información de debug
                if ($debugOutput || !empty($phpErrors)) {
                    echo "<details style='margin-top:15px;'>";
                    echo "<summary style='cursor:pointer;color:#007bff;'>Ver detalles de comunicación SMTP (click para expandir)</summary>";
                    echo "<div style='background:#f0f0f0;padding:10px;border:1px solid #ccc;max-height:400px;overflow:auto;'>";
                    if ($debugOutput) {
                        echo "<h5>Debug Output:</h5>";
                        echo "<pre>" . htmlspecialchars($debugOutput) . "</pre>";
                    }
                    if (!empty($phpErrors)) {
                        echo "<h5>Errores PHP:</h5>";
                        echo "<pre>" . htmlspecialchars(implode("\n", $phpErrors)) . "</pre>";
                    }
                    echo "</div>";
                    echo "</details>";
                }
                
                echo "<div style='background:#fff3cd;padding:15px;border-left:4px solid #ffc107;margin:15px 0;'>";
                echo "<h5>🔍 Diagnóstico:</h5>";
                echo "<p><strong>El servidor SMTP está aceptando el email correctamente</strong>, pero si no llega, el problema está en el servidor SMTP, no en el código.</p>";
                
                // Buscar ID del mensaje en el debug output
                $messageId = '';
                if (preg_match('/250 OK id=([^\s]+)/', $debugOutput, $matches)) {
                    $messageId = $matches[1];
                    echo "<p><strong>ID del mensaje:</strong> <code>$messageId</code></p>";
                    echo "<p><small>Comparte este ID con tu proveedor de hosting para que busquen el email en los logs.</small></p>";
                }
                
                echo "<p><strong>Próximos pasos:</strong></p>";
                echo "<ol>";
                echo "<li><strong>Contacta a tu proveedor de hosting</strong> (GoDaddy/Zumura Digital) y pregunta:</li>";
                echo "<ul>";
                echo "<li>¿El servidor SMTP está configurado para ENVIAR emails o solo para aceptarlos?</li>";
                echo "<li>¿Hay restricciones que bloqueen el envío a dominios externos?</li>";
                echo "<li>¿Pueden revisar los logs del servidor con el ID del mensaje?</li>";
                echo "</ul>";
                echo "<li><strong>Revisa la carpeta de spam</strong> del destinatario</li>";
                echo "<li><strong>Prueba con otro email</strong> (Gmail, Outlook, etc.) para descartar problemas del destinatario</li>";
                echo "<li><strong>Verifica que el servidor SMTP está realmente enviando</strong> y no solo aceptando</li>";
                echo "</ol>";
                echo "<p><strong>💡 Tip:</strong> El servidor está aceptando correctamente, así que el código funciona. El problema es que el servidor SMTP necesita configuración adicional para enviar emails.</p>";
                echo "</div>";
            } else {
                echo "<div style='background:#f8d7da;padding:15px;border-left:4px solid #dc3545;margin:15px 0;'>";
                echo "<p style='color:red;font-size:18px;margin:0;'><strong>✗ Error al enviar email</strong></p>";
                echo "<p>El servidor SMTP no pudo enviar el email. Verifica:</p>";
                echo "<ul>";
                echo "<li>Las credenciales en smtp_config.php son correctas</li>";
                echo "<li>El servidor SMTP está accesible</li>";
                echo "<li>El puerto {$smtpConfig['port']} no está bloqueado por firewall</li>";
                echo "</ul>";
                echo "</div>";
                
                if ($debugOutput) {
                    echo "<details style='margin-top:15px;'>";
                    echo "<summary style='cursor:pointer;color:#dc3545;'>Ver detalles de error (click para expandir)</summary>";
                    echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;max-height:400px;overflow:auto;'>" . htmlspecialchars($debugOutput) . "</pre>";
                    echo "</details>";
                }
            }
        } catch (Exception $e) {
            echo "<div style='background:#f8d7da;padding:15px;border-left:4px solid #dc3545;margin:15px 0;'>";
            echo "<p style='color:red;font-size:18px;margin:0;'><strong>✗ Excepción capturada:</strong></p>";
            echo "<pre style='background:#fff;padding:10px;border:1px solid #ccc;max-height:300px;overflow:auto;'>" . htmlspecialchars($e->getMessage()) . "</pre>";
            echo "</div>";
            
            echo "<details style='margin-top:15px;'>";
            echo "<summary style='cursor:pointer;color:#dc3545;'>Ver stack trace completo (click para expandir)</summary>";
            echo "<pre style='background:#f0f0f0;padding:10px;border:1px solid #ccc;max-height:400px;overflow:auto;'>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
            echo "</details>";
        }
    }
} else {
    ?>
    <hr>
    <h3>Prueba de envío:</h3>
    <form method="POST" style="background:#f8f9fa;padding:20px;border-radius:8px;max-width:500px;">
        <div style="margin-bottom:15px;">
            <label style="display:block;margin-bottom:5px;font-weight:bold;">Email de destino:</label>
            <input type="email" name="test_email" value="<?php echo htmlspecialchars($smtpConfig['username']); ?>" 
                   style="padding: 10px; width: 100%; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box;" 
                   required placeholder="tu-email@ejemplo.com">
            <small style="color:#666;">Ingresa el email donde quieres recibir la prueba</small>
        </div>
        <button type="submit" style="padding: 12px 24px; background: #007cba; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; font-weight: bold;">
            📧 Enviar Email de Prueba
        </button>
    </form>
    <div style="background:#fff3cd;padding:15px;border-left:4px solid #ffc107;margin:15px 0;max-width:500px;">
        <p style="margin:0;"><strong>⚠️ Nota:</strong> Este script enviará un email de prueba. Asegúrate de que las credenciales en smtp_config.php sean correctas.</p>
    </div>
    <?php
}

echo "<hr>";
echo "<p><small>Para ver logs detallados, habilita 'debug' => true en smtp_config.php</small></p>";
?>
