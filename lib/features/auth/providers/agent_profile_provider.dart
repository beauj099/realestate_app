import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/providers/api_providers.dart';
import '../../../core/theme/agency.dart';
import '../../../core/theme/custom_agencies.dart';
import '../../../core/theme/theme_provider.dart';
import '../data/models/agent_profile.dart';
import 'auth_provider.dart';

/// Secure-storage key holding the cached profile JSON.
const String _profileStorageKey = 'agent_profile';

/// Owns the signed-in agent's profile.
///
/// Loaded from `GET /api/agents/me` whenever the agent becomes signed in, and
/// saved with `PUT`. A copy is cached in secure storage (it carries an email,
/// mobile and FFC number) so the profile shows before the request returns.
class AgentProfileNotifier extends Notifier<AgentProfile> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  AgentProfile build() {
    ref.listen(authProvider.select((s) => s.status), (previous, next) {
      if (next == AuthStatus.authenticated) {
        refresh();
      } else if (next == AuthStatus.unauthenticated) {
        state = const AgentProfile();
      }
    });
    _loadCache();
    if (ref.read(authProvider).status == AuthStatus.authenticated) refresh();
    return const AgentProfile();
  }

  Future<void> _loadCache() async {
    try {
      final raw = await _storage.read(key: _profileStorageKey);
      if (raw == null || !state.isEmpty) return;
      state = AgentProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('AgentProfile: failed to load cache: $e');
    }
  }

  Future<void> _writeCache(AgentProfile profile) async {
    try {
      await _storage.write(
        key: _profileStorageKey,
        value: jsonEncode(profile.toJson()),
      );
    } catch (e) {
      debugPrint('AgentProfile: failed to write cache: $e');
    }
  }

  /// Pulls the profile from the API and re-brands the app to the agent's
  /// agency. Keeps the cached copy when offline.
  Future<void> refresh() async {
    try {
      final json = await ref.read(agentApiServiceProvider).getMe();
      final profile = AgentProfile.fromApi(json, cached: state);
      final agency = await _resolveAgency(profile);
      final resolved = profile.copyWith(agencySlug: agency?.slug);
      state = resolved;
      await _writeCache(resolved);
      if (agency != null) {
        await ref.read(agencyProvider.notifier).setAgency(agency);
      }
    } catch (e) {
      debugPrint('AgentProfile: refresh failed, keeping cache: $e');
    }
  }

  /// Records what the agent typed before the API answers — the API stores a
  /// single full name, and this keeps the first/last split they entered.
  Future<void> seed(AgentProfile profile) async {
    state = profile;
    await _writeCache(profile);
  }

  /// Saves [profile] to the API. Throws on failure; the caller maps the error
  /// (including field errors) for display.
  Future<void> save(AgentProfile profile) async {
    final json = await ref
        .read(agentApiServiceProvider)
        .updateMe(profile.toApiJson());
    final saved = AgentProfile.fromApi(
      json,
      cached: profile,
    ).copyWith(agencySlug: profile.agencySlug);
    state = saved;
    await _writeCache(saved);
    await ref.read(authProvider.notifier).updateDisplayName(saved.fullName);
  }

  /// Finds the agency matching the profile's agency name: the cached slug if
  /// it still fits, then a listed or previously added agency. An unknown name
  /// — e.g. one added on another device — is added here, without a logo, so
  /// it stays selectable.
  Future<Agency?> _resolveAgency(AgentProfile profile) async {
    final name = profile.agencyName.trim();
    if (name.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final custom = readCustomAgencies(prefs);

    final bySlug = profile.agencySlug == null
        ? null
        : Agency.fromSlug(profile.agencySlug, custom: custom);
    if (bySlug != null && bySlug.name == name) return bySlug;

    return Agency.matchName(name, custom: custom) ??
        await ref.read(customAgenciesProvider.notifier).add(name: name);
  }
}

final agentProfileProvider =
    NotifierProvider<AgentProfileNotifier, AgentProfile>(
      AgentProfileNotifier.new,
    );
