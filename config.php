<?php
// Configuración centralizada de la base de datos para el panel de administración
$host = 'localhost';
$dbname = 'playcoop_Caja_OblatosMX';
$username = 'playcoop';
$password = '+B1xv*25Y2rQmT';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    // Todos los endpoints que incluyen este archivo devuelven JSON,
    // así que regresamos un error JSON estándar y detenemos la ejecución.
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error de conexión a la base de datos: ' . $e->getMessage()
    ]);
    exit;
}

