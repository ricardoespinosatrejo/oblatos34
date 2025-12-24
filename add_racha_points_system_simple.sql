-- Script para agregar sistema de puntos de racha a la tabla usuarios
-- Versión simplificada sin consultas a INFORMATION_SCHEMA

-- Agregar campo de puntos de racha (sistema principal)
-- Si la columna ya existe, este comando dará un error pero no afectará la base de datos
ALTER TABLE usuarios 
ADD COLUMN racha_points INT DEFAULT 0 COMMENT 'Puntos acumulados por rachas (sistema principal)';

-- Crear índice para optimizar consultas por puntos de racha
-- Si el índice ya existe, este comando dará un error pero no afectará la base de datos
CREATE INDEX idx_usuarios_racha_points ON usuarios(racha_points DESC);

-- Verificar que el campo se agregó correctamente
DESCRIBE usuarios;






