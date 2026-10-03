import 'area_details.dart';

/// The area buyers search for the property by, from Property24's homes for
/// sale nearest it: the Property24 suburb most of the closest ones (within
/// 2 km, nearer counting more) are listed under. Suburb names differ between
/// sources (the City's "Lynn's View" is mostly Property24's "Steynsrust"),
/// and a buyer searches Property24's. Else Property24's suburb matched to the
/// report's; null when there is neither.
String? suggestMarketingArea(ForSale? forSale) {
  if (forSale == null) return null;
  final near = [
    for (final l in forSale.listings)
      if (l.distanceM case final d? when d <= 2000)
        if ((l.suburb ?? '').trim().isNotEmpty) (d: d, suburb: l.suburb!),
  ]..sort((a, b) => a.d.compareTo(b.d));
  final votes = <String, double>{};
  final names = <String, String>{};
  for (final l in near.take(6)) {
    final key = l.suburb.trim().toLowerCase();
    names.putIfAbsent(key, () => l.suburb.trim());
    votes[key] = (votes[key] ?? 0) + 1 / (l.d + 100);
  }
  if (votes.isNotEmpty) {
    final best = votes.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return names[best.key];
  }
  final matched = forSale.suburbs.firstOrNull?.name.trim();
  return matched == null || matched.isEmpty ? null : matched;
}
