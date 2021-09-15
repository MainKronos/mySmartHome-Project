use smarthome;

Drop Procedure if exists Suggerimenti;

Delimiter $$

Create Procedure Suggerimenti()
   Begin
   Declare ContatoreDispositiviPocoUsati integer default 0;
   Declare TempIdDispositivo integer default 0;
   Declare TempConsumo integer default 0;
   Declare ProduzioneIstantaneaMenoConsumo integer default 0;
   Declare SogliaDiSicurezza integer default 0;
   Declare MessaggioNotifica varchar(100);
   Declare finito integer default 0;
   
   Declare cursoreOttimizzazioneConsumi Cursor For
      
      with DispositiviACicloPocoUsati as    -- questa cte contiene i dispositivi a ciclo non interrompibile che non sono stati utilizzati da più di un giorno
     (
     select *
     from AttivitaCiclo AC
	 where Datediff(current_date(),AC.Data) > 1 
           and
           not exists( Select *
                       From  AttivitaCiclo AC2
					   where AC.Ciclo = AC2.Ciclo
					         and
                             AC.Programma = AC2.Programma
                             and
                             AC2.Data < AC.Data
					 )
     ),
     DispositiviEProgrammiIdonei as    -- questa cte contiene i dispositivi a ciclo non interrompibile che hanno un programma che può essere completato entro le 18 
     (                                 -- (si presume che la produzione elettrica dopo le 18 cali drasticamente per via del tramonto del sole)
        select rank() over (order by DAC.Data,P.Durata Desc),DAC.ciclo as id_dispositivo,P.Consumo
        from  DispositiviACicloPocoUsati DAC
              inner join
              Programma P
              on P.id_programma = DAC.programma
              
        where 18 - hour(now()) - minute(now())/60 > P.durata/60
	          and 
              hour(now()) + minute(now())/60 - 6 > P.durata/60
     )
      Select Id_Dispositivo,Consumo
      From DispositiviEProgrammiIdonei;
      
   Declare continue handler
      for not found set finito = 1;
   
   set ContatoreDispositiviPocoUsati =    -- qui viene calcolato il numero di dispositivi a ciclo non interrompibile che non vengono utilizzati da un giorno o più
	 (
		select count(*)
        from AttivitaCiclo AC
		where Datediff(current_date(),AC.Data) > 1
              and
              not exists( Select *
                          From  AttivitaCiclo AC2
					      where AC.Ciclo = AC2.Ciclo
					            and
                                AC.Programma = AC2.Programma
                                and
                                AC2.Data < AC.Data
					    ) 
     );
   
   set ProduzioneIstantaneaMenoConsumo = 4000; -- ProduzioneIstantanea() - ConsumoTot(current_date())

	if ContatoreDispositiviPocoUsati = 0 and ProduzioneIstantaneaMenoConsumo > 0 then       -- se non esistono dispositivi a ciclo non interrompibile attivabili allora ci limitiamo 
        signal sqlstate '45000'                                                             -- a segnalare all'utente una eventuale eccedenza di produzione elettrica 
		set message_text = 'notifica: hai ProduzioneIstantaneaMenoConsumo Kw disponibili, usali!';
	else
     
     Open cursoreOttimizzazioneConsumi;
     
     preleva: Loop
        fetch cursoreOttimizzazioneConsumi into TempIdDispositivo,TempConsumo;
        if finito = 1 then
           leave preleva;
		end if;
        if ProduzioneIstantaneaMenoConsumo - TempConsumo > TempConsumo/100 * 30 then          -- se c'e abbastanza produzione da permettere l'avvio di un programma di un dispositivo a ciclo non interrompibile
        set ProduzioneIstantaneaMenoConsumo = ProduzioneIstantaneaMenoConsumo - TempConsumo;  -- senza ricorrere al prelievo di energia dalla rete, allora viene consigliato all'utente di avviare il programma in questione
           signal sqlstate '45000'
           set message_text = 'notifica: puoi avviare il dispositivo in questione';
        else
           Leave preleva;
		end if;
	end loop preleva;
    close cursoreOttimizzazioneConsumi;
    end if;
      
End $$
Delimiter ;
     
