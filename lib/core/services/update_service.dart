import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart' as play;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// What the store answered about the build installed on this device.
enum UpdateStatus {
  /// The store could not be asked: no network, or the app is not published
  /// there yet. Nothing is ever shown in that case.
  unknown,

  /// The installed build is the newest one.
  upToDate,

  /// A newer build is published.
  available,
}

/// The answer of one version check.
class AppUpdate {
  const AppUpdate({required this.status, this.version, this.storeUrl});

  final UpdateStatus status;

  /// The version published on the store, when it is known.
  final String? version;

  /// Where to send the user to update.
  final Uri? storeUrl;

  static const AppUpdate unknown = AppUpdate(status: UpdateStatus.unknown);

  bool get isAvailable => status == UpdateStatus.available;
}

/// Asks the store whether a newer build exists, and sends the user to it.
///
/// **iOS** queries the public `itunes.apple.com` lookup with the bundle id:
/// one request, no account, no identifier — only the name of the app.
/// **Android** uses the Play In-App Updates API, which answers only when the
/// app was installed from Play; anywhere else, the check stays silent.
///
/// A failure is never shown as an error: an offline app must not nag.
class UpdateService {
  UpdateService({Future<Map<String, dynamic>> Function(Uri url)? fetch})
    : _fetch = fetch ?? _getJson;

  /// Injected by tests, so the check runs without the network.
  final Future<Map<String, dynamic>> Function(Uri url) _fetch;

  /// One check per session is enough, and it keeps the app from asking the
  /// store again every time the About screen is opened.
  static const Duration _cacheFor = Duration(hours: 6);
  static AppUpdate? _cached;
  static DateTime? _cachedAt;

  /// Asks the store. Never throws: a failure is [UpdateStatus.unknown].
  Future<AppUpdate> check({bool force = false}) async {
    final AppUpdate? cached = _cached;
    final DateTime? cachedAt = _cachedAt;
    if (!force &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheFor) {
      return cached;
    }

    AppUpdate update;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        update = await _checkAppStore();
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        update = await _checkPlay();
      } else {
        update = AppUpdate.unknown;
      }
    } catch (error) {
      debugPrint('UpdateService: check failed ($error)');
      update = AppUpdate.unknown;
    }

    _cached = update;
    _cachedAt = DateTime.now();
    return update;
  }

  /// Sends the user where the update lives. On Android, the Play flow the
  /// store provides; the store page is the fallback.
  Future<void> apply(AppUpdate update) async {
    final Uri? storeUrl = update.storeUrl;
    if (storeUrl != null) {
      await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await play.InAppUpdate.performImmediateUpdate();
        return;
      } catch (error) {
        debugPrint('UpdateService: in-app update failed ($error)');
      }
      await launchUrl(await _playPage(), mode: LaunchMode.externalApplication);
    }
  }

  Future<AppUpdate> _checkAppStore() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    final Map<String, dynamic> json = await _fetch(
      Uri.https('itunes.apple.com', '/lookup', <String, String>{
        'bundleId': info.packageName,
      }),
    );

    final List<Object?> results =
        (json['results'] as List<Object?>?) ?? const <Object?>[];
    if (results.isEmpty || results.first is! Map) {
      // Not published yet: there is nothing to offer.
      return AppUpdate.unknown;
    }

    final Map<Object?, Object?> first = results.first as Map<Object?, Object?>;
    final String? published = first['version'] as String?;
    final String? trackUrl = first['trackViewUrl'] as String?;
    if (published == null || !isNewerVersion(published, info.version)) {
      return const AppUpdate(status: UpdateStatus.upToDate);
    }

    return AppUpdate(
      status: UpdateStatus.available,
      version: published,
      storeUrl: trackUrl == null ? null : Uri.tryParse(trackUrl),
    );
  }

  Future<AppUpdate> _checkPlay() async {
    final play.AppUpdateInfo info = await play.InAppUpdate.checkForUpdate();
    if (info.updateAvailability == play.UpdateAvailability.updateAvailable) {
      return AppUpdate(
        status: UpdateStatus.available,
        version: info.availableVersionCode?.toString(),
      );
    }
    return const AppUpdate(status: UpdateStatus.upToDate);
  }

  Future<Uri> _playPage() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    return Uri.https('play.google.com', '/store/apps/details', <String, String>{
      'id': info.packageName,
    });
  }

  static Future<Map<String, dynamic>> _getJson(Uri url) async {
    final HttpClient client = HttpClient();
    try {
      final HttpClientRequest request = await client.getUrl(url);
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: url);
      }
      final String body = await response.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }

  /// Whether [candidate] is a later version than [current].
  ///
  /// Fields are compared one by one — `1.10.0` is newer than `1.9.9` — and a
  /// pre-release suffix ranks *below* the release it prepares: `0.9.0-beta` is
  /// older than `0.9.0`, and newer than `0.8.4`.
  @visibleForTesting
  static bool isNewerVersion(String candidate, String current) {
    final _Version? left = _Version.tryParse(candidate);
    final _Version? right = _Version.tryParse(current);
    if (left == null || right == null) return false;
    return left.compareTo(right) > 0;
  }
}

/// A `major.minor.patch[-prerelease]` version, which is as much as a store
/// comparison needs.
class _Version implements Comparable<_Version> {
  const _Version(this.fields, this.preRelease);

  final List<int> fields;

  /// Empty for a release, non-empty for a pre-release (`beta`, `rc.1`…).
  final String preRelease;

  static _Version? tryParse(String value) {
    final String clean = value.split('+').first.trim();
    if (clean.isEmpty) return null;

    final int dash = clean.indexOf('-');
    final String numbers = dash == -1 ? clean : clean.substring(0, dash);
    final String pre = dash == -1 ? '' : clean.substring(dash + 1);

    final List<int> fields = <int>[];
    for (final String part in numbers.split('.')) {
      final int? number = int.tryParse(part);
      if (number == null) return null;
      fields.add(number);
    }
    if (fields.isEmpty) return null;

    return _Version(fields, pre);
  }

  @override
  int compareTo(_Version other) {
    final int length = fields.length > other.fields.length
        ? fields.length
        : other.fields.length;
    for (int i = 0; i < length; i++) {
      final int left = i < fields.length ? fields[i] : 0;
      final int right = i < other.fields.length ? other.fields[i] : 0;
      if (left != right) return left.compareTo(right);
    }

    // Same numbers: a pre-release is older than the final release.
    if (preRelease.isEmpty && other.preRelease.isEmpty) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;
    return preRelease.compareTo(other.preRelease);
  }
}
