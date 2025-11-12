DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Torneo_Editar
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION: 

*/

DROP PROCEDURE IF EXISTS sp_Torneo_Editar$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Torneo_Editar`(
    IN `in_id` INT(11),
    IN `in_nombre` VARCHAR(120),
    IN `in_inicio` DATETIME
) MODIFIES SQL DATA

BEGIN

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
