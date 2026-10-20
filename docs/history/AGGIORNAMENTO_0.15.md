# Crateri 0.15 - campo e bordi

Il campo non puo piu essere ridotto fino a diventare un riquadro centrale:
lo zoom minimo segue la larghezza della finestra con piccoli margini laterali.
Nuova inquadratura iniziale piu vicina; il mare e mantenuto verso il fondo e
il personaggio attivo rimane sotto la fascia delle informazioni. La vecchia
preferenza zoom viene aggiornata una volta; le nuove scelte restano memorizzate.
C alterna panoramica completa e inquadratura vicina, rotella regola lo zoom.
La visuale vicina mostra una porzione della mappa, senza deformare il terreno.

Rimossi i limiti invisibili laterali dei personaggi. Oltre un raggio all'esterno
del terreno il verme viene eliminato, sia camminando sia per una spinta.

Verifiche esportato: inquadratura, larghezza minima, mare, eliminazione su
entrambi i lati; comandi mouse e zoom, 24 armi, casse/IA/scorte, editor,
pacchetti, granate, turni e vittoria. Catture controllate visivamente.
Log in verifiche/*0.15.log. Versione 0.14 conservata separatamente.
