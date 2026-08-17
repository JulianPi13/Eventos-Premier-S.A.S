USE eventos_premier;

-- ---------------------------------------------------------------------
-- Función: calcular_total_reserva
-- Calcula el valor total de una reserva (precio_hora * horas) + IVA 19%
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS calcular_total_reserva;

DELIMITER $$

CREATE FUNCTION calcular_total_reserva(
    p_precio_hora DECIMAL(12,2),
    p_horas       DECIMAL(10,2)
)
RETURNS DECIMAL(12,2)
DETERMINISTIC
NO SQL
BEGIN
    DECLARE v_subtotal DECIMAL(12,2);
    DECLARE v_total     DECIMAL(12,2);

    IF p_precio_hora IS NULL OR p_horas IS NULL OR p_precio_hora < 0 OR p_horas < 0 THEN
        RETURN 0;
    END IF;

    SET v_subtotal = p_precio_hora * p_horas;
    SET v_total = ROUND(v_subtotal * 1.19, 2); -- IVA del 19%

    RETURN v_total;
END $$

DELIMITER ;

-- ---------------------------------------------------------------------
-- Función: verificar_disponibilidad
-- Retorna 1 si el salón está disponible en el rango de fechas indicado,
-- 0 si ya existe una reserva Activa/Finalizada que se cruza con ese rango.
-- No tiene en cuenta las reservas Canceladas.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS verificar_disponibilidad;

DELIMITER $$

CREATE FUNCTION verificar_disponibilidad(
    p_salon_id      INT,
    p_fecha_inicio  DATETIME,
    p_fecha_fin     DATETIME
)
RETURNS TINYINT
READS SQL DATA
BEGIN
    DECLARE v_conflictos INT DEFAULT 0;
    DECLARE v_estado_salon VARCHAR(20);

    -- Si el salón está en mantenimiento no está disponible
    SELECT estado INTO v_estado_salon
    FROM salones
    WHERE salon_id = p_salon_id;

    IF v_estado_salon IS NULL THEN
        RETURN 0; -- el salón no existe
    END IF;

    IF v_estado_salon = 'En mantenimiento' THEN
        RETURN 0;
    END IF;

    -- Se considera ocupado si hay una reserva Activa o Finalizada que se
    -- traslape con el rango solicitado (fecha_inicio < fin AND fecha_fin > inicio)
    SELECT COUNT(*) INTO v_conflictos
    FROM reservas
    WHERE salon_id = p_salon_id
      AND estado IN ('Activa', 'Finalizada')
      AND fecha_inicio < p_fecha_fin
      AND fecha_fin > p_fecha_inicio;

    IF v_conflictos > 0 THEN
        RETURN 0;
    ELSE
        RETURN 1;
    END IF;
END $$

DELIMITER ;
