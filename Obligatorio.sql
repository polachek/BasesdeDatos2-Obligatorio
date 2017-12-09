/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*								SE PIDE #1								  */
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/


/* Creacion de la BD */
CREATE DATABASE BD_INVESTIGACIONES
go
USE BD_INVESTIGACIONES
go
/* Creacion de tablas */

create table Universidad (
	nombre varchar(100), 
	pais varchar(50) not null, 
	ciudad varchar(50) not null 
	)
go

create table Investigador (
	idInvestigador int, 
	nombre varchar(100) not null, 
	mail varchar(200), 
	telefono varchar(20),
	carrera varchar(50), 
	nivelInvestig varchar(20) not null, 
	cantTrabPub int )
go

create Table Trabajo (
		idTrab int not null, 
		nomTrab varchar(100) not null, 
		descripTrab varchar(10) not null, 
		tipoTrab varchar(20) not null, 
		fechaInicio date not null, 
		linkTrab varchar(200),
        lugarPublic int)
go

create table Tags (
	idtag int, 
	palabra varchar(50))
go

create Table TTags (
	idTrab Varchar(10) not null, 
	idTag int not null
	)
go
	
create Table TAutores (
	idTrab varchar(10) not null,
	idInvestigador int not null, 
	rolinvestig varchar(3))
go
	
create Table Referencias (
	idTrab varchar(10) not null,
	idTrabReferenciado varchar(10) not null
	)
go
	
create Table Lugares (
	idLugar int primary key, 
	nombre varchar(100) not null, 
	nivelLugar int , 
	año int not null, 
	mes int not null, 
	diaIni int, 
	diaFin int, 
	link varchar(200), 
	universidad varchar(50) )
go



/*########################################################################*/
/*              ALTERACIONES PARA AGREGAR RESTRICCIONES      			  */
/*########################################################################*/

/* UNIVERSIDAD */

ALTER TABLE Universidad
ALTER COLUMN nombre VARCHAR(100) NOT NULL;
GO

ALTER TABLE Universidad
ADD Constraint pk_nombre Primary key(nombre)
GO

ALTER TABLE Universidad 
ADD telefono varchar(20) not null;
GO

/*-------------------------------------------------------------------------*/

/* INVESTIGADOR */
ALTER TABLE Investigador
DROP COLUMN idInvestigador
GO

ALTER TABLE Investigador
ADD idInvestigador INT NOT NULL IDENTITY(1,1)
GO

ALTER TABLE Investigador
ADD idUniversidad VARCHAR(100) NOT NULL
GO

ALTER TABLE Investigador
ADD CONSTRAINT Investigador_PK PRIMARY KEY (idInvestigador)
GO

ALTER TABLE Investigador
ADD CONSTRAINT Investigador_FK FOREIGN KEY (idUniversidad)
REFERENCES Universidad
GO

ALTER TABLE Investigador
ADD CONSTRAINT NivelInv_CH CHECK (nivelInvestig IN ('EGrado', 'EMaestria', 'EDoctor', 'Doctor'))
GO

ALTER TABLE Investigador
ADD UNIQUE (Mail)
GO

ALTER TABLE Investigador
ALTER COLUMN cantTrabPub INT NOT NULL
GO

/*-------------------------------------------------------------------------*/
/*Disparador para controlar que un INVESTIGADOR no cambie de UNIVERSIDAD */
CREATE TRIGGER INVESTIGADOR_UNIVERSIDAD
ON Investigador
INSTEAD OF UPDATE
AS
BEGIN
	IF(EXISTS
		(
			SELECT * 
			FROM Investigador x, inserted i
			WHERE x.idInvestigador = i.idInvestigador
			AND x.idUniversidad <> i.idUniversidad
		)
	)
	BEGIN
		PRINT 'No se admiten cambios de UNIVERSIDAD para un INVESTIGADOR.' 
	END		
	ELSE
	BEGIN
		UPDATE Investigador
		SET nombre = i.nombre, mail = i.mail, telefono = i.telefono, carrera = i.carrera, nivelInvestig = i.nivelInvestig,cantTrabPub = i.cantTrabPub,idUniversidad = i.idUniversidad
		FROM inserted i, Investigador inv
		where i.idInvestigador = inv.idInvestigador
	END
END
GO

/*-------------------------------------------------------------------------*/

/* TRABAJO */
ALTER TABLE Trabajo
DROP COLUMN idTrab
GO

ALTER TABLE Trabajo
ADD idTrab varchar(10) not null;
GO

ALTER TABLE Trabajo
ALTER COLUMN descripTrab VARCHAR(200)
GO

ALTER TABLE Trabajo
ADD CONSTRAINT tipoTrab_check CHECK (tipoTrab IN ('poster', 'articulo', 'capitulo', 'otro'))
GO

ALTER TABLE Trabajo
ADD CONSTRAINT Trabajo_PK PRIMARY KEY (idTrab)
GO

ALTER TABLE Trabajo
ADD CONSTRAINT Trabajo_FK FOREIGN KEY (lugarPublic)
REFERENCES Lugares
GO

/*-------------------------------------------------------------------------*/
/*Disparador para generar ID Trabajo */

CREATE TRIGGER trig_idTrab
ON Trabajo
INSTEAD OF INSERT
AS
BEGIN

  DECLARE @ultINS int;
  SET @ultINS = (select COUNT(*) from Trabajo where tipoTrab in (select tipoTrab from inserted));

  DECLARE @alphaNumID varchar(10);
  SELECT @alphaNumID = UPPER(SUBSTRING(tipoTrab, 1, 1)) from inserted;

  SET @alphaNumID = @alphaNumID + CONVERT(varchar(10), @ultINS);

  INSERT INTO Trabajo
  SELECT nomTrab, descripTrab, tipoTrab, fechaInicio, linkTrab, lugarPublic, @alphaNumID
  FROM inserted
END
GO

/*-------------------------------------------------------------------------*/

/* TAGS */
ALTER TABLE Tags
ALTER COLUMN idTag INT NOT NULL
GO

ALTER TABLE Tags
ADD CONSTRAINT Tags_PK PRIMARY KEY (idTag)
GO

/* Disparador para generar secuenciador autonumérico impar en tabla TAGS*/
CREATE TRIGGER IdTag_TAGS
ON Tags
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	DECLARE @contador INT,
			@maximo INT	
	IF(EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted))
	BEGIN	
	    IF (NOT EXISTS( SELECT * FROM Tags))
		 BEGIN
		    SET @maximo = 1
			INSERT Tags
			SELECT idtag = @maximo, palabra = inserted.palabra
			FROM inserted
		 END
		ELSE
		 BEGIN
		  SELECT @maximo = MAX(idtag) FROM Tags
			IF((@maximo >= 2 AND @maximo%2 = 1) OR @maximo = 1)
			BEGIN
				SET @maximo = @maximo + 2
				INSERT Tags
				SELECT idtag = @maximo, palabra = inserted.palabra
				FROM inserted
			END
			ELSE IF((@maximo >= 2 AND @maximo%2 = 0))
			BEGIN
				SET @maximo = @maximo + 1
				INSERT Tags
				SELECT idtag = @maximo, palabra = inserted.palabra
				FROM inserted
			END 
	     END
	END
	ELSE IF(EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted))
	 BEGIN
		UPDATE Tags
		set palabra = inserted.palabra
		from inserted
		where Tags.idtag = inserted.idtag
	 END	 
END
GO
/*-------------------------------------------------------------------------*/

/* TTAGS */
ALTER TABLE TTags
ADD CONSTRAINT TTags_PK PRIMARY KEY (idTrab, idTag)
GO

ALTER TABLE TTags
ADD CONSTRAINT TTags_FK1 FOREIGN KEY (idTrab)
REFERENCES Trabajo
GO

ALTER TABLE TTags
ADD CONSTRAINT TTags_FK2 FOREIGN KEY (idTag)
REFERENCES Tags
GO

/*-------------------------------------------------------------------------*/

/* TAUTORES */
ALTER TABLE TAutores
ADD CONSTRAINT TAutores_PK PRIMARY KEY (idTrab, idInvestigador)
GO

ALTER TABLE TAutores
ADD CONSTRAINT TAutores_FK1 FOREIGN KEY (idTrab)
REFERENCES Trabajo
GO

ALTER TABLE TAutores
ADD CONSTRAINT TAutores_FK2 FOREIGN KEY (idInvestigador)
REFERENCES Investigador
GO

ALTER TABLE TAutores
ALTER COLUMN rolinvestig varchar(20);
GO

ALTER TABLE TAutores
ADD CONSTRAINT rolinvestig_check CHECK (rolinvestig IN ('autor-ppal', 'autor-sec', 'autor-director'))
GO

/*-------------------------------------------------------------------------*/

/* REFERENCIAS */
ALTER TABLE Referencias
ADD CONSTRAINT Referencias_PK PRIMARY KEY (idTrab, idTrabReferenciado)
GO

ALTER TABLE Referencias
ADD CONSTRAINT Referencias_FK_Trab FOREIGN KEY (idTrab)
REFERENCES Trabajo
GO

ALTER TABLE Referencias
ADD CONSTRAINT Referencias_FK_TrabRef FOREIGN KEY (idTrabReferenciado)
REFERENCES Trabajo
GO

/*-------------------------------------------------------------------------*/
/* Disparador para que un trabajo no se referencia a sí mismo en la tabla referencias.*/

CREATE TRIGGER EvitarReferenciaCircular_REFERENCIAS
ON Referencias
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	DECLARE @trabajo VARCHAR(10)
	DECLARE @referencia VARCHAR(10)		
	SELECT @trabajo = idTrab FROM inserted
	SELECT @referencia = idTrabReferenciado FROM inserted	

	IF(EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted))
	 BEGIN
		IF(@trabajo <> @referencia)
		BEGIN
			INSERT Referencias
			VALUES (@trabajo, @referencia)
		END
		ELSE
		BEGIN
			PRINT 'Un trabajo no puede referenciarse a sí mismo.'
		END
	 END
	ELSE
	 BEGIN
		IF(@trabajo <> @referencia)
		 BEGIN
			UPDATE Referencias
			SET idTrabReferenciado = @referencia
			FROM inserted
			WHERE Referencias.idTrab = @trabajo
		 END
		ELSE
		 BEGIN
			PRINT 'Un trabajo no puede referenciarse a sí mismo.'
		 END
	 END
END
GO
/*-------------------------------------------------------------------------*/

/* LUGARES */
ALTER TABLE Lugares
ALTER COLUMN nombre varchar(250) not null;
GO

ALTER TABLE Lugares
ADD CONSTRAINT nombre_uniq unique (nombre);
GO

ALTER TABLE Lugares
ADD tipoLugar varchar(10) not null;
GO

ALTER TABLE Lugares
ADD CONSTRAINT tipoLugar_check CHECK (tipoLugar IN ('Congresos', 'Revistas', 'Libros'))
GO

ALTER TABLE Lugares
ADD CONSTRAINT nivelLugar_check CHECK (nivelLugar BETWEEN 1 and 4);
GO

ALTER TABLE Lugares
ALTER COLUMN universidad VARCHAR(100) NOT NULL
GO

ALTER TABLE Lugares
ADD CONSTRAINT Lugares_FK FOREIGN KEY (universidad)
REFERENCES Universidad
GO

ALTER TABLE Lugares
ADD CONSTRAINT mes_check CHECK (mes BETWEEN 1 and 12)
GO

ALTER TABLE Lugares
ADD CONSTRAINT diaI_check CHECK (diaIni BETWEEN 1 and 31)
GO

ALTER TABLE Lugares
ADD CONSTRAINT diaF_check CHECK (diaFin BETWEEN 1 and 31)
GO

ALTER TABLE Lugares
ADD CONSTRAINT año_check CHECK (año BETWEEN 1900 and YEAR( GETDATE()));
GO

/*-------------------------------------------------------------------------*/
/* Disparador para controlar que diaFin no sea nulo cuando tipolugar tiene 
valor 'Congresos' en tabla LUGARES*/

CREATE TRIGGER EvitarDiaFinNulo_LUGARES
ON Lugares
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @anio VARCHAR (4),
			@mes VARCHAR (2),
			@diaIni VARCHAR (2),
			@diaFin VARCHAR (10),
			@fechaInicio DATE,
			@fechaFin DATE,
			@fechaActual DATE
		
		SELECT @anio = CAST(año AS VARCHAR(4)) FROM inserted
		SELECT @mes = CAST(mes AS VARCHAR(2)) FROM inserted
		SELECT @diaIni = CAST(diaIni AS varchar(2)) FROM inserted		
		SET @fechaInicio = CONVERT(date, @anio+'-'+@mes+'-'+@diaIni)
		
		IF(EXISTS (SELECT tipoLugar from inserted WHERE tipoLugar LIKE 'Congresos')  AND NOT EXISTS (SELECT diaFin FROM inserted WHERE diafin IS NULL))
		BEGIN

			SELECT @diaFin = CAST(diaFin AS VARCHAR(2)) FROM inserted
			SET @fechaFin = CONVERT(date, @anio+'-'+@mes+'-'+@diaFin)
			SET @fechaActual = GETDATE()
			IF(@fechaInicio < @fechaFin AND @fechaInicio < @fechaActual)
			BEGIN
				INSERT Lugares
				SELECT idLugar = inserted.idLugar, nombre = inserted.nombre, nivelLugar = inserted.nivelLugar, año = inserted.año, mes = inserted.mes, diaIni = inserted.diaIni, diaFin = inserted.diaFin, link = inserted.link, universidad = inserted.universidad, tipoLugar = inserted.tipoLugar
				FROM inserted
			END
			ELSE
			BEGIN
				PRINT 'La fecha de inicio debe ser anterior a la fecha fin y ambas deben ser anteriores a la fecha actual.'
			END				
		END
		ELSE 
		BEGIN
			PRINT 'Todos los congresos deben tener un día fin.'				
		END
END
GO

/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*                              SE PIDE #2                      		  */
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/* 2. Creación de índices que considere puedan ser útiles para optimizar las consultas
 (según criterio establecido en el curso)*/

CREATE INDEX i_investigador_uni ON Investigador(idUniversidad);
CREATE INDEX i_lugares_uni ON Lugares(universidad);
CREATE INDEX i_autores_investigador ON TAutores(idInvestigador);
CREATE INDEX i_trabajo_lugar ON Trabajo(lugarPublic);
CREATE INDEX i_trabajo_referenciado ON Referencias(idTrabReferenciado);
CREATE INDEX i_ttags_tags ON TTags(idTag);
GO

/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*                              SE PIDE #3                      		  */
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/* 3. Ingreso de un juego completo de datos de prueba (será más valorada la calidad de los datos
más que la cantidad. El mismo debería incluir ejemplos que deban ser rechazados por no
cumplir con las restricciones implementadas.*/

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                           Tabla UNIVERSIDAD                              */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*Datos OK*/
INSERT INTO Universidad
VALUES 
('Udelar', 'Uruguay', 'Montevideo', '29009999'),
('ORT', 'Uruguay', 'Montevideo', '27007777'),
('UCUDAL', 'Uruguay', 'Montevideo', '24004444'),
('UM', 'Uruguay', 'Montevideo', '26006666'),
('Universidad de Palermo', 'Argentina', 'Buenos Aires', '44116666'),
('UBA', 'Argentina', 'Buenos Aires', '44110000'),
('Universidad de Córdoba', 'Argentina', 'Córdoba', '45000000'),
('Universidad de Brasilia', 'Brasil', 'Brasilia', '62501253'),
('Universidad Federal de Alagoas', 'Brasil', 'Alagoas', '78514569'),
('Universidad de Amazonas', 'Brasil', 'Amazonas', '35358978')


/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                           Tabla LUGARES                                  */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* Datos OK */
INSERT INTO Lugares
VALUES
(1, 'Teatro Solis', 4, 2016, 11, 8, null, 'http://www.teatrosolis.org.uy', 'Udelar', 'Revistas'),
(2, 'LATU', 3, 2015, 11, 9, 13, 'www.latu.org.uy', 'ORT', 'Congresos'),
(3, 'Radisson Victoria Plaza Hotel', 4, 2015, 5, 20, null, 'https://www.radissonblu.com', 'UM', 'Libros'),
(4, 'Holiday Inn', 2, 2017, 2, 10, 16, 'https://www.ihg.com', 'UCUDAL', 'Congresos'),
(5, 'Hotel Dazzler', 1, 2014, 8, 8, null, 'https://www.dazzlerhoteles.com', 'UBA', 'Revistas')


/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                           Tabla INVESTIGADOR                             */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*Datos OK*/
INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES 
('Marcelo López', 'mlopez@investigadores.com.uy', '098999999', 'Ingeniería Química', 'EGrado', 5,'Udelar'),
('Laura Marquisio', 'lmarqui@investigadores.com.uy', '098111111', 'Licenciatura en Relaciones Internacionales', 'EMaestria', 1,'UM'),
('Fabián Méndez', 'fmendez@investigadores.com.uy', '095951135', 'Licenciatura en Economía', 'EMaestria', 3,'Udelar'),
('Silvia Luque', 'sluque@investigadores.com.uy', '096457215', 'Licenciatura en Economía', 'EDoctor', 9,'Udelar'),
('Silvio Duarte', 'sduarte@investigadores.com.uy', '099485245', 'Licenciatura en Sistemas', 'Doctor', 15,'Udelar'),
('Walter Clitish', 'wclitish@investigadores.com.uy', '099123456', 'Licenciatura en Letras', 'EDoctor', 12,'Udelar'),
('Maicol Uriarte', 'muriarte@investigadores.com.uy', '15648524', 'Licenciatura en Bellas Artes', 'EMaestria', 9,'UBA'),
('Marianela Ifrán', 'mifran@investigadores.com.uy', '15677425', 'Ingeniería Naval', 'EGrado', 1,'Universidad de Córdoba'),
('Linda Cibils', 'lcibils@investigadores.com.uy', '48579568', 'Licenciatura en Ciencias Biológicas', 'EDoctor', 5,'Universidad de Amazonas'),
('Marcio Avellanal', 'mavellanal@investigadores.com.uy', '45129685', 'Licenciatura en Matemáticas', 'EDoctor', 5,'Universidad Federal de Alagoas')

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                              Tabla TRABAJO                               */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* Datos OK */
INSERT INTO Trabajo
VALUES
('Investigacion GARZA CUCA', 'La garza cuca o también denominada garza mora (Ardea cocoi) es un ave nativa del Centro y Sudamérica, se estudia su ambiente y entorno', 'articulo', '2016-04-03', 'https://www.infoanimales.com/informacion-sobre-la-garza-cuca',1, 'id'),
('Venado de campo', 'Investigacion sobre el venado de campo, uno de los integrantes más característicos de la fauna uruguaya', 'capitulo', '2017-02-01', 'http://blogs.ceibal.edu.uy/formacion/colecciones-de-recursos/venado-de-campo/',2, 'id'),
('Investigacion sobre el Agua', 'El agua es un bien y un recurso cada vez mas escaso, que debe ser valorado, protegido y recuperado', 'poster', '2017-05-17', 'https://es.slideshare.net/sssanchezayelen/investigacin-sobre-el-agua',3, 'id'),
('Investigacion sobre las drogas', 'La drogadicción es una enfermedad que consiste en la dependencia de sustancias que afectan el sistema nervioso central y las funciones cerebrales', 'articulo', '2017-05-17', 'https://www.monografias.com/docs/Investigacion-sobre-las-drogas-FKJQBHKYMZ',4, 'id'),
('Investigacion sobre medio ambiente ', 'El análisis de lo ambiental desde la perspectiva de lo social', 'Otro', '2017-08-20', 'http://cis.ufro.cl/index.php?option=com_content&view=article&id=45&Itemid=34',5, 'id'),
('Investigacion sobre Cultura maya ', 'La civilización maya es sin duda la más fascinante de las antiguas culturas americanas', 'Otro', '2017-04-28', 'https://www.biografiasyvidas.com/historia/cultura_maya.htm',5, 'id')

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                              Tabla TAGS                                  */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*Datos OK*/
INSERT INTO Tags
VALUES 
(1, 'garza'),
(1, 'cuca'),
(1, 'venado'),
(1, 'campo'),
(1, 'fauna'),
(1, 'animales'),
(1, 'silvestre'),
(1, 'agua'),
(1, 'ambiente'),
(1, 'ecología'),
(1, 'drogas'),
(1, 'adicciones'),
(1, 'cultura'),
(1, 'mayas')

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                              Tabla TTAGS                                 */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*Datos OK*/
INSERT INTO TTags
VALUES 
('A0',1),
('A0',3),
('C0',5),
('O0',7),
('O1',9),
('P0',15),
('O1',17)

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                           Tabla TAUTORES                                 */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

INSERT INTO TAutores
VALUES
('A0',1,'autor-ppal'),
('A0',5,'autor-sec'),
('C0',2,'autor-director'),
('O1',2,'autor-ppal'),
('P0',3,'autor-director'),
('A1',4,'autor-ppal'),
('A1',6,'autor-ppal'),
('A1',9,'autor-sec'),
('A0',9,'autor-sec'),
('A1',8,'autor-director')

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                      Tabla REFERENCIAS                                  */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/* Datos OK */
INSERT INTO Referencias
VALUES
('A0','C0'),
('P0','O0'),
('A0','A1')


/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*                              SE PIDE #4                      		  */
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/

/* 4a - Crear una función que dada una universidad devuelva el último trabajo 
publicado por esta. Si hay más de uno devolver uno cualquiera.*/

CREATE FUNCTION fn_UltimoTrabajoPorUniv (@unaUniversidad VARCHAR(100))
RETURNS VARCHAR(110)
AS
BEGIN
	DECLARE @ultTrabajo VARCHAR(10)
	DECLARE @nomTrabajo VARCHAR(100)
	DECLARE @ret VARCHAR(110)

	SELECT @ultTrabajo = idTrab , @nomTrabajo = nomTrab
	FROM Trabajo tr
	WHERE tr.fechaInicio in (Select Max(fechaInicio) from Trabajo where lugarPublic IN 
	(
		SELECT idLugar
		FROM Lugares
		WHERE universidad = @unaUniversidad
	))	
	
	 set @ret = @ultTrabajo + ' - ' + @nomTrabajo;

RETURN @ret
END
GO

declare @ultTrabUni VARCHAR(110);
set @ultTrabUni = dbo.fn_UltimoTrabajoPorUniv('ORT')
PRINT @ultTrabUni

select * from Lugares
select * from Trabajo

/* 4b - Crear una función almacenada que reciba como parámetro un trabajo 
y devuelva la cantidad de referencias externas que tiene.*/

CREATE FUNCTION fn_CantReferenciasExt ( @unTrabajo VARCHAR(100))
RETURNS INT
AS
BEGIN
	DECLARE @cantReferencias INT
	IF(EXISTS (	SELECT * FROM Referencias r WHERE r.idTrab = @unTrabajo))
	BEGIN
		SELECT @cantReferencias = COUNT(*)
		FROM Referencias r
		WHERE r.idTrab = @unTrabajo 		
		AND  r.idTrabReferenciado NOT IN(
			SELECT idTrab
			from TAutores a
			where idInvestigador in (
			 select idInvestigador
			 from TAutores b
			 where r.idTrab = b.idTrab
			)
		)
	END
	ELSE
	 BEGIN
	  SET @cantReferencias = 0
	 END

RETURN @cantReferencias
END
GO

declare @cantRef int;
set @cantRef = dbo.fn_CantReferenciasExt('P0')
PRINT @cantRef

declare @cantRef int;
set @cantRef = dbo.fn_CantReferenciasExt('A0')
PRINT @cantRef
go


/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* 4c - Crear una función que reciba dos investigadores y devuelva 
la cantidad de trabajos publicados en los cuales ambos investigadores fueron autores 
y alguno de los dos o los dos fueron autores principales.*/

CREATE FUNCTION fn_CantTrabPublicados
(
	@investigadorA INT,
	@investigadorB INT
)
RETURNS INT
AS
BEGIN
	DECLARE @cantTrabajos INT

	SELECT @cantTrabajos = COUNT (DISTINCT x.idTrab)
	from TAutores x, TAutores y
	where x.idInvestigador = @investigadorA
	and y.idInvestigador = @investigadorB
	and x.idTrab = y.idTrab
	and (x.rolinvestig = 'autor-ppal' or y.rolinvestig= 'autor-ppal') 

RETURN @cantTrabajos
END
GO

declare @cantTrabInvs int;
set @cantTrabInvs = dbo.fn_CantTrabPublicados(6,8)
PRINT @cantTrabInvs


GO
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* 4d - Crear una función o procedimiento, según considere/corresponda, 
que dado un investigador actualice el campo cantidad de trabajos publicados 
registrados de la tabla Investigador, y devuelva una indicación de si la cantidad 
que estaba registrada (antes de la actualización) era correcta o no.*/

CREATE PROCEDURE spu_UpdateCantTrab
@unInvestigador INT,
@mensaje VARCHAR(200) output
AS
BEGIN
	DECLARE @cantTrabajosEfectivos INT,
			@cantTrabajosContados INT
	
	SELECT @cantTrabajosEfectivos = COUNT(*)
	FROM TAutores
	WHERE idInvestigador = @unInvestigador

	SELECT @cantTrabajosContados = cantTrabPub
	FROM Investigador
	WHERE idInvestigador = @unInvestigador

	IF(@cantTrabajosContados = @cantTrabajosEfectivos)
	BEGIN
		SET @mensaje = 'La cantidad de trabajos era correcta, no fue necesario actualizar la tabla.'		
	END
	ELSE
	BEGIN
		UPDATE Investigador
		SET cantTrabPub = @cantTrabajosEfectivos
		WHERE idInvestigador = @unInvestigador
		SET @mensaje = 'La cantidad de trabajos no era correcta, la tabla se actualizó con el valor correcto.'		
	END
END
go

declare @mensaje varchar(200)
EXEC spu_UpdateCantTrab 9, @mensaje output
print @mensaje

select * from Investigador

go
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*
4.e Crear una función que dado dos años (año1 y año2) y una palabra clave devuelva 
la cantidad de trabajos publicados en libros o revistas en el rango de años 
y que trata el tema indicado por la palabra clave.*/

CREATE FUNCTION fn_CantTrbjAniosClave(
@anio1 INT,
@anio2 INT,
@clave varchar(50)
)
RETURNS INT
AS
BEGIN
 Declare @cantidad int;
 select @cantidad = COUNT(*)
FROM Trabajo
WHERE idTrab in (
	SELECT idTrab
	From TTags 
	where idTag in(
		 Select idTag 
		 from Tags
		 where palabra = @clave
    )
) AND lugarPublic in (
					SELECT idLugar
					from Lugares
					where (tipoLugar = 'Revistas' or tipoLugar = 'Libros')
					AND año BETWEEN @anio1 AND @anio2
)
RETURN @cantidad
END

declare @cantTrabInvs int;
set @cantTrabInvs = dbo.fn_CantTrbjAniosClave(2015, 2016, 'Popoi')
PRINT @cantTrabInvs


go
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*
4.f Crear una función que reciba un tipo de trabajo y devuelva un nuevo identificador para dicho trabajo. */
CREATE FUNCTION fn_NuevoIdentTipoTrabajo(
@elTipoTrabajo varchar(50)
)
RETURNS VARCHAR(150)
AS
BEGIN
	DECLARE @ret VARCHAR(150);
	declare @alphaNumID varchar(10);
	IF(@elTipoTrabajo LIKE 'poster' OR @elTipoTrabajo LIKE 'articulo' OR @elTipoTrabajo LIKE 'capitulo' OR @elTipoTrabajo LIKE 'OTRO')
    BEGIN
		select @alphaNumID = UPPER(SUBSTRING(@elTipoTrabajo, 1, 1));
		declare @ultINS int;
		set @ultINS = (select COUNT(*) from Trabajo where tipoTrab = @elTipoTrabajo);

		set @ret = @alphaNumID + CONVERT(varchar(10), @ultINS);
	END
	ELSE
	BEGIN
		set @ret ='El parametro ingresado no corresponde a un tipo de trabajo valido.';
	END
RETURN @ret
END
GO

declare @nueviTipo varchar(150);
set @nueviTipo = dbo.fn_NuevoIdentTipoTrabajo('poster')
PRINT @nueviTipo
GO


/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*
4.g Crear un procedimiento que dado una universidad devuelva los datos del congreso 
en el cual público su ultimo Articulo, y algún tipo de indicación de si existe o no 
un artículo con esas condiciones. Suponemos que no hay congresos que traten 
los mismos temas y que se solapen en el tiempo. */
CREATE FUNCTION fn_CongresoDeUniArt(
@laUniversidad varchar(100)
)
RETURNS VARCHAR(300)
AS
BEGIN
	declare @nombre VARCHAR(250);
	declare @nivelLugar int;
	declare @diaIni int;
	declare @mes int;
	declare @anio int;
	DECLARE @ret VARCHAR(300);

	SELECT @nombre = l.nombre, @nivelLugar = l.nivelLugar, @diaIni = l.diaIni, @mes = l.mes, @anio = l.año
	FROM Lugares l, Trabajo t
	WHERE l.idLugar = t.lugarPublic
	AND t.idTrab IN (
		SELECT MAX(idTrab)
		FROM Trabajo ta
		WHERE ta.tipoTrab = 'Articulo'
		AND lugarPublic IN(
			SELECT idLugar
			FROM Lugares lg
			WHERE lg.tipoLugar = 'Congresos'
			AND lg.universidad = @laUniversidad
		)
	)
set @ret = @nombre+ ' - Nivel Lugar:'+CONVERT(varchar(1), @nivelLugar)+ ' - Fecha: '+CONVERT(varchar(2), @diaIni)+'/'+CONVERT(varchar(2), @mes)+'/'+CONVERT(varchar(4), @anio)
RETURN @ret
END

declare @uni varchar(300);
set @uni = dbo.fn_CongresoDeUniArt('UCUDAL')
PRINT @uni

go
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*
4.h Crear un procedimiento o función, según considere/corresponda, 
que dado un tipo de trabajo (Articulo, Poster, etc.) 
devuelva la cantidad de investigadores que tengan más de 5 trabajos del tipo indicado,
 y que tengan la maxima cantidad de publicaciones.. */

CREATE FUNCTION fn_CantAutTipoTrab(
@tipoTrabajo varchar(20)
)
RETURNS int
AS
BEGIN
 declare @ret int;
 SELECT @ret = COUNT(DISTINCT idInvestigador)
 FROM TAutores ta
 WHERE ta.idInvestigador IN(
	SELECT inv.idInvestigador
	FROM Investigador inv
	WHERE inv.cantTrabPub IN( 
		SELECT MAX(cantTrabPub)
		FROM Investigador
		)
	)
 AND ta.idInvestigador IN(
	SELECT inv.idInvestigador
	FROM Investigador inv, Trabajo t, TAutores ta
	WHERE inv.idInvestigador = ta.idInvestigador
	AND ta.idTrab = t.idTrab
	AND t.tipoTrab LIKE @tipoTrabajo
	GROUP BY inv.idInvestigador
	HAVING COUNT(*)>5
	)

 RETURN @ret;
END
go

declare @ret int;
set @ret = dbo.fn_CantAutTipoTrab('articulo')
PRINT @ret





/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*                              SE PIDE #5                      		  */
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/


/*
5 - a. Crear un trigger que al insertar un trabajo asegure las restricciones identificadas, 
y en caso de que no se asignó una fecha de inicio el trigger asigne el primero de enero del año actual 
como fecha de inicio del trabajo.
En el caso de considerarse insert de a un trabajo por vez, debe asegurarse de que la operación se haga 
solo en ese caso.
*/

DROP TRIGGER trig_idTrab
go

CREATE TRIGGER tg_RestriccionesTrabajo
ON Trabajo
INSTEAD OF INSERT
AS
BEGIN
	
	IF( NOT EXISTS( Select COUNT(*) From inserted GROUP BY nomTrab having count(*) > 1))
	 BEGIN
		 DECLARE @nomTrab VARCHAR(100);
		 DECLARE @descripTrab VARCHAR(100);
		 DECLARE @tipoTrab VARCHAR(20);
		 DECLARE @fecha date;

		 /*Trigger Trabajo alphanumerico*/
		 declare @ultINS int;
		 set @ultINS = (select COUNT(*) from Trabajo where tipoTrab in (select tipoTrab from inserted));
		 declare @alphaNumID varchar(10);
		 select @alphaNumID = UPPER(SUBSTRING(tipoTrab, 1, 1)) from inserted;
	     set @alphaNumID = @alphaNumID + CONVERT(varchar(10), @ultINS);
		 

		 /* Trigger 5a */
		 select @nomTrab = nomTrab, @descripTrab = descripTrab, @tipoTrab = tipoTrab, @fecha = fechaInicio
	     from inserted

		 IF(@nomTrab is not null AND @tipoTrab is not null)
		 BEGIN
			IF(@tipoTrab like 'poster' OR @tipoTrab like 'articulo' OR @tipoTrab like 'capitulo' OR @tipoTrab like 'otro')
			BEGIN
				if(@fecha is null) Begin set @fecha = '01-01-'+CONVERT(varchar(4),YEAR(GETDATE())); End
				insert into Trabajo
				select nomTrab, descripTrab, tipoTrab, @fecha, linkTrab, lugarPublic, @alphaNumID
				from inserted
			END
			ELSE
			BEGIN
			 PRINT 'Parametros no correctos'
			END
		 END

	 END
END
GO

/*
5b - Crear un trigger que controle que solo puedan eliminarse trabajos no publicados que iniciaron hace
 más de 2 años. Eliminando todos los datos de la base de datos que considere necesarios asociados a dichos trabajos.
Debe considerarse eliminaciones múltiples.
*/

CREATE TRIGGER tg_EliminarTrabajos
ON Trabajo
INSTEAD OF DELETE
AS
BEGIN	

	DELETE FROM Referencias
	WHERE idTrab IN	(
		SELECT x.idTrab
		FROM Trabajo x
		WHERE YEAR(x.fechaInicio) < (YEAR(GETDATE()) - 2)
	)
	AND idTrab IN (
		SELECT y.idTrab
		FROM Trabajo y
		WHERE y.lugarPublic IS NULL
	)
	AND idTrab IN(
		SELECT idTrab
		FROM deleted
	)

	DELETE FROM Referencias
	WHERE idTrabReferenciado IN	(
		SELECT x.idTrab
		FROM Trabajo x
		WHERE YEAR(x.fechaInicio) < (YEAR(GETDATE()) - 2)
	)
	AND idTrabReferenciado IN (
		SELECT y.idTrab
		FROM Trabajo y
		WHERE y.lugarPublic IS NULL
	)
	AND idTrabReferenciado IN(
		SELECT idTrab
		FROM deleted
	)

	DELETE FROM TAutores
	WHERE idTrab IN	(
		SELECT x.idTrab
		FROM Trabajo x
		WHERE YEAR(x.fechaInicio) < (YEAR(GETDATE()) - 2)
	)
	AND idTrab IN (
		SELECT y.idTrab
		FROM Trabajo y
		WHERE y.lugarPublic IS NULL
	)
	AND idTrab IN(
		SELECT idTrab
		FROM deleted
	)

	DELETE FROM TTags
	WHERE idTrab IN	(
		SELECT x.idTrab
		FROM Trabajo x
		WHERE YEAR(x.fechaInicio) < (YEAR(GETDATE()) - 2)
	)
	AND idTrab IN (
		SELECT y.idTrab
		FROM Trabajo y
		WHERE y.lugarPublic IS NULL
	)
	AND idTrab IN(
		SELECT idTrab
		FROM deleted
	)
	
	DELETE FROM Trabajo
	WHERE YEAR(fechaInicio) < (YEAR(GETDATE()) - 2)
	AND lugarPublic IS NULL	
	AND idTrab IN(
		SELECT idTrab
		FROM deleted
	)
END
GO

/*
5c - Crear un trigger que solo permita insertar dos trabajos, uno como referencia del otro, 
si tienen algún tema (palabras claves) en común. */

CREATE TRIGGER tg_InsertarReferencias
ON Referencias
INSTEAD OF INSERT
AS
BEGIN	

	DECLARE @trabajo VARCHAR(10)
		
	SELECT @trabajo = x.idTrab
	FROM inserted x
	WHERE idTrab IN(
		SELECT idTrab
		FROM TTags
		WHERE idTag IN
		(
			SELECT idTag
			FROM TTags
			WHERE idTrab IN(
				SELECT y.idTrabReferenciado
				FROM inserted y
			)
		)
	)

	IF (@trabajo IS NOT NULL)
	BEGIN 
		INSERT INTO Referencias
		SELECT idtrab, idTrabReferenciado
		FROM inserted
	END
	ELSE
	BEGIN
		PRINT 'Los trabajos no tienen temas (palabras clave) en común.'
	END	
END
GO

/* 5d - Crear un trigger que audite las inserciones y las actualizaciones de los lugares que
tienen algún trabajo publicado, registrando en alguna tabla auxiliar el lugar que se
quiere actualizar/insertar, la operación (INS o UPD), el usuario y la fecha hora de la
operación.*/

CREATE TABLE LogInsertAndUpdate (
	lugar INT,
	operacion VARCHAR(3) CHECK (operacion IN ('INS', 'UPD')),
	usuario VARCHAR(50),
	fechaOperacion date
)
GO

ALTER TRIGGER tg_AuditarInsOrUpd
ON Lugares
AFTER INSERT, UPDATE
AS
BEGIN
		DECLARE @lugar INT
		SELECT @lugar = idLugar
		FROM inserted
		
		IF(EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted))
		BEGIN
			INSERT INTO LogInsertAndUpdate
			VALUES (@lugar, 'INS', USER, GETDATE())
		END
		ELSE IF(EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted))
		BEGIN

			IF(EXISTS (
			SELECT * 
			FROM inserted 
			WHERE idLugar IN 
				(
					SELECT lugarPublic
					FROM Trabajo
				)
			)
			)
			BEGIN
					INSERT INTO LogInsertAndUpdate
					VALUES (@lugar, 'UPD', USER, GETDATE())
			END
		END

END

select * from LogInsertAndUpdate
select * from Trabajo

update Lugares set nombre = 'Teatro Solis' where idLugar = 1
INSERT INTO Lugares
VALUES(6, 'Test Log', 1, 2014, 8, 8, null, 'https://www.dazzlerhoteles.com', 'UBA', 'Revistas');



/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*                              SE PIDE #6                      		  */
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/

/*
a. Mostrar, para cada trabajo publicado con mas de 3 autores, 
el identificador del trabajo, nombre del mismo, la cantidad de autores que tiene, 
y lugar donde se publico (id y nombre).
*/

SELECT t.idTrab as 'Identificador del trabajo', t.nomTrab as 'Nombre de Trabajo', Count(distinct ta.idInvestigador) as 'Cantidad de Autores', l.idLugar as 'Id Lugar', l.nombre as 'Nombe del Lugar'
FROM Trabajo t, Lugares l, TAutores ta
WHERE t.lugarPublic = l.idLugar and t.idTrab = ta.idTrab
GROUP BY t.idTrab,t.nomTrab, l.idLugar, l.nombre  
HAVING COUNT(*) > 3

/*
b. Obtener la lista de palabras claves que aparecen en trabajos sobre 'BASE DE DATOS'
(palabra clave) publicados en revistas del año actual. La salida debe aparecer
ordenado alfabéticamente, sin repetidos.	
*/

SELECT DISTINCT t.palabra
FROM TTags tt, Tags t, Trabajo w, Lugares l
WHERE tt.idTag = t.idtag
AND tt.idTrab = w.idTrab
AND w.lugarPublic = l.idLugar
AND l.tipoLugar LIKE 'Revistas'
AND l.año = YEAR(GETDATE())
AND w.idTrab IN(
	SELECT z.idTrab
	FROM TTags z
	WHERE z.idTag IN (
		SELECT y.idtag
		FROM Tags y
		WHERE y.palabra = 'BASE DE DATOS'
	)
)
ORDER BY (t.palabra)

/* c - Mostrar los datos de las universidades y el link a los congresos, 
de las universidades que han realizado más de 2 congresos de nivel 4, 
en los ultimos 5 años, con mas de 20 trabajos publicados en esos congresos. */

SELECT DISTINCT u.nombre, l.link
FROM Universidad u, Lugares l
WHERE u.nombre = l.universidad
AND l.universidad IN (
	SELECT x.universidad
	FROM Lugares x
	WHERE x.tipoLugar LIKE 'Congresos'
	GROUP BY x.universidad
	HAVING COUNT (*) > 20
)
AND l.nivelLugar = 4
AND l.año > YEAR(GETDATE())-5
AND l.tipoLugar LIKE 'Congresos'
GROUP BY u.nombre
HAVING COUNT(*) > 2 

/* d- Obtener para cada investigador el ultimo trabajo 
que inicio en el cual fue/es autor principal.*/

SELECT i.idInvestigador
FROM Investigador i LEFT OUTER JOIN TAutores ta 
ON i.idInvestigador = ta.idInvestigador
LEFT OUTER JOIN Trabajo t 
ON ta.idTrab = t.idTrab
WHERE ta.rolinvestig = 'autor-ppal'
AND t.idTrab IN 
(
	SELECT 	TOP 1 x.idTrab
	FROM Trabajo x, TAutores y
	WHERE x.idTrab = y.idTrab
	AND i.idInvestigador = y.idInvestigador
	ORDER BY fechaInicio DESC
)

/* e - Para cada investigador mostrar, su identificación, 
nombre, nombre de la universidad a la que pertenece, 
y la cantidad de trabajos suyos publicados en lugares de nivel 1, 
de nivel 2, de nivel 3 y de nivel 4, 
en los últimos 5 años, en la carrera de Ingeniería. */


SELECT DISTINCT i.idInvestigador, i.nombre, i.idUniversidad, 
dbo.fn_CantTrabajoPorNivel(1, i.idInvestigador) as 'Cantidad trabajos nivel 1',
dbo.fn_CantTrabajoPorNivel(2, i.idInvestigador) as 'Cantidad trabajos nivel 2',
dbo.fn_CantTrabajoPorNivel(3, i.idInvestigador) as 'Cantidad trabajos nivel 3',
dbo.fn_CantTrabajoPorNivel(4, i.idInvestigador) as 'Cantidad trabajos nivel 4'
FROM Investigador i LEFT OUTER JOIN TAutores ta
ON i.idInvestigador = ta.idInvestigador 
LEFT OUTER JOIN Trabajo t 
ON ta.idTrab = t.idTrab
LEFT OUTER JOIN Lugares l
ON t.lugarPublic = l.idLugar


alter FUNCTION fn_CantTrabajoPorNivel(
@nivelLugar int,
@idInv int
)
RETURNS int
AS
BEGIN
	DECLARE @ret int
	SELECT @ret = COUNT(*)
	FROM Lugares lu, Investigador inv, TAutores x, Trabajo t
	WHERE lu.universidad = inv.idUniversidad
	AND inv.idInvestigador = x.idInvestigador
	AND lu.nivelLugar = @nivelLugar
	AND x.idTrab = t.idTrab
	AND inv.idInvestigador = @idInv
	AND YEAR(t.fechaInicio) > YEAR(GETDATE())-5
	AND inv.carrera LIKE 'Ingeniería'
	RETURN @ret
END

/* f - Para la universidad “ORT” mostrar el identificador de sus investigadores 
que tienen algún trabajo en el año actual y la cantidad de trabajos 
publicados en congresos de nivel 4. 
En caso de investigadores sin trabajos publicados en estos congresos pero con
trabajos en proceso el año actual deben aparecer en el resultado.*/

SELECT i.idInvestigador, (
	SELECT COUNT(*)
	FROM Lugares lu, Investigador inv, TAutores x, Trabajo tra
	WHERE lu.idLugar = tra.lugarPublic
	AND inv.idInvestigador = x.idInvestigador
	AND tra.idTrab = x.idTrab
	AND inv.idInvestigador = i.idInvestigador
	AND lu.nivelLugar = 4  
	AND lu.tipoLugar = 'Congresos'
	AND inv.idUniversidad LIKE 'ORT'
) AS 'Cant. de Trabajos en ORT para Nivel 4'
FROM Investigador i LEFT OUTER JOIN TAutores ta
ON i.idInvestigador = ta.idInvestigador
LEFT OUTER JOIN Trabajo t
ON ta.idTrab = t.idTrab
WHERE i.idUniversidad LIKE 'ORT'
AND YEAR(t.fechaInicio) = YEAR(GETDATE())

/* g - Mostrar para cada universidad que tiene trabajos publicados, 
los datos del último trabajo publicado. 
Solucionar usando la función a).*/

SELECT DISTINCT U.nombre , dbo.fn_UltimoTrabajoPorUniv(l.universidad) AS 'Datos de Trabajo publicado'
FROM Trabajo t, Lugares l, Universidad u
WHERE t.lugarPublic = l.idLugar
AND U.nombre = L.universidad

/* h- Eliminar las palabras claves no usadas en los trabajos.*/

DELETE FROM Tags
WHERE idTag NOT IN
(
	SELECT idtag
	FROM TTags
)
GO

/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*                              SE PIDE #7                       		  */
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/

/* a- Realizar una vista que muestre lista de Congresos y 
para cada uno la cantidad de trabajos publicados que no tienen autores que 
sean investigadores de la universidad anfitriona del congreso.
*/

create VIEW View_ListaCongresos
AS
SELECT lu.nombre 'Congreso', COUNT(DISTINCT tra.idTrab) AS 'Cantidad de trabajos'
FROM Lugares lu, Investigador inv, TAutores x, Trabajo tra
WHERE lu.idLugar = tra.lugarPublic
AND inv.idInvestigador = x.idInvestigador
AND tra.idTrab = x.idTrab
AND lu.tipoLugar LIKE 'Congresos'
AND tra.idTrab NOT IN (
	SELECT t.idTrab
	FROM Investigador i, Trabajo t, TAutores ta, Lugares l
	WHERE t.idTrab = ta.idTrab
	AND i.idInvestigador = ta.idInvestigador
	AND i.idUniversidad = lu.Universidad
)
GROUP BY lu.nombre

select * from View_ListaCongresos


/* b- Realizar una vista que muestre para cada Investigador, 
para cada tipo de trabajo la fecha de inicio del primer y último trabajo. 
Todas los investigadores deben aparecer en el resultado, 
aunque no tengan trabajos que cumplan las condiciones.
*/

select * from TAutores
select * from Investigador
select * from Trabajo

SELECT i.idInvestigador Investigador, t.tipoTrab 'Tipo de trabajo', MIN(t.fechaInicio), MAX(t.fechaInicio) 
FROM Investigador i LEFT OUTER JOIN TAutores ta
ON i.idInvestigador = ta.idInvestigador
LEFT OUTER JOIN Trabajo t
ON ta.idTrab = t.idTrab 
GROUP BY i.idInvestigador, t.tipoTrab

go

/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*             SE PIDE #3   -     DATOS A RECHAZAR						  */
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/* 3. Ingreso de un juego completo de datos de prueba (será más valorada la calidad de los datos
más que la cantidad. El mismo debería incluir ejemplos que deban ser rechazados por no
cumplir con las restricciones implementadas.*/


/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*							TABLA UNIVERSIDAD								 */
/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* Caso a ser rechazado por contener PK duplicada*/
INSERT INTO Universidad
VALUES ('Udelar', 'Argentina', 'Buenos Aires', '44114444')

/* Caso a ser rechazado por pais = NULL*/
INSERT INTO Universidad
VALUES ('Nueva Universidad', NULL, 'Buenos Aires', '44554455')

/* Caso a ser rechazado por ciudad = NULL*/
INSERT INTO Universidad
VALUES ('Universidad del Nuevo Mundo', 'Uruguay', NULL, '55445544')

/* Caso a ser rechazado por telefono = NULL*/
INSERT INTO Universidad (nombre, pais, ciudad)
VALUES ('Universidad Cornell', 'Uruguay', 'Montevideo')


/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*								TABLA LUGARES								*/
/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* Caso a ser rechazado por idLugar duplicado */
INSERT INTO Lugares
VALUES(1, 'Hotel Guadalajara', 4, 2017, 11, 8, null, '', 'Udelar', 'Revistas')

/* Caso a ser rechazado por nombre = null */
INSERT INTO Lugares (idLugar, nombre, nivelLugar, año, mes, diaIni, diaFin, link, universidad, tipoLugar)
VALUES(6, null, 4, 2017, 11, 8, null, '', 'Udelar', 'Revistas')

/* Caso a ser rechazado por nivel > 4 */
INSERT INTO Lugares
VALUES(6, 'Hotel Guadalajara', 8, 2017, 11, 8, null, '', 'Udelar', 'Revistas')

/* Caso a ser rechazado por año > año actual */
INSERT INTO Lugares
VALUES(6, 'Hotel Guadalajara', 4, 2300, 11, 8, null, '', 'Udelar', 'Revistas')

/* Caso a ser rechazado por mes > 12 */
INSERT INTO Lugares
VALUES(6, 'Hotel Guadalajara', 4, 2015, 98, 8, null, '', 'Udelar', 'Revistas')

/* Caso a ser rechazado por mes < 1 */
INSERT INTO Lugares
VALUES(6, 'Hotel Guadalajara', 4, 2015, 0, 8, null, '', 'Udelar', 'Revistas')

/* Caso a ser rechazado por dia > 31 */
INSERT INTO Lugares
VALUES(6, 'Hotel Guadalajara', 4, 2015, 11, 50, null, '', 'Udelar', 'Revistas')

/* Caso a ser rechazado por tipoLugar no entre los permtidos */
INSERT INTO Lugares
VALUES(6, 'Hotel Guadalajara', 4, 2015, 11, 20, null, '', 'Udelar', 'Verduleria')

/* Caso a ser rechazado por nombre repetido */
INSERT INTO Lugares
VALUES(6, 'Hotel Dazzler', 4, 2015, 11, 20, null, '', 'Udelar', 'Revistas')

/* Caso a ser rechazado por universidad = null */
INSERT INTO Lugares (idLugar, nombre, nivelLugar, año, mes, diaIni, diaFin, link, universidad, tipoLugar)
VALUES(6, 'Hotel Guadalajara', 4, 2016, 11, 8, null, '', null, 'Revistas')


/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*							TABLA INVESTIGADOR								*/
/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*Datos a rechazar*/
/* Caso a ser rechazado por ingresar idInvestigador */
INSERT INTO Investigador (idInvestigador,nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES (365,'Marcio Avellanal', 'mavellanal@investigadores.com.uy', '45129685', 'Licenciatura en Matemáticas', 'EDoctor', 5,'Universidad Federal de Alagoas')

/* Caso a ser rechazado por ingresar Universidad inexistente */
INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('Marcio Avellanal', 'mavellanal@investigadores.com.uy', '45129685', 'Licenciatura en Matemáticas', 'EDoctor', 5,'Universidad de Michigan')

/* Caso a ser rechazado por no ingresar nombre*/
INSERT INTO Investigador (mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('mavellanal@investigadores.com.uy', '45129685', 'Licenciatura en Matemáticas', 'EDoctor', 5,'Universidad de Michigan')

/* Caso a ser rechazado por no ingresar nivelInvestig*/
INSERT INTO Investigador (nombre, mail, telefono, carrera,cantTrabPub,idUniversidad)
VALUES ('Marcio Avellanal', 'mavellanal@investigadores.com.uy', '45129685', 'Licenciatura en Matemáticas', 5,'Universidad de Michigan')

/* Caso a ser rechazado por no ingresar cantTrabPub*/
INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,idUniversidad)
VALUES ('Marcio Avellanal', 'mavellanal@investigadores.com.uy', '45129685', 'Licenciatura en Matemáticas', 'EDoctor','Universidad de Michigan')

/* Caso a ser rechazado por no ingresar mail unico*/
INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('Marcio Avellanal', 'mavellanal@investigadores.com.uy', '98765432', 'Dcotor en Medicina', 'EDoctor', 4,'Udelar')

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                              Tabla TRABAJO                               */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*Datos a rechazar*/
/* Caso a ser rechazado por Descripcion > 200 Caracteres */
/*
INSERT INTO Trabajo
VALUES('Investigacion de como hacer las cosas mal', 'Nor hence hoped her after other known defer his. For county now sister engage had season better had waited. Occasional mrs interested far expression acceptance. Day either mrs talent pulled men rather 201', 'articulo', '2016-04-03', null,1,'P3')
*/

/* Caso a ser rechazado por tipoTrab no permitido */
INSERT INTO Trabajo
VALUES('Investigacion sobre el mal hacer', 'Investigacion sobre cuando las cosas se macen hal', 'resumen', '2016-04-03', 'https://www.google.com.uy',1,'P4')

/* Caso a ser rechazado por Lugar = null */
INSERT INTO Trabajo
VALUES('Investigacion sobre el lugar nulo', 'Investigacion sobre la nulinidad del lugar', 'articulo', '2016-04-03', 'https://www.google.com.uy',null,'A4')

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                              Tabla TAGS                                  */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*Datos a rechazar*/
/* Caso a ser rechazado por identificador par */
INSERT INTO Tags(idtag, palabra)
VALUES (2,'ruinas')

/* Caso a ser rechazado por palabra NULL */
INSERT INTO Tags(palabra)
VALUES (NULL)

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                              Tabla TTAGS                                 */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*Datos a rechazar*/
/*Caso a ser rechazado por PK duplicado*/
INSERT INTO TTags
VALUES ('O2',27)

/*Caso a ser rechazado por IdTag inexistente*/
INSERT INTO TTags
VALUES ('O2',28)

/*Caso a ser rechazado por IdTrab inexistente*/
INSERT INTO TTags
VALUES ('Z15',27)

/*Caso a ser rechazado por IdTrab null*/
INSERT INTO TTags(idTag)
VALUES (27)


/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                           Tabla TAUTORES                                 */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*Datos a rechazar*/
/*Caso a ser rechazado por PK duplicada*/
INSERT INTO TAutores
VALUES('A2',8,'autor-sec')

/*Caso a ser rechazado por IdTrab null*/
INSERT INTO TAutores(idInvestigador,rolinvestig)
VALUES(8,'autor-director')

/*Caso a ser rechazado por IdInvestigador null*/
INSERT INTO TAutores(idTrab,rolinvestig)
VALUES('A1','autor-director')

/*Caso a ser rechazado por rol fuera de rango*/
INSERT INTO TAutores(idTrab,idInvestigador,rolinvestig)
VALUES('A1',7,'editor')

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                      Tabla REFERENCIAS                                  */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*Datos a rechazar*/
/* Caso a ser rechazado por: idTrab = null */
INSERT INTO Referencias
VALUES(null,'A1')

/* Caso a ser rechazado por: idTrabReferenciado = null */
INSERT INTO Referencias
VALUES('O2',null)
GO
/* Caso a ser rechazado por: se referencia asimismo  */
/* REGULAR CON TRIGGER
INSERT INTO Referencias
VALUES('O2','O2')
*/