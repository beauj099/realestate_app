import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/providers/api_providers.dart';
import 'agency.dart';
import 'custom_agencies.dart';
import 'theme_provider.dart';

/// Preference key holding the last agency list the API returned.
const String _directoryPrefsKey = 'agencyDirectory';

/// Reads the cached agency list, or null when there is none.
List<Agency>? readCachedDirectory(SharedPreferences prefs) {
  final raw = prefs.getString(_directoryPrefsKey);
  if (raw == null) return null;
  try {
    final list = (jsonDecode(raw) as List)
        .map((e) => Agency.fromApi(e as Map<String, dynamic>))
        .toList();
    return list.isEmpty ? null : list;
  } catch (e) {
    debugPrint('AgencyDirectory: failed to parse cache, ignoring: $e');
    return null;
  }
}

/// Every agency the API knows: the listed brands, then the ones agents added
/// ("Other"), which are shared with every agent.
///
/// Starts from the bundled [Agency.all], then the copy cached from the last
/// fetch, then `GET /api/agencies`. An agency added while the API cannot be
/// reached (or before sign-up finishes) is kept on this device by
/// [CustomAgenciesNotifier] and sent up by [syncLocalAgencies] once signed in.
class AgencyDirectoryNotifier extends Notifier<List<Agency>> {
  @override
  List<Agency> build() {
    _load();
    return Agency.all;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = readCachedDirectory(prefs);
    if (cached != null) state = cached;
    await refresh();
  }

  /// Fetches the list from the API. Keeps what it has when offline.
  Future<void> refresh() async {
    try {
      final json = await ref.read(agencyApiServiceProvider).getAll();
      final agencies = json.map(Agency.fromApi).toList();
      // An empty answer means a server without the Agencies table yet.
      if (agencies.isEmpty) return;
      await _store(agencies);
    } catch (e) {
      debugPrint('AgencyDirectory: refresh failed, keeping list: $e');
    }
  }

  /// Adds an unlisted agency for every agent. When the API cannot take it
  /// (offline, or not signed in yet during registration) it is kept on this
  /// device and sent later by [syncLocalAgencies].
  Future<Agency> add({required String name, String? logoPath}) async {
    try {
      final json = await ref
          .read(agencyApiServiceProvider)
          .add(name: name.trim(), logoPath: logoPath);
      final agency = Agency.fromApi(json);
      await _store([...state.where((a) => a.slug != agency.slug), agency]);
      return agency;
    } catch (e) {
      debugPrint('AgencyDirectory: add failed, keeping on device: $e');
      return ref
          .read(customAgenciesProvider.notifier)
          .add(name: name, logoSourcePath: logoPath);
    }
  }

  /// Sends agencies added on this device while offline or before sign-up to
  /// the API, then drops the local copies. The selected agency follows if it
  /// was one of them. Call once signed in; failures are retried next time.
  Future<void> syncLocalAgencies() async {
    final prefs = await SharedPreferences.getInstance();
    final local = readCustomAgencies(prefs);
    for (final pending in local) {
      try {
        final logo = pending.logoFilePath;
        final hasLogo = logo != null && await File(logo).exists();
        final json = await ref
            .read(agencyApiServiceProvider)
            .add(name: pending.name, logoPath: hasLogo ? logo : null);
        final shared = Agency.fromApi(json);
        await _store([...state.where((a) => a.slug != shared.slug), shared]);
        await ref.read(customAgenciesProvider.notifier).remove(pending.slug);
        if (ref.read(agencyProvider).slug == pending.slug) {
          await ref.read(agencyProvider.notifier).setAgency(shared);
        }
      } catch (e) {
        debugPrint('AgencyDirectory: could not send "${pending.name}": $e');
        return;
      }
    }
  }

  Future<void> _store(List<Agency> agencies) async {
    state = agencies;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _directoryPrefsKey,
      jsonEncode(agencies.map((a) => a.toApiJson()).toList()),
    );
  }
}

final agencyDirectoryProvider =
    NotifierProvider<AgencyDirectoryNotifier, List<Agency>>(
      AgencyDirectoryNotifier.new,
    );

/// Every agency an agent can pick: the directory, then any added on this
/// device that have not reached the API yet.
final selectableAgenciesProvider = Provider<List<Agency>>((ref) {
  final directory = ref.watch(agencyDirectoryProvider);
  final names = directory.map((a) => a.name.toLowerCase()).toSet();
  return [
    ...directory,
    ...ref
        .watch(customAgenciesProvider)
        .where((a) => !names.contains(a.name.toLowerCase())),
  ];
});
