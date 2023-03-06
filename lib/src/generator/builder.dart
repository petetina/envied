library envied.builder;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generator.dart';

/// Primary builder to build the generated code from the `EnviedGenerator`
Builder enviedBuilder(BuilderOptions options) => SharedPartBuilder([EnviedGenerator()], 'envied');
