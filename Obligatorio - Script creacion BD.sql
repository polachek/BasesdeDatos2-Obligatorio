/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/

/*########################################################################*/
/*                       CREACIÓN DE TABLAS								  */
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
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/
/*########################################################################*/

/*########################################################################*/
/*              ALTERACIONES PARA AGREGAR RESTRICCIONES      			  */
/*########################################################################*/

/* UNIVERSIDAD */
ALTER TABLE Universidad
DROP nombre 

ALTER TABLE Universidad
ADD nombre VARCHAR(100) PRIMARY KEY 

/*########################################################################*/

/* INVESTIGADOR */
ALTER TABLE Investigador
DROP COLUMN idInvestigador

ALTER TABLE Investigador
ADD idInvestigador INT NOT NULL IDENTITY(1,1)

ALTER TABLE Investigador
ADD idUniversidad VARCHAR(100) NOT NULL

ALTER TABLE Investigador
ADD CONSTRAINT Investigador_PK PRIMARY KEY (idInvestigador)

ALTER TABLE Investigador
ADD CONSTRAINT Investigador_FK FOREIGN KEY (idUniversidad)
REFERENCES Universidad

ALTER TABLE Investigador
ADD CONSTRAINT NivelInv_CH CHECK (nivelInvestig IN ('EGrado', 'EMaestria', 'EDoctorado', 'Doctor'))

ALTER TABLE Investigador
ADD UNIQUE (Mail)

ALTER TABLE Investigador
ALTER COLUMN cantTrabPub INT NOT NULL

/*########################################################################*/

/* TRABAJO */
ALTER TABLE Trabajo
ADD CONSTRAINT Trabajo_PK PRIMARY KEY (idTrab)

ALTER TABLE Trabajo
ADD CONSTRAINT Trabajo_FK FOREIGN KEY (lugarPublic)
REFERENCES Lugares

/*########################################################################*/

/* TAGS */
ALTER TABLE Tags
ALTER COLUMN idTag INT NOT NULL

ALTER TABLE Tags
ADD CONSTRAINT Tags_PK PRIMARY KEY (idTag)

/*########################################################################*/

/* TTAGS */
ALTER TABLE TTags
ALTER COLUMN idTrab INT NOT NULL

ALTER TABLE TTags
ALTER COLUMN idTag INT NOT NULL

ALTER TABLE TTAGS 
ALTER COLUMN idTrab INT;

ALTER TABLE TTags
ADD CONSTRAINT TTags_PK PRIMARY KEY (idTrab, idTag)

ALTER TABLE TTags
ADD CONSTRAINT TTags_FK1 FOREIGN KEY (idTrab)
REFERENCES Trabajo

ALTER TABLE TTags
ADD CONSTRAINT TTags_FK2 FOREIGN KEY (idTag)
REFERENCES Tags

/*########################################################################*/

/* TAUTORES */
ALTER TABLE TAutores
ALTER COLUMN idTrab INT NOT NULL

ALTER TABLE TAutores
ADD CONSTRAINT TAutores_PK PRIMARY KEY (idTrab, idInvestigador)

ALTER TABLE TAutores
ADD CONSTRAINT TAutores_FK1 FOREIGN KEY (idTrab)
REFERENCES Trabajo

ALTER TABLE TAutores
ADD CONSTRAINT TAutores_FK2 FOREIGN KEY (idInvestigador)
REFERENCES Trabajo

/*########################################################################*/

/* REFERENCIAS */
ALTER TABLE Referencias
ALTER COLUMN idTrab INT NOT NULL

ALTER TABLE Referencias
ADD CONSTRAINT Referencias_PK PRIMARY KEY (idTrab, idTrabReferenciado)

ALTER TABLE Referencias
ADD CONSTRAINT Referencias_FK FOREIGN KEY (idTrab)
REFERENCES Trabajo

/*########################################################################*/

/* LUGARES */
ALTER TABLE Lugares
ALTER COLUMN universidad VARCHAR(100)

ALTER TABLE Lugares
ADD CONSTRAINT Lugares_FK FOREIGN KEY (universidad)
REFERENCES Universidad
