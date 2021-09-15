drop procedure if exists NotificaAbitudini_MANUAL;
delimiter $$
create procedure NotificaAbitudini_MANUAL()
begin

    declare pruning_PeriodAnalytics float default 0.3; -- utilizzata come variabile di potatura dei valori superflui
    declare pruning_DeviceAnalytics float default 0.0085; -- utilizzata come variabile di potatura dei valori superflui

    declare _supporto_ int default 0; -- utilizzata come variabile temporanea nel DeviceAnalytics e nel PeriodAnalitics

    declare txt text default ''; -- variabile temporane per il messaggio

    -- Dispositivi che vengono avviati peridiocamente ogni settimana alla stessa ora
    drop table if exists PeriodicDevice;
    create table PeriodicDevice as (
        select ab.id_dispositivo, id_stanza, weekday(ab.giorno) as giorno_settimana, hour(ab.giorno) as ora, count(*) as frequenza
        from abitudiniutenti ab
        group by ab.id_dispositivo, id_stanza, weekday(ab.giorno), hour(ab.giorno)
        order by count(*) desc
    );

    -- Dispositivi che vengono avviati insieme
    drop table if exists TogetherDevice;
    create table TogetherDevice as (
        select dense_rank() over (
            order by date(ab.giorno), hour(ab.giorno), ab.id_stanza
        ) as gruppo, ab.id_dispositivo, ab.id_stanza
        from abitudiniutenti ab
    );


    -- PeriodAnalytics #################################################################################################
    -- analisi della frequenza dei dispositivi che vngono avviati peridiocamente
    drop table if exists PeriodAnalytics;
    create table PeriodAnalytics (
        id_dispositivo int,
        giorno_settimana int,
        ora int,
        frequenza int,
        supporto int,
        primary key (id_dispositivo, giorno_settimana, ora)
    );

    set _supporto_ = (
        select max(frequenza)
        from PeriodicDevice
    );

    insert into PeriodAnalytics
    select id_dispositivo, giorno_settimana, ora, frequenza, _supporto_
    from PeriodicDevice;

    -- DeviceAnalytics #################################################################################################
    -- analisi della frequenza dei dispositivi che vengono avviati insieme
    drop table if exists DeviceAnalytics;
    create table DeviceAnalytics (
        id_disposito_main int,
        id_dispositivo_reference int,
        frequenza int,
        supporto int,
        primary key (id_disposito_main, id_dispositivo_reference)
    );

    set _supporto_ = (
        select max(gruppo)
        from TogetherDevice
    );


    insert into DeviceAnalytics
    with CrossDevice as (
        select td.gruppo, td.id_dispositivo
        from TogetherDevice td
    )
    select cd1.id_dispositivo as id_disposito_main, cd2.id_dispositivo as id_dispositivo_reference, count(*) as frequenza, _supporto_ as supporto
    from CrossDevice cd1
        inner join CrossDevice cd2 on cd1.gruppo = cd2.gruppo
    where cd1.id_dispositivo <> cd2.id_dispositivo
    group by cd1.id_dispositivo, cd2.id_dispositivo
    order by cd1.id_dispositivo;

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
            and (pa.frequenza / pa.supporto) >= pruning_PeriodAnalytics -- potatura
            and (da.frequenza / da.supporto) >= pruning_DeviceAnalytics -- potatura
    ) as d;

    select Broadcast(txt, -1);
    select txt;


    drop table PeriodicDevice;
    drop table TogetherDevice;
    drop table PeriodAnalytics;
    drop table DeviceAnalytics;


end $$
delimiter ;

Drop event if exists NotificaAbitudini;
Create event NotificaAbitudini
on schedule every 1 hour
starts '2021-12-12 23:55:00' do call NotificaAbitudini_MANUAL();


# call NotificaAbitudini_MANUAL();