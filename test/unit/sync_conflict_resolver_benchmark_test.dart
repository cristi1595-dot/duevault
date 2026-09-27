import 'package:flutter_test/flutter_test.dart';
import 'package:duevault_app/models/vault_item.dart';

void main() {
  test('Benchmark local items lookup', () {
    final cloudItems = List.generate(2000, (i) => VaultItem()..uuid = 'uuid_$i');
    final localItems = List.generate(2000, (i) => VaultItem()..uuid = 'uuid_${i + 1000}');

    final stopwatch = Stopwatch()..start();

    // Baseline O(N^2) simulation
    int matchCountBaseline = 0;
    for (var cloudItem in cloudItems) {
      final localItem = localItems.where((i) => i.uuid == cloudItem.uuid).firstOrNull;
      if (localItem != null) matchCountBaseline++;
    }
    final baselineMs = stopwatch.elapsedMilliseconds;

    stopwatch.reset();
    stopwatch.start();

    // Optimized O(N) map simulation
    final localItemMap = {for (var item in localItems) item.uuid: item};
    int matchCountOptimized = 0;
    for (var cloudItem in cloudItems) {
      final localItem = localItemMap[cloudItem.uuid];
      if (localItem != null) matchCountOptimized++;
    }
    final optimizedMs = stopwatch.elapsedMilliseconds;

    print('Baseline time: ${baselineMs}ms');
    print('Optimized time: ${optimizedMs}ms');
    expect(matchCountBaseline, equals(matchCountOptimized));
  });
}
