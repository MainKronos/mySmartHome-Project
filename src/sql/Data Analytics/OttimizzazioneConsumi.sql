use smarthome;

Drop Procedure if exists OttimizzazioneConsumi; -- event ogni ora dopo il calcolo della batteria, solo dalle 6 alle 18

Delimiter $$

Create Procedure OttimizzazioneConsumi()
   
   Begin
   
   Declare ContatoreDispositiviPocoUsati integer default 0;
   Declare TempIdDispositivo integer default 0;
   Declare TempConsumo integer default 0;
   Declare TempDurata integer default 0;
   Declare TempProgramma varchar(255);
   Declare timer time;
   Declare ProduzioneCarica integer default 0;
   Declare Consumo integer default 0;
   Declare ProduzioneCaricaConsumo integer default 0;
   Declare SogliaDiSicurezza integer default 0;
   Declare MessaggioNotifica varchar(255);
   Declare Finito integer default 0;
   Declare CaricaBatteria integer default 0;
   Declare UsoBatteria tinyint default 0;
   
   Declare cursoreOttimizzazioneConsumi Cursor For
      
      with DispositiviACicloPocoUsati as    -- questa cte contiene i dispositivi a ciclo non interrompibile che non sono stati utilizzati da più di un giorno
     (
        select distinct C.id_dispositivo
        from AttivitaCiclo AC
             right outer join
             Ciclo C
             on AC.Ciclo = C.id_dispositivo
	    where AC.Data is null 
              or
              (
			     AC.Data is not null 
                 and
                 Datediff(current_date(),AC.Data) > 1 
			  )
     ),
     DispositiviEProgrammiIdonei as    -- questa cte contiene i dispositivi a ciclo non interrompibile che hanno un programma che può essere completato entro le 18 
     (                                 -- (si presume che la produzione elettrica dopo le 18 cali drasticamente per via del tramonto del sole)
        select rank() over (order by P.Durata Desc,P.Consumo Desc),
               DAC.id_dispositivo,
               P.Consumo,
               P.Durata,
               P.Tipo
        from  DispositiviACicloPocoUsati DAC
              inner join
              Programma P
              on P.ciclo = DAC.id_dispositivo
              
        where 18 - hour(now()) - minute(now())/60 > P.durata/60
	          and 
              hour(now()) + minute(now())/60 - 6 > P.durata/60
     )
      Select DPI.Id_Dispositivo,DPI.Consumo,DPI.Durata,DPI.Tipo
      From DispositiviEProgrammiIdonei DPI;
      
   Declare continue handler
      for not found set finito = 1;
   
   Set CaricaBatteria = 
   (
      Select sum(carica)
      From Batteria
   );
   
   
   
   set ContatoreDispositiviPocoUsati =    -- qui viene calcolato il numero di dispositivi a ciclo non interrompibile che non vengono utilizzati da un giorno o più
	 (
		select count(distinct C.id_dispositivo)
        from AttivitaCiclo AC
             right outer join
             Ciclo C
             on AC.Ciclo = C.id_dispositivo
	    where AC.Data is null 
              or
              (
			     AC.Data is not null 
                 and
                 Datediff(current_date(),AC.Data) > 1 
			  )
     );
   
   Set UsoBatteria =   -- prende l'usobatteria della fasciaoraria corrente
   (
      Select IFO.uso_batteria
      From ImpostazioneFasciaOraria IFO
      Where IFO.id_fascia_oraria = 
                              (
                                 Select distinct E.id_fascia_oraria
                                 From Energia E
                                 Where E.data_variazione >= all 
															 (
                                                                Select E2.data_variazione
                                                                From Energia E2
                                                             )
                              
                              )
	 
   );
   
   Set ProduzioneCarica =  ProduzioneIstantanea() + UsoBatteria * CaricaBatteria;
   
   Set timer = time(now());
   
   Set Consumo = ConsumoTot(current_timestamp);
   
   Set ProduzioneCaricaConsumo = ProduzioneCarica - Consumo;
   
	if ContatoreDispositiviPocoUsati = 0 and ProduzioneCaricaConsumo > 0 then       -- se non esistono dispositivi a ciclo non interrompibile attivabili allora ci limitiamo 
                                                                                    -- a segnalare all'utente una eventuale eccedenza di produzione elettrica 
        Set ProduzioneCarica = ProduzioneCarica + Broadcast(concat('hai ', ProduzioneCaricaConsumo, ' Kw disponibili, usali'),-1);
        
	elseif ProduzioneCaricaConsumo < 0 then
       
	   if ProduzioneCarica/Consumo < 0.6 then  -- se l'utente sta consumando molto di più di quanto sta producendo gli viene inviata una notifica
           
             Set ProduzioneCarica = ProduzioneCarica +  Broadcast(concat('stai prelevando ', -ProduzioneCaricaConsumo, ' W  dalla rete'),-1);
	   
       end if;
       
     else
     
        Open cursoreOttimizzazioneConsumi;
        preleva: Loop
        fetch cursoreOttimizzazioneConsumi into TempIdDispositivo,TempConsumo,TempDurata,TempProgramma;
        if finito = 1 then
        
		   leave preleva;
           
		end if;
        
        if ProduzioneCaricaConsumo - TempConsumo > TempConsumo/100 * 30 
           and
           18 - hour(timer) - minute(timer)/60 > TempDurata/60
		   and 
		   hour(timer) + minute(timer)/60 - 6 > TempDurata/60
              
		   then          -- se c'e abbastanza produzione da permettere l'avvio di un programma di un dispositivo a ciclo non interrompibile
        
           set ProduzioneCaricaConsumo = ProduzioneCaricaConsumo - TempConsumo;  -- senza ricorrere al prelievo di energia dalla rete, allora viene consigliato all'utente di avviare il programma in questione
           
			 Set ProduzioneCarica = ProduzioneCarica + Broadcast(concat(
                                                                          'puoi avviare il programma ', 
																		  TempProgramma,
                                                                          ' del dispositivo ',
                                                                          (
																	         Select Nome 
																			 From Dispositivo 
																		     Where id_dispositivo = TempIdDispositivo
																		  ), 
                                                                          ' che si trova in ', 
																		  (
																		     Select L.Nome 
																			 From Luogo L 
																				  inner join 
																				  Dispositivo D 
																				  on L.id_luogo = D.stanza
																			 Where D.id_dispositivo = TempIdDispositivo
																		   )
							                                             ),TempIdDispositivo
																 );
			Set timer = timer + interval TempDurata minute;
		else
           
           leave preleva;
           
		end if;
        
	end loop preleva;
    close cursoreOttimizzazioneConsumi;
    
    end if;
      
End $$
Delimiter ;
     