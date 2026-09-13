import 'package:flutter/material.dart';

import '../core/widgets/dun_view.dart';

/// A short Flutter handoff after the platform launch screen. It is an overlay,
/// so routing and database initialization can continue underneath it.
class StartupBrandingOverlay extends StatefulWidget {
  const StartupBrandingOverlay({required this.child, super.key});
  final Widget child;
  @override
  State<StartupBrandingOverlay> createState() => _StartupBrandingOverlayState();
}

class _StartupBrandingOverlayState extends State<StartupBrandingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _visible = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _controller.duration = reduced
        ? const Duration(milliseconds: 260)
        : const Duration(milliseconds: 1100);
    _controller.forward().whenComplete(() {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      if (_visible)
        IgnorePointer(
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeIn),
            ),
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: .88, end: 1).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: const SizedBox(
                        width: 150,
                        height: 150,
                        child: DunMascot(
                          semanticLabel: 'Dun, the LastDone guide',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'LastDone',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
