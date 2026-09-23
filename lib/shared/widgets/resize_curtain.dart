import 'package:flutter/material.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Hides the frames Flutter paints while the window is still resizing.
///
/// During a rotation the engine hands the app a viewport whose aspect ratio no
/// longer matches the window being animated, so the compositor scales the whole
/// surface — the page stretches, then snaps back. This is flutter/flutter#16322,
/// and the engine already delays its own viewport swap (reducing the distortion
/// by half). The app cannot stop the scaling, but it can hide the frames: a
/// flat paper curtain drops as soon as the size changes and lifts once the size
/// has held still for [settle] — that is, once the rotation is over. A flat
/// colour is scaled like everything else, yet it has no shape to distort.
class ResizeCurtain extends StatefulWidget {
  const ResizeCurtain({super.key, required this.child, this.settle = _defaultSettle});

  final Widget child;

  /// How long the size must stay put before the content shows again. A little
  /// longer than the platform's rotation transition.
  final Duration settle;

  static const Duration _defaultSettle = Duration(milliseconds: 260);

  @override
  State<ResizeCurtain> createState() => _ResizeCurtainState();
}

class _ResizeCurtainState extends State<ResizeCurtain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: widget.settle,
  );

  Size? _size;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Size size = MediaQuery.sizeOf(context);
    // First layout is not a resize: only a change after it raises the curtain.
    if (_size != null && _size != size) _settle.forward(from: 0);
    _size = size;
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _settle,
            builder: (BuildContext context, Widget? child) =>
                _settle.isAnimating
                ? const IgnorePointer(
                    child: _CurtainSurface(
                      key: ValueKey<String>('resize-curtain'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// The paper the curtain shows. Flat, so the rotation's non-uniform scale has
/// nothing to distort.
class _CurtainSurface extends StatelessWidget {
  const _CurtainSurface({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(color: barColor(context));
}
