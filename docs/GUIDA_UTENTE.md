# Guida utente

## Installazione e avvio

Windows x64. Estrai completamente lo ZIP, non avviare il gioco dentro
l'anteprima dell'archivio. Il pacchetto Setup contiene `Installa.cmd`:
installa in `%LOCALAPPDATA%\SboMusic\Wormfront` e crea il collegamento nel menu Start.
Non richiede amministratore. Il pacchetto portatile funziona anche senza
installazione: `Wormfront.exe` e `Wormfront.pck` devono rimanere insieme.

L'installazione non modifica firewall, avvio automatico o impostazioni globali.
Per rimuoverla apri `Disinstalla.cmd` nella cartella del gioco e conferma.
I salvataggi personali restano conservati. Per aggiornare, chiudi il gioco
ed esegui il nuovo pacchetto. La versione portatile si rimuove eliminando
la sua cartella dopo aver conservato eventuali creazioni desiderate.

## Preparare una partita

Scegli il terreno. **Rigenera** cambia la struttura dei tipi procedurali.
Imposta 1-4 personaggi per squadra, salute, durata turno e danni agli alleati.
Attiva o disattiva IA, difficolta, rifornimenti e partenze mescolate.
Avvia la partita. Le scelte nel menu non cambiano una partita in pausa
finche non premi Avvia; Riprendi conserva quella in corso.

Gli sfondi vengono scelti una volta per avvio, senza ripetizioni immediate.
Non sono il terreno: gli elementi lontani nello sfondo non hanno collisione.

## Movimento e tiro

| Comando | Risultato |
| --- | --- |
| A/D oppure frecce sinistra/destra | Cammina |
| Shift | Salta, se c'e appoggio o margine di salto |
| Mouse | Mira |
| Sinistro tenuto / rilascio | Carica / spara |
| Clic sinistro rapido | Spara alla potenza corrente |
| Destro trascinato verticalmente | Modifica potenza |
| W/S, Q/E, Spazio | Mira, potenza e tiro da tastiera |
| M oppure Tab | Apri/chiudi arsenale |
| 1-8 | Seleziona le prime otto armi |
| Invio | Passa turno |
| R | Riavvia la partita sulla mappa selezionata |
| Esc | Menu/pausa |
| F1 | Aiuto e pausa |
| Rotella | Zoom |
| C | Panoramica e ritorno |
| Trascina rotella | Sposta la camera |
| F11 oppure Alt+Invio | Schermo intero/finestra |
| A- e A+ nei pulsanti | Dimensione testi indipendente dallo zoom |

Lo zoom e i testi sono memorizzati. La camera non segue automaticamente
il proiettile: riposizionala prima del tiro o usa la panoramica.
Si viene eliminati esaurendo la vita, cadendo nell'acqua o oltre i bordi.

## Armi speciali

- **Bomba sacra**: esplosivo a miccia con grande raggio e spinta.
- **Missile guidato**: indica il bersaglio prima del lancio. La correzione
  e graduale; pareti e soffitti possono intercettarlo.
- **Missile telecomandato**: guida spostando il mouse durante il volo.
- **Grappolo / fruttata**: producono proiettili secondari. Il turno aspetta
  la conclusione anche dei frammenti.
- **Incursioni**: indica la zona con il mouse; le bombe scendono dall'alto.
  Un tetto puo proteggere i personaggi sottostanti.
- **Dinamite**: si posa vicino al verme. Durante la miccia puoi allontanarti
  con A/D o frecce e saltare con Shift.
- **Spinta / mazza / pugno**: serve un bersaglio davanti e a breve distanza.
- **Teletrasporto**: indica aria libera sopra un appoggio non occupato.
  Un punto invalido non consuma munizioni.

Le scorte appartengono alla squadra; il simbolo infinito indica uso illimitato.
Le casse possono ripristinare salute o dare munizioni. Gli effetti delle
armi possono coinvolgere alleati e l'utilizzatore secondo le regole impostate.

## Editor e creazioni

**F2** apre l'editor mappe. Disegna o cancella terreno, scegli i due ancoraggi
iniziali delle squadre, usa annulla/ripeti, salva e prova la mappa.
Gli ancoraggi devono avere spazio e un appoggio valido per la squadra scelta.
Le partenze mescolate possono essere diverse dai due ancoraggi.
**F3** ripristina la mappa iniziale.

**F4** apre armi e regole. Modifica danni, raggi, spinta, gravita, miccia,
rimbalzo e colore. Applica avvia una nuova partita. Rinominare una voce
modifica quella voce: non crea una copia. Per aggiungere armi al catalogo
sorgente segui [MODDING](MODDING.md). Non c'e ancora un pulsante Duplica.

| File | Contenuto |
| --- | --- |
| `.wormfront` | Terreno e due ancoraggi |
| `.arsenale` | Armi e regole |
| `.wormfrontpack` | Mappa, armi e configurazione iniziale |

I pacchetti non salvano un turno in corso. Scambia questi file con altri
giocatori; non serve inviare la cartella dei dati personali.
I formati nuovi possono richiedere una versione recente del gioco.

## Dati e problemi comuni

Godot salva preferenze e creazioni in `%APPDATA%\Godot\app_userdata\Wormfront`.
Le edizioni precedenti usavano cartelle diverse: puoi
recuperare i file desiderati attraverso le finestre Carica, scegliendo la cartella dati della vecchia installazione. I formati precedenti restano leggibili.
I test degli sviluppatori usano cartelle isolate e non i tuoi salvataggi.

- Se l'eseguibile non trova i dati, estrai tutto e verifica `Wormfront.pck`.
- Se non puoi sparare, controlla munizioni, timer, turno e pannelli aperti.
- Se il teletrasporto non parte, indica un punto libero sopra una superficie.
- Se una squadra non puo partire, riduci i membri o allarga gli appoggi.
- Se non senti suoni, controlla Suoni attivi nel menu e il volume di Windows.

Il gioco e un'alpha: descrivi mappa, arma e passaggi per riprodurre un problema,
indicando la versione e senza pubblicare dati personali o l'intera cartella utente.

