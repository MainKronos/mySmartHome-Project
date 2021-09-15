 Delimiter %%
   Create event if not exists  EliminazioneFasciaOraria
   on schedule every 1 day
   starts '2021-12-12 23:55:00'
   do
      begin
         
         Delete from FasciaOraria
         where data_attivazione > now() + interval 1 day;
         
         Delete from ImpostazioneFasciaOraria
         where id_fascia_oraria in
         (
            select id_fascia_oraria
            from FasciaOraria
            where data_attivazione > now() + interval 1 day        
         );
end %%