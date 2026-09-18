import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Cover image of a note or folder, materialized from the encrypted store.
///
/// It is meant to sit behind the card content: it never intercepts taps and
/// shows a neutral placeholder until the file has been read.
class CoverImage extends StatefulWidget {
  const CoverImage({
    super.key,
    required this.name,
    this.fit = BoxFit.cover,
    this.onError,
    this.expand = true,
    this.lightDimAlpha = 0.12,
  });

  final String name;
  final BoxFit fit;

  /// Called once when the stored file cannot be read (corrupted or missing),
  /// so a manageable cover can surface it.
  final VoidCallback? onError;

  /// When true (default) the image fills the box it is given. When false it
  /// keeps its own aspect ratio at full width and sizes the box itself.
  final bool expand;

  /// Dim applied in the light theme; the dark theme always dims at 0.3.
  final double lightDimAlpha;

  @override
  State<CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<CoverImage> {
  // Shared store so the materialized-path cache is reused across every card.
  AttachmentsStore get _store => getIt<AttachmentsStore>();

  late Future<String> _path = _store.materialize(widget.name);
  bool _errorReported = false;

  @override
  void didUpdateWidget(CoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _path = _store.materialize(widget.name);
      _errorReported = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<String>(
      future: _path,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasError && !_errorReported) {
          _errorReported = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onError?.call();
          });
        }
        // Fade the cover in so a card does not pop when it appears.
        if (!snapshot.hasData) {
          return AnimatedSwitcher(
            duration: TanoMotion.base,
            child: widget.expand
                ? const _CoverPlaceholder(
                    key: ValueKey<String>('cover-placeholder'),
                  )
                : const SizedBox.shrink(),
          );
        }

        final Widget image = Image.file(
          File(snapshot.data!),
          fit: widget.fit,
          width: widget.expand ? null : double.infinity,
          // Decode at most a screen-wide bitmap: covers never show bigger,
          // keeping many covers light.
          cacheWidth:
              (MediaQuery.sizeOf(context).width *
                      MediaQuery.devicePixelRatioOf(context))
                  .round(),
        );
        final Widget dim = ColoredBox(
          color: Colors.black.withValues(
            alpha: isDark ? 0.3 : widget.lightDimAlpha,
          ),
        );
        return AnimatedSwitcher(
          duration: TanoMotion.base,
          child: widget.expand
              // Background: fill the box it is given.
              ? Stack(
                  key: const ValueKey<String>('cover'),
                  fit: StackFit.expand,
                  children: <Widget>[image, dim],
                )
              // Full image: keep the aspect ratio and dim only the image.
              : Stack(
                  key: const ValueKey<String>('cover'),
                  children: <Widget>[image, Positioned.fill(child: dim)],
                ),
        );
      },
    );
  }
}

/// Neutral block shown while a cover is read from disk.
class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05),
      child: Center(
        child: Icon(
          Symbols.imagesmode,
          size: 22.0,
          color: mutedTextColor(context).withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
