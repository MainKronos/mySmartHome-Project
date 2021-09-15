drop function if exists Broadcast;
delimiter $$
create function Broadcast ( _Messaggio varchar(255), _IdDispositivo int)
returns tinyint deterministic
begin
   
   if _IdDispositivo = -1 then

      Insert into Notifica (messaggio,data,accettata,account_utente)
         Select _Messaggio,now(),0,nome_utente
         From Account;
   else
      
      Insert into Notifica (messaggio,data,accettata,account_utente,id_dispositivo)
         Select _Messaggio,now(),0,nome_utente,_IdDispositivo
         From Account;
    end if;  

   Return 0;

end $$

delimiter ;