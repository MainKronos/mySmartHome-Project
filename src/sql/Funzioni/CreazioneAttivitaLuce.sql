drop procedure if exists CreazioneAttivitaLuce;
delimiter $$
create procedure CreazioneAttivitaLuce(
in _nome_utente varchar(255), in _luce int, in _stato tinyint, in _temperatura int, in _intensita int, in _data datetime
) begin

    -- Dichiarazione Variabili
    declare check_data boolean default FALSE;
    declare error_data varchar(255) default '';

    declare check_nome_utente boolean default FALSE;
    declare error_nome_utente varchar(255) default '';

    declare check_dispositvo boolean default FALSE;
    declare error_dispositivo varchar(255) default '';

    declare id_attivita_var int default 0;

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
        from Luce
        where id_dispositivo = _luce
    );
    if not check_dispositvo then
        select concat('La dispositivo luce ', _luce, ' non esiste.') into error_dispositivo;
        signal sqlstate '45000'
        set message_text = error_dispositivo;
    end if ;

    -- Errore Stato
    if not _stato then
        set _temperatura = 0;
        set _intensita = 0;
    end if;

    -- Inizio Procedura

    set id_attivita_var = (
        select a.id_attivita + 1
        from Attivita a
        order by a.id_attivita desc
        limit 1
    );

    insert into Attivita
    value (id_attivita_var);

    insert into Accesso
    value (_nome_utente, id_attivita_var, now());

    insert into AttivitaLuce
    value (id_attivita_var, _luce, _stato, _temperatura, _intensita, _data);

end $$
delimiter ;


call CreazioneAttivitaLuce('alooker3', 1, 1, 4000, 100, now());