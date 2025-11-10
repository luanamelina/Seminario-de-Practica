DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Inscripcion_Crear
AUTORA: Luana Melina Issa

VERSION: 1.2

*/

DROP PROCEDURE IF EXISTS sp_Inscripcion_Crear$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Inscripcion_Crear`(
    IN in_torneo_id  BIGINT,
    IN in_usuario_id BIGINT
) MODIFIES SQL DATA
BEGIN

    DECLARE v_max_jugadores   INT;
    DECLARE v_torneo_activo   TINYINT(1);
    DECLARE v_torneo_estado   ENUM('PENDIENTE','EN_CURSO','FINALIZADO');
    DECLARE v_count           INT;
    DECLARE v_seeding         INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        SELECT  max_jugadores,
                activo,
                estado
        INTO    v_max_jugadores,
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
                SET MESSAGE_TEXT = 'Solo se permiten inscripciones en torneos no iniciados';
        END IF;

        SELECT COUNT(*)
        INTO v_count
        FROM usuario
        WHERE id = in_usuario_id
          AND activo = 1;

        IF v_count = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El usuario no existe o está inactivo';
        END IF;

        SELECT COUNT(*)
        INTO v_count
        FROM inscripcion
        WHERE torneo_id  = in_torneo_id
          AND usuario_id = in_usuario_id
          AND activo     = 1;

        IF v_count > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El usuario ya está inscripto en este torneo';
        END IF;

        IF v_max_jugadores IS NOT NULL THEN
            SELECT COUNT(*)
            INTO v_count
            FROM inscripcion
            WHERE torneo_id = in_torneo_id
              AND activo    = 1;

            IF v_count >= v_max_jugadores THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'El torneo ya alcanzó el máximo de jugadores';
            END IF;
        END IF;

        SET v_seeding = FLOOR(1 + RAND() * 1000);

        INSERT INTO inscripcion (
            torneo_id,
            usuario_id,
            seeding,
            check_in,
            activo
        )
        VALUES (
            in_torneo_id,
            in_usuario_id,
            v_seeding,
            1,
            1
        );

        SELECT ROW_COUNT() AS 'ROW_COUNT';

    COMMIT;
END$$

DELIMITER ;
