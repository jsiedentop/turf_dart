//Compares two geometries of the same dimension and returns true if their intersection set results in a geometry
//different from both but of the same dimension. It applies to Polygon/Polygon, LineString/LineString,
//Multipoint/Multipoint, MultiLineString/MultiLineString and MultiPolygon/MultiPolygon.
//
// In other words, it returns true if the two geometries overlap, provided that neither completely contains the other.
//
// @name booleanOverlap
// @param  {Geometry|Feature<LineString|MultiLineString|Polygon|MultiPolygon>} feature1 input
// @param  {Geometry|Feature<LineString|MultiLineString|Polygon|MultiPolygon>} feature2 input
// @returns {boolean} true/false
// @example
// var poly1 = turf.polygon([[[0,0],[0,5],[5,5],[5,0],[0,0]]]);
// var poly2 = turf.polygon([[[1,1],[1,6],[6,6],[6,1],[1,1]]]);
// var poly3 = turf.polygon([[[10,10],[10,15],[15,15],[15,10],[10,10]]]);
//
// turf.booleanOverlap(poly1, poly2)
// //=true
// turf.booleanOverlap(poly2, poly3)
// //=false

import 'package:turf/helpers.dart';
import 'package:turf/line_overlap.dart';
import 'package:turf/line_segment.dart';
import 'package:turf/src/invariant.dart';

import 'boolean_helper.dart';

bool booleanOverlap(
  GeoJSONObject feature1,
  GeoJSONObject feature2,
) {
  var geom1 = getGeom(feature1);
  var geom2 = getGeom(feature2);

  // features must be not equal
  // const equality = new GeojsonEquality({ precision: 6 });
  // if (equality.compare(feature1 as any, feature2 as any)) return false;
  //throw new Error("features must be of the same type");

  switch (geom1.runtimeType) {
    case Point:
      throw FeatureNotSupported(geom1, geom2);
    case MultiPoint:
      switch (geom2.runtimeType) {
        case MultiPoint:
          return isMultiPointOverlapping(
            geom1 as MultiPoint,
            geom2 as MultiPoint,
          );
        default:
          throw FeatureNotSupported(geom1, geom2);
      }
    case LineString:
      switch (geom2.runtimeType) {
        case LineString:
        case MultiLineString:
          return isLineStringOverlapping(
            geom1 as LineString,
            geom2 as LineString,
          );
        default:
          throw FeatureNotSupported(geom1, geom2);
      }
    case MultiLineString:
      switch (geom2.runtimeType) {
        case LineString:
        case MultiLineString:
          return isLineStringOverlapping(
            geom1 as LineString,
            geom2 as LineString,
          );
        default:
          throw FeatureNotSupported(geom1, geom2);
      }
    case Polygon:
      final polygon = geom1 as Polygon;
      switch (geom2.runtimeType) {
        case Polygon:
        case MultiPolygon:
          return isPolygonOverlapping(polygon, geom2 as Polygon);
        default:
          throw FeatureNotSupported(geom1, geom2);
      }
    case MultiPolygon:
      switch (geom2.runtimeType) {
        case Polygon:
        case MultiPolygon:
        //return isMultiPolygonInPolygon(geom1 as MultiPolygon, geom2 as Polygon);
        default:
          throw FeatureNotSupported(geom1, geom2);
      }
    default:
      throw FeatureNotSupported(geom1, geom2);
  }
}

bool isMultiPointOverlapping(MultiPoint points1, MultiPoint points2) {
  //return points1.coordinates.every(
  //  (point1) => points2.coordinates.any(
  //    (point2) => point1 == point2,
  //  ),
  //);
  /*
  for (var i = 0; i < (geom1 as MultiPoint).coordinates.length; i++) {
        for (var j = 0; j < (geom2 as MultiPoint).coordinates.length; j++) {
          var coord1 = geom1.coordinates[i];
          var coord2 = geom2.coordinates[j];
          if (coord1[0] === coord2[0] && coord1[1] === coord2[1]) {
            return true;
          }
        }
      }
      return false;
       */
  throw UnimplementedError();
}

bool isLineStringOverlapping(LineString line1, LineString line2) {
  segmentEach(
    line1,
    (segment1, _, __, ___, ____) {
      segmentEach(
        line2,
        (segment2, _, __, ___, ____) {
          if (lineOverlap(segment1, segment2).features.isNotEmpty) {
            return true;
          }
        },
      );
    },
  );
  return false;
}

bool isPolygonOverlapping(Polygon polygon1, Polygon polygon2) {
  segmentEach(
    polygon1,
    (segment1, _, __, ___, ____) {
      segmentEach(
        polygon2,
        (segment2, _, __, ___, ____) {
          //if (lineIntersect(segment1, segment2).features.length) {
          return true;
          //}
        },
      );
    },
  );
  throw UnimplementedError();
}
