-- ======================================
-- REINICIALIZACIÓN COMPLETA DE LA BASE
-- ======================================

DROP DATABASE IF EXISTS olimpiadas;
CREATE DATABASE olimpiadas;
USE olimpiadas;

SET FOREIGN_KEY_CHECKS = 0;

-- Eliminación de tablas en orden seguro
DROP TABLE IF EXISTS EVENTO;
DROP TABLE IF EXISTS MEDALLA;
DROP TABLE IF EXISTS PSICOLOGO;
DROP TABLE IF EXISTS ENTRENADOR;
DROP TABLE IF EXISTS FISIOTERAPEUTA;
DROP TABLE IF EXISTS CUERPO_TECNICO;
DROP TABLE IF EXISTS EQUIPO;
DROP TABLE IF EXISTS ATLETA;
DROP TABLE IF EXISTS PARTICIPANTE;
DROP TABLE IF EXISTS DISCIPLINA;
DROP TABLE IF EXISTS DEPORTE;
DROP TABLE IF EXISTS SEDE;
DROP TABLE IF EXISTS PAIS;

SET FOREIGN_KEY_CHECKS = 1;

-- ======================================
-- CREACIÓN DE TABLAS
-- ======================================

CREATE TABLE PAIS(
  cod_iso VARCHAR(3) PRIMARY KEY,
  nombre VARCHAR(50)
);

CREATE TABLE SEDE(
  id_sede INT PRIMARY KEY,
  nombre VARCHAR(50),
  ciudad VARCHAR(50),
  aforo INT,
  cod_iso VARCHAR(3),
  anho INT,
  FOREIGN KEY (cod_iso) REFERENCES PAIS(cod_iso)
);

CREATE TABLE DEPORTE(
  id_deporte INT PRIMARY KEY,
  nombre VARCHAR(50)
);

CREATE TABLE DISCIPLINA(
  id_deporte INT,
  id_disciplina INT,
  nombre VARCHAR(50),
  categoria CHAR(1),
  PRIMARY KEY(id_deporte, id_disciplina),
  FOREIGN KEY(id_deporte) REFERENCES DEPORTE(id_deporte)
);

CREATE TABLE PARTICIPANTE(
  id_participante INT PRIMARY KEY,
  nombre VARCHAR(50),
  tipo VARCHAR(10),
  cod_iso VARCHAR(3),
  FOREIGN KEY(cod_iso) REFERENCES PAIS(cod_iso)
);

CREATE TABLE ATLETA(
  dni VARCHAR(9) PRIMARY KEY,
  edad INT,
  genero CHAR(1),
  id_participante INT,
  FOREIGN KEY(id_participante) REFERENCES PARTICIPANTE(id_participante)
);

CREATE TABLE EQUIPO(
  id_equipo INT PRIMARY KEY,
  id_participante INT,
  FOREIGN KEY(id_participante) REFERENCES PARTICIPANTE(id_participante)
);

CREATE TABLE CUERPO_TECNICO(
  id_cuerpotec INT PRIMARY KEY,
  dni VARCHAR(9),
  id_participante INT,
  FOREIGN KEY(id_participante) REFERENCES PARTICIPANTE(id_participante)
);

CREATE TABLE FISIOTERAPEUTA(
  id_fisio INT PRIMARY KEY,
  titulacion VARCHAR(50),
  id_cuerpotec INT,
  FOREIGN KEY(id_cuerpotec) REFERENCES CUERPO_TECNICO(id_cuerpotec)
);

CREATE TABLE ENTRENADOR(
  id_entrenador INT PRIMARY KEY,
  especialidad VARCHAR(50),
  id_cuerpotec INT,
  FOREIGN KEY(id_cuerpotec) REFERENCES CUERPO_TECNICO(id_cuerpotec)
);

CREATE TABLE PSICOLOGO(
  id_psicologo INT PRIMARY KEY,
  licencia VARCHAR(50),
  id_cuerpotec INT,
  FOREIGN KEY(id_cuerpotec) REFERENCES CUERPO_TECNICO(id_cuerpotec)
);

CREATE TABLE MEDALLA(
  id_medalla INT PRIMARY KEY,
  tipo VARCHAR(50)
);

CREATE TABLE EVENTO(
    fecha DATE,
    id_deporte INT,
    id_disciplina INT,
    id_sede INT,
    id_medalla INT,
    id_participante INT,
    PRIMARY KEY(id_sede, id_deporte, id_disciplina, id_participante),
    FOREIGN KEY(id_deporte, id_disciplina) REFERENCES DISCIPLINA(id_deporte, id_disciplina),
    FOREIGN KEY(id_sede) REFERENCES SEDE(id_sede),
    FOREIGN KEY(id_participante) REFERENCES PARTICIPANTE(id_participante),
    FOREIGN KEY(id_medalla) REFERENCES MEDALLA(id_medalla)
);


-- =====================================
-- INSERT DE LAS TABLAS
-- =====================================

-- TABLA PAIS
INSERT INTO PAIS (cod_iso, nombre) VALUES ('ESP', 'España');
INSERT INTO PAIS (cod_iso, nombre) VALUES ('FRA', 'Francia');


-- TABLA SEDE
INSERT INTO SEDE (id_sede, nombre, ciudad, aforo, cod_iso, anho) VALUES
(1, 'Palacio de Deportes', 'Madrid', 15000, 'ESP', 2025),
(2, 'Stade de France', 'París', 80000, 'FRA', 2025);


-- TABLA DEPORTE
INSERT INTO DEPORTE (id_deporte, nombre) VALUES (1, 'Natación');
INSERT INTO DEPORTE (id_deporte, nombre) VALUES (2, 'Atletismo');


-- TABLA DISCIPLINA
INSERT INTO DISCIPLINA (id_deporte, id_disciplina, nombre, categoria) VALUES (1, 1, '100m Libre', 'M');
INSERT INTO DISCIPLINA (id_deporte, id_disciplina, nombre, categoria) VALUES (1, 2, '200m Libre', 'F');
INSERT INTO DISCIPLINA (id_deporte, id_disciplina, nombre, categoria) VALUES (2, 1, '100m Lisos', 'M');


-- TABLA PARTICIPANTE
INSERT INTO PARTICIPANTE (id_participante, nombre, tipo, cod_iso) VALUES (1, 'España Natación', 'EQUIPO', 'ESP');
INSERT INTO PARTICIPANTE (id_participante, nombre, tipo, cod_iso) VALUES (2, 'Juan Pérez', 'ATLETA', 'ESP');
INSERT INTO PARTICIPANTE (id_participante, nombre, tipo, cod_iso) VALUES (3, 'Francia Atletismo', 'EQUIPO', 'FRA');


-- TABLA ATLETA
INSERT INTO ATLETA (dni, edad, genero, id_participante) VALUES ('12345678A', 22, 'M', 2);


-- TABLA EQUIPO
INSERT INTO EQUIPO (id_equipo, id_participante) VALUES (1, 1);
INSERT INTO EQUIPO (id_equipo, id_participante) VALUES (2, 3);


-- TABLA CUERPO_TECNICO
INSERT INTO CUERPO_TECNICO (id_cuerpotec, dni, id_participante) VALUES (1, '87654321B', 1);


-- TABLA FISIOTERAPEUTA
INSERT INTO FISIOTERAPEUTA (id_fisio, titulacion, id_cuerpotec) VALUES (1, 'Licenciado en Fisioterapia', 1);


-- TABLA ENTRENADOR
INSERT INTO ENTRENADOR (id_entrenador, especialidad, id_cuerpotec) VALUES (1, 'Natación de velocidad', 1);


-- TABLA PSICOLOGO
INSERT INTO PSICOLOGO (id_psicologo, licencia, id_cuerpotec) VALUES (1, 'Licencia Psicología Deportiva', 1);


-- TABLA MEDALLA
INSERT INTO MEDALLA (id_medalla, tipo) VALUES (1, 'Oro');
INSERT INTO MEDALLA (id_medalla, tipo) VALUES (2, 'Plata');


-- TABLA EVENTO
INSERT INTO EVENTO (fecha, id_deporte, id_disciplina, id_sede, id_medalla, id_participante)
VALUES ('2025-07-15', 1, 1, 1, 1, 1);
INSERT INTO EVENTO (fecha, id_deporte, id_disciplina, id_sede, id_medalla, id_participante)
VALUES ('2025-07-15', 1, 1, 1, 2, 2);


-- =====================================
-- SENTENCIAS DE COMPROBACIÓN
-- =====================================

SELECT * FROM PAIS;
SELECT * FROM SEDE;
SELECT * FROM DEPORTE;
SELECT * FROM DISCIPLINA;
SELECT * FROM PARTICIPANTE;
SELECT * FROM ATLETA;
SELECT * FROM EQUIPO;
SELECT * FROM CUERPO_TECNICO;
SELECT * FROM FISIOTERAPEUTA;
SELECT * FROM ENTRENADOR;
SELECT * FROM PSICOLOGO;
SELECT * FROM MEDALLA;
SELECT * FROM EVENTO;
SELECT * FROM vista_participante_actualizable;
SELECT * FROM vista_atleta_actualizable;
SELECT * FROM vista_medallas_pais;
SELECT * FROM vista_disciplinas_deporte;
