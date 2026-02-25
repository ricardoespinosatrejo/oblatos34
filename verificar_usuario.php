<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit(0); }

$input = json_decode(file_get_contents('php://input'), true);
$nombreUsuario = isset($input['nombre_usuario']) ? trim($input['nombre_usuario']) : '';

$host = 'localhost';
$dbname = 'playcoop_Caja_OblatosMX';
$user = 'playcoop';
$pass = '+B1xv*25Y2rQmT';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $stmt = $pdo->prepare('SELECT id FROM usuarios WHERE nombre_usuario = ? LIMIT 1');
    $stmt->execute([$nombreUsuario]);
    $existe = $stmt->fetch() !== false;
    echo json_encode(['existe' => $existe]);
} catch (Throwable $e) {
    echo json_encode(['existe' => false]);
}
