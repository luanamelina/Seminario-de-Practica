-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 16-11-2025 a las 04:29:44
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `sistematorneos`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Clasificacion_ActualizarPosiciones` (IN `in_torneo_id` BIGINT)  MODIFIES SQL DATA BEGIN
    SET @pos := 0;

    UPDATE clasificacion c
    JOIN (
        SELECT
            torneo_id,
            usuario_id,
            (@pos := @pos + 1) AS nueva_posicion
        FROM clasificacion
        JOIN (SELECT @pos := 0) r
        WHERE torneo_id = in_torneo_id
          AND activo    = 1
        ORDER BY puntos DESC, usuario_id ASC
    ) t
      ON c.torneo_id  = t.torneo_id
     AND c.usuario_id = t.usuario_id
    SET c.posicion = t.nueva_posicion
    WHERE c.torneo_id = in_torneo_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Inscripcion_Crear` (IN `in_torneo_id` BIGINT, IN `in_usuario_id` BIGINT)  MODIFIES SQL DATA BEGIN

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

        -- 1) Validar torneo
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Match_RegistrarResultado` (IN `in_match_id` BIGINT, IN `in_p1_wins` TINYINT, IN `in_p2_wins` TINYINT, IN `in_resultado` ENUM('P1','P2','EMPATE','BYE'))  MODIFIES SQL DATA BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_Borrar` (IN `in_id` TINYINT(11))  MODIFIES SQL DATA BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

        UPDATE torneo
        SET
            activo = 0
        WHERE id = in_id;

        SELECT ROW_COUNT() AS 'ROW_COUNT';

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_Crear` (IN `in_nombre` VARCHAR(120), IN `in_modalidad` ENUM('SUIZO','ROUND_ROBIN','BRACKET'), IN `in_inicio` DATETIME, IN `in_max_jugadores` INT)  MODIFIES SQL DATA BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

        INSERT INTO torneo (
            nombre,
			modalidad,
			estado,
			inicio,
			max_jugadores,
			activo
        )
        VALUES(
            in_nombre,
			in_modalidad,
			'PENDIENTE',
			in_inicio,
			in_max_jugadores,
			1
        );

        SELECT ROW_COUNT() AS 'ROW_COUNT';

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_Editar` (IN `in_id` INT(11), IN `in_nombre` VARCHAR(120), IN `in_inicio` DATETIME)  MODIFIES SQL DATA BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;
        UPDATE torneo
        SET
            nombre = in_nombre,
            inicio = in_inicio
        WHERE id = in_id;

        SELECT ROW_COUNT() AS 'ROW_COUNT';

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarEstructura` (IN `in_torneo_id` BIGINT)  MODIFIES SQL DATA BEGIN

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

        -- 1) Obtener datos del torneo
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

        -- Solo permitimos generar estructura para torneos PENDIENTE
        IF v_torneo_estado <> 'PENDIENTE' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'La estructura solo puede generarse para torneos pendientes';
        END IF;

        -- 2) Contar jugadores inscriptos
        SELECT COUNT(*)
        INTO v_cant_jugadores
        FROM inscripcion
        WHERE torneo_id = in_torneo_id
          AND activo    = 1;

        IF v_cant_jugadores < 2 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Cantidad insuficiente de jugadores inscriptos para generar la estructura';
        END IF;

        -- 3) Inicializar clasificacion (una fila por jugador inscripto activo)
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

        -- 4) Llamar al generador según modalidad
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

        -- 5) Cambiar estado del torneo a EN_CURSO
        UPDATE torneo
        SET estado = 'EN_CURSO'
        WHERE id = in_torneo_id;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarEstructura_Bracket` (IN `in_torneo_id` BIGINT)  MODIFIES SQL DATA BEGIN

    DECLARE v_cant_jugadores INT;
    DECLARE v_bracket_size   INT;
    DECLARE v_rounds         INT;
    DECLARE v_tmp            INT;
    DECLARE v_ronda_id       BIGINT;
    DECLARE v_i              INT;
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
            SET MESSAGE_TEXT = 'Cantidad insuficiente de jugadores para Bracket';
    END IF;

    -- 2) Calcular tamaño del cuadro (potencia de 2 >= cantidad de jugadores)
    SET v_bracket_size = 1;
    WHILE v_bracket_size < v_cant_jugadores DO
        SET v_bracket_size = v_bracket_size * 2;
    END WHILE;

    -- 3) Calcular cantidad de rondas (log2 del bracket_size, con bucle simple)
    SET v_rounds = 0;
    SET v_tmp    = v_bracket_size;

    WHILE v_tmp > 1 DO
        SET v_tmp    = v_tmp / 2;
        SET v_rounds = v_rounds + 1;
    END WHILE;

    -- 4) Crear rondas (estructura)
    SET v_i = 1;
    WHILE v_i <= v_rounds DO
        INSERT INTO ronda(torneo_id, numero, estado, inicio, activo)
        VALUES (in_torneo_id, v_i, 'PENDIENTE', NULL, 1);
        SET v_i = v_i + 1;
    END WHILE;

    -- 5) Obtener id de la ronda 1
    SELECT id
    INTO v_ronda_id
    FROM ronda
    WHERE torneo_id = in_torneo_id
      AND numero    = 1
    LIMIT 1;

    -- 6) Tabla temporal con los jugadores ordenados por seeding
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

    -- Completar con BYEs hasta el tamaño del cuadro
    SET v_i = v_cant_jugadores + 1;
    WHILE v_i <= v_bracket_size DO
        INSERT INTO tmp_players_bracket(pos, usuario_id)
        VALUES (v_i, NULL);
        SET v_i = v_i + 1;
    END WHILE;

    -- 7) Crear match_ de la PRIMERA RONDA
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

            -- BYE: pasa automáticamente v_p1 a la siguiente ronda (lógica a implementar en otro SP)
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

    -- Nota: los match_ de rondas siguientes se pueden generar dinámicamente
    -- cuando se conozcan los ganadores, utilizando next_match_id y next_slot
    -- en un SP futuro (por ejemplo sp_Bracket_RegistrarGanador).

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarEstructura_RoundRobin` (IN `in_torneo_id` BIGINT)  MODIFIES SQL DATA BEGIN

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarEstructura_Suizo` (IN `in_torneo_id` BIGINT)  MODIFIES SQL DATA BEGIN

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarSiguienteRonda` (IN `in_torneo_id` BIGINT)  MODIFIES SQL DATA BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarSiguienteRonda_Bracket` (IN `in_torneo_id` BIGINT)  MODIFIES SQL DATA proc: BEGIN

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_GenerarSiguienteRonda_Suizo` (IN `in_torneo_id` BIGINT)  MODIFIES SQL DATA proc: BEGIN

    DECLARE v_n_jugadores INT;
    DECLARE v_rondas_tot INT;
    DECLARE v_rondas_creadas INT;

    DECLARE v_ronda_id BIGINT;
    DECLARE v_ronda_num INT;

    DECLARE v_p1 BIGINT;
    DECLARE v_p2 BIGINT;
    DECLARE v_mesa INT;

    /* =============================== */
    /* 1) CONTAR JUGADORES             */
    /* =============================== */
    SELECT COUNT(*) INTO v_n_jugadores
    FROM clasificacion
    WHERE torneo_id = in_torneo_id AND activo = 1;

    IF v_n_jugadores < 2 THEN
        UPDATE torneo SET estado='FINALIZADO' WHERE id=in_torneo_id;
        LEAVE proc;
    END IF;

    /* =============================== */
    /* 2) CALCULAR RONDAS TOTALES      */
    /* =============================== */
    SET v_rondas_tot = CEIL(LOG2(v_n_jugadores));

    /* =============================== */
    /* 3) CREAR RONDA SI FALTA         */
    /* =============================== */
    SELECT COUNT(*) INTO v_rondas_creadas
    FROM ronda
    WHERE torneo_id = in_torneo_id;

    IF v_rondas_creadas < v_rondas_tot THEN
        INSERT INTO ronda(torneo_id, numero, estado)
        VALUES(in_torneo_id, v_rondas_creadas + 1, 'PENDIENTE');
    END IF;

    /* =============================== */
    /* 4) TOMAR RONDA PENDIENTE        */
    /* =============================== */
    SELECT id, numero INTO v_ronda_id, v_ronda_num
    FROM ronda
    WHERE torneo_id=in_torneo_id
      AND estado='PENDIENTE'
      AND NOT EXISTS (
          SELECT 1 FROM match_ m WHERE m.ronda_id = ronda.id AND m.activo=1
      )
    ORDER BY numero
    LIMIT 1;

    IF v_ronda_id IS NULL THEN
        UPDATE torneo SET estado='FINALIZADO' WHERE id=in_torneo_id;
        LEAVE proc;
    END IF;


    /* =============================== */
    /* 5) LISTA ORDENADA POR PUNTOS    */
    /* =============================== */
    DROP TEMPORARY TABLE IF EXISTS tmp_jugadores;

    CREATE TEMPORARY TABLE tmp_jugadores (
        usuario_id BIGINT PRIMARY KEY,
        puntos INT,
        asignado TINYINT DEFAULT 0
    );

    INSERT INTO tmp_jugadores(usuario_id, puntos)
    SELECT usuario_id, puntos
    FROM clasificacion
    WHERE torneo_id=in_torneo_id AND activo=1
    ORDER BY puntos DESC, usuario_id;


    /* =============================== */
    /* 6) ENFRENTAMIENTOS PREVIOS      */
    /* =============================== */
    DROP TEMPORARY TABLE IF EXISTS tmp_prev_matches;

    CREATE TEMPORARY TABLE tmp_prev_matches (
        p1 BIGINT,
        p2 BIGINT
    );

    INSERT INTO tmp_prev_matches(p1,p2)
    SELECT LEAST(player1_id,player2_id),
           GREATEST(player1_id,player2_id)
    FROM match_
    WHERE ronda_id IN (SELECT id FROM ronda WHERE torneo_id=in_torneo_id)
      AND player1_id IS NOT NULL
      AND player2_id IS NOT NULL
      AND activo=1;


    /* =============================== */
    /* 7) BYES PREVIOS                 */
    /* =============================== */
    DROP TEMPORARY TABLE IF EXISTS tmp_prev_byes;

    CREATE TEMPORARY TABLE tmp_prev_byes (
        usuario_id BIGINT PRIMARY KEY
    );

    INSERT INTO tmp_prev_byes(usuario_id)
    SELECT player1_id
    FROM match_
    WHERE resultado='BYE'
      AND player2_id IS NULL
      AND activo=1
      AND ronda_id IN (SELECT id FROM ronda WHERE torneo_id=in_torneo_id);


    /* =============================== */
    /* 8) EMPAREJAMIENTO SUIZO         */
    /* =============================== */

    emparejar: WHILE (SELECT COUNT(*) FROM tmp_jugadores WHERE asignado=0) > 0 DO

        /* p1: primer jugador sin asignar */
        SELECT usuario_id INTO v_p1
        FROM tmp_jugadores
        WHERE asignado=0
        ORDER BY puntos DESC, usuario_id
        LIMIT 1;

        /* p2: rival válido */
        SELECT usuario_id INTO v_p2
        FROM tmp_jugadores t
        WHERE asignado=0
          AND usuario_id <> v_p1
          AND NOT EXISTS (
              SELECT 1 FROM tmp_prev_matches
              WHERE p1 = LEAST(v_p1, t.usuario_id)
                AND p2 = GREATEST(v_p1, t.usuario_id)
          )
        ORDER BY puntos DESC, usuario_id
        LIMIT 1;

        /* ================================
             SI NO HAY RIVAL → BYE
        ================================= */
        IF v_p2 IS NULL THEN

            /* El jugador puede recibir BYE solo si nunca tuvo uno */
            IF v_p1 NOT IN (SELECT usuario_id FROM tmp_prev_byes) THEN

                /* calcular mesa */
                SELECT IFNULL(MAX(mesa),0)+1 INTO v_mesa
                FROM match_
                WHERE ronda_id = v_ronda_id;

                /* insertar BYE */
                INSERT INTO match_(
                    ronda_id, mesa,
                    player1_id, player2_id,
                    p1_wins, p2_wins,
                    resultado, ganador_id,
                    observaciones, activo
                ) VALUES (
                    v_ronda_id, v_mesa,
                    v_p1, NULL,
                    0,0,
                    'BYE', v_p1,
                    'BYE asignado',
                    1
                );

                UPDATE tmp_jugadores SET asignado=1 WHERE usuario_id=v_p1;

                ITERATE emparejar;
            END IF;

            /* Si ya tuvo BYE → forzar rival cualquiera */
            SELECT usuario_id INTO v_p2
            FROM tmp_jugadores
            WHERE asignado=0 AND usuario_id<>v_p1
            ORDER BY puntos DESC, usuario_id
            LIMIT 1;
        END IF;


        /* ================================
             MATCH NORMAL
        ================================= */

        /* calcular mesa */
        SELECT IFNULL(MAX(mesa),0)+1 INTO v_mesa
        FROM match_
        WHERE ronda_id = v_ronda_id;

        /* insertar match */
        INSERT INTO match_(
            ronda_id, mesa,
            player1_id, player2_id,
            p1_wins, p2_wins,
            resultado, ganador_id,
            activo
        ) VALUES (
            v_ronda_id, v_mesa,
            v_p1, v_p2,
            0,0,
            'PENDIENTE',
            NULL,
            1
        );

        UPDATE tmp_jugadores SET asignado=1 WHERE usuario_id=v_p1;
        UPDATE tmp_jugadores SET asignado=1 WHERE usuario_id=v_p2;

    END WHILE emparejar;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Usuario_Borrar` (IN `in_id` TINYINT(11))  MODIFIES SQL DATA BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

        UPDATE usuario
        SET
            activo = 0
        WHERE id = in_id;

        SELECT ROW_COUNT() AS 'ROW_COUNT';

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Usuario_Crear` (IN `in_nombres` VARCHAR(80), IN `in_apellidos` VARCHAR(80), IN `in_email` VARCHAR(120), IN `in_usuario` VARCHAR(60), IN `in_password` VARCHAR(200), IN `in_esadmin` TINYINT(1))  MODIFIES SQL DATA BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
		RESIGNAL; 
    END;

    START TRANSACTION;

        INSERT INTO usuario (
            nombres,
            apellidos,
            email,
            usuario,
			password_hash,
			es_admin,
			activo
        )
        VALUES(
            in_nombres,
            in_apellidos,
            in_email,
            in_usuario,
			in_password,
			in_esadmin,
			1
        );

        SELECT ROW_COUNT() AS 'ROW_COUNT';

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Usuario_Editar` (IN `in_id` INT(11), IN `in_nombres` VARCHAR(80), IN `in_apellidos` VARCHAR(80), IN `in_email` VARCHAR(120))  MODIFIES SQL DATA BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;
        UPDATE usuario
        SET
            nombres = in_nombres,
            apellidos = in_apellidos,
            email = in_email
        WHERE id = in_id;

        SELECT ROW_COUNT() AS 'ROW_COUNT';

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Usuario_Traer` (IN `in_id` BIGINT(20), IN `in_usuario` VARCHAR(60), IN `in_password_hash` VARCHAR(200), IN `in_admin` TINYINT(1), IN `in_ordendesc` INT)  MODIFIES SQL DATA BEGIN

    DECLARE consulta VARCHAR(1500);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;
    SET consulta = 'SELECT * FROM usuario WHERE activo = 1';

	IF (in_id <> 0)
	THEN
		SET consulta = CONCAT(consulta, ' AND id =', in_id);
	END IF;
	
	IF (in_usuario <> '')
	THEN
		SET consulta = CONCAT(consulta, ' AND usuario =', QUOTE(in_usuario));
	END IF;
	
	IF (in_password_hash <> '')
	THEN
		SET consulta = CONCAT(consulta, ' AND password_hash =', QUOTE(in_password_hash));
	END IF;
	
	IF (in_admin <> 0)
	THEN
		SET consulta = CONCAT(consulta, ' AND es_admin =', in_admin);
	END IF;

	IF (in_ordendesc = 1)
	THEN
		SET consulta = CONCAT(consulta, ' ORDER BY nombres DESC');
	ELSE
		SET consulta = CONCAT(consulta, ' ORDER BY nombres ASC');
	END IF;

	EXECUTE IMMEDIATE consulta;

    COMMIT;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clasificacion`
--

CREATE TABLE `clasificacion` (
  `torneo_id` bigint(20) NOT NULL,
  `usuario_id` bigint(20) NOT NULL,
  `puntos` int(11) NOT NULL DEFAULT 0,
  `posicion` int(11) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inscripcion`
--

CREATE TABLE `inscripcion` (
  `torneo_id` bigint(20) NOT NULL,
  `usuario_id` bigint(20) NOT NULL,
  `seeding` int(11) DEFAULT NULL,
  `check_in` tinyint(1) NOT NULL DEFAULT 0,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `match_`
--

CREATE TABLE `match_` (
  `id` bigint(20) NOT NULL,
  `ronda_id` bigint(20) NOT NULL,
  `mesa` int(11) DEFAULT NULL,
  `player1_id` bigint(20) NOT NULL,
  `player2_id` bigint(20) DEFAULT NULL,
  `p1_wins` tinyint(4) NOT NULL DEFAULT 0,
  `p2_wins` tinyint(4) NOT NULL DEFAULT 0,
  `resultado` enum('P1','P2','EMPATE','BYE','PENDIENTE') NOT NULL DEFAULT 'PENDIENTE',
  `ganador_id` bigint(20) DEFAULT NULL,
  `next_match_id` bigint(20) DEFAULT NULL,
  `next_slot` tinyint(4) DEFAULT NULL,
  `observaciones` varchar(255) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ronda`
--

CREATE TABLE `ronda` (
  `id` bigint(20) NOT NULL,
  `torneo_id` bigint(20) NOT NULL,
  `numero` int(11) NOT NULL,
  `estado` enum('PENDIENTE','EN_CURSO','CERRADA') NOT NULL DEFAULT 'PENDIENTE',
  `inicio` datetime DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `torneo`
--

CREATE TABLE `torneo` (
  `id` bigint(20) NOT NULL,
  `nombre` varchar(120) NOT NULL,
  `modalidad` enum('SUIZO','ROUND_ROBIN','BRACKET') NOT NULL,
  `estado` enum('PENDIENTE','EN_CURSO','FINALIZADO') NOT NULL DEFAULT 'PENDIENTE',
  `inicio` datetime DEFAULT NULL,
  `max_jugadores` int(11) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `id` bigint(20) NOT NULL,
  `nombres` varchar(80) NOT NULL,
  `apellidos` varchar(80) NOT NULL,
  `email` varchar(120) NOT NULL,
  `usuario` varchar(60) DEFAULT NULL,
  `password_hash` varchar(200) DEFAULT NULL,
  `es_admin` tinyint(1) NOT NULL DEFAULT 0,
  `activo` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`id`, `nombres`, `apellidos`, `email`, `usuario`, `password_hash`, `es_admin`, `activo`) VALUES
(6, 'Luana', 'Issa', 'test@email.com', 'user', 'admin', 1, 1),
(31, 'Katarina', 'Claes', 'katarinaclaes@hamefura.com', '', '', 0, 1),
(32, 'Jeord', 'Stuart', 'jeordstuart@hamefura.com', '', '', 0, 1),
(33, 'Sophia', 'Ascart', 'sophiaascart@hamefura.com', '', '', 0, 1),
(34, 'Mary', 'Hunt', 'maryhunt@hamefura.com', '', '', 0, 1),
(35, 'Keith', 'Claes', 'keithclaes@hamefura.com', '', '', 0, 1),
(36, 'Alan', 'Stuart', 'alanstuart@hamefura.com', '', '', 0, 1),
(37, 'Nicol', 'Ascart', 'nicolascart@hamefura.com', '', '', 0, 1),
(38, 'Maria', 'Campbell', 'mariacampbell@hamefura.com', '', '', 0, 1);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `clasificacion`
--
ALTER TABLE `clasificacion`
  ADD PRIMARY KEY (`torneo_id`,`usuario_id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `idx_orden` (`torneo_id`,`puntos`);

--
-- Indices de la tabla `inscripcion`
--
ALTER TABLE `inscripcion`
  ADD PRIMARY KEY (`torneo_id`,`usuario_id`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `match_`
--
ALTER TABLE `match_`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player2_id` (`player2_id`),
  ADD KEY `ganador_id` (`ganador_id`),
  ADD KEY `next_match_id` (`next_match_id`),
  ADD KEY `idx_ronda` (`ronda_id`),
  ADD KEY `idx_jugadores` (`player1_id`,`player2_id`);

--
-- Indices de la tabla `ronda`
--
ALTER TABLE `ronda`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `torneo_id` (`torneo_id`,`numero`);

--
-- Indices de la tabla `torneo`
--
ALTER TABLE `torneo`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `match_`
--
ALTER TABLE `match_`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

--
-- AUTO_INCREMENT de la tabla `ronda`
--
ALTER TABLE `ronda`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT de la tabla `torneo`
--
ALTER TABLE `torneo`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `clasificacion`
--
ALTER TABLE `clasificacion`
  ADD CONSTRAINT `clasificacion_ibfk_1` FOREIGN KEY (`torneo_id`) REFERENCES `torneo` (`id`),
  ADD CONSTRAINT `clasificacion_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`);

--
-- Filtros para la tabla `inscripcion`
--
ALTER TABLE `inscripcion`
  ADD CONSTRAINT `inscripcion_ibfk_1` FOREIGN KEY (`torneo_id`) REFERENCES `torneo` (`id`),
  ADD CONSTRAINT `inscripcion_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`);

--
-- Filtros para la tabla `match_`
--
ALTER TABLE `match_`
  ADD CONSTRAINT `match__ibfk_1` FOREIGN KEY (`ronda_id`) REFERENCES `ronda` (`id`),
  ADD CONSTRAINT `match__ibfk_2` FOREIGN KEY (`player1_id`) REFERENCES `usuario` (`id`),
  ADD CONSTRAINT `match__ibfk_3` FOREIGN KEY (`player2_id`) REFERENCES `usuario` (`id`),
  ADD CONSTRAINT `match__ibfk_4` FOREIGN KEY (`ganador_id`) REFERENCES `usuario` (`id`),
  ADD CONSTRAINT `match__ibfk_5` FOREIGN KEY (`next_match_id`) REFERENCES `match_` (`id`);

--
-- Filtros para la tabla `ronda`
--
ALTER TABLE `ronda`
  ADD CONSTRAINT `ronda_ibfk_1` FOREIGN KEY (`torneo_id`) REFERENCES `torneo` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
