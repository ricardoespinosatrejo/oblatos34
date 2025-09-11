-- Verificar estructura actual de la tabla eventos
DESCRIBE eventos;

-- Verificar si las columnas específicas ya existen
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'Caja_OblatosMX' 
AND TABLE_NAME = 'eventos'
ORDER BY ORDINAL_POSITION;











