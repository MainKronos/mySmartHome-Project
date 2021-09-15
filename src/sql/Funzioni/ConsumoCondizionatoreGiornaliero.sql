-- stima i consumi derivanti da una determinata impostazione relativa a un elemento di condizionamento per un dato giorno, in base anche alla considerazione (o alla stima) dell’energia prodotta.

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
    select sum(t.livello_efficienza_energetica * abs(t.temperatura - i.temperatura) * (time_to_sec(timediff(t.attivita_successiva, t.data))/3600) ) into consumo_condizionatore_giornaliero_ -- per ogni temperatura calcolo il consumo istantaneo e poi sommo tutto
    from myAttivita ma 
        inner join Impostazione i on i.id_impostazione = ma.impostazione
        inner join Temperature t on (time(t.data) between i.ora_inizio and i.ora_fine);
end $$
delimiter ;

call ConsumoCondizionatoreGiornaliero('2020-06-01', 195, @tmp);
select @tmp;