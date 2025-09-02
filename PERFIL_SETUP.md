# Configuración de la Página de Perfil

## Descripción
Esta funcionalidad permite a los usuarios ver y editar su información de perfil, incluyendo:
- Cambio de foto de perfil (3 opciones disponibles)
- Edición de datos personales
- Edición de información de contacto
- Edición de datos del padre/madre

## Archivos Creados/Modificados

### 1. `lib/perfil.dart`
- Página principal del perfil
- Interfaz de usuario con diseño basado en Figma
- Funcionalidad de edición y guardado
- Integración con `UserManager`

### 2. `lib/user_manager.dart`
- Expandido para incluir `currentUser` con toda la información del usuario
- Nuevo método `setCurrentUser()` para actualizar datos

### 3. `lib/widgets/header_navigation.dart`
- Imagen de perfil ahora es clickeable
- Navega a `/perfil` al hacer click

### 4. `lib/main.dart`
- Agregada ruta `/perfil` para la nueva página

### 5. `lib/inicio.dart`
- Modificado para usar `setCurrentUser()` en lugar de `setUserInfo()`

### 6. `update_profile.php`
- Script PHP para manejar actualizaciones del perfil
- Validación de datos
- Conexión a base de datos MySQL

## Configuración del Servidor PHP

### 1. Subir `update_profile.php` al servidor
Colocar el archivo en: `https://zumuradigital.com/app-oblatos-login/update_profile.php`

### 2. Configurar Base de Datos
Modificar las credenciales en `update_profile.php`:

```php
$host = 'localhost';
$dbname = 'oblatos34_db';
$username = 'tu_usuario_real';
$password = 'tu_password_real';
```

### 3. Estructura de Base de Datos
Asegurarse de que la tabla `usuarios` tenga estos campos:
- `id` (INT, PRIMARY KEY)
- `nombre_menor` (VARCHAR)
- `email` (VARCHAR)
- `telefono` (VARCHAR)
- `nombre_padre_madre` (VARCHAR)
- `profile_image` (INT)
- `updated_at` (TIMESTAMP)

### 4. Agregar Campo `profile_image` (si no existe)
```sql
ALTER TABLE usuarios ADD COLUMN profile_image INT DEFAULT 1;
ALTER TABLE usuarios ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
```

## Funcionalidades Implementadas

### ✅ Completado
- [x] Página de perfil con diseño de Figma
- [x] Selección de 3 fotos de perfil
- [x] Campos editables para información personal
- [x] Botón de puntos con diseño morado
- [x] Sección de datos del padre/madre
- [x] Modo de edición con botones guardar/cancelar
- [x] Audio `ding.mp3` en interacciones
- [x] Navegación desde header
- [x] Integración con `UserManager`
- [x] Script PHP para actualizaciones

### 🔄 Pendiente de Configuración
- [ ] Configurar credenciales de base de datos en PHP
- [ ] Subir archivo PHP al servidor
- [ ] Verificar estructura de base de datos
- [ ] Probar funcionalidad completa

## Uso

### Para el Usuario
1. Hacer click en la imagen de perfil en el header superior derecho
2. Ver información del perfil
3. Click en "EDITAR PERFIL" para modificar datos
4. Seleccionar nueva foto de perfil si se desea
5. Modificar campos editables
6. Click en "GUARDAR CAMBIOS" para confirmar

### Para el Desarrollador
1. Configurar base de datos en `update_profile.php`
2. Subir archivo PHP al servidor
3. Verificar que la ruta `/perfil` funcione correctamente
4. Probar funcionalidad de edición y guardado

## Notas Técnicas

- La página usa `Provider` para manejo de estado
- Los datos se sincronizan entre la app y el servidor
- Se incluye manejo de errores y mensajes de usuario
- El diseño es responsive y sigue las especificaciones de Figma
- Se mantiene consistencia con el resto de la aplicación






