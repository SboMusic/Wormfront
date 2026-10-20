# Pubblicazione e dati personali

La distribuzione di progetto usa **SboMusic** come autore.
La copia pubblica e separata dall'ambiente di sviluppo originale.

Sono esclusi cache Godot, profili utente, log locali, vecchie distribuzioni,
archivi del motore, credenziali e dati personali. I riferimenti alle risorse
sono relativi a res://; gli script accettano il percorso del motore come
parametro, senza richiedere il computer originale.

Prima di pubblicare vengono controllati nomi dei file, contenuti testuali,
binari di distribuzione e metadati testuali delle immagini, cercando percorsi
utente, identificativi privati noti e possibili credenziali. I pacchetti sono
verificati anche dopo l'estrazione e associati a somme SHA256.

Le licenze di Godot includono nomi ed email dei loro autori: sono attribuzioni
legali di terze parti e non vengono sostituite con il nome del progetto.
Anche il binario del motore puo contenere attribuzioni e percorsi di compilazione dei suoi autori. Il template ufficiale e modificato soltanto nelle risorse icona/versione con RCEdit; il controllo riconosce la build verificata tramite SHA256.

Il controllo riguarda i file pubblicati, non cambia nome o visibilita del
profilo GitHub. I log di test generati su ogni computer rimangono privati
in .local e non fanno parte degli archivi pubblici. Le creazioni dei giocatori
restano nella loro cartella dati, non nella repository.

Per ripetere il controllo usa tools/audit_publication.mjs con Node.js.
I marcatori personali facoltativi si passano attraverso l'ambiente locale,
non si scrivono nei file versionati. Il report elenca categorie e percorsi
relativi, senza riprodurre i valori personali cercati.

