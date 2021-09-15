Drop trigger if exists fascia_oraria_in_energia;
Delimiter $$

Create trigger fascia_oraria_in_energia
Before insert on Energia
For each row
begin
   
   Set New.id_fascia_oraria =
      (
      Select id_fascia_oraria
      From FasciaOraria FO
      Where time(FO.ora_inizio) < time(FO.ora_fine)
            and
            time(new.Data_variazione) >= time(FO.ora_inizio) and time(new.Data_variazione) < time(FO.ora_fine)
            and
            FO.data_attivazione <= new.Data_variazione
            and
            FO.data_attivazione >= all
               (
               Select FO2.data_attivazione
               From FasciaOraria FO2
               Where FO2.data_attivazione <= new.data_variazione
               )
	   );
       
       if new.id_fascia_oraria is null then
	set new.id_fascia_oraria =
       (
       Select FO3.id_fascia_oraria
       From FasciaOraria FO3
       where time(FO3.ora_inizio) > time(FO3.ora_fine)
             and
             (time(new.Data_variazione) >= time(FO3.ora_inizio) or time(new.Data_variazione) < time(FO3.ora_fine))
             and       
		     FO3.data_attivazione <= new.Data_variazione
             and
             FO3.data_attivazione >= all
               (
               Select FO4.data_attivazione
               From FasciaOraria FO4
               Where FO4.data_attivazione <= new.data_variazione
               )
      );
      end if;
	
End $$
Delimiter ;
      
   