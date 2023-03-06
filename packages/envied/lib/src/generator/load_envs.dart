import 'dart:io' show File;

import 'parser.dart';

/// Load the environment variables from the supplied [path],
/// using the `dotenv` parser.
///
/// If file doesn't exist, an error will be thrown through the
/// [onError] function.
Future<Map<String, String>> loadEnvs(
  String name,
  String path,
  String defaultPath,
  Function(String) onError,
) async {
  const parser = Parser();
  final file = File.fromUri(Uri.file(path));
  final defaultFile = File.fromUri(Uri.file(defaultPath));

  var lines = <String>[];
  print("Reading $name env file.");
  if (await file.exists()) {
    lines = await file.readAsLines();
    print("Reading ${file.path} file successfully.");
  } else if (await defaultFile.exists()) {
    print("Using default .env file.");
    lines = await defaultFile.readAsLines();
    print("Reading ${defaultFile.path} file successfully.");
  } else {
    onError("Environment variable file doesn't exist at `$path`.");
  }

  final envs = parser.parse(lines);
  return envs;
}
