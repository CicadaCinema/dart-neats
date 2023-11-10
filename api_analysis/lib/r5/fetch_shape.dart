import 'dart:convert';
import 'dart:io';

import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:api_analysis/common.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

import '../pubapi.dart';
import 'analyze.dart';
import 'shapes.dart';

/// Returns the shape of a given package version.
///
/// The a cache is used where possible to save/load shapes.
Future<PackageShape> fetchShape({
  required String name,
  required Version version,
  required String cachePath,
}) async {
  final shapeCacheFile = File(path.join(cachePath, '$name-$version.json'));

  // Check if this shape is already cached.
  if (await shapeCacheFile.exists()) {
    return PackageShape.fromJson(
      json.decode(
        await shapeCacheFile.readAsString(),
      ),
    );
  }

  // Download the package from pub into memory.
  final packagePath = '/tempPackagePath';
  final fs = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);

  await PubApi.withApi((api) async {
    final info = await api.listVersions(name);
    final pv = info.versions.singleWhere((v) => v.version == version);
    assert(pv.pubspec.dart3Compatible);

    final files = await api.fetchPackage(pv.archiveUrl);
    for (final f in files) {
      fs.setOverlay(
        path.join(packagePath, f.path),
        content: utf8.decode(f.bytes, allowMalformed: true),
        modificationStamp: 0,
      );
    }
    final lv = pv.pubspec.languageVersion;
    fs.setOverlay(
      path.join(packagePath, '.dart_tool', 'package_config.json'),
      content: json.encode({
        'configVersion': 2,
        'packages': [
          {
            'name': pv.pubspec.name,
            'rootUri': packagePath,
            'packageUri': 'lib/',
            'languageVersion': '${lv.major}.${lv.minor}'
          }
        ],
        'generated': DateTime.now().toUtc().toIso8601String(),
        'generator': 'pub',
        'generatorVersion': '3.0.5'
      }),
      modificationStamp: 0,
    );
  });
  final packageShape = await analyzePackage(packagePath, fs: fs);

  // Cache the shape.
  await shapeCacheFile.writeAsString(
    json.encode(
      packageShape.toJson(),
    ),
  );

  return packageShape;
}

/// Returns the path to the shape cache directory, which is guaranteed to exist.
String shapeCache() {
  final shapeCachePath = path.join(systemCache(), 'shapes');
  Directory(shapeCachePath).createSync(recursive: true);
  return shapeCachePath;
}

String systemCache() {
  // Implementation copied from pub.
  // https://github.com/dart-lang/pub/blob/1779628b386819675130f14326f1e8812901c48f/lib/src/system_cache.dart#L42-L67

  if (Platform.environment.containsKey('PUB_CACHE')) {
    return Platform.environment['PUB_CACHE']!;
  } else if (Platform.isWindows) {
    // %LOCALAPPDATA% is used as the cache location over %APPDATA%, because
    // the latter is synchronised between devices when the user roams between
    // them, whereas the former is not.
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null) {
      throw StateError('''
Could not find the pub cache. No `LOCALAPPDATA` environment variable exists.
Consider setting the `PUB_CACHE` variable manually.
''');
    }
    return path.join(localAppData, 'Pub', 'Cache');
  } else {
    final home = Platform.environment['HOME'];
    if (home == null) {
      throw StateError('''
Could not find the pub cache. No `HOME` environment variable exists.
Consider setting the `PUB_CACHE` variable manually.
''');
    }
    return path.join(home, '.pub-cache');
  }
}
