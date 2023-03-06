import 'dart:io' show File;

import 'parser.dart';

/// Load the environment variables from the supplied [path],
/// using the `dotenv` parser.
///
/// If file doesn't exist, an error will be thrown through the
/// [onError] function.
Future<Map<String, String>> loadEnvs(
  String path,
  String defaultPath,
  Function(String) onError,
) async {
  const parser = Parser();
  final file = File.fromUri(Uri.file(path));
  final defaultFile = File.fromUri(Uri.file(defaultPath));

  var lines = <String>[];
  if (await file.exists()) {
    print(file.path);
    lines = await file.readAsLines();
  } else if (await defaultFile.exists()) {
    print("Using default .env file");
    print(defaultFile.path);
    lines = await defaultFile.readAsLines();
  } else {
    onError("Environment variable file doesn't exist at `$path`.");
  }

  final envs = parser.parse(lines);
  return envs;
}
