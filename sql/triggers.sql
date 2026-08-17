USE eventos_premier;

-- ---------------------------------------------------------------------
-- Trigger: validar_reserva_trigger (BEFORE INSERT)
-- Valida disponibilidad con verificar_disponibilidad() y, si el salón
-- está libre, fija precio_hora_aplicado con la tarifa vigente del salón.
-- total_horas y valor_total no se tocan aquí: son columnas GENERATED, MySQL las calcula solo.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS validar_reserva_trigger;

DELIMITER $$

CREATE TRIGGER validar_reserva_trigger
BEFORE INSERT ON reservas
FOR EACH ROW
BEGIN
    DECLARE v_precio_hora DECIMAL(12,2);

    IF verificar_disponibilidad(NEW.salon_id, NEW.fecha_inicio, NEW.fecha_fin) = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El salón no está disponible en el rango de fechas indicado.';
    END IF;

    SELECT precio_hora INTO v_precio_hora
    FROM salones
    WHERE salon_id = NEW.salon_id;

    SET NEW.precio_hora_aplicado = v_precio_hora;
END $$

DELIMITER ;

-- ---------------------------------------------------------------------
-- Trigger: validar_reserva_update_trigger (BEFORE UPDATE)
-- Si se mueve una reserva activa a otro salón u otro horario, vuelve a
-- validar disponibilidad (excluyendo la propia reserva de la revisión)
-- y, si cambió de salón, actualiza precio_hora_aplicado con la tarifa
-- del nuevo salón. Si solo cambian las fechas dentro del mismo salón,
-- precio_hora_aplicado se conserva: es la tarifa ya pactada.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS validar_reserva_update_trigger;

DELIMITER $$

CREATE TRIGGER validar_reserva_update_trigger
BEFORE UPDATE ON reservas
FOR EACH ROW
BEGIN
    DECLARE v_conflictos  INT DEFAULT 0;
    DECLARE v_precio_hora DECIMAL(12,2);

    IF NEW.estado = 'Activa'
       AND (NEW.fecha_inicio <> OLD.fecha_inicio
            OR NEW.fecha_fin <> OLD.fecha_fin
            OR NEW.salon_id <> OLD.salon_id) THEN

        SELECT COUNT(*) INTO v_conflictos
        FROM reservas
        WHERE salon_id = NEW.salon_id
          AND reserva_id <> OLD.reserva_id
          AND estado IN ('Activa', 'Finalizada')
          AND fecha_inicio < NEW.fecha_fin
          AND fecha_fin > NEW.fecha_inicio;

        IF v_conflictos > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El salón no está disponible en el rango de fechas indicado.';
        END IF;

        IF NEW.salon_id <> OLD.salon_id THEN
            SELECT precio_hora INTO v_precio_hora
            FROM salones
            WHERE salon_id = NEW.salon_id;

            SET NEW.precio_hora_aplicado = v_precio_hora;
        END IF;
    END IF;
END $$

DELIMITER ;

-- ---------------------------------------------------------------------
-- Trigger: actualizar_estado_salon_trigger (AFTER INSERT)
-- Al registrar una nueva reserva, el salón pasa a estado 'Ocupado'.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS actualizar_estado_salon_trigger;

DELIMITER $$

CREATE TRIGGER actualizar_estado_salon_trigger
AFTER INSERT ON reservas
FOR EACH ROW
BEGIN
    IF NEW.estado = 'Activa' THEN
        UPDATE salones
        SET estado = 'Ocupado'
        WHERE salon_id = NEW.salon_id
          AND estado = 'Disponible';
    END IF;
END $$

DELIMITER ;

-- ---------------------------------------------------------------------
-- Trigger: liberar_salon_trigger (AFTER DELETE)
-- Al eliminar una reserva, el salón vuelve a estado 'Disponible',
-- siempre que no existan otras reservas activas pendientes para ese
-- salón y que no esté actualmente en mantenimiento.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS liberar_salon_trigger;

DELIMITER $$

CREATE TRIGGER liberar_salon_trigger
AFTER DELETE ON reservas
FOR EACH ROW
BEGIN
    DECLARE v_otras_activas INT;

    SELECT COUNT(*) INTO v_otras_activas
    FROM reservas
    WHERE salon_id = OLD.salon_id
      AND estado = 'Activa';

    IF v_otras_activas = 0 THEN
        UPDATE salones
        SET estado = 'Disponible'
        WHERE salon_id = OLD.salon_id
          AND estado <> 'En mantenimiento';
    END IF;
END $$

DELIMITER ;

-- ---------------------------------------------------------------------
-- Trigger: auditoria_precios_trigger (AFTER UPDATE)
-- Cuando se actualiza el precio_hora de un salón, registra el cambio
-- en la tabla auditoria_precios con usuario, fecha y valor anterior/nuevo.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS auditoria_precios_trigger;

DELIMITER $$

CREATE TRIGGER auditoria_precios_trigger
AFTER UPDATE ON salones
FOR EACH ROW
BEGIN
    IF NEW.precio_hora <> OLD.precio_hora THEN
        INSERT INTO auditoria_precios (salon_id, usuario, fecha_cambio, precio_anterior, precio_nuevo)
        VALUES (OLD.salon_id, CURRENT_USER(), NOW(), OLD.precio_hora, NEW.precio_hora);
    END IF;
END $$

DELIMITER ;
