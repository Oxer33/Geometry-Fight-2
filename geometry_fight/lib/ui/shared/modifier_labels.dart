import '../../data/wave_configs.dart';
import '../../l10n/generated/app_localizations.dart';

/// Localized HUD banner name for a wave modifier (keyed on [WaveModifier.name]).
/// Falls back to the enum's built-in [WaveModifierUi.displayName] for unknown
/// ids (defensive — keeps the HUD render path safe if a modifier is added).
String waveModifierName(AppLocalizations l10n, WaveModifier modifier) {
  switch (modifier) {
    case WaveModifier.none:
      return '';
    case WaveModifier.frenzy:
      return l10n.waveModNameFrenzy;
    case WaveModifier.tank:
      return l10n.waveModNameTank;
    case WaveModifier.glass:
      return l10n.waveModNameGlass;
    case WaveModifier.loot:
      return l10n.waveModNameLoot;
    case WaveModifier.blitz:
      return l10n.waveModNameBlitz;
    case WaveModifier.haste:
      return l10n.waveModNameHaste;
    case WaveModifier.magnetic:
      return l10n.waveModNameMagnetic;
    case WaveModifier.iron:
      return l10n.waveModNameIron;
  }
}

/// Localized HUD banner tagline for a wave modifier. Falls back to the enum's
/// built-in [WaveModifierUi.tagline].
String waveModifierTagline(AppLocalizations l10n, WaveModifier modifier) {
  switch (modifier) {
    case WaveModifier.none:
      return '';
    case WaveModifier.frenzy:
      return l10n.waveModTaglineFrenzy;
    case WaveModifier.tank:
      return l10n.waveModTaglineTank;
    case WaveModifier.glass:
      return l10n.waveModTaglineGlass;
    case WaveModifier.loot:
      return l10n.waveModTaglineLoot;
    case WaveModifier.blitz:
      return l10n.waveModTaglineBlitz;
    case WaveModifier.haste:
      return l10n.waveModTaglineHaste;
    case WaveModifier.magnetic:
      return l10n.waveModTaglineMagnetic;
    case WaveModifier.iron:
      return l10n.waveModTaglineIron;
  }
}

/// Localized name for a modifier id. Falls back to [fallback] if id is
/// unknown (defensive — keeps render path safe when new mods are added).
String modifierName(AppLocalizations l10n, String id, String fallback) {
  switch (id) {
    case 'glass_cannon':
      return l10n.modNameGlassCannon;
    case 'bullet_hell':
      return l10n.modNameBulletHell;
    case 'speed_demon':
      return l10n.modNameSpeedDemon;
    case 'no_powerups':
      return l10n.modNameNoPowerups;
    case 'fog_of_war':
      return l10n.modNameFogOfWar;
    case 'tiny_arena':
      return l10n.modNameTinyArena;
    case 'one_shot':
      return l10n.modNameOneShot;
    case 'chaos':
      return l10n.modNameChaos;
    case 'giant_mode':
      return l10n.modNameGiantMode;
    case 'ricochet_world':
      return l10n.modNameRicochetWorld;
    case 'infinite_bombs':
      return l10n.modNameInfiniteBombs;
    case 'magnet_king':
      return l10n.modNameMagnetKing;
    default:
      return fallback;
  }
}

/// Localized description for a modifier id. Falls back to [fallback].
String modifierDesc(AppLocalizations l10n, String id, String fallback) {
  switch (id) {
    case 'glass_cannon':
      return l10n.modDescGlassCannon;
    case 'bullet_hell':
      return l10n.modDescBulletHell;
    case 'speed_demon':
      return l10n.modDescSpeedDemon;
    case 'no_powerups':
      return l10n.modDescNoPowerups;
    case 'fog_of_war':
      return l10n.modDescFogOfWar;
    case 'tiny_arena':
      return l10n.modDescTinyArena;
    case 'one_shot':
      return l10n.modDescOneShot;
    case 'chaos':
      return l10n.modDescChaos;
    case 'giant_mode':
      return l10n.modDescGiantMode;
    case 'ricochet_world':
      return l10n.modDescRicochetWorld;
    case 'infinite_bombs':
      return l10n.modDescInfiniteBombs;
    case 'magnet_king':
      return l10n.modDescMagnetKing;
    default:
      return fallback;
  }
}
