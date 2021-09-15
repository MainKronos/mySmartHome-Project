Drop Procedure If Exists Carica_Batteria_MANUAL;
Delimiter $$
Create Procedure Carica_Batteria_MANUAL()
    Begin
    
    Declare caricaBatteria int default 0;
    Declare capienzaBatteria int default 0;
    Declare Nrecord int default 0;
    Declare TempProduzioneMenoConsumo int default 0;
    Declare contatore int default 1;
    
    drop temporary table if exists risultati;
    
    create temporary table risultati (
       ordine int not null default 0,
       data_variazione datetime not null,
       produzione_meno_consumo int not null default 0,
    
       primary key(ordine)
    );
    
    insert into risultati
       
       with energia_target as
       (
          Select E.sorgente,
                 E.data_variazione,
                 E.Produzione,
                 fascia_oraria_in_energia(E.data_variazione) as id_fascia_oraria
                 
          From Energia E
          Where E.data_variazione > now() - interval 1 year - interval 3 month - interval 3 day - interval 17 hour
       ),
       logtable_produzione_intervallo as 
       (
          Select ET.sorgente,
                 ET.data_variazione,
                 ET.produzione as produzione_intervallo,
                 IFO.batteria,
                 IFO.uso_batteria
          From energia_target ET
               inner join
               ImpostazioneFasciaOraria IFO
               on IFO.id_fascia_oraria = ET.id_fascia_oraria
       ),
       produzione_sorgenti_e_consumo as
       (
          Select LPI.data_variazione,
                 sum(LPI.produzione_intervallo) as produzione_totale_intervallo,
                 LPI.batteria,
                 LPI.uso_batteria,
                 ConsumoRange(LPI.data_variazione,LPI.data_variazione + interval 30 minute) as consumo
           From logtable_produzione_intervallo LPI
           Group by LPI.data_variazione
        )
       
       Select rank() over(order by PSC.data_variazione) as ordine,
              PSC.data_variazione,
              (PSC.produzione_totale_intervallo * PSC.batteria/100 - PSC.uso_batteria * PSC.consumo) as produzione_meno_consumo
       From produzione_sorgenti_e_consumo PSC;
     
     Set caricaBatteria = 
    (
       Select sum(carica/100 * capienza)
       From Batteria
    );
    
    Set capienzaBatteria = 
    (
       Select sum(capienza)
       From Batteria
    );
    
	set Nrecord = 
    (
       Select count(*)
       From risultati
    );
    
    carica:loop
       if contatore > Nrecord then
       
          leave carica;
       
       end if;
       
	   Set TempProduzioneMenoConsumo =
	   (
	      Select produzione_meno_consumo
		  From risultati
		  Where ordine = contatore
	   );
       
	   if caricaBatteria + TempProduzioneMenoConsumo >= capienzaBatteria then
             
	      Set caricaBatteria = capienzaBatteria;
		  
	   elseif caricaBatteria + TempProduzioneMenoConsumo <= 0 then
             
		  Set caricaBatteria = 0;
		  
	   else
             
		  Set caricaBatteria = caricaBatteria + TempProduzioneMenoConsumo;
		  
	   end if;
          
	   Set contatore = contatore + 1;
       
	end loop carica;
    
    Update Batteria
    Set carica = capienza * caricaBatteria/capienzaBatteria;
    
end $$    

delimiter ;