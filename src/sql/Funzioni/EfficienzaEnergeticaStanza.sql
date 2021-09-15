drop function if exists EfficienzaEnergeticaStanza;
delimiter $$
create function EfficienzaEnergeticaStanza(_stanza int, _instant datetime)
returns float deterministic
begin

	declare efficienza float default 0;

	with TemperaturaInt as (
        select d.temperatura
        from (
            select s.temperatura, s.data, ifnull(lead(s.data, 1) over(
                partition by s.stanza
                order by s.data
            ),now()) as data_successiva
            from Sensore s
			where s.stanza = _stanza
        ) as d
        where _instant between d.data and d.data_successiva
    ),
	TemperaturaEx as (
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

	select abs(ti.temperatura - te.temperatura) * s.dispersione into efficienza
	from TemperaturaInt ti, TemperaturaEx te, Stanza s
	where s.luogo = _stanza;

	return efficienza;

end $$
delimiter ;

select EfficienzaEnergeticaStanza(1, '2020-06-06 01:44:13');