# Crateri 0.12

Richieste implementate: zoom persistente durante la sessione e il riavvio della
partita; M per arsenale; destro trascinato per potenza; sinistro tenuto per carica
e rilascio per tiro; anteprime specifiche per famiglia; armi illustrate in mano;
venti mappe grandi a tre piani con rampe e aperture; partenze casuali mescolate.

La preferenza zoom resta distinta dallo zoom temporaneo della panoramica.
Non viene ancora salvata tra chiusura e riapertura del programma.
Il clic rapido mantiene la potenza corrente; la carica prolungata riparte da 150.
Mouse rilasciato sopra l'interfaccia non lascia una carica o trascinamento attivo.
Menu, editor, cambio turno e riavvio interrompono le azioni del mouse.

trajectory_preview.gd condivide bocca di lancio, gravita, miccia, coefficienti di
rimbalzo, raggi di collisione e sottopassi del tiro. Risultati memorizzati finche
mira, potenza, terreno, arma e personaggi restano invariati. Raggi e schegge sono
rettilinei; i raggi coincidono con la collisione usata dal tiro istantaneo.
La simulazione non modifica terreno, salute o munizioni. Le anteprime su bersagli
in movimento e trivelle restano approssimate; una scarica puo eliminare un
bersaglio prima degli ultimi frammenti, cambiandone il punto di arresto.

TeamSpawns.scattered usa un generatore casuale locale, campiona appoggi su tutte
le quote, evita compenetrazioni e distanze sotto 55 px e cerca un avversario a
80-280 px da ciascun alleato. Con tre membri cerca quote alta/media/bassa.
Se il terreno non offre abbastanza posti, ritorna al posizionamento tradizionale
validato. Nel menu e mostrato un esempio deterministico, non l'estrazione futura.
Il formato delle creazioni resta versione 1 con scatter_spawns opzionale.

verify_fixes.gd copre zoom, panoramica, M, destro e carica/rilascio, anteprima
rettilinea e impatto reale, ventaglio, parabole e granate, assenza di mutazioni,
semi differenti, appoggi validi, distanza tra personaggi, avversari vicini e tre
quote usate. Restano le suite precedenti e le verifiche della distribuzione.
