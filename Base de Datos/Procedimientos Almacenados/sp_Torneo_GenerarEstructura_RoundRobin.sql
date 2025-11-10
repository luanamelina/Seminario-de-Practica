DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Torneo_GenerarEstructura_RoundRobin
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION:
*/

DROP PROCEDURE IF EXISTS sp_Torneo_GenerarEstructura_RoundRobin$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarEstructura_RoundRobin`(
    IN in_torneo_id BIGINT
) MODIFIES SQL DATA
BEGIN

    DECLARE v_cant_jugadores INT;
    DECLARE v_n              INT;
    DECLARE v_rondas         INT;
    DECLARE v_round          INT;
    DECLARE v_i              INT;
    DECLARE v_p1             BIGINT;
    DECLARE v_p2             BIGINT;
    DECLARE v_ronda_id       BIGINT;

    -- 1) Contar jugadores
    SELECT COUNT(*)
    INTO v_cant_jugadores
    FROM inscripcion
    WHERE torneo_id = in_torneo_id
      AND activo    = 1;

    IF v_cant_jugadores < 2 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cantidad insuficiente de jugadores para Round Robin';
    END IF;

    -- 2) Ajustar N (si impar, se agrega BYE)
    SET v_n = v_cant_jugadores;

    IF (v_n % 2) <> 0 THEN
        SET v_n = v_n + 1;
    END IF;

    -- 3) Cantidad de rondas = N - 1
    SET v_rondas = v_n - 1;

    -- 4) Crear tabla temporal de jugadores
    DROP TEMPORARY TABLE IF EXISTS tmp_players_rr;

    CREATE TEMPORARY TABLE tmp_players_rr (
        pos        INT NOT NULL PRIMARY KEY,
        usuario_id BIGINT NULL
    );

    INSERT INTO tmp_players_rr(pos, usuario_id)
    SELECT
        ROW_NUMBER() OVER (ORDER BY COALESCE(seeding, 999999), usuario_id) AS pos,
        usuario_id
    FROM inscripcion
    WHERE torneo_id = in_torneo_id
      AND activo    = 1;

    -- Si hay BYE, agregamos un NULL
    IF v_cant_jugadores <> v_n THEN
        INSERT INTO tmp_players_rr(pos, usuario_id)
        VALUES (v_n, NULL);
    END IF;

    -- 5) Bucle de rondas
    SET v_round = 1;
    WHILE v_round <= v_rondas DO

        -- 5.1) Crear la ronda
        INSERT INTO ronda(torneo_id, numero, estado, inicio, activo)
        VALUES (in_torneo_id, v_round, 'PENDIENTE', NULL, 1);

        SET v_ronda_id = LAST_INSERT_ID();

        -- 5.2) Generar los match_ de esta ronda
        SET v_i = 1;
        WHILE v_i <= v_n / 2 DO

            SELECT usuario_id
            INTO v_p1
            FROM tmp_players_rr
            WHERE pos = v_i;

            SELECT usuario_id
            INTO v_p2
            FROM tmp_players_rr
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

        -- 5.3) Rotar jugadores (excepto posición 1)
        DROP TEMPORARY TABLE IF EXISTS tmp_players_rr_copy;

        CREATE TEMPORARY TABLE tmp_players_rr_copy AS
        SELECT pos, usuario_id
        FROM tmp_players_rr;

        TRUNCATE tmp_players_rr;

        INSERT INTO tmp_players_rr(pos, usuario_id)
        SELECT
            CASE
                WHEN pos = 1 THEN 1
                WHEN pos = v_n THEN 2
                ELSE pos + 1
            END AS new_pos,
            usuario_id
        FROM tmp_players_rr_copy;

        DROP TEMPORARY TABLE IF EXISTS tmp_players_rr_copy;

        SET v_round = v_round + 1;
    END WHILE;

    DROP TEMPORARY TABLE IF EXISTS tmp_players_rr;

END$$

DELIMITER ;
