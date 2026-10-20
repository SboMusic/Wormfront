# Aggiornamento 0.11

Implementate le richieste dell'utente:

- Difficolta IA Facile, Normale, Difficile, conservata nelle configurazioni.
  Risoluzioni rispettive di ricerca: angoli 20/10/5 gradi, potenza 150/75/40.
  Su Facile si aggiunge un errore deterministico di mira fino a 7 gradi.
- Arsenale illustrato a cinque colonne, scorrevole e filtrabile per categoria,
  con scorte e dettagli. Disegni SVG originali generati dal codice e riutilizzati
  per famiglia; nessuna risorsa grafica di Worms. 24 armi/varianti funzionanti,
  ancora da distinguere e bilanciare: non sono 24 comportamenti indipendenti.
- 24 mappe: quattro classiche e venti grandi, larghe 2200 pixel rispetto ai 1100
  iniziali. Cinque famiglie di geometrie con fasi differenti: canyon, isole,
  caverne, ponti e camere. Editor, collisioni, anteprima e pacchetti gestiscono
  la larghezza reale; accettate anche mappe larghe 3300 e alte 700.
- Camera indipendente dall'interfaccia, zoom 0.45-2.2, vista ravvicinata a inizio
  turno, inseguimento del proiettile, panoramica C e trascinamento centrale.
  Mouse convertito da schermo a mondo usando la stessa trasformazione del disegno.
- Mira con movimento del mouse e tiro con clic sinistro; Q/E mantiene il controllo
  della potenza. Tastiera conservata. Clic sulle interfacce non spara nel mondo.
- Vermi disegnati con corpo segmentato e arrotondato, occhi, fascia della squadra
  e piccola animazione durante il movimento. Grafica procedurale ancora provvisoria.

Compatibilita: campi aggiuntivi opzionali, formati versione 1; configurazioni
con 2-32 armi, vecchi pacchetti leggibili. Il salvataggio e' una creazione iniziale,
non lo stato di una partita. Le distribuzioni precedenti rimangono separate.

Verifiche dedicate in verify_expansion.gd: tutte le mappe con quattro membri,
conversione del mouse e mira, selezione ultima arma e filtro, editor della meta
destra della mappa, pacchetto con dimensioni/arsenale/difficolta e tre livelli IA.
Restano attive le prove precedenti e quelle di casse, munizioni e colpi speciali.
