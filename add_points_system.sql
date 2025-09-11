-- Script para agregar sistema de puntos a la tabla usuarios
-- Ejecutar en la base de datos MySQL

-- Agregar campo de puntos (puntuación total del usuario)
ALTER TABLE usuarios ADD COLUMN puntos INT DEFAULT 0 COMMENT 'Puntuación total del usuario';

-- Agregar campo de última sesión (para calcular puntos diarios)
ALTER TABLE usuarios ADD COLUMN ultima_sesion DATE DEFAULT NULL COMMENT 'Fecha de la última sesión del usuario';

-- Agregar campo de racha de días (para bonus por consistencia)
ALTER TABLE usuarios ADD COLUMN racha_dias INT DEFAULT 0 COMMENT 'Días consecutivos de uso';

-- Agregar campo de fecha de creación de la racha
ALTER TABLE usuarios ADD COLUMN fecha_inicio_racha DATE DEFAULT NULL COMMENT 'Fecha de inicio de la racha actual';

-- Agregar campo de último bonus de racha
ALTER TABLE usuarios ADD COLUMN ultimo_bonus_racha DATE DEFAULT NULL COMMENT 'Fecha del último bonus de racha otorgado';

-- Crear índice para optimizar consultas por puntos
CREATE INDEX idx_usuarios_puntos ON usuarios(puntos DESC);

-- Crear índice para optimizar consultas por última sesión
CREATE INDEX idx_usuarios_ultima_sesion ON usuarios(ultima_sesion);

-- Verificar que los campos se agregaron correctamente
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

















