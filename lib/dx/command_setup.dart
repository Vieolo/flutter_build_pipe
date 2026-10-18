import 'package:build_pipe/config/config.dart';
import 'package:build_pipe/dx/cli_help.dart';
import 'package:build_pipe/runner/output_mode.dart';
import 'package:build_pipe/utils/console.utils.dart';
import 'package:build_pipe/utils/validation.utils.dart';

/// Handles the `--help` flag, reads the config, and prints the problems found in it
///
/// The problems are printed in the output chosen by the user, which is known from the flag even when
/// the config could not be read. Returns null when the command cannot run, after printing why
Future<BPConfig?> loadCommandConfig(List<String> args, HelpCommand command) async {
  // Handling the command's --help flag
  handleCommandHelpFlag(args, command);

  (BPConfig?, List<BPConfigValidationError>) configAndErrors = await BPConfig.readPubspec(args);

  OutputMode output = configAndErrors.$1?.output ?? OutputMode.fromArgs(args).$1 ?? OutputMode.auto;
  Console.json = output == OutputMode.json;

  // Printing the errors that were found while parsing the config
  // If the error are fatal the config will be null
  for (BPConfigValidationError error in configAndErrors.$2) {
    error.print();
  }
  return configAndErrors.$1;
}
