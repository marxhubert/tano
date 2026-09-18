import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';

/// How long a toast stays on screen, fade included.
const Duration _toastDuration = Duration(milliseconds: 2200);
const Duration _toastFade = Duration(milliseconds: 200);

/// The toast currently on screen, so a new one replaces it instead of stacking.
OverlayEntry? _currentToast;

/// Shows a short, non-blocking message.
///
/// Android gets the idiomatic [SnackBar]. iOS has no such banner, and an alert
/// would stop the user for a single sentence, so it gets a toast: a small
/// floating capsule that leaves on its own.
Future<void> showTanoToast(BuildContext context, String message) async {
  final ThemeData theme = Theme.of(context);
  final bool isApple =
      theme.platform == TargetPlatform.iOS ||
      theme.platform == TargetPlatform.macOS;
  if (!isApple) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        // A SnackBar with an action defaults to persist: true; without an
        // action the timeout already applies.
        persist: false,
      ),
    );
    return;
  }

  final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  // A fast second notice replaces the first rather than piling up on it.
  if (_currentToast?.mounted ?? false) _currentToast!.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (BuildContext context) => _Toast(
      message: message,
      onDismissed: () {
        entry.remove();
        if (identical(_currentToast, entry)) _currentToast = null;
      },
    ),
  );
  _currentToast = entry;
  overlay.insert(entry);
}

/// Confirms a move: "1 note moved to Work", or "moved back to Home".
Future<void> showMovedToast(
  BuildContext context, {
  required int count,
  required String? folderId,
}) async {
  final String what = AppText.count(count, 'note', 'notes');
  if (folderId == null) {
    await showTanoToast(context, '$what ${AppText.tr('moved_home')}');
    return;
  }
  final String? name = await _folderName(folderId);
  if (!context.mounted) return;
  await showTanoToast(
    context,
    name == null
        ? '$what ${AppText.tr('moved')}'
        : '$what ${AppText.tr('moved_to', <String, String>{'folder': name})}',
  );
}

/// Confirms a lock change, on a note or on a folder.
Future<void> showLockToast(
  BuildContext context, {
  required bool locked,
  required bool folder,
}) {
  final String key = folder
      ? (locked ? 'folder_locked' : 'folder_unlocked')
      : (locked ? 'note_locked' : 'note_unlocked');
  return showTanoToast(context, AppText.tr(key));
}

Future<String?> _folderName(String id) async {
  final NotesRepository repository = getIt<NotesRepository>();
  if (repository is! FoldersRepository) return null;
  final List<Folder> folders =
      await (repository as FoldersRepository).loadFolders();
  for (final Folder folder in folders) {
    if (folder.id == id) return folder.name;
  }
  return null;
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.onDismissed});

  final String message;
  final VoidCallback onDismissed;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: _toastFade,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fade.forward();
    _timer = Timer(_toastDuration, _leave);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (!mounted) return;
    await _fade.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Just under the app bar, and never wider than three quarters of the
    // screen: the notice hugs its text but stays a notice, not a banner.
    final double maxWidth = MediaQuery.sizeOf(context).width * 0.75;
    return Positioned(
      top: MediaQuery.paddingOf(context).top +
          kToolbarHeight +
          appPaddingTight,
      left: sectionGap,
      right: sectionGap,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fade,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: tanoTeal.withValues(alpha: 0.80),
                  borderRadius: BorderRadius.circular(pillRadius),
                  // The same rule as the FAB: light in dark, dark in light.
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: TanoText.label,
                    // Plain text: no weight, no underline, no highlight.
                    fontWeight: FontWeight.normal,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}