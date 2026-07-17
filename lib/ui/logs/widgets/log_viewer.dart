import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/app_logger.dart';

/// Color-coded real-time log viewer widget.
///
/// Consumes a [List<LogEntry>] and renders them in a scrollable dark terminal
/// panel. Can be embedded inside any screen.
class LogViewer extends StatefulWidget {
  final List<LogEntry> entries;
  final VoidCallback? onClear;

  const LogViewer({
    super.key,
    required this.entries,
    this.onClear,
  });

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final ScrollController _scroll = ScrollController();
  LogLevel? _filterLevel;
  bool _autoScroll = true;

  @override
  void didUpdateWidget(LogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.length != oldWidget.entries.length && _autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<LogEntry> get _visible {
    if (_filterLevel == null) return widget.entries;
    return widget.entries.where((e) => e.level == _filterLevel).toList();
  }

  Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.success: return Colors.greenAccent;
      case LogLevel.warning: return Colors.orangeAccent;
      case LogLevel.error:   return Colors.redAccent;
      case LogLevel.info:    return const Color(0xFF8AB4F8);
    }
  }

  String _levelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.success: return '✓';
      case LogLevel.warning: return '⚠';
      case LogLevel.error:   return '✗';
      case LogLevel.info:    return 'i';
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(visible),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3C4043)),
            ),
            child: visible.isEmpty
                ? _buildEmpty()
                : _buildList(visible),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(List<LogEntry> visible) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Level filter chips
          _FilterChip(
            label: 'All',
            color: Colors.white54,
            active: _filterLevel == null,
            onTap: () => setState(() => _filterLevel = null),
          ),
          const SizedBox(width: 6),
          for (final level in LogLevel.values) ...[
            _FilterChip(
              label: level.name[0].toUpperCase() + level.name.substring(1),
              color: _levelColor(level),
              active: _filterLevel == level,
              onTap: () => setState(
                () => _filterLevel = _filterLevel == level ? null : level,
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Spacer(),
          // Auto-scroll toggle
          Tooltip(
            message: 'Auto-scroll',
            child: IconButton(
              iconSize: 18,
              icon: Icon(
                Icons.vertical_align_bottom,
                color: _autoScroll ? const Color(0xFF8AB4F8) : Colors.grey,
              ),
              onPressed: () => setState(() => _autoScroll = !_autoScroll),
            ),
          ),
          // Copy all
          Tooltip(
            message: 'Copy all logs',
            child: IconButton(
              iconSize: 18,
              icon: const Icon(Icons.copy, color: Colors.grey),
              onPressed: visible.isEmpty
                  ? null
                  : () {
                      final text = visible
                          .map((e) => '[${e.timeLabel}] [${e.level.name.toUpperCase()}] ${e.message}')
                          .join('\n');
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs copied to clipboard')),
                      );
                    },
            ),
          ),
          // Clear
          Tooltip(
            message: 'Clear logs',
            child: IconButton(
              iconSize: 18,
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: widget.onClear,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terminal, color: Colors.white12, size: 48),
          SizedBox(height: 12),
          Text(
            'No log entries yet',
            style: TextStyle(color: Colors.white24, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Activity will appear here when you scan or run git operations.',
            style: TextStyle(color: Colors.white12, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<LogEntry> entries) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        final color = _levelColor(e.level);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timestamp
              Text(
                e.timeLabel,
                style: const TextStyle(
                  color: Colors.white24,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              // Level badge
              Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _levelIcon(e.level),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              // Message
              Expanded(
                child: Text(
                  e.message,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.6) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : Colors.white38,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
