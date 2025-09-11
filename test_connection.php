<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Configuración de la base de datos
$host = 'localhost';
$dbname = 'Caja_OblatosMX';
$username = 'Caja_OblatosMX';
$password = '5556374784Mexico***';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Verificar que las tablas existen
    $tables = $pdo->query("SHOW TABLES LIKE 'game_scores'")->fetchAll();
    $tables2 = $pdo->query("SHOW TABLES LIKE 'game_user_stats'")->fetchAll();
    
    echo json_encode([
        'success' => true, 
        'message' => 'Conexión exitosa',
        'game_scores_table' => count($tables) > 0 ? 'Existe' : 'No existe',
        'game_user_stats_table' => count($tables2) > 0 ? 'Existe' : 'No existe'
    ]);
    
} catch(PDOException $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>







