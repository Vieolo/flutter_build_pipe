import 'package:build_pipe/runner/pipe_events.dart';
import 'package:mansil/mansil.dart';

/// The formatting shared by the reporters
class PipeFormat {
  /// Formats a duration as `4.2s`, `1m 12s`, or `1h 5m`
  static String duration(Duration d) {
    if (d.inSeconds < 60) {
      return "${(d.inMilliseconds / 1000).toStringAsFixed(1)}s";
    }
    if (d.inMinutes < 60) {
      return "${d.inMinutes}m ${d.inSeconds % 60}s";
    }
    return "${d.inHours}h ${d.inMinutes % 60}m";
  }

  /// Formats a duration as a fixed-width timestamp, e.g. `[01:12.5]`
  static String timestamp(Duration d) {
    String minutes = d.inMinutes.toString().padLeft(2, "0");
    String seconds = ((d.inMilliseconds % 60000) / 1000).toStringAsFixed(1).padLeft(4, "0");
    return "[$minutes:$seconds]";
  }

  /// The lines at the top of the output, describing the run
  static List<String> title(PipeRunInfo info) {
    return ["command: ${info.command}", "workflow: ${info.workflow}", "version: ${info.version}"];
  }

  /// Prepares a line of the output of a command to be shown in the terminal
  ///
  /// The escape sequences are removed, since the cursor movements of a command would break the
  /// output of the reporter, and the tabs are replaced, since their width depends on the terminal
  static String terminalLine(String line) {
    return Mansil.strip(line).replaceAll("\t", "    ").trimRight();
  }

  /// The symbol showing the status of a finished or pending step
  static String symbol(StepState step, {required bool useColor}) {
    switch (step.status) {
      case StepStatus.succeeded:
        return step.warningCount == 0 ? color("√", Mansil.greenFg, useColor) : color("!", Mansil.yellowFg, useColor);
      case StepStatus.failed:
        return color("X", Mansil.redFg, useColor);
      case StepStatus.skipped:
        return color("-", Mansil.dim, useColor);
      case StepStatus.pending:
        return color("-", Mansil.dim, useColor);
      case StepStatus.running:
        return color("›", Mansil.cyanFg, useColor);
    }
  }

  /// The short outcome shown after a finished step, e.g. `exited with code 1` or `skipped, an earlier step has failed`
  static String outcome(StepState step) {
    switch (step.status) {
      case StepStatus.failed:
        return step.error?.message ?? "failed";
      case StepStatus.skipped:
        return "skipped, ${step.skipReason ?? "-"}";
      case StepStatus.succeeded:
        return step.warningCount == 0 ? "" : "${step.warningCount} warning${step.warningCount == 1 ? "" : "s"}";
      case StepStatus.pending:
      case StepStatus.running:
        return "";
    }
  }

  /// The one-line summary of a run, e.g. `1 of 7 steps failed, 2 skipped - 2m 10s`
  static String summary(PipeRunResult result) {
    int total = result.steps.length;
    List<String> parts = [];
    if (result.hasFailures) {
      parts.add("${result.failedSteps.length} of $total step${total == 1 ? "" : "s"} failed");
    } else {
      parts.add(total == 1 ? "The step succeeded" : "All $total steps succeeded");
    }
    if (result.skippedSteps.isNotEmpty) {
      parts.add("${result.skippedSteps.length} skipped");
    }
    if (result.warningCount > 0) {
      parts.add("${result.warningCount} warning${result.warningCount == 1 ? "" : "s"}");
    }
    return "${parts.join(", ")} - ${duration(result.elapsed)}";
  }

  /// Wraps the [text] in the given ANSI [code], when [useColor] is true
  static String color(String text, String code, bool useColor) {
    return useColor ? "$code$text${Mansil.reset}" : text;
  }

  /// Pads the [text] with spaces to the given number of terminal columns
  static String pad(String text, int width) {
    int missing = width - Mansil.visibleWidth(text);
    return missing > 0 ? "$text${" " * missing}" : text;
  }
}
