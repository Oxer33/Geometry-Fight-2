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
/// - `phoenix`: auto-revive player una volta per run quando HP raggiunge 0.
/// - `blackHolePet`: micro pozzo gravitazionale stazionario davanti al player.
/// - `empDrone`: pulse stun nemici entro 250px ogni 8s.
/// - `tacticalSpotter`: trigger slow-mo quando il player è in salute critica.
/// - `slower`: campo di rallentamento davanti al player; rallenta i nemici vicini.
enum PetType {
  none,
  attack,
  collect,
  sweep,
  defend,
  snipe,
  ram,
  phoenix,
  blackHolePet,
  empDrone,
  tacticalSpotter,
  slower,
  bomber,
  repulsor,
}

/// Definizione metadata pet — display name, descrizione, costo gold,
/// colore neon. Usato da shop + loadout screen.
class PetDef {
  final PetType type;
  final String id; // string id per persistenza saveData
  final String displayName;
  final String description;
  final int cost; // gold per unlock (0 = unlock di default)
  final Color color;
  final String iconCode; // 1-2 char rappresentazione testuale (loadout grid)

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
    cost: 15000,
    color: NeonColors.bulletYellow,
    iconCode: 'A',
  ),
  PetDef(
    type: PetType.collect,
    id: 'collect',
    displayName: 'COLLECT',
    description: 'Vola libero raccoglie geoms a distanza. Boost economy.',
    cost: 12000,
    color: NeonColors.cyan,
    iconCode: 'C',
  ),
  PetDef(
    type: PetType.sweep,
    id: 'sweep',
    displayName: 'SWEEP',
    description: 'Orbita il player, instakill nemico al tocco.',
    cost: 20000,
    color: NeonColors.pink,
    iconCode: 'S',
  ),
  PetDef(
    type: PetType.defend,
    id: 'defend',
    displayName: 'DEFEND',
    description: 'Segue retro player, spara nella direzione opposta.',
    cost: 18000,
    color: NeonColors.green,
    iconCode: 'D',
  ),
  PetDef(
    type: PetType.snipe,
    id: 'snipe',
    displayName: 'SNIPE',
    description: 'Orbita lento + laser al nemico più vicino ogni 1.5s.',
    cost: 22000,
    color: NeonColors.laserRed,
    iconCode: 'N',
  ),
  PetDef(
    type: PetType.ram,
    id: 'ram',
    displayName: 'RAM',
    description: 'Insegue + si schianta sul nemico più vicino. Cooldown 1s.',
    cost: 25000,
    color: NeonColors.orange,
    iconCode: 'R',
  ),
  PetDef(
    type: PetType.phoenix,
    id: 'phoenix',
    displayName: 'PHOENIX',
    description: 'Auto-revive una volta per run + 2s di invincibilità.',
    cost: 35000,
    color: NeonColors.orange,
    iconCode: 'P',
  ),
  PetDef(
    type: PetType.blackHolePet,
    id: 'black_hole_pet',
    displayName: 'BLACK HOLE',
    description: 'Pozzo gravitazionale: trascina i nemici entro 150px.',
    cost: 28000,
    color: NeonColors.purple,
    iconCode: 'B',
  ),
  PetDef(
    type: PetType.empDrone,
    id: 'emp_drone',
    displayName: 'EMP DRONE',
    description: 'Pulse stun nemici entro 250px ogni 8s (0.5s di stordimento).',
    cost: 26000,
    color: NeonColors.cyan,
    iconCode: 'E',
  ),
  PetDef(
    type: PetType.tacticalSpotter,
    id: 'tactical_spotter',
    displayName: 'TACTICAL SPOTTER',
    description: 'Slow-mo 0.5s quando il player è in salute critica. CD 6s.',
    cost: 30000,
    color: NeonColors.lime,
    iconCode: 'T',
  ),
  PetDef(
    type: PetType.slower,
    id: 'slower',
    displayName: 'SLOWER',
    description:
        'Crea un campo di rallentamento davanti alla navicella: i nemici '
        'che entrano nel campo si muovono al rallentatore.',
    cost: 24000,
    color: NeonColors.teal,
    iconCode: 'L',
  ),
  PetDef(
    type: PetType.bomber,
    id: 'bomber',
    displayName: 'BOMBER',
    description:
        'Sgancia mine esplosive attorno al player: detonano al contatto coi '
        'nemici o a fine vita, infliggendo danno ad area.',
    cost: 31000,
    color: NeonColors.orange,
    iconCode: 'M',
  ),
  PetDef(
    type: PetType.repulsor,
    id: 'repulsor',
    displayName: 'REPULSOR',
    description:
        'Campo di forza che respinge i nemici vicini al player: nessun danno, '
        'puro controllo difensivo (opposto del Black Hole).',
    cost: 27000,
    color: NeonColors.lime,
    iconCode: 'X',
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
