import 'package:flame/components.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_fight/game/systems/score_system.dart';

/// Unit tests for [ScoreSystem] pure, deterministic, side-effect-free logic.
///
/// Covered: multiplier accumulation via addGeoms (incl. the 9999 cap),
/// score accumulation via addKill (base x multiplier x scoreMultiplier x
/// modifierMultiplier, rounded), the various reset semantics, and the
/// extra-life threshold crossing inside update().
///
/// NOT covered (require a running game loop / Flame component lifecycle / Hive):
/// none in this file — ScoreSystem is plain state with no such dependencies.
/// The only Flame touchpoint is the unused Vector2 position param of addKill,
/// which is constructible standalone and does not need a game instance.
void main() {
  const maxMultiplier = 9999.0;

  group('initial state', () {
    test('starts at zero score, zero geoms, 1x multiplier', () {
      // Arrange
      final system = ScoreSystem();

      // Act / Assert
      expect(system.score, 0);
      expect(system.geoms, 0);
      expect(system.multiplier, 1.0);
    });

    test('difficulty and modifier multipliers default to 1.0', () {
      // Arrange
      final system = ScoreSystem();

      // Assert
      expect(system.geomValueMultiplier, 1.0);
      expect(system.scoreMultiplier, 1.0);
      expect(system.modifierMultiplier, 1.0);
    });

    test('reports no extra life earned before any update', () {
      // Arrange
      final system = ScoreSystem();

      // Assert
      expect(system.earnedExtraLife, isFalse);
      expect(system.extraLivesThisFrame, 0);
    });
  });

  group('addGeoms', () {
    test('accumulates geom count by the given amount', () {
      // Arrange
      final system = ScoreSystem();

      // Act
      system.addGeoms(3);
      system.addGeoms(2);

      // Assert
      expect(system.geoms, 5);
    });

    test('raises multiplier by amount * geomValueMultiplier (default 1.0)', () {
      // Arrange
      final system = ScoreSystem();

      // Act
      system.addGeoms(4);

      // Assert
      expect(system.multiplier, 1.0 + 4 * 1.0);
    });

    test('scales multiplier gain by a custom geomValueMultiplier', () {
      // Arrange
      final system = ScoreSystem()..geomValueMultiplier = 1.5;

      // Act
      system.addGeoms(2);

      // Assert: 1.0 base + 2 * 1.5
      expect(system.multiplier, 4.0);
    });

    test('caps multiplier at 9999 even when a huge amount is added', () {
      // Arrange
      final system = ScoreSystem();

      // Act
      system.addGeoms(100000);

      // Assert
      expect(system.multiplier, maxMultiplier);
    });

    test('multiplier never exceeds cap across repeated additions', () {
      // Arrange
      final system = ScoreSystem()..geomValueMultiplier = 2.0;

      // Act
      for (var i = 0; i < 10000; i++) {
        system.addGeoms(5);
      }

      // Assert
      expect(system.multiplier, maxMultiplier);
      expect(system.geoms, 50000);
    });

    test('accumulates geoms even after multiplier is capped', () {
      // Arrange
      final system = ScoreSystem();
      system.addGeoms(100000); // multiplier now capped

      // Act
      system.addGeoms(7);

      // Assert: count keeps growing, multiplier stays at cap
      expect(system.geoms, 100007);
      expect(system.multiplier, maxMultiplier);
    });
  });

  group('addKill', () {
    final anyPosition = Vector2.zero();

    test('adds base points when all multipliers are 1.0', () {
      // Arrange
      final system = ScoreSystem();

      // Act
      system.addKill(100, anyPosition);

      // Assert
      expect(system.score, 100);
    });

    test('scales points by the current geom multiplier', () {
      // Arrange
      final system = ScoreSystem();
      system.addGeoms(4); // multiplier -> 5.0

      // Act
      system.addKill(100, anyPosition);

      // Assert: 100 * 5.0
      expect(system.score, 500);
    });

    test('scales points by scoreMultiplier and modifierMultiplier', () {
      // Arrange
      final system = ScoreSystem()
        ..scoreMultiplier = 2.0
        ..modifierMultiplier = 3.0;

      // Act
      system.addKill(10, anyPosition);

      // Assert: 10 * 1.0 * 2.0 * 3.0
      expect(system.score, 60);
    });

    test('combines geom, score, and modifier multipliers', () {
      // Arrange
      final system = ScoreSystem()
        ..scoreMultiplier = 2.0
        ..modifierMultiplier = 1.5;
      system.addGeoms(2); // multiplier -> 3.0

      // Act
      system.addKill(10, anyPosition);

      // Assert: 10 * 3.0 * 2.0 * 1.5 = 90
      expect(system.score, 90);
    });

    test('rounds fractional earned points to nearest integer', () {
      // Arrange: 10 * 1.0 * 0.55 * 1.0 = 5.5 -> rounds to 6
      final system = ScoreSystem()..scoreMultiplier = 0.55;

      // Act
      system.addKill(10, anyPosition);

      // Assert
      expect(system.score, 6);
    });

    test('accumulates score across multiple kills', () {
      // Arrange
      final system = ScoreSystem();

      // Act
      system.addKill(100, anyPosition);
      system.addKill(250, anyPosition);

      // Assert
      expect(system.score, 350);
    });

    test('ignores the position argument when computing score', () {
      // Arrange
      final systemA = ScoreSystem();
      final systemB = ScoreSystem();

      // Act
      systemA.addKill(100, Vector2.zero());
      systemB.addKill(100, Vector2(999, -999));

      // Assert: position has no effect on score
      expect(systemA.score, systemB.score);
    });
  });

  group('multiplierDisplay', () {
    test('rounds the multiplier to the nearest integer for display', () {
      // Arrange
      final system = ScoreSystem()..geomValueMultiplier = 0.5;

      // Act: 1.0 + 3 * 0.5 = 2.5 -> rounds to 3 (round-half-away-from-zero)
      system.addGeoms(3);

      // Assert
      expect(system.multiplierDisplay, 3);
    });

    test('reports 1 for the fresh 1x multiplier', () {
      // Arrange
      final system = ScoreSystem();

      // Assert
      expect(system.multiplierDisplay, 1);
    });
  });

  group('resetMultiplier', () {
    test('returns multiplier to 1x without touching score or geoms', () {
      // Arrange
      final system = ScoreSystem();
      system.addGeoms(5); // multiplier -> 6.0
      system.addKill(100, Vector2.zero()); // some score

      final scoreBefore = system.score;
      final geomsBefore = system.geoms;

      // Act
      system.resetMultiplier();

      // Assert
      expect(system.multiplier, 1.0);
      expect(system.score, scoreBefore);
      expect(system.geoms, geomsBefore);
    });
  });

  group('reset', () {
    test('clears score, geoms, and multiplier', () {
      // Arrange
      final system = ScoreSystem();
      system.addGeoms(5);
      system.addKill(100, Vector2.zero());

      // Act
      system.reset();

      // Assert
      expect(system.score, 0);
      expect(system.geoms, 0);
      expect(system.multiplier, 1.0);
    });

    test('preserves difficulty and modifier multipliers', () {
      // Arrange
      final system = ScoreSystem()
        ..geomValueMultiplier = 1.25
        ..scoreMultiplier = 4.0
        ..modifierMultiplier = 2.0;

      // Act
      system.reset();

      // Assert: these are owned by difficulty/modifier config, not reset here
      expect(system.geomValueMultiplier, 1.25);
      expect(system.scoreMultiplier, 4.0);
      expect(system.modifierMultiplier, 2.0);
    });

    test('re-arms extra-life thresholds so they fire again after reset', () {
      // Arrange
      final system = ScoreSystem();
      system.score = 10000;
      system.update(0.016); // consumes the 10K threshold
      expect(system.extraLivesThisFrame, 1);

      // Act
      system.reset();
      system.score = 10000;
      system.update(0.016);

      // Assert: threshold index was reset, so 10K grants a life again
      expect(system.extraLivesThisFrame, 1);
    });
  });

  group('resetAll', () {
    test('clears base state and restores all multipliers to 1.0', () {
      // Arrange
      final system = ScoreSystem()
        ..geomValueMultiplier = 1.5
        ..scoreMultiplier = 4.0
        ..modifierMultiplier = 3.0;
      system.addGeoms(5);
      system.addKill(100, Vector2.zero());

      // Act
      system.resetAll();

      // Assert
      expect(system.score, 0);
      expect(system.geoms, 0);
      expect(system.multiplier, 1.0);
      expect(system.geomValueMultiplier, 1.0);
      expect(system.scoreMultiplier, 1.0);
      expect(system.modifierMultiplier, 1.0);
    });
  });

  group('update — extra life thresholds', () {
    test('grants no extra life below the first threshold', () {
      // Arrange
      final system = ScoreSystem();
      system.score = 9999;

      // Act
      system.update(0.016);

      // Assert
      expect(system.earnedExtraLife, isFalse);
      expect(system.extraLivesThisFrame, 0);
    });

    test('grants exactly one extra life when crossing 10K', () {
      // Arrange
      final system = ScoreSystem();
      system.score = 10000;

      // Act
      system.update(0.016);

      // Assert
      expect(system.earnedExtraLife, isTrue);
      expect(system.extraLivesThisFrame, 1);
    });

    test('does not re-grant a threshold already crossed', () {
      // Arrange
      final system = ScoreSystem();
      system.score = 10000;
      system.update(0.016); // crosses 10K

      // Act: same threshold, next frame — score grew but stays under 100K
      system.score = 50000;
      system.update(0.016);

      // Assert: no new life because 100K not yet reached
      expect(system.extraLivesThisFrame, 0);
      expect(system.earnedExtraLife, isFalse);
    });

    test('grants the next life when the second threshold is crossed', () {
      // Arrange
      final system = ScoreSystem();
      system.score = 10000;
      system.update(0.016); // 10K

      // Act
      system.score = 100000;
      system.update(0.016); // 100K

      // Assert
      expect(system.extraLivesThisFrame, 1);
    });

    test(
      'grants multiple lives when several thresholds cross in one frame',
      () {
        // Arrange: a big jump (e.g. boss kill at high multiplier) skips past
        // both 10K and 100K in a single tick.
        final system = ScoreSystem();
        system.score = 200000;

        // Act
        system.update(0.016);

        // Assert
        expect(system.extraLivesThisFrame, 2);
        expect(system.earnedExtraLife, isTrue);
      },
    );

    test('grants all six lives when score leaps past every threshold', () {
      // Arrange: thresholds are 10K,100K,1M,10M,100M,1B (six total).
      final system = ScoreSystem();
      system.score = 2000000000; // 2B, above the 1B top threshold

      // Act
      system.update(0.016);

      // Assert
      expect(system.extraLivesThisFrame, 6);
    });

    test('resets the per-frame life count at the start of each update', () {
      // Arrange
      final system = ScoreSystem();
      system.score = 10000;
      system.update(0.016); // earns 1
      expect(system.extraLivesThisFrame, 1);

      // Act: a later frame with no new threshold crossed
      system.update(0.016);

      // Assert: counter cleared, not sticky from the previous frame
      expect(system.extraLivesThisFrame, 0);
    });

    test(
      'never grants more than six lives even far beyond the top threshold',
      () {
        // Arrange
        final system = ScoreSystem();

        // Act: cross everything, then keep climbing across frames
        system.score = 1000000000; // 1B
        system.update(0.016);
        system.score = 9999999999; // way past
        system.update(0.016);

        // Assert: top threshold already consumed, no further lives
        expect(system.extraLivesThisFrame, 0);
      },
    );
  });
}
