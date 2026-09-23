import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';

/// Route registrations live as long as their drafts, including covered routes.
/// Registration itself does not rebuild the tree; lifecycle events do.
class PrivacySession extends ChangeNotifier {
  bool _blocked = false;
  bool get blocked => _blocked;
  set blocked(bool value) {
    if (_blocked == value) return;
    _blocked = value;
    notifyListeners();
  }

  final Set<Object> _protected = {};
  bool get hasProtectedContent => _protected.isNotEmpty;
  void setProtected(Object token, bool value) {
    if (value) {
      _protected.add(token);
    } else {
      _protected.remove(token);
    }
  }
}

class _PrivacyScope extends InheritedNotifier<PrivacySession> {
  const _PrivacyScope({required PrivacySession session, required super.child})
    : super(notifier: session);
  PrivacySession get session => notifier!;
}

bool isPrivacyBlocked(BuildContext context) =>
    context.getInheritedWidgetOfExactType<_PrivacyScope>()?.session.blocked ??
    false;

/// Registers a protected screen without discarding its state when it is hidden.
class ProtectedContent extends StatefulWidget {
  const ProtectedContent({
    super.key,
    required this.protected,
    required this.child,
  });
  final bool protected;
  final Widget child;
  @override
  State<ProtectedContent> createState() => _ProtectedContentState();
}

class _ProtectedContentState extends State<ProtectedContent> {
  PrivacySession? _session;
  final Object _token = Object();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context
        .dependOnInheritedWidgetOfExactType<_PrivacyScope>()
        ?.session;
    if (_session != session) {
      _session?.setProtected(_token, false);
      _session = session;
    }
    _session?.setProtected(_token, widget.protected);
  }

  @override
  void didUpdateWidget(ProtectedContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _session?.setProtected(_token, widget.protected);
  }

  @override
  void dispose() {
    _session?.setProtected(_token, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PopScope(canPop: !(_session?.blocked ?? false), child: widget.child);
}

/// Covers all content while inactive; protected routes also require a fresh
/// credential after a real background transition. Draft widgets stay mounted.
class PrivacyGuard extends StatefulWidget {
  const PrivacyGuard({super.key, required this.child, this.authenticate});
  final Widget child;
  final Future<bool> Function()? authenticate;
  @override
  State<PrivacyGuard> createState() => _PrivacyGuardState();
}

class _PrivacyGuardState extends State<PrivacyGuard>
    with WidgetsBindingObserver {
  final _session = PrivacySession();
  static const _native = MethodChannel('tano/privacy');

  void _releaseNativeCoverAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _state != AppLifecycleState.resumed) return;
      try {
        await _native.invokeMethod<void>('frameReady');
      } on MissingPluginException {
        /* Unit tests and non-iOS platforms. */
      } on PlatformException {
        /* Keep a native cover rather than expose content. */
      }
    });
  }

  AppLifecycleState _state = AppLifecycleState.resumed;
  bool _locked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    _state =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _session.blocked = _state != AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _releaseNativeCoverAfterFrame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_session.hasProtectedContent) _locked = true;
    }
    if (state != AppLifecycleState.resumed) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _session.blocked = state != AppLifecycleState.resumed || _locked;
    setState(() => _state = state);
    if (state == AppLifecycleState.resumed) {
      _releaseNativeCoverAfterFrame();
      // Returning from the system viewer is the moment to sweep plaintext
      // copies that have outlived their viewing session.
      if (getIt.isRegistered<AttachmentsStore>()) {
        unawaited(getIt<AttachmentsStore>().clearExpiredMaterialized());
      }
    }
  }

  Future<void> _unlock() async {
    if (_authenticating || _state != AppLifecycleState.resumed) return;
    setState(() => _authenticating = true);
    var success = false;
    try {
      success =
          await (widget.authenticate?.call() ??
              getIt<AuthService>().authenticate());
    } catch (_) {
      // Fail closed, without exposing platform exception contents.
    }
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      // Android's own credential activity may pause the app. A successful
      // system result after return is fresh authorization, not an old session.
      if (success && _state == AppLifecycleState.resumed) {
        _locked = false;
      }
    });
    _session.blocked = _state != AppLifecycleState.resumed || _locked;
  }

  @override
  Widget build(BuildContext context) {
    final covered = _state != AppLifecycleState.resumed || _locked;
    return _PrivacyScope(
      session: _session,
      child: PopScope(
        canPop: !covered,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Offstage removes paint, hit testing and semantics, preserving drafts.
            Offstage(
              offstage: covered,
              child: TickerMode(enabled: !covered, child: widget.child),
            ),
            if (covered)
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 40),
                        const SizedBox(height: 16),
                        Text(
                          AppText.tr('privacy_screen_locked'),
                          textAlign: TextAlign.center,
                        ),
                        if (_state == AppLifecycleState.resumed) ...[
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _authenticating ? null : _unlock,
                            child: Text(AppText.tr('option_unlock')),
                          ),
                        ],
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
}
