DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Match_RegistrarResultado
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION:
*/

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_Match_RegistrarResultado$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Match_RegistrarResultado`(
    IN in_match_id BIGINT,
    IN in_p1_wins  TINYINT,
    IN in_p2_wins  TINYINT,
    IN in_resultado ENUM('P1','P2','EMPATE','BYE')
)
MODIFIES SQL DATA
BEGIN
    DECLARE v_ronda_id        BIGINT;
    DECLARE v_torneo_id       BIGINT;
    DECLARE v_modalidad       ENUM('SUIZO','ROUND_ROBIN','BRACKET');
    DECLARE v_player1_id      BIGINT;
    DECLARE v_player2_id      BIGINT;
    DECLARE v_ganador_id      BIGINT;
    DECLARE v_prev_resultado  ENUM('P1','P2','EMPATE','BYE','PENDIENTE');
    DECLARE v_prev_ganador_id BIGINT;
    DECLARE v_next_match_id   BIGINT;
    DECLARE v_next_slot       TINYINT;
    DECLARE v_pendientes      INT;
    DECLARE v_next_resultado  ENUM('P1','P2','EMPATE','BYE','PENDIENTE');

    DECLARE v_pts_win  INT DEFAULT 1;
    DECLARE v_pts_draw INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        SELECT
            m.ronda_id,
            m.player1_id,
            m.player2_id,
            m.next_match_id,
            m.next_slot,
            m.resultado,
            m.ganador_id,
            r.torneo_id,
            t.modalidad
        INTO
            v_ronda_id,
            v_player1_id,
            v_player2_id,
            v_next_match_id,
            v_next_slot,
            v_prev_resultado,
            v_prev_ganador_id,
            v_torneo_id,
            v_modalidad
        FROM match_ m
        JOIN ronda  r ON r.id = m.ronda_id
        JOIN torneo t ON t.id = r.torneo_id
        WHERE m.id    = in_match_id
          AND m.activo = 1
        FOR UPDATE;

        IF v_ronda_id IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El enfrentamiento no existe o está inactivo';
        END IF;

        IF v_modalidad = 'BRACKET'
           AND v_next_match_id IS NOT NULL THEN

            SELECT resultado
            INTO v_next_resultado
            FROM match_
            WHERE id = v_next_match_id;

            IF v_next_resultado <> 'PENDIENTE' THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'No se puede corregir este match porque la siguiente ronda ya tiene resultado';
            END IF;
        END IF;

        IF v_modalidad IN ('SUIZO','ROUND_ROBIN')
           AND v_prev_resultado IS NOT NULL
           AND v_prev_resultado <> 'PENDIENTE' THEN

            IF v_prev_resultado = 'P1' THEN

                UPDATE clasificacion
                SET puntos = puntos - v_pts_win
                WHERE torneo_id  = v_torneo_id
                  AND usuario_id = v_player1_id;

            ELSEIF v_prev_resultado = 'P2' THEN

                UPDATE clasificacion
                SET puntos = puntos - v_pts_win
                WHERE torneo_id  = v_torneo_id
                  AND usuario_id = v_player2_id;

            ELSEIF v_prev_resultado = 'EMPATE' THEN
                IF v_pts_draw <> 0 THEN
                    UPDATE clasificacion
                    SET puntos = puntos - v_pts_draw
                    WHERE torneo_id  = v_torneo_id
                      AND usuario_id IN (v_player1_id, v_player2_id);
                END IF;

            ELSEIF v_prev_resultado = 'BYE' THEN

                IF v_prev_ganador_id IS NOT NULL THEN
                    UPDATE clasificacion
                    SET puntos = puntos - v_pts_win
                    WHERE torneo_id  = v_torneo_id
                      AND usuario_id = v_prev_ganador_id;
                END IF;

            END IF;

        END IF;

        IF v_modalidad = 'BRACKET'
           AND v_next_match_id IS NOT NULL
           AND v_prev_ganador_id IS NOT NULL THEN

            UPDATE match_
            SET player1_id = CASE
                                WHEN v_next_slot = 1 AND player1_id = v_prev_ganador_id
                                THEN NULL
                                ELSE player1_id
                             END,
                player2_id = CASE
                                WHEN v_next_slot = 2 AND player2_id = v_prev_ganador_id
                                THEN NULL
                                ELSE player2_id
                             END
            WHERE id = v_next_match_id;
        END IF;

        SET v_ganador_id = NULL;

        IF in_resultado = 'P1' THEN
            SET v_ganador_id = v_player1_id;

        ELSEIF in_resultado = 'P2' THEN
            SET v_ganador_id = v_player2_id;

        ELSEIF in_resultado = 'BYE' THEN
            IF v_player1_id IS NOT NULL AND v_player2_id IS NULL THEN
                SET v_ganador_id = v_player1_id;
            ELSEIF v_player2_id IS NOT NULL AND v_player1_id IS NULL THEN
                SET v_ganador_id = v_player2_id;
            END IF;
        END IF;

        UPDATE match_
        SET
            p1_wins   = in_p1_wins,
            p2_wins   = in_p2_wins,
            resultado = in_resultado,
            ganador_id = v_ganador_id
        WHERE id = in_match_id;

        IF v_modalidad IN ('SUIZO','ROUND_ROBIN') THEN

            IF in_resultado = 'P1' THEN

                UPDATE clasificacion
                SET puntos = puntos + v_pts_win
                WHERE torneo_id  = v_torneo_id
                  AND usuario_id = v_player1_id;

            ELSEIF in_resultado = 'P2' THEN

                UPDATE clasificacion
                SET puntos = puntos + v_pts_win
                WHERE torneo_id  = v_torneo_id
                  AND usuario_id = v_player2_id;

            ELSEIF in_resultado = 'EMPATE' THEN
                IF v_pts_draw <> 0 THEN
                    UPDATE clasificacion
                    SET puntos = puntos + v_pts_draw
                    WHERE torneo_id  = v_torneo_id
                      AND usuario_id IN (v_player1_id, v_player2_id);
                END IF;

            ELSEIF in_resultado = 'BYE' THEN

                IF v_ganador_id IS NOT NULL THEN
                    UPDATE clasificacion
                    SET puntos = puntos + v_pts_win
                    WHERE torneo_id  = v_torneo_id
                      AND usuario_id = v_ganador_id;
                END IF;

            END IF;

        END IF;


        IF v_modalidad = 'BRACKET'
           AND v_next_match_id IS NOT NULL
           AND v_ganador_id   IS NOT NULL THEN

            IF v_next_slot = 1 THEN

                UPDATE match_
                SET player1_id = v_ganador_id
                WHERE id = v_next_match_id;

            ELSEIF v_next_slot = 2 THEN

                UPDATE match_
                SET player2_id = v_ganador_id
                WHERE id = v_next_match_id;

            END IF;

        END IF;


        SELECT COUNT(*)
        INTO v_pendientes
        FROM match_
        WHERE ronda_id = v_ronda_id
          AND resultado = 'PENDIENTE'
          AND activo    = 1;

        IF v_pendientes = 0 THEN
            UPDATE ronda
            SET estado = 'CERRADA'
            WHERE id = v_ronda_id;
        END IF;


        IF v_modalidad IN ('SUIZO','ROUND_ROBIN') THEN
            CALL sp_Clasificacion_ActualizarPosiciones(v_torneo_id);
        END IF;

        SELECT v_ganador_id AS GANADOR_ID;

    COMMIT;
END$$

DELIMITER ;
