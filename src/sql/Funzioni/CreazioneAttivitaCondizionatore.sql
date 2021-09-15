drop procedure if exists CreazioneAttivitaCondizionatore;
delimiter $$
create procedure CreazioneAttivitaCondizionatore(
in _nome_utente varchar(255), in _condizionatore int, in _id_impostazione int, in _data datetime, in _data_fine datetime, in _intervallo int
) begin

    -- Dichiarazione Variabili
    declare check_data boolean default FALSE;
    declare error_data varchar(255) default '';

    declare check_nome_utente boolean default FALSE;
    declare error_nome_utente varchar(255) default '';

    declare check_dispositvo boolean default FALSE;
    declare error_dispositivo varchar(255) default '';

    declare check_id_impostazione boolean default FALSE;
    declare error_id_impostazione varchar(255) default '';

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
        from Condizionatore
        where id_dispositivo = _condizionatore
    );
    if not check_dispositvo then
        select concat('Il dispositivo condizionatore ', _condizionatore, ' non esiste.') into error_dispositivo;
        signal sqlstate '45000'
        set message_text = error_dispositivo;
    end if ;

    -- Errore Impostazione
    set check_id_impostazione = exists(
        select *
        from Impostazione
        where condizionatore = _condizionatore
            and id_impostazione = _id_impostazione
    );
    if not check_id_impostazione then
        select concat('L''impostazione ', _id_impostazione, ' per il dispositivo, ', _condizionatore, ' non esiste.') into error_id_impostazione;
        signal sqlstate '45000'
        set message_text = error_id_impostazione;
    end if ;

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

    insert into AttivitaCondizionatore
    value (id_attivita_var, _condizionatore, _id_impostazione, _data_fine, _intervallo, _data);

end $$
delimiter ;


call CreazioneAttivitaCondizionatore('alooker3', 190, 1, now(), now(), NULL);