# 🎯 Sistema de Puntos - Configuración PHP

## 📋 **Archivo: `update_points.php`**

### 🚀 **Funcionalidades Implementadas:**

#### **1️⃣ Sesión Diaria (`sesion_diaria`):**
- **+2 puntos** por cada día que el usuario accede
- **Calcula racha** de días consecutivos
- **Bonus automático** por rachas de 7 y 30 días

#### **2️⃣ Completar Actividad (`completar_actividad`):**
- **Caja:** +10 puntos
- **Aprendiendo:** +5 puntos  
- **Videoblog:** +3 puntos
- **Poder:** +15 puntos

#### **3️⃣ Sistema de Rachas:**
- **7 días consecutivos:** +50 puntos bonus
- **30 días consecutivos:** +200 puntos bonus
- **Control automático** de fechas de bonus

---

## ⚙️ **Configuración Requerida:**

### **Base de Datos:**
```php
$host = 'localhost';
$dbname = 'tu_base_de_datos'; // CAMBIAR por tu nombre real
$username = 'tu_usuario';      // CAMBIAR por tu usuario real
$password = 'tu_password';     // CAMBIAR por tu contraseña real
```

### **Tabla `usuarios` debe tener:**
- ✅ `id` (PRIMARY KEY)
- ✅ `puntos` (INT)
- ✅ `ultima_sesion` (DATE)
- ✅ `racha_dias` (INT)
- ✅ `fecha_inicio_racha` (DATE)
- ✅ `ultimo_bonus_racha` (DATE)

---

## 📡 **Cómo Usar desde Flutter:**

### **1️⃣ Sesión Diaria:**
```dart
// Cuando el usuario abre la app
final response = await http.post(
  Uri.parse('https://tu-servidor.com/update_points.php'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'user_id': userManager.currentUser!['id'],
    'action': 'sesion_diaria'
  })
);
```

### **2️⃣ Completar Actividad:**
```dart
// Cuando el usuario completa una actividad
final response = await http.post(
  Uri.parse('https://tu-servidor.com/update_points.php'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'user_id': userManager.currentUser!['id'],
    'action': 'completar_actividad',
    'actividad': 'caja' // o 'aprendiendo', 'videoblog', 'poder'
  })
);
```

---

## 🔧 **Instalación:**

### **1️⃣ Subir al Servidor:**
- **Subir** `update_points.php` a tu servidor web
- **Ubicación:** `https://tu-servidor.com/update_points.php`

### **2️⃣ Configurar Base de Datos:**
- **Editar** las credenciales en el archivo PHP
- **Verificar** que la tabla `usuarios` tenga todos los campos

### **3️⃣ Probar:**
- **Hacer POST** con datos de prueba
- **Verificar** que se actualicen los puntos

---

## 📊 **Respuestas del API:**

### **✅ Éxito:**
```json
{
  "success": true,
  "message": "Puntos actualizados correctamente",
  "data": {
    "puntos": 25,
    "racha_dias": 3,
    "ultima_sesion": "2024-01-15",
    "fecha_inicio_racha": "2024-01-13"
  }
}
```

### **❌ Error:**
```json
{
  "error": "Usuario no encontrado"
}
```

---

## 🎯 **Próximos Pasos:**

1. **Configurar credenciales** de base de datos
2. **Subir archivo** al servidor
3. **Integrar en Flutter** para llamadas automáticas
4. **Probar funcionalidad** completa

---

## ⚠️ **Notas Importantes:**

- **Seguridad:** El archivo valida todos los inputs
- **CORS:** Configurado para permitir llamadas desde Flutter
- **Error Handling:** Manejo completo de errores
- **Performance:** Usa prepared statements para seguridad

---

**¿Necesitas ayuda con algún paso específico?** 🚀





















