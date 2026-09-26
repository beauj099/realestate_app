/// Runs [tasks] with at most [width] in flight at once and returns their
/// results in the original order.
///
/// Saving sends many small requests (one per room, feature and photo); a few
/// at a time finishes several times faster than one after another, without
/// flooding a phone's connection or the API.
Future<List<T>> runLimited<T>(
  List<Future<T> Function()> tasks, {
  int width = 4,
}) async {
  final results = List<T?>.filled(tasks.length, null);
  var next = 0;
  Future<void> worker() async {
    while (next < tasks.length) {
      final i = next++;
      results[i] = await tasks[i]();
    }
  }

  await Future.wait([
    for (var w = 0; w < width && w < tasks.length; w++) worker(),
  ]);
  return results.cast<T>();
}
