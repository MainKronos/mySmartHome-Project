-- Registrazione Utente

drop procedure if exists RegistrazioneUtente;
delimiter $$
create procedure RegistrazioneUtente(
    in _nome_utente varchar(50), in _password varchar(50), in _domanda_sicurezza varchar(255), in _risposta_sicurezza varchar(255), in _codice_fiscale varchar(17),
    in _nome varchar(50), in _cognome varchar(50), in _data_nascita date, in _telefono varchar(255),
    in _tipologia_documento varchar(255), in _numero_documento varchar(50), in _scadenza_documento date, in _ente_rilascio_documento varchar(255)
)
begin

    declare check_codice_fiscale boolean default FALSE;
    declare check_scadenza_documento boolean default FALSE;

    set check_codice_fiscale = _codice_fiscale REGEXP '([B-DF-HJ-NP-TV-Z]{3})([B-DF-HJ-NP-TV-Z]{3})([1-9]|1[0-2])([A-Z])(0[1-9]|[12][0-9]|3[01])([0-9A-Z]{4})([A-Z])';
    if not check_codice_fiscale then
        signal sqlstate '45000'
        set message_text = 'Codice Fiscale non valido.';
    end if;

    set check_scadenza_documento = _scadenza_documento > current_date();
    if not check_scadenza_documento then
        signal sqlstate '45000'
        set message_text = 'Documento scaduto.';
    end if;

    insert into Utente
    values (_codice_fiscale, _nome, _cognome, _data_nascita, _telefono);

    insert into Documento
    values (_codice_fiscale, _tipologia_documento, _numero_documento, _scadenza_documento, _ente_rilascio_documento);

    insert into Account
    values (_nome_utente, _password, _domanda_sicurezza, _risposta_sicurezza, _codice_fiscale);
end $$
delimiter ;

call RegistrazioneUtente(
    'pippo', '1234', 'Chi sono?', 'pippo', 'CHSLNZ12A31B7HAA',
    'Pippo', 'Caputo', '2001-02-02', '2344354564',
    'Documento Speciale', 'IlNumeroUno', '2029-02-02', 'Mio Nonno'
);