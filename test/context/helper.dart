import 'dart:convert';
import 'dart:io';

import 'package:turf/helpers.dart';

void loadGeoJson(
    String path, void Function(String path, GeoJSONObject geoJson) test) {
  final file = File(path);
  final content = file.readAsStringSync();
  final geoJson = GeoJSONObject.fromJson(jsonDecode(content));
  test(file.path, geoJson);
}

void loadGeoJsonFiles(
  String path,
  void Function(String path, GeoJSONObject geoJson) test,
) {
  var testDirectory = Directory(path);

  for (var file in testDirectory.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.geojson')) {
      if (file.path.contains('skip')) continue;

      final content = file.readAsStringSync();
      final geoJson = GeoJSONObject.fromJson(jsonDecode(content));
      test(file.path, geoJson);
    }
  }
}

void loadTestCases(
  String basePath,
  void Function(
    String path,
    GeoJSONObject geoJsonGiven,
    GeoJSONObject geoJsonExpected,
  ) test,
) {
  var inDirectory = Directory("$basePath/in");
  var outDirectory = Directory("$basePath/out");

  if (!inDirectory.existsSync()) {
    throw Exception("directory ${inDirectory.path} not found");
  }
  if (!outDirectory.existsSync()) {
    throw Exception("directory ${outDirectory.path} not found");
  }

  final inFiles = inDirectory
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (file) =>
            file.path.endsWith('.geojson') &&
            file.path.contains('skip') == false,
      )
      .toList();

  for (var file in inFiles) {
    final outFile = File(file.path.replaceFirst('/in/', '/out/'));
    if (outFile.existsSync() == false) {
      throw Exception("file ${outFile.path} not found");
    }

    final geoJsonGiven = GeoJSONObject.fromJson(
      jsonDecode(file.readAsStringSync()),
    );

    final geoJsonExpected = GeoJSONObject.fromJson(
      jsonDecode(outFile.readAsStringSync()),
    );

    test(file.path, geoJsonGiven, geoJsonExpected);
  }
}

Feature<LineString> lineString(List<List<int>> coordinates, {dynamic id}) {
  return Feature(
    id: id,
    geometry: LineString(coordinates: coordinates.toPositions()),
  );
}

Point point(List<double> coordinates) {
  return Point(coordinates: Position.of(coordinates));
}

Feature<Polygon> polygon(List<List<List<int>>> coordinates) {
  return Feature(
    geometry: Polygon(coordinates: coordinates.toPositions()),
  );
}

extension PointsExtension on List<List<int>> {
  List<Position> toPositions() =>
      map((position) => Position.of(position)).toList(growable: false);
}

extension PolygonPointsExtensions on List<List<List<int>>> {
  List<List<Position>> toPositions() =>
      map((element) => element.toPositions()).toList(growable: false);
}
