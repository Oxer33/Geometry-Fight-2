import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/achievements.dart';
import '../../data/crash_reporter.dart';
import '../../data/language_controller.dart';
import '../../data/leaderboard.dart';
import '../../data/save_data.dart';
import '../../game/systems/audio_system.dart';
import '../../game/systems/music_manager.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart' show appLocale;

/// Lingue supportate dal language selector. Mappatura codice ISO → label
/// display (nome lingua nella propria lingua, "endonym"). L'ordine in lista
/// è preservato (Map literal in Dart 2.x+ → insertion-ordered).
const Map<String, String> _kSupportedLanguages = <String, String>{
  'it': 'Italiano',
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'pt': 'Português',
  'zh': '中文',
  'ja': '日本語',
  'ru': 'Русский',
};

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SettingsScreen({super.key, required this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  double _bgmVolume = 0.7;
  double _sfxVolume = 0.8;
  bool _vibration = true;
  bool _showFps = false;
  String _languageCode = 'it';

  late AnimationController _entranceController;
  late AnimationController _glowController;

  final ScrollController _settingsCtrl = ScrollController();
  final ScrollController _crashLogsCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSettings();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _settingsCtrl.dispose();
    _crashLogsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Lingua: source of truth = SaveData (Hive), non SharedPreferences. Coerente
    // con persistenza richiesta in Step 5 della task i18n.
    final saved = SaveManager.load();
    if (!mounted) return;
    setState(() {
      _bgmVolume = prefs.getDouble('bgm_volume') ?? 0.7;
      _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.8;
      _vibration = prefs.getBool('vibration') ?? true;
      _showFps = prefs.getBool('show_fps') ?? false;
      _languageCode = saved.languageCode;
    });
  }

  /// Cambia lingua: aggiorna SaveData (Hive persist), aggiorna `appLocale`
  /// globale così MaterialApp rebuilda con la nuova locale, aggiorna lo stato
  /// locale del widget per la spunta nella list.
  Future<void> _onLanguageSelected(String code) async {
    if (!_kSupportedLanguages.containsKey(code)) return;
    if (code == _languageCode) return;
    setState(() => _languageCode = code);
    await LanguageController.instance.setLanguage(code);
    appLocale.value = Locale(code);
  }

  /// Wrap orizzontale di chip selezionabili per ogni lingua supportata.
  /// Tocco su una chip = applica lingua immediatamente.
  Widget _buildLanguageWrap({required double entrance, required double delay}) {
    final e = (delay >= 1.0
        ? 1.0
        : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0));
    const items = <(String, String)>[
      ('it', '🇮🇹 Italiano'),
      ('en', '🇬🇧 English'),
      ('es', '🇪🇸 Español'),
      ('fr', '🇫🇷 Français'),
      ('de', '🇩🇪 Deutsch'),
      ('pt', '🇵🇹 Português'),
      ('ru', '🇷🇺 Русский'),
      ('zh', '🇨🇳 中文'),
      ('ja', '🇯🇵 日本語'),
    ];
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 15 * (1 - e)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            color: Colors.purpleAccent.withValues(alpha: 0.04),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final code = item.$1;
              final label = item.$2;
              final isSel = code == _languageCode;
              return InkWell(
                onTap: () => _onLanguageSelected(code),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? Colors.purpleAccent.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel ? Colors.purpleAccent : Colors.white24,
                      width: isSel ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSel ? Colors.purpleAccent : Colors.white70,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bgm_volume', _bgmVolume);
    await prefs.setDouble('sfx_volume', _sfxVolume);
    await prefs.setBool('vibration', _vibration);
    await prefs.setBool('show_fps', _showFps);
    AudioSystem.setSfxVolume(_sfxVolume);
    AudioSystem.setBgmVolume(_bgmVolume);
    AudioSystem.setVibration(_vibration);
    // Live update del player BGM (slider music = effetto immediato)
    unawaited(MusicManager.setVolume(_bgmVolume));
  }

  /// Mostra i crash log raccolti da CrashReporter. L'utente può copiarli
  /// per condividerli o cancellarli dopo aver risolto il problema.
  void _showCrashLogs() {
    final logs = CrashReporter.getLogs();
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.report_problem_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.settingsCrashLogsTitle(logs.length),
              style: const TextStyle(
                color: Colors.redAccent,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 340,
          child: logs.isEmpty
              ? Center(
                  child: Text(
                    l10n.settingsNoCrash,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                )
              : RawScrollbar(
                  controller: _crashLogsCtrl,
                  thumbVisibility: true,
                  trackVisibility: true,
                  thickness: 10,
                  radius: const Radius.circular(5),
                  thumbColor: const Color(0xFF00FFFF),
                  trackColor: const Color(0x3300FFFF),
                  trackBorderColor: const Color(0x8800FFFF),
                  child: ListView.separated(
                    controller: _crashLogsCtrl,
                    itemCount: logs.length,
                    separatorBuilder: (_, i) =>
                        const Divider(color: Colors.white12, height: 12),
                    itemBuilder: (_, i) {
                      // Più recenti in cima
                      final entry = logs[logs.length - 1 - i];
                      return Text(
                        entry,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
        ),
        actions: [
          if (logs.isNotEmpty)
            TextButton.icon(
              icon: const Icon(
                Icons.copy_rounded,
                color: Colors.cyanAccent,
                size: 16,
              ),
              label: Text(
                l10n.settingsCopy,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontFamily: 'monospace',
                ),
              ),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: logs.join('\n\n')));
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.settingsLogsCopied,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    backgroundColor: Colors.cyanAccent,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          if (logs.isNotEmpty)
            TextButton.icon(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 16,
              ),
              label: Text(
                l10n.settingsDelete,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'monospace',
                ),
              ),
              onPressed: () async {
                await CrashReporter.clear();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.close,
              style: const TextStyle(
                color: Colors.white54,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_entranceController, _glowController]),
          builder: (context, _) {
            final entrance = _entranceController.value;
            final glow = _glowController.value;

            return Column(
              children: [
                // Header
                _buildHeader(entrance, l10n),

                // Settings
                Expanded(
                  child: RawScrollbar(
                    controller: _settingsCtrl,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 10,
                    radius: const Radius.circular(5),
                    thumbColor: const Color(0xFF00FFFF),
                    trackColor: const Color(0x3300FFFF),
                    trackBorderColor: const Color(0x8800FFFF),
                    child: ListView(
                      controller: _settingsCtrl,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Language section (added BEFORE Audio per task)
                        _buildSectionHeader(
                          l10n.settingsLanguage,
                          Icons.language_rounded,
                          Colors.purpleAccent,
                          entrance,
                          0.0,
                        ),
                        const SizedBox(height: 12),
                        _buildLanguageWrap(entrance: entrance, delay: 0.02),

                        const SizedBox(height: 24),

                        // Audio section
                        _buildSectionHeader(
                          l10n.settingsAudio,
                          Icons.volume_up_rounded,
                          Colors.cyanAccent,
                          entrance,
                          0.05,
                        ),
                        const SizedBox(height: 12),
                        _buildSlider(
                          label: l10n.settingsMusic,
                          value: _bgmVolume,
                          icon: Icons.music_note_rounded,
                          color: Colors.cyanAccent,
                          onChanged: (v) => setState(() => _bgmVolume = v),
                          onChangeEnd: (_) => unawaited(_saveSettings()),
                          entrance: entrance,
                          delay: 0.08,
                          glow: glow,
                        ),
                        const SizedBox(height: 16),
                        _buildSlider(
                          label: l10n.settingsSfxLong,
                          value: _sfxVolume,
                          icon: Icons.surround_sound_rounded,
                          color: const Color(0xFFFF4466),
                          onChanged: (v) => setState(() => _sfxVolume = v),
                          onChangeEnd: (_) => unawaited(_saveSettings()),
                          entrance: entrance,
                          delay: 0.12,
                          glow: glow,
                        ),

                        const SizedBox(height: 24),

                        // Gameplay section
                        _buildSectionHeader(
                          l10n.settingsGameplay,
                          Icons.tune_rounded,
                          const Color(0xFFCC00FF),
                          entrance,
                          0.18,
                        ),
                        const SizedBox(height: 12),
                        _buildToggle(
                          label: l10n.settingsVibration,
                          value: _vibration,
                          icon: Icons.vibration_rounded,
                          color: const Color(0xFFCC00FF),
                          onChanged: (v) {
                            setState(() => _vibration = v);
                            unawaited(_saveSettings());
                          },
                          entrance: entrance,
                          delay: 0.22,
                          glow: glow,
                        ),
                        const SizedBox(height: 12),
                        _buildToggle(
                          label: l10n.settingsShowFps,
                          value: _showFps,
                          icon: Icons.speed_rounded,
                          color: Colors.greenAccent,
                          onChanged: (v) {
                            setState(() => _showFps = v);
                            unawaited(_saveSettings());
                          },
                          entrance: entrance,
                          delay: 0.26,
                          glow: glow,
                        ),

                        const SizedBox(height: 32),

                        // Danger zone
                        _buildSectionHeader(
                          l10n.settingsDangerZone,
                          Icons.warning_rounded,
                          Colors.redAccent,
                          entrance,
                          0.3,
                        ),
                        const SizedBox(height: 12),
                        _buildResetButton(entrance, glow, l10n),

                        const SizedBox(height: 32),

                        // Test / Debug section
                        _buildSectionHeader(
                          l10n.settingsTestDebug,
                          Icons.bug_report_rounded,
                          Colors.amberAccent,
                          entrance,
                          0.4,
                        ),
                        const SizedBox(height: 12),
                        _buildTestButton(
                          label: l10n.settingsAddCredits,
                          icon: Icons.add_circle_outline,
                          color: Colors.amberAccent,
                          entrance: entrance,
                          delay: 0.45,
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final save = SaveManager.load();
                            save.goldGeoms += 100000;
                            await SaveManager.save(save);
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.settingsCreditsAdded(save.goldGeoms),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                backgroundColor: Colors.amberAccent.shade700,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTestButton(
                          label: l10n.settingsResetPurchases,
                          icon: Icons.restart_alt_rounded,
                          color: Colors.orangeAccent,
                          entrance: entrance,
                          delay: 0.5,
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            // Rebuild SaveData immutabilmente (coding-style:
                            // ALWAYS new objects, NEVER mutate): preservo i
                            // campi non resettati (goldGeoms, highscores,
                            // stats, totalPlaytime, playedModes,
                            // activeModifiers) e ricreo liste/mappe da zero.
                            final current = SaveManager.load();
                            final save = SaveData(
                              goldGeoms: current.goldGeoms,
                              upgrades: <String, int>{},
                              unlockedSkins: <String>['classic'],
                              unlockedTrails: <String>['normal'],
                              unlockedModes: <String>['classic'],
                              unlockedWeapons: <String>['basic'],
                              highscores: Map<String, int>.from(
                                current.highscores,
                              ),
                              totalPlaytime: current.totalPlaytime,
                              stats: Map<String, int>.from(current.stats),
                              playedModes: List<String>.from(
                                current.playedModes,
                              ),
                              activeModifiers: List<String>.from(
                                current.activeModifiers,
                              ),
                              activeSkin: 'classic',
                              activeTrail: 'normal',
                              startingWeapon: 'basic',
                            );
                            await SaveManager.save(save);
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.settingsPurchasesReset,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                backgroundColor: Colors.orangeAccent,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTestButton(
                          label: l10n.settingsCrashLogs,
                          icon: Icons.report_problem_rounded,
                          color: Colors.redAccent,
                          entrance: entrance,
                          delay: 0.55,
                          onTap: _showCrashLogs,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double entrance, AppLocalizations l10n) {
    return Opacity(
      opacity: entrance,
      child: Transform.translate(
        offset: Offset(0, -20 * (1 - entrance)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                    ),
                    color: Colors.cyanAccent.withValues(alpha: 0.05),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.cyanAccent,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                l10n.settingsTitle,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                  shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 8)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    double entrance,
    double delay,
  ) {
    final e = (delay >= 1.0
        ? 1.0
        : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0));
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(-15 * (1 - e), 0),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color, size: 12),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 4,
                shadows: [
                  Shadow(color: color.withValues(alpha: 0.3), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.3), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
    required double entrance,
    required double delay,
    required double glow,
  }) {
    final e = (delay >= 1.0
        ? 1.0
        : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0));
    final pct = (value * 100).round();

    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 15 * (1 - e)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                color.withValues(alpha: 0.04 + glow * 0.02),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: color.withValues(alpha: 0.1),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$pct%',
                      style: TextStyle(
                        color: color,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Custom slider track
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: color,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.06),
                  thumbColor: color,
                  overlayColor: color.withValues(alpha: 0.15),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                ),
                child: Slider(
                  value: value,
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required IconData icon,
    required Color color,
    required ValueChanged<bool> onChanged,
    required double entrance,
    required double delay,
    required double glow,
  }) {
    final e = (delay >= 1.0
        ? 1.0
        : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0));

    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 15 * (1 - e)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                (value ? color : Colors.white).withValues(
                  alpha: 0.04 + (value ? glow * 0.02 : 0),
                ),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: value ? color : Colors.white38, size: 16),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              // Custom neon toggle
              GestureDetector(
                onTap: () => onChanged(!value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 48,
                  height: 26,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: value
                          ? color.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    color: value
                        ? color.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.03),
                    boxShadow: value
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: value ? color : Colors.white38,
                        boxShadow: value
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required String label,
    required IconData icon,
    required Color color,
    required double entrance,
    required double delay,
    required VoidCallback onTap,
  }) {
    final e = ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 15 * (1 - e)),
        child: Center(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.4)),
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.08),
                    color.withValues(alpha: 0.02),
                  ],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton(
    double entrance,
    double glow,
    AppLocalizations l10n,
  ) {
    final e = ((entrance - 0.35) / 0.65).clamp(0.0, 1.0);

    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 15 * (1 - e)),
        child: Center(
          child: GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF0A0A0A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  title: Row(
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.settingsResetTitle,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontFamily: 'monospace',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    l10n.settingsResetWarning,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        l10n.settingsResetButton,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await SaveManager.clear();
                await LeaderboardManager.clear();
                await AchievementManager.clear();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('bgm_volume');
                await prefs.remove('sfx_volume');
                await prefs.remove('vibration');
                await prefs.remove('show_fps');
                await prefs.remove('tutorial_seen');
                if (!mounted) return;
                setState(() {
                  _bgmVolume = 0.7;
                  _sfxVolume = 0.8;
                  _vibration = true;
                  _showFps = false;
                  _languageCode = 'it';
                });
                // Riapplico i volumi runtime: `prefs.remove` pulisce il
                // persistente ma il mixer live conserva l'ultimo valore
                // usato → senza questi reapply la musica resterebbe al
                // volume pre-reset finché non si tocca lo slider.
                AudioSystem.setSfxVolume(_sfxVolume);
                AudioSystem.setBgmVolume(_bgmVolume);
                AudioSystem.setVibration(_vibration);
                unawaited(MusicManager.setVolume(_bgmVolume));
                // Reset locale a default 'it': `SaveManager.clear()` ha
                // wipato il save quindi load() restituirà un nuovo SaveData
                // con languageCode='it'. Sync appLocale globale.
                appLocale.value = const Locale('it');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.redAccent.withValues(alpha: 0.08),
                    Colors.redAccent.withValues(alpha: 0.02),
                  ],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.settingsResetAllData,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
