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

### UI/UX
- [x] Main Menu con geometrie fluttuanti
- [x] Game Screen con overlay HUD
- [x] Pause Screen semi-trasparente
- [x] Game Over Screen con score/retry
- [x] Shop Screen con 5 categorie
- [x] Settings Screen (volume, vibrazione)
- [x] HUD moderna glassmorphism (score, vite, bombe, wave, combo, power-up)
- [x] Joystick visuali neon con thumb mobile
- [x] Pulsante bomba pulsante con glow

### Grafica
- [x] Sfondo spaziale con stelle parallax, nebulose e polvere cosmica
- [x] Effetti neon glow su tutti gli elementi
- [x] Screen shake su esplosioni
- [x] Explosion particles
- [x] Floating text (+punti sopra kill)
- [x] Spawn pulse ring
- [x] Trail proiettili

### Dati
- [x] Salvataggio Hive persistente (geomi, upgrade, skin, highscore)
- [x] Sistema upgrade permanenti (8 categorie)
- [x] Spatial hash grid per collision detection O(n)

---

## 🔄 IN CORSO / MIGLIORAMENTI FUTURI

### Alta Priorità
- [ ] Audio BGM + SFX (flame_audio predisposto ma asset mancanti)
- [ ] Tutorial pop-up primo avvio
- [ ] Barra HP boss durante boss fight nella HUD
- [ ] Indicatori freccia per nemici/boss fuori schermo
- [ ] Slow-mo con desaturazione quando bomba attiva
- [ ] Chromatic aberration flash quando player colpito
- [ ] "PERFECT WAVE!" bonus se wave completata senza danni

### Media Priorità
- [ ] Modalità Boss Rush (sbloccabile)
- [ ] Modalità Survival (sbloccabile)
- [ ] Modalità Challenge Pack
- [ ] Ship skins visive nel gioco (attualmente solo dati)
- [ ] Bullet trails cosmetici (fuoco, ghiaccio, plasma, arcobaleno)
- [ ] Death spiral boss (rotazione elementi al centro)
- [ ] Warp lines inizio wave (starfield warp)
- [ ] Doppler pitch proiettili nemici

### Bassa Priorità
- [ ] Object pooling completo per proiettili/particelle/geomi
- [ ] Fragment shader GLSL per glow avanzato
- [ ] Leaderboard online
- [ ] Vibrazione haptic su mobile
- [ ] FPS counter opzionale
- [ ] Aggiungere più boss per le wave 55, 60, ecc.
- [ ] Animazioni transizione tra screen

---

## 🐛 BUG NOTI RISOLTI
- [x] Joystick sinistro non funzionava (moveInput sovrascritta da keyboard handler ogni frame)
- [x] AnimatedBuilder duplicato in hud.dart e virtual_joystick.dart (unificato in NeonAnimatedBuilder)

## 📝 NOTE PER SVILUPPATORI FUTURI
- I flag `usingTouchMove`/`usingTouchAim` in `game_world.dart` servono a evitare conflitti touch/keyboard
- SpaceBackground ha priority -20, GridDistortion ha priority -10 (sotto tutto)
- La HUD usa _GameNotifier che rebuilda ogni 80ms (ottimizzabile)
- I nuovi nemici (Leech, Titan, Glitch) sono integrati sia nelle wave 1-50 che nelle endless

---

*Ultimo aggiornamento: Marzo 2026*
