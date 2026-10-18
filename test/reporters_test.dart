import 'dart:io';

import 'package:build_pipe/runner/interactive_reporter.dart';
import 'package:build_pipe/runner/log_file_reporter.dart';
import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/runner/pipe_runner.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:build_pipe/runner/plain_reporter.dart';
import 'package:test/test.dart';

/// A tiny terminal, handling only what the reporters write: text, new lines, moving the cursor to the
/// start of a previous line, and clearing the screen below the cursor. The colors are ignored
class VirtualTerminal implements StringSink {
  final List<String> rows = [""];
  int _row = 0;

  @override
  void write(Object? object) {
    String text = "$object";
    int i = 0;
    while (i < text.length) {
      if (text.codeUnitAt(i) == 0x1b) {
        Match match = RegExp(r'\x1b\[([?0-9;]*)([A-Za-z])').matchAsPrefix(text, i)!;
        String params = match.group(1)!;
        switch (match.group(2)) {
          case "F":
            _row -= int.parse(params.isEmpty ? "1" : params);
          case "J":
            rows.removeRange(_row, rows.length);
            rows.add("");
        }
        i = match.end;
      } else if (text[i] == "\n") {
        _row++;
        if (_row == rows.length) rows.add("");
        i++;
      } else {
        rows[_row] += text[i];
        i++;
      }
    }
  }

  @override
  void writeln([Object? object = ""]) => write("$object\n");

  @override
  void writeAll(Iterable<Object?> objects, [String separator = ""]) => write(objects.join(separator));

  @override
  void writeCharCode(int charCode) => write(String.fromCharCode(charCode));

  /// The rows of the screen, without the empty row the cursor sits on
  List<String> get screen => rows.last.isEmpty ? rows.sublist(0, rows.length - 1) : rows;
}

/// A short run with a success, a failure with output, and a skipped step
Future<void> runSample(List<PipeReporter> reporters) async {
  await PipeRunner(reporters).run("build_pipe build", [
    PipeStage(
      "Build",
      onFailure: FailurePolicy.continueRun,
      steps: [
        ActionStep("iOS", (StepContext context) async => null),
        CommandStep(
          "Android",
          executable: Platform.resolvedExecutable,
          arguments: ["test/sample/echo_and_exit.dart", "2", "gradle failed", "token abc123"],
          redactions: ["abc123"],
        ),
      ],
    ),
    PipeStage(
      "Post-build",
      steps: [
        ActionStep("Post-build command", (StepContext context) async {
          context.warn("nothing to do");
          return null;
        }),
      ],
    ),
  ]);
}

void main() {
  test('InteractiveReporter leaves the finished tree and the summary on the screen', () async {
    VirtualTerminal terminal = VirtualTerminal();
    await runSample([
      InteractiveReporter(out: terminal, terminalSize: () => (columns: 100, lines: 30), logFilePath: "the.log"),
    ]);

    List<String> screen = terminal.screen;
    expect(screen.first, "build_pipe build");
    expect(screen, contains("Build"));
    expect(screen.any((String row) => row.startsWith("├── √ iOS")), isTrue);
    expect(screen.any((String row) => row.startsWith("└── X Android") && row.endsWith("exited with code 2")), isTrue);
    expect(screen, contains("        gradle failed"));
    expect(screen, contains("        token REDACTED"));
    expect(screen.any((String row) => row.startsWith("└── ! Post-build command")), isTrue);
    expect(screen, contains("      ! nothing to do"));
    expect(screen.where((String row) => row.contains("Android")), hasLength(1), reason: "the live line of a step is replaced, not repeated");
    expect(screen.last, "Log: the.log");
    expect(screen[screen.length - 2], startsWith("X 1 of 3 steps failed, 1 warning - "));
  });

  test('PlainReporter prints the end of the output only for a failed step', () async {
    StringBuffer out = StringBuffer();
    await runSample([PlainReporter(printOutput: false, useColor: false, out: out)]);
    List<String> lines = out.toString().split("\n");

    expect(lines, containsAllInOrder(["Build", "› iOS", "› Android", "Post-build", "› Post-build command", "    ! nothing to do"]));
    expect(lines.any((String line) => line.startsWith("X Android - ") && line.endsWith(" - exited with code 2")), isTrue);
    expect(lines, containsAllInOrder(["      gradle failed", "      token REDACTED"]));
    expect(lines.any((String line) => line.startsWith("√ iOS - ")), isTrue);
  });

  test('PlainReporter prints the whole output when asked to', () async {
    StringBuffer out = StringBuffer();
    await runSample([PlainReporter(printOutput: true, useColor: false, out: out)]);
    String text = out.toString();

    expect(text, contains("    gradle failed\n"));
    expect(text, isNot(contains("The last")));
  });

  test('LogFileReporter writes a section per step and a summary', () async {
    Directory dir = await Directory.systemTemp.createTemp("build_pipe_log_test");
    addTearDown(() => dir.delete(recursive: true));
    String path = "${dir.path}/logs/run.log";

    (LogFileReporter?, String?) opened = LogFileReporter.open(path);
    expect(opened.$2, isNull);
    await runSample([opened.$1!]);
    String log = await File(path).readAsString();

    expect(log, startsWith("build_pipe build\nstarted at "));
    expect(log, contains("[2/3] Build › Android\n"));
    expect(log, matches(RegExp(r'\[\d\d:\d\d\.\d\]   token REDACTED\n')));
    expect(log, isNot(contains("abc123")));
    expect(log, contains("  exit code: 2\n"));
    expect(log, matches(RegExp(r'failed - \d+\.\ds - exited with code 2\n')));
    expect(log, contains("warning: nothing to do"));
    expect(log, contains("  X [2/3] Build › Android"));
    expect(opened.$1!.writeError, isNull);
  });

  test('LogFileReporter returns an error when the file cannot be created', () async {
    Directory dir = await Directory.systemTemp.createTemp("build_pipe_log_test");
    addTearDown(() => dir.delete(recursive: true));
    File blocker = await File("${dir.path}/file").create();

    (LogFileReporter?, String?) opened = LogFileReporter.open("${blocker.path}/run.log");
    expect(opened.$1, isNull);
    expect(opened.$2, isNotNull);
  });
}
