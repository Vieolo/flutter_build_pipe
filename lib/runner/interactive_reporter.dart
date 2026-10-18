import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:build_pipe/runner/pipe_events.dart';
import 'package:build_pipe/runner/pipe_format.dart';
import 'package:build_pipe/runner/pipe_step.dart';
import 'package:mansil/mansil.dart';

/// Shows the run as a tree of stages and steps, updated in place, for terminals
///
/// The finished steps are printed for good. The running step and the steps after it form the live
/// part at the bottom, which is erased and redrawn on every frame. Since the steps run in order, the
/// finished steps are always above the live part
class InteractiveReporter implements PipeReporter {
  static const List<String> _spinner = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
  static const Duration _frameInterval = Duration(milliseconds: 80);

  /// The number of output lines shown under the running step
  static const int _liveOutputLines = 3;

  final String? logFilePath;
  final StringSink _out;
  final ({int columns, int lines}) Function() _terminalSize;

  List<StepState> _steps = [];

  /// The index of the first step that is not printed for good yet
  int _firstLiveStep = 0;
  int _liveHeight = 0;
  int _labelWidth = 0;
  int _frame = 0;
  final Set<PipeStage> _printedStages = {};

  /// The lines to be printed for good on the next frame
  final List<String> _pendingLines = [];

  Timer? _timer;
  StreamSubscription<ProcessSignal>? _interruptSubscription;

  /// The [out] and [terminalSize] default to the stdout, and are replaced in the tests
  InteractiveReporter({
    this.logFilePath,
    StringSink? out,
    ({int columns, int lines}) Function()? terminalSize,
  }) : _out = out ?? stdout,
       _terminalSize = terminalSize ?? (() => (columns: stdout.terminalColumns, lines: stdout.terminalLines));

  @override
  void onEvent(PipeEvent event) {
    switch (event) {
      case RunStarted started:
        _steps = started.steps;
        _labelWidth = _steps.fold(0, (int width, StepState s) => max(width, Mansil.visibleWidth(s.step.label)));
        _pendingLines.addAll([_bold(started.title), ""]);

        _out.write(Mansil.hideCursor);
        // The cursor would stay hidden after the user stops the run with ctrl+c
        _interruptSubscription = ProcessSignal.sigint.watch().listen((ProcessSignal _) {
          _out.write(Mansil.showCursor);
          exit(130);
        });
        _timer = Timer.periodic(_frameInterval, (Timer _) {
          _frame++;
          _render();
        });
        _render();
      case StepStarted started:
        _printStageTitle(started.step);
        _render();
      case StepFinished finished:
        _printStageTitle(finished.step);
        _pendingLines.addAll(_finishedLines(finished.step));
        _firstLiveStep = finished.step.number;
        _render();
      case RunFinished finished:
        _timer?.cancel();
        _render();
        _out.writeln();
        _out.writeln(
          finished.result.hasFailures
              ? PipeFormat.color("X ${PipeFormat.summary(finished.result)}", Mansil.redFg, true)
              : PipeFormat.color("√ ${PipeFormat.summary(finished.result)}", Mansil.greenFg, true),
        );
        if (logFilePath != null) {
          _out.writeln(_dim("Log: $logFilePath"));
        }
        _out.write(Mansil.showCursor);
      default:
        // The rest of the events change the state of the running step, which is drawn on the next frame
        break;
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _interruptSubscription?.cancel();
  }

  /// Erases the live part, prints the pending lines for good, and draws the live part again
  void _render() {
    ({int columns, int lines}) size = _terminalSize();
    StringBuffer buffer = StringBuffer();
    buffer.write(Mansil.cursorPrevLine(_liveHeight));
    buffer.write(Mansil.clearScreenDown);
    for (String line in _pendingLines) {
      buffer.writeln(line);
    }
    _pendingLines.clear();

    // Each live line must fit in one row of the terminal, otherwise the next frame would not erase all of it
    List<String> live = _liveLines(size.lines);
    for (String line in live) {
      buffer.writeln(Mansil.truncate(line, size.columns - 1, "…"));
    }
    _liveHeight = live.length;
    _out.write(buffer.toString());
  }

  /// The lines of the running step and the steps after it, cut to fit in the terminal
  List<String> _liveLines(int terminalLines) {
    List<String> lines = [];
    Set<PipeStage> titledStages = {..._printedStages};
    for (int i = _firstLiveStep; i < _steps.length; i++) {
      StepState step = _steps[i];
      if (!titledStages.contains(step.stage)) {
        lines.add(_bold(step.stage.title));
        titledStages.add(step.stage);
      }
      lines.add(_stepLine(step));
      if (step.status == StepStatus.running) {
        List<String> output = step.recentOutput;
        for (String line in output.skip(max(0, output.length - _liveOutputLines))) {
          lines.add(_dim("${_branchContinuation(step)}  ${PipeFormat.terminalLine(line)}"));
        }
      }
    }

    // The cursor cannot move above the top of the terminal, so a taller live part could not be erased
    int limit = max(terminalLines - 1, 1);
    if (lines.length > limit) {
      int hidden = lines.length - limit + 1;
      lines = [...lines.take(limit - 1), _dim("    … and $hidden more")];
    }
    return lines;
  }

  /// The lines printed for good once a step has finished
  List<String> _finishedLines(StepState step) {
    String indent = "${_branchContinuation(step)}  ";
    List<String> lines = [_stepLine(step)];
    for (String warning in step.warnings) {
      lines.add("$indent${PipeFormat.color("! $warning", Mansil.yellowFg, true)}");
    }
    if (step.status == StepStatus.failed) {
      for (String detail in step.error?.details ?? <String>[]) {
        lines.add("$indent${PipeFormat.color(detail, Mansil.redFg, true)}");
      }
      List<String> output = step.recentOutput;
      if (output.isNotEmpty) {
        lines.add(_dim("${indent}The last ${output.length} lines of the output:"));
        for (String line in output) {
          lines.add(_dim("$indent  ${PipeFormat.terminalLine(line)}"));
        }
      }
    }
    return lines;
  }

  /// e.g. `├── √ flutter clean     2.1s`
  String _stepLine(StepState step) {
    String branch = step.isLastInStage ? "└──" : "├──";
    String symbol = step.status == StepStatus.running ? PipeFormat.color(_spinner[_frame % _spinner.length], Mansil.cyanFg, true) : PipeFormat.symbol(step, useColor: true);

    String time = "";
    if (step.status == StepStatus.running || step.status == StepStatus.succeeded || step.status == StepStatus.failed) {
      time = PipeFormat.duration(step.elapsed).padLeft(7);
    }

    String note = "";
    if (step.status == StepStatus.running && step.statusText != null) {
      note = _dim(step.statusText!);
    } else if (step.status == StepStatus.failed) {
      note = PipeFormat.color(PipeFormat.outcome(step), Mansil.redFg, true);
    } else if (step.status == StepStatus.skipped) {
      note = _dim(PipeFormat.outcome(step));
    }

    String line = "$branch $symbol ${PipeFormat.pad(step.step.label, _labelWidth)}  ${_dim(time)}";
    return note.isEmpty ? line : "$line  $note";
  }

  void _printStageTitle(StepState step) {
    if (_printedStages.add(step.stage)) {
      _pendingLines.add(_bold(step.stage.title));
    }
  }

  /// What continues the branch of the tree under a step, so that its extra lines stay inside the tree
  String _branchContinuation(StepState step) => step.isLastInStage ? "    " : "│   ";

  String _bold(String text) => PipeFormat.color(text, Mansil.bold, true);

  String _dim(String text) => PipeFormat.color(text, Mansil.dim, true);
}
