
DROP DATABASE IF EXISTS eventos_premier;
CREATE DATABASE eventos_premier

USE eventos_premier;

-- ---------------------------------------------------------------------
-- Tabla: salones
-- ---------------------------------------------------------------------
CREATE TABLE salones (
    salon_id        INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    capacidad       INT NOT NULL CHECK (capacidad > 0),
    precio_hora     DECIMAL(12,2) NOT NULL CHECK (precio_hora >= 0),
    estado          ENUM('Disponible', 'Ocupado', 'En mantenimiento') NOT NULL DEFAULT 'Disponible',
    encargado       VARCHAR(100) NOT NULL,
    fecha_creacion  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- Tabla: clientes
-- ---------------------------------------------------------------------
CREATE TABLE clientes (
    cliente_id       INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo  VARCHAR(150) NOT NULL,
    identificacion   VARCHAR(30) NOT NULL UNIQUE,
    telefono         VARCHAR(20) NOT NULL,
    correo           VARCHAR(120) NOT NULL UNIQUE,
    tipo_cliente     ENUM('Individual', 'Corporativo') NOT NULL DEFAULT 'Individual',
    fecha_registro   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- Tabla: reservas
--
CREATE TABLE reservas (
    reserva_id           INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id            INT NOT NULL,
    salon_id               INT NOT NULL,
    fecha_inicio            DATETIME NOT NULL,
    fecha_fin                DATETIME NOT NULL,
    precio_hora_aplicado      DECIMAL(12,2) NOT NULL CHECK (precio_hora_aplicado >= 0),
    total_horas DECIMAL(10,2)
        GENERATED ALWAYS AS (
            ROUND(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin) / 60, 2)
        ) VIRTUAL,
    valor_total DECIMAL(12,2)
        GENERATED ALWAYS AS (
            ROUND(precio_hora_aplicado
                  * ROUND(TIMESTAMPDIFF(MINUTE, fecha_inicio, fecha_fin) / 60, 2)
                  * 1.19, 2)
        ) VIRTUAL,
    estado             ENUM('Activa', 'Cancelada', 'Finalizada') NOT NULL DEFAULT 'Activa',
    fecha_creacion       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reservas_cliente
        FOREIGN KEY (cliente_id) REFERENCES clientes (cliente_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_reservas_salon
        FOREIGN KEY (salon_id) REFERENCES salones (salon_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_fechas_reserva CHECK (fecha_fin > fecha_inicio)
);

CREATE INDEX idx_reservas_salon_fechas ON reservas (salon_id, fecha_inicio, fecha_fin);
CREATE INDEX idx_reservas_cliente ON reservas (cliente_id);

-- ---------------------------------------------------------------------
-- Tabla: pagos
-- ---------------------------------------------------------------------
CREATE TABLE pagos (
    pago_id       INT AUTO_INCREMENT PRIMARY KEY,
    reserva_id     INT NOT NULL,
    fecha_pago     DATE NOT NULL,
    monto_pagado   DECIMAL(12,2) NOT NULL CHECK (monto_pagado > 0),
    metodo_pago    ENUM('Efectivo', 'Tarjeta', 'Transferencia') NOT NULL,
    CONSTRAINT fk_pagos_reserva
        FOREIGN KEY (reserva_id) REFERENCES reservas (reserva_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX idx_pagos_reserva ON pagos (reserva_id);

-- ---------------------------------------------------------------------
-- Tabla: auditoria_precios

-- ---------------------------------------------------------------------
CREATE TABLE auditoria_precios (
    auditoria_id     INT AUTO_INCREMENT PRIMARY KEY,
    salon_id          INT NOT NULL,
    usuario           VARCHAR(100) NOT NULL,
    fecha_cambio       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    precio_anterior    DECIMAL(12,2) NOT NULL,
    precio_nuevo       DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_auditoria_salon
        FOREIGN KEY (salon_id) REFERENCES salones (salon_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);
