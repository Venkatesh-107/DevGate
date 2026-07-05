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
  List<String> _droppedFiles = [];

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerStateProvider);
    final hasResults = scannerState.findings.isNotEmpty || (_droppedFiles.isNotEmpty && !scannerState.isScanning);

    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() {
          _isDragging = false;
          _droppedFiles = details.files.map((file) => file.path).toList();
        });
        if (_droppedFiles.isNotEmpty) {
          await ref.read(scannerStateProvider.notifier).scanDirectories(_droppedFiles);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        decoration: BoxDecoration(
          color: _isDragging ? Colors.blue.withValues(alpha: 0.1) : const Color(0xFF1E1E1E),
          border: Border.all(
            color: _isDragging ? const Color(0xFF8AB4F8) : const Color(0xFF3C4043),
            width: _isDragging ? 3 : 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (_isDragging) BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: scannerState.isScanning
              ? _buildScanningState(scannerState)
              : hasResults
                  ? _buildReportDashboard(scannerState)
                  : _buildEmptyState(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3C4043).withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined, size: 80, color: Color(0xFF8AB4F8)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Scan Your Project',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'Drag and drop your project folders here to analyze\nsecurity risks and architecture recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _browseFolder,
            icon: const Icon(Icons.folder_open),
            label: const Text('Browse Folders', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: const Color(0xFF8AB4F8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningState(ScannerState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF8AB4F8)),
          const SizedBox(height: 24),
          const Text('Analyzing Project Files...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text(
            state.currentFile.split('/').last,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReportDashboard(ScannerState state) {
    final securityFindings = state.findings.where((f) => f.type != FindingType.recommendation).toList();
    final recommendations = state.findings.where((f) => f.type == FindingType.recommendation).toList();

    return Column(
      children: [
        _buildDashboardHeader(securityFindings.length, recommendations.length),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildSecurityList(securityFindings),
              ),
              Container(width: 1, color: const Color(0xFF3C4043)),
              Expanded(
                flex: 1,
                child: _buildRecommendationsList(recommendations),
              ),
            ],
          ),
        ),
        _buildDashboardFooter(state),
      ],
    );
  }

  Widget _buildDashboardHeader(int securityCount, int recCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildStatCard('Security Risks', securityCount.toString(), securityCount > 0 ? Colors.redAccent : Colors.green)),
          Expanded(child: _buildStatCard('Recommendations', recCount.toString(), const Color(0xFF8AB4F8))),
          Expanded(child: _buildStatCard('Scan Status', 'Complete', Colors.green)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(
          title, 
          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSecurityList(List<Finding> findings) {
    if (findings.isEmpty) {
      return const Center(child: Text('No security risks found! 🎉', style: TextStyle(color: Colors.green, fontSize: 18)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Vulnerabilities Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: findings.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final f = findings[index];
              return Card(
                color: const Color(0xFF131314),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Text(f.label, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text(f.type.name.toUpperCase(), style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.insert_drive_file, color: Colors.grey, size: 14),
                          const SizedBox(width: 6),
                          Expanded(child: Text(f.filePath.split('/').last, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
                          Text('Line: ${f.lineNumber}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          f.snippet,
                          style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 12),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsList(List<Finding> findings) {
    if (findings.isEmpty) {
      return const Center(child: Text('No recommendations.', style: TextStyle(color: Colors.grey)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Architecture Advice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: findings.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final f = findings[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(f.label, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(f.snippet, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardFooter(ScannerState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF334155))),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {
              ref.read(scannerStateProvider.notifier).clearFindings();
              setState(() => _droppedFiles = []);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('New Scan'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _exportJson(state),
            icon: const Icon(Icons.download),
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

  Future<void> _browseFolder() async {
    try {
      String? selectedDirectory = await getDirectoryPath();
      if (selectedDirectory != null) {
        setState(() {
          _droppedFiles = [selectedDirectory];
        });
        await ref.read(scannerStateProvider.notifier).scanDirectories([selectedDirectory]);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking folder: $e')));
    }
  }



  Future<void> _exportJson(ScannerState state) async {
    try {
      final saveLocation = await getSaveLocation(suggestedName: 'devgate_report.json');
      if (saveLocation != null) {
        final file = File(saveLocation.path);
        await file.writeAsString(const JsonEncoder.withIndent('  ').convert(_generateReportData(state)));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report saved successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving report: $e')));
    }
  }

  Map<String, dynamic> _generateReportData(ScannerState state) {
    return {
      'generated_by': 'DevGate v1.0.0',
      'scanned_at': DateTime.now().toIso8601String(),
      'summary': {'total_findings': state.findings.length},
      'findings': state.findings.map((f) => {
        'type': f.type.name,
        'label': f.label,
        'file': f.filePath,
        'line': f.lineNumber,
        'snippet': f.snippet,
        'severity': f.severity.name,
      }).toList(),
    };
  }
}

