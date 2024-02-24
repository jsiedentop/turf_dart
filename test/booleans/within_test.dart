import 'package:test/test.dart';
import 'package:turf/helpers.dart';
import 'package:turf/src/booleans/boolean_helper.dart';
import 'package:turf/src/booleans/boolean_within.dart';
import '../context/helper.dart';

void main() {
  group('within - true', () {
    loadGeoJsonFiles('./test/examples/booleans/within/true', (path, geoJson) {
      final feature1 = (geoJson as FeatureCollection).features[0];
      final feature2 = geoJson.features[1];
      test(path, () => expect(booleanWithin(feature1, feature2), true));
    });
  });

  group('within - false', () {
    loadGeoJsonFiles('./test/examples/booleans/within/false', (path, geoJson) {
      final feature1 = (geoJson as FeatureCollection).features[0];
      final feature2 = geoJson.features[1];
      test(path, () => expect(booleanWithin(feature1, feature2), false));
    });
  });

  group('within', () {
    loadGeoJson(
        './test/examples/booleans/within/true/MultiPolygon/MultiPolygon/skip-multipolygon-within-multipolygon.geojson',
        (path, geoJson) {
      final feature1 = (geoJson as FeatureCollection).features[0];
      final feature2 = geoJson.features[1];

      test(
        'FeatureNotSupported',
        () => expect(
          () => booleanWithin(feature1, feature2),
          throwsA(isA<FeatureNotSupported>()),
        ),
      );
    });

    test('within - point in multipoligon with hole', () {
      loadGeoJson(
          './test/examples/booleans/point_in_polygon/in/multipoly-with-hole.geojson',
          (path, geoJson) {
        final multiPolygon = (geoJson as Feature);
        final pointInHole = point([-86.69208526611328, 36.20373274711739]);
        var pointInPolygon = point([-86.72229766845702, 36.20258997094334]);
        var pointInSecondPolygon =
            point([-86.75079345703125, 36.18527313913089]);

        expect(booleanWithin(pointInHole, multiPolygon), false,
            reason: "point in hole");
        expect(booleanWithin(pointInPolygon, multiPolygon), true,
            reason: "point in polygon");
        expect(booleanWithin(pointInSecondPolygon, multiPolygon), true,
            reason: "point outside polygon");
      });
    });

    test("within - point in polygon", () {
      var simplePolygon = polygon([
        [
          [0, 0],
          [0, 100],
          [100, 100],
          [100, 0],
          [0, 0],
        ],
      ]);
      var pointIn = point([50, 50]);
      var pointOut = point([140, 150]);

      expect(booleanWithin(pointIn, simplePolygon), true,
          reason: "point inside polygon");
      expect(booleanWithin(pointOut, simplePolygon), false,
          reason: "point outside polygon");

      var concavePolygon = polygon([
        [
          [0, 0],
          [50, 50],
          [0, 100],
          [100, 100],
          [100, 0],
          [0, 0],
        ],
      ]);

      var pointInConcave = point([75, 75]);
      var pointOutConcave = point([25, 50]);

      expect(booleanWithin(pointInConcave, concavePolygon), true,
          reason: "point inside concave polygon");
      expect(booleanWithin(pointOutConcave, concavePolygon), false,
          reason: "point outside concave polygon");
    });
  });
}
