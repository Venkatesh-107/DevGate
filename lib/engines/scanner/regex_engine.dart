class RegexEngine {
  // A comprehensive set of high-signal secret patterns (TruffleHog-inspired).
  // 20 patterns covering all major cloud providers, SaaS APIs, and key formats.
  static final Map<String, RegExp> _patterns = {
    // ─── Cloud Providers ───────────────────────────────────────────────────────
    'AWS Access Key ID': RegExp(
      r'(?:A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}',
    ),
    'AWS Secret Access Key': RegExp(
      r'aws_secret_access_key\s*={0,1}\s*([a-zA-Z0-9/+=]{40})',
      caseSensitive: false,
    ),
    'Google API Key': RegExp(r'AIza[0-9A-Za-z_-]{35}'),
    'Azure Storage Key': RegExp(
      r'DefaultEndpointsProtocol=https;AccountName=[^;]+;AccountKey=[A-Za-z0-9+/=]{88}',
    ),
    'Firebase Config': RegExp(
      r'firebase[a-zA-Z]*["\s]*[:=]["\s]*[A-Za-z0-9_-]{20,}',
      caseSensitive: false,
    ),
    'Supabase Key': RegExp(r'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[A-Za-z0-9_-]{50,}'),

    // ─── Payment ───────────────────────────────────────────────────────────────
    'Stripe Standard API Key': RegExp(r'sk_live_[0-9a-zA-Z]{24}'),
    'Stripe Restricted API Key': RegExp(r'rk_live_[0-9a-zA-Z]{24}'),

    // ─── AI / LLM ──────────────────────────────────────────────────────────────
    'OpenAI API Key': RegExp(r'sk-[A-Za-z0-9]{48}'),
    'Anthropic API Key': RegExp(r'sk-ant-[A-Za-z0-9_-]{40,}'),

    // ─── Version Control ───────────────────────────────────────────────────────
    'GitHub Personal Access Token': RegExp(r'ghp_[0-9a-zA-Z]{36}'),
    'GitHub Fine-Grained PAT': RegExp(r'github_pat_[0-9a-zA-Z_]{82}'),
    'npm Token': RegExp(r'npm_[A-Za-z0-9]{36}'),

    // ─── Messaging / Communication ─────────────────────────────────────────────
    'Slack Bot Token': RegExp(r'xoxb-[0-9]{11}-[0-9]{11}-[a-zA-Z0-9]{24}'),
    'Discord Bot Token': RegExp(r'[MN][A-Za-z0-9]{23,28}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27,}'),
    'Twilio API Key': RegExp(r'SK[0-9a-fA-F]{32}'),
    'SendGrid API Key': RegExp(r'SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}'),
    'Mailgun API Key': RegExp(r'key-[0-9a-zA-Z]{32}'),

    // ─── Infrastructure ────────────────────────────────────────────────────────
    'Heroku API Key': RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'),

    // ─── Cryptographic Keys ────────────────────────────────────────────────────
    'RSA Private Key': RegExp(r'-----BEGIN RSA PRIVATE KEY-----'),
    'Generic Private Key': RegExp(r'-----BEGIN (?:EC |DSA )?PRIVATE KEY-----'),
    'Generic JWT': RegExp(
      r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}',
    ),
  };

  /// Returns the total number of loaded detection patterns.
  static int get patternCount => _patterns.length;

  /// Scans the provided text against known regex patterns.
  /// Returns a list of matched secret descriptions (e.g., "AWS Access Key ID").
  static List<String> scanText(String text) {
    List<String> findings = [];

    _patterns.forEach((name, regex) {
      if (regex.hasMatch(text)) {
        findings.add(name);
      }
    });

    return findings;
  }
}
