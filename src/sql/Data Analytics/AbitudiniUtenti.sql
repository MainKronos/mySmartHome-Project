drop table if exists AbitudiniUtenti;
create table AbitudiniUtenti (
	id_dispositivo int,
	id_stanza int,
	ora_inizio time,
	giorno date,

	primary key (id_dispositivo, id_stanza, ora_inizio, giorno)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

drop procedure if exists AbitudiniUtenti_FULL;
delimiter $$
create procedure AbitudiniUtenti_FULL()
begin

    truncate abitudiniutenti;

    insert into AbitudiniUtenti
    select d.id_dispositivo, d.stanza, time(k.data) as ora_inizio, date(k.data) as giorno
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
#     having count(*) > 3


end $$
delimiter ;

drop procedure if exists AbitudiniUtenti_PARTIAL;
delimiter $$
create procedure AbitudiniUtenti_PARTIAL(in _id_attivita int)
begin

    insert into AbitudiniUtenti
    select d.id_dispositivo, d.stanza, time(k.data) as ora_inizio, date(k.data) as giorno_settimana
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