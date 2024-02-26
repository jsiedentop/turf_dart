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

      loadGeoJson(file.path, test);
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
