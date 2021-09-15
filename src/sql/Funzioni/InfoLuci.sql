-- Il DB deve rendere anche possibile capire quali elementi di illuminazione vengono mantenuti spenti, in quali giorni, e per quanto tempo.

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

call InfoLuci();