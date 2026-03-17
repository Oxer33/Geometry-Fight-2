import 'package:flutter/material.dart';

/// Widget helper riutilizzabile che rebuilda ad ogni notifica del Listenable.
/// Usato in tutto il progetto per animazioni e aggiornamenti periodici.
class NeonAnimatedBuilder extends StatefulWidget {
  final Listenable animation;
  final Widget Function(BuildContext, Widget?) builder;

  const NeonAnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  State<NeonAnimatedBuilder> createState() => _NeonAnimatedBuilderState();
}

class _NeonAnimatedBuilderState extends State<NeonAnimatedBuilder> {
  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.animation.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, null);
}
