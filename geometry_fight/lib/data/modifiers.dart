/// Modificatori di gioco (mutatori) per Geometry Fight 2.
/// Ogni modificatore altera le regole base per aggiungere varietà.

class GameModifier {
  final String id;
  final String name;
  final String description;
  final String icon;
  final double scoreMultiplier; // Bonus/malus ai punti
  final bool isChallenge; // true = più difficile, false = più facile

  const GameModifier({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.scoreMultiplier = 1.0,
    this.isChallenge = true,
  });
}

/// Tutti i modificatori disponibili
const List<GameModifier> allModifiers = [
  // === CHALLENGE (aumentano difficoltà, bonus punti) ===
  GameModifier(
    id: 'glass_cannon',
    name: 'CANNONE DI VETRO',
    description: '3x danno, ma 1 sola vita. Nessuna invincibilità.',
    icon: '💎',
    scoreMultiplier: 3.0,
    isChallenge: true,
  ),
  GameModifier(
    id: 'bullet_hell',
    name: 'BULLET HELL',
    description: 'I nemici sparano il doppio più velocemente.',
    icon: '🔴',
    scoreMultiplier: 2.0,
    isChallenge: true,
  ),
  GameModifier(
    id: 'speed_demon',
    name: 'SPEED DEMON',
    description: 'Tutto si muove 1.5x più veloce (player e nemici).',
    icon: '⚡',
    scoreMultiplier: 1.5,
    isChallenge: true,
  ),
  GameModifier(
    id: 'no_powerups',
    name: 'PURISTA',
    description: 'Nessun power-up durante la partita.',
    icon: '🚫',
    scoreMultiplier: 1.5,
    isChallenge: true,
  ),
  GameModifier(
    id: 'fog_of_war',
    name: 'NEBBIA DI GUERRA',
    description: 'Visibilità ridotta. Solo l\'area vicina è visibile.',
    icon: '🌫️',
    scoreMultiplier: 2.0,
    isChallenge: true,
  ),
  GameModifier(
    id: 'tiny_arena',
    name: 'ARENA PICCOLA',
    description: 'Arena ridotta del 50%. Meno spazio per schivare.',
    icon: '📦',
    scoreMultiplier: 1.5,
    isChallenge: true,
  ),

  // === FUN (alterano il gameplay, penalità punteggio) ===
  GameModifier(
    id: 'one_shot',
    name: 'ONE SHOT',
    description: 'Tutti i nemici muoiono con 1 colpo. Ma anche tu.',
    icon: '🎯',
    scoreMultiplier: 0.5,
    isChallenge: false,
  ),
  GameModifier(
    id: 'chaos',
    name: 'CAOS TOTALE',
    description: 'Power-up random ogni 10 secondi automaticamente.',
    icon: '🎲',
    scoreMultiplier: 0.8,
    isChallenge: false,
  ),
  GameModifier(
    id: 'giant_mode',
    name: 'GIGANTE',
    description: 'Tutto è 2x più grande. Nemici, proiettili, tutto.',
    icon: '🔍',
    scoreMultiplier: 0.8,
    isChallenge: false,
  ),
  GameModifier(
    id: 'ricochet_world',
    name: 'RIMBALZO TOTALE',
    description: 'Tutti i proiettili rimbalzano 5 volte.',
    icon: '🏓',
    scoreMultiplier: 0.7,
    isChallenge: false,
  ),
  GameModifier(
    id: 'infinite_bombs',
    name: 'BOMBER',
    description: 'Bombe infinite! Ma niente armi.',
    icon: '💣',
    scoreMultiplier: 0.5,
    isChallenge: false,
  ),
  GameModifier(
    id: 'magnet_king',
    name: 'RE MAGNETE',
    description: 'Raggio magnete enorme. I geom volano verso di te.',
    icon: '🧲',
    scoreMultiplier: 0.9,
    isChallenge: false,
  ),
];

/// Trova un modificatore per ID
GameModifier? getModifier(String id) {
  for (final m in allModifiers) {
    if (m.id == id) return m;
  }
  return null;
}

/// Calcola il moltiplicatore punteggio combinato di tutti i modificatori attivi
double combinedScoreMultiplier(List<String> activeModifierIds) {
  double result = 1.0;
  for (final id in activeModifierIds) {
    final mod = getModifier(id);
    if (mod != null) {
      result *= mod.scoreMultiplier;
    }
  }
  return result;
}
