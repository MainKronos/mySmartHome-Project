# mySmartHome-Project
Progetto di Base di Dati mySmartHome

Documentazione: [Documentazione.pdf](./documentazione/Documentazione.pdf)

Diagramma ER non ristrutturato: [Schema ER NON ristrutturato.pdf](./documentazione/Schema%20ER%20NON%20ristrutturato.pdf)

Diagramma ER ristrutturato: [Schema ER ristrutturato.pdf](./documentazione/Schema%20ER%20ristrutturato.pdf)

Schema logico: [Schema Logico.pdf](./documentazione/Schema%20Logico.pdf)


## Struttura
- database.sql
  - [1 - 7](./sql/database.sql#L1-L7): Creazione del Database
  - [12 - 444](./sql/database.sql#L12-L444): Creazione delle Tabelle
  - [448 - 726](./sql/database.sql#L448-L726): Aggiornamento ridondanze
    - [454 - 606](./sql/database.sql#L454-L606): EmergencyExit
      - [454 - 566](./sql/database.sql#L454-L566): EmergencyExit: _procedura_
      - [568 - 606](./sql/database.sql#L568-L606): EmergencyExit_ALL: _procedura_
    - [608 - 726](./sql/database.sql#L508-L726): CaricaBatteria: _event_
  - [732 - 1204](./sql/database.sql#L732-L1204): Funzioni di Utilità/Manutenzione
    - [738 - 760](./sql/database.sql#L738-L760): ProduzioneIstantanea: _funzione_
    - [762 - 880](./sql/database.sql#L762-L880): ConsumoDispositivo: _funzione_
    - [882 - 994](./sql/database.sql#L882-L994): ConsumoTot: _funzione_
    - [996 - 1019](./sql/database.sql#L996-L1019): Broadcast: _funzione_
    - [1021 - 1065](./sql/database.sql#L1021-L1065): EfficienzaEnergeticaStanza: _funzione_
    - [1067 - 1116](./sql/database.sql#L1067-L1116): Fascia_oraria_corrente: _funzione_
    - [1119 - 1151](./sql/database.sql#L1119-L1151): PuliziaDatabase: _event_
    - [1153 - 1204](./sql/database.sql#L1153-L1204): RegistrazioneScelte: _event_
  - [1208 - 2484](./sql/database.sql#L1208-L2484): Funzionalità
    - [1214 - 1244](./sql/database.sql#L1214-L1244): ConsumoCondizionatoreGiornaliero: _procedura_
    - [1246 - 1265](./sql/database.sql#L1246-L1265): InfoLuci: _procedura_
    - [1267 - 1373](./sql/database.sql#L1267-L1376): ConsumoRange: _funzione_
    - [1375 - 1484](./sql/database.sql#L1375-L1484): StatoDispositivo: _funzione_
    - [1486- 1507](./sql/database.sql#L1486-L1507): Carica_Batteria: _funzione_
    - [1509 - 1702](./sql/database.sql#L1509-L1702): InserimentoFasciaOraria:
      - [1509 - 1682](./sql/database.sql#L1509-L1682): InserimentoFasciaOraria: _procedura_
      - [1684 - 1702](./sql/database.sql#L1684-L1702): EliminazioneFasciaOraria: _event_
      - [1704 - 1914](./sql/database.sql#L1704-L1914): ModificaFasceOrarie: _procedura_
    - [1916 - 1881](./sql/database.sql#L1916-L1881): RegistrazioneUtente: _procedura_
    - [1952 - 1950](./sql/database.sql#L1952-L1950): AttivazioneScena: _procedura_
    - [1987 - 2422](./sql/database.sql#L1987-L2422): CreazioneAttivita:
      - [1987 - 2082](./sql/database.sql#L1987-L2082): CreazioneAttivitaCiclo: _procedura_
      - [2084 - 2173](./sql/database.sql#L2084-L2173): CreazioneAttivitaCondizionatore: _procedura_
      - [2175 - 2252](./sql/database.sql#L2175-L2252): CreazioneAttivitaLuce: _procedura_
      - [2255 - 2325](./sql/database.sql#L2255-L2325): CreazioneAttivitaToggle: _procedura_
      - [2327 - 2422](./sql/database.sql#L2327-L2422): CreazioneAttivitaVariabile: _procedura_
    - [2424 - 2471](./sql/database.sql#L2424-L2471): InfoGuadagni: _procedura_
    - [2473- 2484](./sql/database.sql#L2473-L2484): emergency_exit_read: _procedura_
  - [2490 - 2588](./sql/database.sql#L2490-L2588): Business Rules
    - [2494 - 2540](./sql/database.sql#L2494-L2540): PuntoCollegamentoTBI: _trigger_
    - [2542 - 2588](./sql/database.sql#L2542-L2588): PuntoCollegamentoTBU: _trigger_
  - [2597 - 3065](./sql/database.sql#L2597-L3065): Data Analytics
    - [2601 - 2806](./sql/database.sql#L2601-L2806): AbitudiniUtenti:
      - [2602- 2638](./sql/database.sql#L2602-L2638): AbitudiniUtenti_FULL: _procedura_
      - [2640 - 2674](./sql/database.sql#L2640-L2674): AbitudiniUtenti_PARTIAL: _procedura_
      - [2678 - 2680](./sql/database.sql#L2678-L2680): AbitudiniUtenti_TRIGGER_TOGGLE: _trigger_
      - [2682 - 2684](./sql/database.sql#L2682-L2684): AbitudiniUtenti_TRIGGER_LUCE: _trigger_
      - [2686 - 2688](./sql/database.sql#L2686-L2688): AbitudiniUtenti_TRIGGER_CICLO: _trigger_
      - [2690 - 2692](./sql/database.sql#L2690-L2692): AbitudiniUtenti_TRIGGER_VARIABILE: _trigger_
      - [2696 - 2794](./sql/database.sql#L2696-L2794): NotificaAbitudini_MANUAL: procedure
      - [2796 - 2806](./sql/database.sql#L2796-L2806): NotificaAbitudini: _event_
    - [2808 - 3065](./sql/database.sql#L2808-L3065): OttimizzazioneConsumi
      - [2811 - 2832](./sql/database.sql#L2811-L2832): PeriodAnalytics: _funzione_
      - [2828 - 3053](./sql/database.sql#L2828-L3053): OttimizzazioneConsumi_MANUAL: _procedura_
      - [3055 - 3065](./sql/database.sql#L3055-3065): OttimizzazioneConsumi: _event_
- dati.sql
  - [1 - 23822](./sql/database.sql#L1-L23822): Dati
  - [23824 - 23825](./sql/database.sql#L23824-L23825): Esecuzione procedure essenziali