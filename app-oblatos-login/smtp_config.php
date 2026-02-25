<?php
// Configuración SMTP para envío de emails
// Ajusta estos valores según tu proveedor de hosting/correo

return [
    'enabled' => true, // Usar SMTP para envío
    
    // Configuración SMTP (ajusta host/puerto si tu hosting indica otros valores)
    // Si falla, prueba: 'host' => 'smtp.playcoop.com.mx', 'port' => 587, 'encryption' => 'tls'
    'host' => 'mail.playcoop.com.mx',
    'port' => 465, // 465 (SSL) o 587 (TLS) según hosting
    'encryption' => 'ssl', // 'tls', 'ssl', o '' (sin cifrado)
    
    // Credenciales del servidor SMTP
    'username' => 'password@playcoop.com.mx', // Email que envía los mensajes
    'password' => 'U=d&ByysDn4zd#SF', // Password de la cuenta
    
    // Remitente
    'from_email' => 'password@playcoop.com.mx',
    'from_name' => 'Recuperación de contraseña Oblatos34',
    
    // Configuración adicional
    'timeout' => 30, // Timeout en segundos
    'debug' => false, // Cambiar a true para ver logs de depuración
];

