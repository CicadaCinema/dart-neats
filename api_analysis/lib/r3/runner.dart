import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:async/async.dart';

import 'package:retry/retry.dart';
import 'package:tar/tar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Directory, IOException, gzip;

final _pubHostedUrl = Uri.parse('https://pub.dev/');

Future<PackageShape> analyzeHostedPackage(
    String packageName, String version) async {
  print('fetch $packageName version $version');
  final pkgUri = _pubHostedUrl.resolve(
    'packages/$packageName/versions/$version.tar.gz',
  );
  final pkgGzip = await retry(
    () => http.readBytes(pkgUri).timeout(Duration(seconds: 30)),
    retryIf: (e) => e is TimeoutException || e is IOException,
  );
  final pkgBytes = gzip.decode(pkgGzip);

  final fs = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);

  await TarReader.forEach(Stream.value(pkgBytes), (entry) async {
    if (entry.type == TypeFlag.reg) {
      fs.setOverlay(
        '/pkg/${entry.name}',
        content: utf8.decode(await collectBytes(entry.contents)),
        modificationStamp: 0,
      );
    }
  });
  fs.setOverlay(
    '/pkg/.dart_tool/package_config.json',
    content: json.encode({
      "configVersion": 2,
      "packages": [
        {
          "name": packageName,
          "rootUri": "/pkg",
          "packageUri": "lib/",
          "languageVersion": "3.0"
        }
      ],
      "generated": "2023-07-28T09:37:20.214485Z",
      "generator": "pub",
      "generatorVersion": "3.0.5"
    }),
    modificationStamp: 0,
  );

  final sw = Stopwatch()..start();
  final packagePath = '/pkg';
  final package = await analyzePackage(packagePath, fs: fs);
  print('analysis took: ${sw.elapsedMilliseconds} ms');
  print(package.toJsonSummary());
  return package;
}

