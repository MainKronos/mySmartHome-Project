Drop event if exists PuliziaDatabase;
Delimiter $$
Create Event PuliziaDatabase
on schedule every 1 day
starts '2021-12-12 23:55:00'
do
   begin
   Delete from Energia
   Where data_variazione < now() - interval 1 month; 
   
   Delete from Sensore
   Where data < now() - interval 1 month;
   
   Delete from Attivita 
   Where id_attivita in
   (
      Select id_attivita
      From Accesso
      Where data < now() - interval 1 month
   );
   
   end $$
   
Delimiter $$