import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/save_data.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SettingsScreen({super.key, required this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _bgmVolume = 0.7;
  double _sfxVolume = 0.8;
  bool _vibration = true;
  bool _showFps = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SettingSlider(
            label: 'BGM VOLUME',
            value: _bgmVolume,
            onChanged: (v) {
              setState(() => _bgmVolume = v);
              _saveSettings();
            },
          ),
          const SizedBox(height: 24),
          _SettingSlider(
            label: 'SFX VOLUME',
            value: _sfxVolume,
            onChanged: (v) {
              setState(() => _sfxVolume = v);
              _saveSettings();
            },
          ),
          const SizedBox(height: 24),
          _SettingToggle(
            label: 'VIBRATION',
            value: _vibration,
            onChanged: (v) {
              setState(() => _vibration = v);
              _saveSettings();
            },
          ),
          const SizedBox(height: 24),
          _SettingToggle(
            label: 'SHOW FPS',
            value: _showFps,
            onChanged: (v) {
              setState(() => _showFps = v);
              _saveSettings();
            },
          ),
          const SizedBox(height: 48),
          Center(
            child: GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF111111),
                    title: const Text('RESET DATA',
                        style: TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                    content: const Text(
                      'This will erase all progress, upgrades, and purchases.',
                      style: TextStyle(color: Colors.white70, fontFamily: 'monospace'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL',
                            style: TextStyle(color: Colors.white54)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('RESET',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await SaveManager.clear();
                  setState(() {});
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'RESET ALL DATA',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _SettingSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.cyanAccent,
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.cyanAccent,
            overlayColor: Colors.cyanAccent.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: Colors.cyanAccent.withValues(alpha: 0.5),
          thumbColor: WidgetStatePropertyAll(Colors.cyanAccent),
          inactiveTrackColor: Colors.white12,
        ),
      ],
    );
  }
}
