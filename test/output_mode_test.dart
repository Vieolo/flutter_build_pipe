import 'package:build_pipe/runner/output_mode.dart';
import 'package:test/test.dart';

void main() {
  group('OutputMode', () {
    test('parses the names of the modes', () {
      for (OutputMode mode in OutputMode.values) {
        expect(OutputMode.parse(mode.name), (mode, null));
      }
      expect(OutputMode.parse("xml").$2, contains("auto, interactive, plain, verbose, json"));
    });

    test('reads the --bp-output flag', () {
      expect(OutputMode.fromArgs(["--workflow=local"]), (null, null));
      expect(OutputMode.fromArgs(["--workflow=local", "--bp-output=json"]), (OutputMode.json, null));
      expect(OutputMode.fromArgs(["--bp-output=xml"]).$2, contains("Invalid --bp-output"));
      expect(OutputMode.fromArgs(["--bp-output", "json"]).$2, contains("needs a value"));
      expect(OutputMode.isFlag("--bp-output=json"), isTrue);
      expect(OutputMode.isFlag("--output=build/web"), isFalse);
    });

    test('resolves auto from the terminal and the CI env variable', () {
      expect(OutputMode.auto.resolve(hasTerminal: true, environment: {}), OutputMode.interactive);
      expect(OutputMode.auto.resolve(hasTerminal: false, environment: {}), OutputMode.plain);
      expect(OutputMode.auto.resolve(hasTerminal: true, environment: {"CI": "true"}), OutputMode.plain);
      expect(OutputMode.auto.resolve(hasTerminal: true, environment: {"CI": "1"}), OutputMode.plain);
      expect(OutputMode.auto.resolve(hasTerminal: true, environment: {"CI": "false"}), OutputMode.interactive);
      expect(OutputMode.auto.resolve(hasTerminal: true, environment: {"CI": ""}), OutputMode.interactive);
    });

    test('keeps a mode that is not auto', () {
      expect(OutputMode.interactive.resolve(hasTerminal: false, environment: {"CI": "true"}), OutputMode.interactive);
      expect(OutputMode.json.resolve(hasTerminal: true, environment: {}), OutputMode.json);
    });
  });
}
