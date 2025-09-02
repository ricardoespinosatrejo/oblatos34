-- Script simplificado para agregar la columna profile_image
-- Ejecutar en la base de datos MySQL en GoDaddy

-- Agregar campo de imagen de perfil
ALTER TABLE usuarios ADD COLUMN profile_image INT DEFAULT 1 COMMENT 'Número de imagen de perfil (1, 2, o 3)';

-- Verificar que la columna se agregó correctamente
DESCRIBE usuarios;






