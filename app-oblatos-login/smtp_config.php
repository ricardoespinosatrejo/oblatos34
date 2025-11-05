<?php
// Configuración SMTP para envío de emails
// Ajusta estos valores según tu proveedor de hosting/correo

return [
    'enabled' => false, // Cambiar a false para deshabilitar SMTP y usar mail() nativo
    
    // Configuración SMTP
    'host' => 'zumuradigital.com', // Cambiar a 'mail.zumuradigital.com' si smtp no funciona
    'port' => 465, // Puerto común: 587 (TLS), 465 (SSL), 25 (sin cifrado)
    'encryption' => 'ssl', // 'tls', 'ssl', o '' (sin cifrado)
    
    // Credenciales del servidor SMTP
    'username' => 'contacto-app@zumuradigital.com', // Email que envía los mensajes
    'password' => '5540855457Mexico***', // Password de la cuenta o "App Password" si usas Gmail
    
    // Remitente
    'from_email' => 'contacto-app@zumuradigital.com',
    'from_name' => 'Contacto App Oblatos',
    
    // Configuración adicional
    'timeout' => 30, // Timeout en segundos
    'debug' => false, // Cambiar a true para ver logs de depuración
];

