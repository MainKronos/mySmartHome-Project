Drop Procedure if exists ModificaFasceOrarie;

Delimiter $$

Create Procedure ModificaFasceOrarie(IN _OraInizio time, IN _OraFine time, IN _Retribuzione float, IN _Prezzo float, IN _NomeUtente varchar(255),IN _Casa int, IN _Batteria int, IN _Rete int, IN _UsoBatteria tinyint)
begin
   Declare ContatoreRecord int default 0;
   
   Set ContatoreRecord =
        (
           Select Count(*)
           From FasciaOraria
        );
	
   if ContatoreRecord = 0 then   -- questa procedura si occupa di modificare set di fasce orarie già esistenti, naturalmente se non ne esiste nessuno la procedura restituisce un errore
      signal sqlstate '45000'
	  set message_text = 'non esistono fasce orarie da modificare';
	
   elseif _Casa + _Batteria + _Rete <> 100 then  -- questa è una business rule che i dati inseriti devono rispettare
      signal sqlstate '45000'
      set message_text = 'La somma tra la corrente inviata alla casa, alla batteria e alla rete deve fare 100';
   elseif
      _NomeUtente not in 
         (
         select nome_utente
         from Account
         )
   then
      signal sqlstate '45000'
      set message_text = 'il nome utente inserito non esiste';
      
   else
      create temporary table if not exists NuovaFasciaOrariaEImpostazione(  -- in questa temporary table verrà inserito il set di fasce orarie che si intende modificare,
         _Id_fascia_Oraria int default 0,                                   -- insieme alla fascia oraria appena inserita
         Ora_Inizio time not null,
         Ora_Fine time not null,
         Retribuzione float not null,
         Prezzo float not null,
         Account_Utente varchar(100) not null,
         Data_Attivazione datetime not null,
         Casa int not null,
         Batteria int not null,
         Rete int not null,
         Uso_Batteria tinyint not null,
         primary key(Ora_Inizio,Data_Attivazione)
         ) Engine=InnoDB Default charset = latin1;
         
         truncate table NuovaFasciaOrariaEImpostazione;
         
         insert into FasciaOraria
            select 1000,_OraFine,FODM.Ora_Fine,FODM.Retribuzione,FODM.Prezzo,FODM.Account_Utente,FODM.Data_Attivazione
			from 
            (
               select *
               from FasciaOraria FO                                       -- se la fascia oraria appena inserita si trova in mezzo ad una fascia oraria già presente,
                    natural join                                          -- allora è necessario "spezzare in due" la fascia oraria in questione per fare spazio a quella nuova.
                    ImpostazioneFasciaOraria                              -- la fascia oraria vecchia viene reinserita temporaneamente (creando un duplicato) in FasciaOraria con
               where FO.data_attivazione >= all                           -- id_fascia_oraria = 1000, di modo da essere facilmente riconoscibile e rimovibile successivamente
               (
			      select FO2.data_attivazione
                  from FasciaOraria FO2
			   )
			) FODM
			where ((_OraInizio between FODM.Ora_Inizio and FODM.Ora_Fine)
				  or
				  FODM.Ora_Fine < FODM.Ora_Inizio
				  and
				  (_OraInizio < FODM.Ora_Fine or _OraInizio > FODM.Ora_Inizio))
                  and
                  ((_OraFine between FODM.Ora_Inizio and FODM.Ora_Fine)
				  or
				  FODM.Ora_Fine < FODM.Ora_Inizio
				  and
				  (_OraFine < FODM.Ora_Fine or _OraFine > FODM.Ora_Inizio)); 
                  
		insert into ImpostazioneFasciaOraria              -- viene creato un duplicato anche in ImpostazioneFasciaOraria
           select 1000,Casa,Batteria,Rete,Uso_Batteria
           from ImpostazioneFasciaOraria
           where Id_Fascia_Oraria in
           (
           select Id_Fascia_Oraria
           from
		   (
               select *
               from FasciaOraria FO
                    natural join
                    ImpostazioneFasciaOraria
               where FO.data_attivazione >= all
               (
			      select FO2.data_attivazione
                  from FasciaOraria FO2
			   )
			) FODM
			where ((_OraInizio between FODM.Ora_Inizio and FODM.Ora_Fine)
				  or
				  FODM.Ora_Fine < FODM.Ora_Inizio
				  and
				  (_OraInizio < FODM.Ora_Fine or _OraInizio > FODM.Ora_Inizio))
                  and
                  ((_OraFine between FODM.Ora_Inizio and FODM.Ora_Fine)
				  or
				  FODM.Ora_Fine < FODM.Ora_Inizio
				  and
				  (_OraFine < FODM.Ora_Fine or _OraFine > FODM.Ora_Inizio))
           );
         
         -- la fascia oraria inserita dall'utente viene messa nella temporary table con data_attivazione pari al giorno successivo all'inserimento
        insert into NuovaFasciaOrariaEImpostazione (Ora_Inizio,Ora_Fine,Retribuzione,Prezzo,Account_Utente,Data_Attivazione,Casa,Batteria,Rete,Uso_Batteria) 
        values (_OraInizio,_OraFine,_Retribuzione,_Prezzo,_NomeUtente,now() + interval 1 Day,_Casa,_Batteria,_Rete,_UsoBatteria);
         
		insert into NuovaFasciaOrariaEImpostazione (Ora_Inizio,Ora_Fine,Retribuzione,Prezzo,Account_Utente,Data_Attivazione,Casa,Batteria,Rete,Uso_Batteria)
        
        
         with FasciaOrariaDaModificare as -- la fascia oraria da modificare è quella con data di attivazione più recente, ovvero quella attiva al momento della modifica
	     (
            select *
            from FasciaOraria FO
                 natural join
                 ImpostazioneFasciaOraria
            where FO.data_attivazione >= all
            (
			   select FO2.data_attivazione
               from FasciaOraria FO2
			)
         ),
         IdFasciaOrariaDaTogliere as  -- gli id delle fasce orarie che si sovrappongono completamente alla fascia oraria inserita dall'utente finiscono qua dentro
         (
            select FODM.Id_Fascia_Oraria
			from FasciaOrariaDaModificare FODM
			where ((FODM.Ora_Inizio between _OraInizio and _OraFine)
				  or
				  _OraFine < _OraInizio
				  and
				  (FODM.Ora_Inizio < _OraFine or FODM.Ora_Inizio > _OraInizio))
                  and
                  ((FODM.Ora_Fine between _OraInizio and _OraFine)
				  or
				  _OraFine < _OraInizio
				  and
				  (FODM.Ora_Fine < _OraFine or FODM.Ora_Fine > _OraInizio)) 
         )
        
		select FODM.Ora_Inizio,FODM.Ora_Fine,FODM.Retribuzione,FODM.Prezzo,FODM.Account_Utente,now() + interval 1 day,FODM.Casa,FODM.Batteria,FODM.Rete,FODM.Uso_Batteria
		from FasciaOrariaDaModificare FODM
		where FODM.Id_Fascia_Oraria not in     -- il set di fasce orarie più recente (quello da modificare) meno le fasce orarie che si sovrappongono a quella 
            (                                  -- inserita dall'utente viene inserito nella temporary table
               Select *
               From IdFasciaOrariaDaTogliere
            );
            
		Delete from FasciaOraria
        where data_attivazione > now()
              or
              Id_Fascia_Oraria = 1000;
              
        
        Delete from ImpostazioneFasciaOraria   -- vengono rimossi i possibili duplicati e, in caso di chiamate consecutive di questa procedura, vengono rimossi anche tutti i set
        where id_fascia_oraria in              -- di fasce orarie con data di attivazione futura, ovvero i risultati di una chiamata recente di questa procedura
           (                                   
		   select FO.id_fascia_oraria
           from FasciaOraria FO
           where data_attivazione > now()
                 or
                 Id_Fascia_Oraria = 1000
           ); 
           
		Set ContatoreRecord =  
        (
           Select Count(*)
           From FasciaOraria
        );
           
		insert into FasciaOraria  
           select Rank() over(order by Data_Attivazione,Ora_inizio) + ContatoreRecord as Id_Fascia_Oraria,Ora_Inizio,Ora_Fine,Retribuzione,Prezzo,Account_Utente,Data_Attivazione
           from NuovaFasciaOrariaEImpostazione;
				
        Select * From FasciaOraria;
		
        Insert into ImpostazioneFasciaOraria
           Select Rank() over(order by Data_Attivazione,Ora_inizio) + ContatoreRecord,Casa,Batteria,Rete,Uso_Batteria
           From NuovaFasciaOrariaEImpostazione;
           
		
           Update FasciaOraria                  -- le fasce orarie che non si sovrappongono completamente alla fascia oraria inserita dall'utente vengono "corrette" modificando la loro ora
           Set Ora_Fine = _OraInizio            -- di inizio o di fine di modo da eliminare la sovrapposizione
           Where Data_Attivazione > now() 
                 and
                 ((_OraInizio > Ora_Inizio and _OraInizio < Ora_Fine)
				  or
				  (Ora_Fine < Ora_Inizio
				  and
				  (_OraInizio < Ora_Fine or _OraInizio > Ora_Inizio)));
              
        
           Update FasciaOraria
           Set Ora_Inizio = _OraFine
           Where Data_Attivazione > now()
                 and
                  ((_OraFine > Ora_Inizio and _OraFine < Ora_Fine)
				  or
				  (Ora_Fine < Ora_Inizio
				  and
				  (_OraFine < Ora_Fine or _OraFine > Ora_Inizio)));
	

        drop table NuovaFasciaOrariaEImpostazione;
        
        end if;
end $$

delimiter ;
         
      
	
       