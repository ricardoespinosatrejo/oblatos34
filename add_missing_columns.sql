-- Agregar columnas que faltan para sincronización con Google Calendar
-- (Solo las que no existen)

-- Verificar y agregar google_event_id si no existe
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = 'Caja_OblatosMX' 
     AND TABLE_NAME = 'eventos' 
     AND COLUMN_NAME = 'google_event_id') = 0,
    'ALTER TABLE eventos ADD COLUMN google_event_id VARCHAR(255) NULL',
    'SELECT "google_event_id ya existe" as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificar y agregar last_sync_at si no existe
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = 'Caja_OblatosMX' 
     AND TABLE_NAME = 'eventos' 
     AND COLUMN_NAME = 'last_sync_at') = 0,
    'ALTER TABLE eventos ADD COLUMN last_sync_at TIMESTAMP NULL',
    'SELECT "last_sync_at ya existe" as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificar y agregar sync_status si no existe
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = 'Caja_OblatosMX' 
     AND TABLE_NAME = 'eventos' 
     AND COLUMN_NAME = 'sync_status') = 0,
    'ALTER TABLE eventos ADD COLUMN sync_status ENUM("pending", "synced", "error") DEFAULT "pending"',
    'SELECT "sync_status ya existe" as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificar y agregar categoria si no existe
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = 'Caja_OblatosMX' 
     AND TABLE_NAME = 'eventos' 
     AND COLUMN_NAME = 'categoria') = 0,
    'ALTER TABLE eventos ADD COLUMN categoria VARCHAR(100) DEFAULT "general"',
    'SELECT "categoria ya existe" as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificar y agregar enviar_notificacion si no existe
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = 'Caja_OblatosMX' 
     AND TABLE_NAME = 'eventos' 
     AND COLUMN_NAME = 'enviar_notificacion') = 0,
    'ALTER TABLE eventos ADD COLUMN enviar_notificacion BOOLEAN DEFAULT TRUE',
    'SELECT "enviar_notificacion ya existe" as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificar y agregar notificacion_enviada si no existe
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = 'Caja_OblatosMX' 
     AND TABLE_NAME = 'eventos' 
     AND COLUMN_NAME = 'notificacion_enviada') = 0,
    'ALTER TABLE eventos ADD COLUMN notificacion_enviada BOOLEAN DEFAULT FALSE',
    'SELECT "notificacion_enviada ya existe" as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verificar y agregar recordatorio_horas si no existe
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = 'Caja_OblatosMX' 
     AND TABLE_NAME = 'eventos' 
     AND COLUMN_NAME = 'recordatorio_horas') = 0,
    'ALTER TABLE eventos ADD COLUMN recordatorio_horas INT DEFAULT 24',
    'SELECT "recordatorio_horas ya existe" as message'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Crear índices si no existen
CREATE INDEX IF NOT EXISTS idx_google_event_id ON eventos(google_event_id);
CREATE INDEX IF NOT EXISTS idx_sync_status ON eventos(sync_status);

-- Crear tabla de categorías si no existe
CREATE TABLE IF NOT EXISTS categorias_eventos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    color VARCHAR(7) DEFAULT '#2196F3',
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar categorías básicas (solo si la tabla está vacía)
INSERT IGNORE INTO categorias_eventos (nombre, color, descripcion) VALUES
('Reuniones', '#2196F3', 'Reuniones de equipo y comité'),
('Campañas', '#4CAF50', 'Campañas de recaudación y donación'),
('Talleres', '#FF9800', 'Talleres educativos y capacitación'),
('Eventos Sociales', '#9C27B0', 'Eventos de networking y sociales'),
('Asambleas', '#F44336', 'Asambleas generales y votaciones'),
('General', '#757575', 'Eventos generales');




