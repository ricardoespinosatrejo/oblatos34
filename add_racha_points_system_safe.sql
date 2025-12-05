-- Script para agregar sistema de puntos de racha a la tabla usuarios
-- Versión segura: ejecuta solo si la columna no existe

-- Paso 1: Agregar campo de puntos de racha
-- Si la columna ya existe, verás un error pero puedes ignorarlo
ALTER TABLE usuarios 
ADD COLUMN racha_points INT DEFAULT 0 COMMENT 'Puntos acumulados por rachas (sistema principal)';

-- Paso 2: Crear índice (ignora el error si ya existe)
CREATE INDEX idx_usuarios_racha_points ON usuarios(racha_points DESC);

-- Paso 3: Verificar que el campo se agregó correctamente
DESCRIBE usuarios;


