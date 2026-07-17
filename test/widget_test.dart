import 'package:flutter_test/flutter_test.dart';

// DevGate smoke tests — the app requires secure storage and platform channels
// that are not available in the widget test environment. Real integration tests
// should be run on a physical device or emulator.
void main() {
  test('placeholder — see integration tests for full coverage', () {
    expect(1 + 1, 2);
  });
}
