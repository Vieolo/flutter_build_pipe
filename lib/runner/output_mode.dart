import 'dart:io';

/// How a run is shown, set by the `output` field of a workflow and overridden by the `--bp-output` flag
enum OutputMode {
  /// `interactive` in a terminal, and `plain` anywhere else, including a CI
  auto,

  /// A tree of the steps that updates in place, with the last lines of the output of the running step
  interactive,

  /// One line per step, without moving the cursor, e.g. for a CI
  plain,

  /// Like `plain`, along with the whole output of the commands as they run
  verbose,

  /// One JSON object per line, for scripts and agents
  json;

  static const String flag = "--bp-output";

  /// The names of all the modes, e.g. for the error of an unknown value
  static String get names => values.map((OutputMode mode) => mode.name).join(", ");

  /// Parses the name of a mode, returning the error for an unknown one
  static (OutputMode?, String?) parse(String value) {
    for (OutputMode mode in values) {
      if (mode.name == value) return (mode, null);
    }
    return (null, "'$value' is not a valid output. The valid values are: $names");
  }

  /// Reads the value of the `--bp-output` flag. The mode is null when the flag is not given
  static (OutputMode?, String?) fromArgs(List<String> args) {
    for (String arg in args) {
      if (arg == flag) {
        return (null, "$flag needs a value, e.g. $flag=plain. The valid values are: $names");
      }
      if (arg.startsWith("$flag=")) {
        (OutputMode?, String?) parsed = parse(arg.substring(flag.length + 1));
        return parsed.$2 == null ? parsed : (null, "Invalid $flag -> ${parsed.$2}");
      }
    }
    return (null, null);
  }

  /// Whether the [arg] is the `--bp-output` flag, which is not passed down to the build commands
  static bool isFlag(String arg) => arg == flag || arg.startsWith("$flag=");

  /// Turns `auto` into the mode that fits where the output goes. The other modes are returned as they are
  ///
  /// A CI may give the command a terminal that only records the output, where redrawing the
  /// lines would fill the record with copies of them, so a set `CI` env variable counts as no terminal.
  /// The [hasTerminal] and [environment] default to those of the stdout and the process
  OutputMode resolve({bool? hasTerminal, Map<String, String>? environment}) {
    if (this != auto) return this;

    bool terminal = hasTerminal ?? (stdout.hasTerminal && stdout.supportsAnsiEscapes);
    String ci = ((environment ?? Platform.environment)["CI"] ?? "").trim().toLowerCase();
    bool isCI = ci.isNotEmpty && ci != "false" && ci != "0";
    return terminal && !isCI ? interactive : plain;
  }
}
