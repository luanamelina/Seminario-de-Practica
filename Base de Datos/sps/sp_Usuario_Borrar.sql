DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Usuario_Borrar
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION:  

*/

DROP PROCEDURE IF EXISTS sp_Usuario_Borrar$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Usuario_Borrar`(
    IN `in_id` TINYINT(11)
) MODIFIES SQL DATA

BEGIN

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
