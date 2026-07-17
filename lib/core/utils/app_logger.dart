import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Log severity level.
enum LogLevel { info, success, warning, error }

/// A single immutable log entry.
class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;

  const LogEntry({
    required this.timestamp,
    required this.message,
    required this.level,
  });

  /// Formats the timestamp as HH:MM:SS.
  String get timeLabel {
    final t = timestamp;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/// Riverpod Notifier that maintains an in-memory log stream.
///
/// Usage (in a widget or notifier that has access to `ref`):
/// ```dart
/// ref.read(appLoggerProvider.notifier).info('Project loaded');
/// ```
class AppLogger extends Notifier<List<LogEntry>> {
  @override
  List<LogEntry> build() => [];

  void log(String message, {LogLevel level = LogLevel.info}) {
    state = [
      ...state,
      LogEntry(timestamp: DateTime.now(), message: message, level: level),
    ];
  }

  void info(String message) => log(message, level: LogLevel.info);
  void success(String message) => log(message, level: LogLevel.success);
  void warning(String message) => log(message, level: LogLevel.warning);
  void error(String message) => log(message, level: LogLevel.error);

  void clear() => state = [];
}

final appLoggerProvider =
    NotifierProvider<AppLogger, List<LogEntry>>(() => AppLogger());
