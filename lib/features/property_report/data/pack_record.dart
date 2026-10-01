import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../property_overview/data/models/property_state.dart';

/// When a listing's report pack was last made, and from what. Kept on the
/// phone, so the overview can say the pack is out of date once something it
/// shows has changed since.
class PackRecord {
  final DateTime madeAt;
  final String fingerprint;

  const PackRecord(this.madeAt, this.fingerprint);

  static String _key(int listingId) => 'pack-made:$listingId';

  static Future<PackRecord?> load(int listingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(listingId));
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return PackRecord(
        DateTime.parse(j['madeAt'] as String),
        j['fingerprint'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(int listingId, PropertyState listing) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(listingId),
        jsonEncode({
          'madeAt': DateTime.now().toIso8601String(),
          'fingerprint': packFingerprint(listing),
        }),
      );
    } catch (_) {
      // Only the "out of date" hint is lost.
    }
  }
}

/// Everything about the listing that the pack shows: the address, sizes,
/// rooms (with their condition, score, features, notes and flatlet layout),
/// outside, parking, owners and every figure on Price & Commission and
/// Purchase History. Photos count by number only: an upload turns a phone
/// path into a web address without changing the photo.
String packFingerprint(PropertyState s) => jsonEncode([
  s.streetNumber.trim(),
  s.street.trim(),
  s.unitNumber.trim(),
  s.suburb.trim(),
  s.city.trim(),
  s.estateName.trim(),
  s.erfNumber.trim(),
  s.erfSize.trim(),
  s.floorArea.trim(),
  s.constructionYear.trim(),
  s.propertyTypeId,
  s.zoningId,
  [
    for (final r in s.rooms)
      [
        r.name,
        r.conditionRating,
        r.score,
        r.notes.trim(),
        r.unit?.toJson(),
        [for (final f in r.features) f.description],
        r.photos.length,
      ],
  ],
  [
    for (final p in s.parking) [p.parkingTypeId, p.quantity],
  ],
  s.outdoorFeatures,
  s.exteriorPhotos.length,
  s.listingValuation.content,
  [
    for (final c in [s.primaryContact, ...s.coContacts])
      [c.title, c.fullName.trim(), c.companyName.trim()],
  ],
  s.houseScore,
]);

/// The pack record for a listing; refreshed after a pack is made.
final packRecordProvider = FutureProvider.autoDispose.family<PackRecord?, int>(
  (ref, listingId) => PackRecord.load(listingId),
);
