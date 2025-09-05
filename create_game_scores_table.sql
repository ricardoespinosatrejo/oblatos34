-- Tabla para almacenar puntajes del juego
CREATE TABLE IF NOT EXISTS game_scores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    username VARCHAR(100) NOT NULL,
    score INT NOT NULL,
    level_reached INT NOT NULL,
    coins_collected INT DEFAULT 0,
    game_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_score (score),
    INDEX idx_game_date (game_date)
);

-- Tabla para estadísticas del juego por usuario
CREATE TABLE IF NOT EXISTS game_user_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    username VARCHAR(100) NOT NULL,
    total_games_played INT DEFAULT 0,
    highest_score INT DEFAULT 0,
    highest_level INT DEFAULT 0,
    total_coins_collected INT DEFAULT 0,
    last_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_user (user_id)
);