DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Torneo_GenerarEstructura_Suizo
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION:
*/

DROP PROCEDURE IF EXISTS sp_Torneo_GenerarEstructura_Suizo$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarEstructura_Suizo`(
    IN in_torneo_id BIGINT
) MODIFIES SQL DATA
BEGIN

    DECLARE v_cant_jugadores INT;
    DECLARE v_rondas         INT;
    DECLARE v_n              INT;
    DECLARE v_i              INT;
    DECLARE v_ronda_id       BIGINT;
    DECLARE v_p1             BIGINT;
    DECLARE v_p2             BIGINT;

    -- 1) Contar jugadores
    SELECT COUNT(*)
    INTO v_cant_jugadores
    FROM inscripcion
    WHERE torneo_id = in_torneo_id
      AND activo    = 1;

    IF v_cant_jugadores < 2 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cantidad insuficiente de jugadores para torneo suizo';
    END IF;

    -- 2) Definir cantidad de rondas (heurística simple)
    IF v_cant_jugadores <= 4 THEN
        SET v_rondas = 2;
    ELSEIF v_cant_jugadores <= 8 THEN
        SET v_rondas = 3;
    ELSEIF v_cant_jugadores <= 16 THEN
        SET v_rondas = 4;
    ELSE
        SET v_rondas = 5;
    END IF;

    -- 3) Crear rondas (solo ESTRUCTURA)
    SET v_i = 1;
    WHILE v_i <= v_rondas DO
        INSERT INTO ronda(torneo_id, numero, estado, inicio, activo)
        VALUES (in_torneo_id, v_i, 'PENDIENTE', NULL, 1);
        SET v_i = v_i + 1;
    END WHILE;

    -- 4) Obtener id de la ronda 1
    SELECT id
    INTO v_ronda_id
    FROM ronda
    WHERE torneo_id = in_torneo_id
      AND numero    = 1
    LIMIT 1;

    -- 5) Crear lista de jugadores ordenada por seeding
    DROP TEMPORARY TABLE IF EXISTS tmp_players_suizo;

    CREATE TEMPORARY TABLE tmp_players_suizo (
        pos        INT NOT NULL PRIMARY KEY,
        usuario_id BIGINT NULL
    );

    INSERT INTO tmp_players_suizo(pos, usuario_id)
    SELECT
        ROW_NUMBER() OVER (ORDER BY COALESCE(seeding, 999999), usuario_id) AS pos,
        usuario_id
    FROM inscripcion
    WHERE torneo_id = in_torneo_id
      AND activo    = 1;

    -- Manejo de BYE si la cantidad es impar
    SET v_n = v_cant_jugadores;

    IF (v_n % 2) <> 0 THEN
        SET v_n = v_n + 1;
        INSERT INTO tmp_players_suizo(pos, usuario_id)
        VALUES (v_n, NULL);
    END IF;

    -- 6) Emparejar jugadores para la ronda 1
    SET v_i = 1;
    WHILE v_i <= v_n / 2 DO

        SELECT usuario_id
        INTO v_p1
        FROM tmp_players_suizo
        WHERE pos = v_i;

        SELECT usuario_id
        INTO v_p2
        FROM tmp_players_suizo
        WHERE pos = (v_n - v_i + 1);

        IF v_p1 IS NOT NULL AND v_p2 IS NOT NULL THEN

            INSERT INTO match_(
                ronda_id,
                mesa,
                player1_id,
                player2_id,
                p1_wins,
                p2_wins,
                resultado,
                ganador_id,
                next_match_id,
                next_slot,
                observaciones,
                activo
            )
            VALUES (
                v_ronda_id,
                v_i,
                v_p1,
                v_p2,
                0,
                0,
                'PENDIENTE',
                NULL,
                NULL,
                NULL,
                NULL,
                1
            );

        ELSEIF v_p1 IS NOT NULL AND v_p2 IS NULL THEN

            INSERT INTO match_(
                ronda_id,
                mesa,
                player1_id,
                player2_id,
                p1_wins,
                p2_wins,
                resultado,
                ganador_id,
                next_match_id,
                next_slot,
                observaciones,
                activo
            )
            VALUES (
                v_ronda_id,
                v_i,
                v_p1,
                NULL,
                0,
                0,
                'BYE',
                v_p1,
                NULL,
                NULL,
                'BYE',
                1
            );

        ELSEIF v_p1 IS NULL AND v_p2 IS NOT NULL THEN

            INSERT INTO match_(
                ronda_id,
                mesa,
                player1_id,
                player2_id,
                p1_wins,
                p2_wins,
                resultado,
                ganador_id,
                next_match_id,
                next_slot,
                observaciones,
                activo
            )
            VALUES (
                v_ronda_id,
                v_i,
                v_p2,
                NULL,
                0,
                0,
                'BYE',
                v_p2,
                NULL,
                NULL,
                'BYE',
                1
            );

        END IF;

        SET v_i = v_i + 1;
    END WHILE;

    DROP TEMPORARY TABLE IF EXISTS tmp_players_suizo;

END$$

DELIMITER ;
