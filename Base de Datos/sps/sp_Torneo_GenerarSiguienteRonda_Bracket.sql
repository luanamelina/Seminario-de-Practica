DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Torneo_GenerarSiguienteRonda_Bracket
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION:
*/

DROP PROCEDURE IF EXISTS sp_Torneo_GenerarSiguienteRonda_Bracket$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarSiguienteRonda_Bracket`(
    IN in_torneo_id BIGINT
) MODIFIES SQL DATA
proc: BEGIN

    DECLARE v_ronda_actual        INT;
    DECLARE v_ronda_siguiente     INT;
    DECLARE v_ronda_siguiente_id  BIGINT;
    DECLARE v_cant_ganadores      INT;
    DECLARE v_matches_siguiente   INT;
    DECLARE v_n                   INT;
    DECLARE v_i                   INT;
    DECLARE v_p1                  BIGINT;
    DECLARE v_p2                  BIGINT;

    SELECT MAX(numero)
    INTO   v_ronda_actual
    FROM   ronda
    WHERE  torneo_id = in_torneo_id
      AND  estado    = 'CERRADA';

    IF v_ronda_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No hay ninguna ronda cerrada para generar la siguiente';
    END IF;

    SELECT COUNT(*)
    INTO   v_cant_ganadores
    FROM   match_ m
    JOIN   ronda  r ON r.id = m.ronda_id
    WHERE  r.torneo_id  = in_torneo_id
      AND  r.numero     = v_ronda_actual
      AND  m.ganador_id IS NOT NULL
      AND  m.activo     = 1;

    IF v_cant_ganadores <= 1 THEN
        UPDATE torneo
        SET estado = 'FINALIZADO'
        WHERE id = in_torneo_id;
        LEAVE proc;
    END IF;

    SET v_ronda_siguiente = v_ronda_actual + 1;

    SELECT id
    INTO   v_ronda_siguiente_id
    FROM   ronda
    WHERE  torneo_id = in_torneo_id
      AND  numero    = v_ronda_siguiente
    LIMIT  1;

    IF v_ronda_siguiente_id IS NULL THEN
        INSERT INTO ronda(torneo_id, numero, estado, inicio, activo)
        VALUES (in_torneo_id, v_ronda_siguiente, 'PENDIENTE', NULL, 1);
        SET v_ronda_siguiente_id = LAST_INSERT_ID();
    ELSE
        SELECT COUNT(*)
        INTO   v_matches_siguiente
        FROM   match_
        WHERE  ronda_id = v_ronda_siguiente_id
          AND  activo   = 1;

        IF v_matches_siguiente > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'La siguiente ronda ya fue generada';
        END IF;
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_ganadores_bracket;

    CREATE TEMPORARY TABLE tmp_ganadores_bracket (
        pos        INT NOT NULL PRIMARY KEY,
        usuario_id BIGINT NULL
    );

    INSERT INTO tmp_ganadores_bracket(pos, usuario_id)
    SELECT
        ROW_NUMBER() OVER (ORDER BY m.id) AS pos,
        m.ganador_id
    FROM match_ m
    JOIN ronda  r ON r.id = m.ronda_id
    WHERE r.torneo_id  = in_torneo_id
      AND r.numero     = v_ronda_actual
      AND m.ganador_id IS NOT NULL
      AND m.activo     = 1;

    SELECT COUNT(*) INTO v_n FROM tmp_ganadores_bracket;

    IF (v_n % 2) = 1 THEN
        SET v_n = v_n + 1;
        INSERT INTO tmp_ganadores_bracket(pos, usuario_id)
        VALUES (v_n, NULL);
    END IF;

    SET v_i = 1;
    WHILE v_i <= v_n DO

        SELECT usuario_id
        INTO   v_p1
        FROM   tmp_ganadores_bracket
        WHERE  pos = v_i;

        SELECT usuario_id
        INTO   v_p2
        FROM   tmp_ganadores_bracket
        WHERE  pos = v_i + 1;

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
                v_ronda_siguiente_id,
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
                v_ronda_siguiente_id,
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

    DROP TEMPORARY TABLE IF EXISTS tmp_ganadores_bracket;

END$$

DELIMITER ;
