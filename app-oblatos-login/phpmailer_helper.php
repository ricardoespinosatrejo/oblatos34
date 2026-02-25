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
            
            // Configuración de debug - capturar output en variable global para poder mostrarlo
            global $phpmailer_debug_output;
            if (!isset($phpmailer_debug_output)) {
                $phpmailer_debug_output = '';
            }
            
            if ($config['debug']) {
                $mail->SMTPDebug = 3; // Nivel 3: mostrar TODO (conexión, comandos, respuestas)
                $mail->Debugoutput = function($str, $level) {
                    global $phpmailer_debug_output;
                    $phpmailer_debug_output .= "[$level] " . trim($str) . "\n";
                    // También enviar a error_log por si acaso
                    error_log("PHPMailer Debug [$level]: " . trim($str));
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
            
            // Intentar enviar y verificar el resultado
            $sendResult = $mail->send();
            
            // Capturar debug output si está disponible
            global $phpmailer_debug_output;
            $debugInfo = '';
            if (isset($phpmailer_debug_output) && !empty($phpmailer_debug_output)) {
                $debugInfo = $phpmailer_debug_output;
                // Limpiar para el próximo envío
                $phpmailer_debug_output = '';
            }
            
            if (!$sendResult) {
                $errorInfo = $mail->ErrorInfo ?? 'Error desconocido al enviar email';
                if ($config['debug']) {
                    error_log("PHPMailer send() retornó false: " . $errorInfo);
                }
                $errorMsg = "Error al enviar email: " . $errorInfo;
                if ($debugInfo) {
                    $errorMsg .= "\n\nDebug Info:\n" . $debugInfo;
                }
                throw new Exception($errorMsg);
            }
            
            // Si el envío fue exitoso pero queremos el debug output, guardarlo
            if ($config['debug'] && $debugInfo) {
                // Guardar en una variable global para que el script de prueba pueda acceder
                global $phpmailer_last_debug;
                $phpmailer_last_debug = $debugInfo;
            }
            
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
 * Lee todas las líneas de una respuesta SMTP hasta la línea final (código seguido de espacio, ej. "250 OK").
 * El servidor puede enviar varias líneas "250-algo"; hay que consumirlas todas.
 */
function _smtpReadResponse($socket) {
    $lastLine = '';
    while ($line = fgets($socket)) {
        $line = trim($line);
        $lastLine = $line;
        // Línea final: código de 3 dígitos + espacio (ej. "235 OK") o solo código
        if (preg_match('/^\d{3}\s/', $line) || (strlen($line) === 3 && ctype_digit($line))) {
            break;
        }
    }
    return $lastLine;
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
        throw new Exception("No se pudo conectar al servidor SMTP ($host:$port): [$errno] $errstr");
    }
    
    // Leer respuesta inicial (220)
    _smtpReadResponse($socket);
    
    // EHLO
    fwrite($socket, "EHLO $host\r\n");
    _smtpReadResponse($socket);
    
    // STARTTLS si es necesario
    if ($encryption === 'tls') {
        fwrite($socket, "STARTTLS\r\n");
        _smtpReadResponse($socket);
        stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLS_CLIENT);
        fwrite($socket, "EHLO $host\r\n");
        _smtpReadResponse($socket);
    }
    
    // Autenticación
    fwrite($socket, "AUTH LOGIN\r\n");
    _smtpReadResponse($socket);
    fwrite($socket, base64_encode($username) . "\r\n");
    _smtpReadResponse($socket);
    fwrite($socket, base64_encode($password) . "\r\n");
    $authResponse = _smtpReadResponse($socket);
    
    if (strpos($authResponse, '235') !== 0 && strpos($authResponse, '235 ') !== 0) {
        fclose($socket);
        throw new Exception("SMTP autenticación fallida. Respuesta: " . trim($authResponse));
    }
    
    // Enviar email
    fwrite($socket, "MAIL FROM: <{$config['from_email']}>\r\n");
    _smtpReadResponse($socket);
    fwrite($socket, "RCPT TO: <$to>\r\n");
    _smtpReadResponse($socket);
    fwrite($socket, "DATA\r\n");
    _smtpReadResponse($socket);
    
    $headers = "From: {$config['from_name']} <{$config['from_email']}>\r\n";
    $headers .= "To: <$to>\r\n";
    $headers .= "Subject: $subject\r\n";
    $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
    $headers .= "\r\n";
    
    fwrite($socket, $headers . $message . "\r\n.\r\n");
    _smtpReadResponse($socket);
    fwrite($socket, "QUIT\r\n");
    fclose($socket);
    
    return true;
}

