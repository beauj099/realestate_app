import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/models/agent_profile.dart';

/// Secure-storage key holding the agent's profile JSON.
const String _profileStorageKey = 'agent_profile';

/// Owns the signed-in agent's registration details.
///
/// Persists to secure storage rather than shared preferences because the
/// record carries an email, mobile number and FFC licence number. Swap the
/// read/write bodies for API calls once the backend exposes `/api/agents/me`.
class AgentProfileNotifier extends Notifier<AgentProfile> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  AgentProfile build() {
    load();
    return const AgentProfile();
  }

  Future<void> load() async {
    try {
      final raw = await _storage.read(key: _profileStorageKey);
      if (raw == null) return;
      state = AgentProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('AgentProfile: failed to load, using empty profile: $e');
    }
  }

  Future<void> save(AgentProfile profile) async {
    state = profile;
    try {
      await _storage.write(
        key: _profileStorageKey,
        value: jsonEncode(profile.toJson()),
      );
    } catch (e) {
      debugPrint('AgentProfile: failed to persist: $e');
    }
  }

  Future<void> clear() async {
    state = const AgentProfile();
    try {
      await _storage.delete(key: _profileStorageKey);
    } catch (e) {
      debugPrint('AgentProfile: failed to clear: $e');
    }
  }
}

final agentProfileProvider =
    NotifierProvider<AgentProfileNotifier, AgentProfile>(
      AgentProfileNotifier.new,
    );
