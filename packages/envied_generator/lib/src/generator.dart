import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:envied/envied.dart';
import 'package:envied_generator/src/generate_line.dart';
import 'package:envied_generator/src/generate_line_encrypted.dart';
import 'package:envied_generator/src/load_envs.dart';
import 'package:source_gen/source_gen.dart';

/// Generate code for classes annotated with the `@Envied()`.
///
/// Will throw an [InvalidGenerationSourceError] if the annotated
/// element is not a [classElement].
class EnviedGenerator extends GeneratorForAnnotation<EnviedMultiple> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    Element enviedEl = element;
    if (enviedEl is! ClassElement) {
      throw InvalidGenerationSourceError(
        '`@Envied` can only be used on classes.',
        element: enviedEl,
      );
    }

    var environmentsObject = annotation.read('environments').listValue;
    var environments = <Envied>[];
    if (environmentsObject.isNotEmpty) {
      print(environmentsObject);
      try {
        //var map = json.decode(environmentsString);
        for (var env in environmentsObject) {
          final config = Envied(
            path: env.getField('path')?.toStringValue(), //.literalValue as String?,
            requireEnvFile: env.getField('requireEnvFile')?.toBoolValue() ?? false,
            name: env.getField('name')?.toStringValue(),
            obfuscate: env.getField('obfuscate')?.toBoolValue() ?? false,
          );

          environments.add(config);
        }
      } on Exception {
        throw InvalidGenerationSourceError('Unable to parse environments parameter.');
      }
    } else {
      print("nulllllllll");
    }
    final enviedMultiple = EnviedMultiple(environments);

    var result = "";
    for (var env in enviedMultiple.environments) {
      final envs = await loadEnvs(env.path, (error) {
        if (env.requireEnvFile) {
          throw InvalidGenerationSourceError(
            error,
            element: enviedEl,
          );
        }
      });

      TypeChecker enviedFieldChecker = TypeChecker.fromRuntime(EnviedField);
      final lines = enviedEl.supertype?.element.fields.map((fieldEl) {
        if (enviedFieldChecker.hasAnnotationOf(fieldEl)) {
          DartObject? dartObject = enviedFieldChecker.firstAnnotationOf(fieldEl);
          ConstantReader reader = ConstantReader(dartObject);

          String varName = reader.read('varName').literalValue as String? ?? fieldEl.name;
          String? varValue;
          if (envs.containsKey(varName)) {
            varValue = envs[varName];
          } else if (Platform.environment.containsKey(varName)) {
            varValue = Platform.environment[varName];
          }
          final bool obfuscate = reader.read('obfuscate').literalValue as bool? ?? env.obfuscate;

          return (obfuscate ? generateLineEncrypted : generateLine)(
            fieldEl,
            varValue,
          );
        } else {
          return '';
        }
      });
      result += '''
    class _${env.name ?? enviedEl.name} {
      ${lines?.toList().join()}
    }
    ''';
    }

    return result;
  }
}
