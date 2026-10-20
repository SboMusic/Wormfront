# Verifiche della distribuzione 0.20.0

Eseguite il 20 ottobre 2026 su Windows con Godot 4.5.1:

- Nove suite automatiche: tutte PASS; inclusa compatibilita con mappe,
  arsenali e pacchetti salvati nei formati precedenti.
- Catture del gioco esportato con renderer reale OpenGL/NVIDIA: PASS.
- Metadati Windows: ProductName Wormfront, CompanyName SboMusic,
  OriginalFilename Wormfront.exe, versione 0.20.0.0.
- Icona PNG trasparente, ICO 16/32/48/64/128/256 e icona nell'eseguibile.
- Eseguibile esportato: menu, editor, armi, pacchetti, pausa, granata e vittoria.
- Installer provato in cartella isolata, senza modificare i collegamenti reali.
- Audit dei file sorgenti e dei pacchetti estratti con marcatori privati locali.

Il motore mantiene le attribuzioni dei suoi autori. Le sue risorse Windows
sono aggiornate con RCEdit ufficiale, senza modificare il codice del motore.
Non verificati: collegamento Start nel profilo reale, secondo PC fisico,
compatibilita con ogni GPU e bilanciamento di ogni mappa casuale.
