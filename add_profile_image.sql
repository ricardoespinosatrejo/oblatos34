-- Script para agregar la columna profile_image faltante
-- Ejecutar en la base de datos MySQL

-- Agregar campo de imagen de perfil
ALTER TABLE usuarios ADD COLUMN profile_image INT DEFAULT 1 COMMENT 'Número de imagen de perfil (1, 2, o 3)';

-- Verificar que la columna se agregó correctamente
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
ORDER BY ORDINAL_POSITION;
















