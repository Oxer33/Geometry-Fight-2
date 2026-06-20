import 'package:flutter/material.dart';

import '../../../data/save_data.dart';
import '../../../data/talents/talent_allocator.dart';
import '../../../data/talents/talent_arm.dart';
import '../../../data/talents/talent_def.dart';
import '../../../data/talents/talent_effect.dart';
import '../../../data/talents/talent_generator.dart';
import 'talent_fx_painter.dart';
import 'talent_web_painter.dart';

/// Path-of-Exile-style talent web screen. Pan+zoom over a cached static layer
/// with an animated overlay; tap a node to inspect/allocate. Animations pause
/// during interaction so zooming just transforms the cached raster.
class TalentTreeScreen extends StatefulWidget {
  const TalentTreeScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TalentTreeScreen> createState() => _TalentTreeScreenState();
}

class _TalentTreeScreenState extends State<TalentTreeScreen>
    with TickerProviderStateMixin {
  late SaveData _save;
  late final TalentTree _tree;
  late final TalentAllocator _alloc;
  late final TransformationController _tc;
  late final AnimationController _pulse;
  late final AnimationController _spin;
  late final AnimationController _wave;

  int _revision = 0;
  bool _viewInitialized = false;
  Set<String> _owned = {};
  late TalentFxData _fxData;

  static const Color _bg = Color(0xFF05050C);

  @override
  void initState() {
    super.initState();
    _save = SaveManager.load();
    _tree = buildTalentTree();
    _alloc = TalentAllocator(_save);
    _tc = TransformationController();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _refresh();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _spin.dispose();
    _wave.dispose();
    _tc.dispose();
    super.dispose();
  }

  void _refresh() {
    _owned = _save.ownedTalents.toSet();
    // Rebuild owned-derived FX geometry ONCE per allocation (not per frame).
    _fxData = TalentFxData(_tree, _owned);
  }

  void _centerView(Size size) {
    const s = 0.42;
    final hub = _tree.hubCenter;
    final tx = size.width / 2 - hub * s;
    final ty = size.height / 2 - hub * s;
    // Column-major scale+translate (avoids deprecated Matrix4.translate/scale).
    _tc.value = Matrix4(
      s,
      0,
      0,
      0, //
      0,
      s,
      0,
      0, //
      0,
      0,
      1,
      0, //
      tx,
      ty,
      0,
      1,
    );
  }

  // ── Tap hit-test ───────────────────────────────────────────────────────────
  void _onTapUp(TapUpDetails d) {
    final hub = _tree.hubCenter;
    final p = d.localPosition;
    TalentDef? hit;
    double best = double.infinity;
    for (final n in _tree.nodes) {
      final dx = (hub + n.x) - p.dx;
      final dy = (hub + n.y) - p.dy;
      final dist2 = dx * dx + dy * dy;
      final hr = talentHitRadius(n.tier);
      if (dist2 <= hr * hr && dist2 < best) {
        best = dist2;
        hit = n;
      }
    }
    if (hit != null) _openNode(hit);
  }

  Future<void> _openNode(TalentDef node) async {
    // Forks always open the choose-one popup (PREVIEW) as long as neither twin
    // is taken — so you can compare the two alternatives BEFORE you can reach
    // them. Allocation inside the popup stays gated by [canAllocate].
    if (node.isFork &&
        !_owned.contains(node.id) &&
        _alloc.excludedSibling(node) == null) {
      await _showForkChoice(node);
    } else {
      await _showDetail(node);
    }
  }

  Future<void> _allocate(TalentDef node) async {
    if (_alloc.allocate(node)) {
      await SaveManager.save(_save);
      if (!mounted) return;
      setState(() {
        _revision++;
        _refresh();
      });
    }
  }

  Future<void> _respec() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _frame(
        title: _t('respec'),
        children: [
          Text(
            _t('respecConfirm'),
            style: _bodyStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dialogButton(
                  _t('close'),
                  () => Navigator.pop(ctx, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dialogButton(
                  _t('respec'),
                  () => Navigator.pop(ctx, true),
                  accent: const Color(0xFFFF4D6D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok == true) {
      _alloc.respec();
      await SaveManager.save(_save);
      if (!mounted) return;
      setState(() {
        _revision++;
        _refresh();
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (!_viewInitialized) {
                _viewInitialized = true;
                final size = constraints.biggest;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _centerView(size);
                });
              }
              return InteractiveViewer(
                transformationController: _tc,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.12,
                maxScale: 4.5,
                // Animations keep running during pan/zoom (the wave must not
                // freeze while the user drags to another section).
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: _onTapUp,
                  child: SizedBox(
                    width: _tree.designSize,
                    height: _tree.designSize,
                    child: Stack(
                      children: [
                        RepaintBoundary(
                          child: CustomPaint(
                            size: Size(_tree.designSize, _tree.designSize),
                            painter: TalentWebPainter(
                              tree: _tree,
                              owned: _owned,
                              revision: _revision,
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: Listenable.merge([_pulse, _spin, _wave]),
                          builder: (context, _) => CustomPaint(
                            size: Size(_tree.designSize, _tree.designSize),
                            painter: TalentFxPainter(
                              data: _fxData,
                              pulse: _pulse.value,
                              spin: _spin.value,
                              wave: _wave.value,
                              revision: _revision,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          _buildHeader(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final level = _save.playerLevel;
    final points = _save.talentPoints;
    final intoLevel = _save.playerXp - xpForLevel(level);
    final span = xpForLevel(level + 1) - xpForLevel(level);
    final frac = span <= 0 ? 0.0 : (intoLevel / span).clamp(0.0, 1.0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconBtn(Icons.arrow_back_rounded, widget.onBack),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_t('title')}   ${_t('level')} $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF49E5A6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _pointsBadge(points),
            const SizedBox(width: 8),
            _iconBtn(Icons.restart_alt_rounded, _respec),
          ],
        ),
      ),
    );
  }

  Widget _pointsBadge(int points) {
    final active = points > 0;
    final color = active ? const Color(0xFFFFD27A) : Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        color: color.withValues(alpha: 0.08),
        boxShadow: active
            ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$points',
            style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(
            _t('points'),
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontFamily: 'monospace',
              fontSize: 7,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1.4),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );

  // ── Detail popup (single-rank) ─────────────────────────────────────────────
  Future<void> _showDetail(TalentDef node) async {
    final isOwned = _owned.contains(node.id);
    final blockedBy = _alloc.excludedSibling(node);
    final unlocked = _alloc.isUnlocked(node);
    final noPoints = _save.talentPoints <= 0;
    final canAlloc = _alloc.canAllocate(node);

    String? status;
    if (isOwned) {
      status = '✓ ${_t('owned')}';
    } else if (blockedBy != null) {
      status = _t('lockedChose').replaceFirst('{x}', _localName(blockedBy));
    } else if (!unlocked) {
      status = _t('lockedPrereq');
    } else if (noPoints) {
      status = _t('noPoints');
    } // ready → no status line (the button conveys the action).

    await showDialog<void>(
      context: context,
      builder: (ctx) => _frame(
        title: _tierLabel(node.tier),
        accent: Color(node.colorArgb),
        children: [
          Text(
            _localName(node),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(node.colorArgb),
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _localDesc(node),
            textAlign: TextAlign.center,
            style: _bodyStyle,
          ),
          if (node.isFork && blockedBy == null && !isOwned) ...[
            const SizedBox(height: 8),
            Text(
              _t('exclusiveSingle'),
              textAlign: TextAlign.center,
              style: _hintStyle,
            ),
          ],
          if (status != null) ...[
            const SizedBox(height: 12),
            Text(status, textAlign: TextAlign.center, style: _statusStyle),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dialogButton(_t('close'), () => Navigator.pop(ctx)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dialogButton(
                  isOwned ? _t('owned') : _t('allocate'),
                  canAlloc
                      ? () {
                          Navigator.pop(ctx);
                          _allocate(node);
                        }
                      : null,
                  accent: Color(node.colorArgb),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Fork choose-one-of-two popup ───────────────────────────────────────────
  Future<void> _showForkChoice(TalentDef optionA) async {
    final optionB = _tree.byId[optionA.excludes.first];
    if (optionB == null) return _showDetail(optionA);

    // Why-can't-I-pick note (the slot is shared, so it's the same for A & B).
    String? gate;
    if (!_alloc.isUnlocked(optionA)) {
      gate = _t('lockedPrereq');
    } else if (_save.talentPoints <= 0) {
      gate = _t('noPoints');
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => _frame(
        title: _t('chooseOne'),
        accent: Color(optionA.colorArgb),
        children: [
          Text(
            _t('exclusiveSingle'),
            textAlign: TextAlign.center,
            style: _hintStyle,
          ),
          const SizedBox(height: 14),
          _forkOption(ctx, optionA),
          const SizedBox(height: 10),
          _forkOption(ctx, optionB),
          if (gate != null) ...[
            const SizedBox(height: 12),
            Text(gate, textAlign: TextAlign.center, style: _statusStyle),
          ],
          const SizedBox(height: 14),
          _dialogButton(_t('close'), () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  Widget _forkOption(BuildContext ctx, TalentDef opt) {
    final canPick = _alloc.canAllocate(opt);
    final col = Color(opt.colorArgb);
    return GestureDetector(
      onTap: canPick
          ? () {
              Navigator.pop(ctx);
              _allocate(opt);
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: col.withValues(alpha: canPick ? 1.0 : 0.4),
            width: 1.6,
          ),
          color: col.withValues(alpha: canPick ? 0.1 : 0.03),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _abilityName(opt.empowers!),
                    style: TextStyle(
                      color: col.withValues(alpha: canPick ? 1.0 : 0.6),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (canPick)
                  Text(
                    _it ? 'SCEGLI ▸' : 'PICK ▸',
                    style: TextStyle(
                      color: col,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_localDesc(opt), style: _bodyStyle),
          ],
        ),
      ),
    );
  }

  // ── Shared dialog chrome ───────────────────────────────────────────────────
  Widget _frame({
    required String title,
    required List<Widget> children,
    Color accent = const Color(0xFF49E5A6),
  }) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0A16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.6), width: 1.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: accent,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _dialogButton(String label, VoidCallback? onTap, {Color? accent}) {
    final c = onTap == null ? Colors.white24 : (accent ?? Colors.white);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: c.withValues(alpha: 0.6), width: 1.5),
          color: c.withValues(alpha: 0.06),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: c,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  TextStyle get _bodyStyle => TextStyle(
    color: Colors.white.withValues(alpha: 0.85),
    fontFamily: 'monospace',
    fontSize: 12,
  );
  TextStyle get _statusStyle => TextStyle(
    color: Colors.white.withValues(alpha: 0.6),
    fontFamily: 'monospace',
    fontSize: 11,
    fontStyle: FontStyle.italic,
  );
  TextStyle get _hintStyle => TextStyle(
    color: const Color(0xFFFFD27A).withValues(alpha: 0.85),
    fontFamily: 'monospace',
    fontSize: 10,
  );

  // ── Localized node name / effect descriptions (what each bonus does) ───────
  bool get _it => _save.languageCode == 'it';

  String _effName(TalentEffect e) {
    if (!_it) return talentEffectName(e);
    return switch (e) {
      TalentEffect.atkPct => 'Danno',
      TalentEffect.shieldDuration => 'Durata Scudo',
      TalentEffect.critChance => 'Prob. Critico',
      TalentEffect.critDmg => 'Danno Critico',
      TalentEffect.fireRate => 'Cadenza Fuoco',
      TalentEffect.moveSpeed => 'Velocità',
      TalentEffect.cooldown => 'Cooldown',
      TalentEffect.goldFind => 'Oro',
      TalentEffect.essenceFind => 'XP',
      TalentEffect.magnet => 'Calamita',
      TalentEffect.bombRadius => 'Raggio Bomba',
      TalentEffect.skillPower => 'Potenzia',
    };
  }

  /// Plain-language explanation of one (effect, magnitude) grant.
  String _effLine(TalentEffect e, double mag) {
    final pct = (mag * 100).round();
    if (_it) {
      return switch (e) {
        TalentEffect.atkPct => '+$pct% danno arma',
        TalentEffect.shieldDuration =>
          '+${mag.toStringAsFixed(1)}s scudo dopo la morte (se hai vite)',
        TalentEffect.critChance => '+$pct% probabilità di critico',
        TalentEffect.critDmg => '+$pct% danno dei colpi critici',
        TalentEffect.fireRate => '+$pct% cadenza di fuoco',
        TalentEffect.moveSpeed => '+$pct% velocità di movimento',
        TalentEffect.cooldown => '−$pct% cooldown dello scatto',
        TalentEffect.goldFind => '+$pct% oro guadagnato a fine partita',
        TalentEffect.essenceFind => '+$pct% XP guadagnata (sali più in fretta)',
        TalentEffect.magnet => '+${mag.round()} raggio calamita (raccolta)',
        TalentEffect.bombRadius => '+$pct% raggio esplosione bomba',
        TalentEffect.skillPower => '+$pct% potenza abilità',
      };
    }
    return switch (e) {
      TalentEffect.atkPct => '+$pct% weapon damage',
      TalentEffect.shieldDuration =>
        '+${mag.toStringAsFixed(1)}s shield after death (if lives remain)',
      TalentEffect.critChance => '+$pct% crit chance',
      TalentEffect.critDmg => '+$pct% crit damage',
      TalentEffect.fireRate => '+$pct% fire rate',
      TalentEffect.moveSpeed => '+$pct% move speed',
      TalentEffect.cooldown => '−$pct% dash cooldown',
      TalentEffect.goldFind => '+$pct% gold earned per run',
      TalentEffect.essenceFind => '+$pct% XP gained (level up faster)',
      TalentEffect.magnet => '+${mag.round()} magnet pickup range',
      TalentEffect.bombRadius => '+$pct% bomb blast radius',
      TalentEffect.skillPower => '+$pct% ability power',
    };
  }

  String _abilityName(AbilityFx fx) {
    if (_it && fx == AbilityFx.dash) return 'Scatto';
    if (_it && fx == AbilityFx.bomb) return 'Bomba';
    return abilityFxName(fx);
  }

  /// Localized empower line for a fork.
  String _forkLine(TalentDef f) {
    final p = (f.magnitude * 100).round();
    final c = (f.empowerCdr * 100).round();
    final name = _abilityName(f.empowers!);
    return _it
        ? 'Potenzia $name: +$p% potenza, −$c% cooldown'
        : 'Empower $name: +$p% power, −$c% cooldown';
  }

  /// Localized node title.
  String _localName(TalentDef node) {
    if (node.isFork) {
      final v = _abilityName(node.empowers!);
      return _it ? 'Potenzia: $v' : 'Empower: $v';
    }
    final arm = kTalentArms[node.arm].name;
    return switch (node.tier) {
      TalentTier.root => _it ? 'Radice $arm' : '$arm Root',
      TalentTier.keystone => _it ? 'Chiave di Volta $arm' : '$arm Keystone',
      TalentTier.notable =>
        '${_effName(node.effect)} (${_it ? 'Notevole' : 'Notable'})',
      _ => _effName(node.effect),
    };
  }

  /// Localized description of everything the node grants.
  String _localDesc(TalentDef node) {
    if (node.isFork) return _forkLine(node);
    return node.stats.map((s) => _effLine(s.effect, s.magnitude)).join('  ·  ');
  }

  String _tierLabel(TalentTier t) => switch (t) {
    TalentTier.keystone => 'KEYSTONE',
    TalentTier.fork => 'FORK',
    TalentTier.notable => 'NOTABLE',
    TalentTier.root => 'ROOT',
    TalentTier.minor => 'MINOR',
  };

  // ── Local i18n (IT + EN fallback) ──────────────────────────────────────────
  String _t(String key) {
    final lang = _save.languageCode;
    final table = _strings[lang] ?? _strings['en']!;
    return table[key] ?? _strings['en']![key] ?? key;
  }

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'title': 'TALENTS',
      'level': 'LV',
      'points': 'POINTS',
      'allocate': 'ALLOCATE',
      'owned': 'OWNED',
      'close': 'CLOSE',
      'respec': 'RESPEC',
      'respecConfirm': 'Refund every allocated talent point?',
      'chooseOne': 'CHOOSE ONE',
      'exclusiveSingle': 'Exclusive — taking one permanently locks the other.',
      'noPoints': 'No talent points',
      'lockedPrereq': 'Unlock a connected node first',
      'lockedChose': 'Locked — you chose {x}',
    },
    'it': {
      'title': 'TALENTI',
      'level': 'LIV',
      'points': 'PUNTI',
      'allocate': 'SBLOCCA',
      'owned': 'POSSEDUTO',
      'close': 'CHIUDI',
      'respec': 'AZZERA',
      'respecConfirm': 'Rimborsare tutti i punti talent allocati?',
      'chooseOne': 'SCEGLI UNO',
      'exclusiveSingle':
          'Esclusivo — sceglierne uno blocca l\'altro per sempre.',
      'noPoints': 'Nessun punto talent',
      'lockedPrereq': 'Sblocca prima un nodo connesso',
      'lockedChose': 'Bloccato — hai scelto {x}',
    },
  };
}
