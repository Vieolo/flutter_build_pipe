import 'dart:io';

/// A command with a known output and exit code, used by the tests
///
/// Usage: `dart test/sample/echo_and_exit.dart <exit code> [lines...]`
/// The lines starting with `err:` are written to the stderr, the rest to the stdout
void main(List<String> args) {
  for (String line in args.skip(1)) {
    if (line.startsWith("err:")) {
      stderr.writeln(line.substring(4));
    } else {
      stdout.writeln(line);
    }
  }
  exitCode = int.parse(args.first);
}
