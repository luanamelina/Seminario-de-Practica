DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Torneo_GenerarEstructura_Bracket
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION:
*/

DROP PROCEDURE IF EXISTS sp_Torneo_GenerarEstructura_Bracket$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarEstructura_Bracket`(
    IN in_torneo_id BIGINT
) MODIFIES SQL DATA
BEGIN

    DECLARE v_cant_jugadores INT;
    DECLARE v_bracket_size   INT;
    DECLARE v_rounds         INT;
    DECLARE v_tmp            INT;
    DECLARE v_ronda_id       BIGINT;
    DECLARE v_i              INT;
    DECLARE v_p1             BIGINT;
    DECLARE v_p2             BIGINT;

    SELECT COUNT(*)
    INTO v_cant_jugadores
    FROM inscripcion
    WHERE torneo_id = in_torneo_id
      AND activo    = 1;

    IF v_cant_jugadores < 2 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cantidad insuficiente de jugadores para Bracket';
    END IF;

    SET v_bracket_size = 1;
    WHILE v_bracket_size < v_cant_jugadores DO
        SET v_bracket_size = v_bracket_size * 2;
    END WHILE;

    SET v_rounds = 0;
    SET v_tmp    = v_bracket_size;

    WHILE v_tmp > 1 DO
        SET v_tmp    = v_tmp / 2;
        SET v_rounds = v_rounds + 1;
    END WHILE;

    SET v_i = 1;
    WHILE v_i <= v_rounds DO
        INSERT INTO ronda(torneo_id, numero, estado, inicio, activo)
        VALUES (in_torneo_id, v_i, 'PENDIENTE', NULL, 1);
        SET v_i = v_i + 1;
    END WHILE;

    SELECT id
    INTO v_ronda_id
    FROM ronda
    WHERE torneo_id = in_torneo_id
      AND numero    = 1
    LIMIT 1;

    DROP TEMPORARY TABLE IF EXISTS tmp_players_bracket;

    CREATE TEMPORARY TABLE tmp_players_bracket (
        pos        INT NOT NULL PRIMARY KEY,
        usuario_id BIGINT NULL
    );

    INSERT INTO tmp_players_bracket(pos, usuario_id)
    SELECT
        ROW_NUMBER() OVER (ORDER BY COALESCE(seeding, 999999), usuario_id) AS pos,
        usuario_id
    FROM inscripcion
    WHERE torneo_id = in_torneo_id
      AND activo    = 1;

    SET v_i = v_cant_jugadores + 1;
    WHILE v_i <= v_bracket_size DO
        INSERT INTO tmp_players_bracket(pos, usuario_id)
        VALUES (v_i, NULL);
        SET v_i = v_i + 1;
    END WHILE;

    SET v_i = 1;
    WHILE v_i <= v_bracket_size DO

        SELECT usuario_id
        INTO v_p1
        FROM tmp_players_bracket
        WHERE pos = v_i;

        SELECT usuario_id
        INTO v_p2
        FROM tmp_players_bracket
        WHERE pos = v_i + 1;

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
                (v_i + 1) / 2,
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
                (v_i + 1) / 2,
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

        END IF;

        SET v_i = v_i + 2;
    END WHILE;

    DROP TEMPORARY TABLE IF EXISTS tmp_players_bracket;

END$$

DELIMITER ;
