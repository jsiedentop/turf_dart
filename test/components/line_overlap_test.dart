import 'package:turf/line_overlap.dart';
import 'package:test/test.dart';
import 'package:turf/helpers.dart';

import '../context/helper.dart';
import '../context/load_test_cases.dart';
import '../context/matcher.dart' as geo;

void main() {
  group('lineOverlap - partial lines', () {
    final first = lineString([
      [100, -30],
      [150, -30],
    ]);

    test('inner part', () {
      final second = lineString([
        [110, -30],
        [120, -30],
      ]);
      final expected = featureCollection([second]);

      expect(lineOverlap(first, second), geo.equals(expected));
      expect(lineOverlap(second, first), geo.equals(expected));
    });

    test('start part', () {
      final second = lineString([
        [100, -30],
        [110, -30],
      ]);
      final expected = featureCollection([second]);

      expect(lineOverlap(first, second), geo.equals(expected));
      expect(lineOverlap(second, first), geo.equals(expected));
    });

    test('two inner segments', () {
      final second = lineString([
        [110, -30],
        [120, -30],
        [130, -30],
      ]);
      final expected = featureCollection([second]);

      expect(lineOverlap(first, second), geo.equals(expected));
      expect(lineOverlap(second, first), geo.equals(expected));
    });

    test('multiple segments on the same line', () {
      final first = lineString([
        [0, 1],
        [1, 1],
        [1, 0],
        [2, 0],
        [2, 1],
        [3, 1],
        [3, 0],
        [4, 0],
        [4, 1],
        [4, 0],
      ]);
      final second = lineString([
        [0, 0],
        [6, 0],
      ]);

      final expected = featureCollection([
        lineString([
          [1, 0],
          [2, 0]
        ]),
        lineString([
          [3, 0],
          [4, 0]
        ]),
      ]);

      expect(lineOverlap(first, second), geo.equals(expected));
      expect(lineOverlap(second, first), geo.equals(expected));
    });

    test('partial overlap', () {
      // bug: https://github.com/Turfjs/turf/issues/2580
      final second = lineString([
        [90, -30],
        [110, -30],
      ]);

      final expected = featureCollection([
        lineString([
          [100, -30],
          [110, -30],
        ])
      ]);

      expect(lineOverlap(first, second), geo.equals(expected));
      expect(lineOverlap(second, first), geo.equals(expected));
    });

    test('two separate inner segments', () {
      final second = lineString([
        [140, -30],
        [150, -30],
        [150, -20],
        [100, -20],
        [100, -30],
        [110, -30],
      ]);

      final expected = featureCollection(
        [
          lineString([
            [140, -30],
            [150, -30]
          ]),
          lineString([
            [100, -30],
            [110, -30]
          ]),
        ],
      );

      expect(lineOverlap(first, second), geo.equals(expected));
      expect(lineOverlap(second, first), geo.equals(expected));
    });
  });

  group('lineOverlap', () {
    loadTestCases("test/examples/line_overlap", (
      path,
      geoJsonGiven,
      geoJsonExpected,
    ) {
      final first = (geoJsonGiven as FeatureCollection).features[0];
      final second = geoJsonGiven.features[1];
      final expectedCollection = geoJsonExpected as FeatureCollection;

      // if there is an overlap, geoJsonExpected has 3 Features where the
      // first is the overlapping line. If there are only 2 features in the
      // collection, there is no overlap.
      final expected = expectedCollection.features.length == 2
          ? featureCollection()
          : featureCollection(
              expectedCollection.features
                  .sublist(0, expectedCollection.features.length - 2)
                  .map((e) => Feature(geometry: e.geometry as LineString))
                  .toList(),
            );
      test(path, () {
        print(path);
        final tolerance = first.properties?['tolerance'] ?? 0.0;
        final result = lineOverlap(first, second, tolerance: tolerance);
        expect(result, geo.equals(expected));
      });
    });
  });
}
