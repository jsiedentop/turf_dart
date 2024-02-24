import 'dart:convert';

import 'package:rbush/rbush.dart';
//import 'package:turf/bbox.dart';
import 'package:turf/boolean.dart';
//import 'package:turf/helpers.dart';
import 'package:turf/line_segment.dart';
import 'package:turf/meta.dart';
//import 'package:turf/nearest_point_on_line.dart';
import 'package:turf/turf.dart';
import 'package:turf_equality/turf_equality.dart';

import 'invariant.dart';

logFeature(String info, Feature? feature) => logJson(info, feature?.toJson());
logCollection(String info, FeatureCollection? feature) =>
    logJson(info, feature?.toJson());
logJson(String info, Map<String, dynamic>? json) {
  print(info);
  if (json == null) {
    print("(null)");
  } else {
    final jsonString = jsonEncode(json);
    final urlString =
        "http://geojson.io/#data=data:application/json,${Uri.encodeComponent(jsonString)}";
    print(urlString);
  }
  print(".\n");
}

bool _equal(List<Position> first, List<Position> second) {
  Equality eq = Equality();
  final result = eq.compare(
    LineString(coordinates: first),
    LineString(coordinates: second),
  );
  //final a = Feature(
  //  geometry: LineString(coordinates: first),
  //  properties: {"stroke": "#F00", "fill": "#F00", "stroke-width": "25"},
  // );
  // final b = Feature(geometry: LineString(coordinates: second));
  // final feature = FeatureCollection(features: [a, b]);
  // logCollection("equal == $result", feature);

  return result;
}

class FeatureRBush {
  FeatureRBush._(this._tree);
  final RBushBase<List<List<double>>> _tree;

  static FeatureRBush create(FeatureCollection<LineString> segments) {
    final tree = RBushBase<List<List<double>>>(
      maxEntries: 4,
      toBBox: (segment) => RBushBox.fromList(_bbox(segment)),
      getMinX: (segment) => RBushBox.fromList(_bbox(segment)).minX,
      getMinY: (segment) => RBushBox.fromList(_bbox(segment)).minY,
    );

    final line1Segments = segments.features.map((e) {
      final line = e.geometry as LineString;
      return line.coordinates
          .map((e) => [e.lng.toDouble(), e.lat.toDouble()])
          .toList();
    }).toList();

    tree.load(line1Segments);
    return FeatureRBush._(tree);
  }

  FeatureCollection<LineString> searchArea(Feature<LineString> segment) {
    final coordinates = segment.geometry!.coordinates
        .map((e) => [e.lng.toDouble(), e.lat.toDouble()])
        .toList();

    //final searchArea = RBushBox.fromList(_bbox(segment.geometry.coordinates));
    //final segment1 = <List<double>>[
    //  [115, -25],
    //  [125, -30]
    //];

    final searchArea = RBushBox.fromList(_bbox(coordinates));
    final result = _tree.search(searchArea);

    final features = result.map(
      (e) {
        final positions = e.map((e) => Position.of(e)).toList();
        final feature = Feature(geometry: LineString(coordinates: positions));
        return feature;
      },
    ).toList();

    final segmentsWithinSameBox = FeatureCollection<LineString>(
      features: features,
    );
    return segmentsWithinSameBox;
  }

  static List<double> _bbox(List<List<double>> coordinates) {
    var minX = double.infinity; // lat1
    var minY = double.infinity; // lng1
    var maxX = double.negativeInfinity; // lat2
    var maxY = double.negativeInfinity; // lng2

    for (List<double> coordinate in coordinates) {
      double x = coordinate[0];
      double y = coordinate[1];

      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }

    return [minX, minY, maxX, maxY];
  }
}

/// Takes any [LineString], [MultiLineString], [Polygon] or [MultiPolygon] and
/// returns the overlapping lines between both features.
/// [feature1] first feature
/// [feature2] second feature
/// [tolerance] tolerance distance to match overlapping line segments, default is 0
/// [unit] the unit in which the tolerance is expressed, default is kilometers
/// returns [FeatureCollection<LineString>] lines(s) that are overlapping between both features
///
/// Example
/// ```dart
/// final line1 = lineString([[115, -35], [125, -30], [135, -30], [145, -35]]);
/// final line2 = lineString([[115, -25], [125, -30], [135, -30], [145, -25]]);
/// final overlapping = lineOverlap(line1, line2);
/// ```
FeatureCollection<LineString> lineOverlap(
  Feature feature1,
  Feature feature2, {
  num tolerance = 0,
  Unit unit = Unit.kilometers,
}) {
  /*
  RBushBox toRBBox(Feature<LineString> feature) {
    // ToDo: only works if feature is a 2d line string of 4 coordinates
    // will not work, if the line string has altitude information.
    // final listOfCoordinates = box.toList();

    final box = bbox(feature);
    // minX,     minY,     maxX,     maxY
    final listOfCoordinates = [box.lat1, box.lng1, box.lat1, box.lng1];
    final rBushBox = RBushBox.fromList(listOfCoordinates);
    //final rBushBox = RBushBox.fromList(bbox(feature).toList());
    return rBushBox;
  }*/

  // Create Spatial Index
  /*final tree = RBushBase<Feature<LineString>>(
    maxEntries: 4,
    getMinX: (Feature<LineString> feature) {
      // final minX = bbox(feature).lng1.toDouble();
      final minX = toRBBox(feature).minX;
      return minX;
    },
    getMinY: (Feature<LineString> feature) {
      // final minY = bbox(feature).lat1.toDouble();
      final minY = toRBBox(feature).minY;
      return minY;
    },
    toBBox: toRBBox,
  );
  final line1Segements = lineSegment(line1);
  logCollection("line1 segments:", line1Segements);
  tree.load(line1Segements.features);
  */
  final tree = FeatureRBush.create(lineSegment(feature1));

  // Detect Line Intersection

  // Containers
  final features = <Feature<LineString>>[];

  //Feature<LineString>? result;

  logFeature("line1:", feature1);
  logFeature("line2:", feature2);

  // Iterate over segments of line2
  segmentEach(feature2, (Feature<LineString> segment, _, __, ___, ____) {
    //bool overlapping = false;

    //List<Feature<LineString>> deferredOverlappingSegments = [];
    final segmentCoords = getCoorsSorted(segment);
    final segmentLine = segment.geometry as LineString;

    logFeature("line2 segment:", segment);

    // detect segments of line1, that falls within the same
    // bonds of the current line2 segment
    // final segmentsWithinSameBox = FeatureCollection<LineString>(
    //  features: tree.search(toRBBox(segment)),
    //);
    final segmentsWithinSameBox = tree.searchArea(segment);
    logCollection("segmentsWithinSameBox:", segmentsWithinSameBox);
    featureEach(segmentsWithinSameBox, (Feature current, _) {
      final match = current as Feature<LineString>;
      final matchCoords = getCoorsSorted(match);
      final matchLine = match.geometry as LineString;

      logFeature("line1 match segment:", current);

      //print("segmentCoords:");
      //print(jsonEncode(segmentCoords.map((e) => e.toJson()).toList()));

      //print("matchCoords:");
      //print(jsonEncode(matchCoords.map((e) => e.toJson()).toList()));

      final isSubset = _equal(segmentCoords, matchCoords) ||
          positionsOnLine(segmentCoords, matchLine, tolerance, unit);

      // Is the outer line2 segment a subset of the line1 segment?
      if (isSubset) {
        // add the complete segment to the overlapping result

        //final combined = concatSegment(result, segment);
        //final segmentIsNotConnectedWithResult = combined == null;
        //if (segmentIsNotConnectedWithResult) {
        //  features.add(result!);
        //  result = segment;
        //} else {
        //  result = combined;
        //}
        final result = concatSegmentToFeatures(features, segment);
        logFeature("isSubset, result: ", result);

        // ToDo: we should be able to add the complete line1 segment to the result
        // and ignore the current value.
        // result = segment;
        //overlapping = true;

        // ToDo (Issue #901):
        // The segment is a subset but it could be, that the neither the
        // start nor the end point is the same. In this case the segment is
        // not concatenated to the result. This is a known issue.
        // assert(combined == null);

        // Add the complete line2 segment to the result and stop the loop.
        return false;
      }

      // The line2 segment is not a subset of line1 segment. Check if line1
      // segment is a subset of line2 segment.
      if (positionsOnLine(matchCoords, segmentLine, tolerance, unit)) {
        print("positionsOnLine");
        // Add the line1 segment to the overlapping result.
        //final combined = concatSegment(result, match);
        //final segmentIsNotConnectedWithResult = combined == null;
        //if (segmentIsNotConnectedWithResult) {
        //  print("combined == null, add deferred");
        // Current line1 segment is a subset of line2 segment, but it isn't
        // connected to the result via start or end point.
        // We're adding it later to the result.
        //  deferredOverlappingSegments.add(match);

        //features.add(result!);
        //result = segment;
        //} else {
        //  print("combined as result");
        //  result = combined;
        //}

        final result = concatSegmentToFeatures(features, match);
        logFeature("!overlapping, result: ", result);
      }
    });

    // Segment doesn't overlap - add overlaps to results & reset
    //if (overlapping == false && result != null) {
    //  features.add(result!);
    //  result = null;
    //
    //  if (deferredOverlappingSegments.isNotEmpty) {
    //    features.addAll(deferredOverlappingSegments);
    //    deferredOverlappingSegments = [];
    //  }
    //}
  });

  //if (result != null) {
  //  features.add(result!);
  //  result = null;
  //if (!overlapping) {
  //   features.addAll(deferredOverlappingSegments);
  //   deferredOverlappingSegments = [];
  // }
  //}

  // This seems wrong to me. If we are adding the result to the feature, when
  // overlapping is true, then doesn't need to add it here. Another point is,
  // that if we have an overlapping segment for line2 and then an not overlapping
  // segment, that means, that the overlapping segment is not added to the result.
  // Add last segment if exists
  //if (result != null) features.add(result!);

  return FeatureCollection(features: features);

  // ToDo: check if the false return really ends the loop,
  // if so, move this statement to the end. Maybe add a test for this.
  // featureEach
}

List<Position> getCoorsSorted(Feature feature) {
  int byPosition(Position a, Position b) {
    return a.lng < b.lng
        ? -1
        : a.lng > b.lng
            ? 1
            : 0;
  }

  final positions = getCoords(feature) as List<Position>;
  positions.sort(byPosition);
  return positions;
}

bool positionsOnLine(
  List<Position> coords,
  LineString line,
  num tolerance,
  Unit unit,
) {
  final firstPoint = Point(coordinates: coords[0]);
  final secondPoint = Point(coordinates: coords[1]);

  bool isPointOnLine(Point point, LineString line) {
    if (tolerance == 0) {
      return booleanPointOnLine(point, line);
    }
    final nearestPoint = nearestPointOnLine(line, point, unit);
    return nearestPoint.properties!['dist'] <= tolerance;
  }

  final firstPointOnLine = isPointOnLine(firstPoint, line);
  final secondPointOnLine = isPointOnLine(secondPoint, line);

  logCollection(
      "positions on line? first=$firstPointOnLine, second=$secondPointOnLine",
      FeatureCollection<GeometryObject>(features: [
        Feature<Point>(geometry: firstPoint),
        Feature<Point>(geometry: secondPoint),
        Feature<LineString>(geometry: line),
      ]));

  return firstPointOnLine && secondPointOnLine;
}

Feature<LineString> concatSegmentToFeatures(
  List<Feature<LineString>> result,
  Feature<LineString> segment,
) {
  for (var i = result.length - 1; i >= 0; i--) {
    final currentOverlap = result[i];
    final combined = concatSegment(currentOverlap, segment);
    final segmentsConnected = combined != null;
    if (segmentsConnected) {
      // ToDo: Check if this is necessary.
      result[i] = combined;
      return result[i];
    }
  }
  result.add(segment);
  return segment;
}

/// Concat Segment
/// Concatenates a line with multiple positions with a
/// 2-vertex line segment.
/// returns null, if line and segment are not connected.
/// otherwise the concatenated line.
// * @param {Feature<LineString>} segment 2-vertex LineString
//  * @returns {Feature<LineString>} concat lineString
Feature<LineString>? concatSegment(
  Feature<LineString>? line,
  Feature<LineString> segment,
) {
  if (line == null) return segment;

  final lineCoords = getCoords(line) as List<Position>;
  final segmentCoords = getCoords(segment) as List<Position>;
  assert(lineCoords.length >= 2, 'line must have at least two coordinates.');
  assert(segmentCoords.length == 2, 'segment must have two coordinates.');

  final lineStart = lineCoords.first;
  final lineEnd = lineCoords.last;
  final segmentStart = segmentCoords[0];
  final segmentEnd = segmentCoords[1];

  List<Position> linePositions =
      (line.geometry as LineString).clone().coordinates;

  if (segmentStart == lineStart) {
    linePositions.insert(0, segmentEnd);
  } else if (segmentEnd == lineStart) {
    linePositions.insert(0, segmentStart);
  } else if (segmentStart == lineEnd) {
    linePositions.add(segmentEnd);
  } else if (segmentEnd == lineEnd) {
    linePositions.add(segmentStart);
  } else {
    // If the overlap leaves the segment unchanged, return null so that this can be
    // identified.
    return null;
  }

  return Feature(geometry: LineString(coordinates: linePositions));
}
