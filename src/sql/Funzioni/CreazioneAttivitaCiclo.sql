drop procedure if exists CreazioneAttivitaCiclo;
delimiter $$
create procedure CreazioneAttivitaCiclo(
in _nome_utente varchar(255), in _ciclo int, in _tipo varchar(255), in _data datetime
) begin

    -- Dichiarazione Variabili
    declare check_data boolean default FALSE;
    declare error_data varchar(255) default '';

    declare check_nome_utente boolean default FALSE;
    declare error_nome_utente varchar(255) default '';

    declare check_dispositvo boolean default FALSE;
    declare error_dispositivo varchar(255) default '';

    declare check_tipo boolean default FALSE;
    declare error_tipo varchar(255) default '';

    declare id_attivita_var int default 0;
    declare id_programma_var int default 0;

    -- Errore Data
    set check_data = _data >= now();
    if not check_data then
        select concat('La data ', _data, ' non è valida') into error_data;
        signal sqlstate '45000'
        set message_text = error_data;
    end if;

    -- Errore Utente
    set check_nome_utente = exists(
        select *
        from Account
        where nome_utente = _nome_utente
    );
    if not check_nome_utente then
        select concat('L'' Utente ', _nome_utente, ' non esiste.') into error_nome_utente;
        signal sqlstate '45000'
        set message_text = error_nome_utente;
    end if;

    -- Errore Dispositivo
    set check_dispositvo = exists(
        select *
        from Ciclo
        where id_dispositivo = _ciclo
    );
    if not check_dispositvo then
        select concat('Il dispositivo a ciclo ', _ciclo, ' non esiste.') into error_dispositivo;
        signal sqlstate '45000'
        set message_text = error_dispositivo;
    end if ;

    -- Errore Tipo
    set check_tipo = exists(
        select *
        from Programma
        where ciclo = _ciclo
            and tipo = _tipo
    );
    if not check_tipo then
        select concat('La tipologia ', _tipo, ' per il dispositivo, ', _ciclo, ' non esiste.') into error_tipo;
        signal sqlstate '45000'
        set message_text = error_tipo;
    end if ;

    -- Inizio Procedura

    set id_attivita_var = (
        select a.id_attivita + 1
        from Attivita a
        order by a.id_attivita desc
        limit 1
    );

    set id_programma_var = (
        select id_programma
        from Programma
        where ciclo = _ciclo
            and tipo = _tipo
    );


    insert into Attivita
    value (id_attivita_var);

    insert into Accesso
    value (_nome_utente, id_attivita_var, now());

    insert into AttivitaCiclo
    value (id_attivita_var, _ciclo, id_programma_var, _data);

end $$
delimiter ;


call CreazioneAttivitaCiclo('alooker3', 170, 'Asciugatura Veloce 1', now());