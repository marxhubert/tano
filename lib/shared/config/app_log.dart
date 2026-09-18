import 'package:flutter/foundation.dart';

/// The one place the app writes to the console.
///
/// [debugPrint] is not stripped from a release build the way an `assert` is: it
/// keeps printing. Every diagnostic therefore goes through here, and disappears
/// once the optimisation is on.
void appLog(String message) {
  if (kDebugMode) debugPrint(message);
}
