enum FindingType { regex, entropy, recommendation }
enum Severity { critical, high, medium, low }

class Finding {
  final FindingType type;
  final String label;        
  final String filePath;
  final int lineNumber;
  final String snippet;      
  final double? entropyScore;
  final Severity severity;
  final DateTime detectedAt;

  Finding({
    required this.type,
    required this.label,
    required this.filePath,
    required this.lineNumber,
    required this.snippet,
    this.entropyScore,
    required this.severity,
    required this.detectedAt,
  });
}
