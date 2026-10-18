import 'dart:io';

import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/runner/pipe_format.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:mansil/mansil.dart';

/// Shows the run line by line, without moving the cursor
///
/// Used when the output is not a terminal, such as in CI, or when the output of the commands is printed
class PlainReporter implements PipeReporter {
  /// Whether to print the output of the commands as they run. When false, the end of the output is
  /// printed only when a step fails
  final bool printOutput;
  final bool useColor;
  final String? logFilePath;
  final StringSink _out;

  final Set<PipeStage> _printedStages = {};

  /// The [out] defaults to the stdout, and is replaced in the tests
  PlainReporter({required this.printOutput, required this.useColor, this.logFilePath, StringSink? out}) : _out = out ?? stdout;

  @override
  void onEvent(PipeEvent event) {
    switch (event) {
      case RunStarted started:
        _out.writeln(_color(started.title, Mansil.bold));
        _out.writeln();
      case StepStarted started:
        _printStageTitle(started.step);
        _out.writeln("${PipeFormat.symbol(started.step, useColor: useColor)} ${started.step.step.label}");
      case StepStatusChanged changed:
        _out.writeln(_color("    ${changed.text}", Mansil.dim));
      case StepWarned warned:
        _out.writeln(_color("    ! ${warned.message}", Mansil.yellowFg));
      case CommandStarted started:
        if (printOutput) {
          _out.writeln(_color("    \$ ${started.commandLine}", Mansil.dim));
        }
      case CommandOutput output:
        if (printOutput) {
          _out.writeln("    ${PipeFormat.terminalLine(output.line)}");
        }
      case StepFinished finished:
        _printStageTitle(finished.step);
        _printFinished(finished.step);
      case RunFinished finished:
        _out.writeln();
        _out.writeln(
          finished.result.hasFailures ? _color("X ${PipeFormat.summary(finished.result)}", Mansil.redFg) : _color("√ ${PipeFormat.summary(finished.result)}", Mansil.greenFg),
        );
        if (logFilePath != null) {
          _out.writeln("Log: $logFilePath");
        }
      case StepLogged():
      case CommandFinished():
        // Only meant for the log file
        break;
    }
  }

  @override
  Future<void> close() async {}

  void _printFinished(StepState step) {
    List<String> parts = [step.step.label];
    if (step.status != StepStatus.skipped) {
      parts.add(PipeFormat.duration(step.elapsed));
    }
    String outcome = PipeFormat.outcome(step);
    if (outcome.isNotEmpty) {
      parts.add(outcome);
    }
    _out.writeln("${PipeFormat.symbol(step, useColor: useColor)} ${parts.join(" - ")}");

    if (step.status != StepStatus.failed) return;
    for (String detail in step.error?.details ?? <String>[]) {
      _out.writeln(_color("    $detail", Mansil.redFg));
    }
    // When the output is printed, the end of it is already right above
    List<String> output = step.recentOutput;
    if (!printOutput && output.isNotEmpty) {
      _out.writeln(_color("    The last ${output.length} lines of the output:", Mansil.dim));
      for (String line in output) {
        _out.writeln("      ${PipeFormat.terminalLine(line)}");
      }
    }
  }

  void _printStageTitle(StepState step) {
    if (_printedStages.add(step.stage)) {
      if (_printedStages.length > 1) {
        _out.writeln();
      }
      _out.writeln(_color(step.stage.title, Mansil.bold));
    }
  }

  String _color(String text, String code) => PipeFormat.color(text, code, useColor);
}
