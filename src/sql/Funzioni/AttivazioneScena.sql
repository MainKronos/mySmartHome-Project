-- Attivazione Scena Luci

drop procedure if exists AttivazioneScena;
delimiter $$
create procedure AttivazioneScena(in _scena int)
begin

    declare numero_attivita int default 0;
    declare ultima_attivita int default 0;
    declare tmp int default 0;

    set numero_attivita = (
        select count(*)
        from Configurazione
        where id_scena = _scena
    );

    set ultima_attivita = (
        select id_attivita
        from Attivita
        order by id_attivita desc
        limit 1
    );

    scan: loop
        if tmp = numero_attivita then
            leave scan;
        end if ;

        set tmp = tmp + 1;

        insert into Attivita
        values (ultima_attivita + tmp);

        insert into AttivitaLuce
        select ultima_attivita + tmp, d.id_dispositivo, 1, d.temperatura, d.intensita, now()
        from(
            select *
            from Configurazione
            where id_scena = _scena
        ) as d;

    end loop ;

end $$
delimiter ;

call AttivazioneScena(1);