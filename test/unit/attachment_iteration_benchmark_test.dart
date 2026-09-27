// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Benchmark baseline vs optimized attachment lookup performance', () {
    // Construct old item attached files (200 files)
    final oldAttachedFiles = List.generate(
      200,
      (i) => 'C:\\Users\\Test\\Documents\\attachments\\doc_1000$i.pdf',
    );
    final oldCloudIds = List.generate(200, (i) => 'cloud_id_$i');
    final oldChecksums = List.generate(200, (i) => 'checksum_$i');

    // Construct new item attached files (150 files: 100 kept, 50 new)
    final newAttachedFiles = [
      ...List.generate(
        100,
        (i) => '/var/mobile/containers/data/doc_1000${i * 2}.pdf',
      ),
      ...List.generate(
        50,
        (i) => '/var/mobile/containers/data/new_doc_$i.pdf',
      ),
    ];

    const iterations = 500;

    // Baseline
    final swBaseline = Stopwatch()..start();
    List<String> baselineRemovedFiles = [];
    List<String> baselineNewCloudIds = [];
    List<String> baselineNewChecksums = [];

    for (int it = 0; it < iterations; it++) {
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
        final oldFileName =
            p.basename(oldAttachedFiles[i].replaceAll('\\', '/'));
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

      if (it == iterations - 1) {
        baselineRemovedFiles = removedFiles;
        baselineNewCloudIds = newCloudIds;
        baselineNewChecksums = newChecksums;
      }
    }
    swBaseline.stop();

    // Optimized
    final swOptimized = Stopwatch()..start();
    List<String> optimizedRemovedFiles = [];
    List<String> optimizedNewCloudIds = [];
    List<String> optimizedNewChecksums = [];

    for (int it = 0; it < iterations; it++) {
      final List<String> removedFiles = [];
      final List<String> removedCloudIds = [];

      final updatedFileNames = newAttachedFiles
          .map((newPath) => p.basename(newPath.replaceAll('\\', '/')))
          .toSet();

      for (int i = 0; i < oldAttachedFiles.length; i++) {
        final oldPath = oldAttachedFiles[i];
        final oldFileName = p.basename(oldPath.replaceAll('\\', '/'));

        final stillExists = updatedFileNames.contains(oldFileName);

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
        final oldFileName =
            p.basename(oldAttachedFiles[i].replaceAll('\\', '/'));
        final stillExists = updatedFileNames.contains(oldFileName);
        if (stillExists) {
          if (i < oldCloudIds.length) {
            newCloudIds.add(oldCloudIds[i]);
          }
          if (i < oldChecksums.length) {
            newChecksums.add(oldChecksums[i]);
          }
        }
      }

      if (it == iterations - 1) {
        optimizedRemovedFiles = removedFiles;
        optimizedNewCloudIds = newCloudIds;
        optimizedNewChecksums = newChecksums;
      }
    }
    swOptimized.stop();

    // Verify output parity
    expect(optimizedRemovedFiles, equals(baselineRemovedFiles));
    expect(optimizedNewCloudIds, equals(baselineNewCloudIds));
    expect(optimizedNewChecksums, equals(baselineNewChecksums));

    print(
      'Baseline execution time ($iterations iterations): ${swBaseline.elapsedMilliseconds} ms',
    );
    print(
      'Optimized execution time ($iterations iterations): ${swOptimized.elapsedMilliseconds} ms',
    );
    final speedup =
        swBaseline.elapsedMilliseconds /
        (swOptimized.elapsedMilliseconds > 0
            ? swOptimized.elapsedMilliseconds
            : 1);
    print('Speedup factor: ${speedup.toStringAsFixed(1)}x');
  });
}
