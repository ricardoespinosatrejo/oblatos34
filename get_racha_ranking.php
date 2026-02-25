<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Usar la configuración centralizada de la base de datos
require_once 'config.php';

try {
    // Obtener usuarios ordenados por puntos de racha y días de racha
    $limit = 100; // máximo de usuarios en el ranking

    $sql = "SELECT 
                id,
                nombre_usuario,
                racha_points,
                racha_dias
            FROM usuarios
            ORDER BY racha_points DESC, racha_dias DESC, ultima_sesion DESC
            LIMIT :limit";

    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
    $stmt->execute();

    $usuarios = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success'  => true,
        'usuarios' => $usuarios,
        'total'    => count($usuarios),
        'message'  => 'Ranking de racha obtenido correctamente'
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error en la base de datos: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error interno del servidor: ' . $e->getMessage()
    ]);
}

