# Progetto: artiglieria 2D per PC

## Obiettivo

Creare un videogioco originale per PC, ispirato alle meccaniche generali di Worms, completamente gratuito e senza finalità commerciali. Utilizzare personaggi, nome, mappe, immagini, suoni e interfaccia propri.

## Tecnologie

Godot 4 e GDScript. SboMusic supporta la programmazione; il progetto Godot contiene il gioco. La prima piattaforma è Windows.

## Funzionalità previste

- Combattimento a turni tra squadre.
- Terreno distruttibile ed effetti fisici delle esplosioni.
- Armi personalizzabili per danno, traiettoria, grafica ed effetti.
- Editor integrato per mappe.
- Editor per armi e regole.
- Condivisione delle creazioni tra giocatori.

## Prima fase

Piccola mappa 2D, due personaggi, movimento, un'arma e terreno distruttibile. Il prototipo 0.1 usa due squadre da un personaggio, partita locale, 100 punti vita, turni di 35 secondi e un colpo per turno. Questi valori sono proposte iniziali modificabili.

## Metodo

Avanzamento: prototipi 0.1–0.8 verificati dall'utente con esito positivo. Il limite dei due slot modificabili dell'editor armi è noto: l'utente ha chiesto di rimandare Nuova/Duplica e proseguire. La versione 0.9 aggiunge la distribuzione Windows x64 con eseguibile e dati del gioco, archivio ZIP, istruzioni e licenze del motore. Verificate build debug e release, rendering del programma esportato e copia estratta con directory dati vuota. Prova dell'utente sulla 0.9 e prova su un secondo PC da completare. Le due armi hanno munizioni illimitate in questa fase.

Le scelte di gioco vengono definite e riviste insieme all'utente; SboMusic prepara il codice e propone regole iniziali concrete. Prima si verifica il nucleo giocabile, poi si aggiungono editor e funzionalità avanzate.

## Decisioni ancora aperte

Stile visivo finale, nomi e personalizzazione delle squadre, inventario armi, vento e acqua. Il salto è già presente; vita, turni e numero di personaggi si impostano dal menu o dall'editor. I formati restano `.crateri` versione 1 per le mappe, `.arsenale` versione 1 per due armi e regole e `.crateripack` versione 1 per una creazione completa autonoma. I vecchi file senza `team_size` usano una squadra da uno. La distribuzione iniziale è uno ZIP per Windows x64, senza installazione di Godot. Nuova/Duplica/Elimina armi restano rimandati. Raccolta online e multiplayer in rete sono decisioni separate. Restano grafica e audio.

## Aggiornamento 0.10

Dopo la conferma dell'alpha, implementate le richieste basate sui due riferimenti:
mappe con camere, aperture, ponti e isole; sfondo e terreno più leggibili; nomi,
salute, indicatore attivo e mirino; otto armi con griglia, icone e scorte;
IA per Arancio; casse di salute o munizioni che scendono con il paracadute.
Vedere ANALISI_0.10.md per implementazione, verifiche e limiti. Le configurazioni
ora ammettono 2–16 armi e conservano IA/casse; il formato resta versione 1 con
campi opzionali. Il limite precedente dei due slot è superato per le armi
predefinite; Nuova/Duplica/Elimina resta rinviato. Vento, audio e rete restano
fasi future. La distribuzione 0.9 è conservata separatamente.

## Aggiornamento 0.11

Su richiesta: scelta difficolta IA, arsenale illustrato e filtrabile, 24 armi
comprese varianti da caratterizzare, 24 mappe complessive, campo largo il doppio,
camera con zoom/panoramica, vermi segmentati e mira con il mouse. Compatibilita
di mappe e pacchetti mantenuta. Vedere AGGIORNAMENTO_0.11.md e LEGGIMI della
nuova distribuzione. Restano conservate le versioni Windows 0.9 e 0.10.

## Aggiornamento 0.12

Corretti zoom e anteprime; M per arsenale; potenza con destro e carica/rilascio
sinistro; armi equipaggiate disegnate sui vermi. Mappe grandi a tre piani con
rampe e partenze casuali mescolate, tre membri per squadra nel menu iniziale.
Dettagli e limiti in AGGIORNAMENTO_0.12.md, verifiche in verifiche/ESITO_0.12.md.
Restyling artistico completo rinviato come richiesto. Versioni precedenti conservate.

## Aggiornamento 0.13

Generatore con sei topologie e semi casuali, pulsante Rigenera, ancoraggi
ricavati dalla nuova maschera e distribuzione mescolata sui veri appoggi.
Suoni originali sintetizzati per armi, esplosioni, rimbalzi e casse, con mute
nel menu e pausa. Verificata la distribuzione Windows e conservate le precedenti.
Vedere AGGIORNAMENTO_0.13.md e verifiche/ESITO_0.13.md.

## Aggiornamento 0.14

Schermo intero all'avvio e rendering nativo, HUD compatto, aiuto F1 con pausa,
F11 per la finestra, testi regolabili indipendentemente dallo zoom e preferenze
persistenti. Adattati camera, mouse, editor e menu. Verificate cinque risoluzioni,
24 armi e regressioni; ZIP estratto e provato con profilo pulito. Dettagli in
AGGIORNAMENTO_0.14.md e verifiche/ESITO_0.14.md. Restyling artistico separato.

## Aggiornamento 0.16

Mappe grandi sviluppate verso l'alto, terrazze irregolari, cavita e collegamenti
in sostituzione delle isole ovali ripetute. Mare inquadrato sul fondo, partenze
nella fascia alta e casse provenienti da sopra la nuova geometria. Versioni
precedenti conservate. Vedere AGGIORNAMENTO_0.16.md e verifiche/ESITO_0.16.md.

## Aggiornamento 0.17

Mappe grandi alte 1100, nuovi piani superiori e collegamenti. Camera ferma
nel volo dei proiettili e durante le esplosioni. Adattati editor, file, partenze,
acqua e IA alle altezze reali. Mappe da 700 ancora compatibili. Vedere
AGGIORNAMENTO_0.17.md e verifiche/ESITO_0.17.md.

## Aggiornamento 0.18

Prima scena giocabile del restyling cartoon: sfondo e roccia dipinti, verme
illustrato con animazione procedurale, sei famiglie di armi in mano e nel menu,
nuovo tema condiviso, scie e scintille. Maschera fisica e camera stabile
conservate. Asset e prompt in assets/art-018/ART_DIRECTION.md. Dettagli e limiti
in AGGIORNAMENTO_0.18.md, prove in verifiche/ESITO_0.18.md.

## Aggiornamento 0.19

Sfondi casuali senza ripetizioni immediate, architetture delle mappe ridisegnate
e tre materiali dipinti. Arsenale ampliato a 36 con dodici nuove aggiunte,
guidance, frammenti, incursioni, corpo a corpo e teletrasporto. Gli altri
comportamenti della fonte sono elencati in ARSENALE_ROADMAP.md, non dichiarati
come gia disponibili. Dettagli in AGGIORNAMENTO_0.19.md e prove in
verifiche/ESITO_0.19.md. Versioni precedenti conservate.
