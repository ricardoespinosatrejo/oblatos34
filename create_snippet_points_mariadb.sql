-- Crear tabla para contabilizar puntos de snippets (compatible con MariaDB)
CREATE TABLE snippet_points (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    snippet_id VARCHAR(50) NOT NULL,
    points INT DEFAULT 10,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_user_date (user_id, created_at),
    INDEX idx_snippet_date (snippet_id, created_at)
);

-- Crear índice único por separado (compatible con MariaDB)
CREATE UNIQUE INDEX unique_user_snippet_date ON snippet_points (user_id, snippet_id, DATE(created_at));

-- Agregar columna de puntos diarios
ALTER TABLE usuarios ADD COLUMN puntos_diarios INT DEFAULT 0;
















