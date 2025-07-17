class Console {
  /// Prints the `obj` to the terminal
  ///
  /// This function checks if we are in debug more or not and will not
  /// print anything during the production mode
  static void log(Object? obj) {
    print(obj?.toString() ?? "");
  }

  static void logError(String message) {
    Console.log("\u001b[31;1m$message\u001b[0m");
  }

  static void logSuccess(String message) {
    Console.log("\u001b[32;1m$message\u001b[0m");
  }

  static void logWarning(String message, [bool skipWhileIntegrationTest = true]) {
    Console.log("\u001b[33;1m$message\u001b[0m");
  }

  static void logInfo(String message, [bool skipWhileIntegrationTest = true]) {
    Console.log("\u001b[37;1m$message\u001b[0m");
  }
}
