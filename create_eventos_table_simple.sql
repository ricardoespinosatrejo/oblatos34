-- Crear tabla de eventos para Caja Oblatos
CREATE TABLE IF NOT EXISTS eventos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    descripcion TEXT,
    fecha_inicio DATETIME NOT NULL,
    fecha_fin DATETIME,
    ubicacion VARCHAR(255),
    es_todo_el_dia BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insertar algunos eventos de ejemplo con fechas fijas
INSERT INTO eventos (titulo, descripcion, fecha_inicio, fecha_fin, ubicacion, es_todo_el_dia) VALUES
('Reunión de Caja Oblatos', 'Reunión mensual para discutir proyectos y campañas', '2024-09-04 10:00:00', '2024-09-04 12:00:00', 'Sede Principal Caja Oblatos', FALSE),
('Campaña de Donación', 'Campaña anual de recaudación de fondos', '2024-09-07 00:00:00', '2024-09-07 23:59:59', 'Plaza Central', TRUE),
('Taller de Cooperativas', 'Taller educativo sobre cooperativas y economía solidaria', '2024-09-09 14:00:00', '2024-09-09 17:00:00', 'Centro Comunitario', FALSE),
('Evento de Networking', 'Networking con otras organizaciones cooperativas', '2024-09-16 18:00:00', '2024-09-16 22:00:00', 'Hotel Central', FALSE),
('Asamblea General', 'Asamblea general de miembros de Caja Oblatos', '2024-09-23 15:00:00', '2024-09-23 18:00:00', 'Auditorio Principal', FALSE);
