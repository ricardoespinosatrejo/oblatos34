-- Crear tabla para tokens FCM
CREATE TABLE IF NOT EXISTS fcm_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(255) NOT NULL UNIQUE,
    user_id INT NULL,
    device_type ENUM('android', 'ios', 'web') DEFAULT 'android',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_token (token),
    INDEX idx_user_id (user_id),
    INDEX idx_is_active (is_active)
);

-- Crear tabla para historial de notificaciones
CREATE TABLE IF NOT EXISTS notificaciones_historial (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    evento_id INT NULL,
    tipo_notificacion ENUM('evento_proximo', 'recordatorio', 'nuevo_evento', 'recordatorio_personalizado') NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    mensaje TEXT NOT NULL,
    enviada_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    leida_at TIMESTAMP NULL,
    fcm_token VARCHAR(255) NULL,
    
    INDEX idx_user_id (user_id),
    INDEX idx_evento_id (evento_id),
    INDEX idx_enviada_at (enviada_at),
    INDEX idx_leida_at (leida_at)
);

-- Crear tabla para configuraciones de notificación por usuario
CREATE TABLE IF NOT EXISTS configuraciones_notificacion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    eventos_proximos BOOLEAN DEFAULT TRUE,
    recordatorios BOOLEAN DEFAULT TRUE,
    nuevos_eventos BOOLEAN DEFAULT TRUE,
    recordatorio_horas INT DEFAULT 24,
    hora_recordatorio TIME DEFAULT '09:00:00',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_user_id (user_id)
);










