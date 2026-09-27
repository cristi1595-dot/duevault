// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Benchmark old vs new attachment alignment logic', () {
    const int count = 1000;
    final List<String> oldAttachedFiles = List.generate(
      count,
      (i) => 'C:\\Users\\Test\\Documents\\file_$i.pdf',
    );
    // Keep 500 files, remove 500 files, add 500 new files
    final List<String> newAttachedFiles = [
      ...List.generate(
        500,
        (i) => '/var/mobile/Containers/Data/Application/file_$i.pdf',
      ),
      ...List.generate(
        500,
        (i) => '/var/mobile/Containers/Data/Application/new_file_$i.pdf',
      ),
    ];
    final List<String> oldCloudIds = List.generate(count, (i) => 'cloud_id_$i');
    final List<String> oldChecksums = List.generate(count, (i) => 'checksum_$i');

    const iterations = 50;

    // Baseline implementation
    final stopwatchOld = Stopwatch()..start();
    for (int iter = 0; iter < iterations; iter++) {
      final List<String> removedFiles = [];
      final List<String> removedCloudIds = [];

      for (int i = 0; i < oldAttachedFiles.length; i++) {
        final oldPath = oldAttachedFiles[i];
        final oldFileName = p.basename(oldPath.replaceAll('\\', '/'));

        final stillExists = newAttachedFiles.any((newPath) =>
            p.basename(newPath.replaceAll('\\', '/')) == oldFileName);

        if (!stillExists) {
          removedFiles.add(oldFileName);
          if (i < oldCloudIds.length) {
            removedCloudIds.add(oldCloudIds[i]);
          }
        }
      }

      final List<String> newCloudIds = [];
      final List<String> newChecksums = [];
      for (int i = 0; i < oldAttachedFiles.length; i++) {
        final oldFileName = p.basename(oldAttachedFiles[i].replaceAll('\\', '/'));
        final stillExists = newAttachedFiles.any((newPath) =>
            p.basename(newPath.replaceAll('\\', '/')) == oldFileName);
        if (stillExists) {
          if (i < oldCloudIds.length) {
            newCloudIds.add(oldCloudIds[i]);
          }
          if (i < oldChecksums.length) {
            newChecksums.add(oldChecksums[i]);
          }
        }
      }
    }
    stopwatchOld.stop();
    final baselineUs = stopwatchOld.elapsedMicroseconds;

    // Optimized implementation
    final stopwatchNew = Stopwatch()..start();
    for (int iter = 0; iter < iterations; iter++) {
      final Set<String> newFileNames = newAttachedFiles
          .map((newPath) => p.basename(newPath.replaceAll('\\', '/')))
          .toSet();

      final List<String> removedFiles = [];
      final List<String> removedCloudIds = [];

      for (int i = 0; i < oldAttachedFiles.length; i++) {
        final oldPath = oldAttachedFiles[i];
        final oldFileName = p.basename(oldPath.replaceAll('\\', '/'));

        final stillExists = newFileNames.contains(oldFileName);

        if (!stillExists) {
          removedFiles.add(oldFileName);
          if (i < oldCloudIds.length) {
            removedCloudIds.add(oldCloudIds[i]);
          }
        }
      }

      final List<String> newCloudIds = [];
      final List<String> newChecksums = [];
      for (int i = 0; i < oldAttachedFiles.length; i++) {
        final oldFileName = p.basename(oldAttachedFiles[i].replaceAll('\\', '/'));
        final stillExists = newFileNames.contains(oldFileName);
        if (stillExists) {
          if (i < oldCloudIds.length) {
            newCloudIds.add(oldCloudIds[i]);
          }
          if (i < oldChecksums.length) {
            newChecksums.add(oldChecksums[i]);
          }
        }
      }
    }
    stopwatchNew.stop();
    final optimizedUs = stopwatchNew.elapsedMicroseconds;

    final speedup = baselineUs / (optimizedUs == 0 ? 1 : optimizedUs);
    print('Baseline execution time: ${baselineUs / 1000} ms');
    print('Optimized execution time: ${optimizedUs / 1000} ms');
    print('Speedup factor: ${speedup.toStringAsFixed(2)}x');
  });
}
