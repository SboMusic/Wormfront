# Compilazione e distribuzione

## Requisiti

Godot **4.5.1 Standard** per sviluppare, PowerShell 7 per gli script degli
sviluppatori, template Windows x64 **4.5.1.stable** per esportare.
Godot e i template si ottengono dalle distribuzioni ufficiali di Godot.
Non sono inclusi nel repository. Chi gioca non deve installarli.

Apri `project.godot` in Godot e attendi l'importazione. F5 avvia il progetto.
Per la riga di comando imposta GODOT_EXE o passa `-GodotExe` agli script.
Esempio con percorsi scelti da te, non riferimenti a un computer specifico:

```powershell
$env:GODOT_EXE = 'D:\Godot\Godot_v4.5.1-stable_win64_console.exe'
pwsh -File tools/run_tests.ps1
pwsh -File tools/build_windows.ps1 -TemplateDir 'D:\Godot\templates\4.5.1.stable'
pwsh -File tools/package_windows.ps1
```

I percorsi dell'esempio sono illustrativi. Se i template ufficiali sono
installati nella cartella standard Godot su Windows, TemplateDir e opzionale.
Lo script li copia in `.local/export-templates` senza includerli nei commit.
Il preset di esportazione usa solo percorsi relativi.

## Risultati

- `dist/Crateri-0.19.1-Windows-x64/`: eseguibile, PCK, guide e licenze.
- ZIP con lo stesso nome: pacchetto portatile.
- `dist/Crateri-0.19.1-Windows-Setup.zip`: installazione per utente Windows.
- File `.sha256`: controllo di integrita dei pacchetti.

Importazione e build usano un profilo dati isolato in `.local`.
Non copiano i salvataggi personali dell'autore nella distribuzione.
Non sono richieste firme o certificati privati per ricompilare il prototipo.

## Creare una release

Esegui i test, costruisci i pacchetti e provali dopo estrazione in una
cartella nuova. Controlla le somme SHA256, le licenze e gli screenshot.
L'eseguibile e il PCK vanno negli allegati della release, non nella cronologia
Git: la repository conserva sorgenti, asset e strumenti riproducibili.
Tag suggerito per questa distribuzione: `v0.19.1`.

Il codice dell'installer e in `installer/`. `Installa.cmd` usa PowerShell
incluso in Windows e installa nella cartella locale dell'utente; non crea
servizi, regole di rete o attivita pianificate. `-NoShortcuts` permette una
prova isolata senza modificare il menu Start. Il disinstallatore rimuove
soltanto i file elencati nel proprio manifest, senza cancellare salvataggi.

## Verifica visiva

Per catturare il gioco esportato:

```powershell
.\dist\Crateri-0.19.1-Windows-x64\Crateri.exe --script tools/capture_screenshots.gd -- docs/screenshots
```

Il file di cattura deve essere indicato con un percorso assoluto se il processo
viene avviato da una cartella diversa. Usa screenshot generati dalla release,
senza finestre, nomi di file personali o schermate dell'account del sistema.
