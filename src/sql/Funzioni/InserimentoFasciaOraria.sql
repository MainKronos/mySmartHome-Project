drop procedure if exists InserimentoFasciaOraria;
delimiter $$
create procedure InserimentoFasciaOraria (IN _OraInizio time,IN _OraFine time,IN  _Retribuzione int,IN _Prezzo int,IN _NomeUtente varchar(255),IN _Casa int,IN _Batteria int,IN _Rete int,IN _UsoBatteria tinyint)
begin
   
   declare finito tinyint default 0;
   declare contatoreRecord int default 0;
   
   if _Casa + _Batteria + _Rete <> 100 then
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
   end if;
   
   
   Set contatoreRecord =
   (
      Select count(*)
      From FasciaOraria
   );
   
   if exists ( -- impedisce l'inserimento di fasce orarie che si sovrappongono interamente a fasce orarie inserite in precedenza
      
      Select *
      From FasciaOraria
      Where Data_Attivazione > now()
            and
            ((Ora_Inizio >= _OraInizio and Ora_Inizio < _OraFine)
			or
			(_OraFine < _OraInizio
			and
			(Ora_Inizio < _OraFine or Ora_Inizio >= _OraInizio)))
			and
			((Ora_Fine > _OraInizio and Ora_Fine <= _OraFine)
			or
			(_OraFine < _OraInizio
			and
			(Ora_Fine <= _OraFine or Ora_Fine > _OraInizio)))
   )
   
   then 
      
      insert into Notifica
      values ("la fascia oraria inserita non è valida perchè si sovrappone ad un'altra inserita in precedenza",0,_NomeUtente);
      
   elseif exists( -- impedisce l'inserimento di fasce orarie contenute interamente in una fascia oraria inserita in precedenza
     
     Select *
      From FasciaOraria
      Where Data_Attivazione > now()
            and
            ((_OraInizio > Ora_Inizio and _OraInizio < Ora_Fine)
			or
			(Ora_Fine < Ora_Inizio
			and
			(_OraInizio < Ora_Fine or _OraInizio > Ora_Inizio)))
			and
			((_OraFine > Ora_Inizio and _OraFine < Ora_Fine)
			or
			(Ora_Fine < Ora_Inizio
			and
			(_OraFine < Ora_Fine or _OraFine > Ora_Inizio)))
   )
   
   then 
   
      insert into Notifica
      values ("quella fascia oraria è già coperta",0,_NomeUtente);
   
   end if;
   
   Set _OraInizio = ifnull(  -- se l'utente inserisce una orainizio che si sovrappone ad una fascia oraria esistente, questa viene aggiustata
   (
      select Ora_Fine
      from FasciaOraria
      where data_Attivazione > now()
            and
			((Ora_Fine between _OraInizio and _OraFine)
			or
			(_OraFine < _OraInizio
			and
			(Ora_Fine < _OraFine or Ora_Fine > _OraInizio))) 
   ),_OraInizio);
   
   Set _OraFine = ifnull( -- se l'utente inserisce una orafine che si sovrappone ad una fascia oraria esistente, questa viene aggiustata
   (
      select Ora_Inizio
      from FasciaOraria
      where data_Attivazione > now()
            and
			((Ora_Inizio between _OraInizio and _OraFine)
			or
			(_OraFine < _OraInizio
			and
			(Ora_Inizio < _OraFine or Ora_Inizio > _OraInizio))) 
   ),_OraFine);
   
   
   if exists -- non viene permesso l'inserimento di fasce orarie che non abbiano orainizio o orafine uguali ad una fascia oraria esistente, viene fatta un'eccezione per la prima fascia oraria da inserire
   (
      Select *
      From FasciaOraria
      Where Data_Attivazione > now()
   )
   
   then
      
      if( (_OraInizio <> all(Select Ora_Fine From FasciaOraria)) and (_OraFine <> all(Select Ora_Inizio From FasciaOraria)) )
      
      then 
         
         insert into Notifica
         values ("la fascia oraria deve avere orainizio/orafine uguale ad orafine/orainizio di una fascia oraria già esistente",0,_NomeUtente);
      end if;
   
   end if;
   
   if exists -- se la fascia oraria inserita ha orainizio e orafine uguali ad una fascia oraria esistente, viene segnalato il completamento del set di fasce orarie
   (
      Select *
      From fasciaOraria
      Where Data_Attivazione > now()
            and
            _OraInizio = Ora_Fine
   )
   
   then 
      
      if exists
      (
         Select *
         From FasciaOraria
         Where Data_Attivazione > now()
               and
               _OraFine = Ora_Inizio
      )
      then
      set finito = 1;
      end if;
	end if;
   
   
  
   
   if finito = 1 then
     Update FasciaOraria
     Set data_attivazione = now() + interval 1 day
     Where data_attivazione > now();
     insert into Notifica
         values ("set di fasce orarie inserito correttamente",0,_NomeUtente);
   end if;
   
   insert into FasciaOraria
   values (contatoreRecord + 1,_OraInizio,_OraFine,_Retribuzione,_Prezzo,_NomeUtente,now() + interval 1 day);
   
   insert into ImpostazioneFasciaOraria
   values (contatoreRecord + 1,_Casa,_Batteria,_Rete,_UsoBatteria);
end $$

delimiter ;
   
   