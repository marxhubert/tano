import 'package:flutter/foundation.dart';
import 'package:tano/shared/config/secure_preferences.dart';

/// The four text sizes the interface offers.
enum TanoTextSize { small, normal, large, extraLarge }

extension TanoTextSizeScale on TanoTextSize {
  /// Multiplier applied on top of the system's own text scale.
  double get scale => switch (this) {
    TanoTextSize.small => 0.9,
    TanoTextSize.normal => 1.0,
    TanoTextSize.large => 1.15,
    TanoTextSize.extraLarge => 1.3,
  };
}

/// The size of the interface text, chosen in the settings.
///
/// Four steps rather than a free slider: a step is easy to name, easy to
/// store and easy to test, and the user always knows how far they are from the
/// default.
class TextScaleController extends ChangeNotifier {
  TextScaleController._();

  static final TextScaleController instance = TextScaleController._();

  static const String _prefKey = 'textSize';

  TanoTextSize _size = TanoTextSize.normal;

  TanoTextSize get size => _size;
  double get scale => _size.scale;

  Future<void> init() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    final String? saved = prefs.getString(_prefKey);
    _size = TanoTextSize.values.firstWhere(
      (TanoTextSize value) => value.name == saved,
      orElse: () => TanoTextSize.normal,
    );
    notifyListeners();
  }

  Future<void> setSize(TanoTextSize size) async {
    if (_size == size) return;
    _size = size;
    notifyListeners();
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setString(_prefKey, size.name);
  }
}