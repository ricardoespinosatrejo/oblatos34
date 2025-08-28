<?php
// Script para actualizar puntos del usuario automáticamente
// Maneja sesiones diarias, racha de días y puntos por actividades

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Manejar preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Solo permitir POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Método no permitido']);
    exit;
}

// Obtener y decodificar datos JSON
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data) {
    http_response_code(400);
    echo json_encode(['error' => 'Datos JSON inválidos']);
    exit;
}

// Validar campos requeridos
$required_fields = ['user_id', 'action'];
if (!validateRequiredFields($data, $required_fields)) {
    http_response_code(400);
    echo json_encode(['error' => 'Campos requeridos faltantes']);
    exit;
}

$user_id = $data['user_id'];
$action = $data['action'];

// Configuración de base de datos
$host = 'localhost';
$dbname = 'Caja_OblatosMX';
$username = 'Caja_OblatosMX';
$password = '5556374784Mexico***';

try {
    // Conectar a la base de datos
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Obtener usuario actual
    $stmt = $pdo->prepare("SELECT * FROM usuarios WHERE id = ?");
    $stmt->execute([$user_id]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$user) {
        http_response_code(404);
        echo json_encode(['error' => 'Usuario no encontrado']);
        exit;
    }
    
    // Procesar la acción solicitada
    $result = processAction($pdo, $user, $action, $data);
    
    // Devolver respuesta exitosa
    echo json_encode([
        'success' => true,
        'message' => 'Puntos actualizados correctamente',
        'data' => $result
    ]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Error de base de datos',
        'details' => $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Error interno del servidor',
        'details' => $e->getMessage()
    ]);
}

/**
 * Procesa la acción solicitada y actualiza los puntos
 */
function processAction($pdo, $user, $action, $data) {
    $puntos = $user['puntos'] ?? 0;
    $racha_dias = $user['racha_dias'] ?? 0;
    $ultima_sesion = $user['ultima_sesion'] ?? null;
    $fecha_inicio_racha = $user['fecha_inicio_racha'] ?? null;
    $ultimo_bonus_racha = $user['ultimo_bonus_racha'] ?? null;
    
    $hoy = date('Y-m-d');
    $hoy_date = new DateTime($hoy);
    
    switch ($action) {
        case 'sesion_diaria':
            return processSesionDiaria($pdo, $user['id'], $puntos, $racha_dias, $ultima_sesion, $fecha_inicio_racha, $ultimo_bonus_racha, $hoy_date);
            
        case 'completar_actividad':
            $actividad = $data['actividad'] ?? '';
            $puntos_actividad = getPuntosActividad($actividad);
            return processActividad($pdo, $user['id'], $puntos, $puntos_actividad, $hoy_date);
            
        case 'actualizar_racha':
            return processRacha($pdo, $user['id'], $racha_dias, $fecha_inicio_racha, $ultimo_bonus_racha, $hoy_date);
            
        default:
            throw new Exception('Acción no válida');
    }
}

/**
 * Procesa sesión diaria del usuario
 */
function processSesionDiaria($pdo, $user_id, $puntos, $racha_dias, $ultima_sesion, $fecha_inicio_racha, $ultimo_bonus_racha, $hoy_date) {
    $nuevos_puntos = $puntos;
    $nueva_racha = $racha_dias;
    $nueva_fecha_inicio = $fecha_inicio_racha;
    $nuevo_ultimo_bonus = $ultimo_bonus_racha;
    
    if ($ultima_sesion === null) {
        // Primera sesión
        $nueva_fecha_inicio = $hoy_date->format('Y-m-d');
        $nueva_racha = 1;
        $nuevos_puntos += 2; // Puntos por primera sesión del día
    } else {
        $ultima_sesion_date = new DateTime($ultima_sesion);
        
        if ($hoy_date > $ultima_sesion_date) {
            // Nueva sesión del día
            $nuevos_puntos += 2; // Puntos por sesión diaria
            
            // Verificar si es día consecutivo
            $ayer = clone $hoy_date;
            $ayer->modify('-1 day');
            
            if ($ultima_sesion_date->format('Y-m-d') === $ayer->format('Y-m-d')) {
                $nueva_racha++;
                $nuevos_puntos = checkBonusRacha($nuevos_puntos, $nueva_racha, $nuevo_ultimo_bonus, $hoy_date);
            } else {
                // Rompió la racha
                $nueva_racha = 1;
                $nueva_fecha_inicio = $hoy_date->format('Y-m-d');
            }
        }
    }
    
    // Actualizar base de datos
    $stmt = $pdo->prepare("
        UPDATE usuarios 
        SET puntos = ?, racha_dias = ?, ultima_sesion = ?, fecha_inicio_racha = ?, ultimo_bonus_racha = ?
        WHERE id = ?
    ");
    
    $stmt->execute([
        $nuevos_puntos,
        $nueva_racha,
        $hoy_date->format('Y-m-d'),
        $nueva_fecha_inicio,
        $nuevo_ultimo_bonus,
        $user_id
    ]);
    
    return [
        'puntos' => $nuevos_puntos,
        'racha_dias' => $nueva_racha,
        'ultima_sesion' => $hoy_date->format('Y-m-d'),
        'fecha_inicio_racha' => $nueva_fecha_inicio,
        'ultimo_bonus_racha' => $nuevo_ultimo_bonus
    ];
}

/**
 * Procesa completar una actividad
 */
function processActividad($pdo, $user_id, $puntos_actuales, $puntos_actividad, $hoy_date) {
    $nuevos_puntos = $puntos_actuales + $puntos_actividad;
    
    // Actualizar puntos en base de datos
    $stmt = $pdo->prepare("UPDATE usuarios SET puntos = ? WHERE id = ?");
    $stmt->execute([$nuevos_puntos, $user_id]);
    
    return [
        'puntos' => $nuevos_puntos,
        'puntos_ganados' => $puntos_actividad
    ];
}

/**
 * Verifica y otorga bonus por racha
 */
function checkBonusRacha($puntos, $racha_dias, $ultimo_bonus_racha, $hoy_date) {
    $nuevos_puntos = $puntos;
    
    if ($racha_dias == 7 && $ultimo_bonus_racha === null) {
        // Bonus por 7 días consecutivos
        $nuevos_puntos += 50;
    } elseif ($racha_dias == 30 && 
              ($ultimo_bonus_racha === null || 
               strtotime($ultimo_bonus_racha) < strtotime('-7 days'))) {
        // Bonus por 30 días consecutivos
        $nuevos_puntos += 200;
    }
    
    return $nuevos_puntos;
}

/**
 * Obtiene puntos por actividad específica
 */
function getPuntosActividad($actividad) {
    switch (strtolower($actividad)) {
        case 'caja':
            return 10;
        case 'aprendiendo':
            return 5;
        case 'videoblog':
            return 3;
        case 'poder':
            return 15;
        default:
            return 0;
    }
}

/**
 * Valida que todos los campos requeridos estén presentes
 */
function validateRequiredFields($data, $required_fields) {
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            return false;
        }
    }
    return true;
}
?>
