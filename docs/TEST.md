# Test

Esegui `pwsh -File tools/run_tests.ps1 -GodotExe <eseguibile-Godot-4.5.1>`.
Gli script isolano dati e log sotto `.local/`, esclusa dalla distribuzione.
Controllano sia il codice d'uscita sia errori/assert nel testo: alcune prove
Godot possono terminare il processo con zero anche dopo un assert.

| Suite principale | Cosa verifica |
| --- | --- |
| verify.gd | Movimento, armi base, editor, squadre, menu, file e turni |
| verify_new_weapons.gd | Guida, telecomando, frammenti, incursioni, teletrasporto e corpo a corpo |
| verify_arsenal_all.gd | Conclusione del tiro e munizioni per tutte le 36 armi |
| verify_upgrade.gd | Casse, salute, scorte, IA e compatibilita |
| verify_expansion.gd | Mappe, partenze, difficolta, arsenale e input |
| verify_random_audio.gd | Semi, variazioni geometriche, appoggi, pacchetti e audio |
| verify_tall_camera.gd | Mondo alto, camera stabile, file e coordinate dell'editor |
| verify_restyle.gd | Immagini, maschera fisica, texture, wormfront e apertura editor |

`verify_display.gd` richiede una finestra e verifica piu risoluzioni, fino al
4K, clic reali, aiuto, F11 e audio. Gli altri script visivi in tests sono
strumenti storici o manuali: non ogni vecchia cattura e una suite di regressione.

La rilettura dei pixel GPU viene verificata con renderer reale. Il renderer
Dummy senza display non aggiorna i dati GPU come una finestra renderizzata:
in headless si verificano maschera e binding della texture, con la prova
visiva separata sull'eseguibile Windows.

`tools/verify_export.gd` verifica che il programma esportato sia autonomo,
contenga i dati corretti ed escluda cartelle di sviluppo, poi prova menu,
editor, pacchetti, pausa, granata e vittoria.

Prima di una release provare inoltre installazione/disinstallazione in
una destinazione temporanea, pacchetto estratto e integrita degli archivi.
Le prove automatiche non dimostrano il bilanciamento di ogni seme casuale
ne il funzionamento su ogni GPU o su un secondo PC fisico.

La suite verify_rebrand.gd verifica il nuovo nome e la lettura dei vecchi formati.

