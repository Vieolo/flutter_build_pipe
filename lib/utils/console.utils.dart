import 'package:mansil/mansil.dart';

/// Handles the printing to the terminal
class Console {
  /// Logs a text in red
  static void logError(String message) {
    print("${Mansil.redFg}${Mansil.bold}$message${Mansil.reset}");
  }

  /// Logs a text in green
  static void logSuccess(String message) {
    print("${Mansil.greenFg}${Mansil.bold}$message${Mansil.reset}");
  }

  /// Logs a text in yellow
  static void logWarning(String message) {
    print("${Mansil.yellowFg}${Mansil.bold}$message${Mansil.reset}");
  }

  /// Logs a text in bold white
  static void logInfo(String message) {
    print("${Mansil.whiteFg}${Mansil.bold}$message${Mansil.reset}");
  }
}
