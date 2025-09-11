# Sistema de Snippets - Configuración y Uso

## 📋 Descripción General

El sistema de snippets implementa fichas informativas que aparecen automáticamente mientras el usuario navega por la aplicación. Cada snippet otorga 10 puntos al usuario y se muestra con un contador regresivo de 10 segundos.

## 🎯 Características Implementadas

### ✅ Funcionalidades Principales
- **Aparición automática**: Los snippets aparecen en tiempos progresivos (30s, 45s, 60s, 90s, 150s...)
- **Selección aleatoria**: Cada snippet se selecciona aleatoriamente de los 12 disponibles
- **Contador regresivo**: Muestra cuenta regresiva de 10 segundos
- **Sistema de puntos**: Otorga 10 puntos por snippet visto (solo si se completa el contador)
- **Prevención de duplicados**: No muestra el mismo snippet dos veces en el mismo día
- **Animaciones**: Fade-in y scale animations para una experiencia fluida
- **Sonido**: Reproduce sonido al ganar puntos
- **Control inteligente**: Los snippets NO aparecen durante el juego ni la calculadora
- **Cierre manual**: Click en la imagen del snippet para cerrarlo (sin puntos)
- **Fade-in del fondo**: Animación suave del fondo del snippet

### 📱 Interfaz de Usuario
- **Overlay completo**: Aparece encima de toda la interfaz
- **Fondo semitransparente**: Permite ver el contenido de fondo
- **Imagen de snippet**: Centrada, clickeable y con bordes redondeados
- **Contador visual**: Muestra el tiempo restante
- **Mensaje de puntos**: "¡Ganaste 10 puntos!" después del contador
- **Botón de cerrar**: Opcional en la esquina superior derecha
- **Fade-in del fondo**: Animación suave de aparición del fondo

## 🗂️ Archivos Creados/Modificados

### Nuevos Archivos
1. **`lib/widgets/snippet_overlay.dart`** - Widget principal del overlay
2. **`lib/services/snippet_service.dart`** - Servicio para manejar la lógica de snippets
3. **`add_snippet_points.php`** - API PHP para agregar puntos
4. **`create_snippet_points_table.sql`** - Script SQL para crear tablas

### Archivos Modificados
1. **`pubspec.yaml`** - Agregada carpeta de imágenes snippets
2. **`lib/main_container.dart`** - Integración del sistema de snippets
3. **`lib/user_manager.dart`** - Método `updateUserPoints()` agregado
4. **`lib/juego.dart`** - Control de snippets durante el juego
5. **`lib/calculadora.dart`** - Control de snippets durante la calculadora

## 🖼️ Imágenes Requeridas

Las siguientes imágenes deben estar en `assets/images/snippets/`:
- `Snippets-back.jpg` - Fondo del overlay
- `snippet-01.png` a `snippet-12.png` - Imágenes de los snippets

## 🗄️ Base de Datos

### Tabla: `snippet_points`
```sql
CREATE TABLE snippet_points (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    snippet_id VARCHAR(50) NOT NULL,
    points INT DEFAULT 10,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_snippet_date (user_id, snippet_id, DATE(created_at))
);
```

### Columna Agregada: `usuarios.puntos_diarios`
```sql
ALTER TABLE usuarios ADD COLUMN puntos_diarios INT DEFAULT 0;
```

## ⏰ Tiempos de Aparición

Los snippets aparecen en los siguientes intervalos:
1. **30 segundos** - Primer snippet
2. **45 segundos** - Segundo snippet  
3. **60 segundos** - Tercer snippet
4. **90 segundos** - Cuarto snippet
5. **150 segundos** - Quinto snippet
6. **240 segundos** (4 min) - Sexto snippet
7. **360 segundos** (6 min) - Séptimo snippet
8. **480 segundos** (8 min) - Octavo snippet
9. **600 segundos** (10 min) - Noveno snippet
10. **720 segundos** (12 min) - Décimo snippet
11. **900 segundos** (15 min) - Undécimo snippet
12. **1200 segundos** (20 min) - Duodécimo snippet

## 🔧 Configuración

### 1. Ejecutar Script SQL
```bash
mysql -u root -p oblatos34_db < create_snippet_points_table.sql
```

### 2. Subir Archivo PHP
Subir `add_snippet_points.php` al servidor web en:
```
https://zumuradigital.com/app-oblatos-login/add_snippet_points.php
```

### 3. Verificar Imágenes
Asegurar que todas las imágenes estén en `assets/images/snippets/`

## 🎮 Uso del Sistema

### Inicialización Automática
El sistema se inicializa automáticamente cuando se carga `MainContainer` y comienza a mostrar snippets después de 1 segundo.

### Control Manual
```dart
// Obtener instancia del servicio
final snippetService = SnippetService();

// Iniciar timer
snippetService.startAppTimer();

// Detener timer
snippetService.stopAppTimer();

// Obtener estadísticas
final stats = snippetService.getStats();
```

## 📊 API Endpoints

### POST `/add_snippet_points.php`
**Body:**
```json
{
  "user_id": "123",
  "points": 10,
  "snippet_id": "snippet-01.png"
}
```

**Response:**
```json
{
  "success": true,
  "points_added": 10,
  "total_points": 150,
  "snippets_today": 3,
  "message": "¡Ganaste 10 puntos!"
}
```

## 🐛 Solución de Problemas

### Snippets no aparecen
1. Verificar que las imágenes estén en la carpeta correcta
2. Revisar que el servicio se haya inicializado
3. Comprobar logs de consola para errores

### Puntos no se agregan
1. Verificar conexión a la base de datos
2. Comprobar que el archivo PHP esté subido correctamente
3. Revisar logs del servidor web

### Errores de linting
- Ejecutar `flutter analyze` para identificar problemas
- Corregir imports no utilizados
- Eliminar variables no referenciadas

## 🚀 Próximas Mejoras

- [ ] Persistencia de snippets vistos por día
- [ ] Configuración de tiempos personalizable
- [ ] Estadísticas de snippets por usuario
- [ ] Notificaciones push para snippets
- [ ] Modo offline para snippets
