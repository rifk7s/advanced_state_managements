import 'package:flutter_test/flutter_test.dart';

import 'package:global_state/global_state.dart';

void main() {
  test('can add a counter', () {
    final gs = GlobalState();
    expect(gs.counters.length, 0);
    gs.addCounter();
    expect(gs.counters.length, 1);
  });
}
