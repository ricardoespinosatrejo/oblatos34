# Configuración SMTP para Recuperación de Password

## Archivos creados:
- `smtp_config.php` - Configuración SMTP (editar con tus credenciales)
- `phpmailer_helper.php` - Helper para envío de emails
- `recuperar_password.php` - Actualizado para usar SMTP

## Configuración rápida:

### 1. Editar `smtp_config.php`

Abre el archivo `app-oblatos-login/smtp_config.php` y ajusta estos valores:

```php
'host' => 'smtp.tu-servidor.com', // Ejemplo: smtp.gmail.com, smtp.zumuradigital.com
'port' => 587, // 587 (TLS), 465 (SSL), o 25 (sin cifrado)
'encryption' => 'tls', // 'tls', 'ssl', o '' (sin cifrado)
'username' => 'tu-email@zumuradigital.com',
'password' => 'tu-password',
'from_email' => 'no-reply@zumuradigital.com',
'from_name' => 'Oblatos 34',
```

### 2. Opciones de configuración:

#### Opción A: Usar Gmail
```php
'host' => 'smtp.gmail.com',
'port' => 587,
'encryption' => 'tls',
'username' => 'tu-email@gmail.com',
'password' => 'tu-app-password', // Necesitas crear "App Password" en Gmail
```

#### Opción B: Usar servidor SMTP propio
```php
'host' => 'smtp.zumuradigital.com', // Consulta con tu hosting
'port' => 587, // O el puerto que te indique tu hosting
'encryption' => 'tls',
'username' => 'no-reply@zumuradigital.com',
'password' => 'password-del-servidor',
```

#### Opción C: Deshabilitar SMTP (usar mail() nativo)
```php
'enabled' => false, // Usará mail() de PHP si está disponible
```

### 3. Opcional: Instalar PHPMailer (recomendado)

El sistema funciona sin PHPMailer (usa socket SMTP nativo), pero PHPMailer es más robusto.

**Opción 1: Descargar manualmente**
1. Descarga PHPMailer desde: https://github.com/PHPMailer/PHPMailer/releases
2. Extrae y coloca la carpeta `PHPMailer` dentro de `app-oblatos-login/`
3. La estructura debería ser: `app-oblatos-login/PHPMailer/PHPMailer.php`

**Opción 2: Usar composer (si tienes acceso)**
```bash
cd app-oblatos-login
composer require phpmailer/phpmailer
```

### 4. Probar el sistema

1. Sube todos los archivos a tu servidor
2. Asegúrate de que `smtp_config.php` tenga las credenciales correctas
3. Prueba recuperar password desde la app
4. Revisa tu bandeja de entrada (y spam)

### 5. Debugging

Si no funciona, habilita el modo debug en `smtp_config.php`:
```php
'debug' => true,
```

Esto mostrará logs de depuración en el error_log de PHP.

## Notas importantes:

- **Seguridad**: Nunca subas `smtp_config.php` con credenciales reales a repositorios públicos
- **Gmail**: Si usas Gmail, necesitas crear una "App Password" en tu cuenta de Google
- **Hosting**: Consulta con tu proveedor de hosting las credenciales SMTP si no las conoces
- **Firewall**: Asegúrate de que el puerto SMTP (587, 465, etc.) no esté bloqueado

## Soporte común:

- **Gmail**: smtp.gmail.com:587 (TLS)
- **Outlook/Hotmail**: smtp-mail.outlook.com:587 (TLS)
- **Yahoo**: smtp.mail.yahoo.com:587 (TLS)
- **cPanel**: Consulta con tu hosting, generalmente smtp.tu-dominio.com:587



























