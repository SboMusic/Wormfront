# Wormfront 0.19 - mappe tematiche, sfondi e nuove armi

## Mappe: intervento prioritario

La sagoma del terreno ora include cittadelle con merli, finestre, stanze,
passaggi nelle pareti, ponti interrotti e scalinate; massicci cavernosi con
camere collegate e pozzi; falesie con balconi e tunnel; grandi archi con
terrazze sfalsate. Le 24 scelte rimangono disponibili, con variazioni casuali.
Le coppie di famiglie condividono alcune tecniche costruttive, non sono 24
ambientazioni disegnate singolarmente.

Tre materiali dipinti distinguono muratura/muschio, ghiaccio e roccia vulcanica.
L'anteprima del menu usa lo stesso materiale del terreno in partita. Finestre,
pareti e ponti fanno parte della maschera e vengono realmente distrutti.
La mappa salvata conserva forma e colori che determinano il materiale.
Le vecchie mappe restano caricabili. Rigenera mostra le nuove strutture.

## Sfondi

Tre wallpaper: crepuscolo, valle alpina, deserto al tramonto. Scelta casuale
una volta per avvio, condivisa fra menu e partita, senza ripetizione immediata
rispetto all'avvio precedente. Le immagini create con image_gen e i prompt
finali sono in assets/art-019/ART_DIRECTION.md.

## Arsenale: 36 armi totali

Dodici aggiunte: Bomba sacra, Missile guidato, Missile telecomandato,
Bomba a grappolo, Bomba fruttata, Incursione aerea, Pioggia di bombe,
Dinamite, Spinta, Mazza cinetica, Pugno ardente, Teletrasporto.

- Guidato: indica il bersaglio con il mouse prima del lancio; la traiettoria
  curva verso quel punto e resta soggetta alle collisioni del terreno.
- Telecomandato: muovi il mouse anche durante il volo per guidare il missile.
- Grappoli: proiettili secondari con movimento e collisioni separati.
- Incursioni: indica la zona; le bombe scendono dall'alto, colpendo anche i soffitti.
- Dinamite: viene lasciata vicino al verme; frecce/A-D e Shift permettono la fuga.
- Corpo a corpo: danno e spinta soltanto nel raggio davanti al personaggio.
- Teletrasporto: indica aria libera sopra un appoggio. Destinazioni occupate
  o senza appoggio non consumano munizioni.

Armi e regole salvano anche i nuovi comportamenti. Limite configurazioni
portato da 32 a 64. Le versioni precedenti non riconoscono tutti i nuovi tipi.
L'IA mantiene il pianificatore per le armi balistiche e istantanee; non usa
ancora telecomando, teletrasporto, incursioni o corpo a corpo.

La fonte richiesta comprende armi di diversi capitoli. Questa versione NON
contiene tutte le armi di Worms: e un primo ampliamento con meccaniche vere.
Le altre famiglie da realizzare sono in ARSENALE_ROADMAP.md. Nomi, grafica,
valori e bilanciamento di Wormfront sono originali; non e una replica esatta.

Verifiche: verifiche/ESITO_0.19.md. Versioni precedenti conservate.
