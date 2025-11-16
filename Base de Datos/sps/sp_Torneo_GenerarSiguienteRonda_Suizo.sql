DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Torneo_GenerarSiguienteRonda_Suizo
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION:
*/

DROP PROCEDURE IF EXISTS sp_Torneo_GenerarSiguienteRonda_Suizo$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarSiguienteRonda_Suizo`(
    IN in_torneo_id BIGINT
) MODIFIES SQL DATA
proc: BEGIN

    DECLARE v_ronda_num   INT;
    DECLARE v_ronda_id    BIGINT;
    DECLARE v_n           INT;
    DECLARE v_i           INT;
    DECLARE v_p1          BIGINT;
    DECLARE v_p2          BIGINT;

    SELECT r.numero, r.id
    INTO   v_ronda_num, v_ronda_id
    FROM   ronda r
    WHERE  r.torneo_id = in_torneo_id
      AND  r.estado    = 'PENDIENTE'
      AND  NOT EXISTS (
             SELECT 1 FROM match_ m
             WHERE m.ronda_id = r.id
               AND m.activo   = 1
           )
    ORDER BY r.numero
    LIMIT 1;

    IF v_ronda_id IS NULL THEN
        UPDATE torneo
        SET estado = 'FINALIZADO'
        WHERE id = in_torneo_id;
        LEAVE proc;
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_players_suizo_next;

    CREATE TEMPORARY TABLE tmp_players_suizo_next (
        pos        INT NOT NULL PRIMARY KEY,
        usuario_id BIGINT NULL
    );

    INSERT INTO tmp_players_suizo_next(pos, usuario_id)
    SELECT
        ROW_NUMBER() OVER (ORDER BY c.puntos DESC, c.usuario_id) AS pos,
        c.usuario_id
    FROM clasificacion c
    WHERE c.torneo_id = in_torneo_id
      AND c.activo    = 1;

    SELECT COUNT(*) INTO v_n FROM tmp_players_suizo_next;

    IF v_n < 2 THEN
        UPDATE torneo
        SET estado = 'FINALIZADO'
        WHERE id = in_torneo_id;
        DROP TEMPORARY TABLE IF EXISTS tmp_players_suizo_next;
        LEAVE proc;
    END IF;

    IF (v_n % 2) = 1 THEN
        SET v_n = v_n + 1;
        INSERT INTO tmp_players_suizo_next(pos, usuario_id)
        VALUES (v_n, NULL);
    END IF;

    SET v_i = 1;
    WHILE v_i <= v_n DO

        SELECT usuario_id
        INTO   v_p1
        FROM   tmp_players_suizo_next
        WHERE  pos = v_i;

        SELECT usuario_id
        INTO   v_p2
        FROM   tmp_players_suizo_next
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
                'PENDIENTE',
                NULL,
                NULL,
                NULL,
                'POSIBLE BYE',
                1
            );

        END IF;

        SET v_i = v_i + 2;
    END WHILE;

    DROP TEMPORARY TABLE IF EXISTS tmp_players_suizo_next;

END$$

DELIMITER ;
