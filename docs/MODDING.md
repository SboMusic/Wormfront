# Modificare Crateri

## Avvio rapido per chi sviluppa

Installa Godot 4.5.1 Standard, importa il `project.godot` alla radice e premi F5.
I file in `src/` sono GDScript. `main.tscn` e la scena di avvio.
Prima di modificare crea un ramo Git o una copia; esegui le prove pertinenti.
Per lavorare non servono i binari di Windows o le cache dell'autore.

## Parametri delle armi

`data/weapons.json` e un array di definizioni. Puoi duplicare una voce,
rinominarla, modificarla e aggiungerla all'array fino a 64 voci; il formato
richiede almeno due voci. Il catalogo viene letto all'avvio.

```json
{
  "name": "Razzo del laboratorio",
  "kind": "projectile",
  "trigger": "impact",
  "damage": 55,
  "crater_radius": 48,
  "damage_radius": 90,
  "impulse": 240,
  "gravity_scale": 1.0,
  "ammo": 4,
  "category": "Artiglieria",
  "color": "ffd58c"
}
```

Questo e un elemento, non un file completo: inseriscilo nell'array esistente
separandolo dagli altri con una virgola. Usa JSON valido, senza commenti.

| Campo | Valori/limiti |
| --- | --- |
| name | Nome fino a 24 caratteri |
| kind | projectile, beam, scatter, drill, homing, controlled, airstrike, placed, melee, teleport |
| trigger | impact oppure fuse |
| damage | 1-100 |
| crater_radius | 8-120 |
| damage_radius | 16-180 |
| impulse | 0-500 |
| gravity_scale | 0.25-2; la guida dei missili usa il proprio movimento |
| fuse | 1-6 secondi per le armi a miccia |
| bounce | 0-0.85 |
| ammo | -1 illimitate, oppure 0-20 |
| cluster | 0-8; frammenti o bombe dell'incursione |
| category | Artiglieria, Bombe, Precisione, Speciali |
| color | Colore HTML senza #, per esempio ffd58c |

`src/data/weapon_catalog.gd` normalizza e limita i dati. Non tutti i parametri
hanno effetto su tutti i tipi: corpo a corpo, teletrasporto e guida hanno
regole proprie. Le icone sono associate in `src/art/weapon_art.gd`,
`painted_art.gd` e `special_weapon_art.gd`: aggiungere dati non genera da solo
una nuova illustrazione. Le varianti oltre il catalogo possono condividere
un'icona finche non ne aggiungi una specifica.

Per una meccanica nuova modifica in modo coerente catalogo, simulazione,
anteprima, UI, salvataggi, IA e test. Gli effetti aggiuntivi sono in
`src/game/expanded_weapons.gd`; la traiettoria prevista e in
`src/game/trajectory_preview.gd`. Un nome nuovo non equivale a una meccanica nuova.

## Regole

Il menu e l'editor scrivono le regole normalizzate da `src/data/arsenal_data.gd`.
Salute 1-300, turni 10-120 secondi, squadra 1-4, difficolta 0-2;
self_damage, ai_enabled, supplies e scatter_spawns sono booleani.
Le configurazioni `.arsenale` hanno format `crateri-arsenal`, version 1,
un array weapons e un oggetto rules. Conviene generare il primo file dall'editor.

## Mappe

Il modo piu semplice e F2. Per mappe procedurali:

- `src/world/terrain_factory.gd`: nomi e scelta del generatore.
- `src/world/world_generator.gd`: seme, famiglie, materiali e ancoraggi.
- `src/world/terrain_architecture.gd`: geometrie di cittadelle, camere,
  falesie e archi. Usa RNG passato dal chiamante per preservare il seme.
- `src/world/team_spawns.gd`: disposizione della squadra e partenze mescolate.

Una mappa e un'immagine RGBA: alpha trasparente significa vuoto, alpha pieno
significa terreno. I crateri modificano questa stessa maschera. Il materiale
visivo non deve introdurre superfici solide che la maschera non contiene.
Dimensioni ammesse: larghezze 1100/2200/3300 e altezze 700/1100.
Il mare e legato all'altezza del mondo; conserva spazio superiore, bordi
e appoggi validi. Verifica entrambe le squadre anche con quattro membri.

I `.crateri` contengono format `crateri-map`, version 1, terreno PNG in base64
e due coordinate di spawn. Non caricano script o percorsi esterni.
Modifica i formati solo aggiungendo migrazioni e prove di compatibilita.

## Grafica, menu e audio

Le immagini sono in `assets/art-018` e `assets/art-019`; prompt e note
spiegano come sono state realizzate. Mantieni trasparenza di vermi e icone.
Gli sfondi sono elencati in `src/art/painted_art.gd`: aggiungi il file a SKIES.
Il materiale del terreno e `assets/art-018/terrain.gdshader`, che legge
l'atlante art-019/materials.png e usa i colori del terreno per scegliere il tema.
`visual_style.gd` costruisce il tema UI; testi e spazi devono essere provati
anche al massimo ingrandimento. Gli editor lavorano in coordinate adattate.

`src/game/game_audio.gd` sintetizza gli effetti e gestisce mute e pausa.
Non distribuire audio, immagini o marchi di terzi senza una licenza adeguata.

## Verifica e condivisione

Esegui i test specifici e la regressione, importa il progetto da una cartella
pulita e crea un nuovo pacchetto. Riporta eventuali incompatibilita nel changelog.
Non includere `.godot`, `.local`, salvataggi o file di autenticazione nei commit.
Per le modifiche redistribuite conserva autore e licenze; l'uso consentito
resta quello non commerciale stabilito da LICENSE.
