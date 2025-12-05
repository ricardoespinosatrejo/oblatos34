-- Script para agregar sistema de puntos de racha a la tabla usuarios
-- Ejecutar en la base de datos MySQL/MariaDB

-- Agregar campo de puntos de racha (sistema principal)
ALTER TABLE usuarios 
ADD COLUMN IF NOT EXISTS racha_points INT DEFAULT 0 COMMENT 'Puntos acumulados por rachas (sistema principal)';

-- Crear índice para optimizar consultas por puntos de racha
CREATE INDEX IF NOT EXISTS idx_usuarios_racha_points ON usuarios(racha_points DESC);

-- Verificar que el campo se agregó correctamente
DESCRIBE usuarios;

-- Mostrar la estructura actualizada de la tabla
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'usuarios' 
AND COLUMN_NAME = 'racha_points';


