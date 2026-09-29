import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/network/platform_config_io.dart';

void main() {
  test('only local and private addresses count as dev hosts', () {
    for (final host in [
      'localhost',
      '127.0.0.1',
      '10.0.2.2',
      '192.168.1.20',
      '172.20.0.5',
      '10.1.2.3',
    ]) {
      expect(isDevHost(host), isTrue, reason: host);
    }
    for (final host in [
      'api.realworth.co.za',
      '172.32.0.1',
      '8.8.8.8',
      'evil.192.168.1.1.example.com',
    ]) {
      expect(isDevHost(host), isFalse, reason: host);
    }
  });
}
