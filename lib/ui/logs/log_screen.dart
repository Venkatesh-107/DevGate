import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import 'widgets/log_viewer.dart';

/// Full-page activity log screen — shows all DevGate operations in real time.
class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(appLoggerProvider);
    final logger  = ref.read(appLoggerProvider.notifier);

    // Severity counts for the stat bar.
    final infoCount    = entries.where((e) => e.level == LogLevel.info).length;
    final successCount = entries.where((e) => e.level == LogLevel.success).length;
    final warnCount    = entries.where((e) => e.level == LogLevel.warning).length;
    final errorCount   = entries.where((e) => e.level == LogLevel.error).length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.terminal, color: Color(0xFF8AB4F8), size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity Log',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${entries.length} total entr${entries.length == 1 ? 'y' : 'ies'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Stat chips ─────────────────────────────────────────────────────
          if (entries.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _StatChip(label: 'Info',    count: infoCount,    color: const Color(0xFF8AB4F8)),
                _StatChip(label: 'Success', count: successCount, color: Colors.greenAccent),
                _StatChip(label: 'Warning', count: warnCount,    color: Colors.orangeAccent),
                _StatChip(label: 'Error',   count: errorCount,   color: Colors.redAccent),
              ],
            ),
          const SizedBox(height: 16),

          // ── Log viewer ─────────────────────────────────────────────────────
          Expanded(
            child: LogViewer(
              entries: entries,
              onClear: logger.clear,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
