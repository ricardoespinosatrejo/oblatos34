-- Script para crear tablas de trivias (CMS)
-- Versión simplificada sin consultas a INFORMATION_SCHEMA

-- Tabla principal de trivias
CREATE TABLE IF NOT EXISTS trivias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pregunta TEXT NOT NULL COMMENT 'Texto de la pregunta',
    tipo ENUM('normal', 'recuperacion_racha') DEFAULT 'normal' COMMENT 'Tipo de trivia: normal o recuperación de racha',
    puntos INT DEFAULT 10 COMMENT 'Puntos otorgados al responder correctamente',
    activa BOOLEAN DEFAULT TRUE COMMENT 'Si la trivia está activa y disponible',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_tipo (tipo),
    INDEX idx_activa (activa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de opciones de respuesta para cada trivia
CREATE TABLE IF NOT EXISTS trivia_opciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    trivia_id INT NOT NULL,
    opcion_texto TEXT NOT NULL COMMENT 'Texto de la opción de respuesta',
    es_correcta BOOLEAN DEFAULT FALSE COMMENT 'Si esta opción es la correcta',
    orden INT DEFAULT 0 COMMENT 'Orden de visualización de la opción',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trivia_id) REFERENCES trivias(id) ON DELETE CASCADE,
    INDEX idx_trivia_id (trivia_id),
    INDEX idx_es_correcta (es_correcta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla para registrar respuestas de usuarios a trivias
CREATE TABLE IF NOT EXISTS trivia_respuestas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    trivia_id INT NOT NULL,
    opcion_id INT NOT NULL COMMENT 'ID de la opción seleccionada',
    es_correcta BOOLEAN DEFAULT FALSE COMMENT 'Si la respuesta fue correcta',
    puntos_obtenidos INT DEFAULT 0 COMMENT 'Puntos obtenidos por esta respuesta',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (trivia_id) REFERENCES trivias(id) ON DELETE CASCADE,
    FOREIGN KEY (opcion_id) REFERENCES trivia_opciones(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_trivia_id (trivia_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla para registrar retos diarios completados
CREATE TABLE IF NOT EXISTS daily_challenges_completed (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    challenge_type ENUM('coins', 'video', 'trivia') NOT NULL,
    challenge_data TEXT COMMENT 'JSON con datos del reto (targetValue, videoId, triviaId, etc)',
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    puntos_obtenidos INT DEFAULT 10 COMMENT 'Puntos obtenidos por completar el reto',
    fecha DATE NOT NULL COMMENT 'Fecha en que se completó el reto',
    FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_challenge_date (user_id, challenge_type, fecha),
    INDEX idx_user_id (user_id),
    INDEX idx_fecha (fecha),
    INDEX idx_challenge_type (challenge_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


