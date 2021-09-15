Drop function if exists fascia_oraria_in_energia;
Delimiter $$

Create function fascia_oraria_in_energia(DataVariazione datetime)
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
      
   