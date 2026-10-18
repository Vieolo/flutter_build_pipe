import 'dart:io';

/// A hook used by the tests, printing the env variables it is given
///
/// Usage: `dart test/sample/print_env.dart <tag> [NAME...]`
/// Prints `<tag>` alone, or `<tag> NAME=value` for each of the names
void main(List<String> args) {
  if (args.length == 1) {
    stdout.writeln(args.first);
  }
  for (String name in args.skip(1)) {
    stdout.writeln("${args.first} $name=${Platform.environment[name] ?? ""}");
  }
}
