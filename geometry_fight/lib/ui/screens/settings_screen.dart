import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/save_data.dart';

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

  late AnimationController _entranceController;
  late AnimationController _glowController;

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
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bgmVolume = prefs.getDouble('bgm_volume') ?? 0.7;
      _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.8;
      _vibration = prefs.getBool('vibration') ?? true;
      _showFps = prefs.getBool('show_fps') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bgm_volume', _bgmVolume);
    await prefs.setDouble('sfx_volume', _sfxVolume);
    await prefs.setBool('vibration', _vibration);
    await prefs.setBool('show_fps', _showFps);
  }

  @override
  Widget build(BuildContext context) {
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
                _buildHeader(entrance),

                // Settings
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Audio section
                      _buildSectionHeader('AUDIO', Icons.volume_up_rounded,
                          Colors.cyanAccent, entrance, 0.0),
                      const SizedBox(height: 12),
                      _buildSlider(
                        label: 'MUSICA',
                        value: _bgmVolume,
                        icon: Icons.music_note_rounded,
                        color: Colors.cyanAccent,
                        onChanged: (v) => setState(() => _bgmVolume = v),
                        onChangeEnd: (_) => _saveSettings(),
                        entrance: entrance,
                        delay: 0.05,
                        glow: glow,
                      ),
                      const SizedBox(height: 16),
                      _buildSlider(
                        label: 'EFFETTI SONORI',
                        value: _sfxVolume,
                        icon: Icons.surround_sound_rounded,
                        color: const Color(0xFFFF4466),
                        onChanged: (v) => setState(() => _sfxVolume = v),
                        onChangeEnd: (_) => _saveSettings(),
                        entrance: entrance,
                        delay: 0.1,
                        glow: glow,
                      ),

                      const SizedBox(height: 24),

                      // Gameplay section
                      _buildSectionHeader('GAMEPLAY', Icons.tune_rounded,
                          const Color(0xFFCC00FF), entrance, 0.15),
                      const SizedBox(height: 12),
                      _buildToggle(
                        label: 'VIBRAZIONE',
                        value: _vibration,
                        icon: Icons.vibration_rounded,
                        color: const Color(0xFFCC00FF),
                        onChanged: (v) {
                          setState(() => _vibration = v);
                          _saveSettings();
                        },
                        entrance: entrance,
                        delay: 0.2,
                        glow: glow,
                      ),
                      const SizedBox(height: 12),
                      _buildToggle(
                        label: 'MOSTRA FPS',
                        value: _showFps,
                        icon: Icons.speed_rounded,
                        color: Colors.greenAccent,
                        onChanged: (v) {
                          setState(() => _showFps = v);
                          _saveSettings();
                        },
                        entrance: entrance,
                        delay: 0.25,
                        glow: glow,
                      ),

                      const SizedBox(height: 32),

                      // Danger zone
                      _buildSectionHeader('ZONA PERICOLOSA',
                          Icons.warning_rounded, Colors.redAccent, entrance, 0.3),
                      const SizedBox(height: 12),
                      _buildResetButton(entrance, glow),

                      const SizedBox(height: 32),

                      // Test / Debug section
                      _buildSectionHeader('TEST / DEBUG',
                          Icons.bug_report_rounded, Colors.amberAccent, entrance, 0.4),
                      const SizedBox(height: 12),
                      _buildTestButton(
                        label: '+1000 CREDITI',
                        icon: Icons.add_circle_outline,
                        color: Colors.amberAccent,
                        entrance: entrance,
                        delay: 0.45,
                        onTap: () async {
                          final save = SaveManager.load();
                          save.goldGeoms += 1000;
                          await SaveManager.save(save);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('+1000 crediti! Totale: ${save.goldGeoms}',
                                  style: const TextStyle(fontFamily: 'monospace')),
                              backgroundColor: Colors.amberAccent.shade700,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTestButton(
                        label: 'RESET ACQUISTI',
                        icon: Icons.restart_alt_rounded,
                        color: Colors.orangeAccent,
                        entrance: entrance,
                        delay: 0.5,
                        onTap: () async {
                          final save = SaveManager.load();
                          save.unlockedSkins
                            ..clear()
                            ..add('classic');
                          save.unlockedTrails
                            ..clear()
                            ..add('normal');
                          save.unlockedWeapons
                            ..clear()
                            ..add('basic');
                          save.unlockedModes
                            ..clear()
                            ..add('classic');
                          save.upgrades.clear();
                          save.activeSkin = 'classic';
                          save.activeTrail = 'normal';
                          save.startingWeapon = 'basic';
                          await SaveManager.save(save);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Acquisti resettati!',
                                  style: TextStyle(fontFamily: 'monospace')),
                              backgroundColor: Colors.orangeAccent,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double entrance) {
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
                        color: Colors.cyanAccent.withValues(alpha: 0.3)),
                    color: Colors.cyanAccent.withValues(alpha: 0.05),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.cyanAccent, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'SETTINGS',
                style: TextStyle(
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
      String title, IconData icon, Color color, double entrance, double delay) {
    final e = (delay >= 1.0 ? 1.0 : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0));
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
                  Shadow(color: color.withValues(alpha: 0.3), blurRadius: 4)
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
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
    final e = (delay >= 1.0 ? 1.0 : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0));
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
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: color.withValues(alpha: 0.1),
                      border:
                          Border.all(color: color.withValues(alpha: 0.3)),
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
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
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
    final e = (delay >= 1.0 ? 1.0 : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0));

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
                (value ? color : Colors.white)
                    .withValues(alpha: 0.04 + (value ? glow * 0.02 : 0)),
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
                    alignment:
                        value ? Alignment.centerRight : Alignment.centerLeft,
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

  Widget _buildResetButton(double entrance, double glow) {
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
                        color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.warning_rounded,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      const Text('RESET DATA',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontFamily: 'monospace',
                            fontSize: 16,
                          )),
                    ],
                  ),
                  content: const Text(
                    'Tutti i progressi, upgrade e acquisti verranno cancellati.',
                    style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                        fontSize: 12),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('ANNULLA',
                          style: TextStyle(
                              color: Colors.white54, fontFamily: 'monospace')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('RESET',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await SaveManager.clear();
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
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.4)),
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
                  const Icon(Icons.delete_forever_rounded,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'RESET ALL DATA',
                    style: TextStyle(
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
