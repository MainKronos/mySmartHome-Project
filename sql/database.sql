BEGIN;
DROP DATABASE IF EXISTS SmartHome;
CREATE DATABASE SmartHome;
COMMIT;

USE SmartHome;
SET GLOBAL log_bin_trust_function_creators = 1;


-- ###########################################################################################################################################
-- #####################            ##########################################################################################################
-- ##################### SMART HOME ##########################################################################################################
-- #####################            ##########################################################################################################
-- ###########################################################################################################################################

-- Tabella Utente ###########################################################################################################################################
drop table if exists Utente;
create table Utente (
    codice_fiscale char(16) not null,
    nome varchar(255) not null,
    cognome varchar(255) not null,
    data_nascita date not null,
    telefono char(10) not null,

    primary key (codice_fiscale),
    constraint CHECK_Utente_codice_fiscale check (codice_fiscale REGEXP '([B-DF-HJ-NP-TV-Z]{3})([B-DF-HJ-NP-TV-Z]{3})(0[1-9]|1[0-2])([A-Z])(0[1-9]|[12][0-9]|3[01])([0-9A-Z]{4})([A-Z])') not enforced
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Documento ###########################################################################################################################################
drop table if exists Documento;
create table Documento (
    utente char(16) not null,
    tipologia varchar(255) not null,
    numero varchar(255) not null,
    scadenza date not null,
    ente_rilascio varchar(255) not null,

    primary key (utente),
    foreign key (utente) references Utente(codice_fiscale) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Account ###########################################################################################################################################
drop table if exists Account;
create table Account (
    nome_utente varchar(255) not null,
    `password` varchar(255) not null,
    domanda_sicurezza varchar(255) not null,
    risposta_sicurezza varchar(255) not null,
    codice_fiscale char(16) not null,

    primary key (nome_utente),
    foreign key (codice_fiscale) references Utente(codice_fiscale) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Notifica ###########################################################################################################################################
drop table if exists Notifica;
create table Notifica (
    id_notifica int not null AUTO_INCREMENT,
    messaggio varchar(255) not null,
    `data` datetime not null,
    accettata tinyint not null,
    account_utente varchar(255) not null,
    id_dispositivo int,

    primary key (id_notifica),
    foreign key (account_utente) references Account(nome_utente) on delete cascade,
    constraint CHECK_Notifica_accettata check (accettata between 0 and 1)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella FasciaOraria ###########################################################################################################################################
drop table if exists FasciaOraria;
create table FasciaOraria (
    id_fascia_oraria int not null AUTO_INCREMENT,
    ora_inizio time not null,
    ora_fine time not null,
    retribuzione float not null, -- euro / watt
    prezzo float not null, -- euro / watt
    account_utente varchar(255) not null,
    data_attivazione date not null,

    primary key (id_fascia_oraria),
    foreign key (account_utente) references Account(nome_utente) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella ImpostazioneFasciaOraria ###########################################################################################################################################
drop table if exists ImpostazioneFasciaOraria;
create table ImpostazioneFasciaOraria (
    id_fascia_oraria int not null,
    casa int not null,
    batteria int not null,
    rete int not null,
    uso_batteria tinyint not null,
    
    primary key (id_fascia_oraria),
    foreign key (id_fascia_oraria) references FasciaOraria(id_fascia_oraria) on delete cascade,
    constraint CHECK_ImpostazioneFasciaOraria_uso_batteria check (uso_batteria between 0 and 1),
    constraint CHECK_ImpostazioneFasciaOraria_casa check (casa between 0 and 100),
    constraint CHECK_ImpostazioneFasciaOraria_batteria check (batteria between 0 and 100),
    constraint CHECK_ImpostazioneFasciaOraria_rete check (rete between 0 and 100)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Luogo ###########################################################################################################################################
drop table if exists Luogo;
create table Luogo (
    id_luogo int not null AUTO_INCREMENT,
    nome varchar(255) not null,

    primary key (id_luogo)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella PuntoCollegamento ###########################################################################################################################################
drop table if exists PuntoCollegamento;
create table PuntoCollegamento (
    id_collegamento int not null AUTO_INCREMENT,
    tipo varchar(255) not null,
    punto_cardinale char(2),
    collegamento1 int not null,
    collegamento2 int not null,

    primary key (id_collegamento),
    foreign key (collegamento1) references Luogo(id_luogo) on delete cascade,
    foreign key (collegamento2) references Luogo(id_luogo) on delete cascade,
    constraint CHECK_PuntoCollegamento_tipo check (tipo = 'Porta' or tipo = 'Finestra' or tipo = 'Portafinestra'),
    constraint CHECK_PuntoCollegamento_punto_cardinale check (punto_cardinale = 'N' or punto_cardinale = 'NE' or punto_cardinale = 'E' or punto_cardinale = 'SE' or punto_cardinale = 'S' or punto_cardinale = 'SW' or punto_cardinale = 'W' or punto_cardinale = 'NW')
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Esterno ###########################################################################################################################################
drop table if exists Esterno;
create table Esterno (
    luogo int not null,

    primary key (luogo),
    foreign key (luogo) references Luogo(id_luogo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Sensore ###########################################################################################################################################
drop table if exists SensoreEsterno;
create table SensoreEsterno (
    luogo int not null,
    `data` datetime not null,
    temperatura float not null, -- centigradi

    primary key (luogo, `data`),
    foreign key (luogo) references Esterno(luogo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Stanza ###########################################################################################################################################
drop table if exists Stanza;
create table Stanza (
    luogo int not null,
    altezza float not null, -- metri
    piano int not null,
    larghezza float not null, -- metri
    lunghezza float not null, -- metri
    dispersione int not null, -- watt / centigradi
    emergency_exit longtext,

    primary key (luogo),
    foreign key (luogo) references Luogo(id_luogo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Batteria ###########################################################################################################################################
drop table if exists Batteria;
create table Batteria (
    id_batteria int not null AUTO_INCREMENT,
    capienza int not null, -- Ampere-ora
    luogo int not null,
    carica int not null,

    primary key (id_batteria),
    foreign key (luogo) references Stanza(luogo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Sensore ###########################################################################################################################################
drop table if exists Sensore;
create table Sensore (
    stanza int not null,
    `data` datetime not null,
    temperatura float not null, -- centigradi

    primary key (stanza, `data`),
    foreign key (stanza) references Stanza(luogo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Sorgente ###########################################################################################################################################
drop table if exists Sorgente;
create table Sorgente (
    id_sorgente int not null AUTO_INCREMENT,
    tipo varchar(255),
    luogo int not null,

    primary key (id_sorgente),
    foreign key (luogo) references Esterno(luogo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Energia ###########################################################################################################################################
drop table if exists Energia;
create table Energia (
    sorgente int not null,
    data_variazione datetime not null,
    produzione int not null, -- watt

    primary key (sorgente, data_variazione),
    foreign key (sorgente) references Sorgente(id_sorgente) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Attivita ###########################################################################################################################################
drop table if exists Attivita;
create table Attivita (
    id_attivita int not null AUTO_INCREMENT,

    primary key (id_attivita)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Accesso ###########################################################################################################################################
drop table if exists Accesso;
create table Accesso (
    account_utente varchar(255) not null,
    id_attivita int not null,
    `data` datetime not null,

    primary key (account_utente,id_attivita),
    foreign key (account_utente) references Account(nome_utente) on delete cascade,
    foreign key (id_attivita) references Attivita(id_attivita) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Dispositivo ###########################################################################################################################################
drop table if exists Dispositivo;
create table Dispositivo (
    id_dispositivo int not null AUTO_INCREMENT,
    nome varchar(255) not null,
    stanza int not null,

    primary key (id_dispositivo),
    foreign key (stanza) references Stanza(luogo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella SmartPlug ###########################################################################################################################################
drop table if exists SmartPlug;
create table SmartPlug (
    id_smart_plug int not null AUTO_INCREMENT,
    dispositivo int,
    
    foreign key (dispositivo) references Dispositivo(id_dispositivo) on delete cascade,
    primary key (id_smart_plug)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Luce ###########################################################################################################################################
drop table if exists Luce;
create table Luce (
    id_dispositivo int not null,
    consumo int not null, -- watt

    primary key (id_dispositivo),
    foreign key (id_dispositivo) references Dispositivo(id_dispositivo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Scena ###########################################################################################################################################
drop table if exists Scena;
create table Scena (
    id_scena int not null AUTO_INCREMENT,
    nome varchar(255),

    primary key (id_scena)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Configurazione ###########################################################################################################################################
drop table if exists Configurazione;
create table Configurazione (
    id_dispositivo int not null,
    id_scena int not null,
    temperatura int not null, -- kelvin
    intensita int not null, -- percentuale

    primary key (id_dispositivo,id_scena),
    foreign key (id_dispositivo) references Luce(id_dispositivo) on delete cascade,
    foreign key (id_scena) references Scena(id_scena) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Toggle ###########################################################################################################################################
drop table if exists Toggle;
create table Toggle (
    id_dispositivo int not null,
    consumo int not null,

    primary key (id_dispositivo),
    foreign key (id_dispositivo) references Dispositivo(id_dispositivo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Ciclo ###########################################################################################################################################
drop table if exists Ciclo;
create table Ciclo (
    id_dispositivo int not null,

    primary key (id_dispositivo),
    foreign key (id_dispositivo) references Dispositivo(id_dispositivo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Variabile ###########################################################################################################################################
drop table if exists Variabile;
create table Variabile (
    id_dispositivo int not null,

    primary key (id_dispositivo),
    foreign key (id_dispositivo) references Dispositivo(id_dispositivo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Condizionatore ###########################################################################################################################################
drop table if exists Condizionatore;
create table Condizionatore (
    id_dispositivo int not null,

    primary key (id_dispositivo),
    foreign key (id_dispositivo) references Dispositivo(id_dispositivo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Programma ###########################################################################################################################################
drop table if exists Programma;
create table Programma (
    id_programma int not null AUTO_INCREMENT,
    tipo varchar(255) not null,
    durata int not null, -- minuti
    consumo int not null, -- watt / ora
    ciclo int not null,

    primary key (id_programma),
    foreign key (ciclo) references Ciclo(id_dispositivo) on delete cascade,
    unique (tipo, ciclo)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Potenza ###########################################################################################################################################
drop table if exists Potenza;
create table Potenza (
    id_potenza int not null AUTO_INCREMENT,
    consumo int not null, -- watt
    livello int not null,
    variabile int not null,

    primary key (id_potenza),
    foreign key (variabile) references Variabile(id_dispositivo) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella Impostazione ###########################################################################################################################################
drop table if exists Impostazione;
create table Impostazione (
    id_impostazione int not null AUTO_INCREMENT,
    ora_inizio time not null,
    ora_fine time not null,
    umidita int not null, -- percentuale
    temperatura int not null, -- centigradi
    condizionatore int not null,

    primary key (id_impostazione),
    foreign key (condizionatore) references Condizionatore(id_dispositivo) on delete cascade,
    constraint CHECK_Impostazione_umidita check (umidita between 0 and 100)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella AttivitaLuce ###########################################################################################################################################
drop table if exists AttivitaLuce;
create table AttivitaLuce (
    id_attivita int not null,
    luce int not null,
    stato tinyint not null,
    temperatura int not null,
    intensita int not null, -- percentuale
    data datetime not null,
    
    primary key (id_attivita),
    foreign key (id_attivita) references Attivita(id_attivita) on delete cascade,
    foreign key (luce) references Luce(id_dispositivo) on delete cascade,
    constraint CHECK_AttivitaLuce_stato check (stato between 0 and 1),
    constraint CHECK_AttivitaLuce_intensita check (intensita between 0 and 100)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella AttivitaToggle ###########################################################################################################################################
drop table if exists AttivitaToggle;
create table AttivitaToggle (
    id_attivita int not null,
    toggle int not null,
    stato tinyint not null,
    data datetime not null,
    
    primary key (id_attivita),
    foreign key (id_attivita) references Attivita(id_attivita) on delete cascade,
    foreign key (toggle) references Toggle(id_dispositivo) on delete cascade,
    constraint CHECK_AttivitaToggle_stato check (stato between 0 and 1)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella AttivitaCiclo ###########################################################################################################################################
drop table if exists AttivitaCiclo;
create table AttivitaCiclo (
    id_attivita int not null,
    ciclo int not null,
    programma int not null,
    data datetime not null,
    
    primary key (id_attivita),
    foreign key (id_attivita) references Attivita(id_attivita) on delete cascade,
    foreign key (ciclo) references Ciclo(id_dispositivo) on delete cascade,
    foreign key (programma) references Programma(id_programma) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella AttivitaVariabile ###########################################################################################################################################
drop table if exists AttivitaVariabile;
create table AttivitaVariabile (
    id_attivita int not null,
    variabile int not null,
    potenza int not null,
    data datetime not null,
    
    primary key (id_attivita),
    foreign key (id_attivita) references Attivita(id_attivita) on delete cascade,
    foreign key (variabile) references Variabile(id_dispositivo) on delete cascade,
    foreign key (potenza) references Potenza(id_potenza) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Tabella AttivitaCondizionatore ###########################################################################################################################################
drop table if exists AttivitaCondizionatore;
create table AttivitaCondizionatore (
    id_attivita int not null,
    condizionatore int not null,
    impostazione int not null,
    data_fine datetime,
    intervallo int, -- giorni
    data datetime not null,
    
    primary key (id_attivita),
    foreign key (id_attivita) references Attivita(id_attivita) on delete cascade,
    foreign key (condizionatore) references Condizionatore(id_dispositivo) on delete cascade,
    foreign key (impostazione) references Impostazione(id_impostazione) on delete cascade
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ###########################################################################################################################################
-- ###########################################################################################################################################

-- LogTable per il calcolo della carica delle batterie ###########################################################################################################################################
drop table if exists LogTableBatteria;
create table LogTableBatteria (
    sorgente int not null,
    data_variazione datetime not null, 
    produzione int not null,
    batteria int not null,
    uso_batteria tinyint,

    primary key (sorgente,data_variazione)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- tabella AbitudiniUtenti ###########################################################################################################################################
drop table if exists AbitudiniUtenti;
create table AbitudiniUtenti (
    id_dispositivo int,
    id_stanza int,
    giorno datetime,

    primary key (id_dispositivo, id_stanza, giorno)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



-- ###########################################################################################################################################
-- #####################                   ###################################################################################################
-- ##################### REDUNDANCY UPDATE ###################################################################################################
-- #####################                   ###################################################################################################
-- ###########################################################################################################################################

-- Procedura EmergencyExit ###########################################################################################################################################
drop procedure if exists EmergencyExit;
delimiter $$
create procedure EmergencyExit(in _id_stanza int, out _txt longtext)
begin

    declare counter int default 0; -- contatore che conta i passaggi fatti
    declare bad_end bool default false; -- vero se non ci sono vie di uscita
    declare good_end bool default false; -- vero se esiste una via di uscita
    declare check_value bool default false; -- controlla se _id_stanza è una stanza

    set check_value = _id_stanza in (
        select luogo
        from stanza
    );

    if check_value then

        -- tabella che contiene solo i luoghi che permettono una via di fuga dalla casa
        drop temporary table if exists MyExit;
        create temporary table MyExit as (
            select l.id_luogo
            from luogo l
            where l.nome = 'Giardino' or l.nome = 'Piazza'
        );

        -- tabella per i calcolo delle possibili strade per uscire dalla casa
        drop table if exists PathLength;
        create table PathLength(
            id_luogo int, -- stanza di riferimento
            pre_id_luogo int, -- stanza precedente
            distanza int, -- distanza percorsa
            msg longtext, -- messaggio contenente la mappa per uscire dalla stanza  _id_stanza
            primary key (id_luogo)
        );


        insert into PathLength
        select s.id_luogo, NULL, if(s.id_luogo = _id_stanza, 0, NULL), concat(s.nome, '(', s.id_luogo, ')')
        from luogo s;

        -- ######################################################################

        -- ripete finchè o non esiste una via di fuga o ne è stata trovata una
        repeat
            -- aggiornamento distanze
            replace into PathLength
            select d.id_luogo,
                   if(pll.distanza is null or pll.distanza >= d.distanza, d.pre_id_luogo, pll.pre_id_luogo),
                   if(pll.distanza is null or pll.distanza >= d.distanza, d.distanza, pll.distanza), pll.msg
            from (
                select pc.collegamento2 as id_luogo, pc.collegamento1 as pre_id_luogo, pl.distanza + 1 as distanza
                from PathLength pl
                    inner join puntocollegamento pc on pc.collegamento1 = pl.id_luogo
                where pl.distanza = counter
            ) as d
                inner join PathLength pll on pll.id_luogo = d.id_luogo;

            -- aggiornamento messaggio
            replace into PathLength
            select pl.id_luogo, pl.pre_id_luogo, pl.distanza, concat(pll.msg, ' -> ', l.nome, '(', pl.id_luogo, ')')
            from PathLength pl
                inner join pathlength pll on pl.pre_id_luogo = pll.id_luogo
                inner join luogo l on l.id_luogo = pl.id_luogo;

            set counter = counter + 1;

            set bad_end = not exists(
                select *
                from PathLength
                where distanza >= counter
            );

            set good_end = exists(
                select pl.pre_id_luogo
                from PathLength pl
                where pl.distanza is not null
                    and pl.id_luogo in (
                        select me.id_luogo
                        from MyExit me
                )
                order by pl.distanza
            );

        until bad_end or good_end

        end repeat;

        if good_end then
            set _txt = (
                select concat('Via di uscita: ', pl.msg)
                from PathLength pl
                where pl.distanza is not null
                    and pl.id_luogo in (
                        select me.id_luogo
                        from MyExit me
                )
                order by pl.distanza
                limit 1
            );
        else
            set _txt = 'Non esiste una via di uscita.';
        end if;

        drop table PathLength;
        drop temporary table MyExit;

    else
        set _txt = 'L''ID inserito non appartiene ad una stanza. ';
    end if ;

end $$
delimiter ;

drop procedure if exists EmergencyExit_ALL;
delimiter $$
create procedure EmergencyExit_ALL()
begin

    declare finito bool default false;
    declare tmp_id int default NULL;
    declare tmp_msg longtext default NULL;

    declare my_cursor cursor for
    select id_luogo
    from luogo;

    declare continue handler for not found set finito = true;

    -- drop temporary table if exists tmp;
    -- create temporary table tmp(
    --     id_stanza int,
    --     msg longtext,
    --     primary key (id_stanza)
    -- );

    open my_cursor;

    -- aggiornamento ridondanza emergency_exit in Stanza per ogni stanza
    scan: loop

        fetch my_cursor into tmp_id;

        if finito then
            leave scan;
        end if ;

        call EmergencyExit(tmp_id, tmp_msg);
        -- insert into tmp value (tmp_id, tmp_msg);

        update stanza
        set emergency_exit = tmp_msg
        where luogo = tmp_id;

    end loop ;

    close my_cursor;

end $$
delimiter ;





-- ###########################################################################################################################################
-- #####################         #############################################################################################################
-- ##################### UTILITY #############################################################################################################
-- #####################         #############################################################################################################
-- ###########################################################################################################################################

-- Function ProduzioneIstantanea #############################################################################################################
Drop function if exists ProduzioneIstantanea;
Delimiter $$
Create function ProduzioneIstantanea()
returns int deterministic
Begin
   
   Declare ProduzioneInst_ int default 0;
   
   Set ProduzioneInst_ =                -- alla variabile produzione istantanea viene assegnata la somma dei valori di produzione a cui è associata la data_variazione più grande, 
   (                                    -- ovvero il più recente, per ciascuna sorgente
      select sum(E.Produzione)
      from Energia E
      where E.Data_Variazione >= all
      (
         select E2.Data_Variazione
         from Energia E2
      )
   );
   
   Return ProduzioneInst_;
End $$
Delimiter ;

-- Function ConsumoDispositivo ###############################################################################################################
drop function if exists ConsumoDispositivo;
delimiter $$
create function ConsumoDispositivo(_dispositivo int, _instant datetime)
returns int deterministic
begin

    declare consumo_dis int default 0; -- valore di ritorno della funzione

    with MyLuce as ( -- consumo del _dispositivo se fosse una luce
        select d.id_dispositivo as dispositivo, (d.stato * d.consumo) as consumo
        from (
            select l.id_dispositivo, al.stato, l.consumo, al.data, ifnull(lead(al.data, 1) over(
                partition by l.id_dispositivo
                order by al.data
            ),now()) as attivita_successiva
            from Luce l
                inner join AttivitaLuce al on al.luce = l.id_dispositivo
            where l.id_dispositivo = _dispositivo
        ) as d
        where _instant between d.data and d.attivita_successiva
    ),
    MyToggle as ( -- consumo del _dispositivo se fosse un toggle
        select d.id_dispositivo as dispositivo, (d.stato * d.consumo) as consumo
        from (
            select t.id_dispositivo, att.stato, t.consumo, att.data, ifnull(lead(att.data, 1) over(
                partition by t.id_dispositivo
                order by att.data
            ), now()) as attivita_successiva
            from Toggle t
                inner join AttivitaToggle att on att.toggle = t.id_dispositivo
            where t.id_dispositivo = _dispositivo
        ) as d
        where _instant between d.data and d.attivita_successiva
    ),
    MyCiclo as ( -- consumo del _dispositivo se fosse un dispositivo a ciclo
        select d.ciclo as dispositivo, (_instant between d.data and addtime(d.data, SEC_TO_TIME(d.durata * 60))) * -- controlla se _instant ricade nel range temporale del programma del dispositivo a ciclo
            d.consumo as consumo
        from (
            select ac.ciclo, p.durata, p.consumo, ac.data, ifnull(lead(ac.data, 1) over(
                partition by ac.programma
                order by ac.data
            ), now()) as attivita_successiva
            from AttivitaCiclo ac
                inner join Programma p on p.id_programma = ac.programma
            where ac.ciclo = _dispositivo
        ) as d
        where _instant between d.data and d.attivita_successiva
    ),
    MyVariabile as ( -- consumo del _dispositivo se fosse un dispositivo variabile
        select d.variabile as dispositivo, d.consumo * (d.livello <> 0) as consumo -- se il livello è zero significhe che il dispositivo è spento
        from (
            select av.variabile, p.consumo, p.livello, av.data, ifnull(lead(av.data, 1) over(
                partition by av.variabile
                order by av.data
            ), now()) as attivita_successiva
            from AttivitaVariabile av
                inner join Potenza p on p.id_potenza = av.potenza 
            where av.variabile = _dispositivo
        ) as d
        where _instant between d.data and d.attivita_successiva
    ),
    MyCondizionatore as ( -- consumo del _dispositivo se fosse un condizionatore
        select c.id_dispositivo as dispositivo, (EfficienzaEnergeticaStanza(d.stanza, se.data) * abs(se.temperatura - i.temperatura)) * 
            (time(_instant) between i.ora_inizio and i.ora_fine) * -- controlla se _instant si trova nel periodo di esecuzione dell'impostazione
            (datediff(_instant, ac.Data) % ac.intervallo = 0) as consumo -- controlla se _instant si trova nel giorno dell'esecuzione dell'impostazione
        from AttivitaCondizionatore ac
            inner join Impostazione i on i.id_impostazione = ac.impostazione
            inner join Condizionatore c on c.id_dispositivo = ac.condizionatore
            inner join Dispositivo d on d.id_dispositivo = c.id_dispositivo
            inner join Stanza s on s.luogo = d.stanza
            inner join (
                select se.temperatura, se.stanza, se.data, ifnull(lead(se.data, 1) over(
                    partition by se.stanza
                    order by se.data
                ), now()) as attivita_successiva
                from Sensore se
            ) as se on se.stanza = s.luogo
            where c.id_dispositivo = _dispositivo
            and _instant between se.data and se.attivita_successiva
    )

    -- unisce tutto quello che ha trovato
    select ifnull(d.consumo, 0) into consumo_dis
    from (
        select consumo
        from MyLuce
        where dispositivo is not null

        union

        select consumo
        from MyToggle
        where dispositivo is not null

        union

        select consumo
        from MyCiclo mc
        where dispositivo is not null

        union

        select consumo
        from MyVariabile
        where dispositivo is not null

        union

        select consumo
        from MyCondizionatore
        where dispositivo is not null
    ) as d
    limit 1;

    return consumo_dis;

end $$
delimiter ;

-- Function ConsumoTot #######################################################################################################################
drop function if exists ConsumoTot;
delimiter $$
create function ConsumoTot(_instant datetime)
returns int not deterministic
begin

    declare consumo_tot int default 0; -- valore di ritorno

    with MyLuce as (
        select d.id_dispositivo as dispositivo, (d.stato * d.consumo) as consumo
        from (
            select l.id_dispositivo, al.stato, l.consumo, al.data, ifnull(lead(al.data, 1) over(
                partition by l.id_dispositivo
                order by al.data
            ),now()) as attivita_successiva
            from Luce l
                inner join AttivitaLuce al on al.luce = l.id_dispositivo
        ) as d
        where _instant between d.data and d.attivita_successiva
    ),
    MyToggle as (
        select d.id_dispositivo as dispositivo, (d.stato * d.consumo) as consumo
        from (
            select t.id_dispositivo, att.stato, t.consumo, att.data, ifnull(lead(att.data, 1) over(
                partition by t.id_dispositivo
                order by att.data
            ), now()) as attivita_successiva
            from Toggle t
                inner join AttivitaToggle att on att.toggle = t.id_dispositivo
        ) as d
        where _instant between d.data and d.attivita_successiva
    ),
    MyCiclo as (
        select d.ciclo as dispositivo, (_instant between d.data and addtime(d.data, SEC_TO_TIME(d.durata * 60))) * -- controlla se _instant ricade nel range temporale del programma del dispositivo a ciclo
            d.consumo as consumo 
        from (
            select ac.ciclo, p.durata, p.consumo, ac.data, ifnull(lead(ac.data, 1) over(
                partition by ac.programma
                order by ac.data
            ), now()) as attivita_successiva
            from AttivitaCiclo ac
                inner join Programma p on p.id_programma = ac.programma
        ) as d
        where _instant between d.data and d.attivita_successiva
    ),
    MyVariabile as (
        select d.variabile as dispositivo, d.consumo * (d.livello <> 0) as consumo -- se il livello è zero significhe che il dispositivo è spento
        from (
            select av.variabile, p.consumo, p.livello, av.data, ifnull(lead(av.data, 1) over(
                partition by av.variabile
                order by av.data
            ), now()) as attivita_successiva
            from AttivitaVariabile av
                inner join Potenza p on p.id_potenza = av.potenza
        ) as d
        where _instant between d.data and d.attivita_successiva
    ),
    MyCondizionatore as (
        select c.id_dispositivo as dispositivo, (EfficienzaEnergeticaStanza(d.stanza, se.data) * abs(se.temperatura - i.temperatura)) *
            (time(_instant) between i.ora_inizio and i.ora_fine) * -- controlla se _instant si trova nel periodo di esecuzione dell'impostazione
            (datediff(ac.Data, _instant) % ac.intervallo = 0) as consumo -- controlla se _instant si trova nel giorno dell'esecuzione dell'impostazione
        from AttivitaCondizionatore ac
            inner join Impostazione i on i.id_impostazione = ac.impostazione
            inner join Condizionatore c on c.id_dispositivo = ac.condizionatore
            inner join Dispositivo d on d.id_dispositivo = c.id_dispositivo
            inner join Stanza s on s.luogo = d.stanza
            inner join (
                select se.temperatura, se.stanza, se.data, ifnull(lead(se.data, 1) over(
                    partition by se.stanza
                    order by se.data
                ), now()) as attivita_successiva
                from Sensore se
            ) as se on se.stanza = s.luogo
            and _instant between se.data and se.attivita_successiva
    )

    -- unisce tutto e somma i consumi
    select ifnull(sum(d.consumo), 0) into consumo_tot
    from (
        select consumo
        from MyLuce
        where dispositivo is not null

        union

        select consumo
        from MyToggle
        where dispositivo is not null

        union

        select consumo
        from MyCiclo mc
        where dispositivo is not null

        union

        select consumo
        from MyVariabile
        where dispositivo is not null

        union

        select consumo
        from MyCondizionatore
        where dispositivo is not null
    ) as d;

    return consumo_tot;

end $$
delimiter ;

-- Function Broadcast ########################################################################################################################
drop function if exists Broadcast;
delimiter $$
create function Broadcast ( _Messaggio varchar(255), _IdDispositivo int)
returns tinyint deterministic
begin
   
    if _IdDispositivo = -1 then

        Insert into Notifica (messaggio,data,accettata,account_utente)
        Select _Messaggio,now(),0,nome_utente
        From Account;
    else
      
        Insert into Notifica (messaggio,data,accettata,account_utente,id_dispositivo)
        Select _Messaggio,now(),0,nome_utente,_IdDispositivo
        From Account;
    end if;  

   Return 0;

end $$
delimiter ;

-- Function EfficienzaEnergeticaStanza #######################################################################################################
drop function if exists EfficienzaEnergeticaStanza;
delimiter $$
create function EfficienzaEnergeticaStanza(_stanza int, _instant datetime)
returns float deterministic
begin

    declare efficienza float default 0; -- valore di ritorno

    with TemperaturaInt as ( -- temperatura interna alla _stanza all'istante _instant
        select d.temperatura, d.stanza
        from (
            select s.temperatura, s.data, s.stanza, ifnull(lead(s.data, 1) over(
                partition by s.stanza
                order by s.data
            ),now()) as data_successiva
            from Sensore s
            where s.stanza = _stanza
        ) as d
        where _instant between d.data and d.data_successiva
    ),
    TemperaturaEx as ( -- temperatura media esterna all'istante _instant
        select avg(d.temperatura) as temperatura
        from (
            select s.temperatura, s.data, ifnull(lead(s.data, 1) over(
                partition by s.luogo
                order by s.data
            ),now()) as data_successiva
            from SensoreEsterno s
        ) as d
        where _instant between d.data and d.data_successiva
    )

    -- 100: pessima efficienza energetica
    -- 0: ottima efficienza energetica
    select abs((100 / pow(1.05, avg(abs(ti.temperatura - te.temperatura) * s.dispersione))) - 100) into efficienza
    from TemperaturaInt ti
        inner join Stanza s on ti.stanza = s.luogo
        cross join TemperaturaEx te
    where s.luogo = _stanza;

    return efficienza;

end $$
delimiter ;

-- Function fascia_oraria_corrente #######################################################################################################

Drop function if exists fascia_oraria_corrente;
Delimiter $$
Create function fascia_oraria_corrente(DataVariazione datetime)
Returns int deterministic
begin
   
   Declare IdFasciaOraria_ int default 0;
   
   Set IdFasciaOraria_ =
      (
      Select FO.id_fascia_oraria
      From FasciaOraria FO
      Where time(FO.ora_inizio) < time(FO.ora_fine)
            and
            time(DataVariazione) >= time(FO.ora_inizio) and time(DataVariazione) < time(FO.ora_fine)
            and
            FO.data_attivazione <= DataVariazione
            and
            FO.data_attivazione >= all
               (
               Select FO2.data_attivazione
               From FasciaOraria FO2
               Where FO2.data_attivazione <= DataVariazione
               )
       );
       
       if IdFasciaOraria_ is null then
    set IdFasciaOraria_ =
       (
       Select FO3.id_fascia_oraria
       From FasciaOraria FO3
       where time(FO3.ora_inizio) > time(FO3.ora_fine)
             and
             (time(DataVariazione) >= time(FO3.ora_inizio) or time(DataVariazione) < time(FO3.ora_fine))
             and       
             FO3.data_attivazione <= DataVariazione
             and
             FO3.data_attivazione >= all
               (
               Select FO4.data_attivazione
               From FasciaOraria FO4
               Where FO4.data_attivazione <= DataVariazione
               )
      );
      end if;
      return IdFasciaOraria_;
    
End $$
Delimiter ;

-- ###########################################################################################################################################
-- #####################               #######################################################################################################
-- ##################### FUNCTIONALITY #######################################################################################################
-- #####################               #######################################################################################################
-- ###########################################################################################################################################

-- Procedure ConsumoCondizionatoreGiornaliero ################################################################################################ 
drop procedure if exists ConsumoCondizionatoreGiornaliero;
delimiter $$
create procedure ConsumoCondizionatoreGiornaliero(
    in _giorno date, in _condizionatore int,
    out consumo_condizionatore_giornaliero_ int
)
begin
    with myAttivita as (
        select ac.impostazione
        from AttivitaCondizionatore ac
        where (ac.data_fine > _giorno or ac.data_fine is null) -- se la data fine è successiva al _giorno o è un'attivita perpetua
            and datediff(ac.Data, _giorno) % ac.intervallo = 0 -- se il _giorno si trova nel giorno indicato dall'intervallo
            and ac.condizionatore = _condizionatore
    ), Temperature as (
        select EfficienzaEnergeticaStanza(d.stanza, se.data) as livello_efficienza_energetica, se.temperatura, se.data, ifnull(lead(se.data, 1) over(
                partition by d.stanza
                order by se.data
            ),now()) as attivita_successiva
        from Dispositivo d 
            inner join Stanza s on s.luogo = d.stanza
            inner join Sensore se on se.stanza = s.luogo
        where d.id_dispositivo = _condizionatore
            and date(se.data) = _giorno
    )
    select ifnull(sum(t.livello_efficienza_energetica * abs(t.temperatura - i.temperatura) * (time_to_sec(timediff(t.attivita_successiva, t.data))/3600) ), 0) into consumo_condizionatore_giornaliero_ -- per ogni temperatura calcolo il consumo istantaneo e poi sommo tutto
    from myAttivita ma 
        inner join Impostazione i on i.id_impostazione = ma.impostazione
        inner join Temperature t on (time(t.data) between i.ora_inizio and i.ora_fine);
end $$
delimiter ;

-- Procedure InfoLuci ########################################################################################################################
drop procedure if exists InfoLuci;
delimiter $$
create procedure InfoLuci()
begin

    select dd.luce, date(dd.data_off) as giorno, sum(
        time_to_sec(timediff(dd.data_on, dd.data_off)) / 3600
    ) as tempo_off_ore
    from (
        select al.luce, al.data as data_off, ifnull(lead(al.data, 1) over (
            partition by al.luce, date(al.data)
            order by date(al.data) -- ricavo la ora dello stato ON successivo allo stato OFF
            ), cast(date(al.data) as datetime) + interval 1 day) as data_on
        from AttivitaLuce al
        where al.stato = 0 -- stato luce == OFF
    ) as dd
    group by dd.luce, date(dd.data_off);
end $$
delimiter ;

-- Function ConsumoRange #####################################################################################################################
drop function if exists ConsumoRange;
delimiter $$
create function ConsumoRange(_instant1 datetime, _instant2 datetime)
returns int deterministic -- watt * minuto
begin

    declare consumo_tot int default 0;

    with consumo_luci as ( -- calcola tutti i consumi delle attività delle luci che rientrano nel range _instant1, _instant2
        select sum(d.stato * d.consumo * time_to_sec(timediff(if(d.data_succ > _instant2, d.data_succ, _instant2), d.data))/60) as consumo
        from (
            select l.id_dispositivo, al.stato, l.consumo, al.data, ifnull(lead(al.data, 1) over(
                partition by l.id_dispositivo
                order by al.data
            ),now()) as data_succ
            from Luce l
                inner join AttivitaLuce al on al.luce = l.id_dispositivo
        ) as d
        where d.data between _instant1 and _instant2
    ),
    consumo_toggle as ( -- calcola tutti i consumi delle attività dei toggle che rientrano nel range _instant1, _instant2
        select sum(d.stato * d.consumo * time_to_sec(timediff(if(d.data_succ > _instant2, d.data_succ, _instant2), d.data))/60) as consumo
        from (
            select t.id_dispositivo, att.stato, t.consumo, att.data, ifnull(lead(att.data, 1) over(
                partition by t.id_dispositivo
                order by att.data
            ), now()) as data_succ
            from Toggle t
                inner join AttivitaToggle att on att.toggle = t.id_dispositivo
        ) as d
        where d.data between _instant1 and _instant2
    ),
    consumo_ciclo as ( -- calcola tutti i consumi delle attività dei dispositivi a ciclo che rientrano nel range _instant1, _instant2
        select sum(d.durata * d.consumo) as consumo
        from (
            select ac.ciclo, p.durata, p.consumo, ac.data, ifnull(lead(ac.data, 1) over(
                partition by ac.programma
                order by ac.data
            ), now()) as data_succ
            from AttivitaCiclo ac
                inner join Programma p on p.id_programma = ac.programma
        ) as d
        where d.data between _instant1 and _instant2
    ),
    consumo_variabile as ( -- calcola tutti i consumi delle attività dei a consumo variabile che rientrano nel range _instant1, _instant2
        select sum(d.consumo * (d.livello <> 0) * time_to_sec(timediff(if(d.data_succ > _instant2, d.data_succ, _instant2), d.data))/60) as consumo
        from (
            select av.variabile, p.consumo, p.livello, av.data, ifnull(lead(av.data, 1) over(
                partition by av.variabile
                order by av.data
            ), now()) as data_succ
            from AttivitaVariabile av
                inner join Potenza p on p.id_potenza = av.potenza 
        ) as d
        where d.data between _instant1 and _instant2
    ),
    consumo_condizionatore as ( -- calcola tutti i consumi delle attività dei condizionatori che rientrano nel range _instant1, _instant2
        select sum(EfficienzaEnergeticaStanza(d.stanza, se.data) * abs(se.temperatura - i.temperatura)
            * (time_to_sec(timediff(if(se.data_succ > _instant2, se.data_succ, _instant2), se.data))/60) *
            (i.ora_inizio between time(_instant1) and time(_instant2) ) * -- bool
            (datediff(_instant1, ac.Data) % ac.intervallo = 0)) as consumo -- bool
        from AttivitaCondizionatore ac
            inner join Impostazione i on i.id_impostazione = ac.impostazione
            inner join Condizionatore c on c.id_dispositivo = ac.condizionatore
            inner join Dispositivo d on d.id_dispositivo = c.id_dispositivo
            inner join Stanza s on s.luogo = d.stanza
            inner join (
                select se.temperatura, se.stanza, se.data, ifnull(lead(se.data, 1) over(
                    partition by se.stanza
                    order by se.data
                ), now()) as data_succ
                from Sensore se
            ) as se on se.stanza = s.luogo
            where se.data between _instant1 and _instant2
    )

    -- somma tutto quello che ha trovato
    select ifnull(sum(consumo), 0) into consumo_tot
    from (
        select consumo
        from consumo_luci

        union all

        select consumo
        from consumo_toggle

        union all

        select consumo
        from consumo_ciclo

        union all

        select consumo
        from consumo_variabile

        union all

        select consumo
        from consumo_condizionatore
    ) as d;

    return consumo_tot;
end $$
delimiter ;

-- funzione StatoDispositivo ################################################################################################################
drop function if exists StatoDispositivo;
delimiter $$
create function StatoDispositivo(
    _dispositivo int
) returns bool not deterministic
begin

    declare stato_ bool default false; -- valore di ritorno

    with MyLuce as ( -- calcola lo stato del _dispositivo se fosse una luce
        select d.id_dispositivo as dispositivo, d.stato
        from (
            select l.id_dispositivo, al.stato, l.consumo, al.data, ifnull(lead(al.data, 1) over(
                partition by l.id_dispositivo
                order by al.data
            ),now()) as attivita_successiva
            from Luce l
                inner join AttivitaLuce al on al.luce = l.id_dispositivo
            where l.id_dispositivo = _dispositivo
        ) as d
        where now() between d.data and d.attivita_successiva
    ),
    MyToggle as ( -- calcola lo stato del _dispositivo se fosse un toggle
        select d.id_dispositivo as dispositivo, d.stato
        from (
            select t.id_dispositivo, att.stato, t.consumo, att.data, ifnull(lead(att.data, 1) over(
                partition by t.id_dispositivo
                order by att.data
            ), now()) as attivita_successiva
            from Toggle t
                inner join AttivitaToggle att on att.toggle = t.id_dispositivo
            where t.id_dispositivo = _dispositivo
        ) as d
        where now() between d.data and d.attivita_successiva
    ),
    MyCiclo as (  -- calcola lo stato del _dispositivo se fosse un dispositivo a ciclo
        select d.ciclo as dispositivo, (now() between d.data and addtime(d.data, d.durata)) as stato
        from (
            select ac.ciclo, p.durata, p.consumo, ac.data, ifnull(lead(ac.data, 1) over(
                partition by ac.programma
                order by ac.data
            ), now()) as attivita_successiva
            from AttivitaCiclo ac
                inner join Programma p on p.id_programma = ac.programma
            where ac.ciclo = _dispositivo
        ) as d
        where now() between d.data and d.attivita_successiva
    ),
    MyVariabile as (  -- calcola lo stato del _dispositivo se fosse un dispositivo a consumo variabile
        select d.variabile as dispositivo, (d.livello <> 0) as stato
        from (
            select av.variabile, p.consumo, p.livello, av.data, ifnull(lead(av.data, 1) over(
                partition by av.variabile
                order by av.data
            ), now()) as attivita_successiva
            from AttivitaVariabile av
                inner join Potenza p on p.id_potenza = av.potenza 
            where av.variabile = _dispositivo
        ) as d
        where now() between d.data and d.attivita_successiva
    ),
    MyCondizionatore as ( -- calcola lo stato del _dispositivo se fosse un condizionatore
        select c.id_dispositivo as dispositivo, (
                (time(now()) between i.ora_inizio and i.ora_fine) * -- bool
                (datediff(now(), ac.Data) % ac.intervallo = 0) -- bool
            ) as stato
        from AttivitaCondizionatore ac
            inner join Impostazione i on i.id_impostazione = ac.impostazione
            inner join Condizionatore c on c.id_dispositivo = ac.condizionatore
            where c.id_dispositivo = _dispositivo
    )

    -- unisce tutto quello che ha trovato
    select ifnull(stato,0) into stato_
    from (
        select stato
        from MyLuce
        where dispositivo is not null

        union

        select stato
        from MyToggle
        where dispositivo is not null

        union

        select stato
        from MyCiclo
        where dispositivo is not null

        union

        select stato
        from MyVariabile
        where dispositivo is not null

        union

        select stato
        from MyCondizionatore
        where dispositivo is not null
    )as d
    limit 1;

    return stato_;

end $$
delimiter ;

-- Procedure Carica_Batteria_MANUAL #################################################################################################################
Drop Procedure If Exists Carica_Batteria_MANUAL;
Delimiter $$
Create Procedure Carica_Batteria_MANUAL()
    Begin
    
    Declare caricaBatteria int default 0;
    Declare capienzaBatteria int default 0;
    Declare Nrecord int default 0;
    Declare TempProduzioneMenoConsumo int default 0;
    Declare contatore int default 1;
    
    drop temporary table if exists risultati;
    
    create temporary table risultati (
       ordine int not null default 0,
       data_variazione datetime not null,
       produzione_meno_consumo int not null default 0,
    
       primary key(ordine)
    );
    
    insert into risultati
       
       with energia_target as
       (
          Select E.sorgente,
                 E.data_variazione,
                 E.Produzione,
                 fascia_oraria_corrente(E.data_variazione) as id_fascia_oraria
                 
          From Energia E
          Where E.data_variazione > now() - interval 80 minute
       ),
       logtable_produzione_intervallo as 
       (
          Select ET.sorgente,
                 ET.data_variazione,
                 ET.produzione as produzione_intervallo,
                 IFO.batteria,
                 IFO.uso_batteria
          From energia_target ET
               inner join
               ImpostazioneFasciaOraria IFO
               on IFO.id_fascia_oraria = ET.id_fascia_oraria
       ),
       produzione_sorgenti_e_consumo as
       (
          Select LPI.data_variazione,
                 sum(LPI.produzione_intervallo) as produzione_totale_intervallo,
                 LPI.batteria,
                 LPI.uso_batteria,
                 ConsumoRange(LPI.data_variazione,LPI.data_variazione + interval 30 minute) as consumo
           From logtable_produzione_intervallo LPI
           Group by LPI.data_variazione
        )
       
       Select rank() over(order by PSC.data_variazione) as ordine,
              PSC.data_variazione,
              (PSC.produzione_totale_intervallo * PSC.batteria/100 - PSC.uso_batteria * PSC.consumo) as produzione_meno_consumo
       From produzione_sorgenti_e_consumo PSC;
     
     Set caricaBatteria = 
    (
       Select sum(carica/100 * capienza)
       From Batteria
    );
    
    Set capienzaBatteria = 
    (
       Select sum(capienza)
       From Batteria
    );
    
    set Nrecord = 
    (
       Select count(*)
       From risultati
    );
    
    carica:loop
       if contatore > Nrecord then
       
          leave carica;
       
       end if;
       
       Set TempProduzioneMenoConsumo =
       (
          Select produzione_meno_consumo
          From risultati
          Where ordine = contatore
       );
       
       if caricaBatteria + TempProduzioneMenoConsumo >= capienzaBatteria then
             
          Set caricaBatteria = capienzaBatteria;
          
       elseif caricaBatteria + TempProduzioneMenoConsumo <= 0 then
             
          Set caricaBatteria = 0;
          
       else
             
          Set caricaBatteria = caricaBatteria + TempProduzioneMenoConsumo;
          
       end if;
          
       Set contatore = contatore + 1;
       
    end loop carica;
    
    Update Batteria
    Set carica = capienza * caricaBatteria/capienzaBatteria;
    
end $$    
delimiter ;

-- Procedure InserimentoFasciaOraria ed Event EliminazioneFasciaOraria #################################################################################################################

drop procedure if exists InserimentoFasciaOraria;
delimiter $$
create procedure InserimentoFasciaOraria (IN _OraInizio time,IN _OraFine time,IN  _Retribuzione int,IN _Prezzo int,IN _NomeUtente varchar(255),IN _Casa int,IN _Batteria int,IN _Rete int,IN _UsoBatteria tinyint)
begin
   
   declare finito tinyint default 0;
   declare contatoreRecord int default 0;
   
   if _Casa + _Batteria + _Rete <> 100 then
      signal sqlstate '45000'
      set message_text = 'La somma tra la corrente inviata alla casa, alla batteria e alla rete deve fare 100';
   elseif
      _NomeUtente not in 
         (
         select nome_utente
         from Account
         )
   then
      signal sqlstate '45000'
      set message_text = 'il nome utente inserito non esiste';
   end if;
   
   
   Set contatoreRecord =
   (
      Select count(*)
      From FasciaOraria
   );
   
   if exists ( -- impedisce l'inserimento di fasce orarie che si sovrappongono interamente a fasce orarie inserite in precedenza
      
      Select *
      From FasciaOraria
      Where Data_Attivazione > now()
            and
            ((Ora_Inizio >= _OraInizio and Ora_Inizio < _OraFine)
            or
            (_OraFine < _OraInizio
            and
            (Ora_Inizio < _OraFine or Ora_Inizio >= _OraInizio)))
            and
            ((Ora_Fine > _OraInizio and Ora_Fine <= _OraFine)
            or
            (_OraFine < _OraInizio
            and
            (Ora_Fine <= _OraFine or Ora_Fine > _OraInizio)))
   )
   
   then 
      
      insert into Notifica
      values ("la fascia oraria inserita non è valida perchè si sovrappone ad un'altra inserita in precedenza",0,_NomeUtente);
      
   elseif exists( -- impedisce l'inserimento di fasce orarie contenute interamente in una fascia oraria inserita in precedenza
     
     Select *
      From FasciaOraria
      Where Data_Attivazione > now()
            and
            ((_OraInizio > Ora_Inizio and _OraInizio < Ora_Fine)
            or
            (Ora_Fine < Ora_Inizio
            and
            (_OraInizio < Ora_Fine or _OraInizio > Ora_Inizio)))
            and
            ((_OraFine > Ora_Inizio and _OraFine < Ora_Fine)
            or
            (Ora_Fine < Ora_Inizio
            and
            (_OraFine < Ora_Fine or _OraFine > Ora_Inizio)))
   )
   
   then 
   
      insert into Notifica
      values ("quella fascia oraria è già coperta",0,_NomeUtente);
   
   end if;
   
   Set _OraInizio = ifnull(  -- se l'utente inserisce una orainizio che si sovrappone ad una fascia oraria esistente, questa viene aggiustata
   (
      select Ora_Fine
      from FasciaOraria
      where data_Attivazione > now()
            and
            ((Ora_Fine between _OraInizio and _OraFine)
            or
            (_OraFine < _OraInizio
            and
            (Ora_Fine < _OraFine or Ora_Fine > _OraInizio))) 
   ),_OraInizio);
   
   Set _OraFine = ifnull( -- se l'utente inserisce una orafine che si sovrappone ad una fascia oraria esistente, questa viene aggiustata
   (
      select Ora_Inizio
      from FasciaOraria
      where data_Attivazione > now()
            and
            ((Ora_Inizio between _OraInizio and _OraFine)
            or
            (_OraFine < _OraInizio
            and
            (Ora_Inizio < _OraFine or Ora_Inizio > _OraInizio))) 
   ),_OraFine);
   
   
   if exists -- non viene permesso l'inserimento di fasce orarie che non abbiano orainizio o orafine uguali ad una fascia oraria esistente, viene fatta un'eccezione per la prima fascia oraria da inserire
   (
      Select *
      From FasciaOraria
      Where Data_Attivazione > now()
   )
   
   then
      
      if( (_OraInizio <> all(Select Ora_Fine From FasciaOraria)) and (_OraFine <> all(Select Ora_Inizio From FasciaOraria)) )
      
      then 
         
         insert into Notifica
         values ("la fascia oraria deve avere orainizio/orafine uguale ad orafine/orainizio di una fascia oraria già esistente",0,_NomeUtente);
      end if;
   
   end if;
   
   if exists -- se la fascia oraria inserita ha orainizio e orafine uguali ad una fascia oraria esistente, viene segnalato il completamento del set di fasce orarie
   (
      Select *
      From fasciaOraria
      Where Data_Attivazione > now()
            and
            _OraInizio = Ora_Fine
   )
   
   then 
      
      if exists
      (
         Select *
         From FasciaOraria
         Where Data_Attivazione > now()
               and
               _OraFine = Ora_Inizio
      )
      then
      set finito = 1;
      end if;
    end if;
   
   
  
   
   if finito = 1 then
     Update FasciaOraria
     Set data_attivazione = now() + interval 1 day
     Where data_attivazione > now();
     insert into Notifica
         values ("set di fasce orarie inserito correttamente",0,_NomeUtente);
   end if;
   
   insert into FasciaOraria
   values (contatoreRecord + 1,_OraInizio,_OraFine,_Retribuzione,_Prezzo,_NomeUtente,now() + interval 1 day);
   
   insert into ImpostazioneFasciaOraria
   values (contatoreRecord + 1,_Casa,_Batteria,_Rete,_UsoBatteria);
end $$
delimiter ;

Delimiter $$
Create event if not exists  EliminazioneFasciaOraria
on schedule every 1 day
starts '2021-12-12 23:55:00'
do begin
         
         Delete from FasciaOraria
         where data_attivazione > now() + interval 1 day;
         
         Delete from ImpostazioneFasciaOraria
         where id_fascia_oraria in
         (
            select id_fascia_oraria
            from FasciaOraria
            where data_attivazione > now() + interval 1 day        
         );
end $$
 
delimiter ;

-- Procedure ModificaFasceOrarie #############################################################################################################

Delimiter $$

Create Procedure ModificaFasceOrarie(IN _OraInizio time, IN _OraFine time, IN _Retribuzione float, IN _Prezzo float, IN _NomeUtente varchar(255),IN _Casa int, IN _Batteria int, IN _Rete int, IN _UsoBatteria tinyint)
begin
   Declare ContatoreRecord int default 0;
   
   Set ContatoreRecord =
        (
           Select Count(*)
           From FasciaOraria
        );
    
   if ContatoreRecord = 0 then
      signal sqlstate '45000'
      set message_text = 'non esistono fasce orarie da modificare';
    
   elseif _Casa + _Batteria + _Rete <> 100 then
      signal sqlstate '45000'
      set message_text = 'La somma tra la corrente inviata alla casa, alla batteria e alla rete deve fare 100';
   elseif
      _NomeUtente not in 
         (
         select nome_utente
         from Account
         )
   then
      signal sqlstate '45000'
      set message_text = 'il nome utente inserito non esiste';
      
   else
      create temporary table if not exists NuovaFasciaOrariaEImpostazione(
         _Id_fascia_Oraria int default 0,
         Ora_Inizio time not null,
         Ora_Fine time not null,
         Retribuzione float not null,
         Prezzo float not null,
         Account_Utente varchar(100) not null,
         Data_Attivazione datetime not null,
         Casa int not null,
         Batteria int not null,
         Rete int not null,
         Uso_Batteria tinyint not null,
         primary key(Ora_Inizio,Data_Attivazione)
         ) Engine=InnoDB Default charset = latin1;
         
         truncate table NuovaFasciaOrariaEImpostazione;
         
         insert into FasciaOraria
            select 1000,_OraFine,FODM.Ora_Fine,FODM.Retribuzione,FODM.Prezzo,FODM.Account_Utente,FODM.Data_Attivazione
            from 
            (
               select *
               from FasciaOraria FO
                    natural join
                    ImpostazioneFasciaOraria
               where FO.data_attivazione >= all
               (
                  select FO2.data_attivazione
                  from FasciaOraria FO2
               )
            ) FODM
            where ((_OraInizio between FODM.Ora_Inizio and FODM.Ora_Fine)
                  or
                  FODM.Ora_Fine < FODM.Ora_Inizio
                  and
                  (_OraInizio < FODM.Ora_Fine or _OraInizio > FODM.Ora_Inizio))
                  and
                  ((_OraFine between FODM.Ora_Inizio and FODM.Ora_Fine)
                  or
                  FODM.Ora_Fine < FODM.Ora_Inizio
                  and
                  (_OraFine < FODM.Ora_Fine or _OraFine > FODM.Ora_Inizio)); 
                  
        insert into ImpostazioneFasciaOraria
           select 1000,Casa,Batteria,Rete,Uso_Batteria
           from ImpostazioneFasciaOraria
           where Id_Fascia_Oraria in
           (
           select Id_Fascia_Oraria
           from
           (
               select *
               from FasciaOraria FO
                    natural join
                    ImpostazioneFasciaOraria
               where FO.data_attivazione >= all
               (
                  select FO2.data_attivazione
                  from FasciaOraria FO2
               )
            ) FODM
            where ((_OraInizio between FODM.Ora_Inizio and FODM.Ora_Fine)
                  or
                  FODM.Ora_Fine < FODM.Ora_Inizio
                  and
                  (_OraInizio < FODM.Ora_Fine or _OraInizio > FODM.Ora_Inizio))
                  and
                  ((_OraFine between FODM.Ora_Inizio and FODM.Ora_Fine)
                  or
                  FODM.Ora_Fine < FODM.Ora_Inizio
                  and
                  (_OraFine < FODM.Ora_Fine or _OraFine > FODM.Ora_Inizio))
           );
         
         
        insert into NuovaFasciaOrariaEImpostazione (Ora_Inizio,Ora_Fine,Retribuzione,Prezzo,Account_Utente,Data_Attivazione,Casa,Batteria,Rete,Uso_Batteria)
        values (_OraInizio,_OraFine,_Retribuzione,_Prezzo,_NomeUtente,now() + interval 1 Day,_Casa,_Batteria,_Rete,_UsoBatteria);
         
        insert into NuovaFasciaOrariaEImpostazione (Ora_Inizio,Ora_Fine,Retribuzione,Prezzo,Account_Utente,Data_Attivazione,Casa,Batteria,Rete,Uso_Batteria)
        

         with FasciaOrariaDaModificare as 
         (
            select *
            from FasciaOraria FO
                 natural join
                 ImpostazioneFasciaOraria
            where FO.data_attivazione >= all
            (
               select FO2.data_attivazione
               from FasciaOraria FO2
            )
         ),
         IdFasciaOrariaDaTogliere as 
         (
            select FODM.Id_Fascia_Oraria
            from FasciaOrariaDaModificare FODM
            where ((FODM.Ora_Inizio between _OraInizio and _OraFine)
                  or
                  _OraFine < _OraInizio
                  and
                  (FODM.Ora_Inizio < _OraFine or FODM.Ora_Inizio > _OraInizio))
                  and
                  ((FODM.Ora_Fine between _OraInizio and _OraFine)
                  or
                  _OraFine < _OraInizio
                  and
                  (FODM.Ora_Fine < _OraFine or FODM.Ora_Fine > _OraInizio)) 
         )
        
        select FODM.Ora_Inizio,FODM.Ora_Fine,FODM.Retribuzione,FODM.Prezzo,FODM.Account_Utente,now() + interval 1 day,FODM.Casa,FODM.Batteria,FODM.Rete,FODM.Uso_Batteria
        from FasciaOrariaDaModificare FODM
        where FODM.Id_Fascia_Oraria not in 
            (
               Select *
               From IdFasciaOrariaDaTogliere
            );
            
        Delete from FasciaOraria
        where data_attivazione > now()
              or
              Id_Fascia_Oraria = 1000;
              
        
        Delete from ImpostazioneFasciaOraria
        where id_fascia_oraria in 
           (
           select FO.id_fascia_oraria
           from FasciaOraria FO
           where data_attivazione > now()
                 or
                 Id_Fascia_Oraria = 1000
           ); 
           
        Set ContatoreRecord =
        (
           Select Count(*)
           From FasciaOraria
        );
           
        insert into FasciaOraria
           select Rank() over(order by Data_Attivazione,Ora_inizio) + ContatoreRecord as Id_Fascia_Oraria,Ora_Inizio,Ora_Fine,Retribuzione,Prezzo,Account_Utente,Data_Attivazione
           from NuovaFasciaOrariaEImpostazione;
                
        Select * From FasciaOraria;
        
        Insert into ImpostazioneFasciaOraria
           Select Rank() over(order by Data_Attivazione,Ora_inizio) + ContatoreRecord,Casa,Batteria,Rete,Uso_Batteria
           From NuovaFasciaOrariaEImpostazione;
           
        
           Update FasciaOraria
           Set Ora_Fine = _OraInizio
           Where Data_Attivazione > now() 
                 and
                 ((_OraInizio > Ora_Inizio and _OraInizio < Ora_Fine)
                  or
                  (Ora_Fine < Ora_Inizio
                  and
                  (_OraInizio < Ora_Fine or _OraInizio > Ora_Inizio)));
              
        
           Update FasciaOraria
           Set Ora_Inizio = _OraFine
           Where Data_Attivazione > now()
                 and
                  ((_OraFine > Ora_Inizio and _OraFine < Ora_Fine)
                  or
                  (Ora_Fine < Ora_Inizio
                  and
                  (_OraFine < Ora_Fine or _OraFine > Ora_Inizio)));
    

        drop table NuovaFasciaOrariaEImpostazione;
        
        end if;
end $$

delimiter ;

-- Procedure RegistrazioneUtente #############################################################################################################
drop procedure if exists RegistrazioneUtente;
delimiter $$
create procedure RegistrazioneUtente(
    in _nome_utente varchar(50), in _password varchar(50), in _domanda_sicurezza varchar(255), in _risposta_sicurezza varchar(255), in _codice_fiscale varchar(17),
    in _nome varchar(50), in _cognome varchar(50), in _data_nascita date, in _telefono varchar(255),
    in _tipologia_documento varchar(255), in _numero_documento varchar(50), in _scadenza_documento date, in _ente_rilascio_documento varchar(255)
)
begin

    declare check_codice_fiscale boolean default FALSE; -- controlla la validità del codice fiscale
    declare check_scadenza_documento boolean default FALSE; -- controlla la validità del documento

    set check_codice_fiscale = _codice_fiscale REGEXP '([B-DF-HJ-NP-TV-Z]{3})([B-DF-HJ-NP-TV-Z]{3})(0[1-9]|1[0-2])([A-Z])(0[1-9]|[12][0-9]|3[01])([0-9A-Z]{4})([A-Z])';
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

-- Procedure AttivazioneScena ################################################################################################################
-- Attivazione Scena Luci

drop procedure if exists AttivazioneScena;
delimiter $$
create procedure AttivazioneScena(in _scena int)
begin

    declare numero_attivita int default 0;
    declare ultima_attivita int default 0;

    set numero_attivita = ( -- calcola il numero di attività che dovrà aggiungere
        select count(*)
        from Configurazione
        where id_scena = _scena
    );

    set ultima_attivita = ( -- calcola l'ultima attività registrata
        select id_attivita
        from Attivita
        order by id_attivita desc
        limit 1
    );

    insert into Attivita
    select row_number() over () + ultima_attivita
    from configurazione c
    where c.id_scena = _scena;

    insert into attivitaluce -- inserisce in attivitaluce tutte le informazione contenute in configurazione
    select row_number() over () + ultima_attivita, c.id_dispositivo, 1, c.temperatura, c.intensita, now()
    from configurazione c
    where c.id_scena = _scena;

end $$
delimiter ;

-- Procedure CreazioneAttivitaCiclo ###########################################################################################################################################
drop procedure if exists CreazioneAttivitaCiclo;
delimiter $$
create procedure CreazioneAttivitaCiclo(
in _nome_utente varchar(255), in _ciclo int, in _tipo varchar(255), in _data datetime
) begin

    -- Dichiarazione Variabili
    declare check_data boolean default FALSE; -- controlla se la _data è valida
    declare error_data varchar(255) default ''; -- messaggio di errore

    declare check_nome_utente boolean default FALSE; -- controlla se il _nome_utente è valido
    declare error_nome_utente varchar(255) default ''; -- messaggio di errore

    declare check_dispositvo boolean default FALSE; -- controlla se _ciclo è un dispositivo a ciclo
    declare error_dispositivo varchar(255) default ''; -- messaggio di errore

    declare check_tipo boolean default FALSE; -- controlla se il tipo di programma _tipo esiste ed appartiene a _ciclo
    declare error_tipo varchar(255) default ''; -- messaggio di errore

    declare id_attivita_var int default 0; -- variabile di appoggio
    declare id_programma_var int default 0; -- variabile di appoggio

    -- Errore Data
    set check_data = _data >= now(); -- controlla se la _data è valida
    if not check_data then
        select concat('La data ', _data, ' non è valida') into error_data;
        signal sqlstate '45000'
        set message_text = error_data;
    end if;

    -- Errore Utente
    set check_nome_utente = exists( -- controlla se il _nome_utente è valido
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
    set check_dispositvo = exists( -- controlla se _ciclo è un dispositivo a ciclo
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
    set check_tipo = exists( -- controlla se il tipo di programma _tipo esiste ed appartiene a _ciclo
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

-- Procedure CreazioneAttivitaCondizionatore #################################################################################################

drop procedure if exists CreazioneAttivitaCondizionatore;
delimiter $$
create procedure CreazioneAttivitaCondizionatore(
in _nome_utente varchar(255), in _condizionatore int, in _id_impostazione int, in _data datetime, in _data_fine datetime, in _intervallo int
) begin

    -- Dichiarazione Variabili
    declare check_data boolean default FALSE; -- controlla se _data è una data valida
    declare error_data varchar(255) default ''; -- messaggio di errore

    declare check_nome_utente boolean default FALSE; -- controlla se _nome_utente è un utente registrato
    declare error_nome_utente varchar(255) default ''; -- messaggio di errore

    declare check_dispositvo boolean default FALSE; -- controlla se il dispositivo _condizionatore è un condizionatore
    declare error_dispositivo varchar(255) default ''; -- messaggio di errore

    declare check_id_impostazione boolean default FALSE; -- controlla se l'impostazione _id_impostazione esiste ed appartiene a _condizionatore
    declare error_id_impostazione varchar(255) default ''; -- messaggio di errore

    declare id_attivita_var int default 0; -- variabile di appoggio

    -- Errore Data
    set check_data = _data >= now(); -- controlla se _data è una data valida
    if not check_data then
        select concat('La data ', _data, ' non è valida') into error_data;
        signal sqlstate '45000'
        set message_text = error_data;
    end if;

    -- Errore Utente
    set check_nome_utente = exists( -- controlla se _nome_utente è un utente registrato
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
    set check_dispositvo = exists( -- controlla se il dispositivo _condizionatore è un condizionatore
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
    set check_id_impostazione = exists( -- controlla se l'impostazione _id_impostazione esiste ed appartiene a _condizionatore
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

-- Procedure CreazioneAttivitaLuce ###########################################################################################################
drop procedure if exists CreazioneAttivitaLuce;
delimiter $$
create procedure CreazioneAttivitaLuce(
in _nome_utente varchar(255), in _luce int, in _stato tinyint, in _temperatura int, in _intensita int, in _data datetime
) begin

    -- Dichiarazione Variabili
    declare check_data boolean default FALSE; -- controlla se _data è una data valida
    declare error_data varchar(255) default ''; -- messaggio di errore

    declare check_nome_utente boolean default FALSE; -- controlla se _nome_utente è un utente registrato
    declare error_nome_utente varchar(255) default ''; -- messaggio di errore

    declare check_dispositvo boolean default FALSE; -- controlla se _luce esiste ed è una luce
    declare error_dispositivo varchar(255) default ''; -- messaggio di errore

    declare id_attivita_var int default 0; -- variabile di appoggio

    -- Errore Data
    set check_data = _data >= now(); -- controlla se _data è una data valida
    if not check_data then
        select concat('La data ', _data, ' non è valida') into error_data;
        signal sqlstate '45000'
        set message_text = error_data;
    end if;

    -- Errore Utente
    set check_nome_utente = exists( -- controlla se _nome_utente è un utente registrato
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
    set check_dispositvo = exists( -- controlla se _luce esiste ed è una luce
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
    if not _stato then -- se _stato è OFF allora sia _temperatura che _intensita devono essere a 0
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

-- Procedure CreazioneAttivitaToggle #########################################################################################################
drop procedure if exists CreazioneAttivitaToggle;
delimiter $$
create procedure CreazioneAttivitaToggle(
in _nome_utente varchar(255), in _toggle int, in _stato tinyint, in _data datetime
) begin

    -- Dichiarazione Variabili
    declare check_data boolean default FALSE; -- controlla che _data sia una data valida
    declare error_data varchar(255) default ''; -- messaggio di errore

    declare check_nome_utente boolean default FALSE; -- controlla che _nome_utente si un utente registrato
    declare error_nome_utente varchar(255) default ''; -- messaggio di errore

    declare check_dispositvo boolean default FALSE; -- controlla che _toggle sia un dispositivo toggle
    declare error_dispositivo varchar(255) default ''; -- messaggio di errore

    declare id_attivita_var int default 0;

    -- Errore Data
    set check_data = _data >= now(); -- controlla che _data sia una data valida
    if not check_data then
        select concat('La data ', _data, ' non è valida') into error_data;
        signal sqlstate '45000'
        set message_text = error_data;
    end if;

    -- Errore Utente
    set check_nome_utente = exists( -- controlla che _nome_utente si un utente registrato
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
    set check_dispositvo = exists( -- controlla che _toggle sia un dispositivo toggle
        select *
        from Toggle
        where id_dispositivo = _toggle
    );
    if not check_dispositvo then
        select concat('Il dispositivo toggle ', _toggle, ' non esiste.') into error_dispositivo;
        signal sqlstate '45000'
        set message_text = error_dispositivo;
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

    insert into AttivitaToggle
    value (id_attivita_var, _toggle, _stato, _data);

end $$
delimiter ;

-- Procedure CreazioneAttivitaVariabile ######################################################################################################
drop procedure if exists CreazioneAttivitaVariabile;
delimiter $$
create procedure CreazioneAttivitaVariabile(
in _nome_utente varchar(255), in _variabile int, in _livello int, in _data datetime
) begin

    -- Dichiarazione Variabili
    declare check_data boolean default FALSE; -- controlla che _data sia una data valida
    declare error_data varchar(255) default ''; -- messaggio di errore

    declare check_nome_utente boolean default FALSE; -- controlla se _nome_utente è un utente registrato
    declare error_nome_utente varchar(255) default ''; -- messaggio di errore

    declare check_dispositvo boolean default FALSE; -- controlla se _variabile sia un dispositivo a consumo variabile
    declare error_dispositivo varchar(255) default ''; -- messaggio di errore

    declare check_potenza boolean default FALSE; -- controlla il livello di potenza _livello esiste ed appartiene a _variabile 
    declare error_potenza varchar(255) default ''; -- messaggio di errore

    declare id_attivita_var int default 0; -- variabile di appoggio
    declare id_potenza_var int default 0; -- variabile di appoggio

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

-- Event PuliziaDatabase #####################################################################################################################
-- Drop event if exists PuliziaDatabase;
-- Delimiter $$
-- Create Event PuliziaDatabase
-- on schedule every 1 day
-- starts '2021-12-12 23:55:00'
-- do
--   begin
--   Delete from Energia 
--   Where data_variazione < now() - interval 1 month; 
   
--   Delete from Sensore
--   Where data < now() - interval 1 month;
   
--   Delete from SensoreEsterno
--   Where data < now() - interval 1 month;
   
--   Delete from Attivita 
--   Where id_attivita in
--   (
--      Select id_attivita
--      From Accesso
--      Where data < now() - interval 1 month
--   );
   
--   Delete from Notifica
--   Where data < now() - interval 1 month;
   
--   end $$
   
-- Delimiter $$

-- Procedure Statistiche_MANUAL #####################################################################################################################

Drop procedure if exists Statistiche_MANUAL;
Delimiter $$
Create procedure Statistiche_MANUAL()
begin 
   
   select Broadcast(concat('Oggi le tue sorgenti hanno prodotto ',
                          ifnull(
                                   (
                                      Select round(avg(E.Produzione),2)
                                      From Energia E
                                      Where E.data_variazione > now() - interval 1 day

                                   ),
                                0
                                ),
                           ' W, di cui ',
                           ifnull(
                                    (
                                       Select round(avg(E.Produzione * IFO.rete/100),2)
                                       From Energia E
                                            Natural join
                                            ImpostazioneFasciaOraria IFO
                                       Where E.data_variazione > now() - interval 1 day
                                    ),
                                 0
                                 ),
                           ' W sono andati nella rete pubblica, per cui hai guadagnato ',
                           ifnull(
                                    (
                                       Select round(avg(E.Produzione * IFO.rete/100 * FO.retribuzione),1)
                                       From Energia E
                                            Natural join
                                            FasciaOraria FO
                                            Natural join
                                            ImpostazioneFasciaOraria IFO
                                       Where E.data_variazione > now() - interval 1 day
                                    ),
                                 0
                                 ),
                           ' Euro'
                           ), 
                  -1 
                  );
   
end $$

Delimiter ;

-- ###########################################################################################################################################
-- #####################                ######################################################################################################
-- ##################### BUSINESS RULES ######################################################################################################
-- #####################                ######################################################################################################
-- ###########################################################################################################################################

-- Trigger PuntoCollegamentoTBI ##############################################################################################################
drop trigger if exists PuntoCollegamentoTBI; -- TBI = trigger before insert
delimiter $$
create trigger PuntoCollegamentoTBI
before insert on PuntoCollegamento for each row
begin

    declare check_collegamento boolean default FALSE;
    declare error_collegamento varchar(255) default '';

    declare check_tipo boolean default FALSE;
    declare error_tipo varchar(255) default '';

    declare check_punto_cardinale_porta boolean default FALSE;
    declare check_punto_cardinale_finestra boolean default FALSE;
    declare error_punto_cardinale varchar(255) default '';

    set check_collegamento = new.collegamento1 <> new.collegamento2;
    if not check_collegamento then
        select concat('Una ', new.tipo, ' non può collegare una stanza con la stessa stanza.') into error_collegamento;
        signal sqlstate '45000'
        set message_text = error_collegamento;
    end if;

    set check_tipo = new.tipo = 'Porta' or new.tipo = 'Finestra' or new.tipo = 'Portafinestra';
    if not check_tipo then
        select concat('Il tipo del Punto di Collegamento ', new.id_collegamento, ' non è valido, i possibili valori sono: ''Porta'', ''Finestra'', '' Portafinestra''') into error_tipo;
        signal sqlstate '45000'
        set message_text = error_tipo;
    end if;

    set check_punto_cardinale_porta = new.tipo = 'Porta' and new.punto_cardinale is null;
    set check_punto_cardinale_finestra = (new.tipo = 'Finestra' or new.tipo = 'Portafinestra')
        and (new.punto_cardinale = 'N' or new.punto_cardinale = 'NE' or new.punto_cardinale = 'E' or new.punto_cardinale = 'SE' or new.punto_cardinale = 'S' or new.punto_cardinale = 'SW' or new.punto_cardinale = 'W' or new.punto_cardinale = 'NW');

    if new.tipo = 'Porta' and not check_punto_cardinale_porta then
        select concat('Il Punto di Collegamento ', new.tipo, ' non ha un punto cardinale di rifermento e quindi il suo valore deve essere NULL.') into error_punto_cardinale;
        signal sqlstate '45000'
        set message_text = error_punto_cardinale;
    elseif (new.tipo = 'Finestra' or new.tipo = 'Portafinestra') and not check_punto_cardinale_finestra then
        select concat('Il Punto di Collegamento ', new.tipo, ' deve avere un punto cardinale di rifermento (''N'', ''NE'', ''E'', ''SE'', ''S'', ''SW'', ''W'', ''NW'')') into error_punto_cardinale;
        signal sqlstate '45000'
        set message_text = error_punto_cardinale;
    end if;

end $$
delimiter ;

-- Trigger PuntoCollegamentoTBU ##############################################################################################################
drop trigger if exists PuntoCollegamentoTBU; -- TBU = trigger before update
delimiter $$
create trigger PuntoCollegamentoTBU
before update on PuntoCollegamento for each row
begin

    declare check_collegamento boolean default FALSE;
    declare error_collegamento varchar(255) default '';

    declare check_tipo boolean default FALSE;
    declare error_tipo varchar(255) default '';

    declare check_punto_cardinale_porta boolean default FALSE;
    declare check_punto_cardinale_finestra boolean default FALSE;
    declare error_punto_cardinale varchar(255) default '';

    set check_collegamento = new.collegamento1 <> new.collegamento2;
    if not check_collegamento then
        select concat('Una ', new.tipo, ' non può collegare una stanza con la stessa stanza.') into error_collegamento;
        signal sqlstate '45000'
        set message_text = error_collegamento;
    end if;

    set check_tipo = new.tipo = 'Porta' or new.tipo = 'Finestra' or new.tipo = 'Portafinestra';
    if not check_tipo then
        select concat('Il tipo del Punto di Collegamento ', new.id_collegamento, ' non è valido, i possibili valori sono: ''Porta'', ''Finestra'', '' Portafinestra''') into error_tipo;
        signal sqlstate '45000'
        set message_text = error_tipo;
    end if;

    set check_punto_cardinale_porta = new.tipo = 'Porta' and new.punto_cardinale is null;
    set check_punto_cardinale_finestra = (new.tipo = 'Finestra' or new.tipo = 'Portafinestra')
        and (new.punto_cardinale = 'N' or new.punto_cardinale = 'NE' or new.punto_cardinale = 'E' or new.punto_cardinale = 'SE' or new.punto_cardinale = 'S' or new.punto_cardinale = 'SW' or new.punto_cardinale = 'W' or new.punto_cardinale = 'NW');

    if new.tipo = 'Porta' and not check_punto_cardinale_porta then
        select concat('Il Punto di Collegamento ', new.tipo, ' non ha un punto cardinale di rifermento e quindi il suo valore deve essere NULL.') into error_punto_cardinale;
        signal sqlstate '45000'
        set message_text = error_punto_cardinale;
    elseif (new.tipo = 'Finestra' or new.tipo = 'Portafinestra') and not check_punto_cardinale_finestra then
        select concat('Il Punto di Collegamento ', new.tipo, ' deve avere un punto cardinale di rifermento (''N'', ''NE'', ''E'', ''SE'', ''S'', ''SW'', ''W'', ''NW'')') into error_punto_cardinale;
        signal sqlstate '45000'
        set message_text = error_punto_cardinale;
    end if;

end $$
delimiter ;

-- ###########################################################################################################################################
-- #####################                ######################################################################################################
-- ##################### Data Analytics ######################################################################################################
-- #####################                ######################################################################################################
-- ###########################################################################################################################################

-- Data Analytics 1: AbitudiniUtenti e NotificaAbitudini ################################################################################################

drop procedure if exists AbitudiniUtenti_FULL;
delimiter $$
create procedure AbitudiniUtenti_FULL()
begin

    truncate abitudiniutenti;

    insert into AbitudiniUtenti
    select d.id_dispositivo, d.stanza, k.data as giorno
    from (
        select p.id_dispositivo, p.data
        from (
            select al.id_attivita, al.luce as id_dispositivo, al.data
            from attivitaluce al

            union

            select att.id_attivita, att.toggle as id_dispositivo, att.data
            from AttivitaToggle att

            union

            select ac.id_attivita, ac.ciclo as id_dispositivo, ac.data
            from AttivitaCiclo ac

            union

            select av.id_attivita, av.variabile as id_dispositivo, av.data
            from AttivitaVariabile av
        ) as p
    ) as k
        inner join Dispositivo d on k.id_dispositivo = d.id_dispositivo
        inner join Stanza s on s.luogo = d.stanza;


end $$
delimiter ;

drop procedure if exists AbitudiniUtenti_PARTIAL;
delimiter $$
create procedure AbitudiniUtenti_PARTIAL(in _id_attivita int)
begin

    insert into AbitudiniUtenti
    select d.id_dispositivo, d.stanza, k.data as giorno
    from (
        select p.id_dispositivo, p.data
        from (
            select al.id_attivita, al.luce as id_dispositivo, al.data
            from attivitaluce al

            union

            select att.id_attivita, att.toggle as id_dispositivo, att.data
            from AttivitaToggle att

            union

            select ac.id_attivita, ac.ciclo as id_dispositivo, ac.data
            from AttivitaCiclo ac

            union

            select av.id_attivita, av.variabile as id_dispositivo, av.data
            from AttivitaVariabile av
        ) as p
        where p.id_attivita = _id_attivita
    ) as k
        inner join Dispositivo d on k.id_dispositivo = d.id_dispositivo
        inner join Stanza s on s.luogo = d.stanza;

end $$
delimiter ;

-- TRIGGERS

drop trigger if exists AbitudiniUtenti_TRIGGER_TOGGLE;
create trigger AbitudiniUtenti_TRIGGER_TOGGLE after insert on attivitatoggle
for each row call AbitudiniUtenti_PARTIAL(new.id_attivita);

drop trigger if exists AbitudiniUtenti_TRIGGER_LUCE;
create trigger AbitudiniUtenti_TRIGGER_LUCE after insert on attivitaluce
for each row call AbitudiniUtenti_PARTIAL(new.id_attivita);

drop trigger if exists AbitudiniUtenti_TRIGGER_CICLO;
create trigger AbitudiniUtenti_TRIGGER_CICLO after insert on attivitaciclo
for each row call AbitudiniUtenti_PARTIAL(new.id_attivita);

drop trigger if exists AbitudiniUtenti_TRIGGER_VARIABILE;
create trigger AbitudiniUtenti_TRIGGER_VARIABILE after insert on attivitavariabile
for each row call AbitudiniUtenti_PARTIAL(new.id_attivita);


-- ############################################################################################################




drop procedure if exists NotificaAbitudini_MANUAL;
delimiter $$
create procedure NotificaAbitudini_MANUAL()
begin

    declare pruning_PeriodAnalytics float default 0.11; -- utilizzata come variabile di potatura dei valori superflui
    declare pruning_DeviceAnalytics float default 0.3; -- utilizzata come variabile di potatura dei valori superflui

    declare _supporto_ int default 0; -- utilizzata come variabile temporanea nel DeviceAnalytics e nel PeriodAnalitics

    declare txt text default ''; -- variabile temporane per il messaggio

    -- PeriodAnalytics #################################################################################################
    -- analisi della frequenza dei dispositivi che vngono avviati peridiocamente
    drop table if exists PeriodAnalytics;
    create table PeriodAnalytics (
        id_dispositivo int,
        giorno_settimana int,
        ora int,
        confidenza float,
        primary key (id_dispositivo, giorno_settimana, ora)
    );


    insert into PeriodAnalytics
    select d.id_dispositivo, d.giorno_settimana, d.ora, count(*)/d.FreqA as confidenza
    from (
        select ab.id_dispositivo, ab.id_stanza, weekday(ab.giorno) as giorno_settimana, hour(ab.giorno) as ora, count(*) over(partition by ab.id_dispositivo, id_stanza) as FreqA
        from abitudiniutenti ab
    ) as d
    group by d.id_dispositivo, d.id_stanza, d.giorno_settimana, d.ora
    order by count(*) desc;

    -- DeviceAnalytics #################################################################################################

    -- Dispositivi che vengono avviati insieme
    drop table if exists TogetherDevice;
    create table TogetherDevice as (
        select d.gruppo, d.id_dispositivo, count(*) as frequenza
        from (
            select dense_rank() over (
                order by date(ab.giorno), hour(ab.giorno), ab.id_stanza
            ) as gruppo, ab.id_dispositivo, ab.id_stanza
            from abitudiniutenti ab
        ) as d
        group by d.gruppo, d.id_dispositivo
    );

    -- analisi della frequenza dei dispositivi che vengono avviati insieme
    drop table if exists DeviceAnalytics;
    create table DeviceAnalytics (
        id_disposito_main int,
        id_dispositivo_reference int,
        confidenza float,
        primary key (id_disposito_main, id_dispositivo_reference)
    );


    insert into DeviceAnalytics
        with CrossDevice as (
        select cd1.id_dispositivo as id_disposito_main, cd2.id_dispositivo as id_dispositivo_reference, cd2.frequenza
        from TogetherDevice cd1
            inner join TogetherDevice cd2 on cd1.gruppo = cd2.gruppo
    )
    select d.id_disposito_main, d.id_dispositivo_reference, count(*)/d.freqA as confidenza
    from (
          select cd.id_disposito_main, cd.id_dispositivo_reference, count(*) over(partition by cd.id_disposito_main) as freqA
          from CrossDevice cd
          where cd.id_disposito_main <> cd.id_dispositivo_reference
    ) as d
    group by d.id_disposito_main, d.id_dispositivo_reference
    order by d.id_disposito_main;

    -- ############################################################################################################

     -- invio notifiche

    select concat('Potresti voler avviare: ', d.disposito_main, ', ', group_concat(d.dispositivo_reference separator ', ')) into txt
    from (
        select concat(d2.nome, ' (', da.id_disposito_main, ')') as disposito_main, concat(d1.nome, ' (', da.id_dispositivo_reference, ')') as dispositivo_reference
        from PeriodAnalytics pa
            inner join DeviceAnalytics da on da.id_disposito_main = pa.id_dispositivo
            inner join dispositivo d1 on d1.id_dispositivo = da.id_dispositivo_reference
            inner join dispositivo d2 on d2.id_dispositivo = da.id_disposito_main
        where pa.ora = hour(now())
            and pa.giorno_settimana = weekday(current_date)
            and pa.confidenza >= pruning_PeriodAnalytics -- potatura
            and pa.confidenza >= pruning_DeviceAnalytics -- potatura
    ) as d;

    select Broadcast(txt, -1);
    select txt;

    select *
    from DeviceAnalytics
    where confidenza >= pruning_DeviceAnalytics
    order by confidenza desc ;

    select *
    from PeriodAnalytics
    where confidenza >= pruning_PeriodAnalytics
    order by confidenza desc ;


    drop table TogetherDevice;
    drop table PeriodAnalytics;
    drop table DeviceAnalytics;


end $$
delimiter ;

Drop event if exists NotificaAbitudini;
delimiter $$
Create event NotificaAbitudini
on schedule every 3 hour
starts STR_TO_DATE(CONCAT(current_date(), ' 06:00:00'), '%Y-%m-%d %H:%i:%s') do
begin
    if hour(now()) between 6 and 24 then
        call NotificaAbitudini_MANUAL();
    end if ;
end $$
delimiter ;

-- Data Analytics 2: OttimizzazioneConsumi ################################################################################################


Drop function if exists PeriodAnalytics;
delimiter $$
Create function PeriodAnalytics(_data datetime)
returns int not deterministic
begin
    declare ret int default 0;


    select d.id_dispositivo into ret
    from (
        select ab.id_dispositivo, ab.id_stanza, weekday(ab.giorno) as giorno_settimana, hour(ab.giorno) as ora, count(*) over(partition by ab.id_dispositivo, id_stanza) as FreqA
        from abitudiniutenti ab
    ) as d
    where weekday(_data) = d.giorno_settimana and hour(_data) = d.ora and StatoDispositivo(d.id_dispositivo) = 0
    group by d.id_dispositivo, d.id_stanza, d.giorno_settimana, d.ora
    order by count(*) desc
    limit 1;

    return ret;

end $$
delimiter ;


 -- ############################################################################################################


Drop Procedure if exists OttimizzazioneConsumi_MANUAL; 

Delimiter $$

Create Procedure OttimizzazioneConsumi_MANUAL()
   
   Begin
   
   Declare ContatoreDispositiviPocoUsati integer default 0;
   Declare TempIdDispositivo integer default 0;
   Declare TempConsumo integer default 0;
   Declare TempDurata integer default 0;
   Declare TempProgramma varchar(255);
   Declare IdDispositivoConsigliato integer default 0;
   Declare Produzione integer default 0;
   Declare Consumo integer default 0;
   Declare CaricaBatteria integer default 0;
   Declare ImmissioneBatteria integer default 0;
   Declare UsoBatteria tinyint default 0;
   
   Drop temporary table if exists risultati;
   
   Create temporary table risultati
      (
      
      with DispositiviACicloPocoUsati as    -- questa cte contiene i dispositivi a ciclo non interrompibile che non sono stati utilizzati da più di un giorno
     (
        select distinct C.id_dispositivo
        from AttivitaCiclo AC
             right outer join
             Ciclo C
             on AC.Ciclo = C.id_dispositivo
	    where AC.Data is null 
              or
              (
			     AC.Data is not null 
                 and
                 Datediff(current_date(),AC.Data) > 1 
			  )
     ),
     DispositiviEProgrammiIdonei as    -- questa cte contiene i dispositivi a ciclo non interrompibile che hanno un programma che può essere completato entro le 18 
     (                                 -- (si presume che la produzione elettrica dopo le 18 cali drasticamente per via del tramonto del sole)
        select rank() over (order by P.Durata Desc,P.Consumo Desc) as ordine,
               DAC.id_dispositivo,
               P.Consumo,
               P.Durata,
               P.Tipo
        from  DispositiviACicloPocoUsati DAC
              inner join
              Programma P
              on P.ciclo = DAC.id_dispositivo
              
        where 18 - hour(now()) - minute(now())/60 > P.durata/60
	          and 
              hour(now()) + minute(now())/60 - 6 > P.durata/60
     )
     
	  Select DPI.id_dispositivo,DPI.consumo,DPI.durata,DPI.tipo
      From DispositiviEProgrammiIdonei DPI
      Where DPI.ordine = 1
    );  
    
   Set TempIdDispositivo = 
   (
      Select R.id_dispositivo
      From risultati R
   );
   
    Set TempConsumo = 
   (
      Select R.consumo
      From risultati R
   );
   
    Set TempDurata = 
   (
      Select R.durata
      From risultati R
   );
   
    Set TempProgramma = 
   (
      Select R.tipo
      From risultati R
   );
   
   Set CaricaBatteria = 
   (
      Select sum(carica)
      From Batteria
   );
   
   set ContatoreDispositiviPocoUsati =    -- qui viene calcolato il numero di dispositivi a ciclo non interrompibile che non vengono utilizzati da un giorno o più
	 (
		select count(distinct C.id_dispositivo)
        from AttivitaCiclo AC
             right outer join
             Ciclo C
             on AC.Ciclo = C.id_dispositivo
	    where AC.Data is null 
              or
              (
			     AC.Data is not null 
                 and
                 Datediff(current_date(),AC.Data) > 1 
			  )
     );
   
   Set UsoBatteria =   -- prende l'usobatteria della fasciaoraria corrente
   (
      Select IFO.uso_batteria
      From ImpostazioneFasciaOraria IFO
      Where IFO.id_fascia_oraria = 
                              (
                                 Select distinct fascia_oraria_corrente(E.data_variazione)
                                 From Energia E
                                 Where E.data_variazione >= all 
															 (
                                                                Select E2.data_variazione
                                                                From Energia E2
                                                             )
                              
                              )
	 
   );
   
   Set Produzione = ProduzioneIstantanea();
   
   Set ImmissioneBatteria =  UsoBatteria * CaricaBatteria;

   Set Consumo = ConsumoTot(now());
   
   Set IdDispositivoConsigliato = PeriodAnalytics(now());
   
   Case
		
      when(Produzione - Consumo < 200 and Produzione - Consumo > - 200) then
		   
	     Set Produzione = Produzione + Broadcast(concat('L''efficienza energetica al momento è alta'),-1);
		
	  when(Produzione - Consumo < 400 and Produzione - Consumo >= 200) then
        
		 Set Produzione = Produzione + Broadcast(concat('L''efficienza energetica al momento è media',
																	', potresti voler attivare il dispositivo ',
																	(
																	   Select D.Nome
																	   From Dispositivo D
																	   Where D.id_dispositivo = IdDispositivoConsigliato
																	),
																	' che si trova in ',
																	(
																	   Select L.Nome 
																	   From Luogo L 
																		    inner join 
																		    Dispositivo D 
																		    on L.id_luogo = D.stanza
																	   Where D.id_dispositivo = IdDispositivoConsigliato
																	)
																   ),IdDispositivoConsigliato
															);
                                                                
	  when(Produzione - Consumo < -200 and Produzione - Consumo > -400) then
		   
	     Set Produzione = Produzione + Broadcast(concat('L''efficienza energetica al momento è media'),-1);
           
	  when(Produzione - Consumo >= 400) then
		   
		 Set Produzione = Produzione + Broadcast(concat('L''efficienza energetica al momento è bassa',
																	  ', potresti voler attivare il dispositivo ',
                                                                      (
																         Select D.Nome
																		 From Dispositivo D
																		 Where D.id_dispositivo = IdDispositivoConsigliato
																	   ),
                                                                       ' che si trova in ',
																	   (
																	      Select L.Nome 
																		  From Luogo L 
																			   inner join 
																			   Dispositivo D 
																			   on L.id_luogo = D.stanza
																		  Where D.id_dispositivo = IdDispositivoConsigliato
																	   )
                                                                      ),IdDispositivoConsigliato
																);
	      
          if ContatoreDispositiviPocoUsati <> 0 then                                                            
    
             if Produzione + ImmissioneBatteria - Consumo - TempConsumo > TempConsumo/100 * 30 
                and
                18 - hour(now()) - minute(now())/60 > TempDurata/60
		        and 
		        hour(now()) + minute(now())/60 - 6 > TempDurata/60
              
			 then          -- se c'e abbastanza produzione da permettere l'avvio di un programma di un dispositivo a ciclo non interrompibile
                           -- senza ricorrere al prelievo di energia dalla rete, allora viene consigliato all'utente di avviare il programma in questione
             Set Produzione = Produzione + Broadcast(concat('Puoi avviare il programma ', 
																		  TempProgramma,
                                                                          ' del dispositivo ',
                                                                          (
																	         Select Nome 
																			 From Dispositivo 
																		     Where id_dispositivo = TempIdDispositivo
																		  ), 
                                                                          ' che si trova in ', 
																		  (
																		     Select L.Nome 
																			 From Luogo L 
																				  inner join 
																				  Dispositivo D 
																				  on L.id_luogo = D.stanza
																			 Where D.id_dispositivo = TempIdDispositivo
																		   )
							                                             ),TempIdDispositivo
																 );
           
		      end if;

	     end if;
         
	  when(Produzione - Consumo <= -400) then
        
	     Set Produzione = Produzione + Broadcast(concat('L''efficienza energetica al momento è bassa',
                                                                      ' stai prelevando ',
                                                                      - (Produzione + ImmissioneBatteria - Consumo),
                                                                      ' W dalla rete'
                                                                     ),-1);
      else begin end;     
	  End case;
                                                                    
End $$
Delimiter ;

Drop event if exists OttimizzazioneConsumi;  -- event ogni ora dopo il calcolo della batteria, solo dalle 6 alle 18
delimiter $$
Create event OttimizzazioneConsumi
on schedule every 3 hour
starts STR_TO_DATE(CONCAT(current_date(), ' 06:00:00'), '%Y-%m-%d %H:%i:%s') do
begin
    if hour(now()) between 6 and 18 then
        call OttimizzazioneConsumi_MANUAL();
    end if ;
end $$
delimiter ;
