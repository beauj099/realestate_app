import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/network/run_limited.dart';

void main() {
  test(
    'returns results in task order, never more than width at once',
    () async {
      var running = 0;
      var peak = 0;
      final results = await runLimited(width: 3, [
        for (var i = 0; i < 10; i++)
          () async {
            running++;
            if (running > peak) peak = running;
            // Later tasks finish first, so order has to be restored.
            await Future<void>.delayed(Duration(milliseconds: 20 - i));
            running--;
            return i;
          },
      ]);
      expect(results, List.generate(10, (i) => i));
      expect(peak, 3);
    },
  );

  test('handles no tasks', () async {
    expect(await runLimited<int>([]), isEmpty);
  });
}
