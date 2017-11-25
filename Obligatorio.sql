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
go

ALTER TABLE Universidad
 add Constraint pk_nombre Primary key(nombre)

 ALTER TABLE Universidad Add telefono varchar(20) not null;



/*-------------------------------------------------------------------------*/

/* INVESTIGADOR */
ALTER TABLE Investigador
DROP COLUMN idInvestigador

ALTER TABLE Investigador
ADD idInvestigador INT NOT NULL IDENTITY(1,1)


ALTER TABLE Investigador
ADD idUniversidad VARCHAR(100) NOT NULL
go

ALTER TABLE Investigador
ADD CONSTRAINT Investigador_PK PRIMARY KEY (idInvestigador)

ALTER TABLE Investigador
ADD CONSTRAINT Investigador_FK FOREIGN KEY (idUniversidad)
REFERENCES Universidad

ALTER TABLE Investigador
ADD CONSTRAINT NivelInv_CH CHECK (nivelInvestig IN ('EGrado', 'EMaestria', 'EDoctor', 'Doctor'))

ALTER TABLE Investigador
ADD UNIQUE (Mail)

ALTER TABLE Investigador
ALTER COLUMN cantTrabPub INT NOT NULL

/*-------------------------------------------------------------------------*/

/* TRABAJO */
ALTER TABLE Trabajo
DROP COLUMN idTrab
go

ALTER TABLE Trabajo
ADD idTrab varchar(10) not null;
go

ALTER TABLE Trabajo
ALTER COLUMN descripTrab VARCHAR(200)
go

ALTER TABLE Trabajo
ADD CONSTRAINT tipoTrab_check CHECK (tipoTrab IN ('poster', 'articulo', 'capitulo', 'otro'))

/*

=> IMPLEMENTAR TRIGGER

ALTER TABLE Trabajo
ADD CONSTRAINT idTrab_check CHECK (idTrab like '[PACO][1-9]+')
*/
ALTER TABLE Trabajo
ADD CONSTRAINT Trabajo_PK PRIMARY KEY (idTrab)

ALTER TABLE Trabajo
ADD CONSTRAINT Trabajo_FK FOREIGN KEY (lugarPublic)
REFERENCES Lugares

/*-------------------------------------------------------------------------*/

/* TAGS */
ALTER TABLE Tags
ALTER COLUMN idTag INT NOT NULL
go


ALTER TABLE Tags
ADD CONSTRAINT Tags_PK PRIMARY KEY (idTag)

/*-------------------------------------------------------------------------*/

/* TTAGS */
ALTER TABLE TTags
ADD CONSTRAINT TTags_PK PRIMARY KEY (idTrab, idTag)

ALTER TABLE TTags
ADD CONSTRAINT TTags_FK1 FOREIGN KEY (idTrab)
REFERENCES Trabajo

ALTER TABLE TTags
ADD CONSTRAINT TTags_FK2 FOREIGN KEY (idTag)
REFERENCES Tags

/*-------------------------------------------------------------------------*/

/* TAUTORES */
ALTER TABLE TAutores
ADD CONSTRAINT TAutores_PK PRIMARY KEY (idTrab, idInvestigador)

ALTER TABLE TAutores
ADD CONSTRAINT TAutores_FK1 FOREIGN KEY (idTrab)
REFERENCES Trabajo

ALTER TABLE TAutores
ADD CONSTRAINT TAutores_FK2 FOREIGN KEY (idInvestigador)
REFERENCES Investigador

ALTER TABLE TAutores
ALTER COLUMN rolinvestig varchar(20);
go

ALTER TABLE TAutores
ADD CONSTRAINT rolinvestig_check CHECK (rolinvestig IN ('autor-ppal', 'autor-sec', 'autor-director'))





/*-------------------------------------------------------------------------*/

/* REFERENCIAS */
ALTER TABLE Referencias
ADD CONSTRAINT Referencias_PK PRIMARY KEY (idTrab, idTrabReferenciado)

ALTER TABLE Referencias
ADD CONSTRAINT Referencias_FK_Trab FOREIGN KEY (idTrab)
REFERENCES Trabajo

ALTER TABLE Referencias
ADD CONSTRAINT Referencias_FK_TrabRef FOREIGN KEY (idTrabReferenciado)
REFERENCES Trabajo

/*-------------------------------------------------------------------------*/

/* LUGARES */
ALTER TABLE Lugares
ALTER COLUMN nombre varchar(250) not null;

ALTER TABLE Lugares
ADD CONSTRAINT nombre_uniq unique (nombre);

ALTER TABLE Lugares
ADD tipoLugar varchar(10) not null;
go

ALTER TABLE Lugares
ADD CONSTRAINT tipoLugar_check CHECK (tipoLugar IN ('Congresos', 'Revistas', 'Libros'))

ALTER TABLE Lugares
ADD CONSTRAINT nivelLugar_check CHECK (nivelLugar BETWEEN 1 and 4);

ALTER TABLE Lugares
ALTER COLUMN universidad VARCHAR(100) NOT NULL

ALTER TABLE Lugares
ADD CONSTRAINT Lugares_FK FOREIGN KEY (universidad)
REFERENCES Universidad

ALTER TABLE Lugares
ADD CONSTRAINT mes_check CHECK (mes BETWEEN 1 and 12)

ALTER TABLE Lugares
ADD CONSTRAINT diaI_check CHECK (diaIni BETWEEN 1 and 31)

ALTER TABLE Lugares
ADD CONSTRAINT diaF_check CHECK (diaFin BETWEEN 1 and 31)

ALTER TABLE Lugares
ADD CONSTRAINT año_check CHECK (año BETWEEN 1900 and YEAR( GETDATE()));
GO




create trigger trig_idTrab
on Trabajo
instead of insert
as
begin

  declare @ultINS int;
  set @ultINS = (select COUNT(*) from Trabajo where tipoTrab in (select tipoTrab from inserted));

  declare @alphaNumID varchar(10);
  select @alphaNumID = UPPER(SUBSTRING(tipoTrab, 1, 1)) from inserted;

  set @alphaNumID = @alphaNumID + CONVERT(varchar(10), @ultINS);

  insert into Trabajo
  select nomTrab, descripTrab, tipoTrab, fechaInicio, linkTrab, lugarPublic, @alphaNumID
  from inserted
end
go


/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*                              SE PIDE #2                      		  */
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/* 2. Creación de índices que considere puedan ser útiles para optimizar las consultas
 (según criterio establecido en el curso)*/

/* CREATE INDEX <nombre-índice>ON <nombre-tabla>(columna1 [, columna2, ...]) */
CREATE INDEX i_investigador_uni ON Investigador(idUniversidad);
CREATE INDEX i_lugares_uni ON Lugares(universidad);
CREATE INDEX i_autores_investigador ON TAutores(idInvestigador);
CREATE INDEX i_trabajo_lugar ON Trabajo(lugarPublic);
CREATE INDEX i_ttags_tags ON TTags(idTag);






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
VALUES ('Udelar', 'Uruguay', 'Montevideo', '29009999')

INSERT INTO Universidad
VALUES ('ORT', 'Uruguay', 'Montevideo', '27007777')

INSERT INTO Universidad
VALUES ('UCUDAL', 'Uruguay', 'Montevideo', '24004444')

INSERT INTO Universidad
VALUES ('UM', 'Uruguay', 'Montevideo', '26006666')

INSERT INTO Universidad
VALUES ('Universidad de Palermo', 'Argentina', 'Buenos Aires', '44116666')

INSERT INTO Universidad
VALUES ('UBA', 'Argentina', 'Buenos Aires', '44110000')

INSERT INTO Universidad
VALUES ('Universidad de Córdoba', 'Argentina', 'Córdoba', '45000000')

INSERT INTO Universidad
VALUES ('Universidad de Brasilia', 'Brasil', 'Brasilia', '62501253')

INSERT INTO Universidad
VALUES ('Universidad Federal de Alagoas', 'Brasil', 'Alagoas', '78514569')

INSERT INTO Universidad
VALUES ('Universidad de Amazonas', 'Brasil', 'Amazonas', '35358978')

/*Datos a rechazar*/
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

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                           Tabla LUGARES                                  */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* Datos OK */
INSERT INTO Lugares
VALUES(1, 'Teatro Solis', 4, 2016, 11, 8, null, 'http://www.teatrosolis.org.uy', 'Udelar', 'Revistas')

INSERT INTO Lugares
VALUES(2, 'LATU', 3, 2015, 11, 9, 13, 'www.latu.org.uy', 'ORT', 'Congresos')

INSERT INTO Lugares
VALUES(3, 'Radisson Victoria Plaza Hotel', 4, 2015, 5, 20, null, 'https://www.radissonblu.com', 'UM', 'Libros')

INSERT INTO Lugares
VALUES(4, 'Holiday Inn', 2, 2017, 2, 10, 16, 'https://www.ihg.com', 'UCUDAL', 'Congresos')

INSERT INTO Lugares
VALUES(5, 'Hotel Dazzler', 1, 2014, 8, 8, null, 'https://www.dazzlerhoteles.com', 'UBA', 'Revistas')


/*Datos a rechazar*/
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
GO


/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                           Tabla INVESTIGADOR                             */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*Datos OK*/
INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('Marcelo López', 'mlopez@investigadores.com.uy', '098999999', 'Ingeniería Química', 'EGrado', 5,'Udelar')

INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('Laura Marquisio', 'lmarqui@investigadores.com.uy', '098111111', 'Licenciatura en Relaciones Internacionales', 'EMaestria', 1,'UM')

INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('Fabián Méndez', 'fmendez@investigadores.com.uy', '095951135', 'Licenciatura en Economía', 'EMaestria', 3,'Udelar')

INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('Silvia Luque', 'sluque@investigadores.com.uy', '096457215', 'Licenciatura en Economía', 'EDoctor', 9,'Udelar')

INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('Silvio Duarte', 'sduarte@investigadores.com.uy', '099485245', 'Licenciatura en Sistemas', 'Doctor', 15,'Udelar')

INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('Walter Clitish', 'wclitish@investigadores.com.uy', '099123456', 'Licenciatura en Letras', 'EDoctor', 12,'Udelar')

INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('Maicol Uriarte', 'muriarte@investigadores.com.uy', '15648524', 'Licenciatura en Bellas Artes', 'EMaestria', 9,'UBA')

INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('Marianela Ifrán', 'mifran@investigadores.com.uy', '15677425', 'Ingeniería Naval', 'EGrado', 1,'Universidad de Córdoba')

INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('Linda Cibils', 'lcibils@investigadores.com.uy', '48579568', 'Licenciatura en Ciencias Biológicas', 'EDoctor', 5,'Universidad de Amazonas')

INSERT INTO Investigador (nombre, mail, telefono, carrera, nivelInvestig,cantTrabPub,idUniversidad)
VALUES ('Marcio Avellanal', 'mavellanal@investigadores.com.uy', '45129685', 'Licenciatura en Matemáticas', 'EDoctor', 5,'Universidad Federal de Alagoas')


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
Select * from trabajo


/* Datos OK */
INSERT INTO Trabajo
VALUES('Investigacion GARZA CUCA', 'La garza cuca o también denominada garza mora (Ardea cocoi) es un ave nativa del Centro y Sudamérica, se estudia su ambiente y entorno', 'articulo', '2016-04-03', 'https://www.infoanimales.com/informacion-sobre-la-garza-cuca',1,'P1')

INSERT INTO Trabajo
VALUES('Venado de campo', 'Investigacion sobre el venado de campo, uno de los integrantes más característicos de la fauna uruguaya', 'capitulo', '2017-02-01', 'http://blogs.ceibal.edu.uy/formacion/colecciones-de-recursos/venado-de-campo/',2,'A1')

INSERT INTO Trabajo
VALUES('Investigacion sobre el Agua', 'El agua es un bien y un recurso cada vez mas escaso, que debe ser valorado, protegido y recuperado', 'poster', '2017-05-17', 'https://es.slideshare.net/sssanchezayelen/investigacin-sobre-el-agua',3,'P2')

INSERT INTO Trabajo
VALUES('Investigacion sobre las drogas', 'La drogadicción es una enfermedad que consiste en la dependencia de sustancias que afectan el sistema nervioso central y las funciones cerebrales', 'articulo', '2017-05-17', 'https://www.monografias.com/docs/Investigacion-sobre-las-drogas-FKJQBHKYMZ',4,'A2')

INSERT INTO Trabajo
VALUES('Investigacion sobre medio ambiente ', 'El análisis de lo ambiental desde la perspectiva de lo social', 'Otro', '2017-08-20', 'http://cis.ufro.cl/index.php?option=com_content&view=article&id=45&Itemid=34',5,'O1')

INSERT INTO Trabajo
VALUES('Investigacion sobre Cultura maya ', 'La civilización maya es sin duda la más fascinante de las antiguas culturas americanas', 'Otro,', '2017-04-28', 'https://www.biografiasyvidas.com/historia/cultura_maya.htm',6,'O2')

/*Datos a rechazar*/
/* Caso a ser rechazado por Descripcion > 200 Caracteres */
INSERT INTO Trabajo
VALUES('Investigacion de como hacer las cosas mal', 'Nor hence hoped her after other known defer his. For county now sister engage had season better had waited. Occasional mrs interested far expression acceptance. Day either mrs talent pulled men rather 201', 'articulo', '2016-04-03', null,1,'P3')

/* Caso a ser rechazado por tipoTrab no permitido */
INSERT INTO Trabajo
VALUES('Investigacion sobre el mal hacer', 'Investigacion sobre cuando las cosas se macen hal', 'propaganda', '2016-04-03', 'https://www.google.com.uy',1,'P4')

/* Caso a ser rechazado por Lugar = null */
INSERT INTO Trabajo
VALUES('Investigacion sobre el lugar nulo', 'Investigacion sobre la nulinidad del lugar', 'articulo', '2016-04-03', 'https://www.google.com.uy',null,'A4')

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                              Tabla TAGS                                  */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*Datos OK*/
INSERT INTO Tags(palabra)
VALUES ('garza')

INSERT INTO Tags(palabra)
VALUES ('cuca')

INSERT INTO Tags(palabra)
VALUES ('venado')

INSERT INTO Tags(palabra)
VALUES ('campo')

INSERT INTO Tags(palabra)
VALUES ('fauna')

INSERT INTO Tags(palabra)
VALUES ('animales')

INSERT INTO Tags(palabra)
VALUES ('silvestre')

INSERT INTO Tags(palabra)
VALUES ('agua')

INSERT INTO Tags(palabra)
VALUES ('ambiente')

INSERT INTO Tags(palabra)
VALUES ('ecología')

INSERT INTO Tags(palabra)
VALUES ('drogas')

INSERT INTO Tags(palabra)
VALUES ('adicciones')

INSERT INTO Tags(palabra)
VALUES ('cultura')

INSERT INTO Tags(palabra)
VALUES ('mayas')

/*Datos a rechazar*/
/* Caso a ser rechazado por identificador par */
INSERT INTO Tags(idtag, palabra)
VALUES (2,'ruinas')

/* Caso a ser rechazado por palabra NULL */
INSERT INTO Tags(palabra)
VALUES (NULL)

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*                              Tabla TTAGS                                  */
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/*Datos OK*/
INSERT INTO TTags
VALUES ('P1',1)

INSERT INTO TTags
VALUES ('P1',3)

INSERT INTO TTags
VALUES ('A1',5)

INSERT INTO TTags
VALUES ('A1',7)

INSERT INTO TTags
VALUES ('A1',9)

INSERT INTO TTags
VALUES ('P2',15)

INSERT INTO TTags
VALUES ('P2',17)

INSERT INTO TTags
VALUES ('P2',19)

INSERT INTO TTags
VALUES ('A2',21)

INSERT INTO TTags
VALUES ('A2',23)

INSERT INTO TTags
VALUES ('O1',17)

INSERT INTO TTags
VALUES ('O2',25)

INSERT INTO TTags
VALUES ('O2',27)

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

INSERT INTO TAutores
VALUES('P1',1,'autor-ppal')

INSERT INTO TAutores
VALUES('P1',5,'autor-sec')

INSERT INTO TAutores
VALUES('P2',2,'autor-director')

INSERT INTO TAutores
VALUES('01',2,'autor-ppal')

INSERT INTO TAutores
VALUES('02',3,'autor-director')

INSERT INTO TAutores
VALUES('A1',4,'autor-ppal')

INSERT INTO TAutores
VALUES('A2',6,'autor-ppal')

INSERT INTO TAutores
VALUES('A2',9,'autor-sec')

INSERT INTO TAutores
VALUES('A2',9,'autor-sec')

INSERT INTO TAutores
VALUES('A2',8,'autor-director')

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
/* Datos OK */
INSERT INTO Referencias
VALUES('P2','O1')

INSERT INTO Referencias
VALUES('P1','A1')

/*Datos a rechazar*/
/* Caso a ser rechazado por: idTrab = null */
INSERT INTO Referencias
VALUES(null,'A1')

/* Caso a ser rechazado por: idTrabReferenciado = null */
INSERT INTO Referencias
VALUES('O2',null)

/* Caso a ser rechazado por: se referencia asimismo  */
/* REGULAR CON TRIGGER
INSERT INTO Referencias
VALUES('O2','O2')
*/


/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*                              SE PIDE #4                      		  */
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/

/* 4b - Crear una función almacenada que reciba como parámetro un trabajo 
y devuelva la cantidad de referencias externas que tiene.*/
/*
CREATE FUNCTION fn_CantReferenciasExt
(
	@unTrabajo VARCHAR(100)
)
RETURNS INT
AS
BEGIN
	DECLARE @cantReferencias INT
	IF(EXISTS (	SELECT * FROM Referencias r WHERE r.idTrab = @unTrabajo))
	BEGIN
		SELECT @cantReferencias = COUNT(*)
		FROM Referencias r, TAutores a
		WHERE r.idTrab = @unTrabajo 
		AND r.idTrab = a.idTrab
		AND r.idTrabReferenciado = a.idTrab
		AND a.idInvestigador NOT IN 
		(
			SELECT idInvestigador
			FROM TAutores
			WHERE a.idTrab = r.idTrab
		)
		 
	END
RETURN @cantReferencias
END
GO
*/
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* 4c - Crear una función que reciba dos investigadores y devuelva 
la cantidad de trabajos publicados en los cuales ambos investigadores fueron autores 
y alguno de los dos o los dos fueron autores principales.*/
/*
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
	FROM TAutores x, TAutores y
	WHERE x.idTrab IN 
	(
		SELECT idTrab
		FROM TAutores
		WHERE idInvestigador = @investigadorA
	) 
	AND x.idTrab IN
	(
		SELECT idTrab
		FROM TAutores
		WHERE idInvestigador = @investigadorB	
	)
	AND 
	(
		EXISTS
		(
			SELECT *
			FROM TAutores
			WHERE idInvestigador = @investigadorA
			AND x.idTrab = y.idTrab
			AND y.rolinvestig LIKE 'autor-ppal' 
		)
		OR EXISTS
		(
			SELECT *
			FROM TAutores
			WHERE idInvestigador = @investigadorB
			AND x.idTrab = y.idTrab
			AND y.rolinvestig LIKE 'autor-ppal'
		)
	)

RETURN @cantTrabajos
END
GO
*/
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* 4d - Crear una función o procedimiento, según considere/corresponda, 
que dado un investigador actualice el campo cantidad de trabajos publicados 
registrados de la tabla Investigador, y devuelva una indicación de si la cantidad 
que estaba registrada (antes de la actualización) era correcta o no.*/
/*
CREATE PROCEDURE spu_UpdateCantTrab
@unInvestigador INT,
@mensaje VARCHAR(50) output
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

*/

