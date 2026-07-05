import 'dart:io';

/// Result of any git operation
class GitResult {
  final bool success;
  final String output;
  final String error;

  const GitResult({
    required this.success,
    required this.output,
    this.error = '',
  });
}

/// Represents a file changed in the working tree
class GitFile {
  final String status; // 'M', 'A', 'D', '?', etc.
  final String path;

  const GitFile({required this.status, required this.path});

  String get statusLabel {
    switch (status.trim()) {
      case 'M': return 'Modified';
      case 'A': return 'Added';
      case 'D': return 'Deleted';
      case '?': return 'Untracked';
      case 'R': return 'Renamed';
      default: return status;
    }
  }
}

class GitEngine {
  final String workingDir;

  GitEngine(this.workingDir);

  // ─── Internal runner ────────────────────────────────────────────────────────

  Future<GitResult> _run(List<String> args, {String? cwd}) async {
    try {
      final result = await Process.run(
        'git',
        args,
        workingDirectory: cwd ?? workingDir,
        environment: {
          ...Platform.environment,
          // Prevent git from opening an editor for commit messages
          'GIT_TERMINAL_PROMPT': '0',
        },
      );
      return GitResult(
        success: result.exitCode == 0,
        output: result.stdout.toString().trim(),
        error: result.stderr.toString().trim(),
      );
    } catch (e) {
      return GitResult(success: false, output: '', error: e.toString());
    }
  }

  // ─── Repo Detection ─────────────────────────────────────────────────────────

  Future<bool> isGitRepo() async {
    final result = await _run(['rev-parse', '--is-inside-work-tree']);
    return result.success;
  }

  Future<String?> getRepoRoot() async {
    final result = await _run(['rev-parse', '--show-toplevel']);
    return result.success ? result.output : null;
  }

  // ─── Status ─────────────────────────────────────────────────────────────────

  Future<List<GitFile>> status() async {
    final result = await _run(['status', '--porcelain', '-uall']);
    if (!result.success || result.output.isEmpty) return [];

    return result.output
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          final statusCode = line.substring(0, 2).trim().isNotEmpty
              ? line.substring(0, 2).trim()
              : '?';
          final path = line.length > 3 ? line.substring(3).trim() : line.trim();
          return GitFile(status: statusCode, path: path);
        })
        .toList();
  }

  Future<String> currentBranch() async {
    final result = await _run(['rev-parse', '--abbrev-ref', 'HEAD']);
    return result.success ? result.output : 'unknown';
  }

  Future<String> remoteUrl() async {
    final result = await _run(['remote', 'get-url', 'origin']);
    return result.success ? result.output : 'No remote';
  }

  Future<String> log({int count = 5}) async {
    final result = await _run([
      'log',
      '--oneline',
      '-$count',
    ]);
    return result.success ? result.output : '';
  }

  // ─── Staging ─────────────────────────────────────────────────────────────────

  Future<GitResult> addAll() => _run(['add', '.']);

  Future<GitResult> addFile(String filePath) => _run(['add', filePath]);

  Future<GitResult> addFiles(List<String> filePaths) => _run(['add', ...filePaths]);

  Future<GitResult> resetFile(String filePath) => _run(['restore', '--staged', filePath]);

  // ─── Commit ──────────────────────────────────────────────────────────────────

  Future<GitResult> commit(String message) {
    return _run(['commit', '-m', message]);
  }

  // ─── Remote Ops ──────────────────────────────────────────────────────────────

  Future<GitResult> push({String remote = 'origin', String? branch}) async {
    final b = branch ?? await currentBranch();
    return _run(['push', remote, b]);
  }

  Future<GitResult> pull({String remote = 'origin', String? branch}) async {
    final b = branch ?? await currentBranch();
    return _run(['pull', remote, b]);
  }

  // ─── Init & Clone ────────────────────────────────────────────────────────────

  Future<GitResult> init({String? initialBranch = 'main'}) {
    return _run(['init', '--initial-branch=$initialBranch']);
  }

  Future<GitResult> addRemote(String url, {String name = 'origin'}) {
    return _run(['remote', 'add', name, url]);
  }

  Future<GitResult> setRemoteUrl(String url, {String name = 'origin'}) {
    return _run(['remote', 'set-url', name, url]);
  }

  /// Clone a repo into [destinationPath]
  static Future<GitResult> clone(String url, String destinationPath) async {
    try {
      final result = await Process.run(
        'git',
        ['clone', url, destinationPath],
        environment: {
          ...Platform.environment,
          'GIT_TERMINAL_PROMPT': '0',
        },
      );
      return GitResult(
        success: result.exitCode == 0,
        output: result.stdout.toString().trim(),
        error: result.stderr.toString().trim(),
      );
    } catch (e) {
      return GitResult(success: false, output: '', error: e.toString());
    }
  }

  // ─── Config (for auth via HTTPS token) ───────────────────────────────────────

  /// Inject GitHub token into the remote URL so push/pull works without a password prompt.
  /// Format: https://token@github.com/owner/repo.git
  Future<GitResult> setRemoteWithToken(String owner, String repo, String token) {
    final url = 'https://$token@github.com/$owner/$repo.git';
    return setRemoteUrl(url);
  }

  Future<GitResult> configUser(String name, String email) async {
    await _run(['config', 'user.name', name]);
    return _run(['config', 'user.email', email]);
  }
}
