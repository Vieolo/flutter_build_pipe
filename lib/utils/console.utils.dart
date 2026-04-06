/// Handles the printing to the terminal
class Console {
  /// Logs a text in red
  static void logError(String message) {
    print("\u001b[31;1m$message\u001b[0m");
  }

  /// Logs a text in green
  static void logSuccess(String message) {
    print("\u001b[32;1m$message\u001b[0m");
  }

  /// Logs a text in yellow
  static void logWarning(String message) {
    print("\u001b[33;1m$message\u001b[0m");
  }

  /// Logs a text in bold white
  static void logInfo(String message) {
    print("\u001b[37;1m$message\u001b[0m");
  }
}
