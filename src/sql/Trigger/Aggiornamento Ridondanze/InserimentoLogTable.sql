Drop trigger if exists inserimento_log_table;
Delimiter $$

Create trigger inserimento_log_table
After insert on Energia
For each row
begin

   insert into LogTableBatteria
     select new.sorgente,new.data_variazione,new.produzione,batteria,uso_batteria
     from ImpostazioneFasciaOraria IFO
     where IFO.id_fascia_oraria = new.id_fascia_oraria;


End $$

Delimiter ;