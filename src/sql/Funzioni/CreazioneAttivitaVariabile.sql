drop procedure if exists CreazioneAttivitaVariabile;
delimiter $$
create procedure CreazioneAttivitaVariabile(
in _nome_utente varchar(255), in _variabile int, in _livello int, in _data datetime
) begin

    -- Dichiarazione Variabili
    declare check_data boolean default FALSE;
    declare error_data varchar(255) default '';

    declare check_nome_utente boolean default FALSE;
    declare error_nome_utente varchar(255) default '';

    declare check_dispositvo boolean default FALSE;
    declare error_dispositivo varchar(255) default '';

    declare check_potenza boolean default FALSE;
    declare error_potenza varchar(255) default '';

    declare id_attivita_var int default 0;
    declare id_potenza_var int default 0;

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
        from Variabile
        where id_dispositivo = _variabile
    );
    if not check_dispositvo then
        select concat('Il dispositivo variabile ', _variabile, ' non esiste.') into error_dispositivo;
        signal sqlstate '45000'
        set message_text = error_dispositivo;
    end if ;

    -- Errore Potenza
    set check_potenza = exists(
        select *
        from Potenza
        where variabile = _variabile
            and livello = _livello
    );
    if not check_potenza then
        select concat('Il livello di potenza ', _livello, ' per il dispositivo, ', _variabile, ' non esiste.') into error_potenza;
        signal sqlstate '45000'
        set message_text = error_potenza;
    end if ;

    -- Inizio Procedura

    set id_attivita_var = (
        select a.id_attivita + 1
        from Attivita a
        order by a.id_attivita desc
        limit 1
    );

    set id_potenza_var = (
        select id_potenza
        from Potenza
        where variabile = _variabile
            and livello = _livello
    );

    insert into Attivita
    value (id_attivita_var);

    insert into Accesso
    value (_nome_utente, id_attivita_var, now());

    insert into AttivitaVariabile
    value (id_attivita_var, _variabile, id_potenza_var, _data);

end $$
delimiter ;


call CreazioneAttivitaVariabile('alooker3', 177, 1, now());