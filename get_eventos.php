<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Configuración de la base de datos
$host = 'localhost';
$dbname = 'Caja_OblatosMX';
$username = 'Caja_OblatosMX';
$password = '5556374784Mexico***';

// Configuración de Google Calendar API
$apiKey = 'AIzaSyBoq2xgRCGEhTZbtEZRWje1dAq9h9Jd-7M'; // Tu API Key
$calendarId = '8bf0ed6ddf3748fd389c89613f8bfe2b23c88560b066724d0365c505a58ab16d@group.calendar.google.com'; // Usar 'primary' para el calendario principal, o el ID específico del calendario

try {
    // Opción 1: Obtener eventos desde Google Calendar API
    function getEventosFromGoogleCalendar($apiKey, $calendarId) {
        $now = date('c');
        $thirtyDaysFromNow = date('c', strtotime('+30 days'));
        
        $url = "https://www.googleapis.com/calendar/v3/calendars/{$calendarId}/events?" .
               "key={$apiKey}&" .
               "timeMin={$now}&" .
               "timeMax={$thirtyDaysFromNow}&" .
               "orderBy=startTime&" .
               "singleEvents=true";
        
        $response = file_get_contents($url);
        return json_decode($response, true);
    }
    
    // Opción 2: Obtener eventos desde base de datos local
    function getEventosFromDatabase($host, $dbname, $username, $password) {
        $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        $query = "SELECT * FROM eventos WHERE fecha_inicio >= NOW() ORDER BY fecha_inicio ASC LIMIT 20";
        $stmt = $pdo->prepare($query);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    // Opción 3: Eventos de ejemplo (para pruebas)
    function getEventosEjemplo() {
        return [
            [
                'id' => '1',
                'titulo' => 'demostracion de la app',
                'descripcion' => 'vas a ver una demostracion de la aplicacion',
                'fecha_inicio' => date('Y-m-d H:i:s', strtotime('today 15:02')),
                'fecha_fin' => date('Y-m-d H:i:s', strtotime('today 17:02')),
                'ubicacion' => 'Sede Principal Caja Oblatos',
                'es_todo_el_dia' => false,
                'categoria' => 'Asambleas'
            ],
            [
                'id' => '2',
                'titulo' => 'Campaña de Donación',
                'descripcion' => 'Campaña anual de recaudación de fondos',
                'fecha_inicio' => date('Y-m-d', strtotime('+5 days')),
                'fecha_fin' => date('Y-m-d', strtotime('+5 days')),
                'ubicacion' => 'Plaza Central',
                'es_todo_el_dia' => true,
                'categoria' => 'Campañas'
            ],
            [
                'id' => '3',
                'titulo' => 'Taller de Cooperativas',
                'descripcion' => 'Taller educativo sobre cooperativas y economía solidaria',
                'fecha_inicio' => date('Y-m-d H:i:s', strtotime('+1 week')),
                'fecha_fin' => date('Y-m-d H:i:s', strtotime('+1 week +3 hours')),
                'ubicacion' => 'Centro Comunitario',
                'es_todo_el_dia' => false,
                'categoria' => 'Talleres'
            ],
            [
                'id' => '4',
                'titulo' => 'Evento de Networking',
                'descripcion' => 'Networking con otras organizaciones cooperativas',
                'fecha_inicio' => date('Y-m-d H:i:s', strtotime('+2 weeks')),
                'fecha_fin' => date('Y-m-d H:i:s', strtotime('+2 weeks +4 hours')),
                'ubicacion' => 'Hotel Central',
                'es_todo_el_dia' => false,
                'categoria' => 'Eventos Sociales'
            ],
            [
                'id' => '5',
                'titulo' => 'Reunión Ejecutiva',
                'descripcion' => 'Reunión mensual del comité ejecutivo',
                'fecha_inicio' => date('Y-m-d H:i:s', strtotime('+3 days')),
                'fecha_fin' => date('Y-m-d H:i:s', strtotime('+3 days +1 hour')),
                'ubicacion' => 'Oficina Principal',
                'es_todo_el_dia' => false,
                'categoria' => 'Reuniones'
            ],
            [
                'id' => '6',
                'titulo' => 'Asamblea General',
                'descripcion' => 'Asamblea general anual de socios',
                'fecha_inicio' => date('Y-m-d H:i:s', strtotime('+1 month')),
                'fecha_fin' => date('Y-m-d H:i:s', strtotime('+1 month +4 hours')),
                'ubicacion' => 'Auditorio Principal',
                'es_todo_el_dia' => false,
                'categoria' => 'Asambleas'
            ]
        ];
    }
    
    // Usar eventos de ejemplo por defecto (más confiable para pruebas)
    $eventos = getEventosEjemplo();
    
    // Formatear respuesta
    $response = [
        'success' => true,
        'eventos' => $eventos,
        'total' => count($eventos),
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    $error = [
        'success' => false,
        'error' => $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    echo json_encode($error, JSON_UNESCAPED_UNICODE);
}
?>
