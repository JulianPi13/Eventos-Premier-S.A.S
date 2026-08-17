USE eventos_premier;

-- ---------------------------------------------------------------------
-- Vista: vista_resumen_reservas
-- Nombre del cliente, nombre del salón, fecha de inicio, fecha de fin,
-- total y estado de cada reserva.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vista_resumen_reservas;

CREATE VIEW vista_resumen_reservas AS
SELECT
    r.reserva_id,
    c.nombre_completo       AS cliente,
    s.nombre                 AS salon,
    r.fecha_inicio,
    r.fecha_fin,
    r.precio_hora_aplicado,
    r.total_horas,
    r.valor_total             AS total,
    r.estado
FROM reservas r
INNER JOIN clientes c ON c.cliente_id = r.cliente_id
INNER JOIN salones  s ON s.salon_id  = r.salon_id;

-- Uso:
-- SELECT * FROM vista_resumen_reservas ORDER BY fecha_inicio;


-- ---------------------------------------------------------------------
-- Consulta 1: Reservas realizadas en un rango de fechas (BETWEEN)
-- Ejemplo: reservas cuyo inicio cae entre el 1 y el 31 de agosto de 2026
-- ---------------------------------------------------------------------
SELECT
    r.reserva_id,
    c.nombre_completo AS cliente,
    s.nombre           AS salon,
    r.fecha_inicio,
    r.fecha_fin,
    r.valor_total
FROM reservas r
INNER JOIN clientes c ON c.cliente_id = r.cliente_id
INNER JOIN salones  s ON s.salon_id  = r.salon_id
WHERE r.fecha_inicio BETWEEN '2026-08-01 00:00:00' AND '2026-08-31 23:59:59'
ORDER BY r.fecha_inicio;


-- ---------------------------------------------------------------------
-- Consulta 2: Salones con capacidad mayor a X personas y disponibles
-- Ejemplo: X = 50
-- ---------------------------------------------------------------------
SELECT
    salon_id,
    nombre,
    capacidad,
    precio_hora,
    estado,
    encargado
FROM salones
WHERE capacidad > 50
  AND estado = 'Disponible'
ORDER BY capacidad DESC;


-- ---------------------------------------------------------------------
-- Consulta 3: Clientes corporativos con más de 3 reservas
-- (usando subconsulta con COUNT)
-- ---------------------------------------------------------------------
SELECT
    c.cliente_id,
    c.nombre_completo,
    c.correo,
    c.tipo_cliente,
    sub.total_reservas
FROM clientes c
INNER JOIN (
    SELECT cliente_id, COUNT(*) AS total_reservas
    FROM reservas
    GROUP BY cliente_id
    HAVING COUNT(*) > 3
) sub ON sub.cliente_id = c.cliente_id
WHERE c.tipo_cliente = 'Corporativo'
ORDER BY sub.total_reservas DESC;

-- Variante equivalente usando subconsulta escalar / EXISTS:
-- SELECT c.cliente_id, c.nombre_completo, c.tipo_cliente
-- FROM clientes c
-- WHERE c.tipo_cliente = 'Corporativo'
--   AND (SELECT COUNT(*) FROM reservas r WHERE r.cliente_id = c.cliente_id) > 3;


-- ---------------------------------------------------------------------
-- Consultas adicionales de apoyo administrativo
-- ---------------------------------------------------------------------

-- Ingresos totales por salón (para reportes de ingresos)
SELECT
    s.salon_id,
    s.nombre,
    COUNT(r.reserva_id)         AS numero_reservas,
    COALESCE(SUM(r.valor_total), 0) AS ingresos_totales
FROM salones s
LEFT JOIN reservas r ON r.salon_id = s.salon_id AND r.estado <> 'Cancelada'
GROUP BY s.salon_id, s.nombre
ORDER BY ingresos_totales DESC;

-- Total pagado vs. valor de la reserva (para detectar saldos pendientes)
SELECT
    r.reserva_id,
    c.nombre_completo AS cliente,
    r.valor_total,
    COALESCE(SUM(p.monto_pagado), 0)               AS total_pagado,
    r.valor_total - COALESCE(SUM(p.monto_pagado), 0) AS saldo_pendiente
FROM reservas r
INNER JOIN clientes c ON c.cliente_id = r.cliente_id
LEFT JOIN pagos p ON p.reserva_id = r.reserva_id
GROUP BY r.reserva_id, c.nombre_completo, r.valor_total
ORDER BY saldo_pendiente DESC;

-- Salones actualmente en mantenimiento
SELECT nombre, encargado, precio_hora
FROM salones
WHERE estado = 'En mantenimiento';

-- Historial de cambios de precio de un salón (auditoría)
SELECT
    a.auditoria_id,
    s.nombre AS salon,
    a.usuario,
    a.fecha_cambio,
    a.precio_anterior,
    a.precio_nuevo
FROM auditoria_precios a
INNER JOIN salones s ON s.salon_id = a.salon_id
ORDER BY a.fecha_cambio DESC;

-- Ejemplo de uso de las funciones personalizadas
SELECT calcular_total_reserva(120000, 3) AS total_con_iva;
SELECT verificar_disponibilidad(1, '2026-09-01 14:00:00', '2026-09-01 18:00:00') AS disponible;
