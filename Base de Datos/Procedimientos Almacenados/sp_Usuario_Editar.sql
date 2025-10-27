DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Usuario_Editar
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION: 

*/

DROP PROCEDURE IF EXISTS sp_Usuario_Editar$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Usuario_Editar`(
    IN `in_id` INT(11),
    IN `in_nombres` VARCHAR(80),
    IN `in_apellidos` VARCHAR(80),
    IN `in_email` VARCHAR(120),
    IN `in_usuario` VARCHAR(60),
	IN `in_password` VARCHAR(200),
	IN `in_esadmin` TINYINT(1)
) MODIFIES SQL DATA

BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;
        UPDATE usuario
        SET
            nombres = in_nombres,
            apellidos = in_apellidos,
            email = in_email,
            usuario = in_usuario,
			password_hash = in_password,
			es_admin = in_esadmin
        WHERE id = in_id;

        SELECT ROW_COUNT() AS 'ROW_COUNT';

    COMMIT;
END$$
