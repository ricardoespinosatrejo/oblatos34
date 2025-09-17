-- Agregar columnas para sincronización con Google Calendar
ALTER TABLE eventos 
ADD COLUMN google_event_id VARCHAR(255) NULL,
ADD COLUMN last_sync_at TIMESTAMP NULL,
ADD COLUMN sync_status ENUM('pending', 'synced', 'error') DEFAULT 'pending';

-- Crear índice para búsquedas por Google Event ID
CREATE INDEX idx_google_event_id ON eventos(google_event_id);

-- Crear índice para búsquedas por estado de sincronización
CREATE INDEX idx_sync_status ON eventos(sync_status);

-- Agregar columna para categoría de eventos
ALTER TABLE eventos 
ADD COLUMN categoria VARCHAR(100) DEFAULT 'general';

-- Crear tabla de categorías de eventos
CREATE TABLE IF NOT EXISTS categorias_eventos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    color VARCHAR(7) DEFAULT '#2196F3',
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar categorías básicas
INSERT INTO categorias_eventos (nombre, color, descripcion) VALUES
('Reuniones', '#2196F3', 'Reuniones de equipo y comité'),
('Campañas', '#4CAF50', 'Campañas de recaudación y donación'),
('Talleres', '#FF9800', 'Talleres educativos y capacitación'),
('Eventos Sociales', '#9C27B0', 'Eventos de networking y sociales'),
('Asambleas', '#F44336', 'Asambleas generales y votaciones'),
('General', '#757575', 'Eventos generales');

-- Agregar columna para notificaciones
ALTER TABLE eventos 
ADD COLUMN enviar_notificacion BOOLEAN DEFAULT TRUE,
ADD COLUMN notificacion_enviada BOOLEAN DEFAULT FALSE,
ADD COLUMN recordatorio_horas INT DEFAULT 24;













