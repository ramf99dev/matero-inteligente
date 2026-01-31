import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static const bool _isDebug = kDebugMode;

  static final Logger _logger = Logger(
    level: _isDebug ? Level.verbose : Level.warning,
    printer: _isDebug ? PrettyPrinter() : SimplePrinter(),
  );

  static void debug(String message) {
    if (_isDebug) _logger.d(message);
  }

  static void info(String message) {
    if (_isDebug) _logger.i(message);
  }

  static void warning(String message) {
    _logger.w(message);
  }

  static void error(String message, [dynamic error]) {
    _logger.e('$message ${error ?? ''}');
  }

  static void verbose(String message) {
    if (_isDebug) _logger.v(message);
  }
}
