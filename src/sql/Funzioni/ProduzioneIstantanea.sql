
Drop function if exists ProduzioneIstantanea;

Delimiter $$

Create function ProduzioneIstantanea()
returns int deterministic

Begin
   
   Declare ProduzioneInst_ int default 0;
   
   Set ProduzioneInst_ =                -- alla variabile produzione istantanea viene assegnata la somma dei valori di produzione a cui è associata la data_variazione più grande, 
   (                                    -- ovvero il più recente, per ciascuna sorgente
      select sum(E.Produzione)
      from Energia E
      where E.Data_Variazione >= all
      (
         select E2.Data_Variazione
         from Energia E2
      )
   );
   
   Return ProduzioneInst_;
End $$
Delimiter ;