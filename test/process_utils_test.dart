import 'dart:io';

import 'package:test/test.dart';
import 'package:build_pipe/utils/process.utils.dart';

void main() {
  group('ProcessHelper.run', () {
    test('returns the merged output and the exit code', () async {
      List<String> streamed = [];
      (CommandResult?, CommandError?) outcome = await ProcessHelper.run(
        Platform.resolvedExecutable,
        ["test/sample/echo_and_exit.dart", "0", "first", "err:second"],
        onOutput: streamed.add,
      );
      expect(outcome.$2, isNull);
      expect(outcome.$1!.exitCode, 0);
      expect(outcome.$1!.output, unorderedEquals(["first", "second"]));
      expect(streamed, unorderedEquals(["first", "second"]));
    });

    test('returns a non-zero exit code as a result, not an error', () async {
      (CommandResult?, CommandError?) outcome = await ProcessHelper.run(Platform.resolvedExecutable, ["test/sample/echo_and_exit.dart", "3"]);
      expect(outcome.$2, isNull);
      expect(outcome.$1!.exitCode, 3);
    });

    test('returns an error when the command cannot be started', () async {
      (CommandResult?, CommandError?) outcome = await ProcessHelper.run("build_pipe_missing_executable", []);
      expect(outcome.$1, isNull);
      expect(outcome.$2!.message, contains("build_pipe_missing_executable"));
    });
  });

  group('ProcessHelper.splitCommand', () {
    test('splits simple command', () {
      final result = ProcessHelper.splitCommand('flutter build apk');
      expect(result, ['flutter', 'build', 'apk']);
    });

    test('splits command with double quotes', () {
      final result = ProcessHelper.splitCommand('sh -c "flutter build apk"');
      expect(result, ['sh', '-c', 'flutter build apk']);
    });

    test('splits command with single quotes', () {
      final result = ProcessHelper.splitCommand("sh -c 'flutter build apk'");
      expect(result, ['sh', '-c', 'flutter build apk']);
    });

    test('splits command with nested quotes (not supported by simple parser but check behavior)', () {
      // Current implementation strips the outer-most quotes but doesn't handle nested ones specially.
      final result = ProcessHelper.splitCommand('echo "Hello \'World\'"');
      expect(result, ['echo', "Hello 'World'"]);
    });

    test('handles multiple spaces', () {
      final result = ProcessHelper.splitCommand('flutter   build  apk');
      expect(result, ['flutter', 'build', 'apk']);
    });

    test('handles empty string', () {
      final result = ProcessHelper.splitCommand('');
      expect(result, []);
    });

    test('handles complex command with mixed quotes', () {
      final result = ProcessHelper.splitCommand('python3 script.py --arg1 "value with spaces" --arg2 \'another value\'');
      expect(result, ['python3', 'script.py', '--arg1', 'value with spaces', '--arg2', 'another value']);
    });
  });
}
