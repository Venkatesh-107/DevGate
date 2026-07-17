import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/finding.dart';
import '../../../engines/scanner/scanner_engine.dart';

class DropZoneWidget extends ConsumerStatefulWidget {
  const DropZoneWidget({super.key});

  @override
  ConsumerState<DropZoneWidget> createState() => _DropZoneWidgetState();
}

class _DropZoneWidgetState extends ConsumerState<DropZoneWidget> {
  bool _isDragging = false;
  List<String> _droppedPaths = [];

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerStateProvider);
    final hasResults = scannerState.findings.isNotEmpty ||
        (_droppedPaths.isNotEmpty && !scannerState.isScanning);

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited:  (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() {
          _isDragging = false;
          _droppedPaths = details.files.map((f) => f.path).toList();
        });
        if (_droppedPaths.isNotEmpty) {
          await ref
              .read(scannerStateProvider.notifier)
              .scanDirectories(_droppedPaths);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        decoration: BoxDecoration(
          color: _isDragging
              ? Colors.blue.withValues(alpha: 0.08)
              : const Color(0xFF1E1E1E),
          border: Border.all(
            color: _isDragging
                ? const Color(0xFF8AB4F8)
                : const Color(0xFF3C4043),
            width: _isDragging ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (_isDragging)
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: scannerState.isScanning
              ? _buildScanningView(scannerState)
              : hasResults
                  ? _buildResultsDashboard(scannerState)
                  : _buildEmptyView(),
        ),
      ),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────────────

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3C4043).withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined,
                size: 80, color: Color(0xFF8AB4F8)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Scan Your Project',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'Drag and drop project folders here to detect secrets,\n'
            'leaked credentials, and get architecture recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _browseFolder,
            icon: const Icon(Icons.folder_open),
            label:
                const Text('Browse Folder', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: const Color(0xFF8AB4F8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Scanning state ──────────────────────────────────────────────────────

  Widget _buildScanningView(ScannerState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              color: Color(0xFF8AB4F8),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analyzing Project Files...',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            state.currentFile.split('/').last,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          // Live finding count
          if (state.findings.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${state.findings.where((f) => f.type != FindingType.recommendation).length} finding(s) detected so far',
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Results dashboard ───────────────────────────────────────────────────

  Widget _buildResultsDashboard(ScannerState state) {
    final security       = state.findings.where((f) => f.type != FindingType.recommendation).toList();
    final recommendations = state.findings.where((f) => f.type == FindingType.recommendation).toList();
    final filtered        = state.filteredFindings.where((f) => f.type != FindingType.recommendation).toList();

    return Column(
      children: [
        _buildStatsBar(state, security, recommendations),
        _buildFilterBar(state),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildSecurityList(filtered, security.length),
              ),
              Container(width: 1, color: const Color(0xFF3C4043)),
              Expanded(
                flex: 1,
                child: _buildRecommendationsList(recommendations),
              ),
            ],
          ),
        ),
        _buildFooter(state),
      ],
    );
  }

  Widget _buildStatsBar(
    ScannerState state,
    List<Finding> security,
    List<Finding> recommendations,
  ) {
    final critical = security.where((f) => f.severity == Severity.critical).length;
    final high     = security.where((f) => f.severity == Severity.high).length;
    final medium   = security.where((f) => f.severity == Severity.medium).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _StatCard(
              title: 'Security Risks',
              value: security.length.toString(),
              color: security.isEmpty ? Colors.green : Colors.redAccent,
            ),
          ),
          if (critical > 0) ...[
            const _StatDivider(),
            Expanded(
              child: _StatCard(
                title: 'Critical',
                value: critical.toString(),
                color: Colors.red,
              ),
            ),
          ],
          const _StatDivider(),
          Expanded(
            child: _StatCard(
              title: 'High',
              value: high.toString(),
              color: Colors.orangeAccent,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatCard(
              title: 'Medium',
              value: medium.toString(),
              color: Colors.amberAccent,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatCard(
              title: 'Recommendations',
              value: recommendations.length.toString(),
              color: const Color(0xFF8AB4F8),
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatCard(
              title: 'Files Scanned',
              value: state.scannedFileCount.toString(),
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ScannerState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF0F172A),
      child: Row(
        children: [
          const Text('Filter:',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 10),
          _SeverityChip(
            label: 'All',
            color: Colors.white54,
            active: state.severityFilter == null,
            onTap: () => ref
                .read(scannerStateProvider.notifier)
                .setSeverityFilter(null),
          ),
          const SizedBox(width: 6),
          _SeverityChip(
            label: 'High',
            color: Colors.orangeAccent,
            active: state.severityFilter == Severity.high,
            onTap: () => ref
                .read(scannerStateProvider.notifier)
                .setSeverityFilter(Severity.high),
          ),
          const SizedBox(width: 6),
          _SeverityChip(
            label: 'Medium',
            color: Colors.amberAccent,
            active: state.severityFilter == Severity.medium,
            onTap: () => ref
                .read(scannerStateProvider.notifier)
                .setSeverityFilter(Severity.medium),
          ),
          const SizedBox(width: 6),
          _SeverityChip(
            label: 'Low',
            color: Colors.blueAccent,
            active: state.severityFilter == Severity.low,
            onTap: () => ref
                .read(scannerStateProvider.notifier)
                .setSeverityFilter(Severity.low),
          ),
          const SizedBox(width: 12),
          const VerticalDivider(width: 1, color: Colors.white12),
          const SizedBox(width: 12),
          _SeverityChip(
            label: 'Regex',
            color: Colors.redAccent,
            active: state.typeFilter == FindingType.regex,
            onTap: () => ref
                .read(scannerStateProvider.notifier)
                .setTypeFilter(state.typeFilter == FindingType.regex
                    ? null
                    : FindingType.regex),
          ),
          const SizedBox(width: 6),
          _SeverityChip(
            label: 'Entropy',
            color: Colors.purpleAccent,
            active: state.typeFilter == FindingType.entropy,
            onTap: () => ref
                .read(scannerStateProvider.notifier)
                .setTypeFilter(state.typeFilter == FindingType.entropy
                    ? null
                    : FindingType.entropy),
          ),
          const Spacer(),
          if (state.severityFilter != null || state.typeFilter != null)
            TextButton.icon(
              onPressed: () {
                ref
                    .read(scannerStateProvider.notifier)
                    .setSeverityFilter(null);
                ref.read(scannerStateProvider.notifier).setTypeFilter(null);
              },
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('Clear filters', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityList(List<Finding> filtered, int totalCount) {
    if (totalCount == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text(
              'No security risks found! 🎉',
              style: TextStyle(color: Colors.green, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Your project looks clean.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                'Vulnerabilities',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  filtered.length == totalCount
                      ? '$totalCount'
                      : '${filtered.length} / $totalCount',
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (_, i) => _FindingCard(finding: filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsList(List<Finding> recs) {
    if (recs.isEmpty) {
      return const Center(
        child: Text(
          'No recommendations.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Architecture Advice',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: recs.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (_, i) {
              final f = recs[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: Colors.blueAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f.label,
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      f.snippet,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ScannerState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF334155))),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {
              ref.read(scannerStateProvider.notifier).clearFindings();
              setState(() => _droppedPaths = []);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('New Scan'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _exportJson(state),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export JSON'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8AB4F8),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _browseFolder() async {
    try {
      final dir = await getDirectoryPath();
      if (dir != null) {
        setState(() => _droppedPaths = [dir]);
        await ref
            .read(scannerStateProvider.notifier)
            .scanDirectories([dir]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking folder: $e')),
        );
      }
    }
  }

  Future<void> _exportJson(ScannerState state) async {
    try {
      final loc =
          await getSaveLocation(suggestedName: 'devgate_report.json');
      if (loc != null) {
        final file = File(loc.path);
        await file.writeAsString(
          const JsonEncoder.withIndent('  ')
              .convert(_buildReportData(state)),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report saved successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving report: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _buildReportData(ScannerState state) {
    final security = state.findings
        .where((f) => f.type != FindingType.recommendation)
        .toList();

    return {
      'generated_by': 'DevGate v1.0.0',
      'scanned_at': DateTime.now().toIso8601String(),
      'summary': {
        'total_findings': state.findings.length,
        'security_risks': security.length,
        'high': state.highCount,
        'medium': state.mediumCount,
        'low': state.lowCount,
        'files_scanned': state.scannedFileCount,
      },
      'findings': state.findings
          .map((f) => {
                'type': f.type.name,
                'label': f.label,
                'file': f.filePath,
                'line': f.lineNumber,
                'snippet': f.snippet,
                'severity': f.severity.name,
                if (f.entropyScore != null)
                  'entropy_score': f.entropyScore!.toStringAsFixed(4),
              })
          .toList(),
    };
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFF334155),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _SeverityChip({
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
        duration: const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.6)
                : const Color(0xFF3C4043),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : Colors.white38,
            fontSize: 11,
            fontWeight:
                active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FindingCard extends StatelessWidget {
  final Finding finding;

  const _FindingCard({required this.finding});

  Color get _severityColor {
    switch (finding.severity) {
      case Severity.critical: return Colors.red;
      case Severity.high:     return Colors.orangeAccent;
      case Severity.medium:   return Colors.amberAccent;
      case Severity.low:      return Colors.blueAccent;
    }
  }

  String get _severityLabel {
    switch (finding.severity) {
      case Severity.critical: return 'CRITICAL';
      case Severity.high:     return 'HIGH';
      case Severity.medium:   return 'MEDIUM';
      case Severity.low:      return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor;

    return Card(
      color: const Color(0xFF131314),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    finding.label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Severity badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _severityLabel,
                    style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    finding.type.name.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.insert_drive_file_outlined,
                    color: Colors.grey, size: 13),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    finding.filePath.split('/').last,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Line ${finding.lineNumber}',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11),
                ),
                if (finding.entropyScore != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'H=${finding.entropyScore!.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.purpleAccent, fontSize: 11),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                finding.snippet,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontSize: 11),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
