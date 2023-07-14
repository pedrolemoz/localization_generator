// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:change_case/change_case.dart';
import 'package:path/path.dart';

import 'localization_generator_exceptions.dart';

class LocalizationGenerator {
  final String _generatedClassName;
  final String _projectDirectory;
  final String _generatedFileDirectory;

  static final _interpolationRegExp = RegExp(r'%\w+\d*');

  const LocalizationGenerator({
    required String generatedClassName,
    required String projectDirectory,
    required String generatedFileDirectory,
  })  : _generatedFileDirectory = generatedFileDirectory,
        _projectDirectory = projectDirectory,
        _generatedClassName = generatedClassName;

  void generate() {
    final i18nDirectory = Directory(join(_projectDirectory, 'lib', 'i18n'));
    final content = _getBaseContent(i18nDirectory);
    final generatedClass = _generateClass(content);
    _writeToFile(generatedClass);
    _formatGeneratedFile();
  }

  Map<String, dynamic> _getBaseContent(Directory i18nDirectory) {
    final files = i18nDirectory.listSync();
    final jsonFiles =
        files.where((file) => file.path.split('.').last == 'json');
    if (jsonFiles.isEmpty) throw NoLocalizationFilesFoundException();
    final jsonContent = jsonFiles.map((file) => _parseFileAsJSON(file.path));
    final baseContent = jsonContent.first;
    final allFilesHaveTheSameKeys = jsonContent.skip(1).every((content) {
      return baseContent.keys.every(content.containsKey) &&
          content.keys.every(baseContent.containsKey);
    });
    if (!allFilesHaveTheSameKeys) {
      throw InconsistentLocalizationFilesException();
    }
    return baseContent;
  }

  Map<String, dynamic> parseJSON(String jsonPath) {
    final content = File(jsonPath).readAsStringSync();
    return json.decode(content);
  }

  String _generateClass(Map<String, dynamic> content) {
    final generatedClass = StringBuffer(
      "import 'package:localization/localization.dart';\n\nclass $_generatedClassName {\n  const $_generatedClassName._();\n\n",
    );

    for (final entry in content.entries) {
      final contentKey = entry.key;
      final camelCaseKey = contentKey.toCamelCase();

      final matches = _interpolationRegExp.allMatches(entry.value);
      final variables = <String>[];

      if (matches.isNotEmpty) {
        for (final arg in matches) {
          final variable = arg.group(0);
          if (variable != null) variables.add(variable);
        }
      }

      late final String line;

      if (variables.isEmpty) {
        line = "  static String get $camelCaseKey => '$contentKey'.i18n();\n";
      } else {
        final parsedArgs = variables.map((e) => e.replaceAll('%', ''));
        final functionArgs =
            parsedArgs.map((e) => 'String $e').reduce((a, b) => a += ', $b');
        final parameters = parsedArgs.reduce((a, b) => a += ', $b');

        line =
            "  static String $camelCaseKey($functionArgs) => '$contentKey'.i18n([$parameters]);\n";
      }

      generatedClass.write(line);
    }

    generatedClass.write('}\n');

    return generatedClass.toString();
  }

  Map<String, dynamic> _parseFileAsJSON(String filePath) {
    final content = File(filePath).readAsStringSync();
    return json.decode(content);
  }

  void _writeToFile(String generatedContent) {
    final path = _getGeneratedFilePath();
    final file = File(path);
    file.writeAsStringSync(generatedContent);
  }

  void _formatGeneratedFile() {
    final path = _getGeneratedFilePath();
    Process.run('dart', ['format', path]);
  }

  String _getGeneratedFilePath() {
    final fileName = _generatedClassName.toSnakeCase();
    final path = join(_generatedFileDirectory, '$fileName.dart');
    return path;
  }
}
