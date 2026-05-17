import 'dart:ui';
import 'constants.dart';

/// Pet companion type (ispirato Geometry Wars 3 Dimensions: Attack, Collect,
/// Ram, Snipe, Defend, Sweep).
///
/// Ogni pet ha comportamento unico in battaglia:
/// - `none`: nessun pet equipaggiato.
/// - `attack`: segue il player, spara bullet aggiuntivi nella stessa direzione.
/// - `collect`: vola indipendente, magnetizza geoms verso il player.
/// - `sweep`: orbita il player, instakill nemico al contatto.
/// - `defend`: segue retro player, spara nella direzione opposta.
/// - `snipe`: orbita lento, laser ray al nemico più vicino periodico.
/// - `ram`: insegue nemico più vicino e si schianta (kill al contatto).
enum PetType {
  none,
  attack,
  collect,
  sweep,
  defend,
  snipe,
  ram,
  shieldOrb,
  magnetCore,
  turretDrone,
  vampire,
}

/// Definizione metadata pet — display name, descrizione, costo gold,
/// colore neon. Usato da shop + loadout screen.
class PetDef {
  final PetType type;
  final String id;            // string id per persistenza saveData
  final String displayName;
  final String description;
  final int cost;             // gold per unlock (0 = unlock di default)
  final Color color;
  final String iconCode;      // 1-2 char rappresentazione testuale (loadout grid)

  const PetDef({
    required this.type,
    required this.id,
    required this.displayName,
    required this.description,
    required this.cost,
    required this.color,
    required this.iconCode,
  });
}

/// Catalog completo pet disponibili. `none` esclusa (è il default no-pet).
const List<PetDef> kPetCatalog = [
  PetDef(
    type: PetType.attack,
    id: 'attack',
    displayName: 'ATTACK',
    description: 'Segue il player + spara raffiche extra. Doppia la firepower.',
    cost: 1500,
    color: NeonColors.bulletYellow,
    iconCode: 'A',
  ),
  PetDef(
    type: PetType.collect,
    id: 'collect',
    displayName: 'COLLECT',
    description: 'Vola libero raccoglie geoms a distanza. Boost economy.',
    cost: 1200,
    color: NeonColors.cyan,
    iconCode: 'C',
  ),
  PetDef(
    type: PetType.sweep,
    id: 'sweep',
    displayName: 'SWEEP',
    description: 'Orbita il player, instakill nemico al tocco.',
    cost: 2000,
    color: NeonColors.pink,
    iconCode: 'S',
  ),
  PetDef(
    type: PetType.defend,
    id: 'defend',
    displayName: 'DEFEND',
    description: 'Segue retro player, spara nella direzione opposta.',
    cost: 1800,
    color: NeonColors.green,
    iconCode: 'D',
  ),
  PetDef(
    type: PetType.snipe,
    id: 'snipe',
    displayName: 'SNIPE',
    description: 'Orbita lento + laser al nemico più vicino ogni 1.5s.',
    cost: 2200,
    color: NeonColors.laserRed,
    iconCode: 'N',
  ),
  PetDef(
    type: PetType.ram,
    id: 'ram',
    displayName: 'RAM',
    description: 'Insegue + si schianta sul nemico più vicino. Cooldown 1s.',
    cost: 2500,
    color: NeonColors.orange,
    iconCode: 'R',
  ),
  PetDef(
    type: PetType.shieldOrb,
    id: 'shield_orb',
    displayName: 'SHIELD ORB',
    description: 'Orbita il player. Genera scudo 1-hit ogni 30s.',
    cost: 2400,
    color: NeonColors.cyan,
    iconCode: 'O',
  ),
  PetDef(
    type: PetType.magnetCore,
    id: 'magnet_core',
    displayName: 'MAGNET CORE',
    description: 'Attira tutti i geom verso il player entro 400px.',
    cost: 1600,
    color: NeonColors.orange,
    iconCode: 'M',
  ),
  PetDef(
    type: PetType.turretDrone,
    id: 'turret_drone',
    displayName: 'TURRET DRONE',
    description: 'Orbita il player. Spara al nemico più vicino ogni 1.5s.',
    cost: 2000,
    color: NeonColors.yellow,
    iconCode: 'T',
  ),
  PetDef(
    type: PetType.vampire,
    id: 'vampire',
    displayName: 'VAMPIRE',
    description: 'Kill nemico entro 200px: 5% chance +1 HP al player.',
    cost: 2800,
    color: NeonColors.red,
    iconCode: 'V',
  ),
];

/// Lookup PetDef da string id (saveData.activePet). Ritorna null se 'none'
/// o id sconosciuto.
PetDef? petDefById(String id) {
  for (final p in kPetCatalog) {
    if (p.id == id) return p;
  }
  return null;
}

/// Lookup PetType da string id. Ritorna `PetType.none` se id sconosciuto
/// o esplicitamente 'none'.
PetType petTypeById(String id) {
  if (id == 'none' || id.isEmpty) return PetType.none;
  return petDefById(id)?.type ?? PetType.none;
}
