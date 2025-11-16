DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Torneo_GenerarSiguienteRonda
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION:
*/

DROP PROCEDURE IF EXISTS sp_Torneo_GenerarSiguienteRonda$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarSiguienteRonda`(
    IN in_torneo_id BIGINT
) MODIFIES SQL DATA
BEGIN
    DECLARE v_modalidad ENUM('SUIZO','ROUND_ROBIN','BRACKET');
    DECLARE v_estado    ENUM('PENDIENTE','EN_CURSO','FINALIZADO');
    DECLARE v_activo    TINYINT(1);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        SELECT modalidad, estado, activo
        INTO   v_modalidad, v_estado, v_activo
        FROM   torneo
        WHERE  id = in_torneo_id
        LIMIT  1
        FOR UPDATE;

        IF v_activo IS NULL OR v_activo = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El torneo no existe o no está activo';
        END IF;

        IF v_estado <> 'EN_CURSO' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Solo se pueden generar rondas para torneos en curso';
        END IF;

        IF v_modalidad = 'BRACKET' THEN

            CALL sp_Torneo_GenerarSiguienteRonda_Bracket(in_torneo_id);

        ELSEIF v_modalidad = 'SUIZO' THEN

            CALL sp_Torneo_GenerarSiguienteRonda_Suizo(in_torneo_id);

        ELSEIF v_modalidad = 'ROUND_ROBIN' THEN

            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'ROUND_ROBIN ya tiene toda la estructura generada';

        ELSE

            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Modalidad de torneo no soportada';

        END IF;

    COMMIT;
END$$

DELIMITER ;
