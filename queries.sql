-- RF 4

select a.cidade_ativo, count (e.id)
    from eventos e
    right join dispositivos d
    on e.dispositivos_id_dispositivos = d.id_dispositivos
    inner join ativos a
    on a.clientes_id_cliente = d.ativos_id_cliente and a.id_ativos = d.ativos_id_ativos
    group by a.cidade_ativo;


-- RF 5

select ativos.tipologia, dispositivos.tipo_dispositivos
from dispositivos
inner join ativos
on ativos.id_ativos = dispositivos.ativos_id_ativos
order by ativos.tipologia;


-- RF 6 - Visualizar os ativos “mais problemáticos”, nos últimos 180 dias. com mais do que 3 eventos

select a.id_ativos as Ativo, a.clientes_id_cliente as Cliente, count (e.id) as N_Eventos
    from ativos a 
    left join dispositivos d
    on a.clientes_id_cliente = d.ativos_id_cliente and a.id_ativos = d.ativos_id_ativos
    inner join eventos e
    on d.id_dispositivos = e.dispositivos_id_dispositivos
    where dia_hora > sysdate - 180 
    group by a.id_ativos, a.clientes_id_cliente
    having count(e.id) > 3
    order by N_Eventos DESC;
    
    
-- RF 8 Visualizar cada cliente e o respetivo valor mensal a pagar. 

select id_cliente, nome, preço
    from clientes c, fatura f
    where c.id_cliente = f.clientes_id_cliente;
    
    
-- RF 9 Lista de ativos estáticos que têm câmera

select id_ativos, tipo_ativos, tipologia, endereço, cidade_ativo, coordenadas, to_char(hora_inicial,'HH24:MI'), to_char(hora_final, 'HH24:MI'), clientes_id_cliente
    from ativos a, dispositivos d
    where a.tipo_ativos = 'estático' and (d.tipo_dispositivos like 'camera%') and a.clientes_id_cliente = d.ativos_id_cliente and a.id_ativos = d.ativos_id_ativos;


-- RF 10 Clientes com mais de 65 anos

select * from clientes
    where data_nascimento < sysdate - interval '65' year
    order by data_nascimento desc;


-- RF 11 O total dinheiro a receber dos clientes max e min

select sum (f.preço) as Total, max(f.preço) as Máximo, min(f.preço) as Mínimo
    from fatura f
    inner join clientes c
    on c.id_cliente = f.clientes_id_cliente;
