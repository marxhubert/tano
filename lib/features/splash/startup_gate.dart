import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/paper_surface.dart';
import 'package:tano/shared/widgets/privacy_guard.dart';
import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';

/// Startup can be retried without deleting data, changing keys or exposing
/// paths/SQL/error values. No application routes exist until initialization succeeds.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key, required this.initialize, required this.child});
  final Future<void> Function() initialize;
  final Widget child;
  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _ready = false;
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await widget.initialize();
      if (mounted) {
        setState(() {
          _ready = true;
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _retry() {
    if (_busy) return;
    setState(() => _busy = true);
    _initialize();
  }

  @override
  Widget build(BuildContext context) => _ready
      ? widget.child
      : MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: tanoTheme(Brightness.light),
          darkTheme: tanoTheme(Brightness.dark),
          builder: (context, child) =>
              PaperSurface(child: PrivacyGuard(child: child!)),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _busy
                    ? const CircularProgressIndicator.adaptive()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppText.tr('load_error_title'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppText.tr('storage_recovery_message'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _retry,
                            child: Text(AppText.tr('retry')),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
}
