-- Crear tabla para contabilizar puntos de snippets
CREATE TABLE IF NOT EXISTS snippet_points (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    snippet_id VARCHAR(50) NOT NULL,
    points INT DEFAULT 10,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_user_date (user_id, created_at),
    INDEX idx_snippet_date (snippet_id, created_at),
    UNIQUE KEY unique_user_snippet_date (user_id, snippet_id, DATE(created_at))
);

-- Agregar columna de puntos diarios si no existe
ALTER TABLE usuarios 
ADD COLUMN IF NOT EXISTS puntos_diarios INT DEFAULT 0;

-- Crear vista para estadísticas de snippets por usuario
CREATE OR REPLACE VIEW snippet_stats AS
SELECT 
    u.id as user_id,
    u.nombre,
    u.email,
    COUNT(sp.id) as total_snippets_vistos,
    SUM(sp.points) as total_puntos_snippets,
    MAX(sp.created_at) as ultimo_snippet_visto,
    COUNT(CASE WHEN DATE(sp.created_at) = CURDATE() THEN 1 END) as snippets_hoy
FROM usuarios u
LEFT JOIN snippet_points sp ON u.id = sp.user_id
GROUP BY u.id, u.nombre, u.email;

-- Crear procedimiento para resetear puntos diarios (ejecutar diariamente)
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS ResetDailyPoints()
BEGIN
    UPDATE usuarios SET puntos_diarios = 0;
END //
DELIMITER ;

-- Crear trigger para actualizar puntos diarios automáticamente
DELIMITER //
CREATE TRIGGER IF NOT EXISTS update_daily_points 
AFTER INSERT ON snippet_points
FOR EACH ROW
BEGIN
    UPDATE usuarios 
    SET puntos_diarios = puntos_diarios + NEW.points 
    WHERE id = NEW.user_id;
END //
DELIMITER ;
















