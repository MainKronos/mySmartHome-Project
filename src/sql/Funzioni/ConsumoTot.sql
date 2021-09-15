-- Calcolo consumo istantaneo di tutti i dispositivi

drop function if exists ConsumoTot;
delimiter $$
create function ConsumoTot(_instant datetime)
returns int not deterministic
begin

    declare consumo_tot int default 0;

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
        select d.ciclo as dispositivo, (_instant between d.data and addtime(d.data, d.durata)) * d.consumo as consumo
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
        select d.variabile as dispositivo, d.consumo * (d.livello <> 0) as consumo
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
            (time(_instant) between i.ora_inizio and i.ora_fine) * -- bool
            (datediff(ac.Data, _instant) % ac.intervallo = 0) as consumo -- bool
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

    select sum(d.consumo) into consumo_tot
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

select ConsumoTot('2020-06-01 18:30:00');