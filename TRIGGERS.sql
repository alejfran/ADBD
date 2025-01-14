USE  FINAL ;

DELIMITER $$ 

USE  FINAL $$
DROP TRIGGER IF EXISTS FINAL.ENVIO_AFTER_INSERT  $$
USE  FINAL $$
CREATE DEFINER = CURRENT_USER TRIGGER    FINAL.ENVIO_AFTER_INSERT  AFTER INSERT ON  ENVIO  FOR EACH ROW
BEGIN
	UPDATE PEDIDO SET PEDIDO.Coste_Total = PEDIDO.Coste_Productos + new.Coste WHERE NEW.PEDIDO_Num_Pedido = PEDIDO.Num_Pedido AND NEW.PEDIDO_Usuario_DNI = PEDIDO.Usuario_DNI;
END$$

DELIMITER ;

DELIMITER $$
USE  FINAL $$
DROP TRIGGER IF EXISTS    FINAL.ENVIO_AFTER_UPDATE  $$
USE  FINAL $$
CREATE DEFINER = CURRENT_USER TRIGGER    FINAL.ENVIO_AFTER_UPDATE  AFTER UPDATE ON  ENVIO  FOR EACH ROW
BEGIN
	UPDATE PEDIDO SET PEDIDO.Coste_Total = PEDIDO.Coste_Productos + new.Coste WHERE NEW.PEDIDO_Num_Pedido = PEDIDO.Num_Pedido AND NEW.PEDIDO_Usuario_DNI = PEDIDO.Usuario_DNI;
END$$
DELIMITER ;

DELIMITER $$
USE  FINAL $$
DROP TRIGGER IF EXISTS    FINAL.PEDIDO_has_PRODUCTO_AFTER_INSERT  $$
USE  FINAL $$
CREATE DEFINER = CURRENT_USER TRIGGER    FINAL.PEDIDO_has_PRODUCTO_AFTER_INSERT  AFTER INSERT ON  PEDIDO_has_PRODUCTO  FOR EACH ROW
BEGIN
	UPDATE PEDIDO SET PEDIDO.Coste_Productos = PEDIDO.Coste_Productos + (new.Cantidad * (SELECT PRODUCTO.Coste FROM PRODUCTO 
    WHERE new.PRODUCTO_Num_Producto = PRODUCTO.Num_Producto)) WHERE PEDIDO.Num_Pedido = new.PEDIDO_Num_Pedido AND PEDIDO.Usuario_DNI = NEW.PEDIDO_Usuario_DNI;
END$$
DELIMITER ;

DELIMITER $$
USE  FINAL $$
DROP TRIGGER IF EXISTS    FINAL.PEDIDO_has_PRODUCTO_AFTER_INSERT_1  $$
USE  FINAL $$
CREATE DEFINER = CURRENT_USER TRIGGER    FINAL.PEDIDO_has_PRODUCTO_AFTER_INSERT_1  AFTER INSERT ON  PEDIDO_has_PRODUCTO  FOR EACH ROW
BEGIN
	UPDATE PRODUCTO SET PRODUCTO.Stock = PRODUCTO.Stock - new.Cantidad WHERE new.PRODUCTO_Num_Producto = PRODUCTO.Num_Producto;
END$$

DELIMITER ;

DELIMITER $$
USE  FINAL $$
DROP TRIGGER IF EXISTS    FINAL.PEDIDO_has_PRODUCTO_AFTER_UPDATE  $$
USE  FINAL $$
CREATE DEFINER = CURRENT_USER TRIGGER    FINAL.PEDIDO_has_PRODUCTO_AFTER_UPDATE  AFTER UPDATE ON  PEDIDO_has_PRODUCTO  FOR EACH ROW
BEGIN
	UPDATE PEDIDO SET PEDIDO.Coste_Productos = PEDIDO.Coste_Productos - (old.Cantidad * (SELECT PRODUCTO.Coste FROM PRODUCTO WHERE PEDIDO_HAS_PRODUCTO.PRODUCTO_Num_Producto = Producto.Num_Producto)) WHERE PEDIDO.Num_Pedido = new.PEDIDO_Num_Pedido AND PEDIDO.Usuario_DNI = NEW.PEDIDO_Usuario_DNI;
	UPDATE PEDIDO SET PEDIDO.Coste_Productos = PEDIDO.Coste_Productos + (new.Cantidad * (SELECT PRODUCTO.Coste FROM PRODUCTO WHERE PEDIDO_HAS_PRODUCTO.PRODUCTO_Num_Producto = Producto.Num_Producto)) WHERE PEDIDO.Num_Pedido = new.PEDIDO_Num_Pedido AND PEDIDO.Usuario_DNI = NEW.PEDIDO_Usuario_DNI;
END$$
DELIMITER ;

DELIMITER $$
USE  FINAL $$
DROP TRIGGER IF EXISTS    FINAL.PEDIDO_has_PRODUCTO_AFTER_UPDATE_1  $$
USE  FINAL $$
CREATE DEFINER = CURRENT_USER TRIGGER    FINAL.PEDIDO_has_PRODUCTO_AFTER_UPDATE_1  AFTER UPDATE ON  PEDIDO_has_PRODUCTO  FOR EACH ROW
BEGIN
	UPDATE PRODUCTO SET PRODUCTO.Stock = PRODUCTO.Stock + old.Cantidad WHERE old.PRODUCTO_Num_Producto = PRODUCTO.Num_Producto;
	UPDATE PRODUCTO SET PRODUCTO.Stock = PRODUCTO.Stock - new.Cantidad WHERE new.PRODUCTO_Num_Producto = PRODUCTO.Num_Producto;
END$$
DELIMITER ;

DELIMITER $$
USE  FINAL $$
DROP TRIGGER IF EXISTS    FINAL.PEDIDO_has_PRODUCTO_AFTER_DELETE  $$
USE  FINAL $$
CREATE DEFINER = CURRENT_USER TRIGGER    FINAL.PEDIDO_has_PRODUCTO_AFTER_DELETE  AFTER DELETE ON  PEDIDO_has_PRODUCTO  FOR EACH ROW
BEGIN
	UPDATE PEDIDO SET PEDIDO.Coste_Productos = PEDIDO.Coste_Productos - (old.Cantidad * (SELECT PRODUCTO.Coste FROM PRODUCTO WHERE old.PRODUCTO_Num_Producto = Producto.Num_Producto)) WHERE PEDIDO.Num_Pedido = old.PEDIDO_Num_Pedido;
	UPDATE PRODUCTO SET PRODUCTO.Stock = PRODUCTO.Stock + old.Cantidad WHERE old.PRODUCTO_Num_Producto = PRODUCTO.Num_Producto;
END$$
DELIMITER ;



DELIMITER $$
DROP TRIGGER IF EXISTS    FINAL.PAGO_BEFORE_INSERT  $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.PAGO_BEFORE_INSERT BEFORE INSERT ON PAGO FOR EACH ROW
BEGIN
    IF(NEW.Cantidad_Pagada != (SELECT Coste_Total FROM PEDIDO WHERE PEDIDO.Num_Pedido= NEW.PEDIDO_Num_Pedido AND PEDIDO.Usuario_DNI = NEW.PEDIDO_Usuario_DNI))
    THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CANTIDAD PAGADA ES DIFERENTE AL COSTE_TOTAL DEL PEDIDO';
    END IF;
END$$

DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS FINAL.verifyExistsElectronicaAlimentacion $$
CREATE DEFINER = CURRENT_USER TRIGGER FINAL.verifyExistsElectronicaAlimentacion BEFORE INSERT ON ELECTRONICA
    FOR EACH ROW
    BEGIN
        IF NEW.PRODUCTO_Num_Producto IN (
            select A.PRODUCTO_Num_Producto
            From ALIMENTACION A 
            where NEW.PRODUCTO_Num_Producto = A.PRODUCTO_Num_Producto
        ) THEN 
           SIGNAL SQLSTATE '45000' set message_text = `ESTE PRODUCTO YA PERTENECE A OTRO TIPO DE PRODUCTO el-al`;

        END IF;
    END$$
DELIMITER ;

DELIMITER $$
USE  FINAL $$
DROP TRIGGER IF EXISTS    FINAL.PEDIDO_BEFORE_UPDATE  $$
USE  FINAL $$
CREATE DEFINER = CURRENT_USER TRIGGER FINAL.PEDIDO_BEFORE_UPDATE BEFORE UPDATE ON PEDIDO FOR EACH ROW
BEGIN
IF EXISTS(SELECT ENVIO.Coste FROM ENVIO WHERE ENVIO.PEDIDO_Num_Pedido = NEW.Num_Pedido AND ENVIO.PEDIDO_Usuario_DNI = NEW.Usuario_DNI)
    THEN
    SET new.Coste_Total = (SELECT ENVIO.Coste FROM ENVIO WHERE ENVIO.PEDIDO_Num_Pedido = NEW.Num_Pedido AND ENVIO.PEDIDO_Usuario_DNI = NEW.Usuario_DNI) + new.Coste_Productos;
    END IF;
END$$

DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS FINAL.verifyExistsElectronicaLibros $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.verifyExistsElectronicaLibros BEFORE INSERT ON ELECTRONICA
    FOR EACH ROW
    BEGIN
        IF NEW.PRODUCTO_Num_Producto  IN (
            select L.PRODUCTO_Num_Producto
            From LIBROS L
            where NEW.PRODUCTO_Num_Producto = L.PRODUCTO_Num_Producto
        ) THEN 
           SIGNAL SQLSTATE '45000' set message_text = `ESTE PRODUCTO YA PERTENECE A OTRO TIPO DE PRODUCTO el-li`;
        END IF;
    END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS FINAL.verifyExistsElectronicaJuegos $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.verifyExistsElectronicaJuegos BEFORE INSERT ON ELECTRONICA
    FOR EACH ROW
    BEGIN
        IF NEW.PRODUCTO_Num_Producto IN (
            select J.PRODUCTO_Num_Producto
            From JUEGOS J
            where NEW.PRODUCTO_Num_Producto = J.PRODUCTO_Num_Producto
        ) THEN
SIGNAL SQLSTATE '45000' set message_text = `ESTE PRODUCTO YA PERTENECE A OTRO TIPO DE PRODUCTO el-ju`;

        END IF;
    END$$

DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS FINAL.verifyExistsJuegosElectronica $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.verifyExistsJuegosElectronica BEFORE INSERT ON JUEGOS
    FOR EACH ROW
    BEGIN
        IF NEW.PRODUCTO_Num_Producto IN (
            select E.PRODUCTO_Num_Producto
            From ELECTRONICA E
            where NEW.PRODUCTO_Num_Producto = E.PRODUCTO_Num_Producto
        ) THEN
          SIGNAL SQLSTATE '45000' set message_text = `ESTE PRODUCTO YA PERTENECE A OTRO TIPO DE PRODUCTO`;

        END IF;
    END$$

DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS FINAL.verifyExistsJuegosAlimentacion $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.verifyExistsJuegosAlimentacion BEFORE INSERT ON JUEGOS
    FOR EACH ROW
    BEGIN
        IF NEW.PRODUCTO_Num_Producto IN (
            select A.PRODUCTO_Num_Producto
            From ALIMENTACION A
            where NEW.PRODUCTO_Num_Producto = A.PRODUCTO_Num_Producto
        ) THEN
           CALL `ESTE PRODUCTO YA PERTENECE A OTRO TIPO DE PRODUCTO`;

        END IF;
    END$$

DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS FINAL.verifyExistsJuegosLibros $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.verifyExistsJuegosLibros BEFORE INSERT ON JUEGOS
    FOR EACH ROW
    BEGIN
        IF NEW.PRODUCTO_Num_Producto IN (
            select L.PRODUCTO_Num_Producto
            From LIBROS L
            where NEW.PRODUCTO_Num_Producto = L.PRODUCTO_Num_Producto
        ) THEN
            SIGNAL SQLSTATE '45000' set message_text = `ESTE PRODUCTO YA PERTENECE A OTRO TIPO DE PRODUCTO`;

        END IF;
    END$$
DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS FINAL.verifyExistsAlimentacionLibros $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.verifyExistsAlimentacionLibros BEFORE INSERT ON ALIMENTACION
    FOR EACH ROW
    BEGIN
        IF NEW.PRODUCTO_Num_Producto IN (
            select L.PRODUCTO_Num_Producto
            From LIBROS L
            where NEW.PRODUCTO_Num_Producto = L.PRODUCTO_Num_Producto
        ) THEN
            SIGNAL SQLSTATE '45000' set message_text = `ESTE PRODUCTO YA PERTENECE A OTRO TIPO DE PRODUCTO`;

        END IF;
    END$$

DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS FINAL.verifyExistsAlimentacionElectrónica $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.verifyExistsAlimentacionElectrónica BEFORE INSERT ON ALIMENTACION
    FOR EACH ROW
    BEGIN
        IF NEW.PRODUCTO_Num_Producto IN (
            select E.PRODUCTO_Num_Producto
            From ELECTRONICA E
            where NEW.PRODUCTO_Num_Producto = E.PRODUCTO_Num_Producto
        ) THEN
            SIGNAL SQLSTATE '45000' set message_text = `ESTE PRODUCTO YA PERTENECE A OTRO TIPO DE PRODUCTO`;

        END IF;
    END$$
DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS FINAL.verifyExistsAlimentacionJuegos $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.verifyExistsAlimentacionJuegos BEFORE INSERT ON ALIMENTACION
    FOR EACH ROW
    BEGIN
        IF NEW.PRODUCTO_Num_Producto IN (
            select J.PRODUCTO_Num_Producto
            From JUEGOS J
            where NEW.PRODUCTO_Num_Producto = J.PRODUCTO_Num_Producto
        ) THEN
            SIGNAL SQLSTATE '45000' set message_text = `ESTE PRODUCTO YA PERTENECE A OTRO TIPO DE PRODUCTO`;

        END IF;
    END$$

DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS FINAL.verifyExistsLibrosJuegos $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.verifyExistsLibrosJuegos BEFORE INSERT ON LIBROS
    FOR EACH ROW
    BEGIN
        IF NEW.PRODUCTO_Num_Producto IN (
            select J.PRODUCTO_Num_Producto
            From JUEGOS J
            where NEW.PRODUCTO_Num_Producto = J.PRODUCTO_Num_Producto
        ) THEN
            SIGNAL SQLSTATE '45000' set message_text = `ESTE PRODUCTO YA PERTENECE A OTRO TIPO DE PRODUCTO`;

        END IF;
    END$$
DELIMITER ;

DELIMITER $$

DROP TRIGGER IF EXISTS FINAL.verifyExistsLibrosElectronica $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.verifyExistsLibrosElectronica BEFORE INSERT ON LIBROS
    FOR EACH ROW
    BEGIN
        IF NEW.PRODUCTO_Num_Producto IN (
            select E.PRODUCTO_Num_Producto
            From ELECTRONICA E
            where NEW.PRODUCTO_Num_Producto = E.PRODUCTO_Num_Producto
        ) THEN
            SIGNAL SQLSTATE '45000' set message_text = `ESTE PRODUCTO YA PERTENECE A OTRO TIPO DE PRODUCTO`;

        END IF;
    END$$

DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS FINAL.verifyExistsLibrosAlimentacion $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.verifyExistsLibrosAlimentacion BEFORE INSERT ON LIBROS
    FOR EACH ROW
    BEGIN
        IF NEW.PRODUCTO_Num_Producto IN (
            select A.PRODUCTO_Num_Producto
            From ALIMENTACION A
            where NEW.PRODUCTO_Num_Producto = A.PRODUCTO_Num_Producto
        ) THEN
            SIGNAL SQLSTATE '45000' set message_text = `ESTE PRODUCTO YA PERTENECE A OTRO TIPO DE PRODUCTO`;

        END IF;
    END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS FINAL.REVISA_BEFORE_UPDATE $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.REVISA_BEFORE_UPDATE BEFORE UPDATE ON REVISA FOR EACH ROW
BEGIN
IF NEW.Usuario_DNI != NEW.PEDIDO_Usuario_DNI
	THEN
		SIGNAL SQLSTATE '45000' set message_text = 'El usuario no ha hecho un pedido con ese identificador';
    END IF;
END$$

DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS FINAL.REVISA_BEFORE_INSERT $$

CREATE DEFINER = CURRENT_USER TRIGGER FINAL.REVISA_BEFORE_INSERT BEFORE INSERT ON REVISA FOR EACH ROW
BEGIN
IF NEW.Usuario_DNI != NEW.PEDIDO_Usuario_DNI
	THEN
		SIGNAL SQLSTATE '45000' set message_text = 'El usuario no ha hecho un pedido con ese identificador';
    END IF;
END$$

DELIMITER ;