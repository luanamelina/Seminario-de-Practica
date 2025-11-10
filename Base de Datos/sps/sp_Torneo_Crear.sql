DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Torneo_Crear
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION: 

*/

DROP PROCEDURE IF EXISTS sp_Torneo_Crear$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_Crear`(
    IN `in_nombre` VARCHAR(120),
    IN `in_modalidad` ENUM('SUIZO', 'ROUND_ROBIN', 'BRACKET'),
    IN `in_inicio` DATETIME,
    IN `in_max_jugadores` INT
) MODIFIES SQL DATA

BEGIN

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
