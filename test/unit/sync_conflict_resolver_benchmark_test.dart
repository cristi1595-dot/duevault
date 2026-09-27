import 'package:flutter_test/flutter_test.dart';
import 'package:duevault_app/models/vault_item.dart';

void main() {
  test('Benchmark O(N*M) vs O(N+M) Set check in SyncConflictResolver logic', () {
    const int itemCount = 5000;

    final cloudItems = List.generate(
      itemCount,
      (i) => VaultItem()..uuid = 'uuid-cloud-$i',
    );

    final localItems = List.generate(
      itemCount,
      (i) => VaultItem()..uuid = 'uuid-local-$i',
    );

    // Make 50% overlap
    for (int i = 0; i < itemCount ~/ 2; i++) {
      localItems[i].uuid = cloudItems[i].uuid;
    }

    // Measure O(N^2) / O(N*M) method (Current Code)
    final stopwatchLinear = Stopwatch()..start();
    int countLinear = 0;
    for (var localItem in localItems) {
      final existsInCloud = cloudItems.any((i) => i.uuid == localItem.uuid);
      if (existsInCloud) {
        countLinear++;
      }
    }
    stopwatchLinear.stop();

    // Measure O(N+M) method (Set approach)
    final stopwatchSet = Stopwatch()..start();
    int countSet = 0;
    final cloudUuids = cloudItems.map((i) => i.uuid).toSet();
    for (var localItem in localItems) {
      final existsInCloud = cloudUuids.contains(localItem.uuid);
      if (existsInCloud) {
        countSet++;
      }
    }
    stopwatchSet.stop();

    expect(countLinear, equals(countSet));

    print('--- BENCHMARK RESULTS ---');
    print('Item count (N=M): $itemCount');
    print('Baseline O(N*M) linear scan time: ${stopwatchLinear.elapsedMilliseconds} ms (${stopwatchLinear.elapsedMicroseconds} µs)');
    print('Optimized O(N+M) Set contains time: ${stopwatchSet.elapsedMilliseconds} ms (${stopwatchSet.elapsedMicroseconds} µs)');
    if (stopwatchSet.elapsedMicroseconds > 0) {
      final speedup = stopwatchLinear.elapsedMicroseconds / stopwatchSet.elapsedMicroseconds;
      print('Speedup factor: ${speedup.toStringAsFixed(2)}x faster');
    }
    print('-------------------------');
  });
}
