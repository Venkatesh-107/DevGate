import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/finding.dart';
import 'entropy_math.dart';
import 'regex_engine.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class ScannerState {
  final bool isScanning;
  final String currentFile;
  final int scannedFileCount;
  final List<Finding> findings;
  final double entropyThreshold;
  final Severity? severityFilter; // null = show all
  final FindingType? typeFilter;  // null = show all

  const ScannerState({
    this.isScanning        = false,
    this.currentFile       = '',
    this.scannedFileCount  = 0,
    this.findings          = const [],
    this.entropyThreshold  = 4.8,
    this.severityFilter,
    this.typeFilter,
  });

  ScannerState copyWith({
    bool?         isScanning,
    String?       currentFile,
    int?          scannedFileCount,
    List<Finding>? findings,
    double?       entropyThreshold,
    Severity?     severityFilter,
    FindingType?  typeFilter,
    bool          clearSeverityFilter = false,
    bool          clearTypeFilter     = false,
  }) {
    return ScannerState(
      isScanning:       isScanning       ?? this.isScanning,
      currentFile:      currentFile      ?? this.currentFile,
      scannedFileCount: scannedFileCount ?? this.scannedFileCount,
      findings:         findings         ?? this.findings,
      entropyThreshold: entropyThreshold ?? this.entropyThreshold,
      severityFilter:   clearSeverityFilter ? null : (severityFilter ?? this.severityFilter),
      typeFilter:       clearTypeFilter     ? null : (typeFilter     ?? this.typeFilter),
    );
  }

  // ─── Derived ───────────────────────────────────────────────────────────────

  List<Finding> get filteredFindings {
    var list = findings;
    if (severityFilter != null) {
      list = list.where((f) => f.severity == severityFilter).toList();
    }
    if (typeFilter != null) {
      list = list.where((f) => f.type == typeFilter).toList();
    }
    return list;
  }

  int get criticalCount  => findings.where((f) => f.severity == Severity.critical).length;
  int get highCount      => findings.where((f) => f.severity == Severity.high).length;
  int get mediumCount    => findings.where((f) => f.severity == Severity.medium).length;
  int get lowCount       => findings.where((f) => f.severity == Severity.low).length;
  int get securityCount  => findings.where((f) => f.type != FindingType.recommendation).length;
  int get recoCount      => findings.where((f) => f.type == FindingType.recommendation).length;
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class ScannerNotifier extends Notifier<ScannerState> {
  @override
  ScannerState build() => const ScannerState();

  AppLogger get _logger => ref.read(appLoggerProvider.notifier);

  // ─── Filter controls ───────────────────────────────────────────────────────

  void setSeverityFilter(Severity? filter) {
    state = state.copyWith(
      severityFilter:     filter,
      clearSeverityFilter: filter == null,
    );
  }

  void setTypeFilter(FindingType? filter) {
    state = state.copyWith(
      typeFilter:      filter,
      clearTypeFilter: filter == null,
    );
  }

  void setEntropyThreshold(double threshold) {
    state = state.copyWith(entropyThreshold: threshold);
  }

  // ─── Main scan ─────────────────────────────────────────────────────────────

  Future<void> scanDirectories(
    List<String> directoryPaths, {
    int maxFileSizeKb = 5120, // 5 MB
  }) async {
    // Reset to fresh scanning state, preserving user-configured threshold.
    state = ScannerState(
      isScanning:        true,
      entropyThreshold:  state.entropyThreshold,
    );

    final List<Finding> allFindings = [];
    int scannedFiles = 0;

    _logger.info(
      'Starting scan of ${directoryPaths.length} director${directoryPaths.length == 1 ? 'y' : 'ies'}...',
    );

    for (final dirPath in directoryPaths) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        _logger.warning('Directory not found: $dirPath');
        continue;
      }

      // ── Architectural recommendations ────────────────────────────────────
      if (File('${dir.path}/pubspec.yaml').existsSync()) {
        allFindings.add(Finding(
          type: FindingType.recommendation,
          label: 'Flutter/Dart Project Detected',
          filePath: dir.path,
          lineNumber: 0,
          snippet:
              'Consider using a structured architecture like Clean Architecture or Feature-First '
              '(e.g. lib/core, lib/ui, lib/data, lib/domain).',
          severity: Severity.low,
          detectedAt: DateTime.now(),
        ));
        _logger.info('Flutter project detected at $dirPath');
      }

      if (File('${dir.path}/package.json').existsSync()) {
        allFindings.add(Finding(
          type: FindingType.recommendation,
          label: 'Node.js/Web Project Detected',
          filePath: dir.path,
          lineNumber: 0,
          snippet:
              'Run `npm audit` regularly and never commit .env files.',
          severity: Severity.low,
          detectedAt: DateTime.now(),
        ));
        _logger.info('Node.js project detected at $dirPath');
      }

      if (File('${dir.path}/Dockerfile').existsSync() ||
          File('${dir.path}/docker-compose.yml').existsSync()) {
        allFindings.add(Finding(
          type: FindingType.recommendation,
          label: 'Docker Project Detected',
          filePath: dir.path,
          lineNumber: 0,
          snippet:
              'Ensure no credentials are hardcoded in Dockerfile or docker-compose.yml. '
              'Use Docker secrets or environment variable injection at runtime.',
          severity: Severity.low,
          detectedAt: DateTime.now(),
        ));
        _logger.info('Docker project detected at $dirPath');
      }

      // ── File scan ────────────────────────────────────────────────────────
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        if (!_isTextFile(entity.path)) continue;

        // Skip noisy generated directories.
        const skipDirs = {
          '.git', 'node_modules', '.dart_tool', 'build',
          '.pub-cache', '.gradle', 'Pods', '__pycache__',
        };
        if (skipDirs.any((d) => entity.path.contains('/$d/'))) continue;

        final stat = await entity.stat();
        if (stat.size > maxFileSizeKb * 1024) continue;

        state = state.copyWith(currentFile: entity.path);

        try {
          final content = await entity.readAsString();
          final lines   = content.split('\n');
          scannedFiles++;

          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];

            // 1. Regex scan
            for (final label in RegexEngine.scanText(line)) {
              allFindings.add(Finding(
                type:       FindingType.regex,
                label:      label,
                filePath:   entity.path,
                lineNumber: i + 1,
                snippet:    line.trim(),
                severity:   Severity.high,
                detectedAt: DateTime.now(),
              ));
              _logger.warning(
                'Secret: $label — ${entity.path.split('/').last}:${i + 1}',
              );
            }

            // 2. Entropy scan — only check long tokens without code punctuation.
            for (final token in line.split(RegExp(r'\s+'))) {
              if (token.length <= 16) continue;
              if (token.contains('{') || token.contains('}')) continue;
              if (token.contains('(') || token.contains(')')) continue;

              final entropy = EntropyMath.calculateEntropy(token);
              if (entropy > state.entropyThreshold) {
                allFindings.add(Finding(
                  type:         FindingType.entropy,
                  label:        'High Entropy String',
                  filePath:     entity.path,
                  lineNumber:   i + 1,
                  snippet:      token,
                  entropyScore: entropy,
                  severity:     Severity.medium,
                  detectedAt:   DateTime.now(),
                ));
              }
            }
          }
        } catch (e) {
          _logger.error('Cannot read ${entity.path.split('/').last}: $e');
        }
      }
    }

    final secCount = allFindings.where((f) => f.type != FindingType.recommendation).length;
    _logger.success(
      'Scan complete — $scannedFiles file(s) scanned, $secCount security finding(s).',
    );

    state = ScannerState(
      isScanning:       false,
      currentFile:      'Scan Complete',
      scannedFileCount: scannedFiles,
      findings:         allFindings,
      entropyThreshold: state.entropyThreshold,
    );
  }

  void clearFindings() {
    state = ScannerState(entropyThreshold: state.entropyThreshold);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  bool _isTextFile(String path) {
    final p = path.toLowerCase();
    const exts = {
      '.dart', '.js', '.jsx', '.ts', '.tsx',
      '.json', '.yaml', '.yml', '.toml',
      '.txt', '.md', '.env', '.env.local', '.env.example',
      '.py', '.rb', '.go', '.java', '.kt', '.swift',
      '.php', '.sh', '.bash', '.zsh',
      '.xml', '.properties', '.gradle', '.config',
      '.tf', '.hcl',         // Terraform / HCL
      '.sql',
      '.rs',                 // Rust
      '.cs',                 // C#
      '.cpp', '.c', '.h',
    };
    return exts.any((ext) => p.endsWith(ext));
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final scannerStateProvider =
    NotifierProvider<ScannerNotifier, ScannerState>(() => ScannerNotifier());
