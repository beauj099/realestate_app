import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'agency.dart';

/// Preference key holding the JSON list of agent-added agencies.
const String _customAgenciesPrefsKey = 'customAgencies';

/// Reads the agencies the agent added via "Other".
List<Agency> readCustomAgencies(SharedPreferences prefs) {
  final raw = prefs.getString(_customAgenciesPrefsKey);
  if (raw == null) return const [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => Agency.customFromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('CustomAgencies: failed to parse, ignoring: $e');
    return const [];
  }
}

/// Agencies added on this device that have not reached the API yet.
///
/// Agencies are normally added through `AgencyDirectoryNotifier.add`, which
/// shares them with every agent. This holds the ones added while the API could
/// not take them (offline, or during registration before the account exists)
/// until `syncLocalAgencies` sends them up and [remove]s them.
class CustomAgenciesNotifier extends Notifier<List<Agency>> {
  @override
  List<Agency> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = readCustomAgencies(prefs);
  }

  /// Adds (or, for a name already added, updates) an agency.
  ///
  /// [logoSourcePath] is copied into app storage, because image_picker hands
  /// back a cache path the OS may clear.
  Future<Agency> add({required String name, String? logoSourcePath}) async {
    // Work from what is stored, not [state]: this can run before the initial
    // load lands, and writing a half-loaded list back would drop agencies.
    final prefs = await SharedPreferences.getInstance();
    final current = readCustomAgencies(prefs);
    final trimmed = name.trim();
    final existing = current
        .where((a) => a.name.toLowerCase() == trimmed.toLowerCase())
        .firstOrNull;
    final slug =
        existing?.slug ??
        '${Agency.customSlugPrefix}${DateTime.now().millisecondsSinceEpoch}';

    var logoPath = existing?.logoFilePath;
    if (logoSourcePath != null) {
      logoPath = await _storeLogo(logoSourcePath, slug) ?? logoPath;
    }

    final agency = Agency.custom(
      slug: slug,
      name: trimmed,
      logoFilePath: logoPath,
    );
    state = [...current.where((a) => a.slug != slug), agency];
    await prefs.setString(
      _customAgenciesPrefsKey,
      jsonEncode(state.map((a) => a.toJson()).toList()),
    );
    return agency;
  }

  /// Drops a pending agency once the API has it.
  Future<void> remove(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    final current = readCustomAgencies(prefs);
    state = current.where((a) => a.slug != slug).toList();
    await prefs.setString(
      _customAgenciesPrefsKey,
      jsonEncode(state.map((a) => a.toJson()).toList()),
    );
  }

  Future<String?> _storeLogo(String sourcePath, String slug) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/agency_logos');
      await dir.create(recursive: true);
      final dot = sourcePath.lastIndexOf('.');
      final ext = dot == -1 ? '.png' : sourcePath.substring(dot);
      // A fresh name per upload, so Image.file never serves a cached old logo.
      final dest =
          '${dir.path}/$slug-${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(sourcePath).copy(dest);
      return dest;
    } catch (e) {
      debugPrint('CustomAgencies: failed to store logo: $e');
      return null;
    }
  }
}

final customAgenciesProvider =
    NotifierProvider<CustomAgenciesNotifier, List<Agency>>(
      CustomAgenciesNotifier.new,
    );
