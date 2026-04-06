import 'package:test/test.dart';
import 'package:build_pipe/utils/process.utils.dart';

void main() {
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
