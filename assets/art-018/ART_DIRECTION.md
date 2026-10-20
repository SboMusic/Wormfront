# Direzione artistica Wormfront 0.18

19 ottobre 2026. Prima scena giocabile del restyling, stile cartoon dipinto.
Generazione: strumento integrato image_gen, senza CLI o API esterne configurate.
Tutti i file consumati dal gioco sono copiati in questa cartella.

## File

- twilight.png: sfondo illustrato, usato in partita e dietro il menu.
- worm.png: personaggio con trasparenza, direzione destra; animazione procedurale
  di respiro e movimento, specchiatura per la direzione, fascia della squadra.
- weapons.png: tavola trasparente di sei famiglie di armi. Le regioni effettive
  sono definite in painted_art.gd; le varianti delle 24 armi condividono le famiglie.
- stone.png: texture dipinta della sezione rocciosa, ripetuta dal materiale.
- terrain.gdshader: materiale del terreno. La trasparenza della maschera fisica
  originale determina la sagoma e i wormfront; il materiale cambia solo il colore.

La tavola armi e il personaggio preservano l'alpha generato. Il codice ritaglia
le regioni per l'uso nel motore; gli originali restano disponibili qui.
Il tema dei controlli e in visual_style.gd. Non e una nuova simulazione fisica.

## Prompt finali usati

### Sfondo
Use case: stylized-concept. Production game asset for original PC 2D cartoon artillery game Wormfront. Create a polished wide 16:9 hand-painted background ONLY, no foreground collision terrain, no characters, no weapons, no UI and no text. Whimsical luminous twilight landscape with layered distant jagged mesas and floating rock arches, soft lavender clouds, deep teal pine silhouettes along bottom, turquoise mist, subtle warm sunset glow behind central opening. High quality painterly cartoon illustration, crisp confident shapes, richly colored but low contrast and dark enough behind gameplay. Main upper half spacious blue-violet sky, scenery concentrated at lower edges and distant horizon; no large bright moon. Full bleed composition, original visual identity, not copied from any existing game. Intended to fill gameplay screen and menu background.

### Verme (transparent_background=true)
Use case: stylized-concept. Production sprite for original 2D cartoon artillery game Wormfront. ONE cute expressive peach-pink worm adventurer, full body side view facing RIGHT. No arms, no legs, no weapon, no hat, no props. Curled segmented horizontal tail extends left, upright pear-shaped head on right with two huge expressive white eyes looking right, raised eyebrow, confident small grin, warm pink cheeks. Body has 5 clear subtle belly segments. Excellent hand-painted 2D game animation character, thick dark plum contour, soft warm highlights, saturated coral shadow, clean readable silhouette. Transparent background with real alpha, no floor, no shadow, no text, no frame. Center the whole character within generous transparent padding. Wide roughly 4:3 composition. This will be displayed at only 40 pixels high, so avoid small details. Original character, do not copy any existing game character.

### Armi (transparent_background=true)
Use case: stylized-concept. Production weapon icon atlas for original 2D cartoon game Wormfront. Transparent background real alpha. EXACT 3 columns by 2 rows equal-size grid, no grid lines, no text. Six separate objects, one centered in each of the 6 equal cells, ample transparent margin, no overlap between cells. Same hand painted cartoon style throughout, thick dark navy contour, warm metal reflections, expressive chunky silhouettes, each horizontal object faces RIGHT. TOP LEFT: teal and brass oversized rocket launcher with wooden grip and flared open muzzle. TOP CENTER: round olive-green grenade with brass pin and yellow band. TOP RIGHT: futuristic silver and turquoise ray gun, round luminous cyan core. BOTTOM LEFT: warm wooden double-barrel blaster with silver barrels. BOTTOM CENTER: mechanical handheld drill with gold conical bit pointing right and dark teal motor housing. BOTTOM RIGHT: red and brass heavy rocket launcher with twin barrels and chunky grip. All objects seen perfectly from the side, centered, no hands or characters, no backdrop, no ground shadow, no lettering. Consistent crafted cartoon adventure visual quality, readable at 70px. Wide 3:2 canvas, equal square cells.

### Terreno
Use case: stylized-concept. Production terrain texture, square seamless tile, for original 2D cartoon platform artillery game Wormfront. Full frame cross section of earth and stone: richly hand-painted warm ochre and umber compact soil with large irregular blue-grey slate boulders embedded, some small amber mineral veins and tiny pebbles. Flat orthographic cross-section, no horizon, no surface grass, no sky, no objects, no lettering, no background. Tile must fill all edges and be repeatable. Confident dark brown outlines around organically rounded asymmetric rocks, warm highlighted upper rock facets, soft cool shadows, tactile painted texture, clean high-end 2D cartoon videogame asset rather than photoreal. Mostly medium-dark earth, rocks about 40% coverage, no regular brick grid. Keep detail readable when tiled at 512 game pixels.
