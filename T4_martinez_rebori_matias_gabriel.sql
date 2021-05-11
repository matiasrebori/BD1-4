--@C:\sql\T4_martinez_rebori_matias_gabriel.sql
--conexion al sistema
CONN system/admin;
-- Si existe el usuario edgar, lo elimino con todos sus objetos para probar una y otra vez;
DROP USER matias CASCADE;
--crear usuario
CREATE USER matias IDENTIFIED BY admin DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp QUOTA UNLIMITED ON users;
--dar privilegio/permiso de inicio de sesion y de crear tablas
GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE, CREATE TRIGGER, CREATE VIEW TO matias;
--salir de system
DISC;
--entrar en matias
CONN matias/admin;

-- Para cambiar formato de fechas:
ALTER SESSION SET NLS_DATE_FORMAT = 'dd-mm-yyyy';

--tabla socios

create table socios(
    nrosocio integer,
    nombres char(30),
    apellidos char(30),
    ci integer unique,
    edad integer,
    socioproponente integer,
    constraint pks primary key (nrosocio),
    constraint fksp foreign key (socioproponente) references socios (nrosocio),
    constraint ck_mayor_edad check (edad>18)
);
CREATE SEQUENCE seq_nrosocio;

--tabla prestamo

create table prestamo(
    nroprestamo integer,
    nrosocio integer,
    fecha date,
    tasa number(2,1),
    monto integer check (monto>0),
    saldo integer,
    constraint Pkp primary key (nroprestamo),
    constraint Fkps foreign key (nrosocio) references socios(nrosocio)
);
CREATE SEQUENCE seq_nroprestamo;

--tabla cuota

create table cuota(
    nroprestamo integer,
    nrocuota integer,
    fecha_vence date,
    fecha_pago date,
    importe integer check (importe>0),
    constraint Fkpc foreign key (nroprestamo) references prestamo(nroprestamo),
    constraint pkc primary key (nroprestamo, nrocuota)
);

-- Insercion en tabla Socios
insert into socios values(seq_nrosocio.nextval,'Luis','Acosta',1111,25,null);
insert into socios values(seq_nrosocio.nextval,'Pedro','Rivaldi',2222,19,1);
insert into socios values(seq_nrosocio.nextval,'Laura','Diaz',3333,33,1);
insert into socios values(seq_nrosocio.nextval,'Leticia','Perez',4444,23,2);
insert into socios values(seq_nrosocio.nextval,'Roberto','Gomez',5555,30,3);

-- Insercion en tabla Prestamo
insert into prestamo values (seq_nroprestamo.nextval,1,'01-02-2017',1.2,1000000,0);
insert into prestamo values (seq_nroprestamo.nextval,2,'01-04-2017',1.2,1000000,500000);
insert into prestamo values (seq_nroprestamo.nextval,2,'05-04-2017',1.2,1000000,1000000);
insert into prestamo values (seq_nroprestamo.nextval,1,'01-05-2017',1.2,1000000,1000000);
insert into prestamo values (seq_nroprestamo.nextval,5,'05-06-2017',1.2,2500000,2000000);

-- Insercion en tabla Cuota
insert into cuota values(1,1,'01-03-2017','25-02-2017',500000);
insert into cuota values(1,2,'01-04-2017','30-03-2017',500000);
insert into cuota values(2,1,'01-05-2017','25-04-2017',500000);
insert into cuota values(2,2,'01-06-2017',null,50000);
insert into cuota values(3,1,'05-05-2017',null,500000);
insert into cuota values(3,2,'05-06-2017',null,500000);
insert into cuota values(4,1,'01-06-2017',null,500000);
insert into cuota values(4,2,'01-07-2017',null,500000);
insert into cuota values(5,1,'01-07-2017',null,500000);

--  trigger 

CREATE TRIGGER VERIFICAR_FECHA_CUOTA
BEFORE UPDATE OF fecha_pago ON cuota
FOR EACH ROW
BEGIN
    IF(:new.fecha_pago > :old.fecha_vence ) THEN 
        raise_application_error( -20001, 'Cuota vencida!!! Consulte con la gerencia.' );
    ELSE
        UPDATE prestamo SET saldo = saldo - :old.importe WHERE ( nroprestamo = :old.nroprestamo );
    END IF;
END;
/

--probar trigger 
--no deberia funcionar
update cuota set fecha_pago = '02-06-2017' where  nroprestamo = 2 and nrocuota = 2;
--si deberia funcionar
update cuota set fecha_pago = '01-06-2017' where  nroprestamo = 2 and nrocuota = 2;

COMMIT;

--4 vista Vista_Socios , select * from Vista_Socios;

CREATE VIEW VISTA_SOCIOS ( Nrosocio , Nombres , CI, Total_Prestamo_Obtenido, Total_Prestamo_Cancelado, NroSocio_Proponente ,Socio_Proponente )
AS
SELECT 
    s.nrosocio, 
    s.nombres || ' ' || s.apellidos, 
    s.ci,
    ( SELECT SUM(p.monto) FROM prestamo p WHERE p.nrosocio = s.nrosocio ),
    ( SELECT SUM(p.monto) FROM prestamo p WHERE p.nrosocio = s.nrosocio AND p.saldo = 0),
    s.socioproponente,
    s2.nombres || ' ' || s2.apellidos
    FROM socios s
    --left join por si socio no tiene un socioproponente y que aparezca igual
    LEFT JOIN socios s2 ON s.socioproponente = s2.nrosocio
    ORDER BY s.nrosocio;

--5
SELECT nombres, apellidos, ci, edad FROM socios WHERE edad >= 25 AND edad <=30; 
--6
SELECT
    p.nroprestamo,
    p.nrosocio,
    s.ci,
    s.nombres || ' ' || s.apellidos AS nombres,
    s2.nombres || ' ' || s2.apellidos AS socioproponente,
    p.monto
FROM
    prestamo p, socios s
LEFT JOIN socios s2 ON s.socioproponente = s2.nrosocio
WHERE
    monto =(
        SELECT
            MAX( monto )
        FROM
            prestamo
    )
AND
    p.nrosocio = s.nrosocio;