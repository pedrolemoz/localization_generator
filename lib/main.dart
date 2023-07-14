import 'localization_generator.dart';
import 'localization_generator_exceptions.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    throw NoArgumentsException();
  }

  final generatedClassName = args.elementAtOrNull(0);
  final projectDirectory = args.elementAtOrNull(1);
  final generatedFileDirectory = args.elementAtOrNull(2);

  if (generatedClassName == null) {
    throw NoClassNameSpecifiedException();
  }

  if (projectDirectory == null) {
    throw NoProjectDirectorySpecifiedException();
  }

  if (generatedFileDirectory == null) {
    throw NoGeneratedFileDirectorySpecifiedException();
  }

  final generator = LocalizationGenerator(
    generatedClassName: generatedClassName,
    projectDirectory: projectDirectory,
    generatedFileDirectory: generatedFileDirectory,
  );

  generator.generate();
}
