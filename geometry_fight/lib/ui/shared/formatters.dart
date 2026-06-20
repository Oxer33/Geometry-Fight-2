// Shared number/time formatters consolidated from HUD and main menu.
// Keep output identical to the original per-screen implementations.

/// Compact score formatting used by the in-game HUD.
/// Note: only abbreviates with K from 10000 upward (matches original HUD).
String formatScore(int s) {
  if (s >= 1000000000) return '${(s / 1000000000).toStringAsFixed(1)}B';
  if (s >= 1000000) return '${(s / 1000000).toStringAsFixed(1)}M';
  if (s >= 10000) return '${s ~/ 1000}K';
  return '$s';
}

/// Compact number formatting used by the main menu (K from 1000 upward).
String formatNumber(int n) {
  if (n >= 1000000000) {
    return '${(n / 1000000000).toStringAsFixed(1)}B';
  }
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1)}K';
  }
  return n.toString();
}

/// Human-readable elapsed time in hours/minutes.
String formatTime(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) {
    return '${h}h ${m}m';
  }
  return '${m}m';
}
