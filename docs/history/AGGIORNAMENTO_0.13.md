# Aggiornamento 0.13

Sostituito il generatore che ripeteva le tre fasce con world_generator.gd:
sei archetipi (isole, continente cavernoso, canyon, rovine, archi e coste).
Primitivi diversi e parametri casuali cambiano la topologia, non soltanto il colore.
Seme positivo riproducibile per tipo. La selezione o Rigenera producono una nuova
variante; R mantiene il terreno e rimescola i personaggi. La dimensione resta
2200x700. Le quattro mappe classiche e i file precedenti rimangono supportati.

Gli ancoraggi vengono cercati sul terreno generato e validati per quattro membri;
se necessario vengono aggiunti due appoggi di recupero. Le partenze mescolate
campionano tutti gli appoggi, con distanze minime e avversari vicini quando
possibile. Un pacchetto conserva la maschera esatta e gli ancoraggi: il seme non
e necessario per riaprire una creazione. L'anteprima delle partenze e indicativa.

GameAudio sintetizza otto campioni PCM originali a 22050 Hz, con inviluppo e
rumore filtrato. Pool di 12 voci, volume iniziale moderato, variazione di tono
per danno dell'arma, una sola esplosione sonora per fotogramma per evitare la
sovrapposizione di cinque impatti della stessa scarica. Pausa e mute interrompono
correttamente la riproduzione; nessuna dipendenza da audio remoto.

verify_random_audio.gd verifica tre semi per ognuna delle sei famiglie, distanza
tra maschere binarie, riproducibilita, Rigenera, otto appoggi validi, pacchetto
esatto, campioni distinti non muti e senza saturazione individuale, lancio e mute.
Il confronto visivo dei sei archetipi e in verifiche/mappe-varieta-0.13.png.
La qualita percettiva dei suoni e il bilanciamento restano da provare dall'utente.
