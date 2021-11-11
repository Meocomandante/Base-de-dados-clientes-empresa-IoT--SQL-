drop sequence cliente_key_seq;
drop sequence ativo_key_seq;
drop sequence dispositivo_key_seq;
drop sequence fatura_key_seq;

--RF3 Visualizar os alertas ocorridos num ativo entre duas datas

CREATE TYPE TABLE_RES_OBJ AS OBJECT (
    tipo VARCHAR2(100),
    alerta INTEGER,
    dia DATE
);

CREATE TYPE TABLE_RES AS TABLE OF TABLE_RES_OBJ;

CREATE OR REPLACE FUNCTION visualizar_alerta(data_inicial IN DATE, data_final IN DATE)
RETURN TABLE_RES
IS
variavel TABLE_RES:= TABLE_RES();
BEGIN
select cast(Multiset(select dispositivos.tipo_dispositivos, dispositivos.alerta, eventos.dia_hora
from dispositivos
inner join eventos
on eventos.dispositivos_id_dispositivos = dispositivos.id_dispositivos
where dispositivos.alerta = 1 and eventos.dia_hora BETWEEN data_inicial and data_final)
AS TABLE_RES)
into variavel
from dual;
RETURN variavel;
END;


--RF7 Visualizar os clientes e os respetivos alertas (decorrentes dos seus ativos)

CREATE TYPE rf7_OBJ AS OBJECT (
    nome VARCHAR2(150),
    tipologia VARCHAR2(100),
    alerta INTEGER
);

CREATE TYPE rf7_TABLE AS TABLE OF rf7_OBJ;

CREATE OR REPLACE FUNCTION visualizar_alerta_cliente(cliente_id IN INTEGER)
RETURN rf7_TABLE
IS
variavel2 rf7_TABLE:= rf7_TABLE();
BEGIN
select cast(Multiset(select clientes.nome, ativos.tipo_ativos, dispositivos.alerta
from clientes
inner join ativos
on clientes.id_cliente = ativos.clientes_id_cliente
inner join dispositivos
on clientes.id_cliente = dispositivos.ativos_id_cliente and ativos.id_ativos = dispositivos.ativos_id_ativos
where dispositivos.alerta = 1 and clientes.id_cliente = cliente_id)
AS rf7_TABLE)
into variavel2
from dual;
RETURN variavel2;
END;


--RF12 Clientes que têm mais de x dispositivos

CREATE TYPE rf12_OBJ AS OBJECT(
    nome VARCHAR2(150),
    tipo VARCHAR2(100),
    id_dispositivo INTEGER
    --n_disp INTEGER
);

CREATE TYPE rf12_TABLE AS TABLE OF rf12_OBJ;

CREATE OR REPLACE FUNCTION visualizar_dispositivos_clientes(n_dispositivos IN INTEGER)
RETURN rf12_TABLE
IS
variavel3 rf12_TABLE:= rf12_TABLE();
aux INTEGER;
BEGIN
select cast(Multiset(select clientes.nome, dispositivos.tipo_dispositivos, dispositivos.id_dispositivos
from clientes
inner join ativos
on clientes.id_cliente = ativos.clientes_id_cliente
inner join dispositivos
on ativos.clientes_id_cliente = dispositivos.ativos_id_cliente and ativos.id_ativos = dispositivos.ativos_id_ativos
where clientes.nº_dispositivos > n_dispositivos
GROUP BY dispositivos.id_dispositivos, clientes.nome, dispositivos.tipo_dispositivos)
AS rf12_TABLE)
into variavel3
from dual;
RETURN variavel3;
END;

------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE SEQUENCE cliente_key_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;
 
 CREATE SEQUENCE ativo_key_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;
 
 CREATE SEQUENCE dispositivo_key_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;
 
 CREATE SEQUENCE fatura_key_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;
 
--Inserir Cliente

create or replace procedure ADD_cliente(
    nome1 in clientes.nome%type,
    contribuinte in clientes.nº_contribuinte%type,
    numero in clientes.numerotele%type,
    morada in clientes.endereço_cliente%type,
    data_nasc in clientes.data_nascimento%type
    )
    is
    begin

    insert into clientes(id_cliente, nome, nº_contribuinte, numerotele, endereço_cliente, data_nascimento, nº_dispositivos)
    values(cliente_key_seq.nextval,nome1,contribuinte, numero, morada, data_nasc, 0);
end ADD_cliente;


--Inserir ativo

create or replace procedure ADD_ativo(
    --ativo_id in ativos.id_ativos%type,
    tipo in ativos.classificação%type,
    tipologia1 in ativos.tipo_ativos%type,
    endereço1 in ativos.endereço_ativo%type,
    cidade in ativos.cidade_ativo%type,
    coord in ativos.coordenadas%type,
    hora_ini in ativos.hora_inicial%type,
    hora_fin in ativos.hora_final%type,
    cliente_id in ativos.clientes_id_cliente%type
    )
    is
    begin

    insert into ativos(id_ativos, CLASSIFICAÇÃO, tipo_ativos, endereço_ativo, cidade_ativo, coordenadas, hora_inicial, hora_final, clientes_id_cliente)
    values(ativo_key_seq.nextval, tipo, tipologia1, endereço1, cidade, coord, hora_ini, hora_fin, cliente_id);
end ADD_ativo;


--Inserir dispositivo

create or replace procedure ADD_dispositivo(
    tipo in dispositivos.tipo_dispositivos%type,
    alerta1 in dispositivos.alerta%type,
    ativo_id in dispositivos.ativos_id_ativos%type,
    cliente_id in dispositivos.ativos_id_cliente%type
    )
    is
        n INTEGER;
    begin

    insert into dispositivos(id_dispositivos, tipo_dispositivos, alerta, ativos_id_ativos, ativos_id_cliente)
    values(dispositivo_key_seq.nextval, tipo, alerta1, ativo_id, cliente_id);
    select nº_dispositivos into n from clientes where clientes.id_cliente = cliente_id;
    
    UPDATE clientes
    SET nº_dispositivos = n + 1
    WHERE clientes.id_cliente = cliente_id;
end ADD_dispositivo;


--Inserir evento

create or replace procedure ADD_evento(
    evento_id in eventos.id%type,
    data_evento in eventos.dia_hora%type,
    dispositivo_id in eventos.dispositivos_id_dispositivos%type,
    gravidade_evento in eventos.gravidade%type
    )
    is
    begin

    insert into eventos(id, dia_hora, dispositivos_id_dispositivos, gravidade)
    values(evento_id, data_evento, dispositivo_id, gravidade_evento);
    
    if (gravidade_evento = 1) then
        UPDATE dispositivos
        SET alerta = 1
        WHERE id_dispositivos = dispositivo_id;
    end if;
end ADD_evento;


--Inserir fatura

CREATE OR REPLACE TYPE id_array IS VARRAY(10) of INTEGER;
create or replace procedure ADD_fatura(
    endereço1 in fatura.enderenço_fatura%type,
    cidade in fatura.cidade_fatura%type,
    codigopostal in fatura.codigo_postal%type,
    cliente_id in INTEGER
    )
    is
    x INTEGER;
    ativo_id INTEGER;
    array id_array := id_array();
    n INTEGER;
    datai DATE;
    dataf DATE;
    total NUMBER;
    preço_final NUMBER;
begin
    preço_final :=0;
    select ativos.id_ativos BULK COLLECT into array
    from ativos
    where ativos.clientes_id_cliente = cliente_id;
    
    select count(*) into x
    from ativos
    where ativos.clientes_id_cliente = cliente_id;
    
    FOR i IN 1..x
    LOOP
    array.extend();
        ativo_id := array(i);
        --calcular preço
        select count(*) into n
        from dispositivos
        inner join ativos
        on dispositivos.ativos_id_ativos = ativos.id_ativos and ativos.id_ativos = ativo_id;
        
        select hora_inicial into datai 
        from ativos
        where ativos.id_ativos = ativo_id;
        
        select hora_final into dataf
        from ativos
        where ativos.id_ativos = ativo_id;
        
        select (hora_final-hora_inicial)*24 into total
        from ativos
        where ativos.id_ativos = ativo_id;
        
        total := total*n;
        preço_final := preço_final + total;
    END LOOP;
    insert into fatura
    values(fatura_key_seq.nextval, preço_final, endereço1, cidade, codigopostal, cliente_id);
end ADD_fatura;


--Update nºtele cliente

CREATE OR REPLACE PROCEDURE update_tele_cliente(
    cliente_id in clientes.id_cliente%type,
    n_tele in clientes.numerotele%type)
is
begin
    UPDATE clientes
    SET numerotele = n_tele
    WHERE id_cliente = cliente_id;
end update_tele_cliente;


--Update endereço cliente
CREATE OR REPLACE PROCEDURE update_endereço_cliente(
    cliente_id in clientes.id_cliente%type,
    endereco in clientes.endereço_cliente%type)
is
begin
    UPDATE clientes
    SET endereço_cliente = endereco
    WHERE id_cliente = cliente_id;
end update_endereço_cliente;


--Apagar evento

CREATE OR REPLACE PROCEDURE delete_evento(
    evento_id in eventos.id%type,
    dispositivo_id in dispositivos.id_dispositivos%type
    )
    is
    begin
    delete eventos where eventos.id = evento_id and dispositivos_id_dispositivos = dispositivo_id;
end delete_evento;


--Apagar dispositivo

CREATE OR REPLACE PROCEDURE delete_dispositivo(
    dispositivo_id in dispositivos.id_dispositivos%type
    )
    is
    n INTEGER;
    cliente_id INTEGER;
    begin
    
    select dispositivos.ativos_id_cliente into cliente_id 
    from dispositivos
    where dispositivos.id_dispositivos = dispositivo_id;
    
    select nº_dispositivos into n 
    from clientes 
    where clientes.id_cliente = cliente_id;
    
    UPDATE clientes
    SET nº_dispositivos = n - 1
    WHERE clientes.id_cliente = cliente_id;
    
    delete dispositivos where dispositivos.id_dispositivos = dispositivo_id;
end delete_dispositivo;


--Apagar cliente, ativos associados e dispositivos associados

CREATE OR REPLACE PROCEDURE delete_cliente(
    cliente_id in clientes.id_cliente%type
    )
    is
    begin
    
    UPDATE clientes
    SET nº_dispositivos = 0
    WHERE clientes.id_cliente = cliente_id;
    
    delete from ativos where ativos.clientes_id_cliente = cliente_id;
end delete_cliente;
