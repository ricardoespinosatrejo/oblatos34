<?php
/**
 * Helper para enviar emails usando SMTP
 * Compatible con PHPMailer o funciones nativas según configuración
 */

function sendEmailWithSMTP($to, $subject, $message, $config) {
    // Si SMTP está deshabilitado, usar mail() nativo
    if (!$config['enabled']) {
        $headers = 'From: ' . $config['from_name'] . ' <' . $config['from_email'] . '>' . "\r\n" .
                   'Content-Type: text/plain; charset=UTF-8';
        return @mail($to, $subject, $message, $headers);
    }
    
    // Intentar usar PHPMailer si está disponible
    // Buscar en diferentes ubicaciones posibles
    $phpmailerPaths = [
        __DIR__ . '/PHPMailer/PHPMailer.php',
        __DIR__ . '/PHPMailer-7.0.0/src/PHPMailer.php',
        __DIR__ . '/PHPMailer-7.0.0/PHPMailer.php',
        __DIR__ . '/vendor/phpmailer/phpmailer/src/PHPMailer.php',
    ];
    
    $phpmailerPath = null;
    foreach ($phpmailerPaths as $path) {
        if (file_exists($path)) {
            $phpmailerPath = $path;
            break;
        }
    }
    
    if ($phpmailerPath) {
        // Determinar la ruta base de PHPMailer
        $basePath = dirname($phpmailerPath);
        
        // Cargar archivos según la estructura encontrada
        require_once $phpmailerPath;
        
        // Intentar cargar SMTP.php y Exception.php desde diferentes ubicaciones
        // Si está en src/, los archivos están en el mismo directorio
        $smtpPaths = [
            $basePath . '/SMTP.php',  // Mismo directorio que PHPMailer.php
            dirname($basePath) . '/SMTP.php',  // Un nivel arriba
            dirname($basePath) . '/src/SMTP.php',  // En src/ un nivel arriba
        ];
        $exceptionPaths = [
            $basePath . '/Exception.php',  // Mismo directorio que PHPMailer.php
            dirname($basePath) . '/Exception.php',  // Un nivel arriba
            dirname($basePath) . '/src/Exception.php',  // En src/ un nivel arriba
        ];
        
        foreach ($smtpPaths as $path) {
            if (file_exists($path)) {
                require_once $path;
                break;
            }
        }
        
        foreach ($exceptionPaths as $path) {
            if (file_exists($path)) {
                require_once $path;
                break;
            }
        }
        
        // Crear instancia de PHPMailer (probamos diferentes namespaces)
        try {
            $mail = null;
            if (class_exists('PHPMailer\PHPMailer\PHPMailer')) {
                $mail = new PHPMailer\PHPMailer\PHPMailer(true);
            } elseif (class_exists('PHPMailer')) {
                $mail = new PHPMailer(true);
            } else {
                throw new \Exception('PHPMailer class not found. Available classes: ' . implode(', ', get_declared_classes()));
            }
            
            if (!$mail) {
                throw new \Exception('No se pudo crear instancia de PHPMailer');
            }
        } catch (\Exception $e) {
            if ($config['debug']) {
                error_log("Error inicializando PHPMailer: " . $e->getMessage());
            }
            throw new \Exception("Error inicializando PHPMailer: " . $e->getMessage());
        }
        
        try {
            // Configuración del servidor
            $mail->isSMTP();
            $mail->Host = $config['host'];
            $mail->SMTPAuth = true;
            $mail->Username = $config['username'];
            $mail->Password = $config['password'];
            $mail->SMTPSecure = $config['encryption'];
            $mail->Port = $config['port'];
            $mail->CharSet = 'UTF-8';
            $mail->Timeout = $config['timeout'];
            
            // Configuración de debug
            if ($config['debug']) {
                $mail->SMTPDebug = 2; // Mostrar información detallada
                $mail->Debugoutput = function($str, $level) {
                    error_log("PHPMailer Debug [$level]: $str");
                };
            }
            
            // Mejoras para Gmail y otros proveedores
            $mail->XMailer = 'Oblatos 34 App'; // Identificador del remitente
            $mail->Priority = 3; // Prioridad normal (1=alta, 3=normal, 5=baja)
            
            // Remitente y destinatario
            $mail->setFrom($config['from_email'], $config['from_name']);
            $mail->addAddress($to);
            
            // Agregar Reply-To (importante para Gmail)
            $mail->addReplyTo($config['from_email'], $config['from_name']);
            
            // Headers adicionales para mejorar la entrega
            $mail->addCustomHeader('List-Unsubscribe', '<mailto:' . $config['from_email'] . '>');
            $mail->addCustomHeader('X-Auto-Response-Suppress', 'All');
            
            // Contenido
            $mail->isHTML(false);
            $mail->Subject = $subject;
            $mail->Body = $message;
            
            // Codificación mejorada
            $mail->Encoding = 'base64'; // Mejor compatibilidad con Gmail
            
            $mail->send();
            return true;
        } catch (\Exception $e) {
            $errorMsg = '';
            if (isset($mail) && property_exists($mail, 'ErrorInfo')) {
                $errorMsg = $mail->ErrorInfo;
            } else {
                $errorMsg = $e->getMessage();
            }
            
            if ($config['debug']) {
                error_log("Error PHPMailer: " . $errorMsg);
                error_log("Stack trace: " . $e->getTraceAsString());
            }
            
            // Lanzar excepción con más información para que el script de prueba la capture
            throw new Exception("PHPMailer Error: " . $errorMsg);
        }
    }
    
    // Fallback: usar socket SMTP manual si PHPMailer no está disponible
    return sendEmailWithSocketSMTP($to, $subject, $message, $config);
}

/**
 * Envío de email usando socket SMTP (sin dependencias externas)
 */
function sendEmailWithSocketSMTP($to, $subject, $message, $config) {
    $host = $config['host'];
    $port = $config['port'];
    $username = $config['username'];
    $password = $config['password'];
    $encryption = $config['encryption'];
    
    // Crear socket
    $context = stream_context_create([
        'ssl' => [
            'verify_peer' => false,
            'verify_peer_name' => false,
            'allow_self_signed' => true
        ]
    ]);
    
    $socket = @stream_socket_client(
        ($encryption === 'ssl' ? 'ssl://' : '') . $host . ':' . $port,
        $errno,
        $errstr,
        $config['timeout'],
        STREAM_CLIENT_CONNECT,
        $context
    );
    
    if (!$socket) {
        return false;
    }
    
    // Leer respuesta inicial
    fgets($socket);
    
    // EHLO
    fwrite($socket, "EHLO $host\r\n");
    fgets($socket);
    
    // STARTTLS si es necesario
    if ($encryption === 'tls') {
        fwrite($socket, "STARTTLS\r\n");
        fgets($socket);
        stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLS_CLIENT);
        fwrite($socket, "EHLO $host\r\n");
        fgets($socket);
    }
    
    // Autenticación
    fwrite($socket, "AUTH LOGIN\r\n");
    fgets($socket);
    fwrite($socket, base64_encode($username) . "\r\n");
    fgets($socket);
    fwrite($socket, base64_encode($password) . "\r\n");
    $authResponse = fgets($socket);
    
    if (strpos($authResponse, '235') === false) {
        fclose($socket);
        return false;
    }
    
    // Enviar email
    fwrite($socket, "MAIL FROM: <{$config['from_email']}>\r\n");
    fgets($socket);
    fwrite($socket, "RCPT TO: <$to>\r\n");
    fgets($socket);
    fwrite($socket, "DATA\r\n");
    fgets($socket);
    
    $headers = "From: {$config['from_name']} <{$config['from_email']}>\r\n";
    $headers .= "To: <$to>\r\n";
    $headers .= "Subject: $subject\r\n";
    $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
    $headers .= "\r\n";
    
    fwrite($socket, $headers . $message . "\r\n.\r\n");
    fgets($socket);
    fwrite($socket, "QUIT\r\n");
    fclose($socket);
    
    return true;
}

