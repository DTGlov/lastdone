import 'package:flutter/material.dart';

enum DunState { resting, focused, celebrating }

enum DunMascotState { idle, subscriptions, celebrating }

/// Shared local mascot states. Assets never require a runtime network request.
class DunMascot extends StatefulWidget {
  const DunMascot({
    this.state = DunMascotState.idle,
    this.semanticLabel,
    this.decorative = false,
    super.key,
  });
  final DunMascotState state;
  final String? semanticLabel;
  final bool decorative;

  @override
  State<DunMascot> createState() => _DunMascotState();
}

class _DunMascotState extends State<DunMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathing = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBreathing();
  }

  @override
  void didUpdateWidget(covariant DunMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBreathing();
  }

  void _syncBreathing() {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (widget.state == DunMascotState.subscriptions && !reducedMotion) {
      _breathing.repeat(reverse: true);
    } else {
      _breathing.stop();
    }
  }

  @override
  void dispose() {
    _breathing.dispose();
    super.dispose();
  }

  String get _asset => switch (widget.state) {
    DunMascotState.idle => 'assets/images/dun/dun_idle.png',
    DunMascotState.subscriptions => 'assets/images/dun/dun_subscriptions.png',
    DunMascotState.celebrating => 'assets/images/dun/dun_celebrating.png',
  };

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      _asset,
      fit: BoxFit.contain,
      cacheWidth: 800,
      errorBuilder: (context, error, stackTrace) => Icon(
        widget.state == DunMascotState.celebrating
            ? Icons.celebration_outlined
            : Icons.auto_awesome,
        size: 40,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    final animated = widget.state == DunMascotState.subscriptions
        ? AnimatedBuilder(
            animation: _breathing,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, -1.5 * _breathing.value),
              child: child,
            ),
            child: image,
          )
        : image;
    return Semantics(
      container: true,
      image: !widget.decorative,
      label: widget.decorative ? null : widget.semanticLabel,
      excludeSemantics: widget.decorative,
      child: animated,
    );
  }
}

/// Compatibility adapter for screens that still use the original state API.
class DunView extends StatelessWidget {
  const DunView({this.state = DunState.resting, super.key});
  final DunState state;

  @override
  Widget build(BuildContext context) => DunMascot(
    state: state == DunState.celebrating
        ? DunMascotState.celebrating
        : DunMascotState.idle,
    semanticLabel: switch (state) {
      DunState.resting => 'Dun is resting',
      DunState.focused => 'Dun is focused',
      DunState.celebrating => 'Dun is celebrating',
    },
  );
}
