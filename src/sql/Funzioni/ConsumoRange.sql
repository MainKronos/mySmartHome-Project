-- Consumo totale dei dispositivi in un range dato

drop function if exists ConsumoRange;
delimiter $$
create function ConsumoRange(_instant1 datetime, _instant2 datetime)
returns int deterministic
begin

    declare consumo_tot int default 0;

   with consumo_luci as (
        select sum(d.stato * d.consumo * time_to_sec(timediff(if(d.data_succ > _instant2, d.data_succ, _instant2), d.data))/3600) as consumo
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
    consumo_toggle as (
        select sum(d.stato * d.consumo * time_to_sec(timediff(if(d.data_succ > _instant2, d.data_succ, _instant2), d.data))/3600) as consumo
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
    consumo_ciclo as (
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
    consumo_variabile as (
        select sum(d.consumo * (d.livello <> 0) * time_to_sec(timediff(if(d.data_succ > _instant2, d.data_succ, _instant2), d.data))/3600) as consumo
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
    consumo_condizionatore as (
        select sum(EfficienzaEnergeticaStanza(d.stanza, se.data) * abs(se.temperatura - i.temperatura)
            * (time_to_sec(timediff(if(se.data_succ > _instant2, se.data_succ, _instant2), se.data))/3600) *
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
#
        select consumo
        from consumo_condizionatore
    ) as d;

    return consumo_tot;
end $$
delimiter ;

select ConsumoRange('2020-06-01 02:41:55','2020-06-05 02:45:08');