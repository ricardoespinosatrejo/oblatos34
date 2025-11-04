<?php
// Configuración SMTP para envío de emails
// Ajusta estos valores según tu proveedor de hosting/correo

return [
    'enabled' => true, // Cambiar a false para deshabilitar SMTP y usar mail() nativo
    
    // Configuración SMTP
    'host' => 'smtp.gmail.com', // Ejemplo: smtp.gmail.com, smtp.zumuradigital.com, etc.
    'port' => 587, // Puerto común: 587 (TLS), 465 (SSL), 25 (sin cifrado)
    'encryption' => 'tls', // 'tls', 'ssl', o '' (sin cifrado)
    
    // Credenciales del servidor SMTP
    'username' => 'tu-email@zumuradigital.com', // Email que envía los mensajes
    'password' => 'tu-password-app', // Password de la cuenta o "App Password" si usas Gmail
    
    // Remitente
    'from_email' => 'no-reply@zumuradigital.com',
    'from_name' => 'Oblatos 34',
    
    // Configuración adicional
    'timeout' => 30, // Timeout en segundos
    'debug' => false, // Cambiar a true para ver logs de depuración
];

