USE eventos_premier;

-- ---------------------------------------------------------------------
-- Salones
-- ---------------------------------------------------------------------
INSERT INTO salones (nombre, capacidad, precio_hora, estado, encargado) VALUES
('Salón Esmeralda',   80,  120000.00, 'Disponible',      'Laura Gómez'),
('Salón Zafiro',      40,   90000.00, 'Disponible',      'Carlos Pérez'),
('Salón Diamante',    200, 250000.00, 'Disponible',      'Ana Rodríguez'),
('Salón Rubí',        25,   60000.00, 'En mantenimiento','Julián Torres'),
('Salón Topacio',     60,  100000.00, 'Disponible',      'María Fernanda Ruiz');

-- ---------------------------------------------------------------------
-- Clientes
-- ---------------------------------------------------------------------
INSERT INTO clientes (nombre_completo, identificacion, telefono, correo, tipo_cliente) VALUES
('Constructora Andina S.A.S.', '900123456-1', '3011234567', 'eventos@andina.com',    'Corporativo'),
('Tech Solutions Colombia',    '900987654-2', '3029876543', 'contacto@techsol.co',   'Corporativo'),
('Laura Martínez',             '1012345678',  '3151234567', 'laura.martinez@mail.com','Individual'),
('Andrés Gómez',                '1023456789',  '3169876543', 'andres.gomez@mail.com', 'Individual'),
('Fundación Nuevo Horizonte',  '901112233-3', '3187654321', 'contacto@nuevohorizonte.org', 'Corporativo'),
('Camila Rojas',                '1034567890',  '3201122334', 'camila.rojas@mail.com', 'Individual');

-- ---------------------------------------------------------------------
-- Reservas
-- precio_hora_aplicado lo fija validar_reserva_trigger con la tarifa
-- vigente del salón; total_horas y valor_total son columnas generadas,
-- no se insertan (MySQL las calcula al leer la fila).
-- Se generan 4 reservas para "Constructora Andina S.A.S." (cliente_id = 1)
-- para poder probar la consulta de "corporativos con más de 3 reservas".
-- ---------------------------------------------------------------------
INSERT INTO reservas (cliente_id, salon_id, fecha_inicio, fecha_fin, estado) VALUES
(1, 1, '2026-08-05 08:00:00', '2026-08-05 12:00:00', 'Activa'),     -- Andina - Esmeralda
(1, 2, '2026-08-10 14:00:00', '2026-08-10 17:00:00', 'Activa'),     -- Andina - Zafiro
(1, 3, '2026-08-18 09:00:00', '2026-08-18 13:00:00', 'Finalizada'), -- Andina - Diamante
(1, 5, '2026-09-02 10:00:00', '2026-09-02 12:00:00', 'Activa'),     -- Andina - Topacio
(2, 3, '2026-08-20 15:00:00', '2026-08-20 19:00:00', 'Activa'),     -- Tech Solutions - Diamante
(3, 2, '2026-08-08 18:00:00', '2026-08-08 22:00:00', 'Activa'),     -- Laura Martínez - Zafiro
(4, 1, '2026-08-25 16:00:00', '2026-08-25 20:00:00', 'Activa'),     -- Andrés Gómez - Esmeralda
(5, 5, '2026-08-15 08:00:00', '2026-08-15 11:00:00', 'Cancelada'),  -- Fundación - Topacio (cancelada)
(6, 3, '2026-09-05 12:00:00', '2026-09-05 16:00:00', 'Activa');     -- Camila Rojas - Diamante

-- ---------------------------------------------------------------------
-- Pagos
-- ---------------------------------------------------------------------
INSERT INTO pagos (reserva_id, fecha_pago, monto_pagado, metodo_pago) VALUES
(1, '2026-08-01', 300000.00, 'Transferencia'),
(2, '2026-08-06', 160000.00, 'Tarjeta'),
(3, '2026-08-12', 500000.00, 'Efectivo'),
(5, '2026-08-15', 400000.00, 'Transferencia'),
(6, '2026-08-05', 200000.00, 'Tarjeta'),
(7, '2026-08-20', 250000.00, 'Efectivo');

-- ---------------------------------------------------------------------
-- Demostración de triggers
-- ---------------------------------------------------------------------

-- 1. actualizar_estado_salon_trigger: tras los INSERT anteriores, los
--    salones con reservas 'Activa' ya deberían figurar como 'Ocupado'.
SELECT nombre, estado FROM salones;

-- 2. auditoria_precios_trigger: al actualizar el precio_hora de un salón
--    se registra el cambio en auditoria_precios.
--    Además, esto sirve para comprobar que no hay redundancia mal
--    resuelta: las reservas ya creadas sobre el salón 1 deben conservar
--    su precio_hora_aplicado y su valor_total originales, sin importar
--    que la tarifa del salón cambie después.
SELECT reserva_id, precio_hora_aplicado, total_horas, valor_total
FROM reservas
WHERE salon_id = 1;                          -- "antes" del cambio de tarifa

UPDATE salones
SET precio_hora = 130000.00
WHERE salon_id = 1;

SELECT * FROM auditoria_precios;

SELECT reserva_id, precio_hora_aplicado, total_horas, valor_total
FROM reservas
WHERE salon_id = 1;                          -- "después": debe salir igual

-- 3. liberar_salon_trigger: al eliminar una reserva activa, si no quedan
--    otras reservas activas para ese salón, vuelve a 'Disponible'.
DELETE FROM reservas WHERE reserva_id = 6;

SELECT nombre, estado FROM salones WHERE salon_id = 2;
