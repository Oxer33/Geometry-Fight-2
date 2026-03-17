# TODO LIST - Geometry Fight 2

## ✅ COMPLETATO

### Core Gameplay
- [x] GameLoop base + player con movimento dual-stick
- [x] Proiettili + collisione base (8 tipi arma)
- [x] 17 nemici implementati con comportamenti distinti
- [x] 6 boss implementati con fasi multiple
- [x] Sistema wave (50 wave + endless mode)
- [x] Griglia deformabile con spring simulation
- [x] Sistema score/geomi/moltiplicatore
- [x] Sistema combo
- [x] 8 power-up funzionanti
- [x] Proiettili rimbalzano sui muri
- [x] Input mobile (dual joystick visuale) e desktop (WASD)
- [x] Camera follow player con smoothing
- [x] 4 livelli di difficoltà (Facile, Normale, Difficile, Incubo)
- [x] 5 modalità di gioco (Classica, Boss Rush, Sopravvivenza, Attacco a Tempo, Zen)
- [x] Perfect Wave bonus (+50 geomi se wave completata senza danni)
- [x] Screen flash rosso quando player viene colpito
- [x] Difficoltà applicata a: HP nemici, velocità, drop rate, vite, bombe

### UI/UX
- [x] Splash Screen con logo animato, particelle e esagono rotante
- [x] Main Menu con geometrie fluttuanti + pulsante CLASSIFICA
- [x] Schermata selezione modalità/difficoltà con card neon
- [x] Game Screen con overlay HUD
- [x] Pause Screen semi-trasparente
- [x] Game Over Screen con score/retry
- [x] Shop Screen con 5 categorie
- [x] Settings Screen (volume, vibrazione)
- [x] HUD moderna glassmorphism (score, vite, bombe, wave, combo, power-up)
- [x] Barra HP boss nella HUD durante boss fight
- [x] Joystick visuali neon con thumb mobile
- [x] Pulsante bomba pulsante con glow
- [x] Leaderboard locale con top 10, filtri per modalità, medaglie
- [x] Contatore nemici rimanenti in basso

### Grafica Player
- [x] Forma nave dettagliata con ali, cockpit, linee strutturali
- [x] Doppi thruster con fiamme animate (core bianco + arancione + glow rosso)
- [x] Trail di movimento (scia luminosa 18 punti)
- [x] Effetto overdrive arcobaleno (aura RGB rotante)
- [x] Wing-tip lights pulsanti (rosso/verde)
- [x] Scudo force field esagonale animato con doppio anello e punti energetici
- [x] Sfondo spaziale con stelle parallax, nebulose e polvere cosmica

### Grafica Nemici
- [x] Enemy base: doppio glow (soft+bright), mini HP bar, chromatic aberration hit, spawn pulse doppio
- [x] Drone: nucleo pulsante, croce interna, punti energetici sui vertici
- [x] Mine: punte animate pulsanti, anelli pericolo concentrici, scintille
- [x] Bouncer: archi rotanti velocità-dipendenti, nucleo luminoso proporzionale
- [x] Kamikaze: anelli di carica, scia di fuoco rush, nucleo incandescente
- [x] Weaver: linee strutturali, nucleo pulsante, punti energetici punte
- [x] Splitter: linee di frattura, nucleo colore-per-dimensione, indicatore livello split

### Dati
- [x] Salvataggio Hive persistente (geomi, upgrade, skin, highscore)
- [x] Sistema upgrade permanenti (8 categorie)
- [x] Spatial hash grid per collision detection O(n)
- [x] Leaderboard persistente con Hive (top 10 per modalità+difficoltà)

---

## 🔄 MIGLIORAMENTI FUTURI

### Alta Priorità
- [ ] Audio BGM + SFX (flame_audio predisposto, servono asset audio)
- [ ] Icona app personalizzata (flutter_launcher_icons)
- [ ] Tutorial pop-up primo avvio
- [ ] Indicatori freccia per nemici/boss fuori schermo

### Media Priorità
- [ ] Ship skins visive nel gioco (attualmente solo dati)
- [ ] Bullet trails cosmetici (fuoco, ghiaccio, plasma, arcobaleno)
- [ ] Migliorare grafica nemici rimanenti (Shield, BlackHole, Spawner, Snake)
- [ ] Slow-mo con desaturazione quando bomba attiva
- [ ] Death spiral boss (rotazione elementi al centro)
- [ ] Warp lines inizio wave (starfield warp)

### Bassa Priorità
- [ ] Object pooling completo per proiettili/particelle/geomi
- [ ] Fragment shader GLSL per glow avanzato
- [ ] Leaderboard online
- [ ] Vibrazione haptic su mobile
- [ ] FPS counter opzionale
- [ ] Animazioni transizione tra screen
- [ ] Doppler pitch proiettili nemici

---

## 🐛 BUG NOTI RISOLTI
- [x] Joystick sinistro non funzionava (moveInput sovrascritta da keyboard handler)
- [x] AnimatedBuilder duplicato (unificato in NeonAnimatedBuilder)
- [x] Leech non rallentava effettivamente il player (fix: modifica player.speed)
- [x] API deprecata activeColor in settings_screen (fix: activeTrackColor)

## 📝 NOTE PER SVILUPPATORI FUTURI
- I flag `usingTouchMove`/`usingTouchAim` evitano conflitti touch/keyboard
- SpaceBackground priority -20, GridDistortion priority -10
- La HUD usa _GameNotifier con rebuild ogni 80ms
- I 3 nuovi nemici (Leech, Titan, Glitch) integrati nelle wave 1-50 e endless
- DifficultyConfig applicata a spawn in game_world.spawnEnemy()
- Leaderboard auto-save al game over in game_screen.dart
- Perfect Wave tracking con _hitThisWave flag

---

## ✅ COMPLETATO (Sessione 3 - Marzo 2026)

### Fix Critici
- [x] Fix wave system: nemici non spawnavano dopo wave 1 (_postSpawnDelay 1.5s)
- [x] Modalità di gioco effettivamente implementate nel wave system

### Nuovi Contenuti
- [x] 5 nuovi nemici: Healer (cura), Orbiter (orbita+spara), Siren (rallenta proiettili), Necro (resuscita), Tesla (archi elettrici)
- [x] 5 nuovi boss: Nexus Prime (portali), Void Reaper (zone morte), Tesla Lord (torri fulmini), Phantom King (invisibilità+cloni), Omega Core (boss finale supremo HP:3000)
- [x] Wave estese da 50 a 75 con nuovi boss

### Meccaniche
- [x] Attrazione geomi passiva 80px (senza power-up)
- [x] Velocità attrazione proporzionale alla distanza

### Grafica Nemici Upgrade (10 nemici migliorati)
- [x] Drone: nucleo pulsante, croce, punti energetici
- [x] Mine: punte animate, anelli pericolo, scintille
- [x] Bouncer: archi velocità, nucleo luminoso
- [x] Kamikaze: anelli carica, scia fuoco, nucleo incandescente
- [x] Weaver: linee strutturali, nucleo, punti energetici
- [x] Splitter: linee frattura, indicatore livello
- [x] Shield: force field multi-layer, segmenti HP, indicatore regen
- [x] BlackHole: doppio anello gravitazionale, particelle spiralanti, indicatore raggio
- [x] Spawner: linee strutturali, indicatore spawn, punti vertici
- [x] Snake: connessioni luminose, gradiente colore, occhi sulla testa

### UI
- [x] Splash screen cinematografico (navicella insegue drone, esplosione, logo)

---

*Ultimo aggiornamento: Marzo 2026*
