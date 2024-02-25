import 'package:test/test.dart';
import 'package:turf/src/geojson.dart';
import 'package:turf_equality/turf_equality.dart';

Matcher equals<T extends GeoJSONObject>(T? expected) => _Equals<T>(expected);

class _Equals<T extends GeoJSONObject> extends Matcher {
  _Equals(this.expected);
  final T? expected;

  @override
  Description describe(Description description) {
    return description.add('is equal');
  }

  @override
  bool matches(actual, Map matchState) {
    if (actual is! GeoJSONObject) return false;

    Equality eq = Equality();
    return eq.compare(actual, expected);
  }
}

Matcher length<T extends GeoJSONObject>(int length) => _Length<T>(length);

class _Length<T extends GeoJSONObject> extends Matcher {
  _Length(this.length);
  final int length;

  @override
  Description describe(Description description) {
    return description.add('length is $length');
  }

  @override
  bool matches(actual, Map matchState) {
    switch (actual.runtimeType) {
      case FeatureCollection:
        return (actual as FeatureCollection).features.length == length;
      case GeometryCollection:
        return (actual as GeometryCollection).geometries.length == length;
      case MultiPoint:
        return (actual as MultiPoint).coordinates.length == length;
      case MultiPolygon:
        return (actual as MultiPolygon).coordinates.length == length;
      case MultiLineString:
        return (actual as MultiLineString).coordinates.length == length;
      default:
        return false;
    }
  }
}
