import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finding.dart';
import 'entropy_math.dart';
import 'regex_engine.dart';

class ScannerState {
  final bool isScanning;
  final String currentFile;
  final List<Finding> findings;

  const ScannerState({
    this.isScanning = false,
    this.currentFile = '',
    this.findings = const [],
  });

  ScannerState copyWith({
    bool? isScanning,
    String? currentFile,
    List<Finding>? findings,
  }) {
    return ScannerState(
      isScanning: isScanning ?? this.isScanning,
      currentFile: currentFile ?? this.currentFile,
      findings: findings ?? this.findings,
    );
  }
}

class ScannerNotifier extends Notifier<ScannerState> {
  @override
  ScannerState build() => const ScannerState();

  Future<void> scanDirectories(List<String> directoryPaths, {double entropyThreshold = 4.8}) async {
    state = const ScannerState(isScanning: true);
    
    List<Finding> allFindings = [];

    for (final directoryPath in directoryPaths) {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) continue;

      // --- Architectural Recommendations ---
      final hasPubspec = File('${dir.path}/pubspec.yaml').existsSync();
      final hasPackageJson = File('${dir.path}/package.json').existsSync();
      
      if (hasPubspec) {
        allFindings.add(Finding(
          type: FindingType.recommendation,
          label: 'Flutter/Dart Project Detected',
          filePath: dir.path,
          lineNumber: 0,
          snippet: 'Consider using a structured architecture like Clean Architecture or Feature-First (e.g. lib/core, lib/ui, lib/data, lib/domain).',
          severity: Severity.low,
          detectedAt: DateTime.now(),
        ));
      }
      
      if (hasPackageJson) {
        allFindings.add(Finding(
          type: FindingType.recommendation,
          label: 'Node.js/Web Project Detected',
          filePath: dir.path,
          lineNumber: 0,
          snippet: 'Ensure your dependencies are audited regularly using `npm audit` and avoid checking in .env files.',
          severity: Severity.low,
          detectedAt: DateTime.now(),
        ));
      }

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          if (_isProbablyTextFile(entity.path)) {
            final stat = await entity.stat();
            if (stat.size > 1000 * 1024 * 1024) continue; // skip files > 1GB

            const skipDirs = {'.git', 'node_modules', '.dart_tool', 'build', '.pub-cache'};
            if (skipDirs.any((d) => entity.path.contains('/$d/'))) continue;
            state = state.copyWith(currentFile: entity.path);
            
            try {
              final content = await entity.readAsString();
              final lines = content.split('\n');
              
              for (int i = 0; i < lines.length; i++) {
                final line = lines[i];
                final regexFindings = RegexEngine.scanText(line);
                
                for (var label in regexFindings) {
                  allFindings.add(Finding(
                    type: FindingType.regex,
                    label: label,
                    filePath: entity.path,
                    lineNumber: i + 1,
                    snippet: line.trim(),
                    severity: Severity.high,
                    detectedAt: DateTime.now(),
                  ));
                }

                // 2. Entropy Scan
                final tokens = line.split(RegExp(r'\s+'));
                for (var token in tokens) {
                  // Only check long tokens without common code punctuation to reduce false positives
                  if (token.length > 16 && !token.contains('{') && !token.contains('}')) { 
                    final entropy = EntropyMath.calculateEntropy(token);
                    if (entropy > entropyThreshold) { 
                      allFindings.add(Finding(
                        type: FindingType.entropy,
                        label: 'High Entropy String',
                        filePath: entity.path,
                        lineNumber: i + 1,
                        snippet: token,
                        entropyScore: entropy,
                        severity: Severity.medium,
                        detectedAt: DateTime.now(),
                      ));
                    }
                  }
                }
              }
            } catch (e) {
               print('Could not read ${entity.path}: $e');
            }
          }
        }
      }
    }

    state = ScannerState(
      isScanning: false,
      currentFile: 'Scan Complete',
      findings: allFindings,
    );
  }

  void clearFindings() {
    state = const ScannerState();
  }

  bool _isProbablyTextFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.dart') || 
           lowerPath.endsWith('.js') || 
           lowerPath.endsWith('.ts') || 
           lowerPath.endsWith('.json') || 
           lowerPath.endsWith('.yaml') || 
           lowerPath.endsWith('.yml') ||
           lowerPath.endsWith('.txt') ||
           lowerPath.endsWith('.md') ||
           lowerPath.endsWith('.env');
  }
}

final scannerStateProvider = NotifierProvider<ScannerNotifier, ScannerState>(() {
  return ScannerNotifier();
});
