use smarthome;

Drop Procedure If Exists Carica_Batteria;
Delimiter $$
Create Procedure Carica_Batteria()
    Begin
    
    Declare caricaBatteria int default 0;
    Declare capienzaBatteria int default 0;
    Declare Nrecord int default 0;
    Declare TempProduzioneMenoConsumo int default 0;
    Declare contatore int default 1;
    
    create temporary table risultati (
       ordine int not null default 0,
       data_variazione datetime not null,
       produzione_meno_consumo int not null default 0,
    
       primary key(ordine)
    );
    
    insert into risultati
       
       with logtable_produzione_intervallo as 
       (
          Select sorgente,data_variazione,produzione * 30 as produzione_intervallo,batteria,uso_batteria
          From LogTableBatteria
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
       Select sum(carica)
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
    
    truncate LogTableBatteria;
    
end $$    

delimiter ;
     
