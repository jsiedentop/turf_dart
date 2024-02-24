import 'package:rbush/rbush.dart';
import 'package:turf/bbox.dart';
import 'package:turf/extensions.dart';
import 'package:turf/line_overlap.dart';
//import 'package:turf/src/line_segment.dart';
import 'package:test/test.dart';
import 'package:turf/helpers.dart';
import 'package:turf/line_segment.dart';
import 'package:turf_equality/turf_equality.dart';

import '../context/helper.dart';

void main() {
  group('lineOverlap - partial lines', () {
    Equality eq = Equality();
    bool compare(GeoJSONObject actual, GeoJSONObject expected) {
      LineString toLineString(GeoJSONObject geoJson) =>
          geoJson is FeatureCollection
              ? geoJson.features.first.geometry as LineString
              : geoJson is Feature
                  ? geoJson.geometry as LineString
                  : geoJson is LineString
                      ? geoJson
                      : throw "bad usage";

      return eq.compare(toLineString(actual), toLineString(expected));
    }

    final line1 = lineString([
      [100, -30],
      [150, -30],
    ]);

    test('inner part', () {
      final line2 = lineString([
        [110, -30],
        [120, -30],
      ]);

      expect(compare(lineOverlap(line1, line2), line2), true);
      expect(compare(lineOverlap(line2, line1), line2), true);
    });

    test('start part', () {
      final line2 = lineString([
        [100, -30],
        [110, -30],
      ]);

      expect(compare(lineOverlap(line1, line2), line2), true);
      expect(compare(lineOverlap(line2, line1), line2), true);
    });

    test('two inner segments', () {
      final line2 = lineString([
        [110, -30],
        [120, -30],
        [130, -30],
      ]);

      expect(compare(lineOverlap(line1, line2), line2), true);
      expect(compare(lineOverlap(line2, line1), line2), true);
    });

    // Known bug: https://github.com/Turfjs/turf/issues/2580
    test('partial overlap', skip: true, () {
      final line2 = lineString([
        [90, -30],
        [110, -30],
      ]);

      expect(compare(lineOverlap(line1, line2), line2), true);
      expect(compare(lineOverlap(line2, line1), line2), true);
    });

    test('two separate inner segments', () {
      final line2 = lineString([
        [140, -30],
        [150, -30],
        [150, -20],
        [100, -20],
        [100, -30],
        [110, -30],
      ]);

      final expected = FeatureCollection(
        features: [
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

      expect(compare(lineOverlap(line1, line2), expected), true);
      expect(compare(lineOverlap(line2, line1), expected), true);
    });
  });

  group('lineOverlap', () {
    test('equal - line', () {
      Equality eq = Equality();

      final line1 = LineString(coordinates: [
        Position.of([125, -30]),
        Position.of([135, -30]),
      ]);

      final line2 = LineString(coordinates: [
        Position.of([115, -35]),
        Position.of([125, -30]),
      ]);

      final result = eq.compare(
        line1,
        line2,
      );
      expect(result, false);
    });

    test('rbush', () {
      RBushBox toRBBox(Feature<LineString> feature) {
        final box = RBushBox.fromList(bbox(feature).toList());
        return box;
      }

      // Create Spatial Index
      var tree = RBushBase<Feature<LineString>>(
        //maxEntries: 4,
        maxEntries: 10,
        getMinX: (Feature<LineString> feature) {
          final minX = bbox(feature).lng1.toDouble();
          return minX;
        },
        getMinY: (Feature<LineString> feature) {
          final minY = bbox(feature).lat1.toDouble();
          return minY;
        },

        toBBox: toRBBox,
      );

      final line1 = lineString([
        [115, -35],
        [125, -30],
        [135, -30],
        [145, -35]
      ]);
      final line1Segements = lineSegment(line1);
      tree.load(line1Segements.features);
    });

    loadTestCases("test/examples/line_overlap", (
      path,
      geoJsonGiven,
      geoJsonExpected,
    ) {
      final feature1 = (geoJsonGiven as FeatureCollection).features[0];
      final feature2 = geoJsonGiven.features[1];
      final expectedCollection = geoJsonExpected as FeatureCollection;

      // if there is an overlap, geoJsonExpected has 3 Features where the
      // first is the overlapping line. If there are only 2 features in the
      // collection, there is no overlap.
      final expected = expectedCollection.features.length == 2
          ? FeatureCollection()
          : FeatureCollection(
              features: expectedCollection.features
                  .sublist(0, expectedCollection.features.length - 2)
                  .map((e) => Feature(geometry: e.geometry as LineString))
                  .toList(),

              //[
              //  Feature(
              //    geometry:
              //        expectedCollection.features.first.geometry as LineString,
              //  ),
              //],
            );

      test(path, () {
        print(path);

        final tolerance = feature1.properties?['tolerance'] ?? 0.0;
        final result = lineOverlap(feature1, feature2, tolerance: tolerance);

        //ToDo: check if the result is the same, if feature2 and feature1 are swapped?

        print("actual:   ${result.coordAll().map((e) => e!.toJson())}");
        print("expected: ${expected.coordAll().map((e) => e!.toJson())}");
        print("actual:   ${result.toJson()}");
        print("expected: ${expected.toJson()}");
        logCollection("actual:  ", result);
        logCollection("expected:", expected);

        print(".");

        expect(result.toJson(), equals(expected.toJson()));

        //expect(lineOverlap(feature1, feature2),
        //geoJsonExpected.features[0].properties['lineOverlap'])
        // {type: FeatureCollection, features: [{type: Feature, geometry: {type: LineString, bbox: null, coordinates: [[125, -30], [135, -30], [145, -35]]}, properties: {}}], bbox: null}
        // {type: FeatureCollection, features: [{type: Feature, geometry: {type: LineString, bbox: null, coordinates: [[125, -30], [135, -30], [145, -35]]}, properties: {}}], bbox: null}
      });

      /*
      
      function colorize(features, color = "#F00", width = 25) {
  const results = [];
  featureEach(features, (feature) => {
    feature.properties = {
      stroke: color,
      fill: color,
      "stroke-width": width,
    };
    results.push(feature);
  });
  if (features.type === "Feature") return results[0];
  return featureCollection(results);
}

 */

/*
    for (const { filename, name, geojson } of fixtures) {
    const [source, target] = geojson.features;
    const shared = colorize(
      lineOverlap(source, target, geojson.properties),
      "#0F0"
    );
    const results = featureCollection(shared.features.concat([source, target]));

    if (process.env.RE GEN)
      writeJsonFileSync(directories.out + filename, results);
    t.deepEquals(results, loadJsonFileSync(directories.out + filename), name);
  }
  t.end();
*/
    });
  });
}
