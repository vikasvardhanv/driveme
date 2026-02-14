import 'dart:collection';
import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error, api }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Object? error;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
  });

  @override
  String toString() {
    return '${timestamp.hour}:${timestamp.minute}:${timestamp.second}.${timestamp.millisecond} [${level.name.toUpperCase()}] $message ${error ?? ''}';
  }
}

class LogService extends ChangeNotifier {
  // Singleton instance
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  // Circular buffer for logs
  final int _maxLogs = 200;
  final Queue<LogEntry> _logs = Queue<LogEntry>();

  List<LogEntry> get logs => _logs.toList();

  void log(String message, {LogLevel level = LogLevel.info, Object? error}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error,
    );
    
    _logs.addFirst(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeLast();
    }
    
    // Also print to console for development
    debugPrint(entry.toString());
    notifyListeners();
  }

  void info(String message) => log(message, level: LogLevel.info);
  void warn(String message) => log(message, level: LogLevel.warning);
  void error(String message, [Object? error]) => log(message, level: LogLevel.error, error: error);
  void api(String message) => log(message, level: LogLevel.api);

  void clear() {
    _logs.clear();
    notifyListeners();
  }
}
