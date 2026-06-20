import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_fight/data/save_data.dart';

/// Unit tests for the PURE logic of [SaveData].
///
/// [SaveData] is a plain Dart object — no Hive box or SharedPreferences are
/// required to exercise its JSON (de)serialization, copyWith defensive copies,
/// upgrade-level clamping, multiplier getters, or daily-reward streak logic.
/// (Hive lives in [SaveManager], which is intentionally NOT tested here.)
///
/// Daily-reward tests stay deterministic by computing dates relative to
/// [DateTime.now()] so they never depend on a hardcoded calendar date.
void main() {
  /// Helper: today's date in the same `YYYY-MM-DD` format SaveData uses
  /// internally (see `SaveData._today`). Computed from DateTime.now() to match
  /// the production helper exactly.
  String dateString(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$dd';
  }

  String todayString() => dateString(DateTime.now());
  String yesterdayString() =>
      dateString(DateTime.now().subtract(const Duration(days: 1)));

  group('toJson <-> fromJson round-trip', () {
    test('preserves all fields including maps, lists, strings and ints', () {
      // Arrange — a fully-populated SaveData with non-default values for
      // every field so a dropped/garbled field would change the result.
      final original = SaveData(
        goldGeoms: 1234,
        upgrades: {'firepower': 5, 'speed': 3, 'dash': 7},
        unlockedSkins: ['classic', 'neon', 'gold'],
        unlockedTrails: ['normal', 'fire'],
        unlockedModes: ['classic', 'tunnel', 'boss'],
        unlockedWeapons: ['basic', 'laser', 'shotgun'],
        highscores: {'classic': 9999, 'tunnel': 4200},
        totalPlaytime: 86400,
        stats: {'kills': 500, 'deaths': 12},
        playedModes: ['classic', 'tunnel'],
        activeModifiers: ['double_damage', 'glass_cannon'],
        activeSkin: 'neon',
        activeTrail: 'fire',
        startingWeapon: 'laser',
        activePet: 'cube',
        unlockedPets: ['none', 'cube', 'orb'],
        lastDailyClaim: '2026-06-17',
        dailyStreak: 9,
        languageCode: 'en',
      );

      // Act — serialize then deserialize.
      final restored = SaveData.fromJson(original.toJson());

      // Assert — every field survives the round-trip intact.
      expect(restored.goldGeoms, original.goldGeoms);
      expect(restored.upgrades, original.upgrades);
      expect(restored.unlockedSkins, original.unlockedSkins);
      expect(restored.unlockedTrails, original.unlockedTrails);
      expect(restored.unlockedModes, original.unlockedModes);
      expect(restored.unlockedWeapons, original.unlockedWeapons);
      expect(restored.highscores, original.highscores);
      expect(restored.totalPlaytime, original.totalPlaytime);
      expect(restored.stats, original.stats);
      expect(restored.playedModes, original.playedModes);
      expect(restored.activeModifiers, original.activeModifiers);
      expect(restored.activeSkin, original.activeSkin);
      expect(restored.activeTrail, original.activeTrail);
      expect(restored.startingWeapon, original.startingWeapon);
      expect(restored.activePet, original.activePet);
      expect(restored.unlockedPets, original.unlockedPets);
      expect(restored.lastDailyClaim, original.lastDailyClaim);
      expect(restored.dailyStreak, original.dailyStreak);
      expect(restored.languageCode, original.languageCode);
    });

    test('default-constructed SaveData round-trips to equal defaults', () {
      // Arrange
      final original = SaveData();

      // Act
      final restored = SaveData.fromJson(original.toJson());

      // Assert — constructor defaults survive serialization.
      expect(restored.goldGeoms, 0);
      expect(restored.upgrades, <String, int>{});
      expect(restored.unlockedSkins, ['classic']);
      expect(restored.unlockedTrails, ['normal']);
      expect(restored.unlockedModes, ['classic']);
      expect(restored.unlockedWeapons, ['basic']);
      expect(restored.highscores, <String, int>{});
      expect(restored.totalPlaytime, 0);
      expect(restored.stats, <String, int>{});
      expect(restored.playedModes, <String>[]);
      expect(restored.activeModifiers, <String>[]);
      expect(restored.activeSkin, 'classic');
      expect(restored.activeTrail, 'normal');
      expect(restored.startingWeapon, 'basic');
      expect(restored.activePet, 'none');
      expect(restored.unlockedPets, ['none']);
      expect(restored.lastDailyClaim, '');
      expect(restored.dailyStreak, 0);
      expect(restored.languageCode, 'it');
    });
  });

  group('fromJson defaults and robustness', () {
    test('empty json falls back to all constructor defaults', () {
      // Arrange / Act
      final data = SaveData.fromJson(<String, dynamic>{});

      // Assert — every field gets its documented default.
      expect(data.goldGeoms, 0);
      expect(data.upgrades, <String, int>{});
      expect(data.unlockedSkins, ['classic']);
      expect(data.unlockedTrails, ['normal']);
      expect(data.unlockedModes, ['classic']);
      expect(data.unlockedWeapons, ['basic']);
      expect(data.highscores, <String, int>{});
      expect(data.totalPlaytime, 0);
      expect(data.stats, <String, int>{});
      expect(data.playedModes, <String>[]);
      expect(data.activeModifiers, <String>[]);
      expect(data.activeSkin, 'classic');
      expect(data.activeTrail, 'normal');
      expect(data.startingWeapon, 'basic');
      expect(data.activePet, 'none');
      expect(data.unlockedPets, ['none']);
      expect(data.lastDailyClaim, '');
      expect(data.dailyStreak, 0);
      expect(data.languageCode, 'it');
    });

    test(
      'missing individual keys use their defaults while present keys win',
      () {
        // Arrange — only a subset of keys present.
        final json = <String, dynamic>{'goldGeoms': 50, 'activeSkin': 'neon'};

        // Act
        final data = SaveData.fromJson(json);

        // Assert — present keys honored, missing keys defaulted.
        expect(data.goldGeoms, 50);
        expect(data.activeSkin, 'neon');
        expect(data.activeTrail, 'normal'); // missing -> default
        expect(data.upgrades, <String, int>{}); // missing -> default
        expect(data.unlockedSkins, ['classic']); // missing -> default
      },
    );

    test('coerces num (double) values to int for scalar int fields', () {
      // Arrange — Hive can hand back doubles where ints are expected.
      final json = <String, dynamic>{
        'goldGeoms': 100.0,
        'totalPlaytime': 250.0,
        'dailyStreak': 4.0,
      };

      // Act
      final data = SaveData.fromJson(json);

      // Assert — coerced to int, and they are genuinely ints.
      expect(data.goldGeoms, 100);
      expect(data.goldGeoms, isA<int>());
      expect(data.totalPlaytime, 250);
      expect(data.totalPlaytime, isA<int>());
      expect(data.dailyStreak, 4);
      expect(data.dailyStreak, isA<int>());
    });

    test('coerces num (double) values to int inside map fields', () {
      // Arrange — upgrades/highscores/stats values arriving as doubles.
      final json = <String, dynamic>{
        'upgrades': {'firepower': 3.0, 'speed': 2.0},
        'highscores': {'classic': 1234.0},
        'stats': {'kills': 99.0},
      };

      // Act
      final data = SaveData.fromJson(json);

      // Assert — map values coerced to int.
      expect(data.upgrades, {'firepower': 3, 'speed': 2});
      expect(data.upgrades['firepower'], isA<int>());
      expect(data.highscores, {'classic': 1234});
      expect(data.highscores['classic'], isA<int>());
      expect(data.stats, {'kills': 99});
      expect(data.stats['kills'], isA<int>());
    });

    test('back-compat: missing activePet defaults to "none"', () {
      // Arrange — an old save predating the pet feature.
      final json = <String, dynamic>{'goldGeoms': 10};

      // Act
      final data = SaveData.fromJson(json);

      // Assert
      expect(data.activePet, 'none');
      expect(data.unlockedPets, ['none']);
    });

    test('back-compat: missing languageCode defaults to "it"', () {
      // Arrange — an old save predating the language feature.
      final json = <String, dynamic>{'goldGeoms': 10};

      // Act
      final data = SaveData.fromJson(json);

      // Assert — original development language.
      expect(data.languageCode, 'it');
    });

    test('coerces null numeric map values to 0', () {
      // Arrange — a corrupted/partial map entry with a null value.
      final json = <String, dynamic>{
        'upgrades': {'firepower': null},
      };

      // Act
      final data = SaveData.fromJson(json);

      // Assert — null -> 0 per the `(v as num?)?.toInt() ?? 0` coercion.
      expect(data.upgrades, {'firepower': 0});
    });
  });

  group('copyWith', () {
    test('overriding each field individually replaces only that field', () {
      // Arrange
      final base = SaveData();

      // Act + Assert — one field at a time.
      expect(base.copyWith(goldGeoms: 777).goldGeoms, 777);
      expect(base.copyWith(totalPlaytime: 42).totalPlaytime, 42);
      expect(base.copyWith(dailyStreak: 5).dailyStreak, 5);
      expect(base.copyWith(activeSkin: 'neon').activeSkin, 'neon');
      expect(base.copyWith(activeTrail: 'fire').activeTrail, 'fire');
      expect(base.copyWith(startingWeapon: 'laser').startingWeapon, 'laser');
      expect(base.copyWith(activePet: 'cube').activePet, 'cube');
      expect(
        base.copyWith(lastDailyClaim: '2026-01-01').lastDailyClaim,
        '2026-01-01',
      );
      expect(base.copyWith(languageCode: 'en').languageCode, 'en');
      expect(base.copyWith(upgrades: {'speed': 1}).upgrades, {'speed': 1});
      expect(base.copyWith(unlockedSkins: ['classic', 'neon']).unlockedSkins, [
        'classic',
        'neon',
      ]);
      expect(base.copyWith(unlockedTrails: ['normal', 'fire']).unlockedTrails, [
        'normal',
        'fire',
      ]);
      expect(base.copyWith(unlockedModes: ['classic', 'boss']).unlockedModes, [
        'classic',
        'boss',
      ]);
      expect(
        base.copyWith(unlockedWeapons: ['basic', 'laser']).unlockedWeapons,
        ['basic', 'laser'],
      );
      expect(base.copyWith(highscores: {'classic': 5}).highscores, {
        'classic': 5,
      });
      expect(base.copyWith(stats: {'kills': 3}).stats, {'kills': 3});
      expect(base.copyWith(playedModes: ['tunnel']).playedModes, ['tunnel']);
      expect(base.copyWith(activeModifiers: ['glass_cannon']).activeModifiers, [
        'glass_cannon',
      ]);
    });

    test('fields not passed are carried over from the original', () {
      // Arrange — a fully customized instance.
      final original = SaveData(
        goldGeoms: 500,
        upgrades: {'firepower': 4},
        unlockedSkins: ['classic', 'neon'],
        activeSkin: 'neon',
        activePet: 'cube',
        dailyStreak: 6,
        languageCode: 'fr',
      );

      // Act — change only one field.
      final copy = original.copyWith(goldGeoms: 999);

      // Assert — changed field updated, everything else preserved.
      expect(copy.goldGeoms, 999);
      expect(copy.upgrades, {'firepower': 4});
      expect(copy.unlockedSkins, ['classic', 'neon']);
      expect(copy.activeSkin, 'neon');
      expect(copy.activePet, 'cube');
      expect(copy.dailyStreak, 6);
      expect(copy.languageCode, 'fr');
    });

    test(
      'returned collections are defensive copies, not shared references',
      () {
        // Arrange
        final original = SaveData(
          upgrades: {'firepower': 1},
          unlockedSkins: ['classic'],
          unlockedTrails: ['normal'],
          unlockedModes: ['classic'],
          unlockedWeapons: ['basic'],
          highscores: {'classic': 10},
          stats: {'kills': 1},
          playedModes: ['classic'],
          activeModifiers: ['x'],
          unlockedPets: ['none'],
        );

        // Act — copyWith without passing any collection.
        final copy = original.copyWith();

        // Assert — equal in value but NOT identical (no shared mutable refs).
        expect(copy.upgrades, original.upgrades);
        expect(identical(copy.upgrades, original.upgrades), isFalse);
        expect(identical(copy.unlockedSkins, original.unlockedSkins), isFalse);
        expect(
          identical(copy.unlockedTrails, original.unlockedTrails),
          isFalse,
        );
        expect(identical(copy.unlockedModes, original.unlockedModes), isFalse);
        expect(
          identical(copy.unlockedWeapons, original.unlockedWeapons),
          isFalse,
        );
        expect(identical(copy.highscores, original.highscores), isFalse);
        expect(identical(copy.stats, original.stats), isFalse);
        expect(identical(copy.playedModes, original.playedModes), isFalse);
        expect(
          identical(copy.activeModifiers, original.activeModifiers),
          isFalse,
        );
        expect(identical(copy.unlockedPets, original.unlockedPets), isFalse);
      },
    );

    test(
      'mutating original collection after copyWith does not affect copy',
      () {
        // Arrange
        final original = SaveData(upgrades: {'firepower': 1});
        final copy = original.copyWith();

        // Act — mutate the source map in place.
        original.upgrades['speed'] = 9;

        // Assert — the defensive copy is untouched.
        expect(copy.upgrades, {'firepower': 1});
        expect(copy.upgrades.containsKey('speed'), isFalse);
      },
    );
  });

  group('getUpgradeLevel clamping', () {
    test('returns 0 for an unknown upgrade id', () {
      // Arrange
      final data = SaveData();

      // Act / Assert
      expect(data.getUpgradeLevel('does_not_exist'), 0);
    });

    test('returns the stored level when within range', () {
      // Arrange
      final data = SaveData(upgrades: {'firepower': 5});

      // Act / Assert
      expect(data.getUpgradeLevel('firepower'), 5);
    });

    test('clamps a negative stored level up to 0', () {
      // Arrange — a tampered save with a negative level.
      final data = SaveData(upgrades: {'firepower': -7});

      // Act / Assert
      expect(data.getUpgradeLevel('firepower'), 0);
    });

    test('clamps an over-max stored level down to kMaxUpgradeLevel', () {
      // Arrange — a tampered save above the cap.
      final data = SaveData(upgrades: {'firepower': 9999});

      // Act / Assert
      expect(data.getUpgradeLevel('firepower'), kMaxUpgradeLevel);
    });

    test('exact kMaxUpgradeLevel is returned unchanged', () {
      // Arrange
      final data = SaveData(upgrades: {'firepower': kMaxUpgradeLevel});

      // Act / Assert
      expect(data.getUpgradeLevel('firepower'), kMaxUpgradeLevel);
    });
  });

  // Stat getters are now folded from owned TALENTS (the shop upgrade stat tab
  // was replaced by the talent web). Old `upgrades`-map levels no longer affect
  // these. One-shot design → no HP/lives/shield talents.
  group('talent-driven stat getters', () {
    test('all multipliers are baseline 1.0 with no talents', () {
      final s = SaveData();
      expect(s.damageMultiplier, 1.0);
      expect(s.speedMultiplier, 1.0);
      expect(s.fireRateMultiplier, 1.0);
    });

    test('legacy upgrades map no longer affects stat getters', () {
      // A maxed old save grants nothing now — talents are the only source.
      final legacy = SaveData(
        upgrades: {
          'firepower': kMaxUpgradeLevel,
          'speed': kMaxUpgradeLevel,
          'fire_rate': kMaxUpgradeLevel,
        },
      );
      expect(legacy.damageMultiplier, 1.0);
      expect(legacy.speedMultiplier, 1.0);
      expect(legacy.fireRateMultiplier, 1.0);
    });

    test('owning stat talents raises the matching multiplier', () {
      // root2 = Massacre root (+Attack), root5 = Ascendant root (+Move Speed).
      expect(
        SaveData(ownedTalents: ['root2']).damageMultiplier,
        greaterThan(1.0),
      );
      expect(
        SaveData(ownedTalents: ['root5']).speedMultiplier,
        greaterThan(1.0),
      );
    });

    test('bombRadius base is 375 (scaled only by talents)', () {
      expect(SaveData().bombRadius, closeTo(375.0, 1e-9));
    });

    test('startingLives is fixed at 3 — no HP/lives talents (one-shot)', () {
      expect(SaveData().startingLives, 3);
      expect(
        SaveData(upgrades: {'starting_lives': kMaxUpgradeLevel}).startingLives,
        3,
      );
    });

    test('postDeathShieldDuration is 0 — no shield talents', () {
      expect(SaveData().postDeathShieldDuration, 0);
    });

    test('dash is always unlocked; base cooldown 2.0s', () {
      final s = SaveData();
      expect(s.dashUnlocked, isTrue);
      expect(s.dashCooldown, closeTo(2.0, 1e-9));
    });
  });

  group('claimDailyReward and canClaimDailyReward', () {
    test('first claim sets streak to 1 and grants kDailyRewardAmount', () {
      // Arrange — a brand new save, never claimed.
      final data = SaveData(goldGeoms: 0);
      expect(data.lastDailyClaim, '');

      // Act
      final reward = data.claimDailyReward();

      // Assert
      expect(reward, kDailyRewardAmount);
      expect(data.goldGeoms, kDailyRewardAmount);
      expect(data.dailyStreak, 1);
      expect(data.lastDailyClaim, todayString());
    });

    test('claiming when last claim was yesterday increments the streak', () {
      // Arrange — claimed exactly one day ago, with an existing streak.
      final data = SaveData(
        goldGeoms: 1000,
        lastDailyClaim: yesterdayString(),
        dailyStreak: 3,
      );

      // Act
      final reward = data.claimDailyReward();

      // Assert — streak += 1, gold += reward, date updated to today.
      expect(reward, kDailyRewardAmount);
      expect(data.dailyStreak, 4);
      expect(data.goldGeoms, 1000 + kDailyRewardAmount);
      expect(data.lastDailyClaim, todayString());
    });

    test('claiming after a gap of more than one day resets streak to 1', () {
      // Arrange — last claim was 5 days ago (gap > 1).
      final fiveDaysAgo = dateString(
        DateTime.now().subtract(const Duration(days: 5)),
      );
      final data = SaveData(
        goldGeoms: 200,
        lastDailyClaim: fiveDaysAgo,
        dailyStreak: 10,
      );

      // Act
      final reward = data.claimDailyReward();

      // Assert — streak reset to 1, reward still granted.
      expect(reward, kDailyRewardAmount);
      expect(data.dailyStreak, 1);
      expect(data.goldGeoms, 200 + kDailyRewardAmount);
      expect(data.lastDailyClaim, todayString());
    });

    test('second claim on the same day is a no-op returning 0', () {
      // Arrange — already claimed today.
      final data = SaveData(
        goldGeoms: 500,
        lastDailyClaim: todayString(),
        dailyStreak: 2,
      );

      // Act
      final reward = data.claimDailyReward();

      // Assert — nothing changes; returns 0.
      expect(reward, 0);
      expect(data.goldGeoms, 500);
      expect(data.dailyStreak, 2);
      expect(data.lastDailyClaim, todayString());
    });

    test('canClaimDailyReward is false when already claimed today', () {
      // Arrange
      final data = SaveData(lastDailyClaim: todayString());

      // Act / Assert
      expect(data.canClaimDailyReward(), isFalse);
    });

    test('canClaimDailyReward is true when never claimed', () {
      // Arrange — default empty lastDailyClaim.
      final data = SaveData();

      // Act / Assert
      expect(data.canClaimDailyReward(), isTrue);
    });

    test('canClaimDailyReward is true when last claim was yesterday', () {
      // Arrange
      final data = SaveData(lastDailyClaim: yesterdayString());

      // Act / Assert
      expect(data.canClaimDailyReward(), isTrue);
    });

    test('canClaimDailyReward becomes false immediately after a claim', () {
      // Arrange
      final data = SaveData();
      expect(data.canClaimDailyReward(), isTrue);

      // Act
      data.claimDailyReward();

      // Assert — same-day re-claim is blocked.
      expect(data.canClaimDailyReward(), isFalse);
    });

    test(
      'malformed lastDailyClaim is handled gracefully (streak resets to 1)',
      () {
        // Arrange — a corrupted date string that DateTime.parse cannot read.
        final data = SaveData(
          goldGeoms: 0,
          lastDailyClaim: 'not-a-date',
          dailyStreak: 7,
        );

        // Act — claimDailyReward catches the parse error and resets the streak.
        final reward = data.claimDailyReward();

        // Assert
        expect(reward, kDailyRewardAmount);
        expect(data.dailyStreak, 1);
        expect(data.lastDailyClaim, todayString());
      },
    );
  });
}
