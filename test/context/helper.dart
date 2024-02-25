// A List of builders that are similar to the way TurfJs creates GeoJSON
// objects. The idea is to make it easier to port JavaScript tests to Dart.
import 'package:turf/turf.dart';

Feature<LineString> lineString(List<List<double>> coordinates, {dynamic id}) {
  return Feature(
    id: id,
    geometry: LineString(coordinates: positions(coordinates)),
  );
}

Point point(List<double> coordinates) {
  return Point(coordinates: Position.of(coordinates));
}

Position position(List<double> coordinates) {
  return Position.of(coordinates);
}

List<Position> positions(List<List<double>> coordinates) {
  return coordinates.map((e) => position(e)).toList(growable: false);
}

Feature<Polygon> polygon(List<List<List<double>>> coordinates) {
  return Feature(
    geometry: Polygon(
        coordinates: coordinates
            .map((element) => positions(element))
            .toList(growable: false)),
  );
}

FeatureCollection featureCollection<T extends GeometryObject>(
    [List<Feature<T>> features = const []]) {
  return FeatureCollection<T>(features: features);
}
