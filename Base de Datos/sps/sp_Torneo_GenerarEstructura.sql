DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Torneo_GenerarEstructura
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION:
*/

DROP PROCEDURE IF EXISTS sp_Torneo_GenerarEstructura$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarEstructura`(
    IN in_torneo_id BIGINT
) MODIFIES SQL DATA
BEGIN

    DECLARE v_modalidad       ENUM('SUIZO','ROUND_ROBIN','BRACKET');
    DECLARE v_torneo_activo   TINYINT(1);
    DECLARE v_torneo_estado   ENUM('PENDIENTE','EN_CURSO','FINALIZADO');
    DECLARE v_cant_jugadores  INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        SELECT  modalidad,
                activo,
                estado
        INTO    v_modalidad,
                v_torneo_activo,
                v_torneo_estado
        FROM torneo
        WHERE id = in_torneo_id
        LIMIT 1;

        IF v_torneo_activo IS NULL OR v_torneo_activo = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El torneo no existe o no está activo';
        END IF;

        IF v_torneo_estado <> 'PENDIENTE' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'La estructura solo puede generarse para torneos pendientes';
        END IF;

        SELECT COUNT(*)
        INTO v_cant_jugadores
        FROM inscripcion
        WHERE torneo_id = in_torneo_id
          AND activo    = 1;

        IF v_cant_jugadores < 2 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Cantidad insuficiente de jugadores inscriptos para generar la estructura';
        END IF;

        INSERT INTO clasificacion(torneo_id, usuario_id, puntos, posicion, activo)
        SELECT  i.torneo_id,
                i.usuario_id,
                0 AS puntos,
                NULL AS posicion,
                1 AS activo
        FROM inscripcion i
        LEFT JOIN clasificacion c
               ON c.torneo_id  = i.torneo_id
              AND c.usuario_id = i.usuario_id
        WHERE i.torneo_id = in_torneo_id
          AND i.activo    = 1
          AND c.usuario_id IS NULL;

        IF v_modalidad = 'SUIZO' THEN

            CALL sp_Torneo_GenerarEstructura_Suizo(in_torneo_id);

        ELSEIF v_modalidad = 'ROUND_ROBIN' THEN

            CALL sp_Torneo_GenerarEstructura_RoundRobin(in_torneo_id);

        ELSEIF v_modalidad = 'BRACKET' THEN

            CALL sp_Torneo_GenerarEstructura_Bracket(in_torneo_id);

        ELSE
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Modalidad de torneo no soportada';
        END IF;

        UPDATE torneo
        SET estado = 'EN_CURSO'
        WHERE id = in_torneo_id;

    COMMIT;
END$$

DELIMITER ;
