# Come e stato sviluppato Wormfront

Progetto di SboMusic, nato come prototipo originale di artiglieria 2D per PC.
Motore Godot 4.5.1 Standard e GDScript; prima piattaforma Windows x64.
Le meccaniche di giochi a turni sono un riferimento, non una fonte di asset.

## Metodo

Ogni incremento introduce un gruppo di funzionalita, seguito da prove sul
sorgente, esportazione e prova del programma Windows. Il prototipo iniziale
usava una piccola mappa, due personaggi, movimento, un'arma e wormfront.
Sono arrivati squadre, editor, formati di file e pacchetti; poi IA, casse,
arsenale illustrato, mouse, camera e mondi piu grandi.

La grafica e stata sviluppata separatamente dalle regole: prima forme di
servizio, poi personaggi e materiali dipinti, menu coerenti e sfondi.
Sono stati usati anche strumenti generativi AI per immagini originali;
le note degli asset conservano specifiche e prompt per riprodurre lo stile.
Audio ed effetti sonori sono sintetizzati dal codice.

## Evoluzione sintetica

- 0.11-0.12: espansione di armi/mappe, IA e comandi mouse; anteprime e camera.
- 0.13: famiglie procedurali, semi casuali e suoni.
- 0.14-0.17: visualizzazione nativa, HUD compatto, testi regolabili,
  margini e uscite laterali, terreno alto e camera stabile durante i tiri.
- 0.18: prima scena del restyling, personaggio, armi illustrate e tema UI.
- 0.19: nuove architetture, tre materiali/sfondi e 36 armi.
- 0.20.0: riordino dei sorgenti, attribuzione SboMusic, guide, installer,
  licenza e preparazione della distribuzione pubblica.

La [cronologia](CHANGELOG.md) rimanda alle note storiche conservate.
La cartella history documenta lo sviluppo passato: alcune indicazioni sui
vecchi percorsi sono storiche. Per i percorsi attuali usa le guide principali.

## Principi per continuare

Conservare la separazione fra dati, regole, rendering e interfaccia.
Provare una meccanica vera prima di moltiplicarne i nomi. Validare mappe e
salvataggi anche quando l'interfaccia impedisce normalmente dati errati.
Mantenere leggibili i testi e non muovere la camera senza necessita.
Per ogni modifica verificare anche la distribuzione esportata: importare
nell'editor non basta a dimostrare che un pacchetto funzioni su un altro PC.
