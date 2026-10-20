# Architettura

## Struttura

| Cartella | Responsabilita |
| --- | --- |
| src/game | Stato della partita, tiro, effetti e audio |
| src/world | Generazione del terreno, famiglie e partenze |
| src/data | Catalogo e validazione dei formati |
| src/ai | Pianificatore dell'avversario |
| src/ui | Menu, arsenale e anteprime |
| src/editors | Bozze delle mappe e delle regole |
| src/art | Risorse grafiche, tema e icone |

`main.tscn` istanzia `src/game/main.gd`. Il progetto costruisce gran parte
 dell'interfaccia da codice: non cercare una scena separata per ogni pannello.

## Ciclo di gioco

Il menu conserva una configurazione proposta. Avvia valida mappa, squadre,
armi e regole, poi crea la partita. Riprendi non applica le nuove proposte.
La fase libera permette movimento e mira. Sparare cattura una copia dei
parametri dell'arma, consuma una munizione e attiva il proiettile o l'effetto.
Seguono eventuali proiettili secondari e l'assestamento. Poi viene scelto il
personaggio vivo successivo e controllato il risultato della partita.
La pausa e gli editor sospendono timer e simulazione interessata.

## Terreno e fisica

La stessa immagine RGBA contiene la maschera per collisioni e distruzione.
`solid` e `blocked` campionano pixel e sagoma del personaggio. I movimenti e
i proiettili usano sottopassi per non attraversare pareti sottili.
Le esplosioni cancellano un disco e applicano danno/spinta con decadimento
in base alla distanza. I raggi di cratere e danno sono distinti.
Il materiale grafico legge la trasparenza aggiornata e dipinge la superficie:
non aggiunge collisioni. Il binding della texture viene aggiornato anche
quando una nuova partita sostituisce l'immagine del terreno.

## Mappe e partenze

Un seme riproduce la geometria. Il generatore costruisce strutture, le colora
per il materiale, cerca appoggi e valida le squadre. La disposizione mescolata
usa superfici reali, distanze minime e fasce di altezza. Ci sono appoggi di
recupero se una geometria non offre ancoraggi sufficienti.
Le mappe grandi sono 2200x1100; i formati accettano anche altre dimensioni
esplicitamente validate. Le quattro mappe classiche restano disponibili.

## Armi, anteprime e IA

Il catalogo JSON e normalizzato prima dell'uso. Il tipo guida il comportamento:
proiettile balistico, raggi, dispersione, trivella, ricerca, telecomando,
incursione, esplosivo posato, corpo a corpo o teletrasporto.
L'anteprima condivide gravita, sottopassi e sterzata dove applicabile.
Il telecomando puo cambiare bersaglio durante il volo, quindi la previsione
non e una promessa del percorso finale. I frammenti hanno stato autonomo e
il turno aspetta la loro conclusione.

L'IA valuta traiettorie e difficolta per il sottoinsieme supportato;
esclude ancora alcune armi speciali. Non scambia i propri piani con il giocatore.

## Camera e interfaccia

Rendering alla dimensione effettiva della finestra. Il mondo usa zoom e
offset; i clic devono essere trasformati all'inverso. I testi hanno una scala
indipendente e rimangono leggibili mentre il mondo cambia zoom. Gli editor
adattano il proprio spazio di disegno al pannello. Durante tiri ed esplosioni
la camera resta ferma; panoramica e trascinamento sono espliciti.

## Persistenza

Mappe, armi e pacchetti sono JSON con PNG incorporato quando necessario.
Validazione di versione, dimensioni, valori e coordinate precede l'uso.
La scrittura usa un file temporaneo prima di sostituire il precedente.
Preferenze e creazioni stanno nella cartella utente di Godot; niente nel
repository dipende dal profilo personale con cui e stato sviluppato il gioco.
