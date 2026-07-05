import 'dart:math';

class EntropyMath {
  /// Calculates the Shannon entropy of a given string.
  /// Higher values suggest more randomness (e.g., API keys, secrets).
  static double calculateEntropy(String text) {
    if (text.isEmpty) return 0.0;

    final Map<String, int> frequencies = {};
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      frequencies[char] = (frequencies[char] ?? 0) + 1;
    }

    double entropy = 0.0;
    final int length = text.length;

    for (final frequency in frequencies.values) {
      final double p = frequency / length;
      entropy -= p * (log(p) / ln2);
    }

    return entropy;
  }
}
