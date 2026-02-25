<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Usar la configuración centralizada de base de datos
require_once 'config.php';

try {
    // Por defecto solo eventos futuros; si algún día quieres ver pasados puedes agregar un parámetro
    $includePast = isset($_GET['include_past']) && $_GET['include_past'] === '1';

    $sql = "SELECT 
                id,
                titulo,
                descripcion,
                fecha_inicio,
                fecha_fin,
                ubicacion,
                es_todo_el_dia,
                categoria
            FROM eventos";

    if (!$includePast) {
        // Mostrar solo eventos vigentes o futuros:
        // - Si tiene fecha_fin: se muestra mientras fecha_fin sea hoy o futura
        // - Si no tiene fecha_fin: se muestra mientras fecha_inicio sea hoy o futura
        $sql .= " WHERE (
                    (fecha_fin IS NOT NULL AND fecha_fin >= CURDATE())
                    OR
                    (fecha_fin IS NULL AND fecha_inicio >= CURDATE())
                 )";
    }

    $sql .= " ORDER BY fecha_inicio ASC LIMIT 100";

    $stmt = $pdo->prepare($sql);
    $stmt->execute();

    $eventos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $response = [
        'success'   => true,
        'eventos'   => $eventos,
        'total'     => count($eventos),
        'timestamp' => date('Y-m-d H:i:s'),
    ];

    echo json_encode($response, JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    $error = [
        'success'   => false,
        'error'     => $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s'),
    ];

    echo json_encode($error, JSON_UNESCAPED_UNICODE);
}
?>
