import '../save_data.dart';
import 'talent_def.dart';
import 'talent_generator.dart';

/// Allocation/ownership logic over a [SaveData]'s owned talents. Stateless aside
/// from the [save] it edits; the caller persists via `SaveManager.save`.
///
/// SLOT-AWARE ownership is the crux of the fork system: a prereq pointing at a
/// fork's slot id must be satisfied if EITHER option is owned (both occupy the
/// same slot). [ownsSlot] is used everywhere connectivity is checked.
class TalentAllocator {
  TalentAllocator(this.save) : tree = buildTalentTree();

  final SaveData save;
  final TalentTree tree;

  /// True if this exact node id is owned.
  bool owns(String id) => save.ownedTalents.contains(id);

  /// True if the SLOT [id] occupies is filled — by [id] itself or by any of its
  /// mutually-exclusive fork twins (which share the slot/position).
  bool ownsSlot(String id) {
    if (owns(id)) return true;
    final node = tree.byId[id];
    if (node == null) return false;
    for (final x in node.excludes) {
      if (owns(x)) return true;
    }
    return false;
  }

  /// A node is unlockable once it is a root OR any CONNECTED neighbour (in
  /// either direction along an edge) has its slot owned. Connectivity is
  /// undirected so owning a node opens every node it links to — not only the
  /// ones further out from the hub.
  bool isUnlocked(TalentDef node) {
    if (node.isRoot) return true;
    final adj = tree.neighbors[node.id];
    if (adj == null) return false;
    for (final m in adj) {
      if (ownsSlot(m)) return true;
    }
    return false;
  }

  /// The chosen fork sibling that permanently blocks [node], if any.
  TalentDef? excludedSibling(TalentDef node) {
    for (final x in node.excludes) {
      if (owns(x)) return tree.byId[x];
    }
    return null;
  }

  /// Whether [node] can be allocated right now.
  bool canAllocate(TalentDef node) =>
      save.talentPoints > 0 &&
      !owns(node.id) &&
      isUnlocked(node) &&
      excludedSibling(node) == null;

  /// Allocate [node]. Returns true on success. Spends one point implicitly
  /// (points = level − owned.length) and grows [SaveData.ownedTalents], which
  /// invalidates the folded-stats cache.
  bool allocate(TalentDef node) {
    if (!canAllocate(node)) return false;
    save.allocateTalent(node.id);
    return true;
  }

  /// Refund every allocated point (clear owned). Returns the count refunded.
  /// Currency cost (if any) is applied by the caller before invoking this.
  int respec() {
    final n = save.ownedTalents.length;
    save.respecTalents();
    return n;
  }
}
