# TODO LIST - Geometry Fight 2

## ✅ COMPLETATO

### Core Gameplay
- [x] GameLoop base + player con movimento dual-stick
- [x] Proiettili + collisione base (8 tipi arma)
- [x] 27 nemici implementati con comportamenti distinti
- [x] 16 boss implementati con fasi multiple
- [x] Sistema wave (100 wave + endless mode)
- [x] Griglia deformabile con spring simulation
- [x] Sistema score/geomi/moltiplicatore
- [x] Sistema combo
- [x] 8 power-up funzionanti
- [x] Proiettili rotondi (non rimbalzano, si distruggono fuori arena)
- [x] Input mobile (dual joystick visuale) e desktop (WASD)
- [x] Camera follow player con smoothing
- [x] 4 livelli di difficoltà (Facile, Normale, Difficile, Incubo)
- [x] 6 modalità di gioco (Classica, Boss Rush, Sopravvivenza, Attacco a Tempo, Zen, Tunnel)
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
- [ ] Audio BGM + SFX reali (attualmente solo feedback aptico)
- [x] Icona app personalizzata (generata + flutter_launcher_icons)
- [ ] Tutorial pop-up primo avvio
- [x] Indicatori freccia per nemici/boss fuori schermo (max 8, rosse+oro boss)

### Media Priorità
- [ ] Ship skins visive nel gioco (attualmente solo dati)
- [ ] Bullet trails cosmetici (fuoco, ghiaccio, plasma, arcobaleno)
- [x] Grafica nemici migliorata (tutti i 27 nemici con effetti spettacolari)
- [ ] Slow-mo con desaturazione quando bomba attiva
- [ ] Death spiral boss (rotazione elementi al centro)
- [ ] Warp lines inizio wave (starfield warp)

### Bassa Priorità
- [ ] Object pooling completo per proiettili/particelle/geomi
- [ ] Fragment shader GLSL per glow avanzato
- [ ] Leaderboard online
- [x] Vibrazione haptic su mobile (AudioSystem con HapticFeedback)
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

## ✅ COMPLETATO (Sessione 4 - Marzo 2026)

### Code Review Professionale
- [x] Fix highscore hardcoded 'classic' → usa gameMode.name
- [x] Rimossi import inutilizzati score_system.dart  
- [x] Rimossa classe AnimatedBuilder duplicata da main_menu.dart
- [x] Menu responsive landscape/portrait con bottoni compatti

### UI/UX
- [x] Splash screen: tasto SKIP visibile, proiettili che colpiscono drone, flash impatto
- [x] Menu principale: layout a 2 colonne landscape, bottoni con icone, responsive
- [x] Modalità sbloccate per test (kDebugUnlockAll)

### 5 Nuovi Nemici (27 totali)
- [x] Gravity Well (indaco): campo gravitazionale, spirale interna, particelle orbitanti
- [x] Swarm Drone (rosa): gruppi enormi, si enragiano quando uno muore
- [x] Laser Turret (rosso): stazionaria, laser rotante 360°, warmup con indicatore
- [x] Time Bomb (arancio): countdown 8s visibile, scudo 2s, esplosione area 200px
- [x] Decoy (verde ingannevole): imita power-up, esplode vicino, scopribile sparandogli

### 5 Nuovi Boss (16 totali)
- [x] Mirror Master (wave 80): ottagono con facce riflettenti shimmer
- [x] Swarm Queen (wave 85): alveare con ali membranose, spawna sciami
- [x] Graviton (wave 90): sfera nera con anelli dorati, alterna PULL/PUSH gravità
- [x] Inferno (wave 95): stella 5 punte con scie di fuoco, nucleo incandescente
- [x] Eternity Engine (wave 100): BOSS DEFINITIVO, triplo anello arcobaleno, 4 fasi

### Nuova Modalità
- [x] Tunnel infinito: nemici in corridoio veloce, boss ogni 5 wave

### Meccaniche
- [x] Wave estese da 75 a 100 con boss batch 3
- [x] Tutti i 27 nemici nelle endless waves
- [x] Self-review: fix endless waves, analisi Q&A step-by-step

---

## ✅ COMPLETATO (Sessione 5 - Marzo 2026)

### Fix Critici Gameplay
- [x] Boss non perdevano vita: aggiunto BossBase check in PlayerBullet.onCollisionStart
- [x] Proiettili rettangolari → rotondi (CircleHitbox radius:3, drawCircle)
- [x] Proiettili rimbalzavano sui muri → distrutti quando escono dall'arena
- [x] Splash screen navicella in retromarcia → punta a destra, stessa forma in-game
- [x] Boss Rush 2 boss contemporanei → solo boss per wave, nemici dal boss stesso
- [x] Hitbox boss 80% → 95% della dimensione visiva

### Modalità Tunnel Completa
- [x] TunnelRenderer con muri neon ondeggianti (curve sinusoidali)
- [x] Ostacoli barriera laser (spawn periodico, danno al contatto)
- [x] Doppia linea parallasse + linee guida velocità
- [x] Arena dinamica 600px corridoio → 1800px per boss fight
- [x] Player e nemici confinati nel tunnel

### Boss Spawn Nemici
- [x] Ogni boss spawna 3-9 nemici ogni 5s automaticamente
- [x] Tipi nemici progressivi per fase (drone→kamikaze→splitter)
- [x] Più veloce nelle fasi avanzate del boss

### Meccaniche Modalità
- [x] Zen mode: vite infinite (respawn immediato)
- [x] Time Attack: timer 180s countdown con game over automatico
- [x] Tutte le 6 modalità verificate e funzionanti

### Icona App
- [x] Generata programmaticamente (1024x1024 PNG)
- [x] Configurata con flutter_launcher_icons per Android e iOS

---

*Ultimo aggiornamento: Marzo 2026*
