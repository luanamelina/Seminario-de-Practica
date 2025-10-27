DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Usuario_Crear
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION: 

*/

DROP PROCEDURE IF EXISTS sp_Usuario_Crear$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Usuario_Crear`(
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
