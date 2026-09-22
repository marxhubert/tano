part of 'app_fab.dart';

/// Observes the real, visible layout. Unlike a hidden copy this follows text
/// scale, locale, width and asynchronous content without duplicate menus.
class _FabSizeObserver extends SingleChildRenderObjectWidget {
  const _FabSizeObserver({
    super.key,
    required this.onSizeChanged,
    required super.child,
  });
  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _FabSizeRenderObject(onSizeChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    _FabSizeRenderObject renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _FabSizeRenderObject extends RenderProxyBox {
  _FabSizeRenderObject(this.onSizeChanged);
  ValueChanged<Size> onSizeChanged;
  Size? _reportedSize;
  bool _pending = false;

  @override
  void performLayout() {
    super.performLayout();
    if (_reportedSize == size || _pending) return;
    _pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pending = false;
      if (!attached || _reportedSize == size) return;
      _reportedSize = size;
      onSizeChanged(size);
    });
  }
}
