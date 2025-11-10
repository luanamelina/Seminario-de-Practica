DELIMITER $$

/*
PROCEDIMIENTO ALMACENADO: sp_Usuario_Traer
AUTORA: Luana Melina Issa

VERSION: 1.0

DESCRIPCION:

*/

DROP PROCEDURE IF EXISTS sp_Usuario_Traer$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_Usuario_Traer`(
	IN `in_id` BIGINT(20),
	IN `in_usuario` VARCHAR(60),
	IN `in_password_hash` VARCHAR(200),
	IN `in_admin` TINYINT(1),
    IN `in_ordendesc` INT
) MODIFIES SQL DATA

BEGIN

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
