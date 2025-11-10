DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Clasificacion_ActualizarPosiciones
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION:
*/

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_Clasificacion_ActualizarPosiciones$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Clasificacion_ActualizarPosiciones`(
    IN in_torneo_id BIGINT
)
MODIFIES SQL DATA
BEGIN
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

DELIMITER ;
