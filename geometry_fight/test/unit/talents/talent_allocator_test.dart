import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_fight/data/save_data.dart';
import 'package:geometry_fight/data/talents/talent_allocator.dart';
import 'package:geometry_fight/data/talents/talent_service.dart';
import 'package:geometry_fight/data/talents/talent_generator.dart';

void main() {
  final tree = buildTalentTree();

  test('XP curve: level 1 at 0 xp, monotonic, invertible', () {
    expect(levelForXp(0), 1);
    expect(levelForXp(xpForLevel(2)), 2);
    expect(levelForXp(xpForLevel(50)), 50);
    expect(levelForXp(xpForLevel(50) - 1), 49);
  });

  test('grantTestLevels(1000) yields ~1000 talent points', () {
    final save = SaveData();
    save.grantTestLevels(1000);
    expect(save.playerLevel, greaterThanOrEqualTo(1000));
    expect(save.talentPoints, greaterThanOrEqualTo(1000));
  });

  test('allocating an +atk node raises the damage multiplier', () {
    final save = SaveData(playerXp: xpForLevel(10));
    expect(save.damageMultiplier, 1.0);
    final alloc = TalentAllocator(save);
    final root = tree.byId['root2']!; // Massacre root → atkPct
    expect(alloc.allocate(root), isTrue);
    expect(save.damageMultiplier, greaterThan(1.0));
  });

  test('spend guards against overspend', () {
    final save = SaveData(); // level 1 → exactly 1 point
    final alloc = TalentAllocator(save);
    expect(alloc.allocate(tree.byId['root0']!), isTrue);
    // Out of points now: any further allocation must fail.
    expect(save.talentPoints, 0);
    expect(alloc.allocate(tree.byId['root1']!), isFalse);
    expect(save.ownedTalents.length, 1);
  });

  test('respec refunds every point', () {
    final save = SaveData(playerXp: xpForLevel(10));
    final alloc = TalentAllocator(save);
    alloc.allocate(tree.byId['root0']!);
    alloc.allocate(tree.byId['root1']!);
    expect(save.ownedTalents.length, 2);
    final refunded = alloc.respec();
    expect(refunded, 2);
    expect(save.ownedTalents, isEmpty);
    expect(save.talentPoints, save.playerLevel);
  });

  test('taking a fork permanently blocks its twin', () {
    final save = SaveData(playerXp: xpForLevel(5000));
    final alloc = TalentAllocator(save);
    final forkA = tree.forks.firstWhere((f) => !isForkTwinId(f.id));
    final forkB = tree.byId[forkA.excludes.first]!;
    // Unlock the slot by owning one of its prereqs directly.
    save.ownedTalents.add(forkA.prereq.first);
    expect(alloc.isUnlocked(forkB), isTrue);
    expect(alloc.allocate(forkB), isTrue);
    expect(alloc.allocate(forkA), isFalse, reason: 'A blocked by chosen B');
    expect(alloc.excludedSibling(forkA)?.id, forkB.id);
  });

  test('slot-aware: taking EITHER fork option unlocks the slot children', () {
    final save = SaveData(playerXp: xpForLevel(5000));
    final alloc = TalentAllocator(save);
    final forkA = tree.forks.firstWhere((f) => !isForkTwinId(f.id));
    final forkB = tree.byId[forkA.excludes.first]!;
    // A child whose prereq points at the fork's slot id (== option A id).
    final child = tree.nodes.firstWhere(
      (n) =>
          n.prereq.contains(forkA.id) && n.id != forkA.id && n.id != forkB.id,
    );
    // Take option B (NOT A). The slot is still "owned" for connectivity.
    save.ownedTalents.add(forkA.prereq.first);
    expect(alloc.allocate(forkB), isTrue);
    expect(
      alloc.ownsSlot(forkA.id),
      isTrue,
      reason: 'either option fills slot',
    );
    expect(alloc.isUnlocked(child), isTrue);
  });

  test('skill empower forks fold into per-ability power/cdr maps', () {
    final save = SaveData(playerXp: xpForLevel(5000));
    final alloc = TalentAllocator(save);
    final forkA = tree.forks.firstWhere((f) => !isForkTwinId(f.id));
    save.ownedTalents.add(forkA.prereq.first);
    expect(alloc.allocate(forkA), isTrue);
    final fx = forkA.empowers!;
    expect(save.talentStats.skillPower(fx), greaterThan(0));
    expect(save.talentStats.skillCdr(fx), greaterThan(0));
  });

  test(
    'unlock is bidirectional: owning a node opens neighbours both sides',
    () {
      final save = SaveData(playerXp: xpForLevel(5000));
      final alloc = TalentAllocator(save);
      final mid = tree.byId['n4_4']!; // notable mid node, not a fork slot
      save.ownedTalents.add(mid.id);
      final adj = tree.neighbors[mid.id]!;
      for (final id in adj) {
        final n = tree.byId[id]!;
        if (n.isRoot) continue;
        expect(
          alloc.isUnlocked(n),
          isTrue,
          reason: 'neighbour $id not unlocked',
        );
      }
      final hasInner = adj.any((id) => tree.byId[id]!.dist < mid.dist);
      final hasOuter = adj.any((id) => tree.byId[id]!.dist > mid.dist);
      expect(hasInner && hasOuter, isTrue, reason: 'neighbours on both sides');
    },
  );

  test('connectivity: greedily taking connected nodes reaches every slot', () {
    // Start with only the 6 roots valid; repeatedly allocate ANY takeable node.
    // If the web is fully connected, this must reach every non-fork slot and
    // exactly one option of every fork slot — i.e. "taking a talent really does
    // grant access to the ones it connects to", all the way out to keystones.
    final save = SaveData(playerXp: xpForLevel(20000)); // points to spare
    final alloc = TalentAllocator(save);
    var progress = true;
    while (progress) {
      progress = false;
      for (final n in tree.nodes) {
        if (alloc.canAllocate(n)) {
          alloc.allocate(n);
          progress = true;
        }
      }
    }
    final owned = save.ownedTalents.toSet();

    // Every non-fork node (root/minor/notable/keystone) must be reachable.
    for (final n in tree.nodes) {
      if (n.isFork) continue;
      expect(owned.contains(n.id), isTrue, reason: 'unreachable node: ${n.id}');
    }

    // Every fork slot: exactly ONE of the twin pair owned (the other blocked).
    final slots = <String>{
      for (final f in tree.forks)
        isForkTwinId(f.id) ? f.id.substring(0, f.id.length - 2) : f.id,
    };
    for (final slot in slots) {
      final a = owned.contains(slot);
      final b = owned.contains('${slot}_x');
      expect(a ^ b, isTrue, reason: 'fork slot $slot: need exactly one owned');
    }
  });
}
