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

-- Insertar algunos eventos de ejemplo
INSERT INTO eventos (titulo, descripcion, fecha_inicio, fecha_fin, ubicacion, es_todo_el_dia) VALUES
('Reunión de Caja Oblatos', 'Reunión mensual para discutir proyectos y campañas', DATE_ADD(NOW(), INTERVAL 2 DAY), DATE_ADD(NOW(), INTERVAL 2 DAY + INTERVAL 2 HOUR), 'Sede Principal Caja Oblatos', FALSE),
('Campaña de Donación', 'Campaña anual de recaudación de fondos', DATE_ADD(NOW(), INTERVAL 5 DAY), DATE_ADD(NOW(), INTERVAL 5 DAY), 'Plaza Central', TRUE),
('Taller de Cooperativas', 'Taller educativo sobre cooperativas y economía solidaria', DATE_ADD(NOW(), INTERVAL 7 DAY), DATE_ADD(NOW(), INTERVAL 7 DAY + INTERVAL 3 HOUR), 'Centro Comunitario', FALSE),
('Evento de Networking', 'Networking con otras organizaciones cooperativas', DATE_ADD(NOW(), INTERVAL 14 DAY), DATE_ADD(NOW(), INTERVAL 14 DAY + INTERVAL 4 HOUR), 'Hotel Central', FALSE),
('Asamblea General', 'Asamblea general de miembros de Caja Oblatos', DATE_ADD(NOW(), INTERVAL 21 DAY), DATE_ADD(NOW(), INTERVAL 21 DAY + INTERVAL 3 HOUR), 'Auditorio Principal', FALSE);
