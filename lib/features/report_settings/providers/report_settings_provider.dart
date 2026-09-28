import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/agent_profile_provider.dart';
import '../../property_overview/data/models/room_score.dart';
import '../data/models/report_settings.dart';

/// The signed-in agent's report defaults (calculator rates, room weights),
/// read from their profile. Also hands the room weights to [RoomScore], so
/// the suggested house score follows the agent's own weighting.
final reportSettingsProvider = Provider<ReportSettings>((ref) {
  final settings = ref.watch(
    agentProfileProvider.select((p) => p.reportSettings),
  );
  RoomScore.weights = settings.roomWeights;
  return settings;
});
