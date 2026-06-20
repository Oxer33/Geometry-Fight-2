import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_fight/data/talents/talent_effect.dart';
import 'package:geometry_fight/data/talents/talent_generator.dart';

void main() {
  final tree = buildTalentTree();

  test('web has ~600 nodes with unique ids', () {
    expect(tree.nodes.length, greaterThanOrEqualTo(550));
    expect(tree.nodes.length, lessThanOrEqualTo(720));
    final ids = tree.nodes.map((n) => n.id).toSet();
    expect(ids.length, tree.nodes.length, reason: 'ids must be unique');
  });

  test('6 roots have no prereq and jut inward', () {
    final roots = tree.roots.toList();
    expect(roots.length, 6);
    for (final r in roots) {
      expect(r.prereq, isEmpty);
      expect(r.dist, lessThan(kInnerRadius), reason: 'roots jut inward');
    }
  });

  test('every prereq id resolves (slot-aware base ids exist)', () {
    for (final n in tree.nodes) {
      for (final p in n.prereq) {
        expect(
          tree.byId.containsKey(p),
          isTrue,
          reason: '$p missing for ${n.id}',
        );
      }
    }
  });

  test('keystones bundle >= 3 stats', () {
    final keys = tree.nodes.where((n) => n.isKeystone).toList();
    expect(keys.length, 6);
    for (final k in keys) {
      expect(k.stats.length, greaterThanOrEqualTo(3));
    }
  });

  test('it is cross-linked (more edges than a pure tree)', () {
    // Undirected edge set from prereq links.
    final edges = <String>{};
    for (final n in tree.nodes) {
      for (final p in n.prereq) {
        final a = n.id.compareTo(p) < 0 ? '${n.id}|$p' : '$p|${n.id}';
        edges.add(a);
      }
    }
    // A pure tree on N nodes has N-1 edges; a web has many more.
    expect(edges.length, greaterThan(tree.nodes.length));
  });

  test('every ability fx gets >= 2 empower forks', () {
    final counts = <AbilityFx, int>{};
    for (final f in tree.forks) {
      counts[f.empowers!] = (counts[f.empowers!] ?? 0) + 1;
    }
    for (final fx in AbilityFx.values) {
      expect(counts[fx] ?? 0, greaterThanOrEqualTo(2), reason: 'fx $fx');
    }
  });

  test('forks come in mutually-exclusive twins at the same position', () {
    final forks = tree.forks.toList();
    expect(forks.length, kForkTiers.length * 6 * 2); // A + B per slot
    for (final f in forks) {
      expect(f.excludes.length, 1);
      final twin = tree.byId[f.excludes.first]!;
      expect(twin.excludes, contains(f.id), reason: 'exclusion symmetric');
      expect(twin.x, f.x);
      expect(twin.y, f.y);
    }
  });
}
